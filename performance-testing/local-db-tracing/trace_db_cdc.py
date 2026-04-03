from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from time import perf_counter, sleep
from typing import Iterable


@dataclass(frozen=True)
class TableStatus:
    """Carry the current CDC state for one user table so enable/disable decisions stay explicit."""

    schema_name: str
    table_name: str
    is_tracked_by_cdc: bool


@dataclass(frozen=True)
class CaptureInstance:
    """Keep the source table and CDC capture-instance name paired during change collection."""

    schema_name: str
    table_name: str
    capture_instance: str


@dataclass(frozen=True)
class PrimaryKeyColumn:
    """Preserve PK column order so replay can rebuild keys in the same shape SQL Server expects."""

    schema_name: str
    table_name: str
    column_name: str
    key_ordinal: int


@dataclass(frozen=True)
class UidGeneratorEntry:
    """Mirror Local_UID_generator rows so replay can reuse ODSE-style ID allocation semantics."""

    class_name_cd: str
    type_cd: str
    uid_prefix_cd: str
    uid_suffix_cd: str


@dataclass(frozen=True)
class ManagedCdcState:
    """Persist exactly which CDC state the tracer owns so later cleanup does not overreach."""

    tables: list[dict[str, str]]
    database_cdc_enabled_by_tracer: bool


class SqlCmdError(RuntimeError):
    """Differentiate sqlcmd failures from normal control-flow exits."""

    pass


CDC_METADATA_COLUMNS = {
    "__$start_lsn",
    "__$seqval",
    "__$operation",
    "__$update_mask",
    "__$command_id",
}

LOCAL_TRACING_DIR = Path("performance-testing") / "local-db-tracing"
LOCAL_RUNTIME_DIR = LOCAL_TRACING_DIR / ".local"
DEFAULT_STATE_FILE_DIR = LOCAL_RUNTIME_DIR
LEGACY_STATE_FILE = LOCAL_TRACING_DIR / "enabled-cdc-tables.json"
REPLAY_METADATA_CACHE_PREFIX = "replay-metadata-"
REPLAY_METADATA_CACHE_VERSION = 3
EXCLUDED_TRACE_TABLES = {
    ("dbo", "job_flow_log"),
}
DEFAULT_POST_PROCESSING_CONTAINER_PREFIX = "nedss-datareporting-post-processing-service"
DEFAULT_POST_PROCESSING_IDLE_MESSAGE = "No ids to process from the topics."
DEFAULT_POST_PROCESSING_WAIT_TIMEOUT_SECONDS = 3
DEFAULT_POST_PROCESSING_INITIAL_WAIT_SECONDS = 5

class SqlCmdClient:
    """Centralize sqlcmd execution so every metadata and CDC query uses the same calling convention."""

    def __init__(self, executable: str, server: str, database: str, user: str, password: str):
        """Capture connection settings once so helper functions stay focused on the SQL they need."""

        self.executable = executable
        self.server = server
        self.database = database
        self.user = user
        self.password = password

    def query(self, sql: str, database: str | None = None) -> str:
        """Run sqlcmd through a temp script file so larger queries and quoting stay predictable on Windows."""

        target_db = database or self.database
        with tempfile.NamedTemporaryFile("w", suffix=".sql", delete=False, encoding="utf-8") as handle:
            handle.write(sql)
            script_path = Path(handle.name)

        command = [
            self.executable,
            "-S",
            self.server,
            "-d",
            target_db,
            "-U",
            self.user,
            "-P",
            self.password,
            "-b",
            "-w",
            "65535",
            "-s",
            "\t",
            "-y",
            "0",
            "-Y",
            "0",
            "-i",
            str(script_path),
        ]

        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                check=False,
            )
        finally:
            script_path.unlink(missing_ok=True)

        if result.returncode != 0:
            stderr = (result.stderr or "").strip()
            stdout = (result.stdout or "").strip()
            message = stderr or stdout or f"sqlcmd failed with exit code {result.returncode}"
            raise SqlCmdError(message)

        return result.stdout


def parse_args() -> argparse.Namespace:
    """Keep the CLI contract in one place so tracing and cleanup modes evolve together."""

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
        default=str(Path("performance-testing") / "local-db-tracing" / "output"),
        help="Directory where run output folders are created",
    )
    parser.add_argument(
        "--state-file",
        help="JSON file used to track tracer-managed CDC tables left enabled across runs; defaults to enabled-cdc-tables-<database>.json",
    )
    parser.add_argument(
        "--cleanup",
        choices=("ask", "yes", "no"),
        default="ask",
        help="Whether to disable tracer-managed CDC tables after the run: ask, yes, or no",
    )
    parser.add_argument(
        "--keep-enabled",
        action="store_true",
        help="Legacy alias for --cleanup no",
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


def sql_quote(value: str) -> str:
    """Escape literal strings because most metadata queries are assembled dynamically."""

    return value.replace("'", "''")


def require_sqlcmd(executable: str) -> str:
    """Fail early when sqlcmd is missing so the user does not get partial tracing state."""

    resolved = shutil.which(executable)
    if not resolved:
        raise SystemExit(f"sqlcmd executable not found: {executable}")
    return resolved


def utc_now() -> str:
    """Use UTC timestamps everywhere so manifests and summaries are comparable across environments."""

    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def progress_now() -> str:
    """Render local timestamps for user-facing progress messages during long-running trace phases."""

    return datetime.now().astimezone().replace(microsecond=0).isoformat()


def log_progress(action: str) -> None:
    """Emit timestamped progress so long CDC phases can be correlated with the current bottleneck."""

    print(f"[{progress_now()}] {action}")


def run_process(command: list[str]) -> subprocess.CompletedProcess[str]:
    """Run a local process with consistent text handling for docker and sqlcmd helper commands."""

    return subprocess.run(
        command,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )


def find_container_name_by_prefix(docker_executable: str, prefix: str) -> tuple[str | None, str]:
    """Resolve the post-processing container dynamically because Compose appends numeric suffixes."""

    result = run_process([docker_executable, "ps", "--format", "{{.Names}}"])
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "docker ps failed").strip()
        return None, detail

    names = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    matches = sorted(name for name in names if name.startswith(prefix))
    if not matches:
        return None, f"No running container name starts with {prefix}"
    if len(matches) > 1:
        return matches[0], f"Multiple containers matched; using {matches[0]}"
    return matches[0], ""


