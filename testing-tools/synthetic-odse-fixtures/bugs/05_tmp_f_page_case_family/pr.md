**Title:** Fix sp_hepatitis_datamart_postprocessing: capture @@ROWCOUNT before debug SELECT (and seed nrt_investigation.patient_id)

## Description
Two distinct issues surfaced under the original "TMP_F_PAGE_CASE family" hypothesis. After investigation, both were narrowed down; neither matched the original framing.

**Bug 5a (RTR-side, logging defect, in scope for this PR):** `sp_hepatitis_datamart_postprocessing` captured `@@ROWCOUNT` for step 3 ("Generating #TMP_F_PAGE_CASE") *after* an `IF @debug='true' SELECT * FROM #TMP_F_PAGE_CASE` statement. On the predicate-only path (`@debug=false`), SQL Server still evaluates the IF predicate, which resets `@@ROWCOUNT` to 0, so `job_flow_log` always reported `row_count=0` for step 3 even when the temp table was correctly populated. Swapping the `SELECT @ROWCOUNT_NO = @@ROWCOUNT` capture to run *before* the IF restores the correct count. Logging-only; no behavioral change to downstream steps. This pattern is unique to step 3 of this one SP.

**Bug 5b (fixture-side, orchestrator-only):** the Hepatitis datamart SP reads `nrt_investigation.patient_id` directly to resolve `PATIENT_KEY` via `F_PAGE_CASE`. When NULL, `F_PAGE_CASE`'s `COALESCE(PATIENT.PATIENT_KEY, 1)` falls back to sentinel `PATIENT_KEY=1` (`PATIENT_UID=NULL`), and the SP's `DELETE WHERE PATIENT_UID IS NULL` then removes the row before INSERT. Setting `patient_id` to a real `nrt_patient.patient_uid` in the comparison-fixtures orchestrator unblocks HEPATITIS_DATAMART population.

Verified locally: post-fix, `HEPATITIS_DATAMART` has > 0 rows, and `job_flow_log` step 3 row_count matches the actual TMP_F_PAGE_CASE row count.

## Related Issue
[APP-471](https://cdc-nbs.atlassian.net/browse/APP-471)

## Additional Notes
The 5b commit modifies `testing-tools/synthetic-odse-fixtures/scripts/merge_and_verify.sh`, which only exists on the `aw/odse-test-seed` branch (the test-seed work). Because of this, the fix branch was based on `aw/odse-test-seed` rather than `main` and the branch contains the full comparison-fixtures content. If reviewing only the RTR-side fix (5a) is preferred, cherry-pick the 5a commit onto a fresh branch off `main`.

The original brief listed 10 condition-datamart SPs as sharing this bug, and hypothesized transaction-isolation as the root cause. Investigation ruled both out: only `sp_hepatitis_datamart_postprocessing` references `#TMP_F_PAGE_CASE` (the other 9 SPs use different temp-table structures and have unrelated 0-row symptoms that need separate investigation), and 5 isolation hypotheses (RCSI, BEGIN TRANSACTION scoping, NOLOCK, STRING_SPLIT type conv, parameter sniffing) were ruled out empirically.

No `testData/unit` fixture was added: the SP wraps each step in `BEGIN TRANSACTION/COMMIT`, so `job_flow_log` rows the test would assert on get rolled back at test-harness teardown. The 5a fix is verified via the repro path in `testing-tools/synthetic-odse-fixtures/bugs/05_tmp_f_page_case_family/repro.sql`.

## Checklist
- [ ] I have ensured that the pull request is of a manageable size, allowing it to be reviewed within a single session.
- [ ] I have reviewed my changes to ensure they are clear, concise, and well-documented.
- [ ] I have updated the documentation, if applicable.
- [ ] I have added or updated test cases to cover my changes, if applicable.
