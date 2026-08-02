"""Generate MSSQL bulk-load files from the functional tests' setup scripts.

The setup scripts are full T-SQL (variables, ``OUTPUT INSERTED`` identity
captures, UPDATEs and DELETEs), so the final rows cannot be read straight off
the INSERT statements. Instead each test's scripts are *evaluated* once by a
small interpreter that covers exactly the constructs the corpus uses:

  * ``DECLARE @x bigint|nvarchar = <literal or string-concat expression>``
  * ``DECLARE @t TABLE (...)`` + ``INSERT ... OUTPUT INSERTED.[col] INTO @t``
    + ``SELECT TOP 1 @x = [value] FROM @t`` — the identity capture pattern.
    When the captured column is not in the INSERT's column list the value is
    database-generated; a synthetic value is allocated instead (loaded later
    with KEEPIDENTITY) so downstream references stay consistent.
  * ``INSERT INTO [dbo].[T] (cols) VALUES (...), (...)``
  * ``UPDATE``/``DELETE`` with conjunctive equality WHERE clauses (including
    ``(SELECT TOP 1 ...)`` scalar subqueries), applied to the in-memory rows.

The evaluated rows are rendered N times — each copy's block IDs shifted per
the BulkPlan, each copy's synthetic identities drawn from a fresh range. The
Parquet output and load scripts live in :mod:`.parquet_out`; this module owns
evaluation, the column-set parts, per-copy rendering, and the set-based
``fixup.sql`` for seed-data-dependent INSERTs.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Callable, Optional, Union

from .bulk import BulkPlan, TestSetup
from .remapper import BLOCK_SIZE

_IDENT = r"\[?([A-Za-z0-9_]+)\]?"
_QUALIFIED = r"(?:\[?[A-Za-z0-9_]+\]?\.)*" + _IDENT


class BulkGenError(ValueError):
    """A setup construct the evaluator does not support."""


class _SubqueryMiss(Exception):
    """A scalar subquery matched no evaluated row.

    Either the subquery reads seed data that only exists on a real database,
    or the recorded WHERE captured state that a prior statement in the replay
    already changed (in which case the statement no-ops on a real run too).
    """

    def __init__(self, table: str):
        super().__init__(table)
        self.table = table


# ---------------------------------------------------------------------------
# Values
#
# A value is None (SQL NULL) or a list of parts; a part is a plain string or
# an IdRef placeholder for a synthesized identity. Block IDs stay as digits
# inside the strings and are shifted at render time.


@dataclass(frozen=True)
class IdRef:
    table: str
    seq: int  # per-table sequence within one copy of the suite


Part = Union[str, IdRef]
Value = Optional[list]


def _text(value: Value) -> str:
    if value is None:
        return "<NULL>"
    return "".join(p if isinstance(p, str) else f"<id:{p.table}:{p.seq}>" for p in value)


def _values_equal(a: Value, b: Value) -> bool:
    if a is None or b is None:
        return a is b
    return _text(a) == _text(b)


# ---------------------------------------------------------------------------
# Statement splitting: ';' outside string literals, with '--' comments
# dropped (outside literals only — XML payloads may contain either).


def split_sql(sql: str) -> list[str]:
    statements: list[str] = []
    buf: list[str] = []
    i, n = 0, len(sql)
    in_string = False
    while i < n:
        ch = sql[i]
        if in_string:
            buf.append(ch)
            if ch == "'":
                in_string = False
            i += 1
        elif ch == "'":
            in_string = True
            buf.append(ch)
            i += 1
        elif ch == "-" and sql.startswith("--", i):
            while i < n and sql[i] != "\n":
                i += 1
        elif ch == ";":
            statements.append("".join(buf))
            buf = []
            i += 1
        else:
            buf.append(ch)
            i += 1
    statements.append("".join(buf))
    return [s.strip() for s in statements if s.strip()]


def _split_top_level(text: str, is_sep: Callable[[str, int], int]) -> list[str]:
    """Split on separators found outside quotes and parentheses.

    ``is_sep(text, i)`` returns the separator length at ``i`` (0 = no match).
    """
    parts: list[str] = []
    buf: list[str] = []
    depth = 0
    in_string = False
    i, n = 0, len(text)
    while i < n:
        ch = text[i]
        if in_string:
            buf.append(ch)
            if ch == "'":
                in_string = False
            i += 1
            continue
        if ch == "'":
            in_string = True
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if depth == 0 and not in_string:
            sep_len = is_sep(text, i)
            if sep_len:
                parts.append("".join(buf))
                buf = []
                i += sep_len
                continue
        buf.append(ch)
        i += 1
    parts.append("".join(buf))
    return [p.strip() for p in parts]


def _split_commas(text: str) -> list[str]:
    return _split_top_level(text, lambda t, i: 1 if t[i] == "," else 0)


def _split_ands(text: str) -> list[str]:
    def is_and(t: str, i: int) -> int:
        if t[i : i + 3].upper() == "AND" and (i == 0 or not t[i - 1].isalnum()):
            after = i + 3
            if after >= len(t) or not (t[after].isalnum() or t[after] == "_"):
                return 3
        return 0

    return _split_top_level(text, is_and)


# ---------------------------------------------------------------------------
# Evaluation


@dataclass
class Table:
    name: str
    first_seen: int
    columns: list[str] = field(default_factory=list)  # union, in first-seen order
    rows: list[dict] = field(default_factory=list)  # col -> Value
    identity_col: Optional[str] = None
    identity_count: int = 0  # synthesized values per copy of the suite
    _by_lower: dict[str, str] = field(default_factory=dict)

    def add_column(self, col: str) -> str:
        """Register a column and return its canonical (first-seen) spelling.

        SQL Server column names are case-insensitive; different tests spell
        the same column differently, and a duplicate in the union would make
        the bulkload view invalid.
        """
        canonical = self._by_lower.get(col.lower())
        if canonical is None:
            canonical = col
            self._by_lower[col.lower()] = col
            self.columns.append(col)
        return canonical


def _row_get(row: dict, col: str) -> Value:
    """Case-insensitive row lookup (row keys hold canonical spellings)."""
    if col in row:
        return row[col]
    lower = col.lower()
    for key, value in row.items():
        if key.lower() == lower:
            return value
    return None


@dataclass
class SuiteData:
    """Final-state rows for the whole suite, still holding original block IDs."""

    plan: BulkPlan
    tables: dict[str, Table] = field(default_factory=dict)
    test_rows: dict[str, list[tuple[str, dict]]] = field(default_factory=dict)
    # INSERT rows with values only the target database can supply (seed-data
    # subqueries). Loaded via a staging table + one set-based INSERT..SELECT.
    deferred_rows: list["DeferredRow"] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    def table(self, name: str) -> Table:
        key = name.lower()
        if key not in self.tables:
            self.tables[key] = Table(name=name, first_seen=len(self.tables))
        return self.tables[key]

    @property
    def load_order(self) -> list[Table]:
        return sorted(self.tables.values(), key=lambda t: t.first_seen)

    @property
    def rows_per_copy(self) -> int:
        return sum(len(t.rows) for t in self.tables.values())


@dataclass
class DeferredRow:
    """One INSERT row whose seed-dependent columns resolve at load time."""

    test: str
    table_key: str
    columns: list[str]  # literal columns, canonical, insert order
    values: list  # parallel to columns
    seed_cols: list[tuple[str, list]]  # (canonical column, expr as parts)


_DECLARE_ASSIGN = re.compile(
    r"DECLARE\s+(@\w+)\s+[A-Za-z]+(?:\s*\(\s*(?:\d+|MAX)\s*\))?\s*=\s*", re.I
)
_DECLARE_TABLE = re.compile(r"DECLARE\s+(@\w+)\s+TABLE\s*\(", re.I)
_DECLARE_BARE = re.compile(
    r"DECLARE\s+(@\w+)\s+[A-Za-z]+(?:\s*\(\s*(?:\d+|MAX)\s*\))?\s*(?=$|;|\n|DECLARE)", re.I
)
_STRING = re.compile(r"N?'((?:[^']|'')*)'", re.S)
_INSERT = re.compile(
    rf"INSERT\s+INTO\s+{_QUALIFIED}\s*\((?P<cols>[^)]*)\)\s*"
    r"(?:OUTPUT\s+INSERTED\.\[?(?P<outcol>[A-Za-z0-9_]+)\]?"
    r"\s+INTO\s+(?P<tv>@\w+)\s*(?:\([^)]*\))?\s*)?"
    r"VALUES\s*(?P<values>.*)$",
    re.I | re.S,
)
_CAPTURE = re.compile(
    rf"SELECT\s+TOP\s*\(?\s*1\s*\)?\s+(?P<var>@\w+)\s*=\s*{_IDENT}\s+FROM\s+(?P<tv>@\w+)\s*$",
    re.I,
)
_UPDATE = re.compile(
    rf"UPDATE\s+{_QUALIFIED}\s+SET\s+(?P<set>.*?)\s+WHERE\s+(?P<where>.*)$", re.I | re.S
)
_DELETE = re.compile(
    rf"DELETE\s+FROM\s+{_QUALIFIED}\s*(?:WHERE\s+(?P<where>.*))?$", re.I | re.S
)
_SUBQUERY = re.compile(
    rf"\(\s*SELECT\s+TOP\s*\(?\s*1\s*\)?\s+{_IDENT}\s+FROM\s+{_QUALIFIED}\s*"
    r"(?:WHERE\s+(?P<where>.*?))?\s*(?:ORDER\s+BY\s+[^)]*)?\)$",
    re.I | re.S,
)


class _Evaluator:
    def __init__(self, suite: SuiteData, test: TestSetup, now: str):
        self.suite = suite
        self.test = test
        self.now = now
        self.env: dict[str, Value] = {}
        self.table_vars: dict[str, list[Value]] = {}

    def warn(self, msg: str) -> None:
        self.suite.warnings.append(f"{self.test.name}: {msg}")

    # -- expressions --------------------------------------------------------

    def eval_expr(self, text: str, row: Optional[dict] = None) -> Value:
        text = text.strip()
        sub = _SUBQUERY.match(text)
        if sub:
            return self._eval_subquery(sub)
        parts = _split_top_level(text, lambda t, i: 1 if t[i] == "+" else 0)
        if len(parts) > 1:
            values = [self.eval_expr(part, row) for part in parts]
            if any(v is None for v in values):
                return None  # SQL: NULL propagates through + (either meaning)
            texts = [_text(v) for v in values]
            if all(re.fullmatch(r"-?\d+", t) for t in texts):
                return [str(sum(int(t) for t in texts))]
            out: list = []
            for value in values:
                out.extend(value)
            return out
        return self._eval_primary(text, row)

    def _eval_primary(self, text: str, row: Optional[dict]) -> Value:
        text = text.strip()
        m = _STRING.fullmatch(text)
        if m:
            return [m.group(1).replace("''", "'")]
        if re.fullmatch(r"-?\d+(\.\d+)?", text):
            return [text]
        if re.fullmatch(r"NULL", text, re.I):
            return None
        if text.startswith("@"):
            if text not in self.env:
                raise BulkGenError(f"reference to unset variable {text}")
            return self.env[text]
        if re.fullmatch(r"GETDATE\s*\(\s*\)", text, re.I):
            return [self.now]
        m = re.fullmatch(r"ABS\s*\((.*)\)", text, re.I | re.S)
        if m:
            value = self.eval_expr(m.group(1), row)
            if value is None:
                return None
            return [str(abs(int(_text(value))))]
        m = re.fullmatch(
            r"CONVERT\s*\(\s*\w+(?:\s*\(\s*(?:\d+|MAX)\s*\))?\s*,(.*)\)", text, re.I | re.S
        )
        if m:
            return self.eval_expr(m.group(1), row)
        m = re.fullmatch(r"ISNULL\s*\((.*)\)", text, re.I | re.S)
        if m:
            args = _split_commas(m.group(1))
            if len(args) == 2:
                value = self.eval_expr(args[0], row)
                return value if value is not None else self.eval_expr(args[1], row)
        if row is not None:
            m = re.fullmatch(_IDENT, text)
            if m:
                return _row_get(row, m.group(1))
        raise BulkGenError(f"unsupported expression: {text[:80]!r}")

    def _eval_subquery(self, m: re.Match) -> Value:
        col, table_name = m.group(1), m.group(2)
        table = self.suite.table(table_name)
        conditions = self._parse_where(m.group("where")) if m.group("where") else []
        for row in table.rows:
            if all(_values_equal(_row_get(row, c), v) for c, v in conditions):
                return _row_get(row, col)
        raise _SubqueryMiss(table_name)

    def _parse_where(self, where: str) -> list[tuple[str, Value]]:
        conditions = []
        for clause in _split_ands(where):
            m = re.fullmatch(rf"\s*{_IDENT}\s*=\s*(.*)", clause, re.S)
            if not m:
                raise BulkGenError(f"unsupported WHERE clause: {clause[:80]!r}")
            conditions.append((m.group(1), self.eval_expr(m.group(2))))
        return conditions

    # -- statements ---------------------------------------------------------

    def run(self, sql: str) -> None:
        for statement in split_sql(sql):
            keyword = statement.split(None, 1)[0].upper()
            if keyword in ("USE", "ALTER", "SET"):
                continue
            handler = getattr(self, f"_do_{keyword.lower()}", None)
            if handler is None:
                raise BulkGenError(f"unsupported statement: {statement[:80]!r}")
            handler(statement)

    def _do_declare(self, statement: str) -> None:
        remaining = statement
        for m in _DECLARE_TABLE.finditer(remaining):
            self.table_vars[m.group(1)] = []
        remaining = _DECLARE_TABLE.sub("DECLARED_TABLE (", remaining)
        # Assigned declares: the expression runs to the end of the statement
        # (statements were already split on ';'), one DECLARE per statement in
        # this corpus once table declares are removed.
        m = _DECLARE_ASSIGN.search(remaining)
        if m:
            self.env[m.group(1)] = self.eval_expr(remaining[m.end():])
            return
        for m in _DECLARE_BARE.finditer(remaining):
            self.env.setdefault(m.group(1), None)

    def _do_insert(self, statement: str) -> None:
        m = _INSERT.match(statement)
        if not m:
            raise BulkGenError(f"unsupported INSERT: {statement[:80]!r}")
        table = self.suite.table(m.group(1))
        columns = [c.strip().strip("[]") for c in m.group("cols").split(",")]
        out_col, out_tv = m.group("outcol"), m.group("tv")

        rows = []
        for tuple_text in _split_commas(m.group("values").strip()):
            if not (tuple_text.startswith("(") and tuple_text.endswith(")")):
                raise BulkGenError(f"unsupported VALUES tuple: {tuple_text[:80]!r}")
            raw_values = _split_commas(tuple_text[1:-1])
            if len(raw_values) != len(columns):
                raise BulkGenError(
                    f"column/value count mismatch inserting into {table.name}"
                )
            literals: list[tuple[str, Value]] = []
            seeds: list[tuple[str, list]] = []
            miss_table = ""
            for col, value_text in zip(columns, raw_values):
                canonical = table.add_column(col)
                try:
                    literals.append((canonical, self.eval_expr(value_text)))
                except _SubqueryMiss as miss:
                    # A value only the target database can supply (seed-data
                    # lookup): resolve at load time via a set-based INSERT.
                    seeds.append((canonical, self._inline_vars(value_text)))
                    miss_table = miss.table
            if seeds:
                if out_col:
                    raise BulkGenError(
                        f"OUTPUT capture on seed-dependent INSERT into {table.name}"
                    )
                self.suite.deferred_rows.append(DeferredRow(
                    test=self.test.name,
                    table_key=table.name.lower(),
                    columns=[c for c, _ in literals],
                    values=[v for _, v in literals],
                    seed_cols=seeds,
                ))
                self.warn(
                    f"INSERT into {table.name} deferred to fixup.sql "
                    f"(subquery on {miss_table} reads seed data)"
                )
                continue
            rows.append(dict(literals))

        for row in rows:
            if out_col:
                out_key = table.add_column(out_col)
                if out_key in row:
                    captured = row[out_key]
                else:
                    # Database-generated (identity): synthesize a stable value.
                    table.identity_col = out_key
                    captured = [IdRef(table.name, table.identity_count)]
                    table.identity_count += 1
                    row[out_key] = captured
                self.table_vars.setdefault(out_tv, []).append(captured)
            table.rows.append(row)
            self.suite.test_rows.setdefault(self.test.name, []).append(
                (table.name.lower(), row)
            )

    def _inline_vars(self, statement: str) -> list:
        """Replace @variables with SQL literals, keeping IdRefs as parts."""
        parts: list = []
        pos = 0
        for m in re.finditer(r"@\w+", statement):
            parts.append(statement[pos : m.start()])
            value = self.env.get(m.group(0))
            if value is None:
                if m.group(0) not in self.env:
                    raise BulkGenError(f"reference to unset variable {m.group(0)}")
                parts.append("NULL")
            elif len(value) == 1 and isinstance(value[0], IdRef):
                parts.append(value[0])
            elif re.fullmatch(r"-?\d+(\.\d+)?", _text(value)):
                parts.append(_text(value))
            else:
                parts.append("N'" + _text(value).replace("'", "''") + "'")
            pos = m.end()
        parts.append(statement[pos:])
        return parts

    def _do_select(self, statement: str) -> None:
        m = _CAPTURE.match(statement)
        if not m:
            raise BulkGenError(f"unsupported SELECT: {statement[:80]!r}")
        tv = m.group("tv")
        if tv not in self.table_vars or not self.table_vars[tv]:
            raise BulkGenError(f"capture from empty/unknown table variable {tv}")
        self.env[m.group("var")] = self.table_vars[tv][-1]

    def _do_update(self, statement: str) -> None:
        m = _UPDATE.match(statement)
        if not m:
            raise BulkGenError(f"unsupported UPDATE: {statement[:80]!r}")
        table = self.suite.table(m.group(1))
        try:
            conditions = self._parse_where(m.group("where"))
        except _SubqueryMiss as miss:
            # A no-op on a real replay too: the recorded WHERE state was
            # already changed by an earlier statement (or targets seed data).
            self.warn(f"UPDATE {table.name} skipped (subquery on {miss.table} "
                      f"matched no rows)")
            return
        assignments = []
        for clause in _split_commas(m.group("set")):
            am = re.fullmatch(rf"\s*{_IDENT}\s*=\s*(.*)", clause, re.S)
            if not am:
                raise BulkGenError(f"unsupported SET clause: {clause[:80]!r}")
            assignments.append((am.group(1), am.group(2)))
        matched = 0
        try:
            for row in table.rows:
                if all(_values_equal(_row_get(row, c), v) for c, v in conditions):
                    matched += 1
                    # SQL evaluates every RHS against the pre-update row.
                    new_values = [(c, self.eval_expr(e, row)) for c, e in assignments]
                    for col, value in new_values:
                        row[table.add_column(col)] = value
        except _SubqueryMiss as miss:
            self.warn(f"UPDATE {table.name} skipped (subquery on {miss.table} "
                      f"matched no rows)")
            return
        if matched == 0:
            self.warn(f"UPDATE {table.name} matched no rows")

    def _do_delete(self, statement: str) -> None:
        m = _DELETE.match(statement)
        if not m:
            raise BulkGenError(f"unsupported DELETE: {statement[:80]!r}")
        table = self.suite.table(m.group(1))
        try:
            conditions = self._parse_where(m.group("where")) if m.group("where") else []
        except _SubqueryMiss as miss:
            self.warn(f"DELETE from {table.name} skipped (subquery on {miss.table} "
                      f"matched no rows)")
            return
        kept = [
            row
            for row in table.rows
            if not all(_values_equal(_row_get(row, c), v) for c, v in conditions)
        ]
        removed = {id(r) for r in table.rows} - {id(r) for r in kept}
        table.rows = kept
        for rows in self.suite.test_rows.values():
            rows[:] = [(t, r) for t, r in rows if id(r) not in removed]


def evaluate_suite(plan: BulkPlan, now: Optional[str] = None) -> SuiteData:
    """Run every test's setup scripts through the interpreter once."""
    suite = SuiteData(plan=plan)
    now = now or datetime.now().strftime("%Y-%m-%dT%H:%M:%S.000")
    for test in plan.tests:
        evaluator = _Evaluator(suite, test, now)
        for step_name, sql in test.steps:
            try:
                evaluator.run(sql)
            except BulkGenError as exc:
                raise BulkGenError(f"{test.name}/{step_name}: {exc}") from exc

    # Once a table is known to have an identity column, EVERY row must carry
    # a synthesized value — not only the OUTPUT-captured ones. Loading with
    # IDENTITY_INSERT advances the table's identity seed (unlike bcp's
    # KEEPIDENTITY), so a row left for the server to number would draw a
    # value inside the synthesized range another copy explicitly claims.
    for table in suite.tables.values():
        if not table.identity_col:
            continue
        for row in table.rows:
            if table.identity_col not in row:
                row[table.identity_col] = [IdRef(table.name, table.identity_count)]
                table.identity_count += 1
    return suite


