CREATE or ALTER PROCEDURE [dbo].[sp_f_std_page_case_postprocessing] @phc_id_list nvarchar(max), @debug bit = 'false'
AS
BEGIN
BEGIN TRY

   declare @rowcount_no bigint;
   declare @proc_step_no float = 0;
   declare @proc_step_name varchar(200) = '';
   declare @batch_id bigint;
   declare @create_dttm datetime2(7) = current_timestamp;
   declare @update_dttm datetime2(7) = current_timestamp;
   declare @dataflow_name varchar(200) = 'F_STD_PAGE_CASE';
   declare @package_name varchar(200) = 'F_STD_PAGE_CASE';

   SET @batch_id = cast((format(getdate(),'yyMMddHHmmss')) as bigint);

    INSERT INTO [dbo].[job_flow_log]
    (batch_id
        ,[create_dttm]
        ,[update_dttm]
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[msg_description1]
        ,[row_count])
    VALUES (@batch_id
            ,@create_dttm
            ,@update_dttm
            ,@dataflow_name
            ,@package_name
            ,'START'
            ,0
            ,'SP_Start'
            ,LEFT(@phc_id_list, 500)
            ,0);


    BEGIN TRANSACTION;
        SET @proc_step_no = 1;
        SET @proc_step_name = ' Generating PHC_UIDS_ALL';

        IF OBJECT_ID('#PHC_CASE_UIDS_ALL', 'U') IS NOT NULL
            drop table #PHC_CASE_UIDS_ALL
        ;

        SELECT
            ni.public_health_case_uid  'PAGE_CASE_UID',
                nicm.CASE_MANAGEMENT_UID,
            ni.INVESTIGATION_FORM_CD,
            ni.CD,
            ni.LAST_CHG_TIME,
            ni.ADD_TIME,
            ni.investigator_id,
            ni.physician_id,
            ni.patient_id,
            ni.person_as_reporter_uid,
            ni.hospital_uid,
            ni.ordering_facility_uid,
            ni.ca_supervisor_of_phc_uid,
            ni.closure_investgr_of_phc_uid,
            ni.dispo_fld_fupinvestgr_of_phc_uid,
            ni.fld_fup_investgr_of_phc_uid,
            ni.fld_fup_prov_of_phc_uid,
            ni.fld_fup_supervisor_of_phc_uid,
            ni.init_fld_fup_investgr_of_phc_uid,
            ni.init_fup_investgr_of_phc_uid,
            ni.init_interviewer_of_phc_uid,
            ni.interviewer_of_phc_uid,
            ni.surv_investgr_of_phc_uid,
            ni.fld_fup_facility_of_phc_uid,
            ni.org_as_hospital_of_delivery_uid,
            ni.per_as_provider_of_delivery_uid,
            ni.per_as_provider_of_obgyn_uid,
            ni.per_as_provider_of_pediatrics_uid,
            ni.org_as_reporter_uid
        INTO
            #PHC_CASE_UIDS_ALL
        FROM
            dbo.nrt_investigation  ni
                LEFT OUTER JOIN dbo.nrt_investigation_case_management nicm ON	ni.public_health_case_uid = nicm.public_health_case_uid
                LEFT OUTER JOIN NBS_SRTE.dbo.CONDITION_CODE cc with(nolock) ON 	cc.CONDITION_CD= ni.CD AND	cc.INVESTIGATION_FORM_CD
            NOT IN 	( 'bo.','INV_FORM_BMDGBS','INV_FORM_BMDGEN','INV_FORM_BMDNM','INV_FORM_BMDSP','INV_FORM_GEN','INV_FORM_HEPA','INV_FORM_HEPBV','INV_FORM_HEPCV','INV_FORM_HEPGEN','INV_FORM_MEA','INV_FORM_PER','INV_FORM_RUB','INV_FORM_RVCT','INV_FORM_VAR')
        where
            ni.public_health_case_uid in (
            SELECT value FROM STRING_SPLIT(@phc_id_list, ',')
            ) and
            nicm.CASE_MANAGEMENT_UID is not null;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,@dataflow_name,@package_name,'START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

    COMMIT TRANSACTION;

    if @debug = 'true' select '#PHC_CASE_UIDS_ALL', * from #PHC_CASE_UIDS_ALL;

    BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1; --2
        SET @PROC_STEP_NAME = ' Generating PHC_UIDS';


        IF OBJECT_ID('#PHC_UIDS', 'U') IS NOT NULL
            drop table #PHC_UIDS
        ;


    SELECT ni.public_health_case_uid page_case_uid,
           ni.CASE_MANAGEMENT_UID,
           ni.INVESTIGATION_FORM_CD,
           ni.CD,
           ni.LAST_CHG_TIME,
           ni.ADD_TIME,
           ni.investigator_id,
           ni.physician_id,
           ni.patient_id,
           ni.person_as_reporter_uid,
           ni.hospital_uid,
           ni.ordering_facility_uid,
           ni.ca_supervisor_of_phc_uid,
           ni.closure_investgr_of_phc_uid,
           ni.dispo_fld_fupinvestgr_of_phc_uid,
           ni.fld_fup_investgr_of_phc_uid,
           ni.fld_fup_prov_of_phc_uid,
           ni.fld_fup_supervisor_of_phc_uid,
           ni.init_fld_fup_investgr_of_phc_uid,
           ni.init_fup_investgr_of_phc_uid,
           ni.init_interviewer_of_phc_uid,
           ni.interviewer_of_phc_uid,
           ni.surv_investgr_of_phc_uid,
           ni.fld_fup_facility_of_phc_uid,
           ni.org_as_hospital_of_delivery_uid,
           ni.per_as_provider_of_delivery_uid,
           ni.per_as_provider_of_obgyn_uid,
           ni.per_as_provider_of_pediatrics_uid,
           ni.org_as_reporter_uid
    INTO
        #PHC_UIDS
    FROM dbo.nrt_investigation ni
    WHERE ni.public_health_case_uid IN (SELECT value FROM STRING_SPLIT(@phc_id_list, ',')) and
        INVESTIGATION_FORM_CD  NOT IN ( 'INV_FORM_BMDGAS','INV_FORM_BMDGBS','INV_FORM_BMDGEN',
                                        'INV_FORM_BMDNM','INV_FORM_BMDSP','INV_FORM_GEN','INV_FORM_HEPA','INV_FORM_HEPBV','INV_FORM_HEPCV',
                                        'INV_FORM_HEPGEN','INV_FORM_MEA','INV_FORM_PER','INV_FORM_RUB','INV_FORM_RVCT','INV_FORM_VAR')
      and CASE_MANAGEMENT_UID IS NOT NULL;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO dbo.[JOB_FLOW_LOG]
    (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
    VALUES(@BATCH_ID,@dataflow_name,@package_name,'START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

    COMMIT TRANSACTION;


    BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1; --3
        SET @PROC_STEP_NAME = ' Generating ENTITY_KEYSTORE_STD';


        IF OBJECT_ID('#ENTITY_KEYSTORE_STD', 'U') IS NOT NULL
            drop table #ENTITY_KEYSTORE_STD
        ;


        SELECT
            FSSHC.ADD_TIME,
            FSSHC.LAST_CHG_TIME,
            FSSHC.PATIENT_ID,
            COALESCE(PATIENT.PATIENT_KEY, 1)  AS PATIENT_KEY,
            FSSHC.PAGE_CASE_UID,
            FSSHC.HOSPITAL_UID,
            COALESCE(HOSPITAL.ORGANIZATION_KEY, 1)  AS HOSPITAL_KEY,
            FSSHC.ORG_AS_REPORTER_UID,
            COALESCE(REPORTERORG.ORGANIZATION_KEY, 1)  AS ORG_AS_REPORTER_KEY,
            FSSHC.PERSON_AS_REPORTER_UID,
            COALESCE(PERSONREPORTER.PROVIDER_KEY, 1)  AS PERSON_AS_REPORTER_KEY,
            FSSHC.PHYSICIAN_ID,
            COALESCE(PHYSICIAN.PROVIDER_KEY, 1)  AS PHYSICIAN_KEY,
            FSSHC.INVESTIGATOR_ID,
            COALESCE(PROVIDER.PROVIDER_KEY, 1)  AS INVESTIGATOR_KEY,
            COALESCE(INVESTIGATION.INVESTIGATION_KEY,1 ) AS INVESTIGATION_KEY,
            COALESCE(CONDITION.CONDITION_KEY,1)  AS CONDITION_KEY,
            COALESCE(LOC.GEOCODING_LOCATION_KEY, 1) AS GEOCODING_LOCATION_KEY,
            COALESCE(FACILITYORG.ORGANIZATION_KEY,1) AS ORDERING_FACILITY_KEY,
            COALESCE(CL.PROVIDER_KEY,1) AS CLOSED_BY_KEY,
            COALESCE(DISP.PROVIDER_KEY,1) AS DISPOSITIONED_BY_KEY,
            COALESCE(FACILITY.ORGANIZATION_KEY,1) AS FACILITY_FLD_FOLLOW_UP_KEY,
            COALESCE(FLD_FUP_INVESTGTR.PROVIDER_KEY,1) AS INVSTGTR_FLD_FOLLOW_UP_KEY,
            COALESCE(PROVIDER_FLD_FUP.PROVIDER_KEY,1) AS PROVIDER_FLD_FOLLOW_UP_KEY,
            COALESCE(SUPRVSR_FLD_FUP.PROVIDER_KEY,1) AS SUPRVSR_OF_FLD_FOLLOW_UP_KEY,
            COALESCE(INIT_FLD_FUP.PROVIDER_KEY,1) AS INIT_ASGNED_FLD_FOLLOW_UP_KEY,
            COALESCE(INIT_INVSTGR_PHC.PROVIDER_KEY,1) AS INIT_FOLLOW_UP_INVSTGTR_KEY,
            COALESCE(INIT_INTERVIEWER.PROVIDER_KEY,1) AS INIT_ASGNED_INTERVIEWER_KEY,
            COALESCE(INTERVIEWER.PROVIDER_KEY,1) AS INTERVIEWER_ASSIGNED_KEY,
            COALESCE(SURV.PROVIDER_KEY,1) AS SURVEILLANCE_INVESTIGATOR_KEY,
            COALESCE(CA.PROVIDER_KEY,1) AS SUPRVSR_OF_CASE_ASSGNMENT_KEY,
            COALESCE(HOSPDELIVERY.ORGANIZATION_KEY, 1) AS DELIVERING_HOSP_KEY,
            COALESCE(PROVDELIVERY.PROVIDER_KEY, 1) AS DELIVERING_MD_KEY,
            COALESCE(MOTHEROBGYN.PROVIDER_KEY, 1) AS MOTHER_OB_GYN_KEY,
            COALESCE(PEDIATRICIAN.PROVIDER_KEY, 1) AS PEDIATRICIAN_KEY
        into #ENTITY_KEYSTORE_STD
        FROM #PHC_CASE_UIDS_ALL   FSSHC
                 LEFT OUTER JOIN dbo.CONDITION CONDITION with(nolock) ON FSSHC.CD= CONDITION.CONDITION_CD
            LEFT OUTER JOIN dbo.D_PATIENT PATIENT	with(nolock) ON fsshc.PATIENT_ID= PATIENT.PATIENT_UID
            LEFT OUTER JOIN dbo.D_ORGANIZATION  HOSPITAL with(nolock) ON fsshc.HOSPITAL_UID= HOSPITAL.ORGANIZATION_UID
            LEFT OUTER JOIN dbo.D_ORGANIZATION  HOSPDELIVERY with(nolock) ON fsshc.ORG_AS_HOSPITAL_OF_DELIVERY_UID= HOSPDELIVERY.ORGANIZATION_UID
            LEFT OUTER JOIN dbo.D_ORGANIZATION REPORTERORG with(nolock) ON fsshc.ORG_AS_REPORTER_UID= REPORTERORG.ORGANIZATION_UID
            LEFT OUTER JOIN dbo.D_ORGANIZATION FACILITYORG with(nolock) ON fsshc.ORDERING_FACILITY_UID= FACILITYORG.ORGANIZATION_UID
            LEFT OUTER JOIN dbo.D_PROVIDER PERSONREPORTER with(nolock) ON  fsshc.PERSON_AS_REPORTER_UID= PERSONREPORTER.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER PROVDELIVERY with(nolock) ON fsshc.PER_AS_PROVIDER_OF_DELIVERY_UID= PROVDELIVERY.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER MOTHEROBGYN with(nolock) ON fsshc.PER_AS_PROVIDER_OF_OBGYN_UID= MOTHEROBGYN.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER PEDIATRICIAN with(nolock) ON fsshc.PER_AS_PROVIDER_OF_PEDIATRICS_UID= PEDIATRICIAN.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER PROVIDER with(nolock) ON fsshc.INVESTIGATOR_ID= PROVIDER.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER PHYSICIAN with(nolock) ON fsshc.PHYSICIAN_ID= PHYSICIAN.PROVIDER_UID
            LEFT OUTER JOIN dbo.INVESTIGATION  INVESTIGATION with(nolock) ON fsshc.PAGE_CASE_UID= INVESTIGATION.CASE_UID
            LEFT OUTER JOIN dbo.D_PROVIDER CL with(nolock) ON fsshc.CLOSURE_INVESTGR_OF_PHC_UID= CL.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER DISP with(nolock) ON fsshc.DISPO_FLD_FUPINVESTGR_OF_PHC_UID= DISP.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_ORGANIZATION  FACILITY with(nolock) ON fsshc.FLD_FUP_FACILITY_OF_PHC_UID= FACILITY.ORGANIZATION_UID
            LEFT OUTER JOIN dbo.D_PROVIDER FLD_FUP_INVESTGTR with(nolock) ON fsshc.FLD_FUP_INVESTGR_OF_PHC_UID= FLD_FUP_INVESTGTR.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER PROVIDER_FLD_FUP with(nolock) ON fsshc.FLD_FUP_PROV_OF_PHC_UID= PROVIDER_FLD_FUP.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER SUPRVSR_FLD_FUP with(nolock) ON fsshc.FLD_FUP_SUPERVISOR_OF_PHC_UID= SUPRVSR_FLD_FUP.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER INIT_FLD_FUP with(nolock) ON fsshc.INIT_FLD_FUP_INVESTGR_OF_PHC_UID= INIT_FLD_FUP.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER INIT_INVSTGR_PHC with(nolock) ON fsshc.INIT_FUP_INVESTGR_OF_PHC_UID= INIT_INVSTGR_PHC.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER INIT_INTERVIEWER with(nolock) ON fsshc.INIT_INTERVIEWER_OF_PHC_UID= INIT_INTERVIEWER.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER INTERVIEWER with(nolock) ON fsshc.INTERVIEWER_OF_PHC_UID= INTERVIEWER.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER SURV with(nolock) ON fsshc.SURV_INVESTGR_OF_PHC_UID= SURV.PROVIDER_UID
            LEFT OUTER JOIN dbo.D_PROVIDER CA with(nolock) ON fsshc.CA_SUPERVISOR_OF_PHC_UID= CA.PROVIDER_UID
            LEFT JOIN dbo.GEOCODING_LOCATION AS LOC with(nolock) ON LOC.ENTITY_UID = PATIENT.PATIENT_UID
        where  PAGE_CASE_UID IN (
            SELECT PAGE_CASE_UID FROM #PHC_UIDS
            )
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,@dataflow_name,@package_name,'START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

    COMMIT TRANSACTION;

    if @debug = 'true' select '##ENTITY_KEYSTORE_STD', * from #ENTITY_KEYSTORE_STD;

    BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1; --4
        SET @PROC_STEP_NAME = ' Generating DIMENSION_KEYS_PAGECASEID';


        IF OBJECT_ID('#DIMENSION_KEYS_PAGECASEID', 'U') IS NOT NULL
            drop table #DIMENSION_KEYS_PAGECASEID
        ;

        select L_INV_ADMINISTRATIVE.PAGE_CASE_UID as PAGE_CASE_UID
        into #DIMENSION_KEYS_PAGECASEID
        from  dbo.L_INV_ADMINISTRATIVE  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_CLINICAL  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_COMPLICATION  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_CONTACT  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_DEATH  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_EPIDEMIOLOGY  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_HIV  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_ISOLATE_TRACKING  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_LAB_FINDING  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_MEDICAL_HISTORY  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_MOTHER  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_OTHER  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_PATIENT_OBS  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_PREGNANCY_BIRTH  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_RESIDENCY  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_RISK_FACTOR  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_SOCIAL_HISTORY  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_SYMPTOM  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_TRAVEL  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_TREATMENT  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_UNDER_CONDITION  with(nolock) union
        select PAGE_CASE_UID 	 from  dbo.L_INV_VACCINATION  with(nolock) union
        SELECT PAGE_CASE_UID	    from  dbo.L_INVESTIGATION_REPEAT  with(nolock) union
        SELECT PAGE_CASE_UID	    from  dbo.L_INV_PLACE_REPEAT with(nolock)
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,@dataflow_name,@package_name,'START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

    COMMIT TRANSACTION;

    if @debug = 'true' select '##DIMENSION_KEYS_PAGECASEID', * from #DIMENSION_KEYS_PAGECASEID;

    BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1; --5
        SET @PROC_STEP_NAME = ' Generating #DIMENSIONAL_KEYS';


        IF OBJECT_ID('#DIMENSIONAL_KEYS', 'U') IS NOT NULL
            drop table #DIMENSIONAL_KEYS
        ;

        select  DIMC.page_case_uid,
            COALESCE(ladmin.D_INV_ADMINISTRATIVE_KEY , 1) AS 	D_INV_ADMINISTRATIVE_KEY ,
            COALESCE(licl.D_INV_CLINICAL_KEY , 1) AS 	D_INV_CLINICAL_KEY ,
            COALESCE(licomp.D_INV_COMPLICATION_KEY , 1) AS 	D_INV_COMPLICATION_KEY ,
            COALESCE(licon.D_INV_CONTACT_KEY , 1) AS 	D_INV_CONTACT_KEY ,
            COALESCE(lid.D_INV_DEATH_KEY , 1) AS 	D_INV_DEATH_KEY ,
            COALESCE(lie.D_INV_EPIDEMIOLOGY_KEY , 1) AS 	D_INV_EPIDEMIOLOGY_KEY ,
            COALESCE(lihiv.D_INV_HIV_KEY , 1) AS 	D_INV_HIV_KEY ,
            COALESCE(lipo.D_INV_PATIENT_OBS_KEY , 1) AS 	D_INV_PATIENT_OBS_KEY ,
            COALESCE(liit.D_INV_ISOLATE_TRACKING_KEY , 1) AS 	D_INV_ISOLATE_TRACKING_KEY ,
            COALESCE(lilf.D_INV_LAB_FINDING_KEY , 1) AS 	D_INV_LAB_FINDING_KEY ,
            COALESCE(limh.D_INV_MEDICAL_HISTORY_KEY , 1) AS 	D_INV_MEDICAL_HISTORY_KEY ,
            COALESCE(lim.D_INV_MOTHER_KEY , 1) AS 	D_INV_MOTHER_KEY ,
            COALESCE(liot.D_INV_OTHER_KEY , 1) AS 	D_INV_OTHER_KEY ,
            COALESCE(lipb.D_INV_PREGNANCY_BIRTH_KEY , 1) AS 	D_INV_PREGNANCY_BIRTH_KEY ,
            COALESCE(lirs.D_INV_RESIDENCY_KEY , 1) AS 	D_INV_RESIDENCY_KEY ,
            COALESCE(lirf.D_INV_RISK_FACTOR_KEY , 1) AS 	D_INV_RISK_FACTOR_KEY ,
            COALESCE(lish.D_INV_SOCIAL_HISTORY_KEY , 1) AS 	D_INV_SOCIAL_HISTORY_KEY ,
            COALESCE(lis.D_INV_SYMPTOM_KEY , 1) AS 	D_INV_SYMPTOM_KEY ,
            COALESCE(litr.D_INV_TREATMENT_KEY , 1) AS 	D_INV_TREATMENT_KEY ,
            COALESCE(litl.D_INV_TRAVEL_KEY , 1) AS 	D_INV_TRAVEL_KEY ,
            COALESCE(liuc.D_INV_UNDER_CONDITION_KEY , 1) AS 	D_INV_UNDER_CONDITION_KEY ,
            COALESCE(liv.D_INV_VACCINATION_KEY , 1) AS 	D_INV_VACCINATION_KEY ,
            COALESCE(lir.D_INVESTIGATION_REPEAT_KEY , 1 ) AS	D_INVESTIGATION_REPEAT_KEY,
            COALESCE(lipr.D_INV_PLACE_REPEAT_KEY , 1 ) AS	D_INV_PLACE_REPEAT_KEY
        into #DIMENSIONAL_KEYS
        from #DIMENSION_KEYS_PAGECASEID DIMC
             LEFT OUTER JOIN   dbo.L_INV_ADMINISTRATIVE ladmin  with(nolock) ON  ladmin.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_CLINICAL licl  with(nolock) ON  licl.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_COMPLICATION licomp  with(nolock) ON  licomp.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_CONTACT licon  with(nolock) ON  licon.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_DEATH lid  with(nolock) ON  lid.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_EPIDEMIOLOGY lie  with(nolock) ON  lie.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_HIV lihiv  with(nolock) ON  lihiv.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_ISOLATE_TRACKING liit  with(nolock) ON  liit.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_LAB_FINDING lilf  with(nolock) ON  lilf.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_MEDICAL_HISTORY limh  with(nolock) ON  limh.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_MOTHER lim  with(nolock) ON  lim.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_OTHER liot  with(nolock) ON  liot.PAGE_CASE_UID = dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_PATIENT_OBS lipo  with(nolock) ON  lipo.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_PREGNANCY_BIRTH lipb  with(nolock) ON  lipb.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_RESIDENCY lirs  with(nolock) ON  lirs.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_RISK_FACTOR lirf  with(nolock) ON  lirf.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_SOCIAL_HISTORY lish  with(nolock) ON  lish.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_SYMPTOM lis  with(nolock) ON  lis.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_TRAVEL litl  with(nolock) ON  litl.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_TREATMENT litr  with(nolock) ON  litr.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_UNDER_CONDITION liuc  with(nolock) ON liuc.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_VACCINATION liv  with(nolock) ON  liv.PAGE_CASE_UID  =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INVESTIGATION_REPEAT lir  with(nolock) ON lir.PAGE_CASE_UID =  dimc.page_case_uid
             LEFT OUTER JOIN   dbo.L_INV_PLACE_REPEAT lipr  with(nolock) ON  lipr.PAGE_CASE_UID =  dimc.page_case_uid
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,@dataflow_name,@package_name,'START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

    COMMIT TRANSACTION;

    if @debug = 'true' select '###DIMENSIONAL_KEYS', * from #DIMENSIONAL_KEYS;

    BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1; --6
        SET @PROC_STEP_NAME = ' Generating #F_STD_PAGE_CASE_TEMP_INC';

        IF OBJECT_ID('#F_STD_PAGE_CASE_TEMP_INC', 'U') IS NOT NULL
            drop table #F_STD_PAGE_CASE_TEMP_INC
        ;

        SELECT
            DIM_KEYS.*,
            --CAST ( 1 as float ) AS D_INV_PLACE_REPEAT_KEY ,
            KEYSTORE.CONDITION_KEY,
            KEYSTORE.INVESTIGATION_KEY,
            KEYSTORE.PHYSICIAN_KEY,
            KEYSTORE.INVESTIGATOR_KEY,
            KEYSTORE.HOSPITAL_KEY                  as HOSPITAL_KEY,
            KEYSTORE.PATIENT_KEY,
            KEYSTORE.PERSON_AS_REPORTER_KEY        AS PERSON_AS_REPORTER_KEY,
            KEYSTORE.ORG_AS_REPORTER_KEY           AS ORG_AS_REPORTER_KEY,
            --KEYSTORE.HOSPITAL_KEY AS HOSPITAL_KEY,
            KEYSTORE.ORDERING_FACILITY_KEY         AS ORDERING_FACILITY_KEY,
            KEYSTORE.GEOCODING_LOCATION_KEY,
            KEYSTORE.CLOSED_BY_KEY                 AS CLOSED_BY_KEY,
            KEYSTORE.DISPOSITIONED_BY_KEY          AS DISPOSITIONED_BY_KEY,
            KEYSTORE.FACILITY_FLD_FOLLOW_UP_KEY    AS FACILITY_FLD_FOLLOW_UP_KEY,
            KEYSTORE.INVSTGTR_FLD_FOLLOW_UP_KEY    AS INVSTGTR_FLD_FOLLOW_UP_KEY,
            KEYSTORE.PROVIDER_FLD_FOLLOW_UP_KEY    AS PROVIDER_FLD_FOLLOW_UP_KEY,
            KEYSTORE.SUPRVSR_OF_FLD_FOLLOW_UP_KEY  AS SUPRVSR_OF_FLD_FOLLOW_UP_KEY,
            KEYSTORE.INIT_ASGNED_FLD_FOLLOW_UP_KEY AS INIT_ASGNED_FLD_FOLLOW_UP_KEY,
            KEYSTORE.INIT_FOLLOW_UP_INVSTGTR_KEY   AS INIT_FOLLOW_UP_INVSTGTR_KEY,
            KEYSTORE.INIT_ASGNED_INTERVIEWER_KEY   AS INIT_ASGNED_INTERVIEWER_KEY,
            KEYSTORE.INTERVIEWER_ASSIGNED_KEY      AS INTERVIEWER_ASSIGNED_KEY,
            KEYSTORE.SURVEILLANCE_INVESTIGATOR_KEY AS SURVEILLANCE_INVESTIGATOR_KEY,
            KEYSTORE.SUPRVSR_OF_CASE_ASSGNMENT_KEY AS SUPRVSR_OF_CASE_ASSGNMENT_KEY,
            KEYSTORE.DELIVERING_HOSP_KEY           AS DELIVERING_HOSP_KEY,
            KEYSTORE.DELIVERING_MD_KEY             AS DELIVERING_MD_KEY,
            KEYSTORE.MOTHER_OB_GYN_KEY             AS MOTHER_OB_GYN_KEY,
            KEYSTORE.PEDIATRICIAN_KEY              AS PEDIATRICIAN_KEY,
            DATE1.DATE_KEY                         AS ADD_DATE_KEY,
            DATE2.DATE_KEY                         AS LAST_CHG_DATE_KEY
        INTO
            #F_STD_PAGE_CASE_TEMP_INC
        FROM #DIMENSIONAL_KEYS as DIM_KEYS
                 INNER JOIN #ENTITY_KEYSTORE_STD AS KEYSTORE
                            ON DIM_KEYS.PAGE_CASE_UID = KEYSTORE.PAGE_CASE_UID
                 LEFT OUTER JOIN dbo.RDB_DATE DATE1 with(nolock)
        ON cast(DATE1.DATE_MM_DD_YYYY as date) = cast(KEYSTORE.ADD_TIME as date)
            LEFT OUTER JOIN dbo.RDB_DATE DATE2 with(nolock)
        ON cast(DATE2.DATE_MM_DD_YYYY as date) = cast(KEYSTORE.LAST_CHG_TIME as date)
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,@dataflow_name,@package_name,'START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

    COMMIT TRANSACTION;

    if @debug = 'true' select '##F_STD_PAGE_CASE_TEMP_INC-1', * from #F_STD_PAGE_CASE_TEMP_INC;

    BEGIN TRANSACTION;

        insert into dbo.ETL_DQ_LOG (
            EVENT_TYPE,EVENT_UID,EVENT_LOCAL_ID,DQ_ISSUE_CD,DQ_ISSUE_DESC_TXT,DQ_ISSUE_QUESTION_IDENTIFIER,DQ_ISSUE_ANSWER_TXT,
            DQ_ISSUE_RDB_LOCATION,job_batch_log_UID,DQ_ETL_PROCESS_TABLE,DQ_ETL_PROCESS_COLUMN,DQ_STATUS_TIME,DQ_ISSUE_SOURCE_LOCATION,DQ_ISSUE_SOURCE_QUESTION_LABEL
        )
        select
            'F_STD_PAGE_CASE',
            inv.CASE_UID,
            inv.INV_LOCAL_ID,
            'DUPLICATE ENTITY ID',
            'BAD DATA: There are duplicate entries for the same investigation. The NBS_act_entity table contains duplicate entity UIDs (local_id). Please review this table for any additional duplicate records linked to the same investigation local_KEY.',
            'DEM197',' ',' ',
            @batch_id,
            cd.CONDITION_DESC,
            ' ',GETDATE(),
            coalesce(pt.PATIENT_LOCAL_ID,' '),
            pti.Patient_KEY
        FROM #F_STD_PAGE_CASE_TEMP_INC pti
                 inner join dbo.INVESTIGATION inv with(nolock) on inv.INVESTIGATION_KEY = pti.INVESTIGATION_KEY
            inner join dbo.D_PATIENT pt with(nolock) on pt.PATIENT_KEY = pti.PATIENT_KEY
            inner join dbo.CONDITION cd with(nolock) on cd.CONDITION_KEY = pti.CONDITION_KEY
        where pti.INVESTIGATION_KEY in ( select INVESTIGATION_KEY
            FROM #F_STD_PAGE_CASE_TEMP_INC pti
            group by INVESTIGATION_KEY, PATIENT_KEY having count(*) > 1
            )
        ;

        insert into dbo.ETL_DQ_LOG ( EVENT_TYPE,EVENT_UID,EVENT_LOCAL_ID,DQ_ISSUE_CD,DQ_ISSUE_DESC_TXT,DQ_ISSUE_QUESTION_IDENTIFIER,DQ_ISSUE_ANSWER_TXT,
                                     DQ_ISSUE_RDB_LOCATION,job_batch_log_UID,DQ_ETL_PROCESS_TABLE,DQ_ETL_PROCESS_COLUMN,DQ_STATUS_TIME,DQ_ISSUE_SOURCE_LOCATION,DQ_ISSUE_SOURCE_QUESTION_LABEL
        )
        select
            'F_PAGE_CASE',
            inv.CASE_UID,
            inv.INV_LOCAL_ID,
            'DUPLICATE ENTITY ID',
            'BAD DATA: There are duplicate entries for the same investigation. The NBS_act_entity table contains duplicate entity UIDs (local_id). Please review this table for any additional duplicate records linked to the same investigation local_KEY.',
            'DEM197',' ',' ',
            @batch_id,
            cd.CONDITION_DESC,
            ' ',GETDATE(),
            coalesce(pt.PATIENT_LOCAL_ID,' '),
            pti.Patient_KEY
        FROM #F_STD_PAGE_CASE_TEMP_INC pti
                 inner join dbo.INVESTIGATION inv with(nolock) on inv.INVESTIGATION_KEY = pti.INVESTIGATION_KEY
            inner join dbo.D_PATIENT pt with(nolock) on pt.PATIENT_KEY = pti.PATIENT_KEY
            inner join dbo.CONDITION cd with(nolock) on cd.CONDITION_KEY = pti.CONDITION_KEY
        where pti.INVESTIGATION_KEY  in ( select INVESTIGATION_KEY
            FROM #F_STD_PAGE_CASE_TEMP_INC pti
            group by INVESTIGATION_KEY having count(*) > 1
            )
        ;


    COMMIT TRANSACTION;


    if @debug = 'true' select '#F_STD_PAGE_CASE_TEMP_INC-2', * from #F_STD_PAGE_CASE_TEMP_INC;

    BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' Generating F_STD_PAGE_CASE';

      DELETE fstdcase
        FROM dbo.F_STD_PAGE_CASE fstdcase
        JOIN #F_STD_PAGE_CASE_TEMP_INC fstdcaseinc ON fstdcase.investigation_key=fstdcaseinc.investigation_key;

        INSERT INTO dbo.F_STD_PAGE_CASE (
            D_INV_ADMINISTRATIVE_KEY,
            D_INV_CLINICAL_KEY,
            D_INV_COMPLICATION_KEY,
            D_INV_CONTACT_KEY,
            D_INV_DEATH_KEY,
            D_INV_EPIDEMIOLOGY_KEY,
            D_INV_HIV_KEY,
            D_INV_PATIENT_OBS_KEY,
            D_INV_ISOLATE_TRACKING_KEY,
            D_INV_LAB_FINDING_KEY,
            D_INV_MEDICAL_HISTORY_KEY,
            D_INV_MOTHER_KEY,
            D_INV_OTHER_KEY,
            D_INV_PREGNANCY_BIRTH_KEY,
            D_INV_RESIDENCY_KEY,
            D_INV_RISK_FACTOR_KEY,
            D_INV_SOCIAL_HISTORY_KEY,
            D_INV_SYMPTOM_KEY,
            D_INV_TREATMENT_KEY,
            D_INV_TRAVEL_KEY,
            D_INV_UNDER_CONDITION_KEY,
            D_INV_VACCINATION_KEY,
            D_INVESTIGATION_REPEAT_KEY,
            D_INV_PLACE_REPEAT_KEY,
            CONDITION_KEY,
            INVESTIGATION_KEY,
            PHYSICIAN_KEY,
            INVESTIGATOR_KEY,
            HOSPITAL_KEY,
            PATIENT_KEY,
            PERSON_AS_REPORTER_KEY,
            ORG_AS_REPORTER_KEY,
            ORDERING_FACILITY_KEY,
            GEOCODING_LOCATION_KEY,
            CLOSED_BY_KEY,
            DISPOSITIONED_BY_KEY,
            FACILITY_FLD_FOLLOW_UP_KEY,
            INVSTGTR_FLD_FOLLOW_UP_KEY,
            PROVIDER_FLD_FOLLOW_UP_KEY,
            SUPRVSR_OF_FLD_FOLLOW_UP_KEY,
            INIT_ASGNED_FLD_FOLLOW_UP_KEY,
            INIT_FOLLOW_UP_INVSTGTR_KEY,
            INIT_ASGNED_INTERVIEWER_KEY,
            INTERVIEWER_ASSIGNED_KEY,
            SURVEILLANCE_INVESTIGATOR_KEY,
            SUPRVSR_OF_CASE_ASSGNMENT_KEY,
            DELIVERING_HOSP_KEY,
            DELIVERING_MD_KEY,
            MOTHER_OB_GYN_KEY,
            PEDIATRICIAN_KEY,
            ADD_DATE_KEY,
            LAST_CHG_DATE_KEY
        )
        select
            src.D_INV_ADMINISTRATIVE_KEY,
            src.D_INV_CLINICAL_KEY,
            src.D_INV_COMPLICATION_KEY,
            src.D_INV_CONTACT_KEY,
            src.D_INV_DEATH_KEY,
            src.D_INV_EPIDEMIOLOGY_KEY,
            src.D_INV_HIV_KEY,
            src.D_INV_PATIENT_OBS_KEY,
            src.D_INV_ISOLATE_TRACKING_KEY,
            src.D_INV_LAB_FINDING_KEY,
            src.D_INV_MEDICAL_HISTORY_KEY,
            src.D_INV_MOTHER_KEY,
            src.D_INV_OTHER_KEY,
            src.D_INV_PREGNANCY_BIRTH_KEY,
            src.D_INV_RESIDENCY_KEY,
            src.D_INV_RISK_FACTOR_KEY,
            src.D_INV_SOCIAL_HISTORY_KEY,
            src.D_INV_SYMPTOM_KEY,
            src.D_INV_TREATMENT_KEY,
            src.D_INV_TRAVEL_KEY,
            src.D_INV_UNDER_CONDITION_KEY,
            src.D_INV_VACCINATION_KEY,
            src.D_INVESTIGATION_REPEAT_KEY,
            src.D_INV_PLACE_REPEAT_KEY,
            src.CONDITION_KEY,
            src.INVESTIGATION_KEY,
            src.PHYSICIAN_KEY,
            src.INVESTIGATOR_KEY,
            src.HOSPITAL_KEY,
            src.PATIENT_KEY,
            src.PERSON_AS_REPORTER_KEY,
            src.ORG_AS_REPORTER_KEY,
            src.ORDERING_FACILITY_KEY,
            src.GEOCODING_LOCATION_KEY,
            src.CLOSED_BY_KEY,
            src.DISPOSITIONED_BY_KEY,
            src.FACILITY_FLD_FOLLOW_UP_KEY,
            src.INVSTGTR_FLD_FOLLOW_UP_KEY,
            src.PROVIDER_FLD_FOLLOW_UP_KEY,
            src.SUPRVSR_OF_FLD_FOLLOW_UP_KEY,
            src.INIT_ASGNED_FLD_FOLLOW_UP_KEY,
            src.INIT_FOLLOW_UP_INVSTGTR_KEY,
            src.INIT_ASGNED_INTERVIEWER_KEY,
            src.INTERVIEWER_ASSIGNED_KEY,
            src.SURVEILLANCE_INVESTIGATOR_KEY,
            src.SUPRVSR_OF_CASE_ASSGNMENT_KEY,
            src.DELIVERING_HOSP_KEY,
            src.DELIVERING_MD_KEY,
            src.MOTHER_OB_GYN_KEY,
            src.PEDIATRICIAN_KEY,
            src.ADD_DATE_KEY,
            src.LAST_CHG_DATE_KEY
        from
            #F_STD_PAGE_CASE_TEMP_INC src
                left join
            dbo.F_STD_PAGE_CASE tgt
            on src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY
        where src.INVESTIGATION_KEY is not null and tgt.INVESTIGATION_KEY is null;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,@dataflow_name,@package_name,'START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);




        /**
          This code moved as is from Classic ETL SQL
        This should cover any issue with defect https://nbscentral.sramanaged.com/redmine/issues/12555
        ETL Error in Dynamic Datamarts Process - Problem Record(s) Causing Million+ Rows in Dynamic Datamart (Total Should Be a Few Thousand)
        */
        DELETE FROM dbo.F_STD_PAGE_CASE WHERE INVESTIGATION_KEY IN (SELECT INVESTIGATION_KEY FROM dbo.F_STD_PAGE_CASE
                                                                    GROUP BY INVESTIGATION_KEY HAVING COUNT(INVESTIGATION_KEY)>1) AND PATIENT_KEY =1;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,@dataflow_name,@package_name,'START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

    COMMIT TRANSACTION;


    SET @PROC_STEP_NO =  999 ;
            SET @Proc_Step_Name = 'SP_COMPLETE';

    INSERT INTO dbo.[job_flow_log]
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type] ,[step_number],[step_name],[row_count])
    VALUES
        (@batch_id,@dataflow_name,@package_name,'COMPLETE',@Proc_Step_no,@Proc_Step_name,@RowCount_no);



END TRY

BEGIN CATCH

IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

		DECLARE @ErrorNumber INT = ERROR_NUMBER();
		DECLARE @ErrorLine INT = ERROR_LINE();
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();


INSERT INTO dbo.[job_flow_log] (
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
        ,'Case Count'
        ,'Case Count'
        ,'ERROR'
        ,@Proc_Step_no
        ,'ERROR - '+ @Proc_Step_name
        , 'Step -' +CAST(@Proc_Step_no AS VARCHAR(3))+' -' +CAST(@ErrorMessage AS VARCHAR(500))
        ,0
    );


return -1 ;

END CATCH

END
;