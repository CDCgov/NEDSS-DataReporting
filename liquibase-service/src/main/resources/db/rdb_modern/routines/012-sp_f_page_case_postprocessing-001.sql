CREATE OR ALTER PROCEDURE dbo.sp_f_page_case_postprocessing
    @phc_ids nvarchar(max),
    @debug bit = 'false'
AS

BEGIN
    DECLARE @RowCount_no INT ;
    DECLARE @Proc_Step_no FLOAT = 0 ;
    DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyyyMMddHHmmss')) as bigint);

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';


        BEGIN TRANSACTION;

        INSERT INTO [dbo].[job_flow_log] (
                                           batch_id
                                         ,[Dataflow_Name]
                                         ,[package_Name]
                                         ,[Status_Type]
                                         ,[step_number]
                                         ,[step_name]
                                         ,[row_count]
                                         ,[Msg_Description1]
        )
        VALUES
            (
              @batch_id
            ,'F_PAGE_CASE'
            ,'F_PAGE_CASE'
            ,'START'
            ,@Proc_Step_no
            ,@Proc_Step_Name
            ,0
            ,LEFT('ID List-' + @phc_ids,500)
            );

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;


        SET @Proc_Step_no = 2;
        SET @Proc_Step_Name = ' Generating PHC_UIDS_ALL';

        ---> PHC_UIDS
        SELECT inv.public_health_case_uid page_case_uid,
               CASE_MANAGEMENT_UID,
               INVESTIGATION_FORM_CD,
               CD,
               LAST_CHG_TIME
        INTO #PHC_UIDS
        FROM dbo.nrt_investigation inv
        WHERE inv.public_health_case_uid IN (SELECT value FROM STRING_SPLIT(@phc_ids, ','))
          AND INVESTIGATION_FORM_CD  NOT IN ( 'INV_FORM_BMDGAS','INV_FORM_BMDGBS','INV_FORM_BMDGEN',
                                              'INV_FORM_BMDNM','INV_FORM_BMDSP','INV_FORM_GEN','INV_FORM_HEPA','INV_FORM_HEPBV','INV_FORM_HEPCV',
                                              'INV_FORM_HEPGEN','INV_FORM_MEA','INV_FORM_PER','INV_FORM_RUB','INV_FORM_RVCT','INV_FORM_VAR')
        AND CASE_MANAGEMENT_UID is null;

        if @debug  = 'true' select * from #PHC_UIDS;



        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES(@batch_id,'F_PAGE_CASE','F_PAGE_CASE','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = 3;
        SET @Proc_Step_Name = ' Generating PHC_CASE_UIDS_ALL';

        IF OBJECT_ID('#PHC_CASE_UIDS_ALL', 'U') IS NOT NULL
            drop table #PHC_CASE_UIDS_ALL
            ;


        SELECT
            inv.PUBLIC_HEALTH_CASE_UID  'PAGE_CASE_UID', /* VS LENGTH =8 AS PAGE_CASE_UID 'PAGE_CASE_UID',*/
            CASE_MANAGEMENT_UID,
            INVESTIGATION_FORM_CD,
            CD,
            LAST_CHG_TIME
        INTO  #PHC_CASE_UIDS_ALL
        FROM
            dbo.nrt_investigation inv
        --LEFT OUTER JOIN NBS_ODSE.dbo.CASE_MANAGEMENT ON	inv.PUBLIC_HEALTH_CASE_UID= CASE_MANAGEMENT.PUBLIC_HEALTH_CASE_UID
        --LEFT OUTER JOIN NBS_SRTE.dbo.CONDITION_CODE ON 	CONDITION_CODE.CONDITION_CD= inv.CD AND
        where inv.public_health_case_uid IN (SELECT value FROM STRING_SPLIT(@phc_ids, ','))
          and INVESTIGATION_FORM_CD  NOT IN 	( 'bo.','INV_FORM_BMDGBS','INV_FORM_BMDGEN','INV_FORM_BMDNM','INV_FORM_BMDSP','INV_FORM_GEN','INV_FORM_HEPA','INV_FORM_HEPBV','INV_FORM_HEPCV','INV_FORM_HEPGEN','INV_FORM_MEA','INV_FORM_PER','INV_FORM_RUB','INV_FORM_RVCT','INV_FORM_VAR')
          AND CASE_MANAGEMENT_UID is null;

        if @debug  = 'true' select * from #PHC_CASE_UIDS_ALL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES(@batch_id,'F_PAGE_CASE','F_PAGE_CASE','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = 4;
        SET @Proc_Step_Name = ' Generating ENTITY_KEYSTORE_INC';

        IF OBJECT_ID('#ENTITY_KEYSTORE_INC', 'U') IS NOT NULL
            drop table #ENTITY_KEYSTORE_INC
            ;

        -- drop table dbo.F_S_INV_CASE

        IF OBJECT_ID('#F_S_INV_CASE', 'U') IS NOT NULL
            drop table #F_S_INV_CASE;

        -- Populate dbo.F_S_INV_CASE


        SELECT public_health_case_uid AS PAGE_CASE_UID,
               nac_last_chg_time as last_chg_time,
               nac_add_time as add_time,
               investigator_id as INVESTIGATOR_uid,
               person_as_reporter_uid as PERSON_AS_REPORTER_UID,
               patient_id as patient_uid,
               physician_id as PHYSICIAN_UID,
               hospital_uid as HOSPITAL_UID,
               organization_id as ORG_AS_REPORTER_UID,
               ordering_facility_uid as ORDERING_FACILTY_UID
        INTO #F_S_INV_CASE
        FROM dbo.nrt_investigation inv WHERE public_health_case_uid
                                                 IN (SELECT PAGE_CASE_UID FROM #PHC_UIDS WHERE CASE_MANAGEMENT_UID IS NULL);

        if @debug  = 'true' select * from #F_S_INV_CASE;


        SELECT
            FSIV.ADD_TIME,
            FSIV.LAST_CHG_TIME,
            FSIV.PATIENT_UID,
            COALESCE(PATIENT.PATIENT_KEY, 1)  AS PATIENT_KEY,
            FSIV.PAGE_CASE_UID,
            FSIV.HOSPITAL_UID,
            COALESCE(HOSPITAL.ORGANIZATION_KEY, 1)  AS HOSPITAL_KEY,
            FSIV.ORG_AS_REPORTER_UID,
            COALESCE(REPORTERORG.ORGANIZATION_KEY, 1)  AS ORG_AS_REPORTER_KEY,
            FSIV.PERSON_AS_REPORTER_UID,
            COALESCE(PERSONREPORTER.PROVIDER_KEY, 1)  AS PERSON_AS_REPORTER_KEY,
            FSIV.PHYSICIAN_UID,
            COALESCE(PHYSICIAN.PROVIDER_KEY, 1)  AS PHYSICIAN_KEY,
            FSIV.INVESTIGATOR_UID,
            COALESCE(PROVIDER.PROVIDER_KEY, 1)  AS INVESTIGATOR_KEY,
            COALESCE(INVESTIGATION.INVESTIGATION_KEY,1 ) AS INVESTIGATION_KEY,
            COALESCE(CONDITION.CONDITION_KEY,1)  AS CONDITION_KEY,
            COALESCE(LOC.GEOCODING_LOCATION_KEY, 1) AS GEOCODING_LOCATION_KEY
        --'' as TEMP
        into #ENTITY_KEYSTORE_INC
        FROM #F_S_INV_CASE  FSIV
                 LEFT OUTER JOIN dbo.D_PATIENT PATIENT	 ON	FSIV.PATIENT_UID= PATIENT.PATIENT_UID
                 LEFT OUTER JOIN dbo.D_ORGANIZATION  HOSPITAL ON 	FSIV.HOSPITAL_UID= HOSPITAL.ORGANIZATION_UID
                 LEFT OUTER JOIN dbo.D_ORGANIZATION REPORTERORG ON 	FSIV.ORG_AS_REPORTER_UID= REPORTERORG.ORGANIZATION_UID
                 LEFT OUTER JOIN dbo.D_PROVIDER PERSONREPORTER ON  	FSIV.PERSON_AS_REPORTER_UID= PERSONREPORTER.PROVIDER_UID
                 LEFT OUTER JOIN dbo.D_PROVIDER PROVIDER ON 	FSIV.INVESTIGATOR_UID= PROVIDER.PROVIDER_UID
                 LEFT OUTER JOIN dbo.D_PROVIDER PHYSICIAN ON 	FSIV.PHYSICIAN_UID= PHYSICIAN.PROVIDER_UID
                 LEFT OUTER JOIN dbo.INVESTIGATION  INVESTIGATION ON 	FSIV.PAGE_CASE_UID= INVESTIGATION.CASE_UID
                 LEFT OUTER JOIN #PHC_CASE_UIDS_ALL  CASE_UID ON 	FSIV.PAGE_CASE_UID= CASE_UID.PAGE_CASE_UID
                 LEFT OUTER JOIN dbo.CONDITION CONDITION ON 	CASE_UID.CD= CONDITION.CONDITION_CD
                 LEFT JOIN dbo.GEOCODING_LOCATION AS LOC ON LOC.ENTITY_UID = PATIENT.PATIENT_UID
        ;

        if @debug  = 'true' select * from #ENTITY_KEYSTORE_INC;
        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES(@batch_id,'F_PAGE_CASE','F_PAGE_CASE','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = 5;
        SET @Proc_Step_Name = ' Generating DIMENSION_KEYS_PAGECASEID';

        IF OBJECT_ID('#DIMENSION_KEYS_PAGECASEID', 'U') IS NOT NULL
            drop table #DIMENSION_KEYS_PAGECASEID
            ;

        with LOOKUPCTE as (
            select L_INV_ADMINISTRATIVE.PAGE_CASE_UID 	 from  dbo.L_INV_ADMINISTRATIVE  union
            select L_INV_CLINICAL.PAGE_CASE_UID 	 from  dbo.L_INV_CLINICAL  union
            select L_INV_COMPLICATION.PAGE_CASE_UID 	 from  dbo.L_INV_COMPLICATION  union
            select L_INV_CONTACT.PAGE_CASE_UID 	 from  dbo.L_INV_CONTACT  union
            select L_INV_DEATH.PAGE_CASE_UID 	 from  dbo.L_INV_DEATH  union
            select L_INV_EPIDEMIOLOGY.PAGE_CASE_UID 	 from  dbo.L_INV_EPIDEMIOLOGY  union
            select L_INV_HIV.PAGE_CASE_UID 	 from  dbo.L_INV_HIV  union
            select L_INV_ISOLATE_TRACKING.PAGE_CASE_UID 	 from  dbo.L_INV_ISOLATE_TRACKING  union
            select L_INV_LAB_FINDING.PAGE_CASE_UID 	 from  dbo.L_INV_LAB_FINDING  union
            select L_INV_MEDICAL_HISTORY.PAGE_CASE_UID 	 from  dbo.L_INV_MEDICAL_HISTORY  union
            select L_INV_MOTHER.PAGE_CASE_UID 	 from  dbo.L_INV_MOTHER  union
            select L_INV_OTHER.PAGE_CASE_UID 	 from  dbo.L_INV_OTHER  union
            select L_INV_PATIENT_OBS.PAGE_CASE_UID 	 from  dbo.L_INV_PATIENT_OBS  union
            select L_INV_PREGNANCY_BIRTH.PAGE_CASE_UID 	 from  dbo.L_INV_PREGNANCY_BIRTH  union
            select L_INV_RESIDENCY.PAGE_CASE_UID 	 from  dbo.L_INV_RESIDENCY  union
            select L_INV_RISK_FACTOR.PAGE_CASE_UID 	 from  dbo.L_INV_RISK_FACTOR  union
            select L_INV_SOCIAL_HISTORY.PAGE_CASE_UID 	 from  dbo.L_INV_SOCIAL_HISTORY  union
            select L_INV_SYMPTOM.PAGE_CASE_UID 	 from  dbo.L_INV_SYMPTOM  union
            select L_INV_TRAVEL.PAGE_CASE_UID 	 from  dbo.L_INV_TRAVEL  union
            select L_INV_TREATMENT.PAGE_CASE_UID 	 from  dbo.L_INV_TREATMENT  union
            select L_INV_UNDER_CONDITION.PAGE_CASE_UID 	 from  dbo.L_INV_UNDER_CONDITION  union
            select L_INV_VACCINATION.PAGE_CASE_UID 	 from  dbo.L_INV_VACCINATION union
            SELECT L_INVESTIGATION_REPEAT.PAGE_CASE_UID	 from  dbo.L_INVESTIGATION_REPEAT union
            SELECT L_INV_PLACE_REPEAT.PAGE_CASE_UID	 from  dbo.L_INV_PLACE_REPEAT
        )
        select cte.*
        into #DIMENSION_KEYS_PAGECASEID
        from LOOKUPCTE cte
         INNER JOIN #ENTITY_KEYSTORE_INC keystore --joining with this table in advance to reduce the rows
                    ON cte.PAGE_CASE_UID = keystore.PAGE_CASE_UID
        ;

        if @debug  = 'true' select * from #DIMENSION_KEYS_PAGECASEID where page_case_uid IN (SELECT value FROM STRING_SPLIT(@phc_ids, ','));


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES(@batch_id,'F_PAGE_CASE','F_PAGE_CASE','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = 6;
        SET @Proc_Step_Name = ' Generating DIMENSIONAL_KEYS';

        IF OBJECT_ID('#DIMENSIONAL_KEYS', 'U') IS NOT NULL
            drop table #DIMENSIONAL_KEYS
            ;

        /**Updated to handle cases when there are no page builder investigation updates.*/
        select  phc.page_case_uid,
                COALESCE(L_INV_ADMINISTRATIVE.D_INV_ADMINISTRATIVE_KEY , 1) AS 	D_INV_ADMINISTRATIVE_KEY ,
                COALESCE(L_INV_CLINICAL.D_INV_CLINICAL_KEY , 1) AS 	D_INV_CLINICAL_KEY ,
                COALESCE(L_INV_COMPLICATION.D_INV_COMPLICATION_KEY , 1) AS 	D_INV_COMPLICATION_KEY ,
                COALESCE(L_INV_CONTACT.D_INV_CONTACT_KEY , 1) AS 	D_INV_CONTACT_KEY ,
                COALESCE(L_INV_DEATH.D_INV_DEATH_KEY , 1) AS 	D_INV_DEATH_KEY ,
                COALESCE(L_INV_EPIDEMIOLOGY.D_INV_EPIDEMIOLOGY_KEY , 1) AS 	D_INV_EPIDEMIOLOGY_KEY ,
                COALESCE(L_INV_HIV.D_INV_HIV_KEY , 1) AS 	D_INV_HIV_KEY ,
                COALESCE(L_INV_PATIENT_OBS.D_INV_PATIENT_OBS_KEY , 1) AS 	D_INV_PATIENT_OBS_KEY ,
                COALESCE(L_INV_ISOLATE_TRACKING.D_INV_ISOLATE_TRACKING_KEY , 1) AS 	D_INV_ISOLATE_TRACKING_KEY ,
                COALESCE(L_INV_LAB_FINDING.D_INV_LAB_FINDING_KEY , 1) AS 	D_INV_LAB_FINDING_KEY ,
                COALESCE(L_INV_MEDICAL_HISTORY.D_INV_MEDICAL_HISTORY_KEY , 1) AS 	D_INV_MEDICAL_HISTORY_KEY ,
                COALESCE(L_INV_MOTHER.D_INV_MOTHER_KEY , 1) AS 	D_INV_MOTHER_KEY ,
                COALESCE(L_INV_OTHER.D_INV_OTHER_KEY , 1) AS 	D_INV_OTHER_KEY ,
                COALESCE(L_INV_PREGNANCY_BIRTH.D_INV_PREGNANCY_BIRTH_KEY , 1) AS 	D_INV_PREGNANCY_BIRTH_KEY ,
                COALESCE(L_INV_RESIDENCY.D_INV_RESIDENCY_KEY , 1) AS 	D_INV_RESIDENCY_KEY ,
                COALESCE(L_INV_RISK_FACTOR.D_INV_RISK_FACTOR_KEY , 1) AS 	D_INV_RISK_FACTOR_KEY ,
                COALESCE(L_INV_SOCIAL_HISTORY.D_INV_SOCIAL_HISTORY_KEY , 1) AS 	D_INV_SOCIAL_HISTORY_KEY ,
                COALESCE(L_INV_SYMPTOM.D_INV_SYMPTOM_KEY , 1) AS 	D_INV_SYMPTOM_KEY ,
                COALESCE(L_INV_TREATMENT.D_INV_TREATMENT_KEY , 1) AS 	D_INV_TREATMENT_KEY ,
                COALESCE(L_INV_TRAVEL.D_INV_TRAVEL_KEY , 1) AS 	D_INV_TRAVEL_KEY ,
                COALESCE(L_INV_UNDER_CONDITION.D_INV_UNDER_CONDITION_KEY , 1) AS 	D_INV_UNDER_CONDITION_KEY ,
                COALESCE(L_INV_VACCINATION.D_INV_VACCINATION_KEY , 1) AS 	D_INV_VACCINATION_KEY ,
                COALESCE(L_INVESTIGATION_REPEAT.D_INVESTIGATION_REPEAT_KEY , 1 ) AS	D_INVESTIGATION_REPEAT_KEY,
                COALESCE(L_INV_PLACE_REPEAT.D_INV_PLACE_REPEAT_KEY , 1 ) AS	D_INV_PLACE_REPEAT_KEY
        into #DIMENSIONAL_KEYS
        from #PHC_UIDS phc
                 LEFT OUTER JOIN  #DIMENSION_KEYS_PAGECASEID DIMC ON DIMC.PAGE_CASE_UID = phc.PAGE_CASE_UID
                 LEFT OUTER JOIN   dbo.L_INV_ADMINISTRATIVE ON  L_INV_ADMINISTRATIVE.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_CLINICAL ON  L_INV_CLINICAL.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_COMPLICATION ON  L_INV_COMPLICATION.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_CONTACT ON  L_INV_CONTACT.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_DEATH ON  L_INV_DEATH.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_EPIDEMIOLOGY ON  L_INV_EPIDEMIOLOGY.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_HIV ON  L_INV_HIV.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_ISOLATE_TRACKING ON  L_INV_ISOLATE_TRACKING.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_LAB_FINDING ON  L_INV_LAB_FINDING.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_MEDICAL_HISTORY ON  L_INV_MEDICAL_HISTORY.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_MOTHER ON  L_INV_MOTHER.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_OTHER ON  L_INV_OTHER.PAGE_CASE_UID = dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_PATIENT_OBS ON  L_INV_PATIENT_OBS.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_PREGNANCY_BIRTH ON  L_INV_PREGNANCY_BIRTH.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_RESIDENCY ON  L_INV_RESIDENCY.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_RISK_FACTOR ON  L_INV_RISK_FACTOR.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_SOCIAL_HISTORY ON  L_INV_SOCIAL_HISTORY.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_SYMPTOM ON  L_INV_SYMPTOM.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_TRAVEL ON  L_INV_TRAVEL.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_TREATMENT ON   L_INV_TREATMENT.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_UNDER_CONDITION ON   L_INV_UNDER_CONDITION.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_VACCINATION ON  L_INV_VACCINATION.PAGE_CASE_UID  =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INVESTIGATION_REPEAT ON  L_INVESTIGATION_REPEAT.PAGE_CASE_UID =  dimc.page_case_uid
                 LEFT OUTER JOIN   dbo.L_INV_PLACE_REPEAT ON  L_INV_PLACE_REPEAT.PAGE_CASE_UID =  dimc.page_case_uid
        ;

        if @debug  = 'true' select * from #DIMENSIONAL_KEYS;
        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES(@batch_id,'F_PAGE_CASE','F_PAGE_CASE','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = 7;
        SET @Proc_Step_Name = ' Generating F_PAGE_CASE_TEMP_INC';

        IF OBJECT_ID('#F_PAGE_CASE_TEMP_INC', 'U') IS NOT NULL
            drop table #F_PAGE_CASE_TEMP_INC
            ;


        --DROP TABLE dbo.F_PAGE_CASE;

        --CREATE TABLE 	F_PAGE_CASE AS
        SELECT
            DIM_KEYS.*,
            --CAST ( 1 as float ) AS D_INV_PLACE_REPEAT_KEY,
            KEYSTORE.CONDITION_KEY,
            KEYSTORE.INVESTIGATION_KEY,
            KEYSTORE.PHYSICIAN_KEY,
            KEYSTORE.INVESTIGATOR_KEY,
            KEYSTORE.HOSPITAL_KEY as HOSPITAL_KEY,
            KEYSTORE.PATIENT_KEY,
            KEYSTORE.PERSON_AS_REPORTER_KEY AS PERSON_AS_REPORTER_KEY,
            KEYSTORE.ORG_AS_REPORTER_KEY AS ORG_AS_REPORTER_KEY,
            --KEYSTORE.HOSPITAL_KEY AS HOSPITAL_KEY,
            KEYSTORE.GEOCODING_LOCATION_KEY,
            DATE1.DATE_KEY AS ADD_DATE_KEY,
            DATE2.DATE_KEY AS LAST_CHG_DATE_KEY

        INTO #F_PAGE_CASE_TEMP_INC
        FROM  #ENTITY_KEYSTORE_INC AS KEYSTORE
                  INNER JOIN #DIMENSIONAL_KEYS as DIM_KEYS ON DIM_KEYS.PAGE_CASE_UID = KEYSTORE.PAGE_CASE_UID
                  LEFT OUTER JOIN dbo.RDB_DATE DATE1 ON cast(DATE1.DATE_MM_DD_YYYY as date)= cast(KEYSTORE.ADD_TIME as date)
                  LEFT OUTER JOIN dbo.RDB_DATE DATE2 ON cast(DATE2.DATE_MM_DD_YYYY as date )=cast(KEYSTORE.LAST_CHG_TIME as date)
        ;



        if @debug  = 'true' select * from #DIMENSIONAL_KEYS;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES(@batch_id,'F_PAGE_CASE','F_PAGE_CASE','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = 8;
        SET @Proc_Step_Name = ' Generating DROP COLUMNS';

        -- DROP COLUMN PAGE_CASE_UID;
        ALTER TABLE  #F_PAGE_CASE_TEMP_INC DROP COLUMN PAGE_CASE_UID ;
        if @debug  = 'true' select * from #F_PAGE_CASE_TEMP_INC;

        --??PROC SORT DATA=F_PAGE_CASE NODUPKEY; BY PATIENT_KEY; RUN;

        IF OBJECT_ID('dbo.F_PAGE_CASE', 'U') IS NOT NULL
            BEGIN
                --drop table dbo.F_PAGE_CASE;
                DELETE fpagecase FROM dbo.F_PAGE_CASE fpagecase
                                          JOIN #F_PAGE_CASE_TEMP_INC fpagecaseinc ON fpagecase.investigation_key=fpagecaseinc.investigation_key;

                INSERT INTO dbo.F_PAGE_CASE SELECT * FROM #F_PAGE_CASE_TEMP_INC;
            END;


        IF OBJECT_ID('dbo.F_PAGE_CASE', 'U') IS NULL
            BEGIN
                SELECT *
                into [dbo].F_PAGE_CASE
                FROM
                    (
                        SELECT *,
                               ROW_NUMBER () OVER (PARTITION BY PATIENT_KEY order by PATIENT_KEY) rowid
                        FROM #F_PAGE_CASE_TEMP_INC
                    ) AS Der WHERE rowid=1;


                ALTER TABLE  dbo.F_PAGE_CASE DROP COLUMN rowid ;
            END;
        /**
        This should cover any issue with defect https://nbscentral.sramanaged.com/redmine/issues/12555
        ETL Error in Dynamic Datamarts Process - Problem Record(s) Causing Million+ Rows in Dynamic Datamart (Total Should Be a Few Thousand)
        */

        DELETE FROM [DBO].F_PAGE_CASE WHERE INVESTIGATION_KEY IN (SELECT INVESTIGATION_KEY FROM dbo.F_PAGE_CASE
                                                                  GROUP BY INVESTIGATION_KEY HAVING COUNT(INVESTIGATION_KEY)>1) AND PATIENT_KEY =1

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES(@batch_id,'F_PAGE_CASE','F_PAGE_CASE','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION ;

        SET @Proc_Step_no = 9;
        SET @Proc_Step_Name = 'SP_COMPLETE';


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
        VALUES
            (
              @batch_id,
              'F_PAGE_CASE'
            ,'S_F_PAGE_CASE'
            ,'COMPLETE'
            ,@Proc_Step_no
            ,@Proc_Step_name
            ,@RowCount_no
            ,LEFT('ID List-' + @phc_ids,500)
            );


        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH


        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;



        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();


        INSERT INTO [dbo].[job_flow_log] (
                                           batch_id
                                         ,[Dataflow_Name]
                                         ,[package_Name]
                                         ,[Status_Type]
                                         ,[step_number]
                                         ,[step_name]
                                         ,[Error_Description]
                                         ,[row_count]
        )
        VALUES
            (
              @batch_id
            ,'F_PAGE_CASE'
            ,'S_F_PAGE_CASE'
            ,'ERROR'
            ,@Proc_Step_no
            ,'ERROR - '+ @Proc_Step_name
            , 'Step -' +CAST(@Proc_Step_no AS VARCHAR(3))+' -' +CAST(@ErrorMessage AS VARCHAR(500))
            ,0
            );


        return -1 ;

    END CATCH

END;