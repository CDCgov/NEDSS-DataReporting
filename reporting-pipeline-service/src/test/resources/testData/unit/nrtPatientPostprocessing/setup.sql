-- ============================================================
-- sp_nrt_patient_postprocessing / sp_patient_dim_columns_update_to_datamart
-- Unit tests for sp_nrt_patient_postprocessing
--     Patient 1: RACE_CALCULATED and RACE_CALCULATED_DETAILS
--                propagate correctly to MORBIDITY_REPORT_DATAMART (bug fix)
--     Patient 2: PATIENT_PHONE_NUMBER_HOME, AGE_REPORTED, RACE_CALCULATED,
--                and RACE_CALC_DETAILS propagate correctly to VAR_DATAMART
--                (bug fix)
--     Patient 3: PATIENT_FIRST_NAME, PATIENT_BIRTH_COUNTRY, RACE_CALCULATED,
--                RACE_CALC_DETAILS, and age group columns propagate correctly
--                to TB_DATAMART and TB_HIV_DATAMART (bug fix)
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

-- Patient 3
DECLARE @patient_uid_3  BIGINT = 90300001;
DECLARE @patient_key_3  BIGINT;
DECLARE @inv_key_3      BIGINT = 90300002;
DECLARE @org_key_3      BIGINT = 90300003;
DECLARE @provider_key_3 BIGINT = 90300004;
DECLARE @tb_pam_key_3   BIGINT = 90300005;

-- ------------------------------------------------------------
-- nrt_patient_key
-- ------------------------------------------------------------
INSERT INTO dbo.nrt_patient_key (patient_uid)
VALUES (@patient_uid_1);
SET @patient_key_1 = SCOPE_IDENTITY();

INSERT INTO dbo.nrt_patient_key (patient_uid)
VALUES (@patient_uid_2);
SET @patient_key_2 = SCOPE_IDENTITY();

INSERT INTO dbo.nrt_patient_key (patient_uid)
VALUES (@patient_uid_3);
SET @patient_key_3 = SCOPE_IDENTITY();

-- ------------------------------------------------------------
-- d_patient
-- Patient 1: stale race data
-- Patient 2: stale phone, age, race data
-- Patient 3: stale birth country, first name, and race data
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

INSERT INTO dbo.D_PATIENT (
    PATIENT_KEY, PATIENT_UID, PATIENT_RECORD_STATUS,
    PATIENT_BIRTH_COUNTRY,
    PATIENT_FIRST_NAME,
    PATIENT_RACE_CALCULATED,
    PATIENT_RACE_CALC_DETAILS
)
VALUES (
           @patient_key_3, @patient_uid_3, 'ACTIVE',
           'Unknown',     -- stale — will differ from nrt_patient
           'Unknown',     -- stale — will differ from nrt_patient
           'Unknown',     -- stale — will differ from nrt_patient
           'Unknown'      -- stale — will differ from nrt_patient
       );

-- ------------------------------------------------------------
-- nrt_patient
-- Patient 1: updated race data
-- Patient 2: updated phone, age, race data
-- Patient 3: updated birth country, first name, dob, and race data
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

