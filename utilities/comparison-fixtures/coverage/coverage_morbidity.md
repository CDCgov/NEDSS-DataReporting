# Coverage: morbidity (Morbidity Report)

## Inputs
- Baseline: 6.0.18.1
- UID range allocated: 20080000 - 20089999
- Foundation dependencies:
  - `@dbo_Act_morbidity_uid` (20000130) — foundation Morbidity observation Order
  - `@dbo_Entity_patient_uid` (20000000) — referenced via `observation.subject_person_uid` and `nrt_observation.patient_id`
  - `@dbo_Entity_provider_uid` (20000010) — referenced via `nrt_observation.morb_physician_id` / `morb_reporter_id`
  - `@dbo_Entity_organization_uid` (20000020) — referenced via `nrt_observation.morb_hosp_id` / `morb_hosp_reporter_id` / `health_care_id` / `author_organization_id` / `ordering_organization_id` / `performing_organization_id`
- Other-agent dependencies: baseline SRTE only (`code_value_general` for `STD_NBS_PROCESSING_DECISION_ALL` and `MRB_RPT_METH` and `MORB_RPT_TYPE` and `YNU`); `nrt_srte_Jurisdiction_code` for the JURISDICTION_NM lookup.

## SPs verified
- `dbo.sp_observation_event @obs_id_list = N'20000130,20080010'` — exit code 0; emits a JSON-shaped projection of the foundation Morb Order + v2 Morb Order observations (act_uid + parent metadata + nesteddata branches).
- `dbo.sp_d_morbidity_report_postprocessing @pMorbidityIdList = N'20000130,20080010', @debug = 0` — completes through step 23 (`Inserting into dbo.Morbidity_Report`, 2 rows committed). Steps 24/25 (`Updating MORBIDITY_REPORT_EVENT` / `Inserting into MORBIDITY_REPORT_EVENT`) **fail with NOT-NULL violation on `MORBIDITY_REPORT_EVENT.PATIENT_KEY`** at Tier 1 isolation. The SP body's BEGIN CATCH at line 1424 logs `Status_Type='ERROR'` for step 25 and returns an Error row from the final `SELECT`. The earlier BEGIN/COMMIT TRANSACTION blocks for `MORBIDITY_REPORT` (lines 1062-1142) had already committed, so MORBIDITY_REPORT rows survive. **The MORB_RPT_USER_COMMENT INSERT also does not run** because it's downstream of the failing MORBIDITY_REPORT_EVENT INSERT (steps 26-27 are skipped after CATCH triggers).

C_Order/C_Result UIDs (20080020/20080021) and the 16 INV/MRB followup UIDs (20080100–20080115) are NOT included in `@pMorbidityIdList` because the SP filter at line 281-282 is `obs_domain_cd_st_1 = 'Order' AND CTRL_CD_DISPLAY_FORM = 'MorbReport'`. The followups have `obs_domain_cd_st_1 = 'Result'` (or 'C_Order'/'C_Result' for the user-comment pair) and would surface as "Missing NRT Record" backfill if passed in directly. They are reachable via the v2 Order's `followup_observation_uid` CSV which the SP traverses via `CROSS APPLY string_split(...)` at lines 99-100.

## Apply / FK check
- `sqlcmd -i fixtures/00_foundation/00_foundation.sql` exit code 0.
- `sqlcmd -i fixtures/10_subjects/morbidity.sql` exit code 0 — clean apply on first iteration.
- ODSE INSERTs: 1 row to `act_id` (foundation enrichment) + 1 row to `act_id` (v2 Morb Order) + 19 rows to `act` (v2 Order + C_Order + C_Result + 16 followups) + 19 rows to `observation` (same set) + 18 rows to `act_relationship` (Morb-internal: 2 user-comment + 16 INV/MRB followups → v2 Morb Order) + 10 rows to `obs_value_coded` + 4 rows to `obs_value_date` + 3 rows to `obs_value_txt`. RDB_MODERN: 20 rows to `nrt_observation` + 10 to `nrt_observation_coded` + 4 to `nrt_observation_date` + 3 to `nrt_observation_txt`.
- Iteration count: **1 baseline-reset cycle** — the fixture applied cleanly and the SP's PATIENT_KEY-NOT-NULL failure is a documented LINK_REQUIRED, not a fixture bug.

## Coverage by target table

### MORBIDITY_REPORT — 30 / 30 live columns populated

