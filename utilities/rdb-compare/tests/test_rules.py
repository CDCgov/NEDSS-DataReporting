from rdb_compare.models import CellDiff, Verdict
from rdb_compare.rules import (
    ExpectedDiffRule,
    IgnoreColumnRule,
    KnownBugRule,
    RuleRegistry,
    SkipTableRule,
)
from rdb_compare.rules import predicates as P


def cell(table="T", column="C", rdb=None, modern=None, key=(1,)):
    return CellDiff(table=table, key=key, column=column, rdb_value=rdb, modern_value=modern)


# --- name matching -----------------------------------------------------
def test_skip_table_glob_matches_case_insensitively():
    r = SkipTableRule("ETL_*", "staging table")
    assert r.matches_table("ETL_CONTROL")
    assert r.matches_table("etl_control")
    assert not r.matches_table("D_PATIENT")
    assert r.scope == "table"
    assert r.verdict == Verdict.IGNORED


def test_ignore_column_matches_suffix_glob_any_table():
    r = IgnoreColumnRule("*_LAST_UPDATE_DT", "ETL timing", category="env")
    assert r.matches_column("D_PATIENT", "RECORD_LAST_UPDATE_DT")
    assert not r.matches_column("D_PATIENT", "PATIENT_KEY")


def test_ignore_column_scoped_to_table():
    r = IgnoreColumnRule("*_KEY", "surrogate offset", table_pattern="D_PATIENT", category="key")
    assert r.matches_column("D_PATIENT", "PATIENT_KEY")
    assert not r.matches_column("D_PROVIDER", "PROVIDER_KEY")


# --- predicates --------------------------------------------------------
def test_rdb_null_modern_set_predicate():
    assert P.rdb_null_modern_set(cell(rdb=None, modern="X"))
    assert P.rdb_null_modern_set(cell(rdb="  ", modern="X"))
    assert not P.rdb_null_modern_set(cell(rdb="Y", modern="X"))
    assert not P.rdb_null_modern_set(cell(rdb=None, modern=None))


def test_null_vs_empty_predicate():
    assert P.null_vs_empty(cell(rdb=None, modern=""))
    assert P.null_vs_empty(cell(rdb="", modern=None))
    assert not P.null_vs_empty(cell(rdb="a", modern=""))


# --- registry ordering & classification --------------------------------
def test_known_bug_beats_generic_ignore_on_same_column():
    # A generic env-timestamp ignore and a specific known-bug both match;
    # the bug (base_priority 20) must win over ignore (40).
    reg = RuleRegistry([
        IgnoreColumnRule("*_DT", "env timestamp", category="env"),
        KnownBugRule("D_FOO", "BAR_DT", "bug: never populated", ticket="PDF-37"),
    ])
    cls = reg.classify_column("D_FOO", "BAR_DT", [cell(table="D_FOO", column="BAR_DT")])
    assert cls.verdict == Verdict.KNOWN_BUG
    assert cls.rule_id == "BUG-D_FOO.BAR_DT"


def test_unmatched_column_is_new():
    reg = RuleRegistry([SkipTableRule("ETL_*", "staging")])
    cls = reg.classify_column("D_PATIENT", "FIRST_NM", [cell()])
    assert cls.verdict == Verdict.NEW
    assert cls.rule_id is None


def test_predicate_rule_only_applies_when_all_cells_match():
    reg = RuleRegistry([
        ExpectedDiffRule(
            "TREATMENT", "TREATMENT_COMMENTS",
            "NULL vs empty representation only",
            predicate=P.null_vs_empty,
        ),
    ])
    # All cells fit the NULL-vs-empty pattern -> EXPECTED.
    good = [cell(table="TREATMENT", column="TREATMENT_COMMENTS", rdb=None, modern="")]
    assert reg.classify_column("TREATMENT", "TREATMENT_COMMENTS", good).verdict == Verdict.EXPECTED
    # One cell is a real value diff -> the rule does NOT apply -> NEW.
    mixed = good + [cell(table="TREATMENT", column="TREATMENT_COMMENTS", rdb="aspirin", modern="ibuprofen")]
    assert reg.classify_column("TREATMENT", "TREATMENT_COMMENTS", mixed).verdict == Verdict.NEW


def test_classify_table_returns_none_when_not_skipped():
    reg = RuleRegistry([SkipTableRule("ETL_*", "staging")])
    assert reg.classify_table("D_PATIENT") is None
    assert reg.is_skipped("ETL_CONTROL")
    assert reg.classify_table("ETL_CONTROL").verdict == Verdict.IGNORED


def test_exact_table_beats_glob_within_same_priority():
    reg = RuleRegistry([
        ExpectedDiffRule("*", "STATUS", "generic status diff", id="EXP-generic"),
        ExpectedDiffRule("D_INV", "STATUS", "specific", id="EXP-specific"),
    ])
    cls = reg.classify_column("D_INV", "STATUS", [cell(table="D_INV", column="STATUS")])
    assert cls.rule_id == "EXP-specific"
