CREATE OR ALTER PROCEDURE [dbo].sp_dyn_dm_repeatdatedata_postprocessing
    @batch_id BIGINT,
    @DATAMART_NAME VARCHAR(100),
    @id_list nvarchar(max),
    @debug bit = 'false'
AS
BEGIN
    BEGIN TRY

        /*
         * tmp_DynDm_INVESTIGATION_REPEAT_DATE
         * tmp_DynDm_REPEAT_BLOCK_DATE_ALL
         * */


        DECLARE @RowCount_no INT;
        DECLARE @Proc_Step_no FLOAT = 0;
        DECLARE @Proc_Step_Name VARCHAR(200) = '';

        DECLARE @dataflow_name varchar(200) = 'DYNAMIC_DATAMART POST-Processing';
        DECLARE @package_name varchar(200) = 'sp_dyn_dm_repeatdatedata_postprocessing: ' + @DATAMART_NAME; --'sp_dyn_dm_repeatdatedata_postprocessing';

        DECLARE @nbs_page_form_cd varchar(200)='';
        SET @nbs_page_form_cd = (SELECT FORM_CD FROM dbo.v_nrt_nbs_page WHERE DATAMART_NM = @DATAMART_NAME)

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [row_count])
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @Proc_Step_no
               , @Proc_Step_Name
               , 0);


        /*Notes: Convert to Temp*/

        IF OBJECT_ID('#tmp_DynDM_Metadata', 'U') IS NOT NULL
            drop table #tmp_DynDM_Metadata;


        IF OBJECT_ID('#tmp_DynDM_REPEAT_ALL', 'U') IS NOT NULL
            drop table #tmp_DynDM_REPEAT_ALL;


        IF OBJECT_ID('#tmp_DynDM_BLOCK_DATA', 'U') IS NOT NULL
            drop table #tmp_DynDM_BLOCK_DATA;


        IF OBJECT_ID('dbo.tmp_DynDM_REPEAT_BLOCK', 'U') IS NOT NULL
            drop table dbo.tmp_DynDM_REPEAT_BLOCK;


        IF OBJECT_ID('dbo.tmp_DynDM_INVESTIGATION_REPEAT_DATE', 'U') IS NOT NULL
            drop table dbo.tmp_DynDM_INVESTIGATION_REPEAT_DATE;


        IF OBJECT_ID('#tmp_DynDM_REPEAT_BLOCK_OUT_BASE', 'U') IS NOT NULL
            drop table #tmp_DynDM_REPEAT_BLOCK_OUT_BASE;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING #tmp_DynDM_Metadata';


        IF OBJECT_ID('#tmp_DynDM_Metadata', 'U') IS NOT NULL
            drop table #tmp_DynDM_Metadata;


        SELECT distinct DATAMART_NM
                      , RDB_COLUMN_NM
                      , USER_DEFINED_COLUMN_NM
                      , INVESTIGATION_FORM_CD
                      , coalesce(BLOCK_PIVOT_NBR, 1)         as BLOCK_PIVOT_NBR
                      , BLOCK_NM
                      , rtrim(USER_DEFINED_COLUMN_NM) + '_1' as USER_DEFINED_COLUMN_NM_1
                      , rtrim(USER_DEFINED_COLUMN_NM) + '_2' as USER_DEFINED_COLUMN_NM_2
                      , rtrim(USER_DEFINED_COLUMN_NM) + '_3' as USER_DEFINED_COLUMN_NM_3
                      , rtrim(USER_DEFINED_COLUMN_NM) + '_4' as USER_DEFINED_COLUMN_NM_4
                      , rtrim(USER_DEFINED_COLUMN_NM) + '_5' as USER_DEFINED_COLUMN_NM_5
        into #tmp_DynDM_Metadata
        FROM dbo.v_nrt_d_inv_repeat_metadata
        WHERE RDB_TABLE_NM = 'D_INVESTIGATION_REPEAT'
          AND data_type in ('DATETIME', 'DATE', 'Date', 'Date/Time')
          AND code_set_group_id is null
          AND USER_DEFINED_COLUMN_NM != ''
          AND USER_DEFINED_COLUMN_NM IS NOT NULL
          AND INVESTIGATION_FORM_CD = @nbs_page_form_cd
        ORDER BY RDB_COLUMN_NM;


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_Metadata;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING update #tmp_DynDM_Metadata';


        update #tmp_DynDM_Metadata
        SET USER_DEFINED_COLUMN_NM_1 = '',
            USER_DEFINED_COLUMN_NM_2 = '',
            USER_DEFINED_COLUMN_NM_3 = '',
            USER_DEFINED_COLUMN_NM_4 = '',
            USER_DEFINED_COLUMN_NM_5 = ''
        where BLOCK_PIVOT_NBR = 0;


        update #tmp_DynDM_Metadata
        SET USER_DEFINED_COLUMN_NM_2 = '',
            USER_DEFINED_COLUMN_NM_3 = '',
            USER_DEFINED_COLUMN_NM_4 = '',
            USER_DEFINED_COLUMN_NM_5 = ''
        where BLOCK_PIVOT_NBR = 1;


        update #tmp_DynDM_Metadata
        SET USER_DEFINED_COLUMN_NM_3 = '',
            USER_DEFINED_COLUMN_NM_4 = '',
            USER_DEFINED_COLUMN_NM_5 = ''
        where BLOCK_PIVOT_NBR = 2;


        update #tmp_DynDM_Metadata
        SET USER_DEFINED_COLUMN_NM_4 = '',
            USER_DEFINED_COLUMN_NM_5 = ''
        where BLOCK_PIVOT_NBR = 3;

        update #tmp_DynDM_Metadata
        SET USER_DEFINED_COLUMN_NM_5 = ''
        where BLOCK_PIVOT_NBR = 4;

        --DX select 'tmp_DynDM_Metadata',* from  dbo.tmp_DynDM_Metadata where rdb_column_nm like '%DD_R_PDI_DATE%';


        declare @countmeta int = 0;

        select top 2 @countmeta = count(*) from #tmp_DynDM_Metadata with (nolock);

        --	select '@countmeta',@countmeta

        if @countmeta < 1
            begin

                select 'No repeat date metadata';


                IF OBJECT_ID('dbo.tmp_DynDM_INVESTIGATION_REPEAT_DATE', 'U') IS NOT NULL
                    drop table dbo.tmp_DynDM_INVESTIGATION_REPEAT_DATE;


                IF OBJECT_ID('dbo.tmp_DynDM_REPEAT_BLOCK_DATE_ALL', 'U') IS NOT NULL
                    drop table dbo.tmp_DynDM_REPEAT_BLOCK_DATE_ALL;


                CREATE TABLE [dbo].tmp_DynDM_INVESTIGATION_REPEAT_DATE
                (
                    [INVESTIGATION_KEY] [bigint] NULL
                ) ON [PRIMARY];

                CREATE TABLE [dbo].tmp_DynDM_REPEAT_BLOCK_DATE_ALL
                (
                    [INVESTIGATION_KEY] [bigint] NULL
                ) ON [PRIMARY];


                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = 'SP_COMPLETE';


                INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type],
                                                  [step_number], [step_name], [row_count])
                VALUES (@batch_id, @dataflow_name, @package_name, 'START',
                        @Proc_Step_no, @Proc_Step_Name, @ROWCOUNT_NO);


                COMMIT TRANSACTION;

                return;

            end;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING #tmp_DynDM_METADATA_OUT';


        IF OBJECT_ID('#tmp_DynDM_METADATA_OUT', 'U') IS NOT NULL
            drop table #tmp_DynDM_METADATA_OUT;


        IF OBJECT_ID('dbo.tmp_DynDM_TransposedData', 'U') IS NOT NULL
            drop table dbo.tmp_DynDM_TransposedData;


        select rdb_column_nm, block_nm, variable as '_NAME_', value as 'COL1'
        into #tmp_DynDM_METADATA_OUT
        from (select rdb_column_nm,
                     block_nm,
                     USER_DEFINED_COLUMN_NM_1,
                     USER_DEFINED_COLUMN_NM_2,
                     USER_DEFINED_COLUMN_NM_3,
                     USER_DEFINED_COLUMN_NM_4,
                     USER_DEFINED_COLUMN_NM_5
              from #tmp_DynDM_METADATA with (nolock)) as t
                 unpivot (
                 value for variable in ( USER_DEFINED_COLUMN_NM_1 ,USER_DEFINED_COLUMN_NM_2 ,USER_DEFINED_COLUMN_NM_3,USER_DEFINED_COLUMN_NM_4,USER_DEFINED_COLUMN_NM_5)
                 ) as unpvt;


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_METADATA_OUT;


        IF COL_LENGTH('tempdb..#tmp_DynDM_METADATA_OUT', 'COL1') IS NULL
            BEGIN
                ALTER TABLE #tmp_DynDM_METADATA_OUT
                    ADD COL1 VARCHAR(8000)
            END


        DELETE FROM #tmp_DynDM_METADATA_OUT WHERE (COL1) IS NULL or rtrim(COL1) = '';

        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_METADATA_OUT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING #tmp_DynDM_METADATA_OUT1';


        IF OBJECT_ID('#tmp_DynDM_METADATA_OUT1', 'U') IS NOT NULL
            drop table #tmp_DynDM_METADATA_OUT1;


        --CREATE TABLE METADATA_OUT1 AS
        SELECT *
        into #tmp_DynDM_METADATA_OUT1
        FROM #tmp_DynDM_METADATA_OUT with (nolock)
        WHERE BLOCK_NM IS NOT NULL;

        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_METADATA_OUT1;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_METADATA_OUT_final';


        IF OBJECT_ID('#tmp_DynDM_METADATA_OUT_final', 'U') IS NOT NULL
            drop table #tmp_DynDM_METADATA_OUT_final;


        SELECT DISTINCT mo.*
                      , mo1.BLOCK_NM                                     AS BLOCK_NM1
                      , CAST(SUBSTRING(mo.COL1, LEN(mo.COL1), 1) AS INT) AS ANSWER_GROUP_SEQ_NBR
        into #tmp_DynDM_METADATA_OUT_final
        FROM #tmp_DynDM_METADATA_OUT mo with (nolock)
                 INNER JOIN #tmp_DynDM_METADATA_OUT1 mo1 with (nolock) ON mo1.RDB_COLUMN_NM = mo.RDB_COLUMN_NM;


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_METADATA_OUT_final;


        --DX select * from dbo.tmp_DynDM_METADATA_OUT_final;


        declare @countstd int = 0;

        --Ref: sp_dyn_dm_invest_form_postprocessing
        SELECT DISTINCT FORM_CD,
                        DATAMART_NM,
                        RDB_TABLE_NM,
                        RDB_COLUMN_NM,
                        USER_DEFINED_COLUMN_NM,
                        INVESTIGATION_FORM_CD,
                        rdb_column_nm_list
        INTO #tmp_DynDm_Case_Management_Metadata
        FROM dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata case_meta
        where case_meta.INVESTIGATION_FORM_CD = @nbs_page_form_cd;


        select @COUNTSTD = count(*)
        from #tmp_DynDm_Case_Management_Metadata;


        declare @FACT_CASE varchar(40) = '';

        --Note: Single set of investigations to a datamart are the expected input.
        if @countstd > 1
            begin
                set @FACT_CASE = 'F_STD_PAGE_CASE';
            end
        else
            begin
                set @FACT_CASE = 'F_PAGE_CASE';
            end;

        -- select @fact_case;

        print @FACT_CASE;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_D_INV_REPEAT_METADATA';


        IF OBJECT_ID('dbo.tmp_DynDM_D_INV_REPEAT_METADATA', 'U') IS NOT NULL
            drop table dbo.tmp_DynDM_D_INV_REPEAT_METADATA;


        --	CREATE TABLE D_INV_REPEAT_METADATA AS
        SELECT DISTINCT DATAMART_NM, RDB_COLUMN_NM, USER_DEFINED_COLUMN_NM, BLOCK_PIVOT_NBR
        into #tmp_DynDM_D_INV_REPEAT_METADATA
        FROM #tmp_DynDM_Metadata with (nolock);

        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_D_INV_REPEAT_METADATA;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  db_cursor CURSOR ';


        -- Initialize variables
        DECLARE @RDB_COLUMN_NAME_LIST NVARCHAR(4000) = '';
        DECLARE @RDB_COLUMN_LIST NVARCHAR(4000) = '';
        DECLARE @RDB_COLUMN_COMMA_LIST NVARCHAR(4000) = '';

        -- Loop through the source table
        DECLARE @SORT_KEY INT;
        DECLARE @DATAMART_NM NVARCHAR(4000);
        DECLARE @RDB_COLUMN_NM NVARCHAR(4000);
        DECLARE @USER_DEFINED_COLUMN_NM NVARCHAR(4000);
        DECLARE @USER_DEFINED_COLUMN_NAME NVARCHAR(4000);
        DECLARE @RDB_COLUMN_NAME NVARCHAR(4000);

        SELECT @RDB_COLUMN_NAME_LIST = @RDB_COLUMN_NAME_LIST +
                                       QUOTENAME(RDB_COLUMN_NM) + ' AS ' +  QUOTENAME(USER_DEFINED_COLUMN_NM) + ', ',
               @RDB_COLUMN_LIST = @RDB_COLUMN_LIST + QUOTENAME(RDB_COLUMN_NM) + ' ',
               @RDB_COLUMN_COMMA_LIST = @RDB_COLUMN_COMMA_LIST + QUOTENAME(RDB_COLUMN_NM)+','
        FROM #tmp_DynDM_D_INV_REPEAT_METADATA with (nolock)
        WHERE DATAMART_NM IS NOT NULL
        ORDER BY RDB_COLUMN_NM;


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_D_INV_REPEAT_METADATA;

        PRINT @RDB_COLUMN_LIST;
        PRINT @RDB_COLUMN_COMMA_LIST;
        PRINT @RDB_COLUMN_NAME_LIST;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  RDB_COLUMN_NAME_LIST';


        DECLARE @D_REPEAT_CASE NVARCHAR(4000) = '';
        DECLARE @D_REPEAT_CASE_NAME NVARCHAR(4000) = '';
        DECLARE @D_REPEAT_COMMA_NAME NVARCHAR(4000) = '';
        DECLARE @D_REPEAT_COMMA_NAME1 NVARCHAR(4000) = '';


        if LEN(@RDB_COLUMN_NAME_LIST) < 1
            begin
                SET @RDB_COLUMN_NAME_LIST = ' '
                SET @RDB_COLUMN_LIST = ' '
                SET @RDB_COLUMN_COMMA_LIST = ' '
            end


        SET @D_REPEAT_CASE = LEFT(@RDB_COLUMN_NAME_LIST, LEN(@RDB_COLUMN_NAME_LIST) - 1);

        SET @D_REPEAT_CASE_NAME = @RDB_COLUMN_LIST;

        SET @D_REPEAT_COMMA_NAME = @RDB_COLUMN_COMMA_LIST;

        SET @D_REPEAT_COMMA_NAME1 = LEFT(@RDB_COLUMN_COMMA_LIST, LEN(@RDB_COLUMN_COMMA_LIST) - 1);


        declare @SQL varchar(8000)


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK';


        IF OBJECT_ID('dbo.tmp_DynDM_REPEAT_BLOCK', 'U') IS NOT NULL
            drop table dbo.tmp_DynDM_REPEAT_BLOCK;


        SELECT isd.PATIENT_KEY AS PATIENT_KEY, isd.INVESTIGATION_KEY, c.DISEASE_GRP_CD
        into #tmp_DynDm_SUMM_DATAMART
        FROM dbo.INV_SUMM_DATAMART isd with (nolock)
                 INNER JOIN dbo.v_condition_dim c with (nolock)
                            ON isd.DISEASE_CD = c.CONDITION_CD and c.DISEASE_GRP_CD = @nbs_page_form_cd
                 INNER JOIN dbo.INVESTIGATION I with (nolock) ON isd.investigation_key = I.INVESTIGATION_KEY
            and I.case_uid in (SELECT value FROM STRING_SPLIT(@id_list, ','));


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDm_SUMM_DATAMART;


        if object_id('dbo.D_INVESTIGATION_REPEAT') is not null
            Begin
                SET @SQL = '   SELECT ' + @D_REPEAT_COMMA_NAME +
                           ' ANSWER_GROUP_SEQ_NBR, D_INVESTIGATION_REPEAT.D_INVESTIGATION_REPEAT_KEY, tmp.INVESTIGATION_KEY, D_INVESTIGATION_REPEAT.BLOCK_NM ' +
                           '    into dbo.tmp_DynDM_REPEAT_BLOCK' +
                           '    FROM #tmp_DynDM_SUMM_DATAMART tmp with (nolock)' +
                           '		INNER JOIN  dbo.' + @FACT_CASE +
                           '   with (nolock)  ON tmp.INVESTIGATION_KEY  = ' + @FACT_CASE +
                           '.INVESTIGATION_KEY ' +
                           '		INNER JOIN  dbo.D_INVESTIGATION_REPEAT' + '  with (nolock) ON	' + @FACT_CASE +
                           '.' + 'D_INVESTIGATION_REPEAT_KEY  = D_INVESTIGATION_REPEAT.D_INVESTIGATION_REPEAT_KEY ' +
                           '	  WHERE D_INVESTIGATION_REPEAT.D_INVESTIGATION_REPEAT_KEY>1 ';

                -- select 1,@SQL;
                PRINT @SQL;
                EXEC (@SQL);
            end
        else
            Begin

                SET @SQL = '   SELECT tmp_DynDM_SUMM_DATAMART.INVESTIGATION_KEY ' +
                           '    into dbo.tmp_DynDM_REPEAT_BLOCK' +
                           '    FROM #tmp_DynDM_SUMM_DATAMART ';

                -- select 2,@SQL;

                EXEC (@SQL);
            end;


        if @debug = 'true' select @Proc_Step_Name as step, * from dbo.tmp_DynDM_REPEAT_BLOCK;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_OUT_VARCHAR';


        IF OBJECT_ID('dbo.tmp_DynDM_REPEAT_BLOCK_OUT_VARCHAR', 'U') IS NOT NULL
            drop table dbo.tmp_DynDM_REPEAT_BLOCK_OUT_VARCHAR;


        declare @columns varchar(8000);

        select @columns = @RDB_COLUMN_COMMA_LIST;

        --select '@columns_1', @columns;


        SET @sql =
                N' select INVESTIGATION_KEY ,BLOCK_NM as BLOCK_NM_BLOCK_OUT ,ANSWER_GROUP_SEQ_NBR,variable as RDB_COLUMN_NM_BLOCK_OUT,value as dateColumn '
                    + ' into dbo.tmp_DynDM_REPEAT_BLOCK_OUT_VARCHAR '
                    + ' from ( '
                    + ' select INVESTIGATION_KEY ,BLOCK_NM ,ANSWER_GROUP_SEQ_NBR,  ' + @D_REPEAT_COMMA_NAME1
                    + ' from  dbo.tmp_DynDM_REPEAT_BLOCK  with (nolock)'
                    + ' ) as t '
                    + ' unpivot ( '
                    + ' value for variable in ( ' + @D_REPEAT_COMMA_NAME1 + ') '
                    + ' ) as unpvt ';


        --DX	select  '@sql tmp_DynDM_REPEAT_BLOCK_OUT_VARCHAR',@sql;


        EXEC ( @sql);


        --DX select 'tmp_DynDM_REPEAT_BLOCK_OUT_VARCHAR',* from dbo.tmp_DynDM_REPEAT_BLOCK_OUT_VARCHAR;

        if @debug = 'true' select @Proc_Step_Name as step, * from dbo.tmp_DynDM_REPEAT_BLOCK_OUT_VARCHAR;


        --/*
        ----- VS

        --DATA REPEAT_BLOCK_OUT;
        --set REPEAT_BLOCK_OUT;
        --RDB_COLUMN_NM = _NAME_;
        --coloumnText=ANSWER_TXT;
        --rename col1=dateColumn;
        --RUN;

        --*/

        --select * from dbo.tmp_DynDM_REPEAT_BLOCK_OUT_VARCHAR;


        ----CREATE TABLE BLOCK_DATA AS
        ---- DECLARE  @batch_id BIGINT = 999;  DECLARE  @DATAMART_NAME VARCHAR(100) = 'STD';


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_BLOCK_DATA';


        IF OBJECT_ID('#tmp_DynDM_BLOCK_DATA', 'U') IS NOT NULL
            drop table #tmp_DynDM_BLOCK_DATA;

        SELECT RDB_COLUMN_NM
             , BLOCK_NM
        into #tmp_DynDM_BLOCK_DATA
        FROM dbo.v_nrt_d_inv_repeat_metadata
        WHERE RDB_TABLE_NM = 'D_INVESTIGATION_REPEAT'
          AND PART_TYPE_CD IS NULL
          AND QUESTION_GROUP_SEQ_NBR IS NOT NULL
          AND data_type in ('DATETIME', 'DATE', 'Date', 'Date/Time')
          AND USER_DEFINED_COLUMN_NM != ''
          AND USER_DEFINED_COLUMN_NM IS NOT NULL
          AND BLOCK_PIVOT_NBR IS NOT NULL
          AND data_type in ('DATETIME', 'DATE', 'Date', 'Date/Time')
          AND code_set_group_id is null
          AND INVESTIGATION_FORM_CD = @nbs_page_form_cd
        ORDER BY RDB_COLUMN_NM, BLOCK_NM;


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_BLOCK_DATA;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_OUT_BASE';


        IF OBJECT_ID('dbo.tmp_DynDM_REPEAT_BLOCK_OUT_BASE', 'U') IS NOT NULL
            drop table dbo.tmp_DynDM_REPEAT_BLOCK_OUT_BASE;


        ----CREATE TABLE REPEAT_BLOCK_OUT_BASE AS
        SELECT DISTINCT *
        into #tmp_DynDM_REPEAT_BLOCK_OUT_BASE
        FROM dbo.tmp_DynDM_REPEAT_BLOCK_OUT_VARCHAR rbo
                 INNER JOIN #tmp_DynDM_BLOCK_DATA bd with (nolock) ON rbo.BLOCK_NM_BLOCK_OUT = bd.BLOCK_NM
            AND UPPER(rbo.RDB_COLUMN_NM_BLOCK_OUT) = UPPER(bd.RDB_COLUMN_NM);


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_OUT_ALL';


        IF OBJECT_ID('dbo.tmp_DynDM_REPEAT_BLOCK_OUT_ALL', 'U') IS NOT NULL
            drop table dbo.tmp_DynDM_REPEAT_BLOCK_OUT_ALL;


        SELECT INVESTIGATION_KEY,
               RDB_COLUMN_NM_BLOCK_OUT,
               BLOCK_NM_BLOCK_OUT,
               ANSWER_GROUP_SEQ_NBR,
               cast(STUFF(
                       (select(SELECT rtrim(' ~' + coalesce(' ' + rtrim(ltrim(dateColumn)), '.'))
                               FROM #tmp_DynDM_REPEAT_BLOCK_OUT_BASE with (nolock)
                               where INVESTIGATION_KEY = a.INVESTIGATION_KEY
                                 AND RDB_COLUMN_NM_BLOCK_OUT = a.RDB_COLUMN_NM_BLOCK_OUT
                                 AND BLOCK_NM_BLOCK_OUT = a.BLOCK_NM_BLOCK_OUT
                                 AND ANSWER_GROUP_SEQ_NBR = a.ANSWER_GROUP_SEQ_NBR
                               order by INVESTIGATION_KEY, RDB_COLUMN_NM_BLOCK_OUT, BLOCK_NM_BLOCK_OUT,
                                        ANSWER_GROUP_SEQ_NBR
                               FOR XML PATH (''),TYPE).value('.', 'varchar(8000)'))
                   , 1, 1, '') as varchar(8000)) AS ANSWER_DESC21
        into #tmp_DynDM_REPEAT_BLOCK_OUT_ALL
        FROM #tmp_DynDM_REPEAT_BLOCK_OUT_BASE AS a with (nolock)
        group BY INVESTIGATION_KEY, RDB_COLUMN_NM_BLOCK_OUT, BLOCK_NM_BLOCK_OUT, ANSWER_GROUP_SEQ_NBR

        --having count(*) > 1
        ;


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_REPEAT_BLOCK_OUT_ALL;


        update #tmp_DynDM_REPEAT_BLOCK_OUT_ALL
        set ANSWER_DESC21 = substring(ANSWER_DESC21, 3, len(ANSWER_DESC21));


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_METADATA_OUT1';


        IF OBJECT_ID('#tmp_DynDM_METADATA_OUT1', 'U') IS NOT NULL
            drop table #tmp_DynDM_METADATA_OUT1;


        ----CREATE TABLE METADATA_OUT as
        select RDB_COLUMN_NM, _NAME_, COL1, BLOCK_NM, ANSWER_GROUP_SEQ_NBR
        into #tmp_DynDM_METADATA_OUT1_2
        FROM #tmp_DynDM_METADATA_OUT_final with (nolock);


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_METADATA_OUT1_2;


        --DX select 'tmp_DynDM_METADATA_OUT1',* from dbo.tmp_DynDM_METADATA_OUT1;
        --DX select 'tmp_DynDM_REPEAT_BLOCK_OUT_BASE',* from tmp_DynDM_REPEAT_BLOCK_OUT_BASE;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_METADATA_MERGED_INIT';


        IF OBJECT_ID('#tmp_DynDM_METADATA_MERGED_INIT', 'U') IS NOT NULL
            drop table #tmp_DynDM_METADATA_MERGED_INIT;


        --CREATE TABLE METADATA_MERGED_INIT AS
        SELECT distinct dmo.*, drbob.dateColumn, drbob.investigation_key
        into #tmp_DynDM_METADATA_MERGED_INIT
        FROM #tmp_DynDM_METADATA_OUT1_2 dmo with (nolock)
                 LEFT OUTER JOIN #tmp_DynDM_REPEAT_BLOCK_OUT_BASE drbob with (nolock) ON
            UPPER(dmo.RDB_COLUMN_NM) = UPPER(drbob.RDB_COLUMN_NM)
                AND dmo.ANSWER_GROUP_SEQ_NBR = drbob.ANSWER_GROUP_SEQ_NBR
                AND dmo.BLOCK_NM = drbob.BLOCK_NM
        --where drbob.investigation_key is not null
        ;

        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_METADATA_MERGED_INIT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_INVESTIGATION_REPEAT_DATE';


        IF OBJECT_ID('dbo.tmp_DynDM_INVESTIGATION_REPEAT_DATE', 'U') IS NOT NULL
            drop table dbo.tmp_DynDM_INVESTIGATION_REPEAT_DATE;


        SET @columns = N'';

        SELECT @columns += N', p.' + QUOTENAME(LTRIM(RTRIM([COL1])))
        FROM (SELECT [COL1]
              FROM #tmp_DynDM_METADATA_MERGED_INIT AS p with (nolock)
              GROUP BY [COL1]) AS x;


        SET @sql = N'
												SELECT [INVESTIGATION_KEY] , ' + STUFF(@columns, 1, 2, '') +
                   ' into dbo.tmp_DynDM_INVESTIGATION_REPEAT_DATE ' +
                   'FROM (
                   SELECT [INVESTIGATION_KEY], [dateColumn] , [COL1]
                    FROM #tmp_DynDM_METADATA_MERGED_INIT  with (nolock)
                       group by [INVESTIGATION_KEY], [dateColumn] , [COL1]
                           ) AS j PIVOT (max(dateColumn) FOR [COL1] in
                          (' + STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '') + ')) AS p;';

        print @sql;
        EXEC (@sql);

        IF OBJECT_ID('dbo.tmp_DynDM_INVESTIGATION_REPEAT_DATE', 'U') IS NULL
        CREATE TABLE [dbo].tmp_DynDM_INVESTIGATION_REPEAT_DATE
        (
            [INVESTIGATION_KEY] [bigint] NULL
        ) ;


        delete from dbo.tmp_DynDM_INVESTIGATION_REPEAT_DATE where investigation_key is null;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_ALL';


        IF OBJECT_ID('#tmp_DynDM_REPEAT_ALL', 'U') IS NOT NULL
            drop table #tmp_DynDM_REPEAT_ALL;

        SELECT DISTINCT RDB_COLUMN_NM, USER_DEFINED_COLUMN_NM + '_ALL' as USER_DEFINED_COLUMN_NM_ALL
        into #tmp_DynDM_REPEAT_ALL
        FROM #tmp_DynDM_D_INV_REPEAT_METADATA with (nolock);


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  insert tmp_DynDM_REPEAT_BLOCK_OUT_ALL ';


        with t1 as (select INVESTIGATION_KEY,
                           RDB_COLUMN_NM_BLOCK_OUT,
                           BLOCK_NM_BLOCK_OUT,
                           max(ANSWER_GROUP_SEQ_NBR) maxANSWER_GROUP_SEQ_NBR,
                           min(ANSWER_GROUP_SEQ_NBR) minANSWER_GROUP_SEQ_NBR
                    from #tmp_DynDM_REPEAT_BLOCK_OUT_ALL
                    group by INVESTIGATION_KEY, RDB_COLUMN_NM_BLOCK_OUT, BLOCK_NM_BLOCK_OUT)
           , x as (select INVESTIGATION_KEY,
                          RDB_COLUMN_NM_BLOCK_OUT,
                          BLOCK_NM_BLOCK_OUT,
                          minANSWER_GROUP_SEQ_NBR,
                          maxANSWER_GROUP_SEQ_NBR
                   from t1
                   union all
                   select INVESTIGATION_KEY,
                          RDB_COLUMN_NM_BLOCK_OUT,
                          BLOCK_NM_BLOCK_OUT,
                          minANSWER_GROUP_SEQ_NBR + 1,
                          maxANSWER_GROUP_SEQ_NBR
                   from x
                   where minANSWER_GROUP_SEQ_NBR < maxANSWER_GROUP_SEQ_NBR)
        insert
        into #tmp_DynDM_REPEAT_BLOCK_OUT_ALL ( [INVESTIGATION_KEY]
                                             , [RDB_COLUMN_NM_BLOCK_OUT]
                                             , [BLOCK_NM_BLOCK_OUT]
                                             , [ANSWER_GROUP_SEQ_NBR]
                                             , [ANSWER_DESC21])
        select x.INVESTIGATION_KEY,
               x.RDB_COLUMN_NM_BLOCK_OUT,
               x.BLOCK_NM_BLOCK_OUT,
               x.minANSWER_GROUP_SEQ_NBR as missing_ANSWER_GROUP_SEQ_NBR,
               null
        from x
                 left join #tmp_DynDM_REPEAT_BLOCK_OUT_ALL t
                           on t.INVESTIGATION_KEY = x.INVESTIGATION_KEY
                               and t.RDB_COLUMN_NM_BLOCK_OUT = x.RDB_COLUMN_NM_BLOCK_OUT
                               and t.BLOCK_NM_BLOCK_OUT = x.BLOCK_NM_BLOCK_OUT
                               and t.ANSWER_GROUP_SEQ_NBR = x.minANSWER_GROUP_SEQ_NBR
        where t.ANSWER_GROUP_SEQ_NBR is null
        order by 1, 2, 3, 4;


        --DX select 'tmp_DynDM_REPEAT_BLOCK_OUT_ALL - 2 ',* from dbo.tmp_DynDM_REPEAT_BLOCK_OUT_ALL;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max';


        IF OBJECT_ID('dbo.tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max', 'U') IS NOT NULL
            drop table dbo.tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max;


        select 'tmp_DynDM_REPEAT_BLOCK_OUT_BASE_1' as tb,
               INVESTIGATION_KEY,
               BLOCK_NM_BLOCK_OUT,
               max(ANSWER_GROUP_SEQ_NBR)           as block_max
        into #tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max
        from #tmp_DynDM_REPEAT_BLOCK_OUT_BASE
        group by investigation_key, BLOCK_NM_BLOCK_OUT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max_1';


        IF OBJECT_ID('#tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max_1', 'U') IS NOT NULL
            drop table #tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max_1;


        select 'tmp_DynDM_REPEAT_BLOCK_OUT_BASE_1'   as tb,
               rb.INVESTIGATION_KEY,
               rb.BLOCK_NM_BLOCK_OUT,
               rb.RDB_COLUMN_NM,
               max(ANSWER_GROUP_SEQ_NBR)             as block_clock_max,
               block_max,
               block_max - max(ANSWER_GROUP_SEQ_NBR) as block_insert_count,
               cast(null as varchar(30))             as block_pad
        into #tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max_1
        from #tmp_DynDM_REPEAT_BLOCK_OUT_BASE rb
                 inner join #tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max rbx
                            on rbx.BLOCK_NM_BLOCK_OUT = rb.BLOCK_NM_BLOCK_OUT and
                               rbx.investigation_key = rb.INVESTIGATION_KEY
        --where  rb.INVESTIGATION_KEY = 146
        group by rb.investigation_key, rb.BLOCK_NM_BLOCK_OUT, rb.RDB_COLUMN_NM, block_max;


        delete
        from #tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max_1
        where block_clock_max = block_max;

        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max_1;


        --update #tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max_1 set block_insert_count = 3;


        update #tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max_1
        set block_pad = substring(
                substring(replicate('~.', block_insert_count), 2, len(replicate('~.', block_insert_count))), 1, 30);

        insert into #tmp_DynDM_REPEAT_BLOCK_OUT_ALL
        select investigation_key, rdb_column_nm, block_nm_block_out, block_max, block_pad
        from #tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max_1;


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_REPEAT_BLOCK_OUT_ALL;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                     [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_METADATA_OUT';


        IF OBJECT_ID('dbo.tmp_DynDM_REPEAT_BLOCK_METADATA_OUT', 'U') IS NOT NULL
            drop table dbo.tmp_DynDM_REPEAT_BLOCK_METADATA_OUT;


        --CREATE TABLE REPEAT_BLOCK_METADATA_OUT AS
        SELECT rba.*, ra.USER_DEFINED_COLUMN_NM_ALL
        into #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT
        FROM #tmp_DynDM_REPEAT_ALL ra with (nolock)
                 LEFT OUTER JOIN #tmp_DynDM_REPEAT_BLOCK_OUT_ALL rba with (nolock)
                                 ON UPPER(ra.RDB_COLUMN_NM) = UPPER(rba.RDB_COLUMN_NM_BLOCK_OUT);


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL';


        IF OBJECT_ID('#tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL', 'U') IS NOT NULL
            drop table #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL;

        SELECT [INVESTIGATION_KEY],
               [USER_DEFINED_COLUMN_NM_ALL],
               STUFF(
                       (SELECT ' ~ ' + coalesce([ANSWER_DESC21], '.')
                        FROM #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT with (nolock)
                        WHERE [INVESTIGATION_KEY] = a.[INVESTIGATION_KEY]
                          AND [USER_DEFINED_COLUMN_NM_ALL] = a.[USER_DEFINED_COLUMN_NM_ALL]
                        order by [INVESTIGATION_KEY], [USER_DEFINED_COLUMN_NM_ALL], answer_group_seq_nbr
                        FOR XML PATH (''))
                   , 1, 3, '') AS ANSWER_DESC21
        into #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL
        FROM #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT AS a
        GROUP BY [INVESTIGATION_KEY], [USER_DEFINED_COLUMN_NM_ALL];


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL;


        --DX							select 'dbo.tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL',* from dbo.tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL   ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_DATE_ALL';


        IF OBJECT_ID('dbo.tmp_DynDM_REPEAT_BLOCK_DATE_ALL', 'U') IS NOT NULL
            drop table dbo.tmp_DynDM_REPEAT_BLOCK_DATE_ALL;


        --DECLARE @columns NVARCHAR(4000);
        --DECLARE @sql NVARCHAR(4000);

        SET @columns = N'';

        SELECT @columns += N', p.' + QUOTENAME(LTRIM(RTRIM([USER_DEFINED_COLUMN_NM_ALL])))
        FROM (SELECT [USER_DEFINED_COLUMN_NM_ALL]
              FROM #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL AS p
              GROUP BY [USER_DEFINED_COLUMN_NM_ALL]) AS x;


        SET @sql = N'
												SELECT [INVESTIGATION_KEY]  , ' + STUFF(@columns, 1, 2, '') +
                   ' into dbo.tmp_DynDM_REPEAT_BLOCK_DATE_ALL ' +
                   'FROM (
                   SELECT [INVESTIGATION_KEY], [ANSWER_DESC21] , [USER_DEFINED_COLUMN_NM_ALL]
                    FROM #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL with (nolock)
                       group by [INVESTIGATION_KEY], [ANSWER_DESC21] , [USER_DEFINED_COLUMN_NM_ALL]
                           ) AS j PIVOT (max(ANSWER_DESC21) FOR [USER_DEFINED_COLUMN_NM_ALL] in
                          (' + STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '') + ')) AS p;';

        print @sql;
        EXEC ( @sql);


        IF OBJECT_ID('dbo.tmp_DynDM_REPEAT_BLOCK_DATE_ALL', 'U') IS NULL
        CREATE TABLE [dbo].tmp_DynDM_REPEAT_BLOCK_DATE_ALL
        (
            [INVESTIGATION_KEY] [bigint] NULL
        ) ;


        if @debug = 'true' select @Proc_Step_Name as step, * from dbo.tmp_DynDM_REPEAT_BLOCK_DATE_ALL;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],
                                          [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,
                @Proc_Step_Name, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_OUT_VARCHAR';


        IF OBJECT_ID('dbo.tmp_DynDM_REPEAT_BLOCK_OUT_VARCHAR', 'U') IS NOT NULL
            drop table dbo.tmp_DynDM_REPEAT_BLOCK_OUT_VARCHAR;


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_Name = 'SP_COMPLETE';


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [row_count])
        VALUES ( @batch_id,
                 @dataflow_name
               , @package_name
               , 'COMPLETE'
               , @Proc_Step_no
               , @Proc_Step_name
               , @RowCount_no);


        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) +
            CHAR(10) + -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [create_dttm]
        , [update_dttm]
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        , [msg_description1]
        , [Error_Description])

        VALUES ( @batch_id
               , current_timestamp
               , current_timestamp
               , @dataflow_name
               , @package_name
               , 'ERROR'
               , @Proc_Step_no
               , @proc_step_name
               , 0
               , LEFT(@id_list, 500)
               , @FullErrorMessage);


        return -1;

    END CATCH
END;

