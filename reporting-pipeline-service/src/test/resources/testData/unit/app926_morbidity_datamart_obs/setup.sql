-- APP-926: sp_morbidity_report_datamart_postprocessing — @obs_uids branch.
-- A report qualifies for the datamart when CAST(MR.MORB_RPT_UID AS bigint) is in
-- @obs_uids AND MORB_RPT_KEY <> 1 AND MR.RECORD_STATUS_CD = 'ACTIVE'.
-- Key range 9261xxx is dedicated to this case so it can't collide with other cases
-- or the sentinel key=1 dimension rows.
--   9261001  ACTIVE  + in @obs_uids  -> qualifies (the one expected row)
--   9261002  ACTIVE  + NOT in @obs   -> excluded (param filter)
--   9261003  INACTIVE+ in @obs_uids  -> excluded (RECORD_STATUS_CD filter)
-- All MRE FK keys point to sentinel 1 (NULL dimension members) so only the obs
-- branch can match; EVENT_METRIC.EVENT_UID = MORB_RPT_UID feeds PROGRAM_AREA.
USE RDB_MODERN;

INSERT INTO dbo.MORBIDITY_REPORT
    (MORB_RPT_KEY, MORB_RPT_UID, MORB_RPT_LOCAL_ID, JURISDICTION_NM, ELECTRONIC_IND, RECORD_STATUS_CD)
VALUES
    (9261001, 9261001, 'MOR9261001', 'Obs County', 'E',  'ACTIVE'),
    (9261002, 9261002, 'MOR9261002', 'Obs County', NULL, 'ACTIVE'),
    (9261003, 9261003, 'MOR9261003', 'Obs County', NULL, 'INACTIVE');

INSERT INTO dbo.MORBIDITY_REPORT_EVENT
    (MORB_RPT_KEY, PATIENT_KEY, PHYSICIAN_KEY, REPORTER_KEY, MORB_RPT_SRC_ORG_KEY, HSPTL_KEY,
     INVESTIGATION_KEY, CONDITION_KEY, NURSING_HOME_KEY, HEALTH_CARE_KEY, LDF_GROUP_KEY,
     MORB_RPT_CREATE_DT_KEY, HSPTL_DISCHARGE_DT_KEY, ILLNESS_ONSET_DT_KEY, MORB_RPT_DT_KEY, RECORD_STATUS_CD)
VALUES
    (9261001, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1, 'ACTIVE'),
    (9261002, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1, 'ACTIVE'),
    (9261003, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1, 'ACTIVE');

INSERT INTO dbo.EVENT_METRIC (EVENT_TYPE, EVENT_UID, PROG_AREA_DESC_TXT)
VALUES ('Observation', 9261001, 'Enteric');

EXEC dbo.sp_morbidity_report_datamart_postprocessing
     @obs_uids=N'9261001,9261003', @pat_uids=N'', @prov_uids=N'', @org_uids=N'', @inv_uids=N'', @debug=0;