# ---------------------------------------------------------------------------
# Rendering: per-copy ID shifting via precompiled segments


_NUMBER = re.compile(r"(?<!\d)\d+(?!\d)")


def _compile_parts(parts: list, block_start: int, block_end: int) -> list:
    """Split string parts around in-block numbers so shifting is a cheap join.

    Returns a list of: plain str | int (in-block ID, shift me) | IdRef.
    """
    compiled: list = []
    for part in parts:
        if isinstance(part, IdRef):
            compiled.append(part)
            continue
        pos = 0
        for m in _NUMBER.finditer(part):
            number = int(m.group(0))
            if block_start <= number < block_end:
                compiled.append(part[pos : m.start()])
                compiled.append(number)
                pos = m.end()
        compiled.append(part[pos:])
    return compiled


@dataclass
class TablePart:
    """Rows of one table sharing the exact same column set.

    Different inserts into a table use different column subsets; loading them
    through one union view would turn absent columns into NULLs where a real
    INSERT applies the column default (and NOT NULL columns would reject the
    load). Each distinct column set gets its own data file and view instead.
    """

    table: Table
    name: str  # e.g. "Person" or "Person__2"
    columns: list[str]
    index: int = 1  # 1-based position among the table's parts

    @property
    def keep_identity(self) -> bool:
        return self.table.identity_col in self.columns


