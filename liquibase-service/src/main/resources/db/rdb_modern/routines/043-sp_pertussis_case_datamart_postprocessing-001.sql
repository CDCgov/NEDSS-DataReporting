CREATE OR ALTER PROCEDURE [dbo].[sp_pertussis_case_datamart_postprocessing]
    @phc_uids nvarchar(max),
    @debug bit = 'false'
AS

BEGIN
    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyyyMMddHHmmssffff')) as bigint);
    PRINT @batch_id;
    DECLARE @RowCount_no int;
    DECLARE @Proc_Step_no float= 0;
    DECLARE @Proc_Step_Name varchar(200) = '';
    DECLARE @datamart_nm VARCHAR(100) = 'PERTUSSIS_CASE_DATAMART';

    DECLARE @tgt_table_nm VARCHAR(50) = 'Pertussis_Case';
    DECLARE @prt_treatment_table_nm VARCHAR(50) = 'Pertussis_Treatment_Field';
    DECLARE @prt_src_table_nm VARCHAR(50) = 'Pertussis_Suspected_Source_Fld';


    DECLARE @inv_form_cd VARCHAR(100) = 'INV_FORM_PER%';

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
               , LEFT('ID List-' + @phc_uids, 500));

        COMMIT TRANSACTION;

        /*
            Note for Pertussis_Case and Pertussis_Suspected_Source_Fld target tables:
            In IMRDBMapping, Pertussis_Suspected_Source_Fld is not explicitly mapped. So,
            for these tables, it is necessary to filter out the codes that go to 
            Pertussis_Suspected_Source_Fld, so they don't get populated into Pertussis_Case.
            Likewise, the temp tables for Pertussis_Suspected_Source_Fld will have to include
            the necessary codes hardcoded.

            Pertussis_Treatment_Field is explicitly mapped in IMRDBMapping, so it 
            does not need to be accounted for with any hardcoded filtering.
        */
        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #OBS_CODED_PERTUSSIS_Case';

            IF OBJECT_ID('#OBS_CODED_PERTUSSIS_Case', 'U') IS NOT NULL
                drop table #OBS_CODED_PERTUSSIS_Case;

            SELECT public_health_case_uid,
                   unique_cd      as cd,
                   CASE WHEN unique_cd = 'PRT112' THEN 'BIRTH_WEIGHT_UNKNOWN'
                   ELSE col_nm
                   END AS col_nm,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.label,
                   CASE WHEN unique_cd = 'PRT112' and numeric_response = -1.00000 THEN 'Yes'
                   ELSE coded_response
                   END as response
            INTO #OBS_CODED_PERTUSSIS_Case
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE (RDB_TABLE = @tgt_table_nm and db_field = 'code' AND unique_cd NOT IN ('PRT075', 'PRT076', 'PRT077', 'PRT087')) or unique_cd = 'PRT112'
              AND (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_CODED_PERTUSSIS_Case;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = ' GENERATING #OBS_TXT_PERTUSSIS_Case';

            IF OBJECT_ID('#OBS_TXT_PERTUSSIS_Case', 'U') IS NOT NULL
                drop table #OBS_TXT_PERTUSSIS_Case;

            SELECT public_health_case_uid,
                   unique_cd    as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   txt_response as response
            INTO #OBS_TXT_PERTUSSIS_Case
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @tgt_table_nm and db_field = 'value_txt' and unique_cd != 'PRT078'
                AND (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_TXT_PERTUSSIS_Case;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_DATE_PERTUSSIS_Case';

            IF OBJECT_ID('#OBS_DATE_PERTUSSIS_Case', 'U') IS NOT NULL
                drop table #OBS_DATE_PERTUSSIS_Case;

            select public_health_case_uid,
                   unique_cd     as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   date_response as response
            INTO #OBS_DATE_PERTUSSIS_Case
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @tgt_table_nm and db_field = 'from_time' and unique_cd != 'PRT088'
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_DATE_PERTUSSIS_Case;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_NUMERIC_PERTUSSIS_Case';

            IF OBJECT_ID('#OBS_NUMERIC_PERTUSSIS_Case', 'U') IS NOT NULL
                drop table #OBS_NUMERIC_PERTUSSIS_Case;

            select rom.public_health_case_uid,
                   rom.unique_cd        as cd,
                   rom.col_nm,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.numeric_response as response,
                   CASE WHEN isc.DATA_TYPE = 'numeric' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS NUMERIC(' + CAST(isc.NUMERIC_PRECISION as NVARCHAR(5)) + ',' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + '))'
                        WHEN isc.DATA_TYPE LIKE '%int' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS ' + isc.DATA_TYPE + ')'
                        WHEN isc.DATA_TYPE IN ('varchar', 'nvarchar') THEN 'CAST(ovn.' + QUOTENAME(col_nm) + ' AS ' + isc.DATA_TYPE + '(' + CAST(isc.CHARACTER_MAXIMUM_LENGTH as NVARCHAR(5)) + '))'
                        ELSE 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ',5) AS NUMERIC(15,5))'
                       END AS converted_column
            INTO #OBS_NUMERIC_PERTUSSIS_Case
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE rom.RDB_TABLE = @tgt_table_nm and rom.db_field = 'numeric_value_1' AND unique_cd NOT IN ('PRT074', 'PRT112')
              and (rom.public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_NUMERIC_PERTUSSIS_Case;

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
                @PROC_STEP_NAME = 'GENERATING #OBS_CODED_PERTUSSIS_SUSPECTED_SOURCE_FLD';

            IF OBJECT_ID('#OBS_CODED_PERTUSSIS_SUSPECTED_SOURCE_FLD', 'U') IS NOT NULL
                drop table #OBS_CODED_PERTUSSIS_SUSPECTED_SOURCE_FLD;

            SELECT public_health_case_uid,
                   unique_cd      as cd,
                   col_nm,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.label,
                   rom.branch_id,
                   coded_response as response
            INTO #OBS_CODED_PERTUSSIS_SUSPECTED_SOURCE_FLD
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @tgt_table_nm and db_field = 'code' AND unique_cd IN ('PRT075', 'PRT076', 'PRT077', 'PRT087')
              AND (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_CODED_PERTUSSIS_SUSPECTED_SOURCE_FLD;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = ' GENERATING #OBS_TXT_PERTUSSIS_SUSPECTED_SOURCE_FLD';

            IF OBJECT_ID('#OBS_TXT_PERTUSSIS_SUSPECTED_SOURCE_FLD', 'U') IS NOT NULL
                drop table #OBS_TXT_PERTUSSIS_SUSPECTED_SOURCE_FLD;

            SELECT public_health_case_uid,
                   unique_cd    as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   rom.branch_id,
                   txt_response as response
            INTO #OBS_TXT_PERTUSSIS_SUSPECTED_SOURCE_FLD
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @tgt_table_nm and db_field = 'value_txt' and unique_cd  = 'PRT078'
                AND (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_TXT_PERTUSSIS_SUSPECTED_SOURCE_FLD;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_DATE_PERTUSSIS_SUSPECTED_SOURCE_FLD';

            IF OBJECT_ID('#OBS_DATE_PERTUSSIS_SUSPECTED_SOURCE_FLD', 'U') IS NOT NULL
                drop table #OBS_DATE_PERTUSSIS_SUSPECTED_SOURCE_FLD;

            select public_health_case_uid,
                   unique_cd     as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   branch_id,
                   date_response as response
            INTO #OBS_DATE_PERTUSSIS_SUSPECTED_SOURCE_FLD
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @tgt_table_nm and db_field = 'from_time' and unique_cd = 'PRT088'
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_DATE_PERTUSSIS_SUSPECTED_SOURCE_FLD;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_NUMERIC_PERTUSSIS_SUSPECTED_SOURCE_FLD';

            IF OBJECT_ID('#OBS_NUMERIC_PERTUSSIS_SUSPECTED_SOURCE_FLD', 'U') IS NOT NULL
                drop table #OBS_NUMERIC_PERTUSSIS_SUSPECTED_SOURCE_FLD;

            select rom.public_health_case_uid,
                   rom.unique_cd        as cd,
                   rom.col_nm,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.branch_id,
                   rom.numeric_response as response,
                   CASE WHEN isc.DATA_TYPE = 'numeric' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS NUMERIC(' + CAST(isc.NUMERIC_PRECISION as NVARCHAR(5)) + ',' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + '))'
                        WHEN isc.DATA_TYPE LIKE '%int' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS ' + isc.DATA_TYPE + ')'
                        WHEN isc.DATA_TYPE IN ('varchar', 'nvarchar') THEN 'CAST(ovn.' + QUOTENAME(col_nm) + ' AS ' + isc.DATA_TYPE + '(' + CAST(isc.CHARACTER_MAXIMUM_LENGTH as NVARCHAR(5)) + '))'
                        ELSE 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ',5) AS NUMERIC(15,5))'
                       END AS converted_column
            INTO #OBS_NUMERIC_PERTUSSIS_SUSPECTED_SOURCE_FLD
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE rom.RDB_TABLE = @tgt_table_nm and rom.db_field = 'numeric_value_1' AND unique_cd = 'PRT074'
              and (rom.public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_NUMERIC_PERTUSSIS_SUSPECTED_SOURCE_FLD;

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
                @PROC_STEP_NAME = 'GENERATING #OBS_CODED_PERTUSSIS_TREATMENT_FIELD';

            IF OBJECT_ID('#OBS_CODED_PERTUSSIS_TREATMENT_FIELD', 'U') IS NOT NULL
                drop table #OBS_CODED_PERTUSSIS_TREATMENT_FIELD;

            SELECT public_health_case_uid,
                   unique_cd      as cd,
                   col_nm,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.label,
                   rom.branch_id,
                   coded_response as response
            INTO #OBS_CODED_PERTUSSIS_TREATMENT_FIELD
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @prt_treatment_table_nm and db_field = 'code' 
              AND (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_CODED_PERTUSSIS_TREATMENT_FIELD;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = ' GENERATING #OBS_TXT_PERTUSSIS_TREATMENT_FIELD';

            IF OBJECT_ID('#OBS_TXT_PERTUSSIS_TREATMENT_FIELD', 'U') IS NOT NULL
                drop table #OBS_TXT_PERTUSSIS_TREATMENT_FIELD;

            SELECT public_health_case_uid,
                   unique_cd    as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   rom.branch_id,
                   txt_response as response
            INTO #OBS_TXT_PERTUSSIS_TREATMENT_FIELD
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @prt_treatment_table_nm and db_field = 'value_txt'
                AND (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_TXT_PERTUSSIS_TREATMENT_FIELD;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_DATE_PERTUSSIS_TREATMENT_FIELD';

            IF OBJECT_ID('#OBS_DATE_PERTUSSIS_TREATMENT_FIELD', 'U') IS NOT NULL
                drop table #OBS_DATE_PERTUSSIS_TREATMENT_FIELD;

            select public_health_case_uid,
                   unique_cd     as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   branch_id,
                   date_response as response
            INTO #OBS_DATE_PERTUSSIS_TREATMENT_FIELD
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @prt_treatment_table_nm and db_field = 'from_time' 
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_DATE_PERTUSSIS_TREATMENT_FIELD;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_NUMERIC_PERTUSSIS_TREATMENT_FIELD';

            IF OBJECT_ID('#OBS_NUMERIC_PERTUSSIS_TREATMENT_FIELD', 'U') IS NOT NULL
                drop table #OBS_NUMERIC_PERTUSSIS_TREATMENT_FIELD;

            select rom.public_health_case_uid,
                   rom.unique_cd        as cd,
                   rom.col_nm,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.branch_id,
                   rom.numeric_response as response,
                   CASE WHEN isc.DATA_TYPE = 'numeric' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS NUMERIC(' + CAST(isc.NUMERIC_PRECISION as NVARCHAR(5)) + ',' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + '))'
                        WHEN isc.DATA_TYPE LIKE '%int' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS ' + isc.DATA_TYPE + ')'
                        WHEN isc.DATA_TYPE IN ('varchar', 'nvarchar') THEN 'CAST(ovn.' + QUOTENAME(col_nm) + ' AS ' + isc.DATA_TYPE + '(' + CAST(isc.CHARACTER_MAXIMUM_LENGTH as NVARCHAR(5)) + '))'
                        ELSE 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ',5) AS NUMERIC(15,5))'
                       END AS converted_column
            INTO #OBS_NUMERIC_PERTUSSIS_TREATMENT_FIELD
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE rom.RDB_TABLE = @prt_treatment_table_nm and rom.db_field = 'numeric_value_1' 
              and (rom.public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_NUMERIC_PERTUSSIS_TREATMENT_FIELD;

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
                @PROC_STEP_NAME = 'GENERATING #OLD_TREATMENT_GRP_KEYS';

            IF OBJECT_ID('#OLD_TREATMENT_GRP_KEYS', 'U') IS NOT NULL
                drop table #OLD_TREATMENT_GRP_KEYS;

            SELECT PERTUSSIS_TREATMENT_GRP_KEY
            INTO #OLD_TREATMENT_GRP_KEYS
            FROM dbo.Pertussis_Case prt WITH (nolock)
            INNER JOIN dbo.INVESTIGATION inv WITH (nolock) ON inv.INVESTIGATION_KEY = prt.INVESTIGATION_KEY
            WHERE inv.CASE_UID IN (SELECT value FROM STRING_SPLIT(@phc_uids, ','))

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OLD_TREATMENT_GRP_KEYS;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #TMP_TREATMENT_GRP';

            IF OBJECT_ID('#TMP_TREATMENT_GRP', 'U') IS NOT NULL
                drop table #TMP_TREATMENT_GRP;

            SELECT DISTINCT public_health_case_uid,
                            COALESCE(PERTUSSIS_TREATMENT_GRP_KEY, 1) AS PERTUSSIS_TREATMENT_GRP_KEY
            INTO #TMP_TREATMENT_GRP
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN dbo.INVESTIGATION inv WITH (nolock) ON inv.CASE_UID=rom.public_health_case_uid
            LEFT JOIN dbo.Pertussis_Case prt WITH (nolock) ON prt.INVESTIGATION_KEY = inv.INVESTIGATION_KEY
            WHERE public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) AND RDB_table=@prt_treatment_table_nm;

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #TMP_TREATMENT_GRP;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #TREATMENT_IDS';

            IF OBJECT_ID('#TREATMENT_IDS', 'U') IS NOT NULL
                drop table #TREATMENT_IDS;

            WITH id_cte AS (
                SELECT public_health_case_uid, cd
                FROM #OBS_CODED_PERTUSSIS_TREATMENT_FIELD
                WHERE public_health_case_uid IS NOT NULL
                UNION ALL
                SELECT public_health_case_uid, cd
                FROM #OBS_NUMERIC_PERTUSSIS_TREATMENT_FIELD
                WHERE public_health_case_uid IS NOT NULL
                UNION ALL
                SELECT public_health_case_uid, cd
                FROM #OBS_DATE_PERTUSSIS_TREATMENT_FIELD
                WHERE public_health_case_uid IS NOT NULL
                UNION ALL
                SELECT public_health_case_uid, cd
                FROM #OBS_TXT_PERTUSSIS_TREATMENT_FIELD
                WHERE public_health_case_uid IS NOT NULL
            ),
                 ordered_selection AS
                     (SELECT public_health_case_uid,
                             cd,
                             ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, cd ORDER BY cd) as row_num
                      FROM id_cte)

            -- distinct here makes it to where we only keep row numbers 1 -> max row num for each phc
            SELECT DISTINCT ids.public_health_case_uid, ids.row_num
            INTO #TREATMENT_IDS
            FROM ordered_selection ids;

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #TREATMENT_IDS;

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
                @PROC_STEP_NAME = 'INSERTING INTO nrt_pertussis_treatment_group_key';

            DELETE FROM dbo.nrt_pertussis_treatment_group_key;
            INSERT INTO dbo.nrt_pertussis_treatment_group_key (public_health_case_uid)
            SELECT DISTINCT public_health_case_uid
            FROM #TMP_TREATMENT_GRP
            WHERE PERTUSSIS_TREATMENT_GRP_KEY = 1
            ORDER BY public_health_case_uid;

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
                @PROC_STEP_NAME = 'INSERTING INTO PERTUSSIS_TREATMENT_GROUP';


            INSERT INTO dbo.PERTUSSIS_TREATMENT_GROUP (PERTUSSIS_TREATMENT_GRP_KEY)
            SELECT PERTUSSIS_TREATMENT_GRP_KEY
            FROM dbo.nrt_pertussis_treatment_group_key;

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
                @PROC_STEP_NAME = 'UPDATING #TMP_TREATMENT_GRP';

            UPDATE #TMP_TREATMENT_GRP
            SET #TMP_TREATMENT_GRP.PERTUSSIS_TREATMENT_GRP_KEY = trt.PERTUSSIS_TREATMENT_GRP_KEY
            FROM dbo.nrt_pertussis_treatment_group_key trt
            WHERE trt.public_health_case_uid = #TMP_TREATMENT_GRP.public_health_case_uid;

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #TMP_TREATMENT_GRP;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERTING INTO nrt_pertussis_treatment_key';

            DELETE FROM dbo.nrt_pertussis_treatment_key;
            INSERT INTO dbo.nrt_pertussis_treatment_key
            (
                PERTUSSIS_TREATMENT_GRP_KEY,
                public_health_case_uid,
                selection_number
            )
            SELECT
                trt.PERTUSSIS_TREATMENT_GRP_KEY,
                ids.public_health_case_uid,
                ids.row_num AS selection_number
            FROM #TREATMENT_IDS ids
            LEFT JOIN #TMP_TREATMENT_GRP trt
                ON ids.public_health_case_uid = trt.public_health_case_uid;

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
                @PROC_STEP_NAME = 'GENERATING #OLD_SRC_GRP_KEYS';

            IF OBJECT_ID('#OLD_SRC_GRP_KEYS', 'U') IS NOT NULL
                drop table #OLD_SRC_GRP_KEYS;

            SELECT PERTUSSIS_SUSPECT_SRC_GRP_KEY
            INTO #OLD_SRC_GRP_KEYS
            FROM dbo.Pertussis_Case prt WITH (nolock)
            INNER JOIN dbo.INVESTIGATION inv WITH (nolock) ON inv.INVESTIGATION_KEY = prt.INVESTIGATION_KEY
            WHERE inv.CASE_UID IN (SELECT value FROM STRING_SPLIT(@phc_uids, ','))

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OLD_SRC_GRP_KEYS;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #TMP_SRC_GRP';

            IF OBJECT_ID('#TMP_SRC_GRP', 'U') IS NOT NULL
                drop table #TMP_SRC_GRP;

            SELECT DISTINCT public_health_case_uid,
                            COALESCE(PERTUSSIS_SUSPECT_SRC_GRP_KEY, 1) AS PERTUSSIS_SUSPECT_SRC_GRP_KEY
            INTO #TMP_SRC_GRP
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN dbo.INVESTIGATION inv WITH (nolock) ON inv.CASE_UID=rom.public_health_case_uid
            LEFT JOIN dbo.Pertussis_Case prt WITH (nolock) ON prt.INVESTIGATION_KEY = inv.INVESTIGATION_KEY
            WHERE public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ','))
            AND unique_cd IN (
                --coded
                'PRT075', 
                'PRT076',	
                'PRT077',	
                'PRT087',
                --numeric
                'PRT074',
                --date
                'PRT088',
                --txt
                'PRT078'	
            );

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #TMP_SRC_GRP;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #SOURCE_IDS';

            IF OBJECT_ID('#SOURCE_IDS', 'U') IS NOT NULL
                drop table #SOURCE_IDS;

            WITH id_cte AS (
                SELECT public_health_case_uid, cd
                FROM #OBS_CODED_PERTUSSIS_SUSPECTED_SOURCE_FLD
                WHERE public_health_case_uid IS NOT NULL
                UNION ALL
                SELECT public_health_case_uid, cd
                FROM #OBS_TXT_PERTUSSIS_SUSPECTED_SOURCE_FLD
                WHERE public_health_case_uid IS NOT NULL
                UNION ALL
                SELECT public_health_case_uid, cd
                FROM #OBS_DATE_PERTUSSIS_SUSPECTED_SOURCE_FLD
                WHERE public_health_case_uid IS NOT NULL
                UNION ALL
                SELECT public_health_case_uid, cd
                FROM #OBS_NUMERIC_PERTUSSIS_SUSPECTED_SOURCE_FLD
                WHERE public_health_case_uid IS NOT NULL
            ),
                 ordered_selection AS
                     (SELECT public_health_case_uid,
                             cd,
                             ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, cd ORDER BY cd) as row_num
                      FROM id_cte)

            -- distinct here makes it to where we only keep row numbers 1 -> max row num for each phc
            SELECT DISTINCT ids.public_health_case_uid, ids.row_num
            INTO #SOURCE_IDS
            FROM ordered_selection ids;

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #SOURCE_IDS;

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
                @PROC_STEP_NAME = 'INSERTING INTO nrt_pertussis_source_group_key';

            DELETE FROM dbo.nrt_pertussis_source_group_key;
            INSERT INTO dbo.nrt_pertussis_source_group_key (public_health_case_uid)
            SELECT DISTINCT public_health_case_uid
            FROM #TMP_SRC_GRP
            WHERE PERTUSSIS_SUSPECT_SRC_GRP_KEY = 1
            ORDER BY public_health_case_uid;

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
                @PROC_STEP_NAME = 'INSERTING INTO dbo.PERTUSSIS_SUSPECTED_SRC_GROUP';


            INSERT INTO dbo.PERTUSSIS_SUSPECTED_SOURCE_GRP (PERTUSSIS_SUSPECT_SRC_GRP_KEY)
            SELECT PERTUSSIS_SUSPECT_SRC_GRP_KEY
            FROM dbo.nrt_pertussis_source_group_key;

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
                @PROC_STEP_NAME = 'UPDATING #TMP_SRC_GRP';

            UPDATE #TMP_SRC_GRP
            SET #TMP_SRC_GRP.PERTUSSIS_SUSPECT_SRC_GRP_KEY = prt.PERTUSSIS_SUSPECT_SRC_GRP_KEY
            FROM dbo.nrt_pertussis_source_group_key prt
            WHERE prt.public_health_case_uid = #TMP_SRC_GRP.public_health_case_uid;

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #TMP_SRC_GRP;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERTING INTO nrt_pertussis_source_key';

            DELETE FROM dbo.nrt_pertussis_source_key;
            INSERT INTO dbo.nrt_pertussis_source_key
            (
                PERTUSSIS_SUSPECT_SRC_GRP_KEY,
                public_health_case_uid,
                selection_number
            )
            SELECT
                prt.PERTUSSIS_SUSPECT_SRC_GRP_KEY,
                ids.public_health_case_uid,
                ids.row_num AS selection_number
            FROM #SOURCE_IDS ids
            LEFT JOIN #TMP_SRC_GRP prt
                ON ids.public_health_case_uid = prt.public_health_case_uid;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #KEY_ATTR_INIT';

            IF OBJECT_ID('#KEY_ATTR_INIT', 'U') IS NOT NULL
                drop table #KEY_ATTR_INIT;

            SELECT
                map.public_health_case_uid,
                INVESTIGATOR_KEY,
                PHYSICIAN_KEY,
                PATIENT_KEY,
                REPORTER_KEY,
                DAYCARE_FACILITY_KEY,
                INV_ASSIGNED_DT_KEY,
                COALESCE(srg.PERTUSSIS_SUSPECT_SRC_GRP_KEY, 1) AS PERTUSSIS_SUSPECT_SRC_GRP_KEY,
                COALESCE(trg.PERTUSSIS_TREATMENT_GRP_KEY, 1) AS PERTUSSIS_TREATMENT_GRP_KEY,
                INVESTIGATION_KEY,
                ADT_HSPTL_KEY,
                RPT_SRC_ORG_KEY,
                CONDITION_KEY,
                LDF_GROUP_KEY,
                GEOCODING_LOCATION_KEY
            INTO #KEY_ATTR_INIT
            FROM dbo.v_nrt_inv_keys_attrs_mapping map
            LEFT JOIN #TMP_SRC_GRP srg ON srg.public_health_case_uid=map.public_health_case_uid
            LEFT JOIN #TMP_TREATMENT_GRP trg ON trg.public_health_case_uid=map.public_health_case_uid
            WHERE map.public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ','))
              AND investigation_form_cd like @inv_form_cd;

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #KEY_ATTR_INIT;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'CHECKING FOR NEW COLUMNS - ' + @tgt_table_nm;

        -- run procedure for checking target table schema vs results of temp tables above
        EXEC sp_alter_datamart_schema_postprocessing @batch_id, @datamart_nm, @tgt_table_nm, @debug;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'CHECKING FOR NEW COLUMNS - ' + @prt_treatment_table_nm;

        -- run procedure for checking target table schema vs results of temp tables above (treatment)
        exec sp_alter_datamart_schema_postprocessing @batch_id, @datamart_nm, @prt_treatment_table_nm, @debug;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'CHECKING FOR NEW COLUMNS - ' + @prt_src_table_nm;

        -- run procedure for checking target table schema vs results of temp tables above (suspected source)
        exec sp_alter_datamart_schema_postprocessing @batch_id, @datamart_nm, @prt_src_table_nm, @debug;

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
            FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_PERTUSSIS_Case) AS cols;

            DECLARE @obsnum_columns NVARCHAR(MAX) = '';
            SELECT @obsnum_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_NUMERIC_PERTUSSIS_Case) AS cols;

            DECLARE @obstxt_columns NVARCHAR(MAX) = '';
            SELECT @obstxt_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_TXT_PERTUSSIS_Case) AS cols;

            DECLARE @obsdate_columns NVARCHAR(MAX) = '';
            SELECT @obsdate_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_DATE_PERTUSSIS_Case) AS cols;

            DECLARE @Update_sql NVARCHAR(MAX) = '';

            DECLARE @select_phc_col_nm_response NVARCHAR(MAX) =
                'SELECT public_health_case_uid, col_nm, response';

            SET @Update_sql = '
                UPDATE tgt
                    SET
                    tgt.INVESTIGATOR_KEY=src.INVESTIGATOR_KEY,
                    tgt.PHYSICIAN_KEY = src.PHYSICIAN_KEY,
                    tgt.PATIENT_KEY = src.PATIENT_KEY,
                    tgt.REPORTER_KEY = src.REPORTER_KEY,
                    tgt.INV_ASSIGNED_DT_KEY = src.INV_ASSIGNED_DT_KEY,
                    tgt.PERTUSSIS_SUSPECT_SRC_GRP_KEY = src.PERTUSSIS_SUSPECT_SRC_GRP_KEY,
                    tgt.PERTUSSIS_TREATMENT_GRP_KEY = src.PERTUSSIS_TREATMENT_GRP_KEY,
                    tgt.INVESTIGATION_KEY = src.INVESTIGATION_KEY,
                    tgt.ADT_HSPTL_KEY = src.ADT_HSPTL_KEY,
                    tgt.RPT_SRC_ORG_KEY = src.RPT_SRC_ORG_KEY,
                    tgt.CONDITION_KEY = src.CONDITION_KEY,
                    tgt.LDF_GROUP_KEY = src.LDF_GROUP_KEY,
                    tgt.GEOCODING_LOCATION_KEY = src.GEOCODING_LOCATION_KEY'
                    + IIF(@obscoded_columns != '',
                          ',' + (SELECT STRING_AGG('tgt.'
                                                       + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX))
                                                       + ' = ovc.'
                                                       + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)),',')
                                 FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_PERTUSSIS_Case) as cols),
                          '')
                    + IIF(@obsnum_columns != '',
                          ',' + (SELECT STRING_AGG('tgt.'
                                                       + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX))
                                                       + ' = '
                                                       + CAST(converted_column AS NVARCHAR(MAX)),',')
                                 FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_PERTUSSIS_Case) as cols),
                          '')
                    + IIF(@obstxt_columns != '',
                          ',' + (SELECT STRING_AGG('tgt.'
                                                       + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX))
                                                       + ' = ovt.'
                                                       + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)),',')
                                 FROM (SELECT DISTINCT col_nm FROM #OBS_TXT_PERTUSSIS_Case) as cols),
                          '')
                    + IIF(@obsdate_columns != '',
                          ',' + (SELECT STRING_AGG('tgt.'
                                                       + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX))
                                                       + ' = ovd.'
                                                       + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)),',')
                                 FROM (SELECT DISTINCT col_nm FROM #OBS_DATE_PERTUSSIS_Case) as cols),
                          '')
                + ' FROM #KEY_ATTR_INIT src
                    LEFT JOIN dbo. ' + @tgt_table_nm + ' tgt
                        ON src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY'
                + IIF(@obscoded_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, ' + @obscoded_columns + '
                        FROM ('
                        + @select_phc_col_nm_response
                        + ' FROM #OBS_CODED_PERTUSSIS_Case
                            WHERE public_health_case_uid IS NOT NULL
                        ) AS SourceData
                        PIVOT (
                            MAX(response)
                            FOR col_nm IN (' + @obscoded_columns + ')
                        ) AS PivotTable) ovc
                        ON ovc.public_health_case_uid = src.public_health_case_uid', ' ')
                + IIF(@obsnum_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, ' + @obsnum_columns + '
                        FROM ('
                        + @select_phc_col_nm_response
                        + ' FROM #OBS_NUMERIC_PERTUSSIS_Case
                            WHERE public_health_case_uid IS NOT NULL
                        ) AS SourceData
                        PIVOT (
                            MAX(response)
                            FOR col_nm IN (' + @obsnum_columns + ')
                        ) AS PivotTable) ovn
                        ON ovn.public_health_case_uid = src.public_health_case_uid', ' ')
                + IIF(@obstxt_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, ' + @obstxt_columns + '
                        FROM ('
                        + @select_phc_col_nm_response
                        + ' FROM #OBS_TXT_PERTUSSIS_Case
                            WHERE public_health_case_uid IS NOT NULL
                        ) AS SourceData
                        PIVOT (
                            MAX(response)
                            FOR col_nm IN (' + @obstxt_columns + ')
                        ) AS PivotTable) ovt
                        ON ovt.public_health_case_uid = src.public_health_case_uid', ' ')
                + IIF(@obsdate_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, ' + @obsdate_columns + '
                        FROM ('
                        + @select_phc_col_nm_response
                        + ' FROM #OBS_DATE_PERTUSSIS_Case
                            WHERE public_health_case_uid IS NOT NULL
                        ) AS SourceData
                        PIVOT (
                            MAX(response)
                            FOR col_nm IN (' + @obsdate_columns + ')
                        ) AS PivotTable) ovd
                        ON ovd.public_health_case_uid = src.public_health_case_uid', ' ')
                + ' WHERE tgt.INVESTIGATION_KEY IS NOT NULL
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
            FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_PERTUSSIS_Case) AS cols;


            DECLARE @Insert_sql NVARCHAR(MAX) = ''

            SET @Insert_sql = '
            INSERT INTO dbo. ' + @tgt_table_nm + ' (
                INVESTIGATOR_KEY,
                PHYSICIAN_KEY,
                PATIENT_KEY,
                REPORTER_KEY,
                INV_ASSIGNED_DT_KEY,
                PERTUSSIS_SUSPECT_SRC_GRP_KEY,
                PERTUSSIS_TREATMENT_GRP_KEY,
                INVESTIGATION_KEY,
                ADT_HSPTL_KEY,
                RPT_SRC_ORG_KEY,
                CONDITION_KEY,
                LDF_GROUP_KEY,
                GEOCODING_LOCATION_KEY'
                + IIF(@obscoded_columns != '', ',' + @obscoded_columns, '')
                + IIF(@obsnum_columns != '', ',' + @obsnum_columns, '')
                + IIF(@obstxt_columns != '', ',' + @obstxt_columns, '')
                + IIF(@obsdate_columns != '', ',' + @obsdate_columns, '')
                + ') SELECT
                        src.INVESTIGATOR_KEY,
                        src.PHYSICIAN_KEY,
                        src.PATIENT_KEY,
                        src.REPORTER_KEY,
                        src.INV_ASSIGNED_DT_KEY,
                        src.PERTUSSIS_SUSPECT_SRC_GRP_KEY,
                        src.PERTUSSIS_TREATMENT_GRP_KEY,
                        src.INVESTIGATION_KEY,
                        src.ADT_HSPTL_KEY,
                        src.RPT_SRC_ORG_KEY,
                        src.CONDITION_KEY,
                        src.LDF_GROUP_KEY,
                        src.GEOCODING_LOCATION_KEY'
                + IIF(@obscoded_columns != '', ',' + @obscoded_columns, '')
                + IIF(@obsnum_columns != '', ',' + @obsnum_insert_columns, '')
                + IIF(@obstxt_columns != '', ',' + @obstxt_columns, '')
                + IIF(@obsdate_columns != '', ',' + @obsdate_columns, '')
                + ' FROM #KEY_ATTR_INIT src
                    LEFT JOIN (SELECT INVESTIGATION_KEY FROM dbo. ' + @tgt_table_nm + ') tgt
                    ON src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY'
                + IIF(@obscoded_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, ' + @obscoded_columns + '
                        FROM ('
                        + @select_phc_col_nm_response
                        + ' FROM #OBS_CODED_PERTUSSIS_Case
                                WHERE public_health_case_uid IS NOT NULL
                        ) AS SourceData
                        PIVOT (
                            MAX(response)
                            FOR col_nm IN (' + @obscoded_columns + ')
                        ) AS PivotTable) ovc
                        ON ovc.public_health_case_uid = src.public_health_case_uid', ' ') +
                + IIF(@obsnum_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, ' + @obsnum_columns + '
                        FROM ('
                        + @select_phc_col_nm_response
                        + ' FROM #OBS_NUMERIC_PERTUSSIS_Case
                            WHERE public_health_case_uid IS NOT NULL
                        ) AS SourceData
                        PIVOT (
                            MAX(response)
                            FOR col_nm IN (' + @obsnum_columns + ')
                        ) AS PivotTable) ovn
                        ON ovn.public_health_case_uid = src.public_health_case_uid', ' ')
                + IIF(@obstxt_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, ' + @obstxt_columns + '
                        FROM ('
                        + @select_phc_col_nm_response
                        + ' FROM #OBS_TXT_PERTUSSIS_Case
                            WHERE public_health_case_uid IS NOT NULL
                        ) AS SourceData
                        PIVOT (
                            MAX(response)
                            FOR col_nm IN (' + @obstxt_columns + ')
                        ) AS PivotTable) ovt
                        ON ovt.public_health_case_uid = src.public_health_case_uid', ' ')
                + IIF(@obsdate_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, ' + @obsdate_columns + '
                        FROM ('
                        + @select_phc_col_nm_response
                        + ' FROM #OBS_DATE_PERTUSSIS_Case
                            WHERE public_health_case_uid IS NOT NULL
                        ) AS SourceData
                        PIVOT (
                            MAX(response)
                            FOR col_nm IN (' + @obsdate_columns + ')
                        ) AS PivotTable) ovd
                        ON ovd.public_health_case_uid = src.public_health_case_uid', ' ')
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


        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETING Old Keys from ' + @prt_treatment_table_nm;

            DELETE FROM dbo.PERTUSSIS_TREATMENT_FIELD
            WHERE PERTUSSIS_TREATMENT_GRP_KEY > 1 AND EXISTS (
                SELECT 1 FROM #OLD_TREATMENT_GRP_KEYS
                WHERE PERTUSSIS_TREATMENT_GRP_KEY = dbo.PERTUSSIS_TREATMENT_FIELD.PERTUSSIS_TREATMENT_GRP_KEY
            );

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'INSERT INTO ' + @prt_treatment_table_nm;


            SELECT @obscoded_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_PERTUSSIS_TREATMENT_FIELD) AS cols;

            SELECT @obstxt_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_TXT_PERTUSSIS_TREATMENT_FIELD) AS cols;

            SELECT @obsdate_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_DATE_PERTUSSIS_TREATMENT_FIELD) AS cols;


            SELECT @obsnum_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_NUMERIC_PERTUSSIS_TREATMENT_FIELD) AS cols;


            SELECT @obsnum_insert_columns = COALESCE(
                    STRING_AGG(CAST(converted_column AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm), '')
            FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_PERTUSSIS_TREATMENT_FIELD) AS cols;


            SET @Insert_sql = '
            INSERT INTO dbo. ' + @prt_treatment_table_nm + ' (
                PERTUSSIS_TREATMENT_GRP_KEY,
                PERTUSSIS_TREATMENT_FLD_KEY'
                + IIF(@obscoded_columns != '', ',' + @obscoded_columns, '')
                + IIF(@obstxt_columns != '', ',' + @obstxt_columns, '')
                + IIF(@obsdate_columns != '', ',' + @obsdate_columns, '')
                + IIF(@obsnum_columns != '', ',' + @obsnum_columns, '')
                + ') SELECT
                        src.PERTUSSIS_TREATMENT_GRP_KEY,
                        src.PERTUSSIS_TREATMENT_FLD_KEY'
                + IIF(@obscoded_columns != '', ',' + @obscoded_columns, '')
                + IIF(@obstxt_columns != '', ',' + @obstxt_columns, '')
                + IIF(@obsdate_columns != '', ',' + @obsdate_columns, '')
                + IIF(@obsnum_columns != '', ',' + @obsnum_insert_columns, '')
                + ' FROM dbo.nrt_pertussis_treatment_key src'
                + IIF(@obscoded_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, row_num, ' + @obscoded_columns + '
                        FROM (
                            SELECT
                                public_health_case_uid,
                                col_nm,
                                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, cd ORDER BY branch_id) AS row_num,
                                response
                            FROM #OBS_CODED_PERTUSSIS_TREATMENT_FIELD
                            WHERE public_health_case_uid IS NOT NULL
                            ) AS SourceData
                            PIVOT (
                                MAX(response)
                                FOR col_nm IN (' + @obscoded_columns + ')
                            ) AS PivotTable) ovc
                            ON ovc.public_health_case_uid = src.public_health_case_uid and ovc.row_num = src.selection_number ', ' ') 
                            + IIF(@obstxt_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, row_num, ' + @obstxt_columns + '
                        FROM (
                            SELECT
                                public_health_case_uid,
                                col_nm,
                                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, cd ORDER BY branch_id) AS row_num,
                                response
                            FROM #OBS_TXT_PERTUSSIS_TREATMENT_FIELD
                            WHERE public_health_case_uid IS NOT NULL
                            ) AS SourceData
                            PIVOT (
                                MAX(response)
                                FOR col_nm IN (' + @obstxt_columns + ')
                            ) AS PivotTable) ovt
                            ON ovt.public_health_case_uid = src.public_health_case_uid and ovt.row_num = src.selection_number ', ' ') 
                            + IIF(@obsdate_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, row_num, ' + @obsdate_columns + '
                        FROM (
                            SELECT
                                public_health_case_uid,
                                col_nm,
                                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, cd ORDER BY branch_id) AS row_num,
                                response
                            FROM #OBS_DATE_PERTUSSIS_TREATMENT_FIELD
                            WHERE public_health_case_uid IS NOT NULL
                            ) AS SourceData
                            PIVOT (
                                MAX(response)
                                FOR col_nm IN (' + @obsdate_columns + ')
                            ) AS PivotTable) ovd
                            ON ovd.public_health_case_uid = src.public_health_case_uid and ovd.row_num = src.selection_number ', ' ') 
                + IIF(@obsnum_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, row_num, ' + @obsnum_columns + '
                        FROM (
                            SELECT
                                public_health_case_uid,
                                col_nm,
                                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, cd ORDER BY branch_id) AS row_num,
                                response
                            FROM #OBS_NUMERIC_PERTUSSIS_TREATMENT_FIELD
                            WHERE public_health_case_uid IS NOT NULL
                            ) AS SourceData
                            PIVOT (
                                MAX(response)
                                FOR col_nm IN (' + @obsnum_columns + ')
                            ) AS PivotTable) ovn
                            ON ovn.public_health_case_uid = src.public_health_case_uid and ovn.row_num = src.selection_number ', ' ')
                + ' WHERE src.public_health_case_uid IN (' + @phc_uids + ')';

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


        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETING Old Keys from ' + @prt_src_table_nm;

            DELETE FROM dbo.PERTUSSIS_SUSPECTED_SOURCE_FLD
            WHERE PERTUSSIS_SUSPECT_SRC_GRP_KEY > 1 AND EXISTS (
                SELECT 1 FROM #OLD_SRC_GRP_KEYS
                WHERE PERTUSSIS_SUSPECT_SRC_GRP_KEY = dbo.PERTUSSIS_SUSPECTED_SOURCE_FLD.PERTUSSIS_SUSPECT_SRC_GRP_KEY
            );

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'INSERT INTO ' + @prt_src_table_nm;


            SELECT @obscoded_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_PERTUSSIS_SUSPECTED_SOURCE_FLD) AS cols;

            SELECT @obstxt_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_TXT_PERTUSSIS_SUSPECTED_SOURCE_FLD) AS cols;

            SELECT @obsdate_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_DATE_PERTUSSIS_SUSPECTED_SOURCE_FLD) AS cols;


            SELECT @obsnum_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_NUMERIC_PERTUSSIS_SUSPECTED_SOURCE_FLD) AS cols;


            SELECT @obsnum_insert_columns = COALESCE(
                    STRING_AGG(CAST(converted_column AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm), '')
            FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_PERTUSSIS_SUSPECTED_SOURCE_FLD) AS cols;


            SET @Insert_sql = '
            INSERT INTO dbo. ' + @prt_src_table_nm + ' (
                PERTUSSIS_SUSPECT_SRC_GRP_KEY,
                PERTUSSIS_SUSPECT_SRC_FLD_KEY'
                + IIF(@obscoded_columns != '', ',' + @obscoded_columns, '')
                + IIF(@obstxt_columns != '', ',' + @obstxt_columns, '')
                + IIF(@obsdate_columns != '', ',' + @obsdate_columns, '')
                + IIF(@obsnum_columns != '', ',' + @obsnum_columns, '')
                + ') SELECT
                        src.PERTUSSIS_SUSPECT_SRC_GRP_KEY,
                        src.PERTUSSIS_SUSPECT_SRC_FLD_KEY'
                + IIF(@obscoded_columns != '', ',' + @obscoded_columns, '')
                + IIF(@obstxt_columns != '', ',' + @obstxt_columns, '')
                + IIF(@obsdate_columns != '', ',' + @obsdate_columns, '')
                + IIF(@obsnum_columns != '', ',' + @obsnum_insert_columns, '')
                + ' FROM dbo.nrt_pertussis_source_key src'
                + IIF(@obscoded_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, row_num, ' + @obscoded_columns + '
                        FROM (
                            SELECT
                                public_health_case_uid,
                                col_nm,
                                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, cd ORDER BY branch_id) AS row_num,
                                response
                            FROM #OBS_CODED_PERTUSSIS_SUSPECTED_SOURCE_FLD
                            WHERE public_health_case_uid IS NOT NULL
                            ) AS SourceData
                            PIVOT (
                                MAX(response)
                                FOR col_nm IN (' + @obscoded_columns + ')
                            ) AS PivotTable) ovc
                            ON ovc.public_health_case_uid = src.public_health_case_uid and ovc.row_num = src.selection_number ', ' ') 
                            + IIF(@obstxt_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, row_num, ' + @obstxt_columns + '
                        FROM (
                            SELECT
                                public_health_case_uid,
                                col_nm,
                                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, cd ORDER BY branch_id) AS row_num,
                                response
                            FROM #OBS_TXT_PERTUSSIS_SUSPECTED_SOURCE_FLD
                            WHERE public_health_case_uid IS NOT NULL
                            ) AS SourceData
                            PIVOT (
                                MAX(response)
                                FOR col_nm IN (' + @obstxt_columns + ')
                            ) AS PivotTable) ovt
                            ON ovt.public_health_case_uid = src.public_health_case_uid and ovt.row_num = src.selection_number ', ' ') 
                            + IIF(@obsdate_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, row_num, ' + @obsdate_columns + '
                        FROM (
                            SELECT
                                public_health_case_uid,
                                col_nm,
                                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, cd ORDER BY branch_id) AS row_num,
                                response
                            FROM #OBS_DATE_PERTUSSIS_SUSPECTED_SOURCE_FLD
                            WHERE public_health_case_uid IS NOT NULL
                            ) AS SourceData
                            PIVOT (
                                MAX(response)
                                FOR col_nm IN (' + @obsdate_columns + ')
                            ) AS PivotTable) ovd
                            ON ovd.public_health_case_uid = src.public_health_case_uid and ovd.row_num = src.selection_number ', ' ') 
                + IIF(@obsnum_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, row_num, ' + @obsnum_columns + '
                        FROM (
                            SELECT
                                public_health_case_uid,
                                col_nm,
                                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, cd ORDER BY branch_id) AS row_num,
                                response
                            FROM #OBS_NUMERIC_PERTUSSIS_SUSPECTED_SOURCE_FLD
                            WHERE public_health_case_uid IS NOT NULL
                            ) AS SourceData
                            PIVOT (
                                MAX(response)
                                FOR col_nm IN (' + @obsnum_columns + ')
                            ) AS PivotTable) ovn
                            ON ovn.public_health_case_uid = src.public_health_case_uid and ovn.row_num = src.selection_number ', ' ')
                + ' WHERE src.public_health_case_uid IN (' + @phc_uids + ')';

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


        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETE Old Keys from PERTUSSIS_TREATMENT_GROUP';

            DELETE FROM dbo.PERTUSSIS_TREATMENT_GROUP
            WHERE PERTUSSIS_TREATMENT_GRP_KEY > 1 AND EXISTS (
                SELECT 1 FROM #OLD_TREATMENT_GRP_KEYS
                WHERE PERTUSSIS_TREATMENT_GRP_KEY = dbo.PERTUSSIS_TREATMENT_GROUP.PERTUSSIS_TREATMENT_GRP_KEY
            ) AND NOT EXISTS (
                SELECT 1 FROM #TMP_TREATMENT_GRP
                WHERE PERTUSSIS_TREATMENT_GRP_KEY = dbo.PERTUSSIS_TREATMENT_GROUP.PERTUSSIS_TREATMENT_GRP_KEY
            );

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
                @PROC_STEP_NAME = 'DELETE Old Keys from PERTUSSIS_SUSPECTED_SOURCE_GRP';

            DELETE FROM dbo.PERTUSSIS_SUSPECTED_SOURCE_GRP
            WHERE PERTUSSIS_SUSPECT_SRC_GRP_KEY > 1 AND EXISTS (
                SELECT 1 FROM #OLD_SRC_GRP_KEYS
                WHERE PERTUSSIS_SUSPECT_SRC_GRP_KEY = dbo.PERTUSSIS_SUSPECTED_SOURCE_GRP.PERTUSSIS_SUSPECT_SRC_GRP_KEY
            ) AND NOT EXISTS (
                SELECT 1 FROM #TMP_SRC_GRP
                WHERE PERTUSSIS_SUSPECT_SRC_GRP_KEY = dbo.PERTUSSIS_SUSPECTED_SOURCE_GRP.PERTUSSIS_SUSPECT_SRC_GRP_KEY
            );

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'COMPLETE', 999, 'COMPLETE', 0);


    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION;
            END;
        DECLARE @FullErrorMessage NVARCHAR(4000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count] )
        VALUES( @Batch_id
          , @datamart_nm
          , @datamart_nm
          , 'ERROR'
          , @Proc_Step_no
          , @Proc_Step_name
          , @FullErrorMessage
          , 0 );
        RETURN -1;

    END CATCH;
END;