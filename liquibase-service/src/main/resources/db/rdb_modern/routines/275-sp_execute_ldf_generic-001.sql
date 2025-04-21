CREATE OR ALTER PROCEDURE [dbo].[sp_execute_ldf_generic] 
@phc_uids nvarchar(max),
@batch_id bigint,
@debug bit = 'false',
@target_table_name nvarchar(max)
 as 
  BEGIN 
	declare @RowCount_no bigint;
	declare @proc_step_no float = 0;
	declare @proc_step_name varchar(200) = '';
	declare @dataflow_name varchar(200) = 'sp_ldf_generic_datamart_postprocessing';
	declare @package_name varchar(200) = 'sp_execute_ldf_generic : '+lower(@target_table_name);

	DECLARE @cols  AS NVARCHAR(MAX)=''; 
	DECLARE @query AS NVARCHAR(MAX)=''; 

	DECLARE  @Alterdynamiccolumnlist varchar(max)='' 
	DECLARE  @dynamiccolumnUpdate varchar(max)='' 
	DECLARE  @dynamiccolumninsert varchar(max)='' 
	
	DECLARE  @dynamiccolumnList varchar(max)=''	--insert into LDF_GENERIC table from TMP_GENERIC table 
	DECLARE @count BIGINT; 
	

	DECLARE @global_tmp_generic_ta NVARCHAR(MAX);
	set @global_tmp_generic_ta = '##TMP_GENERIC_TA_' + CAST(@batch_id as varchar(50));

	DECLARE @global_tmp_generic_short_col NVARCHAR(MAX);
	set @global_tmp_generic_short_col = '##TMP_GENERIC_SHORT_COL_' + CAST(@batch_id as varchar(50));

	DECLARE @global_tmp_generic NVARCHAR(MAX);
	set @global_tmp_generic = '##TMP_GENERIC_' + CAST(@batch_id as varchar(50));

	--------------------------------------------------------------------------------------------------------

	SET @Proc_Step_no = 1;
    SET @Proc_Step_Name = 'SP_Start';

        --Serialize input parameters to JSON for clean logging
        DECLARE @params_json VARCHAR(200) = JSON_QUERY((
            SELECT
                @phc_uids AS phc_uids,
                @batch_id AS batch_id,
                @debug AS debug,
                @target_table_name AS target_table_name
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ));


       INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count], [Msg_Description1])
		VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
				@RowCount_no, @params_json); 
       
--------------------------------------------------------------------------------------------------------
 
 	BEGIN TRY 

		---CREATE TABLE BASE_GENERIC AS  
		SET @count = 
		( 
			SELECT COUNT(1) 
			FROM dbo.LDF_DIMENSIONAL_DATA LDF_DIMENSIONAL_DATA  with (nolock) 
				INNER JOIN dbo.LDF_DATAMART_TABLE_REF   with (nolock) ON LDF_DIMENSIONAL_DATA.PHC_CD = dbo.LDF_DATAMART_TABLE_REF.condition_cd 
															AND DATAMART_NAME = upper(@target_table_name)
				INNER JOIN (SELECT TRIM(value) AS value FROM STRING_SPLIT(@phc_uids, ',')) phc								
				on LDF_DIMENSIONAL_DATA.INVESTIGATION_UID = phc.value 									
		);	 

		IF (@count > 0) 
		BEGIN 
	
			--------- Create #LDF_GENERIC1 table 
	
				SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
				SET @PROC_STEP_NAME = ' GENERATING TMP_BASE_GENERIC';  
	
				--------- Create #TMP_BASE_GENERIC table 
	
				IF OBJECT_ID('#TMP_BASE_GENERIC', 'U') IS NOT NULL   
						DROP TABLE #TMP_BASE_GENERIC; 
			
				SELECT LDA.* 
								INTO #TMP_BASE_GENERIC 
								FROM dbo.LDF_DIMENSIONAL_DATA LDA 
									INNER JOIN dbo.LDF_DATAMART_TABLE_REF with (nolock)
										ON PHC_CD = LDF_DATAMART_TABLE_REF.CONDITION_CD 
										AND DATAMART_NAME = upper(@target_table_name)
									INNER JOIN (SELECT TRIM(value) AS value FROM STRING_SPLIT(@phc_uids, ',')) phc								
									on LDA.INVESTIGATION_UID = phc.value 												
					
				SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

					
				if
				@debug = 'true'
				select @Proc_Step_Name as step, *
				from #TMP_BASE_GENERIC;
		
				SELECT @RowCount_no = @@ROWCOUNT;
			
				INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
				VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
						@RowCount_no);  
		
