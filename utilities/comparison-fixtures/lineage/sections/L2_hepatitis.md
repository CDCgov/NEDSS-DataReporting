# L2 — Hepatitis cluster

Tables: `HEPATITIS_DATAMART`, `HEP100`, `HEP_MULTI_VALUE_FIELD_GROUP`
(the "hepatitis_case" subject), `LDF_HEPATITIS`.

Writing SPs:
`sp_hepatitis_datamart_postprocessing` (013),
`sp_hep100_datamart_postprocessing` (042),
`sp_hepatitis_case_datamart_postprocessing` (039),
`sp_ldf_hepatitis_datamart_postprocessing` (320).

Column appendix slice: `lineage/columns/L2_hepatitis.tsv` (398 rows).
Status mix: **330 VERIFIED · 65 BLOCKED:tempdb · 2 INFERRED · 1 DYNAMIC.**
This reconciles exactly with `coverage/coverage_merged.md`:
HEP100 185/187, HEP_MULTI 1/1, HEPATITIS_DATAMART 144/209, LDF 0/7.

All four SPs are datamart-postprocessing SPs with **no `_event`
partner**: per STRATEGY.md's convention, they read already-populated
RDB_MODERN dimensions/staging (`nrt_*`, the `D_INV_*` page-builder
dims, `F_PAGE_CASE`), never `nbs_odse.dbo.*` directly. The ODSE edge is
therefore one hop further upstream — ODSE `public_health_case` /
`nbs_case_answer` / `observation` rows flow into `nrt_investigation` /
`nrt_page_case_answer` (production: CDC→Debezium→Kafka; fixtures:
hand-authored), get pivoted into the `D_INV_<cat>` dimensions by the
page-builder chain (`sp_s_pagebuilder_*` → `sp_d_pagebuilder_*`), and
only then are read by the Hepatitis datamart SP. The `odse_source_col(s)`
column in the appendix names that upstream origin; the
`transform_note` names the dimension hop.

## HEPATITIS_DATAMART (144/209 VERIFIED, 65 BLOCKED:tempdb)

Row flow (SP 013): the SP builds `#TMP_HEPATITIS_CASE_BASE` by a wide
`SELECT DISTINCT … INTO` (lines 1853–2097) that FULL-OUTER-JOINs the
`INVESTIGATION` dim (`I.`) to twelve page-builder dimensions keyed on
`INVESTIGATION_KEY`: `D_INV_LAB_FINDING` (`L.`),
`D_INV_RISK_FACTOR` (`R.`), `D_INV_EPIDEMIOLOGY` (`E.`),
`D_Patient` (`P.`), `D_INV_VACCINATION` (`V.`), `D_INV_TRAVEL` (`T.`),
`D_INV_MOTHER` (`M.`), `D_INV_MEDICAL_HISTORY` (`MH.`),
`D_INV_ADMINISTRATIVE` (`A.`), `D_INV_PATIENT_OBS` (`PO.`),
`D_INV_CLINICAL` (`C.`), a provider/org/reporting-source bundle
`#TMP_HEP_PAT_PROV` (`HP.`, joined off `F_PAGE_CASE` keys to
`D_PROVIDER`/`D_ORGANIZATION`), and a vaccination-repeat pivot
`#TMP_VAC_REPEAT_OUT_FINAL` (`VAC.`). Each datamart column's source
prefix in the appendix is taken straight from this SELECT, so the
ODSE origin is the corresponding `nbs_case_answer` answer (LAB_*,
RSK_*, EPI_*, etc.) for the page-builder dims, `public_health_case`
for the `I.` columns, and provider/organization participations for the
`HP.` columns.

Gating predicates: the SP filters on Hepatitis condition codes
(`condition_cd IN ('10110','10104','10100','10106','10101','10102',
'10103','10105','10481','50248','999999')`; the fixture uses 10110
Hep A acute). The load-bearing gate is the
`DELETE FROM #TMP_HEPATITIS_CASE_BASE WHERE PATIENT_UID IS NULL`
(line ~2148): if `nrt_investigation.patient_id` is NULL,
`sp_f_page_case_postprocessing`'s `COALESCE(PATIENT.PATIENT_KEY, 1)`
falls back to the sentinel patient (UID NULL) and the row is deleted,
yielding 0 datamart rows. This is the bug-5b cascade documented in
`coverage/coverage_hep_datamart_investigation.md` and
`bugs/05_tmp_f_page_case_family/`. Notable transforms: numeric-string
guarding (`NOT LIKE N'%[^0-9.,-]%' AND ISNUMERIC = 1`) on
`LAST6PLUSMO_INCAR_*` / sex-partner / STD-year columns; control-char
stripping on `INV_COMMENTS`; `SUBSTRING` truncation on
`BINATIONAL_RPTNG_CRIT` (300) and `TEST_REASON_OTH` (150);
`HEP_D_TEST_IND` Yes/No→Y/N/U recode; `VACC_GT_4_IND` empty→'False';
`EVENT_DATE` / `EVENT_DATE_TYPE` are SP literals (`CAST(NULL …)`).