def fetch_container_logs_since(docker_executable: str, container_name: str, since_utc: str) -> tuple[bool, str]:
    """Read recent container logs from the action window without tailing indefinitely."""

    result = run_process([docker_executable, "logs", "--since", since_utc, container_name])
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "docker logs failed").strip()
        return False, detail
    return True, "\n".join(part for part in (result.stdout, result.stderr) if part)


def extract_meaningful_log_lines(output: str) -> list[str]:
    """Normalize docker log output into comparable lines for tail-based idle detection."""

    return [line.strip() for line in output.splitlines() if line.strip()]


def has_post_processing_idle_tail(lines: list[str], idle_message: str) -> bool:
    """Proceed only when the latest two meaningful log lines are non-idle followed by idle."""

    if len(lines) < 2:
        return False

    previous_line = lines[-2]
    last_line = lines[-1]
    return not previous_line.endswith(idle_message) and last_line.endswith(idle_message)


def wait_for_post_processing_idle(
    container_prefix: str,
    idle_message: str,
    since_utc: str,
    timeout_seconds: int,
    initial_wait_seconds: int,
) -> None:
    """Pause capture until the post-processing container reports its queue is drained."""

    docker_executable = shutil.which("docker")
    if not docker_executable:
        print("docker executable not found; skipping post-processing log wait")
        return

    container_name, detail = find_container_name_by_prefix(docker_executable, container_prefix)
    if container_name is None:
        print(f"Skipping post-processing log wait: {detail}")
        return

    if detail:
        print(detail)

    log_progress(
        f"Waiting up to {timeout_seconds}s for {container_name} to log: {idle_message}"
    )
    if initial_wait_seconds > 0:
        log_progress(f"Sleeping {initial_wait_seconds}s before polling logs")
        sleep(initial_wait_seconds)

    deadline = perf_counter() + max(timeout_seconds, 0)
    while perf_counter() <= deadline:
        success, output = fetch_container_logs_since(docker_executable, container_name, since_utc)
        if not success:
            print(f"Skipping post-processing log wait: {output}")
            return
        lines = extract_meaningful_log_lines(output)
        if has_post_processing_idle_tail(lines, idle_message):
            log_progress(f"Observed idle message in {container_name}")
            return
        sleep(2)

    print(
        f"Timed out after {timeout_seconds}s waiting for {container_name} to log the idle message; continuing capture"
    )


def database_name_slug(database: str) -> str:
    """Turn database names into safe filenames so per-database state does not depend on shell escaping."""

    cleaned = []
    for character in database:
        if character.isalnum() or character in {"-", "_", "."}:
            cleaned.append(character)
        else:
            cleaned.append("_")
    slug = "".join(cleaned).strip("._-")
    return slug or "database"


def default_state_file_for_database(database: str) -> Path:
    """Separate cleanup state per database so traces for different schemas cannot clobber each other."""

    return DEFAULT_STATE_FILE_DIR / f"enabled-cdc-tables-{database_name_slug(database)}.json"


def replay_metadata_cache_file_for_database(database: str) -> Path:
    """Cache replay metadata per database because PK/FK discovery is expensive but mostly stable."""

    return DEFAULT_STATE_FILE_DIR / f"{REPLAY_METADATA_CACHE_PREFIX}{database_name_slug(database)}.json"


def resolve_state_files(args: argparse.Namespace) -> tuple[Path, Path | None]:
    """Support explicit state files while still honoring the legacy shared file during migration."""

    if args.state_file:
        return Path(args.state_file), None
    return default_state_file_for_database(args.database), LEGACY_STATE_FILE


def serialize_table_key(schema_name: str, table_name: str) -> str:
    """Normalize table identifiers before they are written into human-readable artifacts."""

    return f"{schema_name}.{table_name}"


def is_excluded_trace_table(schema_name: str, table_name: str) -> bool:
    """Keep known high-noise internal tables out of CDC enablement and capture output."""

    return (schema_name.lower(), table_name.lower()) in EXCLUDED_TRACE_TABLES


def value_key(value: object) -> str:
    """Create stable dictionary keys for replay values so `1`, `"1"`, and `NULL` stay distinct."""

    # Serialize values consistently so replay lookups do not depend on Python's object formatting.
    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(",", ":"))


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
    if args.keep_enabled:
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


def disable_managed_tables(
    client: SqlCmdClient,
    managed_tables: list[dict[str, str]],
) -> list[dict[str, str]]:
    """Attempt best-effort CDC cleanup while preserving any failures for a later retry."""

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


def fetch_database_cdc_enabled(client: SqlCmdClient, database: str) -> bool:
    """Guard the whole workflow because table-level CDC operations are meaningless without database-level CDC."""

    sql = f"""
SET NOCOUNT ON;
SELECT CASE WHEN is_cdc_enabled = 1 THEN '1' ELSE '0' END
FROM sys.databases
WHERE name = '{sql_quote(database)}';
"""
    return client.query(sql, database="master").strip() == "1"


def enable_database_cdc(client: SqlCmdClient, database: str) -> tuple[bool, str]:
    """Enable database-level CDC in the target database so the tracer can bootstrap itself."""

    sql = """
SET NOCOUNT ON;
BEGIN TRY
    EXEC sys.sp_cdc_enable_db;
    SELECT 'ENABLED' AS status, '' AS detail;
END TRY
BEGIN CATCH
    SELECT 'SKIPPED' AS status, ERROR_MESSAGE() AS detail;
END CATCH;
"""
    rows = list(read_tsv(client.query(sql, database=database)))
    if not rows:
        return False, "No response from SQL Server"
    return rows[0][0] == "ENABLED", rows[0][1] if len(rows[0]) > 1 else ""


