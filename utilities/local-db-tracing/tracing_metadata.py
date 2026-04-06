"""Load and cache SQL Server metadata needed to reconstruct CDC replay."""

from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

from tracing_constants import REPLAY_METADATA_CACHE_VERSION
from tracing_models import PrimaryKeyColumn, TableStatus, CaptureInstance, UidGeneratorEntry
from tracing_paths import replay_metadata_cache_file_for_database
from tracing_sql import SqlCmdClient, read_tsv, sql_identifier, sql_quote
from tracing_state import utc_now



def fetch_database_cdc_enabled(client: SqlCmdClient, database: str) -> bool:
    """Check whether CDC is enabled at the database level.

    Args:
        client: SQL Server client used to query metadata.
        database: Database name to inspect.

    Returns:
        bool: True when database-level CDC is enabled.
    """

    sql = f"""
SET NOCOUNT ON;
SELECT CASE WHEN is_cdc_enabled = 1 THEN '1' ELSE '0' END
FROM sys.databases
WHERE name = '{sql_quote(database)}';
"""
    return client.query(sql, database="master").strip() == "1"



def enable_database_cdc(client: SqlCmdClient, database: str) -> tuple[bool, str]:
    """Attempt to enable CDC for a database.

    Args:
        client: SQL Server client used to execute the CDC enable command.
        database: Database name to enable.

    Returns:
        tuple[bool, str]: Whether CDC ended up enabled and any detail returned
        by SQL Server.
    """

    database_literal = sql_quote(database)
    database_identifier = sql_identifier(database)
    sql = f"""
SET NOCOUNT ON;
USE [{database_identifier}];
BEGIN TRY
    EXEC sys.sp_cdc_enable_db;
    SELECT 'ENABLED' AS status, '' AS detail;
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() LIKE '%principal "dbo" does not exist%'
    BEGIN
        BEGIN TRY
            EXEC (N'ALTER AUTHORIZATION ON DATABASE::[{database_identifier}] TO [sa];');
            EXEC sys.sp_cdc_enable_db;
            SELECT 'ENABLED' AS status, 'Assigned database owner to sa before enabling CDC.' AS detail;
        END TRY
        BEGIN CATCH
            SELECT 'SKIPPED' AS status, ERROR_MESSAGE() AS detail;
        END CATCH;
    END
    ELSE
    BEGIN
        SELECT 'SKIPPED' AS status, ERROR_MESSAGE() AS detail;
    END
END CATCH;
SELECT CASE WHEN is_cdc_enabled = 1 THEN '1' ELSE '0' END
FROM sys.databases
WHERE name = '{database_literal}';
"""
    rows = list(read_tsv(client.query(sql, database="master")))
    if not rows:
        return False, "No response from SQL Server"

    status = rows[0][0]
    detail = rows[0][1] if len(rows[0]) > 1 else ""
    is_enabled = rows[-1][0] == "1"
    return status == "ENABLED" or is_enabled, detail



def disable_database_cdc(client: SqlCmdClient, database: str) -> tuple[bool, str]:
    """Attempt to disable CDC for a database.

    Args:
        client: SQL Server client used to execute the CDC disable command.
        database: Database name to disable.

    Returns:
        tuple[bool, str]: Whether CDC was disabled and any detail returned by
        SQL Server.
    """

    sql = """
SET NOCOUNT ON;
BEGIN TRY
    EXEC sys.sp_cdc_disable_db;
    SELECT 'DISABLED' AS status, '' AS detail;
END TRY
BEGIN CATCH
    SELECT 'SKIPPED' AS status, ERROR_MESSAGE() AS detail;
END CATCH;
"""
    rows = list(read_tsv(client.query(sql, database=database)))
    if not rows:
        return False, "No response from SQL Server"
    return rows[0][0] == "DISABLED", rows[0][1] if len(rows[0]) > 1 else ""



