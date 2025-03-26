CREATE OR ALTER PROCEDURE dbo.sp_nrt_d_var_pam_postprocessing 
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
            declare @dataflow_name varchar(200) = 'd_var_pam POST-Processing';
            declare @package_name varchar(200) = 'RDB_MODERN.sp_nrt_d_var_pam_postprocessing';
                set @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);

        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT], [Msg_Description1])
        VALUES (@BATCH_ID, @dataflow_name, @package_name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO, LEFT (@phc_uids, 199));

    
--------------------------------------------------------------------------------------------------------
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING S_PHC_LIST TABLE';
          
        IF OBJECT_ID('#S_PHC_LIST', 'U') IS NOT NULL
            drop table #S_PHC_LIST;

        SELECT value
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
            @PROC_STEP_NAME = 'GENERATING #S_VAR_PAM_SET_TRANSLATED TABLE';
          
        
        IF OBJECT_ID('#S_VAR_PAM_SET_TRANSLATED', 'U') IS NOT NULL
            drop table #S_VAR_PAM_SET_TRANSLATED;

        --Step 2: Create S_VAR_PAM_SET_TRANSLATED temporary table
        SELECT 
            I.public_health_case_UID AS VAR_PAM_UID,
            NCA.CODE_SET_GROUP_ID,
            NCA.DATAMART_COLUMN_NM,
            NCA.ANSWER_TXT,
            NCA.RECORD_STATUS_CD,
            NCA.LAST_CHG_TIME,
            NCA.BATCH_ID,
            METADATA.CODE_SET_NM,
            CVG.CODE,
            CVG.CODE_SHORT_DESC_TXT AS CODE_SHORT_DESC_TXT
        INTO #S_VAR_PAM_SET_TRANSLATED
        FROM [dbo].nrt_investigation I  with (nolock)
        INNER JOIN #S_PHC_LIST PHC_LIST
            on I.public_health_case_UID = PHC_LIST.value
        LEFT JOIN dbo.nrt_page_case_answer NCA  with (nolock)
            on NCA.act_uid = I.public_health_case_UID
        LEFT JOIN dbo.NRT_SRTE_CODESET_GROUP_METADATA METADATA with (nolock)
            ON METADATA.CODE_SET_GROUP_ID = NCA.CODE_SET_GROUP_ID
        LEFT JOIN dbo.NRT_SRTE_CODE_VALUE_GENERAL CVG with (nolock)
            ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
            AND CVG.CODE = NCA.ANSWER_TXT
        where I.investigation_form_cd = 'INV_FORM_VAR'
            AND NCA.ldf_status_cd IS NULL
            AND NCA.nbs_ui_component_uid <> 1013
            AND NCA.nbs_question_uid IS NOT NULL
            AND NCA.DATAMART_COLUMN_NM IS NOT NULL
            AND NCA.RECORD_STATUS_CD <> 'LOG_DEL'
            AND NCA.data_location = 'NBS_Case_Answer.answer_txt'
            AND NCA.DATAMART_COLUMN_NM <> 'N/A'
            AND I.cd IN (
                SELECT condition_cd 
                FROM dbo.NRT_SRTE_condition_code 
                WHERE investigation_form_cd = 'INV_FORM_VAR'
            )
            AND isnull(I.batch_id, 1) = isnull(NCA.batch_id, 1);


        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_VAR_PAM_SET_TRANSLATED;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        

--------------------------------------------------------------------------------------------------------
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #S_VAR_PAM_SET_CVG TABLE';
        
        
        IF OBJECT_ID('#S_VAR_PAM_SET_CVG', 'U') IS NOT NULL
            drop table #S_VAR_PAM_SET_CVG;
        
        -- Step 3: Apply conditional logic for ANSWER_TXT (equivalent to DATA S_VAR_PAM_SET_CVG)
        SELECT 
            VAR_PAM_UID,
            CODE_SET_GROUP_ID,
            DATAMART_COLUMN_NM,
            CASE 
                WHEN CODE_SET_GROUP_ID = '' 
                     AND CODE_SET_NM NOT IN ('STATE_CCD', 'COUNTY_CCD', 'PSL_CNTRY', 'S_JURDIC_C', 'S_PROGRA_C') 
                THEN ANSWER_TXT
                WHEN CODE_SET_NM NOT IN ('STATE_CCD', 'COUNTY_CCD', 'PSL_CNTRY', 'S_JURDIC_C', 'S_PROGRA_C')
                THEN CODE_SHORT_DESC_TXT
                ELSE ANSWER_TXT
            END AS ANSWER_TXT,
            CODE_SET_NM,
            RECORD_STATUS_CD,
            LAST_CHG_TIME,
            CODE,
            CODE_SHORT_DESC_TXT
        INTO #S_VAR_PAM_SET_CVG
        FROM #S_VAR_PAM_SET_TRANSLATED;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_VAR_PAM_SET_CVG;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
    
--------------------------------------------------------------------------------------------------------
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #S_VAR_PAM_SET_CVG2 TABLE';
          
        
        
        IF OBJECT_ID('#S_VAR_PAM_SET_CVG2', 'U') IS NOT NULL
            drop table #S_VAR_PAM_SET_CVG2;
        

        -- Step 4: Join with COUNTRY_CODE and update ANSWER_TXT
        SELECT 
            VAR.VAR_PAM_UID,
            VAR.CODE_SET_GROUP_ID,
            VAR.DATAMART_COLUMN_NM,
            CASE 
                WHEN VAR.CODE_SET_GROUP_ID = '' AND VAR.CODE_SET_NM NOT IN ('PSL_CNTRY') 
                THEN VAR.ANSWER_TXT
                WHEN VAR.CODE_SET_NM = 'PSL_CNTRY' 
                THEN CVG.CODE_DESC_TXT
                ELSE VAR.ANSWER_TXT
            END AS ANSWER_TXT,
            VAR.CODE_SET_NM,
            VAR.RECORD_STATUS_CD,
            VAR.LAST_CHG_TIME,
            VAR.CODE,
            CVG.CODE_DESC_TXT
        INTO #S_VAR_PAM_SET_CVG2
        FROM #S_VAR_PAM_SET_CVG VAR
        LEFT JOIN dbo.NRT_SRTE_COUNTRY_CODE CVG with (nolock)
            ON CVG.CODE = VAR.ANSWER_TXT
            AND VAR.CODE_SET_NM = 'PSL_CNTRY';
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_VAR_PAM_SET_CVG2;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
    
