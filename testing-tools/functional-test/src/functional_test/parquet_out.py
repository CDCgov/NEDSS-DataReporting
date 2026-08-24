"""Parquet + OPENROWSET output for --bulk.

Targets SQL Server 2022+, modeled on the odse-volume-generator load pipeline:

  * Rows are written as Parquet (string columns; the server converts in the
    INSERT..SELECT). Parquet distinguishes NULL from empty string and needs
    no terminator or timestamp workarounds.
  * Each table part loads with one set-based statement per shard file:
    INSERT INTO t (cols) SELECT cols FROM OPENROWSET(BULK ..., PARQUET).
    The explicit column list handles column subsets directly — no views.
    Files must be visible to the SERVER (e.g. the compose bind mount).
  * Generation is sharded over worker processes: copy range [start, start+n)
    is deterministic (offsets and identity values are pure functions of the
    global copy index), so shards are generated and loaded independently.
  * --manage-indexes emits pre/post scripts that disable non-unique
    nonclustered indexes on the target tables during the load and rebuild
    them after — the same dynamic-SQL approach as odse-volume-generator.

Output layout: <Part>__s<K>.parquet per shard, shard_<K>.sql per shard,
pre.sql / post.sql, fixup.sql (set-based, from bulkgen), load.sql (sequential
all-in-one) and load.sh (parallel shard loaders via xargs -P).
"""

from __future__ import annotations

import multiprocessing as mp
from pathlib import Path
from typing import Callable, Optional

from .bulkgen import (
    SuiteData,
    TablePart,
    _compile_rows,
    _render_field,
    _reseed_tables,
    _write_fixup_sql,
    build_ordered_parts,
)

FLUSH_EVERY_ROWS = 100_000


def _shard_ranges(copies: int, workers: int) -> list[tuple[int, int, int]]:
    """(shard_index, start, count) covering [0, copies) contiguously."""
    workers = max(1, min(workers, copies))
    base, extra = divmod(copies, workers)
    ranges = []
    start = 0
    for shard in range(workers):
        count = base + (1 if shard < extra else 0)
        ranges.append((shard, start, count))
        start += count
    return ranges


def _shard_file(part: TablePart, shard: int) -> str:
    return f"{part.name}__s{shard:03d}.parquet"


class _PartWriter:
    """Buffered Parquet writer for one table part (all columns as strings)."""

    def __init__(self, path: Path, columns: list[str]):
        import pyarrow as pa
        import pyarrow.parquet as pq

        self._pa = pa
        self.columns = columns
        self.schema = pa.schema([(c, pa.string()) for c in columns])
        self.writer = pq.ParquetWriter(path, self.schema)
        self.buffer: list[list[Optional[str]]] = [[] for _ in columns]
        self.rows = 0
        # Longest value per column: OPENROWSET's default inference caps
        # strings at VARCHAR(8000), so wide columns (EDX XML payloads) need
        # an explicit NVARCHAR(MAX) in the load statement's WITH schema.
        self.max_len = [0] * len(columns)

    def append(self, fields: list[Optional[str]]) -> None:
        for i, (column, value) in enumerate(zip(self.buffer, fields)):
            column.append(value)
            if value is not None and len(value) > self.max_len[i]:
                self.max_len[i] = len(value)
        self.rows += 1
        if len(self.buffer[0]) >= FLUSH_EVERY_ROWS:
            self.flush()

    def flush(self) -> None:
        if self.buffer and self.buffer[0]:
            arrays = [self._pa.array(col, type=self._pa.string()) for col in self.buffer]
            self.writer.write_table(self._pa.Table.from_arrays(arrays, schema=self.schema))
            self.buffer = [[] for _ in self.columns]

    def close(self) -> None:
        self.flush()
        self.writer.close()


