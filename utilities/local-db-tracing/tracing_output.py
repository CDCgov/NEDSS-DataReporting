"""Write tracing artifacts and user-facing summaries for CDC capture runs."""

from __future__ import annotations

import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable

from tracing_constants import CDC_METADATA_COLUMNS, DEFAULT_STARTING_UID
from tracing_models import KnownAssociation, UidGeneratorEntry
from tracing_replay import (
    format_value,
    reconstruct_sql_statements,
    update_pair_key,
)
from tracing_sql import quote_identifier



def summarize_row_identifier(record: dict[str, object]) -> str:
    """Build a concise identifier string for one captured CDC row.

    Args:
        record: Captured CDC record including operation metadata and row payload.

    Returns:
        str: Short human-readable summary of the record identity.
    """

    row = record.get("row")
    if not isinstance(row, dict):
        return f"{record['operation']} seqval={record['seqval']}"

    preferred_suffixes = ("_uid", "_key", "_seq")
    excluded_columns = CDC_METADATA_COLUMNS | {"add_user_id", "last_chg_user_id", "version_ctrl_nbr"}
    identifier_parts: list[str] = []

    for column_name in row:
        if column_name in excluded_columns:
            continue
        if column_name == "local_id":
            identifier_parts.append(f"{column_name}={row[column_name]}")

    for suffix in preferred_suffixes:
        for column_name in row:
            if column_name in excluded_columns:
                continue
            if column_name.endswith(suffix):
                part = f"{column_name}={row[column_name]}"
                if part not in identifier_parts:
                    identifier_parts.append(part)

    if not identifier_parts:
        for column_name in row:
            if column_name in excluded_columns:
                continue
            if column_name.endswith("_id"):
                identifier_parts.append(f"{column_name}={row[column_name]}")

    if not identifier_parts:
        identifier_parts.append(f"seqval={record['seqval']}")

    parse_error = record.get("row_parse_error")
    if parse_error:
        return f"{record['operation']} {'; '.join(identifier_parts[:3])} [payload parse error]"
    return f"{record['operation']} {'; '.join(identifier_parts[:3])}"



def summarize_record_identity(record: dict[str, object]) -> str:
    """Strip the operation prefix from a row summary.

    Args:
        record: Captured CDC record to summarize.

    Returns:
        str: Record identity without the leading operation name.
    """

    summary = summarize_row_identifier(record)
    parts = summary.split(" ", 1)
    return parts[1] if len(parts) == 2 else summary



def summarize_update_pair(before_record: dict[str, object], after_record: dict[str, object]) -> str:
    """Summarize an update by comparing its before and after CDC rows.

    Args:
        before_record: CDC row emitted before the update.
        after_record: CDC row emitted after the update.

    Returns:
        str: Short human-readable description of the changed columns.
    """

    before_row = before_record.get("row") if isinstance(before_record.get("row"), dict) else {}
    after_row = after_record.get("row") if isinstance(after_record.get("row"), dict) else {}

    changed_columns: list[str] = []
    for column_name in sorted(set(before_row) | set(after_row)):
        if column_name in CDC_METADATA_COLUMNS:
            continue
        before_value = before_row.get(column_name)
        after_value = after_row.get(column_name)
        if before_value != after_value:
            changed_columns.append(f"{column_name}: {format_value(before_value)} -> {format_value(after_value)}")

    identity = summarize_record_identity(after_record)
    parse_error = before_record.get("row_parse_error") or after_record.get("row_parse_error")
    if parse_error:
        return f"update {identity} [payload parse error]"
    if not changed_columns:
        return f"update {identity} [no visible column change]"

    suffix = "; ..." if len(changed_columns) > 3 else ""
    return f"update {identity} {'; '.join(changed_columns[:3])}{suffix}"



def summarize_table_records(records: list[dict[str, object]]) -> list[str]:
    """Summarize all captured rows for one table.

    Args:
        records: CDC records already grouped by table.

    Returns:
        list[str]: Bullet-ready summary lines for the grouped records.
    """

    lines: list[str] = []
    pending_updates: dict[tuple[str, str, int | None], dict[str, object]] = {}

    for record in records:
        operation = record["operation"]
        if operation == "update_before":
            pending_updates[update_pair_key(record)] = record
            continue

        if operation == "update_after":
            pair_key = update_pair_key(record)
            before_record = pending_updates.pop(pair_key, None)
            if before_record is not None:
                lines.append(f"    - {summarize_update_pair(before_record, record)}")
                continue

        lines.append(f"    - {summarize_row_identifier(record)}")

    for record in pending_updates.values():
        lines.append(f"    - {summarize_row_identifier(record)}")

    return lines



def write_jsonl(path: Path, records: Iterable[dict[str, object]]) -> None:
    """Write captured CDC records to a JSON Lines file.

    Args:
        path: Output file path.
        records: Records to serialize.
    """

    with path.open("w", encoding="utf-8", newline="\n") as handle:
        for record in records:
            handle.write(json.dumps(record, ensure_ascii=True))
            handle.write("\n")



