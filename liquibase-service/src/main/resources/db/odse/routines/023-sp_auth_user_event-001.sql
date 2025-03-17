CREATE OR ALTER PROCEDURE dbo.sp_auth_user_event @user_id_list nvarchar(max)
AS
BEGIN

    BEGIN TRY

        DECLARE @batch_id BIGINT;
        SET @batch_id = cast((format(getdate(), 'yyMMddHHmmssffff')) as bigint);

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        , [Msg_Description1])
        VALUES ( @batch_id
               , 'Auth_User PRE-Processing Event'
               , 'NBS_ODSE.sp_auth_user_event'
               , 'START'
               , 0
               , LEFT('Pre ID-' + @user_id_list, 199)
               , 0
               , LEFT(@user_id_list, 199));

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

        INSERT INTO [rdb_modern].[dbo].[job_flow_log] ( batch_id
                                                      , [Dataflow_Name]
                                                      , [package_Name]
                                                      , [Status_Type]
                                                      , [step_number]
                                                      , [step_name]
                                                      , [row_count]
                                                      , [Msg_Description1])
        VALUES ( @batch_id
               , 'Auth_User PRE-Processing Event'
               , 'NBS_ODSE.sp_auth_user_event'
               , 'COMPLETE'
               , 0
               , LEFT('Pre ID-' + @user_id_list, 199)
               , 0
               , LEFT(@user_id_list, 199));

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @FullErrorMessage VARCHAR(8000) =
        'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
        'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
        'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
        'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
        'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [rdb_modern].[dbo].[job_flow_log] ( batch_id
                                                      , [Dataflow_Name]
                                                      , [package_Name]
                                                      , [Status_Type]
                                                      , [step_number]
                                                      , [step_name]
                                                      , [row_count]
                                                      , [Msg_Description1]
                                                        ,[Error_Description]
                                                        )

        VALUES ( @batch_id
               , 'Auth_user PRE-Processing Event'
               , 'NBS_ODSE.sp_auth_user_event'
               , 'ERROR'
               , 0
               , 'Auth_user PRE-Processing Event'
               , 0
               , LEFT(@user_id_list, 199)
                ,@FullErrorMessage
            );
        return @FullErrorMessage;

    END CATCH

END;