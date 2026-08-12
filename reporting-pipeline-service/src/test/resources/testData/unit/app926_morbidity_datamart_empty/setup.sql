-- APP-926: empty-parameter guard. Valid, ACTIVE report data is present but every UID
-- list is empty, so no branch of the qualifying WHERE can match and the datamart gains
-- no rows in this case's key range. STRING_SPLIT('', ',') yields a single '' token that
-- casts to 0, and no seeded UID is 0, so nothing qualifies. Key range 9268xxx.
-- (query.sql asserts a COUNT of 0; the framework requires a query to return a row, so a
--  zero-row datamart SELECT can't be used here.)
USE RDB_MODERN;

INSERT INTO dbo.D_PATIENT (PATIENT_KEY, PATIENT_UID, PATIENT_LOCAL_ID)
VALUES (9268010, 9268010, 'PAT9268010');

INSERT INTO dbo.MORBIDITY_REPORT
    (MORB_RPT_KEY, MORB_RPT_UID, MORB_RPT_LOCAL_ID, JURISDICTION_NM, ELECTRONIC_IND, RECORD_STATUS_CD)
VALUES
    (9268001, 9268001, 'MOR9268001', 'Empty County', NULL, 'ACTIVE');

INSERT INTO dbo.MORBIDITY_REPORT_EVENT
    (MORB_RPT_KEY, PATIENT_KEY, PHYSICIAN_KEY, REPORTER_KEY, MORB_RPT_SRC_ORG_KEY, HSPTL_KEY,
     INVESTIGATION_KEY, CONDITION_KEY, NURSING_HOME_KEY, HEALTH_CARE_KEY, LDF_GROUP_KEY,
     MORB_RPT_CREATE_DT_KEY, HSPTL_DISCHARGE_DT_KEY, ILLNESS_ONSET_DT_KEY, MORB_RPT_DT_KEY, RECORD_STATUS_CD)
VALUES
    (9268001, 9268010, 1,1,1,1, 1,1,1,1,1, 1,1,1,1, 'ACTIVE');

EXEC dbo.sp_morbidity_report_datamart_postprocessing
     @obs_uids=N'', @pat_uids=N'', @prov_uids=N'', @org_uids=N'', @inv_uids=N'', @debug=0;
