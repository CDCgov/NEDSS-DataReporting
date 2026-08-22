-- GREEN when the never-before-synced Order's LAB_TEST row was inserted anyway
-- (pre-fix: no row at all, since #lab_test_N excluded new INACTIVE-computed rows).
SELECT
    LAB_TEST_UID,
    RECORD_STATUS_CD
FROM RDB_MODERN.dbo.LAB_TEST
WHERE LAB_TEST_UID = 1009300001;
