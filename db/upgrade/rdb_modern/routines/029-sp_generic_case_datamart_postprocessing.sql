CREATE OR ALTER PROCEDURE [dbo].[sp_generic_case_datamart_postprocessing]
    @phc_ids nvarchar(max),
    @debug bit = 'false'
AS

BEGIN

    /*
     * [Description]
     * This stored procedure is handles event based updates to Generic_Case datamart.
     * 1. Receives input list of public_health_case_uids. .
     * 2. Uses v_nrt_inv_keys_attrs_mapping to get the records. Had to hard code 'INV110' into this proc to exclude it as it is not included in the original SAS proc
     * 3. Pivots the data to transform the col_nm values obtained for each code into column
     * 4. The pivoted data is used to insert and also update into the datamart on the INVESTIGATION_KEY.
     * */


    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyyyMMddHHmmss')) as bigint);
    PRINT @batch_id;
    DECLARE @RowCount_no int;
    DECLARE @Proc_Step_no float= 0;
    DECLARE @Proc_Step_Name varchar(200)= '';
    DECLARE @datamart_nm VARCHAR(100) = 'GENERIC_CASE_DATAMART';

    DECLARE @inv_form_cd VARCHAR(100) = 'INV_FORM_GEN%';
    DECLARE @tgt_table_nm VARCHAR(50) = 'Generic_Case';

