# _quarantine

Fixtures here are excluded from `scripts/merge_and_verify.sh` (it globs
`30_sp_coverage/*.sql`; quarantined files carry a non-`.sql` suffix). Each file's
suffix states why it is out: `.broken` / `.apply-error-*` / `.generated-always-violation`
fail on apply; `.tempdb-blowup` is a resource runaway; `.odse-only-superseded-by-*` was
replaced by an ODSE-only sibling; `.no-datamart-row-*` / `.partial-*` are incomplete
chains; `.ordering-dep-*` / `.regresses-*` are run-order or cross-fixture conflicts. To
quarantine, rename a fixture with such a suffix; to restore, rename it back to `.sql`.

## Currently quarantined

- **`zz_hepatitis_datamart_round2.sql.tempdb-blowup`** (2026-05-25).
  A hepatitis_datamart round-2 enrich (+61 columns claimed). In a
  full single-batch pipeline run its tail-EXEC chain
  (`sp_f_page_case_postprocessing` → `sp_hepatitis_datamart_postprocessing`,
  both keyed to PHC 22008500) spilled **~70GB into tempdb** and filled
  the host disk to 100%, wedging MSSQL twice. The two SPs run fine
  incrementally on a warm DB (which is how the prior run got
  the +61), but in the cold single-batch merge they run against the
  full dataset and a runaway join/spill blows up tempdb. Quarantined
  per the fixture-error rule to unblock a clean headline from the
  other ~38 Tier-3 fixtures. **Cost:** loses the +61 hepatitis columns (live
  coverage falls back toward the pre-enrich ~84% range). **Follow-up:**
  needs a bug writeup + an SP fix (or a tempdb cap so it fails loudly
  on just this fixture); restore once the runaway is fixed.

- **`zz_case_lab_datamart_enrich.sql.broken`**: a
  case_lab_datamart fixture with a NOT NULL constraint failure on apply
  (quarantined in round 2).

- **`zz_hepatitis_obs_chain.sql.wrong-condition-no-datamart-row`**
  (2026-06-03). The hepatitis chain's first attempt: 139 HEP question observations hung
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
  also add nothing there: pure dead weight plus a Tier-3 drain-flood risk
  (LESSON 8). Replaced by **`zz_hepatitis_case_chain.sql`** (new PHC
  22043000 under cond **10481** → form `INV_FORM_HEPGEN`, which both maps
  to Hepatitis_Case AND matches the `INV_FORM_HEP%` gate).

## ODSE-only conversion (2026-06-05)

Quarantined as part of the **ODSE-only invariant** remediation: fixtures must
author only NBS_ODSE rows and let the RTR pipeline derive everything in
RDB_MODERN. These 10 carried direct RDB_MODERN writes whose coverage is either
already produced by the pipeline or by an existing ODSE-only sibling, so they are
retired from the active set rather than rewritten. Full triage +
per-fixture recipes in `../../../docs/ODSE_ONLY_CONVERSION.md`.

- **`f_page_case_unblock.sql.odse-only-form_cd-derived-from-condition_code`**:
  only content was `UPDATE nrt_investigation SET INVESTIGATION_FORM_CD=...`.
  That value is derived by 056-sp_investigation_event from ODSE PHC `cd='10110'`
  + SRTE `condition_code` (form_cd is not a PHC column), so it is redundant under the
  ODSE-only design.
- **`zz_inv_summ_datamart_unblock.sql.odse-only-inv_summ_datamart-sp-derived`**:
  injected one synthetic INV_SUMM_DATAMART row "even if the SP no-ops". 045 already
  produces real rows for the 30 investigations; the seed was cosmetic. (No bug #21
  exists in `bugs/`.)
- **`zz_hepatitis_zz_hep100_unblock.sql.odse-only-hepatitis_case-pipeline-derived`**:
  direct INSERT into HEPATITIS_CASE under a false "no SP writes it" premise.
  039-sp_hepatitis_case_datamart writes it via dynamic SQL; live DB already has a
  pipeline-derived HEPATITIS_CASE row (PHC 22043000). Not the TMP_F_PAGE_CASE bug
  (that gates 013/HEPATITIS_DATAMART only).
- **`zz_covid_case_datamart_round2.sql.odse-only-superseded-by-zz_covid_dedicated_entities`**:
  hand-wrote D_PROVIDER/D_ORGANIZATION + nrt_investigation FK repoint; superseded by
  the ODSE-only `zz_covid_dedicated_entities.sql` (5/7 sections were empty stubs; its
  nrt_investigation UPDATE regressed correct ODSE values).
