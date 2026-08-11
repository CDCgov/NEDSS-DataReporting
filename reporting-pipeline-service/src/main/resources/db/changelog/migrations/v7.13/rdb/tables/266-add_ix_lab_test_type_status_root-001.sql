-- APP-925: covering index on LAB_TEST(LAB_TEST_TYPE, RECORD_STATUS_CD) INCLUDE (ROOT_ORDERED_TEST_PNTR).
-- sp_d_labtest_result_postprocessing's "Update Inactive LAB_TEST_RESULT Records" step (line ~1785)
-- finds inactive orders via
--   SELECT ROOT_ORDERED_TEST_PNTR FROM LAB_TEST WHERE LAB_TEST_TYPE='Order' AND RECORD_STATUS_CD='INACTIVE'
-- which, without this index, is a full scan of LAB_TEST. This is the exec plan's own missing-index hint
-- (77% impact); it turns that scan into a seek. Idempotent.
-- NOTE: the plan's OTHER hint (LAB_TEST_RESULT(RECORD_STATUS_CD) INCLUDE (LAB_TEST_UID)) is intentionally
-- NOT created: it is maintained on the very column the downstream UPDATE flips, so it was measured
-- net-negative across the step.
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_LAB_TEST_type_status_root' AND object_id = OBJECT_ID('dbo.LAB_TEST')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_LAB_TEST_type_status_root
        ON dbo.LAB_TEST (LAB_TEST_TYPE, RECORD_STATUS_CD)
        INCLUDE (ROOT_ORDERED_TEST_PNTR);
END
