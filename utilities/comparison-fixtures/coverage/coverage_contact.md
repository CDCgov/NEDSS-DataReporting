# Coverage: Contact Record (Tier 1)

## Inputs
- Baseline: 6.0.18.1 (post-liquibase migration)
- UID range allocated: 20120000 - 20129999
- Foundation dependencies (read-only):
  - `@dbo_Act_contact_uid = 20000170` — foundation Contact Act + ct_contact row
  - `@dbo_Entity_patient_uid = 20000000` — referenced via v2 ct_contact.subject_entity_uid + nrt_contact.SUBJECT_ENTITY_UID + THIRD_PARTY_ENTITY_UID; also satisfies foundation ct_contact's NOT-NULL FKs
  - `@dbo_Act_investigation_uid = 20000100` — referenced via v2 ct_contact.subject_entity_phc_uid / contact_entity_phc_uid / third_party_entity_phc_uid + matching nrt_contact columns
  - `@dbo_Act_interview_uid = 20000140` — referenced via v2 nrt_contact.NAMED_DURING_INTERVIEW_UID
  - `@dbo_Entity_organization_uid = 20000020` — referenced via v2 nrt_contact.CONTACT_EXPOSURE_SITE_UID
  - `@dbo_Entity_provider_uid = 20000010` — referenced via v2 nrt_contact.PROVIDER_CONTACT_INVESTIGATOR_UID + DISPOSITIONED_BY_UID
  - `@superuser_id = 10009282` — sentinel
- Other-agent dependencies (UID range registry): none. Contact is fully isolated at Tier 1; no other Tier 1 subject's UIDs are referenced in this fixture.

## SPs verified
- `dbo.sp_contact_record_event @cc_uids = '20000170,20120010', @debug = 0` — **FAILED with parser error** at line 52: `Invalid object name 'nbs_odse.dbo.fn_get_value_by_cd_codeset'`. This is a baseline-RTR bug: the SP body at line 69 references the function via `nbs_odse.dbo.fn_get_value_by_cd_codeset` but the function actually lives in `RDB_MODERN.dbo.fn_get_value_by_cd_codeset` (verified across all five DBs — only RDB_MODERN has it). The CASE expression that wraps this call is gated by `cc.CONTACT_STATUS is not null and cc.CONTACT_STATUS != ''`, so leaving CONTACT_STATUS NULL on every ct_contact row was attempted to short-circuit the call — but SQL Server resolves object names at parse time for the whole SELECT, regardless of CASE branch evaluation. The SP cannot run against any input. **Not a blocker for stop conditions** per STRATEGY.md "RTR transformation chain": event SPs are a contract test, not a staging populator. Their failure does not gate fixture verification, which depends on the postprocessing SPs only. Documented as `OUT_OF_SCOPE_RTR_BUG` below.
- `dbo.sp_d_contact_record_postprocessing @contact_uids = '20000170,20120010', @debug = 0` — **exit code 0**, 2 rows inserted into `dbo.NRT_CONTACT_KEY` (allocating D_CONTACT_RECORD_KEY 2 + 3) and 2 rows inserted into `dbo.D_CONTACT_RECORD`. `Missing NRT Record` early-return NOT triggered. `job_flow_log` ends with `step_name='COMPLETE'`, `status_type='COMPLETE'`, step 999.
- `dbo.sp_f_contact_record_case_postprocessing @contact_uids = '20000170,20120010', @debug = 0` — **exit code 0**, 2 rows inserted into `dbo.F_CONTACT_RECORD_CASE`. `job_flow_log` ends with `step_name='COMPLETE'`, `status_type='COMPLETE'`, step 999.

Both postprocessing SPs ran with `status_type=COMPLETE` and no `ERROR` rows in `job_flow_log`. Iteration count: **2** (first iteration discovered the `ct_contact.contact_entity_uid UNIQUE KEY` constraint forbids reusing foundation Patient for v2; resolved by allocating a v2 contact-party entity at 20120020).

