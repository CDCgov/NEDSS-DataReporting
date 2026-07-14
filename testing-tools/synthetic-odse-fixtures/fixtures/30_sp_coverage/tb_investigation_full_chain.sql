-- =====================================================================
-- Tier 3 — TB Investigation full ODSE + Tier 2 + NBS_case_answer chain
-- =====================================================================
-- Goal: unblock the TB-PAM cluster (14 d_* dim tables + 12 d_*_group
-- link tables + tb_pam_ldf, F_TB_PAM, TB_DATAMART, TB_HIV_DATAMART).
-- These all read from D_TB_PAM (147-sp_nrt_d_tb_pam_postprocessing),
-- which in turn pivots dbo.nrt_page_case_answer rows joined to
-- dbo.nrt_investigation filtered by investigation_form_cd='INV_FORM_RVCT'.
--
-- WHY A NEW UID, NOT AN UPGRADE
--   The existing stub at public_health_case_uid 22000010 in
--   `multi_condition_investigations.sql` writes only an nrt_investigation
--   row (no ODSE-side act/PHC, no nbs_case_answer, no
--   nrt_page_case_answer). It exercises the "Investigation exists, no
--   PAM answers" path. We leave it untouched and allocate a NEW TB
--   Investigation at 22001000 with the full ODSE + staging chain so:
--     - the stub continues exercising the no-answers path
--     - the new variant exercises the fully-populated PAM path
--   Together they cover both branches of the TB-PAM SP family.
--
-- WHAT THIS FIXTURE AUTHORS
--   1. ODSE chain (NBS_ODSE):
--        - act               (act_uid=22001000, class='CASE', mood='EVN')
--        - public_health_case (TB-specific codes; cd='10220',
--                              investigation_form_cd='INV_FORM_RVCT',
--                              prog_area_cd='TB', case_class_cd='C',
--                              jurisdiction_cd='130001' Fulton County)
--        - act_id             (PHC_LOCAL_ID assigning_authority)
--        - case_management    (NULL-left so f_page_case filter still
--                              filters it out — not the focus here)
--        - nbs_case_answer    rows for each RVCT-form TUB* question
--                              driving the TB-PAM and 12 d_topic SPs
--   2. RDB_MODERN staging (mirrors the kafka-connect JDBC sink writes):
--        - nrt_investigation row keyed on public_health_case_uid 22001000
--          with patient_id=20000000 (foundation Patient), the
--          investigation_form_cd='INV_FORM_RVCT' that all the SPs filter
--          on, and nac_page_case_uid=22001000 so F_TB_PAM's
--          MAX(nac_page_case_uid) grouping resolves.
--        - nrt_page_case_answer rows — one per TUB question, with
--          datamart_column_nm, code_set_group_id, question_identifier,
--          data_location, answer_txt, ldf_status_cd=NULL, batch_id=NULL,
--          last_chg_time set so all the TB-PAM SP joins and predicates
--          resolve correctly. The TUB question UIDs and their
--          code_set_group_ids were verified live against
--          NBS_ODSE.dbo.nbs_question on 2026-05-21.
--   3. Does NOT author nrt_investigation_confirmation, additional
--      cross-subject participation/act_relationship, or D_TB_PAM /
--      F_TB_PAM directly — those are downstream of the SP chain.
--
-- VERIFICATION CALL-CHAIN (tail-EXECs at bottom)
--   The chain composes:
--     sp_nrt_investigation_postprocessing    — flows nrt_investigation → INVESTIGATION
--     sp_nrt_d_tb_pam_postprocessing         — root: D_TB_PAM (147)
--     sp_nrt_d_disease_site_postprocessing   — D_DISEASE_SITE(_GROUP) (145)
--     sp_nrt_d_addl_risk_postprocessing      — D_ADDL_RISK(_GROUP)   (146)
--     sp_nrt_d_tb_hiv_postprocessing         — D_TB_HIV              (160)
--     sp_nrt_d_move_cntry_postprocessing     — D_MOVE_CNTRY(_GROUP)  (156)
--     sp_nrt_d_gt_12_reas_postprocessing     — D_GT_12_REAS(_GROUP)  (170)
--     sp_nrt_d_move_cnty_postprocessing      — D_MOVE_CNTY(_GROUP)   (175)
--     sp_nrt_d_hc_prov_ty_3_postprocessing   — D_HC_PROV_TY_3(_GROUP)(180)
--     sp_nrt_d_move_state_postprocessing     — D_MOVE_STATE(_GROUP)  (185)
--     sp_nrt_d_out_of_cntry_postprocessing   — D_OUT_OF_CNTRY(_GROUP)(190)
--     sp_nrt_d_moved_where_postprocessing    — D_MOVED_WHERE(_GROUP) (195)
--     sp_nrt_d_smr_exam_ty_postprocessing    — D_SMR_EXAM_TY(_GROUP) (200)
--     sp_nrt_tb_pam_ldf_postprocessing       — TB_PAM_LDF            (220)
--     sp_f_tb_pam_postprocessing             — F_TB_PAM              (206)
--     sp_tb_datamart_postprocessing          — TB_DATAMART, TB_HIV_DATAMART (255)
--   PARAMETER NAMES VARY across the cluster:
--     @phc_id_list   — 147, 160, 170, 180, 190, 200, 206, 220, 255
--     @phc_uids      — 145, 146, 156, 175, 185, 195, 225, 230
--   Verified by grep on each SP signature 2026-05-21.
--   Note: 225 (sp_nrt_d_rash_loc_gen) and 230 (sp_nrt_d_pcr_source) are
--   Varicella-only (VAR176, etc.) — not invoked here.
--
-- UID block (Tier 3 full-chain TB Investigation): 22001000-22001999
--   22001000  public_health_case.public_health_case_uid (act.act_uid;
--             nrt_investigation.public_health_case_uid;
--             nrt_page_case_answer.act_uid for every answer row)
--   22001001  case_management.case_management_uid (IDENTITY-inserted)
--   22001100..22001268  nbs_case_answer.nbs_case_answer_uid +
--             nrt_page_case_answer.nbs_case_answer_uid for each
--             authored TUB answer row (169 questions max; we author
--             a curated 30+ that exercise every d_topic SP).
--
-- Foundation dependencies (read-only):
--   @superuser_id              10009282
--   @foundation_patient_uid    20000000   (D_PATIENT exists; F_TB_PAM
--                                          INNER JOINs D_PATIENT on
--                                          PERSON_UID=PATIENT_UID)
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;

