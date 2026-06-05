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
- [done] All modules built by parallel agents + cli.py glue; summarize() skip-table
  fix; 51 tests green; sample report in examples/. commit 2342c011
- [done] pymssql connectivity smoke OK: RDB(387 tables)/RDB_MODERN(539)/NBS_ODSE all
  present, cross-DB queries work.
- [WAITING] background live-run agent (id a1c6ac08fd6c58a03) populating RDB via
  MasterETL; watching for /tmp/rdb_compare_data_ready = READY. THEN run:
  `uv run rdb-compare --host localhost --port 3433 --user sa --rdb RDB --modern RDB_MODERN --out ./out`
  then review out/comparison.md, commit it as the morning deliverable, write a
  FINAL summary here, and PushNotification one line.
- NOTE: RDB already has 387 tables (schema present); MasterETL must finish loading
  DATA before the comparison is meaningful — wait for the sentinel.

## FINAL (2026-06-05, resumed after host OOM + scale-up to 61GB)

The overnight live-run agent died when the host ran out of RAM (stack down,
sentinel gone). Re-ran the whole stretch path from scratch on the scaled host:

1. **Stage 1** `merge_and_verify.sh` → RDB_MODERN populated via real CDC
   pipeline. Clean. **372 tables** with rows.
2. **Stage 2** `run_masteretl_local.sh` (extracted from `aw/masteretl-local-fixtures`)
   → RDB populated via SAS/MasterETL. **256 tables** with rows. Hit one infra
   snag: a stale `sas` container from before the reboot held a dead network ref
   (`network … not found`) — `docker rm -f` it, re-ran, clean start. MasterETL
   reported **123 SAS errors**, all condition-specific datamart failures for
   disease families our fixtures don't seed (BMIRD/strep-pneumo, ABCs,
   mother/congenital, datamart SPs with no matching investigation) — the
   expected partial-coverage mirror of RDB_MODERN's ~80%.
3. **Comparison** `rdb-compare … --out ./out` → `out/comparison.{json,md}`,
   copied to **`examples/live_comparison.{json,md}`** (out/ is gitignored) as the
   committed deliverable.

### Tool fix required to finish (the run hung twice before this)
`REF_FORMCODE_TRANSLATION` (RDB 158776 / MODERN 125548 rows) made the engine
hang >20min: `keys.resolve_keys` picked `NBS_QUESTION_UID`, a **non-unique**
reference column, so the cross-DB join fanned out near-cartesian (158k×125k). A
pymssql `--query-timeout` didn't help — the cost is in fetching the exploded
result, not query exec. Fixes (52 tests green):
- `engine.build_key_duplicate_probe_sql` + a guard in `compare_table`: before the
  fan-out-prone overlap/diff joins, a cheap `GROUP BY … HAVING COUNT(*)>1`
  uniqueness probe on **both** sides; non-unique key → degrade to counts-only
  (`error="key … not unique; counts only"`). 0.14s on the offender.
- `db.connect(timeout=)` + `--query-timeout` (default 120s) secondary safety.
- `--progress` per-table stderr lines (index/presence/rdb/modern/elapsed).
- reconnect-on-per-table-error so one bad table can't cascade.
Full 180-table run now completes in ~6min, no table >8s.

### Result: 180 tables compared, 0 skipped. 11 tables need attention.
NEW=149 col-diffs · KNOWN_BUG=3 · EXPECTED=0 · IGNORED=40. The classifier's
IGNORED (key-offset, env-timestamp) and KNOWN_BUG rules (LAB_TEST key-offset +
LAB_RPT_LAST_UPDATE_BY, D_INTERVIEW_NOTE not-populated) fired correctly. The 149
NEW are honest v1 output — the catalog's ExpectedDiff rules (transcribed from the
rtr-diffs page) didn't match these specific (table,col) pairs. They cluster:

- **~85 — `D_VAR_PAM`**: every Varicella-PAM column `value → NULL`. RDB
  (MasterETL) fully populated it; RTR populated none. Consistent with documented
  out-of-scope/blocked var-datamart SPs → **RTR coverage gap, not a value bug**.
  Top ExpectedDiff candidate.
- **encoding mojibake** in `*_COMMENTS` (INVESTIGATION/NOTIFICATION/TREATMENT,
  INV_COMMENTS): RDB `â€"` vs RDB_MODERN `—`. SAS `sas_encoding=latin1`
  mis-encodes the UTF-8 em-dash; **RTR is correct**. Systematic MasterETL
  data-quality artifact → ExpectedDiff/Ignore candidate.
- **NULL vs empty-string** (`D_ORGANIZATION` email/phone): representational →
  Ignore candidate.
- **`LAB_TEST`/`LAB_RESULT_VAL`/`TEST_RESULT_GROUPING`**: RTR populates *more*
  (rows 22→72, 19→97, 20→63) and fills lab metadata (jurisdiction, specimen,
  dates, ELR_IND) MasterETL leaves NULL — directional, **RTR more complete**.
  Confirm intended.
- **Genuine behavioral diffs to review**: `INVESTIGATION` (RTR adds
  hospitalization fields but drops INV_STATE_CASE_ID 28/31 and OUTBREAK_NAME_DESC),
  `D_PROVIDER` phone work/cell mapping, `D_TB_PAM.TB_VERCRIT_CALC_IND` NULL→FALSE.

### Presence (the cross-coverage picture)
- **5 RDB-only**: `CODESET`/`CODE_VAL_GENERAL` (reference) + `DM_INV_STD`/
  `DM_INV_HEPATITIS_B_PERINATAL`/`GEOCODING_LOCATION` (MasterETL-only per
  `catalog/odse_unknown_tables.md` → **expected RTR gaps**, exactly as predicted).
- **18 modern-only**: RTR datamarts/events MasterETL didn't emit (BMIRD/COVID/
  TB/HEPATITIS/MORBIDITY datamarts, SR100, SUMMARY_REPORT_CASE) — partly the 123
  SAS errors leaving those RDB tables empty.
- **65 both-populated with differing row counts** (mostly ±1–3 link/group
  cardinality; large ones are reference/infra: REF_FORMCODE_TRANSLATION,
  JOB_FLOW_LOG, RDB_TABLE_METADATA).

### Follow-ups for next pass
1. Add ExpectedDiff/Ignore rules for the three systematic buckets above
   (var-PAM RTR gap, em-dash latin1 mojibake, NULL-vs-empty) to cut NEW noise.
2. Improve `keys.resolve_keys` to skip/flag non-unique `*_UID` reference keys up
   front (the guard now catches them at runtime; better to not resolve them).
3. Triage the genuine INVESTIGATION/D_PROVIDER/lab-metadata directional diffs
   with the RTR team.
