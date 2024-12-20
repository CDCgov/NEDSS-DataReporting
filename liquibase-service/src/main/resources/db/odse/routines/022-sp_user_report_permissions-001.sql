CREATE OR ALTER PROCEDURE dbo.sp_user_report_permissions(
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
        SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmss')) AS bigint);

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

    
    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;


        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();


        INSERT INTO [rdb_modern].[dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [Error_Description]
                                         , [row_count])
        VALUES ( @batch_id
               , 'USER_REPORT_PERMISSIONS'
               , 'USER_REPORT_PERMISSIONS'
               , 'ERROR'
               , @Proc_Step_no
               , 'ERROR - ' + @Proc_Step_name
               , 'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
               , 0);


        return -1;

    END CATCH

END

    ;