def fetch_table_statuses(client: SqlCmdClient) -> list[TableStatus]:
    """Fetch CDC tracking status for user tables in the active database.

    Args:
        client: SQL Server client used to query table metadata.

    Returns:
        list[TableStatus]: Table status entries ordered by schema and table.
    """

    sql = """
SET NOCOUNT ON;
SELECT
    s.name,
    t.name,
    CASE WHEN t.is_tracked_by_cdc = 1 THEN '1' ELSE '0' END
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND s.name <> 'cdc'
ORDER BY s.name, t.name;
"""
    return [TableStatus(row[0], row[1], row[2] == "1") for row in read_tsv(client.query(sql))]



def fetch_capture_instances(client: SqlCmdClient) -> list[CaptureInstance]:
    """Fetch CDC capture instances for tracked tables.

    Args:
        client: SQL Server client used to query CDC metadata.

    Returns:
        list[CaptureInstance]: Capture instances ordered by schema and table.
    """

    sql = """
SET NOCOUNT ON;
SELECT
    s.name,
    t.name,
    ct.capture_instance
FROM cdc.change_tables ct
JOIN sys.tables t ON t.object_id = ct.source_object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
ORDER BY s.name, t.name;
"""
    return [CaptureInstance(row[0], row[1], row[2]) for row in read_tsv(client.query(sql))]



def fetch_primary_key_columns(client: SqlCmdClient) -> dict[tuple[str, str], list[str]]:
    """Fetch ordered primary-key columns for each user table.

    Args:
        client: SQL Server client used to query relational metadata.

    Returns:
        dict[tuple[str, str], list[str]]: Mapping of table keys to ordered
        primary-key column names.
    """

    sql = """
SET NOCOUNT ON;
SELECT
    s.name,
    t.name,
    c.name,
    CAST(ic.key_ordinal AS varchar(20))
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.indexes i ON i.object_id = t.object_id AND i.is_primary_key = 1
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, ic.key_ordinal;
"""
    columns_by_table: defaultdict[tuple[str, str], list[PrimaryKeyColumn]] = defaultdict(list)
    for row in read_tsv(client.query(sql)):
        columns_by_table[(row[0], row[1])].append(
            PrimaryKeyColumn(
                schema_name=row[0],
                table_name=row[1],
                column_name=row[2],
                key_ordinal=int(row[3]),
            )
        )

    return {
        table_key: [column.column_name for column in sorted(columns, key=lambda item: item.key_ordinal)]
        for table_key, columns in columns_by_table.items()
    }



def fetch_identity_columns(client: SqlCmdClient) -> dict[tuple[str, str], list[str]]:
    """Fetch identity columns for each user table.

    Args:
        client: SQL Server client used to query relational metadata.

    Returns:
        dict[tuple[str, str], list[str]]: Mapping of table keys to identity
        column names.
    """

    sql = """
SET NOCOUNT ON;
SELECT
    s.name,
    t.name,
    c.name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.is_ms_shipped = 0
  AND c.is_identity = 1
ORDER BY s.name, t.name, c.column_id;
"""
    identities: defaultdict[tuple[str, str], list[str]] = defaultdict(list)
    for row in read_tsv(client.query(sql)):
        identities[(row[0], row[1])].append(row[2])
    return dict(identities)



