from __future__ import annotations

import argparse
import sys
from datetime import datetime
from pathlib import Path

from tracing_capture import (
    disable_managed_tables,
    enable_table_cdc,
    fetch_changes_for_captures,
    fetch_max_lsn,
)
from tracing_constants import (
    DEFAULT_KNOWN_ASSOCIATIONS_FILE,
    DEFAULT_POST_PROCESSING_CONTAINER_PREFIX,
    DEFAULT_POST_PROCESSING_IDLE_MESSAGE,
    DEFAULT_POST_PROCESSING_INITIAL_WAIT_SECONDS,
    DEFAULT_POST_PROCESSING_WAIT_TIMEOUT_SECONDS,
    LOCAL_TRACING_DIR,
)
from tracing_metadata import (
    disable_database_cdc,
    enable_database_cdc,
    fetch_capture_instances,
    fetch_database_cdc_enabled,
    fetch_table_statuses,
    get_replay_metadata,
)
from tracing_models import ManagedCdcState
from tracing_output import write_jsonl, write_manifest, write_summary
from tracing_paths import is_excluded_trace_table, output_name_component, resolve_state_files
from tracing_post_processing import log_progress, wait_for_post_processing_idle
from tracing_replay import change_sort_key
from tracing_sql import SqlCmdClient, require_sqlcmd
from tracing_state import (
    clear_managed_table_files,
    clear_managed_tables,
    load_known_associations,
    load_managed_tables,
    normalize_table_entries,
    save_managed_tables,
    should_disable_tables,
    utc_now,
)



def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Enable CDC on a SQL Server database for tracing, capture changes, and optionally clean up afterward."
    )
    parser.add_argument("--server", default="localhost,3433", help="SQL Server host and port")
    parser.add_argument("--database", default="NBS_ODSE", help="Database to trace")
    parser.add_argument("--user", required=True, help="SQL Server login")
    parser.add_argument("--password", required=True, help="SQL Server password")
    parser.add_argument("--sqlcmd", default="sqlcmd", help="sqlcmd executable name or path")
    parser.add_argument(
        "--output-dir",
        default=str(LOCAL_TRACING_DIR / "output"),
        help="Directory where run output folders are created",
    )
    parser.add_argument(
        "--state-file",
        help="JSON file used to track tracer-managed CDC tables left enabled across runs; defaults to enabled-cdc-tables-<database>.json",
    )
    parser.add_argument(
        "--known-associations-file",
        default=str(DEFAULT_KNOWN_ASSOCIATIONS_FILE),
        help="JSON file describing replay-time key associations for polymorphic columns such as EVENT_UID",
    )
    parser.add_argument(
        "--cleanup",
        choices=("ask", "yes", "no"),
        default="ask",
        help="Whether to disable tracer-managed CDC tables after the run: ask, yes, or no",
    )
    parser.add_argument(
        "--disable-only",
        action="store_true",
        help="Disable the tracer-managed CDC tables recorded in the state file, then exit",
    )
    parser.add_argument(
        "--skip-post-processing-wait",
        action="store_true",
        help="Do not wait for the post-processing service container to report it is idle after the UI action",
    )
    parser.add_argument(
        "--post-processing-container-prefix",
        default=DEFAULT_POST_PROCESSING_CONTAINER_PREFIX,
        help="Docker container-name prefix to watch after the UI action",
    )
    parser.add_argument(
        "--post-processing-idle-message",
        default=DEFAULT_POST_PROCESSING_IDLE_MESSAGE,
        help="Container log message that indicates post-processing is idle",
    )
    parser.add_argument(
        "--post-processing-wait-timeout",
        type=int,
        default=DEFAULT_POST_PROCESSING_WAIT_TIMEOUT_SECONDS,
        help="Seconds to wait for the post-processing service idle log message after the UI action",
    )
    parser.add_argument(
        "--post-processing-initial-wait",
        type=int,
        default=DEFAULT_POST_PROCESSING_INITIAL_WAIT_SECONDS,
        help="Seconds to wait before polling post-processing logs so stale idle messages do not win immediately",
    )
    return parser.parse_args()