--------------------------------------------------------------------------------------------------------				
					--- CREATE TABLE LINKED_GENERIC AS  
				
					SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
					SET @PROC_STEP_NAME = 'GENERATING TMP_LINKED_GENERIC';  
	
					IF OBJECT_ID('#TMP_LINKED_GENERIC', 'U') IS NOT NULL   
							DROP TABLE #TMP_LINKED_GENERIC; 
	
	
						SELECT GEN_LDF.*,  
							INV.INVESTIGATION_KEY,  
							INV.INV_LOCAL_ID 'INVESTIGATION_LOCAL_ID',  
							INV.CASE_OID 'PROGRAM_JURISDICTION_OID', 
							GEN.PATIENT_KEY, 
							PATIENT.PATIENT_LOCAL_ID 'PATIENT_LOCAL_ID', 
							CONDITION.CONDITION_SHORT_NM 'DISEASE_NAME' 
						INTO  #TMP_LINKED_GENERIC 
						FROM 
							#TMP_BASE_GENERIC GEN_LDF
							INNER JOIN  dbo.INVESTIGATION INV with (nolock) 
						ON   
							GEN_LDF.INVESTIGATION_UID=INV.CASE_UID  
						INNER JOIN dbo.GENERIC_CASE GEN  with (nolock) 
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
                    from #TMP_LINKED_GENERIC;	
						
					SELECT @ROWCOUNT_NO = @@ROWCOUNT; 
	
					INSERT INTO [dbo].[job_flow_log]
					(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
					VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
							@RowCount_no);  

	--------------------------------------------------------------------------------------------------------				
			
					----- CREATE TABLE ALL_GENERIC AS  
				
					SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
					SET @PROC_STEP_NAME = 'GENERATING TMP_ALL_GENERIC';  
	
				IF OBJECT_ID('#TMP_ALL_GENERIC', 'U') IS NOT NULL   
					DROP TABLE #TMP_ALL_GENERIC; 
	
					SELECT A.*,  
					B.DATAMART_COLUMN_NM 'DM', 
					CASE WHEN  DATALENGTH(REPLACE(A.CONDITION_CD, ' ', ''))>1 THEN A.CONDITION_CD
					WHEN DATALENGTH(REPLACE(A.CONDITION_CD, ' ', ''))<=1 THEN A.PHC_CD
					WHEN DATALENGTH(A.page_set)<2 THEN A.PAGE_SET
					WHEN DATALENGTH(B.DATAMART_COLUMN_NM)>2 THEN B.DATAMART_COLUMN_NM
					ELSE A.phc_cd END AS DISEASE_CD, 
					A.page_set AS DISEASE_NM
					INTO #TMP_ALL_GENERIC 
					FROM 	dbo.LDF_DATAMART_COLUMN_REF  B with (nolock) 
					INNER JOIN #TMP_LINKED_GENERIC A with (nolock) 
					ON A.LDF_UID= B.LDF_UID WHERE 
					( 
						B.LDF_PAGE_SET ='OTHER' 
						OR B.CONDITION_CD IN (SELECT CONDITION_CD FROM  
						dbo.LDF_DATAMART_TABLE_REF WHERE DATAMART_NAME = upper(@target_table_name)) 
					);

                    if
                    @debug = 'true'
                    select @Proc_Step_Name as step, *
                    from #TMP_ALL_GENERIC;	
						
					SELECT @ROWCOUNT_NO = @@ROWCOUNT; 
	
					INSERT INTO [dbo].[job_flow_log]
					(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
					VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
							@RowCount_no);  

	--------------------------------------------------------------------------------------------------------				
				
					SET @PROC_STEP_NO = @PROC_STEP_NO + 1; 
					SET @PROC_STEP_NAME = ' GENERATING TMP_ALL_GENERIC_SHORT_COL';  
	
				IF OBJECT_ID('#TMP_ALL_GENERIC_SHORT_COL', 'U') IS NOT NULL   
						DROP TABLE #TMP_ALL_GENERIC_SHORT_COL; 
					
						SELECT INVESTIGATION_KEY, 
									INVESTIGATION_LOCAL_ID, 
									PROGRAM_JURISDICTION_OID, 
									PATIENT_KEY, 
									PATIENT_LOCAL_ID, 
									DISEASE_NAME, 
									DISEASE_CD, 
									DATAMART_COLUMN_NM, 
									SUBSTRING(COL1, 1, 8000) as ANSWERCOL
						INTO #TMP_ALL_GENERIC_SHORT_COL 
						FROM #TMP_ALL_GENERIC
						WHERE data_type IN ('CV', 'ST');  
					
					
                    if
                    @debug = 'true'
                    select @Proc_Step_Name as step, *
                    from #TMP_ALL_GENERIC;	
                    
                    SELECT @ROWCOUNT_NO = @@ROWCOUNT; 
	
					INSERT INTO [dbo].[job_flow_log]
					(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
					VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
							@RowCount_no);   
	
	--------------------------------------------------------------------------------------------------------				
				
					SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
					SET @PROC_STEP_NAME = ' GENERATING TMP_ALL_GENERIC_TA';  
	
				IF OBJECT_ID('#TMP_ALL_GENERIC_TA', 'U') IS NOT NULL   
						DROP TABLE #TMP_ALL_GENERIC_TA; 
					
						SELECT INVESTIGATION_KEY, 
									INVESTIGATION_LOCAL_ID, 
									PROGRAM_JURISDICTION_OID, 
									PATIENT_KEY, 
									PATIENT_LOCAL_ID, 
									DISEASE_NAME, 
									DISEASE_CD, 
									DATAMART_COLUMN_NM, 
									SUBSTRING(COL1, 1, 8000) as ANSWERCOL  
						INTO #TMP_ALL_GENERIC_TA 
						FROM #TMP_ALL_GENERIC
						WHERE data_type IN ('LIST_ST'); 

                    if
                    @debug = 'true'
                    select @Proc_Step_Name as step, *
                    from #TMP_ALL_GENERIC_TA;	
					
					SELECT @ROWCOUNT_NO = @@ROWCOUNT;

					INSERT INTO [dbo].[job_flow_log]
					(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
					VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
							@RowCount_no);   
	
	--------------------------------------------------------------------------------------------------------		 
	
					SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
					SET @PROC_STEP_NAME = ' GENERATING TMP_GENERIC_TA';  
					set @count = (SELECT count(*) FROM #TMP_ALL_GENERIC_TA) 
					IF @count > 0 
					BEGIN 
						EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_generic_ta +''', ''U'')  IS NOT NULL
						BEGIN
							DROP TABLE ' + @global_tmp_generic_ta +';
						END;')
	
						--DECLARE @cols  AS NVARCHAR(MAX)=''; 
						--DECLARE @query AS NVARCHAR(MAX)=''; 
						SET @cols=''; 
						SET @query=''; 
	
						SELECT @cols = @cols + QUOTENAME(DATAMART_COLUMN_NM) + ',' FROM (select distinct DATAMART_COLUMN_NM from #TMP_ALL_GENERIC_TA ) as tmp 
						select @cols = substring(@cols, 0, len(@cols)) --trim "," at end 
	
						--PRINT CAST(@cols AS NVARCHAR(3000)) 
						set @query =  
						'SELECT * 
						INTO ' + @global_tmp_generic_ta +'
						fROM 
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
							
						FROM #TMP_ALL_GENERIC_TA ) 
						as A  
	
						PIVOT ( MAX([ANSWERCOL]) FOR DATAMART_COLUMN_NM   IN (' + @cols + ')) AS PivotTable'; 
						execute(@query) 

                    if
                    @debug = 'true'
                    select @Proc_Step_Name as step, *
                    from #TMP_ALL_GENERIC_TA;	
					
					SELECT @ROWCOUNT_NO = @@ROWCOUNT;
					
					END 

					INSERT INTO [dbo].[job_flow_log]
					(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
					VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
							@RowCount_no);  


	--------------------------------------------------------------------------------------------------------
					
                    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
					SET @PROC_STEP_NAME = ' GENERATING TMP_GENERIC_TA';  

                    -- If data does not exist create TMP_GENERIC_TA table same as TMP_ALL_GENERIC_TA, which will be used while merging table in step 9 
					set @count = (SELECT count(*) FROM #TMP_ALL_GENERIC_TA) 
					IF @count = 0 
					
                    BEGIN 

					EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_generic_ta +''', ''U'')  IS NOT NULL
						BEGIN
							DROP TABLE ' + @global_tmp_generic_ta +';
						END;')

					set @query =  
						'SELECT INVESTIGATION_KEY, 
								INVESTIGATION_LOCAL_ID, 
								PROGRAM_JURISDICTION_OID, 
								PATIENT_KEY, 
								PATIENT_LOCAL_ID, 
								DISEASE_NAME, 
								DISEASE_CD 
							INTO '+ @global_tmp_generic_ta + '
							FROM #TMP_ALL_GENERIC_TA with (nolock);';
					
					execute(@query) ;

                    SELECT @ROWCOUNT_NO = @@ROWCOUNT;

                    INSERT INTO [dbo].[job_flow_log]
					(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
					VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
							@RowCount_no);  
							
					END	 

	--------------------------------------------------------------------------------------------------------
						
					SET @PROC_STEP_NO = @PROC_STEP_NO + 1; 
					SET @PROC_STEP_NAME = ' GENERATING TMP_GENERIC_SHORT_COL';  
					set @count = (SELECT count(*) FROM #TMP_ALL_GENERIC_SHORT_COL) 
					IF @count > 0 
					BEGIN 
					
					EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_generic_short_col +''', ''U'')  IS NOT NULL
						BEGIN
							DROP TABLE ' + @global_tmp_generic_short_col +';
						END;')

	
						--DECLARE @cols  AS NVARCHAR(MAX)=''; 
						--DECLARE @query AS NVARCHAR(MAX)=''; 
						SET @cols=''; 
						SET @query=''; 
							
							SELECT @cols = @cols + QUOTENAME(DATAMART_COLUMN_NM) + ',' FROM (select distinct DATAMART_COLUMN_NM from #TMP_ALL_GENERIC_SHORT_COL ) as tmp 
							select @cols = substring(@cols, 0, len(@cols)) --trim "," at end 
							
							set @query =  
							'SELECT * 
							INTO ' + @global_tmp_generic_short_col +'
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
								
							FROM #TMP_ALL_GENERIC_SHORT_COL ) 
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
					SET @PROC_STEP_NAME = ' GENERATING TMP_GENERIC_SHORT_COL';  

					-- If data does not exist create TMP_GENERIC_SHORT_COL table same as TMP_ALL_GENERIC_SHORT_COL, which will be used while merging table in step 9 
					set @count = (SELECT count(*) FROM #TMP_ALL_GENERIC_SHORT_COL) 
					IF @count = 0 
					BEGIN 

					EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_generic_short_col +''', ''U'')  IS NOT NULL
						BEGIN
							DROP TABLE ' + @global_tmp_generic_short_col +';
						END;')

						set @query =  
							'SELECT INVESTIGATION_KEY, 
							INVESTIGATION_LOCAL_ID, 
							PROGRAM_JURISDICTION_OID, 
							PATIENT_KEY, 
							PATIENT_LOCAL_ID, 
							DISEASE_NAME, 
							DISEASE_CD 
							INTO ' +  @global_tmp_generic_short_col + '
							FROM #TMP_ALL_GENERIC_SHORT_COL; '; 
							execute(@query) 

					END 

                    SELECT @ROWCOUNT_NO = @@ROWCOUNT; 
	
					INSERT INTO [dbo].[job_flow_log]
					(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
					VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
							@RowCount_no);   
