"""Regenerate a tracing summary from existing run artifacts."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from tracing_constants import DEFAULT_KNOWN_ASSOCIATIONS_FILE, DEFAULT_STARTING_UID
from tracing_env import load_database_connection_defaults, resolve_server_argument
from tracing_metadata import fetch_superuser_id, get_replay_metadata
from tracing_output import write_summary
from tracing_post_processing import log_progress
from tracing_sql import SqlCmdClient, require_sqlcmd
from tracing_state import load_known_associations


def parse_args() -> argparse.Namespace:
    defaults = load_database_connection_defaults()

    parser = argparse.ArgumentParser(
        description="Regenerate summary.txt from an existing changes.jsonl and sibling manifest.json."
    )
    parser.add_argument(
        "--input-file",
        required=True,
        help="Path to an existing changes.jsonl file from a prior trace run",
    )
    parser.add_argument(
        "--manifest-file",
        help="Optional manifest.json path; defaults to manifest.json next to the input file",
    )
    parser.add_argument(
        "--output-file",
        help="Optional summary.txt path; defaults to summary.txt next to the input file",
    )
    parser.add_argument(
        "--server",
        default=resolve_server_argument(defaults),
        help="SQL Server host and port; defaults to DATABASE_SERVER and DATABASE_PORT from .env",
    )
    parser.add_argument(
        "--database",
        help="Database name override; defaults to the database field in manifest.json",
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
        "--action",
        action="append",
        default=[],
        help="Optional NBS action note to include in the regenerated summary; repeat for multiple actions",
    )
    parser.add_argument(
        "--starting-uid",
        type=int,
        help="Starting UID value for reconstructed replay SQL variable declarations; prompts with default 1234 when omitted",
    )
    args = parser.parse_args()
    if not args.user:
        parser.error("--user is required unless DATABASE_USERNAME is set in .env or the environment")
    if not args.password:
        parser.error("--password is required unless DATABASE_PASSWORD is set in .env or the environment")
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


def load_json(path: Path) -> dict[str, object]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise SystemExit(f"JSON file is not valid: {path} | {error}") from error
    if not isinstance(payload, dict):
        raise SystemExit(f"JSON file must contain an object: {path}")
    return payload


def load_changes(path: Path) -> list[dict[str, object]]:
    changes: list[dict[str, object]] = []
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = raw_line.strip()
        if not stripped:
            continue
        try:
            item = json.loads(stripped)
        except json.JSONDecodeError as error:
            raise SystemExit(f"changes.jsonl contains invalid JSON on line {line_number}: {error}") from error
        if not isinstance(item, dict):
            raise SystemExit(f"changes.jsonl line {line_number} must decode to an object")
        changes.append(item)
    return changes


def main() -> int:
    args = parse_args()
    starting_uid = resolve_starting_uid(args.starting_uid)

    changes_path = Path(args.input_file).resolve()
    if not changes_path.is_file():
        raise SystemExit(f"Input file not found: {changes_path}")

    manifest_path = Path(args.manifest_file).resolve() if args.manifest_file else changes_path.with_name("manifest.json")
    if not manifest_path.is_file():
        raise SystemExit(f"Manifest file not found: {manifest_path}")

    output_path = Path(args.output_file).resolve() if args.output_file else changes_path.with_name("summary.txt")
    manifest = load_json(manifest_path)
    database = args.database or str(manifest.get("database") or "").strip()
    if not database:
        raise SystemExit("Database name is missing; pass --database or provide it in manifest.json")

    known_associations = load_known_associations(Path(args.known_associations_file))
    changes = load_changes(changes_path)

    executable = require_sqlcmd(args.sqlcmd)
    client = SqlCmdClient(executable, args.server, database, args.user, args.password)

    log_progress("Loading replay metadata")
    (
        primary_keys_by_table,
        identity_columns_by_table,
        foreign_keys_by_source,
        column_sql_types,
        generated_always_columns,
        uid_generator_entries,
        core_replay_ignored_tables,
    ) = get_replay_metadata(client, database)
    superuser_id = fetch_superuser_id(client, database)

    manifest["database"] = database
    log_progress("Writing regenerated summary.txt")
    nbs_steps = manifest.get("steps") or None
    id_map_dir = changes_path.parent.parent
    write_summary(
        output_path,
        args.action,
        manifest,
        changes,
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
        id_map_dir=id_map_dir,
    )
    print(output_path)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("Interrupted by user", file=sys.stderr)
        raise SystemExit(130)