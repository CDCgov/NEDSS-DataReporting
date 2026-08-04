/* =============================================================================
   Procedure:   dbo.sp_lab100_datamart_postprocessing
   Purpose:     Builds/refreshes the LAB100 reporting datamart for a batch of
                lab test UIDs. Joins order and result records, resolves
                patient, provider, organization, program-area, LOINC, and
                condition reference data, then upserts the resulting rows into
                dbo.LAB100 and reconciles inactive/removed source records.

   Parameters:
     @labtestuids   Comma-delimited list of dbo.LAB_TEST.lab_test_uid values
                     to process for this batch. Only rows with
                     LAB_TEST_TYPE = 'Result' (plus each row's parent Order)
                     are considered.
     @debug          1 = emit intermediate result sets for every temp table,
                     for troubleshooting.
                     0 = normal operation (default).

   Returns:     A single result row describing the outcome (empty on success;
                populated with error detail on failure). Per-step row counts
                are written to dbo.JOB_FLOW_LOG for observability.
   ============================================================================= */
IF EXISTS (
    SELECT * FROM sysobjects
    WHERE id = OBJECT_ID(N'[dbo].[sp_lab100_datamart_postprocessing]')
      AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_lab100_datamart_postprocessing]
END
GO

CREATE PROCEDURE dbo.[sp_lab100_datamart_postprocessing]
    @labtestuids            NVARCHAR(MAX),
    @debug                  BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BatchId        BIGINT        = CAST(FORMAT(GETDATE(), 'yyMMddHHmmssffff') AS BIGINT);
    DECLARE @DataflowName   VARCHAR(50)   = 'LAB100_DATAMART';
    DECLARE @RowCountNo     INT           = 0;
    DECLARE @ProcStepNo     FLOAT         = 0;
    DECLARE @ProcStepName   VARCHAR(200)  = '';

    BEGIN TRY

        -- Log the start of the batch.
        SET @ProcStepNo = 1;
        SET @ProcStepName = 'SP_Start';

        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        -- Build the base working set: every LAB_TEST row for the requested
        -- UIDs, plus, for each Result row, its parent Order row, so a
        -- result is never processed without its order context.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LABTEST_LABTESTRESULT';

        IF OBJECT_ID('tempdb..#TMP_LABTEST_LABTESTRESULT', 'U') IS NOT NULL
            DROP TABLE #TMP_LABTEST_LABTESTRESULT;

        SELECT
            lt.*,
            RESULT_COMMENT_GRP_KEY,
            TEST_RESULT_GRP_KEY,
            PERFORMING_LAB_KEY,
            PATIENT_KEY,
            COPY_TO_PROVIDER_KEY,
            LAB_TEST_TECHNICIAN_KEY,
            SPECIMEN_COLLECTOR_KEY,
            ORDERING_ORG_KEY,
            REPORTING_LAB_KEY,
            CONDITION_KEY,
            LAB_RPT_DT_KEY,
            MORB_RPT_KEY,
            INVESTIGATION_KEY,
            LDF_GROUP_KEY,
            ORDERING_PROVIDER_KEY
        INTO #TMP_LABTEST_LABTESTRESULT
        FROM dbo.LAB_TEST lt WITH (NOLOCK)
            LEFT OUTER JOIN dbo.LAB_TEST_RESULT ltr WITH (NOLOCK)
                ON lt.LAB_TEST_KEY = ltr.LAB_TEST_KEY
        WHERE lt.LAB_TEST_KEY <> 1
          AND lt.lab_test_uid IN (
                SELECT lab_test_uid AS uid
                FROM dbo.LAB_TEST WITH (NOLOCK)
                WHERE lab_test_uid IN (SELECT value FROM STRING_SPLIT(@labtestuids, ','))
                  AND LAB_TEST_TYPE = 'Result'
                UNION ALL
                SELECT ROOT_ORDERED_TEST_PNTR AS uid
                FROM dbo.LAB_TEST WITH (NOLOCK)
                WHERE lab_test_uid IN (SELECT value FROM STRING_SPLIT(@labtestuids, ','))
                  AND LAB_TEST_TYPE = 'Result'
          );

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LABTEST_LABTESTRESULT' AS step, * FROM #TMP_LABTEST_LABTESTRESULT;

        -- Split off the Order-side rows and project order-specific fields.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LABTEST_ORDER';

        IF OBJECT_ID('tempdb..#TMP_LABTEST_ORDER', 'U') IS NOT NULL
            DROP TABLE #TMP_LABTEST_ORDER;

        SELECT
            LAB_TEST_STATUS, LAB_TEST_KEY, LAB_RPT_LOCAL_ID, REASON_FOR_TEST_DESC, RECORD_STATUS_CD,
            LAB_RPT_UID AS ORDERED_RPT_UID,
            LAB_TEST_CD AS ORDERED_LAB_TEST_CD,
            LAB_TEST_CD_DESC AS ORDERED_LAB_TEST_CD_DESC,
            LAB_TEST_CD_SYS_CD AS ORDERED_TEST_CODE,
            LAB_TEST_CD_SYS_NM AS ORDERED_LABTEST_CD_SYS_NM,
            SPECIMEN_DETAILS,
            LAB_TEST_UID AS ORDERED_TEST_UID,
            SPECIMEN_ADD_TIME, SPECIMEN_LAST_CHANGE_TIME, ORDERING_ORG_KEY,
            REPORTING_LAB_KEY AS REPORTING_LAB_KEY_ORDER,
            CONDITION_KEY, INVESTIGATION_KEY, ORDERING_PROVIDER_KEY, LAB_RPT_STATUS, NULL AS OID, CONDITION_CD,
            REASON_FOR_TEST_DESC AS REASON_FOR_TEST_DESC1,
            SPECIMEN_SRC AS SPECIMEN_SRC_CD,
            SPECIMEN_DESC AS SPECIMEN_SRC_DESC,
            CASE WHEN LDF_GROUP_KEY = 1 THEN NULL ELSE LDF_GROUP_KEY END AS LDF_GROUP_KEY,
            CASE WHEN MORB_RPT_KEY = 1 THEN NULL ELSE MORB_RPT_KEY END AS MORB_RPT_KEY,
            PATIENT_KEY,
            DOCUMENT_LINK,
            ALT_LAB_TEST_CD_SYS_CD, ALT_LAB_TEST_CD_SYS_NM,
            lab_test_type
        INTO #TMP_LABTEST_ORDER
        FROM #TMP_LABTEST_LABTESTRESULT
        WHERE lab_test_type = 'Order';

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LABTEST_ORDER' AS step, * FROM #TMP_LABTEST_ORDER;

        -- Split off the Result-side rows and project result-specific fields.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LABTEST_RESULT';

        IF OBJECT_ID('tempdb..#TMP_LABTEST_RESULT', 'U') IS NOT NULL
            DROP TABLE #TMP_LABTEST_RESULT;

        SELECT
            LAB_TEST_KEY, LAB_RPT_LOCAL_ID, TEST_METHOD_CD,
            TEST_METHOD_CD_DESC,
            LAB_TEST_CD AS RESULTED_LAB_TEST_CD,
            ELR_IND,
            LAB_RPT_UID AS RESULTED_RPT_UID,
            LAB_TEST_CD_DESC AS RESULTED_TEST,
            INTERPRETATION_FLG,
            LAB_RPT_RECEIVED_BY_PH_DT,
            LAB_RPT_CREATED_DT,
            LAB_RPT_CREATED_BY,
            LAB_TEST_DT,
            LAB_RPT_LAST_UPDATE_DT,
            JURISDICTION_CD, LAB_TEST_CD_SYS_NM,
            JURISDICTION_NM,
            OID,
            ACCESSION_NBR,
            SPECIMEN_SRC, SPECIMEN_DESC, SPECIMEN_SITE,
            SPECIMEN_SITE_DESC,
            SPECIMEN_COLLECTION_DT,
            LAB_TEST_UID AS RESULTED_TEST_UID,
            ROOT_ORDERED_TEST_PNTR,
            PARENT_TEST_PNTR,
            LAB_RPT_DT_KEY,
            RESULT_COMMENT_GRP_KEY, TEST_RESULT_GRP_KEY,
            LAB_RPT_LAST_UPDATE_BY AS PERFORMING_LAB_KEY,
            LAB_RPT_LAST_UPDATE_BY,
            ALT_LAB_TEST_CD, ALT_LAB_TEST_CD_DESC,
            ALT_LAB_TEST_CD_SYS_CD, ALT_LAB_TEST_CD_SYS_NM,
            LAB_TEST_CD_DESC AS RESULTED_LAB_TEST_CD_DESC,
            LAB_TEST_CD_SYS_NM AS RESULTEDTEST_CD_SYS_NM,
            TEST_METHOD_CD AS RESULT_TEST_METHOD_CD,
            LAB_TEST_KEY AS RESULTED_LAB_TEST_KEY,
            lab_test_type
        INTO #TMP_LABTEST_RESULT
        FROM #TMP_LABTEST_LABTESTRESULT
        WHERE lab_test_type = 'Result';

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LABTEST_RESULT' AS step, * FROM #TMP_LABTEST_RESULT;

        -- Identify and exclude orders/results tied to a morbidity report
        -- that has since been marked INACTIVE.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_DELETEDMORBS';

        IF OBJECT_ID('tempdb..#TMP_DELETEDMORBS', 'U') IS NOT NULL
            DROP TABLE #TMP_DELETEDMORBS;

        SELECT
            mr.MORB_RPT_KEY, ORDERED_TEST_UID
        INTO #TMP_DELETEDMORBS
        FROM dbo.MORBIDITY_REPORT mr WITH (NOLOCK), #TMP_LABTEST_ORDER tlo
        WHERE mr.RECORD_STATUS_CD = 'INACTIVE'
          AND mr.MORB_RPT_KEY = tlo.MORB_RPT_KEY;

        DELETE FROM #TMP_LABTEST_RESULT
        WHERE ROOT_ORDERED_TEST_PNTR IN (SELECT ORDERED_TEST_UID FROM #TMP_DELETEDMORBS);

        DELETE FROM #TMP_LABTEST_ORDER
        WHERE MORB_RPT_KEY IN (SELECT MORB_RPT_KEY FROM #TMP_DELETEDMORBS);

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_DELETEDMORBS' AS step, * FROM #TMP_DELETEDMORBS;

        -- Normalize raw result values for this batch's result groups:
        -- decode escaped XML entities and build a combined display string.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LAB_RESULT_VALMODIFIED';

        IF OBJECT_ID('tempdb..#TMP_LAB_RESULT_VALMODIFIED', 'U') IS NOT NULL
            DROP TABLE #TMP_LAB_RESULT_VALMODIFIED;

        SELECT
            TEST_RESULT_GRP_KEY AS TEST_RESULT_GRP_KEY_VAL,
            REPLACE(REPLACE(LTRIM(RTRIM(TEST_RESULT_VAL_CD_DESC) + ' ' + RTRIM(LAB_RESULT_TXT_VAL) + ' ' + RTRIM(NUMERIC_RESULT) + ' ' +
                                    RTRIM(RESULT_UNITS)), CHAR(13), ','), CHAR(10), ' ') AS RESULT,
            TEST_RESULT_VAL_CD, TEST_RESULT_VAL_CD_SYS_NM,
            ALT_RESULT_VAL_CD      AS LOCAL_RESULT_CODE,
            ALT_RESULT_VAL_CD_DESC AS LOCAL_RESULT_NAME,
            REF_RANGE_FRM          AS RESULT_REF_RANGE_FRM,
            REF_RANGE_TO           AS RESULT_REF_RANGE_TO,
            TEST_RESULT_VAL_CD      AS RESULTEDTEST_VAL_CD,
            TEST_RESULT_VAL_CD_DESC AS RESULTEDTEST_VAL_CD_DESC,
            (REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lab_result_txt_val,
                                                                     '&#x09;', CHAR(9)),
                                                             '&#x0A;', CHAR(10)),
                                                     '&#x0D;', CHAR(13)),
                                             '&#x20;', CHAR(32)),
                                     '&amp;', CHAR(38)),
                             '&lt;', CHAR(60)),
                     '&gt;', CHAR(62))) AS LAB_RESULT_TXT_VAL,
            RTRIM(NUMERIC_RESULT) + COALESCE(' ' + RTRIM(RESULT_UNITS), '') AS NUMERIC_RESULT_WITHUNITS
        INTO #TMP_LAB_RESULT_VALMODIFIED
        FROM dbo.LAB_RESULT_VAL lr WITH (NOLOCK)
        WHERE TEST_RESULT_GRP_KEY IN (
            SELECT DISTINCT TEST_RESULT_GRP_KEY FROM #TMP_LABTEST_LABTESTRESULT
        );

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LAB_RESULT_VALMODIFIED' AS step, * FROM #TMP_LAB_RESULT_VALMODIFIED;

        -- Pull comment records tied to this batch's lab tests.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LAB_RESULT_COMMENT';

        IF OBJECT_ID('tempdb..#TMP_LAB_RESULT_COMMENT', 'U') IS NOT NULL
            DROP TABLE #TMP_LAB_RESULT_COMMENT;

        SELECT
            LAB_TEST_UID,
            LAB_RESULT_COMMENT_KEY,
            SUBSTRING(LAB_RESULT_COMMENTS, 1, 2000) AS LAB_RESULT_COMMENTS,
            RESULT_COMMENT_GRP_KEY,
            SUBSTRING(RECORD_STATUS_CD, 1, 8) AS RECORD_STATUS_CD,
            RDB_LAST_REFRESH_TIME
        INTO #TMP_LAB_RESULT_COMMENT
        FROM (
            SELECT lrc.*
            FROM dbo.LAB_RESULT_COMMENT lrc WITH (NOLOCK)
                INNER JOIN #TMP_LABTEST_LABTESTRESULT tmp ON lrc.LAB_TEST_UID = tmp.LAB_TEST_UID
        ) t;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LAB_RESULT_COMMENT' AS step, * FROM #TMP_LAB_RESULT_COMMENT;

        -- Attach normalized values and comments to each result row, and
        -- derive the result's parent order UID.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LABTEST_RESULT_ENRICHED';

        IF OBJECT_ID('tempdb..#TMP_LABTEST_RESULT_ENRICHED', 'U') IS NOT NULL
            DROP TABLE #TMP_LABTEST_RESULT_ENRICHED;

        SELECT
            ltr.LAB_TEST_KEY, ltr.LAB_RPT_LOCAL_ID, ltr.TEST_METHOD_CD, ltr.TEST_METHOD_CD_DESC,
            ltr.RESULTED_LAB_TEST_CD, ltr.ELR_IND, ltr.RESULTED_RPT_UID, ltr.RESULTED_TEST,
            ltr.INTERPRETATION_FLG, ltr.LAB_RPT_RECEIVED_BY_PH_DT, ltr.LAB_RPT_CREATED_DT,
            ltr.LAB_RPT_CREATED_BY, ltr.LAB_TEST_DT, ltr.LAB_RPT_LAST_UPDATE_DT, ltr.JURISDICTION_CD,
            ltr.LAB_TEST_CD_SYS_NM, ltr.JURISDICTION_NM, ltr.OID, ltr.ACCESSION_NBR, ltr.SPECIMEN_SRC,
            ltr.SPECIMEN_DESC, ltr.SPECIMEN_SITE, ltr.SPECIMEN_SITE_DESC, ltr.SPECIMEN_COLLECTION_DT,
            ltr.RESULTED_TEST_UID, ltr.ROOT_ORDERED_TEST_PNTR, ltr.PARENT_TEST_PNTR,
            ltr.TEST_RESULT_GRP_KEY, ltr.PERFORMING_LAB_KEY, ltr.LAB_RPT_LAST_UPDATE_BY,
            ltr.ALT_LAB_TEST_CD, ltr.ALT_LAB_TEST_CD_DESC, ltr.ALT_LAB_TEST_CD_SYS_CD, ltr.ALT_LAB_TEST_CD_SYS_NM,
            ltr.RESULTED_LAB_TEST_CD_DESC, ltr.RESULTEDTEST_CD_SYS_NM, ltr.RESULT_TEST_METHOD_CD,
            ltr.RESULTED_LAB_TEST_KEY, ltr.lab_test_type,
            ltrv.RESULT, ltrv.TEST_RESULT_VAL_CD, ltrv.TEST_RESULT_VAL_CD_SYS_NM, ltrv.LOCAL_RESULT_CODE,
            ltrv.LOCAL_RESULT_NAME, ltrv.RESULT_REF_RANGE_FRM, ltrv.RESULT_REF_RANGE_TO,
            ltrv.RESULTEDTEST_VAL_CD, ltrv.RESULTEDTEST_VAL_CD_DESC, ltrv.LAB_RESULT_TXT_VAL,
            ltrv.NUMERIC_RESULT_WITHUNITS,
            tlrc.LAB_RESULT_COMMENTS,
            ltr.PARENT_TEST_PNTR AS ORDERED_TEST_UID
        INTO #TMP_LABTEST_RESULT_ENRICHED
        FROM #TMP_LABTEST_RESULT ltr
            LEFT OUTER JOIN #TMP_LAB_RESULT_VALMODIFIED ltrv
                ON ltr.TEST_RESULT_GRP_KEY = ltrv.TEST_RESULT_GRP_KEY_VAL
            LEFT OUTER JOIN #TMP_LAB_RESULT_COMMENT tlrc
                ON tlrc.RESULT_COMMENT_GRP_KEY = ltr.RESULT_COMMENT_GRP_KEY;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LABTEST_RESULT_ENRICHED' AS step, * FROM #TMP_LABTEST_RESULT_ENRICHED;

        -- Enrich order rows with patient demographic and address fields.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LABTEST_ORDER1';

        IF OBJECT_ID('tempdb..#TMP_LABTEST_ORDER1', 'U') IS NOT NULL
            DROP TABLE #TMP_LABTEST_ORDER1;

        SELECT
            DISTINCT LTO.*,
                     PATIENT_UID,
                     PATIENT_FIRST_NAME AS PERSON_FIRST_NM,
                     PATIENT_MIDDLE_NAME AS PERSON_MIDDLE_NM,
                     PATIENT_LAST_NAME AS PERSON_LAST_NM,
                     PATIENT_LOCAL_ID AS PERSON_LOCAL_ID,
                     PATIENT_DOB AS PERSON_DOB,
                     PATIENT_CURRENT_SEX AS PERSON_CURR_GENDER,
                     CAST((
                         COALESCE(RTRIM(PATIENT_STREET_ADDRESS_1), '')
                             + COALESCE(',' + RTRIM(PATIENT_STREET_ADDRESS_2), '')
                             + COALESCE(',' + UPPER(RTRIM(PATIENT_CITY)), '')
                             + COALESCE(',' + RTRIM(PATIENT_COUNTY), '')
                             + COALESCE(',' + RTRIM(PATIENT_ZIP), '')
                             + COALESCE(',' + RTRIM(PATIENT_STATE), '')
                         ) AS VARCHAR(725)) AS PATIENT_ADDRESS,
                     PATIENT_STREET_ADDRESS_2,
                     RTRIM(PATIENT_CITY) AS PATIENT_CITY,
                     PATIENT_STATE,
                     PATIENT_ZIP AS PATIENT_ZIP_CODE,
                     PATIENT_COUNTY,
                     PATIENT_COUNTRY,
                     PATIENT_AGE_REPORTED AS AGE_REPORTED,
                     PATIENT_AGE_REPORTED_UNIT AS PATIENT_REPORTED_AGE_UNITS,
                     CAST('' AS VARCHAR(10)) AS ADDR_USE_CD_DESC,
                     CAST('' AS VARCHAR(10)) AS ADDR_CD_DESC
        INTO #TMP_LABTEST_ORDER1
        FROM #TMP_LABTEST_ORDER LTO
            LEFT OUTER JOIN dbo.D_PATIENT PAT WITH (NOLOCK) ON LTO.PATIENT_KEY = PAT.PATIENT_KEY;

        -- Default the address-use descriptors whenever a patient address
        -- was actually resolved.
        UPDATE #TMP_LABTEST_ORDER1
        SET ADDR_USE_CD_DESC = 'HOME',
            ADDR_CD_DESC = 'HOUSE'
        WHERE PATIENT_ADDRESS IS NOT NULL AND RTRIM(PATIENT_ADDRESS) != '';

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LABTEST_ORDER1' AS step, * FROM #TMP_LABTEST_ORDER1;

        -- Derive PROGRAM_AREA_ID by parsing the OID string. Tries a
        -- left-aligned parse first, then falls back to a right-aligned
        -- parse to match legacy SAS SUBSTR(PUT(OID,11.),7,5) behavior.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LAB_RESULTS_ORDER_CONTACT1';

        IF OBJECT_ID('tempdb..#TMP_LAB_RESULTS_ORDER_CONTACT1', 'U') IS NOT NULL
            DROP TABLE #TMP_LAB_RESULTS_ORDER_CONTACT1;

        SELECT
            *, COALESCE(
                TRY_CAST(NULLIF(LTRIM(RTRIM(SUBSTRING(LEFT(RTRIM(CAST(oid AS VARCHAR(30))) + SPACE(11), 11), 7, 5))), '') AS INT),
                TRY_CAST(NULLIF(LTRIM(RTRIM(SUBSTRING(RIGHT(SPACE(11) + RTRIM(CAST(oid AS VARCHAR(30))), 11), 7, 5))), '') AS INT)
            ) AS PROGRAM_AREA_ID
        INTO #TMP_LAB_RESULTS_ORDER_CONTACT1
        FROM #TMP_LABTEST_RESULT_ENRICHED;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LAB_RESULTS_ORDER_CONTACT1' AS step, * FROM #TMP_LAB_RESULTS_ORDER_CONTACT1;

        -- Resolve program-area reference data for the derived ID.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LAB_RESULTS_ORDER_CONTACT2';

        IF OBJECT_ID('tempdb..#TMP_LAB_RESULTS_ORDER_CONTACT2', 'U') IS NOT NULL
            DROP TABLE #TMP_LAB_RESULTS_ORDER_CONTACT2;

        SELECT
            tlroc1.*, pac.*
        INTO #TMP_LAB_RESULTS_ORDER_CONTACT2
        FROM #TMP_LAB_RESULTS_ORDER_CONTACT1 tlroc1
            LEFT OUTER JOIN dbo.nrt_srte_Program_area_code pac WITH (NOLOCK)
                ON TRY_CAST(LEFT(CAST(pac.NBS_UID AS VARCHAR(30)) + SPACE(5), 5) AS INT) = tlroc1.PROGRAM_AREA_ID;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LAB_RESULTS_ORDER_CONTACT2' AS step, * FROM #TMP_LAB_RESULTS_ORDER_CONTACT2;

        -- Attach ordering-provider details to each order.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_PERSON_ORDER_PROVIDER';

        IF OBJECT_ID('tempdb..#TMP_PERSON_ORDER_PROVIDER', 'U') IS NOT NULL
            DROP TABLE #TMP_PERSON_ORDER_PROVIDER;

        SELECT
            LABORDER.*,
            PROVIDER_PHONE_WORK AS PROVIDER_PHONE,
            PROVIDER_FIRST_NAME, PROVIDER_MIDDLE_NAME, PROVIDER_LAST_NAME,
            COALESCE(RTRIM(PROVIDER_LAST_NAME), '') + ', ' + COALESCE(RTRIM(PROVIDER_FIRST_NAME), '') + COALESCE(' ' + RTRIM(PROVIDER_MIDDLE_NAME), '')
                AS ORDERING_PROVIDER_NM,
            PROVIDER_STREET_ADDRESS_1, PROVIDER_STREET_ADDRESS_2,
            UPPER(PROVIDER_CITY) AS PROVIDER_CITY,
            PROVIDER_STATE, PROVIDER_ZIP,
            PROVIDER_COUNTY, PROVIDER_COUNTRY,
            CAST((
                COALESCE(RTRIM(PROVIDER_STREET_ADDRESS_1), '')
                    + COALESCE(',' + RTRIM(PROVIDER_STREET_ADDRESS_2), '')
                    + COALESCE(',' + UPPER(RTRIM(PROVIDER_CITY)), '')
                    + COALESCE(',' + RTRIM(PROVIDER_COUNTY), '')
                    + COALESCE(',' + RTRIM(PROVIDER_ZIP), '')
                    + COALESCE(',' + RTRIM(PROVIDER_STATE), '')
                ) AS VARCHAR(725)) AS PROVIDER_ADDRESS,
            CAST('' AS VARCHAR(30)) AS PRV_ADDR_USE_CD_DESC,
            CAST('' AS VARCHAR(30)) AS PRV_ADDR_CD_DESC
        INTO #TMP_PERSON_ORDER_PROVIDER
        FROM dbo.D_PROVIDER P WITH (NOLOCK),
             #TMP_LABTEST_ORDER1 LABORDER
        WHERE LABORDER.ORDERING_PROVIDER_KEY = P.PROVIDER_KEY;

        -- Default the provider address-use descriptors whenever a provider
        -- address was actually resolved, then null out any that ended up
        -- blank.
        UPDATE #TMP_PERSON_ORDER_PROVIDER
        SET PRV_ADDR_USE_CD_DESC = 'PRIMARY WORK PLACE',
            PRV_ADDR_CD_DESC = 'OFFICE'
        WHERE PROVIDER_ADDRESS IS NOT NULL AND RTRIM(PROVIDER_ADDRESS) != '';

        UPDATE #TMP_PERSON_ORDER_PROVIDER
        SET PRV_ADDR_USE_CD_DESC = NULL
        WHERE RTRIM(PRV_ADDR_USE_CD_DESC) = '';

        UPDATE #TMP_PERSON_ORDER_PROVIDER
        SET PRV_ADDR_CD_DESC = NULL
        WHERE RTRIM(PRV_ADDR_CD_DESC) = '';

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_PERSON_ORDER_PROVIDER' AS step, * FROM #TMP_PERSON_ORDER_PROVIDER;

        -- Resolve reporting-facility (lab) organization details.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LAB_ENTITY1';

        IF OBJECT_ID('tempdb..#TMP_LAB_ENTITY1', 'U') IS NOT NULL
            DROP TABLE #TMP_LAB_ENTITY1;

        SELECT
            DISTINCT
            pop.REPORTING_LAB_KEY_ORDER AS REPORTING_LAB_KEY_REPORTING,
            REPORTING_LAB.ORGANIZATION_NAME AS REPORTING_FACILITY,
            REPORTING_LAB.ORGANIZATION_FACILITY_ID AS REPORTING_FACILITY_CLIA_NBR,
            REPORTING_LAB.ORGANIZATION_LOCAL_ID AS REPORTING_FACILITY_ID,
            REPORTING_LAB.ORGANIZATION_UID AS REPORTING_FACILITY_UID,
            REPORTING_LAB.ORGANIZATION_PHONE_WORK AS REPORTING_FACILITY_PHONE_NBR
        INTO #TMP_LAB_ENTITY1
        FROM #TMP_PERSON_ORDER_PROVIDER pop
            INNER JOIN dbo.D_ORGANIZATION REPORTING_LAB WITH (NOLOCK)
                ON REPORTING_LAB.ORGANIZATION_KEY = pop.REPORTING_LAB_KEY_ORDER;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LAB_ENTITY1' AS step, * FROM #TMP_LAB_ENTITY1;

        -- Resolve ordering-facility organization details.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LAB_ENTITY2';

        IF OBJECT_ID('tempdb..#TMP_LAB_ENTITY2', 'U') IS NOT NULL
            DROP TABLE #TMP_LAB_ENTITY2;

        SELECT
            DISTINCT
            pop.ORDERING_ORG_KEY AS ORDERING_ORG_KEY_ORDER,
            ORDERING_ORG.ORGANIZATION_LOCAL_ID AS ORDERING_FACILITY_ID,
            ORDERING_ORG.ORGANIZATION_NAME AS ORDERING_FACILITY,
            ORDERING_ORG.ORGANIZATION_PHONE_WORK AS ORDERING_FACILITY_PHONE_NBR
        INTO #TMP_LAB_ENTITY2
        FROM #TMP_PERSON_ORDER_PROVIDER pop
            INNER JOIN dbo.D_ORGANIZATION ORDERING_ORG WITH (NOLOCK)
                ON ORDERING_ORG.ORGANIZATION_KEY = pop.ORDERING_ORG_KEY;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LAB_ENTITY2' AS step, * FROM #TMP_LAB_ENTITY2;

        -- Join reporting-facility rows back to the provider/order context.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LAB_ORDER_ENTITY1';

        IF OBJECT_ID('tempdb..#TMP_LAB_ORDER_ENTITY1', 'U') IS NOT NULL
            DROP TABLE #TMP_LAB_ORDER_ENTITY1;

        SELECT
            DISTINCT le.*, pop.*
        INTO #TMP_LAB_ORDER_ENTITY1
        FROM #TMP_LAB_ENTITY1 le,
             #TMP_PERSON_ORDER_PROVIDER pop
        WHERE le.REPORTING_LAB_KEY_REPORTING = pop.REPORTING_LAB_KEY_ORDER;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LAB_ORDER_ENTITY1' AS step, * FROM #TMP_LAB_ORDER_ENTITY1;

        -- Union the ordering-org keys found via both entity resolutions
        -- above, to build one distinct list to drive the merge below.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LAB_ORDER_ENTITY_KEY';

        IF OBJECT_ID('tempdb..#TMP_LAB_ORDER_ENTITY_KEY', 'U') IS NOT NULL
            DROP TABLE #TMP_LAB_ORDER_ENTITY_KEY;

        SELECT
            ORDERING_ORG_KEY_ORDER
        INTO #TMP_LAB_ORDER_ENTITY_KEY
        FROM #TMP_LAB_ENTITY2
        UNION
        SELECT
            ORDERING_ORG_KEY
        FROM #TMP_LAB_ORDER_ENTITY1;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LAB_ORDER_ENTITY_KEY' AS step, * FROM #TMP_LAB_ORDER_ENTITY_KEY;

        -- Combine reporting- and ordering-facility details per key.
        -- INVESTIGATION_KEYS / INV_KEY are placeholders, populated below.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LAB_ORDER_ENTITY11';

        IF OBJECT_ID('tempdb..#TMP_LAB_ORDER_ENTITY11', 'U') IS NOT NULL
            DROP TABLE #TMP_LAB_ORDER_ENTITY11;

        SELECT
            DISTINCT COALESCE(e2.ORDERING_ORG_KEY_ORDER, e1.REPORTING_LAB_KEY_REPORTING) AS ORDERING_ORG_KEY_MAIN, e2.*, e1.*,
                     CAST(NULL AS VARCHAR(2000)) AS INVESTIGATION_KEYS,
                     CAST(NULL AS BIGINT) AS INV_KEY
        INTO #TMP_LAB_ORDER_ENTITY11
        FROM #TMP_LAB_ORDER_ENTITY_KEY loek
            LEFT OUTER JOIN #TMP_LAB_ENTITY2 e2 ON e2.ORDERING_ORG_KEY_ORDER = loek.ORDERING_ORG_KEY_ORDER
            LEFT OUTER JOIN #TMP_LAB_ORDER_ENTITY1 e1 ON e1.ORDERING_ORG_KEY = loek.ORDERING_ORG_KEY_ORDER;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LAB_ORDER_ENTITY11' AS step, * FROM #TMP_LAB_ORDER_ENTITY11;

        -- Roll up investigation keys per lab test into one delimited string.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LAB_ORDER_ENTITY11_INVKEYS';

        IF OBJECT_ID('tempdb..#TMP_LAB_ORDER_ENTITY11_INVKEYS', 'U') IS NOT NULL
            DROP TABLE #TMP_LAB_ORDER_ENTITY11_INVKEYS;

        SELECT
            lab_test_key,
            STRING_AGG(CAST(investigation_key AS VARCHAR(20)), ', ')
                WITHIN GROUP (ORDER BY investigation_key) AS INVESTIGATION_KEYS
        INTO #TMP_LAB_ORDER_ENTITY11_INVKEYS
        FROM #TMP_LAB_ORDER_ENTITY11
        GROUP BY lab_test_key;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LAB_ORDER_ENTITY11_INVKEYS' AS step, * FROM #TMP_LAB_ORDER_ENTITY11_INVKEYS;

        -- Build the final flattened order/entity/investigation-key row
        -- set. Source columns that could collide are disambiguated with
        -- an _OE suffix.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LAB_ORDER_ENTITY';

        IF OBJECT_ID('tempdb..#TMP_LAB_ORDER_ENTITY', 'U') IS NOT NULL
            DROP TABLE #TMP_LAB_ORDER_ENTITY;

        SELECT
            DISTINCT [ORDERING_ORG_KEY_MAIN]
                   ,[ORDERING_ORG_KEY_ORDER]
                   ,[ORDERING_FACILITY_ID]
                   ,[ORDERING_FACILITY]
                   ,[ORDERING_FACILITY_PHONE_NBR]
                   ,[REPORTING_LAB_KEY_REPORTING]
                   ,[REPORTING_FACILITY]
                   ,[REPORTING_FACILITY_CLIA_NBR]
                   ,[REPORTING_FACILITY_ID]
                   ,[REPORTING_FACILITY_UID]
                   ,[REPORTING_FACILITY_PHONE_NBR]
                   ,[LAB_TEST_STATUS]
                   ,loe11.[LAB_TEST_KEY] AS LAB_TEST_KEY_OE
                   ,[LAB_RPT_LOCAL_ID] AS LAB_RPT_LOCAL_ID_OE
                   ,[REASON_FOR_TEST_DESC]
                   ,[RECORD_STATUS_CD]
                   ,[ORDERED_RPT_UID]
                   ,[ORDERED_LAB_TEST_CD]
                   ,[ORDERED_LAB_TEST_CD_DESC]
                   ,[ORDERED_TEST_CODE]
                   ,[ORDERED_LABTEST_CD_SYS_NM]
                   ,[SPECIMEN_DETAILS]
                   ,[ORDERED_TEST_UID] AS ORDERED_TEST_UID_OE
                   ,[SPECIMEN_ADD_TIME]
                   ,[SPECIMEN_LAST_CHANGE_TIME]
                   ,[ORDERING_ORG_KEY]
                   ,[REPORTING_LAB_KEY_ORDER]
                   ,[CONDITION_KEY]
                   ,[ORDERING_PROVIDER_KEY]
                   ,[LAB_RPT_STATUS]
                   ,[OID] AS oid_order
                   ,[CONDITION_CD]
                   ,[REASON_FOR_TEST_DESC1]
                   ,[SPECIMEN_SRC_CD]
                   ,[SPECIMEN_SRC_DESC]
                   ,[LDF_GROUP_KEY]
                   ,[MORB_RPT_KEY]
                   ,[PATIENT_KEY]
                   ,[DOCUMENT_LINK]
                   ,[ALT_LAB_TEST_CD_SYS_CD] AS ALT_LAB_TEST_CD_SYS_CD_OE
                   ,[lab_test_type] AS lab_test_type_oe
                   ,[PATIENT_UID]
                   ,[PERSON_FIRST_NM]
                   ,[PERSON_MIDDLE_NM]
                   ,[PERSON_LAST_NM]
                   ,[PERSON_LOCAL_ID]
                   ,[PERSON_DOB]
                   ,[PERSON_CURR_GENDER]
                   ,[PATIENT_ADDRESS]
                   ,[PATIENT_STREET_ADDRESS_2]
                   ,[PATIENT_CITY]
                   ,[PATIENT_STATE]
                   ,[PATIENT_ZIP_CODE]
                   ,[PATIENT_COUNTY]
                   ,[PATIENT_COUNTRY]
                   ,[AGE_REPORTED]
                   ,[PATIENT_REPORTED_AGE_UNITS]
                   ,[ADDR_USE_CD_DESC]
                   ,[ADDR_CD_DESC]
                   ,[PROVIDER_PHONE]
                   ,[PROVIDER_FIRST_NAME]
                   ,[PROVIDER_MIDDLE_NAME]
                   ,[PROVIDER_LAST_NAME]
                   ,[ORDERING_PROVIDER_NM]
                   ,[PROVIDER_STREET_ADDRESS_1]
                   ,[PROVIDER_STREET_ADDRESS_2]
                   ,[PROVIDER_CITY]
                   ,[PROVIDER_STATE]
                   ,[PROVIDER_ZIP]
                   ,[PROVIDER_COUNTY]
                   ,[PROVIDER_COUNTRY]
                   ,[PROVIDER_ADDRESS]
                   ,[PRV_ADDR_USE_CD_DESC]
                   ,[PRV_ADDR_CD_DESC]
                   ,loei.[INVESTIGATION_KEYS]
                   ,[INV_KEY]
        INTO #TMP_LAB_ORDER_ENTITY
        FROM #TMP_LAB_ORDER_ENTITY11 loe11
            LEFT OUTER JOIN #TMP_LAB_ORDER_ENTITY11_INVKEYS loei ON loei.lab_test_key = loe11.lab_test_key;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LAB_ORDER_ENTITY' AS step, * FROM #TMP_LAB_ORDER_ENTITY;

        -- Join the order/entity rows back to their result rows.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LABTESTSINIT';

        IF OBJECT_ID('tempdb..#TMP_LABTESTSINIT', 'U') IS NOT NULL
            DROP TABLE #TMP_LABTESTSINIT;

        SELECT *
        INTO #TMP_LABTESTSINIT
        FROM #TMP_LAB_ORDER_ENTITY loe
            LEFT OUTER JOIN #TMP_LABTEST_RESULT_ENRICHED loeu ON loe.ORDERED_TEST_UID_OE = loeu.ORDERED_TEST_UID;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LABTESTSINIT' AS step, * FROM #TMP_LABTESTSINIT;

        -- Attach condition, program-area, and LOINC reference data.
        -- LOINC is resolved from the ordered test code when it is itself
        -- LOINC-coded, falling back to a hyphenated local code or a
        -- reference-table lookup.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LABTESTS';

        IF OBJECT_ID('tempdb..#TMP_LABTESTS', 'U') IS NOT NULL
            DROP TABLE #TMP_LABTESTS;

        SELECT
            li.ORDERING_ORG_KEY_MAIN, li.ORDERING_ORG_KEY_ORDER, li.ORDERING_FACILITY_ID, li.ORDERING_FACILITY,
            li.ORDERING_FACILITY_PHONE_NBR, li.REPORTING_LAB_KEY_REPORTING, li.REPORTING_FACILITY,
            li.REPORTING_FACILITY_CLIA_NBR, li.REPORTING_FACILITY_ID, li.REPORTING_FACILITY_UID,
            li.REPORTING_FACILITY_PHONE_NBR, li.LAB_TEST_STATUS, li.LAB_TEST_KEY_OE, li.LAB_RPT_LOCAL_ID_OE,
            li.REASON_FOR_TEST_DESC, li.RECORD_STATUS_CD, li.ORDERED_RPT_UID, li.ORDERED_LAB_TEST_CD,
            li.ORDERED_LAB_TEST_CD_DESC, li.ORDERED_TEST_CODE, li.ORDERED_LABTEST_CD_SYS_NM, li.SPECIMEN_DETAILS,
            li.ORDERED_TEST_UID_OE, li.SPECIMEN_ADD_TIME, li.SPECIMEN_LAST_CHANGE_TIME, li.ORDERING_ORG_KEY,
            li.REPORTING_LAB_KEY_ORDER, li.CONDITION_KEY, li.ORDERING_PROVIDER_KEY, li.LAB_RPT_STATUS, li.oid_order,
            li.CONDITION_CD, li.REASON_FOR_TEST_DESC1, li.SPECIMEN_SRC_CD, li.SPECIMEN_SRC_DESC, li.LDF_GROUP_KEY,
            li.MORB_RPT_KEY, li.PATIENT_KEY, li.DOCUMENT_LINK, li.ALT_LAB_TEST_CD_SYS_CD_OE, li.lab_test_type_oe,
            li.PATIENT_UID, li.PERSON_FIRST_NM, li.PERSON_MIDDLE_NM, li.PERSON_LAST_NM, li.PERSON_LOCAL_ID,
            li.PERSON_DOB, li.PERSON_CURR_GENDER, li.PATIENT_ADDRESS, li.PATIENT_STREET_ADDRESS_2, li.PATIENT_CITY,
            li.PATIENT_STATE, li.PATIENT_ZIP_CODE, li.PATIENT_COUNTY, li.PATIENT_COUNTRY, li.AGE_REPORTED,
            li.PATIENT_REPORTED_AGE_UNITS, li.ADDR_USE_CD_DESC, li.ADDR_CD_DESC, li.PROVIDER_PHONE,
            li.PROVIDER_FIRST_NAME, li.PROVIDER_MIDDLE_NAME, li.PROVIDER_LAST_NAME, li.ORDERING_PROVIDER_NM,
            li.PROVIDER_STREET_ADDRESS_1, li.PROVIDER_STREET_ADDRESS_2, li.PROVIDER_CITY, li.PROVIDER_STATE,
            li.PROVIDER_ZIP, li.PROVIDER_COUNTY, li.PROVIDER_COUNTRY, li.PROVIDER_ADDRESS, li.PRV_ADDR_USE_CD_DESC,
            li.PRV_ADDR_CD_DESC, li.INVESTIGATION_KEYS, li.INV_KEY, li.LAB_TEST_KEY, li.LAB_RPT_LOCAL_ID,
            li.TEST_METHOD_CD, li.TEST_METHOD_CD_DESC, li.RESULTED_LAB_TEST_CD, li.ELR_IND, li.RESULTED_RPT_UID,
            li.RESULTED_TEST, li.INTERPRETATION_FLG, li.LAB_RPT_RECEIVED_BY_PH_DT, li.LAB_RPT_CREATED_DT,
            li.LAB_RPT_CREATED_BY, li.LAB_TEST_DT, li.LAB_RPT_LAST_UPDATE_DT, li.JURISDICTION_CD,
            li.LAB_TEST_CD_SYS_NM, li.JURISDICTION_NM, li.OID, li.ACCESSION_NBR, li.SPECIMEN_SRC, li.SPECIMEN_DESC,
            li.SPECIMEN_SITE, li.SPECIMEN_SITE_DESC, li.SPECIMEN_COLLECTION_DT, li.RESULTED_TEST_UID,
            li.ROOT_ORDERED_TEST_PNTR, li.PARENT_TEST_PNTR, li.TEST_RESULT_GRP_KEY, li.PERFORMING_LAB_KEY,
            li.ALT_LAB_TEST_CD, li.ALT_LAB_TEST_CD_DESC, li.ALT_LAB_TEST_CD_SYS_CD, li.ALT_LAB_TEST_CD_SYS_NM,
            li.RESULTED_LAB_TEST_CD_DESC, li.RESULTEDTEST_CD_SYS_NM, li.RESULT_TEST_METHOD_CD,
            li.RESULTED_LAB_TEST_KEY, li.lab_test_type, li.RESULT, li.TEST_RESULT_VAL_CD,
            li.TEST_RESULT_VAL_CD_SYS_NM, li.LOCAL_RESULT_CODE, li.LOCAL_RESULT_NAME, li.RESULT_REF_RANGE_FRM,
            li.RESULT_REF_RANGE_TO, li.RESULTEDTEST_VAL_CD, li.RESULTEDTEST_VAL_CD_DESC, li.LAB_RESULT_TXT_VAL,
            li.NUMERIC_RESULT_WITHUNITS, li.LAB_RESULT_COMMENTS, li.ORDERED_TEST_UID,
            lroc2.code_seq, lroc2.code_set_nm, lroc2.nbs_uid, lroc2.prog_area_cd, lroc2.prog_area_desc_txt,
            lroc2.PROGRAM_AREA_ID, lroc2.status_cd, lroc2.status_time,
            cc.CONDITION_SHORT_NM,
            CASE
                WHEN LTRIM(RTRIM(lr.LOINC_RAW)) IS NULL AND CHARINDEX('-', li.ORDERED_LAB_TEST_CD) > 3 THEN li.ORDERED_LAB_TEST_CD
                WHEN LTRIM(RTRIM(lr.LOINC_RAW)) IS NULL THEN ll.loinc_cd
                ELSE lr.LOINC_RAW
            END AS LOINC,
            CAST(NULL AS VARCHAR(50)) AS CONDITION
        INTO #TMP_LABTESTS
        FROM #TMP_LABTESTSINIT li
            LEFT OUTER JOIN dbo.nrt_srte_Condition_code cc WITH (NOLOCK) ON cc.CONDITION_CD = li.CONDITION_CD
            LEFT OUTER JOIN #TMP_LAB_RESULTS_ORDER_CONTACT2 lroc2 ON lroc2.RESULTED_TEST_UID = li.RESULTED_TEST_UID
            LEFT OUTER JOIN dbo.nrt_srte_Labtest_loinc ll ON ll.LAB_TEST_CD = li.ORDERED_LAB_TEST_CD
            CROSS APPLY (
                SELECT CASE WHEN UPPER(li.LAB_TEST_CD_SYS_NM) = 'LOINC' THEN li.ORDERED_LAB_TEST_CD ELSE CAST(NULL AS VARCHAR(50)) END AS LOINC_RAW
            ) lr;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LABTESTS' AS step, * FROM #TMP_LABTESTS;

        -- Overlay a condition code derived from LOINC/condition reference
        -- data wherever one is available.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LABTESTS3';

        IF OBJECT_ID('tempdb..#TMP_LABTESTS3', 'U') IS NOT NULL
            DROP TABLE #TMP_LABTESTS3;

        SELECT
            lt2.ORDERING_ORG_KEY_MAIN, lt2.ORDERING_ORG_KEY_ORDER, lt2.ORDERING_FACILITY_ID, lt2.ORDERING_FACILITY,
            lt2.ORDERING_FACILITY_PHONE_NBR, lt2.REPORTING_LAB_KEY_REPORTING, lt2.REPORTING_FACILITY,
            lt2.REPORTING_FACILITY_CLIA_NBR, lt2.REPORTING_FACILITY_ID, lt2.REPORTING_FACILITY_UID,
            lt2.REPORTING_FACILITY_PHONE_NBR, lt2.LAB_TEST_STATUS, lt2.LAB_TEST_KEY_OE, lt2.LAB_RPT_LOCAL_ID_OE,
            lt2.REASON_FOR_TEST_DESC, lt2.RECORD_STATUS_CD, lt2.ORDERED_RPT_UID, lt2.ORDERED_LAB_TEST_CD,
            lt2.ORDERED_LAB_TEST_CD_DESC, lt2.ORDERED_TEST_CODE, lt2.ORDERED_LABTEST_CD_SYS_NM, lt2.SPECIMEN_DETAILS,
            lt2.ORDERED_TEST_UID_OE, lt2.SPECIMEN_ADD_TIME, lt2.SPECIMEN_LAST_CHANGE_TIME, lt2.ORDERING_ORG_KEY,
            lt2.REPORTING_LAB_KEY_ORDER, lt2.CONDITION_KEY, lt2.ORDERING_PROVIDER_KEY, lt2.LAB_RPT_STATUS,
            lt2.oid_order,
            CASE
                WHEN lc.condition_cd IS NOT NULL AND RTRIM(LTRIM(lc.condition_cd)) <> '' THEN lc.condition_cd
                ELSE lt2.CONDITION_CD
            END AS CONDITION_CD,
            lt2.REASON_FOR_TEST_DESC1, lt2.SPECIMEN_SRC_CD, lt2.SPECIMEN_SRC_DESC, lt2.LDF_GROUP_KEY,
            lt2.MORB_RPT_KEY, lt2.PATIENT_KEY, lt2.DOCUMENT_LINK, lt2.ALT_LAB_TEST_CD_SYS_CD_OE, lt2.lab_test_type_oe,
            lt2.PATIENT_UID, lt2.PERSON_FIRST_NM, lt2.PERSON_MIDDLE_NM, lt2.PERSON_LAST_NM, lt2.PERSON_LOCAL_ID,
            lt2.PERSON_DOB, lt2.PERSON_CURR_GENDER, lt2.PATIENT_ADDRESS, lt2.PATIENT_STREET_ADDRESS_2,
            lt2.PATIENT_CITY, lt2.PATIENT_STATE, lt2.PATIENT_ZIP_CODE, lt2.PATIENT_COUNTY, lt2.PATIENT_COUNTRY,
            lt2.AGE_REPORTED, lt2.PATIENT_REPORTED_AGE_UNITS, lt2.ADDR_USE_CD_DESC, lt2.ADDR_CD_DESC,
            lt2.PROVIDER_PHONE, lt2.PROVIDER_FIRST_NAME, lt2.PROVIDER_MIDDLE_NAME, lt2.PROVIDER_LAST_NAME,
            lt2.ORDERING_PROVIDER_NM, lt2.PROVIDER_STREET_ADDRESS_1, lt2.PROVIDER_STREET_ADDRESS_2,
            lt2.PROVIDER_CITY, lt2.PROVIDER_STATE, lt2.PROVIDER_ZIP, lt2.PROVIDER_COUNTY, lt2.PROVIDER_COUNTRY,
            lt2.PROVIDER_ADDRESS, lt2.PRV_ADDR_USE_CD_DESC, lt2.PRV_ADDR_CD_DESC, lt2.INVESTIGATION_KEYS,
            lt2.INV_KEY, lt2.LAB_TEST_KEY, lt2.LAB_RPT_LOCAL_ID, lt2.TEST_METHOD_CD, lt2.TEST_METHOD_CD_DESC,
            lt2.RESULTED_LAB_TEST_CD, lt2.ELR_IND, lt2.RESULTED_RPT_UID, lt2.RESULTED_TEST, lt2.INTERPRETATION_FLG,
            lt2.LAB_RPT_RECEIVED_BY_PH_DT, lt2.LAB_RPT_CREATED_DT, lt2.LAB_RPT_CREATED_BY, lt2.LAB_TEST_DT,
            lt2.LAB_RPT_LAST_UPDATE_DT, lt2.JURISDICTION_CD, lt2.LAB_TEST_CD_SYS_NM, lt2.JURISDICTION_NM, lt2.OID,
            lt2.ACCESSION_NBR, lt2.SPECIMEN_SRC, lt2.SPECIMEN_DESC, lt2.SPECIMEN_SITE, lt2.SPECIMEN_SITE_DESC,
            lt2.SPECIMEN_COLLECTION_DT, lt2.RESULTED_TEST_UID, lt2.ROOT_ORDERED_TEST_PNTR, lt2.PARENT_TEST_PNTR,
            lt2.TEST_RESULT_GRP_KEY, lt2.PERFORMING_LAB_KEY, lt2.ALT_LAB_TEST_CD, lt2.ALT_LAB_TEST_CD_DESC,
            lt2.ALT_LAB_TEST_CD_SYS_CD, lt2.ALT_LAB_TEST_CD_SYS_NM, lt2.RESULTED_LAB_TEST_CD_DESC,
            lt2.RESULTEDTEST_CD_SYS_NM, lt2.RESULT_TEST_METHOD_CD, lt2.RESULTED_LAB_TEST_KEY, lt2.lab_test_type,
            lt2.RESULT, lt2.TEST_RESULT_VAL_CD, lt2.TEST_RESULT_VAL_CD_SYS_NM, lt2.LOCAL_RESULT_CODE,
            lt2.LOCAL_RESULT_NAME, lt2.RESULT_REF_RANGE_FRM, lt2.RESULT_REF_RANGE_TO, lt2.RESULTEDTEST_VAL_CD,
            lt2.RESULTEDTEST_VAL_CD_DESC, lt2.LAB_RESULT_TXT_VAL, lt2.NUMERIC_RESULT_WITHUNITS,
            lt2.LAB_RESULT_COMMENTS, lt2.ORDERED_TEST_UID, lt2.code_seq, lt2.code_set_nm, lt2.nbs_uid,
            lt2.prog_area_cd, lt2.prog_area_desc_txt, lt2.PROGRAM_AREA_ID, lt2.status_cd, lt2.status_time,
            CASE
                WHEN RTRIM(LTRIM(lt2.CONDITION_SHORT_NM)) = '' OR RTRIM(LTRIM(lt2.CONDITION_SHORT_NM)) IS NULL THEN lc.DISEASE_NM
                ELSE lt2.CONDITION_SHORT_NM
            END AS CONDITION_SHORT_NM,
            lt2.LOINC,
            lt2.CONDITION
        INTO #TMP_LABTESTS3
        FROM #TMP_LABTESTS lt2
            LEFT OUTER JOIN dbo.nrt_srte_Loinc_condition lc WITH (NOLOCK) ON lc.loinc_cd = lt2.LOINC;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LABTESTS3' AS step, * FROM #TMP_LABTESTS3;

        -- Apply SNOMED-derived condition overrides where the resulted
        -- value looks like a SNOMED code, blank out empty address/
        -- descriptor fields, and finalize the CONDITION/SNOMED columns.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING TMP_LABTESTS4';

        IF OBJECT_ID('tempdb..#TMP_LABTESTS4', 'U') IS NOT NULL
            DROP TABLE #TMP_LABTESTS4;

        SELECT
            lt3.ORDERING_ORG_KEY_MAIN, lt3.ORDERING_ORG_KEY_ORDER, lt3.ORDERING_FACILITY_ID, lt3.ORDERING_FACILITY,
            lt3.ORDERING_FACILITY_PHONE_NBR, lt3.REPORTING_LAB_KEY_REPORTING, lt3.REPORTING_FACILITY,
            lt3.REPORTING_FACILITY_CLIA_NBR, lt3.REPORTING_FACILITY_ID, lt3.REPORTING_FACILITY_UID,
            lt3.REPORTING_FACILITY_PHONE_NBR, lt3.LAB_TEST_STATUS, lt3.LAB_TEST_KEY_OE, lt3.LAB_RPT_LOCAL_ID_OE,
            lt3.REASON_FOR_TEST_DESC, lt3.RECORD_STATUS_CD, lt3.ORDERED_RPT_UID, lt3.ORDERED_LAB_TEST_CD,
            lt3.ORDERED_LAB_TEST_CD_DESC, lt3.ORDERED_TEST_CODE, lt3.ORDERED_LABTEST_CD_SYS_NM, lt3.SPECIMEN_DETAILS,
            lt3.ORDERED_TEST_UID_OE, lt3.SPECIMEN_ADD_TIME, lt3.SPECIMEN_LAST_CHANGE_TIME, lt3.ORDERING_ORG_KEY,
            lt3.REPORTING_LAB_KEY_ORDER, lt3.CONDITION_KEY, lt3.ORDERING_PROVIDER_KEY, lt3.LAB_RPT_STATUS,
            lt3.oid_order,
            CASE
                WHEN TEST_RESULT_VAL_CD LIKE '%[^0-9]%' AND SUBSTRING(TEST_RESULT_VAL_CD, 2, 1) = '-'
                    AND sc.CONDITION_CD IS NOT NULL AND RTRIM(LTRIM(sc.CONDITION_CD)) <> '' THEN sc.CONDITION_CD
                ELSE lt3.CONDITION_CD
            END AS CONDITION_CD,
            lt3.REASON_FOR_TEST_DESC1, lt3.SPECIMEN_SRC_CD, lt3.SPECIMEN_SRC_DESC, lt3.LDF_GROUP_KEY,
            lt3.MORB_RPT_KEY, lt3.PATIENT_KEY, lt3.DOCUMENT_LINK, lt3.ALT_LAB_TEST_CD_SYS_CD_OE, lt3.lab_test_type_oe,
            lt3.PATIENT_UID, lt3.PERSON_FIRST_NM, lt3.PERSON_MIDDLE_NM, lt3.PERSON_LAST_NM, lt3.PERSON_LOCAL_ID,
            lt3.PERSON_DOB, lt3.PERSON_CURR_GENDER,
            CASE WHEN RTRIM(Patient_Address) = '' THEN NULL ELSE lt3.PATIENT_ADDRESS END AS PATIENT_ADDRESS,
            lt3.PATIENT_STREET_ADDRESS_2, lt3.PATIENT_CITY, lt3.PATIENT_STATE, lt3.PATIENT_ZIP_CODE,
            lt3.PATIENT_COUNTY, lt3.PATIENT_COUNTRY, lt3.AGE_REPORTED, lt3.PATIENT_REPORTED_AGE_UNITS,
            CASE WHEN RTRIM(lt3.ADDR_USE_CD_DESC) = '' THEN NULL ELSE lt3.ADDR_USE_CD_DESC END AS ADDR_USE_CD_DESC,
            CASE WHEN RTRIM(lt3.ADDR_CD_DESC) = '' THEN NULL ELSE lt3.ADDR_CD_DESC END AS ADDR_CD_DESC,
            lt3.PROVIDER_PHONE, lt3.PROVIDER_FIRST_NAME, lt3.PROVIDER_MIDDLE_NAME, lt3.PROVIDER_LAST_NAME,
            lt3.ORDERING_PROVIDER_NM, lt3.PROVIDER_STREET_ADDRESS_1, lt3.PROVIDER_STREET_ADDRESS_2,
            lt3.PROVIDER_CITY, lt3.PROVIDER_STATE, lt3.PROVIDER_ZIP, lt3.PROVIDER_COUNTY, lt3.PROVIDER_COUNTRY,
            CASE WHEN RTRIM(PROVIDER_ADDRESS) = '' THEN NULL ELSE lt3.PROVIDER_ADDRESS END AS PROVIDER_ADDRESS,
            lt3.PRV_ADDR_USE_CD_DESC, lt3.PRV_ADDR_CD_DESC, lt3.INVESTIGATION_KEYS, lt3.INV_KEY, lt3.LAB_TEST_KEY,
            lt3.LAB_RPT_LOCAL_ID, lt3.TEST_METHOD_CD, lt3.TEST_METHOD_CD_DESC, lt3.RESULTED_LAB_TEST_CD,
            lt3.ELR_IND, lt3.RESULTED_RPT_UID, lt3.RESULTED_TEST, lt3.INTERPRETATION_FLG,
            lt3.LAB_RPT_RECEIVED_BY_PH_DT, lt3.LAB_RPT_CREATED_DT, lt3.LAB_RPT_CREATED_BY, lt3.LAB_TEST_DT,
            lt3.LAB_RPT_LAST_UPDATE_DT, lt3.JURISDICTION_CD, lt3.LAB_TEST_CD_SYS_NM, lt3.JURISDICTION_NM, lt3.OID,
            lt3.ACCESSION_NBR, lt3.SPECIMEN_SRC, lt3.SPECIMEN_DESC, lt3.SPECIMEN_SITE, lt3.SPECIMEN_SITE_DESC,
            lt3.SPECIMEN_COLLECTION_DT, lt3.RESULTED_TEST_UID, lt3.ROOT_ORDERED_TEST_PNTR, lt3.PARENT_TEST_PNTR,
            lt3.TEST_RESULT_GRP_KEY, lt3.PERFORMING_LAB_KEY, lt3.ALT_LAB_TEST_CD, lt3.ALT_LAB_TEST_CD_DESC,
            lt3.ALT_LAB_TEST_CD_SYS_CD, lt3.ALT_LAB_TEST_CD_SYS_NM, lt3.RESULTED_LAB_TEST_CD_DESC,
            lt3.RESULTEDTEST_CD_SYS_NM, lt3.RESULT_TEST_METHOD_CD, lt3.RESULTED_LAB_TEST_KEY, lt3.lab_test_type,
            lt3.RESULT, lt3.TEST_RESULT_VAL_CD, lt3.TEST_RESULT_VAL_CD_SYS_NM, lt3.LOCAL_RESULT_CODE,
            lt3.LOCAL_RESULT_NAME, lt3.RESULT_REF_RANGE_FRM, lt3.RESULT_REF_RANGE_TO, lt3.RESULTEDTEST_VAL_CD,
            lt3.RESULTEDTEST_VAL_CD_DESC, lt3.LAB_RESULT_TXT_VAL, lt3.NUMERIC_RESULT_WITHUNITS,
            lt3.LAB_RESULT_COMMENTS, lt3.ORDERED_TEST_UID, lt3.code_seq, lt3.code_set_nm, lt3.nbs_uid,
            lt3.prog_area_cd, lt3.prog_area_desc_txt, lt3.PROGRAM_AREA_ID, lt3.status_cd, lt3.status_time,
            CASE
                WHEN lt3.TEST_RESULT_VAL_CD LIKE '%[^0-9]%' AND SUBSTRING(lt3.TEST_RESULT_VAL_CD, 2, 1) = '-'
                    AND (lt3.CONDITION = '' OR lt3.CONDITION IS NULL) AND lt3.CONDITION_SHORT_NM IS NULL THEN SUBSTRING(sc.DISEASE_NM, 1, 50)
                ELSE lt3.CONDITION_SHORT_NM
            END AS CONDITION_SHORT_NM,
            lt3.LOINC,
            CASE
                WHEN TEST_RESULT_VAL_CD LIKE '%[^0-9]%' AND SUBSTRING(TEST_RESULT_VAL_CD, 2, 1) = '-'
                    AND (CONDITION = '' OR CONDITION IS NULL) THEN SUBSTRING(sc.DISEASE_NM, 1, 50)
                ELSE lt3.CONDITION
            END AS CONDITION,
            CASE
                WHEN lt3.TEST_RESULT_VAL_CD LIKE '%[^0-9]%' AND SUBSTRING(lt3.TEST_RESULT_VAL_CD, 2, 1) = '-' THEN lt3.TEST_RESULT_VAL_CD
                ELSE CAST(NULL AS VARCHAR(1000))
            END AS SNOMED
        INTO #TMP_LABTESTS4
        FROM #TMP_LABTESTS3 lt3
            LEFT OUTER JOIN dbo.nrt_srte_Snomed_condition sc WITH (NOLOCK) ON sc.SNOMED_CD = lt3.TEST_RESULT_VAL_CD;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        IF @debug = 1 SELECT 'TMP_LABTESTS4' AS step, * FROM #TMP_LABTESTS4;

        -- =================================================================
        -- Durable writes to dbo.LAB100 begin here. This is the only
        -- portion of the batch that needs transactional atomicity /
        -- rollback, since everything above only touches temp tables.
        -- =================================================================
        BEGIN TRANSACTION;

        -- Update existing LAB100 rows matched by RESULTED_LAB_TEST_KEY.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING LAB100 Table - Update';

        UPDATE dbo.LAB100
        SET
            [LAB_RPT_LOCAL_ID] = src.[LAB_RPT_LOCAL_ID]
          ,[RESULTED_LAB_TEST_CD] = SUBSTRING(src.RESULTED_LAB_TEST_CD, 1, 50)
          ,[PROGRAM_JURISDICTION_OID] = src.[oid]
          ,[RECORD_STATUS_CD] = SUBSTRING(src.RECORD_STATUS_CD, 1, 8)
          ,[RESULTED_LAB_TEST_CD_DESC] = SUBSTRING(RTRIM(src.RESULTED_LAB_TEST_CD_DESC), 1, 1000)
          ,[RESULTEDTEST_CD_SYS_NM] = SUBSTRING(src.RESULTEDTEST_CD_SYS_NM, 1, 100)
          ,[RESULTEDTEST_VAL_CD] = SUBSTRING(src.RESULTEDTEST_VAL_CD, 1, 20)
          ,[RESULTEDTEST_VAL_CD_DESC] = SUBSTRING(src.RESULTEDTEST_VAL_CD_DESC, 1, 1000)
          ,[NUMERIC_RESULT_WITHUNITS] = SUBSTRING(src.NUMERIC_RESULT_WITHUNITS, 1, 50)
          ,[LAB_RESULT_TXT_VAL] = SUBSTRING(RTRIM(src.LAB_RESULT_TXT_VAL), 1, 2000)
          ,[LAB_RESULT_COMMENTS] = SUBSTRING(RTRIM(src.LAB_RESULT_COMMENTS), 1, 2000)
          ,[RESULT_REF_RANGE_FRM] = SUBSTRING(src.RESULT_REF_RANGE_FRM, 1, 20)
          ,[RESULT_REF_RANGE_TO] = SUBSTRING(src.RESULT_REF_RANGE_TO, 1, 20)
          ,[ALT_LAB_TEST_CD] = SUBSTRING(src.ALT_LAB_TEST_CD, 1, 50)
          ,[ALT_LAB_TEST_CD_DESC] = SUBSTRING(src.ALT_LAB_TEST_CD_DESC, 1, 1000)
          ,[ALT_LAB_TEST_CD_SYS_CD] = SUBSTRING(src.ALT_LAB_TEST_CD_SYS_CD, 1, 50)
          ,[ALT_LAB_TEST_CD_SYS_NM] = SUBSTRING(src.ALT_LAB_TEST_CD_SYS_NM, 1, 100)
          ,[PATIENT_KEY] = src.[PATIENT_KEY]
          ,[DOCUMENT_LINK] = src.[DOCUMENT_LINK]
          ,[ACCESSION_NBR] = SUBSTRING(src.ACCESSION_NBR, 1, 199)
          ,[JURISDICTION_CD] = SUBSTRING(src.JURISDICTION_CD, 1, 20)
          ,[JURISDICTION_NM] = SUBSTRING(src.JURISDICTION_NM, 1, 32)
          ,[ORDERING_FACILITY] = SUBSTRING(src.ORDERING_FACILITY, 1, 100)
          ,[REPORTING_FACILITY] = SUBSTRING(src.REPORTING_FACILITY, 1, 100)
          ,[LAB_TEST_STATUS] = SUBSTRING(src.LAB_TEST_STATUS, 1, 50)
          ,[ELR_IND] = SUBSTRING(src.ELR_IND, 1, 1)
          ,[ORDERED_LAB_TEST_CD] = SUBSTRING(src.ORDERED_LAB_TEST_CD, 1, 50)
          ,[ORDERED_LAB_TEST_CD_DESC] = SUBSTRING(src.ORDERED_LAB_TEST_CD_DESC, 1, 1000)
          ,[ORDERED_LABTEST_CD_SYS_NM] = SUBSTRING(src.ORDERED_LABTEST_CD_SYS_NM, 1, 100)
          ,[CONDITION_CD] = SUBSTRING(src.CONDITION_CD, 1, 72)
          ,[CONDITION_SHORT_NM] = SUBSTRING(src.CONDITION_SHORT_NM, 1, 50)
          ,[PROGRAM_AREA_CD] = SUBSTRING(src.PROG_AREA_CD, 1, 20)
          ,[PROGRAM_AREA_DESC] = SUBSTRING(src.PROG_AREA_DESC_TXT, 1, 33)
          ,[SPECIMEN_COLLECTION_DT] = src.[SPECIMEN_COLLECTION_DT]
          ,[SPECIMEN_SRC_DESC] = SUBSTRING(src.SPECIMEN_SRC_DESC, 1, 100)
          ,[SPECIMEN_SRC_CD] = SUBSTRING(src.SPECIMEN_SRC_CD, 1, 50)
          ,[LAB_TEST_DT] = src.[LAB_TEST_DT]
          ,[LAB_RPT_CREATED_DT] = src.[LAB_RPT_CREATED_DT]
          ,[LAB_RPT_LAST_UPDATE_DT] = src.[LAB_RPT_LAST_UPDATE_DT]
          ,[LAB_RPT_RECEIVED_BY_PH_DT] = src.[LAB_RPT_RECEIVED_BY_PH_DT]
          ,[LAB_RPT_STATUS] = SUBSTRING(src.LAB_RPT_STATUS, 1, 50)
          ,[REASON_FOR_TEST_DESC] = SUBSTRING(src.REASON_FOR_TEST_DESC, 1, 4000)
          ,[PERSON_LOCAL_ID] = SUBSTRING(src.PERSON_LOCAL_ID, 1, 50)
          ,[PERSON_FIRST_NM] = SUBSTRING(src.PERSON_FIRST_NM, 1, 50)
          ,[PERSON_MIDDLE_NM] = SUBSTRING(src.PERSON_MIDDLE_NM, 1, 50)
          ,[PERSON_LAST_NM] = SUBSTRING(src.PERSON_LAST_NM, 1, 50)
          ,[PERSON_DOB] = src.[PERSON_DOB]
          ,[AGE_REPORTED] = src.[AGE_REPORTED]
          ,[PATIENT_REPORTED_AGE_UNITS] = SUBSTRING(RTRIM(src.PATIENT_REPORTED_AGE_UNITS), 1, 20)
          ,[PERSON_CURR_GENDER] = SUBSTRING(src.PERSON_CURR_GENDER, 1, 1)
          ,[PATIENT_ADDRESS] = SUBSTRING(src.PATIENT_ADDRESS, 1, 725)
          ,[ADDR_USE_CD_DESC] = SUBSTRING(src.ADDR_USE_CD_DESC, 1, 1000)
          ,[ADDR_CD_DESC] = SUBSTRING(src.ADDR_CD_DESC, 1, 1000)
          ,[PATIENT_CITY] = SUBSTRING(RTRIM(src.PATIENT_CITY), 1, 50)
          ,[PATIENT_COUNTY] = SUBSTRING(src.PATIENT_COUNTY, 1, 50)
          ,[PATIENT_STATE] = SUBSTRING(src.PATIENT_STATE, 1, 50)
          ,[PATIENT_ZIP_CODE] = SUBSTRING(src.PATIENT_ZIP_CODE, 1, 20)
          ,[ADDRESS_DATE] = NULL
          ,[ORDERING_PROVIDER_NM] = RTRIM(LTRIM(SUBSTRING(src.ORDERING_PROVIDER_NM, 1, 50)))
          ,[PROVIDER_ADDRESS] = SUBSTRING(src.PROVIDER_ADDRESS, 1, 725)
          ,[PRV_ADDR_USE_CD_DESC] = SUBSTRING(src.PRV_ADDR_USE_CD_DESC, 1, 1000)
          ,[PRV_ADDR_CD_DESC] = SUBSTRING(src.PRV_ADDR_CD_DESC, 1, 1000)
          ,[PROVIDER_PHONE] = SUBSTRING(src.PROVIDER_PHONE, 1, 50)
          ,[MORB_RPT_KEY] = src.[MORB_RPT_KEY]
          ,[LDF_GROUP_KEY] = src.[LDF_GROUP_KEY]
          ,[INVESTIGATION_KEYS] = SUBSTRING(src.INVESTIGATION_KEYS, 1, 1000)
          ,[EVENT_DATE] = COALESCE(src.SPECIMEN_COLLECTION_DT, src.LAB_TEST_DT, src.LAB_RPT_RECEIVED_BY_PH_DT, src.LAB_RPT_CREATED_DT)
          ,[REPORTING_FACILITY_UID] = src.REPORTING_FACILITY_UID
          ,[RDB_LAST_REFRESH_TIME] = CURRENT_TIMESTAMP
        FROM
            dbo.LAB100 tgt INNER JOIN (SELECT * FROM #TMP_LABTESTS4 WHERE LAB_RPT_LOCAL_ID IS NOT NULL) src
                                      ON src.RESULTED_LAB_TEST_KEY = tgt.RESULTED_LAB_TEST_KEY;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        -- Insert LAB100 rows for lab tests that don't yet exist in the
        -- table.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'GENERATING LAB100 Table - Insert';

        INSERT INTO dbo.[LAB100] (
             [LAB_RPT_LOCAL_ID], [RESULTED_LAB_TEST_CD], [PROGRAM_JURISDICTION_OID], [RECORD_STATUS_CD],
             [RESULTED_LAB_TEST_CD_DESC], [RESULTEDTEST_CD_SYS_NM], [RESULTEDTEST_VAL_CD], [RESULTEDTEST_VAL_CD_DESC],
             [NUMERIC_RESULT_WITHUNITS], [LAB_RESULT_TXT_VAL], [LAB_RESULT_COMMENTS], [RESULT_REF_RANGE_FRM],
             [RESULT_REF_RANGE_TO], [ALT_LAB_TEST_CD], [ALT_LAB_TEST_CD_DESC], [ALT_LAB_TEST_CD_SYS_CD],
             [ALT_LAB_TEST_CD_SYS_NM], [PATIENT_KEY], [DOCUMENT_LINK], [ACCESSION_NBR], [JURISDICTION_CD],
             [JURISDICTION_NM], [ORDERING_FACILITY], [REPORTING_FACILITY], [LAB_TEST_STATUS], [ELR_IND],
             [ORDERED_LAB_TEST_CD], [ORDERED_LAB_TEST_CD_DESC], [ORDERED_LABTEST_CD_SYS_NM], [CONDITION_CD],
             [CONDITION_SHORT_NM], [PROGRAM_AREA_CD], [PROGRAM_AREA_DESC], [SPECIMEN_COLLECTION_DT],
             [SPECIMEN_SRC_DESC], [SPECIMEN_SRC_CD], [LAB_TEST_DT], [LAB_RPT_CREATED_DT], [LAB_RPT_LAST_UPDATE_DT],
             [LAB_RPT_RECEIVED_BY_PH_DT], [LAB_RPT_STATUS], [REASON_FOR_TEST_DESC], [PERSON_LOCAL_ID],
             [PERSON_FIRST_NM], [PERSON_MIDDLE_NM], [PERSON_LAST_NM], [PERSON_DOB], [AGE_REPORTED],
             [PATIENT_REPORTED_AGE_UNITS], [PERSON_CURR_GENDER], [PATIENT_ADDRESS], [ADDR_USE_CD_DESC],
             [ADDR_CD_DESC], [PATIENT_CITY], [PATIENT_COUNTY], [PATIENT_STATE], [PATIENT_ZIP_CODE], [ADDRESS_DATE],
             [ORDERING_PROVIDER_NM], [PROVIDER_ADDRESS], [PRV_ADDR_USE_CD_DESC], [PRV_ADDR_CD_DESC],
             [PROVIDER_PHONE], [RESULTED_LAB_TEST_KEY], [MORB_RPT_KEY], [LDF_GROUP_KEY], [INVESTIGATION_KEYS],
             [EVENT_DATE], [REPORTING_FACILITY_UID], [RDB_LAST_REFRESH_TIME]
        )
        SELECT
            DISTINCT
            src.[LAB_RPT_LOCAL_ID], SUBSTRING(src.RESULTED_LAB_TEST_CD, 1, 50), src.oid,
            SUBSTRING(src.RECORD_STATUS_CD, 1, 8), SUBSTRING(RTRIM(src.RESULTED_LAB_TEST_CD_DESC), 1, 1000),
            SUBSTRING(src.RESULTEDTEST_CD_SYS_NM, 1, 100), SUBSTRING(src.RESULTEDTEST_VAL_CD, 1, 20),
            SUBSTRING(src.RESULTEDTEST_VAL_CD_DESC, 1, 1000), SUBSTRING(src.NUMERIC_RESULT_WITHUNITS, 1, 50),
            SUBSTRING(RTRIM(src.LAB_RESULT_TXT_VAL), 1, 2000), SUBSTRING(RTRIM(src.LAB_RESULT_COMMENTS), 1, 2000),
            SUBSTRING(src.RESULT_REF_RANGE_FRM, 1, 20), SUBSTRING(src.RESULT_REF_RANGE_TO, 1, 20),
            SUBSTRING(src.ALT_LAB_TEST_CD, 1, 50), SUBSTRING(src.ALT_LAB_TEST_CD_DESC, 1, 1000),
            SUBSTRING(src.ALT_LAB_TEST_CD_SYS_CD, 1, 50), SUBSTRING(src.ALT_LAB_TEST_CD_SYS_NM, 1, 100),
            src.PATIENT_KEY, src.DOCUMENT_LINK, SUBSTRING(src.ACCESSION_NBR, 1, 199),
            SUBSTRING(src.JURISDICTION_CD, 1, 20), SUBSTRING(src.JURISDICTION_NM, 1, 32),
            SUBSTRING(src.ORDERING_FACILITY, 1, 100), SUBSTRING(src.REPORTING_FACILITY, 1, 100),
            SUBSTRING(src.LAB_TEST_STATUS, 1, 50), SUBSTRING(src.ELR_IND, 1, 1),
            SUBSTRING(src.ORDERED_LAB_TEST_CD, 1, 50), SUBSTRING(src.ORDERED_LAB_TEST_CD_DESC, 1, 1000),
            SUBSTRING(src.ORDERED_LABTEST_CD_SYS_NM, 1, 100), SUBSTRING(src.CONDITION_CD, 1, 72),
            SUBSTRING(src.CONDITION_SHORT_NM, 1, 50), SUBSTRING(src.PROG_AREA_CD, 1, 20),
            SUBSTRING(src.PROG_AREA_DESC_TXT, 1, 33), src.SPECIMEN_COLLECTION_DT,
            SUBSTRING(src.SPECIMEN_SRC_DESC, 1, 100), SUBSTRING(src.SPECIMEN_SRC_CD, 1, 50), src.LAB_TEST_DT,
            src.LAB_RPT_CREATED_DT, src.LAB_RPT_LAST_UPDATE_DT, src.LAB_RPT_RECEIVED_BY_PH_DT,
            SUBSTRING(src.LAB_RPT_STATUS, 1, 50), SUBSTRING(src.REASON_FOR_TEST_DESC, 1, 4000),
            SUBSTRING(src.PERSON_LOCAL_ID, 1, 50), SUBSTRING(src.PERSON_FIRST_NM, 1, 50),
            SUBSTRING(src.PERSON_MIDDLE_NM, 1, 50), SUBSTRING(src.PERSON_LAST_NM, 1, 50), src.PERSON_DOB,
            src.AGE_REPORTED, SUBSTRING(RTRIM(src.PATIENT_REPORTED_AGE_UNITS), 1, 20),
            SUBSTRING(src.PERSON_CURR_GENDER, 1, 1), SUBSTRING(src.PATIENT_ADDRESS, 1, 725),
            SUBSTRING(src.ADDR_USE_CD_DESC, 1, 1000), SUBSTRING(src.ADDR_CD_DESC, 1, 1000),
            SUBSTRING(RTRIM(src.PATIENT_CITY), 1, 50), SUBSTRING(src.PATIENT_COUNTY, 1, 50),
            SUBSTRING(src.PATIENT_STATE, 1, 50), SUBSTRING(src.PATIENT_ZIP_CODE, 1, 20),
            NULL AS [ADDRESS_DATE], RTRIM(LTRIM(SUBSTRING(src.ORDERING_PROVIDER_NM, 1, 50))),
            SUBSTRING(src.PROVIDER_ADDRESS, 1, 725), SUBSTRING(src.PRV_ADDR_USE_CD_DESC, 1, 1000),
            SUBSTRING(src.PRV_ADDR_CD_DESC, 1, 1000), SUBSTRING(src.PROVIDER_PHONE, 1, 50),
            src.RESULTED_LAB_TEST_KEY, src.MORB_RPT_KEY, src.LDF_GROUP_KEY,
            SUBSTRING(src.INVESTIGATION_KEYS, 1, 1000),
            COALESCE(src.SPECIMEN_COLLECTION_DT, src.LAB_TEST_DT, src.LAB_RPT_RECEIVED_BY_PH_DT, src.LAB_RPT_CREATED_DT) AS [EVENT_DATE],
            src.REPORTING_FACILITY_UID,
            CURRENT_TIMESTAMP AS [RDB_LAST_REFRESH_TIME]
        FROM
            #TMP_LABTESTS4 src
                LEFT JOIN dbo.LAB100 tgt ON src.RESULTED_LAB_TEST_KEY = tgt.RESULTED_LAB_TEST_KEY
        WHERE src.LAB_RPT_LOCAL_ID IS NOT NULL AND tgt.RESULTED_LAB_TEST_KEY IS NULL;

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        COMMIT TRANSACTION;

        -- =================================================================
        -- The two reconciliation steps below are NOT scoped to
        -- @labtestuids: they detect orders that became inactive, or
        -- LAB_TEST rows that were removed entirely, anywhere in the
        -- source system, and therefore run independently of the current
        -- batch's size.
        -- =================================================================
        BEGIN TRANSACTION;

        -- Mark LAB100 rows INACTIVE when their parent order has since been
        -- marked INACTIVE in LAB_TEST.
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'Update Inactive LAB100 Records';

        UPDATE l
        SET record_status_cd = 'INACTIVE'
        FROM dbo.LAB100 l
        WHERE
            RESULTED_LAB_TEST_KEY IN (
                SELECT
                    l.RESULTED_LAB_TEST_KEY
                FROM dbo.LAB_TEST lt
                    INNER JOIN dbo.LAB100 l ON l.RESULTED_LAB_TEST_KEY = lt.LAB_TEST_KEY
                WHERE
                    ROOT_ORDERED_TEST_PNTR IN (
                        SELECT ROOT_ORDERED_TEST_PNTR
                        FROM dbo.LAB_TEST ltr
                        WHERE LAB_TEST_TYPE = 'Order'
                          AND record_status_cd = 'INACTIVE'
                    )
                    AND l.record_status_cd <> 'INACTIVE'
            );

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        -- Remove LAB100 rows whose underlying LAB_TEST row no longer
        -- exists at all (true orphans, not just inactive ones).
        SET @ProcStepNo += 1;
        SET @ProcStepName = 'DELETE REMOVED OBSERVATIONS FROM LAB100';

        DELETE FROM dbo.LAB100
        WHERE RESULTED_LAB_TEST_KEY IN (
            SELECT DISTINCT l.RESULTED_LAB_TEST_KEY
            FROM dbo.LAB100 l
            EXCEPT
            SELECT lt.LAB_TEST_KEY
            FROM dbo.LAB_TEST lt
        );

        SELECT @RowCountNo = @@ROWCOUNT;
        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'START', @ProcStepNo, @ProcStepName, @RowCountNo);

        COMMIT TRANSACTION;

        -- Log batch completion and return an empty success result set.
        SET @ProcStepNo = 999;
        SET @ProcStepName = 'SP_COMPLETE';

        INSERT INTO dbo.JOB_FLOW_LOG
            (BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, ROW_COUNT)
        VALUES
            (@BatchId, @DataflowName, @DataflowName, 'COMPLETE', @ProcStepNo, @ProcStepName, @RowCountNo);

        SELECT
            CAST(NULL AS BIGINT) AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            CAST(NULL AS VARCHAR(30)) AS datamart,
            CAST(NULL AS VARCHAR(50)) AS condition_cd,
            CAST(NULL AS VARCHAR(200)) AS stored_procedure,
            CAST(NULL AS VARCHAR(50)) AS investigation_form_cd
        WHERE 1 = 0;

    END TRY

    BEGIN CATCH

        -- Roll back any open transaction, log full error detail to
        -- JOB_FLOW_LOG, and return an error result row to the caller.
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: '   + CAST(ERROR_NUMBER()   AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: '    + CAST(ERROR_STATE()    AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: '     + CAST(ERROR_LINE()     AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: '  + ERROR_MESSAGE();

        INSERT INTO dbo.JOB_FLOW_LOG (
            BATCH_ID, DATAFLOW_NAME, PACKAGE_NAME, STATUS_TYPE, STEP_NUMBER, STEP_NAME, Error_Description, ROW_COUNT
        )
        VALUES (
            @BatchId, @DataflowName, @DataflowName, 'ERROR', @ProcStepNo, @ProcStepName, @FullErrorMessage, 0
        );

        SELECT
            0 AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            'Error' AS datamart,
            CAST(NULL AS VARCHAR(50)) AS condition_cd,
            @FullErrorMessage AS stored_procedure,
            CAST(NULL AS VARCHAR(50)) AS investigation_form_cd;

    END CATCH

END;
GO
