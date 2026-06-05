"""Render a classified :class:`~rdb_compare.models.RunReport` to JSON and Markdown.

This is the *report* layer (see :mod:`rdb_compare.models` for the contract): the
engine produces raw :class:`~rdb_compare.models.TableResult` objects, the
classifier annotates each finding with a :class:`~rdb_compare.models.Classification`,
and this module turns the annotated run into deliverables -- a fully
JSON-serializable dict (for machines/diffing) and a human-readable Markdown
report that leads with the differences a person actually needs to look at (NEW),
then known bugs, then expected, then the structurally-uninteresting tail.

Nothing here mutates the report; rendering is a pure read-only pass.
"""

from __future__ import annotations

import json
from typing import Any, Optional

from rdb_compare.classifier import summarize
from rdb_compare.models import (
    Classification,
    ColumnDiff,
    RunReport,
    TableResult,
    Verdict,
)

# Verdict ordering used to surface the actionable findings first.
_VERDICT_ORDER = {
    Verdict.NEW: 0,
    Verdict.KNOWN_BUG: 1,
    Verdict.EXPECTED: 2,
    Verdict.IGNORED: 3,
}

# How many cell samples to inline per column in the Markdown report.
_MAX_INLINE_SAMPLES = 3
# Truncate long sample values so the Markdown table stays readable.
_MAX_VALUE_LEN = 40


# --- helpers ------------------------------------------------------------


def _verdict_of(col: ColumnDiff) -> Verdict:
    """The verdict for a column, treating an unclassified column as NEW."""
    return col.classification.verdict if col.classification else Verdict.NEW


def _ordered_columns(table: TableResult) -> list:
    """Columns ordered NEW-first, then known-bug/expected/ignored, then by name."""
    return sorted(
        table.columns,
        key=lambda c: (_VERDICT_ORDER.get(_verdict_of(c), 99), c.column),
    )


def _trunc(value: Any) -> str:
    """Render a cell value as a short, single-line string for inline samples."""
    if value is None:
        return "NULL"
    text = str(value).replace("\n", " ").replace("\r", " ")
    if len(text) > _MAX_VALUE_LEN:
        return text[: _MAX_VALUE_LEN - 1] + "…"
    return text


def _classification_dict(cls: Optional[Classification]) -> dict:
    """JSON-friendly form of a classification (defaulting to NEW when absent)."""
    if cls is None:
        return {"verdict": Verdict.NEW.value, "rule_id": None, "reason": ""}
    return {
        "verdict": cls.verdict.value,
        "rule_id": cls.rule_id,
        "reason": cls.reason,
    }


# --- JSON ---------------------------------------------------------------


def to_dict(report: RunReport) -> dict:
    """Convert a classified run to a fully JSON-serializable dict.

    Enums become their ``.value``, tuples become lists, and every dataclass is
    expanded into a plain dict. The result embeds the :func:`summarize` rollup
    and per-table/per-column detail (presence, counts, matched/only key counts,
    key columns, and each column's compared/mismatches/rate/classification plus
    capped value samples).
    """
    return {
        "rdb_db": report.rdb_db,
        "modern_db": report.modern_db,
        "generated_at": report.generated_at,
        "discovered": report.discovered,
        "skipped": report.skipped,
        "compared": report.compared,
        "summary": summarize(report),
        "tables": [_table_to_dict(t) for t in report.tables],
    }


def _table_to_dict(table: TableResult) -> dict:
    return {
        "table": table.table,
        "presence": table.presence.value,
        "key_columns": list(table.key_columns),
        "rdb_count": table.rdb_count,
        "modern_count": table.modern_count,
        "row_count_matches": table.row_count_matches,
        "matched_keys": table.matched_keys,
        "rdb_only_keys": table.rdb_only_keys,
        "modern_only_keys": table.modern_only_keys,
        "skipped": table.skipped,
        "skip_reason": table.skip_reason,
        "error": table.error,
        "classification": (
            _classification_dict(table.classification)
            if table.classification
            else None
        ),
        "columns": [_column_to_dict(c) for c in table.columns],
    }


def _column_to_dict(col: ColumnDiff) -> dict:
    return {
        "column": col.column,
        "compared": col.compared,
        "mismatches": col.mismatches,
        "mismatch_rate": col.mismatch_rate,
        "classification": _classification_dict(col.classification),
        "samples": [_sample_to_dict(s) for s in col.samples],
    }


def _sample_to_dict(cell) -> dict:
    return {
        "key": list(cell.key),
        "rdb_value": cell.rdb_value,
        "modern_value": cell.modern_value,
    }


def render_json(report: RunReport) -> str:
    """Return the JSON text for a run (indent=2, non-JSON values via ``str``)."""
    return json.dumps(to_dict(report), indent=2, default=str)


def write_json(report: RunReport, path) -> None:
    """Write the run's JSON form to ``path``."""
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(render_json(report))


# --- Markdown -----------------------------------------------------------


def _samples_cell(col: ColumnDiff) -> str:
    """Inline ``rdb -> modern`` samples for a column, capped and truncated."""
    if not col.samples:
        return ""
    parts = []
    for s in col.samples[:_MAX_INLINE_SAMPLES]:
        parts.append(f"`{_trunc(s.rdb_value)}` → `{_trunc(s.modern_value)}`")
    extra = len(col.samples) - _MAX_INLINE_SAMPLES
    if extra > 0:
        parts.append(f"(+{extra} more)")
    return "; ".join(parts)


