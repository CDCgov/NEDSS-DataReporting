# Coverage: HEPATITIS_DATAMART end-to-end investigation

Generated: 2026-05-19. Reconciles a contradiction between
`coverage/coverage_tier_3.md` and
`bugs/05_tmp_f_page_case_family/findings.md`/`pr.md`.

## TL;DR

- `coverage_tier_3.md`'s "transaction-isolation bug" hypothesis is
  **wrong**. There is no isolation bug. The two symptoms it cited are
  (a) a misleading log artifact (bug 5a) and (b) a fixture-side NULL
  cascade (bug 5b).
- With bug 5b's UPDATE applied,
  **HEPATITIS_DATAMART populates: 0 → 1 row**.
- The pr.md claim (5b fix unblocks HEPATITIS_DATAMART) is correct.
- The Tier 3 doc's broader "this same bug blocks all 9 other condition
  datamarts" claim is **wrong**: only `sp_hepatitis_datamart_*`
  references `#TMP_F_PAGE_CASE` (per `bugs/05_*/findings.md` and verified
  here). The other 9 condition datamarts each have a different blocker
  (different temp-table pattern, missing observation data, missing
  case-management UID, or routed through a different fact table).
- **The 5b orchestrator fix lives on branch `aw/app-471/bug-5`
  (commit f72833b5) and is NOT present on the current `aw/odse-test-seed`
  branch's `merge_and_verify.sh`.** Until the branches merge, every
  end-to-end run on `aw/odse-test-seed` produces
  HEPATITIS_DATAMART=0.

## Method

1. Fresh baseline: `docker compose down -v && up -d nbs-mssql liquibase`,
   waited for liquibase exit 0.
2. Ran `./scripts/merge_and_verify.sh --skip-reset`. Script aborted in
   step 8 on `fixtures/30_sp_coverage/ldf_answers_tetanus.sql` (a known
   bug — see `coverage_tier_3.md` LDF section). The orchestrator's
   step-9 datamart SPs never ran in the scripted invocation.
3. Manually applied
   `fixtures/30_sp_coverage/multi_condition_investigations.sql` (which
   internally `EXEC`s `sp_nrt_investigation_postprocessing`) to bring
   the post-aborted-orchestrator state in line with what a successful
   end-to-end would have produced before step 9.
4. **Baseline run** (no 5b fix): manually executed the 14 datamart SPs
   from `run_datamart_sps()` and recorded row counts. This represents
   what `merge_and_verify.sh` on the current `aw/odse-test-seed`
   branch produces today.
5. **5b run**: `UPDATE dbo.nrt_investigation SET patient_id = 20000000
   WHERE patient_id IS NULL` (all 13 inv rows), re-ran
   `sp_nrt_investigation_postprocessing` and the datamart SPs.
   Recorded row counts.
6. Inspected `job_flow_log` for each datamart family to localize the
   actual blocker.

Connection: `sqlcmd -S localhost,3433 -U sa -C` with `SQLCMDPASSWORD`
env var. SP source files cited live in
`liquibase-service/src/main/resources/db/005-rdb_modern/routines/`.

## State of HEPATITIS_DATAMART

| Scenario | HEPATITIS_DATAMART | F_PAGE_CASE | nrt_investigation.patient_id (foundation 20000100) |
| --- | --- | --- | --- |
| Current orchestrator (no 5b fix) | **0** | 6 | NULL |
| After applying 5b UPDATE manually | **1** | 6 | 20000000 |

Sample row (post-5b):

```
PATIENT_UID         = 20000000
INVESTIGATION_KEY   = 3
CONDITION_CD        = 10110          (Hep A acute)
```

`job_flow_log` confirms the bug 5a logging artifact survives the fix:
step 3.0 "Generating #TMP_F_PAGE_CASE" logs `row_count=0` in both
runs, while step 4.0 onwards logs `row_count=1`. Per
`bugs/05_tmp_f_page_case_family/findings.md` lines 46-67, the temp
table is correctly populated; the log is wrong because `IF
@debug='true' …` resets `@@ROWCOUNT` between the SELECT INTO and the
@@ROWCOUNT capture (file
`013-sp_hepatitis_datamart_postprocessing-001.sql` lines 95-111). This
is logging-only; downstream steps see the rows.

## What bug 5b's orchestrator change actually unlocks

