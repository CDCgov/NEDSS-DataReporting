IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_nrt_ldf_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_nrt_ldf_postprocessing]
END
GO 

CREATE PROCEDURE dbo.sp_nrt_ldf_postprocessing @ldf_uid_list nvarchar(max), @debug bit = 'false'
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

        set @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);
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

--------------------------------------------------------------------------------------------------------
        SET @proc_step_name='Create #LDF_UID_LIST Table';
        SET @proc_step_no = @proc_step_no +1;

        IF OBJECT_ID('#LDF_UID_LIST', 'U') IS NOT NULL
			    DROP TABLE #LDF_UID_LIST;

        SELECT distinct TRIM(value) AS value  
        INTO  #LDF_UID_LIST
        FROM STRING_SPLIT(@ldf_uid_list, ',')

        if @debug = 'true' select * from #LDF_UID_LIST;
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

--------------------------------------------------------------------------------------------------------
        SET @proc_step_name='Create #DEL_LDF_DATA_KEY to capture delete events';
        SET @proc_step_no = @proc_step_no +1;

        IF OBJECT_ID('#DEL_LDF_DATA_KEY', 'U') IS NOT NULL
          DROP TABLE #DEL_LDF_DATA_KEY;

        select distinct ld.LDF_DATA_KEY, ld.LDF_GROUP_KEY
        into #DEL_LDF_DATA_KEY
        from dbo.ldf_data ld with (nolock)
        inner join dbo.nrt_ldf_data_key nld with (nolock)
          on nld.d_ldf_data_key = ld.LDF_DATA_KEY
        inner join #LDF_UID_LIST ldf_uid_list with (nolock) 
          on ldf_uid_list.value = nld.ldf_uid
        inner join dbo.nrt_ldf_data nrt_ldf_data with (nolock) 
          on nrt_ldf_data.ldf_uid = nld.ldf_uid and 
          nrt_ldf_data.business_object_uid = nld.business_object_uid
        inner join dbo.nrt_odse_state_defined_field_metadata sdfmd with (nolock) 
          on sdfmd.ldf_uid = nld.ldf_uid
        where nrt_ldf_data.RECORD_STATUS_CD is null
        or sdfmd.active_ind = 'N';

        if @debug = 'true' select * from #DEL_LDF_DATA_KEY;
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
               
------------------------------------------------------------------------------------------------------
        declare @backfill_list nvarchar(max);  
        SET @backfill_list = 
        ( 
          SELECT string_agg(t.value, ',')
          FROM (SELECT distinct TRIM(value) AS value FROM STRING_SPLIT(@ldf_uid_list, ',')) t
                    left join #DEL_LDF_DATA_KEY tmp
                    on tmp.ldf_uid = t.value	
                    WHERE tmp.ldf_uid is null	
        );

        IF @backfill_list IS NOT NULL
        BEGIN
            SELECT
                CAST(NULL AS BIGINT) AS public_health_case_uid,
                CAST(NULL AS BIGINT) AS patient_uid,
                CAST(NULL AS BIGINT) AS observation_uid,
                'Error' AS datamart,
                CAST(NULL AS VARCHAR(50))  AS condition_cd,
                'Missing NRT Record: sp_nrt_ldf_postprocessing' AS stored_procedure,
                CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
                WHERE 1=1;
           RETURN;
        END
		------------------------------------------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Delete Records from nrt_ldf_data_key';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        delete T 
        from dbo.nrt_ldf_data_key T with (nolock)
        inner join #DEL_LDF_DATA_KEY dldk
          on dldk.LDF_DATA_KEY = T.d_ldf_data_key
        
        COMMIT TRANSACTION;

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

--------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Delete Records from ldf_data';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        delete T 
        from dbo.ldf_data T with (nolock)
        inner join #DEL_LDF_DATA_KEY dldk
          on dldk.LDF_DATA_KEY = T.LDF_DATA_KEY
        
        COMMIT TRANSACTION;

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

--------------------------------------------------------------------------------------------------------
        SET @proc_step_name='Create #DEL_GROUP_KEY';
        SET @proc_step_no = @proc_step_no +1;

        
        IF OBJECT_ID('#DEL_GROUP_KEY', 'U') IS NOT NULL
          DROP TABLE #DEL_GROUP_KEY;

        select distinct lg.ldf_group_key 
        into #DEL_GROUP_KEY
        from dbo.ldf_group lg with (nolock)
        left join (select distinct ldf_group_key from dbo.LDF_DATA with (nolock)) nld
          on nld.ldf_group_key = lg.ldf_group_key
        where nld.LDF_GROUP_KEY is null;

        if @debug = 'true' select * from #DEL_GROUP_KEY;
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
--------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Delete Records from nrt_ldf_group_key';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        delete T from 
        dbo.nrt_ldf_group_key T with (nolock)
        inner join  #DEL_GROUP_KEY dldk
        on T.d_ldf_group_key = dldk.ldf_group_key;
        
        COMMIT TRANSACTION;

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

