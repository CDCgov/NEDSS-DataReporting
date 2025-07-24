IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_rubella_case_datamart_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_rubella_case_datamart_postprocessing]
END
GO 

CREATE PROCEDURE dbo.sp_rubella_case_datamart_postprocessing @phc_uids nvarchar(max),
                                                                  @debug bit = 'false'
as

BEGIN

    DECLARE
        @RowCount_no INT;
    DECLARE
        @Proc_Step_no FLOAT = 0;
    DECLARE
        @Proc_Step_Name VARCHAR(200) = '';
    DECLARE
        @batch_id BIGINT;
    SET
        @batch_id = cast((format(getdate(), 'yyMMddHHmmssffff')) as bigint);

    -- condition for investigation_form_cd uses the LIKE operator for Rubella_Case, so % is included
    DECLARE
        @inv_form_cd VARCHAR(100) = 'INV_FORM_RUB%';

    -- used in conditions for temp table queries and the dynamic sql
    DECLARE
        @tgt_table_nm VARCHAR(50) = 'Rubella_Case';

    -- used in the logging statements
    DECLARE
        @datamart_nm VARCHAR(100) = 'RUBELLA_CASE_DATAMART';

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET
            @Proc_Step_Name = 'SP_Start';

        BEGIN
            TRANSACTION;

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
               , LEFT('ID List-' + @phc_uids, 500));

        COMMIT TRANSACTION;

        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = ' GENERATING #KEY_ATTR_INIT';

            IF OBJECT_ID('#KEY_ATTR_INIT', 'U') IS NOT NULL
            drop table #KEY_ATTR_INIT;

            select public_health_case_uid,
                   transmission_mode_cd AS transmission_setting,
                   INVESTIGATION_KEY,
                   CONDITION_KEY,
                   patient_key,
                   Investigator_key,
                   Physician_key,
                   Reporter_key,
                   Rpt_Src_Org_key,
                   ADT_HSPTL_KEY,
                   Inv_Assigned_dt_key,
                   LDF_GROUP_KEY,
                   GEOCODING_LOCATION_KEY
            INTO #KEY_ATTR_INIT
            from dbo.v_nrt_inv_keys_attrs_mapping
            where public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ','))
              AND investigation_form_cd LIKE @inv_form_cd;

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #KEY_ATTR_INIT;

            SELECT @RowCount_no = @@ROWCOUNT;


            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #OBS_CODED_Rubella_Case';

            IF OBJECT_ID('#OBS_CODED_Rubella_Case', 'U') IS NOT NULL
            drop table #OBS_CODED_Rubella_Case;


            select public_health_case_uid,
                   unique_cd      as cd,
                   col_nm,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.label,
                   coded_response as response
            INTO #OBS_CODED_Rubella_Case
            from dbo.v_rdb_obs_mapping rom
            LEFT JOIN
                INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table)
                AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @tgt_table_nm and db_field = 'code'
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_CODED_Rubella_Case;



            SELECT @RowCount_no = @@ROWCOUNT;



            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = ' GENERATING #OBS_TXT_Rubella_Case';

            IF OBJECT_ID('#OBS_TXT_Rubella_Case', 'U') IS NOT NULL
            drop table #OBS_TXT_Rubella_Case;

            select public_health_case_uid,
                   unique_cd    as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   txt_response as response
            INTO #OBS_TXT_Rubella_Case
            from dbo.v_rdb_obs_mapping
            LEFT JOIN
                INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(RDB_table)
                AND UPPER(isc.COLUMN_NAME) = UPPER(col_nm)
            WHERE RDB_TABLE = @tgt_table_nm and db_field = 'value_txt'
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_TXT_Rubella_Case;

            SELECT @RowCount_no = @@ROWCOUNT;


            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = ' GENERATING #OBS_DATE_Rubella_Case';

            IF OBJECT_ID('#OBS_DATE_Rubella_Case', 'U') IS NOT NULL
            drop table #OBS_DATE_Rubella_Case;

            select public_health_case_uid,
                   unique_cd     as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   date_response as response
            INTO #OBS_DATE_Rubella_Case
            from dbo.v_rdb_obs_mapping
            LEFT JOIN
                INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(RDB_table)
                AND UPPER(isc.COLUMN_NAME) = UPPER(col_nm)
            WHERE (RDB_TABLE = @tgt_table_nm and db_field = 'from_time' or unique_cd in ('INV132','INV133'))
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_DATE_Rubella_Case;

            SELECT @RowCount_no = @@ROWCOUNT;


            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = ' GENERATING #OBS_NUMERIC_Rubella_Case';

            IF OBJECT_ID('#OBS_NUMERIC_Rubella_Case', 'U') IS NOT NULL
            drop table #OBS_NUMERIC_Rubella_Case;


            select rom.public_health_case_uid,
                   rom.unique_cd        as cd,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.col_nm,
                   rom.numeric_response as response,
                   CASE WHEN isc.DATA_TYPE = 'numeric' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS NUMERIC(' + CAST(isc.NUMERIC_PRECISION as NVARCHAR(5)) + ',' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + '))'
                        WHEN isc.DATA_TYPE LIKE '%int' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS ' + isc.DATA_TYPE + ')'
                    WHEN isc.DATA_TYPE IN ('varchar', 'nvarchar') THEN 'CAST(ovn.' + QUOTENAME(col_nm) + ' AS ' + isc.DATA_TYPE + '(' + CAST(isc.CHARACTER_MAXIMUM_LENGTH as NVARCHAR(5)) + '))'
                    ELSE 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ',5) AS NUMERIC(15,5))'
                END AS converted_column
            INTO #OBS_NUMERIC_Rubella_Case
            from dbo.v_rdb_obs_mapping rom
            LEFT JOIN
                INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table)
                AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE rom.RDB_TABLE = @tgt_table_nm and rom.db_field = 'numeric_value_1'
            and (rom.public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_NUMERIC_Rubella_Case;

            SELECT @RowCount_no = @@ROWCOUNT;


            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;


            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'CHECKING FOR NEW COLUMNS';

            -- run procedure for checking target table schema vs results of temp tables above
            exec sp_alter_datamart_schema_postprocessing @batch_id, @datamart_nm, @tgt_table_nm, @debug;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);


        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'UPDATE dbo.' + @tgt_table_nm;

            -- variables for the column lists
            -- must be ordered the same as those used in the insert statement
            DECLARE @obscoded_columns NVARCHAR(MAX) = '';
            SELECT @obscoded_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_Rubella_Case) AS cols;

            DECLARE @obsnum_columns NVARCHAR(MAX) = '';
            SELECT @obsnum_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_NUMERIC_Rubella_Case) AS cols;

            DECLARE @obstxt_columns NVARCHAR(MAX) = '';
            SELECT @obstxt_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_TXT_Rubella_Case) AS cols;

            DECLARE @obsdate_columns NVARCHAR(MAX) = '';
            SELECT @obsdate_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_DATE_Rubella_Case) AS cols;

            DECLARE @Update_sql NVARCHAR(MAX) = '';

            SET @Update_sql = '
        UPDATE tgt
        SET
        tgt.TRANSMISSION_SETTING = src.TRANSMISSION_SETTING,
        tgt.INVESTIGATION_KEY = src.INVESTIGATION_KEY,
        tgt.CONDITION_KEY = src.CONDITION_KEY,
        tgt.patient_key = src.patient_key,
        tgt.Investigator_key = src.Investigator_key,
        tgt.Physician_key = src.Physician_key,
        tgt.Reporter_key = src.Reporter_key,
        tgt.Rpt_Src_Org_key = src.Rpt_Src_Org_key,
        tgt.ADT_HSPTL_KEY = src.ADT_HSPTL_KEY,
        tgt.Inv_Assigned_dt_key = src.Inv_Assigned_dt_key,
        tgt.LDF_GROUP_KEY = src.LDF_GROUP_KEY,
        tgt.GEOCODING_LOCATION_KEY = src.GEOCODING_LOCATION_KEY
        ' + CASE
                WHEN @obscoded_columns != '' THEN ',' + (SELECT STRING_AGG('tgt.' +
                                                        CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)) +
                                                        ' = ovc.' +
                                                        CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)),
                                                        ',')
                    FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_Rubella_Case) as cols)
            ELSE '' END
                + CASE
                      WHEN @obsnum_columns != '' THEN ',' + (SELECT STRING_AGG('tgt.' +
                                                                                CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)) +
                                                                               ' = ' +
                                                                               CAST(converted_column AS NVARCHAR(MAX)),
                                                                               ',')
                                                             FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_Rubella_Case) as cols)
                      ELSE '' END
                + CASE
                      WHEN @obstxt_columns != '' THEN ',' + (SELECT STRING_AGG('tgt.' +
                                                                               CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)) +
                                                                               ' = ovt.' +
                                                                               CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)),
                                                                               ',')
                                                             FROM (SELECT DISTINCT col_nm FROM #OBS_TXT_Rubella_Case) as cols)
                      ELSE '' END
                + CASE
                      WHEN @obsdate_columns != '' THEN ',' + (SELECT STRING_AGG('tgt.' +
                                                                                CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)) +
                                                                                ' = ovd.' +
                                                                                CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)),
                                                                                ',')
                                                              FROM (SELECT DISTINCT col_nm FROM #OBS_DATE_Rubella_Case) as cols)
                      ELSE '' END +
                              ' FROM
                              #KEY_ATTR_INIT src
                              LEFT JOIN dbo. ' + @tgt_table_nm + ' tgt
                                  on src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY'
                + CASE
                      WHEN @obscoded_columns != '' THEN
                          ' LEFT JOIN (
                          SELECT public_health_case_uid, ' + @obscoded_columns + '
        FROM (
            SELECT
                public_health_case_uid,
                col_nm,
                response
            FROM
                #OBS_CODED_Rubella_Case
                WHERE public_health_case_uid IS NOT NULL
        ) AS SourceData
        PIVOT (
            MAX(response)
            FOR col_nm IN (' + @obscoded_columns + ')
        ) AS PivotTable) ovc
        ON ovc.public_health_case_uid = src.public_health_case_uid'
                      ELSE ' ' END +
                              + CASE
                                    WHEN @obsnum_columns != '' THEN
                                        ' LEFT JOIN (
                                        SELECT public_health_case_uid, ' + @obsnum_columns + '
        FROM (
            SELECT
                public_health_case_uid,
                col_nm,
                response
            FROM
                #OBS_NUMERIC_Rubella_Case
                WHERE public_health_case_uid IS NOT NULL
        ) AS SourceData
        PIVOT (
            MAX(response)
            FOR col_nm IN (' + @obsnum_columns + ')
        ) AS PivotTable) ovn
        ON ovn.public_health_case_uid = src.public_health_case_uid'
                                    ELSE ' ' END
                + CASE
                      WHEN @obstxt_columns != '' THEN
                          ' LEFT JOIN (
                          SELECT public_health_case_uid, ' + @obstxt_columns + '
        FROM (
            SELECT
                public_health_case_uid,
                col_nm,
                response
            FROM
                #OBS_TXT_Rubella_Case
                WHERE public_health_case_uid IS NOT NULL
        ) AS SourceData
        PIVOT (
            MAX(response)
            FOR col_nm IN (' + @obstxt_columns + ')
        ) AS PivotTable) ovt
        ON ovt.public_health_case_uid = src.public_health_case_uid'
                      ELSE ' ' END
                + CASE
                      WHEN @obsdate_columns != '' THEN
                          ' LEFT JOIN (
                          SELECT public_health_case_uid, ' + @obsdate_columns + '
        FROM (
            SELECT
                public_health_case_uid,
                col_nm,
                response
            FROM
                #OBS_DATE_Rubella_Case
                WHERE public_health_case_uid IS NOT NULL
        ) AS SourceData
        PIVOT (
            MAX(response)
            FOR col_nm IN (' + @obsdate_columns + ')
        ) AS PivotTable) ovd
        ON ovd.public_health_case_uid = src.public_health_case_uid'
                      ELSE ' ' END
                + ' WHERE
        tgt.INVESTIGATION_KEY IS NOT NULL
        AND src.public_health_case_uid IS NOT NULL;';

            if
                @debug = 'true'
                select @Proc_Step_Name as step, @Update_sql;

            exec sp_executesql @Update_sql;

            SELECT @RowCount_no = @@ROWCOUNT;


            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'INSERT INTO dbo.' + @tgt_table_nm;


        -- Variables for the columns in the insert select statement
        -- Must be ordered the same as the original column lists

        DECLARE @obsnum_insert_columns NVARCHAR(MAX) = '';
        SELECT @obsnum_insert_columns = COALESCE(
                STRING_AGG(CAST(converted_column AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm), '')
        FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_Rubella_Case) AS cols;


        DECLARE @Insert_sql NVARCHAR(MAX) = ''

        SET @Insert_sql = '
        INSERT INTO dbo. ' + @tgt_table_nm + ' (
        TRANSMISSION_SETTING,
        INVESTIGATION_KEY,
        CONDITION_KEY,
        patient_key,
        Investigator_key,
        Physician_key,
        Reporter_key,
        Rpt_Src_Org_key,
        ADT_HSPTL_KEY,
        Inv_Assigned_dt_key,
        LDF_GROUP_KEY,
        GEOCODING_LOCATION_KEY
        ' + CASE
                  WHEN @obscoded_columns != '' THEN ',' + @obscoded_columns
                  ELSE '' END
            + CASE
                  WHEN @obsnum_columns != '' THEN ',' + @obsnum_columns
                  ELSE '' END
            + CASE
                  WHEN @obstxt_columns != '' THEN ',' + @obstxt_columns
                  ELSE '' END
            + CASE
                  WHEN @obsdate_columns != '' THEN ',' + @obsdate_columns
                  ELSE '' END +
                          ') SELECT
                            src.TRANSMISSION_SETTING,
                            src.INVESTIGATION_KEY,
                            src.CONDITION_KEY,
                            src.patient_key,
                            src.Investigator_key,
                            src.Physician_key,
                            src.Reporter_key,
                            src.Rpt_Src_Org_key,
                            src.ADT_HSPTL_KEY,
                            src.Inv_Assigned_dt_key,
                            src.LDF_GROUP_KEY,
                            src.GEOCODING_LOCATION_KEY
            ' + CASE
            WHEN @obscoded_columns != '' THEN ',' + @obscoded_columns
                  ELSE '' END
            + CASE
                  WHEN @obsnum_columns != '' THEN ',' + @obsnum_insert_columns
                  ELSE '' END
            + CASE
                  WHEN @obstxt_columns != '' THEN ',' + @obstxt_columns
                  ELSE '' END
            + CASE
                  WHEN @obsdate_columns != '' THEN ',' + @obsdate_columns
                  ELSE '' END +
            ' FROM #KEY_ATTR_INIT src
            LEFT JOIN (SELECT INVESTIGATION_KEY FROM dbo. ' + @tgt_table_nm + ') tgt
                ON src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY
             '
            + CASE
                      WHEN @obscoded_columns != '' THEN
                          ' LEFT JOIN (
                          SELECT public_health_case_uid, ' + @obscoded_columns + '
        FROM (
            SELECT
                public_health_case_uid,
                col_nm,
                response
            FROM
                #OBS_CODED_Rubella_Case
                WHERE public_health_case_uid IS NOT NULL
        ) AS SourceData
        PIVOT (
            MAX(response)
            FOR col_nm IN (' + @obscoded_columns + ')
        ) AS PivotTable) ovc
        ON ovc.public_health_case_uid = src.public_health_case_uid'
                      ELSE ' ' END +
                              + CASE
                                    WHEN @obsnum_columns != '' THEN
                                        ' LEFT JOIN (
                                        SELECT public_health_case_uid, ' + @obsnum_columns + '
        FROM (
            SELECT
                public_health_case_uid,
                col_nm,
                response
            FROM
                #OBS_NUMERIC_Rubella_Case
                WHERE public_health_case_uid IS NOT NULL
        ) AS SourceData
        PIVOT (
            MAX(response)
            FOR col_nm IN (' + @obsnum_columns + ')
        ) AS PivotTable) ovn
        ON ovn.public_health_case_uid = src.public_health_case_uid'
                                    ELSE ' ' END
                + CASE
                      WHEN @obstxt_columns != '' THEN
                          ' LEFT JOIN (
                          SELECT public_health_case_uid, ' + @obstxt_columns + '
        FROM (
            SELECT
                public_health_case_uid,
                col_nm,
                response
            FROM
                #OBS_TXT_Rubella_Case
                WHERE public_health_case_uid IS NOT NULL
        ) AS SourceData
        PIVOT (
            MAX(response)
            FOR col_nm IN (' + @obstxt_columns + ')
        ) AS PivotTable) ovt
        ON ovt.public_health_case_uid = src.public_health_case_uid'
                      ELSE ' ' END
                + CASE
                      WHEN @obsdate_columns != '' THEN
                          ' LEFT JOIN (
                          SELECT public_health_case_uid, ' + @obsdate_columns + '
        FROM (
            SELECT
                public_health_case_uid,
                col_nm,
                response
            FROM
                #OBS_DATE_Rubella_Case
                WHERE public_health_case_uid IS NOT NULL
        ) AS SourceData
        PIVOT (
            MAX(response)
            FOR col_nm IN (' + @obsdate_columns + ')
        ) AS PivotTable) ovd
        ON ovd.public_health_case_uid = src.public_health_case_uid'
                      ELSE ' ' END
                + ' WHERE tgt.INVESTIGATION_KEY IS NULL
        AND src.public_health_case_uid IS NOT NULL';


        if
            @debug = 'true'
            select @Proc_Step_Name as step, @Insert_sql;

        exec sp_executesql @Insert_sql;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @datamart_nm, @datamart_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'COMPLETE', 999, 'COMPLETE', 0);
        
        SELECT
            CAST(NULL AS BIGINT) AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            CAST(NULL AS VARCHAR(30)) AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            CAST(NULL AS VARCHAR(200)) AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=0;

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

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
               , @datamart_nm
               , @datamart_nm
               , 'ERROR'
               , @Proc_Step_no
               , @Proc_Step_name
               , @FullErrorMessage
               , 0);


        SELECT
            0 AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            'Error' AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            @FullErrorMessage AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=1;

    END CATCH

END;
