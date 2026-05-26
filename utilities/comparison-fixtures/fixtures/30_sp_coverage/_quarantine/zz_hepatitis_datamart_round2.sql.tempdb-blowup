-- =====================================================================
-- Tier 3 - Round 2 - hepatitis_datamart enrichment
-- =====================================================================
-- Goal: lift HEPATITIS_DATAMART column coverage from baseline 140/209
-- toward 200/209 by filling the remaining unpopulated cols on PHC
-- 22008500 (the Hep A acute investigation set up by Agent B2).
--
-- STRATEGY
--   Round 1 (zz_hepatitis_datamart_enrich.sql) brought us from 26 -> 140
--   cols by direct-INSERT into D_INV_LAB_FINDING / D_INV_EPIDEMIOLOGY /
--   D_INV_MEDICAL_HISTORY / D_INV_MOTHER / D_INV_TRAVEL /
--   D_INV_ADMINISTRATIVE / D_INV_CLINICAL / D_INV_PATIENT_OBS /
--   D_INV_VACCINATION + L_INV_<cat> link rows for PHC 22008500.
--
--   D_INV_RISK_FACTOR was explicitly SKIPPED in Round 1 due to numeric-
--   cast concerns. Round 2 takes care of it (using numeric literals for
--   RSK_NumSexPrtners / RSK_IncarcTimeMonths / RSK_IncarcYear6Mos / RSK_STDTxYr).
--   The SP filter `NOT LIKE N'%[^0-9.,-]%' AND ISNUMERIC = 1`
--   gates the values, so numeric strings flow.
--
--   Other Round 2 enrichments:
--   - UPDATE dbo.INVESTIGATION (CASE_UID=22008500): set INV_COMMENTS,
--     INV_START_DT, PATIENT_PREGNANT_IND so the 3 INVESTIGATION-sourced
--     cols flow.
--   - INSERT D_PROVIDER (key 22023001 PHYSICIAN, 22023002 INVESTIGATOR)
--     + UPDATE F_PAGE_CASE.PHYSICIAN_KEY / INVESTIGATOR_KEY so PHYS_*,
--     INVESTIGATOR_NAME, PHYSICIAN_UID, INVESTIGATOR_UID flow.
--   - INSERT D_ORGANIZATION (key 22023003 REPORTER) + UPDATE
--     F_PAGE_CASE.ORG_AS_REPORTER_KEY so RPT_SRC_SOURCE_NM, RPT_SRC_STATE,
--     RPT_SRC_CITY, RPT_SRC_COUNTY, RPT_SRC_COUNTY_CD, REPORTING_SOURCE_UID
--     flow.
--   - INSERT D_INVESTIGATION_REPEAT rows for vaccination dose history
--     (VAC_VACCINATIONDATE + VAC_VACCINEDOSENUM) + link to F_PAGE_CASE
--     via L_INVESTIGATION_REPEAT-style mechanism. SP pivots
--     D_INVESTIGATION_REPEAT [1..4] rows into VACC_DOSE_NBR_1..4 /
--     VACC_RECVD_DT_1..4.
--   - INSERT/UPDATE D_INV_VACCINATION row to set VAC_ImmuneGlobulin
--     and VAC_LastIGDose so IMM_GLOB_RECVD_IND and GLOB_LAST_RECVD_YR flow.
--
-- UID ALLOCATION
--   22023000 - 22023999  (Agent Q round-2 reserved block).
--     22023001  D_PROVIDER physician
--     22023002  D_PROVIDER investigator
--     22023003  D_ORGANIZATION reporter
--     22023100  D_INV_RISK_FACTOR new key (replace key=1)
--     22023110 - 22023113  D_INVESTIGATION_REPEAT vaccination rows
--
-- IDEMPOTENCY: every INSERT / UPDATE is guarded by IF NOT EXISTS or by
-- value-checks; safe to re-apply.
--
-- TAIL-EXECS: re-run sp_f_page_case_postprocessing (to pick up updated
-- F_PAGE_CASE keys), then sp_hepatitis_datamart_postprocessing.
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- 1. UPDATE INVESTIGATION row for INV_COMMENTS, INV_START_DT, PATIENT_PREGNANT_IND
-- ---------------------------------------------------------------------
-- The HEPATITIS_DATAMART SP reads these from dbo.INVESTIGATION directly
-- (lines 1071, 1072, 1074 of the SP), filling INV_COMMENTS, INV_START_DT,
-- and PAT_PREGNANT_IND on the datamart row.
UPDATE dbo.INVESTIGATION
SET
    INV_COMMENTS = ISNULL(INV_COMMENTS, N'Hep A acute investigation - source likely contaminated food. No outbreak link confirmed at time of report.'),
    INV_START_DT = ISNULL(INV_START_DT, '2026-03-22T00:00:00'),
    PATIENT_PREGNANT_IND = ISNULL(PATIENT_PREGNANT_IND, N'N')