def prompt_nbs_actions() -> list[str]:
    action = input("Describe the actions you took in NBS: ").strip()
    return [action] if action else []



def run_disable_only(
    args: argparse.Namespace,
    client: SqlCmdClient,
    state_file: Path,
    legacy_state_file: Path | None,
) -> int:
    managed_state, loaded_state_file = load_managed_tables(state_file, args.database, legacy_state_file)
    managed_tables = managed_state.tables
    if not managed_tables and not managed_state.database_cdc_enabled_by_tracer:
        print(f"No tracer-managed CDC tables recorded in {state_file}")
        clear_managed_table_files(state_file, loaded_state_file, legacy_state_file)
        return 0

    print(f"Disabling tracer-managed CDC tables from: {loaded_state_file or state_file}")
    print(f"Tables recorded: {len(managed_tables)}")
    remaining_failures = disable_managed_tables(client, managed_tables)
    database_disable_failed = False

    if not remaining_failures and managed_state.database_cdc_enabled_by_tracer:
        disabled, detail = disable_database_cdc(client, args.database)
        if disabled:
            print(f"Disabled database-level CDC: {args.database}")
            managed_state = ManagedCdcState(tables=[], database_cdc_enabled_by_tracer=False)
        else:
            database_disable_failed = True
            print(f"Database CDC cleanup failed: {detail}")

    if remaining_failures:
        save_managed_tables(
            state_file,
            args.server,
            args.database,
            [{"schema_name": item["schema_name"], "table_name": item["table_name"]} for item in remaining_failures],
            database_cdc_enabled_by_tracer=managed_state.database_cdc_enabled_by_tracer,
        )
        if loaded_state_file and loaded_state_file != state_file:
            clear_managed_tables(loaded_state_file)
        print()
        print("Some tables could not be disabled and remain in the state file:")
        for item in remaining_failures:
            print(f"- {item['schema_name']}.{item['table_name']}: {item['detail']}")
        return 1

    if database_disable_failed:
        save_managed_tables(
            state_file,
            args.server,
            args.database,
            [],
            database_cdc_enabled_by_tracer=True,
        )
        if loaded_state_file and loaded_state_file != state_file:
            clear_managed_tables(loaded_state_file)
        return 1

    clear_managed_table_files(state_file, loaded_state_file, legacy_state_file)
    print("Disabled all tracer-managed CDC tables")
    return 0



