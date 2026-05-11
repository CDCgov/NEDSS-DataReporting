from __future__ import annotations

import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))

import replay_setup


class ReplaySetupTest(unittest.TestCase):
    def test_rewrite_setup_sql_updates_only_eligible_columns(self) -> None:
        sql = (
            "INSERT INTO [dbo].[Person] ([person_uid], [add_time], [birth_time], [last_chg_time], [record_status_time]) "
            "VALUES (1, N'2026-04-23T14:16:11.967', N'1985-03-17T00:00:00', N'2026-04-23T14:16:11.967', N'2026-04-23T14:16:11.967');\n"
            "INSERT INTO [dbo].[Person_name] ([person_uid], [as_of_date], [add_time]) "
            "VALUES (1, N'2026-04-23T00:00:00', N'2026-04-23T14:16:11.960');\n"
            "UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-23T14:16:37.777', [birth_time] = N'1985-03-17T00:00:00' WHERE [person_uid] = 1;\n"
        )

        eligible_columns = {
            ("dbo", "Person", "add_time"),
            ("dbo", "Person", "last_chg_time"),
            ("dbo", "Person", "record_status_time"),
            ("dbo", "Person_name", "as_of_date"),
            ("dbo", "Person_name", "add_time"),
        }
        column_types = {
            ("dbo", "Person", "add_time"): "datetime2",
            ("dbo", "Person", "last_chg_time"): "datetime2",
            ("dbo", "Person", "record_status_time"): "datetime2",
            ("dbo", "Person_name", "as_of_date"): "date",
            ("dbo", "Person_name", "add_time"): "datetime",
        }

        rewritten_sql, replacement_count = replay_setup.rewrite_setup_sql(sql, eligible_columns, column_types)

        self.assertEqual(replacement_count, 6)
        self.assertIn("VALUES (1, CAST(CURRENT_TIMESTAMP AS datetime2), N'1985-03-17T00:00:00', CAST(CURRENT_TIMESTAMP AS datetime2), CAST(CURRENT_TIMESTAMP AS datetime2));", rewritten_sql)
        self.assertIn("VALUES (1, CAST(CURRENT_TIMESTAMP AS date), CURRENT_TIMESTAMP);", rewritten_sql)
        self.assertIn("SET [last_chg_time] = CAST(CURRENT_TIMESTAMP AS datetime2), [birth_time] = N'1985-03-17T00:00:00'", rewritten_sql)
        self.assertIn("N'1985-03-17T00:00:00'", rewritten_sql)

    def test_resolve_database_name_prefers_use_then_env(self) -> None:
        defaults = {"DB_ODSE": "ENV_ODSE"}
        self.assertEqual(
            replay_setup.resolve_database_name(None, defaults, "USE [NBS_ODSE];\nSELECT 1;\n"),
            "NBS_ODSE",
        )
        self.assertEqual(
            replay_setup.resolve_database_name(None, defaults, "SELECT 1;\n"),
            "ENV_ODSE",
        )
        self.assertEqual(
            replay_setup.resolve_database_name("CLI_ODSE", defaults, "SELECT 1;\n"),
            "CLI_ODSE",
        )

    @patch.object(replay_setup, "fetch_column_sql_types", return_value={("dbo", "Person", "add_time"): "datetime"})
    @patch.object(replay_setup, "fetch_auto_datetime_columns", return_value={("dbo", "Person", "add_time")})
    @patch.object(replay_setup, "require_sqlcmd", return_value="sqlcmd")
    @patch.object(replay_setup, "SqlCmdClient")
    @patch.object(
        replay_setup,
        "load_database_connection_defaults",
        return_value={
            "DATABASE_SERVER": "dbhost",
            "DATABASE_PORT": "1544",
            "DATABASE_USERNAME": "trace_user",
            "DATABASE_PASSWORD": "secret",
            "DB_ODSE": "ENV_ODSE",
        },
    )
    def test_execute_setup_sql_prompts_for_mode_when_omitted(
        self,
        _: object,
        client_cls: object,
        __: object,
        ___: object,
        ____: object,
    ) -> None:
        with TemporaryDirectory() as temp_dir:
            setup_path = Path(temp_dir) / "setup.sql"
            setup_path.write_text(
                "INSERT INTO [dbo].[Person] ([person_uid], [add_time]) VALUES (1, N'2026-04-23T14:16:11.967');\n",
                encoding="utf-8",
            )
            args = SimpleNamespace(
                setup_sql=str(setup_path),
                auto_datetime_mode=None,
                server="dbhost,1544",
                database=None,
                user="trace_user",
                password="secret",
                sqlcmd="sqlcmd",
            )
            client = client_cls.return_value

            with patch("builtins.input", return_value="y"):
                exit_code = replay_setup.execute_setup_sql(args)

        self.assertEqual(exit_code, 0)
        client_cls.assert_called_once_with("sqlcmd", "dbhost,1544", "ENV_ODSE", "trace_user", "secret")
        client.query.assert_called_once()
        executed_sql = client.query.call_args.args[0]
        self.assertIn("CURRENT_TIMESTAMP", executed_sql)
        self.assertEqual(client.query.call_args.kwargs["database"], "ENV_ODSE")


if __name__ == "__main__":
    unittest.main()