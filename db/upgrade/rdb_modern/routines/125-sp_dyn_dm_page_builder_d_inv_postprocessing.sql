CREATE OR ALTER PROCEDURE [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
	@batch_id BIGINT,
	@DATAMART_NAME VARCHAR(100),
	@RDB_TABLE_NM  VARCHAR(100),
	@DIM_KEY VARCHAR(100),
	@phc_id_list nvarchar(max),
	@debug BIT = 'false'
	AS
BEGIN
	 BEGIN TRY

        /**
        * OUTPUT TABLES:
        * tmp_DynDM_<RDB_TABLE_NM>_<DATAMART_NAME>_<batch_id>
        * */

        DECLARE @RowCount_no INT = 0 ;
        DECLARE @Proc_Step_no FLOAT = 0 ;
        DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
        DECLARE @nbs_page_form_cd VARCHAR(200) = '';

	DECLARE @RowCount_no INT = 0 ;
	DECLARE @Proc_Step_no FLOAT = 0 ;
	DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
	DECLARE @nbs_page_form_cd VARCHAR(200) = '';

	DECLARE @Dataflow_Name VARCHAR(200)='DYNAMIC_DATAMART POST-Processing';
	DECLARE @Package_Name VARCHAR(200)='sp_dyn_dm_page_builder_d_inv_postprocessing: '+@DATAMART_NAME+' - '+@RDB_TABLE_NM;
	DECLARE @tmp_DynDm_D_INVESTIGATION varchar(200) = 'dbo.tmp_DynDM_'+@RDB_TABLE_NM+'_'+@DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));

	SET @Proc_Step_no = 1;
	SET @Proc_Step_Name = 'SP_Start';

	--Serialize input parameters to JSON for clean logging
	DECLARE @params_json VARCHAR(200) = JSON_QUERY((
		SELECT
			@batch_id AS batch_id,
			@DATAMART_NAME AS DATAMART_NAME,
			@RDB_TABLE_NM AS RDB_TABLE_NM,
			@DIM_KEY AS DIM_KEY,
			@phc_id_list AS phc_id_list,
			@debug AS debug
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	));


 	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count], msg_description1 )
 	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO, @params_json );

	SET @nbs_page_form_cd = (SELECT FORM_CD FROM dbo.V_NRT_NBS_PAGE WHERE DATAMART_NM=@DATAMART_NAME);

