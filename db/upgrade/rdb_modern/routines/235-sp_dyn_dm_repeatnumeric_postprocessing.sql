CREATE OR ALTER PROCEDURE [dbo].sp_dyn_dm_repeatnumeric_postprocessing

    @batch_id BIGINT,
    @DATAMART_NAME VARCHAR(100),
    @phc_id_list nvarchar(max),
    @debug bit = 'false'

AS
BEGIN

    BEGIN TRY

        DECLARE @RowCount_no INT ;
        DECLARE @Proc_Step_no FLOAT = 0 ;
        DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
        --DECLARE @DATAMART_NAME VARCHAR = 'GENERIC_V2';
        DECLARE @Dataflow_Name VARCHAR(100) = 'DYNAMIC_DATAMART POST PROCESSING' ;
        DECLARE @package_Name VARCHAR(100) = 'sp_dyn_dm_repeatnumeric_postprocessing: '+ @DATAMART_NAME;

        DECLARE @nbs_page_form_cd varchar(200)='';
        SET @nbs_page_form_cd = (SELECT top 1 FORM_CD FROM dbo.v_nrt_nbs_page WHERE DATAMART_NM=@DATAMART_NAME) -- check multiple data name.

        IF @debug = 'true'
            BEGIN
                SELECT '@nbs_page_form_cd:', @nbs_page_form_cd;

                -- Check if any records match in the view with this form code
                SELECT 'View records that match form code:', COUNT(*)
                FROM dbo.V_NRT_NBS_REPEATNUMERIC_RDB_TABLE_METADATA
                WHERE INVESTIGATION_FORM_CD = @nbs_page_form_cd;

                -- Check actual records in the view for these investigations
                SELECT TOP 10 'First 10 rows from view:', *
                FROM dbo.V_NRT_NBS_REPEATNUMERIC_RDB_TABLE_METADATA;
            END

        --primary tables used in the main proc
        DECLARE @tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC varchar(500) = '[dbo].tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC_'+ @DATAMART_NAME +'_'+ cast(@batch_id as varchar);
        DECLARE @tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL varchar(500) = '[dbo].tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL_'+ @DATAMART_NAME +'_'+ cast(@batch_id as varchar);

        --temporary table used only in this proc
        DECLARE @tmp_DynDm_REPEAT_BLOCK varchar(500) = '[dbo].tmp_DynDm_REPEAT_BLOCK_'+ @DATAMART_NAME +'_'+ cast(@batch_id as varchar);

        DECLARE @ddl_sql_invreptnum nvarchar(800) = 'CREATE TABLE [dbo].tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC_'+ @DATAMART_NAME +'_'+ cast(@batch_id as varchar) +'(INVESTIGATION_KEY_REPEAT_NUMERIC [bigint] NULL)';
        DECLARE @ddl_sql_reptblknum nvarchar(800) = 'CREATE TABLE [dbo].tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL_'+ @DATAMART_NAME +'_'+ cast(@batch_id as varchar) +'(INVESTIGATION_KEY_REPEAT_BLOCK_NUMERIC_ALL [bigint] NULL)';

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';

        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count],[Msg_description1] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO,LEFT (@phc_id_list, 500)
               );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING tmp_DynDm_METADATA_INIT';

        SELECT distinct
            DATAMART_NM,
            RDB_COLUMN_NM,
            USER_DEFINED_COLUMN_NM,
            BLOCK_PIVOT_NBR,
            BLOCK_NM,
            data_type,
            code_set_group_id
        into #tmp_DynDm_METADATA_INIT
        FROM dbo.V_NRT_NBS_REPEATNUMERIC_RDB_TABLE_METADATA meta
        WHERE INVESTIGATION_FORM_CD = @nbs_page_form_cd
          and (code_set_group_id < 0
            OR data_type in ( 'Numeric','NUMERIC') )
        ORDER BY RDB_COLUMN_NM;

        if @debug = 'true'
            select @Proc_Step_Name,* from #tmp_DynDm_METADATA_INIT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING tmp_DynDm_METADATA_UNIT';

        SELECT distinct
            DATAMART_NM,
            substring(LTRIM(RTRIM(RDB_COLUMN_NM)),1,21)+'_UNIT' as RDB_COLUMN_NM,
            USER_DEFINED_COLUMN_NM +'_UNIT' as USER_DEFINED_COLUMN_NM,
            BLOCK_PIVOT_NBR,
            BLOCK_NM,
            MASK
        into #tmp_DynDm_METADATA_UNIT
        FROM dbo.V_NRT_NBS_REPEATNUMERIC_RDB_TABLE_METADATA meta
        WHERE INVESTIGATION_FORM_CD = @nbs_page_form_cd
          AND UNIT_TYPE_CD='CODED'
          AND MASK IS NOT NULL;

        if @debug = 'true'
            select @Proc_Step_Name,* from #tmp_DynDm_METADATA_UNIT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING tmp_DynDm_METADATA';

        select [DATAMART_NM]
             ,[BLOCK_PIVOT_NBR]
             ,[BLOCK_NM]
             ,[mask]
             ,[RDB_COLUMN_NM]
             ,[USER_DEFINED_COLUMN_NM]
             ,cast([USER_DEFINED_COLUMN_NM]+'_1' as varchar(200)) as USER_DEFINED_COLUMN_NM_1
             ,cast([USER_DEFINED_COLUMN_NM]+'_2' as varchar(200)) as USER_DEFINED_COLUMN_NM_2
             ,cast([USER_DEFINED_COLUMN_NM]+'_3' as varchar(200)) as USER_DEFINED_COLUMN_NM_3
             ,cast([USER_DEFINED_COLUMN_NM]+'_4' as varchar(200)) as USER_DEFINED_COLUMN_NM_4
             ,cast([USER_DEFINED_COLUMN_NM]+'_5' as varchar(200)) as USER_DEFINED_COLUMN_NM_5
        into #tmp_DynDm_METADATA
        FROM #tmp_DynDm_METADATA_UNIT
        union all
        select [DATAMART_NM]
             ,[BLOCK_PIVOT_NBR]
             ,[BLOCK_NM]
             ,null
             ,[RDB_COLUMN_NM]
             ,[USER_DEFINED_COLUMN_NM]
             ,cast([USER_DEFINED_COLUMN_NM]+'_1' as varchar(200)) as USER_DEFINED_COLUMN_NM_1
             ,cast([USER_DEFINED_COLUMN_NM]+'_2' as varchar(200)) as USER_DEFINED_COLUMN_NM_2
             ,cast([USER_DEFINED_COLUMN_NM]+'_3' as varchar(200)) as USER_DEFINED_COLUMN_NM_3
             ,cast([USER_DEFINED_COLUMN_NM]+'_4' as varchar(200)) as USER_DEFINED_COLUMN_NM_4
             ,cast([USER_DEFINED_COLUMN_NM]+'_5' as varchar(200)) as USER_DEFINED_COLUMN_NM_5
        FROM #tmp_DynDm_METADATA_INIT
        ;