Bug 5b's fix is the **single** UPDATE in
`scripts/merge_and_verify.sh::run_investigation_chain()` (commit
f72833b5, branch `aw/app-471/bug-5` only):

```sh
sql_q RDB_MODERN "UPDATE dbo.nrt_investigation SET patient_id = 20000000 WHERE public_health_case_uid = 20000100"
```

Effect:

- Without the UPDATE: `nrt_investigation.patient_id = NULL` →
  `sp_f_page_case_postprocessing` line 142
  `COALESCE(PATIENT.PATIENT_KEY, 1)` falls back to sentinel `PATIENT_KEY=1`
  (`PATIENT_UID=NULL`) → `sp_hepatitis_datamart_postprocessing` line 2149
  `DELETE FROM #TMP_HEPATITIS_CASE_BASE WHERE PATIENT_UID IS NULL`
  removes the row → INSERT inserts 0 rows.
- With the UPDATE: PATIENT_KEY resolves to the real foundation
  PATIENT_KEY (=3 in this run) → row survives the DELETE → INSERT
  inserts 1 row.

The fix only addresses foundation Inv 20000100. For the 10 Tier 3
multi-condition variants (22000010–22000100) and the Tetanus variant
(22000200), `patient_id` is also NULL because
`fixtures/30_sp_coverage/multi_condition_investigations.sql:42-121` and
`ldf_answers_tetanus.sql:28-41` don't set it. **Setting it manually
across all 13 rows produces no additional HEPATITIS_DATAMART rows** —
all the non-foundation Hep A variant (v2 20050010) is filtered out by
F_PAGE_CASE because `case_management_uid IS NOT NULL` on v2.

### Why the Tier 3 doc was wrong

`coverage_tier_3.md` section "F_PAGE_CASE → HEPATITIS_DATAMART cascade
— RTR investigation needed" (lines 94-136) claimed:

> Verified manually: this exact query (with `dbo.condition` substituted
> for `#TMP_CONDITION`) returns 1 row. Inside the SP's scope it returns 0.

That claim was based on reading the **job_flow_log row_count for step
3.0**, which is unreliable because of bug 5a. The temp table actually
held the row — it just wasn't logged. The downstream step that *did*
clear the row was step 27 (`TMP_HEPATITIS_CASE_BASE`), and that
clearance was driven by the bug 5b cascade (PATIENT_UID IS NULL DELETE),
not isolation.

All five isolation hypotheses are independently ruled out per
`bugs/05_tmp_f_page_case_family/findings.md` lines 36-44.

## Per-condition diagnosis for the 9 other "family" datamarts

Row counts in this run (with 5b fix applied to all 13 nrt_investigation
rows):

| Datamart table | Rows | Blocker (citation) |
| --- | --- | --- |
| HEPATITIS_DATAMART | **1** | unblocked by 5b |
| HEPATITIS_CASE | 0 | dynamic-pivot SP; reads NBS_case_answer-style observation data we don't seed (file 014, `HEPATITIS_CASE_DATAMART` dataflow) |
| HEP100 | 0 | reads HEPATITIS_DATAMART joined to additional observation data |
| F_STD_PAGE_CASE | 0 | filter requires `CASE_MANAGEMENT_UID IS NOT NULL`; STD/HIV variants 22000080/22000090 have it NULL (file `*f_std_page_case*`, line 155) |
| STD_HIV_DATAMART | 0 | depends on F_STD_PAGE_CASE + INV_HIV (file 026, lines 81-83, 515-518) |
| TB_DATAMART | 0 | reads F_TB_PAM (0 rows) + observation data (file 255 lines 164-168) |
| VAR_DATAMART | 0 | reads F_VAR_PAM (0 rows) + observation data (file 250) |
| BMIRD_STREP_PNEUMO_DATAMART | 0 | INV_FORM_BMDSP filtered out of F_PAGE_CASE; reads condition-specific NBS_case_answer pivots (file 140) |
| PERTUSSIS_CASE | 0 | dynamic-pivot SP; needs Pertussis observation rows (file 043) |
| RUBELLA_CASE | 1 (sentinel) | INV_FORM_RUB excluded from F_PAGE_CASE; the one row is the all-NULL sentinel pre-existing in baseline (file 031) |
| CRS_CASE | 0 | dynamic-pivot SP; errors out at step "UPDATE dbo.CRS_Case" (job_flow_log Status_Type='ERROR'); reads observation data (file 032) |
| MEASLES_CASE | 0 | dynamic-pivot SP; needs Measles observation rows; INV_FORM_MEA excluded from F_PAGE_CASE (file 033) |
| COVID_CASE_DATAMART | 1 | populates without 5b: reads `nrt_investigation` directly via different join path; 22000070 row populates with NULLs for most fields. Real coverage still needs COVID observation data (file 310) |

