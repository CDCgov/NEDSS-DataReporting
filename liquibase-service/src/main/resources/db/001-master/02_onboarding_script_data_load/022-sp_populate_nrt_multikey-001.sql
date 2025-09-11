IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_populate_nrt_multikey]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_populate_nrt_multikey]
END
GO 

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

    INSERT INTO [dbo].[job_flow_log]
            ( batch_id
            , [Dataflow_Name]
            , [package_Name]
            , [Status_Type]
            , [step_number]
            , [step_name]
            , [row_count]
            , [Msg_Description1])
            VALUES ( @batch_id
                , @dataflow_name
                , @package_name
                , 'START'
                , 0
                , ''
                , 0
                , '');
    
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
                FROM NBS_ODSE.dbo.' + @ODSETable + ' t WITH (READPAST) 
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

            INSERT INTO [dbo].[job_flow_log]
            ( batch_id
            , [Dataflow_Name]
            , [package_Name]
            , [Status_Type]
            , [step_number]
            , [step_name]
            , [row_count]
            , [Msg_Description1])
            VALUES ( @batch_id
                , @dataflow_name
                , @package_name
                , 'START'
                , 0
                , LEFT(CONCAT('Updated ', @Rows, ' rows; last key = (', @LastKey1, ',', @LastKey2, ')'), 199)
                , 0
                , '');

            -- wait for 1 second between batches
            WAITFOR DELAY '00:00:01';
        END

        DECLARE @EndTime DATETIME = GETDATE();

        PRINT 'Loading Script for NBS_ODSE.dbo.' + @ODSETable + ' completed at: ' + CONVERT(VARCHAR(50), @EndTime, 121);

       INSERT INTO [dbo].[job_flow_log]
            ( batch_id
            , [Dataflow_Name]
            , [package_Name]
            , [Status_Type]
            , [step_number]
            , [step_name]
            , [row_count]
            , [Msg_Description1])
            VALUES ( @batch_id
                , @dataflow_name
                , @package_name
                , 'COMPLETE'
                , 0
                , ''
                , 0
                , '');
    end try

    BEGIN CATCH


        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        , [Msg_Description1]
        , [Error_Description]
        )
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'ERROR'
               , 0
               , @dataflow_name
               , 0
               , ''
               , @FullErrorMessage
               );

        return @FullErrorMessage;

    END CATCH

end;