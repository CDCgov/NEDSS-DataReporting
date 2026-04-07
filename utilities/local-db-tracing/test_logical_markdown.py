from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from tracing_logical_markdown import render_logical_changes_markdown


class LogicalMarkdownTest(unittest.TestCase):
    def test_renders_summary_and_changes(self) -> None:
        logical_changes = [
            {
                "database": "NBS_ODSE",
                "schema_name": "dbo",
                "table_name": "Person",
                "operation": "insert",
                "stable_identity": {
                    "strategy": "business_keys",
                    "eligible_for_comparison": True,
                    "fields": {"local_id": "PSN10067007GA01"},
                },
                "after": {
                    "local_id": "PSN10067007GA01",
                    "first_nm": "Bart",
                    "last_nm": "Simpson",
                },
                "metadata": {
                    "start_lsn": "0x01",
                    "tran_end_time": "2026-04-07T14:11:05.230",
                    "capture_window": {
                        "start_time_utc": "2026-04-07T14:10:35+00:00",
                        "end_time_utc": "2026-04-07T14:11:48+00:00",
                        "start_lsn": "0x01",
                        "end_lsn": "0x02",
                    },
                    "action_descriptions": ["Added a vaccine"],
                },
            },
            {
                "database": "NBS_ODSE",
                "schema_name": "dbo",
                "table_name": "Person",
                "operation": "update",
                "stable_identity": {
                    "strategy": "business_keys",
                    "eligible_for_comparison": True,
                    "fields": {"local_id": "PSN10067007GA01"},
                },
                "changed_fields": {
                    "last_nm": {"from": "Simpson", "to": "Simpson-Smith"}
                },
                "after": {
                    "local_id": "PSN10067007GA01",
                    "first_nm": "Bart",
                    "last_nm": "Simpson-Smith",
                },
                "metadata": {
                    "start_lsn": "0x02",
                    "tran_end_time": "2026-04-07T14:12:05.230",
                },
            },
        ]

        markdown = render_logical_changes_markdown(logical_changes, "sample/logical-changes.json")

        self.assertIn("# Logical Change Report", markdown)
        self.assertIn("Source artifact: sample/logical-changes.json", markdown)
        self.assertIn("- Database: NBS_ODSE", markdown)
        self.assertIn("- Total logical changes: 2", markdown)
        self.assertIn("- dbo.Person: 2", markdown)
        self.assertIn("## 1. INSERT dbo.Person", markdown)
        self.assertIn("## 2. UPDATE dbo.Person", markdown)
        self.assertIn("### Inserted Row", markdown)
        self.assertIn("### Changed Fields", markdown)
        self.assertIn("### Row After Change", markdown)
        self.assertIn("| Field | Value |", markdown)
        self.assertIn("| Field | Before | After |", markdown)
        self.assertIn("| last_nm | \"Simpson\" | \"Simpson-Smith\" |", markdown)

    def test_renders_empty_artifact(self) -> None:
        markdown = render_logical_changes_markdown([], "sample/logical-changes.json")

        self.assertIn("# Logical Change Report", markdown)
        self.assertIn("No logical changes were captured.", markdown)


if __name__ == "__main__":
    unittest.main()