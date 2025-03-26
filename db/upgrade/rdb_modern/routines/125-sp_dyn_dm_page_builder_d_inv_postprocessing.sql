CREATE OR ALTER PROCEDURE [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing

            @batch_id BIGINT,
			@DATAMART_NAME VARCHAR(100),
			@RDB_TABLE_NM  VARCHAR(100),
			@TABLE_NM  VARCHAR(100),
			@DIM_KEY VARCHAR(100),
			@phc_id_list nvarchar(max)
	AS

BEGIN
	 BEGIN TRY


	--    	DECLARE  @batch_id BIGINT = 999;  DECLARE @DATAMART_NAME  VARCHAR(100) =  'STD' , @RDB_TABLE_NM  VARCHAR(100) = 'D_INV_ADMINISTRATIVE',  @TABLE_NM  VARCHAR(100) = 'D_INV_ADMINISTRATIVE', @DIM_KEY  VARCHAR(100) = 'D_INV_ADMINISTRATIVE_KEY';


		DECLARE @RowCount_no INT = 0 ;
		DECLARE @Proc_Step_no FLOAT = 0 ;
		DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
		DECLARE @batch_start_time datetime = null ;
		DECLARE @batch_end_time datetime = null ;
		DECLARE @nbs_page_form_cd varchar(200)='';
		DECLARE @Dataflow_Name varchar(200)='DYNAMIC_DATAMART POST-PROCESSING';
	    DECLARE @Package_Name varchar(200)='DynDm_Manage_D_Inv_sp '+@DATAMART_NAME+' - '+@RDB_TABLE_NM;




    BEGIN TRANSACTION;

	SET @Proc_Step_no = 1;
	SET @Proc_Step_Name = 'SP_Start';

 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );

    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
	SET @nbs_page_form_cd = (SELECT FORM_CD FROM dbo.v_nrt_nbs_page WHERE DATAMART_NM=@DATAMART_NAME)

	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  #tmp_DynDm_D_INV_METADATA';


        declare @countstd int = 0;


	   select  @COUNTSTD = count(*)
	    from dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata with (nolock)
        ;


  declare @FACT_CASE varchar(40) = '';


  if @countstd > 1
     begin
      set @FACT_CASE = 'F_STD_PAGE_CASE';
	end
  else
     begin
      set @FACT_CASE = 'F_PAGE_CASE';
     end
  ;

  --select @fact_case;



/*It creates a table with the metadata for that specific datamartnm and rdb_table_nm which is the one received as a parameter*/

