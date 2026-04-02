Local Database CDC Tracing

This folder is a local scratch area for tracing SQL Server database changes caused by UI actions.
It is intended for personal investigation and test design, not for committing into the repository.

Git

This folder is ignored locally through .git/info/exclude.
That means it stays out of git status on this machine without changing the shared .gitignore.

Local-only cache and state files are written under .local/ so they can be excluded cleanly when this tracer is eventually committed.

What The Script Does

The tracer script:

- checks which tables in the target database already have CDC enabled
- enables CDC on all remaining eligible user tables
- records a start LSN and timestamp
- waits for you to perform a UI action and press Enter
- prompts you for a one-line description of the actions you took in NBS
- captures CDC rows between the start and end markers
- writes a summary and change log into an output folder
- prompts before disabling tracer-managed CDC tables
- records any tracer-managed tables left enabled into a local state file

Prerequisites

- Docker environment running with SQL Server available on localhost:3433
- sqlcmd installed and available on PATH
- a SQL login with permission to enable and disable CDC in the target database
- Python 3.10+ recommended

Files Written Per Run

The script creates a timestamped folder under output/ containing:

- summary.txt, including a reconstructed SQL section in CDC order
- manifest.json
- changes.jsonl

The top of summary.txt now includes the one-line NBS action note you entered after stopping the recording.

It may also maintain a database-specific local state file under .local/ such as .local/enabled-cdc-tables-NBS_ODSE.json or .local/enabled-cdc-tables-RDB_Modern.json when you leave tracer-managed CDC enabled.
It also caches replay metadata per database under .local/ in files like .local/replay-metadata-NBS_ODSE.json so PK/FK discovery only has to happen once per database.

The manifest is a per-run summary. The external state file is the source of truth only for deferred cleanup.

Usage

From the repository root:

```powershell
python performance-testing/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "PizzaIsGood33!"
```

Useful options:

```powershell
python performance-testing/local-db-tracing/trace_db_cdc.py --help
python performance-testing/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "PizzaIsGood33!" --output-dir performance-testing/local-db-tracing/output
python performance-testing/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "..." --cleanup yes
python performance-testing/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "..." --cleanup no
python performance-testing/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database NBS_ODSE --user sa --password "..." --disable-only
python performance-testing/local-db-tracing/trace_db_cdc.py --server localhost,3433 --database RDB_Modern --user sa --password "..."
```

Notes

- The script expects database-level CDC to already be enabled for the database named by `--database`.
- Some tables may be skipped if SQL Server rejects CDC enablement for them.
- changes.jsonl is the best file to mine later when turning observed behavior into tests.
- The reconstructed SQL now allocates fresh root primary key values and threads them through related inserts by following cached PK/FK metadata, which avoids rerun conflicts on captured IDs.
- The reconstructed SQL forces any column whose name ends with `user_id` to use `9999` so replayed audit values do not depend on the captured environment.
- The reconstructed SQL also allocates replay-time `version_ctrl_nbr` values for `_hist` inserts and increments `version_ctrl_nbr` on live-row updates so reruns do not collide with existing history-row primary keys.
- CDC rows are now fetched in one batched query after first checking which capture instances actually have rows in the LSN window, which avoids spawning one `sqlcmd` process per table and skips JSON reconstruction for unchanged tables.
- Reconstructed SQL is only generated when the capture actually contains replayable row operations.
- The default cleanup mode is interactive: the script asks whether to disable tracer-managed CDC tables at the end.
- If you answer `n`, the script writes the tracer-managed table list to a database-specific state file like enabled-cdc-tables-NBS_ODSE.json so a later `--disable-only` run can turn CDC back off.
- `--cleanup yes` skips the prompt and always disables tracer-managed tables after the run.
- `--cleanup no` and `--keep-enabled` skip cleanup and persist the tracer-managed table list.
- The tracer logic is database-agnostic; switching from `NBS_ODSE` to `RDB_Modern` is just a `--database` change as long as CDC is enabled there.
- If an older shared state file named enabled-cdc-tables.json exists in the top-level local-db-tracing folder, the tracer will still read it once and migrate future saves to .local/.
- Hint: wait for the PostProcessingService to report "No ids to process from the topics." to ensure all changes are captured.

To Do:

- suppress low-signal fields like last_chg_time, record_status_time, status_time, and version_ctrl_nbr unless they are the only things that changed.
