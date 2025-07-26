IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_ldf_bmird_datamart_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_ldf_bmird_datamart_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_ldf_bmird_datamart_postprocessing] 
@phc_uids nvarchar(max),
@debug bit = 'false'
 as 
  BEGIN 
	declare @RowCount_no bigint;
	declare @proc_step_no float = 0;
	declare @proc_step_name varchar(200) = '';
	declare @batch_id bigint;
	declare @dataflow_name varchar(200) = 'sp_ldf_bmird_datamart_postprocessing POST-Processing';
	declare @package_name varchar(200) = 'sp_ldf_bmird_datamart_postprocessing';
	set @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);

	DECLARE @cols  AS NVARCHAR(MAX)=''; 
	DECLARE @query AS NVARCHAR(MAX)=''; 

	DECLARE  @Alterdynamiccolumnlist varchar(max)='' 
	DECLARE  @dynamiccolumnUpdate varchar(max)='' 
	DECLARE  @dynamiccolumninsert varchar(max)='' 
	
	DECLARE  @dynamiccolumnList varchar(max)=''	--insert into LDF_BMIRD table from TMP_BMIRD table 
	DECLARE @count BIGINT; 
	

	DECLARE @global_tmp_bmird_ta NVARCHAR(MAX);
	set @global_tmp_bmird_ta = '##TMP_BMIRD_TA_' + CAST(@batch_id as varchar(50));

	DECLARE @global_tmp_bmird_short_col NVARCHAR(MAX);
	set @global_tmp_bmird_short_col = '##TMP_BMIRD_SHORT_COL_' + CAST(@batch_id as varchar(50));

	DECLARE @global_tmp_bmird NVARCHAR(MAX);
	set @global_tmp_bmird = '##TMP_BMIRD_' + CAST(@batch_id as varchar(50));

 	BEGIN TRY 

		SET @Proc_Step_no = @PROC_STEP_NO + 1; 
		SET @Proc_Step_Name = 'SP_START';

		INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count], [Msg_Description1])
		VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
				@RowCount_no, LEFT (@phc_uids, 199)); 
--------------------------------------------------------------------------------------------------------

		/* THIS IS EXISTING CODE IN RDB. WHEN THERE IS NO RECORD IN LDF_DIMENSIONAL, THE SP WILL NOT EXECUTE. 
		HENCE COMMENTING THIS LINE TO ENSURE ALL THE RECORDS ARE PROCESSED
		
		SET @count = 
		( 
			SELECT COUNT(1) 
			FROM dbo.LDF_DIMENSIONAL_DATA LDF_DIMENSIONAL_DATA  with (nolock) 
				INNER JOIN dbo.LDF_DATAMART_TABLE_REF   with (nolock) ON LDF_DIMENSIONAL_DATA.PHC_CD = dbo.LDF_DATAMART_TABLE_REF.condition_cd 
															AND DATAMART_NAME = upper('LDF_BMIRD')
				INNER JOIN 	(SELECT distinct TRIM(value) AS value FROM STRING_SPLIT(@phc_uids, ',')) phc									
				on LDF_DIMENSIONAL_DATA.INVESTIGATION_UID = phc.value				
		);	 

		IF (@count > 0) 
		*/
		
		BEGIN 
			
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'LDF_UID_LIST';  
			
			--------- Create #LDF_UID_LIST table 
			IF OBJECT_ID('#LDF_UID_LIST', 'U') IS NOT NULL   
				DROP TABLE #LDF_UID_LIST; 
		
			SELECT distinct TRIM(value) AS value into #LDF_UID_LIST FROM STRING_SPLIT(@phc_uids, ',')		

			if
			@debug = 'true'
			select @Proc_Step_Name as step, *
			from #LDF_UID_LIST;

			SELECT @RowCount_no = @@ROWCOUNT;
		
			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no);  

	--------------------------------------------------------------------------------------------------------
			--------- Create #LDF_BMIRD table 
				
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = ' GENERATING TMP_BASE_BMIRD';  

			--------- Create #TMP_BASE_BMIRD table 

			IF OBJECT_ID('#TMP_BASE_BMIRD', 'U') IS NOT NULL   
					DROP TABLE #TMP_BASE_BMIRD; 
		
			SELECT LDA.* 
				INTO #TMP_BASE_BMIRD 
				FROM dbo.LDF_DIMENSIONAL_DATA LDA 
					INNER JOIN dbo.LDF_DATAMART_TABLE_REF ON PHC_CD = LDF_DATAMART_TABLE_REF.CONDITION_CD 
																AND DATAMART_NAME = upper('LDF_BMIRD')
					INNER JOIN 	#LDF_UID_LIST phc									
					on LDA.INVESTIGATION_UID = phc.value;				
				
			SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

				
			if
			@debug = 'true'
			select @Proc_Step_Name as step, *
			from #TMP_BASE_BMIRD;
	
			SELECT @RowCount_no = @@ROWCOUNT;
		
			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no);  
	
