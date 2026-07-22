"""Tests for the Parquet + OPENROWSET bulk output (--bulk-format parquet)."""

import pyarrow.parquet as pq

from functional_test.bulk import build_bulk_plan
from functional_test.bulkgen import evaluate_suite
from functional_test.parquet_out import (
    _shard_ranges,
    write_bulk_parquet,
)

from test_bulkgen import _make_suite


def _read(out, name):
    return pq.read_table(out / name).to_pydict()


class TestShardRanges:
    def test_even_split(self):
        assert _shard_ranges(6, 3) == [(0, 0, 2), (1, 2, 2), (2, 4, 2)]

    def test_remainder_spread_over_first_shards(self):
        assert _shard_ranges(7, 3) == [(0, 0, 3), (1, 3, 2), (2, 5, 2)]

    def test_more_workers_than_copies(self):
        assert _shard_ranges(2, 8) == [(0, 0, 1), (1, 1, 1)]


class TestParquetValues:
    def test_values_shifted_and_raw(self, tmp_path):
        suite = evaluate_suite(build_bulk_plan(_make_suite(tmp_path)))
        out = tmp_path / "out"
        write_bulk_parquet(suite, out, copies=3, identity_base=900)

        person = _read(out, "Person__s000.parquet")
        # alpha + beta per copy, 3 copies; block IDs shifted per copy.
        assert person["person_uid"] == [
            "1000001000", "1000002000",
            "1000001050", "1000002050",
            "1000001100", "1000002100",
        ]
        # No .dat workarounds: the ISO 'T' timestamp survives as-is.
        assert person["add_time"][0] == "2026-05-06T22:11:00.673"
        # Embedded ID in the computed local_id shifted.
        assert person["local_id"][2] == "PSN1000001050GA01"

        answer = _read(out, "Answer__s000.parquet")
        assert answer["answer_uid"] == ["900", "901", "902"]
        hist = _read(out, "AnswerHist__s000.parquet")
        assert hist["answer_uid"] == ["900", "901", "902"]

    def test_empty_string_and_null_distinct(self, tmp_path):
        step = tmp_path / "vals" / "010"
        step.mkdir(parents=True)
        (step / "setup.sql").write_text(
            "DECLARE @a bigint = 1000001000;\n"
            "INSERT INTO [dbo].[Fact] ([case_uid], [empty_col], [null_col]) "
            "VALUES (@a, N'', NULL);\n"
        )
        suite = evaluate_suite(build_bulk_plan([tmp_path / "vals"]))
        out = tmp_path / "out"
        write_bulk_parquet(suite, out, copies=1)
        fact = _read(out, "Fact__s000.parquet")
        assert fact["empty_col"] == [""]  # real empty string, no CHAR(1) sentinel
        assert fact["null_col"] == [None]  # real NULL

    def test_sharded_output_matches_single_shard(self, tmp_path):
        suite = evaluate_suite(build_bulk_plan(_make_suite(tmp_path)))
        single = tmp_path / "single"
        sharded = tmp_path / "sharded"
        write_bulk_parquet(suite, single, copies=5, workers=1)
        write_bulk_parquet(suite, sharded, copies=5, workers=2)

        one = _read(single, "Person__s000.parquet")
        merged = _read(sharded, "Person__s000.parquet")
        second = _read(sharded, "Person__s001.parquet")
        for col in one:
            merged_col = merged[col] + second[col]
            assert merged_col == one[col], f"column {col} differs"


