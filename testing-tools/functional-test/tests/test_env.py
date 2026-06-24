"""Tests for .env / environment connection defaults."""

from functional_test import env


class TestParseDotenv:
    def test_parses_key_values_and_strips_quotes(self, tmp_path):
        p = tmp_path / ".env"
        p.write_text(
            "# a comment\n"
            "\n"
            "DATABASE_SERVER=db.example\n"
            'DATABASE_PASSWORD="Pizza Is Good"\n'
            "DATABASE_USERNAME='sa'\n"
            "NOT_A_PAIR\n"
        )
        values = env.parse_dotenv(p)
        assert values == {
            "DATABASE_SERVER": "db.example",
            "DATABASE_PASSWORD": "Pizza Is Good",
            "DATABASE_USERNAME": "sa",
        }


class TestResolveServerArgument:
    def test_defaults(self):
        assert env.resolve_server_argument({}) == "localhost,3433"

    def test_uses_server_and_port(self):
        assert env.resolve_server_argument(
            {"DATABASE_SERVER": "db", "DATABASE_PORT": "1500"}
        ) == "db,1500"

    def test_server_with_comma_passes_through(self):
        assert env.resolve_server_argument({"DATABASE_SERVER": "db,9999"}) == "db,9999"

    def test_blank_falls_back_to_defaults(self):
        assert env.resolve_server_argument(
            {"DATABASE_SERVER": "  ", "DATABASE_PORT": ""}
        ) == "localhost,3433"


class TestLoadDefaults:
    def test_dotenv_then_environment_overrides(self, tmp_path, monkeypatch):
        dotenv = tmp_path / ".env"
        dotenv.write_text("DATABASE_SERVER=fromfile\nDATABASE_USERNAME=fileuser\n")
        monkeypatch.setattr(env, "find_dotenv", lambda: dotenv)
        monkeypatch.setenv("DATABASE_USERNAME", "envuser")
        monkeypatch.delenv("DATABASE_SERVER", raising=False)
        monkeypatch.delenv("DATABASE_PORT", raising=False)
        monkeypatch.delenv("DATABASE_PASSWORD", raising=False)

        defaults = env.load_database_connection_defaults()
        assert defaults["DATABASE_SERVER"] == "fromfile"  # from .env
        assert defaults["DATABASE_USERNAME"] == "envuser"  # env overrides .env

    def test_no_dotenv_uses_environment_only(self, monkeypatch):
        monkeypatch.setattr(env, "find_dotenv", lambda: None)
        for key in ("DATABASE_SERVER", "DATABASE_PORT", "DATABASE_USERNAME"):
            monkeypatch.delenv(key, raising=False)
        monkeypatch.setenv("DATABASE_PASSWORD", "secret")
        assert env.load_database_connection_defaults() == {"DATABASE_PASSWORD": "secret"}


class TestFindDotenv:
    def test_finds_in_parent_directory(self, tmp_path):
        (tmp_path / ".env").write_text("DATABASE_SERVER=x\n")
        nested = tmp_path / "a" / "b"
        nested.mkdir(parents=True)
        found = env.find_dotenv(nested)
        assert found == tmp_path / ".env"

    def test_returns_none_when_absent(self, tmp_path):
        nested = tmp_path / "a"
        nested.mkdir()
        assert env.find_dotenv(nested) is None