--------------------------------------------------------------------------------------------------------				
				--- CREATE TABLE LINKED_BMIRD AS  
			
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'GENERATING TMP_LINKED_BMIRD';  

			IF OBJECT_ID('#TMP_LINKED_BMIRD', 'U') IS NOT NULL   
					DROP TABLE #TMP_LINKED_BMIRD; 

			SELECT GEN_LDF.*,  
				INV.INVESTIGATION_KEY,  
				INV.INV_LOCAL_ID 'INVESTIGATION_LOCAL_ID',  
				INV.CASE_OID 'PROGRAM_JURISDICTION_OID', 
				GEN.PATIENT_KEY, 
				PATIENT.PATIENT_LOCAL_ID 'PATIENT_LOCAL_ID', 
				CONDITION.CONDITION_SHORT_NM 'DISEASE_NAME' 
			INTO  #TMP_LINKED_BMIRD 
			FROM 
				#TMP_BASE_BMIRD GEN_LDF  with (nolock) 
				INNER JOIN  dbo.INVESTIGATION INV with (nolock) 
			ON   
				GEN_LDF.INVESTIGATION_UID=INV.CASE_UID  
			INNER JOIN dbo.BMIRD_CASE GEN  with (nolock) 
			ON  
				GEN.INVESTIGATION_KEY=INV.INVESTIGATION_KEY 
			INNER JOIN dbo.CONDITION  with (nolock) 
			ON  
				CONDITION.CONDITION_KEY= GEN.CONDITION_KEY 
			INNER JOIN dbo.D_PATIENT PATIENT  with (nolock) 
			ON  
				PATIENT.PATIENT_KEY=GEN.PATIENT_KEY;

			if
			@debug = 'true'
			select @Proc_Step_Name as step, *
			from #TMP_LINKED_BMIRD;	
				
			SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no);  

--------------------------------------------------------------------------------------------------------				
	
			----- CREATE TABLE ALL_BMIRD AS  
		
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'GENERATING TMP_ALL_BMIRD';  

			IF OBJECT_ID('#TMP_ALL_BMIRD', 'U') IS NOT NULL   
				DROP TABLE #TMP_ALL_BMIRD; 

			SELECT A.*,  
			B.DATAMART_COLUMN_NM 'DM', 
			CASE WHEN  DATALENGTH(REPLACE(A.CONDITION_CD, ' ', ''))>1 THEN A.CONDITION_CD
			ELSE A.phc_cd END AS DISEASE_CD, 
			A.page_set AS DISEASE_NM
			INTO #TMP_ALL_BMIRD 
			FROM 	dbo.LDF_DATAMART_COLUMN_REF  B with (nolock) 
			INNER JOIN #TMP_LINKED_BMIRD A with (nolock) 
			ON A.LDF_UID= B.LDF_UID WHERE 
			( 
				B.LDF_PAGE_SET ='BMIRD' 
				OR B.CONDITION_CD IN (SELECT CONDITION_CD FROM  
				dbo.LDF_DATAMART_TABLE_REF WHERE DATAMART_NAME = 'LDF_BMIRD')
			);

			if
			@debug = 'true'
			select @Proc_Step_Name as step, *
			from #TMP_ALL_BMIRD;	
				
			SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no);  