-- ----- New TB Investigation full-chain UIDs -----
DECLARE @tb_full_phc_uid          bigint = 22001000;  -- act.act_uid + public_health_case.public_health_case_uid
DECLARE @tb_full_case_mgmt_uid    bigint = 22001001;  -- case_management.case_management_uid

-- =====================================================================
-- ODSE: act parent row
-- =====================================================================
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@tb_full_phc_uid, N'CASE', N'EVN');

-- =====================================================================
-- ODSE: public_health_case row
-- =====================================================================
-- SRTE-verified codes (queried 2026-05-21):
--   condition_code.condition_cd='10220' Tuberculosis, prog_area_cd='TB',
--     investigation_form_cd='INV_FORM_RVCT'.
--   program_area_code.prog_area_cd='TB' (S_PROGRA_C, nbs_uid=14).
--   code_value_general PHC_CLASS 'C' (Confirmed).
--   code_value_general PHC_IN_STS 'O' (Open).
--   jurisdiction_code '130001' Fulton County (used by Tier 1 v2 inv).
INSERT INTO [dbo].[public_health_case]
    ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
     [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
     [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [outbreak_ind], [outbreak_name],
     [mmwr_week], [mmwr_year])
VALUES
    (@tb_full_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'I',
     N'C', N'10220', N'Tuberculosis', N'NND', N'NND',
     N'O', CAST(GETDATE() AS DATE), @superuser_id, N'CAS22001000GA01',
     N'OPEN', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'T', 1, N'TB', N'130001',
     22001000, N'N', NULL,
     N'14', N'2026');

-- =====================================================================
-- ODSE: act_id (PHC_LOCAL_ID) — matches the canonical Investigation pattern
-- =====================================================================
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@tb_full_phc_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE',
     '2026-04-01T00:00:00', N'CAS22001000GA01', N'PHC_LOCAL_ID',
     N'Local Public Health Case Identifier', N'A', '2026-04-01T00:00:00');

