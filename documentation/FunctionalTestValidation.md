**This document starts after the functional test exists.** It takes a test step that already has `setup.sql`, `query.sql`, and `expected.json`, and checks it against MasterETL. Creating those three files in the first place — from a recorded UI flow, through `trace_db_dual_capture.py` and `build_step_test_artifacts.py` — is a different workflow, documented in [End-To-End: Create A Functional Test From A Recorded User Flow](../testing-tools/local-db-tracing/README.md#end-to-end-create-a-functional-test-from-a-recorded-user-flow). Do that first if you are starting from nothing.

# Functional Test Validation

Functional tests assert against the changes RTR writes to `RDB_MODERN`. This document covers the other half of the picture: capturing what MasterETL writes to the legacy `RDB` for the same input, and cross-checking the two, so that a passing functional test means something.

There are two parts to it:

1. **Capture** — drive a functional test step's `setup.sql` into ODSE, run MasterETL, and record what changed in `RDB`. This produces a `query.sql` / `expected.json` pair for the legacy side.
2. **Validate** — run each side's queries against each side's database. Four combinations, each answering a different question.

Either way, the artifacts are expected to follow the functional test standards agreed upon by the team, including the use of id fields (e.g., `local_id` or `act_uid`) and the file syntax expected by `reporting-pipeline-service/src/test/java/gov/cdc/nbs/report/pipeline/integration/functional/DataDrivenFunctionalTests.java`. `setup.sql` is expected to be complete, but may require changes based on your unique functional tests.

## Prerequisites

- The local stack running with the `sas` profile, and the ability to run MasterETL. See [DevSetup.md](DevSetup.md).
- `sqlcmd` installed and available on your `PATH`.
- A `.env` supplying `DATABASE_SERVER`, `DATABASE_PORT`, `DATABASE_USERNAME`, and `DATABASE_PASSWORD`. Every tool below reads these, so the examples omit connection flags; pass `--server`, `--user`, and `--password` to override.
- The tracing tools in [testing-tools/local-db-tracing](../testing-tools/local-db-tracing/README.md).
- A functional test step under `reporting-pipeline-service/src/test/resources/testData/functional/<suite>/<step>/` holding `setup.sql`, `query.sql`, and `expected.json`. If you are building the test rather than validating an existing one, follow [End-To-End: Create A Functional Test From A Recorded User Flow](../testing-tools/local-db-tracing/README.md#end-to-end-create-a-functional-test-from-a-recorded-user-flow) first, and claim an id range in [testData/functional/README.md](../reporting-pipeline-service/src/test/resources/testData/functional/README.md) before you do — ranges are allocated 1,000 ids per scenario, and two tests sharing ids fail in ways that look like data bugs.

> **If MasterETL will not complete, fix that first.** It runs against a full `RDB` and is sensitive to the state that database is left in — an incomplete previous run, out-of-date stored procedures, or a transaction log that cannot grow will each stop it, and none of them will look like a capture problem. Check your team's internal [*Common Issues — Development Environments*](https://cdc-nbs.atlassian.net/wiki/spaces/NE/pages/2339078162/Common+Issues+-+Development+Environments) runbook before assuming the tooling is at fault.

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

Some differences appear on every run, and **the validator classifies most of them for you.** Every case comes back as `PASS`, `WARNING`, or `FAIL`. `WARNING` means the rows matched except on differences the tool is willing to overlook:

- **Timestamps that differ.** Replay rewrites inserted timestamps so MasterETL picks the records up, and the two pipelines write their own audit columns at their own times. Two ISO datetimes that simply differ are a warning.
- **`.000` millisecond differences** — `2026-04-23T22:22:34.000` against `2026-04-23T22:22:34` is the same value formatted two ways.
- **`null` against an empty string.**
- **Fields whose names end in `_ID`, `_UID`, or `_KEY`**, and `RDB_LAST_REFRESH_TIME`. These are surrogate keys and refresh stamps, assigned per database and not comparable across the two.

**One datetime difference is deliberately not forgiven.** If one side holds a date-only value (`T00:00:00`) and the other a real time, that is a `FAIL`, not a warning — it usually means a date column was replayed as a timestamp or the reverse, which is a defect in the setup data rather than noise. Replay the value as a date if you hit it.

So `WARNING` is the tool having already applied the rules above. Read warnings; do not chase them. `FAIL` is where the work is.

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

Each run writes `rdb-selects-results.json` and `rdb-selects-results.md` next to the input file. Work from the Markdown: it opens with a count, then one row per case, then a field-level diff for each case that did not pass.

```
| Cases    | 7 |
| Passes   | 2 |
| Warnings | 0 |
| Fails    | 5 |
```

**Read the four runs in this order.**

1. **`RDB_MODERN` against `RDB_MODERN` must have no `FAIL`.** This is the functional test. Anything failing here is a real test failure — fix the data or the assertions before reading anything else.
2. **Then `RDB` against `RDB`.** If the capture does not validate against the database it was captured from, it is not a usable baseline and the two crossed runs cannot be interpreted. Re-capture before continuing.
3. **Then the two crossed runs.** These are where RTR-vs-MasterETL differences surface. Every failing case carries an `Error:` line, and there are only two kinds — which is what tells you where to look:

| `Error:` line | What it means | What to do |
| --- | --- | --- |
| `SQL query returned empty output` | The query found nothing on the target side. The table is populated by one pipeline and not the other. | The biggest finding the crossed runs produce. If it is an `RDB` query finding nothing in `RDB_MODERN`, RTR does not populate that table. If it is an `RDB_MODERN` query finding nothing in `RDB`, your test asserts on something MasterETL never wrote. Either way, record it. |
| `Expected JSON does not match actual query result` | The rows exist on both sides but a field differs. | Read the field table underneath and sort the rows by the three shapes below. |

Within a field-level diff, three shapes are worth telling apart:

| Shape | Example | Reading |
| --- | --- | --- |
| Both sides present, values differ, flagged as a warning | `PATIENT_ADD_TIME` — `2026-05-08T17:56:42.520` vs `2026-04-23T14:16:11.967` | Noise. The tool already discounted it. |
| One side `missing` | `PATIENT_AGE_REPORTED` — `41` vs *missing* | A column-coverage difference: one pipeline populates the column and the other leaves it null, or the assertion is over-specified. Decide which, then either drop the field from the assertion or record the gap. |
| Both present, values genuinely differ | `CONDITION_CD` — `"50265"` vs `"Salmonellosis"` | A real difference in what the two pipelines store — here, a code against its description. This is the class worth writing down. |

Before filing anything, check it against the team's catalogue of expected differences — as above, several of these are known and intentional.

Add anything you decide to keep to `query.sql` and `expected.json`, then run the functional tests. From the **repository root**, not from `reporting-pipeline-service` — the wrapper lives at the root:

```shell
./gradlew clean reporting-pipeline-service:test-functional -D tests=<suite>
```

Drop `-D tests=` to run every functional suite. See [Testing](../README.md#testing) for the unit-test task and the rest of the options.
