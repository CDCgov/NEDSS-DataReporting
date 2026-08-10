/* =============================================================================
   Every DML statement in sp_lab100_datamart_postprocessing matches rows on
   RESULTED_LAB_TEST_KEY. 
   ============================================================================= */
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_LAB100_RESULTED_LAB_TEST_KEY'
      AND object_id = OBJECT_ID('dbo.LAB100')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_LAB100_RESULTED_LAB_TEST_KEY
        ON dbo.LAB100 (RESULTED_LAB_TEST_KEY)
        INCLUDE (
            LAB_RPT_LOCAL_ID,
            RESULTED_LAB_TEST_CD_DESC,
            RESULTEDTEST_VAL_CD_DESC,
            NUMERIC_RESULT_WITHUNITS,
            LAB_RESULT_TXT_VAL,
            LAB_RESULT_COMMENTS,
            PATIENT_KEY,
            ELR_IND,
            SPECIMEN_COLLECTION_DT,
            LAB_RPT_RECEIVED_BY_PH_DT
        );
END
