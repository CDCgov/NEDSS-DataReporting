CREATE PROCEDURE [dbo].[sp_covid_case_test]
  @observation_id_list NVARCHAR(max), -- List of observation IDs to process (comma-separated)
  @debug               BIT = 'false'  -- Flag to enable debug output
AS
  BEGIN
    /* Logging and initialization variables */
    DECLARE @rowcount BIGINT;
    DECLARE @proc_step_no FLOAT = 0;
    DECLARE @proc_step_name VARCHAR(200) = '';
    DECLARE @batch_id       BIGINT;
    DECLARE @dataflow_name  VARCHAR(200) = 'COVID LAB DATAMART Post-Processing Event';
    DECLARE @package_name   VARCHAR(200) = 'sp_covid_lab_datamart_postprocessing';
    SET @batch_id = Cast((Format(Getdate(),'yyMMddHHmmssffff')) AS BIGINT);
    -- Initialize logging
    INSERT INTO [dbo].[job_flow_log]
                (
                            batch_id ,
                            [Dataflow_Name] ,
                            [package_Name] ,
                            [Status_Type] ,
                            [step_number] ,
                            [step_name] ,
                            [msg_description1] ,
                            [row_count]
                )
                VALUES
                (
                            @batch_id ,
                            @dataflow_name ,
                            @package_name ,
                            'START' ,
                            0 ,
                            'SP_Start' ,
                            LEFT(Isnull(@observation_id_list, 'NULL'),500) ,
                            0
                );

    BEGIN try
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
        SELECT     obs.observation_uid
        INTO       #covid_observations_to_process
        FROM       String_split(@observation_id_list, ',') split_ids
        INNER JOIN dbo.nrt_observation obs WITH(nolock)
        ON         try_cast(split_ids.value as bigint) = obs.observation_uid
        WHERE      COALESCE(obs.record_status_cd, '') <> 'LOG_DEL';

      END
      /* Logging */
      SET @rowcount = @@ROWCOUNT;
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
                              'START' ,
                              @proc_step_no ,
                              @proc_step_name ,
                              @rowcount ,
                              LEFT(Isnull(@observation_id_list, 'NULL'),500)
                  );

      /* Debug output if requested */
      IF @debug = 1
      SELECT @proc_step_name,
             *
      FROM   #covid_observations_to_process;

      /* Create the next session table to hold text results */
      SET @proc_step_name = 'Extract Text Results';
      SET @proc_step_no = 2;
      SELECT DISTINCT o_order.observation_uid,
                      o.observation_uid                        AS target_observation_uid, --result
                      o.local_id                               AS lab_local_id,
                      COALESCE(dp.patient_local_id,p.local_id) AS patient_local_id
      INTO            #covid_result_list
      FROM            #covid_observations_to_process cp --Order
      INNER JOIN      dbo.nrt_observation o_order WITH(nolock)
      ON              cp.observation_uid = o_order.observation_uid
      CROSS apply
                      (
                             SELECT Cast(value AS BIGINT) AS target_obs_uid
                             FROM   String_split(o_order.result_observation_uid, ',') ) AS split_results
      INNER JOIN      dbo.nrt_observation o WITH(nolock)
      ON              split_results.target_obs_uid = o.observation_uid
      LEFT JOIN       dbo.d_patient dp WITH(nolock)
      ON              o_order.patient_id = dp.patient_uid
      LEFT JOIN       dbo.nrt_patient p WITH(nolock)
      ON              o_order.patient_id = p.patient_uid
      INNER JOIN      dbo.nrt_patient_key pk WITH(nolock)
      ON              pk.patient_uid = p.patient_uid
      WHERE           COALESCE(dp.patient_uid, pk.patient_uid) IS NOT NULL
      AND             (
                                      o.cd IN
                                      (
                                             SELECT loinc_cd
                                             FROM   dbo.nrt_srte_loinc_condition
                                             WHERE  condition_cd = '11065' )
                      OR              o.cd IN(''))--replace '' with the local codes seperated by comma
      AND             o.cd NOT IN
                      (
                             SELECT loinc_cd
                             FROM   dbo.nrt_srte_loinc_code
                             WHERE  time_aspect = 'Pt'
                             AND    system_cd = '^Patient' );

      IF @debug = 1
      SELECT '#COVID_RESULT_LIST',
             *
      FROM   #covid_result_list;

      SELECT DISTINCT cp.observation_uid,
                      cp.target_observation_uid, --result
                      cp.lab_local_id,
                      cp.patient_local_id,
                      Replace(Replace(otxt.ovt_value_txt,         Char(13), ' '), Char(10), ' ') AS text_result_desc,
                      Replace(Replace(otxt_comment.ovt_value_txt, Char(13), ' '), Char(10), ' ') AS result_comments
      INTO            #covid_text_result_list
      FROM            #covid_result_list cp --Order
      INNER JOIN      dbo.nrt_observation o WITH(nolock)
      ON              cp.target_observation_uid = o.observation_uid
      LEFT OUTER JOIN dbo.nrt_observation_txt otxt WITH(nolock)
      ON              o.observation_uid = otxt.observation_uid
      AND             Isnull(o.batch_id,1) = Isnull(otxt.batch_id,1)
      AND             (
                                      otxt.ovt_txt_type_cd = 'O'
                      OR              otxt.ovt_txt_type_cd IS NULL)
      LEFT OUTER JOIN dbo.nrt_observation_txt otxt_comment WITH(nolock)
      ON              o.observation_uid = otxt_comment.observation_uid
      AND             Isnull(o.batch_id,1) = Isnull(otxt_comment.batch_id,1)
      AND             otxt_comment.ovt_txt_type_cd = 'N' ;

      IF @debug = 1
      SELECT '#COVID_TEXT_RESULT_LIST',
             *
      FROM   #covid_text_result_list;

      /* Logging */
      SET @rowcount = @@ROWCOUNT;
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
                              'START' ,
                              @proc_step_no ,
                              @proc_step_name ,
                              @rowcount ,
                              LEFT(Isnull(@observation_id_list, 'NULL'),500)
                  );

      /* Debug output if requested */
      IF @debug = 1
      SELECT @proc_step_name,
             *
      FROM   #covid_text_result_list;

      /* Create the core lab data table */
      SET @proc_step_name = 'Create COVID_LAB_CORE_DATA';
      SET @proc_step_no = 3;
      SELECT DISTINCT o.observation_uid AS observation_uid,
                      o.local_id        AS lab_local_id,
                      o.record_status_cd,
                      o.cd                     AS ordered_test_cd,
                      o.cd_desc_txt            AS ordered_test_desc,
                      o.cd_system_cd           AS ordered_test_code_system,
                      o.electronic_ind         AS electronic_ind,
                      o.prog_area_cd           AS program_area_cd,
                      o.jurisdiction_cd        AS jurisdiction_cd,
                      o.activity_to_time       AS lab_report_dt,
                      o.rpt_to_state_time      AS lab_rpt_received_by_ph_dt,
                      o.activity_from_time     AS order_test_date,
                      o.target_site_cd         AS specimen_source_site_cd,
                      o.target_site_desc_txt   AS specimen_source_site_desc,
                      cvg1.code_short_desc_txt AS order_result_status,
                      j_code.code_desc_txt     AS jurisdiction_nm,
                      mat.material_cd          AS specimen_cd,
                      mat.material_desc        AS specimen_desc,
                      mat.material_details     AS specimen_type_free_text,
                      CASE
                                      WHEN o.accession_number IS NULL
                                      OR              o.accession_number = '' THEN o.local_id
                                      ELSE o.accession_number
                      END AS specimen_id,
                      CASE
                                      WHEN o.accession_number IS NULL
                                      OR              o.accession_number = '' THEN o.local_id
                                      ELSE o.accession_number
                      END                      AS testing_lab_accession_number,
                      o.add_time               AS lab_added_dt,
                      o.last_chg_time          AS lab_update_dt,
                      o.effective_from_time    AS specimen_coll_dt,
                      o1.observation_uid       AS covid_lab_datamart_key,
                      o1.cd                    AS resulted_test_cd,
                      o1.cd_desc_txt           AS resulted_test_desc,
                      o1.cd_system_cd          AS resulted_test_code_system,
                      o1.device_instance_id_1  AS device_instance_id_1,
                      o1.device_instance_id_2  AS device_instance_id_2,
                      cvg2.code_short_desc_txt AS test_result_status,
                      o1.method_desc_txt       AS test_method_desc,
                      CASE
                                      WHEN o1.method_cd LIKE '%**%' THEN LEFT(o1.method_cd, Charindex('**', o1.method_cd)-1)
                                      ELSE o1.method_cd
                      END AS device_type_id_1,
                      CASE
                                      WHEN o1.method_cd LIKE '%**%' THEN Substring(o1.method_cd, Charindex('**', o1.method_cd)+2, Len(o1.method_cd))
                                      ELSE NULL
                      END                                                                                 AS device_type_id_2,
                      COALESCE(d_org_perform.organization_name, org_perform.organization_name)            AS perform_facility_name,
                      COALESCE(d_org_perform.organization_street_address_1, org_perform.street_address_1) AS testing_lab_address_one,
                      COALESCE(d_org_perform.organization_street_address_2, org_perform.street_address_2) AS testing_lab_address_two,
                      COALESCE(d_org_perform.organization_country, org_perform.country)                   AS testing_lab_country,
                      COALESCE(d_org_perform.organization_county_code, org_perform.county_code)           AS testing_lab_county,
                      COALESCE(d_org_perform.organization_county, org_perform.county)                     AS testing_lab_county_desc,
                      COALESCE(d_org_perform.organization_city, org_perform.city)                         AS testing_lab_city,
                      COALESCE(d_org_perform.organization_state_code, org_perform.state_code)             AS testing_lab_state_cd,
                      COALESCE(d_org_perform.organization_state, org_perform.state)                       AS testing_lab_state,
                      COALESCE(d_org_perform.organization_zip, org_perform.zip)                           AS testing_lab_zip_cd,
                      ovc.ovc_code                                                                        AS result_cd,
                      ovc.ovc_code_system_cd                                                              AS result_cd_sys,
                      ovc.ovc_display_name                                                                AS result_desc,
                      text_result_desc,
                      ovn.ovn_comparator_cd_1    AS numeric_comparator_cd,
                      ovn.ovn_numeric_value_1    AS numeric_value_1,
                      ovn.ovn_numeric_value_2    AS numeric_value_2,
                      ovn.ovn_numeric_unit_cd    AS numeric_unit_cd,
                      ovn.ovn_low_range          AS numeric_low_range,
                      ovn.ovn_high_range         AS numeric_high_range,
                      ovn.ovn_separator_cd       AS numeric_separator_cd,
                      o1.interpretation_cd       AS interpretation_cd,
                      o1.interpretation_desc_txt AS interpretation_desc,
                      result_comments,
                      Ltrim(Isnull(ovc.ovc_display_name, '') + ' ' + Isnull(text_result_desc, '') + ' ' + Isnull(result_comments, ' ')) AS result
      INTO            #covid_lab_core_data
      FROM            #covid_text_result_list ctr
      LEFT JOIN       dbo.nrt_observation o WITH(nolock)
      ON              ctr.observation_uid = o.observation_uid
      LEFT JOIN       dbo.nrt_observation o1 WITH(nolock)
      ON              ctr.target_observation_uid = o1.observation_uid --Result
      AND             o1.obs_domain_cd_st_1 = 'Result'
      LEFT OUTER JOIN dbo.nrt_observation_coded ovc WITH(nolock)
      ON              o1.observation_uid = ovc.observation_uid
      AND             Isnull(o1.batch_id,1) = Isnull(ovc.batch_id,1)
      LEFT OUTER JOIN dbo.nrt_srte_jurisdiction_code j_code WITH(nolock)
      ON              j_code.code = o.jurisdiction_cd
      LEFT OUTER JOIN dbo.nrt_srte_code_value_general cvg1 WITH(nolock)
      ON              cvg1.code = o.status_cd
      AND             cvg1.code_set_nm = 'ACT_OBJ_ST'
      LEFT OUTER JOIN dbo.nrt_srte_code_value_general cvg2 WITH(nolock)
      ON              cvg2.code = o1.status_cd
      AND             cvg2.code_set_nm = 'ACT_OBJ_ST'
      LEFT OUTER JOIN dbo.nrt_observation_numeric ovn WITH(nolock)
      ON              o1.observation_uid = ovn.observation_uid
      AND             Isnull(o1.batch_id,1) = Isnull(ovn.batch_id,1)
      LEFT OUTER JOIN dbo.nrt_observation_material mat WITH(nolock)
      ON              o.material_id = mat.material_id
      LEFT OUTER JOIN dbo.nrt_organization org_perform WITH(nolock)
      ON              o1.performing_organization_id = org_perform.organization_uid
                      --LEFT JOIN dbo.nrt_organization_key orgk WITH(NOLOCK) ON orgk.organization_uid = org_perform.organization_uid
      LEFT OUTER JOIN dbo.d_organization d_org_perform WITH(nolock)
      ON              o1.performing_organization_id = d_org_perform.organization_uid
      --WHERE COALESCE(d_org_perform.ORGANIZATION_UID, org_perform.ORGANIZATION_UID) IS NOT NULL;
      /* Logging */
      SET @rowcount = @@ROWCOUNT;
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
                              'START' ,
                              @proc_step_no ,
                              @proc_step_name ,
                              @rowcount ,
                              LEFT(Isnull(@observation_id_list, 'NULL'),500)
                  );

      /* Debug output if requested */
      IF @debug = 1
      SELECT @proc_step_name,
             *
      FROM   #covid_lab_core_data;

      /* Create result type classification */
      SET @proc_step_name = 'Create COVID_LAB_RSLT_TYPE';
      SET @proc_step_no = 4;
      SELECT core.observation_uid AS rt_observation_uid,
             -- core.target_observation_uid,
             core.result AS rt_result,
             CASE
                           -- Modify the logic (add additional variables) to determine negative labs
                    WHEN result IN('NEGATIVE',
                                   'Negative: SARS-CoV-2 virus is NOT detected',
                                   'PAN SARS RNA: NEGATIVE',
                                   'PRESUMPTIVE NEGATIVE',
                                   'SARS COV 2 RNA: NEGATIVE',
                                   'Not Detected',
                                   'Not detected (qualifier value)',
                                   'OVERALL RESULT: NOT DETECTED',
                                   'Undetected',
                                   'SARS-CoV-2 RNA was not present in the specimen')
                    OR     result LIKE '%Negative%'
                    OR     result LIKE '%Presumptive Negative%'
                    OR     result LIKE 'the specimen is negative for sars-cov%'
                    OR     result LIKE '%not detected%'
                    OR     result LIKE 'undetected%' THEN 'Negative'
                           -- Modify the logic (add additional variables) to determine positive labs
                    WHEN result IN('***DETECTED***',
                                   'Presum-Pos',
                                   'present')
                    OR     result LIKE 'abnormal%'
                    OR     (
                                  result LIKE '%detected%'
                           AND    result NOT LIKE '%not detected%'
                           AND    result NOT LIKE '%undetected%')
                    OR     result LIKE 'positive%'
                    OR     result LIKE '%positive%'
                    OR     result LIKE 'presumptive pos%'
                    OR     result LIKE 'the specimen is positive for sars-cov%' THEN 'Positive'
                           -- Modify the logic (add additional variables) to determine Indeterminate labs
                    WHEN result IN('Inconclusive',
                                   'Indeterminate',
                                   'Invalid',
                            'not det',
                                   'Not Performed',
                                   'pendingPUI',
                                   'unknown',
                                   'unknowninconclusive')
                    OR     result LIKE '%INCONCLUSIVE by RT%'
                    OR     result LIKE '%Inconclusive%'
                    OR     result LIKE '%Indeterminate%'
                    OR     result LIKE '%unresolved%' THEN 'Indeterminate'
                    ELSE NULL
             END AS result_category
      INTO   #covid_lab_rslt_type
      FROM   #covid_lab_core_data core
      WHERE  result != '';

      IF @debug = 1
      SELECT @proc_step_name,
             *
      FROM   #covid_lab_rslt_type;

      /* Logging */
      SET @rowcount = @@ROWCOUNT;
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
                              'START' ,
                              @proc_step_no ,
                              @proc_step_name ,
                              @rowcount ,
                              LEFT(Isnull(@observation_id_list, 'NULL'),500)
                  );

      /* Create patient data */
      SET @proc_step_name = 'Create COVID_LAB_PATIENT_DATA';
      SET @proc_step_no = 5;
      -- Patient Data
      SELECT DISTINCT o.observation_uid                                                   AS pat_observation_uid,
                      COALESCE(d_patient.patient_last_name,p.last_name)                   AS last_name,
                      COALESCE(d_patient.patient_middle_name,p.middle_name)               AS middle_name,
                      COALESCE(d_patient.patient_first_name,p.first_name)                 AS first_name,
                      COALESCE(d_patient.patient_local_id,p.local_id)                     AS patient_local_id,
                      NULL                                                                AS current_sex_cd, --CNDE-2751: Code is not recorded in D_PATIENT. Temporary stopgap.
                      COALESCE(d_patient.patient_age_reported,p.age_reported)             AS age_reported,
                      COALESCE(d_patient.patient_age_reported_unit,p.age_reported_unit)   AS age_unit_cd,
                      COALESCE(d_patient.patient_dob,p.dob)                               AS birth_dt,
                      COALESCE(d_patient.patient_deceased_date,p.deceased_date)           AS patient_death_date,
                      COALESCE(d_patient.patient_deceased_indicator,p.deceased_indicator) AS patient_death_ind,
                      COALESCE(d_patient.patient_phone_home,p.phone_home)                 AS phone_number,
                      COALESCE(d_patient.patient_street_address_1,p.street_address_1)     AS address_one,
                      COALESCE(d_patient.patient_street_address_2,p.street_address_2)     AS address_two,
                      COALESCE(d_patient.patient_city,p.city)                             AS city,
                      COALESCE(d_patient.patient_state_code,p.state_code)                 AS state_cd,
                      COALESCE(dim_state.state_nm,nrt_state.state_nm)                     AS state,
                      COALESCE(d_patient.patient_zip,p.zip)                               AS zip_code,
                      COALESCE(d_patient.patient_county_code,p.county_code)               AS county_cd,
                      COALESCE(d_patient.patient_county,p.county)                         AS county_desc,
                      COALESCE(d_patient.patient_race_calculated,p.race_calculated)       AS patient_race_calc,
                      COALESCE(d_patient.patient_ethnicity,p.ethnicity)                   AS patient_ethnicity
      INTO            #covid_lab_patient_data
      FROM            #covid_observations_to_process o
      INNER JOIN      dbo.nrt_observation obs WITH(nolock)
      ON              o.observation_uid = obs.observation_uid
      LEFT JOIN       dbo.d_patient d_patient WITH(nolock)
      ON              obs.patient_id = d_patient.patient_uid
      LEFT JOIN       dbo.nrt_patient p WITH(nolock)
      ON              obs.patient_id = p.patient_uid
      LEFT OUTER JOIN dbo.nrt_srte_state_code dim_state WITH(nolock)
      ON              dim_state.state_cd = d_patient.patient_state_code
      LEFT OUTER JOIN dbo.nrt_srte_state_code nrt_state WITH(nolock)
      ON              nrt_state.state_cd = p.state_code;

      IF @debug = 1
      SELECT @proc_step_name,
             *
      FROM   #covid_lab_patient_data;

      /* Logging */
      SET @rowcount = @@ROWCOUNT;
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
                              'START' ,
                              @proc_step_no ,
                              @proc_step_name ,
                              @rowcount ,
                              LEFT(Isnull(@observation_id_list, 'NULL'),500)
                  );

      /* Create entities data */
      SET @proc_step_name = 'Create COVID_LAB_ENTITIES_DATA';
      SET @proc_step_no = 6;
      IF Object_id('tempdb..#COVID_LAB_ENTITIES_DATA', 'U') IS NOT NULL
      DROP TABLE #covid_lab_entities_data;

      -- Lab Entities Data
      SELECT DISTINCT o.observation_uid                                                                    AS entity_observation_uid,
                      COALESCE(d_org_author.organization_name,org_author.organization_name)                AS reporting_facility_name,
                      COALESCE(d_org_author.organization_street_address_1, org_author.street_address_1)    AS reporting_facility_address_one,
                      COALESCE(d_org_author.organization_street_address_2, org_author.street_address_2)    AS reporting_facility_address_two,
                      COALESCE(d_org_author.organization_country,org_author.country)                       AS reporting_facility_country,
                      COALESCE(d_org_author.organization_county_code, org_author.county_code)              AS reporting_facility_county,
                      COALESCE(d_org_author.organization_county, org_author.county)                        AS reporting_facility_county_desc,
                      COALESCE(d_org_author.organization_city, org_author.city)                            AS reporting_facility_city,
                      COALESCE(d_org_author.organization_state_code, org_author.state_code)                AS reporting_facility_state_cd,
                      COALESCE(dim_state_org_author.state_nm, nrt_state_org_author.state_nm)               AS reporting_facility_state,
                      COALESCE(d_org_author.organization_zip, org_author.zip)                              AS reporting_facility_zip_cd,
                      COALESCE(d_org_author.organization_facility_id, org_author.facility_id)              AS reporting_facility_clia,
                      COALESCE(d_org_author.organization_phone_work, org_author.phone_work)                AS reporting_facility_phone_nbr,
                      COALESCE(d_org_author.organization_phone_ext_work, org_author.phone_ext_work)        AS reporting_facility_phone_ext,
                      COALESCE(d_org_order.organization_name, org_order.organization_name)                 AS ordering_facility_name,
                      COALESCE(d_org_order.organization_street_address_1, org_order.street_address_1)      AS ordering_facility_address_one,
                      COALESCE(d_org_order.organization_street_address_2, org_order.street_address_2)      AS ordering_facility_address_two,
                      COALESCE(d_org_order.organization_country, org_order.country)                        AS ordering_facility_country,
                      COALESCE(d_org_order.organization_county_code, org_order.county_code)                AS ordering_facility_county,
                      COALESCE(d_org_order.organization_county, org_order.county)                          AS ordering_facility_county_desc,
                      COALESCE(d_org_order.organization_city, org_order.city)                              AS ordering_facility_city,
                      COALESCE(d_org_order.organization_state_code, org_order.state_code)                  AS ordering_facility_state_cd,
                      COALESCE(dim_state_org_order.state_nm, nrt_state_org_order.state_nm)                 AS ordering_facility_state,
                      COALESCE(d_org_order.organization_zip, org_order.zip)                                AS ordering_facility_zip_cd,
                      COALESCE(d_org_order.organization_phone_work, org_order.phone_work)                  AS ordering_facility_phone_nbr,
                      COALESCE(d_org_order.organization_phone_ext_work, org_order.phone_ext_work)          AS ordering_facility_phone_ext,
                      COALESCE(d_provider_order.provider_first_name,provider_order.first_name)             AS ordering_provider_first_name,
                      COALESCE(d_provider_order.provider_last_name,provider_order.last_name)               AS ordering_provider_last_name,
                      COALESCE(d_provider_order.provider_street_address_1,provider_order.street_address_1) AS ordering_provider_address_one,
                      COALESCE(d_provider_order.provider_street_address_2,provider_order.street_address_2) AS ordering_provider_address_two,
                      COALESCE(d_provider_order.provider_country,provider_order.country)                   AS ordering_provider_country,
                      COALESCE(d_provider_order.provider_county_code,provider_order.county_code)           AS ordering_provider_county,
                      COALESCE(d_provider_order.provider_county,provider_order.county)                     AS ordering_provider_county_desc,
                      COALESCE(d_provider_order.provider_city,provider_order.city)                         AS ordering_provider_city,
                      COALESCE(d_provider_order.provider_state_code,provider_order.state_code)             AS ordering_provider_state_cd,
                      COALESCE(dim_state_provider_order.state_nm, nrt_state_provider_order.state_nm)       AS ordering_provider_state,
                      COALESCE(d_provider_order.provider_zip,provider_order.zip)                           AS ordering_provider_zip_cd,
                      COALESCE(d_provider_order.provider_phone_work,provider_order.phone_work)             AS ordering_provider_phone_nbr,
                      COALESCE(d_provider_order.provider_phone_ext_work,provider_order.phone_ext_work)     AS ordering_provider_phone_ext,
                      COALESCE(d_provider_order.provider_local_id,provider_order.local_id)  AS ordering_provider_id
      INTO            #covid_lab_entities_data
      FROM            #covid_lab_core_data o
      LEFT JOIN       dbo.nrt_observation obs WITH(nolock)
      ON              o.observation_uid = obs.observation_uid
                      /*Auth Org*/
      LEFT JOIN       dbo.nrt_organization org_author WITH(nolock)
      ON              obs.author_organization_id = org_author.organization_uid
      LEFT JOIN       dbo.d_organization d_org_author WITH(nolock)
      ON              obs.author_organization_id = d_org_author.organization_uid
      LEFT OUTER JOIN dbo.nrt_srte_state_code dim_state_org_author WITH(nolock)
      ON              dim_state_org_author.state_cd = d_org_author.organization_state_code
      LEFT OUTER JOIN dbo.nrt_srte_state_code nrt_state_org_author WITH(nolock)
      ON              nrt_state_org_author.state_cd = org_author.state_code
                      /*Ordering Org*/
      LEFT JOIN       dbo.nrt_organization org_order WITH(nolock)
      ON              obs.ordering_organization_id = org_order.organization_uid
      LEFT JOIN       dbo.d_organization d_org_order WITH(nolock)
      ON              obs.ordering_organization_id = d_org_order.organization_uid
      LEFT OUTER JOIN dbo.nrt_srte_state_code dim_state_org_order WITH(nolock)
      ON              dim_state_org_order.state_cd = d_org_order.organization_state_code
      LEFT OUTER JOIN dbo.nrt_srte_state_code nrt_state_org_order WITH(nolock)
      ON              nrt_state_org_order.state_cd = org_order.state_code
                      /*Ordering Provider*/
      LEFT JOIN       dbo.nrt_provider AS provider_order WITH (nolock)
      ON              EXISTS
                      (
                             SELECT 1
                             FROM   String_split(obs.ordering_person_id, ',') nprv
                             WHERE  Cast(nprv.value AS BIGINT) = provider_order.provider_uid)
      LEFT JOIN       dbo.d_provider AS d_provider_order WITH (nolock)
      ON              EXISTS
                      (
                             SELECT 1
                             FROM   String_split(obs.ordering_person_id, ',') nprv
                             WHERE  Cast(nprv.value AS BIGINT) = d_provider_order.provider_uid)
      LEFT OUTER JOIN dbo.nrt_srte_state_code dim_state_provider_order WITH(nolock)
      ON              dim_state_provider_order.state_cd = d_provider_order.provider_state_code
      LEFT OUTER JOIN dbo.nrt_srte_state_code nrt_state_provider_order WITH(nolock)
      ON              nrt_state_provider_order.state_cd = provider_order.state_code ;

      IF @debug = 1
      SELECT @proc_step_name,
             *
      FROM   #covid_lab_entities_data;

      /* Logging */
      SET @rowcount = @@ROWCOUNT;
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
                              'START' ,
                              @proc_step_no ,
                              @proc_step_name ,
                              @rowcount ,
                              LEFT(Isnull(@observation_id_list, 'NULL'),500)
                  );

      /* Create associations data */
      SET @proc_step_name = 'Create COVID_LAB_ASSOCIATIONS';
      SET @proc_step_no = 7;
      SELECT DISTINCT core.observation_uid  AS assoc_observation_uid,
                      o.associated_phc_uids AS associated_case_id
      INTO            #covid_lab_associations
      FROM            #covid_lab_core_data core
      INNER JOIN      dbo.nrt_observation o WITH(nolock)
      ON              o.observation_uid = core.observation_uid;

      IF @debug = 1
      SELECT @proc_step_name,
             *
      FROM   #covid_lab_associations;

      /* Logging */
      SET @rowcount = @@ROWCOUNT;
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
                              'START' ,
                              @proc_step_no ,
                              @proc_step_name ,
                              @rowcount ,
                              LEFT(Isnull(@observation_id_list, 'NULL'),500)
                  );

      /* Create AOE data table - FIXED: Create outside of IF block to fix scope issue */
      SET @proc_step_name = 'Create COVID_LAB_AOE_DATA';
      SET @proc_step_no = 7.5;
      -- Create the AOE table structure outside of conditional logic to fix scope issue
      IF Object_id('tempdb..#COVID_LAB_AOE_DATA', 'U') IS NOT NULL
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

 IF @debug = 1
 PRINT 'AOE columns added: ' + @aoe_sql;
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
          EXEC sp_executesql
            @pivot_sql;
          IF @debug = 1
          PRINT 'AOE pivot update completed: ' + @pivot_sql;
        END
        IF @debug = 1
        SELECT 'Full AOE processing completed' AS debug_message;

      END
      ELSE
      BEGIN
        IF @debug = 1
        SELECT 'No AOE metadata - minimal structure maintained' AS debug_message;

      END
      /* Logging */
      SET @rowcount = @@ROWCOUNT;
      INSERT INTO [dbo].[job_flow_log]
                  (
                              batch_id,
                              [Dataflow_Name],
                              [package_Name],
                              [Status_Type],
                              [step_number],
                              [step_name],
                              [row_count],
                              [msg_description1]
                  )
                  VALUES
                  (
                              @batch_id,
                              @dataflow_name,
                              @package_name,
                              'START',
                              @proc_step_no,
                              @proc_step_name,
                              @rowcount,
                              LEFT(Isnull(@observation_id_list, 'NULL'),500)
                  );

      SET @proc_step_name = 'Alter Datamart Columns for All Temp Tables';
      SET @proc_step_no = 7.7;
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
                 OR         st.NAME LIKE '#COVID_LAB_RSLT_TYPE%'
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

    OR (st.NAME LIKE '#COVID_LAB_RSLT_TYPE%' AND c.NAME = 'rt_observation_uid')
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
          IF @debug = 1
          PRINT 'Executed: ' + @column_query;
        END try
        BEGIN catch
          IF @debug = 1
          PRINT 'Error executing: ' + @column_query + ' - ' + Error_message();
          -- Continue processing other columns even if one fails
        END catch
      END
      IF @debug = 1
      SELECT 'Dynamic column check completed for all temp tables' AS debug_message,
             Isnull(@Max_Query_No, 0)                             AS total_alter_statements;

      /* Logging */
      INSERT INTO [dbo].[job_flow_log]
                  (
                              batch_id,
                              [Dataflow_Name],
                              [package_Name],
                              [Status_Type],
                              [step_number],
                              [step_name],
                              [row_count],
                              [msg_description1]
                  )
                  VALUES
                  (
                              @batch_id,
                              @dataflow_name,
                              @package_name,
                              'START',
                              @proc_step_no,
                              @proc_step_name,
                              Isnull(@Max_Query_No, 0),
                              LEFT(Isnull(@observation_id_list, 'NULL'),500)
                  );

      /* Start transaction for the actual update to the datamart */
      SET @proc_step_name = 'Update COVID_LAB_DATAMART';
      SET @proc_step_no = 8;
      BEGIN TRANSACTION;
      /* Delete existing records for these observations */
      DELETE
      FROM   dbo.covid_lab_datamart
      WHERE  observation_uid IN
             (
                    SELECT observation_uid
                    FROM   #covid_lab_core_data);

      /* Logging */
      SET @rowcount = @@ROWCOUNT;
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
                              'START' ,
                              @proc_step_no ,
                              @proc_step_name + ' - Delete' ,
                              @rowcount ,
                              LEFT(Isnull(@observation_id_list, 'NULL'),500)
                  );

      /* Insert updated records - FIXED: Using dynamic INSERT to handle AOE columns */
      DECLARE @insert_columns NVARCHAR(max) = '';
      DECLARE @select_columns NVARCHAR(max) = '';
      DECLARE @insert_sql     NVARCHAR(max);
      -- Build base column lists
      SET @insert_columns = 'Observation_UID,Lab_Local_ID,Ordered_Test_Cd,Ordered_Test_Desc,Ordered_Test_Code_System,ORDER_TEST_DATE,Electronic_Ind,Program_Area_Cd,Jurisdiction_Cd,Lab_Report_Dt,Lab_Rpt_Received_By_PH_Dt,Order_result_status,Jurisdiction_Nm,Specimen_Cd,Specimen_Desc,Specimen_type_free_text,Specimen_Id,SPECIMEN_SOURCE_SITE_CD,SPECIMEN_SOURCE_SITE_DESC,Testing_Lab_Accession_Number,Lab_Added_Dt,Lab_Update_Dt,Specimen_Coll_Dt,COVID_LAB_DATAMART_KEY,Resulted_Test_Cd,Resulted_Test_Desc,Resulted_Test_Code_System,DEVICE_INSTANCE_ID_1,DEVICE_INSTANCE_ID_2,Test_result_status,Test_Method_Desc,Device_Type_Id_1,Device_Type_Id_2,Perform_Facility_Name,Testing_lab_Address_One,Testing_lab_Address_Two,Testing_lab_Country,Testing_lab_county,Testing_lab_county_Desc,Testing_lab_City,Testing_lab_State_Cd,Testing_lab_State,Testing_lab_Zip_Cd,Result_Cd,Result_Cd_Sys,Result_Desc,Text_Result_Desc,Numeric_Comparator_Cd,Numeric_Value_1,Numeric_Value_2,Numeric_Unit_Cd,Numeric_Low_Range,Numeric_High_Range,Numeric_Separator_Cd,Interpretation_Cd,Interpretation_Desc,Result_Comments,Result,Result_Category,Last_Name,Middle_Name,First_Name,Patient_Local_ID,Current_Sex_Cd,Age_Reported,Age_Unit_Cd,Birth_Dt,PATIENT_DEATH_DATE,PATIENT_DEATH_IND,Phone_Number,Address_One,Address_Two,City,State_Cd,State,Zip_Code,County_Cd,County_Desc,PATIENT_RACE_CALC,PATIENT_ETHNICITY,Reporting_Facility_Name,Reporting_Facility_Address_One,Reporting_Facility_Address_Two,Reporting_Facility_Country,Reporting_Facility_County,Reporting_Facility_County_Desc,Reporting_Facility_City,Reporting_Facility_State_Cd,Reporting_Facility_State,Reporting_Facility_Zip_Cd,Reporting_Facility_Clia,Reporting_Facility_Phone_Nbr,Reporting_Facility_Phone_Ext,Ordering_Facility_Name,Ordering_Facility_Address_One,Ordering_Facility_Address_Two,Ordering_Facility_Country,Ordering_Facility_County,Ordering_Facility_County_Desc,Ordering_Facility_City,Ordering_Facility_State_Cd,Ordering_Facility_State,Ordering_Facility_Zip_Cd,Ordering_Facility_Phone_Nbr,Ordering_Facility_Phone_Ext,Ordering_Provider_First_Name,Ordering_Provider_Last_Name,Ordering_Provider_Address_One,Ordering_Provider_Address_Two,Ordering_Provider_Country,Ordering_Provider_County,Ordering_Provider_County_Desc,Ordering_Provider_City,Ordering_Provider_State_Cd,Ordering_Provider_State,Ordering_Provider_Zip_Cd,Ordering_Provider_Phone_Nbr,Ordering_Provider_Phone_Ext,ORDERING_PROVIDER_ID,Associated_Case_ID';
      SET @select_columns = 'core.Observation_UID,core.Lab_Local_ID,core.Ordered_Test_Cd,core.Ordered_Test_Desc,core.Ordered_Test_Code_System,core.ORDER_TEST_DATE,core.Electronic_Ind,core.Program_Area_Cd,core.Jurisdiction_Cd,core.Lab_Report_Dt,core.Lab_Rpt_Received_By_PH_Dt,core.Order_result_status,core.Jurisdiction_Nm,LEFT(core.Specimen_Cd,50),LEFT(core.Specimen_Desc,100),LEFT(core.Specimen_type_free_text,1000),LEFT(core.Specimen_Id,100),LEFT(core.SPECIMEN_SOURCE_SITE_CD,20),LEFT(core.SPECIMEN_SOURCE_SITE_DESC,100),LEFT(core.Testing_Lab_Accession_Number,199),core.Lab_Added_Dt,core.Lab_Update_Dt,core.Specimen_Coll_Dt,core.COVID_LAB_DATAMART_KEY,LEFT(core.Resulted_Test_Cd,50),LEFT(core.Resulted_Test_Desc,1000),LEFT(core.Resulted_Test_Code_System,300),LEFT(core.DEVICE_INSTANCE_ID_1,199),LEFT(core.DEVICE_INSTANCE_ID_2,199),LEFT(core.Test_result_status,100),LEFT(core.Test_Method_Desc,2000),LEFT(core.Device_Type_Id_1,199),LEFT(core.Device_Type_Id_2,199),LEFT(core.Perform_Facility_Name,100),LEFT(core.Testing_lab_Address_One,100),LEFT(core.Testing_lab_Address_Two,100),LEFT(core.Testing_lab_Country,20),LEFT(core.Testing_lab_county,20),LEFT(core.Testing_lab_county_Desc,255),LEFT(core.Testing_lab_City,100),LEFT(core.Testing_lab_State_Cd,20),LEFT(core.Testing_lab_State,2),LEFT(core.Testing_lab_Zip_Cd,20),LEFT(core.Result_Cd,20),LEFT(core.Result_Cd_Sys,300),LEFT(core.Result_Desc,300),core.Text_Result_Desc,LEFT(core.Numeric_Comparator_Cd,20),core.Numeric_Value_1,core.Numeric_Value_2,LEFT(core.Numeric_Unit_Cd,20),LEFT(core.Numeric_Low_Range,20),LEFT(core.Numeric_High_Range,20),LEFT(core.Numeric_Separator_Cd,10),LEFT(core.Interpretation_Cd,20),LEFT(core.Interpretation_Desc,100),core.Result_Comments,core.Result,LEFT(rslt.Result_Category,13),pat.Last_Name,pat.Middle_Name,pat.First_Name,pat.Patient_Local_ID,pat.Current_Sex_Cd,LEFT(pat.Age_Reported,10),LEFT(pat.Age_Unit_Cd,20),pat.Birth_Dt,pat.PATIENT_DEATH_DATE,LEFT(pat.PATIENT_DEATH_IND,20),LEFT(pat.Phone_Number,20),LEFT(pat.Address_One,100),LEFT(pat.Address_Two,100),LEFT(pat.City,100),LEFT(pat.State_Cd,20),LEFT(pat.State,2),LEFT(pat.Zip_Code,20),LEFT(pat.County_Cd,20),LEFT(pat.County_Desc,255),pat.PATIENT_RACE_CALC,LEFT(pat.PATIENT_ETHNICITY,20),LEFT(ent.Reporting_Facility_Name,100),LEFT(ent.Reporting_Facility_Address_One,100),LEFT(ent.Reporting_Facility_Address_Two,100),LEFT(ent.Reporting_Facility_Country,20),LEFT(ent.Reporting_Facility_County,20),LEFT(ent.Reporting_Facility_County_Desc,255),LEFT(ent.Reporting_Facility_City,100),LEFT(ent.Reporting_Facility_State_Cd,20),LEFT(ent.Reporting_Facility_State,2),LEFT(ent.Reporting_Facility_Zip_Cd,20),LEFT(ent.Reporting_Facility_Clia,20),LEFT(ent.Reporting_Facility_Phone_Nbr,20),LEFT(ent.Reporting_Facility_Phone_Ext,20),ent.Ordering_Facility_Name,ent.Ordering_Facility_Address_One,ent.Ordering_Facility_Address_Two,ent.Ordering_Facility_Country,ent.Ordering_Facility_County,ent.Ordering_Facility_County_Desc,ent.Ordering_Facility_City,LEFT(ent.Ordering_Facility_State_Cd,20),LEFT(ent.Ordering_Facility_State,2),ent.Ordering_Facility_Zip_Cd,ent.Ordering_Facility_Phone_Nbr,ent.Ordering_Facility_Phone_Ext,ent.Ordering_Provider_First_Name,ent.Ordering_Provider_Last_Name,ent.Ordering_Provider_Address_One,ent.Ordering_Provider_Address_Two,ent.Ordering_Provider_Country,ent.Ordering_Provider_County,ent.Ordering_Provider_County_Desc,ent.Ordering_Provider_City,ent.Ordering_Provider_State_Cd,LEFT(ent.Ordering_Provider_State,2),ent.Ordering_Provider_Zip_Cd,ent.Ordering_Provider_Phone_Nbr,ent.Ordering_Provider_Phone_Ext,LEFT(ent.ORDERING_PROVIDER_ID,199),assoc.Associated_Case_ID';
      -- Add AOE columns if they exist
      DECLARE @aoe_insert_columns NVARCHAR(max) = '';
      DECLARE @aoe_select_columns NVARCHAR(max) = '';
      SELECT @aoe_insert_columns += N',[' + Ltrim(Rtrim(column_name)) + ']',
             @aoe_select_columns += N',aoe.[' + Ltrim(Rtrim(column_name)) + ']'
      FROM   information_schema.columns
      WHERE  table_name = 'COVID_LAB_DATAMART'
      AND    table_schema = 'dbo'
      AND    column_name NOT IN ( 'Observation_UID',
                                 'Lab_Local_ID',
                                 'Ordered_Test_Cd',
                                 'Ordered_Test_Desc',
                                 'Ordered_Test_Code_System',
                                 'ORDER_TEST_DATE',
                                 'Electronic_Ind',
                                 'Program_Area_Cd',
                                 'Jurisdiction_Cd',
                                 'Lab_Report_Dt',
                                 'Lab_Rpt_Received_By_PH_Dt',
                                 'Order_result_status',
                                 'Jurisdiction_Nm',
                                 'Specimen_Cd',
                                 'Specimen_Desc',
                                 'Specimen_type_free_text',
                                 'Specimen_Id',
                                 'SPECIMEN_SOURCE_SITE_CD',
                                 'SPECIMEN_SOURCE_SITE_DESC',
                                 'Testing_Lab_Accession_Number',
                                 'Lab_Added_Dt',
                                 'Lab_Update_Dt',
                                 'Specimen_Coll_Dt',
                                 'COVID_LAB_DATAMART_KEY',
                                 'Resulted_Test_Cd',
                                 'Resulted_Test_Desc',
                                 'Resulted_Test_Code_System',
                                 'DEVICE_INSTANCE_ID_1',
                                 'DEVICE_INSTANCE_ID_2',
                                 'Test_result_status',
                                 'Test_Method_Desc',
                                 'Device_Type_Id_1',
                                 'Device_Type_Id_2',
                                 'Perform_Facility_Name',
                                 'Testing_lab_Address_One',
                                 'Testing_lab_Address_Two',
                                 'Testing_lab_Country',
                                 'Testing_lab_county',
                                 'Testing_lab_county_Desc',
                                 'Testing_lab_City',
                                 'Testing_lab_State_Cd',
                                 'Testing_lab_State',
                                 'Testing_lab_Zip_Cd',
                                 'Result_Cd',
                                 'Result_Cd_Sys',
                                 'Result_Desc',
                                 'Text_Result_Desc',
                                 'Numeric_Comparator_Cd',
                                 'Numeric_Value_1',
                                 'Numeric_Value_2',
                                 'Numeric_Unit_Cd',
                                 'Numeric_Low_Range',
                                 'Numeric_High_Range',
                                 'Numeric_Separator_Cd',
                                 'Interpretation_Cd',
                                 'Interpretation_Desc',
                                 'Result_Comments',
                                 'Result',
                                 'Result_Category',
                                 'Last_Name',
                                 'Middle_Name',
                                 'First_Name',
                                 'Patient_Local_ID',
                                 'Current_Sex_Cd',
                                 'Age_Reported',
                                 'Age_Unit_Cd',
                                 'Birth_Dt',
                                 'PATIENT_DEATH_DATE',
              'PATIENT_DEATH_IND',
                                 'Phone_Number',
                                 'Address_One',
                                 'Address_Two',
                                 'City',
                                 'State_Cd',
                                 'State',
                                 'Zip_Code',
                                 'County_Cd',
                                 'County_Desc',
                                 'PATIENT_RACE_CALC',
                                 'PATIENT_ETHNICITY',
                                 'Reporting_Facility_Name',
                                 'Reporting_Facility_Address_One',
                                 'Reporting_Facility_Address_Two',
                                 'Reporting_Facility_Country',
                                 'Reporting_Facility_County',
                                 'Reporting_Facility_County_Desc',
                                 'Reporting_Facility_City',
                                 'Reporting_Facility_State_Cd',
                                 'Reporting_Facility_State',
                                 'Reporting_Facility_Zip_Cd',
                                 'Reporting_Facility_Clia',
                                 'Reporting_Facility_Phone_Nbr',
                                 'Reporting_Facility_Phone_Ext',
                                 'Ordering_Facility_Name',
                                 'Ordering_Facility_Address_One',
                                 'Ordering_Facility_Address_Two',
                                 'Ordering_Facility_Country',
                                 'Ordering_Facility_County',
                                 'Ordering_Facility_County_Desc',
                                 'Ordering_Facility_City',
                                 'Ordering_Facility_State_Cd',
                                 'Ordering_Facility_State',
                                 'Ordering_Facility_Zip_Cd',
                                 'Ordering_Facility_Phone_Nbr',
                                 'Ordering_Facility_Phone_Ext',
                                 'Ordering_Provider_First_Name',
                                 'Ordering_Provider_Last_Name',
                                 'Ordering_Provider_Address_One',
                                 'Ordering_Provider_Address_Two',
                                 'Ordering_Provider_Country',
                                 'Ordering_Provider_County',
                                 'Ordering_Provider_County_Desc',
                                 'Ordering_Provider_City',
                                 'Ordering_Provider_State_Cd',
                                 'Ordering_Provider_State',
                                 'Ordering_Provider_Zip_Cd',
                                 'Ordering_Provider_Phone_Nbr',
                                 'Ordering_Provider_Phone_Ext',
                                 'ORDERING_PROVIDER_ID',
                                 'Associated_Case_ID',
                                 'record_status_cd',
                                 'rt_result');

      -- Build final INSERT statement
      SET @insert_sql = N'  INSERT INTO dbo.COVID_LAB_DATAMART (' + @insert_columns + @aoe_insert_columns + ')  SELECT DISTINCT ' + @select_columns + @aoe_select_columns + '  FROM #COVID_LAB_CORE_DATA core  LEFT JOIN #COVID_LAB_RSLT_TYPE rslt ON core.Observation_UID = rslt.RT_Observation_UID  AND core.Result = rslt.RT_Result  LEFT JOIN #COVID_LAB_PATIENT_DATA pat ON core.Observation_UID = pat.Pat_Observation_UID  LEFT JOIN #COVID_LAB_ENTITIES_DATA ent ON core.Observation_UID = ent.Entity_Observation_uid  LEFT JOIN #COVID_LAB_ASSOCIATIONS assoc ON core.Observation_UID = assoc.assoc_observation_uid  LEFT JOIN #COVID_LAB_AOE_DATA aoe ON core.observation_UID = aoe.AOE_observation_uid';
      EXEC sp_executesql
        @insert_sql;
      /* Logging for insert operation */
      SET @rowcount = @@ROWCOUNT;
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
                              'START' ,
                              @proc_step_no ,
                              @proc_step_name + ' - Insert' ,
                              @rowcount ,
                              LEFT(Isnull(@observation_id_list, 'NULL'),500)
                  );

      /* Commit the transaction */
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