--------------------------------------------------------------------------------------------------------
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #S_PAM_CHG_TIME TABLE';
          
        
        
        IF OBJECT_ID('#S_PAM_CHG_TIME', 'U') IS NOT NULL
            drop table #S_PAM_CHG_TIME;
        
        -- Step 5: Create S_PAM_CHG_TIME temporary table
        SELECT DISTINCT 
            VAR_PAM_UID,
            LAST_CHG_TIME
        INTO #S_PAM_CHG_TIME
        FROM #S_VAR_PAM_SET_CVG;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_PAM_CHG_TIME;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
            
--------------------------------------------------------------------------------------------------------
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #S_VAR_PAM1 TABLE';
          
        
        IF OBJECT_ID('#S_VAR_PAM1', 'U') IS NOT NULL
            drop table #S_VAR_PAM1;

        -- Pivot transformation
        SELECT *
        INTO #S_VAR_PAM1
        FROM (
            SELECT 
                VAR_PAM_UID,
                DATAMART_COLUMN_NM,
                ANSWER_TXT
            FROM #S_VAR_PAM_SET_CVG
        ) AS SourceTable
        PIVOT (
            MAX(ANSWER_TXT)
            FOR DATAMART_COLUMN_NM IN (
                VACCINE_TYPE_2, VACCINE_MANUFACTURER_1, EPI_LINKED, PCR_TEST, 
                VARICELLA_NO_VACCINE_REASON, SEROLOGY_TEST, DFA_TEST_RESULT, 
                HEALTHCARE_WORKER, IGG_TEST_WHOLE_CELL_MFGR, PREVIOUS_DIAGNOSIS_AGE_UNIT,
                PREGNANT_TRIMESTER, PREVIOUS_DIAGNOSIS, LAB_TESTING_OTHER_SPECIFY,
                IGM_TEST_TYPE, FEVER_TEMPERATURE_UNIT, IGG_TEST, MEDICATION_NAME,
                VACCINE_MANUFACTURER_3, COMPLICATIONS_PNEUMONIA, DFA_TEST, VESICLES,
                VARICELLA_NO_2NDVACCINE_REASON, IGM_TEST, VACCINE_TYPE_4,
                COMPLICATIONS_CEREB_ATAXIA, FEVER, STRAIN_TYPE, LAB_TESTING_OTHER_RESULT,
                CROPS_WAVES, TREATED, RASH_LOCATION, PATIENT_VISIT_HC_PROVIDER,
                RASH_CRUST, TRANSMISSION_SETTING, CULTURE_TEST_RESULT, HEMORRHAGIC,
                CULTURE_TEST, VACCINE_TYPE_1, PCR_TEST_RESULT, LAB_TESTING_OTHER,
                COMPLICATIONS, COMPLICATIONS_PNEU_DIAG_BY, VACCINE_TYPE_5,
                IGG_TEST_TYPE, EPI_LINKED_CASE_TYPE, VACCINE_MANUFACTURER_4,
                MACULAR_PAPULAR, VACCINE_TYPE_3, PREVIOUS_DIAGNOSIS_BY, VESICULAR,
                VACCINE_MANUFACTURER_5, DEATH_VARICELLA, IGG_TEST_GP_ELISA_MFGR,
                VARICELLA_VACCINE, IGM_TEST_RESULT, IMMUNOCOMPROMISED, COMPLICATIONS_OTHER,
                ITCHY, PATIENT_BIRTH_COUNTRY, DEATH_AUTOPSY, COMPLICATIONS_ENCEPHALITIS,
                COMPLICATIONS_HEMORRHAGIC, COMPLICATIONS_SKIN_INFECTION,
                COMPLICATIONS_DEHYDRATION, VACCINE_MANUFACTURER_2, GENOTYPING_SENT_TO_CDC,
                STRAIN_IDENTIFICATION_SENT, IGG_TEST_CONVALESCENT_RESULT,
                IGG_TEST_ACUTE_RESULT, LAB_TESTING, PAPULES, SCABS, LESIONS_TOTAL,
                MACULES, PCR_TEST_SOURCE_OTHER, VARICELLA_NO_2NDVACCINE_OTHER,
                VACCINE_LOT_5, RASH_LOCATION_DERMATOME, IGG_TEST_OTHER, VACCINE_LOT_4,
                VACCINE_LOT_1, DEATH_CAUSE, VARICELLA_NO_VACCINE_OTHER,
                IGG_TEST_ACUTE_VALUE, TRANSMISSION_SETTING_OTHER,
                IMMUNOCOMPROMISED_CONDITION, LAB_TESTING_OTHER_RESULT_VALUE,
                VACCINE_LOT_3, MEDICATION_NAME_OTHER, PREVIOUS_DIAGNOSIS_BY_OTHER,
                RASH_LOCATION_OTHER, IGG_TEST_CONVALESCENT_VALUE, IGM_TEST_TYPE_OTHER,
                PCR_TEST_RESULT_OTHER, VACCINE_LOT_2, IGM_TEST_RESULT_VALUE,
                COMPLICATIONS_OTHER_SPECIFY,IGG_TEST_ACUTE_DATE, VACCINE_DATE_4, 
                PCR_TEST_DATE, VACCINE_DATE_2, MEDICATION_START_DATE, DFA_TEST_DATE, 
                VACCINE_DATE_3, IGG_TEST_CONVALESCENT_DATE, MEDICATION_STOP_DATE, 
                VACCINE_DATE_1, LAB_TESTING_OTHER_DATE, CULTURE_TEST_DATE, GENOTYPING_SENT_TO_CDC_DATE, 
                FEVER_ONSET_DATE, RASH_ONSET_DATE, DEATH_VARICELLA_DATE, IGM_TEST_DATE, VACCINE_DATE_5, 
                VARICELLA_VACCINE_DOSES_NUMBER, FEVER_DURATION_DAYS, PREVIOUS_DIAGNOSIS_AGE, 
                LESIONS_TOTAL_LT50, VESICLES_NUMBER, MACULES_NUMBER, PAPULES_NUMBER, 
                PREGNANT_WEEKS, RASH_CRUSTED_DAYS, RASH_DURATION_DAYS, FEVER_TEMPERATURE
            )
        ) AS PivotTable;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_VAR_PAM1;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
    
