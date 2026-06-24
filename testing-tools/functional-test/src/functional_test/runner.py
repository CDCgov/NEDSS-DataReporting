"""Discovery and execution of data-driven functional tests.

This mirrors ``DataDrivenFunctionalTests`` from the Java reporting-pipeline-service:

  * Each immediate sub-directory of the test-data directory is one test.
  * Within a test, each sub-directory is a *step*, executed in alphabetical order.
  * A step contains ``setup.sql``, ``query.sql`` and ``expected.json``.
  * ``setup.sql`` is executed once (it inserts source data into NBS_ODSE).
  * Each statement in ``query.sql`` (split on ``;``) is polled against the
    reporting database until it returns rows matching ``expected.json`` (lenient
    JSON match) or the retry limit is hit.
"""

from __future__ import annotations

import json
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Optional

from .compare import lenient_match, normalize_rows
from .remapper import IdRemapper, build_id_remapper, build_shift_remapper

SETUP_FILE = "setup.sql"
QUERY_FILE = "query.sql"
EXPECTED_FILE = "expected.json"

DEFAULT_MAX_RETRY = 40
DEFAULT_RETRY_DELAY = 6.0


def split_statements(sql: str) -> list[str]:
    """Split SQL on ``;``, dropping ``--`` comment lines and blank statements.

    Faithful port of ``QueryRunner.splitStatements`` from the Java tests.
    """
    if not sql or not sql.strip():
        return []

    statements = []
    for chunk in sql.split(";"):
        lines = [line for line in chunk.splitlines() if not line.lstrip().startswith("--")]
        statement = "\n".join(lines).strip()
        if statement:
            statements.append(statement)
    return statements


def discover_tests(data_dir: Path, selected: Optional[list[str]] = None) -> list[Path]:
    """Return the test directories under ``data_dir``.

    If ``selected`` is given, only directories whose names match (case
    insensitive) are returned, in the order requested.
    """
    if not data_dir.is_dir():
        raise FileNotFoundError(f"Test data directory does not exist: {data_dir}")

    all_dirs = sorted(p for p in data_dir.iterdir() if p.is_dir())

    if not selected:
        return all_dirs

    by_name = {p.name.lower(): p for p in all_dirs}
    resolved: list[Path] = []
    missing: list[str] = []
    for name in selected:
        match = by_name.get(name.lower())
        if match is None:
            missing.append(name)
        else:
            resolved.append(match)

    if missing:
        available = ", ".join(p.name for p in all_dirs) or "(none)"
        raise ValueError(
            f"Unknown functional test(s): {', '.join(missing)}.\nAvailable tests: {available}"
        )
    return resolved


def discover_steps(test_dir: Path) -> list[Path]:
    return sorted((p for p in test_dir.iterdir() if p.is_dir()), key=lambda p: p.name)


@dataclass
class QueryResult:
    index: int
    query: str
    passed: bool
    attempts: int
    elapsed: float
    expected: Any = None
    actual: Any = None
    error: Optional[str] = None


@dataclass
class StepResult:
    name: str
    setup_error: Optional[str] = None
    queries: list[QueryResult] = field(default_factory=list)

    @property
    def passed(self) -> bool:
        return self.setup_error is None and all(q.passed for q in self.queries)


@dataclass
class TestResult:
    name: str
    steps: list[StepResult] = field(default_factory=list)
    error: Optional[str] = None

    @property
    def passed(self) -> bool:
        return self.error is None and all(s.passed for s in self.steps)


class Database:
    """Thin wrapper over a single pymssql connection.

    A single connection (the Java ``adminClient``) is enough: ``setup.sql``
    switches database with ``USE [...]`` and every query uses three-part
    ``[RDB_MODERN].[dbo].[...]`` names, so cross-database reads work from the
    same connection.
    """

    def __init__(self, host: str, port: Optional[int], user: str, password: str, database: str):
        import pymssql  # imported lazily so --help works without the driver

        kwargs: dict[str, Any] = {
            "server": host,
            "user": user,
            "password": password,
            "database": database,
            "autocommit": False,
        }
        if port is not None:
            kwargs["port"] = str(port)
        self._conn = pymssql.connect(**kwargs)

    def execute_setup(self, sql: str) -> None:
        if not sql or not sql.strip():
            return
        cursor = self._conn.cursor()
        try:
            cursor.execute(sql)
            self._conn.commit()
        except Exception:
            self._conn.rollback()
            raise
        finally:
            cursor.close()

    def select(self, query: str) -> list[dict[str, Any]]:
        # Each poll uses its own transaction so it sees freshly-committed
        # pipeline output rather than a stale snapshot.
        self._conn.commit()
        cursor = self._conn.cursor(as_dict=True)
        try:
            cursor.execute(query)
            return list(cursor.fetchall())
        finally:
            cursor.close()

    def close(self) -> None:
        try:
            self._conn.close()
        except Exception:
            pass


def parse_address(address: str) -> tuple[str, Optional[int]]:
    """Parse ``host``, ``host:port`` or ``host,port`` into (host, port).

    A backslash (named instance, e.g. ``host\\SQLEXPRESS``) is left intact and
    no port is extracted.
    """
    address = address.strip()
    if "\\" in address and ":" not in address and "," not in address:
        return address, None
    sep = "," if "," in address else (":" if ":" in address else None)
    if sep is None:
        return address, None
    host, _, port_str = address.partition(sep)
    port_str = port_str.strip()
    return host.strip(), int(port_str) if port_str else None


