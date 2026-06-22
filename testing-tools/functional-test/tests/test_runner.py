"""Tests for discovery, SQL splitting, polling and step execution."""

import json

import pytest

from functional_test import runner
from functional_test.runner import (
    _wait_for_match,
    discover_steps,
    discover_tests,
    parse_address,
    run_step,
    run_test,
    split_statements,
)


class TestSplitStatements:
    def test_empty_and_blank(self):
        assert split_statements("") == []
        assert split_statements("   \n  ") == []

    def test_single_statement(self):
        assert split_statements("SELECT 1") == ["SELECT 1"]

    def test_trailing_semicolon_no_empty_statement(self):
        assert split_statements("SELECT 1;") == ["SELECT 1"]

    def test_multiple_statements(self):
        assert split_statements("SELECT 1; SELECT 2") == ["SELECT 1", "SELECT 2"]

    def test_comment_lines_stripped(self):
        sql = "-- a comment\nSELECT 1;\n-- another\nSELECT 2"
        assert split_statements(sql) == ["SELECT 1", "SELECT 2"]

    def test_indented_comment_stripped(self):
        sql = "    -- indented comment\n    SELECT 1"
        assert split_statements(sql) == ["SELECT 1"]

    def test_blank_statements_filtered(self):
        assert split_statements("SELECT 1;;\n\n;SELECT 2;") == ["SELECT 1", "SELECT 2"]

    def test_comment_only_chunk_dropped(self):
        assert split_statements("-- only a comment") == []


class TestParseAddress:
    @pytest.mark.parametrize(
        "address,expected",
        [
            ("localhost:3433", ("localhost", 3433)),
            ("localhost,1433", ("localhost", 1433)),
            ("localhost", ("localhost", None)),
            ("10.0.0.5:1433", ("10.0.0.5", 1433)),
            ("host\\SQLEXPRESS", ("host\\SQLEXPRESS", None)),
            ("  localhost:3433  ", ("localhost", 3433)),
            ("localhost:", ("localhost", None)),
        ],
    )
    def test_parse(self, address, expected):
        assert parse_address(address) == expected


def _make_step(step_dir, setup="SELECT 1", query="SELECT 1", expected=None):
    step_dir.mkdir(parents=True, exist_ok=True)
    (step_dir / "setup.sql").write_text(setup)
    (step_dir / "query.sql").write_text(query)
    (step_dir / "expected.json").write_text(json.dumps(expected if expected is not None else {}))
    return step_dir


class TestDiscovery:
    def test_discover_tests_sorted(self, tmp_path):
        for name in ["btest", "atest", "ctest"]:
            (tmp_path / name).mkdir()
        (tmp_path / "notADir.txt").write_text("x")
        found = discover_tests(tmp_path)
        assert [p.name for p in found] == ["atest", "btest", "ctest"]

    def test_discover_tests_selected_order_and_case(self, tmp_path):
        for name in ["Interview", "elrEColi"]:
            (tmp_path / name).mkdir()
        found = discover_tests(tmp_path, ["elrecoli", "INTERVIEW"])
        assert [p.name for p in found] == ["elrEColi", "Interview"]

    def test_discover_tests_unknown_raises(self, tmp_path):
        (tmp_path / "interview").mkdir()
        with pytest.raises(ValueError, match="Unknown functional test"):
            discover_tests(tmp_path, ["nope"])

    def test_discover_tests_missing_dir_raises(self, tmp_path):
        with pytest.raises(FileNotFoundError):
            discover_tests(tmp_path / "does-not-exist")

    def test_discover_steps_sorted(self, tmp_path):
        for name in ["020-b", "010-a", "030-c"]:
            (tmp_path / name).mkdir()
        steps = discover_steps(tmp_path)
        assert [p.name for p in steps] == ["010-a", "020-b", "030-c"]


class FakeDB:
    """Duck-typed stand-in for runner.Database."""

    def __init__(self, results=None, setup_error=None):
        # results: list of result lists returned by successive select() calls
        self._results = list(results or [])
        self._setup_error = setup_error
        self.setup_calls = []
        self.select_calls = []

    def execute_setup(self, sql):
        self.setup_calls.append(sql)
        if self._setup_error:
            raise self._setup_error

    def select(self, query):
        self.select_calls.append(query)
        if self._results:
            return self._results.pop(0)
        return []


