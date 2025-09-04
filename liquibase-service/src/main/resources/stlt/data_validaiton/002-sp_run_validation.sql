IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_run_validation]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_run_validation]
END
GO 
/**
    Stored Procedure: dbo.sp_run_validation

    Purpose:
    Validates a given RDB table against its corresponding ODSE table, with optional inclusion of job flow log errors,
    and can optionally update the ODSE table's last_chg_time for relevant records.

    Parameters:
    @entity           VARCHAR(100)  - The RDB table or entity to validate against the ODSE table.
    @check_log        BIT            - 1 = include job_flow_log error info, 0 = only run validation query.
    @topn_errors      SMALLINT       - Optional; when provided, limits to TOP N latest errors; 
                                       when NULL, retrieves all errors from the last @lookback days (default 10).
    @initiate_update  BIT            - 0 = update the ODSE table (last_chg_time) for rows corresponding to validated UIDs.
    @from_date        DATE           - Optional; updates only rows where last_chg_time >= @from_date. Defaults to current date.

    Logic Overview:
    1. Handle for Dynamic Datamarts  Dependencies:
        - Expanded rows for each DM_INV_* datamart instead of just the placeholder one.
        - Creates a temporary table that gets used downstream

    2. Resolve Dependencies:
        - Uses a recursive CTE to expand all dependencies for the given @entity.
        - Produces an ordered list of entities to process (parents before children).

    3. Iterate Entities:
        - For each entity:
            • Loads the validation query and associated dataflows.
            • Executes the validation query, comparing ODSE table data against RDB, NRT, and Backfill/Retry tables.
            • If @check_log = 1, joins validation results to recent job_flow_log errors filtered by dataflows, Status_Type = 'ERROR', 
              and either TOP N or last X days.
            • Aggregates errors per UID into a JSON array (error_log_json).

    4. Collate Results:
        - Inserts results into a temporary table #results with a unified schema including error_log_json.
        - Maintains #root_uids for top-level entity UIDs.

    5. Conditional Update (if @initiate_update = 1):
        - Parses the ODSE table name and primary key from the validation query.
        - Updates only rows in the ODSE table where the PK matches UIDs in #results.
        - Sets last_chg_time to last_chg_time+2 mins for these rows.

*/   
CREATE PROCEDURE dbo.sp_run_validation
(
    @entity    VARCHAR(100), 
    @check_log BIT = 0,
    @topn_errors  SMALLINT = NULL,
    @initiate_update BIT = 0,
    @from_date      DATE = NULL
)
AS
BEGIN
SET NOCOUNT ON;

DECLARE @validation_query NVARCHAR(MAX);
DECLARE @sql NVARCHAR(MAX);
DECLARE @dataflows VARCHAR(500);
DECLARE @lookback INT = 10;
DECLARE @odse_table SYSNAME;
    
