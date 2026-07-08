-- =====================================================================
-- R6 (NO-SHORTCUT, ANSWER-ONLY) — hepatitis_datamart NULL-column gap fill #2
--   via single-dim page ANSWERS on TWO NEW Hep investigations whose
--   condition->form carries the still-NULL D_INV_RISK_FACTOR / D_INV_MOTHER
--   datamart-mapped questions. UID block 22076000-22076999.
-- =====================================================================
-- TARGET (hepatitis_datamart, routine 013 — live-verified all-NULL today,
--   AND NOT reachable from the Acute (10100) / Hep-A (10110) / HEPGEN (10481)
--   forms used by the committed hep fills + zz_hepatitis_answer_gap.sql):
--
--   D_INV_RISK_FACTOR (9) — routine 013 step 11 final-INSERT cols 19/129/131/
--     135/137/140/148/161/162 (lines ~836-870):
--       RSK_HepContactEver       -> HEP_CONTACT_EVER_IND
--       RSK_BloodWorkerEver      -> MED_DEN_EMP_EVER_IND
--       RSK_ClottingPrior87      -> CLOTFACTOR_PRIOR_1987
--       RSK_HemodialysisLongTerm -> LT_HEMODIALYSIS_IND
--       RSK_IDU                  -> EVER_INJCT_NOPRSC_DRG
--       RSK_IncarceratedEver     -> EVER_INCAR_IND
--       RSK_NumSexPrtners        -> LIFE_SEX_PRTNR_NBR
--       RSK_TransfusionPrior92   -> BLD_TRANSF_PRIOR_1992
--       RSK_TransplantPrior92    -> ORGN_TRNSP_PRIOR_1992
--   D_INV_MOTHER (7) — routine 013 step 10 (lines ~697-704):
--       MTH_MotherBornOutsideUS  -> MTH_BORN_OUTSIDE_US
--       MTH_MotherEthnicity      -> MTH_ETHNICITY
--       MTH_MotherHBsAgPosPrior  -> MTH_HBS_AG_PRIOR_POS
--       MTH_MotherPositiveAfter  -> MTH_POS_AFTER
--       MTH_MotherPosTestDate    -> MTH_POS_TEST_DT
--       MTH_MotherRace           -> MTH_RACE
--       MTH_MothersBirthCountry  -> MTH_BIRTH_COUNTRY
--   => 16 still-NULL hepatitis_datamart columns expected to populate.
--
-- WHY THESE ARE NULL (root cause, proven live 2026-06-04 against
--   NBS_rdb_metadata x NBS_ui_metadata x NBS_page):
--   The page-builder (routine 007) resolves each nbs_case_answer to a target
--   D_INV_* dim column by matching (INVESTIGATION_FORM_CD, nbs_question_uid)
--   against NBS_rdb_metadata (line ~205). The 9 RISK questions above are mapped
--   to D_INV_RISK_FACTOR ONLY on form PG_Hepatitis_B_and_C_Chronic_Investigation
--   (conditions 10105 / 10106), and the 7 MOTHER questions to D_INV_MOTHER ONLY
--   on form PG_Hepatitis_B_Perinatal_Investigation (condition 10104). They are
--   NOT mapped on the Acute (PG_Hepatitis_B_and_C_Acute_Investigation, cond
--   10100) form that PHCs 22046000 / 22054000 use, nor on the Hep-A form
--   (20000100 / zz_hepatitis_answer_gap.sql) — verified: a query of all hep
--   forms returns these column mappings ONLY on the Chronic / Perinatal forms.
--   So no Chronic / Perinatal Hep investigation ever existed to carry them, and
--   routine 013 (which selects condition_cd IN ('10104','10105','10106',...),
--   line ~71) read NULL for all 16 columns.
--
-- FIX (ODSE-only, additive, ANSWER-ONLY — NO observations, bug #20 obs
--   fail-fast NOT tripped): author TWO NEW Hep investigations whose
--   condition_code.investigation_form_cd carries the mappings, each with a
--   SubjOfPHC patient link (sets nrt_investigation.patient_id so
--   ProcessDatamartData does not silently drop the datamart, LESSON 5) and
--   single-dim page answers (answer_group_seq_nbr = NULL routes to the SINGLE
--   D_INV_* dim, routine 007, LESSON 9 — NOT D_INVESTIGATION_REPEAT):
--     PHC 22076000  condition 10105 (Hepatitis B chronic) ->
--                   PG_Hepatitis_B_and_C_Chronic_Investigation  -> 9 RISK answers
--     PHC 22076100  condition 10104 (Hepatitis B perinatal) ->
--                   PG_Hepatitis_B_Perinatal_Investigation      -> 7 MOTHER answers
--   Both conditions map in RDB_MODERN.dbo.nrt_datamart_metadata to
--   Hepatitis_Datamart -> sp_hepatitis_datamart_postprocessing (routine 013),
--   and both are in routine 013's #TMP_CONDITION list (10104/10105/10106).
--   Because coverage counts a column populated if ANY datamart row is non-NULL,
--   the two new rows fill the still-NULL RISK / MOTHER columns.
--
-- CODESET-VALIDATED VALUES (page-builder resolves coded answers via
--   NBS_SRTE.code_value_general; verified live):
--   CSG 4150  Y/N (Y / N);  CSG 102960 country '124'=CANADA;
--   CSG 102950 ethnicity '2186-5'=Not Hispanic or Latino;
--   CSG 104890 race '2'=Asian.  (RSK_NumSexPrtners is NUMERIC; dates typed.)
--
-- IDEMPOTENCY / COLLISION SAFETY (LESSON 10/11): nbs_case_answer is left on
--   auto-IDENTITY (no IDENTITY_INSERT); each answer carries a DISTINGUISHING
--   guard `answer_group_seq_nbr IS NULL` on (act_uid, nbs_question_uid) so it
--   matches ONLY this fixture's single-dim rows, never a group-0 page answer
--   any other fixture might write for the same (act, question). The two PHC
--   entities are guarded by NOT EXISTS on public_health_case_uid. UIDs consumed
--   from 22076000-22076999: 22076000 (act/phc/act_id) + 22076100 (act/phc/act_id).
--
-- LANDING NOTE / ORCHESTRATION: these PHCs are NOT in scripts/merge_and_verify.sh
--   PHC_UIDS (that file is OUT OF BOUNDS for this task — not edited). They are
--   processed by the SERVICE's per-CDC Tier-3 drain (sp_investigation_event ->
--   page-builder routines 007/036 -> sp_hepatitis_datamart_postprocessing) which
--   targets every changed investigation, not only the harness backstop list.
--   The last_chg_time bump below makes CDC re-emit them. If the deterministic
--   Step-9 backstop is later desired for these PHCs, add 22076000,22076100 to
--   PHC_UIDS (separate, sanctioned harness change — intentionally NOT done here).
--
-- DOCUMENTED OUT-OF-REACH (left NULL — not answer-reachable, skipped):
--   * PAT_MIDDLE_NM    : sourced from SHARED D_PATIENT (routine 013 ~line 1037,
--     PATIENT_MIDDLE_NAME). Foundation patient 20000000 has no middle name and
--     the loop forbids UPDATE of shared dims -> NULL.
--   * DIE_FRM_THIS_ILLNESS_IND : no die_frm_this_illness_ind column exists on
--     public_health_case in this seed (observation-sourced) -> NULL.
--   * LEGACY_CASE_ID   : populated only for migrated/legacy investigations; no
--     answer route -> NULL.
--   * VACC_DOSE_NBR_1..4 / VACC_RECVD_DT_1..4 (8) : REPEATING vaccination-block
--     datamart cols (routine 013 step 13 pivots VAC_* by group 1..4). These need
--     answer_group_seq_nbr = 1/2/3/4 repeating-block answers, NOT single-dim
--     (LESSON 9) — out of scope for this single-dim ANSWER-only fixture. Left
--     for a dedicated repeating-vaccination fixture.
--
-- Foundation deps (read-only): patient 20000000 (D_PATIENT), superuser 10009282.
-- ODSE-only: no nrt_* INSERTs, no EXEC sp_*, no seed/SRTE/liquibase edits, no
--   new observations, no Confirmation_method rows. Omit GENERATED ALWAYS period
--   cols. Additive; never UPDATE shared dims.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @ts datetime = '2026-04-01T00:00:00';
DECLARE @su bigint = 10009282;