## UID allocation table

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20120010 | @dbo_Act_contact_v2_uid | v2 Contact `act.act_uid` + `ct_contact.ct_contact_uid` | Class `ENC`, mood `EVN`. Fully-attributed Contact variant; every column the postprocessing SPs read from `nrt_contact` set non-NULL except CONTACT_STATUS (left NULL — see RTR-bug note in SP-verified section). |
| 20120020 | @dbo_Entity_contact_party_uid | v2 contact-party `entity.entity_uid` + `person.person_uid` | Class `PSN`, person.cd `PAT`. Required because `ct_contact.contact_entity_uid` has a UNIQUE constraint (`UQ_CT_contact_3101`); foundation Patient (20000000) is consumed by foundation ct_contact's contact_entity_uid, so v2 needs a distinct entity. Subject_entity_uid + third_party_entity_uid have no UNIQUE constraint and remain pointed at foundation Patient. Minimal person row (no person_name). |

Unused UIDs in Contact Tier 1 block (20120000-20120009, 20120011-20120019, 20120021-20129999) are reserved for future Contact Tier 1 / Tier 3 amendments. Do not allocate from this range outside of Contact Tier 1.

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_contact` keyed on `contact_uid` 20000170 (foundation) and 20120010 (v2). Those identities are not new UIDs — they reference the foundation Contact created in 00_foundation.sql plus the v2 Act+ct_contact above. No `nrt_contact_answer` rows authored — `dbo.nrt_metadata_columns` is empty for `TABLE_NAME='D_CONTACT_RECORD'` in baseline 6.0.18.1, so the d_contact_record postprocessing SP's dynamic PIVOT collapses to a no-op.

No surrogate-key tables hand-authored — the d_contact_record postprocessing SP allocates `nrt_contact_key` IDENTITY at lines 234-238. IDENT_CURRENT verified at 2 at baseline (clean state, sane).

## Columns populated

### D_CONTACT_RECORD (live: 66 / catalog: 45 / SP-write set: 41 / populated: 41 / 41)

41 of 66 live columns are within the postprocessing SP's static write list (the `INSERT INTO dbo.D_CONTACT_RECORD` column list at lines 374-416). The remaining 25 live columns are out-of-scope at Tier 1 (see "Columns deliberately skipped"). All 41 SP-populated columns populated on v2 (D_CONTACT_RECORD_KEY=3.0); foundation row (D_CONTACT_RECORD_KEY=2.0) populates the 8 system columns and leaves the 33 detail columns NULL to exhibit the null/blank path.

| Column | Foundation (UID 20000170 / KEY=2.0) | v2 (UID 20120010 / KEY=3.0) |
| --- | --- | --- |
| D_CONTACT_RECORD_KEY | 2.0 (allocated by IDENTITY in nrt_contact_key) | 3.0 |
| ADD_TIME | 2026-04-01 00:00:00 | 2026-04-15 10:00:00 |
| ADD_USER_ID | 10009282 | 10009282 |
| CONTACT_ENTITY_EPI_LINK_ID | NULL | `EPI20120010` |
| CTT_DISPO_DT | NULL | 2026-04-20 08:00:00 |
| CTT_EVAL_DT | NULL | 2026-04-13 08:00:00 |
| CTT_EVAL_NOTES | NULL | `Evaluation completed at PHC.` |
| CTT_INV_ASSIGNED_DT | NULL | 2026-04-10 08:00:00 |
| LAST_CHG_TIME | 2026-04-01 00:00:00 | 2026-04-15 10:00:00 |
| LAST_CHG_USER_ID | 10009282 | 10009282 |
| LOCAL_ID | `CON20000170GA01` | `CON20120010GA01` |
| CTT_NAMED_ON_DT | NULL | 2026-04-09 08:00:00 |
| PROGRAM_JURISDICTION_OID | NULL | 9999999 |
| RECORD_STATUS_CD | `ACTIVE` | `ACTIVE` |
| RECORD_STATUS_TIME | 2026-04-01 00:00:00 | 2026-04-15 10:00:00 |
| CTT_RISK_NOTES | NULL | `Sexual partner identified by index case during interview.` |
| SUBJECT_ENTITY_EPI_LINK_ID | NULL | `EPI20000000` |
| CTT_SYMP_ONSET_DT | NULL | 2026-04-12 08:00:00 |
| CTT_SYMP_NOTES | NULL | `Mild GI symptoms, fever.` |
| CTT_TRT_END_DT | NULL | 2026-04-25 08:00:00 |
| CTT_TRT_START_DT | NULL | 2026-04-14 08:00:00 |
| CTT_TRT_NOTES | NULL | `Treatment plan: 14-day course Acyclovir 400mg TID.` |
| CTT_NOTES | NULL | `Contact identified during partner-services interview.` |
| VERSION_CTRL_NBR | 1 | 1 |
| CTT_PROGRAM_AREA | NULL | `HEP` (PROGRAM_AREA_CODE.prog_area_desc_txt for code 'HEP') |
| CTT_JURISDICTION_NM | NULL | `Fulton County` (JURISDICTION_CODE for '130001') |
| CTT_SHARED_IND | NULL | `Yes` (YN code 'Y') |
| CTT_SYMP_IND | NULL | `Yes` (YNU code 'Y') |
| CTT_RISK_IND | NULL | `Yes` (YNU code 'Y') |
| CTT_EVAL_COMPLETED | NULL | `Yes` (YNU code 'Y') |
| CTT_TRT_INITIATED_IND | NULL | `Yes` (YNU code 'Y') |
| CTT_DISPOSITION | NULL | `Confirmed Case` (NBS_DISPO code 'CONF') |
| CTT_PRIORITY | NULL | `High` (NBS_PRIORITY code 'HIGH') |
| CTT_RELATIONSHIP | NULL | `Partner` (NBS_RELATIONSHIP code 'PARTNER') |
| CTT_TRT_NOT_START_RSN | NULL | `Refused Treatment` (NBS_NO_TRTMNT_REAS 'REFUSETX') |
| CTT_TRT_NOT_COMPLETE_RSN | NULL | `Provider Decision` (NBS_NO_TRTMNT_REAS 'PROVDEC') |
| CTT_HEALTH_STATUS | NULL | `Acute Illness` (NBS_HEALTH_STATUS 'AILL') |
| CTT_PROCESSING_DECISION | NULL | `Field Follow-up` (STD_CONTACT_RCD_PROCESSING_DECISION 'FF') |
| CTT_STATUS | NULL | `Active` (free-text — does NOT come from event SP's INV109 codeset call; populated directly via nrt_contact.CTT_STATUS to bypass the broken event SP path) |
| CTT_REFERRAL_BASIS | NULL | `P1 - Partner, Sex` (REFERRAL_BASIS code 'P1') |
| CTT_GROUP_LOT_ID | NULL | `GRP_HEPA` (raw code propagated through; NBS_GROUP_NM is empty in baseline so the event SP's LEFT JOIN to code_value_general would surface NULL — at Tier 1 isolation the postprocessing SP just propagates whatever we put in nrt_contact.CTT_GROUP_LOT_ID. SRTE_GAP — see below.) |
| CTT_TRT_COMPLETE_IND | NULL | `No` (YNU code 'N') |

### F_CONTACT_RECORD_CASE (live: 11 / catalog: 12; populated: 11 / 11)

Both rows inserted (D_CONTACT_RECORD_KEY 2.0 + 3.0). Cross-subject keys all resolve to sentinel 1 at Tier 1 isolation: the F_postproc SP COALESCEs every key column to 1 explicitly (`coalesce(inv3.INVESTIGATION_KEY, 1) as CONTACT_INVESTIGATION_KEY`, etc., lines 79-103). D_PATIENT/D_PROVIDER/D_ORGANIZATION/INVESTIGATION/NRT_INTERVIEW_KEY are empty for our foundation UIDs at Tier 1 isolation, so all 10 surrogate-key columns COALESCE to 1.

| Column | Foundation (KEY=2.0) | v2 (KEY=3.0) | Notes |
| --- | --- | --- | --- |
| D_CONTACT_RECORD_KEY | 2.0 | 3.0 | Allocated via nrt_contact_key IDENTITY; resolved by F_postproc's #F_CRC_INIT_KEYS join |
| THIRD_PARTY_ENTITY_KEY | 1 | 1 | COALESCE(pt1.PATIENT_KEY, 1) — D_PATIENT empty for foundation Patient |
| CONTACT_KEY | 1 | 1 | COALESCE(pt2.PATIENT_KEY, 1) — D_PATIENT empty for foundation Patient (foundation row's nrt_contact.CONTACT_ENTITY_UID); v2 row's CONTACT_ENTITY_UID = @dbo_Entity_contact_party_uid (20120020) which is also not in D_PATIENT |
| SUBJECT_KEY | 1 | 1 | COALESCE(pt3.PATIENT_KEY, 1) — D_PATIENT empty for foundation Patient |
| THIRD_PARTY_INVESTIGATION_KEY | 1 | 1 | COALESCE(inv1.INVESTIGATION_KEY, 1) — INVESTIGATION empty for foundation Investigation; foundation row's nrt_contact.THIRD_PARTY_ENTITY_PHC_UID NULL → join NULL → COALESCE 1 |
| SUBJECT_INVESTIGATION_KEY | 1 | 1 | COALESCE(inv2.INVESTIGATION_KEY, 1) — INVESTIGATION empty for foundation Investigation |
| CONTACT_INVESTIGATION_KEY | 1 | 1 | COALESCE(inv3.INVESTIGATION_KEY, 1) — INVESTIGATION empty for foundation Investigation; foundation row's nrt_contact.CONTACT_ENTITY_PHC_UID populated, v2's also populated, but neither resolves to a row in dbo.INVESTIGATION at Tier 1 isolation |
| CONTACT_INTERVIEW_KEY | 1.0 | 1.0 | COALESCE(intw.D_INTERVIEW_KEY, 1) — NRT_INTERVIEW_KEY empty in baseline; foundation row's nrt_contact.NAMED_DURING_INTERVIEW_UID NULL → join NULL → COALESCE 1; v2 row's NAMED_DURING_INTERVIEW_UID = foundation Interview but NRT_INTERVIEW_KEY empty so still 1 |
| DISPOSITIONED_BY_KEY | 1 | 1 | COALESCE(pv2.PROVIDER_KEY, 1) — D_PROVIDER empty for foundation Provider |
| CONTACT_EXPOSURE_SITE_KEY | 1 | 1 | COALESCE(org.ORGANIZATION_KEY, 1) — D_ORGANIZATION empty for foundation Org |
| CONTACT_INVESTIGATOR_KEY | 1 | 1 | COALESCE(pv1.PROVIDER_KEY, 1) — D_PROVIDER empty for foundation Provider |

## Columns deliberately skipped

| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| D_CONTACT_RECORD | CTT_INITIATE_FOLLOWUP_DT, CTT_LAST_SEX_EXP_DT, CTT_FIRST_SEX_EXP_DT, CTT_LAST_NDLSHARE_EXP_DT, CTT_FIRST_NDLSHARE_EXP_DT, CTT_REL_WITH_PATIENT, CTT_ELICIT_INTERNET_INFO, CTT_MET_OP_INTERNET, CTT_SPOUSE_OF_OP, CTT_SOURCE_SPREAD, CTT_HEIGHT, CTT_SIZE_BUILD, CTT_OTHER_ID_INFO, CTT_HAIR, CTT_COMPLEXION, CTT_SEX_EXP_FREQ, CTT_NDLSHARE_EXP_FREQ, CTT_EXPOSURE_TYPE, CTT_EXPOSURE_SITE_TYPE, CTT_FIRST_EXPOSURE_DT, CTT_LAST_EXPOSURE_DT, CR_CONTACT1, CR_CONTACT2 (23 columns) | LDF / dynamic-PIVOT columns; populated only when `dbo.nrt_metadata_columns` has rows for `TABLE_NAME='D_CONTACT_RECORD'`. Verified empty in baseline 6.0.18.1 (`SELECT * FROM dbo.NRT_METADATA_COLUMNS WHERE TABLE_NAME='D_CONTACT_RECORD'` returns 0 rows). The `nrt_contact_answer` table accepts source rows but the d_contact_record postprocessing SP's dynamic PIVOT collapses to a no-op when @Col_number=0 (lines 260-263, 313-316, 363-372, 417-419, 463-466, 473-490). | sp_d_contact_record_postprocessing-001.sql lines 260-263, 313-316, 363-372, 417-419, 463-466, 473-490; live `dbo.nrt_metadata_columns WHERE TABLE_NAME='D_CONTACT_RECORD'` returned 0 rows |
| D_CONTACT_RECORD | TREATMNT_END_DESCRIPTION (1 column) | Live-schema column NOT in the d_contact_record postprocessing SP's INSERT/UPDATE column list. SP-static-extracted: lines 374-416 (INSERT col list) and 272-312 (UPDATE col list) do not reference TREATMNT_END_DESCRIPTION. Populated by neither the postprocessing SP nor any datamart SP per `rtr_target_columns.md`. Likely a phantom column from an older RDB version — left for an RTR maintainer to sweep. | sp_d_contact_record_postprocessing-001.sql lines 272-312, 374-416 (no TREATMNT_END_DESCRIPTION reference) |
| D_CONTACT_RECORD | (foundation row, KEY=2.0) — 33 of 41 SP-populated columns | Deliberate null-path coverage: foundation Contact's nrt_contact row is sparse (only 8 system columns populated); the d_postprocessing SP propagates NULLs straight into D_CONTACT_RECORD. Pairs with v2 row's fully-populated path to exercise both branches of every column the SP touches. | sp_d_contact_record_postprocessing-001.sql lines 96-145 (SELECT into #CONTACT_INIT) — propagation is direct, no defaulting/CASE on the SP side |

## Gaps reported

### OUT_OF_SCOPE
- **`D_CONTACT_RECORD` LDF/dynamic columns (23 columns)**: CTT_INITIATE_FOLLOWUP_DT, CTT_LAST_SEX_EXP_DT, CTT_FIRST_SEX_EXP_DT, CTT_LAST_NDLSHARE_EXP_DT, CTT_FIRST_NDLSHARE_EXP_DT, CTT_REL_WITH_PATIENT, CTT_ELICIT_INTERNET_INFO, CTT_MET_OP_INTERNET, CTT_SPOUSE_OF_OP, CTT_SOURCE_SPREAD, CTT_HEIGHT, CTT_SIZE_BUILD, CTT_OTHER_ID_INFO, CTT_HAIR, CTT_COMPLEXION, CTT_SEX_EXP_FREQ, CTT_NDLSHARE_EXP_FREQ, CTT_EXPOSURE_TYPE, CTT_EXPOSURE_SITE_TYPE, CTT_FIRST_EXPOSURE_DT, CTT_LAST_EXPOSURE_DT, CR_CONTACT1, CR_CONTACT2. These are populated only via the SP's dynamic PIVOT against `nrt_contact_answer`, gated by `nrt_metadata_columns.TABLE_NAME='D_CONTACT_RECORD'` having rows. Empty at baseline. Belongs to a Tier 3 LDF-coverage fixture once `nrt_metadata_columns` is seeded. (Same pattern as Interview's 6 LDF columns and Vaccination's empty NRT_METADATA_COLUMNS.)
- **`D_CONTACT_RECORD.TREATMNT_END_DESCRIPTION`**: Live-schema column not in any RTR SP's write list (verified static-extract of d_contact_record postprocessing + grep across `routines/`). Phantom or RDB-only column; not the fixture's responsibility.
- **`F_CONTACT_RECORD_CASE` cross-subject key resolution**: All 10 cross-subject keys (THIRD_PARTY_ENTITY_KEY, CONTACT_KEY, SUBJECT_KEY, THIRD_PARTY_INVESTIGATION_KEY, SUBJECT_INVESTIGATION_KEY, CONTACT_INVESTIGATION_KEY, CONTACT_INTERVIEW_KEY, DISPOSITIONED_BY_KEY, CONTACT_EXPOSURE_SITE_KEY, CONTACT_INVESTIGATOR_KEY) resolve to sentinel 1 at Tier 1 isolation because the source dimension tables (D_PATIENT, INVESTIGATION, D_PROVIDER, D_ORGANIZATION, NRT_INTERVIEW_KEY) are empty for our foundation UIDs. The SP COALESCEs every key to 1. The path completes — INSERT succeeds — but distinguishing real-key-resolution from sentinel-fallback requires merged-fixture sequence (Patient + Investigation + Provider + Organization + Interview Tier 1 chains run before Contact's f_postprocessing). Tier 1 verifies the SQL path completes; merged-fixture run will verify the keys resolve to non-1 surrogate keys.

### OUT_OF_SCOPE_RTR_BUG
- **`sp_contact_record_event` references nonexistent function `nbs_odse.dbo.fn_get_value_by_cd_codeset`**: The function actually lives in `RDB_MODERN.dbo.fn_get_value_by_cd_codeset` — verified across all 5 baseline DBs (NBS_ODSE, NBS_SRTE, RDB, RDB_MODERN, NBS_MSGOUTE); only RDB_MODERN has it. The SP at line 69 wraps the call in a CASE gated by `CONTACT_STATUS is not null and CONTACT_STATUS != ''`, but SQL Server resolves object names at parse time for the entire SELECT — leaving CONTACT_STATUS NULL on every ct_contact row does NOT short-circuit the parser error. The event SP cannot run successfully against any input until either the function is added to NBS_ODSE (or aliased via a synonym) or the SP body is rewritten to use the correct database qualifier. Per STRATEGY.md "RTR transformation chain" the event SP is a contract test, not a staging populator; its failure does not gate fixture verification. The two postprocessing SPs (which are the actual stop-condition gates) ran clean. Fixture authors don't own RTR; document-and-move-on per template Step 1.

### SRTE_GAP
- **`NBS_GROUP_NM` codeset is empty in baseline NBS_SRTE.dbo.code_value_general** (verified: `SELECT COUNT(*) FROM dbo.code_value_general WHERE code_set_nm='NBS_GROUP_NM'` returns 0). The event SP at line 151 LEFT JOINs to `code_value_general` on `code_set_nm='NBS_GROUP_NM'` and sources `CTT_GROUP_LOT_ID`'s description from `cvg12.code_short_desc_txt`. With no rows in the codeset, the JOIN surfaces NULL and the event SP would emit `CTT_GROUP_LOT_ID = NULL` even for non-empty `group_name_cd` source values. At Tier 1 isolation we propagate the raw code (`GRP_HEPA`) directly via `nrt_contact.CTT_GROUP_LOT_ID` — the postprocessing SP doesn't re-validate against SRTE; it copies the upstream-projected value. Once `NBS_GROUP_NM` is seeded in baseline SRTE the event SP would resolve to a real description. Belongs to Tier 0 amendment or upstream SRTE seeding.
- **`INV109` codeset (CONTACT_STATUS)**: Not directly verified — bypassed because we set CONTACT_STATUS NULL on every ct_contact row (see RTR-bug note). At Tier 1 we populate D_CONTACT_RECORD.CTT_STATUS via `nrt_contact.CTT_STATUS = 'Active'` (free text mirroring INV109's expected CDC value). Whether INV109 has rows in `nbs_srte.dbo.codeset` is moot for fixture verification given the broken event SP path.

### LINK_REQUIRED
- **`F_CONTACT_RECORD_CASE` 10 cross-subject keys resolution to non-sentinel-1 values**: Resolved in merged-fixture sequence after Patient + Investigation + Provider + Organization + Interview Tier 1 chains run. At Tier 1 isolation all 10 COALESCE to 1; merged-fixture run will surface real surrogate keys (e.g., CONTACT_INTERVIEW_KEY = NRT_INTERVIEW_KEY.D_INTERVIEW_KEY for foundation Interview UID 20000140 — which Interview Tier 1's d_postprocessing allocates as 2.0).

### FOUNDATION_GAP
- (none — foundation provided everything Contact Tier 1 needed: ct_contact row with hard NOT-NULL FKs satisfied, foundation Patient + Investigation + Interview + Provider + Org as referenceable parent UIDs.)

## Decisions made

- **Variant count: 2** (foundation + v2). Sufficient to exercise:
  - Both null/blank and fully-populated branches of every D_CONTACT_RECORD column the postprocessing SP populates from nrt_contact.
  - All 10 F_CONTACT_RECORD_CASE COALESCE-to-1 fallback paths (foundation row's NULL soft refs and v2's populated-but-unresolved soft refs both end up as sentinel 1 at Tier 1 isolation; merged-fixture run will distinguish them).
  - No additional v3 needed — Contact's SPs have no CASE branches conditional on row-level `*_CD` values that would warrant a third variant. The postprocessing SP is straight pass-through; the F-postproc only branches on COALESCE-1 fallback.
- **Contact health status: `AILL` (Acute Illness)** from NBS_HEALTH_STATUS. Chosen as a domain-realistic non-sentinel value; any of {AILL, ASYM, CILL, DEAD, MILL, MLDS, MODS, RCVD, REFD, SEVS, UASK, UNK} would have worked equivalently for column-coverage purposes.
- **Exposure indicator codes**: `Y` for shared_ind (YN), symptom (YNU), risk_factor (YNU), evaluation_completed (YNU), treatment_initiated (YNU); `N` for treatment_end (YNU). Chosen to drive the populated-path through every CTT_*_IND column. The postprocessing SP propagates these as upstream-projected SRTE descriptions ('Yes', 'No') from nrt_contact's CTT_* columns — no SP-side re-validation.
- **Disposition: `CONF` (Confirmed Case)** from NBS_DISPO. Driven primarily for column-coverage realism; `NBS_DISPO` and `FIELD_FOLLOWUP_DISPOSITION_STD` are union-joined by the event SP at line 145 (`code_set_nm in ('NBS_DISPO', 'FIELD_FOLLOWUP_DISPOSITION_STD')`); we used NBS_DISPO. (FIELD_FOLLOWUP_DISPOSITION_STD code 'C' = 'C - Infected, Brought to Treatment' would have exercised the alternate codeset path on the event SP — moot at Tier 1 since the event SP is broken.)
- **CONTACT_STATUS strategy: NULL on both variants**. Driven by the `nbs_odse.dbo.fn_get_value_by_cd_codeset` 3-part-name bug. The CTT_STATUS column on D_CONTACT_RECORD is still populated for v2 via direct `nrt_contact.CTT_STATUS='Active'` assignment, since the d_postprocessing SP propagates this column straight from staging without re-resolving against SRTE.
- **v2 contact-party entity at 20120020**: Allocated because `ct_contact.contact_entity_uid` has a UNIQUE constraint (`UQ_CT_contact_3101`); foundation Patient (20000000) is consumed by foundation ct_contact's contact_entity_uid. Subject_entity_uid + third_party_entity_uid have no UNIQUE constraint and remain pointed at foundation Patient.
- **No `nrt_contact_answer` rows**: NRT_METADATA_COLUMNS for D_CONTACT_RECORD is empty in baseline — authoring nrt_contact_answer rows is inert at Tier 1 (PIVOT collapses to no-op). Belongs to a Tier 3 LDF fixture once metadata is seeded.
- **No cross-subject NBS_act_entity / Act_relationship / Participation rows**: Per template forbidden-list. The event SP's three NBS_act_entity LEFT JOINs (SiteOfExposure / InvestgrOfContact / DispoInvestgrOfConRec) at lines 155-157 will surface NULL — moot at Tier 1 since the event SP is broken anyway. The F-postproc reads CONTACT_EXPOSURE_SITE_UID / PROVIDER_CONTACT_INVESTIGATOR_UID / DISPOSITIONED_BY_UID directly from nrt_contact (which we populate), not from NBS_act_entity — so we successfully drive those soft-ref UIDs into the F-postproc joins without authoring any NBS_act_entity rows.
- **No SP-execution invocation of `sp_covid_contact_datamart_postprocessing`, `sp_public_health_case_fact_datamart_event`, or `sp_public_health_case_fact_datamart_update`**: per per-subject prompt's "NOT in scope" list. These are Tier 2 / datamart-side SPs that will run in the merged-fixture sequence after Tier 2 wires participation rows.
