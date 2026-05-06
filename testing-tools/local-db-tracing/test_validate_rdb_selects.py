from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import validate_rdb_selects
from tracing_models import SqlCmdError


class FakeSqlClient:
    def __init__(self, outputs: list[str | Exception]):
        self._outputs = outputs
        self.calls: list[str] = []

    def query(self, sql: str) -> str:
        self.calls.append(sql)
        response = self._outputs[len(self.calls) - 1]
        if isinstance(response, Exception):
            raise response
        return response


class ValidateRdbSelectsTest(unittest.TestCase):
    def test_parse_cases_and_prelude(self) -> None:
        sql_text = """
USE [RDB_MODERN];

DECLARE @id bigint = 1;

-- dbo.TableA | operations: insert
SELECT [id] FROM [dbo].[TableA] WHERE [id] = @id FOR JSON PATH;
-- EXPECTED_ROWS_JSON:
-- [{"id":1}]

-- dbo.TableB | operations: insert
SELECT [id] FROM [dbo].[TableB] WHERE [id] = @id FOR JSON PATH;
-- EXPECTED_ROWS_JSON:
-- [{"id":1}]
""".strip()

        statements, cases = validate_rdb_selects.parse_cases(sql_text)
        prelude = validate_rdb_selects.build_prelude_sql(statements, cases[0])

        self.assertEqual(len(cases), 2)
        self.assertEqual(cases[0].label, "dbo.TableA | operations: insert")
        self.assertEqual(cases[1].label, "dbo.TableB | operations: insert")
        self.assertEqual(cases[0].expected_json, [{"id": 1}])
        self.assertIn("USE [RDB_MODERN];", prelude)
        self.assertIn("DECLARE @id bigint = 1;", prelude)

    def test_compare_case_handles_sql_error_without_raising(self) -> None:
        case = validate_rdb_selects.SelectCase(
            case_index=1,
            label="dbo.Broken | operations: insert",
            query_sql="SELECT [id] FROM [dbo].[Broken] FOR JSON PATH;",
            query_start_line=10,
            expected_json=[{"id": 1}],
        )
        client = FakeSqlClient([SqlCmdError("Subquery returned more than 1 value")])

        result = validate_rdb_selects.compare_case(client, "USE [RDB_MODERN];", case)

        self.assertEqual(result["status"], "fail")
        self.assertIn("Subquery returned more than 1 value", str(result.get("error")))

    def test_compare_case_success_and_mismatch(self) -> None:
        case_one = validate_rdb_selects.SelectCase(
            case_index=1,
            label="pass-case",
            query_sql="SELECT [id] FROM [dbo].[T] FOR JSON PATH;",
            query_start_line=5,
            expected_json=[{"id": 1}],
        )
        case_two = validate_rdb_selects.SelectCase(
            case_index=2,
            label="fail-case",
            query_sql="SELECT [id] FROM [dbo].[T] FOR JSON PATH;",
            query_start_line=9,
            expected_json=[{"id": 2}],
        )
        client = FakeSqlClient([
            'JSON_F52E2B61-18A1-11d1-B105-00805F49916B\n[{"id":1}]\n',
            'JSON_F52E2B61-18A1-11d1-B105-00805F49916B\n[{"id":1}]\n',
        ])

        pass_result = validate_rdb_selects.compare_case(client, "USE [RDB_MODERN];", case_one)
        fail_result = validate_rdb_selects.compare_case(client, "USE [RDB_MODERN];", case_two)

        self.assertEqual(pass_result["status"], "pass")
        self.assertEqual(fail_result["status"], "fail")
        self.assertIn("does not match", str(fail_result.get("error")))

    def test_value_level_diff_highlighting(self) -> None:
        expected = [{"id": 1, "name": "Alice"}]
        actual = [{"id": 2, "name": "Alice"}]

        expected_mask, actual_mask = validate_rdb_selects.build_diff_masks(expected, actual)
        rendered_expected = validate_rdb_selects.render_json_with_mask(
            expected,
            expected_mask,
            use_color=True,
            diff_color=validate_rdb_selects.ANSI_YELLOW,
        )
        rendered_actual = validate_rdb_selects.render_json_with_mask(
            actual,
            actual_mask,
            use_color=True,
            diff_color=validate_rdb_selects.ANSI_RED,
        )

        self.assertIn(f'{validate_rdb_selects.ANSI_YELLOW}1{validate_rdb_selects.ANSI_RESET}', rendered_expected)
        self.assertIn(f'{validate_rdb_selects.ANSI_RED}2{validate_rdb_selects.ANSI_RESET}', rendered_actual)
        self.assertNotIn(f'{validate_rdb_selects.ANSI_YELLOW}"Alice"{validate_rdb_selects.ANSI_RESET}', rendered_expected)
        self.assertNotIn(f'{validate_rdb_selects.ANSI_RED}"Alice"{validate_rdb_selects.ANSI_RESET}', rendered_actual)

    def test_markdown_report_contains_error_style_and_spans(self) -> None:
        summary = {
            "case_count": 2,
            "pass_count": 1,
            "warning_count": 0,
            "fail_count": 1,
        }
        results = [
            {
                "case_index": 1,
                "label": "dbo.good | operations: insert",
                "query_start_line": 10,
                "status": "pass",
                "expected": [{"id": 1}],
                "actual": [{"id": 1}],
            },
            {
                "case_index": 2,
                "label": "dbo.bad | operations: insert",
                "query_start_line": 20,
                "status": "fail",
                "error": "Expected JSON does not match actual query result",
                "expected": [{"id": 2}],
                "actual": [{"id": 3}],
            },
        ]

        report = validate_rdb_selects.render_markdown_report(
            Path("input.sql"),
            Path("results.json"),
            Path("results.md"),
            summary,
            results,
        )

        self.assertIn("<style>", report)
        self.assertIn('.error {', report)
        self.assertIn('.warning {', report)
        self.assertIn('| <span class="ok">Passes</span> | 1 |', report)
        self.assertIn('| <span class="error">Fails</span> | 1 |', report)
        self.assertIn('<span class="error">FAIL</span>', report)
        self.assertIn('| Case | Status | Label |', report)
        self.assertNotIn('| Case | Status | Label | Line |', report)
        self.assertIn('dbo.good \\| operations: insert', report)
        self.assertIn('<a href="#case-2">dbo.bad \\| operations: insert</a>', report)
        self.assertIn('<a id="case-2"></a>', report)
        self.assertIn('| Field | Expected | Returned |', report)
        self.assertIn('<span class="error">2</span>', report)
        self.assertIn('## Details', report)
        self.assertNotIn('## Failure Details', report)
        self.assertIn('<span class="error">3</span>', report)

    def test_null_vs_empty_string_warning(self) -> None:
        case = validate_rdb_selects.SelectCase(
            case_index=1,
            label="null-vs-empty-case",
            query_sql="SELECT [id], [name] FROM [dbo].[T] FOR JSON PATH;",
            query_start_line=5,
            expected_json=[{"id": 1, "name": None}],
        )
        client = FakeSqlClient([
            'JSON_F52E2B61-18A1-11d1-B105-00805F49916B\n[{"id":1,"name":""}]\n',
        ])

        result = validate_rdb_selects.compare_case(client, "USE [RDB_MODERN];", case)

        self.assertEqual(result["status"], "warning")
        self.assertIn("null vs empty string", str(result.get("error")))

    def test_mixed_null_vs_empty_and_real_failure(self) -> None:
        case = validate_rdb_selects.SelectCase(
            case_index=1,
            label="mixed-case",
            query_sql="SELECT [id], [name], [age] FROM [dbo].[T] FOR JSON PATH;",
            query_start_line=5,
            expected_json=[{"id": 1, "name": None, "age": 30}],
        )
        client = FakeSqlClient([
            'JSON_F52E2B61-18A1-11d1-B105-00805F49916B\n[{"id":1,"name":"","age":25}]\n',
        ])

        result = validate_rdb_selects.compare_case(client, "USE [RDB_MODERN];", case)

        self.assertEqual(result["status"], "fail")
        self.assertIn("does not match", str(result.get("error")))

    def test_key_field_mismatch_is_warning(self) -> None:
        case = validate_rdb_selects.SelectCase(
            case_index=1,
            label="key-warning-case",
            query_sql="SELECT [id], [OBSERVATION_KEY] FROM [dbo].[T] FOR JSON PATH;",
            query_start_line=5,
            expected_json=[{"id": 1, "OBSERVATION_KEY": 123}],
        )
        client = FakeSqlClient([
            'JSON_F52E2B61-18A1-11d1-B105-00805F49916B\n[{"id":1,"OBSERVATION_KEY":999}]\n',
        ])

        result = validate_rdb_selects.compare_case(client, "USE [RDB_MODERN];", case)

        self.assertEqual(result["status"], "warning")
        self.assertIn("*_ID/*_UID/*_KEY", str(result.get("error")))

    def test_key_field_warning_plus_real_mismatch_is_fail(self) -> None:
        case = validate_rdb_selects.SelectCase(
            case_index=1,
            label="key-and-real-fail-case",
            query_sql="SELECT [id], [OBSERVATION_KEY], [name] FROM [dbo].[T] FOR JSON PATH;",
            query_start_line=5,
            expected_json=[{"id": 1, "OBSERVATION_KEY": 123, "name": "Alice"}],
        )
        client = FakeSqlClient([
            'JSON_F52E2B61-18A1-11d1-B105-00805F49916B\n[{"id":1,"OBSERVATION_KEY":999,"name":"Bob"}]\n',
        ])

        result = validate_rdb_selects.compare_case(client, "USE [RDB_MODERN];", case)

        self.assertEqual(result["status"], "fail")
        self.assertIn("does not match", str(result.get("error")))

    def test_markdown_report_details_includes_warnings_and_failures(self) -> None:
        summary = {
            "case_count": 3,
            "pass_count": 1,
            "warning_count": 1,
            "fail_count": 1,
        }
        results = [
            {
                "case_index": 1,
                "label": "dbo.good | operations: insert",
                "query_start_line": 10,
                "status": "pass",
                "expected": [{"id": 1}],
                "actual": [{"id": 1}],
            },
            {
                "case_index": 2,
                "label": "dbo.warning | operations: insert",
                "query_start_line": 15,
                "status": "warning",
                "error": "JSON matches except for null vs empty string differences",
                "expected": [{"id": 2, "name": None}],
                "actual": [{"id": 2, "name": ""}],
            },
            {
                "case_index": 3,
                "label": "dbo.bad | operations: insert",
                "query_start_line": 20,
                "status": "fail",
                "error": "Expected JSON does not match actual query result",
                "expected": [{"id": 3}],
                "actual": [{"id": 4}],
            },
        ]

        report = validate_rdb_selects.render_markdown_report(
            Path("input.sql"),
            Path("results.json"),
            Path("results.md"),
            summary,
            results,
        )

        self.assertIn("## Details", report)
        self.assertNotIn("## Failure Details", report)
        self.assertNotIn("## Warning Details", report)
        self.assertIn('<a id="case-2"></a>', report)
        self.assertIn('<a id="case-3"></a>', report)
        self.assertIn('<a href="#case-2">dbo.warning \\| operations: insert</a>', report)
        self.assertIn('<a href="#case-3">dbo.bad \\| operations: insert</a>', report)
        self.assertIn('<span class="warning">JSON matches except for null vs empty string differences</span>', report)
        self.assertIn('<span class="error">Expected JSON does not match actual query result</span>', report)


if __name__ == "__main__":
    unittest.main()