- **`zz_covid_contact_datamart_enrich.sql.odse-only-superseded-by-covid-contact-fill+side`**:
  patched D_PATIENT/nrt_patient/nrt_contact for a patient (20000000) no longer linked
  to the COVID PHC; coverage carried by `zz_covid_contact_fill.sql` +
  `zz_covid_dedicated_entities.sql` + `zz_covid_contact_side.sql`.
- **`zz_covid_vaccination_datamart_enrich.sql.odse-only-superseded-by-zz_covid_vaccination_gap`**:
  hand-wrote D_PATIENT/D_PROVIDER/D_ORGANIZATION/D_VACCINATION; self-defeating (no
  NRT_VACCINATION row, so the dims were never joined). Covered by the ODSE-only
  `zz_covid_vaccination_gap.sql`.
- **`zz_enrich_vaccination.sql.odse-only-superseded-by-zz_covid_vaccination_gap`**:
  `UPDATE nrt_vaccination` overwriting a Hep-A row's material_cd to COVID '208' (not
  ODSE-backed). Covered by `zz_covid_vaccination_gap.sql`.
- **`zz_d_contact_record_enrich.sql.odse-only-superseded-by-zz_contact_record_gap`**:
  wrote nrt_contact_answer + seeded NRT_METADATA_COLUMNS (a second, deeper violation).
  Covered ODSE-only by `zz_contact_record_gap.sql`.
- **`zz_d_inv_place_repeat_enrich.sql.odse-only-superseded-by-zz_d_inv_place_repeat`**:
  self-declared "now-inert", but still carried a `DELETE FROM nrt_page_case_answer`.
  Superseded by the ODSE-only `zz_d_inv_place_repeat.sql`.
- **`zz_lab101_unblock.sql.odse-only-superseded-by-zz_lab100_101_fill-partB`**:
  hand-built the LAB101 LAB_* hierarchy in RDB_MODERN; `zz_lab100_101_fill.sql` Part B
  authors the same chain ODSE-only and the pipeline derives the LAB_* rows. (LAB101
  datamart fullness is separately gated by bug #16, tracked against the ODSE path.)

## Other quarantined (reason in the suffix)

- **`zz_d_investigation_repeat_forms_3.sql.ordering-dep-on-hep2-phc-22076100`**: depends on a Hep-2 PHC (22076100) authored by a later fixture, so it is not safe in the plain alphabetical apply order.
- **`zz_lab101_fill.sql.partial-5of46-tick6-dvarpam-suspect`**: filled only 5/46 LAB101 columns and is suspected of perturbing D_VAR_PAM; superseded by the LAB100/101 fill.
- **`zz_tb_datamart_addl_chain.sql.no-datamart-row-incomplete-chain`** / **`zz_var_datamart_addl_chain.sql.apply-error-msg515`**: incomplete TB / VAR datamart chains (no datamart row produced; Msg 515 on apply).
- **`zz_tb_datamart_enrich_r3.sql.generated-always-violation`**: writes a `GENERATED ALWAYS` column.
- **`zz_var_datamart_enrich_r3.sql.regresses-shared-var-datamart`**: regresses the shared VAR_DATAMART coverage.

## Restored

- **`zz_lab100_101_fill.sql`** (APP-737, fixed 2026-06-04). Was quarantined
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

## History (2026-05-21, Phase-2 debug pass)

This directory previously held COVID and Varicella full-chain fixtures
that were quarantined because they regressed the TB cluster in a merged
pipeline run. The root cause turned out to be trivial: both fixtures
were missing `SET IDENTITY_INSERT [dbo].[nbs_case_answer] ON/OFF` around
their `nbs_case_answer` INSERT block (same bug TB had originally; see
commit a7757dbc). The COVID INSERT failed mid-apply with
`Cannot insert explicit value for identity column in table
'NBS_case_answer' when IDENTITY_INSERT is set to OFF`. Because
`scripts/merge_and_verify.sh` runs `set -euo pipefail`, the COVID
fixture failure aborted the merge run (historically, before TB's
postprocessing completed), leaving D_TB_PAM / F_TB_PAM / TB_DATAMART at
0 rows. (`set -euo pipefail` still aborts the run on any fixture apply
error.) There was no
cross-fixture interference: the two fixtures compose cleanly with
TB once the IDENTITY_INSERT toggle is added.

Both fixtures are now restored to `fixtures/30_sp_coverage/` with the
fix applied. Merged pipeline now lands at 33.6% column coverage
(+5.7pp over the prior 27.9% TB+STD+BMIRD baseline).

Quarantine and restore are just renames (drop or re-add the `.sql` extension);
the reason lives in the filename suffix, not in a sibling directory.
