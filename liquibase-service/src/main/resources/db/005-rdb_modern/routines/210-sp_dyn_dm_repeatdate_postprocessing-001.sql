IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_dyn_dm_repeatdate_postprocessing]')
                                      AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
    BEGIN
        DROP PROCEDURE [dbo].[sp_dyn_dm_repeatdate_postprocessing]
    END
GO

CREATE PROCEDURE dbo.sp_dyn_dm_repeatdate_postprocessing
    @batch_id BIGINT,
    @DATAMART_NAME VARCHAR(100),
    @phc_id_list nvarchar(max),
    @debug bit = 'false'
AS
BEGIN
    BEGIN TRY

        /* Output Tables:
         * tmp_DynDm_INVESTIGATION_REPEAT_DATE_<DATAMART_NAME>_<batch_id>
         * tmp_DynDm_REPEAT_BLOCK_DATE_ALL_<DATAMART_NAME_<batch_id>
         * */


        DECLARE @RowCount_no INT;
        DECLARE @Proc_Step_no FLOAT = 0;
        DECLARE @Proc_Step_Name VARCHAR(200) = '';

        DECLARE @dataflow_name varchar(200) = 'DYNAMIC_DATAMART POST-Processing';
        DECLARE @package_name varchar(200) = 'sp_dyn_dm_repeatdatedata_postprocessing: ' + @DATAMART_NAME; --'sp_dyn_dm_repeatdatedata_postprocessing';

        DECLARE @nbs_page_form_cd varchar(200)='';
        SET @nbs_page_form_cd = (SELECT FORM_CD FROM dbo.v_nrt_nbs_page WHERE DATAMART_NM = @DATAMART_NAME);

        DECLARE @tmp_DynDm_INVESTIGATION_REPEAT_DATE varchar(200) = 'dbo.tmp_DynDm_INVESTIGATION_REPEAT_DATE_'+@DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));
        DECLARE @tmp_DynDm_REPEAT_BLOCK_DATE_ALL varchar(200) = 'dbo.tmp_DynDm_REPEAT_BLOCK_DATE_ALL_'+@DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));
        DECLARE @tmp_DynDM_REPEAT_BLOCK varchar(200) = 'dbo.tmp_DynDM_REPEAT_BLOCK_'+@DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));;

        DECLARE @temp_sql nvarchar(max);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [row_count]
                                         , [Msg_Description1])
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @Proc_Step_no
               , @Proc_Step_Name
               , 0
               , LEFT(@phc_id_list, 500))


        SET @temp_sql = '
        IF OBJECT_ID(''tempdb..'+@tmp_DynDM_REPEAT_BLOCK+''', ''U'') IS NOT NULL
            drop table '+@tmp_DynDM_REPEAT_BLOCK;
        exec sp_executesql @temp_sql;


        SET @temp_sql = '
        IF OBJECT_ID('''+@tmp_DynDm_INVESTIGATION_REPEAT_DATE+''', ''U'') IS NOT NULL
            drop table '+@tmp_DynDm_INVESTIGATION_REPEAT_DATE;
        exec sp_executesql @temp_sql;

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING #tmp_DynDM_Metadata';


        SELECT distinct DATAMART_NM
                      , RDB_COLUMN_NM
                      , USER_DEFINED_COLUMN_NM
                      , INVESTIGATION_FORM_CD
                      , coalesce(BLOCK_PIVOT_NBR, 1)         as BLOCK_PIVOT_NBR
                      , BLOCK_NM
                      ,rtrim(USER_DEFINED_COLUMN_NM) +'_1' as USER_DEFINED_COLUMN_NM_1
                      ,rtrim(USER_DEFINED_COLUMN_NM) +'_2' as USER_DEFINED_COLUMN_NM_2
                      ,rtrim(USER_DEFINED_COLUMN_NM) +'_3' as USER_DEFINED_COLUMN_NM_3
                      ,rtrim(USER_DEFINED_COLUMN_NM) +'_4' as USER_DEFINED_COLUMN_NM_4
                      ,rtrim(USER_DEFINED_COLUMN_NM) +'_5' as USER_DEFINED_COLUMN_NM_5
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
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Check for countmeta';


        DECLARE @countmeta int = 0;
        SELECT TOP 2 @countmeta = count(*) from #tmp_DynDM_Metadata ;

        IF @countmeta < 1
            BEGIN

                if @debug = 'true' SELECT 'No repeat date metadata';


                SET @temp_sql = '
		        IF OBJECT_ID('''+@tmp_DynDm_INVESTIGATION_REPEAT_DATE+''', ''U'') IS NOT NULL
		            drop table '+@tmp_DynDm_INVESTIGATION_REPEAT_DATE;
                exec sp_executesql @temp_sql;


                SET @temp_sql = '
		        IF OBJECT_ID('''+@tmp_DynDM_REPEAT_BLOCK_DATE_ALL+''', ''U'') IS NOT NULL
		            drop table '+@tmp_DynDM_REPEAT_BLOCK_DATE_ALL;
                exec sp_executesql @temp_sql;


                SET @temp_sql = '
                CREATE TABLE ' + @tmp_DynDM_INVESTIGATION_REPEAT_DATE + '
                (
                    [INVESTIGATION_KEY] [bigint] NULL
                ) ON [PRIMARY];

                CREATE TABLE ' + @tmp_DynDM_REPEAT_BLOCK_DATE_ALL + '
                (
                    [INVESTIGATION_KEY] [bigint] NULL
                ) ON [PRIMARY];';

                exec sp_executesql @temp_sql;


                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = 'SP_COMPLETE';


                INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type],[step_number],[step_name],[row_count])
                VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @ROWCOUNT_NO);

                return;

            end;


