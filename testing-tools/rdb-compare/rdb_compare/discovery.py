"""Table discovery for the RDB vs RDB_MODERN comparison.

The comparison only runs on tables that exist in *both* databases. This module
computes that common set, drops the structurally uninteresting tables the rule
registry skips (ETL/event/lookup/staging/SAS/temp, RDB_MODERN-only tables, etc.),
and applies optional caller-supplied include/exclude globs.
"""

from __future__ import annotations

from fnmatch import fnmatchcase

from rdb_compare import db


def discover(conn, rdb_db, modern_db, registry, include=None, exclude=None):
    """Return the sorted list of tables to compare.

    Starts from the intersection of the tables present in ``rdb_db`` and
    ``modern_db``, then:

    * drops any table the ``registry`` marks skipped
      (:meth:`~rdb_compare.rules.RuleRegistry.is_skipped`);
    * if ``include`` globs are given, keeps only tables matching at least one;
    * if ``exclude`` globs are given, drops tables matching at least one.

    Glob matching is case-insensitive via :func:`fnmatch.fnmatchcase` on
    upper-cased table names (SQL Server's default collation behaviour).

    :param conn: an open DB connection (passed through to :mod:`rdb_compare.db`).
    :param rdb_db: legacy RDB database name.
    :param modern_db: modern RDB_MODERN database name.
    :param registry: a :class:`~rdb_compare.rules.RuleRegistry`.
    :param include: optional iterable of glob patterns to keep.
    :param exclude: optional iterable of glob patterns to drop.
    :returns: sorted list of table names common to both databases and surviving
        the skip rules and include/exclude filters.
    """
    rdb_tables = db.list_tables(conn, rdb_db)
    modern_tables = db.list_tables(conn, modern_db)
    common = set(rdb_tables) & set(modern_tables)

    include = list(include) if include else None
    exclude = list(exclude) if exclude else None

    kept: list[str] = []
    for table in common:
        if registry.is_skipped(table):
            continue
        upper = table.upper()
        if include is not None and not any(
            fnmatchcase(upper, p.upper()) for p in include
        ):
            continue
        if exclude is not None and any(
            fnmatchcase(upper, p.upper()) for p in exclude
        ):
            continue
        kept.append(table)

    return sorted(kept)
