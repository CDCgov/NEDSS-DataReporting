"""Typed, declarative rule classes for the known-differences registry.

Each rule is a small data object that (a) matches a table and/or column by name
pattern and (b) carries a fixed :class:`~rdb_compare.models.Verdict`. This is the
"modular, extensible" alternative to if/else sprawl: new known differences are
added by appending rule instances to the catalog, and each rule is independently
unit-testable.

Name matching is case-insensitive (SQL Server default) and glob-style via
:func:`fnmatch.fnmatchcase` on upper-cased names, so patterns like ``"*_KEY"``,
``"*_LAST_UPDATE_DT"`` or ``"D_*"`` work as expected.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from fnmatch import fnmatchcase
from typing import Callable, Optional

from rdb_compare.models import Verdict
from rdb_compare.rules.predicates import any_value


def _match(pattern: str, name: str) -> bool:
    return fnmatchcase((name or "").upper(), (pattern or "").upper())


def _is_glob(pattern: str) -> bool:
    return any(ch in (pattern or "") for ch in "*?[")


@dataclass(frozen=True)
class Rule:
    """Base rule. Subclasses set ``scope`` and supply matching behaviour."""

    id: str
    reason: str
    verdict: Verdict
    scope: str = "column"            # "table" or "column"
    base_priority: int = 50
    table_pattern: str = "*"
    column_pattern: str = "*"
    predicate: Callable = field(default=any_value)
    ticket: Optional[str] = None     # e.g. a Jira/PDF reference for KNOWN_BUG

    # --- matching -------------------------------------------------------
    def matches_table(self, table: str) -> bool:
        return _match(self.table_pattern, table)

    def matches_column(self, table: str, column: str) -> bool:
        return _match(self.table_pattern, table) and _match(self.column_pattern, column)

    def applies_to_cells(self, cells) -> bool:
        """True when this rule explains *every* mismatch in the column.

        Empty ``cells`` -> vacuously True (used by name-only rules).
        """
        return all(self.predicate(c) for c in cells)

    # --- ordering -------------------------------------------------------
    def sort_key(self) -> tuple:
        # Lower sorts first (checked first, wins). More specific (no glob in
        # table+column) beats glob within the same base priority.
        glob = _is_glob(self.table_pattern) or _is_glob(self.column_pattern)
        return (self.base_priority, 1 if glob else 0, self.id)


# NB: the subclasses below are *plain* subclasses of the frozen ``Rule``
# dataclass -- intentionally NOT re-decorated with @dataclass, which would
# regenerate ``__init__`` and clobber these convenience constructors. They call
# the parent's generated (object.__setattr__-based) ``__init__``, so instances
# remain frozen.


class SkipTableRule(Rule):
    """Exclude an entire table from comparison (verdict IGNORED, scope table)."""

    def __init__(self, table_pattern: str, reason: str, id: Optional[str] = None):
        super().__init__(
            id=id or f"SKIP-{table_pattern}",
            reason=reason,
            verdict=Verdict.IGNORED,
            scope="table",
            base_priority=10,
            table_pattern=table_pattern,
        )


class IgnoreColumnRule(Rule):
    """Ignore a column's differences by name (key offsets, env/timestamp, audit)."""

    def __init__(
        self,
        column_pattern: str,
        reason: str,
        table_pattern: str = "*",
        category: str = "",
        id: Optional[str] = None,
    ):
        super().__init__(
            id=id or f"IGN-{category or 'col'}-{column_pattern}",
            reason=reason,
            verdict=Verdict.IGNORED,
            scope="column",
            base_priority=40,
            table_pattern=table_pattern,
            column_pattern=column_pattern,
        )


class ExpectedDiffRule(Rule):
    """A documented, by-design difference (verdict EXPECTED)."""

    def __init__(
        self,
        table_pattern: str,
        column_pattern: str,
        reason: str,
        predicate: Callable = any_value,
        id: Optional[str] = None,
    ):
        super().__init__(
            id=id or f"EXP-{table_pattern}.{column_pattern}",
            reason=reason,
            verdict=Verdict.EXPECTED,
            scope="column",
            base_priority=30,
            table_pattern=table_pattern,
            column_pattern=column_pattern,
            predicate=predicate,
        )


class KnownBugRule(Rule):
    """A documented probable bug (verdict KNOWN_BUG)."""

    def __init__(
        self,
        table_pattern: str,
        column_pattern: str,
        reason: str,
        ticket: Optional[str] = None,
        predicate: Callable = any_value,
        id: Optional[str] = None,
    ):
        super().__init__(
            id=id or f"BUG-{table_pattern}.{column_pattern}",
            reason=reason,
            verdict=Verdict.KNOWN_BUG,
            scope="column",
            base_priority=20,
            table_pattern=table_pattern,
            column_pattern=column_pattern,
            predicate=predicate,
            ticket=ticket,
        )
