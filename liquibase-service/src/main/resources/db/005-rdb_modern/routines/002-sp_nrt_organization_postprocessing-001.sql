IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_nrt_organization_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_nrt_organization_postprocessing]
END
GO 

CREATE PROCEDURE dbo.sp_nrt_organization_postprocessing @id_list nvarchar(max), @debug bit = 'false'
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
        declare @dataflow_name varchar(200) = 'Organization POST-Processing';
        declare @package_name varchar(200) = 'sp_nrt_organization_postprocessing';

        set @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);

        INSERT INTO [dbo].[job_flow_log] 
        (batch_id,[create_dttm],[update_dttm],[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES 
        (@batch_id,@create_dttm,@update_dttm,@dataflow_name,@package_name,'START',0,'SP_Start',LEFT(@id_list,500),0);

        SET @proc_step_name='Create ORGANIZATION Temp table for -'+ LEFT(@id_list,165);
        SET @proc_step_no = 1;

        /* Temp organization table creation*/
        select
            ORGANIZATION_KEY,
            nrt.organization_uid as ORGANIZATION_UID,
            nrt.local_id as ORGANIZATION_LOCAL_ID,
            nrt.record_status as ORGANIZATION_RECORD_STATUS,
            nrt.organization_name as ORGANIZATION_NAME,
            nrt.general_comments as ORGANIZATION_GENERAL_COMMENTS,
            nrt.quick_code as ORGANIZATION_QUICK_CODE,
            nrt.stand_ind_class as ORGANIZATION_STAND_IND_CLASS,
            nrt.facility_id as ORGANIZATION_FACILITY_ID,
            nrt.facility_id_auth as ORGANIZATION_FACILITY_ID_AUTH,
            case when nrt.street_address_1 = '' then NULL else nrt.street_address_1 end as ORGANIZATION_STREET_ADDRESS_1,
            case when nrt.street_address_2 = '' then NULL else nrt.street_address_2 end as ORGANIZATION_STREET_ADDRESS_2,
            nrt.city as ORGANIZATION_CITY,
            nrt.state as ORGANIZATION_STATE,
            nrt.state_code as ORGANIZATION_STATE_CODE,
            nrt.zip as ORGANIZATION_ZIP,
            nrt.county as ORGANIZATION_COUNTY,
            nrt.county_code as ORGANIZATION_COUNTY_CODE,
            nrt.country as ORGANIZATION_COUNTRY,
            case when nrt.address_comments = '' then NULL else nrt.address_comments end as ORGANIZATION_ADDRESS_COMMENTS,
            nrt.phone_work as ORGANIZATION_PHONE_WORK,
            nrt.phone_ext_work as ORGANIZATION_PHONE_EXT_WORK,
            nrt.email as ORGANIZATION_EMAIL,
            nrt.phone_comments as ORGANIZATION_PHONE_COMMENTS,
            nrt.fax as ORGANIZATION_FAX,
            nrt.entry_method as ORGANIZATION_ENTRY_METHOD,
            nrt.add_user_name as ORGANIZATION_ADDED_BY,
            nrt.add_time as ORGANIZATION_ADD_TIME,
            nrt.last_chg_user_name as ORGANIZATION_LAST_UPDATED_BY,
            nrt.last_chg_time as ORGANIZATION_LAST_CHANGE_TIME
        into #temp_org_table
        from dbo.nrt_organization nrt with (nolock)
                 left join dbo.d_organization o with (nolock) on o.organization_uid = nrt.organization_uid
        where nrt.organization_uid in (SELECT value FROM STRING_SPLIT(@id_list, ','));

        declare @backfill_list nvarchar(max);  
        SET @backfill_list = 
        ( 
          SELECT string_agg(t.value, ',')
          FROM (SELECT distinct TRIM(value) AS value FROM STRING_SPLIT(@id_list, ',')) t
                    left join #temp_org_table tmp
                    on tmp.organization_uid = t.value	
                    WHERE tmp.organization_uid is null	
        );
        IF @backfill_list IS NOT NULL
          BEGIN
            SELECT
                0 AS public_health_case_uid,
                CAST(NULL AS BIGINT) AS patient_uid,
                CAST(NULL AS BIGINT) AS observation_uid,
                'Error' AS datamart,
                CAST(NULL AS VARCHAR(50))  AS condition_cd,
                'Missing NRT Record: sp_nrt_organization_postprocessing' AS stored_procedure,
                CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
                WHERE 1=1;
          RETURN;
        END

        if @debug = 'true' select * from #temp_org_table;


        /* D_Organization Update Operation */
        BEGIN TRANSACTION;

        SET @proc_step_name='Update dbo.nrt_organization_key';
        SET @proc_step_no = 2;

        update k
        SET
          k.updated_dttm = GETDATE()
        FROM dbo.nrt_organization_key k
          INNER JOIN #temp_org_table d
            ON K.d_organization_key = d.ORGANIZATION_KEY;

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
               ,LEFT(@id_list,500)
               );



        SET @proc_step_name='Update D_ORGANIZATION Dimension';
        SET @proc_step_no = 3;

        update dbo.d_organization
        set	[ORGANIZATION_KEY]             = org.ORGANIZATION_KEY,
               [ORGANIZATION_UID]               = org.ORGANIZATION_UID,
               [ORGANIZATION_LOCAL_ID]          = org.ORGANIZATION_LOCAL_ID,
               [ORGANIZATION_RECORD_STATUS]     = org.ORGANIZATION_RECORD_STATUS,
               [ORGANIZATION_NAME]              = CASE WHEN (substring(org.ORGANIZATION_NAME,1,50)) is null then null else substring(org.ORGANIZATION_NAME,1,50) end,
               [ORGANIZATION_GENERAL_COMMENTS]  = org.ORGANIZATION_GENERAL_COMMENTS,
               ORGANIZATION_QUICK_CODE          = CASE WHEN (substring(org.ORGANIZATION_QUICK_CODE,1,50)) is null then null else substring(org.ORGANIZATION_QUICK_CODE,1,50) end,
               [ORGANIZATION_STAND_IND_CLASS]   = org.ORGANIZATION_STAND_IND_CLASS,
               [ORGANIZATION_FACILITY_ID]	   = CASE when (substring(org.ORGANIZATION_FACILITY_ID,1,50)) is null then null else substring(org.ORGANIZATION_FACILITY_ID,1,50) end,
               [ORGANIZATION_FACILITY_ID_AUTH]  = CASE WHEN (substring(org.ORGANIZATION_FACILITY_ID_AUTH,1,50)) is null then null else substring(org.ORGANIZATION_FACILITY_ID_AUTH,1,50) end,
               [ORGANIZATION_STREET_ADDRESS_1]  = substring(org.[ORGANIZATION_STREET_ADDRESS_1] ,1,50),
               [ORGANIZATION_STREET_ADDRESS_2]  = substring(org.[ORGANIZATION_STREET_ADDRESS_2] ,1,50),
               [ORGANIZATION_CITY]			   = substring(org.[ORGANIZATION_CITY],1,50),
               [ORGANIZATION_STATE]             = org.[ORGANIZATION_STATE],
               [ORGANIZATION_STATE_CODE]        = org.[ORGANIZATION_STATE_CODE],
               [ORGANIZATION_ZIP]               = org.[ORGANIZATION_ZIP] ,
               [ORGANIZATION_COUNTY]            = org.[ORGANIZATION_COUNTY] ,
               [ORGANIZATION_COUNTY_CODE]       = org.[ORGANIZATION_COUNTY_CODE] ,
               [ORGANIZATION_COUNTRY]           = org.[ORGANIZATION_COUNTRY],
               [ORGANIZATION_ADDRESS_COMMENTS]  =  org.[ORGANIZATION_ADDRESS_COMMENTS],
               [ORGANIZATION_PHONE_WORK]        =  org.[ORGANIZATION_PHONE_WORK] ,
               [ORGANIZATION_PHONE_EXT_WORK]  =  org.[ORGANIZATION_PHONE_EXT_WORK] ,
               [ORGANIZATION_EMAIL]			   = substring(org.[ORGANIZATION_EMAIL],1,50),
               [ORGANIZATION_PHONE_COMMENTS]    =  org.[ORGANIZATION_PHONE_COMMENTS] ,
               [ORGANIZATION_ENTRY_METHOD]       =  org.[ORGANIZATION_ENTRY_METHOD] ,
               [ORGANIZATION_LAST_CHANGE_TIME]   =  org.[ORGANIZATION_LAST_CHANGE_TIME],
               [ORGANIZATION_ADD_TIME]           =  org.[ORGANIZATION_ADD_TIME] ,
               [ORGANIZATION_ADDED_BY]           =  org.[ORGANIZATION_ADDED_BY]  ,
               [ORGANIZATION_LAST_UPDATED_BY]    =  org.[ORGANIZATION_LAST_UPDATED_BY],
               [ORGANIZATION_FAX]				   =  org.[ORGANIZATION_FAX]
        from #temp_org_table org
                 inner join dbo.d_organization o with (nolock) on org.organization_uid = o.organization_uid
            and org.organization_key = o.organization_key
            and o.organization_key is not null;

        

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
               ,LEFT(@id_list,500)
               );

        SET @proc_step_name='Insert into D_ORAGANIZATION Dimension';
        SET @proc_step_no = 4;

        /* D_Organization Insert Operation */
        

          insert into dbo.nrt_organization_key(organization_uid)
          select organization_uid from #temp_org_table where organization_key is null order by organization_uid;

          insert into dbo.d_organization
          ([ORGANIZATION_KEY]
          ,[ORGANIZATION_UID]
          ,[ORGANIZATION_LOCAL_ID]
          ,[ORGANIZATION_RECORD_STATUS]
          ,[ORGANIZATION_NAME]
          ,[ORGANIZATION_GENERAL_COMMENTS]
          ,[ORGANIZATION_QUICK_CODE]
          ,[ORGANIZATION_STAND_IND_CLASS]
          ,[ORGANIZATION_FACILITY_ID]
          ,[ORGANIZATION_FACILITY_ID_AUTH]
          ,[ORGANIZATION_STREET_ADDRESS_1]
          ,[ORGANIZATION_STREET_ADDRESS_2]
          ,[ORGANIZATION_CITY]
          ,[ORGANIZATION_STATE]
          ,[ORGANIZATION_STATE_CODE]
          ,[ORGANIZATION_ZIP]
          ,[ORGANIZATION_COUNTY]
          ,[ORGANIZATION_COUNTY_CODE]
          ,[ORGANIZATION_COUNTRY]
          ,[ORGANIZATION_ADDRESS_COMMENTS]
          ,[ORGANIZATION_PHONE_WORK]
          ,[ORGANIZATION_PHONE_EXT_WORK]
          ,[ORGANIZATION_EMAIL]
          ,[ORGANIZATION_PHONE_COMMENTS]
          ,[ORGANIZATION_ENTRY_METHOD]
          ,[ORGANIZATION_LAST_CHANGE_TIME]
          ,[ORGANIZATION_ADD_TIME]
          ,[ORGANIZATION_ADDED_BY]
          ,[ORGANIZATION_LAST_UPDATED_BY]
          ,[ORGANIZATION_FAX])
          SELECT  k.d_organization_key  as ORGANIZATION_KEY
                ,org.[ORGANIZATION_UID]
                ,org.[ORGANIZATION_LOCAL_ID]
                ,org.[ORGANIZATION_RECORD_STATUS]
                ,cast(org.ORGANIZATION_NAME as varchar(50)) as ORGANIZATION_NAME
                ,org.[ORGANIZATION_GENERAL_COMMENTS]
                ,isnull(NULLIF(cast(org.[ORGANIZATION_QUICK_CODE] as varchar(50)),''),NULL) as ORGANIZATION_QUICK_CODE
                ,org.[ORGANIZATION_STAND_IND_CLASS]
                ,cast(org.[ORGANIZATION_FACILITY_ID] as varchar(50)) as ORGANIZATION_FACILITY_ID
                ,cast(org.ORGANIZATION_FACILITY_ID_AUTH as varchar(50)) as ORGANIZATION_FACILITY_ID_AUTH
                ,case when cast (org.[ORGANIZATION_STREET_ADDRESS_1] as varchar(50)) is null then null else cast(org.[ORGANIZATION_STREET_ADDRESS_1] as varchar(50)) end
                ,case when cast (org.[ORGANIZATION_STREET_ADDRESS_2] as varchar(50)) is null then null else cast(org.[ORGANIZATION_STREET_ADDRESS_2] as varchar(50)) end
                ,isnull(NULLIF(cast(org.[ORGANIZATION_CITY] as varchar(50)),''),NULL) as ORGANIZATION_CITY
                ,isnull(NULLIF(org.[ORGANIZATION_STATE],''),NULL) as ORGANIZATION_STATE
                ,isnull(NULLIF(org.[ORGANIZATION_STATE_CODE],''),NULL) as ORGANIZATION_STATE_CODE
                ,isnull(NULLIF(cast(org.[ORGANIZATION_ZIP] as varchar(10)),''),NULL) as ORGANIZATION_ZIP
                ,isnull(NULLIF(org.[ORGANIZATION_COUNTY],''),NULL) as ORGANIZATION_COUNTY
                ,isnull(NULLIF(org.[ORGANIZATION_COUNTY_CODE] ,''),NULL) as ORGANIZATION_COUNTY_CODE
                ,isnull(NULLIF(org.[ORGANIZATION_COUNTRY],''),NULL) as ORGANIZATION_COUNTRY
                ,case when org.[ORGANIZATION_ADDRESS_COMMENTS] is null then null else RTRIM(LTRIM(org.[ORGANIZATION_ADDRESS_COMMENTS])) end
                ,case when org.[ORGANIZATION_PHONE_WORK]is  null then null else org.[ORGANIZATION_PHONE_WORK] end
                ,case when org.[ORGANIZATION_PHONE_EXT_WORK] is null then null else org.[ORGANIZATION_PHONE_EXT_WORK] end
                ,isnull(NULLIF(cast(org.[ORGANIZATION_EMAIL] as varchar(50)),''),NULL) as  ORGANIZATION_EMAIL
                ,case when org.[ORGANIZATION_PHONE_COMMENTS] is null then null else RTRIM(LTRIM(org.[ORGANIZATION_PHONE_COMMENTS])) end
                ,org.[ORGANIZATION_ENTRY_METHOD]
                ,org.[ORGANIZATION_LAST_CHANGE_TIME]
                ,org.[ORGANIZATION_ADD_TIME]
                ,org.[ORGANIZATION_ADDED_BY]
                ,org.[ORGANIZATION_LAST_UPDATED_BY]
                ,org.[ORGANIZATION_FAX]
          FROM #temp_org_table org
                    join dbo.nrt_organization_key k with (nolock) on org.organization_uid = k.organization_uid
          where org.organization_key is null;

        /* Logging */
        set @rowcount=@@rowcount
        INSERT INTO [dbo].[job_flow_log] 
        (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count],[msg_description1])
        VALUES 
        ( @batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount,LEFT(@id_list,500));


        COMMIT TRANSACTION;

        SET @proc_step_name='SP_COMPLETE';
        SET @proc_step_no = 4;

        INSERT INTO [dbo].[job_flow_log] (batch_id,[create_dttm],[update_dttm],[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count],[msg_description1])
        VALUES (@batch_id,current_timestamp,current_timestamp,@dataflow_name,@package_name,'COMPLETE',@proc_step_no,@proc_step_name,0,LEFT(@id_list,500));

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

        DECLARE @FullErrorMessage NVARCHAR(4000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        /* Logging */
        INSERT INTO [dbo].[job_flow_log] 
        (batch_id,[create_dttm],[update_dttm],[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count],[msg_description1],[Error_Description])
        VALUES
        (@batch_id,current_timestamp,current_timestamp,@dataflow_name,@package_name,'ERROR',@proc_Step_no,@proc_step_name,0,LEFT(@id_list,500),@FullErrorMessage);

        SELECT
            0 AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            'Error' AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            @FullErrorMessage AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=1;

    END CATCH

END;