def fetch_foreign_key_columns(client: SqlCmdClient) -> dict[tuple[str, str, str], tuple[str, str, str]]:
    """Fetch source-to-target foreign-key column mappings.

    Args:
        client: SQL Server client used to query relational metadata.

    Returns:
        dict[tuple[str, str, str], tuple[str, str, str]]: Mapping from source
        schema, table, and column to the referenced schema, table, and column.
    """

    sql = """
SET NOCOUNT ON;
SELECT
    src_schema.name,
    src_table.name,
    src_column.name,
    target_schema.name,
    target_table.name,
    target_column.name
FROM sys.foreign_key_columns fkc
JOIN sys.tables src_table ON src_table.object_id = fkc.parent_object_id
JOIN sys.schemas src_schema ON src_schema.schema_id = src_table.schema_id
JOIN sys.columns src_column ON src_column.object_id = fkc.parent_object_id AND src_column.column_id = fkc.parent_column_id
JOIN sys.tables target_table ON target_table.object_id = fkc.referenced_object_id
JOIN sys.schemas target_schema ON target_schema.schema_id = target_table.schema_id
JOIN sys.columns target_column ON target_column.object_id = fkc.referenced_object_id AND target_column.column_id = fkc.referenced_column_id
WHERE src_table.is_ms_shipped = 0
  AND target_table.is_ms_shipped = 0
ORDER BY src_schema.name, src_table.name, fkc.constraint_column_id;
"""
    foreign_keys: dict[tuple[str, str, str], tuple[str, str, str]] = {}
    for row in read_tsv(client.query(sql)):
        foreign_keys[(row[0], row[1], row[2])] = (row[3], row[4], row[5])
    return foreign_keys



def fetch_column_sql_types(client: SqlCmdClient) -> dict[tuple[str, str, str], str]:
    """Fetch normalized SQL type strings for user-table columns.

    Args:
        client: SQL Server client used to query column metadata.

    Returns:
        dict[tuple[str, str, str], str]: Mapping of schema, table, and column
        to a replay-ready SQL type string.
    """

    sql = """
SET NOCOUNT ON;
SELECT
    s.name,
    t.name,
    c.name,
    CASE
        WHEN ty.name IN ('varchar', 'char', 'binary', 'varbinary')
            THEN ty.name + '(' + CASE WHEN c.max_length = -1 THEN 'max' ELSE CAST(c.max_length AS varchar(20)) END + ')'
        WHEN ty.name IN ('nvarchar', 'nchar')
            THEN ty.name + '(' + CASE WHEN c.max_length = -1 THEN 'max' ELSE CAST(c.max_length / 2 AS varchar(20)) END + ')'
        WHEN ty.name IN ('decimal', 'numeric')
            THEN ty.name + '(' + CAST(c.precision AS varchar(20)) + ',' + CAST(c.scale AS varchar(20)) + ')'
        WHEN ty.name IN ('datetime2', 'datetimeoffset', 'time')
            THEN ty.name + '(' + CAST(c.scale AS varchar(20)) + ')'
        ELSE ty.name
    END
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;
"""
    column_types: dict[tuple[str, str, str], str] = {}
    for row in read_tsv(client.query(sql)):
        column_types[(row[0], row[1], row[2])] = row[3]
    return column_types



def fetch_generated_always_columns(client: SqlCmdClient) -> set[tuple[str, str, str]]:
    """Fetch columns that SQL Server always generates automatically.

    Args:
        client: SQL Server client used to query column metadata.

    Returns:
        set[tuple[str, str, str]]: Schema, table, and column tuples for
        generated-always columns.
    """

    sql = """
SET NOCOUNT ON;
SELECT
    s.name,
    t.name,
    c.name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.is_ms_shipped = 0
  AND c.generated_always_type <> 0
ORDER BY s.name, t.name, c.column_id;
"""
    generated_columns: set[tuple[str, str, str]] = set()
    for row in read_tsv(client.query(sql)):
        generated_columns.add((row[0], row[1], row[2]))
    return generated_columns



