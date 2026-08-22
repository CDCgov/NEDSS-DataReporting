-- Regression test for APP-1009: sp_d_lab_test_postprocessing's "DELETING inactive
-- entries from LAB_TEST" step (routine 018) hard-DELETEd a LAB_TEST row (and its
-- nrt_lab_test_key row) once it computed RECORD_STATUS_CD='INACTIVE', instead of
-- persisting it as INACTIVE like legacy MasterEtl (RDB.dbo.LAB_TEST) does. Confirmed
-- live via job_flow_log: a created-then-deleted lab report's Order row vanished from
-- RDB_MODERN.LAB_TEST entirely, and its children (whose own status never changed)
-- stayed ACTIVE forever, because the cascade step meant to propagate the Order's new
-- INACTIVE status down to them ("Update Inactive LAB_TEST Records") read
-- dbo.LAB_TEST's stale, not-yet-updated value and ran with zero rows affected.
--
-- Sets up an Order + Order_rslt + Result already present in LAB_TEST/nrt_lab_test_key
-- as ACTIVE (simulating a prior successful sync), then reprocesses just the Order's
-- observation_uid after its nrt_observation.record_status_cd flips to LOG_DEL --
-- mirroring the real single-observation delete event. Post-fix: all three rows persist
-- in LAB_TEST (not deleted), all with RECORD_STATUS_CD='INACTIVE'.
--
-- The SP commits internally, so seeded rows survive the harness rollback -- this band
-- (1009100xxx) is reset idempotently at the top so reruns don't collide.
USE RDB_MODERN;

DELETE FROM dbo.LAB_TEST WHERE LAB_TEST_UID IN (1009100001, 1009100002, 1009100003);
DELETE FROM dbo.nrt_lab_test_key WHERE LAB_TEST_UID IN (1009100001, 1009100002, 1009100003);
DELETE FROM dbo.nrt_observation WHERE observation_uid IN (1009100001, 1009100002, 1009100003);

-- Order: the only observation reprocessed this batch, now LOG_DEL.
INSERT INTO dbo.nrt_observation
    (observation_uid, obs_domain_cd_st_1, ctrl_cd_display_form, record_status_cd,
     version_ctrl_nbr, report_observation_uid, report_refr_uid, report_sprt_uid, cd, status_cd)
VALUES
    (1009100001, 'Order', 'LabReport', 'LOG_DEL', 1, 1009100001, NULL, NULL, 'LABX', 'A');

-- Simulate a prior successful sync: Order, Order_rslt, and Result already keyed and
-- present in LAB_TEST as ACTIVE, all rooted at the Order.
INSERT INTO dbo.nrt_lab_test_key (LAB_TEST_UID) VALUES (1009100001), (1009100002), (1009100003);

INSERT INTO dbo.LAB_TEST (LAB_TEST_KEY, LAB_TEST_UID, LAB_TEST_TYPE, LAB_TEST_PNTR, ROOT_ORDERED_TEST_PNTR, PARENT_TEST_PNTR, RECORD_STATUS_CD)
SELECT
    k.LAB_TEST_KEY,
    k.LAB_TEST_UID,
    CASE k.LAB_TEST_UID
        WHEN 1009100001 THEN 'Order'
        WHEN 1009100002 THEN 'Order_rslt'
        ELSE 'Result'
    END,
    k.LAB_TEST_UID,
    1009100001,
    1009100001,
    'ACTIVE'
FROM dbo.nrt_lab_test_key k
WHERE k.LAB_TEST_UID IN (1009100001, 1009100002, 1009100003);

EXEC dbo.sp_d_lab_test_postprocessing @obs_ids = N'1009100001', @debug = 0;
