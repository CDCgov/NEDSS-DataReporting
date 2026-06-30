"""Apply the rule registry to raw comparison results.

The engine produces :class:`~rdb_compare.models.TableResult` objects with raw,
unclassified :class:`~rdb_compare.models.ColumnDiff` entries. :func:`classify_run`
walks the results and attaches a :class:`~rdb_compare.models.Classification` to
each column difference (and a table-level note for skipped tables), without
mutating the comparison logic itself -- classification is a separate, pure pass
so the known-differences knowledge stays in the rule catalog.
"""

from __future__ import annotations

from rdb_compare.models import Classification, RunReport, TableResult, Verdict
from rdb_compare.rules import RuleRegistry


def classify_table_result(result: TableResult, registry: RuleRegistry) -> TableResult:
    """Attach classifications to a single table result (in place) and return it."""
    table_cls = registry.classify_table(result.table)
    if table_cls is not None:
        result.skipped = True
        result.skip_reason = table_cls.reason
        result.classification = table_cls
        return result

    for col in result.columns:
        col.classification = registry.classify_column(
            result.table, col.column, col.samples
        )
    return result


def classify_run(report: RunReport, registry: RuleRegistry) -> RunReport:
    """Classify every table result in a run (in place) and return the report."""
    for result in report.tables:
        classify_table_result(result, registry)
    return report


def summarize(report: RunReport) -> dict:
    """Roll up verdict counts across all classified column differences."""
    counts = {v.value: 0 for v in Verdict}
    actionable_tables = 0
    for t in report.tables:
        if t.skipped:
            # Skipped tables carry only a table-level IGNORED classification;
            # their (typically absent) columns must not roll up as NEW.
            counts[Verdict.IGNORED.value] += 1
            continue
        has_new = False
        for c in t.columns:
            cls = c.classification or Classification(Verdict.NEW)
            counts[cls.verdict.value] += 1
            if cls.verdict == Verdict.NEW:
                has_new = True
        if has_new:
            actionable_tables += 1
    return {
        "verdict_counts": counts,
        "actionable_tables": actionable_tables,
        "tables_compared": report.compared,
        "tables_skipped": report.skipped,
        "tables_discovered": report.discovered,
    }
