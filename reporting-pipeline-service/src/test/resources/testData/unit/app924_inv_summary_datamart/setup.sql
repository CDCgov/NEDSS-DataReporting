-- APP-924 regression test for sp_inv_summary_datamart_postprocessing.
-- Seeds one investigation (case_uid 9924001) with a confirmation method, a condition,
-- and a lab-result -> lab100 chain so the #TMP_InvLab lab path (the optimized step 12/13)
-- executes, then EXECs the SP. Uses a distinct 9924xxx key band because this SP commits
-- internally (per-step COMMIT/BEGIN), which defeats the harness rollback isolation.

USE RDB_MODERN;

SET NOCOUNT ON;

-- dimension sentinels the CASE_COUNT foreign keys require (key = 1)
IF NOT EXISTS (SELECT 1 FROM dbo.D_PROVIDER     WHERE PROVIDER_KEY = 1)     INSERT INTO dbo.D_PROVIDER (PROVIDER_KEY) VALUES (1);
IF NOT EXISTS (SELECT 1 FROM dbo.D_ORGANIZATION WHERE ORGANIZATION_KEY = 1) INSERT INTO dbo.D_ORGANIZATION (ORGANIZATION_KEY) VALUES (1);
IF NOT EXISTS (SELECT 1 FROM dbo.D_PATIENT      WHERE PATIENT_KEY = 1)      INSERT INTO dbo.D_PATIENT (PATIENT_KEY) VALUES (1);
IF NOT EXISTS (SELECT 1 FROM dbo.RDB_DATE       WHERE DATE_KEY = 1)         INSERT INTO dbo.RDB_DATE (DATE_KEY) VALUES (1);

-- clean the band so a re-run against a dirtied container does not collide
DELETE FROM dbo.INV_SUMM_DATAMART        WHERE INVESTIGATION_KEY = 9924001;
DELETE FROM dbo.CASE_LAB_DATAMART        WHERE INVESTIGATION_KEY = 9924001;
DELETE FROM dbo.LAB_TEST_RESULT          WHERE LAB_TEST_KEY = 9924001;
DELETE FROM dbo.LAB_TEST                 WHERE LAB_TEST_KEY = 9924001;
DELETE FROM dbo.LAB100                   WHERE LAB_RPT_LOCAL_ID = 'LAB9924001';
DELETE FROM dbo.CASE_COUNT               WHERE INVESTIGATION_KEY = 9924001;
DELETE FROM dbo.CONFIRMATION_METHOD_GROUP WHERE INVESTIGATION_KEY = 9924001;
DELETE FROM dbo.CONFIRMATION_METHOD      WHERE CONFIRMATION_METHOD_KEY = 9924001;
DELETE FROM dbo.CONDITION                WHERE CONDITION_KEY = 9924001;
DELETE FROM dbo.INVESTIGATION            WHERE INVESTIGATION_KEY = 9924001;

INSERT INTO dbo.INVESTIGATION (INVESTIGATION_KEY, CASE_UID, CASE_TYPE, RECORD_STATUS_CD, INV_LOCAL_ID, PROGRAM_AREA_DESCRIPTION)
VALUES (9924001, 9924001, 'I', 'ACTIVE', 'CAS9924001', 'TEST_PA');

INSERT INTO dbo.CONDITION (CONDITION_KEY, CONDITION_DESC, CONDITION_CD, DISEASE_GRP_CD)
VALUES (9924001, 'Test Condition', '10999', 'TESTGRP');

INSERT INTO dbo.CASE_COUNT (INVESTIGATION_KEY, CONDITION_KEY, INVESTIGATOR_KEY, REPORTER_KEY, PHYSICIAN_KEY,
                            RPT_SRC_ORG_KEY, INV_ASSIGNED_DT_KEY, PATIENT_KEY, INV_START_DT_KEY, DIAGNOSIS_DT_KEY, INV_RPT_DT_KEY)
VALUES (9924001, 9924001, 1, 1, 1, 1, 1, 1, 1, 1, 1);

INSERT INTO dbo.CONFIRMATION_METHOD (CONFIRMATION_METHOD_KEY, CONFIRMATION_METHOD_DESC)
VALUES (9924001, 'Lab confirmed');
INSERT INTO dbo.CONFIRMATION_METHOD_GROUP (INVESTIGATION_KEY, CONFIRMATION_METHOD_KEY, CONFIRMATION_DT)
VALUES (9924001, 9924001, '2024-01-15');

-- lab-result chain: LAB_TEST (obs uid 9924777) -> LAB_TEST_RESULT (links investigation) -> LAB100 (specimen dt)
INSERT INTO dbo.LAB_TEST (LAB_TEST_KEY, LAB_RPT_UID, RECORD_STATUS_CD, LAB_RPT_LOCAL_ID)
VALUES (9924001, 9924777, 'ACTIVE', 'LAB9924001');
INSERT INTO dbo.LAB_TEST_RESULT (LAB_TEST_KEY, INVESTIGATION_KEY, RECORD_STATUS_CD,
                                 RESULT_COMMENT_GRP_KEY, TEST_RESULT_GRP_KEY, PERFORMING_LAB_KEY, PATIENT_KEY,
                                 COPY_TO_PROVIDER_KEY, LAB_TEST_TECHNICIAN_KEY, SPECIMEN_COLLECTOR_KEY, ORDERING_ORG_KEY,
                                 REPORTING_LAB_KEY, CONDITION_KEY, LAB_RPT_DT_KEY, MORB_RPT_KEY, LDF_GROUP_KEY, ORDERING_PROVIDER_KEY)
VALUES (9924001, 9924001, 'ACTIVE', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
INSERT INTO dbo.LAB100 (LAB_RPT_LOCAL_ID, SPECIMEN_COLLECTION_DT)
VALUES ('LAB9924001', '2024-01-05');

-- CASE_LAB_DATAMART carries the specimen date that the final UPDATE writes into the datamart
INSERT INTO dbo.CASE_LAB_DATAMART (INVESTIGATION_KEY, EARLIEST_SPECIMEN_COLLECT_DATE, LABORATORY_INFORMATION, EVENT_DATE, EVENT_DATE_TYPE)
VALUES (9924001, '2024-01-10', 'LabInfoXYZ', '2024-01-12', 'SPECIMEN');

-- The SP returns a result set (#INV_SUMM_RETURN) on the success path; capture it so the
-- setup batch returns only an update count (JdbcClient.update() rejects a result set).
CREATE TABLE #app924_ret (
    public_health_case_uid sql_variant,
    patient_uid            sql_variant,
    observation_uid        sql_variant,
    datamart               sql_variant,
    condition_cd           sql_variant,
    stored_procedure       sql_variant,
    investigation_form_cd  sql_variant
);
INSERT INTO #app924_ret
EXEC dbo.sp_inv_summary_datamart_postprocessing @phc_uids = '9924001', @obs_uids = '9924777', @debug = 'false';