-------------------------------------------------------------------------------------------------------------------------------------------

	SET @Proc_Step_no = @Proc_Step_no + 1; --2
	SET @Proc_Step_Name = ' GENERATING #tmp_DynDm_D_INV_METADATA';


    declare @countstd int = 0;

	select  @countstd = count(*)
        from dbo.V_NRT_NBS_D_CASE_MGMT_RDB_TABLE_METADATA case_meta with (nolock)
        where case_meta.INVESTIGATION_FORM_CD = @nbs_page_form_cd;


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


	SELECT  DISTINCT
		d_inv_meta.FORM_CD,
		d_inv_meta.DATAMART_NM,
		d_inv_meta.RDB_TABLE_NM,
		d_inv_meta.RDB_COLUMN_NM,
		d_inv_meta.USER_DEFINED_COLUMN_NM
	INTO
		#tmp_DynDm_D_INV_METADATA
	FROM
		dbo.V_NRT_D_INV_METADATA d_inv_meta
	WHERE
		d_inv_meta.RDB_TABLE_NM=@RDB_TABLE_NM
	  	AND d_inv_meta.INVESTIGATION_FORM_CD= @nbs_page_form_cd
   ;

	if @debug='true' print @Proc_Step_Name;

	if @debug='true' select '#tmp_DynDm_D_INV_METADATA',* from #tmp_DynDm_D_INV_METADATA;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	SET @Proc_Step_no = @Proc_Step_no + 1; --3
	SET @Proc_Step_Name = ' REMOVING MISSING COLUMNS  #tmp_DynDm_D_INV_METADATA';

	DELETE FROM
		#tmp_DynDm_D_INV_METADATA
	WHERE
		RDB_COLUMN_NM not in (
			SELECT COLUMN_NAME FROM  INFORMATION_SCHEMA.COLUMNS  where TABLE_NAME = @RDB_TABLE_NM
		)
	;

	if @debug='true' print @Proc_Step_Name;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	SET @Proc_Step_no = @Proc_Step_no + 1; --4
	SET @Proc_Step_Name = ' UPDATING #tmp_DynDm_D_INV_METADATA';


	update #tmp_DynDm_D_INV_METADATA
	set USER_DEFINED_COLUMN_NM = rtrim(RDB_COLUMN_NM)
	where USER_DEFINED_COLUMN_NM is null
	;

	if @debug='true' print @Proc_Step_Name;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	SET @Proc_Step_no = @Proc_Step_no + 1; --5
	SET @Proc_Step_Name = ' GENERATING #tmp_DynDm_D_INV_METADATA_1';


	SELECT a.*
	INTO  #tmp_DynDm_D_INV_METADATA_1
	FROM  #tmp_DynDm_D_INV_METADATA a
	INNER JOIN
        ( SELECT
			ROW_NUMBER() over(PARTITION BY USER_DEFINED_COLUMN_NM ORDER BY  USER_DEFINED_COLUMN_NM) AS SEQ,
			#tmp_DynDm_D_INV_METADATA.*
            FROM #tmp_DynDm_D_INV_METADATA
		) b
        ON a.USER_DEFINED_COLUMN_NM = b.USER_DEFINED_COLUMN_NM and a.rdb_column_nm = b.rdb_column_nm
    WHERE b.SEQ = 1
	;

	if @debug='true' print @Proc_Step_Name;
	if @debug='true' select '#tmp_DynDm_D_INV_METADATA_1',* from #tmp_DynDm_D_INV_METADATA_1;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
 	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );



	SET @Proc_Step_no = @Proc_Step_no + 1; --6
	SET @Proc_Step_Name = ' GENERATING #tmp_DynDm_D_INV_METADATA_distinct';

	SELECT DISTINCT (RDB_COLUMN_NM  + ' AS ' + USER_DEFINED_COLUMN_NM) as USER_DEFINED_COLUMN_NM
	INTO #tmp_DynDm_D_INV_METADATA_distinct
	FROM #tmp_DynDm_D_INV_METADATA_1
	;

	if @debug='true' print @Proc_Step_Name;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
 	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	SET @Proc_Step_no = @Proc_Step_no + 1; --7
	SET @Proc_Step_Name = ' GENERATING #tmp_DynDm_D_INV_METADATA_OTH';


	DECLARE @D_INV_CASE_LIST VARCHAR(MAX);
	SET  @D_INV_CASE_LIST =null;

	SELECT @D_INV_CASE_LIST = COALESCE(@D_INV_CASE_LIST+',' ,'') + USER_DEFINED_COLUMN_NM
		FROM  #tmp_DynDm_D_INV_METADATA_distinct
	;

	SELECT DISTINCT
		OTHER_VALUE_IND_CD, DATAMART_NM, RDB_TABLE_NM,
		substring(LTRIM(RTRIM(RDB_COLUMN_NM)),1,26)+'_OTH' as RDB_COLUMN_NM,
		USER_DEFINED_COLUMN_NM +'_OTH' as  USER_DEFINED_COLUMN_NM
	into
		#tmp_DynDm_D_INV_METADATA_OTH
	FROM
		dbo.V_NRT_D_INV_METADATA
		WHERE RDB_TABLE_NM=@RDB_TABLE_NM
		AND INVESTIGATION_FORM_CD= @nbs_page_form_cd
		AND OTHER_VALUE_IND_CD='T'
	;

	if @debug='true' print @Proc_Step_Name;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
 	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	SET @Proc_Step_no = @Proc_Step_no + 1; --8
	SET @Proc_Step_Name = ' GENERATING #tmp_DynDm_D_INV_METADATA_OTH_1';

	SELECT a.*
	INTO
		#tmp_DynDm_D_INV_METADATA_OTH_1
	FROM
		#tmp_DynDm_D_INV_METADATA_OTH a
	INNER JOIN
          (SELECT
		  	ROW_NUMBER() over(PARTITION BY USER_DEFINED_COLUMN_NM ORDER BY  USER_DEFINED_COLUMN_NM) AS SEQ,
			#tmp_DynDm_D_INV_METADATA_OTH.*
            FROM
			#tmp_DynDm_D_INV_METADATA_OTH
		) b
        ON a.USER_DEFINED_COLUMN_NM = b.USER_DEFINED_COLUMN_NM and a.rdb_column_nm = b.rdb_column_nm
    WHERE b.SEQ = 1
	;

	if @debug='true' print @Proc_Step_Name;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	SET @Proc_Step_no = @Proc_Step_no + 1; --9
	SET @Proc_Step_Name = ' GENERATING  COLUMN LIST';


	DECLARE @D_INV_CASE_OTH_list VARCHAR(MAX) = null;
	DECLARE @D_INV_CASE_OTH_list_flag  int = 0;

	SELECT @D_INV_CASE_OTH_list = coalesce((COALESCE(@D_INV_CASE_OTH_list+',' ,'') + RDB_COLUMN_NM + ' AS ' +  coalesce(USER_DEFINED_COLUMN_NM,'')),'')
	FROM  #tmp_DynDm_D_INV_METADATA_OTH_1;


	if (len(@D_INV_CASE_OTH_list) <  1 or @D_INV_CASE_OTH_list is null )
	begin
    	SET @D_INV_CASE_OTH_list_flag = 1;
	end

	if @debug='true' print @Proc_Step_Name;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	SET @Proc_Step_no = @Proc_Step_no + 1; --10
	SET @Proc_Step_Name = ' GENERATING #tmp_DynDm_D_INV_METADATA_UNIT';


	SELECT  DISTINCT OTHER_VALUE_IND_CD, DATAMART_NM,
	        RDB_TABLE_NM,
			RDB_COLUMN_NM +  '_UNIT' as RDB_COLUMN_NM ,
			USER_DEFINED_COLUMN_NM +  '_UNIT' as  USER_DEFINED_COLUMN_NM
	into
		#tmp_DynDm_D_INV_METADATA_UNIT
	FROM
		dbo.V_NRT_D_INV_METADATA
		WHERE RDB_TABLE_NM = @RDB_TABLE_NM
		AND INVESTIGATION_FORM_CD = @nbs_page_form_cd
		AND DATA_TYPE IN ('Numeric','NUMERIC') AND CODE_SET_GROUP_ID IS NULL AND MASK IS NOT NULL and UPPER(UNIT_TYPE_CD)='CODED'
		AND  NOT EXISTS (
			SELECT 1
			FROM  #tmp_DynDm_D_INV_METADATA AS t2
			WHERE t2.USER_DEFINED_COLUMN_NM = USER_DEFINED_COLUMN_NM +  '_UNIT'
		)
	;

	if @debug='true' print @Proc_Step_Name;
	if @debug='true' select '#tmp_DynDm_D_INV_METADATA_UNIT',* from #tmp_DynDm_D_INV_METADATA_UNIT;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
 	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	SET @Proc_Step_no = @Proc_Step_no + 1; --11
	SET @Proc_Step_Name = ' REMOVING MISSING COLUMNS #tmp_DynDm_D_INV_METADATA_UNIT';

	DELETE FROM  #tmp_DynDm_D_INV_METADATA_UNIT
	WHERE RDB_COLUMN_NM not in (
		SELECT COLUMN_NAME FROM  INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @RDB_TABLE_NM
	)
	;

	if @debug='true' print @Proc_Step_Name;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );



	SET @Proc_Step_no = @Proc_Step_no + 1; --12
	SET @Proc_Step_Name = ' GENERATING #tmp_DynDm_D_INV_METADATA_UNIT_1';


	SELECT a.*
	INTO  #tmp_DynDm_D_INV_METADATA_UNIT_1
	FROM  #tmp_DynDm_D_INV_METADATA_UNIT a
	INNER JOIN
          (SELECT ROW_NUMBER() over(PARTITION BY USER_DEFINED_COLUMN_NM ORDER BY  USER_DEFINED_COLUMN_NM) AS SEQ,  #tmp_DynDm_D_INV_METADATA_UNIT.*
            FROM #tmp_DynDm_D_INV_METADATA_UNIT
		) b
        ON a.USER_DEFINED_COLUMN_NM = b.USER_DEFINED_COLUMN_NM and a.rdb_column_nm = b.rdb_column_nm
    WHERE b.SEQ = 1
	;

	if @debug='true' print @Proc_Step_Name;
	if @debug='true' select '#tmp_DynDm_D_INV_METADATA_UNIT_1',* from #tmp_DynDm_D_INV_METADATA_UNIT_1;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	SET @Proc_Step_no = @Proc_Step_no + 1; --13
	SET @Proc_Step_Name = ' GENERATING  #tmp_DynDm_SUMM_DATAMART';

	SELECT
		isd.PATIENT_KEY AS PATIENT_KEY,
		isd.INVESTIGATION_KEY,
		c.DISEASE_GRP_CD
    into
		#tmp_DynDm_SUMM_DATAMART
    FROM
		dbo.INV_SUMM_DATAMART isd with ( nolock)
    INNER JOIN
		dbo.V_CONDITION_DIM c with ( nolock)  ON   isd.DISEASE_CD = c.CONDITION_CD and c.DISEASE_GRP_CD = @nbs_page_form_cd
    INNER JOIN
		dbo.INVESTIGATION I with (nolock) ON isd.investigation_key = I.investigation_key
     and  I.case_uid in (SELECT value FROM STRING_SPLIT(@phc_id_list, ','));

	if @debug='true' print @Proc_Step_Name;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	SET @Proc_Step_no = @Proc_Step_no + 1; --14
	SET @Proc_Step_Name = ' GENERATING '+@tmp_DynDm_D_INVESTIGATION ;


	declare @D_INV_CASE_UNIT_list VARCHAR(Max) = null ;

	SELECT @D_INV_CASE_UNIT_list = coalesce((COALESCE(@D_INV_CASE_UNIT_list+',' ,'') + RDB_COLUMN_NM + ' AS  ' +  coalesce(USER_DEFINED_COLUMN_NM,'')),'')
	FROM  #tmp_DynDm_D_INV_METADATA_UNIT_1;


	if ((len(@D_INV_CASE_UNIT_list) <  1 or @D_INV_CASE_UNIT_list is null )  )
	begin
    	SET @D_INV_CASE_UNIT_list = null ;
	end

	declare @listStr as varchar(max) = '';
	SET @listStr =   coalesce(@D_INV_CASE_UNIT_list + ',','') + coalesce(@D_INV_CASE_OTH_list + ',','') + coalesce(@D_INV_CASE_list+' ,','')

	if @debug='true' print @listStr;

	IF OBJECT_ID(@tmp_DynDm_D_INVESTIGATION) IS NOT NULL
    	EXEC ('DROP Table ' + @tmp_DynDm_D_INVESTIGATION)
	;

    declare @SQL varchar(max);

	if  object_id('dbo.'+@RDB_TABLE_NM) is not null
		Begin
			SET @SQL = '   SELECT distinct  '+@listStr + ' tmp.INVESTIGATION_KEY ' +
					'    into ' + @tmp_DynDm_D_INVESTIGATION +
					'    FROM #tmp_DynDM_SUMM_DATAMART tmp with (nolock)'+
					'		INNER JOIN  dbo.'+@FACT_CASE +'   with (nolock)  ON tmp.INVESTIGATION_KEY  = '+@FACT_CASE+'.INVESTIGATION_KEY '+
					'		INNER JOIN  dbo.'+@RDB_TABLE_NM+'  with (nolock) ON	'+@FACT_CASE+'.'+@DIM_KEY+'  = '+@RDB_TABLE_NM+'.'+@DIM_KEY
					;
		end
	else
		Begin
			SET @SQL = '  SELECT  distinct '+@listStr + ' tmp_DynDM_SUMM_DATAMART.INVESTIGATION_KEY ' +
				'    into '+@tmp_DynDm_D_INVESTIGATION +
				'    FROM #tmp_DynDM_SUMM_DATAMART with (nolock) '
				;
		end
	;

	if @debug='true' print @SQL;
	exec (@SQL);

	if @debug='true' print @Proc_Step_Name;

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );



	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'SP_COMPLETE';

	INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'COMPLETE' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			COMMIT TRANSACTION;
		END;

		-- Construct the error message string with all details:
		DECLARE @FullErrorMessage VARCHAR(8000) =
			'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
			'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
			'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
			'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
			'Error Message: ' + ERROR_MESSAGE();

		if @debug='true' print @FullErrorMessage;

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