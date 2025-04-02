CREATE OR ALTER PROCEDURE [dbo].[sp_tb_hiv_datamart_postprocessing] 
    @phc_id_list nvarchar(max),
    @debug bit = 'false'
AS
BEGIN

    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) AS BIGINT);
    PRINT @batch_id;
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT= 0;
    DECLARE @Proc_Step_Name VARCHAR(200)= '';
	DECLARE @Dataflow_Name VARCHAR(200) = 'TB_HIV_DATAMART POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_tb_hiv_datamart_postprocessing';

    BEGIN TRY
        

        SET @Proc_Step_Name = 'SP_Start';

        INSERT INTO dbo.job_flow_log ( batch_id
                                    , [Dataflow_Name]
                                    , [package_Name]
                                    , [Status_Type]
                                    , [step_number]
                                    , [step_name]
                                    , [row_count]
                                    , [Msg_Description1])
        VALUES ( @batch_id
            , @Dataflow_Name
            , @Package_Name
            , 'START'
            , @Proc_Step_no
            , @Proc_Step_Name
            , 0
            , LEFT('ID List-' + @phc_id_list, 500));

-------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #TB_HIV_WITH_UID';

        IF OBJECT_ID('tempdb..#TB_HIV_WITH_UID') IS NOT NULL
            DROP TABLE #TB_HIV_WITH_UID;

        -- Create temporary table #TB_HIV_WITH_UID
        SELECT 
            h.TB_PAM_UID,
            h.HIV_STATE_PATIENT_NUM,
            h.HIV_STATUS,
            h.HIV_CITY_CNTY_PATIENT_NUM,
            h.D_TB_HIV_KEY
        INTO #TB_HIV_WITH_UID
        FROM [dbo].D_TB_HIV h WITH(nolock) 
        INNER JOIN [dbo].D_TB_PAM p WITH(nolock) 
            ON h.TB_PAM_UID = p.TB_PAM_UID;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #TB_HIV_WITH_UID;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #TB_HIV_DATAMART';
        
        IF OBJECT_ID('tempdb..#TB_HIV_DATAMART') IS NOT NULL
            DROP TABLE #TB_HIV_WITH_UID;

        -- Create temporary table #TB_HIV_DATAMART
        SELECT 
            h.TB_PAM_UID, --AS TB_HIV_TB_PAM_UID,  -- Alias to avoid ambiguity
            h.HIV_STATE_PATIENT_NUM,
            h.HIV_STATUS,
            h.HIV_CITY_CNTY_PATIENT_NUM,
            CASE WHEN h.D_TB_HIV_KEY > 0 THEN h.D_TB_HIV_KEY ELSE 1 END AS D_TB_HIV_KEY,
            d.*  -- All columns from TB_DATAMART
        INTO #TB_HIV_DATAMART
        FROM #TB_HIV_WITH_UID h
        RIGHT OUTER JOIN [dbo].TB_DATAMART d WITH(nolock) 
            ON h.TB_PAM_UID = d.TB_PAM_UID;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #TB_HIV_DATAMART;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