--------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Delete Records from PATIENT_LDF_GROUP';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        delete T from 
        dbo.PATIENT_LDF_GROUP T with (nolock)
        inner join  #DEL_GROUP_KEY dldk
        on T.ldf_group_key = dldk.ldf_group_key;
        
        COMMIT TRANSACTION;

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

--------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Delete Records from ORGANIZATION_LDF_GROUP';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        delete T from 
        dbo.ORGANIZATION_LDF_GROUP T with (nolock)
        inner join  #DEL_GROUP_KEY dldk
        on T.ldf_group_key = dldk.ldf_group_key;
        
        COMMIT TRANSACTION;

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

--------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Delete Records from PROVIDER_LDF_GROUP';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        delete T from 
        dbo.PROVIDER_LDF_GROUP T with (nolock)
        inner join  #DEL_GROUP_KEY dldk
        on T.ldf_group_key = dldk.ldf_group_key;
        
        COMMIT TRANSACTION;

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

/* Handling Updates in the DM tables when there is a delete in the group */
--------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Update BMIRD_CASE';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        update T 
        set ldf_group_key = 1
        from dbo.BMIRD_CASE T with (nolock)
        inner join  #DEL_GROUP_KEY dldk
        on T.ldf_group_key = dldk.ldf_group_key;
        
        COMMIT TRANSACTION;

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

--------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Update CRS_CASE';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        update T 
        set ldf_group_key = 1
        from dbo.CRS_CASE T with (nolock)
        inner join  #DEL_GROUP_KEY dldk
        on T.ldf_group_key = dldk.ldf_group_key;
        
        COMMIT TRANSACTION;

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

--------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Update GENERIC_CASE';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        update T 
        set ldf_group_key = 1
        from dbo.GENERIC_CASE T with (nolock)
        inner join  #DEL_GROUP_KEY dldk
        on T.ldf_group_key = dldk.ldf_group_key;
        
        COMMIT TRANSACTION;

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
--------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Update HEPATITIS_CASE';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        update T 
        set ldf_group_key = 1
        from dbo.HEPATITIS_CASE T with (nolock)
        inner join  #DEL_GROUP_KEY dldk
        on T.ldf_group_key = dldk.ldf_group_key;
        
        COMMIT TRANSACTION;

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
--------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Update MEASLES_CASE';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        update T 
        set ldf_group_key = 1
        from dbo.MEASLES_CASE T with (nolock)
        inner join  #DEL_GROUP_KEY dldk
        on T.ldf_group_key = dldk.ldf_group_key;
        
        COMMIT TRANSACTION;

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
--------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Update RUBELLA_CASE';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        update T 
        set ldf_group_key = 1
        from dbo.RUBELLA_CASE T with (nolock)
        inner join  #DEL_GROUP_KEY dldk
        on T.ldf_group_key = dldk.ldf_group_key;
        
        COMMIT TRANSACTION;

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
--------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Update PERTUSSIS_CASE';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        update T 
        set ldf_group_key = 1
        from dbo.PERTUSSIS_CASE T with (nolock)
        inner join  #DEL_GROUP_KEY dldk
        on T.ldf_group_key = dldk.ldf_group_key;
        
        COMMIT TRANSACTION;

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
--------------------------------------------------------------------------------------------------------
        SET @proc_step_name='Update SUMMARY_REPORT_CASE';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        update T 
        set ldf_group_key = 1
        from dbo.SUMMARY_REPORT_CASE T with (nolock)
        inner join  #DEL_GROUP_KEY dldk
        on T.ldf_group_key = dldk.ldf_group_key;
        
        COMMIT TRANSACTION;

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
--------------------------------------------------------------------------------------------------------

        SET @proc_step_name='Delete Records from ldf_group';
        SET @proc_step_no = @proc_step_no +1;

        BEGIN TRANSACTION

        delete T from 
        dbo.ldf_group T with (nolock)
        inner join  #DEL_GROUP_KEY dldk
        on T.ldf_group_key = dldk.ldf_group_key;
        
        COMMIT TRANSACTION;

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
------------------------------------------------------------------------------------------------------
        SET @proc_step_name='Get Business IDS to delete';
        SET @proc_step_no = @proc_step_no +1;

        IF OBJECT_ID('#tmp_business_object_uids', 'U') IS NOT NULL
          DROP TABLE #tmp_business_object_uids;

        select distinct nrt.business_object_uid
        into #tmp_business_object_uids
        from dbo.nrt_ldf_data nrt with (nolock)
        inner join dbo.ldf_group lg with (nolock)
          on nrt.business_object_uid = lg.business_object_uid
        inner join #LDF_UID_LIST ldf
          on nrt.ldf_uid = ldf.value

        if @debug = 'true' select * from #DEL_LDF_DATA_KEY;
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

