IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_covid_lab_datamart_postprocessing]')
                                      AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
    BEGIN
        DROP PROCEDURE [dbo].[sp_covid_lab_datamart_postprocessing]
    END
GO

CREATE PROCEDURE [dbo].[sp_covid_lab_datamart_postprocessing]
    @observation_id_list nvarchar(max),       -- List of observation IDs to process (comma-separated)
    @debug bit = 'false'                       -- Flag to enable debug output
AS
BEGIN
    /* Logging and initialization variables */
    DECLARE @rowcount bigint;
    DECLARE @proc_step_no float = 0;
    DECLARE @proc_step_name varchar(200) = '';
    DECLARE @batch_id bigint;
    DECLARE @dataflow_name varchar(200) = 'COVID LAB DATAMART Post-Processing Event';
    DECLARE @package_name varchar(200) = 'sp_covid_lab_datamart_postprocessing';

    SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);

    -- Initialize logging
    INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
    VALUES (@batch_id,@dataflow_name,@package_name,'START',0,'SP_Start',LEFT(ISNULL(@observation_id_list, 'NULL'),500),0);

    BEGIN TRY
        SET @proc_step_name = 'Create COVID_LAB_TEMP_DATA';
        SET @proc_step_no = 1;

        /* Determine which observations to process */
        IF @observation_id_list = ''
            BEGIN
                RAISERROR('observation_id_list parameter cannot be empty. Please provide at least one observation ID.', 16, 1);
                RETURN;
            END
        ELSE
            BEGIN
                -- Process the specific observations in the ID list
                -- And filter out LOG_DEL records upfront
                SELECT obs.observation_uid
                INTO #COVID_OBSERVATIONS_TO_PROCESS
                FROM STRING_SPLIT(@observation_id_list, ',') split_ids
                         INNER JOIN dbo.nrt_observation obs WITH(NOLOCK) ON TRY_CAST(split_ids.value AS BIGINT) = obs.observation_uid
                WHERE COALESCE(obs.record_status_cd, '') <> 'LOG_DEL';

            END

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,LEFT(ISNULL(@observation_id_list, 'NULL'),500),0);

        /* Debug output if requested */
        IF @debug = 'true' SELECT  @proc_step_name, * FROM #COVID_OBSERVATIONS_TO_PROCESS;

        /* Create the next session table to hold text results */
        SET @proc_step_name = 'Extract Text Results';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        SELECT DISTINCT
            o_order.observation_uid,
            o.observation_uid AS target_observation_uid, --result
            o.local_id AS Lab_Local_ID,
            COALESCE(dp.PATIENT_LOCAL_ID,p.local_id) AS Patient_Local_ID
        INTO #COVID_RESULT_LIST
        FROM #COVID_OBSERVATIONS_TO_PROCESS cp --Order
                 INNER JOIN dbo.nrt_observation o_order WITH(NOLOCK) ON cp.observation_uid = o_order.observation_uid
                 CROSS APPLY (
            SELECT CAST(value AS BIGINT) as target_obs_uid
            FROM STRING_SPLIT(o_order.result_observation_uid, ',')
        ) as split_results
                 INNER JOIN dbo.nrt_observation o WITH(NOLOCK) ON split_results.target_obs_uid = o.observation_uid
                 LEFT JOIN dbo.D_PATIENT dp WITH(NOLOCK) ON o_order.patient_id = dp.patient_uid
                 LEFT JOIN dbo.nrt_patient p WITH(NOLOCK) ON o_order.patient_id = p.patient_uid
                 INNER JOIN dbo.nrt_patient_key pk WITH(NOLOCK) ON pk.patient_uid = p.patient_uid
        WHERE COALESCE(dp.patient_uid, pk.patient_uid) IS NOT NULL
          AND (o.cd IN
               (
                   SELECT loinc_cd
                   FROM dbo.nrt_srte_Loinc_condition
                   WHERE condition_cd = '11065'
               )
            OR o.cd IN(''))--replace '' with the local codes seperated by comma
          AND o.cd NOT IN
              (
                  SELECT loinc_cd
                  FROM dbo.nrt_srte_Loinc_code
                  WHERE time_aspect = 'Pt'
                    AND system_cd = '^Patient'
              );

        IF @debug = 'true' SELECT '#COVID_RESULT_LIST', *
                           from #COVID_RESULT_LIST;


        SELECT DISTINCT
            cp.observation_uid,
            cp.target_observation_uid, --result
            cp.Lab_Local_ID,
            cp.Patient_Local_ID,
            replace(replace(otxt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ') AS Text_Result_Desc,
            replace(replace(otxt_comment.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ') AS Result_Comments
        INTO #COVID_TEXT_RESULT_LIST
        FROM #COVID_RESULT_LIST cp --Order
                 INNER JOIN dbo.nrt_observation o WITH(NOLOCK) ON cp.target_observation_uid = o.observation_uid
                 LEFT OUTER JOIN dbo.nrt_observation_txt otxt WITH(NOLOCK) ON o.observation_uid = otxt.observation_uid AND isnull(o.batch_id,1) = isnull(otxt.batch_id,1)
            AND (otxt.ovt_txt_type_cd = 'O' OR otxt.ovt_txt_type_cd IS NULL)
                 LEFT OUTER JOIN dbo.nrt_observation_txt otxt_comment WITH(NOLOCK) ON o.observation_uid = otxt_comment.observation_uid AND isnull(o.batch_id,1) = isnull(otxt_comment.batch_id,1)
            AND otxt_comment.ovt_txt_type_cd = 'N'
        ;

        IF @debug = 'true' SELECT '#COVID_TEXT_RESULT_LIST',*
                           from #COVID_TEXT_RESULT_LIST;

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,LEFT(ISNULL(@observation_id_list, 'NULL'),500),0);

        /* Debug output if requested */
        IF @debug = 'true'
            SELECT @proc_step_name, * FROM #COVID_TEXT_RESULT_LIST;

        /* Create the core lab data table */
        SET @proc_step_name = 'Create COVID_LAB_CORE_DATA';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;


        SELECT DISTINCT
            o.observation_uid AS Observation_UID,
            o.local_id AS Lab_Local_ID,
            o.record_status_cd,
            o.cd AS Ordered_Test_Cd,
            o.cd_desc_txt AS Ordered_Test_Desc,
            o.cd_system_cd AS Ordered_Test_Code_System,
            o.electronic_ind AS Electronic_Ind,
            o.prog_area_cd AS Program_Area_Cd,
            o.jurisdiction_cd AS Jurisdiction_Cd,
            o.activity_to_time AS Lab_Report_Dt,
            o.rpt_to_state_time AS Lab_Rpt_Received_By_PH_Dt,
            o.activity_from_time AS ORDER_TEST_DATE,
            o.target_site_cd AS SPECIMEN_SOURCE_SITE_CD,
            o.target_site_desc_txt AS SPECIMEN_SOURCE_SITE_DESC,
            cvg1.code_short_desc_txt AS Order_result_status,
            j_code.code_desc_txt AS Jurisdiction_Nm,
            mat.material_cd AS Specimen_Cd,
            mat.material_desc AS Specimen_Desc,
            mat.material_details AS Specimen_type_free_text,
            CASE
                WHEN o.accession_number IS NULL
                    OR o.accession_number = ''
                    THEN o.local_id
                ELSE o.accession_number
                END AS Specimen_Id,
            CASE
                WHEN o.accession_number IS NULL
                    OR o.accession_number = ''
                    THEN o.local_id
                ELSE o.accession_number
                END AS Testing_Lab_Accession_Number,
            o.add_time AS Lab_Added_Dt,
            o.last_chg_time AS Lab_Update_Dt,
            o.effective_from_time AS Specimen_Coll_Dt,
            o1.observation_uid AS COVID_LAB_DATAMART_KEY,
            o1.cd AS Resulted_Test_Cd,
            o1.cd_desc_txt AS Resulted_Test_Desc,
            o1.cd_system_cd AS Resulted_Test_Code_System,
            o1.device_instance_id_1 AS DEVICE_INSTANCE_ID_1,
            o1.device_instance_id_2 AS DEVICE_INSTANCE_ID_2,
            cvg2.code_short_desc_txt AS Test_result_status,
            o1.method_desc_txt AS Test_Method_Desc,
            CASE WHEN o1.method_cd LIKE '%**%'
                     THEN LEFT(o1.method_cd, CHARINDEX('**', o1.method_cd)-1)
                 ELSE o1.method_cd
                END AS Device_Type_Id_1,
            CASE WHEN o1.method_cd LIKE '%**%'
                     THEN SUBSTRING(o1.method_cd, CHARINDEX('**', o1.method_cd)+2, LEN(o1.method_cd))
                 ELSE NULL
                END AS Device_Type_Id_2,
            COALESCE(d_org_perform.ORGANIZATION_NAME, org_perform.organization_name) AS Perform_Facility_Name,
            COALESCE(d_org_perform.ORGANIZATION_STREET_ADDRESS_1, org_perform.street_address_1) AS Testing_lab_Address_One,
            COALESCE(d_org_perform.ORGANIZATION_STREET_ADDRESS_2, org_perform.street_address_2) AS Testing_lab_Address_Two,
            COALESCE(d_org_perform.ORGANIZATION_COUNTRY, org_perform.country) AS Testing_lab_Country,
            COALESCE(d_org_perform.ORGANIZATION_COUNTY_CODE, org_perform.county_code) AS Testing_lab_county,
            COALESCE(d_org_perform.ORGANIZATION_COUNTY, org_perform.county) AS Testing_lab_county_Desc,
            COALESCE(d_org_perform.ORGANIZATION_CITY, org_perform.city) AS Testing_lab_City,
            COALESCE(d_org_perform.ORGANIZATION_STATE_CODE, org_perform.state_code) AS Testing_lab_State_Cd,
            dim_state_testing_lab.state_nm AS Testing_lab_State, --State small Code is not recorded in D_ORGANIZATION nor nrt_organization. Temporary solution.
            COALESCE(d_org_perform.ORGANIZATION_ZIP, org_perform.zip) AS Testing_lab_Zip_Cd,
            ovc.ovc_code AS Result_Cd,
            ovc.ovc_code_system_cd AS Result_Cd_Sys,
            ovc.ovc_display_name AS Result_Desc,
            Text_Result_Desc,
            ovn.ovn_comparator_cd_1 AS Numeric_Comparator_Cd,
            ovn.ovn_numeric_value_1 AS Numeric_Value_1,
            ovn.ovn_numeric_value_2 AS Numeric_Value_2,
            ovn.ovn_numeric_unit_cd AS Numeric_Unit_Cd,
            ovn.ovn_low_range AS Numeric_Low_Range,
            ovn.ovn_high_range AS Numeric_High_Range,
            ovn.ovn_separator_cd AS Numeric_Separator_Cd,
            o1.interpretation_cd AS Interpretation_Cd,
            o1.interpretation_desc_txt AS Interpretation_Desc,
            Result_Comments,
            LTRIM(ISNULL(ovc.ovc_display_name, '') + ' ' + ISNULL(Text_Result_Desc, '') + ' ' + ISNULL(Result_Comments, ' ')) AS Result
        INTO #COVID_LAB_CORE_DATA
        FROM #COVID_TEXT_RESULT_LIST ctr
                 LEFT JOIN dbo.nrt_observation o WITH(NOLOCK) ON ctr.observation_uid = o.observation_uid
                 LEFT JOIN dbo.nrt_observation o1 WITH(NOLOCK) ON ctr.target_observation_uid = o1.observation_uid --Result
            AND o1.obs_domain_cd_st_1 = 'Result'
                 LEFT OUTER JOIN dbo.nrt_observation_coded ovc WITH(NOLOCK) ON o1.observation_uid = ovc.observation_uid
            AND isnull(o1.batch_id,1) = isnull(ovc.batch_id,1)
                 LEFT OUTER JOIN dbo.nrt_srte_Jurisdiction_code j_code WITH(NOLOCK) ON j_code.code = o.jurisdiction_cd
                 LEFT OUTER JOIN dbo.nrt_srte_Code_value_general cvg1 WITH(NOLOCK) ON cvg1.code = o.status_cd
            AND cvg1.code_set_nm = 'ACT_OBJ_ST'
                 LEFT OUTER JOIN dbo.nrt_srte_Code_value_general cvg2 WITH(NOLOCK) ON cvg2.code = o1.status_cd
            AND cvg2.code_set_nm = 'ACT_OBJ_ST'
                 LEFT OUTER JOIN dbo.nrt_observation_numeric ovn WITH(NOLOCK) ON o1.observation_uid = ovn.observation_uid
            AND isnull(o1.batch_id,1) = isnull(ovn.batch_id,1)
                 LEFT OUTER JOIN dbo.nrt_observation_material mat WITH(NOLOCK) ON o.material_id = mat.material_id
                 LEFT OUTER JOIN dbo.nrt_organization org_perform WITH(NOLOCK) ON o1.performing_organization_id = org_perform.organization_uid
            --LEFT JOIN dbo.nrt_organization_key orgk WITH(NOLOCK) ON orgk.organization_uid = org_perform.organization_uid
                 LEFT OUTER JOIN dbo.D_Organization d_org_perform WITH(NOLOCK) ON o1.performing_organization_id = d_org_perform.ORGANIZATION_UID
                 OUTER APPLY  (
            SELECT COALESCE(d_org_perform.ORGANIZATION_STATE, org_perform.state) Testing_lab_State
        ) AS ld
                 LEFT JOIN dbo.nrt_srte_State_code dim_state_testing_lab WITH(NOLOCK) ON dim_state_testing_lab.code_desc_txt = ld.Testing_lab_State;


        /* Logging */
        SET @rowcount = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,LEFT(ISNULL(@observation_id_list, 'NULL'),500),0);

        /* Debug output if requested */
        IF @debug = 'true'
            SELECT @proc_step_name,* FROM #COVID_LAB_CORE_DATA;

        /* Create result type classification */
        SET @proc_step_name = 'Create COVID_LAB_RSLT_TYPE';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        SELECT
            core.Observation_UID AS RT_Observation_UID,
--            core.target_observation_uid,
            core.Result AS RT_Result,
            CASE
                -- Modify the logic (add additional variables) to determine negative labs
                WHEN Result IN('NEGATIVE', 'Negative: SARS-CoV-2 virus is NOT detected', 'PAN SARS RNA: NEGATIVE', 'PRESUMPTIVE NEGATIVE', 'SARS COV 2 RNA: NEGATIVE', 'Not Detected', 'Not detected (qualifier value)', 'OVERALL RESULT: NOT DETECTED', 'Undetected', 'SARS-CoV-2 RNA was not present in the specimen')
                    OR Result LIKE '%Negative%'
                    OR Result LIKE '%Presumptive Negative%'
                    OR Result LIKE 'the specimen is negative for sars-cov%'
                    OR Result LIKE '%not detected%'
                    OR Result LIKE 'undetected%'
                    THEN 'Negative'
                -- Modify the logic (add additional variables) to determine positive labs
                WHEN Result IN('***DETECTED***', 'Presum-Pos', 'present')
                    OR Result LIKE 'abnormal%'
                    OR (Result LIKE '%detected%'
                        AND Result NOT LIKE '%not detected%'
                        AND Result NOT LIKE '%undetected%')
                    OR Result LIKE 'positive%'
                    OR Result LIKE '%positive%'
                    OR Result LIKE 'presumptive pos%'
                    OR Result LIKE 'the specimen is positive for sars-cov%'
                    THEN 'Positive'
                -- Modify the logic (add additional variables) to determine Indeterminate labs
                WHEN Result IN('Inconclusive', 'Indeterminate', 'Invalid', 'not det', 'Not Performed', 'pendingPUI', 'unknown', 'unknowninconclusive')
                    OR Result LIKE '%INCONCLUSIVE by RT%'
                    OR Result LIKE '%Inconclusive%'
                    OR Result LIKE '%Indeterminate%'
                    OR Result LIKE '%unresolved%'
                    THEN 'Indeterminate'
                ELSE NULL
                END AS Result_Category
        INTO #COVID_LAB_RSLT_TYPE
        FROM #COVID_LAB_CORE_DATA core
        WHERE Result != '';

        IF @debug = 'true'
            SELECT @proc_step_name,* FROM #COVID_LAB_RSLT_TYPE;


        /* Logging */
        SET @rowcount = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,LEFT(ISNULL(@observation_id_list, 'NULL'),500),0);


        /* Create patient data */
        SET @proc_step_name = 'Create COVID_LAB_PATIENT_DATA';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        -- Patient Data
        SELECT DISTINCT
            o.Observation_uid AS Pat_Observation_UID,
            COALESCE(d_patient.PATIENT_LAST_NAME,p.last_name) AS Last_Name,
            COALESCE(d_patient.PATIENT_MIDDLE_NAME,p.middle_name) AS Middle_Name,
            COALESCE(d_patient.PATIENT_FIRST_NAME,p.first_name) AS First_Name,
            COALESCE(d_patient.PATIENT_LOCAL_ID,p.local_id) AS Patient_Local_ID,
            cvg1.CODE_VAL AS Current_Sex_Cd, --CNDE-2751: Sex Code is not recorded in D_PATIENT nor nrt_patient. Temporary solution.
            COALESCE(d_patient.PATIENT_AGE_REPORTED,p.age_reported) AS Age_Reported,
            COALESCE(d_patient.PATIENT_AGE_REPORTED_UNIT,p.age_reported_unit) AS Age_Unit_Cd,
            COALESCE(d_patient.PATIENT_DOB,p.dob) AS Birth_Dt,
            COALESCE(d_patient.PATIENT_DECEASED_DATE,p.deceased_date) AS PATIENT_DEATH_DATE,
            cvg2.CODE_VAL AS PATIENT_DEATH_IND, --Death Code is not recorded in D_PATIENT nor nrt_patient. Temporary solution.
            COALESCE(d_patient.PATIENT_PHONE_HOME,p.phone_home) AS Phone_Number,
            COALESCE(d_patient.PATIENT_STREET_ADDRESS_1,p.street_address_1) AS Address_One,
            COALESCE(d_patient.PATIENT_STREET_ADDRESS_2,p.street_address_2) AS Address_Two,
            COALESCE(d_patient.PATIENT_CITY,p.city) AS City,
            COALESCE(d_patient.PATIENT_STATE_CODE,p.state_code) AS State_Cd,
            COALESCE(dim_state.state_NM,nrt_state.state_NM) AS State,
            COALESCE(d_patient.PATIENT_ZIP,p.zip) AS Zip_Code,
            COALESCE(d_patient.PATIENT_COUNTY_CODE,p.county_code) AS County_Cd,
            COALESCE(d_patient.PATIENT_COUNTY,p.county) AS County_Desc,
            COALESCE(d_patient.PATIENT_RACE_CALCULATED,p.race_calculated) AS PATIENT_RACE_CALC,
            COALESCE(d_patient.PATIENT_ETHNICITY,p.ethnicity) AS PATIENT_ETHNICITY
        INTO #COVID_LAB_PATIENT_DATA
        FROM #COVID_OBSERVATIONS_TO_PROCESS o
            INNER JOIN dbo.nrt_observation obs WITH(NOLOCK) ON o.observation_uid = obs.observation_uid
            LEFT JOIN dbo.d_patient d_patient WITH(NOLOCK) ON obs.patient_id = d_patient.PATIENT_UID
            LEFT JOIN dbo.nrt_patient p WITH(NOLOCK) ON obs.patient_id = p.patient_uid
            LEFT OUTER JOIN dbo.nrt_srte_State_code dim_state WITH(NOLOCK) ON dim_state.state_cd = d_patient.PATIENT_STATE_CODE
            LEFT OUTER JOIN dbo.nrt_srte_State_code nrt_state WITH(NOLOCK) ON nrt_state.state_cd = p.state_code
            OUTER APPLY (
            SELECT
                COALESCE(d_patient.PATIENT_CURRENT_SEX,p.current_sex) AS PATIENT_CURRENT_SEX,
                COALESCE(d_patient.PATIENT_DECEASED_INDICATOR,p.deceased_indicator) AS PATIENT_DECEASED_INDICATOR
            ) AS pd
            LEFT JOIN dbo.v_code_value_general cvg1 WITH (NOLOCK) ON cvg1.CODE_DESC = pd.PATIENT_CURRENT_SEX AND cvg1.cd='DEM113'             --Person.PERSON_CURR_GENDER
            LEFT JOIN dbo.v_code_value_general cvg2 WITH (NOLOCK) ON cvg2.CODE_DESC = pd.PATIENT_DECEASED_INDICATOR AND cvg2.cd='DEM127';     --Person.PATIENT_DECEASED_IND

        IF @debug = 'true' SELECT @proc_step_name, * FROM #COVID_LAB_PATIENT_DATA;

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,LEFT(ISNULL(@observation_id_list, 'NULL'),500),0);

        /* Create entities data */
        SET @proc_step_name = 'Create COVID_LAB_ENTITIES_DATA';
        SET @proc_step_no = 6;

        IF OBJECT_ID('tempdb..#COVID_LAB_ENTITIES_DATA', 'U') IS NOT NULL
            DROP TABLE #COVID_LAB_ENTITIES_DATA;


        -- Lab Entities Data
        SELECT DISTINCT
            o.Observation_UID AS Entity_Observation_uid,
            COALESCE(d_org_author.ORGANIZATION_NAME,org_author.organization_name) AS Reporting_Facility_Name,
            COALESCE(d_org_author.ORGANIZATION_STREET_ADDRESS_1, org_author.street_address_1) AS Reporting_Facility_Address_One,
            COALESCE(d_org_author.ORGANIZATION_STREET_ADDRESS_2, org_author.street_address_2) AS Reporting_Facility_Address_Two,
            COALESCE(d_org_author.ORGANIZATION_COUNTRY,org_author.country) AS Reporting_Facility_Country,
            COALESCE(d_org_author.ORGANIZATION_COUNTY_CODE, org_author.county_code) AS Reporting_Facility_County,
            COALESCE(d_org_author.ORGANIZATION_COUNTY, org_author.county) AS Reporting_Facility_County_Desc,
            COALESCE(d_org_author.ORGANIZATION_CITY, org_author.city) AS Reporting_Facility_City,
            COALESCE(d_org_author.ORGANIZATION_STATE_CODE, org_author.state_code) AS Reporting_Facility_State_Cd,
            COALESCE(dim_state_org_author.state_NM, nrt_state_org_author.state_NM) AS Reporting_Facility_State,
            COALESCE(d_org_author.ORGANIZATION_ZIP, org_author.zip) AS Reporting_Facility_Zip_Cd,
            COALESCE(d_org_author.ORGANIZATION_FACILITY_ID, org_author.facility_id) AS Reporting_Facility_Clia,
            COALESCE(d_org_author.ORGANIZATION_PHONE_WORK, org_author.phone_work) AS Reporting_Facility_Phone_Nbr,
            COALESCE(d_org_author.ORGANIZATION_PHONE_EXT_WORK, org_author.phone_ext_work) AS Reporting_Facility_Phone_Ext,
            COALESCE(d_org_order.ORGANIZATION_NAME, org_order.organization_name) AS Ordering_Facility_Name,
            COALESCE(d_org_order.ORGANIZATION_STREET_ADDRESS_1, org_order.street_address_1) AS Ordering_Facility_Address_One,
            COALESCE(d_org_order.ORGANIZATION_STREET_ADDRESS_2, org_order.street_address_2) AS Ordering_Facility_Address_Two,
            COALESCE(d_org_order.ORGANIZATION_COUNTRY, org_order.country) AS Ordering_Facility_Country,
            COALESCE(d_org_order.ORGANIZATION_COUNTY_CODE, org_order.county_code) AS Ordering_Facility_County,
            COALESCE(d_org_order.ORGANIZATION_COUNTY, org_order.county) AS Ordering_Facility_County_Desc,
            COALESCE(d_org_order.ORGANIZATION_CITY, org_order.city) AS Ordering_Facility_City,
            COALESCE(d_org_order.ORGANIZATION_STATE_CODE, org_order.state_code) AS Ordering_Facility_State_Cd,
            COALESCE(dim_state_org_order.state_NM, nrt_state_org_order.state_NM) AS Ordering_Facility_State,
            COALESCE(d_org_order.ORGANIZATION_ZIP, org_order.zip) AS Ordering_Facility_Zip_Cd,
            COALESCE(d_org_order.ORGANIZATION_PHONE_WORK, org_order.phone_work) AS Ordering_Facility_Phone_Nbr,
            COALESCE(d_org_order.ORGANIZATION_PHONE_EXT_WORK, org_order.phone_ext_work) AS Ordering_Facility_Phone_Ext,
            COALESCE(d_provider_order.PROVIDER_FIRST_NAME,provider_order.first_name) AS Ordering_Provider_First_Name,
            COALESCE(d_provider_order.PROVIDER_LAST_NAME,provider_order.last_name) AS Ordering_Provider_Last_Name,
            COALESCE(d_provider_order.PROVIDER_STREET_ADDRESS_1,provider_order.street_address_1) AS Ordering_Provider_Address_One,
            COALESCE(d_provider_order.PROVIDER_STREET_ADDRESS_2,provider_order.street_address_2) AS Ordering_Provider_Address_Two,
            provider_order.country_code AS Ordering_Provider_Country,
            COALESCE(d_provider_order.PROVIDER_COUNTY_CODE,provider_order.county_code) AS Ordering_Provider_County,
            COALESCE(d_provider_order.PROVIDER_COUNTY,provider_order.county) AS Ordering_Provider_County_Desc,
            COALESCE(d_provider_order.PROVIDER_CITY,provider_order.city) AS Ordering_Provider_City,
            COALESCE(d_provider_order.PROVIDER_STATE_CODE,provider_order.state_code) AS Ordering_Provider_State_Cd,
            COALESCE(dim_state_provider_order.state_NM, nrt_state_provider_order.state_NM) AS Ordering_Provider_State,
            COALESCE(d_provider_order.PROVIDER_ZIP,provider_order.zip) AS Ordering_Provider_Zip_Cd,
            COALESCE(d_provider_order.PROVIDER_PHONE_WORK,provider_order.phone_work) AS Ordering_Provider_Phone_Nbr,
            COALESCE(d_provider_order.PROVIDER_PHONE_EXT_WORK,provider_order.phone_ext_work) AS Ordering_Provider_Phone_Ext,
            provider_order.provider_npi AS ORDERING_PROVIDER_ID
        INTO #COVID_LAB_ENTITIES_DATA
        FROM #COVID_LAB_CORE_DATA o
            LEFT JOIN dbo.nrt_observation obs WITH(NOLOCK) ON o.Observation_UID = obs.observation_uid
            /*Auth Org*/
            LEFT JOIN dbo.nrt_organization org_author WITH(NOLOCK) ON obs.author_organization_id = org_author.organization_uid
            LEFT JOIN dbo.D_Organization d_org_author WITH(NOLOCK) ON obs.author_organization_id = d_org_author.ORGANIZATION_UID
            LEFT OUTER JOIN dbo.nrt_srte_State_code dim_state_org_author WITH(NOLOCK) ON dim_state_org_author.state_cd = d_org_author.ORGANIZATION_STATE_CODE
            LEFT OUTER JOIN dbo.nrt_srte_State_code nrt_state_org_author WITH(NOLOCK) ON nrt_state_org_author.state_cd = org_author.state_code
            /*Ordering Org*/
            LEFT JOIN dbo.nrt_organization org_order WITH(NOLOCK) ON obs.ordering_organization_id = org_order.organization_uid
            LEFT JOIN dbo.D_Organization d_org_order WITH(NOLOCK) ON obs.ordering_organization_id = d_org_order.ORGANIZATION_UID
            LEFT OUTER JOIN dbo.nrt_srte_State_code dim_state_org_order WITH(NOLOCK) ON dim_state_org_order.state_cd = d_org_order.ORGANIZATION_STATE_CODE
            LEFT OUTER JOIN dbo.nrt_srte_State_code nrt_state_org_order WITH(NOLOCK) ON nrt_state_org_order.state_cd = org_order.state_code
            /*Ordering Provider*/
            LEFT JOIN dbo.nrt_provider AS provider_order with (nolock)
                ON EXISTS (SELECT 1 FROM STRING_SPLIT(obs.ordering_person_id, ',') nprv WHERE cast(nprv.value AS BIGINT) = provider_order.provider_uid)
            LEFT JOIN dbo.D_PROVIDER AS d_provider_order with (nolock)
                ON EXISTS (SELECT 1 FROM STRING_SPLIT(obs.ordering_person_id, ',') nprv WHERE cast(nprv.value AS BIGINT) = d_provider_order.provider_uid)
            LEFT OUTER JOIN dbo.nrt_srte_State_code dim_state_provider_order WITH(NOLOCK) ON dim_state_provider_order.state_cd = d_provider_order.PROVIDER_STATE_CODE
            LEFT OUTER JOIN dbo.nrt_srte_State_code nrt_state_provider_order WITH(NOLOCK) ON nrt_state_provider_order.state_cd = provider_order.state_code
            OUTER APPLY (
            SELECT COALESCE(d_provider_order.PROVIDER_COUNTRY,provider_order.country) AS Provider_Country
            ) AS pd


        IF @debug = 'true' SELECT @proc_step_name, * FROM #COVID_LAB_ENTITIES_DATA;

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,LEFT(ISNULL(@observation_id_list, 'NULL'),500),0);

        /* Create associations data */
        SET @proc_step_name = 'Create COVID_LAB_ASSOCIATIONS';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        SELECT DISTINCT
            core.Observation_UID AS ASSOC_OBSERVATION_UID,
            o.associated_phc_uids AS Associated_Case_ID
        INTO #COVID_LAB_ASSOCIATIONS
        FROM #COVID_LAB_CORE_DATA core
                 INNER JOIN dbo.nrt_observation o WITH(NOLOCK) ON o.observation_uid = core.Observation_UID;

        IF @debug = 'true'
            SELECT @proc_step_name, * FROM #COVID_LAB_ASSOCIATIONS;

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,LEFT(ISNULL(@observation_id_list, 'NULL'),500),0);

        /* Create AOE data table - FIXED: Create outside of IF block to fix scope issue */
        SET @proc_step_name = 'Create COVID_LAB_AOE_DATA';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        -- Create the AOE table structure outside of conditional logic to fix scope issue
        IF OBJECT_ID('tempdb..#COVID_LAB_AOE_DATA', 'U') IS NOT NULL
            DROP TABLE #covid_lab_aoe_data;

        CREATE TABLE #covid_lab_aoe_data
        (
            aoe_observation_uid BIGINT NULL
        );

        -- Insert observations into AOE table
        INSERT INTO #covid_lab_aoe_data
        (
            aoe_observation_uid
        )
        SELECT DISTINCT observation_uid
        FROM            #covid_observations_to_process;

        -- Check if nrt_odse_lookup_question table has data for LAB_REPORT form
        IF EXISTS
            (
                SELECT 1
                FROM   dbo.nrt_odse_lookup_question
                WHERE  from_form_cd = 'LAB_REPORT')
            BEGIN
                -- AOE metadata exists, proceed with full AOE processing
                -- Create staging table (following original COVID_LAB_AOE_ST pattern)
                IF Object_id('tempdb..#COVID_LAB_AOE_ST', 'U') IS NOT NULL
                    DROP TABLE #covid_lab_aoe_st;

                SELECT DISTINCT o.observation_uid AS aoe_observation_uid,
                                o1.cd,
                                lq.rdb_column_nm,
                                CASE
                                    WHEN ovn.ovn_numeric_value_1 IS NOT NULL THEN Cast(ovn.ovn_numeric_value_1 AS VARCHAR(20)) + '^' + Isnull(ovn.ovn_numeric_unit_cd, '')
                                    WHEN not2.ovt_value_txt IS NOT NULL THEN not2.ovt_value_txt
                                    WHEN noc.ovc_code IS NOT NULL THEN cvg.code_short_desc_txt
                                    END AS answer_txt
                INTO            #covid_lab_aoe_st
                FROM            dbo.nrt_odse_lookup_question lq
                                    LEFT OUTER JOIN dbo.nrt_observation o1 WITH(nolock)
                                                    ON              o1.cd = lq.from_question_identifier
                                                        AND             o1.obs_domain_cd_st_1 = 'Result'
                                    LEFT OUTER JOIN dbo.nrt_observation o WITH(nolock)
                                                    ON              EXISTS
                                                        (
                                                            SELECT 1
                                                            FROM   String_split(Isnull(Cast(o1.report_observation_uid AS VARCHAR(max)), ''), ',')
                                                            WHERE  try_cast(Ltrim(Rtrim(value)) as bigint) = o.observation_uid )
                                    LEFT OUTER JOIN dbo.nrt_observation_coded noc WITH(nolock)
                                                    ON              noc.observation_uid = o1.observation_uid
                                                        AND             isnull(o1.batch_id, 1) = isnull(noc.batch_id, 1)
                                    LEFT OUTER JOIN dbo.nrt_observation_txt not2 WITH(nolock)
                                                    ON              not2.observation_uid = o1.observation_uid
                                                        AND             (
                                                                        not2.ovt_txt_type_cd = 'O'
                                                                            OR              not2.ovt_txt_type_cd IS NULL)
                                                        AND             isnull(o1.batch_id, 1) = isnull(not2.batch_id, 1)
                                    LEFT OUTER JOIN dbo.nrt_observation_numeric ovn WITH(nolock)
                                                    ON              ovn.observation_uid = o1.observation_uid
                                                        AND             isnull(o1.batch_id, 1) = isnull(ovn.batch_id, 1)
                                    LEFT OUTER JOIN dbo.nrt_srte_code_value_general cvg WITH(nolock)
                                                    ON              cvg.code_set_nm = lq.from_code_set
                                                        AND             noc.ovc_code = cvg.code
                WHERE           o.observation_uid IN
                                (
                                    SELECT observation_uid
                                    FROM   #covid_observations_to_process)
                  and             lq.from_form_cd = 'LAB_REPORT';


                -- Get list of columns to add to AOE table and add them

                DECLARE @aoe_columns NVARCHAR(MAX);
                DECLARE @aoe_sql NVARCHAR(MAX);
                SET @aoe_columns = N'';

                SELECT @aoe_columns += N',[' + LTRIM(RTRIM([RDB_COLUMN_NM])) + '] VARCHAR(MAX) NULL'
                FROM (
                         SELECT DISTINCT [RDB_COLUMN_NM]
                         FROM dbo.nrt_odse_lookup_question AS p WITH(NOLOCK)
                         WHERE FROM_FORM_CD = 'LAB_REPORT'
                           AND LTRIM(RTRIM([RDB_COLUMN_NM])) IS NOT NULL
                           AND LTRIM(RTRIM([RDB_COLUMN_NM])) <> ''
                     ) AS x;

                -- Add columns to AOE table if any exist
                IF LEN(@aoe_columns) > 0
                    BEGIN
                        -- Remove leading comma
                        SET @aoe_columns = SUBSTRING(@aoe_columns, 2, LEN(@aoe_columns));
                        SET @aoe_sql = N'ALTER TABLE #COVID_LAB_AOE_DATA ADD ' + @aoe_columns;
                        EXEC sp_executesql @aoe_sql;

                        IF @debug = 'true'
                            PRINT 'AOE columns added : ' + @aoe_sql;
                    END

                -- Update AOE table with data using dynamic pivot
                DECLARE @pivot_columns NVARCHAR(max);
                DECLARE @pivot_sql     NVARCHAR(max);
                SET @pivot_columns = N'';
                SELECT @pivot_columns += N', [' + Ltrim(Rtrim([RDB_COLUMN_NM])) + ']'
                FROM   (
                           SELECT DISTINCT [RDB_COLUMN_NM]
                           FROM            dbo.nrt_odse_lookup_question AS p WITH(nolock)
                           WHERE           from_form_cd = 'LAB_REPORT'
                             AND             Ltrim(Rtrim([RDB_COLUMN_NM])) IS NOT NULL
                             AND             Ltrim(Rtrim([RDB_COLUMN_NM])) <> '' ) AS x;

                -- Update AOE table with pivoted data if columns exist
                IF Len(@pivot_columns) > 0
                    BEGIN
                        SET @pivot_sql = N'  UPDATE aoe  SET ' + Stuff(@pivot_columns, 1, 2, '') + N'  FROM #COVID_LAB_AOE_DATA aoe  INNER JOIN (  SELECT [AOE_Observation_uid]' + @pivot_columns + N'  FROM (  SELECT [AOE_Observation_uid], answer_txt, [RDB_COLUMN_NM]  FROM #COVID_LAB_AOE_ST AS p WITH (NOLOCK)  GROUP BY [AOE_Observation_uid], [answer_txt], [RDB_COLUMN_NM]  ) AS j  PIVOT (MAX(answer_txt) FOR [RDB_COLUMN_NM] IN (' + Stuff(@pivot_columns, 1, 2, '') + N')) AS p  ) AS pivoted ON aoe.AOE_Observation_uid = pivoted.AOE_Observation_uid';
                        -- Remove column assignments from SET clause for UPDATE
                        SET @pivot_sql = Replace(@pivot_sql, 'SET [', 'SET [');
                        SET @pivot_sql = Replace(@pivot_sql, '], [', '] = pivoted.[' + Char(13) + Char(10) + ', [');
                        SET @pivot_sql = Replace(@pivot_sql, 'SET [', 'SET [');
                        -- Fix the SET clause properly
                        DECLARE @set_clause NVARCHAR(max) = '';
                        SELECT @set_clause += N', [' + Ltrim(Rtrim([RDB_COLUMN_NM])) + '] = pivoted.[' + Ltrim(Rtrim([RDB_COLUMN_NM])) + ']'
                        FROM   (
                                   SELECT DISTINCT [RDB_COLUMN_NM]
                                   FROM            dbo.nrt_odse_lookup_question AS p WITH(nolock)
                                   WHERE           from_form_cd = 'LAB_REPORT'
                                     AND             Ltrim(Rtrim([RDB_COLUMN_NM])) IS NOT NULL
                                     AND             Ltrim(Rtrim([RDB_COLUMN_NM])) <> '' ) AS x;

                        SET @pivot_sql = N'  UPDATE aoe  SET ' + Stuff(@set_clause, 1, 2, '') + N'  FROM #COVID_LAB_AOE_DATA aoe  INNER JOIN (  SELECT [AOE_Observation_uid]' + @pivot_columns + N'  FROM (  SELECT [AOE_Observation_uid], answer_txt, [RDB_COLUMN_NM]  FROM #COVID_LAB_AOE_ST AS p WITH (NOLOCK)  GROUP BY [AOE_Observation_uid], [answer_txt], [RDB_COLUMN_NM]  ) AS j  PIVOT (MAX(answer_txt) FOR [RDB_COLUMN_NM] IN (' + Stuff(@pivot_columns, 1, 2, '') + N')) AS p  ) AS pivoted ON aoe.AOE_Observation_uid = pivoted.AOE_Observation_uid';
                        EXEC sp_executesql @pivot_sql;
                        IF @debug = 'true'
                            PRINT 'AOE pivot update completed: ' + @pivot_sql;
                    END

                IF @debug = 'true' SELECT 'Full AOE processing completed' AS debug_message;

            END
        ELSE
            BEGIN
                IF @debug = 'true'
                    SELECT 'No AOE metadata - minimal structure maintained' AS debug_message;

            END
        /* Logging */
        SET @rowcount = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,LEFT(ISNULL(@observation_id_list, 'NULL'),500),0);

        BEGIN TRANSACTION;
        SET @proc_step_name = 'Alter Datamart Columns for All Temp Tables';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        DECLARE @TEMP_QUERY_TABLE TABLE
                                  (
                                      id         INT IDENTITY(1, 1),
                                      query_stmt VARCHAR(5000)
                                  );

        DECLARE @column_query  VARCHAR(5000);
        DECLARE @Max_Query_No  INT;
        DECLARE @Curr_Query_No INT;

        -- FIXED: Generate ALTER statements only for columns that truly don't exist
        INSERT INTO @Temp_Query_Table
        SELECT     'ALTER TABLE dbo.COVID_LAB_DATAMART ADD [' + c.NAME + '] ' + Upper(t.NAME) +
                   CASE
                       WHEN t.NAME IN('char',
                                      'varchar',
                                      'nchar',
                                      'nvarchar') THEN ' (' +
                                                       CASE
                                                           WHEN c.max_length = -1 THEN 'MAX'
                                                           WHEN t.NAME IN ('nchar',
                                                                           'nvarchar') THEN Cast(c.max_length/2 AS VARCHAR(10))
                                                           ELSE Cast(c.max_length AS                               VARCHAR(10))
                                                           END + ')'
                       ELSE ''
                       END +
                   CASE
                       WHEN c.is_nullable = 0 THEN ' NOT NULL'
                       ELSE ' NULL'
                       END
        FROM       tempdb.sys.tables st
                       INNER JOIN tempdb.sys.columns c
                                  ON         st.object_id = c.object_id
                       INNER JOIN tempdb.sys.types t
                                  ON         c.user_type_id = t.user_type_id
        WHERE      (
            st.NAME LIKE '#COVID_LAB_CORE_DATA%'
                OR         st.NAME LIKE '#COVID_LAB_PATIENT_DATA%'
                OR         st.NAME LIKE '#COVID_LAB_ENTITIES_DATA%'
                OR         st.NAME LIKE '#COVID_LAB_ASSOCIATIONS%'
                OR         st.NAME LIKE '#COVID_LAB_AOE_DATA%')
          AND        NOT EXISTS
            (
                SELECT 1
                FROM   information_schema.columns dc
                WHERE  dc.table_name = 'COVID_LAB_DATAMART'
                  AND    dc.table_schema = 'dbo'
                  AND    dc.column_name = c.NAME )
            /*AND        c.NAME NOT IN( 'AOE_Observation_uid',
                                     'RT_Observation_UID',
                                     'Pat_Observation_UID',
                                     'Entity_Observation_uid',
                     'ASSOC_OBSERVATION_UID' )*/
          AND NOT (
            --  (st.NAME LIKE '#COVID_LAB_CORE_DATA%' AND  c.NAME IN ('observation_uid', 'record_status_cd'))
            (st.NAME LIKE '#COVID_LAB_CORE_DATA%' AND  c.NAME = 'record_status_cd')
                OR (st.NAME LIKE '#COVID_LAB_PATIENT_DATA%' AND c.NAME = 'pat_observation_uid')
                OR (st.NAME LIKE '#COVID_LAB_ENTITIES_DATA%' AND c.NAME = 'entity_observation_uid')
                OR (st.NAME LIKE '#COVID_LAB_ASSOCIATIONS%' AND c.NAME = 'assoc_observation_uid')
                OR (st.NAME LIKE '#COVID_LAB_AOE_DATA%' AND c.NAME = 'aoe_observation_uid')
            )
          AND        st.NAME IN
                     (
                         SELECT NAME
                         FROM   tempdb.sys.tables
                         WHERE  Object_id('tempdb..' + NAME) IS NOT NULL );

        -- Execute ALTER statements using corrected loop logic
        SET @Max_Query_No =
                (
                    SELECT Max(id)
                    FROM   @Temp_Query_Table);

        SET @Curr_Query_No = 0;
        WHILE @Curr_Query_No < @Max_Query_No
            BEGIN
                SET @Curr_Query_No = @Curr_Query_No + 1;
                SET @column_query =
                        (
                            SELECT query_stmt
                            FROM   @Temp_Query_Table
                            WHERE  id = @Curr_Query_No);
                BEGIN try
                    EXEC (@column_query);
                    IF @debug = 'true'
                        PRINT 'Executed: ' + @column_query;
                END try
                BEGIN catch
                    IF @debug = 'true'  PRINT 'Error executing: ' + @column_query + ' - ' + Error_message();
                    -- Continue processing other columns even if one fails
                END catch
            END
        IF @debug = 'true'
            SELECT 'Dynamic column check completed for all temp tables' AS debug_message,
                   Isnull(@Max_Query_No, 0)                             AS total_alter_statements;

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,LEFT(ISNULL(@observation_id_list, 'NULL'),500),0);
        COMMIT TRANSACTION;

        /* Start transaction for the actual update to the datamart */
        SET @proc_step_name = 'Update COVID_LAB_DATAMART';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        BEGIN TRANSACTION;
        /* Delete existing records for these observations */
        DELETE
        FROM   dbo.covid_lab_datamart
        WHERE  observation_uid IN
               (
                   SELECT observation_uid
                   FROM   #covid_lab_core_data);


        DECLARE @insert_query NVARCHAR(MAX);
        SET @insert_query =
                (
                    SELECT 'INSERT INTO  [dbo].[COVID_LAB_DATAMART]( ' + STUFF(
                            (
                                SELECT ', [' + name + ']'
                                FROM tempdb.sys.columns
                                WHERE object_id = OBJECT_ID('tempdb..#COVID_LAB_CORE_DATA')
                                  AND NAME NOT IN('record_status_cd') FOR XML PATH('')
                            ), 1, 1, '') + ', [Result_Category], ' + STUFF(
                                   (
                                       SELECT ', [' + name + ']'
                                       FROM tempdb.sys.columns
                                       WHERE object_id = OBJECT_ID('tempdb..#COVID_LAB_PATIENT_DATA')
                                         AND NAME NOT IN('Pat_Observation_UID') FOR XML PATH('')
                                   ), 1, 1, '') + ',' + STUFF(
                                   (
                                       SELECT ', [' + name + ']'
                                       FROM tempdb.sys.columns
                                       WHERE object_id = OBJECT_ID('tempdb..#COVID_LAB_ENTITIES_DATA')
                                         AND NAME NOT IN('Entity_Observation_uid') FOR XML PATH('')
                                   ), 1, 1, '') + ',' + STUFF(
                                   (
                                       SELECT ', [' + name + ']'
                                       FROM tempdb.sys.columns
                                       WHERE object_id = OBJECT_ID('tempdb..#COVID_LAB_AOE_DATA')
                                         AND NAME NOT IN('AOE_Observation_uid') FOR XML PATH('')
                                   ), 1, 1, '') + ', [Associated_Case_ID]' + ' ) select distinct ' + STUFF(
                                   (
                                       SELECT ', [' + name + ']'
                                       FROM tempdb.sys.columns
                                       WHERE object_id = OBJECT_ID('tempdb..#COVID_LAB_CORE_DATA')
                                         AND NAME NOT IN('record_status_cd') FOR XML PATH('')
                                   ), 1, 1, '') + ', [Result_Category], ' + STUFF(
                                   (
                                       SELECT ', [' + name + ']'
                                       FROM tempdb.sys.columns
                                       WHERE object_id = OBJECT_ID('tempdb..#COVID_LAB_PATIENT_DATA')
                                         AND NAME NOT IN('Pat_Observation_UID') FOR XML PATH('')
                                   ), 1, 1, '') + ',' + STUFF(
                                   (
                                       SELECT ', [' + name + ']'
                                       FROM tempdb.sys.columns
                                       WHERE object_id = OBJECT_ID('tempdb..#COVID_LAB_ENTITIES_DATA')
                                         AND NAME NOT IN('Entity_Observation_uid') FOR XML PATH('')
                                   ), 1, 1, '') + ',' + STUFF(
                                   (
                                       SELECT ', [' + name + ']'
                                       FROM tempdb.sys.columns
                                       WHERE object_id = OBJECT_ID('tempdb..#COVID_LAB_AOE_DATA')
                                         AND NAME NOT IN('AOE_Observation_uid') FOR XML PATH('')
                                   ), 1, 1, '') + ', [Associated_Case_ID] ' + '
	           FROM #COVID_LAB_CORE_DATA COVID_LAB_CORE_DATA
                 LEFT OUTER JOIN #COVID_LAB_RSLT_TYPE COVID_LAB_RSLT_TYPE ON COVID_LAB_CORE_DATA.Observation_UID = COVID_LAB_RSLT_TYPE.RT_Observation_UID
                                                                AND COVID_LAB_CORE_DATA.Result = COVID_LAB_RSLT_TYPE.RT_Result
                 INNER JOIN #COVID_LAB_PATIENT_DATA COVID_LAB_PATIENT_DATA ON COVID_LAB_CORE_DATA.Observation_UID = COVID_LAB_PATIENT_DATA.Pat_Observation_UID
                 LEFT OUTER JOIN #COVID_LAB_ENTITIES_DATA COVID_LAB_ENTITIES_DATA ON COVID_LAB_CORE_DATA.Observation_UID = COVID_LAB_ENTITIES_DATA.Entity_Observation_uid
				 LEFT OUTER JOIN #COVID_LAB_AOE_DATA COVID_LAB_AOE_DATA ON COVID_LAB_CORE_DATA.Observation_UID = COVID_LAB_AOE_DATA.AOE_Observation_uid
                 LEFT OUTER JOIN #COVID_LAB_ASSOCIATIONS COVID_LAB_ASSOCIATIONS ON COVID_LAB_CORE_DATA.Observation_UID = COVID_LAB_ASSOCIATIONS.ASSOC_OBSERVATION_UID;'
                );

        IF @debug = 'true' PRINT 'Insert Query: ' + @insert_query;
        EXEC sp_executesql @insert_query;

        /* Logging for insert operation */
        SET @rowcount = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,LEFT(ISNULL(@observation_id_list, 'NULL'),500),0);

        COMMIT TRANSACTION;

        /* Final logging */
        SET @proc_step_name = 'SP_COMPLETE';
        SET @proc_step_no = 999;
        INSERT INTO [dbo].[job_flow_log]
        (
            batch_id ,
            [Dataflow_Name] ,
            [package_Name] ,
            [Status_Type] ,
            [step_number] ,
            [step_name] ,
            [row_count] ,
            [msg_description1]
        )
        VALUES
            (
                @batch_id ,
                @dataflow_name ,
                @package_name ,
                'COMPLETE' ,
                @proc_step_no ,
                @proc_step_name ,
                0 ,
                LEFT(Isnull(@observation_id_list, 'NULL'),500)
            );

    END try
    BEGIN catch
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @FullErrorMessage NVARCHAR(4000) = 'Error Number: ' + Cast(Error_number() AS VARCHAR(10)) + Char(13) + Char(10) + 'Error Severity: ' + Cast(Error_severity() AS VARCHAR(10)) + Char(13) + Char(10) + 'Error State: ' + Cast(Error_state() AS VARCHAR(10)) + Char(13) + Char(10) + 'Error Line: ' + Cast(Error_line() AS VARCHAR(10)) + Char(13) + Char(10) + 'Error Message: ' + Error_message();
        /* Logging */
        INSERT INTO [dbo].[job_flow_log]
        (
            batch_id ,
            [Dataflow_Name] ,
            [package_Name] ,
            [Status_Type] ,
            [step_number] ,
            [step_name] ,
            [row_count] ,
            [msg_description1] ,
            [Error_Description]
        )
        VALUES
            (
                @batch_id ,
                @dataflow_name ,
                @package_name ,
                'ERROR' ,
                @proc_Step_no ,
                @proc_step_name ,
                0 ,
                LEFT(Isnull(@observation_id_list, 'NULL'),500) ,
                @FullErrorMessage
            );

        RETURN Error_number();
    END catch;
END;