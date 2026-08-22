-- GREEN when all three rows still exist in LAB_TEST (not hard-deleted) and are all
-- INACTIVE: the Order via its own LOG_DEL status, the children via the cascade.
SELECT
    LAB_TEST_UID,
    LAB_TEST_TYPE,
    RECORD_STATUS_CD
FROM RDB_MODERN.dbo.LAB_TEST
WHERE LAB_TEST_UID IN (1009100001, 1009100002, 1009100003)
ORDER BY LAB_TEST_UID;
