"""Reconstruct replayable SQL statements from captured CDC row payloads."""

from __future__ import annotations

import json
from datetime import datetime

from tracing_constants import (
    CDC_METADATA_COLUMNS,
    DEFAULT_STARTING_UID,
    DEFAULT_UID_BLOCK_SIZE_BY_CLASS,
    GENERIC_LOCAL_ID_PATTERN,
)
from tracing_models import KnownAssociation, UidAllocation, UidGeneratorEntry
from tracing_paths import (
    derived_variable_name,
    output_table_name_for_variable,
    sanitize_sql_name,
    variable_name_for_value,
)
from tracing_sql import quote_identifier, sql_literal, sql_quote


SUPERUSER_ID_VARIABLE = "@superuser_id"



def value_key(value: object) -> str:
    """Create a stable string key for arbitrary JSON-compatible values.

    Args:
        value: Value to normalize for registry lookups.

    Returns:
        str: Deterministic JSON representation of the value.
    """

    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(",", ":"))



def update_pair_key(record: dict[str, object]) -> tuple[str, str, int | None]:
    """Build the pairing key for CDC update-before and update-after rows.

    Args:
        record: Captured CDC record.

    Returns:
        tuple[str, str, int | None]: Key derived from LSN, sequence value, and
        command id.
    """

    return (str(record["start_lsn"]), str(record["seqval"]), record.get("command_id"))



def change_sort_key(record: dict[str, object]) -> tuple[str, str, int, int]:
    """Build a stable sort key for CDC rows.

    Args:
        record: Captured CDC record.

    Returns:
        tuple[str, str, int, int]: Key that keeps records ordered by LSN,
        sequence value, command id, and operation code.
    """

    command_id = record.get("command_id")
    return (
        str(record["start_lsn"]),
        str(record["seqval"]),
        -1 if command_id is None else int(command_id),
        int(record["operation_code"]),
    )



def format_value(value: object) -> str:
    """Render a Python value the same way it will appear in summaries.

    Args:
        value: Value to render.

    Returns:
        str: JSON-style string representation of the value.
    """

    return json.dumps(value, ensure_ascii=True)



def parse_int_value(value: object) -> int | None:
    """Coerce a loosely typed JSON value to an integer when safe.

    Args:
        value: Value to inspect.

    Returns:
        int | None: Parsed integer value, or None when coercion is unsafe.
    """

    if isinstance(value, bool):
        return int(value)
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value) if value.is_integer() else None
    if isinstance(value, str):
        stripped = value.strip()
        if stripped.startswith("+"):
            stripped = stripped[1:]
        if stripped.startswith("-"):
            digits = stripped[1:]
            return int(stripped) if digits.isdigit() else None
        return int(stripped) if stripped.isdigit() else None
    return None



def is_numeric_sql_type(sql_type: str) -> bool:
    """Determine whether a SQL type should be treated as numeric.

    Args:
        sql_type: SQL type string from metadata.

    Returns:
        bool: True when the SQL type represents a numeric column family.
    """

    lowered = sql_type.lower()
    return lowered.startswith(("tinyint", "smallint", "int", "bigint", "decimal", "numeric"))



def register_nrt_patient_mpr_uid_reference(
    table_key: tuple[str, str],
    row: dict[str, object],
    variable_registry: dict[tuple[str, str, str, str], str],
    column_sql_types: dict[tuple[str, str, str], str],
    prelude_lines: list[str],
    variable_name_counts: dict[str, int],
) -> None:
    if table_key != ("dbo", "nrt_patient"):
        return
    if "patient_uid" not in row or "patient_mpr_uid" not in row:
        return

    patient_uid_reference = variable_registry.get((table_key[0], table_key[1], "patient_uid", value_key(row["patient_uid"])))
    if not patient_uid_reference:
        return

    patient_mpr_uid_key = (table_key[0], table_key[1], "patient_mpr_uid", value_key(row["patient_mpr_uid"]))
    if patient_mpr_uid_key in variable_registry:
        return

    variable_name = allocate_replay_variable_name(table_key[0], table_key[1], "patient_mpr_uid", variable_name_counts)
    sql_type = column_sql_types.get((table_key[0], table_key[1], "patient_mpr_uid"), "bigint")
    prelude_lines.append(f"DECLARE {variable_name} {sql_type} = {patient_uid_reference} + 1;")
    variable_registry[patient_mpr_uid_key] = variable_name

    patient_uid_alias_key = (table_key[0], table_key[1], "patient_uid", value_key(row["patient_mpr_uid"]))
    variable_registry.setdefault(patient_uid_alias_key, variable_name)



def infer_uid_class_from_local_id(local_id: object, uid_generator_entries: list[UidGeneratorEntry]) -> str | None:
    if not isinstance(local_id, str):
        return None
    for entry in uid_generator_entries:
        if local_id.startswith(entry.uid_prefix_cd) and local_id.endswith(entry.uid_suffix_cd):
            middle = local_id[len(entry.uid_prefix_cd) : len(local_id) - len(entry.uid_suffix_cd) if entry.uid_suffix_cd else None]
            if middle.isdigit():
                return entry.class_name_cd
    return None



