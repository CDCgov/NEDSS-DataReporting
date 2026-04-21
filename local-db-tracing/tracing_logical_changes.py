from __future__ import annotations

import json
from pathlib import Path

from tracing_constants import CDC_METADATA_COLUMNS
from tracing_replay import data_columns, update_pair_key


PREFERRED_IDENTITY_COLUMNS = (
    "local_id",
    "patient_local_id",
    "person_local_id",
    "inv_local_id",
    "investigation_local_id",
    "notification_local_id",
    "organization_local_id",
    "provider_local_id",
    "event_local_id",
    "report_local_id",
    "morb_rpt_local_id",
    "observation_local_id",
    "lab_local_id",
    "place_local_id",
    "public_health_case_uid",
)

SURROGATE_KEY_SUFFIXES = (
    "_key",
    "_uid",
    "_id",
)

SURROGATE_KEY_EXCEPTIONS = {
    "public_health_case_uid",
}


def normalize_column_name(column_name: str) -> str:
    return column_name.strip().lower()


def is_empty_identity_value(value: object) -> bool:
    if value is None:
        return True
    if isinstance(value, str):
        return not value.strip()
    return False


def build_primary_key_values(
    row: dict[str, object],
    primary_key_columns: list[str],
) -> dict[str, object]:
    return {
        column_name: row[column_name]
        for column_name in primary_key_columns
        if column_name in row and not is_empty_identity_value(row[column_name])
    }


def build_stable_identity(
    row: dict[str, object],
    primary_key_columns: list[str],
) -> dict[str, object]:
    normalized_to_actual = {normalize_column_name(column_name): column_name for column_name in row}
    fields: dict[str, object] = {}

    for preferred_name in PREFERRED_IDENTITY_COLUMNS:
        actual_name = normalized_to_actual.get(preferred_name)
        if actual_name is None:
            continue
        value = row.get(actual_name)
        if is_empty_identity_value(value):
            continue
        fields[actual_name] = value

    if not fields:
        for column_name in row:
            normalized_name = normalize_column_name(column_name)
            value = row.get(column_name)
            if is_empty_identity_value(value):
                continue
            if normalized_name == "local_id" or normalized_name.endswith("_local_id"):
                fields[column_name] = value

    if fields:
        return {
            "strategy": "business_keys",
            "eligible_for_comparison": True,
            "fields": fields,
        }

    primary_key_values = build_primary_key_values(row, primary_key_columns)
    if primary_key_values:
        return {
            "strategy": "fallback_primary_key",
            "eligible_for_comparison": False,
            "fields": primary_key_values,
        }

    return {
        "strategy": "unresolved",
        "eligible_for_comparison": False,
        "fields": {},
    }


def strip_cdc_metadata(row: dict[str, object]) -> dict[str, object]:
    return {
        column_name: value
        for column_name, value in row.items()
        if column_name not in CDC_METADATA_COLUMNS
    }


def build_changed_fields(
    before_row: dict[str, object],
    after_row: dict[str, object],
) -> dict[str, dict[str, object]]:
    changed_fields: dict[str, dict[str, object]] = {}
    for column_name in sorted(set(data_columns(before_row)) | set(data_columns(after_row))):
        before_value = before_row.get(column_name)
        after_value = after_row.get(column_name)
        if before_value == after_value:
            continue
        changed_fields[column_name] = {
            "from": before_value,
            "to": after_value,
        }
    return changed_fields


def build_record_metadata(
    record: dict[str, object],
    run_metadata: dict[str, object],
) -> dict[str, object]:
    step_value = record.get("_step")
    if step_value is None:
        normalized_step: int | None = None
    else:
        try:
            normalized_step = int(step_value)
        except (TypeError, ValueError):
            normalized_step = None

    metadata = {
        "start_lsn": record.get("start_lsn"),
        "seqval": record.get("seqval"),
        "command_id": record.get("command_id"),
        "operation_code": record.get("operation_code"),
        "tran_begin_time": record.get("tran_begin_time"),
        "tran_end_time": record.get("tran_end_time"),
        "step": normalized_step,
        "capture_window": {
            "start_time_utc": run_metadata["start_time_utc"],
            "end_time_utc": run_metadata["end_time_utc"],
            "start_lsn": run_metadata["start_lsn"],
            "end_lsn": run_metadata["end_lsn"],
        },
        "action_descriptions": run_metadata["action_descriptions"],
    }
    return metadata


