from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from tracing_metadata import load_replay_metadata_cache, save_replay_metadata_cache
from tracing_models import UidGeneratorEntry


class ReplayMetadataCacheTest(unittest.TestCase):
    def test_core_replay_ignored_tables_round_trip(self) -> None:
        primary_keys_by_table = {
            ("dbo", "Entity"): ["entity_uid"],
            ("dbo", "EDX_patient_match"): ["EDX_patient_match_uid"],
        }
        identity_columns_by_table = {
            ("dbo", "EDX_patient_match"): ["EDX_patient_match_uid"],
        }
        foreign_keys_by_source = {
            ("dbo", "EDX_patient_match", "Patient_uid"): ("dbo", "Entity", "entity_uid"),
        }
        column_sql_types = {
            ("dbo", "Entity", "entity_uid"): "bigint",
            ("dbo", "EDX_patient_match", "EDX_patient_match_uid"): "bigint",
            ("dbo", "EDX_patient_match", "Patient_uid"): "bigint",
        }
        generated_always_columns: set[tuple[str, str, str]] = set()
        uid_generator_entries = [
            UidGeneratorEntry(class_name_cd="PERSON", type_cd="NBS", uid_prefix_cd="PSN", uid_suffix_cd="GA01")
        ]
        core_replay_ignored_tables = {
            ("dbo", "EDX_patient_match"),
            ("dbo", "EDX_entity_match"),
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            cache_file = Path(temp_dir) / "replay-metadata-NBS_ODSE.json"
            save_replay_metadata_cache(
                cache_file,
                "NBS_ODSE",
                primary_keys_by_table,
                identity_columns_by_table,
                foreign_keys_by_source,
                column_sql_types,
                generated_always_columns,
                uid_generator_entries,
                core_replay_ignored_tables,
            )

            payload = cache_file.read_text(encoding="utf-8")
            self.assertIn('"core_replay"', payload)
            self.assertIn('"ignored_tables"', payload)

            loaded = load_replay_metadata_cache(cache_file, "NBS_ODSE")

        self.assertIsNotNone(loaded)
        self.assertEqual(loaded[-1], core_replay_ignored_tables)


if __name__ == "__main__":
    unittest.main()