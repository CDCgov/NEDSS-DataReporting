-- =====================================================================
-- Tier 3 — STD_HIV_DATAMART enrichment (sibling of std_hiv_investigation_full_chain.sql)
-- =====================================================================
-- Goal: lift STD_HIV_DATAMART column coverage from baseline 135/248
-- toward 200+/248 by enriching the existing 22004000 STD Syphilis
-- Investigation full chain with the remaining D_INV_* dimensions
-- referenced by sp_std_hiv_datamart_postprocessing.
--
-- ASSEMBLY MODEL
--   The sister fixture `std_hiv_investigation_full_chain.sql` already
--   authored:
--     - PHC 22004000 (Syphilis primary, PG_STD_Investigation)
--     - 5 D_INV_* + L_INV_* pairs:
--         HIV (22004100), ADMINISTRATIVE (22004110), CLINICAL (22004120),
--         EPIDEMIOLOGY (22004130), COMPLICATION (22004140)
--     - F_STD_PAGE_CASE row (INVESTIGATION_KEY=22)
--     - STD_HIV_DATAMART row (135/248 cols populated)
--
--   sp_std_hiv_datamart_postprocessing (026 lines 176-572) reads 11
--   additional D_INV_* dimensions plus D_PATIENT, D_CASE_MANAGEMENT,
--   and INV_HIV. This enrichment authors the missing 9 D_INV_* +
--   L_INV_* pairs, UPDATEs the existing D_INV_HIV / D_INV_EPIDEMIOLOGY
--   for missing columns, UPDATEs the foundation D_PATIENT row for
--   columns it doesn't already supply, and UPDATEs D_CASE_MANAGEMENT
--   for the OOJ_INITG_AGNCY_* fields.
--
-- WHY THIS APPROACH
--   - The 9 unauthored L_INV_*/D_INV_* pairs are MasterETL-only
--     persistent tables read by RTR datamart SPs (see
--     odse_unknown_tables.md row group at line 76). Hand-authoring is
--     the convention established by std_hiv_investigation_full_chain.sql.
--   - D_PATIENT is shared with the foundation patient (20000000). Both
--     existing STD_HIV_DATAMART rows reference PATIENT_KEY=3 — UPDATEs
--     here lift both rows. Foundation values that ARE populated
--     (FIRST_NAME, LAST_NAME, RACE, ETHNICITY, etc.) are NOT modified.
--
-- UID ALLOCATION (within reserved block 22012000-22012999)
--   22012100  D_INV_LAB_FINDING.D_INV_LAB_FINDING_KEY
--   22012110  D_INV_MEDICAL_HISTORY.D_INV_MEDICAL_HISTORY_KEY
--   22012120  D_INV_PATIENT_OBS.D_INV_PATIENT_OBS_KEY
--   22012130  D_INV_PREGNANCY_BIRTH.D_INV_PREGNANCY_BIRTH_KEY
--   22012140  D_INV_RISK_FACTOR.D_INV_RISK_FACTOR_KEY
--   22012150  D_INV_SOCIAL_HISTORY.D_INV_SOCIAL_HISTORY_KEY
--   22012160  D_INV_SYMPTOM.D_INV_SYMPTOM_KEY
--   22012170  D_INV_TREATMENT.D_INV_TREATMENT_KEY
--   22012180  D_INV_CONTACT.D_INV_CONTACT_KEY
--
-- DOES NOT TOUCH
--   - PHC 22004000 act/public_health_case/case_management (authored
--     by std_hiv_investigation_full_chain.sql)
--   - The orchestrator (this fixture runs in standalone-fixture mode
--     because PHC 22004000 is already in PHC_UIDS via the prior round;
--     re-EXECing sp_std_hiv_datamart_postprocessing is safe because the
--     SP does DELETE-then-INSERT per @phc_id at lines 1248-1260).
--
-- VERIFICATION CALL-CHAIN (tail-EXECs at bottom)
--   sp_f_std_page_case_postprocessing(@phc_id_list=N'22004000')
--   sp_std_hiv_datamart_postprocessing(@phc_id=N'22004000')
--
-- ORCH_TODO
--   None. PHC 22004000 is already in scripts/merge_and_verify.sh
--   PHC_UIDS (per coverage_std_hiv_full_chain.md recommendation;
--   parent agent action).
-- =====================================================================