WHERE CASE_UID = 22008500;

GO

-- ---------------------------------------------------------------------
-- 2. INSERT D_PROVIDER rows for PHYSICIAN + INVESTIGATOR
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.D_PROVIDER WHERE PROVIDER_KEY = 22023001)
BEGIN
    INSERT INTO dbo.D_PROVIDER (PROVIDER_KEY, PROVIDER_UID, PROVIDER_LOCAL_ID,
        PROVIDER_FIRST_NAME, PROVIDER_MIDDLE_NAME, PROVIDER_LAST_NAME,
        PROVIDER_CITY, PROVIDER_STATE, PROVIDER_COUNTY, PROVIDER_ZIP,
        PROVIDER_STREET_ADDRESS_1, PROVIDER_COUNTRY,
        PROVIDER_ADD_TIME, PROVIDER_LAST_CHANGE_TIME)
    VALUES (22023001, 22023001, N'PRV22023001GA01',
        N'Hannah', N'B', N'Lechter',
        N'Atlanta', N'Georgia', N'Fulton County', N'30303',
        N'500 Provider Way', N'United States',
        '2026-04-01T00:00:00', '2026-04-01T00:00:00');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.D_PROVIDER WHERE PROVIDER_KEY = 22023002)
BEGIN
    INSERT INTO dbo.D_PROVIDER (PROVIDER_KEY, PROVIDER_UID, PROVIDER_LOCAL_ID,
        PROVIDER_FIRST_NAME, PROVIDER_MIDDLE_NAME, PROVIDER_LAST_NAME,
        PROVIDER_CITY, PROVIDER_STATE, PROVIDER_COUNTY, PROVIDER_ZIP,
        PROVIDER_STREET_ADDRESS_1, PROVIDER_COUNTRY,
        PROVIDER_ADD_TIME, PROVIDER_LAST_CHANGE_TIME)
    VALUES (22023002, 22023002, N'PRV22023002GA01',
        N'Ingrid', N'C', N'Olsen',
        N'Atlanta', N'Georgia', N'Fulton County', N'30303',
        N'600 Investigator Way', N'United States',
        '2026-04-01T00:00:00', '2026-04-01T00:00:00');
END;

-- ---------------------------------------------------------------------
-- 3. INSERT D_ORGANIZATION row for REPORTING SOURCE
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.D_ORGANIZATION WHERE ORGANIZATION_KEY = 22023003)
BEGIN
    INSERT INTO dbo.D_ORGANIZATION (ORGANIZATION_KEY, ORGANIZATION_UID,
        ORGANIZATION_NAME, ORGANIZATION_CITY, ORGANIZATION_STATE,
        ORGANIZATION_COUNTY, ORGANIZATION_COUNTY_CODE, ORGANIZATION_ZIP,
        ORGANIZATION_STREET_ADDRESS_1, ORGANIZATION_COUNTRY,
        ORGANIZATION_ADD_TIME, ORGANIZATION_LAST_CHANGE_TIME)
    VALUES (22023003, 22023003,
        N'Fulton County Health Clinic', N'Atlanta', N'Georgia',
        N'Fulton County', N'121', N'30303',
        N'700 Reporter Way', N'United States',
        '2026-04-01T00:00:00', '2026-04-01T00:00:00');
END;

GO

-- ---------------------------------------------------------------------
-- 4. UPDATE F_PAGE_CASE to point at our new provider/org keys
-- ---------------------------------------------------------------------
-- The HEPATITIS_DATAMART SP joins F_PAGE_CASE -> D_PROVIDER on
-- PHYSICIAN_KEY / INVESTIGATOR_KEY and -> D_ORGANIZATION on
-- ORG_AS_REPORTER_KEY (lines 1289-1296 of SP). Currently these are 1
-- (the empty default row). Pointing at our new rows enables PHYS_*,
-- INVESTIGATOR_*, RPT_SRC_* columns on the datamart.
UPDATE dbo.F_PAGE_CASE
SET
    PHYSICIAN_KEY = 22023001,
    INVESTIGATOR_KEY = 22023002,
    ORG_AS_REPORTER_KEY = 22023003