def fetch_uid_generator_entries(client: SqlCmdClient) -> list[UidGeneratorEntry]:
    """Fetch Local_UID_generator rows when the table exists.

    Args:
        client: SQL Server client used to query ODSE metadata.

    Returns:
        list[UidGeneratorEntry]: Generator rows used for replay-time ID
        allocation.
    """

    sql = """
SET NOCOUNT ON;
IF OBJECT_ID(N'dbo.Local_UID_generator', N'U') IS NOT NULL
BEGIN
    SELECT
        ISNULL(class_name_cd, ''),
        ISNULL(type_cd, ''),
        ISNULL(UID_prefix_cd, ''),
        ISNULL(UID_suffix_CD, '')
    FROM dbo.Local_UID_generator
    ORDER BY class_name_cd;
END;
"""
    entries: list[UidGeneratorEntry] = []
    for row in read_tsv(client.query(sql)):
        entries.append(
            UidGeneratorEntry(
                class_name_cd=row[0] if len(row) > 0 else "",
                type_cd=row[1] if len(row) > 1 else "",
                uid_prefix_cd=row[2] if len(row) > 2 else "",
                uid_suffix_cd=row[3] if len(row) > 3 else "",
            )
        )
    return entries



def save_replay_metadata_cache(
    cache_file: Path,
    database: str,
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    identity_columns_by_table: dict[tuple[str, str], list[str]],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    column_sql_types: dict[tuple[str, str, str], str],
    generated_always_columns: set[tuple[str, str, str]],
    uid_generator_entries: list[UidGeneratorEntry],
) -> None:
    """Persist replay metadata so repeated tracing runs can skip re-querying it.

    Args:
        cache_file: Cache file path to write.
        database: Database name the metadata belongs to.
        primary_keys_by_table: Ordered primary-key columns by table.
        identity_columns_by_table: Identity columns by table.
        foreign_keys_by_source: Foreign-key column mappings.
        column_sql_types: Replay-ready SQL type strings by column.
        generated_always_columns: Generated-always columns.
        uid_generator_entries: Local UID generator metadata.
    """

    payload = {
        "cache_version": REPLAY_METADATA_CACHE_VERSION,
        "database": database,
        "saved_at_utc": utc_now(),
        "primary_keys": [
            {"schema_name": schema_name, "table_name": table_name, "columns": columns}
            for (schema_name, table_name), columns in sorted(primary_keys_by_table.items())
        ],
        "identity_columns": [
            {"schema_name": schema_name, "table_name": table_name, "columns": columns}
            for (schema_name, table_name), columns in sorted(identity_columns_by_table.items())
        ],
        "foreign_keys": [
            {
                "source_schema": source_schema,
                "source_table": source_table,
                "source_column": source_column,
                "target_schema": target_schema,
                "target_table": target_table,
                "target_column": target_column,
            }
            for (source_schema, source_table, source_column), (target_schema, target_table, target_column) in sorted(
                foreign_keys_by_source.items()
            )
        ],
        "column_sql_types": [
            {
                "schema_name": schema_name,
                "table_name": table_name,
                "column_name": column_name,
                "sql_type": sql_type,
            }
            for (schema_name, table_name, column_name), sql_type in sorted(column_sql_types.items())
        ],
        "generated_always_columns": [
            {"schema_name": schema_name, "table_name": table_name, "column_name": column_name}
            for (schema_name, table_name, column_name) in sorted(generated_always_columns)
        ],
        "uid_generators": [
            {
                "class_name_cd": entry.class_name_cd,
                "type_cd": entry.type_cd,
                "uid_prefix_cd": entry.uid_prefix_cd,
                "uid_suffix_cd": entry.uid_suffix_cd,
            }
            for entry in uid_generator_entries
        ],
    }
    cache_file.parent.mkdir(parents=True, exist_ok=True)
    cache_file.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")



