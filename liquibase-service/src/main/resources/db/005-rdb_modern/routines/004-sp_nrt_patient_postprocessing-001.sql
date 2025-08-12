IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_nrt_patient_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_nrt_patient_postprocessing]
END
GO 

CREATE PROCEDURE dbo.sp_nrt_patient_postprocessing @id_list nvarchar(max), @debug bit = 'false'
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
        declare @dataflow_name varchar(200) = 'Patient POST-Processing';
        declare @package_name varchar(200) = 'RDB_MODERN.sp_nrt_patient_postprocessing';
        declare @datamart_error nvarchar(MAX) = 'The following datamart updates had an error:';
        declare @return_code INT = 0;
        declare @sql NVARCHAR(MAX) = '';


        set @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);
        declare @dimension_update_tbl_nm VARCHAR(200) = 'DYN_DM_D_PATIENT_UPDATE_' + CAST(@batch_id AS VARCHAR(200));

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[create_dttm],[update_dttm],[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES 
        (@batch_id,@create_dttm,@update_dttm,@dataflow_name,@package_name,'START',0,'SP_Start',LEFT(@id_list,500),0);

        SET @proc_step_name='Create PATIENT Temp tables for -'+ LEFT(@id_list,165);
        SET @proc_step_no = 1;

        /* Temp patient table creation*/
        with src as (
        select
            PATIENT_KEY,
            nrt.patient_uid               AS PATIENT_UID,
            nrt.patient_mpr_uid           AS PATIENT_MPR_UID,
            record_status                 AS PATIENT_RECORD_STATUS,
            local_id                      AS PATIENT_LOCAL_ID,
            case
                when rtrim(ltrim(general_comments)) = '' then null
                else general_comments
            end                                AS PATIENT_GENERAL_COMMENTS,
            first_name                         AS PATIENT_FIRST_NAME,
            case
                when rtrim(ltrim(middle_name)) = '' then null
                else middle_name
            end                                AS PATIENT_MIDDLE_NAME,
            last_name AS PATIENT_LAST_NAME,
            name_suffix AS PATIENT_NAME_SUFFIX,
            alias_nickname AS PATIENT_ALIAS_NICKNAME,
            case
                when rtrim(ltrim(street_address_1)) = '' then null
                else street_address_1
            end                                AS PATIENT_STREET_ADDRESS_1,
            case
                when rtrim(ltrim(street_address_2)) = '' then null
                else street_address_2
            end                                AS PATIENT_STREET_ADDRESS_2,
            case
                when rtrim(ltrim(city)) = '' then null
                else city end AS PATIENT_CITY,
            state                              AS PATIENT_STATE,
            case
                when rtrim(ltrim(state_code)) = '' then null
                else state_code
            end                                AS PATIENT_STATE_CODE,
            case
                when rtrim(ltrim(zip)) = '' then null
                else zip
            end                                AS PATIENT_ZIP,
            case
                when rtrim(ltrim(county_code)) = '' then null
                else county_code
            end                                AS PATIENT_COUNTY_CODE,
            county                             AS PATIENT_COUNTY,
            case
                when rtrim(ltrim(country)) = '' then null
                else country
            end                                AS PATIENT_COUNTRY,
            case
                when rtrim(ltrim(within_city_limits)) = '' then null
                else within_city_limits
            end                                AS PATIENT_WITHIN_CITY_LIMITS,
            case
                when rtrim(ltrim(phone_home)) = '' then null
                else phone_home
            end                                AS PATIENT_PHONE_HOME,
            case
                when rtrim(ltrim(phone_ext_home)) = '' then null
                else phone_ext_home
            end                                AS PATIENT_PHONE_EXT_HOME,
            case
                when rtrim(ltrim(phone_work)) = '' then null
                else phone_work
            end                                AS PATIENT_PHONE_WORK,
            case
                when rtrim(ltrim(phone_ext_work)) = '' then null
                else phone_ext_work
            end                                AS PATIENT_PHONE_EXT_WORK,
            phone_cell                         AS PATIENT_PHONE_CELL,
            email                              AS PATIENT_EMAIL,
            dob                                AS PATIENT_DOB,
            age_reported                       AS PATIENT_AGE_REPORTED,
            age_reported_unit                  AS PATIENT_AGE_REPORTED_UNIT,
            birth_sex                          AS PATIENT_BIRTH_SEX,
            current_sex                         AS PATIENT_CURRENT_SEX,
            deceased_indicator                  AS PATIENT_DECEASED_INDICATOR,
            deceased_date                       AS PATIENT_DECEASED_DATE,
            marital_status                      AS PATIENT_MARITAL_STATUS,
            case
                when rtrim(ltrim(ssn)) = '' then null
                else ssn
            end                                AS PATIENT_SSN,
            ethnicity                          AS PATIENT_ETHNICITY,
            race_calculated                    AS PATIENT_RACE_CALCULATED,
            race_calc_details                  AS PATIENT_RACE_CALC_DETAILS,
            race_amer_ind_1                    AS PATIENT_RACE_AMER_IND_1,
            race_amer_ind_2                    AS PATIENT_RACE_AMER_IND_2,
            race_amer_ind_3                    AS PATIENT_RACE_AMER_IND_3,
            race_amer_ind_gt3_ind              AS PATIENT_RACE_AMER_IND_GT3_IND,
            race_amer_ind_all                  AS PATIENT_RACE_AMER_IND_ALL,
            race_asian_1        AS PATIENT_RACE_ASIAN_1,
            race_asian_2        AS PATIENT_RACE_ASIAN_2,
            race_asian_3        AS PATIENT_RACE_ASIAN_3,
            race_asian_gt3_ind  AS PATIENT_RACE_ASIAN_GT3_IND,
            race_asian_all      AS PATIENT_RACE_ASIAN_ALL,
            race_black_1        AS PATIENT_RACE_BLACK_1,
            race_black_2        AS PATIENT_RACE_BLACK_2,
            race_black_3        AS PATIENT_RACE_BLACK_3,
            race_black_gt3_ind  AS PATIENT_RACE_BLACK_GT3_IND,
            race_black_all      AS PATIENT_RACE_BLACK_ALL,
            race_nat_hi_1       AS PATIENT_RACE_NAT_HI_1,
            race_nat_hi_2       AS PATIENT_RACE_NAT_HI_2,
            race_nat_hi_3       AS PATIENT_RACE_NAT_HI_3,
            race_nat_hi_gt3_ind AS PATIENT_RACE_NAT_HI_GT3_IND,
            race_nat_hi_all     AS PATIENT_RACE_NAT_HI_ALL,
            race_white_1        AS PATIENT_RACE_WHITE_1,
            race_white_2        AS PATIENT_RACE_WHITE_2,
            race_white_3        AS PATIENT_RACE_WHITE_3,
            race_white_gt3_ind  AS PATIENT_RACE_WHITE_GT3_IND,
            race_white_all      AS PATIENT_RACE_WHITE_ALL,
            nrt.patient_number       AS PATIENT_NUMBER,
            nrt.patient_number_auth  AS PATIENT_NUMBER_AUTH,
            entry_method             AS PATIENT_ENTRY_METHOD,
            speaks_english           AS PATIENT_SPEAKS_ENGLISH,
            unk_ethnic_rsn           AS PATIENT_UNK_ETHNIC_RSN,
            curr_sex_unk_rsn         AS PATIENT_CURR_SEX_UNK_RSN,
            preferred_gender         AS PATIENT_PREFERRED_GENDER,
            addl_gender_info         AS PATIENT_ADDL_GENDER_INFO,
            case
                when rtrim(ltrim(census_tract)) = '' then null
                else census_tract
            end                      AS PATIENT_CENSUS_TRACT,
            race_all                 AS PATIENT_RACE_ALL,
            birth_country            AS PATIENT_BIRTH_COUNTRY,
            primary_occupation       AS PATIENT_PRIMARY_OCCUPATION,
            primary_language         AS PATIENT_PRIMARY_LANGUAGE,
            add_user_name            AS PATIENT_ADDED_BY,
            add_time                 AS PATIENT_ADD_TIME,
            last_chg_user_name       AS PATIENT_LAST_UPDATED_BY,
            last_chg_time            AS PATIENT_LAST_CHANGE_TIME
        from dbo.nrt_patient nrt with (nolock)
                left join dbo.d_patient p with (nolock) on p.patient_uid = nrt.patient_uid
        where
            nrt.patient_uid in (SELECT value FROM STRING_SPLIT(@id_list, ','))
        )
        select
            PATIENT_UID,
            PATIENT_KEY,
            PATIENT_MPR_UID,
            PATIENT_RECORD_STATUS,
            PATIENT_LOCAL_ID,
            substring([PATIENT_GENERAL_COMMENTS] ,1,2000) as PATIENT_GENERAL_COMMENTS,
            PATIENT_FIRST_NAME,
            PATIENT_MIDDLE_NAME,
            PATIENT_LAST_NAME,
            PATIENT_NAME_SUFFIX,
            PATIENT_ALIAS_NICKNAME,
            substring([PATIENT_STREET_ADDRESS_1],1,50) as PATIENT_STREET_ADDRESS_1,
            substring([PATIENT_STREET_ADDRESS_2],1,50) as PATIENT_STREET_ADDRESS_2,
            substring([PATIENT_CITY] ,1,50) as PATIENT_CITY,
            PATIENT_STATE,
            PATIENT_STATE_CODE,
            PATIENT_ZIP,
            PATIENT_COUNTY_CODE,
            substring([PATIENT_COUNTY] ,1,50) as PATIENT_COUNTY,
            PATIENT_COUNTRY,
            PATIENT_WITHIN_CITY_LIMITS,
            PATIENT_PHONE_HOME,
            PATIENT_PHONE_EXT_HOME,
            PATIENT_PHONE_WORK,
            PATIENT_PHONE_EXT_WORK,
            PATIENT_PHONE_CELL,
            PATIENT_EMAIL,
            PATIENT_DOB,
            PATIENT_AGE_REPORTED,
            substring([PATIENT_AGE_REPORTED_UNIT] ,1,20)    as PATIENT_AGE_REPORTED_UNIT,
            substring([PATIENT_BIRTH_SEX] ,1,50)            as PATIENT_BIRTH_SEX,
            substring([PATIENT_CURRENT_SEX] ,1,50)          as PATIENT_CURRENT_SEX,
            substring([PATIENT_DECEASED_INDICATOR] ,1,50)   as PATIENT_DECEASED_INDICATOR,
            PATIENT_DECEASED_DATE,
            substring([PATIENT_MARITAL_STATUS] ,1,50)   as PATIENT_MARITAL_STATUS,
            substring([PATIENT_SSN] ,1,50)              as PATIENT_SSN,
            substring([PATIENT_ETHNICITY] ,1,50)        as PATIENT_ETHNICITY,
            substring([PATIENT_RACE_CALCULATED] ,1,50)  as PATIENT_RACE_CALCULATED,
            PATIENT_RACE_CALC_DETAILS,
            PATIENT_RACE_AMER_IND_1,
            PATIENT_RACE_AMER_IND_2,
            PATIENT_RACE_AMER_IND_3,
            PATIENT_RACE_AMER_IND_GT3_IND,
            PATIENT_RACE_AMER_IND_ALL,
            PATIENT_RACE_ASIAN_1,
            PATIENT_RACE_ASIAN_2,
            PATIENT_RACE_ASIAN_3,
            PATIENT_RACE_ASIAN_GT3_IND,
            PATIENT_RACE_ASIAN_ALL,
            PATIENT_RACE_BLACK_1,
            PATIENT_RACE_BLACK_2,
            PATIENT_RACE_BLACK_3,
            PATIENT_RACE_BLACK_GT3_IND,
            PATIENT_RACE_BLACK_ALL,
            PATIENT_RACE_NAT_HI_1,
            PATIENT_RACE_NAT_HI_2,
            PATIENT_RACE_NAT_HI_3,
            PATIENT_RACE_NAT_HI_GT3_IND,
            PATIENT_RACE_NAT_HI_ALL,
            PATIENT_RACE_WHITE_1,
            PATIENT_RACE_WHITE_2,
            PATIENT_RACE_WHITE_3,
            PATIENT_RACE_WHITE_GT3_IND,
            PATIENT_RACE_WHITE_ALL,
            substring([PATIENT_NUMBER] ,1,50) as PATIENT_NUMBER,
            PATIENT_NUMBER_AUTH,
            PATIENT_ENTRY_METHOD,
            PATIENT_SPEAKS_ENGLISH,
            PATIENT_UNK_ETHNIC_RSN,
            PATIENT_CURR_SEX_UNK_RSN,
            PATIENT_PREFERRED_GENDER,
            PATIENT_ADDL_GENDER_INFO,
            PATIENT_CENSUS_TRACT,
            PATIENT_RACE_ALL,
            substring([PATIENT_BIRTH_COUNTRY] ,1,50)        as PATIENT_BIRTH_COUNTRY,
            substring([PATIENT_PRIMARY_OCCUPATION] ,1,50)   as PATIENT_PRIMARY_OCCUPATION,
            substring([PATIENT_PRIMARY_LANGUAGE] ,1,50) as PATIENT_PRIMARY_LANGUAGE,
            PATIENT_ADDED_BY,
            PATIENT_ADD_TIME,
            PATIENT_LAST_UPDATED_BY,
            PATIENT_LAST_CHANGE_TIME
        into #temp_patient_table
        from src;

        declare @backfill_list nvarchar(max);  
        SET @backfill_list = 
		( 
			SELECT string_agg(t.value, ',')
			FROM (SELECT distinct TRIM(value) AS value FROM STRING_SPLIT(@id_list, ',')) t
                left join #temp_patient_table tmp
                on tmp.patient_uid = t.value	
                WHERE tmp.patient_uid is null	
		);

        IF @backfill_list IS NOT NULL
        BEGIN
            SELECT
                0 AS public_health_case_uid,
                CAST(NULL AS BIGINT) AS patient_uid,
                CAST(NULL AS BIGINT) AS observation_uid,
                'Error' AS datamart,
                CAST(NULL AS VARCHAR(50))  AS condition_cd,
                'Missing NRT Record: sp_nrt_patient_postprocessing' AS stored_procedure,
                CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
                WHERE 1=1;
            RETURN;
        END

        /* Logging */
        set @rowcount=@@rowcount
        INSERT INTO [dbo].[job_flow_log] (
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


        /* D_Patient Update Operation */
        BEGIN TRANSACTION;

        SET @proc_step_name='Update dbo.nrt_patient_key';
        SET @proc_step_no = 2;

        update k
        SET
          k.updated_dttm = GETDATE()
        FROM dbo.nrt_patient_key k
          INNER JOIN #temp_patient_table d
            ON K.d_patient_key = d.patient_KEY;

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



     -- Check for updates in the patient table that are valid for downstream datamarts
     select
          tpt.*,
          -- common case for multiple datamarts
          case
               when tpt.PATIENT_FIRST_NAME <> p.PATIENT_FIRST_NAME or
               tpt.PATIENT_LAST_NAME <> p.PATIENT_LAST_NAME or
               tpt.PATIENT_STREET_ADDRESS_1 <> p.PATIENT_STREET_ADDRESS_1 or
               tpt.PATIENT_STREET_ADDRESS_2 <> p.PATIENT_STREET_ADDRESS_2 or
               tpt.PATIENT_CITY <> p.PATIENT_CITY or
               tpt.PATIENT_STATE <> p.PATIENT_STATE or
               tpt.PATIENT_ZIP <> p.PATIENT_ZIP or
               tpt.PATIENT_DOB <> p.PATIENT_DOB or
               tpt.PATIENT_AGE_REPORTED <> p.PATIENT_AGE_REPORTED or
               tpt.PATIENT_AGE_REPORTED_UNIT <> p.PATIENT_AGE_REPORTED_UNIT or
               tpt.PATIENT_CURRENT_SEX <> p.PATIENT_CURRENT_SEX
               then 1
               else 0
          end as datamart_update,
          -- additional cases for case_lab datamart
          case
               when
               tpt.PATIENT_MIDDLE_NAME <> p.PATIENT_MIDDLE_NAME or
               tpt.PATIENT_COUNTY <> p.PATIENT_COUNTY or
               tpt.PATIENT_PHONE_HOME <> p.PATIENT_PHONE_HOME or
               tpt.PATIENT_PHONE_EXT_HOME <> p.PATIENT_PHONE_EXT_HOME or
               tpt.PATIENT_RACE_CALCULATED <> p.PATIENT_RACE_CALCULATED
               then 1
               else 0
          end as case_lab_datamart_update,
          -- additional cases for bmird_strep_pneumo_datamart datamart
          case
               when
               tpt.PATIENT_COUNTY <> p.PATIENT_COUNTY or
               tpt.PATIENT_ETHNICITY <> p.PATIENT_ETHNICITY or
               tpt.PATIENT_RACE_CALCULATED <> p.PATIENT_RACE_CALCULATED or
               tpt.PATIENT_RACE_CALC_DETAILS <> p.PATIENT_RACE_CALC_DETAILS
               then 1
               else 0
          end as bmird_strep_pneumo_datamart_update,
          -- additional cases for hep100 datamart
          case
               when
               tpt.PATIENT_MIDDLE_NAME <> p.PATIENT_MIDDLE_NAME or
               tpt.PATIENT_COUNTY <> p.PATIENT_COUNTY or
               tpt.PATIENT_ENTRY_METHOD <> p.PATIENT_ENTRY_METHOD or
               tpt.PATIENT_RACE_CALC_DETAILS <> p.PATIENT_RACE_CALC_DETAILS
               then 1
               else 0
          end as hep100_datamart_update,
          -- additional cases for morbidity_report_datamart
          case
               when
               tpt.PATIENT_MIDDLE_NAME <> p.PATIENT_MIDDLE_NAME or
               tpt.PATIENT_COUNTY <> p.PATIENT_COUNTY or
               tpt.PATIENT_COUNTRY <> p.PATIENT_COUNTRY or
               tpt.PATIENT_PHONE_HOME <> p.PATIENT_PHONE_HOME or
               tpt.PATIENT_PHONE_EXT_HOME <> p.PATIENT_PHONE_EXT_HOME or
               tpt.PATIENT_PHONE_WORK <> p.PATIENT_PHONE_WORK or
               tpt.PATIENT_PHONE_EXT_WORK <> p.PATIENT_PHONE_EXT_WORK or
               tpt.PATIENT_RACE_CALCULATED <> p.PATIENT_RACE_CALCULATED or
               tpt.PATIENT_RACE_CALC_DETAILS <> p.PATIENT_RACE_CALC_DETAILS or
               tpt.PATIENT_ETHNICITY <> p.PATIENT_ETHNICITY or
               tpt.PATIENT_GENERAL_COMMENTS <> p.PATIENT_GENERAL_COMMENTS or
               tpt.PATIENT_DECEASED_DATE <> p.PATIENT_DECEASED_DATE or
               tpt.PATIENT_DECEASED_INDICATOR <> p.PATIENT_DECEASED_INDICATOR or
               tpt.PATIENT_MARITAL_STATUS <> p.PATIENT_MARITAL_STATUS or
               tpt.PATIENT_SSN <> p.PATIENT_SSN or
               tpt.PATIENT_NAME_SUFFIX <> p.PATIENT_NAME_SUFFIX 
               then 1
               else 0
          end as morbidity_report_datamart_update,
          -- additional cases for std_hiv_datamart_update
          case
               when
               tpt.PATIENT_MIDDLE_NAME <> p.PATIENT_MIDDLE_NAME or
               tpt.PATIENT_COUNTY <> p.PATIENT_COUNTY or
               tpt.PATIENT_COUNTRY <> p.PATIENT_COUNTRY or
               tpt.PATIENT_PHONE_HOME <> p.PATIENT_PHONE_HOME or
               tpt.PATIENT_PHONE_EXT_HOME <> p.PATIENT_PHONE_EXT_HOME or
               tpt.PATIENT_PHONE_WORK <> p.PATIENT_PHONE_WORK or
               tpt.PATIENT_PHONE_EXT_WORK <> p.PATIENT_PHONE_EXT_WORK or
               tpt.PATIENT_RACE_CALCULATED <> p.PATIENT_RACE_CALCULATED or
               tpt.PATIENT_ETHNICITY <> p.PATIENT_ETHNICITY or
               tpt.PATIENT_DECEASED_DATE <> p.PATIENT_DECEASED_DATE or
               tpt.PATIENT_DECEASED_INDICATOR <> p.PATIENT_DECEASED_INDICATOR or
               tpt.PATIENT_MARITAL_STATUS <> p.PATIENT_MARITAL_STATUS or
               tpt.PATIENT_ADDL_GENDER_INFO <> p.PATIENT_ADDL_GENDER_INFO or
               tpt.PATIENT_ALIAS_NICKNAME <> p.PATIENT_ALIAS_NICKNAME or
               tpt.PATIENT_BIRTH_COUNTRY <> p.PATIENT_BIRTH_COUNTRY or
               tpt.PATIENT_BIRTH_SEX <> p.PATIENT_BIRTH_SEX or
               tpt.PATIENT_CENSUS_TRACT <> p.PATIENT_CENSUS_TRACT or
               tpt.PATIENT_CURR_SEX_UNK_RSN <> p.PATIENT_CURR_SEX_UNK_RSN or
               tpt.PATIENT_EMAIL <> p.PATIENT_EMAIL or
               tpt.PATIENT_PREFERRED_GENDER <> p.PATIENT_PREFERRED_GENDER or
               tpt.PATIENT_UNK_ETHNIC_RSN <> p.PATIENT_UNK_ETHNIC_RSN
               then 1
               else 0
          end as std_hiv_datamart_update,
          -- additional cases for var_datamart
          case
               when
               tpt.PATIENT_MIDDLE_NAME <> p.PATIENT_MIDDLE_NAME or
               tpt.PATIENT_COUNTY <> p.PATIENT_COUNTY or
               tpt.PATIENT_COUNTRY <> p.PATIENT_COUNTRY or
               tpt.PATIENT_PHONE_HOME <> p.PATIENT_PHONE_HOME or
               tpt.PATIENT_PHONE_EXT_HOME <> p.PATIENT_PHONE_EXT_HOME or
               tpt.PATIENT_PHONE_WORK <> p.PATIENT_PHONE_WORK or
               tpt.PATIENT_PHONE_EXT_WORK <> p.PATIENT_PHONE_EXT_WORK or
               tpt.PATIENT_RACE_CALCULATED <> p.PATIENT_RACE_CALCULATED or
               tpt.PATIENT_RACE_CALC_DETAILS <> p.PATIENT_RACE_CALC_DETAILS or
               tpt.PATIENT_ETHNICITY <> p.PATIENT_ETHNICITY or
               tpt.PATIENT_GENERAL_COMMENTS <> p.PATIENT_GENERAL_COMMENTS or
               tpt.PATIENT_DECEASED_DATE <> p.PATIENT_DECEASED_DATE or
               tpt.PATIENT_DECEASED_INDICATOR <> p.PATIENT_DECEASED_INDICATOR or
               tpt.PATIENT_MARITAL_STATUS <> p.PATIENT_MARITAL_STATUS or
               tpt.PATIENT_SSN <> p.PATIENT_SSN or
               tpt.PATIENT_NAME_SUFFIX <> p.PATIENT_NAME_SUFFIX or
               tpt.PATIENT_WITHIN_CITY_LIMITS <> p.PATIENT_WITHIN_CITY_LIMITS
               then 1
               else 0
          end as var_datamart_update,
          -- additional cases for tb_datamart
          case
               when
               tpt.PATIENT_BIRTH_COUNTRY <> p.PATIENT_BIRTH_COUNTRY or
               tpt.PATIENT_BIRTH_SEX <> p.PATIENT_BIRTH_SEX or
               tpt.PATIENT_RACE_NAT_HI_1 <> p.PATIENT_RACE_NAT_HI_1 or
               tpt.PATIENT_RACE_NAT_HI_2 <> p.PATIENT_RACE_NAT_HI_2 or
               tpt.PATIENT_RACE_NAT_HI_3 <> p.PATIENT_RACE_NAT_HI_3 or
               tpt.PATIENT_RACE_ASIAN_1 <> p.PATIENT_RACE_ASIAN_1 or
               tpt.PATIENT_RACE_ASIAN_2 <> p.PATIENT_RACE_ASIAN_2 or
               tpt.PATIENT_RACE_ASIAN_3 <> p.PATIENT_RACE_ASIAN_3 or
               tpt.PATIENT_RACE_ASIAN_ALL <> p.PATIENT_RACE_ASIAN_ALL or
               tpt.PATIENT_RACE_ASIAN_GT3_IND <> p.PATIENT_RACE_ASIAN_GT3_IND or
               tpt.PATIENT_RACE_NAT_HI_GT3_IND <> p.PATIENT_RACE_NAT_HI_GT3_IND or
               tpt.PATIENT_RACE_NAT_HI_ALL <> p.PATIENT_RACE_NAT_HI_ALL
               then 1
               else 0
          end as tb_datamart_update
     into #PATIENT_UPDATE_LIST
     from dbo.D_PATIENT p with (nolock)
          inner join #temp_patient_table tpt on tpt.patient_key = p.patient_key
     ;

     if @debug = 'true'
     select * from #PATIENT_UPDATE_LIST;

     SET @proc_step_name='Update D_PATIENT Dimension';
     SET @proc_step_no = 3;

        update dbo.d_patient
        set	[PATIENT_KEY]	=	tpt.[PATIENT_KEY]	,
               [PATIENT_MPR_UID]	=	tpt.[PATIENT_MPR_UID]	,
               [PATIENT_RECORD_STATUS]	=	tpt.[PATIENT_RECORD_STATUS]	,
               [PATIENT_LOCAL_ID]	=	tpt.[PATIENT_LOCAL_ID]	,
               [PATIENT_GENERAL_COMMENTS]	=	 tpt.[PATIENT_GENERAL_COMMENTS]	,
               [PATIENT_FIRST_NAME]	=	tpt.[PATIENT_FIRST_NAME]	,
               [PATIENT_MIDDLE_NAME]	=	tpt.[PATIENT_MIDDLE_NAME]	,
               [PATIENT_LAST_NAME]	=	tpt.[PATIENT_LAST_NAME]	,
               [PATIENT_NAME_SUFFIX]	=	tpt.[PATIENT_NAME_SUFFIX]	,
               [PATIENT_ALIAS_NICKNAME]	=	tpt.[PATIENT_ALIAS_NICKNAME]	,
               [PATIENT_STREET_ADDRESS_1]	=	tpt.[PATIENT_STREET_ADDRESS_1]	,
               [PATIENT_STREET_ADDRESS_2]	=	tpt.[PATIENT_STREET_ADDRESS_2]	,
               [PATIENT_CITY]	=	 tpt.[PATIENT_CITY]	,
               [PATIENT_STATE]	=	tpt.[PATIENT_STATE]	,
               [PATIENT_STATE_CODE]	=	tpt.[PATIENT_STATE_CODE]	,
               [PATIENT_ZIP]	=	tpt.[PATIENT_ZIP]	,
               [PATIENT_COUNTY]	=		tpt.[PATIENT_COUNTY],
               [PATIENT_COUNTY_CODE]	=	tpt.[PATIENT_COUNTY_CODE]	,
               [PATIENT_COUNTRY]	=	tpt.[PATIENT_COUNTRY]	,
               [PATIENT_WITHIN_CITY_LIMITS]	=	tpt.[PATIENT_WITHIN_CITY_LIMITS]	,
               [PATIENT_PHONE_HOME]	=	tpt.[PATIENT_PHONE_HOME]	,
               [PATIENT_PHONE_EXT_HOME]	=	tpt.[PATIENT_PHONE_EXT_HOME]	,
               [PATIENT_PHONE_WORK]	=	tpt.[PATIENT_PHONE_WORK]	,
               [PATIENT_PHONE_EXT_WORK]	=	tpt.[PATIENT_PHONE_EXT_WORK]	,
               [PATIENT_PHONE_CELL]	=	tpt.[PATIENT_PHONE_CELL]	,
               [PATIENT_EMAIL]	=	tpt.[PATIENT_EMAIL]	,
               [PATIENT_DOB]	=	tpt.[PATIENT_DOB]	,
               [PATIENT_AGE_REPORTED]	=		tpt.[PATIENT_AGE_REPORTED],
               [PATIENT_AGE_REPORTED_UNIT]	=	 tpt.[PATIENT_AGE_REPORTED_UNIT],
               [PATIENT_BIRTH_SEX]	=	 tpt.[PATIENT_BIRTH_SEX],
               [PATIENT_CURRENT_SEX]	=		tpt.[PATIENT_CURRENT_SEX],
               [PATIENT_DECEASED_INDICATOR]	=		tpt.[PATIENT_DECEASED_INDICATOR],
               [PATIENT_DECEASED_DATE]	=	tpt.[PATIENT_DECEASED_DATE]	,
               [PATIENT_MARITAL_STATUS]	=		tpt.[PATIENT_MARITAL_STATUS],
               [PATIENT_SSN]	=	tpt.[PATIENT_SSN],
               [PATIENT_ETHNICITY]	=		tpt.[PATIENT_ETHNICITY],
               [PATIENT_RACE_CALCULATED]	=		tpt.[PATIENT_RACE_CALCULATED],
               [PATIENT_RACE_CALC_DETAILS]	=	tpt.[PATIENT_RACE_CALC_DETAILS]	,
               [PATIENT_RACE_AMER_IND_1]	=	tpt.[PATIENT_RACE_AMER_IND_1]	,
               [PATIENT_RACE_AMER_IND_2]	=	tpt.[PATIENT_RACE_AMER_IND_2]	,
               [PATIENT_RACE_AMER_IND_3]	=	tpt.[PATIENT_RACE_AMER_IND_3]	,
               [PATIENT_RACE_AMER_IND_GT3_IND]	=	tpt.[PATIENT_RACE_AMER_IND_GT3_IND]	,
               [PATIENT_RACE_AMER_IND_ALL]	=	tpt.[PATIENT_RACE_AMER_IND_ALL]	,
               [PATIENT_RACE_ASIAN_1]	=	tpt.[PATIENT_RACE_ASIAN_1]	,
               [PATIENT_RACE_ASIAN_2]	=	tpt.[PATIENT_RACE_ASIAN_2]	,
               [PATIENT_RACE_ASIAN_3]	=	tpt.[PATIENT_RACE_ASIAN_3]	,
               [PATIENT_RACE_ASIAN_GT3_IND]	=	tpt.[PATIENT_RACE_ASIAN_GT3_IND]	,
               [PATIENT_RACE_ASIAN_ALL]	=	tpt.[PATIENT_RACE_ASIAN_ALL]	,
               [PATIENT_RACE_BLACK_1]	=	tpt.[PATIENT_RACE_BLACK_1]	,
               [PATIENT_RACE_BLACK_2]	=	tpt.[PATIENT_RACE_BLACK_2]	,
               [PATIENT_RACE_BLACK_3]	=	tpt.[PATIENT_RACE_BLACK_3]	,
               [PATIENT_RACE_BLACK_GT3_IND]	=	tpt.[PATIENT_RACE_BLACK_GT3_IND]	,
               [PATIENT_RACE_BLACK_ALL]	=	tpt.[PATIENT_RACE_BLACK_ALL]	,
               [PATIENT_RACE_NAT_HI_1]	=	tpt.[PATIENT_RACE_NAT_HI_1]	,
               [PATIENT_RACE_NAT_HI_2]	=	tpt.[PATIENT_RACE_NAT_HI_2]	,
               [PATIENT_RACE_NAT_HI_3]	=	tpt.[PATIENT_RACE_NAT_HI_3]	,
               [PATIENT_RACE_NAT_HI_GT3_IND]	=	tpt.[PATIENT_RACE_NAT_HI_GT3_IND]	,
               [PATIENT_RACE_NAT_HI_ALL]	=	tpt.[PATIENT_RACE_NAT_HI_ALL]	,
               [PATIENT_RACE_WHITE_1]	=	tpt.[PATIENT_RACE_WHITE_1]	,
               [PATIENT_RACE_WHITE_2]	=	tpt.[PATIENT_RACE_WHITE_2]	,
               [PATIENT_RACE_WHITE_3]	=	tpt.[PATIENT_RACE_WHITE_3]	,
               [PATIENT_RACE_WHITE_GT3_IND]	=	tpt.[PATIENT_RACE_WHITE_GT3_IND]	,
               [PATIENT_RACE_WHITE_ALL]	=	tpt.[PATIENT_RACE_WHITE_ALL]	,
               [PATIENT_NUMBER]	=		tpt.[PATIENT_NUMBER],
               [PATIENT_NUMBER_AUTH]	=	tpt.[PATIENT_NUMBER_AUTH]	,
               [PATIENT_ENTRY_METHOD]	=	tpt.[PATIENT_ENTRY_METHOD]	,
               [PATIENT_LAST_CHANGE_TIME]	=	tpt.[PATIENT_LAST_CHANGE_TIME]	,
               [PATIENT_ADD_TIME]	=	tpt.[PATIENT_ADD_TIME]	,
               [PATIENT_ADDED_BY]	=	tpt.[PATIENT_ADDED_BY]	,
               [PATIENT_LAST_UPDATED_BY]	=	tpt.[PATIENT_LAST_UPDATED_BY]	,
               [PATIENT_SPEAKS_ENGLISH]	=	tpt.[PATIENT_SPEAKS_ENGLISH]	,
               [PATIENT_UNK_ETHNIC_RSN]	=	tpt.[PATIENT_UNK_ETHNIC_RSN]	,
               [PATIENT_CURR_SEX_UNK_RSN]	=	tpt.[PATIENT_CURR_SEX_UNK_RSN]	,
               [PATIENT_PREFERRED_GENDER]	=	tpt.[PATIENT_PREFERRED_GENDER]	,
               [PATIENT_ADDL_GENDER_INFO]	=	tpt.[PATIENT_ADDL_GENDER_INFO]	,
               [PATIENT_CENSUS_TRACT]	=	tpt.[PATIENT_CENSUS_TRACT]	,
               [PATIENT_RACE_ALL]	=	tpt.[PATIENT_RACE_ALL]	,
               [PATIENT_BIRTH_COUNTRY]	=	 tpt.[PATIENT_BIRTH_COUNTRY],
               [PATIENT_PRIMARY_OCCUPATION]	=		tpt.[PATIENT_PRIMARY_OCCUPATION],
               [PATIENT_PRIMARY_LANGUAGE]	=		tpt.[PATIENT_PRIMARY_LANGUAGE]
        from #temp_patient_table tpt
                 inner join dbo.d_patient p with (nolock) on tpt.patient_uid = p.patient_uid
            and tpt.patient_key = p.patient_key
            and p.patient_key is not null;

        /* Logging */
        set @rowcount=@@rowcount
        INSERT INTO [dbo].[job_flow_log] (
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

        SET @proc_step_name='Insert into D_PATIENT Dimension';
        SET @proc_step_no = 4;

        /* D_Patient Insert Operation */
        -- declare @max_key bigint;
        -- select  @max_key = max(patient_key) from dbo.d_patient;

        insert into dbo.nrt_patient_key(patient_uid)
        select patient_uid from #temp_patient_table where patient_key is null order by patient_uid;

        insert into dbo.d_patient
        ([PATIENT_KEY]
        ,[PATIENT_MPR_UID]
        ,[PATIENT_RECORD_STATUS]
        ,[PATIENT_LOCAL_ID]
        ,[PATIENT_GENERAL_COMMENTS]
        ,[PATIENT_FIRST_NAME]
        ,[PATIENT_MIDDLE_NAME]
        ,[PATIENT_LAST_NAME]
        ,[PATIENT_NAME_SUFFIX]
        ,[PATIENT_ALIAS_NICKNAME]
        ,[PATIENT_STREET_ADDRESS_1]
        ,[PATIENT_STREET_ADDRESS_2]
        ,[PATIENT_CITY]
        ,[PATIENT_STATE]
        ,[PATIENT_STATE_CODE]
        ,[PATIENT_ZIP]
        ,[PATIENT_COUNTY]
        ,[PATIENT_COUNTY_CODE]
        ,[PATIENT_COUNTRY]
        ,[PATIENT_WITHIN_CITY_LIMITS]
        ,[PATIENT_PHONE_HOME]
        ,[PATIENT_PHONE_EXT_HOME]
        ,[PATIENT_PHONE_WORK]
        ,[PATIENT_PHONE_EXT_WORK]
        ,[PATIENT_PHONE_CELL]
        ,[PATIENT_EMAIL]
        ,[PATIENT_DOB]
        ,[PATIENT_AGE_REPORTED]
        ,[PATIENT_AGE_REPORTED_UNIT]
        ,[PATIENT_BIRTH_SEX]
        ,[PATIENT_CURRENT_SEX]
        ,[PATIENT_DECEASED_INDICATOR]
        ,[PATIENT_DECEASED_DATE]
        ,[PATIENT_MARITAL_STATUS]
        ,[PATIENT_SSN]
        ,[PATIENT_ETHNICITY]
        ,[PATIENT_RACE_CALCULATED]
        ,[PATIENT_RACE_CALC_DETAILS]
        ,[PATIENT_RACE_AMER_IND_1]
        ,[PATIENT_RACE_AMER_IND_2]
        ,[PATIENT_RACE_AMER_IND_3]
        ,[PATIENT_RACE_AMER_IND_GT3_IND]
        ,[PATIENT_RACE_AMER_IND_ALL]
        ,[PATIENT_RACE_ASIAN_1]
        ,[PATIENT_RACE_ASIAN_2]
        ,[PATIENT_RACE_ASIAN_3]
        ,[PATIENT_RACE_ASIAN_GT3_IND]
        ,[PATIENT_RACE_ASIAN_ALL]
        ,[PATIENT_RACE_BLACK_1]
        ,[PATIENT_RACE_BLACK_2]
        ,[PATIENT_RACE_BLACK_3]
        ,[PATIENT_RACE_BLACK_GT3_IND]
        ,[PATIENT_RACE_BLACK_ALL]
        ,[PATIENT_RACE_NAT_HI_1]
        ,[PATIENT_RACE_NAT_HI_2]
        ,[PATIENT_RACE_NAT_HI_3]
        ,[PATIENT_RACE_NAT_HI_GT3_IND]
        ,[PATIENT_RACE_NAT_HI_ALL]
        ,[PATIENT_RACE_WHITE_1]
        ,[PATIENT_RACE_WHITE_2]
        ,[PATIENT_RACE_WHITE_3]
        ,[PATIENT_RACE_WHITE_GT3_IND]
        ,[PATIENT_RACE_WHITE_ALL]
        ,[PATIENT_NUMBER]
        ,[PATIENT_NUMBER_AUTH]
        ,[PATIENT_ENTRY_METHOD]
        ,[PATIENT_LAST_CHANGE_TIME]
        ,[PATIENT_UID]
        ,[PATIENT_ADD_TIME]
        ,[PATIENT_ADDED_BY]
        ,[PATIENT_LAST_UPDATED_BY]
        ,[PATIENT_SPEAKS_ENGLISH]
        ,[PATIENT_UNK_ETHNIC_RSN]
        ,[PATIENT_CURR_SEX_UNK_RSN]
        ,[PATIENT_PREFERRED_GENDER]
        ,[PATIENT_ADDL_GENDER_INFO]
        ,[PATIENT_CENSUS_TRACT]
        ,[PATIENT_RACE_ALL]
        ,[PATIENT_BIRTH_COUNTRY]
        ,[PATIENT_PRIMARY_OCCUPATION]
        ,[PATIENT_PRIMARY_LANGUAGE] )
        SELECT  distinct k.[d_PATIENT_KEY] as PATIENT_KEY
                       ,tpt.[PATIENT_MPR_UID]
                       ,tpt.[PATIENT_RECORD_STATUS]
                       ,tpt.[PATIENT_LOCAL_ID]
                       ,tpt.[PATIENT_GENERAL_COMMENTS]
                       ,tpt.[PATIENT_FIRST_NAME]
                       ,tpt.[PATIENT_MIDDLE_NAME]
                       ,tpt.[PATIENT_LAST_NAME]
                       ,tpt.[PATIENT_NAME_SUFFIX]
                       ,tpt.[PATIENT_ALIAS_NICKNAME]
                       ,tpt.[PATIENT_STREET_ADDRESS_1]
                       ,tpt.[PATIENT_STREET_ADDRESS_2]
                       ,tpt.[PATIENT_CITY]
                       ,tpt.[PATIENT_STATE]
                       ,tpt.[PATIENT_STATE_CODE]
                       ,tpt.[PATIENT_ZIP]
                       ,tpt.[PATIENT_COUNTY]
                       ,tpt.[PATIENT_COUNTY_CODE]
                       ,tpt.[PATIENT_COUNTRY]
                       ,tpt.[PATIENT_WITHIN_CITY_LIMITS]
                       ,tpt.[PATIENT_PHONE_HOME]
                       ,tpt.[PATIENT_PHONE_EXT_HOME]
                       ,tpt.[PATIENT_PHONE_WORK]
                       ,tpt.[PATIENT_PHONE_EXT_WORK]
                       ,tpt.[PATIENT_PHONE_CELL]
                       ,tpt.[PATIENT_EMAIL]
                       ,tpt.[PATIENT_DOB]
                       ,tpt.[PATIENT_AGE_REPORTED]
                       ,tpt.[PATIENT_AGE_REPORTED_UNIT]
                       ,tpt.[PATIENT_BIRTH_SEX]
                       ,tpt.[PATIENT_CURRENT_SEX]
                       ,tpt.[PATIENT_DECEASED_INDICATOR]
                       ,tpt.[PATIENT_DECEASED_DATE]
                       ,tpt.[PATIENT_MARITAL_STATUS]
                       ,tpt.[PATIENT_SSN]
                       ,tpt.[PATIENT_ETHNICITY]
                       ,tpt.[PATIENT_RACE_CALCULATED]
                       ,tpt.[PATIENT_RACE_CALC_DETAILS]
                       ,tpt.[PATIENT_RACE_AMER_IND_1]
                       ,tpt.[PATIENT_RACE_AMER_IND_2]
                       ,tpt.[PATIENT_RACE_AMER_IND_3]
                       ,tpt.[PATIENT_RACE_AMER_IND_GT3_IND]
                       ,tpt.[PATIENT_RACE_AMER_IND_ALL]
                       ,tpt.[PATIENT_RACE_ASIAN_1]
                       ,tpt.[PATIENT_RACE_ASIAN_2]
                       ,tpt.[PATIENT_RACE_ASIAN_3]
                       ,tpt.[PATIENT_RACE_ASIAN_GT3_IND]
                       ,tpt.[PATIENT_RACE_ASIAN_ALL]
                       ,tpt.[PATIENT_RACE_BLACK_1]
                       ,tpt.[PATIENT_RACE_BLACK_2]
                       ,tpt.[PATIENT_RACE_BLACK_3]
                       ,tpt.[PATIENT_RACE_BLACK_GT3_IND]
                       ,tpt.[PATIENT_RACE_BLACK_ALL]
                       ,tpt.[PATIENT_RACE_NAT_HI_1]
                       ,tpt.[PATIENT_RACE_NAT_HI_2]
                       ,tpt.[PATIENT_RACE_NAT_HI_3]
                       ,tpt.[PATIENT_RACE_NAT_HI_GT3_IND]
                       ,tpt.[PATIENT_RACE_NAT_HI_ALL]
                       ,tpt.[PATIENT_RACE_WHITE_1]
                       ,tpt.[PATIENT_RACE_WHITE_2]
                       ,tpt.[PATIENT_RACE_WHITE_3]
                       ,tpt.[PATIENT_RACE_WHITE_GT3_IND]
                       ,tpt.[PATIENT_RACE_WHITE_ALL]
                       ,tpt.[PATIENT_NUMBER]
                       ,tpt.[PATIENT_NUMBER_AUTH]
                       ,tpt.[PATIENT_ENTRY_METHOD]
                       ,tpt.[PATIENT_LAST_CHANGE_TIME]
                       ,tpt.[PATIENT_UID]
                       ,tpt.[PATIENT_ADD_TIME]
                       ,tpt.[PATIENT_ADDED_BY]
                       ,tpt.[PATIENT_LAST_UPDATED_BY]
                       ,tpt.[PATIENT_SPEAKS_ENGLISH]
                       ,tpt.[PATIENT_UNK_ETHNIC_RSN]
                       ,tpt.[PATIENT_CURR_SEX_UNK_RSN]
                       ,tpt.[PATIENT_PREFERRED_GENDER]
                       ,tpt.[PATIENT_ADDL_GENDER_INFO]
                       ,tpt.[PATIENT_CENSUS_TRACT]
                       ,tpt.[PATIENT_RACE_ALL]
                       ,tpt.[PATIENT_BIRTH_COUNTRY]
                       ,tpt.[PATIENT_PRIMARY_OCCUPATION]
                       ,tpt.[PATIENT_PRIMARY_LANGUAGE]
        FROM #temp_patient_table tpt
                 join dbo.nrt_patient_key k with (nolock) on tpt.patient_uid = k.patient_uid
        where tpt.patient_key is null;

        /* Logging */
        set @rowcount=@@rowcount
        INSERT INTO [dbo].[job_flow_log] (
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

        COMMIT TRANSACTION;
        /** Datamart Update Operations **/
        SET @proc_step_name='GENERATE DYNAMIC DATAMART PATIENTS TABLE';
        SET @proc_step_no = 5;

        SET @sql = '
        SELECT
               pg.datamart_nm
               , ''tmp_DynDm_Patient_Data_'' + pg.datamart_nm + ''_' + CAST(@batch_id AS VARCHAR(200)) + ''' AS tbl_nm
               , STRING_AGG(CAST(dinv.case_uid AS NVARCHAR(MAX)), '','') AS phc_uid_list
        INTO dbo.' + @dimension_update_tbl_nm + '
        FROM (select i.INVESTIGATION_KEY, d.PATIENT_KEY
          from dbo.F_STD_PAGE_CASE i with (NOLOCK) inner join #temp_patient_table d on i.PATIENT_KEY = d.PATIENT_KEY
          union all
          select i.INVESTIGATION_KEY, d.PATIENT_KEY
          from dbo.F_PAGE_CASE i with (NOLOCK) inner join #temp_patient_table d on i.PATIENT_KEY = d.PATIENT_KEY) p
          INNER JOIN dbo.INVESTIGATION dinv with (NOLOCK)
               ON dinv.investigation_key = p.INVESTIGATION_KEY
          INNER JOIN dbo.INV_SUMM_DATAMART invsum
               ON invsum.INVESTIGATION_KEY = dinv.investigation_key
          INNER JOIN dbo.condition c with (NOLOCK)
               ON c.CONDITION_CD = invsum.DISEASE_CD
          INNER JOIN dbo.nrt_odse_NBS_page pg with (NOLOCK)
               ON c.DISEASE_GRP_CD = pg.form_cd AND pg.datamart_nm IS NOT NULL
          GROUP BY pg.datamart_nm;
';

          exec sp_executesql @sql;

          if @debug = 'true'
               BEGIN
                    select @sql;
                    DECLARE @sql_statement_DEBUG NVARCHAR(MAX) = 'SELECT * FROM dbo.' + @dimension_update_tbl_nm + ';';
                    exec sp_executesql @sql_statement_DEBUG;
               END;
          set @rowcount=@@rowcount
        INSERT INTO [dbo].[job_flow_log] (
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

        SET @proc_step_name='EXECUTE DYNAMIC DATAMART DIMENSION UPDATE';
        SET @proc_step_no = 6;

        exec @return_code = dbo.sp_dyn_dm_dimension_update 'D_PATIENT', @dimension_update_tbl_nm, @batch_id, @debug;


        if @return_code = -1
           RAISERROR('Error in dynamic datamart update', 16, 1);

        set @rowcount=@@rowcount
        INSERT INTO [dbo].[job_flow_log] (
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

          IF OBJECT_ID('dbo.' + @dimension_update_tbl_nm, 'U') IS NOT NULL
               BEGIN
                    SET @sql = 'drop table dbo.' + @dimension_update_tbl_nm;
                    exec sp_executesql @sql;
               END

        SET @proc_step_name='Check and perform update to valid patient attributes in downstream Datamarts';
        SET @proc_step_no = 7;
        -- Enter only if there are updates in the patient table that are valid for downstream datamarts
        IF EXISTS (
            select 1 from #PATIENT_UPDATE_LIST
            where datamart_update
                +case_lab_datamart_update
                +bmird_strep_pneumo_datamart_update
                +hep100_datamart_update
                +morbidity_report_datamart_update
                +std_hiv_datamart_update
                +var_datamart_update
                +tb_datamart_update >= 1
        )
        BEGIN

            INSERT INTO [dbo].[job_flow_log]
            (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count],[msg_description1])
            VALUES
            (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount,
                LEFT( (SELECT
                    patient_uid,
                    datamart_update
                    +case_lab_datamart_update
                    +bmird_strep_pneumo_datamart_update
                    +hep100_datamart_update
                    +morbidity_report_datamart_update
                    +std_hiv_datamart_update
                    +var_datamart_update
                    +tb_datamart_update as update_count
                    FROM #PATIENT_UPDATE_LIST
                    FOR JSON PATH
                ), 500)
            )
            ;
            exec sp_patient_dim_columns_update_to_datamart @batch_id, @debug;
        END


        SET @proc_step_name='SP_COMPLETE';
        SET @proc_step_no = 999;

        INSERT INTO [dbo].[job_flow_log] (
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
               ,LEFT(@id_list,500)
               );


        SELECT nri.public_health_case_uid                       AS public_health_case_uid,
               nrt.PATIENT_UID                                  AS patient_uid,
               null                                             AS observation_uid,
               CONCAT_WS(',',dtm.Datamart, ldf.datamart_name)   AS datamart,
               nri.cd                                           AS condition_cd,
               dtm.Stored_Procedure                             AS stored_procedure,
               nri.investigation_form_cd                        AS investigation_form_cd
        FROM #temp_patient_table nrt
            INNER JOIN dbo.nrt_investigation nri with (nolock) ON nrt.PATIENT_UID = nri.patient_id
            LEFT JOIN dbo.D_PATIENT pat with (nolock) ON pat.PATIENT_UID = nrt.PATIENT_UID
            INNER JOIN dbo.nrt_datamart_metadata dtm with (nolock) ON dtm.condition_cd = nri.cd AND dtm.Datamart = 'Covid_Case_Datamart'
            LEFT JOIN dbo.LDF_DATAMART_TABLE_REF ldf with (nolock) on ldf.condition_cd = nri.cd
        UNION
        SELECT
            vac.vaccination_uid                                 AS public_health_case_uid,
            vac.patient_uid                                     AS patient_uid,
            null                                                AS observation_uid,
            dtm.Datamart                                        AS datamart,
            dtm.condition_cd                                    AS condition_cd,
            dtm.Stored_Procedure                                AS stored_procedure,
            null                                                AS investigation_form_cd
        FROM #temp_patient_table nrt with (nolock)
            INNER JOIN dbo.nrt_vaccination vac with (nolock) on nrt.patient_uid = vac.patient_uid
            INNER JOIN dbo.nrt_datamart_metadata dtm with (nolock) ON dtm.Datamart = 'Covid_Vaccination_Datamart'
        WHERE vac.material_cd IN('207', '208', '213');


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
          (batch_id,[create_dttm],[update_dttm],[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count],[msg_description1],[Error_Description])
          VALUES
          (@batch_id,current_timestamp,current_timestamp,@dataflow_name,@package_name,'ERROR',@Proc_Step_no,@proc_step_name,0,LEFT(@id_list,500),@FullErrorMessage);

            SELECT
                0 AS public_health_case_uid,
                CAST(NULL AS BIGINT) AS patient_uid,
                CAST(NULL AS BIGINT) AS observation_uid,
                'Error' AS datamart,
                CAST(NULL AS VARCHAR(50))  AS condition_cd,
                @FullErrorMessage AS stored_procedure,
                CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
                WHERE 1=1;

          /*
               Cleanup process for the scenario in which
               one or more of the dynamic datamart operations fail
          */
          IF OBJECT_ID('dbo.' + @dimension_update_tbl_nm, 'U') IS NOT NULL
               BEGIN
                    SET @sql = 'drop table dbo.' + @dimension_update_tbl_nm;
                    exec sp_executesql @sql;
               END


    END CATCH

END;