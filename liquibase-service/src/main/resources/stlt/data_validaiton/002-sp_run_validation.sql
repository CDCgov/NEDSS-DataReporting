IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_run_validation]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_run_validation]
END
GO 
/**
	1.	Resolve Dependencies
        •	Uses a recursive CTE to expand all dependencies for the given @entity.
        •	Produces an ordered list of entities to process (parents before children).
	2.	Iterate Entities
        For each entity:
        •	Load the validation_query and dataflows.
        •	Run the validation query that compares ODSE table with RDB table, NRT tables and also the Backfill/Retry table
        •	If @check_log = 0, run the validation query directly.
        •	If @check_log = 1, join validation results to recent job_flow_log errors:
        •	Filters by dataflows, Status_Type = 'ERROR', and either TOP N or last X days.
        •	Aggregates errors into JSON (error_log_json) per record.
	3.	Collate Results
        •	Results are inserted into a temp table #results with a unified schema (including error_log_json).
        •	At the end, a single combined result set is returned for all entities in dependency order.
**/    
CREATE OR ALTER PROCEDURE dbo.sp_run_validation
(
    @entity    VARCHAR(100), --rdb table that is validated against odse
    @check_log BIT = 0,   -- 1 = include job_flow_log info, 0 = only run validation query
    @topn_errors  SMALLINT = NULL -- when provided, get TOP N latest errors; when NULL, get all errors from last 10 days
)
AS
BEGIN
SET NOCOUNT ON;

DECLARE @validation_query NVARCHAR(MAX);
DECLARE @sql NVARCHAR(MAX);
DECLARE @dataflows VARCHAR(500);
DECLARE @lookback INT = 10;
    
BEGIN TRY

    ----------------------------------------------------------------------
    -- 1. Resolve dependencies (recursive CTE)
    ----------------------------------------------------------------------
    ;WITH dep_cte AS (
        SELECT r.rdb_entity, r.dependencies, 0 AS level
        FROM dbo.JOB_VALIDATION_CONFIG r
        WHERE r.rdb_entity = @entity

        UNION ALL

        SELECT c.rdb_entity, c.dependencies, p.level + 1
        FROM dep_cte p
        JOIN dbo.JOB_VALIDATION_CONFIG c
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
    -- 2. Cursor/loop through entities in dependency order
    ----------------------------------------------------------------------
    DECLARE @curr_entity VARCHAR(500), @level INT;

    DECLARE entity_cursor CURSOR FOR
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
        FROM dbo.JOB_VALIDATION_CONFIG
        WHERE rdb_entity = @curr_entity;

        IF @validation_query IS NULL
        BEGIN
            RAISERROR('No validation query found for entity %s', 16, 1, @curr_entity);
            CLOSE entity_cursor;
            DEALLOCATE entity_cursor;
            RETURN;
        END


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

        select  @sql;

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
    -- 3. Collated result
    ----------------------------------------------------------------------
    SELECT * FROM #results;

END TRY
BEGIN CATCH
    CLOSE entity_cursor;
    DEALLOCATE entity_cursor;
    DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();
    select @FullErrorMessage;
END CATCH
END;