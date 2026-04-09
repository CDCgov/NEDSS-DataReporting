from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from tracing_models import KnownAssociation, UidGeneratorEntry
from tracing_metadata import DEFAULT_SUPERUSER_ID
from tracing_output import write_summary
from tracing_replay import reconstruct_sql_statements


class ReplaySqlTest(unittest.TestCase):
    def setUp(self) -> None:
        self.primary_keys_by_table = {
            ("dbo", "Security_log"): ["security_log_uid"],
            ("dbo", "Entity"): ["entity_uid"],
            ("dbo", "EDX_patient_match"): ["EDX_patient_match_uid"],
            ("dbo", "Person"): ["person_uid"],
            ("dbo", "Postal_locator"): ["postal_locator_uid"],
            ("dbo", "Entity_locator_participation"): ["entity_uid", "locator_uid"],
        }
        self.identity_columns_by_table = {
            ("dbo", "EDX_patient_match"): ["EDX_patient_match_uid"],
        }
        self.foreign_keys_by_source = {
            ("dbo", "EDX_patient_match", "Patient_uid"): ("dbo", "Entity", "entity_uid"),
            ("dbo", "Person", "person_uid"): ("dbo", "Entity", "entity_uid"),
            ("dbo", "Person", "person_parent_uid"): ("dbo", "Entity", "entity_uid"),
            ("dbo", "Entity_locator_participation", "entity_uid"): ("dbo", "Entity", "entity_uid"),
            ("dbo", "Entity_locator_participation", "locator_uid"): ("dbo", "Postal_locator", "postal_locator_uid"),
        }
        self.column_sql_types = {
            ("dbo", "Security_log", "security_log_uid"): "bigint",
            ("dbo", "Entity", "entity_uid"): "bigint",
            ("dbo", "EDX_patient_match", "EDX_patient_match_uid"): "bigint",
            ("dbo", "EDX_patient_match", "Patient_uid"): "bigint",
            ("dbo", "Person", "person_uid"): "bigint",
            ("dbo", "Person", "person_parent_uid"): "bigint",
            ("dbo", "Postal_locator", "postal_locator_uid"): "bigint",
            ("dbo", "Entity_locator_participation", "entity_uid"): "bigint",
            ("dbo", "Entity_locator_participation", "locator_uid"): "bigint",
        }
        self.uid_generator_entries = [
            UidGeneratorEntry(class_name_cd="PERSON", type_cd="NBS", uid_prefix_cd="PSN", uid_suffix_cd="GA01")
        ]
        self.known_associations: list[KnownAssociation] = []
        self.generated_always_columns: set[tuple[str, str, str]] = set()
        self.changes = [
            {
                "schema_name": "dbo",
                "table_name": "Security_log",
                "operation": "insert",
                "start_lsn": "0x01",
                "seqval": "0x01",
                "operation_code": 2,
                "row": {
                    "security_log_uid": 10000194,
                    "event_type_cd": "LOGIN_SUCCESS",
                },
            },
            {
                "schema_name": "dbo",
                "table_name": "Person_hist",
                "operation": "insert",
                "start_lsn": "0x01",
                "seqval": "0x01a",
                "operation_code": 2,
                "row": {
                    "person_uid": 10009297,
                    "version_ctrl_nbr": 1,
                },
            },
            {
                "schema_name": "dbo",
                "table_name": "Entity",
                "operation": "insert",
                "start_lsn": "0x01",
                "seqval": "0x02",
                "operation_code": 2,
                "row": {
                    "entity_uid": 10009297,
                    "class_cd": "PSN",
                },
            },
            {
                "schema_name": "dbo",
                "table_name": "Person",
                "operation": "insert",
                "start_lsn": "0x01",
                "seqval": "0x03",
                "operation_code": 2,
                "row": {
                    "person_uid": 10009297,
                    "add_time": "2026-04-07T19:30:46.130",
                    "person_parent_uid": 10009297,
                    "local_id": "PSN10067007GA01",
                    "add_user_id": 7777,
                    "first_nm": "Bart",
                    "last_nm": "Simpson",
                },
            },
            {
                "schema_name": "dbo",
                "table_name": "EDX_patient_match",
                "operation": "insert",
                "start_lsn": "0x01",
                "seqval": "0x03a",
                "operation_code": 2,
                "row": {
                    "EDX_patient_match_uid": 100092971,
                    "Patient_uid": 10009297,
                    "match_string": "123456789^DL^NY^NY^L^SIMPSON^BART",
                    "type_cd": "PAT",
                },
            },
            {
                "schema_name": "dbo",
                "table_name": "Postal_locator",
                "operation": "insert",
                "start_lsn": "0x01",
                "seqval": "0x04",
                "operation_code": 2,
                "row": {
                    "postal_locator_uid": 10009298,
                    "state_cd": "13",
                },
            },
            {
                "schema_name": "dbo",
                "table_name": "Entity_locator_participation",
                "operation": "insert",
                "start_lsn": "0x01",
                "seqval": "0x05",
                "operation_code": 2,
                "row": {
                    "entity_uid": 10009297,
                    "locator_uid": 10009298,
                    "cd": "H",
                },
            },
        ]

    def test_reconstruct_sql_uses_negative_id_seed_variables(self) -> None:
        sql = "\n".join(
            reconstruct_sql_statements(
                self.changes,
                self.primary_keys_by_table,
                self.identity_columns_by_table,
                self.foreign_keys_by_source,
                self.column_sql_types,
                self.generated_always_columns,
                self.uid_generator_entries,
                self.known_associations,
            )
        )

        self.assertNotIn("GetUid", sql)
        self.assertNotIn("MAX([postal_locator_uid])", sql)
        self.assertIn(f"DECLARE @superuser_id bigint = {DEFAULT_SUPERUSER_ID};", sql)
        self.assertIn(
            "DECLARE @superuser_id bigint = 10009282;\n\n-- Adjust the UID declarations below manually so they remain unique across other tests.\n",
            sql,
        )
        self.assertNotIn("DECLARE @dbo_Security_log_security_log_uid bigint = -1000;", sql)
        self.assertIn("DECLARE @dbo_Entity_entity_uid bigint = -1000;", sql)
        self.assertIn("DECLARE @dbo_Postal_locator_postal_locator_uid bigint = -1001;", sql)
        self.assertIn(
            "DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';",
            sql,
        )
        self.assertIn("N'2026-04-07T19:30:46.130'", sql)
        self.assertNotIn("SYSUTCDATETIME()", sql)
        self.assertIn(str(DEFAULT_SUPERUSER_ID), sql)
        self.assertIn("@superuser_id", sql)
        self.assertNotIn(", 7777,", sql)
        self.assertNotIn("INSERT INTO [dbo].[Security_log]", sql)
        self.assertNotIn("INSERT INTO [dbo].[Person_hist]", sql)
        self.assertIn(
            "VALUES (@dbo_Entity_entity_uid, @dbo_Postal_locator_postal_locator_uid, N'H');",
            sql,
        )

    def test_summary_declares_only_required_uids(self) -> None:
        manifest = {
            "database": "NBS_ODSE",
            "start_time_utc": "2026-04-07T14:08:36+00:00",
            "end_time_utc": "2026-04-07T14:09:47+00:00",
            "start_lsn": "0x01",
            "end_lsn": "0x02",
            "initially_tracked_table_count": 20,
            "enabled_tables": [],
            "skipped_tables": [],
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            summary_path = Path(temp_dir) / "summary.txt"
            write_summary(
                summary_path,
                ["Added Bart Simpson"],
                manifest,
                self.changes,
                self.primary_keys_by_table,
                self.identity_columns_by_table,
                self.foreign_keys_by_source,
                self.column_sql_types,
                self.generated_always_columns,
                self.uid_generator_entries,
                self.known_associations,
            )
            summary = summary_path.read_text(encoding="utf-8")

        self.assertIn(
            "USE [NBS_ODSE];\nDECLARE @superuser_id bigint = 10009282;\n\n-- Adjust the UID declarations below manually so they remain unique across other tests.\nDECLARE @dbo_Entity_entity_uid bigint = -1000;\nDECLARE @dbo_Postal_locator_postal_locator_uid bigint = -1001;\n",
            summary,
        )
        self.assertNotIn("Security_log_security_log_uid", summary)
        self.assertNotIn("INSERT INTO [dbo].[Security_log]", summary)
        self.assertIn("- dbo.Person_hist: 1", summary)
        self.assertNotIn("INSERT INTO [dbo].[Person_hist]", summary)
        self.assertNotIn("DECLARE @id bigint", summary)

    def test_core_replay_skips_cached_helper_tables(self) -> None:
        manifest = {
            "database": "NBS_ODSE",
            "start_time_utc": "2026-04-07T14:08:36+00:00",
            "end_time_utc": "2026-04-07T14:09:47+00:00",
            "start_lsn": "0x01",
            "end_lsn": "0x02",
            "initially_tracked_table_count": 20,
            "enabled_tables": [],
            "skipped_tables": [],
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            summary_path = Path(temp_dir) / "summary.txt"
            write_summary(
                summary_path,
                ["Added Bart Simpson"],
                manifest,
                self.changes,
                self.primary_keys_by_table,
                self.identity_columns_by_table,
                self.foreign_keys_by_source,
                self.column_sql_types,
                self.generated_always_columns,
                self.uid_generator_entries,
                self.known_associations,
                {("dbo", "EDX_patient_match")},
                "core",
            )
            summary = summary_path.read_text(encoding="utf-8")

        self.assertIn("- dbo.EDX_patient_match: 1", summary)
        self.assertIn("Tables excluded from reconstructed SQL (core replay):", summary)
        self.assertIn("- dbo.EDX_patient_match", summary)
        self.assertNotIn("INSERT INTO [dbo].[EDX_patient_match]", summary)


if __name__ == "__main__":
    unittest.main()