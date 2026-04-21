from __future__ import annotations

import json
from pathlib import Path

from tracing_logical_changes import (
    SURROGATE_KEY_EXCEPTIONS,
    SURROGATE_KEY_SUFFIXES,
    normalize_column_name,
)
from tracing_replay import value_key


def is_surrogate_key_column(column_name: str) -> bool:
    normalized_name = normalize_column_name(column_name)
    if normalized_name in SURROGATE_KEY_EXCEPTIONS:
        return False
    return any(normalized_name.endswith(suffix) for suffix in SURROGATE_KEY_SUFFIXES)


def comparable_identity_key(change: dict[str, object]) -> tuple[tuple[str, str], ...] | None:
    identity = change.get("stable_identity")
    if not isinstance(identity, dict):
        return None
    if not identity.get("eligible_for_comparison"):
        return None

    fields = identity.get("fields")
    if not isinstance(fields, dict) or not fields:
        return None

    return tuple(
        sorted(
            (normalize_column_name(column_name), value_key(column_value))
            for column_name, column_value in fields.items()
        )
    )


def comparable_change_key(change: dict[str, object]) -> tuple[str, str, str, tuple[tuple[str, str], ...]] | None:
    identity_key = comparable_identity_key(change)
    if identity_key is None:
        return None

    schema_name = normalize_column_name(str(change.get("schema_name", "")))
    table_name = normalize_column_name(str(change.get("table_name", "")))
    operation = normalize_column_name(str(change.get("operation", "")))
    return (schema_name, table_name, operation, identity_key)


def normalized_identity_columns(change: dict[str, object]) -> set[str]:
    identity = change.get("stable_identity")
    if not isinstance(identity, dict):
        return set()
    fields = identity.get("fields")
    if not isinstance(fields, dict):
        return set()
    return {normalize_column_name(column_name) for column_name in fields}


def comparable_row_payload(change: dict[str, object], row_field: str) -> dict[str, object]:
    row = change.get(row_field)
    if not isinstance(row, dict):
        return {}

    identity_columns = normalized_identity_columns(change)
    comparable_values: dict[str, object] = {}
    for column_name, value in row.items():
        normalized_name = normalize_column_name(column_name)
        if normalized_name in identity_columns:
            continue
        if is_surrogate_key_column(column_name):
            continue
        comparable_values[normalized_name] = value
    return comparable_values


def comparable_changed_fields(change: dict[str, object]) -> dict[str, dict[str, object]]:
    changed_fields = change.get("changed_fields")
    if not isinstance(changed_fields, dict):
        return {}

    identity_columns = normalized_identity_columns(change)
    comparable_values: dict[str, dict[str, object]] = {}
    for column_name, value in changed_fields.items():
        normalized_name = normalize_column_name(column_name)
        if normalized_name in identity_columns:
            continue
        if is_surrogate_key_column(column_name):
            continue
        if not isinstance(value, dict):
            continue
        comparable_values[normalized_name] = {
            "from": value.get("from"),
            "to": value.get("to"),
        }
    return comparable_values


def comparable_payload(change: dict[str, object]) -> dict[str, object]:
    operation = normalize_column_name(str(change.get("operation", "")))
    if operation == "insert":
        return comparable_row_payload(change, "after")
    if operation == "delete":
        return comparable_row_payload(change, "before")
    if operation == "update":
        return comparable_changed_fields(change)
    return {}


def comparable_payload_ready(change: dict[str, object]) -> bool:
    operation = normalize_column_name(str(change.get("operation", "")))
    payload = comparable_payload(change)
    if operation == "update":
        return bool(payload)
    return True


def summarize_change(change: dict[str, object], payload: dict[str, object] | None = None) -> dict[str, object]:
    return {
        "database": change.get("database"),
        "schema_name": change.get("schema_name"),
        "table_name": change.get("table_name"),
        "operation": change.get("operation"),
        "stable_identity": change.get("stable_identity"),
        "comparable_payload": comparable_payload(change) if payload is None else payload,
    }


def build_target_index(
    target_changes: list[dict[str, object]],
) -> dict[tuple[str, str, str, tuple[tuple[str, str], ...]], list[tuple[int, dict[str, object]]]]:
    index: dict[tuple[str, str, str, tuple[tuple[str, str], ...]], list[tuple[int, dict[str, object]]]] = {}
    for change_index, change in enumerate(target_changes):
        key = comparable_change_key(change)
        if key is None:
            continue
        index.setdefault(key, []).append((change_index, change))
    return index


