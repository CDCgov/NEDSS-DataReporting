USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 1 Morbidity Report fixture
-- Baseline: 6.0.18.1 (post-liquibase) + fixtures/00_foundation/00_foundation.sql
--
-- ARCHITECTURAL NOTE
--   Morbidity Report shares the event SP with Lab — `sp_observation_event`
--   — and is distinguished by `obs.ctrl_cd_display_form = 'MorbReport'`
--   plus `obs.obs_domain_cd_st_1 = 'Order'` (the same Order domain Lab
--   uses, but with a different display-form sentinel).
--
--   The postprocessing SP is `sp_d_morbidity_report_postprocessing` (note
--   filename uses `nrt_morbidity_report_postprocessing` but the SP inside
--   is `sp_d_morbidity_report_postprocessing`). Param name is
--   `@pMorbidityIdList` (camelCase, "p" prefix).
--
--   The Morbidity SP filters at line 281-282:
--     WHERE obs.obs_domain_cd_st_1 = 'Order' AND obs.CTRL_CD_DISPLAY_FORM = 'MorbReport'
--
--   The SP pivots followup observations whose `cd` is in a fixed list of
--   codes (INV128, INV145, INV148, INV149, INV178, MRB100, MRB102,
--   MRB122, MRB129, MRB130, MRB161, MRB165, MRB166, MRB167, MRB168, MRB169)
--   into MORBIDITY_REPORT columns:
--     INV128 -> HOSPITALIZED_IND        (coded)
--     INV145 -> DIE_FROM_ILLNESS_IND    (coded)
--     INV148 -> DAYCARE_IND             (coded)
--     INV149 -> FOOD_HANDLER_IND        (coded)
--     INV178 -> PREGNANT_IND            (coded)
--     MRB100 -> MORB_RPT_TYPE           (coded)
--     MRB102 -> MORB_RPT_COMMENTS       (txt)
--     MRB122 -> TEMP_ILLNESS_ONSET_DT_KEY (date)
--     MRB129 -> NURSING_HOME_ASSOCIATE_IND (coded; substring 1,1)
--     MRB130 -> HEALTHCARE_ORG_ASSOCIATE_IND (coded)
--     MRB161 -> MORB_RPT_DELIVERY_METHOD (coded)
--     MRB165 -> TEMP_DIAGNOSIS_DT_KEY / DIAGNOSIS_DT (date)
--     MRB166 -> HSPTL_ADMISSION_DT      (date)
--     MRB167 -> TEMP_HSPTL_DISCHARGE_DT_KEY (date)
--     MRB168 -> SUSPECT_FOOD_WTRBORNE_ILLNESS (coded)
--     MRB169 -> MORB_RPT_OTHER_SPECIFY  (txt)
--
--   Cross-subject FK joins in MORBIDITY_REPORT_EVENT mostly use COALESCE:
--     INVESTIGATION_KEY -> 1, HSPTL_KEY -> 1, MORB_RPT_SRC_ORG_KEY -> 1,
--     REPORTER_KEY -> 1, HEALTH_CARE_KEY -> 1, dt-keys -> 1, etc.
--   Two are NOT COALESCEd:
--     - PATIENT_KEY (no fallback, NULL on Tier 1 isolation since
--       d_patient is empty — LINK_REQUIRED, documented in coverage)
--     - LDF_GROUP_KEY (no fallback either; the SP body actually
--       COALESCEs to 1 in the SELECT-INTO at line 967, but the
--       INSERT/UPDATE re-emits tmp.[LDF_GROUP_KEY] without COALESCE.
--       Net result: 1 — sentinel from COALESCE in the SELECT-INTO).
--
--   The SP's UPDATE to LAB_TEST_RESULT.morb_rpt_key (line 335) is a
--   no-op at Tier 1 isolation (LAB_TEST_RESULT.morb_rpt_key is NULL on
--   all rows because no morbidity has linked yet, and we do not
--   pre-populate LAB_TEST_RESULT in this fixture).
--
-- WHAT THIS FIXTURE DOES
--   1. Foundation Morbidity enrichment: keep the foundation observation
--      (UID 20000130) `Order` row unmodified per the Tier 1 contract.
--      Add an `act_id` row keyed on its act_uid (foundation has none).
--      The foundation nrt_observation row is sparse (no followup
--      observations attached, no associated_phc_uids), exhibiting the
--      SP's null/blank propagation path.
--   2. v2 Morbidity Order: a fully-attributed Order observation
--      (UID 20080010, ctrl_cd_display_form='MorbReport') in this block.
--      Every column the postprocessing SP reads is set. condition cd
--      '10110' (Hep A acute) consistent with Lab + Investigation.
--   3. v2 followup observations (16 obs, UIDs 20080100..20080115) — each
--      carries one of the INV/MRB codes that drives a column in
--      MORBIDITY_REPORT via the SP's pivot. Coded codes have a
--      corresponding nrt_observation_coded row; date codes have a
--      nrt_observation_date row; txt codes have a nrt_observation_txt
--      row. v2 Morbidity's `followup_observation_uid` CSV lists all 16
--      so the SP's CROSS APPLY string_split picks them up.
--   4. v2 followup C_Order/C_Result pair (UIDs 20080020/20080021) drives
--      the MORB_RPT_USER_COMMENT path. C_Result obs_value_txt provides
--      the comment text.
--   5. Synthetic staging rows in RDB_MODERN:
--        - dbo.nrt_observation: 20 rows total (foundation Morb Order +
--          v2 Morb Order + v2 C_Order + v2 C_Result + 16 v2 followups)
--        - dbo.nrt_observation_coded: 11 rows (one per coded MRB/INV
--          followup)
--        - dbo.nrt_observation_date: 4 rows (MRB122/165/166/167)
--        - dbo.nrt_observation_txt: 3 rows (MRB102, MRB169, C_Result
--          user-comment)
--   6. Does NOT author cross-subject act_relationship rows (Morb ->
--      Investigation). MORBIDITY_REPORT_EVENT.INVESTIGATION_KEY etc.
--      resolve to 1 via COALESCE.
--   7. Does NOT hand-author surrogate-key tables (none exist for
--      Morbidity — the SP allocates morb_rpt_key + user_comment_key
--      via the inline tmp_id_assignment + MAX-key + offset pattern).
--   8. Does NOT invoke `sp_morbidity_report_datamart_postprocessing`
--      (Tier 2/3 territory).
--
-- UID block (Morbidity Tier 1): 20080000-20089999.
-- Foundation dependencies (read-only):
--   @dbo_Act_morbidity_uid       20000130  (act / observation Order, foundation)
--   @dbo_Entity_patient_uid      20000000  (referenced via observation.subject_person_uid + nrt_observation.patient_id)
--   @dbo_Entity_provider_uid     20000010  (referenced via nrt_observation.morb_physician_id + morb_reporter_id)
--   @dbo_Entity_organization_uid 20000020  (referenced via nrt_observation.morb_hosp_id, morb_hosp_reporter_id, health_care_id, author_organization_id)
-- =====================================================================

