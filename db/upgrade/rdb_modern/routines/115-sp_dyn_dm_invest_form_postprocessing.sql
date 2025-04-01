CREATE OR ALTER PROCEDURE [dbo].sp_dyn_dm_invest_form_postprocessing
-- call this after populating <>

            @batch_id BIGINT,
			@DATAMART_NAME VARCHAR(100),
			@phc_id_list nvarchar(max),
			@debug bit = 'false'
	AS
BEGIN
	 BEGIN TRY

	    --	DECLARE  @batch_id BIGINT = 999;  DECLARE  @DATAMART_NAME VARCHAR(100) = 'CONG_SYPHILIS';
		DECLARE @RowCount_no INT ;
		DECLARE @Proc_Step_no FLOAT = 0 ;
		DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
		DECLARE @batch_start_time datetime = null ;
		DECLARE @batch_end_time datetime = null ;
		DECLARE @nbs_page_form_cd varchar(200)='';
	    DECLARE @Dataflow_Name varchar(200)='DYNAMIC_DATAMART POST-PROCESSING';
	    DECLARE @Package_Name varchar(200)='DynDM_INVEST_FORM_PROC '+@DATAMART_NAME;

	    DECLARE @tmp_DynDm_PATIENT_DATA varchar(200) = 'dbo.tmp_DynDm_Patient_Data_'+@DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));
	    DECLARE @tmp_DynDm_INVESTIGATION_DATA varchar(200) = 'dbo.tmp_DynDm_Investigation_Data_'+@DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));

        DECLARE @temp_sql nvarchar(max);

	SET @Proc_Step_no = 1;
	SET @Proc_Step_Name = 'SP_Start';




    INSERT INTO dbo.job_flow_log (
	        batch_id
		   ,[Dataflow_Name]
		   ,[package_Name]
		    ,[Status_Type]
           ,[step_number]
           ,[step_name]
           ,[row_count]
           )
		   VALUES
           (
		   @batch_id
           ,@Dataflow_Name
           ,@Package_Name
		   ,'START'
		   ,@Proc_Step_no
		   ,@Proc_Step_Name
           ,0
		   );



	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_SUMM_DATAMART';





  --DROP TABLE #tmp_DynDm_SUMM_DATAMART;


/*Creates a summ_datamart with patient key, investigation key and disease group code*/
  --CREATE TABLE dbo.SUMM_DATAMART AS

  /*IF OBJECT_ID('#tmp_DynDm_SUMM_DATAMART', 'U') IS NOT NULL
 				drop table #tmp_DynDm_SUMM_DATAMART;
	*/
SET @nbs_page_form_cd = (SELECT FORM_CD FROM dbo.v_nrt_nbs_page WHERE DATAMART_NM=@DATAMART_NAME)

  SELECT isd.PATIENT_KEY AS PATIENT_KEY, isd.INVESTIGATION_KEY, c.DISEASE_GRP_CD
    into #tmp_DynDm_SUMM_DATAMART
     FROM dbo.INV_SUMM_DATAMART isd with ( nolock)
       INNER JOIN dbo.v_condition_dim c with ( nolock)  ON   isd.DISEASE_CD = c.CONDITION_CD and c.DISEASE_GRP_CD = @nbs_page_form_cd
       INNER JOIN dbo.INVESTIGATION nrt_inv_key with (nolock) ON isd.investigation_key = nrt_inv_key.investigation_key
    -- and  nrt_inv_key.case_uid in (SELECT value FROM STRING_SPLIT(@phc_id_list, ','));

	   if @debug = 'true'
            select * from #tmp_DynDm_SUMM_DATAMART;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );



	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_Investigation_Data';


/*Make a list of rdb_column_nm separated by ,*/

--DX select * from  #tmp_DynDm_INV_METADATA ;

	DECLARE @listStr VARCHAR(MAX)
/*


SELECT @listStr = COALESCE(@listStr+',' ,'') + RDB_COLUMN_NM  + ' '+ coalesce(USER_DEFINED_COLUMN_NM,'')
FROM  #tmp_DynDm_INV_METADATA;
*/


/*It creates a new table with a list of all the rdb column name plus the investigation key*/
--	CREATE TABLE INVESTIGATION_DATA AS

