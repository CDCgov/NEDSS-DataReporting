"""Capture RDB_MODERN and RDB logical changes, then compare RDB against RDB_MODERN."""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path

from compare_logical_changes import write_compare_markdown
from tracing_capture import disable_managed_tables, enable_table_cdc, fetch_changes_for_captures, fetch_max_lsn
from tracing_constants import LOCAL_TRACING_DIR
from tracing_env import load_database_connection_defaults, resolve_server_argument
from tracing_logical_changes import build_logical_changes, write_logical_changes
from tracing_logical_compare import compare_logical_changes, load_logical_changes, write_compare_results
from tracing_logical_markdown import write_logical_changes_markdown
from tracing_metadata import (
    fetch_capture_instances,
    fetch_database_cdc_enabled,
    fetch_table_statuses,
    get_replay_metadata,
)
from tracing_output import write_jsonl, write_manifest
from tracing_paths import is_excluded_trace_table, output_name_component
from tracing_replay import change_sort_key
from tracing_sql import SqlCmdClient, manual_enable_database_cdc_instructions, require_sqlcmd
from tracing_state import utc_now


def parse_args() -> argparse.Namespace:
    defaults = load_database_connection_defaults()
    parser = argparse.ArgumentParser(
        description=(
            "Run a two-window logical trace: capture RDB_MODERN around a UI action, "
            "capture RDB around MasterETL, then compare RDB (baseline) to RDB_MODERN (target)."
        )
    )
    parser.add_argument(
        "--server",
        default=resolve_server_argument(defaults),
        help="SQL Server host and port; defaults to DATABASE_SERVER and DATABASE_PORT from .env",
    )
    parser.add_argument("--rdb-modern-database", default="RDB_MODERN", help="Target database to capture first")
    parser.add_argument("--rdb-database", default="RDB", help="Baseline database to capture second")
    parser.add_argument(
        "--user",
        default=defaults.get("DATABASE_USERNAME"),
        help="SQL Server login; defaults to DATABASE_USERNAME from .env",
    )
    parser.add_argument(
        "--password",
        default=defaults.get("DATABASE_PASSWORD"),
        help="SQL Server password; defaults to DATABASE_PASSWORD from .env",
    )
    parser.add_argument("--sqlcmd", default="sqlcmd", help="sqlcmd executable name or path")
    parser.add_argument(
        "--output-dir",
        default=str(LOCAL_TRACING_DIR / "output"),
        help="Directory where run output folders are created",
    )
    parser.add_argument(
        "--cleanup",
        choices=("yes", "no"),
        default="no",
        help="Disable CDC on tables this script enabled during each capture window",
    )
    args = parser.parse_args()
    if not args.user:
        parser.error("--user is required unless DATABASE_USERNAME is set in .env or the environment")
    if not args.password:
        parser.error("--password is required unless DATABASE_PASSWORD is set in .env or the environment")
    return args


def ensure_database_cdc_enabled(client: SqlCmdClient, database: str, user: str) -> None:
    if fetch_database_cdc_enabled(client, database):
        return
    raise SystemExit(manual_enable_database_cdc_instructions(database, "trace_rdb_vs_rdb_modern_compare.py", user))


