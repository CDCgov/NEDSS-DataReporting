IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_event_metric_cleanup_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_event_metric_cleanup_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_event_metric_cleanup_postprocessing]
    @debug bit = 'false'
AS
BEGIN

    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) AS BIGINT);
    PRINT @batch_id;
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT= 0;
    DECLARE @Proc_Step_Name VARCHAR(200)= '';
	DECLARE @Dataflow_Name VARCHAR(200) = 'Event Metric Cleanup POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_event_metric_cleanup_postprocessing';

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
            @PROC_STEP_NAME = 'GET CONFIG VALUE';

        
        DECLARE @metrics_gobackby_days INTEGER;

        SET @metrics_gobackby_days = CAST((SELECT MAX(config_value) FROM dbo.nrt_odse_NBS_configuration WITH (NOLOCK)
                                        WHERE config_key = 'METRICS_GOBACKBY_DAYS') AS INTEGER);

        if @debug = 'true'
            SELECT @Proc_Step_Name, @metrics_gobackby_days;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GET COUNT IN dbo.EVENT_METRIC_INC';

        
        DECLARE @em_inc_current_records INTEGER = (
            SELECT COUNT(*) FROM dbo.EVENT_METRIC_INC WITH (NOLOCK)
                WHERE DATEDIFF(day, ADD_TIME, GETDATE()) <= @metrics_gobackby_days
        );
        
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT @Proc_Step_Name, @em_inc_current_records AS em_inc_current_records;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GET COUNT IN dbo.EVENT_METRIC';

        
        DECLARE @em_current_records INTEGER = (
            SELECT COUNT(*) FROM dbo.EVENT_METRIC WITH (NOLOCK)
        );
        
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT @Proc_Step_Name, @em_current_records AS em_current_records;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'CREATE LOAD FLAG';

        /*
            If the number of records that would be valid in EVENT_METRIC is greater in
            EVENT_METRIC_INC.

            When records need to be loaded, we will SKIP the delete step. The states
            where records need to be loaded and records need to be deleted should be
            mutually exclusive.
        */
        DECLARE @load_records bit;
        SET @load_records = CASE 
                                WHEN @em_inc_current_records > @em_current_records THEN 1
                                ELSE 0
                            END;
        
        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT @Proc_Step_Name, @load_records AS load_flag;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------

        IF (@load_records = 1)
        BEGIN

        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'ADD RECORDS TO dbo.EVENT_METRIC';

            INSERT INTO dbo.EVENT_METRIC
            (
                [EVENT_TYPE],
                [EVENT_UID], 
                [LOCAL_ID], 
                [LOCAL_PATIENT_ID], 
                [CONDITION_CD], 
                [CONDITION_DESC_TXT],
                [PROG_AREA_CD], 
                [PROG_AREA_DESC_TXT], 
                [PROGRAM_JURISDICTION_OID], 
                [JURISDICTION_CD],
                [JURISDICTION_DESC_TXT],
                [RECORD_STATUS_CD], 
                [RECORD_STATUS_DESC_TXT], 
                [RECORD_STATUS_TIME], 
                [ELECTRONIC_IND], 
                [STATUS_CD],
                [STATUS_DESC_TXT], 
                [STATUS_TIME], 
                [ADD_TIME], 
                [ADD_USER_ID], 
                [LAST_CHG_TIME], 
                [LAST_CHG_USER_ID],
                [CASE_CLASS_CD], 
                [CASE_CLASS_DESC_TXT], 
                [INVESTIGATION_STATUS_CD], 
                [INVESTIGATION_STATUS_DESC_TXT],
                [ADD_USER_NAME], 
                [LAST_CHG_USER_NAME]
            )
            SELECT
                emi.[EVENT_TYPE],
                emi.[EVENT_UID], 
                emi.[LOCAL_ID], 
                emi.[LOCAL_PATIENT_ID], 
                emi.[CONDITION_CD], 
                emi.[CONDITION_DESC_TXT],
                emi.[PROG_AREA_CD], 
                emi.[PROG_AREA_DESC_TXT], 
                emi.[PROGRAM_JURISDICTION_OID], 
                emi.[JURISDICTION_CD],
                emi.[JURISDICTION_DESC_TXT],
                emi.[RECORD_STATUS_CD], 
                emi.[RECORD_STATUS_DESC_TXT], 
                emi.[RECORD_STATUS_TIME], 
                emi.[ELECTRONIC_IND], 
                emi.[STATUS_CD],
                emi.[STATUS_DESC_TXT], 
                emi.[STATUS_TIME], 
                emi.[ADD_TIME], 
                emi.[ADD_USER_ID], 
                emi.[LAST_CHG_TIME], 
                emi.[LAST_CHG_USER_ID],
                emi.[CASE_CLASS_CD], 
                emi.[CASE_CLASS_DESC_TXT], 
                emi.[INVESTIGATION_STATUS_CD], 
                emi.[INVESTIGATION_STATUS_DESC_TXT],
                emi.[ADD_USER_NAME], 
                emi.[LAST_CHG_USER_NAME]
            FROM (
                SELECT * FROM dbo.EVENT_METRIC_INC WITH (NOLOCK)
                WHERE DATEDIFF(day, ADD_TIME, GETDATE()) <= @metrics_gobackby_days
                    AND ADD_TIME <= (SELECT MIN(ADD_TIME) FROM dbo.EVENT_METRIC WITH (NOLOCK))
            ) emi
            LEFT JOIN dbo.EVENT_METRIC em WITH (NOLOCK)
                ON emi.EVENT_TYPE = em.EVENT_TYPE
                    AND emi.EVENT_UID = em.EVENT_UID
            WHERE em.EVENT_TYPE IS NULL AND em.EVENT_UID IS NULL;


            SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

            IF @debug = 'true'
                SELECT @Proc_Step_Name, @RowCount_no AS added_rows;

            INSERT INTO [dbo].[job_flow_log] 
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);
        COMMIT TRANSACTION;

        END
        ELSE 

        BEGIN
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETE OLD EVENTS FROM dbo.EVENT_METRIC';

            
            DELETE em 
            FROM dbo.EVENT_METRIC em
            WHERE DATEDIFF(day, ADD_TIME, GETDATE()) > @metrics_gobackby_days;
            
            SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

            IF @debug = 'true'
                SELECT @Proc_Step_Name, @RowCount_no AS deleted_rows;

            INSERT INTO [dbo].[job_flow_log] 
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);

        END;

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

        return -1 ;

    END CATCH

END;