/*
select  DISTINCT FORM_CD, DATAMART_NM, RDB_TABLE_NM, RDB_COLUMN_NM,USER_DEFINED_COLUMN_NM , rdb_column_nm_list
            -- into #tmp_DynDm_INV_METADATA
FROM dbo.v_nrt_nbs_investigation_rdb_table_metadata inv_meta
where  inv_meta.INVESTIGATION_FORM_CD=@nbs_page_form_cd;

*/

	SET @temp_sql = '
        IF OBJECT_ID('''+@tmp_DynDm_INVESTIGATION_DATA+''', ''U'') IS NOT NULL
            drop table '+@tmp_DynDm_INVESTIGATION_DATA;
    exec sp_executesql @temp_sql;


  --  declare @SQL varchar(MAX);

	SET @temp_sql = '
 		SELECT  rdb_column_nm_list , isd.INVESTIGATION_KEY
	        into '+@tmp_DynDm_INVESTIGATION_DATA+'
	        FROM dbo.INVESTIGATION inv with ( nolock)
	           INNER JOIN #tmp_DynDm_SUMM_DATAMART isd ON	isd.INVESTIGATION_KEY  =inv.INVESTIGATION_KEY
	           inner join dbo.v_nrt_nbs_investigation_rdb_table_metadata inv_meta on isd.DISEASE_GRP_CD =  inv_meta.INVESTIGATION_FORM_CD
	           and inv_meta.INVESTIGATION_FORM_CD = '''+@nbs_page_form_cd +''' and isd.DISEASE_GRP_CD = '''+@nbs_page_form_cd +'''';
	exec sp_executesql @temp_sql;

	if @debug = 'true'
		SET @temp_sql = '
	 	select * from '+ @tmp_DynDm_INVESTIGATION_DATA;
		exec sp_executesql @temp_sql;


				SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name  ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );





/*
    BEGIN TRANSACTION;

	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  #tmp_DynDm_Case_Management_Metadata';


	--DX  select * from #tmp_DynDm_Investigation_Data;

/*-------INVESTIGATION ENDS----------*/
/*CMData  data*/


/*it creates a new table with all the metadata associated to that investigation for the specific datamart name*/
--	CREATE TABLE CASE_MANAGEMENT_METADATA AS


     IF OBJECT_ID('#tmp_DynDm_Case_Management_Metadata', 'U') IS NOT NULL
 				drop table #tmp_DynDm_Case_Management_Metadata;




	SELECT  DISTINCT INIT.FORM_CD, INIT.DATAMART_NM, NBS_RDB_METADATA.RDB_TABLE_NM,
	NBS_RDB_METADATA.RDB_COLUMN_NM,NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM
	into #tmp_DynDm_Case_Management_Metadata
	FROM dbo.v_nbs_page INIT
	 INNER JOIN NBS_ODSE..NBS_UI_METADATA  with ( nolock) 	ON NBS_UI_METADATA.INVESTIGATION_FORM_CD = INIT.FORM_CD
	 INNER JOIN NBS_ODSE..NBS_RDB_METADATA  with ( nolock) 	ON NBS_UI_METADATA.NBS_UI_METADATA_UID = NBS_RDB_METADATA.NBS_UI_METADATA_UID
	WHERE RDB_TABLE_NM='D_CASE_MANAGEMENT'
	 AND NBS_UI_METADATA.INVESTIGATION_FORM_CD=(SELECT FORM_CD FROM dbo.NBS_PAGE WHERE DATAMART_NM=@DATAMART_NAME)
	 AND NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM <> ''
	 and NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM IS NOT NULL
	--ORDER BY INIT.FORM_CD,  NBS_RDB_METADATA.RDB_COLUMN_NM
	;

	--DX select *	from  #tmp_DynDm_Case_Management_Metadata;

	-- RAVI -- why set FORM_CD here
	update  #tmp_DynDm_Case_Management_Metadata
	set FORM_CD =(SELECT FORM_CD FROM dbo.NBS_PAGE WHERE DATAMART_NM=@DATAMART_NAME),
	RDB_TABLE_NM='D_CASE_MANAGEMENT'
	;




				SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name  ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );



    COMMIT TRANSACTION;

	*/



     SELECT  DISTINCT FORM_CD, DATAMART_NM, RDB_TABLE_NM, RDB_COLUMN_NM,USER_DEFINED_COLUMN_NM ,INVESTIGATION_FORM_CD,rdb_column_nm_list
	into #tmp_DynDm_Case_Management_Metadata
	FROM dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata case_meta
	where case_meta.INVESTIGATION_FORM_CD=@nbs_page_form_cd ;


  if @debug = 'true'
            select * from #tmp_DynDm_Case_Management_Metadata;




	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_INV_SUMM_DATAMART';





/*New table with some columns of the investigation summary datamart*/


