IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_dyn_dm_provider_data_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_dyn_dm_provider_data_postprocessing]
END
GO 

CREATE PROCEDURE dbo.sp_dyn_dm_provider_data_postprocessing
    @batch_id BIGINT,
    @DATAMART_NAME VARCHAR(100), @phc_id_list nvarchar(max),
    @debug bit = false
AS
BEGIN
    BEGIN TRY

        /**
    	 * OUTPUT TABLES:
    	 * tmp_DynDm_PROVIDER_<DATAMART_NAME>_<batch_id>
    	 * */

        DECLARE @RowCount_no INT = 0 ;
        DECLARE @Proc_Step_no FLOAT = 0 ;
        DECLARE @Proc_Step_Name VARCHAR(200) = '' ;

        DECLARE @nbs_page_form_cd varchar(200)=''
        DECLARE @Dataflow_Name varchar(200) = 'DYNAMIC_DATAMART POST-Processing';
        DECLARE @Package_Name varchar(200) = 'sp_dyn_dm_provider_data_postprocessing: '+@DATAMART_NAME;

        DECLARE @tmp_DynDm_PROVIDER varchar(200) = 'dbo.tmp_DynDm_PROVIDER_'+@DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));

        DECLARE @temp_sql nvarchar(max);
        SET @nbs_page_form_cd = (SELECT FORM_CD FROM dbo.V_NRT_NBS_PAGE WHERE DATAMART_NM=@DATAMART_NAME);


        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';

        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );

---------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING  FACT_CASE';


        declare @countstd int = 0;

        select  @countstd = count(*) from dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata case_meta
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
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );

---------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING  tmp_DynDm_Provider_Metadata';


        IF OBJECT_ID('tempdb..#tmp_DynDm_Provider_Metadata', 'U') IS NOT NULL
            drop table #tmp_DynDm_Provider_Metadata;

        select DISTINCT RDB_COLUMN_NM, user_defined_column_nm, part_type_cd ,
                        [Key],Detail, QEC, [UID]
        into #tmp_DynDm_Provider_Metadata
        from dbo.v_nrt_d_provider_rdb_table_metadata  WHERE INVESTIGATION_FORM_CD  =  @nbs_page_form_cd;

        IF @debug = 'true' SELECT @Proc_Step_Name AS step, * FROM #tmp_DynDm_Provider_Metadata;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );

---------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING '+@tmp_DynDm_PROVIDER;

        IF OBJECT_ID(@tmp_DynDm_PROVIDER, 'U') IS NOT NULL
            exec ('drop table ' +@tmp_DynDm_PROVIDER);

        SELECT isd.PATIENT_KEY AS PATIENT_KEY, isd.INVESTIGATION_KEY, c.DISEASE_GRP_CD
        into #tmp_DynDm_SUMM_DATAMART
        FROM dbo.INV_SUMM_DATAMART isd with ( nolock)
                 INNER JOIN dbo.condition c with ( nolock)  ON   isd.DISEASE_CD = c.CONDITION_CD and c.DISEASE_GRP_CD = @nbs_page_form_cd
                 INNER JOIN dbo.INVESTIGATION I with (nolock) ON isd.investigation_key = I.investigation_key
            and  I.case_uid in (SELECT value FROM STRING_SPLIT(@phc_id_list, ','));

        IF @debug = 'true' SELECT @Proc_Step_Name AS step, * FROM #tmp_DynDm_SUMM_DATAMART;

        SET @temp_sql = '
		select distinct investigation_key,
		cast( null as  [varchar](50)) [PROVIDER_LOCAL_ID],
		cast( null as  bigint) [PROVIDER_UID]
		into '+@tmp_DynDm_PROVIDER+'
		 FROM #tmp_DynDm_SUMM_DATAMART'
        -- pass the prv_Id_List  param
        ;
        exec sp_executesql @temp_sql;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );


        declare  @USER_DEFINED_COLUMN_NM varchar(max) ,@PART_TYPE_CD  varchar(max) ,@DETAIL  varchar(max) ,@QEC  varchar(max) ,@UID varchar(max);

        declare @SQL varchar(max)


