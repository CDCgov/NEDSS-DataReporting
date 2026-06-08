-- ============================================================
-- sp_nrt_patient_postprocessing / sp_patient_dim_columns_update_to_datamart
-- Unit tests for sp_nrt_patient_postprocessing
--     Patient 1: RACE_CALCULATED and RACE_CALCULATED_DETAILS
--                propagate correctly to MORBIDITY_REPORT_DATAMART (bug fix)
--     Patient 2: PATIENT_PHONE_NUMBER_HOME, AGE_REPORTED, RACE_CALCULATED,
--                and RACE_CALC_DETAILS propagate correctly to VAR_DATAMART
--                (bug fix)
-- ============================================================

USE [RDB_Modern];

-- ------------------------------------------------------------
-- UIDs / keys
-- ------------------------------------------------------------

-- Patient 1
DECLARE @patient_uid_1  BIGINT = 90100001;
DECLARE @patient_key_1  BIGINT;
DECLARE @morb_rpt_key_1 BIGINT = 90100002;
DECLARE @inv_key_1      BIGINT = 90100003;

-- Patient 2
DECLARE @patient_uid_2  BIGINT = 90200001;
DECLARE @patient_key_2  BIGINT;
DECLARE @inv_key_2      BIGINT = 90200002;
DECLARE @org_key_2      BIGINT = 90200003;
DECLARE @provider_key_2 BIGINT = 90200004;
DECLARE @var_pam_key_2  BIGINT = 90200005;

-- ------------------------------------------------------------
-- nrt_patient_key
-- ------------------------------------------------------------
INSERT INTO dbo.nrt_patient_key (patient_uid)
VALUES (@patient_uid_1);
SET @patient_key_1 = SCOPE_IDENTITY();

INSERT INTO dbo.nrt_patient_key (patient_uid)
VALUES (@patient_uid_2);
SET @patient_key_2 = SCOPE_IDENTITY();

-- ------------------------------------------------------------
-- d_patient
-- Patient 1: stale race data
-- Patient 2: stale phone, age, race data
-- ------------------------------------------------------------
INSERT INTO dbo.D_PATIENT (
    PATIENT_KEY, PATIENT_UID, PATIENT_RECORD_STATUS,
    PATIENT_RACE_CALCULATED, PATIENT_RACE_CALC_DETAILS
)
VALUES (
           @patient_key_1, @patient_uid_1, 'ACTIVE',
           'Unknown',    -- stale — will differ from nrt_patient
           'Unknown'     -- stale — will differ from nrt_patient
       );

INSERT INTO dbo.D_PATIENT (
    PATIENT_KEY, PATIENT_UID, PATIENT_RECORD_STATUS,
    PATIENT_PHONE_HOME,
    PATIENT_AGE_REPORTED,
    PATIENT_RACE_CALCULATED,
    PATIENT_RACE_CALC_DETAILS
)
VALUES (
           @patient_key_2, @patient_uid_2, 'ACTIVE',
           '0000000000',  -- stale — will differ from nrt_patient
           0,             -- stale — will differ from nrt_patient
           'Unknown',     -- stale — will differ from nrt_patient
           'Unknown'      -- stale — will differ from nrt_patient
       );

-- ------------------------------------------------------------
-- nrt_patient
-- Patient 1: updated race data
-- Patient 2: updated phone, age, race data
-- ------------------------------------------------------------
INSERT INTO dbo.nrt_patient (
    patient_uid, patient_mpr_uid, record_status, local_id,
    race_calculated, race_calc_details
)
VALUES (
           @patient_uid_1, @patient_uid_1, 'ACTIVE',
           'PSN' + CAST(@patient_uid_1 AS VARCHAR),
           'Multi-Race',   -- new value triggers morbidity_report_datamart_update = 1
           'Asian | White' -- new value triggers morbidity_report_datamart_update = 1
       );

INSERT INTO dbo.nrt_patient (
    patient_uid, patient_mpr_uid, record_status, local_id,
    phone_home,
    age_reported,
    race_calculated, race_calc_details
)
VALUES (
           @patient_uid_2, @patient_uid_2, 'ACTIVE',
           'PSN' + CAST(@patient_uid_2 AS VARCHAR),
           '4045550100',   -- new value triggers var_datamart_update = 1
           45,             -- new value triggers var_datamart_update = 1
           'White',        -- new value triggers var_datamart_update = 1
           'White'         -- new value triggers var_datamart_update = 1
       );

