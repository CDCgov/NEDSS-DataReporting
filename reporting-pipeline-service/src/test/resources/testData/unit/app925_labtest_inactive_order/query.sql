-- GREEN when the ACTIVE Result under the INACTIVE Order has been flipped to INACTIVE
-- in all three tables. Scoped to the 925101xxx band so the parameter-independent,
-- whole-table mutation step's writes to other cases' bands cannot leak into the assert.
-- Single statement (no inner semicolons) so it maps to result key "0".
SELECT SRC, RECORD_STATUS_CD FROM (
    SELECT 'LAB_TEST_RESULT'    AS SRC, RECORD_STATUS_CD FROM RDB_MODERN.dbo.LAB_TEST_RESULT   WHERE LAB_TEST_UID = 925101001
    UNION ALL
    SELECT 'LAB_RESULT_VAL'     AS SRC, RECORD_STATUS_CD FROM RDB_MODERN.dbo.LAB_RESULT_VAL    WHERE LAB_TEST_UID = 925101001
    UNION ALL
    SELECT 'LAB_RESULT_COMMENT' AS SRC, RECORD_STATUS_CD FROM RDB_MODERN.dbo.LAB_RESULT_COMMENT WHERE LAB_TEST_UID = 925101001
) x
ORDER BY SRC
