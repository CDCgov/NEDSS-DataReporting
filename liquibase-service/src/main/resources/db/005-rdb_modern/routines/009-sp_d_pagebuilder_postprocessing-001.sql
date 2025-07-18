IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_d_pagebuilder_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_d_pagebuilder_postprocessing]
END
GO 

CREATE PROCEDURE dbo.sp_d_pagebuilder_postprocessing
	   	@Batch_id bigint,
	   	@phc_id_list nvarchar(max),
	   	@rdb_table_name varchar(250) = 'D_INV_ADMINISTRATIVE',
	 	@category varchar(250) = 'INV_ADMINISTRATIVE',
		@debug bit = 'false'
AS
BEGIN
	DECLARE @RowCount_no int;
	DECLARE @Proc_Step_no float= 0;
	DECLARE @Proc_Step_Name varchar(200)= '';
	DECLARE @batch_start_time datetime2(7)= NULL;
	DECLARE @batch_end_time datetime2(7)= NULL;

	BEGIN TRY

		SET @Proc_Step_no = 1;
		SET @Proc_Step_Name = 'SP_Start';

		BEGIN TRANSACTION;

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count], [msg_description1] )
		VALUES( @Batch_id, @category, '' + @rdb_table_name, 'START', @Proc_Step_no, @Proc_Step_Name, 0, LEFT(@phc_id_list, 500));


		SET @Proc_Step_no = 2;
		SET @Proc_Step_Name = ' Add new columns to table ' + @rdb_table_name;

		-- create table rdb_ui_metadata_INV_ADMINISTRATIVE as

		Create Table #Temp_Query_Table
		(
			ID int IDENTITY(1, 1), QUERY_stmt varchar(5000)
		);
		DECLARE @column_query varchar(5000);
		DECLARE @Max_Query_No int;
		DECLARE @Curr_Query_No int;
		DECLARE @ColumnList varchar(5000);

		INSERT INTO #Temp_Query_Table
			   SELECT 'ALTER TABLE dbo.' + @rdb_table_name +' ADD ['+COLUMN_NAME+'] '+DATA_TYPE+CASE
																								  WHEN DATA_TYPE IN( 'char', 'varchar', 'nchar', 'nvarchar' ) THEN ' ('+COALESCE(CAST(NULLIF(CHARACTER_MAXIMUM_LENGTH, -1) AS varchar(10)), CAST(CHARACTER_MAXIMUM_LENGTH as varchar(10)))+')'
																								  ELSE ''
																								  END+CASE
																									  WHEN IS_NULLABLE = 'NO' THEN ' NOT NULL'
																									  ELSE ' NULL'
																									  END
			   FROM INFORMATION_SCHEMA.COLUMNS AS c
			   WHERE TABLE_NAME = 'S_' + @category AND
					 NOT EXISTS
			   (
				   SELECT 1
				   FROM INFORMATION_SCHEMA.COLUMNS
				   WHERE TABLE_NAME = @rdb_table_name AND
						 COLUMN_NAME = c.COLUMN_NAME
			   ) AND
					 LOWER(COLUMN_NAME) NOT IN( LOWER('PAGE_CASE_UID'), 'last_chg_time' );

		if @debug  = 'true' select * from #Temp_Query_Table;

		SET @Max_Query_No =
		(
			SELECT MAX(ID)
			FROM #Temp_Query_Table AS t
		);

		SET @Curr_Query_No = 0;

		WHILE @Max_Query_No > @Curr_Query_No

		BEGIN
			SET @Curr_Query_No = @Curr_Query_No + 1;

			SET @column_query =
			(
				SELECT QUERY_stmt
				FROM #Temp_Query_Table AS t
				WHERE ID = @Curr_Query_No
			);

			if @debug  = 'true' SELECT @column_query;

			EXEC (@column_query);

		END;

		SELECT @RowCount_no = @@ROWCOUNT;


		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, '' + @rdb_table_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );


		SET @Proc_Step_no = 3;
		SET @Proc_Step_Name = ' Inserting data in to ' + @rdb_table_name;

		DECLARE @check_query nvarchar(max);

		SET @check_query =	'IF NOT EXISTS
							(
								SELECT d_' + @category + '_key
								FROM [dbo].' + @rdb_table_name +'
								WHERE d_' + @category + '_key = 1
							)
							BEGIN
								INSERT INTO [dbo].' + @rdb_table_name + '( [D_' + @category + '_KEY] )
								VALUES( 1 );
							END
							';
		if @debug = 'true' SELECT @check_query;

		EXEC sp_executesql @check_query;

		-- SELECT @RowCount_no = @@ROWCOUNT;

		DECLARE @insert_query nvarchar(max);

		SET @insert_query =
		'INSERT INTO  [dbo].' + @rdb_table_name + '( [D_' + @category + '_KEY] ,'+STUFF(
                (
                    SELECT ', ['+name+']'
					FROM syscolumns
					WHERE id = OBJECT_ID('S_' + @category) AND
						LOWER(NAME) NOT IN( LOWER('PAGE_CASE_UID'), 'last_chg_time' )
					FOR XML PATH('')
				), 1, 1, '')+' ) select [D_' + @category + '_KEY] , '+STUFF(
                (
                    SELECT ', ['+name+']'
                    FROM syscolumns
                    WHERE id = OBJECT_ID('S_' + @category ) AND
                        LOWER(NAME) NOT IN( LOWER('PAGE_CASE_UID'), 'last_chg_time' )
                    FOR XML PATH('')
                ), 1, 1, '')+'
	  			FROM  dbo.L_' + @category + '_INC LINV
	   			INNER JOIN dbo.S_' + @category + ' SINV ON SINV.PAGE_CASE_UID=LINV.PAGE_CASE_UID
				INNER JOIN
                (SELECT value FROM STRING_SPLIT('''+@phc_id_list+''', '','')) nu
                ON SINV.PAGE_CASE_UID = nu.value and LINV.PAGE_CASE_UID = nu.value'
							+ ' where linv.D_' + @category + '_KEY != 1'
		;

		if @debug = 'true'  SELECT @insert_query;

		EXEC sp_executesql @insert_query;


		SELECT @RowCount_no = @@ROWCOUNT;

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count], [msg_description1] )
		VALUES( @Batch_id, @category, @rdb_table_name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no, LEFT(@phc_id_list, 500));


		SET @Proc_Step_no = 999;
		SET @Proc_Step_Name = 'SP_COMPLETE';


		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count], [msg_description1])
		VALUES( @Batch_id, @category, @rdb_table_name, 'COMPLETE', @Proc_Step_no, @Proc_Step_name, @RowCount_no, LEFT(@phc_id_list, 500));

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH

		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION;
		END;

		         -- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count], [msg_description1] )
		VALUES( @Batch_id
		  , @category + '-' + cast(@phc_id_list as varchar(20))
		  , @rdb_table_name + '-' + cast(@phc_id_list as varchar(20))
		  , 'ERROR'
		  , @Proc_Step_no
		  , @Proc_Step_Name
		  , @FullErrorMessage
		  , 0
          , LEFT(@phc_id_list, 500) );

		RETURN -1;
	END CATCH;

END;