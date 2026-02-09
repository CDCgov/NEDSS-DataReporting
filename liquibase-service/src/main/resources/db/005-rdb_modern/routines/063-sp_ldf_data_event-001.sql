IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_ldf_data_event]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_ldf_data_event]
END
GO 

CREATE PROCEDURE dbo.sp_ldf_data_event @bus_obj_nm varchar(20), @ldf_uid nvarchar(max),  @bus_obj_uid_list nvarchar(max)
AS 
begin
	 begin try

		DECLARE @batch_id BIGINT;
		SET @batch_id = cast((format(getdate(), 'yyMMddHHmmssffff')) as bigint);
		DECLARE @dataflow_name NVARCHAR(200) = 'ldf_data PRE-Processing Event';
        DECLARE @package_name NVARCHAR(200) = 'NBS_ODSE.sp_ldf_data_event';
        
        INSERT INTO [dbo].[job_flow_log]
            ( batch_id
            , [Dataflow_Name]
            , [package_Name]
            , [Status_Type]
            , [step_number]
            , [step_name]
            , [row_count]
            , [Msg_Description1])
            VALUES ( @batch_id
                , @dataflow_name
                , @package_name
                , 'START'
                , 0
                , LEFT('Pre ID-' + @bus_obj_uid_list, 199)
                , 0
                , LEFT(@bus_obj_uid_list, 199));

			if @bus_obj_nm = 'PAT'  exec dbo.sp_ldf_patient_event @ldf_uid, @bus_obj_uid_list, @batch_id
			else if @bus_obj_nm = 'PRV'  exec dbo.sp_ldf_provider_event @ldf_uid , @bus_obj_uid_list, @batch_id 
			else if  @bus_obj_nm = 'ORG'  exec dbo.sp_ldf_organization_event @ldf_uid, @bus_obj_uid_list, @batch_id 
			else if  @bus_obj_nm = 'LAB'  exec dbo.sp_ldf_observation_event @ldf_uid, @bus_obj_uid_list, @batch_id 
			else if  @bus_obj_nm = 'PHC'  exec dbo.sp_ldf_phc_event @ldf_uid, @bus_obj_uid_list, @batch_id 
			else if  @bus_obj_nm = 'BMD'  exec dbo.sp_ldf_phc_event @ldf_uid, @bus_obj_uid_list, @batch_id
			else if  @bus_obj_nm = 'HEP'  exec dbo.sp_ldf_phc_event @ldf_uid, @bus_obj_uid_list, @batch_id
			else if  @bus_obj_nm = 'NIP'  exec dbo.sp_ldf_phc_event @ldf_uid, @bus_obj_uid_list, @batch_id
			else if  @bus_obj_nm = 'VAC'  exec dbo.sp_ldf_intervention_event @ldf_uid, @bus_obj_uid_list, @batch_id 
		
		INSERT INTO [dbo].[job_flow_log]
            ( batch_id
            , [Dataflow_Name]
            , [package_Name]
            , [Status_Type]
            , [step_number]
            , [step_name]
            , [row_count]
            , [Msg_Description1])
            VALUES ( @batch_id
                , @dataflow_name
                , @package_name
                , 'COMPLETE'
                , 0
                , LEFT('Pre ID-' + @bus_obj_uid_list, 199)
                , 0
                , LEFT(@bus_obj_uid_list, 199));

	end try

	BEGIN CATCH

     IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;
  
    	DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        , [Msg_Description1]
        , [Error_Description]
        )
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'ERROR'
               , 0
               , @dataflow_name
               , 0
               , LEFT(@bus_obj_uid_list, 199)
               , @FullErrorMessage
               );

        return @FullErrorMessage;

	END CATCH 
end
