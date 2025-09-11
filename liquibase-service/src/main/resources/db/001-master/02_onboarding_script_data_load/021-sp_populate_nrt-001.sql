IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_populate_nrt]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_populate_nrt]
END
GO 

CREATE PROCEDURE dbo.sp_populate_nrt
    @ODSETable      NVARCHAR(200),
    @ODSEUidColumn  NVARCHAR(200),
    @SetStatement   NVARCHAR(2000),
    @BatchSize      NVARCHAR(100),
    @NRTTable       NVARCHAR(200),
    @NRTUIDColumn   NVARCHAR(200)
AS
Begin

    BEGIN TRY

        DECLARE @StartTime DATETIME = GETDATE();
        DECLARE @batch_id BIGINT;
        SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);
        DECLARE @dataflow_name NVARCHAR(200) = 'sp_populate_nrt - ' + @ODSETable;
        DECLARE @package_name NVARCHAR(200) = 'NRT Table Population';
        DECLARE @LastUID        bigint = 0; -- start below min uid
        DECLARE @Rows           int = 1;
        DECLARE @SQLStatement   NVARCHAR(MAX) = '';

        
        CREATE TABLE #NRTKeys
        (
            [UID] bigint PRIMARY KEY
        );

        SET @SQLStatement = ' 
        INSERT INTO #NRTKeys
        SELECT ' + @NRTUIDColumn + ' FROM ' + @NRTTable + ' nrt';

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
            [UID] bigint PRIMARY KEY
        );

        WHILE (@Rows > 0)
        BEGIN
            DELETE FROM #UpdatedKeys;

            SET @SQLStatement = 'INSERT INTO #UpdatedKeys 
            ( 
                [UID] 
            ) 
            SELECT TOP (' + @BatchSize + ') t.' + @ODSEUidColumn + ' 
            FROM NBS_ODSE.dbo.' + @ODSETable + ' t WITH (READPAST) 
            LEFT JOIN #NRTKeys nrt 
            ON nrt.UID = t.' + @ODSEUidColumn + ' 
            WHERE t.' + @ODSEUidColumn + ' > ' + CAST(@LastUID AS NVARCHAR(50)) + ' 
            AND nrt.uid IS NULL 
            ORDER BY t.' + @ODSEUidColumn;

            exec sp_executesql @SQLStatement;

            SET @SQLStatement = '
            UPDATE t 
                ' + @SetStatement + ' 
            FROM NBS_ODSE.dbo.' + @ODSETable + ' t 
            INNER JOIN #UpdatedKeys uk 
                ON t.' + @ODSEUidColumn + ' = uk.[UID]
            ';

            exec sp_executesql @SQLStatement;

            SET @Rows = @@ROWCOUNT;
            IF (@Rows = 0) BREAK;

            SELECT @LastUID = MAX([UID]) FROM #UpdatedKeys;

            PRINT CONCAT('Updated ', @Rows, ' rows; last UID = ', @LastUID);

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
                , LEFT(CONCAT('Updated ', @Rows, ' rows; last UID = ', @LastUID), 199)
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