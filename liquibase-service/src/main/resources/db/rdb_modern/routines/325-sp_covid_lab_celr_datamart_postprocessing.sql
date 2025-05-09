CREATE OR ALTER PROCEDURE [dbo].[sp_covid_lab_celr_datamart_postprocessing](
@lab_uids NVARCHAR(MAX),
@debug BIT = 'false'
)
AS
  BEGIN
	    /*
	* [Description]
	* This stored procedure is builds the covid_lab_celr_datamart_postprocessing
	* 1. It builds a subquery from COVID_LAB_DATAMART
	* 2. Derived computed columns based on conditions.
	* 3. Delete table if exists COVID_LAB_CELR_DATAMART
	* 4. The data is specific to patient's health and test data related to covid.
	Final step joins all the Derived column data then insert data into COVID_LAB_CELR_DATAMART.
	*/
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';


    DECLARE @Dataflow_Name  VARCHAR(200) = 'COVID DATAMART Post-Processing Event';
    DECLARE @Package_Name   VARCHAR(200) = 'sp_covid_lab_celr_datamart_postprocessing';

    BEGIN try
      SET @Proc_Step_no = 1;
      SET @Proc_Step_Name = 'SP_Start';
      DECLARE @batch_id BIGINT;
      SET @batch_id = Cast((Format(Getdate(), 'yyMMddHHmmssffff')) AS BIGINT);
      IF @debug = 'true'
      SELECT @batch_id;

      SELECT @ROWCOUNT_NO = 0;

      INSERT INTO [DBO].[JOB_FLOW_LOG]
                  (
                              batch_id,
                              [DATAFLOW_NAME],
                              [PACKAGE_NAME],
                              [STATUS_TYPE],
                              [STEP_NUMBER],
                              [STEP_NAME],
                              [ROW_COUNT]
                  )
                  VALUES
                  (
                              @BATCH_ID,
                              @Dataflow_Name,
                              @Package_Name,
                              'START',
                              @PROC_STEP_NO,
                              @PROC_STEP_NAME,
                              @ROWCOUNT_NO
                  );

      BEGIN TRANSACTION;

 --------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' GENERATING #PHC_LIST';

    --Step 1: Create #PHC_LIST
    select cld.COVID_LAB_DATAMART_KEY
    into #LAB_LIST
    from dbo.covid_lab_datamart cld
    inner join (SELECT value FROM STRING_SPLIT(@lab_uids, ',')) labList
    on cld.COVID_LAB_DATAMART_KEY = labList.value ;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


    if
    @debug = 'true'
        select @Proc_Step_Name as step, *
        from #LAB_LIST;