class TestLoadScripts:
    def test_scripts(self, tmp_path):
        suite = evaluate_suite(build_bulk_plan(_make_suite(tmp_path)))
        out = tmp_path / "out"
        write_bulk_parquet(suite, out, copies=4, workers=2, manage_indexes=True)

        shard0 = (out / "shard_000.sql").read_text()
        assert ("FROM OPENROWSET(BULK N'$(DataDir)/Person__s000.parquet', "
                "FORMAT = 'PARQUET')") in shard0
        assert "INSERT INTO [dbo].[Person] (" in shard0
        # Identity table wrapped in guarded IDENTITY_INSERT; Person is not.
        assert "SET IDENTITY_INSERT [dbo].[Answer] ON;" in shard0
        assert "TableHasIdentity" in shard0
        assert "SET IDENTITY_INSERT [dbo].[Person] ON;" not in shard0
        # FK-safe order preserved.
        assert shard0.index("Person__s000") < shard0.index("Answer__s000")
        assert shard0.index("Answer__s000") < shard0.index("AnswerHist__s000")

        # Deadlock retry wrapper around every insert.
        assert "IF ERROR_NUMBER() <> 1205 OR @attempt >= 5 THROW;" in shard0

        shard1 = (out / "shard_001.sql").read_text()
        assert "Person__s001.parquet" in shard1
        # Rotated start: shard 1 begins on a different table than shard 0.
        import re
        first0 = re.search(r"(\w+)__s000\.parquet", shard0).group(1)
        first1 = re.search(r"(\w+)__s001\.parquet", shard1).group(1)
        assert first0 != first1

        pre = (out / "pre.sql").read_text()
        assert "NOCHECK CONSTRAINT ALL" in pre  # FK checks off, like bcp
        assert "DISABLE" in pre and "NONCLUSTERED" in pre
        post = (out / "post.sql").read_text()
        assert "WITH NOCHECK CHECK CONSTRAINT ALL" in post
        assert "REBUILD" in post
        assert "DBCC CHECKIDENT ('[dbo].[Answer]');" in post

        load_sh = (out / "load.sh").read_text()
        assert "xargs -P" in load_sh
        assert "DATA_DIR" in load_sh
        assert "run_sqlcmd pre.sql" in load_sh
        assert "run_sqlcmd fixup.sql" in load_sh  # mini suite has a deferred row

        load_sql = (out / "load.sql").read_text()
        assert "Person__s000.parquet" in load_sql and "Person__s001.parquet" in load_sql

        # fixup.sql stays set-based: one statement for all copies.
        fixup = (out / "fixup.sql").read_text()
        assert fixup.count("INSERT INTO [dbo].[Link]") == 1
        assert "TOP (4)" in fixup
        assert "(1000001000 + (n.i / 20) * 2000 + (n.i % 20) * 50)" in fixup
        assert "SELECT TOP(1) [g] FROM [dbo].[SeedTable]" in fixup

        # No bcp-era artifacts.
        assert not (out / "views.sql").exists()
        assert not list(out.glob("*.dat"))

    def test_with_schema_sized_from_data(self, tmp_path):
        # OPENROWSET's inferred VARCHAR(8000) truncates wide values, so each
        # statement declares an explicit schema; MAX only for wide columns.
        payload = "x" * 5000
        step = tmp_path / "wide" / "010"
        step.mkdir(parents=True)
        (step / "setup.sql").write_text(
            "DECLARE @a bigint = 1000001000;\n"
            f"INSERT INTO [dbo].[Doc] ([doc_uid], [payload], [cd]) "
            f"VALUES (@a, N'{payload}', N'11648804');\n"
        )
        suite = evaluate_suite(build_bulk_plan([tmp_path / "wide"]))
        out = tmp_path / "out"
        write_bulk_parquet(suite, out, copies=2, workers=2)
        for shard_sql in ("shard_000.sql", "shard_001.sql"):
            text = (out / shard_sql).read_text()
            assert "WITH ([doc_uid] NVARCHAR(4000), [payload] NVARCHAR(MAX), " \
                   "[cd] NVARCHAR(4000)) AS r;" in text

    def test_no_index_sections_by_default(self, tmp_path):
        suite = evaluate_suite(build_bulk_plan(_make_suite(tmp_path)))
        out = tmp_path / "out"
        write_bulk_parquet(suite, out, copies=1)
        assert "DISABLE" not in (out / "pre.sql").read_text()
        assert "REBUILD" not in (out / "post.sql").read_text()
