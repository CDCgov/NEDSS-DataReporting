"""Execute generated rdb-selects.sql queries and compare each result to EXPECTED_ROWS_JSON."""

from __future__ import annotations

import argparse
import html
import json
import os
import re
from dataclasses import dataclass
from pathlib import Path

from tracing_env import load_database_connection_defaults, resolve_server_argument
from tracing_models import SqlCmdError
from tracing_sql import SqlCmdClient, require_sqlcmd


USE_DATABASE_PATTERN = re.compile(r"^\s*USE\s+\[(?P<database>[^\]]+)\]\s*;\s*$", re.IGNORECASE)
EXPECTED_MARKER = "-- EXPECTED_ROWS_JSON:"
JSON_HEADER_PREFIX = "JSON_F52E2B61"

ANSI_RESET = "\x1b[0m"
ANSI_RED = "\x1b[31m"
ANSI_GREEN = "\x1b[32m"
ANSI_YELLOW = "\x1b[33m"


@dataclass(frozen=True)
class SqlStatement:
    sql: str
    start_line: int
    end_line: int


@dataclass(frozen=True)
class SelectCase:
    case_index: int
    label: str
    query_sql: str
    query_start_line: int
    expected_json: object


def parse_args() -> argparse.Namespace:
    defaults = load_database_connection_defaults()

    parser = argparse.ArgumentParser(
        description="Run each SELECT in rdb-selects.sql and compare against EXPECTED_ROWS_JSON comments."
    )
    parser.add_argument("--input-file", required=True, help="Path to rdb-selects.sql")
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
        "--output-file",
        help="Where to write validator JSON results; defaults next to the input as rdb-selects-results.json",
    )
    parser.add_argument(
        "--markdown-output-file",
        help="Where to write validator Markdown results; defaults to the JSON output path with .md extension",
    )
    parser.add_argument(
        "--no-color",
        action="store_true",
        help="Disable colored CLI output",
    )
    args = parser.parse_args()

    if not args.user:
        parser.error("--user is required unless DATABASE_USERNAME is set in .env or the environment")
    if not args.password:
        parser.error("--password is required unless DATABASE_PASSWORD is set in .env or the environment")
    return args


