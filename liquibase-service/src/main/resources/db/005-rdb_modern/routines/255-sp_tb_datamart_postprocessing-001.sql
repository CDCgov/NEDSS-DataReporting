IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_tb_datamart_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_tb_datamart_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_tb_datamart_postprocessing]
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
	DECLARE @Dataflow_Name VARCHAR(200) = 'TB_DATAMART POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_tb_datamart_postprocessing';

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

                
        --------------------------------------------------------------------------------------------------------
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING S_INVESTIGATION_LIST TABLE';
          
        IF OBJECT_ID('#S_INVESTIGATION_LIST', 'U') IS NOT NULL
            DROP TABLE #S_INVESTIGATION_LIST;

        SELECT DISTINCT
            TRIM(i.value) as TB_PAM_UID,
            inv.INVESTIGATION_KEY
        INTO  #S_INVESTIGATION_LIST
        FROM STRING_SPLIT(@phc_id_list, ',') i
        INNER JOIN [dbo].INVESTIGATION inv WITH (NOLOCK)
            ON inv.CASE_UID = i.value
        WHERE UPPER(inv.RECORD_STATUS_CD) = 'ACTIVE';
        
        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #S_INVESTIGATION_LIST;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
            
        --------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING S_INVESTIGATION_LIST_DEL TABLE';
          
        IF OBJECT_ID('#S_INVESTIGATION_LIST_DEL', 'U') IS NOT NULL
            DROP TABLE #S_INVESTIGATION_LIST_DEL;

        SELECT DISTINCT
            TRIM(i.value) as TB_PAM_UID,
            inv.INVESTIGATION_KEY
        INTO  #S_INVESTIGATION_LIST_DEL
        FROM STRING_SPLIT(@phc_id_list, ',') i
        INNER JOIN [dbo].INVESTIGATION inv WITH (NOLOCK)
            ON inv.CASE_UID = i.value
        WHERE UPPER(inv.RECORD_STATUS_CD) = 'INACTIVE';

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #S_INVESTIGATION_LIST_DEL;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
            
        --------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #PATIENT TABLE';
          
        IF OBJECT_ID('#PATIENT', 'U') IS NOT NULL
            DROP TABLE #PATIENT;

        -- 1. Create #PATIENT temporary table
        SELECT DISTINCT
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
            p.PATIENT_BIRTH_SEX AS PATIENT_BIRTH_SEX,
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
            p.PATIENT_RACE_NAT_HI_ALL AS RACE_NAT_HI_ALL
        INTO #PATIENT
        FROM [dbo].F_TB_PAM f WITH (NOLOCK)
        LEFT JOIN [dbo].D_PATIENT p WITH (NOLOCK)
            ON p.PATIENT_KEY = f.PERSON_KEY
        INNER JOIN #S_INVESTIGATION_LIST S
            ON S.INVESTIGATION_KEY = f.INVESTIGATION_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #S_INVESTIGATION_LIST_DEL;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #PROVIDER TABLE';
          
        IF OBJECT_ID('#PROVIDER', 'U') IS NOT NULL
            DROP TABLE #PROVIDER;

        -- 2. Create #PROVIDER temporary table
        SELECT DISTINCT
            f.PERSON_KEY,
            p.PROVIDER_LAST_NAME AS INVESTIGATOR_LAST_NAME,
            p.PROVIDER_FIRST_NAME AS INVESTIGATOR_FIRST_NAME,
            p.PROVIDER_PHONE_WORK AS INVESTIGATOR_PHONE_NUMBER,
            f.PROVIDER_KEY
        INTO #PROVIDER
        FROM [dbo].F_TB_PAM f WITH (NOLOCK)
        LEFT JOIN [dbo].D_PROVIDER p WITH (NOLOCK)
            ON p.PROVIDER_KEY = f.PROVIDER_KEY
        INNER JOIN #S_INVESTIGATION_LIST S
            ON S.INVESTIGATION_KEY = f.INVESTIGATION_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #PROVIDER;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #PHYSICIAN TABLE';
          
        IF OBJECT_ID('#PHYSICIAN', 'U') IS NOT NULL
            DROP TABLE #PHYSICIAN;

        -- 3. Create #PHYSICIAN temporary table
        SELECT DISTINCT
            f.PERSON_KEY,
            p.PROVIDER_LAST_NAME AS PHYSICIAN_LAST_NAME,
            p.PROVIDER_FIRST_NAME AS PHYSICIAN_FIRST_NAME, 
            p.PROVIDER_PHONE_WORK AS PHYSICIAN_PHONE_NUMBER,
            f.PHYSICIAN_KEY
        INTO #PHYSICIAN    
        FROM [dbo].F_TB_PAM f WITH (NOLOCK)
        LEFT JOIN [dbo].D_PROVIDER p WITH (NOLOCK)
            ON p.PROVIDER_KEY = f.PHYSICIAN_KEY
        INNER JOIN #S_INVESTIGATION_LIST S
            ON S.INVESTIGATION_KEY = f.INVESTIGATION_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #PHYSICIAN;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        -------------------------------------------------------------------------------------------------------- 

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #REPORTER TABLE';
          
        IF OBJECT_ID('#REPORTER', 'U') IS NOT NULL
            DROP TABLE #REPORTER;

        -- 4. Create #REPORTER temporary table
        SELECT DISTINCT
            f.PERSON_KEY,
            r.PROVIDER_LAST_NAME AS REPORTER_LAST_NAME,
            r.PROVIDER_FIRST_NAME AS REPORTER_FIRST_NAME,
            f.PERSON_AS_REPORTER_KEY,
            r.PROVIDER_PHONE_WORK AS REPORTER_PHONE_NUMBER
        INTO #REPORTER
        FROM [dbo].F_TB_PAM f WITH (NOLOCK)
        LEFT JOIN [dbo].D_PROVIDER r WITH (NOLOCK)
            ON r.PROVIDER_KEY = f.PERSON_AS_REPORTER_KEY
        INNER JOIN #S_INVESTIGATION_LIST S
            ON S.INVESTIGATION_KEY = f.INVESTIGATION_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #REPORTER;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        -------------------------------------------------------------------------------------------------------- 

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #ORG_REPORTER TABLE';
          
        IF OBJECT_ID('#ORG_REPORTER', 'U') IS NOT NULL
            DROP TABLE #ORG_REPORTER;

        -- 5. Create #ORG_REPORTER temporary table
        SELECT DISTINCT
            f.PERSON_KEY,
            o.ORGANIZATION_NAME AS REPORTING_SOURCE_NAME,
            f.ORG_AS_REPORTER_KEY
        INTO #ORG_REPORTER
        FROM [dbo].F_TB_PAM f WITH (NOLOCK)
        LEFT JOIN [dbo].D_ORGANIZATION o WITH (NOLOCK)
            ON o.ORGANIZATION_KEY = f.ORG_AS_REPORTER_KEY
        INNER JOIN #S_INVESTIGATION_LIST S
            ON S.INVESTIGATION_KEY = f.INVESTIGATION_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #ORG_REPORTER;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        -------------------------------------------------------------------------------------------------------- 

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #HOSPITAL TABLE';
          
        IF OBJECT_ID('#HOSPITAL', 'U') IS NOT NULL
            DROP TABLE #HOSPITAL;

        -- 6. Create #HOSPITAL temporary table
        SELECT DISTINCT
            f.PERSON_KEY,
            o.ORGANIZATION_NAME AS HOSPITAL_NAME,
            f.HOSPITAL_KEY
        INTO #HOSPITAL
        FROM [dbo].F_TB_PAM f WITH (NOLOCK)
        LEFT JOIN [dbo].D_ORGANIZATION o WITH (NOLOCK)
            ON o.ORGANIZATION_KEY = f.HOSPITAL_KEY
        INNER JOIN #S_INVESTIGATION_LIST S
            ON S.INVESTIGATION_KEY = f.INVESTIGATION_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #HOSPITAL;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        -------------------------------------------------------------------------------------------------------- 

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #ENTITY_LOCATION TABLE';
          
        IF OBJECT_ID('#ENTITY_LOCATION', 'U') IS NOT NULL
            DROP TABLE #ENTITY_LOCATION;

        -- 7. Create #ENTITY_LOCATION temporary table
        SELECT DISTINCT
            p.AGE_REPORTED,
            p.AGE_REPORTED_UNIT,
            h.HOSPITAL_KEY,
            h.HOSPITAL_NAME,
            pr.INVESTIGATOR_FIRST_NAME,
            pr.INVESTIGATOR_LAST_NAME,
            pr.INVESTIGATOR_PHONE_NUMBER,
            p.PATIENT_BIRTH_SEX,
            p.PATIENT_CITY,
            p.PATIENT_COUNTRY,
            p.PATIENT_COUNTY,
            p.PATIENT_CURRENT_SEX,
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
            p.PATIENT_WITHIN_CITY_LIMITS,
            p.PATIENT_ZIP,
            r.PERSON_AS_REPORTER_KEY,
            p.PERSON_KEY,
            ph.PHYSICIAN_FIRST_NAME,
            ph.PHYSICIAN_KEY,
            ph.PHYSICIAN_LAST_NAME,
            ph.PHYSICIAN_PHONE_NUMBER,
            pr.PROVIDER_KEY,
            p.RACE_ASIAN_1,
            p.RACE_ASIAN_2,
            p.RACE_ASIAN_3,
            p.RACE_ASIAN_ALL,
            p.RACE_ASIAN_GT3_IND,
            p.RACE_CALCULATED,
            p.RACE_CALC_DETAILS,
            p.RACE_NAT_HI_1,
            p.RACE_NAT_HI_2,
            p.RACE_NAT_HI_3,
            p.RACE_NAT_HI_ALL,
            p.RACE_NAT_HI_GT3_IND,
            r.REPORTER_FIRST_NAME,
            r.REPORTER_LAST_NAME,
            r.REPORTER_PHONE_NUMBER,
            o.REPORTING_SOURCE_NAME
        INTO #ENTITY_LOCATION
        FROM #PATIENT p
        INNER JOIN #PROVIDER pr ON pr.PERSON_KEY = p.PERSON_KEY
        INNER JOIN #PHYSICIAN ph ON ph.PERSON_KEY = p.PERSON_KEY
        INNER JOIN #REPORTER r ON r.PERSON_KEY = p.PERSON_KEY
        INNER JOIN #ORG_REPORTER o ON p.PERSON_KEY = o.PERSON_KEY
        INNER JOIN #HOSPITAL h ON p.PERSON_KEY = h.PERSON_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #ENTITY_LOCATION;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        -------------------------------------------------------------------------------------------------------- 

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #BASE_TRANSLATED TABLE';
          
        IF OBJECT_ID('#BASE_TRANSLATED', 'U') IS NOT NULL
            DROP TABLE #BASE_TRANSLATED;

        -- 8. Create #BASE_TRANSLATED temporary table
        SELECT 
            i.ADD_TIME                      AS INVESTIGATION_CREATE_DATE,
            i.ADD_USER_ID                   AS INVESTIGATION_CREATED_BY,
            i.LAST_CHG_USER_ID              AS INVESTIGATION_LAST_UPDTD_BY,
            i.LAST_CHG_TIME                 AS INVESTIGATION_LAST_UPDTD_DATE,
            i.PROGRAM_AREA_DESCRIPTION,
            i.LOCAL_ID                      AS INVESTIGATION_LOCAL_ID,
            inv.CASE_OID                    AS PROGRAM_JURISDICTION_OID,
            inv.CASE_RPT_MMWR_WK            AS MMWR_WEEK,
            inv.CASE_RPT_MMWR_YR            AS MMWR_YEAR,
            inv.INV_COMMENTS                AS GENERAL_COMMENTS,
            inv.INV_STATE_CASE_ID           AS STATE_CASE_NUMBER,
            inv.CITY_COUNTY_CASE_NBR        AS city_county_case_number,
            inv.INV_START_DT                AS INVESTIGATION_START_DATE,
            inv.INVESTIGATION_key           AS INVESTIGATION_KEY,
            inv.INVESTIGATION_STATUS        AS INVESTIGATION_STATUS,
            inv.INV_CASE_STATUS             AS CASE_STATUS,
            inv.JURISDICTION_NM             AS JURISDICTION_NAME,
            inv.CITY_COUNTY_CASE_NBR        AS CITY_COUNTY_CASE_NBR,
            inv.Inv_Rpt_Dt                  AS DATE_REPORTED,
            inv.Earliest_Rpt_To_State_Dt    AS DATE_SUBMITTED,
            inv.HSPTLIZD_IND                AS HOSPITALIZED,
            inv.HSPTL_ADMISSION_DT          AS HOSPITALIZED_ADMISSION_DATE,
            inv.HSPTL_DISCHARGE_DT          AS HOSPITALIZED_DISCHARGE_DATE,
            inv.HSPTL_DURATION_DAYS         AS HOSPITALIZED_DURATION_DAYS,
            inv.ILLNESS_ONSET_DT            AS ILLNESS_ONSET_DATE,
            inv.DIAGNOSIS_DT                AS DIAGNOSIS_DATE,
            inv.EARLIEST_RPT_TO_CNTY_DT     AS DATE_REPORTED_TO_COUNTY,
            inv.OUTBREAK_IND                AS OUTBREAK,
            inv.OUTBREAK_NAME               AS OUTBREAK_CD,
            inv.INV_ASSIGNED_DT             AS INVESTIGATOR_ASSIGN_DATE,
            inv.PATIENT_AGE_AT_ONSET_UNIT   AS ILLNESS_ONSET_AGE_UNIT,
            inv.PATIENT_AGE_AT_ONSET        AS ILLNESS_ONSET_AGE,
            inv.PATIENT_PREGNANT_IND        AS PREGNANT,
            inv.INVESTIGATION_DEATH_DATE    AS INVESTIGATION_DEATH_DATE,
            inv.DIE_FRM_THIS_ILLNESS_IND    AS DIE_FRM_THIS_ILLNESS_IND,
            inv.ILLNESS_END_DT              AS ILLNESS_END_DATE,
            inv.ILLNESS_DURATION            AS ILLNESS_DURATION,
            inv.ILLNESS_DURATION_UNIT       AS ILLNESS_DURATION_UNIT,
            inv.DAYCARE_ASSOCIATION_IND     AS DAYCARE,
            inv.FOOD_HANDLR_IND             AS FOOD_HANDLER,
            inv.DISEASE_IMPORTED_IND        AS DISEASE_ACQUIRED_WHERE,
            inv.IMPORT_FRM_CNTRY            AS DISEASE_ACQUIRED_COUNTRY,
            inv.IMPORT_FRM_STATE            AS DISEASE_ACQUIRED_STATE,
            inv.IMPORT_FRM_CITY             AS DISEASE_ACQUIRED_CITY,
            inv.IMPORT_FRM_CNTY             AS DISEASE_ACQUIRED_COUNTY,
            inv.TRANSMISSION_MODE           AS TRANSMISSION_MODE,
            inv.DETECTION_METHOD_DESC_TXT   AS DETECTION_METHOD,
            inv.RPT_SRC_CD_DESC             AS REPORTING_SOURCE_TYPE,
            --t.*,
            t.D_TB_PAM_KEY,
            t.TB_PAM_UID,
            t.CALC_DISEASE_SITE,
            t.LINK_STATE_CASE_NUM_1,
            t.LINK_REASON_1,
            t.LINK_STATE_CASE_NUM_2,
            t.LINK_REASON_2,
            t.COUNT_STATUS,
            t.COUNTRY_OF_VERIFIED_CASE,
            t.COUNT_DATE,
            t.PREVIOUS_DIAGNOSIS_IND,
            t.PREVIOUS_DIAGNOSIS_YEAR,
            t.PATIENT_OUTSIDE_US_GT_2_MONTHS,
            t.PRIMARY_GUARD_1_BIRTH_COUNTRY,
            t.PRIMARY_GUARD_2_BIRTH_COUNTRY,
            t.STATUS_AT_DIAGNOSIS,
            t.DISEASE_SITE,
            t.SPUTUM_SMEAR_RESULT,
            t.SPUTUM_SMEAR_COLLECT_DATE,
            t.SPUTUM_CULTURE_RESULT,
            t.SPUTUM_CULT_COLLECT_DATE,
            t.SPUTUM_CULT_RESULT_RPT_DATE,
            t.SPUTUM_CULT_RPT_LAB_TY,
            t.SMR_PATH_CYTO_RESULT,
            t.SMR_PATH_CYTO_COLLECT_DATE,
            t.SMR_PATH_CYTO_SITE,
            t.CULT_TISSUE_RESULT,
            t.CULT_TISSUE_COLLECT_DATE,
            t.CULT_TISSUE_SITE,
            t.CULT_TISSUE_RESULT_RPT_DATE,
            t.CULT_TISSUE_RESULT_RPT_LAB_TY,
            t.NAA_RESULT,
            t.NAA_COLLECT_DATE,
            t.NAA_SPEC_IS_SPUTUM_IND,
            t.NAA_SPEC_NOT_SPUTUM,
            t.NAA_RESULT_RPT_DATE,
            t.NAA_RPT_LAB_TY,
            t.CHEST_XRAY_RESULT,
            t.CHEST_XRAY_CAVITY_EVIDENCE,
            t.CHEST_XRAY_MILIARY_EVIDENCE,
            t.CT_SCAN_RESULT,
            t.CT_SCAN_CAVITY_EVIDENCE,
            t.CT_SCAN_MILIARY_EVIDENCE,
            t.TST_RESULT,
            t.TST_PLACED_DATE,
            t.TST_MM_INDURATION,
            t.IGRA_RESULT,
            t.IGRA_COLLECT_DATE,
            t.IGRA_TEST_TY,
            t.PRIMARY_REASON_EVALUATED,
            t.HIV_STATUS,
            t.HIV_STATE_PATIENT_NUM,
            t.HIV_CITY_CNTY_PATIENT_NUM,
            t.HOMELESS_IND,
            t.CORRECTIONAL_FACIL_RESIDENT,
            t.CORRECTIONAL_FACIL_TY,
            t.CORRECTIONAL_FACIL_CUSTODY_IND,
            t.LONGTERM_CARE_FACIL_RESIDENT,
            t.LONGTERM_CARE_FACIL_TY,
            t.OCCUPATION_RISK,
            t.INJECT_DRUG_USE_PAST_YEAR,
            t.NONINJECT_DRUG_USE_PAST_YEAR,
            t.EXCESS_ALCOHOL_USE_PAST_YEAR,
            t.OTHER_TB_RISK_FACTORS,
            t.IMMIGRATION_STATUS_AT_US_ENTRY,
            t.INIT_REGIMEN_START_DATE,
            t.INIT_REGIMEN_ISONIAZID,
            t.INIT_REGIMEN_RIFAMPIN,
            t.INIT_REGIMEN_PYRAZINAMIDE,
            t.INIT_REGIMEN_ETHAMBUTOL,
            t.INIT_REGIMEN_STREPTOMYCIN,
            t.INIT_REGIMEN_ETHIONAMIDE,
            t.INIT_REGIMEN_KANAMYCIN,
            t.INIT_REGIMEN_CYCLOSERINE,
            t.INIT_REGIMEN_CAPREOMYCIN,
            t.INIT_REGIMEN_PA_SALICYLIC_ACID,
            t.INIT_REGIMEN_AMIKACIN,
            t.INIT_REGIMEN_RIFABUTIN,
            t.INIT_REGIMEN_CIPROFLOXACIN,
            t.INIT_REGIMEN_OFLOXACIN,
            t.INIT_REGIMEN_RIFAPENTINE,
            t.INIT_REGIMEN_LEVOFLOXACIN,
            t.INIT_REGIMEN_MOXIFLOXACIN,
            t.INIT_REGIMEN_OTHER_1_IND,
            t.INIT_REGIMEN_OTHER_1,
            t.INIT_REGIMEN_OTHER_2_IND,
            t.INIT_REGIMEN_OTHER_2,
            t.ISOLATE_SUBMITTED_IND,
            t.ISOLATE_ACCESSION_NUM,
            t.INIT_SUSCEPT_TESTING_DONE,
            t.FIRST_ISOLATE_COLLECT_DATE,
            t.FIRST_ISOLATE_IS_SPUTUM_IND,
            t.FIRST_ISOLATE_NOT_SPUTUM,
            t.INIT_SUSCEPT_ISONIAZID,
            t.INIT_SUSCEPT_RIFAMPIN,
            t.INIT_SUSCEPT_PYRAZINAMIDE,
            t.INIT_SUSCEPT_ETHAMBUTOL,
            t.INIT_SUSCEPT_STREPTOMYCIN,
            t.INIT_SUSCEPT_ETHIONAMIDE,
            t.INIT_SUSCEPT_KANAMYCIN,
            t.INIT_SUSCEPT_CYCLOSERINE,
            t.INIT_SUSCEPT_CAPREOMYCIN,
            t.INIT_SUSCEPT_PA_SALICYLIC_ACID,
            t.INIT_SUSCEPT_AMIKACIN,
            t.INIT_SUSCEPT_RIFABUTIN,
            t.INIT_SUSCEPT_CIPROFLOXACIN,
            t.INIT_SUSCEPT_OFLOXACIN,
            t.INIT_SUSCEPT_RIFAPENTINE,
            t.INIT_SUSCEPT_LEVOFLOXACIN,
            t.INIT_SUSCEPT_MOXIFLOXACIN,
            t.INIT_SUSCEPT_OTHER_QUNINOLONES,
            t.INIT_SUSCEPT_OTHER_1_IND,
            t.INIT_SUSCEPT_OTHER_1,
            t.INIT_SUSCEPT_OTHER_2_IND,
            t.INIT_SUSCEPT_OTHER_2,
            t.SPUTUM_CULTURE_CONV_DOCUMENTED,
            t.TB_SPUTUM_CULTURE_NEGATIVE_DAT,
            t.NO_CONV_DOC_REASON,
            t.NO_CONV_DOC_OTHER_REASON,
            t.MOVED_IND,
            t.TRANSNATIONAL_REFERRAL_IND,
            t.MOVE_CITY,
            t.THERAPY_STOP_DATE,
            t.THERAPY_STOP_REASON,
            t.THERAPY_STOP_CAUSE_OF_DEATH,
            t.THERAPY_EXTEND_GT_12_OTHER,
            t.DOT,
            t.DOT_NUMBER_WEEKS,
            t.FINAL_SUSCEPT_TESTING,
            t.FINAL_ISOLATE_COLLECT_DATE,
            t.FINAL_ISOLATE_IS_SPUTUM_IND,
            t.FINAL_ISOLATE_NOT_SPUTUM,
            t.FINAL_SUSCEPT_ISONIAZID,
            t.FINAL_SUSCEPT_RIFAMPIN,
            t.FINAL_SUSCEPT_PYRAZINAMIDE,
            t.FINAL_SUSCEPT_ETHAMBUTOL,
            t.FINAL_SUSCEPT_STREPTOMYCIN,
            t.FINAL_SUSCEPT_ETHIONAMIDE,
            t.FINAL_SUSCEPT_KANAMYCIN,
            t.FINAL_SUSCEPT_CYCLOSERINE,
            t.FINAL_SUSCEPT_CAPREOMYCIN,
            t.FINAL_SUSCEPT_PA_SALICYLIC_ACI,
            t.FINAL_SUSCEPT_AMIKACIN,
            t.FINAL_SUSCEPT_RIFABUTIN,
            t.FINAL_SUSCEPT_CIPROFLOXACIN,
            t.FINAL_SUSCEPT_OFLOXACIN,
            t.FINAL_SUSCEPT_RIFAPENTINE,
            t.FINAL_SUSCEPT_LEVOFLOXACIN,
            t.FINAL_SUSCEPT_MOXIFLOXACIN,
            t.FINAL_SUSCEPT_OTHER_QUINOLONES,
            t.FINAL_SUSCEPT_OTHER_IND,
            t.FINAL_SUSCEPT_OTHER,
            t.FINAL_SUSCEPT_OTHER_2_IND,
            t.FINAL_SUSCEPT_OTHER_2,
            t.CASE_VERIFICATION,
            t.COMMENTS_FOLLOW_UP_1,
            t.COMMENTS_FOLLOW_UP_2,
            t.MOVE_CITY_2,
            t.DATE_ARRIVED_IN_US,
            t.PATIENT_BIRTH_COUNTRY,
            t.US_BORN_IND,
            t.TB_VERCRIT_CALC_IND,
            t.PROVIDER_OVERRIDE_COMMENTS,
            t.INIT_DRUG_REG_CALC,
            t.LAST_CHG_TIME,
            -- t.* end
            -- f.*
            f.PROVIDER_KEY,  
            f.D_MOVE_STATE_GROUP_KEY,
            f.D_HC_PROV_TY_3_GROUP_KEY,
            f.D_DISEASE_SITE_GROUP_KEY,
            f.D_ADDL_RISK_GROUP_KEY,
            f.D_MOVE_CNTY_GROUP_KEY,
            f.D_GT_12_REAS_GROUP_KEY,
            f.D_MOVE_CNTRY_GROUP_KEY,
            f.D_MOVED_WHERE_GROUP_KEY,
            f.D_SMR_EXAM_TY_GROUP_KEY,
            f.D_OUT_OF_CNTRY_GROUP_KEY,
            f.PERSON_KEY,
            -- f.* end
            cvg.CODE,
            cvg.CODE_SHORT_DESC_TXT AS OUTBREAK_NAME 
        INTO #BASE_TRANSLATED
        FROM [dbo].F_TB_PAM f WITH (NOLOCK)
        LEFT JOIN [dbo].D_TB_PAM t WITH (NOLOCK)
            ON f.D_TB_PAM_KEY = t.D_TB_PAM_KEY
        LEFT JOIN [dbo].INVESTIGATION inv WITH (NOLOCK)
            ON t.TB_PAM_UID = inv.CASE_UID
        LEFT JOIN [dbo].nrt_investigation i WITH (NOLOCK) 
            ON i.public_health_case_uid = t.TB_PAM_UID 
        LEFT JOIN [dbo].nrt_srte_Code_value_general cvg WITH (NOLOCK)
            ON cvg.CODE = inv.OUTBREAK_NAME AND cvg.CODE_SET_NM = 'OUTBREAK_NM'
        INNER JOIN #S_INVESTIGATION_LIST S
            ON S.INVESTIGATION_KEY = f.INVESTIGATION_KEY

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #BASE_TRANSLATED;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        -------------------------------------------------------------------------------------------------------- 

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #INIT TABLE';
          
        IF OBJECT_ID('#INIT', 'U') IS NOT NULL
            DROP TABLE #INIT;

        -- 9. Create #INIT temporary table with age calculations
        ;WITH AgeCalc AS (
            SELECT 
                bt.*, 
                --el.*  (except PERSON_KEY, PROVIDER_KEY),
                el.AGE_REPORTED,
                el.AGE_REPORTED_UNIT,
                el.HOSPITAL_KEY,
                el.HOSPITAL_NAME,
                el.INVESTIGATOR_FIRST_NAME,
                el.INVESTIGATOR_LAST_NAME,
                el.INVESTIGATOR_PHONE_NUMBER,
                el.PATIENT_BIRTH_SEX,
                el.PATIENT_CITY,
                el.PATIENT_COUNTRY,
                el.PATIENT_COUNTY,
                el.PATIENT_CURRENT_SEX,
                el.PATIENT_DECEASED_DATE,
                el.PATIENT_DECEASED_INDICATOR,
                el.PATIENT_DOB,
                el.PATIENT_ETHNICITY,
                el.PATIENT_FIRST_NAME,
                el.PATIENT_GENERAL_COMMENTS,
                el.PATIENT_LAST_NAME,
                el.PATIENT_LOCAL_ID,
                el.PATIENT_MARITAL_STATUS,
                el.PATIENT_MIDDLE_NAME,
                el.PATIENT_NAME_SUFFIX,
                el.PATIENT_PHONE_EXT_HOME,
                el.PATIENT_PHONE_EXT_WORK,
                el.PATIENT_PHONE_NUMBER_HOME,
                el.PATIENT_PHONE_NUMBER_WORK,
                el.PATIENT_SSN,
                el.PATIENT_STATE,
                el.PATIENT_STREET_ADDRESS_1,
                el.PATIENT_STREET_ADDRESS_2,
                el.PATIENT_WITHIN_CITY_LIMITS,
                el.PATIENT_ZIP,
                el.PERSON_AS_REPORTER_KEY,
                el.PHYSICIAN_FIRST_NAME,
                el.PHYSICIAN_KEY,
                el.PHYSICIAN_LAST_NAME,
                el.PHYSICIAN_PHONE_NUMBER,
                el.RACE_ASIAN_1,
                el.RACE_ASIAN_2,
                el.RACE_ASIAN_3,
                el.RACE_ASIAN_ALL,
                el.RACE_ASIAN_GT3_IND,
                el.RACE_CALCULATED,
                el.RACE_CALC_DETAILS,
                el.RACE_NAT_HI_1,
                el.RACE_NAT_HI_2,
                el.RACE_NAT_HI_3,
                el.RACE_NAT_HI_ALL,
                el.RACE_NAT_HI_GT3_IND,
                el.REPORTER_FIRST_NAME,
                el.REPORTER_LAST_NAME,
                el.REPORTER_PHONE_NUMBER,
                el.REPORTING_SOURCE_NAME,
                CAST(el.PATIENT_DOB AS DATE) AS PAT_DOB,
                CAST(bt.DATE_REPORTED AS DATE) AS RPT_TIME,
                CASE 
                    WHEN el.PATIENT_DOB IS NOT NULL AND bt.DATE_REPORTED IS NOT NULL 
                    THEN DATEDIFF(day, el.PATIENT_DOB, bt.DATE_REPORTED) / 365.25 
                    ELSE NULL 
                END AS AGE_IN_DEC
            FROM #BASE_TRANSLATED bt
            LEFT JOIN #ENTITY_LOCATION el   
                ON el.PERSON_KEY = bt.PERSON_KEY
        )
        SELECT DISTINCT
            *,
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
        INTO #INIT  
        FROM AgeCalc;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #INIT;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        -------------------------------------------------------------------------------------------------------- 

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #GT_12_REAS_OUT TABLE';
          
        IF OBJECT_ID('#GT_12_REAS_OUT', 'U') IS NOT NULL
            DROP TABLE #GT_12_REAS_OUT;

        -- 10. Create #GT_12_REAS_OUT temporary table
        ;WITH Ranked AS (
            SELECT 
                D_GT_12_REAS_GROUP_KEY,
                value,
                ROW_NUMBER() OVER (PARTITION BY D_GT_12_REAS_GROUP_KEY ORDER BY value) AS rn
            FROM [dbo].D_GT_12_REAS D WITH (NOLOCK) 
            INNER JOIN #S_INVESTIGATION_LIST S 
                ON S.TB_PAM_UID = D.TB_PAM_UID
        )
        SELECT 
            D_GT_12_REAS_GROUP_KEY,
            STRING_AGG(value, ' | ') WITHIN GROUP (ORDER BY value) AS GT_12_REAS_ALL,  
            NULLIF(MAX(CASE WHEN rn = 1 THEN value ELSE '' END),'') AS GT_12_REAS_1,  
            NULLIF(MAX(CASE WHEN rn = 2 THEN value ELSE '' END),'') AS GT_12_REAS_2,  
            NULLIF(MAX(CASE WHEN rn = 3 THEN value ELSE '' END),'') AS GT_12_REAS_3,  
            NULLIF(MAX(CASE WHEN rn = 4 THEN value ELSE '' END),'') AS GT_12_REAS_4,  
            CASE 
                WHEN MAX(CASE WHEN rn = 4 THEN value ELSE '' END) > '' 
                THEN 'TRUE' 
                ELSE 'FALSE' 
            END AS GT_12_REAS_GT3_IND  
        INTO #GT_12_REAS_OUT  
        FROM Ranked
        GROUP BY D_GT_12_REAS_GROUP_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #GT_12_REAS_OUT;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #SMR_EXAM_TY_OUT TABLE';
          
        IF OBJECT_ID('#SMR_EXAM_TY_OUT', 'U') IS NOT NULL
            DROP TABLE #SMR_EXAM_TY_OUT;

        -- 11. Create #SMR_EXAM_TY_OUT temporary table
        ;WITH Ranked AS (
            SELECT 
                D_SMR_EXAM_TY_GROUP_KEY,
                value,
                ROW_NUMBER() OVER (PARTITION BY D_SMR_EXAM_TY_GROUP_KEY ORDER BY value) AS rn
            FROM [dbo].D_SMR_EXAM_TY D WITH (NOLOCK)
            INNER JOIN #S_INVESTIGATION_LIST S 
                ON S.TB_PAM_UID = D.TB_PAM_UID
        )
        SELECT 
            D_SMR_EXAM_TY_GROUP_KEY,
            STRING_AGG(value, ' | ') WITHIN GROUP (ORDER BY value) AS SMR_EXAM_TY_ALL,
            NULLIF(MAX(CASE WHEN rn = 1 THEN value ELSE '' END),'') AS SMR_EXAM_TY_1,
            NULLIF(MAX(CASE WHEN rn = 2 THEN value ELSE '' END),'') AS SMR_EXAM_TY_2,
            NULLIF(MAX(CASE WHEN rn = 3 THEN value ELSE '' END),'') AS SMR_EXAM_TY_3,
            NULLIF(MAX(CASE WHEN rn = 4 THEN value ELSE '' END),'') AS SMR_EXAM_TY_4,
            CASE 
                WHEN MAX(CASE WHEN rn = 4 THEN value ELSE '' END) > '' 
                THEN 'TRUE' 
                ELSE 'FALSE' 
            END AS SMR_EXAM_TY_GT3_IND
        INTO #SMR_EXAM_TY_OUT  
        FROM  Ranked
        GROUP BY D_SMR_EXAM_TY_GROUP_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #SMR_EXAM_TY_OUT;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------
        
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #ADDL_RISK_OUT TABLE';
          
        IF OBJECT_ID('#ADDL_RISK_OUT', 'U') IS NOT NULL
            DROP TABLE #ADDL_RISK_OUT;

        -- 12. Create #ADDL_RISK_OUT temporary table
        WITH Ranked AS (
            SELECT 
                D_ADDL_RISK_GROUP_KEY,
                value,
                ROW_NUMBER() OVER (PARTITION BY D_ADDL_RISK_GROUP_KEY ORDER BY value) AS rn
            FROM [dbo].D_ADDL_RISK D WITH (NOLOCK)
            INNER JOIN #S_INVESTIGATION_LIST S 
                ON S.TB_PAM_UID = D.TB_PAM_UID
        )
        SELECT 
            D_ADDL_RISK_GROUP_KEY,
            STRING_AGG(value, ' | ') WITHIN GROUP (ORDER BY value) AS ADDL_RISK_ALL,  
            NULLIF(MAX(CASE WHEN rn = 1 THEN value ELSE '' END),'') AS ADDL_RISK_1,  
            NULLIF(MAX(CASE WHEN rn = 2 THEN value ELSE '' END),'') AS ADDL_RISK_2,  
            NULLIF(MAX(CASE WHEN rn = 3 THEN value ELSE '' END),'') AS ADDL_RISK_3,  
            NULLIF(MAX(CASE WHEN rn = 4 THEN value ELSE '' END),'') AS ADDL_RISK_4,  
            CASE 
                WHEN MAX(CASE WHEN rn = 4 THEN value ELSE '' END) > '' 
                THEN 'TRUE' 
                ELSE 'FALSE' 
            END AS ADDL_RISK_GT3_IND  
        INTO #ADDL_RISK_OUT  
        FROM Ranked
        GROUP BY D_ADDL_RISK_GROUP_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #ADDL_RISK_OUT;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #DISEASE_SITE_OUT TABLE';
          
        IF OBJECT_ID('#DISEASE_SITE_OUT', 'U') IS NOT NULL
            DROP TABLE #DISEASE_SITE_OUT;

        -- 13. Create #DISEASE_SITE_OUT temporary table
        WITH Ranked AS (
            SELECT 
                D_DISEASE_SITE_GROUP_KEY,
                value,
                ROW_NUMBER() OVER (PARTITION BY D_DISEASE_SITE_GROUP_KEY ORDER BY value) AS rn
            FROM [dbo].D_DISEASE_SITE D WITH (NOLOCK)
            INNER JOIN #S_INVESTIGATION_LIST S 
                ON S.TB_PAM_UID = D.TB_PAM_UID
        )
        SELECT 
            D_DISEASE_SITE_GROUP_KEY,
            STRING_AGG(value, ' | ') WITHIN GROUP (ORDER BY value) AS DISEASE_SITE_ALL,
            NULLIF(MAX(CASE WHEN rn = 1 THEN value ELSE '' END),'') AS DISEASE_SITE_1,
            NULLIF(MAX(CASE WHEN rn = 2 THEN value ELSE '' END),'') AS DISEASE_SITE_2,
            NULLIF(MAX(CASE WHEN rn = 3 THEN value ELSE '' END),'') AS DISEASE_SITE_3,
            NULLIF(MAX(CASE WHEN rn = 4 THEN value ELSE '' END),'') AS DISEASE_SITE_4,
            CASE 
                WHEN MAX(CASE WHEN rn = 4 THEN value ELSE '' END) > '' 
                THEN 'TRUE' 
                ELSE 'FALSE' 
            END AS DISEASE_SITE_GT3_IND
        INTO #DISEASE_SITE_OUT  
        FROM Ranked
        GROUP BY D_DISEASE_SITE_GROUP_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #DISEASE_SITE_OUT;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #HC_PROV_TY_3_OUT TABLE';
          
        IF OBJECT_ID('#HC_PROV_TY_3_OUT', 'U') IS NOT NULL
            DROP TABLE #HC_PROV_TY_3_OUT;

        -- 14. Create #HC_PROV_TY_3_OUT temporary table
        WITH Ranked AS (
            SELECT 
                D_HC_PROV_TY_3_GROUP_KEY,
                value,
                ROW_NUMBER() OVER (PARTITION BY D_HC_PROV_TY_3_GROUP_KEY ORDER BY value) AS rn
            FROM [dbo].D_HC_PROV_TY_3 D WITH (NOLOCK)
            INNER JOIN #S_INVESTIGATION_LIST S 
                ON S.TB_PAM_UID = D.TB_PAM_UID
        )
        SELECT 
            D_HC_PROV_TY_3_GROUP_KEY,
            STRING_AGG(value, ' | ') WITHIN GROUP (ORDER BY value) AS HC_PROV_TY_ALL,
            NULLIF(MAX(CASE WHEN rn = 1 THEN value ELSE '' END),'') AS HC_PROV_TY_1,
            NULLIF(MAX(CASE WHEN rn = 2 THEN value ELSE '' END),'') AS HC_PROV_TY_2,
            NULLIF(MAX(CASE WHEN rn = 3 THEN value ELSE '' END),'') AS HC_PROV_TY_3,
            NULLIF(MAX(CASE WHEN rn = 4 THEN value ELSE '' END),'') AS HC_PROV_TY_4,
            CASE 
                WHEN MAX(CASE WHEN rn = 4 THEN value ELSE '' END) > '' 
                THEN 'TRUE' 
                ELSE 'FALSE' 
            END AS HC_PROV_TY_GT3_IND
        INTO #HC_PROV_TY_3_OUT  
        FROM Ranked
        GROUP BY D_HC_PROV_TY_3_GROUP_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #HC_PROV_TY_3_OUT;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #MOVED_WHERE_OUT TABLE';
          
        IF OBJECT_ID('#MOVED_WHERE_OUT', 'U') IS NOT NULL
            DROP TABLE #MOVED_WHERE_OUT;

        -- 15. Create #MOVED_WHERE_OUT temporary table
        WITH Ranked AS (
            SELECT 
                D_MOVED_WHERE_GROUP_KEY,
                value,
                ROW_NUMBER() OVER (PARTITION BY D_MOVED_WHERE_GROUP_KEY ORDER BY value) AS rn
            FROM [dbo].D_MOVED_WHERE D WITH (NOLOCK)
            INNER JOIN #S_INVESTIGATION_LIST S 
                ON S.TB_PAM_UID = D.TB_PAM_UID
        )
        SELECT 
            D_MOVED_WHERE_GROUP_KEY,
            STRING_AGG(value, ' | ') WITHIN GROUP (ORDER BY value) AS MOVED_WHERE_ALL,
            NULLIF(MAX(CASE WHEN rn = 1 THEN value ELSE '' END),'') AS MOVED_WHERE_1,
            NULLIF(MAX(CASE WHEN rn = 2 THEN value ELSE '' END),'') AS MOVED_WHERE_2,
            NULLIF(MAX(CASE WHEN rn = 3 THEN value ELSE '' END),'') AS MOVED_WHERE_3,
            NULLIF(MAX(CASE WHEN rn = 4 THEN value ELSE '' END),'') AS MOVED_WHERE_4,
            CASE 
                WHEN MAX(CASE WHEN rn = 4 THEN value ELSE '' END) > '' 
                THEN 'TRUE' 
                ELSE 'FALSE' 
            END AS MOVED_WHERE_GT3_IND
        INTO #MOVED_WHERE_OUT  
        FROM Ranked
        GROUP BY D_MOVED_WHERE_GROUP_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #MOVED_WHERE_OUT;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------
        
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #OUT_OF_CNTRY_OUT TABLE';
          
        IF OBJECT_ID('#OUT_OF_CNTRY_OUT', 'U') IS NOT NULL
            DROP TABLE #OUT_OF_CNTRY_OUT;

        -- 16. Create #OUT_OF_CNTRY_OUT temporary table
        WITH Ranked AS (
            SELECT 
                D_OUT_OF_CNTRY_GROUP_KEY,
                value,
                ROW_NUMBER() OVER (PARTITION BY D_OUT_OF_CNTRY_GROUP_KEY ORDER BY value) AS rn
            FROM [dbo].D_OUT_OF_CNTRY D WITH (NOLOCK)
            INNER JOIN #S_INVESTIGATION_LIST S 
                ON S.TB_PAM_UID = D.TB_PAM_UID
        )
        SELECT 
            D_OUT_OF_CNTRY_GROUP_KEY,
            STRING_AGG(value, ' | ') WITHIN GROUP (ORDER BY value) AS OUT_OF_CNTRY_ALL,
            NULLIF(MAX(CASE WHEN rn = 1 THEN value ELSE '' END),'') AS OUT_OF_CNTRY_1,
            NULLIF(MAX(CASE WHEN rn = 2 THEN value ELSE '' END),'') AS OUT_OF_CNTRY_2,
            NULLIF(MAX(CASE WHEN rn = 3 THEN value ELSE '' END),'') AS OUT_OF_CNTRY_3,
            NULLIF(MAX(CASE WHEN rn = 4 THEN value ELSE '' END),'') AS OUT_OF_CNTRY_4,
            CASE 
                WHEN MAX(CASE WHEN rn = 4 THEN value ELSE '' END) > '' 
                THEN 'TRUE' 
                ELSE 'FALSE' 
            END AS OUT_OF_CNTRY_GT3_IND
        INTO #OUT_OF_CNTRY_OUT  
        FROM Ranked
        GROUP BY D_OUT_OF_CNTRY_GROUP_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #OUT_OF_CNTRY_OUT;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #MOVE_STATE_OUT TABLE';
          
        IF OBJECT_ID('#MOVE_STATE_OUT', 'U') IS NOT NULL
            DROP TABLE #MOVE_STATE_OUT;

        -- 17. Create #MOVE_STATE_OUT temporary table
        WITH Ranked AS (
            SELECT 
                D_MOVE_STATE_GROUP_KEY,
                value,
                ROW_NUMBER() OVER (PARTITION BY D_MOVE_STATE_GROUP_KEY ORDER BY value) AS rn
            FROM [dbo].D_MOVE_STATE D WITH (NOLOCK)
            INNER JOIN #S_INVESTIGATION_LIST S 
                ON S.TB_PAM_UID = D.TB_PAM_UID
        )
        SELECT 
            D_MOVE_STATE_GROUP_KEY,
            STRING_AGG(value, ' | ') WITHIN GROUP (ORDER BY value) AS MOVE_STATE_ALL,
            NULLIF(MAX(CASE WHEN rn = 1 THEN value ELSE '' END),'') AS MOVE_STATE_1,
            NULLIF(MAX(CASE WHEN rn = 2 THEN value ELSE '' END),'') AS MOVE_STATE_2,
            NULLIF(MAX(CASE WHEN rn = 3 THEN value ELSE '' END),'') AS MOVE_STATE_3,
            NULLIF(MAX(CASE WHEN rn = 4 THEN value ELSE '' END),'') AS MOVE_STATE_4,
            CASE 
                WHEN MAX(CASE WHEN rn = 4 THEN value ELSE '' END) > '' 
                THEN 'TRUE' 
                ELSE 'FALSE' 
            END AS MOVE_STATE_GT3_IND
        INTO #MOVE_STATE_OUT  
        FROM Ranked
        GROUP BY D_MOVE_STATE_GROUP_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #MOVE_STATE_OUT;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        --------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #MOVE_CNTRY_OUT TABLE';
          
        IF OBJECT_ID('#MOVE_CNTRY_OUT', 'U') IS NOT NULL
            DROP TABLE #MOVE_CNTRY_OUT;

        -- 18. Create #MOVE_CNTRY_OUT temporary table
        WITH Ranked AS (
            SELECT 
                D_MOVE_CNTRY_GROUP_KEY,
                value,
                ROW_NUMBER() OVER (PARTITION BY D_MOVE_CNTRY_GROUP_KEY ORDER BY value) AS rn
            FROM [dbo].D_MOVE_CNTRY D WITH (NOLOCK)
            INNER JOIN #S_INVESTIGATION_LIST S 
                ON S.TB_PAM_UID = D.TB_PAM_UID
        )
        SELECT 
            D_MOVE_CNTRY_GROUP_KEY,
            STRING_AGG(value, ' | ') WITHIN GROUP (ORDER BY value) AS MOVE_CNTRY_ALL,
            NULLIF(MAX(CASE WHEN rn = 1 THEN value ELSE '' END),'') AS MOVE_CNTRY_1,
            NULLIF(MAX(CASE WHEN rn = 2 THEN value ELSE '' END),'') AS MOVE_CNTRY_2,
            NULLIF(MAX(CASE WHEN rn = 3 THEN value ELSE '' END),'') AS MOVE_CNTRY_3,
            NULLIF(MAX(CASE WHEN rn = 4 THEN value ELSE '' END),'') AS MOVE_CNTRY_4,
            CASE 
                WHEN MAX(CASE WHEN rn = 4 THEN value ELSE '' END) > '' 
                THEN 'TRUE' 
                ELSE 'FALSE' 
            END AS MOVE_CNTRY_GT3_IND
        INTO #MOVE_CNTRY_OUT  
        FROM Ranked
        GROUP BY D_MOVE_CNTRY_GROUP_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #MOVE_CNTRY_OUT;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        --------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #MOVE_CNTY_OUT TABLE';
          
        IF OBJECT_ID('#MOVE_CNTY_OUT', 'U') IS NOT NULL
            DROP TABLE #MOVE_CNTY_OUT;

        -- 19. Create #MOVE_CNTY_OUT temporary table
        WITH Ranked AS (
            SELECT 
                D_MOVE_CNTY_GROUP_KEY,
                value,
                ROW_NUMBER() OVER (PARTITION BY D_MOVE_CNTY_GROUP_KEY ORDER BY value) AS rn
            FROM [dbo].D_MOVE_CNTY D WITH (NOLOCK)
            INNER JOIN #S_INVESTIGATION_LIST S 
                ON S.TB_PAM_UID = D.TB_PAM_UID
        )
        SELECT 
            D_MOVE_CNTY_GROUP_KEY,
            STRING_AGG(value, ' | ') WITHIN GROUP (ORDER BY value) AS MOVE_CNTY_ALL,  
            NULLIF(MAX(CASE WHEN rn = 1 THEN value ELSE '' END),'')  AS MOVE_CNTY_1,
            NULLIF(MAX(CASE WHEN rn = 2 THEN value ELSE '' END),'')  AS MOVE_CNTY_2,
            NULLIF(MAX(CASE WHEN rn = 3 THEN value ELSE '' END),'')  AS MOVE_CNTY_3,
            NULLIF(MAX(CASE WHEN rn = 4 THEN value ELSE '' END),'')  AS MOVE_CNTY_4,
            CASE 
                WHEN MAX(CASE WHEN rn = 4 THEN value ELSE '' END) > ''  
                THEN 'TRUE' 
                ELSE 'FALSE' 
            END AS MOVE_CNTY_GT3_IND
        INTO #MOVE_CNTY_OUT
        FROM Ranked
        GROUP BY D_MOVE_CNTY_GROUP_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #MOVE_CNTY_OUT;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        --------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CONFIRMATION_METHOD_OUT TABLE';
          
        IF OBJECT_ID('#CONFIRMATION_METHOD_OUT', 'U') IS NOT NULL
            DROP TABLE #CONFIRMATION_METHOD_OUT;

        -- 20. Create #CONFIRMATION_METHOD_OUT temporary table
        WITH ConfirmationMethod AS (
            SELECT 
                cm.*, 
                cmg.investigation_key, 
                cmg.confirmation_dt
            FROM [dbo].confirmation_method cm WITH (NOLOCK)
            INNER JOIN [dbo].confirmation_method_group cmg WITH (NOLOCK)
                ON cmg.confirmation_method_key = cm.confirmation_method_key
            INNER JOIN [dbo].investigation inv WITH (NOLOCK)
                ON cmg.investigation_key = inv.investigation_key
            INNER JOIN [dbo].f_tb_pam f WITH (NOLOCK)
                ON f.investigation_key = inv.investigation_key
            INNER JOIN #S_INVESTIGATION_LIST S 
                    ON S.INVESTIGATION_KEY = F.INVESTIGATION_KEY
            WHERE inv.record_status_cd = 'ACTIVE'
        ),
        Pivoted AS (
            SELECT 
                investigation_key, confirmation_dt,
                MAX(CASE WHEN rn = 1 THEN CONFIRMATION_METHOD_DESC END) AS COL1,
                MAX(CASE WHEN rn = 2 THEN CONFIRMATION_METHOD_DESC END) AS COL2,
                MAX(CASE WHEN rn = 3 THEN CONFIRMATION_METHOD_DESC END) AS COL3,
                MAX(CASE WHEN rn = 4 THEN CONFIRMATION_METHOD_DESC END) AS COL4,
                MAX(CASE WHEN rn = 5 THEN CONFIRMATION_METHOD_DESC END) AS COL5,
                MAX(CASE WHEN rn = 6 THEN CONFIRMATION_METHOD_DESC END) AS COL6,
                MAX(CASE WHEN rn = 7 THEN CONFIRMATION_METHOD_DESC END) AS COL7,
                MAX(CASE WHEN rn = 8 THEN CONFIRMATION_METHOD_DESC END) AS COL8,
                MAX(CASE WHEN rn = 9 THEN CONFIRMATION_METHOD_DESC END) AS COL9,
                MAX(CASE WHEN rn = 10 THEN CONFIRMATION_METHOD_DESC END) AS COL10,
                MAX(CASE WHEN rn = 11 THEN CONFIRMATION_METHOD_DESC END) AS COL11,
                MAX(CASE WHEN rn = 12 THEN CONFIRMATION_METHOD_DESC END) AS COL12,
                MAX(CASE WHEN rn = 13 THEN CONFIRMATION_METHOD_DESC END) AS COL13
            FROM (
                SELECT investigation_key, confirmation_dt, CONFIRMATION_METHOD_DESC,
                    ROW_NUMBER() OVER (PARTITION BY investigation_key ORDER BY CONFIRMATION_METHOD_DESC) AS rn
                FROM ConfirmationMethod
            ) AS Ranked
            GROUP BY investigation_key, confirmation_dt
        ),
        Processed AS (
            SELECT 
                investigation_key, confirmation_dt,
                CASE 
                    WHEN CHARINDEX(' | .', TRIM(' | ' FROM CONCAT_WS(' | ', COL1, COL2, COL3, COL4, COL5, COL6, COL7, COL8, COL9, COL10, COL11, COL12, COL13))) > 0
                    THEN LEFT(
                        TRIM(' | ' FROM CONCAT_WS(' | ', COL1, COL2, COL3, COL4, COL5, COL6, COL7, COL8, COL9, COL10, COL11, COL12, COL13)),
                        CHARINDEX(' | .', TRIM(' | ' FROM CONCAT_WS(' | ', COL1, COL2, COL3, COL4, COL5, COL6, COL7, COL8, COL9, COL10, COL11, COL12, COL13))) - 1
                    )
                    ELSE TRIM(' | ' FROM CONCAT_WS(' | ', COL1, COL2, COL3, COL4, COL5, COL6, COL7, COL8, COL9, COL10, COL11, COL12, COL13))
                END AS CONFIRMATION_METHOD_ALL,
                CASE WHEN LEN(COL1) > 2 THEN COL1 ELSE '' END AS CONFIRMATION_METHOD_1,
                CASE WHEN LEN(COL2) > 2 THEN COL2 ELSE '' END AS CONFIRMATION_METHOD_2,
                CASE WHEN LEN(COL3) > 2 THEN COL3 ELSE '' END AS CONFIRMATION_METHOD_3,
                CASE WHEN LEN(COL4) > 2 THEN COL4 ELSE '' END AS CONFIRMATION_METHOD_4,
                CASE WHEN LEN(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(UPPER(COL4), 'A', ''), 'B', ''), 'C', ''), 'D', ''), 
                    'E', ''), 'F', ''), 'G', ''), 'H', ''), 'I', ''), 'J', ''), 'K', ''), 'L', ''), 'M', ''), 
                    'N', ''), 'O', ''), 'P', ''), 'Q', ''), 'R', ''), 'S', ''), 'T', ''), 'U', ''), 'V', ''), 
                    'W', ''), 'X', ''), 'Y', ''), 'Z', '')
                ) > 2 THEN 'True' ELSE 'False' END AS CONFIRMATION_METHOD_GT3_IND
            FROM Pivoted
        )
        SELECT 
            NULLIF(CONFIRMATION_METHOD_1, '') AS CONFIRMATION_METHOD_1, 
            NULLIF(CONFIRMATION_METHOD_2, '') AS CONFIRMATION_METHOD_2, 
            NULLIF(CONFIRMATION_METHOD_3, '') AS CONFIRMATION_METHOD_3, 
            NULLIF(CONFIRMATION_METHOD_GT3_IND, '') AS CONFIRMATION_METHOD_GT3_IND,  
            NULLIF(CONFIRMATION_METHOD_ALL, '') AS CONFIRMATION_METHOD_ALL,  
            CONFIRMATION_DT,
            INVESTIGATION_KEY
        INTO #CONFIRMATION_METHOD_OUT  
        FROM Processed
        ORDER BY INVESTIGATION_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #CONFIRMATION_METHOD_OUT;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        --------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #TB_DATAMART_init TABLE';
          
        IF OBJECT_ID('#TB_DATAMART_init', 'U') IS NOT NULL
            DROP TABLE #TB_DATAMART_init;

        -- 21. Create #TB_DATAMART_init temporary table 
        SELECT 
            i.*,
            g.GT_12_REAS_1, g.GT_12_REAS_2, g.GT_12_REAS_3,
            s.SMR_EXAM_TY_1, s.SMR_EXAM_TY_2, s.SMR_EXAM_TY_3,
            a.ADDL_RISK_1, a.ADDL_RISK_2, a.ADDL_RISK_3,
            d.DISEASE_SITE_1, d.DISEASE_SITE_2, d.DISEASE_SITE_3,
            h.HC_PROV_TY_1, h.HC_PROV_TY_2, h.HC_PROV_TY_3,
            mw.MOVED_WHERE_1, mw.MOVED_WHERE_2, mw.MOVED_WHERE_3,
            oc.OUT_OF_CNTRY_1, oc.OUT_OF_CNTRY_2, oc.OUT_OF_CNTRY_3,
            ms.MOVE_STATE_1, ms.MOVE_STATE_2, ms.MOVE_STATE_3,
            mc.MOVE_CNTRY_1, mc.MOVE_CNTRY_2, mc.MOVE_CNTRY_3,
            mct.MOVE_CNTY_1, mct.MOVE_CNTY_2, mct.MOVE_CNTY_3,
            g.GT_12_REAS_GT3_IND, s.SMR_EXAM_TY_GT3_IND, a.ADDL_RISK_GT3_IND,
            d.DISEASE_SITE_GT3_IND, h.HC_PROV_TY_GT3_IND, mw.MOVED_WHERE_GT3_IND,
            oc.OUT_OF_CNTRY_GT3_IND, ms.MOVE_STATE_GT3_IND, mc.MOVE_CNTRY_GT3_IND, mct.MOVE_CNTY_GT3_IND,
            oc.OUT_OF_CNTRY_ALL, d.DISEASE_SITE_ALL, s.SMR_EXAM_TY_ALL, 
            a.ADDL_RISK_ALL, mct.MOVE_CNTY_ALL, ms.MOVE_STATE_ALL, 
            mc.MOVE_CNTRY_ALL, g.GT_12_REAS_ALL, h.HC_PROV_TY_ALL, mw.MOVED_WHERE_ALL,
            cm.CONFIRMATION_METHOD_1, cm.CONFIRMATION_METHOD_2, cm.CONFIRMATION_METHOD_3,
            cm.CONFIRMATION_METHOD_GT3_IND, cm.CONFIRMATION_METHOD_ALL,
            cm.CONFIRMATION_DT AS CONFIRMATION_DATE
        INTO #TB_DATAMART_init  
        FROM #INIT i
        LEFT JOIN #GT_12_REAS_OUT g
            ON i.D_GT_12_REAS_GROUP_KEY = g.D_GT_12_REAS_GROUP_KEY
        LEFT JOIN #SMR_EXAM_TY_OUT s
            ON i.D_SMR_EXAM_TY_GROUP_KEY = s.D_SMR_EXAM_TY_GROUP_KEY
        LEFT JOIN #ADDL_RISK_OUT a
            ON i.D_ADDL_RISK_GROUP_KEY = a.D_ADDL_RISK_GROUP_KEY
        LEFT JOIN #DISEASE_SITE_OUT d
            ON i.D_DISEASE_SITE_GROUP_KEY = d.D_DISEASE_SITE_GROUP_KEY
        LEFT JOIN #HC_PROV_TY_3_OUT h
            ON i.D_HC_PROV_TY_3_GROUP_KEY = h.D_HC_PROV_TY_3_GROUP_KEY
        LEFT JOIN #MOVED_WHERE_OUT mw
            ON i.D_MOVED_WHERE_GROUP_KEY = mw.D_MOVED_WHERE_GROUP_KEY
        LEFT JOIN #OUT_OF_CNTRY_OUT oc
            ON i.D_OUT_OF_CNTRY_GROUP_KEY = oc.D_OUT_OF_CNTRY_GROUP_KEY
        LEFT JOIN #MOVE_STATE_OUT ms
            ON i.D_MOVE_STATE_GROUP_KEY = ms.D_MOVE_STATE_GROUP_KEY
        LEFT JOIN #MOVE_CNTRY_OUT mc
            ON i.D_MOVE_CNTRY_GROUP_KEY = mc.D_MOVE_CNTRY_GROUP_KEY
        LEFT JOIN #MOVE_CNTY_OUT mct
            ON i.D_MOVE_CNTY_GROUP_KEY = mct.D_MOVE_CNTY_GROUP_KEY
        LEFT JOIN #CONFIRMATION_METHOD_OUT cm
            ON i.INVESTIGATION_KEY = cm.INVESTIGATION_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #TB_DATAMART_init;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        --------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #TB_DATAMART TABLE';
          
        IF OBJECT_ID('#TB_DATAMART', 'U') IS NOT NULL
            DROP TABLE #TB_DATAMART;

        -- 22. Create #TB_DATAMART temporary table 
        WITH BaseData AS (
            SELECT 
                tdi.*,
                invn.last_notification_send_date AS notification_sent_date, --(original) rd.date_mm_dd_yyyy AS notification_sent_date,
                n.NOTIFICATION_STATUS,
                n.NOTIFICATION_LOCAL_ID,
                nu.first_nm AS notif_first_nm,
                nu.last_nm AS notif_last_nm,
                cu.first_nm AS createUser_first_nm,
                cu.last_nm AS createUser_last_nm,
                eu.first_nm AS editUser_first_nm,
                eu.last_nm AS editUser_last_nm
            FROM #TB_DATAMART_init tdi
            LEFT JOIN [dbo].notification_event ne WITH(NOLOCK) 
                ON tdi.person_key = ne.patient_key
            LEFT JOIN [dbo].notification n WITH(NOLOCK) 
                ON ne.notification_key = n.notification_key
            LEFT JOIN [dbo].nrt_investigation_notification invn WITH(NOLOCK)  
                ON invn.public_health_case_uid = tdi.TB_PAM_UID     
            LEFT JOIN [dbo].user_profile nu WITH(NOLOCK) 
                ON n.notification_submitted_by = nu.NEDSS_ENTRY_ID
            LEFT JOIN [dbo].user_profile cu WITH(NOLOCK) 
                ON tdi.INVESTIGATION_CREATED_BY = cu.NEDSS_ENTRY_ID
            LEFT JOIN [dbo].user_profile eu WITH(NOLOCK) 
                ON tdi.INVESTIGATION_LAST_UPDTD_BY = eu.NEDSS_ENTRY_ID
        ),
        ProcessedData AS (
            SELECT 
                --[list all columns from TB_DATAMART_init except INVESTIGATION_CREATED_BY and INVESTIGATION_LAST_UPDTD_BY],
                CALC_5_YEAR_AGE_GROUP, CALC_10_YEAR_AGE_GROUP,         
                PATIENT_NAME_SUFFIX, PATIENT_STATE, PATIENT_COUNTY, PATIENT_COUNTRY, 
                PATIENT_WITHIN_CITY_LIMITS, AGE_REPORTED_UNIT, PATIENT_BIRTH_SEX, PATIENT_CURRENT_SEX, 
                PATIENT_DECEASED_INDICATOR, PATIENT_MARITAL_STATUS, PATIENT_ETHNICITY,
                RACE_CALCULATED, RACE_CALC_DETAILS, 
                RACE_ASIAN_1, RACE_ASIAN_2, RACE_ASIAN_3, RACE_ASIAN_GT3_IND, RACE_ASIAN_ALL,
                RACE_NAT_HI_1, RACE_NAT_HI_2, RACE_NAT_HI_3, RACE_NAT_HI_GT3_IND, RACE_NAT_HI_ALL,
                JURISDICTION_NAME,
                PROGRAM_AREA_DESCRIPTION,
                INVESTIGATION_STATUS,
                LINK_REASON_1, LINK_REASON_2,
                PREVIOUS_DIAGNOSIS_IND,
                US_BORN_IND,
                PATIENT_BIRTH_COUNTRY,
                PATIENT_OUTSIDE_US_GT_2_MONTHS,
                OUT_OF_CNTRY_1, OUT_OF_CNTRY_2, OUT_OF_CNTRY_3, OUT_OF_CNTRY_GT3_IND, OUT_OF_CNTRY_ALL,
                PRIMARY_GUARD_1_BIRTH_COUNTRY, PRIMARY_GUARD_2_BIRTH_COUNTRY, STATUS_AT_DIAGNOSIS,
                DISEASE_SITE_1, DISEASE_SITE_2, DISEASE_SITE_3, DISEASE_SITE_GT3_IND, DISEASE_SITE_ALL, CALC_DISEASE_SITE,
                SPUTUM_SMEAR_RESULT, SPUTUM_CULTURE_RESULT, SPUTUM_CULT_RPT_LAB_TY,
                SMR_PATH_CYTO_RESULT, SMR_PATH_CYTO_SITE,
                SMR_EXAM_TY_1, SMR_EXAM_TY_2, SMR_EXAM_TY_3, SMR_EXAM_TY_GT3_IND, SMR_EXAM_TY_ALL,
                CULT_TISSUE_RESULT, CULT_TISSUE_SITE, CULT_TISSUE_RESULT_RPT_LAB_TY,
                NAA_RESULT, NAA_SPEC_IS_SPUTUM_IND, NAA_SPEC_NOT_SPUTUM, NAA_RPT_LAB_TY,
                CHEST_XRAY_RESULT, CHEST_XRAY_CAVITY_EVIDENCE, CHEST_XRAY_MILIARY_EVIDENCE,
                CT_SCAN_RESULT, CT_SCAN_CAVITY_EVIDENCE, CT_SCAN_MILIARY_EVIDENCE,
                TST_RESULT,
                IGRA_RESULT,
                PRIMARY_REASON_EVALUATED,
                HOMELESS_IND,
                CORRECTIONAL_FACIL_RESIDENT, CORRECTIONAL_FACIL_TY, CORRECTIONAL_FACIL_CUSTODY_IND,
                LONGTERM_CARE_FACIL_RESIDENT, LONGTERM_CARE_FACIL_TY,
                OCCUPATION_RISK,
                INJECT_DRUG_USE_PAST_YEAR, NONINJECT_DRUG_USE_PAST_YEAR,
                EXCESS_ALCOHOL_USE_PAST_YEAR,
                ADDL_RISK_1, ADDL_RISK_2, ADDL_RISK_GT3_IND, ADDL_RISK_3, ADDL_RISK_ALL,
                IMMIGRATION_STATUS_AT_US_ENTRY,
                INIT_REGIMEN_ISONIAZID, INIT_REGIMEN_RIFAMPIN, INIT_REGIMEN_PYRAZINAMIDE, INIT_REGIMEN_ETHAMBUTOL,
                INIT_REGIMEN_STREPTOMYCIN, INIT_REGIMEN_ETHIONAMIDE, INIT_REGIMEN_KANAMYCIN, INIT_REGIMEN_CYCLOSERINE,
                INIT_REGIMEN_CAPREOMYCIN, INIT_REGIMEN_PA_SALICYLIC_ACID, INIT_REGIMEN_AMIKACIN, INIT_REGIMEN_RIFABUTIN,
                INIT_REGIMEN_CIPROFLOXACIN, INIT_REGIMEN_OFLOXACIN, INIT_REGIMEN_RIFAPENTINE, INIT_REGIMEN_LEVOFLOXACIN,
                INIT_REGIMEN_MOXIFLOXACIN, INIT_REGIMEN_OTHER_1_IND, INIT_REGIMEN_OTHER_2_IND, INIT_SUSCEPT_TESTING_DONE,
                ISOLATE_SUBMITTED_IND, FIRST_ISOLATE_IS_SPUTUM_IND, FIRST_ISOLATE_NOT_SPUTUM,
                INIT_SUSCEPT_ISONIAZID, INIT_SUSCEPT_RIFAMPIN, INIT_SUSCEPT_PYRAZINAMIDE, INIT_SUSCEPT_ETHAMBUTOL,
                INIT_SUSCEPT_STREPTOMYCIN, INIT_SUSCEPT_ETHIONAMIDE, INIT_SUSCEPT_KANAMYCIN, INIT_SUSCEPT_CYCLOSERINE,
                INIT_SUSCEPT_CAPREOMYCIN, INIT_SUSCEPT_PA_SALICYLIC_ACID, INIT_SUSCEPT_AMIKACIN, INIT_SUSCEPT_RIFABUTIN,
                INIT_SUSCEPT_CIPROFLOXACIN, INIT_SUSCEPT_OFLOXACIN, INIT_SUSCEPT_RIFAPENTINE, INIT_SUSCEPT_LEVOFLOXACIN,
                INIT_SUSCEPT_MOXIFLOXACIN, INIT_SUSCEPT_OTHER_QUNINOLONES, INIT_SUSCEPT_OTHER_1_IND, INIT_SUSCEPT_OTHER_2_IND,
                SPUTUM_CULTURE_CONV_DOCUMENTED, NO_CONV_DOC_REASON,
                MOVED_IND, 
                MOVE_CITY, MOVE_CITY_2,
                MOVED_WHERE_1, MOVED_WHERE_2,  MOVED_WHERE_3, MOVED_WHERE_GT3_IND, MOVED_WHERE_ALL,
                MOVE_CNTY_1, MOVE_CNTY_2, MOVE_CNTY_3, MOVE_CNTY_GT3_IND, MOVE_CNTY_ALL,
                MOVE_STATE_1, MOVE_STATE_2, MOVE_STATE_3, MOVE_STATE_GT3_IND, MOVE_STATE_ALL,
                MOVE_CNTRY_1, MOVE_CNTRY_2, MOVE_CNTRY_3, MOVE_CNTRY_GT3_IND, MOVE_CNTRY_ALL,
                TRANSNATIONAL_REFERRAL_IND, THERAPY_STOP_REASON, THERAPY_STOP_CAUSE_OF_DEATH,
                GT_12_REAS_1, GT_12_REAS_2, GT_12_REAS_3, GT_12_REAS_GT3_IND, GT_12_REAS_ALL,
                HC_PROV_TY_1, HC_PROV_TY_2, HC_PROV_TY_3, HC_PROV_TY_GT3_IND, HC_PROV_TY_ALL,
                DOT, FINAL_ISOLATE_IS_SPUTUM_IND, FINAL_ISOLATE_NOT_SPUTUM,
                FINAL_SUSCEPT_TESTING, FINAL_SUSCEPT_ISONIAZID, FINAL_SUSCEPT_RIFAMPIN, FINAL_SUSCEPT_PYRAZINAMIDE,
                FINAL_SUSCEPT_ETHAMBUTOL, FINAL_SUSCEPT_STREPTOMYCIN, FINAL_SUSCEPT_ETHIONAMIDE, FINAL_SUSCEPT_KANAMYCIN,
                FINAL_SUSCEPT_CYCLOSERINE, FINAL_SUSCEPT_CAPREOMYCIN, FINAL_SUSCEPT_PA_SALICYLIC_ACI, FINAL_SUSCEPT_AMIKACIN,
                FINAL_SUSCEPT_RIFABUTIN, FINAL_SUSCEPT_CIPROFLOXACIN, FINAL_SUSCEPT_OFLOXACIN, FINAL_SUSCEPT_RIFAPENTINE,
                FINAL_SUSCEPT_LEVOFLOXACIN, FINAL_SUSCEPT_MOXIFLOXACIN, FINAL_SUSCEPT_OTHER_QUINOLONES, FINAL_SUSCEPT_OTHER_IND,
                FINAL_SUSCEPT_OTHER_2_IND,
                CASE_VERIFICATION, CASE_STATUS,
                COUNT_STATUS, COUNTRY_OF_VERIFIED_CASE,
                NOTIFICATION_STATUS, NOTIFICATION_SENT_DATE,
                PATIENT_DOB, PATIENT_DECEASED_DATE,
                INVESTIGATION_START_DATE, INVESTIGATOR_ASSIGN_DATE, INVESTIGATION_DEATH_DATE,
                DATE_REPORTED, DATE_SUBMITTED, DATE_ARRIVED_IN_US,
                PREVIOUS_DIAGNOSIS_YEAR,
                SPUTUM_SMEAR_COLLECT_DATE, SPUTUM_CULT_COLLECT_DATE, SPUTUM_CULT_RESULT_RPT_DATE, SMR_PATH_CYTO_COLLECT_DATE,
                CULT_TISSUE_COLLECT_DATE, CULT_TISSUE_RESULT_RPT_DATE,
                NAA_COLLECT_DATE, NAA_RESULT_RPT_DATE,
                TST_PLACED_DATE, IGRA_COLLECT_DATE, INIT_REGIMEN_START_DATE,
                FIRST_ISOLATE_COLLECT_DATE, TB_SPUTUM_CULTURE_NEGATIVE_DAT,
                THERAPY_STOP_DATE, FINAL_ISOLATE_COLLECT_DATE, COUNT_DATE,       
                INVESTIGATION_CREATE_DATE, INVESTIGATION_LAST_UPDTD_DATE, INVESTIGATION_KEY, CALC_REPORTED_AGE,
                PATIENT_PHONE_EXT_HOME, PATIENT_PHONE_EXT_WORK, AGE_REPORTED,
                TST_MM_INDURATION, DOT_NUMBER_WEEKS,
                MMWR_WEEK, MMWR_YEAR, PROGRAM_JURISDICTION_OID, 
                PATIENT_LOCAL_ID, INVESTIGATION_LOCAL_ID,
                PATIENT_GENERAL_COMMENTS, PATIENT_FIRST_NAME, PATIENT_MIDDLE_NAME, PATIENT_LAST_NAME,
                PATIENT_STREET_ADDRESS_1, PATIENT_STREET_ADDRESS_2, PATIENT_CITY, PATIENT_ZIP,
                PATIENT_PHONE_NUMBER_HOME, PATIENT_PHONE_NUMBER_WORK, PATIENT_SSN,
                INVESTIGATOR_FIRST_NAME, INVESTIGATOR_LAST_NAME, INVESTIGATOR_PHONE_NUMBER,
                STATE_CASE_NUMBER, CITY_COUNTY_CASE_NUMBER, LINK_STATE_CASE_NUM_1, LINK_STATE_CASE_NUM_2,
                IGRA_TEST_TY, OTHER_TB_RISK_FACTORS,
                INIT_REGIMEN_OTHER_1, INIT_REGIMEN_OTHER_2,
                GENERAL_COMMENTS, ISOLATE_ACCESSION_NUM,
                INIT_SUSCEPT_OTHER_1, INIT_SUSCEPT_OTHER_2, COMMENTS_FOLLOW_UP_1, NO_CONV_DOC_OTHER_REASON,
                THERAPY_EXTEND_GT_12_OTHER, FINAL_SUSCEPT_OTHER, FINAL_SUSCEPT_OTHER_2, COMMENTS_FOLLOW_UP_2,
                DIE_FRM_THIS_ILLNESS_IND, PROVIDER_OVERRIDE_COMMENTS,
                NOTIFICATION_LOCAL_ID, INIT_DRUG_REG_CALC,
                REPORTER_PHONE_NUMBER, REPORTING_SOURCE_NAME, REPORTING_SOURCE_TYPE, REPORTER_FIRST_NAME, REPORTER_LAST_NAME,
                PHYSICIAN_FIRST_NAME, PHYSICIAN_LAST_NAME, PHYSICIAN_PHONE_NUMBER,
                HOSPITALIZED, HOSPITAL_NAME, HOSPITALIZED_ADMISSION_DATE, HOSPITALIZED_DISCHARGE_DATE, HOSPITALIZED_DURATION_DAYS,
                DIAGNOSIS_DATE, ILLNESS_ONSET_DATE, ILLNESS_ONSET_AGE, ILLNESS_ONSET_AGE_UNIT, ILLNESS_END_DATE, ILLNESS_DURATION, ILLNESS_DURATION_UNIT,
                PREGNANT, DAYCARE, FOOD_HANDLER,
                DISEASE_ACQUIRED_WHERE, DISEASE_ACQUIRED_COUNTRY, DISEASE_ACQUIRED_STATE, DISEASE_ACQUIRED_CITY, DISEASE_ACQUIRED_COUNTY,
                TRANSMISSION_MODE, DETECTION_METHOD, OUTBREAK, OUTBREAK_NAME,
                CONFIRMATION_METHOD_1, CONFIRMATION_METHOD_2, CONFIRMATION_METHOD_3, CONFIRMATION_METHOD_ALL, CONFIRMATION_DATE, CONFIRMATION_METHOD_GT3_IND,
                DATE_REPORTED_TO_COUNTY,        
                notif_first_nm,
                notif_last_nm,
                createUser_first_nm,
                createUser_last_nm,
                editUser_first_nm,
                editUser_last_nm,
                CASE 
                    WHEN LEN(TRIM(notif_first_nm)) > 0 AND LEN(TRIM(notif_last_nm)) > 0 
                        THEN TRIM(notif_last_nm) + ', ' + TRIM(notif_first_nm)
                    WHEN LEN(TRIM(notif_last_nm)) > 0 THEN TRIM(notif_last_nm)
                    WHEN LEN(TRIM(notif_first_nm)) > 0 THEN TRIM(notif_first_nm)
                    ELSE NULL
                END AS NOTIFICATION_SUBMITTER,
                CASE 
                    WHEN LEN(TRIM(createUser_first_nm)) > 0 AND LEN(TRIM(createUser_last_nm)) > 0 
                        THEN TRIM(createUser_last_nm) + ', ' + TRIM(createUser_first_nm)
                    WHEN LEN(TRIM(createUser_last_nm)) > 0 THEN TRIM(createUser_last_nm)
                    WHEN LEN(TRIM(createUser_first_nm)) > 0 THEN TRIM(createUser_first_nm)
                    ELSE NULL
                END AS INVESTIGATION_CREATED_BY,
                CASE 
                    WHEN LEN(TRIM(editUser_first_nm)) > 0 AND LEN(TRIM(editUser_last_nm)) > 0 
                        THEN TRIM(editUser_last_nm) + ', ' + TRIM(editUser_first_nm)
                    WHEN LEN(TRIM(editUser_last_nm)) > 0 THEN TRIM(editUser_last_nm)
                    WHEN LEN(TRIM(editUser_first_nm)) > 0 THEN TRIM(editUser_first_nm)
                    ELSE NULL
                END AS INVESTIGATION_LAST_UPDTD_BY
            FROM BaseData
        )
        SELECT *
        INTO #TB_DATAMART  
        FROM ProcessedData
        WHERE investigation_key > 0;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #TB_DATAMART;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES 
            (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        --------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION
        
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETE INCOMING ACTIVE RECORDS';

            -- 23. DELETE INCOMING ACTIVE RECORDS
            DELETE T
            FROM [dbo].TB_DATAMART T
            INNER JOIN #S_INVESTIGATION_LIST S 
                ON S.INVESTIGATION_KEY = T.INVESTIGATION_KEY;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #S_INVESTIGATION_LIST;

            INSERT INTO [dbo].[job_flow_log]
                (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES 
                (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            --------------------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETE INCOMING DELETED RECORDS';

            -- 24. DELETE DELETED RECORDS
            DELETE T
            FROM [dbo].TB_DATAMART T
            INNER JOIN #S_INVESTIGATION_LIST_DEL S 
                ON S.INVESTIGATION_KEY = T.INVESTIGATION_KEY;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #S_INVESTIGATION_LIST_DEL;

            INSERT INTO [dbo].[job_flow_log]
                (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES 
                (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        
            --------------------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERT INCOMING RECORDS';

            -- 25. INSERT INCOMING RECORDS
            INSERT INTO [dbo].TB_DATAMART (
                CALC_5_YEAR_AGE_GROUP,
                CALC_10_YEAR_AGE_GROUP,
                PATIENT_NAME_SUFFIX,
                PATIENT_STATE,
                PATIENT_COUNTY,
                PATIENT_COUNTRY,
                PATIENT_WITHIN_CITY_LIMITS,
                AGE_REPORTED_UNIT,
                PATIENT_BIRTH_SEX,
                PATIENT_CURRENT_SEX,
                PATIENT_DECEASED_INDICATOR,
                PATIENT_MARITAL_STATUS,
                PATIENT_ETHNICITY,
                RACE_CALCULATED,
                RACE_CALC_DETAILS,
                RACE_ASIAN_1,
                RACE_ASIAN_2,
                RACE_ASIAN_3,
                RACE_ASIAN_GT3_IND,
                RACE_ASIAN_ALL,
                RACE_NAT_HI_1,
                RACE_NAT_HI_2,
                RACE_NAT_HI_3,
                RACE_NAT_HI_GT3_IND,
                RACE_NAT_HI_ALL,
                JURISDICTION_NAME,
                PROGRAM_AREA_DESCRIPTION,
                INVESTIGATION_STATUS,
                LINK_REASON_1,
                LINK_REASON_2,
                PREVIOUS_DIAGNOSIS_IND,
                US_BORN_IND,
                PATIENT_BIRTH_COUNTRY,
                PATIENT_OUTSIDE_US_GT_2_MONTHS,
                OUT_OF_CNTRY_1,
                OUT_OF_CNTRY_2,
                OUT_OF_CNTRY_3,
                OUT_OF_CNTRY_GT3_IND,
                OUT_OF_CNTRY_ALL,
                PRIMARY_GUARD_1_BIRTH_COUNTRY,
                PRIMARY_GUARD_2_BIRTH_COUNTRY,
                STATUS_AT_DIAGNOSIS,
                DISEASE_SITE_1,
                DISEASE_SITE_2,
                DISEASE_SITE_3,
                DISEASE_SITE_GT3_IND,
                DISEASE_SITE_ALL,
                CALC_DISEASE_SITE,
                SPUTUM_SMEAR_RESULT,
                SPUTUM_CULTURE_RESULT,
                SPUTUM_CULT_RPT_LAB_TY,
                SMR_PATH_CYTO_RESULT,
                SMR_PATH_CYTO_SITE,
                SMR_EXAM_TY_1,
                SMR_EXAM_TY_2,
                SMR_EXAM_TY_3,
                SMR_EXAM_TY_GT3_IND,
                SMR_EXAM_TY_ALL,
                CULT_TISSUE_RESULT,
                CULT_TISSUE_SITE,
                CULT_TISSUE_RESULT_RPT_LAB_TY,
                NAA_RESULT,
                NAA_SPEC_IS_SPUTUM_IND,
                NAA_SPEC_NOT_SPUTUM,
                NAA_RPT_LAB_TY,
                CHEST_XRAY_RESULT,
                CHEST_XRAY_CAVITY_EVIDENCE,
                CHEST_XRAY_MILIARY_EVIDENCE,
                CT_SCAN_RESULT,
                CT_SCAN_CAVITY_EVIDENCE,
                CT_SCAN_MILIARY_EVIDENCE,
                TST_RESULT,
                IGRA_RESULT,
                PRIMARY_REASON_EVALUATED,
                HOMELESS_IND,
                CORRECTIONAL_FACIL_RESIDENT,
                CORRECTIONAL_FACIL_TY,
                CORRECTIONAL_FACIL_CUSTODY_IND,
                LONGTERM_CARE_FACIL_RESIDENT,
                LONGTERM_CARE_FACIL_TY,
                OCCUPATION_RISK,
                INJECT_DRUG_USE_PAST_YEAR,
                NONINJECT_DRUG_USE_PAST_YEAR,
                ADDL_RISK_1,
                EXCESS_ALCOHOL_USE_PAST_YEAR,
                ADDL_RISK_2,
                ADDL_RISK_GT3_IND,
                ADDL_RISK_3,
                ADDL_RISK_ALL,
                IMMIGRATION_STATUS_AT_US_ENTRY,
                INIT_REGIMEN_ISONIAZID,
                INIT_REGIMEN_RIFAMPIN,
                INIT_REGIMEN_PYRAZINAMIDE,
                INIT_REGIMEN_ETHAMBUTOL,
                INIT_REGIMEN_STREPTOMYCIN,
                INIT_REGIMEN_ETHIONAMIDE,
                INIT_REGIMEN_KANAMYCIN,
                INIT_REGIMEN_CYCLOSERINE,
                INIT_REGIMEN_CAPREOMYCIN,
                INIT_REGIMEN_PA_SALICYLIC_ACID,
                INIT_REGIMEN_AMIKACIN,
                INIT_REGIMEN_RIFABUTIN,
                INIT_REGIMEN_CIPROFLOXACIN,
                INIT_REGIMEN_OFLOXACIN,
                INIT_REGIMEN_RIFAPENTINE,
                INIT_REGIMEN_LEVOFLOXACIN,
                INIT_REGIMEN_MOXIFLOXACIN,
                INIT_REGIMEN_OTHER_1_IND,
                INIT_REGIMEN_OTHER_2_IND,
                ISOLATE_SUBMITTED_IND,
                INIT_SUSCEPT_TESTING_DONE,
                FIRST_ISOLATE_IS_SPUTUM_IND,
                FIRST_ISOLATE_NOT_SPUTUM,
                INIT_SUSCEPT_ISONIAZID,
                INIT_SUSCEPT_RIFAMPIN,
                INIT_SUSCEPT_PYRAZINAMIDE,
                INIT_SUSCEPT_ETHAMBUTOL,
                INIT_SUSCEPT_STREPTOMYCIN,
                INIT_SUSCEPT_ETHIONAMIDE,
                INIT_SUSCEPT_KANAMYCIN,
                INIT_SUSCEPT_CYCLOSERINE,
                INIT_SUSCEPT_CAPREOMYCIN,
                INIT_SUSCEPT_PA_SALICYLIC_ACID,
                INIT_SUSCEPT_AMIKACIN,
                INIT_SUSCEPT_RIFABUTIN,
                INIT_SUSCEPT_CIPROFLOXACIN,
                INIT_SUSCEPT_OFLOXACIN,
                INIT_SUSCEPT_RIFAPENTINE,
                INIT_SUSCEPT_LEVOFLOXACIN,
                INIT_SUSCEPT_MOXIFLOXACIN,
                INIT_SUSCEPT_OTHER_QUNINOLONES,
                INIT_SUSCEPT_OTHER_1_IND,
                INIT_SUSCEPT_OTHER_2_IND,
                SPUTUM_CULTURE_CONV_DOCUMENTED,
                NO_CONV_DOC_REASON,
                MOVED_WHERE_1,
                MOVED_IND,
                MOVED_WHERE_2,
                MOVED_WHERE_GT3_IND,
                MOVED_WHERE_3,
                MOVED_WHERE_ALL,
                MOVE_CITY,
                MOVE_CNTY_1,
                MOVE_CNTY_2,
                MOVE_CNTY_GT3_IND,
                MOVE_CNTY_3,
                MOVE_STATE_1,
                MOVE_CNTY_ALL,
                MOVE_STATE_2,
                MOVE_STATE_GT3_IND,
                MOVE_STATE_3,
                MOVE_CNTRY_1,
                MOVE_STATE_ALL,
                MOVE_CNTRY_2,
                MOVE_CNTRY_GT3_IND,
                MOVE_CNTRY_3,
                MOVE_CNTRY_ALL,
                TRANSNATIONAL_REFERRAL_IND,
                THERAPY_STOP_REASON,
                GT_12_REAS_1,
                THERAPY_STOP_CAUSE_OF_DEATH,
                GT_12_REAS_2,
                GT_12_REAS_GT3_IND,
                GT_12_REAS_3,
                GT_12_REAS_ALL,
                HC_PROV_TY_1,
                HC_PROV_TY_2,
                HC_PROV_TY_GT3_IND,
                HC_PROV_TY_3,
                HC_PROV_TY_ALL,
                DOT,
                FINAL_SUSCEPT_TESTING,
                FINAL_ISOLATE_IS_SPUTUM_IND,
                FINAL_ISOLATE_NOT_SPUTUM,
                FINAL_SUSCEPT_ISONIAZID,
                FINAL_SUSCEPT_RIFAMPIN,
                FINAL_SUSCEPT_PYRAZINAMIDE,
                FINAL_SUSCEPT_ETHAMBUTOL,
                FINAL_SUSCEPT_STREPTOMYCIN,
                FINAL_SUSCEPT_ETHIONAMIDE,
                FINAL_SUSCEPT_KANAMYCIN,
                FINAL_SUSCEPT_CYCLOSERINE,
                FINAL_SUSCEPT_CAPREOMYCIN,
                FINAL_SUSCEPT_PA_SALICYLIC_ACI,
                FINAL_SUSCEPT_AMIKACIN,
                FINAL_SUSCEPT_RIFABUTIN,
                FINAL_SUSCEPT_CIPROFLOXACIN,
                FINAL_SUSCEPT_OFLOXACIN,
                FINAL_SUSCEPT_RIFAPENTINE,
                FINAL_SUSCEPT_LEVOFLOXACIN,
                FINAL_SUSCEPT_MOXIFLOXACIN,
                FINAL_SUSCEPT_OTHER_QUINOLONES,
                FINAL_SUSCEPT_OTHER_IND,
                FINAL_SUSCEPT_OTHER_2_IND,
                CASE_VERIFICATION,
                CASE_STATUS,
                COUNT_STATUS,
                COUNTRY_OF_VERIFIED_CASE,
                NOTIFICATION_STATUS,
                NOTIFICATION_SENT_DATE,
                PATIENT_DOB,
                PATIENT_DECEASED_DATE,
                INVESTIGATION_START_DATE,
                INVESTIGATOR_ASSIGN_DATE,
                DATE_REPORTED,
                DATE_SUBMITTED,
                PREVIOUS_DIAGNOSIS_YEAR,
                DATE_ARRIVED_IN_US,
                INVESTIGATION_DEATH_DATE,
                SPUTUM_SMEAR_COLLECT_DATE,
                SPUTUM_CULT_COLLECT_DATE,
                SPUTUM_CULT_RESULT_RPT_DATE,
                SMR_PATH_CYTO_COLLECT_DATE,
                CULT_TISSUE_COLLECT_DATE,
                CULT_TISSUE_RESULT_RPT_DATE,
                NAA_COLLECT_DATE,
                NAA_RESULT_RPT_DATE,
                TST_PLACED_DATE,
                IGRA_COLLECT_DATE,
                INIT_REGIMEN_START_DATE,
                FIRST_ISOLATE_COLLECT_DATE,
                TB_SPUTUM_CULTURE_NEGATIVE_DAT,
                THERAPY_STOP_DATE,
                FINAL_ISOLATE_COLLECT_DATE,
                COUNT_DATE,
                INVESTIGATION_CREATE_DATE,
                INVESTIGATION_LAST_UPDTD_DATE,
                INVESTIGATION_KEY,
                CALC_REPORTED_AGE,
                PATIENT_PHONE_EXT_HOME,
                PATIENT_PHONE_EXT_WORK,
                AGE_REPORTED,
                TST_MM_INDURATION,
                DOT_NUMBER_WEEKS,
                MMWR_WEEK,
                MMWR_YEAR,
                PROGRAM_JURISDICTION_OID,
                PATIENT_LOCAL_ID,
                INVESTIGATION_LOCAL_ID,
                PATIENT_GENERAL_COMMENTS,
                PATIENT_FIRST_NAME,
                PATIENT_MIDDLE_NAME,
                PATIENT_LAST_NAME,
                PATIENT_STREET_ADDRESS_1,
                PATIENT_STREET_ADDRESS_2,
                PATIENT_CITY,
                PATIENT_ZIP,
                PATIENT_PHONE_NUMBER_HOME,
                PATIENT_PHONE_NUMBER_WORK,
                PATIENT_SSN,
                INVESTIGATOR_FIRST_NAME,
                INVESTIGATOR_LAST_NAME,
                INVESTIGATOR_PHONE_NUMBER,
                STATE_CASE_NUMBER,
                CITY_COUNTY_CASE_NUMBER,
                LINK_STATE_CASE_NUM_1,
                LINK_STATE_CASE_NUM_2,
                IGRA_TEST_TY,
                OTHER_TB_RISK_FACTORS,
                INIT_REGIMEN_OTHER_1,
                INIT_REGIMEN_OTHER_2,
                GENERAL_COMMENTS,
                ISOLATE_ACCESSION_NUM,
                INIT_SUSCEPT_OTHER_1,
                INIT_SUSCEPT_OTHER_2,
                COMMENTS_FOLLOW_UP_1,
                NO_CONV_DOC_OTHER_REASON,
                MOVE_CITY_2,
                THERAPY_EXTEND_GT_12_OTHER,
                FINAL_SUSCEPT_OTHER,
                FINAL_SUSCEPT_OTHER_2,
                COMMENTS_FOLLOW_UP_2,
                DIE_FRM_THIS_ILLNESS_IND,
                PROVIDER_OVERRIDE_COMMENTS,
                INVESTIGATION_CREATED_BY,
                INVESTIGATION_LAST_UPDTD_BY,
                NOTIFICATION_LOCAL_ID,
                NOTIFICATION_SUBMITTER,
                INIT_DRUG_REG_CALC,
                REPORTER_PHONE_NUMBER,
                REPORTING_SOURCE_NAME,
                REPORTING_SOURCE_TYPE,
                REPORTER_FIRST_NAME,
                REPORTER_LAST_NAME,
                PHYSICIAN_FIRST_NAME,
                PHYSICIAN_LAST_NAME,
                PHYSICIAN_PHONE_NUMBER,
                HOSPITALIZED,
                HOSPITAL_NAME,
                HOSPITALIZED_ADMISSION_DATE,
                HOSPITALIZED_DISCHARGE_DATE,
                HOSPITALIZED_DURATION_DAYS,
                DIAGNOSIS_DATE,
                ILLNESS_ONSET_DATE,
                ILLNESS_ONSET_AGE,
                ILLNESS_ONSET_AGE_UNIT,
                ILLNESS_END_DATE,
                ILLNESS_DURATION,
                ILLNESS_DURATION_UNIT,
                PREGNANT,
                DAYCARE,
                FOOD_HANDLER,
                DISEASE_ACQUIRED_WHERE,
                DISEASE_ACQUIRED_COUNTRY,
                DISEASE_ACQUIRED_STATE,
                DISEASE_ACQUIRED_CITY,
                DISEASE_ACQUIRED_COUNTY,
                TRANSMISSION_MODE,
                DETECTION_METHOD,
                OUTBREAK,
                OUTBREAK_NAME,
                CONFIRMATION_METHOD_1,
                CONFIRMATION_METHOD_2,
                CONFIRMATION_METHOD_3,
                CONFIRMATION_METHOD_ALL,
                CONFIRMATION_DATE,
                CONFIRMATION_METHOD_GT3_IND,
                DATE_REPORTED_TO_COUNTY
            )
            SELECT 
                CALC_5_YEAR_AGE_GROUP,
                CALC_10_YEAR_AGE_GROUP,
                LEFT(PATIENT_NAME_SUFFIX, 50),
                LEFT(PATIENT_STATE, 50),
                LEFT(PATIENT_COUNTY, 50),
                LEFT(PATIENT_COUNTRY, 50),
                LEFT(PATIENT_WITHIN_CITY_LIMITS, 50),
                LEFT(AGE_REPORTED_UNIT, 50),
                LEFT(PATIENT_BIRTH_SEX, 50),
                LEFT(PATIENT_CURRENT_SEX, 50),
                LEFT(PATIENT_DECEASED_INDICATOR, 50),
                LEFT(PATIENT_MARITAL_STATUS, 50),
                LEFT(PATIENT_ETHNICITY, 50),
                LEFT(RACE_CALCULATED, 4000),
                LEFT(RACE_CALC_DETAILS, 200),
                LEFT(RACE_ASIAN_1, 50),
                LEFT(RACE_ASIAN_2, 50),
                LEFT(RACE_ASIAN_3, 50),
                LEFT(RACE_ASIAN_GT3_IND, 50),
                LEFT(RACE_ASIAN_ALL, 4000),
                LEFT(RACE_NAT_HI_1, 50),
                LEFT(RACE_NAT_HI_2, 50),
                LEFT(RACE_NAT_HI_3, 50),
                LEFT(RACE_NAT_HI_GT3_IND, 50),
                LEFT(RACE_NAT_HI_ALL, 4000),
                LEFT(JURISDICTION_NAME, 50),
                LEFT(PROGRAM_AREA_DESCRIPTION, 50),
                LEFT(INVESTIGATION_STATUS, 50),
                LEFT(LINK_REASON_1, 50),
                LEFT(LINK_REASON_2, 50),
                LEFT(PREVIOUS_DIAGNOSIS_IND, 50),
                LEFT(US_BORN_IND, 50),
                LEFT(PATIENT_BIRTH_COUNTRY, 50),
                LEFT(PATIENT_OUTSIDE_US_GT_2_MONTHS, 50),
                LEFT(OUT_OF_CNTRY_1, 50),
                LEFT(OUT_OF_CNTRY_2, 50),
                LEFT(OUT_OF_CNTRY_3, 50),
                LEFT(OUT_OF_CNTRY_GT3_IND, 50),
                LEFT(OUT_OF_CNTRY_ALL, 4000),
                LEFT(PRIMARY_GUARD_1_BIRTH_COUNTRY, 50),
                LEFT(PRIMARY_GUARD_2_BIRTH_COUNTRY, 50),
                LEFT(STATUS_AT_DIAGNOSIS, 50),
                LEFT(DISEASE_SITE_1, 50),
                LEFT(DISEASE_SITE_2, 50),
                LEFT(DISEASE_SITE_3, 50),
                LEFT(DISEASE_SITE_GT3_IND, 50),
                LEFT(DISEASE_SITE_ALL, 4000),
                LEFT(CALC_DISEASE_SITE, 50),
                LEFT(SPUTUM_SMEAR_RESULT, 50),
                LEFT(SPUTUM_CULTURE_RESULT, 50),
                LEFT(SPUTUM_CULT_RPT_LAB_TY, 50),
                LEFT(SMR_PATH_CYTO_RESULT, 50),
                LEFT(SMR_PATH_CYTO_SITE, 50),
                LEFT(SMR_EXAM_TY_1, 50),
                LEFT(SMR_EXAM_TY_2, 50),
                LEFT(SMR_EXAM_TY_3, 50),
                LEFT(SMR_EXAM_TY_GT3_IND, 50),
                LEFT(SMR_EXAM_TY_ALL, 4000),
                LEFT(CULT_TISSUE_RESULT, 50),
                LEFT(CULT_TISSUE_SITE, 50),
                LEFT(CULT_TISSUE_RESULT_RPT_LAB_TY, 50),
                LEFT(NAA_RESULT, 50),
                LEFT(NAA_SPEC_IS_SPUTUM_IND, 50),
                LEFT(NAA_SPEC_NOT_SPUTUM, 50),
                LEFT(NAA_RPT_LAB_TY, 50),
                LEFT(CHEST_XRAY_RESULT, 50),
                LEFT(CHEST_XRAY_CAVITY_EVIDENCE, 50),
                LEFT(CHEST_XRAY_MILIARY_EVIDENCE, 50),
                LEFT(CT_SCAN_RESULT, 50),
                LEFT(CT_SCAN_CAVITY_EVIDENCE, 50),
                LEFT(CT_SCAN_MILIARY_EVIDENCE, 50),
                LEFT(TST_RESULT, 50),
                LEFT(IGRA_RESULT, 50),
                LEFT(PRIMARY_REASON_EVALUATED, 50),
                LEFT(HOMELESS_IND, 50),
                LEFT(CORRECTIONAL_FACIL_RESIDENT, 50),
                LEFT(CORRECTIONAL_FACIL_TY, 50),
                LEFT(CORRECTIONAL_FACIL_CUSTODY_IND, 50),
                LEFT(LONGTERM_CARE_FACIL_RESIDENT, 50),
                LEFT(LONGTERM_CARE_FACIL_TY, 50),
                LEFT(OCCUPATION_RISK, 50),
                LEFT(INJECT_DRUG_USE_PAST_YEAR, 50),
                LEFT(NONINJECT_DRUG_USE_PAST_YEAR, 50),
                LEFT(ADDL_RISK_1, 50),
                LEFT(EXCESS_ALCOHOL_USE_PAST_YEAR, 50),
                LEFT(ADDL_RISK_2, 50),
                LEFT(ADDL_RISK_GT3_IND, 50),
                LEFT(ADDL_RISK_3, 50),
                LEFT(ADDL_RISK_ALL, 4000),
                LEFT(IMMIGRATION_STATUS_AT_US_ENTRY, 50),
                LEFT(INIT_REGIMEN_ISONIAZID, 50),
                LEFT(INIT_REGIMEN_RIFAMPIN, 50),
                LEFT(INIT_REGIMEN_PYRAZINAMIDE, 50),
                LEFT(INIT_REGIMEN_ETHAMBUTOL, 50),
                LEFT(INIT_REGIMEN_STREPTOMYCIN, 50),
                LEFT(INIT_REGIMEN_ETHIONAMIDE, 50),
                LEFT(INIT_REGIMEN_KANAMYCIN, 50),
                LEFT(INIT_REGIMEN_CYCLOSERINE, 50),
                LEFT(INIT_REGIMEN_CAPREOMYCIN, 50),
                LEFT(INIT_REGIMEN_PA_SALICYLIC_ACID, 50),
                LEFT(INIT_REGIMEN_AMIKACIN, 50),
                LEFT(INIT_REGIMEN_RIFABUTIN, 50),
                LEFT(INIT_REGIMEN_CIPROFLOXACIN, 50),
                LEFT(INIT_REGIMEN_OFLOXACIN, 50),
                LEFT(INIT_REGIMEN_RIFAPENTINE, 50),
                LEFT(INIT_REGIMEN_LEVOFLOXACIN, 50),
                LEFT(INIT_REGIMEN_MOXIFLOXACIN, 50),
                LEFT(INIT_REGIMEN_OTHER_1_IND, 50),
                LEFT(INIT_REGIMEN_OTHER_2_IND, 50),
                LEFT(ISOLATE_SUBMITTED_IND, 50),
                LEFT(INIT_SUSCEPT_TESTING_DONE, 50),
                LEFT(FIRST_ISOLATE_IS_SPUTUM_IND, 50),
                LEFT(FIRST_ISOLATE_NOT_SPUTUM, 50),
                LEFT(INIT_SUSCEPT_ISONIAZID, 50),
                LEFT(INIT_SUSCEPT_RIFAMPIN, 50),
                LEFT(INIT_SUSCEPT_PYRAZINAMIDE, 50),
                LEFT(INIT_SUSCEPT_ETHAMBUTOL, 50),
                LEFT(INIT_SUSCEPT_STREPTOMYCIN, 50),
                LEFT(INIT_SUSCEPT_ETHIONAMIDE, 50),
                LEFT(INIT_SUSCEPT_KANAMYCIN, 50),
                LEFT(INIT_SUSCEPT_CYCLOSERINE, 50),
                LEFT(INIT_SUSCEPT_CAPREOMYCIN, 50),
                LEFT(INIT_SUSCEPT_PA_SALICYLIC_ACID, 50),
                LEFT(INIT_SUSCEPT_AMIKACIN, 50),
                LEFT(INIT_SUSCEPT_RIFABUTIN, 50),
                LEFT(INIT_SUSCEPT_CIPROFLOXACIN, 50),
                LEFT(INIT_SUSCEPT_OFLOXACIN, 50),
                LEFT(INIT_SUSCEPT_RIFAPENTINE, 50),
                LEFT(INIT_SUSCEPT_LEVOFLOXACIN, 50),
                LEFT(INIT_SUSCEPT_MOXIFLOXACIN, 50),
                LEFT(INIT_SUSCEPT_OTHER_QUNINOLONES, 50),
                LEFT(INIT_SUSCEPT_OTHER_1_IND, 50),
                LEFT(INIT_SUSCEPT_OTHER_2_IND, 50),
                LEFT(SPUTUM_CULTURE_CONV_DOCUMENTED, 50),
                LEFT(NO_CONV_DOC_REASON, 50),
                LEFT(MOVED_WHERE_1, 50),
                LEFT(MOVED_IND, 100),
                LEFT(MOVED_WHERE_2, 50),
                LEFT(MOVED_WHERE_GT3_IND, 50),
                LEFT(MOVED_WHERE_3, 50),
                LEFT(MOVED_WHERE_ALL, 4000),
                LEFT(MOVE_CITY, 100),
                LEFT(MOVE_CNTY_1, 50),
                LEFT(MOVE_CNTY_2, 50),
                LEFT(MOVE_CNTY_GT3_IND, 50),
                LEFT(MOVE_CNTY_3, 50),
                LEFT(MOVE_STATE_1, 50),
                LEFT(MOVE_CNTY_ALL, 4000),
                LEFT(MOVE_STATE_2, 50),
                LEFT(MOVE_STATE_GT3_IND, 50),
                LEFT(MOVE_STATE_3, 50),
                LEFT(MOVE_CNTRY_1, 50),
                LEFT(MOVE_STATE_ALL, 4000),
                LEFT(MOVE_CNTRY_2, 50),
                LEFT(MOVE_CNTRY_GT3_IND, 50),
                LEFT(MOVE_CNTRY_3, 50),
                LEFT(MOVE_CNTRY_ALL, 4000),
                LEFT(TRANSNATIONAL_REFERRAL_IND, 50),
                LEFT(THERAPY_STOP_REASON, 50),
                LEFT(GT_12_REAS_1, 50),
                LEFT(THERAPY_STOP_CAUSE_OF_DEATH, 50),
                LEFT(GT_12_REAS_2, 50),
                LEFT(GT_12_REAS_GT3_IND, 50),
                LEFT(GT_12_REAS_3, 50),
                LEFT(GT_12_REAS_ALL, 4000),
                LEFT(HC_PROV_TY_1, 50),
                LEFT(HC_PROV_TY_2, 50),
                LEFT(HC_PROV_TY_GT3_IND, 50),
                LEFT(HC_PROV_TY_3, 50),
                LEFT(HC_PROV_TY_ALL, 4000),
                LEFT(DOT, 50),
                LEFT(FINAL_SUSCEPT_TESTING, 50),
                LEFT(FINAL_ISOLATE_IS_SPUTUM_IND, 50),
                LEFT(FINAL_ISOLATE_NOT_SPUTUM, 50),
                LEFT(FINAL_SUSCEPT_ISONIAZID, 50),
                LEFT(FINAL_SUSCEPT_RIFAMPIN, 50),
                LEFT(FINAL_SUSCEPT_PYRAZINAMIDE, 50),
                LEFT(FINAL_SUSCEPT_ETHAMBUTOL, 50),
                LEFT(FINAL_SUSCEPT_STREPTOMYCIN, 50),
                LEFT(FINAL_SUSCEPT_ETHIONAMIDE, 50),
                LEFT(FINAL_SUSCEPT_KANAMYCIN, 50),
                LEFT(FINAL_SUSCEPT_CYCLOSERINE, 50),
                LEFT(FINAL_SUSCEPT_CAPREOMYCIN, 50),
                LEFT(FINAL_SUSCEPT_PA_SALICYLIC_ACI, 50),
                LEFT(FINAL_SUSCEPT_AMIKACIN, 50),
                LEFT(FINAL_SUSCEPT_RIFABUTIN, 50),
                LEFT(FINAL_SUSCEPT_CIPROFLOXACIN, 50),
                LEFT(FINAL_SUSCEPT_OFLOXACIN, 50),
                LEFT(FINAL_SUSCEPT_RIFAPENTINE, 50),
                LEFT(FINAL_SUSCEPT_LEVOFLOXACIN, 50),
                LEFT(FINAL_SUSCEPT_MOXIFLOXACIN, 50),
                LEFT(FINAL_SUSCEPT_OTHER_QUINOLONES, 50),
                LEFT(FINAL_SUSCEPT_OTHER_IND, 50),
                LEFT(FINAL_SUSCEPT_OTHER_2_IND, 50),
                LEFT(CASE_VERIFICATION, 50),
                LEFT(CASE_STATUS, 50),
                LEFT(COUNT_STATUS, 50),
                LEFT(COUNTRY_OF_VERIFIED_CASE, 50),
                LEFT(NOTIFICATION_STATUS, 50),
                NOTIFICATION_SENT_DATE,
                PATIENT_DOB,
                PATIENT_DECEASED_DATE,
                INVESTIGATION_START_DATE,
                INVESTIGATOR_ASSIGN_DATE,
                DATE_REPORTED,
                DATE_SUBMITTED,
                PREVIOUS_DIAGNOSIS_YEAR,
                DATE_ARRIVED_IN_US,
                INVESTIGATION_DEATH_DATE,
                SPUTUM_SMEAR_COLLECT_DATE,
                SPUTUM_CULT_COLLECT_DATE,
                SPUTUM_CULT_RESULT_RPT_DATE,
                SMR_PATH_CYTO_COLLECT_DATE,
                CULT_TISSUE_COLLECT_DATE,
                CULT_TISSUE_RESULT_RPT_DATE,
                NAA_COLLECT_DATE,
                NAA_RESULT_RPT_DATE,
                TST_PLACED_DATE,
                IGRA_COLLECT_DATE,
                INIT_REGIMEN_START_DATE,
                FIRST_ISOLATE_COLLECT_DATE,
                TB_SPUTUM_CULTURE_NEGATIVE_DAT,
                THERAPY_STOP_DATE,
                FINAL_ISOLATE_COLLECT_DATE,
                COUNT_DATE,
                INVESTIGATION_CREATE_DATE,
                INVESTIGATION_LAST_UPDTD_DATE,
                INVESTIGATION_KEY,
                CALC_REPORTED_AGE,
                LEFT(PATIENT_PHONE_EXT_HOME, 50),
                LEFT(PATIENT_PHONE_EXT_WORK, 50),
                AGE_REPORTED,
                TST_MM_INDURATION,
                DOT_NUMBER_WEEKS,
                MMWR_WEEK,
                MMWR_YEAR,
                PROGRAM_JURISDICTION_OID,
                LEFT(PATIENT_LOCAL_ID, 50),
                LEFT(INVESTIGATION_LOCAL_ID, 50),
                LEFT(PATIENT_GENERAL_COMMENTS, 2000),
                LEFT(PATIENT_FIRST_NAME, 50),
                LEFT(PATIENT_MIDDLE_NAME, 50),
                LEFT(PATIENT_LAST_NAME, 50),
                LEFT(PATIENT_STREET_ADDRESS_1, 50),
                LEFT(PATIENT_STREET_ADDRESS_2, 50),
                LEFT(PATIENT_CITY, 50),
                LEFT(PATIENT_ZIP, 50),
                LEFT(PATIENT_PHONE_NUMBER_HOME, 50),
                LEFT(PATIENT_PHONE_NUMBER_WORK, 50),
                LEFT(PATIENT_SSN, 50),
                LEFT(INVESTIGATOR_FIRST_NAME, 50),
                LEFT(INVESTIGATOR_LAST_NAME, 50),
                LEFT(INVESTIGATOR_PHONE_NUMBER, 50),
                LEFT(STATE_CASE_NUMBER, 50),
                LEFT(CITY_COUNTY_CASE_NUMBER, 50),
                LEFT(LINK_STATE_CASE_NUM_1, 50),
                LEFT(LINK_STATE_CASE_NUM_2, 50),
                LEFT(IGRA_TEST_TY, 50),
                LEFT(OTHER_TB_RISK_FACTORS, 50),
                LEFT(INIT_REGIMEN_OTHER_1, 50),
                LEFT(INIT_REGIMEN_OTHER_2, 50),
                LEFT(GENERAL_COMMENTS, 2000),
                LEFT(ISOLATE_ACCESSION_NUM, 50),
                LEFT(INIT_SUSCEPT_OTHER_1, 50),
                LEFT(INIT_SUSCEPT_OTHER_2, 50),
                LEFT(COMMENTS_FOLLOW_UP_1, 2000),
                LEFT(NO_CONV_DOC_OTHER_REASON, 50),
                LEFT(MOVE_CITY_2, 50),
                LEFT(THERAPY_EXTEND_GT_12_OTHER, 50),
                LEFT(FINAL_SUSCEPT_OTHER, 50),
                LEFT(FINAL_SUSCEPT_OTHER_2, 50),
                LEFT(COMMENTS_FOLLOW_UP_2, 2000),
                LEFT(DIE_FRM_THIS_ILLNESS_IND, 50),
                LEFT(PROVIDER_OVERRIDE_COMMENTS, 2000),
                LEFT(INVESTIGATION_CREATED_BY, 50),
                LEFT(INVESTIGATION_LAST_UPDTD_BY, 50),
                LEFT(NOTIFICATION_LOCAL_ID, 50),
                LEFT(NOTIFICATION_SUBMITTER, 50),
                LEFT(INIT_DRUG_REG_CALC, 200),
                LEFT(REPORTER_PHONE_NUMBER, 50),
                LEFT(REPORTING_SOURCE_NAME, 50),
                LEFT(REPORTING_SOURCE_TYPE, 50),
                LEFT(REPORTER_FIRST_NAME, 50),
                LEFT(REPORTER_LAST_NAME, 50),
                LEFT(PHYSICIAN_FIRST_NAME, 50),
                LEFT(PHYSICIAN_LAST_NAME, 50),
                LEFT(PHYSICIAN_PHONE_NUMBER, 50),
                LEFT(HOSPITALIZED, 50),
                LEFT(HOSPITAL_NAME, 50),
                HOSPITALIZED_ADMISSION_DATE,
                HOSPITALIZED_DISCHARGE_DATE,
                HOSPITALIZED_DURATION_DAYS,
                DIAGNOSIS_DATE,
                ILLNESS_ONSET_DATE,
                ILLNESS_ONSET_AGE,
                LEFT(ILLNESS_ONSET_AGE_UNIT, 50),
                ILLNESS_END_DATE,
                ILLNESS_DURATION,
                LEFT(ILLNESS_DURATION_UNIT, 50),
                LEFT(PREGNANT, 50),
                LEFT(DAYCARE, 50),
                LEFT(FOOD_HANDLER, 50),
                LEFT(DISEASE_ACQUIRED_WHERE, 50),
                LEFT(DISEASE_ACQUIRED_COUNTRY, 50),
                LEFT(DISEASE_ACQUIRED_STATE, 50),
                LEFT(DISEASE_ACQUIRED_CITY, 100),
                LEFT(DISEASE_ACQUIRED_COUNTY, 50),
                LEFT(TRANSMISSION_MODE, 50),
                LEFT(DETECTION_METHOD, 50),
                LEFT(OUTBREAK, 50),
                LEFT(OUTBREAK_NAME, 100),
                LEFT(CONFIRMATION_METHOD_1, 50),
                LEFT(CONFIRMATION_METHOD_2, 50),
                LEFT(CONFIRMATION_METHOD_3, 50),
                LEFT(CONFIRMATION_METHOD_ALL, 4000),
                CONFIRMATION_DATE,
                LEFT(CONFIRMATION_METHOD_GT3_IND, 2000),
                DATE_REPORTED_TO_COUNTY
            FROM #TB_DATAMART;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #TB_DATAMART;

            INSERT INTO [dbo].[job_flow_log]
                (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES 
                (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;
        
        --------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

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