-- ------------------------------------------------------------
-- MORBIDITY_REPORT_EVENT — links patient 1 to morb report
-- ------------------------------------------------------------
INSERT INTO dbo.MORBIDITY_REPORT_EVENT (
    NURSING_HOME_KEY, HEALTH_CARE_KEY, MORB_RPT_CREATE_DT_KEY,
    HSPTL_DISCHARGE_DT_KEY, ILLNESS_ONSET_DT_KEY, MORB_RPT_SRC_ORG_KEY,
    PATIENT_KEY, MORB_RPT_KEY, MORB_RPT_DT_KEY,
    PHYSICIAN_KEY, REPORTER_KEY, HSPTL_KEY,
    INVESTIGATION_KEY, CONDITION_KEY, LDF_GROUP_KEY,
    RECORD_STATUS_CD
)
VALUES (
           0, 0, 0, 0, 0, 0,
           @patient_key_1,
           @morb_rpt_key_1,
           0, 0, 0, 0,
           @inv_key_1,
           0, 0,
           'ACTIVE'
       );

-- ------------------------------------------------------------
-- MORBIDITY_REPORT_DATAMART — stale race data for patient 1
-- ------------------------------------------------------------
INSERT INTO dbo.MORBIDITY_REPORT_DATAMART (
    MORBIDITY_REPORT_KEY, RACE_CALCULATED, RACE_CALCULATED_DETAILS
)
VALUES (
           @morb_rpt_key_1,
           'Unknown',      -- stale — SP should replace with 'Multi-Race'
           'Unknown'       -- stale — SP should replace with 'Asian | White'
       );

-- ------------------------------------------------------------
-- D_ORGANIZATION, D_PROVIDER, D_VAR_PAM — required by F_VAR_PAM
-- ------------------------------------------------------------
INSERT INTO dbo.D_ORGANIZATION (ORGANIZATION_KEY) VALUES (@org_key_2);
INSERT INTO dbo.D_PROVIDER (PROVIDER_KEY)         VALUES (@provider_key_2);
INSERT INTO dbo.D_VAR_PAM (D_VAR_PAM_KEY, VAR_PAM_UID)
VALUES (@var_pam_key_2, @patient_uid_2);

-- ------------------------------------------------------------
-- F_VAR_PAM — links patient 2 to investigation
-- ------------------------------------------------------------
INSERT INTO dbo.F_VAR_PAM (
    PERSON_KEY, D_VAR_PAM_KEY, PROVIDER_KEY,
    D_PCR_SOURCE_GROUP_KEY, D_RASH_LOC_GEN_GROUP_KEY,
    HOSPITAL_KEY, ORG_AS_REPORTER_KEY, PERSON_AS_REPORTER_KEY,
    PHYSICIAN_KEY, ADD_DATE_KEY, LAST_CHG_DATE_KEY,
    INVESTIGATION_KEY
)
VALUES (
           @patient_key_2, @var_pam_key_2, @provider_key_2,
           1, 1,
           @org_key_2, @org_key_2, @provider_key_2,
           @provider_key_2, 0, 0,
           @inv_key_2
       );

-- ------------------------------------------------------------
-- VAR_DATAMART — stale phone, age, race data for patient 2
-- ------------------------------------------------------------
INSERT INTO dbo.VAR_DATAMART (
    INVESTIGATION_KEY,
    PATIENT_PHONE_NUMBER_HOME,
    AGE_REPORTED,
    RACE_CALCULATED,
    RACE_CALC_DETAILS
)
VALUES (
           @inv_key_2,
           '0000000000',   -- stale — SP should replace with '4045550100'
           0,              -- stale — SP should replace with 45
           'Unknown',      -- stale — SP should replace with 'White'
           'Unknown'       -- stale — SP should replace with 'White'
       );

-- ------------------------------------------------------------
-- Execute SP for both patients in one call
-- ------------------------------------------------------------
EXEC dbo.sp_nrt_patient_postprocessing
    @id_list = '90100001,90200001';