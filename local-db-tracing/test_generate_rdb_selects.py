from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))

import generate_rdb_selects


class GenerateRdbSelectsTest(unittest.TestCase):
    def test_extracts_declare_block_from_inserts_sql(self) -> None:
        inserts_sql = """USE [NBS_ODSE];\nDECLARE @superuser_id bigint = 10009282;\n\n-- Adjust the UID declarations below manually so they remain unique across other tests.\nDECLARE @dbo_Entity_entity_uid bigint = -1000;\nDECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';\n\n-- dbo.Entity\nINSERT INTO [dbo].[Entity] ([entity_uid]) VALUES (@dbo_Entity_entity_uid);\n"""

        declare_lines = generate_rdb_selects.extract_declare_block(inserts_sql)

        self.assertEqual(
            declare_lines,
            [
                "DECLARE @superuser_id bigint = 10009282;",
                "",
                "-- Adjust the UID declarations below manually so they remain unique across other tests.",
                "DECLARE @dbo_Entity_entity_uid bigint = -1000;",
                "DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';",
            ],
        )

    def test_renders_select_using_local_id_variable_when_unambiguous(self) -> None:
        declare_entries = generate_rdb_selects.parse_declare_entries(
            [
                "DECLARE @dbo_Entity_entity_uid bigint = -1000;",
                "DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';",
            ]
        )
        scaffolds = generate_rdb_selects.build_scaffolds(
            [
                {
                    "schema_name": "dbo",
                    "table_name": "D_PATIENT",
                    "operation": "insert",
                    "stable_identity": {
                        "strategy": "business_keys",
                        "eligible_for_comparison": True,
                        "fields": {"PATIENT_LOCAL_ID": "PSN10067006GA01"},
                    },
                    "primary_key_values": {"PATIENT_KEY": 9},
                    "after": {"PATIENT_KEY": 9},
                }
            ],
            declare_entries,
        )

        sql, expected_map = generate_rdb_selects.render_sql(
            {
                "logical_database": "RDB_MODERN",
                "cdc_summary_file": str(generate_rdb_selects.REPO_ROOT / "summary.txt"),
                "logical_changes_file": str(generate_rdb_selects.REPO_ROOT / "logical-changes.json"),
            },
            ["DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';"],
            declare_entries,
            scaffolds,
        )

        self.assertIn("USE [RDB_MODERN];", sql)
        self.assertIn("-- Source summary: summary.txt", sql)
        self.assertIn("-- Logical changes: logical-changes.json", sql)
        self.assertIn("WHERE [PATIENT_LOCAL_ID] = @dbo_Person_local_id", sql)
        self.assertNotIn("GO", sql)
        self.assertIn("FOR JSON PATH;", sql)
        self.assertNotIn("ORDER BY 1;", sql)
        self.assertNotIn("EXPECTED_ROWS_JSON", sql)
        self.assertEqual(expected_map, {"0": [{"PATIENT_KEY": 9}]})

    def test_main_generates_output_file_from_combined_manifest(self) -> None:
        with TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paired_dir = root / "20260408-143320-NBS_ODSE-to-RDB_MODERN"
            cdc_dir = paired_dir / "cdc-NBS_ODSE"
            logical_dir = paired_dir / "logical-RDB_MODERN"
            cdc_dir.mkdir(parents=True)
            logical_dir.mkdir(parents=True)

            summary_path = cdc_dir / "summary.txt"
            summary_path.write_text(
                """Reconstructed SQL written to: inserts.sql\nRun inserts.sql directly against the source database to replay captured writes.\n""",
                encoding="utf-8",
            )
            inserts_path = cdc_dir / "inserts.sql"
            inserts_path.write_text(
                """USE [NBS_ODSE];\nDECLARE @dbo_Entity_entity_uid bigint = -1000;\nDECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';\n\n-- dbo.Person\nINSERT INTO [dbo].[Person] ([person_uid]) VALUES (@dbo_Entity_entity_uid);\n""",
                encoding="utf-8",
            )

            logical_changes_path = logical_dir / "logical-changes.json"
            logical_changes_path.write_text(
                json.dumps(
                    [
                        {
                            "schema_name": "dbo",
                            "table_name": "D_PATIENT",
                            "operation": "insert",
                            "stable_identity": {
                                "strategy": "business_keys",
                                "eligible_for_comparison": True,
                                "fields": {"PATIENT_LOCAL_ID": "PSN10067006GA01"},
                            },
                            "primary_key_values": {"PATIENT_KEY": 9},
                            "after": {"PATIENT_KEY": 9},
                        }
                    ],
                    indent=2,
                )
                + "\n",
                encoding="utf-8",
            )

            manifest_path = paired_dir / "combined-manifest.json"
            manifest_path.write_text(
                json.dumps(
                    {
                        "logical_database": "TEST_DB_NO_CACHE",
                        "cdc_summary_file": str(summary_path),
                        "cdc_inserts_file": str(inserts_path),
                        "logical_changes_file": str(logical_changes_path),
                    },
                    indent=2,
                )
                + "\n",
                encoding="utf-8",
            )

            output_path = paired_dir / "rdb-selects.sql"
            with patch("sys.argv", ["generate_rdb_selects.py", "--combined-manifest", str(manifest_path)]):
                exit_code = generate_rdb_selects.main()

            self.assertEqual(exit_code, 0)
            self.assertTrue(output_path.exists())
            sql = output_path.read_text(encoding="utf-8")
            self.assertIn("SELECT *", sql)
            self.assertIn("FROM [dbo].[D_PATIENT]", sql)
            self.assertIn("FOR JSON PATH;", sql)
            self.assertNotIn("ORDER BY 1;", sql)
            self.assertNotIn("EXPECTED_ROWS_JSON", sql)
            expected_json_path = output_path.with_name("expected.json")
            self.assertTrue(expected_json_path.exists())
            expected_map = json.loads(expected_json_path.read_text(encoding="utf-8"))
            self.assertEqual(expected_map, {"0": [{"PATIENT_KEY": 9}]})

    def test_expected_rows_json_uses_resolved_declare_values(self) -> None:
        declare_entries = generate_rdb_selects.parse_declare_entries(
            [
                "DECLARE @dbo_Entity_entity_uid bigint = -2222;",
                "DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';",
            ]
        )
        scaffolds = generate_rdb_selects.build_scaffolds(
            [
                {
                    "schema_name": "dbo",
                    "table_name": "D_PATIENT",
                    "operation": "insert",
                    "stable_identity": {
                        "strategy": "business_keys",
                        "eligible_for_comparison": True,
                        "fields": {"PATIENT_LOCAL_ID": "PSN10067010GA01"},
                    },
                    "primary_key_values": {"PATIENT_KEY": 16},
                    "after": {
                        "PATIENT_KEY": 16,
                        "PATIENT_UID": 10009314,
                        "PATIENT_MPR_UID": 10009314,
                        "PATIENT_LOCAL_ID": "PSN10067010GA01",
                    },
                }
            ],
            declare_entries,
        )

        sql, expected_map = generate_rdb_selects.render_sql(
            {
                "logical_database": "RDB_MODERN",
                "cdc_summary_file": str(generate_rdb_selects.REPO_ROOT / "summary.txt"),
                "logical_changes_file": str(generate_rdb_selects.REPO_ROOT / "logical-changes.json"),
            },
            [
                "DECLARE @dbo_Entity_entity_uid bigint = -2222;",
                "DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';",
            ],
            declare_entries,
            scaffolds,
        )

        self.assertNotIn("EXPECTED_ROWS_JSON", sql)
        self.assertEqual(
            expected_map,
            {"0": [{"PATIENT_KEY": 16, "PATIENT_UID": -2222, "PATIENT_MPR_UID": -2222, "PATIENT_LOCAL_ID": "PSN2222GA01"}]},
        )

    def test_generated_always_columns_are_excluded_from_select_and_expected_json(self) -> None:
        declare_entries = generate_rdb_selects.parse_declare_entries(
            [
                "DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN1234GA01';",
            ]
        )
        scaffolds = generate_rdb_selects.build_scaffolds(
            [
                {
                    "schema_name": "dbo",
                    "table_name": "nrt_patient",
                    "operation": "insert",
                    "stable_identity": {
                        "strategy": "business_keys",
                        "eligible_for_comparison": True,
                        "fields": {"local_id": "PSN1234GA01"},
                    },
                    "primary_key_values": {},
                    "after": {
                        "local_id": "PSN1234GA01",
                        "patient_uid": 1234,
                        "refresh_datetime": "2026-04-10T12:39:25.8253214",
                    },
                }
            ],
            declare_entries,
        )

        sql, expected_map = generate_rdb_selects.render_sql(
            {
                "logical_database": "RDB_MODERN",
                "cdc_summary_file": str(generate_rdb_selects.REPO_ROOT / "summary.txt"),
                "logical_changes_file": str(generate_rdb_selects.REPO_ROOT / "logical-changes.json"),
            },
            ["DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN1234GA01';"],
            declare_entries,
            scaffolds,
            columns_by_table={
                ("dbo", "nrt_patient"): ["local_id", "patient_uid", "refresh_datetime"],
            },
            generated_always_columns={
                ("dbo", "nrt_patient", "refresh_datetime"),
            },
        )

        self.assertIn("SELECT", sql)
        self.assertIn("    [local_id],", sql)
        self.assertIn("    [patient_uid]", sql)
        self.assertNotIn("[refresh_datetime]", sql)
        self.assertNotIn("EXPECTED_ROWS_JSON", sql)
        self.assertEqual(expected_map, {"0": [{"local_id": "PSN1234GA01", "patient_uid": 1234}]})
        self.assertNotIn("refresh_datetime", sql)

    def test_auto_datetime_columns_are_excluded_from_select_and_expected_json(self) -> None:
        declare_entries = generate_rdb_selects.parse_declare_entries(
            [
                "DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN1234GA01';",
            ]
        )
        scaffolds = generate_rdb_selects.build_scaffolds(
            [
                {
                    "schema_name": "dbo",
                    "table_name": "nrt_patient_key",
                    "operation": "insert",
                    "stable_identity": {
                        "strategy": "business_keys",
                        "eligible_for_comparison": True,
                        "fields": {"d_patient_key": 4},
                    },
                    "primary_key_values": {},
                    "after": {
                        "patient_uid": 1234,
                        "created_dttm": "2026-04-10T12:39:31.3500000",
                        "updated_dttm": "2026-04-10T12:39:31.3500000",
                    },
                }
            ],
            declare_entries,
        )

        sql, expected_map = generate_rdb_selects.render_sql(
            {
                "logical_database": "RDB_MODERN",
                "cdc_summary_file": str(generate_rdb_selects.REPO_ROOT / "summary.txt"),
                "logical_changes_file": str(generate_rdb_selects.REPO_ROOT / "logical-changes.json"),
            },
            ["DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN1234GA01';"],
            declare_entries,
            scaffolds,
            columns_by_table={
                ("dbo", "nrt_patient_key"): ["patient_uid", "created_dttm", "updated_dttm"],
            },
            auto_datetime_defaults={
                ("dbo", "nrt_patient_key", "created_dttm"),
                ("dbo", "nrt_patient_key", "updated_dttm"),
            },
        )

        self.assertIn("SELECT", sql)
        self.assertIn("    [patient_uid]", sql)
        self.assertNotIn("[created_dttm]", sql)
        self.assertNotIn("[updated_dttm]", sql)
        self.assertNotIn("EXPECTED_ROWS_JSON", sql)
        self.assertEqual(expected_map, {"0": [{"patient_uid": 1234}]})

    def test_known_refresh_timestamps_are_excluded_from_select_and_expected_json(self) -> None:
        declare_entries = generate_rdb_selects.parse_declare_entries(
            [
                "DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN1234GA01';",
            ]
        )
        scaffolds = generate_rdb_selects.build_scaffolds(
            [
                {
                    "schema_name": "dbo",
                    "table_name": "LAB_REPORT",
                    "operation": "insert",
                    "stable_identity": {
                        "strategy": "business_keys",
                        "eligible_for_comparison": True,
                        "fields": {"PATIENT_LOCAL_ID": "PSN1234GA01"},
                    },
                    "primary_key_values": {},
                    "after": {
                        "PATIENT_LOCAL_ID": "PSN1234GA01",
                        "RDB_LAST_REFRESH_TIME": "2026-04-23T12:34:56",
                        "LAB_RPT_LAST_UPDATE_DT": "2026-04-23T12:35:56",
                        "RESULT_STATUS": "FINAL",
                    },
                }
            ],
            declare_entries,
        )

        sql = generate_rdb_selects.render_sql(
            {
                "logical_database": "RDB_MODERN",
                "cdc_summary_file": str(generate_rdb_selects.REPO_ROOT / "summary.txt"),
                "logical_changes_file": str(generate_rdb_selects.REPO_ROOT / "logical-changes.json"),
            },
            ["DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN1234GA01';"],
            declare_entries,
            scaffolds,
            columns_by_table={
                ("dbo", "LAB_REPORT"): [
                    "PATIENT_LOCAL_ID",
                    "RDB_LAST_REFRESH_TIME",
                    "LAB_RPT_LAST_UPDATE_DT",
                    "RESULT_STATUS",
                ],
            },
        )

        self.assertIn("SELECT", sql)
        self.assertIn("    [PATIENT_LOCAL_ID],", sql)
        self.assertIn("    [RESULT_STATUS]", sql)
        self.assertNotIn("[RDB_LAST_REFRESH_TIME]", sql)
        self.assertNotIn("[LAB_RPT_LAST_UPDATE_DT]", sql)
        self.assertIn('-- EXPECTED_ROWS_JSON:\n-- [{"PATIENT_LOCAL_ID":"PSN1234GA01","RESULT_STATUS":"FINAL"}]', sql)
        self.assertNotIn("RDB_LAST_REFRESH_TIME", sql)
        self.assertNotIn("LAB_RPT_LAST_UPDATE_DT", sql)

    def test_expected_rows_json_maps_ambiguous_entity_uid_candidates_deterministically(self) -> None:
        declare_entries = generate_rdb_selects.parse_declare_entries(
            [
                "DECLARE @dbo_Entity_entity_uid bigint = 9999;",
                "DECLARE @dbo_Entity_entity_uid_2 bigint = 10002;",
                "DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';",
            ]
        )

        expected_json = generate_rdb_selects.expected_rows_json(
            (
                {"PATIENT_LOCAL_ID": "PSN9999GA01", "PATIENT_MPR_UID": 10009290, "PATIENT_UID": 10009290},
                {"PATIENT_LOCAL_ID": "PSN9999GA01", "PATIENT_MPR_UID": 10009290, "PATIENT_UID": 10009293},
            ),
            declare_entries,
            excluded_columns=set(),
            output_column_order=None,
        )

        self.assertIn('"PATIENT_MPR_UID":9999', expected_json)
        self.assertIn('"PATIENT_UID":9999', expected_json)
        self.assertIn('"PATIENT_UID":10002', expected_json)


    def test_predicate_for_field_cycles_ambiguous_candidates_round_robin(self) -> None:
        declare_entries = generate_rdb_selects.parse_declare_entries(
            [
                "DECLARE @dbo_Act_act_uid bigint = 7784;",
                "DECLARE @dbo_Observation_local_id nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid))) + N'GA01';",
                "DECLARE @dbo_Observation_local_id_2 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid + 1))) + N'GA01';",
                "DECLARE @dbo_Observation_local_id_3 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid + 2))) + N'GA01';",
            ]
        )

        ambiguity_state: dict[tuple[str, tuple[str, ...]], int] = {}
        first_predicate, _ = generate_rdb_selects.predicate_for_field(
            "LOCAL_ID",
            "OBS10001016GA01",
            declare_entries,
            ambiguity_state,
        )
        second_predicate, _ = generate_rdb_selects.predicate_for_field(
            "LOCAL_ID",
            "OBS10001016GA01",
            declare_entries,
            ambiguity_state,
        )
        third_predicate, _ = generate_rdb_selects.predicate_for_field(
            "LOCAL_ID",
            "OBS10001016GA01",
            declare_entries,
            ambiguity_state,
        )

        self.assertEqual(first_predicate, "[LOCAL_ID] = @dbo_Observation_local_id")
        self.assertEqual(second_predicate, "[LOCAL_ID] = @dbo_Observation_local_id_2")
        self.assertEqual(third_predicate, "[LOCAL_ID] = @dbo_Observation_local_id_3")

    def test_render_sql_includes_step_comment_for_single_step(self) -> None:
        declare_entries = generate_rdb_selects.parse_declare_entries([])
        scaffolds = generate_rdb_selects.build_scaffolds(
            [
                {
                    "schema_name": "dbo",
                    "table_name": "D_PATIENT",
                    "operation": "insert",
                    "stable_identity": {
                        "strategy": "business_keys",
                        "eligible_for_comparison": True,
                        "fields": {"PATIENT_LOCAL_ID": "PSN10067006GA01"},
                    },
                    "primary_key_values": {"PATIENT_KEY": 9},
                    "after": {"PATIENT_KEY": 9},
                    "metadata": {"step": 1},
                }
            ],
            declare_entries,
        )

        sql, _expected_map = generate_rdb_selects.render_sql(
            {
                "logical_database": "RDB_MODERN",
                "cdc_summary_file": str(generate_rdb_selects.REPO_ROOT / "summary.txt"),
                "logical_changes_file": str(generate_rdb_selects.REPO_ROOT / "logical-changes.json"),
            },
            [],
            declare_entries,
            scaffolds,
        )

        self.assertIn("-- Step: 1", sql)

    def test_render_sql_includes_steps_comment_for_multi_step_scaffold(self) -> None:
        declare_entries = generate_rdb_selects.parse_declare_entries([])
        scaffolds = generate_rdb_selects.build_scaffolds(
            [
                {
                    "schema_name": "dbo",
                    "table_name": "D_PATIENT",
                    "operation": "insert",
                    "stable_identity": {
                        "strategy": "business_keys",
                        "eligible_for_comparison": True,
                        "fields": {"PATIENT_LOCAL_ID": "PSN10067006GA01"},
                    },
                    "primary_key_values": {"PATIENT_KEY": 9},
                    "after": {"PATIENT_KEY": 9},
                    "metadata": {"step": 1},
                },
                {
                    "schema_name": "dbo",
                    "table_name": "D_PATIENT",
                    "operation": "update",
                    "stable_identity": {
                        "strategy": "business_keys",
                        "eligible_for_comparison": True,
                        "fields": {"PATIENT_LOCAL_ID": "PSN10067006GA01"},
                    },
                    "primary_key_values": {"PATIENT_KEY": 9},
                    "after": {"PATIENT_KEY": 9, "PATIENT_LAST_NAME": "Tester-Smith"},
                    "metadata": {"step": 2},
                },
            ],
            declare_entries,
        )

        sql, _expected_map = generate_rdb_selects.render_sql(
            {
                "logical_database": "RDB_MODERN",
                "cdc_summary_file": str(generate_rdb_selects.REPO_ROOT / "summary.txt"),
                "logical_changes_file": str(generate_rdb_selects.REPO_ROOT / "logical-changes.json"),
            },
            [],
            declare_entries,
            scaffolds,
        )

        self.assertIn("-- Steps: 1, 2", sql)

    def test_generate_rdb_selects_writes_cumulative_step_query_files(self) -> None:
        with TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paired_dir = root / "20260408-143320-NBS_ODSE-to-RDB_MODERN"
            cdc_dir = paired_dir / "cdc-NBS_ODSE"
            logical_dir = paired_dir / "logical-RDB_MODERN"
            cdc_dir.mkdir(parents=True)
            logical_dir.mkdir(parents=True)

            summary_path = cdc_dir / "summary.txt"
            summary_path.write_text(
                """Reconstructed SQL written to: inserts.sql\nRun inserts.sql directly against the source database to replay captured writes.\n""",
                encoding="utf-8",
            )
            inserts_path = cdc_dir / "inserts.sql"
            inserts_path.write_text(
                """USE [NBS_ODSE];\nDECLARE @dbo_Entity_entity_uid bigint = -1000;\nDECLARE @dbo_Person_local_id nvarchar(40) = N'PSN1000GA01';\n\n-- STEP 1: Create patient\n-- step: 1\nINSERT INTO [dbo].[Person] ([person_uid]) VALUES (@dbo_Entity_entity_uid);\n""",
                encoding="utf-8",
            )

            logical_changes_path = logical_dir / "logical-changes.json"
            logical_changes_path.write_text(
                json.dumps(
                    [
                        {
                            "schema_name": "dbo",
                            "table_name": "D_PATIENT",
                            "operation": "insert",
                            "stable_identity": {
                                "strategy": "business_keys",
                                "eligible_for_comparison": True,
                                "fields": {"PATIENT_LOCAL_ID": "PSN1000GA01"},
                            },
                            "primary_key_values": {"PATIENT_KEY": 9},
                            "after": {"PATIENT_KEY": 9, "PATIENT_LOCAL_ID": "PSN1000GA01", "PATIENT_LAST_NAME": "Alpha"},
                            "metadata": {"step": 1},
                        },
                        {
                            "schema_name": "dbo",
                            "table_name": "D_PATIENT",
                            "operation": "update",
                            "stable_identity": {
                                "strategy": "business_keys",
                                "eligible_for_comparison": True,
                                "fields": {"PATIENT_LOCAL_ID": "PSN1000GA01"},
                            },
                            "primary_key_values": {"PATIENT_KEY": 9},
                            "after": {"PATIENT_KEY": 9, "PATIENT_LOCAL_ID": "PSN1000GA01", "PATIENT_LAST_NAME": "Beta"},
                            "metadata": {"step": 2},
                        },
                    ],
                    indent=2,
                )
                + "\n",
                encoding="utf-8",
            )

            manifest_path = paired_dir / "combined-manifest.json"
            manifest_path.write_text(
                json.dumps(
                    {
                        "logical_database": "TEST_DB_NO_CACHE",
                        "cdc_summary_file": str(summary_path),
                        "cdc_inserts_file": str(inserts_path),
                        "logical_changes_file": str(logical_changes_path),
                        "steps": [
                            {"step": 1, "description": "Create patient"},
                            {"step": 2, "description": "Update patient"},
                        ],
                    },
                    indent=2,
                )
                + "\n",
                encoding="utf-8",
            )

            output_path, scaffold_count = generate_rdb_selects.generate_rdb_selects_from_manifest(manifest_path)

            step1_sql = (logical_dir / "step-1" / "query.sql").read_text(encoding="utf-8")
            step2_sql = (logical_dir / "step-2" / "query.sql").read_text(encoding="utf-8")
            final_sql = output_path.read_text(encoding="utf-8")

        self.assertEqual(scaffold_count, 1)
        self.assertIn('"PATIENT_LAST_NAME":"Alpha"', step1_sql)
        self.assertNotIn('"PATIENT_LAST_NAME":"Beta"', step1_sql)
        self.assertIn('"PATIENT_LAST_NAME":"Beta"', step2_sql)
        self.assertIn('"PATIENT_LAST_NAME":"Beta"', final_sql)


if __name__ == "__main__":
    unittest.main()

