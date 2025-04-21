CREATE OR ALTER PROCEDURE [dbo].[sp_ldf_generic_datamart_postprocessing] 
@phc_uids nvarchar(max),
@debug bit = 'false'
 as 
  BEGIN 
	declare @RowCount_no bigint;
	declare @proc_step_no float = 0;
	declare @proc_step_name varchar(200) = '';
	declare @batch_id bigint;
	declare @dataflow_name varchar(200) = 'sp_ldf_generic_datamart_postprocessing';
	declare @package_name varchar(200) = 'sp_ldf_generic_datamart_postprocessing';
	set @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);


 	BEGIN TRY 

		SET @Proc_Step_no = @PROC_STEP_NO + 1; 
		SET @Proc_Step_Name = 'SP_START';

		INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count], [Msg_Description1])
		VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
				@RowCount_no, LEFT (@phc_uids, 199)); 
--------------------------------------------------------------------------------------------------------

		BEGIN TRANSACTION
     
		SET @Proc_Step_no = @PROC_STEP_NO + 1;
		SET @Proc_Step_Name = 'Execute loading ldf_generic';

			
		EXECUTE  [dbo].[sp_execute_ldf_generic]  
			@phc_uids= @phc_uids
			,@batch_id= @batch_id
			,@target_table_name = 'LDF_GENERIC'
			,@debug = @debug;


		INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count], [Msg_Description1])
		VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
				@RowCount_no, LEFT (@phc_uids, 199)); 

		COMMIT TRANSACTION

--------------------------------------------------------------------------------------------------------

		BEGIN TRANSACTION
     
		SET @Proc_Step_no = @PROC_STEP_NO + 1; 
		SET @Proc_Step_Name = 'Execute loading ldf_generic1';

		EXECUTE  [dbo].[sp_execute_ldf_generic]  
		@phc_uids= @phc_uids
		,@batch_id= @batch_id
		,@target_table_name = 'LDF_GENERIC1'
		,@debug = @debug;

		INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count],[Msg_Description1])
		VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
				@RowCount_no, LEFT (@phc_uids, 199)); 

		COMMIT TRANSACTION

--------------------------------------------------------------------------------------------------------


		BEGIN TRANSACTION
     
		SET @Proc_Step_no = @PROC_STEP_NO + 1;
		SET @Proc_Step_Name = 'Execute loading ldf_generic2';

		EXECUTE  [dbo].[sp_execute_ldf_generic]  
		@phc_uids= @phc_uids
		,@batch_id= @batch_id
		,@target_table_name = 'LDF_GENERIC2'
		,@debug = @debug;


		INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count],[Msg_Description1])
		VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
				@RowCount_no, LEFT (@phc_uids, 199)); 

		COMMIT TRANSACTION

--------------------------------------------------------------------------------------------------------

		SET @Proc_Step_no = 999; 
		SET @Proc_Step_Name = 'SP_COMPLETE';

		INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES (@batch_id, @dataflow_name, @package_name, 'COMPLETE', @Proc_Step_no, @Proc_Step_Name,
				@RowCount_no); 

--------------------------------------------------------------------------------------------------------

	END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0   
            BEGIN
                ROLLBACK TRANSACTION;
            END;

        DECLARE @FullErrorMessage VARCHAR(8000) =
		'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
		'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		'Error Message: ' + ERROR_MESSAGE();


        INSERT INTO dbo.[job_flow_log] (
			batch_id
		 ,[Dataflow_Name]
		 ,[package_Name]
		 ,[Status_Type]
		 ,[step_number]
		 ,[step_name]
		 ,[Error_Description]
		 ,[row_count]
        )
        VALUES (
            @batch_id
            ,@dataflow_name
            ,@package_name
            ,'ERROR'
            ,@Proc_Step_no
            , @Proc_Step_name
            , @FullErrorMessage
            ,0
		);

        return -1 ;

    END CATCH

END;

------------------------------------------------------------------------------------------------------
