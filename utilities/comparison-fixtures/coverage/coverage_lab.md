# Coverage: lab

## Inputs
- Baseline: 6.0.18.1
- UID range allocated: 20070000 - 20079999
- Foundation dependencies:
  - `@dbo_Act_lab_uid` (20000120) — foundation Lab observation Order
  - `@dbo_Entity_patient_uid` (20000000) — referenced via observation.subject_person_uid + nrt_observation.patient_id
  - `@dbo_Entity_provider_uid` (20000010) — referenced via nrt_observation.ordering_person_id, result_interpreter_id, transcriptionist_id, etc.
  - `@dbo_Entity_organization_uid` (20000020) — referenced via nrt_observation.author_organization_id, ordering_organization_id, performing_organization_id, morb_hosp_id
- Other-agent dependencies: baseline SRTE only. `nrt_srte_Loinc_condition` and `nrt_srte_Labtest_loinc` are pre-populated by Liquibase (~13.8K + 8.7K rows respectively).

## SPs verified
- `dbo.sp_observation_event @obs_id_list = N'20000120,20070010,20070011'` — exit code 0; emits 3-row JSON-shaped projection (foundation Order + v2 Order + v2 Result).
- `dbo.sp_d_lab_test_postprocessing @obs_ids = N'20000120,20070010,20070011', @debug = 0` — exit code 0; `dbo.job_flow_log` records `step_name='SP_COMPLETE', status_type='COMPLETE'`.
- `dbo.sp_d_labtest_result_postprocessing @pLabResultList = N'20000120,20070010,20070011', @pDebug = 0` — exit code 0; `dbo.job_flow_log` records `step_name='SP_COMPLETE', status_type='COMPLETE'`.

C_Order/C_Result UIDs (20070020/20070021) are NOT included in `@obs_ids` because the postprocessing SP filters at line 218-219 to `obs_domain_cd_st_1 IN ('Order','Result','R_Order','R_Result','I_Order','I_Result','Order_rslt')` — C_Order/C_Result fall outside that list and would surface as "Missing NRT Record" backfill errors. They are reachable via the v2 Order's `followup_observation_uid='20070020,20070021'` CSV which the SP traverses in the LAB_RPT_USER_COMMENT branch.

## Apply / FK check
- `sqlcmd -i fixtures/00_foundation/00_foundation.sql` exit code 0.
- `sqlcmd -i fixtures/10_subjects/lab.sql` exit code 0 — clean apply.
- `DBCC CHECKCONSTRAINTS` run against every NBS_ODSE table written: `act`, `act_id`, `act_relationship`, `observation`, `observation_interp`, `observation_reason`, `obs_value_txt`, `obs_value_coded`, `obs_value_numeric`, `obs_value_date`. All clean.
- Iteration count: **3 baseline-reset cycles** to convergence (1: column-mismatch on observation.interpretation_cd + nrt_observation column count; 2: PK conflict on nrt_lab_test_result_group_key from baseline IDENTITY-NULL quirk; 3: missing followup CSV pair / Result-level `txt_type_cd='N'` row).

## Coverage by target table

Per `catalog/rtr_target_columns.md` writers list, columns the postprocessing SPs write are populated as below for Lab UID 20070010 / 20070011 and (where applicable) foundation 20000120.