def _build_parts(suite: SuiteData) -> dict[tuple[str, frozenset], TablePart]:
    """Assign every distinct (table, column-set) to a TablePart, in row order."""
    parts: dict[tuple[str, frozenset], TablePart] = {}
    per_table: dict[str, int] = {}
    for test in suite.plan.tests:
        for table_key, row in suite.test_rows.get(test.name, []):
            key = (table_key, frozenset(c.lower() for c in row))
            if key in parts:
                continue
            table = suite.tables[table_key]
            per_table[table_key] = per_table.get(table_key, 0) + 1
            parts[key] = TablePart(
                table=table,
                name=table.name,  # renamed below if the table splits
                columns=[c for c in table.columns if c in row],
            )
    # Deterministic names: number the parts of any table that split.
    counters: dict[str, int] = {}
    for key, part in parts.items():
        table_key = key[0]
        counters[table_key] = counters.get(table_key, 0) + 1
        part.index = counters[table_key]
        if per_table[table_key] > 1:
            part.name = f"{part.table.name}__{part.index}"
    return parts


@dataclass
class _CompiledRow:
    part: TablePart
    fields: list  # one compiled parts-list (or None) per part column


def _compile_rows(
    suite: SuiteData, parts: dict[tuple[str, frozenset], TablePart]
) -> dict[str, list[_CompiledRow]]:
    by_test: dict[str, list[_CompiledRow]] = {}
    for test in suite.plan.tests:
        lo, hi = test.block_start, test.block_start + BLOCK_SIZE
        compiled = []
        for table_key, row in suite.test_rows.get(test.name, []):
            part = parts[(table_key, frozenset(c.lower() for c in row))]
            fields = [
                None if row.get(col) is None else _compile_parts(row[col], lo, hi)
                for col in part.columns
            ]
            compiled.append(_CompiledRow(part, fields))
        by_test[test.name] = compiled
    return by_test