def extract_local_id_numeric_value(local_id: object, uid_generator_entries: list[UidGeneratorEntry]) -> int | None:
    if not isinstance(local_id, str):
        return None
    for entry in uid_generator_entries:
        if local_id.startswith(entry.uid_prefix_cd) and local_id.endswith(entry.uid_suffix_cd):
            end_index = len(local_id) - len(entry.uid_suffix_cd) if entry.uid_suffix_cd else len(local_id)
            middle = local_id[len(entry.uid_prefix_cd) : end_index]
            if middle.isdigit():
                return int(middle)
    return None



def find_uid_generator_entry_for_local_id(
    local_id: object,
    uid_generator_entries: list[UidGeneratorEntry],
) -> UidGeneratorEntry | None:
    if not isinstance(local_id, str):
        return None
    for entry in uid_generator_entries:
        if local_id.startswith(entry.uid_prefix_cd) and local_id.endswith(entry.uid_suffix_cd):
            end_index = len(local_id) - len(entry.uid_suffix_cd) if entry.uid_suffix_cd else len(local_id)
            middle = local_id[len(entry.uid_prefix_cd) : end_index]
            if middle.isdigit():
                return entry
    return None



def fallback_uid_allocation_count(entry: UidGeneratorEntry) -> int:
    return DEFAULT_UID_BLOCK_SIZE_BY_CLASS.get(entry.class_name_cd.upper(), 1)



def infer_fallback_local_id_allocation(
    local_id: object,
    uid_generator_entries: list[UidGeneratorEntry],
) -> UidAllocation | None:
    entry = find_uid_generator_entry_for_local_id(local_id, uid_generator_entries)
    if entry is None:
        return None
    return UidAllocation(
        class_name_cd=entry.class_name_cd,
        count=fallback_uid_allocation_count(entry),
        type_cd=entry.type_cd,
        uid_prefix_cd=entry.uid_prefix_cd,
        uid_suffix_cd=entry.uid_suffix_cd,
    )



def infer_local_id_components(
    local_id: object,
    uid_generator_entries: list[UidGeneratorEntry],
) -> tuple[str, str, str] | None:
    if not isinstance(local_id, str):
        return None

    entry = find_uid_generator_entry_for_local_id(local_id, uid_generator_entries)
    if entry is not None:
        end_index = len(local_id) - len(entry.uid_suffix_cd) if entry.uid_suffix_cd else len(local_id)
        middle = local_id[len(entry.uid_prefix_cd) : end_index]
        if middle.isdigit():
            return entry.uid_prefix_cd, middle, entry.uid_suffix_cd

    match = GENERIC_LOCAL_ID_PATTERN.match(local_id)
    if match is None:
        return None
    return match.group("prefix"), match.group("number"), match.group("suffix")



def local_id_max_plus_one_statements(
    variable_name: str,
    table_key: tuple[str, str],
    prefix: str,
    suffix: str,
) -> list[str]:
    prefix_length = len(prefix)
    suffix_length = len(suffix)
    local_id_column = quote_identifier("local_id")
    number_start = prefix_length + 1
    number_length_expression = f"LEN({local_id_column}) - {prefix_length} - {suffix_length}"
    numeric_payload_expression = f"TRY_CONVERT(bigint, SUBSTRING({local_id_column}, {number_start}, {number_length_expression}))"
    predicates = [
        f"{local_id_column} IS NOT NULL",
        f"{local_id_column} LIKE N'{sql_quote(prefix)}%'",
        f"LEN({local_id_column}) > {prefix_length + suffix_length}",
    ]
    if suffix:
        predicates.append(f"RIGHT({local_id_column}, {suffix_length}) = N'{sql_quote(suffix)}'")
    where_clause = " AND ".join(predicates)
    return [
        f"DECLARE {variable_name} nvarchar(40);",
        (
            f"SET {variable_name} = (SELECT N'{sql_quote(prefix)}' + CONVERT(nvarchar(20), "
            f"ISNULL(MAX({numeric_payload_expression}), 0) + 1) + N'{sql_quote(suffix)}' "
            f"FROM {quote_identifier(table_key[0])}.{quote_identifier(table_key[1])} WHERE {where_clause});"
        ),
    ]



def find_nbs_uid_generator_entry(uid_generator_entries: list[UidGeneratorEntry]) -> UidGeneratorEntry | None:
    nbs_entries = [entry for entry in uid_generator_entries if entry.type_cd.upper() == "NBS"]
    if len(nbs_entries) != 1:
        return None
    return nbs_entries[0]


def replay_base_variable_name(schema_name: str, table_name: str, column_name: str) -> str:
    return "@" + sanitize_sql_name(f"{schema_name}_{table_name}_{column_name}")


