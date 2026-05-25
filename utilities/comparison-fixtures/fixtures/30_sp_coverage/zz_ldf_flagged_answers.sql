-- =====================================================================
-- Tier 3 — LDF-flagged answers + LDF group data
-- =====================================================================
-- Goal: unblock the *_pam_ldf + ldf_mumps + *_ldf_group cluster of
-- currently-empty datamarts by:
--
--   1. Adding LDF-flagged nrt_page_case_answer rows for TB (RVCT) and
--      Varicella (VAR) — feeds tb_pam_ldf / var_pam_ldf via the
--      sp_nrt_tb_pam_ldf_postprocessing / sp_nrt_var_pam_ldf_postprocessing
--      SPs (which filter ldf_status_cd IN ('LDF_UPDATE','LDF_CREATE',
--      'LDF_PROCESSED') AND nuim_record_status_cd IN ('Active','Inactive')).
--      Every existing answer fixture sets ldf_status_cd=NULL so these
--      tables are 0/3 before this fixture.
--
--   2. Adding additional Mumps nrt_ldf_data rows (CV/ST data_type only —
--      the dimensional SP rejects SUB) so LDF_DIMENSIONAL_DATA gets a
--      Mumps row, unblocking ldf_mumps (0/7 before).
--
--   3. Adding nrt_ldf_data rows whose business_object_uid is a
--      patient_uid / organization_uid / provider_uid in d_patient /
--      d_organization / d_provider — so sp_nrt_ldf_postprocessing
--      populates patient_ldf_group / organization_ldf_group /
--      provider_ldf_group (all 0/3 before).
--
-- SKIPPED tables (lacking baseline metadata, cannot populate):
--   - ldf_bmird     (no condition_cd=11717 in nrt_odse_state_defined_field_metadata)
--   - ldf_hepatitis (no condition_cd=10110 in nrt_odse_state_defined_field_metadata)
--   These require seeding ldf metadata first — out of scope for fixtures.
--
-- UID range: 22019000 - 22019999 (Agent M, slot reserved in uid_ranges.md).
-- Note: the orchestrator does NOT call sp_nrt_tb_pam_ldf_postprocessing
--       or sp_nrt_var_pam_ldf_postprocessing — this fixture must tail-EXEC.
-- =====================================================================

USE [RDB_MODERN];
GO

PRINT '[zz_ldf_flagged_answers] start';

