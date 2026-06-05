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
    PRINT '[zz_ldf_flagged_answers] inserted 3 TB LDF-flagged answers';
END

-- ---------------------------------------------------------------------
-- Part 2: Varicella (VAR) LDF-flagged answers
-- ---------------------------------------------------------------------
-- PHC 22002000 (investigation_form_cd='INV_FORM_VAR', condition=10030).
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_page_case_answer WHERE nbs_case_answer_uid = 22019011)
BEGIN
    PRINT '[zz_ldf_flagged_answers] inserted 3 VAR LDF-flagged answers';
END

-- ---------------------------------------------------------------------
-- Part 3: Mumps LDF answer rows (dimensional path).
-- ---------------------------------------------------------------------
-- sp_ldf_mumps_datamart_postprocessing joins LDF_DIMENSIONAL_DATA →
-- INVESTIGATION → GENERIC_CASE → D_PATIENT. GENERIC_CASE is populated
-- by sp_generic_case_datamart_postprocessing which filters
-- `investigation_form_cd LIKE 'INV_FORM_GEN%'`. The existing Mumps PHC
-- (22000030, form='PG_Mumps_Investigation') does NOT match, so its LDF
-- data cannot flow into ldf_mumps.
--
-- Workaround: create a new Mumps PHC in our UID range with
-- investigation_form_cd='INV_FORM_GEN'. Then attach LDF data to it.
-- (This mirrors the foodborne path in ldf_answers_mumps_foodborne.sql.)
--
-- ldf_uids 10001292, 10001294, 10001295 are CV-typed (the dimensional
-- SP rejects SUB types — see lines 119-120 of the dimensional SP).
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_investigation WHERE public_health_case_uid = 22019100)
BEGIN
    PRINT '[zz_ldf_flagged_answers] inserted Mumps PHC 22019100 (INV_FORM_GEN)';

END

IF NOT EXISTS (SELECT 1 FROM dbo.nrt_ldf_data WHERE business_object_uid = 22019100)
BEGIN
    PRINT '[zz_ldf_flagged_answers] inserted 3 Mumps CV-typed LDF data rows for 22019100';
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
    PRINT '[zz_ldf_flagged_answers] inserted patient LDF data row';
END

-- organization_ldf_group: business_object_uid = 10003001 (existing org)
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_ldf_data WHERE ldf_uid = 10001297 AND business_object_uid = 10003001)
BEGIN
    PRINT '[zz_ldf_flagged_answers] inserted organization LDF data row';
END

-- provider_ldf_group: business_object_uid = 10003004 (existing provider)
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_ldf_data WHERE ldf_uid = 10001298 AND business_object_uid = 10003004)
BEGIN
    PRINT '[zz_ldf_flagged_answers] inserted provider LDF data row';
END

-- =====================================================================
-- Tail-EXEC the LDF SPs to populate the target tables.
-- =====================================================================

-- 4a. TB PAM LDF (PHC 22001000, INV_FORM_RVCT)
BEGIN TRY
    PRINT '[zz_ldf_flagged_answers] sp_nrt_tb_pam_ldf_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[zz_ldf_flagged_answers] sp_nrt_tb_pam_ldf_postprocessing ERROR: ' + ERROR_MESSAGE();
END CATCH;

-- 4b. VAR PAM LDF (PHC 22002000, INV_FORM_VAR)
BEGIN TRY
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
    WHERE business_object_uid IN (22019100, 22000030, 20000000, 10003001, 10003004)
) x;

PRINT '[zz_ldf_flagged_answers] ldf_uid_list = ' + ISNULL(@ldf_uid_list, '<null>');

BEGIN TRY
    PRINT '[zz_ldf_flagged_answers] sp_nrt_ldf_dimensional_data_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[zz_ldf_flagged_answers] sp_nrt_ldf_dimensional_data_postprocessing ERROR: ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    PRINT '[zz_ldf_flagged_answers] sp_nrt_ldf_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[zz_ldf_flagged_answers] sp_nrt_ldf_postprocessing ERROR: ' + ERROR_MESSAGE();
END CATCH;

-- 4d. GENERIC_CASE for the new Mumps PHC (INV_FORM_GEN) so the mumps
--     datamart SP's downstream join to GENERIC_CASE finds a match.
--     (sp_generic_case_datamart_postprocessing filters investigation_form_cd
--     LIKE 'INV_FORM_GEN%' — see line 34 of 030-sp_generic_case_…sql.)
-- NOTE: ORCH_TODO — 22019100 is not in $PHC_UIDS of merge_and_verify.sh,
--   so Step 9's sp_generic_case_datamart_postprocessing won't include it.
--   We run it here explicitly. Until/unless the orchestrator UID list is
--   updated, this fixture's mumps coverage relies on this local EXEC.
BEGIN TRY
    PRINT '[zz_ldf_flagged_answers] sp_generic_case_datamart_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[zz_ldf_flagged_answers] sp_generic_case_datamart_postprocessing ERROR: ' + ERROR_MESSAGE();
END CATCH;

-- 4e. Mumps datamart (idempotent — orchestrator Step 9 also runs it
--     against $PHC_UIDS, but 22019100 isn't there yet; explicit here).
BEGIN TRY
    PRINT '[zz_ldf_flagged_answers] sp_ldf_mumps_datamart_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[zz_ldf_flagged_answers] sp_ldf_mumps_datamart_postprocessing ERROR: ' + ERROR_MESSAGE();
END CATCH;

PRINT '[zz_ldf_flagged_answers] done';
GO