def disable_database_cdc(client: SqlCmdClient, database: str) -> tuple[bool, str]:
    """Disable database-level CDC only when this tracer previously enabled it and cleanup is requested."""

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
    """Snapshot table tracking status once so enablement decisions are based on a consistent baseline."""

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
    rows = []
    for row in read_tsv(client.query(sql)):
        rows.append(TableStatus(row[0], row[1], row[2] == "1"))
    return rows


def fetch_capture_instances(client: SqlCmdClient) -> list[CaptureInstance]:
    """Use SQL Server's registered capture instances so change reads follow the database's own CDC mapping."""

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
    captures = []
    for row in read_tsv(client.query(sql)):
        if is_excluded_trace_table(row[0], row[1]):
            continue
        captures.append(CaptureInstance(row[0], row[1], row[2]))
    return captures


def fetch_primary_key_columns(client: SqlCmdClient) -> dict[tuple[str, str], list[str]]:
    """Collect ordered PK metadata because replay logic needs table identity, not just raw row payloads."""

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
    """Distinguish server-generated keys from caller-supplied keys before reconstructing replay SQL."""

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
    """Capture FK relationships so replay can substitute generated parent keys into dependent rows."""

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
    """Retain SQL types so generated variables match the database columns they stand in for."""

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
    """Detect columns SQL Server manages automatically so replay SQL does not try to assign them."""

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
    """Read Local_UID_generator when present; some traced databases like RDB_MODERN do not have it."""

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
    """Persist replay metadata so repeated trace runs do not keep rediscovering the same schema facts."""

    payload = {
        "cache_version": REPLAY_METADATA_CACHE_VERSION,
        "database": database,
        "saved_at_utc": utc_now(),
        "primary_keys": [
            {
                "schema_name": schema_name,
                "table_name": table_name,
                "columns": columns,
            }
            for (schema_name, table_name), columns in sorted(primary_keys_by_table.items())
        ],
        "identity_columns": [
            {
                "schema_name": schema_name,
                "table_name": table_name,
                "columns": columns,
            }
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
            {
                "schema_name": schema_name,
                "table_name": table_name,
                "column_name": column_name,
            }
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
    """Reject stale or mismatched replay caches so generated SQL never depends on wrong schema metadata."""

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

    payload_database = payload.get("database")
    if payload_database != database:
        return None

    if "uid_generators" not in payload or "generated_always_columns" not in payload:
        return None

    primary_keys_by_table: dict[tuple[str, str], list[str]] = {}
    for item in payload.get("primary_keys", []):
        primary_keys_by_table[(item["schema_name"], item["table_name"])] = list(item["columns"])

    identity_columns_by_table: dict[tuple[str, str], list[str]] = {}
    for item in payload.get("identity_columns", []):
        identity_columns_by_table[(item["schema_name"], item["table_name"])] = list(item["columns"])

    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]] = {}
    for item in payload.get("foreign_keys", []):
        foreign_keys_by_source[(item["source_schema"], item["source_table"], item["source_column"])] = (
            item["target_schema"],
            item["target_table"],
            item["target_column"],
        )

    column_sql_types: dict[tuple[str, str, str], str] = {}
    for item in payload.get("column_sql_types", []):
        column_sql_types[(item["schema_name"], item["table_name"], item["column_name"])] = item["sql_type"]

    generated_always_columns: set[tuple[str, str, str]] = set()
    for item in payload.get("generated_always_columns", []):
        generated_always_columns.add((item["schema_name"], item["table_name"], item["column_name"]))

    uid_generator_entries: list[UidGeneratorEntry] = []
    for item in payload.get("uid_generators", []):
        uid_generator_entries.append(
            UidGeneratorEntry(
                class_name_cd=item["class_name_cd"],
                type_cd=item["type_cd"],
                uid_prefix_cd=item["uid_prefix_cd"],
                uid_suffix_cd=item["uid_suffix_cd"],
            )
        )

    return primary_keys_by_table, identity_columns_by_table, foreign_keys_by_source, column_sql_types, generated_always_columns, uid_generator_entries


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
    """Hide cache-vs-query decisions from the rest of the tracer so replay always gets a complete metadata bundle."""

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
    return primary_keys_by_table, identity_columns_by_table, foreign_keys_by_source, column_sql_types, generated_always_columns, uid_generator_entries


def fetch_max_lsn(client: SqlCmdClient) -> str:
    """Anchor the capture window with SQL Server's current max LSN so the trace is bounded and reproducible."""

    sql = """
SET NOCOUNT ON;
SELECT master.dbo.fn_varbintohexstr(sys.fn_cdc_get_max_lsn());
"""
    value = client.query(sql).strip()
    if not value:
        raise SqlCmdError("Could not determine current CDC max LSN")
    return value


def enable_table_cdc(client: SqlCmdClient, schema_name: str, table_name: str) -> tuple[bool, str]:
    """Wrap CDC enablement in TRY/CATCH so one table failure does not abort the whole tracing session."""

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
    """Mirror enablement behavior during cleanup so disable-only mode reports actionable failures."""

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


def read_tsv(raw_output: str, expected_columns: int | None = None) -> Iterable[list[str]]:
    """Strip sqlcmd noise while keeping tab-delimited payloads intact for metadata and CDC parsing."""

    cleaned: list[str] = []
    for line in raw_output.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.endswith("rows affected)") or stripped.endswith("row affected)"):
            continue
        if set(stripped) <= {"-", "\t", " "}:
            continue
        cleaned.append(line.rstrip("\r"))

    for line in cleaned:
        if expected_columns and expected_columns > 1:
            yield [part.strip() for part in line.split("\t", expected_columns - 1)]
        else:
            yield [part.strip() for part in line.split("\t")]


def fetch_changes_for_capture(
    client: SqlCmdClient,
    capture: CaptureInstance,
    start_lsn: str,
    end_lsn: str,
) -> list[dict[str, object]]:
    """Read one CDC capture stream into a normalized record shape the rest of the tracer can reason about."""

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
    """Fetch only changed capture-instance rows in one sqlcmd invocation so latency scales with touched tables, not enabled tables."""

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


