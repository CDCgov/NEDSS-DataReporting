from __future__ import annotations

import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))

import trace_db_cdc
import trace_db_dual_capture
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
        trace_db_dual_capture,
        "load_database_connection_defaults",
        return_value={
            "DATABASE_SERVER": "dbhost",
            "DATABASE_PORT": "1544",
            "DATABASE_USERNAME": "trace_user",
            "DATABASE_PASSWORD": "secret",
        },
    )
    def test_trace_db_dual_capture_uses_database_env_defaults(self, _: object) -> None:
        with patch("sys.argv", ["trace_db_dual_capture.py"]):
            args = trace_db_dual_capture.parse_args()

        self.assertEqual(args.server, "dbhost,1544")
        self.assertEqual(args.user, "trace_user")
        self.assertEqual(args.password, "secret")
        self.assertEqual(args.cdc_database, "NBS_ODSE")
        self.assertEqual(args.logical_database, "RDB_MODERN")

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

    def test_trace_db_logical_changes_writes_markdown_artifact(self) -> None:
        with TemporaryDirectory() as temp_dir:
            run_dir = Path(temp_dir)
            logical_changes = [
                {
                    "database": "RDB_MODERN",
                    "schema_name": "dbo",
                    "table_name": "D_PATIENT",
                    "operation": "insert",
                    "stable_identity": {
                        "strategy": "business_keys",
                        "eligible_for_comparison": True,
                        "fields": {"PATIENT_LOCAL_ID": "PAT10001"},
                    },
                    "after": {"PATIENT_LOCAL_ID": "PAT10001"},
                    "metadata": {
                        "start_lsn": "0x01",
                        "tran_end_time": "2026-04-08T12:00:01+00:00",
                        "capture_window": {
                            "start_time_utc": "2026-04-08T12:00:00+00:00",
                            "end_time_utc": "2026-04-08T12:01:00+00:00",
                            "start_lsn": "0x01",
                            "end_lsn": "0x02",
                        },
                        "action_descriptions": ["Created a patient"],
                    },
                }
            ]

            trace_db_logical_changes.write_run_artifacts(
                run_dir,
                {"database": "RDB_MODERN"},
                [],
                logical_changes,
            )

            markdown_path = run_dir / "logical-changes.md"
            self.assertTrue(markdown_path.exists())
            markdown = markdown_path.read_text(encoding="utf-8")
            self.assertIn("# Logical Change Report", markdown)
            self.assertIn("Source artifact:", markdown)
            self.assertIn("logical-changes.json", markdown)


if __name__ == "__main__":
    unittest.main()