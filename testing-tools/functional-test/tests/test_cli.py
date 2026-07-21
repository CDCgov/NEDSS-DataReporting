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
def _isolate_env(monkeypatch):
    # Neutralize any real .env / environment so tests are deterministic.
    monkeypatch.setattr(cli, "load_database_connection_defaults", lambda: {})
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

    def test_server_default_when_no_env(self):
        parser = cli.build_parser()
        args = parser.parse_args(["-d", "/data"])
        assert args.address == "localhost,3433"
        assert args.user is None
        assert args.password is None

    def test_env_defaults_populate_flags(self, monkeypatch):
        monkeypatch.setattr(
            cli,
            "load_database_connection_defaults",
            lambda: {
                "DATABASE_SERVER": "db",
                "DATABASE_PORT": "1500",
                "DATABASE_USERNAME": "sa",
                "DATABASE_PASSWORD": "pw",
            },
        )
        args = cli.build_parser().parse_args(["-d", "/data"])
        assert args.address == "db,1500"
        assert args.user == "sa"
        assert args.password == "pw"

    def test_flags_override_env_defaults(self, monkeypatch):
        monkeypatch.setattr(
            cli,
            "load_database_connection_defaults",
            lambda: {"DATABASE_USERNAME": "sa", "DATABASE_PASSWORD": "pw"},
        )
        args = cli.build_parser().parse_args(
            ["-d", "/data", "-S", "other:9", "-U", "u2", "-P", "p2"]
        )
        assert args.address == "other:9"
        assert args.user == "u2"
        assert args.password == "p2"

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

    def test_id_flag_parsed_as_int(self):
        parser = cli.build_parser()
        args = parser.parse_args(
            ["-S", "h", "-U", "u", "-P", "p", "-d", "/data", "-t", "interview", "-i", "1000014000"]
        )
        assert args.start_id == 1000014000

    def test_id_defaults_none(self):
        parser = cli.build_parser()
        args = parser.parse_args(["-S", "h", "-U", "u", "-P", "p", "-d", "/data"])
        assert args.start_id is None
        assert args.shift_id is None

    def test_shift_id_parsed_as_int(self):
        parser = cli.build_parser()
        args = parser.parse_args(["-d", "/data", "-s", "-4000"])
        assert args.shift_id == -4000
        assert args.start_id is None

    def test_id_and_shift_id_mutually_exclusive(self):
        parser = cli.build_parser()
        with pytest.raises(SystemExit):
            parser.parse_args(["-d", "/data", "-i", "1000014000", "-s", "10000"])

    def test_debug_defaults_false(self):
        parser = cli.build_parser()
        args = parser.parse_args(["-d", "/data"])
        assert args.debug is False
        args = parser.parse_args(["-d", "/data", "--debug"])
        assert args.debug is True

    def test_bulk_flags(self):
        parser = cli.build_parser()
        args = parser.parse_args(["-d", "/data"])
        assert args.bulk is None and args.bulk_out is None
        assert args.identity_base == 500_000_000
        args = parser.parse_args(
            ["-d", "/data", "--bulk", "100", "--bulk-out", "/out", "--identity-base", "7"]
        )
        assert args.bulk == 100
        assert str(args.bulk_out) == "/out"
        assert args.identity_base == 7

    def test_skip_query_defaults_false(self):
        parser = cli.build_parser()
        args = parser.parse_args(["-d", "/data"])
        assert args.skip_query is False
        args = parser.parse_args(["-d", "/data", "--skip-query"])
        assert args.skip_query is True

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

    def test_no_user_without_env_returns_2(self, tmp_path, monkeypatch):
        _make_test_tree(tmp_path, [{"a": 1}])
        monkeypatch.setattr(cli, "Database", _boom)
        rc = cli.main(["-S", "host", "-P", "pw", "-d", str(tmp_path)])
        assert rc == 2

    def test_credentials_from_env_when_omitted(self, tmp_path, monkeypatch):
        _make_test_tree(tmp_path, [{"a": 1}])
        monkeypatch.setattr(
            cli,
            "load_database_connection_defaults",
            lambda: {"DATABASE_USERNAME": "sa", "DATABASE_PASSWORD": "secret"},
        )
        monkeypatch.setattr(cli, "Database", FakeDatabase)
        rc = cli.main(["-S", "host", "-d", str(tmp_path), "--retry-delay", "0"])
        assert rc == 0
        _host, _port, user, password, _db = FakeDatabase.instances[0].args
        assert (user, password) == ("sa", "secret")

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


