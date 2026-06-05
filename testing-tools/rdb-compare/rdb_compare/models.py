"""Shared data contracts for the RDB vs RDB_MODERN comparison.

Every module in :mod:`rdb_compare` agrees on these dataclasses. The comparison
*engine* produces :class:`TableResult` objects (raw, unclassified); the
*classifier* annotates each finding with a :class:`Classification` by consulting
the rule registry; the *report* layer renders the annotated results to JSON/MD.

The comparison is UID-keyed and column-by-column (see the PDF templates): rows
are matched on a table's business/UID key(s) -- never the surrogate ``*_KEY``
columns, which carry documented offsets -- and every non-key column is compared
NULL-aware.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Optional


# Sentinel meaning "no value supplied" (distinct from SQL NULL, which is None).
class _Unset:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __repr__(self):
        return "UNSET"

    def __bool__(self):
        return False


UNSET = _Unset()


class Verdict(str, Enum):
    """How a raw difference should be interpreted."""

    NEW = "NEW"             # Unexpected -- not covered by any rule; needs attention.
    EXPECTED = "EXPECTED"   # Documented, by-design difference.
    KNOWN_BUG = "KNOWN_BUG"  # Documented probable bug (has a ticket/PDF reference).
    IGNORED = "IGNORED"     # Structurally uninteresting (skip table, env/timestamp,
                            # surrogate-key offset, audit column).

    def __str__(self) -> str:  # nice rendering in reports
        return self.value


@dataclass(frozen=True)
class Classification:
    """The verdict the rule registry assigns to a finding."""

    verdict: Verdict
    rule_id: Optional[str] = None  # e.g. "SKIP-ETL", "BUG-D_PLACE", "EXP-EVENT_DATE_TYPE"
    reason: str = ""

    @property
    def is_actionable(self) -> bool:
        """NEW findings are the ones a human needs to look at."""
        return self.verdict == Verdict.NEW


@dataclass(frozen=True)
class CellDiff:
    """A single (row-key, column) value mismatch."""

    table: str
    key: tuple              # the UID value(s) identifying the row
    column: str
    rdb_value: Any
    modern_value: Any


@dataclass
class ColumnDiff:
    """Aggregated mismatch information for one column of one table."""

    table: str
    column: str
    compared: int = 0                 # rows present in BOTH and thus comparable
    mismatches: int = 0               # of those, how many differ
    samples: list = field(default_factory=list)  # list[CellDiff], capped
    classification: Optional[Classification] = None

    @property
    def mismatch_rate(self) -> float:
        return (self.mismatches / self.compared) if self.compared else 0.0


class Presence(str, Enum):
    BOTH = "both"
    RDB_ONLY = "rdb_only"
    MODERN_ONLY = "modern_only"

    def __str__(self) -> str:
        return self.value


@dataclass
class TableResult:
    """Comparison outcome for a single table."""

    table: str
    presence: Presence = Presence.BOTH
    key_columns: tuple = ()
    rdb_count: int = 0
    modern_count: int = 0
    matched_keys: int = 0             # keys present in both
    rdb_only_keys: int = 0            # keys only in RDB
    modern_only_keys: int = 0         # keys only in RDB_MODERN
    columns: list = field(default_factory=list)  # list[ColumnDiff] (mismatching columns)
    skipped: bool = False
    skip_reason: Optional[str] = None
    # Classification attached to a *table-level* observation (skip, or a
    # row-count/existence difference). Column-level verdicts live on each ColumnDiff.
    classification: Optional[Classification] = None
    error: Optional[str] = None       # populated if the table could not be compared

    @property
    def row_count_matches(self) -> bool:
        return self.rdb_count == self.modern_count

    @property
    def has_column_mismatches(self) -> bool:
        return any(c.mismatches for c in self.columns)


@dataclass
class RunReport:
    """The full comparison run."""

    rdb_db: str
    modern_db: str
    generated_at: str = ""            # ISO timestamp, stamped by the caller
    tables: list = field(default_factory=list)  # list[TableResult]
    discovered: int = 0               # tables found in common
    skipped: int = 0                  # tables skipped by rule
    compared: int = 0                 # tables actually compared

    def actionable_tables(self) -> list:
        """Tables with at least one NEW (unexplained) column difference."""
        out = []
        for t in self.tables:
            if any(
                c.classification and c.classification.verdict == Verdict.NEW
                for c in t.columns
            ):
                out.append(t)
        return out