def compare_payloads(
    baseline_change: dict[str, object],
    target_change: dict[str, object],
) -> list[str]:
    operation = normalize_column_name(str(baseline_change.get("operation", "")))
    baseline_payload = comparable_payload(baseline_change)
    target_payload = comparable_payload(target_change)
    mismatches: list[str] = []

    if operation in {"insert", "delete"}:
        for column_name, baseline_value in baseline_payload.items():
            if column_name not in target_payload:
                mismatches.append(f"missing comparable column {column_name}")
                continue
            if target_payload[column_name] != baseline_value:
                mismatches.append(
                    f"column {column_name} expected {baseline_value!r} but found {target_payload[column_name]!r}"
                )
        return mismatches

    if operation == "update":
        for column_name, baseline_value in baseline_payload.items():
            if column_name not in target_payload:
                mismatches.append(f"missing comparable changed field {column_name}")
                continue
            target_value = target_payload[column_name]
            if not isinstance(target_value, dict):
                mismatches.append(f"changed field {column_name} is not structured correctly in target")
                continue
            if target_value.get("from") != baseline_value.get("from"):
                mismatches.append(
                    f"changed field {column_name} expected from {baseline_value.get('from')!r} but found {target_value.get('from')!r}"
                )
            if target_value.get("to") != baseline_value.get("to"):
                mismatches.append(
                    f"changed field {column_name} expected to {baseline_value.get('to')!r} but found {target_value.get('to')!r}"
                )
        return mismatches

    mismatches.append(f"unsupported operation {operation}")
    return mismatches


def compare_logical_changes(
    baseline_changes: list[dict[str, object]],
    target_changes: list[dict[str, object]],
    baseline_label: str,
    target_label: str,
) -> dict[str, object]:
    target_index = build_target_index(target_changes)
    used_target_indices: set[int] = set()
    matched_changes: list[dict[str, object]] = []
    missing_changes: list[dict[str, object]] = []
    skipped_changes: list[dict[str, object]] = []

    for baseline_index, baseline_change in enumerate(baseline_changes):
        key = comparable_change_key(baseline_change)
        if key is None:
            skipped_changes.append(
                {
                    "baseline_index": baseline_index,
                    "reason": "Stable identity is not eligible for cross-system comparison",
                    "baseline_change": summarize_change(baseline_change),
                }
            )
            continue

        if not comparable_payload_ready(baseline_change):
            skipped_changes.append(
                {
                    "baseline_index": baseline_index,
                    "reason": "No comparable non-surrogate field changes remain after filtering",
                    "baseline_change": summarize_change(baseline_change),
                }
            )
            continue

        candidates = target_index.get(key, [])
        candidate_details: list[dict[str, object]] = []
        matched_target_index: int | None = None

        for target_index_value, target_change in candidates:
            if target_index_value in used_target_indices:
                continue

            mismatches = compare_payloads(baseline_change, target_change)
            if not mismatches:
                matched_target_index = target_index_value
                used_target_indices.add(target_index_value)
                matched_changes.append(
                    {
                        "baseline_index": baseline_index,
                        "target_index": target_index_value,
                        "baseline_change": summarize_change(baseline_change),
                        "target_change": summarize_change(target_change),
                    }
                )
                break

            candidate_details.append(
                {
                    "target_index": target_index_value,
                    "mismatches": mismatches,
                    "target_change": summarize_change(target_change),
                }
            )

        if matched_target_index is None:
            missing_changes.append(
                {
                    "baseline_index": baseline_index,
                    "reason": "No target logical change matched the baseline change",
                    "candidate_count": len(candidates),
                    "candidate_details": candidate_details,
                    "baseline_change": summarize_change(baseline_change),
                }
            )

    return {
        "baseline": {
            "label": baseline_label,
            "change_count": len(baseline_changes),
        },
        "target": {
            "label": target_label,
            "change_count": len(target_changes),
        },
        "summary": {
            "baseline_change_count": len(baseline_changes),
            "target_change_count": len(target_changes),
            "matched_change_count": len(matched_changes),
            "missing_change_count": len(missing_changes),
            "skipped_change_count": len(skipped_changes),
            "comparable_baseline_change_count": len(baseline_changes) - len(skipped_changes),
        },
        "matched_changes": matched_changes,
        "missing_changes": missing_changes,
        "skipped_changes": skipped_changes,
    }


def load_logical_changes(path: Path) -> list[dict[str, object]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, list):
        raise ValueError(f"Expected a JSON array in {path}")
    for item in payload:
        if not isinstance(item, dict):
            raise ValueError(f"Expected each logical change to be an object in {path}")
    return payload


def write_compare_results(path: Path, results: dict[str, object]) -> None:
    path.write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")