def summarize_row_identifier(record: dict[str, object]) -> str:
    """Pick stable, human-meaningful identifiers so summaries are useful without opening raw JSON payloads."""

    row = record.get("row")
    if not isinstance(row, dict):
        return f"{record['operation']} seqval={record['seqval']}"

    preferred_suffixes = ("_uid", "_key", "_seq")
    excluded_columns = CDC_METADATA_COLUMNS | {
        "add_user_id",
        "last_chg_user_id",
        "version_ctrl_nbr",
    }

    identifier_parts: list[str] = []

    for column_name in row:
        if column_name in excluded_columns:
            continue
        if column_name == "local_id":
            identifier_parts.append(f"{column_name}={row[column_name]}")

    for suffix in preferred_suffixes:
        for column_name in row:
            if column_name in excluded_columns:
                continue
            if column_name.endswith(suffix):
                part = f"{column_name}={row[column_name]}"
                if part not in identifier_parts:
                    identifier_parts.append(part)

    if not identifier_parts:
        for column_name in row:
            if column_name in excluded_columns:
                continue
            if column_name.endswith("_id"):
                identifier_parts.append(f"{column_name}={row[column_name]}")

    if not identifier_parts:
        identifier_parts.append(f"seqval={record['seqval']}")

    parse_error = record.get("row_parse_error")
    if parse_error:
        return f"{record['operation']} {'; '.join(identifier_parts[:3])} [payload parse error]"

    return f"{record['operation']} {'; '.join(identifier_parts[:3])}"


def summarize_record_identity(record: dict[str, object]) -> str:
    """Reuse the summary identity without the operation prefix when composing higher-level messages."""

    summary = summarize_row_identifier(record)
    parts = summary.split(" ", 1)
    return parts[1] if len(parts) == 2 else summary


def update_pair_key(record: dict[str, object]) -> tuple[str, str, int | None]:
    """Pair CDC before/after images using the tuple SQL Server keeps stable within one logical update."""

    return (str(record["start_lsn"]), str(record["seqval"]), record.get("command_id"))


def change_sort_key(record: dict[str, object]) -> tuple[str, str, int, int]:
    """Keep replay order aligned with CDC order so reconstructed SQL follows the original transaction sequence."""

    command_id = record.get("command_id")
    return (
        str(record["start_lsn"]),
        str(record["seqval"]),
        -1 if command_id is None else int(command_id),
        int(record["operation_code"]),
    )


def format_value(value: object) -> str:
    """Render values consistently in summaries so diffs are easy to scan."""

    return json.dumps(value, ensure_ascii=True)


def quote_identifier(identifier: str) -> str:
    """Bracket identifiers because replay SQL is assembled dynamically and must survive reserved words."""

    return f"[{identifier.replace(']', ']]')}]"


def sql_literal(value: object) -> str:
    """Translate JSON-like payload values back into SQL literals for the reconstructed replay section."""

    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, (int, float)):
        return str(value)
    return f"N'{sql_quote(str(value))}'"


def is_numeric_sql_type(sql_type: str) -> bool:
    """Limit synthetic key generation to numeric columns because the fallback strategy depends on ordering."""

    lowered = sql_type.lower()
    return lowered.startswith(("tinyint", "smallint", "int", "bigint", "decimal", "numeric"))


def sanitize_sql_name(name: str) -> str:
    """Make generated variable names safe without hiding their relationship to the source table and value."""

    cleaned = []
    for character in name:
        if character.isalnum() or character == "_":
            cleaned.append(character)
        else:
            cleaned.append("_")
    sanitized = "".join(cleaned).strip("_")
    return sanitized or "value"


def variable_name_for_value(schema_name: str, table_name: str, column_name: str, value: object) -> str:
    # Keep the captured source value in the variable name so generated IDs remain easy to trace in the summary output.
    return "@" + sanitize_sql_name(f"{schema_name}_{table_name}_{column_name}_{value}")


def output_table_name_for_variable(variable_name: str) -> str:
    """Keep OUTPUT capture tables derived from the main variable so related temp objects stay recognizable."""

    return "@" + sanitize_sql_name(variable_name.lstrip("@") + "_output")


def register_nrt_patient_mpr_uid_reference(
    table_key: tuple[str, str],
    row: dict[str, object],
    variable_registry: dict[tuple[str, str, str, str], str],
    column_sql_types: dict[tuple[str, str, str], str],
    prelude_lines: list[str],
) -> None:
    """Treat nrt_patient.patient_mpr_uid as replay-generated from the new patient_uid so downstream rows reuse it."""

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

    variable_name = variable_name_for_value(table_key[0], table_key[1], "patient_mpr_uid", row["patient_mpr_uid"])
    sql_type = column_sql_types.get((table_key[0], table_key[1], "patient_mpr_uid"), "bigint")
    prelude_lines.append(f"DECLARE {variable_name} {sql_type} = {patient_uid_reference} + 1;")
    variable_registry[patient_mpr_uid_key] = variable_name


def infer_uid_class_from_local_id(local_id: object, uid_generator_entries: list[UidGeneratorEntry]) -> str | None:
    """Infer allocator class from ODSE-style local IDs when the table name alone is not enough."""

    if not isinstance(local_id, str):
        return None
    for entry in uid_generator_entries:
        if local_id.startswith(entry.uid_prefix_cd) and local_id.endswith(entry.uid_suffix_cd):
            middle = local_id[len(entry.uid_prefix_cd) : len(local_id) - len(entry.uid_suffix_cd) if entry.uid_suffix_cd else None]
            if middle.isdigit():
                return entry.class_name_cd
    return None