def load_replay_metadata_cache(
    cache_file: Path,
    database: str,
) -> tuple[
    dict[tuple[str, str], list[str]],
    dict[tuple[str, str], list[str]],
    dict[tuple[str, str, str], tuple[str, str, str]],
    dict[tuple[str, str, str], str],
    set[tuple[str, str, str]],
    list[UidGeneratorEntry],
] | None:
    """Load cached replay metadata when it matches the current database.

    Args:
        cache_file: Cache file path to read.
        database: Database name expected in the cache.

    Returns:
        tuple[...] | None: Cached replay metadata when present and compatible,
        otherwise None.

    Raises:
        SystemExit: If the cache file exists but is malformed.
    """

    if not cache_file.exists():
        return None

    try:
        payload = json.loads(cache_file.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise SystemExit(f"Replay metadata cache is not valid JSON: {cache_file} | {error}") from error

    if not isinstance(payload, dict):
        raise SystemExit(f"Replay metadata cache has an invalid format: {cache_file}")

    if payload.get("cache_version") != REPLAY_METADATA_CACHE_VERSION:
        return None

    if payload.get("database") != database:
        return None

    if "uid_generators" not in payload or "generated_always_columns" not in payload:
        return None

    primary_keys_by_table = {
        (item["schema_name"], item["table_name"]): list(item["columns"])
        for item in payload.get("primary_keys", [])
    }
    identity_columns_by_table = {
        (item["schema_name"], item["table_name"]): list(item["columns"])
        for item in payload.get("identity_columns", [])
    }
    foreign_keys_by_source = {
        (item["source_schema"], item["source_table"], item["source_column"]): (
            item["target_schema"],
            item["target_table"],
            item["target_column"],
        )
        for item in payload.get("foreign_keys", [])
    }
    column_sql_types = {
        (item["schema_name"], item["table_name"], item["column_name"]): item["sql_type"]
        for item in payload.get("column_sql_types", [])
    }
    generated_always_columns = {
        (item["schema_name"], item["table_name"], item["column_name"])
        for item in payload.get("generated_always_columns", [])
    }
    uid_generator_entries = [
        UidGeneratorEntry(
            class_name_cd=item["class_name_cd"],
            type_cd=item["type_cd"],
            uid_prefix_cd=item["uid_prefix_cd"],
            uid_suffix_cd=item["uid_suffix_cd"],
        )
        for item in payload.get("uid_generators", [])
    ]
    return (
        primary_keys_by_table,
        identity_columns_by_table,
        foreign_keys_by_source,
        column_sql_types,
        generated_always_columns,
        uid_generator_entries,
    )



def get_replay_metadata(
    client: SqlCmdClient,
    database: str,
) -> tuple[
    dict[tuple[str, str], list[str]],
    dict[tuple[str, str], list[str]],
    dict[tuple[str, str, str], tuple[str, str, str]],
    dict[tuple[str, str, str], str],
    set[tuple[str, str, str]],
    list[UidGeneratorEntry],
]:
    """Load replay metadata from cache or SQL Server.

    Args:
        client: SQL Server client used when cache data is unavailable.
        database: Database name whose metadata should be returned.

    Returns:
        tuple[dict[tuple[str, str], list[str]], dict[tuple[str, str], list[str]],
        dict[tuple[str, str, str], tuple[str, str, str]],
        dict[tuple[str, str, str], str], set[tuple[str, str, str]],
        list[UidGeneratorEntry]]: Replay metadata collections used by summary
        generation and SQL reconstruction.
    """

    cache_file = replay_metadata_cache_file_for_database(database)
    cached = load_replay_metadata_cache(cache_file, database)
    if cached is not None:
        return cached

    primary_keys_by_table = fetch_primary_key_columns(client)
    identity_columns_by_table = fetch_identity_columns(client)
    foreign_keys_by_source = fetch_foreign_key_columns(client)
    column_sql_types = fetch_column_sql_types(client)
    generated_always_columns = fetch_generated_always_columns(client)
    uid_generator_entries = fetch_uid_generator_entries(client)
    save_replay_metadata_cache(
        cache_file,
        database,
        primary_keys_by_table,
        identity_columns_by_table,
        foreign_keys_by_source,
        column_sql_types,
        generated_always_columns,
        uid_generator_entries,
    )
    return (
        primary_keys_by_table,
        identity_columns_by_table,
        foreign_keys_by_source,
        column_sql_types,
        generated_always_columns,
        uid_generator_entries,
    )