--declare @PART_TYPE_CD varchar(max) = null , @SQL varchar(max);


        DECLARE db_cursor_org CURSOR  LOCAL FOR
            select PART_TYPE_CD , [key],DETAIL,QEC ,[UID] from #tmp_DynDm_Provider_Metadata;

        OPEN db_cursor_org
        FETCH NEXT FROM db_cursor_org INTO @PART_TYPE_CD ,@USER_DEFINED_COLUMN_NM,@DETAIL ,@QEC ,@UID

        WHILE @@FETCH_STATUS = 0
            BEGIN

                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = ' GENERATING  #tmp_DynDm_ProvPart_Table_temp';


                IF OBJECT_ID('tempdb..#tmp_DynDm_ProvPart_Table_temp', 'U') IS NOT NULL
                    drop table #tmp_DynDm_ProvPart_Table_temp;


                CREATE TABLE #tmp_DynDm_ProvPart_Table_temp(
                                                               [PROVIDER_KEY] [bigint] NULL,
                                                               [PROVIDER_QUICK_CODE] [varchar](50) NULL,
                                                               [PROVIDER_LOCAL_ID] [varchar](50) NULL,
                                                               [PROVIDER_UID] [bigint] NULL,
                                                               [PROVIDER_FIRST_NAME] [varchar](50) NULL,
                                                               [PROVIDER_MIDDLE_NAME] [varchar](50) NULL,
                                                               [PROVIDER_LAST_NAME] [varchar](50) NULL,
                                                               [PROVIDER_NAME_SUFFIX] [varchar](50) NULL,
                                                               [PROVIDER_NAME_DEGREE] [varchar](50) NULL,
                                                               [PROVIDER_STREET_ADDRESS_1] [varchar](50) NULL,
                                                               [PROVIDER_STREET_ADDRESS_2] [varchar](50) NULL,
                                                               [PROVIDER_CITY] [varchar](50) NULL,
                                                               [PROVIDER_STATE] [varchar](50) NULL,
                                                               [PROVIDER_ZIP] [varchar](50) NULL,
                                                               [PROVIDER_COUNTY] [varchar](50) NULL,
                                                               [PROVIDER_PHONE_WORK] [varchar](50) NULL,
                                                               [PROVIDER_PHONE_EXT_WORK] [varchar](50) NULL,
                                                               [PROVIDER_EMAIL_WORK] [varchar](50) NULL,
                                                               [PART_TYPE_CD] [bigint] NULL,
                                                               [PART_TYPE_CD_NM] [varchar](200) NOT NULL,
                                                               [CITY_STATE_ZIP] [varchar](4000) NULL,
                                                               [PROVIDER_NAME] [varchar](5000) NULL,
                                                               [DETAIL] varchar(2000),
                                                               [INVESTIGATION_KEY] [bigint] NOT NULL
                );


                SET @SQL = 	'  insert into  #tmp_DynDm_ProvPart_Table_temp SELECT  d_p.PROVIDER_KEY, ' +
                              ' d_p.PROVIDER_QUICK_CODE, ' +
                              ' d_p.PROVIDER_LOCAL_ID, ' +
                              ' d_p.PROVIDER_UID, ' +
                              ' d_p.PROVIDER_FIRST_NAME, ' +
                              ' d_p.PROVIDER_MIDDLE_NAME, ' +
                              ' d_p.PROVIDER_LAST_NAME, ' +
                              ' d_p.PROVIDER_NAME_SUFFIX, ' +
                              ' d_p.PROVIDER_NAME_DEGREE, ' +
                              ' d_p.PROVIDER_STREET_ADDRESS_1, ' +
                              ' d_p.PROVIDER_STREET_ADDRESS_2, ' +
                              ' d_p.PROVIDER_CITY, ' +' d_p.PROVIDER_STATE, ' + ' d_p.PROVIDER_ZIP, ' +
                              ' d_p.PROVIDER_COUNTY, ' +
                              ' d_p.PROVIDER_PHONE_WORK, ' +
                              ' d_p.PROVIDER_PHONE_EXT_WORK, ' +
                              '  PROVIDER_EMAIL_WORK, ' +
                              @PART_TYPE_CD +', ' +
                              ''''+   @PART_TYPE_CD +''', '+
                              '   coalesce( ltrim(rtrim(PROVIDER_CITY))+'', '','''')+coalesce( ltrim(rtrim(PROVIDER_STATE))+'' '','''')+coalesce( ltrim(rtrim(PROVIDER_ZIP)),'''') '  + ','+
                              ' null ,'+
                              ' null ,'+
                              '   s_d.INVESTIGATION_KEY AS INVESTIGATION_KEY ' +
                              ' FROM #tmp_DynDm_SUMM_DATAMART s_d '+
                              ' INNER JOIN dbo.'+@FACT_CASE+ '   ON s_d.INVESTIGATION_KEY =  '+@FACT_CASE+ '.INVESTIGATION_KEY '+
                              ' LEFT JOIN dbo.D_PROVIDER  d_p ON '+@FACT_CASE+'.'+@PART_TYPE_CD+' = d_p.PROVIDER_KEY  '+
                              '; '


                IF @debug = 'true'  PRINT @SQL;

                IF @debug = 'true' SELECT @Proc_Step_Name AS step, * FROM #tmp_DynDm_ProvPart_Table_temp;

                EXEC(@SQL);


                SELECT @ROWCOUNT_NO = @@ROWCOUNT;
                INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
                VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no , @Proc_Step_Name  +'-'+ @PART_TYPE_CD  , @ROWCOUNT_NO );



                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = ' GENERATING  UPDATE tmp_DynDm_ProvPart_Table_temp';


                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   PROVIDER_NAME = LTRIM(  RTRIM(coalesce(PROVIDER_FIRST_NAME,'')) ) 	 ;
                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   PROVIDER_NAME = LTRIM(  RTRIM(PROVIDER_NAME))  + ' ' +  LTRIM(RTRIM(PROVIDER_MIDDLE_NAME))  WHERE   LEN(LTRIM(RTRIM(PROVIDER_MIDDLE_NAME )))>0 	 ;
                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   PROVIDER_NAME = LTRIM(  RTRIM(PROVIDER_NAME))  + ' ' +  LTRIM(RTRIM(PROVIDER_LAST_NAME))  WHERE   LEN(LTRIM(RTRIM(PROVIDER_LAST_NAME )))>0 	 ;
                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   PROVIDER_NAME = LTRIM(  RTRIM(PROVIDER_NAME))  + ', ' +  LTRIM(RTRIM(PROVIDER_NAME_SUFFIX))  WHERE LEN(LTRIM(RTRIM(PROVIDER_NAME_SUFFIX )))>0 	 ;
                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   PROVIDER_NAME = LTRIM(  RTRIM(PROVIDER_NAME))  + ', ' +  LTRIM(RTRIM(PROVIDER_NAME_DEGREE))  WHERE    LEN(LTRIM(RTRIM(PROVIDER_NAME_DEGREE )))>0  	 ;

                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   PROVIDER_NAME = null where LTRIM(  RTRIM(PROVIDER_NAME)) = '';


                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   DETAIL  ='<b></b>'  + RTRIM(PROVIDER_LOCAL_ID)  WHERE   LEN(LTRIM(RTRIM(PROVIDER_LOCAL_ID)))>0 	 ;
                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL))  + '<br>'  +  PROVIDER_NAME	 WHERE  LEN(LTRIM(RTRIM(PROVIDER_NAME)))>0 	 ;
                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   DETAIL = LTRIM(RTRIM(DETAIL))  + '<br>'  +  LTRIM(RTRIM(PROVIDER_STREET_ADDRESS_1))  WHERE   LEN(LTRIM(RTRIM(PROVIDER_STREET_ADDRESS_1)))>0 	 ;
                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   DETAIL = LTRIM(RTRIM(DETAIL))  +  '<br>'  +  LTRIM(RTRIM(PROVIDER_STREET_ADDRESS_2)) 	 WHERE  LEN(LTRIM(RTRIM(PROVIDER_STREET_ADDRESS_2)))>0 	 ;
                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL)) +  '<br>'  +  LTRIM(  RTRIM(CITY_STATE_ZIP)) 	 WHERE  LEN(LTRIM(RTRIM(CITY_STATE_ZIP)))>0 	 ;
                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL)) +  '<br>'  +  LTRIM(RTRIM(PROVIDER_COUNTY)) WHERE  LEN(LTRIM(RTRIM(PROVIDER_COUNTY)))>0 	 ;
                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL)) +  '<br>'  +  LTRIM(  RTRIM(PROVIDER_PHONE_WORK)) 	 WHERE  LEN(LTRIM(RTRIM(PROVIDER_PHONE_WORK)))>0 	 ;
                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL)) +  ', ext. '  +  LTRIM(  RTRIM(PROVIDER_PHONE_EXT_WORK)) 	 WHERE  LEN(LTRIM(RTRIM(PROVIDER_PHONE_WORK)))>0 and LEN(LTRIM(RTRIM(PROVIDER_PHONE_EXT_WORK)))>0 	 ;
                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL)) +  '<br> ext. '  +  LTRIM(  RTRIM(PROVIDER_PHONE_EXT_WORK)) 	 WHERE  LEN(LTRIM(RTRIM(PROVIDER_PHONE_WORK)))=0 and LEN(LTRIM(RTRIM(PROVIDER_PHONE_EXT_WORK)))>0 	 ;
                UPDATE #tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL)) +  '<br>' 	 WHERE  LEN(LTRIM(RTRIM(DETAIL )))>0 	 ;


                SELECT @ROWCOUNT_NO = @@ROWCOUNT;
                INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
                VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no , @Proc_Step_Name  +'-'+ @PART_TYPE_CD  , @ROWCOUNT_NO );



                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = ' Executing ALTER on #tmp_DynDm_ProvPart_Table_temp and '+@tmp_DynDm_PROVIDER;


                SET @SQL =  'alter table #tmp_DynDm_ProvPart_Table_temp add  ' +  @DETAIL  + ' [varchar](2000) , ' +  @USER_DEFINED_COLUMN_NM+ ' bigint , '  +  @QEC+ ' [varchar](50) , ' +  @UID+ ' bigint ; ';
                EXEC(@SQL);


                SET @SQL =  'alter table '+@tmp_DynDm_PROVIDER+' add   ' +  @DETAIL  + ' [varchar](2000) , ' +  @USER_DEFINED_COLUMN_NM+ ' bigint , '  +  @QEC+ ' [varchar](50) , ' +  @UID+ ' bigint ; ';
                EXEC(@SQL);


                SELECT @ROWCOUNT_NO = @@ROWCOUNT;
                INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
                VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no , @Proc_Step_Name  +'-'+ @PART_TYPE_CD  , @ROWCOUNT_NO );



                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = ' Executing UPDATE on '+@tmp_DynDm_PROVIDER;


                SET @SQL =  'update tDO SET '
                    +  ' PROVIDER_LOCAL_ID = orgtemp.PROVIDER_LOCAL_ID ,'
                    +  ' PROVIDER_UID = orgtemp.PROVIDER_UID ,'
                    +  @DETAIL  + ' = DETAIL , '
                    +  @USER_DEFINED_COLUMN_NM+ ' =  PROVIDER_KEY , '
                    +  @QEC+ ' = PROVIDER_QUICK_CODE , '
                    +  @UID+ ' = orgtemp.PROVIDER_UID '
                    +  ' FROM '+@tmp_DynDm_PROVIDER+'  tDO '
                    +  ' INNER JOIN #tmp_DynDm_ProvPart_Table_temp orgtemp  ON  tDO.investigation_key = orgtemp.investigation_key '
                    + ' ; '


                EXEC(@SQL);

                SELECT @ROWCOUNT_NO = @@ROWCOUNT;
                INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
                VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no , @Proc_Step_Name  +'-'+ @PART_TYPE_CD  , @ROWCOUNT_NO );


                FETCH NEXT FROM db_cursor_org INTO @PART_TYPE_CD ,@USER_DEFINED_COLUMN_NM,@DETAIL ,@QEC ,@UID

            END

        CLOSE db_cursor_org;
        DEALLOCATE db_cursor_org
        ;



        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'SP COMPLETE';


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );



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