def write_shard(
    suite: SuiteData,
    out_dir: Path,
    shard: int,
    start: int,
    count: int,
    base_shift: int = 0,
    identity_base: int = 500_000_000,
    on_progress: Optional[Callable[[int], None]] = None,
) -> dict[str, list[int]]:
    """Render global copies [start, start+count) into this shard's files.

    Returns per-part max value length per column (for the load schemas).
    """
    part_map, all_parts = build_ordered_parts(suite)
    compiled_by_test = _compile_rows(suite, part_map)

    writers = {
        part.name: _PartWriter(out_dir / _shard_file(part, shard), part.columns)
        for part in all_parts
    }
    try:
        for copy_index in range(start, start + count):
            offset = suite.plan.offset_for(copy_index, base_shift)
            id_base = {
                key: identity_base + copy_index * table.identity_count
                for key, table in suite.tables.items()
                if table.identity_count
            }
            for test in suite.plan.tests:
                for row in compiled_by_test[test.name]:
                    writers[row.part.name].append([
                        None if f is None else _render_field(f, offset, id_base)
                        for f in row.fields
                    ])
            if on_progress:
                on_progress(copy_index - start + 1)
    finally:
        for writer in writers.values():
            writer.close()
    return {name: w.max_len for name, w in writers.items()}


def _shard_worker(args) -> tuple[int, dict[str, list[int]]]:
    suite, out_dir, shard, start, count, base_shift, identity_base = args
    max_lens = write_shard(
        suite, Path(out_dir), shard, start, count,
        base_shift=base_shift, identity_base=identity_base,
    )
    return shard, max_lens


# ---------------------------------------------------------------------------
# Load scripts


_INDEX_FILTER = "i.type_desc = 'NONCLUSTERED' AND i.is_unique = 0 AND i.is_primary_key = 0"


def _index_batch(tables: list[str], action: str) -> list[str]:
    table_list = ", ".join(f"'{t}'" for t in tables)
    return [
        "DECLARE @sql nvarchar(max) = N'';",
        f"SELECT @sql += N'ALTER INDEX ' + QUOTENAME(i.name) + N' ON dbo.'",
        f"    + QUOTENAME(t.name) + N' {action};' + CHAR(10)",
        "FROM sys.indexes i JOIN sys.tables t ON t.object_id = i.object_id",
        f"WHERE t.name IN ({table_list}) AND {_INDEX_FILTER};",
        "EXEC sp_executesql @sql;",
    ]


def _sql_type(max_len: int) -> str:
    # OPENROWSET's inferred VARCHAR(8000) truncates wide values (EDX XML
    # payloads), so every load states an explicit schema sized from the
    # actual data; MAX only where needed (LOB handling costs on small cols).
    return "NVARCHAR(MAX)" if max_len > 4000 else "NVARCHAR(4000)"


def _part_batch(part: TablePart, shard: int, max_lens: list[int]) -> list[str]:
    """One GO-terminated batch loading one part, with deadlock retry.

    Parallel shards inserting into the same tables deadlock under lock
    escalation; error 1205 is retryable by definition, so retry it a few
    times and re-raise anything else.
    """
    table = part.table.name
    columns = ", ".join(f"[{c}]" for c in part.columns)
    with_schema = ", ".join(
        f"[{c}] {_sql_type(m)}" for c, m in zip(part.columns, max_lens)
    )
    insert = (
        f"INSERT INTO [dbo].[{table}] ({columns}) "
        f"SELECT {columns} "
        f"FROM OPENROWSET(BULK N'$(DataDir)/{_shard_file(part, shard)}', "
        f"FORMAT = 'PARQUET') WITH ({with_schema}) AS r;"
    )
    # Explicit values for an identity column need IDENTITY_INSERT (the
    # OPENROWSET path has no KEEPIDENTITY option). Guarded so a target where
    # the column is not actually IDENTITY still loads.
    guard = f"OBJECTPROPERTY(OBJECT_ID(N'dbo.{table}'), 'TableHasIdentity') = 1"
    identity_on = f"        IF {guard} SET IDENTITY_INSERT [dbo].[{table}] ON;"
    identity_off = f"        IF {guard} SET IDENTITY_INSERT [dbo].[{table}] OFF;"

    lines = ["DECLARE @attempt int = 0;", "WHILE 1 = 1", "BEGIN", "    BEGIN TRY"]
    if part.keep_identity:
        lines.append(identity_on)
    lines.append("        " + insert)
    if part.keep_identity:
        lines.append(identity_off)
    lines += ["        BREAK;", "    END TRY", "    BEGIN CATCH"]
    if part.keep_identity:
        lines.append(identity_off)
    lines += [
        "        IF ERROR_NUMBER() <> 1205 OR @attempt >= 5 THROW;",
        "        SET @attempt += 1;",
        "        WAITFOR DELAY '00:00:02';",
        "    END CATCH",
        "END",
        "GO",
    ]
    return lines