def infer_uid_class_registry(
    changes: list[dict[str, object]],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    uid_generator_entries: list[UidGeneratorEntry],
) -> dict[tuple[str, str, str, str], str]:
    """Precompute allocator classes once so replay generation does not have to rediscover them row by row."""

    # Map captured PK values to Local_UID_generator classes so replay can call the same allocator the source DB used.
    class_registry: dict[tuple[str, str, str, str], str] = {}
    for record in sorted(changes, key=change_sort_key):
        if record.get("operation") != "insert":
            continue
        row = record.get("row")
        if not isinstance(row, dict):
            continue
        table_key = (str(record["schema_name"]), str(record["table_name"]))
        primary_key_columns = primary_keys_by_table.get(table_key, [])
        if len(primary_key_columns) != 1:
            continue
        primary_key_column = primary_key_columns[0]
        if primary_key_column not in row:
            continue

        class_name = infer_uid_class_from_local_id(row.get("local_id"), uid_generator_entries)
        if not class_name:
            normalized_table_name = table_key[1].upper()
            for entry in uid_generator_entries:
                if entry.class_name_cd.upper() == normalized_table_name:
                    class_name = entry.class_name_cd
                    break
        if not class_name:
            continue

        key = (table_key[0], table_key[1], primary_key_column, value_key(row[primary_key_column]))
        class_registry[key] = class_name

        foreign_key_target = foreign_keys_by_source.get((table_key[0], table_key[1], primary_key_column))
        if foreign_key_target is not None:
            class_registry[(foreign_key_target[0], foreign_key_target[1], foreign_key_target[2], value_key(row[primary_key_column]))] = class_name

    return class_registry


def data_columns(row: dict[str, object]) -> list[str]:
    """Drop CDC metadata columns so replay works from business data rather than transport details."""

    return [column_name for column_name in row if column_name not in CDC_METADATA_COLUMNS]


def is_user_id_column(column_name: str) -> bool:
    """Treat audit-style user identifiers as environment-specific values during replay generation."""

    return column_name.lower().endswith("user_id")


def is_version_column(column_name: str) -> bool:
    """Recognize row-version columns that need replay-time allocation rather than captured literals."""

    return column_name.lower() == "version_ctrl_nbr"


def is_history_table(table_key: tuple[str, str]) -> bool:
    """Identify history tables whose composite keys include a replay-sensitive version number."""

    return table_key[1].lower().endswith("_hist")


def generated_primary_key_column(
    table_key: tuple[str, str],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    identity_columns_by_table: dict[tuple[str, str], list[str]],
) -> str | None:
    """Only treat a PK as server-generated when the schema says SQL Server owns that value."""

    primary_key_columns = primary_keys_by_table.get(table_key, [])
    if len(primary_key_columns) != 1:
        return None
    primary_key_column = primary_key_columns[0]
    if primary_key_column not in identity_columns_by_table.get(table_key, []):
        return None
    return primary_key_column


def resolve_suffix_variable_reference(
    column_name: str,
    value: object,
    variable_registry: dict[tuple[str, str, str, str], str],
) -> str | None:
    """Recover shared generated keys in subtype tables when the schema does not expose a direct FK path."""

    # Some tables share a generated key value through subtype/supertype naming that is not represented as a direct FK.
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
    column_name: str,
    value: object,
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
) -> str | None:
    """Prefer a replay variable over a literal whenever the captured value represents a generated key."""

    direct_key = (table_key[0], table_key[1], column_name, value_key(value))
    if direct_key in variable_registry:
        return variable_registry[direct_key]

    # Prefer the schema FK when it exists, then fall back to the looser suffix match for subtype tables.
    foreign_key_target = foreign_keys_by_source.get((table_key[0], table_key[1], column_name))
    if foreign_key_target is None:
        return resolve_suffix_variable_reference(column_name, value, variable_registry)

    target_reference = variable_registry.get((foreign_key_target[0], foreign_key_target[1], foreign_key_target[2], value_key(value)))
    if target_reference:
        return target_reference

    return resolve_suffix_variable_reference(column_name, value, variable_registry)


def sql_value_expression(
    table_key: tuple[str, str],
    column_name: str,
    value: object,
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
) -> str:
    """Centralize value rendering so replay stays consistent about literals versus generated-key variables."""

    variable_reference = resolve_variable_reference(table_key, column_name, value, variable_registry, foreign_keys_by_source)
    if variable_reference:
        return variable_reference
    return sql_literal(value)


def sql_replay_assignment_expression(
    table_key: tuple[str, str],
    column_name: str,
    value: object,
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
) -> str:
    """Normalize environment-specific audit users while preserving existing replay key substitution logic."""

    if is_user_id_column(column_name):
        return "9999"
    return sql_value_expression(table_key, column_name, value, variable_registry, foreign_keys_by_source)


def build_version_lookup_predicates(
    table_key: tuple[str, str],
    row: dict[str, object],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
) -> str:
    """Match existing versioned rows on the stable key columns so replay can pick the next version number."""

    key_columns = [column_name for column_name in primary_keys_by_table.get(table_key, []) if not is_version_column(column_name)]
    if not key_columns:
        key_columns = [column_name for column_name in data_columns(row) if not is_version_column(column_name)]
    return build_where_clause(table_key, row, key_columns, variable_registry, foreign_keys_by_source)


def sql_insert_assignment_expression(
    table_key: tuple[str, str],
    row: dict[str, object],
    column_name: str,
    value: object,
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
) -> str:
    """Allocate replay-safe insert values for environment-specific users and versioned history rows."""

    if is_version_column(column_name) and is_history_table(table_key):
        predicates = build_version_lookup_predicates(
            table_key,
            row,
            primary_keys_by_table,
            variable_registry,
            foreign_keys_by_source,
        )
        return (
            f"(SELECT ISNULL(MAX({quote_identifier(column_name)}), 0) + 1 "
            f"FROM {quote_identifier(table_key[0])}.{quote_identifier(table_key[1])} "
            f"WHERE {predicates})"
        )
    return sql_replay_assignment_expression(table_key, column_name, value, variable_registry, foreign_keys_by_source)


def sql_update_assignment_expression(
    table_key: tuple[str, str],
    column_name: str,
    value: object,
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
) -> str:
    """Allocate replay-safe update values for row versions while preserving existing substitution rules."""

    if is_version_column(column_name):
        return f"ISNULL({quote_identifier(column_name)}, 0) + 1"
    return sql_replay_assignment_expression(table_key, column_name, value, variable_registry, foreign_keys_by_source)