def allocate_replay_variable_name(
    schema_name: str,
    table_name: str,
    column_name: str,
    variable_name_counts: dict[str, int],
) -> str:
    base_name = replay_base_variable_name(schema_name, table_name, column_name)
    count = variable_name_counts.get(base_name, 0) + 1
    variable_name_counts[base_name] = count
    if count == 1:
        return base_name
    return derived_variable_name(base_name, str(count))


def next_negative_id_literal(id_state: dict[str, int]) -> str:
    next_value = id_state["next_value"]
    if next_value >= 0:
        id_state["next_value"] = next_value + 1
    else:
        id_state["next_value"] = next_value - 1
    return str(next_value)


def negative_id_variable_statement(variable_name: str, sql_type: str, id_state: dict[str, int]) -> str:
    return f"DECLARE {variable_name} {sql_type} = {next_negative_id_literal(id_state)};"


def local_id_literal_statement(variable_name: str, prefix: str, suffix: str, numeric_expression: str) -> str:
    return (
        f"DECLARE {variable_name} nvarchar(40) = N'{sql_quote(prefix)}' + "
        f"CONVERT(nvarchar(20), ABS(CONVERT(bigint, {numeric_expression}))) + N'{sql_quote(suffix)}';"
    )



def infer_fallback_root_uid_allocation(
    table_key: tuple[str, str],
    primary_key_column: str,
    uid_generator_entries: list[UidGeneratorEntry],
) -> UidAllocation | None:
    if primary_key_column.lower() not in {"entity_uid", "act_uid"}:
        return None
    if table_key[1].lower() not in {"entity", "act"}:
        return None

    entry = find_nbs_uid_generator_entry(uid_generator_entries)
    if entry is None:
        return None

    return UidAllocation(
        class_name_cd=entry.class_name_cd,
        count=fallback_uid_allocation_count(entry),
        type_cd=entry.type_cd,
        uid_prefix_cd=entry.uid_prefix_cd,
        uid_suffix_cd=entry.uid_suffix_cd,
    )



def allocation_variable_statements(variable_name: str, sql_type: str, allocation: UidAllocation) -> tuple[list[str], str]:
    from_variable = derived_variable_name(variable_name, "from_seed")
    to_variable = derived_variable_name(variable_name, "to_seed")
    type_variable = derived_variable_name(variable_name, "type_cd")
    prefix_variable = derived_variable_name(variable_name, "uid_prefix")
    suffix_variable = derived_variable_name(variable_name, "uid_suffix")
    lines = [
        f"DECLARE {variable_name} {sql_type};",
        f"DECLARE {from_variable} varchar(20);",
        f"DECLARE {to_variable} varchar(20);",
        f"DECLARE {type_variable} varchar(10);",
        f"DECLARE {prefix_variable} varchar(10);",
        f"DECLARE {suffix_variable} varchar(10);",
        (
            f"EXEC dbo.GetUid @classNameCd = N'{sql_quote(allocation.class_name_cd)}', @count = {allocation.count}, "
            f"@fromseedValueNbr = {from_variable} OUTPUT, @toseedValueNbr = {to_variable} OUTPUT, "
            f"@typeCd = {type_variable} OUTPUT, @uidPrefixCd = {prefix_variable} OUTPUT, @uidSuffixCd = {suffix_variable} OUTPUT;"
        ),
    ]
    return lines, from_variable



def build_uid_allocation_lookup(uid_generator_entries: list[UidGeneratorEntry]) -> dict[str, UidGeneratorEntry]:
    return {entry.class_name_cd.upper(): entry for entry in uid_generator_entries}



