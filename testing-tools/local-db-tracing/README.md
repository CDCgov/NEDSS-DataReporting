# Local Database CDC Tracing

This directory contains a local investigation tool for tracing SQL Server Change Data Capture (CDC) changes caused by UI actions. It is designed for ad hoc debugging and test design around NBS and downstream processing.

Local cache and state files are written under `.local/`. Per-run artifacts are written under `output/`.

## Quick Start

Run from the repository root.

Use this section as a fast path. For the full canonical workflow, use the 10-step process below.

1. Start dual capture:

```powershell
python testing-tools/local-db-tracing/trace_db_dual_capture.py
```

2. Replay your NBS flow, then finish capture in the tracer prompts.
3. Replay the captured inserts into ODSE via `replay_setup.py`:

```powershell
python testing-tools/local-db-tracing/replay_setup.py --setup-sql testing-tools/local-db-tracing/output/<paired-run>/cdc-NBS_ODSE/inserts.sql --auto-datetime-mode preserve --server localhost,3433 --user sa --password "<password>"
```

When prompted for UID renumbering, press Enter to keep existing IDs.

4. Validate generated RDB queries:

```powershell
python testing-tools/local-db-tracing/validate_rdb_selects.py --input-file testing-tools/local-db-tracing/output/<paired-run>/rdb-selects.sql
```

5. Promote artifacts (`setup.sql`, `query.sql`, `expected.json`) into the functional test step folder.

## End-To-End: Create A Functional Test From A Recorded User Flow

This workflow is the repeatable process for turning a real UI flow into functional test artifacts that validate RDB outputs.

### Prerequisites For This Workflow

- Run from repository root: `NEDSS-DataReporting/`
- Services are up with SQL Server reachable (for example through `docker-compose.yaml`)
- Python environment is active and can run `testing-tools/local-db-tracing/*.py`
- `sqlcmd` is installed and available in `PATH`
- You can log into NBS and run the target user flow
- `trace_db_dual_capture.py` has credentials via `.env` or flags (`--server`, `--user`, `--password`)

### Required Inputs Before You Start

1. A target scenario (for example, one step in a functional path)
2. A Chrome Recorder export for that scenario (`.json`)
3. A destination test step folder under `reporting-pipeline-service/src/test/resources/testData/functional/<suite>/<step>/`

### ID Range Registry

Before creating or shifting test IDs, check the functional test ID registry to avoid range collisions:

- `reporting-pipeline-service/src/test/resources/testData/functional/README.md`

### 10-Step Process

1. Identify the target flow.
2. (optionally) Record the flow using Google Chrome Recorder.
3. Start `trace_db_dual_capture.py`:

```powershell
python testing-tools/local-db-tracing/trace_db_dual_capture.py --server localhost,3433 --user sa --password "<password>"
```

4. Replay the recorded flow (manually in NBS or from Chrome Recorder export).
5. Wait for the post-processing service to complete.
6. Stop `trace_db_dual_capture.py` (press Enter when prompted and finish the capture).
7. Replay `inserts.sql` in the paired run's `cdc-<database>/` folder against ODSE via `replay_setup.py`.

```powershell
python testing-tools/local-db-tracing/replay_setup.py --setup-sql testing-tools/local-db-tracing/output/<paired-run>/cdc-NBS_ODSE/inserts.sql --auto-datetime-mode preserve --server localhost,3433 --user sa --password "<password>"
```

When prompted for UID renumbering, press Enter to keep existing IDs.

8. Run `validate_rdb_selects.py`:

```powershell
python testing-tools/local-db-tracing/validate_rdb_selects.py --input-file testing-tools/local-db-tracing/output/<paired-run>/rdb-selects.sql --server localhost,3433 --user sa --password "<password>"
```

9. Review results in `rdb-selects-results.md`:

- `testing-tools/local-db-tracing/output/<paired-run>/rdb-selects-results.md`
- confirm each case is passing, or note mismatches to fix before promoting artifacts

10. Create the functional test artifacts:

- `setup.sql`
- `query.sql`
- `expected.json`

Use the helper to copy and normalize a single step into a functional test directory:

```powershell
python testing-tools/local-db-tracing/build_step_test_artifacts.py --setup-step testing-tools/local-db-tracing/output/<paired-run>/cdc-NBS_ODSE/step-<N> --logical-step testing-tools/local-db-tracing/output/<paired-run>/logical-RDB_MODERN/step-<N> --test-step reporting-pipeline-service/src/test/resources/testData/functional/<suite>/<step>
```

After generating artifacts, run functional tests to verify the new step:

```powershell
cd reporting-pipeline-service
./gradlew test --tests "gov.cdc.nbs.report.pipeline.integration.functional.DataDrivenFunctionalTests"
```

### Validation Checklist Before Opening A PR

- `setup.sql` replays cleanly with `sqlcmd -b`
- `query.sql` statements are ordered and map to `expected.json` keys (`"0"`, `"1"`, ...)
- `expected.json` is valid JSON and contains only stable assertions
- `rdb-selects-results.md` is all pass, or you intentionally updated assertions to match expected behavior
- artifacts live in the correct test step folder under `reporting-pipeline-service/src/test/resources/testData/functional/`

### Troubleshooting

- No data returned in validator results:
	- Confirm `inserts.sql` ran successfully against ODSE.
	- Re-run validation after post-processing is idle.
- Unexpected timestamp mismatches:
	- For date-only fields (captured with `T00:00:00.000`), prefer `CURRENT_DATE` when replaying setup values.
- Validator parse or case errors:
	- Ensure `query.sql` has valid `SELECT`/`WITH` statements and `expected.json` keys match statement order.
- Functional test flakiness:
	- Verify the step uses unique IDs for its assigned range and does not overlap another suite.
- CDC setup failures:
	- Confirm database-level CDC is enabled and ownership/permissions are correct.

### Example Artifacts

A complete example artifact set is provided here:

- `testing-tools/local-db-tracing/docs/functional-test-artifact-example/010-createPatient/setup.sql`
- `testing-tools/local-db-tracing/docs/functional-test-artifact-example/010-createPatient/query.sql`
- `testing-tools/local-db-tracing/docs/functional-test-artifact-example/010-createPatient/expected.json`

This example mirrors a real functional step and can be used as a template for structure and formatting.

## Detailed Reference

Detailed tracer reference (commands, options, output structure, and implementation notes) is in [docs/reference-guide.md](docs/reference-guide.md).
