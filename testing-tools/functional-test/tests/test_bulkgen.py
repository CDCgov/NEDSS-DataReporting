"""Tests for bulk-load file generation (--bulk): planning, evaluation, output."""

import pytest

from functional_test.bulk import build_bulk_plan
from functional_test.bulkgen import (
    BulkGenError,
    build_ordered_parts,
    evaluate_suite,
    split_sql,
)

ALPHA_SETUP = """USE [NBS_ODSE];
DECLARE @patient_uid bigint = 1000001000;
DECLARE @local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @patient_uid))) + N'GA01';
DECLARE @answer_out TABLE ([value] bigint);
INSERT INTO [dbo].[Person] ([person_uid], [local_id], [version_ctrl_nbr], [status_cd], [add_time])
VALUES (@patient_uid, @local_id, 1, N'A', N'2026-05-06T22:11:00.673');
INSERT INTO [dbo].[Answer] ([act_uid], [txt]) OUTPUT INSERTED.[answer_uid] INTO @answer_out
VALUES (@patient_uid, N'semi;colon ''quoted''');
DECLARE @answer_uid bigint;
SELECT TOP 1 @answer_uid = [value] FROM @answer_out;
INSERT INTO [dbo].[AnswerHist] ([answer_uid], [note]) VALUES (@answer_uid, N'h');
UPDATE [dbo].[Person] SET [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1,
    [status_cd] = N'I' WHERE [person_uid] = @patient_uid;
INSERT INTO [dbo].[Tmp] ([a], [b]) VALUES (1, N'x'), (2, N'y');
DELETE FROM [dbo].[Tmp] WHERE [a] = 1;
INSERT INTO [dbo].[Link] ([person_uid], [grp]) VALUES (@patient_uid,
    (SELECT TOP(1) [g] FROM [dbo].[SeedTable] WHERE [name]='|' ORDER BY [v] DESC));
UPDATE [dbo].[Person] SET [note] = N'z' WHERE [person_uid] =
    (SELECT TOP 1 [person_uid] FROM [dbo].[Person] WHERE [status_cd] = N'NOPE');
"""

BETA_SETUP = """USE [NBS_ODSE];
DECLARE @a bigint = 1000002000;
DECLARE @b bigint = 1000002049;
INSERT INTO [dbo].[Person] ([person_uid], [local_id], [version_ctrl_nbr], [status_cd], [add_time])
VALUES (@a, N'PSN1000002000GA01', 1, N'A', N'2026-05-06T22:11:00.673');
INSERT INTO [dbo].[Act] ([act_uid]) VALUES (@b);
"""


def _make_suite(tmp_path):
    for name, sql in [("alpha", ALPHA_SETUP), ("beta", BETA_SETUP)]:
        step = tmp_path / name / "010-step"
        step.mkdir(parents=True)
        (step / "setup.sql").write_text(sql)
    return [tmp_path / "alpha", tmp_path / "beta"]


class TestSplitSql:
    def test_semicolon_inside_string_not_split(self):
        assert split_sql("INSERT INTO t VALUES (N'a;b'); SELECT 1") == [
            "INSERT INTO t VALUES (N'a;b')",
            "SELECT 1",
        ]

    def test_comments_stripped_outside_strings_only(self):
        statements = split_sql("-- top comment\nSELECT 1; INSERT (N'x--y')")
        assert statements == ["SELECT 1", "INSERT (N'x--y')"]

    def test_escaped_quote(self):
        assert split_sql("SELECT N'it''s;fine'; SELECT 2") == [
            "SELECT N'it''s;fine'",
            "SELECT 2",
        ]


