# Local Database CDC Tracing

This directory contains a local investigation tool for tracing SQL Server Change Data Capture (CDC) changes caused by UI actions. It is designed for ad hoc debugging and test design around NBS and downstream processing.

Local cache and state files are written under `.local/`. Per-run artifacts are written under `output/`.

## What The Script Does

The tracer script:

- checks whether database-level CDC is enabled and stops with manual SQL instructions if it is not
- checks which user tables are already CDC-enabled
- enables CDC on remaining eligible tables, except known noisy exclusions such as `dbo.job_flow_log`
- records a start log sequence number (LSN) and timestamp
- waits for you to perform a UI action and press Enter
- optionally waits for the post-processing container to report that it is idle before taking the end LSN
- prompts for a short description of the NBS actions you performed
- captures CDC rows in the recorded LSN window
- writes summary and machine-readable output files for the run
- optionally disables tracer-managed CDC tables during cleanup
- persists cleanup state in `.local/` when tracer-managed CDC is intentionally left enabled or table cleanup partially fails

## Prerequisites

- Docker environment running with SQL Server reachable at the target `--server`
- `sqlcmd` installed and available on `PATH`, or passed explicitly with `--sqlcmd`
- database-level CDC already enabled in the target database
- a SQL login with permission to enable and disable CDC on tables in the target database
- Python 3.10+

If database-level CDC is not enabled yet, enable it manually before running the tracer:

```sql
-- If SQL Server reports an orphaned dbo owner or similar authorization error,
-- you may need to run this first:
ALTER AUTHORIZATION ON DATABASE::[<database_name>] TO [<username>];
GO

USE [<database_name>];
GO
EXEC sys.sp_cdc_enable_db;
GO
```

## Basic Usage

Run from the repository root:

```powershell
python utilities/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "<password>"
```

The default behavior is:

- output goes to `utilities/local-db-tracing/output`
- cleanup mode is `ask`
- post-processing wait is enabled
- known replay associations are loaded from `utilities/local-db-tracing/known_replay_associations.json`
- replay mode is `core`, which skips helper-table writes listed in the replay metadata cache

## Common Commands

Show help:

```powershell
python utilities/local-db-tracing/trace_db_cdc.py --help
```

Write artifacts to a custom output directory:

```powershell
python utilities/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "<password>" --output-dir utilities/local-db-tracing/output
```

Always clean up tracer-managed CDC objects after the run:

```powershell
python utilities/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "<password>" --cleanup yes
```

Keep tracer-managed CDC enabled for later cleanup:

```powershell
python utilities/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "<password>" --cleanup no
```

Disable whatever the tracer previously left enabled, then exit:

```powershell
python utilities/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "<password>" --disable-only
```

Trace a different database:

```powershell
python utilities/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database RDB_Modern --user sa --password "<password>"
```

Capture logical row-level changes for a database run:

```powershell
python utilities/local-db-tracing/trace_db_logical_changes.py --server localhost,3433 --database RDB_Modern --user sa --password "<password>"
```

Compare a baseline logical change capture against a target logical change capture:

```powershell
python utilities/local-db-tracing/compare_logical_changes.py --baseline-file utilities/local-db-tracing/output/20260407-101153-NBS_ODSE/logical-changes.json --target-file utilities/local-db-tracing/output/20260406-112759-RDB_MODERN/logical-changes.json
```

Convert a logical change capture into a human-friendly Markdown report:

```powershell
python utilities/local-db-tracing/logical_changes_to_markdown.py --input-file utilities/local-db-tracing/output/20260407-101153-NBS_ODSE/logical-changes.json
```

Regenerate `summary.txt` from an existing `changes.jsonl` run artifact:

```powershell
python utilities/local-db-tracing/regenerate_summary.py --input-file utilities/local-db-tracing/output/20260407-101153-NBS_ODSE/changes.jsonl
```

Regenerate `summary.txt` and include the original action note again:

```powershell
python utilities/local-db-tracing/regenerate_summary.py --input-file utilities/local-db-tracing/output/20260407-101153-NBS_ODSE/changes.jsonl --action "Added Bart Simpson"
```

Include helper-table writes in reconstructed SQL when needed:

```powershell
python utilities/local-db-tracing/regenerate_summary.py --input-file utilities/local-db-tracing/output/20260407-101153-NBS_ODSE/changes.jsonl --replay-mode full
```

## Important Options

