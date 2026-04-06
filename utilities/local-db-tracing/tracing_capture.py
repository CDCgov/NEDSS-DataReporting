"""Capture CDC rows and manage table-level CDC enablement for tracing runs."""

from __future__ import annotations

import json
from time import perf_counter

from tracing_models import CaptureInstance
from tracing_post_processing import log_progress
from tracing_sql import SqlCmdClient, quote_identifier, read_tsv, sql_quote



def fetch_max_lsn(client: SqlCmdClient) -> str:
    """Fetch the current maximum CDC LSN from SQL Server.

    Args:
        client: SQL Server client used to query CDC metadata.

    Returns:
        str: The current CDC max LSN encoded as a SQL Server hex literal.

    Raises:
        SystemExit: If SQL Server does not return an LSN value.
    """

    sql = """
SET NOCOUNT ON;
SELECT master.dbo.fn_varbintohexstr(sys.fn_cdc_get_max_lsn());
"""
    value = client.query(sql).strip()
    if not value:
        raise SystemExit("Could not determine current CDC max LSN")
    return value



def enable_table_cdc(client: SqlCmdClient, schema_name: str, table_name: str) -> tuple[bool, str]:
    """Attempt to enable CDC for one source table.

    Args:
        client: SQL Server client used to execute the CDC enable command.
        schema_name: Source schema name.
        table_name: Source table name.

    Returns:
        tuple[bool, str]: Whether the table was enabled and any detail returned
        by SQL Server.
    """

    sql = f"""
SET NOCOUNT ON;
BEGIN TRY
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'{sql_quote(schema_name)}',
        @source_name = N'{sql_quote(table_name)}',
        @role_name = NULL,
        @supports_net_changes = 0;
    SELECT 'ENABLED' AS status, '' AS detail;
END TRY
BEGIN CATCH
    SELECT 'SKIPPED' AS status, ERROR_MESSAGE() AS detail;
END CATCH;
"""
    rows = list(read_tsv(client.query(sql)))
    if not rows:
        return False, "No response from SQL Server"
    return rows[0][0] == "ENABLED", rows[0][1] if len(rows[0]) > 1 else ""



def disable_table_cdc(client: SqlCmdClient, schema_name: str, table_name: str) -> tuple[bool, str]:
    """Attempt to disable CDC for one source table.

    Args:
        client: SQL Server client used to execute the CDC disable command.
        schema_name: Source schema name.
        table_name: Source table name.

    Returns:
        tuple[bool, str]: Whether the table was disabled and any detail returned
        by SQL Server.
    """

    sql = f"""
SET NOCOUNT ON;
BEGIN TRY
    EXEC sys.sp_cdc_disable_table
        @source_schema = N'{sql_quote(schema_name)}',
        @source_name = N'{sql_quote(table_name)}',
        @capture_instance = N'{sql_quote(schema_name)}_{sql_quote(table_name)}';
    SELECT 'DISABLED' AS status, '' AS detail;
END TRY
BEGIN CATCH
    SELECT 'SKIPPED' AS status, ERROR_MESSAGE() AS detail;
END CATCH;
"""
    rows = list(read_tsv(client.query(sql)))
    if not rows:
        return False, "No response from SQL Server"
    return rows[0][0] == "DISABLED", rows[0][1] if len(rows[0]) > 1 else ""



def disable_managed_tables(client: SqlCmdClient, managed_tables: list[dict[str, str]]) -> list[dict[str, str]]:
    """Disable all tracer-managed tables and keep only failed cleanup entries.

    Args:
        client: SQL Server client used to disable CDC.
        managed_tables: Table entries previously recorded as tracer-managed.

    Returns:
        list[dict[str, str]]: Remaining table entries that still need cleanup.
    """

    remaining_tables: list[dict[str, str]] = []
    for entry in managed_tables:
        disabled, detail = disable_table_cdc(client, entry["schema_name"], entry["table_name"])
        if disabled:
            print(f"Disabled CDC: {entry['schema_name']}.{entry['table_name']}")
            continue

        message = detail.strip()
        lowered = message.lower()
        if "is not enabled for change data capture" in lowered or "does not have change data capture enabled" in lowered:
            print(f"Already disabled: {entry['schema_name']}.{entry['table_name']}")
            continue

        remaining_tables.append(
            {
                "schema_name": entry["schema_name"],
                "table_name": entry["table_name"],
                "detail": message,
            }
        )
        print(f"Cleanup failed: {entry['schema_name']}.{entry['table_name']} | {message}")
    return remaining_tables