class TestBulkPlan:
    def test_stride_slots_span(self, tmp_path):
        plan = build_bulk_plan(_make_suite(tmp_path))
        assert plan.stride == 50  # beta spans ids ..000-..049
        assert plan.slots == 20
        assert plan.span == 2000  # blocks 1000001000 and 1000002000

    def test_offset_pattern_tiles_then_jumps(self, tmp_path):
        plan = build_bulk_plan(_make_suite(tmp_path))
        offsets = [plan.offset_for(i) for i in (0, 1, 19, 20, 21)]
        assert offsets == [0, 50, 950, 2000, 2050]
        assert plan.offset_for(0, base=100000) == 100000

    def test_copies_never_overlap(self, tmp_path):
        plan = build_bulk_plan(_make_suite(tmp_path))
        used = set()
        for i in range(60):
            offset = plan.offset_for(i)
            for test in plan.tests:
                span = range(
                    test.block_start + offset,
                    test.block_start + offset + test.block_width,
                )
                assert not used.intersection(span), f"copy {i} collides"
                used.update(span)

    def test_shared_block_rejected(self, tmp_path):
        dirs = _make_suite(tmp_path)
        clone = tmp_path / "alpha2" / "010-step"
        clone.mkdir(parents=True)
        (clone / "setup.sql").write_text("DECLARE @x bigint = 1000001005;\n")
        with pytest.raises(ValueError, match="overlapping UID blocks"):
            build_bulk_plan(dirs + [tmp_path / "alpha2"])


class TestEvaluate:
    def test_final_state(self, tmp_path):
        suite = evaluate_suite(build_bulk_plan(_make_suite(tmp_path)))

        person = suite.tables["person"]
        alpha_person = person.rows[0]
        # local_id computed from the concat expression.
        assert "".join(alpha_person["local_id"]) == "PSN1000001000GA01"
        # UPDATE applied: version bumped against the pre-update row, status set.
        assert "".join(alpha_person["version_ctrl_nbr"]) == "2"
        assert "".join(alpha_person["status_cd"]) == "I"
        # The subquery-miss UPDATE was skipped: no 'note' column materialized.
        assert "note" not in alpha_person

        # Identity capture: Answer's uid synthesized, reused by AnswerHist.
        answer = suite.tables["answer"]
        assert answer.identity_col == "answer_uid"
        assert answer.identity_count == 1
        hist = suite.tables["answerhist"]
        assert hist.rows[0]["answer_uid"] == answer.rows[0]["answer_uid"]

        # Multi-row insert + delete leaves only the a=2 row.
        tmp = suite.tables["tmp"]
        assert ["".join(r["a"]) for r in tmp.rows] == ["2"]

        # Seed-data subquery insert deferred, subquery-miss update warned.
        assert len(suite.deferred_rows) == 1
        assert any("deferred to fixup.sql" in w for w in suite.warnings)
        assert any("UPDATE Person skipped" in w for w in suite.warnings)

    def test_column_names_case_insensitive(self, tmp_path):
        # Different tests spell the same column differently; SQL Server is
        # case-insensitive, so the union must hold one canonical spelling.
        step = tmp_path / "mixed" / "010"
        step.mkdir(parents=True)
        (step / "setup.sql").write_text(
            "DECLARE @a bigint = 1000001000;\n"
            "DECLARE @b bigint = 1000001001;\n"
            "INSERT INTO [dbo].[Fact] ([case_uid], [ELP_class_cd]) VALUES (@a, N'x');\n"
            "INSERT INTO [dbo].[Fact] ([case_uid], [elp_class_cd]) VALUES (@b, N'y');\n"
            "UPDATE [dbo].[Fact] SET [Elp_Class_Cd] = N'z' WHERE [CASE_UID] = @b;\n"
        )
        suite = evaluate_suite(build_bulk_plan([tmp_path / "mixed"]))
        fact = suite.tables["fact"]
        assert fact.columns == ["case_uid", "ELP_class_cd"]  # first-seen spelling
        assert ["".join(r["ELP_class_cd"]) for r in fact.rows] == ["x", "z"]
        assert not suite.warnings

    def test_unsupported_statement_raises(self, tmp_path):
        step = tmp_path / "bad" / "010"
        step.mkdir(parents=True)
        (step / "setup.sql").write_text(
            "DECLARE @a bigint = 1000001000;\nMERGE INTO t USING x ON 1=1;"
        )
        with pytest.raises(BulkGenError, match="bad/010"):
            evaluate_suite(build_bulk_plan([tmp_path / "bad"]))