BEGIN TRY

        SET @Proc_Step_Name = 'SP_Start';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;



        BEGIN TRANSACTION;

        INSERT INTO dbo.job_flow_log ( batch_id
                                     , [Dataflow_Name]
                                     , [package_Name]
                                     , [Status_Type]
                                     , [step_number]
                                     , [step_name]
                                     , [row_count]
                                     , [Msg_Description1])
        VALUES ( @batch_id
               , @datamart_nm
               , @datamart_nm
               , 'START'
               , @Proc_Step_no
               , @Proc_Step_Name
               , 0
               , LEFT('ID List-' + @phc_ids, 500));

        COMMIT TRANSACTION;

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #KEY_ATTR_INIT';

        IF OBJECT_ID('#KEY_ATTR_INIT', 'U') IS NOT NULL
            drop table #KEY_ATTR_INIT
        ;
        select
            public_health_case_uid,
            INVESTIGATION_KEY,
            CONDITION_KEY,
            PATIENT_KEY,
            INVESTIGATOR_KEY,
            PHYSICIAN_KEY,
            REPORTER_KEY,
            RPT_SRC_ORG_KEY,
            ADT_HSPTL_KEY,
            INV_ASSIGNED_DT_KEY,
            LDF_GROUP_KEY,
            GEOCODING_LOCATION_KEY,
            NULLIF(effective_duration_amt, '') as ILLNESS_DURATION,
            effective_duration_unit_cd as ILLNESS_DURATION_UNIT,
            pat_age_at_onset as PATIENT_AGE_AT_ONSET,
            pat_age_at_onset_unit_cd as PATIENT_AGE_AT_ONSET_UNIT,
            detection_method_cd as DETECTION_METHOD,
            detection_method_desc_txt as DETECTION_METHOD_OTHER
        INTO #KEY_ATTR_INIT
        from dbo.v_nrt_inv_keys_attrs_mapping
        where
            public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_ids, ','))
            AND investigation_form_cd like @inv_form_cd;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #KEY_ATTR_INIT;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #OBS_CODED_Generic_Case';

        IF OBJECT_ID('#OBS_CODED_Generic_Case', 'U') IS NOT NULL
            drop table #OBS_CODED_Generic_Case;

        select public_health_case_uid,
               unique_cd    as cd,
               col_nm,
               coded_response as response,
               rdb_table,
               db_field,
               label
        INTO #OBS_CODED_Generic_Case
        from dbo.v_rdb_obs_mapping rom
        left join INFORMATION_SCHEMA.COLUMNS isc
             on UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table)
             and UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
        WHERE (RDB_TABLE = @tgt_table_nm and db_field = 'code')
          and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_ids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL))
        ;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #OBS_CODED_Generic_Case;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #OBS_DATE_Generic_Case';

        IF OBJECT_ID('#OBS_DATE_Generic_Case', 'U') IS NOT NULL
            drop table #OBS_DATE_Generic_Case;

        select public_health_case_uid,
               unique_cd    as cd,
               col_nm,
               date_response as response,
               rdb_table,
               db_field
        INTO #OBS_DATE_Generic_Case
        from dbo.v_rdb_obs_mapping rom
         left join INFORMATION_SCHEMA.COLUMNS isc
                on UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table)
                and UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
        WHERE (RDB_TABLE = @tgt_table_nm and db_field = 'from_time')
          and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_ids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL))
         and  unique_cd != 'INV110';

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #OBS_DATE_Generic_Case;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #OBS_NUMERIC_Generic_Case';

        IF OBJECT_ID('#OBS_NUMERIC_Generic_Case', 'U') IS NOT NULL
            drop table #OBS_NUMERIC_Generic_Case;

        select
            rom.public_health_case_uid,
            rom.unique_cd    as cd,
            rom.col_nm,
            rom.numeric_response as response,
            rom.rdb_table,
            rom.db_field,
            CASE
                WHEN isc.DATA_TYPE = 'numeric' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS NUMERIC(' + CAST(isc.NUMERIC_PRECISION as NVARCHAR(5)) + ',' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + '))'
                WHEN isc.DATA_TYPE LIKE '%int' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS ' + isc.DATA_TYPE + ')'
                WHEN isc.DATA_TYPE IN ('varchar', 'nvarchar') THEN 'CAST(ovn.' + QUOTENAME(col_nm) + ' AS ' + isc.DATA_TYPE + '(' + CAST(isc.CHARACTER_MAXIMUM_LENGTH as NVARCHAR(5)) + '))'
                ELSE 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ',5) AS NUMERIC(15,5))'
            END AS converted_column
        into #OBS_NUMERIC_Generic_Case
        from dbo.v_rdb_obs_mapping rom
        left join
            INFORMATION_SCHEMA.COLUMNS isc
            ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table)
            AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
        WHERE (RDB_TABLE = @tgt_table_nm and db_field = 'numeric_value_1')
          and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_ids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL))
        ;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #OBS_NUMERIC_Generic_Case;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Exec procedure: dbo.sp_alter_datamart_schema_postprocessing';
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, 0);

        exec sp_alter_datamart_schema_postprocessing @batch_id, @datamart_nm, @tgt_table_nm, @debug;




        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'UPDATE dbo.'+@tgt_table_nm;

        -- variables for the column lists
        -- must be ordered the same as those used in the insert statement
        DECLARE @obscoded_columns NVARCHAR(MAX) = '';
        SELECT @obscoded_columns = COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm), '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_Generic_Case) AS cols;

        DECLARE @obsnum_columns NVARCHAR(MAX) = '';
        SELECT @obsnum_columns = COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm), '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_NUMERIC_Generic_Case) AS cols;

        DECLARE @obsdate_columns NVARCHAR(MAX) = '';
        SELECT @obsdate_columns = COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm), '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_DATE_Generic_Case)  AS cols;



       DECLARE @Update_sql NVARCHAR(MAX) = '';

       SET @Update_sql = '
       UPDATE tgt
       SET
       tgt.INVESTIGATION_KEY = src.INVESTIGATION_KEY,
       tgt.CONDITION_KEY = src.CONDITION_KEY,
       tgt.PATIENT_KEY = src.PATIENT_KEY,
       tgt.INVESTIGATOR_KEY = src.INVESTIGATOR_KEY,
       tgt.PHYSICIAN_KEY = src.PHYSICIAN_KEY,
       tgt.REPORTER_KEY = src.REPORTER_KEY,
       tgt.RPT_SRC_ORG_KEY = src.RPT_SRC_ORG_KEY,
	    tgt.ADT_HSPTL_KEY = src.ADT_HSPTL_KEY,
       tgt.INV_ASSIGNED_DT_KEY = src.INV_ASSIGNED_DT_KEY,
       tgt.LDF_GROUP_KEY = src.LDF_GROUP_KEY,
       tgt.GEOCODING_LOCATION_KEY = src.GEOCODING_LOCATION_KEY,
       tgt.ILLNESS_DURATION = src.ILLNESS_DURATION,
       tgt.ILLNESS_DURATION_UNIT = src.ILLNESS_DURATION_UNIT,
       tgt.PATIENT_AGE_AT_ONSET = case when src.PATIENT_AGE_AT_ONSET is not null and len(src.PATIENT_AGE_AT_ONSET)=0 then NULL else src.PATIENT_AGE_AT_ONSET end ,
       tgt.PATIENT_AGE_AT_ONSET_UNIT = src.PATIENT_AGE_AT_ONSET_UNIT,
       tgt.DETECTION_METHOD = src.DETECTION_METHOD,
       tgt.DETECTION_METHOD_OTHER = src.DETECTION_METHOD_OTHER'
 		+ CASE
	       	WHEN @obscoded_columns != '' THEN ',' + (SELECT STRING_AGG('tgt.' + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)) + ' = ovc.' + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)),',')
	              FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_Generic_Case) as cols)
	       	ELSE ''
		END
		+ CASE
	      WHEN @obsnum_columns != '' THEN ',' + (SELECT STRING_AGG('tgt.' + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)) +  ' = ' + CAST(converted_column AS NVARCHAR(MAX)),  ',')
                 FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_Generic_Case) as cols)
          ELSE ''
		END
		+ CASE
	        WHEN @obsdate_columns != '' THEN ',' + (SELECT STRING_AGG('tgt.' + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)) + ' = ovd.' + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)),',')
	               FROM (SELECT DISTINCT col_nm FROM #OBS_DATE_Generic_Case) as cols)
	        ELSE ''
    	END
       + '
       FROM
       #KEY_ATTR_INIT src
       LEFT OUTER JOIN dbo.'+@tgt_table_nm+' tgt
           on src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY'
       + CASE
             WHEN @obscoded_columns != '' THEN
	        '
	        LEFT OUTER JOIN (
	        SELECT public_health_case_uid, ' + @obscoded_columns + '
	        FROM (
	            SELECT
	                public_health_case_uid,
	                col_nm,
	                response
	            FROM
	                #OBS_CODED_Generic_Case
	                where public_health_case_uid IS NOT NULL
	        ) AS SourceData
	        PIVOT (
	            MAX(response)
	            FOR col_nm IN (' + @obscoded_columns + ')
	        ) AS PivotTable) ovc
	        ON ovc.public_health_case_uid = src.public_health_case_uid'
       	ELSE ' '
       END
       + CASE
             WHEN @obsnum_columns != '' THEN
	        '
	        LEFT OUTER JOIN(
	        SELECT public_health_case_uid, ' + @obsnum_columns + '
	        FROM (
	            SELECT
	                public_health_case_uid,
	                col_nm,
	                response
	            FROM
	                #OBS_NUMERIC_Generic_Case
	                where public_health_case_uid IS NOT NULL
	        ) AS SourceData
	        PIVOT (
	            MAX(response)
	            FOR col_nm IN (' + @obsnum_columns + ')
	        ) AS PivotTable) ovn
	        ON ovn.public_health_case_uid = src.public_health_case_uid'
       	ELSE ' '
       END
       + CASE
             WHEN @obsdate_columns != '' THEN
	        '
	        LEFT OUTER JOIN (
	        SELECT public_health_case_uid, ' + @obsdate_columns + '
	        FROM (
	            SELECT
	                public_health_case_uid,
	                col_nm,
	                response
	            FROM
	                #OBS_DATE_Generic_Case
	                where public_health_case_uid IS NOT NULL
	        ) AS SourceData
	        PIVOT (
	            MAX(response)
	            FOR col_nm IN (' + @obsdate_columns + ')
	        ) AS PivotTable) ovd
	        ON ovd.public_health_case_uid = src.public_health_case_uid'
       	ELSE ' '
       END
       + ' WHERE
       tgt.INVESTIGATION_KEY IS NOT NULL
       AND src.public_health_case_uid IS NOT NULL;';

       if
           @debug = 'true'
           select @Proc_Step_Name as step,  @Update_sql;
        exec sp_executesql @Update_sql;

       SELECT @RowCount_no = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'INSERT INTO dbo.'+@tgt_table_nm;


        -- Variables for the columns in the insert select statement
        -- Must be ordered the same as the original column lists


        DECLARE @obsnum_insert_columns NVARCHAR(MAX) = '';
        SELECT @obsnum_insert_columns =  COALESCE(STRING_AGG(CAST(converted_column AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm), '')
            FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_Generic_Case) AS cols;



        DECLARE @Insert_sql NVARCHAR(MAX) = ''

        SET @Insert_sql = '
        INSERT INTO dbo.'+@tgt_table_nm+' (
	    	INVESTIGATION_KEY,
	        CONDITION_KEY,
	        PATIENT_KEY,
	        INVESTIGATOR_KEY,
	        PHYSICIAN_KEY,
	        REPORTER_KEY,
	        RPT_SRC_ORG_KEY,
	        ADT_HSPTL_KEY,
	        INV_ASSIGNED_DT_KEY,
	        LDF_GROUP_KEY,
	        GEOCODING_LOCATION_KEY,
	        ILLNESS_DURATION,
	        ILLNESS_DURATION_UNIT,
	        PATIENT_AGE_AT_ONSET,
	        PATIENT_AGE_AT_ONSET_UNIT,
	        DETECTION_METHOD,
	        DETECTION_METHOD_OTHER
        ' + CASE
                WHEN @obscoded_columns != '' THEN ',' + @obscoded_columns
            	ELSE ''
            END
          + CASE
                WHEN @obsnum_columns != '' THEN ',' + @obsnum_columns
            	ELSE ''
            END
          + CASE
                WHEN @obsdate_columns != '' THEN ',' + @obsdate_columns
            	ELSE ''
            END +
          ') SELECT
            src.INVESTIGATION_KEY,
	        src.CONDITION_KEY,
	        src.PATIENT_KEY,
	        src.INVESTIGATOR_KEY,
	        src.PHYSICIAN_KEY,
	        src.REPORTER_KEY,
	        src.RPT_SRC_ORG_KEY,
			src.ADT_HSPTL_KEY,
	        src.INV_ASSIGNED_DT_KEY,
	        src.LDF_GROUP_KEY,
	        src.GEOCODING_LOCATION_KEY,
	        src.ILLNESS_DURATION,
	        src.ILLNESS_DURATION_UNIT,
	        case when src.PATIENT_AGE_AT_ONSET is not null and len(src.PATIENT_AGE_AT_ONSET)=0 then NULL else src.PATIENT_AGE_AT_ONSET end as PATIENT_AGE_AT_ONSET,
	        src.PATIENT_AGE_AT_ONSET_UNIT,
	        src.DETECTION_METHOD,
	        src.DETECTION_METHOD_OTHER
          ' + CASE
                WHEN @obscoded_columns != '' THEN ',' + @obscoded_columns
            	ELSE ''
            END
         	+ CASE
                WHEN @obsnum_columns != '' THEN ',' + @obsnum_insert_columns
            	ELSE ''
            END
         	+ CASE
                WHEN @obsdate_columns != '' THEN ',' + @obsdate_columns
            	ELSE ''
            END
         	+
            '
			  FROM #KEY_ATTR_INIT src
              LEFT OUTER JOIN (SELECT INVESTIGATION_KEY FROM dbo. ' + @tgt_table_nm + ') tgt
              ON src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY
            '
            + CASE
	              WHEN @obscoded_columns != '' THEN
		        '
				LEFT OUTER JOIN (
		        SELECT public_health_case_uid, ' + @obscoded_columns + '
		        FROM (
		            SELECT
		                public_health_case_uid,
		                col_nm,
		                response
		            FROM
		                #OBS_CODED_Generic_Case
		                where public_health_case_uid IS NOT NULL

		        ) AS SourceData
		        PIVOT (
		            MAX(response)
		            FOR col_nm IN (' + @obscoded_columns + ')
		        ) AS PivotTable) ovc
		        ON ovc.public_health_case_uid = src.public_health_case_uid'
        		ELSE ' '
        	END
	        + CASE
	              WHEN @obsnum_columns != '' THEN
		        '
				LEFT OUTER JOIN (
		        SELECT public_health_case_uid, ' + @obsnum_columns + '
		        FROM (
		            SELECT
		                public_health_case_uid,
		                col_nm,
		                response
		            FROM
		                #OBS_NUMERIC_Generic_Case
		                where public_health_case_uid IS NOT NULL

		        ) AS SourceData
		        PIVOT (
		            MAX(response)
		            FOR col_nm IN (' + @obsnum_columns + ')
		        ) AS PivotTable) ovn
		        ON ovn.public_health_case_uid = src.public_health_case_uid'
	        	ELSE ' '
	        END
        	+ CASE
              	WHEN @obsdate_columns != '' THEN
		        '
				LEFT OUTER JOIN (
		        SELECT public_health_case_uid, ' + @obsdate_columns + '
		        FROM (
		            SELECT
		                public_health_case_uid,
		                col_nm,
		                response
		            FROM
		                #OBS_DATE_Generic_Case
		                where public_health_case_uid IS NOT NULL
		        ) AS SourceData
		        PIVOT (
		            MAX(response)
		            FOR col_nm IN (' + @obsdate_columns + ')
		        ) AS PivotTable) ovd
		        ON ovd.public_health_case_uid = src.public_health_case_uid'
        		ELSE ' '
        	END
        	+  ' WHERE tgt.INVESTIGATION_KEY IS NULL
        		AND src.public_health_case_uid IS NOT NULL';


        if
            @debug = 'true'
            select @Proc_Step_Name as step, @Insert_sql;

        exec sp_executesql @Insert_sql;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @datamart_nm, @datamart_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        INSERT INTO [dbo].[job_flow_log]
        (batch_id,
         [Dataflow_Name],
         [package_Name],
         [Status_Type],
         [step_number],
         [step_name],
         [row_count]
        )
        VALUES
            (@batch_id,
             @datamart_nm,
             @datamart_nm,
             'COMPLETE',
             @Proc_Step_no,
             @Proc_Step_name,
             @RowCount_no
            );
        COMMIT TRANSACTION;


    END TRY


    BEGIN CATCH
        IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION;
            END;
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count] )
        VALUES( @Batch_id, @datamart_nm, @datamart_nm, 'ERROR', @Proc_Step_no, 'ERROR - '+@Proc_Step_name, 'Step -'+CAST(@Proc_Step_no AS varchar(3))+' -'+CAST(@ErrorMessage AS varchar(500)), 0 );
        RETURN -1;

    END CATCH;
END;