-- ----- Sentinel reference -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Foundation dependencies referenced (read-only) -----
DECLARE @foundation_act_morb_uid   bigint = 20000130;  -- foundation Morb Order Act / observation
DECLARE @foundation_patient_uid    bigint = 20000000;  -- foundation Patient (subject_person_uid)
DECLARE @foundation_provider_uid   bigint = 20000010;  -- foundation Provider (morb_physician/reporter)
DECLARE @foundation_org_uid        bigint = 20000020;  -- foundation Organization (morb_hosp / morb_hosp_reporter / health_care / author)

-- =====================================================================
-- UID allocations (Morbidity Tier 1: 20080000-20089999)
-- =====================================================================

-- ----- v2 Morbidity Order -----
DECLARE @dbo_Act_morb_v2_order_uid    bigint = 20080010;  -- v2 Morb Order observation (root)

-- ----- v2 followup C_Order / C_Result for user comment -----
DECLARE @dbo_Act_morb_v2_corder_uid   bigint = 20080020;  -- v2 C_Order
DECLARE @dbo_Act_morb_v2_cresult_uid  bigint = 20080021;  -- v2 C_Result

-- ----- v2 followup observations carrying INV/MRB codes (1 per code, 16 codes) -----
DECLARE @dbo_Act_morb_v2_INV128       bigint = 20080100;  -- HOSPITALIZED_IND (coded)
DECLARE @dbo_Act_morb_v2_INV145       bigint = 20080101;  -- DIE_FROM_ILLNESS_IND (coded)
DECLARE @dbo_Act_morb_v2_INV148       bigint = 20080102;  -- DAYCARE_IND (coded)
DECLARE @dbo_Act_morb_v2_INV149       bigint = 20080103;  -- FOOD_HANDLER_IND (coded)
DECLARE @dbo_Act_morb_v2_INV178       bigint = 20080104;  -- PREGNANT_IND (coded)
DECLARE @dbo_Act_morb_v2_MRB100       bigint = 20080105;  -- MORB_RPT_TYPE (coded)
DECLARE @dbo_Act_morb_v2_MRB102       bigint = 20080106;  -- MORB_RPT_COMMENTS (txt)
DECLARE @dbo_Act_morb_v2_MRB122       bigint = 20080107;  -- TEMP_ILLNESS_ONSET_DT_KEY (date)
DECLARE @dbo_Act_morb_v2_MRB129       bigint = 20080108;  -- NURSING_HOME_ASSOCIATE_IND (coded; substring 1,1)
DECLARE @dbo_Act_morb_v2_MRB130       bigint = 20080109;  -- HEALTHCARE_ORG_ASSOCIATE_IND (coded)
DECLARE @dbo_Act_morb_v2_MRB161       bigint = 20080110;  -- MORB_RPT_DELIVERY_METHOD (coded)
DECLARE @dbo_Act_morb_v2_MRB165       bigint = 20080111;  -- TEMP_DIAGNOSIS_DT_KEY / DIAGNOSIS_DT (date)
DECLARE @dbo_Act_morb_v2_MRB166       bigint = 20080112;  -- HSPTL_ADMISSION_DT (date)
DECLARE @dbo_Act_morb_v2_MRB167       bigint = 20080113;  -- TEMP_HSPTL_DISCHARGE_DT_KEY (date)
DECLARE @dbo_Act_morb_v2_MRB168       bigint = 20080114;  -- SUSPECT_FOOD_WTRBORNE_ILLNESS (coded)
DECLARE @dbo_Act_morb_v2_MRB169       bigint = 20080115;  -- MORB_RPT_OTHER_SPECIFY (txt)

-- =====================================================================
-- ODSE rows — additive enrichments and v2 variant.
-- =====================================================================

-- =====================================================================
-- Foundation Morbidity enrichment: act_id (local id).
-- The foundation observation 20000130 has no act_id; this enrichment
-- gives the event SP's act_ids JSON branch a non-empty array on the
-- foundation variant.
-- =====================================================================
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@foundation_act_morb_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE',
     '2026-04-01T00:00:00', N'OBS20000130GA01', N'OBS_LOCAL_ID',
     N'Local Observation Identifier', N'A', '2026-04-01T00:00:00');

-- =====================================================================
-- v2 act parent rows.
-- act.class_cd 'OBS' from SRTE ACT_CLS; mood_cd 'EVN'.
-- =====================================================================
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@dbo_Act_morb_v2_order_uid,    N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_corder_uid,   N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_cresult_uid,  N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_INV128,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_INV145,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_INV148,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_INV149,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_INV178,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_MRB100,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_MRB102,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_MRB122,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_MRB129,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_MRB130,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_MRB161,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_MRB165,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_MRB166,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_MRB167,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_MRB168,       N'OBS', N'EVN'),
    (@dbo_Act_morb_v2_MRB169,       N'OBS', N'EVN');

