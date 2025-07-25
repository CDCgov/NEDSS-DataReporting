IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_covid_vaccination_datamart_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_covid_vaccination_datamart_postprocessing]
END
GO 

CREATE PROCEDURE dbo.sp_covid_vaccination_datamart_postprocessing(
    @vac_uids NVARCHAR(MAX), @patient_uids  NVARCHAR(MAX),
    @debug bit = 'false')
    as

BEGIN
    /*
    * [Description]
    * This stored procedure is builds the covid_vaccination_datamart
    * 1. It builds VAC_LIST based on the incoming vac_uids and patient_uids
    * 2. Next we delete the vac_ids already present and then remove the LOG_DEL ones from the batch
    * 3. Then we join to various DIM tables to capture information to insert into the datamart
    */
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';


    DECLARE @Dataflow_Name VARCHAR(200) = 'COVID DATAMART Post-Processing Event';
    DECLARE @Package_Name VARCHAR(200) = 'sp_covid_vaccination_datamart_postprocessing';


BEGIN TRY

    SET @Proc_Step_no = 1;
    SET @Proc_Step_Name = 'SP_Start';
    DECLARE @batch_id bigint;
    SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmssffff')) AS bigint);

    if
        @debug = 'true'
    select @batch_id;


    SELECT @ROWCOUNT_NO = 0;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' GENERATING #PHC_LIST';


    --Step 1: Create #VAC_LIST
    select nrtVac.vaccination_uid, nrtVac.local_id, nrtVac.phc_uid, nrtVac.record_status_cd
    into #VAC_LIST
    from dbo.NRT_VACCINATION nrtVac
    inner join (
    	SELECT value FROM STRING_SPLIT(@vac_uids, ',')
    	union all
    	SELECT vaccination_uid FROM dbo.NRT_VACCINATION where patient_uid in (select value from STRING_SPLIT(@patient_uids, ','))
    ) batch
    on nrtVac.vaccination_uid = batch.value and nrtVac.material_cd IN('207', '208', '213');

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


    if
    @debug = 'true'
        select @Proc_Step_Name as step, *
        from #VAC_LIST;

