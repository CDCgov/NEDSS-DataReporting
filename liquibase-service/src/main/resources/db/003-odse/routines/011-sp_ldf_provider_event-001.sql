IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_ldf_provider_event]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_ldf_provider_event]
END
GO 

CREATE PROCEDURE dbo.sp_ldf_provider_event @ldf_uid_list nvarchar(max), @bus_obj_uid_list nvarchar(max), @batch_id BIGINT
AS
Begin

    BEGIN TRY

        DECLARE @dataflow_name NVARCHAR(200) = 'ldf_provider PRE-Processing Event';
        DECLARE @package_name NVARCHAR(200) = 'NBS_ODSE.sp_ldf_provider_event';
        
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
                , LEFT('Pre ID-' + @bus_obj_uid_list, 199)
                , 0
                , LEFT(@bus_obj_uid_list, 199));

        /*select * from dbo.v_ldf_provider ldf
         WHERE ldf.ldf_uid in (SELECT value FROM STRING_SPLIT(@ldf_uid_list, ','))
         and ldf.business_object_uid  in (SELECT value FROM STRING_SPLIT(@bus_obj_uid_list, ','))
             Order By ldf.business_object_uid, ldf.display_order_nbr;*/
        select distinct m.ldf_uid,
                        m.active_ind,
                        m.add_time ldf_meta_data_add_time,
                        m.admin_comment,
                        m.business_object_nm ldf_meta_data_business_object_nm,
                        m.category_type,
                        m.cdc_national_id,
                        m.class_cd,
                        m.code_set_nm,
                        m.condition_cd,
                        m.condition_desc_txt,
                        m.data_type,
                        m.deployment_cd,
                        m.display_order_nbr,
                        m.field_size,
                        m.label_txt,
                        m.ldf_page_id,
                        m.required_ind,
                        m.state_cd,
                        m.validation_txt,
                        m.validation_jscript_txt,
                        p.record_status_time,
                        dbo.fn_get_record_status(p.record_status_cd) as record_status_cd,
                        m.custom_subform_metadata_uid,
                        m.html_tag,
                        m.import_version_nbr,
                        m.nnd_ind,
                        m.ldf_oid,
                        m.version_ctrl_nbr ldf_meta_data_version_ctrl_num,
                        m.nbs_question_uid,
                        d.business_object_uid,
                        d.add_time ldf_data_field_add_time,
                        d.business_object_nm ldf_field_data_business_object_nm,
                        d.last_chg_time ldf_data_last_chg_time,
                        d.ldf_value,
                        d.version_ctrl_nbr ldf_field_data_version_ctrl_num,
                        cvg.code_desc_txt as ldf_column_type,
                        m.record_status_time as metadata_record_status_time,
                        dbo.fn_get_record_status(m.record_status_cd) as metadata_record_status_cd
        from  nbs_odse.dbo.State_Defined_Field_MetaData m
                  join nbs_odse.dbo.State_Defined_Field_Data d with (nolock) on m.ldf_uid = d.ldf_uid  and d.business_object_nm = 'PRV'
            and d.business_object_uid  in (SELECT value FROM STRING_SPLIT(@bus_obj_uid_list, ','))
            and d.ldf_uid in (SELECT value FROM STRING_SPLIT(@ldf_uid_list, ','))
                  join nbs_srte.dbo.code_value_general cvg with (nolock) on  cvg.code = m.data_type  and cvg.code_set_nm = 'LDF_DATA_TYPE'
                  join nbs_odse.dbo.Person p with (nolock) on d.business_object_uid=p.person_uid and p.person_uid<>p.person_parent_uid
            and p.cd='PRV'
        Order By business_object_uid, display_order_nbr ;

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
                , LEFT('Pre ID-' + @bus_obj_uid_list, 199)
                , 0
                , LEFT(@bus_obj_uid_list, 199));

    end try

    BEGIN CATCH


        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [rdb].[dbo].[job_flow_log]
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
               , LEFT(@bus_obj_uid_list, 199)
               , @FullErrorMessage
               );

        return @FullErrorMessage;

    END CATCH

end;