def build_ordered_parts(
    suite: SuiteData,
) -> tuple[dict[tuple[str, frozenset], TablePart], list[TablePart]]:
    """Part registry plus parts in FK-safe (first-insert, part-index) order."""
    part_map = _build_parts(suite)
    order = {t.name.lower(): t.first_seen for t in suite.tables.values()}
    all_parts = sorted(
        part_map.values(), key=lambda p: (order[p.table.name.lower()], p.index)
    )
    return part_map, all_parts


def _render_field(compiled: list, offset: int, id_base: dict[str, int]) -> str:
    out = []
    for part in compiled:
        if isinstance(part, int):
            out.append(str(part + offset))
        elif isinstance(part, IdRef):
            out.append(str(id_base[part.table.lower()] + part.seq))
        else:
            out.append(part)
    return "".join(out)


# fixup.sql resolves seed-dependent INSERTs set-based: a numbers CTE yields
# one row per copy, every column becomes an expression in the copy index i
# (shifted IDs are base + (i/slots)*span + (i%slots)*stride), and the seed
# subquery appears once — constant script size regardless of copy count.


def _copy_offset_sql(plan: BulkPlan, base_shift: int) -> str:
    expr = f"(n.i / {plan.slots}) * {plan.span} + (n.i % {plan.slots}) * {plan.stride}"
    return f"{base_shift} + {expr}" if base_shift else expr


