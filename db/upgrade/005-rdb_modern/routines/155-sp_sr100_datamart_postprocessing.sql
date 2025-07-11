IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_sr100_datamart_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_sr100_datamart_postprocessing]
END
GO 

CREATE PROCEDURE dbo.sp_sr100_datamart_postprocessing(
    @id_list nvarchar(MAX),
    @debug bit = 'false')
AS
BEGIN
    BEGIN TRY
        DECLARE @RowCount_no INT;
        DECLARE @Proc_Step_no FLOAT = 0;
        DECLARE @Proc_Step_Name VARCHAR(200) = '';
        DECLARE @batch_id bigint;
        SET @batch_id = cast((format(getdate(), 'yyMMddHHmmssffff')) as bigint);
        DECLARE @Dataflow_Name VARCHAR(200) = 'SR100 Post-Processing Event';
        DECLARE @Package_Name VARCHAR(200) = 'sp_sr100_datamart_postprocessing';

        if @debug = 'true' print @batch_id;

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';

        SELECT @ROWCOUNT_NO = 0;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT],
         [Msg_Description1])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO,
                LEFT(@id_list, 500));

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #temp_sr100';

        SELECT src.INVESTIGATION_KEY     AS INVESTIGATION_KEY,
               I.inv_local_id            AS LOCAL_ID,
               I.CASE_RPT_MMWR_WK        AS MMWRWK,
               I.CASE_RPT_MMWR_YR        AS MMWRYR,
               src.SUM_RPT_CASE_COUNT    AS NBR_CASES,
               c.CONDITION_CD            AS CONDITION_CD,
               c.CONDITION_DESC          AS CONDITION,
               SRC.COUNTY_CD             AS COUNTY_CD,
               sccv.code_desc_txt        AS COUNTY_NAME,
               SRC.state_CD              AS STATE_CD,
               CASE
                   WHEN LTRIM(RTRIM(scg.SUMMARY_CASE_SRC_TXT)) = '' OR scg.SUMMARY_CASE_SRC_TXT IS NULL THEN 'N/A'
                   WHEN LEN(LTRIM(RTRIM(scg.SUMMARY_CASE_SRC_TXT))) > 1 THEN scg.SUMMARY_CASE_SRC_TXT
                   END         AS RPT_SOURCE,
               CASE
                   WHEN LTRIM(RTRIM(cvg.code_desc)) = '' OR cvg.code_desc IS NULL THEN 'No Source Selected'
                   WHEN LEN(LTRIM(RTRIM(cvg.code_desc))) > 1 THEN cvg.code_desc
                   END         AS RPT_SOURCE_DESC,
               rd1.DATE_MM_DD_YYYY       AS DATE_REPORTED,
               rd1.CLNDR_MON_NAME        AS MONTH_REPORTED,
               rd.DATE_MM_DD_YYYY        AS NOTIF_CREATE_DATE,
               rd.CLNDR_MON_NAME         AS NOTIF_CREATE_MONTH,
               rd.CLNDR_YR               AS NOTIF_CREATE_YEAR,
               src.SUM_RPT_CASE_COMMENTS AS REPORT_COMMENTS,
               em.ADD_TIME               AS DATE_ADDED,
               em.ADD_USER_NAME          AS ADD_USER_NAME
        INTO #temp_sr100
        FROM dbo.SUMMARY_REPORT_CASE SRC with (nolock)
                 INNER JOIN dbo.INVESTIGATION I with (nolock)
                            ON src.INVESTIGATION_KEY = I.INVESTIGATION_KEY
                 LEFT OUTER JOIN dbo.SUMMARY_CASE_GROUP SCG with (nolock)
                                 ON src.summary_case_src_key = scg.summary_case_src_key
                 LEFT OUTER JOIN dbo.v_code_value_general CVG
                                 ON scg.SUMMARY_CASE_SRC_TXT = cvg.code_val
                                     and cvg.cd = 'SUM103'
                 LEFT OUTER JOIN dbo.RDB_DATE RD with (nolock)
                                 ON rd.date_key = src.NOTIFICATION_SEND_DT_KEY
                 LEFT OUTER JOIN dbo.RDB_DATE RD1 with (nolock)
                                 ON rd1.DATE_MM_DD_YYYY = I.EARLIEST_RPT_TO_STATE_DT
                 INNER JOIN dbo.condition c with (nolock)
                            ON c.CONDITION_KEY = src.CONDITION_KEY
                 LEFT OUTER JOIN dbo.CASE_COUNT cc with (nolock)
                                 ON cc.INVESTIGATION_KEY = I.INVESTIGATION_KEY
                 INNER JOIN dbo.nrt_srte_state_county_code_value sccv
                            ON SRC.county_cd = sccv.code
                 INNER JOIN dbo.EVENT_METRIC em with (nolock)
                            ON em.local_id = I.inv_local_id
        WHERE I.CASE_UID IN (select value FROM STRING_SPLIT(@id_list, ','))
        ORDER BY I.inv_local_id asc;

        IF @debug = 'true' SELECT * from #temp_sr100;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'Update SR100';


        UPDATE dbo.SR100
        SET LOCAL_ID           = t.LOCAL_ID,
            MMWRWK             = t.MMWRWK,
            MMWRYR             = t.MMWRYR,
            NBR_CASES          = t.NBR_CASES,
            CONDITION_CD       = t.CONDITION_CD,
            [CONDITION]        = t.CONDITION,
            COUNTY_CD          = t.COUNTY_CD,
            COUNTY_NAME        = t.COUNTY_NAME,
            STATE_CD           = t.STATE_CD,
            RPT_SOURCE         = t.RPT_SOURCE,
            RPT_SOURCE_DESC    = t.RPT_SOURCE_DESC,
            DATE_REPORTED      = t.DATE_REPORTED,
            MONTH_REPORTED     = t.MONTH_REPORTED,
            NOTIF_CREATE_DATE  = t.NOTIF_CREATE_DATE,
            NOTIF_CREATE_MONTH = t.NOTIF_CREATE_MONTH,
            NOTIF_CREATE_YEAR  = t.NOTIF_CREATE_YEAR,
            REPORT_COMMENTS    = t.REPORT_COMMENTS,
            DATE_ADDED         = t.DATE_ADDED,
            ADD_USER_NAME      = t.ADD_USER_NAME,
            INVESTIGATION_KEY  = t.INVESTIGATION_KEY
        FROM #temp_sr100 t
                 INNER JOIN dbo.SR100 s with (nolock) ON
            t.INVESTIGATION_KEY = s.INVESTIGATION_KEY;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'Insert into SR100';


        INSERT INTO dbo.SR100
        (LOCAL_ID,
         MMWRWK,
         MMWRYR,
         NBR_CASES,
         CONDITION_CD,
         [CONDITION],
         COUNTY_CD,
         COUNTY_NAME,
         STATE_CD,
         RPT_SOURCE,
         RPT_SOURCE_DESC,
         DATE_REPORTED,
         MONTH_REPORTED,
         NOTIF_CREATE_DATE,
         NOTIF_CREATE_MONTH,
         NOTIF_CREATE_YEAR,
         REPORT_COMMENTS,
         DATE_ADDED,
         ADD_USER_NAME,
         INVESTIGATION_KEY)
        SELECT t.LOCAL_ID,
               t.MMWRWK,
               t.MMWRYR,
               t.NBR_CASES,
               t.CONDITION_CD,
               t.CONDITION,
               t.COUNTY_CD,
               t.COUNTY_NAME,
               t.STATE_CD,
               t.RPT_SOURCE,
               t.RPT_SOURCE_DESC,
               t.DATE_REPORTED,
               t.MONTH_REPORTED,
               t.NOTIF_CREATE_DATE,
               t.NOTIF_CREATE_MONTH,
               t.NOTIF_CREATE_YEAR,
               t.REPORT_COMMENTS,
               t.DATE_ADDED,
               t.ADD_USER_NAME,
               t.INVESTIGATION_KEY
        FROM #temp_sr100 t
                 LEFT JOIN dbo.SR100 s with (nolock) ON
            t.INVESTIGATION_KEY = s.INVESTIGATION_KEY
        WHERE s.INVESTIGATION_KEY is null;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, 'COMPLETE', 0);

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) +
            CHAR(10) + -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [Error_Description]
                                         , [row_count])
        VALUES ( @batch_id
               , @Dataflow_Name
               , @Package_Name
               , 'ERROR'
               , @Proc_Step_no
               , @Proc_Step_name
               , @FullErrorMessage
               , 0);

        RETURN -1;

    END CATCH
END;