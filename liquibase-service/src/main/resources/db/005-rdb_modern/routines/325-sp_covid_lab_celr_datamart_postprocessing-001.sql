IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_covid_lab_celr_datamart_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_covid_lab_celr_datamart_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_covid_lab_celr_datamart_postprocessing](
    @obs_uids NVARCHAR(MAX),
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


    DECLARE @Dataflow_Name VARCHAR(200) = 'COVID LAB CELR DATAMART Post-Processing Event';
    DECLARE @Package_Name  VARCHAR(200) = 'sp_covid_lab_celr_datamart_postprocessing';

    BEGIN try
        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';
        DECLARE @batch_id BIGINT;
        SET @batch_id = cast((Format(getdate(), 'yyMMddHHmmssffff')) AS BIGINT);
        IF @debug = 'true'
            SELECT @batch_id;


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


        --------------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #Patient_LIST';

        --Step 1: Create #Patient_LIST
        select  cld.Patient_Local_ID , cld.COVID_LAB_DATAMART_KEY
        into #Patient_LIST
        from dbo.covid_lab_datamart cld  with (nolock)
                 inner join (SELECT value FROM STRING_SPLIT(@obs_uids, ',')) obsList
                            on cld.Observation_Uid = obsList.value ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        if @debug = 'true' select @Proc_Step_Name as step, * from #Patient_LIST;

--------------------------------------------------------------------------------------------------------------------------------------------------
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' Check rows in #Patient_LIST';

        -- Step 2: Check if there are no rows in #Patient_LIST
        IF NOT EXISTS (SELECT 1 FROM #Patient_LIST)
            BEGIN
                if @debug='true'
                    PRINT 'No rows found in #Patient_LIST. Exiting procedure.';
                RETURN;
            END

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' DELETING FROM COVID_LAB_CELR_DATAMART';

        --Step 3: Delete records from COVID_CASE_DATAMART where PHC data is going to be inserted
        DELETE FROM dbo.COVID_LAB_CELR_DATAMART
        WHERE Patient_id IN (SELECT Patient_Local_ID FROM #Patient_LIST);

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

--------------------------------------------------------------------------------------------------------------------------------------------------


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
                                   SELECT
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
                                           END            AS patient_county,
                                       covid_lab_datamart.patient_ethnicity AS patient_ethnicity,
                                       covid_lab_datamart.age_reported      AS patient_age,
                                       covid_lab_datamart.age_unit_cd       AS patient_age_units,

                                       CONVERT(VARCHAR(max), illness_onset_date, 120) AS illness_onset_date,

                                       pregnant AS pregnant,

                                       symptomatic_for_disease AS symptomatic_for_disease,

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
                                       Substring(covid_lab_datamart.ordering_facility_zip_cd, 0, 6)               AS ordering_facility_zip_code,
                                       covid_lab_datamart.ordering_facility_phone_nbr                              AS ordering_facility_phone_number,
                                       covid_lab_datamart.order_result_status                                         AS order_result_status,
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
                                       NULL                   AS report_facil_data_source_app,
                                       'V2020-07-30'          AS csv_file_version_no,
                                       Getdate()              AS file_created_date,
                                       employed_in_healthcare AS employed_in_healthcare,

                                       first_test AS first_test,

                                       hospitalized AS hospitalized,

                                       icu AS icu,

                                       resident_congregate_setting AS resident_congregate_setting,

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

                                       patient_death_date AS patient_death_date,

                                       patient_death_ind AS patient_death_indicator,


                                       specimen_source_site_cd AS specimen_source_site_code,

                                       NULL                      AS specimen_source_site_code_sys,
                                       specimen_source_site_desc AS specimen_source_site_descrip,

                                       order_test_date AS order_test_date,

                                       testing_lab_county AS testing_lab_county,

                                       device_instance_id_1 AS device_instance_id_1,

                                       device_instance_id_2 AS device_instance_id_2,

                                       device_type_id_1 AS device_type_id_1,

                                       device_type_id_2 AS device_type_id_2

                                   FROM  dbo.covid_lab_datamart with (nolock)
                                             inner join #Patient_LIST plist
                                                        on covid_lab_datamart.patient_local_id  = plist.Patient_Local_ID
                                                            and covid_lab_datamart.COVID_LAB_DATAMART_KEY = plist.COVID_LAB_DATAMART_KEY)AS results) AS results2

        if @debug = 'true' select @Proc_Step_Name as step, * from #covid_lab_celr_datamart;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

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

        SELECT
            CAST(NULL AS BIGINT) AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            CAST(NULL AS VARCHAR(30)) AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            CAST(NULL AS VARCHAR(200)) AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=0;

    END TRY
    BEGIN catch
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

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

        SELECT
            0 AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            'Error' AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            @FullErrorMessage AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=1;
            
    END catch;
END;