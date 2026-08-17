-- =====================================================================
-- Round 4 (NO-SHORTCUT) — hepatitis_datamart page-builder fill (ODSE-only)
-- =====================================================================
-- TARGET: fill the 167 NULL columns on dbo.hepatitis_datamart (42/209 at
--   the baseline) through the REAL page-builder + datamart pipeline.
--
-- ROOT CAUSE (proven live, 2026-06-03):
--   The committed zz_hepatitis_case_chain.sql PHC 22043000 (condition
--   10481 -> form INV_FORM_HEPGEN) populates dbo.HEPATITIS_CASE (149/152)
--   via the InvFrmQ *observation* route (routine 039 / hep100 042). But
--   sp_hepatitis_datamart_postprocessing (routine 013) does NOT read
--   HEPATITIS_CASE for its 167 NULL columns — it sources them from the
--   page-builder dimensions:
--       D_INV_LAB_FINDING       (alias L  — 36 lab columns)
--       D_INV_RISK_FACTOR       (alias R  — ~38 risk columns)
--       D_INV_MEDICAL_HISTORY   (alias MH — 9 columns)
--       D_INV_EPIDEMIOLOGY      (alias E  — contact/drug/sex columns)
--   joined 1:1 to the investigation through dbo.F_PAGE_CASE
--   (routine 013, steps 5/7/8/9, INNER JOIN #TMP_F_PAGE_CASE on
--   INVESTIGATION_KEY). Those single dims are built by
--   sp_s_pagebuilder_postprocessing (routine 007) + sp_f_page_case_postprocessing
--   from nrt_page_case_answer (<- ODSE nbs_case_answer), and ONLY for
--   answers with ANSWER_GROUP_SEQ_NBR IS NULL (routine 007 lines 103/191/193 —
--   LESSON 9). The service derives nrt_investigation.rdb_table_name_list in
--   Java from those answers' distinct rdb_table_nm.
--
--   PHC 22043000 had ZERO page answers, AND its form INV_FORM_HEPGEN carries
--   ZERO datamart-mapped nbs_ui_metadata/nbs_rdb_metadata, so its
--   rdb_table_name_list is NULL, F_PAGE_CASE has no row for it, and every
--   D_INV_* join in routine 013 returns nothing => 167 NULL columns.
--   Live confirmation: nrt_investigation.rdb_table_name_list IS NULL for
--   22043000; F_PAGE_CASE / D_INV_* counts for its INVESTIGATION_KEY = 0.
--
-- FIX (ODSE-only, additive): author a NEW Hepatitis investigation under
--   condition_cd '10100' (Hepatitis B, acute) which:
--     - maps in nrt_datamart_metadata to 'Hepatitis_Datamart'
--       -> sp_hepatitis_datamart_postprocessing (routine 013), AND
--     - has condition_code.investigation_form_cd =
--       'PG_Hepatitis_B_and_C_Acute_Investigation', the page form that DOES
--       carry the datamart-mapped page-builder metadata (live count: 36
--       LAB_FINDING + 30 RISK_FACTOR + 9 MEDICAL_HISTORY + 10 EPIDEMIOLOGY =
--       85 questions resolving a non-null rdb_table_nm).
--   The PHC gets a SubjOfPHC patient link (so ProcessDatamartData does not
--   silently drop it — LESSON 5) and 85 nbs_case_answer rows, one per
--   datamart-mapped question_uid of that form, with type-correct values and
--   answer_group_seq_nbr = NULL (single-dim route, LESSON 9).
--
--   CDC mirrors ODSE -> nrt_page_case_answer; the service computes
--   rdb_table_name_list -> sp_f_page_case_postprocessing builds F_PAGE_CASE +
--   sp_s_pagebuilder_postprocessing builds the single D_INV_* dims ->
--   routine 013 fills hepatitis_datamart for the new PHC.
--
-- EXPECTED FILL: routine 013 maps these dims into ~80 distinct
--   hepatitis_datamart columns (LAB 36 -> HEP_*_ANTIBODY/HBsAg/HBeAg/dates,
--   RISK ~30 -> BLD_*/INCAR_*/PIERC_*/TATT_*/STD_*, MED_HISTORY 9 ->
--   DIABETES_*/PAT_JUNDICED_IND/TEST_REASON*/SYMPTOMATIC_IND, EPI ~10 ->
--   contact/sex-partner/drug-use). All sampled target columns are NULL today.
--   Conservative expectation: ~80 of the 167 NULL columns populate.
--
-- ORCH_TODO: add 22046000 to PHC_UIDS in scripts/merge_and_verify.sh so
--   Step-8.x page-builder (007/036) and Step-9 routine 013 target it.
--   (Same orchestration step that 22043000 required.)
--
-- UID block (reserved 22046000-22046999 in catalog/uid_ranges.md):
--   22046000   public_health_case / act / act_id (the new HEP-B-acute PHC)
--   (nbs_case_answer_uid is IDENTITY -> omitted; participation subject is the
--    foundation patient 20000000, no new UID consumed.)
--
-- Foundation deps (read-only): patient 20000000 (D_PATIENT), superuser 10009282.
-- ODSE-only: no nrt_* INSERTs, no EXEC sp_*, no seed/SRTE/liquibase edits.
-- Omit GENERATED ALWAYS period cols.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @ts datetime = '2026-04-01T00:00:00';
DECLARE @superuser_id bigint = 10009282;
DECLARE @phc_uid bigint = 22046000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @phc_uid)
BEGIN
    -- ----- ODSE: act + public_health_case (condition 10100 -> PG_Hepatitis_B_and_C_Acute) -----
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@phc_uid, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@phc_uid, @ts, @superuser_id, N'I',
         N'C', N'10100', N'Hepatitis B, acute', N'NND', N'NND',
         N'O', CAST(GETDATE() AS DATE), @superuser_id, N'CAS22046000GA01',
         N'OPEN', @ts, N'A', @ts,
         N'T', 1, N'HEP', N'130001',
         @phc_uid, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@phc_uid, 1, @ts, @superuser_id,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE',
         @ts, N'CAS22046000GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @ts);

    -- ----- ODSE: SubjOfPHC patient link (sets nrt_investigation.patient_id) -----
    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @phc_uid, N'SubjOfPHC', N'CASE', @ts, @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', @ts, N'A', @ts, N'PSN',
         N'Subject of Public Health Case');

    -- ----- 85 page-builder answers on PG_Hepatitis_B_and_C_Acute_Investigation -----
    -- One nbs_case_answer per datamart-mapped question_uid of the form, with a
    -- type-correct value. answer_group_seq_nbr = NULL routes each to the SINGLE
    -- D_INV_* dim (routine 007 gate), NOT D_INVESTIGATION_REPEAT (LESSON 9).
    -- Comments map each question -> target D_INV dim column. (Generated from
    -- live nbs_ui_metadata -> nbs_rdb_metadata; nbs_case_answer_uid IDENTITY omitted.)

    -- D_INV_EPIDEMIOLOGY (10) --------------------------------------------------
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001007,1,'840',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_CNTRY_USUAL_RESID
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001065,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_ContactHousehold
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001064,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_ContactOfCase
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001070,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_ContactOther
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001071,1,'RTRfix',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_ContactOthSpecify
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001066,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_ContactSexPartner
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001077,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_FemaleSexPartners
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001078,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_IVDrugUse
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001076,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_MaleSexPartner
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001079,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_RecDrugUse

    -- D_INV_LAB_FINDING (36) ---------------------------------------------------
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001033,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_ALT_Result
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001133,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_AntiHBsPositive
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001132,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_AntiHBsTested
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001036,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_AST_Result
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001052,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HBeAg
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001051,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HBeAg_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001044,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HBsAg
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001043,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HBsAg_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001050,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HBV_NAT
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001049,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HBV_NAT_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001059,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HCVRNA
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001058,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HCVRNA_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001099,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HepDTest
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001042,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_IgM_AntiHAV
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001041,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_IgMAntiHAVDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001048,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_IgMAntiHBc
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001047,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_IgMAntiHBcDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001097,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_PrevNegHepTest
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001055,1,'RTRfix',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_SignalToCutoff
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001057,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_Supplem_antiHCV
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001056,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_Supplem_antiHCV_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001034,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TestDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001037,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TestDate2
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001035,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TestResultUpperLimit
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001038,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TestResultUpperLimit2
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001040,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHAV
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001039,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHAVDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001046,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHBc
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001045,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHBcDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001054,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHCV
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001053,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHCV_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001061,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHDV
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001060,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHDV_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001063,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHEV
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001062,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHEV_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001098,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_VerifiedTestDate

    -- D_INV_MEDICAL_HISTORY (9) ------------------------------------------------
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001031,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_Diabetes
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001032,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_DiabetesDxDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001006,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_DueDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001028,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_Jaundiced
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001029,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_PrevAwareInfection
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001030,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_ProviderOfCare
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001025,1,'OTH',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_ReasonForTest
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001026,1,'RTRfix',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_ReasonForTestingOth
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001027,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_Symptomatic

    -- D_INV_RISK_FACTOR (30) ---------------------------------------------------
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001108,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_BloodExpOther
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001105,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_BloodTransfusion
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001106,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_BloodTransfusionDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001111,1,'1',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_BloodWorkerCnctFreq
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001110,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_BloodWorkerOnset
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001104,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_ContaminatedStick
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001120,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_DentalOralSx
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001103,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_HEMODIALYSIS_BEFORE_ONSET
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001122,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_HospitalizedPrior
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001124,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_Incarcerated24Hrs
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001128,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_Incarcerated6months
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001126,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_IncarceratedJail
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001125,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_IncarcerationPrison
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001127,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_IncarcJuvenileFacilit
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001130,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_IncarcTimeMonths
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001129,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_IncarcYear6Mos
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001107,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_IVInjectInfuseOutpt
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001123,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_LongTermCareRes
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001109,1,'RTRfix',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_OtherBldExpSpec
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001117,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_Piercing
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001119,1,'RTRfix',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_PiercingOthLocSpec
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001118,1,'1',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_PiercingRcvdFrom
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001113,1,'1',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_PSWrkrBldCnctFreq
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001112,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_PublicSafetyWorker
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001101,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_STDTxEver
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001102,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_STDTxYr
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001121,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_SurgeryOther
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001114,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_Tattoo
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001115,1,'1',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_TattooLocation
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22046000,10001116,1,'RTRfix',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_TattooLocOthSpec
END;
GO

-- Bump last_chg_time so CDC re-emits the investigation and the service
-- re-runs sp_investigation_event, deriving rdb_table_name_list from the new
-- page answers and driving the page-builder + hepatitis_datamart SPs.
UPDATE [NBS_ODSE].[dbo].[public_health_case]
   SET [last_chg_time] = SYSDATETIME()
 WHERE public_health_case_uid = 22046000;
GO