def infer_uid_allocation_registry(
    changes: list[dict[str, object]],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    uid_generator_entries: list[UidGeneratorEntry],
) -> dict[tuple[str, str, str, str], UidAllocation]:
    generator_entries_by_class = build_uid_allocation_lookup(uid_generator_entries)
    allocation_by_seed: dict[int, UidAllocation] = {}
    pending_updates: dict[tuple[str, str, int | None], dict[str, object]] = {}

    for record in sorted(changes, key=change_sort_key):
        table_key = (str(record["schema_name"]), str(record["table_name"]))
        if table_key != ("dbo", "Local_UID_generator"):
            continue
        if record.get("row_parse_error"):
            continue

        operation = record.get("operation")
        if operation == "update_before":
            pending_updates[update_pair_key(record)] = record
            continue
        if operation != "update_after":
            continue

        before_record = pending_updates.pop(update_pair_key(record), None)
        if before_record is None:
            continue

        before_row = before_record.get("row")
        after_row = record.get("row")
        if not isinstance(before_row, dict) or not isinstance(after_row, dict):
            continue

        class_name = str(before_row.get("class_name_cd") or after_row.get("class_name_cd") or "").strip()
        before_seed = parse_int_value(before_row.get("seed_value_nbr"))
        after_seed = parse_int_value(after_row.get("seed_value_nbr"))
        if not class_name or before_seed is None or after_seed is None or after_seed <= before_seed:
            continue

        metadata = generator_entries_by_class.get(class_name.upper())
        allocation_by_seed[before_seed] = UidAllocation(
            class_name_cd=class_name,
            count=after_seed - before_seed,
            type_cd="" if metadata is None else metadata.type_cd,
            uid_prefix_cd="" if metadata is None else metadata.uid_prefix_cd,
            uid_suffix_cd="" if metadata is None else metadata.uid_suffix_cd,
        )

    allocation_registry: dict[tuple[str, str, str, str], UidAllocation] = {}
    for record in sorted(changes, key=change_sort_key):
        if record.get("operation") != "insert":
            continue
        row = record.get("row")
        if not isinstance(row, dict):
            continue

        table_key = (str(record["schema_name"]), str(record["table_name"]))
        primary_key_columns = primary_keys_by_table.get(table_key, [])
        if len(primary_key_columns) == 1:
            primary_key_column = primary_key_columns[0]
            primary_key_value = parse_int_value(row.get(primary_key_column))
            allocation = None if primary_key_value is None else allocation_by_seed.get(primary_key_value)
            if allocation is not None:
                key = (table_key[0], table_key[1], primary_key_column, value_key(row[primary_key_column]))
                allocation_registry[key] = allocation

                foreign_key_target = foreign_keys_by_source.get((table_key[0], table_key[1], primary_key_column))
                if foreign_key_target is not None:
                    allocation_registry[(foreign_key_target[0], foreign_key_target[1], foreign_key_target[2], value_key(row[primary_key_column]))] = allocation

        if "local_id" in row:
            local_id_value = extract_local_id_numeric_value(row.get("local_id"), uid_generator_entries)
            allocation = None if local_id_value is None else allocation_by_seed.get(local_id_value)
            if allocation is not None:
                allocation_registry[(table_key[0], table_key[1], "local_id", value_key(row["local_id"]))] = allocation

    return allocation_registry



def data_columns(row: dict[str, object]) -> list[str]:
    return [column_name for column_name in row if column_name not in CDC_METADATA_COLUMNS]



def is_user_id_column(column_name: str) -> bool:
    return column_name.lower().endswith("user_id")



def is_version_column(column_name: str) -> bool:
    return column_name.lower() == "version_ctrl_nbr"



def is_history_table(table_key: tuple[str, str]) -> bool:
    return table_key[1].lower().endswith("_hist")



def generated_primary_key_column(
    table_key: tuple[str, str],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    identity_columns_by_table: dict[tuple[str, str], list[str]],
) -> str | None:
    primary_key_columns = primary_keys_by_table.get(table_key, [])
    if len(primary_key_columns) != 1:
        return None
    primary_key_column = primary_key_columns[0]
    if primary_key_column not in identity_columns_by_table.get(table_key, []):
        return None
    return primary_key_column