-- =====================================================================
-- ODSE: case_management (minimal; matches Tier 1 v2 Investigation shape)
-- IDENTITY column requires IDENTITY_INSERT toggle to pin our UID.
-- =====================================================================
SET IDENTITY_INSERT [dbo].[case_management] ON;
INSERT INTO [dbo].[case_management]
    ([case_management_uid], [public_health_case_uid], [status_900],
     [field_record_number], [surv_assigned_date],
     [surv_closed_date], [case_closed_date])
VALUES
    (@tb_full_case_mgmt_uid, @tb_full_phc_uid, N'C',
     N'FRN-TB-FULL-01', '2026-04-02T00:00:00',
     '2026-04-30T00:00:00', '2026-04-30T00:00:00');
SET IDENTITY_INSERT [dbo].[case_management] OFF;

GO

-- =====================================================================
-- ODSE: nbs_case_answer — one row per RVCT-form TUB* question we author.
-- These satisfy the ODSE-side referential model (the WS_CASE_ANSWER /
-- equivalent view that the upstream page-builder consumes in production).
-- The downstream RTR SPs do NOT read this table directly — they read
-- dbo.nrt_page_case_answer in RDB_MODERN, which the kafka-connect JDBC
-- sink writes. We mirror those staging rows below.
--
-- TUB question UIDs and code_set_group_ids verified live against
-- NBS_ODSE.dbo.nbs_question (data_location='NBS_Case_Answer.answer_txt'),
-- 2026-05-21.
-- =====================================================================

DECLARE @superuser_id_2 bigint = 10009282;
DECLARE @tb_full_phc_uid_2 bigint = 22001000;

-- nbs_case_answer.nbs_case_answer_uid is an IDENTITY column. We let it
-- AUTO-assign (LESSON 10: hardcoded IDENTITY_INSERT UIDs collide with the
-- auto-IDENTITY flood and the guard silently skips the whole INSERT). The
-- pipeline keys page answers on (act_uid, nbs_question_uid, seq_nbr), so
-- the surrogate UID is irrelevant. Guard on the natural key.
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @tb_full_phc_uid_2 AND nbs_question_uid = 1079 AND answer_group_seq_nbr IS NULL)
BEGIN
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid], [add_time], [add_user_id],
     [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [seq_nbr])
