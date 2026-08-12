-- APP-926: all five qualifying branches supplied at once (obs + pat + prov + org + inv).
-- One report per branch, distinct keys in the 9266xxx range, so each branch of the
-- OR in the SP WHERE contributes exactly one datamart row (5 total).
USE RDB_MODERN;

INSERT INTO dbo.D_PATIENT      (PATIENT_KEY, PATIENT_UID, PATIENT_LOCAL_ID) VALUES (9266020, 9266020, 'PAT9266020');
INSERT INTO dbo.D_PROVIDER     (PROVIDER_KEY, PROVIDER_UID, PROVIDER_LAST_NAME) VALUES (9266030, 9266030, 'DocMixed');
INSERT INTO dbo.D_ORGANIZATION (ORGANIZATION_KEY, ORGANIZATION_UID, ORGANIZATION_NAME) VALUES (9266040, 9266040, 'HospMixed');
INSERT INTO dbo.INVESTIGATION  (INVESTIGATION_KEY, CASE_UID, INV_CASE_STATUS, RECORD_STATUS_CD) VALUES (9266050, 9266050, 'C', 'ACTIVE');

INSERT INTO dbo.MORBIDITY_REPORT
    (MORB_RPT_KEY, MORB_RPT_UID, MORB_RPT_LOCAL_ID, JURISDICTION_NM, ELECTRONIC_IND, RECORD_STATUS_CD)
VALUES
    (9266001, 9266001, 'MOR9266001', 'Mixed County', 'E',  'ACTIVE'),   -- obs branch
    (9266002, 9266002, 'MOR9266002', 'Mixed County', NULL, 'ACTIVE'),   -- pat branch
    (9266003, 9266003, 'MOR9266003', 'Mixed County', NULL, 'ACTIVE'),   -- prov (physician) branch
    (9266004, 9266004, 'MOR9266004', 'Mixed County', NULL, 'ACTIVE'),   -- org (hsptl) branch
    (9266005, 9266005, 'MOR9266005', 'Mixed County', NULL, 'ACTIVE');   -- inv branch

INSERT INTO dbo.MORBIDITY_REPORT_EVENT
    (MORB_RPT_KEY, PATIENT_KEY, PHYSICIAN_KEY, REPORTER_KEY, MORB_RPT_SRC_ORG_KEY, HSPTL_KEY,
     INVESTIGATION_KEY, CONDITION_KEY, NURSING_HOME_KEY, HEALTH_CARE_KEY, LDF_GROUP_KEY,
     MORB_RPT_CREATE_DT_KEY, HSPTL_DISCHARGE_DT_KEY, ILLNESS_ONSET_DT_KEY, MORB_RPT_DT_KEY, RECORD_STATUS_CD)
VALUES
    (9266001, 1,       1,       1,1,1,       1,       1,1,1,1, 1,1,1,1, 'ACTIVE'),
    (9266002, 9266020, 1,       1,1,1,       1,       1,1,1,1, 1,1,1,1, 'ACTIVE'),
    (9266003, 1,       9266030, 1,1,1,       1,       1,1,1,1, 1,1,1,1, 'ACTIVE'),
    (9266004, 1,       1,       1,1,9266040, 1,       1,1,1,1, 1,1,1,1, 'ACTIVE'),
    (9266005, 1,       1,       1,1,1,       9266050, 1,1,1,1, 1,1,1,1, 'ACTIVE');

INSERT INTO dbo.EVENT_METRIC (EVENT_TYPE, EVENT_UID, PROG_AREA_DESC_TXT)
VALUES ('Observation', 9266001, 'Enteric'),
       ('Observation', 9266002, 'Enteric'),
       ('Observation', 9266003, 'Enteric'),
       ('Observation', 9266004, 'Enteric'),
       ('Observation', 9266005, 'Enteric');

EXEC dbo.sp_morbidity_report_datamart_postprocessing
     @obs_uids=N'9266001', @pat_uids=N'9266020', @prov_uids=N'9266030', @org_uids=N'9266040', @inv_uids=N'9266050', @debug=0;