def _sql_string(text: str) -> str:
    return "N'" + text.replace("'", "''") + "'"


def _part_exprs(compiled: list, offset_sql: str, identity_base: int, suite: SuiteData) -> list[str]:
    exprs = []
    for part in compiled:
        if isinstance(part, int):
            exprs.append(f"({part} + {offset_sql})")
        elif isinstance(part, IdRef):
            count = suite.tables[part.table.lower()].identity_count
            exprs.append(f"({identity_base + part.seq} + n.i * {count})")
        elif part:
            exprs.append(_sql_string(part))
    return exprs


def _value_expr(
    value: Value, lo: int, hi: int, offset_sql: str, identity_base: int, suite: SuiteData
) -> str:
    if value is None:
        return "NULL"
    exprs = _part_exprs(_compile_parts(value, lo, hi), offset_sql, identity_base, suite)
    if not exprs:
        return "N''"
    if len(exprs) == 1:
        expr = exprs[0]
        # A plain numeric literal needs no quoting.
        if expr.startswith("N'") and re.fullmatch(r"-?\d+(\.\d+)?", _text(value)):
            return _text(value)
        return expr
    return "CONCAT(" + ", ".join(exprs) + ")"


def _seed_expr(
    parts: list, lo: int, hi: int, offset_sql: str, identity_base: int, suite: SuiteData
) -> str:
    # The parts are SQL text (variables already inlined); only embedded block
    # IDs and identity references are rewritten as expressions in n.i.
    out = []
    for part in _compile_parts(parts, lo, hi):
        if isinstance(part, int):
            out.append(f"({part} + {offset_sql})")
        elif isinstance(part, IdRef):
            count = suite.tables[part.table.lower()].identity_count
            out.append(f"({identity_base + part.seq} + n.i * {count})")
        else:
            out.append(part)
    return "".join(out)