--------------------------------------------------------------------------------------------------------------------------------------------

        declare @countmeta int = 0;

        select @countmeta = count(*) from #tmp_DynDm_Metadata;

        if @countmeta < 1
            begin

                select 'No repeat numeric metadata';

                exec(@ddl_sql_invreptnum);

                exec(@ddl_sql_reptblknum);

                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = 'SP_COMPLETE';

                SELECT @ROWCOUNT_NO = @@ROWCOUNT;
                INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
                VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

                return ;

            end;

--------------------------------------------------------------------------------------------------------------------------------------------

        update #tmp_DynDm_METADATA
        SET BLOCK_PIVOT_NBR=1 where BLOCK_PIVOT_NBR is null;

        update #tmp_DynDm_METADATA
        SET USER_DEFINED_COLUMN_NM_1 = '',
            USER_DEFINED_COLUMN_NM_2 = '',
            USER_DEFINED_COLUMN_NM_3 = '',
            USER_DEFINED_COLUMN_NM_4 = '',
            USER_DEFINED_COLUMN_NM_5 = ''
        where BLOCK_PIVOT_NBR = 0 ;

        update #tmp_DynDm_METADATA
        SET USER_DEFINED_COLUMN_NM_2 = '',
            USER_DEFINED_COLUMN_NM_3 = '',
            USER_DEFINED_COLUMN_NM_4 = '',
            USER_DEFINED_COLUMN_NM_5 = ''
        where BLOCK_PIVOT_NBR = 1 ;

        update #tmp_DynDm_METADATA
        SET USER_DEFINED_COLUMN_NM_3 = '',
            USER_DEFINED_COLUMN_NM_4 = '',
            USER_DEFINED_COLUMN_NM_5 = ''
        where BLOCK_PIVOT_NBR = 2 ;

        update #tmp_DynDm_METADATA
        SET USER_DEFINED_COLUMN_NM_4 = '',
            USER_DEFINED_COLUMN_NM_5 = ''
        where BLOCK_PIVOT_NBR = 3 ;

        update #tmp_DynDm_METADATA
        SET USER_DEFINED_COLUMN_NM_5 = ''
        where BLOCK_PIVOT_NBR = 4 ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING tmp_DynDm_METADATA_OUT';

        select
            rdb_column_nm
             ,block_nm
             ,variable as '_NAME_'
             ,value as 'COL1'
        into #tmp_DynDm_METADATA_OUT
        from (
                 select rdb_column_nm,block_nm, USER_DEFINED_COLUMN_NM_1 ,USER_DEFINED_COLUMN_NM_2 ,USER_DEFINED_COLUMN_NM_3,USER_DEFINED_COLUMN_NM_4,USER_DEFINED_COLUMN_NM_5
                 from #tmp_DynDm_METADATA
             ) as t
                 unpivot (
                 value for variable in ( USER_DEFINED_COLUMN_NM_1 ,USER_DEFINED_COLUMN_NM_2 ,USER_DEFINED_COLUMN_NM_3,USER_DEFINED_COLUMN_NM_4,USER_DEFINED_COLUMN_NM_5)
                 ) as unpvt
        ;

        if @debug = 'true'
            select 'tmp_DynDm_METADATA_OUT',* from #tmp_DynDm_METADATA_OUT;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING tmp_DynDm_METADATA_OUT_TMP';

        select
            RDB_COLUMN_NM,
            BLOCK_NM,
            _NAME_,
            COL1
        into
            #tmp_DynDm_METADATA_OUT_TMP
        FROM
            #tmp_DynDm_METADATA_OUT
        where
            COL1 is not NULL
          and LTRIM( RTRIM(COL1)) <> '';

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING tmp_DynDm_METADATA_OUT1';

        SELECT
            *
        into
            #tmp_DynDm_METADATA_OUT1
        FROM
            #tmp_DynDm_METADATA_OUT_TMP
        WHERE
            BLOCK_NM IS NOT NULL;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING tmp_DynDm_METADATA_OUT_final';

        SELECT
            DISTINCT mo.*,
                     mo1.BLOCK_NM AS BLOCK_NM1 ,
                     cast( null as int) as ANSWER_GROUP_SEQ_NBR
        into
            #tmp_DynDm_METADATA_OUT_final
        FROM
            #tmp_DynDm_METADATA_OUT_TMP mo
                INNER JOIN #tmp_DynDm_METADATA_OUT1 mo1 ON
                UPPER(mo1.RDB_COLUMN_NM) = UPPER(mo.RDB_COLUMN_NM);

        UPDATE
            #tmp_DynDm_METADATA_OUT_final
        SET
            ANSWER_GROUP_SEQ_NBR = CAST(RIGHT(COL1, 1) AS INT)
        where 1=1;

        if @debug = 'true'
            select * from #tmp_DynDm_METADATA_OUT_final;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name , @package_Name, 'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING tmp_DynDm_Case_Management_Metadata';

        declare @countSTD int = 0;

        SELECT
            DISTINCT FORM_CD,
                     DATAMART_NM,
                     RDB_TABLE_NM,
                     RDB_COLUMN_NM,
                     USER_DEFINED_COLUMN_NM ,
                     INVESTIGATION_FORM_CD
        into
            #tmp_DynDm_Case_Management_Metadata
        FROM
            dbo.V_NRT_NBS_D_CASE_MGMT_RDB_TABLE_METADATA case_meta
        where
            DATAMART_NM = @DATAMART_NAME
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name , @package_Name, 'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING Selecting Fact table';

        select @countSTD = count(*) from #tmp_DynDm_Case_Management_Metadata;
        declare @FACT_CASE varchar(40) = '';

        if @countSTD > 1
            begin
                set @FACT_CASE = 'F_STD_PAGE_CASE';
            end
        else
            begin
                set @FACT_CASE = 'F_PAGE_CASE';
            end
            ;

        if @debug = 'true'
            select @FACT_CASE;

        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,0 );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING tmp_DynDm_D_INV_REPEAT_METADATA';

        SELECT
            DISTINCT DATAMART_NM,
                     RDB_COLUMN_NM,
                     USER_DEFINED_COLUMN_NM,
                     BLOCK_PIVOT_NBR,
                     cast( null as varchar(400)) as RDB_COLUMN_NAME_LIST,
                     cast( null as varchar(400)) as RDB_COLUMN_LIST,
                     cast( null as varchar(400)) as RDB_COLUMN_COMMA_LIST
        into
            #tmp_DynDm_D_INV_REPEAT_METADATA
        FROM
            #tmp_DynDm_METADATA;

        update
            #tmp_DynDm_D_INV_REPEAT_METADATA
        set
            USER_DEFINED_COLUMN_NM = rtrim(RDB_COLUMN_NM)
        where
            USER_DEFINED_COLUMN_NM is null
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING #tmp_DynDm_DYNINVLISTING ';

        select
            distinct (RDB_COLUMN_NM + ' AS ' + USER_DEFINED_COLUMN_NM) as USER_DEFINED_COLUMN_NM
        into
            #tmp_DynDm_DYNINVLISTING
        from
            #tmp_DynDm_D_INV_REPEAT_METADATA
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

        DECLARE @RDB_COLUMN_NAME_LIST VARCHAR(MAX);
        SET @RDB_COLUMN_NAME_LIST =null;

        SELECT @RDB_COLUMN_NAME_LIST = COALESCE(@RDB_COLUMN_NAME_LIST+',' ,'') + USER_DEFINED_COLUMN_NM
        FROM #tmp_DynDm_DYNINVLISTING;

