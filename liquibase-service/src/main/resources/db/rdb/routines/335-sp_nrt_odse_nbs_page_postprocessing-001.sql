IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_nrt_odse_nbs_page_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_nrt_odse_nbs_page_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_nrt_odse_nbs_page_postprocessing]
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
        WITH ordered_rdb_metadata AS (
        SELECT
            pg.datamart_nm
            , pg.nbs_page_uid
            , rdbm.nbs_ui_metadata_uid
            , rdbm.rdb_table_nm
            , rdbm.rdb_column_nm
            , COALESCE(rdbm.user_defined_column_nm, CONCAT('COL_NAME_REMOVED_VIA_UI_', rdbm.nbs_ui_metadata_uid)) as user_defined_column_nm
            , rdbm.last_chg_time
            , uim.data_type
            , rdbm.block_pivot_nbr
        FROM dbo.nrt_odse_NBS_page pg
        INNER JOIN dbo.v_nrt_odse_NBS_rdb_metadata_recent rdbm
            ON rdbm.nbs_page_uid = pg.nbs_page_uid
        INNER JOIN dbo.nrt_odse_NBS_ui_metadata uim
            ON uim.nbs_ui_metadata_uid = rdbm.nbs_ui_metadata_uid
        -- filter on incoming nbs_page_uid values
        where
            pg.nbs_page_uid IN (SELECT value FROM STRING_SPLIT(@page_id_list, ','))
            AND pg.datamart_nm IS NOT NULL
        )
        SELECT 
            datamart_nm
            , nbs_page_uid
            , nbs_ui_metadata_uid
            , rdb_table_nm
            , rdb_column_nm
            , user_defined_column_nm
            , last_chg_time
            , data_type
            , block_pivot_nbr
        INTO #PAGEBUILDER_SCHEMA_INIT
        FROM ordered_rdb_metadata
        ORDER BY datamart_nm, rdb_table_nm, rdb_column_nm, last_chg_time DESC;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 



        IF @debug = 'true'
            SELECT * FROM #PAGEBUILDER_SCHEMA_INIT;


        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);

