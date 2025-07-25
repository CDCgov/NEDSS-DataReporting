IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_public_health_case_fact_datamart_event]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_public_health_case_fact_datamart_event]
END
GO 

CREATE PROCEDURE dbo.sp_public_health_case_fact_datamart_event @phc_id_list nvarchar(max), @debug bit = 'false'
AS
BEGIN
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
    DECLARE @batch_start_time DATETIME2(7) = NULL;
    DECLARE @batch_end_time DATETIME2(7) = NULL;
    DECLARE @type_code VARCHAR(200) = 'PHCMartETL';
    DECLARE @type_description VARCHAR(200) = 'PHCMartETL Process';
    DECLARE @return_value INT = 0;
    DECLARE @batch_id bigint;
    SET @batch_id = cast((format(getdate(), 'yyMMddHHmmssffff')) as bigint);



    BEGIN TRY
        --EXEC @return_value = rdb.[dbo].[sp_nbs_batch_start] @type_code
        --	,@type_description;

        -- SELECT 'Return Value TEST ' = @return_value;

        /*
            SELECT @batch_id = batch_id
                ,@batch_start_time = batch_start_dttm --,
                --  @batch_end_time = batch_end_dttm
            FROM rdb.[dbo].[job_batch_log]
            WHERE type_code = 'PHCMartETL'
                AND status_type = 'start'

            SET @batch_end_time = getdate();
            */

        --PRINT 'starttime' + LEFT(CONVERT(VARCHAR, @batch_start_time, 120), 10)
        --PRINT 'endtime' + LEFT(CONVERT(VARCHAR, @batch_end_time, 120), 10)
        PRINT CAST(@batch_id AS VARCHAR(max));

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_INV_FORM_CODE_DATA';

        IF OBJECT_ID('#TEMP_INV_FORM_CODE_DATA') IS NOT NULL
            DROP TABLE #TEMP_INV_FORM_CODE_DATA;

        -- The below SQL is now a view - nbs_odse.dbo.v_inv_form_code_data
        /*SELECT DISTINCT DATA_LOCATION
            ,CODESET.CODE_SET_GROUP_ID
            ,CODESET.CODE_SET_NM
            ,NBS_UI_METADATA.INVESTIGATION_FORM_CD
            ,CODE_VALUE_GENERAL.CODE
            ,CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        INTO #TEMP_INV_FORM_CODE_DATA
        FROM NBS_ODSE.DBO.NBS_UI_METADATA WITH (NOLOCK)
        INNER JOIN NBS_SRTE.DBO.CODESET WITH (NOLOCK) ON NBS_UI_METADATA.CODE_SET_GROUP_ID = CODESET.CODE_SET_GROUP_ID
        INNER JOIN NBS_SRTE.DBO.CONDITION_CODE WITH (NOLOCK) ON CONDITION_CODE.INVESTIGATION_FORM_CD = NBS_UI_METADATA.INVESTIGATION_FORM_CD
        INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON CODE_VALUE_GENERAL.CODE_SET_NM = CODESET.CODE_SET_NM
        WHERE  question_identifier in (
                'DEM218', 'DEM114', 'INV163',  'INV161',  'DEM126',  'DEM113', 'DEM127', 'INV159', 'INV152', 'DEM155', 'NOT112', 'INV109',  'INV107', 'DEM140',  'DEM116_B', 'DEM139', 'INV145', 'INV150', 'INV151', 'NPP063', 'INV144', 'DEM142', 'INV108',  'DEM152', 'DEM238', 'INV187', 'INV112', 'INV174', 'INV107', 'INV2002')
                AND CODESET.CODE_SET_GROUP_ID IS NOT NULL
        ORDER BY NBS_UI_METADATA.DATA_LOCATION */

        -- use the view and order by data_location
        Select DATA_LOCATION
             ,CODE_SET_GROUP_ID
             ,CODE_SET_NM
             ,INVESTIGATION_FORM_CD
             ,CODE
             ,CODE_SHORT_DESC_TXT
        INTO #TEMP_INV_FORM_CODE_DATA
        from nbs_odse.dbo.v_inv_form_code_data
        ORDER BY DATA_LOCATION;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;
        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating DBO.TEMP_UPDATE_NEW_PATIENT';


        IF OBJECT_ID('#TEMP_UPDATE_NEW_PATIENT') IS NOT NULL
            DROP TABLE #TEMP_UPDATE_NEW_PATIENT;

        SELECT  Public_health_case.PUBLIC_HEALTH_CASE_UID
             ,PER.PERSON_UID
             ,PER.PERSON_PARENT_UID
             ,PER.LOCAL_ID AS PERSON_LOCAL_ID
             ,PER.AGE_CATEGORY_CD
             ,PER.AGE_REPORTED
             ,PER.AGE_REPORTED_TIME
             ,PER.AGE_REPORTED_UNIT_CD
             ,PER.BIRTH_TIME
             ,PER.BIRTH_TIME_CALC
             ,PER.CD AS PERSON_CD
             ,PER.CD_DESC_TXT AS PERSON_CODE_DESC
             ,PER.CURR_SEX_CD
             ,PER.DECEASED_IND_CD
             ,PER.DECEASED_TIME
             ,PER.ETHNIC_GROUP_IND
             ,PER.MARITAL_STATUS_CD
             ,MPR.MULTIPLE_BIRTH_IND
             ,MPR.OCCUPATION_CD
             ,MPR.PRIM_LANG_CD
             ,MPR.ADULTS_IN_HOUSE_NBR
             ,MPR.BIRTH_GENDER_CD
             ,MPR.BIRTH_ORDER_NBR
             ,MPR.CHILDREN_IN_HOUSE_NBR
             ,MPR.EDUCATION_LEVEL_CD
             ,MPR.LAST_CHG_TIME AS MPR_LAST_CHG_TIME
             ,NOTIFICATION.LAST_CHG_TIME AS NOTIF_LAST_CHG_TIME
        INTO #TEMP_UPDATE_NEW_PATIENT
        FROM NBS_ODSE.DBO.PERSON PER WITH (NOLOCK)
                 INNER JOIN NBS_ODSE.DBO.PARTICIPATION PAR WITH (NOLOCK) ON PER.PERSON_UID = PAR.SUBJECT_ENTITY_UID
                 INNER JOIN NBS_ODSE.DBO.Public_health_case Public_health_case WITH (NOLOCK) ON PAR.act_uid = Public_health_case.public_health_case_uid
                 INNER JOIN NBS_ODSE.DBO.PERSON MPR WITH (NOLOCK) ON PER.PERSON_PARENT_UID = MPR.PERSON_UID
                 LEFT JOIN NBS_ODSE.DBO.ACT_RELATIONSHIP  WITH (NOLOCK) ON ACT_RELATIONSHIP.TARGET_ACT_UID=PUBLIC_HEALTH_CASE.PUBLIC_HEALTH_CASE_UID
                 LEFT JOIN NBS_ODSE.DBO.NOTIFICATION   WITH (NOLOCK) ON NOTIFICATION.NOTIFICATION_UID=ACT_RELATIONSHIP.SOURCE_ACT_UID
            AND NOTIFICATION.CD='NOTF'
        WHERE PAR.TYPE_CD = 'SUBJOFPHC'
          and  Public_health_case.public_health_case_uid in (select value from string_split(@phc_id_list, ','))
        /*  AND (
                (PER.LAST_CHG_TIME >= @batch_start_time
                AND PER.LAST_CHG_TIME< @batch_end_time)
                OR (MPR.LAST_CHG_TIME >= @batch_start_time
                AND MPR.LAST_CHG_TIME< @batch_end_time)
                OR (NOTIFICATION.LAST_CHG_TIME >= @batch_start_time
                AND NOTIFICATION.LAST_CHG_TIME< @batch_end_time)
                )
        */

         if @debug = 'true' Select '#TEMP_UPDATE_NEW_PATIENT', * from #TEMP_UPDATE_NEW_PATIENT;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );
        COMMIT TRANSACTION;
        -------------------PHCSUBJECT
        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_PHCPATIENTINFO';

        IF OBJECT_ID('#TEMP_PHCPATIENTINFO') IS NOT NULL
            DROP TABLE #TEMP_PHCPATIENTINFO;

        SELECT
                   PER.*
             ,PATIENTNAME
             ,case when LTRIM(RTRIM(PST.STATE_CD)) = '' then null else LTRIM(RTRIM(PST.STATE_CD)) end STATE_CD
             ,SRT1.code_short_desc_txt AS STATE
             ,case when LTRIM(RTRIM(PST.CNTY_CD)) = '' then null else LTRIM(RTRIM(PST.CNTY_CD)) end CNTY_CD
             ,SRT3.code_desc_txt AS COUNTY
             ,PAR.AWARENESS_CD
             ,PAR.AWARENESS_DESC_TXT
             ,PAR.TYPE_CD AS PAR_TYPE_CD
             ,CVG.CODE_SHORT_DESC_TXT AS EDUCATION_LEVEL_DESC_TXT
             ,RTRIM(LTRIM(A.CODE_SHORT_DESC_TXT)) AS ETHNIC_GROUP_IND_DESC
             ,CVG2.CODE_SHORT_DESC_TXT AS MARITAL_STATUS_DESC_TXT
             ,LNG.CODE_SHORT_DESC_TXT AS PRIM_LANG_DESC_TXT
             ,ELP.FROM_TIME AS ELP_FROM_TIME
             ,ELP.TO_TIME AS ELP_TO_TIME
             ,ELP.CLASS_CD AS ELP_CLASS_CD
             ,ELP.USE_CD AS ELP_USE_CD
             ,ELP.AS_OF_DATE AS SUB_ADDR_AS_OF_DATE
             ,PST.POSTAL_LOCATOR_UID
             ,PST.CENSUS_BLOCK_CD
             ,PST.CENSUS_MINOR_CIVIL_DIVISION_CD
             ,PST.CENSUS_TRACK_CD
             ,PST.CITY_CD
             ,case when LTRIM(RTRIM(PST.CITY_DESC_TXT)) = '' then null else LTRIM(RTRIM(PST.CITY_DESC_TXT)) end CITY_DESC_TXT
             ,case when LTRIM(RTRIM(PST.CNTRY_CD)) = '' then null else LTRIM(RTRIM(PST.CNTRY_CD)) end CNTRY_CD
             ,CNTRY_DESC.CODE_SHORT_DESC_TXT AS CNTRY_DESC_TXT
             ,PST.REGION_DISTRICT_CD
             ,PST.MSA_CONGRESS_DISTRICT_CD
             ,case when LTRIM(RTRIM(PST.ZIP_CD)) = '' then null else LTRIM(RTRIM(PST.ZIP_CD)) end ZIP_CD
             ,PST.RECORD_STATUS_TIME AS PST_RECORD_STATUS_TIME
             ,PST.RECORD_STATUS_CD AS PST_RECORD_STATUS_CD
             ,case when LTRIM(RTRIM(PST.STREET_ADDR1)) = '' then null else LTRIM(RTRIM(PST.STREET_ADDR1)) end STREET_ADDR1
             ,case when LTRIM(RTRIM(PST.STREET_ADDR2)) = '' then null else LTRIM(RTRIM(PST.STREET_ADDR2)) end STREET_ADDR2
             ,PAR.ACT_UID
             ,CONDITION_CODE.INVESTIGATION_FORM_CD
             ,AGE_UNIT.CODE_SHORT_DESC_TXT AS AGE_REPORTED_UNIT_DESC_TXT
             ,BIRTH_GENDER.CODE_SHORT_DESC_TXT AS BIRTH_GENDER_DESC_TXT
             ,CURR_SEX.CODE_SHORT_DESC_TXT AS CURR_SEX_DESC_TXT
             ,OCCUPATION.CODE_SHORT_DESC_TXT AS OCCUPATION_DESC_TXT
             ,RN = ROW_NUMBER() OVER (
            PARTITION BY PER.PERSON_UID ORDER BY PER.PERSON_UID
            )
             , CASE WHEN (CONDITION_CODE.investigation_form_cd NOT LIKE 'PG_%' or CONDITION_CODE.investigation_form_cd  is null) then 1 else 0 end as FLAG1 ---added this as part of optimization (very imp)
        INTO #TEMP_PHCPATIENTINFO
        FROM #TEMP_UPDATE_NEW_PATIENT PER WITH (NOLOCK)
                 INNER JOIN NBS_ODSE.DBO.PARTICIPATION PAR WITH (NOLOCK) ON PER.PERSON_UID = PAR.SUBJECT_ENTITY_UID
                 INNER JOIN NBS_ODSE.DBO.Public_health_case Public_health_case WITH (NOLOCK) ON PAR.act_uid = Public_health_case.public_health_case_uid
                 INNER JOIN NBS_srte.DBO.Condition_code Condition_code WITH (NOLOCK) ON Condition_code.condition_cd = Public_health_case.cd
                 LEFT OUTER JOIN NBS_ODSE.DBO.ENTITY_LOCATOR_PARTICIPATION ELP WITH (NOLOCK) ON ELP.ENTITY_UID = PER.PERSON_UID
            AND ELP.USE_CD = 'H'
            AND ELP.CLASS_CD = 'PST'
            AND ELP.RECORD_STATUS_CD = 'ACTIVE'
                 LEFT OUTER JOIN NBS_ODSE.DBO.POSTAL_LOCATOR PST WITH (NOLOCK) ON ELP.LOCATOR_UID = PST.POSTAL_LOCATOR_UID
            AND PST.RECORD_STATUS_CD = 'ACTIVE'
                 LEFT OUTER JOIN NBS_SRTE.DBO.Code_value_general CNTRY_DESC ON CNTRY_DESC.code=PST.cntry_cd
            AND CNTRY_DESC.CODE=PST.CNTRY_CD
            AND CNTRY_DESC.CODE_SET_NM='PSL_CNTRY'
                 LEFT OUTER JOIN NBS_SRTE.DBO.V_state_code SRT1 WITH (NOLOCK) ON PST.STATE_CD = SRT1.CODE
                 LEFT OUTER JOIN NBS_SRTE.DBO.state_county_code_value SRT3 WITH (NOLOCK) ON PST.CNTY_CD = SRT3.CODE
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA A ON A.CODE=PER.ETHNIC_GROUP_IND
            AND  A.investigation_form_cd = Condition_code.investigation_form_cd
            AND A.DATA_LOCATION LIKE '%.ETHNIC_GROUP_IND'
                 LEFT OUTER JOIN (
                 select PERSON_UID, PATIENTNAME, isnull(RECORD_STATUS_CD, 'ACTIVE') as RECORD_STATUS_CD, NM_USE_CD
                 	from (
						select PERSON_UID, (COALESCE(LTRIM(RTRIM(LAST_NM)), '') + ', ' + COALESCE(LTRIM(RTRIM(FIRST_NM)), '')) AS PATIENTNAME, NM_USE_CD,
						RECORD_STATUS_CD, LAST_CHG_TIME ,  ROW_NUMBER() OVER(partition by PERSON_UID ORDER BY last_chg_time desc ) AS rnum
						from NBS_ODSE.DBO.PERSON_NAME WITH (NOLOCK) ) t
					where rnum=1 ) PNM ON PER.PERSON_UID = PNM.PERSON_UID
            AND PNM.NM_USE_CD = 'L'
            AND PNM.RECORD_STATUS_CD = 'ACTIVE'

                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA AGE_UNIT WITH (NOLOCK) ON PER.age_reported_unit_cd = AGE_UNIT.CODE
            AND  AGE_UNIT.investigation_form_cd = Condition_code.investigation_form_cd
            AND AGE_UNIT.DATA_LOCATION LIKE 'Person.age_reported_unit_cd'
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA BIRTH_GENDER WITH (NOLOCK) ON PER.birth_gender_cd = BIRTH_GENDER.CODE
            AND  BIRTH_GENDER.investigation_form_cd = Condition_code.investigation_form_cd
            AND BIRTH_GENDER.DATA_LOCATION LIKE 'Person.birth_gender_cd'
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA CURR_SEX WITH (NOLOCK) ON PER.curr_sex_cd = CURR_SEX.CODE
            AND  CURR_SEX.investigation_form_cd = Condition_code.investigation_form_cd
            AND CURR_SEX.DATA_LOCATION LIKE 'Person.curr_sex_cd'
                 LEFT OUTER JOIN NBS_SRTE.DBO.NAICS_INDUSTRY_CODE OCCUPATION WITH (NOLOCK) ON PER.occupation_cd = OCCUPATION.CODE
                 LEFT OUTER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL CVG WITH (NOLOCK) ON PER.education_level_cd = CVG.CODE
            AND CVG.CODE_SET_NM = 'P_EDUC_LVL'
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA CVG2 WITH (NOLOCK) ON PER.MARITAL_STATUS_CD = CVG2.CODE
            AND  CVG2.investigation_form_cd = Condition_code.investigation_form_cd
            AND CVG2.DATA_LOCATION = 'PERSON.MARITAL_STATUS_CD'
                 LEFT OUTER JOIN NBS_SRTE.DBO.LANGUAGE_CODE LNG WITH (NOLOCK) ON PER.PRIM_LANG_CD = LNG.CODE
        where Public_health_case.public_health_case_uid in (select value from string_split(@phc_id_list, ','))
        ORDER BY PAR.ACT_UID;

        if @debug = 'true' Select '##TEMP_PHCPATIENTINFO', * from #TEMP_PHCPATIENTINFO;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        DELETE
        FROM #TEMP_PHCPATIENTINFO
        WHERE RN > 1

        /* -- moved to the above sql
         UPDATE #TEMP_PHCPATIENTINFO
        SET city_desc_txt = NULL
        WHERE city_desc_txt = LTRIM(RTRIM(''));

        UPDATE #TEMP_PHCPATIENTINFO
        SET STREET_ADDR1 = NULL
        WHERE STREET_ADDR1 = LTRIM(RTRIM(''));

        UPDATE #TEMP_PHCPATIENTINFO
        SET STREET_ADDR2 = NULL
        WHERE STREET_ADDR2 = LTRIM(RTRIM(''));

        UPDATE #TEMP_PHCPATIENTINFO
        SET cntry_cd = NULL
        WHERE cntry_cd = LTRIM(RTRIM(''));


        UPDATE #TEMP_PHCPATIENTINFO
        SET ZIP_CD = NULL
        WHERE ZIP_CD = LTRIM(RTRIM(''));

        UPDATE #TEMP_PHCPATIENTINFO
        SET CNTY_CD = NULL
        WHERE CNTY_CD = LTRIM(RTRIM(''));


        */


        PRINT '1. starttime' + LEFT(CONVERT(VARCHAR, @batch_start_time, 120), 10)
        PRINT '1. endtime' + LEFT(CONVERT(VARCHAR, @batch_end_time, 120), 10)


        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        UPDATE #TEMP_PHCPATIENTINFO
        SET ETHNIC_GROUP_IND_DESC = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCPATIENTINFO
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON #TEMP_PHCPATIENTINFO.ETHNIC_GROUP_IND = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'P_ETHN_GRP'
            AND #TEMP_PHCPATIENTINFO.FLAG1 =1; ---added this optimization


        UPDATE #TEMP_PHCPATIENTINFO
        SET MARITAL_STATUS_DESC_TXT = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCPATIENTINFO
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON #TEMP_PHCPATIENTINFO.MARITAL_STATUS_CD = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'P_MARITAL'
            AND #TEMP_PHCPATIENTINFO.FLAG1 =1; ---added this optimization


        UPDATE #TEMP_PHCPATIENTINFO
        SET BIRTH_GENDER_DESC_TXT = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCPATIENTINFO
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON #TEMP_PHCPATIENTINFO.birth_gender_cd = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'SEX'
            AND BIRTH_GENDER_DESC_TXT IS NULL
            AND birth_gender_cd IS NOT NULL


        UPDATE #TEMP_PHCPATIENTINFO
        SET AGE_REPORTED_UNIT_DESC_TXT = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCPATIENTINFO
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON #TEMP_PHCPATIENTINFO.age_reported_unit_cd = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'AGE_UNIT'
            AND #TEMP_PHCPATIENTINFO.FLAG1 =1; ---added this optimization


        UPDATE #TEMP_PHCPATIENTINFO
        SET CURR_SEX_DESC_TXT = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCPATIENTINFO
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON #TEMP_PHCPATIENTINFO.curr_sex_cd = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'SEX'
            AND #TEMP_PHCPATIENTINFO.FLAG1 =1; ---added this optimization


        COMMIT TRANSACTION;
        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_PHCINFO_INIT';
        IF OBJECT_ID('#TEMP_PHCINFO_INIT') IS NOT NULL
            DROP TABLE #TEMP_PHCINFO_INIT;

        SELECT OBSERVATION2.CD, t.PUBLIC_HEALTH_CASE_UID,OBS_VALUE_DATE.FROM_TIME
        INTO #TEMP_PHCINFO_INIT
        FROM #TEMP_PHCPATIENTINFO t WITH (NOLOCK)
                 INNER JOIN NBS_ODSE.DBO.ACT_RELATIONSHIP WITH (NOLOCK) ON ACT_RELATIONSHIP.TARGET_ACT_UID=t.PUBLIC_HEALTH_CASE_UID
                 INNER JOIN NBS_ODSE.DBO.ACT_RELATIONSHIP ACT_RELATIONSHIP2 WITH (NOLOCK) ON ACT_RELATIONSHIP2.TARGET_ACT_UID=ACT_RELATIONSHIP.SOURCE_ACT_UID
                 LEFT JOIN NBS_ODSE.DBO.OBSERVATION OBSERVATION2 WITH (NOLOCK) ON OBSERVATION2.OBSERVATION_UID =ACT_RELATIONSHIP2.SOURCE_ACT_UID
                 LEFT JOIN NBS_ODSE.DBO.OBS_VALUE_DATE  WITH (NOLOCK) ON OBSERVATION2.OBSERVATION_UID =OBS_VALUE_DATE.OBSERVATION_UID
        WHERE OBSERVATION2.CD IN ('INV132', 'INV133') AND ACT_RELATIONSHIP.TYPE_CD ='PHCInvForm';

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_PHCINFO_LEGACY_HOSP';
        IF OBJECT_ID('#TEMP_PHCINFO_LEGACY_HOSP') IS NOT NULL
            DROP TABLE #TEMP_PHCINFO_LEGACY_HOSP;

        SELECT OBSERVATION2.CD, t.PUBLIC_HEALTH_CASE_UID,OBS_VALUE_CODED.CODE
        INTO #TEMP_PHCINFO_LEGACY_HOSP
        FROM #TEMP_PHCPATIENTINFO t WITH (NOLOCK)
                 INNER JOIN NBS_ODSE.DBO.ACT_RELATIONSHIP WITH (NOLOCK) ON ACT_RELATIONSHIP.TARGET_ACT_UID=t.PUBLIC_HEALTH_CASE_UID
                 INNER JOIN NBS_ODSE.DBO.ACT_RELATIONSHIP ACT_RELATIONSHIP2 WITH (NOLOCK) ON ACT_RELATIONSHIP2.TARGET_ACT_UID=ACT_RELATIONSHIP.SOURCE_ACT_UID
                 INNER JOIN NBS_ODSE.DBO.OBSERVATION AS OBSERVATION2  WITH (NOLOCK) ON ACT_RELATIONSHIP2.SOURCE_ACT_UID =OBSERVATION2.OBSERVATION_UID
                 INNER JOIN NBS_ODSE.DBO.OBS_VALUE_CODED  WITH (NOLOCK) ON ACT_RELATIONSHIP2.SOURCE_ACT_UID =OBS_VALUE_CODED.OBSERVATION_UID
        WHERE OBSERVATION2.CD IN ('INV128') AND ACT_RELATIONSHIP.TYPE_CD ='PHCInvForm';

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_PHCINFO1';

        IF OBJECT_ID('#TEMP_PHCINFO1') IS NOT NULL
            DROP TABLE #TEMP_PHCINFO1;

        SELECT PHC.PUBLIC_HEALTH_CASE_UID
             ,PHC.CASE_TYPE_CD
             ,PHC.DIAGNOSIS_TIME AS DIAGNOSIS_DATE
             ,PHC.CD AS PHC_CODE
             ,PHC.CD_DESC_TXT AS PHC_CODE_DESC
             ,ISNULL(PHC.CASE_CLASS_CD, '') CASE_CLASS_CD
             ,PHC.CD_SYSTEM_CD
             ,PHC.CD_SYSTEM_DESC_TXT
             ,PHC.CONFIDENTIALITY_CD
             ,PHC.CONFIDENTIALITY_DESC_TXT
             ,case when ltrim(rtrim(PHC.DETECTION_METHOD_CD)) = '' then null else ltrim(rtrim(PHC.DETECTION_METHOD_CD)) end detection_method_cd
             ,
            /*PHC.DETECTION_METHOD_DESC_TXT,*/
            case when ltrim(rtrim(PHC.DISEASE_IMPORTED_CD)) = '' then null else ltrim(rtrim(PHC.DISEASE_IMPORTED_CD)) end DISEASE_IMPORTED_CD
             ,
            /*PHC.DISEASE_IMPORTED_DESC_TXT,*/
            PHC.GROUP_CASE_CNT
             ,PHC.INVESTIGATION_STATUS_CD
             ,PHC.JURISDICTION_CD
             ,JURISDICTION_CODE.CODE_DESC_TXT AS JURISDICTION
             ,case when SUBSTRING(ltrim(rtrim(PHC.MMWR_WEEK)), 1, 4) = '' then null else SUBSTRING(ltrim(rtrim(PHC.MMWR_WEEK)), 1, 4) end MMWR_WEEK
             ,case when SUBSTRING(ltrim(rtrim(PHC.MMWR_YEAR)), 1, 4) = '' then null else SUBSTRING(ltrim(rtrim(PHC.MMWR_YEAR)), 1, 4) end MMWR_YEAR
             ,case when ltrim(rtrim(PHC.OUTBREAK_IND)) = '' then null else ltrim(rtrim(PHC.OUTBREAK_IND)) end OUTBREAK_IND
             ,case when ltrim(rtrim(PHC.OUTBREAK_FROM_TIME)) = '' then null else ltrim(rtrim(PHC.OUTBREAK_FROM_TIME)) end OUTBREAK_FROM_TIME
             ,case when ltrim(rtrim(PHC.OUTBREAK_TO_TIME)) = '' then null else ltrim(rtrim(PHC.OUTBREAK_TO_TIME)) end OUTBREAK_TO_TIME
             ,case when ltrim(rtrim(PHC.OUTBREAK_NAME)) = '' then null else ltrim(rtrim(PHC.OUTBREAK_NAME)) end OUTBREAK_NAME
             ,case when ltrim(rtrim(PHC.OUTCOME_CD)) = '' then null else ltrim(rtrim(PHC.OUTCOME_CD)) end OUTCOME_CD
             ,case when SUBSTRING(ltrim(rtrim(PHC.PAT_AGE_AT_ONSET)), 1, 4) = '' then null else SUBSTRING(ltrim(rtrim(PHC.PAT_AGE_AT_ONSET)), 1, 4) end PAT_AGE_AT_ONSET
             ,case when ltrim(rtrim(PHC.PAT_AGE_AT_ONSET_UNIT_CD)) = '' then null else ltrim(rtrim(PHC.PAT_AGE_AT_ONSET_UNIT_CD)) end PAT_AGE_AT_ONSET_UNIT_CD
             ,PHC.PROG_AREA_CD
             ,PHC.RECORD_STATUS_CD
             ,PHC.RPT_CNTY_CD
             ,PHC.RPT_FORM_CMPLT_TIME
             ,case when ltrim(rtrim(PHC.RPT_SOURCE_CD)) = '' then null else ltrim(rtrim(PHC.RPT_SOURCE_CD)) end RPT_SOURCE_CD
             ,
            /*PHC.RPT_SOURCE_CD_DESC_TXT*/
            PHC.RPT_TO_COUNTY_TIME
             ,PHC.RPT_TO_STATE_TIME
             ,PHC.STATUS_CD
             ,PHC.EFFECTIVE_FROM_TIME AS ONSETDATE
             ,PHC.ACTIVITY_FROM_TIME AS INVESTIGATIONSTARTDATE
             ,PHC.ADD_TIME AS PHC_ADD_TIME
             ,PHC.PROGRAM_JURISDICTION_OID
             ,PHC.SHARED_IND
             ,PHC.IMPORTED_COUNTRY_CD AS IMPORTED_COUNTRY_CODE
             ,PHC.IMPORTED_STATE_CD AS IMPORTED_STATE_CODE
             ,PHC.IMPORTED_COUNTY_CD AS IMPORTED_COUNTY_CODE
             ,PHC.INVESTIGATOR_ASSIGNED_TIME AS INVESTIGATOR_ASSIGN_DATE
             ,PHC.HOSPITALIZED_ADMIN_TIME AS HSPTL_ADMISSION_DT
             ,PHC.HOSPITALIZED_DISCHARGE_TIME AS HSPTL_DISCHARGE_DT
             ,PHC.HOSPITALIZED_DURATION_AMT
             ,PHC.IMPORTED_CITY_DESC_TXT
             ,PHC.DECEASED_TIME AS INVESTIGATION_DEATH_DATE
             ,PHC.LOCAL_ID AS LOCAL_ID
             ,PHC.LAST_CHG_TIME AS LASTUPDATE
             ,case when ltrim(rtrim(PHC.TXT)) = '' then null else ltrim(rtrim(PHC.TXT)) end PHCTXT
             ,FOOD_HANDLER_IND_CD
             ,case when ltrim(rtrim(hospitalized_ind_cd)) = '' then null else ltrim(rtrim(hospitalized_ind_cd)) end HOSPITALIZED_IND
             ,DAY_CARE_IND_CD
             ,PREGNANT_IND_CD
             ,CONDITION_CODE.INVESTIGATION_FORM_CD
             ,TEMP_PHCINFO_INITA.FROM_TIME AS LEGACY_HSPTL_ADMISSION_DT
             ,TEMP_PHCINFO_INITb.FROM_TIME AS LEGACY_HSPTL_DISCHARGE_DT
             ,NOTIF_LAST_CHG_TIME
             ,t.CODE AS LEGACY_HOSP_IND
        INTO #TEMP_PHCINFO1
        FROM NBS_ODSE.DBO.PUBLIC_HEALTH_CASE PHC WITH (NOLOCK)
                 INNER JOIN #TEMP_PHCPATIENTINFO t1 ON PHC.PUBLIC_HEALTH_CASE_UID = t1.ACT_UID
                 LEFT OUTER JOIN NBS_SRTE.DBO.JURISDICTION_CODE WITH (NOLOCK) ON JURISDICTION_CODE.CODE = PHC.jurisdiction_cd
                 INNER JOIN NBS_SRTE.DBO.Condition_code ON PHC.CD=Condition_code.condition_cd
                 LEFT OUTER JOIN #TEMP_PHCINFO_INIT TEMP_PHCINFO_INITA ON  PHC.PUBLIC_HEALTH_CASE_UID = TEMP_PHCINFO_INITA.PUBLIC_HEALTH_CASE_UID
            AND TEMP_PHCINFO_INITA.CD='INV132'
                 LEFT OUTER JOIN #TEMP_PHCINFO_INIT TEMP_PHCINFO_INITB ON  PHC.PUBLIC_HEALTH_CASE_UID = TEMP_PHCINFO_INITB.PUBLIC_HEALTH_CASE_UID
            AND TEMP_PHCINFO_INITB.CD='INV133'
                 LEFT OUTER JOIN #TEMP_PHCINFO_LEGACY_HOSP t  ON  PHC.PUBLIC_HEALTH_CASE_UID = t.PUBLIC_HEALTH_CASE_UID
            AND t.CD='INV128'
        where PHC.public_health_case_uid in (select value from string_split(@phc_id_list, ','))


        if @debug = 'true' Select '#TEMP_PHCINFO1', * from #TEMP_PHCINFO1;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        PRINT @ROWCOUNT_NO;

        UPDATE #TEMP_PHCINFO1
        SET HSPTL_ADMISSION_DT = LEGACY_HSPTL_ADMISSION_DT
        WHERE LEGACY_HSPTL_ADMISSION_DT IS NOT NULL;

        UPDATE #TEMP_PHCINFO1
        SET HOSPITALIZED_IND = LEGACY_HOSP_IND
        WHERE LEGACY_HOSP_IND IS NOT NULL;

        UPDATE #TEMP_PHCINFO1
        SET HSPTL_DISCHARGE_DT = LEGACY_HSPTL_DISCHARGE_DT
        WHERE LEGACY_HSPTL_DISCHARGE_DT IS NOT NULL;
