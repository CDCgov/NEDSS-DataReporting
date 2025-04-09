CREATE OR ALTER PROCEDURE dbo.sp_dyn_dm_case_management_postprocessing
    @batch_id BIGINT,
    @DATAMART_NAME VARCHAR(100),
    @phc_id_list nvarchar(max),
    @debug bit = 'false'

AS
BEGIN
    BEGIN TRY

        /**
         * OUTPUT TABLES:
         * tmp_DynDm_Case_Management_Data_<DATAMART_NAME>_<batch_id>
         * */

        DECLARE @RowCount_no INT ;
        DECLARE @Proc_Step_no FLOAT = 0 ;
        DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
        DECLARE @nbs_page_form_cd VARCHAR(200) = '';

        DECLARE @Dataflow_Name VARCHAR(200)='DYNAMIC_DATAMART POST-Processing';
        DECLARE @Package_Name VARCHAR(200)='DynDM_Manage_Case_Management '+@DATAMART_NAME;

        DECLARE @tmp_DynDm_CASE_MANAGEMENT_DATA varchar(200) = 'dbo.tmp_DynDm_Case_Management_Data_'+@DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));

        DECLARE @temp_sql nvarchar(max);


        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';

        INSERT INTO dbo.job_flow_log (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
        VALUES (@batch_id,@Dataflow_Name,@Package_Name,'START',@Proc_Step_no,@Proc_Step_Name,0);

-------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING #tmp_DynDm_SUMM_DATAMART';

        SET @nbs_page_form_cd = (SELECT FORM_CD FROM dbo.V_NRT_NBS_PAGE WHERE DATAMART_NM=@DATAMART_NAME);

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


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

-------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING '+@tmp_DynDm_CASE_MANAGEMENT_DATA;

        DECLARE @listStr VARCHAR(MAX) = null;

        SELECT @listStr = COALESCE(@listStr+',' ,'') +  RDB_COLUMN_NM  + ' '+ coalesce(USER_DEFINED_COLUMN_NM,'')
        FROM  dbo.V_NRT_NBS_D_CASE_MGMT_RDB_TABLE_METADATA with (nolock) where INVESTIGATION_FORM_CD = @nbs_page_form_cd;

        IF OBJECT_ID(@tmp_DynDm_CASE_MANAGEMENT_DATA, 'U') IS NOT NULL
            exec ('drop table '+@tmp_DynDm_CASE_MANAGEMENT_DATA);

        if len(@listStr) > 1
            begin
                SET @temp_sql = '
            SELECT
                isd.INVESTIGATION_KEY ,rdb_column_nm_list
            INTO
                '+ @tmp_DynDm_CASE_MANAGEMENT_DATA +'
            FROM
                #tmp_DynDM_SUMM_DATAMART isd
            INNER JOIN
                dbo.V_NRT_NBS_D_CASE_MGMT_RDB_TABLE_METADATA case_mgmt_meta on  case_mgmt_meta.INVESTIGATION_FORM_CD = isd.DISEASE_GRP_CD
            LEFT JOIN
                dbo.D_CASE_MANAGEMENT case_mgmt ON isd.INVESTIGATION_KEY = case_mgmt.INVESTIGATION_KEY
            WHERE  case_mgmt.INVESTIGATION_KEY>1' ;
            end
        else
            begin
                SET @temp_sql = '
            SELECT
                isd.INVESTIGATION_KEY
            INTO
                '+ @tmp_DynDm_CASE_MANAGEMENT_DATA +'
            FROM
                #tmp_DynDM_SUMM_DATAMART isd
            INNER JOIN
                dbo.V_NRT_NBS_D_CASE_MGMT_RDB_TABLE_METADATA case_mgmt_meta on  case_mgmt_meta.INVESTIGATION_FORM_CD = isd.DISEASE_GRP_CD
            LEFT JOIN
                dbo.D_CASE_MANAGEMENT case_mgmt ON isd.INVESTIGATION_KEY = case_mgmt.INVESTIGATION_KEY
            WHERE  case_mgmt.INVESTIGATION_KEY>1' ;
            end

        exec sp_executesql @temp_sql;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );

-------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'SP_COMPLETE';

        INSERT INTO dbo.job_flow_log (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
        VALUES(@batch_id,@Dataflow_Name,@Package_Name,'COMPLETE',@Proc_Step_no,@Proc_Step_name,@RowCount_no);


    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0   COMMIT TRANSACTION;

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