--------------------------------------------------------------------------------------------------------
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #S_VAR_PAM TABLE';
          
        
        IF OBJECT_ID('#S_VAR_PAM', 'U') IS NOT NULL
            drop table #S_VAR_PAM;

        -- Final transformation with date and numeric conversions
        SELECT 
            S1.VAR_PAM_UID,
            S1.VACCINE_TYPE_2,
            S1.VACCINE_MANUFACTURER_1,
            S1.EPI_LINKED,
            S1.PCR_TEST,
            S1.VARICELLA_NO_VACCINE_REASON,
            S1.SEROLOGY_TEST,
            S1.DFA_TEST_RESULT,
            S1.HEALTHCARE_WORKER,
            S1.IGG_TEST_WHOLE_CELL_MFGR,
            S1.PREVIOUS_DIAGNOSIS_AGE_UNIT,
            S1.PREGNANT_TRIMESTER,
            S1.PREVIOUS_DIAGNOSIS,
            S1.LAB_TESTING_OTHER_SPECIFY,
            S1.IGM_TEST_TYPE,
            S1.FEVER_TEMPERATURE_UNIT,
            S1.IGG_TEST,
            S1.MEDICATION_NAME,
            S1.VACCINE_MANUFACTURER_3,
            S1.COMPLICATIONS_PNEUMONIA,
            S1.DFA_TEST,
            S1.VESICLES,
            S1.VARICELLA_NO_2NDVACCINE_REASON,
            S1.IGM_TEST,
            S1.VACCINE_TYPE_4,
            S1.COMPLICATIONS_CEREB_ATAXIA,
            S1.FEVER,
            S1.STRAIN_TYPE,
            S1.LAB_TESTING_OTHER_RESULT,
            S1.CROPS_WAVES,
            S1.TREATED,
            S1.RASH_LOCATION,
            S1.PATIENT_VISIT_HC_PROVIDER,
            S1.RASH_CRUST,
            S1.TRANSMISSION_SETTING,
            S1.CULTURE_TEST_RESULT,
            S1.HEMORRHAGIC,
            S1.CULTURE_TEST,
            S1.VACCINE_TYPE_1,
            S1.PCR_TEST_RESULT,
            S1.LAB_TESTING_OTHER,
            S1.COMPLICATIONS,
            S1.COMPLICATIONS_PNEU_DIAG_BY,
            S1.VACCINE_TYPE_5,
            S1.IGG_TEST_TYPE,
            S1.EPI_LINKED_CASE_TYPE,
            S1.VACCINE_MANUFACTURER_4,
            S1.MACULAR_PAPULAR,
            S1.VACCINE_TYPE_3,
            S1.PREVIOUS_DIAGNOSIS_BY,
            S1.VESICULAR,
            S1.VACCINE_MANUFACTURER_5,
            S1.DEATH_VARICELLA,
            S1.IGG_TEST_GP_ELISA_MFGR,
            S1.VARICELLA_VACCINE,
            S1.IGM_TEST_RESULT,
            S1.IMMUNOCOMPROMISED,
            S1.COMPLICATIONS_OTHER,
            S1.ITCHY,
            S1.PATIENT_BIRTH_COUNTRY,
            S1.DEATH_AUTOPSY,
            S1.COMPLICATIONS_ENCEPHALITIS,
            S1.COMPLICATIONS_HEMORRHAGIC,
            S1.COMPLICATIONS_SKIN_INFECTION,
            S1.COMPLICATIONS_DEHYDRATION,
            S1.VACCINE_MANUFACTURER_2,
            S1.GENOTYPING_SENT_TO_CDC,
            S1.STRAIN_IDENTIFICATION_SENT,
            S1.IGG_TEST_CONVALESCENT_RESULT,
            S1.IGG_TEST_ACUTE_RESULT,
            S1.LAB_TESTING,
            S1.PAPULES,
            S1.SCABS,
            S1.LESIONS_TOTAL,
            S1.MACULES,
            S1.PCR_TEST_SOURCE_OTHER,
            S1.VARICELLA_NO_2NDVACCINE_OTHER,
            S1.VACCINE_LOT_5,
            S1.RASH_LOCATION_DERMATOME,
            S1.IGG_TEST_OTHER,
            S1.VACCINE_LOT_4,
            S1.VACCINE_LOT_1,
            S1.DEATH_CAUSE,
            S1.VARICELLA_NO_VACCINE_OTHER,
            S1.IGG_TEST_ACUTE_VALUE,
            S1.TRANSMISSION_SETTING_OTHER,
            S1.IMMUNOCOMPROMISED_CONDITION,
            S1.LAB_TESTING_OTHER_RESULT_VALUE,
            S1.VACCINE_LOT_3,
            S1.MEDICATION_NAME_OTHER,
            S1.PREVIOUS_DIAGNOSIS_BY_OTHER,
            S1.RASH_LOCATION_OTHER,
            S1.IGG_TEST_CONVALESCENT_VALUE,
            S1.IGM_TEST_TYPE_OTHER,
            S1.PCR_TEST_RESULT_OTHER,
            S1.VACCINE_LOT_2,
            S1.IGM_TEST_RESULT_VALUE,
            S1.COMPLICATIONS_OTHER_SPECIFY,
            TRY_CAST(S1.IGG_TEST_ACUTE_DATE AS DATETIME) AS IGG_TEST_ACUTE_DATE,
            TRY_CAST(S1.VACCINE_DATE_4 AS DATETIME) AS VACCINE_DATE_4,
            TRY_CAST(S1.PCR_TEST_DATE AS DATETIME) AS PCR_TEST_DATE,
            TRY_CAST(S1.VACCINE_DATE_2 AS DATETIME) AS VACCINE_DATE_2,
            TRY_CAST(S1.MEDICATION_START_DATE AS DATETIME) AS MEDICATION_START_DATE,
            TRY_CAST(S1.DFA_TEST_DATE AS DATETIME) AS DFA_TEST_DATE,
            TRY_CAST(S1.VACCINE_DATE_3 AS DATETIME) AS VACCINE_DATE_3,
            TRY_CAST(S1.IGG_TEST_CONVALESCENT_DATE AS DATETIME) AS IGG_TEST_CONVALESCENT_DATE,
            TRY_CAST(S1.MEDICATION_STOP_DATE AS DATETIME) AS MEDICATION_STOP_DATE,
            TRY_CAST(S1.VACCINE_DATE_1 AS DATETIME) AS VACCINE_DATE_1,
            TRY_CAST(S1.LAB_TESTING_OTHER_DATE AS DATETIME) AS LAB_TESTING_OTHER_DATE,
            TRY_CAST(S1.CULTURE_TEST_DATE AS DATETIME) AS CULTURE_TEST_DATE,
            TRY_CAST(S1.GENOTYPING_SENT_TO_CDC_DATE AS DATETIME) AS GENOTYPING_SENT_TO_CDC_DATE,
            TRY_CAST(S1.FEVER_ONSET_DATE AS DATETIME) AS FEVER_ONSET_DATE,
            TRY_CAST(S1.RASH_ONSET_DATE AS DATETIME) AS RASH_ONSET_DATE,
            TRY_CAST(S1.DEATH_VARICELLA_DATE AS DATETIME) AS DEATH_VARICELLA_DATE,
            TRY_CAST(S1.IGM_TEST_DATE AS DATETIME) AS IGM_TEST_DATE,
            TRY_CAST(S1.VACCINE_DATE_5 AS DATETIME) AS VACCINE_DATE_5,
            TRY_CAST(REPLACE(S1.VARICELLA_VACCINE_DOSES_NUMBER, ',', '') AS DECIMAL(20,0)) AS VARICELLA_VACCINE_DOSES_NUMBER,
            TRY_CAST(REPLACE(S1.FEVER_DURATION_DAYS, ',', '') AS DECIMAL(20,0)) AS FEVER_DURATION_DAYS,
            TRY_CAST(REPLACE(S1.PREVIOUS_DIAGNOSIS_AGE, ',', '') AS DECIMAL(20,0)) AS PREVIOUS_DIAGNOSIS_AGE,
            TRY_CAST(REPLACE(S1.LESIONS_TOTAL_LT50, ',', '') AS DECIMAL(20,0)) AS LESIONS_TOTAL_LT50,
            TRY_CAST(REPLACE(S1.VESICLES_NUMBER, ',', '') AS DECIMAL(20,0)) AS VESICLES_NUMBER,
            TRY_CAST(REPLACE(S1.MACULES_NUMBER, ',', '') AS DECIMAL(20,0)) AS MACULES_NUMBER,
            TRY_CAST(REPLACE(S1.PAPULES_NUMBER, ',', '') AS DECIMAL(20,0)) AS PAPULES_NUMBER,
            TRY_CAST(REPLACE(S1.PREGNANT_WEEKS, ',', '') AS DECIMAL(20,0)) AS PREGNANT_WEEKS,
            TRY_CAST(REPLACE(S1.RASH_CRUSTED_DAYS, ',', '') AS DECIMAL(20,0)) AS RASH_CRUSTED_DAYS,
            TRY_CAST(REPLACE(S1.RASH_DURATION_DAYS, ',', '') AS DECIMAL(20,0)) AS RASH_DURATION_DAYS,
            TRY_CAST(REPLACE(S1.FEVER_TEMPERATURE, ',', '') AS DECIMAL(20,0)) AS FEVER_TEMPERATURE,
            CT.LAST_CHG_TIME
        INTO #S_VAR_PAM
        FROM #S_VAR_PAM1 S1
        INNER JOIN #S_PAM_CHG_TIME CT
            ON S1.VAR_PAM_UID = CT.VAR_PAM_UID
        WHERE S1.VAR_PAM_UID IS NOT NULL;
        
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_VAR_PAM;
        

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
            @PROC_STEP_NAME = 'GENERATING Keys for nrt_var_pam_key TABLE';
          
        --insert new items to generate key 
		INSERT INTO [dbo].[nrt_var_pam_key] (VAR_PAM_UID)
		SELECT 
			S.VAR_PAM_UID
        FROM #S_VAR_PAM S
		left join dbo.NRT_VAR_PAM_KEY N
            on S.VAR_PAM_UID = N.VAR_PAM_UID
        where N.VAR_PAM_UID is null;
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;
    

