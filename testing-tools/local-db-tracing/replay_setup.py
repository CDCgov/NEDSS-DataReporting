from __future__ import annotations

import argparse
import os
import re
from pathlib import Path

from tracing_env import load_database_connection_defaults, resolve_server_argument
from tracing_constants import ALWAYS_REPLACE_COLUMN_NAMES, DO_NOT_REPLACE_COLUMNS_ANY_TABLE, DO_NOT_REPLACE_COLUMNS_BY_TABLE
from tracing_metadata import fetch_auto_datetime_columns, fetch_column_sql_types
from tracing_sql import SqlCmdClient, require_sqlcmd


USE_DATABASE_PATTERN = re.compile(r"^\s*USE\s+\[(?P<database>[^\]]+)\]\s*;\s*$", re.IGNORECASE | re.MULTILINE)
INSERT_PATTERN = re.compile(
    r"^(?P<prefix>\s*INSERT\s+INTO\s+\[(?P<schema>[^\]]+)\]\.\[(?P<table>[^\]]+)\]\s*)"
    r"\((?P<columns>.*?)\)(?P<between>.*?)\bVALUES\s*\((?P<values>.*)\)(?P<suffix>\s*;\s*)$",
    re.IGNORECASE | re.DOTALL,
)
UPDATE_PATTERN = re.compile(
    r"^(?P<prefix>\s*UPDATE\s+\[(?P<schema>[^\]]+)\]\.\[(?P<table>[^\]]+)\]\s+SET\s+)"
    r"(?P<assignments>.*?)(?P<suffix>\s+WHERE\s+.*;\s*)$",
    re.IGNORECASE | re.DOTALL,
)
ASSIGNMENT_PATTERN = re.compile(r"^\s*\[(?P<column>[^\]]+)\]\s*=\s*(?P<value>.+?)\s*$", re.DOTALL)
HARDCODED_DATE_LITERAL_PATTERN = re.compile(
    r"^N?'\d{4}-\d{2}-\d{2}(?:[T\s]\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?)?'$",
    re.IGNORECASE,
)

DATABASE_ENV_KEYS = ("DATABASE_NAME", "DB_ODSE", "ODSE_DATABASE")
AUTO_DATETIME_MODE_CHOICES = {"current", "preserve"}

# Matches UID DECLARE lines like: DECLARE @dbo_Entity_entity_uid bigint = 14217;
# Only matches @dbo_-prefixed variables; does NOT match @superuser_id or nvarchar local-id derivations.
UID_DECLARE_PATTERN = re.compile(
    r"^(?P<indent>\s*)DECLARE\s+(?P<name>@dbo_[A-Za-z0-9_]+)\s+bigint\s*=\s*(?P<value>-?\d+)\s*;\s*$",
    re.IGNORECASE,
)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    defaults = load_database_connection_defaults()

    parser = argparse.ArgumentParser(
        description="Run a setup.sql against ODSE, optionally rewriting auto-populated datetime/date literals."
    )
    parser.add_argument("--setup-sql", required=True, help="Path to the setup.sql file to execute")
    parser.add_argument(
        "--auto-datetime-mode",
        choices=sorted(AUTO_DATETIME_MODE_CHOICES),
        help="Choose 'current' to rewrite eligible hardcoded inserted timestamps/dates or 'preserve' to leave the SQL unchanged",
    )
    parser.add_argument(
        "--server",
        default=resolve_server_argument(defaults),
        help="SQL Server host and port; defaults to DATABASE_SERVER and DATABASE_PORT from .env",
    )
    parser.add_argument(
        "--database",
        help="Target database; defaults to --database, then USE [database] in the script, then DATABASE_NAME/DB_ODSE/ODSE_DATABASE, then NBS_ODSE",
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
        "--debug",
        action="store_true",
        help="Print the SQL that would be executed to stdout without writing to the database",
    )
    return parser.parse_args(argv)