def is_generated_always_column(
    table_key: tuple[str, str],
    column_name: str,
    generated_always_columns: set[tuple[str, str, str]],
) -> bool:
    """Skip replay assignments for columns SQL Server computes automatically."""

    return (table_key[0], table_key[1], column_name) in generated_always_columns


def select_key_columns(
    row: dict[str, object],
    preferred_columns: list[str],
) -> list[str]:
    """Favor real key columns but degrade gracefully so malformed metadata does not make replay impossible."""

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
) -> str:
    """Build predicates from replay-aware key expressions so updates and deletes follow regenerated IDs."""

    predicates: list[str] = []
    for column_name in key_columns:
        value = row.get(column_name)
        if value is None:
            predicates.append(f"{quote_identifier(column_name)} IS NULL")
        else:
            predicates.append(
                f"{quote_identifier(column_name)} = {sql_value_expression(table_key, column_name, value, variable_registry, foreign_keys_by_source)}"
            )
    return " AND ".join(predicates) if predicates else "1 = 0"


def register_direct_primary_key_references(
    table_key: tuple[str, str],
    row: dict[str, object],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
) -> None:
    """Backfill PK lookups after an insert so later rows can reuse the same generated value."""

    for column_name in primary_keys_by_table.get(table_key, []):
        if column_name not in row:
            continue
        variable_reference = resolve_variable_reference(table_key, column_name, row[column_name], variable_registry, foreign_keys_by_source)
        if variable_reference:
            variable_registry[(table_key[0], table_key[1], column_name, value_key(row[column_name]))] = variable_reference


def reconstruct_insert_sql(
    record: dict[str, object],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    identity_columns_by_table: dict[tuple[str, str], list[str]],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    column_sql_types: dict[tuple[str, str, str], str],
    generated_always_columns: set[tuple[str, str, str]],
    variable_registry: dict[tuple[str, str, str, str], str],
    uid_class_registry: dict[tuple[str, str, str, str], str],
) -> str | None:
    """Rebuild inserts in a rerunnable form, replacing captured generated keys with replay-time variables."""

    row = record.get("row")
    if not isinstance(row, dict):
        return None

    table_key = (str(record["schema_name"]), str(record["table_name"]))
    generated_primary_key = generated_primary_key_column(table_key, primary_keys_by_table, identity_columns_by_table)
    primary_key_columns = primary_keys_by_table.get(table_key, [])
    root_generated_primary_key: str | None = None
    existing_primary_key_variable: str | None = None

    if len(primary_key_columns) == 1 and primary_key_columns[0] in row:
        primary_key_column = primary_key_columns[0]
        existing_primary_key_variable = resolve_variable_reference(
            table_key,
            primary_key_column,
            row[primary_key_column],
            variable_registry,
            foreign_keys_by_source,
        )
        if existing_primary_key_variable:
            variable_registry[(table_key[0], table_key[1], primary_key_column, value_key(row[primary_key_column]))] = (
                existing_primary_key_variable
            )
        elif generated_primary_key is None:
            # Non-identity root tables still need a synthetic variable so dependent inserts can refer to the same replay value.
            column_sql_type = column_sql_types.get((table_key[0], table_key[1], primary_key_column), "")
            if (
                is_numeric_sql_type(column_sql_type)
                and (table_key[0], table_key[1], primary_key_column) not in foreign_keys_by_source
            ):
                root_generated_primary_key = primary_key_column

    columns = [
        column_name
        for column_name in data_columns(row)
        if column_name != generated_primary_key
        and not is_generated_always_column(table_key, column_name, generated_always_columns)
    ]
    if not columns:
        return None

    prelude_lines: list[str] = []
    post_insert_lines: list[str] = []
    if generated_primary_key and generated_primary_key in row:
        generated_value = row[generated_primary_key]
        variable_name = variable_name_for_value(table_key[0], table_key[1], generated_primary_key, generated_value)
        output_table_name = output_table_name_for_variable(variable_name)
        sql_type = column_sql_types.get((table_key[0], table_key[1], generated_primary_key), "int")
        variable_registry[(table_key[0], table_key[1], generated_primary_key, value_key(generated_value))] = variable_name
        prelude_lines.extend(
            [
                f"DECLARE {variable_name} {sql_type};",
                f"DECLARE {output_table_name} TABLE ([value] {sql_type});",
            ]
        )
    elif root_generated_primary_key and root_generated_primary_key in row:
        generated_value = row[root_generated_primary_key]
        variable_name = variable_name_for_value(table_key[0], table_key[1], root_generated_primary_key, generated_value)
        sql_type = column_sql_types.get((table_key[0], table_key[1], root_generated_primary_key), "int")
        variable_registry[(table_key[0], table_key[1], root_generated_primary_key, value_key(generated_value))] = variable_name
        uid_class_name = uid_class_registry.get((table_key[0], table_key[1], root_generated_primary_key, value_key(generated_value)))
        if uid_class_name:
            # ODSE-style tables allocate IDs through Local_UID_generator instead of IDENTITY columns.
            prelude_lines.extend(
                [
                    f"DECLARE {variable_name} {sql_type};",
                    f"EXEC dbo.getNextUid_sp @pClass = N'{sql_quote(uid_class_name)}', @uid = {variable_name} OUTPUT;",
                ]
            )
        else:
            # Fall back only when no allocator metadata exists for the captured root key.
            prelude_lines.append(
                f"DECLARE {variable_name} {sql_type} = (SELECT ISNULL(MAX({quote_identifier(root_generated_primary_key)}), 0) + 1 FROM {quote_identifier(table_key[0])}.{quote_identifier(table_key[1])});"
            )

    register_nrt_patient_mpr_uid_reference(
        table_key,
        row,
        variable_registry,
        column_sql_types,
        prelude_lines,
    )

    column_sql = ", ".join(quote_identifier(column_name) for column_name in columns)
    value_sql = ", ".join(
        sql_insert_assignment_expression(
            table_key,
            row,
            column_name,
            row[column_name],
            primary_keys_by_table,
            variable_registry,
            foreign_keys_by_source,
        )
        for column_name in columns
    )

    insert_sql = (
        f"INSERT INTO {quote_identifier(str(record['schema_name']))}.{quote_identifier(str(record['table_name']))} "
        f"({column_sql})"
    )
    if generated_primary_key and generated_primary_key in row:
        variable_name = variable_registry[(table_key[0], table_key[1], generated_primary_key, value_key(row[generated_primary_key]))]
        output_table_name = output_table_name_for_variable(variable_name)
        insert_sql += f" OUTPUT INSERTED.{quote_identifier(generated_primary_key)} INTO {output_table_name} ([value])"
    insert_sql += f" VALUES ({value_sql});"

    if generated_primary_key and generated_primary_key in row:
        variable_name = variable_registry[(table_key[0], table_key[1], generated_primary_key, value_key(row[generated_primary_key]))]
        output_table_name = output_table_name_for_variable(variable_name)
        post_insert_lines.append(f"SELECT TOP 1 {variable_name} = [value] FROM {output_table_name};")

    register_direct_primary_key_references(table_key, row, primary_keys_by_table, variable_registry, foreign_keys_by_source)
    return "\n".join([*prelude_lines, insert_sql, *post_insert_lines])