--------------------------------------------------------------------------------------------------------
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING TEMP table for updates and inserts';

        IF OBJECT_ID('#L_VAR_PAM', 'U') IS NOT NULL
            drop table #L_VAR_PAM;
          
        --insert new items to generate key 
		SELECT 
			S.*,
            N.D_VAR_PAM_KEY
        INTO #L_VAR_PAM
        FROM DBO.NRT_VAR_PAM_KEY N with (nolock)
        INNER JOIN #S_VAR_PAM S
            ON 	N.VAR_PAM_UID= S.VAR_PAM_UID;
       

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
            @PROC_STEP_NAME = 'Update Dim_Table for nrt_var_pam_key TABLE';


        UPDATE DBO.D_VAR_PAM
        SET VACCINE_TYPE_2 = L.VACCINE_TYPE_2,
            VACCINE_MANUFACTURER_1 = L.VACCINE_MANUFACTURER_1,
            EPI_LINKED = L.EPI_LINKED,
            PCR_TEST = L.PCR_TEST,
            VARICELLA_NO_VACCINE_REASON = L.VARICELLA_NO_VACCINE_REASON,
            SEROLOGY_TEST = L.SEROLOGY_TEST,
            DFA_TEST_RESULT = L.DFA_TEST_RESULT,
            HEALTHCARE_WORKER = L.HEALTHCARE_WORKER,
            IGG_TEST_WHOLE_CELL_MFGR = L.IGG_TEST_WHOLE_CELL_MFGR,
            PREVIOUS_DIAGNOSIS_AGE_UNIT = L.PREVIOUS_DIAGNOSIS_AGE_UNIT,
            PREGNANT_TRIMESTER = L.PREGNANT_TRIMESTER,
            PREVIOUS_DIAGNOSIS = L.PREVIOUS_DIAGNOSIS,
            LAB_TESTING_OTHER_SPECIFY = L.LAB_TESTING_OTHER_SPECIFY,
            IGM_TEST_TYPE = L.IGM_TEST_TYPE,
            FEVER_TEMPERATURE_UNIT = L.FEVER_TEMPERATURE_UNIT,
            IGG_TEST = L.IGG_TEST,
            MEDICATION_NAME = L.MEDICATION_NAME,
            VACCINE_MANUFACTURER_3 = L.VACCINE_MANUFACTURER_3,
            COMPLICATIONS_PNEUMONIA = L.COMPLICATIONS_PNEUMONIA,
            DFA_TEST = L.DFA_TEST,
            VESICLES = L.VESICLES,
            VARICELLA_NO_2NDVACCINE_REASON = L.VARICELLA_NO_2NDVACCINE_REASON,
            IGM_TEST = L.IGM_TEST,
            VACCINE_TYPE_4 = L.VACCINE_TYPE_4,
            COMPLICATIONS_CEREB_ATAXIA = L.COMPLICATIONS_CEREB_ATAXIA,
            FEVER = L.FEVER,
            STRAIN_TYPE = L.STRAIN_TYPE,
            LAB_TESTING_OTHER_RESULT = L.LAB_TESTING_OTHER_RESULT,
            CROPS_WAVES = L.CROPS_WAVES,
            TREATED = L.TREATED,
            RASH_LOCATION = L.RASH_LOCATION,
            PATIENT_VISIT_HC_PROVIDER = L.PATIENT_VISIT_HC_PROVIDER,
            RASH_CRUST = L.RASH_CRUST,
            TRANSMISSION_SETTING = L.TRANSMISSION_SETTING,
            CULTURE_TEST_RESULT = L.CULTURE_TEST_RESULT,
            HEMORRHAGIC = L.HEMORRHAGIC,
            CULTURE_TEST = L.CULTURE_TEST,
            VACCINE_TYPE_1 = L.VACCINE_TYPE_1,
            PCR_TEST_RESULT = L.PCR_TEST_RESULT,
            LAB_TESTING_OTHER = L.LAB_TESTING_OTHER,
            COMPLICATIONS = L.COMPLICATIONS,
            COMPLICATIONS_PNEU_DIAG_BY = L.COMPLICATIONS_PNEU_DIAG_BY,
            VACCINE_TYPE_5 = L.VACCINE_TYPE_5,
            IGG_TEST_TYPE = L.IGG_TEST_TYPE,
            EPI_LINKED_CASE_TYPE = L.EPI_LINKED_CASE_TYPE,
            VACCINE_MANUFACTURER_4 = L.VACCINE_MANUFACTURER_4,
            MACULAR_PAPULAR = L.MACULAR_PAPULAR,
            VACCINE_TYPE_3 = L.VACCINE_TYPE_3,
            PREVIOUS_DIAGNOSIS_BY = L.PREVIOUS_DIAGNOSIS_BY,
            VESICULAR = L.VESICULAR,
            VACCINE_MANUFACTURER_5 = L.VACCINE_MANUFACTURER_5,
            DEATH_VARICELLA = L.DEATH_VARICELLA,
            IGG_TEST_GP_ELISA_MFGR = L.IGG_TEST_GP_ELISA_MFGR,
            VARICELLA_VACCINE = L.VARICELLA_VACCINE,
            IGM_TEST_RESULT = L.IGM_TEST_RESULT,
            IMMUNOCOMPROMISED = L.IMMUNOCOMPROMISED,
            COMPLICATIONS_OTHER = L.COMPLICATIONS_OTHER,
            ITCHY = L.ITCHY,
            PATIENT_BIRTH_COUNTRY = L.PATIENT_BIRTH_COUNTRY,
            DEATH_AUTOPSY = L.DEATH_AUTOPSY,
            COMPLICATIONS_ENCEPHALITIS = L.COMPLICATIONS_ENCEPHALITIS,
            COMPLICATIONS_HEMORRHAGIC = L.COMPLICATIONS_HEMORRHAGIC,
            COMPLICATIONS_SKIN_INFECTION = L.COMPLICATIONS_SKIN_INFECTION,
            COMPLICATIONS_DEHYDRATION = L.COMPLICATIONS_DEHYDRATION,
            VACCINE_MANUFACTURER_2 = L.VACCINE_MANUFACTURER_2,
            GENOTYPING_SENT_TO_CDC = L.GENOTYPING_SENT_TO_CDC,
            STRAIN_IDENTIFICATION_SENT = L.STRAIN_IDENTIFICATION_SENT,
            IGG_TEST_CONVALESCENT_RESULT = L.IGG_TEST_CONVALESCENT_RESULT,
            IGG_TEST_ACUTE_RESULT = L.IGG_TEST_ACUTE_RESULT,
            LAB_TESTING = L.LAB_TESTING,
            PAPULES = L.PAPULES,
            SCABS = L.SCABS,
            LESIONS_TOTAL = L.LESIONS_TOTAL,
            MACULES = L.MACULES,
            IGG_TEST_ACUTE_DATE = L.IGG_TEST_ACUTE_DATE,
            VACCINE_DATE_4 = L.VACCINE_DATE_4,
            PCR_TEST_DATE = L.PCR_TEST_DATE,
            VACCINE_DATE_2 = L.VACCINE_DATE_2,
            MEDICATION_START_DATE = L.MEDICATION_START_DATE,
            DFA_TEST_DATE = L.DFA_TEST_DATE,
            VACCINE_DATE_3 = L.VACCINE_DATE_3,
            IGG_TEST_CONVALESCENT_DATE = L.IGG_TEST_CONVALESCENT_DATE,
            MEDICATION_STOP_DATE = L.MEDICATION_STOP_DATE,
            VACCINE_DATE_1 = L.VACCINE_DATE_1,
            LAB_TESTING_OTHER_DATE = L.LAB_TESTING_OTHER_DATE,
            CULTURE_TEST_DATE = L.CULTURE_TEST_DATE,
            GENOTYPING_SENT_TO_CDC_DATE = L.GENOTYPING_SENT_TO_CDC_DATE,
            FEVER_ONSET_DATE = L.FEVER_ONSET_DATE,
            RASH_ONSET_DATE = L.RASH_ONSET_DATE,
            DEATH_VARICELLA_DATE = L.DEATH_VARICELLA_DATE,
            IGM_TEST_DATE = L.IGM_TEST_DATE,
            VACCINE_DATE_5 = L.VACCINE_DATE_5,
            VARICELLA_VACCINE_DOSES_NUMBER = L.VARICELLA_VACCINE_DOSES_NUMBER,
            FEVER_DURATION_DAYS = L.FEVER_DURATION_DAYS,
            PREVIOUS_DIAGNOSIS_AGE = L.PREVIOUS_DIAGNOSIS_AGE,
            LESIONS_TOTAL_LT50 = L.LESIONS_TOTAL_LT50,
            VESICLES_NUMBER = L.VESICLES_NUMBER,
            MACULES_NUMBER = L.MACULES_NUMBER,
            PAPULES_NUMBER = L.PAPULES_NUMBER,
            PREGNANT_WEEKS = L.PREGNANT_WEEKS,
            RASH_CRUSTED_DAYS = L.RASH_CRUSTED_DAYS,
            RASH_DURATION_DAYS = L.RASH_DURATION_DAYS,
            FEVER_TEMPERATURE = L.FEVER_TEMPERATURE,
            PCR_TEST_SOURCE_OTHER = L.PCR_TEST_SOURCE_OTHER,
            VARICELLA_NO_2NDVACCINE_OTHER = L.VARICELLA_NO_2NDVACCINE_OTHER,
            VACCINE_LOT_5 = L.VACCINE_LOT_5,
            RASH_LOCATION_DERMATOME = L.RASH_LOCATION_DERMATOME,
            IGG_TEST_OTHER = L.IGG_TEST_OTHER,
            VACCINE_LOT_4 = L.VACCINE_LOT_4,
            VACCINE_LOT_1 = L.VACCINE_LOT_1,
            DEATH_CAUSE = L.DEATH_CAUSE,
            VARICELLA_NO_VACCINE_OTHER = L.VARICELLA_NO_VACCINE_OTHER,
            IGG_TEST_ACUTE_VALUE = L.IGG_TEST_ACUTE_VALUE,
            TRANSMISSION_SETTING_OTHER = L.TRANSMISSION_SETTING_OTHER,
            IMMUNOCOMPROMISED_CONDITION = L.IMMUNOCOMPROMISED_CONDITION,
            LAB_TESTING_OTHER_RESULT_VALUE = L.LAB_TESTING_OTHER_RESULT_VALUE,
            VACCINE_LOT_3 = L.VACCINE_LOT_3,
            MEDICATION_NAME_OTHER = L.MEDICATION_NAME_OTHER,
            PREVIOUS_DIAGNOSIS_BY_OTHER = L.PREVIOUS_DIAGNOSIS_BY_OTHER,
            RASH_LOCATION_OTHER = L.RASH_LOCATION_OTHER,
            IGG_TEST_CONVALESCENT_VALUE = L.IGG_TEST_CONVALESCENT_VALUE,
            IGM_TEST_TYPE_OTHER = L.IGM_TEST_TYPE_OTHER,
            PCR_TEST_RESULT_OTHER = L.PCR_TEST_RESULT_OTHER,
            VACCINE_LOT_2 = L.VACCINE_LOT_2,
            IGM_TEST_RESULT_VALUE = L.IGM_TEST_RESULT_VALUE,
            LAST_CHG_TIME  = L.LAST_CHG_TIME,
            COMPLICATIONS_OTHER_SPECIFY = L.COMPLICATIONS_OTHER_SPECIFY
        FROM #L_VAR_PAM L
        inner join DBO.D_VAR_PAM D with (nolock)
            ON D.D_VAR_PAM_KEY = L.D_VAR_PAM_KEY
        WHERE D.D_VAR_PAM_KEY IS not null;

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
            @PROC_STEP_NAME = 'INSERT INTO D_VAR_PAM TABLE';


        INSERT INTO DBO.D_VAR_PAM(D_VAR_PAM_KEY, VAR_PAM_UID, VACCINE_TYPE_2, VACCINE_MANUFACTURER_1, EPI_LINKED, 
            PCR_TEST, VARICELLA_NO_VACCINE_REASON, SEROLOGY_TEST, DFA_TEST_RESULT, HEALTHCARE_WORKER, 
            IGG_TEST_WHOLE_CELL_MFGR, PREVIOUS_DIAGNOSIS_AGE_UNIT, PREGNANT_TRIMESTER, PREVIOUS_DIAGNOSIS, 
            LAB_TESTING_OTHER_SPECIFY, IGM_TEST_TYPE, FEVER_TEMPERATURE_UNIT, IGG_TEST, MEDICATION_NAME, 
            VACCINE_MANUFACTURER_3, COMPLICATIONS_PNEUMONIA, DFA_TEST, VESICLES, VARICELLA_NO_2NDVACCINE_REASON, 
            IGM_TEST, VACCINE_TYPE_4, COMPLICATIONS_CEREB_ATAXIA, FEVER, STRAIN_TYPE, LAB_TESTING_OTHER_RESULT,
            CROPS_WAVES, TREATED, RASH_LOCATION, PATIENT_VISIT_HC_PROVIDER, RASH_CRUST, TRANSMISSION_SETTING, 
            CULTURE_TEST_RESULT, HEMORRHAGIC, CULTURE_TEST, VACCINE_TYPE_1, PCR_TEST_RESULT, LAB_TESTING_OTHER, 
            COMPLICATIONS, COMPLICATIONS_PNEU_DIAG_BY, VACCINE_TYPE_5, IGG_TEST_TYPE, EPI_LINKED_CASE_TYPE, 
            VACCINE_MANUFACTURER_4, MACULAR_PAPULAR, VACCINE_TYPE_3, PREVIOUS_DIAGNOSIS_BY, VESICULAR, 
            VACCINE_MANUFACTURER_5, DEATH_VARICELLA, IGG_TEST_GP_ELISA_MFGR, VARICELLA_VACCINE, IGM_TEST_RESULT, 
            IMMUNOCOMPROMISED, COMPLICATIONS_OTHER, ITCHY, PATIENT_BIRTH_COUNTRY, DEATH_AUTOPSY, 
            COMPLICATIONS_ENCEPHALITIS, COMPLICATIONS_HEMORRHAGIC, COMPLICATIONS_SKIN_INFECTION, COMPLICATIONS_DEHYDRATION, VACCINE_MANUFACTURER_2, 
            GENOTYPING_SENT_TO_CDC, STRAIN_IDENTIFICATION_SENT, IGG_TEST_CONVALESCENT_RESULT, IGG_TEST_ACUTE_RESULT, 
            LAB_TESTING, PAPULES, SCABS, LESIONS_TOTAL, MACULES, IGG_TEST_ACUTE_DATE, VACCINE_DATE_4, PCR_TEST_DATE, 
            VACCINE_DATE_2, MEDICATION_START_DATE, DFA_TEST_DATE, VACCINE_DATE_3, IGG_TEST_CONVALESCENT_DATE, 
            MEDICATION_STOP_DATE, VACCINE_DATE_1, LAB_TESTING_OTHER_DATE, CULTURE_TEST_DATE, GENOTYPING_SENT_TO_CDC_DATE, FEVER_ONSET_DATE, 
            RASH_ONSET_DATE, DEATH_VARICELLA_DATE, IGM_TEST_DATE, VACCINE_DATE_5, VARICELLA_VACCINE_DOSES_NUMBER, FEVER_DURATION_DAYS, 
            PREVIOUS_DIAGNOSIS_AGE, LESIONS_TOTAL_LT50, VESICLES_NUMBER, MACULES_NUMBER, PAPULES_NUMBER, PREGNANT_WEEKS, RASH_CRUSTED_DAYS, RASH_DURATION_DAYS, FEVER_TEMPERATURE, 
            PCR_TEST_SOURCE_OTHER, VARICELLA_NO_2NDVACCINE_OTHER, VACCINE_LOT_5, RASH_LOCATION_DERMATOME, IGG_TEST_OTHER, VACCINE_LOT_4, VACCINE_LOT_1, DEATH_CAUSE, 
            VARICELLA_NO_VACCINE_OTHER, IGG_TEST_ACUTE_VALUE, TRANSMISSION_SETTING_OTHER, IMMUNOCOMPROMISED_CONDITION, LAB_TESTING_OTHER_RESULT_VALUE, VACCINE_LOT_3, MEDICATION_NAME_OTHER, 
            PREVIOUS_DIAGNOSIS_BY_OTHER, RASH_LOCATION_OTHER, IGG_TEST_CONVALESCENT_VALUE, IGM_TEST_TYPE_OTHER, PCR_TEST_RESULT_OTHER, VACCINE_LOT_2, IGM_TEST_RESULT_VALUE, 
            LAST_CHG_TIME , COMPLICATIONS_OTHER_SPECIFY)
        SELECT L.D_VAR_PAM_KEY, L.VAR_PAM_UID, L.VACCINE_TYPE_2, L.VACCINE_MANUFACTURER_1, L.EPI_LINKED,
            L.PCR_TEST, L.VARICELLA_NO_VACCINE_REASON, L.SEROLOGY_TEST, L.DFA_TEST_RESULT, L.HEALTHCARE_WORKER,
            L.IGG_TEST_WHOLE_CELL_MFGR, L.PREVIOUS_DIAGNOSIS_AGE_UNIT, L.PREGNANT_TRIMESTER, L.PREVIOUS_DIAGNOSIS,
            L.LAB_TESTING_OTHER_SPECIFY, L.IGM_TEST_TYPE, L.FEVER_TEMPERATURE_UNIT, L.IGG_TEST, L.MEDICATION_NAME,
            L.VACCINE_MANUFACTURER_3, L.COMPLICATIONS_PNEUMONIA, L.DFA_TEST, L.VESICLES, L.VARICELLA_NO_2NDVACCINE_REASON,
            L.IGM_TEST, L.VACCINE_TYPE_4, L.COMPLICATIONS_CEREB_ATAXIA, L.FEVER, L.STRAIN_TYPE, L.LAB_TESTING_OTHER_RESULT,
            L.CROPS_WAVES, L.TREATED, L.RASH_LOCATION, L.PATIENT_VISIT_HC_PROVIDER, L.RASH_CRUST, L.TRANSMISSION_SETTING,
            L.CULTURE_TEST_RESULT, L.HEMORRHAGIC, L.CULTURE_TEST, L.VACCINE_TYPE_1, L.PCR_TEST_RESULT, L.LAB_TESTING_OTHER,
            L.COMPLICATIONS, L.COMPLICATIONS_PNEU_DIAG_BY, L.VACCINE_TYPE_5, L.IGG_TEST_TYPE, L.EPI_LINKED_CASE_TYPE,
            L.VACCINE_MANUFACTURER_4, L.MACULAR_PAPULAR, L.VACCINE_TYPE_3, L.PREVIOUS_DIAGNOSIS_BY, L.VESICULAR,
            L.VACCINE_MANUFACTURER_5, L.DEATH_VARICELLA, L.IGG_TEST_GP_ELISA_MFGR, L.VARICELLA_VACCINE, L.IGM_TEST_RESULT,
            L.IMMUNOCOMPROMISED, L.COMPLICATIONS_OTHER, L.ITCHY, L.PATIENT_BIRTH_COUNTRY, L.DEATH_AUTOPSY,
            L.COMPLICATIONS_ENCEPHALITIS, L.COMPLICATIONS_HEMORRHAGIC, L.COMPLICATIONS_SKIN_INFECTION, L.COMPLICATIONS_DEHYDRATION, L.VACCINE_MANUFACTURER_2,
            L.GENOTYPING_SENT_TO_CDC, L.STRAIN_IDENTIFICATION_SENT, L.IGG_TEST_CONVALESCENT_RESULT, L.IGG_TEST_ACUTE_RESULT,
            L.LAB_TESTING, L.PAPULES, L.SCABS, L.LESIONS_TOTAL, L.MACULES, L.IGG_TEST_ACUTE_DATE, L.VACCINE_DATE_4, L.PCR_TEST_DATE,
            L.VACCINE_DATE_2, L.MEDICATION_START_DATE, L.DFA_TEST_DATE, L.VACCINE_DATE_3, L.IGG_TEST_CONVALESCENT_DATE,
            L.MEDICATION_STOP_DATE, L.VACCINE_DATE_1, L.LAB_TESTING_OTHER_DATE, L.CULTURE_TEST_DATE, L.GENOTYPING_SENT_TO_CDC_DATE, L.FEVER_ONSET_DATE,
            L.RASH_ONSET_DATE, L.DEATH_VARICELLA_DATE, L.IGM_TEST_DATE, L.VACCINE_DATE_5, L.VARICELLA_VACCINE_DOSES_NUMBER, L.FEVER_DURATION_DAYS,
            L.PREVIOUS_DIAGNOSIS_AGE, L.LESIONS_TOTAL_LT50, L.VESICLES_NUMBER, L.MACULES_NUMBER, L.PAPULES_NUMBER, L.PREGNANT_WEEKS, L.RASH_CRUSTED_DAYS, L.RASH_DURATION_DAYS, L.FEVER_TEMPERATURE,
            L.PCR_TEST_SOURCE_OTHER, L.VARICELLA_NO_2NDVACCINE_OTHER, L.VACCINE_LOT_5, L.RASH_LOCATION_DERMATOME, L.IGG_TEST_OTHER, L.VACCINE_LOT_4, L.VACCINE_LOT_1, L.DEATH_CAUSE,
            L.VARICELLA_NO_VACCINE_OTHER, L.IGG_TEST_ACUTE_VALUE, L.TRANSMISSION_SETTING_OTHER, L.IMMUNOCOMPROMISED_CONDITION, L.LAB_TESTING_OTHER_RESULT_VALUE, L.VACCINE_LOT_3, L.MEDICATION_NAME_OTHER,
            L.PREVIOUS_DIAGNOSIS_BY_OTHER, L.RASH_LOCATION_OTHER, L.IGG_TEST_CONVALESCENT_VALUE, L.IGM_TEST_TYPE_OTHER, L.PCR_TEST_RESULT_OTHER, L.VACCINE_LOT_2, L.IGM_TEST_RESULT_VALUE,
            L.LAST_CHG_TIME , L.COMPLICATIONS_OTHER_SPECIFY
        FROM #L_VAR_PAM L
        LEFT join DBO.D_VAR_PAM D with (nolock)
            ON D.D_VAR_PAM_KEY = L.D_VAR_PAM_KEY
        WHERE D.D_VAR_PAM_KEY IS null;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;
    
--------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);
    
-------------------------------------------------------------------------------------------

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

        return -1 ;

    END CATCH

END;
---------------------------------------------------END OF PROCEDURE---------------------------------------------------------------------
        
        