BEGIN TRY

    ----------------------------------------------------------------------
    -- 1. Resolve dependencies (recursive CTE)
    ----------------------------------------------------------------------

    -- 1. Create the temp table with same structure
    CREATE TABLE #JOB_VALIDATION_CONFIG (
        rdb_entity varchar(500),
        dataflows varchar(500),
        validation_query nvarchar(max),
        dependencies nvarchar(max) default NULL
    );

    -- 2. Insert all rows except the placeholder DM_INV_<DATAMART_NM>
    INSERT INTO #JOB_VALIDATION_CONFIG (rdb_entity, dataflows, validation_query, dependencies)
    SELECT rdb_entity, dataflows, validation_query, dependencies
    FROM dbo.JOB_VALIDATION_CONFIG
    WHERE rdb_entity <> 'DM_INV_<DATAMART_NM>';

    -- 3. Insert dynamic DM_INV_* rows
    INSERT INTO #JOB_VALIDATION_CONFIG (rdb_entity, dataflows, validation_query, dependencies)
    SELECT 
        'DM_INV_' + DATAMART_NM AS rdb_entity,
        'DYNAMIC_DATAMART POST-Processing' AS dataflows,
        REPLACE(
            REPLACE(jvc.validation_query, '<DATAMART_NM>', DATAMART_NM),
            '<DISEASE_GRP_CD>', DISEASE_GRP_CD
        ) AS validation_query,
        jvc.dependencies
    FROM
    (select distinct DATAMART_NM, DISEASE_GRP_CD FROM 
        dbo.INV_SUMM_DATAMART isd WITH (nolock) 
        INNER JOIN 
            dbo.CONDITION c WITH (nolock)  
            ON isd.DISEASE_CD = c.CONDITION_CD
        INNER JOIN 
            dbo.V_NRT_NBS_INVESTIGATION_RDB_TABLE_METADATA inv_meta 
            ON c.DISEASE_GRP_CD = inv_meta.FORM_CD
    ) dminfo
    CROSS JOIN (select * from dbo.JOB_VALIDATION_CONFIG where rdb_entity = 'DM_INV_<DATAMART_NM>')jvc
    ;

    ----------------------------------------------------------------------
    -- 2. Resolve dependencies (recursive CTE)
    ----------------------------------------------------------------------
    ;WITH dep_cte AS (
        SELECT r.rdb_entity, r.dependencies, 0 AS level
        FROM #JOB_VALIDATION_CONFIG r
        WHERE r.rdb_entity = @entity

        UNION ALL

        SELECT c.rdb_entity, c.dependencies, p.level + 1
        FROM dep_cte p
        JOIN #JOB_VALIDATION_CONFIG c
          ON EXISTS (
             SELECT 1 FROM STRING_SPLIT(p.dependencies, ',') d
             WHERE d.value = c.rdb_entity
          )
    )
    SELECT rdb_entity, MAX(level) AS level
    INTO #entities_to_run
    FROM dep_cte
    GROUP BY rdb_entity;

    select * from  #entities_to_run;

    ----------------------------------------------------------------------
    -- 3. Cursor/loop through entities in dependency order
    ----------------------------------------------------------------------
    DECLARE @curr_entity VARCHAR(500), @level INT;

    DECLARE entity_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT rdb_entity, level
    FROM #entities_to_run
    ORDER BY level;

    CREATE TABLE #results (
    rdb_entity VARCHAR(500),
    uid BIGINT,
    local_id VARCHAR(100),
    update_time DATETIME,
    record_status_cd VARCHAR(20),
    record_in_nrt_table VARCHAR(5),
    record_in_nrt_key_table VARCHAR(5),
    retry_list NVARCHAR(MAX),
    retry_job_batch_id BIGINT,
    retry_count INT,
    retry_error_desc NVARCHAR(MAX),
    error_log_json NVARCHAR(MAX)
    );

    CREATE TABLE #root_uids (uid BIGINT PRIMARY KEY);

  

    OPEN entity_cursor;
    FETCH NEXT FROM entity_cursor INTO @curr_entity, @level;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- 1. Get validation query and dataflows for the entity
        SELECT 
            @validation_query = validation_query,
            @dataflows = dataflows
        FROM #JOB_VALIDATION_CONFIG
        WHERE rdb_entity = @curr_entity;

        IF @validation_query IS NULL
        BEGIN
            RAISERROR('No validation query found for entity %s', 16, 1, @curr_entity);
            CLOSE entity_cursor;
            DEALLOCATE entity_cursor;
            RETURN;
        END

        PRINT '--- Loop Iteration ---';
        PRINT 'Current Entity: ' + ISNULL(@curr_entity, '<NULL>');
        PRINT 'Level: ' + CAST(@level AS VARCHAR(10));
        --PRINT 'Validation Query: ' + ISNULL(@validation_query, '<NULL>');
        PRINT 'Dataflows: ' + ISNULL(@dataflows, '<NULL>');



        IF @check_log = 0
        BEGIN
            -- Only use validation query
            SET @sql = 'select v.*, error_log_json as NULL from ('+@validation_query+') v';
        END
        ELSE
        BEGIN
            -- 2. Build dynamic SQL that:
            --    - Runs validation query
            --    - Appends latest N errors flattened as JSON array
            SET @sql = '
            ;WITH validation_cte AS (
                SELECT * FROM (' + @validation_query + ' ) base '+
                CASE
                    WHEN EXISTS (SELECT 1 FROM #root_uids) THEN ' WHERE  uid IN (SELECT uid FROM #root_uids)'
                    ELSE ''
                END +
                ' 
            ),
            error_cte AS (
                SELECT
                    jfl.batch_id,
                    jfl.Dataflow_Name,
                    jfl.package_Name,
                    jfl.Error_Description,
                    jfl.Step_Number,
                    jfl.Step_Name,
                    jfl.create_dttm,
                    vstr.uid
                FROM dbo.JOB_FLOW_LOG jfl WITH (NOLOCK)
                INNER JOIN STRING_SPLIT(@dataflows, '','') df ON jfl.Dataflow_Name = df.value
                INNER JOIN (
                    SELECT DISTINCT CAST(uid AS VARCHAR(50)) AS uid_str, uid
                    FROM validation_cte
                ) vstr
                    ON jfl.Msg_Description1 LIKE ''%'' + vstr.uid_str + ''%''
                WHERE jfl.Status_Type = ''ERROR''
                ' + CASE 
                        WHEN @topn_errors IS NULL 
                        THEN 'AND jfl.create_dttm >= DATEADD(DAY, -@lookback, SYSDATETIME())' 
                        ELSE '' 
                    END + '
            )
            SELECT 
                ''' + @curr_entity + ''' AS rdb_entity,
                v.*,
                (
                    SELECT ' + 
                        CASE 
                            WHEN @topn_errors IS NOT NULL THEN 'TOP (@topn_errors)' 
                            ELSE '' 
                        END + '
                        e.batch_id,
                        e.Dataflow_Name,
                        e.package_Name,
                        e.Error_Description AS Latest_Error_Info,
                        e.Step_Number AS Latest_Step_Number,
                        e.Step_Name AS Latest_Step,
                        e.create_dttm AS Latest_Step_Execution_Time
                    FROM error_cte e
                    WHERE e.uid = v.uid
                    ORDER BY e.batch_id DESC, e.create_dttm DESC
                    FOR JSON PATH
                ) AS error_log_json
            FROM validation_cte v;
            ';
        END

        PRINT 'SQL statement: ' + @sql;
        PRINT 'Parameter @dataflows: ' + ISNULL(@dataflows, '<NULL>');

        -- 3. Execute dynamic SQL with parameters
        IF @check_log = 0
        BEGIN
            INSERT INTO #results
            EXEC sp_executesql 
                @sql, 
                N'@dataflows VARCHAR(500)', 
                @dataflows = @dataflows;
        END
        ELSE
        BEGIN
            IF @topn_errors IS NOT NULL
            BEGIN
                INSERT INTO #results
                EXEC sp_executesql 
                    @sql, 
                    N'@dataflows VARCHAR(500), @topn_errors SMALLINT, @lookback INT', 
                    @dataflows = @dataflows, 
                    @topn_errors = @topn_errors,
                    @lookback = @lookback;
            END
            ELSE
            BEGIN
                INSERT INTO #results
                EXEC sp_executesql 
                    @sql, 
                    N'@dataflows VARCHAR(500), @lookback INT', 
                    @dataflows = @dataflows,
                    @lookback = @lookback;
            END
        END
        
        IF @level= 0
        BEGIN
        INSERT INTO #root_uids (uid)
            SELECT DISTINCT uid FROM #results;
        END

        FETCH NEXT FROM entity_cursor INTO @curr_entity, @level;
    END

    CLOSE entity_cursor;
    DEALLOCATE entity_cursor;

    ----------------------------------------------------------------------
    -- 4. Collated result
    ----------------------------------------------------------------------
    SELECT TOP 1000 * FROM #results;

    ----------------------------------------------------------------------
    -- 5. If initiate_update = 1, parse odse table name and run UPDATE
    ----------------------------------------------------------------------

    IF @initiate_update = 1
    BEGIN
        SET NOCOUNT OFF;
        DECLARE @RowCount_no INT;
        DECLARE @odse_pk_column NVARCHAR(MAX);

        -- Default from_date to today if not provided
        IF @from_date IS NULL
            SET @from_date = CAST(SYSDATETIME() AS DATE);

        IF @entity = 'D_CASE_MANAGEMENT' 
            SET @entity = 'INVESTIGATION'
        
        ;WITH cte AS (
            SELECT 
                CHARINDEX('nbs_odse.dbo.', validation_query) AS startpos, 
                validation_query, 
                rdb_entity 
            FROM #JOB_VALIDATION_CONFIG
            WHERE rdb_entity = @entity
        )
        SELECT TOP 1 @odse_table = SUBSTRING(
            validation_query, 
            startpos + LEN('nbs_odse.dbo.'), 
            CHARINDEX(' ', validation_query, startpos + LEN('nbs_odse.dbo.')) - (startpos + LEN('nbs_odse.dbo.'))
        ) 
        FROM cte;
        IF @odse_table IS NOT NULL
        BEGIN
            ;WITH PKCols AS (
                SELECT
                    c.name AS column_name,
                    ic.key_ordinal
                FROM nbs_odse.sys.indexes i
                JOIN nbs_odse.sys.index_columns ic
                ON i.object_id = ic.object_id AND i.index_id = ic.index_id
                JOIN nbs_odse.sys.columns c
                ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                WHERE i.is_primary_key = 1 AND ic.key_ordinal = 1
                AND i.object_id = OBJECT_ID(N'nbs_odse.dbo.' + @odse_table)
            )
            SELECT @odse_pk_column =
                STRING_AGG(QUOTENAME(column_name), ',')
            FROM PKCols;

            PRINT 'ODSE table: nbs_odse.dbo.' + ISNULL(@odse_table,'(null)')
                + ' | PK: ' + ISNULL(@odse_pk_column,'(none)');
                
            DECLARE @update_sql NVARCHAR(MAX) = N'
            UPDATE tgt
            SET last_chg_time = dateadd(minute, 2, last_chg_time)
            FROM nbs_odse.dbo.' + QUOTENAME(@odse_table) + ' AS tgt
            INNER JOIN #results r
                ON tgt.' + @odse_pk_column + ' = r.uid
            WHERE tgt.last_chg_time >= @from_date;';  
            
            PRINT 'SQL statement: ' + @update_sql;
            PRINT 'Parameter @from_date: ' + ISNULL(cast(@from_date as varchar) , '<NULL>');
            
            EXEC sp_executesql @update_sql, N'@from_date DATE', @from_date=@from_date;
            SELECT @RowCount_no = @@ROWCOUNT;
            PRINT 'Updated '+CAST(@RowCount_no AS VARCHAR(20)) +' rows in table: nbs_odse.dbo.' + @odse_table;
        END
        ELSE
        BEGIN
            RAISERROR('Could not find nbs_odse.dbo.<table> in validation query for entity %s', 16, 1, @entity);
            RETURN;
        END

    END
END TRY
BEGIN CATCH
    -- Close cursor only if it exists and is open
    IF CURSOR_STATUS('local', 'entity_cursor') >= -1
    BEGIN
        IF CURSOR_STATUS('local', 'entity_cursor') > -1
            CLOSE entity_cursor;

        DEALLOCATE entity_cursor;
    END;
    DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();
    select @FullErrorMessage;
END CATCH
END;