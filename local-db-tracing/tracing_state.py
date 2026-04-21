from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

from tracing_models import KnownAssociation, ManagedCdcState



def utc_now() -> str:
    """Use UTC timestamps everywhere so manifests and summaries are comparable across environments."""

    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()



def parse_known_association_entry(item: object, index: int) -> KnownAssociation:
    """Validate one association entry so replay-time lookups fail fast on malformed config."""

    if not isinstance(item, dict):
        raise SystemExit(f"Known association #{index} must be a JSON object")

    source = item.get("source")
    target = item.get("target")
    when = item.get("when", {})

    if not isinstance(source, dict) or not isinstance(target, dict):
        raise SystemExit(f"Known association #{index} must contain object-valued 'source' and 'target' entries")
    if not isinstance(when, dict):
        raise SystemExit(f"Known association #{index} has an invalid 'when' value; expected an object")

    required_keys = ("schema", "table", "column")
    missing_source_keys = [key for key in required_keys if not isinstance(source.get(key), str) or not source.get(key)]
    missing_target_keys = [key for key in required_keys if not isinstance(target.get(key), str) or not target.get(key)]
    if missing_source_keys:
        missing = ", ".join(missing_source_keys)
        raise SystemExit(f"Known association #{index} source is missing required string fields: {missing}")
    if missing_target_keys:
        missing = ", ".join(missing_target_keys)
        raise SystemExit(f"Known association #{index} target is missing required string fields: {missing}")

    return KnownAssociation(
        source_schema=source["schema"],
        source_table=source["table"],
        source_column=source["column"],
        target_schema=target["schema"],
        target_table=target["table"],
        target_column=target["column"],
        when=when,
    )



def load_known_associations(path: Path) -> list[KnownAssociation]:
    """Load optional semantic key mappings so replay can resolve polymorphic identifiers."""

    if not path.exists():
        return []

    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Could not parse known associations file {path}: {exc}") from exc

    entries = payload.get("associations") if isinstance(payload, dict) else payload
    if not isinstance(entries, list):
        raise SystemExit(f"Known associations file {path} must contain a top-level array or an 'associations' array")

    return [parse_known_association_entry(item, index + 1) for index, item in enumerate(entries)]



def normalize_table_entries(entries: Iterable[dict[str, str]]) -> list[dict[str, str]]:
    """Deduplicate and sort tracked-table lists so saved state remains deterministic between runs."""

    seen: set[tuple[str, str]] = set()
    normalized: list[dict[str, str]] = []
    for entry in entries:
        schema_name = entry.get("schema_name", "").strip()
        table_name = entry.get("table_name", "").strip()
        if not schema_name or not table_name:
            continue
        key = (schema_name, table_name)
        if key in seen:
            continue
        seen.add(key)
        normalized.append({"schema_name": schema_name, "table_name": table_name})
    normalized.sort(key=lambda item: (item["schema_name"], item["table_name"]))
    return normalized



def read_state_file(
    state_file: Path,
    expected_database: str,
    strict_database_match: bool,
) -> ManagedCdcState | None:
    """Validate persisted cleanup state before using it to disable CDC on live tables."""

    if not state_file.exists():
        return None

    try:
        payload = json.loads(state_file.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise SystemExit(f"State file is not valid JSON: {state_file} | {error}") from error

    if not isinstance(payload, dict):
        raise SystemExit(f"State file has an invalid format: {state_file}")

    payload_database = payload.get("database")
    if isinstance(payload_database, str) and payload_database != expected_database:
        if strict_database_match:
            raise SystemExit(
                f"State file database mismatch: {state_file} is for {payload_database}, not {expected_database}"
            )
        return None

    raw_tables = payload.get("tables", [])
    if not isinstance(raw_tables, list):
        raise SystemExit(f"State file tables entry is invalid: {state_file}")

    normalized = normalize_table_entries(raw_tables)
    if len(normalized) != len(raw_tables):
        raise SystemExit(f"State file contains invalid table entries: {state_file}")

    database_cdc_enabled_by_tracer = payload.get("database_cdc_enabled_by_tracer", False)
    if not isinstance(database_cdc_enabled_by_tracer, bool):
        raise SystemExit(f"State file database CDC flag is invalid: {state_file}")

    return ManagedCdcState(
        tables=normalized,
        database_cdc_enabled_by_tracer=database_cdc_enabled_by_tracer,
    )



def load_managed_tables(
    state_file: Path,
    database: str,
    legacy_state_file: Path | None = None,
) -> tuple[ManagedCdcState, Path | None]:
    """Prefer database-scoped cleanup state but fall back to the legacy file so older runs remain recoverable."""

    state = read_state_file(state_file, database, strict_database_match=True)
    if state is not None:
        return state, state_file

    if legacy_state_file and legacy_state_file != state_file:
        legacy_state = read_state_file(legacy_state_file, database, strict_database_match=False)
        if legacy_state is not None:
            print(f"Using legacy state file for this run: {legacy_state_file}")
            return legacy_state, legacy_state_file

    return ManagedCdcState(tables=[], database_cdc_enabled_by_tracer=False), None



def save_managed_tables(
    state_file: Path,
    server: str,
    database: str,
    tables: list[dict[str, str]],
    database_cdc_enabled_by_tracer: bool = False,
    last_run_output_dir: str | None = None,
) -> None:
    """Persist only the tables this tracer is responsible for so later cleanup stays safe and targeted."""

    normalized = normalize_table_entries(tables)
    state_file.parent.mkdir(parents=True, exist_ok=True)
    payload: dict[str, object] = {
        "server": server,
        "database": database,
        "saved_at_utc": utc_now(),
        "tables": normalized,
        "database_cdc_enabled_by_tracer": database_cdc_enabled_by_tracer,
    }
    if last_run_output_dir:
        payload["last_run_output_dir"] = last_run_output_dir
    state_file.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")



def clear_managed_tables(state_file: Path) -> None:
    """Remove stale cleanup state once all tracer-managed tables have been handled."""

    state_file.unlink(missing_ok=True)



def clear_managed_table_files(*state_files: Path | None) -> None:
    """Clear every known state-file location so legacy and current cleanup records cannot diverge."""

    for state_file in state_files:
        if state_file is not None:
            clear_managed_tables(state_file)



def should_disable_tables(args: argparse.Namespace, table_count: int) -> bool:
    """Resolve cleanup intent once so the finally block can focus on applying it consistently."""

    if table_count == 0:
        return False
    if args.cleanup == "yes":
        return True
    if args.cleanup == "no":
        return False

    while True:
        response = input(f"Disable CDC on {table_count} tracer-managed table(s)? [y/n]: ").strip().lower()
        if response in {"y", "yes"}:
            return True
        if response in {"n", "no"}:
            return False
        print("Please answer y or n.")
