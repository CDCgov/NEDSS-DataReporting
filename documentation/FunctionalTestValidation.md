# Functional Test Validation

Functional tests assert against the changes RTR writes to `RDB_MODERN`. This document covers the other half of the picture: capturing what MasterETL writes to the legacy `RDB` for the same input, and cross-checking the two, so that a passing functional test means something.

There are two parts to it:

1. **Capture** — drive a functional test step's `setup.sql` into ODSE, run MasterETL, and record what changed in `RDB`. This produces a `query.sql` / `expected.json` pair for the legacy side.
2. **Validate** — run each side's queries against each side's database. Four combinations, each answering a different question.

**This document starts after the functional test exists.** It takes a test step that already has `setup.sql`, `query.sql`, and `expected.json`, and checks it against MasterETL. Creating those three files in the first place — from a recorded UI flow, through `trace_db_dual_capture.py` and `build_step_test_artifacts.py` — is a different workflow, documented in [End-To-End: Create A Functional Test From A Recorded User Flow](../testing-tools/local-db-tracing/README.md#end-to-end-create-a-functional-test-from-a-recorded-user-flow). Do that first if you are starting from nothing.

Either way, the artifacts are expected to follow the functional test standards agreed upon by the team, including the use of id fields (e.g., `local_id` or `act_uid`) and the file syntax expected by `reporting-pipeline-service/src/test/java/gov/cdc/nbs/report/pipeline/integration/functional/DataDrivenFunctionalTests.java`. `setup.sql` is expected to be complete, but may require changes based on your unique functional tests.

This documentation was produced as a deliverable for the Jira Ticket [APP-473](https://cdc-nbs.atlassian.net/browse/APP-473).

## Prerequisites

- The local stack running with the `sas` profile, and the ability to run MasterETL. See [DevSetup.md](DevSetup.md).
- `sqlcmd` installed and available on your `PATH`.
- A `.env` supplying `DATABASE_SERVER`, `DATABASE_PORT`, `DATABASE_USERNAME`, and `DATABASE_PASSWORD`. Every tool below reads these, so the examples omit connection flags; pass `--server`, `--user`, and `--password` to override.
- The tracing tools in [testing-tools/local-db-tracing](../testing-tools/local-db-tracing/README.md).
- A functional test step under `reporting-pipeline-service/src/test/resources/testData/functional/<suite>/<step>/` holding `setup.sql`, `query.sql`, and `expected.json`. If you are building the test rather than validating an existing one, follow [End-To-End: Create A Functional Test From A Recorded User Flow](../testing-tools/local-db-tracing/README.md#end-to-end-create-a-functional-test-from-a-recorded-user-flow) first, and claim an id range in [testData/functional/README.md](../reporting-pipeline-service/src/test/resources/testData/functional/README.md) before you do — ranges are allocated 1,000 ids per scenario, and two tests sharing ids fail in ways that look like data bugs.

> **If MasterETL will not complete, fix that first.** It runs against a full `RDB` and is sensitive to the state that database is left in — an incomplete previous run, out-of-date stored procedures, or a transaction log that cannot grow will each stop it, and none of them will look like a capture problem. Check your team's internal *Common Issues — Development Environments* runbook before assuming the tooling is at fault.

## The validation model

Two databases hold the same data by two different routes: MasterETL writes `RDB`, RTR writes `RDB_MODERN`. Each route produces its own `query.sql` / `expected.json` pair, and each pair can be run against either database. That gives four combinations, and each one tells you something different.

### The four-way A-B / B-A matrix

| Query source | Run against | Tells us |
| --- | --- | --- |
| `RDB_MODERN` | `RDB_MODERN` | **Validation — this IS the functional test** |
| `RDB_MODERN` | `RDB` | The RTR rewrite is accurate |
| `RDB` | `RDB` | Validation of the captured legacy behavior |
| `RDB` | `RDB_MODERN` | The functional test captured everything |

**Query source** is where the `query.sql` / `expected.json` pair came from:

- `RDB_MODERN` — the functional test artifacts under `reporting-pipeline-service/src/test/resources/testData/functional/`.
- `RDB` — the artifacts captured from MasterETL under `testing-tools/local-db-tracing/output/`, produced by the capture workflow below.

### Only the first combination must pass 100%

**`RDB_MODERN` queries against `RDB_MODERN` is the functional test.** It is the only combination that is a gate, and it must pass completely.

The other three are diagnostics about drift between RTR and MasterETL. A failure in one of them is information, not a broken build:

- **`RDB_MODERN` queries against `RDB`** — a failure means RTR produces something MasterETL does not. That is either a genuine difference or a deliberate one.
- **`RDB` queries against `RDB`** — a failure means the capture itself is unreliable. Fix that before reading anything into the other two.
- **`RDB` queries against `RDB_MODERN`** — a failure means MasterETL touched a table the functional test does not assert on. This is the combination that finds missing coverage, and it is the reason to capture the legacy side at all.

A difference surfaced this way is not automatically a defect. Several are known and intentional; check any finding against the team's catalogue of expected differences between `RDB` and `RDB_MODERN` before filing it.

### Acceptable noise

Some differences appear on every run and should not be chased:

- **Timestamps are expected to be off.** Replay rewrites inserted timestamps so that MasterETL picks the records up, and the two pipelines write their own audit columns at their own times.
- **`.000` discrepancies in datetimes are OK.** `2026-04-23T22:22:34.000` and `2026-04-23T22:22:34` are the same value formatted two ways.
- **`_KEY` columns are surrogate keys**, assigned per database and not comparable across the two. A generated `WHERE` clause that leans on them needs narrowing to a business key before it is trustworthy as an assertion.

## Part 1 — Capture the legacy side with dual capture

`trace_db_dual_capture.py` records raw CDC from `NBS_ODSE` and logical row-level changes from a second database in one synchronized run. Pointing its `--logical-database` at `RDB` is what makes it capture MasterETL's output rather than RTR's.

Work one functional test step at a time, and use three terminals: one on the SAS container, one running the tracer, one for replay.

**1. Run MasterETL once before you start.** This drains any pending work, so that the changes you capture belong to your step and nothing else.

```shell
docker compose exec -u SAS -it sas sh -c '/opt/wildfly-10.0.0.Final/nedssdomain/Nedss/BatchFiles/MasterEtl.sh'
```

**2. Start dual capture**, from the repository root, in its own terminal. It will run until you tell it to finish.

```shell
python testing-tools/local-db-tracing/trace_db_dual_capture.py --logical-database RDB
```

**3. Replay the step's `setup.sql`** in a third terminal.

```shell
python testing-tools/local-db-tracing/replay_setup.py --setup-sql reporting-pipeline-service/src/test/resources/testData/functional/<suite>/<step>/setup.sql
```

Two prompts, and the first one matters:

- *Rewrite eligible inserted timestamps/dates to `CURRENT_TIMESTAMP`?* — **yes**. MasterETL selects on `last_chg_time`, so records carrying their original hardcoded timestamps are simply not picked up. You can also pass `--auto-datetime-mode current` to answer it up front.
- *UID renumbering* — press **Enter** to keep the existing numbering. Renumber only if you are re-running against a database you did not reset, and be aware that new UIDs have to be reconciled against the ids already in your validation files.

**4. Run MasterETL again** and wait for it to finish. It takes roughly five minutes.

```shell
docker compose exec -u SAS -it sas sh -c 'time /opt/wildfly-10.0.0.Final/nedssdomain/Nedss/BatchFiles/MasterEtl.sh'
```

**5. Return to the tracer and press ENTER** to close the capture, then record the name of the step when prompted.

**6. Repeat steps 3–5** for each remaining step in the test.

### What the run produces

The run writes a folder named for its two databases, `output/<timestamp>-NBS_ODSE-to-RDB/`, containing:

```
cdc-NBS_ODSE/                 raw CDC captured from ODSE
  step-<N>/setup.sql          replayable inserts for that step
logical-RDB/                  logical changes captured from RDB
  logical-changes.md          human-readable review of every change MasterETL made
  logical-changes.json
  step-<N>/query.sql          the legacy-side query pair for that step
  step-<N>/expected.json
```

`logical-changes.md` is worth reading before you validate anything — it is the fastest way to see which `RDB` tables MasterETL populated, and therefore which tables your functional test may be missing.

You now have a `query.sql` / `expected.json` pair for both sides: `RDB_MODERN` under `reporting-pipeline-service/src/test/resources/testData/functional/`, and `RDB` under `testing-tools/local-db-tracing/output/`.

## Part 2 — Run the four-way validation

`validate_rdb_selects.py` executes each `SELECT` in the file you give it and compares the result against the `expected.json` sitting beside it.

**Start from a clean database.** MasterETL is cumulative, so a run on top of earlier test data will not tell you what you think it does. Reset first — `docker compose down` and up again, or restore from a backup — then, for each step:

1. Replay the step's `setup.sql`:

   ```shell
   python testing-tools/local-db-tracing/replay_setup.py --setup-sql reporting-pipeline-service/src/test/resources/testData/functional/<suite>/<step>/setup.sql
   ```

2. Run MasterETL, and wait for both it and RTR to finish. RTR's post-processing runs on a fixed-delay loop, so give it time to drain before concluding that a comparison failed.

3. Run all four validations:

   ```shell
   # RDB_MODERN queries and expected vs. RDB_MODERN actual  --  the functional test
   python testing-tools/local-db-tracing/validate_rdb_selects.py \
     --input-file reporting-pipeline-service/src/test/resources/testData/functional/<suite>/<step>/query.sql

   # RDB_MODERN queries and expected vs. RDB actual  --  is the RTR rewrite accurate?
   python testing-tools/local-db-tracing/validate_rdb_selects.py \
     --input-file reporting-pipeline-service/src/test/resources/testData/functional/<suite>/<step>/query.sql \
     --database RDB

   # RDB queries and expected vs. RDB actual  --  is the capture sound?
   python testing-tools/local-db-tracing/validate_rdb_selects.py \
     --input-file testing-tools/local-db-tracing/output/<paired-run>/logical-RDB/step-<N>/query.sql

   # RDB queries and expected vs. RDB_MODERN actual  --  did the functional test capture everything?
   python testing-tools/local-db-tracing/validate_rdb_selects.py \
     --input-file testing-tools/local-db-tracing/output/<paired-run>/logical-RDB/step-<N>/query.sql \
     --database RDB_MODERN
   ```

   > `--database` is what makes the cross-runs cross. Each `query.sql` opens with a `USE [...]` statement naming the database it was generated against, and that is the default target; the two crossed combinations need `--database` passed explicitly to override it.

4. Repeat for each step.

### Reading the results

Each run writes `rdb-selects-results.json` and `rdb-selects-results.md` next to the input file. Work from the Markdown: it lists each case as pass or fail with the expected and actual rows side by side.

Read the results in this order:

1. **`RDB_MODERN` against `RDB_MODERN` must be all green.** Anything else here is a real functional test failure — fix the data or the assertions before looking further.
2. **Check `RDB` against `RDB`.** If the capture does not validate against its own database, the two crossed runs cannot be interpreted.
3. **Then read the two crossed runs**, discounting the acceptable noise above, and treating what remains as either a table your test is missing or a difference between RTR and MasterETL worth recording.

Add anything you find to `query.sql` and `expected.json`, then run the functional tests:

```shell
cd reporting-pipeline-service
./gradlew test --tests "gov.cdc.nbs.report.pipeline.integration.functional.DataDrivenFunctionalTests"
```

## Worked example — finding a missing table

What the four-way validation is for is easiest to see on a case where it found something. Running the capture over the Morbidity Report suite showed that MasterETL populated a table the functional test did not assert on at all — the `RDB` queries against `RDB_MODERN` combination, and the reason that combination exists.

### Reading the capture

`logical-changes.md` lists every change MasterETL made, one entry per row written. This entry is the one that mattered:

**113. INSERT dbo.MORBIDITY_REPORT**

| Metric | Value |
| --- | --- |
| Identity | business_keys: MORB_RPT_LOCAL_ID="OBS20100086GA01" |
| Transaction end | 2026-04-23T22:22:34.720 |
| LSN | 0x00006bf6000312400004 |

**Inserted Row**

| Field | Value |
| --- | --- |
| DAYCARE_IND | "N" |
| DIAGNOSIS_DT | "2026-04-05T00:00:00" |
| DIE_FROM_ILLNESS_IND | "Y" |
| ELECTRONIC_IND | "N" |
| FOOD_HANDLER_IND | "N" |
| HEALTHCARE_ORG_ASSOCIATE_IND | "UNK" |
| HOSPITALIZED_IND | "Y" |
| HSPTL_ADMISSION_DT | "2026-04-03T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| MORB_RPT_CREATE_BY | 10009282 |
| MORB_RPT_KEY | 3 |
| MORB_RPT_LAST_UPDATE_BY | 10009282 |
| MORB_RPT_LAST_UPDATE_DT | "2026-04-23T22:20:11.717" |
| MORB_RPT_LOCAL_ID | "OBS20100086GA01" |
| MORB_RPT_OID | 1300100009 |
| MORB_RPT_OTHER_SPECIFY | "other something" |
| MORB_RPT_SHARE_IND | "T" |
| MORB_RPT_TYPE | "INIT" |
| MORB_RPT_UID | 20100086 |
| NURSING_HOME_ASSOCIATE_IND | "Y" |
| PH_RECEIVE_DT | "2026-04-10T00:00:00" |
| PREGNANT_IND | "Y" |
| RDB_LAST_REFRESH_TIME | "2026-04-23T22:22:34.717" |
| RECORD_STATUS_CD | "ACTIVE" |
| SUSPECT_FOOD_WTRBORNE_ILLNESS | "N" |

### Updating `query.sql` and `expected.json`
The existing files for this functional test suite were accurate based on MasterEtl's output with the exception of 1 table: `MORBIDITY_REPORT`. This table was missing completely from validation! To account for this the following was performed:
1. A new entry added to `query.sql` to get the columns modified on the table.
```sql
...
-- 5: MORBIDITY_REPORT
SELECT
    [DAYCARE_IND],
    [DIAGNOSIS_DT],
    [DIE_FROM_ILLNESS_IND],
    [ELECTRONIC_IND],
    [FOOD_HANDLER_IND],
    [HEALTHCARE_ORG_ASSOCIATE_IND],
    [HOSPITALIZED_IND],
    [HSPTL_ADMISSION_DT],
    [JURISDICTION_CD],
    [JURISDICTION_NM],
    [MORB_RPT_CREATE_BY],
    [MORB_RPT_KEY],
    [MORB_RPT_LAST_UPDATE_BY],
    [MORB_RPT_LAST_UPDATE_DT],
    [MORB_RPT_LOCAL_ID],
    [MORB_RPT_OID],
    [MORB_RPT_OTHER_SPECIFY],
    [MORB_RPT_SHARE_IND],
    [MORB_RPT_TYPE],
    [MORB_RPT_UID],
    [NURSING_HOME_ASSOCIATE_IND],
    [PH_RECEIVE_DT],
    [PREGNANT_IND],
    [RDB_LAST_REFRESH_TIME],
    [RECORD_STATUS_CD],
    [SUSPECT_FOOD_WTRBORNE_ILLNESS]
FROM [RDB_MODERN].[dbo].[MORBIDITY_REPORT]
WHERE [MORB_RPT_LOCAL_ID] = 'OBS20100027GA01';
```
2. A new entry added to `expected.json`.
```json
...
"5": [
    {
      "DAYCARE_IND": "N",
      "DIAGNOSIS_DT": "2026-04-05T00:00:00.000",
      "DIE_FROM_ILLNESS_IND": "Y",
      "ELECTRONIC_IND": "N",
      "FOOD_HANDLER_IND": "N",
      "HEALTHCARE_ORG_ASSOCIATE_IND": "UNK",
      "HOSPITALIZED_IND": "Y",
      "HSPTL_ADMISSION_DT": "2026-04-03T00:00:00.000",
      "JURISDICTION_CD": "130001",
      "JURISDICTION_NM": "Fulton County",
      "MORB_RPT_CREATE_BY": 10009282,
      "MORB_RPT_LAST_UPDATE_BY": 10009282,
      "MORB_RPT_LAST_UPDATE_DT": "2026-04-10T20:26:11.853",
      "MORB_RPT_LOCAL_ID": "OBS20100027GA01",
      "MORB_RPT_OID": 1300100009,
      "MORB_RPT_OTHER_SPECIFY": "other something",
      "MORB_RPT_SHARE_IND": "T",
      "MORB_RPT_TYPE": "INIT",
      "MORB_RPT_UID": 20100027,
      "NURSING_HOME_ASSOCIATE_IND": "Y",
      "PH_RECEIVE_DT": "2026-04-10T00:00:00.000",
      "PREGNANT_IND": "Y",
      "RECORD_STATUS_CD": "ACTIVE",
      "SUSPECT_FOOD_WTRBORNE_ILLNESS": "N"
    }
  ]
```
3. Execute the functional test suite, and confirm the new assertion passes:

```shell
cd reporting-pipeline-service
./gradlew test --tests "gov.cdc.nbs.report.pipeline.integration.functional.DataDrivenFunctionalTests"
```
