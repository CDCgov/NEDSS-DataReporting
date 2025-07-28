IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_var_datamart_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_var_datamart_postprocessing]
END
GO 

CREATE PROCEDURE dbo.sp_var_datamart_postprocessing 
@phc_uids nvarchar(max),
@debug bit = 'false'
AS
BEGIN
    BEGIN TRY
        /* Logging */
            declare @RowCount_no bigint;
            declare @proc_step_no float = 0;
            declare @proc_step_name varchar(200) = '';
            declare @batch_id bigint;
            declare @dataflow_name varchar(200) = 'var_datamart POST-Processing';
            declare @package_name varchar(200) = 'sp_var_datamart_postprocessing';
                set @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);

        SELECT @ROWCOUNT_NO = 0;

        SET @Proc_Step_Name = 'SP_Start';

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT], [Msg_Description1])
        VALUES (@BATCH_ID, @dataflow_name, @package_name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO, LEFT (@phc_uids, 199));

--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #S_PHC_LIST TABLE';
                
        IF OBJECT_ID('#S_PHC_LIST', 'U') IS NOT NULL
            drop table #S_PHC_LIST;

        SELECT DISTINCT value
        INTO  #S_PHC_LIST
        FROM STRING_SPLIT(@phc_uids, ',');
        
        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
            
--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING S_INVESTIGATION_LIST_DEL TABLE';
          
        IF OBJECT_ID('#S_INVESTIGATION_LIST_DEL', 'U') IS NOT NULL
            DROP TABLE #S_INVESTIGATION_LIST_DEL;

        SELECT DISTINCT
            inv.CASE_UID as VAR_PAM_UID,
            inv.INVESTIGATION_KEY
        INTO  #S_INVESTIGATION_LIST_DEL
        FROM #S_PHC_LIST phc
        INNER JOIN [dbo].INVESTIGATION inv WITH (NOLOCK)
            ON inv.CASE_UID = phc.value
        WHERE UPPER(inv.RECORD_STATUS_CD) = 'INACTIVE';

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #S_INVESTIGATION_LIST_DEL;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);

--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETE INCOMING INACTIVE RECORDS';

        BEGIN TRANSACTION

            -- 24. DELETE DELETED RECORDS
            DELETE T
            FROM [dbo].VAR_DATAMART T
            INNER JOIN #S_INVESTIGATION_LIST_DEL S 
                ON S.INVESTIGATION_KEY = T.INVESTIGATION_KEY;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #S_INVESTIGATION_LIST_DEL;

           INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);

        COMMIT TRANSACTION;

--------------------------------------------------------------------------------------------------------  
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #DMBASE TABLE';
                
        IF OBJECT_ID('#DMBASE', 'U') IS NOT NULL
            drop table #DMBASE;

        SELECT distinct D_VAR_PAM.D_VAR_PAM_KEY
        INTO  #DMBASE
        from [dbo].nrt_investigation I  with (nolock)
        INNER JOIN #S_PHC_LIST PHC_LIST
            on I.PUBLIC_HEALTH_CASE_UID = PHC_LIST.value
        inner join dbo.NRT_SRTE_condition_code cc with (nolock) 
            on I.cd = cc.condition_cd 
            and  cc.condition_cd = '10030'
            and cc.PORT_REQ_IND_CD = 'T' 
        inner join dbo.D_VAR_PAM D_VAR_PAM  with (nolock)
        ON D_VAR_PAM.VAR_PAM_UID = I.PUBLIC_HEALTH_CASE_UID;
        
        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
            