/*
		UPDATE #TEMP_PHCINFO1
		SET detection_method_cd = NULL
		WHERE detection_method_cd = LTRIM(RTRIM(''));

		UPDATE #TEMP_PHCINFO1
		SET outcome_cd = NULL
		WHERE outcome_cd = LTRIM(RTRIM(''));

		UPDATE #TEMP_PHCINFO1
		SET outbreak_from_time = NULL
		WHERE outbreak_from_time = LTRIM(RTRIM(''));

		UPDATE #TEMP_PHCINFO1
		SET outbreak_ind = NULL
		WHERE outbreak_ind = LTRIM(RTRIM(''));

		UPDATE #TEMP_PHCINFO1
		SET outbreak_name = NULL
		WHERE outbreak_name = LTRIM(RTRIM(''));

		UPDATE #TEMP_PHCINFO1
		SET disease_imported_cd = NULL
		WHERE disease_imported_cd = LTRIM(RTRIM(''));

		UPDATE #TEMP_PHCINFO1
		SET PAT_AGE_AT_ONSET = NULL
		WHERE PAT_AGE_AT_ONSET = LTRIM(RTRIM(''));

		UPDATE #TEMP_PHCINFO1
		SET PAT_AGE_AT_ONSET_UNIT_CD = NULL
		WHERE PAT_AGE_AT_ONSET_UNIT_CD = LTRIM(RTRIM(''));

		UPDATE #TEMP_PHCINFO1
		SET MMWR_YEAR = NULL
		WHERE MMWR_YEAR = LTRIM(RTRIM(''));

		UPDATE #TEMP_PHCINFO1
		SET MMWR_WEEK = NULL
		WHERE MMWR_WEEK = LTRIM(RTRIM(''));

		UPDATE #TEMP_PHCINFO1
		SET RPT_SOURCE_CD = NULL
		WHERE RPT_SOURCE_CD = LTRIM(RTRIM(''));

		UPDATE #TEMP_PHCINFO1
		SET HOSPITALIZED_IND = NULL
		WHERE HOSPITALIZED_IND = LTRIM(RTRIM(''));
*/
        ALTER TABLE #TEMP_PHCINFO1 DROP column LEGACY_HSPTL_DISCHARGE_DT, LEGACY_HSPTL_ADMISSION_DT;
        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;
        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Remove Updated records';

       /* IF OBJECT_ID('NBS_ODSE.DBO.SubjectRaceInfo_Modern') IS NULL
            select *
            into NBS_ODSE.DBO.SubjectRaceInfo_Modern
            from NBS_ODSE.DBO.SubjectRaceInfo;
		*/
        DELETE
        FROM NBS_ODSE.DBO.SubjectRaceInfo
        WHERE public_health_case_uid IN (
            SELECT public_health_case_uid
            FROM #TEMP_PHCINFO1
        );

        /*IF OBJECT_ID('NBS_ODSE.DBO.PublicHealthCaseFact_Modern') IS NULL
            select *
            into NBS_ODSE.DBO.PublicHealthCaseFact_Modern
            from NBS_ODSE.DBO.PublicHealthCaseFact;*/

        DELETE
        FROM NBS_ODSE.DBO.PublicHealthCaseFact
        WHERE public_health_case_uid IN (
            SELECT public_health_case_uid
            FROM #TEMP_PHCINFO1
        );

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_PHCINFO2';

        IF OBJECT_ID('#TEMP_PHCINFO2') IS NOT NULL
            DROP TABLE #TEMP_PHCINFO2;

        SELECT A.*
             ,NBS_CASE_ANSWER.ANSWER_TXT AS THERAPY_DATE
        INTO #TEMP_PHCINFO2
        FROM #TEMP_PHCINFO1 A WITH (NOLOCK)
                 LEFT OUTER JOIN NBS_ODSE.DBO.NBS_CASE_ANSWER WITH (NOLOCK) ON A.PUBLIC_HEALTH_CASE_UID = NBS_CASE_ANSWER.ACT_UID
            AND NBS_CASE_ANSWER.NBS_QUESTION_UID IN (
                SELECT NBS_QUESTION_UID
                FROM NBS_ODSE.DBO.NBS_QUESTION WITH (NOLOCK)
                WHERE QUESTION_IDENTIFIER = 'TUB170'
            );

        if @debug = 'true' Select '#TEMP_PHCINFO2', * from #TEMP_PHCINFO2;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@Proc_Step_no
               ,@Proc_Step_Name
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_PHCINFO3';

        IF OBJECT_ID('#TEMP_PHCINFO3') IS NOT NULL
            DROP TABLE #TEMP_PHCINFO3;

        SELECT A.*
             ,case when ltrim(rtrim(AID.ROOT_EXTENSION_TXT)) = '' then null else ltrim(rtrim(AID.ROOT_EXTENSION_TXT)) end  AS STATE_CASE_ID
        INTO #TEMP_PHCINFO3
        FROM #TEMP_PHCINFO2 A WITH (NOLOCK)
                 LEFT OUTER JOIN NBS_ODSE.DBO.ACT_ID AID WITH (NOLOCK) ON A.PUBLIC_HEALTH_CASE_UID = AID.ACT_UID
            AND ACT_ID_SEQ = 1
        WHERE A.RECORD_STATUS_CD <> 'LOG_DEL'
        ORDER BY A.PUBLIC_HEALTH_CASE_UID;

        if @debug = 'true' Select '#TEMP_PHCINFO3', * from #TEMP_PHCINFO3;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Update TEMP_PHCINFO3';

        /*UPDATE #TEMP_PHCINFO3
        SET STATE_CASE_ID = NULL
        WHERE STATE_CASE_ID = LTRIM(RTRIM(''));*/

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;



        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_PHCINFO';

        IF OBJECT_ID('#TEMP_PHCINFO') IS NOT NULL
            DROP TABLE #TEMP_PHCINFO;

        SELECT PUBLIC_HEALTH_CASE_UID
             ,CASE_TYPE_CD
             ,DIAGNOSIS_DATE
             ,PHC_CODE
             ,case when PHC_CODE_DESC = null then A.condition_short_nm  else PHC_CODE_DESC end as PHC_CODE_DESC
             ,CASE_CLASS_CD
             ,CD_SYSTEM_CD
             ,THERAPY_DATE
             ,STATE_CASE_ID
             ,CD_SYSTEM_DESC_TXT
             ,CONFIDENTIALITY_CD
             ,CONFIDENTIALITY_DESC_TXT
             ,DETECTION_METHOD_CD
             ,DISEASE_IMPORTED_CD
             ,GROUP_CASE_CNT
             ,INVESTIGATION_STATUS_CD
             ,JURISDICTION
             ,JURISDICTION_CD
             ,MMWR_WEEK
             ,MMWR_YEAR
             ,OUTBREAK_IND
             ,OUTBREAK_FROM_TIME
             ,OUTBREAK_TO_TIME
             ,OUTBREAK_NAME
             ,OUTCOME_CD
             ,PAT_AGE_AT_ONSET
             ,PAT_AGE_AT_ONSET_UNIT_CD
             ,t3.PROG_AREA_CD
             ,RECORD_STATUS_CD
             ,RPT_CNTY_CD
             ,RPT_FORM_CMPLT_TIME
             ,RPT_SOURCE_CD
             ,RPT_TO_COUNTY_TIME
             ,RPT_TO_STATE_TIME
             ,t3.STATUS_CD
             ,ONSETDATE
             ,INVESTIGATIONSTARTDATE
             ,PHC_ADD_TIME
             ,PROGRAM_JURISDICTION_OID
             ,SHARED_IND
             ,IMPORTED_COUNTRY_CODE
             ,IMPORTED_STATE_CODE
             ,IMPORTED_COUNTY_CODE
             ,INVESTIGATOR_ASSIGN_DATE
             ,HSPTL_ADMISSION_DT
             ,HSPTL_DISCHARGE_DT
             ,HOSPITALIZED_DURATION_AMT
             ,IMPORTED_CITY_DESC_TXT
             ,INVESTIGATION_DEATH_DATE
             ,LOCAL_ID
             ,HOSPITALIZED_IND
             ,DAY_CARE_IND_CD AS CASE_DAY_CARE_IND_CD
             ,PREGNANT_IND_CD
             ,LASTUPDATE
             ,case when ltrim(rtrim(PHCTXT))='' then null else ltrim(rtrim(PHCTXT)) end as PHCTXT
             ,A.CONDITION_CD
             ,A.investigation_form_cd
             ,A.condition_short_nm AS PHC_CODE_SHORT_DESC
             ,B.CODE_SHORT_DESC_TXT AS DISEASE_IMPORTED_DESC_TXT
             ,C.CODE_SHORT_DESC_TXT AS DETECTION_METHOD_DESC_TXT
             ,D.CODE_SHORT_DESC_TXT AS RPT_SOURCE_DESC_TXT
             ,E.CODE_SHORT_DESC_TXT AS HOSPITALIZED
             ,F.CODE_SHORT_DESC_TXT AS PREGNANT
             ,G.CODE_SHORT_DESC_TXT AS DAY_CARE_IND_CD
             ,H.CODE_SHORT_DESC_TXT AS FOOD_HANDLER_IND_CD
             ,I.CODE_SHORT_DESC_TXT AS IMPORTED_COUNTRY_CD
             ,J.CODE_SHORT_DESC_TXT AS IMPORTED_COUNTY_CD
             ,K.CODE_SHORT_DESC_TXT AS IMPORTED_STATE_CD
             ,L.CODE_SHORT_DESC_TXT AS CASE_CLASS_DESC_TXT
             ,M.CODE_SHORT_DESC_TXT AS investigation_status_desc_txt
             ,N.CODE_SHORT_DESC_TXT AS outcome_desc_txt
             ,O.CODE_SHORT_DESC_TXT AS pat_age_at_onset_unit_desc_txt
             ,P.prog_area_desc_txt AS prog_area_desc_txt
             ,Q.CODE_SHORT_DESC_TXT AS rpt_cnty_desc_txt
             ,R.CODE_SHORT_DESC_TXT AS outbreak_name_desc
             ,NOTIF_LAST_CHG_TIME
             , CASE WHEN (A.investigation_form_cd NOT LIKE 'PG_%' or A.investigation_form_cd  is null) then 1 else 0 end as FLAG2  /* Optimization (very imp) */
        INTO #TEMP_PHCINFO
        FROM #TEMP_PHCINFO3 t3
                 LEFT OUTER JOIN NBS_SRTE.DBO.CONDITION_CODE A WITH (NOLOCK) ON A.CONDITION_CD = t3.PHC_CODE
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA B WITH (NOLOCK) ON t3.DISEASE_IMPORTED_CD = B.CODE
            AND t3.investigation_form_cd = B.investigation_form_cd
            AND B.DATA_LOCATION LIKE '%.DISEASE_IMPORTED_CD'
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA C WITH (NOLOCK) ON t3.DETECTION_METHOD_CD = C.CODE
            AND t3.investigation_form_cd = C.investigation_form_cd
            AND C.DATA_LOCATION LIKE '%.DETECTION_METHOD_CD'
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA D WITH (NOLOCK) ON t3.RPT_SOURCE_CD = D.CODE
            AND t3.investigation_form_cd = D.investigation_form_cd
            AND D.DATA_LOCATION LIKE '%.RPT_SOURCE_CD'
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA E WITH (NOLOCK) ON t3.HOSPITALIZED_IND = E.CODE
            AND t3.investigation_form_cd = E.investigation_form_cd
            AND E.DATA_LOCATION LIKE '%.HOSPITALIZED_IND_CD'
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA F WITH (NOLOCK) ON t3.PREGNANT_IND_CD = F.CODE
            AND t3.investigation_form_cd = F.investigation_form_cd
            AND F.DATA_LOCATION LIKE '%.PREGNANT_IND_CD'
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA G WITH (NOLOCK) ON t3.DAY_CARE_IND_CD = G.CODE
            AND t3.investigation_form_cd = G.investigation_form_cd
            AND G.DATA_LOCATION LIKE '%.DAY_CARE_IND_CD'
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA H WITH (NOLOCK) ON t3.FOOD_HANDLER_IND_CD = H.CODE
            AND t3.investigation_form_cd = H.investigation_form_cd
            AND H.DATA_LOCATION LIKE '%.FOOD_HANDLER_IND_CD'
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA I WITH (NOLOCK) ON t3.IMPORTED_COUNTRY_CODE = I.CODE
            AND t3.investigation_form_cd = I.investigation_form_cd
            AND I.DATA_LOCATION LIKE '%.IMPORTED_COUNTRY_CD'
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA J WITH (NOLOCK) ON t3.IMPORTED_COUNTY_CODE = J.CODE
            AND t3.investigation_form_cd = J.investigation_form_cd
            AND J.DATA_LOCATION LIKE '%.IMPORTED_COUNTY_CD'
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA K WITH (NOLOCK) ON t3.IMPORTED_STATE_CODE = K.CODE
            AND t3.INVESTIGATION_FORM_CD = K.INVESTIGATION_FORM_CD
            AND K.DATA_LOCATION LIKE '%.IMPORTED_STATE_CD'
                 LEFT OUTER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL L WITH (NOLOCK) ON t3.CASE_CLASS_CD = L.CODE
            AND L.CODE_SET_NM = 'PHC_CLASS'
                 LEFT OUTER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL M WITH (NOLOCK) ON t3.INVESTIGATION_STATUS_CD = M.CODE
            AND M.CODE_SET_NM = 'PHC_IN_STS'
                 LEFT OUTER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL N WITH (NOLOCK) ON t3.OUTCOME_CD = N.CODE
            AND N.CODE_SET_NM = 'YNU'
                 LEFT OUTER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL O WITH (NOLOCK) ON t3.PAT_AGE_AT_ONSET_UNIT_CD = O.CODE
            AND O.CODE_SET_NM = 'AGE_UNIT'
                 LEFT OUTER JOIN NBS_SRTE.DBO.PROGRAM_AREA_CODE P WITH (NOLOCK) ON t3.PROG_AREA_CD = P.PROG_AREA_CD
            AND P.CODE_SET_NM = 'S_PROGRA_C'
                 LEFT OUTER JOIN NBS_SRTE.DBO.V_STATE_COUNTY_CODE_VALUE Q WITH (NOLOCK) ON t3.RPT_CNTY_CD = Q.CODE
            AND Q.CODE_SET_NM = 'COUNTY_CCD'
                 LEFT OUTER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL R WITH (NOLOCK) ON t3.OUTBREAK_NAME = R.CODE
            AND R.CODE_SET_NM = 'OUTBREAK_NM';

        if @debug = 'true' Select '##TEMP_PHCINFO', * from #TEMP_PHCINFO;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        /* -- Moved to SELECT SQL above
         UPDATE #TEMP_PHCINFO
        SET PHC_CODE_DESC = PHC_CODE_SHORT_DESC
        WHERE PHC_CODE_DESC IS NULL;*/


        UPDATE t
        SET DISEASE_IMPORTED_DESC_TXT = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCINFO t
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON t.DISEASE_IMPORTED_CD = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'PHC_IMPRT'
            AND FLAG2=1; /* Optimization */

        UPDATE t
        SET DETECTION_METHOD_DESC_TXT = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCINFO t
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON t.detection_method_cd = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'PHC_DET_MT'
            AND FLAG2=1; /* Optimization */

        UPDATE t
        SET RPT_SOURCE_DESC_TXT = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCINFO t
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON t.rpt_source_cd = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'PHC_RPT_SRC_T'
            AND FLAG2=1; /* Optimization */

        UPDATE t
        SET HOSPITALIZED = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCINFO t
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON t.HOSPITALIZED_IND = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'YNU'
            AND FLAG2=1; /* Optimization */

        UPDATE t
        SET PREGNANT = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCINFO t
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON t.pregnant_ind_cd = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'YNU'
            AND FLAG2=1; /* Optimization */

        UPDATE t
        SET DAY_CARE_IND_CD = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCINFO t
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON t.CASE_DAY_CARE_IND_CD = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'YNU'
            AND FLAG2=1; /* Optimization */

        UPDATE t
        SET FOOD_HANDLER_IND_CD = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCINFO t
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON t.FOOD_HANDLER_IND_CD = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'YNU'
            AND FLAG2=1; /* Optimization */

        UPDATE t
        SET DISEASE_IMPORTED_DESC_TXT = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCINFO t
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON t.DISEASE_IMPORTED_CD = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'PHC_IMPRT'
            AND FLAG2=1; /* Optimization */

        UPDATE t
        SET IMPORTED_COUNTRY_CD = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCINFO t
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON t.IMPORTED_COUNTRY_CODE = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'PSL_CNTRY'
            AND FLAG2=1; /* Optimization */

        UPDATE t
        SET IMPORTED_STATE_CD = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCINFO t
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON t.IMPORTED_STATE_CD = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'STATE_CCD'
            AND FLAG2=1; /* Optimization */

        UPDATE t
        SET IMPORTED_STATE_CD = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_PHCINFO t
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON t.IMPORTED_STATE_CD = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM = 'YNU'
            AND FLAG2=1; /* Optimization */


        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Cleanup process';



        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@Proc_Step_no
               ,@Proc_Step_Name
               ,0
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_PHCSUBJECT';

        IF OBJECT_ID('#TEMP_PHCSUBJECT') IS NOT NULL
            DROP TABLE #TEMP_PHCSUBJECT;

        SELECT --PUBLIC_HEALTH_CASE_UID,
            CASE_TYPE_CD
             ,DIAGNOSIS_DATE
             ,PHC_CODE
             ,PHC_CODE_DESC
             ,CASE_CLASS_CD
             ,CD_SYSTEM_CD
             ,THERAPY_DATE
             ,STATE_CASE_ID
             ,CD_SYSTEM_DESC_TXT
             ,CONFIDENTIALITY_CD
             ,CONFIDENTIALITY_DESC_TXT
             ,DETECTION_METHOD_CD
             ,HSPTL_ADMISSION_DT
             ,HSPTL_DISCHARGE_DT
             ,DISEASE_IMPORTED_CD
             ,GROUP_CASE_CNT
             ,INVESTIGATION_STATUS_CD
             ,JURISDICTION
             ,JURISDICTION_CD
             ,MMWR_WEEK
             ,MMWR_YEAR
             ,OUTBREAK_IND
             ,OUTBREAK_FROM_TIME
             ,OUTBREAK_TO_TIME
             ,OUTBREAK_NAME
             ,OUTCOME_CD
             ,PAT_AGE_AT_ONSET
             ,PAT_AGE_AT_ONSET_UNIT_CD
             ,PROG_AREA_CD
             ,RECORD_STATUS_CD
             ,RPT_CNTY_CD
             ,RPT_FORM_CMPLT_TIME
             ,RPT_SOURCE_CD
             ,RPT_TO_COUNTY_TIME
             ,RPT_TO_STATE_TIME
             ,STATUS_CD
             ,ONSETDATE
             ,INVESTIGATIONSTARTDATE
             ,PHC_ADD_TIME
             ,PROGRAM_JURISDICTION_OID
             ,SHARED_IND
             ,IMPORTED_COUNTRY_CODE
             ,IMPORTED_STATE_CODE
             ,IMPORTED_COUNTY_CODE
             ,INVESTIGATOR_ASSIGN_DATE
             ,HOSPITALIZED_DURATION_AMT
             ,IMPORTED_CITY_DESC_TXT
             ,INVESTIGATION_DEATH_DATE
             ,LOCAL_ID
             ,HOSPITALIZED_IND
             ,PREGNANT_IND_CD
             ,PHC_CODE_SHORT_DESC
             ,DISEASE_IMPORTED_DESC_TXT
             ,DETECTION_METHOD_DESC_TXT
             ,RPT_SOURCE_DESC_TXT
             ,HOSPITALIZED
             ,PREGNANT
             ,RPT_CNTY_DESC_TXT
             ,DAY_CARE_IND_CD
             ,FOOD_HANDLER_IND_CD
             ,IMPORTED_COUNTRY_CD
             ,IMPORTED_COUNTY_CD
             ,IMPORTED_STATE_CD
             ,CASE_CLASS_DESC_TXT
             ,INVESTIGATION_STATUS_DESC_TXT
             ,OUTCOME_DESC_TXT
             ,PAT_AGE_AT_ONSET_UNIT_DESC_TXT
             ,OUTBREAK_NAME_DESC
             ,LASTUPDATE
             ,PHCTXT
             ,PROG_AREA_DESC_TXT
             ,t.*
        INTO #TEMP_PHCSUBJECT
        FROM #TEMP_PHCINFO t1 WITH (NOLOCK)
                 INNER JOIN #TEMP_PHCPATIENTINFO t WITH (NOLOCK) ON t1.PUBLIC_HEALTH_CASE_UID = t.PUBLIC_HEALTH_CASE_UID
        ;
        if @debug = 'true' Select '###TEMP_PHCSUBJECT', * from #TEMP_PHCSUBJECT;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        -----------------------------------------SMMARY
        ----TODO NEEDS TO CHECK MERGE LOGIC
        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_SUMMARYUID';

        IF OBJECT_ID('#TEMP_SUMMARYUID') IS NOT NULL
            DROP TABLE #TEMP_SUMMARYUID;

        SELECT PHC.PUBLIC_HEALTH_CASE_UID
             ,SRT1.PARENT_IS_CD AS STATE_CD
             ,SRT2.CODE_DESC_TXT AS STATE
             ,PHC.RPT_CNTY_CD AS CNTY_CD
             ,SRT1.CODE_DESC_TXT AS COUNTY
        INTO #TEMP_SUMMARYUID
        FROM NBS_ODSE.DBO.PUBLIC_HEALTH_CASE PHC WITH (NOLOCK)
                 LEFT OUTER JOIN NBS_SRTE.DBO.STATE_COUNTY_CODE_VALUE SRT1 WITH (NOLOCK) ON PHC.RPT_CNTY_CD = SRT1.CODE
                 LEFT OUTER JOIN NBS_SRTE.DBO.STATE_CODE SRT2 WITH (NOLOCK) ON SRT1.PARENT_IS_CD = SRT2.STATE_CD
                 LEFT JOIN NBS_ODSE.DBO.ACT_RELATIONSHIP ARN WITH (NOLOCK) ON ARN.TARGET_ACT_UID=PHC.PUBLIC_HEALTH_CASE_UID
                 LEFT JOIN NBS_ODSE.DBO.NOTIFICATION WITH (NOLOCK) ON NOTIFICATION.NOTIFICATION_UID=ARN.SOURCE_ACT_UID
            AND NOTIFICATION.CD='NOTF'
        WHERE CASE_TYPE_CD IS NOT NULL
          AND CASE_TYPE_CD = 'S'
          and  PHC.public_health_case_uid in (select value from string_split(@phc_id_list, ','))

        /* AND (PHC.[last_chg_time] >= @batch_start_time
            AND PHC.[last_chg_time] < @batch_end_time)
        OR (NOTIFICATION.LAST_CHG_TIME >= @batch_start_time
            AND NOTIFICATION.LAST_CHG_TIME < @batch_end_time)	*/

        ORDER BY PUBLIC_HEALTH_CASE_UID;

        if @debug = 'true' Select '##TEMP_SUMMARYUID', * from #TEMP_SUMMARYUID;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_CASECNT';

        IF OBJECT_ID('#TEMP_CASECNT') IS NOT NULL
            DROP TABLE #TEMP_CASECNT;

        SELECT AR2.TARGET_ACT_UID AS PUBLIC_HEALTH_CASE_UID
             ,AR2.SOURCE_ACT_UID AS SUM_REPORT_FORM_UID
             ,AR1.TARGET_ACT_UID AS AR1_SUM_REPORT_FORM_UID
             ,
            /*--SUMMARY_REPORT_FORM OBS_UID*/
            AR1.SOURCE_ACT_UID AS AR1_SUM107_UID
             ,
            /*--SUM107 OBS_UID*/
            OB1.OBSERVATION_UID AS OB1_SUM107_UID
             ,OB1.CD AS OB1_CD
             ,OB2.OBSERVATION_UID AS OB2_SUM_REPORT_FORM_UID
             ,OB2.CD AS OB2_CD
             ,OVN.NUMERIC_VALUE_1 AS GROUP_CASE_CNT
             ,AR1.TYPE_CD AS AR1_TYPE_CD
             ,AR1.SOURCE_CLASS_CD AS AR1_SOURCE_CLASS_CD
             ,AR1.TARGET_CLASS_CD AS AR1_TARGET_CLASS_CD
             ,AR2.TYPE_CD AS AR2_TYPE_CD
             ,AR2.SOURCE_CLASS_CD AS AR2_SOURCE_CLASS_CD
             ,AR2.TARGET_CLASS_CD AS AR2_TARGET_CLASS_CD
        INTO #TEMP_CASECNT
        FROM NBS_ODSE.DBO.ACT_RELATIONSHIP AS AR1 WITH (NOLOCK)
           ,NBS_ODSE.DBO.OBSERVATION AS OB1 WITH (NOLOCK)
           ,NBS_ODSE.DBO.OBSERVATION AS OB2 WITH (NOLOCK)
           ,NBS_ODSE.DBO.OBS_VALUE_NUMERIC AS OVN WITH (NOLOCK)
           ,NBS_ODSE.DBO.ACT_RELATIONSHIP AS AR2 WITH (NOLOCK)
        WHERE AR1.SOURCE_ACT_UID = OB1.OBSERVATION_UID
          AND AR1.TARGET_ACT_UID = OB2.OBSERVATION_UID
          AND AR1.TYPE_CD = 'SUMMARYFRMQ'
          AND OB1.CD = 'SUM107'
          AND OB2.CD = 'SUMMARY_REPORT_FORM'
          AND OB1.OBSERVATION_UID = OVN.OBSERVATION_UID
          AND OB2.OBSERVATION_UID = AR2.SOURCE_ACT_UID
          AND AR2.TYPE_CD = 'SUMMARYFORM'
          and  AR2.TARGET_ACT_UID in (select value from string_split(@phc_id_list, ','))

        /*AND (AR1.[last_chg_time] >= @batch_start_time
            AND AR1.[last_chg_time] < @batch_end_time)*/

        ORDER BY PUBLIC_HEALTH_CASE_UID;

        if @debug = 'true' Select '###TEMP_CASECNT', * from #TEMP_CASECNT;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        ---TODO PENDING CODE LOGIC
        -----------------------NOTIFICATION
        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_SAS_LATEST_NOT';

        IF OBJECT_ID('#TEMP_SAS_LATEST_NOT') IS NOT NULL
            DROP TABLE #TEMP_SAS_LATEST_NOT;

        SELECT TARGET_ACT_UID AS PUBLIC_HEALTH_CASE_UID
             ,ar.SOURCE_ACT_UID
             ,SOURCE_CLASS_CD
             ,NF.RECORD_STATUS_CD AS NOTIFCURRENTSTATE
             , NF.txt
             ,NF.local_id AS NOTIFICATION_LOCAL_ID
        INTO #TEMP_SAS_LATEST_NOT
        FROM NBS_ODSE.DBO.ACT_RELATIONSHIP AR WITH (NOLOCK)
           ,NBS_ODSE.DBO.NOTIFICATION NF WITH (NOLOCK)
        WHERE AR.SOURCE_ACT_UID = NF.NOTIFICATION_UID
          AND SOURCE_CLASS_CD = 'NOTF'
          AND TARGET_CLASS_CD = 'CASE'
          AND (
            NF.RECORD_STATUS_CD = 'COMPLETED'
                OR NF.RECORD_STATUS_CD = 'PEND_APPR'
                OR NF.RECORD_STATUS_CD = 'APPROVED'
            )
          AND  AR.TARGET_ACT_UID IN (SELECT PUBLIC_HEALTH_CASE_UID  FROM #TEMP_PHCSUBJECT WITH (NOLOCK))
        /* AND ((NF.[last_chg_time] >= @batch_start_time
            AND NF.[last_chg_time] < @batch_end_time)
        OR  AR.TARGET_ACT_UID IN (SELECT PUBLIC_HEALTH_CASE_UID  FROM #TEMP_PHCSUBJECT WITH (NOLOCK))
        )*/

        COMMIT TRANSACTION;

        if @debug = 'true' Select '#TEMP_SAS_LATEST_NOT', * from #TEMP_SAS_LATEST_NOT;

        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_SAS_NOTIFICATION';

        IF OBJECT_ID('#TEMP_SAS_NOTIFICATION') IS NOT NULL
            DROP TABLE #TEMP_SAS_NOTIFICATION;

        SELECT DISTINCT TARGET_ACT_UID AS PUBLIC_HEALTH_CASE_UID
                      ,TARGET_CLASS_CD
                      ,SOURCE_ACT_UID
                      ,SOURCE_CLASS_CD
                      ,NF.VERSION_CTRL_NBR
                      ,NF.ADD_TIME
                      ,NF.ADD_USER_ID
                      ,NF.RPT_SENT_TIME
                      ,NF.RECORD_STATUS_CD
                      ,NF.RECORD_STATUS_TIME
                      ,NF.LAST_CHG_TIME
                      ,NF.LAST_CHG_USER_ID
                      ,'Y' AS HIST_IND
                      , NF.txt
                      ,CAST(NULL AS INT) AS NOTIFSENTCOUNT
                      ,CAST(NULL AS INT) AS NOTIFREJECTEDCOUNT
                      ,CAST(NULL AS INT) AS NOTIFCREATEDCOUNT
                      ,CAST(NULL AS INT) AS X1
                      ,CAST(NULL AS INT) AS X2
                      ,CAST(NULL AS DATETIME) AS FIRSTNOTIFICATIONSENDDATE
                      ,CAST(NULL AS DATETIME) AS NOTIFICATIONDATE
        INTO #TEMP_SAS_NOTIFICATION
        FROM NBS_ODSE.DBO.ACT_RELATIONSHIP AR WITH (NOLOCK)
                 INNER JOIN NBS_ODSE.DBO.NOTIFICATION_HIST NF WITH (NOLOCK) ON AR.SOURCE_ACT_UID = NF.NOTIFICATION_UID
        WHERE
            SOURCE_CLASS_CD = 'NOTF'
          AND TARGET_CLASS_CD = 'CASE'
          AND NF.CD='NOTF'
          AND (
            NF.RECORD_STATUS_CD = 'COMPLETED'
                OR NF.RECORD_STATUS_CD = 'MSG_FAIL'
                OR NF.RECORD_STATUS_CD = 'REJECTED'
                OR NF.RECORD_STATUS_CD = 'PEND_APPR'
                OR NF.RECORD_STATUS_CD = 'APPROVED'
            )
          and AR.TARGET_ACT_UID IN (SELECT PUBLIC_HEALTH_CASE_UID FROM #TEMP_PHCSUBJECT WITH (NOLOCK))
        /*AND ((NF.[last_chg_time] >= @batch_start_time
        AND NF.[last_chg_time] < @batch_end_time)
        OR AR.TARGET_ACT_UID IN (SELECT PUBLIC_HEALTH_CASE_UID FROM #TEMP_PHCSUBJECT WITH (NOLOCK))
        )*/

        UNION

        SELECT TARGET_ACT_UID
             ,TARGET_CLASS_CD
             ,SOURCE_ACT_UID
             ,SOURCE_CLASS_CD
             ,NF.VERSION_CTRL_NBR
             ,NF.ADD_TIME
             ,NF.ADD_USER_ID
             ,NF.RPT_SENT_TIME
             ,NF.RECORD_STATUS_CD
             ,NF.RECORD_STATUS_TIME
             ,NF.LAST_CHG_TIME
             ,NF.LAST_CHG_USER_ID
             ,'N' AS HIST_IND
             , NULL AS TXT
             ,CAST(NULL AS INT) AS NOTIFSENTCOUNT
             ,CAST(NULL AS INT) AS NOTIFREJECTEDCOUNT
             ,CAST(NULL AS INT) AS NOTIFCREATEDCOUNT
             ,CAST(NULL AS INT) AS X1
             ,CAST(NULL AS INT) AS X2
             ,CAST(NULL AS DATETIME) AS FIRSTNOTIFICATIONSENDDATE
             ,CAST(NULL AS DATETIME) AS NOTIFICATIONDATE
        FROM NBS_ODSE.DBO.ACT_RELATIONSHIP AR WITH (NOLOCK)
           ,NBS_ODSE.DBO.NOTIFICATION NF WITH (NOLOCK)
        WHERE AR.SOURCE_ACT_UID = NF.NOTIFICATION_UID
          AND SOURCE_CLASS_CD = 'NOTF'
          AND TARGET_CLASS_CD = 'CASE'
          AND NF.CD='NOTF'
          AND (
            NF.RECORD_STATUS_CD = 'COMPLETED'
                OR NF.RECORD_STATUS_CD = 'MSG_FAIL'
                OR NF.RECORD_STATUS_CD = 'REJECTED'
                OR NF.RECORD_STATUS_CD = 'PEND_APPR'
                OR NF.RECORD_STATUS_CD = 'APPROVED'
            )
          and AR.TARGET_ACT_UID IN (SELECT PUBLIC_HEALTH_CASE_UID FROM #TEMP_PHCSUBJECT WITH (NOLOCK))
        /*
    AND ((NF.[last_chg_time] >= @batch_start_time
    AND NF.[last_chg_time] < @batch_end_time)
    OR AR.TARGET_ACT_UID IN (SELECT PUBLIC_HEALTH_CASE_UID FROM #TEMP_PHCSUBJECT WITH (NOLOCK)))
    */
        ORDER BY TARGET_ACT_UID
               ,LAST_CHG_TIME;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_PHCFACT';

        IF OBJECT_ID('#TEMP_PHCFACT') IS NOT NULL
            DROP TABLE #TEMP_PHCFACT;

        SELECT t.*
             ,TARGET_CLASS_CD
             ,tn.SOURCE_ACT_UID
             ,tn.SOURCE_CLASS_CD
             ,VERSION_CTRL_NBR
             ,ADD_TIME
             ,ADD_USER_ID
             ,RPT_SENT_TIME
             ,RECORD_STATUS_CD
             ,RECORD_STATUS_TIME
             ,LAST_CHG_TIME
             ,LAST_CHG_USER_ID
             ,HIST_IND
             ,NOTIFSENTCOUNT
             ,NOTIFCREATEDCOUNT
             ,FIRSTNOTIFICATIONSENDDATE
             ,NOTIFICATIONDATE
        INTO #TEMP_PHCFACT
        FROM #TEMP_CASECNT t WITH (NOLOCK)
                 LEFT JOIN #TEMP_SAS_NOTIFICATION tn WITH (NOLOCK) ON tn.PUBLIC_HEALTH_CASE_UID = t.PUBLIC_HEALTH_CASE_UID;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_MIN_MAX_NOTIFICATION';

        IF OBJECT_ID('#TEMP_MIN_MAX_NOTIFICATION') IS NOT NULL
            DROP TABLE #TEMP_MIN_MAX_NOTIFICATION;

        SELECT DISTINCT MIN(CASE
            WHEN VERSION_CTRL_NBR = 1
                THEN RECORD_STATUS_CD
            END) AS FIRSTNOTIFICATIONSTATUS
                      ,

            SUM(CASE
                WHEN RECORD_STATUS_CD = 'REJECTED'
                    THEN 1
                ELSE 0
                END) NOTIFREJECTEDCOUNT
                      ,SUM(CASE
            WHEN RECORD_STATUS_CD = 'APPROVED'
                OR RECORD_STATUS_CD = 'PEND_APPR'
                THEN 1
            WHEN RECORD_STATUS_CD = 'REJECTED'
                THEN -1
            ELSE 0
            END) NOTIFCREATEDCOUNT
                      ,SUM(CASE
            WHEN RECORD_STATUS_CD = 'COMPLETED'
                THEN 1
            ELSE 0
            END) NOTIFSENTCOUNT
                      ,MIN(CASE
            WHEN RECORD_STATUS_CD = 'COMPLETED'
                THEN RPT_SENT_TIME
            END) AS FIRSTNOTIFICATIONSENDDATE
                      ,
            SUM(CASE
                WHEN RECORD_STATUS_CD = 'PEND_APPR'
                    THEN 1
                ELSE 0
                END) NOTIFCREATEDPENDINGSCOUNT
                      ,MAX(CASE
            WHEN RECORD_STATUS_CD = 'APPROVED'
                OR RECORD_STATUS_CD = 'PEND_APPR'
                THEN LAST_CHG_TIME
            END) AS LASTNOTIFICATIONDATE
                      ,
                      --DONE?
            MAX(CASE
                WHEN RECORD_STATUS_CD = 'COMPLETED'
                    THEN RPT_SENT_TIME
                END) AS LASTNOTIFICATIONSENDDATE
                      ,
                      --DONE?
            MIN(ADD_TIME) AS FIRSTNOTIFICATIONDATE
                      ,
                      --DONE
            MIN(ADD_USER_ID) AS FIRSTNOTIFICATIONSUBMITTEDBY
                      ,
                      --DONE
            MIN(ADD_USER_ID) AS LASTNOTIFICATIONSUBMITTEDBY
                      --DONE
                      --MIN(CASE WHEN RECORD_STATUS_CD='COMPLETED' THEN  LAST_CHG_USER_ID END) AS FIRSTNOTIFICATIONSUBMITTEDBY,
                      ,MIN(CASE
            WHEN RECORD_STATUS_CD = 'COMPLETED'
                AND RPT_SENT_TIME IS NOT NULL
                THEN RPT_SENT_TIME
            END) AS NOTIFICATIONDATE
                      ,PUBLIC_HEALTH_CASE_UID
        INTO #TEMP_MIN_MAX_NOTIFICATION
        FROM #TEMP_SAS_NOTIFICATION WITH (NOLOCK)
        GROUP BY PUBLIC_HEALTH_CASE_UID;

        UPDATE #TEMP_MIN_MAX_NOTIFICATION set NOTIFCREATEDCOUNT = NOTIFCREATEDCOUNT-1 where NOTIFCREATEDPENDINGSCOUNT>0 and NOTIFCREATEDCOUNT>0;
        UPDATE #TEMP_MIN_MAX_NOTIFICATION set NOTIFCREATEDCOUNT = 1 where NOTIFCREATEDPENDINGSCOUNT>0 and NOTIFCREATEDCOUNT=0 and NOTIFREJECTEDCOUNT=0;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@Proc_Step_no
               ,@Proc_Step_Name
               ,0
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_SUB_CASE_NOTIF';

        IF OBJECT_ID('#TEMP_SUB_CASE_NOTIF') IS NOT NULL
            DROP TABLE #TEMP_SUB_CASE_NOTIF;

        SELECT DISTINCT ts.*
                      ,NOTIFCREATEDCOUNT
                      ,NOTIFSENTCOUNT
                      ,NOTIFICATIONDATE
                      ,FIRSTNOTIFICATIONSTATUS
                      ,FIRSTNOTIFICATIONSENDDATE
                      ,LASTNOTIFICATIONDATE
                      ,LASTNOTIFICATIONSENDDATE
                      ,FIRSTNOTIFICATIONDATE
                      ,FIRSTNOTIFICATIONSUBMITTEDBY
                      ,LASTNOTIFICATIONSUBMITTEDBY
                      ,t.TXT AS NOTITXT
                      ,t.NOTIFICATION_LOCAL_ID
                      ,t.NOTIFCURRENTSTATE
                      ,ROWN = ROW_NUMBER() OVER (
            PARTITION BY ts.PUBLIC_HEALTH_CASE_UID ORDER BY ts.PUBLIC_HEALTH_CASE_UID
            )
        INTO #TEMP_SUB_CASE_NOTIF
        FROM #TEMP_PHCSUBJECT ts WITH (NOLOCK)
                 LEFT JOIN #TEMP_MIN_MAX_NOTIFICATION tn WITH (NOLOCK) ON tn.PUBLIC_HEALTH_CASE_UID = ts.PUBLIC_HEALTH_CASE_UID
                 LEFT JOIN #TEMP_SAS_LATEST_NOT  t WITH (NOLOCK) ON t.PUBLIC_HEALTH_CASE_UID = ts.PUBLIC_HEALTH_CASE_UID;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        DELETE
        FROM #TEMP_SUB_CASE_NOTIF
        WHERE ROWN > 1
        --IF OBJECT_ID ('TEMP_PHCFACT') IS NOT NULL DROP TABLE TEMP_PHCFACT;
        --IF OBJECT_ID ('TEMP_MIN_MAX_NOTIFICATION') IS NOT NULL DROP TABLE TEMP_MIN_MAX_NOTIFICATION;
        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_CONFIRM';

        IF OBJECT_ID('#TEMP_CONFIRM') IS NOT NULL
            DROP TABLE #TEMP_CONFIRM;

        SELECT CONFIRMATION_METHOD.PUBLIC_HEALTH_CASE_UID
             ,A.CONFIRMATION_METHOD_TIME
             ,CONFIRMATION_METHOD_CD
             ,tc.CODE_SHORT_DESC_TXT AS CONFIRMATION_METHOD_DESC_TXT
             ,tc.investigation_form_cd
        INTO #TEMP_CONFIRM
        FROM (
                 SELECT CONFIRMATION_METHOD.PUBLIC_HEALTH_CASE_UID
                      ,MAX(CONFIRMATION_METHOD_TIME) AS CONFIRMATION_METHOD_TIME
                 FROM NBS_ODSE.DBO.CONFIRMATION_METHOD WITH (NOLOCK)
                 GROUP BY CONFIRMATION_METHOD.PUBLIC_HEALTH_CASE_UID
             ) A
                 INNER JOIN #TEMP_PHCINFO t WITH (NOLOCK) ON t.PUBLIC_HEALTH_CASE_UID = A.PUBLIC_HEALTH_CASE_UID
                 INNER JOIN NBS_ODSE.DBO.CONFIRMATION_METHOD WITH (NOLOCK) ON A.PUBLIC_HEALTH_CASE_UID = CONFIRMATION_METHOD.PUBLIC_HEALTH_CASE_UID
                 LEFT OUTER JOIN #TEMP_INV_FORM_CODE_DATA  tc WITH (NOLOCK) ON CONFIRMATION_METHOD.CONFIRMATION_METHOD_CD = tc.CODE
            AND  tc.investigation_form_cd = t.investigation_form_cd
            AND tc.CODE_SET_NM= 'PHC_CONF_M'
        GROUP BY CONFIRMATION_METHOD.PUBLIC_HEALTH_CASE_UID
               ,CONFIRMATION_METHOD_CD
               ,A.CONFIRMATION_METHOD_TIME
               ,CONFIRMATION_METHOD_DESC_TXT
               ,tc.CODE_SHORT_DESC_TXT
               ,tc.investigation_form_cd;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        UPDATE t
        SET CONFIRMATION_METHOD_DESC_TXT = CODE_VALUE_GENERAL.CODE_SHORT_DESC_TXT
        FROM #TEMP_CONFIRM t
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL WITH (NOLOCK) ON t.CONFIRMATION_METHOD_CD = CODE_VALUE_GENERAL.CODE
            AND CODE_SET_NM= 'PHC_CONF_M'
        where t.INVESTIGATION_FORM_CD NOT LIKE 'PG_%' or INVESTIGATION_FORM_CD is null

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_CONFIRM_CONCAT';

        IF OBJECT_ID('#TEMP_CONFIRM_CONCAT') IS NOT NULL
            DROP TABLE #TEMP_CONFIRM_CONCAT;

        SELECT DISTINCT PUBLIC_HEALTH_CASE_UID
                      ,CONFIRMATION_METHOD_TIME = (
            SELECT TOP 1 CONFIRMATION_METHOD_TIME
            FROM #TEMP_CONFIRM WITH (NOLOCK)
            WHERE PUBLIC_HEALTH_CASE_UID = T.PUBLIC_HEALTH_CASE_UID
        )
                      ,CONFIRMATION_METHOD_DESC_TXT = STUFF((
                                                                SELECT ', ' + CONFIRMATION_METHOD_DESC_TXT
                                                                FROM #TEMP_CONFIRM WITH (NOLOCK)
                                                                WHERE PUBLIC_HEALTH_CASE_UID = T.PUBLIC_HEALTH_CASE_UID
                                                                FOR XML PATH('')
                                                            ), 1, 1, '')
                      ,CONFIRMATION_METHOD_CD = STUFF((
                                                          SELECT ', ' + CONFIRMATION_METHOD_CD
                                                          FROM #TEMP_CONFIRM WITH (NOLOCK)
                                                          WHERE PUBLIC_HEALTH_CASE_UID = T.PUBLIC_HEALTH_CASE_UID
                                                          FOR XML PATH('')
                                                      ), 1, 1, '')
        INTO #TEMP_CONFIRM_CONCAT
        FROM #TEMP_CONFIRM AS T;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_SUB_CASE_CONF_NOTIF';

        IF OBJECT_ID('#TEMP_SUB_CASE_CONF_NOTIF') IS NOT NULL
            DROP TABLE #TEMP_SUB_CASE_CONF_NOTIF;

        SELECT t.*
             ,CONFIRMATION_METHOD_TIME
             ,CONFIRMATION_METHOD_CD
             ,CONFIRMATION_METHOD_DESC_TXT
        INTO #TEMP_SUB_CASE_CONF_NOTIF
        FROM #TEMP_SUB_CASE_NOTIF t WITH (NOLOCK)
                 LEFT OUTER JOIN #TEMP_CONFIRM_CONCAT tc WITH (NOLOCK) ON t.PUBLIC_HEALTH_CASE_UID = tc.PUBLIC_HEALTH_CASE_UID;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        ----------------------PHCREPORTER
        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_PHCREPORTER';

        IF OBJECT_ID('#TEMP_PHCREPORTER') IS NOT NULL
            DROP TABLE #TEMP_PHCREPORTER;

        SELECT PAR.ACT_UID
             ,PNM.PERSON_UID AS ENTITY_UID
             ,TYPE_CD
             ,TEL.PHONE_NBR_TXT
             ,PAR.FROM_TIME
             ,NAME
        INTO #TEMP_PHCREPORTER
        FROM NBS_ODSE.DBO.PARTICIPATION AS PAR WITH (NOLOCK)
                 INNER JOIN #TEMP_PHCINFO t on t.public_health_CASE_UID  =PAR.ACT_UID
                 INNER JOIN NBS_ODSE.DBO.PERSON  AS P WITH (NOLOCK) ON P.PERSON_UID = PAR.SUBJECT_ENTITY_UID
                 LEFT JOIN (
                 	select PERSON_UID, NAME, isnull(RECORD_STATUS_CD, 'ACTIVE') as RECORD_STATUS_CD, NM_USE_CD
                 	from (
						select PERSON_UID, isnull(RTRIM(LTRIM(LAST_NM)), '') + ', ' + isnull(FIRST_NM, '') AS NAME, NM_USE_CD,
						RECORD_STATUS_CD, LAST_CHG_TIME ,  ROW_NUMBER() OVER(partition by PERSON_UID ORDER BY last_chg_time desc ) AS rnum
						from NBS_ODSE.DBO.PERSON_NAME WITH (NOLOCK) ) t
					where rnum=1 ) PNM  ON PNM.PERSON_UID = PAR.SUBJECT_ENTITY_UID
            AND PNM.NM_USE_CD = 'L'
            AND PNM.RECORD_STATUS_CD = 'ACTIVE'
                 LEFT JOIN NBS_ODSE.DBO.ENTITY_LOCATOR_PARTICIPATION AS ELP WITH (NOLOCK) ON ELP.ENTITY_UID = PAR.SUBJECT_ENTITY_UID
            AND ELP.CLASS_CD = 'TELE'
            AND ELP.USE_CD = 'WP' /*WORK PLACE*/
            AND ELP.CD = 'PH' /*PHONE*/
            AND ELP.RECORD_STATUS_CD = 'ACTIVE'
                 LEFT JOIN NBS_ODSE.DBO.TELE_LOCATOR AS TEL WITH (NOLOCK) ON ELP.LOCATOR_UID = TEL.TELE_LOCATOR_UID
        /*AND (TEL.RECORD_STATUS_CD IS NOT NULL AND TEL.RECORD_STATUS_CD ='ACTIVE')*/
        WHERE (
                  PAR.TYPE_CD IN (
                                  'OrgAsReporterOfPHC'
                      ,'InvestgrOfPHC'
                      ,'PerAsReporterOfPHC'
                      ,'PhysicianOfPHC'
                      )
                  )
        UNION

        SELECT PAR2.ACT_UID
             ,ORG.ORGANIZATION_UID AS ENTITY_UID
             ,TYPE_CD
             ,' ' AS PHONE_NBR_TXT
             ,PAR2.FROM_TIME
             ,ORG.NM_TXT AS NAME
        FROM NBS_ODSE.DBO.PARTICIPATION AS PAR2 WITH (NOLOCK)
                 INNER JOIN #TEMP_PHCINFO t on t.public_health_CASE_UID  =PAR2.ACT_UID
                 INNER JOIN NBS_ODSE.DBO.ORGANIZATION_NAME AS ORG WITH (NOLOCK) ON ORG.ORGANIZATION_UID =  PAR2.SUBJECT_ENTITY_UID
                 INNER JOIN NBS_ODSE.DBO.ORGANIZATION WITH (NOLOCK) ON ORGANIZATION.ORGANIZATION_UID = ORG.ORGANIZATION_UID
        WHERE  PAR2.RECORD_STATUS_CD = 'ACTIVE'
          AND PAR2.TYPE_CD = 'OrgAsReporterOfPHC'
          AND LTRIM(RTRIM(NM_TXT)) <> ''
        /*AND (ORGANIZATION.[last_chg_time] >= @batch_start_time
        AND ORGANIZATION.[last_chg_time] < @batch_end_time)
        OR( t.LASTUPDATE >= @batch_start_time
            AND t.LASTUPDATE < @batch_end_time)
        OR (NOTIF_LAST_CHG_TIME >= @batch_start_time
            AND NOTIF_LAST_CHG_TIME < @batch_end_time)	*/
        ORDER BY ACT_UID
               ,TYPE_CD;


        if @debug = 'true' Select '##TEMP_PHCREPORTER', * from #TEMP_PHCREPORTER;

        IF OBJECT_ID('#TEMP_ENTITY') IS NOT NULL
            DROP TABLE #TEMP_ENTITY;

        SELECT ACT_UID
             ,PROVIDERNAME = MAX(CASE
            WHEN TYPE_CD = 'PhysicianOfPHC'
                THEN NAME
            END)
             ,PROVIDERPHONE = MAX(CASE
            WHEN TYPE_CD = 'PhysicianOfPHC'
                THEN PHONE_NBR_TXT
            END)
             ,REPORTERNAME = MAX(CASE
            WHEN TYPE_CD = 'PerAsReporterOfPHC'
                THEN NAME
            END)
             ,REPORTERPHONE = MAX(CASE
            WHEN TYPE_CD = 'PerAsReporterOfPHC'
                THEN PHONE_NBR_TXT
            END)
             ,INVESTIGATORNAME = MAX(CASE
            WHEN TYPE_CD = 'InvestgrOfPHC'
                THEN NAME
            END)
             ,INVESTIGATORPHONE = MAX(CASE
            WHEN TYPE_CD = 'InvestgrOfPHC'
                THEN PHONE_NBR_TXT
            END)
             ,INVESTIGATORASSIGNEDDATE = MAX(CASE
            WHEN TYPE_CD = 'InvestgrOfPHC'
                THEN FROM_TIME
            END)
             ,ORGANIZATIONNAME = MAX(CASE
            WHEN TYPE_CD = 'OrgAsReporterOfPHC'
                THEN NAME
            END)
        INTO #TEMP_ENTITY
        FROM #TEMP_PHCREPORTER WITH (NOLOCK)
        GROUP BY ACT_UID

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_CASE_ENTITY';

        IF OBJECT_ID('#TEMP_CASE_ENTITY') IS NOT NULL
            DROP TABLE #TEMP_CASE_ENTITY;

        SELECT tn.*
             ,te.PROVIDERNAME
             ,te.PROVIDERPHONE
             ,te.REPORTERNAME
             ,te.REPORTERPHONE
             ,te.INVESTIGATORNAME
             ,te.INVESTIGATORPHONE
             ,te.INVESTIGATORASSIGNEDDATE
             ,te.ORGANIZATIONNAME
        INTO #TEMP_CASE_ENTITY
        FROM #TEMP_SUB_CASE_CONF_NOTIF tn WITH (NOLOCK)
                 LEFT OUTER JOIN #TEMP_ENTITY te WITH (NOLOCK) ON tn.PUBLIC_HEALTH_CASE_UID = te.ACT_UID;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        -------------------------PHCPERSONRACE
        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_PHCPERSONRACE';

        IF OBJECT_ID('#TEMP_PHCPERSONRACE') IS NOT NULL
            DROP TABLE #TEMP_PHCPERSONRACE;

        SELECT DISTINCT PER.PERSON_UID
                      ,PER.RACE_CATEGORY_CD
                      ,CODE_SHORT_DESC_TXT AS RACE_DESC_TXT
        INTO #TEMP_PHCPERSONRACE
        FROM NBS_ODSE.DBO.PERSON_RACE AS PER WITH (NOLOCK)
           ,NBS_SRTE.DBO.RACE_CODE AS RAC WITH (NOLOCK)
           ,#TEMP_UPDATE_NEW_PATIENT t WITH (NOLOCK)
        WHERE PER.RACE_CD = PER.RACE_CATEGORY_CD /*CONCATENATE ONLY CATEGORY CD AND DESC*/
          AND t.PERSON_UID=PER.PERSON_UID
          AND PER.RACE_CD = RAC.CODE
          AND RAC.PARENT_IS_CD = 'ROOT'
          AND RAC.CODE_SET_NM = 'P_RACE_CAT'
        UNION

        SELECT DISTINCT PER.PERSON_UID
                      ,PER.RACE_CATEGORY_CD
                      ,CODE_SHORT_DESC_TXT AS RACE_DESC_TXT
        --INTO TEMP_RACE1
        FROM NBS_ODSE.DBO.PERSON_RACE AS PER WITH (NOLOCK)
           ,NBS_SRTE.DBO.RACE_CODE AS RAC WITH (NOLOCK)
           ,#TEMP_UPDATE_NEW_PATIENT t WITH (NOLOCK)
        WHERE PER.RACE_CD = 'ROOT'
          AND t.PERSON_UID=PER.PERSON_UID
          AND PER.RACE_CATEGORY_CD = RAC.CODE

        IF OBJECT_ID('#TEMP_PHCPERSONRACE_CONCAT') IS NOT NULL
            DROP TABLE #TEMP_PHCPERSONRACE_CONCAT;

        SELECT DISTINCT PERSON_UID
                      ,RACE_CONCATENATED_DESC_TXT = STUFF((
                                                              SELECT ', ' + RACE_DESC_TXT
                                                              FROM #TEMP_PHCPERSONRACE WITH (NOLOCK)
                                                              WHERE PERSON_UID = T.PERSON_UID
                                                              FOR XML PATH('')
                                                          ), 1, 1, '')
                      ,RACE_CONCATENATED_TXT = STUFF((
                                                         SELECT ', ' + RACE_CATEGORY_CD
                                                         FROM #TEMP_PHCPERSONRACE WITH (NOLOCK)
                                                         WHERE PERSON_UID = T.PERSON_UID
                                                         FOR XML PATH('')
                                                     ), 1, 1, '')
        INTO #TEMP_PHCPERSONRACE_CONCAT
        FROM #TEMP_PHCPERSONRACE AS T;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating TEMP_PHC_FACT';

        IF OBJECT_ID('#TEMP_PHC_FACT') IS NOT NULL
            DROP TABLE #TEMP_PHC_FACT;

        SELECT te.*
             ,RACE_CONCATENATED_DESC_TXT
             ,RACE_CONCATENATED_TXT
             ,cast(null  as varchar(20)) EVENT_TYPE
             ,cast(null as datetime)  EVENT_DATE
             ,cast(null as datetime)  REPORT_DATE
             ,cast(null as datetime)  MART_RECORD_CREATION_TIME
        INTO #TEMP_PHC_FACT
        FROM #TEMP_CASE_ENTITY te
                 LEFT OUTER JOIN #TEMP_PHCPERSONRACE_CONCAT tc WITH (NOLOCK) ON te.PERSON_UID = tc.PERSON_UID;

        if @debug = 'true' Select 'Final##TEMP_PHC_FACT', * from #TEMP_PHC_FACT;
        ----------------------
        -- Moved this column above SQL
        -- ALTER TABLE #TEMP_PHC_FACT ADD EVENT_TYPE VARCHAR(20);

        -- ALTER TABLE #TEMP_PHC_FACT ADD EVENT_DATE DATETIME;

        -- ALTER TABLE #TEMP_PHC_FACT ADD REPORT_DATE DATETIME;

        -- ALTER TABLE #TEMP_PHC_FACT ADD MART_RECORD_CREATION_TIME DATETIME;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@Proc_Step_no
               ,@Proc_Step_Name
               ,0
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Updating TEMP_PHC_FACT';

        UPDATE #TEMP_PHC_FACT
        SET EVENT_TYPE = (
            CASE
                WHEN ONSETDATE IS NOT NULL
                    THEN 'O'
                WHEN ONSETDATE IS NULL
                    AND DIAGNOSIS_DATE IS NOT NULL
                    THEN 'D'
                WHEN ONSETDATE IS NULL
                    AND DIAGNOSIS_DATE IS NULL
                    AND RPT_TO_COUNTY_TIME IS NOT NULL
                    THEN 'C'
                WHEN ONSETDATE IS NULL
                    AND DIAGNOSIS_DATE IS NULL
                    AND RPT_TO_COUNTY_TIME IS NULL
                    AND RPT_TO_STATE_TIME IS NOT NULL
                    THEN 'S'
                WHEN PHC_CODE IN ('10220')
                    AND THERAPY_DATE IS NOT NULL
                    THEN 'RVCT_DTS'
                WHEN PHC_CODE IN ('10220')
                    AND THERAPY_DATE IS NULL
                    AND RPT_FORM_CMPLT_TIME IS NOT NULL
                    THEN 'RVCT_DR'
                ELSE 'P'
                END
            )
          ,EVENT_DATE = (
            CASE
                WHEN ONSETDATE IS NOT NULL
                    THEN ONSETDATE
                WHEN ONSETDATE IS NULL
                    AND DIAGNOSIS_DATE IS NOT NULL
                    THEN DIAGNOSIS_DATE
                WHEN ONSETDATE IS NULL
                    AND DIAGNOSIS_DATE IS NULL
                    AND RPT_TO_COUNTY_TIME IS NOT NULL
                    THEN RPT_TO_COUNTY_TIME
                WHEN ONSETDATE IS NULL
                    AND DIAGNOSIS_DATE IS NULL
                    AND RPT_TO_COUNTY_TIME IS NULL
                    AND RPT_TO_STATE_TIME IS NOT NULL
                    THEN RPT_TO_STATE_TIME
                WHEN PHC_CODE IN ('10220')
                    AND THERAPY_DATE IS NOT NULL
                    THEN THERAPY_DATE
                WHEN PHC_CODE IN ('10220')
                    AND THERAPY_DATE IS NULL
                    AND RPT_FORM_CMPLT_TIME IS NOT NULL
                    THEN RPT_FORM_CMPLT_TIME
                ELSE PHC_ADD_TIME
                END
            )
          ,REPORT_DATE = (
            CASE
                WHEN RPT_TO_COUNTY_TIME is not null
                    THEN RPT_TO_COUNTY_TIME
                WHEN RPT_TO_STATE_TIME IS NOT NULL AND RPT_TO_COUNTY_TIME IS NULL
                    THEN RPT_TO_STATE_TIME
                ELSE PHC_ADD_TIME
                END
            )
          ,DECEASED_TIME = (
            CASE
                WHEN PHC_CODE IN (
                                  '10220'
                    ,'10030'
                    )
                    THEN INVESTIGATION_DEATH_DATE
                ELSE DECEASED_TIME
                END
            )
          ,INVESTIGATORASSIGNEDDATE = (
            CASE
                WHEN PHC_CODE IN (
                                  '10220'
                    ,'10030'
                    )
                    THEN INVESTIGATOR_ASSIGN_DATE
                ELSE INVESTIGATORASSIGNEDDATE
                END
            )
          ,MART_RECORD_CREATION_TIME = getDate();;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        -- the below 4 update's are already covered in the above sql
        -- so commenting the below 4 sql
        -- UPDATE #TEMP_PHC_FACT SET EVENT_DATE = THERAPY_DATE WHERE PHC_CODE ='10220' and THERAPY_DATE is not null ;
        -- UPDATE #TEMP_PHC_FACT SET EVENT_DATE = rpt_form_cmplt_time WHERE PHC_CODE ='10220' and THERAPY_DATE is null and rpt_form_cmplt_time is not null;
        -- UPDATE #TEMP_PHC_FACT SET EVENT_TYPE = 'RVCT_DTS' WHERE PHC_CODE ='10220' and THERAPY_DATE is not null ;
        -- UPDATE #TEMP_PHC_FACT SET EVENT_TYPE = 'RVCT_DR' WHERE PHC_CODE ='10220' and THERAPY_DATE is null and rpt_form_cmplt_time is not null;

        -- below sql are now in the corresponding select clause
        -- UPDATE #TEMP_PHC_FACT SET State_cd = NULL WHERE State_cd = LTRIM(RTRIM(''));
        -- UPDATE #TEMP_PHC_FACT SET phctxt = NULL WHERE phctxt = LTRIM(RTRIM(''));
        -- UPDATE #TEMP_PHC_FACT SET cntry_cd = NULL WHERE cntry_cd = LTRIM(RTRIM(''));


        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Cleanup temp tables';
/*
		IF OBJECT_ID('#TEMP_UPDATE_NEW_PATIENT') IS NOT NULL
			DROP TABLE #TEMP_UPDATE_NEW_PATIENT;

		IF OBJECT_ID('#TEMP_PHCINFO1') IS NOT NULL
			DROP TABLE #TEMP_PHCINFO1;

		IF OBJECT_ID('#TEMP_PHCINFO2') IS NOT NULL
			DROP TABLE #TEMP_PHCINFO2;

		IF OBJECT_ID('#TEMP_PHCINFO3') IS NOT NULL
			DROP TABLE #TEMP_PHCINFO3;

		IF OBJECT_ID('#TEMP_INV_FORM_CODE_DATA') IS NOT NULL
			DROP TABLE #TEMP_INV_FORM_CODE_DATA;

		IF OBJECT_ID('#TEMP_PHCPATIENTINFO') IS NOT NULL
			DROP TABLE #TEMP_PHCPATIENTINFO;

		IF OBJECT_ID('#TEMP_PHCSUBJECT') IS NOT NULL
			DROP TABLE #TEMP_PHCSUBJECT;

		IF OBJECT_ID('#TEMP_PHCINFO') IS NOT NULL
			DROP TABLE #TEMP_PHCINFO;

		IF OBJECT_ID('#TEMP_SUMMARYUID') IS NOT NULL
			DROP TABLE #TEMP_SUMMARYUID;

		IF OBJECT_ID('#TEMP_CASECNT') IS NOT NULL
			DROP TABLE #TEMP_CASECNT;
		IF OBJECT_ID('#TEMP_SAS_LATEST_NOT') IS NOT NULL
			DROP TABLE #TEMP_SAS_LATEST_NOT;

		IF OBJECT_ID('#TEMP_SAS_NOTIFICATION') IS NOT NULL
			DROP TABLE #TEMP_SAS_NOTIFICATION;

		IF OBJECT_ID('#TEMP_CASECNT') IS NOT NULL
			DROP TABLE #TEMP_CASECNT;

		IF OBJECT_ID('#TEMP_MIN_MAX_NOTIFICATION') IS NOT NULL
			DROP TABLE #TEMP_MIN_MAX_NOTIFICATION;

		IF OBJECT_ID('#TEMP_PHCFACT') IS NOT NULL
			DROP TABLE #TEMP_PHCFACT;

		IF OBJECT_ID('#TEMP_SUB_CASE_NOTIF') IS NOT NULL
			DROP TABLE #TEMP_SUB_CASE_NOTIF;

		IF OBJECT_ID('#TEMP_CONFIRM') IS NOT NULL
			DROP TABLE #TEMP_CONFIRM;

		IF OBJECT_ID('#TEMP_PHCREPORTER') IS NOT NULL
			DROP TABLE #TEMP_PHCREPORTER;

		IF OBJECT_ID('#TEMP_ENTITY') IS NOT NULL
			DROP TABLE #TEMP_ENTITY;

		IF OBJECT_ID('#TEMP_CASE_ENTITY') IS NOT NULL
			DROP TABLE #TEMP_CASE_ENTITY;

		IF OBJECT_ID('#TEMP_PHCPERSONRACE') IS NOT NULL
			DROP TABLE #TEMP_PHCPERSONRACE;

		IF OBJECT_ID('#TEMP_PHCPERSONRACE_CONCAT') IS NOT NULL
			DROP TABLE #TEMP_PHCPERSONRACE_CONCAT;
*/
        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'STEP-AVOIDED'
               ,@Proc_Step_no
               ,@Proc_Step_Name
               ,0
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Updating PublicHealthCaseFact';

        INSERT INTO NBS_ODSE.DBO.PublicHealthCaseFact (
                                                        PUBLIC_HEALTH_CASE_UID
                                                      ,ADULTS_IN_HOUSE_NBR
                                                      ,HSPTL_ADMISSION_DT
                                                      ,HSPTL_DISCHARGE_DT
                                                      ,AGE_CATEGORY_CD
                                                      ,AGE_REPORTED_TIME
                                                      ,AGE_REPORTED_UNIT_CD
                                                      ,AGE_REPORTED
                                                      ,AWARENESS_CD
                                                      ,AWARENESS_DESC_TXT
                                                      ,BIRTH_GENDER_CD
                                                      ,BIRTH_ORDER_NBR
                                                      ,BIRTH_TIME
                                                      ,BIRTH_TIME_CALC
                                                      ,
            --,BIRTH_TIME_STD
                                                        CASE_CLASS_CD
                                                      ,CASE_TYPE_CD
                                                      ,CD_SYSTEM_CD
                                                      ,CD_SYSTEM_DESC_TXT
                                                      ,CENSUS_BLOCK_CD
                                                      ,CENSUS_MINOR_CIVIL_DIVISION_CD
                                                      ,CENSUS_TRACK_CD
                                                      ,
            --,CNTY_CODE_DESC_TXT
                                                        CHILDREN_IN_HOUSE_NBR
                                                      ,CITY_CD
                                                      ,CITY_DESC_TXT
                                                      ,CONFIDENTIALITY_CD
                                                      ,CONFIDENTIALITY_DESC_TXT
                                                      ,CONFIRMATION_METHOD_CD
                                                      ,CONFIRMATION_METHOD_TIME
                                                      ,COUNTY
                                                      ,CNTRY_CD
                                                      ,CNTY_CD
                                                      ,CURR_SEX_CD
                                                      ,DECEASED_IND_CD
                                                      ,DECEASED_TIME
                                                      ,DETECTION_METHOD_CD
                                                      ,DETECTION_METHOD_DESC_TXT
                                                      ,DIAGNOSIS_DATE
                                                      ,DISEASE_IMPORTED_CD
                                                      ,DISEASE_IMPORTED_DESC_TXT
                                                      ,EDUCATION_LEVEL_CD
                                                      ,ELP_CLASS_CD
                                                      ,ELP_FROM_TIME
                                                      ,ELP_TO_TIME
                                                      ,ETHNIC_GROUP_IND
                                                      ,ETHNIC_GROUP_IND_DESC
                                                      ,EVENT_DATE
                                                      ,EVENT_TYPE
                                                      ,EDUCATION_LEVEL_DESC_TXT
                                                      ,FIRSTNOTIFICATIONSENDDATE
                                                      ,FIRSTNOTIFICATIONDATE
                                                      ,FIRSTNOTIFICATIONSTATUS
                                                      ,FIRSTNOTIFICATIONSUBMITTEDBY
                                                      ,
            --,GEOLATITUDE
            --,GEOLONGITUDE
                                                        GROUP_CASE_CNT
                                                      ,INVESTIGATION_STATUS_CD
                                                      ,INVESTIGATORASSIGNEDDATE
                                                      ,INVESTIGATORNAME
                                                      ,INVESTIGATORPHONE
                                                      ,JURISDICTION_CD
                                                      ,LASTNOTIFICATIONDATE
                                                      ,LASTNOTIFICATIONSENDDATE
                                                      ,LASTNOTIFICATIONSUBMITTEDBY
                                                      ,MARITAL_STATUS_CD
                                                      ,MARITAL_STATUS_DESC_TXT
                                                      ,
            --,MART_RECORD_CREATION_DATE
                                                        MART_RECORD_CREATION_TIME
                                                      ,MMWR_WEEK
                                                      ,MMWR_YEAR
                                                      ,MSA_CONGRESS_DISTRICT_CD
                                                      ,MULTIPLE_BIRTH_IND
                                                      ,NOTIFCREATEDCOUNT
                                                      ,NOTIFICATIONDATE
                                                      ,NOTIFSENTCOUNT
                                                      ,OCCUPATION_CD
                                                      ,ONSETDATE
                                                      ,ORGANIZATIONNAME
                                                      ,OUTCOME_CD
                                                      ,OUTBREAK_FROM_TIME
                                                      ,OUTBREAK_IND
                                                      ,OUTBREAK_NAME
                                                      ,OUTBREAK_TO_TIME
                                                      ,PAR_TYPE_CD
                                                      ,PAT_AGE_AT_ONSET
                                                      ,PAT_AGE_AT_ONSET_UNIT_CD
                                                      ,POSTAL_LOCATOR_UID
                                                      ,PERSON_CD
                                                      ,PERSON_CODE_DESC
                                                      ,PERSON_UID
                                                      ,PHC_ADD_TIME
                                                      ,PHC_CODE
                                                      ,PHC_CODE_DESC
                                                      ,PHC_CODE_SHORT_DESC
                                                      ,PRIM_LANG_CD
                                                      ,PRIM_LANG_DESC_TXT
                                                      ,PROG_AREA_CD
                                                      ,PROVIDERPHONE
                                                      ,PROVIDERNAME
                                                      ,PST_RECORD_STATUS_TIME
                                                      ,PST_RECORD_STATUS_CD
                                                      ,RACE_CONCATENATED_TXT
                                                      ,RACE_CONCATENATED_DESC_TXT
                                                      ,REGION_DISTRICT_CD
                                                      ,RECORD_STATUS_CD
                                                      ,REPORTERNAME
                                                      ,REPORTERPHONE
                                                      ,RPT_CNTY_CD
                                                      ,RPT_FORM_CMPLT_TIME
                                                      ,RPT_SOURCE_CD
                                                      ,RPT_SOURCE_DESC_TXT
                                                      ,RPT_TO_COUNTY_TIME
                                                      ,RPT_TO_STATE_TIME
                                                      ,SHARED_IND
                                                      ,STATE
                                                      ,STATE_CD
                                                      ,
            --,STATE_CODE_SHORT_DESC_TXT
                                                        STATUS_CD
                                                      ,STREET_ADDR1
                                                      ,STREET_ADDR2
                                                      ,ELP_USE_CD
                                                      ,ZIP_CD
                                                      ,PATIENTNAME
                                                      ,JURISDICTION
                                                      ,INVESTIGATIONSTARTDATE
                                                      ,PROGRAM_JURISDICTION_OID
                                                      ,REPORT_DATE
                                                      ,PERSON_PARENT_UID
                                                      ,PERSON_LOCAL_ID
                                                      ,SUB_ADDR_AS_OF_DATE
                                                      ,STATE_CASE_ID
                                                      ,LOCAL_ID
                                                      ,AGE_REPORTED_UNIT_DESC_TXT
                                                      ,BIRTH_GENDER_DESC_TXT
                                                      ,CASE_CLASS_DESC_TXT
                                                      ,CNTRY_DESC_TXT
                                                      ,CURR_SEX_DESC_TXT
                                                      ,INVESTIGATION_STATUS_DESC_TXT
                                                      ,OCCUPATION_DESC_TXT
                                                      ,OUTCOME_DESC_TXT
                                                      ,PAT_AGE_AT_ONSET_UNIT_DESC_TXT
                                                      ,PROG_AREA_DESC_TXT
                                                      ,RPT_CNTY_DESC_TXT
                                                      ,OUTBREAK_NAME_DESC
                                                      ,CONFIRMATION_METHOD_DESC_TXT
                                                      ,LASTUPDATE
                                                      ,PHCTXT
                                                      ,NOTITXT
                                                      ,NOTIFICATION_LOCAL_ID
                                                      ,NOTIFCURRENTSTATE
                                                      ,HOSPITALIZED_IND
        ) (
            SELECT PUBLIC_HEALTH_CASE_UID
                 ,ADULTS_IN_HOUSE_NBR
                 ,HSPTL_ADMISSION_DT
                 ,HSPTL_DISCHARGE_DT
                 ,AGE_CATEGORY_CD
                 ,AGE_REPORTED_TIME
                 ,AGE_REPORTED_UNIT_CD
                 ,CONVERT(NUMERIC, substring(RTRIM(LTRIM(AGE_REPORTED)), 1, 3))
                 ,AWARENESS_CD
                 ,AWARENESS_DESC_TXT
                 ,BIRTH_GENDER_CD
                 ,BIRTH_ORDER_NBR
                 ,BIRTH_TIME
                 ,BIRTH_TIME_CALC
                 ,
                 --,BIRTH_TIME_STD
                CASE_CLASS_CD
                 ,CASE_TYPE_CD
                 ,CD_SYSTEM_CD
                 ,CD_SYSTEM_DESC_TXT
                 ,CENSUS_BLOCK_CD
                 ,CENSUS_MINOR_CIVIL_DIVISION_CD
                 ,CENSUS_TRACK_CD
                 ,
                 --,CNTY_CODE_DESC_TXT
                CHILDREN_IN_HOUSE_NBR
                 ,CITY_CD
                 ,CITY_DESC_TXT
                 ,CONFIDENTIALITY_CD
                 ,CONFIDENTIALITY_DESC_TXT
                 ,substring(RTRIM(LTRIM(CONFIRMATION_METHOD_CD)), 1, 300)
                 ,CONFIRMATION_METHOD_TIME
                 ,COUNTY
                 ,CNTRY_CD
                 ,CNTY_CD
                 ,CURR_SEX_CD
                 ,DECEASED_IND_CD
                 ,DECEASED_TIME
                 ,DETECTION_METHOD_CD
                 ,DETECTION_METHOD_DESC_TXT
                 ,DIAGNOSIS_DATE
                 ,DISEASE_IMPORTED_CD
                 ,DISEASE_IMPORTED_DESC_TXT
                 ,EDUCATION_LEVEL_CD
                 ,ELP_CLASS_CD
                 ,ELP_FROM_TIME
                 ,ELP_TO_TIME
                 ,ETHNIC_GROUP_IND
                 ,RTRIM(LTRIM(substring(ETHNIC_GROUP_IND_DESC, 1, 50)))
                 ,EVENT_DATE
                 ,substring(EVENT_TYPE, 1, 10)
                 ,EDUCATION_LEVEL_DESC_TXT
                 ,FIRSTNOTIFICATIONSENDDATE
                 ,FIRSTNOTIFICATIONDATE
                 ,FIRSTNOTIFICATIONSTATUS
                 ,FIRSTNOTIFICATIONSUBMITTEDBY
                 ,
                 --,GEOLATITUDE
                 --,GEOLONGITUDE
                GROUP_CASE_CNT
                 ,INVESTIGATION_STATUS_CD
                 ,INVESTIGATORASSIGNEDDATE
                 ,INVESTIGATORNAME
                 ,INVESTIGATORPHONE
                 ,JURISDICTION_CD
                 ,LASTNOTIFICATIONDATE
                 ,LASTNOTIFICATIONSENDDATE
                 ,LASTNOTIFICATIONSUBMITTEDBY
                 ,MARITAL_STATUS_CD
                 ,MARITAL_STATUS_DESC_TXT
                 ,
                 --,MART_RECORD_CREATION_DATE
                MART_RECORD_CREATION_TIME
                 ,MMWR_WEEK
                 ,MMWR_YEAR
                 ,MSA_CONGRESS_DISTRICT_CD
                 ,MULTIPLE_BIRTH_IND
                 ,NOTIFCREATEDCOUNT
                 ,NOTIFICATIONDATE
                 ,NOTIFSENTCOUNT
                 ,OCCUPATION_CD
                 ,ONSETDATE
                 ,ORGANIZATIONNAME
                 ,OUTCOME_CD
                 ,OUTBREAK_FROM_TIME
                 ,OUTBREAK_IND
                 ,OUTBREAK_NAME
                 ,OUTBREAK_TO_TIME
                 ,PAR_TYPE_CD
                 ,PAT_AGE_AT_ONSET
                 ,PAT_AGE_AT_ONSET_UNIT_CD
                 ,POSTAL_LOCATOR_UID
                 ,PERSON_CD
                 ,PERSON_CODE_DESC
                 ,PERSON_UID
                 ,PHC_ADD_TIME
                 ,PHC_CODE
                 ,PHC_CODE_DESC
                 ,substring(PHC_CODE_SHORT_DESC, 1, 50)
                 ,PRIM_LANG_CD
                 ,PRIM_LANG_DESC_TXT
                 ,PROG_AREA_CD
                 ,PROVIDERPHONE
                 ,PROVIDERNAME
                 ,PST_RECORD_STATUS_TIME
                 ,PST_RECORD_STATUS_CD
                 ,substring(RTRIM(LTRIM(RACE_CONCATENATED_TXT)), 1, 100)
                 ,substring(RTRIM(LTRIM(RACE_CONCATENATED_DESC_TXT)), 1, 500)
                 ,REGION_DISTRICT_CD
                 ,RECORD_STATUS_CD
                 ,REPORTERNAME
                 ,REPORTERPHONE
                 ,RPT_CNTY_CD
                 ,RPT_FORM_CMPLT_TIME
                 ,RPT_SOURCE_CD
                 ,RPT_SOURCE_DESC_TXT
                 ,RPT_TO_COUNTY_TIME
                 ,RPT_TO_STATE_TIME
                 ,SHARED_IND
                 ,STATE
                 ,STATE_CD
                 ,
                 --,STATE_CODE_SHORT_DESC_TXT
                STATUS_CD
                 ,STREET_ADDR1
                 ,STREET_ADDR2
                 ,ELP_USE_CD
                 ,ZIP_CD
                 ,RTRIM(LTRIM(PATIENTNAME))
                 ,substring(JURISDICTION, 1, 50)
                 ,INVESTIGATIONSTARTDATE
                 ,PROGRAM_JURISDICTION_OID
                 ,REPORT_DATE
                 ,PERSON_PARENT_UID
                 ,PERSON_LOCAL_ID
                 ,SUB_ADDR_AS_OF_DATE
                 ,STATE_CASE_ID
                 ,LOCAL_ID
                 ,AGE_REPORTED_UNIT_DESC_TXT
                 ,BIRTH_GENDER_DESC_TXT
                 ,CASE_CLASS_DESC_TXT
                 ,CNTRY_DESC_TXT
                 ,CURR_SEX_DESC_TXT
                 ,INVESTIGATION_STATUS_DESC_TXT
                 ,OCCUPATION_DESC_TXT
                 ,OUTCOME_DESC_TXT
                 ,PAT_AGE_AT_ONSET_UNIT_DESC_TXT
                 ,PROG_AREA_DESC_TXT
                 ,RPT_CNTY_DESC_TXT
                 ,OUTBREAK_NAME_DESC
                 ,CONFIRMATION_METHOD_DESC_TXT
                 ,LASTUPDATE
                 ,PHCTXT
                 ,NOTITXT
                 ,NOTIFICATION_LOCAL_ID
                 ,NOTIFCURRENTSTATE
                 ,HOSPITALIZED_IND
            FROM #TEMP_PHC_FACT WITH (NOLOCK)
        );

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@PROC_STEP_NO
               ,@PROC_STEP_NAME
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Updating SubjectRaceInfo';

        INSERT INTO NBS_ODSE.DBO.SubjectRaceInfo (
                                                   PUBLIC_HEALTH_CASE_UID
                                                 ,MORBREPORT_UID
                                                 ,RACE_CD
                                                 ,RACE_CATEGORY_CD
                                                 ,RACE_DESC_TXT
        ) (
            SELECT PUBLIC_HEALTH_CASE_UID
                 ,0 AS MORBREPORT_UID
                 ,RACE_CD
                 ,RACE_CATEGORY_CD
                 ,RACE_DESC_TXT FROM NBS_ODSE.DBO.PERSON_RACE AS PR WITH (NOLOCK)
                                   ,#TEMP_PHC_FACT AS PF WITH (NOLOCK) WHERE PR.PERSON_UID = PF.PERSON_UID
        );
        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        IF OBJECT_ID('#TEMP_PHC_FACT') IS NOT NULL
            DROP TABLE #TEMP_PHC_FACT;

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @Batch_id
               ,'PCHMartETL'
               ,'NBS_ODSE.PublicHealthCaseFact RTR'
               ,'COMPLETED'
               ,@Proc_Step_no
               ,@Proc_Step_Name
               ,@ROWCOUNT_NO
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
        )
        VALUES (
                 @batch_id
               ,'PCHMartETL'
               ,'PCHMartETL'
               ,'COMPLETE'
               ,@Proc_Step_no
               ,@Proc_Step_name
               ,@RowCount_no
               );

        COMMIT TRANSACTION;

        --EXEC rdb.[dbo].[sp_nbs_batch_complete] @type_code;

        Select 'SUCCESS'
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO rdb.[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[Error_Description]
                                                      ,[row_count]
                                                      ,[Msg_Description1]
        )
        VALUES (
                 @batch_id
               ,'PCHMartETL'
               ,'PCHMartETL'
               ,'ERROR'
               ,@Proc_Step_no
               , @Proc_Step_name
               ,@FullErrorMessage
               ,0
               , LEFT(@phc_id_list, 199)
               );

        RETURN @FullErrorMessage;
    END CATCH
END;