class TestWaitForMatch:
    def test_matches_immediately(self):
        db = FakeDB(results=[[{"a": 1}]])
        matched, attempts, actual = _wait_for_match(
            lambda: db.select("q"), [{"a": 1}], max_retry=3, retry_delay=0
        )
        assert matched is True
        assert attempts == 1
        assert actual == [{"a": 1}]

    def test_retries_until_match(self):
        db = FakeDB(results=[[], [{"a": 1}]])
        matched, attempts, _ = _wait_for_match(
            lambda: db.select("q"), [{"a": 1}], max_retry=5, retry_delay=0
        )
        assert matched is True
        assert attempts == 2

    def test_exhausts_retries_on_no_match(self):
        db = FakeDB(results=[[{"a": 9}], [{"a": 9}]])
        matched, attempts, actual = _wait_for_match(
            lambda: db.select("q"), [{"a": 1}], max_retry=2, retry_delay=0
        )
        assert matched is False
        assert attempts == 2
        assert actual == [{"a": 9}]

    def test_normalizes_before_compare(self):
        import datetime

        db = FakeDB(results=[[{"t": datetime.datetime(2026, 1, 1, 0, 0, 0, 5000)}]])
        matched, _, _ = _wait_for_match(
            lambda: db.select("q"),
            [{"t": "2026-01-01T00:00:00.005"}],
            max_retry=1,
            retry_delay=0,
        )
        assert matched is True


class TestRunStep:
    def test_passing_step(self, tmp_path):
        step = _make_step(
            tmp_path / "010-step",
            setup="INSERT 1",
            query="SELECT a;\nSELECT b",
            expected={"0": [{"a": 1}], "1": [{"b": 2}]},
        )
        db = FakeDB(results=[[{"a": 1}], [{"b": 2}]])
        result = run_step(db, step, max_retry=1, retry_delay=0)
        assert isinstance(result, runner.StepResult)
        assert result.passed is True
        assert db.setup_calls == ["INSERT 1"]
        assert len(result.queries) == 2
        assert all(q.passed for q in result.queries)

    def test_failing_query(self, tmp_path):
        step = _make_step(
            tmp_path / "010-step",
            query="SELECT a",
            expected={"0": [{"a": 1}]},
        )
        db = FakeDB(results=[[{"a": 999}]])
        result = run_step(db, step, max_retry=1, retry_delay=0)
        assert result.passed is False
        assert result.queries[0].passed is False
        assert result.queries[0].actual == [{"a": 999}]

    def test_setup_error_short_circuits(self, tmp_path):
        step = _make_step(tmp_path / "010-step", expected={"0": [{"a": 1}]})
        db = FakeDB(setup_error=RuntimeError("duplicate key"))
        result = run_step(db, step, max_retry=1, retry_delay=0)
        assert result.passed is False
        assert "duplicate key" in result.setup_error
        assert result.queries == []
        assert db.select_calls == []

    def test_missing_expected_entry(self, tmp_path):
        step = _make_step(
            tmp_path / "010-step",
            query="SELECT a; SELECT b",
            expected={"0": [{"a": 1}]},  # no key "1"
        )
        db = FakeDB(results=[[{"a": 1}]])
        result = run_step(db, step, max_retry=1, retry_delay=0)
        assert result.passed is False
        assert result.queries[1].error is not None
        assert "expected" in result.queries[1].error.lower()

    def test_missing_file(self, tmp_path):
        step = tmp_path / "010-step"
        step.mkdir()
        (step / "setup.sql").write_text("x")
        (step / "query.sql").write_text("x")
        # no expected.json
        db = FakeDB()
        result = run_step(db, step, max_retry=1, retry_delay=0)
        assert result.passed is False
        assert "expected.json" in result.setup_error

    def test_select_exception_recorded(self, tmp_path):
        step = _make_step(tmp_path / "010-step", query="SELECT a", expected={"0": [{"a": 1}]})

        class BoomDB(FakeDB):
            def select(self, query):
                raise RuntimeError("bad sql")

        result = run_step(BoomDB(), step, max_retry=1, retry_delay=0)
        assert result.passed is False
        assert "bad sql" in result.queries[0].error


class TestRunTest:
    def test_runs_steps_in_order(self, tmp_path):
        test_dir = tmp_path / "mytest"
        _make_step(test_dir / "020-b", query="SELECT b", expected={"0": [{"b": 2}]})
        _make_step(test_dir / "010-a", query="SELECT a", expected={"0": [{"a": 1}]})
        db = FakeDB(results=[[{"a": 1}], [{"b": 2}]])
        result = run_test(db, test_dir, max_retry=1, retry_delay=0)
        assert isinstance(result, runner.TestResult)
        assert result.passed is True
        assert [s.name for s in result.steps] == ["010-a", "020-b"]

    def test_no_steps_is_error(self, tmp_path):
        test_dir = tmp_path / "empty"
        test_dir.mkdir()
        result = run_test(FakeDB(), test_dir, max_retry=1, retry_delay=0)
        assert result.passed is False
        assert result.error == "No step directories found"