--------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION
        
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERTING ROWS INTO TB_HIV_DATAMART';


            INSERT INTO [dbo].TB_HIV_DATAMART (
                [CALC_5_YEAR_AGE_GROUP]
                ,[CALC_10_YEAR_AGE_GROUP]
                ,[PATIENT_NAME_SUFFIX]
                ,[PATIENT_STATE]
                ,[PATIENT_COUNTY]
                ,[PATIENT_COUNTRY]
                ,[PATIENT_WITHIN_CITY_LIMITS]
                ,[AGE_REPORTED_UNIT]
                ,[PATIENT_BIRTH_SEX]
                ,[PATIENT_CURRENT_SEX]
                ,[PATIENT_DECEASED_INDICATOR]
                ,[PATIENT_MARITAL_STATUS]
                ,[PATIENT_ETHNICITY]
                ,[RACE_CALCULATED]
                ,[RACE_CALC_DETAILS]
                ,[RACE_ASIAN_1]
                ,[RACE_ASIAN_2]
                ,[RACE_ASIAN_3]
                ,[RACE_ASIAN_GT3_IND]
                ,[RACE_ASIAN_ALL]
                ,[RACE_NAT_HI_1]
                ,[RACE_NAT_HI_2]
                ,[RACE_NAT_HI_3]
                ,[RACE_NAT_HI_GT3_IND]
                ,[RACE_NAT_HI_ALL]
                ,[JURISDICTION_NAME]
                ,[PROGRAM_AREA_DESCRIPTION]
                ,[INVESTIGATION_STATUS]
                ,[LINK_REASON_1]
                ,[LINK_REASON_2]
                ,[PREVIOUS_DIAGNOSIS_IND]
                ,[US_BORN_IND]
                ,[PATIENT_BIRTH_COUNTRY]
                ,[PATIENT_OUTSIDE_US_GT_2_MONTHS]
                ,[OUT_OF_CNTRY_1]
                ,[OUT_OF_CNTRY_2]
                ,[OUT_OF_CNTRY_3]
                ,[OUT_OF_CNTRY_GT3_IND]
                ,[OUT_OF_CNTRY_ALL]
                ,[PRIMARY_GUARD_1_BIRTH_COUNTRY]
                ,[PRIMARY_GUARD_2_BIRTH_COUNTRY]
                ,[STATUS_AT_DIAGNOSIS]
                ,[DISEASE_SITE_1]
                ,[DISEASE_SITE_2]
                ,[DISEASE_SITE_3]
                ,[DISEASE_SITE_GT3_IND]
                ,[DISEASE_SITE_ALL]
                ,[CALC_DISEASE_SITE]
                ,[SPUTUM_SMEAR_RESULT]
                ,[SPUTUM_CULTURE_RESULT]
                ,[SPUTUM_CULT_RPT_LAB_TY]
                ,[SMR_PATH_CYTO_RESULT]
                ,[SMR_PATH_CYTO_SITE]
                ,[SMR_EXAM_TY_1]
                ,[SMR_EXAM_TY_2]
                ,[SMR_EXAM_TY_3]
                ,[SMR_EXAM_TY_GT3_IND]
                ,[SMR_EXAM_TY_ALL]
                ,[CULT_TISSUE_RESULT]
                ,[CULT_TISSUE_SITE]
                ,[CULT_TISSUE_RESULT_RPT_LAB_TY]
                ,[NAA_RESULT]
                ,[NAA_SPEC_IS_SPUTUM_IND]
                ,[NAA_SPEC_NOT_SPUTUM]
                ,[NAA_RPT_LAB_TY]
                ,[CHEST_XRAY_RESULT]
                ,[CHEST_XRAY_CAVITY_EVIDENCE]
                ,[CHEST_XRAY_MILIARY_EVIDENCE]
                ,[CT_SCAN_RESULT]
                ,[CT_SCAN_CAVITY_EVIDENCE]
                ,[CT_SCAN_MILIARY_EVIDENCE]
                ,[TST_RESULT]
                ,[IGRA_RESULT]
                ,[PRIMARY_REASON_EVALUATED]
                ,[HOMELESS_IND]
                ,[CORRECTIONAL_FACIL_RESIDENT]
                ,[CORRECTIONAL_FACIL_TY]
                ,[CORRECTIONAL_FACIL_CUSTODY_IND]
                ,[LONGTERM_CARE_FACIL_RESIDENT]
                ,[LONGTERM_CARE_FACIL_TY]
                ,[OCCUPATION_RISK]
                ,[INJECT_DRUG_USE_PAST_YEAR]
                ,[NONINJECT_DRUG_USE_PAST_YEAR]
                ,[ADDL_RISK_1]
                ,[EXCESS_ALCOHOL_USE_PAST_YEAR]
                ,[ADDL_RISK_2]
                ,[ADDL_RISK_GT3_IND]
                ,[ADDL_RISK_3]
                ,[ADDL_RISK_ALL]
                ,[IMMIGRATION_STATUS_AT_US_ENTRY]
                ,[INIT_REGIMEN_ISONIAZID]
                ,[INIT_REGIMEN_RIFAMPIN]
                ,[INIT_REGIMEN_PYRAZINAMIDE]
                ,[INIT_REGIMEN_ETHAMBUTOL]
                ,[INIT_REGIMEN_STREPTOMYCIN]
                ,[INIT_REGIMEN_ETHIONAMIDE]
                ,[INIT_REGIMEN_KANAMYCIN]
                ,[INIT_REGIMEN_CYCLOSERINE]
                ,[INIT_REGIMEN_CAPREOMYCIN]
                ,[INIT_REGIMEN_PA_SALICYLIC_ACID]
                ,[INIT_REGIMEN_AMIKACIN]
                ,[INIT_REGIMEN_RIFABUTIN]
                ,[INIT_REGIMEN_CIPROFLOXACIN]
                ,[INIT_REGIMEN_OFLOXACIN]
                ,[INIT_REGIMEN_RIFAPENTINE]
                ,[INIT_REGIMEN_LEVOFLOXACIN]
                ,[INIT_REGIMEN_MOXIFLOXACIN]
                ,[INIT_REGIMEN_OTHER_1_IND]
                ,[INIT_REGIMEN_OTHER_2_IND]
                ,[ISOLATE_SUBMITTED_IND]
                ,[INIT_SUSCEPT_TESTING_DONE]
                ,[FIRST_ISOLATE_IS_SPUTUM_IND]
                ,[FIRST_ISOLATE_NOT_SPUTUM]
                ,[INIT_SUSCEPT_ISONIAZID]
                ,[INIT_SUSCEPT_RIFAMPIN]
                ,[INIT_SUSCEPT_PYRAZINAMIDE]
                ,[INIT_SUSCEPT_ETHAMBUTOL]
                ,[INIT_SUSCEPT_STREPTOMYCIN]
                ,[INIT_SUSCEPT_ETHIONAMIDE]
                ,[INIT_SUSCEPT_KANAMYCIN]
                ,[INIT_SUSCEPT_CYCLOSERINE]
                ,[INIT_SUSCEPT_CAPREOMYCIN]
                ,[INIT_SUSCEPT_PA_SALICYLIC_ACID]
                ,[INIT_SUSCEPT_AMIKACIN]
                ,[INIT_SUSCEPT_RIFABUTIN]
                ,[INIT_SUSCEPT_CIPROFLOXACIN]
                ,[INIT_SUSCEPT_OFLOXACIN]
                ,[INIT_SUSCEPT_RIFAPENTINE]
                ,[INIT_SUSCEPT_LEVOFLOXACIN]
                ,[INIT_SUSCEPT_MOXIFLOXACIN]
                ,[INIT_SUSCEPT_OTHER_QUNINOLONES]
                ,[INIT_SUSCEPT_OTHER_1_IND]
                ,[INIT_SUSCEPT_OTHER_2_IND]
                ,[SPUTUM_CULTURE_CONV_DOCUMENTED]
                ,[NO_CONV_DOC_REASON]
                ,[MOVED_WHERE_1]
                ,[MOVED_IND]
                ,[MOVED_WHERE_2]
                ,[MOVED_WHERE_GT3_IND]
                ,[MOVED_WHERE_3]
                ,[MOVED_WHERE_ALL]
                ,[MOVE_CITY]
                ,[MOVE_CNTY_1]
                ,[MOVE_CNTY_2]
                ,[MOVE_CNTY_GT3_IND]
                ,[MOVE_CNTY_3]
                ,[MOVE_STATE_1]
                ,[MOVE_CNTY_ALL]
                ,[MOVE_STATE_2]
                ,[MOVE_STATE_GT3_IND]
                ,[MOVE_STATE_3]
                ,[MOVE_CNTRY_1]
                ,[MOVE_STATE_ALL]
                ,[MOVE_CNTRY_2]
                ,[MOVE_CNTRY_GT3_IND]
                ,[MOVE_CNTRY_3]
                ,[MOVE_CNTRY_ALL]
                ,[TRANSNATIONAL_REFERRAL_IND]
                ,[THERAPY_STOP_REASON]
                ,[GT_12_REAS_1]
                ,[THERAPY_STOP_CAUSE_OF_DEATH]
                ,[GT_12_REAS_2]
                ,[GT_12_REAS_GT3_IND]
                ,[GT_12_REAS_3]
                ,[GT_12_REAS_ALL]
                ,[HC_PROV_TY_1]
                ,[HC_PROV_TY_2]
                ,[HC_PROV_TY_GT3_IND]
                ,[HC_PROV_TY_3]
                ,[HC_PROV_TY_ALL]
                ,[DOT]
                ,[FINAL_SUSCEPT_TESTING]
                ,[FINAL_ISOLATE_IS_SPUTUM_IND]
                ,[FINAL_ISOLATE_NOT_SPUTUM]
                ,[FINAL_SUSCEPT_ISONIAZID]
                ,[FINAL_SUSCEPT_RIFAMPIN]
                ,[FINAL_SUSCEPT_PYRAZINAMIDE]
                ,[FINAL_SUSCEPT_ETHAMBUTOL]
                ,[FINAL_SUSCEPT_STREPTOMYCIN]
                ,[FINAL_SUSCEPT_ETHIONAMIDE]
                ,[FINAL_SUSCEPT_KANAMYCIN]
                ,[FINAL_SUSCEPT_CYCLOSERINE]
                ,[FINAL_SUSCEPT_CAPREOMYCIN]
                ,[FINAL_SUSCEPT_PA_SALICYLIC_ACI]
                ,[FINAL_SUSCEPT_AMIKACIN]
                ,[FINAL_SUSCEPT_RIFABUTIN]
                ,[FINAL_SUSCEPT_CIPROFLOXACIN]
                ,[FINAL_SUSCEPT_OFLOXACIN]
                ,[FINAL_SUSCEPT_RIFAPENTINE]
                ,[FINAL_SUSCEPT_LEVOFLOXACIN]
                ,[FINAL_SUSCEPT_MOXIFLOXACIN]
                ,[FINAL_SUSCEPT_OTHER_QUINOLONES]
                ,[FINAL_SUSCEPT_OTHER_IND]
                ,[FINAL_SUSCEPT_OTHER_2_IND]
                ,[CASE_VERIFICATION]
                ,[CASE_STATUS]
                ,[COUNT_STATUS]
                ,[COUNTRY_OF_VERIFIED_CASE]
                ,[NOTIFICATION_STATUS]
                ,[NOTIFICATION_SENT_DATE]
                ,[PATIENT_DOB]
                ,[PATIENT_DECEASED_DATE]
                ,[INVESTIGATION_START_DATE]
                ,[INVESTIGATOR_ASSIGN_DATE]
                ,[DATE_REPORTED]
                ,[DATE_SUBMITTED]
                ,[PREVIOUS_DIAGNOSIS_YEAR]
                ,[DATE_ARRIVED_IN_US]
                ,[INVESTIGATION_DEATH_DATE]
                ,[SPUTUM_SMEAR_COLLECT_DATE]
                ,[SPUTUM_CULT_COLLECT_DATE]
                ,[SPUTUM_CULT_RESULT_RPT_DATE]
                ,[SMR_PATH_CYTO_COLLECT_DATE]
                ,[CULT_TISSUE_COLLECT_DATE]
                ,[CULT_TISSUE_RESULT_RPT_DATE]
                ,[NAA_COLLECT_DATE]
                ,[NAA_RESULT_RPT_DATE]
                ,[TST_PLACED_DATE]
                ,[IGRA_COLLECT_DATE]
                ,[INIT_REGIMEN_START_DATE]
                ,[FIRST_ISOLATE_COLLECT_DATE]
                ,[TB_SPUTUM_CULTURE_NEGATIVE_DAT]
                ,[THERAPY_STOP_DATE]
                ,[FINAL_ISOLATE_COLLECT_DATE]
                ,[COUNT_DATE]
                ,[INVESTIGATION_CREATE_DATE]
                ,[INVESTIGATION_LAST_UPDTD_DATE]
                ,[INVESTIGATION_KEY]
                ,[CALC_REPORTED_AGE]
                ,[PATIENT_PHONE_EXT_HOME]
                ,[PATIENT_PHONE_EXT_WORK]
                ,[AGE_REPORTED]
                ,[TST_MM_INDURATION]
                ,[DOT_NUMBER_WEEKS]
                ,[MMWR_WEEK]
                ,[MMWR_YEAR]
                ,[PROGRAM_JURISDICTION_OID]
                ,[PATIENT_LOCAL_ID]
                ,[INVESTIGATION_LOCAL_ID]
                ,[PATIENT_GENERAL_COMMENTS]
                ,[PATIENT_FIRST_NAME]
                ,[PATIENT_MIDDLE_NAME]
                ,[PATIENT_LAST_NAME]
                ,[PATIENT_STREET_ADDRESS_1]
                ,[PATIENT_STREET_ADDRESS_2]
                ,[PATIENT_CITY]
                ,[PATIENT_ZIP]
                ,[PATIENT_PHONE_NUMBER_HOME]
                ,[PATIENT_PHONE_NUMBER_WORK]
                ,[PATIENT_SSN]
                ,[INVESTIGATOR_FIRST_NAME]
                ,[INVESTIGATOR_LAST_NAME]
                ,[INVESTIGATOR_PHONE_NUMBER]
                ,[STATE_CASE_NUMBER]
                ,[CITY_COUNTY_CASE_NUMBER]
                ,[LINK_STATE_CASE_NUM_1]
                ,[LINK_STATE_CASE_NUM_2]
                ,[IGRA_TEST_TY]
                ,[OTHER_TB_RISK_FACTORS]
                ,[INIT_REGIMEN_OTHER_1]
                ,[INIT_REGIMEN_OTHER_2]
                ,[GENERAL_COMMENTS]
                ,[ISOLATE_ACCESSION_NUM]
                ,[INIT_SUSCEPT_OTHER_1]
                ,[INIT_SUSCEPT_OTHER_2]
                ,[COMMENTS_FOLLOW_UP_1]
                ,[NO_CONV_DOC_OTHER_REASON]
                ,[MOVE_CITY_2]
                ,[THERAPY_EXTEND_GT_12_OTHER]
                ,[FINAL_SUSCEPT_OTHER]
                ,[FINAL_SUSCEPT_OTHER_2]
                ,[COMMENTS_FOLLOW_UP_2]
                ,[DIE_FRM_THIS_ILLNESS_IND]
                ,[PROVIDER_OVERRIDE_COMMENTS]
                ,[INVESTIGATION_CREATED_BY]
                ,[INVESTIGATION_LAST_UPDTD_BY]
                ,[NOTIFICATION_LOCAL_ID]
                ,[NOTIFICATION_SUBMITTER]
                ,[HIV_STATE_PATIENT_NUM]
                ,[HIV_STATUS]
                ,[HIV_CITY_CNTY_PATIENT_NUM]
                ,[D_TB_HIV_KEY]
                ,[INIT_DRUG_REG_CALC]
                ,[REPORTER_PHONE_NUMBER]
                ,[REPORTING_SOURCE_NAME]
                ,[REPORTING_SOURCE_TYPE]
                ,[REPORTER_FIRST_NAME]
                ,[REPORTER_LAST_NAME]
                ,[PHYSICIAN_FIRST_NAME]
                ,[PHYSICIAN_LAST_NAME]
                ,[PHYSICIAN_PHONE_NUMBER]
                ,[HOSPITALIZED]
                ,[HOSPITAL_NAME]
                ,[HOSPITALIZED_ADMISSION_DATE]
                ,[HOSPITALIZED_DISCHARGE_DATE]
                ,[HOSPITALIZED_DURATION_DAYS]
                ,[DIAGNOSIS_DATE]
                ,[ILLNESS_ONSET_DATE]
                ,[ILLNESS_ONSET_AGE]
                ,[ILLNESS_ONSET_AGE_UNIT]
                ,[ILLNESS_END_DATE]
                ,[ILLNESS_DURATION]
                ,[ILLNESS_DURATION_UNIT]
                ,[PREGNANT]
                ,[DAYCARE]
                ,[FOOD_HANDLER]
                ,[DISEASE_ACQUIRED_WHERE]
                ,[DISEASE_ACQUIRED_COUNTRY]
                ,[DISEASE_ACQUIRED_STATE]
                ,[DISEASE_ACQUIRED_CITY]
                ,[DISEASE_ACQUIRED_COUNTY]
                ,[TRANSMISSION_MODE]
                ,[DETECTION_METHOD]
                ,[OUTBREAK]
                ,[OUTBREAK_NAME]
                ,[CONFIRMATION_METHOD_1]
                ,[CONFIRMATION_METHOD_2]
                ,[CONFIRMATION_METHOD_3]
                ,[CONFIRMATION_METHOD_ALL]
                ,[CONFIRMATION_DATE]
                ,[CONFIRMATION_METHOD_GT3_IND]
                ,[DATE_REPORTED_TO_COUNTY]
            )
            SELECT 
                CALC_5_YEAR_AGE_GROUP
                ,CALC_10_YEAR_AGE_GROUP
                ,PATIENT_NAME_SUFFIX
                ,PATIENT_STATE
                ,PATIENT_COUNTY
                ,PATIENT_COUNTRY
                ,PATIENT_WITHIN_CITY_LIMITS
                ,AGE_REPORTED_UNIT
                ,PATIENT_BIRTH_SEX
                ,PATIENT_CURRENT_SEX
                ,PATIENT_DECEASED_INDICATOR
                ,PATIENT_MARITAL_STATUS
                ,PATIENT_ETHNICITY
                ,RACE_CALCULATED
                ,RACE_CALC_DETAILS
                ,RACE_ASIAN_1
                ,RACE_ASIAN_2
                ,RACE_ASIAN_3
                ,RACE_ASIAN_GT3_IND
                ,RACE_ASIAN_ALL
                ,RACE_NAT_HI_1
                ,RACE_NAT_HI_2
                ,RACE_NAT_HI_3
                ,RACE_NAT_HI_GT3_IND
                ,RACE_NAT_HI_ALL
                ,JURISDICTION_NAME
                ,PROGRAM_AREA_DESCRIPTION
                ,INVESTIGATION_STATUS
                ,LINK_REASON_1
                ,LINK_REASON_2
                ,PREVIOUS_DIAGNOSIS_IND
                ,US_BORN_IND
                ,PATIENT_BIRTH_COUNTRY
                ,PATIENT_OUTSIDE_US_GT_2_MONTHS
                ,OUT_OF_CNTRY_1
                ,OUT_OF_CNTRY_2
                ,OUT_OF_CNTRY_3
                ,OUT_OF_CNTRY_GT3_IND
                ,OUT_OF_CNTRY_ALL
                ,PRIMARY_GUARD_1_BIRTH_COUNTRY
                ,PRIMARY_GUARD_2_BIRTH_COUNTRY
                ,STATUS_AT_DIAGNOSIS
                ,DISEASE_SITE_1
                ,DISEASE_SITE_2
                ,DISEASE_SITE_3
                ,DISEASE_SITE_GT3_IND
                ,DISEASE_SITE_ALL
                ,CALC_DISEASE_SITE
                ,SPUTUM_SMEAR_RESULT
                ,SPUTUM_CULTURE_RESULT
                ,SPUTUM_CULT_RPT_LAB_TY
                ,SMR_PATH_CYTO_RESULT
                ,SMR_PATH_CYTO_SITE
                ,SMR_EXAM_TY_1
                ,SMR_EXAM_TY_2
                ,SMR_EXAM_TY_3
                ,SMR_EXAM_TY_GT3_IND
                ,SMR_EXAM_TY_ALL
                ,CULT_TISSUE_RESULT
                ,CULT_TISSUE_SITE
                ,CULT_TISSUE_RESULT_RPT_LAB_TY
                ,NAA_RESULT
                ,NAA_SPEC_IS_SPUTUM_IND
                ,NAA_SPEC_NOT_SPUTUM
                ,NAA_RPT_LAB_TY
                ,CHEST_XRAY_RESULT
                ,CHEST_XRAY_CAVITY_EVIDENCE
                ,CHEST_XRAY_MILIARY_EVIDENCE
                ,CT_SCAN_RESULT
                ,CT_SCAN_CAVITY_EVIDENCE
                ,CT_SCAN_MILIARY_EVIDENCE
                ,TST_RESULT
                ,IGRA_RESULT
                ,PRIMARY_REASON_EVALUATED
                ,HOMELESS_IND
                ,CORRECTIONAL_FACIL_RESIDENT
                ,CORRECTIONAL_FACIL_TY
                ,CORRECTIONAL_FACIL_CUSTODY_IND
                ,LONGTERM_CARE_FACIL_RESIDENT
                ,LONGTERM_CARE_FACIL_TY
                ,OCCUPATION_RISK
                ,INJECT_DRUG_USE_PAST_YEAR
                ,NONINJECT_DRUG_USE_PAST_YEAR
                ,ADDL_RISK_1
                ,EXCESS_ALCOHOL_USE_PAST_YEAR
                ,ADDL_RISK_2
                ,ADDL_RISK_GT3_IND
                ,ADDL_RISK_3
                ,ADDL_RISK_ALL
                ,IMMIGRATION_STATUS_AT_US_ENTRY
                ,INIT_REGIMEN_ISONIAZID
                ,INIT_REGIMEN_RIFAMPIN
                ,INIT_REGIMEN_PYRAZINAMIDE
                ,INIT_REGIMEN_ETHAMBUTOL
                ,INIT_REGIMEN_STREPTOMYCIN
                ,INIT_REGIMEN_ETHIONAMIDE
                ,INIT_REGIMEN_KANAMYCIN
                ,INIT_REGIMEN_CYCLOSERINE
                ,INIT_REGIMEN_CAPREOMYCIN
                ,INIT_REGIMEN_PA_SALICYLIC_ACID
                ,INIT_REGIMEN_AMIKACIN
                ,INIT_REGIMEN_RIFABUTIN
                ,INIT_REGIMEN_CIPROFLOXACIN
                ,INIT_REGIMEN_OFLOXACIN
                ,INIT_REGIMEN_RIFAPENTINE
                ,INIT_REGIMEN_LEVOFLOXACIN
                ,INIT_REGIMEN_MOXIFLOXACIN
                ,INIT_REGIMEN_OTHER_1_IND
                ,INIT_REGIMEN_OTHER_2_IND
                ,ISOLATE_SUBMITTED_IND
                ,INIT_SUSCEPT_TESTING_DONE
                ,FIRST_ISOLATE_IS_SPUTUM_IND
                ,FIRST_ISOLATE_NOT_SPUTUM
                ,INIT_SUSCEPT_ISONIAZID
                ,INIT_SUSCEPT_RIFAMPIN
                ,INIT_SUSCEPT_PYRAZINAMIDE
                ,INIT_SUSCEPT_ETHAMBUTOL
                ,INIT_SUSCEPT_STREPTOMYCIN
                ,INIT_SUSCEPT_ETHIONAMIDE
                ,INIT_SUSCEPT_KANAMYCIN
                ,INIT_SUSCEPT_CYCLOSERINE
                ,INIT_SUSCEPT_CAPREOMYCIN
                ,INIT_SUSCEPT_PA_SALICYLIC_ACID
                ,INIT_SUSCEPT_AMIKACIN
                ,INIT_SUSCEPT_RIFABUTIN
                ,INIT_SUSCEPT_CIPROFLOXACIN
                ,INIT_SUSCEPT_OFLOXACIN
                ,INIT_SUSCEPT_RIFAPENTINE
                ,INIT_SUSCEPT_LEVOFLOXACIN
                ,INIT_SUSCEPT_MOXIFLOXACIN
                ,INIT_SUSCEPT_OTHER_QUNINOLONES
                ,INIT_SUSCEPT_OTHER_1_IND
                ,INIT_SUSCEPT_OTHER_2_IND
                ,SPUTUM_CULTURE_CONV_DOCUMENTED
                ,NO_CONV_DOC_REASON
                ,MOVED_WHERE_1
                ,MOVED_IND
                ,MOVED_WHERE_2
                ,MOVED_WHERE_GT3_IND
                ,MOVED_WHERE_3
                ,MOVED_WHERE_ALL
                ,MOVE_CITY
                ,MOVE_CNTY_1
                ,MOVE_CNTY_2
                ,MOVE_CNTY_GT3_IND
                ,MOVE_CNTY_3
                ,MOVE_STATE_1
                ,MOVE_CNTY_ALL
                ,MOVE_STATE_2
                ,MOVE_STATE_GT3_IND
                ,MOVE_STATE_3
                ,MOVE_CNTRY_1
                ,MOVE_STATE_ALL
                ,MOVE_CNTRY_2
                ,MOVE_CNTRY_GT3_IND
                ,MOVE_CNTRY_3
                ,MOVE_CNTRY_ALL
                ,TRANSNATIONAL_REFERRAL_IND
                ,THERAPY_STOP_REASON
                ,GT_12_REAS_1
                ,THERAPY_STOP_CAUSE_OF_DEATH
                ,GT_12_REAS_2
                ,GT_12_REAS_GT3_IND
                ,GT_12_REAS_3
                ,GT_12_REAS_ALL
                ,HC_PROV_TY_1
                ,HC_PROV_TY_2
                ,HC_PROV_TY_GT3_IND
                ,HC_PROV_TY_3
                ,HC_PROV_TY_ALL
                ,DOT
                ,FINAL_SUSCEPT_TESTING
                ,FINAL_ISOLATE_IS_SPUTUM_IND
                ,FINAL_ISOLATE_NOT_SPUTUM
                ,FINAL_SUSCEPT_ISONIAZID
                ,FINAL_SUSCEPT_RIFAMPIN
                ,FINAL_SUSCEPT_PYRAZINAMIDE
                ,FINAL_SUSCEPT_ETHAMBUTOL
                ,FINAL_SUSCEPT_STREPTOMYCIN
                ,FINAL_SUSCEPT_ETHIONAMIDE
                ,FINAL_SUSCEPT_KANAMYCIN
                ,FINAL_SUSCEPT_CYCLOSERINE
                ,FINAL_SUSCEPT_CAPREOMYCIN
                ,FINAL_SUSCEPT_PA_SALICYLIC_ACI
                ,FINAL_SUSCEPT_AMIKACIN
                ,FINAL_SUSCEPT_RIFABUTIN
                ,FINAL_SUSCEPT_CIPROFLOXACIN
                ,FINAL_SUSCEPT_OFLOXACIN
                ,FINAL_SUSCEPT_RIFAPENTINE
                ,FINAL_SUSCEPT_LEVOFLOXACIN
                ,FINAL_SUSCEPT_MOXIFLOXACIN
                ,FINAL_SUSCEPT_OTHER_QUINOLONES
                ,FINAL_SUSCEPT_OTHER_IND
                ,FINAL_SUSCEPT_OTHER_2_IND
                ,CASE_VERIFICATION
                ,CASE_STATUS
                ,COUNT_STATUS
                ,COUNTRY_OF_VERIFIED_CASE
                ,NOTIFICATION_STATUS
                ,NOTIFICATION_SENT_DATE
                ,PATIENT_DOB
                ,PATIENT_DECEASED_DATE
                ,INVESTIGATION_START_DATE
                ,INVESTIGATOR_ASSIGN_DATE
                ,DATE_REPORTED
                ,DATE_SUBMITTED
                ,PREVIOUS_DIAGNOSIS_YEAR
                ,DATE_ARRIVED_IN_US
                ,INVESTIGATION_DEATH_DATE
                ,SPUTUM_SMEAR_COLLECT_DATE
                ,SPUTUM_CULT_COLLECT_DATE
                ,SPUTUM_CULT_RESULT_RPT_DATE
                ,SMR_PATH_CYTO_COLLECT_DATE
                ,CULT_TISSUE_COLLECT_DATE
                ,CULT_TISSUE_RESULT_RPT_DATE
                ,NAA_COLLECT_DATE
                ,NAA_RESULT_RPT_DATE
                ,TST_PLACED_DATE
                ,IGRA_COLLECT_DATE
                ,INIT_REGIMEN_START_DATE
                ,FIRST_ISOLATE_COLLECT_DATE
                ,TB_SPUTUM_CULTURE_NEGATIVE_DAT
                ,THERAPY_STOP_DATE
                ,FINAL_ISOLATE_COLLECT_DATE
                ,COUNT_DATE
                ,INVESTIGATION_CREATE_DATE
                ,INVESTIGATION_LAST_UPDTD_DATE
                ,INVESTIGATION_KEY
                ,CALC_REPORTED_AGE
                ,PATIENT_PHONE_EXT_HOME
                ,PATIENT_PHONE_EXT_WORK
                ,AGE_REPORTED
                ,TST_MM_INDURATION
                ,DOT_NUMBER_WEEKS
                ,MMWR_WEEK
                ,MMWR_YEAR
                ,PROGRAM_JURISDICTION_OID
                ,PATIENT_LOCAL_ID
                ,INVESTIGATION_LOCAL_ID
                ,PATIENT_GENERAL_COMMENTS
                ,PATIENT_FIRST_NAME
                ,PATIENT_MIDDLE_NAME
                ,PATIENT_LAST_NAME
                ,PATIENT_STREET_ADDRESS_1
                ,PATIENT_STREET_ADDRESS_2
                ,PATIENT_CITY
                ,PATIENT_ZIP
                ,PATIENT_PHONE_NUMBER_HOME
                ,PATIENT_PHONE_NUMBER_WORK
                ,PATIENT_SSN
                ,INVESTIGATOR_FIRST_NAME
                ,INVESTIGATOR_LAST_NAME
                ,INVESTIGATOR_PHONE_NUMBER
                ,STATE_CASE_NUMBER
                ,CITY_COUNTY_CASE_NUMBER
                ,LINK_STATE_CASE_NUM_1
                ,LINK_STATE_CASE_NUM_2
                ,IGRA_TEST_TY
                ,OTHER_TB_RISK_FACTORS
                ,INIT_REGIMEN_OTHER_1
                ,INIT_REGIMEN_OTHER_2
                ,GENERAL_COMMENTS
                ,ISOLATE_ACCESSION_NUM
                ,INIT_SUSCEPT_OTHER_1
                ,INIT_SUSCEPT_OTHER_2
                ,COMMENTS_FOLLOW_UP_1
                ,NO_CONV_DOC_OTHER_REASON
                ,MOVE_CITY_2
                ,THERAPY_EXTEND_GT_12_OTHER
                ,FINAL_SUSCEPT_OTHER
                ,FINAL_SUSCEPT_OTHER_2
                ,COMMENTS_FOLLOW_UP_2
                ,DIE_FRM_THIS_ILLNESS_IND
                ,PROVIDER_OVERRIDE_COMMENTS
                ,INVESTIGATION_CREATED_BY
                ,INVESTIGATION_LAST_UPDTD_BY
                ,NOTIFICATION_LOCAL_ID
                ,NOTIFICATION_SUBMITTER
                ,HIV_STATE_PATIENT_NUM
                ,HIV_STATUS
                ,HIV_CITY_CNTY_PATIENT_NUM
                ,D_TB_HIV_KEY
                ,INIT_DRUG_REG_CALC
                ,REPORTER_PHONE_NUMBER
                ,REPORTING_SOURCE_NAME
                ,REPORTING_SOURCE_TYPE
                ,REPORTER_FIRST_NAME
                ,REPORTER_LAST_NAME
                ,PHYSICIAN_FIRST_NAME
                ,PHYSICIAN_LAST_NAME
                ,PHYSICIAN_PHONE_NUMBER
                ,HOSPITALIZED
                ,HOSPITAL_NAME
                ,HOSPITALIZED_ADMISSION_DATE
                ,HOSPITALIZED_DISCHARGE_DATE
                ,HOSPITALIZED_DURATION_DAYS
                ,DIAGNOSIS_DATE
                ,ILLNESS_ONSET_DATE
                ,ILLNESS_ONSET_AGE
                ,ILLNESS_ONSET_AGE_UNIT
                ,ILLNESS_END_DATE
                ,ILLNESS_DURATION
                ,ILLNESS_DURATION_UNIT
                ,PREGNANT
                ,DAYCARE
                ,FOOD_HANDLER
                ,DISEASE_ACQUIRED_WHERE
                ,DISEASE_ACQUIRED_COUNTRY
                ,DISEASE_ACQUIRED_STATE
                ,DISEASE_ACQUIRED_CITY
                ,DISEASE_ACQUIRED_COUNTY
                ,TRANSMISSION_MODE
                ,DETECTION_METHOD
                ,OUTBREAK
                ,OUTBREAK_NAME
                ,CONFIRMATION_METHOD_1
                ,CONFIRMATION_METHOD_2
                ,CONFIRMATION_METHOD_3
                ,CONFIRMATION_METHOD_ALL
                ,CONFIRMATION_DATE
                ,CONFIRMATION_METHOD_GT3_IND
                ,DATE_REPORTED_TO_COUNTY
            FROM #TB_HIV_DATAMART

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #TB_HIV_DATAMART;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

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

        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
            DECLARE @FullErrorMessage VARCHAR(8000) =
                'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
                'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
                'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
                'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
                'Error Message: ' + ERROR_MESSAGE();


            INSERT INTO [dbo].[job_flow_log] 
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'ERROR', @Proc_Step_no, @Proc_Step_name, @FullErrorMessage, 0);

        return -1 ;

    END CATCH

END;


---------------------------------------------------END OF PROCEDURE---------------------------------------------------------------------















-- Update D_TB_HIV_KEY: if > 0 keep as is, else set to 1
UPDATE #TB_HIV_DATAMART
SET D_TB_HIV_KEY = CASE 
    WHEN D_TB_HIV_KEY > 0 THEN D_TB_HIV_KEY 
    ELSE 1 
END;

-- Execute the dbload procedure to append data to permanent table
EXEC dbload 'TB_HIV_DATAMART', '#TB_HIV_DATAMART';

-- Optional: Clean up temporary tables
-- DROP TABLE #TB_HIV_WITH_UID;
-- DROP TABLE #TB_HIV_DATAMART;