**Key insight**: the Tier 3 doc's "Multi-condition Investigation
fan-out → still 0 rows. **Same RTR transaction-isolation bug**" claim
(lines 174-186) is wrong on both counts:

1. There is no isolation bug (5a is logging-only; 5b is fixture-side).
2. The 9 other condition datamarts have entirely separate blockers
   (different temp-table patterns, missing observation/PAM/case-management
   fixture data, condition-specific form_cd exclusions in F_PAGE_CASE).
   Per `bugs/05_tmp_f_page_case_family/findings.md` line 30,
   `#TMP_F_PAGE_CASE` is referenced only by
   `sp_hepatitis_datamart_postprocessing`; the other 9 SPs use
   `#S_PHC_LIST`, `#S_INVESTIGATION_LIST`, `#PATIENT`, `#OBS_CODED_*`,
   etc. They don't share a bug — they share a coverage gap.

## Recommended next fixture-side fix

1. **Merge the 5b fix into `aw/odse-test-seed`** (or cherry-pick
   commit `f72833b5`). The current orchestrator on this branch leaves
   `nrt_investigation.patient_id = NULL` for foundation, which means
   every end-to-end run produces HEPATITIS_DATAMART=0 even though the
   bug is well-understood and the one-line fix exists. This is the
   single highest-ROI change to get HEPATITIS_DATAMART into the
   "Fully covered" column of `coverage_merged.md`.

2. **Extend 5b to the Tier 3 multi-condition variants.** Apply the
   same UPDATE pattern to the 10 nrt_investigation rows in
   `fixtures/30_sp_coverage/multi_condition_investigations.sql` and
   the 1 row in `ldf_answers_tetanus.sql`. Specifically: set
   `patient_id = 20000000` (the foundation `nrt_patient.patient_uid`)
   on rows where it's currently NULL. This is needed so condition
   datamarts that DO use the F_PAGE_CASE path (e.g., COVID_CASE,
   syphilis Std_Hiv — if case_management is also fixed) don't fall
   back to sentinel PATIENT_KEY=1 and re-trigger the same DELETE
   cascade.

3. **Document the non-shared-bug status of the 9 other condition
   datamarts.** Replace the "transaction-isolation bug" hypothesis in
   `coverage_tier_3.md` lines 94-186 with the per-condition diagnosis
   table above. Each of those datamarts is its own coverage-gap
   investigation, not a shared blocker.

4. **Optional (out of scope for v1 per STRATEGY.md):** if STD_HIV
   coverage matters before Phase 2, set
   `case_management_uid` on 22000080/22000090 to a real (or sentinel
   non-NULL) value so F_STD_PAGE_CASE picks them up. The exact UID
   would need to come from a `case_management` ODSE row (none currently
   seeded).

## Answer to the headline question

**Was the "transaction-isolation bug" hypothesis in
`coverage_tier_3.md` right or wrong?**

Wrong. There is no transaction-isolation bug. The symptoms it cited
were:

- The `row_count=0` log on `#TMP_F_PAGE_CASE` step 3 — a logging-only
  defect (bug 5a, `IF @debug=...` resetting `@@ROWCOUNT`). The temp
  table is populated correctly.
- The downstream HEPATITIS_DATAMART=0 — a fixture-side NULL cascade
  (bug 5b, `nrt_investigation.patient_id IS NULL` →
  `COALESCE(PATIENT.PATIENT_KEY, 1)` → sentinel PATIENT_UID NULL →
  SP's `DELETE WHERE PATIENT_UID IS NULL`).

Applying bug 5b's one-line fixture-side UPDATE produces
HEPATITIS_DATAMART=1 in a clean end-to-end run. The other 9
"condition-datamart family" tables are blocked for entirely separate
reasons (different temp tables, different fixture data gaps, different
F_PAGE_CASE form_cd routing), not by a shared upstream RTR bug.
