-- =====================================================================
-- Tier 3 — COVID_CASE_DATAMART Round 2 enrichment (Agent R)
-- =====================================================================
-- Authored 2026-05-24 by Agent R (parallel enrichment).
--
-- Goal: lift dbo.covid_case_datamart populated-column count from
-- ~241/383 (post Agent A's round 1) toward 320+/383 by:
--   1. Creating supporting D_PROVIDER / D_ORGANIZATION rows and
--      re-pointing NRT_INVESTIGATION 22003000 fks at them
--      (populates HOSPITAL_NAME, PHC_INV_*, PHYS_*, RPT_PRV_*, RPT_ORG_*).
--   2. Inserting NRT_INVESTIGATION_NOTIFICATION + NRT_INVESTIGATION_CONFIRMATION
--      rows scoped to PHC 22003000 (populates NOTIFICATION_*, CONFIRMATION_*).
--   3. Updating NRT_INVESTIGATION 22003000 directly for PHC-derived
--      cols: txt, notes, detection_method_cd, effective_duration_amt,
--      effective_duration_unit_cd (populates INV_COMMENTS, NOTES,
--      DETECT_METHOD_CD, ILLNESS_DURATION, ILLNESS_DURATION_UNIT).
--   4. Authoring 96 supplemental nrt_page_case_answer rows for the 32
--      repeating-group COVID questions (each gets answer_group_seq_nbr
--      1, 2, 3 — populates *_1, *_2, *_3 columns).
--   5. Authoring 6 supplemental nrt_page_case_answer rows for
--      partial-repeating-group cols (TEST_RESULT_2/3, TEST_TYPE_2/3,
--      PERFORMING_LAB_TYPE_2/3).
--   6. Authoring 12 supplemental nrt_page_case_answer rows for
--      non-repeating COVID questions not covered by Agent A.
--
-- WHY THIS WORKS
--   sp_covid_case_datamart_postprocessing is idempotent (DELETE+INSERT
--   per PHC). The dim/PHC/answer rows we author here are picked up on
--   the next SP run. PHC 22003000 is dedicated to this datamart and
--   only one of two COVID PHCs (22000070 is the other) — but
--   22000070's row is unaffected by our changes since our targets are
--   either:
--     - act_uid=22003000 (nrt_page_case_answer)
--     - public_health_case_uid=22003000 (notification/confirmation)
--     - WHERE public_health_case_uid=22003000 (NRT_INVESTIGATION UPDATE)
--     - New dim UIDs 22024xxx (D_PROVIDER/D_ORGANIZATION)
--   D_PATIENT 20000000 is shared by 25 PHCs and is NOT touched here.
--   (The 4 patient-specific gaps — PATIENT_GEN_COMMENTS,
--   PATIENT_MARITAL_STS, PATIENT_NAME_SUFFIX, PATIENT_PHONE_EXT_WORK —
--   are deliberately left for the orchestrator to address via a
--   COVID-dedicated patient swap.)
--
-- UID block: 22024000..22024999 (Agent R allotment).
--
-- IDEMPOTENCY
--   Wrapped in IF NOT EXISTS guards keyed on the first allocated UID
--   of each section. Re-applying after a successful insert is a no-op.
--
-- TAIL-EXEC
--   Yes — explicit TRY/CATCH EXEC sp_covid_case_datamart_postprocessing
--   so coverage numbers refresh immediately after apply.
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- Section 1: D_PROVIDER + D_ORGANIZATION supporting dims.
-- UIDs 22024000..22024004.
-- ---------------------------------------------------------------------

IF NOT EXISTS (SELECT 1 FROM [dbo].[D_PROVIDER] WHERE PROVIDER_UID = 22024000)
BEGIN
    INSERT INTO [dbo].[D_PROVIDER]
        (PROVIDER_UID, PROVIDER_KEY, PROVIDER_LOCAL_ID, PROVIDER_RECORD_STATUS,
         PROVIDER_FIRST_NAME, PROVIDER_LAST_NAME,
         PROVIDER_PHONE_WORK, PROVIDER_PHONE_EXT_WORK)
    VALUES
        (22024000, 22024000, N'PRV22024000GA01', N'ACTIVE',
         N'Inez', N'Investigator', N'404-555-2200', N'201'),
        (22024001, 22024001, N'PRV22024001GA01', N'ACTIVE',
         N'Phil', N'Physician', N'404-555-2210', N'202'),
        (22024002, 22024002, N'PRV22024002GA01', N'ACTIVE',
         N'Roger', N'Reporter', N'404-555-2220', N'203');
END;
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[D_ORGANIZATION] WHERE ORGANIZATION_UID = 22024003)
BEGIN
    INSERT INTO [dbo].[D_ORGANIZATION]
        (ORGANIZATION_UID, ORGANIZATION_KEY, ORGANIZATION_LOCAL_ID,
         ORGANIZATION_RECORD_STATUS, ORGANIZATION_NAME,
         ORGANIZATION_PHONE_WORK, ORGANIZATION_PHONE_EXT_WORK)
    VALUES
        (22024003, 22024003, N'ORG22024003GA01', N'ACTIVE',
         N'Test Reporting Org', N'404-555-2230', N'301'),
        (22024004, 22024004, N'ORG22024004GA01', N'ACTIVE',
         N'Test Hospital', N'404-555-2240', N'302');
END;
GO

-- ---------------------------------------------------------------------
-- Section 2: Re-point NRT_INVESTIGATION 22003000 + populate phc-derived cols.
-- ---------------------------------------------------------------------

UPDATE [dbo].[NRT_INVESTIGATION]
SET
    investigator_id = 22024000,
    physician_id = 22024001,
    person_as_reporter_uid = 22024002,
    organization_id = 22024003,
    hospital_uid = 22024004,
    txt = N'COVID case investigation comments authored by Agent R round 2',
    notes = N'Agent R round 2 notes — populating NOTES datamart column',
    detection_method_cd = N'ACTIVE',
    effective_duration_amt = 7,
    effective_duration_unit_cd = N'D'
WHERE public_health_case_uid = 22003000;
GO

