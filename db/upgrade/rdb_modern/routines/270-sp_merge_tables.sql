CREATE OR ALTER PROCEDURE [dbo].[sp_merge_tables] 
	@INPUT_TABLE1		VARCHAR(150) = '', 
	@INPUT_TABLE2		VARCHAR(150) = '', 
	@OUTPUT_TABLE       VARCHAR(150) = '', 
	@JOIN_ON_COLUMN       VARCHAR(150) = '',
	@batch_id bigint,
	@target_table_name nvarchar(max)
AS 
BEGIN 

	declare @RowCount_no bigint;
	declare @proc_step_no float = 0;
	declare @proc_step_name varchar(200) = '';
	declare @dataflow_name varchar(200) = 'sp_ldf_generic_datamart_postprocessing';
	declare @package_name varchar(200) = 'sp_merge_tables : '+lower(@target_table_name);
 
	DECLARE  @alterDynamicColumnList VARCHAR(MAX)=''; 
	DECLARE  @dynamicColumnUpdate VARCHAR(MAX)=''; 
	DECLARE  @dynamicColumnInsert VARCHAR(MAX)=''; 
 
	BEGIN TRY

	--------------------------------------------------------------------------------------------------------

	SET @Proc_Step_no = 1;
    SET @Proc_Step_Name = 'SP_Start';

        --Serialize input parameters to JSON for clean logging
        DECLARE @params_json VARCHAR(200) = JSON_QUERY((
            SELECT
                @INPUT_TABLE1 AS INPUT_TABLE1,
                @INPUT_TABLE2 AS INPUT_TABLE2,
                @OUTPUT_TABLE AS OUTPUT_TABLE,
                @JOIN_ON_COLUMN AS JOIN_ON_COLUMN,
				@batch_id as batch_id,
				@target_table_name as target_table_name
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ));


       INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count], [Msg_Description1])
		VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
				@RowCount_no, @params_json); 
       
	--------------------------------------------------------------------------------------------------------
	 
		SELECT   @alterDynamicColumnList  = @alterDynamicColumnList+ 'ALTER TABLE '+@OUTPUT_TABLE+' ADD [' + name   +  '] VARCHAR(4000) ', 
				 @dynamicColumnUpdate= @dynamicColumnUpdate + @OUTPUT_TABLE+'.[' +  name  + ']='  + @INPUT_TABLE1+'.['  +name  + '] ,' 
		FROM     tempdb.Sys.Columns WHERE Object_ID = Object_ID(+'tempdb..'+@INPUT_TABLE1) 
		AND name NOT IN  ( SELECT name FROM  tempdb.Sys.Columns WHERE Object_ID = Object_ID(+'tempdb..'+@INPUT_TABLE2)); 
 
		SELECT @dynamicColumnInsert= @dynamicColumnInsert +'['+  name  + '] ,' 
		FROM  tempdb.Sys.Columns WHERE Object_ID = Object_ID(+'tempdb..'+@INPUT_TABLE1); 
							 
			--PRINT '@alterDynamicColumnList -----------	'+CAST(@alterDynamicColumnList AS NVARCHAR(MAX)) 
			--PRINT '@dynamicColumnUpdate -----------	'+CAST(@dynamicColumnUpdate AS NVARCHAR(MAX)) 
			--PRINT '@dynamicColumnInsert -----------	'+CAST(@dynamicColumnInsert AS NVARCHAR(MAX)) 
 
		EXEC( 'SELECT  * INTO  '+ @OUTPUT_TABLE +'  FROM  '+ @INPUT_TABLE2); 
 
		IF @alterDynamicColumnList IS NOT NULL AND @alterDynamicColumnList!='' 
		BEGIN 
			EXEC( @alterDynamicColumnList); 
		END 
		 
		IF @dynamicColumnUpdate IS NOT NULL AND @dynamicColumnUpdate!='' 
		BEGIN 
			SET  @dynamicColumnUpdate=substring(@dynamicColumnUpdate,1,len(@dynamicColumnUpdate)-1); 
 
			EXEC ('UPDATE  '+@OUTPUT_TABLE+'  SET ' +   @dynamicColumnUpdate + ' FROM '+@OUTPUT_TABLE      
				+' INNER JOIN '+  @INPUT_TABLE1  +' ON '+  @OUTPUT_TABLE+'.['+@JOIN_ON_COLUMN+'] =' +  @INPUT_TABLE1+'.['+@JOIN_ON_COLUMN+']'); 
		END 
		 
		IF @dynamicColumnInsert IS NOT NULL AND @dynamicColumnInsert!='' 
		BEGIN 
			SET  @dynamicColumnInsert=substring(@dynamicColumnInsert,1,len(@dynamicColumnInsert)-1); 
			 
			EXEC ('INSERT INTO  '+@OUTPUT_TABLE+' (' +@dynamicColumnInsert + ') SELECT  ' + @dynamicColumnInsert + ' FROM '+@INPUT_TABLE1 +' WHERE '+ @JOIN_ON_COLUMN +' NOT IN (SELECT  '+@JOIN_ON_COLUMN+' FROM '+@OUTPUT_TABLE+')'); 
		END 
		 
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
