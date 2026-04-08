"""Generate an RDB select scaffold from paired tracing artifacts."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from tracing_constants import LOCAL_TRACING_DIR


SCALAR_DECLARE_PATTERN = re.compile(
    r"^DECLARE\s+(?P<name>@[A-Za-z0-9_]+)\s+(?P<sql_type>[^=;]+?)(?:\s*=\s*(?P<expression>.+?))?;\s*$",
    re.IGNORECASE,
)
STRING_PREFIX_PATTERN = re.compile(r"N'(?P<prefix>[A-Za-z]+)'\s*\+")


@dataclass(frozen=True)
class DeclareEntry:
    name: str
    sql_type: str
    expression: str | None
    value_prefix: str | None


@dataclass(frozen=True)
class SelectScaffold:
    schema_name: str
    table_name: str
    operation_labels: tuple[str, ...]
    identity_strategy: str
    comparison_eligible: bool
    where_fields: tuple[tuple[str, object], ...]
    comments: tuple[str, ...]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate rdb-selects.sql from a paired dual-capture output folder or combined-manifest.json."
    )
    parser.add_argument(
        "--paired-run-dir",
        help="Paired output directory created by trace_db_dual_capture.py; defaults to the latest paired run under output/",
    )
    parser.add_argument(
        "--combined-manifest",
        help="Explicit path to combined-manifest.json; overrides --paired-run-dir when provided",
    )
    parser.add_argument(
        "--output-file",
        help="Path to write the generated SQL scaffold; defaults to rdb-selects.sql next to combined-manifest.json",
    )
    return parser.parse_args()


def latest_combined_manifest() -> Path:
    manifests = sorted((LOCAL_TRACING_DIR / "output").glob("*/combined-manifest.json"), key=lambda path: path.stat().st_mtime)
    if not manifests:
        raise SystemExit("Could not find a paired run. Pass --paired-run-dir or --combined-manifest.")
    return manifests[-1]


def resolve_manifest_path(args: argparse.Namespace) -> Path:
    if args.combined_manifest:
        manifest_path = Path(args.combined_manifest)
    elif args.paired_run_dir:
        manifest_path = Path(args.paired_run_dir) / "combined-manifest.json"
    else:
        manifest_path = latest_combined_manifest()
    if not manifest_path.exists():
        raise SystemExit(f"Combined manifest not found: {manifest_path}")
    return manifest_path


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise SystemExit(f"Could not parse JSON file {path}: {error}") from error


def load_combined_inputs(manifest_path: Path) -> tuple[dict[str, object], Path, Path]:
    manifest_obj = load_json(manifest_path)
    if not isinstance(manifest_obj, dict):
        raise SystemExit(f"Combined manifest has an invalid format: {manifest_path}")

    summary_file = manifest_obj.get("cdc_summary_file")
    logical_changes_file = manifest_obj.get("logical_changes_file")
    if not isinstance(summary_file, str) or not summary_file:
        raise SystemExit(f"Combined manifest is missing cdc_summary_file: {manifest_path}")
    if not isinstance(logical_changes_file, str) or not logical_changes_file:
        raise SystemExit(f"Combined manifest is missing logical_changes_file: {manifest_path}")

    summary_path = Path(summary_file)
    logical_changes_path = Path(logical_changes_file)
    if not summary_path.exists():
        raise SystemExit(f"CDC summary file not found: {summary_path}")
    if not logical_changes_path.exists():
        raise SystemExit(f"Logical changes file not found: {logical_changes_path}")
    return manifest_obj, summary_path, logical_changes_path


def extract_declare_block(summary_text: str) -> list[str]:
    lines = summary_text.splitlines()
    in_reconstructed_sql = False
    collected: list[str] = []
    previous_was_declare = False

    for line in lines:
        if not in_reconstructed_sql:
            if line.strip() == "Reconstructed SQL:":
                in_reconstructed_sql = True
            continue

        stripped = line.strip()
        if stripped.startswith("USE ") or not stripped:
            previous_was_declare = False
            continue
        if stripped.startswith("DECLARE "):
            collected.append(line)
            previous_was_declare = True
            continue
        if stripped.startswith("-- Adjust the UID declarations below manually"):
            if collected and not previous_was_declare and collected[-1] != "":
                collected.append("")
            collected.append(line)
            previous_was_declare = False
            continue
        previous_was_declare = False

    return collected


def parse_declare_entries(declare_lines: list[str]) -> list[DeclareEntry]:
    entries: list[DeclareEntry] = []
    for line in declare_lines:
        match = SCALAR_DECLARE_PATTERN.match(line.strip())
        if not match:
            continue
        sql_type = match.group("sql_type").strip()
        if "TABLE" in sql_type.upper():
            continue
        expression = match.group("expression")
        value_prefix = None
        if expression:
            prefix_match = STRING_PREFIX_PATTERN.search(expression)
            if prefix_match:
                value_prefix = prefix_match.group("prefix")
        entries.append(
            DeclareEntry(
                name=match.group("name"),
                sql_type=sql_type,
                expression=expression.strip() if expression else None,
                value_prefix=value_prefix,
            )
        )
    return entries


def stable_identity_fields(change: dict[str, object]) -> tuple[dict[str, object], str, bool]:
    stable_identity = change.get("stable_identity")
    if isinstance(stable_identity, dict):
        fields = stable_identity.get("fields")
        if isinstance(fields, dict) and fields:
            return (
                fields,
                str(stable_identity.get("strategy") or "unknown"),
                bool(stable_identity.get("eligible_for_comparison")),
            )

    primary_key_values = change.get("primary_key_values")
    if isinstance(primary_key_values, dict) and primary_key_values:
        return primary_key_values, "primary_key", False

    after_values = change.get("after")
    if isinstance(after_values, dict) and after_values:
        first_field = next(iter(after_values.items()))
        return {str(first_field[0]): first_field[1]}, "fallback_after", False

    return {}, "unresolved", False


def normalize_identifier(value: str) -> str:
    return value.strip().lower()


def declaration_group(entry: DeclareEntry) -> str:
    name = normalize_identifier(entry.name)
    if "person_local_id" in name and "hist" not in name:
        return "person_local_id"
    if "person_hist_local_id" in name:
        return "person_hist_local_id"
    if "observation_local_id" in name:
        return "observation_local_id"
    if "investigation_local_id" in name:
        return "investigation_local_id"
    if "intervention_local_id" in name:
        return "intervention_local_id"
    if "notification_local_id" in name:
        return "notification_local_id"
    if "entity_entity_uid" in name:
        return "entity_uid"
    if "act_act_uid" in name:
        return "act_uid"
    if "postal_locator_postal_locator_uid" in name:
        return "postal_locator_uid"
    if name == "@superuser_id":
        return "superuser_id"
    return "other"


def preferred_groups_for_column(column_name: str) -> list[str]:
    normalized = normalize_identifier(column_name)
    if normalized == "local_id" or normalized.endswith("_local_id"):
        if "patient" in normalized or "person" in normalized:
            return ["person_local_id"]
        if "observation" in normalized:
            return ["observation_local_id"]
        if "investigation" in normalized or "inv_" in normalized:
            return ["investigation_local_id"]
        if "intervention" in normalized:
            return ["intervention_local_id"]
        if "notification" in normalized:
            return ["notification_local_id"]
        return ["person_local_id", "observation_local_id", "investigation_local_id", "intervention_local_id"]

    if normalized.endswith("patient_uid") or normalized.endswith("person_uid") or normalized.endswith("entity_uid"):
        return ["entity_uid"]
    if normalized.endswith("patient_mpr_uid") or normalized.endswith("person_parent_uid"):
        return ["entity_uid"]
    if normalized.endswith("observation_uid") or normalized.endswith("act_uid"):
        return ["act_uid"]
    if normalized.endswith("locator_uid") or normalized.endswith("postal_locator_uid"):
        return ["postal_locator_uid"]
    return []


def variable_candidates_for_value(column_name: str, value: object, declare_entries: list[DeclareEntry]) -> list[str]:
    preferred_groups = preferred_groups_for_column(column_name)
    if not preferred_groups:
        return []

    if isinstance(value, str) and value:
        prefix_match = re.match(r"([A-Za-z]+)", value)
        value_prefix = prefix_match.group(1).upper() if prefix_match else None
    else:
        value_prefix = None

    candidates: list[str] = []
    for group_name in preferred_groups:
        grouped = [entry for entry in declare_entries if declaration_group(entry) == group_name]
        if value_prefix is not None:
            prefix_matches = [entry for entry in grouped if entry.value_prefix and entry.value_prefix.upper() == value_prefix]
            grouped = prefix_matches
        if "local_id" in group_name and len(grouped) > 1:
            non_hist = [entry for entry in grouped if "_hist_" not in entry.name.lower()]
            if non_hist:
                grouped = non_hist
        if grouped:
            candidates.extend(entry.name for entry in grouped)

    deduped: list[str] = []
    for candidate in candidates:
        if candidate not in deduped:
            deduped.append(candidate)
    return deduped


def sql_string_literal(value: str) -> str:
    return "N'" + value.replace("'", "''") + "'"


def sql_literal(value: object) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, (int, float)):
        return str(value)
    return sql_string_literal(str(value))


def predicate_for_field(column_name: str, value: object, declare_entries: list[DeclareEntry]) -> tuple[str, list[str]]:
    column_sql = f"[{column_name}]"
    literal_sql = sql_literal(value)
    candidates = variable_candidates_for_value(column_name, value, declare_entries)
    if len(candidates) == 1:
        return f"{column_sql} = {candidates[0]}", []
    if len(candidates) > 1:
        return (
            f"{column_sql} = {literal_sql}",
            [f"Ambiguous variable candidates for {column_name}: {', '.join(candidates)}"],
        )
    return f"{column_sql} = {literal_sql}", []


def build_scaffolds(
    logical_changes: list[dict[str, object]],
    declare_entries: list[DeclareEntry],
) -> list[SelectScaffold]:
    grouped: dict[tuple[str, str, tuple[tuple[str, object], ...]], SelectScaffold] = {}

    for change in logical_changes:
        schema_name = str(change.get("schema_name") or "dbo")
        table_name = str(change.get("table_name") or "")
        fields, strategy, comparison_eligible = stable_identity_fields(change)
        if not table_name or not fields:
            continue

        ordered_fields = tuple(sorted((str(key), value) for key, value in fields.items()))
        group_key = (schema_name, table_name, ordered_fields)
        existing = grouped.get(group_key)
        operation = str(change.get("operation") or "unknown")

        comments: list[str] = []
        if strategy != "business_keys":
            comments.append(f"Identity strategy is {strategy}; review the WHERE clause before using it as a regression assertion.")
        if not comparison_eligible:
            comments.append("Logical comparison marked this identity as not comparison-safe.")

        if existing is None:
            grouped[group_key] = SelectScaffold(
                schema_name=schema_name,
                table_name=table_name,
                operation_labels=(operation,),
                identity_strategy=strategy,
                comparison_eligible=comparison_eligible,
                where_fields=ordered_fields,
                comments=tuple(comments),
            )
            continue

        operation_labels = tuple(sorted({*existing.operation_labels, operation}))
        merged_comments = tuple(dict.fromkeys([*existing.comments, *comments]))
        grouped[group_key] = SelectScaffold(
            schema_name=existing.schema_name,
            table_name=existing.table_name,
            operation_labels=operation_labels,
            identity_strategy=existing.identity_strategy,
            comparison_eligible=existing.comparison_eligible,
            where_fields=existing.where_fields,
            comments=merged_comments,
        )

    return sorted(grouped.values(), key=lambda item: (item.schema_name.lower(), item.table_name.lower(), item.where_fields))


def render_sql(
    manifest: dict[str, object],
    declare_lines: list[str],
    declare_entries: list[DeclareEntry],
    scaffolds: list[SelectScaffold],
) -> str:
    logical_database = str(manifest.get("logical_database") or "RDB_MODERN")
    source_summary_file = str(manifest.get("cdc_summary_file") or "")
    logical_changes_file = str(manifest.get("logical_changes_file") or "")

    lines = [
        f"USE [{logical_database}];",
        "",
        "-- Generated from paired tracing artifacts.",
        f"-- Source summary: {source_summary_file}",
        f"-- Logical changes: {logical_changes_file}",
        "-- Review and adjust the DECLARE values below before running these SELECT statements.",
        "",
    ]

    if declare_lines:
        lines.extend(declare_lines)
        lines.append("")

    for scaffold in scaffolds:
        lines.append(f"-- {scaffold.schema_name}.{scaffold.table_name} | operations: {', '.join(scaffold.operation_labels)}")
        for comment in scaffold.comments:
            lines.append(f"-- {comment}")

        predicate_lines: list[str] = []
        predicate_comments: list[str] = []
        for index, (column_name, value) in enumerate(scaffold.where_fields):
            predicate_sql, comments = predicate_for_field(column_name, value, declare_entries)
            connector = "WHERE" if index == 0 else "  AND"
            predicate_lines.append(f"{connector} {predicate_sql}")
            predicate_comments.extend(comments)

        for comment in dict.fromkeys(predicate_comments):
            lines.append(f"-- {comment}")

        lines.append(f"SELECT *")
        lines.append(f"FROM [{scaffold.schema_name}].[{scaffold.table_name}]")
        lines.extend(predicate_lines)
        lines.append("ORDER BY 1;")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    args = parse_args()
    manifest_path = resolve_manifest_path(args)
    manifest, summary_path, logical_changes_path = load_combined_inputs(manifest_path)
    summary_text = summary_path.read_text(encoding="utf-8")
    logical_changes_obj = load_json(logical_changes_path)
    if not isinstance(logical_changes_obj, list):
        raise SystemExit(f"Logical changes file has an invalid format: {logical_changes_path}")

    declare_lines = extract_declare_block(summary_text)
    declare_entries = parse_declare_entries(declare_lines)
    scaffolds = build_scaffolds(logical_changes_obj, declare_entries)
    output_sql = render_sql(manifest, declare_lines, declare_entries, scaffolds)

    output_path = Path(args.output_file) if args.output_file else manifest_path.with_name("rdb-selects.sql")
    output_path.write_text(output_sql, encoding="utf-8")
    print(f"Wrote RDB select scaffold: {output_path}")
    print(f"Generated SELECT statements: {len(scaffolds)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("Interrupted by user", file=sys.stderr)
        raise SystemExit(130)