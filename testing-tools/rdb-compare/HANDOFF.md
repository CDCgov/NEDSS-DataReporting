# Handoff — run the RDB vs RDB_MODERN comparison from a clean slate

Goal: produce `testing-tools/rdb-compare/out/comparison.{json,md}` — a diff of the
legacy **RDB** (MasterETL output) against **RDB_MODERN** (the modern RTR/CDC
pipeline output), both populated from the SAME synthetic `NBS_ODSE` fixtures.

## TL;DR — one command

```sh
cd /home/ec2-user/NEDSS-DataReporting
./testing-tools/rdb-compare/scripts/clean_slate_to_comparison.sh
```

That runs all three stages in the required order and writes the report. Read the
script header for flags (`--skip-merge`, `--skip-masteretl`, `--compare-only`,
`--keep-pipeline`).

## The three stages (order matters)

1. **`testing-tools/synthetic-odse-fixtures/scripts/merge_and_verify.sh`** → populates
   **RDB_MODERN** via the real pipeline (SQL Server CDC → Debezium → Kafka →
   kafka-connect → `nrt_*` → `sp_*_postprocessing`). It does `docker compose
   down -v` FIRST, so it **wipes everything incl. RDB** — therefore it MUST run
   before MasterETL. ~5–20 min. Brings up mssql/kafka/connect/debezium/
   reporting-pipeline-service/wildfly/liquibase (NOT sas).
2. **`testing-tools/synthetic-odse-fixtures/scripts/run_masteretl_local.sh`** → populates
   **RDB** via the legacy SAS/MasterETL container from the same NBS_ODSE. This is
   the heavy/RAM step (the SAS container). The script lives on branch
   `aw/masteretl-local-fixtures`; the orchestrator auto-extracts it if missing.
3. **`uv run rdb-compare --host localhost --port 3433 --user sa --rdb RDB
   --modern RDB_MODERN --out ./out --progress --query-timeout 120`** (run from
   `testing-tools/rdb-compare/`) → the report.

## Key facts / gotchas

- **DB:** one mssql instance, `localhost,3433`, `sa` / `PizzaIsGood33!`. RDB and
  RDB_MODERN are two databases in it → cross-DB joins work. `sqlcmd` via
  `docker compose exec -T nbs-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost
  -U sa -P 'PizzaIsGood33!' -C ...`.
- **RAM:** the OOM risk is the full CDC stack **+** the SAS container at once.
  The orchestrator stops the CDC services after stage 1 (RDB_MODERN is already
  persisted in mssql) so only mssql+SAS are up for MasterETL. Still, size the
  host generously; watch `docker stats`. A bare `merge_and_verify` peaks ~6–7 GB.
- **MasterETL exits non-zero (~100+ SAS errors) and that's EXPECTED** — they are
  condition-specific datamarts for disease families the fixtures don't seed
  (BMIRD/strep, ABCs, congenital). RDB still populates ~250 tables. Verify RDB by
  row counts (`RDB.dbo.INVESTIGATION > 0`), NOT by exit code.
- **Stale SAS container:** a leftover `nedss-datareporting-sas-1` from a prior run
  holds a dead network ref → `network ... not found`. Fix: `docker rm -f
  nedss-datareporting-sas-1` then retry. (The orchestrator does this.)
- **rdb-compare** already has: `--progress` (per-table stderr), `--query-timeout`,
  and a non-unique-key guard that prevents cartesian-join hangs on reference
  tables (e.g. `REF_FORMCODE_TRANSLATION`). Tests: `cd testing-tools/rdb-compare &&
  uv run pytest -q`.

## Interpreting the report

`out/comparison.md` classifies each diff NEW / KNOWN_BUG / EXPECTED / IGNORED via
the rule catalog (`rdb_compare/rules/catalog.py`). Context for the NEW ones:
- A prior real run is committed at `testing-tools/rdb-compare/examples/live_comparison.{json,md}`,
  with the full finding breakdown in `testing-tools/rdb-compare/LOOP.md` (FINAL section).
- NEW diffs cluster predictably: **encoding mojibake** in `*_COMMENTS` (SAS
  `latin1` mangles UTF-8 em-dashes — RTR is correct); **NULL vs empty-string**;
  **`D_VAR_PAM`-style** value→NULL where one side doesn't populate a PAM datamart;
  **lab metadata** where RTR is more complete than MasterETL.
- **Presence gaps** (RDB-only / MODERN-only tables) are often legitimate
  RTR-vs-MasterETL coverage differences, not bugs — `testing-tools/synthetic-odse-fixtures/
  catalog/odse_unknown_tables.md` lists the 22 MasterETL-only tables.

## Important context about RDB_MODERN's provenance (do not regress)

All `comparison-fixtures` fixtures are now **ODSE-only**: they author only
`NBS_ODSE` rows and the RTR pipeline derives everything in RDB_MODERN (no direct
`nrt_*`/`D_*`/`F_*`/`*_DATAMART` writes). This makes RDB_MODERN a faithful measure
of the real pipeline. See `testing-tools/synthetic-odse-fixtures/ODSE_ONLY_CONVERSION.md`.
If you add or edit a fixture, keep it ODSE-only — verify with the scan in that
doc; do not reintroduce direct RDB_MODERN writes.
