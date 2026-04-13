# Local Database CDC Tracing

This directory contains a local investigation tool for tracing SQL Server Change Data Capture (CDC) changes caused by UI actions. It is designed for ad hoc debugging and test design around NBS and downstream processing.

Local cache and state files are written under `.local/`. Per-run artifacts are written under `output/`.

## Quick Start

Run from the repository root.

1. (Optional) Set database connection values in `.env`: `DATABASE_SERVER`, `DATABASE_PORT`, `DATABASE_USERNAME`, and `DATABASE_PASSWORD`.
2. Start a dual capture run:

```powershell
python utilities/local-db-tracing/trace_db_dual_capture.py
```

3. Perform the action in NBS that you want to turn into a test.
4. Return to the script, press Enter when prompted, and provide a short action description.
5. In the new paired output folder, run `cdc-NBS_ODSE/inserts.sql` against the source database to replay the captured writes.
6. (optional) narrow down local ID lookups from where in to = via

```powershell
python utilities/local-db-tracing/narrow_rdb_selects_where_in.py --input-file utilities/local-db-tracing/output/<paired-run>/rdb-selects.sql
```

7. Validate expected target rows:

```powershell
python utilities/local-db-tracing/validate_rdb_selects.py --input-file utilities/local-db-tracing/output/<paired-run>/rdb-selects.sql
```

8. Review pass/fail details in `utilities/local-db-tracing/output/<paired-run>/rdb-selects-results.md`.

## Overview

This toolkit supports two goals:

- trace source-database writes caused by an NBS action
- verify expected target-database rows for that same action

At a high level, the tracers:

- verify database-level CDC is enabled
- enable CDC on eligible user tables (excluding noisy tables such as `dbo.job_flow_log`)
- capture a start LSN, wait for your action, and capture an end LSN
- write structured artifacts under `utilities/local-db-tracing/output`
- optionally clean up tracer-managed CDC table configuration

## Prerequisites

- Docker environment running with SQL Server reachable at the target `--server`
- `sqlcmd` installed and available on `PATH` (or provided with `--sqlcmd`)
- database-level CDC already enabled in each database you plan to trace
- SQL login with permission to enable/disable CDC on tables
- Python 3.10+

If database-level CDC is not enabled, run this first:

```sql
-- If SQL Server reports an orphaned dbo owner or similar authorization issue,
-- you may need this first:
ALTER AUTHORIZATION ON DATABASE::[<database_name>] TO [<username>];
GO

USE [<database_name>];
GO
EXEC sys.sp_cdc_enable_db;
GO
```

## Main Workflows

### Dual Capture (Recommended)

Captures `NBS_ODSE` CDC and `RDB_MODERN` logical changes for one action window.

```powershell
python utilities/local-db-tracing/trace_db_dual_capture.py --server localhost,3433 --user sa --password "<password>"
```

Use alternate databases when needed:

```powershell
python utilities/local-db-tracing/trace_db_dual_capture.py --server localhost,3433 --cdc-database NBS_ODSE --logical-database RDB_MODERN --user sa --password "<password>"
```

During the run you will:

1. perform the action in NBS
2. press Enter in the tracer
3. enter an action description

By default, the tracer waits for post-processing idle before ending capture and generates `rdb-selects.sql` in the paired run folder.

### CDC Capture Only

Use when you only need raw CDC details and reconstructed replay SQL.

```powershell
python utilities/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "<password>"
```

### Logical Capture Only

Use when you only need target row-level logical deltas.

```powershell
python utilities/local-db-tracing/trace_db_logical_changes.py --server localhost,3433 --database RDB_MODERN --user sa --password "<password>"
```

## Common Commands

Show tracer help:

```powershell
python utilities/local-db-tracing/trace_db_cdc.py --help
```

Always clean up tracer-managed tables after a run:

```powershell
python utilities/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "<password>" --cleanup yes
```

Leave tracer-managed tables enabled for later cleanup:

```powershell
python utilities/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "<password>" --cleanup no
```

Disable previously tracked tracer-managed tables and exit:

```powershell
python utilities/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "<password>" --disable-only
```

Generate `rdb-selects.sql` from an existing paired run:

```powershell
python utilities/local-db-tracing/generate_rdb_selects.py --paired-run-dir utilities/local-db-tracing/output/20260408-143320-NBS_ODSE-to-RDB_MODERN
```

Or generate from a manifest directly:

```powershell
python utilities/local-db-tracing/generate_rdb_selects.py --combined-manifest utilities/local-db-tracing/output/20260408-143320-NBS_ODSE-to-RDB_MODERN/combined-manifest.json
```

Narrow ambiguous `WHERE ... IN (@var1, @var2, ...)` predicates before validation:

```powershell
python utilities/local-db-tracing/narrow_rdb_selects_where_in.py --input-file utilities/local-db-tracing/output/20260410-091404-NBS_ODSE-to-RDB_MODERN/rdb-selects.sql
```

Then validate `rdb-selects.sql` against expected JSON row sets:

```powershell
python utilities/local-db-tracing/validate_rdb_selects.py --input-file utilities/local-db-tracing/output/20260410-091404-NBS_ODSE-to-RDB_MODERN/rdb-selects.sql
```

Or skip narrowing to validate directly with broad IN predicates.

Compare logical changes between baseline and target runs:

