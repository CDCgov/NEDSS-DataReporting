
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
	            when OBJECT_ID('tempdb..#OBS_CODED', 'U') is not NULL
	            		then ' SELECT distinct rdb_table, col_nm, db_field, label FROM #OBS_CODED'
				else ' SELECT null as rdb_table, null as col_nm, null as db_field, null as label'
            end +
			case
				when OBJECT_ID('tempdb..#OBS_TXT', 'U') is not NULL and OBJECT_ID('tempdb..#OBS_CODED', 'U') is not NULL
					then ' union all SELECT distinct rdb_table, col_nm, db_field, null FROM #OBS_TXT'
				when OBJECT_ID('tempdb..#OBS_TXT', 'U') is not null
					then 'SELECT distinct rdb_table, col_nm, db_field, null FROM #OBS_TXT'
				else ''
            end +
			case
				when OBJECT_ID('tempdb..#OBS_DATE', 'U') is not NULL and (
					OBJECT_ID('tempdb..#OBS_CODED', 'U') is not NULL or
					OBJECT_ID('tempdb..#OBS_TXT', 'U') is not NULL
					) then ' union all SELECT distinct rdb_table, col_nm, db_field, null FROM #OBS_DATE'
				when OBJECT_ID('tempdb..#OBS_DATE', 'U') is not NULL
					then 'SELECT distinct rdb_table, col_nm, db_field, null FROM #OBS_DATE'
				else ''
            end +
			case
				when OBJECT_ID('tempdb..#OBS_NUMERIC', 'U') is not NULL and (
					OBJECT_ID('tempdb..#OBS_CODED', 'U') is not NULL or
					OBJECT_ID('tempdb..#OBS_TXT', 'U') is not NULL or
					OBJECT_ID('tempdb..#OBS_DATE', 'U') is not NULL
					) then ' union all SELECT distinct rdb_table, col_nm, db_field, null FROM #OBS_NUMERIC'
				when OBJECT_ID('tempdb..#OBS_NUMERIC', 'U') is not NULL then 'SELECT distinct rdb_table, col_nm, db_field, null FROM #OBS_NUMERIC'
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
	  snt.rdb_table, snt.col_nm, coalesce(isc_rdb.data_type,isc_srte.data_type), coalesce(isc_rdb.character_maximum_length,isc_srte.character_maximum_length), coalesce(isc_rdb.numeric_precision,isc_srte.numeric_precision), coalesce(isc_rdb.numeric_scale,isc_srte.numeric_scale)
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
				when db_field =''code'' and label is null then ''ovc_code''
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
        select 'DynamicQuery', @DynamicQuery;


    exec sp_executesql @DynamicQuery;

     INSERT INTO dbo.[JOB_FLOW_LOG]
	    (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
	    VALUES(@BATCH_ID,@dataflow_name,@package_name,'START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

	  if @debug = 'true'
	    select '#missed_cols', * from #missed_cols;



    SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Adding Missed Columns';

    DECLARE @ColumnDef NVARCHAR(MAX);
	DECLARE @alterquery NVARCHAR(MAX) = 'ALTER TABLE '+@tgt_table_nm+' ADD ';

	DECLARE @Index INT = 1;
	DECLARE @Count INT = (SELECT COUNT(*) FROM #missed_cols );

	IF @Count is null or @Count = 0
    BEGIN
        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
	    INSERT INTO dbo.[JOB_FLOW_LOG]
	    (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
	    VALUES(@BATCH_ID,@dataflow_name,@package_name,'SKIPPED',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
                RETURN;
    END



--	WHILE @Index <= @Count
--    BEGIN
--	    -- Fetch the column name for the current iteration
--        SELECT @ColumnDef = col_nm + ' '+  col_data_type +
--            CASE
--                WHEN col_character_maximum_length IS NOT NULL THEN '(' +
--                                                                   CASE WHEN col_character_maximum_length = -1 THEN 'MAX' ELSE CAST(col_character_maximum_length AS NVARCHAR) END
--                    + ')'
--                WHEN col_data_type IN ('decimal', 'numeric') THEN '(' + CAST(col_numeric_precision AS NVARCHAR) + ',' + CAST(col_numeric_scale AS NVARCHAR) + ')'
--                ELSE ''
--            END
--        FROM (
--                 SELECT
--                     col_nm,
--                     col_data_type,
--                     col_character_maximum_length,
--                     col_numeric_precision,
--                     col_numeric_scale,
--                     ROW_NUMBER() OVER (ORDER BY col_nm) AS RowNum
--                 FROM  #missed_cols
--             ) AS OrderedTable
--        WHERE RowNum = @Index;
--
--        -- Add the column name to the dynamic query - @alterquery
--        SET @alterquery = @alterquery + @ColumnDef;
--
--	    -- Add a comma if it's not the last column
--	    IF @Index < @Count
--	        SET @alterquery = @alterquery + ', ';
--
--	    -- Increment the index
--	    SET @Index = @Index + 1;
--    END


	--alternate approach which didn't work
--	DECLARE @alterquery NVARCHAR(MAX);
	set @alterquery = 'ALTER TABLE '+ @tgt_table_nm + ' ADD ' + (select STRING_AGG( col_nm + ' ' +  col_data_type +
	    CASE
	        WHEN col_CHARACTER_MAXIMUM_LENGTH IS NOT NULL THEN '(' +
	            CASE WHEN col_CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(col_CHARACTER_MAXIMUM_LENGTH AS NVARCHAR) END
	        + ')'
	        WHEN col_data_type IN ('decimal', 'numeric') THEN '(' + CAST(col_NUMERIC_PRECISION AS NVARCHAR) + ',' + CAST(col_NUMERIC_SCALE AS NVARCHAR) + ')'
	        ELSE ''
	    END, ', ') from #missed_cols);

	-- Print or execute the generated SQL

    if @debug = 'true'
        select 'alterquery', @alterquery;

    exec sp_executesql @alterquery;

    INSERT INTO dbo.[JOB_FLOW_LOG]
	    (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
	    VALUES(@BATCH_ID,@dataflow_name,@package_name,'START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

END TRY
    BEGIN CATCH
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count] )
    VALUES( @Batch_id, @dataflow_name, @package_name, 'ERROR', @Proc_Step_no, 'ERROR - '+@Proc_Step_name, 'Step -'+CAST(@Proc_Step_no AS varchar(3))+' -'+CAST(@ErrorMessage AS varchar(500)), 0 );
    RETURN -1;

END CATCH;
END