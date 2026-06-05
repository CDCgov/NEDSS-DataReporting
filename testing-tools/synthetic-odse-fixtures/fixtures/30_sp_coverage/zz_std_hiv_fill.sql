-- =====================================================================
-- zz_std_hiv_fill.sql  (Round 4, no-shortcut, ODSE-only)  [R4-E]
-- =====================================================================
-- TARGET: raise dbo.STD_HIV_DATAMART from 55/248 toward full by making
--         the page-builder D_INV_* dimensions populate for the STD
--         Syphilis investigation (PHC 22004000, condition 10311 ->
--         PG_STD_Investigation).
--
-- ROOT CAUSE (verified live against routine source on 2026-06-03)
--   STD_HIV_DATAMART (routine 026-sp_std_hiv_datamart_postprocessing)
--   LEFT JOINs F_STD_PAGE_CASE to 13 page-builder dims
--   (D_INV_CLINICAL/COMPLICATION/CONTACT/EPIDEMIOLOGY/HIV/LAB_FINDING/
--    MEDICAL_HISTORY/PATIENT_OBS/PREGNANCY_BIRTH/RISK_FACTOR/
--    SOCIAL_HISTORY/SYMPTOM/TREATMENT) + D_INV_ADMINISTRATIVE + INV_HIV.
--   Every one of those dims is EMPTY for the STD investigation, so all
--   ~190 CLN_/CMP_/CTT_(RPT_)/EPI_/HIV_/LAB_/MDH_/IPO_/PBI_/RSK_/SOC_/
--   SYM_/TRT_/ADM_ columns land NULL. The 55 populated columns come only
--   from F_STD_PAGE_CASE keys + D_PATIENT + condition + a few
--   INVESTIGATION/D_CASE_MANAGEMENT fields.
--
--   The page-builder dim staging SP (routine 007
--   sp_s_pagebuilder_postprocessing) builds the SINGLE (non-repeating)
--   D_INV_* dim row ONLY from nbs_case_answer rows whose
--   ANSWER_GROUP_SEQ_NBR IS NULL (text path line 103; coded path lines
--   191/193 `nrt_page.ANSWER_GROUP_SEQ_NBR IS NULL` AND
--   `QUESTION_GROUP_SEQ_NBR IS NULL`). Answers with answer_group_seq_nbr=0
--   are treated as repeating-block answers and feed D_INVESTIGATION_REPEAT
--   instead, never the single dims.
--
--   The generic page-answer generator (zz_page_answers_datamart_routing.sql)
--   authored ALL 364 STD answers with answer_group_seq_nbr=0, so NONE of
--   them feed the single D_INV_* dims (live: 0 STD answers have NULL group
--   seq; 0 D_INV_* dim rows exist for the STD investigation). COVID PHC
--   22003000 populates its dims precisely because its curated full-chain
--   answers (e.g. nbs_case_answer_uid 22003109) carry
--   answer_group_seq_nbr = NULL.  <-- the discriminating fact, verified live.
--
-- FIX (ODSE-only, additive)
--   Author the COMPLEMENT set: one nbs_case_answer per STD-form question
--   that maps (via V_NRT_D_INV_METADATA, INVESTIGATION_FORM_CD=
--   'PG_STD_Investigation') to a single D_INV_* dim column, but with
--   answer_group_seq_nbr = NULL (and seq_nbr = 0, mirroring the working
--   COVID curated answer 22003109). These NEW rows live alongside the
--   generator's group_seq=0 rows (which keep feeding the repeat dim) and
--   are the rows routine 007 pivots into the single dims.
--
--   Answer codes reuse the exact values the generator already proved valid
--   for these question_uids (present in nrt_page_case_answer after CDC), so
--   coded answers resolve against their value sets; a handful are set to
--   clinically realistic STD values (per the MIXED-fidelity decision: STD
--   is clinically meaningful).
--
-- WHICH SP(s) PICK THIS UP (no manual EXEC — the real pipeline runs them)
--   CDC captures nbs_case_answer -> nrt_page_case_answer.
--   056-sp_investigation_event (service, on the PHC last_chg bump below)
--       recomputes nrt_investigation.rdb_table_name_list.
--   011-sp_page_builder_postprocessing / 007 staging / 009 dim (Step 9)
--       build the D_INV_* dim rows from the NULL-group answers.
--   025-sp_f_std_page_case_postprocessing (Step 9) wires the new dim keys
--       into F_STD_PAGE_CASE.
--   026-sp_std_hiv_datamart_postprocessing (Step 9) joins them ->
--       STD_HIV_DATAMART columns populate (and INV_HIV via the HIV dim).
--
-- EXPECTED FILL (single dims -> STD_HIV_DATAMART NULL columns)
--   D_INV_RISK_FACTOR     -> 24 RSK_* cols
--   D_INV_HIV             -> 16 HIV_* cols (also flow to INV_HIV)
--   D_INV_SOCIAL_HISTORY  -> 14 SOC_*/STD_PRTNRS_PRD_TRNSGNDR_TTL cols
--   D_INV_PATIENT_OBS     -> 11 IPO_* cols
--   D_INV_CONTACT         -> 10 RPT_* cols
--   D_INV_LAB_FINDING     -> 9  LAB_* cols
--   D_INV_PREGNANCY_BIRTH -> 8  PBI_* cols
--   D_INV_CLINICAL        -> 7  CLN_* cols
--   D_INV_SYMPTOM         -> 4  SYM_* cols
--   D_INV_ADMINISTRATIVE  -> 3  ADM_REFERRAL_BASIS_OOJ / ADM_RPTNG_CNTY /
--                                DISSEMINATED_IND
--   D_INV_COMPLICATION    -> 2  CMP_CONJUNCTIVITIS_IND / CMP_PID_IND
--   D_INV_EPIDEMIOLOGY    -> 2  EPI_CNTRY_USUAL_RESID / SOURCE_SPREAD
--   D_INV_MEDICAL_HISTORY -> 2  MDH_PREV_STD_HIST / PROVIDER_REASON_VISIT_DT
--   D_INV_TREATMENT       -> 1  TRT_TREATMENT_DATE
--   ~ up to ~113 of the 193 NULL columns (a few coded cols emit a *_CD
--   sibling rather than the display column; actual headline count confirmed
--   by the post-merge coverage measurement).
--
-- NOT IN SCOPE (documented gaps, not fixed here)
--   * D_CASE_MANAGEMENT (FL_FUP_*/INIT_FUP_*/OOJ_*/SURV_*/CA_* ~40 cols)
--     and the INVESTIGATION dim (INV_RPT_DT/INV_START_DT/REFERRAL_BASIS/
--     RPT_SRC_CD_DESC/CURR_PROCESS_STATE/... ) build via their OWN SPs
--     (sp_nrt_case_management_postprocessing / sp_nrt_investigation_
--     postprocessing / DynDM_Manage_Case_Management), not the D_INV_*
--     staging path gated on answer_group_seq_nbr. They are NULL for a
--     DIFFERENT reason and are out of scope for this fixture (would be a
--     separate authoring task).
--   * INVESTIGATOR_*_QC (D_PROVIDER.PROVIDER_QUICK_CODE) and IX_DATE_OI
--     (F_INTERVIEW_CASE) need provider/interview chains, not page answers.
--   * CALC_5_YEAR_AGE_GROUP / PATIENT_* gaps depend on D_PATIENT columns
--     on the shared foundation patient (PATIENT_KEY=4); not touched here
--     (never UPDATE shared dims).
--
-- UID BLOCK (this fixture): 22044000 - 22044999  (R4-E, reserved in
--   catalog/uid_ranges.md). nbs_case_answer_uid is IDENTITY -> pinned via
--   IDENTITY_INSERT. Max existing identity is 22011319, so this block is
--   collision-free.
--
-- REUSED UIDs (read-only, already in DB)
--   22004000  STD PHC (act_uid + public_health_case_uid) -- in PHC_UIDS,
--             so Step-9 SPs rebuild it automatically.
--   10009282  superuser id.
--
-- IDEMPOTENT: guarded by NOT EXISTS on nbs_case_answer_uid 22044000.
-- ADDITIVE: only INSERTs new nbs_case_answer rows + bumps the STD PHC's
--   last_chg_time. No nrt_* INSERT. No EXEC sp_*. No liquibase/seed/SRTE
--   edit. No UPDATE of any shared dim (D_PATIENT / F_*_PAM / USER_PROFILE).
-- =====================================================================

