IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_auth_user_event]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_auth_user_event]
END
GO 

CREATE PROCEDURE dbo.sp_auth_user_event @user_id_list nvarchar(max), @debug_logging bit = 0
AS
BEGIN

    BEGIN TRY

        DECLARE @batch_id BIGINT;
        DECLARE @job_flow_step_name VARCHAR(200) = LEFT('Pre ID-' + @user_id_list, 199);
        DECLARE @job_flow_message VARCHAR(200) = LEFT(@user_id_list, 199);
        SET @batch_id = cast((format(getdate(), 'yyMMddHHmmssffff')) as bigint);

        IF @debug_logging = 1
        BEGIN
            EXEC dbo.sp_add_job_flow_log
                @batch_id = @batch_id,
                @dataflow_name = 'Auth_User PRE-Processing Event',
                @package_name = 'sp_auth_user_event',
                @status_type = 'START',
                @step_number = 0,
                @step_name = @job_flow_step_name,
                @row_count = 0,
                @msg_description1 = @job_flow_message;
        END;

        SELECT a.auth_user_uid,
               a.user_id,
               substring(rtrim(ltrim(a.user_first_nm)), 1, 50) as first_nm,
               substring(rtrim(ltrim(a.user_last_nm)), 1, 50)  as last_nm,
               a.nedss_entry_id,
               a.provider_uid,
               a.add_user_id,
               a.last_chg_user_id,
               a.add_time,
               a.last_chg_time,
               a.record_status_cd,
               a.record_status_time
        FROM nbs_odse.dbo.Auth_user a WITH (NOLOCK)
        WHERE a.auth_user_uid in (SELECT value FROM STRING_SPLIT(@user_id_list, ','));

        IF @debug_logging = 1
        BEGIN
            EXEC dbo.sp_add_job_flow_log
                @batch_id = @batch_id,
                @dataflow_name = 'Auth_User PRE-Processing Event',
                @package_name = 'sp_auth_user_event',
                @status_type = 'COMPLETE',
                @step_number = 0,
                @step_name = @job_flow_step_name,
                @row_count = 0,
                @msg_description1 = @job_flow_message;
        END;

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @FullErrorMessage VARCHAR(8000) =
        'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
        'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
        'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
        'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
        'Error Message: ' + ERROR_MESSAGE();

        EXEC dbo.sp_add_job_flow_log
            @batch_id = @batch_id,
            @dataflow_name = 'Auth_user PRE-Processing Event',
            @package_name = 'sp_auth_user_event',
            @status_type = 'ERROR',
            @step_number = 0,
            @step_name = 'Auth_user PRE-Processing Event',
            @row_count = 0,
            @msg_description1 = @job_flow_message,
            @error_description = @FullErrorMessage;
        return @FullErrorMessage;

    END CATCH

END;