USE [RDB_MODERN];
GO

BEGIN TRY

-- =====================================================================
-- 1. D_INV_LAB_FINDING (LF in SP alias) -> 9 LAB_* cols on STD_HIV_DATAMART
--    Cols: LAB_HIV_SPECIMEN_COLL_DT, LAB_NONTREP_SYPH_RSLT_QNT,
--          LAB_NONTREP_SYPH_RSLT_QUA, LAB_NONTREP_SYPH_TEST_TYP,
--          LAB_SYPHILIS_TST_PS_IND, LAB_SYPHILIS_TST_RSLT_PS,
--          LAB_TESTS_PERFORMED, LAB_TREP_SYPH_RESULT_QUAL,
--          LAB_TREP_SYPH_TEST_TYPE
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[D_INV_LAB_FINDING] WHERE D_INV_LAB_FINDING_KEY = 22012100)
BEGIN
    INSERT INTO [dbo].[D_INV_LAB_FINDING]
        ([D_INV_LAB_FINDING_KEY], [nbs_case_answer_uid],
         [LAB_HIV_SPECIMEN_COLL_DT], [LAB_NONTREP_SYPH_RSLT_QNT],
         [LAB_NONTREP_SYPH_RSLT_QUA], [LAB_NONTREP_SYPH_TEST_TYP],
         [LAB_SYPHILIS_TST_PS_IND], [LAB_SYPHILIS_TST_RSLT_PS],
         [LAB_TESTS_PERFORMED], [LAB_TREP_SYPH_RESULT_QUAL],
         [LAB_TREP_SYPH_TEST_TYPE])
    VALUES
        (22012100, 22012100,
         '2026-03-15', N'1:16',
         N'Reactive', N'RPR',
         N'Yes', N'Reactive',
         N'RPR;TPPA', N'Reactive',
         N'TPPA');
END;

IF NOT EXISTS (SELECT 1 FROM [dbo].[L_INV_LAB_FINDING] WHERE PAGE_CASE_UID = 22004000 AND D_INV_LAB_FINDING_KEY = 22012100)
BEGIN
    INSERT INTO [dbo].[L_INV_LAB_FINDING] ([PAGE_CASE_UID], [D_INV_LAB_FINDING_KEY])
    VALUES (22004000, 22012100);
END;

-- =====================================================================
-- 2. D_INV_MEDICAL_HISTORY (MH alias) -> 2 cols
--    MDH_PREV_STD_HIST, PROVIDER_REASON_VISIT_DT (PROVIDER_REASON_VISIT_DT=MH.MDH_PROVIDER_REASON_VISIT_DT)
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[D_INV_MEDICAL_HISTORY] WHERE D_INV_MEDICAL_HISTORY_KEY = 22012110)
BEGIN
    INSERT INTO [dbo].[D_INV_MEDICAL_HISTORY]
        ([D_INV_MEDICAL_HISTORY_KEY], [nbs_case_answer_uid],
         [MDH_PREV_STD_HIST], [MDH_PROVIDER_REASON_VISIT_DT])
    VALUES
        (22012110, 22012110,
         N'Yes', '2026-03-20');
END;

IF NOT EXISTS (SELECT 1 FROM [dbo].[L_INV_MEDICAL_HISTORY] WHERE PAGE_CASE_UID = 22004000 AND D_INV_MEDICAL_HISTORY_KEY = 22012110)
BEGIN
    INSERT INTO [dbo].[L_INV_MEDICAL_HISTORY] ([PAGE_CASE_UID], [D_INV_MEDICAL_HISTORY_KEY])
    VALUES (22004000, 22012110);
END;