def split_sql_statements(sql_text: str) -> list[SqlStatement]:
    statements: list[SqlStatement] = []
    current_lines: list[str] = []
    start_line: int | None = None

    for line_number, line in enumerate(sql_text.splitlines(), start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith("--"):
            continue

        if start_line is None:
            start_line = line_number
        current_lines.append(line)

        if stripped.endswith(";"):
            statements.append(
                SqlStatement(
                    sql="\n".join(current_lines),
                    start_line=start_line,
                    end_line=line_number,
                )
            )
            current_lines = []
            start_line = None

    return statements


def collect_expected_json(lines: list[str], marker_line_index: int) -> tuple[object, int]:
    json_lines: list[str] = []
    cursor = marker_line_index + 1
    while cursor < len(lines):
        line = lines[cursor]
        stripped = line.strip()
        if not stripped.startswith("--"):
            break
        payload = stripped[2:].lstrip()
        if payload:
            json_lines.append(payload)
        cursor += 1

    json_text = "".join(json_lines).strip()
    if not json_text:
        raise ValueError(f"Missing expected JSON payload after marker on line {marker_line_index + 1}")
    try:
        return json.loads(json_text), cursor
    except json.JSONDecodeError as error:
        raise ValueError(f"Expected JSON is invalid near line {marker_line_index + 1}: {error}") from error


def infer_case_label(lines: list[str], query_start_line: int, marker_line_index: int, case_index: int) -> str:
    for line_index in range(marker_line_index - 1, -1, -1):
        stripped = lines[line_index].strip()
        if line_index + 1 < query_start_line:
            if stripped and not stripped.startswith("--"):
                break
        if stripped.startswith("--") and "| operations:" in stripped:
            return stripped[2:].strip()
    return f"case-{case_index}"


def find_statement_before_line(statements: list[SqlStatement], marker_line_number: int) -> SqlStatement:
    candidates = [statement for statement in statements if statement.end_line < marker_line_number]
    if not candidates:
        raise ValueError(f"Could not find a SQL statement before EXPECTED_ROWS_JSON at line {marker_line_number}")
    return candidates[-1]


def parse_use_database(statements: list[SqlStatement]) -> str | None:
    for statement in statements:
        match = USE_DATABASE_PATTERN.match(statement.sql.strip())
        if match:
            return match.group("database")
    return None


def parse_cases(sql_text: str) -> tuple[list[SqlStatement], list[SelectCase]]:
    lines = sql_text.splitlines()
    statements = split_sql_statements(sql_text)
    cases: list[SelectCase] = []

    for index, line in enumerate(lines):
        if line.strip() != EXPECTED_MARKER:
            continue

        marker_line_number = index + 1
        query_statement = find_statement_before_line(statements, marker_line_number)
        expected_json, _ = collect_expected_json(lines, index)
        case_index = len(cases) + 1
        cases.append(
            SelectCase(
                case_index=case_index,
                label=infer_case_label(lines, query_statement.start_line, index, case_index),
                query_sql=query_statement.sql,
                query_start_line=query_statement.start_line,
                expected_json=expected_json,
            )
        )

    if not cases:
        raise ValueError("No EXPECTED_ROWS_JSON markers were found in this SQL file")
    return statements, cases


def build_prelude_sql(statements: list[SqlStatement], first_case: SelectCase) -> str:
    prelude = [statement.sql for statement in statements if statement.end_line < first_case.query_start_line]
    return "\n\n".join(prelude)


def clean_sqlcmd_output(raw_output: str) -> str:
    cleaned_lines: list[str] = []
    for raw_line in raw_output.splitlines():
        stripped = raw_line.strip()
        if not stripped:
            continue
        if stripped.startswith(JSON_HEADER_PREFIX):
            continue
        if stripped.endswith("rows affected)") or stripped.endswith("row affected)"):
            continue
        if set(stripped) <= {"-", " ", "\t"}:
            continue
        cleaned_lines.append(stripped)
    return "".join(cleaned_lines)


def parse_actual_json(raw_output: str) -> object:
    cleaned = clean_sqlcmd_output(raw_output)
    if not cleaned:
        raise ValueError("SQL query returned empty output")
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        start = cleaned.find("[")
        end = cleaned.rfind("]")
        if start == -1 or end == -1 or end <= start:
            raise ValueError(f"Could not parse SQL output as JSON: {cleaned[:200]}")
        try:
            return json.loads(cleaned[start : end + 1])
        except json.JSONDecodeError as error:
            raise ValueError(f"Could not parse SQL output as JSON: {error}") from error


def default_output_path(input_file: Path) -> Path:
    return input_file.resolve().parent / "rdb-selects-results.json"


def default_markdown_output_path(output_file: Path) -> Path:
    return output_file.with_suffix(".md")


def status_span(status: str) -> str:
    if status == "pass":
        return '<span class="ok">PASS</span>'
    return '<span class="error">FAIL</span>'


def markdown_table_cell(value: object) -> str:
    text = str(value)
    text = text.replace("\\", "\\\\")
    text = text.replace("|", "\\|")
    text = text.replace("\n", " ")
    return text


def flatten_json_fields(value: object, prefix: str = "") -> dict[str, object]:
    if isinstance(value, dict):
        flattened: dict[str, object] = {}
        for key in sorted(value.keys()):
            child_prefix = f"{prefix}.{key}" if prefix else key
            flattened.update(flatten_json_fields(value[key], child_prefix))
        return flattened

    if isinstance(value, list):
        flattened_list: dict[str, object] = {}
        for index, item in enumerate(value):
            child_prefix = f"{prefix}[{index}]" if prefix else f"[{index}]"
            flattened_list.update(flatten_json_fields(item, child_prefix))
        if not value:
            return {prefix or "$": []}
        return flattened_list

    return {prefix or "$": value}


def value_for_table(value: object) -> str:
    if value is None:
        return "null"
    if isinstance(value, (str, int, float, bool)):
        return json.dumps(value, sort_keys=True)
    return json.dumps(value, sort_keys=True)


def comparison_cell(value: object | None, differs: bool) -> str:
    text = html.escape(value_for_table(value)) if value is not None else "<em>missing</em>"
    text = markdown_table_cell(text)
    if differs:
        return f'<span class="error">{text}</span>'
    return text


def render_field_comparison_table(expected: object, actual: object) -> list[str]:
    expected_fields = flatten_json_fields(expected)
    actual_fields = flatten_json_fields(actual)
    field_names = sorted(set(expected_fields.keys()) | set(actual_fields.keys()))

    lines = [
        "| Field | Expected | Returned |",
        "| --- | --- | --- |",
    ]

    for field_name in field_names:
        expected_value = expected_fields.get(field_name)
        actual_value = actual_fields.get(field_name)
        differs = expected_value != actual_value
        safe_field = markdown_table_cell(field_name)
        expected_cell = comparison_cell(expected_value, differs)
        actual_cell = comparison_cell(actual_value, differs)
        lines.append(f"| {safe_field} | {expected_cell} | {actual_cell} |")

    return lines


def render_markdown_report(
    input_file: Path,
    output_file: Path,
    markdown_output_file: Path,
    summary: dict[str, object],
    results: list[dict[str, object]],
) -> str:
    lines: list[str] = [
        "# RDB Select Validation Results",
        "",
        f"Input file: {input_file}",
        f"JSON results: {output_file}",
        "",
        "<style>",
        "    .error {",
        "        color: red;",
        "    }",
        "    .ok {",
        "        color: green;",
        "    }",
        "</style>",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "| --- | --- |",
        f"| Cases | {summary['case_count']} |",
        f"| Passes | {summary['pass_count']} |",
        f"| <span class=\"error\">Fails</span> | {summary['fail_count']} |",
        "",
        "## Case Results",
        "",
        "| Case | Status | Label |",
        "| --- | --- | --- |",
    ]

    for result in results:
        case_index = result["case_index"]
        raw_label = html.escape(str(result["label"]))
        if result["status"] == "fail":
            label = f"<a href=\"#case-{case_index}\">{raw_label}</a>"
        else:
            label = raw_label
        lines.append(f"| {case_index} | {status_span(str(result['status']))} | {markdown_table_cell(label)} |")

    failing_results = [result for result in results if result["status"] == "fail"]
    if failing_results:
        lines.extend(["", "## Failure Details", ""])
        for result in failing_results:
            lines.append(f"<a id=\"case-{result['case_index']}\"></a>")
            lines.append(f"### Case {result['case_index']}: {html.escape(str(result['label']))}")
            lines.append("")
            if result.get("error"):
                lines.append(f"Error: <span class=\"error\">{html.escape(str(result['error']))}</span>")
                lines.append("")
            if result.get("actual") is not None:
                lines.extend(render_field_comparison_table(result.get("expected"), result.get("actual")))
            else:
                lines.append("| Field | Expected | Returned |")
                lines.append("| --- | --- | --- |")
                lines.append("| query_error | <span class=\"error\">(query did not return JSON)</span> | <span class=\"error\">missing</span> |")
            lines.append("")

    lines.append(f"Report file: {markdown_output_file}")
    lines.append("")
    return "\n".join(lines)


def colors_enabled(no_color_flag: bool) -> bool:
    if no_color_flag:
        return False
    if os.environ.get("NO_COLOR"):
        return False
    return True


def colorize(text: str, color: str, use_color: bool) -> str:
    if not use_color:
        return text
    return f"{color}{text}{ANSI_RESET}"


def build_diff_masks(expected: object, actual: object) -> tuple[object, object]:
    if isinstance(expected, dict) and isinstance(actual, dict):
        expected_mask: dict[str, object] = {}
        actual_mask: dict[str, object] = {}
        for key in sorted(set(expected.keys()) | set(actual.keys())):
            in_expected = key in expected
            in_actual = key in actual
            if in_expected and in_actual:
                child_expected_mask, child_actual_mask = build_diff_masks(expected[key], actual[key])
                if child_expected_mask not in (False, {}, []):
                    expected_mask[key] = child_expected_mask
                if child_actual_mask not in (False, {}, []):
                    actual_mask[key] = child_actual_mask
            elif in_expected:
                expected_mask[key] = True
            else:
                actual_mask[key] = True
        return expected_mask, actual_mask

    if isinstance(expected, list) and isinstance(actual, list):
        expected_mask_list: list[object] = []
        actual_mask_list: list[object] = []
        max_len = max(len(expected), len(actual))
        for index in range(max_len):
            in_expected = index < len(expected)
            in_actual = index < len(actual)
            if in_expected and in_actual:
                child_expected_mask, child_actual_mask = build_diff_masks(expected[index], actual[index])
                expected_mask_list.append(child_expected_mask)
                actual_mask_list.append(child_actual_mask)
            elif in_expected:
                expected_mask_list.append(True)
            else:
                actual_mask_list.append(True)
        return expected_mask_list, actual_mask_list

    if expected == actual:
        return False, False
    return True, True


def render_json_with_mask(value: object, mask: object, use_color: bool, diff_color: str, indent: int = 0) -> str:
    if mask is True:
        return colorize(json.dumps(value, sort_keys=True), diff_color, use_color)

    if isinstance(value, dict):
        keys = sorted(value.keys())
        if not keys:
            return "{}"

        lines: list[str] = ["{"]
        for index, key in enumerate(keys):
            child_mask: object = False
            if isinstance(mask, dict):
                child_mask = mask.get(key, False)
            rendered_value = render_json_with_mask(value[key], child_mask, use_color, diff_color, indent + 2)
            suffix = "," if index < len(keys) - 1 else ""
            lines.append(f"{' ' * (indent + 2)}{json.dumps(key)}: {rendered_value}{suffix}")
        lines.append(f"{' ' * indent}}}")
        return "\n".join(lines)

    if isinstance(value, list):
        if not value:
            return "[]"
        lines = ["["]
        for index, item in enumerate(value):
            child_mask = False
            if isinstance(mask, list) and index < len(mask):
                child_mask = mask[index]
            rendered_item = render_json_with_mask(item, child_mask, use_color, diff_color, indent + 2)
            suffix = "," if index < len(value) - 1 else ""
            lines.append(f"{' ' * (indent + 2)}{rendered_item}{suffix}")
        lines.append(f"{' ' * indent}]")
        return "\n".join(lines)

    return json.dumps(value, sort_keys=True)


def compare_case(client: SqlCmdClient, prelude_sql: str, case: SelectCase) -> dict[str, object]:
    sql_batch_parts = ["SET NOCOUNT ON;"]
    if prelude_sql.strip():
        sql_batch_parts.append(prelude_sql)
    sql_batch_parts.append(case.query_sql)
    sql_batch = "\n\n".join(sql_batch_parts)

    try:
        raw_output = client.query(sql_batch)
        actual_json = parse_actual_json(raw_output)
        passed = actual_json == case.expected_json
        result: dict[str, object] = {
            "case_index": case.case_index,
            "label": case.label,
            "query_start_line": case.query_start_line,
            "status": "pass" if passed else "fail",
            "expected": case.expected_json,
            "actual": actual_json,
        }
        if not passed:
            result["error"] = "Expected JSON does not match actual query result"
        return result
    except SqlCmdError as error:
        return {
            "case_index": case.case_index,
            "label": case.label,
            "query_start_line": case.query_start_line,
            "status": "fail",
            "error": str(error),
            "expected": case.expected_json,
        }
    except ValueError as error:
        return {
            "case_index": case.case_index,
            "label": case.label,
            "query_start_line": case.query_start_line,
            "status": "fail",
            "error": str(error),
            "expected": case.expected_json,
        }


def main() -> int:
    args = parse_args()
    input_file = Path(args.input_file)
    if not input_file.exists():
        raise SystemExit(f"Input file not found: {input_file}")

    sql_text = input_file.read_text(encoding="utf-8")
    statements, cases = parse_cases(sql_text)
    inferred_database = parse_use_database(statements)
    database = args.database or inferred_database
    if not database:
        raise SystemExit("Could not determine database from SQL file. Pass --database explicitly.")

    output_file = Path(args.output_file) if args.output_file else default_output_path(input_file)
    markdown_output_file = (
        Path(args.markdown_output_file)
        if args.markdown_output_file
        else default_markdown_output_path(output_file)
    )
    executable = require_sqlcmd(args.sqlcmd)
    client = SqlCmdClient(executable, args.server, database, args.user, args.password)
    prelude_sql = build_prelude_sql(statements, cases[0])
    use_color = colors_enabled(args.no_color)

    print(f"Input file: {input_file}")
    print(f"Server: {args.server}")
    print(f"Database: {database}")
    print(f"Discovered cases: {len(cases)}")

    case_results: list[dict[str, object]] = []
    for case in cases:
        result = compare_case(client, prelude_sql, case)
        case_results.append(result)
        status = str(result["status"]).upper()
        status_color = ANSI_GREEN if status == "PASS" else ANSI_RED
        print(colorize(f"[{status}] Case {case.case_index}: {case.label} (line {case.query_start_line})", status_color, use_color))
        if result.get("error"):
            print(f"        {result['error']}")
        if result["status"] == "fail" and result.get("actual") is not None:
            expected_mask, actual_mask = build_diff_masks(result["expected"], result["actual"])
            print("        Expected:")
            print(render_json_with_mask(result["expected"], expected_mask, use_color, ANSI_YELLOW))
            print("        Actual:")
            print(render_json_with_mask(result["actual"], actual_mask, use_color, ANSI_RED))
        print()

    pass_count = sum(1 for result in case_results if result["status"] == "pass")
    fail_count = len(case_results) - pass_count
    summary: dict[str, object] = {
        "input_file": str(input_file),
        "server": args.server,
        "database": database,
        "case_count": len(case_results),
        "pass_count": pass_count,
        "fail_count": fail_count,
    }
    payload = {"summary": summary, "results": case_results}
    output_file.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    markdown_report = render_markdown_report(input_file, output_file, markdown_output_file, summary, case_results)
    markdown_output_file.write_text(markdown_report, encoding="utf-8")

    print(colorize(f"Pass: {pass_count}", ANSI_GREEN, use_color))
    print(colorize(f"Fail: {fail_count}", ANSI_RED if fail_count else ANSI_GREEN, use_color))
    print(f"Results written to: {output_file}")
    print(f"Markdown report written to: {markdown_output_file}")
    return 0 if fail_count == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())