from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from tracing_logical_changes import build_logical_changes, build_stable_identity


class LogicalChangesTest(unittest.TestCase):
    def test_prefers_business_identity_over_surrogate_keys(self) -> None:
        row = {
            "PATIENT_KEY": 3,
            "PATIENT_UID": 44,
            "PATIENT_LOCAL_ID": "PAT10001",
        }

        identity = build_stable_identity(row, ["PATIENT_KEY"])

        self.assertEqual(identity["strategy"], "business_keys")
        self.assertTrue(identity["eligible_for_comparison"])
        self.assertEqual(identity["fields"], {"PATIENT_LOCAL_ID": "PAT10001"})

    def test_falls_back_to_primary_key_when_no_business_identity_exists(self) -> None:
        row = {
            "BATCH_KEY": 12,
            "STATUS_CD": "ACTIVE",
        }

        identity = build_stable_identity(row, ["BATCH_KEY"])

        self.assertEqual(identity["strategy"], "fallback_primary_key")
        self.assertFalse(identity["eligible_for_comparison"])
        self.assertEqual(identity["fields"], {"BATCH_KEY": 12})

    def test_builds_insert_and_update_logical_changes(self) -> None:
        changes = [
            {
                "schema_name": "dbo",
                "table_name": "D_PATIENT",
                "operation": "insert",
                "operation_code": 2,
                "start_lsn": "0x01",
                "seqval": "0x01",
                "tran_begin_time": "2026-04-07T12:00:00+00:00",
                "tran_end_time": "2026-04-07T12:00:01+00:00",
                "command_id": 1,
                "row": {
                    "PATIENT_KEY": 3,
                    "PATIENT_LOCAL_ID": "PAT10001",
                    "PATIENT_LAST_NAME": "Tester",
                },
            },
            {
                "schema_name": "dbo",
                "table_name": "D_PATIENT",
                "operation": "update_before",
                "operation_code": 3,
                "start_lsn": "0x02",
                "seqval": "0x02",
                "tran_begin_time": "2026-04-07T12:01:00+00:00",
                "tran_end_time": "2026-04-07T12:01:01+00:00",
                "command_id": 2,
                "row": {
                    "PATIENT_KEY": 3,
                    "PATIENT_LOCAL_ID": "PAT10001",
                    "PATIENT_LAST_NAME": "Tester",
                },
            },
            {
                "schema_name": "dbo",
                "table_name": "D_PATIENT",
                "operation": "update_after",
                "operation_code": 4,
                "start_lsn": "0x02",
                "seqval": "0x02",
                "tran_begin_time": "2026-04-07T12:01:00+00:00",
                "tran_end_time": "2026-04-07T12:01:01+00:00",
                "command_id": 2,
                "row": {
                    "PATIENT_KEY": 3,
                    "PATIENT_LOCAL_ID": "PAT10001",
                    "PATIENT_LAST_NAME": "Tester-Smith",
                },
            },
        ]

        logical_changes = build_logical_changes(
            "RDB_MODERN",
            changes,
            {("dbo", "D_PATIENT"): ["PATIENT_KEY"]},
            ["Created and updated Chester Tester"],
            "2026-04-07T12:00:00+00:00",
            "2026-04-07T12:02:00+00:00",
            "0x01",
            "0x03",
        )

        self.assertEqual(len(logical_changes), 2)
        insert_change = logical_changes[0]
        update_change = logical_changes[1]

        self.assertEqual(insert_change["operation"], "insert")
        self.assertEqual(insert_change["stable_identity"]["fields"], {"PATIENT_LOCAL_ID": "PAT10001"})
        self.assertEqual(insert_change["after"]["PATIENT_LAST_NAME"], "Tester")

        self.assertEqual(update_change["operation"], "update")
        self.assertEqual(
            update_change["changed_fields"],
            {"PATIENT_LAST_NAME": {"from": "Tester", "to": "Tester-Smith"}},
        )
        self.assertEqual(update_change["after"]["PATIENT_LAST_NAME"], "Tester-Smith")


if __name__ == "__main__":
    unittest.main()