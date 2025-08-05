IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_patient_delta_update]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_patient_delta_update]
END
GO 
CREATE PROCEDURE [dbo].[sp_patient_delta_update] @batch_id bigint, @debug bit = 'false'
AS
BEGIN

    declare @rowcount bigint;
    declare @proc_step_no float = 0;
    declare @proc_step_name varchar(200) = '';
    declare @create_dttm datetime2(7) = current_timestamp ;
    declare @update_dttm datetime2(7) = current_timestamp ;
    declare @dataflow_name varchar(200) = 'Patient POST-Processing';
    declare @package_name varchar(200) = 'sp_patient_delta_update';

    -- Building a mapping table for investigations and patients which can be used later 
    -- multiple times in the procedure
    select i.INVESTIGATION_KEY, d.* 
    into #INVESTIGATION_PATIENT_MAPPING
    from dbo.F_STD_PAGE_CASE i with (nolock)  inner join #PATIENT_UPDATE_LIST d on i.PATIENT_KEY = d.PATIENT_KEY 
    union all
    select i.INVESTIGATION_KEY, d.* 
    from dbo.F_PAGE_CASE i with (nolock)  inner join #PATIENT_UPDATE_LIST d on i.PATIENT_KEY = d.PATIENT_KEY 

    if @debug = 'true'
    select * from #INVESTIGATION_PATIENT_MAPPING;

    
    SET @proc_step_name=' Update Patient attributes in CASE_LAB_DATAMART';
    SET @proc_step_no = 5.1;

    -- we use the INVESTIGATION_KEY to update the patient attributes in the CASE_LAB_DATAMART
    -- since PATIENT_LOCAL_ID is the only identifier for a patient in the CASE_LAB_DATAMART and it could be NULL

    IF EXISTS (SELECT 1 FROM dbo.CASE_LAB_DATAMART dm with (nolock) 
            inner join #INVESTIGATION_PATIENT_MAPPING map on map.INVESTIGATION_KEY = dm.INVESTIGATION_KEY
            where datamart_update+case_lab_datamart_update >= 1)
    BEGIN
        update dbo.CASE_LAB_DATAMART 
        set PATIENT_FIRST_NM = tmp.PATIENT_FIRST_NAME,
            PATIENT_MIDDLE_NM = tmp.PATIENT_MIDDLE_NAME,
            PATIENT_LAST_NM = tmp.PATIENT_LAST_NAME,  
            PATIENT_HOME_PHONE = 
                    CASE
                        WHEN tmp.PATIENT_PHONE_HOME <> '' AND tmp.PATIENT_PHONE_EXT_HOME <> ''
                        THEN rtrim(tmp.PATIENT_PHONE_HOME) + ' ext. ' + rtrim(tmp.PATIENT_PHONE_EXT_HOME)
                        WHEN tmp.PATIENT_PHONE_HOME <> '' AND tmp.PATIENT_PHONE_EXT_HOME = ''
                        THEN rtrim(tmp.PATIENT_PHONE_HOME)
                        WHEN tmp.PATIENT_PHONE_HOME = '' AND tmp.PATIENT_PHONE_EXT_HOME <> ''
                        THEN 'ext. ' + rtrim(tmp.PATIENT_PHONE_EXT_HOME)
                        ELSE tmp.PATIENT_PHONE_HOME
                    END ,
            PATIENT_STREET_ADDRESS_1 = tmp.PATIENT_STREET_ADDRESS_1,
            PATIENT_STREET_ADDRESS_2 = tmp.PATIENT_STREET_ADDRESS_2,
            PATIENT_CITY = tmp.PATIENT_CITY,
            PATIENT_STATE = tmp.PATIENT_STATE,
            PATIENT_ZIP = tmp.PATIENT_ZIP,
            RACE = tmp.PATIENT_RACE_CALCULATED,
            PATIENT_COUNTY = tmp.PATIENT_COUNTY,
            PATIENT_DOB = tmp.PATIENT_DOB,
            AGE_REPORTED = tmp.PATIENT_AGE_REPORTED,
            AGE_REPORTED_UNIT = tmp.PATIENT_AGE_REPORTED_UNIT,
            PATIENT_CURRENT_SEX = tmp.PATIENT_CURRENT_SEX
        from   
            #INVESTIGATION_PATIENT_MAPPING tmp
        where 
            dbo.CASE_LAB_DATAMART.INVESTIGATION_KEY = tmp.INVESTIGATION_KEY
            and datamart_update+case_lab_datamart_update >= 1;     
    END

    set @rowcount=@@rowcount;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);
    
    SET @proc_step_name=' Update Patient attributes in BMIRD_STREP_PNEUMO_DATAMART';
    SET @proc_step_no = 5.2;

    -- we use the INVESTIGATION_KEY to update the patient attributes in the BMIRD_STREP_PNEUMO_DATAMART
    -- since PATIENT_LOCAL_ID is the only identifier for a patient in the BMIRD_STREP_PNEUMO_DATAMART 

    IF EXISTS (SELECT 1 FROM dbo.BMIRD_STREP_PNEUMO_DATAMART dm with (nolock) 
            inner join #INVESTIGATION_PATIENT_MAPPING map on map.INVESTIGATION_KEY = dm.INVESTIGATION_KEY
            where datamart_update+bmird_strep_pneumo_datamart_update >= 1)
    BEGIN
        update dbo.BMIRD_STREP_PNEUMO_DATAMART 
        set 
        PATIENT_FIRST_NAME = tmp.PATIENT_FIRST_NAME,
        PATIENT_LAST_NAME = tmp.PATIENT_LAST_NAME, 
        PATIENT_DOB = tmp.PATIENT_DOB,
        PATIENT_CURRENT_SEX = tmp.PATIENT_CURRENT_SEX,
        AGE_REPORTED = tmp.PATIENT_AGE_REPORTED,
        AGE_REPORTED_UNIT = tmp.PATIENT_AGE_REPORTED_UNIT,
        PATIENT_ETHNICITY = tmp.PATIENT_ETHNICITY,
        PATIENT_STREET_ADDRESS_1 = tmp.PATIENT_STREET_ADDRESS_1,
        PATIENT_STREET_ADDRESS_2 = tmp.PATIENT_STREET_ADDRESS_2,
        PATIENT_CITY = tmp.PATIENT_CITY,
        PATIENT_STATE = tmp.PATIENT_STATE,
        PATIENT_ZIP = tmp.PATIENT_ZIP,
        PATIENT_COUNTY = tmp.PATIENT_COUNTY,
        RACE_CALCULATED = tmp.PATIENT_RACE_CALCULATED,
        RACE_CALC_DETAILS = tmp.PATIENT_RACE_CALC_DETAILS
        from  
            #INVESTIGATION_PATIENT_MAPPING tmp
        where 
            dbo.BMIRD_STREP_PNEUMO_DATAMART.INVESTIGATION_KEY = tmp.INVESTIGATION_KEY
            and datamart_update+bmird_strep_pneumo_datamart_update >= 1;    
    END

    set @rowcount=@@rowcount;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);

    SET @proc_step_name=' Update Patient attributes in HEP100';
    SET @proc_step_no = 5.3;

    -- we use the PATIENT_UID to update the patient attributes in the HEP100
    -- since PATIENT_UID is available and is not NULL 

    IF EXISTS (SELECT 1 FROM dbo.HEP100 dm with (nolock) 
            inner join #INVESTIGATION_PATIENT_MAPPING map on map.PATIENT_UID = dm.PATIENT_UID
            where datamart_update+hep100_datamart_update >= 1)
    BEGIN
        update dbo.HEP100 
        set 
        PATIENT_FIRST_NAME = tmp.PATIENT_FIRST_NAME,
        PATIENT_MIDDLE_NAME = tmp.PATIENT_MIDDLE_NAME,
        PATIENT_LAST_NAME = tmp.PATIENT_LAST_NAME, 
        PATIENT_DOB = tmp.PATIENT_DOB,
        PATIENT_CURR_GENDER = tmp.PATIENT_CURRENT_SEX,
        PATIENT_REPORTEDAGE = tmp.PATIENT_AGE_REPORTED,
        PATIENT_REPORTED_AGE_UNITS = tmp.PATIENT_AGE_REPORTED_UNIT,
        PATIENT_ADDRESS = NULLIF(COALESCE(TRIM(tmp.PATIENT_STREET_ADDRESS_1) + ',', '')
                    + COALESCE(TRIM(tmp.PATIENT_STREET_ADDRESS_2) + ',', '')
                    + COALESCE(TRIM(tmp.PATIENT_CITY) + ',', '')
                    + COALESCE(TRIM(tmp.PATIENT_COUNTY) + ',', '')
                    + COALESCE(TRIM(tmp.PATIENT_ZIP) + ',', '')
                    + COALESCE(TRIM(tmp.PATIENT_STATE), ''),''),
        PATIENT_STREET_ADDRESS_2 = tmp.PATIENT_STREET_ADDRESS_2,
        PATIENT_CITY = NULLIF(dbo.fn_get_proper_case(tmp.PATIENT_CITY),'') ,
        PATIENT_STATE = tmp.PATIENT_STATE,
        PATIENT_ZIP_CODE = tmp.PATIENT_ZIP,
        PATIENT_COUNTY = tmp.PATIENT_COUNTY,
        PATIENT_COUNTRY = tmp.PATIENT_COUNTRY,
        PATIENT_ELECTRONIC_IND = tmp.PATIENT_ENTRY_METHOD,
        RACE_CALC_DETAILS = tmp.PATIENT_RACE_CALC_DETAILS
        from  
            #INVESTIGATION_PATIENT_MAPPING tmp
        where 
            dbo.HEP100.PATIENT_UID = tmp.PATIENT_UID
            and datamart_update+hep100_datamart_update >= 1;    
    END
    
    set @rowcount=@@rowcount;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);

    SET @proc_step_name=' Update Patient attributes in Morbidity Report';
    SET @proc_step_no = 5.4;

    -- we use the INVESTIGATION_KEY to update the patient attributes in the MORBIDITY_REPORT_DATAMART
    -- since PATIENT_LOCAL_ID is the only identifier for a patient in the MORBIDITY_REPORT_DATAMART and it's NULLABLE

    IF EXISTS (SELECT 1 FROM dbo.MORBIDITY_REPORT_DATAMART dm with (nolock) 
            inner join #INVESTIGATION_PATIENT_MAPPING map on map.INVESTIGATION_KEY = dm.INVESTIGATION_KEY
            where datamart_update+morbidity_report_datamart_update >= 1)
    BEGIN
        update dbo.MORBIDITY_REPORT_DATAMART 
        set 
        [CALC_5_YEAR_AGE_GROUP]	 = 	CASE
            WHEN tmp.PATIENT_AGE_REPORTED >= 0
                    AND tmp.PATIENT_AGE_REPORTED <= 4
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN ' 1'
            WHEN tmp.PATIENT_AGE_REPORTED >= 5
                    AND tmp.PATIENT_AGE_REPORTED <= 9
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN ' 2'
            WHEN tmp.PATIENT_AGE_REPORTED >= 10
                    AND tmp.PATIENT_AGE_REPORTED <= 14
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN ' 3'
            WHEN tmp.PATIENT_AGE_REPORTED >= 15
                    AND tmp.PATIENT_AGE_REPORTED <= 19
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN ' 4'
            WHEN tmp.PATIENT_AGE_REPORTED >= 20
                    AND tmp.PATIENT_AGE_REPORTED <= 24
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN ' 5'
            WHEN tmp.PATIENT_AGE_REPORTED >= 25
                    AND tmp.PATIENT_AGE_REPORTED <= 29
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN ' 6'
            WHEN tmp.PATIENT_AGE_REPORTED >= 30
                    AND tmp.PATIENT_AGE_REPORTED <= 34
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN ' 7'
            WHEN tmp.PATIENT_AGE_REPORTED >= 35
                    AND tmp.PATIENT_AGE_REPORTED <= 39
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN ' 8'
            WHEN tmp.PATIENT_AGE_REPORTED >= 40
                    AND tmp.PATIENT_AGE_REPORTED <= 44
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN ' 9'
            WHEN tmp.PATIENT_AGE_REPORTED >= 45
                    AND tmp.PATIENT_AGE_REPORTED <= 49
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN '10'
            WHEN tmp.PATIENT_AGE_REPORTED >= 50
                    AND tmp.PATIENT_AGE_REPORTED <= 54
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN '11'
            WHEN tmp.PATIENT_AGE_REPORTED >= 55
                    AND tmp.PATIENT_AGE_REPORTED <= 59
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN '12'
            WHEN tmp.PATIENT_AGE_REPORTED >= 60
                    AND tmp.PATIENT_AGE_REPORTED <= 64
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN '13'
            WHEN tmp.PATIENT_AGE_REPORTED >= 65
                    AND tmp.PATIENT_AGE_REPORTED <= 69
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN '14'
            WHEN tmp.PATIENT_AGE_REPORTED >= 70
                    AND tmp.PATIENT_AGE_REPORTED <= 74
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN '15'
            WHEN tmp.PATIENT_AGE_REPORTED >= 75
                    AND tmp.PATIENT_AGE_REPORTED <= 79
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN '16'
            WHEN tmp.PATIENT_AGE_REPORTED >= 80
                    AND tmp.PATIENT_AGE_REPORTED <= 84
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN '17'
            WHEN tmp.PATIENT_AGE_REPORTED >= 85
                    AND tmp.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                    THEN '18'
            ELSE NULL END
        ,[PATIENT_AGE_REPORTED] = CASE
            WHEN tmp.PATIENT_AGE_REPORTED IS NULL
                    AND tmp.PATIENT_AGE_REPORTED_UNIT IS NULL THEN '           .'
            WHEN tmp.PATIENT_AGE_REPORTED IS NULL THEN RTRIM('           .'+ ' ' + tmp.PATIENT_AGE_REPORTED_UNIT)
            WHEN tmp.PATIENT_AGE_REPORTED_UNIT IS NULL THEN (SELECT RIGHT('            ' + CAST(tmp.PATIENT_AGE_REPORTED AS VARCHAR(50)), 12))
            ELSE (SELECT RIGHT('            ' + CAST(tmp.PATIENT_AGE_REPORTED AS VARCHAR(50)), 12) + ' ' + tmp.PATIENT_AGE_REPORTED_UNIT)
        END
        ,[PATIENT_ALIAS]	 = 	tmp.PATIENT_ALIAS_NICKNAME
        ,[PATIENT_BIRTH_COUNTRY]	 = 	tmp.PATIENT_BIRTH_COUNTRY
        ,[PATIENT_BIRTH_SEX]	 = 	tmp.PATIENT_BIRTH_SEX
        ,[PATIENT_CENSUS_TRACT]	 = 	tmp.PATIENT_CENSUS_TRACT
        ,[PATIENT_CITY]	 = 	tmp.PATIENT_CITY
        ,[PATIENT_COUNTRY]	 = 	tmp.PATIENT_COUNTRY
        ,[PATIENT_COUNTY]	 = 	tmp.PATIENT_COUNTY
        ,[PATIENT_CURR_SEX_UNK_RSN]	 = 	tmp.PATIENT_CURR_SEX_UNK_RSN
        ,[PATIENT_CURRENT_SEX]	 = 	tmp.PATIENT_CURRENT_SEX
        ,[PATIENT_DECEASED_DATE]	 = 	CAST(FORMAT(tmp.PATIENT_DECEASED_DATE, 'yyyy-MM-dd') AS datetime)
        ,[PATIENT_DECEASED_INDICATOR]	 = 	tmp.PATIENT_DECEASED_INDICATOR
        ,[PATIENT_DOB]	 = 	CAST(FORMAT(tmp.PATIENT_DOB, 'yyyy-MM-dd') AS datetime)
        ,[PATIENT_EMAIL]	 = 	tmp.PATIENT_EMAIL
        ,[PATIENT_ETHNICITY]	 = 	tmp.PATIENT_ETHNICITY
        ,[PATIENT_LOCAL_ID]	 = 	tmp.PATIENT_LOCAL_ID
        ,[PATIENT_MARITAL_STATUS]	 = 	tmp.PATIENT_MARITAL_STATUS
        ,[PATIENT_NAME]	 = 	RTRIM((ISNULL(RTRIM(LTRIM(tmp.PATIENT_LAST_NAME)), ' ') + ', ' +
                                        ISNULL(RTRIM(LTRIM(tmp.PATIENT_FIRST_NAME)), ' ') + ' ' +
                                        ISNULL(RTRIM(LTRIM(tmp.PATIENT_MIDDLE_NAME)), '')))
        ,[PATIENT_PHONE_CELL]	 = 	tmp.PATIENT_PHONE_CELL
        ,[PATIENT_PHONE_HOME]	 = 	CASE
            WHEN tmp.PATIENT_PHONE_EXT_HOME IS NULL THEN tmp.PATIENT_PHONE_HOME
            ELSE ISNULL(tmp.PATIENT_PHONE_HOME, ' ') + ' Ext ' + tmp.PATIENT_PHONE_EXT_HOME
        END
        ,[PATIENT_PHONE_WORK]	 = 	CASE
            WHEN tmp.PATIENT_PHONE_EXT_WORK IS NULL THEN tmp.PATIENT_PHONE_WORK
            ELSE ISNULL(tmp.PATIENT_PHONE_WORK, ' ') + ' Ext ' + tmp.PATIENT_PHONE_EXT_WORK
        END
        ,[PATIENT_PREFERRED_GENDER]	 = 	tmp.PATIENT_PREFERRED_GENDER
        ,[PATIENT_PREGNANT_IND]	 = 	INV.PATIENT_PREGNANT_IND
        ,[PATIENT_RACE]	 = 	tmp.PATIENT_RACE_CALCULATED
        ,[PATIENT_SEX]	 = 	CASE
            WHEN tmp.PATIENT_PREFERRED_GENDER IS NULL THEN ISNULL(tmp.PATIENT_CURR_SEX_UNK_RSN, tmp.PATIENT_CURRENT_SEX)
            ELSE tmp.PATIENT_PREFERRED_GENDER
        END
        ,[PATIENT_STATE]	 = 	tmp.PATIENT_STATE
        ,[PATIENT_STREET_ADDRESS_1]	 = 	tmp.PATIENT_STREET_ADDRESS_1
        ,[PATIENT_STREET_ADDRESS_2]	 = 	tmp.PATIENT_STREET_ADDRESS_2
        ,[PATIENT_UNK_ETHNIC_RSN]	 = 	tmp.PATIENT_UNK_ETHNIC_RSN
        ,[PATIENT_ZIP]	 = 	tmp.PATIENT_ZIP
        from  
            #INVESTIGATION_PATIENT_MAPPING tmp
        where 
            dbo.MORBIDITY_REPORT_DATAMART.INVESTIGATION_KEY = tmp.INVESTIGATION_KEY
            and datamart_update+morbidity_report_datamart_update >= 1;    
    END

    set @rowcount=@@rowcount;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);

    SET @proc_step_name=' Update Patient attributes in VAR_DATAMART';
    SET @proc_step_no = 5.5;

    IF EXISTS (SELECT 1 FROM dbo.VAR_DATAMART dm with (nolock) 
            inner join #INVESTIGATION_PATIENT_MAPPING map on map.INVESTIGATION_KEY = dm.INVESTIGATION_KEY
            where datamart_update+var_datamart_update >= 1)
    BEGIN
        update dbo.VAR_DATAMART 
        set 
        PATIENT_PHONE_NUMBER_HOME = tmp.PATIENT_FIRST_NAME
        ,PATIENT_PHONE_EXT_HOME = tmp.PATIENT_PHONE_EXT_HOME
        ,PATIENT_PHONE_NUMBER_WORK = tmp.PATIENT_PHONE_WORK
        ,PATIENT_PHONE_EXT_WORK = tmp.PATIENT_PHONE_EXT_WORK
        ,PATIENT_GENERAL_COMMENTS = tmp.PATIENT_GENERAL_COMMENTS
        ,PATIENT_LAST_NAME = tmp.PATIENT_LAST_NAME 
        ,PATIENT_FIRST_NAME = tmp.PATIENT_FIRST_NAME 
        ,PATIENT_MIDDLE_NAME = tmp.PATIENT_MIDDLE_NAME 
        ,PATIENT_NAME_SUFFIX = tmp.PATIENT_NAME_SUFFIX 
        ,PATIENT_DOB = tmp.PATIENT_DOB 
        ,PATIENT_AGE_REPORTED = tmp.PATIENT_AGE_REPORTED 
        ,AGE_REPORTED_UNIT = tmp.PATIENT_AGE_REPORTED_UNIT
        ,PATIENT_CURRENT_SEX = tmp.PATIENT_CURRENT_SEX 
        ,PATIENT_DECEASED_INDICATOR = tmp.PATIENT_DECEASED_INDICATOR 
        ,PATIENT_DECEASED_DATE = tmp.PATIENT_DECEASED_DATE 
        ,PATIENT_MARITAL_STATUS = tmp.PATIENT_MARITAL_STATUS 
        ,PATIENT_SSN= tmp.PATIENT_SSN
        ,PATIENT_ETHNICITY = tmp.PATIENT_ETHNICITY 
        ,PATIENT_STREET_ADDRESS_1 = tmp.PATIENT_STREET_ADDRESS_1 
        ,PATIENT_STREET_ADDRESS_2 = tmp.PATIENT_STREET_ADDRESS_2 
        ,PATIENT_CITY = tmp.PATIENT_CITY 
        ,PATIENT_STATE = tmp.PATIENT_STATE 
        ,PATIENT_ZIP = tmp.PATIENT_ZIP 
        ,PATIENT_COUNTY = tmp.PATIENT_COUNTY 
        ,PATIENT_COUNTRY = tmp.PATIENT_COUNTRY 
        ,WITHIN_CITY_LIMITS = tmp.PATIENT_WITHIN_CITY_LIMITS
        ,RACE_CALC_DETAILS = tmp.PATIENT_RACE_CALC_DETAILS 
        ,RACE_CALCULATED = tmp.PATIENT_RACE_CALCULATED
        from  
            #INVESTIGATION_PATIENT_MAPPING tmp
        where 
            dbo.VAR_DATAMART.INVESTIGATION_KEY = tmp.INVESTIGATION_KEY
            and datamart_update+var_datamart_update >= 1;    
    END

    set @rowcount=@@rowcount;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);

    SET @proc_step_name=' Update Patient attributes in TB_DATAMART';
    SET @proc_step_no = 5.6;

    IF EXISTS (SELECT 1 FROM dbo.TB_DATAMART dm with (nolock) 
            inner join #INVESTIGATION_PATIENT_MAPPING map on map.INVESTIGATION_KEY = dm.INVESTIGATION_KEY
            where datamart_update+var_datamart_update+tb_datamart_update >= 1)
    BEGIN
        with src as (
        select
            p.PATIENT_PHONE_HOME AS PATIENT_PHONE_NUMBER_HOME,
            p.PATIENT_PHONE_EXT_HOME AS PATIENT_PHONE_EXT_HOME,
            p.PATIENT_PHONE_WORK AS PATIENT_PHONE_NUMBER_WORK,
            p.PATIENT_PHONE_EXT_WORK AS PATIENT_PHONE_EXT_WORK,
            p.PATIENT_GENERAL_COMMENTS AS PATIENT_GENERAL_COMMENTS,
            p.PATIENT_LAST_NAME AS PATIENT_LAST_NAME,
            p.PATIENT_FIRST_NAME AS PATIENT_FIRST_NAME,
            p.PATIENT_MIDDLE_NAME AS PATIENT_MIDDLE_NAME,
            p.PATIENT_NAME_SUFFIX AS PATIENT_NAME_SUFFIX,
            p.PATIENT_DOB AS PATIENT_DOB,
            p.PATIENT_AGE_REPORTED AS AGE_REPORTED,
            p.PATIENT_AGE_REPORTED_UNIT AS AGE_REPORTED_UNIT,
            p.PATIENT_BIRTH_SEX AS PATIENT_BIRTH_SEX,
            p.PATIENT_CURRENT_SEX AS PATIENT_CURRENT_SEX,
            p.PATIENT_DECEASED_INDICATOR AS PATIENT_DECEASED_INDICATOR,
            p.PATIENT_DECEASED_DATE AS PATIENT_DECEASED_DATE,
            p.PATIENT_MARITAL_STATUS AS PATIENT_MARITAL_STATUS,
            p.PATIENT_SSN AS PATIENT_SSN,
            p.PATIENT_ETHNICITY AS PATIENT_ETHNICITY,
            p.PATIENT_STREET_ADDRESS_1 AS PATIENT_STREET_ADDRESS_1,
            p.PATIENT_STREET_ADDRESS_2 AS PATIENT_STREET_ADDRESS_2,
            p.PATIENT_CITY AS PATIENT_CITY,
            p.PATIENT_STATE AS PATIENT_STATE,
            p.PATIENT_ZIP AS PATIENT_ZIP,
            p.PATIENT_COUNTY AS PATIENT_COUNTY,
            p.PATIENT_COUNTRY AS PATIENT_COUNTRY,
            p.PATIENT_WITHIN_CITY_LIMITS AS PATIENT_WITHIN_CITY_LIMITS,
            p.PATIENT_RACE_CALC_DETAILS AS RACE_CALC_DETAILS,
            p.PATIENT_RACE_CALCULATED AS RACE_CALCULATED,
            p.PATIENT_RACE_NAT_HI_1 AS RACE_NAT_HI_1,
            p.PATIENT_RACE_NAT_HI_2 AS RACE_NAT_HI_2,
            p.PATIENT_RACE_NAT_HI_3 AS RACE_NAT_HI_3,
            p.PATIENT_RACE_ASIAN_1 AS RACE_ASIAN_1,
            p.PATIENT_RACE_ASIAN_2 AS RACE_ASIAN_2,
            p.PATIENT_RACE_ASIAN_3 AS RACE_ASIAN_3,
            p.PATIENT_RACE_ASIAN_ALL AS RACE_ASIAN_ALL,
            p.PATIENT_RACE_ASIAN_GT3_IND AS RACE_ASIAN_GT3_IND,
            p.PATIENT_RACE_NAT_HI_GT3_IND AS RACE_NAT_HI_GT3_IND,
            p.PATIENT_RACE_NAT_HI_ALL AS RACE_NAT_HI_ALL,
            CASE 
                WHEN p.PATIENT_DOB IS NOT NULL AND dm.DATE_REPORTED IS NOT NULL 
                THEN DATEDIFF(day, p.PATIENT_DOB, dm.DATE_REPORTED) / 365.25 
                ELSE NULL 
            END AS AGE_IN_DEC
        from  
            dbo.TB_DATAMART dm 
        inner join #INVESTIGATION_PATIENT_MAPPING map on map.INVESTIGATION_KEY = dm.INVESTIGATION_KEY
            where datamart_update+var_datamart_update+tb_datamart_update >= 1
        )
        ,src_transformed as (
        select 
            src.*,
            FLOOR(AGE_IN_DEC) AS CALC_REPORTED_AGE,
            CASE 
                WHEN FLOOR(AGE_IN_DEC) IS NULL THEN NULL
                WHEN -1 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 5 THEN 1
                WHEN 5 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 10 THEN 2
                WHEN 10 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 15 THEN 3
                WHEN 15 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 20 THEN 4
                WHEN 20 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 25 THEN 5
                WHEN 25 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 30 THEN 6
                WHEN 30 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 35 THEN 7
                WHEN 35 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 40 THEN 8
                WHEN 40 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 45 THEN 9
                WHEN 45 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 50 THEN 10
                WHEN 50 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 55 THEN 11
                WHEN 55 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 60 THEN 12
                WHEN 60 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 65 THEN 13
                WHEN 65 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 70 THEN 14
                WHEN 70 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 75 THEN 15
                WHEN 75 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 80 THEN 16
                WHEN 80 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 85 THEN 17
                ELSE 18
            END AS CALC_5_YEAR_AGE_GROUP,
            CASE 
                WHEN FLOOR(AGE_IN_DEC) IS NULL THEN NULL
                WHEN -1 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 10 THEN 1
                WHEN 10 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 20 THEN 2
                WHEN 20 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 30 THEN 3
                WHEN 30 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 40 THEN 4
                WHEN 40 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 50 THEN 5
                WHEN 50 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 60 THEN 6
                WHEN 60 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 70 THEN 7
                WHEN 70 <= FLOOR(AGE_IN_DEC) AND FLOOR(AGE_IN_DEC) < 80 THEN 8
                ELSE 9
            END AS CALC_10_YEAR_AGE_GROUP
        ) 
        update dbo.TB_DATAMART
        set
            PATIENT_PHONE_NUMBER_HOME   = left(tmp.PATIENT_PHONE_NUMBER_HOME, 50),
            PATIENT_PHONE_EXT_HOME      = left(tmp.PATIENT_PHONE_EXT_HOME, 50),
            PATIENT_PHONE_NUMBER_WORK   = left(tmp.PATIENT_PHONE_NUMBER_WORK, 50),
            PATIENT_PHONE_EXT_WORK      = left(tmp.PATIENT_PHONE_EXT_WORK, 50),
            PATIENT_GENERAL_COMMENTS    = left(tmp.PATIENT_GENERAL_COMMENTS, 2000),
            PATIENT_LAST_NAME           = left(tmp.PATIENT_LAST_NAME, 50),
            PATIENT_FIRST_NAME          = left(tmp.PATIENT_FIRST_NAME, 50),
            PATIENT_MIDDLE_NAME         = left(tmp.PATIENT_MIDDLE_NAME, 50),
            PATIENT_NAME_SUFFIX         = left(tmp.PATIENT_NAME_SUFFIX, 50),
            PATIENT_DOB                 = tmp.PATIENT_DOB,
            AGE_REPORTED                = tmp.AGE_REPORTED,
            AGE_REPORTED_UNIT           = left(tmp.AGE_REPORTED_UNIT, 50),
            PATIENT_BIRTH_SEX           = left(tmp.PATIENT_BIRTH_SEX, 50),
            PATIENT_CURRENT_SEX         = left(tmp.PATIENT_CURRENT_SEX,50),
            PATIENT_DECEASED_INDICATOR  = left(tmp.PATIENT_DECEASED_INDICATOR, 50),
            PATIENT_DECEASED_DATE       = tmp.PATIENT_DECEASED_DATE,
            PATIENT_MARITAL_STATUS      = left(tmp.PATIENT_MARITAL_STATUS, 50),
            PATIENT_SSN                 = left(tmp.PATIENT_SSN, 50),
            PATIENT_ETHNICITY           = left(tmp.PATIENT_ETHNICITY, 50),
            PATIENT_STREET_ADDRESS_1    = left(tmp.PATIENT_STREET_ADDRESS_1, 50),
            PATIENT_STREET_ADDRESS_2    = left(tmp.PATIENT_STREET_ADDRESS_2, 50),
            PATIENT_CITY                = left(tmp.PATIENT_CITY, 50),
            PATIENT_STATE               = left(tmp.PATIENT_STATE, 50),
            PATIENT_ZIP                 = left(tmp.PATIENT_ZIP, 50),
            PATIENT_COUNTY              = left(tmp.PATIENT_COUNTY, 50),
            PATIENT_COUNTRY             = left(tmp.PATIENT_COUNTRY, 50),
            PATIENT_WITHIN_CITY_LIMITS  = left(tmp.PATIENT_WITHIN_CITY_LIMITS, 50),
            RACE_CALC_DETAILS           = left(tmp.RACE_CALC_DETAILS, 200),
            RACE_CALCULATED             = left(tmp.RACE_CALCULATED, 4000),
            RACE_NAT_HI_1               = left(tmp.RACE_NAT_HI_1, 50),
            RACE_NAT_HI_2               = left(tmp.RACE_NAT_HI_2, 50),
            RACE_NAT_HI_3               = left(tmp.RACE_NAT_HI_3, 50),
            RACE_ASIAN_1                = left(tmp.RACE_ASIAN_1, 50),
            RACE_ASIAN_2                = left(tmp.RACE_ASIAN_2, 50),
            RACE_ASIAN_3                = left(tmp.RACE_ASIAN_3, 50),
            RACE_ASIAN_ALL              = left(tmp.RACE_ASIAN_ALL, 4000),
            RACE_ASIAN_GT3_IND          = left(tmp.RACE_ASIAN_GT3_IND, 50),
            RACE_NAT_HI_GT3_IND         = left(tmp.RACE_NAT_HI_GT3_IND, 50),
            RACE_NAT_HI_ALL             = left(tmp.RACE_NAT_HI_ALL, 4000),
            CALC_REPORTED_AGE           = tmp.CALC_REPORTED_AGE,
            CALC_5_YEAR_AGE_GROUP       = tmp.CALC_5_YEAR_AGE_GROUP,
            CALC_10_YEAR_AGE_GROUP      = tmp.CALC_10_YEAR_AGE_GROUP,
            PATIENT_BIRTH_COUNTRY       = left(tmp.PATIENT_BIRTH_COUNTRY, 50)
        from src_transformed tmp
        where 
            1=1
            and dbo.TB_DATAMART.INVESTIGATION_KEY = tmp.INVESTIGATION_KEY
            ;

        set @rowcount=@@rowcount;
        INSERT INTO [dbo].[job_flow_log] 
        (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
        VALUES 
        (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);

        SET @proc_step_name=' Update Patient attributes in TB_HIV_DATAMART';
        SET @proc_step_no = 5.7;

        update dbo.TB_HIV_DATAMART
        set
            PATIENT_PHONE_NUMBER_HOME   = tb.PATIENT_PHONE_NUMBER_HOME   
            ,PATIENT_PHONE_EXT_HOME      = tb.PATIENT_PHONE_EXT_HOME      
            ,PATIENT_PHONE_NUMBER_WORK   = tb.PATIENT_PHONE_NUMBER_WORK   
            ,PATIENT_PHONE_EXT_WORK      = tb.PATIENT_PHONE_EXT_WORK      
            ,PATIENT_LOCAL_ID            = tb.PATIENT_LOCAL_ID            
            ,PATIENT_GENERAL_COMMENTS    = tb.PATIENT_GENERAL_COMMENTS    
            ,PATIENT_LAST_NAME           = tb.PATIENT_LAST_NAME           
            ,PATIENT_FIRST_NAME          = tb.PATIENT_FIRST_NAME          
            ,PATIENT_MIDDLE_NAME         = tb.PATIENT_MIDDLE_NAME         
            ,PATIENT_NAME_SUFFIX         = tb.PATIENT_NAME_SUFFIX         
            ,PATIENT_DOB                 = tb.PATIENT_DOB                 
            ,AGE_REPORTED                = tb.AGE_REPORTED                
            ,AGE_REPORTED_UNIT           = tb.AGE_REPORTED_UNIT           
            ,PATIENT_BIRTH_SEX           = tb.PATIENT_BIRTH_SEX           
            ,PATIENT_CURRENT_SEX         = tb.PATIENT_CURRENT_SEX         
            ,PATIENT_DECEASED_INDICATOR  = tb.PATIENT_DECEASED_INDICATOR  
            ,PATIENT_DECEASED_DATE       = tb.PATIENT_DECEASED_DATE       
            ,PATIENT_MARITAL_STATUS      = tb.PATIENT_MARITAL_STATUS      
            ,PATIENT_SSN                 = tb.PATIENT_SSN                 
            ,PATIENT_ETHNICITY           = tb.PATIENT_ETHNICITY           
            ,PATIENT_STREET_ADDRESS_1    = tb.PATIENT_STREET_ADDRESS_1    
            ,PATIENT_STREET_ADDRESS_2    = tb.PATIENT_STREET_ADDRESS_2    
            ,PATIENT_CITY                = tb.PATIENT_CITY                
            ,PATIENT_STATE               = tb.PATIENT_STATE               
            ,PATIENT_ZIP                 = tb.PATIENT_ZIP                 
            ,PATIENT_COUNTY              = tb.PATIENT_COUNTY              
            ,PATIENT_COUNTRY             = tb.PATIENT_COUNTRY             
            ,PATIENT_WITHIN_CITY_LIMITS  = tb.PATIENT_WITHIN_CITY_LIMITS  
            ,RACE_CALC_DETAILS           = tb.RACE_CALC_DETAILS           
            ,RACE_CALCULATED             = tb.RACE_CALCULATED             
            ,RACE_NAT_HI_1               = tb.RACE_NAT_HI_1               
            ,RACE_NAT_HI_2               = tb.RACE_NAT_HI_2               
            ,RACE_NAT_HI_3               = tb.RACE_NAT_HI_3               
            ,RACE_ASIAN_1                = tb.RACE_ASIAN_1                
            ,RACE_ASIAN_2                = tb.RACE_ASIAN_2                
            ,RACE_ASIAN_3                = tb.RACE_ASIAN_3                
            ,RACE_ASIAN_ALL              = tb.RACE_ASIAN_ALL              
            ,RACE_ASIAN_GT3_IND          = tb.RACE_ASIAN_GT3_IND          
            ,RACE_NAT_HI_GT3_IND         = tb.RACE_NAT_HI_GT3_IND         
            ,RACE_NAT_HI_ALL             = tb.RACE_NAT_HI_ALL             
            ,CALC_REPORTED_AGE           = tb.CALC_REPORTED_AGE           
            ,CALC_5_YEAR_AGE_GROUP       = tb.CALC_5_YEAR_AGE_GROUP       
            ,CALC_10_YEAR_AGE_GROUP      = tb.CALC_10_YEAR_AGE_GROUP      
            ,PATIENT_BIRTH_COUNTRY       = tb.PATIENT_BIRTH_COUNTRY       
        from dbo.TB_DATAMART tb
        inner join #INVESTIGATION_PATIENT_MAPPING map on map.INVESTIGATION_KEY = tb.INVESTIGATION_KEY
        and datamart_update+var_datamart_update+tb_datamart_update >= 1
        where 
            tb.INVESTIGATION_KEY = dbo.TB_HIV_DATAMART.INVESTIGATION_KEY
        ;

        set @rowcount=@@rowcount;
        INSERT INTO [dbo].[job_flow_log] 
        (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
        VALUES 
        (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);

    END
 
END;