CREATE OR ALTER PROCEDURE dbo.sp_summary_report_case_postprocessing(
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
        DECLARE @Dataflow_Name VARCHAR(200) = 'SUMMARY_REPORT_CASE Post-Processing Event';
        DECLARE @Package_Name VARCHAR(200) = 'sp_summary_report_case_postprocessing';

        if @debug = 'true' print @batch_id;

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';
        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT],[Msg_Description1])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO, LEFT(@id_list, 500));


        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'Generating #tmp_SumRptWork';

        ;
        WITH SumRptWork AS (SELECT nio.public_health_case_uid
                                 , nio.observation_id
                                 , nio.root_type_cd
                                 , nio.branch_id
                                 , nio.branch_type_cd
                                 , ni.cd as condition_cd
                                 , no2.cd
                                 , no2.batch_id --For obs child table validation. Not needed for numeric.
                                 , ni.rpt_cnty_cd
                                 , sccv.parent_is_cd as state_cd
                                 , sccv.code_desc_txt as county_name
                                 , ni.last_chg_time
                            FROM dbo.nrt_investigation ni
                                     INNER JOIN dbo.nrt_investigation_observation nio with (nolock)
                                                ON ni.public_health_case_uid = nio.public_health_case_uid
                                                    AND isnull(ni.batch_id, 1) = isnull(nio.batch_id, 1)
                                     LEFT JOIN dbo.nrt_observation no2 with (nolock)
                                               ON no2.observation_uid = nio.branch_id
                                     LEFT JOIN dbo.nrt_srte_state_county_code_value sccv WITH (NOLOCK)
                                               ON ni.rpt_cnty_cd = sccv.code
                            WHERE ni.public_health_case_uid in (select value FROM STRING_SPLIT(@id_list, ','))
                              AND nio.root_type_cd IN ('SummaryForm','SummaryNotification')
                              AND ni.case_type_cd = 'S'
        ),
             compileSumRptWork AS (SELECT sr.public_health_case_uid,
                                          sr.rpt_cnty_cd,
                                          sr.county_name,
                                          sr.state_cd,
                                          sr.condition_cd,
                                          sr.last_chg_time,
                                          isnull(ROUND(ovn_numeric_value_1, 0), 0)                        AS SUM_RPT_CASE_COUNT,
                                          REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13), ''), CHAR(10), '') AS SUM_RPT_CASE_COMMENTS,
                                          nio.notif_status                                                AS SUM_RPT_CASE_STATUS,
                                          nio.RPT_SENT_TIME                                               AS NOTIFICATION_SEND_DT,
                                          nio.notif_last_chg_time                                         AS NOTI_LAST_CHG_TIME,
                                          ovc.ovc_code                                                    AS SUMMARY_CASE_SRC_TXT,
                                          ovc.observation_uid                AS ovc_observation_uid
                                   FROM SumRptWork sr
                                            LEFT JOIN dbo.nrt_observation_numeric ovn with (nolock)
                                                      on sr.branch_id = ovn.observation_uid 
                                                      AND isnull(sr.batch_id, 1) = isnull(ovn.batch_id, 1) AND
                                                         sr.cd = 'SUM104'
                                            LEFT JOIN dbo.nrt_observation_txt ovt with (nolock)
                                                      ON sr.branch_id = ovt.observation_uid
                                                          AND isnull(sr.batch_id, 1) = isnull(ovt.batch_id, 1) AND
                                                         sr.CD = 'SUM105'
                                            LEFT JOIN dbo.nrt_investigation_notification nio with (nolock)
                                                      on sr.observation_id = nio.notification_uid
                                            LEFT JOIN dbo.nrt_observation_coded ovc with (nolock)
                                                      on sr.branch_id = ovc.observation_uid
                                                          AND sr.cd = 'SUM103')
        SELECT public_health_case_uid,
               max(last_chg_time)         AS LAST_CHG_TIME,
               max(rpt_cnty_cd)       AS COUNTY_CD,
               max(county_name)       AS COUNTY_NAME,
               max(state_cd)     AS STATE_CD,
               max(SUM_RPT_CASE_COUNT)    AS SUM_RPT_CASE_COUNT,
               max(SUM_RPT_CASE_COMMENTS) AS SUM_RPT_CASE_COMMENTS,
               max(SUM_RPT_CASE_STATUS)   AS SUM_RPT_CASE_STATUS,
               max(NOTIFICATION_SEND_DT)  AS NOTIFICATION_SEND_DT,
               max(NOTI_LAST_CHG_TIME)    AS NOTI_LAST_CHG_TIME,
               max(condition_cd)          AS CONDITION_CD,
               max(SUMMARY_CASE_SRC_TXT)  AS SUMMARY_CASE_SRC_TXT,
               max(ovc_observation_uid)   AS ovc_observation_uid
        INTO #tmp_SumRptWork
        FROM compileSumRptWork comp
        GROUP BY public_health_case_uid;

        if @debug = 'true' select @PROC_STEP_NAME as step, * from #tmp_SumRptWork;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'Generating SUMMARY_CASE_SRC_KEYS';


        SELECT src.SUMMARY_CASE_SRC_KEY,
               tmp.SUMMARY_CASE_SRC_TXT,
               tmp.public_health_case_uid,
               tmp.ovc_observation_uid
        INTO #tmp_CaseSrcKey
        FROM #tmp_SumRptWork tmp
                 INNER JOIN dbo.INVESTIGATION i with (nolock) ON i.case_uid = tmp.public_health_case_uid
                 LEFT JOIN dbo.SUMMARY_REPORT_CASE src with (nolock) ON i.investigation_key = src.investigation_key;

        if @debug = 'true' select @PROC_STEP_NAME as step, * from #tmp_CaseSrcKey;

        /*Create key if SUMMARY_CASE_SRC_TXT is not null.*/
        INSERT INTO dbo.nrt_summary_case_group_key(public_health_case_uid, ovc_observation_uid)
        SELECT DISTINCT tmp.public_health_case_uid, tmp.ovc_observation_uid
        FROM #tmp_CaseSrcKey tmp
                 LEFT join DBO.nrt_summary_case_group_key src ON src.ovc_observation_uid = tmp.ovc_observation_uid
        WHERE (tmp.SUMMARY_CASE_SRC_KEY IS NULL
            AND tmp.SUMMARY_CASE_SRC_TXT IS NOT NULL)
          AND (src.ovc_observation_uid IS NULL AND src.public_health_case_uid IS NULL);

        if @debug = 'true'
            select @PROC_STEP_NAME as step, *
            from dbo.nrt_summary_case_group_key
            where public_health_case_uid in (select value FROM STRING_SPLIT(@id_list, ','));

        /*Get keys*/
        select i.INVESTIGATION_KEY,
               tmp.SUM_RPT_CASE_COUNT,
               tmp.SUM_RPT_CASE_COMMENTS,
               tmp.SUM_RPT_CASE_STATUS,
               ISNULL(dt1.DATE_KEY,1)          AS NOTIFICATION_SEND_DT_KEY,
               tmp.COUNTY_CD,
               tmp.COUNTY_NAME,
               tmp.STATE_CD,
               c.CONDITION_KEY                      AS CONDITION_KEY,
               1                                    AS LDF_GROUP_KEY,
               dt2.DATE_KEY                         AS LAST_UPDATE_DT_KEY,
               ISNULL(skey.SUMMARY_CASE_SRC_KEY, 1) AS SUMMARY_CASE_SRC_KEY,
               tmp.SUMMARY_CASE_SRC_TXT
        into #temp_SUMMARY_REPORT_CASE
        FROM #tmp_SumRptWork tmp
                 INNER JOIN dbo.INVESTIGATION i with (nolock) ON i.case_uid = tmp.public_health_case_uid
                 LEFT JOIN dbo.nrt_summary_case_group_key skey ON skey.public_health_case_uid = i.case_uid
                 LEFT JOIN dbo.RDB_DATE dt1 with (nolock)
                           ON dt1.DATE_MM_DD_YYYY = CAST(tmp.NOTIFICATION_SEND_DT AS DATE)
                 LEFT JOIN dbo.v_condition_dim c with (nolock) ON c.CONDITION_CD = tmp.CONDITION_CD
                 LEFT JOIN dbo.RDB_DATE dt2 with (nolock) ON dt2.DATE_MM_DD_YYYY = CAST(tmp.LAST_CHG_TIME AS DATE);

        if @debug = 'true' select @PROC_STEP_NAME as step, * from #temp_SUMMARY_REPORT_CASE;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'UPDATE dbo.SUMMARY_CASE_GROUP';


        UPDATE dbo.SUMMARY_CASE_GROUP
        SET SUMMARY_CASE_SRC_TXT= tmp.SUMMARY_CASE_SRC_TXT
        FROM #temp_SUMMARY_REPORT_CASE tmp
                 INNER JOIN dbo.SUMMARY_CASE_GROUP scg
                            ON scg.SUMMARY_CASE_SRC_KEY = tmp.SUMMARY_CASE_SRC_KEY
        WHERE tmp.SUMMARY_CASE_SRC_KEY IS NOT NULL;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'INSERT INTO dbo.SUMMARY_CASE_GROUP';


        INSERT INTO dbo.SUMMARY_CASE_GROUP
        (SUMMARY_CASE_SRC_KEY, SUMMARY_CASE_SRC_TXT)
        SELECT tmp.SUMMARY_CASE_SRC_KEY,
               tmp.SUMMARY_CASE_SRC_TXT
        FROM #temp_SUMMARY_REPORT_CASE tmp
                 LEFT JOIN dbo.SUMMARY_CASE_GROUP scg on scg.SUMMARY_CASE_SRC_KEY = tmp.SUMMARY_CASE_SRC_KEY
        WHERE tmp.SUMMARY_CASE_SRC_KEY <> 1
          AND scg.SUMMARY_CASE_SRC_KEY IS NULL
        ORDER BY tmp.SUMMARY_CASE_SRC_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);
        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'UPDATE dbo.SUMMARY_REPORT_CASE';


        UPDATE dbo.SUMMARY_REPORT_CASE
        SET SUM_RPT_CASE_COUNT=tmp.SUM_RPT_CASE_COUNT,
            SUM_RPT_CASE_COMMENTS=tmp.SUM_RPT_CASE_COMMENTS,
            INVESTIGATION_KEY=tmp.INVESTIGATION_KEY,
            SUM_RPT_CASE_STATUS=tmp.SUM_RPT_CASE_STATUS,
            SUMMARY_CASE_SRC_KEY=tmp.SUMMARY_CASE_SRC_KEY,
            NOTIFICATION_SEND_DT_KEY=tmp.NOTIFICATION_SEND_DT_KEY,
            COUNTY_CD=tmp.COUNTY_CD,
            COUNTY_NAME=tmp.COUNTY_NAME,
            STATE_CD=tmp.STATE_CD,
            CONDITION_KEY=tmp.CONDITION_KEY,
            LDF_GROUP_KEY=tmp.LDF_GROUP_KEY,
            LAST_UPDATE_DT_KEY=tmp.LAST_UPDATE_DT_KEY
        FROM #temp_SUMMARY_REPORT_CASE tmp
                 INNER JOIN dbo.SUMMARY_REPORT_CASE src ON src.INVESTIGATION_KEY = tmp.INVESTIGATION_KEY
        WHERE tmp.INVESTIGATION_KEY IS NOT NULL;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'INSERT INTO dbo.SUMMARY_REPORT_CASE';


        INSERT INTO dbo.SUMMARY_REPORT_CASE
        (SUM_RPT_CASE_COUNT,
         SUM_RPT_CASE_COMMENTS,
         INVESTIGATION_KEY,
         SUM_RPT_CASE_STATUS,
         SUMMARY_CASE_SRC_KEY,
         NOTIFICATION_SEND_DT_KEY,
         COUNTY_CD,
         COUNTY_NAME,
         STATE_CD,
         CONDITION_KEY,
         LDF_GROUP_KEY,
         LAST_UPDATE_DT_KEY)
        SELECT tmp.SUM_RPT_CASE_COUNT,
               tmp.SUM_RPT_CASE_COMMENTS,
               tmp.INVESTIGATION_KEY,
               tmp.SUM_RPT_CASE_STATUS,
               tmp.SUMMARY_CASE_SRC_KEY,
               tmp.NOTIFICATION_SEND_DT_KEY,
               tmp.COUNTY_CD,
               tmp.COUNTY_NAME,
               tmp.STATE_CD,
               tmp.CONDITION_KEY,
               tmp.LDF_GROUP_KEY,
               tmp.LAST_UPDATE_DT_KEY
        FROM #temp_SUMMARY_REPORT_CASE tmp
                 LEFT JOIN dbo.SUMMARY_REPORT_CASE src ON src.INVESTIGATION_KEY = tmp.INVESTIGATION_KEY
        WHERE src.INVESTIGATION_KEY IS NULL;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);
        COMMIT TRANSACTION;


        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [row_count])
        VALUES ( @batch_id
               , @Dataflow_Name
               , @Package_Name
               , 'COMPLETE'
               , 999
               , @Proc_Step_name
               , @RowCount_no);


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