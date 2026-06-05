"""The known-differences rule registry.

A :class:`RuleRegistry` holds an ordered list of :class:`~rdb_compare.rules.types.Rule`
objects and answers two questions for the classifier:

* :meth:`classify_table` -- is this whole table skipped?
* :meth:`classify_column` -- given a column's mismatches, what verdict applies?

Rules are consulted in ``sort_key`` order (skip < known-bug < expected < ignore,
exact before glob); the first matching rule wins. A column with no matching rule
is classified ``NEW`` -- an unexplained difference that needs human attention.
"""

from __future__ import annotations

from typing import Iterable, Optional

from rdb_compare.models import Classification, Verdict
from rdb_compare.rules.types import (
    ExpectedDiffRule,
    IgnoreColumnRule,
    KnownBugRule,
    Rule,
    SkipTableRule,
)

__all__ = [
    "RuleRegistry",
    "Rule",
    "SkipTableRule",
    "IgnoreColumnRule",
    "ExpectedDiffRule",
    "KnownBugRule",
]

# The verdict for a difference no rule explains.
UNEXPLAINED = Classification(
    verdict=Verdict.NEW,
    rule_id=None,
    reason="No rule matched -- unexplained difference",
)


class RuleRegistry:
    def __init__(self, rules: Optional[Iterable[Rule]] = None):
        self._rules = sorted(rules or [], key=lambda r: r.sort_key())

    def add(self, rule: Rule) -> None:
        self._rules.append(rule)
        self._rules.sort(key=lambda r: r.sort_key())

    def extend(self, rules: Iterable[Rule]) -> None:
        for r in rules:
            self._rules.append(r)
        self._rules.sort(key=lambda r: r.sort_key())

    @property
    def rules(self) -> list:
        return list(self._rules)

    def __len__(self) -> int:
        return len(self._rules)

    # --- classification -------------------------------------------------
    def classify_table(self, table: str) -> Optional[Classification]:
        """Return an IGNORED classification if the table is skipped, else None."""
        for r in self._rules:
            if r.scope == "table" and r.matches_table(table):
                return Classification(r.verdict, r.id, r.reason)
        return None

    def is_skipped(self, table: str) -> bool:
        c = self.classify_table(table)
        return c is not None and c.verdict == Verdict.IGNORED

    def classify_column(self, table: str, column: str, cells=()) -> Classification:
        """Classify a column's mismatches.

        ``cells`` is the list of :class:`~rdb_compare.models.CellDiff` for this
        column; value-predicate rules only apply when they explain *all* of them.
        """
        for r in self._rules:
            if r.scope != "column":
                continue
            if r.matches_column(table, column) and r.applies_to_cells(cells):
                return Classification(r.verdict, r.id, r.reason)
        return UNEXPLAINED
