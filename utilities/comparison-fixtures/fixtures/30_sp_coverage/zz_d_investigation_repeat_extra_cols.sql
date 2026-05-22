-- =====================================================================
-- Tier 3 — Extra rdb_column_nm coverage for D_INVESTIGATION_REPEAT
-- =====================================================================
-- Authored 2026-05-22 (overnight, post bug #9/#10 fixes).
--
-- Goal: populate more BASELINE-DEFINED columns in D_INVESTIGATION_REPEAT.
-- The Pertussis fixture (22006000) authored 8 NEW rdb_column_nm values
-- (TRAVEL_*, EXPOSURE_*) which grew the schema by +8 cols.  But D_INV_REPEAT
-- has ~248 baseline-seeded columns (EPI_*, CLN_*, ADM_*, CMP_*, ...) that
-- are still NULL because no nrt_page_case_answer rows target them.
--
-- Adding answers with rdb_column_nm = existing baseline col name
-- populates that column without growing the schema width.  Net coverage
-- impact = +1 per column populated (numerator only, denominator stays
-- at 256).
--
-- Pattern: piggyback on Pertussis fixture's 6 dim slots
-- (TRAVEL_BLOCK × 3 seq, EXPOSURE_BLOCK × 3 seq) — additional answers
-- with matching (act_uid=22006000, block_nm, answer_group_seq_nbr,
-- new rdb_column_nm) populate the new columns on the SAME dim rows.
--
-- UID block: 22006200-22006499 (300 reserved, comfortable for 50+ rows).
-- Sort prefix: zz_ so this applies AFTER d_investigation_repeat.sql
-- (the SP runs once at Step 8.5 against all PHC_UIDS; both sets of
-- answers are picked up in one pass).
-- =====================================================================

USE [RDB_MODERN];
GO

INSERT INTO [dbo].[nrt_page_case_answer]
    ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid],
     [nbs_question_uid],
     [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr],
     [investigation_form_cd], [question_identifier], [data_location],
     [code_set_group_id], [last_chg_time], [record_status_cd],
     [datamart_column_nm], [ldf_status_cd], [seq_nbr], [batch_id],
     [data_type], [question_group_seq_nbr], [block_nm],
     [unit_value], [unit_type_cd])