--	CREATE TABLE D_INV_METADATA AS


     IF OBJECT_ID('#tmp_DynDm_D_INV_METADATA', 'U') IS NOT NULL
 				drop table #tmp_DynDm_D_INV_METADATA;


	SELECT  DISTINCT d_inv_meta.FORM_CD, d_inv_meta.DATAMART_NM, d_inv_meta.RDB_TABLE_NM, d_inv_meta.RDB_COLUMN_NM,d_inv_meta.USER_DEFINED_COLUMN_NM
	  into #tmp_DynDm_D_INV_METADATA
	  from dbo.v_nrt_d_inv_metadata d_inv_meta
	WHERE d_inv_meta.RDB_TABLE_NM=@RDB_TABLE_NM
	  AND d_inv_meta.INVESTIGATION_FORM_CD= @nbs_page_form_cd

   ;

	update #tmp_DynDm_D_INV_METADATA
	  set FORM_CD =@nbs_page_form_cd,
	  RDB_TABLE_NM=@RDB_TABLE_NM
	;


				SELECT @ROWCOUNT_NO = @@ROWCOUNT;



 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );



	 COMMIT TRANSACTION;

    BEGIN TRANSACTION;

			SET @Proc_Step_no = @Proc_Step_no + 1;
			SET @Proc_Step_Name = 'REMOVING MISSING COLUMNS  #tmp_DynDm_D_INV_METADATA';



	declare @SQL varchar(max);


			 SET @SQL = ' delete from  #tmp_DynDm_D_INV_METADATA' +
						'   WHERE RDB_COLUMN_NM not in ( SELECT      COLUMN_NAME FROM  INFORMATION_SCHEMA.COLUMNS ' +
						'    where    TABLE_NAME = '''+@RDB_TABLE_NM +''' ); '
						;

		--DX	  select 2,@SQL;

			 EXEC (@SQL);



			SELECT @ROWCOUNT_NO = @@ROWCOUNT;


		 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
		 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );



	 COMMIT TRANSACTION;




    BEGIN TRANSACTION;

	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'UPDATING #tmp_DynDm_D_INV_METADATA';


	update #tmp_DynDm_D_INV_METADATA
	 set USER_DEFINED_COLUMN_NM = rtrim(RDB_COLUMN_NM)
	where USER_DEFINED_COLUMN_NM is null
	;

	--DX select * from #tmp_DynDm_D_INV_METADATA  with (nolock)

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	 COMMIT TRANSACTION;


	BEGIN TRANSACTION;

	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_D_INV_METADATA_1';



     IF OBJECT_ID('#tmp_DynDm_D_INV_METADATA_1', 'U') IS NOT NULL
 				drop table #tmp_DynDm_D_INV_METADATA_1;



	SELECT a.*
	INTO  #tmp_DynDm_D_INV_METADATA_1
	FROM  #tmp_DynDm_D_INV_METADATA a
	INNER JOIN
          (SELECT    ROW_NUMBER() over(PARTITION BY USER_DEFINED_COLUMN_NM ORDER BY  USER_DEFINED_COLUMN_NM) AS SEQ,  #tmp_DynDm_D_INV_METADATA.*
            FROM #tmp_DynDm_D_INV_METADATA) b
        ON a.USER_DEFINED_COLUMN_NM = b.USER_DEFINED_COLUMN_NM and a.rdb_column_nm = b.rdb_column_nm
    WHERE b.SEQ = 1
	;


			SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	 COMMIT TRANSACTION;

    BEGIN TRANSACTION;

	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_D_INV_METADATA_distinct';




     IF OBJECT_ID('#tmp_DynDm_D_INV_METADATA_distinct', 'U') IS NOT NULL
 				drop table #tmp_DynDm_D_INV_METADATA_distinct;

	select distinct (RDB_COLUMN_NM  + ' AS ' + USER_DEFINED_COLUMN_NM) as USER_DEFINED_COLUMN_NM
	into #tmp_DynDm_D_INV_METADATA_distinct
	from #tmp_DynDm_D_INV_METADATA_1  with (nolock)
	;

	-- select * from #tmp_DynDm_D_INV_METADATA_distinct DD_R_ADM_NUMERIC_UNIT  order by 1

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );



	 COMMIT TRANSACTION;


    BEGIN TRANSACTION;

	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_D_INV_METADATA_OTH';



	DECLARE @D_INV_CASE_LIST VARCHAR(MAX);



	SET  @D_INV_CASE_LIST =null;

	SELECT @D_INV_CASE_LIST = COALESCE(@D_INV_CASE_LIST+',' ,'') + USER_DEFINED_COLUMN_NM
	 FROM  #tmp_DynDm_D_INV_METADATA_distinct with (nolock);

/*This is the same table than the previous one but for questions with other indicator as true*/

--	CREATE TABLE D_INV_METADATA_OTH AS



     IF OBJECT_ID('#tmp_DynDm_D_INV_METADATA_OTH', 'U') IS NOT NULL
 				drop table #tmp_DynDm_D_INV_METADATA_OTH;
	SELECT  DISTINCT OTHER_VALUE_IND_CD, DATAMART_NM,
	         RDB_TABLE_NM,
	         substring(LTRIM(RTRIM(RDB_COLUMN_NM)),1,26)+'_OTH' as RDB_COLUMN_NM,
			 USER_DEFINED_COLUMN_NM +'_OTH' as  USER_DEFINED_COLUMN_NM
	into #tmp_DynDm_D_INV_METADATA_OTH
	FROM v_nrt_d_inv_metadata
	WHERE RDB_TABLE_NM=@RDB_TABLE_NM
	AND INVESTIGATION_FORM_CD= @nbs_page_form_cd
	AND OTHER_VALUE_IND_CD='T'
	--ORDER BY NBS_RDB_METADATA.RDB_COLUMN_NM
	;

/*It creates the list of OTH columns*/

SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


 COMMIT TRANSACTION;



	BEGIN TRANSACTION;

	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_D_INV_METADATA_OTH_1';



     IF OBJECT_ID('#tmp_DynDm_D_INV_METADATA_OTH_1', 'U') IS NOT NULL
 				drop table #tmp_DynDm_D_INV_METADATA_OTH_1;



	SELECT a.*
	INTO  #tmp_DynDm_D_INV_METADATA_OTH_1
	FROM  #tmp_DynDm_D_INV_METADATA_OTH a
	INNER JOIN
          (SELECT    ROW_NUMBER() over(PARTITION BY USER_DEFINED_COLUMN_NM ORDER BY  USER_DEFINED_COLUMN_NM) AS SEQ,  #tmp_DynDm_D_INV_METADATA_OTH.*
            FROM             #tmp_DynDm_D_INV_METADATA_OTH) b
        ON a.USER_DEFINED_COLUMN_NM = b.USER_DEFINED_COLUMN_NM and a.rdb_column_nm = b.rdb_column_nm
    WHERE b.SEQ = 1
	;


			SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	 COMMIT TRANSACTION;

    BEGIN TRANSACTION;

	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  COLUMN LIST';



DECLARE @D_INV_CASE_OTH_list VARCHAR(MAX) = null;
DECLARE @D_INV_CASE_OTH_list_flag  int = 0;


SELECT @D_INV_CASE_OTH_list = coalesce((COALESCE(@D_INV_CASE_OTH_list+',' ,'') + RDB_COLUMN_NM + ' AS ' +  coalesce(USER_DEFINED_COLUMN_NM,'')),'')
FROM  #tmp_DynDm_D_INV_METADATA_OTH_1 with (nolock);




if (len(@D_INV_CASE_OTH_list) <  1 or @D_INV_CASE_OTH_list is null )
	 begin
           --  SET @D_INV_CASE_OTH_list = @FACT_CASE+'.INVESTIGATION_KEY';

		  --    SET @D_INV_CASE_OTH_list = ''''' as t1 ,';

			  SET @D_INV_CASE_OTH_list_flag = 1;
	end


	SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


 COMMIT TRANSACTION;


    BEGIN TRANSACTION;

	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_D_INV_METADATA_UNIT';





     IF OBJECT_ID('#tmp_DynDm_D_INV_METADATA_UNIT', 'U') IS NOT NULL
 				drop table #tmp_DynDm_D_INV_METADATA_UNIT;



	SELECT  DISTINCT OTHER_VALUE_IND_CD, DATAMART_NM,
	        RDB_TABLE_NM,
			RDB_COLUMN_NM +  '_UNIT' as RDB_COLUMN_NM ,
			USER_DEFINED_COLUMN_NM +  '_UNIT' as  USER_DEFINED_COLUMN_NM
	into #tmp_DynDm_D_INV_METADATA_UNIT
	FROM dbo.v_nrt_d_inv_metadata
	WHERE RDB_TABLE_NM=@RDB_TABLE_NM
	AND INVESTIGATION_FORM_CD=@nbs_page_form_cd
	AND DATA_TYPE IN ('Numeric','NUMERIC') AND CODE_SET_GROUP_ID IS NULL AND MASK IS NOT NULL and UPPER(UNIT_TYPE_CD)='CODED'
		and  NOT EXISTS (    SELECT 1
            FROM  #tmp_DynDm_D_INV_METADATA AS t2
               WHERE t2.USER_DEFINED_COLUMN_NM = USER_DEFINED_COLUMN_NM +  '_UNIT'
         )
	;


			SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	 COMMIT TRANSACTION;

	BEGIN TRANSACTION;

			SET @Proc_Step_no = @Proc_Step_no + 1;
			SET @Proc_Step_Name = 'REMOVING MISSING COLUMNS tmp_DynDm_D_INV_METADATA_UNIT';

			--delete from  #tmp_DynDm_D_INV_METADATA
			--WHERE RDB_COLUMN_NM not in ( SELECT      COLUMN_NAME FROM  INFORMATION_SCHEMA.COLUMNS
			--where    TABLE_NAME = 'D_INV_LAB_FINDING')
			--;


	--declare @SQL varchar(max);


			 SET @SQL = ' delete from  #tmp_DynDm_D_INV_METADATA_UNIT' +
						'   WHERE RDB_COLUMN_NM not in ( SELECT      COLUMN_NAME FROM  INFORMATION_SCHEMA.COLUMNS ' +
						'    where    TABLE_NAME = '''+@RDB_TABLE_NM +''' ); '
						;

	--DX		  select 3,@SQL;

			 EXEC (@SQL);



			SELECT @ROWCOUNT_NO = @@ROWCOUNT;


		 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
		 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );



	 COMMIT TRANSACTION;



	BEGIN TRANSACTION;

	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_D_INV_METADATA_UNIT_1';



     IF OBJECT_ID('#tmp_DynDm_D_INV_METADATA_UNIT_1', 'U') IS NOT NULL
 				drop table #tmp_DynDm_D_INV_METADATA_UNIT_1;



	SELECT a.*
	INTO  #tmp_DynDm_D_INV_METADATA_UNIT_1
	FROM  #tmp_DynDm_D_INV_METADATA_UNIT a
	INNER JOIN
          (SELECT ROW_NUMBER() over(PARTITION BY USER_DEFINED_COLUMN_NM ORDER BY  USER_DEFINED_COLUMN_NM) AS SEQ,  #tmp_DynDm_D_INV_METADATA_UNIT.*
            FROM #tmp_DynDm_D_INV_METADATA_UNIT) b
        ON a.USER_DEFINED_COLUMN_NM = b.USER_DEFINED_COLUMN_NM and a.rdb_column_nm = b.rdb_column_nm
    WHERE b.SEQ = 1
	;


			SELECT @ROWCOUNT_NO = @@ROWCOUNT;


 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	 COMMIT TRANSACTION;




    BEGIN TRANSACTION;

	SET @Proc_Step_no = @Proc_Step_no + 1;

	SET @Proc_Step_Name = 'GENERATING  #tmp_DynDM_'+@RDB_TABLE_NM ;






 declare @D_INV_CASE_UNIT_list varchar(Max) = null ;


SELECT @D_INV_CASE_UNIT_list = coalesce((COALESCE(@D_INV_CASE_UNIT_list+',' ,'') + RDB_COLUMN_NM + ' AS  ' +  coalesce(USER_DEFINED_COLUMN_NM,'')),'')
FROM  #tmp_DynDm_D_INV_METADATA_UNIT_1;




if ((len(@D_INV_CASE_UNIT_list) <  1 or @D_INV_CASE_UNIT_list is null )  )
	 begin
         --    SET @D_INV_CASE_UNIT_list = @FACT_CASE+'.INVESTIGATION_KEY'

			 SET @D_INV_CASE_UNIT_list = null ;
	end


declare @listStr as varchar(max) = '';


SET @listStr =   coalesce(@D_INV_CASE_UNIT_list + ',','') + coalesce(@D_INV_CASE_OTH_list + ',','') + coalesce(@D_INV_CASE_list+' ,','');


DECLARE @TableName VARCHAR(200) = '#tmp_DynDM_'+@RDB_TABLE_NM

IF OBJECT_ID(@TableName) IS NOT NULL
    EXEC ('DROP Table ' + @TableName)
	;
--
--
--		IF  NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('#tmp_DynDM_SUMM_DATAMART') AND NAME ='idx_tmp_summart_dissesgrp')
--		CREATE NONCLUSTERED INDEX  idx_tmp_summart_dissesgrp ON [dbo].[#tmp_DynDm_SUMM_DATAMART] ([DISEASE_GRP_CD]);
--
--
--		IF  NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('#tmp_DynDM_SUMM_DATAMART') AND NAME ='idx_tmp_summart_invkey')
--		CREATE CLUSTERED INDEX idx_tmp_summart_invkey ON [dbo].[#tmp_DynDM_SUMM_DATAMART]( [INVESTIGATION_KEY] ASC);




		IF (EXISTS (select * FROM INFORMATION_SCHEMA.TABLES
		WHERE TABLE_SCHEMA = 'dbo'
		AND TABLE_NAME like  'D_INV_STD'))
		   BEGIN

					IF  NOT EXISTS(SELECT * FROM SYS.INDEXES WHERE OBJECT_ID = OBJECT_ID('DBO.D_INV_STD') AND NAME ='idx_D_INV_STD_key')
							 CREATE  NONCLUSTERED INDEX  idx_D_INV_STD_key ON dbo.D_INV_STD(D_INV_STD_key);

		   END;







		IF (EXISTS (select * FROM INFORMATION_SCHEMA.TABLES
		WHERE TABLE_SCHEMA = 'dbo'
		AND TABLE_NAME like  'F_PAGE_CASE'))
		   BEGIN

					IF  NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('dbo.F_PAGE_CASE') AND NAME ='idx_fpgcase_invkey')
					CREATE NONCLUSTERED INDEX idx_fpgcase_invkey ON [dbo].[F_PAGE_CASE] ([INVESTIGATION_KEY]);

		   END;



		IF (EXISTS (select * FROM INFORMATION_SCHEMA.TABLES
		WHERE TABLE_SCHEMA = 'dbo'
		AND TABLE_NAME like  'F_STD_PAGE_CASE'))
		   BEGIN
			 IF  NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('dbo.F_STD_PAGE_CASE') AND NAME ='idx_fstdpgcase_invkey')
				 CREATE NONCLUSTERED INDEX idx_fstdpgcase_invkey ON [dbo].[F_STD_PAGE_CASE] ([INVESTIGATION_KEY]);
		   END;


	  	SELECT isd.PATIENT_KEY AS PATIENT_KEY, isd.INVESTIGATION_KEY, c.DISEASE_GRP_CD
	    into #tmp_DynDm_SUMM_DATAMART
	     FROM dbo.INV_SUMM_DATAMART isd with ( nolock)
	       INNER JOIN dbo.v_condition_dim c with ( nolock)  ON   isd.DISEASE_CD = c.CONDITION_CD and c.DISEASE_GRP_CD = @nbs_page_form_cd
	       INNER JOIN dbo.INVESTIGATION I with (nolock) ON isd.investigation_key = I.investigation_key
	     and  I.case_uid in (SELECT value FROM STRING_SPLIT(@phc_id_list, ','));


		if  object_id('dbo.'+@RDB_TABLE_NM) is not null
		  Begin

			 SET @SQL = '   SELECT distinct  '+@listStr + ' tmp.INVESTIGATION_KEY ' +
						'    into dbo.tmp_DynDM_'+@RDB_TABLE_NM +
						'    FROM #tmp_DynDM_SUMM_DATAMART tmp with (nolock)'+
						'		INNER JOIN  dbo.'+@FACT_CASE +'   with (nolock)  ON tmp.INVESTIGATION_KEY  = '+@FACT_CASE+'.INVESTIGATION_KEY '+
						'		INNER JOIN  dbo.'+@RDB_TABLE_NM+'  with (nolock) ON	'+@FACT_CASE+'.'+@DIM_KEY+'  = '+@RDB_TABLE_NM+'.'+@DIM_KEY +
						'	  WHERE tmp.DISEASE_GRP_CD = (SELECT FORM_CD FROM dbo.v_nrt_nbs_page WHERE DATAMART_NM='''+@DATAMART_NAME+''' )'
						;

			-- select 1,@SQL;

			 --EXEC (@SQL);
		  end
		else
		  Begin

		SET @SQL = '  SELECT  distinct '+@listStr + ' tmp_DynDM_SUMM_DATAMART.INVESTIGATION_KEY ' +
						'    into #tmp_DynDM_'+@RDB_TABLE_NM +
						'    FROM #tmp_DynDM_SUMM_DATAMART with (nolock) '
						;

			 -- select 2,@SQL;

			-- EXEC (@SQL);
		  end
		  ;

		 EXEC (@SQL);


		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
		 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


		 COMMIT TRANSACTION;


			BEGIN TRANSACTION;

			SET @Proc_Step_no = @Proc_Step_no + 1;
			SET @Proc_Step_Name = 'SP_COMPLETE';

		 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
		 VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'COMPLETE' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );




    	COMMIT TRANSACTION;





		END TRY
				BEGIN CATCH
							IF @@TRANCOUNT > 0
							BEGIN
								ROLLBACK;
							END;

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

							RETURN -1;
				END CATCH;
	END;