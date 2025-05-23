CREATE OR ALTER PROCEDURE [dbo].[sp_nrt_odse_nbs_page_postprocessing]
    @page_id_list nvarchar(max),
    @debug bit = 'false'
AS
BEGIN

    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) AS BIGINT);
    PRINT @batch_id;
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT= 0;
    DECLARE @Proc_Step_Name VARCHAR(200)= '';
	DECLARE @Dataflow_Name VARCHAR(200) = 'nrt_odse_NBS_Page POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_nrt_odse_nbs_page_postprocessing';

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
            , LEFT('ID List-' + @page_id_list, 500));
        
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #PAGEBUILDER_SCHEMA_INIT';

        -- initial temp table
        -- include row_num <= 3 for debugging purposes
        WITH ordered_rdb_metadata AS (
        SELECT
            pg.datamart_nm
            , rdbm.rdb_table_nm
            , rdbm.rdb_column_nm
            , rdbm.user_defined_column_nm
            , rdbm.last_chg_time
            , LEAD(rdbm.user_defined_column_nm) OVER (PARTITION BY pg.datamart_nm, rdbm.rdb_table_nm, rdbm.rdb_column_nm ORDER BY rdbm.last_chg_time DESC) as prev_udcn
            , ROW_NUMBER() OVER (PARTITION BY pg.datamart_nm, rdbm.rdb_table_nm, rdbm.rdb_column_nm ORDER BY rdbm.last_chg_time DESC) as row_num
            , uim.data_type
        FROM dbo.nrt_odse_NBS_page pg
        INNER JOIN dbo.nrt_odse_NBS_rdb_metadata rdbm
            ON rdbm.nbs_page_uid = pg.nbs_page_uid
        INNER JOIN dbo.nrt_odse_NBS_ui_metadata uim
            ON uim.nbs_ui_metadata_uid = rdbm.nbs_ui_metadata_uid
        -- filter on incoming nbs_page_uid values
        where
            pg.nbs_page_uid IN (SELECT value FROM STRING_SPLIT(@page_id_list, ','))
            AND pg.datamart_nm IS NOT NULL
            -- LIKE 'D_INV_%' filter since this is focused on updates to pagebuilder dimensions
            AND rdb_table_nm LIKE 'D_INV_%'
        )
        SELECT 
            datamart_nm
            , rdb_table_nm
            , rdb_column_nm
            , user_defined_column_nm
            , last_chg_time
            , prev_udcn
            , row_num
            , data_type
        INTO #PAGEBUILDER_SCHEMA_INIT
        FROM ordered_rdb_metadata
        WHERE row_num <= 3
        ORDER BY datamart_nm, rdb_table_nm, rdb_column_nm, last_chg_time DESC;


        IF @debug = 'true'
            SELECT * FROM #PAGEBUILDER_SCHEMA_INIT;


        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);