VALUES
    -- ===== TRAVEL_BLOCK seq 1: 5 baseline EPI/CLN cols =====
    (22006000, 22006200, 1, 22006020, N'D_INVESTIGATION_REPEAT', N'EPI_CITY_OF_EXP',
     N'Atlanta', 1, N'PG_Pertussis_Investigation', N'INV820',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_CITY_OF_EXP', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006201, 1, 22006021, N'D_INVESTIGATION_REPEAT', N'EPI_CNTRY_OF_EXP',
     N'United States', 1, N'PG_Pertussis_Investigation', N'INV821',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_CNTRY_OF_EXP', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006202, 1, 22006022, N'D_INVESTIGATION_REPEAT', N'EPI_CNTY_OF_EXP',
     N'Fulton', 1, N'PG_Pertussis_Investigation', N'INV822',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_CNTY_OF_EXP', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006203, 1, 22006023, N'D_INVESTIGATION_REPEAT', N'EPI_ST_OR_PROV_OF_EXP',
     N'GA', 1, N'PG_Pertussis_Investigation', N'INV823',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_ST_OR_PROV_OF_EXP', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006204, 1, 22006024, N'D_INVESTIGATION_REPEAT', N'EPI_BLOOD_DONATION_DT',
     N'02/10/26', 1, N'PG_Pertussis_Investigation', N'INV824',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_BLOOD_DONATION_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),

    -- ===== TRAVEL_BLOCK seq 2: 5 more baseline cols =====
    (22006000, 22006210, 1, 22006020, N'D_INVESTIGATION_REPEAT', N'EPI_CITY_OF_EXP',
     N'Savannah', 2, N'PG_Pertussis_Investigation', N'INV820',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_CITY_OF_EXP', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006211, 1, 22006030, N'D_INVESTIGATION_REPEAT', N'EPI_MASK_WORN_FREQUENCY',
     N'Always', 2, N'PG_Pertussis_Investigation', N'INV830',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_MASK_WORN_FREQUENCY', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006212, 1, 22006031, N'D_INVESTIGATION_REPEAT', N'EPI_MASK_WORN_TRAVELING',
     N'Yes', 2, N'PG_Pertussis_Investigation', N'INV831',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_MASK_WORN_TRAVELING', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006213, 1, 22006032, N'D_INVESTIGATION_REPEAT', N'EPI_OTHER_MEAT_TYPE',
     N'Pork', 2, N'PG_Pertussis_Investigation', N'INV832',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_OTHER_MEAT_TYPE', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006214, 1, 22006033, N'D_INVESTIGATION_REPEAT', N'EPI_BLOOD_TRANSFUSION_DT',
     N'01/15/26', 2, N'PG_Pertussis_Investigation', N'INV833',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_BLOOD_TRANSFUSION_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),

    -- ===== TRAVEL_BLOCK seq 3: 5 more baseline cols =====
    (22006000, 22006220, 1, 22006040, N'D_INVESTIGATION_REPEAT', N'EPI_SUSPECTED_SOURCE_AGE',
     N'42', 3, N'PG_Pertussis_Investigation', N'INV840',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_SUSPECTED_SOURCE_AGE', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006221, 1, 22006041, N'D_INVESTIGATION_REPEAT', N'EPI_SUSPECTED_SOURCE_RELATION',
     N'Coworker', 3, N'PG_Pertussis_Investigation', N'INV841',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_SUSPECTED_SOURCE_RELATION', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006222, 1, 22006042, N'D_INVESTIGATION_REPEAT', N'EPI_SUSPECTED_SOURCE_SEX',
     N'F', 3, N'PG_Pertussis_Investigation', N'INV842',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_SUSPECTED_SOURCE_SEX', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006223, 1, 22006043, N'D_INVESTIGATION_REPEAT', N'EPI_SUSPCTD_SRC_COUGH_ONSET_DT',
     N'02/28/26', 3, N'PG_Pertussis_Investigation', N'INV843',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_SUSPCTD_SRC_COUGH_ONSET_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006224, 1, 22006044, N'D_INVESTIGATION_REPEAT', N'EPI_DATE_OF_READING',
     N'03/05/26', 3, N'PG_Pertussis_Investigation', N'INV844',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_DATE_OF_READING', NULL, 1, NULL,
     N'DATE', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),

    -- ===== EXPOSURE_BLOCK seq 1: 5 CLN_* baseline cols =====
    (22006000, 22006230, 1, 22006050, N'D_INVESTIGATION_REPEAT', N'CLN_ADMITTED_AS_INPATIENT',
     N'Yes', 1, N'PG_Pertussis_Investigation', N'INV850',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CLN_ADMITTED_AS_INPATIENT', NULL, 1, NULL,
     N'TEXT', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006231, 1, 22006051, N'D_INVESTIGATION_REPEAT', N'CLN_DIAGNOSIS_TYPE',
     N'Confirmed', 1, N'PG_Pertussis_Investigation', N'INV851',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CLN_DIAGNOSIS_TYPE', NULL, 1, NULL,
     N'TEXT', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006232, 1, 22006052, N'D_INVESTIGATION_REPEAT', N'CLN_HOSPITAL_NAME',
     N'Grady Memorial Hospital', 1, N'PG_Pertussis_Investigation', N'INV852',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CLN_HOSPITAL_NAME', NULL, 1, NULL,
     N'TEXT', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006233, 1, 22006053, N'D_INVESTIGATION_REPEAT', N'CLN_HOSPITAL_RECORD_NBR',
     N'GMH-2026-00042', 1, N'PG_Pertussis_Investigation', N'INV853',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CLN_HOSPITAL_RECORD_NBR', NULL, 1, NULL,
     N'TEXT', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006234, 1, 22006054, N'D_INVESTIGATION_REPEAT', N'CLN_ADMISSION_DATE',
     N'03/16/26', 1, N'PG_Pertussis_Investigation', N'INV854',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CLN_ADMISSION_DATE', NULL, 1, NULL,
     N'DATE', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),

    -- ===== EXPOSURE_BLOCK seq 2: 5 more CLN_*/ADM_* baseline cols =====
    (22006000, 22006240, 1, 22006060, N'D_INVESTIGATION_REPEAT', N'CLN_DISCHARGE_DATE',
     N'03/22/26', 2, N'PG_Pertussis_Investigation', N'INV860',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CLN_DISCHARGE_DATE', NULL, 1, NULL,
     N'DATE', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006241, 1, 22006061, N'D_INVESTIGATION_REPEAT', N'CLN_HSPTL_DUR_DAYS',
     N'6', 2, N'PG_Pertussis_Investigation', N'INV861',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CLN_HSPTL_DUR_DAYS', NULL, 1, NULL,
     N'NUMERIC', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006242, 1, 22006062, N'D_INVESTIGATION_REPEAT', N'ADM_ADV_EVE_IND',
     N'N', 2, N'PG_Pertussis_Investigation', N'INV862',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'ADM_ADV_EVE_IND', NULL, 1, NULL,
     N'CODED', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006243, 1, 22006063, N'D_INVESTIGATION_REPEAT', N'ADM_LINKED_CASE_NBR',
     N'CASE-LINK-2026-007', 2, N'PG_Pertussis_Investigation', N'INV863',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'ADM_LINKED_CASE_NBR', NULL, 1, NULL,
     N'TEXT', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006244, 1, 22006064, N'D_INVESTIGATION_REPEAT', N'ADM_PREV_STATE_CASE_NBR',
     N'GA-2025-009432', 2, N'PG_Pertussis_Investigation', N'INV864',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'ADM_PREV_STATE_CASE_NBR', NULL, 1, NULL,
     N'TEXT', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),

    -- ===== EXPOSURE_BLOCK seq 3: 5 CMP_* + 1 more EPI_ baseline cols =====
    (22006000, 22006250, 1, 22006070, N'D_INVESTIGATION_REPEAT', N'CMP_COMPLICATION_IND',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INV870',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CMP_COMPLICATION_IND', NULL, 1, NULL,
     N'CODED', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006251, 1, 22006071, N'D_INVESTIGATION_REPEAT', N'CMP_COMPLICATION',
     N'Pneumonia', 3, N'PG_Pertussis_Investigation', N'INV871',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CMP_COMPLICATION', NULL, 1, NULL,
     N'TEXT', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006252, 1, 22006072, N'D_INVESTIGATION_REPEAT', N'CMP_ADVERSE_EVENT',
     N'None', 3, N'PG_Pertussis_Investigation', N'INV872',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CMP_ADVERSE_EVENT', NULL, 1, NULL,
     N'TEXT', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006253, 1, 22006073, N'D_INVESTIGATION_REPEAT', N'CMP_ADVERSE_EVNT_DESC',
     N'No adverse events reported during course of illness', 3, N'PG_Pertussis_Investigation', N'INV873',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CMP_ADVERSE_EVNT_DESC', NULL, 1, NULL,
     N'TEXT', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22006254, 1, 22006074, N'D_INVESTIGATION_REPEAT', N'EPI_SOURCE_VACC_DOSE_NBR',
     N'3', 3, N'PG_Pertussis_Investigation', N'INV874',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EPI_SOURCE_VACC_DOSE_NBR', NULL, 1, NULL,
     N'TEXT', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL');

-- The orchestrator's Step 8.5 (added in commit 99ef3517) runs
-- sp_sld_investigation_repeat_postprocessing against $PHC_UIDS,
-- which picks up these answers along with d_investigation_repeat.sql's
-- 24 original answers in one pass.  No tail-EXEC here.