--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' DELETING FROM COVID_VACCINATION_DATAMART';

    --Step 2: Delete records from COVID_VACCINATION_DATAMART where PHC data is going to be inserted
	DELETE FROM dbo.COVID_VACCINATION_DATAMART
	WHERE local_id IN (SELECT local_id FROM #VAC_LIST);

    --Step 3.1: Delete records from COVID_VACCINATION_DATAMART where PHC is LOG_DEL
    -- this is already deleted from datamart in prior step
    DELETE FROM #VAC_LIST
    WHERE record_status_cd = 'LOG_DEL';

    -- Step 3.2: Check if there are no rows in #VAC_LIST
    IF NOT EXISTS (SELECT 1 FROM #VAC_LIST)
    BEGIN
        if @debug='true'
            PRINT 'No rows found in #TempTable. Exiting procedure.';
        RETURN;
    END

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' INSERTING data into COVID_VACCINATION_DATAMART';

    --Step 4: Insert into table

	BEGIN TRANSACTION; 

   with UID_CTE as (
    select
        nrtVac.phc_uid as public_health_case_uid,
        nrtinv.local_id as local_id,
        nrtVac.patient_uid as PATIENT_UID,
        nrtVac.organization_uid as ORGANIZATION_UID,
        nrtVac.provider_uid as PROVIDER_UID,
        nrtVac.vaccination_uid as VACCINATION_UID,
        nrtVac.add_time as ADD_TIME,
        COALESCE(nrtinv.activity_from_time, nrtinv.add_time) AS INVESTIGATION_DT
    from dbo.NRT_VACCINATION nrtVac
    inner join #VAC_LIST vacList on nrtVac.vaccination_uid = vacList.vaccination_uid
    left outer join
        dbo.NRT_INVESTIGATION nrtinv
            on nrtVac.phc_uid = nrtinv.public_health_case_uid
    )
    INSERT INTO dbo.COVID_VACCINATION_DATAMART
	SELECT DISTINCT
	        CONCAT(CONCAT(cte.vaccination_uid, cte.public_health_Case_uid), RIGHT(YEAR(cte.add_time), 2)) AS COVID_VACCINATION_DATAMART_KEY,
	        cte.local_id AS INVESTIGATION_LOCAL_ID,
	        cte.INVESTIGATION_DT,
	        dvac.VACCINATION_ADMINISTERED_NM,
	        dvac.LOCAL_ID,
	        dvac.VACCINE_ADMINISTERED_DATE,
	        dvac.VACCINATION_ANATOMICAL_SITE,
	        dvac.AGE_AT_VACCINATION,
	        dvac.AGE_AT_VACCINATION_UNIT,
	        dvac.VACCINE_MANUFACTURER_NM,
	        dvac.VACCINE_LOT_NUMBER_TXT,
	        dvac.VACCINE_EXPIRATION_DT,
	        dvac.VACCINE_DOSE_NBR,
	        dvac.VACCINE_INFO_SOURCE,
	        dvac.RECORD_STATUS_CD,
	        dvac.ELECTRONIC_IND,
	        patient.PATIENT_LOCAL_ID,
	        patient.PATIENT_LAST_NAME,
	        patient.PATIENT_FIRST_NAME,
	        patient.PATIENT_MIDDLE_NAME,
	        patient.PATIENT_CURRENT_SEX,
	        patient.PATIENT_BIRTH_SEX,
	        patient.PATIENT_DOB,
	        patient.PATIENT_AGE_REPORTED,
	        patient.PATIENT_AGE_REPORTED_UNIT,
	        patient.PATIENT_STREET_ADDRESS_1,
	        patient.PATIENT_STREET_ADDRESS_2,
	        patient.PATIENT_CITY,
	        patient.PATIENT_STATE_CODE,
	        patient.PATIENT_ZIP,
	        patient.PATIENT_COUNTY,
	        patient.PATIENT_COUNTRY,
	        patient.PATIENT_SSN,
	        patient.PATIENT_PRIMARY_OCCUPATION,
	        patient.PATIENT_MARITAL_STATUS,
	        patient.PATIENT_RACE_CALC_DETAILS,
	        patient.PATIENT_ETHNICITY,
	        patient.PATIENT_BIRTH_COUNTRY,
	        provider.PROVIDER_FIRST_NAME,
	        provider.PROVIDER_LAST_NAME,
	        provider.PROVIDER_NAME_DEGREE,
	        provider.PROVIDER_STREET_ADDRESS_1,
	        provider.PROVIDER_STREET_ADDRESS_2,
	        provider.PROVIDER_CITY,
	        provider.PROVIDER_STATE_CODE,
	        provider.PROVIDER_ZIP,
	        provider.PROVIDER_COUNTY,
	        provider.PROVIDER_COUNTRY,
	        org.ORGANIZATION_NAME,
	        org.ORGANIZATION_STREET_ADDRESS_1,
	        org.ORGANIZATION_STREET_ADDRESS_2,
	        org.ORGANIZATION_CITY,
	        org.ORGANIZATION_STATE_CODE,
	        org.ORGANIZATION_ZIP,
	        org.ORGANIZATION_COUNTY,
	        org.ORGANIZATION_COUNTRY,
	        dvac.ADD_TIME AS ADD_TIME,
	        dvac.ADD_USER_ID AS ADD_USER_ID,
	        dvac.LAST_CHG_TIME AS LAST_CHG_TIME,
	        dvac.LAST_CHG_USER_ID AS LAST_CHG_USER_ID
	FROM UID_CTE cte
	inner join dbo.D_VACCINATION dVac WITH(NOLOCK) ON cte.VACCINATION_UID = dVac.VACCINATION_UID
	left outer join dbo.D_PATIENT patient WITH (NOLOCK) ON cte.PATIENT_UID= patient.PATIENT_UID
	left outer join dbo.D_ORGANIZATION org WITH (NOLOCK) ON cte.ORGANIZATION_UID= org.ORGANIZATION_UID
	left outer join dbo.D_PROVIDER provider WITH (NOLOCK) ON cte.PROVIDER_UID= provider.PROVIDER_UID
	;

	COMMIT TRANSACTION;
	
    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


--------------------------------------------------------------------------------------------------------------------------------------------------
    INSERT INTO [dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name,@Package_Name, 'COMPLETE', 999, 'COMPLETE', 0);

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
    BEGIN CATCH

		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

	     -- Construct the error message string with all details:
	    DECLARE @FullErrorMessage VARCHAR(8000) =
	        'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
	        'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
	        'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
	        'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
	        'Error Message: ' + ERROR_MESSAGE();

		INSERT INTO [dbo].[job_flow_log] ( batch_id
		    , [Dataflow_Name]
		    , [package_Name]
		    , [Status_Type]
		    , [step_number]
		    , [step_name]
		    , [Error_Description]
		    , [row_count])
		VALUES ( @batch_id
		        , @Dataflow_Name
		        , @Package_Name
		        , 'ERROR'
		        , @Proc_Step_no
		        , @Proc_Step_name
		        , @FullErrorMessage
		        , 0);


		SELECT
            0 AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            'Error' AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            @FullErrorMessage AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=1;

END CATCH

END

    ;