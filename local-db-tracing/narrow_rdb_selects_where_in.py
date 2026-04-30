"""Narrow ambiguous WHERE IN variable predicates in generated rdb-selects.sql files.

This helper executes each SELECT case and rewrites:
    WHERE [COLUMN] IN (@var1, @var2, ...)
into:
    WHERE [COLUMN] = @varX
when all of the following are true:
1) the query returns exactly one row
2) the returned row includes COLUMN
3) exactly one declared variable resolves to the returned COLUMN value
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path

from generate_query_expected import parse_declare_entries, resolve_declare_values
from tracing_env import load_database_connection_defaults, resolve_server_argument
from tracing_models import SqlCmdError
from tracing_sql import SqlCmdClient, require_sqlcmd
from validate_rdb_selects import build_prelude_sql, parse_actual_json, parse_cases, parse_use_database

IN_CLAUSE_PATTERN = re.compile(
    r"^(?P<indent>\s*)(?P<keyword>WHERE|AND)\s+\[(?P<column>[^\]]+)\]\s+IN\s*\((?P<vars>[^)]+)\)\s*$",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class ClauseCandidate:
    line_index: int
    keyword: str
    column: str
    variable_names: tuple[str, ...]


def parse_args() -> argparse.Namespace:
    defaults = load_database_connection_defaults()
    parser = argparse.ArgumentParser(
        description="Resolve WHERE ... IN (@vars...) clauses in rdb-selects.sql to WHERE ... = @var when safely determinable."
    )
    parser.add_argument("--input-file", required=True, help="Path to rdb-selects.sql")
    parser.add_argument(
        "--output-file",
        help="Optional output path. If omitted, rewrites the input file in place.",
    )
    parser.add_argument(
        "--server",
        default=resolve_server_argument(defaults),
        help="SQL Server host and port; defaults to DATABASE_SERVER and DATABASE_PORT from .env",
    )
    parser.add_argument(
        "--database",
        help="Target database; defaults to USE [database] from SQL file, then DATABASE_NAME env if available",
    )
    parser.add_argument(
        "--user",
        default=defaults.get("DATABASE_USERNAME"),
        help="SQL Server login; defaults to DATABASE_USERNAME from .env",
    )
    parser.add_argument(
        "--password",
        default=defaults.get("DATABASE_PASSWORD"),
        help="SQL Server password; defaults to DATABASE_PASSWORD from .env",
    )
    parser.add_argument("--sqlcmd", default="sqlcmd", help="sqlcmd executable name or path")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Do not write files; print planned changes only.",
    )
    args = parser.parse_args()

    if not args.user:
        parser.error("--user is required unless DATABASE_USERNAME is set in .env or the environment")
    if not args.password:
        parser.error("--password is required unless DATABASE_PASSWORD is set in .env or the environment")
    return args


def collect_declare_lines(sql_text: str) -> list[str]:
    lines: list[str] = []
    for raw in sql_text.splitlines():
        stripped = raw.strip()
        if stripped.upper().startswith("DECLARE "):
            lines.append(stripped)
    return lines


def parse_clause_candidates(case_query_sql: str, case_start_line: int) -> list[ClauseCandidate]:
    candidates: list[ClauseCandidate] = []
    for offset, raw_line in enumerate(case_query_sql.splitlines()):
        match = IN_CLAUSE_PATTERN.match(raw_line)
        if match is None:
            continue
        variable_names = tuple(
            part.strip()
            for part in match.group("vars").split(",")
            if part.strip().startswith("@")
        )
        if len(variable_names) < 2:
            continue
        candidates.append(
            ClauseCandidate(
                line_index=case_start_line - 1 + offset,
                keyword=match.group("keyword"),
                column=match.group("column"),
                variable_names=variable_names,
            )
        )
    return candidates


def find_single_case_row(client: SqlCmdClient, prelude_sql: str, query_sql: str) -> dict[str, object] | None:
    try:
        raw_output = client.query(prelude_sql + "\n\n" + query_sql)
    except SqlCmdError:
        return None

    try:
        actual = parse_actual_json(raw_output)
    except ValueError:
        return None

    if not isinstance(actual, list) or len(actual) != 1:
        return None

    row = actual[0]
    if not isinstance(row, dict):
        return None

    return row


def rewrite_line_to_equals(line: str, selected_variable: str) -> str:
    match = IN_CLAUSE_PATTERN.match(line)
    if match is None:
        return line
    indent = match.group("indent")
    keyword = match.group("keyword")
    column = match.group("column")
    return f"{indent}{keyword} [{column}] = {selected_variable}"


def main() -> int:
    args = parse_args()

    input_path = Path(args.input_file)
    if not input_path.exists():
        raise SystemExit(f"Input file not found: {input_path}")

    sql_text = input_path.read_text(encoding="utf-8")
    lines = sql_text.splitlines()
    statements, cases = parse_cases(sql_text)
    if not cases:
        raise SystemExit("No EXPECTED_ROWS_JSON cases found; nothing to narrow.")

    prelude_sql = build_prelude_sql(statements, cases[0])
    inferred_database = args.database or parse_use_database(statements) or "RDB_MODERN"

    declare_entries = parse_declare_entries(collect_declare_lines(sql_text))
    resolved_declare_values = resolve_declare_values(declare_entries)

    sqlcmd_executable = require_sqlcmd(args.sqlcmd)
    client = SqlCmdClient(
        executable=sqlcmd_executable,
        server=args.server,
        database=inferred_database,
        user=args.user,
        password=args.password,
    )

    change_count = 0
    for case in cases:
        clause_candidates = parse_clause_candidates(case.query_sql, case.query_start_line)
        if not clause_candidates:
            continue

        single_row = find_single_case_row(client, prelude_sql, case.query_sql)
        if single_row is None:
            continue

        for clause in clause_candidates:
            if clause.line_index < 0 or clause.line_index >= len(lines):
                continue

            row_values_by_column = {str(name).lower(): value for name, value in single_row.items()}
            if clause.column.lower() not in row_values_by_column:
                continue
            resolved_value = row_values_by_column[clause.column.lower()]

            matching_variables = [
                name
                for name in clause.variable_names
                if name in resolved_declare_values and resolved_declare_values[name] == resolved_value
            ]
            if len(matching_variables) != 1:
                continue

            new_line = rewrite_line_to_equals(lines[clause.line_index], matching_variables[0])
            if new_line == lines[clause.line_index]:
                continue
            print(
                f"Case {case.case_index}: narrowed {clause.keyword} [{clause.column}] IN (...) to = {matching_variables[0]}"
            )
            lines[clause.line_index] = new_line
            change_count += 1

    if change_count == 0:
        print("No WHERE IN clauses were safely narrowed.")
        return 0

    output_text = "\n".join(lines) + "\n"
    output_path = Path(args.output_file) if args.output_file else input_path

    if args.dry_run:
        print(f"Dry run complete. Planned updates: {change_count}")
        print(f"No file written. Target path would be: {output_path}")
        return 0

    output_path.write_text(output_text, encoding="utf-8")
    print(f"Wrote narrowed SQL file: {output_path}")
    print(f"Updated WHERE IN predicates: {change_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
