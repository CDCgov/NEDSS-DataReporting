"""The cross-database comparison engine.

Given a table and its business/UID key column(s), the engine builds the T-SQL
that joins ``RDB.dbo.<table>`` against ``RDB_MODERN.dbo.<table>`` on those keys
and reports, per value column, the rows whose values differ (NULL-aware). It
then runs that SQL through :mod:`rdb_compare.db` and folds the raw rows into the
shared :class:`~rdb_compare.models.TableResult` / :class:`ColumnDiff` /
:class:`CellDiff` contract.

The SQL mirrors the canonical comparison templates: identifiers are
bracket-quoted, values are cast to ``NVARCHAR(4000)``, and the difference test is
the NULL-safe ``EXISTS (SELECT L.[col] EXCEPT SELECT M.[col])`` -- true exactly
when the two values differ, with ``NULL`` treated as equal to ``NULL``.
"""

from __future__ import annotations

from typing import Optional

from rdb_compare import db
from rdb_compare.models import CellDiff, ColumnDiff, Presence, TableResult


def _qualified(database: str, table: str) -> str:
    """Three-part, bracket-quoted ``[db].dbo.[table]`` name."""
    return f"[{database}].[dbo].[{table}]"


def build_value_diff_sql(table, key_cols, value_cols, rdb_db, modern_db):
    """Build the per-column value-difference SQL for one table.

    Returns a single ``UNION ALL`` statement with one branch per value column.
    Each branch INNER JOINs ``rdb_db`` (``L``) to ``modern_db`` (``M``) on the
    key column(s), emits ``(key columns..., column_name, rdb_value,
    modern_value)`` cast to ``NVARCHAR(4000)``, and is filtered to only the rows
    where ``L.[col]`` and ``M.[col]`` differ via the NULL-safe
    ``EXISTS (SELECT L.[col] EXCEPT SELECT M.[col])`` test.
    """
    left = _qualified(rdb_db, table)
    right = _qualified(modern_db, table)

    join_on = " AND ".join(f"L.[{k}] = M.[{k}]" for k in key_cols)
    key_select = ", ".join(
        f"CAST(L.[{k}] AS NVARCHAR(4000)) AS [{k}]" for k in key_cols
    )

    branches = []
    for col in value_cols:
        branches.append(
            f"SELECT {key_select}, "
            f"N'{col}' AS [column_name], "
            f"CAST(L.[{col}] AS NVARCHAR(4000)) AS [rdb_value], "
            f"CAST(M.[{col}] AS NVARCHAR(4000)) AS [modern_value]\n"
            f"FROM {left} AS L\n"
            f"INNER JOIN {right} AS M ON {join_on}\n"
            f"WHERE EXISTS (SELECT L.[{col}] EXCEPT SELECT M.[{col}])"
        )

    return "\nUNION ALL\n".join(branches)


def build_count_sql(table, db):
    """Build a ``SELECT COUNT(*)`` over ``[db].dbo.[table]``."""
    return f"SELECT COUNT(*) AS [n] FROM {_qualified(db, table)}"


def build_key_duplicate_probe_sql(table, key_cols, db):
    """Build SQL that returns one row iff the key is *non-unique* in ``db``.

    A resolved ``*_UID`` / ``*_LOCAL_ID`` key is only a valid join key if it
    uniquely identifies a row. On reference / lookup tables a ``*_UID`` column
    can repeat across many rows; joining ``RDB`` to ``RDB_MODERN`` on such a key
    fans out into a many-to-many (near-cartesian) product that can balloon to
    billions of row pairs and hang the run. This probe -- a cheap single-scan
    ``GROUP BY ... HAVING COUNT(*) > 1`` capped at one row -- lets the engine
    detect that case up front and degrade to counts-only instead.
    """
    keys = ", ".join(f"[{k}]" for k in key_cols)
    not_null = " AND ".join(f"[{k}] IS NOT NULL" for k in key_cols)
    return (
        f"SELECT TOP 1 1 AS [dup] FROM {_qualified(db, table)} "
        f"WHERE {not_null} "
        f"GROUP BY {keys} HAVING COUNT(*) > 1"
    )