--------------------------------------------------------------------------------------------------------

        declare @backfill_list nvarchar(max);
        SET @backfill_list =
        (
          SELECT string_agg(t.value, ',')
          FROM (SELECT distinct TRIM(value) AS value FROM STRING_SPLIT(@page_id_list, ',')) t
                    left join #PAGEBUILDER_SCHEMA_INIT tmp
                    on tmp.nbs_page_uid = t.value
                    WHERE tmp.nbs_page_uid is null
        );
        IF @backfill_list IS NOT NULL
        BEGIN
        SELECT
            0 AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            'Error' AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            'Missing NRT Record: sp_nrt_odse_nbs_page_postprocessing' AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=1;
        RETURN;
        END
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATE #METADATA_TABLE_RECORDS';

        -- COUNT OF RECORDS IN DYN DM COLUMN METADATA TABLE 
        -- If 0, a load of the original table state must be done
        SELECT
            psi.nbs_page_uid
            , SUM(CASE WHEN md.nbs_ui_metadata_uid IS NULL THEN 0 ELSE 1 END) AS record_count
            INTO #METADATA_TABLE_RECORDS
        FROM (SELECT DISTINCT nbs_page_uid FROM #PAGEBUILDER_SCHEMA_INIT) psi
        LEFT JOIN dbo.nrt_dyn_dm_column_metadata md
            ON psi.nbs_page_uid = md.nbs_page_uid
        GROUP BY psi.nbs_page_uid;
        
        
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT * FROM #METADATA_TABLE_RECORDS;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
          
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATE #ORIGINAL_DATAMART_STATE';

        /*
            Generates the oldest state for the datamart as determined by what has been synced
            into dbo.nrt_odse_NBS_rdb_metadata. This should generate the current state.

            1. When RTR is deployed, we get a sync from NBS_ODSE.dbo.NBS_rdb_metadata into
                dbo.nrt_odse_NBS_rdb_metadata (consider this the original state).
            2. A given page gets X many updates, each time a new set of metadata enters the nrt table
            3. This stored procedure runs (dynamic datamart schema has yet to be updated)
            4. This table captures the state from our original sync and is inserted into
                dbo.nrt_dyn_dm_column_metadata
            5. Each time this procedure runs, it checks and updates dbo.nrt_dyn_dm_column_metadata
                to keep track of user defined column names based on nbs_ui_metadata_uid
                a. This is the only way to ensure that the correct columns are being renamed by this
                    procedure
        */

        WITH ordered_rdb_metadata AS (
        SELECT
            pg.nbs_page_uid
            , rdbm.nbs_ui_metadata_uid
            , rdbm.user_defined_column_nm
            , RANK() OVER (PARTITION BY pg.datamart_nm ORDER BY rdbm.last_chg_time asc) as row_num
            , rdbm.block_pivot_nbr
        FROM dbo.nrt_odse_NBS_page pg
        INNER JOIN dbo.nrt_odse_NBS_rdb_metadata rdbm
            ON rdbm.nbs_page_uid = pg.nbs_page_uid
        where
            pg.nbs_page_uid IN (SELECT nbs_page_uid FROM #METADATA_TABLE_RECORDS WHERE record_count = 0)
            AND pg.datamart_nm IS NOT NULL
        )
        SELECT 
            nbs_page_uid
            , nbs_ui_metadata_uid
            , user_defined_column_nm
            , block_pivot_nbr
        INTO #ORIGINAL_DATAMART_STATE
        FROM ordered_rdb_metadata
        where row_num = 1;
        
        
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT * FROM #ORIGINAL_DATAMART_STATE;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
          
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'INSERT ORIGINAL STATE INTO dbo.nrt_dyn_dm_column_metadata';

        -- generates the oldest state for the datamart
        INSERT INTO dbo.nrt_dyn_dm_column_metadata (
            nbs_page_uid
            , nbs_ui_metadata_uid
            , user_defined_column_nm
            , block_pivot_nbr
        )
        SELECT
            nbs_page_uid
            , nbs_ui_metadata_uid
            , user_defined_column_nm
            , block_pivot_nbr
        FROM #ORIGINAL_DATAMART_STATE;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 


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
                AND rdb_table_nm LIKE 'D_INV%'
        )
        SELECT
            rdb_table_nm
            , 'CREATE TABLE dbo.' + QUOTENAME(rdb_table_nm) + '( 
            ' + rdb_table_nm + '_KEY FLOAT NULL, 
            nbs_case_answer_uid NUMERIC(21,0) 
            );' AS create_statement
        INTO #MISSING_DIMENSION_TABLES
        FROM distinct_table_cte;
        
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

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
            @create_dim_sql = STRING_AGG(CAST(create_statement AS NVARCHAR(MAX)), ' ') 
        FROM #MISSING_DIMENSION_TABLES;

        if @debug = 'true'
            SELECT @Proc_Step_Name, @create_dim_sql;

        IF COALESCE(@create_dim_sql, '') != ''
            exec sp_executesql @create_dim_sql;
        
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

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
                AND psi.rdb_table_nm LIKE 'D_INV%'
        )
        SELECT
            rdb_table_nm
            , rdb_column_nm
            , data_type
            , 'ALTER TABLE dbo.' + QUOTENAME(rdb_table_nm) + ' ADD ' + QUOTENAME(rdb_column_nm) + ' ' 
                + IIF(data_type = 'DATE', 'DATE', 'VARCHAR(2000)') + ' NULL; ' AS alter_statement
        INTO #MISSING_DIMENSION_COLUMNS
        FROM distinct_column_cte;
        
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

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
            @alter_dim_sql = STRING_AGG(CAST(alter_statement AS NVARCHAR(MAX)), ' ') 
        FROM #MISSING_DIMENSION_COLUMNS;

        if @debug = 'true'
            SELECT @Proc_Step_Name, @alter_dim_sql;

        IF COALESCE(@alter_dim_sql, '') != ''
            exec sp_executesql @alter_dim_sql;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 


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
            , psi.user_defined_column_nm as new_udcn
            , md.user_defined_column_nm as current_udcn
            , psi.block_pivot_nbr
            , psi.rdb_table_nm
        INTO #UPDATED_COL_NAMES
        FROM #PAGEBUILDER_SCHEMA_INIT psi
        INNER JOIN dbo.nrt_dyn_dm_column_metadata md
            ON psi.nbs_page_uid = md.nbs_page_uid AND psi.nbs_ui_metadata_uid = md.nbs_ui_metadata_uid
                -- We only want the scenario when the new user_defined_column_nm (udcn) is different from the current
                AND psi.user_defined_column_nm != COALESCE(md.user_defined_column_nm, psi.user_defined_column_nm);

        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        if @debug = 'true'
            SELECT @Proc_Step_Name, * FROM #UPDATED_COL_NAMES;


        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
          
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'CREATE #INV_REPEAT_COL_UPDATE';

        declare @max_pivot_nbr INTEGER;
        SELECT @max_pivot_nbr = (select max(BLOCK_PIVOT_NBR) from #UPDATED_COL_NAMES);

        with number_list as (
            SELECT 1 AS num
            UNION ALL
            SELECT num + 1
            FROM number_list
            WHERE num < @max_pivot_nbr
        ),
        expanded_col_list AS (
            SELECT
                ucn.datamart_nm
                , CONCAT(ucn.new_udcn, '_', ce.suffix) AS new_udcn
                , CONCAT(ucn.current_udcn, '_', ce.suffix) AS current_udcn
            FROM #UPDATED_COL_NAMES ucn
            LEFT JOIN (
                SELECT CAST('ALL' AS VARCHAR(50)) as suffix
                UNION ALL
                SELECT CAST(num AS VARCHAR(50)) FROM number_list) ce
                on COALESCE(TRY_CAST(ce.suffix as INTEGER), 999999) <= ucn.block_pivot_nbr OR ce.suffix = 'ALL'
            WHERE ucn.rdb_table_nm = 'D_INVESTIGATION_REPEAT'
        )
        SELECT 
            datamart_nm
            , new_udcn
            , current_udcn
            , CONCAT(current_udcn, '_', 'PLACEHOLDERFORSCHEMAUPDATE') as placeholder_udcn
        INTO #INV_REPEAT_COL_UPDATE
        FROM expanded_col_list;
    
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        if @debug = 'true'
            SELECT @Proc_Step_Name, * FROM #INV_REPEAT_COL_UPDATE;


        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
          
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'CREATE #PAGEBUILDER_COL_UPDATE';


        SELECT 
            datamart_nm
            , new_udcn
            , current_udcn
            , CONCAT(current_udcn, '_', 'PLACEHOLDERFORSCHEMAUPDATE') as placeholder_udcn
        INTO #PAGEBUILDER_COL_UPDATE
        FROM #UPDATED_COL_NAMES 
        WHERE rdb_table_nm LIKE 'D_INV_%';

        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        if @debug = 'true'
            SELECT @Proc_Step_Name, * FROM #INV_REPEAT_COL_UPDATE;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
          
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'CREATE #COLUMN_UPDATE_FINAL';


        /*
            placeholder_udcn:
                This column is a temporary renaming that is used in case we need to swap the names of two
                columns at the same time. This way, we do not run into situations where we get an error
                trying to assign a duplicate column name
        */
        WITH column_update_union AS (
            SELECT 
                datamart_nm
                , new_udcn
                , current_udcn
                , placeholder_udcn
            FROM #INV_REPEAT_COL_UPDATE
            UNION ALL
            SELECT
                datamart_nm
                , new_udcn
                , current_udcn
                , placeholder_udcn
            FROM #PAGEBUILDER_COL_UPDATE
        )
        SELECT 
            datamart_nm
            , new_udcn
            , current_udcn
            , 'EXEC sys.sp_rename N''DM_INV_' + UPPER(psi.datamart_nm) + '.' + UPPER(current_udcn) + ''', N''' + UPPER(placeholder_udcn) + ''', ''COLUMN''; ' AS rename_curr_to_placeholder_statement
            , 'EXEC sys.sp_rename N''DM_INV_' + UPPER(psi.datamart_nm) + '.' + UPPER(placeholder_udcn) + ''', N''' + UPPER(new_udcn) + ''', ''COLUMN''; ' AS rename_placeholder_to_new_statement
        INTO #COLUMN_UPDATE_FINAL
        FROM column_update_union psi
        INNER JOIN INFORMATION_SCHEMA.COLUMNS isc
            ON 'DM_INV_' + UPPER(psi.datamart_nm) = UPPER(isc.TABLE_NAME)
                AND UPPER(current_udcn) = UPPER(isc.COLUMN_NAME);

        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 


        if @debug = 'true'
            SELECT @Proc_Step_Name, * FROM #COLUMN_UPDATE_FINAL;


        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
          
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'RENAME DYNAMIC DATAMART COLUMN NAMES';

        DECLARE @curr_to_placeholder_sql NVARCHAR(MAX) = '';
        DECLARE @placeholder_to_new_sql NVARCHAR(MAX) = '';


        SELECT 
            @curr_to_placeholder_sql = STRING_AGG(CAST(rename_curr_to_placeholder_statement AS NVARCHAR(MAX)), ' ') 
        FROM #COLUMN_UPDATE_FINAL;

        SELECT 
            @placeholder_to_new_sql = STRING_AGG(CAST(rename_placeholder_to_new_statement AS NVARCHAR(MAX)), ' ') 
        FROM #COLUMN_UPDATE_FINAL;

        if @debug = 'true'
            SELECT @Proc_Step_Name, @curr_to_placeholder_sql, @placeholder_to_new_sql;

        IF COALESCE(@curr_to_placeholder_sql, '') != ''
            exec sp_executesql @curr_to_placeholder_sql;

        IF COALESCE(@placeholder_to_new_sql, '') != ''
            exec sp_executesql @placeholder_to_new_sql;
        

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
            @update_dyn_dm_sql = STRING_AGG(CAST('EXEC dbo.sp_dyn_dm_main_postprocessing ''' + datamart_nm + ''', '''';' AS NVARCHAR(MAX)), ' ') 
        FROM distinct_datamart_cte;

        if @debug = 'true'
            SELECT @Proc_Step_Name, @update_dyn_dm_sql;

        IF COALESCE(@update_dyn_dm_sql, '') != ''
            exec sp_executesql @update_dyn_dm_sql;
        

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
              
--------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'UPDATE dbo.nrt_dyn_dm_column_metadata';


            UPDATE nrt
                SET
                    nrt.user_defined_column_nm = psi.user_defined_column_nm
                    , nrt.block_pivot_nbr = psi.block_pivot_nbr
            FROM dbo.nrt_dyn_dm_column_metadata nrt
                INNER JOIN #PAGEBUILDER_SCHEMA_INIT psi
                ON nrt.nbs_page_uid = psi.nbs_page_uid AND nrt.nbs_ui_metadata_uid = psi.nbs_ui_metadata_uid;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 
        
        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);

        COMMIT TRANSACTION;
              
--------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'INSERT INTO dbo.nrt_dyn_dm_column_metadata';


        INSERT INTO dbo.nrt_dyn_dm_column_metadata (
            nbs_page_uid
            , nbs_ui_metadata_uid
            , user_defined_column_nm
            , block_pivot_nbr
        )
        SELECT
            psi.nbs_page_uid
            , psi.nbs_ui_metadata_uid
            , psi.user_defined_column_nm
            , psi.block_pivot_nbr
        FROM #PAGEBUILDER_SCHEMA_INIT psi 
            LEFT JOIN dbo.nrt_dyn_dm_column_metadata nrt
            ON nrt.nbs_page_uid = psi.nbs_page_uid AND nrt.nbs_ui_metadata_uid = psi.nbs_ui_metadata_uid
        WHERE nrt.nbs_ui_metadata_uid IS NULL;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 
        
        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);

        COMMIT TRANSACTION;
              
--------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);
    
-------------------------------------------------------------------------------------------
		SELECT
            CAST(NULL AS BIGINT) AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            CAST(NULL AS VARCHAR(30)) AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            CAST(NULL AS VARCHAR(200)) AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=0;
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

        SELECT
            0 AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            'Error' AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            @FullErrorMessage AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=1;

    END CATCH

END;