------------------------------------------------------------------------------------------------                            
					
					--- MERGE  GENERIC_SHORT_COL GENERIC_TA; 
					
					SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
					SET @PROC_STEP_NAME = ' GENERATING TMP_GENERIC';  
	
					EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_generic +''', ''U'')  IS NOT NULL
						BEGIN
							DROP TABLE ' + @global_tmp_generic +';
						END;')

	
						EXECUTE  [dbo].[sp_MERGE_TABLES]  
							@INPUT_TABLE1= @global_tmp_generic_short_col
							,@INPUT_TABLE2= @global_tmp_generic_ta
							,@OUTPUT_TABLE= @global_tmp_generic
							,@JOIN_ON_COLUMN='INVESTIGATION_KEY'
							,@batch_id = @batch_id
							,@target_table_name = @target_table_name;

						set @query =  
							'DELETE FROM '+ @global_tmp_generic +' WHERE INVESTIGATION_KEY IS NULL;'; 
							execute(@query) 
					
					SELECT @ROWCOUNT_NO = @@ROWCOUNT; 
	
					INSERT INTO [dbo].[job_flow_log]
					(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
					VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
							@RowCount_no); 
	
------------------------------------------------------------------------------------------------				
			
				
					SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
					SET @PROC_STEP_NAME = 'GENERATING '+@target_table_name;  
	

						--- If the TMP_GENERIC has additional columns compare to LDF_GENERIC, add these additional columns in LDF_GENERIC table. 
						BEGIN TRANSACTION; 
							SET @Alterdynamiccolumnlist=''; 
							SET @dynamiccolumnUpdate=''; 
							
							SELECT   @Alterdynamiccolumnlist  = @Alterdynamiccolumnlist+ 'ALTER TABLE dbo.'+@target_table_name+' ADD [' + name   +  '] varchar(4000) ', 
								@dynamiccolumnUpdate= @dynamiccolumnUpdate + @target_table_name+'.[' +  name  + ']='  + ''+  @global_tmp_generic +'.['  +name  + '] ,' 
							FROM  tempdb.Sys.Columns WHERE Object_ID = Object_ID('tempdb..'+ @global_tmp_generic +'') 
							AND name NOT IN  ( SELECT name FROM  Sys.Columns WHERE Object_ID = Object_ID(@target_table_name)) 
							
							
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
					SET @PROC_STEP_NAME = 'Update '+@target_table_name;  
	
	
                    BEGIN TRANSACTION; 

                    IF @Alterdynamiccolumnlist IS NOT NULL AND @Alterdynamiccolumnlist!='' 
						
                        BEGIN 
                        
                        SET  @dynamiccolumnUpdate=substring(@dynamiccolumnUpdate,1,len(@dynamiccolumnUpdate)-1) 

                        EXEC ('update  dbo.'+ @target_table_name +'  SET ' +   @dynamiccolumnUpdate + ' FROM '+@global_tmp_generic +'      
                        inner join  dbo.'+@target_table_name+'  on  ' + @global_tmp_generic +'.INVESTIGATION_LOCAL_ID =  dbo.'+@target_table_name+'.INVESTIGATION_LOCAL_ID') 

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
					SET @PROC_STEP_NAME = 'Delete Existing to '+@target_table_name;  
						--In case of updates, delete the existing ones and insert updated ones in LDF_GENERIC 
						EXEC ('DELETE FROM dbo.'+@target_table_name+' WHERE INVESTIGATION_KEY IN (SELECT INVESTIGATION_KEY FROM ' + @global_tmp_generic +' );');

                        INSERT INTO [dbo].[job_flow_log]
					    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
					    VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
							@RowCount_no);  

                    COMMIT TRANSACTION; 

------------------------------------------------------------------------------------------------                            
					
					SET @PROC_STEP_NO = @PROC_STEP_NO + 1; 
					SET @PROC_STEP_NAME = 'Insert to '+@target_table_name;  
                        
                        BEGIN TRANSACTION; 
					
						--- During update if TMP_GENERIC has 4 columns updated only and the LDF_GENERIC has 7 columns then get column name dynamically from TMP_GENERIC and populate them. 
					
							SET @dynamiccolumnList ='' 
							SELECT @dynamiccolumnList= @dynamiccolumnList +'['+ name +'],' FROM  tempdb.Sys.Columns WHERE Object_ID = Object_ID('tempdb..'+ @global_tmp_generic) 
							SET  @dynamiccolumnList=substring(@dynamiccolumnList,1,len(@dynamiccolumnList)-1) 
	
							--PRINT '@@@@@dynamiccolumnList -----------	'+CAST(@dynamiccolumnList AS NVARCHAR(max)) 
	
							EXEC ('INSERT INTO dbo.'+@target_table_name+' ('+@dynamiccolumnList+') 
							SELECT '+@dynamiccolumnList +' 
							FROM '+ @global_tmp_generic+';'); 
	
							SELECT @ROWCOUNT_NO = @@ROWCOUNT; 
                        
                        INSERT INTO [dbo].[job_flow_log]
		    			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
					    VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
						@RowCount_no);  
							
						COMMIT TRANSACTION; 
								
------------------------------------------------------------------------------------------------
					
				SET @PROC_STEP_NO = @PROC_STEP_NO + 1; 
				SET @PROC_STEP_NAME = 'DELETE global temp tables'; 

				EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_generic_short_col +''', ''U'')  IS NOT NULL
					BEGIN
						DROP TABLE ' + @global_tmp_generic_short_col +';
					END;')


				EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_generic_ta +''', ''U'')  IS NOT NULL
					BEGIN
						DROP TABLE ' + @global_tmp_generic_ta +';
					END;')


				EXEC ('IF OBJECT_ID(''tempdb..' + @global_tmp_generic +''', ''U'')  IS NOT NULL
					BEGIN
						DROP TABLE ' + @global_tmp_generic +';
					END;') 

				INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
				VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
				@RowCount_no);  

------------------------------------------------------------------------------------------------
			
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