-------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING #tmp_DynDm_D_INV_REPEAT_METADATA_distinct ';

        select
            distinct RDB_COLUMN_NM
        into
            #tmp_DynDm_D_INV_REPEAT_METADATA_distinct
        FROM
            #tmp_DynDm_D_INV_REPEAT_METADATA;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

        --used later
        DECLARE @RDB_COLUMN_COMMA_LIST VARCHAR(MAX);
        SET @RDB_COLUMN_COMMA_LIST =null;

        SELECT @RDB_COLUMN_COMMA_LIST = COALESCE(@RDB_COLUMN_COMMA_LIST+',' ,'') + RDB_COLUMN_NM
        FROM #tmp_DynDm_D_INV_REPEAT_METADATA_distinct;

        if @debug = 'true'
            select 'RDB_COLUMN_COMMA_LIST',@RDB_COLUMN_COMMA_LIST;

        DECLARE @RDB_COLUMN_COMMA_LIST_SELECT VARCHAR(MAX);
        SET @RDB_COLUMN_COMMA_LIST_SELECT =null;

        SELECT @RDB_COLUMN_COMMA_LIST_SELECT = COALESCE(@RDB_COLUMN_COMMA_LIST_SELECT+',' ,'') + 'coalesce('+RDB_COLUMN_NM+ ','''') '+ RDB_COLUMN_NM
        FROM #tmp_DynDm_D_INV_REPEAT_METADATA_distinct;

        if @debug = 'true'
            SELECT 'RDB_COLUMN_COMMA_LIST_SELECT',@RDB_COLUMN_COMMA_LIST_SELECT ;

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING tmp_DynDm_SUMM_DATAMART';

        SELECT
            isd.PATIENT_KEY AS PATIENT_KEY,
            isd.INVESTIGATION_KEY,
            c.DISEASE_GRP_CD
        into #tmp_DynDm_SUMM_DATAMART
        FROM dbo.INV_SUMM_DATAMART isd with ( nolock)
                 INNER JOIN dbo.V_CONDITION_DIM c with (nolock) ON isd.DISEASE_CD = c.CONDITION_CD
            and CAST(c.DISEASE_GRP_CD AS VARCHAR(200)) = @nbs_page_form_cd
            --INNER JOIN dbo.V_CONDITION_DIM c with ( nolock) ON isd.DISEASE_CD = c.CONDITION_CD and c.DISEASE_GRP_CD = @nbs_page_form_cd
            --INNER JOIN dbo.INVESTIGATION inv with (nolock) ON isd.investigation_key = inv.investigation_key

                 INNER JOIN dbo.INVESTIGATION inv with (nolock) ON isd.investigation_key = inv.investigation_key
            and CAST(inv.case_uid AS VARCHAR(200)) in (SELECT value FROM STRING_SPLIT(@phc_id_list, ','));

        --and inv.case_uid in (SELECT value FROM STRING_SPLIT(@phc_id_list, ','));

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

        --------------------------------------------------------------------------------------------------------------------------------------------
-- building tmp_DynDm_REPEAT_BLOCK
--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING ' + @tmp_DynDm_REPEAT_BLOCK;

        declare @sql nvarchar(MAX);

        if object_id( @tmp_DynDm_REPEAT_BLOCK) is not null
            begin
                declare @dsql nvarchar(500) = 'drop table '+ @tmp_DynDm_REPEAT_BLOCK;
                exec sp_executesql @dsql;
            end

        IF OBJECT_ID('dbo.D_INVESTIGATION_REPEAT', 'U') IS NOT NULL
            begin
                SET @sql = ' SELECT '+ @RDB_COLUMN_COMMA_LIST_SELECT + ' ,ANSWER_GROUP_SEQ_NBR, D_INVESTIGATION_REPEAT.D_INVESTIGATION_REPEAT_KEY, tsd.INVESTIGATION_KEY, D_INVESTIGATION_REPEAT.BLOCK_NM ' +
                           ' into '+@tmp_DynDm_REPEAT_BLOCK+
                           ' FROM #tmp_DynDM_SUMM_DATAMART tsd ' +
                           ' INNER JOIN dbo.'+ @FACT_CASE+ ' ON	tsd.INVESTIGATION_KEY = '+ @FACT_CASE+'.INVESTIGATION_KEY ' +
                           ' INNER JOIN dbo.D_INVESTIGATION_REPEAT ON '+ @FACT_CASE+'.D_INVESTIGATION_REPEAT_KEY = D_INVESTIGATION_REPEAT.D_INVESTIGATION_REPEAT_KEY ' +
                           ' WHERE D_INVESTIGATION_REPEAT.D_INVESTIGATION_REPEAT_KEY>1 ;'

                EXEC sp_executesql @sql;
            end
        else
            begin
                SET @SQL = ' SELECT tsd.INVESTIGATION_KEY ' +
                           'into '+@tmp_DynDm_REPEAT_BLOCK+
                           'FROM #tmp_DynDM_SUMM_DATAMART tsd';

                EXEC sp_executesql @sql;
            end
            ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        IF @debug = 'true'
            BEGIN
                SELECT '@RDB_COLUMN_COMMA_LIST' AS Variable_Name, @RDB_COLUMN_COMMA_LIST AS Value;
                SELECT '@RDB_COLUMN_COMMA_LIST_SELECT' AS Variable_Name, @RDB_COLUMN_COMMA_LIST_SELECT AS Value;
            END


        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING #tmp_DynDm_REPEAT_BLOCK_OUT';

        create table #tmp_DynDm_REPEAT_BLOCK_OUT
        (INVESTIGATION_KEY bigint,
         BLOCK_NM_REPEAT_BLOCK_OUT varchar(max),
         ANSWER_GROUP_SEQ_NBR_REPEAT_BLOCK_OUT varchar(max),
         RDB_COLUMN_NM_REPEAT_BLOCK_OUT varchar(max),
         COL1 varchar(max)
        );

        SET @sql = ' insert into #tmp_DynDm_REPEAT_BLOCK_OUT ' +
                   ' select INVESTIGATION_KEY, BLOCK_NM as BLOCK_NM_REPEAT_BLOCK_OUT, ' +
                   'ANSWER_GROUP_SEQ_NBR as ANSWER_GROUP_SEQ_NBR_REPEAT_BLOCK_OUT, '+

                   'variable as RDB_COLUMN_NM_REPEAT_BLOCK_OUT,value as COL1 '+
                   ' from ( '+
                   ' select INVESTIGATION_KEY, BLOCK_NM, ANSWER_GROUP_SEQ_NBR, '+ @RDB_COLUMN_COMMA_LIST +
                   ' from dbo.tmp_DynDm_REPEAT_BLOCK_' + @DATAMART_NAME + '_' + cast(@batch_id as varchar) +
            --' from ' + @tmp_DynDm_REPEAT_BLOCK +
                   ' ) as t '+
                   ' unpivot ( '+
                   ' value for variable in ( '+@RDB_COLUMN_COMMA_LIST+ ') '+
                   ' ) as unpvt '
        ;

        if @debug = 'true'
            select 'tmp_DynDm_REPEAT_BLOCK_OUT',@sql;

        EXEC sp_executesql @sql;

        if @debug = 'true'
            select 'tmp_DynDm_REPEAT_BLOCK_OUT',* from #tmp_DynDm_REPEAT_BLOCK_OUT;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

        --------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
-- building tmp_DynDm_BLOCK_DATA from tmp_DynDm_BLOCK_DATA_UNIT and tmp_DynDm_BLOCK_DATA_OTH
----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING tmp_DynDm_BLOCK_DATA_UNIT';

        SELECT
            BLOCK_NM,
            RDB_COLUMN_NM
        into
            #tmp_DynDm_BLOCK_DATA_UNIT
        FROM
            dbo.V_NRT_D_INV_REPEAT_BLOCKDATA
        WHERE
            INVESTIGATION_FORM_CD = @nbs_page_form_cd
        ORDER BY
            RDB_COLUMN_NM,
            BLOCK_NM;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING tmp_DynDm_BLOCK_DATA_OTH';

        SELECT
            BLOCK_NM,
            substring(rtrim(RDB_COLUMN_NM), 1, 22) + '_OTH' as RDB_COLUMN_NM
        into
            #tmp_DynDm_BLOCK_DATA_OTH
        FROM
            dbo.V_NRT_D_INV_REPEAT_BLOCKDATA
        WHERE
            INVESTIGATION_FORM_CD = @nbs_page_form_cd
        ORDER BY
            RDB_COLUMN_NM,
            BLOCK_NM;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING tmp_DynDm_BLOCK_DATA';

        SELECT *
        into
            #tmp_DynDm_BLOCK_DATA
        FROM
            #tmp_DynDm_BLOCK_DATA_UNIT
        UNION
        SELECT *
        FROM
            #tmp_DynDm_BLOCK_DATA_OTH;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING tmp_DynDm_REPEAT_BLOCK_OUT_BASE';

        SELECT
            DISTINCT *
        into
            #tmp_DynDm_REPEAT_BLOCK_OUT_BASE
        FROM
            #tmp_DynDm_REPEAT_BLOCK_OUT bo
                INNER JOIN #tmp_DynDm_BLOCK_DATA bd ON
                bo.BLOCK_NM_REPEAT_BLOCK_OUT = bd.BLOCK_NM
                    AND UPPER(bo.RDB_COLUMN_NM_REPEAT_BLOCK_OUT)= UPPER(bd.RDB_COLUMN_NM)
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING tmp_DynDm_REPEAT_BLOCK_OUT_ALL';

        SELECT
            INVESTIGATION_KEY,RDB_COLUMN_NM_REPEAT_BLOCK_OUT, BLOCK_NM_REPEAT_BLOCK_OUT,
            cast(STUFF((select(
                                  SELECT
                                      rtrim(' ~' + coalesce(' ' + rtrim(ltrim(COL1)) , ''))
                                  FROM
                                      #tmp_DynDm_REPEAT_BLOCK_OUT_BASE
                                  where
                                      INVESTIGATION_KEY = a.INVESTIGATION_KEY
                                    AND RDB_COLUMN_NM_REPEAT_BLOCK_OUT = a.RDB_COLUMN_NM_REPEAT_BLOCK_OUT
                                    AND BLOCK_NM_REPEAT_BLOCK_OUT = a.BLOCK_NM_REPEAT_BLOCK_OUT
                                  --AND ANSWER_GROUP_SEQ_NBR_REPEAT_BLOCK_OUT = a.ANSWER_GROUP_SEQ_NBR_REPEAT_BLOCK_OUT
                                  order by
                                      INVESTIGATION_KEY,
                                      RDB_COLUMN_NM_REPEAT_BLOCK_OUT,
                                      BLOCK_NM_REPEAT_BLOCK_OUT,
                                      ANSWER_GROUP_SEQ_NBR_REPEAT_BLOCK_OUT
                                  FOR XML PATH (''),
                                      TYPE).value('.','varchar(8000)')), 1, 1, '') as varchar(8000)
            ) AS ANSWER_DESC21
        into
            #tmp_DynDm_REPEAT_BLOCK_OUT_ALL
        FROM
            #tmp_DynDm_REPEAT_BLOCK_OUT_BASE AS a
        group BY INVESTIGATION_KEY,RDB_COLUMN_NM_REPEAT_BLOCK_OUT, BLOCK_NM_REPEAT_BLOCK_OUT;

        update
            #tmp_DynDm_REPEAT_BLOCK_OUT_ALL
        set
            ANSWER_DESC21 = substring(ANSWER_DESC21,3, len(ANSWER_DESC21))
        where 1=1;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------
        alter table #tmp_DynDm_REPEAT_BLOCK_OUT_BASE
            drop column block_nm, rdb_column_nm;

        exec tempdb.sys.sp_rename N'#tmp_DynDm_REPEAT_BLOCK_OUT_BASE.COL1', N'DATA_VALUE', N'COLUMN';

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING tmp_DynDm_METADATA_MERGED_INIT';

        SELECT
            distinct *
        into
            #tmp_DynDm_METADATA_MERGED_INIT
        FROM
            #tmp_DynDm_METADATA_OUT_final tdof
                LEFT OUTER JOIN #tmp_DynDm_REPEAT_BLOCK_OUT_BASE trbb ON
                UPPER(tdof.RDB_COLUMN_NM) = UPPER(trbb.RDB_COLUMN_NM_REPEAT_BLOCK_OUT)
                    AND tdof.ANSWER_GROUP_SEQ_NBR = trbb.ANSWER_GROUP_SEQ_NBR_REPEAT_BLOCK_OUT
                    AND tdof.BLOCK_NM = trbb.BLOCK_NM_REPEAT_BLOCK_OUT ;

        if @debug = 'true'
            select 'tmp_DynDm_METADATA_MERGED_INIT',* from #tmp_DynDm_METADATA_MERGED_INIT;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        begin transaction;
        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC';

        IF OBJECT_ID(@tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC, 'U') IS NOT NULL
            exec ('drop table '+ @tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC);

        declare @columns varchar(max) = N'';

        SELECT @columns+=N', p.'+QUOTENAME(LTRIM(RTRIM([COL1])))
        FROM
            (
                SELECT [COL1]
                FROM #tmp_DynDm_METADATA_MERGED_INIT AS p
                GROUP BY [COL1]
            ) AS x;

        if @debug='true'
            select @columns;

        if @columns = ',' OR @columns IS NULL
            begin
                if @debug='true'
                    select @ddl_sql_invreptnum;
                exec(@ddl_sql_invreptnum);
            end
        else
            begin
                SET @sql = N'
	SELECT [INVESTIGATION_KEY] , '+STUFF(@columns, 1, 2, '')+
                           ' into '+@tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC +
                           ' FROM (
                           SELECT [INVESTIGATION_KEY], [DATA_VALUE] , [COL1]
                           FROM #tmp_DynDm_METADATA_MERGED_INIT
                           group by [INVESTIGATION_KEY], [DATA_VALUE] , [COL1]
                           ) AS j PIVOT (max(DATA_VALUE) FOR [COL1] in
                           ('+STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '')+')) AS p;';
                if @debug='true'
                    select '@tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC', @sql;
                EXEC sp_executesql @sql;
            end

        commit transaction;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING tmp_DynDm_INVESTIGATION_REPEAT_ALL';

        SELECT
            DISTINCT RDB_COLUMN_NM,
                     cast((rtrim(USER_DEFINED_COLUMN_NM) + '_ALL' )as varchar(4000)) as USER_DEFINED_COLUMN_NM_ALL
        into
            #tmp_DynDm_INVESTIGATION_REPEAT_ALL
        FROM
            #tmp_DynDm_D_INV_REPEAT_METADATA;

        if @debug = 'true' print 'completed #tmp_DynDm_INVESTIGATION_REPEAT_ALL';

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING tmp_DynDm_REPEAT_BLOCK_METADATA_OUT';

        SELECT
            rboa.*,
            ra.USER_DEFINED_COLUMN_NM_ALL
        into
            #tmp_DynDm_REPEAT_BLOCK_METADATA_OUT
        FROM
            #tmp_DynDm_INVESTIGATION_REPEAT_ALL ra
                LEFT OUTER JOIN #tmp_DynDm_REPEAT_BLOCK_OUT_ALL rboa ON
                UPPER(ra.RDB_COLUMN_NM) = UPPER(rboa.RDB_COLUMN_NM_REPEAT_BLOCK_OUT);

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

        if @debug = 'true'
            select '#tmp_DynDm_REPEAT_BLOCK_METADATA_OUT',* from #tmp_DynDm_REPEAT_BLOCK_METADATA_OUT;

--------------------------------------------------------------------------------------------------------------------------------------------

        begin transaction;
        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' GENERATING '+@tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL;

        IF OBJECT_ID(@tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL, 'U') IS NOT NULL
            exec ('drop table '+ @tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL);

        SET @columns = N'';

        SELECT @columns+=N', p.'+QUOTENAME(LTRIM(RTRIM([USER_DEFINED_COLUMN_NM_ALL])))
        FROM
            (
                SELECT [USER_DEFINED_COLUMN_NM_ALL]
                FROM #tmp_DynDm_REPEAT_BLOCK_METADATA_OUT AS p
                GROUP BY [USER_DEFINED_COLUMN_NM_ALL]
            ) AS x;

        if @columns = ',' OR @columns IS NULL
            exec(@ddl_sql_reptblknum);
        else
            begin
                SET @sql = N'
	SELECT [INVESTIGATION_KEY] , '+STUFF(@columns, 1, 2, '')+
                           ' into ' + @tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL +
                           ' FROM (
                           SELECT [INVESTIGATION_KEY], [ANSWER_DESC21] , [USER_DEFINED_COLUMN_NM_ALL]
                           FROM #tmp_DynDm_REPEAT_BLOCK_METADATA_OUT
                           group by [INVESTIGATION_KEY], [ANSWER_DESC21] , [USER_DEFINED_COLUMN_NM_ALL]
                           ) AS j PIVOT (max(ANSWER_DESC21) FOR [USER_DEFINED_COLUMN_NM_ALL] in
                           ('+STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '')+')) AS p;';
                if @debug='true'
                    select '@tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL', @sql;
                exec sp_executesql @sql;
            end

        if @debug = 'true'
            exec('select * from '+@tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL);

        commit transaction;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

--------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'SP_COMPLETE';

        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'COMPLETE' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            BEGIN
                COMMIT TRANSACTION;
            END;

        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) + -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        select @FullErrorMessage;

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count] )
        VALUES( @Batch_id, @Dataflow_Name, @package_Name, 'ERROR',@Proc_Step_no, @Proc_Step_name, @FullErrorMessage, 0 );
        RETURN -1;
    END CATCH;
END;