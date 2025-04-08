CREATE OR ALTER PROCEDURE [dbo].[sp_nrt_tb_pam_ldf_postprocessing] 
    @phc_id_list nvarchar(max),
    @debug bit = 'false'
AS
BEGIN

    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) AS BIGINT);
    PRINT @batch_id;
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT= 0;
    DECLARE @Proc_Step_Name VARCHAR(200)= '';
	DECLARE @Dataflow_Name VARCHAR(200) = 'TB_PAM_LDF POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_nrt_tb_pam_ldf_postprocessing';

    DECLARE @global_temp_table_name varchar(500) = '';
    DECLARE @sql_code NVARCHAR(MAX);
    DECLARE @ldf_columns NVARCHAR(MAX) = '';
    DECLARE @tb_ldf_columns NVARCHAR(MAX) = '';

    SET @global_temp_table_name = '##TB_PAM_LDF_TRANSLATED' + '_' + CAST(@Batch_id as varchar(50));    

    BEGIN TRY
        

        SET @Proc_Step_Name = 'SP_Start';

        INSERT INTO dbo.job_flow_log ( batch_id
                                    , [Dataflow_Name]
                                    , [package_Name]
                                    , [Status_Type]
                                    , [step_number]
                                    , [step_name]
                                    , [row_count]
                                    , [Msg_Description1])
        VALUES ( @batch_id
            , @Dataflow_Name
            , @Package_Name
            , 'START'
            , @Proc_Step_no
            , @Proc_Step_Name
            , 0
            , LEFT('ID List-' + @phc_id_list, 500));