--------------------------------------------------------------------------------------------------------				
			
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1; 
			SET @PROC_STEP_NAME = ' GENERATING TMP_ALL_BMIRD_SHORT_COL';  

			IF OBJECT_ID('#TMP_ALL_BMIRD_SHORT_COL', 'U') IS NOT NULL   
					DROP TABLE #TMP_ALL_BMIRD_SHORT_COL; 
				
			SELECT INVESTIGATION_KEY, 
						INVESTIGATION_LOCAL_ID, 
						PROGRAM_JURISDICTION_OID, 
						PATIENT_KEY, 
						PATIENT_LOCAL_ID, 
						DISEASE_NAME, 
						DISEASE_CD, 
						DATAMART_COLUMN_NM, 
						SUBSTRING(COL1, 1, 8000) as ANSWERCOL
			INTO #TMP_ALL_BMIRD_SHORT_COL 
			FROM #TMP_ALL_BMIRD
			WHERE data_type IN ('CV', 'ST');  
				
				
			if
			@debug = 'true'
			select @Proc_Step_Name as step, *
			from #TMP_ALL_BMIRD;	
			
			SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no);   

--------------------------------------------------------------------------------------------------------				
			
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = ' GENERATING TMP_ALL_BMIRD_TA';  

			IF OBJECT_ID('#TMP_ALL_BMIRD_TA', 'U') IS NOT NULL   
					DROP TABLE #TMP_ALL_BMIRD_TA; 
			
			SELECT INVESTIGATION_KEY, 
				INVESTIGATION_LOCAL_ID, 
				PROGRAM_JURISDICTION_OID, 
				PATIENT_KEY, 
				PATIENT_LOCAL_ID, 
				DISEASE_NAME, 
				DISEASE_CD, 
				DATAMART_COLUMN_NM, 
				SUBSTRING(COL1, 1, 8000) as ANSWERCOL  
			INTO #TMP_ALL_BMIRD_TA 
			FROM #TMP_ALL_BMIRD
			WHERE data_type IN ('LIST_ST'); 

			if
			@debug = 'true'
			select @Proc_Step_Name as step, *
			from #TMP_ALL_BMIRD_TA;	
			
			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no);   
	
	--------------------------------------------------------------------------------------------------------		 
	
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = ' GENERATING TMP_BMIRD_TA';  
			set @count = (SELECT count(*) FROM #TMP_ALL_BMIRD_TA) 
			IF @count > 0 
			BEGIN 
				EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_bmird_ta +''', ''U'')  IS NOT NULL
				BEGIN
					DROP TABLE ' + @global_tmp_bmird_ta +';
				END;')

				--DECLARE @cols  AS NVARCHAR(MAX)=''; 
				--DECLARE @query AS NVARCHAR(MAX)=''; 
				SET @cols=''; 
				SET @query=''; 

				SELECT @cols = @cols + QUOTENAME(DATAMART_COLUMN_NM) + ',' FROM (select distinct DATAMART_COLUMN_NM from #TMP_ALL_BMIRD_TA ) as tmp 
				select @cols = substring(@cols, 0, len(@cols)) --trim "," at end 

				--PRINT CAST(@cols AS NVARCHAR(3000)) 
				set @query =  
				'SELECT * 
				INTO ' + @global_tmp_bmird_ta +'
				fROM 
				(  
				SELECT  INVESTIGATION_KEY, 
						INVESTIGATION_LOCAL_ID, 
						PROGRAM_JURISDICTION_OID, 
						PATIENT_KEY, 
						PATIENT_LOCAL_ID, 
						DISEASE_NAME, 
						DISEASE_CD, 
						DATAMART_COLUMN_NM, 
						ANSWERCOL 
					
				FROM #TMP_ALL_BMIRD_TA ) 
				as A  

				PIVOT ( MAX([ANSWERCOL]) FOR DATAMART_COLUMN_NM   IN (' + @cols + ')) AS PivotTable'; 
				execute(@query) 

			if
			@debug = 'true'
			select @Proc_Step_Name as step, *
			from #TMP_ALL_BMIRD_TA;	
			
			SELECT @ROWCOUNT_NO = @@ROWCOUNT;
			
			END 

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no);  

	--------------------------------------------------------------------------------------------------------
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = ' GENERATING TMP_BMIRD_TA';  

			-- If data does not exist create TMP_BMIRD_TA table same as TMP_ALL_BMIRD_TA, which will be used while merging table in step 9 
			set @count = (SELECT count(*) FROM #TMP_ALL_BMIRD_TA) 
			IF @count = 0 
			
			BEGIN 

			EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_bmird_ta +''', ''U'')  IS NOT NULL
				BEGIN
					DROP TABLE ' + @global_tmp_bmird_ta +';
				END;')

			set @query =  
				'SELECT INVESTIGATION_KEY, 
						INVESTIGATION_LOCAL_ID, 
						PROGRAM_JURISDICTION_OID, 
						PATIENT_KEY, 
						PATIENT_LOCAL_ID, 
						DISEASE_NAME, 
						DISEASE_CD 
					INTO '+ @global_tmp_bmird_ta + '
					FROM #TMP_ALL_BMIRD_TA with (nolock);';
			
			execute(@query) ;

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no);  
					
			END	 

	--------------------------------------------------------------------------------------------------------
						
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1; 
			SET @PROC_STEP_NAME = ' GENERATING TMP_BMIRD_SHORT_COL';  
			set @count = (SELECT count(*) FROM #TMP_ALL_BMIRD_SHORT_COL) 
			IF @count > 0 
			BEGIN 
			
			EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_bmird_short_col +''', ''U'')  IS NOT NULL
				BEGIN
					DROP TABLE ' + @global_tmp_bmird_short_col +';
				END;')

				--DECLARE @cols  AS NVARCHAR(MAX)=''; 
				--DECLARE @query AS NVARCHAR(MAX)=''; 
				SET @cols=''; 
				SET @query=''; 
					
					SELECT @cols = @cols + QUOTENAME(DATAMART_COLUMN_NM) + ',' FROM (select distinct DATAMART_COLUMN_NM from #TMP_ALL_BMIRD_SHORT_COL ) as tmp 
					select @cols = substring(@cols, 0, len(@cols)) --trim "," at end 
					
					set @query =  
					'SELECT * 
					INTO ' + @global_tmp_bmird_short_col +'
					FROM 
					(  
					SELECT     INVESTIGATION_KEY, 
							INVESTIGATION_LOCAL_ID, 
							PROGRAM_JURISDICTION_OID, 
							PATIENT_KEY, 
							PATIENT_LOCAL_ID, 
							DISEASE_NAME, 
							DISEASE_CD, 
							DATAMART_COLUMN_NM, 
							ANSWERCOL 
						
					FROM #TMP_ALL_BMIRD_SHORT_COL ) 
					as A  

					PIVOT ( MAX([ANSWERCOL]) FOR DATAMART_COLUMN_NM   IN (' + @cols + ')) AS PivotTable'; 
					execute(@query) 
				
			END 
			
			SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no);   


	------------------------------------------------------------------------------------------------

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1; 
			SET @PROC_STEP_NAME = ' GENERATING TMP_BMIRD_SHORT_COL';  

			-- If data does not exist create TMP_BMIRD_SHORT_COL table same as TMP_ALL_BMIRD_SHORT_COL, which will be used while merging table in step 9 
			set @count = (SELECT count(*) FROM #TMP_ALL_BMIRD_SHORT_COL) 
			IF @count = 0 
			BEGIN 

			EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_bmird_short_col +''', ''U'')  IS NOT NULL
				BEGIN
					DROP TABLE ' + @global_tmp_bmird_short_col +';
				END;')

				set @query =  
					'SELECT INVESTIGATION_KEY, 
					INVESTIGATION_LOCAL_ID, 
					PROGRAM_JURISDICTION_OID, 
					PATIENT_KEY, 
					PATIENT_LOCAL_ID, 
					DISEASE_NAME, 
					DISEASE_CD 
					INTO ' +  @global_tmp_bmird_short_col + '
					FROM #TMP_ALL_BMIRD_SHORT_COL; '; 
					execute(@query) 

			END 

			SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no);   