def fetch_changes_for_capture(
    client: SqlCmdClient,
    capture: CaptureInstance,
    start_lsn: str,
    end_lsn: str,
) -> list[dict[str, object]]:
    """Fetch CDC rows for one capture instance within an LSN window.

    Args:
        client: SQL Server client used to query CDC rows.
        capture: Capture instance metadata for the source table.
        start_lsn: Exclusive lower bound of the capture window.
        end_lsn: Inclusive upper bound of the capture window.

    Returns:
        list[dict[str, object]]: Parsed CDC records for the requested capture
        instance.
    """

    sql = f"""
SET NOCOUNT ON;
SELECT
    '{sql_quote(capture.schema_name)}' AS schema_name,
    '{sql_quote(capture.table_name)}' AS table_name,
    '{sql_quote(capture.capture_instance)}' AS capture_instance,
    CASE ct.__$operation
        WHEN 1 THEN 'delete'
        WHEN 2 THEN 'insert'
        WHEN 3 THEN 'update_before'
        WHEN 4 THEN 'update_after'
        ELSE 'unknown'
    END AS operation,
    CAST(ct.__$operation AS varchar(20)) AS operation_code,
    master.dbo.fn_varbintohexstr(ct.__$start_lsn) AS start_lsn,
    master.dbo.fn_varbintohexstr(ct.__$seqval) AS seqval,
    CONVERT(varchar(33), ltm.tran_begin_time, 127) AS tran_begin_time,
    CONVERT(varchar(33), ltm.tran_end_time, 127) AS tran_end_time,
    CAST(ct.__$command_id AS varchar(20)) AS command_id,
    (SELECT ct.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS row_json
FROM cdc.{capture.capture_instance}_CT ct
LEFT JOIN cdc.lsn_time_mapping ltm ON ltm.start_lsn = ct.__$start_lsn
WHERE ct.__$start_lsn > {start_lsn}
  AND ct.__$start_lsn <= {end_lsn}
ORDER BY ct.__$start_lsn, ct.__$seqval, ct.__$operation;
"""

    records = []
    for row in read_tsv(client.query(sql), expected_columns=11):
        payload = row[10] if len(row) > 10 else "{}"
        payload_obj: dict[str, object]
        payload_error: str | None = None
        try:
            payload_obj = json.loads(payload) if payload else {}
        except json.JSONDecodeError as error:
            payload_obj = {"_raw_json": payload}
            payload_error = str(error)

        records.append(
            {
                "schema_name": row[0],
                "table_name": row[1],
                "capture_instance": row[2],
                "operation": row[3],
                "operation_code": int(row[4]),
                "start_lsn": row[5],
                "seqval": row[6],
                "tran_begin_time": row[7],
                "tran_end_time": row[8],
                "command_id": int(row[9]) if row[9] else None,
                "row": payload_obj,
                "row_parse_error": payload_error,
            }
        )
    return records