--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #LDF_BASE';

        WITH CTE_INVESTIGATION_BATCH_ID AS (
			SELECT 
				public_health_case_uid,
				batch_id,
				add_user_id,
				last_chg_user_id
			FROM [dbo].nrt_investigation I WITH (NOLOCK) 
			INNER JOIN  (SELECT TRIM(value) AS value FROM STRING_SPLIT(@phc_id_list, ',')) nu on nu.value = I.public_health_case_uid  
			WHERE I.investigation_form_cd='INV_FORM_RVCT'
		)
         SELECT 
            A.DATAMART_COLUMN_NM,
            A.ANSWER_TXT,
            CAST(A.ACT_UID AS BIGINT) AS TB_PAM_UID,
            I.ADD_USER_ID,
            A.CODE_SET_GROUP_ID,
            A.NCA_ADD_TIME AS ADD_TIME,
            I.LAST_CHG_USER_ID,
            A.LAST_CHG_TIME
        INTO #LDF_BASE  
        FROM [dbo].nrt_page_case_answer A WITH (NOLOCK) 
		INNER JOIN CTE_INVESTIGATION_BATCH_ID I 
		ON I.public_health_case_uid = A.ACT_UID AND ISNULL(I.batch_id, 1) = ISNULL(A.batch_id, 1)
        WHERE 
            A.LDF_STATUS_CD IN ('LDF_UPDATE', 'LDF_CREATE', 'LDF_PROCESSED')
            AND A.NUIM_RECORD_STATUS_CD IN ('Active', 'Inactive');
        

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #LDF_BASE;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
        
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #LDF_BASE_CODED_TRANSLATED';

            IF OBJECT_ID('tempdb..#LDF_BASE_CODED_TRANSLATED') IS NOT NULL
                DROP TABLE #LDF_BASE_CODED_TRANSLATED;

            -- LDF_BASE_CODED
            ;WITH LDF_BASE_CODED AS (
                SELECT 
                    tb.DATAMART_COLUMN_NM,
                    tb.ANSWER_TXT,
                    tb.TB_PAM_UID,
                    tb.ADD_USER_ID,
                    tb.CODE_SET_GROUP_ID,
                    tb.ADD_TIME,
                    tb.LAST_CHG_USER_ID,
                    tb.LAST_CHG_TIME,
                    METADATA.CODE_SET_NM,
                    CODESET.CLASS_CD
                FROM #LDF_BASE tb
                LEFT OUTER JOIN [dbo].nrt_srte_codeset_group_metadata METADATA WITH (NOLOCK) 
                    ON METADATA.CODE_SET_GROUP_ID = tb.CODE_SET_GROUP_ID
                LEFT OUTER JOIN [dbo].nrt_srte_Codeset CODESET WITH (NOLOCK) 
                    ON METADATA.CODE_SET_NM = CODESET.CODE_SET_NM    
            )
            
            -- LDF_BASE_CODED_TRANSLATED
            SELECT 
                tb.DATAMART_COLUMN_NM,
                COALESCE(cvg.CODE_SHORT_DESC_TXT, tb.ANSWER_TXT) AS ANSWER_TXT,
                tb.TB_PAM_UID,
                tb.ADD_USER_ID,
                tb.ADD_TIME,
                tb.LAST_CHG_USER_ID,
                tb.LAST_CHG_TIME,
                cvg.CODE,
                cvg.CODE_SHORT_DESC_TXT,
                tb.CODE_SET_NM,
                tb.CLASS_CD
            INTO #LDF_BASE_CODED_TRANSLATED  
            FROM LDF_BASE_CODED tb
            LEFT JOIN [dbo].nrt_srte_Code_value_general cvg WITH (NOLOCK) 
                ON cvg.CODE_SET_NM = tb.CODE_SET_NM
                AND cvg.CODE = tb.ANSWER_TXT
                AND tb.CLASS_CD = 'code_value_general';

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #LDF_BASE_CODED_TRANSLATED;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
---------------------------------------------------------------------------------------------------------------------        

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #LDF_BASE_CLINICAL_TRANSLATED';

            IF OBJECT_ID('#LDF_BASE_CLINICAL_TRANSLATED', 'U') IS NOT NULL
                DROP TABLE #LDF_BASE_CLINICAL_TRANSLATED;

            -- LDF_BASE_CLINICAL_TRANSLATED
            SELECT 
                tb.DATAMART_COLUMN_NM,
                COALESCE(cvc.CODE_SHORT_DESC_TXT, tb.ANSWER_TXT) AS ANSWER_TXT,
                tb.TB_PAM_UID,
                tb.ADD_USER_ID,
                tb.ADD_TIME,
                tb.LAST_CHG_USER_ID,
                tb.LAST_CHG_TIME,
                tb.CODE,
                cvc.CODE_SHORT_DESC_TXT,
                tb.CODE_SET_NM,
                tb.CLASS_CD
            INTO #LDF_BASE_CLINICAL_TRANSLATED  
            FROM #LDF_BASE_CODED_TRANSLATED tb
            LEFT JOIN [dbo].nrt_srte_Code_value_clinical cvc WITH (NOLOCK)
                ON cvc.CODE_SET_NM = tb.CODE_SET_NM
                AND cvc.CODE = tb.ANSWER_TXT
                AND tb.CLASS_CD = 'code_value_clinical';

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #LDF_BASE_CLINICAL_TRANSLATED;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #LDF_BASE_STATE_TRANSLATED';

            IF OBJECT_ID('tempdb..#LDF_BASE_STATE_TRANSLATED') IS NOT NULL
                DROP TABLE #LDF_BASE_STATE_TRANSLATED;

            -- LDF_BASE_STATE_TRANSLATED
            SELECT 
                tb.DATAMART_COLUMN_NM,
                COALESCE(vsc.CODE_SHORT_DESC_TXT, tb.ANSWER_TXT) AS ANSWER_TXT,
                tb.TB_PAM_UID,
                tb.ADD_USER_ID,
                tb.ADD_TIME,
                tb.LAST_CHG_USER_ID,
                tb.LAST_CHG_TIME,
                tb.CODE,
                vsc.CODE_SHORT_DESC_TXT,
                tb.CODE_SET_NM,
                tb.CLASS_CD
            INTO #LDF_BASE_STATE_TRANSLATED  
            FROM #LDF_BASE_CLINICAL_TRANSLATED tb
            LEFT OUTER JOIN [dbo].v_nrt_srte_state_code vsc WITH (NOLOCK)
                ON vsc.CODE_SET_NM = tb.CODE_SET_NM
                AND vsc.STATE_CD = tb.ANSWER_TXT
                AND tb.CLASS_CD IN ('STATE_CCD', 'V_state_code');

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #LDF_BASE_STATE_TRANSLATED;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #LDF_BASE_COUNTRY_TRANSLATED';

            IF OBJECT_ID('tempdb..#LDF_BASE_COUNTRY_TRANSLATED') IS NOT NULL
                DROP TABLE #LDF_BASE_COUNTRY_TRANSLATED;

            -- LDF_BASE_COUNTRY_TRANSLATED
            SELECT 
                tb.DATAMART_COLUMN_NM,
                COALESCE(cc.CODE_SHORT_DESC_TXT, tb.ANSWER_TXT) AS ANSWER_TXT,
                tb.TB_PAM_UID,
                tb.ADD_USER_ID,
                tb.ADD_TIME,
                tb.LAST_CHG_USER_ID,
                tb.LAST_CHG_TIME,
                tb.CODE,
                cc.CODE_SHORT_DESC_TXT,
                tb.CODE_SET_NM,
                tb.CLASS_CD
            INTO #LDF_BASE_COUNTRY_TRANSLATED  
            FROM #LDF_BASE_STATE_TRANSLATED tb
            LEFT JOIN [dbo].nrt_srte_Country_code cc WITH (NOLOCK)
                ON cc.CODE_SET_NM = tb.CODE_SET_NM
                AND cc.CODE = tb.ANSWER_TXT
                AND tb.CLASS_CD IN ('COUNTRY_CODE');


            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #LDF_BASE_COUNTRY_TRANSLATED;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #LDF_BASE_COUNTRY_CONCAT';

            IF OBJECT_ID('tempdb..#LDF_BASE_COUNTRY_CONCAT') IS NOT NULL
                DROP TABLE #LDF_BASE_COUNTRY_CONCAT;

            -- Concatenate ANSWER_TXT by TB_PAM_UID and DATAMART_COLUMN_NM (Replace PROC SORT and DATA step)
            WITH Concatenated AS (
                SELECT 
                    TB_PAM_UID,
                    DATAMART_COLUMN_NM,
                    STRING_AGG(ANSWER_TXT, ' | ') WITHIN GROUP (ORDER BY ANSWER_TXT) AS concatenated_answer_txt,
                    MAX(ADD_USER_ID) AS ADD_USER_ID,
                    MAX(ADD_TIME) AS ADD_TIME,
                    MAX(LAST_CHG_USER_ID) AS LAST_CHG_USER_ID,
                    MAX(LAST_CHG_TIME) AS LAST_CHG_TIME,
                    MAX(CODE) AS CODE,
                    MAX(CODE_SHORT_DESC_TXT) AS CODE_SHORT_DESC_TXT,
                    MAX(CODE_SET_NM) AS CODE_SET_NM,
                    MAX(CLASS_CD) AS CLASS_CD
                FROM #LDF_BASE_COUNTRY_TRANSLATED
                GROUP BY TB_PAM_UID, DATAMART_COLUMN_NM
            )
            SELECT 
                TB_PAM_UID,
                DATAMART_COLUMN_NM,
                CASE WHEN LEN(concatenated_answer_txt) > 0 THEN concatenated_answer_txt ELSE NULL END AS ANSWER_TXT,
                ADD_USER_ID,
                ADD_TIME,
                LAST_CHG_USER_ID,
                LAST_CHG_TIME,
                CODE,
                CODE_SHORT_DESC_TXT,
                CODE_SET_NM,
                CLASS_CD
            INTO #LDF_BASE_COUNTRY_CONCAT  
            FROM Concatenated;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #LDF_BASE_COUNTRY_CONCAT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #MISSED_COLS';

            IF OBJECT_ID('tempdb..#MISSED_COLS') IS NOT NULL
                DROP TABLE #MISSED_COLS;

            SELECT DISTINCT 
                DATAMART_COLUMN_NM AS col_nm, 
                'varchar' AS col_data_type, 
                NULL AS col_NUMERIC_PRECISION, 
                NULL AS col_NUMERIC_SCALE, 
                2000 AS col_CHARACTER_MAXIMUM_LENGTH
            INTO #MISSED_COLS
            FROM #LDF_BASE_COUNTRY_CONCAT l
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS ic
            ON upper(datamart_column_nm) = upper(ic.COLUMN_NAME) AND
                upper(ic.table_name) = 'TB_PAM_LDF'
            WHERE ic.COLUMN_NAME IS NULL;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #MISSED_COLS;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING TABLE WITH NEW COLUMNS';

            
            DECLARE @AlterQuery NVARCHAR(MAX);

            set @AlterQuery = 'ALTER TABLE dbo.TB_PAM_LDF ADD ' + (select STRING_AGG( col_nm + ' ' +  col_data_type +
            CASE
                WHEN col_data_type IN ('decimal', 'numeric') THEN '(' + CAST(col_NUMERIC_PRECISION AS NVARCHAR) + ',' + CAST(col_NUMERIC_SCALE AS NVARCHAR) + ')'
                WHEN col_data_type = 'varchar' THEN '(' +
                    CASE WHEN col_CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(col_CHARACTER_MAXIMUM_LENGTH AS NVARCHAR) END
                + ')'
                ELSE ''
            END, ', ') from #MISSED_COLS);

            exec sp_executesql @AlterQuery;
            
            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;

-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #COL_LIST';

            IF OBJECT_ID('tempdb..#COL_LIST') IS NOT NULL
                DROP TABLE #COL_LIST;

            SELECT DISTINCT ic.COLUMN_NAME, ORDINAL_POSITION
            INTO #COL_LIST
            FROM INFORMATION_SCHEMA.COLUMNS ic 
            WHERE ic.table_name = 'TB_PAM_LDF'
            AND UPPER(ic.COLUMN_NAME) NOT IN ('INVESTIGATION_KEY', 'TB_PAM_UID', 'ADD_TIME'); --IGNORING FIRST THREE DEFAULT COLUMNS;


            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #COL_LIST;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);



-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING LDF_COLUMNS';

                   
            SELECT @ldf_columns = COALESCE(STRING_AGG(CAST(QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY ORDINAL_POSITION), '')
            FROM (SELECT DISTINCT COLUMN_NAME, ORDINAL_POSITION FROM #COL_LIST) AS cols;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING ' + @global_temp_table_name;                

            EXEC ('IF OBJECT_ID(''tempdb..' + @global_temp_table_name +''', ''U'')  IS NOT NULL
            BEGIN
                DROP TABLE ' + @global_temp_table_name +';
            END;')

            IF @ldf_columns != ''
            BEGIN
                SET @sql_code = 'SELECT 
                    TB_PAM_UID, 
                    ADD_TIME,
                    ' + @ldf_columns + '
                INTO ' + @global_temp_table_name +'
                FROM (
                    SELECT 
                        TB_PAM_UID, 
                        ADD_TIME, 
                        ANSWER_TXT, 
                        DATAMART_COLUMN_NM 
                    FROM #LDF_BASE_COUNTRY_CONCAT
                    ) AS SourceTable
                PIVOT (
                    MAX(ANSWER_TXT)
                    FOR DATAMART_COLUMN_NM IN (' + @ldf_columns + ')
                ) AS PivotTable';
            END
            ELSE
            BEGIN
                SET @sql_code = 'SELECT 
                    TB_PAM_UID, 
                    ADD_TIME
                INTO ' + @global_temp_table_name +'
                FROM #LDF_BASE_COUNTRY_CONCAT
                '
            END;
            EXEC sp_executesql @sql_code;    

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                EXEC('SELECT '''+ @Proc_Step_Name +''' AS step, * FROM ' + @global_temp_table_name + ';');

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION
 
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETE INCOMING RECORDS FROM TB_PAM_LDF';

            SET @sql_code = 'DELETE D
            FROM [dbo].TB_PAM_LDF D
            INNER JOIN ' + @global_temp_table_name + ' T
                ON T.TB_PAM_UID = D.TB_PAM_UID
            '
            EXEC sp_executesql @sql_code; 
    
            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                EXEC('SELECT '''+ @Proc_Step_Name +''' AS step, * FROM ' + @global_temp_table_name + ';');
    
            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);
        
        COMMIT TRANSACTION; 

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERT INCOMING RECORDS TO TB_PAM_LDF';

            SET @tb_ldf_columns = (
                SELECT ISNULL(
                    STRING_AGG('tb.' + TRIM(value), ','),
                    ''
                )
                FROM STRING_SPLIT(ISNULL(@ldf_columns, ''), ',')
                WHERE TRIM(value) != ''
            );

            SET @sql_code = 
            'INSERT INTO dbo.TB_PAM_LDF([INVESTIGATION_KEY], [TB_PAM_UID], [add_time] '+ 
                CASE
                    WHEN @ldf_columns != '' THEN ',' + @ldf_columns
                    ELSE ''
                END
            + ' )
            SELECT
                inv.INVESTIGATION_KEY,
                tb.TB_PAM_UID,
                tb.add_time'+
            + CASE
                    WHEN @ldf_columns != '' THEN ',' + @tb_ldf_columns
                    ELSE ''
                END
            +
            '
            FROM
            ' + @global_temp_table_name +' tb
            LEFT JOIN [dbo].investigation inv WITH(nolock)
                ON tb.TB_PAM_UID = inv.CASE_UID
            ';
            EXEC sp_executesql @sql_code;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                EXEC('SELECT '''+ @Proc_Step_Name +''' AS step, * FROM ' + @global_temp_table_name + ';');

            -- Force drop global temp table
            EXEC ('IF OBJECT_ID(''tempdb..' + @global_temp_table_name +''', ''U'')  IS NOT NULL
            BEGIN
                DROP TABLE ' + @global_temp_table_name +';
            END;')

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;

-------------------------------------------------------------------------------------------

        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);
    
-------------------------------------------------------------------------------------------
END TRY

BEGIN CATCH

	IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

	-- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();


        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'ERROR', @Proc_Step_no, @Proc_Step_name, @FullErrorMessage, 0);

	return -1 ;

END CATCH

END;


---------------------------------------------------END OF PROCEDURE---------------------------------------------------------------------
