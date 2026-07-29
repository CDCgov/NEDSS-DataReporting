-- =====================================================================
-- R6 tick2 (NO-SHORTCUT, NON-OBS) — hepatitis_datamart NULL-column gap fill
--   via additional single-dim page ANSWERS on an EXISTING Hep-A PHC.
--   UID block 22067000-22067999 (auto-IDENTITY answers -> 0 consumed).
-- =====================================================================
-- TARGET (hepatitis_datamart, routine 013 — live-verified all-NULL today):
--   D_INV_EPIDEMIOLOGY -> CHILDCARE_CASE_IND, CT_BABYSITTER_IND,
--     CT_CHILDCARE_IND, CT_PLAYMATE_IND, DNP_HOUSEHOLD_CT_IND, DNP_EMPLOYEE_IND,
--     HEP_A_EPLINK_IND, FOODHNDLR_PRIOR_IND, COM_SRC_OUTBREAK_IND,
--     OBRK_FOODHNDLR_IND, OBRK_NOFOODHNDLR_IND, OBRK_UNIDENTIFIED_IND,
--     OBRK_WATERBORNE_IND, FOOD_OBRK_FOOD_ITEM                          (14)
--   D_INV_TRAVEL -> HOUSEHOLD_TRAVEL_IND, TRAVEL_OUT_USACAN_IND,
--     TRAVEL_OUT_USACAN_LOC, HOUSEHOLD_TRAVEL_LOC, TRAVEL_REASON         (5)
--   D_INV_VACCINATION -> IMM_GLOB_RECVD_IND, GLOB_LAST_RECVD_YR          (2)
--   => ~21 still-NULL hepatitis_datamart columns expected to populate.
--
-- WHY THESE ARE NULL (root cause, proven 2026-06-04):
--   These columns are sourced by sp_hepatitis_datamart_postprocessing
--   (routine 013, steps 7/12/13 -> #TMP_D_INV_EPIDEMIOLOGY / _TRAVEL /
--   _VACCINATION) from the SINGLE page-builder dims D_INV_EPIDEMIOLOGY,
--   D_INV_TRAVEL, D_INV_VACCINATION. Their feeding questions are mapped to
--   those dims ONLY on the Hepatitis-A form
--   (PG_Hepatitis_A_Acute_Investigation) — NOT on
--   PG_Hepatitis_B_and_C_Acute_Investigation, which is why the committed
--   Hep-B-acute fills (22046000 / 22054000) left them NULL (documented as
--   "out of reach for this form" in zz_hepatitis_datamart_fill2.sql).
--   The Hep-A subject PHCs that DO carry the mapping are answered ONLY at
--   answer_group_seq_nbr = 0 (by zz_page_answers_datamart_routing.sql),
--   which routine 007 routes to D_INVESTIGATION_REPEAT — NOT the single
--   D_INV_* dims (LESSON 9). So no Hep-A single-dim EPI/TRAVEL/VACC row ever
--   built, and routine 013 read NULL for every one of these columns.
--
-- FIX (ODSE-only, additive, NON-OBS): attach the missing datamart-mapped
--   Hep-A-form answers at answer_group_seq_nbr = NULL (the SINGLE-dim route,
--   LESSON 9) to an EXISTING Hep-A acute PHC that is ALREADY in the harness
--   PHC_UIDS list and already produces a hepatitis_datamart row:
--
--     PHC 20000100  (condition 10110 -> PG_Hepatitis_A_Acute_Investigation)
--
--   Live state confirmed: 20000100 has a SubjOfPHC link (patient 20000000 ->
--   nrt_investigation.patient_id set, so ProcessDatamartData does not drop
--   it, LESSON 5); it ALREADY HAS a hepatitis_datamart row (CASE_UID
--   20000100, INVESTIGATION_KEY 5) whose EPI/TRAVEL/VACC columns are all
--   NULL; and it has ZERO existing nbs_case_answer rows (no group-0
--   collision, no duplication). f_page_case_unblock.sql already sets its
--   nrt_investigation.investigation_form_cd so F_PAGE_CASE / the single
--   D_INV_* dim rows build for it. Adding NULL-group answers therefore fills
--   the existing row's NULL EPI/TRAVEL/VACC dim columns in place.
--
--   NO new observations are authored (bug #20 obs fail-fast is not tripped):
--   only nbs_case_answer rows + a public_health_case.last_chg_time bump.
--
-- IDEMPOTENCY / COLLISION SAFETY (LESSON 10/11): nbs_case_answer is left on
--   auto-IDENTITY (no IDENTITY_INSERT) and each row carries a DISTINGUISHING
--   guard `answer_group_seq_nbr IS NULL` on (act_uid, nbs_question_uid) so it
--   matches ONLY this fixture's single-dim rows and never the group-0 page
--   answers any other fixture may write for the same (act, question).
--   No UID from 22067000-22067999 is consumed (auto-IDENTITY).
--
-- CODESET-VALIDATED VALUES (NBS_SRTE.code_value_general, page-builder
--   resolves coded answers to descriptions): CSG 4150 Y/N (yes/no);
--   CSG 102960 country '124'=CANADA; CSG 104320 reason '5'=tourism.
--   (EPI_OutbreakFoodItem / dates / numeric are free / typed values.)
--
-- No PHC_UIDS / merge_and_verify.sh edit is required: 20000100 is already in
--   PHC_UIDS, so Step-8.x page-builder + Step-9 routine 013 reprocess it.
--
-- Foundation deps (read-only): PHC 20000100, patient 20000000, superuser 10009282.
-- ODSE-only: no nrt_* INSERTs, no EXEC sp_*, no seed/SRTE/liquibase edits,
--   no new observations. Additive; never UPDATE shared dims.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @phc_uid bigint = 20000100;
DECLARE @su bigint = 10009282;

-- ---- D_INV_EPIDEMIOLOGY (Hep-A-only mapped questions -> the 14 NULL cols) ----
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001074 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001074,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_ChildCareCase -> CHILDCARE_CASE_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001068 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001068,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_ContactBabysitter -> CT_BABYSITTER_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001067 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001067,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_ContactChildcare -> CT_CHILDCARE_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001069 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001069,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_ContactPlaymate -> CT_PLAYMATE_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001073 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001073,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_DaycareContact -> DNP_HOUSEHOLD_CT_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001072 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001072,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_InDayCare -> DNP_EMPLOYEE_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=1113 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,1113,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_EpiLinked -> HEP_A_EPLINK_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001091 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001091,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_FoodHandler -> FOODHNDLR_PRIOR_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001085 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001085,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_OutbreakAssoc -> COM_SRC_OUTBREAK_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001086 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001086,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_OutbreakFoodHndlr -> OBRK_FOODHNDLR_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001087 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001087,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_outbreakNonFoodHndlr -> OBRK_NOFOODHNDLR_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001090 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001090,1,'N',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_OutbreakUnidentified -> OBRK_UNIDENTIFIED_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001089 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001089,1,'N',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_OutbreakWaterborne -> OBRK_WATERBORNE_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001088 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001088,1,'Shellfish',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- EPI_OutbreakFoodItem -> FOOD_OBRK_FOOD_ITEM (free text)
GO

-- ---- D_INV_TRAVEL (Hep-A-only mapped questions -> the 5 NULL cols) ----
DECLARE @phc_uid bigint = 20000100;
DECLARE @su bigint = 10009282;
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001080 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001080,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- TRV_PatientTravel -> TRAVEL_OUT_USACAN_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001081 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001081,1,'124',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- TRV_PtTravelCountries -> TRAVEL_OUT_USACAN_LOC (CSG 102960 '124'=CANADA)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001082 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001082,1,'5',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- TRV_VHF_TRAVEL_REASON -> TRAVEL_REASON (CSG 104320 '5'=tourism)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001083 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001083,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- TRV_HouseholdTravel -> HOUSEHOLD_TRAVEL_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001084 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001084,1,'124',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- TRV_TravelCountryHouse -> HOUSEHOLD_TRAVEL_LOC (CSG 102960 '124'=CANADA)
GO

-- ---- D_INV_VACCINATION immune-globulin pair -> IMM_GLOB_RECVD_IND / GLOB_LAST_RECVD_YR ----
DECLARE @phc_uid bigint = 20000100;
DECLARE @su bigint = 10009282;
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001095 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001095,1,'Y',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- VAC_ImmuneGlobulin -> IMM_GLOB_RECVD_IND (CSG 4150)
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@phc_uid AND nbs_question_uid=10001096 AND answer_group_seq_nbr IS NULL)
    INSERT INTO dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (@phc_uid,10001096,1,'2025-09-01',1,NULL,GETDATE(),@su,GETDATE(),@su,'ACTIVE',GETDATE()); -- VAC_LastIGDose -> GLOB_LAST_RECVD_YR (DATE)
GO

-- Bump last_chg_time so CDC re-emits PHC 20000100 -> sp_investigation_event
-- re-derives rdb_table_name_list incl. the now-NULL-group EPI/TRAVEL/VACC
-- answers; sp_s_pagebuilder_postprocessing builds the single D_INV_* dim
-- rows and routine 013 (sp_hepatitis_datamart_postprocessing) fills the
-- targeted NULL columns on the existing 20000100 hepatitis_datamart row.
UPDATE [NBS_ODSE].[dbo].[public_health_case]
   SET [last_chg_time] = SYSDATETIME()
 WHERE public_health_case_uid = 20000100;
GO
