IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_f_contact_record_case_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_f_contact_record_case_postprocessing]
END
GO 

CREATE PROCEDURE dbo.sp_f_contact_record_case_postprocessing(
    @contact_uids NVARCHAR(MAX),
    @debug bit = 'false')
as

BEGIN

    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
    DECLARE @Dataflow_Name VARCHAR(200) = 'F_CONTACT_RECORD_CASE Post-Processing Event';
    DECLARE @Package_Name VARCHAR(200) = 'sp_f_contact_record_case_postprocessing';




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
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);



        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #F_CRC_INIT_KEYS';
        --This step to capture from the nrt key table is needed because contact_uid is not maintained in the dimension
        SELECT
        	D_CONTACT_RECORD_KEY
        	,CONTACT_UID
        INTO #F_CRC_INIT_KEYS
        FROM dbo.NRT_CONTACT_KEY
        WHERE CONTACT_UID IN (SELECT value FROM STRING_SPLIT(@contact_uids, ',') );

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #F_CRC_INIT_KEYS;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #F_CRC_INIT';

        SELECT
        	crsik.D_CONTACT_RECORD_KEY,

        	nc.CONTACT_ENTITY_PHC_UID,
        	coalesce(inv3.INVESTIGATION_KEY, 1) as CONTACT_INVESTIGATION_KEY,

			nc.CONTACT_ENTITY_UID,
			coalesce(pt2.PATIENT_KEY, 1) as CONTACT_KEY,

			nc.NAMED_DURING_INTERVIEW_UID,
			coalesce(intw.D_INTERVIEW_KEY, 1) as CONTACT_INTERVIEW_KEY,

			nc.SUBJECT_ENTITY_PHC_UID,
			coalesce(inv2.INVESTIGATION_KEY, 1) as SUBJECT_INVESTIGATION_KEY,

			nc.SUBJECT_ENTITY_UID,
			coalesce(pt3.PATIENT_KEY, 1) as SUBJECT_KEY,

			nc.THIRD_PARTY_ENTITY_PHC_UID,
			coalesce(inv1.INVESTIGATION_KEY, 1) as THIRD_PARTY_INVESTIGATION_KEY,

			nc.THIRD_PARTY_ENTITY_UID,
			coalesce(pt1.PATIENT_KEY, 1) as THIRD_PARTY_ENTITY_KEY,

			nc.CONTACT_EXPOSURE_SITE_UID,
			coalesce(org.ORGANIZATION_KEY, 1) as CONTACT_EXPOSURE_SITE_KEY,

			nc.PROVIDER_CONTACT_INVESTIGATOR_UID,
			coalesce(pv1.PROVIDER_KEY, 1) as CONTACT_INVESTIGATOR_KEY,

			nc.DISPOSITIONED_BY_UID,
			coalesce(pv2.PROVIDER_KEY, 1) as DISPOSITIONED_BY_KEY

        INTO #F_CRC_INIT
		FROM
			#F_CRC_INIT_KEYS crsik
		LEFT JOIN
			dbo.NRT_CONTACT nc  with (nolock) on nc.CONTACT_UID = crsik.CONTACT_UID
		LEFT JOIN
			dbo.D_ORGANIZATION org  with (nolock) on org.ORGANIZATION_UID  = nc.CONTACT_EXPOSURE_SITE_UID
		LEFT JOIN
			dbo.D_PROVIDER pv1  with (nolock) on pv1.PROVIDER_UID  = nc.PROVIDER_CONTACT_INVESTIGATOR_UID
		LEFT JOIN
			dbo.D_PROVIDER pv2  with (nolock) on pv2.PROVIDER_UID  = nc.DISPOSITIONED_BY_UID
		LEFT JOIN
			dbo.D_PATIENT pt1  with (nolock) on pt1.PATIENT_UID = nc.THIRD_PARTY_ENTITY_UID
		LEFT JOIN
			dbo.D_PATIENT pt2  with (nolock) on pt2.PATIENT_UID = nc.CONTACT_ENTITY_UID
		LEFT JOIN
			dbo.D_PATIENT pt3  with (nolock) on pt3.PATIENT_UID = nc.SUBJECT_ENTITY_UID
		LEFT JOIN
			dbo.INVESTIGATION inv1  with (nolock) on inv1.CASE_UID = nc.THIRD_PARTY_ENTITY_PHC_UID
		LEFT JOIN
			dbo.INVESTIGATION inv2  with (nolock) on inv2.CASE_UID = nc.SUBJECT_ENTITY_PHC_UID
		LEFT JOIN
			dbo.INVESTIGATION inv3  with (nolock) on inv3.CASE_UID = nc.CONTACT_ENTITY_PHC_UID
		LEFT JOIN
			dbo.NRT_INTERVIEW_KEY intw  with (nolock) on intw.INTERVIEW_UID = nc.NAMED_DURING_INTERVIEW_UID
			;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

         if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #F_CRC_INIT;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #F_CRC_INIT_NEW';


        SELECT
        	init.D_CONTACT_RECORD_KEY,
            init.CONTACT_INVESTIGATION_KEY,
            init.CONTACT_KEY,
            init.CONTACT_INTERVIEW_KEY,
            init.SUBJECT_INVESTIGATION_KEY,
            init.SUBJECT_KEY,
            init.THIRD_PARTY_INVESTIGATION_KEY,
            init.THIRD_PARTY_ENTITY_KEY,
            init.CONTACT_EXPOSURE_SITE_KEY,
            init.CONTACT_INVESTIGATOR_KEY,
            init.DISPOSITIONED_BY_KEY
        INTO
        	#F_CRC_INIT_NEW
        FROM
        	#F_CRC_INIT init
        LEFT OUTER JOIN
        	dbo.F_CONTACT_RECORD_CASE fact ON fact.D_CONTACT_RECORD_KEY = init.D_CONTACT_RECORD_KEY
        WHERE
        	fact.D_CONTACT_RECORD_KEY is NULL ;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #F_CRC_INIT_NEW;


        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;




        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' INSERT INTO F_CONTACT_RECORD_CASE';

        INSERT INTO dbo.F_CONTACT_RECORD_CASE (
            D_CONTACT_RECORD_KEY,
            CONTACT_INVESTIGATION_KEY,
            CONTACT_KEY,
            CONTACT_INTERVIEW_KEY,
            SUBJECT_INVESTIGATION_KEY,
            SUBJECT_KEY,
            THIRD_PARTY_INVESTIGATION_KEY,
            THIRD_PARTY_ENTITY_KEY,
            CONTACT_EXPOSURE_SITE_KEY,
            CONTACT_INVESTIGATOR_KEY,
            DISPOSITIONED_BY_KEY
        )
        SELECT
            D_CONTACT_RECORD_KEY,
            CONTACT_INVESTIGATION_KEY,
            CONTACT_KEY,
            CONTACT_INTERVIEW_KEY,
            SUBJECT_INVESTIGATION_KEY,
            SUBJECT_KEY,
            THIRD_PARTY_INVESTIGATION_KEY,
            THIRD_PARTY_ENTITY_KEY,
            CONTACT_EXPOSURE_SITE_KEY,
            CONTACT_INVESTIGATOR_KEY,
            DISPOSITIONED_BY_KEY
        FROM
            #F_CRC_INIT_NEW
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' UPDATE F_CONTACT_RECORD_CASE';

        UPDATE fact
        SET
            fact.CONTACT_INVESTIGATION_KEY = crsik.CONTACT_INVESTIGATION_KEY,
            fact.CONTACT_KEY = crsik.CONTACT_KEY,
            fact.CONTACT_INTERVIEW_KEY = crsik.CONTACT_INTERVIEW_KEY,
            fact.SUBJECT_INVESTIGATION_KEY = crsik.SUBJECT_INVESTIGATION_KEY,
            fact.SUBJECT_KEY = crsik.SUBJECT_KEY,
            fact.THIRD_PARTY_INVESTIGATION_KEY = crsik.THIRD_PARTY_INVESTIGATION_KEY,
            fact.THIRD_PARTY_ENTITY_KEY = crsik.THIRD_PARTY_ENTITY_KEY,
            fact.CONTACT_EXPOSURE_SITE_KEY = crsik.CONTACT_EXPOSURE_SITE_KEY,
            fact.CONTACT_INVESTIGATOR_KEY = crsik.CONTACT_INVESTIGATOR_KEY,
            fact.DISPOSITIONED_BY_KEY = crsik.DISPOSITIONED_BY_KEY
        FROM dbo.F_CONTACT_RECORD_CASE fact
        INNER JOIN (
            SELECT *
            FROM #F_CRC_INIT
            WHERE D_CONTACT_RECORD_KEY NOT IN (SELECT D_CONTACT_RECORD_KEY FROM #F_CRC_INIT_NEW)
        ) crsik
        ON crsik.D_CONTACT_RECORD_KEY = fact.D_CONTACT_RECORD_KEY;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;



        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, 'COMPLETE', 0);

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


        INSERT INTO [dbo].[job_flow_log] ( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count])
        VALUES ( @batch_id, @Dataflow_Name, @Package_Name, 'ERROR', @Proc_Step_no, @Proc_Step_name, @FullErrorMessage, 0);


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