def prompt_auto_datetime_mode() -> str:
    while True:
        response = input("Rewrite eligible inserted timestamps/dates to CURRENT_TIMESTAMP? [y/n]: ").strip().lower()
        if response in {"y", "yes"}:
            return "current"
        if response in {"n", "no"}:
            return "preserve"
        print("Please enter y or n.")


def prompt_starting_id() -> int | None:
    """Ask the user for a starting UID. Returns None if they press Enter without input."""
    response = input("Starting UID for renumbering (press Enter to keep existing IDs): ").strip()
    if not response:
        return None
    try:
        return int(response)
    except ValueError:
        print(f"Invalid integer '{response}', keeping existing IDs.")
        return None


def rewrite_uid_declarations(sql_text: str, starting_id: int) -> tuple[str, int]:
    """Renumber all bigint UID DECLARE lines sequentially from starting_id."""
    lines = sql_text.splitlines(keepends=True)
    counter = starting_id
    rewrites = 0
    result: list[str] = []
    for line in lines:
        match = UID_DECLARE_PATTERN.match(line.rstrip("\n").rstrip("\r"))
        if match:
            new_line = f"{match.group('indent')}DECLARE {match.group('name')} bigint = {counter};\n"
            counter += 1
            rewrites += 1
            result.append(new_line)
        else:
            result.append(line)
    return "".join(result), rewrites


def split_top_level_csv(text: str) -> list[str]:
    parts: list[str] = []
    current: list[str] = []
    depth = 0
    in_string = False
    index = 0
    while index < len(text):
        char = text[index]
        if char == "'":
            current.append(char)
            if in_string and index + 1 < len(text) and text[index + 1] == "'":
                current.append(text[index + 1])
                index += 2
                continue
            in_string = not in_string
            index += 1
            continue
        if not in_string:
            if char == "(":
                depth += 1
            elif char == ")" and depth > 0:
                depth -= 1
            elif char == "," and depth == 0:
                parts.append("".join(current).strip())
                current = []
                index += 1
                continue
        current.append(char)
        index += 1

    tail = "".join(current).strip()
    if tail:
        parts.append(tail)
    return parts


def normalize_column_name(column_token: str) -> str:
    stripped = column_token.strip()
    if stripped.startswith("[") and stripped.endswith("]"):
        return stripped[1:-1]
    return stripped


def value_has_midnight_time(value_token: str) -> bool:
    """Check if a date/datetime literal has a midnight time component (00:00:00)."""
    stripped = value_token.strip()
    # Remove quotes and N prefix if present
    if stripped.startswith("N'"):
        stripped = stripped[2:-1]
    elif stripped.startswith("'"):
        stripped = stripped[1:-1]
    else:
        return False
    
    # Check for time component: T or space followed by 00:00:00
    if 'T' in stripped:
        # Format: 2026-04-23T00:00:00 or 2026-04-23T00:00:00.000
        parts = stripped.split('T')
        if len(parts) == 2 and parts[1].startswith('00:00:00'):
            return True
    elif ' ' in stripped:
        # Format: 2026-04-23 00:00:00 or 2026-04-23 00:00:00.000
        parts = stripped.split(' ')
        if len(parts) == 2 and parts[1].startswith('00:00:00'):
            return True
    
    return False


def replacement_expression(sql_type: str, has_midnight_time: bool = False) -> str:
    sql_current_date = "CAST(CURRENT_TIMESTAMP AS date)"
    lowered = sql_type.lower()
    if lowered == "date":
        return sql_current_date
    if lowered == "time":
        return "CAST(CURRENT_TIMESTAMP AS time)"
    if lowered.startswith("datetimeoffset"):
        if has_midnight_time:
            return f"CAST({sql_current_date} AS datetimeoffset)"
        return "CAST(CURRENT_TIMESTAMP AS datetimeoffset)"
    if lowered.startswith("datetime2"):
        if has_midnight_time:
            return f"CAST({sql_current_date} AS datetime2)"
        return "CAST(CURRENT_TIMESTAMP AS datetime2)"
    if lowered.startswith("smalldatetime"):
        if has_midnight_time:
            return f"CAST({sql_current_date} AS smalldatetime)"
        return "CAST(CURRENT_TIMESTAMP AS smalldatetime)"
    if has_midnight_time:
        return sql_current_date
    return "CURRENT_TIMESTAMP"