def reconstruct_delete_sql(
    record: dict[str, object],
    primary_key_columns: list[str],
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
) -> str | None:
    """Rebuild deletes against replay-aware keys so cleanup operations target regenerated rows."""

    row = record.get("row")
    if not isinstance(row, dict):
        return None
    table_key = (str(record["schema_name"]), str(record["table_name"]))
    key_columns = select_key_columns(row, primary_key_columns)
    where_clause = build_where_clause(table_key, row, key_columns, variable_registry, foreign_keys_by_source)
    return f"DELETE FROM {quote_identifier(str(record['schema_name']))}.{quote_identifier(str(record['table_name']))} WHERE {where_clause};"


def reconstruct_update_sql(
    before_record: dict[str, object],
    after_record: dict[str, object],
    primary_key_columns: list[str],
    generated_always_columns: set[tuple[str, str, str]],
    variable_registry: dict[tuple[str, str, str, str], str],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
) -> str | None:
    """Collapse CDC before/after images into one UPDATE statement that preserves replay key substitutions."""

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
        f"{quote_identifier(column_name)} = {sql_update_assignment_expression(table_key, column_name, after_row.get(column_name), variable_registry, foreign_keys_by_source)}"
        for column_name in changed_columns
    )
    key_columns = select_key_columns(before_row, primary_key_columns)
    where_clause = build_where_clause(table_key, before_row, key_columns, variable_registry, foreign_keys_by_source)
    return (
        f"UPDATE {quote_identifier(str(after_record['schema_name']))}.{quote_identifier(str(after_record['table_name']))} "
        f"SET {set_clause} WHERE {where_clause};"
    )


def append_sql_statement(
    statements: list[str],
    last_table_key: tuple[str, str] | None,
    table_key: tuple[str, str],
    sql_statement: str,
) -> tuple[str, str]:
    """Add lightweight visual grouping so long replay sections stay readable without reordering statements."""

    # Keep the replay section visually grouped by table without changing execution order.
    if last_table_key != table_key:
        if statements:
            statements.append("")
        statements.append(f"-- {table_key[0]}.{table_key[1]}")
    statements.append(sql_statement)
    return table_key


def reconstruct_sql_statements(
    changes: list[dict[str, object]],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    identity_columns_by_table: dict[tuple[str, str], list[str]],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    column_sql_types: dict[tuple[str, str, str], str],
    generated_always_columns: set[tuple[str, str, str]],
    uid_generator_entries: list[UidGeneratorEntry],
) -> list[str]:
    """Walk the CDC stream once and emit replay SQL in the same logical order the source database saw."""

    statements: list[str] = []
    pending_updates: dict[tuple[str, str, int | None], dict[str, object]] = {}
    variable_registry: dict[tuple[str, str, str, str], str] = {}
    uid_class_registry = infer_uid_class_registry(changes, primary_keys_by_table, foreign_keys_by_source, uid_generator_entries)
    last_table_key: tuple[str, str] | None = None

    for record in sorted(changes, key=change_sort_key):
        table_key = (str(record["schema_name"]), str(record["table_name"]))
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
        operation = record["operation"]

        if operation == "insert":
            sql_statement = reconstruct_insert_sql(
                record,
                primary_keys_by_table,
                identity_columns_by_table,
                foreign_keys_by_source,
                column_sql_types,
                generated_always_columns,
                variable_registry,
                uid_class_registry,
            )
            if sql_statement:
                last_table_key = append_sql_statement(statements, last_table_key, table_key, sql_statement)
            continue

        if operation == "delete":
            sql_statement = reconstruct_delete_sql(record, primary_key_columns, variable_registry, foreign_keys_by_source)
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
                variable_registry,
                foreign_keys_by_source,
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

    return statements


def summarize_update_pair(before_record: dict[str, object], after_record: dict[str, object]) -> str:
    """Condense update-before and update-after rows into one readable summary line."""

    before_row = before_record.get("row") if isinstance(before_record.get("row"), dict) else {}
    after_row = after_record.get("row") if isinstance(after_record.get("row"), dict) else {}

    changed_columns: list[str] = []
    for column_name in sorted(set(before_row) | set(after_row)):
        if column_name in CDC_METADATA_COLUMNS:
            continue
        before_value = before_row.get(column_name)
        after_value = after_row.get(column_name)
        if before_value != after_value:
            changed_columns.append(f"{column_name}: {format_value(before_value)} -> {format_value(after_value)}")

    identity = summarize_record_identity(after_record)
    parse_error = before_record.get("row_parse_error") or after_record.get("row_parse_error")

    if parse_error:
        return f"update {identity} [payload parse error]"

    if not changed_columns:
        return f"update {identity} [no visible column change]"

    suffix = "; ..." if len(changed_columns) > 3 else ""
    return f"update {identity} {'; '.join(changed_columns[:3])}{suffix}"