### LAB_TEST — 65 / 66 live columns populated
*(catalog: 67; live schema: 66 — drift on the catalog-listed column that doesn't exist in baseline 6.0.18.1.)*

All 66 live columns are written by `sp_d_lab_test_postprocessing`. 65 are populated; 1 is NULL on every variant:

| Column | NULL across all variants | Reason |
| --- | --- | --- |
| `RESULT_INTERPRETER_NAME` | yes | The SP at line 343 builds this via `LEFT JOIN dbo.nrt_provider nprov ON obs.result_interpreter_id = nprov.provider_uid`. `nrt_provider` is empty at Lab Tier 1 isolation (Provider Tier 1's chain has not run). LINK_REQUIRED — see Gaps. |

The foundation Lab variant (20000120) exhibits the SP's null-propagation path on most columns (TEST_METHOD_CD/_DESC, ALT_LAB_TEST_CD, JURISDICTION_CD, OID, ACCESSION_NBR, SPECIMEN_*, CLINICAL_INFORMATION, REASON_FOR_TEST_*, all the auth/interpreter/transcriptionist columns, CONDITION_CD, PROCESSING_DECISION_*, etc.) since the foundation `nrt_observation` row is sparse. The v2 Lab variant (20070010) populates every column the SP writes.

### LAB_TEST_RESULT — 19 / 20 live columns populated

| Column | Populated | Notes |
| --- | --- | --- |
| LAB_TEST_KEY | yes | from nrt_lab_test_key surrogate |
| LAB_TEST_UID | yes | |
| RESULT_COMMENT_GRP_KEY | yes | 1 (sentinel) on foundation row, real key on v2 |
| TEST_RESULT_GRP_KEY | yes | 1 (sentinel) for Order rows, real key for Result row |
| PERFORMING_LAB_KEY | yes | 1 (sentinel — d_organization has no nrt-org match for our org_uid 20000020 since Organization Tier 1 chain hasn't run) |
| PATIENT_KEY | yes | 1 (sentinel — d_patient has no row matching foundation patient_uid 20000000; D_PATIENT is owned by Patient Tier 1) |
| COPY_TO_PROVIDER_KEY | yes | 1 (sentinel — d_provider has no row for our provider_uid 20000010) |
| LAB_TEST_TECHNICIAN_KEY | yes | 1 (sentinel) |
| SPECIMEN_COLLECTOR_KEY | yes | 1 (sentinel) |
| ORDERING_ORG_KEY | yes | 1 (sentinel) |
| REPORTING_LAB_KEY | yes | 1 (sentinel) |
| CONDITION_KEY | yes | 1 (sentinel — `dbo.condition` is empty in baseline; populated by `sp_nrt_srte_condition_code_postprocessing` infrastructure SP, out of scope) |
| LAB_RPT_DT_KEY | yes | 1 (sentinel — `dbo.rdb_date` is empty in baseline) |
| MORB_RPT_KEY | yes | 1 (sentinel — Morbidity_Report has only a sentinel row at this stage) |
| INVESTIGATION_KEY | yes | 1 (sentinel — Investigation Tier 1's chain has not run; cross-subject act_relationship Lab→Investigation is Tier 2) |
| LDF_GROUP_KEY | yes | 1 (sentinel — `dbo.ldf_group` is empty) |
| ORDERING_PROVIDER_KEY | yes | 1 (sentinel) |
| RECORD_STATUS_CD | yes | 'ACTIVE' |
| RDB_LAST_REFRESH_TIME | yes | GETDATE() at SP runtime |
| LAB_RESULT_VAL_LARGE_TXT_KEY | no | NOT in `rtr_target_columns.md` write set for `sp_d_labtest_result_postprocessing` — column exists in live DDL but the SP body never references it. Treated as OUT_OF_SCOPE for this fixture. |

### LAB_RPT_USER_COMMENT — 8 / 8 live columns populated
| Column | Source |
| --- | --- |
| USER_COMMENT_KEY | nrt_lab_rpt_user_comment_key IDENTITY |
| USER_RPT_COMMENTS | nrt_observation_txt for v2 C_Result (txt_type_cd='N') |
| COMMENTS_FOR_ELR_DT | C_Result.activity_to_time |
| USER_COMMENT_CREATED_BY | C_Result.add_user_id (= @superuser_id) |
| LAB_TEST_KEY | join to nrt_lab_test_key |
| RECORD_STATUS_CD | 'PROCESSED' → 'ACTIVE' transform on the foundation/v2 lab |
| LAB_TEST_UID | v2 Order UID 20070010 |
| RDB_LAST_REFRESH_TIME | GETDATE() |

### LAB_RESULT_VAL — 20 / 20 live columns populated
All 20 columns populated for the v2 Result row (LAB_TEST_UID=20070011): NUMERIC_RESULT (`>1.1`), RESULT_UNITS ('Index'), LAB_RESULT_TXT_VAL ('Reactive — IgM antibody…'), REF_RANGE_FRM ('0.00'), REF_RANGE_TO ('0.90'), TEST_RESULT_VAL_CD ('10828004'), TEST_RESULT_VAL_CD_DESC ('Positive'), TEST_RESULT_VAL_CD_SYS_CD ('2.16.840.1.113883.6.96'), TEST_RESULT_VAL_CD_SYS_NM ('SCT'), ALT_RESULT_VAL_CD ('POS'), ALT_RESULT_VAL_CD_DESC ('Positive'), ALT_RESULT_VAL_CD_SYS_CD ('L'), ALT_RESULT_VAL_CD_SYS_NM ('Local'), TEST_RESULT_VAL_KEY (real key), RECORD_STATUS_CD ('ACTIVE'), FROM_TIME / TO_TIME (2026-04-04 08:30), LAB_TEST_UID (20070011), RDB_LAST_REFRESH_TIME (GETDATE()), TEST_RESULT_GRP_KEY (real key).

### LAB_RESULT_COMMENT — 6 / 6 live columns populated
All 6 columns populated for the v2 Result row's seq=2 'N'-type text: LAB_TEST_UID (20070011), LAB_RESULT_COMMENT_KEY (IDENTITY), LAB_RESULT_COMMENTS ('Result-level note — patient flagged for follow-up serology.'), RESULT_COMMENT_GRP_KEY (real key), RECORD_STATUS_CD ('ACTIVE'), RDB_LAST_REFRESH_TIME (GETDATE()).

### TEST_RESULT_GROUPING — 2 / 3 live columns populated
| Column | Populated | Notes |
| --- | --- | --- |
| TEST_RESULT_GRP_KEY | yes | IDENTITY |
| LAB_TEST_UID | yes | 20070011 |
| RDB_LAST_REFRESH_TIME | NO | sp_d_labtest_result_postprocessing line 1297 explicitly INSERTs `CAST(NULL AS datetime) AS [RDB_LAST_REFRESH_TIME]` — deliberate NULL (annotated `--No downstream update of RDB_LAST_REFRESH_TIME.`). OUT_OF_SCOPE for fixture coverage; the SP itself doesn't write this column non-NULL. |

### RESULT_COMMENT_GROUP — 3 / 3 live columns populated
RESULT_COMMENT_GRP_KEY (IDENTITY), LAB_TEST_UID (20070011), RDB_LAST_REFRESH_TIME (GETDATE()).

### L_LAB_TEST — not populated by Lab Tier 1
`L_LAB_TEST` columns: `LAB_TEST_KEY` (float) and `LAB_TEST_UID` (numeric). The catalog lists no writer for L_LAB_TEST. Live baseline already contains 317 rows of static seed data (likely from Liquibase). Out of scope: this is not written by any Lab postprocessing SP.

## SRTE codes referenced

| Table.column | Value | code_set_nm | Notes |
| --- | --- | --- | --- |
| observation.cd / nrt_observation.cd | `13950-1` | LOINC (`nrt_srte_LOINC_code`, `nrt_srte_Loinc_condition`) | Maps to condition_cd '10110' (Hepatitis A, acute) via `nrt_srte_Loinc_condition`. Verified row exists. |
| observation.cd_system_cd | `2.16.840.1.113883.6.1` | LOINC OID | conventional |
| observation.cd_system_desc_txt | `LN` | conventional LOINC abbreviation | |
| observation.alt_cd | `HAVAB-IGM` | local | not in SRTE — alt_cd is free-text in NBS schema |
| observation.alt_cd_system_cd | `L` | conventional ('Local') | not SRTE-validated |
| observation.method_cd | `IGM-EIA` | conventional | not SRTE-validated |
| observation.target_site_cd | `SER` | conventional ('Serum') | not SRTE-validated |
| observation.priority_cd | `R` | conventional ('Routine') | not SRTE-validated |
| observation.processing_decision_cd | `AC` | `STD_NBS_PROCESSING_DECISION_ALL` | verified in code_value_general |
| observation.obs_domain_cd_st_1 | `Order`, `Result`, `C_Order`, `C_Result` | conventional | matches `sp_d_lab_test_postprocessing` and `sp_observation_event` filters |
| observation.ctrl_cd_display_form | `LabReport` | conventional | matches `sp_d_lab_test_postprocessing` line 219 |
| observation.jurisdiction_cd | `130001` | `S_JURDIC_C` | verified — Fulton County |
| observation.prog_area_cd | `STD` | NBS program-area | conventional |
| observation.record_status_cd | `PROCESSED` | conventional | drives the SP's transform to 'ACTIVE' on RECORD_STATUS_CD |
| observation.status_cd | `A` | `ACT_OBJ_ST` | verified |
| observation.shared_ind | `T` | char(1) flag | conventional |
| observation.electronic_ind | `Y` | char(1) flag | conventional ELR-source flag |
| observation_interp.interpretation_cd | `A` | `OBS_INT` | conventional ('Abnormal') |
| obs_value_coded.code | `10828004` | SNOMED CT ('Positive') | |
| obs_value_coded.code_system_cd | `2.16.840.1.113883.6.96` | SNOMED OID | |
| nrt_observation_material.material_cd | `258450006` | SNOMED ('Serum specimen') | |
| nrt_observation_material.risk_cd | `B` | conventional ('Biohazard') | |
| nrt_observation_reason.reason_cd | `B33.5` | ICD-10 ('Acute hepatitis A') | not SRTE-validated; reason_cd is free-text |
| act_relationship.type_cd | `COMP` | `AR_TYPE` | verified — Lab-internal Order→Result/C_Order |
| act_relationship.source_class_cd / target_class_cd | `OBS` | `ACT_CLS` | |
| act_id.type_cd | `OBS_LOCAL_ID`, `FILLER` | conventional | not SRTE-FK |
| act_id.assigning_authority_cd | `2.16.840.1.114222.4.5.1.1`, `2.16.840.1.113883.4.6` | OID | not SRTE-FK |

## Columns deliberately skipped

| Column | Reason | Citation |
| --- | --- | --- |
| LAB_TEST.RESULT_INTERPRETER_NAME | LINK_REQUIRED — joins `nrt_provider` which is empty at Tier 1 isolation; resolved in merged-fixture sequence after Provider Tier 1 has populated nrt_provider. | sp_d_lab_test_postprocessing line 343 |
| LAB_TEST_RESULT.LAB_RESULT_VAL_LARGE_TXT_KEY | Column exists in live DDL but `sp_d_labtest_result_postprocessing` body never assigns it (not in `rtr_target_columns.md` write set). OUT_OF_SCOPE. | rtr_target_columns.md → LAB_TEST_RESULT writers |
| TEST_RESULT_GROUPING.RDB_LAST_REFRESH_TIME | SP at line 1297 explicitly INSERTs `CAST(NULL AS datetime)`. Deliberate NULL by design. | sp_d_labtest_result_postprocessing line 1289-1297 |
| Foundation Lab variant 20000120 most aux columns | The two-variant pattern: foundation Lab is left sparse to exhibit the SP's null/blank propagation transforms (TEST_METHOD_CD blank → NULL, ACCESSION_NBR blank → NULL, etc.); v2 Lab populates the same columns to exhibit the populated path. | template's two-variant pattern |

## Gaps reported

### LINK_REQUIRED
- **LAB_TEST.RESULT_INTERPRETER_NAME** — SP at `sp_d_lab_test_postprocessing` line 343 LEFT JOINs `nrt_provider` on `result_interpreter_id`. Resolved in merged-fixture sequence after **Provider Tier 1's chain** has populated nrt_provider (it does so via direct INSERT in `provider.sql`). At Lab Tier 1 isolation `nrt_provider` is empty so the join produces NULL.
- **LAB_TEST_RESULT FK columns** (PATIENT_KEY, INVESTIGATION_KEY, CONDITION_KEY, REPORTING_LAB_KEY, ORDERING_PROVIDER_KEY, ORDERING_ORG_KEY, COPY_TO_PROVIDER_KEY, LAB_TEST_TECHNICIAN_KEY, SPECIMEN_COLLECTOR_KEY, PERFORMING_LAB_KEY, MORB_RPT_KEY, LDF_GROUP_KEY, LAB_RPT_DT_KEY) — all currently resolve to **sentinel KEY=1** via `COALESCE(<lookup>, 1)`. Resolved to non-sentinel keys in merged-fixture sequence after the upstream subjects' chains have populated their dimensions: Patient Tier 1 → D_PATIENT, Provider Tier 1 → d_provider, Organization Tier 1 → d_organization, Investigation Tier 1 → INVESTIGATION, infrastructure SP `sp_get_date_dim` → RDB_DATE, infrastructure SP `sp_nrt_srte_condition_code_postprocessing` → CONDITION. Tier 2 act_relationship rows wiring Lab → Investigation are also required for INVESTIGATION_KEY to resolve to the canonical investigation rather than sentinel.

### OUT_OF_SCOPE
- **LAB_TEST_RESULT.LAB_RESULT_VAL_LARGE_TXT_KEY** — column exists in live DDL but no postprocessing SP writes it.
- **TEST_RESULT_GROUPING.RDB_LAST_REFRESH_TIME** — SP explicitly NULLs this column.
- **L_LAB_TEST** — not in `rtr_target_columns.md` writer set for any Lab postprocessing SP. Live baseline contains 317 rows of static seed data (Liquibase-loaded). Not a Lab Tier 1 deliverable.
- **`sp_lab100_datamart_postprocessing`, `sp_lab101_datamart_postprocessing`, `sp_case_lab_datamart_postprocessing`, `sp_covid_lab_celr_datamart_postprocessing`, `sp_covid_lab_datamart_postprocessing`** — datamart SPs that read from already-populated Lab dimensions and need Tier 2 act_relationship rows wiring Lab → Investigation. Per the per-subject prompt, datamart SPs are out-of-scope for Tier 1 Lab.

### BASELINE_QUIRK (documented; the fixture works around it)
- **`dbo.nrt_lab_test_result_group_key` IDENTITY counter is NULL on fresh Liquibase migration** (verified via `DBCC CHECKIDENT(...,NORESEED)` showing `current identity value 'NULL'`). The seeded sentinel row with TEST_RESULT_GRP_KEY=1 was inserted via IDENTITY_INSERT, so the IDENTITY sequence was never advanced past 0. The next INSERT with auto-IDENTITY tries value 1 → PK conflict.
  - **Workaround in this fixture**: `SET IDENTITY_INSERT ... ON; INSERT a high-value row; OFF; DELETE that row` — this advances the IDENTITY counter past the seed row's value. `DBCC CHECKIDENT(...,RESEED,N)` is a no-op when current is NULL, so it does NOT work.
  - Same pattern applied to `nrt_lab_test_key` for safety. `nrt_lab_result_comment_key` and `nrt_lab_rpt_user_comment_key` already have IDENTITY=2 in baseline so don't need the fix.
  - This is a baseline-data quirk in 6.0.18.1, not a Lab fixture bug. Other Tier 1 subjects with similar IDENTITY-sequenced key tables may need the same workaround. A future iteration of STRATEGY.md / liquibase migrations could codify the correct seed-insert pattern.

### SRTE_GAP
- (none — every code is grounded in baseline SRTE.)

### FOUNDATION_GAP
- (none — foundation provides the parent observation/act + Patient/Provider/Organization the fixture needs.)

## Decisions made under ambiguity

- **Variant strategy:** foundation Lab observation 20000120 (Order) kept sparse on observation columns to exhibit the SP's null/blank transform path; v2 Order (20070010) populates every column the postprocessing SPs read; v2 Result child (20070011) carries result values and links back to v2 Order via `report_observation_uid` and Lab-internal `act_relationship` (type_cd='COMP'). v2 followup C_Order (20070020) and C_Result (20070021) drive the LAB_RPT_USER_COMMENT path.

- **LOINC code chosen:** `13950-1` (Hepatitis A virus IgM Ab [Presence] in Serum) — chosen because it maps to condition_cd `10110` (Hepatitis A, acute) via baseline-pre-populated `nrt_srte_Loinc_condition`. Aligns with foundation Investigation's `cd='10110'` choice.

- **followup_observation_uid CSV format:** v2 Order's `followup_observation_uid='20070020,20070021'` (CSV of both C_Order and C_Result UIDs). The SP at line 782-786 requires BOTH to be in the CSV (one to satisfy the C_Order side of the multi-table FROM, one for C_Result).

- **C_Order/C_Result NOT in @obs_ids:** the postprocessing SP filters `obs_domain_cd_st_1 IN ('Order','Result',...)` excluding C_Order/C_Result. Passing them in @obs_ids triggers "Missing NRT Record" backfill. They are reachable via the v2 Order's followup CSV, which the SP traverses internally.

- **observation_interp vs observation.interpretation_cd:** initial draft set `interpretation_cd` on the observation row directly; the column does not exist on `dbo.observation`. Moved to `dbo.observation_interp` (1:1 child table). nrt_observation has the column and we set it there directly on the v2 Result.

- **EDX_Document and material ODSE rows omitted:** EDX_Document.EDX_Document_uid is IDENTITY (cannot be inserted with a specific UID without IDENTITY_INSERT, which would over-engineer the fixture); material.material_uid has a hard FK to entity (would require authoring an entity row of class 'PLC' or equivalent). Both are unnecessary because the postprocessing SPs read from `nrt_observation_edx` and `nrt_observation_material` (RDB_MODERN), which we hand-author. The event SP's JSON projection of EDX/material on the foundation Lab will be empty; this is acceptable at Tier 1.

- **Lab-internal act_relationship rows authored** (Result→Order, C_Order→Order, C_Result→C_Order). Per the per-subject prompt these are explicitly allowed since both endpoints are Lab observations. Cross-subject act_relationships (Lab → Investigation) are NOT authored — that's Tier 2 territory, and at Tier 1 isolation `LAB_TEST_RESULT.INVESTIGATION_KEY` resolves to sentinel 1 via COALESCE.

- **`obs_value_txt` `txt_type_cd` choices:** the v2 Result has TWO `nrt_observation_txt` rows — seq=1 with `txt_type_cd='FT'` (drives `LAB_RESULT_VAL.LAB_RESULT_TXT_VAL`) and seq=2 with `txt_type_cd='N'` (drives `LAB_RESULT_COMMENT.LAB_RESULT_COMMENTS`). The C_Result has one row with `txt_type_cd='N'` (drives `LAB_RPT_USER_COMMENT.USER_RPT_COMMENTS`). The two-row split on the Result was needed to exercise both LAB_RESULT_VAL and LAB_RESULT_COMMENT paths from a single Result observation.

- **Patient/Provider/Organization soft cross-subject UIDs:** v2 Order's nrt_observation row sets patient_id, ordering_person_id, author_organization_id, etc. to the foundation Patient/Provider/Org UIDs. These are SOFT references (no FK in nrt_observation), used to drive the postprocessing SP's joins to D_PATIENT/d_provider/d_organization. At Tier 1 isolation those joins return NULL → COALESCE-to-1 sentinel. In merged-fixture sequence after the upstream Tier 1 chains have populated the dim tables, the joins resolve to real keys.

## UID allocation table

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20070010 | @dbo_Act_lab_v2_order_uid | v2 Order observation `act.act_uid` / `observation.observation_uid` (obs_domain_cd_st_1='Order') | Class `OBS`, mood `EVN`. Fully-attributed Lab Order variant for column coverage. cd='13950-1' (Hepatitis A IgM Ab → condition '10110'). |
| 20070011 | @dbo_Act_lab_v2_result_uid | v2 Result observation `act.act_uid` / `observation.observation_uid` (obs_domain_cd_st_1='Result') | Class `OBS`, mood `EVN`. Wired to 20070010 via `act_relationship` (Lab-internal, type_cd='COMP') AND `nrt_observation.report_observation_uid=20070010`. Carries the result values: `obs_value_coded` (POS), `obs_value_numeric` (>1.10 Index), `obs_value_date`, `obs_value_txt` rows. |
| 20070020 | @dbo_Act_lab_v2_corder_uid | v2 followup C_Order observation `act.act_uid` / `observation.observation_uid` (obs_domain_cd_st_1='C_Order') | Class `OBS`, mood `EVN`. Drives the LAB_RPT_USER_COMMENT path. NOT included in @obs_ids; reached via v2 Order's `followup_observation_uid='20070020,20070021'`. |
| 20070021 | @dbo_Act_lab_v2_cresult_uid | v2 followup C_Result observation `act.act_uid` / `observation.observation_uid` (obs_domain_cd_st_1='C_Result') | Class `OBS`, mood `EVN`. Carries the comment text in `obs_value_txt` (txt_type_cd='N'). |
| 20070030 | @dbo_Material_v2_uid | v2 specimen `material.material_uid` (NOT inserted in NBS_ODSE due to material→entity FK; referenced in `nrt_observation_material.material_id` only) | Reserved UID for future expansion if material ODSE row becomes needed. |
| 20070031 | @dbo_EDX_Document_v2_uid | v2 `EDX_Document.EDX_Document_uid` (NOT inserted in NBS_ODSE due to IDENTITY column; referenced in `nrt_observation_edx.edx_document_uid` only) | Reserved UID for future expansion. |

The fixture also writes:
- 1 row to `NBS_ODSE.dbo.act_id` keyed on `act_uid=20000120` (foundation Lab enrichment — foundation has none).
- 2 rows to `NBS_ODSE.dbo.act_id` keyed on `act_uid=20070010` (v2 Order — local id + filler order number).
- 4 rows to `NBS_ODSE.dbo.act` (one per v2 observation hierarchy member).
- 4 rows to `NBS_ODSE.dbo.observation` (v2 Order, Result, C_Order, C_Result).
- 3 rows to `NBS_ODSE.dbo.act_relationship` (Lab-internal: Result→Order, C_Order→Order, C_Result→C_Order).
- 1 row each to `observation_interp`, `obs_value_coded`, `obs_value_numeric`, `obs_value_date`, `observation_reason`.
- 2 rows to `obs_value_txt` (Result + C_Result).

In RDB_MODERN:
- 5 rows to `dbo.nrt_observation` (foundation Order + v2 Order/Result/C_Order/C_Result).
- 3 rows to `dbo.nrt_observation_txt` (v2 Result FT, v2 Result N, v2 C_Result N).
- 1 row to `dbo.nrt_observation_coded`.
- 1 row to `dbo.nrt_observation_numeric`.
- 1 row to `dbo.nrt_observation_date`.
- 1 row to `dbo.nrt_observation_material` (v2 Order specimen).
- 1 row to `dbo.nrt_observation_reason` (v2 Order reason for test).
- 1 row to `dbo.nrt_observation_edx` (v2 Order EDX document link).

The fixture also runs IDENTITY-advance maintenance on `dbo.nrt_lab_test_result_group_key` and `dbo.nrt_lab_test_key` to work around the baseline-NULL-IDENTITY quirk. These are not new UIDs.