def should_replace_literal(value_token: str) -> bool:
    return bool(HARDCODED_DATE_LITERAL_PATTERN.match(value_token.strip()))


def should_exclude_from_replacement(schema_name: str, table_name: str, column_name: str) -> bool:
    """Check if a column should be excluded from datetime replacement.
    
    Returns True if the column matches either a table-specific or table-agnostic exclusion.
    """
    # Check table-specific exclusion
    if (schema_name, table_name, column_name) in DO_NOT_REPLACE_COLUMNS_BY_TABLE:
        return True
    # Check generic column name exclusion (applies to all tables)
    if column_name in DO_NOT_REPLACE_COLUMNS_ANY_TABLE:
        return True
    return False


def rewrite_insert_statement(
    statement: str,
    eligible_columns: set[tuple[str, str, str]],
    column_types: dict[tuple[str, str, str], str],
) -> tuple[str, int]:
    match = INSERT_PATTERN.match(statement)
    if not match:
        return statement, 0

    schema_name = match.group("schema")
    table_name = match.group("table")
    columns = split_top_level_csv(match.group("columns"))
    values = split_top_level_csv(match.group("values"))
    if len(columns) != len(values):
        return statement, 0

    replacements = 0
    rewritten_values: list[str] = []
    for column_token, value_token in zip(columns, values):
        column_name = normalize_column_name(column_token)
        column_key = (schema_name, table_name, column_name)
        rewritten_value = value_token
        if (column_key in eligible_columns or column_name in ALWAYS_REPLACE_COLUMN_NAMES) and not should_exclude_from_replacement(schema_name, table_name, column_name) and should_replace_literal(value_token):
            sql_type = column_types.get(column_key, "datetime")
            has_midnight = value_has_midnight_time(value_token)
            rewritten_value = replacement_expression(sql_type, has_midnight)
            replacements += 1
        rewritten_values.append(rewritten_value)

    if replacements == 0:
        return statement, 0

    rebuilt = (
        f"{match.group('prefix')}({match.group('columns')})"
        f"{match.group('between')}VALUES ({', '.join(rewritten_values)}){match.group('suffix')}"
    )
    return rebuilt, replacements


def rewrite_update_statement(
    statement: str,
    eligible_columns: set[tuple[str, str, str]],
    column_types: dict[tuple[str, str, str], str],
) -> tuple[str, int]:
    match = UPDATE_PATTERN.match(statement)
    if not match:
        return statement, 0

    schema_name = match.group("schema")
    table_name = match.group("table")
    assignments = split_top_level_csv(match.group("assignments"))
    replacements = 0
    rewritten_assignments: list[str] = []

    for assignment in assignments:
        assignment_match = ASSIGNMENT_PATTERN.match(assignment)
        if not assignment_match:
            rewritten_assignments.append(assignment)
            continue

        column_name = assignment_match.group("column")
        value_token = assignment_match.group("value")
        column_key = (schema_name, table_name, column_name)
        rewritten_assignment = assignment
        if (column_key in eligible_columns or column_name in ALWAYS_REPLACE_COLUMN_NAMES) and not should_exclude_from_replacement(schema_name, table_name, column_name) and should_replace_literal(value_token):
            sql_type = column_types.get(column_key, "datetime")
            has_midnight = value_has_midnight_time(value_token)
            rewritten_assignment = f"[{column_name}] = {replacement_expression(sql_type, has_midnight)}"
            replacements += 1
        rewritten_assignments.append(rewritten_assignment)

    if replacements == 0:
        return statement, 0

    rebuilt = f"{match.group('prefix')}{', '.join(rewritten_assignments)}{match.group('suffix')}"
    return rebuilt, replacements