--------------------------------------------------------------------------------------------------------
 
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #PATIENT TABLE';
          
        IF OBJECT_ID('#PATIENT', 'U') IS NOT NULL
            drop table #PATIENT;
        
        -- PATIENT table
        SELECT 
            f.PERSON_KEY,
            p.PATIENT_PHONE_HOME AS PATIENT_PHONE_NUMBER_HOME,
            p.PATIENT_PHONE_EXT_HOME AS PATIENT_PHONE_EXT_HOME,
            p.PATIENT_PHONE_WORK AS PATIENT_PHONE_NUMBER_WORK,
            p.PATIENT_PHONE_EXT_WORK AS PATIENT_PHONE_EXT_WORK,
            p.PATIENT_LOCAL_ID AS PATIENT_LOCAL_ID,
            p.PATIENT_GENERAL_COMMENTS AS PATIENT_GENERAL_COMMENTS,
            p.PATIENT_LAST_NAME AS PATIENT_LAST_NAME,
            p.PATIENT_FIRST_NAME AS PATIENT_FIRST_NAME,
            p.PATIENT_MIDDLE_NAME AS PATIENT_MIDDLE_NAME,
            p.PATIENT_NAME_SUFFIX AS PATIENT_NAME_SUFFIX,
            p.PATIENT_DOB AS PATIENT_DOB,
            p.PATIENT_AGE_REPORTED AS AGE_REPORTED,
            p.PATIENT_AGE_REPORTED_UNIT AS AGE_REPORTED_UNIT,
            p.PATIENT_CURRENT_SEX AS PATIENT_CURRENT_SEX,
            p.PATIENT_DECEASED_INDICATOR AS PATIENT_DECEASED_INDICATOR,
            p.PATIENT_DECEASED_DATE AS PATIENT_DECEASED_DATE,
            p.PATIENT_MARITAL_STATUS AS PATIENT_MARITAL_STATUS,
            p.PATIENT_SSN,
            p.PATIENT_ETHNICITY AS PATIENT_ETHNICITY,
            p.PATIENT_STREET_ADDRESS_1 AS PATIENT_STREET_ADDRESS_1,
            p.PATIENT_STREET_ADDRESS_2 AS PATIENT_STREET_ADDRESS_2,
            p.PATIENT_CITY AS PATIENT_CITY,
            p.PATIENT_STATE AS PATIENT_STATE,
            p.PATIENT_ZIP AS PATIENT_ZIP,
            p.PATIENT_COUNTY AS PATIENT_COUNTY,
            p.PATIENT_COUNTRY AS PATIENT_COUNTRY,
            p.PATIENT_WITHIN_CITY_LIMITS AS WITHIN_CITY_LIMITS,
            p.PATIENT_RACE_CALC_DETAILS AS RACE_CALC_DETAILS,
            p.PATIENT_RACE_CALCULATED AS RACE_CALCULATED
        INTO #PATIENT 
        FROM dbo.f_VAR_PAM f with (nolock)
        INNER JOIN #DMBASE DM ON
        DM.D_VAR_PAM_KEY = f.D_VAR_PAM_KEY
        LEFT OUTER JOIN dbo.d_patient p with (nolock)
            ON p.patient_key = f.person_key;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #PATIENT;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
    
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #PROVIDER TABLE';
          
        
        IF OBJECT_ID('#PROVIDER', 'U') IS NOT NULL
            drop table #PROVIDER;
        
        -- PROVIDER table
        SELECT 
            f.PERSON_KEY,
            p.PROVIDER_LAST_NAME AS INVESTIGATOR_LAST_NAME,
            p.PROVIDER_FIRST_NAME AS INVESTIGATOR_FIRST_NAME,
            p.PROVIDER_PHONE_WORK AS INVESTIGATOR_PHONE_NUMBER,
            f.provider_key
        INTO #PROVIDER
        FROM dbo.f_VAR_pam f with (nolock)
        INNER JOIN #DMBASE DM ON
            DM.D_VAR_PAM_KEY = f.D_VAR_PAM_KEY
        LEFT OUTER JOIN dbo.D_PROVIDER p with (nolock)
            ON p.PROVIDER_key = f.provider_key;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #PROVIDER;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #PHYSICIAN TABLE';
          
        
        IF OBJECT_ID('#PHYSICIAN', 'U') IS NOT NULL
            drop table #PHYSICIAN;

        -- PHYSICIAN table
        SELECT 
            f.PERSON_KEY,
            p.PROVIDER_LAST_NAME AS PHYSICIAN_LAST_NAME,
            p.PROVIDER_FIRST_NAME AS PHYSICIAN_FIRST_NAME,
            p.PROVIDER_PHONE_WORK AS PHYSICIAN_PHONE_NUMBER,
            f.PHYSICIAN_KEY
        INTO #PHYSICIAN
        FROM dbo.F_VAR_PAM f with (nolock)
        INNER JOIN #DMBASE DM ON
        DM.D_VAR_PAM_KEY = f.D_VAR_PAM_KEY
        LEFT OUTER JOIN dbo.D_PROVIDER p with (nolock)
            ON p.PROVIDER_KEY = f.PHYSICIAN_KEY;        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #PHYSICIAN;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #REPORTER TABLE';
          
        
        IF OBJECT_ID('#REPORTER', 'U') IS NOT NULL
            drop table #REPORTER;
        
        -- REPORTER table
        SELECT 
            f.PERSON_KEY,
            r.PROVIDER_LAST_NAME AS REPORTER_LAST_NAME,
            r.PROVIDER_FIRST_NAME AS REPORTER_FIRST_NAME,
            f.PERSON_AS_REPORTER_KEY,
            r.PROVIDER_PHONE_WORK AS REPORTER_PHONE_NUMBER
        INTO #REPORTER
        FROM dbo.F_VAR_PAM f with (nolock)
        INNER JOIN #DMBASE DM 
            ON DM.D_VAR_PAM_KEY = f.D_VAR_PAM_KEY
        LEFT OUTER JOIN dbo.D_PROVIDER r with (nolock)
            ON r.PROVIDER_KEY = f.PERSON_AS_REPORTER_KEY;        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #REPORTER;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
    
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #ORG_REPORTER TABLE';
          
        IF OBJECT_ID('#ORG_REPORTER', 'U') IS NOT NULL
            drop table #ORG_REPORTER;
        
        -- ORG_REPORTER table
        SELECT 
            f.PERSON_KEY,
            o.ORGANIZATION_NAME AS REPORTING_SOURCE_NAME,
            f.ORG_AS_REPORTER_KEY AS ORG_AS_REPORTER_key
        INTO #ORG_REPORTER
        FROM dbo.F_VAR_PAM f with (nolock)
        INNER JOIN #DMBASE DM ON
            DM.D_VAR_PAM_KEY = f.D_VAR_PAM_KEY
        LEFT OUTER JOIN dbo.D_ORGANIZATION o with (nolock)
            ON o.ORGANIZATION_KEY = f.ORG_AS_REPORTER_KEY;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #ORG_REPORTER;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
    
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #HOSPITAL TABLE';
          
        
        IF OBJECT_ID('#HOSPITAL', 'U') IS NOT NULL
            drop table #HOSPITAL;
        
        -- HOSPITAL table
        SELECT 
            f.PERSON_KEY,
            o.ORGANIZATION_NAME AS HOSPITAL_NAME,
            f.hospital_key
        INTO #HOSPITAL
        FROM dbo.F_VAR_PAM f with (nolock)
        INNER JOIN #DMBASE DM ON
            DM.D_VAR_PAM_KEY = f.D_VAR_PAM_KEY
        LEFT OUTER JOIN dbo.D_ORGANIZATION o with (nolock)
            ON o.ORGANIZATION_KEY = f.hospital_key;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #HOSPITAL;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
    
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #ENTITY_LOCATION TABLE';
          
        IF OBJECT_ID('#ENTITY_LOCATION', 'U') IS NOT NULL
            drop table #ENTITY_LOCATION;

        -- ENTITY_LOCATION table
        SELECT 
            p.AGE_REPORTED,
            h.HOSPITAL_KEY,
            h.HOSPITAL_NAME,
            pr.INVESTIGATOR_FIRST_NAME,
            pr.INVESTIGATOR_LAST_NAME,
            pr.INVESTIGATOR_PHONE_NUMBER,
            o.REPORTING_SOURCE_NAME,
            p.AGE_REPORTED_UNIT,
            p.PATIENT_CITY,
            p.PATIENT_COUNTRY,
            p.PATIENT_COUNTY,
            p.PATIENT_DECEASED_DATE,
            p.PATIENT_DECEASED_INDICATOR,
            p.PATIENT_DOB,
            p.PATIENT_ETHNICITY,
            p.PATIENT_FIRST_NAME,
            p.PATIENT_GENERAL_COMMENTS,
            p.PATIENT_LAST_NAME,
            p.PATIENT_LOCAL_ID,
            p.PATIENT_MARITAL_STATUS,
            p.PATIENT_MIDDLE_NAME,
            p.PATIENT_NAME_SUFFIX,
            p.PATIENT_PHONE_EXT_HOME,
            p.PATIENT_PHONE_EXT_WORK,
            p.PATIENT_PHONE_NUMBER_HOME,
            p.PATIENT_PHONE_NUMBER_WORK,
            p.PATIENT_SSN,
            p.PATIENT_STATE,
            p.PATIENT_STREET_ADDRESS_1,
            p.PATIENT_STREET_ADDRESS_2,
            p.PATIENT_ZIP,
            r.PERSON_AS_REPORTER_KEY,
            p.PATIENT_CURRENT_SEX,
            p.PERSON_KEY,
            ph.PHYSICIAN_FIRST_NAME,
            ph.PHYSICIAN_KEY,
            ph.PHYSICIAN_LAST_NAME,
            ph.PHYSICIAN_PHONE_NUMBER,
            pr.provider_key AS PROVIDER_KEY,
            p.RACE_CALCULATED,
            p.RACE_CALC_DETAILS,
            r.REPORTER_FIRST_NAME,
            r.REPORTER_LAST_NAME,
            r.REPORTER_PHONE_NUMBER,
            p.WITHIN_CITY_LIMITS
        INTO #ENTITY_LOCATION
        FROM #PATIENT p
        INNER JOIN #PROVIDER pr ON pr.PERSON_key = p.PERSON_key
        INNER JOIN #PHYSICIAN ph ON ph.PERSON_KEY = p.PERSON_KEY
        INNER JOIN #REPORTER r ON r.PERSON_KEY = p.PERSON_KEY
        INNER JOIN #ORG_REPORTER o ON p.PERSON_KEY = o.PERSON_KEY
        INNER JOIN #HOSPITAL h ON p.PERSON_KEY = h.PERSON_key;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #ENTITY_LOCATION;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #INVESTIGATION TABLE';
          
        IF OBJECT_ID('#INVESTIGATION', 'U') IS NOT NULL
            drop table #INVESTIGATION;
        
        -- INVESTIGATION table
        SELECT 
             i.CASE_OID AS PROGRAM_JURISDICTION_OID,
                i.CASE_RPT_MMWR_WK AS MMWR_WEEK,
                i.CASE_RPT_MMWR_YR AS MMWR_YEAR,
                i.INV_COMMENTS AS GENERAL_COMMENTS,
                i.INV_STATE_CASE_ID AS STATE_CASE_NUMBER,
                i.CITY_COUNTY_CASE_NBR AS city_county_case_number,
                i.INV_START_DT AS INVESTIGATION_START_DATE,
                i.INVESTIGATION_key AS INVESTIGATION_KEY,
                i.INVESTIGATION_STATUS AS INVESTIGATION_STATUS,
                i.JURISDICTION_NM AS JURISDICTION_NAME,
                i.CITY_COUNTY_CASE_NBR AS CITY_COUNTY_CASE_NBR,
                i.Inv_Rpt_Dt AS DATE_REPORTED,
                i.Earliest_Rpt_To_State_Dt AS DATE_SUBMITTED,
                i.HSPTLIZD_IND AS HOSPITALIZED,
                i.HSPTL_ADMISSION_DT AS HOSPITALIZED_ADMISSION_DATE,
                i.HSPTL_DISCHARGE_DT AS HOSPITALIZED_DISCHARGE_DATE,
                i.HSPTL_DURATION_DAYS AS HOSPITALIZED_DURATION_DAYS,
                i.ILLNESS_ONSET_DT AS ILLNESS_ONSET_DATE,
                i.DIAGNOSIS_DT AS DIAGNOSIS_DATE,
                i.EARLIEST_RPT_TO_STATE_DT AS DATE_REPORTED_TO_STATE,
                i.EARLIEST_RPT_TO_CNTY_DT AS DATE_REPORTED_TO_COUNTY,
                i.INV_CASE_STATUS AS CASE_STATUS,
                i.OUTBREAK_IND AS OUTBREAK,
                i.OUTBREAK_NAME AS OUTBREAK_CD,
                i.INV_ASSIGNED_DT AS INVESTIGATOR_ASSIGN_DATE,
                i.PATIENT_AGE_AT_ONSET_UNIT AS ILLNESS_ONSET_AGE_UNIT,
                i.PATIENT_AGE_AT_ONSET AS ILLNESS_ONSET_AGE,
                i.PATIENT_PREGNANT_IND AS PREGNANT,
                i.INVESTIGATION_DEATH_DATE AS INVESTIGATION_DEATH_DATE,
                i.DIE_FRM_THIS_ILLNESS_IND AS DIE_FRM_THIS_ILLNESS_IND,
                i.ILLNESS_END_DT AS ILLNESS_END_DATE,
                i.ILLNESS_DURATION AS ILLNESS_DURATION,
                i.ILLNESS_DURATION_UNIT AS ILLNESS_DURATION_UNIT,
                i.DAYCARE_ASSOCIATION_IND AS DAYCARE,
                i.FOOD_HANDLR_IND AS FOOD_HANDLER,
                i.DISEASE_IMPORTED_IND AS DISEASE_ACQUIRED_WHERE,
                i.IMPORT_FRM_CNTRY AS DISEASE_ACQUIRED_COUNTRY,
                i.IMPORT_FRM_STATE AS DISEASE_ACQUIRED_STATE,
                i.IMPORT_FRM_CITY AS DISEASE_ACQUIRED_CITY,
                i.IMPORT_FRM_CNTY AS DISEASE_ACQUIRED_COUNTY,
                i.TRANSMISSION_MODE AS TRANSMISSION_MODE,
                i.DETECTION_METHOD_DESC_TXT AS DETECTION_METHOD,
                i.RPT_SRC_CD_DESC AS REPORTING_SOURCE_TYPE,
                i.INVESTIGATION_KEY AS INVESTIGATION_KEY_DUP,
                i.CASE_UID
        INTO #INVESTIGATION
        FROM dbo.investigation i with (nolock)
        INNER JOIN dbo.F_VAR_PAM f with (nolock)
            ON i.INVESTIGATION_KEY = f.INVESTIGATION_KEY
        INNER JOIN #DMBASE DM ON
            DM.D_VAR_PAM_KEY = f.D_VAR_PAM_KEY
        WHERE i.RECORD_STATUS_CD = 'ACTIVE';
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #INVESTIGATION;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #BASE TABLE';
        
        IF OBJECT_ID('#BASE', 'U') IS NOT NULL
            drop table #BASE;
        
        -- BASE table
        SELECT 
         e.ADD_TIME AS INVESTIGATION_CREATE_DATE,
                e.ADD_USER_ID AS INVESTIGATION_CREATED_BY,
                e.LAST_CHG_USER_ID AS INVESTIGATION_LAST_UPDTD_BY,
                e.LAST_CHG_TIME AS INVESTIGATION_LAST_UPDTD_DATE,
                e.PROG_AREA_DESC_TXT AS PROGRAM_AREA_DESCRIPTION,
                e.LOCAL_ID AS INVESTIGATION_LOCAL_ID,
                i.*,
                d.VAR_PAM_UID,
                d.COMPLICATIONS,
                d.COMPLICATIONS_CEREB_ATAXIA,
                d.COMPLICATIONS_DEHYDRATION,
                d.COMPLICATIONS_ENCEPHALITIS,
                d.COMPLICATIONS_HEMORRHAGIC,
                d.COMPLICATIONS_OTHER,
                d.COMPLICATIONS_OTHER_SPECIFY,
                d.COMPLICATIONS_PNEU_DIAG_BY,
                d.COMPLICATIONS_PNEUMONIA,
                d.COMPLICATIONS_SKIN_INFECTION,
                d.CROPS_WAVES,
                d.CULTURE_TEST,
                d.CULTURE_TEST_DATE,
                d.CULTURE_TEST_RESULT,
                d.DEATH_AUTOPSY,
                d.DEATH_CAUSE,
                d.DFA_TEST,
                d.DFA_TEST_DATE,
                d.DFA_TEST_RESULT,
                d.EPI_LINKED,
                d.EPI_LINKED_CASE_TYPE,
                d.FEVER,
                d.FEVER_DURATION_DAYS,
                d.FEVER_ONSET_DATE AS FEVER_ONSET_DATE,
                d.FEVER_TEMPERATURE,
                d.FEVER_TEMPERATURE_UNIT,
                d.GENOTYPING_SENT_TO_CDC,
                d.GENOTYPING_SENT_TO_CDC_DATE,
                d.HEALTHCARE_WORKER,
                d.HEMORRHAGIC,
                d.IGG_TEST,
                d.IGG_TEST_ACUTE_DATE,
                d.IGG_TEST_ACUTE_RESULT,
                d.IGG_TEST_ACUTE_VALUE,
                d.IGG_TEST_CONVALESCENT_DATE,
                d.IGG_TEST_CONVALESCENT_RESULT,
                d.IGG_TEST_CONVALESCENT_VALUE,
                d.IGG_TEST_GP_ELISA_MFGR,
                d.IGG_TEST_OTHER,
                d.IGG_TEST_TYPE,
                d.IGG_TEST_WHOLE_CELL_MFGR,
                d.IGM_TEST,
                d.IGM_TEST_DATE,
                d.IGM_TEST_RESULT,
                d.IGM_TEST_RESULT_VALUE,
                d.IGM_TEST_TYPE,
                d.IGM_TEST_TYPE_OTHER,
                d.IMMUNOCOMPROMISED,
                d.IMMUNOCOMPROMISED_CONDITION,
                d.ITCHY,
                d.LAB_TESTING,
                d.LAB_TESTING_OTHER,
                d.LAB_TESTING_OTHER_DATE,
                d.LAB_TESTING_OTHER_RESULT,
                d.LAB_TESTING_OTHER_RESULT_VALUE,
                d.LAB_TESTING_OTHER_SPECIFY,
                d.LESIONS_TOTAL,
                d.LESIONS_TOTAL_LT50,
                d.MACULAR_PAPULAR,
                d.MACULES,
                d.MACULES_NUMBER,
                d.MEDICATION_NAME,
                d.MEDICATION_NAME_OTHER,
                d.MEDICATION_START_DATE,
                d.MEDICATION_STOP_DATE,
                d.PAPULES,
                d.PAPULES_NUMBER,
                d.PATIENT_BIRTH_COUNTRY,
                d.PATIENT_VISIT_HC_PROVIDER,
                d.PCR_TEST,
                d.PCR_TEST_DATE,
                d.PCR_TEST_RESULT,
                d.PCR_TEST_RESULT_OTHER,
                d.PCR_TEST_SOURCE_OTHER,
                d.PREGNANT_TRIMESTER,
                d.PREGNANT_WEEKS,
                d.PREVIOUS_DIAGNOSIS,
                d.PREVIOUS_DIAGNOSIS_AGE,
                d.PREVIOUS_DIAGNOSIS_AGE_UNIT,
                d.PREVIOUS_DIAGNOSIS_BY,
                d.PREVIOUS_DIAGNOSIS_BY_OTHER,
                d.RASH_CRUST,
                d.RASH_CRUSTED_DAYS,
                d.RASH_DURATION_DAYS,
                d.RASH_LOCATION,
                d.RASH_LOCATION_DERMATOME,
                d.RASH_LOCATION_OTHER,
                d.RASH_ONSET_DATE,
                d.SCABS,
                d.SEROLOGY_TEST,
                d.STRAIN_IDENTIFICATION_SENT,
                d.STRAIN_TYPE,
                d.TRANSMISSION_SETTING,
                d.TRANSMISSION_SETTING_OTHER,
                d.TREATED,
                d.VACCINE_DATE_1,
                d.VACCINE_DATE_2,
                d.VACCINE_DATE_3,
                d.VACCINE_DATE_4,
                d.VACCINE_DATE_5,
                d.VACCINE_LOT_1,
                d.VACCINE_LOT_2,
                d.VACCINE_LOT_3,
                d.VACCINE_LOT_4,
                d.VACCINE_LOT_5,
                d.VACCINE_MANUFACTURER_1,
                d.VACCINE_MANUFACTURER_2,
                d.VACCINE_MANUFACTURER_3,
                d.VACCINE_MANUFACTURER_4,
                d.VACCINE_MANUFACTURER_5,
                d.VACCINE_TYPE_1,
                d.VACCINE_TYPE_2,
                d.VACCINE_TYPE_3,
                d.VACCINE_TYPE_4,
                d.VACCINE_TYPE_5,
                d.VARICELLA_NO_2NDVACCINE_OTHER,
                d.VARICELLA_NO_2NDVACCINE_REASON,
                d.VARICELLA_NO_VACCINE_OTHER,
                d.VARICELLA_NO_VACCINE_REASON,
                d.VARICELLA_VACCINE,
                d.VARICELLA_VACCINE_DOSES_NUMBER,
                d.VESICLES,
                d.VESICLES_NUMBER,
                d.VESICULAR,
                f.D_PCR_SOURCE_GROUP_KEY,
                f.D_RASH_LOC_GEN_GROUP_KEY,
                f.person_key,
                f.provider_key
        INTO #BASE
        FROM dbo.f_VAR_pam f with (nolock)
        INNER JOIN dbo.D_VAR_PAM d with (nolock) ON f.d_VAR_pam_key = d.d_VAR_pam_key
        INNER JOIN #INVESTIGATION i ON f.INVESTIGATION_KEY = i.INVESTIGATION_KEY
        INNER JOIN dbo.EVENT_METRIC e with (nolock) ON e.EVENT_UID = d.VAR_PAM_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #BASE;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #BASE_TRANSLATED TABLE';
          
        
        IF OBJECT_ID('#BASE_TRANSLATED', 'U') IS NOT NULL
            drop table #BASE_TRANSLATED;
        
        -- BASE_TRANSLATED table
        SELECT 
            b.*,
            c.CODE,
            c.CODE_SHORT_DESC_TXT AS OUTBREAK_NAME
        INTO #BASE_TRANSLATED
        FROM #BASE b
        LEFT JOIN dbo.NRT_SRTE_CODE_VALUE_GENERAL c with (nolock)
            ON c.CODE = b.OUTBREAK_CD
            AND c.CODE_SET_NM = 'OUTBREAK_NM';
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #BASE_TRANSLATED;
        
        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #INIT TABLE';
          
        IF OBJECT_ID('#INIT', 'U') IS NOT NULL
            drop table #INIT;
        
        -- INIT table 
            SELECT B.*, E.AGE_REPORTED, E.HOSPITAL_KEY, E.HOSPITAL_NAME, E.INVESTIGATOR_FIRST_NAME, E.INVESTIGATOR_LAST_NAME, E.INVESTIGATOR_PHONE_NUMBER, 
                E.REPORTING_SOURCE_NAME, E.AGE_REPORTED_UNIT, E.PATIENT_CITY, E.PATIENT_COUNTRY, E.PATIENT_COUNTY, E.PATIENT_DECEASED_DATE, E.PATIENT_DECEASED_INDICATOR, E.PATIENT_DOB, E.PATIENT_ETHNICITY, E.PATIENT_FIRST_NAME, 
                E.PATIENT_GENERAL_COMMENTS, E.PATIENT_LAST_NAME, E.PATIENT_LOCAL_ID, E.PATIENT_MARITAL_STATUS, E.PATIENT_MIDDLE_NAME, E.PATIENT_NAME_SUFFIX, E.PATIENT_PHONE_EXT_HOME, E.PATIENT_PHONE_EXT_WORK, E.PATIENT_PHONE_NUMBER_HOME, 
                E.PATIENT_PHONE_NUMBER_WORK, E.PATIENT_SSN, E.PATIENT_STATE, E.PATIENT_STREET_ADDRESS_1, E.PATIENT_STREET_ADDRESS_2, E.PATIENT_ZIP, E.PERSON_AS_REPORTER_KEY, E.PATIENT_CURRENT_SEX, E.PHYSICIAN_FIRST_NAME, E.PHYSICIAN_KEY, 
                E.PHYSICIAN_LAST_NAME, E.PHYSICIAN_PHONE_NUMBER, E.RACE_CALCULATED, E.RACE_CALC_DETAILS, E.REPORTER_FIRST_NAME, E.REPORTER_LAST_NAME, E.REPORTER_PHONE_NUMBER, E.WITHIN_CITY_LIMITS
            INTO #init
            FROM #BASE_TRANSLATED b
            LEFT OUTER JOIN #entity_location e ON e.PERSON_KEY = b.PERSON_KEY;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #INIT;
        
        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #D_PCR_SOURCE TABLE';
          
        IF OBJECT_ID('#D_PCR_SOURCE', 'U') IS NOT NULL
            drop table #D_PCR_SOURCE;

        -- D_PCR_SOURCE processing
        SELECT PCR.*
        INTO #D_PCR_SOURCE
        FROM D_PCR_SOURCE PCR with (nolock)
        INNER JOIN D_VAR_PAM DVP with (nolock)
            ON PCR.VAR_PAM_UID = DVP.VAR_PAM_UID
        INNER JOIN #DMBASE BASE 
            ON BASE.D_VAR_PAM_KEY = DVP.D_VAR_PAM_KEY;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #D_PCR_SOURCE;
        
        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
    
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #D_PCR_SOURCE_OUT TABLE';
          
        IF OBJECT_ID('#D_PCR_SOURCE_OUT', 'U') IS NOT NULL
            drop table #D_PCR_SOURCE_OUT;
        
        -- PCR Source transformation (replacing DATA step)
        SELECT 
            D_PCR_SOURCE_GROUP_KEY,
            STRING_AGG(value, ' | ') AS PCR_TEST_SOURCE_ALL,
            MAX(CASE WHEN rn = 1 THEN value END) AS PCR_TEST_SOURCE_1,
            MAX(CASE WHEN rn = 2 THEN value END) AS PCR_TEST_SOURCE_2,
            MAX(CASE WHEN rn = 3 THEN value END) AS PCR_TEST_SOURCE_3,
            MAX(CASE WHEN rn = 4 THEN value END) AS PCR_TEST_SOURCE_4,
            CASE WHEN MAX(CASE WHEN rn = 4 THEN 1 END) = 1 THEN 'TRUE' ELSE 'FALSE' END AS PCR_TEST_SOURCE_GT3_IND
        INTO #D_PCR_SOURCE_OUT
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY D_PCR_SOURCE_GROUP_KEY ORDER BY value) AS rn
            FROM #D_PCR_SOURCE
        ) t
        GROUP BY D_PCR_SOURCE_GROUP_KEY;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #D_PCR_SOURCE_OUT;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #D_RASH_LOC_GEN TABLE';
        
        IF OBJECT_ID('#D_RASH_LOC_GEN', 'U') IS NOT NULL
            drop table #D_RASH_LOC_GEN;

        -- Similar transformation for D_RASH_LOC_GEN
        SELECT RLG.*
        INTO #D_RASH_LOC_GEN
        FROM dbo.D_RASH_LOC_GEN RLG with (nolock)
        INNER JOIN dbo.D_VAR_PAM DVP with (nolock)
            ON RLG.VAR_PAM_UID = DVP.VAR_PAM_UID
        INNER JOIN #DMBASE BASE 
            ON BASE.D_VAR_PAM_KEY = DVP.D_VAR_PAM_KEY;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #D_RASH_LOC_GEN;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
    
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #D_RASH_LOC_GEN_OUT TABLE';
          
        IF OBJECT_ID('#D_RASH_LOC_GEN_OUT', 'U') IS NOT NULL
            drop table #D_RASH_LOC_GEN_OUT;

        SELECT 
            D_RASH_LOC_GEN_GROUP_KEY,
            STRING_AGG(value, ' | ') AS RASH_LOCATION_GENERAL_ALL,
            MAX(CASE WHEN rn = 1 THEN value END) AS RASH_LOCATION_GENERAL_1,
            MAX(CASE WHEN rn = 2 THEN value END) AS RASH_LOCATION_GENERAL_2,
            MAX(CASE WHEN rn = 3 THEN value END) AS RASH_LOCATION_GENERAL_3,
            MAX(CASE WHEN rn = 4 THEN value END) AS RASH_LOCATION_GENERAL_4,
            CASE WHEN MAX(CASE WHEN rn = 4 THEN 1 END) = 1 THEN 'TRUE' ELSE 'FALSE' END AS RASH_LOCATION_GENERAL_GT3_IND
        INTO #D_RASH_LOC_GEN_OUT
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY D_RASH_LOC_GEN_GROUP_KEY ORDER BY value) AS rn
            FROM #D_RASH_LOC_GEN
        ) t
        GROUP BY D_RASH_LOC_GEN_GROUP_KEY;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #D_RASH_LOC_GEN_OUT;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
    
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CONFIRMATION_METHOD TABLE';
          
        IF OBJECT_ID('#CONFIRMATION_METHOD', 'U') IS NOT NULL
            drop table #CONFIRMATION_METHOD;
        
        -- CONFIRMATION_METHOD processing
        SELECT 
            cm.*,
            cmg.investigation_key,
            cmg.confirmation_dt
        INTO #CONFIRMATION_METHOD
        FROM DBO.confirmation_method cm with (nolock)
        JOIN DBO.confirmation_method_group cmg  with (nolock)
            ON cmg.confirmation_method_key = cm.confirmation_method_key
        JOIN DBO.investigation i with (nolock)
            ON cmg.investigation_key = i.investigation_key
        JOIN DBO.f_var_pam f with (nolock)
            ON f.investigation_key = i.investigation_key
        INNER JOIN #DMBASE BASE
            on f.D_VAR_PAM_KEY = BASE.D_VAR_PAM_KEY
        WHERE i.record_status_cd = 'ACTIVE';
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #CONFIRMATION_METHOD;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CONFIRMATION_METHOD_BASE TABLE';
        
        
        IF OBJECT_ID('#CONFIRMATION_METHOD_BASE', 'U') IS NOT NULL
            drop table #CONFIRMATION_METHOD_BASE;
        
        -- PIVOT for CONFIRMATION_METHOD
        SELECT *
        INTO #CONFIRMATION_METHOD_BASE
        FROM (
            SELECT investigation_key, confirmation_dt, CONFIRMATION_METHOD_DESC,
                'COL' + CAST(ROW_NUMBER() OVER (PARTITION BY investigation_key ORDER BY CONFIRMATION_METHOD_DESC) AS VARCHAR) AS col
            FROM #CONFIRMATION_METHOD
        ) AS SourceTable
        PIVOT (
            MAX(CONFIRMATION_METHOD_DESC)
            FOR col IN (COL1, COL2, COL3, COL4, COL5, COL6, COL7, COL8, COL9, COL10, COL11, COL12, COL13)
        ) AS PivotTable;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #CONFIRMATION_METHOD_BASE;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
    
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CONFIRMATION_METHOD_BASE_TEMP TABLE';
        
        IF OBJECT_ID('#CONFIRMATION_METHOD_BASE_TEMP', 'U') IS NOT NULL
            drop table #CONFIRMATION_METHOD_BASE_TEMP;

           -- Process CONFIRMATION_METHOD_BASE (replacing first DATA step)
            SELECT 
                *,
                CONCAT(COL1, ' | ', COL2, ' | ', COL3, ' | ', COL4, ' | ', COL5, ' | ', COL6, ' | ', COL7, ' | ', COL8, ' | ', COL9, ' | ', COL10, ' | ', COL11, ' | ', COL12, ' | ', COL13) AS CONFIRMATION_METHOD_ALL_TEMP,
                CASE 
                    WHEN CHARINDEX(' | .', CONCAT(COL1, ' | ', COL2, ' | ', COL3, ' | ', COL4, ' | ', COL5, ' | ', COL6, ' | ', COL7, ' | ', COL8, ' | ', COL9, ' | ', COL10, ' | ', COL11, ' | ', COL12, ' | ', COL13)) > 0 
                    THEN LEFT(CONCAT(COL1, ' | ', COL2, ' | ', COL3, ' | ', COL4, ' | ', COL5, ' | ', COL6, ' | ', COL7, ' | ', COL8, ' | ', COL9, ' | ', COL10, ' | ', COL11, ' | ', COL12, ' | ', COL13), 
                               CHARINDEX(' | .', CONCAT(COL1, ' | ', COL2, ' | ', COL3, ' | ', COL4, ' | ', COL5, ' | ', COL6, ' | ', COL7, ' | ', COL8, ' | ', COL9, ' | ', COL10, ' | ', COL11, ' | ', COL12, ' | ', COL13)))
                    ELSE CONCAT(COL1, ' | ', COL2, ' | ', COL3, ' | ', COL4, ' | ', COL5, ' | ', COL6, ' | ', COL7, ' | ', COL8, ' | ', COL9, ' | ', COL10, ' | ', COL11, ' | ', COL12, ' | ', COL13)
                END AS CONFIRMATION_METHOD_ALL
            INTO #CONFIRMATION_METHOD_BASE_TEMP
            FROM #CONFIRMATION_METHOD_BASE;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #CONFIRMATION_METHOD_BASE_TEMP;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CONFIRMATION_METHOD_BASE2 TABLE';
        
        IF OBJECT_ID('#CONFIRMATION_METHOD_BASE2', 'U') IS NOT NULL
            drop table #CONFIRMATION_METHOD_BASE2;
        
            -- Process CONFIRMATION_METHOD_BASE (replacing second DATA step)
            SELECT 
                *,
                CASE WHEN LEN(COL1) > 2 THEN COL1 ELSE NULL END AS CONFIRMATION_METHOD_1,
                CASE WHEN LEN(COL2) > 2 THEN COL2 ELSE NULL END AS CONFIRMATION_METHOD_2,
                CASE WHEN LEN(COL3) > 2 THEN COL3 ELSE NULL END AS CONFIRMATION_METHOD_3,
                CASE WHEN LEN(COL4) > 2 THEN COL4 ELSE NULL END AS CONFIRMATION_METHOD_4,
                CASE WHEN LEN(LTRIM(RTRIM(COL4))) > 3 THEN 'True' ELSE 'False' END AS CONFIRMATION_METHOD_GT3_IND
            INTO #CONFIRMATION_METHOD_BASE2
            FROM #CONFIRMATION_METHOD_BASE_TEMP;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #CONFIRMATION_METHOD_BASE2;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
    
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CONFIRMATION_METHOD_OUT TABLE';
        
        IF OBJECT_ID('#CONFIRMATION_METHOD_OUT', 'U') IS NOT NULL
            drop table #CONFIRMATION_METHOD_OUT;
        
                -- Create CONFIRMATION_METHOD_OUT table
            SELECT 
                CONFIRMATION_METHOD_1,
                CONFIRMATION_METHOD_2,
                CONFIRMATION_METHOD_3,
                CONFIRMATION_METHOD_GT3_IND,
                CONFIRMATION_METHOD_ALL,
                confirmation_dt AS CONFIRMATION_DT,
                investigation_key
            INTO #CONFIRMATION_METHOD_OUT
            FROM #CONFIRMATION_METHOD_BASE2
            WHERE LEN(CONFIRMATION_METHOD_ALL) > 0;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #CONFIRMATION_METHOD_OUT;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
    
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #VAR_DATAMART_INIT TABLE';
          
        IF OBJECT_ID('#VAR_DATAMART_INIT', 'U') IS NOT NULL
            drop table #VAR_DATAMART_INIT;
        
        -- VAR_DATAMART_init
        SELECT 
            i.*,
            r.RASH_LOCATION_GENERAL_1,
            r.RASH_LOCATION_GENERAL_2,
            r.RASH_LOCATION_GENERAL_3,
            p.PCR_TEST_SOURCE_1,
            p.PCR_TEST_SOURCE_2,
            p.PCR_TEST_SOURCE_3,
            r.RASH_LOCATION_GENERAL_GT3_IND,
            p.PCR_TEST_SOURCE_GT3_IND,
            p.PCR_TEST_SOURCE_ALL,
            r.RASH_LOCATION_GENERAL_ALL,
            c.CONFIRMATION_METHOD_1,
            c.CONFIRMATION_METHOD_2,
            c.CONFIRMATION_METHOD_3,
            c.CONFIRMATION_METHOD_GT3_IND,
            c.CONFIRMATION_METHOD_ALL,
            c.CONFIRMATION_DT AS CONFIRMATION_DATE
        INTO #VAR_DATAMART_INIT
        FROM #INIT i
        LEFT JOIN #D_RASH_LOC_GEN_OUT r
            ON i.D_RASH_LOC_GEN_GROUP_KEY = r.D_RASH_LOC_GEN_GROUP_KEY
        LEFT JOIN #D_PCR_SOURCE_OUT p
            ON i.D_PCR_SOURCE_GROUP_KEY = p.D_PCR_SOURCE_GROUP_KEY
        LEFT JOIN #CONFIRMATION_METHOD_OUT c
            ON i.INVESTIGATION_KEY = c.INVESTIGATION_KEY;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #VAR_DATAMART_INIT;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
    
