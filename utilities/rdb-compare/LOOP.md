# rdb-compare — overnight build loop journal

Goal (by morning): a working, tested `rdb-compare` tool **and**, if the live
pipeline cooperates, a *real* RDB-vs-RDB_MODERN comparison report on disk.

## Deliverables (priority order)
1. **Guaranteed**: working tool (engine, db, discovery, keys, report, cli) +
   declarative rule catalog + green unit suite + a *sample* report rendered from
   synthetic results (no DB needed).
2. **Stretch (the thing on the desk)**: real `out/comparison.{json,md}` from a
   live run.

## Live-run workflow (the stretch path)
1. `utilities/comparison-fixtures/scripts/merge_and_verify.sh` — `down -v`, bring
   up the stack (mssql/kafka/connect/debezium/reporting-pipeline-service),
   liquibase, apply fixtures through real CDC → populates **RDB_MODERN**.
2. `utilities/comparison-fixtures/scripts/run_masteretl_local.sh` (lives on branch
   `aw/masteretl-local-fixtures`) — brings up SAS, fixes the autoexec password
   bug, runs MasterETL → populates **RDB** from the same NBS_ODSE.
3. `uv run rdb-compare --host localhost --port 3433 --user sa --rdb RDB --modern RDB_MODERN --out ./out`

DB: `localhost,3433`, `sa` / `PizzaIsGood33!`. RDB + RDB_MODERN are two databases
in the one `nedss-datareporting-nbs-mssql-1` instance → cross-DB joins work.

## Architecture / integration contract (modules build against this)
- `models.py` (DONE): `Verdict`, `Classification`, `CellDiff`, `ColumnDiff`,
  `Presence`, `TableResult`, `RunReport`.
- `rules/` (DONE): `RuleRegistry` + `SkipTableRule/IgnoreColumnRule/`
  `ExpectedDiffRule/KnownBugRule` + `predicates`. `classify_run(report, registry)`.
- `db.py` (TODO): `connect(host,port,user,password) -> conn`;
  `list_tables(conn, db) -> set[str]`; `list_columns(conn, db, table) -> list[str]`
  (exclude computed); `run_query(conn, sql) -> list[dict]`. Uses pymssql.
- `engine.py` (TODO): `build_compare_sql(table, key_cols, value_cols, rdb_db,
  modern_db) -> str` (cross-DB join, NULL-aware per-column is_match — UNIT
  TESTABLE); `compare_table(conn, table, key_cols, rdb_db, modern_db, sample_cap)
  -> TableResult` (counts, presence, per-column ColumnDiff with capped samples).
- `discovery.py` (TODO): `discover(conn, rdb_db, modern_db, registry,
  include=None, exclude=None) -> list[str]` (intersection of tables present in
  both, minus skip-rule tables; respect include/exclude globs).
- `keys.py` (TODO): `KEY_CONFIG: dict[str, tuple]` seeded from the PDF + RDB
  schema conventions; `resolve_keys(table, available_columns) -> tuple|None`.
  Prefer configured keys; else `*_LOCAL_ID`; else `*_UID` (NOT surrogate `*_KEY`,
  which carry offsets); else None (compare counts/existence only, warn).
- `report.py` (TODO): `to_dict(report)`, `write_json(report, path)`,
  `write_markdown(report, path)` (per-table summary, per-column mismatch counts,
  sample rows, verdict badges, NEW-first ordering).
- `cli.py` (TODO): argparse → connect, discover, resolve keys, compare each,
  classify_run, write outputs, print summary.
- `rules/catalog.py` (TODO): `build_default_registry() -> RuleRegistry` — all
  skip/ignore/expected/known-bug rules transcribed from
  `/tmp/rtr-diffs.txt` (the reporting-differences page).

## Status log
- [done] Scaffold + models + rule registry + classifier; 13 tests green. commit b811d7d4