def build_insert_change(
    database: str,
    record: dict[str, object],
    primary_key_columns: list[str],
    run_metadata: dict[str, object],
) -> dict[str, object]:
    row = strip_cdc_metadata(record["row"])
    return {
        "database": database,
        "schema_name": record["schema_name"],
        "table_name": record["table_name"],
        "operation": "insert",
        "stable_identity": build_stable_identity(row, primary_key_columns),
        "primary_key_values": build_primary_key_values(row, primary_key_columns),
        "after": row,
        "metadata": build_record_metadata(record, run_metadata),
    }


def build_delete_change(
    database: str,
    record: dict[str, object],
    primary_key_columns: list[str],
    run_metadata: dict[str, object],
) -> dict[str, object]:
    row = strip_cdc_metadata(record["row"])
    return {
        "database": database,
        "schema_name": record["schema_name"],
        "table_name": record["table_name"],
        "operation": "delete",
        "stable_identity": build_stable_identity(row, primary_key_columns),
        "primary_key_values": build_primary_key_values(row, primary_key_columns),
        "before": row,
        "metadata": build_record_metadata(record, run_metadata),
    }


def build_update_change(
    database: str,
    before_record: dict[str, object],
    after_record: dict[str, object],
    primary_key_columns: list[str],
    run_metadata: dict[str, object],
) -> dict[str, object]:
    before_row = strip_cdc_metadata(before_record["row"])
    after_row = strip_cdc_metadata(after_record["row"])
    return {
        "database": database,
        "schema_name": after_record["schema_name"],
        "table_name": after_record["table_name"],
        "operation": "update",
        "stable_identity": build_stable_identity(after_row, primary_key_columns),
        "primary_key_values": build_primary_key_values(after_row, primary_key_columns),
        "changed_fields": build_changed_fields(before_row, after_row),
        "after": after_row,
        "metadata": build_record_metadata(after_record, run_metadata),
    }


def build_logical_changes(
    database: str,
    changes: list[dict[str, object]],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    action_descriptions: list[str],
    start_time_utc: str,
    end_time_utc: str,
    start_lsn: str,
    end_lsn: str,
) -> list[dict[str, object]]:
    run_metadata = {
        "action_descriptions": action_descriptions,
        "start_time_utc": start_time_utc,
        "end_time_utc": end_time_utc,
        "start_lsn": start_lsn,
        "end_lsn": end_lsn,
    }

    logical_changes: list[dict[str, object]] = []
    pending_updates: dict[tuple[str, str, int | None], dict[str, object]] = {}

    for record in changes:
        table_key = (str(record["schema_name"]), str(record["table_name"]))
        primary_key_columns = primary_keys_by_table.get(table_key, [])
        operation = record["operation"]

        if operation == "insert":
            logical_changes.append(build_insert_change(database, record, primary_key_columns, run_metadata))
            continue

        if operation == "delete":
            logical_changes.append(build_delete_change(database, record, primary_key_columns, run_metadata))
            continue

        if operation == "update_before":
            pending_updates[update_pair_key(record)] = record
            continue

        if operation == "update_after":
            before_record = pending_updates.pop(update_pair_key(record), None)
            if before_record is None:
                continue
            logical_changes.append(
                build_update_change(database, before_record, record, primary_key_columns, run_metadata)
            )

    return logical_changes


def write_logical_changes(path: Path, logical_changes: list[dict[str, object]]) -> None:
    path.write_text(json.dumps(logical_changes, indent=2) + "\n", encoding="utf-8")