CREATE OR ALTER PROCEDURE dbo.sp_aggregate_report_datamart_postprocessing(
    @id_list nvarchar(MAX),
    @debug bit = 'false')
AS
BEGIN
    BEGIN TRY

        DECLARE @RowCount_no INT;
        DECLARE @Proc_Step_no FLOAT = 0;
        DECLARE @Proc_Step_Name VARCHAR(200) = '';
        DECLARE @batch_id bigint;
        SET @batch_id = cast((format(getdate(), 'yyMMddHHmmss')) as bigint);
        DECLARE @Dataflow_Name VARCHAR(200) = 'AGGREGATE_REPORT_DATAMART Post-Processing Event';
        DECLARE @Package_Name VARCHAR(200) = 'sp_aggregate_report_datamart_postprocessing';

        DECLARE @tgt_table_nm VARCHAR(50) = 'AGGREGATE_REPORT_DATAMART';

        if @debug = 'true' print @batch_id;

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';
        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT],[Msg_Description1])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO, LEFT(@id_list, 500));


        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'Generating #AGG_DATA_NUM';

        SELECT act_uid,
               nbs_case_answer_uid,
               datamart_column_nm,
               IIF(agg.batch_id = inv.batch_id, CAST(answer_txt AS float), NULL) as response
        INTO #AGG_DATA_NUM
        FROM dbo.nrt_investigation_aggregate agg
        LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
            ON UPPER(isc.TABLE_NAME) = @tgt_table_nm AND UPPER(isc.COLUMN_NAME) = UPPER(datamart_column_nm)
        LEFT JOIN dbo.nrt_investigation inv with (nolock) ON inv.public_health_case_uid = agg.act_uid
            AND ISNULL(inv.batch_id, 1) = ISNULL(agg.batch_id, 1)
        WHERE agg.data_type = 'Numeric' AND (act_uid in (SELECT value FROM STRING_SPLIT(@id_list, ',')));

        if @debug = 'true' select @Proc_Step_Name as step, * from #AGG_DATA_NUM;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'Generating #AGG_DATA_CODED';

        SELECT act_uid,
               nbs_case_answer_uid,
               datamart_column_nm,
               IIF(agg.batch_id = inv.batch_id,
                   cvg.code_short_desc_txt,
                   NULL) as response
        INTO #AGG_DATA_CODED
        FROM dbo.nrt_investigation_aggregate agg
        LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
            ON UPPER(isc.TABLE_NAME) = @tgt_table_nm AND UPPER(isc.COLUMN_NAME) = UPPER(datamart_column_nm)
        JOIN dbo.nrt_srte_Codeset_Group_Metadata cgm with (nolock) ON cgm.code_set_group_id = agg.code_set_group_id
        JOIN dbo.nrt_srte_Code_value_general cvg with (nolock) ON cvg.code_set_nm = cgm.code_set_nm and cvg.code = agg.answer_txt
        LEFT JOIN dbo.nrt_investigation inv with (nolock) ON inv.public_health_case_uid = agg.act_uid
            AND ISNULL(inv.batch_id, 1) = ISNULL(agg.batch_id, 1)
        WHERE agg.data_type = 'Coded' AND (act_uid in (SELECT value FROM STRING_SPLIT(@id_list, ',')));

        if @debug = 'true' select @Proc_Step_Name as step, * from #AGG_DATA_CODED;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'Generating #AGG_EVENT';

        WITH phcBasic AS (
            SELECT inv.public_health_case_uid,
                inv.local_id,
                inv.rpt_cnty_cd,
                inv.add_time,
                inv.add_user_name,
                inv.last_chg_time,
                inv.last_chg_user_name,
                inv.cd_desc_txt as condition_desc,
                inv.txt as comments,
                inv.mmwr_year,
                inv.mmwr_week
            FROM dbo.nrt_investigation inv
            WHERE inv.public_health_case_uid IN (select value FROM STRING_SPLIT(@id_list, ','))
        ),
        aggEvent AS (
            SELECT
                phc.public_health_case_uid as act_uid,
                phc.local_id,
                sccv.code_desc_txt as REPORTING_COUNTY,
                phc.add_time,
                phc.add_user_name,
                phc.last_chg_time,
                phc.last_chg_user_name,
                phc.condition_desc,
                phc.comments,
                phc.mmwr_year,
                phc.mmwr_week,
                nte.NOTIFICATION_UPD_DT_KEY,
                ntf.NOTIFICATION_STATUS,
                ntf.NOTIFICATION_LOCAL_ID,
                ntf.NOTIFICATION_LAST_CHANGE_TIME
            FROM phcBasic phc
            LEFT JOIN dbo.INVESTIGATION inv with (nolock) ON inv.CASE_UID = phc.public_health_case_uid
            LEFT JOIN dbo.NOTIFICATION_EVENT nte with (nolock) ON nte.INVESTIGATION_KEY = inv.INVESTIGATION_KEY
            LEFT JOIN dbo.NOTIFICATION ntf with (nolock) ON ntf.NOTIFICATION_KEY = nte.NOTIFICATION_KEY
            LEFT JOIN dbo.nrt_srte_state_county_code_value sccv with (nolock) ON phc.rpt_cnty_cd = sccv.code
        )
        SELECT
            ae.act_uid,
            ae.REPORTING_COUNTY,
            ae.comments             AS COMMENTS,
            ae.local_id             AS REPORT_LOCAL_ID,
            ae.condition_desc       AS CONDITION_DESCRIPTION,
            ae.mmwr_year            AS MMWR_YEAR,
            ae.mmwr_week            AS MMWR_WEEK,
            ae.add_time             AS REPORT_CREATE_DATE,
            ae.last_chg_time        AS REPORT_LAST_UPDATE_DATE,
            ae.NOTIFICATION_UPD_DT_KEY,
            ae.NOTIFICATION_STATUS,
            ae.NOTIFICATION_LOCAL_ID,
            ae.NOTIFICATION_LAST_CHANGE_TIME,
            ae.add_user_name        AS USER_NM,
            ae.add_user_name        AS REPORT_CREATED_BY_USER,
            ae.last_chg_user_name   AS REPORT_LAST_UPDATED_BY_USER
        INTO #AGG_EVENT
        FROM aggEvent ae;

        if @debug = 'true' select @Proc_Step_Name as step, * from #AGG_EVENT;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        BEGIN TRANSACTION
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'UPDATE dbo.' + @tgt_table_nm;

        DECLARE @agg_num_columns NVARCHAR(MAX) = '';
        SELECT @agg_num_columns =
               COALESCE(STRING_AGG(CAST(QUOTENAME(datamart_column_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY datamart_column_nm),
                        '')
        FROM (SELECT DISTINCT datamart_column_nm FROM #AGG_DATA_NUM) AS cols;

        DECLARE @agg_coded_columns nvarchar(max) = '';
        SELECT @agg_coded_columns =
               COALESCE(STRING_AGG(CAST(QUOTENAME(datamart_column_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY datamart_column_nm),
                        '')
        FROM (SELECT DISTINCT datamart_column_nm FROM #AGG_DATA_CODED) AS cols;

        DECLARE @update_sql nvarchar(max) = '';

        DECLARE @select_phc_col_nm_response nvarchar(max) =
            'SELECT act_uid, datamart_column_nm, response';

        SET @update_sql ='
            UPDATE tgt
            SET REPORTING_COUNTY = src.REPORTING_COUNTY,
                COMMENTS = src.COMMENTS,
                REPORT_LOCAL_ID = src.REPORT_LOCAL_ID,
                CONDITION_DESCRIPTION = src.CONDITION_DESCRIPTION,
                MMWR_YEAR = src.MMWR_YEAR,
                MMWR_WEEK = src.MMWR_WEEK,
                REPORT_CREATE_DATE = src.REPORT_CREATE_DATE,
                REPORT_LAST_UPDATE_DATE = src.REPORT_LAST_UPDATE_DATE,
                NOTIFICATION_UPD_DT_KEY = src.NOTIFICATION_UPD_DT_KEY,
                NOTIFICATION_STATUS = src.NOTIFICATION_STATUS,
                NOTIFICATION_LOCAL_ID = src.NOTIFICATION_LOCAL_ID,
                NOTIFICATION_LAST_CHANGE_TIME = src.NOTIFICATION_LAST_CHANGE_TIME,
                USER_NM = src.USER_NM,
                REPORT_CREATED_BY_USER = src.REPORT_CREATED_BY_USER,
                REPORT_LAST_UPDATED_BY_USER = src.REPORT_LAST_UPDATED_BY_USER'
                + IIF(@agg_num_columns != '',
                      ',' + (SELECT STRING_AGG('tgt.'
                                                   + CAST(QUOTENAME(datamart_column_nm) AS NVARCHAR(MAX))
                                                   + ' = agn.'
                                                   + CAST(QUOTENAME(datamart_column_nm) AS NVARCHAR(MAX)),',')
                             FROM (SELECT DISTINCT datamart_column_nm FROM #AGG_DATA_NUM) as cols),
                      '')
                + IIF(@agg_coded_columns != '',
                      ',' + (SELECT STRING_AGG('tgt.'
                                                   + CAST(QUOTENAME(datamart_column_nm) AS NVARCHAR(MAX))
                                                   + ' = agc.'
                                                   + CAST(QUOTENAME(datamart_column_nm) AS NVARCHAR(MAX)),',')
                             FROM (SELECT DISTINCT datamart_column_nm FROM #AGG_DATA_CODED) as cols),
                      '')
            + ' FROM #AGG_EVENT src
                LEFT JOIN dbo.' + @tgt_table_nm + ' tgt
                    ON src.REPORT_LOCAL_ID = tgt.REPORT_LOCAL_ID'
            + IIF(@agg_num_columns != '',
                  ' LEFT JOIN (
                    SELECT act_uid, ' + @agg_num_columns + '
                    FROM ('
                    + @select_phc_col_nm_response
                    + ' FROM #AGG_DATA_NUM
                        WHERE act_uid IS NOT NULL
                    ) AS SourceData
                    PIVOT (
                        MAX(response)
                        FOR datamart_column_nm IN (' + @agg_num_columns + ')
                    ) AS PivotTable) agn
                    ON agn.act_uid = src.act_uid', ' ')
            + IIF(@agg_coded_columns != '',
                  ' LEFT JOIN (
                    SELECT act_uid, ' + @agg_coded_columns + '
                    FROM ('
                    + @select_phc_col_nm_response
                    + ' FROM #AGG_DATA_CODED
                        WHERE act_uid IS NOT NULL
                    ) AS SourceData
                    PIVOT (
                        MAX(response)
                        FOR datamart_column_nm IN (' + @agg_coded_columns + ')
                    ) AS PivotTable) agc
                    ON agc.act_uid = src.act_uid', ' ')
            + ' WHERE tgt.REPORT_LOCAL_ID IS NOT NULL
                    AND src.act_uid IS NOT NULL;';

        if @debug = 'true' select @Proc_Step_Name as step, @update_sql;

        EXEC sp_executesql @update_sql;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'INSERT INTO dbo.' + @tgt_table_nm;

        DECLARE @insert_sql nvarchar(max) = ''

        SET @insert_sql = '
            INSERT INTO dbo.' + @tgt_table_nm + ' (
                REPORTING_COUNTY,
                COMMENTS,
                REPORT_LOCAL_ID,
                CONDITION_DESCRIPTION,
                MMWR_YEAR,
                MMWR_WEEK,
                REPORT_CREATE_DATE,
                REPORT_LAST_UPDATE_DATE,
                NOTIFICATION_UPD_DT_KEY,
                NOTIFICATION_STATUS,
                NOTIFICATION_LOCAL_ID,
                NOTIFICATION_LAST_CHANGE_TIME,
                USER_NM,
                REPORT_CREATED_BY_USER,
                REPORT_LAST_UPDATED_BY_USER'
                + IIF(@agg_num_columns != '', ',' + @agg_num_columns, '')
                + IIF(@agg_coded_columns != '', ',' + @agg_coded_columns, '')
            + ') SELECT
                    src.REPORTING_COUNTY,
                    src.COMMENTS,
                    src.REPORT_LOCAL_ID,
                    src.CONDITION_DESCRIPTION,
                    src.MMWR_YEAR,
                    src.MMWR_WEEK,
                    src.REPORT_CREATE_DATE,
                    src.REPORT_LAST_UPDATE_DATE,
                    src.NOTIFICATION_UPD_DT_KEY,
                    src.NOTIFICATION_STATUS,
                    src.NOTIFICATION_LOCAL_ID,
                    src.NOTIFICATION_LAST_CHANGE_TIME,
                    src.USER_NM,
                    src.REPORT_CREATED_BY_USER,
                    src.REPORT_LAST_UPDATED_BY_USER'
            + IIF(@agg_num_columns != '', ',' + @agg_num_columns, '')
            + IIF(@agg_coded_columns != '', ',' + @agg_coded_columns, '')
            + ' FROM #AGG_EVENT src
                LEFT JOIN (SELECT REPORT_LOCAL_ID FROM dbo. ' + @tgt_table_nm + ') tgt
                ON src.REPORT_LOCAL_ID = tgt.REPORT_LOCAL_ID'
            + IIF(@agg_num_columns != '',
                  ' LEFT JOIN (
                    SELECT act_uid, ' + @agg_num_columns + '
                    FROM ('
                      + @select_phc_col_nm_response
                      + ' FROM #AGG_DATA_NUM
                          WHERE act_uid IS NOT NULL
                    ) AS SourceData
                    PIVOT (
                        MAX(response)
                        FOR datamart_column_nm IN (' + @agg_num_columns + ')
                    ) AS PivotTable) agn
                    ON agn.act_uid = src.act_uid', ' ')
            + IIF(@agg_coded_columns != '',
                  ' LEFT JOIN (
                    SELECT act_uid, ' + @agg_coded_columns + '
                    FROM ('
                      + @select_phc_col_nm_response
                      + ' FROM #AGG_DATA_CODED
                          WHERE act_uid IS NOT NULL
                    ) AS SourceData
                    PIVOT (
                        MAX(response)
                        FOR datamart_column_nm IN (' + @agg_coded_columns + ')
                    ) AS PivotTable) agc
                    ON agc.act_uid = src.act_uid', ' ')
            + ' WHERE tgt.REPORT_LOCAL_ID IS NULL
                    AND src.act_uid IS NOT NULL';

        if @debug = 'true' select @Proc_Step_Name as step, @insert_sql;

        exec sp_executesql @insert_sql;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);
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