class TestParts:
    def test_tables_split_per_column_set(self, tmp_path):
        # Inserts with different column subsets get separate parts: absent
        # columns would otherwise load as NULL where a real INSERT applies
        # the column default.
        step = tmp_path / "split" / "010"
        step.mkdir(parents=True)
        (step / "setup.sql").write_text(
            "DECLARE @a bigint = 1000001000;\n"
            "DECLARE @b bigint = 1000001001;\n"
            "INSERT INTO [dbo].[Fact] ([case_uid], [class_cd]) VALUES (@a, N'x');\n"
            "INSERT INTO [dbo].[Fact] ([case_uid]) VALUES (@b);\n"
        )
        suite = evaluate_suite(build_bulk_plan([tmp_path / "split"]))
        _, all_parts = build_ordered_parts(suite)
        assert [p.name for p in all_parts] == ["Fact__1", "Fact__2"]
        assert all_parts[0].columns == ["case_uid", "class_cd"]
        assert all_parts[1].columns == ["case_uid"]

    def test_single_column_set_keeps_plain_name(self, tmp_path):
        suite = evaluate_suite(build_bulk_plan(_make_suite(tmp_path)))
        _, all_parts = build_ordered_parts(suite)
        names = [p.name for p in all_parts]
        assert "Person" in names  # alpha and beta share one column set
        # FK-safe order: first-insert order across tables.
        assert names.index("Person") < names.index("Answer")
        assert names.index("Answer") < names.index("AnswerHist")

    def test_parts_ordered_numerically_not_lexically(self, tmp_path):
        step = tmp_path / "many" / "010"
        step.mkdir(parents=True)
        statements = ["DECLARE @a bigint = 1000001000;"]
        for i in range(12):
            statements.append(
                f"INSERT INTO [dbo].[Fact] ([case_uid], [col{i}]) VALUES (@a, {i});"
            )
        (step / "setup.sql").write_text("\n".join(statements) + "\n")
        suite = evaluate_suite(build_bulk_plan([tmp_path / "many"]))
        _, all_parts = build_ordered_parts(suite)
        names = [p.name for p in all_parts]
        assert names.index("Fact__2") < names.index("Fact__10")
        assert names.index("Fact__9") < names.index("Fact__10")

    def test_uncaptured_rows_of_identity_table_get_synthesized_ids(self, tmp_path):
        # A row inserted without OUTPUT capture into an identity table must
        # still carry a synthesized value: IDENTITY_INSERT advances the seed,
        # so a server-assigned row would collide with another copy's range.
        step = tmp_path / "mixid" / "010"
        step.mkdir(parents=True)
        (step / "setup.sql").write_text(
            "DECLARE @a bigint = 1000001000;\n"
            "DECLARE @out TABLE ([value] bigint);\n"
            "INSERT INTO [dbo].[Ans] ([act_uid], [txt]) OUTPUT INSERTED.[ans_uid] "
            "INTO @out VALUES (@a, N'captured');\n"
            "INSERT INTO [dbo].[Ans] ([act_uid], [txt]) VALUES (@a, N'plain');\n"
        )
        suite = evaluate_suite(build_bulk_plan([tmp_path / "mixid"]))
        ans = suite.tables["ans"]
        assert ans.identity_count == 2
        assert all("ans_uid" in row for row in ans.rows)
        uids = {row["ans_uid"][0].seq for row in ans.rows}
        assert uids == {0, 1}
        # Both rows now share one column set -> a single part, all explicit.
        _, all_parts = build_ordered_parts(suite)
        assert [p.name for p in all_parts if p.table.name == "Ans"] == ["Ans"]
        assert all_parts[0].keep_identity or any(
            p.keep_identity for p in all_parts
        )

    def test_identity_part_flag(self, tmp_path):
        suite = evaluate_suite(build_bulk_plan(_make_suite(tmp_path)))
        _, all_parts = build_ordered_parts(suite)
        by_name = {p.name: p for p in all_parts}
        assert by_name["Answer"].keep_identity is True
        assert by_name["Person"].keep_identity is False
