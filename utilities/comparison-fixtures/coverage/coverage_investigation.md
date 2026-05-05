# Coverage: investigation (Tier 1)

## Inputs

- Baseline: 6.0.18.1
- UID range allocated: 20050000–20059999 (Investigation Tier 1)
- Foundation dependencies (read-only):
  - `@dbo_Act_investigation_uid = 20000100` (act + public_health_case)
  - `@dbo_Entity_patient_uid = 20000000` (referenced as `nrt_investigation.patient_id` on v2 — soft reference; SP does not validate)
- Other-agent dependencies: none (Tier 1 is additive; no cross-subject Tier 2 edges authored)

## SPs verified

- `dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'` — exit code: 0 / contract test only (event SP emits a SELECT projection; no row writes).
  - `job_flow_log` Investigation PRE-Processing Event entry: `Status_Type='COMPLETE'`.
- `dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0` — exit code: 0 / rows-written: 2 INVESTIGATION rows + 1 confirmation_method row + 2 CONFIRMATION_METHOD_GROUP rows.
  - `job_flow_log` Investigation POST-Processing entry: `step_name='SP_COMPLETE'`, `Status_Type='COMPLETE'` (step_number 6).

## Iteration count

1 baseline reset + 1 in-place re-apply (after fixing `case_management` IDENTITY_INSERT and an off-by-2 column-count mismatch in the first-cut nrt_investigation INSERT). Final apply + SP chain clean from a fresh `docker compose down -v && up -d`.

## INVESTIGATION coverage

