from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from tracing_logical_compare import compare_logical_changes


class LogicalCompareTest(unittest.TestCase):
    def test_matches_baseline_changes_and_ignores_extra_target_changes(self) -> None:
        baseline_changes = [
            {
                "database": "RDB",
                "schema_name": "dbo",
                "table_name": "D_PATIENT",
                "operation": "insert",
                "stable_identity": {
                    "strategy": "business_keys",
                    "eligible_for_comparison": True,
                    "fields": {"PATIENT_LOCAL_ID": "PAT10001"},
                },
                "after": {
                    "PATIENT_KEY": 3,
                    "PATIENT_LOCAL_ID": "PAT10001",
                    "PATIENT_LAST_NAME": "Tester",
                    "VERSION_CTRL_NBR": 1,
                },
            },
            {
                "database": "RDB",
                "schema_name": "dbo",
                "table_name": "D_PATIENT",
                "operation": "update",
                "stable_identity": {
                    "strategy": "business_keys",
                    "eligible_for_comparison": True,
                    "fields": {"PATIENT_LOCAL_ID": "PAT10001"},
                },
                "changed_fields": {
                    "PATIENT_LAST_NAME": {"from": "Tester", "to": "Tester-Smith"},
                    "PATIENT_KEY": {"from": 3, "to": 4},
                },
                "after": {
                    "PATIENT_KEY": 4,
                    "PATIENT_LOCAL_ID": "PAT10001",
                    "PATIENT_LAST_NAME": "Tester-Smith",
                },
            },
        ]

        target_changes = [
            {
                "database": "RDB_MODERN",
                "schema_name": "dbo",
                "table_name": "D_PATIENT",
                "operation": "insert",
                "stable_identity": {
                    "strategy": "business_keys",
                    "eligible_for_comparison": True,
                    "fields": {"patient_local_id": "PAT10001"},
                },
                "after": {
                    "PATIENT_KEY": 97,
                    "PATIENT_LOCAL_ID": "PAT10001",
                    "PATIENT_LAST_NAME": "Tester",
                    "VERSION_CTRL_NBR": 1,
                    "STATUS_CD": "A",
                },
            },
            {
                "database": "RDB_MODERN",
                "schema_name": "dbo",
                "table_name": "D_PATIENT",
                "operation": "update",
                "stable_identity": {
                    "strategy": "business_keys",
                    "eligible_for_comparison": True,
                    "fields": {"PATIENT_LOCAL_ID": "PAT10001"},
                },
                "changed_fields": {
                    "PATIENT_LAST_NAME": {"from": "Tester", "to": "Tester-Smith"},
                    "PATIENT_KEY": {"from": 97, "to": 98},
                    "STATUS_CD": {"from": "A", "to": "A"},
                },
                "after": {
                    "PATIENT_KEY": 98,
                    "PATIENT_LOCAL_ID": "PAT10001",
                    "PATIENT_LAST_NAME": "Tester-Smith",
                },
            },
            {
                "database": "RDB_MODERN",
                "schema_name": "dbo",
                "table_name": "D_PATIENT",
                "operation": "insert",
                "stable_identity": {
                    "strategy": "business_keys",
                    "eligible_for_comparison": True,
                    "fields": {"PATIENT_LOCAL_ID": "PAT99999"},
                },
                "after": {
                    "PATIENT_LOCAL_ID": "PAT99999",
                    "PATIENT_LAST_NAME": "Unrelated",
                },
            },
        ]

        results = compare_logical_changes(
            baseline_changes,
            target_changes,
            "baseline/logical-changes.json",
            "target/logical-changes.json",
        )

        self.assertEqual(results["summary"]["matched_change_count"], 2)
        self.assertEqual(results["summary"]["missing_change_count"], 0)
        self.assertEqual(results["summary"]["skipped_change_count"], 0)

    def test_skips_changes_without_comparable_identity(self) -> None:
        baseline_changes = [
            {
                "database": "RDB",
                "schema_name": "dbo",
                "table_name": "Entity",
                "operation": "insert",
                "stable_identity": {
                    "strategy": "fallback_primary_key",
                    "eligible_for_comparison": False,
                    "fields": {"ENTITY_UID": 1001},
                },
                "after": {
                    "ENTITY_UID": 1001,
                    "CLASS_CD": "PSN",
                },
            }
        ]

        results = compare_logical_changes(
            baseline_changes,
            [],
            "baseline/logical-changes.json",
            "target/logical-changes.json",
        )

        self.assertEqual(results["summary"]["matched_change_count"], 0)
        self.assertEqual(results["summary"]["missing_change_count"], 0)
        self.assertEqual(results["summary"]["skipped_change_count"], 1)
        self.assertIn("not eligible", results["skipped_changes"][0]["reason"].lower())

    def test_reports_missing_when_target_payload_does_not_match(self) -> None:
        baseline_changes = [
            {
                "database": "RDB",
                "schema_name": "dbo",
                "table_name": "D_PATIENT",
                "operation": "update",
                "stable_identity": {
                    "strategy": "business_keys",
                    "eligible_for_comparison": True,
                    "fields": {"PATIENT_LOCAL_ID": "PAT10001"},
                },
                "changed_fields": {
                    "PATIENT_LAST_NAME": {"from": "Tester", "to": "Tester-Smith"},
                },
                "after": {
                    "PATIENT_LOCAL_ID": "PAT10001",
                    "PATIENT_LAST_NAME": "Tester-Smith",
                },
            }
        ]

        target_changes = [
            {
                "database": "RDB_MODERN",
                "schema_name": "dbo",
                "table_name": "D_PATIENT",
                "operation": "update",
                "stable_identity": {
                    "strategy": "business_keys",
                    "eligible_for_comparison": True,
                    "fields": {"PATIENT_LOCAL_ID": "PAT10001"},
                },
                "changed_fields": {
                    "PATIENT_LAST_NAME": {"from": "Tester", "to": "Wrong"},
                },
                "after": {
                    "PATIENT_LOCAL_ID": "PAT10001",
                    "PATIENT_LAST_NAME": "Wrong",
                },
            }
        ]

        results = compare_logical_changes(
            baseline_changes,
            target_changes,
            "baseline/logical-changes.json",
            "target/logical-changes.json",
        )

        self.assertEqual(results["summary"]["matched_change_count"], 0)
        self.assertEqual(results["summary"]["missing_change_count"], 1)
        self.assertEqual(results["missing_changes"][0]["candidate_count"], 1)
        self.assertTrue(results["missing_changes"][0]["candidate_details"])


if __name__ == "__main__":
    unittest.main()