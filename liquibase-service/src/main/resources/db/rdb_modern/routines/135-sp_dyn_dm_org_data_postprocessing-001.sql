CREATE OR ALTER PROCEDURE dbo.sp_dyn_dm_org_data_postprocessing

            @batch_id BIGINT,
			@DATAMART_NAME VARCHAR(100),
			@phc_id_list nvarchar(max),
			@debug bit = false

	AS
BEGIN
	 BEGIN TRY

	    /**
         * OUTPUT TABLES:
         * tmp_DynDm_Organization_<DATAMART_NAME>_<batch_id>
         * */

		DECLARE @RowCount_no INT = 0  ;
		DECLARE @Proc_Step_no FLOAT = 0 ;
		DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
		DECLARE @batch_start_time datetime = null ;
		DECLARE @batch_end_time datetime = null ;
		DECLARE @nbs_page_form_cd  varchar(200)= '';
		DECLARE @Dataflow_Name varchar(200)='DYNAMIC_DATAMART POST-PROCESSING';
	    DECLARE @Package_Name varchar(200)='DynDm_OrgData_sp '+@DATAMART_NAME;
        DECLARE @RowCount_no INT = 0  ;
        DECLARE @Proc_Step_no FLOAT = 0 ;
        DECLARE @Proc_Step_Name VARCHAR(200) = '' ;

        DECLARE @nbs_page_form_cd  varchar(200)= '';
        DECLARE @Dataflow_Name varchar(200)='DYNAMIC_DATAMART POST-PROCESSING';
        DECLARE @Package_Name varchar(200)='sp_dyn_dm_org_data_postprocessing '+@DATAMART_NAME;

        DECLARE @tmp_DynDm_ORGANIZATION varchar(200) = 'dbo.tmp_DynDm_Organization_'+@DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));

        DECLARE @temp_sql nvarchar(max);
        SET @nbs_page_form_cd = (SELECT FORM_CD FROM dbo.V_NRT_NBS_PAGE WHERE DATAMART_NM=@DATAMART_NAME);


        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );


        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING  @FACT_CASE';


        declare @countstd int = 0;

        select @COUNTSTD = count(*)
        from dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata case_meta
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

		IF @debug = 'true' PRINT @FACT_CASE;


    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
    VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );


	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = ' GENERATING  #tmp_DynDm_Organization_METADATA';

    Select RDB_COLUMN_NM, user_defined_column_nm, part_type_cd, [Key], Detail, QEC, UID, INVESTIGATION_FORM_CD
    into #tmp_DynDm_Organization_METADATA
    from v_nrt_nbs_d_organization_rdb_table_metadata
    where INVESTIGATION_FORM_CD=@nbs_page_form_cd ;


    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
    VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );



	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = ' GENERATING '+@tmp_DynDm_ORGANIZATION;

	IF OBJECT_ID(@tmp_DynDm_ORGANIZATION, 'U') IS NOT NULL
 		exec ('drop table ' +@tmp_DynDm_ORGANIZATION);


    SELECT isd.PATIENT_KEY AS PATIENT_KEY, isd.INVESTIGATION_KEY, c.DISEASE_GRP_CD
    into #tmp_DynDm_SUMM_DATAMART
    FROM dbo.INV_SUMM_DATAMART isd with ( nolock)
    INNER JOIN dbo.v_condition_dim c with ( nolock)  ON   isd.DISEASE_CD = c.CONDITION_CD and c.DISEASE_GRP_CD = @nbs_page_form_cd
    INNER JOIN dbo.INVESTIGATION I with (nolock) ON isd.investigation_key = I.investigation_key
    and  I.case_uid in (SELECT value FROM STRING_SPLIT(@phc_id_list, ','));


	SET @temp_sql = '
		select distinct investigation_key,
		cast(null as bigint) as ORGANIZATION_UID
		into '+@tmp_DynDm_ORGANIZATION+'
		 FROM #tmp_DynDm_SUMM_DATAMART'
		 -- pass the org_Id_List  param
		;
	exec sp_executesql @temp_sql;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
    VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name , @ROWCOUNT_NO );


    declare  @USER_DEFINED_COLUMN_NM varchar(max) ,@PART_TYPE_CD  varchar(max) ,@DETAIL  varchar(max) ,@QEC  varchar(max) ,@UID varchar(max);
    declare @SQL varchar(max)


    DECLARE db_cursor_org CURSOR LOCAL FOR
    select PART_TYPE_CD , [key],DETAIL,QEC ,[UID] from #tmp_DynDm_Organization_METADATA;

    OPEN db_cursor_org
    FETCH NEXT FROM db_cursor_org INTO @PART_TYPE_CD ,@USER_DEFINED_COLUMN_NM,@DETAIL ,@QEC ,@UID

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING  #tmp_DynDm_OrgPart_Table_temp';

         IF OBJECT_ID('tempdb..#tmp_DynDm_OrgPart_Table_temp', 'U') IS NOT NULL
                    drop table #tmp_DynDm_OrgPart_Table_temp;

        CREATE TABLE #tmp_DynDm_OrgPart_Table_temp (
            [ORGANIZATION_KEY] [bigint] NULL,
            [ORGANIZATION_QUICK_CODE] [varchar](50) NULL,
            [ORGANIZATION_NAME] [varchar](50) NULL,
            [ORGANIZATION_LOCAL_ID] [varchar](50) NULL,
            [ORGANIZATION_UID] [bigint] NULL,
            [ORGANIZATION_STREET_ADDRESS_1] [varchar](50) NULL,
            [ORGANIZATION_STREET_ADDRESS_2] [varchar](50) NULL,
            [ORGANIZATION_CITY] [varchar](50) NULL,
            [ORGANIZATION_STATE] [varchar](50) NULL,
            [ORGANIZATION_ZIP] [varchar](10) NULL,
            [ORGANIZATION_COUNTY] [varchar](50) NULL,
            [ORGANIZATION_PHONE_WORK] [varchar](50) NULL,
            [ORGANIZATION_PHONE_EXT_WORK] [varchar](50) NULL,
            [PART_TYPE_CD] [bigint] NULL,
            [PART_TYPE_CD_NM] varchar(100),
            [CITY_STATE_ZIP] varchar(2000),
            [DETAIL] varchar(2000),
            [INVESTIGATION_KEY] [bigint] NOT NULL
        )
		;

        SET @SQL = ' insert into #tmp_DynDm_OrgPart_Table_temp '
           + ' ([ORGANIZATION_KEY] '
           + ', [ORGANIZATION_QUICK_CODE] '
           + ', [ORGANIZATION_NAME] '
           + ', [ORGANIZATION_LOCAL_ID] '
           + ', [ORGANIZATION_UID] '
           + ', [ORGANIZATION_STREET_ADDRESS_1] '
           + ', [ORGANIZATION_STREET_ADDRESS_2] '
           + ', [ORGANIZATION_CITY] '
           + ', [ORGANIZATION_STATE] '
           + ', [ORGANIZATION_ZIP] '
           + ', [ORGANIZATION_COUNTY] '
           + ', [ORGANIZATION_PHONE_WORK] '
           + ', [ORGANIZATION_PHONE_EXT_WORK] '
           + ', [PART_TYPE_CD] '
           + ', [PART_TYPE_CD_NM] '
           + ', [CITY_STATE_ZIP] '
           + ', [DETAIL] '
           + ', [INVESTIGATION_KEY] )'
        + ' SELECT  distinct '+
        ' (d_o.ORGANIZATION_KEY)   ,  '+
        ' d_o.ORGANIZATION_QUICK_CODE ,  '+
        ' d_o.ORGANIZATION_NAME ,  '+
        ' d_o.ORGANIZATION_LOCAL_ID ,  '+
        ' d_o.ORGANIZATION_UID ,  '+
        ' d_o.ORGANIZATION_STREET_ADDRESS_1 ,  '+
        ' d_o.ORGANIZATION_STREET_ADDRESS_2 ,  '+
        ' d_o.ORGANIZATION_CITY ,  '+
        ' d_o.ORGANIZATION_STATE ,  '+
        ' d_o.ORGANIZATION_ZIP ,  '+
        ' d_o.ORGANIZATION_COUNTY ,  '+
        ' d_o.ORGANIZATION_PHONE_WORK ,  '+
        ' d_o.ORGANIZATION_PHONE_EXT_WORK ,  '+
           @PART_TYPE_CD +', '+
        ''''+   @PART_TYPE_CD +''', '+
        '   coalesce( ltrim(rtrim(ORGANIZATION_CITY))+'', '','''')+coalesce( ltrim(rtrim(ORGANIZATION_STATE))+'' '','''')+coalesce( ltrim(rtrim(ORGANIZATION_ZIP)),'''') '  +
        ' , null ,'+
        ' s_d.INVESTIGATION_KEY AS INVESTIGATION_KEY '+
        ' FROM #tmp_DynDm_SUMM_DATAMART s_d '+
        ' INNER JOIN dbo.'+@FACT_CASE+ '   ON s_d.INVESTIGATION_KEY =  '+@FACT_CASE+ '.INVESTIGATION_KEY '+
        ' LEFT JOIN dbo.D_ORGANIZATION  d_o ON '+@FACT_CASE+'.'+@PART_TYPE_CD+' = d_o.ORGANIZATION_KEY  '+
         '; '


		EXEC(@SQL);

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;
  		INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
		VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name   + '-'+@PART_TYPE_CD  , @ROWCOUNT_NO );


        SET @Proc_Step_no = @Proc_Step_no + 1;
		SET @Proc_Step_Name = ' GENERATING  UPDATE #tmp_DynDm_OrgPart_Table_temp';


        update #tmp_DynDm_OrgPart_Table_temp SET DETAIL ='<b></b>' + LTRIM(RTRIM(coalesce(ORGANIZATION_LOCAL_ID,''))) where LTRIM(RTRIM(ORGANIZATION_LOCAL_ID)) is not null ;
        update #tmp_DynDm_OrgPart_Table_temp SET  DETAIL = DETAIL  + '<br>'  +   (ORGANIZATION_NAME)  where LTRIM(RTRIM(ORGANIZATION_NAME)) is not null ;
        update #tmp_DynDm_OrgPart_Table_temp SET  DETAIL=  DETAIL  + '<br>'  +  LTRIM(RTRIM(ORGANIZATION_STREET_ADDRESS_1))  where LTRIM(RTRIM(ORGANIZATION_STREET_ADDRESS_1)) is not null ;
        update #tmp_DynDm_OrgPart_Table_temp SET  DETAIL=  DETAIL  + '<br>'  +  LTRIM(RTRIM(ORGANIZATION_STREET_ADDRESS_2))  where LTRIM(RTRIM(ORGANIZATION_STREET_ADDRESS_2)) is not null ;
        update #tmp_DynDm_OrgPart_Table_temp SET  DETAIL=  DETAIL  + '<br>'  +  LTRIM(RTRIM(CITY_STATE_ZIP))  where LTRIM(RTRIM(CITY_STATE_ZIP)) is not null ;
        update #tmp_DynDm_OrgPart_Table_temp SET  DETAIL=  DETAIL  + '<br>'  +  LTRIM(RTRIM(ORGANIZATION_COUNTY))  where LTRIM(RTRIM(ORGANIZATION_COUNTY)) is not null ;
        update #tmp_DynDm_OrgPart_Table_temp SET  DETAIL=  DETAIL  + '<br>'  +  LTRIM(RTRIM(ORGANIZATION_PHONE_WORK))  where LTRIM(RTRIM(ORGANIZATION_PHONE_WORK)) is not null ;
        update #tmp_DynDm_OrgPart_Table_temp SET  DETAIL= DETAIL +  ', ext. '  +  LTRIM(  RTRIM(ORGANIZATION_PHONE_EXT_WORK))
            where  LTRIM(RTRIM(ORGANIZATION_PHONE_WORK)) is not null  and LTRIM(RTRIM(ORGANIZATION_PHONE_EXT_WORK)) is not null ;
        update #tmp_DynDm_OrgPart_Table_temp SET  DETAIL= DETAIL +  '<br> ext. '  +  LTRIM(  RTRIM(ORGANIZATION_PHONE_EXT_WORK))
            where  LTRIM(RTRIM(ORGANIZATION_PHONE_WORK)) is  null  and LTRIM(RTRIM(ORGANIZATION_PHONE_EXT_WORK)) is not null ;
        update #tmp_DynDm_OrgPart_Table_temp SET  DETAIL= DETAIL +  '<br> '  where   LTRIM(RTRIM(DETAIL)) is not null ;


		SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
		VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name +'-'+ @PART_TYPE_CD  , @ROWCOUNT_NO );


        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' Executing ALTER on #tmp_DynDm_OrgPart_Table_temp and '+@tmp_DynDm_ORGANIZATION;


		SET @SQL =  'alter table #tmp_DynDm_OrgPart_Table_temp add  ' +  @DETAIL  + ' [varchar](2000) , ' +  @USER_DEFINED_COLUMN_NM+ ' bigint , '  +  @QEC+ ' [varchar](50) , ' +  @UID+ ' bigint ; '

		EXEC(@SQL);

        SET @SQL =  'alter table '+@tmp_DynDm_ORGANIZATION+' add  ' +  @DETAIL  + ' [varchar](2000) , ' +  @USER_DEFINED_COLUMN_NM+ ' bigint , '  +  @QEC+ ' [varchar](50) , ' +  @UID+ ' bigint ; '

		EXEC(@SQL);



		SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
		VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name + ' - '+@PART_TYPE_CD  , @ROWCOUNT_NO  );



		SET @Proc_Step_no = @Proc_Step_no + 1;
		SET @Proc_Step_Name = ' Executing  UPDATE on '+@tmp_DynDm_ORGANIZATION;



        SET @SQL =  'update tDO SET  ORGANIZATION_UID = orgtemp.ORGANIZATION_UID ,'
                  +  @DETAIL  + ' = DETAIL , '
                  +  @USER_DEFINED_COLUMN_NM+ ' =  ORGANIZATION_KEY , '
                  +  @QEC+ ' = ORGANIZATION_QUICK_CODE , '
                  +  @UID+ ' = orgtemp.ORGANIZATION_UID '
                  +  ' FROM '+@tmp_DynDm_ORGANIZATION+'  tDO '
                  +  ' INNER JOIN #tmp_DynDm_OrgPart_Table_temp orgtemp  ON  tDO.investigation_key = orgtemp.investigation_key '
                  + ' ; '


		EXEC(@SQL);

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;
  		INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
		VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name +'-'+ @PART_TYPE_CD  , @ROWCOUNT_NO );


        FETCH NEXT FROM db_cursor_org INTO @PART_TYPE_CD ,@USER_DEFINED_COLUMN_NM,@DETAIL ,@QEC ,@UID

    END

    CLOSE db_cursor_org
    DEALLOCATE db_cursor_org
    ;


    SET @Proc_Step_no = @Proc_Step_no + 1;
    SET @Proc_Step_Name = 'SP_COMPLETE';

	SELECT @ROWCOUNT_NO = @@ROWCOUNT;
  	INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
	VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name  , @ROWCOUNT_NO );


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