def summarize_table_records(records: list[dict[str, object]]) -> list[str]:
    """Preserve table-level chronology while hiding CDC's two-row update representation from the summary."""

    lines: list[str] = []
    pending_updates: dict[tuple[str, str, int | None], dict[str, object]] = {}

    for record in records:
        operation = record["operation"]
        if operation == "update_before":
            pending_updates[update_pair_key(record)] = record
            continue

        if operation == "update_after":
            pair_key = update_pair_key(record)
            before_record = pending_updates.pop(pair_key, None)
            if before_record is not None:
                lines.append(f"    - {summarize_update_pair(before_record, record)}")
                continue

        lines.append(f"    - {summarize_row_identifier(record)}")

    for record in pending_updates.values():
        lines.append(f"    - {summarize_row_identifier(record)}")

    return lines


def write_jsonl(path: Path, records: Iterable[dict[str, object]]) -> None:
    """Keep the raw capture stream on disk so summary and replay bugs can be debugged without recapturing data."""

    with path.open("w", encoding="utf-8", newline="\n") as handle:
        for record in records:
            handle.write(json.dumps(record, ensure_ascii=True))
            handle.write("\n")


def write_manifest(path: Path, manifest: dict[str, object]) -> None:
    """Persist run metadata separately so consumers can inspect the trace window without parsing the summary text."""

    path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")


def prompt_nbs_actions() -> list[str]:
    """Collect a one-line description of the NBS actions that produced the captured CDC changes."""

    action = input("Describe the actions you took in NBS: ").strip()
    return [action] if action else []


def write_summary(
    path: Path,
    nbs_actions: list[str],
    manifest: dict[str, object],
    changes: list[dict[str, object]],
    primary_keys_by_table: dict[tuple[str, str], list[str]],
    identity_columns_by_table: dict[tuple[str, str], list[str]],
    foreign_keys_by_source: dict[tuple[str, str, str], tuple[str, str, str]],
    column_sql_types: dict[tuple[str, str, str], str],
    generated_always_columns: set[tuple[str, str, str]],
    uid_generator_entries: list[UidGeneratorEntry],
) -> None:
    """Produce one human-friendly artifact that explains both what changed and how to replay it."""

    op_counts = Counter(record["operation"] for record in changes)
    table_counts: defaultdict[str, int] = defaultdict(int)
    table_records: defaultdict[str, list[dict[str, object]]] = defaultdict(list)
    for record in changes:
        table_name = f"{record['schema_name']}.{record['table_name']}"
        table_counts[table_name] += 1
        table_records[table_name].append(record)

    lines: list[str] = []
    if nbs_actions:
        lines.append("Actions performed in NBS:")
        for action in nbs_actions:
            lines.append(f"- {action}")
        lines.append("")

    lines.extend([
        f"Run started: {manifest['start_time_utc']}",
        f"Run ended:   {manifest['end_time_utc']}",
        f"Start LSN:   {manifest['start_lsn']}",
        f"End LSN:     {manifest['end_lsn']}",
        "",
        f"Initially CDC-enabled tables: {manifest['initially_tracked_table_count']}",
        f"Tables enabled by this run:   {len(manifest['enabled_tables'])}",
        f"Tables skipped by this run:   {len(manifest['skipped_tables'])}",
        f"Total captured rows:          {len(changes)}",
        "",
        "Captured rows by operation:",
    ])

    for operation in sorted(op_counts):
        lines.append(f"- {operation}: {op_counts[operation]}")

    lines.append("")
    lines.append("Captured rows by table:")
    for table_name in sorted(table_counts):
        lines.append(f"- {table_name}: {table_counts[table_name]}")
        lines.extend(summarize_table_records(table_records[table_name]))

    if manifest["skipped_tables"]:
        lines.append("")
        lines.append("Skipped tables:")
        for item in manifest["skipped_tables"]:
            lines.append(f"- {item['schema_name']}.{item['table_name']}: {item['detail']}")

    replay_changes = [
        record
        for record in changes
        if record.get("operation") in {"insert", "delete", "update_before", "update_after"}
    ]
    reconstructed_sql = []
    if replay_changes:
        reconstructed_sql = reconstruct_sql_statements(
            replay_changes,
            primary_keys_by_table,
            identity_columns_by_table,
            foreign_keys_by_source,
            column_sql_types,
            generated_always_columns,
            uid_generator_entries,
        )
    if reconstructed_sql:
        lines.append("")
        lines.append("Reconstructed SQL:")
        for statement in reconstructed_sql:
            lines.append(statement)

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run_disable_only(
    args: argparse.Namespace,
    client: SqlCmdClient,
    state_file: Path,
    legacy_state_file: Path | None,
) -> int:
    """Let the tracer act as a cleanup tool when the user wants to turn CDC back off later."""

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
    """Coordinate CDC setup, capture, artifact generation, and cleanup so the workflow stays reproducible."""

    args = parse_args()
    executable = require_sqlcmd(args.sqlcmd)
    client = SqlCmdClient(executable, args.server, args.database, args.user, args.password)
    state_file, legacy_state_file = resolve_state_files(args)

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
    primary_keys_by_table, identity_columns_by_table, foreign_keys_by_source, column_sql_types, generated_always_columns, uid_generator_entries = get_replay_metadata(
        client,
        args.database,
    )

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
        captures = fetch_capture_instances(client)
        log_progress(f"Loaded {len(captures)} CDC capture instances")

        log_progress("Fetching CDC rows within the recorded LSN window")
        changes = fetch_changes_for_captures(client, captures, start_lsn, end_lsn)

        log_progress("Sorting captured CDC rows")
        changes.sort(key=change_sort_key)
        log_progress(f"Sorted {len(changes)} CDC rows")

        log_progress("Creating output directory")
        output_root = Path(args.output_dir)
        run_dir = output_root / datetime.now().strftime("%Y%m%d-%H%M%S")
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