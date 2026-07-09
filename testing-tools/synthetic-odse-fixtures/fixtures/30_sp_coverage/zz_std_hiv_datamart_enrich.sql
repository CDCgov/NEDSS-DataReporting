-- =====================================================================
-- Tier 3 — STD_HIV_DATAMART enrichment (ODSE-only) for PHC 22004000
-- =====================================================================
-- CONVERTED 2026-06-05 to ODSE-only authoring (was: direct RDB_MODERN
-- writes). PRINCIPLE: fixtures author ONLY NBS_ODSE rows; the RTR
-- pipeline derives everything in RDB_MODERN.
--
-- WHAT THIS FIXTURE NOW AUTHORS
--   ODSE dbo.nbs_case_answer rows for the PG_STD_Investigation-form
--   questions of NINE topic categories on the existing STD Syphilis-
--   primary investigation PHC 22004000 (act/public_health_case/
--   case_management authored by std_hiv_investigation_full_chain.sql):
--       LAB_FINDING, MEDICAL_HISTORY, PATIENT_OBS, PREGNANCY_BIRTH,
--       RISK_FACTOR, SOCIAL_HISTORY, SYMPTOM, TREATMENT, CONTACT
--   The full CDC pipeline + reporting-pipeline-service derive
--   nrt_page_case_answer from these answers, then the page-builder
--   chain (011 sp_page_builder_postprocessing -> 007 sp_s_* / 008 sp_l_*
--   / 009 sp_d_* via dynamic 'INSERT INTO [dbo].'+@rdb_table_name)
--   builds each D_INV_<category> + L_INV_<category> pair, which
--   sp_std_hiv_datamart_postprocessing (026) then reads.
--
-- WHY THIS IS THE CORRECT CONVERSION (corrects this file's old header)
--   The per-topic D_INV_<category>/L_INV_<category> tables are NOT
--   "MasterETL-only, never written by RTR" (the prior header's claim
--   was a dynamic-SQL grep false-negative). They ARE RTR-derived:
--   011 sp_page_builder_postprocessing fans out to 009/008/007 which
--   INSERT into D_INV_<cat>/L_INV_<cat> via EXEC sp_executesql on a
--   dynamic table name. So hand-writing those RDB_MODERN rows was the
--   violation; authoring nbs_case_answer is the supported path. Model:
--   tb_investigation_full_chain.sql / varicella_investigation_full_chain.sql
--   (RVCT/VAR answers -> topic dims; validated live).
--
-- QUESTION -> CATEGORY -> COLUMN MAPPING (discovered live 2026-06-05)
--   NBS_ODSE.dbo.NBS_rdb_metadata m
--     JOIN NBS_ODSE.dbo.nbs_ui_metadata u ON u.nbs_ui_metadata_uid =
--          m.nbs_ui_metadata_uid
--    WHERE u.investigation_form_cd = 'PG_STD_Investigation'
--      AND m.rdb_table_nm = 'D_INV_<category>'
--   gives (nbs_question_uid, question_identifier, data_type,
--   code_set_group_id, rdb_column_nm). CODED answer codes were taken
--   from RDB_MODERN.dbo.v_nrt_ref_formcode_translation for the same
--   (investigation_form_cd, nbs_question_uid) so every coded answer
--   resolves (007 step 12/19 DELETEs answers whose code does not
--   translate). Dates 'YYYY-MM-DD'; numerics plain integers.
--
-- UID BLOCK (this fixture): nbs_case_answer.nbs_case_answer_uid
--   22012100 .. 22012186   (IDENTITY_INSERT-pinned; distinct from the
--   sister std_hiv_investigation_full_chain.sql block and from
--   zz_std_dedicated_entities.sql 22057xxx). seq_nbr = 0; the pipeline
--   keys answers on (act_uid, nbs_question_uid, seq_nbr) so the
--   surrogate UID is purely for stable cross-fixture reference.
--
-- COORDINATION (same PHC 22004000, parallel conversions)
--   - std_hiv_investigation_full_chain.sql owns the 5 categories
--     HIV / ADMINISTRATIVE / CLINICAL / EPIDEMIOLOGY / COMPLICATION.
--     This fixture does NOT author any of those questions (disjoint
--     nbs_question_uid sets), so the two are additive on the same PHC.
--   - The old UPDATE of D_INV_HIV (HIV_CA_900_OTH_RSN_NOT_LO /
--     HIV_CA_900_REASON_NOT_LOC) is DROPPED: those two columns are not
--     mapped to any PG_STD_Investigation-form question in
--     NBS_rdb_metadata (verified — zero rows), so they cannot be
--     authored as STD-form answers on this Syphilis PHC. The old
--     UPDATE of D_INV_EPIDEMIOLOGY.SOURCE_SPREAD is also DROPPED:
--     SOURCE_SPREAD (question NBS135) is an EPIDEMIOLOGY-category column
--     owned by the sister fixture.
--   - The old UPDATE of D_PATIENT (foundation 20000000) is DROPPED:
--     D_PATIENT is derived by 004/365 from ODSE person, and a dedicated
--     rich STD patient (22057000) is already authored and repointed onto
--     PHC 22004000 by zz_std_dedicated_entities.sql (which supersedes the
--     foundation SubjOfPHC). That fixture already fills the PATIENT_*
--     columns the datamart reads — the old D_PATIENT UPDATE was both a
--     shared-dim violation AND dead (the investigation no longer points
--     at patient 20000000).
--   - The old UPDATE of D_CASE_MANAGEMENT (OOJ_INITG_AGNCY_* dates) is
--     DROPPED: D_CASE_MANAGEMENT is derived by 022 from
--     NBS_ODSE.dbo.case_management, and zz_std_case_management.sql
--     already enriches the per-investigation case_management row
--     (case_management_uid 22004001) including
--     ooj_initg_agncy_recd_date / _outc_due_date / _outc_snt_date.
--
-- ORCHESTRATOR (report-only; this fixture EDITS nothing there)
--   No change required:
--     * 22004000 is already in scripts/merge_and_verify.sh PHC_UIDS.
--     * The page-builder / D_INV_<cat> / L_INV_<cat> derivation runs
--       inside the Tier-3 CDC drain + the dyn_dm STD chain
--       (sp_dyn_dm_main_postprocessing over PHC_UIDS), and
--       sp_f_std_page_case_postprocessing / sp_std_hiv_datamart_post-
--       processing already run over PHC_UIDS at Step 9.
--
-- NO tail-EXEC here (Step 9 / the service own all SP runs).
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;
DECLARE @std_phc_uid  bigint = 22004000;

-- Idempotency guard on the natural-key sentinel (first authored answer).
-- IDENTITY_INSERT pins our distinct UID block 22012100..22012186.
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @std_phc_uid AND nbs_question_uid = 10003234
                 AND nbs_case_answer_uid = 22012100)