USE [NBS_ODSE];
GO

-- nbs_case_answer_uid is IDENTITY; let it AUTO-assign (LESSON 10:
-- hardcoded IDENTITY_INSERT UIDs collide with the auto-IDENTITY flood and
-- the guard silently skips the whole INSERT). Guard on the natural key
-- (act_uid, first nbs_question_uid) instead of the surrogate.
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer] WHERE act_uid = 22004000 AND nbs_question_uid = 10001261 AND answer_group_seq_nbr IS NULL)
BEGIN
    -- Each row: NULL answer_group_seq_nbr (single-dim path), seq_nbr 0,
    -- ACTIVE, superuser, version ctrl 1 -- mirrors COVID curated answer
    -- 22003109. act_uid = 22004000 (STD PHC). Answer codes are the proven
    -- valid codes for each question_uid (clinically meaningful where the
    -- column semantics are clear).
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id], [record_status_cd],
         [record_status_time], [seq_nbr], [answer_group_seq_nbr])
    VALUES
    -- ---- D_INV_RISK_FACTOR (24 RSK_* cols) ----
    (22004000, GETDATE(), 10009282, N'1',        10001261, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_RISK_FACTORS_ASSESS_IND (assessed=Yes)
    (22004000, GETDATE(), 10009282, N'D',        10001262, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_SEX_W_MALE_12MO_IND
    (22004000, GETDATE(), 10009282, N'D',        10001263, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_SEX_W_FEMALE_12MO_IND
    (22004000, GETDATE(), 10009282, N'D',        10001264, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_SEX_W_TRANSGNDR_12MO_IND
    (22004000, GETDATE(), 10009282, N'D',        10001265, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_SEX_W_ANON_PTRNR_12MO_IND
    (22004000, GETDATE(), 10009282, N'D',        10001266, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_SEX_WOUT_CONDOM_12MO_IND
    (22004000, GETDATE(), 10009282, N'D',        10001267, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_SEX_INTOXCTED_HGH_12MO_IND
    (22004000, GETDATE(), 10009282, N'D',        10001268, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_SEX_EXCH_DRGS_MNY_12MO_IND
    (22004000, GETDATE(), 10009282, N'D',        10001269, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_SEX_W_KNWN_MSM_12M_FML_IND
    (22004000, GETDATE(), 10009282, N'D',        10001270, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_SEX_W_KNOWN_IDU_12MO_IND
    (22004000, GETDATE(), 10009282, N'D',        10001271, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_BEEN_INCARCERATD_12MO_IND
    (22004000, GETDATE(), 10009282, N'D',        10001272, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_INJ_DRUG_USE_12MO_IND
    (22004000, GETDATE(), 10009282, N'D',        10001273, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_SHARED_INJ_EQUIP_12MO_IND
    (22004000, GETDATE(), 10009282, N'ASKU',     10001274, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_NO_DRUG_USE_12MO_IND
    (22004000, GETDATE(), 10009282, N'ASKU',     10001275, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_COCAINE_USE_12MO_IND
    (22004000, GETDATE(), 10009282, N'ASKU',     10001276, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_CRACK_USE_12MO_IND
    (22004000, GETDATE(), 10009282, N'ASKU',     10001277, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_HEROIN_USE_12MO_IND
    (22004000, GETDATE(), 10009282, N'ASKU',     10001278, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_METH_USE_12MO_IND
    (22004000, GETDATE(), 10009282, N'ASKU',     10001279, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_NITR_POP_USE_12MO_IND
    (22004000, GETDATE(), 10009282, N'ASKU',     10001280, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_ED_MEDS_USE_12MO_IND
    (22004000, GETDATE(), 10009282, N'ASKU',     10001281, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_OTHER_DRUG_USE_12MO_IND
    (22004000, GETDATE(), 10009282, N'None reported', 10001282, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_OTHER_DRUG_SPEC (TEXT)
    (22004000, GETDATE(), 10009282, N'TGTPOP1',  10001303, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- RSK_TARGET_POPULATIONS

    -- ---- D_INV_HIV (16 HIV_* cols) ----
    (22004000, GETDATE(), 10009282, N'RTRfix',   10001203, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_STATE_CASE_ID (TEXT)
    (22004000, GETDATE(), 10009282, N'1',        10001321, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_ENROLL_PRTNR_SRVCS_IND
    (22004000, GETDATE(), 10009282, N'N',        10001322, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_PREVIOUS_900_TEST_IND
    (22004000, GETDATE(), 10009282, N'1',        10001323, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_SELF_REPORTED_RSLT_900
    (22004000, GETDATE(), 10009282, N'2026-04-01', 10001324, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_LAST_900_TEST_DT (DATE)
    (22004000, GETDATE(), 10009282, N'N',        10001325, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_REFER_FOR_900_TEST
    (22004000, GETDATE(), 10009282, N'2026-04-01', 10001326, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_900_TEST_REFERRAL_DT (DATE)
    (22004000, GETDATE(), 10009282, N'N',        10001327, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_900_TEST_IND
    (22004000, GETDATE(), 10009282, N'1',        10001328, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_900_RESULT
    (22004000, GETDATE(), 10009282, N'2',        10001329, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_RST_PROVIDED_900_RSLT_IND
    (22004000, GETDATE(), 10009282, N'N',        10001330, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_POST_TEST_900_COUNSELING
    (22004000, GETDATE(), 10009282, N'N',        10001331, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_REFER_FOR_900_CARE_IND
    (22004000, GETDATE(), 10009282, N'1',        10001332, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_KEEP_900_CARE_APPT_IND
    (22004000, GETDATE(), 10009282, N'N',        10001333, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_AV_THERAPY_LAST_12MO_IND
    (22004000, GETDATE(), 10009282, N'N',        10001334, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- HIV_AV_THERAPY_EVER_IND

    -- ---- D_INV_SOCIAL_HISTORY (14 cols) ----
    (22004000, GETDATE(), 10009282, N'N',        10001283, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_PLACES_TO_MEET_PARTNER
    (22004000, GETDATE(), 10009282, N'N',        10001285, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_PLACES_TO_HAVE_SEX
    (22004000, GETDATE(), 10009282, N'N',        10001287, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_FEMALE_PRTNRS_12MO_IND
    (22004000, GETDATE(), 10009282, N'0',        10001288, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_FEMALE_PRTNRS_12MO_TTL (NUMERIC)
    (22004000, GETDATE(), 10009282, N'1',        10001289, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_MALE_PRTNRS_12MO_IND
    (22004000, GETDATE(), 10009282, N'2',        10001290, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_MALE_PRTNRS_12MO_TOTAL (NUMERIC)
    (22004000, GETDATE(), 10009282, N'N',        10001291, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_TRANSGNDR_PRTNRS_12MO_IND
    (22004000, GETDATE(), 10009282, N'0',        10001292, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_TRANSGNDR_PRTNRS_12MO_TTL (NUMERIC)
    (22004000, GETDATE(), 10009282, N'N',        10001296, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_PRTNRS_PRD_FML_IND
    (22004000, GETDATE(), 10009282, N'0',        10001297, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_PRTNRS_PRD_FML_TTL (NUMERIC)
    (22004000, GETDATE(), 10009282, N'N',        10001298, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_PRTNRS_PRD_MALE_IND
    (22004000, GETDATE(), 10009282, N'2',        10001299, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_PRTNRS_PRD_MALE_TTL (NUMERIC)
    (22004000, GETDATE(), 10009282, N'N',        10001300, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_PRTNRS_PRD_TRNSGNDR_IND
    (22004000, GETDATE(), 10009282, N'0',        10001301, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_PRTNRS_PRD_TRNSGNDR_TTL -> STD_PRTNRS_PRD_TRNSGNDR_TTL (NUMERIC)
    (22004000, GETDATE(), 10009282, N'N',        10001302, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOC_SX_PRTNRS_INTNT_12MO_IND

    -- ---- D_INV_PATIENT_OBS (11 IPO_* cols) ----
    (22004000, GETDATE(), 10009282, N'N',        10001166, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- IPO_CURRENTLY_IN_INSTITUTION
    (22004000, GETDATE(), 10009282, N'Lives alone', 10001158, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- IPO_LIVING_WITH (TEXT)
    (22004000, GETDATE(), 10009282, N'N/A',      10001167, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- IPO_NAME_OF_INSTITUTITION (TEXT)
    (22004000, GETDATE(), 10009282, N'24',       10001160, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- IPO_TIME_AT_ADDRESS_NUM (NUMERIC)
    (22004000, GETDATE(), 10009282, N'M',        10001161, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- IPO_TIME_AT_ADDRESS_UNIT
    (22004000, GETDATE(), 10009282, N'30',       10001164, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- IPO_TIME_IN_COUNTRY_NUM (NUMERIC)
    (22004000, GETDATE(), 10009282, N'M',        10001165, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- IPO_TIME_IN_COUNTRY_UNIT
    (22004000, GETDATE(), 10009282, N'30',       10001162, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- IPO_TIME_IN_STATE_NUM (NUMERIC)
    (22004000, GETDATE(), 10009282, N'M',        10001163, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- IPO_TIME_IN_STATE_UNIT
    (22004000, GETDATE(), 10009282, N'C',        10001168, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- IPO_TYPE_OF_INSTITUTITION
    (22004000, GETDATE(), 10009282, N'A',        10001159, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- IPO_TYPE_OF_RESIDENCE

    -- ---- D_INV_CONTACT (10 RPT_* cols) ----
    (22004000, GETDATE(), 10009282, N'2026-04-01', 10001182, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CTT_RPT_FIRST_SEX_EXP_DT -> RPT_FIRST_SEX_EXP_DT (DATE)
    (22004000, GETDATE(), 10009282, N'RTRfix',   10001183, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CTT_RPT_SEX_EXP_FREQ -> RPT_SEX_EXP_FREQ (TEXT)
    (22004000, GETDATE(), 10009282, N'2026-04-01', 10001184, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CTT_RPT_LAST_SEX_EXP_DT -> RPT_LAST_SEX_EXP_DT (DATE)
    (22004000, GETDATE(), 10009282, N'2026-04-01', 10001185, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CTT_RPT_FIRST_NDLSHARE_EXP_DT -> RPT_FIRST_NDLSHARE_EXP_DT (DATE)
    (22004000, GETDATE(), 10009282, N'RTRfix',   10001186, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CTT_RPT_NDLSHARE_EXP_FREQ -> RPT_NDLSHARE_EXP_FREQ (TEXT)
    (22004000, GETDATE(), 10009282, N'2026-04-01', 10001187, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CTT_RPT_LAST_NDLSHARE_EXP_DT -> RPT_LAST_NDLSHARE_EXP_DT (DATE)
    (22004000, GETDATE(), 10009282, N'ASC',      10001188, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CTT_RPT_RELATIONSHIP_TO_OP -> RPT_RELATIONSHIP_TO_OP
    (22004000, GETDATE(), 10009282, N'C',        10001189, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CTT_RPT_SPOUSE_OF_OP -> RPT_SPOUSE_OF_OP
    (22004000, GETDATE(), 10009282, N'N',        10001190, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CTT_RPT_MET_OP_INTERNET -> RPT_MET_OP_INTERNET
    (22004000, GETDATE(), 10009282, N'N',        10001191, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CTT_RPT_ELICIT_INTERNET_INFO -> RPT_ELICIT_INTERNET_INFO

    -- ---- D_INV_LAB_FINDING (9 LAB_* cols) ----
    (22004000, GETDATE(), 10009282, N'N',        10001304, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- LAB_TESTS_PERFORMED
    (22004000, GETDATE(), 10009282, N'1',        10001305, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- LAB_NONTREP_SYPH_TEST_TYP
    (22004000, GETDATE(), 10009282, N'1',        10001306, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- LAB_NONTREP_SYPH_RSLT_QNT
    (22004000, GETDATE(), 10009282, N'1',        10001307, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- LAB_NONTREP_SYPH_RSLT_QUA
    (22004000, GETDATE(), 10009282, N'1',        10001308, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- LAB_TREP_SYPH_TEST_TYPE
    (22004000, GETDATE(), 10009282, N'1',        10001309, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- LAB_TREP_SYPH_RESULT_QUAL
    (22004000, GETDATE(), 10009282, N'N',        10003232, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- LAB_SYPHILIS_TST_PS_IND
    (22004000, GETDATE(), 10009282, N'1',        10003233, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- LAB_SYPHILIS_TST_RSLT_PS
    (22004000, GETDATE(), 10009282, N'2026-04-01', 10003234, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- LAB_HIV_SPECIMEN_COLL_DT (DATE)

    -- ---- D_INV_PREGNANCY_BIRTH (8 PBI_* cols) ----
    (22004000, GETDATE(), 10009282, N'1',        10001252, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- PBI_PATIENT_PREGNANT_WKS (NUMERIC)
    (22004000, GETDATE(), 10009282, N'N',        10001253, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- PBI_PREG_AT_EXAM_IND
    (22004000, GETDATE(), 10009282, N'1',        10001254, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- PBI_PREG_AT_EXAM_WKS (NUMERIC)
    (22004000, GETDATE(), 10009282, N'N',        10001255, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- PBI_PREG_AT_IX_IND
    (22004000, GETDATE(), 10009282, N'1',        10001256, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- PBI_PREG_AT_IX_WKS (NUMERIC)
    (22004000, GETDATE(), 10009282, N'N',        10001257, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- PBI_IN_PRENATAL_CARE_IND
    (22004000, GETDATE(), 10009282, N'N',        10001258, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- PBI_PREG_IN_LAST_12MO_IND
    (22004000, GETDATE(), 10009282, N'A',        10001259, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- PBI_PREG_OUTCOME_CD -> PBI_PREG_OUTCOME

    -- ---- D_INV_CLINICAL (7 CLN_* cols) ----
    (22004000, GETDATE(), 10009282, N'2026-04-01', 10001193, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CLN_DT_INIT_HLTH_EXM (DATE)
    (22004000, GETDATE(), 10009282, N'100',      10001195, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CLN_CASE_DIAGNOSIS -> DIAGNOSIS / DIAGNOSIS_CD
    (22004000, GETDATE(), 10009282, N'C',        10001197, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CLN_NEUROSYPHILLIS_IND
    (22004000, GETDATE(), 10009282, N'aripiprazole', 10001200, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CLN_CONDITION_RESISTANT_TO (CODED; reuse generator-proven code)
    (22004000, GETDATE(), 10009282, N'1',        10003228, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CLN_CARE_STATUS_CLOSE_DT
    (22004000, GETDATE(), 10009282, N'N',        10003230, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CLN_PRE_EXP_PROPHY_IND
    (22004000, GETDATE(), 10009282, N'1',        10003231, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CLN_PRE_EXP_PROPHY_REFER

    -- ---- D_INV_SYMPTOM (4 SYM_* cols) ----
    (22004000, GETDATE(), 10009282, N'15188001', 10002135, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SYM_NEUROLOGIC_SIGN_SYM
    (22004000, GETDATE(), 10009282, N'C',        10002136, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SYM_OCULAR_MANIFESTATIONS
    (22004000, GETDATE(), 10009282, N'C',        10002137, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SYM_OTIC_MANIFESTATION
    (22004000, GETDATE(), 10009282, N'C',        10002138, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SYM_LATE_CLINICAL_MANIFES

    -- ---- D_INV_ADMINISTRATIVE (3 cols: ADM_REFERRAL_BASIS_OOJ, ADM_RPTNG_CNTY, DISSEMINATED_IND) ----
    (22004000, GETDATE(), 10009282, N'A1',       10001177, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- ADM_REFERRAL_BASIS_OOJ
    (22004000, GETDATE(), 10009282, N'Y',        10001005, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- ADM_RPTNG_CNTY
    (22004000, GETDATE(), 10009282, N'N',        10001198, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- ADM_DISSEMINATED_IND -> DISSEMINATED_IND

    -- ---- D_INV_COMPLICATION (2 cols) ----
    (22004000, GETDATE(), 10009282, N'N',        10001196, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CMP_PID_IND
    (22004000, GETDATE(), 10009282, N'N',        10001199, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- CMP_CONJUNCTIVITIS_IND

    -- ---- D_INV_EPIDEMIOLOGY (2 cols) ----
    (22004000, GETDATE(), 10009282, N'100',      10001007, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- EPI_CNTRY_USUAL_RESID
    (22004000, GETDATE(), 10009282, N'SO',       10001194, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- SOURCE_SPREAD

    -- ---- D_INV_MEDICAL_HISTORY (2 cols) ----
    (22004000, GETDATE(), 10009282, N'N',        10001316, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- MDH_PREV_STD_HIST
    (22004000, GETDATE(), 10009282, N'2026-04-01', 10003229, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL), -- MDH_PROVIDER_REASON_VISIT_DT -> PROVIDER_REASON_VISIT_DT (DATE)

    -- ---- D_INV_TREATMENT (1 col) ----
    (22004000, GETDATE(), 10009282, N'2026-04-01', 10001192, 1, GETDATE(), 10009282, N'ACTIVE', GETDATE(), 0, NULL); -- TRT_TREATMENT_DATE (DATE)
END
GO

-- ---------------------------------------------------------------------
-- Re-trigger CDC -> service so sp_investigation_event re-runs for the STD
-- PHC AFTER these NULL-group answers exist. This recomputes
-- nrt_investigation.rdb_table_name_list and drives the Step-9 page-builder
-- rebuild of the D_INV_* dims -> F_STD_PAGE_CASE -> STD_HIV_DATAMART.
-- Same last_chg_time bump pattern used by
-- zz_page_answers_datamart_routing.sql and zz_tb_fact_chain.sql.
-- (This bump runs AFTER the generic generator's bump because this fixture
-- sorts after zz_page_answers_datamart_routing.sql in the Tier-3 apply.)
-- ---------------------------------------------------------------------
UPDATE [dbo].[public_health_case]
   SET last_chg_time = GETDATE()
 WHERE public_health_case_uid = 22004000;
GO