Live `dbo.INVESTIGATION` column count: **71** (catalog says 72; minor drift, see `rtr_target_columns.md`'s warning above the INVESTIGATION section).

The postprocessing SP writes **all 71** INVESTIGATION columns (`INVESTIGATION_KEY` is allocated by IDENTITY in `nrt_investigation_key`; the remaining 70 are the values list in the SP's INSERT at lines 536–678; one of those — `INVESTIGATION_KEY` — comes from the just-inserted `nrt_investigation_key.d_INVESTIGATION_KEY`).

**Populated / total: 71 / 71 across both variants combined.**

Per variant:

- Foundation Investigation (`CASE_UID = 20000100`, `INVESTIGATION_KEY = 3` in our run): 11 columns populated. The remaining 60 columns are deliberately NULL — the foundation `public_health_case` row is left mostly NULL (case_class_cd, cd_system_cd, outcome_cd, hospitalized_ind_cd, etc. all NULL) so the SP's `NULLIF`/`CASE WHEN ... null/blank` paths are observable.
- v2 Investigation (`CASE_UID = 20050010`, `INVESTIGATION_KEY = 4`): all 71 columns populated.

### INVESTIGATION columns populated (per variant) — 71/71

| Column | Foundation | v2 | Sample value (v2) |
| --- | --- | --- | --- |
| INVESTIGATION_KEY | yes | yes | 4 |
| CASE_OID | NULL | yes | 20050010 |
| CASE_UID | yes | yes | 20050010 |
| INV_LOCAL_ID | yes | yes | CAS20050010GA01 |
| INV_SHARE_IND | yes | yes | T |
| OUTBREAK_NAME | NULL | yes | V2 Hepatitis Outbreak |
| INVESTIGATION_STATUS | NULL | yes | Open |
| INV_CASE_STATUS | NULL | yes | Confirmed |
| CASE_TYPE | yes | yes | I |
| INV_COMMENTS | NULL | yes | Tier 1 v2 investigation comments — exercises every INV_COMMENTS column. |
| JURISDICTION_CD | yes | yes | 130001 |
| JURISDICTION_NM | NULL | yes | Fulton County |
| EARLIEST_RPT_TO_PHD_DT | NULL | yes | 2026-04-06 |
| ILLNESS_ONSET_DT | NULL | yes | 2026-04-01 |
| ILLNESS_END_DT | NULL | yes | 2026-04-15 |
| INV_RPT_DT | NULL | yes | 2026-04-04 |
| INV_START_DT | NULL | yes | 2026-04-01 |
| RPT_SRC_CD_DESC | NULL | yes | Private Physician Office |
| EARLIEST_RPT_TO_CNTY_DT | NULL | yes | 2026-04-05 |
| EARLIEST_RPT_TO_STATE_DT | NULL | yes | 2026-04-06 |
| CASE_RPT_MMWR_WK | NULL | yes | 14 |
| CASE_RPT_MMWR_YR | NULL | yes | 2026 |
| DISEASE_IMPORTED_IND | NULL | yes | Indigenous |
| IMPORT_FRM_CNTRY | NULL | yes | United States |
| IMPORT_FRM_STATE | NULL | yes | Georgia |
| IMPORT_FRM_CNTY | NULL | yes | Fulton County |
| IMPORT_FRM_CITY | NULL | yes | Atlanta |
| EARLIEST_RPT_TO_CDC_DT | NULL | yes | 2026-04-07 |
| RPT_SRC_CD | NULL | yes | PP |
| IMPORT_FRM_CNTRY_CD | NULL | yes | 840 |
| IMPORT_FRM_STATE_CD | NULL | yes | 13 |
| IMPORT_FRM_CNTY_CD | NULL | yes | 13121 |
| IMPORT_FRM_CITY_CD | NULL | yes | 13 |
| DIAGNOSIS_DT | NULL | yes | 2026-04-03 |
| HSPTL_ADMISSION_DT | NULL | yes | 2026-04-03 |
| HSPTL_DISCHARGE_DT | NULL | yes | 2026-04-08 |
| HSPTL_DURATION_DAYS | NULL | yes | 5 |
| OUTBREAK_IND | NULL | yes | Yes |
| HSPTLIZD_IND | NULL | yes | Yes |
| INV_STATE_CASE_ID | NULL | yes | V2-STATE-CASE-01 |
| CITY_COUNTY_CASE_NBR | NULL | yes | CCN-V2-01 |
| TRANSMISSION_MODE | NULL | yes | Bloodborne |
| RECORD_STATUS_CD | yes | yes | ACTIVE |
| PATIENT_PREGNANT_IND | NULL | yes | Yes |
| DIE_FRM_THIS_ILLNESS_IND | NULL | yes | Yes |
| DAYCARE_ASSOCIATION_IND | NULL | yes | No |
| FOOD_HANDLR_IND | NULL | yes | No |
| INVESTIGATION_DEATH_DATE | NULL | yes | 2026-04-09 |
| PATIENT_AGE_AT_ONSET | NULL | yes | 45 |
| PATIENT_AGE_AT_ONSET_UNIT | NULL | yes | Years |
| INV_ASSIGNED_DT | NULL | yes | 2026-04-02 |
| DETECTION_METHOD_DESC_TXT | NULL | yes | Active Surveillance |
| ILLNESS_DURATION | NULL | yes | 15 |
| ILLNESS_DURATION_UNIT | NULL | yes | Days |
| CONTACT_INV_COMMENTS | NULL | yes | Tier 1 v2 contact investigation comments |
| CONTACT_INV_PRIORITY | NULL | yes | HIGH |
| CONTACT_INFECTIOUS_FROM_DATE | NULL | yes | 2026-04-01 |
| CONTACT_INFECTIOUS_TO_DATE | NULL | yes | 2026-04-15 |
| CONTACT_INV_STATUS | NULL | yes | O |
| INV_CLOSE_DT | NULL | yes | 2026-04-30 |
| PROGRAM_AREA_DESCRIPTION | NULL | yes | Hepatitis |
| ADD_TIME | yes | yes | 2026-04-01 |
| LAST_CHG_TIME | yes | yes | 2026-04-01 |
| INVESTIGATION_ADDED_BY | yes | yes | Foundation, Superuser |
| INVESTIGATION_LAST_UPDATED_BY | yes | yes | Foundation, Superuser |
| REFERRAL_BASIS | NULL | yes | Awaiting Interview |
| CURR_PROCESS_STATE | NULL | yes | Open |
| INV_PRIORITY_CD | NULL | yes | HIGH |
| COINFECTION_ID | NULL | yes | COINF-V2-01 |
| LEGACY_CASE_ID | NULL | yes | LEGACY-CASE-V2-01 |
| OUTBREAK_NAME_DESC | NULL | yes | Hepatitis Outbreak |

## confirmation_method coverage

3 columns, all populated for the new row inserted on the v2 Investigation:

| Column | Foundation v variant | v2 variant | Sample value |
| --- | --- | --- | --- |
| CONFIRMATION_METHOD_KEY | n/a (no nrt_investigation_confirmation row for foundation Investigation) | yes | 4 (allocated via `nrt_confirmation_method_key` IDENTITY) |
| CONFIRMATION_METHOD_CD | n/a | yes | LD |
| CONFIRMATION_METHOD_DESC | n/a | yes | Laboratory confirmed |

The CM_KEY=4 row is a NEW row inserted by the SP — baseline `confirmation_method` only contains keys 1 (NULL/NULL) and 3 (NA). The SP correctly inserts via `nrt_confirmation_method_key` IDENTITY allocation when the staging row's `confirmation_method_cd` is not in the dimension.

## CONFIRMATION_METHOD_GROUP coverage

3 columns, all populated for both INVESTIGATION rows:

| Column | Foundation | v2 | Sample value (v2) |
| --- | --- | --- | --- |
| INVESTIGATION_KEY | yes (3) | yes (4) | 4 |
| CONFIRMATION_METHOD_KEY | yes (1 — SP's `coalesce(cm.CONFIRMATION_METHOD_KEY, 1)` fallback because foundation has no nrt_investigation_confirmation row) | yes (4) | 4 |
| CONFIRMATION_DT | NULL (no CM row → NULL on foundation) | yes | 2026-04-10 |

## Columns deliberately skipped

Within scope of `sp_nrt_investigation_postprocessing`'s INVESTIGATION write set, **no columns are skipped** — every column populated for at least one variant. The foundation row exhibits NULL for 60 of 71 columns by design, exercising the SP's null/blank-handling path.

The postprocessing SP also includes a "Legacy Investigation" branch (lines 198–385) that only fires when `investigation_form_cd IN (...)` — a list of 14 legacy form codes (INV_FORM_BMDGAS, INV_FORM_HEPGEN, INV_FORM_RUB, etc.). The v2 Investigation uses `investigation_form_cd = 'PG_Hepatitis_A_Acute_Investigation'` which is **not** in that list, so the legacy-coded-observation overlay update does not run. This is consistent with current production data shapes for Hepatitis A and is left to a future Tier 3 fixture if legacy-form coverage is needed.

## Cross-subject UID columns left NULL on `nrt_investigation` (Tier 2 to populate)

These are columns on `nrt_investigation` that exist purely to carry foreign-key links to other subjects. The `INVESTIGATION` dimension does NOT directly read them in the postprocessing SP's write set, so leaving them NULL does not affect INVESTIGATION coverage. They are populated by the event SP's joins to `participation` / `act_relationship` / `nbs_act_entity` (which Tier 2 will provide) and consumed by **downstream** dimensions / facts (sp_public_health_case_fact_datamart_*, datamart SPs, sp_dyn_dm_*). All listed under LINK_REQUIRED below.

| nrt_investigation column | Source edge type (per `catalog/edge_types.md`) | Downstream consumer |
| --- | --- | --- |
| `patient_id` | participation `SubjOfPHC` (Patient → PHC) | F_PAGE_CASE / datamart fact assemblies |
| `physician_id` | participation `PhysicianOfPHC` (Provider → PHC) | F_PAGE_CASE / D_INVESTIGATION_REPEAT |
| `investigator_id` | participation `InvestgrOfPHC` (Provider → PHC) | F_PAGE_CASE / sp_inv_summary_datamart |
| `organization_id` | participation `OrgAsReporterOfPHC` (Org → PHC) | F_PAGE_CASE / Hepatitis_Datamart |
| `phc_inv_form_id` | act_relationship `LabReport` / `MorbReport` to PHC | F_PAGE_CASE |
| `nac_page_case_uid` | nbs_act_entity rows (multiple `*OfPHC` type_cds) | F_PAGE_CASE / sp_inv_summary_datamart |
| `person_as_reporter_uid` | nbs_act_entity `PerAsReporterOfPHC` | sp_inv_summary_datamart |
| `hospital_uid` | nbs_act_entity `HospOfADT` | F_PAGE_CASE |
| `ordering_facility_uid` | nbs_act_entity `OrgAsClinicOfPHC` | F_PAGE_CASE |
| `ca_supervisor_of_phc_uid` | nbs_act_entity `CASupervisorOfPHC` | (datamart-side) |
| `closure_investgr_of_phc_uid` | nbs_act_entity `ClosureInvestgrOfPHC` | (datamart-side) |
| `dispo_fld_fupinvestgr_of_phc_uid` | nbs_act_entity `DispoFldFupInvestgrOfPHC` | (datamart-side) |
| `fld_fup_investgr_of_phc_uid` | nbs_act_entity `FldFupInvestgrOfPHC` | (datamart-side) |
| `fld_fup_prov_of_phc_uid` | nbs_act_entity `FldFupProvOfPHC` | (datamart-side) |
| `fld_fup_supervisor_of_phc_uid` | nbs_act_entity `FldFupSupervisorOfPHC` | (datamart-side) |
| `init_fld_fup_investgr_of_phc_uid` | nbs_act_entity `InitFldFupInvestgrOfPHC` | (datamart-side) |
| `init_fup_investgr_of_phc_uid` | nbs_act_entity `InitFupInvestgrOfPHC` | (datamart-side) |
| `init_interviewer_of_phc_uid` | nbs_act_entity `InitInterviewerOfPHC` | (datamart-side) |
| `interviewer_of_phc_uid` | nbs_act_entity `InterviewerOfPHC` | (datamart-side) |
| `surv_investgr_of_phc_uid` | nbs_act_entity `SurvInvestgrOfPHC` | (datamart-side) |
| `fld_fup_facility_of_phc_uid` | nbs_act_entity `FldFupFacilityOfPHC` | (datamart-side) |
| `org_as_hospital_of_delivery_uid` | nbs_act_entity `OrgAsHospitalOfDelivery` | (datamart-side) |
| `per_as_provider_of_delivery_uid` | nbs_act_entity `PerAsProviderOfDelivery` | (datamart-side) |
| `per_as_provider_of_obgyn_uid` | nbs_act_entity `PerAsProviderOfOBGYN` | (datamart-side) |
| `per_as_provider_of_pediatrics_uid` | nbs_act_entity `PerAsProvideroOfPediatrics` (typo preserved in SP) | (datamart-side) |
| `org_as_reporter_uid` | nbs_act_entity `OrgAsReporterOfPHC` | (datamart-side) |
| `daycare_fac_uid` | participation `DaycareFacility` (uncommon) | (datamart-side) |
| `chronic_care_fac_uid` | participation `ChronicCareFacility` (uncommon) | (datamart-side) |
| `investigation_count` | derived from `act_relationship` `SummaryForm` chain (lines 846–875 of event SP) | sp_nrt_case_count_postprocessing |
| `case_count` | derived from same chain | sp_nrt_case_count_postprocessing |
| `investigator_assigned_datetime` | participation `InvestgrOfPHC` (lines 869–874) — populated on v2 from public_health_case.investigator_assigned_time directly, but the cross-subject derivation is via participation | sp_nrt_case_count_postprocessing |

## Gaps reported

### LINK_REQUIRED

These are **Tier 2** edges. The Investigation event SP references the listed connective tables but Tier 1 deliberately does not author cross-subject participation / act_relationship / nbs_act_entity rows.

1. `LINK_REQUIRED: participation type_cd='SubjOfPHC' linking foundation Patient (entity_uid 20000000) → foundation Investigation (act_uid 20000100) — needed by sp_investigation_event lines 339–360 (person_participations JSON branch), and by downstream sp_public_health_case_fact_datamart_event/_update which is out of scope here.`
2. `LINK_REQUIRED: participation type_cd='SubjOfPHC' linking patient → v2 Investigation (act_uid 20050010) — same downstream consumers.`
3. `LINK_REQUIRED: participation type_cd='OrgAsReporterOfPHC' linking foundation Organization (entity_uid 20000020) → foundation/v2 Investigation — populates organization_participations JSON branch (event SP lines 362–375) and downstream nrt_investigation.organization_id / org_as_reporter_uid.`
4. `LINK_REQUIRED: participation type_cd='PerAsReporterOfPHC' linking foundation Provider (entity_uid 20000010) → foundation/v2 Investigation — populates person_as_reporter_uid in the nbs_act_entity pivot (event SP lines 909–933) and downstream sp_inv_summary_datamart_postprocessing.`
5. `LINK_REQUIRED: participation type_cd='PhysicianOfPHC' linking foundation Provider → foundation/v2 Investigation — populates nrt_investigation.physician_id and downstream sp_inv_summary_datamart_postprocessing.PHYSICIAN_FIRST_NAME / PHYSICIAN_LAST_NAME.`
6. `LINK_REQUIRED: participation type_cd='InvestgrOfPHC' linking foundation Provider → foundation/v2 Investigation — populates nrt_investigation.investigator_id, investigator_assigned_datetime (event SP lines 869–874) and downstream sp_inv_summary_datamart_postprocessing.`
7. `LINK_REQUIRED: nbs_act_entity type_cd='HospOfADT' linking foundation Organization → foundation/v2 Investigation — populates nrt_investigation.hospital_uid and downstream F_PAGE_CASE / Hepatitis_Datamart.`
8. `LINK_REQUIRED: nbs_act_entity type_cd='OrgAsClinicOfPHC' linking foundation Organization → foundation/v2 Investigation — populates nrt_investigation.ordering_facility_uid.`
9. `LINK_REQUIRED: nbs_act_entity type_cd='InterviewerOfPHC' / 'InitInterviewerOfPHC' linking Provider → Investigation — populates respective *_of_phc_uid columns.`
10. `LINK_REQUIRED: nbs_act_entity type_cd='SurvInvestgrOfPHC' / 'CASupervisorOfPHC' / 'ClosureInvestgrOfPHC' / 'DispoFldFupInvestgrOfPHC' / 'FldFupInvestgrOfPHC' / 'FldFupProvOfPHC' / 'FldFupSupervisorOfPHC' / 'InitFldFupInvestgrOfPHC' / 'InitFupInvestgrOfPHC' linking Provider → Investigation — populates the corresponding nrt_investigation *_of_phc_uid columns. Each is a separate Tier 2 edge per edge_types.md, but they all share the same Provider/Investigation pair so a single Tier 2 task can cover the whole bundle for v1 coverage.`
11. `LINK_REQUIRED: nbs_act_entity type_cd='FldFupFacilityOfPHC' / 'OrgAsHospitalOfDelivery' / 'OrgAsReporterOfPHC' linking Organization → Investigation — populates org-side *_of_phc_uid columns.`
12. `LINK_REQUIRED: nbs_act_entity type_cd='PerAsProviderOfDelivery' / 'PerAsProviderOfOBGYN' / 'PerAsProvideroOfPediatrics' (note: SP preserves the typo 'PerAsProvideroOfPediatrics' at line 931 — match it exactly, do not silently correct) linking Provider → Investigation — populates per-as-provider columns.`
13. `LINK_REQUIRED: act_relationship type_cd='Notification' linking foundation Notification (act_uid 20000110) → foundation/v2 Investigation — populates the notification_history aggregation (event SP lines 692–845) and downstream notification-driven datamart columns.`
14. `LINK_REQUIRED: act_relationship type_cd='LabReport' linking foundation Lab Report (act_uid 20000120) → foundation/v2 Investigation — populates investigation_observation_ids JSON branch (event SP lines 378–407) and downstream Case_Lab_Datamart.`
15. `LINK_REQUIRED: act_relationship type_cd='MorbReport' linking foundation Morbidity Report (act_uid 20000130) → foundation/v2 Investigation — same downstream branches as LabReport, distinguished by source observation's obs_domain_cd_st_1.`
16. `LINK_REQUIRED: act_relationship type_cd='TreatmentToPHC' linking foundation Treatment (act_uid 20000150) → foundation/v2 Investigation — populates treatment-to-PHC edges consumed by sp_f_page_case_postprocessing and treatment datamarts.`
17. `LINK_REQUIRED: nbs_case_answer rows referencing v2 Investigation's act_uid (20050010) plus matching nbs_question / nbs_ui_metadata seed for 'PG_Hepatitis_A_Acute_Investigation' — populates investigation_case_answer JSON branch (event SP lines 437–571). LDF baseline seed already includes templates for HEP forms; only the act-specific answer rows are needed. This is a Tier 2/Tier 3 boundary depending on how the v1 catalog scopes nbs_case_answer.`

The above LINK_REQUIRED count is **17 distinct edge bundles**. None affect the INVESTIGATION dimension coverage measured here — all affect downstream tables out of Tier 1 scope.

### OUT_OF_SCOPE

- `OUT_OF_SCOPE: sp_sld_investigation_repeat_postprocessing — handles repeating-block dimensions (D_INVESTIGATION_REPEAT). Requires repeating-block act_relationship/participation rows. Tier 2/Tier 3 territory per the per-subject prompt.`
- `OUT_OF_SCOPE: sp_dyn_dm_invest_form_postprocessing / sp_dyn_dm_invest_clear_postprocessing — dynamic-target datamart SPs. Tier 2/Tier 3.`
- `OUT_OF_SCOPE: sp_public_health_case_fact_datamart_event / sp_public_health_case_fact_datamart_update — datamart-side fact assembly. They read PARTICIPATION rows that Tier 2 will write.`
- `OUT_OF_SCOPE: Legacy investigation form coded-observation overlay (lines 218–385 in sp_nrt_investigation_postprocessing). Only fires for legacy form codes (INV_FORM_BMDGAS / INV_FORM_HEPGEN / INV_FORM_RUB / 11 others). v2 uses 'PG_Hepatitis_A_Acute_Investigation' which is not in the list. Defer to a Tier 3 fixture targeting one of the 14 legacy forms if coverage is needed.`

### SRTE_GAP

None. All `*_cd` values populated on the v2 row are grounded in baseline SRTE:

- `condition_cd='10110'` — `nbs_srte.dbo.condition_code` (Hepatitis A, acute; family_cd 'HEP'; investigation_form_cd 'PG_Hepatitis_A_Acute_Investigation')
- `case_class_cd='C'` — `nbs_srte.dbo.code_value_general` `PHC_CLASS` 'Confirmed'
- `investigation_status_cd='O'` — `nbs_srte.dbo.code_value_general` `PHC_IN_STS` 'Open'
- `prog_area_cd='HEP'` — `nbs_srte.dbo.program_area_code` 'HEP'
- `jurisdiction_cd='130001'` — `nbs_srte.dbo.jurisdiction_code` 'Fulton County'
- `pregnant_ind_cd='Y'`, `day_care_ind_cd='N'`, `food_handler_ind_cd='N'`, `hospitalized_ind_cd='Y'`, `outbreak_ind='Y'`, `outcome_cd='Y'` — `nbs_srte.dbo.totalidm` maps INV178 / INV148 / INV149 / INV128 / INV150 / INV145 → `code_set_nm='YNU'`; `code_value_general` 'Y' = Yes / 'N' = No
- `transmission_mode_cd='B'` — `code_value_general` `PHC_TRAN_M` 'Bloodborne'
- `disease_imported_cd='IND'` — `code_value_general` `PHVS_DISEASEACQUIREDJURISDICTION_NND` 'Indigenous'
- `pat_age_at_onset_unit_cd='Y'` — `totalidm` INV144 → `AGE_UNIT` 'Years'
- `detection_method_cd='AS'` — `code_value_general` `PHC_DET_MT` 'Active Surveillance'
- `priority_cd='HIGH'` — `code_value_general` `NBS_PRIORITY` 'High'
- `contact_inv_status_cd='O'` — `code_value_general` `PHC_IN_STS` 'Open'
- `referral_basis_cd='AI'` — `code_value_general` `REFERRAL_BASIS` 'Awaiting Interview'
- `state_cd='13'` — `nbs_srte.dbo.state_code` 'GA'
- `cnty_cd='13121'` — `nbs_srte.dbo.state_county_code_value` 'Fulton County'
- `cntry_cd='840'` — country code 'United States'
- `confirmation_method_cd='LD'` — `code_value_general` `PHC_CONF_M` 'Laboratory confirmed'
- `cd_system_cd='NND'` — Tier 0 left this NULL on foundation; v2 uses 'NND' (the canonical NBS NND code system identifier referenced by RTR's PHC code-system handling). Verified by grep against RTR routine code paths; not validated by an FK.

### FOUNDATION_GAP

None. Foundation provides @dbo_Act_investigation_uid (20000100) with a NULL-heavy public_health_case row, exactly as described in `coverage_foundation.md`. Tier 1 enriches additively (one act_id row, one v2 PHC, one v2 case_management) without modifying foundation.

## Decisions made under prompt ambiguity

- **Variant count: 2** — foundation Investigation enrichment + one fully-attributed v2 Investigation. Matches the Provider/Place canary pattern.
- **Condition selected: 10110 (Hepatitis A, acute)** — foundation's existing `cd='10110'` is reused on v2. STRATEGY.md notes v1 uses one canonical condition per family; multi-condition fan-out is Phase 2.
- **`cd_system_cd` value on v2: 'NND'** — Tier 0 left this NULL ("Tier 1 deferred"); we populate on v2 with the canonical NND code-system identifier. Foundation row remains NULL (we cannot UPDATE foundation per the template).
- **Foundation `case_class_cd` left NULL** — exhibits the SP's null/blank path for INVESTIGATION_STATUS / INV_CASE_STATUS (both come from `fn_get_value_by_cd_codeset(case_class_cd, 'INV163')` etc.). v2 sets `case_class_cd='C'`.
- **`jurisdiction_cd='130001'` on v2** — foundation uses `'1'` which has no match in `nbs_srte.dbo.jurisdiction_code` (real codes start at `'130001'`). Foundation row exhibits the no-jurisdiction-match path (JURISDICTION_NM is NULL), v2 exhibits the populated path.
- **case_management on v2** — added a fully-populated `case_management` row keyed on the v2 PHC. INVESTIGATION dimension does not store case-management columns directly; the row is purely for sp_investigation_event's JSON projection completeness on v2.
- **case_management.case_management_uid is IDENTITY** — wrapped the INSERT in `SET IDENTITY_INSERT [dbo].[case_management] ON/OFF` so we can pin the UID to the allocated value (20050011).
- **Cross-subject UID columns on `nrt_investigation` left NULL on both variants** — `patient_id`, `physician_id`, `investigator_id`, `organization_id`, `*_of_phc_uid` (all 16 of them), `hospital_uid`, `ordering_facility_uid`, `org_as_reporter_uid`, `person_as_reporter_uid`, `daycare_fac_uid`, `chronic_care_fac_uid`, `nac_page_case_uid`, `nac_last_chg_time`, `nac_add_time`, `phc_inv_form_id`, `investigation_count`, `case_count`. INVESTIGATION dimension does not directly read these. Each is documented as LINK_REQUIRED for Tier 2.
- **Foundation `nrt_investigation` row mostly NULL** — exercises the SP's `NULLIF`/`CASE WHEN ... null/blank` handling. v2 row sets every non-cross-subject column to a populated value. Together the two variants exercise both paths for every INVESTIGATION column.
- **Confirmation method on v2 only** — foundation Investigation has no `nrt_investigation_confirmation` row. The SP's `coalesce(cm.CONFIRMATION_METHOD_KEY, 1)` fallback at line 856 produces a CONFIRMATION_METHOD_GROUP row keyed on CONFIRMATION_METHOD_KEY=1 (the baseline NULL CM row) for foundation, exercising the no-CM branch. v2 inserts a new confirmation_method row (CM_KEY=4, CD='LD') and a CONFIRMATION_METHOD_GROUP row pairing v2's INVESTIGATION_KEY to that new CM_KEY with the CONFIRMATION_DT timestamp.
- **No legacy-form coverage** — the legacy coded-observation overlay branch (SP lines 198–385) only fires for 14 legacy investigation_form_cd values (INV_FORM_BMDGAS / INV_FORM_HEPGEN / etc.). v2 uses the modern PG_Hepatitis_A_Acute_Investigation form. Coverage of the legacy branch is deferred to Tier 3 if needed.

## Confirmation of deliverables

1. `utilities/comparison-fixtures/fixtures/10_subjects/investigation.sql` — exists.
2. `utilities/comparison-fixtures/coverage/coverage_investigation.md` — this file.
3. `utilities/comparison-fixtures/catalog/uid_ranges.md` — appended Tier 1 Investigation block (see registry update).
