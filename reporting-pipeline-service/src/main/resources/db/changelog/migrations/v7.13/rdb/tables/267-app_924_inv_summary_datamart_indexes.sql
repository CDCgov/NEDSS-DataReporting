-- APP-924: covering indexes for sp_inv_summary_datamart_postprocessing (#TMP_InvLab build, step 12).
-- The step filters LAB_TEST_RESULT by the set of LAB_TEST_KEY whose LAB_TEST.LAB_RPT_UID is in @obs_uids.
-- Without an index on LAB_TEST(LAB_RPT_UID) the qualifying-key subquery is evaluated as a per-row
-- correlated probe of LAB_TEST; without an index on LAB_TEST_RESULT(LAB_TEST_KEY) the outer set is a
-- full scan. These two covering indexes turn both into seeks.

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.LAB_TEST')
      AND name = N'IX_LAB_TEST_LAB_RPT_UID'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_LAB_TEST_LAB_RPT_UID
        ON dbo.LAB_TEST (LAB_RPT_UID)
        INCLUDE
        (
            LAB_TEST_KEY
        );
END;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.LAB_TEST_RESULT')
      AND name = N'IX_LAB_TEST_RESULT_LAB_TEST_KEY'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_LAB_TEST_RESULT_LAB_TEST_KEY
        ON dbo.LAB_TEST_RESULT (LAB_TEST_KEY)
        INCLUDE
        (
            INVESTIGATION_KEY
        );
END;
