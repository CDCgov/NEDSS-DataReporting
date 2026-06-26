-- The lab test row must land in LAB_TEST with a valid RECORD_STATUS_CD.
-- Pre-fix the SP throws 547 on the INSERT (fail-fast) so no row exists and
-- this query returns nothing (the harness's Await times out -> RED).
-- Post-fix the fallback status is normalized to 'ACTIVE' and the row inserts.
SELECT
    lt.LAB_TEST_UID,
    lt.RECORD_STATUS_CD
FROM RDB_MODERN.dbo.LAB_TEST lt
WHERE lt.LAB_TEST_UID = 22053701
  AND lt.RECORD_STATUS_CD IN ('ACTIVE', 'INACTIVE');