-- =====================================================================
-- 3. D_INV_PATIENT_OBS (OBS alias) -> 11 IPO_* cols
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[D_INV_PATIENT_OBS] WHERE D_INV_PATIENT_OBS_KEY = 22012120)
BEGIN
    INSERT INTO [dbo].[D_INV_PATIENT_OBS]
        ([D_INV_PATIENT_OBS_KEY], [nbs_case_answer_uid],
         [IPO_CURRENTLY_IN_INSTITUTION], [IPO_LIVING_WITH],
         [IPO_NAME_OF_INSTITUTITION],
         [IPO_TIME_AT_ADDRESS_NUM], [IPO_TIME_AT_ADDRESS_UNIT],
         [IPO_TIME_IN_COUNTRY_NUM], [IPO_TIME_IN_COUNTRY_UNIT],
         [IPO_TIME_IN_STATE_NUM], [IPO_TIME_IN_STATE_UNIT],
         [IPO_TYPE_OF_INSTITUTITION], [IPO_TYPE_OF_RESIDENCE])
    VALUES
        (22012120, 22012120,
         N'No', N'Family',
         N'N/A',
         N'24', N'MONTHS',
         N'30', N'YEARS',
         N'30', N'YEARS',
         N'N/A', N'House');
END;

IF NOT EXISTS (SELECT 1 FROM [dbo].[L_INV_PATIENT_OBS] WHERE PAGE_CASE_UID = 22004000 AND D_INV_PATIENT_OBS_KEY = 22012120)
BEGIN
    INSERT INTO [dbo].[L_INV_PATIENT_OBS] ([PAGE_CASE_UID], [D_INV_PATIENT_OBS_KEY])
    VALUES (22004000, 22012120);
END;

-- =====================================================================
-- 4. D_INV_PREGNANCY_BIRTH (PBI alias) -> 8 PBI_* cols
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[D_INV_PREGNANCY_BIRTH] WHERE D_INV_PREGNANCY_BIRTH_KEY = 22012130)
BEGIN
    INSERT INTO [dbo].[D_INV_PREGNANCY_BIRTH]
        ([D_INV_PREGNANCY_BIRTH_KEY], [nbs_case_answer_uid],
         [PBI_IN_PRENATAL_CARE_IND], [PBI_PATIENT_PREGNANT_WKS],
         [PBI_PREG_AT_EXAM_IND], [PBI_PREG_AT_EXAM_WKS],
         [PBI_PREG_AT_IX_IND], [PBI_PREG_AT_IX_WKS],
         [PBI_PREG_IN_LAST_12MO_IND], [PBI_PREG_OUTCOME_CD])
    VALUES
        (22012130, 22012130,
         N'No', N'0',
         N'No', N'0',
         N'No', N'0',
         N'No', N'NA');
END;

IF NOT EXISTS (SELECT 1 FROM [dbo].[L_INV_PREGNANCY_BIRTH] WHERE PAGE_CASE_UID = 22004000 AND D_INV_PREGNANCY_BIRTH_KEY = 22012130)
BEGIN
    INSERT INTO [dbo].[L_INV_PREGNANCY_BIRTH] ([PAGE_CASE_UID], [D_INV_PREGNANCY_BIRTH_KEY])
    VALUES (22004000, 22012130);
END;

-- =====================================================================
-- 5. D_INV_RISK_FACTOR (RI alias) -> 24 RSK_* cols
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[D_INV_RISK_FACTOR] WHERE D_INV_RISK_FACTOR_KEY = 22012140)
BEGIN
    INSERT INTO [dbo].[D_INV_RISK_FACTOR]
        ([D_INV_RISK_FACTOR_KEY], [nbs_case_answer_uid],
         [RSK_BEEN_INCARCERATD_12MO_IND], [RSK_COCAINE_USE_12MO_IND],
         [RSK_CRACK_USE_12MO_IND], [RSK_ED_MEDS_USE_12MO_IND],
         [RSK_HEROIN_USE_12MO_IND], [RSK_INJ_DRUG_USE_12MO_IND],
         [RSK_METH_USE_12MO_IND], [RSK_NITR_POP_USE_12MO_IND],
         [RSK_NO_DRUG_USE_12MO_IND], [RSK_OTHER_DRUG_SPEC],
         [RSK_OTHER_DRUG_USE_12MO_IND], [RSK_RISK_FACTORS_ASSESS_IND],
         [RSK_SEX_EXCH_DRGS_MNY_12MO_IND], [RSK_SEX_INTOXCTED_HGH_12MO_IND],
         [RSK_SEX_W_ANON_PTRNR_12MO_IND], [RSK_SEX_W_FEMALE_12MO_IND],
         [RSK_SEX_W_KNOWN_IDU_12MO_IND], [RSK_SEX_W_KNWN_MSM_12M_FML_IND],
         [RSK_SEX_W_MALE_12MO_IND], [RSK_SEX_W_TRANSGNDR_12MO_IND],
         [RSK_SEX_WOUT_CONDOM_12MO_IND], [RSK_SHARED_INJ_EQUIP_12MO_IND],
         [RSK_TARGET_POPULATIONS])
    VALUES
        (22012140, 22012140,
         N'No', N'No',
         N'No', N'No',
         N'No', N'No',
         N'No', N'No',
         N'Yes', N'None',
         N'No', N'Yes',
         N'No', N'No',
         N'No', N'No',
         N'No', N'No',
         N'Yes', N'No',
         N'No', N'No',
         N'MSM');