--------------------------------------------------------------------------------------------------------
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #VAR_DATAMART_NOT_EVENT TABLE';
          
        IF OBJECT_ID('#VAR_DATAMART_NOT_EVENT', 'U') IS NOT NULL
            drop table #VAR_DATAMART_NOT_EVENT;

        -- VAR_DATAMART_not_event with notification details
        SELECT 
            V.INVESTIGATION_CREATE_DATE, 
            V.INVESTIGATION_LAST_UPDTD_DATE, 
            V.PROGRAM_AREA_DESCRIPTION, 
            V.INVESTIGATION_LOCAL_ID, 
            V.PROGRAM_JURISDICTION_OID, 
            V.MMWR_WEEK, 
            V.MMWR_YEAR, 
            V.GENERAL_COMMENTS, 
            V.STATE_CASE_NUMBER, 
            V.city_county_case_number, 
            V.INVESTIGATION_START_DATE, 
            V.INVESTIGATION_KEY, 
            V.INVESTIGATION_STATUS, 
            V.JURISDICTION_NAME, 
            V.CITY_COUNTY_CASE_NBR, 
            V.DATE_REPORTED, 
            V.DATE_SUBMITTED, 
            V.HOSPITALIZED, 
            V.HOSPITALIZED_ADMISSION_DATE, 
            V.HOSPITALIZED_DISCHARGE_DATE, 
            V.HOSPITALIZED_DURATION_DAYS, 
            V.ILLNESS_ONSET_DATE, 
            V.DIAGNOSIS_DATE, 
            V.DATE_REPORTED_TO_STATE, 
            V.DATE_REPORTED_TO_COUNTY, 
            V.CASE_STATUS, 
            V.OUTBREAK, 
            V.OUTBREAK_CD, 
            V.INVESTIGATOR_ASSIGN_DATE, 
            V.ILLNESS_ONSET_AGE_UNIT, 
            V.ILLNESS_ONSET_AGE, 
            V.PREGNANT, 
            V.INVESTIGATION_DEATH_DATE, 
            V.DIE_FRM_THIS_ILLNESS_IND, 
            V.ILLNESS_END_DATE, 
            V.ILLNESS_DURATION, 
            V.ILLNESS_DURATION_UNIT, 
            V.DAYCARE, 
            V.FOOD_HANDLER, 
            V.DISEASE_ACQUIRED_WHERE, 
            V.DISEASE_ACQUIRED_COUNTRY, 
            V.DISEASE_ACQUIRED_STATE, 
            V.DISEASE_ACQUIRED_CITY, 
            V.DISEASE_ACQUIRED_COUNTY, 
            V.TRANSMISSION_MODE, 
            V.DETECTION_METHOD, 
            V.REPORTING_SOURCE_TYPE, 
            V.INVESTIGATION_KEY_DUP, 
            V.CASE_UID, 
            V.VAR_PAM_UID, 
            V.COMPLICATIONS, 
            V.COMPLICATIONS_CEREB_ATAXIA, 
            V.COMPLICATIONS_DEHYDRATION, 
            V.COMPLICATIONS_ENCEPHALITIS, 
            V.COMPLICATIONS_HEMORRHAGIC, 
            V.COMPLICATIONS_OTHER, 
            V.COMPLICATIONS_OTHER_SPECIFY, 
            V.COMPLICATIONS_PNEU_DIAG_BY, 
            V.COMPLICATIONS_PNEUMONIA, 
            V.COMPLICATIONS_SKIN_INFECTION, 
            V.CROPS_WAVES, 
            V.CULTURE_TEST, 
            V.CULTURE_TEST_DATE, 
            V.CULTURE_TEST_RESULT, 
            V.DEATH_AUTOPSY, 
            V.DEATH_CAUSE, 
            V.DFA_TEST, 
            V.DFA_TEST_DATE, 
            V.DFA_TEST_RESULT, 
            V.EPI_LINKED, 
            V.EPI_LINKED_CASE_TYPE, 
            V.FEVER, 
            V.FEVER_DURATION_DAYS, 
            V.FEVER_ONSET_DATE, 
            V.FEVER_TEMPERATURE, 
            V.FEVER_TEMPERATURE_UNIT, 
            V.GENOTYPING_SENT_TO_CDC, 
            V.GENOTYPING_SENT_TO_CDC_DATE, 
            V.HEALTHCARE_WORKER, 
            V.HEMORRHAGIC, 
            V.IGG_TEST, 
            V.IGG_TEST_ACUTE_DATE, 
            V.IGG_TEST_ACUTE_RESULT, 
            V.IGG_TEST_ACUTE_VALUE, 
            V.IGG_TEST_CONVALESCENT_DATE, 
            V.IGG_TEST_CONVALESCENT_RESULT, 
            V.IGG_TEST_CONVALESCENT_VALUE, 
            V.IGG_TEST_GP_ELISA_MFGR, 
            V.IGG_TEST_OTHER, 
            V.IGG_TEST_TYPE, 
            V.IGG_TEST_WHOLE_CELL_MFGR, 
            V.IGM_TEST, 
            V.IGM_TEST_DATE, 
            V.IGM_TEST_RESULT, 
            V.IGM_TEST_RESULT_VALUE, 
            V.IGM_TEST_TYPE, 
            V.IGM_TEST_TYPE_OTHER, 
            V.IMMUNOCOMPROMISED, 
            V.IMMUNOCOMPROMISED_CONDITION, 
            V.ITCHY, 
            V.LAB_TESTING, 
            V.LAB_TESTING_OTHER, 
            V.LAB_TESTING_OTHER_DATE, 
            V.LAB_TESTING_OTHER_RESULT, 
            V.LAB_TESTING_OTHER_RESULT_VALUE, 
            V.LAB_TESTING_OTHER_SPECIFY, 
            V.LESIONS_TOTAL, 
            V.LESIONS_TOTAL_LT50, 
            V.MACULAR_PAPULAR, 
            V.MACULES, 
            V.MACULES_NUMBER, 
            V.MEDICATION_NAME, 
            V.MEDICATION_NAME_OTHER, 
            V.MEDICATION_START_DATE, 
            V.MEDICATION_STOP_DATE, 
            V.PAPULES, 
            V.PAPULES_NUMBER, 
            V.PATIENT_BIRTH_COUNTRY, 
            V.PATIENT_VISIT_HC_PROVIDER, 
            V.PCR_TEST, 
            V.PCR_TEST_DATE, 
            V.PCR_TEST_RESULT, 
            V.PCR_TEST_RESULT_OTHER, 
            V.PCR_TEST_SOURCE_OTHER, 
            V.PREGNANT_TRIMESTER, 
            V.PREGNANT_WEEKS, 
            V.PREVIOUS_DIAGNOSIS, 
            V.PREVIOUS_DIAGNOSIS_AGE, 
            V.PREVIOUS_DIAGNOSIS_AGE_UNIT, 
            V.PREVIOUS_DIAGNOSIS_BY, 
            V.PREVIOUS_DIAGNOSIS_BY_OTHER, 
            V.RASH_CRUST, 
            V.RASH_CRUSTED_DAYS, 
            V.RASH_DURATION_DAYS, 
            V.RASH_LOCATION, 
            V.RASH_LOCATION_DERMATOME, 
            V.RASH_LOCATION_OTHER, 
            V.RASH_ONSET_DATE, 
            V.SCABS, 
            V.SEROLOGY_TEST, 
            V.STRAIN_IDENTIFICATION_SENT, 
            V.STRAIN_TYPE, 
            V.TRANSMISSION_SETTING, 
            V.TRANSMISSION_SETTING_OTHER, 
            V.TREATED, 
            V.VACCINE_DATE_1, 
            V.VACCINE_DATE_2, 
            V.VACCINE_DATE_3, 
            V.VACCINE_DATE_4, 
            V.VACCINE_DATE_5, 
            V.VACCINE_LOT_1, 
            V.VACCINE_LOT_2, 
            V.VACCINE_LOT_3, 
            V.VACCINE_LOT_4, 
            V.VACCINE_LOT_5, 
            V.VACCINE_MANUFACTURER_1, 
            V.VACCINE_MANUFACTURER_2, 
            V.VACCINE_MANUFACTURER_3, 
            V.VACCINE_MANUFACTURER_4, 
            V.VACCINE_MANUFACTURER_5, 
            V.VACCINE_TYPE_1, 
            V.VACCINE_TYPE_2, 
            V.VACCINE_TYPE_3, 
            V.VACCINE_TYPE_4, 
            V.VACCINE_TYPE_5, 
            V.VARICELLA_NO_2NDVACCINE_OTHER, 
            V.VARICELLA_NO_2NDVACCINE_REASON, 
            V.VARICELLA_NO_VACCINE_OTHER, 
            V.VARICELLA_NO_VACCINE_REASON, 
            V.VARICELLA_VACCINE, 
            V.VARICELLA_VACCINE_DOSES_NUMBER, 
            V.VESICLES, 
            V.VESICLES_NUMBER, 
            V.VESICULAR, 
            V.D_PCR_SOURCE_GROUP_KEY, 
            V.D_RASH_LOC_GEN_GROUP_KEY, 
            V.person_key, 
            V.provider_key, 
            V.CODE, 
            V.OUTBREAK_NAME, 
            V.AGE_REPORTED, 
            V.HOSPITAL_KEY, 
            V.HOSPITAL_NAME, 
            V.INVESTIGATOR_FIRST_NAME, 
            V.INVESTIGATOR_LAST_NAME, 
            V.INVESTIGATOR_PHONE_NUMBER, 
            V.REPORTING_SOURCE_NAME, 
            V.AGE_REPORTED_UNIT, 
            V.PATIENT_CITY, 
            V.PATIENT_COUNTRY, 
            V.PATIENT_COUNTY, 
            V.PATIENT_DECEASED_DATE, 
            V.PATIENT_DECEASED_INDICATOR, 
            V.PATIENT_DOB, 
            V.PATIENT_ETHNICITY, 
            V.PATIENT_FIRST_NAME, 
            V.PATIENT_GENERAL_COMMENTS, 
            V.PATIENT_LAST_NAME, 
            V.PATIENT_LOCAL_ID, 
            V.PATIENT_MARITAL_STATUS, 
            V.PATIENT_MIDDLE_NAME, 
            V.PATIENT_NAME_SUFFIX, 
            V.PATIENT_PHONE_EXT_HOME, 
            V.PATIENT_PHONE_EXT_WORK, 
            V.PATIENT_PHONE_NUMBER_HOME, 
            V.PATIENT_PHONE_NUMBER_WORK, 
            V.PATIENT_SSN, 
            V.PATIENT_STATE, 
            V.PATIENT_STREET_ADDRESS_1, 
            V.PATIENT_STREET_ADDRESS_2, 
            V.PATIENT_ZIP, 
            V.PERSON_AS_REPORTER_KEY, 
            V.PATIENT_CURRENT_SEX, 
            V.PHYSICIAN_FIRST_NAME, 
            V.PHYSICIAN_KEY, 
            V.PHYSICIAN_LAST_NAME, 
            V.PHYSICIAN_PHONE_NUMBER, 
            V.RACE_CALCULATED, 
            V.RACE_CALC_DETAILS, 
            V.REPORTER_FIRST_NAME, 
            V.REPORTER_LAST_NAME, 
            V.REPORTER_PHONE_NUMBER, 
            V.WITHIN_CITY_LIMITS, 
            V.RASH_LOCATION_GENERAL_1, 
            V.RASH_LOCATION_GENERAL_2, 
            V.RASH_LOCATION_GENERAL_3, 
            V.PCR_TEST_SOURCE_1, 
            V.PCR_TEST_SOURCE_2, 
            V.PCR_TEST_SOURCE_3, 
            V.RASH_LOCATION_GENERAL_GT3_IND, 
            V.PCR_TEST_SOURCE_GT3_IND, 
            V.PCR_TEST_SOURCE_ALL, 
            V.RASH_LOCATION_GENERAL_ALL, 
            V.CONFIRMATION_METHOD_1, 
            V.CONFIRMATION_METHOD_2, 
            V.CONFIRMATION_METHOD_3, 
            V.CONFIRMATION_METHOD_GT3_IND, 
            V.CONFIRMATION_METHOD_ALL, 
            V.CONFIRMATION_DATE,
            r.date_mm_dd_yyyy AS notification_sent_date,
            nu.first_nm AS notif_first_nm,
            nu.last_nm AS notif_last_nm,
            cu.first_nm AS createUser_first_nm,
            cu.last_nm AS createUser_last_nm,
            eu.first_nm AS editUser_first_nm,
            eu.last_nm AS editUser_last_nm,
            n.NOTIFICATION_STATUS,
            n.NOTIFICATION_LOCAL_ID,
            CASE 
                WHEN NULLIF(TRIM(nu.last_nm), '') IS NOT NULL AND NULLIF(TRIM(nu.first_nm), '') IS NOT NULL 
                    THEN TRIM(nu.last_nm) + ', ' + TRIM(nu.first_nm)
                WHEN NULLIF(TRIM(nu.last_nm), '') IS NOT NULL 
                    THEN TRIM(nu.last_nm)
                WHEN NULLIF(TRIM(nu.first_nm), '') IS NOT NULL 
                    THEN TRIM(nu.first_nm)
            END AS Notification_Submitter,
            CASE 
                WHEN NULLIF(TRIM(cu.last_nm), '') IS NOT NULL AND NULLIF(TRIM(cu.first_nm), '') IS NOT NULL 
                    THEN TRIM(cu.last_nm) + ', ' + TRIM(cu.first_nm)
                WHEN NULLIF(TRIM(cu.last_nm), '') IS NOT NULL 
                    THEN TRIM(cu.last_nm)
                WHEN NULLIF(TRIM(cu.first_nm), '') IS NOT NULL 
                    THEN TRIM(cu.first_nm)
            END AS INVESTIGATION_CREATED_BY,
            CASE 
                WHEN NULLIF(TRIM(eu.last_nm), '') IS NOT NULL AND NULLIF(TRIM(eu.first_nm), '') IS NOT NULL 
                    THEN TRIM(eu.last_nm) + ', ' + TRIM(eu.first_nm)
                WHEN NULLIF(TRIM(eu.last_nm), '') IS NOT NULL 
                    THEN TRIM(eu.last_nm)
                WHEN NULLIF(TRIM(eu.first_nm), '') IS NOT NULL 
                    THEN TRIM(eu.first_nm)
            END AS INVESTIGATION_LAST_UPDTD_BY,
            CASE 
                WHEN ILLNESS_ONSET_DATE IS NOT NULL THEN ILLNESS_ONSET_DATE
                WHEN DIAGNOSIS_DATE IS NOT NULL THEN DIAGNOSIS_DATE
                WHEN DATE_REPORTED_TO_COUNTY IS NOT NULL THEN DATE_REPORTED_TO_COUNTY
                WHEN DATE_REPORTED_TO_STATE IS NOT NULL THEN DATE_REPORTED_TO_STATE
                ELSE INVESTIGATION_CREATE_DATE
            END AS EVENT_DATE,
            CASE 
                WHEN ILLNESS_ONSET_DATE IS NOT NULL THEN 'O'
                WHEN DIAGNOSIS_DATE IS NOT NULL THEN 'D'
                WHEN DATE_REPORTED_TO_COUNTY IS NOT NULL THEN 'C'
                WHEN DATE_REPORTED_TO_STATE IS NOT NULL THEN 'S'
                ELSE 'P'
            END AS EVENT_DATE_TYPE
        INTO #VAR_DATAMART_NOT_EVENT
        FROM #VAR_DATAMART_INIT v
        LEFT OUTER JOIN dbo.notification_event ne with (nolock)
            ON v.person_key = ne.patient_key
        LEFT OUTER JOIN dbo.notification n with (nolock)
            ON ne.notification_key = n.notification_key
        LEFT OUTER JOIN dbo.RDB_DATE r with (nolock)
            ON ne.NOTIFICATION_SENT_DT_KEY = r.DATE_key
        LEFT OUTER JOIN dbo.user_profile nu with (nolock)
            ON n.notification_submitted_by = nu.NEDSS_ENTRY_ID
        LEFT OUTER JOIN dbo.user_profile cu with (nolock)
            ON v.INVESTIGATION_CREATED_BY = cu.NEDSS_ENTRY_ID
        LEFT OUTER JOIN dbo.user_profile eu with (nolock)
            ON v.INVESTIGATION_LAST_UPDTD_BY = eu.NEDSS_ENTRY_ID;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #VAR_DATAMART_NOT_EVENT;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
    