def build_key_overlap_sql(table, key_cols, rdb_db, modern_db):
    """Build SQL returning ``matched_keys``, ``rdb_only_keys``, ``modern_only_keys``.

    Rows with a NULL key are excluded on both sides (they cannot be matched), so
    the three counts are computed safely against non-NULL keys only.
    """
    left = _qualified(rdb_db, table)
    right = _qualified(modern_db, table)

    join_on = " AND ".join(f"L.[{k}] = M.[{k}]" for k in key_cols)
    l_not_null = " AND ".join(f"L.[{k}] IS NOT NULL" for k in key_cols)
    m_not_null = " AND ".join(f"M.[{k}] IS NOT NULL" for k in key_cols)
    # Correlated NOT EXISTS predicates for the "only" counts.
    no_match_in_modern = " AND ".join(f"M.[{k}] = L.[{k}]" for k in key_cols)
    no_match_in_rdb = " AND ".join(f"L.[{k}] = M.[{k}]" for k in key_cols)

    return (
        "SELECT\n"
        f"  (SELECT COUNT(*) FROM {left} AS L "
        f"INNER JOIN {right} AS M ON {join_on} "
        f"WHERE {l_not_null} AND {m_not_null}) AS [matched_keys],\n"
        f"  (SELECT COUNT(*) FROM {left} AS L "
        f"WHERE {l_not_null} AND NOT EXISTS "
        f"(SELECT 1 FROM {right} AS M WHERE {no_match_in_modern})) AS [rdb_only_keys],\n"
        f"  (SELECT COUNT(*) FROM {right} AS M "
        f"WHERE {m_not_null} AND NOT EXISTS "
        f"(SELECT 1 FROM {left} AS L WHERE {no_match_in_rdb})) AS [modern_only_keys]"
    )


def compare_table(
    conn,
    table,
    key_cols,
    value_cols,
    rdb_db,
    modern_db,
    sample_cap=20,
) -> TableResult:
    """Compare one table across the two databases and return a :class:`TableResult`.

    Populates row counts, key overlap, presence and -- when ``key_cols`` is
    usable -- one :class:`ColumnDiff` per value column that has any mismatch
    (``compared`` = matched keys, ``mismatches`` = differing rows, ``samples``
    capped at ``sample_cap`` :class:`CellDiff`). With no usable key the result
    carries only counts + presence and ``error`` is set. Any per-table SQL error
    is caught and recorded on ``result.error``.
    """
    result = TableResult(table=table, key_columns=tuple(key_cols or ()))

    try:
        rdb_rows = db.run_query(conn, build_count_sql(table, rdb_db))
        modern_rows = db.run_query(conn, build_count_sql(table, modern_db))
        result.rdb_count = rdb_rows[0]["n"] if rdb_rows else 0
        result.modern_count = modern_rows[0]["n"] if modern_rows else 0

        if result.rdb_count and not result.modern_count:
            result.presence = Presence.RDB_ONLY
        elif result.modern_count and not result.rdb_count:
            result.presence = Presence.MODERN_ONLY
        else:
            result.presence = Presence.BOTH

        if not key_cols:
            result.error = "no usable key; counts only"
            return result

        # Guard against a non-unique resolved key: joining on a key that repeats
        # (common on reference / lookup tables whose *_UID column is a FK, not a
        # row id) fans the comparison out into a near-cartesian product. Detect
        # it cheaply on either side and degrade to counts-only rather than hang.
        for side_db in (rdb_db, modern_db):
            dup = db.run_query(
                conn, build_key_duplicate_probe_sql(table, key_cols, side_db)
            )
            if dup:
                result.error = (
                    f"key {'+'.join(key_cols)} not unique in {side_db}; "
                    "counts only (would fan out)"
                )
                return result

        overlap = db.run_query(
            conn, build_key_overlap_sql(table, key_cols, rdb_db, modern_db)
        )
        if overlap:
            result.matched_keys = overlap[0].get("matched_keys", 0) or 0
            result.rdb_only_keys = overlap[0].get("rdb_only_keys", 0) or 0
            result.modern_only_keys = overlap[0].get("modern_only_keys", 0) or 0

        if not value_cols:
            return result

        diff_rows = db.run_query(
            conn,
            build_value_diff_sql(table, key_cols, value_cols, rdb_db, modern_db),
        )

        by_column: dict[str, ColumnDiff] = {}
        for row in diff_rows:
            col_name = row["column_name"]
            col = by_column.get(col_name)
            if col is None:
                col = ColumnDiff(
                    table=table, column=col_name, compared=result.matched_keys
                )
                by_column[col_name] = col
            col.mismatches += 1
            if len(col.samples) < sample_cap:
                key = tuple(row[k] for k in key_cols)
                col.samples.append(
                    CellDiff(
                        table=table,
                        key=key,
                        column=col_name,
                        rdb_value=row["rdb_value"],
                        modern_value=row["modern_value"],
                    )
                )

        # Preserve value_cols ordering for stable, readable output.
        result.columns = [
            by_column[c] for c in value_cols if c in by_column
        ]
    except Exception as exc:  # per-table isolation: one bad table != run failure
        result.error = str(exc)

    return result
