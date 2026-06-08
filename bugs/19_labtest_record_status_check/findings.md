# Bug #19: sp_d_lab_test_postprocessing inserts non-ACTIVE/INACTIVE RECORD_STATUS_CD into LAB_TEST (Error 547)

**Symptom:** `Error 547: The INSERT statement conflicted with the CHECK constraint "CHK_LABTEST_RECORD_STATUS" ... table "dbo.LAB_TEST", column 'RECORD_STATUS_CD'` at routine 018 (`sp_d_lab_test_postprocessing`) step "INSERTING new entries to LAB_TEST" (~line 909/915). `CHK_LABTEST_RECORD_STATUS` allows only `RECORD_STATUS_CD IN ('ACTIVE','INACTIVE')`.

**Trigger:** re-landing `zz_lab100_101_fill.sql` (lab obs UIDs 22053xxx). Routine 018 derives `LAB_TEST.RECORD_STATUS_CD` from the lab observation chain; for this fixture's obs the value is something other than ACTIVE/INACTIVE (the obs carry `record_status_cd='PROCESSED'`, but note the WORKING covid-lab fixture's obs ALSO use 'PROCESSED' and do NOT 547, so the discriminator is subtler: likely a specific lab-result child obs in this fixture with a NULL/blank status, or a difference in which obs routine 018 maps). Throws -> DataProcessingException -> fail-fast skip of lower-priority entities (contributes to the d_var_pam/obs-set instability alongside bug #17).

**Status: FIXED (2026-06-04, branch aw/fix-bug17-labtest-keygen-race).**

**Root cause (proven):** routine 018 builds `LAB_TEST.RECORD_STATUS_CD` as
`COALESCE(#merge_order.RECORD_STATUS_CD_MERGE, #hierarchical_data.RECORD_STATUS_CD_FOR_RESULT_DRUG)`
(line ~550). `RECORD_STATUS_CD_MERGE` (line ~495) IS normalized
(`'' / 'UNPROCESSED' / 'UNPROCESSED_PREV_D' / 'PROCESSED' / NULL → 'ACTIVE'`,
`'LOG_DEL' → 'INACTIVE'`, else raw) and is keyed on `root_ordered_test_pntr`.
But `RECORD_STATUS_CD_FOR_RESULT_DRUG` (line ~411) was the RAW
`COALESCE(tst2/tst3/tst4/obs3.record_status_cd)` of the report_sprt/refr/observation
ancestor, NOT normalized. When a lab test's `root_ordered_test_pntr` resolves to
NULL, the `#merge_order` join misses (NULL <> NULL) so `RECORD_STATUS_CD_MERGE` is
NULL and the COALESCE falls through to the raw fallback. If that ancestor carries
`record_status_cd='PROCESSED'`, the raw 'PROCESSED' is inserted into
`LAB_TEST.RECORD_STATUS_CD`, which violates `CHK_LABTEST_RECORD_STATUS` and raises Error 547.
The working `zz_covid_lab_datamart_unblock.sql` never hits this: its simple
Order/Result chain resolves `root_ordered_test_pntr`, so `#merge_order` matches and
the normalized 'ACTIVE' wins before the raw fallback is ever reached. The new
fixture's deeper I_Order/I_Result hierarchy yields a NULL `root_ordered_test_pntr`,
exposing the un-normalized fallback. (Both fixtures use obs `record_status_cd='PROCESSED'`,
which is why "PROCESSED" alone was not the discriminator.)

**Fix:** routine 018 line ~411 now normalizes `RECORD_STATUS_CD_FOR_RESULT_DRUG`
with the same CASE mapping as `RECORD_STATUS_CD_MERGE`, so the inserted
`RECORD_STATUS_CD` is always a valid 'ACTIVE'/'INACTIVE' (durable: no fixture can
trip the CHECK). Verified RED-to-GREEN via the data-driven unit test
`reporting-pipeline-service/src/test/resources/testData/unit/bug19_labtest_record_status/`.
`zz_lab100_101_fill.sql` un-quarantined (no genuine fixture-data error; the routine
fix covers it).