def should_generate_non_identity_primary_key(
    primary_key_column: str,
    column_sql_type: str,
    table_key: tuple[str, str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
) -> bool:
    if not is_numeric_sql_type(column_sql_type):
        return False
    if (table_key[0], table_key[1], primary_key_column) in foreign_keys_by_source:
        return False
    return not primary_key_column.lower().endswith("_key")



def lookup_variable_reference(
    variable_registry: dict[tuple[str, str, str, str], str],
    schema_name: str,
    table_name: str,
    column_name: str,
    serialized_value: str,
) -> str | None:
    direct_match = variable_registry.get((schema_name, table_name, column_name, serialized_value))
    if direct_match:
        return direct_match

    normalized_schema = schema_name.lower()
    normalized_table = table_name.lower()
    normalized_column = column_name.lower()
    for (registered_schema, registered_table, registered_column, registered_value), variable_name in variable_registry.items():
        if registered_value != serialized_value:
            continue
        if (
            registered_schema.lower() == normalized_schema
            and registered_table.lower() == normalized_table
            and registered_column.lower() == normalized_column
        ):
            return variable_name
    return None



def row_matches_association(row: dict[str, object], association: KnownAssociation) -> bool:
    for column_name, expected_value in association.when.items():
        if value_key(row.get(column_name)) != value_key(expected_value):
            return False
    return True



def resolve_known_association_reference(
    table_key: tuple[str, str],
    row: dict[str, object],
    column_name: str,
    value: object,
    variable_registry: dict[tuple[str, str, str, str], str],
    known_associations: list[KnownAssociation],
) -> str | None:
    normalized_schema = table_key[0].lower()
    normalized_table = table_key[1].lower()
    normalized_column = column_name.lower()
    serialized_value = value_key(value)
    for association in known_associations:
        if association.source_schema.lower() != normalized_schema:
            continue
        if association.source_table.lower() != normalized_table:
            continue
        if association.source_column.lower() != normalized_column:
            continue
        if not row_matches_association(row, association):
            continue
        target_reference = lookup_variable_reference(
            variable_registry,
            association.target_schema,
            association.target_table,
            association.target_column,
            serialized_value,
        )
        if target_reference:
            return target_reference
    return None



def resolve_suffix_variable_reference(
    column_name: str,
    value: object,
    variable_registry: dict[tuple[str, str, str, str], str],
) -> str | None:
    matches: list[str] = []
    serialized_value = value_key(value)
    normalized_column_name = column_name.lower()
    for (_, _, registered_column, registered_value), variable_name in variable_registry.items():
        if registered_value != serialized_value:
            continue
        normalized_registered_column = registered_column.lower()
        if normalized_registered_column.endswith(normalized_column_name) or normalized_column_name.endswith(normalized_registered_column):
            matches.append(variable_name)

    unique_matches = list(dict.fromkeys(matches))
    if len(unique_matches) == 1:
        return unique_matches[0]
    return None



def resolve_variable_reference(
    table_key: tuple[str, str],
    row: dict[str, object],
    column_name: str,
    value: object,
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    known_associations: list[KnownAssociation],
) -> str | None:
    serialized_value = value_key(value)
    direct_reference = lookup_variable_reference(variable_registry, table_key[0], table_key[1], column_name, serialized_value)
    if direct_reference:
        return direct_reference

    associated_reference = resolve_known_association_reference(
        table_key,
        row,
        column_name,
        value,
        variable_registry,
        known_associations,
    )
    if associated_reference:
        return associated_reference

    foreign_key_target = foreign_keys_by_source.get((table_key[0], table_key[1], column_name))
    if foreign_key_target is None:
        return resolve_suffix_variable_reference(column_name, value, variable_registry)

    target_reference = lookup_variable_reference(
        variable_registry,
        foreign_key_target[0],
        foreign_key_target[1],
        foreign_key_target[2],
        serialized_value,
    )
    if target_reference:
        return target_reference

    return resolve_suffix_variable_reference(column_name, value, variable_registry)


def local_id_numeric_expression(
    table_key: tuple[str, str],
    row: dict[str, object],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    column_sql_types: dict[tuple[str, str, str], str],
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    known_associations: list[KnownAssociation],
) -> str | None:
    candidate_columns = primary_keys_by_table.get(table_key, []) + [
        column_name
        for column_name in row
        if column_name != "local_id" and column_name.lower().endswith(("_uid", "_key", "_id"))
    ]
    seen_columns: set[str] = set()

    for column_name in candidate_columns:
        if column_name in seen_columns or column_name not in row:
            continue
        seen_columns.add(column_name)
        sql_type = column_sql_types.get((table_key[0], table_key[1], column_name), "")
        if not is_numeric_sql_type(sql_type):
            continue
        value = row.get(column_name)
        if value is None:
            continue
        variable_reference = resolve_variable_reference(
            table_key,
            row,
            column_name,
            value,
            variable_registry,
            foreign_keys_by_source,
            known_associations,
        )
        if variable_reference:
            return variable_reference

    return None



def sql_value_expression(
    table_key: tuple[str, str],
    row: dict[str, object],
    column_name: str,
    value: object,
    replay_now_window: tuple[datetime, datetime] | None,
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    known_associations: list[KnownAssociation],
) -> str:
    variable_reference = resolve_variable_reference(
        table_key,
        row,
        column_name,
        value,
        variable_registry,
        foreign_keys_by_source,
        known_associations,
    )
    if variable_reference:
        return variable_reference
    return sql_literal(value)



def sql_replay_assignment_expression(
    table_key: tuple[str, str],
    row: dict[str, object],
    column_name: str,
    value: object,
    replay_now_window: tuple[datetime, datetime] | None,
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    known_associations: list[KnownAssociation],
    superuser_id: int,
) -> str:
    if is_user_id_column(column_name):
        return SUPERUSER_ID_VARIABLE
    return sql_value_expression(
        table_key,
        row,
        column_name,
        value,
        replay_now_window,
        variable_registry,
        foreign_keys_by_source,
        known_associations,
    )



def build_version_lookup_predicates(
    table_key: tuple[str, str],
    row: dict[str, object],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    known_associations: list[KnownAssociation],
) -> str:
    key_columns = [column_name for column_name in primary_keys_by_table.get(table_key, []) if not is_version_column(column_name)]
    if not key_columns:
        key_columns = [column_name for column_name in data_columns(row) if not is_version_column(column_name)]
    return build_where_clause(table_key, row, key_columns, variable_registry, foreign_keys_by_source, known_associations)



def sql_insert_assignment_expression(
    table_key: tuple[str, str],
    row: dict[str, object],
    column_name: str,
    value: object,
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    replay_now_window: tuple[datetime, datetime] | None,
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    known_associations: list[KnownAssociation],
    superuser_id: int,
) -> str:
    if is_version_column(column_name) and is_history_table(table_key):
        predicates = build_version_lookup_predicates(
            table_key,
            row,
            primary_keys_by_table,
            variable_registry,
            foreign_keys_by_source,
            known_associations,
        )
        return (
            f"(SELECT ISNULL(MAX({quote_identifier(column_name)}), 0) + 1 "
            f"FROM {quote_identifier(table_key[0])}.{quote_identifier(table_key[1])} "
            f"WHERE {predicates})"
        )
    return sql_replay_assignment_expression(
        table_key,
        row,
        column_name,
        value,
        replay_now_window,
        variable_registry,
        foreign_keys_by_source,
        known_associations,
        superuser_id,
    )



def sql_update_assignment_expression(
    table_key: tuple[str, str],
    row: dict[str, object],
    column_name: str,
    value: object,
    replay_now_window: tuple[datetime, datetime] | None,
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    known_associations: list[KnownAssociation],
    superuser_id: int,
) -> str:
    if is_version_column(column_name):
        return f"ISNULL({quote_identifier(column_name)}, 0) + 1"
    return sql_replay_assignment_expression(
        table_key,
        row,
        column_name,
        value,
        replay_now_window,
        variable_registry,
        foreign_keys_by_source,
        known_associations,
        superuser_id,
    )



def is_generated_always_column(
    table_key: tuple[str, str],
    column_name: str,
    generated_always_columns: set[tuple[str, str, str]],
) -> bool:
    return (table_key[0], table_key[1], column_name) in generated_always_columns



def select_key_columns(row: dict[str, object], preferred_columns: list[str]) -> list[str]:
    columns = [column_name for column_name in preferred_columns if column_name in row and row[column_name] is not None]
    if columns:
        return columns
    return data_columns(row)



def build_where_clause(
    table_key: tuple[str, str],
    row: dict[str, object],
    key_columns: list[str],
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    known_associations: list[KnownAssociation],
) -> str:
    predicates: list[str] = []
    for column_name in key_columns:
        value = row.get(column_name)
        if value is None:
            predicates.append(f"{quote_identifier(column_name)} IS NULL")
        else:
            predicates.append(
                f"{quote_identifier(column_name)} = {sql_value_expression(table_key, row, column_name, value, None, variable_registry, foreign_keys_by_source, known_associations)}"
            )
    return " AND ".join(predicates) if predicates else "1 = 0"



def register_direct_primary_key_references(
    table_key: tuple[str, str],
    row: dict[str, object],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    known_associations: list[KnownAssociation],
) -> None:
    for column_name in primary_keys_by_table.get(table_key, []):
        if column_name not in row:
            continue
        variable_reference = resolve_variable_reference(
            table_key,
            row,
            column_name,
            row[column_name],
            variable_registry,
            foreign_keys_by_source,
            known_associations,
        )
        if variable_reference:
            variable_registry[(table_key[0], table_key[1], column_name, value_key(row[column_name]))] = variable_reference



def reconstruct_insert_sql(
    record: dict[str, object],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    identity_columns_by_table: dict[tuple[str, str], list[str]],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    column_sql_types: dict[tuple[str, str, str], str],
    generated_always_columns: set[tuple[str, str, str]],
    replay_now_window: tuple[datetime, datetime] | None,
    variable_registry: dict[tuple[str, str, str, str], str],
    uid_generator_entries: list[UidGeneratorEntry],
    known_associations: list[KnownAssociation],
    variable_name_counts: dict[str, int],
    id_state: dict[str, int],
    superuser_id: int,
    top_level_declarations: list[str],
) -> str | None:
    row = record.get("row")
    if not isinstance(row, dict):
        return None

    table_key = (str(record["schema_name"]), str(record["table_name"]))
    generated_primary_key = generated_primary_key_column(table_key, primary_keys_by_table, identity_columns_by_table)
    primary_key_columns = primary_keys_by_table.get(table_key, [])
    root_generated_primary_key: str | None = None

    if len(primary_key_columns) == 1 and primary_key_columns[0] in row:
        primary_key_column = primary_key_columns[0]
        existing_primary_key_variable = resolve_variable_reference(
            table_key,
            row,
            primary_key_column,
            row[primary_key_column],
            variable_registry,
            foreign_keys_by_source,
            known_associations,
        )
        if existing_primary_key_variable:
            variable_registry[(table_key[0], table_key[1], primary_key_column, value_key(row[primary_key_column]))] = existing_primary_key_variable
        elif generated_primary_key is None:
            column_sql_type = column_sql_types.get((table_key[0], table_key[1], primary_key_column), "")
            if should_generate_non_identity_primary_key(
                primary_key_column,
                column_sql_type,
                table_key,
                foreign_keys_by_source,
            ):
                root_generated_primary_key = primary_key_column

    columns = [
        column_name
        for column_name in data_columns(row)
        if column_name != generated_primary_key and not is_generated_always_column(table_key, column_name, generated_always_columns)
    ]
    if not columns:
        return None

    prelude_lines: list[str] = []
    post_insert_lines: list[str] = []
    if generated_primary_key and generated_primary_key in row:
        generated_value = row[generated_primary_key]
        variable_name = allocate_replay_variable_name(table_key[0], table_key[1], generated_primary_key, variable_name_counts)
        output_table_name = output_table_name_for_variable(variable_name)
        sql_type = column_sql_types.get((table_key[0], table_key[1], generated_primary_key), "int")
        variable_registry[(table_key[0], table_key[1], generated_primary_key, value_key(generated_value))] = variable_name
        prelude_lines.extend([
            f"DECLARE {variable_name} {sql_type};",
            f"DECLARE {output_table_name} TABLE ([value] {sql_type});",
        ])
    elif root_generated_primary_key and root_generated_primary_key in row:
        generated_value = row[root_generated_primary_key]
        variable_name = allocate_replay_variable_name(table_key[0], table_key[1], root_generated_primary_key, variable_name_counts)
        sql_type = column_sql_types.get((table_key[0], table_key[1], root_generated_primary_key), "int")
        variable_registry[(table_key[0], table_key[1], root_generated_primary_key, value_key(generated_value))] = variable_name
        top_level_declarations.append(negative_id_variable_statement(variable_name, sql_type, id_state))

    local_id_key = (table_key[0], table_key[1], "local_id", value_key(row.get("local_id")))
    if "local_id" in row and local_id_key not in variable_registry:
        local_id_components = infer_local_id_components(row.get("local_id"), uid_generator_entries)
        if local_id_components is not None:
            local_id_variable = allocate_replay_variable_name(table_key[0], table_key[1], "local_id", variable_name_counts)
            numeric_expression = local_id_numeric_expression(
                table_key,
                row,
                primary_keys_by_table,
                column_sql_types,
                variable_registry,
                foreign_keys_by_source,
                known_associations,
            )
            if numeric_expression is None:
                numeric_expression = next_negative_id_literal(id_state)
            prelude_lines.append(local_id_literal_statement(local_id_variable, local_id_components[0], local_id_components[2], numeric_expression))
            variable_registry[local_id_key] = local_id_variable

    register_nrt_patient_mpr_uid_reference(
        table_key,
        row,
        variable_registry,
        column_sql_types,
        prelude_lines,
        variable_name_counts,
    )

    column_sql = ", ".join(quote_identifier(column_name) for column_name in columns)
    value_sql = ", ".join(
        sql_insert_assignment_expression(
            table_key,
            row,
            column_name,
            row[column_name],
            primary_keys_by_table,
            replay_now_window,
            variable_registry,
            foreign_keys_by_source,
            known_associations,
            superuser_id,
        )
        for column_name in columns
    )

    insert_sql = f"INSERT INTO {quote_identifier(str(record['schema_name']))}.{quote_identifier(str(record['table_name']))} ({column_sql})"
    if generated_primary_key and generated_primary_key in row:
        variable_name = variable_registry[(table_key[0], table_key[1], generated_primary_key, value_key(row[generated_primary_key]))]
        output_table_name = output_table_name_for_variable(variable_name)
        insert_sql += f" OUTPUT INSERTED.{quote_identifier(generated_primary_key)} INTO {output_table_name} ([value])"
    insert_sql += f" VALUES ({value_sql});"

    if generated_primary_key and generated_primary_key in row:
        variable_name = variable_registry[(table_key[0], table_key[1], generated_primary_key, value_key(row[generated_primary_key]))]
        output_table_name = output_table_name_for_variable(variable_name)
        post_insert_lines.append(f"SELECT TOP 1 {variable_name} = [value] FROM {output_table_name};")

    register_direct_primary_key_references(table_key, row, primary_keys_by_table, variable_registry, foreign_keys_by_source, known_associations)
    return "\n".join([*prelude_lines, insert_sql, *post_insert_lines])



def reconstruct_delete_sql(
    record: dict[str, object],
    primary_key_columns: list[str],
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    known_associations: list[KnownAssociation],
) -> str | None:
    row = record.get("row")
    if not isinstance(row, dict):
        return None
    table_key = (str(record["schema_name"]), str(record["table_name"]))
    key_columns = select_key_columns(row, primary_key_columns)
    where_clause = build_where_clause(table_key, row, key_columns, variable_registry, foreign_keys_by_source, known_associations)
    return f"DELETE FROM {quote_identifier(str(record['schema_name']))}.{quote_identifier(str(record['table_name']))} WHERE {where_clause};"



def reconstruct_update_sql(
    before_record: dict[str, object],
    after_record: dict[str, object],
    primary_key_columns: list[str],
    generated_always_columns: set[tuple[str, str, str]],
    replay_now_window: tuple[datetime, datetime] | None,
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    known_associations: list[KnownAssociation],
    superuser_id: int,
) -> str | None:
    before_row = before_record.get("row")
    after_row = after_record.get("row")
    if not isinstance(before_row, dict) or not isinstance(after_row, dict):
        return None

    table_key = (str(after_record["schema_name"]), str(after_record["table_name"]))
    changed_columns = [
        column_name
        for column_name in data_columns(after_row)
        if before_row.get(column_name) != after_row.get(column_name)
        and not is_generated_always_column(table_key, column_name, generated_always_columns)
    ]
    if not changed_columns:
        return None

    set_clause = ", ".join(
        f"{quote_identifier(column_name)} = {sql_update_assignment_expression(table_key, after_row, column_name, after_row.get(column_name), replay_now_window, variable_registry, foreign_keys_by_source, known_associations, superuser_id)}"
        for column_name in changed_columns
    )
    key_columns = select_key_columns(before_row, primary_key_columns)
    where_clause = build_where_clause(table_key, before_row, key_columns, variable_registry, foreign_keys_by_source, known_associations)
    return f"UPDATE {quote_identifier(str(after_record['schema_name']))}.{quote_identifier(str(after_record['table_name']))} SET {set_clause} WHERE {where_clause};"



def append_sql_statement(
    statements: list[str],
    last_table_key: tuple[str, str] | None,
    table_key: tuple[str, str],
    sql_statement: str,
) -> tuple[str, str]:
    if last_table_key != table_key:
        if statements:
            statements.append("")
        statements.append(f"-- {table_key[0]}.{table_key[1]}")
    statements.append(sql_statement)
    return table_key


def should_skip_reconstructed_change(table_key: tuple[str, str], operation: str) -> bool:
    return operation == "insert" and (table_key == ("dbo", "Security_log") or is_history_table(table_key))



def reconstruct_sql_statements(
    changes: list[dict[str, object]],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    identity_columns_by_table: dict[tuple[str, str], list[str]],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    column_sql_types: dict[tuple[str, str, str], str],
    generated_always_columns: set[tuple[str, str, str]],
    uid_generator_entries: list[UidGeneratorEntry],
    known_associations: list[KnownAssociation],
    replay_now_window: tuple[datetime, datetime] | None = None,
    superuser_id: int = 10009282,
    starting_uid: int = DEFAULT_STARTING_UID,
) -> list[str]:
    statements: list[str] = []
    top_level_declarations: list[str] = [
        f"DECLARE {SUPERUSER_ID_VARIABLE} bigint = {superuser_id};",
        "",
        "-- Adjust the UID declarations below manually so they remain unique across other tests.",
    ]
    pending_updates: dict[tuple[str, str, int | None], dict[str, object]] = {}
    variable_registry: dict[tuple[str, str, str, str], str] = {}
    variable_name_counts: dict[str, int] = {}
    id_state = {"next_value": starting_uid}
    last_table_key: tuple[str, str] | None = None

    for record in sorted(changes, key=change_sort_key):
        table_key = (str(record["schema_name"]), str(record["table_name"]))
        if table_key == ("dbo", "Local_UID_generator"):
            continue
        operation = str(record["operation"])
        if should_skip_reconstructed_change(table_key, operation):
            continue
        if record.get("row_parse_error"):
            table_name = f"{record['schema_name']}.{record['table_name']}"
            last_table_key = append_sql_statement(
                statements,
                last_table_key,
                table_key,
                f"-- Skipped {record['operation']} for {table_name} at {record['start_lsn']} because row payload could not be parsed",
            )
            continue

        primary_key_columns = primary_keys_by_table.get(table_key, [])

        if operation == "insert":
            sql_statement = reconstruct_insert_sql(
                record,
                primary_keys_by_table,
                identity_columns_by_table,
                foreign_keys_by_source,
                column_sql_types,
                generated_always_columns,
                replay_now_window,
                variable_registry,
                uid_generator_entries,
                known_associations,
                variable_name_counts,
                id_state,
                superuser_id,
                top_level_declarations,
            )
            if sql_statement:
                last_table_key = append_sql_statement(statements, last_table_key, table_key, sql_statement)
            continue

        if operation == "delete":
            sql_statement = reconstruct_delete_sql(
                record,
                primary_key_columns,
                variable_registry,
                foreign_keys_by_source,
                known_associations,
            )
            if sql_statement:
                last_table_key = append_sql_statement(statements, last_table_key, table_key, sql_statement)
            continue

        if operation == "update_before":
            pending_updates[update_pair_key(record)] = record
            continue

        if operation == "update_after":
            before_record = pending_updates.pop(update_pair_key(record), None)
            if before_record is None:
                last_table_key = append_sql_statement(
                    statements,
                    last_table_key,
                    table_key,
                    f"-- Skipped update for {record['schema_name']}.{record['table_name']} at {record['start_lsn']} because the before image was missing",
                )
                continue
            sql_statement = reconstruct_update_sql(
                before_record,
                record,
                primary_key_columns,
                generated_always_columns,
                replay_now_window,
                variable_registry,
                foreign_keys_by_source,
                known_associations,
                superuser_id,
            )
            if sql_statement:
                last_table_key = append_sql_statement(statements, last_table_key, table_key, sql_statement)
            continue

    for orphan in pending_updates.values():
        orphan_table_key = (str(orphan["schema_name"]), str(orphan["table_name"]))
        last_table_key = append_sql_statement(
            statements,
            last_table_key,
            orphan_table_key,
            f"-- Skipped update for {orphan['schema_name']}.{orphan['table_name']} at {orphan['start_lsn']} because the after image was missing",
        )

    if not top_level_declarations:
        return statements

    if not statements:
        return top_level_declarations

    return [*top_level_declarations, "", *statements]