-- =====================================================================
-- PHC 22076000 — Hepatitis B chronic (cond 10105 -> Chronic form) : 9 RISK
-- =====================================================================
DECLARE @phc_chronic bigint = 22076000;
IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @phc_chronic)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@phc_chronic, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@phc_chronic, @ts, @su, N'I',
         N'C', N'10105', N'Hepatitis B virus infection, Chronic', N'NND', N'NND',
         N'O', @ts, @su, N'CAS22076000GA01',
         N'OPEN', @ts, N'A', @ts,
         N'T', 1, N'HEP', N'130001',
         @phc_chronic, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@phc_chronic, 1, @ts, @su,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         @ts, @su, N'ACTIVE',
         @ts, N'CAS22076000GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @ts);

    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @phc_chronic, N'SubjOfPHC', N'CASE', @ts, @su,
         @ts, @su, N'ACTIVE', @ts, N'A', @ts, N'PSN',
         N'Subject of Public Health Case');
END;
GO

-- ---- D_INV_RISK_FACTOR (9) on PG_Hepatitis_B_and_C_Chronic_Investigation ----
-- answer_group_seq_nbr = NULL -> single dim (LESSON 9). nbs_case_answer auto-IDENTITY.
DECLARE @phc_chronic bigint = 22076000;
DECLARE @su bigint = 10009282;
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_chronic AND nbs_question_uid=10001141 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_chronic,10001141,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- RSK_HepContactEver -> HEP_CONTACT_EVER_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_chronic AND nbs_question_uid=10001142 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_chronic,10001142,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- RSK_BloodWorkerEver -> MED_DEN_EMP_EVER_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_chronic AND nbs_question_uid=10001136 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_chronic,10001136,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- RSK_ClottingPrior87 -> CLOTFACTOR_PRIOR_1987 (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_chronic AND nbs_question_uid=10001137 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_chronic,10001137,1,'N',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- RSK_HemodialysisLongTerm -> LT_HEMODIALYSIS_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_chronic AND nbs_question_uid=10001138 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_chronic,10001138,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- RSK_IDU -> EVER_INJCT_NOPRSC_DRG (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_chronic AND nbs_question_uid=10001140 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_chronic,10001140,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- RSK_IncarceratedEver -> EVER_INCAR_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_chronic AND nbs_question_uid=10001139 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_chronic,10001139,1,'3',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- RSK_NumSexPrtners -> LIFE_SEX_PRTNR_NBR (NUMERIC)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_chronic AND nbs_question_uid=10001134 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_chronic,10001134,1,'N',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- RSK_TransfusionPrior92 -> BLD_TRANSF_PRIOR_1992 (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_chronic AND nbs_question_uid=10001135 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_chronic,10001135,1,'N',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- RSK_TransplantPrior92 -> ORGN_TRNSP_PRIOR_1992 (CSG 4150)
GO

-- =====================================================================
-- PHC 22076100 — Hepatitis B perinatal (cond 10104 -> Perinatal form) : 7 MOTHER
-- =====================================================================
DECLARE @ts datetime = '2026-04-01T00:00:00';
DECLARE @su bigint = 10009282;
DECLARE @phc_perinatal bigint = 22076100;
IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @phc_perinatal)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@phc_perinatal, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@phc_perinatal, @ts, @su, N'I',
         N'C', N'10104', N'Hepatitis B Viral Infection, Perinatal', N'NND', N'NND',
         N'O', @ts, @su, N'CAS22076100GA01',
         N'OPEN', @ts, N'A', @ts,
         N'T', 1, N'HEP', N'130001',
         @phc_perinatal, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@phc_perinatal, 1, @ts, @su,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         @ts, @su, N'ACTIVE',
         @ts, N'CAS22076100GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @ts);

    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @phc_perinatal, N'SubjOfPHC', N'CASE', @ts, @su,
         @ts, @su, N'ACTIVE', @ts, N'A', @ts, N'PSN',
         N'Subject of Public Health Case');
END;
GO

-- ---- D_INV_MOTHER (7) on PG_Hepatitis_B_Perinatal_Investigation ----
-- answer_group_seq_nbr = NULL -> single dim (LESSON 9). nbs_case_answer auto-IDENTITY.
DECLARE @phc_perinatal bigint = 22076100;
DECLARE @su bigint = 10009282;
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_perinatal AND nbs_question_uid=10001148 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_perinatal,10001148,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- MTH_MotherBornOutsideUS -> MTH_BORN_OUTSIDE_US (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_perinatal AND nbs_question_uid=10001146 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_perinatal,10001146,1,'2186-5',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- MTH_MotherEthnicity -> MTH_ETHNICITY (CSG 102950 '2186-5'=Not Hispanic or Latino)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_perinatal AND nbs_question_uid=10001149 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_perinatal,10001149,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- MTH_MotherHBsAgPosPrior -> MTH_HBS_AG_PRIOR_POS (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_perinatal AND nbs_question_uid=10001150 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_perinatal,10001150,1,'N',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- MTH_MotherPositiveAfter -> MTH_POS_AFTER (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_perinatal AND nbs_question_uid=10001151 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_perinatal,10001151,1,'2026-02-15',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- MTH_MotherPosTestDate -> MTH_POS_TEST_DT (DATE)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_perinatal AND nbs_question_uid=10001144 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_perinatal,10001144,1,'2',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- MTH_MotherRace -> MTH_RACE (CSG 104890 '2'=Asian)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_perinatal AND nbs_question_uid=10001143 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_perinatal,10001143,1,'124',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- MTH_MothersBirthCountry -> MTH_BIRTH_COUNTRY (CSG 102960 '124'=CANADA)
GO

-- Bump last_chg_time so CDC re-emits both PHCs -> sp_investigation_event
-- re-derives rdb_table_name_list incl. the now-NULL-group RISK / MOTHER
-- answers; sp_s_pagebuilder_postprocessing builds the single D_INV_RISK_FACTOR /
-- D_INV_MOTHER dim rows and routine 013 fills the 16 targeted NULL columns.
UPDATE [NBS_ODSE].[dbo].[public_health_case]
   SET [last_chg_time] = SYSDATETIME()
 WHERE public_health_case_uid IN (22076000, 22076100);
GO
