IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_nrt_backfill_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_nrt_backfill_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_nrt_backfill_postprocessing]
    @entity nvarchar(256),
    @record_uid_list nvarchar(max),
    @batch_id bigint,
    @err_description nvarchar(1000),
    @status_cd  nvarchar(256),
    @retry_count smallint

AS
BEGIN

    BEGIN TRY
        
        declare @rowcount bigint;
        declare @proc_step_no float = 0;
        declare @proc_step_name varchar(200) = '';
        declare @dataflow_name varchar(200) = 'Backfill POST-Processing';
        declare @package_name varchar(200) = 'sp_nrt_backfill_postprocessing';

        BEGIN TRANSACTION;

       if @record_uid_list is null
            --Update the NRT_BACKFILL through JAVA
            --Will be ignored if sproc already updated it and retry_count was increased
            BEGIN
               UPDATE dbo.nrt_backfill
               SET status_cd       = @status_cd,
                   retry_count     = @retry_count,
                   err_description = @err_description,
                   updated_dttm    = GETDATE()
               WHERE batch_id = @batch_id AND (@retry_count > retry_count OR @retry_count = 0)
                 AND (@entity IS NULL OR entity = @entity);
            END
        ELSE
            BEGIN
                --Update the NRT_BACKFILL through SPROC
                update dbo.nrt_backfill
                set
                    retry_count = retry_count + 1,
                    updated_dttm = getdate()
                where record_uid_list = @record_uid_list and entity = @entity;
            END

        --Insert into NRT_BACKFILL table if entity with the same record_uid_list doesn't exist
        INSERT INTO dbo.nrt_backfill
            ( entity
            , record_uid_list
            , batch_id
            , err_description
            , status_cd
            , retry_count
            )
        SELECT
            @entity,
            @record_uid_list,
            @batch_id,
            @err_description,
            @status_cd,
            0
        WHERE
            -- only if there is an actual record list
            @record_uid_list IS NOT NULL
            -- and no existing row with the same (entity, record_uid_list)
            AND NOT EXISTS (
                SELECT 1
                FROM dbo.nrt_backfill AS nb
                WHERE nb.entity           = @entity
                  AND nb.record_uid_list = @record_uid_list
            )
            -- and no existing row with the same (entity, batch_id)
            AND NOT EXISTS (
                SELECT 1
                FROM dbo.nrt_backfill AS nb2
                WHERE nb2.entity   = @entity
                  AND nb2.batch_id = @batch_id
            );

        set @rowcount=@@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (
          batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1]
        )
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@record_uid_list,500)
               );
        
        COMMIT TRANSACTION;
--------------------------------------------------------------------------------------------------------
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