```powershell
python utilities/local-db-tracing/compare_logical_changes.py --baseline-file utilities/local-db-tracing/output/20260407-101153-NBS_ODSE/logical-changes.json --target-file utilities/local-db-tracing/output/20260406-112759-RDB_MODERN/logical-changes.json
```

Regenerate `summary.txt` from `changes.jsonl`:

```powershell
python utilities/local-db-tracing/regenerate_summary.py --input-file utilities/local-db-tracing/output/20260407-101153-NBS_ODSE/changes.jsonl
```

Regenerate `summary.txt` and include action text:

```powershell
python utilities/local-db-tracing/regenerate_summary.py --input-file utilities/local-db-tracing/output/20260407-101153-NBS_ODSE/changes.jsonl --action "Added Bart Simpson"
```

Include helper-table writes in regenerated SQL when needed:

```powershell
python utilities/local-db-tracing/regenerate_summary.py --input-file utilities/local-db-tracing/output/20260407-101153-NBS_ODSE/changes.jsonl --replay-mode full
```

## Key Options

Commonly used options across tracers:

- `--cleanup ask|yes|no`: prompt, always clean up, or always leave tracer-managed CDC tables enabled
- `--disable-only`: disable tracer-managed CDC tables from saved state and exit
- `--state-file`: override default database-specific cleanup state file
- `--sqlcmd`: override the `sqlcmd` executable name or path
- `--skip-post-processing-wait`: end capture immediately after Enter instead of waiting for post-processing idle
- `--post-processing-container-prefix`: container name prefix to watch
- `--post-processing-idle-message`: log message that indicates post-processing idle
- `--post-processing-initial-wait`: delay log polling to avoid stale idle matches
- `--post-processing-wait-timeout`: maximum seconds to wait for idle message
- `--known-associations-file`: override replay association mappings
- `--replay-mode core|full`: `core` for functional test replay, `full` for all replayable side effects

For `regenerate_summary.py`:

- `--input-file`: required path to `changes.jsonl`
- `--manifest-file`: optional path to companion `manifest.json`
- `--output-file`: optional output path for regenerated `summary.txt`
- `--action`: optional action note (repeatable)

## Output Structure

Each run writes a timestamped directory under `utilities/local-db-tracing/output`.

Single CDC run (example):

- `summary.txt`: human-readable summary and reconstructed SQL section when replayable operations exist
- `manifest.json`: structured run metadata
- `changes.jsonl`: one JSON object per CDC row in CDC order
- `inserts.sql`: reconstructed replay SQL when replayable operations exist

Logical-only run (example):

- `logical-changes.json`: row-level insert/update/delete events
- `logical-changes.md`: Markdown rendering of logical changes

Dual-capture run (example `.../20260408-111218-NBS_ODSE-to-RDB_MODERN/`):

- `combined-manifest.json`: pointers to source/target artifacts for the action window
- `cdc-<database>/`: CDC artifacts for source database
- `logical-<database>/`: logical artifacts for target database
- `rdb-selects.sql`: generated target verification queries with `-- EXPECTED_ROWS_JSON` comments
- `rdb-selects-results.json`: machine-readable validation results (when validator is run)
- `rdb-selects-results.md`: human-readable validation report (when validator is run)

## Reference Files

- `known_lookup_keys.json`: Documents which column should be used in WHERE predicates for tables with multiple candidate keys. Consult this when reviewing generated rdb-selects.sql predicates or update it to prevent incorrect key selection in future runs.

## Local State And Cleanup

If cleanup is skipped or partially fails, the tracer writes per-database state under `.local/`, for example:

- `.local/enabled-cdc-tables-NBS_ODSE.json`
- `.local/enabled-cdc-tables-RDB_MODERN.json`

These files are the source of truth for later `--disable-only` cleanup.

Replay metadata is cached per database in files such as `.local/replay-metadata-NBS_ODSE.json` to avoid re-discovering PK/FK metadata on every run. The cache also stores durable `core` replay preferences, including ignored helper tables.

## Reconstructed SQL Notes

When replayable row operations are captured, reconstructed SQL aims to be rerunnable locally and currently:

- declares only replay-safe UID variables required by the replay
- applies semantic associations from `known_replay_associations.json` before FK or name-based fallback
- skips audit-style inserts (for example `dbo.Security_log`)
- preserves captured datetime literals as seen in CDC payloads
- maps `*_user_id` columns to the resolved `superuser` ID (fallback `10009282`)
- assigns replay-safe `version_ctrl_nbr` values for `_hist` inserts and live-row updates
- preserves CDC order to keep replay behavior close to original transaction flow
- in `core` mode, skips helper tables listed in replay metadata under `core_replay.ignored_tables`

If no replayable row operations are found, `summary.txt` is still written without a reconstructed SQL section.

## Notes

- Some tables may be skipped if SQL Server refuses CDC enablement.
- CDC fetches are batched across capture instances (not one `sqlcmd` process per table).
- By default, after you press Enter, capture end waits for a running container starting with `nedss-datareporting-reporting-pipeline-service-1` to log `No ids to process from the topics.`
- The tooling is designed for both `NBS_ODSE` and `RDB_MODERN`, but replay quality depends on available schema metadata.

## To Do

1. Emit a standalone JSON artifact keyed by query label so tests do not need to parse SQL comments.
2. Resolve remaining ambiguous observation variable mappings so more predicates can use source variables instead of literals.
