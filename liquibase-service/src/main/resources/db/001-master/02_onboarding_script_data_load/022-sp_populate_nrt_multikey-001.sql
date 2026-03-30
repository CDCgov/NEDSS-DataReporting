-- This stored procedure is created in master
use master;

IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_populate_nrt_multikey]')
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_populate_nrt_multikey]
END
GO

/*
    For loading nrt_ldf_data, it is necessary to use multiple key columns,
    as uniqueness is determined by both ldf_uid and business_object_uid.

    For that reason, this procedure accommodates the use of two keys.
*/

CREATE   PROCEDURE [dbo].[sp_populate_nrt_multikey]
    @ODSETable      NVARCHAR(200),
    @Key1           NVARCHAR(200),  -- first key column name
    @Key2           NVARCHAR(200),  -- second key column name
    @SetStatement   NVARCHAR(2000),
    @BatchSize      NVARCHAR(100),
    @NRTTable       NVARCHAR(200),
    @NRTKey1        NVARCHAR(200),
    @NRTKey2        NVARCHAR(200)
AS
Begin

    BEGIN TRY

        DECLARE @StartTime DATETIME = GETDATE();
        DECLARE @batch_id BIGINT;
        SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);
        DECLARE @dataflow_name NVARCHAR(200) = 'sp_populate_nrt - ' + @ODSETable;
        DECLARE @package_name NVARCHAR(200) = 'NRT Table Population';
        DECLARE @LastKey1 BIGINT = 0;
        DECLARE @LastKey2 BIGINT = 0;
        DECLARE @Rows           int = 1;
        DECLARE @SQLStatement   NVARCHAR(MAX) = '';
        DECLARE @step_name      nvarchar(200) = '';

        -- Based on configuration, set @RDB_DB to either rdb_modern or rdb
        DECLARE @RDB_DB NVARCHAR(128) = 'rdb';
        IF EXISTS(SELECT 1 FROM NBS_ODSE.DBO.NBS_configuration WHERE config_key ='ENV' AND config_value ='UAT')
            BEGIN
                SET @RDB_DB = 'rdb_modern';
            END
        PRINT 'Using database ' + @RDB_DB + ' in sp_populate_nrt_multikey';

        CREATE TABLE #NRTKeys
        (
            Key1 BIGINT,
            Key2 BIGINT,
            PRIMARY KEY (Key1, Key2)
        );

        SET @SQLStatement = '
        INSERT INTO #NRTKeys
        SELECT ' + @NRTKey1 + ', ' + @NRTKey2 + ' FROM ' + @NRTTable + ' nrt';

        exec sp_executesql @SQLStatement;

        -- Dynamically construct and executes a SQL INSERT statement against the variable database name (@RDB_DB)
        -- The sp_executesql stored procedure is used to safely pass parameters (@batch_id, @dataflow_name, @package_name)
        -- to prevent SQL injection and maintain data integrity.
        SET @SQLStatement = N'
        INSERT INTO ' + QUOTENAME(@RDB_DB) + N'.dbo.job_flow_log
        (
            batch_id,
            Dataflow_Name,
            package_Name,
            Status_Type,
            step_number,
            step_name,
            row_count,
            Msg_Description1
        )
        VALUES
        (
            @batch_id,
            @dataflow_name,
            @package_name,
            ''START'',
            0,
            '''',
            0,
            ''''
        );';

        EXEC sp_executesql
            @SQLStatement,
            N'@batch_id bigint,
            @dataflow_name nvarchar(200),
            @package_name nvarchar(200)',
            @batch_id = @batch_id,
            @dataflow_name = @dataflow_name,
            @package_name = @package_name;
        --

        PRINT 'Starting Loading Script for NBS_ODSE.dbo.' + @ODSETable + ' at: ' + CONVERT(VARCHAR(50), @StartTime, 121);

        CREATE TABLE #UpdatedKeys
        (
            Key1 BIGINT,
            Key2 BIGINT,
            PRIMARY KEY (Key1, Key2)
        );

        WHILE (@Rows > 0)
        BEGIN
            DELETE FROM #UpdatedKeys;

            SET @SQLStatement = '
                INSERT INTO #UpdatedKeys (Key1, Key2)
                SELECT TOP (' + CAST(@BatchSize AS NVARCHAR(20)) + ')
                       t.' + @Key1 + ', t.' + @Key2 + '
                FROM NBS_ODSE.dbo.' + @ODSETable + ' t WITH (NOLOCK)
                LEFT JOIN #NRTKeys nrt
                ON nrt.Key1 = t.' + @Key1 + ' AND nrt.Key2 = t.' + @Key2 + '
                WHERE (t.' + @Key1 + ' > ' + CAST(@LastKey1 AS NVARCHAR(20)) + '
                       OR (t.' + @Key1 + ' = ' + CAST(@LastKey1 AS NVARCHAR(20)) +
                       ' AND t.' + @Key2 + ' > ' + CAST(@LastKey2 AS NVARCHAR(20)) + '))
                AND nrt.Key1 IS NULL AND nrt.Key2 IS NULL
                ORDER BY t.' + @Key1 + ', t.' + @Key2 + ';';


            exec sp_executesql @SQLStatement;

            SET @SQLStatement = '
            UPDATE t
                ' + @SetStatement + '
            FROM NBS_ODSE.dbo.' + @ODSETable + ' t
            INNER JOIN #UpdatedKeys uk
                 ON t.' + @Key1 + ' = uk.Key1
                   AND t.' + @Key2 + ' = uk.Key2
            ';

            exec sp_executesql @SQLStatement;

            SET @Rows = @@ROWCOUNT;
            IF (@Rows = 0) BREAK;

            SELECT TOP 1 @LastKey1 = Key1, @LastKey2 = Key2
            FROM #UpdatedKeys
            ORDER BY Key1 DESC, Key2 DESC;

            PRINT CONCAT('Updated ', @Rows, ' rows; last key = (', @LastKey1, ',', @LastKey2, ')');

            SET @step_name = LEFT(CONCAT('Updated ', @Rows, ' rows; last key = (', @LastKey1, ',', @LastKey2, ')'), 199);
            SET @SQLStatement = N'
            INSERT INTO ' + QUOTENAME(@RDB_DB) + N'.dbo.job_flow_log
            (
                batch_id,
                Dataflow_Name,
                package_Name,
                Status_Type,
                step_number,
                step_name,
                row_count,
                Msg_Description1
            )
            VALUES
            (
                @batch_id,
                @dataflow_name,
                @package_name,
                ''START'',
                0,
                @step_name,
                @row_count,
                ''''
            );';

            EXEC sp_executesql
                @SQLStatement,
                N'@batch_id bigint,
                @dataflow_name nvarchar(200),
                @package_name nvarchar(200),
                @step_name nvarchar(200),
                @row_count int',
                @batch_id = @batch_id,
                @dataflow_name = @dataflow_name,
                @package_name = @package_name,
                @step_name = @step_name,
                @row_count = @Rows;

            -- wait for 1 second between batches
            WAITFOR DELAY '00:00:01';
        END

        DECLARE @EndTime DATETIME = GETDATE();

        PRINT 'Loading Script for NBS_ODSE.dbo.' + @ODSETable + ' completed at: ' + CONVERT(VARCHAR(50), @EndTime, 121);

       SET @SQLStatement = N'
        INSERT INTO ' + QUOTENAME(@RDB_DB) + N'.dbo.job_flow_log
        (
            batch_id,
            Dataflow_Name,
            package_Name,
            Status_Type,
            step_number,
            step_name,
            row_count,
            Msg_Description1
        )
        VALUES
        (
            @batch_id,
            @dataflow_name,
            @package_name,
            ''COMPLETE'',
            0,
            '''',
            0,
            ''''
        );';

        EXEC sp_executesql
            @SQLStatement,
            N'@batch_id bigint,
            @dataflow_name nvarchar(200),
            @package_name nvarchar(200)',
            @batch_id = @batch_id,
            @dataflow_name = @dataflow_name,
            @package_name = @package_name;
    end try

    BEGIN CATCH


        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        SET @SQLStatement = N'
        INSERT INTO ' + QUOTENAME(@RDB_DB) + N'.dbo.job_flow_log
        (
            batch_id,
            Dataflow_Name,
            package_Name,
            Status_Type,
            step_number,
            step_name,
            row_count,
            Msg_Description1,
            Error_Description
        )
        VALUES
        (
            @batch_id,
            @dataflow_name,
            @package_name,
            ''ERROR'',
            0,
            @dataflow_name,
            0,
            '''',
            @FullErrorMessage
        );';

        EXEC sp_executesql
            @SQLStatement,
            N'@batch_id bigint,
            @dataflow_name nvarchar(200),
            @package_name nvarchar(200),
            @FullErrorMessage varchar(8000)',
            @batch_id = @batch_id,
            @dataflow_name = @dataflow_name,
            @package_name = @package_name,
            @FullErrorMessage = @FullErrorMessage;

        return @FullErrorMessage;

    END CATCH

end;