- `--cleanup ask|yes|no`: prompt, always clean up, or always leave tracer-managed CDC enabled
- `--disable-only`: disable tracer-managed CDC based on the recorded state file, then exit
- `--state-file`: override the default database-specific cleanup state file
- `--sqlcmd`: override the `sqlcmd` executable name or path
- `--skip-post-processing-wait`: capture immediately after you press Enter instead of waiting for the post-processing container to go idle
- `--post-processing-container-prefix`: override the container name prefix to watch
- `--post-processing-idle-message`: override the log message that indicates the post-processing container is idle
- `--post-processing-initial-wait`: delay log polling long enough to avoid matching stale idle messages
- `--post-processing-wait-timeout`: cap the post-processing wait in seconds
- `--known-associations-file`: override the default replay association mapping file
- `--replay-mode core|full`: choose functional-test core replay or exact side-effect replay

For `regenerate_summary.py` specifically:

- `--input-file`: required path to the existing `changes.jsonl`
- `--manifest-file`: optional path to the corresponding `manifest.json`; defaults to the file next to `changes.jsonl`
- `--output-file`: optional output path for the regenerated `summary.txt`; defaults to the file next to `changes.jsonl`
- `--action`: optional NBS action note to include in the regenerated summary; repeat for multiple actions
- `--replay-mode`: `core` by default for functional-test SQL, or `full` to include helper-table writes

## Output Files

Each run creates a timestamped directory under `output/`, for example `output/20260406-123456-NBS_ODSE/`.

That directory contains:

- `summary.txt`: human-readable run summary, including the NBS action note and reconstructed SQL when replayable row operations were captured
- `manifest.json`: structured run metadata, including enabled tables, skipped tables, capture instances, and tracked cleanup state
- `changes.jsonl`: one JSON object per captured CDC row in sorted CDC order

The logical-change tracer writes a different machine-readable artifact:

- `logical-changes.json`: one JSON array per run containing row-level insert, update, and delete events with stable comparison identity, changed fields for updates, and full inserted or updated row state
- `compare-results-*.json`: one-way compare output that reports which baseline logical changes were matched, missing, or skipped when checked against a target `logical-changes.json`
- `logical-changes.md`: human-friendly Markdown rendering of a single `logical-changes.json` artifact with run summary, touched tables, and per-change details

The most useful file for later test design is usually `changes.jsonl`. The most useful file for replay-oriented debugging is usually `summary.txt`.

`changes.jsonl` does not store the freeform NBS action note, so regenerated summaries only include that section when you pass one or more `--action` values.

## Local State And Cleanup

When cleanup is skipped or partially fails, the tracer writes database-specific state under `.local/`, such as:

- `.local/enabled-cdc-tables-NBS_ODSE.json`
- `.local/enabled-cdc-tables-RDB_Modern.json`

That state file is the source of truth for later `--disable-only` cleanup. The script also honors the older shared `enabled-cdc-tables.json` file once during migration if it exists.

Replay metadata is cached per database under `.local/` in files such as `.local/replay-metadata-NBS_ODSE.json` so expensive PK and FK discovery does not have to run on every trace. The cache also stores durable core-replay preferences, such as helper tables that should be ignored when generating functional-test replay SQL.

If the tracer enabled database-level CDC itself, cleanup also attempts to disable database-level CDC when the run finishes.

## Reconstructed SQL Behavior

When the capture contains replayable row operations, `summary.txt` includes reconstructed SQL that tries to be rerunnable in a local environment.

Current replay behavior includes:

- declaring only the replay-safe UID variables actually required by the reconstructed SQL and threading those values through related inserts using cached PK and FK metadata
- applying semantic associations from `known_replay_associations.json` before falling back to FK metadata or column-name matching
- preserving captured datetime literals exactly as they appeared in the CDC payload
- forcing columns whose names end with `user_id` to use the resolved `superuser` ID for the traced database, falling back to `10009282`
- assigning replay-safe `version_ctrl_nbr` values for `_hist` inserts and live-row updates
- preserving CDC order so the reconstructed SQL follows the original transaction sequence as closely as possible
- in `core` replay mode, skipping helper tables listed in the replay metadata cache under `core_replay.ignored_tables`

If no replayable row operations were captured, the summary still gets written but the reconstructed SQL section is omitted.

## Notes

- Some tables may still be skipped if SQL Server refuses CDC enablement for them.
- The tracer batches CDC reads across capture instances instead of spawning one `sqlcmd` process per table.
- By default, after you press Enter, the script waits for a running container whose name starts with `nedss-datareporting-post-processing-service` to log `No ids to process from the topics.` before capturing the end LSN.
- The tracer is database-agnostic enough to work against `NBS_ODSE` and `RDB_Modern`, but table eligibility and replay quality still depend on the schema and available metadata in the selected database.