class TestSkipQueryFlag:
    def test_skip_query_passes_despite_mismatched_expected(self, tmp_path, monkeypatch, capsys):
        # Expected would never match FakeDatabase's result, but with --skip-query
        # the query is never run, so the test passes on setup alone.
        _make_test_tree(tmp_path, [{"a": 999}])
        monkeypatch.setattr(cli, "Database", FakeDatabase)
        rc = cli.main(
            ["-S", "h", "-U", "u", "-P", "p", "-d", str(tmp_path),
             "--retry-delay", "0", "--max-retry", "1", "--skip-query"]
        )
        out = capsys.readouterr().out
        assert rc == 0
        assert "queries skipped" in out


class TestDebugFlag:
    def test_failure_without_debug_hides_expected_actual(self, tmp_path, monkeypatch, capsys):
        _make_test_tree(tmp_path, [{"a": 999}])  # expects 999, FakeDatabase returns 1 -> fail
        monkeypatch.setattr(cli, "Database", FakeDatabase)
        rc = cli.main(
            ["-S", "h", "-U", "u", "-P", "p", "-d", str(tmp_path),
             "--retry-delay", "0", "--max-retry", "1"]
        )
        out = capsys.readouterr().out
        assert rc == 1
        assert "FAILED" in out
        assert "expected:" not in out
        assert "actual:" not in out
        assert "--debug" in out  # hint shown

    def test_failure_with_debug_shows_expected_actual(self, tmp_path, monkeypatch, capsys):
        _make_test_tree(tmp_path, [{"a": 999}])
        monkeypatch.setattr(cli, "Database", FakeDatabase)
        rc = cli.main(
            ["-S", "h", "-U", "u", "-P", "p", "-d", str(tmp_path),
             "--retry-delay", "0", "--max-retry", "1", "--debug"]
        )
        out = capsys.readouterr().out
        assert rc == 1
        assert "expected:" in out
        assert "actual:" in out
        assert "999" in out and "\"a\": 1" in out  # expected and actual values both shown


class TestMainIdFlag:
    def test_id_requires_single_test(self, tmp_path, monkeypatch):
        # Two tests, -i with no -t selects all -> error before connecting.
        _make_test_tree(tmp_path, [{"a": 1}])
        (tmp_path / "other" / "010").mkdir(parents=True)
        for fn in ("setup.sql", "query.sql"):
            (tmp_path / "other" / "010" / fn).write_text("x")
        (tmp_path / "other" / "010" / "expected.json").write_text("{}")
        monkeypatch.setattr(cli, "Database", _boom)
        rc = cli.main(["-S", "h", "-U", "u", "-P", "p", "-d", str(tmp_path), "-i", "5"])
        assert rc == 2

    def test_id_passed_to_run_test(self, tmp_path, monkeypatch):
        _make_test_tree(tmp_path, [{"a": 1}])
        monkeypatch.setattr(cli, "Database", FakeDatabase)
        captured = {}
        real_run_test = cli.run_test

        def wrapper(db, test_dir, **kwargs):
            captured.update(kwargs)
            return real_run_test(db, test_dir, **kwargs)

        monkeypatch.setattr(cli, "run_test", wrapper)
        cli.main(
            ["-S", "h", "-U", "u", "-P", "p", "-d", str(tmp_path),
             "-t", "mytest", "-i", "1000014000", "--retry-delay", "0"]
        )
        assert captured.get("new_start_id") == 1000014000

    def test_shift_id_works_with_multiple_tests(self, tmp_path, monkeypatch):
        # Two tests, -s with no -t selects all -> allowed (unlike -i).
        _make_test_tree(tmp_path, [{"a": 1}])
        other = tmp_path / "other" / "010"
        other.mkdir(parents=True)
        (other / "setup.sql").write_text("DECLARE @a bigint = 1000005000\n")
        (other / "query.sql").write_text("SELECT 1")
        (other / "expected.json").write_text("{}")
        monkeypatch.setattr(cli, "Database", FakeDatabase)
        seen = []
        real_run_test = cli.run_test

        def wrapper(db, test_dir, **kwargs):
            seen.append((test_dir.name, kwargs.get("shift_id")))
            return real_run_test(db, test_dir, **kwargs)

        monkeypatch.setattr(cli, "run_test", wrapper)
        rc = cli.main(["-S", "h", "-U", "u", "-P", "p", "-d", str(tmp_path),
                       "-s", "10000", "--retry-delay", "0"])
        assert rc != 2  # not a usage error
        assert {name for name, _ in seen} == {"mytest", "other"}
        assert all(shift == 10000 for _, shift in seen)