END;

IF NOT EXISTS (SELECT 1 FROM [dbo].[L_INV_RISK_FACTOR] WHERE PAGE_CASE_UID = 22004000 AND D_INV_RISK_FACTOR_KEY = 22012140)
BEGIN
    INSERT INTO [dbo].[L_INV_RISK_FACTOR] ([PAGE_CASE_UID], [D_INV_RISK_FACTOR_KEY])
    VALUES (22004000, 22012140);
END;

-- =====================================================================
-- 6. D_INV_SOCIAL_HISTORY (SH alias) -> 14 SOC_*/STD_PRTNRS_* cols
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[D_INV_SOCIAL_HISTORY] WHERE D_INV_SOCIAL_HISTORY_KEY = 22012150)
BEGIN
    INSERT INTO [dbo].[D_INV_SOCIAL_HISTORY]
        ([D_INV_SOCIAL_HISTORY_KEY], [nbs_case_answer_uid],
         [SOC_FEMALE_PRTNRS_12MO_IND], [SOC_FEMALE_PRTNRS_12MO_TTL],
         [SOC_MALE_PRTNRS_12MO_IND], [SOC_MALE_PRTNRS_12MO_TOTAL],
         [SOC_PLACES_TO_HAVE_SEX], [SOC_PLACES_TO_MEET_PARTNER],
         [SOC_PRTNRS_PRD_FML_IND], [SOC_PRTNRS_PRD_FML_TTL],
         [SOC_PRTNRS_PRD_MALE_IND], [SOC_PRTNRS_PRD_MALE_TTL],
         [SOC_PRTNRS_PRD_TRNSGNDR_IND], [SOC_PRTNRS_PRD_TRNSGNDR_TTL],
         [SOC_SX_PRTNRS_INTNT_12MO_IND],
         [SOC_TRANSGNDR_PRTNRS_12MO_IND], [SOC_TRANSGNDR_PRTNRS_12MO_TTL])
    VALUES
        (22012150, 22012150,
         N'No', N'0',
         N'Yes', N'2',
         N'Bar', N'App',
         N'No', N'0',
         N'Yes', N'2',
         N'No', N'0',
         N'No',
         N'No', N'0');
END;

IF NOT EXISTS (SELECT 1 FROM [dbo].[L_INV_SOCIAL_HISTORY] WHERE PAGE_CASE_UID = 22004000 AND D_INV_SOCIAL_HISTORY_KEY = 22012150)
BEGIN
    INSERT INTO [dbo].[L_INV_SOCIAL_HISTORY] ([PAGE_CASE_UID], [D_INV_SOCIAL_HISTORY_KEY])
    VALUES (22004000, 22012150);
END;

-- =====================================================================
-- 7. D_INV_SYMPTOM (SYM alias) -> 4 SYM_* cols
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[D_INV_SYMPTOM] WHERE D_INV_SYMPTOM_KEY = 22012160)
BEGIN
    INSERT INTO [dbo].[D_INV_SYMPTOM]
        ([D_INV_SYMPTOM_KEY], [nbs_case_answer_uid],
         [SYM_NEUROLOGIC_SIGN_SYM], [SYM_OCULAR_MANIFESTATIONS],
         [SYM_OTIC_MANIFESTATION], [SYM_LATE_CLINICAL_MANIFES])
    VALUES
        (22012160, 22012160,
         N'No', N'No',
         N'No', N'No');
END;

IF NOT EXISTS (SELECT 1 FROM [dbo].[L_INV_SYMPTOM] WHERE PAGE_CASE_UID = 22004000 AND D_INV_SYMPTOM_KEY = 22012160)
BEGIN
    INSERT INTO [dbo].[L_INV_SYMPTOM] ([PAGE_CASE_UID], [D_INV_SYMPTOM_KEY])
    VALUES (22004000, 22012160);