--------------------------------------------------------------------------------------------------------
    
    BEGIN TRANSACTION
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Update table';
        
        UPDATE DBO.VAR_DATAMART
        SET 
        INVESTIGATION_KEY = VAR_DM.INVESTIGATION_KEY ,
        PATIENT_LOCAL_ID = VAR_DM.PATIENT_LOCAL_ID ,
        INVESTIGATION_LOCAL_ID = VAR_DM.INVESTIGATION_LOCAL_ID ,
        PATIENT_GENERAL_COMMENTS = VAR_DM.PATIENT_GENERAL_COMMENTS ,
        PATIENT_FIRST_NAME = VAR_DM.PATIENT_FIRST_NAME ,
        PATIENT_MIDDLE_NAME = VAR_DM.PATIENT_MIDDLE_NAME ,
        PATIENT_LAST_NAME = VAR_DM.PATIENT_LAST_NAME ,
        PATIENT_NAME_SUFFIX = VAR_DM.PATIENT_NAME_SUFFIX ,
        PATIENT_STREET_ADDRESS_1 = VAR_DM.PATIENT_STREET_ADDRESS_1 ,
        PATIENT_STREET_ADDRESS_2 = VAR_DM.PATIENT_STREET_ADDRESS_2 ,
        PATIENT_CITY = VAR_DM.PATIENT_CITY ,
        PATIENT_STATE = VAR_DM.PATIENT_STATE ,
        PATIENT_ZIP = VAR_DM.PATIENT_ZIP ,
        PATIENT_COUNTY = VAR_DM.PATIENT_COUNTY ,
        PATIENT_COUNTRY = VAR_DM.PATIENT_COUNTRY ,
        PATIENT_PHONE_NUMBER_HOME = VAR_DM.PATIENT_PHONE_NUMBER_HOME ,
        PATIENT_PHONE_EXT_HOME = VAR_DM.PATIENT_PHONE_EXT_HOME ,
        PATIENT_PHONE_NUMBER_WORK = VAR_DM.PATIENT_PHONE_NUMBER_WORK ,
        PATIENT_PHONE_EXT_WORK = VAR_DM.PATIENT_PHONE_EXT_WORK ,
        PATIENT_DOB = VAR_DM.PATIENT_DOB ,
        AGE_REPORTED = VAR_DM.AGE_REPORTED ,
        AGE_REPORTED_UNIT = VAR_DM.AGE_REPORTED_UNIT ,
        CONFIRMATION_METHOD_1 = VAR_DM.CONFIRMATION_METHOD_1 ,
        CONFIRMATION_METHOD_2 = VAR_DM.CONFIRMATION_METHOD_2 ,
        CONFIRMATION_METHOD_3 = VAR_DM.CONFIRMATION_METHOD_3 ,
        CONFIRMATION_METHOD_ALL = VAR_DM.CONFIRMATION_METHOD_ALL ,
        CONFIRMATION_DATE = VAR_DM.CONFIRMATION_DATE ,
        CONFIRMATION_METHOD_GT3_IND = VAR_DM.CONFIRMATION_METHOD_GT3_IND ,
        PATIENT_CURRENT_SEX = VAR_DM.PATIENT_CURRENT_SEX ,
        PATIENT_DECEASED_INDICATOR = VAR_DM.PATIENT_DECEASED_INDICATOR ,
        PATIENT_DECEASED_DATE = VAR_DM.PATIENT_DECEASED_DATE ,
        PATIENT_MARITAL_STATUS = VAR_DM.PATIENT_MARITAL_STATUS ,
        PATIENT_SSN = VAR_DM.PATIENT_SSN ,
        PATIENT_ETHNICITY = VAR_DM.PATIENT_ETHNICITY ,
        RACE_CALCULATED = VAR_DM.RACE_CALCULATED ,
        RACE_CALC_DETAILS = VAR_DM.RACE_CALC_DETAILS ,
        JURISDICTION_NAME = VAR_DM.JURISDICTION_NAME ,
        PROGRAM_AREA_DESCRIPTION = VAR_DM.PROGRAM_AREA_DESCRIPTION ,
        INVESTIGATION_STATUS = VAR_DM.INVESTIGATION_STATUS ,
        INVESTIGATION_START_DATE = VAR_DM.INVESTIGATION_START_DATE ,
        INVESTIGATOR_FIRST_NAME = VAR_DM.INVESTIGATOR_FIRST_NAME ,
        INVESTIGATOR_LAST_NAME = VAR_DM.INVESTIGATOR_LAST_NAME ,
        INVESTIGATOR_PHONE_NUMBER = VAR_DM.INVESTIGATOR_PHONE_NUMBER ,
        INVESTIGATOR_ASSIGN_DATE = VAR_DM.INVESTIGATOR_ASSIGN_DATE ,
        STATE_CASE_NUMBER = VAR_DM.STATE_CASE_NUMBER ,
        REPORTING_SOURCE_NAME = VAR_DM.REPORTING_SOURCE_NAME ,
        REPORTING_SOURCE_TYPE = VAR_DM.REPORTING_SOURCE_TYPE ,
        REPORTER_FIRST_NAME = VAR_DM.REPORTER_FIRST_NAME ,
        REPORTER_LAST_NAME = VAR_DM.REPORTER_LAST_NAME ,
        REPORTER_PHONE_NUMBER = VAR_DM.REPORTER_PHONE_NUMBER ,
        DATE_REPORTED = VAR_DM.DATE_REPORTED ,
        DATE_REPORTED_TO_COUNTY = VAR_DM.DATE_REPORTED_TO_COUNTY ,
        DATE_REPORTED_TO_STATE = VAR_DM.DATE_REPORTED_TO_STATE ,
        DIAGNOSIS_DATE = VAR_DM.DIAGNOSIS_DATE ,
        ILLNESS_ONSET_DATE = VAR_DM.ILLNESS_ONSET_DATE ,
        ILLNESS_ONSET_AGE = VAR_DM.ILLNESS_ONSET_AGE ,
        ILLNESS_ONSET_AGE_UNIT = VAR_DM.ILLNESS_ONSET_AGE_UNIT ,
        RASH_ONSET_DATE = VAR_DM.RASH_ONSET_DATE ,
        RASH_LOCATION = VAR_DM.RASH_LOCATION ,
        RASH_LOCATION_DERMATOME = VAR_DM.RASH_LOCATION_DERMATOME ,
        RASH_LOCATION_GENERAL_1 = VAR_DM.RASH_LOCATION_GENERAL_1 ,
        RASH_LOCATION_GENERAL_2 = VAR_DM.RASH_LOCATION_GENERAL_2 ,
        RASH_LOCATION_GENERAL_3 = VAR_DM.RASH_LOCATION_GENERAL_3 ,
        RASH_LOCATION_GENERAL_GT3_IND = VAR_DM.RASH_LOCATION_GENERAL_GT3_IND ,
        RASH_LOCATION_GENERAL_ALL = VAR_DM.RASH_LOCATION_GENERAL_ALL ,
        RASH_LOCATION_OTHER = VAR_DM.RASH_LOCATION_OTHER ,
        LESIONS_TOTAL = VAR_DM.LESIONS_TOTAL ,
        LESIONS_TOTAL_LT50 = VAR_DM.LESIONS_TOTAL_LT50 ,
        MACULES = VAR_DM.MACULES ,
        MACULES_NUMBER = VAR_DM.MACULES_NUMBER ,
        PAPULES = VAR_DM.PAPULES ,
        PAPULES_NUMBER = VAR_DM.PAPULES_NUMBER ,
        VESICLES = VAR_DM.VESICLES ,
        VESICLES_NUMBER = VAR_DM.VESICLES_NUMBER ,
        MACULAR_PAPULAR = VAR_DM.MACULAR_PAPULAR ,
        VESICULAR = VAR_DM.VESICULAR ,
        HEMORRHAGIC = VAR_DM.HEMORRHAGIC ,
        ITCHY = VAR_DM.ITCHY ,
        SCABS = VAR_DM.SCABS ,
        CROPS_WAVES = VAR_DM.CROPS_WAVES ,
        RASH_CRUST = VAR_DM.RASH_CRUST ,
        RASH_CRUSTED_DAYS = VAR_DM.RASH_CRUSTED_DAYS ,
        RASH_DURATION_DAYS = VAR_DM.RASH_DURATION_DAYS ,
        FEVER = VAR_DM.FEVER ,
        FEVER_ONSET_DATE = VAR_DM.FEVER_ONSET_DATE ,
        FEVER_TEMPERATURE = VAR_DM.FEVER_TEMPERATURE ,
        FEVER_TEMPERATURE_UNIT = VAR_DM.FEVER_TEMPERATURE_UNIT ,
        FEVER_DURATION_DAYS = VAR_DM.FEVER_DURATION_DAYS ,
        IMMUNOCOMPROMISED = VAR_DM.IMMUNOCOMPROMISED ,
        IMMUNOCOMPROMISED_CONDITION = VAR_DM.IMMUNOCOMPROMISED_CONDITION ,
        PATIENT_VISIT_HC_PROVIDER = VAR_DM.PATIENT_VISIT_HC_PROVIDER ,
        COMPLICATIONS = VAR_DM.COMPLICATIONS ,
        COMPLICATIONS_SKIN_INFECTION = VAR_DM.COMPLICATIONS_SKIN_INFECTION ,
        COMPLICATIONS_CEREB_ATAXIA = VAR_DM.COMPLICATIONS_CEREB_ATAXIA ,
        COMPLICATIONS_ENCEPHALITIS = VAR_DM.COMPLICATIONS_ENCEPHALITIS ,
        COMPLICATIONS_DEHYDRATION = VAR_DM.COMPLICATIONS_DEHYDRATION ,
        COMPLICATIONS_HEMORRHAGIC = VAR_DM.COMPLICATIONS_HEMORRHAGIC ,
        COMPLICATIONS_PNEUMONIA = VAR_DM.COMPLICATIONS_PNEUMONIA ,
        COMPLICATIONS_PNEU_DIAG_BY = VAR_DM.COMPLICATIONS_PNEU_DIAG_BY ,
        COMPLICATIONS_OTHER = VAR_DM.COMPLICATIONS_OTHER ,
        COMPLICATIONS_OTHER_SPECIFY = VAR_DM.COMPLICATIONS_OTHER_SPECIFY ,
        TREATED = VAR_DM.TREATED ,
        MEDICATION_NAME = VAR_DM.MEDICATION_NAME ,
        MEDICATION_NAME_OTHER = VAR_DM.MEDICATION_NAME_OTHER ,
        MEDICATION_START_DATE = VAR_DM.MEDICATION_START_DATE ,
        MEDICATION_STOP_DATE = VAR_DM.MEDICATION_STOP_DATE ,
        HOSPITALIZED = VAR_DM.HOSPITALIZED ,
        HOSPITALIZED_ADMISSION_DATE = VAR_DM.HOSPITALIZED_ADMISSION_DATE ,
        HOSPITALIZED_DISCHARGE_DATE = VAR_DM.HOSPITALIZED_DISCHARGE_DATE ,
        HOSPITALIZED_DURATION_DAYS = VAR_DM.HOSPITALIZED_DURATION_DAYS ,
        HOSPITAL_NAME = VAR_DM.HOSPITAL_NAME ,
        DIE_FRM_THIS_ILLNESS_IND = VAR_DM.DIE_FRM_THIS_ILLNESS_IND ,
        INVESTIGATION_DEATH_DATE = VAR_DM.INVESTIGATION_DEATH_DATE ,
        DEATH_AUTOPSY = VAR_DM.DEATH_AUTOPSY ,
        DEATH_CAUSE = VAR_DM.DEATH_CAUSE ,
        LAB_TESTING = VAR_DM.LAB_TESTING ,
        DFA_TEST = VAR_DM.DFA_TEST ,
        DFA_TEST_DATE = VAR_DM.DFA_TEST_DATE ,
        DFA_TEST_RESULT = VAR_DM.DFA_TEST_RESULT ,
        PCR_TEST = VAR_DM.PCR_TEST ,
        PCR_TEST_DATE = VAR_DM.PCR_TEST_DATE ,
        PCR_TEST_SOURCE_1 = VAR_DM.PCR_TEST_SOURCE_1 ,
        PCR_TEST_SOURCE_2 = VAR_DM.PCR_TEST_SOURCE_2 ,
        PCR_TEST_SOURCE_3 = VAR_DM.PCR_TEST_SOURCE_3 ,
        PCR_TEST_SOURCE_GT3_IND = VAR_DM.PCR_TEST_SOURCE_GT3_IND ,
        PCR_TEST_SOURCE_ALL = VAR_DM.PCR_TEST_SOURCE_ALL ,
        PCR_TEST_SOURCE_OTHER = VAR_DM.PCR_TEST_SOURCE_OTHER ,
        PCR_TEST_RESULT = VAR_DM.PCR_TEST_RESULT ,
        PCR_TEST_RESULT_OTHER = VAR_DM.PCR_TEST_RESULT_OTHER ,
        CULTURE_TEST = VAR_DM.CULTURE_TEST ,
        CULTURE_TEST_DATE = VAR_DM.CULTURE_TEST_DATE ,
        CULTURE_TEST_RESULT = VAR_DM.CULTURE_TEST_RESULT ,
        LAB_TESTING_OTHER = VAR_DM.LAB_TESTING_OTHER ,
        LAB_TESTING_OTHER_SPECIFY = VAR_DM.LAB_TESTING_OTHER_SPECIFY ,
        LAB_TESTING_OTHER_DATE = VAR_DM.LAB_TESTING_OTHER_DATE ,
        LAB_TESTING_OTHER_RESULT = VAR_DM.LAB_TESTING_OTHER_RESULT ,
        LAB_TESTING_OTHER_RESULT_VALUE = VAR_DM.LAB_TESTING_OTHER_RESULT_VALUE ,
        SEROLOGY_TEST = VAR_DM.SEROLOGY_TEST ,
        IGM_TEST = VAR_DM.IGM_TEST ,
        IGM_TEST_TYPE = VAR_DM.IGM_TEST_TYPE ,
        IGM_TEST_TYPE_OTHER = VAR_DM.IGM_TEST_TYPE_OTHER ,
        IGM_TEST_DATE = VAR_DM.IGM_TEST_DATE ,
        IGM_TEST_RESULT = VAR_DM.IGM_TEST_RESULT ,
        IGM_TEST_RESULT_VALUE = VAR_DM.IGM_TEST_RESULT_VALUE ,
        IGG_TEST = VAR_DM.IGG_TEST ,
        IGG_TEST_TYPE = VAR_DM.IGG_TEST_TYPE ,
        IGG_TEST_WHOLE_CELL_MFGR = VAR_DM.IGG_TEST_WHOLE_CELL_MFGR ,
        IGG_TEST_GP_ELISA_MFGR = VAR_DM.IGG_TEST_GP_ELISA_MFGR ,
        IGG_TEST_OTHER = VAR_DM.IGG_TEST_OTHER ,
        IGG_TEST_ACUTE_DATE = VAR_DM.IGG_TEST_ACUTE_DATE ,
        IGG_TEST_ACUTE_RESULT = VAR_DM.IGG_TEST_ACUTE_RESULT ,
        IGG_TEST_ACUTE_VALUE = VAR_DM.IGG_TEST_ACUTE_VALUE ,
        IGG_TEST_CONVALESCENT_DATE = VAR_DM.IGG_TEST_CONVALESCENT_DATE ,
        IGG_TEST_CONVALESCENT_RESULT = VAR_DM.IGG_TEST_CONVALESCENT_RESULT ,
        IGG_TEST_CONVALESCENT_VALUE = VAR_DM.IGG_TEST_CONVALESCENT_VALUE ,
        GENOTYPING_SENT_TO_CDC = VAR_DM.GENOTYPING_SENT_TO_CDC ,
        GENOTYPING_SENT_TO_CDC_DATE = VAR_DM.GENOTYPING_SENT_TO_CDC_DATE ,
        STRAIN_IDENTIFICATION_SENT = VAR_DM.STRAIN_IDENTIFICATION_SENT ,
        STRAIN_TYPE = VAR_DM.STRAIN_TYPE ,
        VARICELLA_VACCINE = VAR_DM.VARICELLA_VACCINE ,
        VARICELLA_NO_VACCINE_REASON = VAR_DM.VARICELLA_NO_VACCINE_REASON ,
        VARICELLA_NO_VACCINE_OTHER = VAR_DM.VARICELLA_NO_VACCINE_OTHER ,
        VARICELLA_VACCINE_DOSES_NUMBER = VAR_DM.VARICELLA_VACCINE_DOSES_NUMBER ,
        VARICELLA_NO_2NDVACCINE_REASON = VAR_DM.VARICELLA_NO_2NDVACCINE_REASON ,
        VARICELLA_NO_2NDVACCINE_OTHER = VAR_DM.VARICELLA_NO_2NDVACCINE_OTHER ,
        VACCINE_DATE_1 = VAR_DM.VACCINE_DATE_1 ,
        VACCINE_TYPE_1 = VAR_DM.VACCINE_TYPE_1 ,
        VACCINE_MANUFACTURER_1 = VAR_DM.VACCINE_MANUFACTURER_1 ,
        VACCINE_LOT_1 = VAR_DM.VACCINE_LOT_1 ,
        VACCINE_DATE_2 = VAR_DM.VACCINE_DATE_2 ,
        VACCINE_TYPE_2 = VAR_DM.VACCINE_TYPE_2 ,
        VACCINE_MANUFACTURER_2 = VAR_DM.VACCINE_MANUFACTURER_2 ,
        VACCINE_LOT_2 = VAR_DM.VACCINE_LOT_2 ,
        VACCINE_DATE_3 = VAR_DM.VACCINE_DATE_3 ,
        VACCINE_TYPE_3 = VAR_DM.VACCINE_TYPE_3 ,
        VACCINE_MANUFACTURER_3 = VAR_DM.VACCINE_MANUFACTURER_3 ,
        VACCINE_LOT_3 = VAR_DM.VACCINE_LOT_3 ,
        VACCINE_DATE_4 = VAR_DM.VACCINE_DATE_4 ,
        VACCINE_TYPE_4 = VAR_DM.VACCINE_TYPE_4 ,
        VACCINE_MANUFACTURER_4 = VAR_DM.VACCINE_MANUFACTURER_4 ,
        VACCINE_LOT_4 = VAR_DM.VACCINE_LOT_4 ,
        VACCINE_DATE_5 = VAR_DM.VACCINE_DATE_5 ,
        VACCINE_TYPE_5 = VAR_DM.VACCINE_TYPE_5 ,
        VACCINE_MANUFACTURER_5 = VAR_DM.VACCINE_MANUFACTURER_5 ,
        VACCINE_LOT_5 = VAR_DM.VACCINE_LOT_5 ,
        PREVIOUS_DIAGNOSIS = VAR_DM.PREVIOUS_DIAGNOSIS ,
        PREVIOUS_DIAGNOSIS_AGE = VAR_DM.PREVIOUS_DIAGNOSIS_AGE ,
        PREVIOUS_DIAGNOSIS_AGE_UNIT = VAR_DM.PREVIOUS_DIAGNOSIS_AGE_UNIT ,
        PREVIOUS_DIAGNOSIS_BY = VAR_DM.PREVIOUS_DIAGNOSIS_BY ,
        PREVIOUS_DIAGNOSIS_BY_OTHER = VAR_DM.PREVIOUS_DIAGNOSIS_BY_OTHER ,
        PATIENT_BIRTH_COUNTRY = VAR_DM.PATIENT_BIRTH_COUNTRY ,
        EPI_LINKED = VAR_DM.EPI_LINKED ,
        EPI_LINKED_CASE_TYPE = VAR_DM.EPI_LINKED_CASE_TYPE ,
        TRANSMISSION_SETTING = VAR_DM.TRANSMISSION_SETTING ,
        TRANSMISSION_SETTING_OTHER = VAR_DM.TRANSMISSION_SETTING_OTHER ,
        HEALTHCARE_WORKER = VAR_DM.HEALTHCARE_WORKER ,
        OUTBREAK = VAR_DM.OUTBREAK ,
        OUTBREAK_NAME = VAR_DM.OUTBREAK_NAME ,
        PREGNANT = VAR_DM.PREGNANT ,
        PREGNANT_WEEKS = VAR_DM.PREGNANT_WEEKS ,
        PREGNANT_TRIMESTER = VAR_DM.PREGNANT_TRIMESTER ,
        CASE_STATUS = VAR_DM.CASE_STATUS ,
        MMWR_WEEK = VAR_DM.MMWR_WEEK ,
        MMWR_YEAR = VAR_DM.MMWR_YEAR ,
        GENERAL_COMMENTS = VAR_DM.GENERAL_COMMENTS ,
        INVESTIGATION_CREATE_DATE = VAR_DM.INVESTIGATION_CREATE_DATE ,
        INVESTIGATION_CREATED_BY = VAR_DM.INVESTIGATION_CREATED_BY ,
        INVESTIGATION_LAST_UPDTD_DATE = VAR_DM.INVESTIGATION_LAST_UPDTD_DATE ,
        INVESTIGATION_LAST_UPDTD_BY = VAR_DM.INVESTIGATION_LAST_UPDTD_BY ,
        PROGRAM_JURISDICTION_OID = VAR_DM.PROGRAM_JURISDICTION_OID ,
        NOTIFICATION_SUBMITTER = VAR_DM.NOTIFICATION_SUBMITTER ,
        NOTIFICATION_SENT_DATE = VAR_DM.NOTIFICATION_SENT_DATE ,
        EVENT_DATE = VAR_DM.EVENT_DATE ,
        NOTIFICATION_STATUS = VAR_DM.NOTIFICATION_STATUS ,
        NOTIFICATION_LOCAL_ID = VAR_DM.NOTIFICATION_LOCAL_ID ,
        EVENT_DATE_TYPE = VAR_DM.EVENT_DATE_TYPE ,
        PHYSICIAN_FIRST_NAME = VAR_DM.PHYSICIAN_FIRST_NAME ,
        PHYSICIAN_LAST_NAME = VAR_DM.PHYSICIAN_LAST_NAME ,
        PHYSICIAN_PHONE_NUMBER = VAR_DM.PHYSICIAN_PHONE_NUMBER ,
        ILLNESS_END_DATE = VAR_DM.ILLNESS_END_DATE ,
        ILLNESS_DURATION = VAR_DM.ILLNESS_DURATION ,
        ILLNESS_DURATION_UNIT = VAR_DM.ILLNESS_DURATION_UNIT ,
        DAYCARE = VAR_DM.DAYCARE ,
        FOOD_HANDLER = VAR_DM.FOOD_HANDLER ,
        DISEASE_ACQUIRED_WHERE = VAR_DM.DISEASE_ACQUIRED_WHERE ,
        DISEASE_ACQUIRED_COUNTRY = VAR_DM.DISEASE_ACQUIRED_COUNTRY ,
        DISEASE_ACQUIRED_STATE = VAR_DM.DISEASE_ACQUIRED_STATE ,
        DISEASE_ACQUIRED_CITY = VAR_DM.DISEASE_ACQUIRED_CITY ,
        DISEASE_ACQUIRED_COUNTY = VAR_DM.DISEASE_ACQUIRED_COUNTY ,
        TRANSMISSION_MODE = VAR_DM.TRANSMISSION_MODE ,
        DETECTION_METHOD = VAR_DM.DETECTION_METHOD
        FROM #VAR_DATAMART_NOT_EVENT VAR_DM
        INNER JOIN DBO.VAR_DATAMART D with (nolock)
        ON D.INVESTIGATION_KEY = VAR_DM.INVESTIGATION_KEY
        WHERE VAR_DM.investigation_key > 0;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;