class TestBulkMode:
    def _make_bulk_tree(self, root):
        step = root / "mytest" / "010-step"
        step.mkdir(parents=True)
        (step / "setup.sql").write_text(
            "USE [NBS_ODSE];\n"
            "DECLARE @uid bigint = 1000001000;\n"
            "INSERT INTO [dbo].[Person] ([person_uid], [nm]) VALUES (@uid, N'x');\n"
        )
        (step / "query.sql").write_text("SELECT 1")
        (step / "expected.json").write_text("{}")
        return root

    def test_bulk_requires_bulk_out(self, tmp_path, monkeypatch):
        self._make_bulk_tree(tmp_path)
        monkeypatch.setattr(cli, "Database", _boom)
        rc = cli.main(["-d", str(tmp_path), "--bulk", "3"])
        assert rc == 2
        rc = cli.main(["-d", str(tmp_path), "--bulk-out", str(tmp_path / "o")])
        assert rc == 2

    def test_bulk_rejects_start_id(self, tmp_path, monkeypatch):
        self._make_bulk_tree(tmp_path)
        monkeypatch.setattr(cli, "Database", _boom)
        rc = cli.main(["-d", str(tmp_path), "-t", "mytest", "-i", "1000002000",
                       "--bulk", "3", "--bulk-out", str(tmp_path / "o")])
        assert rc == 2

    def test_bulk_generates_parquet_by_default(self, tmp_path, monkeypatch, capsys):
        self._make_bulk_tree(tmp_path)
        monkeypatch.setattr(cli, "Database", _boom)  # must never connect
        out = tmp_path / "out"
        rc = cli.main(["-d", str(tmp_path), "--bulk", "2", "--bulk-out", str(out),
                       "--bulk-workers", "1"])
        assert rc == 0
        assert (out / "Person__s000.parquet").exists()
        for script in ("pre.sql", "shard_000.sql", "post.sql", "load.sql", "load.sh"):
            assert (out / script).exists()
        import pyarrow.parquet as pq
        uids = pq.read_table(out / "Person__s000.parquet").to_pydict()["person_uid"]
        assert uids == ["1000001000", "1000001001"]  # copy 2 shifted by width 1
        assert "2 rows" in capsys.readouterr().out

    def test_bulk_manage_indexes_flag(self, tmp_path, monkeypatch):
        self._make_bulk_tree(tmp_path)
        monkeypatch.setattr(cli, "Database", _boom)
        out = tmp_path / "out"
        rc = cli.main(["-d", str(tmp_path), "--bulk", "1", "--bulk-out", str(out),
                       "--bulk-workers", "1", "--manage-indexes"])
        assert rc == 0
        assert "DISABLE" in (out / "pre.sql").read_text()
        assert "REBUILD" in (out / "post.sql").read_text()

    def test_bulk_duplicate_warnings_collapsed(self, tmp_path, monkeypatch, capsys):
        step = tmp_path / "mytest" / "010-step"
        step.mkdir(parents=True)
        (step / "setup.sql").write_text(
            "DECLARE @uid bigint = 1000001000;\n"
            "INSERT INTO [dbo].[Person] ([person_uid]) VALUES (@uid);\n"
            # Two identical no-match updates (seed rows) -> one collapsed line.
            "UPDATE [dbo].[Person] SET [nm] = N'x' WHERE [person_uid] = 1;\n"
            "UPDATE [dbo].[Person] SET [nm] = N'x' WHERE [person_uid] = 1;\n"
        )
        monkeypatch.setattr(cli, "Database", _boom)
        rc = cli.main(["-d", str(tmp_path), "--bulk", "1", "--bulk-out", str(tmp_path / "o")])
        out = capsys.readouterr().out
        assert rc == 0
        assert "2x mytest: UPDATE Person matched no rows" in out
        assert out.count("UPDATE Person matched no rows") == 1

    def test_bulk_eval_error_returns_2(self, tmp_path, monkeypatch, capsys):
        # No DECLARE'd block ids -> planning fails cleanly.
        _make_test_tree(tmp_path, [{"a": 1}])
        monkeypatch.setattr(cli, "Database", _boom)
        rc = cli.main(["-d", str(tmp_path), "--bulk", "2", "--bulk-out", str(tmp_path / "o")])
        assert rc == 2


def _boom(*args, **kwargs):
    raise AssertionError("Database should not be constructed in this path")
