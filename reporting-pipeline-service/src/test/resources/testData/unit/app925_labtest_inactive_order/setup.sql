-- APP-925: sp_d_labtest_result_postprocessing "Update Inactive LAB_TEST_RESULT
-- Records" step. An INACTIVE Order plus its ACTIVE Result: the SP builds
-- #Inactive_Obs = active LAB_TEST_RESULT rows whose LAB_TEST.ROOT_ORDERED_TEST_PNTR
-- resolves to an INACTIVE LAB_TEST_TYPE='Order', then flips LAB_TEST_RESULT,
-- LAB_RESULT_VAL and LAB_RESULT_COMMENT for those UIDs to INACTIVE.
--
-- That step scans ALL of LAB_TEST/LAB_TEST_RESULT (parameter-independent), and the
-- SP COMMITs internally so seeded rows persist past the harness rollback. Each case
-- therefore lives in a distinct key band (925101xxx here) and query.sql scopes to it.
--
-- Order  925101000: LAB_TEST_TYPE='Order', RECORD_STATUS_CD='INACTIVE', root -> itself.
-- Result 925101001: LAB_TEST_TYPE='Result', same root; its LAB_TEST_RESULT +
--                   LAB_RESULT_VAL + LAB_RESULT_COMMENT start ACTIVE.
-- Expected post-run: all three of the Result's rows are INACTIVE.
--
-- NOT-NULL columns seeded per sys.columns: LAB_TEST(LAB_TEST_KEY, RECORD_STATUS_CD);
-- LAB_TEST_RESULT(all *_KEY + RECORD_STATUS_CD); LAB_RESULT_VAL(TEST_RESULT_GRP_KEY,
-- TEST_RESULT_VAL_KEY, RECORD_STATUS_CD); LAB_RESULT_COMMENT(LAB_RESULT_COMMENT_KEY,
-- RESULT_COMMENT_GRP_KEY, RECORD_STATUS_CD). Grouping FK parents seeded too.
USE RDB_MODERN;

-- Idempotent reset of this band (SP commits, so rows survive prior runs). Child-first.
DELETE FROM dbo.LAB_RESULT_COMMENT   WHERE LAB_RESULT_COMMENT_KEY BETWEEN 925101000 AND 925101999;
DELETE FROM dbo.LAB_RESULT_VAL       WHERE TEST_RESULT_GRP_KEY    BETWEEN 925101000 AND 925101999;
DELETE FROM dbo.LAB_TEST_RESULT      WHERE LAB_TEST_KEY           BETWEEN 925101000 AND 925101999;
DELETE FROM dbo.RESULT_COMMENT_GROUP WHERE RESULT_COMMENT_GRP_KEY BETWEEN 925101000 AND 925101999;
DELETE FROM dbo.TEST_RESULT_GROUPING WHERE TEST_RESULT_GRP_KEY    BETWEEN 925101000 AND 925101999;
DELETE FROM dbo.LAB_TEST             WHERE LAB_TEST_KEY           BETWEEN 925101000 AND 925101999;

INSERT INTO dbo.LAB_TEST (LAB_TEST_KEY, LAB_TEST_UID, ROOT_ORDERED_TEST_PNTR, LAB_TEST_TYPE, RECORD_STATUS_CD)
VALUES (925101000, 925101000, 925101000, 'Order',  'INACTIVE'),
       (925101001, 925101001, 925101000, 'Result', 'ACTIVE');

INSERT INTO dbo.TEST_RESULT_GROUPING (TEST_RESULT_GRP_KEY) VALUES (925101001);
INSERT INTO dbo.RESULT_COMMENT_GROUP (RESULT_COMMENT_GRP_KEY) VALUES (925101001);

INSERT INTO dbo.LAB_TEST_RESULT
    (LAB_TEST_KEY, LAB_TEST_UID, RESULT_COMMENT_GRP_KEY, TEST_RESULT_GRP_KEY,
     PERFORMING_LAB_KEY, PATIENT_KEY, COPY_TO_PROVIDER_KEY, LAB_TEST_TECHNICIAN_KEY,
     SPECIMEN_COLLECTOR_KEY, ORDERING_ORG_KEY, REPORTING_LAB_KEY, CONDITION_KEY,
     LAB_RPT_DT_KEY, MORB_RPT_KEY, INVESTIGATION_KEY, LDF_GROUP_KEY,
     ORDERING_PROVIDER_KEY, RECORD_STATUS_CD)
VALUES (925101001, 925101001, 925101001, 925101001,
        1, 1, 1, 1,
        1, 1, 1, 1,
        1, 1, 1, 1,
        1, 'ACTIVE');

INSERT INTO dbo.LAB_RESULT_VAL (TEST_RESULT_GRP_KEY, TEST_RESULT_VAL_KEY, LAB_TEST_UID, RECORD_STATUS_CD)
VALUES (925101001, 925101001, 925101001, 'ACTIVE');

INSERT INTO dbo.LAB_RESULT_COMMENT (LAB_RESULT_COMMENT_KEY, RESULT_COMMENT_GRP_KEY, LAB_TEST_UID, RECORD_STATUS_CD)
VALUES (925101001, 925101001, 925101001, 'ACTIVE');

-- The "Update Inactive LAB_TEST_RESULT Records" step is parameter-independent: it scans
-- ALL of LAB_TEST/LAB_TEST_RESULT regardless of @pLabResultList. Passing a NON-EXISTENT
-- UID (925101999) leaves every upstream temp table empty, so the SP's key-allocation
-- INSERTs (into TEST_RESULT_GROUPING / nrt_*_key) touch nothing and cannot collide,
-- while the global mutation step still runs and flips this band. This isolates the
-- APP-925 change from unrelated upstream key-generation state, mirroring the datamart-SP
-- pattern (seed the dims the step reads, skip the upstream chain).
EXEC dbo.sp_d_labtest_result_postprocessing @pLabResultList = N'925101999', @pDebug = 0;
