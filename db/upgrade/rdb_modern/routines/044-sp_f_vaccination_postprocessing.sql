IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_f_vaccination_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_f_vaccination_postprocessing]
END
GO

CREATE PROCEDURE dbo.sp_f_vaccination_postprocessing(
    @vac_uids NVARCHAR(MAX),
    @debug bit = 'false')
as

BEGIN

    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
    DECLARE @ColumnAdd_sql NVARCHAR(MAX) = '';

    DECLARE @Dataflow_Name VARCHAR(200) = 'F_VACCINATION Post-Processing Event';
    DECLARE @Package_Name VARCHAR(200) = 'sp_f_vaccination_postprocessing';


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
        SET @PROC_STEP_NAME = ' GENERATING #F_VAC_INIT_KEYS';

        SELECT D_VACCINATION_KEY
             , VACCINATION_UID
        INTO #F_VAC_INIT_KEYS
        FROM dbo.NRT_VACCINATION_KEY
        WHERE VACCINATION_UID IN (SELECT value FROM STRING_SPLIT(@vac_uids, ','));

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #F_VAC_INIT_KEYS;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #F_VAC_INIT';

        SELECT dim.D_VACCINATION_KEY,

               nc.PATIENT_UID,
               coalesce(pt1.PATIENT_KEY, 1)        as PATIENT_KEY,

               nc.PROVIDER_UID,
               coalesce(pv1.PROVIDER_KEY, 1)       as VACCINE_GIVEN_BY_KEY,

               nc.ORGANIZATION_UID,
               coalesce(org.ORGANIZATION_KEY, 1)   as VACCINE_GIVEN_BY_ORG_KEY,

               1                                   as D_VACCINATION_REPEAT_KEY,

               nc.PHC_UID,
               coalesce(inv1.INVESTIGATION_KEY, 1) as INVESTIGATION_KEY

        INTO #F_VAC_INIT
        FROM (SELECT *
              FROM dbo.NRT_VACCINATION
              WHERE VACCINATION_UID IN (SELECT value FROM STRING_SPLIT(@vac_uids, ','))) nc
                 LEFT JOIN
             dbo.D_VACCINATION dim with (nolock) on dim.VACCINATION_UID = nc.VACCINATION_UID
                 LEFT JOIN
             dbo.D_ORGANIZATION org with (nolock) on org.ORGANIZATION_UID = nc.ORGANIZATION_UID
                 LEFT JOIN
             dbo.D_PROVIDER pv1 with (nolock) on pv1.PROVIDER_UID = nc.PROVIDER_UID
                 LEFT JOIN
             dbo.D_PATIENT pt1 with (nolock) on pt1.PATIENT_UID = nc.PATIENT_UID
                 LEFT JOIN
             dbo.INVESTIGATION inv1 with (nolock) on inv1.CASE_UID = nc.PHC_UID;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #F_VAC_INIT_NEW';


        SELECT init.D_VACCINATION_KEY,
               init.PATIENT_KEY,
               init.VACCINE_GIVEN_BY_KEY,
               init.VACCINE_GIVEN_BY_ORG_KEY,
               init.D_VACCINATION_REPEAT_KEY,
               init.INVESTIGATION_KEY
        INTO #F_VAC_INIT_NEW
        FROM #F_VAC_INIT init
                 LEFT OUTER JOIN
             dbo.F_VACCINATION fact with (nolock) ON fact.D_VACCINATION_KEY = init.D_VACCINATION_KEY
        WHERE fact.D_VACCINATION_KEY is NULL;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #F_VAC_INIT_NEW;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' INSERT INTO F_VACCINATION';

        INSERT INTO dbo.F_VACCINATION (D_VACCINATION_KEY,
                                       PATIENT_KEY,
                                       VACCINE_GIVEN_BY_KEY,
                                       VACCINE_GIVEN_BY_ORG_KEY,
                                       D_VACCINATION_REPEAT_KEY,
                                       INVESTIGATION_KEY)
        SELECT D_VACCINATION_KEY,
               PATIENT_KEY,
               VACCINE_GIVEN_BY_KEY,
               VACCINE_GIVEN_BY_ORG_KEY,
               D_VACCINATION_REPEAT_KEY,
               INVESTIGATION_KEY
        FROM #F_VAC_INIT_NEW;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' UPDATE F_VACCINATION';

        UPDATE fact
        SET fact.PATIENT_KEY              = src.PATIENT_KEY,
            fact.VACCINE_GIVEN_BY_KEY     = src.VACCINE_GIVEN_BY_KEY,
            fact.VACCINE_GIVEN_BY_ORG_KEY = src.VACCINE_GIVEN_BY_ORG_KEY,
            fact.D_VACCINATION_REPEAT_KEY = src.D_VACCINATION_REPEAT_KEY,
            fact.INVESTIGATION_KEY        = src.INVESTIGATION_KEY
        FROM dbo.F_VACCINATION fact
                 INNER JOIN (SELECT *
                             FROM #F_VAC_INIT
                             WHERE D_VACCINATION_KEY NOT IN (SELECT D_VACCINATION_KEY FROM #F_VAC_INIT_NEW)) src
                            ON src.D_VACCINATION_KEY = fact.D_VACCINATION_KEY;


        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, 'COMPLETE', 0);

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) +
            CHAR(10) + -- Carriage return and line feed for new lines
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
            CAST(NULL AS BIGINT) AS public_health_case_uid,
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

