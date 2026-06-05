"""Thin pymssql access layer for the RDB vs RDB_MODERN comparison.

Both databases live in the *same* SQL Server instance, so a single connection
(opened against ``master``) can reach either via three-part names
(``[db].dbo.[table]``, ``[db].sys.columns``). Every helper here is a small,
side-effect-free wrapper around a cursor; the comparison logic lives in
:mod:`rdb_compare.engine`.
"""

from __future__ import annotations

import pymssql


def connect(host, port, user, password, database="master", timeout=0):
    """Open an autocommit pymssql connection to the SQL Server instance.

    ``database`` defaults to ``master`` because the comparison reaches both RDB
    and RDB_MODERN through fully qualified three-part names rather than the
    connection's current database.

    ``timeout`` is the per-query timeout in seconds (0 = wait forever). A
    non-zero value lets a pathologically slow per-table comparison (an unindexed
    cross-DB join over a large reference table) abort and be recorded as a
    per-table error instead of hanging the whole run.
    """
    return pymssql.connect(
        server=host,
        port=str(port),
        user=user,
        password=password,
        database=database,
        autocommit=True,
        timeout=timeout,
    )


def list_tables(conn, db):
    """Return the set of UPPERCASE base-table names in database ``db``."""
    sql = (
        f"SELECT TABLE_NAME FROM [{db}].INFORMATION_SCHEMA.TABLES "
        "WHERE TABLE_TYPE = 'BASE TABLE'"
    )
    return {row["TABLE_NAME"].upper() for row in run_query(conn, sql)}


def list_columns(conn, db, table):
    """Return ``table``'s column names in ordinal order, excluding computed ones.

    Uses ``[db].sys.columns`` joined to ``[db].sys.tables`` so the lookup is
    scoped to the right database even though the connection points at
    ``master``.
    """
    sql = (
        "SELECT c.name AS name "
        f"FROM [{db}].sys.columns AS c "
        f"INNER JOIN [{db}].sys.tables AS t ON c.object_id = t.object_id "
        f"WHERE t.name = '{table}' AND c.is_computed = 0 "
        "ORDER BY c.column_id"
    )
    return [row["name"] for row in run_query(conn, sql)]


def run_query(conn, sql):
    """Execute ``sql`` and return all rows as a list of ``{column: value}`` dicts."""
    with conn.cursor(as_dict=True) as cur:
        cur.execute(sql)
        return cur.fetchall()