The SP completed step 23 (INSERT INTO MORBIDITY_REPORT, 2 rows). Live column count: **30** (matches per-subject prompt's "Live: 30 cols"). Catalog count was 31 (prompt mentions a close drift); the live schema has 30, all populated for the v2 variant.

| Column | Populated on v2 (UID 20080010) | Populated on foundation (UID 20000130) | Source |
| --- | --- | --- | --- |
| MORB_RPT_KEY | yes (=3) | yes (=2) | inline `tmp_id_assignment` IDENTITY + offset (`MAX(morb_rpt_key)+1`) |
| MORB_RPT_UID | yes | yes | `nrt_observation.observation_uid` |
| MORB_RPT_LOCAL_ID | yes (`OBS20080010GA01`) | yes (`OBS20000130GA01`) | `obs.local_id` |
| MORB_RPT_SHARE_IND | yes (`T`) | yes (`F`) | `obs.shared_ind` |
| MORB_RPT_OID | yes (=20080010) | NULL | `obs.PROGRAM_JURISDICTION_OID` (foundation row sparse) |
| MORB_RPT_TYPE | yes (`INIT`) | NULL | followup MRB100 coded value (`obs_value_coded.code`) |
| MORB_RPT_COMMENTS | yes | NULL | followup MRB102 txt value (`obs_value_txt.value_txt`, FT) |
| MORB_RPT_DELIVERY_METHOD | yes (`Web`) | NULL | followup MRB161 coded value |
| SUSPECT_FOOD_WTRBORNE_ILLNESS | yes (`N`) | NULL | followup MRB168 coded value |
| MORB_RPT_OTHER_SPECIFY | yes | NULL | followup MRB169 txt value |
| NURSING_HOME_ASSOCIATE_IND | yes (`N`, substring 1,1) | NULL | followup MRB129 coded value (substring at line 748) |
| JURISDICTION_CD | yes (`130001`) | yes (`1`) | `obs.jurisdiction_cd` |
| JURISDICTION_NM | yes (`Fulton County`) | NULL | `nrt_srte_Jurisdiction_code` lookup; foundation row's `jurisdiction_cd='1'` is not in the jurisdiction code table |
| HEALTHCARE_ORG_ASSOCIATE_IND | yes (`N`) | NULL | followup MRB130 coded value |
| MORB_RPT_CREATE_BY | yes (=10009282) | yes (=10009282) | `obs.add_user_id` |
| MORB_RPT_LAST_UPDATE_DT | yes | yes | `obs.last_chg_time` |
| MORB_RPT_LAST_UPDATE_BY | yes (=10009282) | yes (=10009282) | `obs.last_chg_user_id` |
| DIAGNOSIS_DT | yes (2026-03-30) | NULL | followup MRB165 date value (line 751) |
| HSPTL_ADMISSION_DT | yes (2026-03-31) | NULL | followup MRB166 date value (line 752) |
| PH_RECEIVE_DT | yes (2026-04-04T10:00:00) | NULL | `obs.rpt_to_state_time` |
| DIE_FROM_ILLNESS_IND | yes (`N`) | NULL | followup INV145 coded value |
| HOSPITALIZED_IND | yes (`Y`) | NULL | followup INV128 coded value |
| PREGNANT_IND | yes (`N`) | NULL | followup INV178 coded value |
| FOOD_HANDLER_IND | yes (`N`) | NULL | followup INV149 coded value |
| DAYCARE_IND | yes (`N`) | NULL | followup INV148 coded value |
| ELECTRONIC_IND | yes (`Y`) | yes (`N`) | `obs.electronic_ind` |
| RECORD_STATUS_CD | yes (`ACTIVE`) | yes (`ACTIVE`) | CASE on `obs.record_status_cd`: `PROCESSED→ACTIVE` |
| RDB_LAST_REFRESH_TIME | yes (`GETDATE()`) | yes (`GETDATE()`) | hardcoded `GETDATE()` at SP runtime |
| PROCESSING_DECISION_CD | yes (`AC`) | NULL | `obs.PROCESSING_DECISION_CD` (foundation row left NULL) |
| PROCESSING_DECISION_DESC | yes (`Administrative Closure`) | NULL | substring of `cvg.Code_short_desc_txt` from `nrt_srte_Code_value_general` lookup on `STD_NBS_PROCESSING_DECISION_ALL` |

The foundation row exhibits the SP's null-propagation path on every column the followup-pivot writes (MORB_RPT_TYPE / COMMENTS / DELIVERY_METHOD / IND columns / DIAGNOSIS_DT / HSPTL_ADMISSION_DT / etc.) since foundation has no followup observations attached. The v2 row populates every column.

### MORBIDITY_REPORT_EVENT — 0 / 17 live columns populated

**Tier 1 isolation:** the INSERT INTO MORBIDITY_REPORT_EVENT step (line 1193-1232 of the SP) **fails** with:
> Cannot insert the value NULL into column 'PATIENT_KEY', table 'RDB_MODERN.dbo.MORBIDITY_REPORT_EVENT'; column does not allow nulls. INSERT fails.

Root cause: the SELECT-INTO at line 950 reads `pat.PATIENT_KEY` directly from a `LEFT JOIN dbo.d_patient AS pat ON n.patient_id = pat.patient_uid`, with NO `COALESCE(..., 1)`. At Tier 1 isolation, `dbo.D_PATIENT` is empty of any row matching `patient_id = 20000000` (foundation Patient): the baseline contains only the sentinel D_PATIENT KEY=1 (PATIENT_UID=NULL) and a baseline-seeded D_PATIENT KEY=2 (PATIENT_UID=10000008, which doesn't match our v2 morbidity's `patient_id=20000000`). The LEFT JOIN therefore returns NULL, and the INSERT fails on the NOT-NULL constraint.

`MORBIDITY_REPORT_EVENT.PATIENT_KEY` is **NOT NULL** but has **no FK constraint** to D_PATIENT (verified — the catalog confirms no FK constraints on this fact table). So the only thing blocking the SP is the column-level NOT NULL.

**Expected merged-fixture sequence coverage: 16/17** when run after **Patient Tier 1's chain** has populated D_PATIENT with a row matching `patient_uid=20000000`. The PATIENT_KEY join then resolves to a real key, the INSERT succeeds, and the remaining 16 columns populate per the SP's COALESCE-to-sentinel pattern:
- `PATIENT_KEY` — non-sentinel after D_PATIENT populated.
- `Condition_Key` — `COALESCE(con.CONDITION_KEY, '')` = '' (because `dbo.condition` is empty in baseline; populated by `sp_nrt_srte_condition_code_postprocessing`, out of scope for this fixture). Cast to bigint, '' becomes 0.
- `HEALTH_CARE_KEY` — `COALESCE(org1.Organization_key, 1)` = 1 (sentinel — d_organization has no row matching `health_care_id=20000020` until Organization Tier 1 chain runs).
- `HSPTL_DISCHARGE_DT_KEY` — `COALESCE(dt3.Date_key, 1)` = 1 (sentinel — `dbo.rdb_date` is empty in baseline).
- `HSPTL_KEY` — `COALESCE(org2.Organization_key, 1)` = 1 (sentinel).
- `ILLNESS_ONSET_DT_KEY` — `COALESCE(dt4.Date_key, 1)` = 1 (sentinel).
- `INVESTIGATION_KEY` — `COALESCE(inv.INVESTIGATION_KEY, 1)` = 1 (sentinel — Investigation Tier 1's chain has not run; cross-subject `act_relationship` Morb→Investigation is Tier 2).
- `MORB_RPT_KEY` — non-sentinel (real key from `tmp_morb_root.morb_rpt_key`).
- `MORB_RPT_CREATE_DT_KEY` — `COALESCE(dt5.Date_key, 1)` = 1 (sentinel).
- `MORB_RPT_DT_KEY` — `COALESCE(dt6.Date_key, 1)` = 1 (sentinel).
- `MORB_RPT_SRC_ORG_KEY` — `COALESCE(org3.Organization_Key, 1)` = 1 (sentinel).
- `PHYSICIAN_KEY` — `COALESCE(phy.provider_key, 1)` = 1 (sentinel — d_provider has no row matching foundation Provider).
- `REPORTER_KEY` — `COALESCE(per1.provider_key, 1)` = 1 (sentinel).
- `LDF_GROUP_KEY` — `COALESCE(ldf_g.ldf_group_key, 1)` = 1 (sentinel — LDF chain hasn't run; the SP body uses COALESCE in the SELECT-INTO at line 967 even though the per-subject prompt note suggested no COALESCE; the INSERT/UPDATE at lines 1167/1226 re-emits `tmp.[LDF_GROUP_KEY]` without COALESCE, but tmp value is 1 from the SELECT-INTO).
- `Morb_Rpt_Count` — hardcoded `1`.
- `Nursing_Home_Key` — hardcoded `1` (line 969 — "cannot find mapping" SP comment).
- `record_status_cd` — `'ACTIVE'` (substring of `tmp.RECORD_STATUS_CD`).

### MORB_RPT_USER_COMMENT — 0 / 8 live columns populated at Tier 1 isolation

The MORB_RPT_USER_COMMENT INSERT (line 1287-1311) is downstream of the failing MORBIDITY_REPORT_EVENT INSERT and never runs because the BEGIN CATCH triggers and rolls back the in-flight transaction.

**Expected merged-fixture sequence coverage: 8/8** when MORBIDITY_REPORT_EVENT INSERT succeeds (after Patient Tier 1's chain has populated D_PATIENT). Per the SP's INSERT/UPDATE pattern at line 1287:
- MORB_RPT_UID = v2 Morb Order UID (20080010)
- USER_COMMENT_KEY = inline IDENTITY + offset (line 882-915)
- MORB_RPT_KEY = real key
- EXTERNAL_MORB_RPT_COMMENTS = v2 C_Result `obs_value_txt` (`'Tier 1 Morbidity v2 — clinician user comment.'`, txt_type_cd='N')
- USER_COMMENTS_BY = `add_user_id` from C_Result (= @superuser_id)
- USER_COMMENTS_DT = `activity_to_time` from C_Result
- RECORD_STATUS_CD = 'ACTIVE'
- RDB_LAST_REFRESH_TIME = `GETDATE()`

### dbo.Morbidity_Report (sentinel bootstrap, line 1144-1146)

Baseline already contains 1 sentinel row at `morb_rpt_KEY=1`, RECORD_STATUS_CD='ACTIVE'. The SP's `INSERT INTO dbo.Morbidity_Report (morb_rpt_KEY,[RECORD_STATUS_CD]) SELECT 1,'ACTIVE' WHERE NOT EXISTS (...)` is a no-op against a baseline that already has this row. After the fixture run there are 3 rows total: sentinel KEY=1, foundation Morb KEY=2 (UID 20000130), v2 Morb KEY=3 (UID 20080010).

This is the same physical table as `MORBIDITY_REPORT` (case-insensitive collation; the SP body uses both spellings interchangeably).

### Side-effect: UPDATE to LAB_TEST_RESULT (line 335)

The SP at line 335 does:
```sql
UPDATE dbo.LAB_TEST_RESULT
SET morb_rpt_key = 1, RDB_LAST_REFRESH_TIME = GETDATE()
WHERE morb_rpt_key IN (... morb reports without investigations ...)
```

This is a back-prop UPDATE that disassociates Lab results from morbidity reports that lost their investigation. At Tier 1 isolation it's a no-op because LAB_TEST_RESULT contains no rows whose `morb_rpt_key` is in our `tmp_morb_root.morb_rpt_key` set (Lab Tier 1's chain isn't run as a precondition for Morbidity Tier 1 isolation; even if it were, no Morb→Lab linkage exists). 0 rows affected.

## SRTE codes referenced

| Table.column | Value | code_set_nm | Notes |
| --- | --- | --- | --- |
| observation.cd / nrt_observation.cd (v2 Morb Order) | `10110` | PHIN_CONDITION (PHIN_CONDITION_CODES) | Hepatitis A, acute. Single condition per family per STRATEGY.md v1. Aligns with foundation Investigation `cd='10110'` and Lab Tier 1's mapped condition. |
| observation.cd_system_cd | `2.16.840.1.114222.4.5.277` | PHIN_CONDITION_CODES OID | conventional |
| observation.cd_system_desc_txt | `PHIN_CONDITION` | conventional | |
| observation.alt_cd | `HEP-A-ACUTE` | local | not SRTE-validated; alt_cd is free-text |
| observation.alt_cd_system_cd | `L` | conventional ('Local') | not SRTE-validated |
| observation.target_site_cd | `WBLD` | conventional ('Whole blood') | not SRTE-validated |
| observation.priority_cd | `R` | conventional ('Routine') | not SRTE-validated |
| observation.processing_decision_cd | `AC` | `STD_NBS_PROCESSING_DECISION_ALL` | verified — 'Administrative Closure' |
| observation.obs_domain_cd_st_1 | `Order`, `Result`, `C_Order`, `C_Result` | conventional | matches `sp_d_morbidity_report_postprocessing` line 281-282 (`Order` filter) and lines 99-105 (followup CSV traversal) |
| observation.ctrl_cd_display_form | `MorbReport` | conventional | matches SP line 282 filter |
| observation.jurisdiction_cd | `130001` | `S_JURDIC_C` (via `nrt_srte_Jurisdiction_code`) | verified — Fulton County |
| observation.prog_area_cd | `STD` | NBS program-area | conventional |
| observation.record_status_cd | `PROCESSED` | conventional | drives the SP's CASE transform `PROCESSED→ACTIVE` (line 271) |
| observation.status_cd | `A` | `ACT_OBJ_ST` | verified |
| observation.shared_ind | `T` | char(1) flag | conventional |
| observation.electronic_ind | `Y` | char(1) flag | conventional ELR-source flag |
| obs_value_coded.code (followups) | `Y`, `N` | `YNU` | verified — Yes/No/Unknown code set |
| obs_value_coded.code_system_cd | `2.16.840.1.114222.4.5.232` | YNU OID | conventional |
| obs_value_coded.code (MRB100) | `INIT` | `MORB_RPT_TYPE` | verified — 'Initial' |
| obs_value_coded.code (MRB161) | `Web` | `MRB_RPT_METH` | verified — 'Web Entry' |
| act_relationship.type_cd | `COMP` | `AR_TYPE` | verified — Morb-internal followups |
| act_relationship.source_class_cd / target_class_cd | `OBS` | `ACT_CLS` | |
| act_id.type_cd | `OBS_LOCAL_ID` | conventional | not SRTE-FK |
| act_id.assigning_authority_cd | `2.16.840.1.114222.4.5.1.1` | OID | not SRTE-FK |
| obs.cd (followup observations) | `INV128`, `INV145`, `INV148`, `INV149`, `INV178`, `MRB100`, `MRB102`, `MRB122`, `MRB129`, `MRB130`, `MRB161`, `MRB165`, `MRB166`, `MRB167`, `MRB168`, `MRB169` | NBS form-question codes | sentinels matched against the SP's hardcoded pivot list at lines 393-394 |

## Columns deliberately skipped

| Column | Reason | Citation |
| --- | --- | --- |
| MORBIDITY_REPORT_EVENT (all 17 columns) | LINK_REQUIRED — INSERT fails at Tier 1 isolation due to PATIENT_KEY NOT NULL with no COALESCE in SP. Resolved in merged-fixture sequence after Patient Tier 1's chain has populated D_PATIENT. | sp_d_morbidity_report_postprocessing line 950 (`pat.PATIENT_KEY` no COALESCE), line 1213 (`tmp.[PATIENT_KEY]` no COALESCE in INSERT) |
| MORB_RPT_USER_COMMENT (all 8 columns) | LINK_REQUIRED — downstream of failing MORBIDITY_REPORT_EVENT INSERT; CATCH block rolls back transaction. Resolved in merged-fixture sequence. | sp_d_morbidity_report_postprocessing lines 1281-1320 |
| Foundation Morb variant 20000130 — most followup-driven columns | The two-variant pattern: foundation Morb is left without followup observations to exhibit the SP's null-pivot path; v2 Morb populates all 16 followups to exhibit the populated path. | template's two-variant pattern |

## Gaps reported

### LINK_REQUIRED
- **MORBIDITY_REPORT_EVENT.PATIENT_KEY** — SP at line 950 reads `pat.PATIENT_KEY` from `LEFT JOIN dbo.d_patient AS pat ON n.patient_id = pat.patient_uid` with NO COALESCE. At Tier 1 isolation, `dbo.D_PATIENT` has no row matching `patient_id=20000000` (foundation Patient). PATIENT_KEY is NOT NULL on the target table, so the INSERT fails (Error 515). Resolved in merged-fixture sequence after **Patient Tier 1's chain** has populated D_PATIENT with a row whose `PATIENT_UID=20000000`. Once that row exists, the join resolves to a real PATIENT_KEY and the INSERT succeeds, populating 16 of 17 MORBIDITY_REPORT_EVENT columns plus all 8 MORB_RPT_USER_COMMENT columns.
- **MORBIDITY_REPORT_EVENT cross-subject FK columns** (`Condition_Key`, `HEALTH_CARE_KEY`, `HSPTL_DISCHARGE_DT_KEY`, `HSPTL_KEY`, `ILLNESS_ONSET_DT_KEY`, `INVESTIGATION_KEY`, `MORB_RPT_CREATE_DT_KEY`, `MORB_RPT_DT_KEY`, `MORB_RPT_SRC_ORG_KEY`, `PHYSICIAN_KEY`, `REPORTER_KEY`, `LDF_GROUP_KEY`) — all currently resolve to **sentinel KEY=1** via `COALESCE(<lookup>, 1)`. Resolved to non-sentinel keys in merged-fixture sequence after the upstream subjects' chains have populated their dimensions: Investigation Tier 1 → INVESTIGATION, Patient Tier 1 → D_PATIENT, Provider Tier 1 → d_provider, Organization Tier 1 → d_organization, infrastructure SP `sp_get_date_dim` → RDB_DATE, infrastructure SP `sp_nrt_srte_condition_code_postprocessing` → CONDITION, LDF chain → LDF_GROUP. Tier 2 act_relationship rows wiring Morb → Investigation are also required for INVESTIGATION_KEY to resolve to the canonical investigation rather than sentinel.

### OUT_OF_SCOPE
- **`sp_morbidity_report_datamart_postprocessing`** (file 048) — datamart SP populating `MORBIDITY_REPORT_DATAMART` (133 cols). Tier 2/3 territory per the per-subject prompt; not invoked by this fixture.
- **The catalog drift (catalog: 31 cols / live: 30)** — the catalog lists 31 columns for MORBIDITY_REPORT but the live schema has 30. This is a known catalog drift; we measure against live (30/30 populated for v2). Probable explanation: the catalog includes a column the SP writes that doesn't exist in baseline 6.0.18.1 — analogous to the Lab catalog/live drift at 67/66.
- **MORBIDITY_REPORT_EVENT catalog/live drift** (catalog: 16 / live: 17) — live has 17 columns; the catalog has 16. The extra live column is `MORB_RPT_COUNT`, which the SP DOES write (line 968 `1 as Morb_Rpt_Count`) — so the catalog under-counts by one. Documenting as known drift; we measure against live 17 columns when reporting MORBIDITY_REPORT_EVENT coverage.

### SRTE_GAP
- (none — every code referenced is grounded in baseline SRTE.)

### FOUNDATION_GAP
- (none — foundation provides the parent observation/act + Patient/Provider/Organization the fixture needs.)

## Decisions made under ambiguity

- **Variant strategy:** foundation Morb observation 20000130 (Order) kept sparse on observation columns AND with no followup observations attached — this exhibits the SP's null/blank propagation path on every followup-pivot-driven column (MORB_RPT_TYPE, MORB_RPT_COMMENTS, MORB_RPT_DELIVERY_METHOD, all the IND columns, DIAGNOSIS_DT, HSPTL_ADMISSION_DT, etc.). v2 Morb (20080010) populates every column the postprocessing SP reads, with 16 followup observations one per pivoted INV/MRB code.

- **Condition code chosen:** `10110` (Hepatitis A, acute) — chosen for v1 single-condition-per-family per STRATEGY.md, aligning with foundation Investigation's `cd='10110'` choice and Lab Tier 1's LOINC→condition mapping.

- **followup_observation_uid CSV format:** v2 Morb Order's `followup_observation_uid` is a CSV listing all 18 followup observation UIDs (2 user-comment + 16 INV/MRB pivot followups). The SP's CROSS APPLY string_split traverses each UID and joins to `#morb_obs_reference` to find the followup observation's `cd` for the pivot.

- **Followups NOT in @pMorbidityIdList:** the postprocessing SP filters at line 281-282 to `obs_domain_cd_st_1='Order' AND CTRL_CD_DISPLAY_FORM='MorbReport'`, excluding Result/C_Order/C_Result. The 18 followups have `obs_domain_cd_st_1` outside that filter (Result/C_Order/C_Result) and would surface as "Missing NRT Record" backfill errors if passed in @pMorbidityIdList. They are reachable via the v2 Morb Order's followup_observation_uid CSV and the SP's internal traversal.

- **CTRL_CD_DISPLAY_FORM='MorbReport' on nrt_observation:** the foundation morbidity ODSE row (`dbo.observation` UID 20000130) has `ctrl_cd_display_form` left NULL (foundation.sql does not set it). For the Morb postprocessing SP to pick up the foundation row, the synthetic `nrt_observation` row we hand-author for it MUST set `ctrl_cd_display_form='MorbReport'`. This is the staging-side handle on the SP filter; the ODSE row remains unmodified.

- **Morb-internal act_relationship rows authored** (16 INV/MRB followups → v2 Morb Order; 2 user-comment followups → v2 Morb Order). Per the per-subject prompt these are explicitly allowed since both endpoints are Morb observations. Cross-subject act_relationships (Morb → Investigation) are NOT authored — that's Tier 2 territory.

- **`obs_value_*` rows in ODSE for the followups:** authored ODSE-side (`obs_value_coded` for INV128/INV145/INV148/INV149/INV178/MRB100/MRB129/MRB130/MRB161/MRB168, `obs_value_date` for MRB122/MRB165/MRB166/MRB167, `obs_value_txt` for MRB102/MRB169/C_Result) AND `nrt_observation_*` rows in RDB_MODERN. The postprocessing SP reads from the `nrt_observation_*` tables; the ODSE rows are for shape consistency / event SP JSON projection.

- **Patient/Provider/Organization soft cross-subject UIDs:** v2 Morb Order's nrt_observation row sets `patient_id=20000000` (foundation Patient), `morb_physician_id=20000010` (foundation Provider), `morb_reporter_id=20000010`, `morb_hosp_id=20000020`, `morb_hosp_reporter_id=20000020`, `health_care_id=20000020`, `author_organization_id/ordering_organization_id/performing_organization_id=20000020`. These are SOFT references (no FK in nrt_observation), used to drive the postprocessing SP's joins to D_PATIENT/d_provider/d_organization. At Tier 1 isolation the joins fail (sparse dim tables) — D_PATIENT failure blocks the EVENT INSERT (LINK_REQUIRED); the others COALESCE to 1 sentinel which is fine.

- **No D_PATIENT scaffolding row authored.** Notification Tier 1 originally added scaffolding rows to INVESTIGATION/CONDITION/RDB_DATE for similar isolation-blocking joins, then **rolled them back** as a Tier 1 contract violation (writing to other subjects' RDB_MODERN output tables). This Morb fixture follows the corrected contract: no scaffolding D_PATIENT row, isolation outcome is documented LINK_REQUIRED, merged-fixture sequence is the production target. The MORBIDITY_REPORT INSERT happens in an earlier transaction (lines 1062-1142) that commits before the failing MORBIDITY_REPORT_EVENT INSERT, so MORBIDITY_REPORT coverage is preserved at Tier 1 isolation.

## UID allocation table

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20080010 | @dbo_Act_morb_v2_order_uid | v2 Morb Order observation `act.act_uid` / `observation.observation_uid` (obs_domain_cd_st_1='Order', ctrl_cd_display_form='MorbReport') | Class `OBS`, mood `EVN`. Fully-attributed Morbidity Order variant for column coverage. cd='10110' (Hep A acute). |
| 20080020 | @dbo_Act_morb_v2_corder_uid | v2 followup C_Order observation `act.act_uid` / `observation.observation_uid` (obs_domain_cd_st_1='C_Order') | Class `OBS`, mood `EVN`. Drives MORB_RPT_USER_COMMENT path. NOT in @pMorbidityIdList; reached via v2 Order's followup_observation_uid CSV. |
| 20080021 | @dbo_Act_morb_v2_cresult_uid | v2 followup C_Result observation `act.act_uid` / `observation.observation_uid` (obs_domain_cd_st_1='C_Result') | Class `OBS`, mood `EVN`. Carries the user-comment txt in `obs_value_txt` (txt_type_cd='N') / `nrt_observation_txt`. |
| 20080100 | @dbo_Act_morb_v2_INV128 | v2 followup observation cd=`INV128` (HOSPITALIZED_IND) | Result-domain. obs_value_coded='Y'. |
| 20080101 | @dbo_Act_morb_v2_INV145 | v2 followup observation cd=`INV145` (DIE_FROM_ILLNESS_IND) | Result-domain. obs_value_coded='N'. |
| 20080102 | @dbo_Act_morb_v2_INV148 | v2 followup observation cd=`INV148` (DAYCARE_IND) | Result-domain. obs_value_coded='N'. |
| 20080103 | @dbo_Act_morb_v2_INV149 | v2 followup observation cd=`INV149` (FOOD_HANDLER_IND) | Result-domain. obs_value_coded='N'. |
| 20080104 | @dbo_Act_morb_v2_INV178 | v2 followup observation cd=`INV178` (PREGNANT_IND) | Result-domain. obs_value_coded='N'. |
| 20080105 | @dbo_Act_morb_v2_MRB100 | v2 followup observation cd=`MRB100` (MORB_RPT_TYPE) | Result-domain. obs_value_coded='INIT'. |
| 20080106 | @dbo_Act_morb_v2_MRB102 | v2 followup observation cd=`MRB102` (MORB_RPT_COMMENTS) | Result-domain. obs_value_txt 'FT'. |
| 20080107 | @dbo_Act_morb_v2_MRB122 | v2 followup observation cd=`MRB122` (TEMP_ILLNESS_ONSET_DT_KEY) | Result-domain. obs_value_date 2026-03-25. |
| 20080108 | @dbo_Act_morb_v2_MRB129 | v2 followup observation cd=`MRB129` (NURSING_HOME_ASSOCIATE_IND) | Result-domain. obs_value_coded='N'. |
| 20080109 | @dbo_Act_morb_v2_MRB130 | v2 followup observation cd=`MRB130` (HEALTHCARE_ORG_ASSOCIATE_IND) | Result-domain. obs_value_coded='N'. |
| 20080110 | @dbo_Act_morb_v2_MRB161 | v2 followup observation cd=`MRB161` (MORB_RPT_DELIVERY_METHOD) | Result-domain. obs_value_coded='Web'. |
| 20080111 | @dbo_Act_morb_v2_MRB165 | v2 followup observation cd=`MRB165` (TEMP_DIAGNOSIS_DT_KEY / DIAGNOSIS_DT) | Result-domain. obs_value_date 2026-03-30. |
| 20080112 | @dbo_Act_morb_v2_MRB166 | v2 followup observation cd=`MRB166` (HSPTL_ADMISSION_DT) | Result-domain. obs_value_date 2026-03-31. |
| 20080113 | @dbo_Act_morb_v2_MRB167 | v2 followup observation cd=`MRB167` (TEMP_HSPTL_DISCHARGE_DT_KEY) | Result-domain. obs_value_date 2026-04-02. |
| 20080114 | @dbo_Act_morb_v2_MRB168 | v2 followup observation cd=`MRB168` (SUSPECT_FOOD_WTRBORNE_ILLNESS) | Result-domain. obs_value_coded='N'. |
| 20080115 | @dbo_Act_morb_v2_MRB169 | v2 followup observation cd=`MRB169` (MORB_RPT_OTHER_SPECIFY) | Result-domain. obs_value_txt 'FT'. |

The fixture also writes:
- 1 row to `NBS_ODSE.dbo.act_id` keyed on `act_uid=20000130` (foundation Morbidity enrichment — foundation has none).
- 1 row to `NBS_ODSE.dbo.act_id` keyed on `act_uid=20080010` (v2 Morb Order — local id).
- 19 rows to `NBS_ODSE.dbo.act` (one per v2 observation: 1 Order + 2 user-comment + 16 INV/MRB followups).
- 19 rows to `NBS_ODSE.dbo.observation` (same set).
- 18 rows to `NBS_ODSE.dbo.act_relationship` (Morb-internal: C_Order→Order, C_Result→C_Order, 16 INV/MRB followups→Order).
- 10 rows to `obs_value_coded` (INV128/INV145/INV148/INV149/INV178/MRB100/MRB129/MRB130/MRB161/MRB168).
- 4 rows to `obs_value_date` (MRB122/MRB165/MRB166/MRB167).
- 3 rows to `obs_value_txt` (MRB102/MRB169 'FT', C_Result 'N').

In RDB_MODERN:
- 20 rows to `dbo.nrt_observation` (foundation Morb Order + v2 Morb Order + v2 C_Order/C_Result + 16 INV/MRB followups).
- 10 rows to `dbo.nrt_observation_coded`.
- 4 rows to `dbo.nrt_observation_date`.
- 3 rows to `dbo.nrt_observation_txt`.

No surrogate-key tables hand-authored — Morbidity uses inline-IDENTITY-temp-table allocation rather than IDENTITY-column nrt_*_key tables (so no IDENTITY-counter quirk like Lab's `nrt_lab_test_result_group_key`).

No cross-subject `act_relationship`, `participation`, `nbs_act_entity` rows. No INSERTs into other subjects' RDB_MODERN output tables (D_PATIENT, INVESTIGATION, CONDITION, RDB_DATE, LAB_TEST, LAB_TEST_RESULT). Foundation rows unmodified.