------------------------------------------------------------------------------------------------                            
			--- MERGE  BMIRD_SHORT_COL BMIRD_TA; 
			
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = ' GENERATING TMP_BMIRD';  

			EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_bmird +''', ''U'')  IS NOT NULL
				BEGIN
					DROP TABLE ' + @global_tmp_bmird +';
				END;')


				EXECUTE  [dbo].[sp_MERGE_TABLES]  
					@INPUT_TABLE1= @global_tmp_bmird_short_col
					,@INPUT_TABLE2= @global_tmp_bmird_ta
					,@OUTPUT_TABLE= @global_tmp_bmird
					,@JOIN_ON_COLUMN='INVESTIGATION_KEY'
					,@batch_id = @batch_id
					,@target_table_name = 'LDF_BMIRD';

				set @query =  
					'DELETE FROM '+ @global_tmp_bmird +' WHERE INVESTIGATION_KEY IS NULL;'; 
					execute(@query) 
			
			SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no); 
	
------------------------------------------------------------------------------------------------				
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'GENERATING LDF_BMIRD';  

				--- If the TMP_BMIRD has additional columns compare to LDF_BMIRD, add these additional columns in LDF_BMIRD table. 
				BEGIN TRANSACTION; 
					SET @Alterdynamiccolumnlist=''; 
					SET @dynamiccolumnUpdate=''; 
					
					SELECT   @Alterdynamiccolumnlist  = @Alterdynamiccolumnlist+ 'ALTER TABLE dbo.LDF_BMIRD ADD [' + name   +  '] varchar(4000) ', 
						@dynamiccolumnUpdate= @dynamiccolumnUpdate + 'LDF_BMIRD.[' +  name  + ']='  + ''+  @global_tmp_bmird +'.['  +name  + '] ,' 
					FROM  tempdb.Sys.Columns WHERE Object_ID = Object_ID('tempdb..'+ @global_tmp_bmird +'') 
					AND name NOT IN  ( SELECT name FROM  Sys.Columns WHERE Object_ID = Object_ID('LDF_BMIRD')) 
					
					
					--PRINT '@@Alterdynamiccolumnlist -----------	'+CAST(@Alterdynamiccolumnlist AS NVARCHAR(max)) 
					--PRINT '@@@@dynamiccolumnUpdate -----------	'+CAST(@dynamiccolumnUpdate AS NVARCHAR(max)) 

					IF @Alterdynamiccolumnlist IS NOT NULL AND @Alterdynamiccolumnlist!='' 
					BEGIN 

						EXEC(  @Alterdynamiccolumnlist) 

					END

			SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no);  

			COMMIT TRANSACTION; 
------------------------------------------------------------------------------------------------
                    
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1; 
			SET @PROC_STEP_NAME = 'Update LDF_BMIRD';  


			BEGIN TRANSACTION; 

			IF @Alterdynamiccolumnlist IS NOT NULL AND @Alterdynamiccolumnlist!='' 
				
				BEGIN 
				
				SET  @dynamiccolumnUpdate=substring(@dynamiccolumnUpdate,1,len(@dynamiccolumnUpdate)-1) 

				EXEC ('update  dbo.LDF_BMIRD  SET ' +   @dynamiccolumnUpdate + ' FROM '+@global_tmp_bmird +'      
				inner join  dbo.LDF_BMIRD  on  ' + @global_tmp_bmird +'.INVESTIGATION_LOCAL_ID =  dbo.LDF_BMIRD.INVESTIGATION_LOCAL_ID') 

				END 

			SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

			INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
				VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no);  
			
			COMMIT TRANSACTION; 
------------------------------------------------------------------------------------------------

			BEGIN TRANSACTION; 

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'Delete Existing to LDF_BMIRD';  
				--In case of updates, delete the existing ones and insert updated ones in LDF_BMIRD 
				EXEC ('DELETE FROM dbo.LDF_BMIRD WHERE INVESTIGATION_KEY IN (SELECT INVESTIGATION_KEY FROM ' + @global_tmp_bmird +' );');

				INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
				VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
					@RowCount_no);  

			COMMIT TRANSACTION; 

	------------------------------------------------------------------------------------------------                            
				
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1; 
			SET @PROC_STEP_NAME = 'Insert to LDF_BMIRD';  
				
				BEGIN TRANSACTION; 
			
				--- During update if TMP_BMIRD has 4 columns updated only and the LDF_BMIRD has 7 columns then get column name dynamically from TMP_BMIRD and populate them. 
			
					SET @dynamiccolumnList ='' 
					SELECT @dynamiccolumnList= @dynamiccolumnList +'['+ name +'],' FROM  tempdb.Sys.Columns WHERE Object_ID = Object_ID('tempdb..'+ @global_tmp_bmird) 
					SET  @dynamiccolumnList=substring(@dynamiccolumnList,1,len(@dynamiccolumnList)-1) 

					--PRINT '@@@@@dynamiccolumnList -----------	'+CAST(@dynamiccolumnList AS NVARCHAR(max)) 

					EXEC ('INSERT INTO dbo.LDF_BMIRD ('+@dynamiccolumnList+') 
					SELECT '+@dynamiccolumnList +' 
					FROM '+ @global_tmp_bmird+';'); 

					SELECT @ROWCOUNT_NO = @@ROWCOUNT; 
				
				INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
				VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
				@RowCount_no);  
					
				COMMIT TRANSACTION; 
							
	------------------------------------------------------------------------------------------------
			
			--UPDATE LDF DM TO NULLS WHEN THERE IS NO RECORD IN LDF_DIMENSTIONAL
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1; 
			SET @PROC_STEP_NAME = 'UPDATE LDF_BMIRD when there is no record in the LDF_DIMENSIONAL_DATA';  
				
			BEGIN TRANSACTION; 

			SET @dynamiccolumnUpdate=''; 
				
			SELECT   @dynamiccolumnUpdate= @dynamiccolumnUpdate + 'TBL.[' +  COLUMN_NAME  + '] = NULL ,' 
			FROM  INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'LDF_BMIRD'
				AND COLUMN_NAME NOT IN  ('INVESTIGATION_KEY', 'INVESTIGATION_LOCAL_ID', 'PROGRAM_JURISDICTION_OID', 'PATIENT_KEY', 'PATIENT_LOCAL_ID', 'DISEASE_NAME', 'DISEASE_CD')
				
			SET  @dynamiccolumnUpdate=substring(@dynamiccolumnUpdate,1,len(@dynamiccolumnUpdate)-1) 


				EXEC ('update TBL SET ' +   @dynamiccolumnUpdate + ' FROM  
				dbo.LDF_BMIRD TBL inner join  
				dbo.INVESTIGATION INV with (nolock) 
				ON TBL.INVESTIGATION_KEY = INV.INVESTIGATION_KEY
				INNER JOIN #LDF_UID_LIST LDF_UID_LIST ON 
				LDF_UID_LIST.VALUE = INV.CASE_UID
				LEFT JOIN (SELECT DISTINCT INVESTIGATION_UID FROM DBO.LDF_DIMENSIONAL_DATA WITH (NOLOCK)) LDF_DIMENSIONAL_DATA 
				ON LDF_DIMENSIONAL_DATA.INVESTIGATION_UID = INV.CASE_UID
				WHERE LDF_DIMENSIONAL_DATA.INVESTIGATION_UID IS NULL;
			');


				SELECT @ROWCOUNT_NO = @@ROWCOUNT; 
				
				INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
				VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
				@RowCount_no);  
					
				COMMIT TRANSACTION; 

	------------------------------------------------------------------------------------------------
				
			SET @PROC_STEP_NO = @PROC_STEP_NO + 1; 
			SET @PROC_STEP_NAME = 'DELETE global temp tables'; 

			EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_bmird_short_col +''', ''U'')  IS NOT NULL
				BEGIN
					DROP TABLE ' + @global_tmp_bmird_short_col +';
				END;')


			EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_bmird_ta +''', ''U'')  IS NOT NULL
				BEGIN
					DROP TABLE ' + @global_tmp_bmird_ta +';
				END;')


			EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_bmird +''', ''U'')  IS NOT NULL
				BEGIN
					DROP TABLE ' + @global_tmp_bmird +';
				END;') 

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
			@RowCount_no);  

------------------------------------------------------------------------------------------------
		END	
		
		SET @Proc_Step_no = 999; 
		SET @Proc_Step_Name = 'SP_COMPLETE';

		INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
				@RowCount_no); 

		SELECT
            CAST(NULL AS BIGINT) AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            CAST(NULL AS VARCHAR(30)) AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            CAST(NULL AS VARCHAR(200)) AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=0;
	
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

END;

------------------------------------------------------------------------------------------------------
