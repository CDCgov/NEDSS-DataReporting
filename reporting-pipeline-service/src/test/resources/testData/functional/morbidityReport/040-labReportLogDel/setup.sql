USE [NBS_ODSE];

-- APP-1009 regression: this is the exact real-world flow that was broken -- marking
-- the Order observation LOG_DEL (as happens when a user deletes a lab report) must
-- flip the Order's own LAB_TEST row to INACTIVE AND cascade to its already-existing
-- Order_rslt/Result rows, all the way through the real CDC pipeline (Debezium ->
-- observation service -> nrt_observation -> sp_d_lab_test_postprocessing) -- not just
-- via a direct stored procedure call. Pre-fix, the Order's LAB_TEST row was hard
-- deleted instead of persisted as INACTIVE, and the children were never touched.
UPDATE [dbo].[Observation]
SET
    [last_chg_time] = N'2026-08-22T00:05:00',
    [record_status_cd] = N'LOG_DEL',
    [record_status_time] = N'2026-08-22T00:05:00',
    [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1
WHERE [observation_uid] = 1000005101;
