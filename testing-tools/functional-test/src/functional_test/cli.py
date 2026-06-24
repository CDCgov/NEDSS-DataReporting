"""Command-line entry point for the functional test runner."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

from .env import load_database_connection_defaults, resolve_server_argument
from .runner import (
    DEFAULT_MAX_RETRY,
    DEFAULT_RETRY_DELAY,
    Database,
    QueryResult,
    TestResult,
    discover_tests,
    parse_address,
    run_test,
)

_USE_COLOR = sys.stdout.isatty() and os.environ.get("NO_COLOR") is None


def _c(text: str, code: str) -> str:
    if not _USE_COLOR:
        return text
    return f"\033[{code}m{text}\033[0m"


def _green(t: str) -> str:
    return _c(t, "32")


def _red(t: str) -> str:
    return _c(t, "31")


def _dim(t: str) -> str:
    return _c(t, "2")


def _bold(t: str) -> str:
    return _c(t, "1")


def build_parser(defaults: dict[str, str] | None = None) -> argparse.ArgumentParser:
    if defaults is None:
        defaults = load_database_connection_defaults()

    parser = argparse.ArgumentParser(
        prog="functional-test",
        description=(
            "Run NEDSS reporting-pipeline functional tests against an already-running "
            "database and application. For each test step the setup SQL is executed against "
            "the source database (NBS_ODSE) and each query is polled against the reporting "
            "database (RDB_MODERN) until its result matches the expected JSON.\n\n"
            "Connection defaults are read from a .env file (or environment) using the same "
            "variable names as the local-db-tracing tools: DATABASE_SERVER, DATABASE_PORT, "
            "DATABASE_USERNAME, DATABASE_PASSWORD. Flags below override them."
        ),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "-S",
        "--server",
        dest="address",
        default=resolve_server_argument(defaults),
        metavar="ADDRESS",
        help="Database address: host, host:port or host,port. Defaults to "
        "DATABASE_SERVER,DATABASE_PORT from .env.",
    )
    parser.add_argument(
        "-U",
        "--user",
        dest="user",
        default=defaults.get("DATABASE_USERNAME"),
        help="Database user (needs write on NBS_ODSE, read on RDB_MODERN). "
        "Defaults to DATABASE_USERNAME from .env.",
    )
    parser.add_argument(
        "-P",
        "--password",
        dest="password",
        default=defaults.get("DATABASE_PASSWORD"),
        help="Database password. Defaults to DATABASE_PASSWORD from .env.",
    )
    parser.add_argument(
        "-d",
        "--data-dir",
        dest="data_dir",
        type=Path,
        required=True,
        help="Directory containing functional test data (the 'functional' folder).",
    )
    parser.add_argument(
        "-t",
        "--test",
        dest="tests",
        action="append",
        metavar="TEST",
        help="Test name to run; repeat -t to run several. If omitted, all tests are run.",
    )
    remap_group = parser.add_mutually_exclusive_group()
    remap_group.add_argument(
        "-i",
        "--id",
        dest="start_id",
        type=int,
        default=None,
        metavar="START_ID",
        help=(
            "Override the test's starting UID. All IDs in the test's allocated block are "
            "shifted on the fly (files on disk are not modified). Requires exactly one -t."
        ),
    )
    remap_group.add_argument(
        "-s",
        "--shift-id",
        dest="shift_id",
        type=int,
        default=None,
        metavar="DELTA",
        help=(
            "Shift every test's UIDs by this integer delta on the fly (files on disk are "
            "not modified). Works with any number of tests. Mutually exclusive with -i."
        ),
    )
    parser.add_argument(
        "--database",
        default="NBS_ODSE",
        help="Initial database for the connection. Setup SQL switches DB with USE [...].",
    )
    parser.add_argument(
        "--max-retry",
        type=int,
        default=DEFAULT_MAX_RETRY,
        help="Maximum number of polls per query before giving up.",
    )
    parser.add_argument(
        "--retry-delay",
        type=float,
        default=DEFAULT_RETRY_DELAY,
        help="Seconds to wait between polls.",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List the discovered tests and exit (no database connection).",
    )
    parser.add_argument(
        "--fail-fast",
        action="store_true",
        help="Stop after the first failing test.",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Live-print each query's SQL and its expected vs actual results on every poll "
        "attempt (so a failing/slow query's data is visible as it changes across retries).",
    )
    return parser


def _print_failure_line(query: QueryResult) -> None:
    print(_red(f"      ✗ query {query.index} FAILED ({query.attempts} attempt(s), "
               f"{query.elapsed:.1f}s)"))
    if query.error:
        print(_dim(f"        error: {query.error}"))


def _print_query_detail(index: int, query: str, expected, actual, note: str = "") -> None:
    header = f"      query {index} detail" + (f" ({note})" if note else "") + ":"
    print(_dim(header))
    print(_dim("        query:"))
    for line in query.splitlines():
        print(_dim(f"          {line}"))
    print(_dim("        expected:"))
    for line in json.dumps(expected, indent=2, default=str).splitlines():
        print(_dim(f"          {line}"))
    print(_dim("        actual:"))
    if not actual:
        print(_dim("          (no rows)"))
    else:
        for line in json.dumps(actual, indent=2, default=str).splitlines():
            print(_dim(f"          {line}"))


def _print_test_result(result: TestResult) -> None:
    """Print the end-of-test pass/fail summary.

    Individual query failures are printed live as they happen (see the on_query
    callback in main); here we only summarize test- and step-level status.
    """
    if result.passed:
        print(_green(f"  ✓ {result.name}"))
        return

    print(_red(f"  ✗ {result.name}"))
    if result.error:
        print(_dim(f"      {result.error}"))
    for step in result.steps:
        if step.passed:
            print(_green(f"    ✓ step {step.name}"))
            continue
        print(_red(f"    ✗ step {step.name}"))
        if step.setup_error:
            print(_red("      ✗ setup.sql FAILED"))
            print(_dim(f"        {step.setup_error}"))


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        test_dirs = discover_tests(args.data_dir, args.tests or None)
    except (FileNotFoundError, ValueError) as exc:
        print(_red(str(exc)), file=sys.stderr)
        return 2

    if args.start_id is not None and len(test_dirs) != 1:
        print(
            _red("-i/--id requires exactly one test (selected with a single -t); "
                 f"{len(test_dirs)} tests selected."),
            file=sys.stderr,
        )
        return 2

    if args.list:
        print(f"Discovered {len(test_dirs)} test(s) in {args.data_dir}:")
        for test_dir in test_dirs:
            print(f"  {test_dir.name}")
        return 0

    if not args.user:
        print(
            _red("No database user. Pass -U or set DATABASE_USERNAME in .env / the environment."),
            file=sys.stderr,
        )
        return 2

    password = args.password
    if not password:
        print(
            _red("No password. Pass -P or set DATABASE_PASSWORD in .env / the environment."),
            file=sys.stderr,
        )
        return 2

    host, port = parse_address(args.address)

    print(_bold(f"Connecting to {host}" + (f":{port}" if port else "") + f" as {args.user} ..."))
    try:
        db = Database(host, port, args.user, password, args.database)
    except Exception as exc:  # noqa: BLE001
        print(_red(f"Failed to connect: {type(exc).__name__}: {exc}"), file=sys.stderr)
        return 2

    print(_bold(f"Running {len(test_dirs)} functional test(s)\n"))

    def emit(msg: str) -> None:
        print(_dim(msg))
        sys.stdout.flush()

    def on_query(query: QueryResult) -> None:
        # Print each failure the moment it happens, not at the end of the test.
        if not query.passed:
            _print_failure_line(query)
            sys.stdout.flush()

    def on_poll(index: int, query: str, expected, attempt: int, actual, matched: bool) -> None:
        # In debug, show the query and what it returns on every poll, so the
        # actual data is visible live as it changes across retries.
        if args.debug:
            note = f"attempt {attempt}: " + ("matched" if matched else "no match")
            _print_query_detail(index, query, expected, actual, note)
            sys.stdout.flush()

    results: list[TestResult] = []
    try:
        for test_dir in test_dirs:
            print(_bold(f"  • {test_dir.name}"))
            sys.stdout.flush()
            result = run_test(
                db,
                test_dir,
                max_retry=args.max_retry,
                retry_delay=args.retry_delay,
                on_event=emit,
                new_start_id=args.start_id,
                shift_id=args.shift_id,
                on_query=on_query,
                on_poll=on_poll,
            )
            results.append(result)
            _print_test_result(result)
            print()
            if args.fail_fast and not result.passed:
                print(_red("Stopping after first failure (--fail-fast)."))
                break
    finally:
        db.close()

    passed = sum(1 for r in results if r.passed)
    failed = len(results) - passed
    print(_bold("=" * 60))
    summary = f"{passed} passed, {failed} failed, {len(results)} total"
    print(_bold(_green(summary) if failed == 0 else _red(summary)))

    if failed and not args.debug:
        print(_dim("Re-run with --debug to see the query and expected vs actual for failures."))

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