The **144 VERIFIED** columns are populated by
`fixtures/30_sp_coverage/zz_hepatitis_datamart_enrich.sql` (Round 1),
which direct-INSERTs the `D_INV_*` dimensions plus their `L_INV_*` link
rows for PHC 22008500 (the page-builder answer→S_INV→D_INV pivot does
not propagate in this DB, so the dims are seeded directly), then
tail-EXECs `sp_f_page_case_postprocessing` and
`sp_hepatitis_datamart_postprocessing`. `INIT_NND_NOT_DT` is also
populated via the notification chain (`sp_nrt_notification_postprocessing`
UPDATE) at merge step 9.

The **65 BLOCKED:tempdb** columns are exactly the ones Agent Q's Round 2
fixture was meant to light up:
`fixtures/30_sp_coverage/_quarantine/zz_hepatitis_datamart_round2.sql.tempdb-blowup`.
They are: the full `D_INV_RISK_FACTOR` (`R.`) set (~39 cols — RSK_* was
explicitly skipped in Round 1 over numeric-cast concerns); the
provider/org/reporting-source (`HP.`) bundle (PHYS_*, INVESTIGATOR_*,
RPT_SRC_*, *_UID — 13 cols); the three `INVESTIGATION`-UPDATE cols
(INV_COMMENTS, INV_START_DT, PAT_PREGNANT_IND); and the
vaccination-repeat pivot outputs (VACC_DOSE_NBR_1..4, VACC_RECVD_DT_1..4,
IMM_GLOB_RECVD_IND, GLOB_LAST_RECVD_YR — 10 cols). **These are NOT in
the live 89.6% coverage.** Round 2 verified them on a *warm*
incremental DB (140→201), but on the deterministic cold single-batch
rebuild its tail-EXEC chain (`sp_f_page_case_postprocessing` →
`sp_hepatitis_datamart_postprocessing`, PHC 22008500) spilled ~70 GB
into tempdb and crashed MSSQL twice (ENOSPC). Per LOOP's
fixture-error rule the file was renamed to a non-`.sql` suffix and
parked under `_quarantine/` (see `BLOCKED.md` and the `_quarantine/`
README). Restoring it needs an upstream fix to the runaway
join/spill in those two SPs (or a tempdb MAX_SIZE cap that fails loudly
on just this fixture). Marked `BLOCKED:tempdb` rather than VERIFIED
accordingly. (Note: the briefing's "bug #14" label does not have a
`bugs/14_*` dir — bug dirs run 01–13 — so the quarantine is tracked
via `BLOCKED.md`/`_quarantine/README.md`, not a numbered bug.)

## HEP100 (185/187 VERIFIED, 2 INFERRED)

Row flow (SP 042): HEP100 does **not** read `HEPATITIS_DATAMART`. It
builds `#HEP100_INIT` by selecting `FROM dbo.HEPATITIS_CASE hc`
(line 349) and joining the patient/provider/investigation dimensions,
then INSERTs into `HEP100` (line 601). So the chain is
`HEPATITIS_CASE → HEP100`, with `HEPATITIS_CASE` itself being the
observation-pivot output (see next section). The clinical/risk/epi
columns are carried straight from `HEPATITIS_CASE`; patient
demographics come from the `nrt_patient`-fed `D_PATIENT` join;
physician/investigator/reporting-source columns from
`D_PROVIDER`/`D_ORGANIZATION`; investigation attributes via the
`INVESTIGATION` dim. The notable derived column is `EVENT_DATE`,
computed from a date-coalesce precedence lifted from the classic SAS
ETL (Illness_onset → Diagnosis → earliest of report/admit/discharge
dates; SP comment lines 61–82).

