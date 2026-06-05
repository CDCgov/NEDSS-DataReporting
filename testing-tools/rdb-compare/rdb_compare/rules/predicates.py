"""Value-level predicates used by Expected/KnownBug rules.

A predicate inspects a single :class:`~rdb_compare.models.CellDiff` and returns
True when that mismatch fits the documented pattern. A rule with a predicate
only classifies a column when the predicate holds for *all* of that column's
mismatches -- so a column that mixes the documented pattern with other,
unexplained value diffs stays NEW/actionable rather than being silently
absorbed.

Predicates are small named functions (not lambdas) so they are testable and
render readably in rule definitions.
"""

from __future__ import annotations

from typing import Any

from rdb_compare.models import CellDiff


def _is_blank(v: Any) -> bool:
    """SQL NULL (None) or an empty/whitespace-only string."""
    return v is None or (isinstance(v, str) and v.strip() == "")


def any_value(cell: CellDiff) -> bool:
    """Unconditional -- the difference is explained regardless of values."""
    return True


def rdb_null_modern_set(cell: CellDiff) -> bool:
    """RDB is NULL/blank, RDB_MODERN has a value (modern populated more)."""
    return _is_blank(cell.rdb_value) and not _is_blank(cell.modern_value)


def modern_null_rdb_set(cell: CellDiff) -> bool:
    """RDB_MODERN is NULL/blank, RDB has a value (legacy populated more)."""
    return _is_blank(cell.modern_value) and not _is_blank(cell.rdb_value)


def null_vs_empty(cell: CellDiff) -> bool:
    """One side NULL, the other an empty string (or vice versa) -- a
    representation-only difference (e.g. TREATMENT_COMMENTS NULL vs '')."""
    a, b = cell.rdb_value, cell.modern_value
    return _is_blank(a) and _is_blank(b) and a != b


def both_blank(cell: CellDiff) -> bool:
    """Both sides blank but unequal representations (None vs '' vs ' ')."""
    return _is_blank(cell.rdb_value) and _is_blank(cell.modern_value)