--CREATE TABLE INV_SUMM_DATAMART AS

     IF OBJECT_ID('#tmp_DynDm_INV_SUMM_DATAMART', 'U') IS NOT NULL
 				drop table #tmp_DynDm_INV_SUMM_DATAMART;

	CREATE TABLE #tmp_DynDm_INV_SUMM_DATAMART
     (PROGRAM_JURISDICTION_OID numeric(20,0) NULL,
     INVESTIGATION_KEY bigint NOT NULL,
     PATIENT_KEY bigint NULL,
     PATIENT_LOCAL_ID varchar(50) NULL,
     INVESTIGATION_CREATE_DATE datetime NULL,
     INVESTIGATION_CREATED_BY varchar(50) NULL,
     INVESTIGATION_LAST_UPDTD_DATE datetime NULL,
     INVESTIGATION_LAST_UPDTD_BY varchar(50) NULL,
     EVENT_DATE datetime NULL,
     EVENT_DATE_TYPE varchar(100) NULL,
     LABORATORY_INFORMATION varchar(4000) NULL,
     EARLIEST_SPECIMEN_COLLECT_DATE datetime NULL,
     NOTIFICATION_STATUS varchar(50) NULL,
     CONFIRMATION_METHOD varchar(4000) NULL,
     CONFIRMATION_DT datetime NULL,
     DISEASE_CD varchar(50) NULL,
     DISEASE varchar(100) NULL,
     NOTIFICATION_LAST_UPDATED_DATE datetime NULL,
     NOTIFICATION_LOCAL_ID varchar(50) NULL,
     PROGRAM_AREA varchar(50) NULL,
     PATIENT_COUNTY_CODE varchar(50) NULL,
     JURISDICTION_NM varchar(100) NULL
     )

	SET @temp_sql = '
	INSERT INTO #tmp_DynDm_INV_SUMM_DATAMART
	 SELECT INV_SUMM_DATAMART.PROGRAM_JURISDICTION_OID,
			INV_SUMM_DATAMART.INVESTIGATION_KEY,
			INV_SUMM_DATAMART.PATIENT_KEY,
			INV_SUMM_DATAMART.PATIENT_LOCAL_ID,
			INV_SUMM_DATAMART.INVESTIGATION_CREATE_DATE,
			INV_SUMM_DATAMART.INVESTIGATION_CREATED_BY,
			INV_SUMM_DATAMART.INVESTIGATION_LAST_UPDTD_DATE,
			INV_SUMM_DATAMART.INVESTIGATION_LAST_UPDTD_BY,
			INV_SUMM_DATAMART.EVENT_DATE,
			INV_SUMM_DATAMART.EVENT_DATE_TYPE,
			INV_SUMM_DATAMART.LABORATORY_INFORMATION,
			INV_SUMM_DATAMART.EARLIEST_SPECIMEN_COLLECT_DATE,
			INV_SUMM_DATAMART.NOTIFICATION_STATUS,
			INV_SUMM_DATAMART.CONFIRMATION_METHOD,
			INV_SUMM_DATAMART.CONFIRMATION_DT,
			INV_SUMM_DATAMART.DISEASE_CD,
			INV_SUMM_DATAMART.DISEASE,
			INV_SUMM_DATAMART.NOTIFICATION_LAST_UPDATED_DATE,
			INV_SUMM_DATAMART.NOTIFICATION_LOCAL_ID,
			INV_SUMM_DATAMART.PROGRAM_AREA,
			--INV_SUMM_DATAMART.INVESTIGATION_LAST_UPDTD_BY,
			INV_SUMM_DATAMART.PATIENT_COUNTY_CODE,
			INV_SUMM_DATAMART.JURISDICTION_NM
	FROM dbo.INV_SUMM_DATAMART with ( nolock)
	INNER JOIN '+@tmp_DynDm_INVESTIGATION_DATA+' d ON d.INVESTIGATION_KEY = INV_SUMM_DATAMART.INVESTIGATION_KEY
	inner join dbo.investigation nrt_inv with ( nolock ) on nrt_inv.investigation_key =  d.INVESTIGATION_KEY
	and  nrt_inv.case_uid in (SELECT value FROM STRING_SPLIT('''+@phc_id_list+''', '',''));';

	exec sp_executesql @temp_sql;

	  if @debug = 'true'
            select * from #tmp_DynDm_INV_SUMM_DATAMART;


/*Patient data*/

	--CREATE TABLE PAT_METADATA AS



				SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name  ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );




	/*
    BEGIN TRANSACTION;

	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_PAT_METADATA';



     IF OBJECT_ID('#tmp_DynDm_PAT_METADATA', 'U') IS NOT NULL
 				drop table #tmp_DynDm_PAT_METADATA;

 				*/

