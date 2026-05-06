from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

from tracing_logical_compare import load_logical_changes


def format_json_value(value: object) -> str:
    return json.dumps(value, ensure_ascii=True, sort_keys=True)


def escape_markdown_cell(value: object) -> str:
    return format_json_value(value).replace("|", "\\|")


def format_table_name(change: dict[str, object]) -> str:
    return f"{change.get('schema_name', '?')}.{change.get('table_name', '?')}"


def format_identity(change: dict[str, object]) -> str:
    stable_identity = change.get("stable_identity")
    if not isinstance(stable_identity, dict):
        return "unavailable"

    strategy = stable_identity.get("strategy", "unknown")
    fields = stable_identity.get("fields")
    if not isinstance(fields, dict) or not fields:
        return f"{strategy}: unavailable"

    rendered_fields = ", ".join(
        f"{column_name}={format_json_value(value)}" for column_name, value in sorted(fields.items())
    )
    return f"{strategy}: {rendered_fields}"


def format_metadata_value(change: dict[str, object], key: str) -> str:
    metadata = change.get("metadata")
    if not isinstance(metadata, dict):
        return "unknown"
    value = metadata.get(key)
    return "unknown" if value in (None, "") else str(value)


def format_capture_window(change: dict[str, object]) -> str:
    metadata = change.get("metadata")
    if not isinstance(metadata, dict):
        return "unknown"
    capture_window = metadata.get("capture_window")
    if not isinstance(capture_window, dict):
        return "unknown"

    start_time = capture_window.get("start_time_utc", "unknown")
    end_time = capture_window.get("end_time_utc", "unknown")
    start_lsn = capture_window.get("start_lsn", "unknown")
    end_lsn = capture_window.get("end_lsn", "unknown")
    return f"{start_time} to {end_time} (LSN {start_lsn} -> {end_lsn})"


def format_action_descriptions(change: dict[str, object]) -> list[str]:
    metadata = change.get("metadata")
    if not isinstance(metadata, dict):
        return []
    action_descriptions = metadata.get("action_descriptions")
    if not isinstance(action_descriptions, list):
        return []
    return [str(item) for item in action_descriptions if str(item).strip()]


def format_row_block(row: dict[str, object]) -> list[str]:
    lines: list[str] = []
    for column_name, value in sorted(row.items()):
        lines.append(f"- {column_name}: {format_json_value(value)}")
    return lines


def render_field_value_table(row: dict[str, object]) -> list[str]:
    lines = ["| Field | Value |", "| --- | --- |"]
    for column_name, value in sorted(row.items()):
        lines.append(f"| {column_name} | {escape_markdown_cell(value)} |")
    return lines


def render_changed_fields_table(changed_fields: dict[str, object]) -> list[str]:
    lines = ["| Field | Before | After |", "| --- | --- | --- |"]
    for column_name, values in sorted(changed_fields.items()):
        if not isinstance(values, dict):
            continue
        lines.append(
            "| "
            f"{column_name} | {escape_markdown_cell(values.get('from'))} | {escape_markdown_cell(values.get('to'))} |"
        )
    return lines


def render_run_summary_table(
    database_name: object,
    capture_window: str,
    logical_change_count: int,
    insert_count: int,
    update_count: int,
    delete_count: int,
    action_descriptions: list[str],
) -> list[str]:
    source_actions = "<br>".join(action_descriptions) if action_descriptions else "None recorded"
    return [
        "| Metric | Value |",
        "| --- | --- |",
        f"| Database | {database_name} |",
        f"| Capture window | {capture_window} |",
        f"| Total logical changes | {logical_change_count} |",
        f"| Inserts | {insert_count} |",
        f"| Updates | {update_count} |",
        f"| Deletes | {delete_count} |",
        f"| Source actions | {source_actions} |",
    ]


def render_tables_touched_table(table_counts: Counter[str]) -> list[str]:
    lines = ["| Table | Change count |", "| --- | --- |"]
    for table_name, change_count in sorted(table_counts.items()):
        lines.append(f"| {table_name} | {change_count} |")
    return lines


def render_change_metadata_table(change: dict[str, object]) -> list[str]:
    return [
        "| Metric | Value |",
        "| --- | --- |",
        f"| Identity | {format_identity(change)} |",
        f"| Transaction end | {format_metadata_value(change, 'tran_end_time')} |",
        f"| LSN | {format_metadata_value(change, 'start_lsn')} |",
    ]


def render_change(change: dict[str, object], change_number: int) -> list[str]:
    operation = str(change.get("operation", "unknown")).upper()
    lines = [f"## {change_number}. {operation} {format_table_name(change)}", ""]
    lines.extend(render_change_metadata_table(change))
    lines.append("")

    if operation == "UPDATE":
        changed_fields = change.get("changed_fields")
        if isinstance(changed_fields, dict) and changed_fields:
            lines.append("### Changed Fields")
            lines.append("")
            lines.extend(render_changed_fields_table(changed_fields))
            lines.append("")

        after_row = change.get("after")
        if isinstance(after_row, dict) and after_row:
            lines.append("### Row After Change")
            lines.append("")
            lines.extend(render_field_value_table(after_row))

    if operation == "INSERT":
        after_row = change.get("after")
        if isinstance(after_row, dict) and after_row:
            lines.append("### Inserted Row")
            lines.append("")
            lines.extend(render_field_value_table(after_row))

    if operation == "DELETE":
        before_row = change.get("before")
        if isinstance(before_row, dict) and before_row:
            lines.append("### Deleted Row")
            lines.append("")
            lines.extend(render_field_value_table(before_row))

    lines.append("")
    return lines


def render_logical_changes_markdown(logical_changes: list[dict[str, object]], source_label: str) -> str:
    lines: list[str] = ["# Logical Change Report", ""]
    lines.append(f"Source artifact: {source_label}")
    lines.append("")

    if not logical_changes:
        lines.append("No logical changes were captured.")
        lines.append("")
        return "\n".join(lines)

    first_change = logical_changes[0]
    database_name = first_change.get("database", "unknown")
    action_descriptions = format_action_descriptions(first_change)
    operation_counts = Counter(str(change.get("operation", "unknown")).lower() for change in logical_changes)
    table_counts = Counter(format_table_name(change) for change in logical_changes)

    lines.append("## Run Summary")
    lines.append("")
    lines.extend(
        render_run_summary_table(
            database_name,
            format_capture_window(first_change),
            len(logical_changes),
            operation_counts.get('insert', 0),
            operation_counts.get('update', 0),
            operation_counts.get('delete', 0),
            action_descriptions,
        )
    )

    lines.append("")
    lines.append("## Tables Touched")
    lines.append("")
    lines.extend(render_tables_touched_table(table_counts))

    lines.append("")
    lines.append("## Changes")
    lines.append("")
    for change_number, change in enumerate(logical_changes, start=1):
        lines.extend(render_change(change, change_number))

    return "\n".join(lines).rstrip() + "\n"


def write_logical_changes_markdown(path: Path, logical_changes: list[dict[str, object]], source_label: str) -> None:
    path.write_text(render_logical_changes_markdown(logical_changes, source_label), encoding="utf-8")


def load_and_render_logical_changes_markdown(input_path: Path, output_path: Path) -> None:
    logical_changes = load_logical_changes(input_path)
    write_logical_changes_markdown(output_path, logical_changes, str(input_path))