-- ---------------------------------------------------------------------
-- Part 1: TB (RVCT) LDF-flagged answers
-- ---------------------------------------------------------------------
-- PHC 22001000 (investigation_form_cd='INV_FORM_RVCT', condition=10220).
-- DATAMART_COLUMN_NM values are custom LDF columns NOT already present
-- in dbo.TB_PAM_LDF (validated: TB_PAM_LDF currently has only
-- INVESTIGATION_KEY/TB_PAM_UID/add_time). The SP ALTER TABLEs the
-- target table to add missing cols at runtime, so any unique names work.
-- ---------------------------------------------------------------------
-- Note: refresh_datetime + max_datetime are GENERATED ALWAYS (system
-- versioning period cols); they cannot appear in an explicit INSERT.
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_page_case_answer WHERE nbs_case_answer_uid = 22019001)
BEGIN
    INSERT INTO dbo.nrt_page_case_answer
        (act_uid, nbs_case_answer_uid, nbs_ui_metadata_uid, nbs_rdb_metadata_uid,
         nbs_question_uid, rdb_table_nm, rdb_column_nm, answer_txt,
         investigation_form_cd, question_identifier, data_location, question_label,
         data_type, code_set_group_id, last_chg_time, record_status_cd,
         part_type_cd, batch_id,
         datamart_column_nm, ldf_status_cd, nca_add_time, nuim_record_status_cd)
    VALUES
    -- TB row 1: LDF custom column "TB_LDF_RISK_OCC" — text answer
    (22001000, 22019001, 22019001, 22019001,
     22019001, 'TB_PAM_LDF', 'TB_LDF_RISK_OCC', 'Healthcare Worker',
     'INV_FORM_RVCT', 'TB_LDF_RISK_OCC', 'NBS_LDF.TB_RISK_OCC', 'Occupational risk (LDF)',
     'TEXT', NULL, '2026-04-01T00:00:00', 'ACTIVE',
     'LDF', 1,
     'TB_LDF_RISK_OCC', 'LDF_PROCESSED', '2026-04-01T00:00:00', 'Active'),

    -- TB row 2: LDF custom column "TB_LDF_TRAVEL_CTRY" — text answer
    (22001000, 22019002, 22019002, 22019002,
     22019002, 'TB_PAM_LDF', 'TB_LDF_TRAVEL_CTRY', 'Mexico',
     'INV_FORM_RVCT', 'TB_LDF_TRAVEL_CTRY', 'NBS_LDF.TB_TRAVEL_CTRY', 'Travel country (LDF)',
     'TEXT', NULL, '2026-04-01T00:00:00', 'ACTIVE',
     'LDF', 1,
     'TB_LDF_TRAVEL_CTRY', 'LDF_PROCESSED', '2026-04-01T00:00:00', 'Active'),

    -- TB row 3: LDF custom column "TB_LDF_CONTACT_TYPE"
    (22001000, 22019003, 22019003, 22019003,
     22019003, 'TB_PAM_LDF', 'TB_LDF_CONTACT_TYPE', 'Household',
     'INV_FORM_RVCT', 'TB_LDF_CONTACT_TYPE', 'NBS_LDF.TB_CONTACT_TYPE', 'Contact type (LDF)',
     'TEXT', NULL, '2026-04-01T00:00:00', 'ACTIVE',
     'LDF', 1,
     'TB_LDF_CONTACT_TYPE', 'LDF_PROCESSED', '2026-04-01T00:00:00', 'Active');
    PRINT '[zz_ldf_flagged_answers] inserted 3 TB LDF-flagged answers';
END

-- ---------------------------------------------------------------------
-- Part 2: Varicella (VAR) LDF-flagged answers
-- ---------------------------------------------------------------------
-- PHC 22002000 (investigation_form_cd='INV_FORM_VAR', condition=10030).
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_page_case_answer WHERE nbs_case_answer_uid = 22019011)
BEGIN
    INSERT INTO dbo.nrt_page_case_answer
        (act_uid, nbs_case_answer_uid, nbs_ui_metadata_uid, nbs_rdb_metadata_uid,
         nbs_question_uid, rdb_table_nm, rdb_column_nm, answer_txt,
         investigation_form_cd, question_identifier, data_location, question_label,
         data_type, code_set_group_id, last_chg_time, record_status_cd,
         part_type_cd, batch_id,
         datamart_column_nm, ldf_status_cd, nca_add_time, nuim_record_status_cd)
    VALUES
    (22002000, 22019011, 22019011, 22019011,
     22019011, 'VAR_PAM_LDF', 'VAR_LDF_OUTBREAK_ID', 'OB-2026-001',
     'INV_FORM_VAR', 'VAR_LDF_OUTBREAK_ID', 'NBS_LDF.VAR_OB_ID', 'Outbreak ID (LDF)',
     'TEXT', NULL, '2026-04-01T00:00:00', 'ACTIVE',
     'LDF', 1,
     'VAR_LDF_OUTBREAK_ID', 'LDF_PROCESSED', '2026-04-01T00:00:00', 'Active'),

    (22002000, 22019012, 22019012, 22019012,
     22019012, 'VAR_PAM_LDF', 'VAR_LDF_SCHOOL_NM', 'Lincoln Elementary',
     'INV_FORM_VAR', 'VAR_LDF_SCHOOL_NM', 'NBS_LDF.VAR_SCHOOL', 'School name (LDF)',
     'TEXT', NULL, '2026-04-01T00:00:00', 'ACTIVE',
     'LDF', 1,
     'VAR_LDF_SCHOOL_NM', 'LDF_PROCESSED', '2026-04-01T00:00:00', 'Active'),

    (22002000, 22019013, 22019013, 22019013,
     22019013, 'VAR_PAM_LDF', 'VAR_LDF_GRADE', '3rd grade',
     'INV_FORM_VAR', 'VAR_LDF_GRADE', 'NBS_LDF.VAR_GRADE', 'Grade level (LDF)',
     'TEXT', NULL, '2026-04-01T00:00:00', 'ACTIVE',
     'LDF', 1,
     'VAR_LDF_GRADE', 'LDF_PROCESSED', '2026-04-01T00:00:00', 'Active');
    PRINT '[zz_ldf_flagged_answers] inserted 3 VAR LDF-flagged answers';
