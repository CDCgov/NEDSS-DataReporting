"""Generate an RDB select scaffold from paired tracing artifacts."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from tracing_constants import LOCAL_TRACING_DIR
from tracing_paths import replay_metadata_cache_file_for_database


REPO_ROOT = Path(__file__).resolve().parents[2]


SCALAR_DECLARE_PATTERN = re.compile(
    r"^DECLARE\s+(?P<name>@[A-Za-z0-9_]+)\s+(?P<sql_type>[^=;]+?)(?:\s*=\s*(?P<expression>.+?))?;\s*$",
    re.IGNORECASE,
)
STRING_PREFIX_PATTERN = re.compile(r"N'(?P<prefix>[A-Za-z]+)'\s*\+")
LOCAL_ID_EXPRESSION_PATTERN = re.compile(
    r"^N'(?P<prefix>[^']*)'\s*\+\s*CONVERT\(nvarchar\(\d+\),\s*ABS\(CONVERT\(bigint,\s*(?P<numeric>.+?)\)\)\)\s*\+\s*N'(?P<suffix>[^']*)'$",
    re.IGNORECASE,
)
VAR_PLUS_OFFSET_PATTERN = re.compile(r"^(?P<left>@[A-Za-z0-9_]+)\s*\+\s*(?P<offset>-?\d+)$")
OFFSET_PLUS_VAR_PATTERN = re.compile(r"^(?P<offset>-?\d+)\s*\+\s*(?P<right>@[A-Za-z0-9_]+)$")


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
    expected_rows: tuple[dict[str, object], ...]


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


def load_rdb_column_metadata(
    logical_database: str,
) -> tuple[
    dict[tuple[str, str], list[str]] | None,
    dict[tuple[str, str], frozenset[str]] | None,
    dict[tuple[str, str, str], tuple[str, str, str]] | None,
    set[tuple[str, str, str]] | None,
    set[tuple[str, str, str]] | None,
]:
    """Load table columns, primary keys, FK links, generated columns, and auto datetime defaults from replay-metadata cache."""
    cache_file = replay_metadata_cache_file_for_database(logical_database)
    if not cache_file.exists():
        return None, None, None, None, None
    try:
        payload = json.loads(cache_file.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None, None, None, None, None
    if not isinstance(payload, dict):
        return None, None, None, None, None

    columns_by_table: dict[tuple[str, str], list[str]] = {}
    for item in payload.get("column_sql_types", []):
        key = (item["schema_name"], item["table_name"])
        columns_by_table.setdefault(key, []).append(item["column_name"])

    primary_keys_by_table: dict[tuple[str, str], frozenset[str]] = {
        (item["schema_name"], item["table_name"]): frozenset(item["columns"])
        for item in payload.get("primary_keys", [])
    }
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]] = {
        (item["source_schema"], item["source_table"], item["source_column"]): (
            item["target_schema"],
            item["target_table"],
            item["target_column"],
        )
        for item in payload.get("foreign_keys", [])
    }
    generated_always_columns: set[tuple[str, str, str]] = {
        (item["schema_name"], item["table_name"], item["column_name"])
        for item in payload.get("generated_always_columns", [])
    }
    auto_datetime_defaults: set[tuple[str, str, str]] = {
        (item["schema_name"], item["table_name"], item["column_name"])
        for item in payload.get("auto_datetime_defaults", [])
    }
    return columns_by_table, primary_keys_by_table, foreign_keys_by_source, generated_always_columns, auto_datetime_defaults


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


def load_combined_inputs(manifest_path: Path) -> tuple[dict[str, object], Path, Path, Path]:
    manifest_obj = load_json(manifest_path)
    if not isinstance(manifest_obj, dict):
        raise SystemExit(f"Combined manifest has an invalid format: {manifest_path}")

    summary_file = manifest_obj.get("cdc_summary_file")
    inserts_file = manifest_obj.get("cdc_inserts_file")
    logical_changes_file = manifest_obj.get("logical_changes_file")
    if not isinstance(summary_file, str) or not summary_file:
        raise SystemExit(f"Combined manifest is missing cdc_summary_file: {manifest_path}")
    if not isinstance(logical_changes_file, str) or not logical_changes_file:
        raise SystemExit(f"Combined manifest is missing logical_changes_file: {manifest_path}")

    summary_path = Path(summary_file)
    inserts_path = Path(inserts_file) if isinstance(inserts_file, str) and inserts_file else summary_path.with_name("inserts.sql")
    logical_changes_path = Path(logical_changes_file)
    if not summary_path.exists():
        raise SystemExit(f"CDC summary file not found: {summary_path}")
    if not inserts_path.exists():
        # Backward-compatible fallback for older artifacts where SQL was embedded in summary.txt.
        inserts_path = summary_path
    if not logical_changes_path.exists():
        raise SystemExit(f"Logical changes file not found: {logical_changes_path}")
    return manifest_obj, summary_path, inserts_path, logical_changes_path


def extract_declare_block(sql_text: str) -> list[str]:
    lines = sql_text.splitlines()
    has_reconstructed_heading = any(line.strip() == "Reconstructed SQL:" for line in lines)
    in_reconstructed_sql = not has_reconstructed_heading
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


def parse_int_literal(expression: str) -> int | None:
    stripped = expression.strip()
    if stripped.startswith("+"):
        stripped = stripped[1:]
    if stripped.startswith("-"):
        return int(stripped) if stripped[1:].isdigit() else None
    return int(stripped) if stripped.isdigit() else None


def resolve_declare_values(declare_entries: list[DeclareEntry]) -> dict[str, object]:
    resolved: dict[str, object] = {}
    pending = {entry.name: entry for entry in declare_entries if entry.expression}

    while pending:
        progressed = False
        for variable_name, entry in list(pending.items()):
            assert entry.expression is not None
            expression = entry.expression.strip()

            int_literal = parse_int_literal(expression)
            if int_literal is not None:
                resolved[variable_name] = int_literal
                del pending[variable_name]
                progressed = True
                continue

            local_id_match = LOCAL_ID_EXPRESSION_PATTERN.match(expression)
            if local_id_match:
                numeric_expression = local_id_match.group("numeric").strip()
                numeric_value: int | None = None
                numeric_variable_name = numeric_expression if numeric_expression.startswith("@") else None
                if numeric_variable_name and numeric_variable_name in resolved:
                    candidate_value = resolved[numeric_variable_name]
                    if isinstance(candidate_value, int):
                        numeric_value = candidate_value
                elif not numeric_variable_name:
                    numeric_value = parse_int_literal(numeric_expression)

                if numeric_value is not None:
                    resolved[variable_name] = (
                        local_id_match.group("prefix")
                        + str(abs(numeric_value))
                        + local_id_match.group("suffix")
                    )
                    del pending[variable_name]
                    progressed = True
                    continue

            if expression.startswith("N'") and expression.endswith("'"):
                resolved[variable_name] = expression[2:-1].replace("''", "'")
                del pending[variable_name]
                progressed = True
                continue

            var_plus_offset_match = VAR_PLUS_OFFSET_PATTERN.match(expression)
            if var_plus_offset_match:
                left_variable = var_plus_offset_match.group("left")
                left_value = resolved.get(left_variable)
                if isinstance(left_value, int):
                    resolved[variable_name] = left_value + int(var_plus_offset_match.group("offset"))
                    del pending[variable_name]
                    progressed = True
                    continue

            offset_plus_var_match = OFFSET_PLUS_VAR_PATTERN.match(expression)
            if offset_plus_var_match:
                right_variable = offset_plus_var_match.group("right")
                right_value = resolved.get(right_variable)
                if isinstance(right_value, int):
                    resolved[variable_name] = int(offset_plus_var_match.group("offset")) + right_value
                    del pending[variable_name]
                    progressed = True
                    continue

        if not progressed:
            break

    return resolved


def apply_expected_row_overrides(
    expected_rows: tuple[dict[str, object], ...],
    declare_entries: list[DeclareEntry],
) -> tuple[dict[str, object], ...]:
    resolved_declare_values = resolve_declare_values(declare_entries)
    if not resolved_declare_values:
        return expected_rows

    declare_entries_by_name = {entry.name: entry for entry in declare_entries}
    multi_candidate_group_overrides: dict[tuple[str, ...], dict[object, object]] = {}
    compatible_ambiguous_groups = {"entity_uid"}

    updated_rows: list[dict[str, object]] = []
    for row in expected_rows:
        updated_row = dict(row)
        for column_name, value in row.items():
            candidates = variable_candidates_for_value(column_name, value, declare_entries)
            if len(candidates) == 0:
                continue

            if len(candidates) == 1:
                replacement_value = resolved_declare_values.get(candidates[0])
                if replacement_value is not None:
                    updated_row[column_name] = replacement_value
                continue

            candidate_groups = {
                declaration_group(declare_entries_by_name[candidate])
                for candidate in candidates
                if candidate in declare_entries_by_name
            }
            if len(candidate_groups) != 1:
                continue
            group_name = next(iter(candidate_groups))
            if group_name not in compatible_ambiguous_groups:
                continue

            resolved_candidates = [
                resolved_declare_values[candidate]
                for candidate in candidates
                if candidate in resolved_declare_values
            ]
            if not resolved_candidates:
                continue

            key = tuple(candidates)
            overrides_for_key = multi_candidate_group_overrides.setdefault(key, {})
            if value in overrides_for_key:
                updated_row[column_name] = overrides_for_key[value]
                continue

            next_value = next((item for item in resolved_candidates if item not in overrides_for_key.values()), None)
            if next_value is None:
                continue

            overrides_for_key[value] = next_value
            updated_row[column_name] = next_value
        updated_rows.append(updated_row)
    return tuple(updated_rows)


def resolve_ambiguous_candidate(
    column_name: str,
    candidates: list[str],
    ambiguity_state: dict[tuple[str, tuple[str, ...]], int] | None,
) -> str | None:
    if ambiguity_state is None or not candidates:
        return None

    key = (normalize_identifier(column_name), tuple(candidates))
    next_index = ambiguity_state.get(key, 0)
    selected = candidates[next_index % len(candidates)]
    ambiguity_state[key] = next_index + 1
    return selected


def predicate_for_field(
    column_name: str,
    value: object,
    declare_entries: list[DeclareEntry],
    ambiguity_state: dict[tuple[str, tuple[str, ...]], int] | None = None,
) -> tuple[str, list[str]]:
    column_sql = f"[{column_name}]"
    normalized_column_name = normalize_identifier(column_name)
    is_local_id_column = normalized_column_name == "local_id" or normalized_column_name.endswith("_local_id")

    # Handle tuples as IN clauses
    if isinstance(value, tuple):
        literals = ", ".join(sql_literal(v) for v in sorted(value))
        return f"{column_sql} IN ({literals})", []

    literal_sql = sql_literal(value)
    candidates = variable_candidates_for_value(column_name, value, declare_entries)
    if len(candidates) == 1:
        return f"{column_sql} = {candidates[0]}", []
    if len(candidates) > 1:
        if is_local_id_column:
            return (
                f"{column_sql} IN ({', '.join(candidates)})",
                [f"Ambiguous variable candidates for {column_name}: {', '.join(candidates)}; using IN clause."],
            )

        selected_candidate = resolve_ambiguous_candidate(column_name, candidates, ambiguity_state)
        if selected_candidate is not None:
            return (
                f"{column_sql} = {selected_candidate}",
                [
                    (
                        f"Ambiguous variable candidates for {column_name}: {', '.join(candidates)}"
                        f"; using {selected_candidate} (round-robin)."
                    )
                ],
            )
        return (
            f"{column_sql} = {literal_sql}",
            [f"Ambiguous variable candidates for {column_name}: {', '.join(candidates)}"],
        )
    return f"{column_sql} = {literal_sql}", []


def build_lookup_scaffold_by_table(scaffolds: list[SelectScaffold]) -> dict[tuple[str, str], SelectScaffold]:
    """Pick the most stable scaffold per table for FK subquery lookups."""

    def score(scaffold: SelectScaffold) -> tuple[int, int, int]:
        return (
            1 if scaffold.identity_strategy == "business_keys" else 0,
            1 if scaffold.comparison_eligible else 0,
            -len(scaffold.where_fields),
        )

    selected: dict[tuple[str, str], SelectScaffold] = {}
    for scaffold in scaffolds:
        key = (normalize_identifier(scaffold.schema_name), normalize_identifier(scaffold.table_name))
        existing = selected.get(key)
        if existing is None or score(scaffold) > score(existing):
            selected[key] = scaffold
    return selected


def canonical_key_name(column_name: str) -> str:
    normalized = normalize_identifier(column_name)
    if normalized.startswith("d_"):
        return normalized[2:]
    return normalized


def infer_target_column_for_source_pk(
    scaffold: SelectScaffold,
    source_column: str,
    primary_keys_by_table: dict[tuple[str, str], frozenset[str]] | None,
    lookup_scaffold_by_table: dict[tuple[str, str], SelectScaffold],
) -> tuple[str, str, str] | None:
    if primary_keys_by_table is None:
        return None

    source_key_name = canonical_key_name(source_column)
    candidates: list[tuple[str, str, str]] = []

    for (schema_name, table_name), pk_columns in primary_keys_by_table.items():
        if normalize_identifier(schema_name) == normalize_identifier(scaffold.schema_name) and normalize_identifier(
            table_name
        ) == normalize_identifier(scaffold.table_name):
            continue

        if len(pk_columns) != 1:
            continue

        target_pk_column = next(iter(pk_columns))
        if canonical_key_name(target_pk_column) != source_key_name:
            continue

        lookup_scaffold = lookup_scaffold_by_table.get((normalize_identifier(schema_name), normalize_identifier(table_name)))
        if lookup_scaffold is None:
            continue

        candidates.append((schema_name, table_name, target_pk_column))

    if len(candidates) == 1:
        return candidates[0]
    return None


def fk_subquery_predicate_for_pk(
    scaffold: SelectScaffold,
    column_name: str,
    declare_entries: list[DeclareEntry],
    primary_keys_by_table: dict[tuple[str, str], frozenset[str]] | None,
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]] | None,
    lookup_scaffold_by_table: dict[tuple[str, str], SelectScaffold],
    ambiguity_state: dict[tuple[str, tuple[str, ...]], int] | None = None,
) -> tuple[str | None, list[str]]:
    if primary_keys_by_table is None or foreign_keys_by_source is None:
        return None, []

    if scaffold.identity_strategy == "business_keys":
        return None, []

    table_key = (scaffold.schema_name, scaffold.table_name)
    pk_columns = primary_keys_by_table.get(table_key, frozenset())
    if column_name.lower() not in {pk_column.lower() for pk_column in pk_columns}:
        return None, []

    # Find the value for this column
    value = None
    for col_name, col_value in scaffold.where_fields:
        if col_name.lower() == column_name.lower():
            value = col_value
            break
    
    # For tuples or single values, process normally - FK lookup should work for both
    # (tuples will be converted to IN by predicate_for_field)

    fk_key = (scaffold.schema_name, scaffold.table_name, column_name)
    foreign_key = foreign_keys_by_source.get(fk_key)
    target_comments: list[str] = []
    if foreign_key is not None:
        target_schema, target_table, target_column = foreign_key
    else:
        inferred_target = infer_target_column_for_source_pk(
            scaffold,
            column_name,
            primary_keys_by_table,
            lookup_scaffold_by_table,
        )
        if inferred_target is None:
            return None, []
        target_schema, target_table, target_column = inferred_target
        target_comments.append(
            f"Inferred lookup for {column_name} via {target_schema}.{target_table}.{target_column} (no explicit FK metadata found)."
        )

    lookup_scaffold = lookup_scaffold_by_table.get((normalize_identifier(target_schema), normalize_identifier(target_table)))
    if lookup_scaffold is None:
        return None, []

    target_predicates: list[str] = []
    uses_variable = False
    for target_field_name, target_field_value in lookup_scaffold.where_fields:
        predicate_sql, comments = predicate_for_field(
            target_field_name,
            target_field_value,
            declare_entries,
            ambiguity_state,
        )
        target_predicates.append(predicate_sql)
        target_comments.extend(comments)
        if "@" in predicate_sql:
            uses_variable = True

    if not target_predicates or not uses_variable:
        return None, []

    subquery_sql = (
        f"(SELECT [{target_column}] FROM [{target_schema}].[{target_table}] "
        f"WHERE {' AND '.join(target_predicates)})"
    )
    # Use IN for both single and multiple FK values - IN works with single values too
    return f"[{column_name}] IN {subquery_sql}", target_comments


def consolidate_fk_scaffolds(scaffolds: list[SelectScaffold]) -> list[SelectScaffold]:
    """Consolidate scaffolds differing only in FK key values by creating IN clauses."""
    
    def is_fk_field(field_name: str, value: object) -> bool:
        """Check if a field is a foreign key (contains 'key' and has numeric value)."""
        normalized = normalize_identifier(field_name)
        return "key" in normalized and isinstance(value, (int, float))
    
    def extract_non_fk_fields(where_fields: tuple[tuple[str, object], ...]) -> tuple[tuple[str, object], ...]:
        """Extract all non-FK fields from where_fields."""
        return tuple((name, value) for name, value in where_fields if not is_fk_field(name, value))
    
    # Group scaffolds by table and non-FK where fields
    groups: dict[tuple[str, str, tuple[tuple[str, object], ...]], list[SelectScaffold]] = {}
    for scaffold in scaffolds:
        non_fk_fields = extract_non_fk_fields(scaffold.where_fields)
        group_key = (scaffold.schema_name, scaffold.table_name, non_fk_fields)
        groups.setdefault(group_key, []).append(scaffold)
    
    consolidated: list[SelectScaffold] = []
    for scaffolds_in_group in groups.values():
        if len(scaffolds_in_group) == 1:
            # No consolidation needed
            consolidated.append(scaffolds_in_group[0])
            continue
        
        # Find FK fields and their values
        all_fk_fields: dict[str, list[object]] = {}
        first_scaffold = scaffolds_in_group[0]
        
        for scaffold in scaffolds_in_group:
            for field_name, value in scaffold.where_fields:
                if is_fk_field(field_name, value):
                    all_fk_fields.setdefault(field_name, []).append(value)
        
        if not all_fk_fields:
            # No FK fields to consolidate
            consolidated.extend(scaffolds_in_group)
            continue
        
        # Build consolidated where_fields with tuple for FK values
        fk_field_name = next(iter(all_fk_fields.keys()))
        fk_values = tuple(sorted(set(all_fk_fields[fk_field_name])))
        
        consolidated_where_fields = extract_non_fk_fields(first_scaffold.where_fields) + ((fk_field_name, fk_values),)
        
        # Merge expected rows from all scaffolds
        merged_expected_rows: dict[str, object] = {}
        for scaffold in scaffolds_in_group:
            for row in scaffold.expected_rows:
                row_key = json.dumps(row, sort_keys=True, separators=(',', ':'))
                if row_key not in merged_expected_rows:
                    merged_expected_rows[row_key] = row
        
        merged_rows = tuple(json.loads(row_key) for row_key in sorted(merged_expected_rows.keys()))
        
        # Build consolidated scaffold
        consolidated_scaffold = SelectScaffold(
            schema_name=first_scaffold.schema_name,
            table_name=first_scaffold.table_name,
            operation_labels=tuple(sorted(set(op for s in scaffolds_in_group for op in s.operation_labels))),
            identity_strategy=first_scaffold.identity_strategy,
            comparison_eligible=first_scaffold.comparison_eligible,
            where_fields=consolidated_where_fields,
            comments=tuple(dict.fromkeys(c for s in scaffolds_in_group for c in s.comments)),
            expected_rows=merged_rows,
        )
        consolidated.append(consolidated_scaffold)
    
    return sorted(consolidated, key=lambda item: (item.schema_name.lower(), item.table_name.lower(), item.where_fields))


def build_scaffolds(
    logical_changes: list[dict[str, object]],
    declare_entries: list[DeclareEntry],
) -> list[SelectScaffold]:
    grouped: dict[tuple[str, str, tuple[tuple[str, object], ...]], SelectScaffold] = {}
    grouped_expected_rows: dict[tuple[str, str, tuple[tuple[str, object], ...]], dict[tuple[tuple[str, object], ...], dict[str, object]]] = {}

    def row_instance_key(change: dict[str, object], ordered_fields: tuple[tuple[str, object], ...]) -> tuple[tuple[str, object], ...]:
        primary_key_values = change.get("primary_key_values")
        if isinstance(primary_key_values, dict) and primary_key_values:
            return tuple(sorted((str(key), value) for key, value in primary_key_values.items()))
        return ordered_fields

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
        expected_rows_by_key = grouped_expected_rows.setdefault(group_key, {})
        current_row_key = row_instance_key(change, ordered_fields)

        comments: list[str] = []
        if strategy != "business_keys":
            comments.append(f"Identity strategy is {strategy}; review the WHERE clause before using it as a regression assertion.")
        if not comparison_eligible:
            comments.append("Logical comparison marked this identity as not comparison-safe.")

        if operation == "delete":
            expected_rows_by_key.pop(current_row_key, None)
        else:
            after_values = change.get("after")
            if isinstance(after_values, dict) and after_values:
                expected_rows_by_key[current_row_key] = after_values

        if existing is None:
            grouped[group_key] = SelectScaffold(
                schema_name=schema_name,
                table_name=table_name,
                operation_labels=(operation,),
                identity_strategy=strategy,
                comparison_eligible=comparison_eligible,
                where_fields=ordered_fields,
                comments=tuple(comments),
                expected_rows=(),
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
            expected_rows=(),
        )

    finalized: list[SelectScaffold] = []
    for group_key, scaffold in grouped.items():
        expected_rows = tuple(
            row
            for _, row in sorted(
                grouped_expected_rows.get(group_key, {}).items(),
                key=lambda item: tuple(str(part) for field in item[0] for part in field),
            )
        )
        finalized.append(
            SelectScaffold(
                schema_name=scaffold.schema_name,
                table_name=scaffold.table_name,
                operation_labels=scaffold.operation_labels,
                identity_strategy=scaffold.identity_strategy,
                comparison_eligible=scaffold.comparison_eligible,
                where_fields=scaffold.where_fields,
                comments=scaffold.comments,
                expected_rows=expected_rows,
            )
        )

    return sorted(finalized, key=lambda item: (item.schema_name.lower(), item.table_name.lower(), item.where_fields))


def apply_known_lookup_keys(
    scaffolds: list[SelectScaffold],
    known_lookup_keys: dict[str, dict[str, object]] | None,
) -> list[SelectScaffold]:
    """Narrow scaffold WHERE fields using table-specific lookup key hints."""
    if not known_lookup_keys:
        return scaffolds

    narrowed_scaffolds: list[SelectScaffold] = []
    for scaffold in scaffolds:
        table_key = f"{scaffold.schema_name}.{scaffold.table_name}"
        table_config = known_lookup_keys.get(table_key)
        if not isinstance(table_config, dict):
            narrowed_scaffolds.append(scaffold)
            continue

        candidate_columns: list[str] = []
        lookup_column = table_config.get("lookup_column")
        if isinstance(lookup_column, str) and lookup_column:
            candidate_columns.append(lookup_column)
        fallback_columns = table_config.get("fallback_columns")
        if isinstance(fallback_columns, list):
            candidate_columns.extend(str(column) for column in fallback_columns if str(column))

        matched_fields: tuple[tuple[str, object], ...] = ()
        matched_column: str | None = None
        for candidate_column in candidate_columns:
            candidate_fields = tuple(
                field
                for field in scaffold.where_fields
                if normalize_identifier(str(field[0])) == normalize_identifier(candidate_column)
            )
            if candidate_fields:
                matched_fields = candidate_fields
                matched_column = candidate_column
                break

        if not matched_fields:
            for candidate_column in candidate_columns:
                expected_values = []
                for row in scaffold.expected_rows:
                    row_value = None
                    for row_column, value in row.items():
                        if normalize_identifier(row_column) == normalize_identifier(candidate_column):
                            row_value = value
                            break
                    if row_value is None:
                        expected_values = []
                        break
                    expected_values.append(row_value)

                if expected_values and all(value == expected_values[0] for value in expected_values[1:]):
                    matched_fields = ((candidate_column, expected_values[0]),)
                    matched_column = candidate_column
                    break

        if not matched_fields:
            narrowed_scaffolds.append(scaffold)
            continue

        comment = (
            f"WHERE clause narrowed to known lookup key: {matched_column}"
            if matched_column == candidate_columns[0]
            else f"WHERE clause narrowed to fallback lookup key: {matched_column}"
        )
        narrowed_scaffolds.append(
            SelectScaffold(
                schema_name=scaffold.schema_name,
                table_name=scaffold.table_name,
                operation_labels=scaffold.operation_labels,
                identity_strategy=scaffold.identity_strategy,
                comparison_eligible=scaffold.comparison_eligible,
                where_fields=matched_fields,
                comments=tuple(dict.fromkeys([*scaffold.comments, comment])),
                expected_rows=scaffold.expected_rows,
            )
        )

    return narrowed_scaffolds


def expected_rows_json(
    expected_rows: tuple[dict[str, object], ...],
    declare_entries: list[DeclareEntry],
    excluded_columns: frozenset[str] | None = None,
    output_column_order: list[str] | None = None,
) -> str:
    effective_expected_rows = apply_expected_row_overrides(expected_rows, declare_entries)

    excluded_column_names = {column_name.lower() for column_name in excluded_columns} if excluded_columns else set()

    filtered_rows = [
        {column_name: value for column_name, value in row.items() if column_name.lower() not in excluded_column_names}
        for row in effective_expected_rows
    ]

    if output_column_order:
        ordered_rows: list[dict[str, object]] = []
        for row in filtered_rows:
            row_keys_by_lower = {column_name.lower(): column_name for column_name in row}
            ordered_row: dict[str, object] = {}

            for column_name in output_column_order:
                row_key = row_keys_by_lower.get(column_name.lower())
                if row_key is not None:
                    ordered_row[row_key] = row[row_key]

            for column_name, value in row.items():
                if column_name not in ordered_row:
                    ordered_row[column_name] = value

            ordered_rows.append(ordered_row)

        return json.dumps(ordered_rows, separators=(",", ":"))

    return json.dumps(filtered_rows, separators=(",", ":"))


def display_path(path_value: str) -> str:
    path = Path(path_value)
    try:
        return path.resolve().relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return path_value.replace("\\", "/")


def render_sql(
    manifest: dict[str, object],
    declare_lines: list[str],
    declare_entries: list[DeclareEntry],
    scaffolds: list[SelectScaffold],
    columns_by_table: dict[tuple[str, str], list[str]] | None = None,
    primary_keys_by_table: dict[tuple[str, str], frozenset[str]] | None = None,
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]] | None = None,
    generated_always_columns: set[tuple[str, str, str]] | None = None,
    auto_datetime_defaults: set[tuple[str, str, str]] | None = None,
) -> str:
    logical_database = str(manifest.get("logical_database") or "RDB_MODERN")
    source_summary_file = display_path(str(manifest.get("cdc_summary_file") or ""))
    logical_changes_file = display_path(str(manifest.get("logical_changes_file") or ""))

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

    lookup_scaffold_by_table = build_lookup_scaffold_by_table(scaffolds)
    ambiguity_state: dict[tuple[str, tuple[str, ...]], int] = {}

    for scaffold in scaffolds:
        lines.append(f"-- {scaffold.schema_name}.{scaffold.table_name} | operations: {', '.join(scaffold.operation_labels)}")
        for comment in scaffold.comments:
            lines.append(f"-- {comment}")

        predicate_lines: list[str] = []
        predicate_comments: list[str] = []
        for index, (column_name, value) in enumerate(scaffold.where_fields):
            fk_lookup_predicate_sql, fk_lookup_comments = fk_subquery_predicate_for_pk(
                scaffold,
                column_name,
                declare_entries,
                primary_keys_by_table,
                foreign_keys_by_source,
                lookup_scaffold_by_table,
                ambiguity_state,
            )
            if fk_lookup_predicate_sql is not None:
                predicate_sql = fk_lookup_predicate_sql
                comments = fk_lookup_comments
            else:
                predicate_sql, comments = predicate_for_field(column_name, value, declare_entries, ambiguity_state)
            connector = "WHERE" if index == 0 else "  AND"
            predicate_lines.append(f"{connector} {predicate_sql}")
            predicate_comments.extend(comments)

        for comment in dict.fromkeys(predicate_comments):
            lines.append(f"-- {comment}")

        table_key = (scaffold.schema_name, scaffold.table_name)
        pk_columns = primary_keys_by_table.get(table_key, frozenset()) if primary_keys_by_table else frozenset()
        generated_excluded_for_table = frozenset(
            col for (s, t, col) in (generated_always_columns or set())
            if normalize_identifier(s) == normalize_identifier(scaffold.schema_name)
            and normalize_identifier(t) == normalize_identifier(scaffold.table_name)
        )
        auto_excluded_for_table = frozenset(
            col for (s, t, col) in (auto_datetime_defaults or set())
            if normalize_identifier(s) == normalize_identifier(scaffold.schema_name)
            and normalize_identifier(t) == normalize_identifier(scaffold.table_name)
        )
        select_excluded_columns = pk_columns | generated_excluded_for_table | auto_excluded_for_table
        json_excluded_columns = pk_columns | generated_excluded_for_table | auto_excluded_for_table
        select_columns: list[str] | None = None
        if columns_by_table is not None:
            all_columns = columns_by_table.get(table_key)
            if all_columns:
                select_excluded_normalized = {normalize_identifier(col) for col in select_excluded_columns}
                select_columns = [
                    col for col in all_columns
                    if normalize_identifier(col) not in select_excluded_normalized
                ]
        if select_columns:
            lines.append("SELECT")
            for i, col in enumerate(select_columns):
                suffix = "," if i < len(select_columns) - 1 else ""
                lines.append(f"    [{col}]{suffix}")
        else:
            lines.append("SELECT *")
        lines.append(f"FROM [{scaffold.schema_name}].[{scaffold.table_name}]")
        lines.extend(predicate_lines)
        lines.append("FOR JSON PATH;")
        lines.append("-- EXPECTED_ROWS_JSON:")
        lines.append(f"-- {expected_rows_json(scaffold.expected_rows, declare_entries, json_excluded_columns, select_columns)}")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def generate_rdb_selects_from_manifest(
    manifest_path: Path,
    output_path: Path | None = None,
) -> tuple[Path, int]:
    manifest, summary_path, inserts_path, logical_changes_path = load_combined_inputs(manifest_path)
    inserts_text = inserts_path.read_text(encoding="utf-8")
    logical_changes_obj = load_json(logical_changes_path)
    if not isinstance(logical_changes_obj, list):
        raise SystemExit(f"Logical changes file has an invalid format: {logical_changes_path}")

    declare_lines = extract_declare_block(inserts_text)
    declare_entries = parse_declare_entries(declare_lines)
    scaffolds = build_scaffolds(logical_changes_obj, declare_entries)
    known_lookup_keys_file = Path(__file__).with_name("known_lookup_keys.json")
    if known_lookup_keys_file.exists():
        try:
            known_lookup_keys_obj = json.loads(known_lookup_keys_file.read_text(encoding="utf-8"))
            if isinstance(known_lookup_keys_obj, dict):
                scaffolds = apply_known_lookup_keys(scaffolds, known_lookup_keys_obj.get("known_tables"))
        except (OSError, json.JSONDecodeError) as error:
            print(f"Warning: Could not load {known_lookup_keys_file}: {error}", file=sys.stderr)
    scaffolds = consolidate_fk_scaffolds(scaffolds)
    scaffolds = [s for s in scaffolds if not s.table_name.lower().startswith("nrt_")]
    logical_database = str(manifest.get("logical_database") or "RDB_MODERN")
    columns_by_table, primary_keys_by_table, foreign_keys_by_source, generated_always_columns, auto_datetime_defaults = load_rdb_column_metadata(logical_database)
    output_sql = render_sql(
        manifest,
        declare_lines,
        declare_entries,
        scaffolds,
        columns_by_table,
        primary_keys_by_table,
        foreign_keys_by_source,
        generated_always_columns,
        auto_datetime_defaults,
    )

    final_output_path = output_path if output_path is not None else manifest_path.with_name("rdb-selects.sql")
    final_output_path.write_text(output_sql, encoding="utf-8")
    return final_output_path, len(scaffolds)


def main() -> int:
    args = parse_args()
    manifest_path = resolve_manifest_path(args)
    requested_output_path = Path(args.output_file) if args.output_file else None
    output_path, scaffold_count = generate_rdb_selects_from_manifest(manifest_path, requested_output_path)
    print(f"Wrote RDB select scaffold: {output_path}")
    print(f"Generated SELECT statements: {scaffold_count}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("Interrupted by user", file=sys.stderr)
        raise SystemExit(130)