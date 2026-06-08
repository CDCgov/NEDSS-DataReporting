# Local Database CDC Tracing

This directory contains a local investigation tool for tracing SQL Server Change Data Capture (CDC) changes caused by UI actions. It is designed for ad hoc debugging and test design around NBS and downstream processing.

Local cache and state files are written under `.local/`. Per-run artifacts are written under `output/`.

## Quick Start

Run from the repository root.

1. (Optional) Set database connection values in `.env`: `DATABASE_SERVER`, `DATABASE_PORT`, `DATABASE_USERNAME`, and `DATABASE_PASSWORD`.
2. Start a dual capture run:

```powershell
python testing-tools/local-db-tracing/trace_db_dual_capture.py
```

3. Perform the action in NBS that you want to turn into a test.
4. Return to the script, press Enter when prompted, and provide a short action description.
5. In the new paired output folder, run `cdc-NBS_ODSE/inserts.sql` against the source database to replay the captured writes.
6. (optional) narrow down local ID lookups from where in to = via

```powershell
python testing-tools/local-db-tracing/narrow_rdb_selects_where_in.py --input-file testing-tools/testing-tools/local-db-tracing/output/<paired-run>/rdb-selects.sql
```

7. Validate expected target rows:

```powershell
python testing-tools/local-db-tracing/validate_rdb_selects.py --input-file testing-tools/testing-tools/local-db-tracing/output/<paired-run>/rdb-selects.sql
```

8. Review pass/fail details in `testing-tools/testing-tools/local-db-tracing/output/<paired-run>/rdb-selects-results.md`.

### Step-By-Step Checks

Dual capture runs also generate per-step artifacts so you can replay and validate one step at a time.

For a paired run such as `testing-tools/testing-tools/local-db-tracing/output/<paired-run>/`:

- replay SQL for each source step is written under `cdc-<database>/step-<N>/setup.sql`
- target verification SQL for each target step is written under `logical-<database>/step-<N>/query.sql`
- each `query.sql` is cumulative through that step, so step 2 reflects the expected target state after both step 1 and step 2 have been applied

Manual step-by-step workflow:

1. Run `cdc-<database>/step-1/setup.sql` against the source database.
2. Wait for `nedss-datareporting-reporting-pipeline-service-1` to have "No ids to process from the topics."
3. Run:

```powershell
python testing-tools/local-db-tracing/validate_rdb_selects.py --input-file testing-tools/testing-tools/local-db-tracing/output/<paired-run>/logical-<database>/step-1/query.sql
```

4. Review the generated Markdown report for step 1, `testing-tools/testing-tools/local-db-tracing/output/<paired-run>/logical-<database>/step-1/rdb-selects-results.md`.
5. Run `cdc-<database>/step-2/setup.sql`.
6. Run:

```powershell
python testing-tools/local-db-tracing/validate_rdb_selects.py --input-file testing-tools/testing-tools/local-db-tracing/output/<paired-run>/logical-<database>/step-2/query.sql
```

7. Review the generated Markdown report for step 2, `testing-tools/testing-tools/local-db-tracing/output/<paired-run>/logical-<database>/step-2/rdb-selects-results.md`.
8. Repeat for later steps.

Example validator command for a step query file:

```powershell
python testing-tools/local-db-tracing/validate_rdb_selects.py --input-file testing-tools/testing-tools/local-db-tracing/output/<paired-run>/logical-RDB_MODERN/step-2/query.sql
```

When only `--input-file` is provided, the validator writes results next to that step query file using default names:

- `rdb-selects-results.json`
- `rdb-selects-results.md`

For example, validating `logical-RDB_MODERN/step-2/query.sql` writes:

- `logical-RDB_MODERN/step-2/rdb-selects-results.json`
- `logical-RDB_MODERN/step-2/rdb-selects-results.md`

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
7. Execute SQL from `inserts.sql` in the paired run's `cdc-<database>/` folder against ODSE.

```powershell
sqlcmd -S localhost,3433 -U sa -P "<password>" -b -C -i testing-tools/local-db-tracing/output/<paired-run>/cdc-NBS_ODSE/inserts.sql
```

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
