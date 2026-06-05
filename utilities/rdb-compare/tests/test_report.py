"""Tests for the report layer (JSON + Markdown rendering)."""

from __future__ import annotations

import json

from rdb_compare.classifier import classify_run
from rdb_compare.models import (
    CellDiff,
    ColumnDiff,
    Presence,
    RunReport,
    TableResult,
)
from rdb_compare.report import render_markdown, to_dict
from rdb_compare.rules import IgnoreColumnRule, KnownBugRule, RuleRegistry, SkipTableRule


def _col(table, name, rdb=None, modern=None):
    samples = [CellDiff(table=table, key=("PAT-1",), column=name, rdb_value=rdb, modern_value=modern)]
    return ColumnDiff(table=table, column=name, compared=10, mismatches=1, samples=samples)


def _registry():
    return RuleRegistry(
        [
            SkipTableRule("ETL_*", "staging table"),
            IgnoreColumnRule("*_LAST_UPDATE_DT", "ETL timing", category="env"),
            KnownBugRule("D_PLACE", "*", "D_PLACE not populated by RTR", ticket="PDF-bug-1"),
        ]
    )


def _classified_report():
    rpt = RunReport(
        rdb_db="RDB",
        modern_db="RDB_MODERN",
        generated_at="2026-06-05T00:00:00Z",
        discovered=3,
        skipped=1,
        compared=2,
        tables=[
            TableResult(
                table="D_PATIENT",
                presence=Presence.BOTH,
                key_columns=("PATIENT_UID",),
                rdb_count=100,
                modern_count=101,
                matched_keys=100,
                rdb_only_keys=0,
                modern_only_keys=1,
                columns=[
                    _col("D_PATIENT", "FIRST_NM", rdb="ALICE", modern="BOB"),
                    _col("D_PATIENT", "RECORD_LAST_UPDATE_DT", rdb="1", modern="2"),
                ],
            ),
            TableResult(
                table="D_PLACE",
                presence=Presence.BOTH,
                key_columns=("PLACE_UID",),
                columns=[_col("D_PLACE", "PLACE_NM", rdb="x", modern="y")],
            ),
            TableResult(
                table="ETL_CONTROL",
                presence=Presence.BOTH,
                columns=[_col("ETL_CONTROL", "BATCH_STATUS", rdb="A", modern="B")],
            ),
        ],
    )
    return classify_run(rpt, _registry())


def test_to_dict_is_json_serializable_and_round_trips():
    rpt = _classified_report()
    d = to_dict(rpt)

    # json.dumps must succeed without a custom encoder.
    text = json.dumps(d)
    back = json.loads(text)

    assert back["rdb_db"] == "RDB"
    assert back["modern_db"] == "RDB_MODERN"
    assert back["generated_at"] == "2026-06-05T00:00:00Z"
    # summarize() ignores skipped tables' columns: the skipped ETL_CONTROL table
    # contributes a single IGNORED (the table itself), not a NEW, so only the
    # genuine D_PATIENT.FIRST_NM rolls up as NEW.
    assert back["summary"]["verdict_counts"]["NEW"] == 1
    assert back["summary"]["verdict_counts"]["IGNORED"] == 2  # env column + skipped table
    assert back["summary"]["verdict_counts"]["KNOWN_BUG"] == 1

    by_name = {t["table"]: t for t in back["tables"]}
    patient = by_name["D_PATIENT"]
    # tuples became lists
    assert patient["key_columns"] == ["PATIENT_UID"]
    assert patient["presence"] == "both"
    assert patient["row_count_matches"] is False

    cols = {c["column"]: c for c in patient["columns"]}
    assert cols["FIRST_NM"]["classification"]["verdict"] == "NEW"
    assert cols["RECORD_LAST_UPDATE_DT"]["classification"]["verdict"] == "IGNORED"
    assert cols["FIRST_NM"]["samples"][0]["rdb_value"] == "ALICE"
    assert cols["FIRST_NM"]["samples"][0]["modern_value"] == "BOB"
    assert cols["FIRST_NM"]["samples"][0]["key"] == ["PAT-1"]

    # skipped table marked
    assert by_name["ETL_CONTROL"]["skipped"] is True


def test_render_markdown_has_expected_structure():
    rpt = _classified_report()
    md = render_markdown(rpt)

    # H1 title + metadata
    assert "# RDB vs RDB_MODERN Comparison Report" in md
    assert "RDB_MODERN" in md

    # Summary section + verdict labels
    assert "## Summary" in md
    assert "NEW" in md
    assert "KNOWN_BUG" in md
    assert "IGNORED" in md

    # Attention section comes first and names the NEW table + column row
    assert "## Tables needing attention (NEW differences)" in md
    assert "`D_PATIENT`" in md
    assert "FIRST_NM" in md

    # Known-bug section names the bug table
    assert "## Known-bug differences" in md
    assert "`D_PLACE`" in md

    # Skipped table is mentioned in its own section
    assert "## Skipped / ignored tables" in md
    assert "ETL_CONTROL" in md

    # NEW ordering: within D_PATIENT, FIRST_NM (NEW) precedes the IGNORED audit col
    assert md.index("FIRST_NM") < md.index("RECORD_LAST_UPDATE_DT")

    # Attention section precedes the known-bug section
    assert md.index("## Tables needing attention") < md.index("## Known-bug differences")