def capture_logical_window(
    client: SqlCmdClient,
    database: str,
    output_root: Path,
    prompt_text: str,
    action_description: str,
    cleanup: str,
) -> Path:
    ensure_database_cdc_enabled(client, database, client.user)

    table_statuses = fetch_table_statuses(client)
    to_enable = [
        item
        for item in table_statuses
        if not item.is_tracked_by_cdc and not is_excluded_trace_table(item.schema_name, item.table_name)
    ]
    enabled_tables: list[dict[str, str]] = []
    skipped_tables: list[dict[str, str]] = [
        {
            "schema_name": item.schema_name,
            "table_name": item.table_name,
            "detail": "Excluded from tracing",
        }
        for item in table_statuses
        if is_excluded_trace_table(item.schema_name, item.table_name)
    ]

    print(f"[{database}] Initial CDC-enabled tables: {sum(1 for item in table_statuses if item.is_tracked_by_cdc)}")
    print(f"[{database}] Tables to attempt enabling: {len(to_enable)}")

    for table in to_enable:
        enabled, detail = enable_table_cdc(client, table.schema_name, table.table_name)
        entry = {"schema_name": table.schema_name, "table_name": table.table_name, "detail": detail}
        if enabled:
            enabled_tables.append(entry)
            print(f"[{database}] Enabled CDC: {table.schema_name}.{table.table_name}")
        else:
            skipped_tables.append(entry)
            print(f"[{database}] Skipped CDC: {table.schema_name}.{table.table_name} | {detail}")

    start_lsn = fetch_max_lsn(client)
    start_time_utc = utc_now()
    print(f"[{database}] Start time (UTC): {start_time_utc}")
    print(f"[{database}] Start LSN:        {start_lsn}")

    input(prompt_text)

    end_lsn = fetch_max_lsn(client)
    end_time_utc = utc_now()
    print(f"[{database}] End time (UTC):   {end_time_utc}")
    print(f"[{database}] End LSN:          {end_lsn}")

    primary_keys_by_table, _, _, _, _, _, _ = get_replay_metadata(client, database)
    captures = [
        capture
        for capture in fetch_capture_instances(client)
        if not is_excluded_trace_table(capture.schema_name, capture.table_name)
    ]
    changes = fetch_changes_for_captures(client, captures, start_lsn, end_lsn)
    changes.sort(key=change_sort_key)

    logical_changes = build_logical_changes(
        database,
        changes,
        primary_keys_by_table,
        [action_description],
        start_time_utc,
        end_time_utc,
        start_lsn,
        end_lsn,
    )

    run_dir = output_root / f"{datetime.now().strftime('%Y%m%d-%H%M%S')}-{output_name_component(database)}"
    run_dir.mkdir(parents=True, exist_ok=True)

    logical_changes_path = run_dir / "logical-changes.json"
    manifest = {
        "server": client.server,
        "database": database,
        "start_time_utc": start_time_utc,
        "end_time_utc": end_time_utc,
        "start_lsn": start_lsn,
        "end_lsn": end_lsn,
        "action_descriptions": [action_description],
        "initially_tracked_table_count": sum(1 for item in table_statuses if item.is_tracked_by_cdc),
        "enabled_tables": enabled_tables,
        "skipped_tables": skipped_tables,
        "captures_considered": [capture.__dict__ for capture in captures],
        "logical_change_count": len(logical_changes),
    }

    write_manifest(run_dir / "manifest.json", manifest)
    write_jsonl(run_dir / "changes.jsonl", changes)
    write_logical_changes(logical_changes_path, logical_changes)
    write_logical_changes_markdown(run_dir / "logical-changes.md", logical_changes, str(logical_changes_path))

    print(f"[{database}] Captured {len(changes)} CDC rows")
    print(f"[{database}] Built {len(logical_changes)} logical change events")
    print(f"[{database}] Output written to: {run_dir}")

    if cleanup == "yes" and enabled_tables:
        cleanup_failures = disable_managed_tables(
            client,
            [{"schema_name": item["schema_name"], "table_name": item["table_name"]} for item in enabled_tables],
        )
        if cleanup_failures:
            print(f"[{database}] Cleanup failures detected:")
            for item in cleanup_failures:
                print(f"- {item['schema_name']}.{item['table_name']}: {item['detail']}")

    return run_dir


def build_compare_output_path(baseline_file: Path, target_file: Path) -> Path:
    baseline_label = baseline_file.resolve().parent.name
    target_label = target_file.resolve().parent.name
    return baseline_file.resolve().parent / f"compare-results-{baseline_label}-vs-{target_label}.json"


def main() -> int:
    args = parse_args()
    executable = require_sqlcmd(args.sqlcmd)

    output_root = Path(args.output_dir)
    output_root.mkdir(parents=True, exist_ok=True)

    modern_client = SqlCmdClient(executable, args.server, args.rdb_modern_database, args.user, args.password)
    rdb_client = SqlCmdClient(executable, args.server, args.rdb_database, args.user, args.password)

    print("Step 1/3: Capture RDB_MODERN logical changes")
    modern_run_dir = capture_logical_window(
        client=modern_client,
        database=args.rdb_modern_database,
        output_root=output_root,
        prompt_text="Do something in the UI, then press Enter to capture RDB_MODERN changes... ",
        action_description="UI action",
        cleanup=args.cleanup,
    )

    print()
    print("Step 2/3: Capture RDB logical changes")
    rdb_run_dir = capture_logical_window(
        client=rdb_client,
        database=args.rdb_database,
        output_root=output_root,
        prompt_text="Run MasterETL, then press Enter to capture RDB changes... ",
        action_description="MasterETL run",
        cleanup=args.cleanup,
    )

    print()
    print("Step 3/3: Compare RDB (baseline) against RDB_MODERN (target)")
    baseline_file = rdb_run_dir / "logical-changes.json"
    target_file = modern_run_dir / "logical-changes.json"

    baseline_changes = load_logical_changes(baseline_file)
    target_changes = load_logical_changes(target_file)
    results = compare_logical_changes(
        baseline_changes,
        target_changes,
        str(baseline_file),
        str(target_file),
    )

    compare_output_file = build_compare_output_path(baseline_file, target_file)
    write_compare_results(compare_output_file, results)
    compare_md_file = compare_output_file.with_suffix(".md")
    write_compare_markdown(compare_md_file, results)

    print(f"Baseline changes: {results['summary']['baseline_change_count']}")
    print(f"Target changes:   {results['summary']['target_change_count']}")
    print(f"Matched:          {results['summary']['matched_change_count']}")
    print(f"Missing:          {results['summary']['missing_change_count']}")
    print(f"Skipped:          {results['summary']['skipped_change_count']}")
    print(f"Output written to: {compare_output_file}")
    print(f"Report written to: {compare_md_file}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
