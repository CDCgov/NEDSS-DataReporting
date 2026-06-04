# _quarantine

Fixtures here are excluded from `scripts/merge_and_verify.sh` (it globs
`30_sp_coverage/*.sql`; quarantined files carry a non-`.sql` suffix).

## Currently quarantined

- **`zz_hepatitis_datamart_round2.sql.tempdb-blowup`** (2026-05-25).
  Agent Q's hepatitis_datamart round-2 enrich (+61 cols claimed). In a
  full single-batch pipeline run its tail-EXEC chain
  (`sp_f_page_case_postprocessing` → `sp_hepatitis_datamart_postprocessing`,
  both keyed to PHC 22008500) spilled **~70GB into tempdb** and filled
  the host disk to 100%, wedging MSSQL — twice (the recurring blocker
  documented in `../../../BLOCKED.md`). The two SPs run fine
  incrementally on a warm DB (which is how the prior live session got
  Q's +61), but in the cold single-batch merge they run against the
  full dataset and a runaway join/spill blows up tempdb. Quarantined
  per LOOP.md's fixture-error rule to unblock a clean headline from the
  other ~38 Tier-3 fixtures. **Cost:** loses Q's +61 hep cols (live
  coverage falls back toward the pre-Q ~84% range). **Follow-up:**
  needs a bug writeup + an SP fix (or a tempdb cap so it fails loudly
  on just this fixture); restore once the runaway is fixed.

- **`zz_case_lab_datamart_enrich.sql.broken`** — Agent K's
  case_lab_datamart fixture; NOT NULL constraint failure on apply
  (quarantined in the round-2 loop).

- **`zz_hepatitis_obs_chain.sql.wrong-condition-no-datamart-row`**
  (2026-06-03). R4-D's first attempt: 139 HEP question observations hung
  off foundation PHC **22008500 (cond 10110)** to populate HEPATITIS_CASE
  / hep100. It applied cleanly and the obs flowed all the way to
  `v_rdb_obs_mapping` (139 rows verified live), but produced **zero**
  HEPATITIS_CASE rows. ROOT CAUSE (proven live): `sp_hepatitis_case_datamart_postprocessing`
  (routine 039) builds its insert from `#KEY_ATTR_INIT`, gated by
  `investigation_form_cd LIKE 'INV_FORM_HEP%'`. Condition 10110 maps in
  NBS_SRTE.condition_code to `investigation_form_cd='PG_Hepatitis_A_Acute_Investigation'`
  (no match), AND in `nrt_datamart_metadata` condition 10110 maps ONLY to
  `Hepatitis_Datamart` (routine 013), never `Hepatitis_Case` (039).
  job_flow_log step `GENERATING #KEY_ATTR_INIT` = row_count 0. The
  hepatitis_datamart SP (013) does NOT read obs at all, so these 139 obs
  also add nothing there — pure dead weight + a Tier-3 drain-flood risk
  (LESSON 8). Replaced by **`zz_hepatitis_case_chain.sql`** (new PHC
  22043000 under cond **10481** → form `INV_FORM_HEPGEN`, which both maps
  to Hepatitis_Case AND matches the `INV_FORM_HEP%` gate).

## Restored

- **`zz_lab100_101_fill.sql`** (bug #19, fixed 2026-06-04). Was quarantined
  as `.bug19-labtest-record-status-547`: re-landing it tripped
  `CHK_LABTEST_RECORD_STATUS` (Error 547) inside `sp_d_lab_test_postprocessing`
  at the "INSERTING new entries to LAB_TEST" step. ROOT CAUSE (proven via a
  reduced data-driven unit test, `reporting-pipeline-service/.../testData/unit/bug19_labtest_record_status/`):
  routine 018 derived `LAB_TEST.RECORD_STATUS_CD` as
  `COALESCE(#merge_order.RECORD_STATUS_CD_MERGE, #hierarchical_data.RECORD_STATUS_CD_FOR_RESULT_DRUG)`.
  The first source is normalized (PROCESSED→ACTIVE etc.) but is NULL when
  `root_ordered_test_pntr` does not resolve (merge_order join miss); the
  fallback then passed the RAW ancestor `record_status_cd` ('PROCESSED')
  straight into the insert. The working `zz_covid_lab_datamart_unblock.sql`
  never hit this because its simple Order/Result chain resolves
  `root_ordered_test_pntr`, so the normalized 'ACTIVE' wins first. FIX:
  routine 018 (line ~411) now normalizes the fallback identically to
  `RECORD_STATUS_CD_MERGE`, so no fixture can trip the CHECK. The fixture had
  no genuine data error, so it is restored unchanged.

## History (2026-05-21, Agent B Phase-2 debug pass)

This directory previously held COVID and Varicella full-chain fixtures
that were quarantined because they regressed the TB cluster in a merged
pipeline run. The root cause turned out to be trivial: both fixtures
were missing `SET IDENTITY_INSERT [dbo].[nbs_case_answer] ON/OFF` around
their `nbs_case_answer` INSERT block (same bug TB had originally — see
commit a7757dbc). The COVID INSERT failed mid-apply with
`Cannot insert explicit value for identity column in table
'NBS_case_answer' when IDENTITY_INSERT is set to OFF`. Because
`scripts/merge_and_verify.sh` runs `set -euo pipefail`, the COVID
fixture failure aborted Step 8 before TB's tail-EXECs ran, leaving
D_TB_PAM / F_TB_PAM / TB_DATAMART at 0 rows. There was no
cross-fixture interference — the two fixtures compose cleanly with
TB once the IDENTITY_INSERT toggle is added.

Both fixtures are now restored to `fixtures/30_sp_coverage/` with the
fix applied. Merged pipeline now lands at 33.6% column coverage
(+5.7pp over the prior 27.9% TB+STD+BMIRD baseline).

Keep this directory empty as a marker. Future quarantines should
allocate new sibling directories.
