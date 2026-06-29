"""Command-line entrypoint for rdb-compare.

Connects to the SQL Server instance holding both RDB and RDB_MODERN, discovers
the tables to compare, resolves each table's business/UID key, runs the
column-by-column comparison, classifies every difference against the
known-differences rule catalog, and writes JSON + Markdown reports.

    uv run rdb-compare --host localhost --port 3433 --user sa \\
        --rdb RDB --modern RDB_MODERN --out ./out
"""

from __future__ import annotations

import argparse
import os
import sys
import time
from datetime import datetime, timezone

from rdb_compare import db, discovery, engine, keys, report
from rdb_compare.classifier import classify_run, summarize
from rdb_compare.models import Presence, RunReport, TableResult
from rdb_compare.rules.catalog import build_default_registry


def _parse_args(argv):
    p = argparse.ArgumentParser(
        prog="rdb-compare",
        description="Compare legacy RDB (MasterETL) against RDB_MODERN (RTR), "
        "classifying every difference as NEW / EXPECTED / KNOWN_BUG / IGNORED.",
    )
    p.add_argument("--host", default="localhost")
    p.add_argument("--port", type=int, default=3433)
    p.add_argument("--user", default="sa")
    p.add_argument(
        "--password",
        default=os.environ.get("SQLCMDPASSWORD", "PizzaIsGood33!"),
        help="DB password (default: $SQLCMDPASSWORD or the dev default).",
    )
    p.add_argument("--rdb", default="RDB", help="Legacy database name.")
    p.add_argument("--modern", default="RDB_MODERN", help="Modern database name.")
    p.add_argument("--out", default="./out", help="Output directory.")
    p.add_argument(
        "--include",
        action="append",
        default=None,
        help="Glob of table names to include (repeatable).",
    )
    p.add_argument(
        "--exclude",
        action="append",
        default=None,
        help="Glob of table names to exclude (repeatable).",
    )
    p.add_argument("--sample-cap", type=int, default=20, help="Max sample rows per column.")
    p.add_argument(
        "--query-timeout",
        type=int,
        default=120,
        help="Per-query timeout in seconds (0 = no limit). A table whose "
        "cross-DB join exceeds this is recorded as an error and the run "
        "continues.",
    )
    p.add_argument(
        "--progress",
        action="store_true",
        help="Print per-table progress to stderr (table index, presence, timing).",
    )
    p.add_argument(
        "--fail-on-new",
        action="store_true",
        help="Exit non-zero if any NEW (unexplained) difference is found.",
    )
    return p.parse_args(argv)


def _common_columns(conn, rdb_db, modern_db, table):
    """Columns present in BOTH copies of the table, preserving RDB order."""
    rdb_cols = db.list_columns(conn, rdb_db, table)
    modern_cols = {c.upper() for c in db.list_columns(conn, modern_db, table)}
    return [c for c in rdb_cols if c.upper() in modern_cols]


def _progress(args, msg):
    """Emit a per-table progress line to stderr when --progress is set."""
    if args.progress:
        print(msg, file=sys.stderr, flush=True)


def run(args) -> RunReport:
    registry = build_default_registry()
    timeout = getattr(args, "query_timeout", 0)
    conn = db.connect(args.host, args.port, args.user, args.password, timeout=timeout)

    tables = discovery.discover(
        conn, args.rdb, args.modern, registry,
        include=args.include, exclude=args.exclude,
    )

    report_obj = RunReport(
        rdb_db=args.rdb,
        modern_db=args.modern,
        generated_at=datetime.now(timezone.utc).isoformat(timespec="seconds"),
        discovered=len(tables),
    )

    total = len(tables)
    for i, table in enumerate(tables, 1):
        _progress(args, f"[{i}/{total}] {table} ...")
        started = time.monotonic()
        try:
            common = _common_columns(conn, args.rdb, args.modern, table)
            key_cols = keys.resolve_keys(table, common)
            value_cols = [
                c for c in common
                if not key_cols or c.upper() not in {k.upper() for k in key_cols}
            ]
            result = engine.compare_table(
                conn, table, key_cols or (), value_cols,
                args.rdb, args.modern, sample_cap=args.sample_cap,
            )
            if not key_cols:
                note = "no usable UID/LOCAL_ID key; compared row counts only"
                result.error = (result.error + "; " + note) if result.error else note
        except Exception as exc:  # noqa: BLE001 -- isolate per-table failures
            result = TableResult(table=table, presence=Presence.BOTH, error=str(exc))
            # A query timeout (or any driver-level error) can leave the shared
            # connection unusable for subsequent tables; reconnect so one bad
            # table cannot cascade into a wall of errors.
            try:
                conn = db.connect(
                    args.host, args.port, args.user, args.password, timeout=timeout
                )
            except Exception:  # noqa: BLE001
                pass
        elapsed = time.monotonic() - started
        _progress(
            args,
            f"[{i}/{total}] {table} {result.presence.value} "
            f"rdb={result.rdb_count} modern={result.modern_count} "
            f"{elapsed:.1f}s{' ERR' if result.error else ''}",
        )
        report_obj.tables.append(result)

    report_obj.compared = sum(1 for t in report_obj.tables if not t.skipped)
    classify_run(report_obj, registry)
    report_obj.skipped = sum(1 for t in report_obj.tables if t.skipped)
    report_obj.compared = len(report_obj.tables) - report_obj.skipped
    return report_obj


def main(argv=None) -> int:
    args = _parse_args(argv if argv is not None else sys.argv[1:])
    report_obj = run(args)

    os.makedirs(args.out, exist_ok=True)
    json_path = os.path.join(args.out, "comparison.json")
    md_path = os.path.join(args.out, "comparison.md")
    report.write_json(report_obj, json_path)
    report.write_markdown(report_obj, md_path)

    s = summarize(report_obj)
    counts = s["verdict_counts"]
    print(f"Compared {report_obj.compared} tables ({report_obj.skipped} skipped) "
          f"of {report_obj.discovered} discovered.")
    print(f"  NEW={counts['NEW']}  KNOWN_BUG={counts['KNOWN_BUG']}  "
          f"EXPECTED={counts['EXPECTED']}  IGNORED={counts['IGNORED']}")
    print(f"  {s['actionable_tables']} table(s) with unexplained (NEW) differences.")
    print(f"Wrote {json_path} and {md_path}")

    if args.fail_on_new and counts["NEW"] > 0:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