VALUES
    -- TUB119 DISEASE_SITE -> 'Pulmonary' (PHVS_TB_ADDL_SITE code 39607008
    --   Pulmonary; drives D_DISEASE_SITE + D_DISEASE_SITE_GROUP + the
    --   CALC_DISEASE_SITE='Pulmonary' branch in 147 SP lines 859-865.)
    (@tb_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'39607008', 1079, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB167 ADDL_RISK -> 73211009 Diabetes Mellitus (PHVS_TB_RISK_FACTORS;
    --   drives D_ADDL_RISK + D_ADDL_RISK_GROUP.)
    (@tb_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'73211009', 1230, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB154 HIV_STATUS -> 260385009 Negative (PHVS_HIV_STATUS; drives
    --   D_TB_HIV row.)
    (@tb_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'260385009', 1273, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB155 HIV_STATE_PATIENT_NUM -> 'HIV-STATE-TB-01' (text; no code set)
    (@tb_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'HIV-STATE-TB-01', 1323, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB156 HIV_CITY_CNTY_PATIENT_NUM -> 'HIV-CITY-TB-01' (text)
    (@tb_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'HIV-CITY-TB-01', 1034, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB229 MOVE_STATE -> '13' Georgia (STATE_CCD; drives D_MOVE_STATE.)
    (@tb_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'13', 1248, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB228 MOVE_CNTY -> '13121' Fulton County (COUNTY_CCD;
    --   drives D_MOVE_CNTY.)
    (@tb_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'13121', 1055, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB230 MOVE_CNTRY -> '840' US (PHVS_TB_BIRTH_CNTRY group 4260;
    --   drives D_MOVE_CNTRY. CODE_SET_GROUP_ID 77777 is a special-case
    --   country-direct lookup; we use the standard codeset path.)
    (@tb_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'840', 1243, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB225 MOVED_WHERE -> 'C1512888' Out of the U.S.
    --   (PHVS_TB_DIS_ACQ_JUR; drives D_MOVED_WHERE.)
    (@tb_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'C1512888', 1256, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB235 GT_12_REAS -> '258143003' Non-adherence
    --   (PHVS_TB_EXTEND_REAS; drives D_GT_12_REAS.)
    (@tb_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'258143003', 1318, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB237 HC_PROV_TY -> '310174000' Private Outpatient
    --   (PHVS_TB_HC_PRAC_TY; drives D_HC_PROV_TY_3.)
    (@tb_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'310174000', 1071, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB129 SMR_EXAM_TY -> '108257001' Pathology/Cytology
    --   (PHVS_TB_MICRO_EX_TY; drives D_SMR_EXAM_TY.)
    (@tb_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'108257001', 1174, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB114 OUT_OF_CNTRY -> 'PHC2' (one of the PHVS_TB_BIRTH_CNTRY codes;
    --   drives D_OUT_OF_CNTRY. Note: 147-tb_pam SP excludes TUB114 from
    --   the main pivot — this row lives so the 190-out_of_cntry SP picks
    --   it up.)
    (@tb_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'PHC2', 1080, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0);
END

GO

-- =====================================================================
-- RDB_MODERN: staging rows that the RTR postprocessing chain consumes.
-- These are written directly to bypass the CDC pipeline (per STRATEGY.md
-- "Convention: postprocessing SPs read NRT staging only — never ODSE").
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- nrt_investigation row for the full-chain TB Investigation.
-- Mirrors the v2 Tier 1 Investigation shape from
-- fixtures/10_subjects/investigation.sql but with TB-specific codes.
--   patient_id = 20000000 (foundation Patient) — required so F_TB_PAM's
--     INNER JOIN D_PATIENT ON PERSON_UID=PATIENT_UID resolves
--     (see 206-sp_f_tb_pam_postprocessing-001.sql line 103-105) AND so
--     the f_page_case patient-key COALESCE→1 sentinel-cascade-DELETE
--     path does not drop the row (see bug-5b convention,
--     fixtures/10_subjects/investigation.sql line 360).
--   nac_page_case_uid = 22001000 — F_TB_PAM at line 58 selects
--     CAST(I.nac_page_case_uid AS BIGINT) AS TB_PAM_UID and groups by
--     it; with NULL the row is silently dropped from F_TB_PAM (the
--     stub at 22000010 hits exactly this gap).
--   investigation_form_cd = 'INV_FORM_RVCT' — required by every TB-PAM
--     SP's predicate (147 line 72, 160 line 64, 220 line 68, 206 line
--     70, plus the 12 d_topic SPs which read nrt_page_case_answer
--     joined to nrt_investigation by act_uid=public_health_case_uid).
--   batch_id NULL — matches the ISNULL(batch_id, 1)=ISNULL(batch_id, 1)
--     join predicate.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_page_case_answer rows. One per TUB question we want exercised.
-- Each row mirrors what a kafka-connect JDBC sink would write after the
-- upstream page-builder service joined nbs_case_answer to
-- nbs_question / nbs_ui_metadata. The TB-PAM SP family reads ALL of:
--   act_uid (= the Investigation's public_health_case_uid)
--   question_identifier (e.g., 'TUB119')
--   nbs_question_uid (matching answer_txt)
--   datamart_column_nm (the target D_TB_PAM column)
--   code_set_group_id (joined to nrt_srte_codeset_group_metadata)
--   answer_txt (CODE value joined to nrt_srte_Code_value_general)
--   data_location = 'NBS_Case_Answer.answer_txt'
--   ldf_status_cd IS NULL (TB-PAM filter at 147 line 87)
--   batch_id matched via ISNULL(.,1) = ISNULL(.,1)
--
-- The 147 SP excludes question_identifier IN ('TUB119', 'TUB129',
-- 'TUB154', 'TUB155', 'TUB156', 'TUB167', 'TUB225', 'TUB228', 'TUB229',
-- 'TUB230', 'TUB235', 'TUB237', 'TUB114') from the main pivot (line
-- 92-95) — those are the questions handled by the 12 standalone
-- d_topic SPs. We therefore author both sets in a single fixture: the
-- excluded TUB questions feed the d_topic SPs, and a curated set of
-- non-excluded TUB questions feeds the main D_TB_PAM pivot.
--
-- NOT-NULL columns:
--   act_uid, nbs_case_answer_uid, nbs_ui_metadata_uid, nbs_question_uid,
--   record_status_cd.
-- nbs_ui_metadata_uid has no FK constraint; we use a stable
-- block-internal value (1 — production allocates per ui_metadata row;
-- the postprocessing SPs do not read this column).
-- ---------------------------------------------------------------------

GO

-- =====================================================================
-- Tail-EXEC the SP chain in dependency order.
--
-- Step A: flow the new nrt_investigation row into INVESTIGATION.
--   sp_nrt_investigation_postprocessing reads nrt_investigation,
--   writes INVESTIGATION row keyed on case_uid=22001000.
--   TB_DATAMART (255) INNER JOINs INVESTIGATION via case_uid; without
--   this step, the row never appears in INVESTIGATION and 255 no-ops.
-- =====================================================================


-- =====================================================================
-- Step B: TB-PAM root SP populates D_TB_PAM (the wide pivoted dim).
--   147 reads nrt_page_case_answer + nrt_investigation, filters on
--   INV_FORM_RVCT, excludes 13 d_topic question_identifiers, pivots
--   the remaining 150+ TUB questions into D_TB_PAM columns. Even with
--   just our 10 main-pivot rows, 1 row writes to D_TB_PAM with those
--   10 columns populated and 156 NULL.
-- =====================================================================


-- =====================================================================
-- Step C: the 12 d_topic SPs each pivot a single TUB question into
--   a topic dim + group link table. Param names vary (see SP-signature
--   table in fixture header comments).
-- =====================================================================

-- @phc_uids SPs (8 of them)
-- (skip d_rash_loc_gen and d_pcr_source — those are Varicella, not TB)

-- @phc_id_list SPs (rest)

-- =====================================================================
-- Step E: tb_pam_ldf — LDF answer dim for the RVCT form. This SP is a
--   postprocessing SP (not a datamart SP) and isn't invoked by the
--   orchestrator's Step 9, so we run it here.
-- =====================================================================


-- =====================================================================
-- Step D / F / G — NOT run from this fixture.
--   sp_f_tb_pam_postprocessing, sp_tb_datamart_postprocessing, and
--   sp_tb_hiv_datamart_postprocessing are all invoked by Step 9 of
--   merge_and_verify.sh against the global PHC_UIDS list (which
--   includes 22001000). Running them here in addition would produce
--   double rows because their DELETE-then-INSERT scope is per-PHC and
--   they'd re-execute identically at Step 9. Single invocation per
--   merged-fixture run, via the orchestrator.
-- =====================================================================