WHERE INVESTIGATION_KEY = 26
  AND PHYSICIAN_KEY = 1;  -- only flip from default to avoid re-running ill-effects

GO

-- ---------------------------------------------------------------------
-- 5. INSERT D_INV_RISK_FACTOR row + UPDATE F_PAGE_CASE pointer
-- ---------------------------------------------------------------------
-- The original Round-1 enrich fixture inserted nrt_page_case_answer
-- rows for RSK_* but the pagebuilder pipeline did not pivot them into
-- D_INV_RISK_FACTOR (agent B2's gotcha #4). We bypass and direct-INSERT.
--
-- LIFE_SEX_PRTNR_NBR / LAST6PLUSMO_INCAR_PER / LAST6PLUSMO_INCAR_YR /
-- STD_LAST_TREATMENT_YR are numeric on HEPATITIS_DATAMART; the SP
-- safe-casts via `NOT LIKE N'%[^0-9.,-]%'`. Use clean numeric strings.
IF NOT EXISTS (SELECT 1 FROM dbo.D_INV_RISK_FACTOR WHERE D_INV_RISK_FACTOR_KEY = 22023100)
BEGIN
    INSERT INTO dbo.D_INV_RISK_FACTOR (D_INV_RISK_FACTOR_KEY,
        RSK_BloodExpOther, RSK_BloodTransfusion, RSK_BloodTransfusionDate,
        RSK_BloodWorkerCnctFreq, RSK_BloodWorkerEver, RSK_BloodWorkerOnset,
        RSK_ClottingPrior87, RSK_ContaminatedStick, RSK_DentalOralSx,
        RSK_HEMODIALYSIS_BEFORE_ONSET, RSK_HemodialysisLongTerm, RSK_HospitalizedPrior,
        RSK_IDU, RSK_Incarcerated24Hrs, RSK_Incarcerated6months,
        RSK_IncarceratedEver, RSK_IncarceratedJail, RSK_IncarcerationPrison,
        RSK_IncarcJuvenileFacilit, RSK_IncarcTimeMonths, RSK_IncarcYear6Mos,
        RSK_IVInjectInfuseOutpt, RSK_LongTermCareRes, RSK_NumSexPrtners,
        RSK_OtherBldExpSpec, RSK_Piercing, RSK_PiercingOthLocSpec,
        RSK_PiercingRcvdFrom, RSK_PSWrkrBldCnctFreq, RSK_PublicSafetyWorker,
        RSK_STDTxEver, RSK_STDTxYr, RSK_SurgeryOther,
        RSK_Tattoo, RSK_TattooLocation, RSK_TattooLocOthSpec,
        RSK_TransfusionPrior92, RSK_TransplantPrior92, RSK_HepContactEver)
    VALUES (22023100,
        N'N', N'N', '2026-03-10',
        N'N', N'N', N'N',
        N'N', N'N', N'N',
        N'N', N'N', N'N',
        N'N', N'N', N'N',
        N'N', N'N', N'N',
        N'N', N'0', N'2024',     -- numeric strings for INCAR_PER/YR
        N'N', N'N', N'2',        -- numeric string for LIFE_SEX_PRTNR_NBR
        N'N', N'N', N'none',
        N'N', N'N', N'N',
        N'N', N'2023', N'N',     -- numeric string for STD_LAST_TREATMENT_YR
        N'N', N'arm', N'none',
        N'N', N'N', N'N');
END;

-- Link D_INV_RISK_FACTOR to F_PAGE_CASE via the linking table
IF NOT EXISTS (SELECT 1 FROM dbo.L_INV_RISK_FACTOR WHERE D_INV_RISK_FACTOR_KEY = 22023100)
BEGIN
    INSERT INTO dbo.L_INV_RISK_FACTOR (D_INV_RISK_FACTOR_KEY, PAGE_CASE_UID)
    VALUES (22023100, 22008500);
END;

-- Repoint F_PAGE_CASE.D_INV_RISK_FACTOR_KEY directly so the SP sees it
UPDATE dbo.F_PAGE_CASE
SET D_INV_RISK_FACTOR_KEY = 22023100
WHERE INVESTIGATION_KEY = 26
  AND D_INV_RISK_FACTOR_KEY = 1;

GO

-- ---------------------------------------------------------------------
-- 6. UPDATE D_INV_VACCINATION for IMM_GLOB_RECVD_IND and GLOB_LAST_RECVD_YR
-- ---------------------------------------------------------------------
-- The SP maps VAC_ImmuneGlobulin -> IMM_GLOB_RECVD_IND and
-- VAC_LastIGDose -> GLOB_LAST_RECVD_YR (verified via SP grep).
-- GLOB_LAST_RECVD_YR is `date` so use a real date string.
UPDATE dbo.D_INV_VACCINATION
SET VAC_ImmuneGlobulin = ISNULL(VAC_ImmuneGlobulin, N'N'),
    VAC_LastIGDose     = ISNULL(VAC_LastIGDose,     '2024-06-01')
WHERE D_INV_VACCINATION_KEY = 22008690;

GO

-- ---------------------------------------------------------------------
-- 7. D_INVESTIGATION_REPEAT rows: vaccination dose history
-- ---------------------------------------------------------------------
-- The HEPATITIS_DATAMART SP PIVOTs D_INVESTIGATION_REPEAT rows with
-- ANSWER_GROUP_SEQ_NBR 1..4 into VACC_DOSE_NBR_1..4 and VACC_RECVD_DT_1..4
-- (sp lines 1585-1822). Filter: rows where INVESTIGATION_KEY matches
-- via PAGE_CASE_UID -> F_PAGE_CASE link.
--
-- VACC_DOSE_NBR_* is numeric and VACC_RECVD_DT_* is date.
-- D_INVESTIGATION_REPEAT has VAC_VACCINEDOSENUM (bigint) and
-- VAC_VACCINATIONDATE (date) columns. ANSWER_GROUP_SEQ_NBR is the
-- iteration index 1..4.
DECLARE @hep_phc_uid bigint = 22008500;

IF NOT EXISTS (SELECT 1 FROM dbo.D_INVESTIGATION_REPEAT WHERE D_INVESTIGATION_REPEAT_KEY = 22023110)
BEGIN
    INSERT INTO dbo.D_INVESTIGATION_REPEAT (D_INVESTIGATION_REPEAT_KEY,
        PAGE_CASE_UID, BLOCK_NM, ANSWER_GROUP_SEQ_NBR,
        VAC_VACCINEDOSENUM, VAC_VACCINATIONDATE)
    VALUES (22023110, @hep_phc_uid, N'INV230', 1, 1, '2010-05-10');
    INSERT INTO dbo.D_INVESTIGATION_REPEAT (D_INVESTIGATION_REPEAT_KEY,
        PAGE_CASE_UID, BLOCK_NM, ANSWER_GROUP_SEQ_NBR,
        VAC_VACCINEDOSENUM, VAC_VACCINATIONDATE)
    VALUES (22023111, @hep_phc_uid, N'INV230', 2, 2, '2010-11-10');
    INSERT INTO dbo.D_INVESTIGATION_REPEAT (D_INVESTIGATION_REPEAT_KEY,
        PAGE_CASE_UID, BLOCK_NM, ANSWER_GROUP_SEQ_NBR,
        VAC_VACCINEDOSENUM, VAC_VACCINATIONDATE)
    VALUES (22023112, @hep_phc_uid, N'INV230', 3, 3, '2018-05-10');
    INSERT INTO dbo.D_INVESTIGATION_REPEAT (D_INVESTIGATION_REPEAT_KEY,
        PAGE_CASE_UID, BLOCK_NM, ANSWER_GROUP_SEQ_NBR,
        VAC_VACCINEDOSENUM, VAC_VACCINATIONDATE)
    VALUES (22023113, @hep_phc_uid, N'INV230', 4, 4, '2025-05-10');
END;

-- Link D_INVESTIGATION_REPEAT rows to the PHC via L_INVESTIGATION_REPEAT.
-- sp_f_page_case_postprocessing reads this table to source
-- D_INVESTIGATION_REPEAT_KEY into F_PAGE_CASE for the PHC. With multiple
-- rows here, F_PAGE_CASE gets multiple rows (one per repeat key) which
-- feed #TMP_F_INVESTIGATION_REPEAT and ultimately the VACC_*_NBR_/_DT_
-- PIVOTs in sp_hepatitis_datamart_postprocessing.
IF NOT EXISTS (SELECT 1 FROM dbo.L_INVESTIGATION_REPEAT WHERE D_INVESTIGATION_REPEAT_KEY = 22023110)
BEGIN
    INSERT INTO dbo.L_INVESTIGATION_REPEAT (D_INVESTIGATION_REPEAT_KEY, PAGE_CASE_UID) VALUES
        (22023110, 22008500),
        (22023111, 22008500),
        (22023112, 22008500),
        (22023113, 22008500);
END;

GO

-- ---------------------------------------------------------------------
-- 7b. nrt_page_case_answer rows for VAC103 / VAC120 (vaccination metadata)
-- ---------------------------------------------------------------------
-- sp_hepatitis_datamart_postprocessing #TMP_METADATA_TEST (line ~1472)
-- builds the vaccination-repeat metadata catalog by SELECTing
-- nrt_page_case_answer rows where:
--   question_identifier IN ('VAC103','VAC120')
--   investigation_form_cd = condition.DISEASE_GRP_DESC = 'PG_Hepatitis_A_Acute_Investigation'
--   block_nm IS NOT NULL
-- The block_nm value is then matched against D_INVESTIGATION_REPEAT.BLOCK_NM
-- to enable the VACC_DOSE_NBR_1..4 / VACC_RECVD_DT_1..4 PIVOT.
-- We use block_nm='INV230' to match the D_INVESTIGATION_REPEAT rows above.
IF NOT EXISTS (SELECT 1 FROM [dbo].[nrt_page_case_answer] WHERE act_uid = 22008500 AND nbs_case_answer_uid = 22023200)
BEGIN
    INSERT INTO [dbo].[nrt_page_case_answer]
        ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid],
         [nbs_question_uid],
         [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr],
         [investigation_form_cd], [question_identifier], [data_location],
         [code_set_group_id], [last_chg_time], [record_status_cd],
         [datamart_column_nm], [ldf_status_cd], [seq_nbr], [batch_id],
         [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd],
         [data_type], [block_nm])
    VALUES
    -- VAC103 (vaccination date) — metadata row to feed #TMP_METADATA_TEST
    (22008500, 22023200, 2, 22023200, N'D_INVESTIGATION_REPEAT', N'VAC_VaccinationDate', N'2010-05-10', N'1', N'PG_Hepatitis_A_Acute_Investigation', N'VAC103', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'VAC_VaccinationDate', NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active', N'TEXT', N'INV230'),
    -- VAC120 (vaccination dose number)
    (22008500, 22023201, 2, 22023201, N'D_INVESTIGATION_REPEAT', N'VAC_VaccineDoseNum',  N'1',          N'1', N'PG_Hepatitis_A_Acute_Investigation', N'VAC120', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'VAC_VaccineDoseNum',  NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active', N'TEXT', N'INV230');
END;

GO

-- Re-run sp_f_page_case_postprocessing so the L_INVESTIGATION_REPEAT rows
-- above produce per-repeat-key F_PAGE_CASE rows the hep datamart SP
-- expects.
BEGIN TRY
    EXEC dbo.sp_f_page_case_postprocessing
        @phc_ids = N'22008500',
        @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'sp_f_page_case_postprocessing failed: ' + ERROR_MESSAGE();
END CATCH;
GO

-- After sp_f_page_case rebuilds the F_PAGE_CASE rows, re-apply our
-- physician / investigator / reporter / risk-factor key overrides so
-- the rows we INSERTed point at the right dim rows (sp_f_page_case may
-- reset PHYSICIAN_KEY etc. back to 1 since we have no real
-- act_relationship / participation rows wiring providers to the PHC).
UPDATE dbo.F_PAGE_CASE
SET PHYSICIAN_KEY = 22023001,
    INVESTIGATOR_KEY = 22023002,
    ORG_AS_REPORTER_KEY = 22023003,
    D_INV_RISK_FACTOR_KEY = 22023100
WHERE INVESTIGATION_KEY = 26
  AND (PHYSICIAN_KEY = 1 OR INVESTIGATOR_KEY = 1 OR ORG_AS_REPORTER_KEY = 1 OR D_INV_RISK_FACTOR_KEY = 1);

GO

-- ---------------------------------------------------------------------
-- 8. Tail-EXECs: re-run F_PAGE_CASE + HEPATITIS_DATAMART
-- ---------------------------------------------------------------------
-- F_PAGE_CASE has the new physician / investigator / reporter / risk-factor
-- keys via direct UPDATEs above, but rerunning sp_f_page_case_postprocessing
-- is idempotent and is safer in the orchestrated merge run.

BEGIN TRY
    EXEC dbo.sp_hepatitis_datamart_postprocessing
        @phc_id = N'22008500',
        @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'sp_hepatitis_datamart_postprocessing failed: ' + ERROR_MESSAGE();
END CATCH;
GO
