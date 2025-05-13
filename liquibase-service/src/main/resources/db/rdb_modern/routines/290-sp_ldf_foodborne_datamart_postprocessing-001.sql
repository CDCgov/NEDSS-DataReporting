
CREATE OR ALTER PROCEDURE [dbo].[sp_ldf_foodborne_datamart_postprocessing]  
  @phc_id_list nvarchar(max),
  @debug bit = 'false'
 AS
BEGIN

	DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) AS BIGINT);
    PRINT @batch_id;
    DECLARE @RowCount_no INT =0;
    DECLARE @Proc_Step_no FLOAT = 0; 
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
	DECLARE @Dataflow_Name VARCHAR(200) = 'LDF_FOODBORNE POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_ldf_foodborne_datamart_postprocessing';

    DECLARE @global_temp_foodborne_ta varchar(500) = '';
    DECLARE @global_temp_foodborne_short_col varchar(500) = '';
    DECLARE @global_temp_foodborne varchar(500) = '';
    DECLARE @sql_code NVARCHAR(MAX);
    DECLARE @ldf_columns NVARCHAR(MAX) = '';
    DECLARE @count BIGINT;

    DECLARE  @dynamiccolumnUpdate varchar(max)='' 


    SET @global_temp_foodborne_ta = '##FOODBORNE_TA' + '_' + CAST(@Batch_id as varchar(50)); 
    SET @global_temp_foodborne_short_col = '##FOODBORNE_SHORT_COL' + '_' + CAST(@Batch_id as varchar(50)); 
    SET @global_temp_foodborne = '##FOODBORNE' + '_' + CAST(@Batch_id as varchar(50)); 
    
 
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


        ------------------------------------------------------------------------------------------------------------------------------------------
		SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET @PROC_STEP_NAME = 'LDF_UID_LIST';  
	
		--------- Create #LDF_UID_LIST table 
        IF OBJECT_ID('#LDF_UID_LIST', 'U') IS NOT NULL   
            DROP TABLE #LDF_UID_LIST; 
    
        SELECT distinct TRIM(value) AS value into #LDF_UID_LIST FROM STRING_SPLIT(@phc_id_list, ',')		

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #LDF_UID_LIST;

        SELECT @RowCount_no = @@ROWCOUNT;
    
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);  
                            
	--------------------------------------------------------------------------------------------------------

        SET
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET
			@PROC_STEP_NAME = 'GENERATING #LDF_PHC_UID_LIST TABLE';

		IF OBJECT_ID('#LDF_PHC_UID_LIST', 'U') IS NOT NULL
			DROP TABLE #LDF_PHC_UID_LIST;

		SELECT 
			s.INVESTIGATION_UID,
			s.LDF_UID,
            inv.INVESTIGATION_KEY
		INTO  #LDF_PHC_UID_LIST
		FROM [dbo].LDF_DIMENSIONAL_DATA s WITH (NOLOCK) 
        INNER JOIN [dbo].INVESTIGATION inv WITH (NOLOCK) 
            ON inv.CASE_UID = s.INVESTIGATION_UID
		INNER JOIN #LDF_UID_LIST nu 
            ON nu.value = s.INVESTIGATION_UID 
			
		SELECT @RowCount_no = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_PHC_UID_LIST;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 	
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        ------------------------------------------------------------------------------------------------------------------------------------------

		/* THIS IS EXISTING CODE IN RDB. WHEN THERE IS NO RECORD IN LDF_DIMENSIONAL, THE SP WILL NOT EXECUTE. 
		HENCE COMMENTING THIS LINE TO ENSURE ALL THE RECORDS ARE PROCESSED
        
        SET @count =
        (
            SELECT COUNT(1)
            FROM [dbo].LDF_DIMENSIONAL_DATA s WITH (NOLOCK)
            INNER JOIN [dbo].LDF_DATAMART_TABLE_REF r WITH (NOLOCK) 
                ON s.PHC_CD = r.condition_cd AND r.DATAMART_NAME = 'LDF_FOODBORNE'
            INNER JOIN #LDF_PHC_UID_LIST l  
                ON l.investigation_uid = s.INVESTIGATION_UID
        );	
            
        IF (@count > 0)
        */
        BEGIN

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #BASE_FOODBORNE';
            
            IF OBJECT_ID('#BASE_FOODBORNE', 'U') IS NOT NULL
			    DROP TABLE #BASE_FOODBORNE;

            SELECT DISTINCT
                s.COL1,
                s.INVESTIGATION_UID,          
                s.CODE_SHORT_DESC_TXT,     
                s.LDF_UID,                       
                s.CODE_SET_NM,             
                s.LABEL_TXT,               
                s.DATA_SOURCE,              
                s.CDC_NATIONAL_ID,          
                s.BUSINESS_OBJECT_NM,       
                s.CONDITION_CD,              
                s.CUSTOM_SUBFORM_METADATA_UID,     
                s.PAGE_SET,                  
                s.DATAMART_COLUMN_NM,       
                s.PHC_CD,                    
                s.DATA_TYPE,                 
                s.FIELD_SIZE
            INTO #BASE_FOODBORNE
            FROM [dbo].LDF_DIMENSIONAL_DATA s WITH (NOLOCK)
            INNER JOIN [dbo].LDF_DATAMART_TABLE_REF r WITH (NOLOCK) 
                ON s.PHC_CD = r.CONDITION_CD AND r.DATAMART_NAME = 'LDF_FOODBORNE'
            INNER JOIN #LDF_PHC_UID_LIST l  
                ON l.investigation_uid = s.INVESTIGATION_UID;

            SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF
				@debug = 'true'
				SELECT @Proc_Step_Name AS step, *
				FROM #BASE_FOODBORNE;

			INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES 
				(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no); 


            ------------------------------------------------------------------------------------------------------------------------------------------
        
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #LINKED_FOODBORNE';
            
            IF OBJECT_ID('#LINKED_FOODBORNE', 'U') IS NOT NULL
			    DROP TABLE #LINKED_FOODBORNE;

            SELECT 
                b.COL1,
                b.INVESTIGATION_UID,          
                b.CODE_SHORT_DESC_TXT,     
                b.LDF_UID,                       
                b.CODE_SET_NM,             
                b.LABEL_TXT,               
                b.DATA_SOURCE,              
                b.CDC_NATIONAL_ID,          
                b.BUSINESS_OBJECT_NM,       
                b.CONDITION_CD,              
                b.CUSTOM_SUBFORM_METADATA_UID,     
                b.PAGE_SET,                  
                b.DATAMART_COLUMN_NM,       
                b.PHC_CD,                    
                b.DATA_TYPE,                 
                b.FIELD_SIZE, 
                i.INVESTIGATION_KEY, 
                i.INV_LOCAL_ID  AS INVESTIGATION_LOCAL_ID, 
                i.CASE_OID  AS PROGRAM_JURISDICTION_OID,
                g.PATIENT_KEY,
                p.PATIENT_LOCAL_ID,
                c.CONDITION_SHORT_NM AS DISEASE_NAME
            INTO #LINKED_FOODBORNE
            FROM #BASE_FOODBORNE b
            INNER JOIN [dbo].INVESTIGATION i WITH (NOLOCK)
                ON b.INVESTIGATION_UID = i.CASE_UID 
            INNER JOIN [dbo].GENERIC_CASE g WITH (NOLOCK)
                ON g.INVESTIGATION_KEY = i.INVESTIGATION_KEY
            INNER JOIN [dbo].V_CONDITION_DIM c WITH (NOLOCK)
                ON c.CONDITION_KEY = g.CONDITION_KEY
            INNER JOIN [dbo].D_PATIENT p WITH (NOLOCK)
                ON p.PATIENT_KEY = g.PATIENT_KEY;

            SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF
				@debug = 'true'
				SELECT @Proc_Step_Name AS step, *
				FROM #LINKED_FOODBORNE;

			INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES 
				(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
            

            ------------------------------------------------------------------------------------------------------------------------------------------    

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #ALL_FOODBORNE';
            
            IF OBJECT_ID('#ALL_FOODBORNE', 'U') IS NOT NULL
			    DROP TABLE #ALL_FOODBORNE;

            SELECT 
                a.COL1,
                a.INVESTIGATION_UID,          
                a.CODE_SHORT_DESC_TXT,     
                a.LDF_UID,                       
                a.CODE_SET_NM,             
                a.LABEL_TXT,               
                a.DATA_SOURCE,              
                a.CDC_NATIONAL_ID,          
                a.BUSINESS_OBJECT_NM,       
                a.CONDITION_CD,              
                a.CUSTOM_SUBFORM_METADATA_UID,     
                a.PAGE_SET,                  
                a.PHC_CD,                    
                a.DATA_TYPE,                 
                a.FIELD_SIZE, 
                a.INVESTIGATION_KEY, 
                a.INVESTIGATION_LOCAL_ID, 
                a.PROGRAM_JURISDICTION_OID,
                a.PATIENT_KEY,
                a.PATIENT_LOCAL_ID,
                a.DISEASE_NAME,
                CASE 
                    WHEN DATALENGTH(REPLACE(a.CONDITION_CD, ' ', '')) > 1 
                    THEN a.CONDITION_CD
                    ELSE a.PHC_CD
                END AS DISEASE_CD,
                CASE 
                    WHEN DATALENGTH(a.page_set) < 2 
                    THEN a.page_set
                    ELSE a.page_set
                END AS DISEASE_NM,
                CASE 
                    WHEN DATALENGTH(b.DATAMART_COLUMN_NM) > 2 
                    THEN b.DATAMART_COLUMN_NM
                    ELSE a.DATAMART_COLUMN_NM
                END AS DATAMART_COLUMN_NM
            INTO #ALL_FOODBORNE
            FROM #LINKED_FOODBORNE a
            FULL OUTER JOIN [dbo].LDF_DATAMART_COLUMN_REF b WITH(NOLOCK)
                ON a.LDF_UID = b.LDF_UID
            WHERE 
                b.LDF_PAGE_SET = 'OTHER'
                OR b.CONDITION_CD IN (
                    SELECT CONDITION_CD 
                    FROM [dbo].LDF_DATAMART_TABLE_REF WITH(NOLOCK)
                    WHERE DATAMART_NAME = 'LDF_FOODBORNE'
            )

            SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF
				@debug = 'true'
				SELECT @Proc_Step_Name AS step, *
				FROM #ALL_FOODBORNE;

			INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES 
				(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


            ------------------------------------------------------------------------------------------------------------------------------------------    

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #ALL_FOODBORNE_SHORT_COL';
            
            IF OBJECT_ID('#ALL_FOODBORNE_SHORT_COL', 'U') IS NOT NULL
			    DROP TABLE #ALL_FOODBORNE_SHORT_COL;

            SELECT 
                INVESTIGATION_KEY,
                INVESTIGATION_LOCAL_ID,
                PROGRAM_JURISDICTION_OID,
                PATIENT_KEY,
                PATIENT_LOCAL_ID,
                DISEASE_NAME,
                DISEASE_CD,
                DATAMART_COLUMN_NM,
                col1  
            INTO #ALL_FOODBORNE_SHORT_COL 
            FROM #ALL_FOODBORNE 
            WHERE data_type IN ('CV', 'ST');

            SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF
				@debug = 'true'
				SELECT @Proc_Step_Name AS step, *
				FROM #ALL_FOODBORNE_SHORT_COL;

			INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES 
				(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


            ------------------------------------------------------------------------------------------------------------------------------------------    

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #ALL_FOODBORNE_TA';
            
            IF OBJECT_ID('#ALL_FOODBORNE_TA', 'U') IS NOT NULL
			    DROP TABLE #ALL_FOODBORNE_TA;

            SELECT 
                INVESTIGATION_KEY,
                INVESTIGATION_LOCAL_ID,
                PROGRAM_JURISDICTION_OID,
                PATIENT_KEY,
                PATIENT_LOCAL_ID,
                DISEASE_NAME,
                DISEASE_CD,
                DATAMART_COLUMN_NM,
                col1  
            INTO #ALL_FOODBORNE_TA
            FROM #ALL_FOODBORNE
            WHERE data_type IN ('LIST_ST');  

            SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF
				@debug = 'true'
				SELECT @Proc_Step_Name AS step, *
				FROM #ALL_FOODBORNE_TA;

			INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES 
				(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


            ------------------------------------------------------------------------------------------------------------------------------------------    

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING ' + @global_temp_foodborne_ta;
            
            EXEC ('IF OBJECT_ID(''tempdb..' + @global_temp_foodborne_ta +''', ''U'')  IS NOT NULL
            BEGIN
                DROP TABLE ' + @global_temp_foodborne_ta +';
            END;')

            SET @count = (SELECT count(*) FROM #ALL_FOODBORNE_TA);

            IF @count > 0
                BEGIN
                    -- Build the comma-separated list of quoted DATAMART_COLUMN_NM values
                    SELECT @ldf_columns = STRING_AGG(QUOTENAME(DATAMART_COLUMN_NM), ',')
                    FROM (
                        SELECT DISTINCT DATAMART_COLUMN_NM 
                        FROM #ALL_FOODBORNE_TA
                    ) AS tmp;

                    IF @ldf_columns != ''
                    BEGIN
                        SET @sql_code = 'SELECT 
                            INVESTIGATION_KEY,
                            INVESTIGATION_LOCAL_ID,
                            PROGRAM_JURISDICTION_OID,
                            PATIENT_KEY,
                            PATIENT_LOCAL_ID,
                            DISEASE_NAME,
                            DISEASE_CD,
                            ' + @ldf_columns + '
                        INTO ' + @global_temp_foodborne_ta +'
                        FROM (
                            SELECT 
                                INVESTIGATION_KEY,
                                INVESTIGATION_LOCAL_ID,
                                PROGRAM_JURISDICTION_OID,
                                PATIENT_KEY,
                                PATIENT_LOCAL_ID,
                                DISEASE_NAME,
                                DISEASE_CD,
                                DATAMART_COLUMN_NM,
                                LEFT(COL1, 8000) AS ANSWERCOL 
                            FROM #ALL_FOODBORNE_TA
                            ) AS SourceTable
                        PIVOT (
                            MAX(ANSWERCOL)
                            FOR DATAMART_COLUMN_NM IN (' + @ldf_columns + ')
                        ) AS PivotTable';
                    END
                    ELSE
                    BEGIN
                        SET @sql_code = 'SELECT 
                            INVESTIGATION_KEY,
                            INVESTIGATION_LOCAL_ID,
                            PROGRAM_JURISDICTION_OID,
                            PATIENT_KEY,
                            PATIENT_LOCAL_ID,
                            DISEASE_NAME,
                            DISEASE_CD
                        INTO ' + @global_temp_foodborne_ta +'
                        FROM #ALL_FOODBORNE_TA';
                    END
                END
                ELSE -- If data does not exist create GLOBAL_TEMP_FOODBORNE_TA table same as #ALL_FOODBORNE_TA
                BEGIN    
                    SET @sql_code = 'SELECT 
                        INVESTIGATION_KEY,
                        INVESTIGATION_LOCAL_ID,
                        PROGRAM_JURISDICTION_OID,
                        PATIENT_KEY,
                        PATIENT_LOCAL_ID,
                        DISEASE_NAME,
                        DISEASE_CD
                    INTO ' + @global_temp_foodborne_ta +'
                    FROM #ALL_FOODBORNE_TA';
                END;

            EXEC sp_executesql @sql_code;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                EXEC('SELECT '''+ @Proc_Step_Name +''' AS step, * FROM ' + @global_temp_foodborne_ta + ';');

            INSERT INTO [dbo].[job_flow_log]
                (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES 
                (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


            ------------------------------------------------------------------------------------------------------------------------------------------    

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING ' + @global_temp_foodborne_short_col;
            
            EXEC ('IF OBJECT_ID(''tempdb..' + @global_temp_foodborne_short_col +''', ''U'')  IS NOT NULL
            BEGIN
                DROP TABLE ' + @global_temp_foodborne_short_col +';
            END;')

            SET @count = (SELECT count(*) FROM #ALL_FOODBORNE_SHORT_COL);

            IF @count > 0
                BEGIN
                    -- Build the comma-separated list of quoted DATAMART_COLUMN_NM values
                    SELECT @ldf_columns = STRING_AGG(QUOTENAME(DATAMART_COLUMN_NM), ',')
                    FROM (
                        SELECT DISTINCT DATAMART_COLUMN_NM 
                        FROM #ALL_FOODBORNE_SHORT_COL
                    ) AS tmp;

                    IF @ldf_columns != ''
                    BEGIN
                        SET @sql_code = 'SELECT 
                            INVESTIGATION_KEY,
                            INVESTIGATION_LOCAL_ID,
                            PROGRAM_JURISDICTION_OID,
                            PATIENT_KEY,
                            PATIENT_LOCAL_ID,
                            DISEASE_NAME,
                            DISEASE_CD,
                            ' + @ldf_columns + '
                        INTO ' + @global_temp_foodborne_short_col +'
                        FROM (
                            SELECT 
                                INVESTIGATION_KEY,
                                INVESTIGATION_LOCAL_ID,
                                PROGRAM_JURISDICTION_OID,
                                PATIENT_KEY,
                                PATIENT_LOCAL_ID,
                                DISEASE_NAME,
                                DISEASE_CD,
                                DATAMART_COLUMN_NM,
                                LEFT(COL1, 8000) AS ANSWERCOL 
                            FROM #ALL_FOODBORNE_SHORT_COL
                            ) AS SourceTable
                        PIVOT (
                            MAX(ANSWERCOL)
                            FOR DATAMART_COLUMN_NM IN (' + @ldf_columns + ')
                        ) AS PivotTable';
                    END
                    ELSE
                    BEGIN
                        SET @sql_code = 'SELECT 
                            INVESTIGATION_KEY,
                            INVESTIGATION_LOCAL_ID,
                            PROGRAM_JURISDICTION_OID,
                            PATIENT_KEY,
                            PATIENT_LOCAL_ID,
                            DISEASE_NAME,
                            DISEASE_CD
                        INTO ' + @global_temp_foodborne_short_col +'
                        FROM #ALL_FOODBORNE_SHORT_COL';
                    END
                END
                ELSE -- If data does not exist create GLOBAL_TEMP_FOODBORNE_SHORT_COL table same as #ALL_FOODBORNE_SHORT_COL
                BEGIN    
                    SET @sql_code = 'SELECT 
                        INVESTIGATION_KEY,
                        INVESTIGATION_LOCAL_ID,
                        PROGRAM_JURISDICTION_OID,
                        PATIENT_KEY,
                        PATIENT_LOCAL_ID,
                        DISEASE_NAME,
                        DISEASE_CD                 
                    INTO ' + @global_temp_foodborne_short_col +'
                    FROM #ALL_FOODBORNE_SHORT_COL';
                END;

            BEGIN TRY
                EXEC sp_executesql @sql_code;
            END TRY
            BEGIN CATCH
                DECLARE @ErrorNumber1 INT = ERROR_NUMBER();
                DECLARE @ErrorLine1 INT = ERROR_LINE();
                DECLARE @ErrorMessage1 NVARCHAR(4000) = ERROR_MESSAGE();

                IF @ErrorNumber1=511
                    BEGIN
                        -- process when error 511
                        EXEC ('IF OBJECT_ID(''tempdb..' + @global_temp_foodborne_short_col +''', ''U'')  IS NOT NULL
                        BEGIN
                            DROP TABLE ' + @global_temp_foodborne_short_col +';
                        END;')

                        SELECT @ldf_columns = STRING_AGG(QUOTENAME(DATAMART_COLUMN_NM), ',')
                        FROM (
                            SELECT DISTINCT TOP 300 DATAMART_COLUMN_NM 
                            FROM #ALL_FOODBORNE_SHORT_COL
                        ) AS tmp;

                        SET @sql_code = 'SELECT 
                            INVESTIGATION_KEY,
                            INVESTIGATION_LOCAL_ID,
                            PROGRAM_JURISDICTION_OID,
                            PATIENT_KEY,
                            PATIENT_LOCAL_ID,
                            DISEASE_NAME,
                            DISEASE_CD,
                            ' + @ldf_columns + '
                        INTO ' + @global_temp_foodborne_short_col +'
                        FROM (
                            SELECT 
                                INVESTIGATION_KEY,
                                INVESTIGATION_LOCAL_ID,
                                PROGRAM_JURISDICTION_OID,
                                PATIENT_KEY,
                                PATIENT_LOCAL_ID,
                                DISEASE_NAME,
                                DISEASE_CD,
                                DATAMART_COLUMN_NM,
                                LEFT(COL1, 8000) AS ANSWERCOL 
                            FROM #ALL_FOODBORNE_TA
                            ) AS SourceTable
                        PIVOT (
                            MAX(ANSWERCOL)
                            FOR DATAMART_COLUMN_NM IN (' + @ldf_columns + ')
                        ) AS PivotTable';

                        EXEC sp_executesql @sql_code;

                    END
                    ELSE
                    THROW @ErrorNumber1, @ErrorMessage1, @ErrorMessage1;
            END CATCH

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                EXEC('SELECT '''+ @Proc_Step_Name +''' AS step, * FROM ' + @global_temp_foodborne_short_col + ';');

            INSERT INTO [dbo].[job_flow_log]
                (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES 
                (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            ------------------------------------------------------------------------------------------------------------------------------------------    

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING ' + @global_temp_foodborne;

            EXECUTE  [dbo].[sp_MERGE_TABLES] 
                @INPUT_TABLE1= @global_temp_foodborne_short_col
                ,@INPUT_TABLE2= @global_temp_foodborne_ta
                ,@OUTPUT_TABLE= @global_temp_foodborne
                ,@JOIN_ON_COLUMN='INVESTIGATION_KEY'
                ,@batch_id= @batch_id
                ,@target_table_name= @global_temp_foodborne;

            SELECT @RowCount_no = @@ROWCOUNT;

            SET @sql_code = 'DELETE FROM ' + @global_temp_foodborne + ' WHERE INVESTIGATION_KEY IS NULL';
            EXEC sp_executesql @sql_code;

            IF
                @debug = 'true'
                EXEC('SELECT '''+ @Proc_Step_Name +''' AS step, * FROM ' + @global_temp_foodborne + ';');

            INSERT INTO [dbo].[job_flow_log]
                (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES 
                (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            ------------------------------------------------------------------------------------------------------------------------------------------    


            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #MISSED_COLS';

            IF OBJECT_ID('#MISSED_COLS') IS NOT NULL
                DROP TABLE #MISSED_COLS;

            SELECT 
                c1.COLUMN_NAME as col_nm,
                'varchar' AS col_data_type, 
                NULL AS col_NUMERIC_PRECISION, 
                NULL AS col_NUMERIC_SCALE, 
                2000 AS col_CHARACTER_MAXIMUM_LENGTH
            INTO #MISSED_COLS    
            FROM 
                tempdb.INFORMATION_SCHEMA.COLUMNS c1
            WHERE 
                c1.TABLE_NAME = @global_temp_foodborne
                AND c1.COLUMN_NAME NOT IN (
                    SELECT c2.COLUMN_NAME 
                    FROM INFORMATION_SCHEMA.COLUMNS c2 
                    WHERE c2.TABLE_SCHEMA = 'dbo' 
                    AND c2.TABLE_NAME = 'LDF_FOODBORNE'
                )
            ORDER BY 
                c1.COLUMN_NAME;    

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #MISSED_COLS;

            INSERT INTO [dbo].[job_flow_log]
                (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES 
                (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            ------------------------------------------------------------------------------------------------------------------------------------------    

            IF EXISTS (SELECT 1 FROM #MISSED_COLS)
            BEGIN
                BEGIN TRANSACTION

                    SET
                        @PROC_STEP_NO = @PROC_STEP_NO + 1;
                    SET
                        @PROC_STEP_NAME = 'ADDING NEW COLUMNS TO TABLE LDF_FOODBORNE';
                    

                    set @sql_code = 'ALTER TABLE dbo.LDF_FOODBORNE ADD ' + (SELECT STRING_AGG( '[' + col_nm + '] ' +  col_data_type +
                    CASE
                        WHEN col_data_type IN ('decimal', 'numeric') THEN '(' + CAST(col_NUMERIC_PRECISION AS NVARCHAR) + ',' + CAST(col_NUMERIC_SCALE AS NVARCHAR) + ')'
                        WHEN col_data_type = 'varchar' THEN '(' +
                            CASE WHEN col_CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(col_CHARACTER_MAXIMUM_LENGTH AS NVARCHAR) END
                        + ')'
                        ELSE ''
                    END, ', ') FROM #MISSED_COLS);

                    EXEC sp_executesql @sql_code;
                    
                    SELECT @RowCount_no = @@ROWCOUNT;

                    IF
                        @debug = 'true'
                        SELECT @Proc_Step_Name AS step, col_nm
                        FROM #MISSED_COLS;

                    INSERT INTO [dbo].[job_flow_log]
                        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
                    VALUES 
                        (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
            
                COMMIT TRANSACTION;  
            END  

            ------------------------------------------------------------------------------------------------------------------------------------------    


            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #COL_LIST TO INSERT';

            IF OBJECT_ID('#COL_LIST') IS NOT NULL
                DROP TABLE #COL_LIST;

            SELECT DISTINCT ic.COLUMN_NAME, ORDINAL_POSITION
            INTO #COL_LIST
            FROM tempdb.INFORMATION_SCHEMA.COLUMNS ic 
            WHERE ic.table_name = @global_temp_foodborne
            AND UPPER(ic.COLUMN_NAME) NOT IN (
                'INVESTIGATION_KEY',
                'INVESTIGATION_LOCAL_ID',
                'PROGRAM_JURISDICTION_OID',
                'PATIENT_KEY',
                'PATIENT_LOCAL_ID',
                'DISEASE_NAME',
                'DISEASE_CD'
            ); --IGNORING DEFAULT COLUMNS;


            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #COL_LIST;

            INSERT INTO [dbo].[job_flow_log]
                (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (
                @batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


            ------------------------------------------------------------------------------------------------------------------------------------------    
            
            
            BEGIN TRANSACTION
            
                SET
                    @PROC_STEP_NO = @PROC_STEP_NO + 1;
                SET
                    @PROC_STEP_NAME = 'DELETING INCOMING RECORDS FROM LDF_FOODBORNE';

                IF OBJECT_ID('#LDF_PHC_UID_DEL') IS NOT NULL
                    DROP TABLE #LDF_PHC_UID_DEL;
                
                SELECT DISTINCT L.INVESTIGATION_KEY 
                INTO #LDF_PHC_UID_DEL
                FROM #LDF_PHC_UID_LIST L 
                INNER JOIN [dbo].LDF_FOODBORNE D 
                    ON D.INVESTIGATION_KEY = L.INVESTIGATION_KEY
                
                DELETE D
                FROM [dbo].LDF_FOODBORNE D 
                INNER JOIN #LDF_PHC_UID_DEL T 
                    ON T.INVESTIGATION_KEY = D.INVESTIGATION_KEY 

                SELECT @RowCount_no = @@ROWCOUNT;

                IF
                    @debug = 'true'
                    SELECT @Proc_Step_Name AS step, *
                    FROM #LDF_PHC_UID_DEL;


                INSERT INTO [dbo].[job_flow_log]
                    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
                VALUES 
                    (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


            COMMIT TRANSACTION; 

            ------------------------------------------------------------------------------------------------------------------------------------------   
            

            BEGIN TRANSACTION

                SET
                    @PROC_STEP_NO = @PROC_STEP_NO + 1;
                SET
                    @PROC_STEP_NAME = 'INSERTING INCOMING RECORDS TO LDF_FOODBORNE';
                
                
                SELECT @ldf_columns = COALESCE(STRING_AGG(CAST(QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY ORDINAL_POSITION), '')
                FROM (SELECT DISTINCT COLUMN_NAME, ORDINAL_POSITION FROM #COL_LIST) AS cols;


                SET @sql_code = 
                'INSERT INTO dbo.LDF_FOODBORNE(
                    INVESTIGATION_KEY,
                    INVESTIGATION_LOCAL_ID,
                    PROGRAM_JURISDICTION_OID,
                    PATIENT_KEY,
                    PATIENT_LOCAL_ID,
                    DISEASE_NAME,
                    DISEASE_CD' + 
                    CASE
                        WHEN @ldf_columns != '' THEN ',' + @ldf_columns
                        ELSE ''
                    END
                + ' )
                SELECT
                    INVESTIGATION_KEY,
                    INVESTIGATION_LOCAL_ID,
                    PROGRAM_JURISDICTION_OID,
                    PATIENT_KEY,
                    PATIENT_LOCAL_ID,
                    DISEASE_NAME,
                    DISEASE_CD'+
                + CASE
                        WHEN @ldf_columns != '' THEN ',' + @ldf_columns
                        ELSE ''
                    END
                +
                '
                FROM ' + @global_temp_foodborne;

                EXEC sp_executesql @sql_code;

                SELECT @RowCount_no = @@ROWCOUNT;

                IF
                    @debug = 'true'
                    EXEC('SELECT '''+ @Proc_Step_Name +''' AS step, * FROM ' + @global_temp_foodborne + ';');

                INSERT INTO [dbo].[job_flow_log]
                    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
                VALUES 
                    (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            COMMIT TRANSACTION;
            

        END
        ------------------------------------------------------------------------------------------------------------------------------------------
        
        --UPDATE LDF DM TO NULLS WHEN THERE IS NO RECORD IN LDF_DIMENSTIONAL
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1; 
        SET @PROC_STEP_NAME = 'UPDATE LDF_FOODBORNE when there is no record in the LDF_DIMENSIONAL_DATA';  
            
        BEGIN TRANSACTION; 

        SET @dynamiccolumnUpdate=''; 
            
        SELECT   @dynamiccolumnUpdate= @dynamiccolumnUpdate + 'TBL.[' +  COLUMN_NAME  + '] = NULL ,' 
        FROM  INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'LDF_FOODBORNE'
            AND COLUMN_NAME NOT IN  ('INVESTIGATION_KEY', 'INVESTIGATION_LOCAL_ID', 'PROGRAM_JURISDICTION_OID', 'PATIENT_KEY', 'PATIENT_LOCAL_ID', 'DISEASE_NAME', 'DISEASE_CD')
            
        SET  @dynamiccolumnUpdate=substring(@dynamiccolumnUpdate,1,len(@dynamiccolumnUpdate)-1) 


            EXEC ('update TBL SET ' +   @dynamiccolumnUpdate + ' FROM  
            dbo.LDF_FOODBORNE TBL inner join  
            dbo.INVESTIGATION INV with (nolock) 
            ON TBL.INVESTIGATION_KEY = INV.INVESTIGATION_KEY
            INNER JOIN #LDF_UID_LIST LDF_UID_LIST ON 
            LDF_UID_LIST.VALUE = INV.CASE_UID
            LEFT JOIN (SELECT DISTINCT INVESTIGATION_UID FROM DBO.LDF_DIMENSIONAL_DATA WITH (NOLOCK)) LDF_DIMENSIONAL_DATA 
            ON LDF_DIMENSIONAL_DATA.INVESTIGATION_UID = INV.CASE_UID
            WHERE LDF_DIMENSIONAL_DATA.INVESTIGATION_UID IS NULL;
        ');

        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 
        
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
        @RowCount_no);  
            
        COMMIT TRANSACTION; 

------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;

        EXEC ('IF OBJECT_ID(''tempdb..' + @global_temp_foodborne_ta +''', ''U'')  IS NOT NULL
            BEGIN
                DROP TABLE ' + @global_temp_foodborne_ta +';
            END;')

        EXEC ('IF OBJECT_ID(''tempdb..' + @global_temp_foodborne_short_col +''', ''U'')  IS NOT NULL
            BEGIN
                DROP TABLE ' + @global_temp_foodborne_short_col +';
            END;')

        EXEC ('IF OBJECT_ID(''tempdb..' + @global_temp_foodborne +''', ''U'')  IS NOT NULL
            BEGIN
                DROP TABLE ' + @global_temp_foodborne +';
            END;')    

        INSERT INTO [dbo].[job_flow_log] 
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);

        ------------------------------------------------------------------------------------------------------------------------------------------

    END TRY

	BEGIN CATCH

		IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        EXEC ('IF OBJECT_ID(''tempdb..' + @global_temp_foodborne_ta +''', ''U'')  IS NOT NULL
            BEGIN
                DROP TABLE ' + @global_temp_foodborne_ta +';
            END;')

        EXEC ('IF OBJECT_ID(''tempdb..' + @global_temp_foodborne_short_col +''', ''U'')  IS NOT NULL
            BEGIN
                DROP TABLE ' + @global_temp_foodborne_short_col +';
            END;')

        EXEC ('IF OBJECT_ID(''tempdb..' + @global_temp_foodborne +''', ''U'')  IS NOT NULL
            BEGIN
                DROP TABLE ' + @global_temp_foodborne +';
            END;')

		-- Construct the error message string with all details:
			DECLARE @FullErrorMessage VARCHAR(8000) =
				'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
				'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
				'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
				'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
				'Error Message: ' + ERROR_MESSAGE();


			INSERT INTO [dbo].[job_flow_log] 
			    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count])
			VALUES 
                (@batch_id, @Dataflow_Name, @Package_Name, 'ERROR', @Proc_Step_no, @Proc_Step_name, @FullErrorMessage, 0);

		return -1 ;

	END CATCH

END;
