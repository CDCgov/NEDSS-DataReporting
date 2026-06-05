from rdb_compare.classifier import classify_run, summarize
from rdb_compare.models import (
    CellDiff,
    ColumnDiff,
    Presence,
    RunReport,
    TableResult,
    Verdict,
)
from rdb_compare.rules import IgnoreColumnRule, KnownBugRule, RuleRegistry, SkipTableRule


def _col(table, name, rdb=None, modern=None):
    samples = [CellDiff(table=table, key=(1,), column=name, rdb_value=rdb, modern_value=modern)]
    return ColumnDiff(table=table, column=name, compared=10, mismatches=1, samples=samples)


def _registry():
    return RuleRegistry([
        SkipTableRule("ETL_*", "staging table"),
        IgnoreColumnRule("*_LAST_UPDATE_DT", "ETL timing", category="env"),
        KnownBugRule("D_PLACE", "*", "D_PLACE not populated by RTR", ticket="PDF-bug-1"),
    ])


def test_skipped_table_is_marked_and_columns_left_unclassified():
    rpt = RunReport(rdb_db="RDB", modern_db="RDB_MODERN", tables=[
        TableResult(table="ETL_CONTROL", columns=[_col("ETL_CONTROL", "X")]),
    ])
    classify_run(rpt, _registry())
    t = rpt.tables[0]
    assert t.skipped
    assert t.classification.verdict == Verdict.IGNORED


def test_column_verdicts_assigned():
    rpt = RunReport(rdb_db="RDB", modern_db="RDB_MODERN", compared=2, tables=[
        TableResult(table="D_PATIENT", presence=Presence.BOTH, columns=[
            _col("D_PATIENT", "FIRST_NM", rdb="ALICE", modern="BOB"),       # NEW
            _col("D_PATIENT", "RECORD_LAST_UPDATE_DT", rdb="1", modern="2"),  # IGNORED
        ]),
        TableResult(table="D_PLACE", presence=Presence.BOTH, columns=[
            _col("D_PLACE", "PLACE_NM", rdb="x", modern="y"),                # KNOWN_BUG
        ]),
    ])
    classify_run(rpt, _registry())
    verdicts = {
        (t.table, c.column): c.classification.verdict
        for t in rpt.tables for c in t.columns
    }
    assert verdicts[("D_PATIENT", "FIRST_NM")] == Verdict.NEW
    assert verdicts[("D_PATIENT", "RECORD_LAST_UPDATE_DT")] == Verdict.IGNORED
    assert verdicts[("D_PLACE", "PLACE_NM")] == Verdict.KNOWN_BUG


def test_summarize_counts_and_actionable():
    rpt = RunReport(rdb_db="RDB", modern_db="RDB_MODERN", discovered=3, skipped=1, compared=2, tables=[
        TableResult(table="D_PATIENT", columns=[
            _col("D_PATIENT", "FIRST_NM", rdb="ALICE", modern="BOB"),
            _col("D_PATIENT", "RECORD_LAST_UPDATE_DT", rdb="1", modern="2"),
        ]),
        TableResult(table="D_PLACE", columns=[_col("D_PLACE", "PLACE_NM", rdb="x", modern="y")]),
    ])
    classify_run(rpt, _registry())
    s = summarize(rpt)
    assert s["verdict_counts"][Verdict.NEW.value] == 1
    assert s["verdict_counts"][Verdict.IGNORED.value] == 1
    assert s["verdict_counts"][Verdict.KNOWN_BUG.value] == 1
    assert s["actionable_tables"] == 1  # only D_PATIENT has a NEW diff
