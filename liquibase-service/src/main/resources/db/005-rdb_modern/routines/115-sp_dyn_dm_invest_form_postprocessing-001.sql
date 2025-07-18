IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_dyn_dm_invest_form_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_dyn_dm_invest_form_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].sp_dyn_dm_invest_form_postprocessing
    @batch_id BIGINT,
    @DATAMART_NAME VARCHAR(100),
    @phc_id_list nvarchar(max),
    @debug bit = 'false'
AS
BEGIN
    BEGIN TRY

        /**
         * OUTPUT TABLES:
         * tmp_DynDm_INV_SUMM_DATAMART_<DATAMART_NAME>_<batch_id>
         * tmp_DynDm_Patient_Data_<DATAMART_NAME>_<batch_id>
         * tmp_DynDm_Investigation_Data_<DATAMART_NAME>_<batch_id>
         * */

        DECLARE @RowCount_no INT ;
        DECLARE @Proc_Step_no FLOAT = 0 ;
        DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
        DECLARE @nbs_page_form_cd VARCHAR(200) = '';

        DECLARE @Dataflow_Name VARCHAR(200)='DYNAMIC_DATAMART POST-Processing';
        DECLARE @Package_Name VARCHAR(200)='sp_dyn_dm_invest_form_postprocessing '+@DATAMART_NAME;

        DECLARE @tmp_DynDm_INV_SUMM_DATAMART VARCHAR(200) = 'dbo.tmp_DynDm_INV_SUMM_DATAMART_'+@DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));
        DECLARE @tmp_DynDm_PATIENT_DATA VARCHAR(200) = 'dbo.tmp_DynDm_Patient_Data_'+@DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));
        DECLARE @tmp_DynDm_INVESTIGATION_DATA VARCHAR(200) = 'dbo.tmp_DynDm_Investigation_Data_'+@DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));
        DECLARE @tmp_DynDm_INACTIVE_INVESTIGATIONS VARCHAR(200) = 'dbo.tmp_DynDm_Inactive_Investigations_'+@DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));

        DECLARE @temp_sql nvarchar(max);

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';

        INSERT INTO dbo.job_flow_log (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
        VALUES (@batch_id,@Dataflow_Name,@Package_Name,'START',@Proc_Step_no,@Proc_Step_Name,0);

-------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING #tmp_DynDm_SUMM_DATAMART';

        SET @nbs_page_form_cd = (SELECT FORM_CD FROM dbo.v_nrt_nbs_page WHERE DATAMART_NM=@DATAMART_NAME)

        SELECT
            isd.PATIENT_KEY AS PATIENT_KEY,
            isd.INVESTIGATION_KEY,
            c.DISEASE_GRP_CD
        into
            #tmp_DynDm_SUMM_DATAMART
        FROM
            dbo.INV_SUMM_DATAMART isd with (nolock)
                INNER JOIN
            dbo.condition c with (nolock)  ON   isd.DISEASE_CD = c.CONDITION_CD and c.DISEASE_GRP_CD = @nbs_page_form_cd
                INNER JOIN
            dbo.INVESTIGATION inv with (nolock) ON isd.investigation_key = inv.investigation_key
                and  inv.case_uid in (SELECT value FROM STRING_SPLIT(@phc_id_list, ','));

        if @debug = 'true'
            select * from #tmp_DynDm_SUMM_DATAMART;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

-------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING  '+ @tmp_DynDm_INACTIVE_INVESTIGATIONS;



        IF OBJECT_ID(@tmp_DynDm_INACTIVE_INVESTIGATIONS, 'U') IS NOT NULL
            exec ('drop table '+ @tmp_DynDm_INACTIVE_INVESTIGATIONS);

        /*
            The following if statement is here to prevent syntax errors when @phc_id_list
            is an empty string. In the future, if we are to update the schemas of the 
            dynamic datamarts based only on metadata changes, then we will need to be able
            to run the procedures without a list of phc uids.
        */
        if len(@phc_id_list) > 1
            BEGIN
                SET @temp_sql = '
                SELECT  inv.INVESTIGATION_KEY 
                into '+@tmp_DynDm_INACTIVE_INVESTIGATIONS+' 
                FROM 
                    dbo.INVESTIGATION inv with ( nolock) 
                WHERE inv.RECORD_STATUS_CD = ''INACTIVE'' AND inv.CASE_UID IN (' + @phc_id_list + ') ';


            if @debug = 'true'
            select @temp_sql;

            exec sp_executesql @temp_sql;

            if @debug = 'true'
                exec('select * from '+@tmp_DynDm_INACTIVE_INVESTIGATIONS);
            END



        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name  ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

-------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING  '+ @tmp_DynDm_INVESTIGATION_DATA;


        DECLARE @listStr VARCHAR(MAX);

        SELECT @listStr = COALESCE(@listStr+',' ,'') + RDB_COLUMN_NM  + ' '+ coalesce(USER_DEFINED_COLUMN_NM,'')
        FROM  dbo.V_NRT_NBS_INVESTIGATION_RDB_TABLE_METADATA 
        WHERE INVESTIGATION_FORM_CD = @nbs_page_form_cd;

        if @debug = 'true'
            select @listStr;

        IF OBJECT_ID(@tmp_DynDm_INVESTIGATION_DATA, 'U') IS NOT NULL
            exec ('drop table '+ @tmp_DynDm_INVESTIGATION_DATA);


        if len(@listStr) > 1
            begin
                SET @temp_sql = '
                SELECT  isd.INVESTIGATION_KEY, '+@listStr+'
                into '+@tmp_DynDm_INVESTIGATION_DATA+'
                FROM
                    dbo.INVESTIGATION inv with ( nolock)
                INNER JOIN
                    #tmp_DynDm_SUMM_DATAMART isd ON	isd.INVESTIGATION_KEY  =inv.INVESTIGATION_KEY'
               ;
            end
        else
            begin
                SET @temp_sql = '
                SELECT  isd.INVESTIGATION_KEY
                into '+@tmp_DynDm_INVESTIGATION_DATA+'
                FROM
                    dbo.INVESTIGATION inv with ( nolock)
                INNER JOIN
                    #tmp_DynDm_SUMM_DATAMART isd ON	isd.INVESTIGATION_KEY  =inv.INVESTIGATION_KEY'
                ;
            end


        if @debug = 'true'
            select @temp_sql;

        exec sp_executesql @temp_sql;

        if @debug = 'true'
            exec('select * from '+@tmp_DynDm_INVESTIGATION_DATA);


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name  ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

-------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING #tmp_DynDm_INV_SUMM_DATAMART';

        IF OBJECT_ID(@tmp_DynDm_INV_SUMM_DATAMART, 'U') IS NOT NULL
            exec ('drop table '+@tmp_DynDm_INV_SUMM_DATAMART);


        SET @temp_sql = '
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
	INTO
		' +@tmp_DynDm_INV_SUMM_DATAMART+'
	FROM
		dbo.INV_SUMM_DATAMART with ( nolock)
	INNER JOIN
		'+@tmp_DynDm_INVESTIGATION_DATA+' d ON d.INVESTIGATION_KEY = INV_SUMM_DATAMART.INVESTIGATION_KEY';

        exec sp_executesql @temp_sql;

        if @debug = 'true'
            exec('select * from '+@tmp_DynDm_INV_SUMM_DATAMART);


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name  ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

-------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING '+@tmp_DynDm_PATIENT_DATA;


        SET  @listStr = null;

        SELECT @listStr = COALESCE(@listStr+',' ,'') + RDB_COLUMN_NM  + ' '+ coalesce(USER_DEFINED_COLUMN_NM,'')
        FROM  dbo.V_NRT_NBS_D_PATIENT_RDB_TABLE_METADATA
        WHERE INVESTIGATION_FORM_CD = @nbs_page_form_cd;

        if @debug = 'true'
            select @listStr;

        IF OBJECT_ID(@tmp_DynDm_PATIENT_DATA, 'U') IS NOT NULL
            exec ('drop table '+@tmp_DynDm_PATIENT_DATA);

        if len(@listStr) > 1
            begin
                SET @temp_sql = '
                SELECT isd.INVESTIGATION_KEY, '+@listStr+'
                into '+@tmp_DynDm_PATIENT_DATA+'
                FROM
                    dbo.D_PATIENT pat with ( nolock)
                INNER JOIN
                    #tmp_DynDm_SUMM_DATAMART isd ON 	pat.PATIENT_KEY = isd.PATIENT_KEY';
            end
        else
            begin
                SET @temp_sql = '
                SELECT  isd.INVESTIGATION_KEY
                into '+@tmp_DynDm_PATIENT_DATA+'
                FROM
                    dbo.D_PATIENT pat with ( nolock)
                INNER JOIN
                    #tmp_DynDm_SUMM_DATAMART isd ON 	pat.PATIENT_KEY = isd.PATIENT_KEY';
            end


        if @debug = 'true'
            select @temp_sql;

        exec sp_executesql @temp_sql;


        if @debug = 'true'
            exec('select * from '+@tmp_DynDm_PATIENT_DATA);

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

-------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'SP_COMPLETE';


        INSERT INTO dbo.job_flow_log (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
        VALUES(@batch_id,@Dataflow_Name,@Package_Name,'COMPLETE',@Proc_Step_no,@Proc_Step_name,@RowCount_no);

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

END;