END

-- ---------------------------------------------------------------------
-- Part 3: Mumps LDF answer rows (dimensional path).
-- ---------------------------------------------------------------------
-- The mumps_foodborne fixture already inserted 5 nrt_ldf_data rows for
-- PHC 22000030, but 2 of those (ldf_uids 10001291, 10001293) have
-- data_type='SUB' which the dimensional SP rejects. The remaining 3
-- (CV-typed) SHOULD have populated LDF_DIMENSIONAL_DATA when the
-- dimensional SP ran, but the SP isn't called by the orchestrator —
-- so LDF_DIMENSIONAL_DATA is empty for mumps. We add 3 more CV/ST
-- mumps rows here and tail-EXEC the dimensional + datamart SPs.
-- (Using ldf_uids known to be CV-typed: 10001316, 10001321, 10001322.)
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_ldf_data WHERE ldf_uid = 10001316 AND business_object_uid = 22000030)
BEGIN
    INSERT INTO dbo.nrt_ldf_data
        (ldf_uid, business_object_uid, ldf_field_data_business_object_nm,
         active_ind, ldf_meta_data_business_object_nm,
         condition_cd, label_txt, data_type, code_set_nm,
         ldf_value, ldf_column_type, record_status_cd,
         ldf_data_field_add_time, ldf_data_last_chg_time,
         metadata_record_status_cd, metadata_record_status_time,
         ldf_meta_data_add_time)
    SELECT
        md.ldf_uid,
        22000030 AS business_object_uid,
        'PHC' AS ldf_field_data_business_object_nm,
        'Y' AS active_ind,
        md.business_object_nm,
        md.condition_cd,
        md.label_txt,
        md.data_type,
        md.code_set_nm,
        'Y' AS ldf_value,
        md.data_type AS ldf_column_type,
        'ACTIVE' AS record_status_cd,
        '2026-04-01T00:00:00',
        '2026-04-01T00:00:00',
        'ACTIVE',
        '2026-04-01T00:00:00',
        '2026-04-01T00:00:00'
    FROM dbo.nrt_odse_state_defined_field_metadata md
    WHERE md.ldf_uid IN (10001316, 10001321, 10001322)
      AND md.business_object_nm = 'PHC';
    PRINT '[zz_ldf_flagged_answers] inserted 3 Mumps CV-typed LDF data rows';
END

-- ---------------------------------------------------------------------
-- Part 4: LDF rows for patient/organization/provider business objects.
-- ---------------------------------------------------------------------
-- sp_nrt_ldf_postprocessing populates *_LDF_GROUP tables by joining
-- ldf_group.business_object_uid → d_patient.patient_uid /
-- d_organization.organization_uid / d_provider.provider_uid.
-- So we add nrt_ldf_data rows where business_object_uid is one of those
-- existing dimensional UIDs. Any active mumps ldf_uid works (the SP
-- only checks active_ind != 'N' on the metadata).
-- ---------------------------------------------------------------------

