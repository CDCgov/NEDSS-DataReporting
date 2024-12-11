CREATE OR ALTER PROCEDURE dbo.sp_nrt_provider_postprocessing @id_list nvarchar(max), @debug bit = 'false'
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
        declare @dataflow_name varchar(200) = 'Provider POST-Processing';
        declare @package_name varchar(200) = 'sp_nrt_provider_postprocessing';

        set @batch_id = cast((format(getdate(),'yyMMddHHmmss')) as bigint);

        INSERT INTO [dbo].[job_flow_log]
        (     batch_id
        ,[create_dttm]
        ,[update_dttm]
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[msg_description1]
        ,[row_count])
        VALUES (
                 @batch_id
               , @create_dttm
               , @update_dttm
               , @dataflow_name
               , @package_name
               , 'START'
               , 0
               , 'SP_Start'
               , LEFT (@id_list, 500)
               , 0
               );

        SET @proc_step_name='Create PROVIDER Temp tables for -'+ LEFT(@id_list,165);
        SET @proc_step_no = 1;

        /* Temp Provider Table*/
        select PROVIDER_KEY,
               nrt.provider_uid                             as PROVIDER_UID,
               local_id                                     as PROVIDER_LOCAL_ID,
               record_status                                as PROVIDER_RECORD_STATUS,
               name_prefix                                  as PROVIDER_NAME_PREFIX,
               first_name                                   as PROVIDER_FIRST_NAME,
               middle_name                                  as PROVIDER_MIDDLE_NAME,
               last_name                                    as PROVIDER_LAST_NAME,
               name_suffix                                  as PROVIDER_NAME_SUFFIX,
               name_degree                                  as PROVIDER_NAME_DEGREE,
               general_comments                             as PROVIDER_GENERAL_COMMENTS,
               case when rtrim(ltrim(quick_code)) = '' then null
                    else quick_code end                     AS PROVIDER_QUICK_CODE,
               nrt.provider_registration_num                as PROVIDER_REGISTRATION_NUM,
               case when rtrim(ltrim(provider_registration_num_auth)) = '' then null
                    else provider_registration_num_auth end AS PROVIDER_REGISRATION_NUM_AUTH,
               case when rtrim(ltrim(street_address_1)) = '' then null
                    else street_address_1 end               AS PROVIDER_STREET_ADDRESS_1,
               case when rtrim(ltrim(street_address_2)) = '' then null
                    else street_address_2 end               AS PROVIDER_STREET_ADDRESS_2,
               city                                         as PROVIDER_CITY,
               state                                        as PROVIDER_STATE,
               state_code                                   as PROVIDER_STATE_CODE,
               zip                                          as PROVIDER_ZIP,
               county                                       as PROVIDER_COUNTY,
               case when rtrim(ltrim(county_code)) = '' then null
                    else county_code end                    AS PROVIDER_COUNTY_CODE,
               country                                      as PROVIDER_COUNTRY,
               case when rtrim(ltrim(address_comments)) = '' then null
                    else address_comments end               AS PROVIDER_ADDRESS_COMMENTS,
               case when rtrim(ltrim(phone_work)) = '' then null
                    else phone_work end                     AS PROVIDER_PHONE_WORK,
               case when rtrim(ltrim(phone_ext_work)) = '' then null
                    else phone_ext_work end                 AS PROVIDER_PHONE_EXT_WORK,
               email_work                                   as PROVIDER_EMAIL_WORK,
               case when rtrim(ltrim(phone_comments)) = '' then null
                    else phone_comments end                 AS PROVIDER_PHONE_COMMENTS,
               phone_cell                                   as PROVIDER_PHONE_CELL,
               entry_method                                 as PROVIDER_ENTRY_METHOD,
               add_user_name                                as PROVIDER_ADDED_BY,
               add_time                                     as PROVIDER_ADD_TIME,
               last_chg_user_name                           as PROVIDER_LAST_UPDATED_BY,
               last_chg_time                                as PROVIDER_LAST_CHANGE_TIME
        into #temp_prv_table
        from dbo.nrt_provider nrt
                 left join dbo.d_provider p with (nolock) on p.provider_uid = nrt.provider_uid
        where nrt.provider_uid in (SELECT value FROM STRING_SPLIT(@id_list, ','));

        if @debug = 'true' select * from #temp_prv_table;

        /* Logging */
        set @rowcount=@@rowcount
        INSERT
        INTO [dbo].[job_flow_log]
        (     batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (
                 @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               , LEFT (@id_list, 500)
               );

        SET @proc_step_name='Update D_PROVIDER Dimension';
        SET @proc_step_no = 2;

        /* D_Provider Update Operation */
        BEGIN TRANSACTION;
        update dbo.d_provider
        set [PROVIDER_UID] = prv.[PROVIDER_UID], [PROVIDER_KEY] = prv.[PROVIDER_KEY], [PROVIDER_LOCAL_ID] = prv.[PROVIDER_LOCAL_ID], [PROVIDER_RECORD_STATUS] = prv.[PROVIDER_RECORD_STATUS], [PROVIDER_NAME_PREFIX] = prv.[PROVIDER_NAME_PREFIX], [PROVIDER_FIRST_NAME] = prv.[PROVIDER_FIRST_NAME], [PROVIDER_MIDDLE_NAME] = prv.[PROVIDER_MIDDLE_NAME], [PROVIDER_LAST_NAME] = prv.[PROVIDER_LAST_NAME], [PROVIDER_NAME_SUFFIX] = prv.[PROVIDER_NAME_SUFFIX], [PROVIDER_NAME_DEGREE] = prv.[PROVIDER_NAME_DEGREE], [PROVIDER_GENERAL_COMMENTS] = prv.[PROVIDER_GENERAL_COMMENTS], [PROVIDER_QUICK_CODE] = substring (prv.[PROVIDER_QUICK_CODE], 1, 50), [PROVIDER_REGISTRATION_NUM] = substring (prv.[PROVIDER_REGISTRATION_NUM], 1, 50), [PROVIDER_REGISRATION_NUM_AUTH] = substring (prv.[PROVIDER_REGISRATION_NUM_AUTH], 1, 50), [PROVIDER_STREET_ADDRESS_1] = substring (prv.[PROVIDER_STREET_ADDRESS_1], 1, 50), [PROVIDER_STREET_ADDRESS_2] = substring (prv.[PROVIDER_STREET_ADDRESS_2], 1, 50), [PROVIDER_CITY] = substring (prv.[PROVIDER_CITY], 1, 50), [PROVIDER_STATE] = prv.[PROVIDER_STATE], [PROVIDER_STATE_CODE] = prv.[PROVIDER_STATE_CODE], [PROVIDER_ZIP] = prv.[PROVIDER_ZIP], [PROVIDER_COUNTY] = prv.[PROVIDER_COUNTY], [PROVIDER_COUNTY_CODE] = prv.[PROVIDER_COUNTY_CODE], [PROVIDER_COUNTRY] = prv.[PROVIDER_COUNTRY], [PROVIDER_ADDRESS_COMMENTS] = prv.[PROVIDER_ADDRESS_COMMENTS], [PROVIDER_PHONE_WORK] = prv.[PROVIDER_PHONE_WORK], [PROVIDER_PHONE_EXT_WORK] = prv.[PROVIDER_PHONE_EXT_WORK], [PROVIDER_EMAIL_WORK] = substring (prv.[PROVIDER_EMAIL_WORK], 1, 50), [PROVIDER_PHONE_COMMENTS] = prv.[PROVIDER_PHONE_COMMENTS], [PROVIDER_PHONE_CELL] = prv.[PROVIDER_PHONE_CELL], [PROVIDER_ENTRY_METHOD] = prv.[PROVIDER_ENTRY_METHOD], [PROVIDER_LAST_CHANGE_TIME] = prv.[PROVIDER_LAST_CHANGE_TIME], [PROVIDER_ADD_TIME] = prv.[PROVIDER_ADD_TIME], [PROVIDER_ADDED_BY] = prv.[PROVIDER_ADDED_BY], [PROVIDER_LAST_UPDATED_BY] = prv.[PROVIDER_LAST_UPDATED_BY]
        from #temp_prv_table prv
                 inner join dbo.d_provider p with (nolock)
                            on prv.provider_uid = p.provider_uid
                                and prv.provider_key = p.provider_key
                                and p.provider_key is not null;


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

        SET @proc_step_name='Insert into D_PROVIDER Dimension';
        SET @proc_step_no = 3;

        /* D_Provider Insert Operation */

        -- delete from the key table to generate new keys for the resulting new data to be inserted
        delete from dbo.nrt_provider_key;
        insert into dbo.nrt_provider_key(provider_uid)
        select provider_uid
        from #temp_prv_table
        where provider_key is null
        order by provider_uid;

        insert into dbo.d_provider
        ([PROVIDER_UID]
        ,[PROVIDER_KEY]
        ,[PROVIDER_LOCAL_ID]
        ,[PROVIDER_RECORD_STATUS]
        ,[PROVIDER_NAME_PREFIX]
        ,[PROVIDER_FIRST_NAME]
        ,[PROVIDER_MIDDLE_NAME]
        ,[PROVIDER_LAST_NAME]
        ,[PROVIDER_NAME_SUFFIX]
        ,[PROVIDER_NAME_DEGREE]
        ,[PROVIDER_GENERAL_COMMENTS]
        ,[PROVIDER_QUICK_CODE]
        ,[PROVIDER_REGISTRATION_NUM]
        ,[PROVIDER_REGISRATION_NUM_AUTH]
        ,[PROVIDER_STREET_ADDRESS_1]
        ,[PROVIDER_STREET_ADDRESS_2]
        ,[PROVIDER_CITY]
        ,[PROVIDER_STATE]
        ,[PROVIDER_ZIP]
        ,[PROVIDER_COUNTY]
        ,[PROVIDER_COUNTRY]
        ,[PROVIDER_ADDRESS_COMMENTS]
        ,[PROVIDER_PHONE_WORK]
        ,[PROVIDER_PHONE_EXT_WORK]
        ,[PROVIDER_EMAIL_WORK]
        ,[PROVIDER_PHONE_COMMENTS]
        ,[PROVIDER_PHONE_CELL]
        ,[PROVIDER_ENTRY_METHOD]
        ,[PROVIDER_LAST_CHANGE_TIME]
        ,[PROVIDER_ADD_TIME]
        ,[PROVIDER_ADDED_BY]
        ,[PROVIDER_LAST_UPDATED_BY]
        ,[PROVIDER_STATE_CODE]
        ,[PROVIDER_COUNTY_CODE])
        SELECT prv.[PROVIDER_UID]
             , k.[d_PROVIDER_KEY] as PROVIDER_KEY
             , prv.[PROVIDER_LOCAL_ID]
             , prv.[PROVIDER_RECORD_STATUS]
             , prv.[PROVIDER_NAME_PREFIX]
             , prv.[PROVIDER_FIRST_NAME]
             , prv.[PROVIDER_MIDDLE_NAME]
             , prv.[PROVIDER_LAST_NAME]
             , prv.[PROVIDER_NAME_SUFFIX]
             , prv.[PROVIDER_NAME_DEGREE]
             , prv.[PROVIDER_GENERAL_COMMENTS]
             , case when cast(prv.PROVIDER_QUICK_CODE as varchar(50)) = '' then null
                    else cast(prv.PROVIDER_QUICK_CODE as varchar(50)) end
             , case when cast(prv.[PROVIDER_REGISTRATION_NUM] as varchar(50)) = '' then null
                    else cast(prv.[PROVIDER_REGISTRATION_NUM] as varchar(50)) end
             , case when cast(prv.[PROVIDER_REGISRATION_NUM_AUTH] as varchar(50)) = '' then null
                    else cast(prv.[PROVIDER_REGISRATION_NUM_AUTH] as varchar(50)) end
             , case when cast(prv.[PROVIDER_STREET_ADDRESS_1] as varchar(50)) = '' then null
                    else cast(prv.[PROVIDER_STREET_ADDRESS_1] as varchar(50)) end
             , case when cast(prv.[PROVIDER_STREET_ADDRESS_2] as varchar(50)) = '' then null
                    else cast(prv.[PROVIDER_STREET_ADDRESS_2] as varchar(50)) end
             , case when cast(prv.[PROVIDER_CITY] as varchar(50)) = '' then null
                    else cast(prv.[PROVIDER_CITY] as varchar(50)) end
             , prv.[PROVIDER_STATE]
             , prv.[PROVIDER_ZIP]
             , prv.[PROVIDER_COUNTY]
             , prv.[PROVIDER_COUNTRY]
             , case when prv.[PROVIDER_ADDRESS_COMMENTS] = '' then null else prv.[PROVIDER_ADDRESS_COMMENTS] end
             , case when prv.[PROVIDER_PHONE_WORK] = '' then null else prv.[PROVIDER_PHONE_WORK] end
             , case when prv.[PROVIDER_PHONE_EXT_WORK] = '' then null else prv.[PROVIDER_PHONE_EXT_WORK] end
             , case when cast(prv.[PROVIDER_EMAIL_WORK] as varchar(50)) = '' then null
                    else cast(prv.[PROVIDER_EMAIL_WORK] as varchar(50)) end
             , case when prv.[PROVIDER_PHONE_COMMENTS] = '' then null else prv.[PROVIDER_PHONE_COMMENTS] end
             , prv.[PROVIDER_PHONE_CELL]
             , prv.[PROVIDER_ENTRY_METHOD]
             , prv.[PROVIDER_LAST_CHANGE_TIME]
             , prv.[PROVIDER_ADD_TIME]
             , prv.[PROVIDER_ADDED_BY]
             , prv.[PROVIDER_LAST_UPDATED_BY]
             , prv.[PROVIDER_STATE_CODE]
             , case when prv.[PROVIDER_COUNTY_CODE] = '' then null else prv.[PROVIDER_COUNTY_CODE] end
        FROM #temp_prv_table prv
                 join dbo.nrt_provider_key k with (nolock) on prv.provider_uid = k.provider_uid
        where prv.provider_key is null;

        /* Logging */
        set
            @rowcount=@@rowcount
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

        select 'Success';

        COMMIT TRANSACTION;

        SET @proc_step_name='SP_COMPLETE';
        SET @proc_step_no = 4;

        INSERT INTO [dbo].[job_flow_log]
        (     batch_id
        ,[create_dttm]
        ,[update_dttm]
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (
                 @batch_id
               , current_timestamp
               , current_timestamp
               , @dataflow_name
               , @package_name
               , 'COMPLETE'
               , @proc_step_no
               , @proc_step_name
               , 0
               , LEFT (@id_list, 500)
               );

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        /* Logging */
        INSERT INTO [dbo].[job_flow_log]
        (     batch_id
        ,[create_dttm]
        ,[update_dttm]
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES
            (
              @batch_id
            , current_timestamp
            , current_timestamp
            , @dataflow_name
            , @package_name
            , 'ERROR'
            , @Proc_Step_no
            , 'Step -' + CAST (@Proc_Step_no AS VARCHAR (3))+' -' + CAST (@ErrorMessage AS VARCHAR (500))
            , 0
            , LEFT (@id_list, 500)
            );

        return @ErrorMessage;

    END CATCH

END;