def _shard_sql_lines(
    parts: list[TablePart],
    shard: int,
    total_shards: int,
    database: str,
    col_max: dict[str, list[int]],
) -> list[str]:
    # Rotate each shard's starting point so concurrent shards work on
    # different tables instead of all hammering the same one. Order within a
    # load doesn't matter for integrity: FK checking is disabled by pre.sql
    # (as bcp's bulk path always implicitly did).
    rotation = (shard * len(parts)) // max(1, total_shards)
    ordered = parts[rotation:] + parts[:rotation]
    lines = [f"USE [{database}];", "GO"]
    for part in ordered:
        lines.extend(_part_batch(part, shard, col_max[part.name]))
    return lines


def write_load_scripts(
    suite: SuiteData,
    out_dir: Path,
    copies: int,
    shards: list[tuple[int, int, int]],
    base_shift: int,
    identity_base: int,
    database: str,
    manage_indexes: bool,
    col_max: dict[str, list[int]],
) -> list[Path]:
    _, all_parts = build_ordered_parts(suite)
    tables = []
    for part in all_parts:
        if part.table.name not in tables:
            tables.append(part.table.name)
    written: list[Path] = []

    pre = [f"USE [{database}];"]
    pre.append("-- Skip FK/CHECK validation during the load, as bcp's bulk path")
    pre.append("-- implicitly does (rows reference IDs within their own copy, and")
    pre.append("-- shards load tables in rotated order for less lock contention).")
    for table in tables:
        pre.append(f"ALTER TABLE [dbo].[{table}] NOCHECK CONSTRAINT ALL;")
    if manage_indexes:
        pre.append("-- Drop per-row index maintenance during the load.")
        pre.extend(_index_batch(tables, "DISABLE"))
    (out_dir / "pre.sql").write_text("\n".join(pre) + "\n")
    written.append(out_dir / "pre.sql")

    shard_paths = []
    for shard, _start, _count in shards:
        path = out_dir / f"shard_{shard:03d}.sql"
        path.write_text(
            "\n".join(
                _shard_sql_lines(all_parts, shard, len(shards), database, col_max)
            ) + "\n"
        )
        shard_paths.append(path)
        written.append(path)

    post = [f"USE [{database}];"]
    post.append("-- Re-enable constraints without validating existing rows (they")
    post.append("-- stay untrusted — the same end-state a bcp/BULK INSERT load has).")
    for table in tables:
        post.append(f"ALTER TABLE [dbo].[{table}] WITH NOCHECK CHECK CONSTRAINT ALL;")
    if manage_indexes:
        post.extend(_index_batch(tables, "REBUILD"))
    reseed = _reseed_tables(all_parts)
    if reseed:
        post.append("-- Re-align identity seeds after explicit-identity load.")
        for name in reseed:
            post.append(f"DBCC CHECKIDENT ('[dbo].[{name}]');")
    (out_dir / "post.sql").write_text("\n".join(post) + "\n")
    written.append(out_dir / "post.sql")

    has_fixup = bool(suite.deferred_rows)
    if has_fixup:
        written.append(_write_fixup_sql(
            out_dir, suite, copies, base_shift, identity_base, database
        ))

    # Sequential all-in-one variant for plain `sqlcmd -i load.sql`.
    combined = ["-- Sequential load; load.sh runs the shards in parallel instead.",
                ":setvar DataDir ."]
    for path in [out_dir / "pre.sql", *shard_paths, out_dir / "post.sql"]:
        combined.append(f"-- --- {path.name} ---")
        combined.extend(path.read_text().splitlines())
    if has_fixup:
        combined.append("-- Then run fixup.sql (seed-data-dependent INSERTs).")
    (out_dir / "load.sql").write_text("\n".join(combined) + "\n")
    written.append(out_dir / "load.sql")

    load_sh = [
        "#!/bin/sh",
        "# Parallel OPENROWSET load (SQL Server 2022+). The server must see the",
        "# .parquet files at DATA_DIR (e.g. a bind mount into the container).",
        "# Usage: SERVER=host,port DBUSER=sa DBPASSWORD=... DATA_DIR=/staging/bulkdata sh load.sh",
        "#   LOAD_WORKERS=6 controls parallel shard loaders;",
        "#   mssql-tools18 users: SQLCMD_OPTS=-C to trust a self-signed certificate.",
        "set -e",
        'cd "$(dirname "$0")"',
        ': "${SERVER:?set SERVER=host,port}" "${DBUSER:?set DBUSER}" "${DBPASSWORD:?set DBPASSWORD}"',
        ': "${DATA_DIR:?set DATA_DIR=server-visible path to the .parquet files}"',
        'SQLCMD="${SQLCMD:-sqlcmd}"',
        'LOAD_WORKERS="${LOAD_WORKERS:-6}"',
        'run_sqlcmd() { "$SQLCMD" -S "$SERVER" -U "$DBUSER" -P "$DBPASSWORD" $SQLCMD_OPTS '
        '-b -v DataDir="$DATA_DIR" -i "$1"; }',
        "run_sqlcmd pre.sql",
        'ls shard_*.sql | xargs -P "$LOAD_WORKERS" -I{} sh -c \''
        '"$0" -S "$1" -U "$2" -P "$3" $4 -b -v DataDir="$5" -i "{}"\' '
        '"$SQLCMD" "$SERVER" "$DBUSER" "$DBPASSWORD" "$SQLCMD_OPTS" "$DATA_DIR"',
        "run_sqlcmd post.sql",
    ]
    if has_fixup:
        load_sh.append("run_sqlcmd fixup.sql")
    load_sh.append('echo "bulk load complete"')
    (out_dir / "load.sh").write_text("\n".join(load_sh) + "\n")
    written.append(out_dir / "load.sh")
    return written