/*

 SELECT  DISTINCT INIT.FORM_CD, INIT.DATAMART_NM, NBS_RDB_METADATA.RDB_TABLE_NM, NBS_RDB_METADATA.RDB_COLUMN_NM,NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM
	into #tmp_DynDm_PAT_METADATA
	FROM #TMP_INIT INIT
	  INNER JOIN NBS_ODSE..NBS_UI_METADATA  with ( nolock) ON NBS_UI_METADATA.INVESTIGATION_FORM_CD = INIT.FORM_CD
      INNER JOIN NBS_ODSE..NBS_RDB_METADATA  with ( nolock) ON NBS_UI_METADATA.NBS_UI_METADATA_UID = NBS_RDB_METADATA.NBS_UI_METADATA_UID
   WHERE RDB_TABLE_NM='D_PATIENT'
     AND NBS_UI_METADATA.INVESTIGATION_FORM_CD=(SELECT FORM_CD FROM dbo.NBS_PAGE WHERE DATAMART_NM=@DATAMART_NAME)
     AND RDB_COLUMN_NM NOT IN ('PATIENT_WORK_STREET_ADDRESS_1', 'PATIENT_WORK_STREET_ADDRESS_2')
     AND NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM <> ''
	 and NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM IS NOT NULL
    ;

*/

    /*
      SELECT  DISTINCT FORM_CD, DATAMART_NM, RDB_TABLE_NM, RDB_COLUMN_NM,USER_DEFINED_COLUMN_NM ,INVESTIGATION_FORM_CD,rdb_column_nm_list
	into #tmp_DynDm_PAT_METADATA
	FROM dbo.v_nrt_nbs_d_patient_rdb_table_metadata pat_meta
	where pat_meta.INVESTIGATION_FORM_CD=@nbs_page_form_cd ;
*/

--DECLARE @listStr VARCHAR(MAX), @SQL VARCHAR(MAX)

/*
SET  @listStr =null;

SELECT @listStr = COALESCE(@listStr+',' ,'') + RDB_COLUMN_NM  + ' '+ coalesce(USER_DEFINED_COLUMN_NM,'')
FROM  #tmp_DynDm_PAT_METADATA;

*/

	/*			SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );



    COMMIT TRANSACTION;
	*/


	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_Patient_Data';


	SET @temp_sql = '
     IF OBJECT_ID('''+@tmp_DynDm_PATIENT_DATA+''', ''U'') IS NOT NULL
 				drop table '+@tmp_DynDm_PATIENT_DATA;
	 exec sp_executesql @temp_sql;

	/*
	SET @SQL = ' SELECT  '+@listStr +' , #tmp_DynDm_SUMM_DATAMART.INVESTIGATION_KEY ' +
	           ' into #tmp_DynDm_Patient_Data ' +
	           ' FROM dbo.D_PATIENT  with ( nolock) ' +
               '    INNER JOIN #tmp_DynDm_SUMM_DATAMART ON 	D_PATIENT.PATIENT_KEY = #tmp_DynDm_SUMM_DATAMART.PATIENT_KEY '
	  ;
--select 'PATIENT DATA',@SQL;

	   EXEC (@SQL);

*/
	SET @temp_sql = '
	 SELECT  pat_meta.rdb_column_nm_list , isd.INVESTIGATION_KEY
	            into '+@tmp_DynDm_PATIENT_DATA+'
	            FROM dbo.D_PATIENT pat with ( nolock)
                   INNER JOIN #tmp_DynDm_SUMM_DATAMART isd ON 	pat.PATIENT_KEY = isd.PATIENT_KEY
      	           inner join dbo.v_nrt_nbs_d_patient_rdb_table_metadata pat_meta on isd.DISEASE_GRP_CD =  pat_meta.INVESTIGATION_FORM_CD
		           and pat_meta.INVESTIGATION_FORM_CD = '''+@nbs_page_form_cd +''' and isd.DISEASE_GRP_CD = '''+@nbs_page_form_cd +'''';
	exec sp_executesql @temp_sql;


	    if @debug = 'true'
		    SET @temp_sql = '
	      	select * from '+ @tmp_DynDm_PATIENT_DATA;
		    exec sp_executesql @temp_sql;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );





--DX select * from @tmp_DynDm_PATIENT_DATA ;


--%mend INVEST_FORM_PROC;



                	SET @Proc_Step_no = @Proc_Step_no + 1;
					SET @Proc_Step_Name = 'SP_COMPLETE';


					INSERT INTO dbo.job_flow_log (
							batch_id
							,[Dataflow_Name]
						   ,[package_Name]
							,[Status_Type]
						   ,[step_number]
						   ,[step_name]
						   ,[row_count]
						   )
						   VALUES
						   (
						   @batch_id,
						   @Dataflow_Name
						   ,@Package_Name
						   ,'COMPLETE'
						   ,@Proc_Step_no
						   ,@Proc_Step_name
						   ,@RowCount_no
						 );



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

        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [Error_Description]
                                         , [row_count])
        VALUES ( @batch_id
               , @Dataflow_Name
               , @Package_Name
               , 'ERROR'
               , @Proc_Step_no
               , @Proc_Step_name
               , @FullErrorMessage
               , 0);


      return -1 ;

	END CATCH

END

;