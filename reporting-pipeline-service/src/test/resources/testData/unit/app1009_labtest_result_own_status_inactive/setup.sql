-- Regression test for APP-1009: sp_d_lab_test_postprocessing's #lab_test_final built
-- LAB_TEST.RECORD_STATUS_CD purely from COALESCE(#merge_order.RECORD_STATUS_CD_MERGE,
-- #hierarchical_data.RECORD_STATUS_CD_FOR_RESULT_DRUG) (routine 018 line ~568) -- both
-- derived from the ROOT ORDER's status via root_ordered_test_pntr, never the row's own
-- normalized status. A Result whose own nrt_observation.record_status_cd is LOG_DEL,
-- while its parent Order stays ACTIVE, therefore stayed ACTIVE in LAB_TEST.
--
-- Order 1009200001 stays ACTIVE; Result 1009200002 (report_observation_uid -> Order)
-- has its own record_status_cd = LOG_DEL. Post-fix: the Result's LAB_TEST row is
-- INACTIVE while the Order's stays ACTIVE.
--
-- The SP commits internally, so seeded rows survive the harness rollback -- this band
-- (1009200xxx) is reset idempotently at the top so reruns don't collide.
USE RDB_MODERN;

DELETE FROM dbo.LAB_TEST WHERE LAB_TEST_UID IN (1009200001, 1009200002);
DELETE FROM dbo.nrt_lab_test_key WHERE LAB_TEST_UID IN (1009200001, 1009200002);
DELETE FROM dbo.nrt_observation WHERE observation_uid IN (1009200001, 1009200002);

INSERT INTO dbo.nrt_observation
    (observation_uid, obs_domain_cd_st_1, ctrl_cd_display_form, record_status_cd,
     version_ctrl_nbr, report_observation_uid, report_refr_uid, report_sprt_uid, cd, status_cd)
VALUES
    (1009200001, 'Order',  'LabReport', 'ACTIVE',  1, 1009200001, NULL, NULL, 'LABX', 'A'),
    (1009200002, 'Result', 'LabReport', 'LOG_DEL', 1, 1009200001, NULL, NULL, 'LABY', 'A');

EXEC dbo.sp_d_lab_test_postprocessing @obs_ids = N'1009200001,1009200002', @debug = 0;
