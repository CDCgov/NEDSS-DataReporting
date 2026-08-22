-- GREEN when the Result's own LOG_DEL status makes its LAB_TEST row INACTIVE, while
-- the still-ACTIVE parent Order's row is unaffected.
SELECT
    LAB_TEST_UID,
    RECORD_STATUS_CD
FROM RDB_MODERN.dbo.LAB_TEST
WHERE LAB_TEST_UID IN (1009200001, 1009200002)
ORDER BY LAB_TEST_UID;