------------------------------------------------------------------------------------------------------
        BEGIN TRANSACTION;

        SET @proc_step_name='Delete from LDF_DATA';
        SET @proc_step_no = @proc_step_no +1;


        delete d  
        from dbo.ldf_data d with (nolock)
        inner join dbo.ldf_group lg with (nolock)
          on d.LDF_GROUP_KEY = lg.LDF_GROUP_KEY
        inner join #tmp_business_object_uids tmp
          on lg.business_object_uid = tmp.business_object_uid
        left join dbo.nrt_ldf_data_key lk with (nolock)
        on lk.d_ldf_data_key = d.ldf_data_key
        where lk.d_ldf_data_key is null;

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
--------------------------------------------------------------------------------------------------------              
      BEGIN TRANSACTION;
        SET @proc_step_name='Create LDF_DATA Temp tables-'+ LEFT(@ldf_uid_list,105);
        SET @proc_step_no = @proc_step_no +1;

        IF OBJECT_ID('#tmp_ldf_data', 'U') IS NOT NULL
          DROP TABLE #tmp_ldf_data;


        /**Create temp table for LDF_DATA */
         select
            ldf.ldf_data_key,
            lgk.d_ldf_group_key as ldf_group_key,
            ld.ldf_uid,
            ld.business_object_uid,
            ld.ldf_column_type,
            ld.condition_cd,
            ld.condition_desc_txt,
            ld.cdc_national_id,
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
                 left join dbo.nrt_ldf_data_key nldk with (nolock) ON ld.ldf_uid = nldk.ldf_uid and ld.business_object_uid = nldk.business_object_uid
                 left join dbo.nrt_ldf_group_key lgk with (nolock) ON lgk.business_object_uid = ld.business_object_uid
                 left join dbo.ldf_data ldf with (nolock) ON nldk.d_ldf_data_key = ldf.ldf_data_key and nldk.d_ldf_group_key = ldf.ldf_group_key
        inner join dbo.nrt_odse_state_defined_field_metadata sdfmd with (nolock) 
          on sdfmd.ldf_uid = ld.ldf_uid
        inner join #LDF_UID_LIST ldf_uid_list 
          on ldf_uid_list.value = ld.ldf_uid
        where ld.RECORD_STATUS_CD is not null
        and sdfmd.active_ind <> 'N';
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

      COMMIT TRANSACTION;
  --------------------------------------------------------------------------------------------------------              
        BEGIN TRANSACTION;

        SET @proc_step_name='Update nrt_ldf_data_key updated_dttm';
        SET @proc_step_no = @proc_step_no +1;

        UPDATE tgt 
        SET tgt.[updated_dttm] = GETDATE()
        FROM [dbo].nrt_ldf_data_key tgt 
        INNER JOIN #tmp_ldf_data tmp
            on tmp.ldf_data_key = tgt.d_ldf_data_key;

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

      COMMIT TRANSACTION;
--------------------------------------------------------------------------------------------------------              
      BEGIN TRANSACTION;
        SET @proc_step_name='Update nrt_ldf_group_key updated_dttm';
        SET @proc_step_no = @proc_step_no +1;

        UPDATE tgt 
        SET tgt.[updated_dttm] = GETDATE()
        FROM [dbo].nrt_ldf_group_key tgt 
        INNER JOIN #tmp_ldf_data tmp
            on tmp.ldf_group_key = tgt.d_ldf_group_key;

       
        if @debug = 'true' select * from #DEL_LDF_DATA_KEY;
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

      COMMIT TRANSACTION;         