def write_manifest(path: Path, manifest: dict[str, object]) -> None:
    """Write run metadata to the manifest artifact.

    Args:
        path: Output file path.
        manifest: Manifest payload describing the run.
    """

    path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")



def write_summary(
    path: Path,
    nbs_actions: list[str],
    manifest: dict[str, object],
    changes: list[dict[str, object]],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    identity_columns_by_table: dict[tuple[str, str], list[str]],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    column_sql_types: dict[tuple[str, str, str], str],
    generated_always_columns: set[tuple[str, str, str]],
    uid_generator_entries: list[UidGeneratorEntry],
    known_associations: list[KnownAssociation],
    core_replay_ignored_tables: set[tuple[str, str]] | None = None,
    replay_mode: str = "full",
    superuser_id: int = 10009282,
    starting_uid: int = DEFAULT_STARTING_UID,
) -> None:
    """Write the human-readable summary artifact for a tracing run.

    Args:
        path: Output file path.
        nbs_actions: User-entered descriptions of the triggering UI actions.
        manifest: Run metadata written alongside the summary.
        changes: Captured CDC records.
        primary_keys_by_table: Ordered primary-key columns by table.
        identity_columns_by_table: Identity columns by table.
        foreign_keys_by_source: Foreign-key column mappings.
        column_sql_types: Replay-ready SQL type strings by column.
        generated_always_columns: Generated-always columns.
        uid_generator_entries: Local UID generator metadata.
        known_associations: Supplemental replay-time semantic key mappings.
        core_replay_ignored_tables: Tables that core replay should omit from
            reconstructed SQL.
        replay_mode: Whether reconstructed SQL should include all replayable
            writes or skip helper-table writes for functional-test replay.
    """

    op_counts = Counter(record["operation"] for record in changes)
    table_counts: defaultdict[str, int] = defaultdict(int)
    table_records: defaultdict[str, list[dict[str, object]]] = defaultdict(list)
    for record in changes:
        table_name = f"{record['schema_name']}.{record['table_name']}"
        table_counts[table_name] += 1
        table_records[table_name].append(record)

    lines: list[str] = []
    if nbs_actions:
        lines.append("Actions performed in NBS:")
        for action in nbs_actions:
            lines.append(f"- {action}")
        lines.append("")

    lines.extend([
        f"Database:    {manifest['database']}",
        f"Run started: {manifest['start_time_utc']}",
        f"Run ended:   {manifest['end_time_utc']}",
        f"Start LSN:   {manifest['start_lsn']}",
        f"End LSN:     {manifest['end_lsn']}",
        "",
        f"Initially CDC-enabled tables: {manifest['initially_tracked_table_count']}",
        f"Tables enabled by this run:   {len(manifest['enabled_tables'])}",
        f"Tables skipped by this run:   {len(manifest['skipped_tables'])}",
        f"Total captured rows:          {len(changes)}",
        "",
        "Captured rows by operation:",
    ])

    for operation in sorted(op_counts):
        lines.append(f"- {operation}: {op_counts[operation]}")

    lines.append("")
    lines.append("Captured rows by table:")
    for table_name in sorted(table_counts):
        lines.append(f"- {table_name}: {table_counts[table_name]}")
        lines.extend(summarize_table_records(table_records[table_name]))

    if manifest["skipped_tables"]:
        lines.append("")
        lines.append("Skipped tables:")
        for item in manifest["skipped_tables"]:
            lines.append(f"- {item['schema_name']}.{item['table_name']}: {item['detail']}")

    replay_changes = [
        record
        for record in changes
        if record.get("operation") in {"insert", "delete", "update_before", "update_after"}
    ]
    ignored_replay_table_names: list[str] = []
    if replay_mode == "core":
        replay_ignored_tables = core_replay_ignored_tables or set()
        ignored_replay_table_names = sorted(
            {
                f"{record['schema_name']}.{record['table_name']}"
                for record in replay_changes
                if (str(record["schema_name"]), str(record["table_name"])) in replay_ignored_tables
            }
        )
        replay_changes = [
            record
            for record in replay_changes
            if (str(record["schema_name"]), str(record["table_name"])) not in replay_ignored_tables
        ]

    reconstructed_sql: list[str] = []
    if replay_changes:
        reconstructed_sql = reconstruct_sql_statements(
            replay_changes,
            primary_keys_by_table,
            identity_columns_by_table,
            foreign_keys_by_source,
            column_sql_types,
            generated_always_columns,
            uid_generator_entries,
            known_associations,
            superuser_id=superuser_id,
            starting_uid=starting_uid,
        )
    if ignored_replay_table_names:
        lines.append("")
        lines.append("Tables excluded from reconstructed SQL (core replay):")
        for table_name in ignored_replay_table_names:
            lines.append(f"- {table_name}")
    if reconstructed_sql:
        inserts_path = path.parent / "inserts.sql"
        inserts_lines = [f"USE {quote_identifier(str(manifest['database']))};", *reconstructed_sql]
        inserts_path.write_text("\n".join(inserts_lines) + "\n", encoding="utf-8")

        lines.append("")
        lines.append(f"Reconstructed SQL written to: {inserts_path.name}")
        lines.append("Run inserts.sql directly against the source database to replay captured writes.")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
