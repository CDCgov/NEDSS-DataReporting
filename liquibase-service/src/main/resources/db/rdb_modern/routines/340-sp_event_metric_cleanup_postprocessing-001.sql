IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_nrt_odse_nbs_page_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_nrt_odse_nbs_page_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_nrt_odse_nbs_page_postprocessing]
    @page_id_list nvarchar(max),
    @debug bit = 'false'
AS
BEGIN

    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) AS BIGINT);
    PRINT @batch_id;
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT= 0;
    DECLARE @Proc_Step_Name VARCHAR(200)= '';
	DECLARE @Dataflow_Name VARCHAR(200) = 'nrt_odse_NBS_Page POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_nrt_odse_nbs_page_postprocessing';

    BEGIN TRY
        

        SET @Proc_Step_Name = 'SP_Start';

        INSERT INTO dbo.job_flow_log ( batch_id
                                    , [Dataflow_Name]
                                    , [package_Name]
                                    , [Status_Type]
                                    , [step_number]
                                    , [step_name]
                                    , [row_count]
                                    , [Msg_Description1])
        VALUES ( @batch_id
            , @Dataflow_Name
            , @Package_Name
            , 'START'
            , @Proc_Step_no
            , @Proc_Step_Name
            , 0
            , LEFT('ID List-' + @page_id_list, 500));
        
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GET CONFIG VALUE';

        


              
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