def rewrite_setup_sql(
    sql_text: str,
    eligible_columns: set[tuple[str, str, str]],
    column_types: dict[tuple[str, str, str], str],
) -> tuple[str, int]:
    rewritten_lines: list[str] = []
    replacements = 0
    for line in sql_text.splitlines():
        updated_line, line_replacements = rewrite_insert_statement(line, eligible_columns, column_types)
        if line_replacements == 0:
            updated_line, line_replacements = rewrite_update_statement(line, eligible_columns, column_types)
        rewritten_lines.append(updated_line)
        replacements += line_replacements
    rewritten_sql = "\n".join(rewritten_lines)
    if sql_text.endswith("\n"):
        rewritten_sql += "\n"
    return rewritten_sql, replacements


def resolve_database_name(explicit_database: str | None, defaults: dict[str, str], sql_text: str) -> str:
    if explicit_database:
        return explicit_database

    match = USE_DATABASE_PATTERN.search(sql_text)
    if match:
        return match.group("database")

    for key in DATABASE_ENV_KEYS:
        value = defaults.get(key) or os.environ.get(key)
        if value:
            return value

    return "NBS_ODSE"


def execute_setup_sql(args: argparse.Namespace) -> int:
    defaults = load_database_connection_defaults()
    setup_path = Path(args.setup_sql).expanduser().resolve()
    if not setup_path.is_file():
        raise SystemExit(f"setup.sql file not found: {setup_path}")

    mode = args.auto_datetime_mode or prompt_auto_datetime_mode()
    starting_id = prompt_starting_id()
    sql_text = setup_path.read_text(encoding="utf-8")
    database = resolve_database_name(args.database, defaults, sql_text)

    if starting_id is not None:
        sql_text, uid_rewrites = rewrite_uid_declarations(sql_text, starting_id)
    else:
        uid_rewrites = 0

    if args.debug:
        sql_to_run = sql_text
        replacement_count = 0
        if mode == "current":
            executable = require_sqlcmd(args.sqlcmd)
            client = SqlCmdClient(executable, args.server, database, args.user or "", args.password or "")
            eligible_columns = fetch_auto_datetime_columns(client)
            column_types = fetch_column_sql_types(client)
            sql_to_run, replacement_count = rewrite_setup_sql(sql_text, eligible_columns, column_types)
        print(f"-- DEBUG: would execute against database '{database}' (auto-datetime mode '{mode}')")
        if uid_rewrites:
            print(f"-- DEBUG: {uid_rewrites} UID declaration(s) renumbered starting from {starting_id}")
        if mode == "current":
            print(f"-- DEBUG: {replacement_count} eligible hardcoded datetime/date literal(s) would be replaced")
        print(sql_to_run, end="")
        return 0

    if not args.user:
        raise SystemExit("--user is required unless DATABASE_USERNAME is set in .env or the environment")
    if not args.password:
        raise SystemExit("--password is required unless DATABASE_PASSWORD is set in .env or the environment")

    executable = require_sqlcmd(args.sqlcmd)
    client = SqlCmdClient(executable, args.server, database, args.user, args.password)

    sql_to_run = sql_text
    replacement_count = 0
    if mode == "current":
        eligible_columns = fetch_auto_datetime_columns(client)
        column_types = fetch_column_sql_types(client)
        sql_to_run, replacement_count = rewrite_setup_sql(sql_text, eligible_columns, column_types)

    client.query(sql_to_run, database=database)
    print(f"Executed {setup_path} against {database} using auto-datetime mode '{mode}'.")
    if uid_rewrites:
        print(f"Renumbered {uid_rewrites} UID declaration(s) starting from {starting_id}.")
    if mode == "current":
        print(f"Replaced {replacement_count} eligible hardcoded datetime/date literal(s).")
    return 0


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    return execute_setup_sql(args)


if __name__ == "__main__":
    raise SystemExit(main())