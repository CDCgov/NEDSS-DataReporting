
CREATE OR ALTER PROCEDURE dbo.sp_alter_datamart_schema_postprocessing
     @batch_id bigint,
    @dataflow_name nvarchar(max),
    @tgt_table_nm nvarchar(max),
    @debug bit = 'false'
    as

BEGIN
    declare @package_name varchar(200) = 'CHECK-AND-MODIFY-DATAMART-'+@tgt_table_nm;
    declare @proc_step_no float = 0;
    declare @proc_step_name varchar(200) = '';
    declare @rowcount_no bigint;


BEGIN TRY

    SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Building Union Query';

    declare @unionquery VARCHAR(500);
	set @unionquery =
			case
	            when OBJECT_ID('tempdb..#OBS_CODED_'+@tgt_table_nm, 'U') is not NULL
	            		then ' SELECT distinct rdb_table, col_nm, db_field, label FROM #OBS_CODED_'+@tgt_table_nm
				else ' SELECT null as rdb_table, null as col_nm, null as db_field, null as label'
            end +
			case
				when OBJECT_ID('tempdb..#OBS_TXT_'+@tgt_table_nm, 'U') is not NULL and OBJECT_ID('tempdb..#OBS_CODED_'+@tgt_table_nm, 'U') is not NULL
					then ' union all SELECT distinct rdb_table, col_nm, db_field, null FROM #OBS_TXT_'+@tgt_table_nm
				when OBJECT_ID('tempdb..#OBS_TXT_'+@tgt_table_nm, 'U') is not null
					then 'SELECT distinct rdb_table, col_nm, db_field, null FROM #OBS_TXT_'+@tgt_table_nm
				else ''
            end +
			case
				when OBJECT_ID('tempdb..#OBS_DATE_'+@tgt_table_nm, 'U') is not NULL and (
					OBJECT_ID('tempdb..#OBS_CODED_'+@tgt_table_nm, 'U') is not NULL or
					OBJECT_ID('tempdb..#OBS_TXT_'+@tgt_table_nm, 'U') is not NULL
					) then ' union all SELECT distinct rdb_table, col_nm, db_field, null FROM #OBS_DATE_'+@tgt_table_nm
				when OBJECT_ID('tempdb..#OBS_DATE_'+@tgt_table_nm, 'U') is not NULL
					then 'SELECT distinct rdb_table, col_nm, db_field, null FROM #OBS_DATE_'+@tgt_table_nm
				else ''
            end +
			case
				when OBJECT_ID('tempdb..#OBS_NUMERIC_'+@tgt_table_nm, 'U') is not NULL and (
					OBJECT_ID('tempdb..#OBS_CODED_'+@tgt_table_nm, 'U') is not NULL or
					OBJECT_ID('tempdb..#OBS_TXT_'+@tgt_table_nm, 'U') is not NULL or
					OBJECT_ID('tempdb..#OBS_DATE_'+@tgt_table_nm, 'U') is not NULL
					) then ' union all SELECT distinct rdb_table, col_nm, db_field, null FROM #OBS_NUMERIC_'+@tgt_table_nm
				when OBJECT_ID('tempdb..#OBS_NUMERIC_'+@tgt_table_nm, 'U') is not NULL then 'SELECT distinct rdb_table, col_nm, db_field, null FROM #OBS_NUMERIC_'+@tgt_table_nm
				else ''
            end
	;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO dbo.[JOB_FLOW_LOG]
    (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
    VALUES(@BATCH_ID,@dataflow_name,@package_name,'START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

    if @debug = 'true'
        select 'unionquery', @unionquery;

    SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Building Missed Columns';


    create  table #missed_cols  (
        rdb_table VARCHAR(100),
        col_nm VARCHAR(100),
        col_data_type VARCHAR(100),
        col_character_maximum_length bigint,
        col_numeric_precision bigint,
        col_numeric_scale bigint
    );


    DECLARE @DynamicQuery NVARCHAR(MAX);

	set @DynamicQuery = 'insert into #missed_cols
	select
	    snt.rdb_table,
        snt.col_nm,
        coalesce(isc_rdb.data_type,isc_srte.data_type, ''varchar''),
        coalesce(isc_rdb.character_maximum_length,isc_srte.character_maximum_length, 300),
        coalesce(isc_rdb.numeric_precision,isc_srte.numeric_precision,18),
        coalesce(isc_rdb.numeric_scale,isc_srte.numeric_scale,0)
	from
	(
	select src.*,
			case
				when db_field =''code'' and label is null then ''nrt_observation_coded''
				when db_field =''code'' and label is not null and label = ''cvg_code'' then ''code_value_general''
				when db_field =''code'' and label is not null and label = ''country'' then ''Country_code''
				when db_field =''code'' and label is not null and label = ''state'' then ''State_code''
				when db_field =''code'' and label is not null and label = ''county'' then ''State_county_code_value''
				when db_field =''code'' and label is not null and label = ''jurcode'' then ''Jurisdiction_code''
				when db_field=''from_time'' then ''nrt_observation_date''
				when db_field=''numeric_value_1'' then ''nrt_observation_numeric''
				when db_field=''value_txt'' then ''nrt_observation_txt''
				else null
			end as src_nrt_table,
			case
				when db_field =''code'' and label is not null and label = ''cvg_code'' then ''code_short_desc_txt''
				when db_field =''code'' and label is not null and label = ''country'' then ''code_short_desc_txt''
				when db_field =''code'' and label is not null and label = ''state'' then ''state_nm''
				when db_field =''code'' and label is not null and label = ''county'' then ''code_desc_txt''
				when db_field =''code'' and label is not null and label = ''jurcode'' then ''code_short_desc_txt''
				when db_field=''from_time'' then ''ovd_from_date''
				when db_field=''numeric_value_1'' then ''ovn_numeric_value_1''
				when db_field=''value_txt'' then ''ovt_value_txt''
				else null
			end as src_nrt_table_col
		from ( '+
		 @unionquery
		+ ' ) src
		left outer join (
			SELECT name FROM sys.columns
			WHERE object_id = OBJECT_ID('''+@tgt_table_nm+''')
		) tgt
		on tgt.name = src.col_nm
		where tgt.name is null
	) snt
	left outer join
	    nbs_srte.INFORMATION_SCHEMA.COLUMNS isc_srte
	    ON UPPER(isc_srte.TABLE_NAME) = UPPER(snt.src_nrt_table)
	    AND UPPER(isc_srte.COLUMN_NAME) = UPPER(snt.src_nrt_table_col)
	left outer join
	    INFORMATION_SCHEMA.COLUMNS isc_rdb
	    ON UPPER(isc_rdb.TABLE_NAME) = UPPER(snt.src_nrt_table)
	    AND UPPER(isc_rdb.COLUMN_NAME) = UPPER(snt.src_nrt_table_col)
	     where rdb_table is not null';


	if @debug = 'true'
        select '@DynamicQuery', @DynamicQuery;


    exec sp_executesql @DynamicQuery;

     INSERT INTO dbo.[JOB_FLOW_LOG]
	    (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
	    VALUES(@BATCH_ID,@dataflow_name,@package_name,'START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

	  if @debug = 'true'
	    select '#missed_cols', * from #missed_cols;



    SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Adding Missed Columns';

	DECLARE @AlterQuery NVARCHAR(MAX);

	DECLARE @Count INT = (SELECT COUNT(*) FROM #missed_cols );

	IF @Count is null or @Count = 0
    BEGIN
        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
	    INSERT INTO dbo.[JOB_FLOW_LOG]
	    (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
	    VALUES(@BATCH_ID,@dataflow_name,@package_name,'SKIPPED',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
                RETURN;
    END



	set @AlterQuery = 'ALTER TABLE '+ @tgt_table_nm + ' ADD ' + (select STRING_AGG( col_nm + ' ' +  col_data_type +
	    CASE
	        WHEN col_data_type IN ('decimal', 'numeric') THEN '(' + CAST(col_NUMERIC_PRECISION AS NVARCHAR) + ',' + CAST(col_NUMERIC_SCALE AS NVARCHAR) + ')'
	        WHEN col_data_type = 'varchar' THEN '(' +
	            CASE WHEN col_CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(col_CHARACTER_MAXIMUM_LENGTH AS NVARCHAR) END
	        + ')'
	        ELSE ''
	    END, ', ') from #missed_cols);

	-- Print or execute the generated SQL

    if @debug = 'true'
        select '@AlterQuery', @AlterQuery;

    exec sp_executesql @AlterQuery;

    INSERT INTO dbo.[JOB_FLOW_LOG]
	    (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
	    VALUES(@BATCH_ID,@dataflow_name,@package_name,'START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

END TRY
    BEGIN CATCH
        -- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count] )
    VALUES( @Batch_id
      , @dataflow_name
      , @package_name
      , 'ERROR'
      , @Proc_Step_no
      , @Proc_Step_name
      , @FullErrorMessage
      , 0 );
    RETURN -1;

END CATCH;
END