def write_bulk_parquet(
    suite: SuiteData,
    out_dir: Path,
    copies: int,
    base_shift: int = 0,
    identity_base: int = 500_000_000,
    database: str = "NBS_ODSE",
    workers: int = 1,
    manage_indexes: bool = False,
    on_progress: Optional[Callable[[int, int], None]] = None,
) -> list[Path]:
    """Write sharded Parquet plus the load scripts; returns written paths.

    ``on_progress`` receives (shards_done, total_shards).
    """
    out_dir.mkdir(parents=True, exist_ok=True)
    shards = _shard_ranges(copies, workers)
    col_max: dict[str, list[int]] = {}

    def merge(shard_max: dict[str, list[int]]) -> None:
        for name, lens in shard_max.items():
            current = col_max.setdefault(name, [0] * len(lens))
            col_max[name] = [max(a, b) for a, b in zip(current, lens)]

    if len(shards) == 1:
        merge(write_shard(suite, out_dir, 0, 0, copies,
                          base_shift=base_shift, identity_base=identity_base))
        if on_progress:
            on_progress(1, 1)
    else:
        specs = [
            (suite, str(out_dir), shard, start, count, base_shift, identity_base)
            for shard, start, count in shards
        ]
        done = 0
        with mp.Pool(len(shards)) as pool:
            for _shard, shard_max in pool.imap_unordered(_shard_worker, specs):
                merge(shard_max)
                done += 1
                if on_progress:
                    on_progress(done, len(shards))

    _, all_parts = build_ordered_parts(suite)
    written = [
        out_dir / _shard_file(part, shard)
        for part in all_parts
        for shard, _s, _c in shards
    ]
    written.extend(write_load_scripts(
        suite, out_dir, copies, shards, base_shift, identity_base,
        database, manage_indexes, col_max,
    ))
    return written