BEGIN
    SET IDENTITY_INSERT [dbo].[nbs_case_answer] ON;

    INSERT INTO [dbo].[nbs_case_answer]
        ([nbs_case_answer_uid], [act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
    -- ===== D_INV_LAB_FINDING (9 cols) =====
    (22012100, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-15', 10003234, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS450 LAB_HIV_SPECIMEN_COLL_DT (DATE)
    (22012101, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'1',          10001306, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD123 LAB_NONTREP_SYPH_RSLT_QNT (1:1)
    (22012102, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'1',          10001307, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD126 LAB_NONTREP_SYPH_RSLT_QUA
    (22012103, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'1',          10001305, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD122 LAB_NONTREP_SYPH_TEST_TYP
    (22012104, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10003232, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS447 LAB_SYPHILIS_TST_PS_IND
    (22012105, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'1',          10003233, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS448 LAB_SYPHILIS_TST_RSLT_PS
    (22012106, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001304, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS275 LAB_TESTS_PERFORMED
    (22012107, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'1',          10001309, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD125 LAB_TREP_SYPH_RESULT_QUAL
    (22012108, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'1',          10001308, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD124 LAB_TREP_SYPH_TEST_TYPE

    -- ===== D_INV_MEDICAL_HISTORY (2 cols) =====
    (22012109, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001316, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD117 MDH_PREV_STD_HIST
    (22012110, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-20', 10003229, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS302 MDH_PROVIDER_REASON_VISIT_DT (DATE)

    -- ===== D_INV_PATIENT_OBS (12 cols) =====
    (22012111, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',          10001166, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS209 IPO_CURRENTLY_IN_INSTITUTION
    (22012112, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Partner',    10001158, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS201 IPO_LIVING_WITH (TEXT)
    (22012113, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N/A',        10001167, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS210 IPO_NAME_OF_INSTITUTITION (TEXT)
    (22012114, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'1',          10001075, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- INV592 IPO_SEXUAL_PREF
    (22012115, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'24',         10001160, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS203 IPO_TIME_AT_ADDRESS_NUM (NUMERIC)
    (22012116, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001161, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS204 IPO_TIME_AT_ADDRESS_UNIT (Years)
    (22012117, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'30',         10001164, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS207 IPO_TIME_IN_COUNTRY_NUM (NUMERIC)
    (22012118, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001165, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS208 IPO_TIME_IN_COUNTRY_UNIT (Years)
    (22012119, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'30',         10001162, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS205 IPO_TIME_IN_STATE_NUM (NUMERIC)
    (22012120, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001163, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS206 IPO_TIME_IN_STATE_UNIT (Years)
    (22012121, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001168, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS211 IPO_TYPE_OF_INSTITUTITION
    (22012122, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001159, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS202 IPO_TYPE_OF_RESIDENCE

    -- ===== D_INV_PREGNANCY_BIRTH (8 cols; male index patient -> 'N'/0) =====
    (22012123, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',          10001257, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS220 PBI_IN_PRENATAL_CARE_IND
    (22012124, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'0',          10001252, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS128 PBI_PATIENT_PREGNANT_WKS (NUMERIC)
    (22012125, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',          10001253, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS216 PBI_PREG_AT_EXAM_IND
    (22012126, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'0',          10001254, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS217 PBI_PREG_AT_EXAM_WKS (NUMERIC)
    (22012127, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',          10001255, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS218 PBI_PREG_AT_IX_IND
    (22012128, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'0',          10001256, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS219 PBI_PREG_AT_IX_WKS (NUMERIC)
    (22012129, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',          10001258, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS221 PBI_PREG_IN_LAST_12MO_IND
    (22012130, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'A',          10001259, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS222 PBI_PREG_OUTCOME_CD

    -- ===== D_INV_RISK_FACTOR (24 coded + 1 text + 1 numeric) =====
    (22012131, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001294, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD888 RSK_ANS_REFUSED_SEX_PARTNER
    (22012132, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001271, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD118 RSK_BEEN_INCARCERATD_12MO_IND
    (22012133, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001275, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS237 RSK_COCAINE_USE_12MO_IND
    (22012134, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001276, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS235 RSK_CRACK_USE_12MO_IND
    (22012135, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001280, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS238 RSK_ED_MEDS_USE_12MO_IND
    (22012136, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001277, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS239 RSK_HEROIN_USE_12MO_IND
    (22012137, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001272, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD114 RSK_INJ_DRUG_USE_12MO_IND
    (22012138, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001278, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS234 RSK_METH_USE_12MO_IND
    (22012139, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001279, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS236 RSK_NITR_POP_USE_12MO_IND
    (22012140, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001274, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS233 RSK_NO_DRUG_USE_12MO_IND
    (22012141, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001281, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS240 RSK_OTHER_DRUG_USE_12MO_IND
    (22012142, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'1',          10001261, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS229 RSK_RISK_FACTORS_ASSESS_IND
    (22012143, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001268, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD112 RSK_SEX_EXCH_DRGS_MNY_12MO_IND
    (22012144, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001267, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD111 RSK_SEX_INTOXCTED_HGH_12MO_IND
    (22012145, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001265, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD109 RSK_SEX_W_ANON_PTRNR_12MO_IND
    (22012146, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001263, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD108 RSK_SEX_W_FEMALE_12MO_IND
    (22012147, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001270, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD110 RSK_SEX_W_KNOWN_IDU_12MO_IND
    (22012148, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001269, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD113 RSK_SEX_W_KNWN_MSM_12M_FML_IND
    (22012149, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001262, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD107 RSK_SEX_W_MALE_12MO_IND
    (22012150, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001264, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS230 RSK_SEX_W_TRANSGNDR_12MO_IND
    (22012151, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001266, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS231 RSK_SEX_WOUT_CONDOM_12MO_IND
    (22012152, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001273, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS232 RSK_SHARED_INJ_EQUIP_12MO_IND
    (22012153, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'TGTPOP1',    10001303, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS271 RSK_TARGET_POPULATIONS
    (22012154, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001295, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD999 RSK_UNK_SEX_PARTNERS
    (22012155, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'None',       10001282, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD300 RSK_OTHER_DRUG_SPEC (TEXT)
    (22012156, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'3',          10001293, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD120 RSK_NUM_SEX_PARTNER_12MO (NUMERIC)

    -- ===== D_INV_SOCIAL_HISTORY (9 coded + 6 numeric) =====
    (22012157, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001287, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS223 SOC_FEMALE_PRTNRS_12MO_IND
    (22012158, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'1',          10001288, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS224 SOC_FEMALE_PRTNRS_12MO_TTL (NUMERIC)
    (22012159, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001289, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS225 SOC_MALE_PRTNRS_12MO_IND
    (22012160, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2',          10001290, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS226 SOC_MALE_PRTNRS_12MO_TOTAL (NUMERIC)
    (22012161, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001285, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS244 SOC_PLACES_TO_HAVE_SEX
    (22012162, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001283, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS242 SOC_PLACES_TO_MEET_PARTNER
    (22012163, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001296, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS129 SOC_PRTNRS_PRD_FML_IND
    (22012164, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'1',          10001297, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS130 SOC_PRTNRS_PRD_FML_TTL (NUMERIC)
    (22012165, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001298, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS131 SOC_PRTNRS_PRD_MALE_IND
    (22012166, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2',          10001299, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS132 SOC_PRTNRS_PRD_MALE_TTL (NUMERIC)
    (22012167, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001300, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS133 SOC_PRTNRS_PRD_TRNSGNDR_IND
    (22012168, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'0',          10001301, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS134 SOC_PRTNRS_PRD_TRNSGNDR_TTL (NUMERIC)
    (22012169, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001302, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD119 SOC_SX_PRTNRS_INTNT_12MO_IND
    (22012170, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001291, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS227 SOC_TRANSGNDR_PRTNRS_12MO_IND
    (22012171, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'0',          10001292, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS228 SOC_TRANSGNDR_PRTNRS_12MO_TTL (NUMERIC)

    -- ===== D_INV_SYMPTOM (4 cols) =====
    (22012172, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',          10002138, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- 72083004 SYM_LATE_CLINICAL_MANIFES
    (22012173, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'84387000',   10002135, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- 102957003 SYM_NEUROLOGIC_SIGN_SYM (Asymptomatic)
    (22012174, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',          10002136, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- 410478005 SYM_OCULAR_MANIFESTATIONS
    (22012175, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',          10002137, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- PHC1472 SYM_OTIC_MANIFESTATION

    -- ===== D_INV_TREATMENT (1 col) =====
    (22012176, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-04-10', 10001192, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- STD105 TRT_TREATMENT_DATE (DATE)

    -- ===== D_INV_CONTACT (10 cols) =====
    (22012177, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001191, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS127 CTT_RPT_ELICIT_INTERNET_INFO
    (22012178, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-01-01', 10001185, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS121 CTT_RPT_FIRST_NDLSHARE_EXP_DT (DATE)
    (22012179, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-01-15', 10001182, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS118 CTT_RPT_FIRST_SEX_EXP_DT (DATE)
    (22012180, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-01', 10001187, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS123 CTT_RPT_LAST_NDLSHARE_EXP_DT (DATE)
    (22012181, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-15', 10001184, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS120 CTT_RPT_LAST_SEX_EXP_DT (DATE)
    (22012182, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',          10001190, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS126 CTT_RPT_MET_OP_INTERNET
    (22012183, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Never',      10001186, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS122 CTT_RPT_NDLSHARE_EXP_FREQ (TEXT)
    (22012184, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'SPO',        10001188, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS124 CTT_RPT_RELATIONSHIP_TO_OP (Spouse)
    (22012185, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Weekly',     10001183, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- NBS119 CTT_RPT_SEX_EXP_FREQ (TEXT)
    (22012186, @std_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',          10001189, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0); -- NBS125 CTT_RPT_SPOUSE_OF_OP

    SET IDENTITY_INSERT [dbo].[nbs_case_answer] OFF;
END
GO

-- =====================================================================
-- CDC RE-TRIGGER (defensive): bump public_health_case.last_chg_time so
-- the Debezium/connect chain re-emits PHC 22004000 and the service
-- re-projects this investigation during the Tier-3 drain. The new
-- nbs_case_answer rows are themselves captured by table-level CDC, so
-- this is belt-and-suspenders. GETDATE() so this wins any prior literal
-- bump in the STD fixture set. (Investigation's OWN row, not a shared
-- dim; no nrt_* INSERT, no EXEC sp_.)
-- =====================================================================
UPDATE [dbo].[public_health_case]
   SET last_chg_time = GETDATE()
 WHERE public_health_case_uid = 22004000;
GO