-- ---------------------------------------------------------------------
-- Section 3: NRT_INVESTIGATION_NOTIFICATION row (NOTIFICATION_* cols).
-- ---------------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 FROM [dbo].[NRT_INVESTIGATION_NOTIFICATION]
    WHERE notification_uid = 22024010
)
BEGIN
    INSERT INTO [dbo].[NRT_INVESTIGATION_NOTIFICATION]
        (source_act_uid, public_health_case_uid, source_class_cd,
         target_class_cd, act_type_cd, status_cd,
         notification_uid, prog_area_cd, jurisdiction_cd,
         rpt_sent_time, notif_status, notif_local_id,
         notif_add_time, notif_last_chg_time)
    VALUES
        (22003000, 22003000, N'NOT', N'PSN', N'PHCNotification', N'A',
         22024010, N'COV', N'130001',
         '2026-04-15T00:00:00', N'COMPLETED', N'NOT22024010GA01',
         '2026-04-14T00:00:00', '2026-04-15T00:00:00');
END;
GO

-- ---------------------------------------------------------------------
-- Section 4: NRT_INVESTIGATION_CONFIRMATION row (CONFIRMATION_* cols).
-- ---------------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 FROM [dbo].[NRT_INVESTIGATION_CONFIRMATION]
    WHERE public_health_case_uid = 22003000
)
BEGIN
    INSERT INTO [dbo].[NRT_INVESTIGATION_CONFIRMATION]
        (public_health_case_uid, confirmation_method_cd,
         confirmation_method_desc_txt, confirmation_method_time, batch_id)
    VALUES
        (22003000, N'LD', N'Laboratory confirmed',
         '2026-04-10T00:00:00', 22024020);
END;
GO