-- patient_ldf_group: business_object_uid = 20000000 (d_patient.patient_uid)
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_ldf_data WHERE ldf_uid = 10001296 AND business_object_uid = 20000000)
BEGIN
    INSERT INTO dbo.nrt_ldf_data
        (ldf_uid, business_object_uid, ldf_field_data_business_object_nm,
         active_ind, ldf_meta_data_business_object_nm,
         condition_cd, label_txt, data_type, code_set_nm,
         ldf_value, ldf_column_type, record_status_cd,
         ldf_data_field_add_time, ldf_data_last_chg_time,
         metadata_record_status_cd, metadata_record_status_time,
         ldf_meta_data_add_time)
    SELECT TOP 1
        md.ldf_uid,
        20000000 AS business_object_uid,   -- foundation Patient
        'PAT' AS ldf_field_data_business_object_nm,
        'Y' AS active_ind,
        md.business_object_nm,
        md.condition_cd,
        md.label_txt,
        md.data_type,
        md.code_set_nm,
        'Y' AS ldf_value,
        md.data_type AS ldf_column_type,
        'ACTIVE' AS record_status_cd,
        '2026-04-01T00:00:00',
        '2026-04-01T00:00:00',
        'ACTIVE',
        '2026-04-01T00:00:00',
        '2026-04-01T00:00:00'
    FROM dbo.nrt_odse_state_defined_field_metadata md
    WHERE md.ldf_uid = 10001296
      AND md.active_ind <> 'N';
    PRINT '[zz_ldf_flagged_answers] inserted patient LDF data row';
END

-- organization_ldf_group: business_object_uid = 10003001 (existing org)
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_ldf_data WHERE ldf_uid = 10001297 AND business_object_uid = 10003001)
BEGIN
    INSERT INTO dbo.nrt_ldf_data
        (ldf_uid, business_object_uid, ldf_field_data_business_object_nm,
         active_ind, ldf_meta_data_business_object_nm,
         condition_cd, label_txt, data_type, code_set_nm,
         ldf_value, ldf_column_type, record_status_cd,
         ldf_data_field_add_time, ldf_data_last_chg_time,
         metadata_record_status_cd, metadata_record_status_time,
         ldf_meta_data_add_time)
    SELECT TOP 1
        md.ldf_uid,
        10003001 AS business_object_uid,    -- existing organization
        'ORG' AS ldf_field_data_business_object_nm,
        'Y' AS active_ind,
        md.business_object_nm,
        md.condition_cd,
        md.label_txt,
        md.data_type,
        md.code_set_nm,
        'Y' AS ldf_value,
        md.data_type AS ldf_column_type,
        'ACTIVE' AS record_status_cd,
        '2026-04-01T00:00:00',
        '2026-04-01T00:00:00',
        'ACTIVE',
        '2026-04-01T00:00:00',
        '2026-04-01T00:00:00'
    FROM dbo.nrt_odse_state_defined_field_metadata md
    WHERE md.ldf_uid = 10001297
      AND md.active_ind <> 'N';
    PRINT '[zz_ldf_flagged_answers] inserted organization LDF data row';
END

-- provider_ldf_group: business_object_uid = 10003004 (existing provider)
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_ldf_data WHERE ldf_uid = 10001298 AND business_object_uid = 10003004)
BEGIN
    INSERT INTO dbo.nrt_ldf_data
        (ldf_uid, business_object_uid, ldf_field_data_business_object_nm,
         active_ind, ldf_meta_data_business_object_nm,
         condition_cd, label_txt, data_type, code_set_nm,
         ldf_value, ldf_column_type, record_status_cd,
         ldf_data_field_add_time, ldf_data_last_chg_time,
         metadata_record_status_cd, metadata_record_status_time,
         ldf_meta_data_add_time)
    SELECT TOP 1
        md.ldf_uid,
        10003004 AS business_object_uid,    -- existing provider
        'PRV' AS ldf_field_data_business_object_nm,
        'Y' AS active_ind,
        md.business_object_nm,
        md.condition_cd,
        md.label_txt,
        md.data_type,
        md.code_set_nm,
        'Y' AS ldf_value,
        md.data_type AS ldf_column_type,
        'ACTIVE' AS record_status_cd,
        '2026-04-01T00:00:00',
        '2026-04-01T00:00:00',
        'ACTIVE',
        '2026-04-01T00:00:00',
        '2026-04-01T00:00:00'
    FROM dbo.nrt_odse_state_defined_field_metadata md
    WHERE md.ldf_uid = 10001298
      AND md.active_ind <> 'N';
    PRINT '[zz_ldf_flagged_answers] inserted provider LDF data row';
