from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))

import trace_db_cdc
import trace_db_logical_changes


class ConnectionDefaultsTest(unittest.TestCase):
    @patch.object(
        trace_db_cdc,
        "load_database_connection_defaults",
        return_value={
            "DATABASE_SERVER": "dbhost",
            "DATABASE_PORT": "1544",
            "DATABASE_USERNAME": "trace_user",
            "DATABASE_PASSWORD": "secret",
        },
    )
    def test_trace_db_cdc_uses_database_env_defaults(self, _: object) -> None:
        with patch("sys.argv", ["trace_db_cdc.py"]):
            args = trace_db_cdc.parse_args()

        self.assertEqual(args.server, "dbhost,1544")
        self.assertEqual(args.user, "trace_user")
        self.assertEqual(args.password, "secret")

    @patch.object(
        trace_db_logical_changes,
        "load_database_connection_defaults",
        return_value={
            "DATABASE_SERVER": "dbhost",
            "DATABASE_PORT": "1544",
            "DATABASE_USERNAME": "trace_user",
            "DATABASE_PASSWORD": "secret",
        },
    )
    def test_trace_db_logical_changes_uses_database_env_defaults(self, _: object) -> None:
        with patch("sys.argv", ["trace_db_logical_changes.py"]):
            args = trace_db_logical_changes.parse_args()

        self.assertEqual(args.server, "dbhost,1544")
        self.assertEqual(args.user, "trace_user")
        self.assertEqual(args.password, "secret")

    @patch.object(
        trace_db_cdc,
        "load_database_connection_defaults",
        return_value={
            "DATABASE_SERVER": "dbhost",
            "DATABASE_PORT": "1544",
            "DATABASE_USERNAME": "trace_user",
            "DATABASE_PASSWORD": "secret",
        },
    )
    def test_cli_arguments_override_database_env_defaults(self, _: object) -> None:
        with patch(
            "sys.argv",
            [
                "trace_db_cdc.py",
                "--server",
                "overridehost,9999",
                "--user",
                "override_user",
                "--password",
                "override_password",
            ],
        ):
            args = trace_db_cdc.parse_args()

        self.assertEqual(args.server, "overridehost,9999")
        self.assertEqual(args.user, "override_user")
        self.assertEqual(args.password, "override_password")


if __name__ == "__main__":
    unittest.main()