-- ---------------------------------------------------------------------
-- Section 5: nrt_page_case_answer rows for 12 non-repeating COVID
-- questions not covered by Agent A's round 1.
-- UIDs 22024100..22024111.
-- ---------------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 FROM [dbo].[nrt_page_case_answer]
    WHERE nbs_case_answer_uid = 22024100
)
BEGIN
    INSERT INTO [dbo].[nrt_page_case_answer]
        ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid],
         [nbs_question_uid],
         [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr],
         [investigation_form_cd], [question_identifier], [data_location],
         [code_set_group_id], [last_chg_time], [record_status_cd],
         [datamart_column_nm], [ldf_status_cd], [seq_nbr], [batch_id])
    VALUES
    (22003000, 22024100, 1, 10009148, N'COVID_CASE', N'ANIMAL_TYPE',
     N'Other', NULL, N'PG_COVID-19_v1.1', N'FDD_Q_32',
     N'NBS_Case_Answer.answer_txt', 108580,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'ANIMAL_TYPE', NULL, NULL, NULL),
    (22003000, 22024101, 1, 10001012, N'COVID_CASE', N'BINATIONAL_RPTNG_CRIT',
     N'Other', NULL, N'PG_COVID-19_v1.1', N'INV515',
     N'NBS_Case_Answer.answer_txt', 102980,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'BINATIONAL_RPTNG_CRIT', NULL, NULL, NULL),
    (22003000, 22024102, 1, 10004138, N'COVID_CASE', N'CASE_IDENTIFY_PROCESS',
     N'Other', NULL, N'PG_COVID-19_v1.1', N'NBS551',
     N'NBS_Case_Answer.answer_txt', 108030,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CASE_IDENTIFY_PROCESS', NULL, NULL, NULL),
    (22003000, 22024103, 1, 10010318, N'COVID_CASE', N'COVID_19_VARIANT',
     N'Other', NULL, N'PG_COVID-19_v1.1', N'NBS786',
     N'NBS_Case_Answer.answer_txt', 115910,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'COVID_19_VARIANT', NULL, NULL, NULL),
    (22003000, 22024104, 1, 10010297, N'COVID_CASE', N'ENROLLED_TRIBE_NAME',
     N'Other', NULL, N'PG_COVID-19_v1.1', N'NBS779',
     N'NBS_Case_Answer.answer_txt', 108560,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'ENROLLED_TRIBE_NAME', NULL, NULL, NULL),
    (22003000, 22024105, 1, 10004238, N'COVID_CASE', N'HIGH_RISK_TRAVEL_LOC',
     N'Other', NULL, N'PG_COVID-19_v1.1', N'NBS556',
     N'NBS_Case_Answer.answer_txt', 108270,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'HIGH_RISK_TRAVEL_LOC', NULL, NULL, NULL),
    (22003000, 22024106, 1, 10004178, N'COVID_CASE', N'INFO_SOURCE',
     N'Other', NULL, N'PG_COVID-19_v1.1', N'NBS553',
     N'NBS_Case_Answer.answer_txt', 108400,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'INFO_SOURCE', NULL, NULL, NULL),
    (22003000, 22024107, 1, 10010319, N'COVID_CASE', N'INTL_DSTINTION_MULTI',
     N'Other', NULL, N'PG_COVID-19_v1.1', N'NBS777',
     N'NBS_Case_Answer.answer_txt', 3560,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'INTL_DSTINTION_MULTI', NULL, NULL, NULL),
    (22003000, 22024108, 1, 10001025, N'COVID_CASE', N'ReasonForTest',
     N'Other', NULL, N'PG_COVID-19_v1.1', N'INV575',
     N'NBS_Case_Answer.answer_txt', 108590,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'ReasonForTest', NULL, NULL, NULL),
    (22003000, 22024109, 1, 10010320, N'COVID_CASE', N'TRAVEL_STATE_MULTI',
     N'Other', NULL, N'PG_COVID-19_v1.1', N'NBS778',
     N'NBS_Case_Answer.answer_txt', 3920,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_STATE_MULTI', NULL, NULL, NULL),
    (22003000, 22024110, 1, 10010296, N'COVID_CASE', N'TRIBAL_NAME',
     N'Other', NULL, N'PG_COVID-19_v1.1', N'95370_3',
     N'NBS_Case_Answer.answer_txt', 108560,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRIBAL_NAME', NULL, NULL, NULL),
    (22003000, 22024111, 1, 10010299, N'COVID_CASE', N'WKPLC_SETTING_CODED',
     N'Other', NULL, N'PG_COVID-19_v1.1', N'NBS686_CD',
     N'NBS_Case_Answer.answer_txt', 108570,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'WKPLC_SETTING_CODED', NULL, NULL, NULL);
END;
GO

-- ---------------------------------------------------------------------
-- Section 6: nrt_page_case_answer rows for 32 repeating-group questions.
-- Each base question gets 3 answer rows with answer_group_seq_nbr=1,2,3
-- to populate the *_1, *_2, *_3 datamart cols.
-- UIDs 22024200..22024295 (32 * 3 = 96 rows).
-- ---------------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 FROM [dbo].[nrt_page_case_answer]
    WHERE nbs_case_answer_uid = 22024200
)
BEGIN
    INSERT INTO [dbo].[nrt_page_case_answer]
        ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid],
         [nbs_question_uid],
         [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr],
         [investigation_form_cd], [question_identifier], [data_location],
         [code_set_group_id], [last_chg_time], [record_status_cd],
         [datamart_column_nm], [ldf_status_cd], [seq_nbr], [batch_id])
    VALUES
    -- ADDL_SPECIMEN_ID (q=10004233, freetext)
    (22003000, 22024200, 1, 10004233, N'COVID_CASE', N'ADDL_SPECIMEN_ID', N'SPEC-001', 1, N'PG_COVID-19_v1.1', N'NBS670', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'ADDL_SPECIMEN_ID', NULL, NULL, NULL),
    (22003000, 22024201, 1, 10004233, N'COVID_CASE', N'ADDL_SPECIMEN_ID', N'SPEC-002', 2, N'PG_COVID-19_v1.1', N'NBS670', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'ADDL_SPECIMEN_ID', NULL, NULL, NULL),
    (22003000, 22024202, 1, 10004233, N'COVID_CASE', N'ADDL_SPECIMEN_ID', N'SPEC-003', 3, N'PG_COVID-19_v1.1', N'NBS670', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'ADDL_SPECIMEN_ID', NULL, NULL, NULL),
    -- ARRIVAL_TRVL_DEST_DT (q=10006158, date)
    (22003000, 22024203, 1, 10006158, N'COVID_CASE', N'ARRIVAL_TRVL_DEST_DT', N'2026-03-01', 1, N'PG_COVID-19_v1.1', N'TRAVEL06', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'ARRIVAL_TRVL_DEST_DT', NULL, NULL, NULL),
    (22003000, 22024204, 1, 10006158, N'COVID_CASE', N'ARRIVAL_TRVL_DEST_DT', N'2026-03-02', 2, N'PG_COVID-19_v1.1', N'TRAVEL06', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'ARRIVAL_TRVL_DEST_DT', NULL, NULL, NULL),
    (22003000, 22024205, 1, 10006158, N'COVID_CASE', N'ARRIVAL_TRVL_DEST_DT', N'2026-03-03', 3, N'PG_COVID-19_v1.1', N'TRAVEL06', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'ARRIVAL_TRVL_DEST_DT', NULL, NULL, NULL),
    -- CDC_SPECIMEN_ID (q=10004232, freetext)
    (22003000, 22024206, 1, 10004232, N'COVID_CASE', N'CDC_SPECIMEN_ID', N'CDC-001', 1, N'PG_COVID-19_v1.1', N'INV965', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CDC_SPECIMEN_ID', NULL, NULL, NULL),
    (22003000, 22024207, 1, 10004232, N'COVID_CASE', N'CDC_SPECIMEN_ID', N'CDC-002', 2, N'PG_COVID-19_v1.1', N'INV965', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CDC_SPECIMEN_ID', NULL, NULL, NULL),
    (22003000, 22024208, 1, 10004232, N'COVID_CASE', N'CDC_SPECIMEN_ID', N'CDC-003', 3, N'PG_COVID-19_v1.1', N'INV965', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CDC_SPECIMEN_ID', NULL, NULL, NULL),
    -- CITY_OF_EXP (q=10001010, freetext)
    (22003000, 22024209, 1, 10001010, N'COVID_CASE', N'CITY_OF_EXP', N'Atlanta', 1, N'PG_COVID-19_v1.1', N'INV504', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CITY_OF_EXP', NULL, NULL, NULL),
    (22003000, 22024210, 1, 10001010, N'COVID_CASE', N'CITY_OF_EXP', N'Marietta', 2, N'PG_COVID-19_v1.1', N'INV504', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CITY_OF_EXP', NULL, NULL, NULL),
    (22003000, 22024211, 1, 10001010, N'COVID_CASE', N'CITY_OF_EXP', N'Decatur', 3, N'PG_COVID-19_v1.1', N'INV504', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CITY_OF_EXP', NULL, NULL, NULL),
    -- CNTRY_OF_EXP (q=10001008, coded codeset=3560)
    (22003000, 22024212, 1, 10001008, N'COVID_CASE', N'CNTRY_OF_EXP', N'USA', 1, N'PG_COVID-19_v1.1', N'INV502', N'NBS_Case_Answer.answer_txt', 3560, '2026-04-01T00:00:00', N'ACTIVE', N'CNTRY_OF_EXP', NULL, NULL, NULL),
    (22003000, 22024213, 1, 10001008, N'COVID_CASE', N'CNTRY_OF_EXP', N'USA', 2, N'PG_COVID-19_v1.1', N'INV502', N'NBS_Case_Answer.answer_txt', 3560, '2026-04-01T00:00:00', N'ACTIVE', N'CNTRY_OF_EXP', NULL, NULL, NULL),
    (22003000, 22024214, 1, 10001008, N'COVID_CASE', N'CNTRY_OF_EXP', N'USA', 3, N'PG_COVID-19_v1.1', N'INV502', N'NBS_Case_Answer.answer_txt', 3560, '2026-04-01T00:00:00', N'ACTIVE', N'CNTRY_OF_EXP', NULL, NULL, NULL),
    -- CNTY_OF_EXP (q=10001011, coded codeset=560)
    (22003000, 22024215, 1, 10001011, N'COVID_CASE', N'CNTY_OF_EXP', N'Y', 1, N'PG_COVID-19_v1.1', N'INV505', N'NBS_Case_Answer.answer_txt', 560, '2026-04-01T00:00:00', N'ACTIVE', N'CNTY_OF_EXP', NULL, NULL, NULL),
    (22003000, 22024216, 1, 10001011, N'COVID_CASE', N'CNTY_OF_EXP', N'Y', 2, N'PG_COVID-19_v1.1', N'INV505', N'NBS_Case_Answer.answer_txt', 560, '2026-04-01T00:00:00', N'ACTIVE', N'CNTY_OF_EXP', NULL, NULL, NULL),
    (22003000, 22024217, 1, 10001011, N'COVID_CASE', N'CNTY_OF_EXP', N'Y', 3, N'PG_COVID-19_v1.1', N'INV505', N'NBS_Case_Answer.answer_txt', 560, '2026-04-01T00:00:00', N'ACTIVE', N'CNTY_OF_EXP', NULL, NULL, NULL),
    -- CUR_OCCUPATION_TXT (q=10005133, freetext)
    (22003000, 22024218, 1, 10005133, N'COVID_CASE', N'CUR_OCCUPATION_TXT', N'Engineer', 1, N'PG_COVID-19_v1.1', N'85658_3', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CUR_OCCUPATION_TXT', NULL, NULL, NULL),
    (22003000, 22024219, 1, 10005133, N'COVID_CASE', N'CUR_OCCUPATION_TXT', N'Nurse', 2, N'PG_COVID-19_v1.1', N'85658_3', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CUR_OCCUPATION_TXT', NULL, NULL, NULL),
    (22003000, 22024220, 1, 10005133, N'COVID_CASE', N'CUR_OCCUPATION_TXT', N'Teacher', 3, N'PG_COVID-19_v1.1', N'85658_3', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CUR_OCCUPATION_TXT', NULL, NULL, NULL),
    -- CURRENT_INDUSTRY (q=10005134, coded codeset=109320)
    (22003000, 22024221, 1, 10005134, N'COVID_CASE', N'CURRENT_INDUSTRY', N'Y', 1, N'PG_COVID-19_v1.1', N'85657_5', N'NBS_Case_Answer.answer_txt', 109320, '2026-04-01T00:00:00', N'ACTIVE', N'CURRENT_INDUSTRY', NULL, NULL, NULL),
    (22003000, 22024222, 1, 10005134, N'COVID_CASE', N'CURRENT_INDUSTRY', N'Y', 2, N'PG_COVID-19_v1.1', N'85657_5', N'NBS_Case_Answer.answer_txt', 109320, '2026-04-01T00:00:00', N'ACTIVE', N'CURRENT_INDUSTRY', NULL, NULL, NULL),
    (22003000, 22024223, 1, 10005134, N'COVID_CASE', N'CURRENT_INDUSTRY', N'Y', 3, N'PG_COVID-19_v1.1', N'85657_5', N'NBS_Case_Answer.answer_txt', 109320, '2026-04-01T00:00:00', N'ACTIVE', N'CURRENT_INDUSTRY', NULL, NULL, NULL),
    -- CURRENT_INDUSTRY_TXT (q=10005135, freetext)
    (22003000, 22024224, 1, 10005135, N'COVID_CASE', N'CURRENT_INDUSTRY_TXT', N'Technology', 1, N'PG_COVID-19_v1.1', N'85078_4', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CURRENT_INDUSTRY_TXT', NULL, NULL, NULL),
    (22003000, 22024225, 1, 10005135, N'COVID_CASE', N'CURRENT_INDUSTRY_TXT', N'Healthcare', 2, N'PG_COVID-19_v1.1', N'85078_4', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CURRENT_INDUSTRY_TXT', NULL, NULL, NULL),
    (22003000, 22024226, 1, 10005135, N'COVID_CASE', N'CURRENT_INDUSTRY_TXT', N'Education', 3, N'PG_COVID-19_v1.1', N'85078_4', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CURRENT_INDUSTRY_TXT', NULL, NULL, NULL),
    -- CURRENT_OCCUPATION (q=10005132, coded codeset=109180)
    (22003000, 22024227, 1, 10005132, N'COVID_CASE', N'CURRENT_OCCUPATION', N'Y', 1, N'PG_COVID-19_v1.1', N'85659_1', N'NBS_Case_Answer.answer_txt', 109180, '2026-04-01T00:00:00', N'ACTIVE', N'CURRENT_OCCUPATION', NULL, NULL, NULL),
    (22003000, 22024228, 1, 10005132, N'COVID_CASE', N'CURRENT_OCCUPATION', N'Y', 2, N'PG_COVID-19_v1.1', N'85659_1', N'NBS_Case_Answer.answer_txt', 109180, '2026-04-01T00:00:00', N'ACTIVE', N'CURRENT_OCCUPATION', NULL, NULL, NULL),
    (22003000, 22024229, 1, 10005132, N'COVID_CASE', N'CURRENT_OCCUPATION', N'Y', 3, N'PG_COVID-19_v1.1', N'85659_1', N'NBS_Case_Answer.answer_txt', 109180, '2026-04-01T00:00:00', N'ACTIVE', N'CURRENT_OCCUPATION', NULL, NULL, NULL),
    -- DEPART_TRVL_DEST_DT (q=10006159, date)
    (22003000, 22024230, 1, 10006159, N'COVID_CASE', N'DEPART_TRVL_DEST_DT', N'2026-03-10', 1, N'PG_COVID-19_v1.1', N'TRAVEL07', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'DEPART_TRVL_DEST_DT', NULL, NULL, NULL),
    (22003000, 22024231, 1, 10006159, N'COVID_CASE', N'DEPART_TRVL_DEST_DT', N'2026-03-11', 2, N'PG_COVID-19_v1.1', N'TRAVEL07', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'DEPART_TRVL_DEST_DT', NULL, NULL, NULL),
    (22003000, 22024232, 1, 10006159, N'COVID_CASE', N'DEPART_TRVL_DEST_DT', N'2026-03-12', 3, N'PG_COVID-19_v1.1', N'TRAVEL07', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'DEPART_TRVL_DEST_DT', NULL, NULL, NULL),
    -- DURATION_OUTSIDE_US (q=10006160, numeric)
    (22003000, 22024233, 1, 10006160, N'COVID_CASE', N'DURATION_OUTSIDE_US', N'5', 1, N'PG_COVID-19_v1.1', N'82310_4', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'DURATION_OUTSIDE_US', NULL, NULL, NULL),
    (22003000, 22024234, 1, 10006160, N'COVID_CASE', N'DURATION_OUTSIDE_US', N'7', 2, N'PG_COVID-19_v1.1', N'82310_4', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'DURATION_OUTSIDE_US', NULL, NULL, NULL),
    (22003000, 22024235, 1, 10006160, N'COVID_CASE', N'DURATION_OUTSIDE_US', N'10', 3, N'PG_COVID-19_v1.1', N'82310_4', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'DURATION_OUTSIDE_US', NULL, NULL, NULL),
    -- INTL_DESTINATIONS (q=10004154, coded codeset=3560)
    (22003000, 22024236, 1, 10004154, N'COVID_CASE', N'INTL_DESTINATIONS', N'USA', 1, N'PG_COVID-19_v1.1', N'TRAVEL05', N'NBS_Case_Answer.answer_txt', 3560, '2026-04-01T00:00:00', N'ACTIVE', N'INTL_DESTINATIONS', NULL, NULL, NULL),
    (22003000, 22024237, 1, 10004154, N'COVID_CASE', N'INTL_DESTINATIONS', N'USA', 2, N'PG_COVID-19_v1.1', N'TRAVEL05', N'NBS_Case_Answer.answer_txt', 3560, '2026-04-01T00:00:00', N'ACTIVE', N'INTL_DESTINATIONS', NULL, NULL, NULL),
    (22003000, 22024238, 1, 10004154, N'COVID_CASE', N'INTL_DESTINATIONS', N'USA', 3, N'PG_COVID-19_v1.1', N'TRAVEL05', N'NBS_Case_Answer.answer_txt', 3560, '2026-04-01T00:00:00', N'ACTIVE', N'INTL_DESTINATIONS', NULL, NULL, NULL),
    -- ISOLTE_SENT_STATE_LAB (q=10004227, coded codeset=4150)
    (22003000, 22024239, 1, 10004227, N'COVID_CASE', N'ISOLTE_SENT_STATE_LAB', N'Y', 1, N'PG_COVID-19_v1.1', N'LAB331', N'NBS_Case_Answer.answer_txt', 4150, '2026-04-01T00:00:00', N'ACTIVE', N'ISOLTE_SENT_STATE_LAB', NULL, NULL, NULL),
    (22003000, 22024240, 1, 10004227, N'COVID_CASE', N'ISOLTE_SENT_STATE_LAB', N'Y', 2, N'PG_COVID-19_v1.1', N'LAB331', N'NBS_Case_Answer.answer_txt', 4150, '2026-04-01T00:00:00', N'ACTIVE', N'ISOLTE_SENT_STATE_LAB', NULL, NULL, NULL),
    (22003000, 22024241, 1, 10004227, N'COVID_CASE', N'ISOLTE_SENT_STATE_LAB', N'Y', 3, N'PG_COVID-19_v1.1', N'LAB331', N'NBS_Case_Answer.answer_txt', 4150, '2026-04-01T00:00:00', N'ACTIVE', N'ISOLTE_SENT_STATE_LAB', NULL, NULL, NULL),
    -- LAB_RESULT_NUM_UNIT (q=10002097, coded codeset=4080)
    (22003000, 22024242, 1, 10002097, N'COVID_CASE', N'LAB_RESULT_NUM_UNIT', N'Y', 1, N'PG_COVID-19_v1.1', N'LAB115', N'NBS_Case_Answer.answer_txt', 4080, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_RESULT_NUM_UNIT', NULL, NULL, NULL),
    (22003000, 22024243, 1, 10002097, N'COVID_CASE', N'LAB_RESULT_NUM_UNIT', N'Y', 2, N'PG_COVID-19_v1.1', N'LAB115', N'NBS_Case_Answer.answer_txt', 4080, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_RESULT_NUM_UNIT', NULL, NULL, NULL),
    (22003000, 22024244, 1, 10002097, N'COVID_CASE', N'LAB_RESULT_NUM_UNIT', N'Y', 3, N'PG_COVID-19_v1.1', N'LAB115', N'NBS_Case_Answer.answer_txt', 4080, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_RESULT_NUM_UNIT', NULL, NULL, NULL),
    -- OTH_PATHOGEN_TST (q=10004253, freetext)
    (22003000, 22024245, 1, 10004253, N'COVID_CASE', N'OTH_PATHOGEN_TST', N'PathTest1', 1, N'PG_COVID-19_v1.1', N'NBS669', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'OTH_PATHOGEN_TST', NULL, NULL, NULL),
    (22003000, 22024246, 1, 10004253, N'COVID_CASE', N'OTH_PATHOGEN_TST', N'PathTest2', 2, N'PG_COVID-19_v1.1', N'NBS669', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'OTH_PATHOGEN_TST', NULL, NULL, NULL),
    (22003000, 22024247, 1, 10004253, N'COVID_CASE', N'OTH_PATHOGEN_TST', N'PathTest3', 3, N'PG_COVID-19_v1.1', N'NBS669', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'OTH_PATHOGEN_TST', NULL, NULL, NULL),
    -- OTH_PATHOGEN_TST_RSLT (q=10004254, coded codeset=108280)
    (22003000, 22024248, 1, 10004254, N'COVID_CASE', N'OTH_PATHOGEN_TST_RSLT', N'Y', 1, N'PG_COVID-19_v1.1', N'NBS668', N'NBS_Case_Answer.answer_txt', 108280, '2026-04-01T00:00:00', N'ACTIVE', N'OTH_PATHOGEN_TST_RSLT', NULL, NULL, NULL),
    (22003000, 22024249, 1, 10004254, N'COVID_CASE', N'OTH_PATHOGEN_TST_RSLT', N'Y', 2, N'PG_COVID-19_v1.1', N'NBS668', N'NBS_Case_Answer.answer_txt', 108280, '2026-04-01T00:00:00', N'ACTIVE', N'OTH_PATHOGEN_TST_RSLT', NULL, NULL, NULL),
    (22003000, 22024250, 1, 10004254, N'COVID_CASE', N'OTH_PATHOGEN_TST_RSLT', N'Y', 3, N'PG_COVID-19_v1.1', N'NBS668', N'NBS_Case_Answer.answer_txt', 108280, '2026-04-01T00:00:00', N'ACTIVE', N'OTH_PATHOGEN_TST_RSLT', NULL, NULL, NULL),
    -- QUANT_TEST_RESULT (q=10002143, numeric)
    (22003000, 22024251, 1, 10002143, N'COVID_CASE', N'QUANT_TEST_RESULT', N'1.5', 1, N'PG_COVID-19_v1.1', N'LAB628', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'QUANT_TEST_RESULT', NULL, NULL, NULL),
    (22003000, 22024252, 1, 10002143, N'COVID_CASE', N'QUANT_TEST_RESULT', N'2.5', 2, N'PG_COVID-19_v1.1', N'LAB628', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'QUANT_TEST_RESULT', NULL, NULL, NULL),
    (22003000, 22024253, 1, 10002143, N'COVID_CASE', N'QUANT_TEST_RESULT', N'3.5', 3, N'PG_COVID-19_v1.1', N'LAB628', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'QUANT_TEST_RESULT', NULL, NULL, NULL),
    -- SPCMN_COLLECTION_DT (q=10002108, date)
    (22003000, 22024254, 1, 10002108, N'COVID_CASE', N'SPCMN_COLLECTION_DT', N'2026-03-15', 1, N'PG_COVID-19_v1.1', N'LAB163', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'SPCMN_COLLECTION_DT', NULL, NULL, NULL),
    (22003000, 22024255, 1, 10002108, N'COVID_CASE', N'SPCMN_COLLECTION_DT', N'2026-03-16', 2, N'PG_COVID-19_v1.1', N'LAB163', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'SPCMN_COLLECTION_DT', NULL, NULL, NULL),
    (22003000, 22024256, 1, 10002108, N'COVID_CASE', N'SPCMN_COLLECTION_DT', N'2026-03-17', 3, N'PG_COVID-19_v1.1', N'LAB163', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'SPCMN_COLLECTION_DT', NULL, NULL, NULL),
    -- SPCMN_SENT_TO_CDC_DT (q=10004231, date)
    (22003000, 22024257, 1, 10004231, N'COVID_CASE', N'SPCMN_SENT_TO_CDC_DT', N'2026-03-18', 1, N'PG_COVID-19_v1.1', N'LAB516', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'SPCMN_SENT_TO_CDC_DT', NULL, NULL, NULL),
    (22003000, 22024258, 1, 10004231, N'COVID_CASE', N'SPCMN_SENT_TO_CDC_DT', N'2026-03-19', 2, N'PG_COVID-19_v1.1', N'LAB516', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'SPCMN_SENT_TO_CDC_DT', NULL, NULL, NULL),
    (22003000, 22024259, 1, 10004231, N'COVID_CASE', N'SPCMN_SENT_TO_CDC_DT', N'2026-03-20', 3, N'PG_COVID-19_v1.1', N'LAB516', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'SPCMN_SENT_TO_CDC_DT', NULL, NULL, NULL),
    -- SPCMN_SENT_TO_CDC_IND (q=10004230, coded codeset=4150)
    (22003000, 22024260, 1, 10004230, N'COVID_CASE', N'SPCMN_SENT_TO_CDC_IND', N'Y', 1, N'PG_COVID-19_v1.1', N'LAB515', N'NBS_Case_Answer.answer_txt', 4150, '2026-04-01T00:00:00', N'ACTIVE', N'SPCMN_SENT_TO_CDC_IND', NULL, NULL, NULL),
    (22003000, 22024261, 1, 10004230, N'COVID_CASE', N'SPCMN_SENT_TO_CDC_IND', N'Y', 2, N'PG_COVID-19_v1.1', N'LAB515', N'NBS_Case_Answer.answer_txt', 4150, '2026-04-01T00:00:00', N'ACTIVE', N'SPCMN_SENT_TO_CDC_IND', NULL, NULL, NULL),
    (22003000, 22024262, 1, 10004230, N'COVID_CASE', N'SPCMN_SENT_TO_CDC_IND', N'Y', 3, N'PG_COVID-19_v1.1', N'LAB515', N'NBS_Case_Answer.answer_txt', 4150, '2026-04-01T00:00:00', N'ACTIVE', N'SPCMN_SENT_TO_CDC_IND', NULL, NULL, NULL),
    -- SPEC_SENT_TO_SPHL_DT (q=10004228, date)
    (22003000, 22024263, 1, 10004228, N'COVID_CASE', N'SPEC_SENT_TO_SPHL_DT', N'2026-03-21', 1, N'PG_COVID-19_v1.1', N'NBS564', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'SPEC_SENT_TO_SPHL_DT', NULL, NULL, NULL),
    (22003000, 22024264, 1, 10004228, N'COVID_CASE', N'SPEC_SENT_TO_SPHL_DT', N'2026-03-22', 2, N'PG_COVID-19_v1.1', N'NBS564', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'SPEC_SENT_TO_SPHL_DT', NULL, NULL, NULL),
    (22003000, 22024265, 1, 10004228, N'COVID_CASE', N'SPEC_SENT_TO_SPHL_DT', N'2026-03-23', 3, N'PG_COVID-19_v1.1', N'NBS564', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'SPEC_SENT_TO_SPHL_DT', NULL, NULL, NULL),
    -- SPECIMEN_ID (q=10004225, freetext)
    (22003000, 22024266, 1, 10004225, N'COVID_CASE', N'SPECIMEN_ID', N'SP-001', 1, N'PG_COVID-19_v1.1', N'NBS674', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'SPECIMEN_ID', NULL, NULL, NULL),
    (22003000, 22024267, 1, 10004225, N'COVID_CASE', N'SPECIMEN_ID', N'SP-002', 2, N'PG_COVID-19_v1.1', N'NBS674', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'SPECIMEN_ID', NULL, NULL, NULL),
    (22003000, 22024268, 1, 10004225, N'COVID_CASE', N'SPECIMEN_ID', N'SP-003', 3, N'PG_COVID-19_v1.1', N'NBS674', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'SPECIMEN_ID', NULL, NULL, NULL),
    -- SPECIMEN_SOURCE (q=10002114, coded codeset=107950)
    (22003000, 22024269, 1, 10002114, N'COVID_CASE', N'SPECIMEN_SOURCE', N'Y', 1, N'PG_COVID-19_v1.1', N'LAB165', N'NBS_Case_Answer.answer_txt', 107950, '2026-04-01T00:00:00', N'ACTIVE', N'SPECIMEN_SOURCE', NULL, NULL, NULL),
    (22003000, 22024270, 1, 10002114, N'COVID_CASE', N'SPECIMEN_SOURCE', N'Y', 2, N'PG_COVID-19_v1.1', N'LAB165', N'NBS_Case_Answer.answer_txt', 107950, '2026-04-01T00:00:00', N'ACTIVE', N'SPECIMEN_SOURCE', NULL, NULL, NULL),
    (22003000, 22024271, 1, 10002114, N'COVID_CASE', N'SPECIMEN_SOURCE', N'Y', 3, N'PG_COVID-19_v1.1', N'LAB165', N'NBS_Case_Answer.answer_txt', 107950, '2026-04-01T00:00:00', N'ACTIVE', N'SPECIMEN_SOURCE', NULL, NULL, NULL),
    -- ST_OR_PROV_OF_EXP (q=10001009, coded codeset=102970)
    (22003000, 22024272, 1, 10001009, N'COVID_CASE', N'ST_OR_PROV_OF_EXP', N'GA', 1, N'PG_COVID-19_v1.1', N'INV503', N'NBS_Case_Answer.answer_txt', 102970, '2026-04-01T00:00:00', N'ACTIVE', N'ST_OR_PROV_OF_EXP', NULL, NULL, NULL),
    (22003000, 22024273, 1, 10001009, N'COVID_CASE', N'ST_OR_PROV_OF_EXP', N'GA', 2, N'PG_COVID-19_v1.1', N'INV503', N'NBS_Case_Answer.answer_txt', 102970, '2026-04-01T00:00:00', N'ACTIVE', N'ST_OR_PROV_OF_EXP', NULL, NULL, NULL),
    (22003000, 22024274, 1, 10001009, N'COVID_CASE', N'ST_OR_PROV_OF_EXP', N'GA', 3, N'PG_COVID-19_v1.1', N'INV503', N'NBS_Case_Answer.answer_txt', 102970, '2026-04-01T00:00:00', N'ACTIVE', N'ST_OR_PROV_OF_EXP', NULL, NULL, NULL),
    -- STATE_ISOLATE_ID (q=10004229, freetext)
    (22003000, 22024275, 1, 10004229, N'COVID_CASE', N'STATE_ISOLATE_ID', N'STATE-001', 1, N'PG_COVID-19_v1.1', N'FDD_Q_1141', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'STATE_ISOLATE_ID', NULL, NULL, NULL),
    (22003000, 22024276, 1, 10004229, N'COVID_CASE', N'STATE_ISOLATE_ID', N'STATE-002', 2, N'PG_COVID-19_v1.1', N'FDD_Q_1141', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'STATE_ISOLATE_ID', NULL, NULL, NULL),
    (22003000, 22024277, 1, 10004229, N'COVID_CASE', N'STATE_ISOLATE_ID', N'STATE-003', 3, N'PG_COVID-19_v1.1', N'FDD_Q_1141', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'STATE_ISOLATE_ID', NULL, NULL, NULL),
    -- TEST_RESULT_COMMENTS (q=10004226, freetext - data_location is NBS_CASE_ANSWER.ANSWER_TXT but works similar)
    (22003000, 22024278, 1, 10004226, N'COVID_CASE', N'TEST_RESULT_COMMENTS', N'Test comment 1', 1, N'PG_COVID-19_v1.1', N'8251_1', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'TEST_RESULT_COMMENTS', NULL, NULL, NULL),
    (22003000, 22024279, 1, 10004226, N'COVID_CASE', N'TEST_RESULT_COMMENTS', N'Test comment 2', 2, N'PG_COVID-19_v1.1', N'8251_1', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'TEST_RESULT_COMMENTS', NULL, NULL, NULL),
    (22003000, 22024280, 1, 10004226, N'COVID_CASE', N'TEST_RESULT_COMMENTS', N'Test comment 3', 3, N'PG_COVID-19_v1.1', N'8251_1', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'TEST_RESULT_COMMENTS', NULL, NULL, NULL),
    -- TRAVEL_INFORMATION (q=10006161, freetext)
    (22003000, 22024281, 1, 10006161, N'COVID_CASE', N'TRAVEL_INFORMATION', N'Travel info 1', 1, N'PG_COVID-19_v1.1', N'TRAVEL23', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'TRAVEL_INFORMATION', NULL, NULL, NULL),
    (22003000, 22024282, 1, 10006161, N'COVID_CASE', N'TRAVEL_INFORMATION', N'Travel info 2', 2, N'PG_COVID-19_v1.1', N'TRAVEL23', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'TRAVEL_INFORMATION', NULL, NULL, NULL),
    (22003000, 22024283, 1, 10006161, N'COVID_CASE', N'TRAVEL_INFORMATION', N'Travel info 3', 3, N'PG_COVID-19_v1.1', N'TRAVEL23', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'TRAVEL_INFORMATION', NULL, NULL, NULL),
    -- TRAVEL_MODE (q=10006157, coded codeset=108540)
    (22003000, 22024284, 1, 10006157, N'COVID_CASE', N'TRAVEL_MODE', N'Y', 1, N'PG_COVID-19_v1.1', N'NBS453', N'NBS_Case_Answer.answer_txt', 108540, '2026-04-01T00:00:00', N'ACTIVE', N'TRAVEL_MODE', NULL, NULL, NULL),
    (22003000, 22024285, 1, 10006157, N'COVID_CASE', N'TRAVEL_MODE', N'Y', 2, N'PG_COVID-19_v1.1', N'NBS453', N'NBS_Case_Answer.answer_txt', 108540, '2026-04-01T00:00:00', N'ACTIVE', N'TRAVEL_MODE', NULL, NULL, NULL),
    (22003000, 22024286, 1, 10006157, N'COVID_CASE', N'TRAVEL_MODE', N'Y', 3, N'PG_COVID-19_v1.1', N'NBS453', N'NBS_Case_Answer.answer_txt', 108540, '2026-04-01T00:00:00', N'ACTIVE', N'TRAVEL_MODE', NULL, NULL, NULL),
    -- TRAVEL_STATE (q=10004152, coded codeset=3920)
    (22003000, 22024287, 1, 10004152, N'COVID_CASE', N'TRAVEL_STATE', N'GA', 1, N'PG_COVID-19_v1.1', N'82754_3', N'NBS_Case_Answer.answer_txt', 3920, '2026-04-01T00:00:00', N'ACTIVE', N'TRAVEL_STATE', NULL, NULL, NULL),
    (22003000, 22024288, 1, 10004152, N'COVID_CASE', N'TRAVEL_STATE', N'GA', 2, N'PG_COVID-19_v1.1', N'82754_3', N'NBS_Case_Answer.answer_txt', 3920, '2026-04-01T00:00:00', N'ACTIVE', N'TRAVEL_STATE', NULL, NULL, NULL),
    (22003000, 22024289, 1, 10004152, N'COVID_CASE', N'TRAVEL_STATE', N'GA', 3, N'PG_COVID-19_v1.1', N'82754_3', N'NBS_Case_Answer.answer_txt', 3920, '2026-04-01T00:00:00', N'ACTIVE', N'TRAVEL_STATE', NULL, NULL, NULL),
    -- VHF_TRAVEL_REASON (q=10001082, coded codeset=4830)
    (22003000, 22024290, 1, 10001082, N'COVID_CASE', N'VHF_TRAVEL_REASON', N'Y', 1, N'PG_COVID-19_v1.1', N'TRAVEL16', N'NBS_Case_Answer.answer_txt', 4830, '2026-04-01T00:00:00', N'ACTIVE', N'VHF_TRAVEL_REASON', NULL, NULL, NULL),
    (22003000, 22024291, 1, 10001082, N'COVID_CASE', N'VHF_TRAVEL_REASON', N'Y', 2, N'PG_COVID-19_v1.1', N'TRAVEL16', N'NBS_Case_Answer.answer_txt', 4830, '2026-04-01T00:00:00', N'ACTIVE', N'VHF_TRAVEL_REASON', NULL, NULL, NULL),
    (22003000, 22024292, 1, 10001082, N'COVID_CASE', N'VHF_TRAVEL_REASON', N'Y', 3, N'PG_COVID-19_v1.1', N'TRAVEL16', N'NBS_Case_Answer.answer_txt', 4830, '2026-04-01T00:00:00', N'ACTIVE', N'VHF_TRAVEL_REASON', NULL, NULL, NULL),
    -- WGS_ID_NBR (q=10010279, numeric)
    (22003000, 22024293, 1, 10010279, N'COVID_CASE', N'WGS_ID_NBR', N'WGS-001', 1, N'PG_COVID-19_v1.1', N'INV949', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'WGS_ID_NBR', NULL, NULL, NULL),
    (22003000, 22024294, 1, 10010279, N'COVID_CASE', N'WGS_ID_NBR', N'WGS-002', 2, N'PG_COVID-19_v1.1', N'INV949', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'WGS_ID_NBR', NULL, NULL, NULL),
    (22003000, 22024295, 1, 10010279, N'COVID_CASE', N'WGS_ID_NBR', N'WGS-003', 3, N'PG_COVID-19_v1.1', N'INV949', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'WGS_ID_NBR', NULL, NULL, NULL);
END;
GO

-- ---------------------------------------------------------------------
-- Section 5b: FIX up Section 5 rows — set seq_nbr=1.
-- The 12 non-repeating PG_COVID cols are nbs_ui_component_uid=1013
-- (multi-answer), so the SP routes them through #COVID_CASE_MULTI_ANS_DATA
-- which REQUIRES seq_nbr IS NOT NULL. Update existing rows.
-- ---------------------------------------------------------------------

UPDATE [dbo].[nrt_page_case_answer]
SET seq_nbr = 1
WHERE nbs_case_answer_uid BETWEEN 22024100 AND 22024111
  AND seq_nbr IS NULL;
GO

-- ---------------------------------------------------------------------
-- Section 7: nrt_page_case_answer rows for partial-repeating cols.
-- These have only the _2 and _3 datamart cols unpopulated; the _1 is
-- already populated by foundation data. We need answers with
-- answer_group_seq_nbr=2 and 3.
-- UIDs 22024400..22024405.
-- ---------------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 FROM [dbo].[nrt_page_case_answer]
    WHERE nbs_case_answer_uid = 22024400
)
BEGIN
    INSERT INTO [dbo].[nrt_page_case_answer]
        ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid],
         [nbs_question_uid],
         [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr],
         [investigation_form_cd], [question_identifier], [data_location],
         [code_set_group_id], [last_chg_time], [record_status_cd],
         [datamart_column_nm], [ldf_status_cd], [seq_nbr], [batch_id])
    VALUES
    -- PERFORMING_LAB_TYPE (q=10001374, coded codeset=108620) - need _2, _3
    (22003000, 22024400, 1, 10001374, N'COVID_CASE', N'PERFORMING_LAB_TYPE', N'Y', 2, N'PG_COVID-19_v1.1', N'LAB606', N'NBS_Case_Answer.answer_txt', 108620, '2026-04-01T00:00:00', N'ACTIVE', N'PERFORMING_LAB_TYPE', NULL, NULL, NULL),
    (22003000, 22024401, 1, 10001374, N'COVID_CASE', N'PERFORMING_LAB_TYPE', N'Y', 3, N'PG_COVID-19_v1.1', N'LAB606', N'NBS_Case_Answer.answer_txt', 108620, '2026-04-01T00:00:00', N'ACTIVE', N'PERFORMING_LAB_TYPE', NULL, NULL, NULL),
    -- TEST_RESULT (q=10001371, coded codeset=108610) - need _2, _3
    (22003000, 22024402, 1, 10001371, N'COVID_CASE', N'TEST_RESULT', N'Y', 2, N'PG_COVID-19_v1.1', N'INV291', N'NBS_Case_Answer.answer_txt', 108610, '2026-04-01T00:00:00', N'ACTIVE', N'TEST_RESULT', NULL, NULL, NULL),
    (22003000, 22024403, 1, 10001371, N'COVID_CASE', N'TEST_RESULT', N'Y', 3, N'PG_COVID-19_v1.1', N'INV291', N'NBS_Case_Answer.answer_txt', 108610, '2026-04-01T00:00:00', N'ACTIVE', N'TEST_RESULT', NULL, NULL, NULL),
    -- TEST_TYPE (q=10001370, coded codeset=108020) - need _2, _3
    (22003000, 22024404, 1, 10001370, N'COVID_CASE', N'TEST_TYPE', N'Y', 2, N'PG_COVID-19_v1.1', N'INV290', N'NBS_Case_Answer.answer_txt', 108020, '2026-04-01T00:00:00', N'ACTIVE', N'TEST_TYPE', NULL, NULL, NULL),
    (22003000, 22024405, 1, 10001370, N'COVID_CASE', N'TEST_TYPE', N'Y', 3, N'PG_COVID-19_v1.1', N'INV290', N'NBS_Case_Answer.answer_txt', 108020, '2026-04-01T00:00:00', N'ACTIVE', N'TEST_TYPE', NULL, NULL, NULL);
END;
GO

-- ---------------------------------------------------------------------
-- Tail EXEC: refresh covid_case_datamart so coverage reflects changes.
-- ---------------------------------------------------------------------

BEGIN TRY
    EXEC dbo.sp_covid_case_datamart_postprocessing @phc_uids = N'22003000', @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'sp_covid_case_datamart_postprocessing failed: ' + ERROR_MESSAGE();
END CATCH;
GO
