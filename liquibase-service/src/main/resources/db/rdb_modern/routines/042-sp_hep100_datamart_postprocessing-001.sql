CREATE OR ALTER PROCEDURE dbo.sp_hep100_datamart_postprocessing @phc_uids nvarchar(max),
                                                                @pat_uids nvarchar(max),
                                                                @prov_uids nvarchar(max),
                                                                @org_uids nvarchar(max),
                                                                @debug bit = 'false'
as

BEGIN

    DECLARE
        @RowCount_no INT;
    DECLARE
        @Proc_Step_no FLOAT = 0;
    DECLARE
        @Proc_Step_Name VARCHAR(200) = '';
    DECLARE
        @batch_id BIGINT;
    SET
        @batch_id = cast((format(getdate(), 'yyyyMMddHHmmss')) as bigint);

    -- used in the logging statements
    DECLARE 
        @datamart_nm VARCHAR(100) = 'HEP100_DATAMART';



    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET
            @Proc_Step_Name = 'SP_Start';

        BEGIN
            TRANSACTION;

        INSERT INTO dbo.job_flow_log ( batch_id
                                     , [Dataflow_Name]
                                     , [package_Name]
                                     , [Status_Type]
                                     , [step_number]
                                     , [step_name]
                                     , [row_count]
                                     , [Msg_Description1])
        VALUES ( @batch_id
               , @datamart_nm
               , @datamart_nm
               , 'START'
               , @Proc_Step_no
               , @Proc_Step_Name
               , 0
               , LEFT('ID List-' + @phc_uids, 500));

        COMMIT TRANSACTION;

        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #HEP100_INIT';

            IF OBJECT_ID('#HEP100_INIT', 'U') IS NOT NULL
            drop table #HEP100_INIT;


                            /*
                    From the classic SAS ETL:
                    "
                    Derive the event date using following algorithm
                    1. Illness_onset_dt
                    2. Diagnosis_Dt
                    3. The earliest of the following dates:
                        Earliest_rpt_to_cnty_dt,
                        Earliest_rpt_to_state_dt,
                        Inv_rpt_dt
                        Inv_start_dt,
                        ALT_Result_dt,
                        AST_result_dt,
                        HSPTL_Admission_dt,
                        Hsptl_discharge_dt
                    "

                    INV_ADD_TIME is not mentioned in the comment, but it is
                    used in the computations related to EVENT_DATE 

                */

            SELECT 
                GETDATE() AS REFRESH_DATETIME,
                HC.INVESTIGATION_KEY, 
                HC.HEP_A_TOTAL_ANTIBODY,
                HC.HEP_A_IGM_ANTIBODY,
                HC.HEP_B_SURFACE_ANTIGEN,
                HC.HEP_B_TOTAL_ANTIBODY,
                HC.HEP_B_IGM_ANTIBODY,
                HC.HEP_C_TOTAL_ANTIBODY,
                HC.HEP_D_TOTAL_ANTIBODY,
                HC.HEP_E_TOTAL_ANTIBODY,
                HC.ANTIHCV_SIGNAL_TO_CUTOFF_RATIO,
                HC.ANTIHCV_SUPPLEMENTAL_ASSAY,
                HC.HCV_RNA,
                HC.ALT_SGPT_RESULT,
                HC.ALT_SGPT_RESULT_UPPER_LIMIT,
                HC.AST_SGOT_RESULT,
                HC.AST_SGOT_RESULT_UPPER_LIMIT,
                HC.ALT_RESULT_DT,
                HC.AST_RESULT_DT,
                HC.PATIENT_SYMPTOMATIC_IND,
                HC.PATIENT_JUNDICED_IND,
                HC.PATIENT_PREGNANT_IND,
                HC.PATIENT_PREGNANCY_DUE_DT,
                HC.HEP_A_EPLINK_IND,
                HC.HEP_A_CONTACTED_IND,
                HC.D_N_P_EMPLOYEE_IND,
                HC.D_N_P_HOUSEHOLD_CONTACT_IND,
                HC.HEP_A_KEYENT_IN_CHILDCARE_IND,
                HC.HEPA_MALE_SEX_PARTNER_NBR,
                HC.HEPA_FEMALE_SEX_PARTNER_NBR,
                HC.STREET_DRUG_INJECTED_IN_2_6_WK,
                HC.STREET_DRUG_USED_IN_2_6_WK,
                HC.TRAVEL_OUT_USA_CAN_IND,
                HC.HOUSEHOLD_NPP_OUT_USA_CAN,
                HC.PART_OF_AN_OUTBRK_IND,
                HC.ASSOCIATED_OUTBRK_TYPE,
                HC.FOODBORNE_OUTBRK_FOOD_ITEM,
                HC.FOODHANDLER_2_WK_PRIOR_ONSET,
                HC.HEP_A_VACC_RECEIVED_IND,
                HC.HEP_A_VACC_RECEIVED_DOSE,
                HC.HEP_A_VACC_LAST_RECEIVED_YR,
                HC.IMMUNE_GLOBULIN_RECEIVED_IND,
                HC.GLOBULIN_LAST_RECEIVED_YR,
                HC.HEP_B_CONTACTED_IND,
                HC.HEPB_STD_TREATED_IND,
                HC.HEPB_STD_LAST_TREATMENT_YR,
                HC.STREET_DRUG_INJECTED_IN6WKMON,
                HC.STREET_DRUG_USED_IN6WKMON,
                HC.HEPB_FEMALE_SEX_PARTNER_NBR,
                HC.HEPB_MALE_SEX_PARTNER_NBR,
                HC.HEMODIALYSIS_IN_LAST_6WKMON,
                HC.BLOOD_CONTAMINATION_IN6WKMON,
                HC.HEPB_BLOOD_RECEIVED_IN6WKMON,
                HC.HEPB_BLOOD_RECEIVED_DT,
                HC.OUTPATIENT_IV_INFUSION_IN6WKMO,
                HC.BLOOD_EXPOSURE_IN_LAST6WKMON,
                HC.BLOOD_EXPOSURE_IN6WKMON_OTHER,
                HC.HEPB_MED_DEN_EMPLOYEE_IN6WKMON,
                HC.HEPB_MED_DEN_BLOOD_CONTACT_FRQ,
                HC.HEPB_PUB_SAFETY_WORKER_IN6WKMO,
                HC.HEPB_PUBSAFETY_BLOODCONTACTFRQ,
                HC.TATTOOED_IN6WKMON_BEFORE_ONSET,
                HC.PIERCING_IN6WKMON_BEFORE_ONSET,
                HC.DEN_WORK_OR_SURGERY_IN6WKMON,
                HC.NON_ORAL_SURGERY_IN6WKMON,
                HC.HSPTLIZD_IN6WKMON_BEFORE_ONSET,
                HC.LONGTERMCARE_RESIDENT_IN6WKMON,
                HC.B_INCARCERATED24PLUSHRSIN6WKMO,
                HC.B_INCARCERATED_6PLUS_MON_IND,
                HC.B_LAST6PLUSMON_INCARCERATE_YR,
                HC.BLAST6PLUSMO_INCARCERATEPERIOD,
                HC.B_LAST_INCARCERATE_PERIOD_UNIT,
                HC.HEP_B_VACC_RECEIVED_IND,
                HC.HEP_B_VACC_SHOT_RECEIVED_NBR,
                HC.HEP_B_VACC_LAST_RECEIVED_YR,
                HC.ANTI_HBSAG_TESTED_IND,
                HC.ANTI_HBS_POSITIVE_REACTIVE_IND,
                HC.HEP_C_CONTACTED_IND,
                HC.MED_DEN_EMPLOYEE_IN_2WK6MO,
                HC.HEPC_MED_DEN_BLOOD_CONTACT_FRQ,
                HC.PUBLIC_SAFETY_WORKER_IN_2WK6MO,
                HC.HEPC_PUBSAFETY_BLOODCONTACTFRQ,
                HC.TATTOOED_IN2WK6MO_BEFORE_ONSET,
                HC.TATTOOED_IN2WK6MO_LOCATION,
                HC.PIERCING_IN2WK6MO_BEFORE_ONSET,
                HC.PIERCING_IN2WK6MO_LOCATION,
                HC.STREET_DRUG_INJECTED_IN_2WK6MO,
                HC.STREET_DRUG_USED_IN_2WK6MO,
                HC.HEMODIALYSIS_IN_LAST_2WK6MO,
                HC.BLOOD_CONTAMINATION_IN_2WK6MO,
                HC.HEPC_BLOOD_RECEIVED_IN_2WK6MO,
                HC.HEPC_BLOOD_RECEIVED_DT,
                HC.BLOOD_EXPOSURE_IN_LAST2WK6MO,
                HC.BLOOD_EXPOSURE_IN2WK6MO_OTHER,
                HC.DEN_WORK_OR_SURGERY_IN2WK6MO,
                HC.NON_ORAL_SURGERY_IN2WK6MO,
                HC.HSPTLIZD_IN2WK6MO_BEFORE_ONSET,
                HC.LONGTERMCARE_RESIDENT_IN2WK6MO,
                HC.INCARCERATED_24PLUSHRSIN2WK6MO,
                HC.HEPC_FEMALE_SEX_PARTNER_NBR,
                HC.HEPC_MALE_SEX_PARTNER_NBR,
                HC.C_INCARCERATED_6PLUS_MON_IND,
                HC.C_LAST6PLUSMON_INCARCERATE_YR,
                HC.CLAST6PLUSMO_INCARCERATEPERIOD,
                HC.C_LAST_INCARCERATE_PERIOD_UNIT,
                HC.HEPC_STD_TREATED_IND,
                HC.HEPC_STD_LAST_TREATMENT_YR,
                HC.BLOOD_TRANSFUSION_BEFORE_1992,
                HC.ORGAN_TRANSPLANT_BEFORE_1992,
                HC.CLOT_FACTOR_CONCERN_BEFORE1987,
                HC.LONGTERM_HEMODIALYSIS_IND,
                HC.EVER_INJECT_NONPRESCRIBED_DRUG,
                HC.LIFETIME_SEX_PARTNER_NBR,
                HC.EVER_INCARCERATED_IND,
                HC.HEPATITIS_CONTACTED_IND,
                HC.HEPATITIS_CONTACT_TYPE,
                HC.HEPATITIS_OTHER_CONTACT_TYPE,
                HC.HEPC_MED_DEN_EMPLOYEE_IND,
                HC.OUTPATIENT_IV_INFUSIONIN2WK6MO,
                CASE
                    WHEN I.ILLNESS_ONSET_DT IS NOT NULL THEN I.ILLNESS_ONSET_DT
                    WHEN I.DIAGNOSIS_DT IS NOT NULL THEN I.DIAGNOSIS_DT
                    WHEN COALESCE(
                        I.EARLIEST_RPT_TO_CNTY_DT, 
                        I.EARLIEST_RPT_TO_STATE_DT, 
                        I.INV_RPT_DT, 
                        I.INV_START_DT, 
                        HC.ALT_RESULT_DT, 
                        HC.AST_RESULT_DT, 
                        I.HSPTL_ADMISSION_DT, 
                        I.HSPTL_DISCHARGE_DT, 
                        P.PATIENT_ADD_TIME
                        ) IS NOT NULL THEN (
                        SELECT TOP 1 dt FROM (
                            SELECT COALESCE(I.EARLIEST_RPT_TO_CNTY_DT, '9999-12-31') AS dt
                            UNION ALL
                            SELECT COALESCE(I.EARLIEST_RPT_TO_STATE_DT, '9999-12-31')
                            UNION ALL
                            SELECT COALESCE(I.INV_RPT_DT, '9999-12-31')
                            UNION ALL
                            SELECT COALESCE(I.INV_START_DT, '9999-12-31')
                            UNION ALL
                            SELECT COALESCE(HC.ALT_RESULT_DT, '9999-12-31')
                            UNION ALL
                            SELECT COALESCE(HC.AST_RESULT_DT, '9999-12-31')
                            UNION ALL
                            SELECT COALESCE(I.HSPTL_ADMISSION_DT, '9999-12-31')
                            UNION ALL
                            SELECT COALESCE(I.HSPTL_DISCHARGE_DT, '9999-12-31')
                            UNION ALL
                            SELECT COALESCE(P.PATIENT_ADD_TIME, '9999-12-31')
                        ) AS dtlist ORDER BY dt ASC
                    )
                ELSE NULL
                END AS EVENT_DATE,
                HC.HEP_MULTI_VAL_GRP_KEY,
                HC.HEP_B_E_ANTIGEN,
                HC.HEP_B_DNA,
                HC.PLACE_OF_BIRTH,
                I.INV_LOCAL_ID AS INV_LOCAL_ID,
                I.INVESTIGATION_STATUS AS INVESTIGATION_STATUS,
                I.INV_CASE_STATUS AS INV_CASE_STATUS,
                I.JURISDICTION_NM AS INV_JURISDICTION_NM,
                I.ILLNESS_ONSET_DT AS ILLNESS_ONSET_DT,
                I.INV_START_DT AS INV_START_DT,
                I.INV_RPT_DT AS INV_RPT_DT,
                I.RPT_SRC_CD_DESC AS RPT_SRC_CD_DESC,
                I.EARLIEST_RPT_TO_CNTY_DT AS EARLIEST_RPT_TO_CNTY_DT,
                I.EARLIEST_RPT_TO_STATE_DT AS EARLIEST_RPT_TO_STATE_DT,
                I.DIE_FRM_THIS_ILLNESS_IND AS DIE_FRM_THIS_ILLNESS_IND,
                I.OUTBREAK_IND AS OUTBREAK_IND,
                I.DISEASE_IMPORTED_IND AS DISEASE_IMPORTED_IND,
                I.IMPORT_FRM_CNTRY AS IMPORT_FROM_COUNTRY,
                I.IMPORT_FRM_STATE AS IMPORT_FROM_STATE,
                I.IMPORT_FRM_CNTY AS IMPORT_FROM_COUNTY,
                I.IMPORT_FRM_CITY AS IMPORT_FROM_CITY,
                I.CASE_RPT_MMWR_WK AS Case_Rpt_MMWR_WEEK,
                I.CASE_RPT_MMWR_YR AS CASE_RPT_MMWR_YEAR,
                I.DIAGNOSIS_DT AS DIAGNOSIS_DT,
                I.HSPTLIZD_IND AS HSPTLIZD_IND,
                I.HSPTL_ADMISSION_DT AS HSPTL_ADMISSION_DT,
                I.HSPTL_DISCHARGE_DT AS HSPTL_DISCHARGE_DT,
                I.HSPTL_DURATION_DAYS AS HSPTL_DURATION_DAYS,
                I.TRANSMISSION_MODE AS TRANSMISSION_MODE,
                I.CASE_OID AS PROGRAM_JURISDICTION_OID,
                I.INV_COMMENTS AS INV_COMMENTS,
                I.RECORD_STATUS_CD AS RECORD_STATUS_CD,
                I.CASE_UID AS CASE_UID,
                inv.cd AS condition_cd,
                con.condition_short_nm as condition,
                P.PATIENT_LOCAL_ID AS PATIENT_LOCAL_ID,
                P.PATIENT_FIRST_NAME AS PATIENT_FIRST_NM,
                P.PATIENT_MIDDLE_NAME AS PATIENT_MIDDLE_NM,
                P.PATIENT_LAST_NAME AS PATIENT_LAST_NM,
                P.PATIENT_DOB AS PATIENT_DOB,
                P.PATIENT_AGE_REPORTED AS PATIENT_REPORTEDAGE,
                P.PATIENT_AGE_REPORTED_UNIT AS PATIENT_REPORTED_AGE_UNITS,
                P.PATIENT_CURRENT_SEX AS PATIENT_CURR_GENDER,
                P.PATIENT_ENTRY_METHOD AS PATIENT_ELECTRONIC_IND,
                P.PATIENT_UID AS PATIENT_UID,
                dbo.fn_get_proper_case(P.PATIENT_CITY) AS PATIENT_CITY,
                P.PATIENT_STATE,
                P.PATIENT_ZIP AS PATIENT_ZIP_CODE,
                P.PATIENT_COUNTY,
                P.PATIENT_COUNTRY,
                P.PATIENT_KEY,
                P.PATIENT_ADD_TIME AS INV_ADD_TIME,
                P.PATIENT_RACE_CALC_DETAILS AS RACE,
                P.PATIENT_LAST_CHANGE_TIME,
                COALESCE(TRIM(P.PATIENT_STREET_ADDRESS_1) + ',', '')
                    + COALESCE(TRIM(P.PATIENT_STREET_ADDRESS_2) + ',', '')
                    + COALESCE(TRIM(P.PATIENT_CITY) + ',', '')
                    + COALESCE(TRIM(P.PATIENT_COUNTY) + ',', '')
                    + COALESCE(TRIM(P.PATIENT_ZIP) + ',', '')
                    + COALESCE(TRIM(P.PATIENT_STATE), '') AS PATIENT_ADDRESS,
                CASE
                    WHEN LEN(COALESCE(TRIM(P.PATIENT_STREET_ADDRESS_2),TRIM(P.PATIENT_CITY),TRIM(P.PATIENT_COUNTY),TRIM(P.PATIENT_ZIP),TRIM(P.PATIENT_STATE), '')) > 0 THEN 'Home'
                    ELSE ''
                END AS ADDR_USE_CD_DESC,
                CASE
                    WHEN LEN(COALESCE(TRIM(P.PATIENT_STREET_ADDRESS_2),TRIM(P.PATIENT_CITY),TRIM(P.PATIENT_COUNTY),TRIM(P.PATIENT_ZIP),TRIM(P.PATIENT_STATE), '')) > 0 THEN 'House'
                    ELSE ''
                END AS ADDR_CD_DESC,
                PROV.PROVIDER_LOCAL_ID,
                PROV.PROVIDER_FIRST_NAME AS PHYSICIAN_FIRST_NM,
                PROV.PROVIDER_MIDDLE_NAME AS PHYSICIAN_MIDDLE_NM,
                PROV.PROVIDER_LAST_NAME AS PHYSICIAN_LAST_NM,
                PROV.PROVIDER_CITY AS PHYSICIAN_CITY,
                PROV.PROVIDER_STATE AS PHYSICIAN_STATE,
                PROV.PROVIDER_COUNTY AS PHYSICIAN_COUNTY,
                PROV.PROVIDER_ADD_TIME,
                PROV.PROVIDER_LAST_CHANGE_TIME,
                PROV.PROVIDER_UID AS PHYSICIAN_UID,
                INVGTR.PROVIDER_FIRST_NAME AS INVESTIGATOR_FIRST_NM,
                INVGTR.PROVIDER_MIDDLE_NAME AS INVESTIGATOR_MIDDLE_NM,
                INVGTR.PROVIDER_LAST_NAME AS INVESTIGATOR_LAST_NM,
                INVGTR.PROVIDER_UID AS INVESTIGATOR_UID,
                REPTORG.ORGANIZATION_NAME AS REPORTING_SOURCE,
                REPTORG.ORGANIZATION_COUNTY AS REPORTING_SOURCE_COUNTY,
                REPTORG.ORGANIZATION_STATE AS REPORTING_SOURCE_STATE,
                REPTORG.ORGANIZATION_CITY AS REPORTING_SOURCE_CITY,
                REPTORG.ORGANIZATION_UID AS REPORTING_SOURCE_UID,
                COALESCE(TRIM(PROV.PROVIDER_FIRST_NAME), ' ') + ',' + COALESCE(TRIM(prov.PROVIDER_MIDDLE_NAME), ' ') + ',' + COALESCE(TRIM(prov.PROVIDER_LAST_NAME), ' ') AS PHYSICIAN_NAME,
                COALESCE(TRIM(INVGTR.PROVIDER_FIRST_NAME), ' ') + ',' + COALESCE(TRIM(INVGTR.PROVIDER_MIDDLE_NAME), ' ') + ',' + COALESCE(TRIM(INVGTR.PROVIDER_LAST_NAME), ' ') AS INVESTIGATOR_NAME,
                CASE 
                    WHEN LEN(TRIM(COALESCE(PROV.PROVIDER_CITY, '')) + TRIM(COALESCE(PROV.PROVIDER_STATE, '')) + TRIM(COALESCE(PROV.PROVIDER_COUNTY, ''))) > 0 
                    THEN 'Primary Work Place' 
                    ELSE NULL 
                END AS PHYSICIAN_ADDRESS_USE_DESC,
                CASE 
                    WHEN LEN(TRIM(COALESCE(PROV.PROVIDER_CITY, '')) + TRIM(COALESCE(PROV.PROVIDER_STATE, '')) + TRIM(COALESCE(PROV.PROVIDER_COUNTY, ''))) > 0 
                    THEN 'Office' 
                    ELSE NULL 
                END AS PHYSICIAN_ADDRESS_TYPE_DESC,
                CASE 
                    WHEN LEN(TRIM(COALESCE(REPTORG.ORGANIZATION_COUNTY, '')) + TRIM(COALESCE(REPTORG.ORGANIZATION_STATE, '')) + TRIM(COALESCE(REPTORG.ORGANIZATION_CITY, ''))) > 0 
                    THEN 'Primary Work Place' 
                    ELSE NULL 
                END AS REPORTING_SOURCE_ADDRESS_USE,
                CASE 
                    WHEN LEN(TRIM(COALESCE(REPTORG.ORGANIZATION_COUNTY, '')) + TRIM(COALESCE(REPTORG.ORGANIZATION_STATE, '')) + TRIM(COALESCE(REPTORG.ORGANIZATION_CITY, ''))) > 0 
                    THEN 'Office' 
                    ELSE NULL 
                END AS REPORTING_SOURCE_ADDRESS_TYPE
            INTO #HEP100_INIT
            FROM dbo.HEPATITIS_CASE hc WITH (NOLOCK)
            INNER JOIN dbo.investigation I WITH (NOLOCK)
                ON HC.investigation_key = I.investigation_key
            LEFT JOIN dbo.nrt_investigation inv WITH (NOLOCK)
                on I.CASE_UID = inv.public_health_case_uid
            LEFT JOIN dbo.D_PATIENT P WITH (NOLOCK)
                ON HC.PATIENT_KEY = P.PATIENT_KEY
            LEFT JOIN dbo.D_PROVIDER PROV WITH (NOLOCK)
                ON HC.PHYSICIAN_KEY = PROV.PROVIDER_KEY
            LEFT JOIN dbo.D_PROVIDER INVGTR WITH (NOLOCK)
                ON HC.INVESTIGATOR_KEY = INVGTR.PROVIDER_KEY
            LEFT JOIN dbo.D_ORGANIZATION REPTORG WITH (NOLOCK)
                ON HC.RPT_SRC_ORG_KEY = REPTORG.ORGANIZATION_KEY
            LEFT JOIN dbo.v_condition_dim con WITH (NOLOCK)
                ON inv.cd = con.condition_cd
            WHERE 
            (I.CASE_UID IN (SELECT value FROM STRING_SPLIT(@phc_uids, ','))
            OR
            P.PATIENT_UID IN (SELECT value FROM STRING_SPLIT(@pat_uids, ','))
            OR
            PROV.PROVIDER_UID IN (SELECT value FROM STRING_SPLIT(@prov_uids, ','))
            OR
            INVGTR.PROVIDER_UID IN (SELECT value FROM STRING_SPLIT(@prov_uids, ','))
            OR
            REPTORG.ORGANIZATION_UID IN (SELECT value FROM STRING_SPLIT(@org_uids, ',')))
            AND I.RECORD_STATUS_CD = 'ACTIVE';
            

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #HEP100_INIT;

            SELECT @RowCount_no = @@ROWCOUNT;


            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'UPDATE dbo.HEP100';

            UPDATE tgt
            SET 
                tgt.PATIENT_LOCAL_ID = src.PATIENT_LOCAL_ID,
                tgt.PROGRAM_JURISDICTION_OID = src.PROGRAM_JURISDICTION_OID,
                tgt.PATIENT_FIRST_NM = src.PATIENT_FIRST_NM,
                tgt.PATIENT_MIDDLE_NM = src.PATIENT_MIDDLE_NM,
                tgt.PATIENT_LAST_NM = src.PATIENT_LAST_NM,
                tgt.PATIENT_DOB = src.PATIENT_DOB,
                tgt.PATIENT_REPORTEDAGE = src.PATIENT_REPORTEDAGE,
                tgt.PATIENT_REPORTED_AGE_UNITS = src.PATIENT_REPORTED_AGE_UNITS,
                tgt.ADDR_USE_CD_DESC = src.ADDR_USE_CD_DESC,
                tgt.ADDR_CD_DESC = src.ADDR_CD_DESC,
                tgt.PATIENT_ADDRESS = src.PATIENT_ADDRESS,
                tgt.PATIENT_CITY = src.PATIENT_CITY,
                tgt.PATIENT_COUNTY = src.PATIENT_COUNTY,
                tgt.PATIENT_ZIP_CODE = src.PATIENT_ZIP_CODE,
                tgt.PATIENT_CURR_GENDER = src.PATIENT_CURR_GENDER,
                tgt.PATIENT_ELECTRONIC_IND = src.PATIENT_ELECTRONIC_IND,
                tgt.RACE = src.RACE,
                tgt.CONDITION_CD = src.CONDITION_CD,
                tgt.CONDITION = src.CONDITION,
                tgt.INV_LOCAL_ID = src.INV_LOCAL_ID,
                tgt.INVESTIGATION_STATUS = src.INVESTIGATION_STATUS,
                tgt.INV_CASE_STATUS = src.INV_CASE_STATUS,
                tgt.INV_JURISDICTION_NM = src.INV_JURISDICTION_NM,
                tgt.RPT_SRC_CD_DESC = src.RPT_SRC_CD_DESC,
                tgt.REPORTING_SOURCE = src.REPORTING_SOURCE,
                tgt.REPORTING_SOURCE_COUNTY = src.REPORTING_SOURCE_COUNTY,
                tgt.REPORTING_SOURCE_CITY = src.REPORTING_SOURCE_CITY,
                tgt.REPORTING_SOURCE_STATE = src.REPORTING_SOURCE_STATE,
                tgt.REPORTING_SOURCE_ADDRESS_USE = src.REPORTING_SOURCE_ADDRESS_USE,
                tgt.REPORTING_SOURCE_ADDRESS_TYPE = src.REPORTING_SOURCE_ADDRESS_TYPE,
                tgt.PHYSICIAN_NAME = src.PHYSICIAN_NAME,
                tgt.PHYSICIAN_COUNTY = src.PHYSICIAN_COUNTY,
                tgt.PHYSICIAN_CITY = src.PHYSICIAN_CITY,
                tgt.PHYSICIAN_STATE = src.PHYSICIAN_STATE,
                tgt.PHYSICIAN_ADDRESS_USE_DESC = src.PHYSICIAN_ADDRESS_USE_DESC,
                tgt.PHYSICIAN_ADDRESS_TYPE_DESC = src.PHYSICIAN_ADDRESS_TYPE_DESC,
                tgt.INVESTIGATOR_NAME = src.INVESTIGATOR_NAME,
                tgt.HEP_A_TOTAL_ANTIBODY = src.HEP_A_TOTAL_ANTIBODY,
                tgt.HEP_A_IGM_ANTIBODY = src.HEP_A_IGM_ANTIBODY,
                tgt.HEP_B_SURFACE_ANTIGEN = src.HEP_B_SURFACE_ANTIGEN,
                tgt.HEP_B_TOTAL_ANTIBODY = src.HEP_B_TOTAL_ANTIBODY,
                tgt.HEP_B_IGM_ANTIBODY = src.HEP_B_IGM_ANTIBODY,
                tgt.HEP_C_TOTAL_ANTIBODY = src.HEP_C_TOTAL_ANTIBODY,
                tgt.HEP_D_TOTAL_ANTIBODY = src.HEP_D_TOTAL_ANTIBODY,
                tgt.HEP_E_TOTAL_ANTIBODY = src.HEP_E_TOTAL_ANTIBODY,
                tgt.ANTIHCV_SIGNAL_TO_CUTOFF_RATIO = src.ANTIHCV_SIGNAL_TO_CUTOFF_RATIO,
                tgt.ANTIHCV_SUPPLEMENTAL_ASSAY = src.ANTIHCV_SUPPLEMENTAL_ASSAY,
                tgt.HCV_RNA = src.HCV_RNA,
                tgt.ALT_SGPT_RESULT = src.ALT_SGPT_RESULT,
                tgt.ALT_SGPT_RESULT_UPPER_LIMIT = src.ALT_SGPT_RESULT_UPPER_LIMIT,
                tgt.AST_SGOT_RESULT = src.AST_SGOT_RESULT,
                tgt.AST_SGOT_RESULT_UPPER_LIMIT = src.AST_SGOT_RESULT_UPPER_LIMIT,
                tgt.ALT_RESULT_DT = src.ALT_RESULT_DT,
                tgt.AST_RESULT_DT = src.AST_RESULT_DT,
                tgt.INV_START_DT = src.INV_START_DT,
                tgt.INV_RPT_DT = src.INV_RPT_DT,
                tgt.EARLIEST_RPT_TO_CNTY_DT = src.EARLIEST_RPT_TO_CNTY_DT,
                tgt.EARLIEST_RPT_TO_STATE_DT = src.EARLIEST_RPT_TO_STATE_DT,
                tgt.DIE_FRM_THIS_ILLNESS_IND = src.DIE_FRM_THIS_ILLNESS_IND,
                tgt.ILLNESS_ONSET_DT = src.ILLNESS_ONSET_DT,
                tgt.DIAGNOSIS_DT = src.DIAGNOSIS_DT,
                tgt.HSPTLIZD_IND = src.HSPTLIZD_IND,
                tgt.HSPTL_ADMISSION_DT = src.HSPTL_ADMISSION_DT,
                tgt.HSPTL_DISCHARGE_DT = src.HSPTL_DISCHARGE_DT,
                tgt.HSPTL_DURATION_DAYS = src.HSPTL_DURATION_DAYS,
                tgt.OUTBREAK_IND = src.OUTBREAK_IND,
                tgt.TRANSMISSION_MODE = src.TRANSMISSION_MODE,
                tgt.DISEASE_IMPORTED_IND = src.DISEASE_IMPORTED_IND,
                tgt.IMPORT_FROM_COUNTRY = src.IMPORT_FROM_COUNTRY,
                tgt.IMPORT_FROM_STATE = src.IMPORT_FROM_STATE,
                tgt.IMPORT_FROM_COUNTY = src.IMPORT_FROM_COUNTY,
                tgt.IMPORT_FROM_CITY = src.IMPORT_FROM_CITY,
                tgt.INV_COMMENTS = src.INV_COMMENTS,
                tgt.CASE_RPT_MMWR_WEEK = src.CASE_RPT_MMWR_WEEK,
                tgt.CASE_RPT_MMWR_YEAR = src.CASE_RPT_MMWR_YEAR,
                tgt.PATIENT_SYMPTOMATIC_IND = src.PATIENT_SYMPTOMATIC_IND,
                tgt.PATIENT_JUNDICED_IND = src.PATIENT_JUNDICED_IND,
                tgt.PATIENT_PREGNANT_IND = src.PATIENT_PREGNANT_IND,
                tgt.PATIENT_PREGNANCY_DUE_DT = src.PATIENT_PREGNANCY_DUE_DT,
                tgt.HEP_A_EPLINK_IND = src.HEP_A_EPLINK_IND,
                tgt.HEP_A_CONTACTED_IND = src.HEP_A_CONTACTED_IND,
                tgt.D_N_P_EMPLOYEE_IND = src.D_N_P_EMPLOYEE_IND,
                tgt.D_N_P_HOUSEHOLD_CONTACT_IND = src.D_N_P_HOUSEHOLD_CONTACT_IND,
                tgt.HEP_A_KEYENT_IN_CHILDCARE_IND = src.HEP_A_KEYENT_IN_CHILDCARE_IND,
                tgt.HEPA_MALE_SEX_PARTNER_NBR = src.HEPA_MALE_SEX_PARTNER_NBR,
                tgt.HEPA_FEMALE_SEX_PARTNER_NBR = src.HEPA_FEMALE_SEX_PARTNER_NBR,
                tgt.STREET_DRUG_INJECTED_IN_2_6_WK = src.STREET_DRUG_INJECTED_IN_2_6_WK,
                tgt.STREET_DRUG_USED_IN_2_6_WK = src.STREET_DRUG_USED_IN_2_6_WK,
                tgt.TRAVEL_OUT_USA_CAN_IND = src.TRAVEL_OUT_USA_CAN_IND,
                tgt.HOUSEHOLD_NPP_OUT_USA_CAN = src.HOUSEHOLD_NPP_OUT_USA_CAN,
                tgt.PART_OF_AN_OUTBRK_IND = src.PART_OF_AN_OUTBRK_IND,
                tgt.ASSOCIATED_OUTBRK_TYPE = src.ASSOCIATED_OUTBRK_TYPE,
                tgt.FOODBORNE_OUTBRK_FOOD_ITEM = src.FOODBORNE_OUTBRK_FOOD_ITEM,
                tgt.FOODHANDLER_2_WK_PRIOR_ONSET = src.FOODHANDLER_2_WK_PRIOR_ONSET,
                tgt.HEP_A_VACC_RECEIVED_IND = src.HEP_A_VACC_RECEIVED_IND,
                tgt.HEP_A_VACC_RECEIVED_DOSE = src.HEP_A_VACC_RECEIVED_DOSE,
                tgt.HEP_A_VACC_LAST_RECEIVED_YR = src.HEP_A_VACC_LAST_RECEIVED_YR,
                tgt.IMMUNE_GLOBULIN_RECEIVED_IND = src.IMMUNE_GLOBULIN_RECEIVED_IND,
                tgt.GLOBULIN_LAST_RECEIVED_YR = src.GLOBULIN_LAST_RECEIVED_YR,
                tgt.HEP_B_CONTACTED_IND = src.HEP_B_CONTACTED_IND,
                tgt.HEPB_STD_TREATED_IND = src.HEPB_STD_TREATED_IND,
                tgt.HEPB_STD_LAST_TREATMENT_YR = src.HEPB_STD_LAST_TREATMENT_YR,
                tgt.STREET_DRUG_INJECTED_IN6WKMON = src.STREET_DRUG_INJECTED_IN6WKMON,
                tgt.STREET_DRUG_USED_IN6WKMON = src.STREET_DRUG_USED_IN6WKMON,
                tgt.HEPB_FEMALE_SEX_PARTNER_NBR = src.HEPB_FEMALE_SEX_PARTNER_NBR,
                tgt.HEPB_MALE_SEX_PARTNER_NBR = src.HEPB_MALE_SEX_PARTNER_NBR,
                tgt.HEMODIALYSIS_IN_LAST_6WKMON = src.HEMODIALYSIS_IN_LAST_6WKMON,
                tgt.BLOOD_CONTAMINATION_IN6WKMON = src.BLOOD_CONTAMINATION_IN6WKMON,
                tgt.HEPB_BLOOD_RECEIVED_IN6WKMON = src.HEPB_BLOOD_RECEIVED_IN6WKMON,
                tgt.HEPB_BLOOD_RECEIVED_DT = src.HEPB_BLOOD_RECEIVED_DT,
                tgt.OUTPATIENT_IV_INFUSION_IN6WKMO = src.OUTPATIENT_IV_INFUSION_IN6WKMO,
                tgt.BLOOD_EXPOSURE_IN_LAST6WKMON = src.BLOOD_EXPOSURE_IN_LAST6WKMON,
                tgt.BLOOD_EXPOSURE_IN6WKMON_OTHER = src.BLOOD_EXPOSURE_IN6WKMON_OTHER,
                tgt.HEPB_MED_DEN_EMPLOYEE_IN6WKMON = src.HEPB_MED_DEN_EMPLOYEE_IN6WKMON,
                tgt.HEPB_MED_DEN_BLOOD_CONTACT_FRQ = src.HEPB_MED_DEN_BLOOD_CONTACT_FRQ,
                tgt.HEPB_PUB_SAFETY_WORKER_IN6WKMO = src.HEPB_PUB_SAFETY_WORKER_IN6WKMO,
                tgt.HEPB_PUBSAFETY_BLOODCONTACTFRQ = src.HEPB_PUBSAFETY_BLOODCONTACTFRQ,
                tgt.TATTOOED_IN6WKMON_BEFORE_ONSET = src.TATTOOED_IN6WKMON_BEFORE_ONSET,
                tgt.PIERCING_IN6WKMON_BEFORE_ONSET = src.PIERCING_IN6WKMON_BEFORE_ONSET,
                tgt.DEN_WORK_OR_SURGERY_IN6WKMON = src.DEN_WORK_OR_SURGERY_IN6WKMON,
                tgt.NON_ORAL_SURGERY_IN6WKMON = src.NON_ORAL_SURGERY_IN6WKMON,
                tgt.HSPTLIZD_IN6WKMON_BEFORE_ONSET = src.HSPTLIZD_IN6WKMON_BEFORE_ONSET,
                tgt.LONGTERMCARE_RESIDENT_IN6WKMON = src.LONGTERMCARE_RESIDENT_IN6WKMON,
                tgt.B_INCARCERATED24PLUSHRSIN6WKMO = src.B_INCARCERATED24PLUSHRSIN6WKMO,
                tgt.B_INCARCERATED_6PLUS_MON_IND = src.B_INCARCERATED_6PLUS_MON_IND,
                tgt.B_LAST6PLUSMON_INCARCERATE_YR = src.B_LAST6PLUSMON_INCARCERATE_YR,
                tgt.BLAST6PLUSMO_INCARCERATEPERIOD = src.BLAST6PLUSMO_INCARCERATEPERIOD,
                tgt.B_LAST_INCARCERATE_PERIOD_UNIT = src.B_LAST_INCARCERATE_PERIOD_UNIT,
                tgt.HEP_B_VACC_RECEIVED_IND = src.HEP_B_VACC_RECEIVED_IND,
                tgt.HEP_B_VACC_SHOT_RECEIVED_NBR = src.HEP_B_VACC_SHOT_RECEIVED_NBR,
                tgt.HEP_B_VACC_LAST_RECEIVED_YR = src.HEP_B_VACC_LAST_RECEIVED_YR,
                tgt.ANTI_HBSAG_TESTED_IND = src.ANTI_HBSAG_TESTED_IND,
                tgt.ANTI_HBS_POSITIVE_REACTIVE_IND = src.ANTI_HBS_POSITIVE_REACTIVE_IND,
                tgt.HEP_C_CONTACTED_IND = src.HEP_C_CONTACTED_IND,
                tgt.MED_DEN_EMPLOYEE_IN_2WK6MO = src.MED_DEN_EMPLOYEE_IN_2WK6MO,
                tgt.HEPC_MED_DEN_BLOOD_CONTACT_FRQ = src.HEPC_MED_DEN_BLOOD_CONTACT_FRQ,
                tgt.PUBLIC_SAFETY_WORKER_IN_2WK6MO = src.PUBLIC_SAFETY_WORKER_IN_2WK6MO,
                tgt.HEPC_PUBSAFETY_BLOODCONTACTFRQ = src.HEPC_PUBSAFETY_BLOODCONTACTFRQ,
                tgt.TATTOOED_IN2WK6MO_BEFORE_ONSET = src.TATTOOED_IN2WK6MO_BEFORE_ONSET,
                tgt.TATTOOED_IN2WK6MO_LOCATION = src.TATTOOED_IN2WK6MO_LOCATION,
                tgt.PIERCING_IN2WK6MO_BEFORE_ONSET = src.PIERCING_IN2WK6MO_BEFORE_ONSET,
                tgt.PIERCING_IN2WK6MO_LOCATION = src.PIERCING_IN2WK6MO_LOCATION,
                tgt.STREET_DRUG_INJECTED_IN_2WK6MO = src.STREET_DRUG_INJECTED_IN_2WK6MO,
                tgt.STREET_DRUG_USED_IN_2WK6MO = src.STREET_DRUG_USED_IN_2WK6MO,
                tgt.HEMODIALYSIS_IN_LAST_2WK6MO = src.HEMODIALYSIS_IN_LAST_2WK6MO,
                tgt.BLOOD_CONTAMINATION_IN_2WK6MO = src.BLOOD_CONTAMINATION_IN_2WK6MO,
                tgt.HEPC_BLOOD_RECEIVED_IN_2WK6MO = src.HEPC_BLOOD_RECEIVED_IN_2WK6MO,
                tgt.HEPC_BLOOD_RECEIVED_DT = src.HEPC_BLOOD_RECEIVED_DT,
                tgt.BLOOD_EXPOSURE_IN_LAST2WK6MO = src.BLOOD_EXPOSURE_IN_LAST2WK6MO,
                tgt.BLOOD_EXPOSURE_IN2WK6MO_OTHER = src.BLOOD_EXPOSURE_IN2WK6MO_OTHER,
                tgt.DEN_WORK_OR_SURGERY_IN2WK6MO = src.DEN_WORK_OR_SURGERY_IN2WK6MO,
                tgt.NON_ORAL_SURGERY_IN2WK6MO = src.NON_ORAL_SURGERY_IN2WK6MO,
                tgt.HSPTLIZD_IN2WK6MO_BEFORE_ONSET = src.HSPTLIZD_IN2WK6MO_BEFORE_ONSET,
                tgt.LONGTERMCARE_RESIDENT_IN2WK6MO = src.LONGTERMCARE_RESIDENT_IN2WK6MO,
                tgt.INCARCERATED_24PLUSHRSIN2WK6MO = src.INCARCERATED_24PLUSHRSIN2WK6MO,
                tgt.HEPC_FEMALE_SEX_PARTNER_NBR = src.HEPC_FEMALE_SEX_PARTNER_NBR,
                tgt.HEPC_MALE_SEX_PARTNER_NBR = src.HEPC_MALE_SEX_PARTNER_NBR,
                tgt.C_INCARCERATED_6PLUS_MON_IND = src.C_INCARCERATED_6PLUS_MON_IND,
                tgt.C_LAST6PLUSMON_INCARCERATE_YR = src.C_LAST6PLUSMON_INCARCERATE_YR,
                tgt.CLAST6PLUSMO_INCARCERATEPERIOD = src.CLAST6PLUSMO_INCARCERATEPERIOD,
                tgt.C_LAST_INCARCERATE_PERIOD_UNIT = src.C_LAST_INCARCERATE_PERIOD_UNIT,
                tgt.HEPC_STD_TREATED_IND = src.HEPC_STD_TREATED_IND,
                tgt.HEPC_STD_LAST_TREATMENT_YR = src.HEPC_STD_LAST_TREATMENT_YR,
                tgt.BLOOD_TRANSFUSION_BEFORE_1992 = src.BLOOD_TRANSFUSION_BEFORE_1992,
                tgt.ORGAN_TRANSPLANT_BEFORE_1992 = src.ORGAN_TRANSPLANT_BEFORE_1992,
                tgt.CLOT_FACTOR_CONCERN_BEFORE1987 = src.CLOT_FACTOR_CONCERN_BEFORE1987,
                tgt.LONGTERM_HEMODIALYSIS_IND = src.LONGTERM_HEMODIALYSIS_IND,
                tgt.EVER_INJECT_NONPRESCRIBED_DRUG = src.EVER_INJECT_NONPRESCRIBED_DRUG,
                tgt.LIFETIME_SEX_PARTNER_NBR = src.LIFETIME_SEX_PARTNER_NBR,
                tgt.EVER_INCARCERATED_IND = src.EVER_INCARCERATED_IND,
                tgt.HEPATITIS_CONTACTED_IND = src.HEPATITIS_CONTACTED_IND,
                tgt.HEPATITIS_CONTACT_TYPE = src.HEPATITIS_CONTACT_TYPE,
                tgt.HEPATITIS_OTHER_CONTACT_TYPE = src.HEPATITIS_OTHER_CONTACT_TYPE,
                tgt.HEPC_MED_DEN_EMPLOYEE_IND = src.HEPC_MED_DEN_EMPLOYEE_IND,
                tgt.OUTPATIENT_IV_INFUSIONIN2WK6MO = src.OUTPATIENT_IV_INFUSIONIN2WK6MO,
                tgt.EVENT_DATE = src.EVENT_DATE,
                tgt.HEP_MULTI_VAL_GRP_KEY = src.HEP_MULTI_VAL_GRP_KEY,
                tgt.INVESTIGATION_KEY = src.INVESTIGATION_KEY,
                tgt.HEP_B_E_ANTIGEN = src.HEP_B_E_ANTIGEN,
                tgt.HEP_B_DNA = src.HEP_B_DNA,
                tgt.PATIENT_UID = src.PATIENT_UID,
                tgt.PHYSICIAN_UID = src.PHYSICIAN_UID,
                tgt.INVESTIGATOR_UID = src.INVESTIGATOR_UID,
                tgt.CASE_UID = src.CASE_UID,
                tgt.REFRESH_DATETIME = src.REFRESH_DATETIME,
                tgt.REPORTING_SOURCE_UID = src.REPORTING_SOURCE_UID,
                tgt.PLACE_OF_BIRTH = src.PLACE_OF_BIRTH
            FROM #HEP100_INIT src
            LEFT JOIN dbo.HEP100 tgt WITH (NOLOCK) ON src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY;


            SELECT @RowCount_no = @@ROWCOUNT;


            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;


                BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERT INTO dbo.HEP100';

            INSERT INTO dbo.HEP100
            (
                PATIENT_LOCAL_ID,
                PROGRAM_JURISDICTION_OID,
                PATIENT_FIRST_NM,
                PATIENT_MIDDLE_NM,
                PATIENT_LAST_NM,
                PATIENT_DOB,
                PATIENT_REPORTEDAGE,
                PATIENT_REPORTED_AGE_UNITS,
                ADDR_USE_CD_DESC,
                ADDR_CD_DESC,
                PATIENT_ADDRESS,
                PATIENT_CITY,
                PATIENT_COUNTY,
                PATIENT_ZIP_CODE,
                PATIENT_CURR_GENDER,
                PATIENT_ELECTRONIC_IND,
                RACE,
                CONDITION_CD,
                CONDITION,
                INV_LOCAL_ID,
                INVESTIGATION_STATUS,
                INV_CASE_STATUS,
                INV_JURISDICTION_NM,
                RPT_SRC_CD_DESC,
                REPORTING_SOURCE,
                REPORTING_SOURCE_COUNTY,
                REPORTING_SOURCE_CITY,
                REPORTING_SOURCE_STATE,
                REPORTING_SOURCE_ADDRESS_USE,
                REPORTING_SOURCE_ADDRESS_TYPE,
                PHYSICIAN_NAME,
                PHYSICIAN_COUNTY,
                PHYSICIAN_CITY,
                PHYSICIAN_STATE,
                PHYSICIAN_ADDRESS_USE_DESC,
                PHYSICIAN_ADDRESS_TYPE_DESC,
                INVESTIGATOR_NAME,
                HEP_A_TOTAL_ANTIBODY,
                HEP_A_IGM_ANTIBODY,
                HEP_B_SURFACE_ANTIGEN,
                HEP_B_TOTAL_ANTIBODY,
                HEP_B_IGM_ANTIBODY,
                HEP_C_TOTAL_ANTIBODY,
                HEP_D_TOTAL_ANTIBODY,
                HEP_E_TOTAL_ANTIBODY,
                ANTIHCV_SIGNAL_TO_CUTOFF_RATIO,
                ANTIHCV_SUPPLEMENTAL_ASSAY,
                HCV_RNA,
                ALT_SGPT_RESULT,
                ALT_SGPT_RESULT_UPPER_LIMIT,
                AST_SGOT_RESULT,
                AST_SGOT_RESULT_UPPER_LIMIT,
                ALT_RESULT_DT,
                AST_RESULT_DT,
                INV_START_DT,
                INV_RPT_DT,
                EARLIEST_RPT_TO_CNTY_DT,
                EARLIEST_RPT_TO_STATE_DT,
                DIE_FRM_THIS_ILLNESS_IND,
                ILLNESS_ONSET_DT,
                DIAGNOSIS_DT,
                HSPTLIZD_IND,
                HSPTL_ADMISSION_DT,
                HSPTL_DISCHARGE_DT,
                HSPTL_DURATION_DAYS,
                OUTBREAK_IND,
                TRANSMISSION_MODE,
                DISEASE_IMPORTED_IND,
                IMPORT_FROM_COUNTRY,
                IMPORT_FROM_STATE,
                IMPORT_FROM_COUNTY,
                IMPORT_FROM_CITY,
                INV_COMMENTS,
                CASE_RPT_MMWR_WEEK,
                CASE_RPT_MMWR_YEAR,
                PATIENT_SYMPTOMATIC_IND,
                PATIENT_JUNDICED_IND,
                PATIENT_PREGNANT_IND,
                PATIENT_PREGNANCY_DUE_DT,
                HEP_A_EPLINK_IND,
                HEP_A_CONTACTED_IND,
                D_N_P_EMPLOYEE_IND,
                D_N_P_HOUSEHOLD_CONTACT_IND,
                HEP_A_KEYENT_IN_CHILDCARE_IND,
                HEPA_MALE_SEX_PARTNER_NBR,
                HEPA_FEMALE_SEX_PARTNER_NBR,
                STREET_DRUG_INJECTED_IN_2_6_WK,
                STREET_DRUG_USED_IN_2_6_WK,
                TRAVEL_OUT_USA_CAN_IND,
                HOUSEHOLD_NPP_OUT_USA_CAN,
                PART_OF_AN_OUTBRK_IND,
                ASSOCIATED_OUTBRK_TYPE,
                FOODBORNE_OUTBRK_FOOD_ITEM,
                FOODHANDLER_2_WK_PRIOR_ONSET,
                HEP_A_VACC_RECEIVED_IND,
                HEP_A_VACC_RECEIVED_DOSE,
                HEP_A_VACC_LAST_RECEIVED_YR,
                IMMUNE_GLOBULIN_RECEIVED_IND,
                GLOBULIN_LAST_RECEIVED_YR,
                HEP_B_CONTACTED_IND,
                HEPB_STD_TREATED_IND,
                HEPB_STD_LAST_TREATMENT_YR,
                STREET_DRUG_INJECTED_IN6WKMON,
                STREET_DRUG_USED_IN6WKMON,
                HEPB_FEMALE_SEX_PARTNER_NBR,
                HEPB_MALE_SEX_PARTNER_NBR,
                HEMODIALYSIS_IN_LAST_6WKMON,
                BLOOD_CONTAMINATION_IN6WKMON,
                HEPB_BLOOD_RECEIVED_IN6WKMON,
                HEPB_BLOOD_RECEIVED_DT,
                OUTPATIENT_IV_INFUSION_IN6WKMO,
                BLOOD_EXPOSURE_IN_LAST6WKMON,
                BLOOD_EXPOSURE_IN6WKMON_OTHER,
                HEPB_MED_DEN_EMPLOYEE_IN6WKMON,
                HEPB_MED_DEN_BLOOD_CONTACT_FRQ,
                HEPB_PUB_SAFETY_WORKER_IN6WKMO,
                HEPB_PUBSAFETY_BLOODCONTACTFRQ,
                TATTOOED_IN6WKMON_BEFORE_ONSET,
                PIERCING_IN6WKMON_BEFORE_ONSET,
                DEN_WORK_OR_SURGERY_IN6WKMON,
                NON_ORAL_SURGERY_IN6WKMON,
                HSPTLIZD_IN6WKMON_BEFORE_ONSET,
                LONGTERMCARE_RESIDENT_IN6WKMON,
                B_INCARCERATED24PLUSHRSIN6WKMO,
                B_INCARCERATED_6PLUS_MON_IND,
                B_LAST6PLUSMON_INCARCERATE_YR,
                BLAST6PLUSMO_INCARCERATEPERIOD,
                B_LAST_INCARCERATE_PERIOD_UNIT,
                HEP_B_VACC_RECEIVED_IND,
                HEP_B_VACC_SHOT_RECEIVED_NBR,
                HEP_B_VACC_LAST_RECEIVED_YR,
                ANTI_HBSAG_TESTED_IND,
                ANTI_HBS_POSITIVE_REACTIVE_IND,
                HEP_C_CONTACTED_IND,
                MED_DEN_EMPLOYEE_IN_2WK6MO,
                HEPC_MED_DEN_BLOOD_CONTACT_FRQ,
                PUBLIC_SAFETY_WORKER_IN_2WK6MO,
                HEPC_PUBSAFETY_BLOODCONTACTFRQ,
                TATTOOED_IN2WK6MO_BEFORE_ONSET,
                TATTOOED_IN2WK6MO_LOCATION,
                PIERCING_IN2WK6MO_BEFORE_ONSET,
                PIERCING_IN2WK6MO_LOCATION,
                STREET_DRUG_INJECTED_IN_2WK6MO,
                STREET_DRUG_USED_IN_2WK6MO,
                HEMODIALYSIS_IN_LAST_2WK6MO,
                BLOOD_CONTAMINATION_IN_2WK6MO,
                HEPC_BLOOD_RECEIVED_IN_2WK6MO,
                HEPC_BLOOD_RECEIVED_DT,
                BLOOD_EXPOSURE_IN_LAST2WK6MO,
                BLOOD_EXPOSURE_IN2WK6MO_OTHER,
                DEN_WORK_OR_SURGERY_IN2WK6MO,
                NON_ORAL_SURGERY_IN2WK6MO,
                HSPTLIZD_IN2WK6MO_BEFORE_ONSET,
                LONGTERMCARE_RESIDENT_IN2WK6MO,
                INCARCERATED_24PLUSHRSIN2WK6MO,
                HEPC_FEMALE_SEX_PARTNER_NBR,
                HEPC_MALE_SEX_PARTNER_NBR,
                C_INCARCERATED_6PLUS_MON_IND,
                C_LAST6PLUSMON_INCARCERATE_YR,
                CLAST6PLUSMO_INCARCERATEPERIOD,
                C_LAST_INCARCERATE_PERIOD_UNIT,
                HEPC_STD_TREATED_IND,
                HEPC_STD_LAST_TREATMENT_YR,
                BLOOD_TRANSFUSION_BEFORE_1992,
                ORGAN_TRANSPLANT_BEFORE_1992,
                CLOT_FACTOR_CONCERN_BEFORE1987,
                LONGTERM_HEMODIALYSIS_IND,
                EVER_INJECT_NONPRESCRIBED_DRUG,
                LIFETIME_SEX_PARTNER_NBR,
                EVER_INCARCERATED_IND,
                HEPATITIS_CONTACTED_IND,
                HEPATITIS_CONTACT_TYPE,
                HEPATITIS_OTHER_CONTACT_TYPE,
                HEPC_MED_DEN_EMPLOYEE_IND,
                OUTPATIENT_IV_INFUSIONIN2WK6MO,
                EVENT_DATE,
                HEP_MULTI_VAL_GRP_KEY,
                INVESTIGATION_KEY,
                HEP_B_E_ANTIGEN,
                HEP_B_DNA,
                PATIENT_UID,
                PHYSICIAN_UID,
                INVESTIGATOR_UID,
                CASE_UID,
                REFRESH_DATETIME,
                REPORTING_SOURCE_UID,
                PLACE_OF_BIRTH
            )
            SELECT
                src.PATIENT_LOCAL_ID,
                src.PROGRAM_JURISDICTION_OID,
                src.PATIENT_FIRST_NM,
                src.PATIENT_MIDDLE_NM,
                src.PATIENT_LAST_NM,
                src.PATIENT_DOB,
                src.PATIENT_REPORTEDAGE,
                src.PATIENT_REPORTED_AGE_UNITS,
                src.ADDR_USE_CD_DESC,
                src.ADDR_CD_DESC,
                src.PATIENT_ADDRESS,
                src.PATIENT_CITY,
                src.PATIENT_COUNTY,
                src.PATIENT_ZIP_CODE,
                src.PATIENT_CURR_GENDER,
                src.PATIENT_ELECTRONIC_IND,
                src.RACE,
                src.CONDITION_CD,
                src.CONDITION,
                src.INV_LOCAL_ID,
                src.INVESTIGATION_STATUS,
                src.INV_CASE_STATUS,
                src.INV_JURISDICTION_NM,
                src.RPT_SRC_CD_DESC,
                src.REPORTING_SOURCE,
                src.REPORTING_SOURCE_COUNTY,
                src.REPORTING_SOURCE_CITY,
                src.REPORTING_SOURCE_STATE,
                src.REPORTING_SOURCE_ADDRESS_USE,
                src.REPORTING_SOURCE_ADDRESS_TYPE,
                src.PHYSICIAN_NAME,
                src.PHYSICIAN_COUNTY,
                src.PHYSICIAN_CITY,
                src.PHYSICIAN_STATE,
                src.PHYSICIAN_ADDRESS_USE_DESC,
                src.PHYSICIAN_ADDRESS_TYPE_DESC,
                src.INVESTIGATOR_NAME,
                src.HEP_A_TOTAL_ANTIBODY,
                src.HEP_A_IGM_ANTIBODY,
                src.HEP_B_SURFACE_ANTIGEN,
                src.HEP_B_TOTAL_ANTIBODY,
                src.HEP_B_IGM_ANTIBODY,
                src.HEP_C_TOTAL_ANTIBODY,
                src.HEP_D_TOTAL_ANTIBODY,
                src.HEP_E_TOTAL_ANTIBODY,
                src.ANTIHCV_SIGNAL_TO_CUTOFF_RATIO,
                src.ANTIHCV_SUPPLEMENTAL_ASSAY,
                src.HCV_RNA,
                src.ALT_SGPT_RESULT,
                src.ALT_SGPT_RESULT_UPPER_LIMIT,
                src.AST_SGOT_RESULT,
                src.AST_SGOT_RESULT_UPPER_LIMIT,
                src.ALT_RESULT_DT,
                src.AST_RESULT_DT,
                src.INV_START_DT,
                src.INV_RPT_DT,
                src.EARLIEST_RPT_TO_CNTY_DT,
                src.EARLIEST_RPT_TO_STATE_DT,
                src.DIE_FRM_THIS_ILLNESS_IND,
                src.ILLNESS_ONSET_DT,
                src.DIAGNOSIS_DT,
                src.HSPTLIZD_IND,
                src.HSPTL_ADMISSION_DT,
                src.HSPTL_DISCHARGE_DT,
                src.HSPTL_DURATION_DAYS,
                src.OUTBREAK_IND,
                src.TRANSMISSION_MODE,
                src.DISEASE_IMPORTED_IND,
                src.IMPORT_FROM_COUNTRY,
                src.IMPORT_FROM_STATE,
                src.IMPORT_FROM_COUNTY,
                src.IMPORT_FROM_CITY,
                src.INV_COMMENTS,
                src.CASE_RPT_MMWR_WEEK,
                src.CASE_RPT_MMWR_YEAR,
                src.PATIENT_SYMPTOMATIC_IND,
                src.PATIENT_JUNDICED_IND,
                src.PATIENT_PREGNANT_IND,
                src.PATIENT_PREGNANCY_DUE_DT,
                src.HEP_A_EPLINK_IND,
                src.HEP_A_CONTACTED_IND,
                src.D_N_P_EMPLOYEE_IND,
                src.D_N_P_HOUSEHOLD_CONTACT_IND,
                src.HEP_A_KEYENT_IN_CHILDCARE_IND,
                src.HEPA_MALE_SEX_PARTNER_NBR,
                src.HEPA_FEMALE_SEX_PARTNER_NBR,
                src.STREET_DRUG_INJECTED_IN_2_6_WK,
                src.STREET_DRUG_USED_IN_2_6_WK,
                src.TRAVEL_OUT_USA_CAN_IND,
                src.HOUSEHOLD_NPP_OUT_USA_CAN,
                src.PART_OF_AN_OUTBRK_IND,
                src.ASSOCIATED_OUTBRK_TYPE,
                src.FOODBORNE_OUTBRK_FOOD_ITEM,
                src.FOODHANDLER_2_WK_PRIOR_ONSET,
                src.HEP_A_VACC_RECEIVED_IND,
                src.HEP_A_VACC_RECEIVED_DOSE,
                src.HEP_A_VACC_LAST_RECEIVED_YR,
                src.IMMUNE_GLOBULIN_RECEIVED_IND,
                src.GLOBULIN_LAST_RECEIVED_YR,
                src.HEP_B_CONTACTED_IND,
                src.HEPB_STD_TREATED_IND,
                src.HEPB_STD_LAST_TREATMENT_YR,
                src.STREET_DRUG_INJECTED_IN6WKMON,
                src.STREET_DRUG_USED_IN6WKMON,
                src.HEPB_FEMALE_SEX_PARTNER_NBR,
                src.HEPB_MALE_SEX_PARTNER_NBR,
                src.HEMODIALYSIS_IN_LAST_6WKMON,
                src.BLOOD_CONTAMINATION_IN6WKMON,
                src.HEPB_BLOOD_RECEIVED_IN6WKMON,
                src.HEPB_BLOOD_RECEIVED_DT,
                src.OUTPATIENT_IV_INFUSION_IN6WKMO,
                src.BLOOD_EXPOSURE_IN_LAST6WKMON,
                src.BLOOD_EXPOSURE_IN6WKMON_OTHER,
                src.HEPB_MED_DEN_EMPLOYEE_IN6WKMON,
                src.HEPB_MED_DEN_BLOOD_CONTACT_FRQ,
                src.HEPB_PUB_SAFETY_WORKER_IN6WKMO,
                src.HEPB_PUBSAFETY_BLOODCONTACTFRQ,
                src.TATTOOED_IN6WKMON_BEFORE_ONSET,
                src.PIERCING_IN6WKMON_BEFORE_ONSET,
                src.DEN_WORK_OR_SURGERY_IN6WKMON,
                src.NON_ORAL_SURGERY_IN6WKMON,
                src.HSPTLIZD_IN6WKMON_BEFORE_ONSET,
                src.LONGTERMCARE_RESIDENT_IN6WKMON,
                src.B_INCARCERATED24PLUSHRSIN6WKMO,
                src.B_INCARCERATED_6PLUS_MON_IND,
                src.B_LAST6PLUSMON_INCARCERATE_YR,
                src.BLAST6PLUSMO_INCARCERATEPERIOD,
                src.B_LAST_INCARCERATE_PERIOD_UNIT,
                src.HEP_B_VACC_RECEIVED_IND,
                src.HEP_B_VACC_SHOT_RECEIVED_NBR,
                src.HEP_B_VACC_LAST_RECEIVED_YR,
                src.ANTI_HBSAG_TESTED_IND,
                src.ANTI_HBS_POSITIVE_REACTIVE_IND,
                src.HEP_C_CONTACTED_IND,
                src.MED_DEN_EMPLOYEE_IN_2WK6MO,
                src.HEPC_MED_DEN_BLOOD_CONTACT_FRQ,
                src.PUBLIC_SAFETY_WORKER_IN_2WK6MO,
                src.HEPC_PUBSAFETY_BLOODCONTACTFRQ,
                src.TATTOOED_IN2WK6MO_BEFORE_ONSET,
                src.TATTOOED_IN2WK6MO_LOCATION,
                src.PIERCING_IN2WK6MO_BEFORE_ONSET,
                src.PIERCING_IN2WK6MO_LOCATION,
                src.STREET_DRUG_INJECTED_IN_2WK6MO,
                src.STREET_DRUG_USED_IN_2WK6MO,
                src.HEMODIALYSIS_IN_LAST_2WK6MO,
                src.BLOOD_CONTAMINATION_IN_2WK6MO,
                src.HEPC_BLOOD_RECEIVED_IN_2WK6MO,
                src.HEPC_BLOOD_RECEIVED_DT,
                src.BLOOD_EXPOSURE_IN_LAST2WK6MO,
                src.BLOOD_EXPOSURE_IN2WK6MO_OTHER,
                src.DEN_WORK_OR_SURGERY_IN2WK6MO,
                src.NON_ORAL_SURGERY_IN2WK6MO,
                src.HSPTLIZD_IN2WK6MO_BEFORE_ONSET,
                src.LONGTERMCARE_RESIDENT_IN2WK6MO,
                src.INCARCERATED_24PLUSHRSIN2WK6MO,
                src.HEPC_FEMALE_SEX_PARTNER_NBR,
                src.HEPC_MALE_SEX_PARTNER_NBR,
                src.C_INCARCERATED_6PLUS_MON_IND,
                src.C_LAST6PLUSMON_INCARCERATE_YR,
                src.CLAST6PLUSMO_INCARCERATEPERIOD,
                src.C_LAST_INCARCERATE_PERIOD_UNIT,
                src.HEPC_STD_TREATED_IND,
                src.HEPC_STD_LAST_TREATMENT_YR,
                src.BLOOD_TRANSFUSION_BEFORE_1992,
                src.ORGAN_TRANSPLANT_BEFORE_1992,
                src.CLOT_FACTOR_CONCERN_BEFORE1987,
                src.LONGTERM_HEMODIALYSIS_IND,
                src.EVER_INJECT_NONPRESCRIBED_DRUG,
                src.LIFETIME_SEX_PARTNER_NBR,
                src.EVER_INCARCERATED_IND,
                src.HEPATITIS_CONTACTED_IND,
                src.HEPATITIS_CONTACT_TYPE,
                src.HEPATITIS_OTHER_CONTACT_TYPE,
                src.HEPC_MED_DEN_EMPLOYEE_IND,
                src.OUTPATIENT_IV_INFUSIONIN2WK6MO,
                src.EVENT_DATE,
                src.HEP_MULTI_VAL_GRP_KEY,
                src.INVESTIGATION_KEY,
                src.HEP_B_E_ANTIGEN,
                src.HEP_B_DNA,
                src.PATIENT_UID,
                src.PHYSICIAN_UID,
                src.INVESTIGATOR_UID,
                src.CASE_UID,
                src.REFRESH_DATETIME,
                src.REPORTING_SOURCE_UID,
                src.PLACE_OF_BIRTH
            FROM #HEP100_INIT src
            LEFT JOIN dbo.HEP100 tgt WITH (NOLOCK)
                on src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY
            WHERE tgt.INVESTIGATION_KEY IS NULL;



            SELECT @RowCount_no = @@ROWCOUNT;


            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;
        


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'COMPLETE', 999, 'COMPLETE', 0);


    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;


        DECLARE
            @ErrorNumber INT = ERROR_NUMBER();
        DECLARE
            @ErrorLine INT = ERROR_LINE();
        DECLARE
            @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE
            @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE
            @ErrorState INT = ERROR_STATE();


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [Error_Description]
                                         , [row_count])
        VALUES ( @batch_id
               , @datamart_nm
               , @datamart_nm
               , 'ERROR'
               , @Proc_Step_no
               , @Proc_Step_name
               , LEFT(@ErrorMessage, 500)
               , 0);


        return -1;

    END CATCH

END;
