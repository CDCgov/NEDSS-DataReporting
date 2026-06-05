import rdb_compare.db as db
from rdb_compare.discovery import discover
from rdb_compare.rules import RuleRegistry, SkipTableRule


def _fake_list_tables(monkeypatch, rdb_set, modern_set):
    """Stub rdb_compare.db.list_tables to return canned sets per database."""
    def fake(conn, database):
        return set(rdb_set) if database == "RDB" else set(modern_set)

    monkeypatch.setattr(db, "list_tables", fake)


def test_intersection_only(monkeypatch):
    _fake_list_tables(
        monkeypatch,
        rdb_set={"D_PATIENT", "INVESTIGATION", "RDB_ONLY"},
        modern_set={"D_PATIENT", "INVESTIGATION", "NRT_INVESTIGATION"},
    )
    reg = RuleRegistry()  # no skip rules
    out = discover(object(), "RDB", "RDB_MODERN", reg)
    assert out == ["D_PATIENT", "INVESTIGATION"]


def test_sorted_output(monkeypatch):
    _fake_list_tables(
        monkeypatch,
        rdb_set={"Z_TABLE", "A_TABLE", "M_TABLE"},
        modern_set={"Z_TABLE", "A_TABLE", "M_TABLE"},
    )
    out = discover(object(), "RDB", "RDB_MODERN", RuleRegistry())
    assert out == ["A_TABLE", "M_TABLE", "Z_TABLE"]


def test_skip_rule_excludes_table(monkeypatch):
    _fake_list_tables(
        monkeypatch,
        rdb_set={"D_PATIENT", "ETL_PROCESS", "S_PATIENT"},
        modern_set={"D_PATIENT", "ETL_PROCESS", "S_PATIENT"},
    )
    reg = RuleRegistry([
        SkipTableRule("ETL_*", "ETL bookkeeping"),
        SkipTableRule("S_*", "staging table"),
    ])
    out = discover(object(), "RDB", "RDB_MODERN", reg)
    assert out == ["D_PATIENT"]


def test_include_globs_keep_only_matches(monkeypatch):
    _fake_list_tables(
        monkeypatch,
        rdb_set={"D_PATIENT", "D_PROVIDER", "INVESTIGATION", "LAB_TEST"},
        modern_set={"D_PATIENT", "D_PROVIDER", "INVESTIGATION", "LAB_TEST"},
    )
    out = discover(
        object(), "RDB", "RDB_MODERN", RuleRegistry(), include=["D_*"]
    )
    assert out == ["D_PATIENT", "D_PROVIDER"]


def test_include_is_case_insensitive(monkeypatch):
    _fake_list_tables(
        monkeypatch,
        rdb_set={"D_PATIENT", "LAB_TEST"},
        modern_set={"D_PATIENT", "LAB_TEST"},
    )
    out = discover(
        object(), "RDB", "RDB_MODERN", RuleRegistry(), include=["lab_*"]
    )
    assert out == ["LAB_TEST"]


def test_exclude_globs_drop_matches(monkeypatch):
    _fake_list_tables(
        monkeypatch,
        rdb_set={"D_PATIENT", "D_PROVIDER", "LAB_TEST"},
        modern_set={"D_PATIENT", "D_PROVIDER", "LAB_TEST"},
    )
    out = discover(
        object(), "RDB", "RDB_MODERN", RuleRegistry(), exclude=["D_*"]
    )
    assert out == ["LAB_TEST"]


def test_include_and_exclude_combine(monkeypatch):
    _fake_list_tables(
        monkeypatch,
        rdb_set={"D_PATIENT", "D_PROVIDER", "D_INV_SYMPTOM"},
        modern_set={"D_PATIENT", "D_PROVIDER", "D_INV_SYMPTOM"},
    )
    out = discover(
        object(),
        "RDB",
        "RDB_MODERN",
        RuleRegistry(),
        include=["D_*"],
        exclude=["*_PROVIDER"],
    )
    assert out == ["D_INV_SYMPTOM", "D_PATIENT"]
