IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_batch_id_cleanup_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_batch_id_cleanup_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_batch_id_cleanup_postprocessing]
    @debug bit = 'false'
AS
BEGIN

    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) AS BIGINT);
    PRINT @batch_id;
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT= 0;
    DECLARE @Proc_Step_Name VARCHAR(200)= '';
	DECLARE @Dataflow_Name VARCHAR(200) = 'Batch Id Cleanup POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_batch_id_cleanup_postprocessing';
    DECLARE @StartDatetime DATETIME = GETDATE();
    DECLARE @LastSuccessTimestamp DATETIME;

    BEGIN TRY
        

        SET @Proc_Step_Name = 'SP_Start';

        INSERT INTO dbo.job_flow_log ( batch_id
                                    , [Dataflow_Name]
                                    , [package_Name]
                                    , [Status_Type]
                                    , [step_number]
                                    , [step_name]
                                    , [row_count])
        VALUES ( @batch_id
            , @Dataflow_Name
            , @Package_Name
            , 'START'
            , @Proc_Step_no
            , @Proc_Step_Name
            , 0);
        
--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GET MOST RECENT SUCCESS TIMESTAMP';

        SET @LastSuccessTimestamp = (SELECT TOP 1
                                        RUN_START_DTTM
                                    FROM dbo.nrt_delete_job_log
                                    WHERE RUN_STATUS IN ('Initial', 'Success')
                                    ORDER BY RUN_ID DESC);
        
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        if @debug = 'true'
            SELECT @Proc_Step_Name, @LastSuccessTimestamp as LastSuccessTimestamp;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #UPDATED_INVESTIGATIONS';

        SELECT
            public_health_case_uid
            , investigation_form_cd
            , case_type_cd
            , batch_id
        INTO #UPDATED_INVESTIGATIONS
        FROM dbo.nrt_investigation WITH (NOLOCK)
            WHERE refresh_datetime >= @LastSuccessTimestamp;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        if @debug = 'true'
            SELECT @Proc_Step_Name, * FROM #UPDATED_INVESTIGATIONS;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #OLD_INVESTIGATION_OBSERVATIONS';

        SELECT
            inv.public_health_case_uid
            , inv.batch_id as inv_batch_id
            , nio.batch_id as nio_batch_id
            , obs.observation_uid as branch_id
            , obs.batch_id as obs_batch_id
        INTO #OLD_INVESTIGATION_OBSERVATIONS
        FROM (SELECT * FROM #UPDATED_INVESTIGATIONS
            WHERE investigation_form_cd LIKE 'INV_FORM%') inv
            INNER JOIN dbo.nrt_investigation_observation nio WITH (NOLOCK)
                ON inv.public_health_case_uid = nio.public_health_case_uid
                    AND nio.batch_id < inv.batch_id
            INNER JOIN dbo.nrt_observation obs
                ON nio.branch_id = obs.observation_uid;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        if @debug = 'true'
            SELECT @Proc_Step_Name, * FROM #OLD_INVESTIGATION_OBSERVATIONS;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #UPDATED_INTERVIEWS';

        SELECT
            interview_uid
            , batch_id
        INTO #UPDATED_INTERVIEWS
        FROM dbo.nrt_interview WITH (NOLOCK)
            WHERE refresh_datetime >= @LastSuccessTimestamp;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        if @debug = 'true'
            SELECT @Proc_Step_Name, * FROM #UPDATED_INTERVIEWS;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_investigation_confirmation';

        DELETE tgt
        FROM dbo.nrt_investigation_confirmation tgt
            INNER JOIN #UPDATED_INVESTIGATIONS uinv
                ON tgt.public_health_case_uid = uinv.public_health_case_uid
                    AND tgt.batch_id < uinv.batch_id;
            
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT @Proc_Step_Name, @RowCount_no AS deleted_rows;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_page_case_answer';

        DELETE tgt
        FROM dbo.nrt_page_case_answer tgt
            INNER JOIN #UPDATED_INVESTIGATIONS uinv
                ON tgt.act_uid = uinv.public_health_case_uid
                    AND tgt.batch_id < uinv.batch_id;
            
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT @Proc_Step_Name, @RowCount_no AS deleted_rows;
 
        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_investigation_aggregate';

        DELETE tgt
        FROM dbo.nrt_investigation_aggregate tgt
            INNER JOIN (SELECT * FROM #UPDATED_INVESTIGATIONS WHERE case_type_cd = 'A') uinv
                ON tgt.act_uid = uinv.public_health_case_uid
                    AND tgt.batch_id < uinv.batch_id;
            
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT @Proc_Step_Name, @RowCount_no AS deleted_rows;
 
        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_observation_coded';

        DELETE tgt
        FROM dbo.nrt_observation_coded tgt
            INNER JOIN #OLD_INVESTIGATION_OBSERVATIONS uinv
                ON tgt.observation_uid = uinv.branch_id
                    AND tgt.batch_id = uinv.obs_batch_id;
            
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT @Proc_Step_Name, @RowCount_no AS deleted_rows;
 
        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_observation_txt';

        DELETE tgt
        FROM dbo.nrt_observation_txt tgt
            INNER JOIN #OLD_INVESTIGATION_OBSERVATIONS uinv
                ON tgt.observation_uid = uinv.branch_id
                    AND tgt.batch_id = uinv.obs_batch_id;
            
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT @Proc_Step_Name, @RowCount_no AS deleted_rows;
 
        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_observation_date';

        DELETE tgt
        FROM dbo.nrt_observation_date tgt
            INNER JOIN #OLD_INVESTIGATION_OBSERVATIONS uinv
                ON tgt.observation_uid = uinv.branch_id
                    AND tgt.batch_id = uinv.obs_batch_id;
            
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT @Proc_Step_Name, @RowCount_no AS deleted_rows;
 
        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_observation_numeric';

        DELETE tgt
        FROM dbo.nrt_observation_numeric tgt
            INNER JOIN #OLD_INVESTIGATION_OBSERVATIONS uinv
                ON tgt.observation_uid = uinv.branch_id
                    AND tgt.batch_id = uinv.obs_batch_id;
            
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT @Proc_Step_Name, @RowCount_no AS deleted_rows;
 
        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_investigation_observation';

        DELETE tgt
        FROM dbo.nrt_investigation_observation tgt
            INNER JOIN #OLD_INVESTIGATION_OBSERVATIONS uinv
                ON tgt.branch_id = uinv.branch_id
                    AND tgt.batch_id = uinv.nio_batch_id;
            
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT @Proc_Step_Name, @RowCount_no AS deleted_rows;
 
        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_interview_note';

        DELETE tgt
        FROM dbo.nrt_interview_note tgt
            INNER JOIN #UPDATED_INTERVIEWS uix
                ON tgt.interview_uid = uix.interview_uid
                    AND tgt.batch_id < uix.batch_id;
            
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT @Proc_Step_Name, @RowCount_no AS deleted_rows;
 
        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_interview_answer';

        DELETE tgt
        FROM dbo.nrt_interview_answer tgt
            INNER JOIN #UPDATED_INTERVIEWS uix
                ON tgt.interview_uid = uix.interview_uid
                    AND tgt.batch_id < uix.batch_id;
            
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT @Proc_Step_Name, @RowCount_no AS deleted_rows;
 
        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'INSERT SUCCESS RECORD INTO dbo.nrt_delete_job_log';

        INSERT INTO dbo.nrt_delete_job_log(
            RUN_START_DTTM,
            RUN_END_DTTM,
            RUN_STATUS
        )
        SELECT
            @StartDatetime,
            GETDATE(),
            'Success';
            
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------
        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);
    
-------------------------------------------------------------------------------------------
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

            INSERT INTO dbo.nrt_delete_job_log(
            RUN_START_DTTM,
            RUN_END_DTTM,
            RUN_STATUS
            )
            SELECT
                @StartDatetime,
                GETDATE(),
                'Failure';

        return -1 ;

    END CATCH

END;

