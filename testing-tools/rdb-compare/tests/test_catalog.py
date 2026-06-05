"""Tests for the default known-differences catalog.

These assert that :func:`build_default_registry` produces a healthy, populated
registry and that representative rules from each section of the "RTR reporting
differences" page classify as documented.
"""

from __future__ import annotations

from rdb_compare.models import CellDiff, Verdict
from rdb_compare.rules.catalog import (
    EXPECTED,
    IGNORE_COLUMNS,
    KNOWN_BUGS,
    SKIP_TABLES,
    build_default_registry,
)


def cell(table, column, rdb=None, modern=None, key=(1,)):
    return CellDiff(table=table, key=key, column=column, rdb_value=rdb, modern_value=modern)


# --- registry shape ----------------------------------------------------
def test_registry_is_non_empty_and_healthy():
    reg = build_default_registry()
    assert len(reg) >= 40
    # No duplicate rule ids.
    ids = [r.id for r in reg.rules]
    assert len(ids) == len(set(ids))


def test_section_lists_are_populated():
    assert len(SKIP_TABLES) >= 10
    assert len(IGNORE_COLUMNS) >= 5
    assert len(EXPECTED) >= 20
    assert len(KNOWN_BUGS) >= 30


# --- skip-list ----------------------------------------------------------
def test_skip_listed_tables_are_skipped():
    reg = build_default_registry()
    assert reg.is_skipped("ETL_DQ_LOG")
    assert reg.is_skipped("ETL_PROCESS")
    assert reg.is_skipped("EVENT_METRIC")
    # Prefix families.
    assert reg.is_skipped("S_INV_MEDICAL_HISTORY")   # staging S_
    assert reg.is_skipped("SAS_WORK_TABLE")          # SAS_
    assert reg.is_skipped("TEMP_SCRATCH")            # TEMP_
    assert reg.is_skipped("nrt_investigation")       # RDB_MODERN-only nrt_
    assert reg.is_skipped("LOOKUP_CONDITION")        # LOOKUP_
    # A real dimension table is NOT skipped.
    assert not reg.is_skipped("D_PATIENT")


# --- _KEY offset --------------------------------------------------------
def test_key_columns_are_ignored():
    reg = build_default_registry()
    c = reg.classify_column("D_INV_SYMPTOM", "D_INV_SYMPTOM_KEY",
                            [cell("D_INV_SYMPTOM", "D_INV_SYMPTOM_KEY", rdb="5", modern="8")])
    assert c.verdict == Verdict.IGNORED
    assert "offset" in c.reason.lower()


# --- environment / timestamp -------------------------------------------
def test_env_timestamp_columns_are_ignored():
    reg = build_default_registry()
    c1 = reg.classify_column("LAB_TEST", "RDB_LAST_REFRESH_TIME",
                            [cell("LAB_TEST", "RDB_LAST_REFRESH_TIME", rdb="a", modern="b")])
    assert c1.verdict == Verdict.IGNORED

    c2 = reg.classify_column("SOME_TABLE", "RECORD_LAST_REFRESH_TIME",
                            [cell("SOME_TABLE", "RECORD_LAST_REFRESH_TIME", rdb="a", modern="b")])
    assert c2.verdict == Verdict.IGNORED


# --- known bugs ---------------------------------------------------------
def test_d_place_is_known_bug():
    reg = build_default_registry()
    c = reg.classify_column("D_PLACE", "PLACE_NM",
                            [cell("D_PLACE", "PLACE_NM", rdb="x", modern=None)])
    assert c.verdict == Verdict.KNOWN_BUG
    assert c.rule_id == "BUG-D_PLACE-not_populated"


def test_d_inv_symptom_fever_is_known_bug():
    reg = build_default_registry()
    c = reg.classify_column("D_INV_SYMPTOM", "SYM_FEVER_HIGHEST_TEMP",
                            [cell("D_INV_SYMPTOM", "SYM_FEVER_HIGHEST_TEMP", rdb="102", modern=None)])
    assert c.verdict == Verdict.KNOWN_BUG


def test_org_facility_auth_null_is_known_bug():
    reg = build_default_registry()
    c = reg.classify_column("D_ORGANIZATION", "ORGANIZATION_FACILITY_AUTH",
                            [cell("D_ORGANIZATION", "ORGANIZATION_FACILITY_AUTH", rdb="NPI", modern=None)])
    assert c.verdict == Verdict.KNOWN_BUG


# --- expected differences ----------------------------------------------
def test_documented_expected_diff():
    reg = build_default_registry()
    # INV_SUMM_DATAMART notification columns: NULL in RDB, populated in modern.
    c = reg.classify_column("INV_SUMM_DATAMART", "NOTIFICATION_STATUS",
                            [cell("INV_SUMM_DATAMART", "NOTIFICATION_STATUS", rdb=None, modern="Approved")])
    assert c.verdict == Verdict.EXPECTED


def test_expected_predicate_only_applies_to_documented_shape():
    reg = build_default_registry()
    # The rule expects RDB-null/modern-set; a real value-vs-value diff should
    # NOT be absorbed and stays NEW.
    cells = [cell("INV_SUMM_DATAMART", "NOTIFICATION_STATUS", rdb="Open", modern="Approved")]
    c = reg.classify_column("INV_SUMM_DATAMART", "NOTIFICATION_STATUS", cells)
    assert c.verdict == Verdict.NEW