END;

-- =====================================================================
-- 8. D_INV_TREATMENT (TRT alias) -> 1 col TRT_TREATMENT_DATE
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[D_INV_TREATMENT] WHERE D_INV_TREATMENT_KEY = 22012170)
BEGIN
    INSERT INTO [dbo].[D_INV_TREATMENT]
        ([D_INV_TREATMENT_KEY], [nbs_case_answer_uid],
         [TRT_TREATMENT_DATE])
    VALUES
        (22012170, 22012170, '2026-04-10');
END;

IF NOT EXISTS (SELECT 1 FROM [dbo].[L_INV_TREATMENT] WHERE PAGE_CASE_UID = 22004000 AND D_INV_TREATMENT_KEY = 22012170)
BEGIN
    INSERT INTO [dbo].[L_INV_TREATMENT] ([PAGE_CASE_UID], [D_INV_TREATMENT_KEY])
    VALUES (22004000, 22012170);
END;

-- =====================================================================
-- 9. D_INV_CONTACT (ICC alias) -> 10 RPT_* cols
--    (CTT_RPT_* attributes map to STD_HIV_DATAMART RPT_* columns)
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[D_INV_CONTACT] WHERE D_INV_CONTACT_KEY = 22012180)
BEGIN
    INSERT INTO [dbo].[D_INV_CONTACT]
        ([D_INV_CONTACT_KEY], [nbs_case_answer_uid],
         [CTT_RPT_ELICIT_INTERNET_INFO],
         [CTT_RPT_FIRST_NDLSHARE_EXP_DT], [CTT_RPT_FIRST_SEX_EXP_DT],
         [CTT_RPT_LAST_NDLSHARE_EXP_DT], [CTT_RPT_LAST_SEX_EXP_DT],
         [CTT_RPT_MET_OP_INTERNET], [CTT_RPT_NDLSHARE_EXP_FREQ],
         [CTT_RPT_RELATIONSHIP_TO_OP], [CTT_RPT_SEX_EXP_FREQ],
         [CTT_RPT_SPOUSE_OF_OP])
    VALUES
        (22012180, 22012180,
         N'Yes',
         '2026-01-01', '2026-01-15',
         '2026-03-01', '2026-03-15',
         N'Yes', N'Never',
         N'Partner', N'Weekly',
         N'No');
END;

IF NOT EXISTS (SELECT 1 FROM [dbo].[L_INV_CONTACT] WHERE PAGE_CASE_UID = 22004000 AND D_INV_CONTACT_KEY = 22012180)
BEGIN
    INSERT INTO [dbo].[L_INV_CONTACT] ([PAGE_CASE_UID], [D_INV_CONTACT_KEY])
    VALUES (22004000, 22012180);
END;

-- =====================================================================
-- 10. UPDATE existing D_INV_HIV row (22004100) with 2 missing cols
--     HIV_CA_900_OTH_RSN_NOT_LO, HIV_CA_900_REASON_NOT_LOC
--     (Authored by std_hiv_investigation_full_chain.sql but those 2
--     columns were deliberately left NULL — see coverage doc.)
-- =====================================================================
UPDATE [dbo].[D_INV_HIV]
SET [HIV_CA_900_OTH_RSN_NOT_LO] = N'Patient declined follow-up',
    [HIV_CA_900_REASON_NOT_LOC] = N'Refused'
WHERE D_INV_HIV_KEY = 22004100
  AND ([HIV_CA_900_OTH_RSN_NOT_LO] IS NULL OR [HIV_CA_900_REASON_NOT_LOC] IS NULL);

-- =====================================================================
-- 11. UPDATE existing D_INV_EPIDEMIOLOGY row (22004130) with SOURCE_SPREAD
-- =====================================================================
UPDATE [dbo].[D_INV_EPIDEMIOLOGY]
SET [SOURCE_SPREAD] = N'Sexual'
WHERE D_INV_EPIDEMIOLOGY_KEY = 22004130
  AND [SOURCE_SPREAD] IS NULL;