def fetch_changes_for_captures(
    client: SqlCmdClient,
    captures: list[CaptureInstance],
    start_lsn: str,
    end_lsn: str,
) -> list[dict[str, object]]:
    """Fetch CDC rows for many capture instances with one batched query.

    Args:
        client: SQL Server client used to query CDC rows.
        captures: Capture instances to inspect.
        start_lsn: Exclusive lower bound of the capture window.
        end_lsn: Inclusive upper bound of the capture window.

    Returns:
        list[dict[str, object]]: Parsed CDC records across all requested
        capture instances.
    """

    if not captures:
        return []

    log_progress(f"Preparing batched CDC fetch across {len(captures)} capture instances")

    statement_parts: list[str] = [
        "SET NOCOUNT ON;",
        "CREATE TABLE #changed_captures (",
        "    schema_name sysname NOT NULL,",
        "    table_name sysname NOT NULL,",
        "    capture_instance sysname NOT NULL PRIMARY KEY",
        ");",
        "CREATE TABLE #cdc_changes (",
        "    schema_name sysname NOT NULL,",
        "    table_name sysname NOT NULL,",
        "    capture_instance sysname NOT NULL,",
        "    operation nvarchar(20) NOT NULL,",
        "    operation_code int NOT NULL,",
        "    start_lsn varbinary(10) NOT NULL,",
        "    seqval varbinary(10) NOT NULL,",
        "    tran_begin_time datetime NULL,",
        "    tran_end_time datetime NULL,",
        "    command_id int NULL,",
        "    row_json nvarchar(max) NULL",
        ");",
    ]

    for capture in captures:
        capture_table_name = f"cdc.{quote_identifier(capture.capture_instance + '_CT')}"
        statement_parts.extend(
            [
                "IF EXISTS (",
                f"    SELECT TOP (1) 1 FROM {capture_table_name} ct",
                f"    WHERE ct.__$start_lsn > {start_lsn}",
                f"      AND ct.__$start_lsn <= {end_lsn}",
                ")",
                "BEGIN",
                "    INSERT INTO #changed_captures (schema_name, table_name, capture_instance)",
                "    VALUES (",
                f"        N'{sql_quote(capture.schema_name)}',",
                f"        N'{sql_quote(capture.table_name)}',",
                f"        N'{sql_quote(capture.capture_instance)}'",
                "    );",
                "END;",
            ]
        )

    for capture in captures:
        capture_table_name = f"cdc.{quote_identifier(capture.capture_instance + '_CT')}"
        statement_parts.extend(
            [
                f"IF EXISTS (SELECT 1 FROM #changed_captures WHERE capture_instance = N'{sql_quote(capture.capture_instance)}')",
                "BEGIN",
                "INSERT INTO #cdc_changes (",
                "    schema_name,",
                "    table_name,",
                "    capture_instance,",
                "    operation,",
                "    operation_code,",
                "    start_lsn,",
                "    seqval,",
                "    tran_begin_time,",
                "    tran_end_time,",
                "    command_id,",
                "    row_json",
                ")",
                "SELECT",
                "    cc.schema_name,",
                "    cc.table_name,",
                "    cc.capture_instance,",
                "    CASE ct.__$operation",
                "        WHEN 1 THEN 'delete'",
                "        WHEN 2 THEN 'insert'",
                "        WHEN 3 THEN 'update_before'",
                "        WHEN 4 THEN 'update_after'",
                "        ELSE 'unknown'",
                "    END AS operation,",
                "    CAST(ct.__$operation AS int) AS operation_code,",
                "    ct.__$start_lsn AS start_lsn,",
                "    ct.__$seqval AS seqval,",
                "    ltm.tran_begin_time,",
                "    ltm.tran_end_time,",
                "    ct.__$command_id AS command_id,",
                "    (SELECT ct.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS row_json",
                f"FROM {capture_table_name} ct",
                f"JOIN #changed_captures cc ON cc.capture_instance = N'{sql_quote(capture.capture_instance)}'",
                "LEFT JOIN cdc.lsn_time_mapping ltm ON ltm.start_lsn = ct.__$start_lsn",
                f"WHERE ct.__$start_lsn > {start_lsn}",
                f"  AND ct.__$start_lsn <= {end_lsn};",
                "END;",
            ]
        )

    statement_parts.extend(
        [
            "SELECT",
            "    schema_name,",
            "    table_name,",
            "    capture_instance,",
            "    operation,",
            "    CAST(operation_code AS varchar(20)) AS operation_code,",
            "    master.dbo.fn_varbintohexstr(start_lsn) AS start_lsn,",
            "    master.dbo.fn_varbintohexstr(seqval) AS seqval,",
            "    CONVERT(varchar(33), tran_begin_time, 127) AS tran_begin_time,",
            "    CONVERT(varchar(33), tran_end_time, 127) AS tran_end_time,",
            "    CAST(command_id AS varchar(20)) AS command_id,",
            "    ISNULL(row_json, '{}') AS row_json",
            "FROM #cdc_changes",
            "ORDER BY start_lsn, seqval, operation_code;",
        ]
    )

    log_progress("Executing batched CDC query")
    query_started = perf_counter()
    raw_output = client.query("\n".join(statement_parts))
    log_progress(f"Completed batched CDC query in {perf_counter() - query_started:.1f}s")

    log_progress("Parsing CDC query results")
    parse_started = perf_counter()
    records = []
    for row in read_tsv(raw_output, expected_columns=11):
        payload = row[10] if len(row) > 10 else "{}"
        payload_obj: dict[str, object]
        payload_error: str | None = None
        try:
            payload_obj = json.loads(payload) if payload else {}
        except json.JSONDecodeError as error:
            payload_obj = {"_raw_json": payload}
            payload_error = str(error)

        records.append(
            {
                "schema_name": row[0],
                "table_name": row[1],
                "capture_instance": row[2],
                "operation": row[3],
                "operation_code": int(row[4]),
                "start_lsn": row[5],
                "seqval": row[6],
                "tran_begin_time": row[7],
                "tran_end_time": row[8],
                "command_id": int(row[9]) if row[9] else None,
                "row": payload_obj,
                "row_parse_error": payload_error,
            }
        )
    log_progress(f"Parsed {len(records)} CDC rows in {perf_counter() - parse_started:.1f}s")
    return records