--------------------------------------------------------------------------------------------------------
    
    BEGIN TRANSACTION
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Inserting to VAR_DATAMART  TABLE';


        INSERT INTO DBO.VAR_DATAMART(INVESTIGATION_KEY, PATIENT_LOCAL_ID, INVESTIGATION_LOCAL_ID, PATIENT_GENERAL_COMMENTS, PATIENT_FIRST_NAME, PATIENT_MIDDLE_NAME, PATIENT_LAST_NAME, PATIENT_NAME_SUFFIX, PATIENT_STREET_ADDRESS_1, PATIENT_STREET_ADDRESS_2, PATIENT_CITY, PATIENT_STATE, PATIENT_ZIP, PATIENT_COUNTY, PATIENT_COUNTRY, PATIENT_PHONE_NUMBER_HOME, PATIENT_PHONE_EXT_HOME, PATIENT_PHONE_NUMBER_WORK, PATIENT_PHONE_EXT_WORK, PATIENT_DOB, AGE_REPORTED, AGE_REPORTED_UNIT, CONFIRMATION_METHOD_1, CONFIRMATION_METHOD_2, CONFIRMATION_METHOD_3, CONFIRMATION_METHOD_ALL, CONFIRMATION_DATE, CONFIRMATION_METHOD_GT3_IND, PATIENT_CURRENT_SEX, PATIENT_DECEASED_INDICATOR, PATIENT_DECEASED_DATE, PATIENT_MARITAL_STATUS, PATIENT_SSN, PATIENT_ETHNICITY, RACE_CALCULATED, RACE_CALC_DETAILS, JURISDICTION_NAME, PROGRAM_AREA_DESCRIPTION, INVESTIGATION_STATUS, INVESTIGATION_START_DATE, INVESTIGATOR_FIRST_NAME, INVESTIGATOR_LAST_NAME, INVESTIGATOR_PHONE_NUMBER, INVESTIGATOR_ASSIGN_DATE, STATE_CASE_NUMBER, REPORTING_SOURCE_NAME, REPORTING_SOURCE_TYPE, REPORTER_FIRST_NAME, REPORTER_LAST_NAME, REPORTER_PHONE_NUMBER, DATE_REPORTED, DATE_REPORTED_TO_COUNTY, DATE_REPORTED_TO_STATE, DIAGNOSIS_DATE, ILLNESS_ONSET_DATE, ILLNESS_ONSET_AGE, ILLNESS_ONSET_AGE_UNIT, RASH_ONSET_DATE, RASH_LOCATION, RASH_LOCATION_DERMATOME, RASH_LOCATION_GENERAL_1, RASH_LOCATION_GENERAL_2, RASH_LOCATION_GENERAL_3, RASH_LOCATION_GENERAL_GT3_IND, RASH_LOCATION_GENERAL_ALL, RASH_LOCATION_OTHER, LESIONS_TOTAL, LESIONS_TOTAL_LT50, MACULES, MACULES_NUMBER, PAPULES, PAPULES_NUMBER, VESICLES, VESICLES_NUMBER, MACULAR_PAPULAR, VESICULAR, HEMORRHAGIC, ITCHY, SCABS, CROPS_WAVES, RASH_CRUST, RASH_CRUSTED_DAYS, RASH_DURATION_DAYS, FEVER, FEVER_ONSET_DATE, FEVER_TEMPERATURE, FEVER_TEMPERATURE_UNIT, FEVER_DURATION_DAYS, IMMUNOCOMPROMISED, IMMUNOCOMPROMISED_CONDITION, PATIENT_VISIT_HC_PROVIDER, COMPLICATIONS, COMPLICATIONS_SKIN_INFECTION, COMPLICATIONS_CEREB_ATAXIA, COMPLICATIONS_ENCEPHALITIS, COMPLICATIONS_DEHYDRATION, COMPLICATIONS_HEMORRHAGIC, COMPLICATIONS_PNEUMONIA, COMPLICATIONS_PNEU_DIAG_BY, COMPLICATIONS_OTHER, COMPLICATIONS_OTHER_SPECIFY, TREATED, MEDICATION_NAME, MEDICATION_NAME_OTHER, MEDICATION_START_DATE, MEDICATION_STOP_DATE, HOSPITALIZED, HOSPITALIZED_ADMISSION_DATE, HOSPITALIZED_DISCHARGE_DATE, HOSPITALIZED_DURATION_DAYS, HOSPITAL_NAME, DIE_FRM_THIS_ILLNESS_IND, INVESTIGATION_DEATH_DATE, DEATH_AUTOPSY, DEATH_CAUSE, LAB_TESTING, DFA_TEST, DFA_TEST_DATE, DFA_TEST_RESULT, PCR_TEST, PCR_TEST_DATE, PCR_TEST_SOURCE_1, PCR_TEST_SOURCE_2, PCR_TEST_SOURCE_3, PCR_TEST_SOURCE_GT3_IND, PCR_TEST_SOURCE_ALL, PCR_TEST_SOURCE_OTHER, PCR_TEST_RESULT, PCR_TEST_RESULT_OTHER, CULTURE_TEST, CULTURE_TEST_DATE, CULTURE_TEST_RESULT, LAB_TESTING_OTHER, LAB_TESTING_OTHER_SPECIFY, LAB_TESTING_OTHER_DATE, LAB_TESTING_OTHER_RESULT, LAB_TESTING_OTHER_RESULT_VALUE, SEROLOGY_TEST, IGM_TEST, IGM_TEST_TYPE, IGM_TEST_TYPE_OTHER, IGM_TEST_DATE, IGM_TEST_RESULT, IGM_TEST_RESULT_VALUE, IGG_TEST, IGG_TEST_TYPE, IGG_TEST_WHOLE_CELL_MFGR, IGG_TEST_GP_ELISA_MFGR, IGG_TEST_OTHER, IGG_TEST_ACUTE_DATE, IGG_TEST_ACUTE_RESULT, IGG_TEST_ACUTE_VALUE, IGG_TEST_CONVALESCENT_DATE, IGG_TEST_CONVALESCENT_RESULT, IGG_TEST_CONVALESCENT_VALUE, GENOTYPING_SENT_TO_CDC, GENOTYPING_SENT_TO_CDC_DATE, STRAIN_IDENTIFICATION_SENT, STRAIN_TYPE, VARICELLA_VACCINE, VARICELLA_NO_VACCINE_REASON, VARICELLA_NO_VACCINE_OTHER, VARICELLA_VACCINE_DOSES_NUMBER, VARICELLA_NO_2NDVACCINE_REASON, VARICELLA_NO_2NDVACCINE_OTHER, VACCINE_DATE_1, VACCINE_TYPE_1, VACCINE_MANUFACTURER_1, VACCINE_LOT_1, VACCINE_DATE_2, VACCINE_TYPE_2, VACCINE_MANUFACTURER_2, VACCINE_LOT_2, VACCINE_DATE_3, VACCINE_TYPE_3, VACCINE_MANUFACTURER_3, VACCINE_LOT_3, VACCINE_DATE_4, VACCINE_TYPE_4, VACCINE_MANUFACTURER_4, VACCINE_LOT_4, VACCINE_DATE_5, VACCINE_TYPE_5, VACCINE_MANUFACTURER_5, VACCINE_LOT_5, PREVIOUS_DIAGNOSIS, PREVIOUS_DIAGNOSIS_AGE, PREVIOUS_DIAGNOSIS_AGE_UNIT, PREVIOUS_DIAGNOSIS_BY, PREVIOUS_DIAGNOSIS_BY_OTHER, PATIENT_BIRTH_COUNTRY, EPI_LINKED, EPI_LINKED_CASE_TYPE, TRANSMISSION_SETTING, TRANSMISSION_SETTING_OTHER, HEALTHCARE_WORKER, OUTBREAK, OUTBREAK_NAME, PREGNANT, PREGNANT_WEEKS, PREGNANT_TRIMESTER, CASE_STATUS, MMWR_WEEK, MMWR_YEAR, GENERAL_COMMENTS, INVESTIGATION_CREATE_DATE, INVESTIGATION_CREATED_BY, INVESTIGATION_LAST_UPDTD_DATE, INVESTIGATION_LAST_UPDTD_BY, PROGRAM_JURISDICTION_OID, NOTIFICATION_SUBMITTER, NOTIFICATION_SENT_DATE, EVENT_DATE, NOTIFICATION_STATUS, NOTIFICATION_LOCAL_ID, EVENT_DATE_TYPE, PHYSICIAN_FIRST_NAME, PHYSICIAN_LAST_NAME, PHYSICIAN_PHONE_NUMBER, ILLNESS_END_DATE, ILLNESS_DURATION, ILLNESS_DURATION_UNIT, DAYCARE, FOOD_HANDLER, DISEASE_ACQUIRED_WHERE, DISEASE_ACQUIRED_COUNTRY, DISEASE_ACQUIRED_STATE, DISEASE_ACQUIRED_CITY, DISEASE_ACQUIRED_COUNTY, TRANSMISSION_MODE, DETECTION_METHOD)
        SELECT V.INVESTIGATION_KEY, V.PATIENT_LOCAL_ID, V.INVESTIGATION_LOCAL_ID, V.PATIENT_GENERAL_COMMENTS, V.PATIENT_FIRST_NAME, V.PATIENT_MIDDLE_NAME, V.PATIENT_LAST_NAME, V.PATIENT_NAME_SUFFIX, V.PATIENT_STREET_ADDRESS_1, V.PATIENT_STREET_ADDRESS_2, V.PATIENT_CITY, V.PATIENT_STATE, V.PATIENT_ZIP, V.PATIENT_COUNTY, V.PATIENT_COUNTRY, V.PATIENT_PHONE_NUMBER_HOME, V.PATIENT_PHONE_EXT_HOME, V.PATIENT_PHONE_NUMBER_WORK, V.PATIENT_PHONE_EXT_WORK, V.PATIENT_DOB, V.AGE_REPORTED, V.AGE_REPORTED_UNIT, V.CONFIRMATION_METHOD_1, V.CONFIRMATION_METHOD_2, V.CONFIRMATION_METHOD_3, V.CONFIRMATION_METHOD_ALL, V.CONFIRMATION_DATE, V.CONFIRMATION_METHOD_GT3_IND, V.PATIENT_CURRENT_SEX, V.PATIENT_DECEASED_INDICATOR, V.PATIENT_DECEASED_DATE, V.PATIENT_MARITAL_STATUS, V.PATIENT_SSN, V.PATIENT_ETHNICITY, V.RACE_CALCULATED, V.RACE_CALC_DETAILS, V.JURISDICTION_NAME, V.PROGRAM_AREA_DESCRIPTION, V.INVESTIGATION_STATUS, V.INVESTIGATION_START_DATE, V.INVESTIGATOR_FIRST_NAME, V.INVESTIGATOR_LAST_NAME, V.INVESTIGATOR_PHONE_NUMBER, V.INVESTIGATOR_ASSIGN_DATE, V.STATE_CASE_NUMBER, V.REPORTING_SOURCE_NAME, V.REPORTING_SOURCE_TYPE, V.REPORTER_FIRST_NAME, V.REPORTER_LAST_NAME, V.REPORTER_PHONE_NUMBER, V.DATE_REPORTED, V.DATE_REPORTED_TO_COUNTY, V.DATE_REPORTED_TO_STATE, V.DIAGNOSIS_DATE, V.ILLNESS_ONSET_DATE, V.ILLNESS_ONSET_AGE, V.ILLNESS_ONSET_AGE_UNIT, V.RASH_ONSET_DATE, V.RASH_LOCATION, V.RASH_LOCATION_DERMATOME, V.RASH_LOCATION_GENERAL_1, V.RASH_LOCATION_GENERAL_2, V.RASH_LOCATION_GENERAL_3, V.RASH_LOCATION_GENERAL_GT3_IND, V.RASH_LOCATION_GENERAL_ALL, V.RASH_LOCATION_OTHER, V.LESIONS_TOTAL, V.LESIONS_TOTAL_LT50, V.MACULES, V.MACULES_NUMBER, V.PAPULES, V.PAPULES_NUMBER, V.VESICLES, V.VESICLES_NUMBER, V.MACULAR_PAPULAR, V.VESICULAR, V.HEMORRHAGIC, V.ITCHY, V.SCABS, V.CROPS_WAVES, V.RASH_CRUST, V.RASH_CRUSTED_DAYS, V.RASH_DURATION_DAYS, V.FEVER, V.FEVER_ONSET_DATE, V.FEVER_TEMPERATURE, V.FEVER_TEMPERATURE_UNIT, V.FEVER_DURATION_DAYS, V.IMMUNOCOMPROMISED, V.IMMUNOCOMPROMISED_CONDITION, V.PATIENT_VISIT_HC_PROVIDER, V.COMPLICATIONS, V.COMPLICATIONS_SKIN_INFECTION, V.COMPLICATIONS_CEREB_ATAXIA, V.COMPLICATIONS_ENCEPHALITIS, V.COMPLICATIONS_DEHYDRATION, V.COMPLICATIONS_HEMORRHAGIC, V.COMPLICATIONS_PNEUMONIA, V.COMPLICATIONS_PNEU_DIAG_BY, V.COMPLICATIONS_OTHER, V.COMPLICATIONS_OTHER_SPECIFY, V.TREATED, V.MEDICATION_NAME, V.MEDICATION_NAME_OTHER, V.MEDICATION_START_DATE, V.MEDICATION_STOP_DATE, V.HOSPITALIZED, V.HOSPITALIZED_ADMISSION_DATE, V.HOSPITALIZED_DISCHARGE_DATE, V.HOSPITALIZED_DURATION_DAYS, V.HOSPITAL_NAME, V.DIE_FRM_THIS_ILLNESS_IND, V.INVESTIGATION_DEATH_DATE, V.DEATH_AUTOPSY, V.DEATH_CAUSE, V.LAB_TESTING, V.DFA_TEST, V.DFA_TEST_DATE, V.DFA_TEST_RESULT, V.PCR_TEST, V.PCR_TEST_DATE, V.PCR_TEST_SOURCE_1, V.PCR_TEST_SOURCE_2, V.PCR_TEST_SOURCE_3, V.PCR_TEST_SOURCE_GT3_IND, V.PCR_TEST_SOURCE_ALL, V.PCR_TEST_SOURCE_OTHER, V.PCR_TEST_RESULT, V.PCR_TEST_RESULT_OTHER, V.CULTURE_TEST, V.CULTURE_TEST_DATE, V.CULTURE_TEST_RESULT, V.LAB_TESTING_OTHER, V.LAB_TESTING_OTHER_SPECIFY, V.LAB_TESTING_OTHER_DATE, V.LAB_TESTING_OTHER_RESULT, V.LAB_TESTING_OTHER_RESULT_VALUE, V.SEROLOGY_TEST, V.IGM_TEST, V.IGM_TEST_TYPE, V.IGM_TEST_TYPE_OTHER, V.IGM_TEST_DATE, V.IGM_TEST_RESULT, V.IGM_TEST_RESULT_VALUE, V.IGG_TEST, V.IGG_TEST_TYPE, V.IGG_TEST_WHOLE_CELL_MFGR, V.IGG_TEST_GP_ELISA_MFGR, V.IGG_TEST_OTHER, V.IGG_TEST_ACUTE_DATE, V.IGG_TEST_ACUTE_RESULT, V.IGG_TEST_ACUTE_VALUE, V.IGG_TEST_CONVALESCENT_DATE, V.IGG_TEST_CONVALESCENT_RESULT, V.IGG_TEST_CONVALESCENT_VALUE, V.GENOTYPING_SENT_TO_CDC, V.GENOTYPING_SENT_TO_CDC_DATE, V.STRAIN_IDENTIFICATION_SENT, V.STRAIN_TYPE, V.VARICELLA_VACCINE, V.VARICELLA_NO_VACCINE_REASON, V.VARICELLA_NO_VACCINE_OTHER, V.VARICELLA_VACCINE_DOSES_NUMBER, V.VARICELLA_NO_2NDVACCINE_REASON, V.VARICELLA_NO_2NDVACCINE_OTHER, V.VACCINE_DATE_1, V.VACCINE_TYPE_1, V.VACCINE_MANUFACTURER_1, V.VACCINE_LOT_1, V.VACCINE_DATE_2, V.VACCINE_TYPE_2, V.VACCINE_MANUFACTURER_2, V.VACCINE_LOT_2, V.VACCINE_DATE_3, V.VACCINE_TYPE_3, V.VACCINE_MANUFACTURER_3, V.VACCINE_LOT_3, V.VACCINE_DATE_4, V.VACCINE_TYPE_4, V.VACCINE_MANUFACTURER_4, V.VACCINE_LOT_4, V.VACCINE_DATE_5, V.VACCINE_TYPE_5, V.VACCINE_MANUFACTURER_5, V.VACCINE_LOT_5, V.PREVIOUS_DIAGNOSIS, V.PREVIOUS_DIAGNOSIS_AGE, V.PREVIOUS_DIAGNOSIS_AGE_UNIT, V.PREVIOUS_DIAGNOSIS_BY, V.PREVIOUS_DIAGNOSIS_BY_OTHER, V.PATIENT_BIRTH_COUNTRY, V.EPI_LINKED, V.EPI_LINKED_CASE_TYPE, V.TRANSMISSION_SETTING, V.TRANSMISSION_SETTING_OTHER, V.HEALTHCARE_WORKER, V.OUTBREAK, V.OUTBREAK_NAME, V.PREGNANT, V.PREGNANT_WEEKS, V.PREGNANT_TRIMESTER, V.CASE_STATUS, V.MMWR_WEEK, V.MMWR_YEAR, V.GENERAL_COMMENTS, V.INVESTIGATION_CREATE_DATE, V.INVESTIGATION_CREATED_BY, V.INVESTIGATION_LAST_UPDTD_DATE, V.INVESTIGATION_LAST_UPDTD_BY, V.PROGRAM_JURISDICTION_OID, V.NOTIFICATION_SUBMITTER, V.NOTIFICATION_SENT_DATE, V.EVENT_DATE, V.NOTIFICATION_STATUS, V.NOTIFICATION_LOCAL_ID, V.EVENT_DATE_TYPE, V.PHYSICIAN_FIRST_NAME, V.PHYSICIAN_LAST_NAME, V.PHYSICIAN_PHONE_NUMBER, V.ILLNESS_END_DATE, V.ILLNESS_DURATION, V.ILLNESS_DURATION_UNIT, V.DAYCARE, V.FOOD_HANDLER, V.DISEASE_ACQUIRED_WHERE, V.DISEASE_ACQUIRED_COUNTRY, V.DISEASE_ACQUIRED_STATE, V.DISEASE_ACQUIRED_CITY, V.DISEASE_ACQUIRED_COUNTY, V.TRANSMISSION_MODE, V.DETECTION_METHOD
            FROM #VAR_DATAMART_NOT_EVENT V
            LEFT JOIN DBO.VAR_DATAMART D with (nolock)
            ON D.INVESTIGATION_KEY = V.INVESTIGATION_KEY
            WHERE D.INVESTIGATION_KEY is null and V.investigation_key > 0;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        
        COMMIT TRANSACTION;
        
--------------------------------------------------------------------------------------------------------
    
    BEGIN TRANSACTION
    
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'SP_COMPLETE';
          
        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'SP_COMPLETE', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;

        SELECT
            CAST(NULL AS BIGINT) AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            CAST(NULL AS VARCHAR(30)) AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            CAST(NULL AS VARCHAR(200)) AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=0;
        
--------------------------------------------------------------------------------------------------------
   
    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0   
            BEGIN
                ROLLBACK TRANSACTION;
            END;

        DECLARE @FullErrorMessage VARCHAR(8000) =
		'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
		'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		'Error Message: ' + ERROR_MESSAGE();


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
        VALUES (
            @batch_id
            ,@dataflow_name
            ,@package_name
            ,'ERROR'
            ,@Proc_Step_no
            , @Proc_Step_name
            , @FullErrorMessage
            ,0
		);

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
---------------------------------------------------END OF PROCEDURE---------------------------------------------------------------------
        
        