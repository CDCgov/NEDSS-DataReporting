IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_user_report_permissions]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_user_report_permissions]
END
GO 

CREATE PROCEDURE dbo.sp_user_report_permissions(
    @user_ids NVARCHAR(MAX) = '')
as

BEGIN

    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';
        DECLARE @batch_id bigint;
        SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmssffff')) AS bigint);
        DECLARE @dataflow_name NVARCHAR(200) = 'USER_REPORT_PERMISSIONS';
        DECLARE @package_name NVARCHAR(200) = 'USER_REPORT_PERMISSIONS';
        
        INSERT INTO [rdb].[dbo].[job_flow_log]
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
                , LEFT('Pre ID-' + @user_ids, 199)
                , 0
                , LEFT(@user_ids, 199));

        select distinct
        [user].user_id                  as [user],
        [object_type].bus_obj_nm        as [object_type],
        [operation_type].bus_op_nm + '-' + [object_type].bus_obj_nm as [authority],
        rep.report_title,
        ds.data_source_title,
        ds.data_source_name
        from     auth_user [user]
                join auth_user_role [role] on
                        [role].auth_user_uid=[user].auth_user_uid
                join auth_perm_set [set] on
                        [role].auth_perm_set_uid=[set].auth_perm_set_uid
                join auth_bus_obj_rt [object_right] on
                        [object_right].auth_perm_set_uid=[set].auth_perm_set_uid
                join auth_bus_obj_type [object_type] on
                        [object_right].auth_bus_obj_type_uid=[object_type].auth_bus_obj_type_uid
                join auth_bus_op_rt [operation_right] on
                        [operation_right].auth_bus_obj_rt_uid=[object_right].auth_bus_obj_rt_uid
                join auth_bus_op_type [operation_type] on
                        [operation_type].auth_bus_op_type_uid=[operation_right].auth_bus_op_type_uid
                INNER JOIN dbo.report rep
                ON (
                        [operation_type].bus_op_nm = 'VIEWREPORTPUBLIC' and rep.shared = 'S'
                        OR
                        [operation_type].bus_op_nm = 'VIEWREPORTPRIVATE' and rep.shared = 'P' and [user].nedss_entry_id = rep.owner_uid
                        OR
                        [operation_type].bus_op_nm = 'VIEWREPORTTEMPLATE' and rep.shared = 'T'
                        OR
                        [operation_type].bus_op_nm = 'VIEWREPORTREPORTINGFACILITY' and rep.shared = 'R'
                )
                LEFT JOIN dbo.Data_Source ds
                ON ds.data_source_uid = rep.data_source_uid
        where   
                /*
                For the case when the user_ids variable is NULL or an empty string, return all user report permissions
                Otherwise, check to see if the user_id is contains in the user_ids variable
                */
                (CASE 
                    WHEN COALESCE(@user_ids, '') = '' THEN 1
                    WHEN [user].user_id in (SELECT value FROM STRING_SPLIT(@user_ids, ',')) THEN 1
                    ELSE 0
                END = 1)
                and not (
                        [role].role_guest_ind = 'T'
                        and isNull([operation_right].bus_op_guest_rt, 'F') = 'F'
                )
                and [operation_type].bus_op_nm in ('VIEWREPORTPRIVATE', 'VIEWREPORTPUBLIC', 'VIEWREPORTREPORTINGFACILITY', 'VIEWREPORTTEMPLATE')

        INSERT INTO [rdb].[dbo].[job_flow_log]
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
                , LEFT('Pre ID-' + @user_ids, 199)
                , 0
                , LEFT(@user_ids, 199));

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;


        DECLARE @FullErrorMessage VARCHAR(8000) =
        'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
        'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
        'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
        'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
        'Error Message: ' + ERROR_MESSAGE();


        INSERT INTO [rdb].[dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [Error_Description]
                                         , [row_count]
                                         , [Msg_Description1])
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'ERROR'
               , @Proc_Step_no
               , @Proc_Step_name
               , @FullErrorMessage
               , 0
               , LEFT(@user_ids, 199)
            );

        return @FullErrorMessage;

    END CATCH

END

    ;