def main() -> int:
    args = parse_args()
    executable = require_sqlcmd(args.sqlcmd)
    client = SqlCmdClient(executable, args.server, args.database, args.user, args.password)
    state_file, legacy_state_file = resolve_state_files(args.state_file, args.database)
    known_associations = load_known_associations(Path(args.known_associations_file))

    if args.disable_only:
        return run_disable_only(args, client, state_file, legacy_state_file)

    managed_state, loaded_state_file = load_managed_tables(state_file, args.database, legacy_state_file)
    managed_tables = managed_state.tables
    database_cdc_enabled_by_tracer = managed_state.database_cdc_enabled_by_tracer

    if not fetch_database_cdc_enabled(client, args.database):
        print(f"Database-level CDC is not enabled for {args.database}; attempting to enable it...")
        enabled, detail = enable_database_cdc(client, args.database)
        if not enabled and not fetch_database_cdc_enabled(client, args.database):
            message = detail.strip() or "Unknown SQL Server error"
            raise SystemExit(f"Could not enable database-level CDC for {args.database}: {message}")
        database_cdc_enabled_by_tracer = True
        print(f"Enabled database-level CDC: {args.database}")

    (
        primary_keys_by_table,
        identity_columns_by_table,
        foreign_keys_by_source,
        column_sql_types,
        generated_always_columns,
        uid_generator_entries,
    ) = get_replay_metadata(client, args.database)

    initial_statuses = fetch_table_statuses(client)
    initially_tracked_count = sum(1 for item in initial_statuses if item.is_tracked_by_cdc)
    excluded_tables = [item for item in initial_statuses if is_excluded_trace_table(item.schema_name, item.table_name)]
    to_enable = [
        item
        for item in initial_statuses
        if not item.is_tracked_by_cdc and not is_excluded_trace_table(item.schema_name, item.table_name)
    ]
    enabled_tables: list[dict[str, str]] = []
    skipped_tables: list[dict[str, str]] = [
        {
            "schema_name": item.schema_name,
            "table_name": item.table_name,
            "detail": "Excluded from tracing",
        }
        for item in excluded_tables
    ]
    cleanup_failures: list[dict[str, str]] = []
    run_dir: Path | None = None

    print(f"Database: {args.database}")
    print(f"Initial CDC-enabled tables: {initially_tracked_count}")
    print(f"Tables to attempt enabling: {len(to_enable)}")
    if excluded_tables:
        print(f"Tables excluded from tracing: {len(excluded_tables)}")
    if managed_tables:
        print(f"Tracer-managed tables already recorded: {len(managed_tables)}")

    try:
        for table in to_enable:
            enabled, detail = enable_table_cdc(client, table.schema_name, table.table_name)
            entry = {"schema_name": table.schema_name, "table_name": table.table_name, "detail": detail}
            if enabled:
                enabled_tables.append(entry)
                print(f"Enabled CDC: {table.schema_name}.{table.table_name}")
            else:
                skipped_tables.append(entry)
                print(f"Skipped CDC: {table.schema_name}.{table.table_name} | {detail}")

        start_lsn = fetch_max_lsn(client)
        start_time_utc = utc_now()
        print()
        print(f"Start time (UTC): {start_time_utc}")
        print(f"Start LSN:        {start_lsn}")
        post_processing_wait_since_utc = utc_now()
        input("Perform the UI action now, then press Enter to capture changes... ")
        if not args.skip_post_processing_wait:
            wait_for_post_processing_idle(
                args.post_processing_container_prefix,
                args.post_processing_idle_message,
                post_processing_wait_since_utc,
                args.post_processing_wait_timeout,
                args.post_processing_initial_wait,
            )

        end_lsn = fetch_max_lsn(client)
        end_time_utc = utc_now()
        print(f"End time (UTC):   {end_time_utc}")
        print(f"End LSN:          {end_lsn}")
        nbs_actions = prompt_nbs_actions()

        log_progress("Collecting CDC capture instances")
        captures = [
            capture
            for capture in fetch_capture_instances(client)
            if not is_excluded_trace_table(capture.schema_name, capture.table_name)
        ]
        log_progress(f"Loaded {len(captures)} CDC capture instances")

        log_progress("Fetching CDC rows within the recorded LSN window")
        changes = fetch_changes_for_captures(client, captures, start_lsn, end_lsn)

        log_progress("Sorting captured CDC rows")
        changes.sort(key=change_sort_key)
        log_progress(f"Sorted {len(changes)} CDC rows")

        log_progress("Creating output directory")
        output_root = Path(args.output_dir)
        run_dir = output_root / f"{datetime.now().strftime('%Y%m%d-%H%M%S')}-{output_name_component(args.database)}"
        run_dir.mkdir(parents=True, exist_ok=True)

        managed_tables_after_run = normalize_table_entries(
            [
                *managed_tables,
                *[{"schema_name": item["schema_name"], "table_name": item["table_name"]} for item in enabled_tables],
            ]
        )

        manifest = {
            "server": args.server,
            "database": args.database,
            "database_cdc_enabled_by_tracer": database_cdc_enabled_by_tracer,
            "start_time_utc": start_time_utc,
            "end_time_utc": end_time_utc,
            "start_lsn": start_lsn,
            "end_lsn": end_lsn,
            "initially_tracked_table_count": initially_tracked_count,
            "enabled_tables": enabled_tables,
            "skipped_tables": skipped_tables,
            "managed_tables_before_run": managed_tables,
            "managed_tables_after_run": managed_tables_after_run,
            "captures_considered": [capture.__dict__ for capture in captures],
        }

        log_progress("Writing manifest.json")
        write_manifest(run_dir / "manifest.json", manifest)
        log_progress("Writing changes.jsonl")
        write_jsonl(run_dir / "changes.jsonl", changes)
        log_progress("Writing summary.txt")
        write_summary(
            run_dir / "summary.txt",
            nbs_actions,
            manifest,
            changes,
            primary_keys_by_table,
            identity_columns_by_table,
            foreign_keys_by_source,
            column_sql_types,
            generated_always_columns,
            uid_generator_entries,
            known_associations,
        )
        log_progress("Finished writing output artifacts")

        print()
        print(f"Captured {len(changes)} CDC rows")
        print(f"Output written to: {run_dir}")
    finally:
        managed_tables_after_run = normalize_table_entries(
            [
                *managed_tables,
                *[{"schema_name": item["schema_name"], "table_name": item["table_name"]} for item in enabled_tables],
            ]
        )
        database_cleanup_failed = False

        if should_disable_tables(args, len(managed_tables_after_run)):
            cleanup_failures = disable_managed_tables(client, managed_tables_after_run)
            if cleanup_failures:
                save_managed_tables(
                    state_file,
                    args.server,
                    args.database,
                    [{"schema_name": item["schema_name"], "table_name": item["table_name"]} for item in cleanup_failures],
                    database_cdc_enabled_by_tracer=database_cdc_enabled_by_tracer,
                    last_run_output_dir=str(run_dir) if run_dir else None,
                )
                if loaded_state_file and loaded_state_file != state_file:
                    clear_managed_tables(loaded_state_file)
            else:
                if database_cdc_enabled_by_tracer:
                    disabled, detail = disable_database_cdc(client, args.database)
                    if disabled:
                        database_cdc_enabled_by_tracer = False
                        print(f"Disabled database-level CDC: {args.database}")
                    else:
                        database_cleanup_failed = True
                        print(f"Database CDC cleanup failed: {detail}")

                if database_cleanup_failed:
                    save_managed_tables(
                        state_file,
                        args.server,
                        args.database,
                        [],
                        database_cdc_enabled_by_tracer=True,
                        last_run_output_dir=str(run_dir) if run_dir else None,
                    )
                    if loaded_state_file and loaded_state_file != state_file:
                        clear_managed_tables(loaded_state_file)
                else:
                    clear_managed_table_files(state_file, loaded_state_file, legacy_state_file)
        elif managed_tables_after_run or database_cdc_enabled_by_tracer:
            save_managed_tables(
                state_file,
                args.server,
                args.database,
                managed_tables_after_run,
                database_cdc_enabled_by_tracer=database_cdc_enabled_by_tracer,
                last_run_output_dir=str(run_dir) if run_dir else None,
            )
            if loaded_state_file and loaded_state_file != state_file:
                clear_managed_tables(loaded_state_file)
            print(f"Left tracer-managed CDC enabled; state recorded in: {state_file}")
        else:
            clear_managed_table_files(state_file, loaded_state_file, legacy_state_file)

        if cleanup_failures:
            print()
            print("Cleanup failures detected:")
            for item in cleanup_failures:
                print(f"- {item['schema_name']}.{item['table_name']}: {item['detail']}")
        if database_cleanup_failed:
            print()
            print(f"Cleanup failure detected: database-level CDC is still enabled for {args.database}")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("Interrupted by user", file=sys.stderr)
        raise SystemExit(130)
