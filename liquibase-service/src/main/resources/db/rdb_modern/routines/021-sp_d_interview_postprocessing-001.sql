CREATE OR ALTER PROCEDURE dbo.sp_d_interview_postprocessing_COPY(
    @interview_uids NVARCHAR(MAX),
    @debug bit = 'false')
as

BEGIN

    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';
        DECLARE @batch_id bigint;
        SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmss')) AS bigint);

        BEGIN TRANSACTION;

        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;



        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #INTERVIEW_INIT';

        SELECT
            INTERVIEW_UID,
            interview_status_cd AS IX_STATUS_CD,
            interview_date AS IX_DATE,
            interviewee_role_cd AS IX_INTERVIEWEE_ROLE_CD,
            interview_type_cd AS IX_TYPE_CD,
            interview_loc_cd AS IX_LOCATION_CD,
            local_id,
            record_status_cd,
            record_status_time,
            ADD_TIME,
            add_user_id,
            last_chg_time,
            last_chg_user_id,
            version_ctrl_nbr,
            IX_STATUS,
            IX_TYPE,
            IX_LOCATION
        FROM dbo.nrt_interview
        WHERE interview_uid in (SELECT value FROM STRING_SPLIT(@interview_uids, ','));

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #NEW_COLUMNS';

        SELECT
            
        FROM dbo.nrt_interview_columns
        WHERE col in (SELECT value FROM STRING_SPLIT(@interview_uids, ','));

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #INTERVIEW_INIT';

        SELECT
            INTERVIEW_UID,
            interview_status_cd AS IX_STATUS_CD,
            interview_date AS IX_DATE,
            interviewee_role_cd AS IX_INTERVIEWEE_ROLE_CD,
            interview_type_cd AS IX_TYPE_CD,
            interview_loc_cd AS IX_LOCATION_CD,
            local_id,
            record_status_cd,
            record_status_time,
            ADD_TIME,
            add_user_id,
            last_chg_time,
            last_chg_user_id,
            version_ctrl_nbr,
            IX_STATUS,
            IX_TYPE,
            IX_LOCATION
        FROM dbo.nrt_interview
        WHERE interview_uid in (SELECT value FROM STRING_SPLIT(@interview_uids, ','));

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;



        
    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;


        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [Error_Description]
                                         , [row_count])
        VALUES ( @batch_id
               , 'D_INTERVIEW'
               , 'D_INTERVIEW'
               , 'ERROR'
               , @Proc_Step_no
               , 'ERROR - ' + @Proc_Step_name
               , 'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
               , 0);


        return -1;

    END CATCH

END

    ;