--------------------------------------------------------------------------------------------------------                   
        
        BEGIN TRANSACTION;
        SET @proc_step_name='Update LDF_DATA Dimension';
        SET @proc_step_no = @proc_step_no +1;


        /** Update condition for LDF_DATA*/
        UPDATE dbo.ldf_data
        SET
            ldf_data_key = ld.ldf_data_key
          ,ldf_group_key = ld.ldf_group_key
          ,ldf_column_type = ld.ldf_column_type
          ,condition_cd = ld.condition_cd
          ,condition_desc_txt = ld.condition_desc_txt
          ,cdc_national_id = ld.cdc_national_id
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

        COMMIT TRANSACTION;

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

        SET @proc_step_name='Insert into LDF_GROUP Dimension';
        SET @proc_step_no = @proc_step_no +1;

        /**Create new keys for LDF_Group*/
        insert into dbo.nrt_ldf_group_key (business_object_uid)
        select distinct tld.business_object_uid from #tmp_ldf_data tld
        	left join dbo.nrt_ldf_group_key nl with (nolock) on nl.business_object_uid = tld.business_object_uid
        where nl.business_object_uid is null
        order by tld.business_object_uid;

        insert into dbo.ldf_group(ldf_group_key, business_object_uid)
        select distinct lgk.d_ldf_group_key, lgk.business_object_uid
        from #tmp_ldf_data ld
        	join dbo.nrt_ldf_group_key lgk with (nolock) on ld.business_object_uid = lgk.business_object_uid
            left join ldf_group lg with (nolock) on lg.ldf_group_key = lgk.d_ldf_group_key
     where lg.ldf_group_key is null;

        insert into dbo.nrt_ldf_data_key(d_ldf_group_key, business_object_uid, ldf_uid)
        select distinct lg.d_ldf_group_key, lg.business_object_uid, ld.ldf_uid
    from #tmp_ldf_data ld
                 left join dbo.nrt_ldf_group_key lg with (nolock) on ld.business_object_uid = lg.business_object_uid
                 left join dbo.nrt_ldf_data_key nldk with (nolock) on ld.ldf_uid = nldk.ldf_uid and ld.business_object_uid = nldk.business_object_uid
        where nldk.d_ldf_data_key is null and nldk.d_ldf_group_key is null;

        COMMIT TRANSACTION;

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

        SET @proc_step_name='Insert into LDF_DATA Dimension';
        SET @proc_step_no = @proc_step_no +1;


        insert into dbo.ldf_data
        (ldf_data_key
        ,ldf_group_key
        ,ldf_column_type
        ,condition_cd
        ,condition_desc_txt
        ,cdc_national_id
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
             ,tld.cdc_national_id  
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

        COMMIT TRANSACTION;

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

        SET @proc_step_name='Update PATIENT_LDF_GROUP Dimension';
        SET @proc_step_no = @proc_step_no +1;

       	UPDATE
	       	dbo.PATIENT_LDF_GROUP
	       	SET
	       	RECORD_STATUS_CD = d.patient_record_status
	        from dbo.ldf_group ldf with (nolock)
	        inner join dbo.d_patient d with (nolock) on ldf.business_object_uid = d.patient_uid
        	inner join (select distinct business_object_uid from #tmp_ldf_data) ld on ldf.business_object_uid = ld.business_object_uid
          inner join dbo.PATIENT_LDF_GROUP plg with (nolock) on plg.patient_key = d.patient_key and plg.LDF_GROUP_KEY = ldf.ldf_group_key; --join on UID with nrt_ldf_data_key

        SET @proc_step_name='Insert into PATIENT_LDF_GROUP Dimension';
        SET @proc_step_no = @proc_step_no +1;

        insert into dbo.PATIENT_LDF_GROUP
        (PATIENT_KEY, LDF_GROUP_KEY, RECORD_STATUS_CD)
        select distinct d.patient_key, ldf.ldf_group_key, d.patient_record_status
        from dbo.ldf_group ldf
        	inner join (select distinct business_object_uid from #tmp_ldf_data) ld on ldf.business_object_uid = ld.business_object_uid --join on UID with nrt_ldf_data_key
          inner join dbo.d_patient d with (nolock) on ldf.business_object_uid = d.patient_uid
          left join dbo.PATIENT_LDF_GROUP plg with (nolock)
            on plg.patient_key = d.patient_key
            and plg.LDF_GROUP_KEY = ldf.ldf_group_key
        where plg.patient_key is null and plg.LDF_GROUP_KEY is null;

        COMMIT TRANSACTION;

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

        SET @proc_step_name='Update PROVIDER_LDF_GROUP Dimension';
        SET @proc_step_no = @proc_step_no +1;

        UPDATE
	       	dbo.PROVIDER_LDF_GROUP
	       	SET
	       	RECORD_STATUS_CD = d.provider_record_status
	       from dbo.ldf_group ldf with (nolock)
	        inner join dbo.d_provider d with (nolock) on ldf.business_object_uid = d.provider_uid
        	inner join (select distinct business_object_uid from #tmp_ldf_data) ld on ldf.business_object_uid = ld.business_object_uid
          inner join dbo.PROVIDER_LDF_GROUP plg with (nolock) on plg.provider_key = d.provider_key and plg.LDF_GROUP_KEY = ldf.ldf_group_key; --join on UID with nrt_ldf_data_key


        SET @proc_step_name='Insert into PROVIDER_LDF_GROUP Dimension';
        SET @proc_step_no = @proc_step_no +1;

        insert into dbo.PROVIDER_LDF_GROUP
        (PROVIDER_KEY, LDF_GROUP_KEY, RECORD_STATUS_CD)
        select distinct d.provider_key, ldf.ldf_group_key, d.provider_record_status
        from dbo.ldf_group ldf
        	inner join (select distinct business_object_uid from #tmp_ldf_data) ld on ldf.business_object_uid = ld.business_object_uid --join on UID with nrt_ldf_data_key
          inner join dbo.d_provider d with (nolock) on ldf.business_object_uid = d.provider_uid
          left join dbo.PROVIDER_LDF_GROUP plg with (nolock)
            on plg.provider_key = d.provider_key
            and plg.LDF_GROUP_KEY = ldf.ldf_group_key
        where plg.provider_key is null and plg.LDF_GROUP_KEY is null;

        COMMIT TRANSACTION;

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

        SET @proc_step_name='Update ORGANIZATION_LDF_GROUP Dimension';
        SET @proc_step_no = @proc_step_no +1;

        UPDATE
	       	dbo.ORGANIZATION_LDF_GROUP
	       	SET
	       	RECORD_STATUS_CD = d.organization_record_status
	        from dbo.ldf_group ldf with (nolock)
	        inner join dbo.d_organization d with (nolock) on ldf.business_object_uid = d.organization_uid
        	inner join (select distinct business_object_uid from #tmp_ldf_data) ld on ldf.business_object_uid = ld.business_object_uid
          inner join dbo.ORGANIZATION_LDF_GROUP plg with (nolock) on plg.organization_key = d.organization_key and plg.LDF_GROUP_KEY = ldf.ldf_group_key; --join on UID with nrt_ldf_data_key

	      
        SET @proc_step_name='Insert into ORGANIZATION_LDF_GROUP Dimension';
        SET @proc_step_no = @proc_step_no +1;

        insert into dbo.ORGANIZATION_LDF_GROUP
        (ORGANIZATION_KEY, LDF_GROUP_KEY, RECORD_STATUS_CD)
        select d.organization_key, ldf.ldf_group_key, d.organization_record_status
        from dbo.ldf_group ldf
        	inner join (select distinct business_object_uid from #tmp_ldf_data) ld on ldf.business_object_uid = ld.business_object_uid --join on UID with nrt_ldf_data_key
          inner join dbo.d_organization d with (nolock) on ldf.business_object_uid = d.organization_uid
          left join dbo.ORGANIZATION_LDF_GROUP plg with (nolock)
            on plg.organization_key = d.organization_key
            and plg.LDF_GROUP_KEY = ldf.ldf_group_key
        where plg.organization_key is null and plg.LDF_GROUP_KEY is null;

        COMMIT TRANSACTION;

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


        SET @proc_step_name='SP_COMPLETE';
        SET @proc_step_no = 999;

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

        SELECT
            CAST(NULL AS BIGINT) AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            CAST(NULL AS VARCHAR(30)) AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            CAST(NULL AS VARCHAR(200)) AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=0;



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

        /* Logging */
        INSERT INTO [dbo].[job_flow_log]
        ( batch_id,[create_dttm],[update_dttm],[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count],[msg_description1],[Error_Description])
        VALUES
        (@batch_id,current_timestamp,current_timestamp,@dataflow_name,@package_name,'ERROR',@Proc_Step_no,@proc_step_name,0,LEFT(@ldf_uid_list,500),@FullErrorMessage);


        SELECT
          CAST(NULL AS BIGINT) AS public_health_case_uid,
          CAST(NULL AS BIGINT) AS patient_uid,
          CAST(NULL AS BIGINT) AS observation_uid,
          'Error' AS datamart,
          CAST(NULL AS VARCHAR(50))  AS condition_cd,
          @FullErrorMessage AS stored_procedure,
          CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
          WHERE 1=1;


    END CATCH

END;