-- =====================================================================
-- v2 Morb Order observation — fully-attributed Order parent.
-- ctrl_cd_display_form='MorbReport' satisfies the Morbidity
-- postprocessing SP's WHERE clause (line 282 of
-- sp_d_morbidity_report_postprocessing).
-- condition cd '10110' (Hepatitis A, acute) consistent with Lab +
-- Investigation per STRATEGY.md single-condition-per-family at v1.
-- subject_person_uid = foundation Patient.
-- =====================================================================
INSERT INTO [dbo].[observation]
    ([observation_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [cd_system_cd], [cd_system_desc_txt],
     [last_chg_time], [last_chg_user_id], [local_id],
     [obs_domain_cd_st_1], [obs_domain_cd], [ctrl_cd_display_form],
     [record_status_cd], [record_status_time],
     [status_cd], [status_time], [subject_person_uid],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [electronic_ind],
     [activity_to_time], [effective_from_time], [rpt_to_state_time],
     [activity_from_time], [target_site_cd], [target_site_desc_txt],
     [txt], [priority_cd], [processing_decision_cd], [pregnant_ind_cd])
VALUES
    (@dbo_Act_morb_v2_order_uid, '2026-04-04T00:00:00', @superuser_id,
     N'10110', N'Hepatitis A, acute',
     N'2.16.840.1.114222.4.5.277', N'PHIN_CONDITION',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080010GA01',
     N'Order', N'Order', N'MorbReport',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1, N'STD', N'130001',
     20080010, N'Y',
     '2026-04-04T08:00:00', '2026-04-03T18:00:00', '2026-04-04T10:00:00',
     '2026-04-03T18:00:00', N'WBLD', N'Whole blood',
     N'Tier 1 v2 Morbidity Report — clinical narrative.',
     N'R', N'AC', N'N');

-- =====================================================================
-- v2 followup C_Order / C_Result observations — drive
-- MORB_RPT_USER_COMMENT path. C_Order/C_Result fall outside the SP's
-- 'Order' filter so are NOT in @pMorbidityIdList, but reached via v2
-- Morb Order's followup_observation_uid CSV.
-- =====================================================================
INSERT INTO [dbo].[observation]
    ([observation_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [last_chg_time], [last_chg_user_id], [local_id],
     [obs_domain_cd_st_1], [obs_domain_cd],
     [record_status_cd], [record_status_time],
     [status_cd], [status_time], [subject_person_uid],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [electronic_ind],
     [activity_to_time])
VALUES
    (@dbo_Act_morb_v2_corder_uid, '2026-04-04T08:00:00', @superuser_id,
     N'NTE', N'Notes Comment Order',
     '2026-04-04T08:00:00', @superuser_id, N'OBS20080020GA01',
     N'C_Order', N'C_Order',
     N'PROCESSED', '2026-04-04T08:00:00',
     N'A', '2026-04-04T08:00:00', @foundation_patient_uid,
     N'T', 1, N'STD', N'130001',
     20080010, N'Y',
     '2026-04-04T08:00:00'),
    (@dbo_Act_morb_v2_cresult_uid, '2026-04-04T08:30:00', @superuser_id,
     N'NTE', N'Notes Comment Result',
     '2026-04-04T08:30:00', @superuser_id, N'OBS20080021GA01',
     N'C_Result', N'C_Result',
     N'PROCESSED', '2026-04-04T08:30:00',
     N'A', '2026-04-04T08:30:00', @foundation_patient_uid,
     N'T', 1, N'STD', N'130001',
     20080010, N'Y',
     '2026-04-04T08:30:00');

-- =====================================================================
-- v2 followup observations (one per pivoted INV/MRB code).
-- These are consumed by the SP's pivot via tmp_MorbFrmQ -> joined to
-- nrt_observation_{coded,date,txt} on observation_uid. Each followup
-- observation carries a single `cd` value matching the SP's pivot list.
-- =====================================================================
INSERT INTO [dbo].[observation]
    ([observation_uid], [add_time], [add_user_id], [cd],
     [last_chg_time], [last_chg_user_id], [local_id],
     [obs_domain_cd_st_1], [obs_domain_cd],
     [record_status_cd], [record_status_time],
     [status_cd], [status_time], [subject_person_uid],
     [shared_ind], [version_ctrl_nbr])
VALUES
    (@dbo_Act_morb_v2_INV128, '2026-04-04T00:00:00', @superuser_id, N'INV128',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080100GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_INV145, '2026-04-04T00:00:00', @superuser_id, N'INV145',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080101GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_INV148, '2026-04-04T00:00:00', @superuser_id, N'INV148',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080102GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_INV149, '2026-04-04T00:00:00', @superuser_id, N'INV149',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080103GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_INV178, '2026-04-04T00:00:00', @superuser_id, N'INV178',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080104GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_MRB100, '2026-04-04T00:00:00', @superuser_id, N'MRB100',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080105GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_MRB102, '2026-04-04T00:00:00', @superuser_id, N'MRB102',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080106GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_MRB122, '2026-04-04T00:00:00', @superuser_id, N'MRB122',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080107GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_MRB129, '2026-04-04T00:00:00', @superuser_id, N'MRB129',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080108GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_MRB130, '2026-04-04T00:00:00', @superuser_id, N'MRB130',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080109GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_MRB161, '2026-04-04T00:00:00', @superuser_id, N'MRB161',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080110GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_MRB165, '2026-04-04T00:00:00', @superuser_id, N'MRB165',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080111GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_MRB166, '2026-04-04T00:00:00', @superuser_id, N'MRB166',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080112GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_MRB167, '2026-04-04T00:00:00', @superuser_id, N'MRB167',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080113GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_MRB168, '2026-04-04T00:00:00', @superuser_id, N'MRB168',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080114GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1),
    (@dbo_Act_morb_v2_MRB169, '2026-04-04T00:00:00', @superuser_id, N'MRB169',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20080115GA01',
     N'Result', N'Result',
     N'PROCESSED', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1);

-- =====================================================================
-- Morbidity-internal act_relationship rows: each followup observation
-- (Result-domain) -> v2 Morb Order (parent). These are Morb-internal —
-- both endpoints are Morb-fixture observations. type_cd='COMP' from
-- SRTE AR_TYPE.
-- The act_relationship rows give the event SP's parent_observations
-- JSON branch a non-empty array. Postprocessing SP does not require
-- act_relationship for the followup pivot — it joins on
-- nrt_observation.followup_observation_uid CSV instead.
-- =====================================================================
INSERT INTO [dbo].[act_relationship]
    ([source_act_uid], [target_act_uid], [type_cd], [add_time], [add_user_id],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [sequence_nbr], [source_class_cd],
     [target_class_cd], [status_cd], [status_time], [type_desc_txt])
VALUES
    -- C_Order / C_Result -> v2 Morb Order
    (@dbo_Act_morb_v2_corder_uid,  @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T08:00:00', @superuser_id, '2026-04-04T08:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T08:00:00', 1, N'OBS', N'OBS',
     N'A', '2026-04-04T08:00:00', N'Component'),
    (@dbo_Act_morb_v2_cresult_uid, @dbo_Act_morb_v2_corder_uid, N'COMP',
     '2026-04-04T08:30:00', @superuser_id, '2026-04-04T08:30:00',
     @superuser_id, N'ACTIVE', '2026-04-04T08:30:00', 1, N'OBS', N'OBS',
     N'A', '2026-04-04T08:30:00', N'Component'),
    -- INV/MRB followups -> v2 Morb Order
    (@dbo_Act_morb_v2_INV128, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 1, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_INV145, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 2, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_INV148, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 3, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_INV149, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 4, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_INV178, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 5, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_MRB100, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 6, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_MRB102, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 7, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_MRB122, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 8, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_MRB129, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 9, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_MRB130, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 10, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_MRB161, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 11, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_MRB165, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 12, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_MRB166, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 13, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_MRB167, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 14, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_MRB168, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 15, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component'),
    (@dbo_Act_morb_v2_MRB169, @dbo_Act_morb_v2_order_uid, N'COMP',
     '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00',
     @superuser_id, N'ACTIVE', '2026-04-04T00:00:00', 16, N'OBS', N'OBS',
     N'A', '2026-04-04T00:00:00', N'Component');

-- =====================================================================
-- v2 Morb Order act_id row.
-- =====================================================================
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@dbo_Act_morb_v2_order_uid, 1, '2026-04-04T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     '2026-04-04T00:00:00', @superuser_id, N'ACTIVE',
     '2026-04-04T00:00:00', N'OBS20080010GA01', N'OBS_LOCAL_ID',
     N'Local Observation Identifier', N'A', '2026-04-04T00:00:00');

-- =====================================================================
-- ODSE obs_value_* rows for the followups — feed the event SP's JSON
-- and provide ODSE-side shape consistency.
-- The Morb postprocessing SP reads from nrt_observation_{coded,date,txt}
-- (RDB_MODERN), not these ODSE rows directly, but the event SP would
-- pivot these in its JSON projection.
-- =====================================================================

-- Coded followups (INV128/INV145/INV148/INV149/INV178/MRB100/MRB129/MRB130/MRB161/MRB168)
INSERT INTO [dbo].[obs_value_coded]
    ([observation_uid], [code], [code_system_cd], [code_system_desc_txt],
     [display_name])
VALUES
    (@dbo_Act_morb_v2_INV128, N'Y', N'2.16.840.1.114222.4.5.232', N'YNU', N'Yes'),
    (@dbo_Act_morb_v2_INV145, N'N', N'2.16.840.1.114222.4.5.232', N'YNU', N'No'),
    (@dbo_Act_morb_v2_INV148, N'N', N'2.16.840.1.114222.4.5.232', N'YNU', N'No'),
    (@dbo_Act_morb_v2_INV149, N'N', N'2.16.840.1.114222.4.5.232', N'YNU', N'No'),
    (@dbo_Act_morb_v2_INV178, N'N', N'2.16.840.1.114222.4.5.232', N'YNU', N'No'),
    (@dbo_Act_morb_v2_MRB100, N'INIT', N'L', N'Local', N'Initial'),
    (@dbo_Act_morb_v2_MRB129, N'N', N'2.16.840.1.114222.4.5.232', N'YNU', N'No'),
    (@dbo_Act_morb_v2_MRB130, N'N', N'2.16.840.1.114222.4.5.232', N'YNU', N'No'),
    (@dbo_Act_morb_v2_MRB161, N'Web', N'L', N'Local', N'Web Entry'),
    (@dbo_Act_morb_v2_MRB168, N'N', N'2.16.840.1.114222.4.5.232', N'YNU', N'No');

-- Date followups (MRB122/MRB165/MRB166/MRB167)
INSERT INTO [dbo].[obs_value_date]
    ([observation_uid], [obs_value_date_seq], [from_time])
VALUES
    (@dbo_Act_morb_v2_MRB122, 1, '2026-03-25T00:00:00'),
    (@dbo_Act_morb_v2_MRB165, 1, '2026-03-30T00:00:00'),
    (@dbo_Act_morb_v2_MRB166, 1, '2026-03-31T00:00:00'),
    (@dbo_Act_morb_v2_MRB167, 1, '2026-04-02T00:00:00');

-- Txt followups (MRB102/MRB169) plus C_Result user comment
INSERT INTO [dbo].[obs_value_txt]
    ([observation_uid], [obs_value_txt_seq], [txt_type_cd], [value_txt])
VALUES
    (@dbo_Act_morb_v2_MRB102, 1, N'FT',
     N'Tier 1 Morbidity v2 — comments narrative text.'),
    (@dbo_Act_morb_v2_MRB169, 1, N'FT',
     N'Tier 1 Morbidity v2 — other-specify free-text.'),
    (@dbo_Act_morb_v2_cresult_uid, 1, N'N',
     N'Tier 1 Morbidity v2 — clinician user comment.');

GO

-- =====================================================================
-- DRIVE THE POSTPROCESSING SP via direct nrt_observation* INSERTs.
-- =====================================================================

USE [RDB_MODERN];
GO

-- Re-declare locals inside the RDB_MODERN batch (DECLAREs do not survive GO).
DECLARE @superuser_id bigint = 10009282;
DECLARE @foundation_act_morb_uid   bigint = 20000130;
DECLARE @foundation_patient_uid    bigint = 20000000;
DECLARE @foundation_provider_uid   bigint = 20000010;
DECLARE @foundation_org_uid        bigint = 20000020;
DECLARE @dbo_Act_morb_v2_order_uid    bigint = 20080010;
DECLARE @dbo_Act_morb_v2_corder_uid   bigint = 20080020;
DECLARE @dbo_Act_morb_v2_cresult_uid  bigint = 20080021;
DECLARE @dbo_Act_morb_v2_INV128       bigint = 20080100;
DECLARE @dbo_Act_morb_v2_INV145       bigint = 20080101;
DECLARE @dbo_Act_morb_v2_INV148       bigint = 20080102;
DECLARE @dbo_Act_morb_v2_INV149       bigint = 20080103;
DECLARE @dbo_Act_morb_v2_INV178       bigint = 20080104;
DECLARE @dbo_Act_morb_v2_MRB100       bigint = 20080105;
DECLARE @dbo_Act_morb_v2_MRB102       bigint = 20080106;
DECLARE @dbo_Act_morb_v2_MRB122       bigint = 20080107;
DECLARE @dbo_Act_morb_v2_MRB129       bigint = 20080108;
DECLARE @dbo_Act_morb_v2_MRB130       bigint = 20080109;
DECLARE @dbo_Act_morb_v2_MRB161       bigint = 20080110;
DECLARE @dbo_Act_morb_v2_MRB165       bigint = 20080111;
DECLARE @dbo_Act_morb_v2_MRB166       bigint = 20080112;
DECLARE @dbo_Act_morb_v2_MRB167       bigint = 20080113;
DECLARE @dbo_Act_morb_v2_MRB168       bigint = 20080114;
DECLARE @dbo_Act_morb_v2_MRB169       bigint = 20080115;

-- Build CSV of v2 followup observation UIDs. SP at lines 99-100 does
--   `CROSS APPLY string_split(rtrim(ltrim(followup_observation_uid)),',')`
-- on the parent Morb Order's nrt_observation row.
DECLARE @v2_followup_csv nvarchar(500) =
    CAST(@dbo_Act_morb_v2_corder_uid  AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_cresult_uid AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_INV128 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_INV145 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_INV148 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_INV149 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_INV178 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_MRB100 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_MRB102 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_MRB122 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_MRB129 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_MRB130 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_MRB161 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_MRB165 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_MRB166 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_MRB167 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_MRB168 AS varchar(20)) + ',' +
    CAST(@dbo_Act_morb_v2_MRB169 AS varchar(20));

-- =====================================================================
-- nrt_observation: 20 rows total.
--   - foundation Morb Order (20000130) — sparse / null-propagation
--     variant; ctrl_cd_display_form='MorbReport' so SP picks it up
--   - v2 Morb Order (20080010) — fully populated
--   - v2 C_Order (20080020), v2 C_Result (20080021)
--   - 16 followup observations (20080100..20080115) — Result-domain
-- refresh_datetime + max_datetime are GENERATED ALWAYS (omitted).
-- 83 settable columns, identical layout to lab.sql.
-- =====================================================================
INSERT INTO [dbo].[nrt_observation]
    ( [observation_uid], [class_cd], [mood_cd], [act_uid]                                  -- 01-04
    , [cd_desc_txt], [record_status_cd], [jurisdiction_cd]                                 -- 05-07
    , [program_jurisdiction_oid], [prog_area_cd], [pregnant_ind_cd]                        -- 08-10
    , [local_id], [activity_to_time], [effective_from_time]                                -- 11-13
    , [rpt_to_state_time], [electronic_ind], [version_ctrl_nbr]                            -- 14-16
    , [ordering_person_id], [patient_id], [result_observation_uid]                         -- 17-19
    , [author_organization_id], [ordering_organization_id]                                 -- 20-21
    , [performing_organization_id], [material_id], [obs_domain_cd_st_1]                    -- 22-24
    , [processing_decision_cd], [cd], [shared_ind]                                         -- 25-27
    , [add_user_id], [add_user_name], [add_time]                                           -- 28-30
    , [last_chg_user_id], [last_chg_user_name], [last_chg_time]                            -- 31-33
    , [ctrl_cd_display_form], [status_cd], [cd_system_cd]                                  -- 34-36
    , [cd_system_desc_txt], [ctrl_cd_user_defined_1], [alt_cd]                             -- 37-39
    , [alt_cd_desc_txt], [alt_cd_system_cd], [alt_cd_system_desc_txt]                      -- 40-42
    , [method_cd], [method_desc_txt], [target_site_cd]                                     -- 43-45
    , [target_site_desc_txt], [txt], [interpretation_cd]                                   -- 46-48
    , [interpretation_desc_txt], [report_observation_uid]                                  -- 49-50
    , [followup_observation_uid], [report_refr_uid], [report_sprt_uid]                     -- 51-53
    , [morb_physician_id], [morb_reporter_id], [transcriptionist_id]                       -- 54-56
    , [transcriptionist_val], [transcriptionist_first_nm]                                  -- 57-58
    , [transcriptionist_last_nm], [assistant_interpreter_id]                               -- 59-60
    , [assistant_interpreter_val], [assistant_interpreter_first_nm]                        -- 61-62
    , [assistant_interpreter_last_nm], [result_interpreter_id]                             -- 63-64
    , [specimen_collector_id], [copy_to_provider_id]                                       -- 65-66
    , [lab_test_technician_id], [health_care_id], [morb_hosp_reporter_id]                  -- 67-69
    , [accession_number], [morb_hosp_id]                                                   -- 70-71
    , [transcriptionist_id_assign_auth]                                                    -- 72
    , [transcriptionist_auth_type], [assistant_interpreter_id_assign_auth]                 -- 73-74
    , [assistant_interpreter_auth_type], [priority_cd]                                     -- 75-76
    , [record_status_time], [status_time], [batch_id]                                      -- 77-79
    , [associated_phc_uids], [activity_from_time]                                          -- 80-81
    , [device_instance_id_1], [device_instance_id_2]                                       -- 82-83
    )
VALUES
    -- ---------------------------------------------------------------
    -- Row 1. Foundation Morbidity Order (UID 20000130) — sparse / null-propagation variant.
    -- ctrl_cd_display_form='MorbReport' to pass the SP's filter.
    -- No followup observations attached -> the SP's MorbFrmQ pivots
    -- produce empty pivot tables for this row, exhibiting the
    -- "no followup data" path.
    -- ---------------------------------------------------------------
    ( @foundation_act_morb_uid, N'OBS', N'EVN', @foundation_act_morb_uid                   -- 01-04
    , N'Foundation morbidity report', N'PROCESSED', N'1'                                   -- 05-07
    , NULL, N'STD', NULL                                                                   -- 08-10
    , N'OBS20000130GA01', NULL, NULL                                                       -- 11-13
    , NULL, N'N', 1                                                                        -- 14-16
    , NULL, @foundation_patient_uid, NULL                                                  -- 17-19
    , NULL, NULL                                                                           -- 20-21
    , NULL, NULL, N'Order'                                                                 -- 22-24
    , NULL, N'MOR100', N'F'                                                                -- 25-27
    , @superuser_id, N'Foundation, Superuser', '2026-04-01T00:00:00'                       -- 28-30
    , @superuser_id, N'Foundation, Superuser', '2026-04-01T00:00:00'                       -- 31-33
    , N'MorbReport', N'A', NULL                                                            -- 34-36
    , NULL, NULL, NULL                                                                     -- 37-39
    , NULL, NULL, NULL                                                                     -- 40-42
    , NULL, NULL, NULL                                                                     -- 43-45
    , NULL, NULL, NULL                                                                     -- 46-48
    , NULL, NULL                                                                           -- 49-50
    , NULL, NULL, NULL                                                                     -- 51-53
    , NULL, NULL, NULL                                                                     -- 54-56
    , NULL, NULL                                                                           -- 57-58
    , NULL, NULL                                                                           -- 59-60
    , NULL, NULL                                                                           -- 61-62
    , NULL, NULL                                                                           -- 63-64
    , NULL, NULL                                                                           -- 65-66
    , NULL, NULL, NULL                                                                     -- 67-69
    , NULL, NULL                                                                           -- 70-71
    , NULL                                                                                 -- 72
    , NULL, NULL                                                                           -- 73-74
    , NULL, NULL                                                                           -- 75-76
    , '2026-04-01T00:00:00', '2026-04-01T00:00:00', NULL                                   -- 77-79
    , NULL, NULL                                                                           -- 80-81
    , NULL, NULL                                                                           -- 82-83
    ),
    -- ---------------------------------------------------------------
    -- Row 2. v2 Morbidity Order (UID 20080010) — fully populated.
    -- ---------------------------------------------------------------
    ( @dbo_Act_morb_v2_order_uid, N'OBS', N'EVN', @dbo_Act_morb_v2_order_uid               -- 01-04
    , N'Hepatitis A, acute', N'PROCESSED', N'130001'                                       -- 05-07
    , 20080010, N'STD', N'N'                                                               -- 08-10
    , N'OBS20080010GA01', '2026-04-04T08:00:00', '2026-04-03T18:00:00'                     -- 11-13
    , '2026-04-04T10:00:00', N'Y', 1                                                       -- 14-16
    , CAST(@foundation_provider_uid AS nvarchar(50)), @foundation_patient_uid, NULL        -- 17-19
    , @foundation_org_uid, @foundation_org_uid                                             -- 20-21
    , @foundation_org_uid, NULL, N'Order'                                                  -- 22-24
    , N'AC', N'10110', N'T'                                                                -- 25-27
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'                       -- 28-30
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'                       -- 31-33
    , N'MorbReport', N'A', N'2.16.840.1.114222.4.5.277'                                    -- 34-36
    , N'PHIN_CONDITION', N'UDV1', N'HEP-A-ACUTE'                                           -- 37-39
    , N'Hepatitis A acute', N'L', N'Local'                                                 -- 40-42
    , NULL, NULL, N'WBLD'                                                                  -- 43-45
    , N'Whole blood', N'Tier 1 v2 Morbidity narrative.', NULL                              -- 46-48
    , NULL, NULL                                                                           -- 49-50
    , @v2_followup_csv, NULL, NULL                                                         -- 51-53
    , @foundation_provider_uid, @foundation_provider_uid, NULL                             -- 54-56
    , NULL, NULL                                                                           -- 57-58
    , NULL, NULL                                                                           -- 59-60
    , NULL, NULL                                                                           -- 61-62
    , NULL, NULL                                                                           -- 63-64
    , NULL, NULL                                                                           -- 65-66
    , NULL, @foundation_org_uid, @foundation_org_uid                                       -- 67-69
    , N'MOR-V2-20080010', @foundation_org_uid                                              -- 70-71
    , NULL                                                                                 -- 72
    , NULL, NULL                                                                           -- 73-74
    , NULL, N'R'                                                                           -- 75-76
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL                                   -- 77-79
    , NULL, '2026-04-03T18:00:00'                                                          -- 80-81
    , NULL, NULL                                                                           -- 82-83
    ),
    -- ---------------------------------------------------------------
    -- Row 3. v2 C_Order (UID 20080020). Reached via followup CSV.
    -- ---------------------------------------------------------------
    ( @dbo_Act_morb_v2_corder_uid, N'OBS', N'EVN', @dbo_Act_morb_v2_corder_uid             -- 01-04
    , N'Notes Comment Order', N'PROCESSED', N'130001'                                      -- 05-07
    , 20080010, N'STD', NULL                                                               -- 08-10
    , N'OBS20080020GA01', '2026-04-04T08:00:00', NULL                                      -- 11-13
    , NULL, N'Y', 1                                                                        -- 14-16
    , NULL, @foundation_patient_uid, NULL                                                  -- 17-19
    , NULL, NULL                                                                           -- 20-21
    , NULL, NULL, N'C_Order'                                                               -- 22-24
    , NULL, N'NTE', N'T'                                                                   -- 25-27
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T08:00:00'                       -- 28-30
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T08:00:00'                       -- 31-33
    , NULL, N'A', NULL                                                                     -- 34-36
    , NULL, NULL, NULL                                                                     -- 37-39
    , NULL, NULL, NULL                                                                     -- 40-42
    , NULL, NULL, NULL                                                                     -- 43-45
    , NULL, NULL, NULL                                                                     -- 46-48
    , NULL, @dbo_Act_morb_v2_order_uid                                                     -- 49-50
    , NULL, NULL, NULL                                                                     -- 51-53
    , NULL, NULL, NULL                                                                     -- 54-56
    , NULL, NULL                                                                           -- 57-58
    , NULL, NULL                                                                           -- 59-60
    , NULL, NULL                                                                           -- 61-62
    , NULL, NULL                                                                           -- 63-64
    , NULL, NULL                                                                           -- 65-66
    , NULL, NULL, NULL                                                                     -- 67-69
    , NULL, NULL                                                                           -- 70-71
    , NULL                                                                                 -- 72
    , NULL, NULL                                                                           -- 73-74
    , NULL, NULL                                                                           -- 75-76
    , '2026-04-04T08:00:00', '2026-04-04T08:00:00', NULL                                   -- 77-79
    , NULL, NULL                                                                           -- 80-81
    , NULL, NULL                                                                           -- 82-83
    ),
    -- ---------------------------------------------------------------
    -- Row 4. v2 C_Result (UID 20080021). Carries user-comment txt.
    -- ---------------------------------------------------------------
    ( @dbo_Act_morb_v2_cresult_uid, N'OBS', N'EVN', @dbo_Act_morb_v2_cresult_uid           -- 01-04
    , N'Notes Comment Result', N'PROCESSED', N'130001'                                     -- 05-07
    , 20080010, N'STD', NULL                                                               -- 08-10
    , N'OBS20080021GA01', '2026-04-04T08:30:00', NULL                                      -- 11-13
    , NULL, N'Y', 1                                                                        -- 14-16
    , NULL, @foundation_patient_uid, NULL                                                  -- 17-19
    , NULL, NULL                                                                           -- 20-21
    , NULL, NULL, N'C_Result'                                                              -- 22-24
    , NULL, N'NTE', N'T'                                                                   -- 25-27
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T08:30:00'                       -- 28-30
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T08:30:00'                       -- 31-33
    , NULL, N'A', NULL                                                                     -- 34-36
    , NULL, NULL, NULL                                                                     -- 37-39
    , NULL, NULL, NULL                                                                     -- 40-42
    , NULL, NULL, NULL                                                                     -- 43-45
    , NULL, NULL, NULL                                                                     -- 46-48
    , NULL, @dbo_Act_morb_v2_corder_uid                                                    -- 49-50
    , NULL, NULL, NULL                                                                     -- 51-53
    , NULL, NULL, NULL                                                                     -- 54-56
    , NULL, NULL                                                                           -- 57-58
    , NULL, NULL                                                                           -- 59-60
    , NULL, NULL                                                                           -- 61-62
    , NULL, NULL                                                                           -- 63-64
    , NULL, NULL                                                                           -- 65-66
    , NULL, NULL, NULL                                                                     -- 67-69
    , NULL, NULL                                                                           -- 70-71
    , NULL                                                                                 -- 72
    , NULL, NULL                                                                           -- 73-74
    , NULL, NULL                                                                           -- 75-76
    , '2026-04-04T08:30:00', '2026-04-04T08:30:00', NULL                                   -- 77-79
    , NULL, NULL                                                                           -- 80-81
    , NULL, NULL                                                                           -- 82-83
    ),
    -- ---------------------------------------------------------------
    -- Rows 5-20. Sixteen INV/MRB followup observations. Each row carries
    -- a single `cd` matching the SP's pivot list. Result-domain;
    -- minimal columns set since the SP only reads `cd` + the obs join +
    -- the value table.
    -- ---------------------------------------------------------------
    ( @dbo_Act_morb_v2_INV128, N'OBS', N'EVN', @dbo_Act_morb_v2_INV128
    , N'INV128', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080100GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'INV128', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_INV145, N'OBS', N'EVN', @dbo_Act_morb_v2_INV145
    , N'INV145', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080101GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'INV145', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_INV148, N'OBS', N'EVN', @dbo_Act_morb_v2_INV148
    , N'INV148', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080102GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'INV148', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_INV149, N'OBS', N'EVN', @dbo_Act_morb_v2_INV149
    , N'INV149', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080103GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'INV149', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_INV178, N'OBS', N'EVN', @dbo_Act_morb_v2_INV178
    , N'INV178', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080104GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'INV178', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_MRB100, N'OBS', N'EVN', @dbo_Act_morb_v2_MRB100
    , N'MRB100', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080105GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'MRB100', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_MRB102, N'OBS', N'EVN', @dbo_Act_morb_v2_MRB102
    , N'MRB102', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080106GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'MRB102', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_MRB122, N'OBS', N'EVN', @dbo_Act_morb_v2_MRB122
    , N'MRB122', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080107GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'MRB122', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_MRB129, N'OBS', N'EVN', @dbo_Act_morb_v2_MRB129
    , N'MRB129', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080108GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'MRB129', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_MRB130, N'OBS', N'EVN', @dbo_Act_morb_v2_MRB130
    , N'MRB130', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080109GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'MRB130', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_MRB161, N'OBS', N'EVN', @dbo_Act_morb_v2_MRB161
    , N'MRB161', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080110GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'MRB161', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_MRB165, N'OBS', N'EVN', @dbo_Act_morb_v2_MRB165
    , N'MRB165', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080111GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'MRB165', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_MRB166, N'OBS', N'EVN', @dbo_Act_morb_v2_MRB166
    , N'MRB166', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080112GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'MRB166', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_MRB167, N'OBS', N'EVN', @dbo_Act_morb_v2_MRB167
    , N'MRB167', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080113GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'MRB167', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_MRB168, N'OBS', N'EVN', @dbo_Act_morb_v2_MRB168
    , N'MRB168', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080114GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'MRB168', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    ),
    ( @dbo_Act_morb_v2_MRB169, N'OBS', N'EVN', @dbo_Act_morb_v2_MRB169
    , N'MRB169', N'PROCESSED', N'130001'
    , NULL, N'STD', NULL
    , N'OBS20080115GA01', NULL, NULL
    , NULL, N'Y', 1
    , NULL, @foundation_patient_uid, NULL
    , NULL, NULL
    , NULL, NULL, N'Result'
    , NULL, N'MRB169', N'T'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'
    , NULL, N'A', NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, @dbo_Act_morb_v2_order_uid
    , NULL, NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL
    , NULL, NULL, NULL
    , NULL, NULL
    , NULL
    , NULL, NULL
    , NULL, NULL
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL
    , NULL, NULL
    , NULL, NULL
    );

-- =====================================================================
-- nrt_observation_coded — coded values for the coded MRB/INV followups.
-- =====================================================================
INSERT INTO [dbo].[nrt_observation_coded]
    ([observation_uid], [ovc_code], [ovc_code_system_cd],
     [ovc_code_system_desc_txt], [ovc_display_name],
     [ovc_alt_cd], [ovc_alt_cd_desc_txt], [ovc_alt_cd_system_cd],
     [ovc_alt_cd_system_desc_txt], [batch_id])
VALUES
    (@dbo_Act_morb_v2_INV128, N'Y',    N'2.16.840.1.114222.4.5.232', N'YNU', N'Yes', NULL, NULL, NULL, NULL, NULL),
    (@dbo_Act_morb_v2_INV145, N'N',    N'2.16.840.1.114222.4.5.232', N'YNU', N'No',  NULL, NULL, NULL, NULL, NULL),
    (@dbo_Act_morb_v2_INV148, N'N',    N'2.16.840.1.114222.4.5.232', N'YNU', N'No',  NULL, NULL, NULL, NULL, NULL),
    (@dbo_Act_morb_v2_INV149, N'N',    N'2.16.840.1.114222.4.5.232', N'YNU', N'No',  NULL, NULL, NULL, NULL, NULL),
    (@dbo_Act_morb_v2_INV178, N'N',    N'2.16.840.1.114222.4.5.232', N'YNU', N'No',  NULL, NULL, NULL, NULL, NULL),
    (@dbo_Act_morb_v2_MRB100, N'INIT', N'L',                         N'Local', N'Initial', NULL, NULL, NULL, NULL, NULL),
    (@dbo_Act_morb_v2_MRB129, N'N',    N'2.16.840.1.114222.4.5.232', N'YNU', N'No',  NULL, NULL, NULL, NULL, NULL),
    (@dbo_Act_morb_v2_MRB130, N'N',    N'2.16.840.1.114222.4.5.232', N'YNU', N'No',  NULL, NULL, NULL, NULL, NULL),
    (@dbo_Act_morb_v2_MRB161, N'Web',  N'L',                         N'Local', N'Web Entry', NULL, NULL, NULL, NULL, NULL),
    (@dbo_Act_morb_v2_MRB168, N'N',    N'2.16.840.1.114222.4.5.232', N'YNU', N'No',  NULL, NULL, NULL, NULL, NULL);

-- =====================================================================
-- nrt_observation_date — date values for the date MRB followups.
-- =====================================================================
INSERT INTO [dbo].[nrt_observation_date]
    ([observation_uid], [ovd_from_date], [ovd_to_date], [ovd_seq], [batch_id])
VALUES
    (@dbo_Act_morb_v2_MRB122, '2026-03-25T00:00:00', '2026-03-25T00:00:00', 1, NULL),
    (@dbo_Act_morb_v2_MRB165, '2026-03-30T00:00:00', '2026-03-30T00:00:00', 1, NULL),
    (@dbo_Act_morb_v2_MRB166, '2026-03-31T00:00:00', '2026-03-31T00:00:00', 1, NULL),
    (@dbo_Act_morb_v2_MRB167, '2026-04-02T00:00:00', '2026-04-02T00:00:00', 1, NULL);

-- =====================================================================
-- nrt_observation_txt — text values for the txt MRB followups + the
-- C_Result user-comment text.
-- ovt_txt_type_cd 'N' on C_Result drives MORB_RPT_USER_COMMENT.
-- ovt_txt_type_cd 'FT' on MRB102/MRB169 drives the pivot's value_txt.
-- =====================================================================
INSERT INTO [dbo].[nrt_observation_txt]
    ([observation_uid], [ovt_seq], [ovt_txt_type_cd], [ovt_value_txt], [batch_id])
VALUES
    (@dbo_Act_morb_v2_MRB102, 1, N'FT',
     N'Tier 1 Morbidity v2 — comments narrative text.', NULL),
    (@dbo_Act_morb_v2_MRB169, 1, N'FT',
     N'Tier 1 Morbidity v2 — other-specify free-text.', NULL),
    (@dbo_Act_morb_v2_cresult_uid, 1, N'N',
     N'Tier 1 Morbidity v2 — clinician user comment.', NULL);

GO
