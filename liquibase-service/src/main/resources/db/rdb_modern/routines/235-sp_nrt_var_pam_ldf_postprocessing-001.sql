CREATE OR ALTER PROCEDURE dbo.sp_nrt_var_pam_ldf_postprocessing 
@phc_uids nvarchar(max),
@debug bit = 'false'
AS
BEGIN
    BEGIN TRY
        /* Logging */
            declare @RowCount_no bigint;
            declare @proc_step_no float = 0;
            declare @proc_step_name varchar(200) = '';
            declare @batch_id bigint;
            declare @dataflow_name varchar(200) = 'var_pam_ldf POST-Processing';
            declare @package_name varchar(200) = 'sp_nrt_var_pam_ldf_postprocessing';
            set @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);

        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT], [Msg_Description1])
        VALUES (@BATCH_ID, @dataflow_name, @package_name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO, LEFT (@phc_uids, 199));

    
--------------------------------------------------------------------------------------------------------
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #S_PHC_LIST TABLE';
                
        IF OBJECT_ID('#S_PHC_LIST', 'U') IS NOT NULL
            drop table #S_PHC_LIST;

        SELECT value
        INTO  #S_PHC_LIST
        FROM STRING_SPLIT(@phc_uids, ',');
        
        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
            
--------------------------------------------------------------------------------------------------------
        
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #LDF_BASE TABLE';
          
        IF OBJECT_ID('#LDF_BASE', 'U') IS NOT NULL
            drop table #LDF_BASE;
        
        SELECT 
            NCA.DATAMART_COLUMN_NM,
            NCA.ANSWER_TXT,
            NCA.ACT_UID AS VAR_PAM_UID,
            NCA.CODE_SET_GROUP_ID,
            NCA.NCA_ADD_TIME,
            NCA.LAST_CHG_TIME,
            CGM.code_set_nm,
            CS.class_cd
        INTO #LDF_BASE
        FROM [dbo].nrt_investigation I  with (nolock)
        INNER JOIN #S_PHC_LIST PHC_LIST
            on I.public_health_case_UID = PHC_LIST.value
        INNER JOIN dbo.nrt_page_case_answer NCA  with (nolock)
            on NCA.act_uid = I.public_health_case_UID  
        LEFT OUTER JOIN [dbo].nrt_srte_codeset_group_metadata CGM with (nolock)
            ON CGM.CODE_SET_GROUP_ID = nca.CODE_SET_GROUP_ID
        LEFT OUTER JOIN [dbo].nrt_srte_codeset CS with (nolock)
            ON CGM.code_set_nm = CS.code_set_nm
        WHERE  NCA.ldf_status_cd IN ('LDF_UPDATE', 'LDF_CREATE', 'LDF_PROCESSED') AND
            NCA.investigation_form_cd = 'INV_FORM_VAR'
        AND NCA.nuim_record_status_cd IN ('Active', 'Inactive')
        AND isnull(I.batch_id, 1) = isnull(NCA.batch_id, 1);
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #LDF_BASE;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
    
--------------------------------------------------------------------------------------------------------
        
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #LDF_BASE_CODED_TRANSLATED TABLE';
          
        
        IF OBJECT_ID('#LDF_BASE_CODED_TRANSLATED', 'U') IS NOT NULL
            drop table #LDF_BASE_CODED_TRANSLATED;
        

        SELECT 
            var.DATAMART_COLUMN_NM,
            var.VAR_PAM_UID,
            var.NCA_ADD_TIME,
            var.LAST_CHG_TIME,
            cvg.CODE,
            cvg.CODE_SHORT_DESC_TXT,
            var.CODE_SET_NM,
            var.CLASS_CD,
            CASE WHEN LEN(cvg.CODE_SHORT_DESC_TXT) > 0 
                 THEN cvg.CODE_SHORT_DESC_TXT 
                 ELSE ANSWER_TXT END AS ANSWER_TXT
        INTO #LDF_BASE_CODED_TRANSLATED
        FROM #LDF_BASE var
        LEFT JOIN DBO.NRT_SRTE_CODE_VALUE_GENERAL cvg
            ON cvg.CODE_SET_NM = var.CODE_SET_NM
            AND cvg.CODE = var.ANSWER_TXT
            AND upper(var.CLASS_CD) = ('CODE_VALUE_GENERAL')
        ORDER BY VAR_PAM_UID, ANSWER_TXT;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #LDF_BASE_CODED_TRANSLATED;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);