END

-- =====================================================================
-- Tail-EXEC the LDF SPs to populate the target tables.
-- =====================================================================

-- 4a. TB PAM LDF (PHC 22001000, INV_FORM_RVCT)
BEGIN TRY
    EXEC dbo.sp_nrt_tb_pam_ldf_postprocessing @phc_id_list = N'22001000', @debug = 0;
    PRINT '[zz_ldf_flagged_answers] sp_nrt_tb_pam_ldf_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[zz_ldf_flagged_answers] sp_nrt_tb_pam_ldf_postprocessing ERROR: ' + ERROR_MESSAGE();
END CATCH;

-- 4b. VAR PAM LDF (PHC 22002000, INV_FORM_VAR)
BEGIN TRY
    EXEC dbo.sp_nrt_var_pam_ldf_postprocessing @phc_uids = N'22002000', @debug = 0;
    PRINT '[zz_ldf_flagged_answers] sp_nrt_var_pam_ldf_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[zz_ldf_flagged_answers] sp_nrt_var_pam_ldf_postprocessing ERROR: ' + ERROR_MESSAGE();
END CATCH;

-- 4c. Run LDF dimensional + group postprocessing for ALL new ldf_uids.
-- This populates LDF_DIMENSIONAL_DATA (for mumps datamart) and the
-- *_LDF_GROUP tables (via the d_patient/d_organization/d_provider joins).
DECLARE @ldf_uid_list nvarchar(max);
SELECT @ldf_uid_list = STRING_AGG(CAST(ldf_uid AS varchar(20)), ',')
FROM (
    SELECT DISTINCT ldf_uid
    FROM dbo.nrt_ldf_data
    WHERE business_object_uid IN (22000030, 20000000, 10003001, 10003004)
) x;

PRINT '[zz_ldf_flagged_answers] ldf_uid_list = ' + ISNULL(@ldf_uid_list, '<null>');

BEGIN TRY
    EXEC dbo.sp_nrt_ldf_dimensional_data_postprocessing @ldf_id_list = @ldf_uid_list, @debug = 0;
    PRINT '[zz_ldf_flagged_answers] sp_nrt_ldf_dimensional_data_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[zz_ldf_flagged_answers] sp_nrt_ldf_dimensional_data_postprocessing ERROR: ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    EXEC dbo.sp_nrt_ldf_postprocessing @ldf_uid_list = @ldf_uid_list, @debug = 0;
    PRINT '[zz_ldf_flagged_answers] sp_nrt_ldf_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[zz_ldf_flagged_answers] sp_nrt_ldf_postprocessing ERROR: ' + ERROR_MESSAGE();
END CATCH;

-- 4d. Mumps datamart (idempotent — orchestrator Step 9 also runs it,
--     but doing it here surfaces issues immediately during testing).
BEGIN TRY
    EXEC dbo.sp_ldf_mumps_datamart_postprocessing @phc_uids = N'22000030', @debug = 0;
    PRINT '[zz_ldf_flagged_answers] sp_ldf_mumps_datamart_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[zz_ldf_flagged_answers] sp_ldf_mumps_datamart_postprocessing ERROR: ' + ERROR_MESSAGE();
END CATCH;

PRINT '[zz_ldf_flagged_answers] done';
GO
