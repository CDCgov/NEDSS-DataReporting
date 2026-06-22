"""Tests for argument parsing and the main entry point (no real database)."""

import json

import pytest

from functional_test import cli


def _make_test_tree(root, expected, results_match=True):
    """Create root/mytest/010-step with one query."""
    step = root / "mytest" / "010-step"
    step.mkdir(parents=True)
    (step / "setup.sql").write_text("INSERT 1")
    (step / "query.sql").write_text("SELECT a")
    (step / "expected.json").write_text(json.dumps({"0": expected}))
    return root


class FakeDatabase:
    """Replaces runner.Database; never touches a real server."""

    instances = []

    def __init__(self, host, port, user, password, database):
        self.args = (host, port, user, password, database)
        self.results = [[{"a": 1}]]
        FakeDatabase.instances.append(self)

    def execute_setup(self, sql):
        pass

    def select(self, query):
        return self.results.pop(0) if self.results else []

    def close(self):
        pass


@pytest.fixture(autouse=True)
def _no_password_env(monkeypatch):
    monkeypatch.delenv("FUNCTIONAL_TEST_DB_PASSWORD", raising=False)
    FakeDatabase.instances.clear()


class TestParser:
    def test_required_flags(self):
        parser = cli.build_parser()
        args = parser.parse_args(["-S", "host:1", "-U", "user", "-P", "pw", "-d", "/data"])
        assert args.address == "host:1"
        assert args.user == "user"
        assert args.password == "pw"
        assert str(args.data_dir) == "/data"
        assert args.tests is None

    def test_password_optional(self):
        parser = cli.build_parser()
        args = parser.parse_args(["-S", "host", "-U", "user", "-d", "/data"])
        assert args.password is None

    def test_repeated_test_flag_and_options(self):
        parser = cli.build_parser()
        args = parser.parse_args(
            ["-S", "host", "-U", "u", "-P", "p", "-d", "/data",
             "-t", "interview", "-t", "elrEColi",
             "--max-retry", "3", "--retry-delay", "0.5", "--fail-fast"]
        )
        assert args.tests == ["interview", "elrEColi"]
        assert args.max_retry == 3
        assert args.retry_delay == 0.5
        assert args.fail_fast is True

    def test_long_flag_aliases(self):
        parser = cli.build_parser()
        args = parser.parse_args(
            ["--server", "host", "--user", "u", "--password", "p", "--data-dir", "/data",
             "--test", "interview"]
        )
        assert args.address == "host"
        assert args.user == "u"
        assert args.password == "p"
        assert args.tests == ["interview"]

    def test_missing_required_args_exits(self):
        parser = cli.build_parser()
        with pytest.raises(SystemExit):
            parser.parse_args(["-S", "host", "-U", "user"])  # no -d


class TestMainListAndErrors:
    def test_list_does_not_connect(self, tmp_path, monkeypatch, capsys):
        _make_test_tree(tmp_path, [{"a": 1}])
        # Database must never be constructed for --list.
        monkeypatch.setattr(cli, "Database", _boom)
        rc = cli.main(["-S", "host", "-U", "user", "-P", "pw", "-d", str(tmp_path), "--list"])
        assert rc == 0
        out = capsys.readouterr().out
        assert "mytest" in out

    def test_bad_data_dir_returns_2(self, capsys):
        rc = cli.main(["-S", "host", "-U", "user", "-P", "pw", "-d", "/no/such/dir"])
        assert rc == 2

    def test_unknown_test_returns_2(self, tmp_path, capsys):
        _make_test_tree(tmp_path, [{"a": 1}])
        rc = cli.main(
            ["-S", "host", "-U", "user", "-P", "pw", "-d", str(tmp_path), "-t", "doesnotexist"]
        )
        assert rc == 2

    def test_no_password_without_env_returns_2(self, tmp_path, monkeypatch):
        _make_test_tree(tmp_path, [{"a": 1}])
        monkeypatch.setattr(cli, "Database", _boom)
        rc = cli.main(["-S", "host", "-U", "user", "-d", str(tmp_path)])
        assert rc == 2

    def test_password_reads_env_when_omitted(self, tmp_path, monkeypatch):
        _make_test_tree(tmp_path, [{"a": 1}])
        monkeypatch.setenv("FUNCTIONAL_TEST_DB_PASSWORD", "secret")
        monkeypatch.setattr(cli, "Database", FakeDatabase)
        rc = cli.main(["-S", "host", "-U", "user", "-d", str(tmp_path)])
        assert rc == 0
        assert FakeDatabase.instances[0].args[3] == "secret"

    def test_connection_failure_returns_2(self, tmp_path, monkeypatch):
        _make_test_tree(tmp_path, [{"a": 1}])

        def _raise(*a, **k):
            raise OSError("refused")

        monkeypatch.setattr(cli, "Database", _raise)
        rc = cli.main(["-S", "host", "-U", "user", "-P", "pw", "-d", str(tmp_path)])
        assert rc == 2


class TestMainRun:
    def test_all_pass_returns_0(self, tmp_path, monkeypatch):
        _make_test_tree(tmp_path, [{"a": 1}])
        monkeypatch.setattr(cli, "Database", FakeDatabase)
        rc = cli.main(
            ["-S", "host:1", "-U", "user", "-P", "pw", "-d", str(tmp_path), "--retry-delay", "0"]
        )
        assert rc == 0

    def test_failure_returns_1(self, tmp_path, monkeypatch):
        _make_test_tree(tmp_path, [{"a": 999}])  # expects a==999 but DB returns a==1
        monkeypatch.setattr(cli, "Database", FakeDatabase)
        rc = cli.main(
            ["-S", "host:1", "-U", "user", "-P", "pw", "-d", str(tmp_path),
             "--retry-delay", "0", "--max-retry", "1"]
        )
        assert rc == 1

    def test_passes_parsed_host_port_to_database(self, tmp_path, monkeypatch):
        _make_test_tree(tmp_path, [{"a": 1}])
        monkeypatch.setattr(cli, "Database", FakeDatabase)
        cli.main(
            ["-S", "myhost:3433", "-U", "user", "-P", "pw", "-d", str(tmp_path), "--retry-delay", "0"]
        )
        host, port, user, password, database = FakeDatabase.instances[0].args
        assert (host, port) == ("myhost", 3433)
        assert database == "NBS_ODSE"


def _boom(*args, **kwargs):
    raise AssertionError("Database should not be constructed in this path")