----------------------------------------------------------------------------------------------------------------------------------------------------

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


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING #tmp_DynDM_METADATA_OUT';


        select rdb_column_nm, block_nm, variable as '_NAME_', value as 'COL1'
        into #tmp_DynDM_METADATA_OUT
        from (select rdb_column_nm,
                     block_nm,
                     USER_DEFINED_COLUMN_NM_1,
                     USER_DEFINED_COLUMN_NM_2,
                     USER_DEFINED_COLUMN_NM_3,
                     USER_DEFINED_COLUMN_NM_4,
                     USER_DEFINED_COLUMN_NM_5
              from #tmp_DynDM_METADATA ) as t
                 unpivot (
                 value for variable in ( USER_DEFINED_COLUMN_NM_1 ,USER_DEFINED_COLUMN_NM_2 ,USER_DEFINED_COLUMN_NM_3,USER_DEFINED_COLUMN_NM_4,USER_DEFINED_COLUMN_NM_5)
                 ) as unpvt;


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_METADATA_OUT;

        --UPDATE 1
        IF COL_LENGTH('tempdb..#tmp_DynDM_METADATA_OUT', 'COL1') IS NULL
            BEGIN
                ALTER TABLE #tmp_DynDM_METADATA_OUT
                    ADD COL1 VARCHAR(8000)
            END

        --UPDATE 2
        DELETE FROM #tmp_DynDM_METADATA_OUT WHERE (COL1) IS NULL or rtrim(COL1) = '';

        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_METADATA_OUT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING #tmp_DynDM_METADATA_OUT1';


        --CREATE TABLE METADATA_OUT1 AS
        SELECT *
        into #tmp_DynDM_METADATA_OUT1
        FROM #tmp_DynDM_METADATA_OUT
        WHERE BLOCK_NM IS NOT NULL;

        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_METADATA_OUT1;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING #tmp_DynDM_METADATA_OUT_final';


        SELECT DISTINCT mo.*
                      , mo1.BLOCK_NM                                     AS BLOCK_NM1
                      , CAST(SUBSTRING(mo.COL1, LEN(mo.COL1), 1) AS INT) AS ANSWER_GROUP_SEQ_NBR
        into #tmp_DynDM_METADATA_OUT_final
        FROM #tmp_DynDM_METADATA_OUT mo
                 INNER JOIN #tmp_DynDM_METADATA_OUT1 mo1  ON mo1.RDB_COLUMN_NM = mo.RDB_COLUMN_NM;


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_METADATA_OUT_final;


        DECLARE @countstd int = 0;

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

        select @COUNTSTD = count(*) from #tmp_DynDm_Case_Management_Metadata;

        if @debug = 'true' PRINT @COUNTSTD;


        declare @FACT_CASE varchar(40) = '';

        if @countstd > 1
            begin
                set @FACT_CASE = 'F_STD_PAGE_CASE';
            end
        else
            begin
                set @FACT_CASE = 'F_PAGE_CASE';
            end;


        if @debug = 'true' print @FACT_CASE;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING #tmp_DynDM_D_INV_REPEAT_METADATA';


        SELECT DISTINCT DATAMART_NM, RDB_COLUMN_NM, USER_DEFINED_COLUMN_NM, BLOCK_PIVOT_NBR
        into #tmp_DynDM_D_INV_REPEAT_METADATA
        FROM #tmp_DynDM_Metadata ;

        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_D_INV_REPEAT_METADATA;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING RDB Column List';


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
        FROM #tmp_DynDM_D_INV_REPEAT_METADATA
        WHERE DATAMART_NM IS NOT NULL
        ORDER BY RDB_COLUMN_NM;


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_D_INV_REPEAT_METADATA;

        --		 if @debug = 'true'
--		 BEGIN
--	        PRINT @RDB_COLUMN_LIST;
--	        PRINT @RDB_COLUMN_COMMA_LIST;
--	        PRINT @RDB_COLUMN_NAME_LIST;
--		 END


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

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


        declare @SQL varchar(8000);


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK';


        SET @temp_sql = '
		        IF OBJECT_ID('''+@tmp_DynDM_REPEAT_BLOCK+''', ''U'') IS NOT NULL
		            drop table '+@tmp_DynDM_REPEAT_BLOCK;
        exec sp_executesql @temp_sql;


        SELECT isd.PATIENT_KEY AS PATIENT_KEY, isd.INVESTIGATION_KEY, c.DISEASE_GRP_CD
        into #tmp_DynDm_SUMM_DATAMART
        FROM dbo.INV_SUMM_DATAMART isd  with (nolock)
                 INNER JOIN dbo.condition c
                            ON isd.DISEASE_CD = c.CONDITION_CD and c.DISEASE_GRP_CD = @nbs_page_form_cd
                 INNER JOIN dbo.INVESTIGATION I with (nolock) ON isd.investigation_key = I.INVESTIGATION_KEY
            and I.case_uid in (SELECT value FROM STRING_SPLIT(@phc_id_list, ','));


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDm_SUMM_DATAMART;


        if object_id('dbo.D_INVESTIGATION_REPEAT') is not null
            Begin
                SET @SQL = '   SELECT ' + @D_REPEAT_COMMA_NAME +
                           ' ANSWER_GROUP_SEQ_NBR, D_INVESTIGATION_REPEAT.D_INVESTIGATION_REPEAT_KEY, tmp.INVESTIGATION_KEY, D_INVESTIGATION_REPEAT.BLOCK_NM ' +
                           '    into '+ @tmp_DynDM_REPEAT_BLOCK +
                           '    FROM #tmp_DynDM_SUMM_DATAMART tmp ' +
                           '		INNER JOIN  dbo.' + @FACT_CASE +
                           '     ON tmp.INVESTIGATION_KEY  = ' + @FACT_CASE +
                           '.INVESTIGATION_KEY ' +
                           '		INNER JOIN  dbo.D_INVESTIGATION_REPEAT' + '   ON	' + @FACT_CASE +
                           '.' + 'D_INVESTIGATION_REPEAT_KEY  = D_INVESTIGATION_REPEAT.D_INVESTIGATION_REPEAT_KEY ' +
                           '	  WHERE D_INVESTIGATION_REPEAT.D_INVESTIGATION_REPEAT_KEY>1 ';

                -- select 1,@SQL;
                --PRINT @SQL;
                EXEC (@SQL);
            end
        else
            Begin

                SET @SQL = ' SELECT tmp_DynDM_SUMM_DATAMART.INVESTIGATION_KEY ' +
                           '    into '+@tmp_DynDM_REPEAT_BLOCK +
                           '    FROM #tmp_DynDM_SUMM_DATAMART ';

                -- select 2,@SQL;

                EXEC (@SQL);
            end;

        --         if @debug = 'true'
--         BEGIN
--         	SET @temp_sql = '
--		        SELECT ''tmp_DynDM_REPEAT_BLOCK'',* FROM '+@tmp_DynDM_REPEAT_BLOCK;
--        	exec sp_executesql @temp_sql;
--         END
--

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @ROWCOUNT_NO);
        COMMIT TRANSACTION;

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_OUT';


        CREATE TABLE #tmp_DynDM_REPEAT_BLOCK_OUT
        (
            INVESTIGATION_KEY BIGINT,
            BLOCK_NM_BLOCK_OUT VARCHAR(30),
            ANSWER_GROUP_SEQ_NBR INT,
            RDB_COLUMN_NM_BLOCK_OUT VARCHAR(100),
            dateColumn DATE
        );

        declare @columns varchar(8000);

        select @columns = @RDB_COLUMN_COMMA_LIST;
        PRINT @RDB_COLUMN_COMMA_LIST;

        SET @temp_sql =
                N' INSERT INTO #tmp_DynDM_REPEAT_BLOCK_OUT
					select INVESTIGATION_KEY ,BLOCK_NM as BLOCK_NM_BLOCK_OUT ,ANSWER_GROUP_SEQ_NBR,variable as RDB_COLUMN_NM_BLOCK_OUT,value as dateColumn '
                    + ' from ( '
                    + ' select INVESTIGATION_KEY ,BLOCK_NM ,ANSWER_GROUP_SEQ_NBR,  ' + @D_REPEAT_COMMA_NAME1
                    + ' from  '+@tmp_DynDM_REPEAT_BLOCK+'  '
                    + ' ) as t '
                    + ' unpivot ( '
                    + ' value for variable in ( ' + @D_REPEAT_COMMA_NAME1 + ') '
                    + ' ) as unpvt ';


        exec sp_executesql @temp_sql;
        --  print(@temp_sql)

        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_REPEAT_BLOCK_OUT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_BLOCK_DATA';

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
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_OUT_BASE';


        SELECT DISTINCT *
        into #tmp_DynDM_REPEAT_BLOCK_OUT_BASE
        FROM #tmp_DynDM_REPEAT_BLOCK_OUT rbo
                 INNER JOIN #tmp_DynDM_BLOCK_DATA bd  ON rbo.BLOCK_NM_BLOCK_OUT = bd.BLOCK_NM
            AND UPPER(rbo.RDB_COLUMN_NM_BLOCK_OUT) = UPPER(bd.RDB_COLUMN_NM);

        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_REPEAT_BLOCK_OUT_BASE;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_OUT_ALL';


        CREATE TABLE #tmp_DynDM_REPEAT_BLOCK_OUT_ALL
        (
            INVESTIGATION_KEY BIGINT,
            RDB_COLUMN_NM_BLOCK_OUT VARCHAR(30),
            BLOCK_NM_BLOCK_OUT VARCHAR(30),
            ANSWER_GROUP_SEQ_NBR INT,
            ANSWER_DESC21 VARCHAR(8000)
        );

        SET @temp_sql = N'
        INSERT INTO #tmp_DynDM_REPEAT_BLOCK_OUT_ALL
		SELECT INVESTIGATION_KEY,
               RDB_COLUMN_NM_BLOCK_OUT,
               BLOCK_NM_BLOCK_OUT,
               ANSWER_GROUP_SEQ_NBR,
               cast(STUFF(
                       (select(SELECT rtrim('' ~'' + coalesce('' '' + rtrim(ltrim(dateColumn)), ''.''))
                               FROM #tmp_DynDM_REPEAT_BLOCK_OUT_BASE
                               where INVESTIGATION_KEY = a.INVESTIGATION_KEY
                                 AND RDB_COLUMN_NM_BLOCK_OUT = a.RDB_COLUMN_NM_BLOCK_OUT
                                 AND BLOCK_NM_BLOCK_OUT = a.BLOCK_NM_BLOCK_OUT
      AND ANSWER_GROUP_SEQ_NBR = a.ANSWER_GROUP_SEQ_NBR
                               order by INVESTIGATION_KEY, RDB_COLUMN_NM_BLOCK_OUT, BLOCK_NM_BLOCK_OUT,
                                        ANSWER_GROUP_SEQ_NBR
                               FOR XML PATH (''''),TYPE).value(''.'', ''varchar(8000)''))
                   , 1, 1, '''') as varchar(8000)) AS ANSWER_DESC21
        FROM #tmp_DynDM_REPEAT_BLOCK_OUT_BASE  AS a
        group BY INVESTIGATION_KEY, RDB_COLUMN_NM_BLOCK_OUT, BLOCK_NM_BLOCK_OUT, ANSWER_GROUP_SEQ_NBR';
        exec sp_executesql @temp_sql;


        UPDATE #tmp_DynDM_REPEAT_BLOCK_OUT_ALL
        SET ANSWER_DESC21 = substring(ANSWER_DESC21, 3, len(ANSWER_DESC21));

        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_REPEAT_BLOCK_OUT_ALL;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_METADATA_OUT1_2';


        IF OBJECT_ID('tempdb..#tmp_DynDM_METADATA_OUT1', 'U') IS NOT NULL
            drop table #tmp_DynDM_METADATA_OUT1;

        --Notes: Replace tmp_DynDM_METADATA_OUT1 with tmp_DynDM_METADATA_OUT1_2 to address compilation error.
        select RDB_COLUMN_NM, _NAME_, COL1, BLOCK_NM, ANSWER_GROUP_SEQ_NBR
        into #tmp_DynDM_METADATA_OUT1_2
        FROM #tmp_DynDM_METADATA_OUT_final ;


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_METADATA_OUT1_2;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_METADATA_MERGED_INIT';


        SELECT distinct dmo.*, drbob.dateColumn, drbob.investigation_key
        into #tmp_DynDM_METADATA_MERGED_INIT
        FROM #tmp_DynDM_METADATA_OUT1_2 dmo
                 LEFT OUTER JOIN #tmp_DynDM_REPEAT_BLOCK_OUT_BASE drbob  ON
            UPPER(dmo.RDB_COLUMN_NM) = UPPER(drbob.RDB_COLUMN_NM)
                AND dmo.ANSWER_GROUP_SEQ_NBR = drbob.ANSWER_GROUP_SEQ_NBR
                AND dmo.BLOCK_NM = drbob.BLOCK_NM;


        if @debug = 'true' select @Proc_Step_Name as step, * from #tmp_DynDM_METADATA_MERGED_INIT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_INVESTIGATION_REPEAT_DATE';


        SET @temp_sql = '
        IF OBJECT_ID('''+@tmp_DynDm_INVESTIGATION_REPEAT_DATE+''', ''U'') IS NOT NULL
            drop table '+@tmp_DynDm_INVESTIGATION_REPEAT_DATE;
        exec sp_executesql @temp_sql;


        SET @columns = N'';

        SELECT @columns+=N', p.'+QUOTENAME(LTRIM(RTRIM([COL1])))
        FROM
            (
                SELECT [COL1]
                FROM #tmp_DynDM_METADATA_MERGED_INIT AS p
                GROUP BY [COL1]
            ) AS x;

        -- PRINT @columns;

        SET @sql = N'
					SELECT [INVESTIGATION_KEY] , ' + STUFF(@columns, 1, 2, '') +
                   ' into '+@tmp_DynDm_INVESTIGATION_REPEAT_DATE +
                   ' FROM (
    SELECT [INVESTIGATION_KEY], [dateColumn] , [COL1]
      FROM #tmp_DynDM_METADATA_MERGED_INIT
                       group by [INVESTIGATION_KEY], [dateColumn] , [COL1]
                           ) AS j PIVOT (max(dateColumn) FOR [COL1] in
                          (' + STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '') + ')) AS p;';

        -- print @sql;
        EXEC (@sql);

        SET @temp_sql = '
        IF OBJECT_ID('''+@tmp_DynDm_INVESTIGATION_REPEAT_DATE+''', ''U'') IS NULL
			  CREATE TABLE '+@tmp_DynDm_INVESTIGATION_REPEAT_DATE+'
        (
            [INVESTIGATION_KEY] [bigint] NULL
        ) ;'

        exec sp_executesql @temp_sql;


        SET @temp_sql = 'delete
			from '+@tmp_DynDm_INVESTIGATION_REPEAT_DATE+' where investigation_key is null;'
        exec sp_executesql @temp_sql;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);
        COMMIT TRANSACTION;

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_ALL';


        SELECT DISTINCT RDB_COLUMN_NM, USER_DEFINED_COLUMN_NM + '_ALL' as USER_DEFINED_COLUMN_NM_ALL
        into #tmp_DynDM_REPEAT_ALL
        FROM #tmp_DynDM_D_INV_REPEAT_METADATA ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

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


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max';


        select 'tmp_DynDM_REPEAT_BLOCK_OUT_BASE_1' as tb,
               INVESTIGATION_KEY,
               BLOCK_NM_BLOCK_OUT,
               max(ANSWER_GROUP_SEQ_NBR)           as block_max
        into #tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max
        from #tmp_DynDM_REPEAT_BLOCK_OUT_BASE
        group by investigation_key, BLOCK_NM_BLOCK_OUT;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max_1';


        select 'tmp_DynDM_REPEAT_BLOCK_OUT_BASE_1'  as tb,
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
        INSERT [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_METADATA_OUT';

        IF OBJECT_ID('#tmp_DynDM_REPEAT_BLOCK_METADATA_OUT', 'U') IS NOT NULL
            drop table #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT;


        SELECT rba.*, ra.USER_DEFINED_COLUMN_NM_ALL
        into #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT
        FROM #tmp_DynDM_REPEAT_ALL ra
                 LEFT OUTER JOIN #tmp_DynDM_REPEAT_BLOCK_OUT_ALL rba
                                 ON UPPER(ra.RDB_COLUMN_NM) = UPPER(rba.RDB_COLUMN_NM_BLOCK_OUT);


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL';


        IF OBJECT_ID('#tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL', 'U') IS NOT NULL
            drop table #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL;

        SELECT
            [INVESTIGATION_KEY], [USER_DEFINED_COLUMN_NM_ALL],
            STUFF(
                    (SELECT  ' ~ ' + coalesce([ANSWER_DESC21],'.')
                     FROM #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT
                     WHERE [INVESTIGATION_KEY] = a.[INVESTIGATION_KEY] AND [USER_DEFINED_COLUMN_NM_ALL] = a.[USER_DEFINED_COLUMN_NM_ALL]
                     order by [INVESTIGATION_KEY], [USER_DEFINED_COLUMN_NM_ALL],answer_group_seq_nbr
                     FOR XML PATH (''))
                , 1, 3, '')  AS ANSWER_DESC21
        into #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL
        FROM  #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT AS a
        GROUP BY [INVESTIGATION_KEY], [USER_DEFINED_COLUMN_NM_ALL]
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);

----------------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_REPEAT_BLOCK_DATE_ALL';


        SET @temp_sql = '
        IF OBJECT_ID('''+@tmp_DynDM_REPEAT_BLOCK_DATE_ALL+''', ''U'') IS NOT NULL
            drop table '+@tmp_DynDM_REPEAT_BLOCK_DATE_ALL;
        exec sp_executesql @temp_sql;


        SET @columns = N'';

        SELECT @columns+=N', p.'+QUOTENAME(LTRIM(RTRIM([USER_DEFINED_COLUMN_NM_ALL])))
        FROM
            (
                SELECT [USER_DEFINED_COLUMN_NM_ALL]
                FROM #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL AS p
                GROUP BY [USER_DEFINED_COLUMN_NM_ALL]
            ) AS x;

        if @debug = 'true' PRINT @columns;

        SET @sql = N'
		SELECT [INVESTIGATION_KEY]  , '+STUFF(@columns, 1, 2, '')+
                   ' into '+@tmp_DynDM_REPEAT_BLOCK_DATE_ALL +
                   ' FROM (
                   SELECT [INVESTIGATION_KEY], [ANSWER_DESC21] , [USER_DEFINED_COLUMN_NM_ALL]
                    FROM #tmp_DynDM_REPEAT_BLOCK_METADATA_OUT_FINAL
                       group by [INVESTIGATION_KEY], [ANSWER_DESC21] , [USER_DEFINED_COLUMN_NM_ALL]
                           ) AS j PIVOT (max(ANSWER_DESC21) FOR [USER_DEFINED_COLUMN_NM_ALL] in
                        ('+STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '')+')) AS p;';

        if @debug = 'true' print @sql;
        EXEC ( @sql);


        SET @temp_sql = '
	        IF OBJECT_ID('''+@tmp_DynDM_REPEAT_BLOCK_DATE_ALL+''', ''U'') IS NULL
				  CREATE TABLE '+@tmp_DynDM_REPEAT_BLOCK_DATE_ALL+'
	        (
	            [INVESTIGATION_KEY] [bigint] NULL
	        ) ;'

        exec sp_executesql @temp_sql;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no,@Proc_Step_Name, @ROWCOUNT_NO);
        COMMIT TRANSACTION;

----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Drop tmp_DynDM_REPEAT_BLOCK';


        SET @temp_sql = '
        IF OBJECT_ID('''+@tmp_DynDM_REPEAT_BLOCK+''', ''U'') IS NOT NULL
            drop table '+@tmp_DynDM_REPEAT_BLOCK;
        exec sp_executesql @temp_sql;


----------------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = 999;
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
               , LEFT(@phc_id_list, 500)
               , @FullErrorMessage);


        return -1;

    END CATCH
END;