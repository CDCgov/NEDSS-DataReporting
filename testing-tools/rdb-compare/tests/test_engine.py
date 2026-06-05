"""Engine tests: SQL shape (build_value_diff_sql) and folding (compare_table).

``compare_table`` is exercised against a fake connection whose ``run_query``
returns canned rows keyed off substrings of the SQL it is handed, so the test
needs no live SQL Server.
"""

from __future__ import annotations

from rdb_compare import db, engine
from rdb_compare.engine import build_value_diff_sql, compare_table
from rdb_compare.models import Presence


# --- SQL shape ---------------------------------------------------------
def test_build_value_diff_sql_shape():
    sql = build_value_diff_sql(
        "LAB_TEST",
        ["LAB_TEST_UID"],
        ["RESULT", "STATUS"],
        "RDB",
        "RDB_MODERN",
    )
    # Table + both databases appear.
    assert "LAB_TEST" in sql
    assert "[RDB]" in sql
    assert "[RDB_MODERN]" in sql
    # Join on the key column.
    assert "L.[LAB_TEST_UID] = M.[LAB_TEST_UID]" in sql
    # NULL-safe EXCEPT difference test.
    assert "EXISTS (SELECT L.[RESULT] EXCEPT SELECT M.[RESULT])" in sql
    # Values cast to NVARCHAR.
    assert "CAST(L.[RESULT] AS NVARCHAR(4000))" in sql
    # One branch per value column, joined with UNION ALL.
    assert sql.count("UNION ALL") == 1
    assert "N'RESULT' AS [column_name]" in sql
    assert "N'STATUS' AS [column_name]" in sql


def test_build_value_diff_sql_composite_key():
    sql = build_value_diff_sql(
        "LAB100",
        ["LAB_RPT_LOCAL_ID", "LAB_RPT_UID"],
        ["COMMENTS"],
        "RDB",
        "RDB_MODERN",
    )
    assert (
        "L.[LAB_RPT_LOCAL_ID] = M.[LAB_RPT_LOCAL_ID] "
        "AND L.[LAB_RPT_UID] = M.[LAB_RPT_UID]"
    ) in sql


# --- compare_table folding --------------------------------------------
class FakeConn:
    """Stands in for a pymssql connection; dispatches on SQL substrings."""

    def __init__(self, counts, overlap, diffs, key_dup=False):
        self._counts = list(counts)  # consumed in call order: RDB then MODERN
        self._overlap = overlap
        self._diffs = diffs
        self._key_dup = key_dup       # True => key-uniqueness probe reports a dup


def _fake_run_query(conn, sql):
    if "[dup]" in sql:  # key-uniqueness probe: one row iff non-unique
        return [{"dup": 1}] if conn._key_dup else []
    if "COUNT(*)" in sql and "matched_keys" not in sql:
        return [{"n": conn._counts.pop(0)}]
    if "matched_keys" in sql:
        return [conn._overlap]
    if "column_name" in sql:
        return conn._diffs
    raise AssertionError(f"unexpected SQL: {sql[:60]}")


def test_compare_table_folds_counts_and_diffs(monkeypatch):
    monkeypatch.setattr(db, "run_query", _fake_run_query)

    diffs = [
        {"LAB_TEST_UID": "1", "column_name": "RESULT",
         "rdb_value": "pos", "modern_value": "neg"},
        {"LAB_TEST_UID": "2", "column_name": "RESULT",
         "rdb_value": "a", "modern_value": "b"},
        {"LAB_TEST_UID": "3", "column_name": "STATUS",
         "rdb_value": None, "modern_value": "X"},
    ]
    conn = FakeConn(
        counts=[100, 98],
        overlap={"matched_keys": 95, "rdb_only_keys": 5, "modern_only_keys": 3},
        diffs=diffs,
    )

    res = compare_table(
        conn, "LAB_TEST", ["LAB_TEST_UID"], ["RESULT", "STATUS"],
        "RDB", "RDB_MODERN",
    )

    assert res.error is None
    assert res.rdb_count == 100
    assert res.modern_count == 98
    assert res.matched_keys == 95
    assert res.rdb_only_keys == 5
    assert res.modern_only_keys == 3
    assert res.presence == Presence.BOTH
    assert res.key_columns == ("LAB_TEST_UID",)

    # Two columns mismatched; ordered per value_cols.
    cols = {c.column: c for c in res.columns}
    assert [c.column for c in res.columns] == ["RESULT", "STATUS"]
    assert cols["RESULT"].mismatches == 2
    assert cols["RESULT"].compared == 95
    assert cols["STATUS"].mismatches == 1
    # Sample CellDiff captured correctly.
    s = cols["RESULT"].samples[0]
    assert s.key == ("1",)
    assert s.rdb_value == "pos"
    assert s.modern_value == "neg"


def test_compare_table_caps_samples(monkeypatch):
    monkeypatch.setattr(db, "run_query", _fake_run_query)

    diffs = [
        {"LAB_TEST_UID": str(i), "column_name": "RESULT",
         "rdb_value": f"l{i}", "modern_value": f"m{i}"}
        for i in range(50)
    ]
    conn = FakeConn(
        counts=[60, 60],
        overlap={"matched_keys": 50, "rdb_only_keys": 0, "modern_only_keys": 0},
        diffs=diffs,
    )

    res = compare_table(
        conn, "LAB_TEST", ["LAB_TEST_UID"], ["RESULT"],
        "RDB", "RDB_MODERN", sample_cap=20,
    )
    col = res.columns[0]
    assert col.mismatches == 50          # every differing row counted
    assert len(col.samples) == 20        # but samples capped


def test_compare_table_no_key_counts_only(monkeypatch):
    monkeypatch.setattr(db, "run_query", _fake_run_query)
    conn = FakeConn(counts=[10, 10], overlap=None, diffs=[])

    res = compare_table(conn, "SOME_TABLE", [], ["A", "B"], "RDB", "RDB_MODERN")

    assert res.rdb_count == 10
    assert res.modern_count == 10
    assert res.columns == []
    assert res.error == "no usable key; counts only"


def test_compare_table_nonunique_key_degrades_to_counts(monkeypatch):
    """A resolved key that repeats (reference table) must not fan out: the probe
    trips and the table degrades to counts-only instead of joining."""
    monkeypatch.setattr(db, "run_query", _fake_run_query)
    # diffs/overlap would be wrong to reach; key_dup=True trips the probe first.
    conn = FakeConn(
        counts=[158776, 125548], overlap=None, diffs=[], key_dup=True
    )

    res = compare_table(
        conn, "REF_FORMCODE_TRANSLATION", ["NBS_QUESTION_UID"],
        ["CODE", "CODE_SHORT_DESC_TXT"], "RDB", "RDB_MODERN",
    )

    assert res.rdb_count == 158776
    assert res.modern_count == 125548
    assert res.columns == []                 # never ran the fan-out join
    assert res.matched_keys == 0
    assert "not unique" in res.error
    assert "RDB" in res.error


def test_compare_table_records_sql_error(monkeypatch):
    def boom(conn, sql):
        raise RuntimeError("Invalid object name 'RDB.dbo.MISSING'")

    monkeypatch.setattr(db, "run_query", boom)
    conn = FakeConn(counts=[], overlap=None, diffs=[])

    res = compare_table(conn, "MISSING", ["UID"], ["A"], "RDB", "RDB_MODERN")
    assert res.error is not None
    assert "MISSING" in res.error
