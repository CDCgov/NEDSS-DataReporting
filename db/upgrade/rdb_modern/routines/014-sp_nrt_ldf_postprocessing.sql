CREATE OR ALTER PROCEDURE dbo.sp_nrt_ldf_postprocessing @ldf_uid_list nvarchar(max), @debug bit = 'false'
AS

BEGIN

    BEGIN TRY

        /* Logging */
        declare @rowcount bigint;
        declare @proc_step_no float = 0;
        declare @proc_step_name varchar(200) = '';
        declare @batch_id bigint;
        declare @create_dttm datetime2(7) = current_timestamp ;
        declare @update_dttm datetime2(7) = current_timestamp ;
        declare @dataflow_name varchar(200) = 'LDF POST-Processing';
        declare @package_name varchar(200) = 'sp_nrt_ldf_postprocessing';

        set @batch_id = cast((format(getdate(),'yyMMddHHmmss')) as bigint);
        print @batch_id;

        INSERT INTO [dbo].[job_flow_log]
        (
          batch_id
        ,[create_dttm]
        ,[update_dttm]
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[msg_description1]
        ,[row_count]
        )
        VALUES (
                 @batch_id
               ,@create_dttm
               ,@update_dttm
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,0
               ,'SP_Start'
               ,LEFT(@ldf_uid_list,500)
               ,0
               );

        SET @proc_step_name='Create LDF_DATA Temp tables-'+ LEFT(@ldf_uid_list,105);
        SET @proc_step_no = 1;


        /**Initial null condition for LDF_DATA and LDF_Group*/
        IF NOT EXISTS (SELECT 1 FROM dbo.ldf_data UNION ALL SELECT 1 FROM dbo.LDF_GROUP)
            BEGIN
                insert into dbo.nrt_ldf_group_key(business_object_uid)
                VALUES (NULL);

                insert into dbo.nrt_ldf_data_key(d_ldf_group_key, business_object_uid, ldf_uid)
                VALUES (1, NULL, NULL)

                insert into dbo.ldf_group(ldf_group_key, business_object_uid)
                VALUES (1, NULL);

                insert into dbo.ldf_data
                (ldf_data_key
                ,ldf_group_key
                ,ldf_column_type
                ,condition_cd
                ,condition_desc_txt
                ,class_cd
                ,code_set_nm
                ,business_obj_nm
                ,display_order_number
                ,field_size
                ,ldf_value
                ,import_version_nbr
                ,label_txt
                ,ldf_oid
                ,nnd_ind
                ,record_status_cd
                )
                values (1
                       ,1
                       ,NULL
                       ,NULL
                       ,NULL
                       ,NULL
                       ,NULL
                       ,NULL
                       ,NULL
                       ,NULL
                       ,NULL
                       ,NULL
                       ,NULL
                       ,NULL
                       ,NULL
                       ,'ACTIVE');

                insert into dbo.PATIENT_LDF_GROUP (PATIENT_KEY, LDF_GROUP_KEY, RECORD_STATUS_CD)
                values (1, 1, 'ACTIVE');

                insert into dbo.PROVIDER_LDF_GROUP (PROVIDER_KEY, LDF_GROUP_KEY, RECORD_STATUS_CD)
                values (1, 1, 'ACTIVE');

                insert into dbo.ORGANIZATION_LDF_GROUP (ORGANIZATION_KEY, LDF_GROUP_KEY, RECORD_STATUS_CD)
                values (1, 1, 'ACTIVE');
            END


        /**Create temp table for LDF_DATA */
        select
            ldf.ldf_data_key,
            ldf.ldf_group_key,
            ld.ldf_uid,
            ld.business_object_uid,
            ld.ldf_column_type,
            ld.condition_cd,
            ld.condition_desc_txt,
            ld.class_cd,
            ld.code_set_nm,
            ld.ldf_field_data_business_object_nm as business_object_nm,
            ld.display_order_nbr as display_order_number,
            ld.field_size,
            ld.ldf_value,
            ld.import_version_nbr,
            ld.label_txt,
            ld.ldf_oid,
            ld.nnd_ind,
            ld.metadata_record_status_cd
        into #tmp_ldf_data
        from dbo.nrt_ldf_data ld
                 left join dbo.nrt_ldf_data_key nldk with (nolock) ON ld.ldf_uid = nldk.ldf_uid
                 left join dbo.ldf_data ldf with (nolock) ON nldk.d_ldf_data_key = ldf.ldf_data_key
            and nldk.d_ldf_group_key = ldf.ldf_group_key
        where ld.ldf_uid in (SELECT value FROM STRING_SPLIT(@ldf_uid_list, ','))
        --and ld.business_object_uid  in (SELECT value FROM STRING_SPLIT(@bus_obj_uid_list, ','))
        ;

        if @debug = 'true' select * from #tmp_ldf_data;

        /* Logging */
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
               ,LEFT(@ldf_uid_list,500)
               );

        BEGIN TRANSACTION;
        SET @proc_step_name='Update LDF_DATA Dimension';
        SET @proc_step_no = 2;


        /** Update condition for LDF_DATA*/
        UPDATE dbo.ldf_data
        SET
            ldf_data_key = ld.ldf_data_key
          ,ldf_group_key = ld.ldf_group_key
          ,ldf_column_type = ld.ldf_column_type
          ,condition_cd = ld.condition_cd
          ,condition_desc_txt = ld.condition_desc_txt
          ,class_cd = ld.class_cd
          ,code_set_nm = ld.code_set_nm
          ,business_obj_nm = ld.business_object_nm
          ,display_order_number = ld.display_order_number
          ,field_size = ld.field_size
          ,ldf_value = ld.ldf_value
          ,import_version_nbr = ld.import_version_nbr
          ,label_txt = ld.label_txt
          ,ldf_oid = ld.ldf_oid
          ,nnd_ind = ld.nnd_ind
          ,record_status_cd = ld.metadata_record_status_cd
        FROM #tmp_ldf_data ld
                 inner join dbo.ldf_data k with (nolock) ON ld.ldf_data_key = k.ldf_data_key
            and ld.ldf_group_key = k.ldf_group_key
        where ld.ldf_group_key is not null
          and ld.ldf_data_key is not null;

        /* Logging */
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
               ,LEFT(@ldf_uid_list,500)
               );

        SET @proc_step_name='Insert into LDF_GROUP Dimension';
        SET @proc_step_no = 3;

        /**Create new keys for LDF_Group*/
        insert into dbo.nrt_ldf_group_key (business_object_uid)
        select distinct tld.business_object_uid from #tmp_ldf_data tld
                                                         left join nrt_ldf_group_key nl with (nolock) on nl.business_object_uid = tld.business_object_uid
        where nl.d_ldf_group_key is null and nl.business_object_uid is null
        order by tld.business_object_uid;

        insert into dbo.ldf_group(ldf_group_key, business_object_uid)
        select distinct lgk.d_ldf_group_key, lgk.business_object_uid
        from #tmp_ldf_data ld
                 join nrt_ldf_group_key lgk with (nolock) on ld.business_object_uid = lgk.business_object_uid
                 left join ldf_group lg with (nolock) on lg.ldf_group_key = lgk.d_ldf_group_key
        where lg.ldf_group_key is null;

        insert into dbo.nrt_ldf_data_key(d_ldf_group_key, business_object_uid, ldf_uid)
        select distinct lg.d_ldf_group_key, lg.business_object_uid, ld.ldf_uid
        from #tmp_ldf_data ld
                 left join nrt_ldf_group_key lg with (nolock) on ld.business_object_uid = lg.business_object_uid
                 left join nrt_ldf_data_key nldk with (nolock) on ld.ldf_uid = nldk.ldf_uid
        where nldk.d_ldf_data_key is null and nldk.d_ldf_group_key is null;

        /* Logging */
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
               ,LEFT(@ldf_uid_list,500)
               );

        SET @proc_step_name='Insert into LDF_DATA Dimension';
        SET @proc_step_no = 4;


        insert into dbo.ldf_data
        (ldf_data_key
        ,ldf_group_key
        ,ldf_column_type
        ,condition_cd
        ,condition_desc_txt
        ,class_cd
        ,code_set_nm
        ,business_obj_nm
        ,display_order_number
        ,field_size
        ,ldf_value
        ,import_version_nbr
        ,label_txt
        ,ldf_oid
        ,nnd_ind
        ,record_status_cd
        )
        select k.d_ldf_data_key
             ,k.d_ldf_group_key
             ,tld.ldf_column_type
             ,tld.condition_cd
             ,tld.condition_desc_txt
             ,tld.class_cd
             ,tld.code_set_nm
             ,tld.business_object_nm
             ,tld.display_order_number
             ,tld.field_size
             ,tld.ldf_value
             ,tld.import_version_nbr
             ,tld.label_txt
             ,tld.ldf_oid
             ,tld.nnd_ind
             ,tld.metadata_record_status_cd
        FROM #tmp_ldf_data tld
                 join dbo.nrt_ldf_data_key k with (nolock) on tld.ldf_uid = k.ldf_uid
            and tld.business_object_uid = k.business_object_uid
                 left join ldf_data ld with (nolock) on ld.ldf_data_key = k.d_ldf_data_key
            and ld.ldf_group_key = k.d_ldf_group_key
        where ld.ldf_data_key is null and ld.ldf_group_key is null;

        /* Logging */
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
               ,LEFT(@ldf_uid_list,500)
               );

        SET @proc_step_name='Insert into PATIENT_LDF_GROUP Dimension';
        SET @proc_step_no = 5;

        insert into dbo.PATIENT_LDF_GROUP (PATIENT_KEY, LDF_GROUP_KEY, RECORD_STATUS_CD)
        select d.patient_key, ldf.d_ldf_group_key, d.patient_record_status
        from nrt_ldf_data_key ldf
                 inner join d_patient d with (nolock) on ldf.ldf_uid = d.patient_uid
        where ldf.ldf_uid in (SELECT value FROM STRING_SPLIT(@ldf_uid_list, ','));

        /* Logging */
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
               ,LEFT(@ldf_uid_list,500)
               );

        SET @proc_step_name='Insert into PROVIDER_LDF_GROUP Dimension';
        SET @proc_step_no = 6;

        insert into dbo.PROVIDER_LDF_GROUP (PROVIDER_KEY , LDF_GROUP_KEY, RECORD_STATUS_CD)
        select d.provider_key, ldf.d_ldf_group_key, d.provider_record_status
        from nrt_ldf_data_key ldf
                 inner join d_provider d with (nolock) on ldf.ldf_uid = d.provider_uid
        where ldf.ldf_uid in (SELECT value FROM STRING_SPLIT(@ldf_uid_list, ','));

        /* Logging */
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
               ,LEFT(@ldf_uid_list,500)
               );

        SET @proc_step_name='Insert into ORGANIZATION_LDF_GROUP Dimension';
        SET @proc_step_no = 7;

        insert into dbo.ORGANIZATION_LDF_GROUP (ORGANIZATION_KEY, LDF_GROUP_KEY, RECORD_STATUS_CD)
        select d.organization_key, ldf.d_ldf_group_key, d.organization_record_status
        from nrt_ldf_data_key ldf
                 inner join d_organization d with (nolock) on ldf.ldf_uid = d.organization_uid
        where ldf.ldf_uid in (SELECT value FROM STRING_SPLIT(@ldf_uid_list, ','));

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
               ,LEFT(@ldf_uid_list,500)
               );


        COMMIT TRANSACTION;

        SET @proc_step_name='SP_COMPLETE';
        SET @proc_step_no = 8;

        INSERT INTO [dbo].[job_flow_log]
        (
          batch_id
        ,[create_dttm]
        ,[update_dttm]
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
               ,current_timestamp
               ,current_timestamp
               ,@dataflow_name
               ,@package_name
               ,'COMPLETE'
               ,@proc_step_no
               ,@proc_step_name
               ,0
               ,LEFT(@ldf_uid_list,500)
               );

        select 'Success';


    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        /* Logging */
        INSERT INTO [dbo].[job_flow_log]
        (
          batch_id
        ,[create_dttm]
        ,[update_dttm]
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1]
        )
        VALUES
            (
              @batch_id
            ,current_timestamp
            ,current_timestamp
            ,@dataflow_name
            ,@package_name
            ,'ERROR'
            ,@Proc_Step_no
            , 'Step -' +CAST(@Proc_Step_no AS VARCHAR(3))+' -' +CAST(@ErrorMessage AS VARCHAR(500))
            ,0
            ,LEFT(@ldf_uid_list,500)
            );


        RETURN @ErrorMessage;


    END CATCH

END;