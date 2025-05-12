CREATE OR ALTER PROCEDURE [dbo].[sp_covid_lab_datamart_postprocessing]
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
    DECLARE @conditionCd VARCHAR(200);

    SET @conditionCd = '11065'; -- COVID-19 condition code

    SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);

    -- Initialize logging
    INSERT INTO [dbo].[job_flow_log] (
                                       batch_id
                                     ,[Dataflow_Name]
                                     ,[package_Name]
                                     ,[Status_Type]
                                     ,[step_number]
                                     ,[step_name]
                                     ,[msg_description1]
                                     ,[row_count]
    )
    VALUES (
             @batch_id
           ,@dataflow_name
           ,@package_name
           ,'START'
           ,0
           ,'SP_Start'
           ,LEFT(ISNULL(@observation_id_list, 'NULL'),500)
           ,0
           );

    BEGIN TRY

        SET @proc_step_name = 'Create COVID_LAB_TEMP_DATA';
        SET @proc_step_no = 1;

        /* Create session table for observations to process */
        IF OBJECT_ID('tempdb..#COVID_OBSERVATIONS_TO_PROCESS', 'U') IS NOT NULL
            DROP TABLE #COVID_OBSERVATIONS_TO_PROCESS;

        /* Create a table with the observations we need to process */
        CREATE TABLE #COVID_OBSERVATIONS_TO_PROCESS (
                                                        observation_uid bigint
        );

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
                INSERT INTO #COVID_OBSERVATIONS_TO_PROCESS (observation_uid)
                SELECT obs.observation_uid
                FROM STRING_SPLIT(@observation_id_list, ',') split_ids
                         INNER JOIN dbo.nrt_observation obs WITH(NOLOCK) ON TRY_CAST(split_ids.value AS BIGINT) = obs.observation_uid
                WHERE obs.record_status_cd <> 'LOG_DEL';
            END

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
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
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'PROCESSING'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(ISNULL(@observation_id_list, 'NULL'),500)
               );

        /* Debug output if requested */
        IF @debug = 'true'
            SELECT * FROM #COVID_OBSERVATIONS_TO_PROCESS;

        /* Create the next session table to hold text results */
        SET @proc_step_name = 'Extract Text Results';
        SET @proc_step_no = 2;

        IF OBJECT_ID('tempdb..#COVID_TEXT_RESULT_LIST', 'U') IS NOT NULL
            DROP TABLE #COVID_TEXT_RESULT_LIST;

        SELECT DISTINCT
            o_result.observation_uid,
            o.observation_uid AS target_observation_uid,
            o.local_id AS Lab_Local_ID,
            p.local_id AS Patient_Local_ID,
            replace(replace(otxt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ') AS 'Text_Result_Desc',
            replace(replace(otxt_comment.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ') AS 'Result_Comments'
        INTO #COVID_TEXT_RESULT_LIST
        FROM #COVID_OBSERVATIONS_TO_PROCESS cp
                 INNER JOIN dbo.nrt_observation o_result WITH(NOLOCK) ON cp.observation_uid = o_result.observation_uid
                 CROSS APPLY (
            SELECT CAST(value AS BIGINT) as target_obs_uid
            FROM STRING_SPLIT(o_result.result_observation_uid, ',')
        ) as split_results
                 INNER JOIN dbo.nrt_observation o WITH(NOLOCK) ON split_results.target_obs_uid = o.observation_uid
                 LEFT JOIN dbo.nrt_patient p WITH(NOLOCK) ON o.patient_id = p.patient_uid
                 LEFT OUTER JOIN dbo.nrt_observation_txt otxt WITH(NOLOCK) ON o_result.observation_uid = otxt.observation_uid
            AND (otxt.ovt_txt_type_cd = 'O' OR otxt.ovt_txt_type_cd IS NULL)
                 LEFT OUTER JOIN dbo.nrt_observation_txt otxt_comment WITH(NOLOCK) ON o_result.observation_uid = otxt_comment.observation_uid
            AND otxt_comment.ovt_txt_type_cd = 'N';

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
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
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'PROCESSING'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(ISNULL(@observation_id_list, 'NULL'),500)
               );

        /* Debug output if requested */
        IF @debug = 'true'
            SELECT * FROM #COVID_TEXT_RESULT_LIST;

        /* Create the core lab data table */
        SET @proc_step_name = 'Create COVID_LAB_CORE_DATA';
        SET @proc_step_no = 3;

        IF OBJECT_ID('tempdb..#COVID_LAB_CORE_DATA', 'U') IS NOT NULL
            DROP TABLE #COVID_LAB_CORE_DATA;

        SELECT DISTINCT
            o.observation_uid AS 'Observation_UID',
            o.local_id AS 'Lab_Local_ID',
            o.record_status_cd,
            o.cd AS 'Ordered_Test_Cd',
            o.cd_desc_txt AS 'Ordered_Test_Desc',
            o.cd_system_cd AS 'Ordered_Test_Code_System',
            o.electronic_ind AS 'Electronic_Ind',
            o.prog_area_cd AS 'Program_Area_Cd',
            o.jurisdiction_cd AS 'Jurisdiction_Cd',
            o.activity_to_time AS 'Lab_Report_Dt',
            o.rpt_to_state_time AS 'Lab_Rpt_Received_By_PH_Dt',
            o.activity_from_time AS 'ORDER_TEST_DATE',
            o.target_site_cd AS 'SPECIMEN_SOURCE_SITE_CD',
            o.target_site_desc_txt AS 'SPECIMEN_SOURCE_SITE_DESC',
            cvg1.code_short_desc_txt AS 'Order_result_status',
            j_code.code_desc_txt AS 'Jurisdiction_Nm',
            mat.material_cd AS 'Specimen_Cd',
            mat.material_nm AS 'Specimen_Desc',
            mat.material_desc AS 'Specimen_type_free_text',
            CASE
                WHEN act_id.root_extension_txt IS NULL
                    OR act_id.root_extension_txt = ''
                    THEN o.local_id
                ELSE act_id.root_extension_txt
                END AS 'Specimen_Id',
            CASE
                WHEN act_id.root_extension_txt IS NULL
                    OR act_id.root_extension_txt = ''
                    THEN o.local_id
                ELSE act_id.root_extension_txt
                END AS 'Testing_Lab_Accession_Number',
            o.add_time AS 'Lab_Added_Dt',
            o.last_chg_time AS 'Lab_Update_Dt',
            o.effective_from_time AS 'Specimen_Coll_Dt',
            o1.observation_uid AS 'COVID_LAB_DATAMART_KEY',
            o1.cd AS 'Resulted_Test_Cd',
            o1.cd_desc_txt AS 'Resulted_Test_Desc',
            o1.cd_system_cd AS 'Resulted_Test_Code_System',
            eii.root_extension_txt AS 'DEVICE_INSTANCE_ID_1',
            eii2.root_extension_txt AS 'DEVICE_INSTANCE_ID_2',
            cvg2.code_short_desc_txt AS 'Test_result_status',
            o1.method_desc_txt AS 'Test_Method_Desc',
            CASE WHEN o1.method_cd LIKE '%**%'
                     THEN LEFT(o1.method_cd, CHARINDEX('**', o1.method_cd)-1)
                 ELSE o1.method_cd
                END AS 'Device_Type_Id_1',
            CASE WHEN o1.method_cd LIKE '%**%'
                     THEN SUBSTRING(o1.method_cd, CHARINDEX('**', o1.method_cd)+2, LEN(o1.method_cd))
                 ELSE NULL
                END AS 'Device_Type_Id_2',
            org_perform.organization_name AS 'Perform_Facility_Name',
            place_perform.place_street_address_1 AS 'Testing_lab_Address_One',
            place_perform.place_street_address_2 AS 'Testing_lab_Address_Two',
            place_perform.place_country AS 'Testing_lab_Country',
            place_perform.place_county_code AS 'Testing_lab_county',
            county.code_desc_txt AS 'Testing_lab_county_Desc',
            place_perform.place_city AS 'Testing_lab_City',
            place_perform.place_state_code AS 'Testing_lab_State_Cd',
            state.state_NM AS 'Testing_lab_State',
            place_perform.place_zip AS 'Testing_lab_Zip_Cd',
            ovc.ovc_code AS 'Result_Cd',
            ovc.ovc_code_system_cd AS 'Result_Cd_Sys',
            ovc.ovc_display_name AS 'Result_Desc',
            Text_Result_Desc,
            ovn.ovn_comparator_cd_1 AS 'Numeric_Comparator_Cd',
            ovn.ovn_numeric_value_1 AS 'Numeric_Value_1',
            ovn.ovn_numeric_value_2 AS 'Numeric_Value_2',
            ovn.ovn_numeric_unit_cd AS 'Numeric_Unit_Cd',
            ovn.ovn_low_range AS 'Numeric_Low_Range',
            ovn.ovn_high_range AS 'Numeric_High_Range',
            ovn.ovn_separator_cd AS 'Numeric_Separator_Cd',
            o1.interpretation_cd AS 'Interpretation_Cd',
            o1.interpretation_desc_txt AS 'Interpretation_Desc',
            Result_Comments,
            LTRIM(ISNULL(ovc.ovc_display_name, '') + ' ' + ISNULL(Text_Result_Desc, '') + ' ' + ISNULL(Result_Comments, ' ')) AS 'Result'
        INTO #COVID_LAB_CORE_DATA
        FROM #COVID_TEXT_RESULT_LIST
                 INNER JOIN dbo.nrt_observation o WITH(NOLOCK) ON #COVID_TEXT_RESULT_LIST.target_observation_uid = o.observation_uid
                 INNER JOIN dbo.nrt_observation o1 WITH(NOLOCK) ON #COVID_TEXT_RESULT_LIST.observation_uid = o1.observation_uid
            AND o1.obs_domain_cd_st_1 = 'Result'
                 LEFT OUTER JOIN dbo.nrt_observation_coded ovc WITH(NOLOCK) ON o1.observation_uid = ovc.observation_uid
                 LEFT OUTER JOIN dbo.nrt_srte_Jurisdiction_code j_code WITH(NOLOCK) ON j_code.code = o.jurisdiction_cd
                 LEFT OUTER JOIN dbo.nrt_srte_Code_value_general cvg1 WITH(NOLOCK) ON cvg1.code = o.status_cd
            AND cvg1.code_set_nm = 'ACT_OBJ_ST'
                 LEFT OUTER JOIN dbo.nrt_srte_Code_value_general cvg2 WITH(NOLOCK) ON cvg2.code = o1.status_cd
            AND cvg2.code_set_nm = 'ACT_OBJ_ST'
                 LEFT OUTER JOIN dbo.nrt_observation_numeric ovn WITH(NOLOCK) ON o1.observation_uid = ovn.observation_uid
                 LEFT OUTER JOIN dbo.nrt_observation_material mat WITH(NOLOCK) ON o.material_id = mat.material_id
                 LEFT OUTER JOIN dbo.nrt_act_id act_id WITH(NOLOCK) ON o.observation_uid = act_id.act_uid
            AND act_id.type_cd = 'FN'
                 LEFT OUTER JOIN dbo.nrt_act_id eii WITH(NOLOCK) ON o1.observation_uid = eii.act_uid
            AND eii.type_cd = 'EII'
            AND eii.act_id_seq = 3
                 LEFT OUTER JOIN dbo.nrt_act_id eii2 WITH(NOLOCK) ON o1.observation_uid = eii2.act_uid
            AND eii2.type_cd = 'EII'
            AND eii2.act_id_seq = 4
                 LEFT OUTER JOIN dbo.nrt_organization org_perform WITH(NOLOCK) ON o1.performing_organization_id = org_perform.organization_uid
                 LEFT OUTER JOIN dbo.D_Organization d_org_perform WITH(NOLOCK) ON org_perform.organization_uid = d_org_perform.organization_id
                 LEFT OUTER JOIN dbo.nrt_place place_perform WITH(NOLOCK) ON org_perform.organization_uid = place_perform.place_uid
                 LEFT OUTER JOIN dbo.nrt_srte_State_county_code_value county WITH(NOLOCK) ON county.code = place_perform.place_county_code
                 LEFT OUTER JOIN dbo.nrt_srte_State_code state WITH(NOLOCK) ON state.state_cd = place_perform.place_state_code;

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
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
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'PROCESSING'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(ISNULL(@observation_id_list, 'NULL'),500)
               );

        /* Debug output if requested */
        IF @debug = 'true'
            SELECT * FROM #COVID_LAB_CORE_DATA;

        /* Create result type classification */
        SET @proc_step_name = 'Create COVID_LAB_RSLT_TYPE';
        SET @proc_step_no = 4;

        IF OBJECT_ID('tempdb..#COVID_LAB_RSLT_TYPE', 'U') IS NOT NULL
            DROP TABLE #COVID_LAB_RSLT_TYPE;

        SELECT
            #COVID_LAB_CORE_DATA.Observation_UID AS RT_Observation_UID,
            #COVID_LAB_CORE_DATA.Result AS RT_Result,
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
        FROM #COVID_LAB_CORE_DATA
        WHERE Result != '';

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
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
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'PROCESSING'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(ISNULL(@observation_id_list, 'NULL'),500)
               );

        /* Create patient data */
        SET @proc_step_name = 'Create COVID_LAB_PATIENT_DATA';
        SET @proc_step_no = 5;

        IF OBJECT_ID('tempdb..#COVID_LAB_PATIENT_DATA', 'U') IS NOT NULL
            DROP TABLE #COVID_LAB_PATIENT_DATA;

        -- Patient Data
        SELECT DISTINCT
            o.Observation_uid AS 'Pat_Observation_UID',
            p.last_name AS 'Last_Name',
            p.middle_name AS 'Middle_Name',
            p.first_name AS 'First_Name',
            p.local_id AS 'Patient_Local_ID',
            p.current_sex AS 'Current_Sex_Cd',
            p.age_reported AS 'Age_Reported',
            p.age_reported_unit AS 'Age_Unit_Cd',
            p.dob AS 'Birth_Dt',
            p.deceased_date AS 'PATIENT_DEATH_DATE',
            p.deceased_indicator AS 'PATIENT_DEATH_IND',
            p.phone_home AS 'Phone_Number',
            p.street_address_1 AS 'Address_One',
            p.street_address_2 AS 'Address_Two',
            p.city AS 'City',
            p.state_code AS 'State_Cd',
            state.state_NM AS 'State',
            p.zip AS 'Zip_Code',
            p.county_code AS 'County_Cd',
            county.code_desc_txt AS 'County_Desc',
            p.race_calculated AS 'PATIENT_RACE_CALC',
            p.ethnicity AS 'PATIENT_ETHNICITY'
        INTO #COVID_LAB_PATIENT_DATA
        FROM #COVID_LAB_CORE_DATA o
                 INNER JOIN dbo.nrt_observation obs WITH(NOLOCK) ON o.Observation_UID = obs.observation_uid
                 INNER JOIN dbo.nrt_patient p WITH(NOLOCK) ON obs.patient_id = p.patient_uid
                 LEFT JOIN dbo.D_Patient d_patient WITH(NOLOCK) ON p.patient_uid = d_patient.PATIENT_MPR_UID
                 LEFT OUTER JOIN dbo.nrt_srte_State_county_code_value county ON county.code = p.county_code
                 LEFT OUTER JOIN dbo.nrt_srte_State_code state ON state.state_cd = p.state_code;

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
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
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'PROCESSING'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(ISNULL(@observation_id_list, 'NULL'),500)
               );

        /* Create entities data */
        SET @proc_step_name = 'Create COVID_LAB_ENTITIES_DATA';
        SET @proc_step_no = 6;

        IF OBJECT_ID('tempdb..#COVID_LAB_ENTITIES_DATA', 'U') IS NOT NULL
            DROP TABLE #COVID_LAB_ENTITIES_DATA;

        -- Lab Entities Data
        SELECT DISTINCT
            o.Observation_UID AS 'Entity_Observation_uid',
            org_author.organization_name AS 'Reporting_Facility_Name',
            place_author.place_street_address_1 AS 'Reporting_Facility_Address_One',
            place_author.place_street_address_2 AS 'Reporting_Facility_Address_Two',
            place_author.place_country AS 'Reporting_Facility_Country',
            place_author.place_county_code AS 'Reporting_Facility_County',
            county_author.code_desc_txt AS 'Reporting_Facility_County_Desc',
            place_author.place_city AS 'Reporting_Facility_City',
            place_author.place_state_code AS 'Reporting_Facility_State_Cd',
            state_author.state_NM AS 'Reporting_Facility_State',
            place_author.place_zip AS 'Reporting_Facility_Zip_Cd',
            org_author.facility_id AS 'Reporting_Facility_Clia',
            tele_author.place_phone AS 'Reporting_Facility_Phone_Nbr',
            tele_author.place_phone_ext AS 'Reporting_Facility_Phone_Ext',
            org_order.organization_name AS 'Ordering_Facility_Name',
            place_order.place_street_address_1 AS 'Ordering_Facility_Address_One',
            place_order.place_street_address_2 AS 'Ordering_Facility_Address_Two',
            place_order.place_country AS 'Ordering_Facility_Country',
            place_order.place_county_code AS 'Ordering_Facility_County',
            county_order.code_desc_txt AS 'Ordering_Facility_County_Desc',
            place_order.place_city AS 'Ordering_Facility_City',
            place_order.place_state_code AS 'Ordering_Facility_State_Cd',
            state_order.state_NM AS 'Ordering_Facility_State',
            place_order.place_zip AS 'Ordering_Facility_Zip_Cd',
            tele_order.place_phone AS 'Ordering_Facility_Phone_Nbr',
            tele_order.place_phone_ext AS 'Ordering_Facility_Phone_Ext',
            provider_order.first_name AS 'Ordering_Provider_First_Name',
            provider_order.last_name AS 'Ordering_Provider_Last_Name',
            provider_place.place_street_address_1 AS 'Ordering_Provider_Address_One',
            provider_place.place_street_address_2 AS 'Ordering_Provider_Address_Two',
            provider_place.place_country AS 'Ordering_Provider_Country',
            provider_place.place_county_code AS 'Ordering_Provider_County',
            county_provider.code_desc_txt AS 'Ordering_Provider_County_Desc',
            provider_place.place_city AS 'Ordering_Provider_City',
            provider_place.place_state_code AS 'Ordering_Provider_State_Cd',
            state_provider.state_NM AS 'Ordering_Provider_State',
            provider_place.place_zip AS 'Ordering_Provider_Zip_Cd',
            provider_tele.place_phone AS 'Ordering_Provider_Phone_Nbr',
            provider_tele.place_phone_ext AS 'Ordering_Provider_Phone_Ext',
            provider_order.local_id AS 'ORDERING_PROVIDER_ID'
        INTO #COVID_LAB_ENTITIES_DATA
        FROM #COVID_LAB_CORE_DATA o
                 LEFT JOIN dbo.nrt_observation obs WITH(NOLOCK) ON o.Observation_UID = obs.observation_uid
                 LEFT JOIN dbo.nrt_organization org_author WITH(NOLOCK) ON obs.author_organization_id = org_author.organization_uid
                 LEFT JOIN dbo.D_Organization d_org_author WITH(NOLOCK) ON org_author.organization_uid = d_org_author.organization_id
                 LEFT JOIN dbo.nrt_place place_author WITH(NOLOCK) ON org_author.organization_uid = place_author.place_uid
                 LEFT JOIN dbo.nrt_srte_State_county_code_value county_author ON county_author.code = place_author.place_county_code
                 LEFT JOIN dbo.nrt_srte_State_code state_author ON state_author.state_cd = place_author.place_state_code
                 LEFT JOIN dbo.nrt_place_tele tele_author WITH(NOLOCK) ON org_author.organization_uid = tele_author.place_uid
            AND tele_author.place_tele_use = 'WP'
                 LEFT JOIN dbo.nrt_organization org_order WITH(NOLOCK) ON obs.ordering_organization_id = org_order.organization_uid
                 LEFT JOIN dbo.D_Organization d_org_order WITH(NOLOCK) ON org_order.organization_uid = d_org_order.ORGANIZATION_UID
                 LEFT JOIN dbo.nrt_place place_order WITH(NOLOCK) ON org_order.organization_uid = place_order.place_uid
                 LEFT JOIN dbo.nrt_srte_State_county_code_value county_order ON county_order.code = place_order.place_county_code
                 LEFT JOIN dbo.nrt_srte_State_code state_order ON state_order.state_cd = place_order.place_state_code
                 LEFT JOIN dbo.nrt_place_tele tele_order WITH(NOLOCK) ON org_order.organization_uid = tele_order.place_uid
            AND tele_order.place_tele_use = 'WP'
                 LEFT JOIN dbo.nrt_provider provider_order WITH(NOLOCK) ON obs.ordering_person_id = provider_order.provider_uid
                 LEFT JOIN dbo.nrt_place provider_place WITH(NOLOCK) ON provider_order.provider_uid = provider_place.place_uid
                 LEFT JOIN dbo.nrt_srte_State_county_code_value county_provider ON county_provider.code = provider_place.place_county_code
                 LEFT JOIN dbo.nrt_srte_State_code state_provider ON state_provider.state_cd = provider_place.place_state_code
                 LEFT JOIN dbo.nrt_place_tele provider_tele WITH(NOLOCK) ON provider_order.provider_uid = provider_tele.place_uid
            AND provider_tele.place_tele_use = 'WP';

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
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
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'PROCESSING'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(ISNULL(@observation_id_list, 'NULL'),500)
               );

        /* Create associations data */
        SET @proc_step_name = 'Create COVID_LAB_ASSOCIATIONS';
        SET @proc_step_no = 7;

        IF OBJECT_ID('tempdb..#COVID_LAB_ASSOCIATIONS', 'U') IS NOT NULL
            DROP TABLE #COVID_LAB_ASSOCIATIONS;

        SELECT DISTINCT
            #COVID_LAB_CORE_DATA.Observation_UID AS 'ASSOC_OBSERVATION_UID',
            o.associated_phc_uids AS 'Associated_Case_ID'
        INTO #COVID_LAB_ASSOCIATIONS
        FROM #COVID_LAB_CORE_DATA
                 INNER JOIN dbo.nrt_observation o WITH(NOLOCK) ON o.observation_uid = #COVID_LAB_CORE_DATA.Observation_UID;

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
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
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'PROCESSING'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(ISNULL(@observation_id_list, 'NULL'),500)
               );

        /* Start transaction for the actual update to the datamart */
        SET @proc_step_name = 'Update COVID_LAB_DATAMART';
        SET @proc_step_no = 8;

        BEGIN TRANSACTION;

        /* Delete existing records for these observations */
        -- Modified as per review comments to filter LOG_DEL records upfront
        DELETE FROM dbo.COVID_LAB_DATAMART
        WHERE Observation_uid IN (SELECT Observation_UID FROM #COVID_LAB_CORE_DATA);

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
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
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'PROCESSING'
               ,@proc_step_no
               ,@proc_step_name + ' - Delete'
               ,@rowcount
               ,LEFT(ISNULL(@observation_id_list, 'NULL'),500)
               );

        /* Insert updated records */
        INSERT INTO dbo.COVID_LAB_DATAMART (
            Observation_UID,
            Lab_Local_ID,
            Ordered_Test_Cd,
            Ordered_Test_Desc,
            Ordered_Test_Code_System,
            ORDER_TEST_DATE,
            Electronic_Ind,
            Program_Area_Cd,
            Jurisdiction_Cd,
            Lab_Report_Dt,
            Lab_Rpt_Received_By_PH_Dt,
            Order_result_status,
            Jurisdiction_Nm,
            Specimen_Cd,
            Specimen_Desc,
            Specimen_type_free_text,
            Specimen_Id,
            SPECIMEN_SOURCE_SITE_CD,
            SPECIMEN_SOURCE_SITE_DESC,
            Testing_Lab_Accession_Number,
            Lab_Added_Dt,
            Lab_Update_Dt,
            Specimen_Coll_Dt,
            COVID_LAB_DATAMART_KEY,
            Resulted_Test_Cd,
            Resulted_Test_Desc,
            Resulted_Test_Code_System,
            DEVICE_INSTANCE_ID_1,
            DEVICE_INSTANCE_ID_2,
            Test_result_status,
            Test_Method_Desc,
            Device_Type_Id_1,
            Device_Type_Id_2,
            Perform_Facility_Name,
            Testing_lab_Address_One,
            Testing_lab_Address_Two,
            Testing_lab_Country,
            Testing_lab_county,
            Testing_lab_county_Desc,
            Testing_lab_City,
            Testing_lab_State_Cd,
            Testing_lab_State,
            Testing_lab_Zip_Cd,
            Result_Cd,
            Result_Cd_Sys,
            Result_Desc,
            Text_Result_Desc,
            Numeric_Comparator_Cd,
            Numeric_Value_1,
            Numeric_Value_2,
            Numeric_Unit_Cd,
            Numeric_Low_Range,
            Numeric_High_Range,
            Numeric_Separator_Cd,
            Interpretation_Cd,
            Interpretation_Desc,
            Result_Comments,
            Result,
            Result_Category,
            Last_Name,
            Middle_Name,
            First_Name,
            Patient_Local_ID,
            Current_Sex_Cd,
            Age_Reported,
            Age_Unit_Cd,
            Birth_Dt,
            PATIENT_DEATH_DATE,
            PATIENT_DEATH_IND,
            Phone_Number,
            Address_One,
            Address_Two,
            City,
            State_Cd,
            State,
            Zip_Code,
            County_Cd,
            County_Desc,
            PATIENT_RACE_CALC,
            PATIENT_ETHNICITY,
            Reporting_Facility_Name,
            Reporting_Facility_Address_One,
            Reporting_Facility_Address_Two,
            Reporting_Facility_Country,
            Reporting_Facility_County,
            Reporting_Facility_County_Desc,
            Reporting_Facility_City,
            Reporting_Facility_State_Cd,
            Reporting_Facility_State,
            Reporting_Facility_Zip_Cd,
            Reporting_Facility_Clia,
            Reporting_Facility_Phone_Nbr,
            Reporting_Facility_Phone_Ext,
            Ordering_Facility_Name,
            Ordering_Facility_Address_One,
            Ordering_Facility_Address_Two,
            Ordering_Facility_Country,
            Ordering_Facility_County,
            Ordering_Facility_County_Desc,
            Ordering_Facility_City,
            Ordering_Facility_State_Cd,
            Ordering_Facility_State,
            Ordering_Facility_Zip_Cd,
            Ordering_Facility_Phone_Nbr,
            Ordering_Facility_Phone_Ext,
            Ordering_Provider_First_Name,
            Ordering_Provider_Last_Name,
            Ordering_Provider_Address_One,
            Ordering_Provider_Address_Two,
            Ordering_Provider_Country,
            Ordering_Provider_County,
            Ordering_Provider_County_Desc,
            Ordering_Provider_City,
            Ordering_Provider_State_Cd,
            Ordering_Provider_State,
            Ordering_Provider_Zip_Cd,
            Ordering_Provider_Phone_Nbr,
            Ordering_Provider_Phone_Ext,
            ORDERING_PROVIDER_ID,
            Associated_Case_ID
        )
        SELECT DISTINCT
            core.Observation_UID,
            core.Lab_Local_ID,
            core.Ordered_Test_Cd,
            core.Ordered_Test_Desc,
            core.Ordered_Test_Code_System,
            core.ORDER_TEST_DATE,
            core.Electronic_Ind,
            core.Program_Area_Cd,
            core.Jurisdiction_Cd,
            core.Lab_Report_Dt,
            core.Lab_Rpt_Received_By_PH_Dt,
            core.Order_result_status,
            core.Jurisdiction_Nm,
            core.Specimen_Cd,
            core.Specimen_Desc,
            core.Specimen_type_free_text,
            core.Specimen_Id,
            core.SPECIMEN_SOURCE_SITE_CD,
            core.SPECIMEN_SOURCE_SITE_DESC,
            core.Testing_Lab_Accession_Number,
            core.Lab_Added_Dt,
            core.Lab_Update_Dt,
            core.Specimen_Coll_Dt,
            core.COVID_LAB_DATAMART_KEY,
            core.Resulted_Test_Cd,
            core.Resulted_Test_Desc,
            core.Resulted_Test_Code_System,
            core.DEVICE_INSTANCE_ID_1,
            core.DEVICE_INSTANCE_ID_2,
            core.Test_result_status,
            core.Test_Method_Desc,
            core.Device_Type_Id_1,
            core.Device_Type_Id_2,
            core.Perform_Facility_Name,
            core.Testing_lab_Address_One,
            core.Testing_lab_Address_Two,
            core.Testing_lab_Country,
            core.Testing_lab_county,
            core.Testing_lab_county_Desc,
            core.Testing_lab_City,
            core.Testing_lab_State_Cd,
            core.Testing_lab_State,
            core.Testing_lab_Zip_Cd,
            core.Result_Cd,
            core.Result_Cd_Sys,
            core.Result_Desc,
            core.Text_Result_Desc,
            core.Numeric_Comparator_Cd,
            core.Numeric_Value_1,
            core.Numeric_Value_2,
            core.Numeric_Unit_Cd,
            core.Numeric_Low_Range,
            core.Numeric_High_Range,
            core.Numeric_Separator_Cd,
            core.Interpretation_Cd,
            core.Interpretation_Desc,
            core.Result_Comments,
            core.Result,
            rslt.Result_Category,
            pat.Last_Name,
            pat.Middle_Name,
            pat.First_Name,
            pat.Patient_Local_ID,
            pat.Current_Sex_Cd,
            pat.Age_Reported,
            pat.Age_Unit_Cd,
            pat.Birth_Dt,
            pat.PATIENT_DEATH_DATE,
            pat.PATIENT_DEATH_IND,
            pat.Phone_Number,
            pat.Address_One,
            pat.Address_Two,
            pat.City,
            pat.State_Cd,
            pat.State,
            pat.Zip_Code,
            pat.County_Cd,
            pat.County_Desc,
            pat.PATIENT_RACE_CALC,
            pat.PATIENT_ETHNICITY,
            ent.Reporting_Facility_Name,
            ent.Reporting_Facility_Address_One,
            ent.Reporting_Facility_Address_Two,
            ent.Reporting_Facility_Country,
            ent.Reporting_Facility_County,
            ent.Reporting_Facility_County_Desc,
            ent.Reporting_Facility_City,
            ent.Reporting_Facility_State_Cd,
            ent.Reporting_Facility_State,
            ent.Reporting_Facility_Zip_Cd,
            ent.Reporting_Facility_Clia,
            ent.Reporting_Facility_Phone_Nbr,
            ent.Reporting_Facility_Phone_Ext,
            ent.Ordering_Facility_Name,
            ent.Ordering_Facility_Address_One,
            ent.Ordering_Facility_Address_Two,
            ent.Ordering_Facility_Country,
            ent.Ordering_Facility_County,
            ent.Ordering_Facility_County_Desc,
            ent.Ordering_Facility_City,
            ent.Ordering_Facility_State_Cd,
            ent.Ordering_Facility_State,
            ent.Ordering_Facility_Zip_Cd,
            ent.Ordering_Facility_Phone_Nbr,
            ent.Ordering_Facility_Phone_Ext,
            ent.Ordering_Provider_First_Name,
            ent.Ordering_Provider_Last_Name,
            ent.Ordering_Provider_Address_One,
            ent.Ordering_Provider_Address_Two,
            ent.Ordering_Provider_Country,
            ent.Ordering_Provider_County,
            ent.Ordering_Provider_County_Desc,
            ent.Ordering_Provider_City,
            ent.Ordering_Provider_State_Cd,
            ent.Ordering_Provider_State,
            ent.Ordering_Provider_Zip_Cd,
            ent.Ordering_Provider_Phone_Nbr,
            ent.Ordering_Provider_Phone_Ext,
            ent.ORDERING_PROVIDER_ID,
            assoc.Associated_Case_ID
        FROM #COVID_LAB_CORE_DATA core
                 LEFT JOIN #COVID_LAB_RSLT_TYPE rslt ON core.Observation_UID = rslt.RT_Observation_UID
                 LEFT JOIN #COVID_LAB_PATIENT_DATA pat ON core.Observation_UID = pat.Pat_Observation_UID
                 LEFT JOIN #COVID_LAB_ENTITIES_DATA ent ON core.Observation_UID = ent.Entity_Observation_uid
                 LEFT JOIN #COVID_LAB_ASSOCIATIONS assoc ON core.Observation_UID = assoc.ASSOC_OBSERVATION_UID
        -- Removed WHERE clause that filtered LOG_DEL records as we're now doing it upfront
        -- WHERE core.record_status_cd <> 'LOG_DEL';

        /* Logging for insert operation */
        SET @rowcount = @@ROWCOUNT;
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
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'PROCESSING'
               ,@proc_step_no
               ,@proc_step_name + ' - Insert'
               ,@rowcount
               ,LEFT(ISNULL(@observation_id_list, 'NULL'),500)
               );

        /* Commit the transaction */
        COMMIT TRANSACTION;

        /* Clean up temporary tables */
        IF OBJECT_ID('tempdb..#COVID_OBSERVATIONS_TO_PROCESS', 'U') IS NOT NULL
            DROP TABLE #COVID_OBSERVATIONS_TO_PROCESS;
        IF OBJECT_ID('tempdb..#COVID_TEXT_RESULT_LIST', 'U') IS NOT NULL
            DROP TABLE #COVID_TEXT_RESULT_LIST;
        IF OBJECT_ID('tempdb..#COVID_LAB_CORE_DATA', 'U') IS NOT NULL
            DROP TABLE #COVID_LAB_CORE_DATA;
        IF OBJECT_ID('tempdb..#COVID_LAB_RSLT_TYPE', 'U') IS NOT NULL
            DROP TABLE #COVID_LAB_RSLT_TYPE;
        IF OBJECT_ID('tempdb..#COVID_LAB_PATIENT_DATA', 'U') IS NOT NULL
            DROP TABLE #COVID_LAB_PATIENT_DATA;
        IF OBJECT_ID('tempdb..#COVID_LAB_ENTITIES_DATA', 'U') IS NOT NULL
            DROP TABLE #COVID_LAB_ENTITIES_DATA;
        IF OBJECT_ID('tempdb..#COVID_LAB_ASSOCIATIONS', 'U') IS NOT NULL
            DROP TABLE #COVID_LAB_ASSOCIATIONS;

        /* Final logging */
        SET @proc_step_name = 'SP_COMPLETE';
        SET @proc_step_no = 9;

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
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'COMPLETE'
               ,@proc_step_no
               ,@proc_step_name
               ,0
               ,LEFT(ISNULL(@observation_id_list, 'NULL'),500)
               );

        /* Return processed observation IDs */
        SELECT DISTINCT Observation_UID as observation_id
        FROM #COVID_LAB_CORE_DATA;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @FullErrorMessage NVARCHAR(4000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        /* Logging */
        INSERT INTO [dbo].[job_flow_log] (
                                           batch_id
                                         ,[Dataflow_Name]
                                         ,[package_Name]
                                         ,[Status_Type]
                                         ,[step_number]
                                         ,[step_name]
                                         ,[row_count]
                                         ,[msg_description1]
                                         ,[Error_Description]
        )
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'ERROR'
               ,@proc_Step_no
               ,@proc_step_name
               ,0
               ,LEFT(ISNULL(@observation_id_list, 'NULL'),500)
               ,@FullErrorMessage
               );

        RETURN ERROR_NUMBER();
    END CATCH;
END;