-- =====================================================================
-- 12. UPDATE D_PATIENT row (foundation 20000000, PATIENT_KEY=3) with the
--     STD-relevant patient columns that the SP reads.
--
--     CALC_5_YEAR_AGE_GROUP is computed from PATIENT_AGE_REPORTED /
--     PATIENT_AGE_REPORTED_UNIT so we need both populated.
--
--     We do NOT overwrite columns that are already populated (FIRST_NAME,
--     LAST_NAME, RACE_CALCULATED, ETHNICITY, etc.). Only fill NULLs.
-- =====================================================================
UPDATE [dbo].[D_PATIENT]
SET [PATIENT_AGE_REPORTED]      = COALESCE([PATIENT_AGE_REPORTED], 35),
    [PATIENT_AGE_REPORTED_UNIT] = COALESCE([PATIENT_AGE_REPORTED_UNIT], N'YEARS'),
    [PATIENT_ALIAS_NICKNAME]    = COALESCE([PATIENT_ALIAS_NICKNAME], N'Foundy'),
    [PATIENT_PHONE_CELL]        = COALESCE([PATIENT_PHONE_CELL], N'404-555-0101'),
    [PATIENT_PHONE_WORK]        = COALESCE([PATIENT_PHONE_WORK], N'404-555-0102'),
    [PATIENT_PREFERRED_GENDER]  = COALESCE([PATIENT_PREFERRED_GENDER], N'Male'),
    [PATIENT_MARITAL_STATUS]    = COALESCE([PATIENT_MARITAL_STATUS], N'Single'),
    [PATIENT_DECEASED_DATE]     = [PATIENT_DECEASED_DATE],  -- leave alive
    [PATIENT_CENSUS_TRACT]      = COALESCE([PATIENT_CENSUS_TRACT], N'013100'),
    [PATIENT_ADDL_GENDER_INFO]  = COALESCE([PATIENT_ADDL_GENDER_INFO], N'N/A'),
    [PATIENT_CURR_SEX_UNK_RSN]  = COALESCE([PATIENT_CURR_SEX_UNK_RSN], N'N/A'),
    [PATIENT_STREET_ADDRESS_2]  = COALESCE([PATIENT_STREET_ADDRESS_2], N'Apt 2'),
    [PATIENT_UNK_ETHNIC_RSN]    = COALESCE([PATIENT_UNK_ETHNIC_RSN], N'N/A')
WHERE PATIENT_UID = 20000000;

-- =====================================================================
-- 13. UPDATE D_CASE_MANAGEMENT row for INVESTIGATION_KEY=22 (CASE_UID=22004000)
--     with OOJ_INITG_AGNCY_* date fields.
-- =====================================================================
UPDATE cm
SET cm.[OOJ_INITG_AGNCY_RECD_DATE]     = COALESCE(cm.[OOJ_INITG_AGNCY_RECD_DATE], '2026-04-03'),
    cm.[OOJ_INITG_AGNCY_OUTC_SNT_DATE] = COALESCE(cm.[OOJ_INITG_AGNCY_OUTC_SNT_DATE], '2026-04-15'),
    cm.[OOJ_INITG_AGNCY_OUTC_DUE_DATE] = COALESCE(cm.[OOJ_INITG_AGNCY_OUTC_DUE_DATE], '2026-04-30')
FROM dbo.D_CASE_MANAGEMENT cm
INNER JOIN dbo.INVESTIGATION i ON i.INVESTIGATION_KEY = cm.INVESTIGATION_KEY
WHERE i.CASE_UID = 22004000;

END TRY
BEGIN CATCH
    PRINT 'zz_std_hiv_datamart_enrich: ERROR in enrichment block';
    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO

-- =====================================================================
-- Tail-EXEC the SP chain to refresh F_STD_PAGE_CASE (picks up the new
-- L_INV_* rows -> dim keys flip from sentinel-1 to our authored keys)
-- and STD_HIV_DATAMART (DELETE+INSERT for @phc_id=22004000 picks up the
-- new dim values from the join cascade).
-- =====================================================================
BEGIN TRY
    EXEC dbo.sp_f_std_page_case_postprocessing
        @phc_id_list = N'22004000',
        @debug = 0;

    EXEC dbo.sp_std_hiv_datamart_postprocessing
        @phc_id = N'22004000',
        @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'zz_std_hiv_datamart_enrich: ERROR in tail-EXEC chain';
    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO
