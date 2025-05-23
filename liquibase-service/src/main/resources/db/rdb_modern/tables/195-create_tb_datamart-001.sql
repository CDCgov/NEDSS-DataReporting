IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'TB_DATAMART' and xtype = 'U')
BEGIN
    CREATE TABLE [dbo].[TB_DATAMART](
        [CALC_5_YEAR_AGE_GROUP] [numeric](18, 0) NULL,
        [CALC_10_YEAR_AGE_GROUP] [numeric](18, 0) NULL,
        [PATIENT_NAME_SUFFIX] [varchar](50) NULL,
        [PATIENT_STATE] [varchar](50) NULL,
        [PATIENT_COUNTY] [varchar](50) NULL,
        [PATIENT_COUNTRY] [varchar](50) NULL,
        [PATIENT_WITHIN_CITY_LIMITS] [varchar](50) NULL,
        [AGE_REPORTED_UNIT] [varchar](50) NULL,
        [PATIENT_BIRTH_SEX] [varchar](50) NULL,
        [PATIENT_CURRENT_SEX] [varchar](50) NULL,
        [PATIENT_DECEASED_INDICATOR] [varchar](50) NULL,
        [PATIENT_MARITAL_STATUS] [varchar](50) NULL,
        [PATIENT_ETHNICITY] [varchar](50) NULL,
        [RACE_CALCULATED] [varchar](4000) NULL,
        [RACE_CALC_DETAILS] [varchar](200) NULL,
        [RACE_ASIAN_1] [varchar](50) NULL,
        [RACE_ASIAN_2] [varchar](50) NULL,
        [RACE_ASIAN_3] [varchar](50) NULL,
        [RACE_ASIAN_GT3_IND] [varchar](50) NULL,
        [RACE_ASIAN_ALL] [varchar](4000) NULL,
        [RACE_NAT_HI_1] [varchar](50) NULL,
        [RACE_NAT_HI_2] [varchar](50) NULL,
        [RACE_NAT_HI_3] [varchar](50) NULL,
        [RACE_NAT_HI_GT3_IND] [varchar](50) NULL,
        [RACE_NAT_HI_ALL] [varchar](4000) NULL,
        [JURISDICTION_NAME] [varchar](50) NULL,
        [PROGRAM_AREA_DESCRIPTION] [varchar](50) NULL,
        [INVESTIGATION_STATUS] [varchar](50) NULL,
        [LINK_REASON_1] [varchar](50) NULL,
        [LINK_REASON_2] [varchar](50) NULL,
        [PREVIOUS_DIAGNOSIS_IND] [varchar](50) NULL,
        [US_BORN_IND] [varchar](50) NULL,
        [PATIENT_BIRTH_COUNTRY] [varchar](50) NULL,
        [PATIENT_OUTSIDE_US_GT_2_MONTHS] [varchar](50) NULL,
        [OUT_OF_CNTRY_1] [varchar](50) NULL,
        [OUT_OF_CNTRY_2] [varchar](50) NULL,
        [OUT_OF_CNTRY_3] [varchar](50) NULL,
        [OUT_OF_CNTRY_GT3_IND] [varchar](50) NULL,
        [OUT_OF_CNTRY_ALL] [varchar](4000) NULL,
        [PRIMARY_GUARD_1_BIRTH_COUNTRY] [varchar](50) NULL,
        [PRIMARY_GUARD_2_BIRTH_COUNTRY] [varchar](50) NULL,
        [STATUS_AT_DIAGNOSIS] [varchar](50) NULL,
        [DISEASE_SITE_1] [varchar](50) NULL,
        [DISEASE_SITE_2] [varchar](50) NULL,
        [DISEASE_SITE_3] [varchar](50) NULL,
        [DISEASE_SITE_GT3_IND] [varchar](50) NULL,
        [DISEASE_SITE_ALL] [varchar](4000) NULL,
        [CALC_DISEASE_SITE] [varchar](50) NULL,
        [SPUTUM_SMEAR_RESULT] [varchar](50) NULL,
        [SPUTUM_CULTURE_RESULT] [varchar](50) NULL,
        [SPUTUM_CULT_RPT_LAB_TY] [varchar](50) NULL,
        [SMR_PATH_CYTO_RESULT] [varchar](50) NULL,
        [SMR_PATH_CYTO_SITE] [varchar](50) NULL,
        [SMR_EXAM_TY_1] [varchar](50) NULL,
        [SMR_EXAM_TY_2] [varchar](50) NULL,
        [SMR_EXAM_TY_3] [varchar](50) NULL,
        [SMR_EXAM_TY_GT3_IND] [varchar](50) NULL,
        [SMR_EXAM_TY_ALL] [varchar](4000) NULL,
        [CULT_TISSUE_RESULT] [varchar](50) NULL,
        [CULT_TISSUE_SITE] [varchar](50) NULL,
        [CULT_TISSUE_RESULT_RPT_LAB_TY] [varchar](50) NULL,
        [NAA_RESULT] [varchar](50) NULL,
        [NAA_SPEC_IS_SPUTUM_IND] [varchar](50) NULL,
        [NAA_SPEC_NOT_SPUTUM] [varchar](50) NULL,
        [NAA_RPT_LAB_TY] [varchar](50) NULL,
        [CHEST_XRAY_RESULT] [varchar](50) NULL,
        [CHEST_XRAY_CAVITY_EVIDENCE] [varchar](50) NULL,
        [CHEST_XRAY_MILIARY_EVIDENCE] [varchar](50) NULL,
        [CT_SCAN_RESULT] [varchar](50) NULL,
        [CT_SCAN_CAVITY_EVIDENCE] [varchar](50) NULL,
        [CT_SCAN_MILIARY_EVIDENCE] [varchar](50) NULL,
        [TST_RESULT] [varchar](50) NULL,
        [IGRA_RESULT] [varchar](50) NULL,
        [PRIMARY_REASON_EVALUATED] [varchar](50) NULL,
        [HOMELESS_IND] [varchar](50) NULL,
        [CORRECTIONAL_FACIL_RESIDENT] [varchar](50) NULL,
        [CORRECTIONAL_FACIL_TY] [varchar](50) NULL,
        [CORRECTIONAL_FACIL_CUSTODY_IND] [varchar](50) NULL,
        [LONGTERM_CARE_FACIL_RESIDENT] [varchar](50) NULL,
        [LONGTERM_CARE_FACIL_TY] [varchar](50) NULL,
        [OCCUPATION_RISK] [varchar](50) NULL,
        [INJECT_DRUG_USE_PAST_YEAR] [varchar](50) NULL,
        [NONINJECT_DRUG_USE_PAST_YEAR] [varchar](50) NULL,
        [ADDL_RISK_1] [varchar](50) NULL,
        [EXCESS_ALCOHOL_USE_PAST_YEAR] [varchar](50) NULL,
        [ADDL_RISK_2] [varchar](50) NULL,
        [ADDL_RISK_GT3_IND] [varchar](50) NULL,
        [ADDL_RISK_3] [varchar](50) NULL,
        [ADDL_RISK_ALL] [varchar](4000) NULL,
        [IMMIGRATION_STATUS_AT_US_ENTRY] [varchar](50) NULL,
        [INIT_REGIMEN_ISONIAZID] [varchar](50) NULL,
        [INIT_REGIMEN_RIFAMPIN] [varchar](50) NULL,
        [INIT_REGIMEN_PYRAZINAMIDE] [varchar](50) NULL,
        [INIT_REGIMEN_ETHAMBUTOL] [varchar](50) NULL,
        [INIT_REGIMEN_STREPTOMYCIN] [varchar](50) NULL,
        [INIT_REGIMEN_ETHIONAMIDE] [varchar](50) NULL,
        [INIT_REGIMEN_KANAMYCIN] [varchar](50) NULL,
        [INIT_REGIMEN_CYCLOSERINE] [varchar](50) NULL,
        [INIT_REGIMEN_CAPREOMYCIN] [varchar](50) NULL,
        [INIT_REGIMEN_PA_SALICYLIC_ACID] [varchar](50) NULL,
        [INIT_REGIMEN_AMIKACIN] [varchar](50) NULL,
        [INIT_REGIMEN_RIFABUTIN] [varchar](50) NULL,
        [INIT_REGIMEN_CIPROFLOXACIN] [varchar](50) NULL,
        [INIT_REGIMEN_OFLOXACIN] [varchar](50) NULL,
        [INIT_REGIMEN_RIFAPENTINE] [varchar](50) NULL,
        [INIT_REGIMEN_LEVOFLOXACIN] [varchar](50) NULL,
        [INIT_REGIMEN_MOXIFLOXACIN] [varchar](50) NULL,
        [INIT_REGIMEN_OTHER_1_IND] [varchar](50) NULL,
        [INIT_REGIMEN_OTHER_2_IND] [varchar](50) NULL,
        [ISOLATE_SUBMITTED_IND] [varchar](50) NULL,
        [INIT_SUSCEPT_TESTING_DONE] [varchar](50) NULL,
        [FIRST_ISOLATE_IS_SPUTUM_IND] [varchar](50) NULL,
        [FIRST_ISOLATE_NOT_SPUTUM] [varchar](50) NULL,
        [INIT_SUSCEPT_ISONIAZID] [varchar](50) NULL,
        [INIT_SUSCEPT_RIFAMPIN] [varchar](50) NULL,
        [INIT_SUSCEPT_PYRAZINAMIDE] [varchar](50) NULL,
        [INIT_SUSCEPT_ETHAMBUTOL] [varchar](50) NULL,
        [INIT_SUSCEPT_STREPTOMYCIN] [varchar](50) NULL,
        [INIT_SUSCEPT_ETHIONAMIDE] [varchar](50) NULL,
        [INIT_SUSCEPT_KANAMYCIN] [varchar](50) NULL,
        [INIT_SUSCEPT_CYCLOSERINE] [varchar](50) NULL,
        [INIT_SUSCEPT_CAPREOMYCIN] [varchar](50) NULL,
        [INIT_SUSCEPT_PA_SALICYLIC_ACID] [varchar](50) NULL,
        [INIT_SUSCEPT_AMIKACIN] [varchar](50) NULL,
        [INIT_SUSCEPT_RIFABUTIN] [varchar](50) NULL,
        [INIT_SUSCEPT_CIPROFLOXACIN] [varchar](50) NULL,
        [INIT_SUSCEPT_OFLOXACIN] [varchar](50) NULL,
        [INIT_SUSCEPT_RIFAPENTINE] [varchar](50) NULL,
        [INIT_SUSCEPT_LEVOFLOXACIN] [varchar](50) NULL,
        [INIT_SUSCEPT_MOXIFLOXACIN] [varchar](50) NULL,
        [INIT_SUSCEPT_OTHER_QUNINOLONES] [varchar](50) NULL,
        [INIT_SUSCEPT_OTHER_1_IND] [varchar](50) NULL,
        [INIT_SUSCEPT_OTHER_2_IND] [varchar](50) NULL,
        [SPUTUM_CULTURE_CONV_DOCUMENTED] [varchar](50) NULL,
        [NO_CONV_DOC_REASON] [varchar](50) NULL,
        [MOVED_WHERE_1] [varchar](50) NULL,
        [MOVED_IND] [varchar](100) NULL,
        [MOVED_WHERE_2] [varchar](50) NULL,
        [MOVED_WHERE_GT3_IND] [varchar](50) NULL,
        [MOVED_WHERE_3] [varchar](50) NULL,
        [MOVED_WHERE_ALL] [varchar](4000) NULL,
        [MOVE_CITY] [varchar](100) NULL,
        [MOVE_CNTY_1] [varchar](50) NULL,
        [MOVE_CNTY_2] [varchar](50) NULL,
        [MOVE_CNTY_GT3_IND] [varchar](50) NULL,
        [MOVE_CNTY_3] [varchar](50) NULL,
        [MOVE_STATE_1] [varchar](50) NULL,
        [MOVE_CNTY_ALL] [varchar](4000) NULL,
        [MOVE_STATE_2] [varchar](50) NULL,
        [MOVE_STATE_GT3_IND] [varchar](50) NULL,
        [MOVE_STATE_3] [varchar](50) NULL,
        [MOVE_CNTRY_1] [varchar](50) NULL,
        [MOVE_STATE_ALL] [varchar](4000) NULL,
        [MOVE_CNTRY_2] [varchar](50) NULL,
        [MOVE_CNTRY_GT3_IND] [varchar](50) NULL,
        [MOVE_CNTRY_3] [varchar](50) NULL,
        [MOVE_CNTRY_ALL] [varchar](4000) NULL,
        [TRANSNATIONAL_REFERRAL_IND] [varchar](50) NULL,
        [THERAPY_STOP_REASON] [varchar](50) NULL,
        [GT_12_REAS_1] [varchar](50) NULL,
        [THERAPY_STOP_CAUSE_OF_DEATH] [varchar](50) NULL,
        [GT_12_REAS_2] [varchar](50) NULL,
        [GT_12_REAS_GT3_IND] [varchar](50) NULL,
        [GT_12_REAS_3] [varchar](50) NULL,
        [GT_12_REAS_ALL] [varchar](4000) NULL,
        [HC_PROV_TY_1] [varchar](50) NULL,
        [HC_PROV_TY_2] [varchar](50) NULL,
        [HC_PROV_TY_GT3_IND] [varchar](50) NULL,
        [HC_PROV_TY_3] [varchar](50) NULL,
        [HC_PROV_TY_ALL] [varchar](4000) NULL,
        [DOT] [varchar](50) NULL,
        [FINAL_SUSCEPT_TESTING] [varchar](50) NULL,
        [FINAL_ISOLATE_IS_SPUTUM_IND] [varchar](50) NULL,
        [FINAL_ISOLATE_NOT_SPUTUM] [varchar](50) NULL,
        [FINAL_SUSCEPT_ISONIAZID] [varchar](50) NULL,
        [FINAL_SUSCEPT_RIFAMPIN] [varchar](50) NULL,
        [FINAL_SUSCEPT_PYRAZINAMIDE] [varchar](50) NULL,
        [FINAL_SUSCEPT_ETHAMBUTOL] [varchar](50) NULL,
        [FINAL_SUSCEPT_STREPTOMYCIN] [varchar](50) NULL,
        [FINAL_SUSCEPT_ETHIONAMIDE] [varchar](50) NULL,
        [FINAL_SUSCEPT_KANAMYCIN] [varchar](50) NULL,
        [FINAL_SUSCEPT_CYCLOSERINE] [varchar](50) NULL,
        [FINAL_SUSCEPT_CAPREOMYCIN] [varchar](50) NULL,
        [FINAL_SUSCEPT_PA_SALICYLIC_ACI] [varchar](50) NULL,
        [FINAL_SUSCEPT_AMIKACIN] [varchar](50) NULL,
        [FINAL_SUSCEPT_RIFABUTIN] [varchar](50) NULL,
        [FINAL_SUSCEPT_CIPROFLOXACIN] [varchar](50) NULL,
        [FINAL_SUSCEPT_OFLOXACIN] [varchar](50) NULL,
        [FINAL_SUSCEPT_RIFAPENTINE] [varchar](50) NULL,
        [FINAL_SUSCEPT_LEVOFLOXACIN] [varchar](50) NULL,
        [FINAL_SUSCEPT_MOXIFLOXACIN] [varchar](50) NULL,
        [FINAL_SUSCEPT_OTHER_QUINOLONES] [varchar](50) NULL,
        [FINAL_SUSCEPT_OTHER_IND] [varchar](50) NULL,
        [FINAL_SUSCEPT_OTHER_2_IND] [varchar](50) NULL,
        [CASE_VERIFICATION] [varchar](50) NULL,
        [CASE_STATUS] [varchar](50) NULL,
        [COUNT_STATUS] [varchar](50) NULL,
        [COUNTRY_OF_VERIFIED_CASE] [varchar](50) NULL,
        [NOTIFICATION_STATUS] [varchar](50) NULL,
        [NOTIFICATION_SENT_DATE] [datetime] NULL,
        [PATIENT_DOB] [datetime] NULL,
        [PATIENT_DECEASED_DATE] [datetime] NULL,
        [INVESTIGATION_START_DATE] [datetime] NULL,
        [INVESTIGATOR_ASSIGN_DATE] [datetime] NULL,
        [DATE_REPORTED] [datetime] NULL,
        [DATE_SUBMITTED] [datetime] NULL,
        [PREVIOUS_DIAGNOSIS_YEAR] [numeric](18, 0) NULL,
        [DATE_ARRIVED_IN_US] [datetime] NULL,
        [INVESTIGATION_DEATH_DATE] [datetime] NULL,
        [SPUTUM_SMEAR_COLLECT_DATE] [datetime] NULL,
        [SPUTUM_CULT_COLLECT_DATE] [datetime] NULL,
        [SPUTUM_CULT_RESULT_RPT_DATE] [datetime] NULL,
        [SMR_PATH_CYTO_COLLECT_DATE] [datetime] NULL,
        [CULT_TISSUE_COLLECT_DATE] [datetime] NULL,
        [CULT_TISSUE_RESULT_RPT_DATE] [datetime] NULL,
        [NAA_COLLECT_DATE] [datetime] NULL,
        [NAA_RESULT_RPT_DATE] [datetime] NULL,
        [TST_PLACED_DATE] [datetime] NULL,
        [IGRA_COLLECT_DATE] [datetime] NULL,
        [INIT_REGIMEN_START_DATE] [datetime] NULL,
        [FIRST_ISOLATE_COLLECT_DATE] [datetime] NULL,
        [TB_SPUTUM_CULTURE_NEGATIVE_DAT] [datetime] NULL,
        [THERAPY_STOP_DATE] [datetime] NULL,
        [FINAL_ISOLATE_COLLECT_DATE] [datetime] NULL,
        [COUNT_DATE] [datetime] NULL,
        [INVESTIGATION_CREATE_DATE] [datetime] NULL,
        [INVESTIGATION_LAST_UPDTD_DATE] [datetime] NULL,
        [INVESTIGATION_KEY] [bigint] NOT NULL,
        [CALC_REPORTED_AGE] [numeric](18, 0) NULL,
        [PATIENT_PHONE_EXT_HOME] [varchar](50) NULL,
        [PATIENT_PHONE_EXT_WORK] [varchar](50) NULL,
        [AGE_REPORTED] [numeric](18, 0) NULL,
        [TST_MM_INDURATION] [numeric](18, 0) NULL,
        [DOT_NUMBER_WEEKS] [numeric](18, 0) NULL,
        [MMWR_WEEK] [numeric](18, 0) NULL,
        [MMWR_YEAR] [numeric](18, 0) NULL,
        [PROGRAM_JURISDICTION_OID] [bigint] NULL,
        [PATIENT_LOCAL_ID] [varchar](50) NULL,
        [INVESTIGATION_LOCAL_ID] [varchar](50) NULL,
        [PATIENT_GENERAL_COMMENTS] [varchar](2000) NULL,
        [PATIENT_FIRST_NAME] [varchar](50) NULL,
        [PATIENT_MIDDLE_NAME] [varchar](50) NULL,
        [PATIENT_LAST_NAME] [varchar](50) NULL,
        [PATIENT_STREET_ADDRESS_1] [varchar](50) NULL,
        [PATIENT_STREET_ADDRESS_2] [varchar](50) NULL,
        [PATIENT_CITY] [varchar](50) NULL,
        [PATIENT_ZIP] [varchar](50) NULL,
        [PATIENT_PHONE_NUMBER_HOME] [varchar](50) NULL,
        [PATIENT_PHONE_NUMBER_WORK] [varchar](50) NULL,
        [PATIENT_SSN] [varchar](50) NULL,
        [INVESTIGATOR_FIRST_NAME] [varchar](50) NULL,
        [INVESTIGATOR_LAST_NAME] [varchar](50) NULL,
        [INVESTIGATOR_PHONE_NUMBER] [varchar](50) NULL,
        [STATE_CASE_NUMBER] [varchar](50) NULL,
        [CITY_COUNTY_CASE_NUMBER] [varchar](50) NULL,
        [LINK_STATE_CASE_NUM_1] [varchar](50) NULL,
        [LINK_STATE_CASE_NUM_2] [varchar](50) NULL,
        [IGRA_TEST_TY] [varchar](50) NULL,
        [OTHER_TB_RISK_FACTORS] [varchar](50) NULL,
        [INIT_REGIMEN_OTHER_1] [varchar](50) NULL,
        [INIT_REGIMEN_OTHER_2] [varchar](50) NULL,
        [GENERAL_COMMENTS] [varchar](2000) NULL,
        [ISOLATE_ACCESSION_NUM] [varchar](50) NULL,
        [INIT_SUSCEPT_OTHER_1] [varchar](50) NULL,
        [INIT_SUSCEPT_OTHER_2] [varchar](50) NULL,
        [COMMENTS_FOLLOW_UP_1] [varchar](2000) NULL,
        [NO_CONV_DOC_OTHER_REASON] [varchar](50) NULL,
        [MOVE_CITY_2] [varchar](50) NULL,
        [THERAPY_EXTEND_GT_12_OTHER] [varchar](50) NULL,
        [FINAL_SUSCEPT_OTHER] [varchar](50) NULL,
        [FINAL_SUSCEPT_OTHER_2] [varchar](50) NULL,
        [COMMENTS_FOLLOW_UP_2] [varchar](2000) NULL,
        [DIE_FRM_THIS_ILLNESS_IND] [varchar](50) NULL,
        [PROVIDER_OVERRIDE_COMMENTS] [varchar](2000) NULL,
        [INVESTIGATION_CREATED_BY] [varchar](50) NULL,
        [INVESTIGATION_LAST_UPDTD_BY] [varchar](50) NULL,
        [NOTIFICATION_LOCAL_ID] [varchar](50) NULL,
        [NOTIFICATION_SUBMITTER] [varchar](50) NULL,
        [INIT_DRUG_REG_CALC] [varchar](200) NULL,
        [REPORTER_PHONE_NUMBER] [varchar](50) NULL,
        [REPORTING_SOURCE_NAME] [varchar](50) NULL,
        [REPORTING_SOURCE_TYPE] [varchar](50) NULL,
        [REPORTER_FIRST_NAME] [varchar](50) NULL,
        [REPORTER_LAST_NAME] [varchar](50) NULL,
        [PHYSICIAN_FIRST_NAME] [varchar](50) NULL,
        [PHYSICIAN_LAST_NAME] [varchar](50) NULL,
        [PHYSICIAN_PHONE_NUMBER] [varchar](50) NULL,
        [HOSPITALIZED] [varchar](50) NULL,
        [HOSPITAL_NAME] [varchar](50) NULL,
        [HOSPITALIZED_ADMISSION_DATE] [datetime] NULL,
        [HOSPITALIZED_DISCHARGE_DATE] [datetime] NULL,
        [HOSPITALIZED_DURATION_DAYS] [numeric](18, 0) NULL,
        [DIAGNOSIS_DATE] [datetime] NULL,
        [ILLNESS_ONSET_DATE] [datetime] NULL,
        [ILLNESS_ONSET_AGE] [numeric](18, 0) NULL,
        [ILLNESS_ONSET_AGE_UNIT] [varchar](50) NULL,
        [ILLNESS_END_DATE] [datetime] NULL,
        [ILLNESS_DURATION] [numeric](18, 0) NULL,
        [ILLNESS_DURATION_UNIT] [varchar](50) NULL,
        [PREGNANT] [varchar](50) NULL,
        [DAYCARE] [varchar](50) NULL,
        [FOOD_HANDLER] [varchar](50) NULL,
        [DISEASE_ACQUIRED_WHERE] [varchar](50) NULL,
        [DISEASE_ACQUIRED_COUNTRY] [varchar](50) NULL,
        [DISEASE_ACQUIRED_STATE] [varchar](50) NULL,
        [DISEASE_ACQUIRED_CITY] [varchar](100) NULL,
        [DISEASE_ACQUIRED_COUNTY] [varchar](50) NULL,
        [TRANSMISSION_MODE] [varchar](50) NULL,
        [DETECTION_METHOD] [varchar](50) NULL,
        [OUTBREAK] [varchar](50) NULL,
        [OUTBREAK_NAME] [varchar](100) NULL,
        [CONFIRMATION_METHOD_1] [varchar](50) NULL,
        [CONFIRMATION_METHOD_2] [varchar](50) NULL,
        [CONFIRMATION_METHOD_3] [varchar](50) NULL,
        [CONFIRMATION_METHOD_ALL] [varchar](4000) NULL,
        [CONFIRMATION_DATE] [datetime] NULL,
        [CONFIRMATION_METHOD_GT3_IND] [varchar](2000) NULL,
        [DATE_REPORTED_TO_COUNTY] [datetime] NULL
    ) ON [PRIMARY]
END