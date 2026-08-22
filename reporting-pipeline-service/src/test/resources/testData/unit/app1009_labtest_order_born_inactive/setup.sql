-- Regression test for APP-1009: sp_d_lab_test_postprocessing's #lab_test_N (new/
-- never-keyed LAB_TEST rows) excluded any row whose computed RECORD_STATUS_CD was
-- INACTIVE (routine 018 line ~671, `WHERE ltf.RECORD_STATUS_CD <> 'INACTIVE'`). A lab
-- report created and deleted before it was ever synced while ACTIVE computes INACTIVE
-- on its very first processing -- so it never got a key or a row in LAB_TEST at all,
-- unlike legacy MasterEtl (Lab_Test.sas), whose %dbload/PROC APPEND always inserts new
-- rows regardless of status.
--
-- Order 1009300001 has no pre-existing key, and its nrt_observation.record_status_cd
-- is already LOG_DEL on this, its first-ever processing. Post-fix: a LAB_TEST row is
-- inserted with RECORD_STATUS_CD='INACTIVE' (pre-fix: no row at all).
--
-- The SP commits internally, so seeded rows survive the harness rollback -- this band
-- (1009300xxx) is reset idempotently at the top so reruns don't collide.
USE RDB_MODERN;

DELETE FROM dbo.LAB_TEST WHERE LAB_TEST_UID = 1009300001;
DELETE FROM dbo.nrt_lab_test_key WHERE LAB_TEST_UID = 1009300001;
DELETE FROM dbo.nrt_observation WHERE observation_uid = 1009300001;

INSERT INTO dbo.nrt_observation
    (observation_uid, obs_domain_cd_st_1, ctrl_cd_display_form, record_status_cd,
     version_ctrl_nbr, report_observation_uid, report_refr_uid, report_sprt_uid, cd, status_cd)
VALUES
    (1009300001, 'Order', 'LabReport', 'LOG_DEL', 1, 1009300001, NULL, NULL, 'LABX', 'A');

EXEC dbo.sp_d_lab_test_postprocessing @obs_ids = N'1009300001', @debug = 0;
