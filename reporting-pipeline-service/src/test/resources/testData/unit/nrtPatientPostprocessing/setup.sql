-- ============================================================
-- sp_nrt_patient_postprocessing / sp_patient_dim_columns_update_to_datamart
-- Unit tests for sp_nrt_patient_postprocessing
--     Patient 1: RACE_CALCULATED and RACE_CALCULATED_DETAILS
--                propagate correctly to MORBIDITY_REPORT_DATAMART (bug fix)
-- ============================================================

USE [RDB_Modern];

-- ------------------------------------------------------------
-- UIDs / keys
-- ------------------------------------------------------------
DECLARE @patient_uid  BIGINT = 90100001;
DECLARE @patient_key  BIGINT;            -- assigned from SCOPE_IDENTITY() below
DECLARE @morb_rpt_key BIGINT = 90100002;
DECLARE @inv_key      BIGINT = 90100003;

-- ------------------------------------------------------------
-- nrt_patient_key
-- ------------------------------------------------------------
INSERT INTO dbo.nrt_patient_key (patient_uid)
VALUES (@patient_uid);

SET @patient_key = SCOPE_IDENTITY();

-- ------------------------------------------------------------
-- d_patient — stale race data
-- ------------------------------------------------------------
INSERT INTO dbo.D_PATIENT (
    PATIENT_KEY,
    PATIENT_UID,
    PATIENT_RECORD_STATUS,
    PATIENT_RACE_CALCULATED,
    PATIENT_RACE_CALC_DETAILS
)
VALUES (
           @patient_key,
           @patient_uid,
           'ACTIVE',
           'Unknown',        -- stale value
           'Unknown'         -- stale value
       );

-- ------------------------------------------------------------
-- nrt_patient — updated race data, triggers
-- morbidity_report_datamart_update = 1
-- ------------------------------------------------------------
INSERT INTO dbo.nrt_patient (
    patient_uid,
    patient_mpr_uid,
    record_status,
    local_id,
    race_calculated,
    race_calc_details
)
VALUES (
           @patient_uid,
           @patient_uid,
           'ACTIVE',
           'PSN' + CAST(@patient_uid AS VARCHAR),
           'Multi-Race',     -- new value
           'Asian | White'   -- new value
       );

-- ------------------------------------------------------------
-- MORBIDITY_REPORT_EVENT
-- ------------------------------------------------------------
INSERT INTO dbo.MORBIDITY_REPORT_EVENT (
    NURSING_HOME_KEY, HEALTH_CARE_KEY, MORB_RPT_CREATE_DT_KEY,
    HSPTL_DISCHARGE_DT_KEY, ILLNESS_ONSET_DT_KEY, MORB_RPT_SRC_ORG_KEY,
    PATIENT_KEY,
    MORB_RPT_KEY,
    MORB_RPT_DT_KEY, PHYSICIAN_KEY, REPORTER_KEY, HSPTL_KEY,
    INVESTIGATION_KEY,
    CONDITION_KEY, LDF_GROUP_KEY,
    RECORD_STATUS_CD
)
VALUES (
           0, 0, 0,
           0, 0, 0,
           @patient_key,
           @morb_rpt_key,   -- joined to MORBIDITY_REPORT_DATAMART.MORBIDITY_REPORT_KEY
           0, 0, 0, 0,
           @inv_key,
           0, 0,
           'ACTIVE'
       );

-- ------------------------------------------------------------
-- MORBIDITY_REPORT_DATAMART — stale race data to be overwritten
-- ------------------------------------------------------------
INSERT INTO dbo.MORBIDITY_REPORT_DATAMART (
    MORBIDITY_REPORT_KEY,
    RACE_CALCULATED,
    RACE_CALCULATED_DETAILS
)
VALUES (
           @morb_rpt_key,
           'Unknown',        -- stale — SP should replace with 'White'
           'Unknown'        -- stale — SP should replace with 'White~'
       );

-- ------------------------------------------------------------
-- Execute SP — writes to MORBIDITY_REPORT_DATAMART by way of
-- sp_patient_dim_columns_update_to_datamart
-- ------------------------------------------------------------
EXEC dbo.sp_nrt_patient_postprocessing @id_list = '90100001';