--------------------------------------------------------------------------------------------------------       

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #LDF_BASE_CLINICAL_TRANSLATED TABLE';
          
        
        IF OBJECT_ID('#LDF_BASE_CLINICAL_TRANSLATED', 'U') IS NOT NULL
            drop table #LDF_BASE_CLINICAL_TRANSLATED;
        

        SELECT 
            var.DATAMART_COLUMN_NM,
            var.VAR_PAM_UID,
            var.NCA_ADD_TIME,
            var.LAST_CHG_TIME,
            cvg.CODE,
            cvg.CODE_SHORT_DESC_TXT,
            var.CODE_SET_NM,
            var.CLASS_CD,
            CASE WHEN LEN(cvg.CODE_SHORT_DESC_TXT) > 0 
                 THEN cvg.CODE_SHORT_DESC_TXT 
                 ELSE ANSWER_TXT END AS ANSWER_TXT
        INTO #LDF_BASE_CLINICAL_TRANSLATED
        FROM #LDF_BASE_CODED_TRANSLATED var
        LEFT JOIN DBO.NRT_SRTE_CODE_VALUE_CLINICAL cvg
            ON cvg.CODE_SET_NM = var.CODE_SET_NM
            AND cvg.CODE = var.ANSWER_TXT
            AND upper(var.CLASS_CD) = ('CODE_VALUE_CLINICAL')
        ORDER BY VAR_PAM_UID, ANSWER_TXT;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #LDF_BASE_CLINICAL_TRANSLATED;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
            
--------------------------------------------------------------------------------------------------------
        
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #LDF_BASE_STATE_TRANSLATED TABLE';
        
        IF OBJECT_ID('#LDF_BASE_STATE_TRANSLATED', 'U') IS NOT NULL
            drop table #LDF_BASE_STATE_TRANSLATED;
        

        SELECT 
            var.DATAMART_COLUMN_NM,
            var.VAR_PAM_UID,
            var.NCA_ADD_TIME,
            var.LAST_CHG_TIME,
            cvg.CODE,
            cvg.CODE_SHORT_DESC_TXT,
            var.CODE_SET_NM,
            var.CLASS_CD,
            CASE WHEN LEN(cvg.CODE_SHORT_DESC_TXT) > 0 
                 THEN cvg.CODE_SHORT_DESC_TXT 
                 ELSE ANSWER_TXT END AS ANSWER_TXT
        INTO #LDF_BASE_STATE_TRANSLATED
        FROM #LDF_BASE_CLINICAL_TRANSLATED var
        LEFT OUTER JOIN DBO.V_NRT_SRTE_STATE_CODE cvg
            ON cvg.CODE_SET_NM = var.CODE_SET_NM
            AND cvg.STATE_CD = var.ANSWER_TXT
            AND upper(var.CLASS_CD) IN ('STATE_CCD', 'V_STATE_CODE')
        ORDER BY VAR_PAM_UID, ANSWER_TXT;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #LDF_BASE_STATE_TRANSLATED;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
    