def _wait_for_match(
    fetch: Callable[[], list[dict[str, Any]]],
    expected: Any,
    max_retry: int,
    retry_delay: float,
    on_attempt: Optional[Callable[[int, Any, bool], None]] = None,
) -> tuple[bool, int, Any]:
    """Poll ``fetch`` until rows match ``expected`` or retries are exhausted.

    ``on_attempt`` (if given) is called after every poll with
    (attempt_number, rows, matched) so callers can surface progress live.

    Returns (matched, attempts, last_actual).
    """
    last_actual: Any = None
    for attempt in range(1, max_retry + 1):
        rows = normalize_rows(fetch())
        last_actual = rows
        matched = bool(rows) and lenient_match(expected, rows)
        if on_attempt:
            on_attempt(attempt, rows, matched)
        if matched:
            return True, attempt, rows
        if attempt < max_retry:
            time.sleep(retry_delay)
    return False, max_retry, last_actual


def run_step(
    db: Database,
    step_dir: Path,
    max_retry: int,
    retry_delay: float,
    on_event: Optional[Callable[[str], None]] = None,
    remapper: Optional[IdRemapper] = None,
    on_query: Optional[Callable[["QueryResult"], None]] = None,
    on_poll: Optional[Callable[[int, str, Any, int, Any, bool], None]] = None,
) -> StepResult:
    result = StepResult(name=step_dir.name)

    setup_path = step_dir / SETUP_FILE
    query_path = step_dir / QUERY_FILE
    expected_path = step_dir / EXPECTED_FILE

    for path in (setup_path, query_path, expected_path):
        if not path.is_file():
            result.setup_error = f"Missing required file: {path.name}"
            return result

    setup_sql = setup_path.read_text()
    query_text = query_path.read_text()
    expected_text = expected_path.read_text()
    if remapper is not None:
        setup_sql = remapper.apply(setup_sql)
        query_text = remapper.apply(query_text)
        expected_text = remapper.apply(expected_text)

    queries = split_statements(query_text)
    expected_map = json.loads(expected_text)

    try:
        db.execute_setup(setup_sql)
    except Exception as exc:  # noqa: BLE001 - surface any DB error to the report
        result.setup_error = f"{type(exc).__name__}: {exc}"
        return result

    for i, query in enumerate(queries):
        if on_event:
            on_event(f"      query {i} ...")
        expected = expected_map.get(str(i))
        if expected is None:
            query_result = QueryResult(
                index=i,
                query=query,
                passed=False,
                attempts=0,
                elapsed=0.0,
                error=f"No expected entry '{i}' in {EXPECTED_FILE}",
            )
            result.queries.append(query_result)
            if on_query:
                on_query(query_result)
            break

        start = time.monotonic()
        attempt_cb = None
        if on_poll:
            attempt_cb = (
                lambda attempt, rows, matched, i=i, q=query, e=expected: on_poll(
                    i, q, e, attempt, rows, matched
                )
            )
        try:
            matched, attempts, actual = _wait_for_match(
                lambda q=query: db.select(q), expected, max_retry, retry_delay, attempt_cb
            )
            error = None
        except Exception as exc:  # noqa: BLE001
            matched, attempts, actual = False, 0, None
            error = f"{type(exc).__name__}: {exc}"

        query_result = QueryResult(
            index=i,
            query=query,
            passed=matched,
            attempts=attempts,
            elapsed=time.monotonic() - start,
            expected=expected,
            actual=actual,
            error=error,
        )
        result.queries.append(query_result)
        if on_query:
            on_query(query_result)

        # Steps run sequentially and each builds on the previous one's state, so
        # once a query fails there is no point running the rest of this test.
        if not matched:
            break

    return result


def run_test(
    db: Database,
    test_dir: Path,
    max_retry: int,
    retry_delay: float,
    on_event: Optional[Callable[[str], None]] = None,
    new_start_id: Optional[int] = None,
    shift_id: Optional[int] = None,
    on_query: Optional[Callable[["QueryResult"], None]] = None,
    on_poll: Optional[Callable[[int, str, Any, int, Any, bool], None]] = None,
) -> TestResult:
    result = TestResult(name=test_dir.name)
    try:
        steps = discover_steps(test_dir)
    except OSError as exc:
        result.error = f"{type(exc).__name__}: {exc}"
        return result

    if not steps:
        result.error = "No step directories found"
        return result

    remapper: Optional[IdRemapper] = None
    if shift_id is not None or new_start_id is not None:
        try:
            if shift_id is not None:
                remapper = build_shift_remapper(test_dir, shift_id)
            else:
                remapper = build_id_remapper(test_dir, new_start_id)
        except ValueError as exc:
            result.error = str(exc)
            return result
        if on_event:
            on_event(
                f"    remapping ids: {remapper.orig_start} -> {remapper.new_start} "
                f"(offset {remapper.offset:+d})"
            )

    for step_dir in steps:
        if on_event:
            on_event(f"    step {step_dir.name}")
        step_result = run_step(
            db, step_dir, max_retry, retry_delay, on_event, remapper, on_query, on_poll
        )
        result.steps.append(step_result)
        # Later steps depend on this one; stop the test at the first failure.
        if not step_result.passed:
            break

    return result