The unblock fixture
(`fixtures/30_sp_coverage/zz_hepatitis_zz_hep100_unblock.sql`)
direct-INSERTs one richly-populated `HEPATITIS_CASE` row keyed to the
Hep A investigation (CASE_UID 22008500), because `HEPATITIS_CASE` has 0
rows in the baseline and no routine-layer SP writes it from ODSE — it
is normally a Kafka/Debezium-streamed table. The fixture resolves
`INVESTIGATION_KEY` dynamically (an earlier hardcoded `=26` broke the
FK on clean rebuilds) and self-heals if the dim row is missing. With
that one row, the SP's `INNER JOIN (HC.investigation_key =
I.investigation_key)` is satisfied and HEP100 populates 185/187 live.
The 2 INFERRED gaps are `ADDR_CD_DESC` / `ADDR_USE_CD_DESC`
(address-type code descriptors) — guarded patient-dim columns
(also written by `sp_patient_dim_columns_update_to_datamart`) that
stay NULL because the seeded patient locator carries no address-use /
address-type code. Not blocked, just unseeded.

## HEP_MULTI_VALUE_FIELD_GROUP (1/1 VERIFIED) — the "hepatitis_case" subject

`sp_hepatitis_case_datamart_postprocessing` (039) is a **dynamic-pivot**
SP (`@tgt_table_nm='Hepatitis_Case'`, `@multival_tgt_table_nm =
'HEP_Multi_Value_Field'`). It reads observation values through
`dbo.v_rdb_obs_mapping` — splitting coded / text / date / numeric
answer values into `#OBS_*_Hepatitis_Case` temp tables filtered by
`RDB_TABLE = @tgt_table_nm` — and writes `HEPATITIS_CASE` plus the
multi-value group table `HEP_MULTI_VALUE_FIELD_GROUP`. The single
cataloged column `HEP_MULTI_VAL_GRP_KEY` is a surrogate group key
assigned per multi-value answer group; its ODSE origin is the
`observation` rows mapped to `HEP_Multi_Value_Field`. Live coverage
shows 1/1 (the group-key row is present), so it is VERIFIED via the
hep100 unblock fixture's seeded `HEPATITIS_CASE`/group context.

Note the coverage-report nuance: the 2026-05-19 investigation
(`coverage_hep_datamart_investigation.md`, line 138) found that
`sp_hepatitis_case_datamart_postprocessing` itself produces **0** rows
of `HEPATITIS_CASE` end-to-end, because it needs `NBS_case_answer`-style
observation data that the fixtures don't seed through the pivot path.
That is why the HEP100 unblock fixture takes the direct-INSERT
shortcut on `HEPATITIS_CASE` rather than relying on SP 039.

## LDF_HEPATITIS (0/7 — DYNAMIC, LDF chain blocked)

`sp_ldf_hepatitis_datamart_postprocessing` (320) is an LDF
(locally-defined-field) datamart SP: its columns are **dynamic** —
the SP `ALTER TABLE`s `LDF_HEPATITIS` per the LDF-template metadata for
the condition, then dynamically INSERTs answer values keyed on
`nrt_ldf` / `nrt_page_case_answer`. There is no static ODSE→column map;
the catalog represents the whole table as one `dynamiccolumnList`
entry. Live coverage is **0/7**: the LDF chain is blocked upstream —
`sp_nrt_ldf_dimensional_data_postprocessing` early-returns producing 0
rows of `LDF_DIMENSIONAL_DATA` (`bugs/07_ldf_dimensional_data_zero/`),
and the related LDF truncation issue (`bugs/06_ldf_data_truncation/`,
fixed on main) sits on the same path. The fixture does tail-EXEC
`sp_ldf_hepatitis_datamart_postprocessing` (@phc_uids='22008500') but
no LDF columns populate. Flagged `DYNAMIC` with the LDF-chain block
noted (`BLOCKED:#07`).

## Summary of what's blocked vs. covered

- **Covered live (the 89.6% run):** HEPATITIS_DATAMART 144/209
  (Round 1 enrich), HEP100 185/187, HEP_MULTI 1/1.
- **Blocked / not in the headline:** HEPATITIS_DATAMART's Round 2 +65
  (RSK_*, provider/org, vaccination-repeat, 3 investigation cols) —
  quarantined for the tempdb blowup; LDF_HEPATITIS 0/7 — LDF
  dimensional-data chain (bug #07); HEP100 2 address-descriptor cols —
  unseeded (INFERRED).