--------------------------------------------------------------------------------------------------------
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #LDF_BASE_COUNTRY_TRANSLATED TABLE';
          
        IF OBJECT_ID('#LDF_BASE_COUNTRY_TRANSLATED', 'U') IS NOT NULL
            drop table #LDF_BASE_COUNTRY_TRANSLATED;

        SELECT 
            var.DATAMART_COLUMN_NM,
            var.VAR_PAM_UID,
            var.NCA_ADD_TIME,
            var.LAST_CHG_TIME,
            cvg.CODE,
            cvg.CODE_SHORT_DESC_TXT,
            var.CODE_SET_NM,
            var.CLASS_CD,
            CASE WHEN LEN(cvg.CODE_SHORT_DESC_TXT) > 0 
                 THEN cvg.CODE_SHORT_DESC_TXT 
                 ELSE ANSWER_TXT END AS ANSWER_TXT
        INTO #LDF_BASE_COUNTRY_TRANSLATED
        FROM #LDF_BASE_STATE_TRANSLATED var
        LEFT OUTER JOIN DBO.NRT_SRTE_COUNTRY_CODE cvg
            ON cvg.CODE_SET_NM = var.CODE_SET_NM
            AND cvg.CODE = var.ANSWER_TXT
            AND upper(var.CLASS_CD) IN ('COUNTRY_CODE')
        ORDER BY VAR_PAM_UID, ANSWER_TXT;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #LDF_BASE_COUNTRY_TRANSLATED;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
        
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #LDF_BASE_TRANSLATED TABLE';
        
        IF OBJECT_ID('#LDF_BASE_TRANSLATED', 'U') IS NOT NULL
            drop table #LDF_BASE_TRANSLATED;
        
        SELECT 
            DATAMART_COLUMN_NM,
            VAR_PAM_UID,
            NCA_ADD_TIME as ADD_TIME,
            STRING_AGG(ANSWER_TXT, ' | ') WITHIN GROUP (ORDER BY ANSWER_TXT) AS ANSWER_TXT
        INTO #LDF_BASE_TRANSLATED
        FROM #LDF_BASE_COUNTRY_TRANSLATED t
        GROUP BY 
            VAR_PAM_UID, datamart_column_nm, NCA_ADD_TIME;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #LDF_BASE_TRANSLATED;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
        
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #MISSED_COLS TABLE';
          
        IF OBJECT_ID('#MISSED_COLS', 'U') IS NOT NULL
            drop table #MISSED_COLS;

        -- All columns in the LDFs are varchar
        select distinct DATAMART_COLUMN_NM as col_nm, 'varchar' as col_data_type, 
                null as col_NUMERIC_PRECISION, 
                null as col_NUMERIC_SCALE, 
                2000 as col_CHARACTER_MAXIMUM_LENGTH
        into #missed_cols
        from #LDF_BASE_TRANSLATED l
        left join INFORMATION_SCHEMA.COLUMNS ic
        on upper(datamart_column_nm) = upper(ic.COLUMN_NAME) AND
            upper(ic.table_name) = 'VAR_PAM_LDF'
        where ic.COLUMN_NAME is null;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #MISSED_COLS;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
    BEGIN TRANSACTION
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING  TABLE';
        
        
        DECLARE @AlterQuery NVARCHAR(MAX);

        set @AlterQuery = 'ALTER TABLE dbo.VAR_PAM_LDF ADD ' + (select STRING_AGG( col_nm + ' ' +  col_data_type +
        CASE
            WHEN col_data_type IN ('decimal', 'numeric') THEN '(' + CAST(col_NUMERIC_PRECISION AS NVARCHAR) + ',' + CAST(col_NUMERIC_SCALE AS NVARCHAR) + ')'
            WHEN col_data_type = 'varchar' THEN '(' +
                CASE WHEN col_CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(col_CHARACTER_MAXIMUM_LENGTH AS NVARCHAR) END
            + ')'
            ELSE ''
        END, ', ') from #missed_cols);

        exec sp_executesql @AlterQuery;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;

--------------------------------------------------------------------------------------------------------
        
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #COL_LIST TABLE';
          
        
        IF OBJECT_ID('#COL_LIST', 'U') IS NOT NULL
            drop table #COL_LIST;


        select distinct ic.COLUMN_NAME, ORDINAL_POSITION
        into #COL_LIST
        from INFORMATION_SCHEMA.COLUMNS ic 
        where ic.table_name = 'VAR_PAM_LDF'
        AND upper(ic.COLUMN_NAME) NOT IN ('INVESTIGATION_KEY', 'VAR_PAM_UID', 'ADD_TIME'); --IGNORING FIRST THREE DEFAULT COLUMNS;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #COL_LIST;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
    
--------------------------------------------------------------------------------------------------------
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING ordered_columns';

        DECLARE @ordered_columns NVARCHAR(MAX) = '';
        
        SELECT @ordered_columns = COALESCE(STRING_AGG(CAST(QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY ORDINAL_POSITION), '')
            FROM (SELECT DISTINCT COLUMN_NAME, ORDINAL_POSITION FROM #COL_LIST) AS cols;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
            
--------------------------------------------------------------------------------------------------------
    
    BEGIN TRANSACTION
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Update dbo.VAR_PAM_LDF';
          
        
        DECLARE @Update_sql NVARCHAR(MAX) = '';

        SET @Update_sql = 
        'UPDATE dbo.VAR_PAM_LDF
        SET
        ADD_TIME = tgt.ADD_TIME'
        + CASE
            WHEN @ordered_columns != '' THEN ',' + (SELECT STRING_AGG( CAST(QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)) + ' = src.' + CAST(QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)),',')
                    FROM (SELECT DISTINCT COLUMN_NAME FROM #COL_LIST) as cols)
            ELSE ''
        END
        + '
        FROM
        (
        SELECT INV.INVESTIGATION_KEY, D_VAR_PAM.VAR_PAM_UID as D_VAR_PAM_UID, LDF_T.*
        FROM DBO.D_VAR_PAM D_VAR_PAM with (nolock)
        INNER JOIN #S_PHC_LIST S_PHC_LIST
            ON S_PHC_LIST.VALUE = D_VAR_PAM.VAR_PAM_UID
        LEFT JOIN (
            SELECT *
            FROM (
                SELECT VAR_PAM_UID, ADD_TIME, ANSWER_TXT, DATAMART_COLUMN_NM from
                #LDF_BASE_TRANSLATED
                ) AS SourceTable
            PIVOT (
                MAX(ANSWER_TXT)
                FOR DATAMART_COLUMN_NM IN (
                ' + 
                @ordered_columns
                +'
                )
            ) AS PivotTable
        ) LDF_T ON
            D_VAR_PAM.VAR_PAM_UID = LDF_T.VAR_PAM_UID
        LEFT JOIN DBO.INVESTIGATION INV with (nolock) ON
            D_VAR_PAM.VAR_PAM_UID = INV.case_uid ) src
        INNER JOIN dbo.VAR_PAM_LDF tgt  with (nolock)
            on src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY and
            src.D_VAR_PAM_UID = tgt.VAR_PAM_UID';
        
        exec sp_executesql @Update_sql;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;
    
--------------------------------------------------------------------------------------------------------
    
    BEGIN TRANSACTION
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Inserting to dbo.VAR_PAM_LDF';
          
        
        DECLARE @Insert_sql NVARCHAR(MAX) = '';

        SET @Insert_sql = 
        'INSERT INTO dbo.VAR_PAM_LDF([INVESTIGATION_KEY], [VAR_PAM_UID], [add_time] '+ 
            CASE
                WHEN @ordered_columns != '' THEN ',' + @ordered_columns
                ELSE ''
            END
        + ' )
        SELECT
        t.INVESTIGATION_KEY,
        t.D_VAR_PAM_UID as VAR_PAM_UID,
        t.add_time'+
        + CASE
                WHEN @ordered_columns != '' THEN ',' + @ordered_columns
                ELSE ''
            END
        +
        '
        FROM
        (
        SELECT INV.INVESTIGATION_KEY, D_VAR_PAM.VAR_PAM_UID as D_VAR_PAM_UID, LDF_T.*
        FROM DBO.D_VAR_PAM D_VAR_PAM with (nolock)
        INNER JOIN #S_PHC_LIST S_PHC_LIST
            ON S_PHC_LIST.VALUE = D_VAR_PAM.VAR_PAM_UID
        LEFT JOIN (
            SELECT *
            FROM (
                SELECT VAR_PAM_UID, ADD_TIME, ANSWER_TXT, DATAMART_COLUMN_NM from
                #LDF_BASE_TRANSLATED
                ) AS SourceTable
            PIVOT (
                MAX(ANSWER_TXT)
                FOR DATAMART_COLUMN_NM IN (
                ' + 
                @ordered_columns
                +'
                )
            ) AS PivotTable
        ) LDF_T ON
            D_VAR_PAM.VAR_PAM_UID = LDF_T.VAR_PAM_UID
        LEFT JOIN DBO.INVESTIGATION INV with (nolock) ON
            D_VAR_PAM.VAR_PAM_UID = INV.case_uid ) t
        LEFT JOIN (select INVESTIGATION_KEY, VAR_PAM_UID from dbo.VAR_PAM_LDF with (nolock)) tgt
        on t.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY and
        t.D_VAR_PAM_UID = tgt.VAR_PAM_UID
        where tgt.VAR_PAM_UID is null;';
        
        exec sp_executesql @Insert_sql;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;
--------------------------------------------------------------------------------------------------------
    
        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);

--------------------------------------------------------------------------------------------------------
   
    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0   
            BEGIN
                ROLLBACK TRANSACTION;
            END;

        DECLARE @FullErrorMessage VARCHAR(8000) =
		'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
		'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		'Error Message: ' + ERROR_MESSAGE();


        INSERT INTO dbo.[job_flow_log] (
			batch_id
			,[Dataflow_Name]
			,[package_Name]
			,[Status_Type]
			,[step_number]
			,[step_name]
			,[Error_Description]
			,[row_count]
        )
        VALUES (
            @batch_id
            ,@dataflow_name
            ,@package_name
            ,'ERROR'
            ,@Proc_Step_no
            , @Proc_Step_name
            , @FullErrorMessage
            ,0
		);

        return -1 ;

    END CATCH

END;
---------------------------------------------------END OF PROCEDURE---------------------------------------------------------------------
        
        