"""Capture source CDC and target logical changes in one synchronized tracing run."""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass, field
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
    DEFAULT_STARTING_UID,
    LOCAL_TRACING_DIR,
)
from tracing_env import load_database_connection_defaults, resolve_server_argument
from tracing_logical_changes import build_logical_changes, write_logical_changes
from tracing_logical_markdown import write_logical_changes_markdown
from generate_query_expected import generate_rdb_selects_from_manifest
from tracing_metadata import (
    fetch_capture_instances,
    fetch_database_cdc_enabled,
    fetch_superuser_id,
    fetch_table_statuses,
    get_replay_metadata,
)
from tracing_output import write_jsonl, write_manifest, write_summary
from tracing_paths import is_excluded_trace_table, output_name_component, resolve_state_files
from tracing_post_processing import log_progress, wait_for_post_processing_idle
from tracing_replay import change_sort_key
from tracing_sql import SqlCmdClient, manual_enable_database_cdc_instructions, require_sqlcmd
from tracing_state import (
    clear_managed_table_files,
    clear_managed_tables,
    load_known_associations,
    load_managed_tables,
    normalize_table_entries,
    save_managed_tables,
    utc_now,
)


@dataclass
class TracePlan:
    label: str
    database: str
    client: SqlCmdClient
    state_file: Path
    legacy_state_file: Path | None
    managed_tables: list[dict[str, str]]
    loaded_state_file: Path | None
    initially_tracked_count: int
    enabled_tables: list[dict[str, str]] = field(default_factory=list)
    skipped_tables: list[dict[str, str]] = field(default_factory=list)
    cleanup_failures: list[dict[str, str]] = field(default_factory=list)
    run_dir: Path | None = None