INSERT INTO dbo.nrt_patient (
    patient_uid, patient_mpr_uid, record_status, local_id,
    birth_country,
    first_name,
    dob,
    race_calculated,
    race_calc_details
)
VALUES (
           @patient_uid_3, @patient_uid_3, 'ACTIVE',
           'PSN' + CAST(@patient_uid_3 AS VARCHAR),
           'USA',          -- new value triggers tb_datamart_update = 1
           'Jane',         -- new value triggers tb_datamart_update = 1
           '1980-01-01',   -- combined with TB_DATAMART.DATE_REPORTED to compute age group columns
           'White',        -- new value triggers tb_datamart_update = 1
           'White'         -- new value triggers tb_datamart_update = 1
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
-- D_ORGANIZATION, D_PROVIDER, D_TB_PAM — required by F_TB_PAM
-- ------------------------------------------------------------
INSERT INTO dbo.D_ORGANIZATION (ORGANIZATION_KEY) VALUES (@org_key_3);
INSERT INTO dbo.D_PROVIDER (PROVIDER_KEY)         VALUES (@provider_key_3);
INSERT INTO dbo.D_TB_PAM (D_TB_PAM_KEY, TB_PAM_UID)
VALUES (@tb_pam_key_3, @patient_uid_3);

-- ------------------------------------------------------------
-- F_TB_PAM — links patient 3 to investigation
-- all group tables use existing key 1
-- ------------------------------------------------------------
INSERT INTO dbo.F_TB_PAM (
    PERSON_KEY, D_TB_PAM_KEY, PROVIDER_KEY,
    D_MOVE_STATE_GROUP_KEY, D_HC_PROV_TY_3_GROUP_KEY,
    D_DISEASE_SITE_GROUP_KEY, D_ADDL_RISK_GROUP_KEY,
    D_MOVE_CNTY_GROUP_KEY, D_GT_12_REAS_GROUP_KEY,
    D_MOVE_CNTRY_GROUP_KEY, D_MOVED_WHERE_GROUP_KEY,
    D_OUT_OF_CNTRY_GROUP_KEY, D_SMR_EXAM_TY_GROUP_KEY,
    ADD_DATE_KEY, LAST_CHG_DATE_KEY,
    INVESTIGATION_KEY,
    HOSPITAL_KEY, ORG_AS_REPORTER_KEY, PERSON_AS_REPORTER_KEY,
    PHYSICIAN_KEY
)
VALUES (
           @patient_key_3, @tb_pam_key_3, @provider_key_3,
           1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
           0, 0,
           @inv_key_3,
           @org_key_3, @org_key_3, @provider_key_3,
           @provider_key_3
       );

-- ------------------------------------------------------------
-- TB_DATAMART — stale patient data for patient 3;
-- DATE_REPORTED combined with nrt_patient.dob to compute age
-- group columns (CALC_REPORTED_AGE, CALC_5_YEAR_AGE_GROUP,
-- CALC_10_YEAR_AGE_GROUP)
-- ------------------------------------------------------------
INSERT INTO dbo.TB_DATAMART (
    INVESTIGATION_KEY,
    PATIENT_FIRST_NAME,
    PATIENT_BIRTH_COUNTRY,
    RACE_CALCULATED,
    RACE_CALC_DETAILS,
    DATE_REPORTED
)
VALUES (
           @inv_key_3,
           'Unknown',      -- stale — SP should replace with 'Jane'
           'Unknown',      -- stale — SP should replace with 'USA'
           'Unknown',      -- stale — SP should replace with 'White'
           'Unknown',      -- stale — SP should replace with 'White'
           '2026-01-01'    -- combined with nrt_patient.dob ('1980-01-01') to compute age groups
       );

-- ------------------------------------------------------------
-- TB_HIV_DATAMART — stale patient data for patient 3;
-- age group columns copied from TB_DATAMART after it is updated
-- ------------------------------------------------------------
INSERT INTO dbo.TB_HIV_DATAMART (
    INVESTIGATION_KEY,
    PATIENT_FIRST_NAME,
    PATIENT_BIRTH_COUNTRY,
    RACE_CALCULATED,
    RACE_CALC_DETAILS
)
VALUES (
           @inv_key_3,
           'Unknown',      -- stale — SP should replace with 'Jane'
           'Unknown',      -- stale — SP should replace with 'USA'
           'Unknown',      -- stale — SP should replace with 'White'
           'Unknown'       -- stale — SP should replace with 'White'
       );

-- ------------------------------------------------------------
-- Execute SP for all patients in one call
-- ------------------------------------------------------------
EXEC dbo.sp_nrt_patient_postprocessing
    @id_list = '90100001,90200001,90300001';