--------------------------------------------------------------------------------------------------------------------------------------------------



    -- Step 2: Check if there are no rows in #LAB_LIST
    IF NOT EXISTS (SELECT 1 FROM #LAB_LIST)
    BEGIN
        if @debug='true'
            PRINT 'No rows found in #TempTable. Exiting procedure.';
        RETURN;
    END


    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' DELETING FROM COVID_LAB_CELR_DATAMART';

    --Step 3: Delete records from COVID_CASE_DATAMART where PHC data is going to be inserted
	DELETE FROM dbo.COVID_LAB_CELR_DATAMART
	WHERE COVID_LAB_DATAMART_KEY IN (SELECT COVID_LAB_DATAMART_KEY FROM #LAB_LIST);

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' GENERATING #covid_lab_celr_datamart';
--      SET @Proc_Step_no = @PROC_STEP_NO + 1;
--      SET @Proc_Step_Name = 'Drop table COVID_LAB_CELR_DATAMART if exists';
--      IF Object_id('dbo.COVID_LAB_CELR_DATAMART', 'U') IS NOT NULL
--      BEGIN
--        DROP TABLE dbo.covid_lab_celr_datamart
--        SELECT @ROWCOUNT_NO = 0;
--
--        INSERT INTO [DBO].[JOB_FLOW_LOG]
--                    (
--                                batch_id,
--                                [DATAFLOW_NAME],
--                                [PACKAGE_NAME],
--                                [STATUS_TYPE],
--                                [STEP_NUMBER],
--                                [STEP_NAME],
--                                [ROW_COUNT]
--                    )
--                    VALUES
--                    (
--                                @BATCH_ID,
--                                @Dataflow_Name,
--                                @Package_Name,
--                                'START',
--                                @PROC_STEP_NO,
--                                @PROC_STEP_NAME,
--                                @ROWCOUNT_NO
--                    );
--
--     END


      SET @Proc_Step_no = @PROC_STEP_NO + 1;
      SET @Proc_Step_Name = 'SELECT DATA INTO #COVID_LAB_CELR_DATAMART';

      SELECT *
      INTO   #covid_lab_celr_datamart
      FROM   (
                         SELECT      results.*
                         FROM        (
                                            SELECT NULL AS illness_onset_date,
                                                   NULL AS pregnant,
                                                   NULL AS symptomatic_for_disease,
                                                   NULL AS employed_in_healthcare,
                                                   NULL AS first_test,
                                                   NULL AS hospitalized,
                                                   NULL AS icu,
                                                   NULL AS resident_congregate_setting,
                                                   NULL AS ordering_provider_id,
                                                   NULL AS patient_death_date,
                                                   NULL AS patient_death_ind,
                                                   NULL AS specimen_source_site_cd,
                                                   NULL AS specimen_source_site_desc,
                                                   NULL AS order_test_date,
                                                   NULL AS perform_facility_county,
                                                   NULL AS device_instance_id_1,
                                                   NULL AS device_instance_id_2,
                                                   NULL AS device_type_id_1,
                                                   NULL AS device_type_id_2 ) AS test
                         CROSS apply
                                     (
                                            SELECT covid_lab_datamart.COVID_LAB_DATAMART_KEY 					AS COVID_CASE_DATAMART_KEY,
                                            	   covid_lab_datamart.testing_lab_accession_number              AS testing_lab_accession_number,
                                                   covid_lab_datamart.specimen_id                               AS testing_lab_specimen_id,
                                                   NULL                                                         AS submitter_unique_sample_id,
                                                   NULL                                                         AS submitter_sample_id_assigner,
                                        COALESCE(covid_lab_datamart.reporting_facility_name, 'NULL') AS testing_lab_name,
                                                   covid_lab_datamart.reporting_facility_clia                   AS testing_lab_id,
                                                   CASE
                                                          WHEN covid_lab_datamart.reporting_facility_clia IS NULL THEN NULL
                                                          WHEN covid_lab_datamart.reporting_facility_clia IS NOT NULL THEN 'CLIA'
                                                   END AS testing_lab_id_type,
                                                   CASE
                                                          WHEN (
                                                                        covid_lab_datamart.reporting_facility_address_one IS NOT NULL
                                                                 AND    covid_lab_datamart.reporting_facility_address_one <> ''
                                                                 AND    covid_lab_datamart.reporting_facility_address_two IS NOT NULL
                                                                 AND    covid_lab_datamart.reporting_facility_address_two <> '') THEN Concat(covid_lab_datamart.reporting_facility_address_one, '; ', covid_lab_datamart.reporting_facility_address_two)
                                                          WHEN (
                                                                        covid_lab_datamart.reporting_facility_address_one IS NOT NULL
                                                                 AND    covid_lab_datamart.reporting_facility_address_one <> '')
                                                          AND    (
                                                                        covid_lab_datamart.reporting_facility_address_two IS NULL
                                                                 OR     covid_lab_datamart.reporting_facility_address_two = '') THEN covid_lab_datamart.reporting_facility_address_one
                                                          WHEN (
                                                                        covid_lab_datamart.reporting_facility_address_one IS NULL
                                                                 OR     covid_lab_datamart.reporting_facility_address_one = '')
                                                          AND    (
                                                                      covid_lab_datamart.reporting_facility_address_two IS NOT NULL
                                                                 AND    covid_lab_datamart.reporting_facility_address_two <> '') THEN covid_lab_datamart.reporting_facility_address_two
                                                          ELSE NULL
                                                   END                                                           AS 'Testing_lab_street_address',
                                                   covid_lab_datamart.reporting_facility_city                    AS testing_lab_city,
                                                   covid_lab_datamart.reporting_facility_state                   AS testing_lab_state,
                                                   Substring(covid_lab_datamart.reporting_facility_zip_cd, 0, 6) AS testing_lab_zip_code,
                                                   covid_lab_datamart.patient_local_id                           AS patient_id,
                                                   'NBS'                                                         AS patient_id_assigner,
                                                   'PI'                                                          AS patient_id_type,
                                                   covid_lab_datamart.birth_dt                                   AS patient_dob,
                                                   covid_lab_datamart.current_sex_cd                             AS patient_gender,
                                                   CONVERT(VARCHAR(max), covid_lab_datamart.patient_race_calc)   AS patient_race,
                        covid_lab_datamart.city                                       AS patient_city,
                                                   COALESCE(COALESCE(
                                                                      (
                                                                      SELECT state_nm
                                                                      FROM   dbo.nrt_srte_state_code
                                                                      WHERE  state_cd = covid_lab_datamart.state ), state ), 'NULL') AS patient_state,
                                                   Substring(covid_lab_datamart.zip_code, 0, 6)                                      AS patient_zip_code,
                                                   CASE
                                                          WHEN Isnumeric(covid_lab_datamart.county_cd)= 1
                                                          AND    Len(covid_lab_datamart.county_cd)= 4 THEN Concat('0', covid_lab_datamart.county_cd)
                                                          ELSE covid_lab_datamart.county_cd
                                                   END                                  AS patient_county,
                                                   covid_lab_datamart.patient_ethnicity AS patient_ethnicity,
                                                   covid_lab_datamart.age_reported      AS patient_age,
                                                   covid_lab_datamart.age_unit_cd       AS patient_age_units,
                                                   --CONVERT(VARCHAR(MAX),FORMAT(COVID_LAB_DATAMART.ILLNESS_ONSET_DT, 'yyyyMMddHHmmss')) AS Illness_Onset_Date,
                                                   CONVERT(VARCHAR(max), illness_onset_date, 120) AS illness_onset_date,
                                                   --ILLNESS_ONSET_DT AS Illness_Onset_Date,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'ILLNESS_ONSET_DT' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN CONVERT(VARCHAR(MAX),FORMAT(ILLNESS_ONSET_DT, 'yyyyMMddHHmmss'))
													ELSE NULL
													END AS Illness_Onset_Date,
													*/
                                                   pregnant AS pregnant,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'PATIENT_PREGNANT_IND' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN PATIENT_PREGNANT_IND
													ELSE NULL
													END AS Pregnant,
													*/
                                                   symptomatic_for_disease AS symptomatic_for_disease,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'SYMPTOMATIC' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN SYMPTOMATIC
													ELSE NULL
													END AS Symptomatic_for_disease,
													*/
                                                   NULL                                                         AS patient_location,
                                                   NULL                                                         AS employed_in_high_risk_setting,
                                                   CONVERT(VARCHAR(max), covid_lab_datamart.associated_case_id) AS public_health_case_id,
                                                   CASE
                                                          WHEN (
                                                                        covid_lab_datamart.specimen_desc = ''
                                                                 OR     covid_lab_datamart.specimen_desc IS NULL)
                                                          AND    (
          covid_lab_datamart.specimen_type_free_text = ''
                                                                 OR     covid_lab_datamart.specimen_type_free_text IS NULL)
                                                          AND    (
                                                                        covid_lab_datamart.specimen_cd = ''
                                                                 OR     covid_lab_datamart.specimen_cd IS NULL) THEN '119324002'
                                                          ELSE specimen_cd
                                                   END AS specimen_type_code,
                                                   CASE
                                                          WHEN (
                                                                        covid_lab_datamart.specimen_desc = ''
                                                                 OR     covid_lab_datamart.specimen_desc IS NULL)
                                                          AND    (
                                                                        covid_lab_datamart.specimen_cd IS NOT NULL
                                                                 AND    covid_lab_datamart.specimen_cd <> '') THEN dbo.Escapespecialcharacters(specimen_cd)
                                                          WHEN (
                                                                        covid_lab_datamart.specimen_desc = ''
                                                                 OR     covid_lab_datamart.specimen_desc IS NULL)
                                                          AND    (
                                                                        covid_lab_datamart.specimen_cd IS NULL
                                                                 OR     covid_lab_datamart.specimen_cd = '')
                                                          AND    (
                                                                        covid_lab_datamart.specimen_type_free_text = ''
                                                                 OR     covid_lab_datamart.specimen_type_free_text IS NULL) THEN 'Specimen of unknown material'
                                                          ELSE dbo.Escapespecialcharacters(specimen_desc)
                                                   END AS specimen_type_description,
                                                   CASE
                                                          WHEN (
                                                                        covid_lab_datamart.specimen_desc = ''
                                                                 OR     covid_lab_datamart.specimen_desc IS NULL)
                                                          AND    (
                                                                        covid_lab_datamart.specimen_cd IS NULL
                                                                 OR     covid_lab_datamart.specimen_cd = '')
                                                          AND    (
                                                                        covid_lab_datamart.specimen_type_free_text = ''
                                                                 OR     covid_lab_datamart.specimen_type_free_text IS NULL) THEN 'SCT'
                                                          ELSE NULL
                                                   END                                                                              AS specimen_type_code_system,
                                                   dbo.Escapespecialcharacters(covid_lab_datamart.specimen_type_free_text)          AS specimen_type_free_text,
                                                   COALESCE(CONVERT(VARCHAR(23), covid_lab_datamart.specimen_coll_dt, 121), '0000') AS specimen_collection_date_time,
                                     NULL                                                                AS specimen_received_date_time,
                                                   'NULL'                                                                           AS ordering_entity_name,
                                                   covid_lab_datamart.ordering_provider_last_name                                   AS ordering_provider_last_name,
                                                   covid_lab_datamart.ordering_provider_first_name                                  AS ordering_provider_first_name,
                                                   CASE
                                                          WHEN (
                                                                        covid_lab_datamart.ordering_provider_address_one IS NOT NULL
                                                                 AND    covid_lab_datamart.ordering_provider_address_one <> ''
                                                                 AND    covid_lab_datamart.ordering_provider_address_two IS NOT NULL
                                                                 AND    covid_lab_datamart.ordering_provider_address_two <> '') THEN Concat(covid_lab_datamart.ordering_provider_address_one, '; ', covid_lab_datamart.ordering_provider_address_two)
                                                          WHEN (
                                                                        covid_lab_datamart.ordering_provider_address_one IS NOT NULL
                                                                 AND    covid_lab_datamart.ordering_provider_address_one <> '')
                                                          AND    (
                                                                        covid_lab_datamart.ordering_provider_address_two IS NULL
                                                                 OR     covid_lab_datamart.ordering_provider_address_two = '') THEN covid_lab_datamart.ordering_provider_address_one
                                                          WHEN (
                                                                        covid_lab_datamart.ordering_provider_address_one IS NULL
                                                                 OR     covid_lab_datamart.ordering_provider_address_one = '')
                                                          AND    (
                                                                        covid_lab_datamart.ordering_provider_address_two IS NOT NULL
                                                                 AND    covid_lab_datamart.ordering_provider_address_two <> '') THEN covid_lab_datamart.ordering_provider_address_two
                                                          ELSE NULL
                                                   END                                                          AS 'Ordering_provider_street',
                                                   covid_lab_datamart.ordering_provider_city                    AS ordering_provider_city,
                                                   COALESCE(ordering_provider_state, 'NULL')                    AS ordering_provider_state,
                                                   Substring(covid_lab_datamart.ordering_provider_zip_cd, 0, 6) AS ordering_provider_zip_code,
                                                   covid_lab_datamart.ordering_facility_name                    AS ordering_facility_name,
                                                   CASE
                                                          WHEN (
                                                                        covid_lab_datamart.ordering_facility_address_one IS NOT NULL
                                                                 AND    covid_lab_datamart.ordering_facility_address_one <> ''
                    AND    covid_lab_datamart.ordering_facility_address_two IS NOT NULL
                                                      AND    covid_lab_datamart.ordering_facility_address_two <> '') THEN Concat(covid_lab_datamart.ordering_facility_address_one, '; ', covid_lab_datamart.ordering_facility_address_two)
                                                          WHEN (
                                                                        covid_lab_datamart.ordering_facility_address_one IS NOT NULL
                                                                 AND    covid_lab_datamart.ordering_facility_address_one <> '')
                                                          AND    (
                                                                        covid_lab_datamart.ordering_facility_address_two IS NULL
                                                                 OR     covid_lab_datamart.ordering_facility_address_two = '') THEN covid_lab_datamart.ordering_facility_address_one
                                                          WHEN (
                                                                        covid_lab_datamart.ordering_facility_address_one IS NULL
                                                                 OR     covid_lab_datamart.ordering_facility_address_one = '')
                                                          AND    (
                                                                        covid_lab_datamart.ordering_facility_address_two IS NOT NULL
                                                                 AND    covid_lab_datamart.ordering_facility_address_two <> '') THEN covid_lab_datamart.ordering_facility_address_two
                                                          ELSE ''
                                                   END                                                                                     AS 'Ordering_facility_street',
                                                   covid_lab_datamart.ordering_facility_city                                               AS ordering_facility_city,
                                                   COALESCE(ordering_facility_state, 'NULL')                AS ordering_facility_state,
                                                   Substring(covid_lab_datamart.ordering_facility_zip_cd, 0, 6)                            AS ordering_facility_zip_code,
                                                   covid_lab_datamart.ordering_facility_phone_nbr                                          AS ordering_facility_phone_number,
                                                   covid_lab_datamart.order_result_status                                                  AS order_result_status,
                                                   covid_lab_datamart.lab_rpt_received_by_ph_dt                                            AS date_result_released,
                                                   covid_lab_datamart.ordered_test_cd                                                      AS ordered_test_code,
                                                   dbo.Escapespecialcharacters(covid_lab_datamart.ordered_test_desc)                       AS ordered_test_description,
                                                   covid_lab_datamart.ordered_test_code_system                                             AS ordered_test_code_system,
                                                   covid_lab_datamart.resulted_test_cd                                                     AS test_performed_code,
                                                   dbo.Escapespecialcharacters(covid_lab_datamart.resulted_test_desc)                      AS test_performed_description,
                                                   covid_lab_datamart.resulted_test_code_system                                            AS test_performed_code_system,
                                                   covid_lab_datamart.result_cd                                                            AS test_result_coded,
                                                   dbo.Escapespecialcharacters(covid_lab_datamart.result_desc)                             AS test_result_description,
                                                   covid_lab_datamart.result_cd_sys                                                        AS test_result_code_system,
                                                   dbo.Escapespecialcharacters(CONVERT(VARCHAR(max), covid_lab_datamart.text_result_desc)) AS test_result_free_text,
                                                   covid_lab_datamart.numeric_comparator_cd                                                AS test_result_comparator,
                                                   covid_lab_datamart.numeric_value_1                                                      AS test_result_number,
                                                   covid_lab_datamart.numeric_separator_cd                                                 AS test_result_number_separator,
                                                   covid_lab_datamart.numeric_value_2                                                      AS test_result_number2,
                                                   covid_lab_datamart.numeric_unit_cd                                                      AS test_result_units,
                                                   CASE
                                                          WHEN (
                                                                        covid_lab_datamart.numeric_low_range IS NOT NULL
                                                                 AND    covid_lab_datamart.numeric_low_range <> ''
                                                                 AND    covid_lab_datamart.numeric_high_range IS NOT NULL
                                                                 AND    covid_lab_datamart.numeric_high_range <> '') THEN Concat(covid_lab_datamart.numeric_low_range, '-', covid_lab_datamart.numeric_high_range)
                                                          WHEN (
                                                                        covid_lab_datamart.numeric_low_range IS NOT NULL
                                                                 AND    covid_lab_datamart.numeric_low_range <> '')
                                                          AND    (
                                                                        covid_lab_datamart.numeric_high_range IS NULL
                                                                 OR     covid_lab_datamart.numeric_high_range = '') THEN covid_lab_datamart.numeric_low_range
                                                          WHEN (
                                                                        covid_lab_datamart.numeric_low_range IS NULL
                                                                 OR     covid_lab_datamart.numeric_low_range = '')
                                                          AND    (
                                                                        covid_lab_datamart.numeric_high_range IS NOT NULL
                                                                 AND    covid_lab_datamart.numeric_high_range <> '') THEN covid_lab_datamart.numeric_high_range
                                                          ELSE NULL
                                                   END                                                                     AS 'Reference_range',
                                                   COALESCE(NULLIF(Trim(covid_lab_datamart.interpretation_desc), ''), 'F') AS abnormal_flag,
              NULL                                                                    AS test_method_description,
                                                   COALESCE(covid_lab_datamart.test_result_status, 'NULL')     AS test_result_status,
                                                   covid_lab_datamart.lab_report_dt                                        AS test_date,
                                                   covid_lab_datamart.reporting_facility_name                              AS reporting_facility_name,
                                                   covid_lab_datamart.reporting_facility_clia                              AS reporting_facility_id,
                                                   --COVID_LAB_DATAMART.LAB_UPDATE_DT AS lab_update_dt,-- column removed as per feedback received on 11/13/2020
                                                   NULL                   AS report_facil_data_source_app,
                                                   'V2020-07-30'          AS csv_file_version_no,
                                                   Getdate()              AS file_created_date,
                                                   employed_in_healthcare AS employed_in_healthcare,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'EMPLOYED_IN_HEALTHCARE' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN EMPLOYED_IN_HEALTHCARE
													ELSE NULL
													END AS Employed_in_healthcare,
													*/
                                                   first_test AS first_test,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'FIRST_TEST' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN FIRST_TEST
													ELSE NULL
													END AS First_test,
													*/
                                                   hospitalized AS hospitalized,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'HOSPITALIZED' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN HOSPITALIZED
													ELSE NULL
													END AS Hospitalized,
													*/
                                                   icu AS icu,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'ICU' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN ICU
													ELSE NULL
													END AS ICU,
													*/
                                                   resident_congregate_setting AS resident_congregate_setting,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'RESIDENT_CONGREGATE_SETTING' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN RESIDENT_CONGREGATE_SETTING
													ELSE NULL
													END AS Resident_congregate_setting,
													*/
                                                   NULL AS most_recent_test_date,
                                                   NULL AS most_recent_test_result,
                                                   NULL AS most_recent_test_type,
                                                   NULL AS disease_symptoms,
                                                   NULL AS patient_occupation,
                                                   NULL AS patient_residency_type,
                                                   CASE
                                                          WHEN Isnumeric(covid_lab_datamart.ordering_facility_county)= 1
                                                          AND    Len(covid_lab_datamart.ordering_facility_county)= 4 THEN Concat('0', covid_lab_datamart.ordering_facility_county)
                                                          ELSE covid_lab_datamart.ordering_facility_county
                                                   END AS ordering_facility_county,
                               CASE
                                                          WHEN Isnumeric(covid_lab_datamart.ordering_provider_county)= 1
                                                          AND    Len(covid_lab_datamart.ordering_provider_county)= 4 THEN Concat('0', covid_lab_datamart.ordering_provider_county)
                                                          ELSE covid_lab_datamart.ordering_provider_county
                                                   END                  AS ordering_provider_county,
                                                   ordering_provider_id AS ordering_provider_id,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'ORDERING_PROVIDER_ID' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN ORDERING_PROVIDER_ID
													ELSE NULL
													END AS Ordering_provider_ID,
													*/
                                                   patient_death_date AS patient_death_date,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'PATIENT_DEATH_DATE' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN PATIENT_DEATH_DATE
													ELSE NULL
													END AS Patient_death_date,
													*/
                                                   patient_death_ind AS patient_death_indicator,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'PATIENT_DEATH_IND' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN PATIENT_DEATH_IND
													ELSE NULL
													END AS Patient_death_indicator,
													*/
                                                   specimen_source_site_cd AS specimen_source_site_code,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'SPECIMEN_SOURCE_SITE_CD' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN SPECIMEN_SOURCE_SITE_CD
													ELSE NULL
													END AS Specimen_source_site_code,
													*/
                                                   NULL                      AS specimen_source_site_code_sys,
                                                   specimen_source_site_desc AS specimen_source_site_descrip,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'SPECIMEN_SOURCE_SITE_DESC' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN SPECIMEN_SOURCE_SITE_DESC
													ELSE NULL
													END AS Specimen_source_site_descrip,
													*/
                                                   order_test_date AS order_test_date,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'ORDER_TEST_DATE' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN ORDER_TEST_DATE
													ELSE NULL
													END AS Order_test_date,
													*/
                                                   testing_lab_county AS testing_lab_county,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'PERFORM_FACILITY_COUNTY' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN PERFORM_FACILITY_COUNTY
													ELSE NULL
													END AS Testing_lab_county,
													*/
                                                   device_instance_id_1 AS device_instance_id_1,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'DEVICE_INSTANCE_ID_1' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN DEVICE_INSTANCE_ID_1
													ELSE NULL
													END AS Device_instance_ID_1,
													*/
                           device_instance_id_2 AS device_instance_id_2,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'DEVICE_INSTANCE_ID_2' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN DEVICE_INSTANCE_ID_2
													ELSE NULL
													END AS Device_instance_ID_2,
													*/
                                                   device_type_id_1 AS device_type_id_1,
                                                   /*
													CASE
													WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'DEVICE_TYPE_ID_1' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
													THEN DEVICE_TYPE_ID_1
													ELSE NULL
													END AS Device_type_ID_1,
													*/
                                                   device_type_id_2 AS device_type_id_2
												                                                   /*
												CASE
												WHEN (SELECT COUNT(*) FROM SYS.COLUMNS WHERE NAME = N'DEVICE_TYPE_ID_2' AND OBJECT_ID = OBJECT_ID(N'COVID_LAB_DATAMART'))=1
												THEN DEVICE_TYPE_ID_2
												ELSE NULL
												END AS Device_type_ID_2
												*/
                                                   --INTO dbo.COVID_LAB_CELR_DATAMART
                                            FROM   dbo.covid_lab_datamart inner join #LAB_LIST LSB
                                            		on covid_lab_datamart.COVID_LAB_DATAMART_KEY = LAB.COVID_LAB_DATAMART_KEY)AS results) AS results2
											      --LEFT OUTER JOIN
											      --DBO.COVID_CASE_DATAMART ON (TRIM(SUBSTRING(Associated_Case_ID,0,COALESCE(NULLIF(CHARINDEX(',',Associated_Case_ID),'0'),LEN(Associated_Case_ID)+1)))) = COVID_CASE_DATAMART.INV_LOCAL_ID
											      --Modify the where clause to determine all the COVID Tests
											      /* WHERE(Result_Cd IN
											(
											SELECT DISTINCT
											lab_test_cd code_list
											FROM dbo.nrt_srte_lab_test
											WHERE default_condition_cd = '11065'
											UNION
											SELECT DISTINCT
											loinc_cd code_list
											FROM dbo.nrt_srte_Loinc_condition
											WHERE condition_cd = '11065'
											)
											OR ((Result_Desc LIKE '%cov%'
											OR Result_Desc LIKE '%result%')
											AND Result_Desc NOT LIKE '%symptom%'
											AND Result_Desc NOT LIKE '%source%'
											AND Result_Desc NOT LIKE '%performed by:%'))*/
      SELECT @ROWCOUNT_NO = @@ROWCOUNT;

      INSERT INTO [DBO].[JOB_FLOW_LOG]
                  (
                              batch_id,
                              [DATAFLOW_NAME],
                              [PACKAGE_NAME],
                              [STATUS_TYPE],
                              [STEP_NUMBER],
                              [STEP_NAME],
                              [ROW_COUNT]
                  )
                  VALUES
                  (
                              @BATCH_ID,
                              @Dataflow_Name,
                              @Package_Name,
                              'START',
                              @PROC_STEP_NO,
                              @PROC_STEP_NAME,
                              @ROWCOUNT_NO
                  );

      SET @Proc_Step_no = @PROC_STEP_NO + 1;
      SET @Proc_Step_Name = 'INSERT DATA INTO COVID_LAB_CELR_DATAMART';


    INSERT INTO dbo.COVID_LAB_CELR_DATAMART
    SELECT * FROM #COVID_LAB_CELR_DATAMART

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;

    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


      SET @Proc_Step_no = @Proc_Step_no + 1;
      SET @Proc_Step_Name = '999';
      INSERT INTO dbo.job_flow_log
                  (
                              batch_id,
                              [Dataflow_Name],
                              [package_Name],
                              [Status_Type],
                              [step_number],
                              [step_name],
                              [row_count]
                  )
                  VALUES
                  (
                              @batch_id,
                              @Dataflow_Name,
                              @Package_Name,
                              'COMPLETE',
                              @Proc_Step_no,
                              @Proc_Step_name,
                              @RowCount_no
                  );

      COMMIT TRANSACTION;
    END try
    BEGIN catch
      IF @@TRANCOUNT > 0
      ROLLBACK TRANSACTION;
       -- Construct the error message string with all details:
      DECLARE @FullErrorMessage VARCHAR(8000) =
		            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
		            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		            'Error Message: ' + ERROR_MESSAGE();

      INSERT INTO [dbo].[job_flow_log]
                  (
                              batch_id ,
                              [Dataflow_Name] ,
                              [package_Name] ,
                              [Status_Type] ,
                              [step_number] ,
                              [step_name] ,
                              [Error_Description] ,
                              [row_count]
                  )
                  VALUES
                  (
                              @batch_id ,
                              @Dataflow_Name ,
                              @Package_Name ,
                              'ERROR' ,
                              @Proc_Step_no ,
                              @Proc_Step_name ,
                              @FullErrorMessage ,
                              0
                  );

      RETURN -1;
    END catch;
  END;