--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #MISSING_DIMENSION_TABLES';

        -- needs to be a distinct list of missing tables so it doesn't try to create the same table multiple times
        WITH distinct_table_cte as (
            SELECT DISTINCT
                psi.rdb_table_nm
            FROM #PAGEBUILDER_SCHEMA_INIT psi
            LEFT JOIN INFORMATION_SCHEMA.TABLES ist
                ON UPPER(psi.rdb_table_nm) = UPPER(ist.TABLE_NAME)
            WHERE ist.TABLE_NAME IS NULL
                AND psi.row_num = 1
        )
        SELECT
            rdb_table_nm
            , 'CREATE TABLE dbo.' + QUOTENAME(rdb_table_nm) + '( 
            ' + rdb_table_nm + '_KEY FLOAT NULL, 
            nbs_case_answer_uid NUMERIC(21,0) 
            );' AS create_statement
        INTO #MISSING_DIMENSION_TABLES
        FROM distinct_table_cte;
        

        IF @debug = 'true'
            SELECT * FROM #MISSING_DIMENSION_TABLES;


        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
          
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'CREATE MISSING PAGEBUILDER DIMENSIONS';

        DECLARE @create_dim_sql NVARCHAR(MAX) = '';


        /*
            Missing dimensions will be initialized with just two columns:
            - The dimension key
            - nbs_case_answer_uid

            The remaining columns (if there are any) will be added by the
            same process in this procedure that adds columns to the already
            existing dimensions.
        */
        SELECT 
            @create_dim_sql = STRING_AGG(create_statement, ' ') 
        FROM #MISSING_DIMENSION_TABLES;

        if @debug = 'true'
            SELECT @Proc_Step_Name, @create_dim_sql;

        IF COALESCE(@create_dim_sql, '') != ''
            exec sp_executesql @create_dim_sql;
        

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
          
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #MISSING_DIMENSION_COLUMNS';

        -- needs to be a distinct list of missing tables so it doesn't try to create the same table multiple times
        WITH distinct_column_cte AS (
            SELECT DISTINCT
                psi.rdb_table_nm
                , psi.rdb_column_nm
                , psi.data_type
            FROM #PAGEBUILDER_SCHEMA_INIT psi
            LEFT JOIN INFORMATION_SCHEMA.TABLES ist
                ON UPPER(psi.rdb_table_nm) = UPPER(ist.TABLE_NAME)
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(psi.rdb_table_nm) = UPPER(isc.TABLE_NAME)
                AND UPPER(psi.rdb_column_nm) = UPPER(isc.COLUMN_NAME)
            WHERE ist.TABLE_NAME IS NOT NULL AND isc.COLUMN_NAME IS NULL
                            AND psi.row_num = 1
        )
        SELECT
            rdb_table_nm
            , rdb_column_nm
            , data_type
            , 'ALTER TABLE dbo.' + QUOTENAME(rdb_table_nm) + ' ADD ' + QUOTENAME(rdb_column_nm) + ' ' 
                + IIF(data_type = 'DATE', 'DATE', 'VARCHAR(2000)') + ' NULL; ' AS alter_statement
        INTO #MISSING_DIMENSION_COLUMNS
        FROM distinct_column_cte;
        

        IF @debug = 'true'
            SELECT * FROM #MISSING_DIMENSION_COLUMNS;


        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
          
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'ADD MISSING COLUMNS TO PAGEBUILDER DIMENSIONS';

        DECLARE @alter_dim_sql NVARCHAR(MAX) = '';

        SELECT 
            @alter_dim_sql = STRING_AGG(alter_statement, ' ') 
        FROM #MISSING_DIMENSION_COLUMNS;

        if @debug = 'true'
            SELECT @Proc_Step_Name, @alter_dim_sql;

        IF COALESCE(@alter_dim_sql, '') != ''
            exec sp_executesql @alter_dim_sql;
        

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
          
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'CREATE #UPDATED_COL_NAMES';



        SELECT 
            psi.datamart_nm
            , psi.user_defined_column_nm
            , psi.prev_udcn
            , 'EXEC sys.sp_rename N''DM_INV_' + UPPER(psi.datamart_nm) + '.' + UPPER(psi.prev_udcn) + ''', N''' + UPPER(psi.user_defined_column_nm) + ''', ''COLUMN''; ' AS rename_statement
        INTO #UPDATED_COL_NAMES
        FROM #PAGEBUILDER_SCHEMA_INIT psi
        INNER JOIN INFORMATION_SCHEMA.COLUMNS isc
            ON 'DM_INV_' + UPPER(psi.datamart_nm) = UPPER(isc.TABLE_NAME)
                AND UPPER(psi.prev_udcn) = UPPER(isc.COLUMN_NAME)
                -- We only want the scenario when the new user_defined_column_nm (udcn) is different from the previous
                -- if the previous udcn is null, then default it to the value for the current udcn, which excludes it
                AND psi.user_defined_column_nm != COALESCE(psi.prev_udcn, psi.user_defined_column_nm)
        WHERE psi.row_num = 1;

        if @debug = 'true'
            SELECT @Proc_Step_Name, * FROM #UPDATED_COL_NAMES;

        

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
          
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'ADD MISSING COLUMNS TO PAGEBUILDER DIMENSIONS';

        DECLARE @update_col_nm_sql NVARCHAR(MAX) = '';

        SELECT 
            @update_col_nm_sql = STRING_AGG(rename_statement, ' ') 
        FROM #UPDATED_COL_NAMES;

        if @debug = 'true'
            SELECT @Proc_Step_Name, @update_col_nm_sql;

        IF COALESCE(@update_col_nm_sql, '') != ''
            exec sp_executesql @update_col_nm_sql;
        

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
              
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'UPDATE DYNAMIC DATAMART SCHEMA';

        DECLARE @update_dyn_dm_sql NVARCHAR(MAX) = '';

        WITH distinct_datamart_cte AS (
            SELECT DISTINCT
                datamart_nm
            FROM #PAGEBUILDER_SCHEMA_INIT
        )
        SELECT 
            @update_dyn_dm_sql = STRING_AGG('EXEC dbo.sp_dyn_dm_main_postprocessing ''' + datamart_nm + ''', '''';', ' ') 
        FROM distinct_datamart_cte;

        if @debug = 'true'
            SELECT @Proc_Step_Name, @update_dyn_dm_sql;

        IF COALESCE(@update_dyn_dm_sql, '') != ''
            exec sp_executesql @update_dyn_dm_sql;
        

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
              
--------------------------------------------------------------------------------------------------------

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