def _write_fixup_sql(
    out_dir: Path,
    suite: SuiteData,
    copies: int,
    base_shift: int,
    identity_base: int,
    database: str,
) -> Path:
    plan = suite.plan
    blocks = {t.name: (t.block_start, t.block_start + BLOCK_SIZE) for t in plan.tests}
    offset_sql = _copy_offset_sql(plan, base_shift)
    lines = [
        "-- INSERTs whose values read seed data on the target database,",
        "-- generated set-based (one statement per deferred row, all copies).",
        "-- Run AFTER load.sql / load.sh.",
        f"USE [{database}];",
    ]
    for row in suite.deferred_rows:
        lo, hi = blocks[row.test]
        table = suite.tables[row.table_key]
        columns = list(row.columns) + [c for c, _ in row.seed_cols]
        exprs = [
            _value_expr(v, lo, hi, offset_sql, identity_base, suite) for v in row.values
        ] + [
            _seed_expr(parts, lo, hi, offset_sql, identity_base, suite)
            for _, parts in row.seed_cols
        ]
        lines.append(
            "WITH d AS (SELECT 0 AS z FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0)) v(z)),"
        )
        lines.append(
            f"     nums(i) AS (SELECT TOP ({copies}) "
            "ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 "
            "FROM d a, d b, d c, d e, d f, d g, d h, d j)"
        )
        lines.append(
            f"INSERT INTO [dbo].[{table.name}] ("
            + ", ".join(f"[{c}]" for c in columns)
            + ")"
        )
        lines.append("SELECT " + ",\n       ".join(exprs))
        lines.append("FROM nums AS n;")
    path = out_dir / "fixup.sql"
    path.write_text("\n".join(lines) + "\n")
    return path


def _reseed_tables(parts: list[TablePart]) -> list[str]:
    """Tables (deduped, in order) whose identity seeds need re-aligning."""
    seen = []
    for part in parts:
        name = part.table.name
        if part.table.identity_col and name not in seen:
            seen.append(name)
    return seen