def parse_args() -> argparse.Namespace:
    defaults = load_database_connection_defaults()

    parser = argparse.ArgumentParser(
        description="Capture CDC from one database and logical changes from another in a single synchronized run."
    )
    parser.add_argument(
        "--server",
        default=resolve_server_argument(defaults),
        help="SQL Server host and port; defaults to DATABASE_SERVER and DATABASE_PORT from .env",
    )
    parser.add_argument("--cdc-database", default="NBS_ODSE", help="Database to capture raw CDC rows from")
    parser.add_argument(
        "--logical-database",
        default="RDB_MODERN",
        help="Database to capture logical row-level changes from",
    )
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
        help="Directory where combined run output folders are created",
    )
    parser.add_argument(
        "--cdc-state-file",
        help="Optional state file override for the CDC database tracer-managed tables",
    )
    parser.add_argument(
        "--logical-state-file",
        help="Optional state file override for the logical-change database tracer-managed tables",
    )
    parser.add_argument(
        "--known-associations-file",
        default=str(DEFAULT_KNOWN_ASSOCIATIONS_FILE),
        help="JSON file describing replay-time key associations for polymorphic columns such as EVENT_UID",
    )
    parser.add_argument(
        "--replay-mode",
        choices=("core", "full"),
        default="core",
        help="Whether reconstructed SQL should skip helper-table writes for functional-test replay or include all replayable writes",
    )
    parser.add_argument(
        "--starting-uid",
        type=int,
        help="Starting UID value for reconstructed replay SQL variable declarations; prompts with default 1234 when omitted",
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
        help="Disable the tracer-managed CDC tables recorded for both databases, then exit",
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
    args = parser.parse_args()
    if not args.user:
        parser.error("--user is required unless DATABASE_USERNAME is set in .env or the environment")
    if not args.password:
        parser.error("--password is required unless DATABASE_PASSWORD is set in .env or the environment")
    if args.cdc_database == args.logical_database:
        parser.error("--cdc-database and --logical-database must be different")
    return args


def resolve_starting_uid(cli_starting_uid: int | None) -> int:
    if cli_starting_uid is not None:
        return cli_starting_uid

    while True:
        response = input(f"Starting UID for reconstructed SQL [default {DEFAULT_STARTING_UID}]: ").strip()
        if not response:
            return DEFAULT_STARTING_UID
        try:
            return int(response)
        except ValueError:
            print("Please enter a whole number (for example: 1234).")


def prompt_another_step() -> bool:
    while True:
        response = input("Record another step? [y/n]: ").strip().lower()
        if response in {"y", "yes"}:
            return True
        if response in {"n", "no"}:
            return False
        print("Please answer y or n.")


def plan_prefix(plan: TracePlan) -> str:
    return f"[{plan.label}:{plan.database}]"


def load_plan(
    args: argparse.Namespace,
    database: str,
    label: str,
    state_file_override: str | None,
    executable: str,
) -> tuple[TracePlan, list[object]]:
    client = SqlCmdClient(executable, args.server, database, args.user, args.password)
    state_file, legacy_state_file = resolve_state_files(state_file_override, database)
    managed_state, loaded_state_file = load_managed_tables(state_file, database, legacy_state_file)

    if not fetch_database_cdc_enabled(client, database):
        print(manual_enable_database_cdc_instructions(database, "trace_db_dual_capture.py", args.user))
        raise SystemExit(1)

    initial_statuses = fetch_table_statuses(client)
    excluded_tables = [item for item in initial_statuses if is_excluded_trace_table(item.schema_name, item.table_name)]
    to_enable = [
        item
        for item in initial_statuses
        if not item.is_tracked_by_cdc and not is_excluded_trace_table(item.schema_name, item.table_name)
    ]
    plan = TracePlan(
        label=label,
        database=database,
        client=client,
        state_file=state_file,
        legacy_state_file=legacy_state_file,
        managed_tables=managed_state.tables,
        loaded_state_file=loaded_state_file,
        initially_tracked_count=sum(1 for item in initial_statuses if item.is_tracked_by_cdc),
        skipped_tables=[
            {
                "schema_name": item.schema_name,
                "table_name": item.table_name,
                "detail": "Excluded from tracing",
            }
            for item in excluded_tables
        ],
    )
    return plan, to_enable


def enable_missing_tables(plan: TracePlan, tables_to_enable: list[object]) -> None:
    print(f"{plan_prefix(plan)} Initial CDC-enabled tables: {plan.initially_tracked_count}")
    print(f"{plan_prefix(plan)} Tables to attempt enabling: {len(tables_to_enable)}")
    if plan.skipped_tables:
        print(f"{plan_prefix(plan)} Tables excluded from tracing: {len(plan.skipped_tables)}")
    if plan.managed_tables:
        print(f"{plan_prefix(plan)} Tracer-managed tables already recorded: {len(plan.managed_tables)}")

    for table in tables_to_enable:
        enabled, detail = enable_table_cdc(plan.client, table.schema_name, table.table_name)
        entry = {"schema_name": table.schema_name, "table_name": table.table_name, "detail": detail}
        if enabled:
            plan.enabled_tables.append(entry)
            print(f"{plan_prefix(plan)} Enabled CDC: {table.schema_name}.{table.table_name}")
        else:
            plan.skipped_tables.append(entry)
            print(f"{plan_prefix(plan)} Skipped CDC: {table.schema_name}.{table.table_name} | {detail}")


def fetch_sorted_changes(plan: TracePlan, start_lsn: str, end_lsn: str) -> tuple[list[object], list[dict[str, object]]]:
    log_progress(f"{plan_prefix(plan)} Collecting CDC capture instances")
    captures = [
        capture
        for capture in fetch_capture_instances(plan.client)
        if not is_excluded_trace_table(capture.schema_name, capture.table_name)
    ]
    log_progress(f"{plan_prefix(plan)} Loaded {len(captures)} CDC capture instances")

    log_progress(f"{plan_prefix(plan)} Fetching CDC rows within the recorded LSN window")
    changes = fetch_changes_for_captures(plan.client, captures, start_lsn, end_lsn)

    log_progress(f"{plan_prefix(plan)} Sorting captured CDC rows")
    changes.sort(key=change_sort_key)
    log_progress(f"{plan_prefix(plan)} Sorted {len(changes)} CDC rows")
    return captures, changes


def write_combined_manifest(path: Path, manifest: dict[str, object]) -> None:
    log_progress("Writing combined-manifest.json")
    write_manifest(path, manifest)


def finalize_plan_cleanup(plan: TracePlan, args: argparse.Namespace, disable_tables_after_run: bool) -> None:
    managed_tables_after_run = normalize_table_entries(
        [
            *plan.managed_tables,
            *[{"schema_name": item["schema_name"], "table_name": item["table_name"]} for item in plan.enabled_tables],
        ]
    )

    if disable_tables_after_run:
        plan.cleanup_failures = disable_managed_tables(plan.client, managed_tables_after_run)
        if plan.cleanup_failures:
            save_managed_tables(
                plan.state_file,
                args.server,
                plan.database,
                [{"schema_name": item["schema_name"], "table_name": item["table_name"]} for item in plan.cleanup_failures],
                last_run_output_dir=str(plan.run_dir) if plan.run_dir else None,
            )
            if plan.loaded_state_file and plan.loaded_state_file != plan.state_file:
                clear_managed_tables(plan.loaded_state_file)
        else:
            clear_managed_table_files(plan.state_file, plan.loaded_state_file, plan.legacy_state_file)
    elif managed_tables_after_run:
        save_managed_tables(
            plan.state_file,
            args.server,
            plan.database,
            managed_tables_after_run,
            last_run_output_dir=str(plan.run_dir) if plan.run_dir else None,
        )
        if plan.loaded_state_file and plan.loaded_state_file != plan.state_file:
            clear_managed_tables(plan.loaded_state_file)
        print(f"{plan_prefix(plan)} Left tracer-managed CDC enabled; state recorded in: {plan.state_file}")
    else:
        clear_managed_table_files(plan.state_file, plan.loaded_state_file, plan.legacy_state_file)

    if plan.cleanup_failures:
        print()
        print(f"{plan_prefix(plan)} Cleanup failures detected:")
        for item in plan.cleanup_failures:
            print(f"- {item['schema_name']}.{item['table_name']}: {item['detail']}")


def prompt_cleanup_choice(args: argparse.Namespace, plans: list[TracePlan]) -> bool:
    managed_table_count = sum(
        len(
            normalize_table_entries(
                [
                    *plan.managed_tables,
                    *[
                        {"schema_name": item["schema_name"], "table_name": item["table_name"]}
                        for item in plan.enabled_tables
                    ],
                ]
            )
        )
        for plan in plans
    )
    if managed_table_count == 0:
        return False
    if args.cleanup == "yes":
        return True
    if args.cleanup == "no":
        return False

    while True:
        response = input(
            f"Disable CDC on {managed_table_count} tracer-managed table(s) across {len(plans)} database(s)? [y/n]: "
        ).strip().lower()
        if response in {"y", "yes"}:
            return True
        if response in {"n", "no"}:
            return False
        print("Please answer y or n.")


def run_disable_only(
    args: argparse.Namespace,
    plan: TracePlan,
) -> int:
    if not plan.managed_tables:
        print(f"{plan_prefix(plan)} No tracer-managed CDC tables recorded in {plan.state_file}")
        clear_managed_table_files(plan.state_file, plan.loaded_state_file, plan.legacy_state_file)
        return 0

    print(f"{plan_prefix(plan)} Disabling tracer-managed CDC tables from: {plan.loaded_state_file or plan.state_file}")
    print(f"{plan_prefix(plan)} Tables recorded: {len(plan.managed_tables)}")
    remaining_failures = disable_managed_tables(plan.client, plan.managed_tables)

    if remaining_failures:
        save_managed_tables(
            plan.state_file,
            args.server,
            plan.database,
            [{"schema_name": item["schema_name"], "table_name": item["table_name"]} for item in remaining_failures],
        )
        if plan.loaded_state_file and plan.loaded_state_file != plan.state_file:
            clear_managed_tables(plan.loaded_state_file)
        print(f"{plan_prefix(plan)} Some tables could not be disabled and remain in the state file")
        return 1

    clear_managed_table_files(plan.state_file, plan.loaded_state_file, plan.legacy_state_file)
    print(f"{plan_prefix(plan)} Disabled all tracer-managed CDC tables")
    return 0


def main() -> int:
    args = parse_args()
    executable = require_sqlcmd(args.sqlcmd)

    cdc_plan, cdc_tables_to_enable = load_plan(args, args.cdc_database, "cdc", args.cdc_state_file, executable)
    logical_plan, logical_tables_to_enable = load_plan(
        args,
        args.logical_database,
        "logical",
        args.logical_state_file,
        executable,
    )
    known_associations = load_known_associations(Path(args.known_associations_file))

    if args.disable_only:
        cdc_exit_code = run_disable_only(args, cdc_plan)
        logical_exit_code = run_disable_only(args, logical_plan)
        return 1 if cdc_exit_code or logical_exit_code else 0

    starting_uid = resolve_starting_uid(args.starting_uid)

    (
        primary_keys_by_table,
        identity_columns_by_table,
        foreign_keys_by_source,
        column_sql_types,
        generated_always_columns,
        uid_generator_entries,
        core_replay_ignored_tables,
    ) = get_replay_metadata(cdc_plan.client, cdc_plan.database)
    superuser_id = fetch_superuser_id(cdc_plan.client, cdc_plan.database)
    logical_primary_keys_by_table, _, _, _, _, _, _ = get_replay_metadata(logical_plan.client, logical_plan.database)

    disable_tables_after_run = False
    try:
        enable_missing_tables(cdc_plan, cdc_tables_to_enable)
        print()
        enable_missing_tables(logical_plan, logical_tables_to_enable)

        start_time_utc = utc_now()

        log_progress(f"{plan_prefix(cdc_plan)} Collecting CDC capture instances")
        cdc_captures = [
            capture
            for capture in fetch_capture_instances(cdc_plan.client)
            if not is_excluded_trace_table(capture.schema_name, capture.table_name)
        ]
        log_progress(f"{plan_prefix(cdc_plan)} Loaded {len(cdc_captures)} CDC capture instances")

        log_progress(f"{plan_prefix(logical_plan)} Collecting CDC capture instances")
        logical_captures = [
            capture
            for capture in fetch_capture_instances(logical_plan.client)
            if not is_excluded_trace_table(capture.schema_name, capture.table_name)
        ]
        log_progress(f"{plan_prefix(logical_plan)} Loaded {len(logical_captures)} CDC capture instances")

        nbs_steps: list[dict[str, object]] = []
        all_cdc_changes: list[dict[str, object]] = []
        all_logical_cdc_changes: list[dict[str, object]] = []
        step_num = 0
        while True:
            step_num += 1
            step_cdc_start_lsn = fetch_max_lsn(cdc_plan.client)
            step_logical_start_lsn = fetch_max_lsn(logical_plan.client)
            step_start_time = utc_now()

            print()
            print(f"Step {step_num} - {plan_prefix(cdc_plan)} Start time (UTC): {step_start_time}")
            print(f"Step {step_num} - {plan_prefix(cdc_plan)} Start LSN:        {step_cdc_start_lsn}")
            print(f"Step {step_num} - {plan_prefix(logical_plan)} Start LSN:    {step_logical_start_lsn}")

            post_processing_wait_since_utc = utc_now()
            input(f"Perform the UI action for step {step_num}, then press Enter to capture both traces... ")
            if not args.skip_post_processing_wait:
                wait_for_post_processing_idle(
                    args.post_processing_container_prefix,
                    args.post_processing_idle_message,
                    post_processing_wait_since_utc,
                    args.post_processing_wait_timeout,
                    args.post_processing_initial_wait,
                )

            step_cdc_end_lsn = fetch_max_lsn(cdc_plan.client)
            step_logical_end_lsn = fetch_max_lsn(logical_plan.client)
            step_end_time = utc_now()
            print(f"Step {step_num} - {plan_prefix(cdc_plan)} End time (UTC):   {step_end_time}")
            print(f"Step {step_num} - {plan_prefix(cdc_plan)} End LSN:          {step_cdc_end_lsn}")
            print(f"Step {step_num} - {plan_prefix(logical_plan)} End LSN:      {step_logical_end_lsn}")

            step_description = input(f"Describe what you did in step {step_num}: ").strip()

            log_progress(f"Step {step_num}: Fetching CDC rows for {plan_prefix(cdc_plan)}")
            step_cdc_changes = fetch_changes_for_captures(
                cdc_plan.client, cdc_captures, step_cdc_start_lsn, step_cdc_end_lsn
            )
            for change in step_cdc_changes:
                change["_step"] = step_num
            all_cdc_changes.extend(step_cdc_changes)
            log_progress(f"Step {step_num}: Fetched {len(step_cdc_changes)} CDC rows for {plan_prefix(cdc_plan)}")

            log_progress(f"Step {step_num}: Fetching CDC rows for {plan_prefix(logical_plan)}")
            step_logical_cdc_changes = fetch_changes_for_captures(
                logical_plan.client, logical_captures, step_logical_start_lsn, step_logical_end_lsn
            )
            for change in step_logical_cdc_changes:
                change["_step"] = step_num
            all_logical_cdc_changes.extend(step_logical_cdc_changes)
            log_progress(
                f"Step {step_num}: Fetched {len(step_logical_cdc_changes)} CDC rows for {plan_prefix(logical_plan)}"
            )

            nbs_steps.append({
                "step": step_num,
                "description": step_description,
                "cdc_start_lsn": step_cdc_start_lsn,
                "cdc_end_lsn": step_cdc_end_lsn,
                "logical_start_lsn": step_logical_start_lsn,
                "logical_end_lsn": step_logical_end_lsn,
                "start_time_utc": step_start_time,
                "end_time_utc": step_end_time,
            })

            if not prompt_another_step():
                break

        cdc_start_lsn = str(nbs_steps[0]["cdc_start_lsn"])
        cdc_end_lsn = str(nbs_steps[-1]["cdc_end_lsn"])
        logical_start_lsn = str(nbs_steps[0]["logical_start_lsn"])
        logical_end_lsn = str(nbs_steps[-1]["logical_end_lsn"])
        end_time_utc = str(nbs_steps[-1]["end_time_utc"])
        action_descriptions = [str(s.get("description", "")) for s in nbs_steps if s.get("description")]

        log_progress(f"{plan_prefix(cdc_plan)} Sorting captured CDC rows")
        all_cdc_changes.sort(key=change_sort_key)
        log_progress(f"{plan_prefix(cdc_plan)} Sorted {len(all_cdc_changes)} CDC rows")

        log_progress(f"{plan_prefix(logical_plan)} Sorting captured CDC rows")
        all_logical_cdc_changes.sort(key=change_sort_key)
        log_progress(f"{plan_prefix(logical_plan)} Sorted {len(all_logical_cdc_changes)} CDC rows")

        log_progress(f"{plan_prefix(logical_plan)} Building logical change events")
        logical_changes = build_logical_changes(
            logical_plan.database,
            all_logical_cdc_changes,
            logical_primary_keys_by_table,
            action_descriptions,
            start_time_utc,
            end_time_utc,
            logical_start_lsn,
            logical_end_lsn,
        )
        log_progress(f"{plan_prefix(logical_plan)} Built {len(logical_changes)} logical change events")

        log_progress("Creating combined output directory")
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        output_root = Path(args.output_dir)
        combined_run_dir = output_root / (
            f"{timestamp}-{output_name_component(args.cdc_database)}-to-{output_name_component(args.logical_database)}"
        )
        combined_run_dir.mkdir(parents=True, exist_ok=True)
        cdc_plan.run_dir = combined_run_dir / f"cdc-{output_name_component(args.cdc_database)}"
        logical_plan.run_dir = combined_run_dir / f"logical-{output_name_component(args.logical_database)}"
        cdc_plan.run_dir.mkdir(parents=True, exist_ok=True)
        logical_plan.run_dir.mkdir(parents=True, exist_ok=True)

        cdc_managed_tables_after_run = normalize_table_entries(
            [
                *cdc_plan.managed_tables,
                *[{"schema_name": item["schema_name"], "table_name": item["table_name"]} for item in cdc_plan.enabled_tables],
            ]
        )
        logical_managed_tables_after_run = normalize_table_entries(
            [
                *logical_plan.managed_tables,
                *[
                    {"schema_name": item["schema_name"], "table_name": item["table_name"]}
                    for item in logical_plan.enabled_tables
                ],
            ]
        )

        cdc_manifest = {
            "server": args.server,
            "database": cdc_plan.database,
            "start_time_utc": start_time_utc,
            "end_time_utc": end_time_utc,
            "start_lsn": cdc_start_lsn,
            "end_lsn": cdc_end_lsn,
                        "steps": nbs_steps,
            "initially_tracked_table_count": cdc_plan.initially_tracked_count,
            "enabled_tables": cdc_plan.enabled_tables,
            "skipped_tables": cdc_plan.skipped_tables,
            "managed_tables_before_run": cdc_plan.managed_tables,
            "managed_tables_after_run": cdc_managed_tables_after_run,
            "captures_considered": [capture.__dict__ for capture in cdc_captures],
            "action_descriptions": action_descriptions,
        }
        logical_manifest = {
            "server": args.server,
            "database": logical_plan.database,
            "start_time_utc": start_time_utc,
            "end_time_utc": end_time_utc,
            "start_lsn": logical_start_lsn,
            "end_lsn": logical_end_lsn,
            "steps": nbs_steps,
            "action_descriptions": action_descriptions,
            "initially_tracked_table_count": logical_plan.initially_tracked_count,
            "enabled_tables": logical_plan.enabled_tables,
            "skipped_tables": logical_plan.skipped_tables,
            "managed_tables_before_run": logical_plan.managed_tables,
            "managed_tables_after_run": logical_managed_tables_after_run,
            "captures_considered": [capture.__dict__ for capture in logical_captures],
            "logical_change_count": len(logical_changes),
        }
        combined_manifest = {
            "server": args.server,
            "captured_at_utc": utc_now(),
            "steps": nbs_steps,
            "action_descriptions": action_descriptions,
            "cdc_database": cdc_plan.database,
            "logical_database": logical_plan.database,
            "cdc_run_dir": str(cdc_plan.run_dir),
            "logical_run_dir": str(logical_plan.run_dir),
            "cdc_summary_file": str(cdc_plan.run_dir / "summary.txt"),
            "cdc_inserts_file": str(cdc_plan.run_dir / "inserts.sql"),
            "logical_changes_file": str(logical_plan.run_dir / "logical-changes.json"),
            "logical_markdown_file": str(logical_plan.run_dir / "logical-changes.md"),
            "cdc_change_count": len(all_cdc_changes),
            "logical_cdc_change_count": len(all_logical_cdc_changes),
            "logical_change_count": len(logical_changes),
        }

        write_combined_manifest(combined_run_dir / "combined-manifest.json", combined_manifest)

        log_progress(f"{plan_prefix(cdc_plan)} Writing manifest.json")
        write_manifest(cdc_plan.run_dir / "manifest.json", cdc_manifest)
        log_progress(f"{plan_prefix(cdc_plan)} Writing changes.jsonl")
        write_jsonl(cdc_plan.run_dir / "changes.jsonl", all_cdc_changes)
        log_progress(f"{plan_prefix(cdc_plan)} Writing summary.txt")
        write_summary(
            cdc_plan.run_dir / "summary.txt",
            [],
            cdc_manifest,
            all_cdc_changes,
            primary_keys_by_table,
            identity_columns_by_table,
            foreign_keys_by_source,
            column_sql_types,
            generated_always_columns,
            uid_generator_entries,
            known_associations,
            core_replay_ignored_tables,
            args.replay_mode,
            superuser_id,
            starting_uid,
            nbs_steps=nbs_steps,
        )

        log_progress(f"{plan_prefix(logical_plan)} Writing manifest.json")
        write_manifest(logical_plan.run_dir / "manifest.json", logical_manifest)
        log_progress(f"{plan_prefix(logical_plan)} Writing changes.jsonl")
        write_jsonl(logical_plan.run_dir / "changes.jsonl", all_logical_cdc_changes)
        log_progress(f"{plan_prefix(logical_plan)} Writing logical-changes.json")
        logical_changes_path = logical_plan.run_dir / "logical-changes.json"
        write_logical_changes(logical_changes_path, logical_changes)
        log_progress(f"{plan_prefix(logical_plan)} Writing logical-changes.md")
        write_logical_changes_markdown(
            logical_plan.run_dir / "logical-changes.md",
            logical_changes,
            str(logical_changes_path),
        )

        log_progress("Generating rdb-selects.sql from combined tracing artifacts")
        rdb_selects_path, expected_json_path, rdb_select_count = generate_rdb_selects_from_manifest(
            combined_run_dir / "combined-manifest.json",
            combined_run_dir / "rdb-selects.sql",
        )
        log_progress("Finished writing combined output artifacts")

        print()
        print(f"{plan_prefix(cdc_plan)} Captured {len(all_cdc_changes)} CDC rows across {len(nbs_steps)} step(s)")
        print(f"{plan_prefix(logical_plan)} Captured {len(all_logical_cdc_changes)} CDC rows across {len(nbs_steps)} step(s)")
        print(f"{plan_prefix(logical_plan)} Built {len(logical_changes)} logical change events")
        print(f"Generated {rdb_select_count} RDB SELECT statements")
        print(f"RDB select scaffold: {rdb_selects_path}")
        print(f"Expected JSON: {expected_json_path}")
        print(f"Combined output written to: {combined_run_dir}")

        disable_tables_after_run = prompt_cleanup_choice(args, [cdc_plan, logical_plan])
    finally:
        finalize_plan_cleanup(cdc_plan, args, disable_tables_after_run)
        finalize_plan_cleanup(logical_plan, args, disable_tables_after_run)

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("Interrupted by user", file=sys.stderr)
        raise SystemExit(130)