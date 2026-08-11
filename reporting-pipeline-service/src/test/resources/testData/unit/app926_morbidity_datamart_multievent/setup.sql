-- APP-926: multi-event report. One MORBIDITY_REPORT (9267001) has TWO
-- MORBIDITY_REPORT_EVENT rows. The SP builds #MORB_EVENT_INIT at MR x MRE grain and
-- applies the qualifying WHERE per (MR, MRE) row, so only the MRE row whose PATIENT_KEY
-- matches @pat_uids survives -> exactly ONE datamart row, carrying the matching
-- patient's data. This is the case a naive key-grain rewrite would break (emit both
-- rows, or the wrong MRE's data). Key range 9267xxx.
--   MRE (a) PATIENT_KEY 9267010 (D_PATIENT UID 9267010, in @pat) -> matches
--   MRE (b) PATIENT_KEY 1       (sentinel, UID NULL)             -> does not match
USE RDB_MODERN;

INSERT INTO dbo.D_PATIENT (PATIENT_KEY, PATIENT_UID, PATIENT_LOCAL_ID)
VALUES (9267010, 9267010, 'PATMULTI');

INSERT INTO dbo.MORBIDITY_REPORT
    (MORB_RPT_KEY, MORB_RPT_UID, MORB_RPT_LOCAL_ID, JURISDICTION_NM, ELECTRONIC_IND, RECORD_STATUS_CD)
VALUES
    (9267001, 9267001, 'MOR9267001', 'Multi County', NULL, 'ACTIVE');

INSERT INTO dbo.MORBIDITY_REPORT_EVENT
    (MORB_RPT_KEY, PATIENT_KEY, PHYSICIAN_KEY, REPORTER_KEY, MORB_RPT_SRC_ORG_KEY, HSPTL_KEY,
     INVESTIGATION_KEY, CONDITION_KEY, NURSING_HOME_KEY, HEALTH_CARE_KEY, LDF_GROUP_KEY,
     MORB_RPT_CREATE_DT_KEY, HSPTL_DISCHARGE_DT_KEY, ILLNESS_ONSET_DT_KEY, MORB_RPT_DT_KEY, RECORD_STATUS_CD)
VALUES
    (9267001, 9267010, 1,1,1,1, 1,1,1,1,1, 1,1,1,1, 'ACTIVE'),
    (9267001, 1,       1,1,1,1, 1,1,1,1,1, 1,1,1,1, 'ACTIVE');

INSERT INTO dbo.EVENT_METRIC (EVENT_TYPE, EVENT_UID, PROG_AREA_DESC_TXT)
VALUES ('Observation', 9267001, 'Enteric');

EXEC dbo.sp_morbidity_report_datamart_postprocessing
     @obs_uids=N'', @pat_uids=N'9267010', @prov_uids=N'', @org_uids=N'', @inv_uids=N'', @debug=0;
