IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_nrt_backfill_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_nrt_backfill_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_nrt_backfill_postprocessing]
    @entity_type nvarchar(1000),
    @record_uid_list nvarchar(max),
    @rdb_table_map nvarchar(max),
    @batch_id bigint,
    @err_description nvarchar(1000),
    @status_cd  nvarchar(1000),
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
            --Update the NRT_BACKFILL table if the same record_uid_list exists
            BEGIN
                update dbo.nrt_backfill 
                set status_cd = @status_cd,
                retry_count = @retry_count
                where batch_id = @batch_id;
            END
        ELSE
            BEGIN
                update dbo.nrt_backfill 
                set retry_count = retry_count + 1
                where record_uid_list = @record_uid_list and entity_type = @entity_type;
            END

        --Insert into NRT_BACKFILL table if the record_uid_list doesnt exists
        insert into dbo.nrt_backfill(entity_type, record_uid_list, batch_id, err_description, status_cd, retry_count)
            select 
                tmp.entity_type,
                tmp.record_uid_list, 
                tmp.batch_id,
                tmp.err_description,
                tmp.status_cd,
                tmp.retry_count
            from 
            (
                select 
                @entity_type as entity_type, 
                @record_uid_list as record_uid_list,
                @batch_id as batch_id,
                @err_description as err_description,
                @status_cd AS status_cd,
                0 AS retry_count
            ) AS tmp
            left join dbo.nrt_backfill nrt with (nolock)
                on tmp.record_uid_list = nrt.record_uid_list and 
                tmp.entity_type = nrt.entity_type
            where nrt.record_uid_list is null and nrt.entity_type is null

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