def _column_rows(table: TableResult) -> list:
    """Markdown table rows (NEW-first) for a table's differing columns."""
    rows = []
    for col in _ordered_columns(table):
        cls = col.classification or Classification(Verdict.NEW)
        rate = f"{col.mismatch_rate * 100:.1f}%"
        rule = cls.rule_id or "-"
        rows.append(
            "| {col} | {compared} | {mm} | {rate} | {verdict} | {rule} | {samples} |".format(
                col=col.column,
                compared=col.compared,
                mm=col.mismatches,
                rate=rate,
                verdict=cls.verdict.value,
                rule=rule,
                samples=_samples_cell(col),
            )
        )
    return rows


def _table_section(table: TableResult) -> list:
    """Markdown lines for one non-skipped table that has differences."""
    lines = [f"### `{table.table}`", ""]
    key_cols = ", ".join(table.key_columns) if table.key_columns else "(none)"
    lines.append(f"- Presence: `{table.presence.value}`")
    lines.append(f"- Key columns: {key_cols}")
    count_note = "" if table.row_count_matches else " (differs)"
    lines.append(
        f"- Row counts: RDB={table.rdb_count}, RDB_MODERN={table.modern_count}{count_note}"
    )
    lines.append(
        "- Keys: matched={m}, rdb-only={r}, modern-only={n}".format(
            m=table.matched_keys, r=table.rdb_only_keys, n=table.modern_only_keys
        )
    )
    if table.classification is not None:
        lines.append(
            "- Table note: {v} ({rid}) -- {reason}".format(
                v=table.classification.verdict.value,
                rid=table.classification.rule_id or "-",
                reason=table.classification.reason,
            )
        )
    lines.append("")
    if table.columns:
        lines.append(
            "| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |"
        )
        lines.append("| --- | ---: | ---: | ---: | --- | --- | --- |")
        lines.extend(_column_rows(table))
        lines.append("")
    return lines


def _has_verdict(table: TableResult, verdict: Verdict) -> bool:
    return any(_verdict_of(c) == verdict for c in table.columns)


def render_markdown(report: RunReport) -> str:
    """Return a human-readable Markdown report for a classified run.

    The report leads with the summary, then the tables needing attention (NEW
    differences), then known-bug tables, then expected-difference tables, and
    finally a compact list of skipped/ignored tables.
    """
    s = summarize(report)
    lines: list = []

    lines.append("# RDB vs RDB_MODERN Comparison Report")
    lines.append("")
    lines.append(f"- RDB (legacy): `{report.rdb_db}`")
    lines.append(f"- RDB_MODERN: `{report.modern_db}`")
    lines.append(f"- Generated at: {report.generated_at or '(unset)'}")
    lines.append("")

    # Summary table.
    counts = s["verdict_counts"]
    lines.append("## Summary")
    lines.append("")
    lines.append("| Metric | Count |")
    lines.append("| --- | ---: |")
    lines.append(f"| Tables discovered | {s['tables_discovered']} |")
    lines.append(f"| Tables compared | {s['tables_compared']} |")
    lines.append(f"| Tables skipped | {s['tables_skipped']} |")
    lines.append(f"| Tables needing attention | {s['actionable_tables']} |")
    lines.append(f"| Column diffs: NEW | {counts[Verdict.NEW.value]} |")
    lines.append(f"| Column diffs: KNOWN_BUG | {counts[Verdict.KNOWN_BUG.value]} |")
    lines.append(f"| Column diffs: EXPECTED | {counts[Verdict.EXPECTED.value]} |")
    lines.append(f"| Column diffs: IGNORED | {counts[Verdict.IGNORED.value]} |")
    lines.append("")

    # Partition the non-skipped tables by their highest-priority verdict.
    non_skipped = [t for t in report.tables if not t.skipped]
    skipped = [t for t in report.tables if t.skipped]

    new_tables = [t for t in non_skipped if _has_verdict(t, Verdict.NEW)]
    bug_tables = [
        t
        for t in non_skipped
        if t not in new_tables and _has_verdict(t, Verdict.KNOWN_BUG)
    ]
    expected_tables = [
        t
        for t in non_skipped
        if t not in new_tables
        and t not in bug_tables
        and _has_verdict(t, Verdict.EXPECTED)
    ]

    lines.append("## Tables needing attention (NEW differences)")
    lines.append("")
    if new_tables:
        for t in new_tables:
            lines.extend(_table_section(t))
    else:
        lines.append("_None -- no unexplained differences._")
        lines.append("")

    lines.append("## Known-bug differences")
    lines.append("")
    if bug_tables:
        for t in bug_tables:
            lines.extend(_table_section(t))
    else:
        lines.append("_None._")
        lines.append("")

    lines.append("## Expected differences")
    lines.append("")
    if expected_tables:
        for t in expected_tables:
            lines.extend(_table_section(t))
    else:
        lines.append("_None._")
        lines.append("")

    lines.append("## Skipped / ignored tables")
    lines.append("")
    if skipped:
        for t in skipped:
            reason = t.skip_reason or (
                t.classification.reason if t.classification else ""
            )
            rid = (
                t.classification.rule_id
                if t.classification and t.classification.rule_id
                else "-"
            )
            lines.append(f"- `{t.table}` ({rid}): {reason}")
    else:
        lines.append("_None._")
    lines.append("")

    return "\n".join(lines)


def write_markdown(report: RunReport, path) -> None:
    """Write the run's Markdown report to ``path``."""
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(render_markdown(report))
