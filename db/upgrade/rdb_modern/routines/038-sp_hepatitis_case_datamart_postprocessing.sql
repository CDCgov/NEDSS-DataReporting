CREATE OR ALTER PROCEDURE dbo.sp_hepatitis_case_datamart_postprocessing @phc_uids nvarchar(max),
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
        @batch_id = cast((format(getdate(), 'yyyyMMddHHmmss')) as bigint);

    -- condition for investigation_form_cd uses the LIKE operator for Hepatitis_Case, so % is included
    DECLARE
        @inv_form_cd VARCHAR(100) = 'INV_FORM_HEP%';

    -- used in conditions for temp table queries and the dynamic sql
    DECLARE
        @tgt_table_nm VARCHAR(50) = 'Hepatitis_Case';

    -- used in the logging statements
    DECLARE 
        @datamart_nm VARCHAR(100) = 'HEPATITIS_CASE_DATAMART';

    -- used in conditions for temp table queries and the dynamic sql (multivalue specific, not needed for tables without multivalue selections)
    DECLARE
        @multival_tgt_table_nm VARCHAR(50) = 'HEP_Multi_Value_Field';


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
                @PROC_STEP_NAME = 'GENERATING #OBS_CODED_Hepatitis_Case';

            IF OBJECT_ID('#OBS_CODED_Hepatitis_Case', 'U') IS NOT NULL
            drop table #OBS_CODED_Hepatitis_Case;


            select public_health_case_uid,
                   unique_cd      as cd,
                   CASE WHEN col_nm = 'NATION_CD' THEN 'PLACE_OF_BIRTH'
                   ELSE col_nm
                   END AS col_nm,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.label,
                   coded_response as response
            INTO #OBS_CODED_Hepatitis_Case
            from dbo.v_rdb_obs_mapping rom
            LEFT JOIN 
                INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table)
                AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE (RDB_TABLE = @tgt_table_nm OR unique_cd = 'HEP255') and db_field = 'code'
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));


            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_CODED_Hepatitis_Case;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_TXT_Hepatitis_Case';

            IF OBJECT_ID('#OBS_TXT_Hepatitis_Case', 'U') IS NOT NULL
            drop table #OBS_TXT_Hepatitis_Case;

            select public_health_case_uid,
                   unique_cd    as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   txt_response as response
            INTO #OBS_TXT_Hepatitis_Case
            from dbo.v_rdb_obs_mapping rom
            LEFT JOIN 
                INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table)
                AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @tgt_table_nm and db_field = 'value_txt'
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_TXT_Hepatitis_Case;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_DATE_Hepatitis_Case';

            IF OBJECT_ID('#OBS_DATE_Hepatitis_Case', 'U') IS NOT NULL
            drop table #OBS_DATE_Hepatitis_Case;

            select public_health_case_uid,
                   unique_cd     as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   date_response as response
            INTO #OBS_DATE_Hepatitis_Case
            from dbo.v_rdb_obs_mapping rom
            LEFT JOIN 
                INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table)
                AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @tgt_table_nm and db_field = 'from_time'
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_DATE_Hepatitis_Case;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_NUMERIC_Hepatitis_Case';

            IF OBJECT_ID('#OBS_NUMERIC_Hepatitis_Case', 'U') IS NOT NULL
            drop table #OBS_NUMERIC_Hepatitis_Case;

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
            INTO #OBS_NUMERIC_Hepatitis_Case
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
                from #OBS_NUMERIC_Hepatitis_Case;

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
                @PROC_STEP_NAME = 'GENERATING #OBS_CODED_HEP_multi_value_field';

            IF OBJECT_ID('#OBS_CODED_HEP_multi_value_field', 'U') IS NOT NULL
            drop table #OBS_CODED_HEP_multi_value_field;


            select public_health_case_uid,
                   unique_cd      as cd,
                   col_nm,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.label,
                   coded_response as response,
                   branch_id
            INTO #OBS_CODED_HEP_multi_value_field
            from dbo.v_rdb_obs_mapping rom
            LEFT JOIN 
                INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table)
                AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @multival_tgt_table_nm and db_field = 'code'
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));


            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_CODED_HEP_multi_value_field;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_TXT_HEP_multi_value_field';

            IF OBJECT_ID('#OBS_TXT_HEP_multi_value_field', 'U') IS NOT NULL
            drop table #OBS_TXT_HEP_multi_value_field;

            select public_health_case_uid,
                   unique_cd    as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   txt_response as response,
                   branch_id
            INTO #OBS_TXT_HEP_multi_value_field
            from dbo.v_rdb_obs_mapping rom
            LEFT JOIN 
                INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table)
                AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @multival_tgt_table_nm and db_field = 'value_txt'
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_TXT_HEP_multi_value_field;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_DATE_HEP_multi_value_field';

            IF OBJECT_ID('#OBS_DATE_HEP_multi_value_field', 'U') IS NOT NULL
            drop table #OBS_DATE_HEP_multi_value_field;

            select public_health_case_uid,
                   unique_cd     as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   date_response as response,
                   branch_id
            INTO #OBS_DATE_HEP_multi_value_field
            from dbo.v_rdb_obs_mapping rom
            LEFT JOIN 
                INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table)
                AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @multival_tgt_table_nm and db_field = 'from_time'
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_DATE_HEP_multi_value_field;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_NUMERIC_HEP_multi_value_field';

            IF OBJECT_ID('#OBS_NUMERIC_HEP_multi_value_field', 'U') IS NOT NULL
            drop table #OBS_NUMERIC_HEP_multi_value_field;

            select rom.public_health_case_uid,
                   rom.unique_cd        as cd,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.col_nm,
                   rom.numeric_response as response,
                   branch_id,
                   CASE WHEN isc.DATA_TYPE = 'numeric' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS NUMERIC(' + CAST(isc.NUMERIC_PRECISION as NVARCHAR(5)) + ',' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + '))'
                        WHEN isc.DATA_TYPE LIKE '%int' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS ' + isc.DATA_TYPE + ')'
                    WHEN isc.DATA_TYPE IN ('varchar', 'nvarchar') THEN 'CAST(ovn.' + QUOTENAME(col_nm) + ' AS ' + isc.DATA_TYPE + '(' + CAST(isc.CHARACTER_MAXIMUM_LENGTH as NVARCHAR(5)) + '))'
                    ELSE 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ',5) AS NUMERIC(15,5))'
                END AS converted_column
            INTO #OBS_NUMERIC_HEP_multi_value_field
            from dbo.v_rdb_obs_mapping rom
            LEFT JOIN 
                INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table)
                AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE rom.RDB_TABLE = @multival_tgt_table_nm and rom.db_field = 'numeric_value_1'
            and (rom.public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_NUMERIC_HEP_multi_value_field;

            SELECT @RowCount_no = @@ROWCOUNT;


            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;


        /*
            The below step gets a total list of all multivalue observation data, then
            keeps as many rows as the highest number of values from each type of observation.
            For example, if for a certain phc_uid CODED has 6, TXT has 3, and NUMERIC has 9 
            selections, this will mean HEP_multi_value_field needs 9 total records inserted
            for that phc. This is because selections will share the same lines.

            These will later be stored in nrt_hepatitis_case_multi_val_key so that way,
            when the observation values are pivoted in the insert statement for
            HEP_mutli_value_field, we can join them back appropriately.
        */
        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = ' GENERATING #HEP_MULTI_VAL_IDS';

            IF OBJECT_ID('#HEP_MULTI_VAL_IDS', 'U') IS NOT NULL
            drop table #HEP_MULTI_VAL_IDS;


            WITH id_cte AS (
                SELECT public_health_case_uid,
                       branch_id
                FROM #OBS_CODED_HEP_multi_value_field
                WHERE public_health_case_uid IS NOT NULL
                UNION ALL
                SELECT public_health_case_uid,
                       branch_id
                FROM #OBS_TXT_HEP_multi_value_field
                WHERE public_health_case_uid IS NOT NULL
                UNION ALL
                SELECT public_health_case_uid,
                       branch_id
                FROM #OBS_DATE_HEP_multi_value_field
                WHERE public_health_case_uid IS NOT NULL
                UNION ALL
                SELECT public_health_case_uid,
                       branch_id
                FROM #OBS_NUMERIC_HEP_multi_value_field
                WHERE public_health_case_uid IS NOT NULL
            ),
            ordered_selection as 
            (SELECT public_health_case_uid,
                   branch_id,
                   ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, branch_id ORDER BY branch_id) as row_num
            FROM id_cte)
            -- distinct here makes it to where we only keep row numbers 1 -> max row num for each phc
            SELECT DISTINCT ids.public_health_case_uid,
                            ids.row_num
            INTO #HEP_MULTI_VAL_IDS
            FROM ordered_selection ids 
            LEFT JOIN dbo.nrt_hepatitis_case_group_key hcgk
                ON ids.public_health_case_uid = hcgk.public_health_case_uid;

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #HEP_MULTI_VAL_IDS;

            SELECT @RowCount_no = @@ROWCOUNT;


            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;

        /*
            Old group keys need to be deleted from both nrt_hepatities_case_group_key
            AND HEP_multi_value_field_group
        */
        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #OLD_GRP_KEYS';

                IF OBJECT_ID('#OLD_GRP_KEYS', 'U') IS NOT NULL
            drop table #OLD_GRP_KEYS;


            SELECT HEP_MULTI_VAL_GRP_KEY 
            INTO #OLD_GRP_KEYS
            FROM dbo.nrt_hepatitis_case_group_key
            where public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ','));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OLD_GRP_KEYS;

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
                @PROC_STEP_NAME = 'DELETE Old Keys from dbo.nrt_hepatitis_case_group_key';


            DELETE FROM dbo.nrt_hepatitis_case_group_key
            WHERE public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ','));

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
                @PROC_STEP_NAME = 'DELETE Old Keys from dbo.nrt_hepatitis_case_multi_val_key';


            DELETE FROM dbo.nrt_hepatitis_case_multi_val_key
            WHERE public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ','));

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;


        -- new group keys need to be inserted
        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERTING INTO dbo.nrt_hepatitis_case_group_key';


            INSERT INTO dbo.nrt_hepatitis_case_group_key
            (
                public_health_case_uid
            )
            SELECT DISTINCT public_health_case_uid
            FROM #HEP_MULTI_VAL_IDS;

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
                @PROC_STEP_NAME = 'INSERTING INTO dbo.nrt_hepatitis_case_multi_val_key';


            INSERT INTO dbo.nrt_hepatitis_case_multi_val_key
            (
                HEP_MULTI_VAL_GRP_KEY,
                public_health_case_uid,
                selection_number
            )
            SELECT 
            hepgrp.HEP_MULTI_VAL_GRP_KEY,
            ids.public_health_case_uid,
            ids.row_num AS selection_number
            FROM #HEP_MULTI_VAL_IDS ids
            LEFT JOIN dbo.nrt_hepatitis_case_group_key hepgrp
                ON ids.public_health_case_uid = hepgrp.public_health_case_uid;

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
                @PROC_STEP_NAME = ' GENERATING #KEY_ATTR_INIT';

            IF OBJECT_ID('#KEY_ATTR_INIT', 'U') IS NOT NULL
            drop table #KEY_ATTR_INIT;

            select inv.public_health_case_uid,
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
                   GEOCODING_LOCATION_KEY,
                   COALESCE(hepgrp.HEP_MULTI_VAL_GRP_KEY, 1) AS HEP_MULTI_VAL_GRP_KEY
            INTO #KEY_ATTR_INIT
            from dbo.v_nrt_inv_keys_attrs_mapping inv
            LEFT JOIN dbo.nrt_hepatitis_case_group_key hepgrp
                ON inv.public_health_case_uid = hepgrp.public_health_case_uid
            where inv.public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ','))
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




            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'CHECKING FOR NEW COLUMNS - ' + @tgt_table_nm;

            -- run procedure for checking target table schema vs results of temp tables above
            exec sp_alter_datamart_schema_postprocessing @batch_id, @datamart_nm, @tgt_table_nm, @debug;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);


            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'CHECKING FOR NEW COLUMNS - ' + @multival_tgt_table_nm;

            -- run procedure for checking target table schema vs results of temp tables above (multiselect)
            exec sp_alter_datamart_schema_postprocessing @batch_id, @datamart_nm, @multival_tgt_table_nm, @debug;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

                    /*
                        The order of the following inserts, updates, and deletes
                        are a result of the FK relationship between the target tables
                    */


        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERTING INTO dbo.HEP_MULTI_VALUE_FIELD_GROUP';

            SELECT * FROM #HEP_MULTI_VAL_IDS ids
            LEFT JOIN dbo.nrt_hepatitis_case_group_key hepgrp
                ON ids.public_health_case_uid = hepgrp.public_health_case_uid;

            INSERT INTO dbo.HEP_MULTI_VALUE_FIELD_GROUP
            (
                HEP_MULTI_VAL_GRP_KEY
            )
            SELECT DISTINCT HEP_MULTI_VAL_GRP_KEY
            FROM #HEP_MULTI_VAL_IDS ids
            LEFT JOIN dbo.nrt_hepatitis_case_group_key hepgrp
                ON ids.public_health_case_uid = hepgrp.public_health_case_uid;

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
                @PROC_STEP_NAME = 'UPDATE dbo.' + @tgt_table_nm;

            -- variables for the column lists
            -- must be ordered the same as those used in the insert statement
            DECLARE @obscoded_columns NVARCHAR(MAX) = '';
            SELECT @obscoded_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_Hepatitis_Case) AS cols;

            DECLARE @obsnum_columns NVARCHAR(MAX) = '';
            SELECT @obsnum_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_NUMERIC_Hepatitis_Case) AS cols;

            DECLARE @obstxt_columns NVARCHAR(MAX) = '';
            SELECT @obstxt_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_TXT_Hepatitis_Case) AS cols;

            DECLARE @obsdate_columns NVARCHAR(MAX) = '';
            SELECT @obsdate_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_DATE_Hepatitis_Case) AS cols;

            DECLARE @Update_sql NVARCHAR(MAX) = '';

            SET @Update_sql = '
        UPDATE tgt
        SET
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
        tgt.GEOCODING_LOCATION_KEY = src.GEOCODING_LOCATION_KEY,
        tgt.HEP_MULTI_VAL_GRP_KEY = src.HEP_MULTI_VAL_GRP_KEY
        ' + CASE
                WHEN @obscoded_columns != '' THEN ',' + (SELECT STRING_AGG('tgt.' +
                                                        CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)) +
                                                        ' = ovc.' +
                                                        CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)),
                                                        ',')
                    FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_Hepatitis_Case) as cols)
            ELSE '' END
                + CASE
                      WHEN @obsnum_columns != '' THEN ',' + (SELECT STRING_AGG('tgt.' +
                                                                                CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)) +
                                                                               ' = ' +
                                                                               CAST(converted_column AS NVARCHAR(MAX)),
                                                                               ',')
                                                             FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_Hepatitis_Case) as cols)
                      ELSE '' END
                + CASE
                      WHEN @obstxt_columns != '' THEN ',' + (SELECT STRING_AGG('tgt.' +
                                                                               CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)) +
                                                                               ' = ovt.' +
                                                                               CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)),
                                                                               ',')
                                                             FROM (SELECT DISTINCT col_nm FROM #OBS_TXT_Hepatitis_Case) as cols)
                      ELSE '' END
                + CASE
                      WHEN @obsdate_columns != '' THEN ',' + (SELECT STRING_AGG('tgt.' +
                                                                                CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)) +
                                                                                ' = ovd.' +
                                                                                CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)),
                                                                                ',')
                                                              FROM (SELECT DISTINCT col_nm FROM #OBS_DATE_Hepatitis_Case) as cols)
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
                #OBS_CODED_Hepatitis_Case 
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
                #OBS_NUMERIC_Hepatitis_Case 
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
                #OBS_TXT_Hepatitis_Case 
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
                #OBS_DATE_Hepatitis_Case 
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
        FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_Hepatitis_Case) AS cols;


        DECLARE @Insert_sql NVARCHAR(MAX) = ''

        SET @Insert_sql = '
        INSERT INTO dbo. ' + @tgt_table_nm + ' (
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
        GEOCODING_LOCATION_KEY,
        HEP_MULTI_VAL_GRP_KEY
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
                            src.GEOCODING_LOCATION_KEY,
                            src.HEP_MULTI_VAL_GRP_KEY
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
                #OBS_CODED_Hepatitis_Case 
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
                #OBS_NUMERIC_Hepatitis_Case 
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
                #OBS_TXT_Hepatitis_Case 
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
                #OBS_DATE_Hepatitis_Case 
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






        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'INSERT INTO dbo.' + @multival_tgt_table_nm;


        -- Variables for the columns in the insert select statement
        -- Must be ordered the same as the original column lists

            SELECT @obscoded_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_HEP_multi_value_field) AS cols;


            SELECT @obstxt_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_TXT_HEP_multi_value_field) AS cols;

            SELECT @obsnum_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_NUMERIC_HEP_multi_value_field) AS cols;

            SELECT @obsdate_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_DATE_HEP_multi_value_field) AS cols;

        
            SELECT @obsnum_insert_columns = COALESCE(
                STRING_AGG(CAST(converted_column AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm), '')
            FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_HEP_multi_value_field) AS cols;



        /*
            When the observation values are pivoted to get column names,
            a row number is assigned and used to join back onto
            nrt_hepatitis_case_multi_val_key to insert the new data.        
        */
        SET @Insert_sql = '
        INSERT INTO dbo. ' + @multival_tgt_table_nm + ' (
        HEP_MULTI_VAL_GRP_KEY,
        HEP_MULTI_VAL_DATA_KEY
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
                            src.HEP_MULTI_VAL_GRP_KEY,
                            src.HEP_MULTI_VAL_DATA_KEY
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
            ' FROM dbo.nrt_hepatitis_case_multi_val_key src 
            
             '
            + CASE
                      WHEN @obscoded_columns != '' THEN
                          ' LEFT JOIN (
                          SELECT public_health_case_uid, row_num, ' + @obscoded_columns + ' 
        FROM (
            SELECT
                public_health_case_uid,
                col_nm,
                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, branch_id ORDER BY branch_id) AS row_num,
                response 
            FROM 
                 #OBS_CODED_HEP_multi_value_field 
                WHERE public_health_case_uid IS NOT NULL 
        ) AS SourceData
        PIVOT (
            MAX(response)
            FOR col_nm IN (' + @obscoded_columns + ')
        ) AS PivotTable) ovc
        ON ovc.public_health_case_uid = src.public_health_case_uid and ovc.row_num = src.selection_number '
                      ELSE ' ' END +
                              + CASE
                                    WHEN @obsnum_columns != '' THEN
                                        ' LEFT JOIN (
                                        SELECT public_health_case_uid, row_num, ' + @obsnum_columns + ' 
        FROM (
            SELECT
                public_health_case_uid,
                col_nm,
                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, branch_id ORDER BY branch_id) AS row_num,
                response 
            FROM 
                 #OBS_NUMERIC_HEP_multi_value_field 
                WHERE public_health_case_uid IS NOT NULL 
        ) AS SourceData
        PIVOT (
            MAX(response)
            FOR col_nm IN (' + @obsnum_columns + ')
        ) AS PivotTable) ovn
        ON ovn.public_health_case_uid = src.public_health_case_uid and ovn.row_num = src.selection_number '
                                    ELSE ' ' END
                + CASE
                      WHEN @obstxt_columns != '' THEN
                          ' LEFT JOIN (
                          SELECT public_health_case_uid, row_num, ' + @obstxt_columns + ' 
        FROM (
            SELECT
                public_health_case_uid,
                col_nm,
                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, branch_id ORDER BY branch_id) AS row_num,
                response 
            FROM 
                 #OBS_TXT_HEP_multi_value_field 
                WHERE public_health_case_uid IS NOT NULL 
        ) AS SourceData
        PIVOT (
            MAX(response)
            FOR col_nm IN (' + @obstxt_columns + ')
        ) AS PivotTable) ovt
        ON ovt.public_health_case_uid = src.public_health_case_uid and ovt.row_num = src.selection_number '
                      ELSE ' ' END
                + CASE
                      WHEN @obsdate_columns != '' THEN
                          ' LEFT JOIN (
                          SELECT public_health_case_uid, row_num, ' + @obsdate_columns + ' 
        FROM (
            SELECT
                public_health_case_uid,
                col_nm,
                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, branch_id ORDER BY branch_id) AS row_num,
                response 
            FROM 
                 #OBS_DATE_HEP_multi_value_field 
                WHERE public_health_case_uid IS NOT NULL 
        ) AS SourceData
        PIVOT (
            MAX(response)
            FOR col_nm IN (' + @obsdate_columns + ')
        ) AS PivotTable) ovd
        ON ovd.public_health_case_uid = src.public_health_case_uid and ovd.row_num = src.selection_number '
                      ELSE ' ' END
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

        -- OLD KEYS must be deleted from target tables, just by the nature of our multiselect options
        -- similar reasons to why we need tombstone messages from our java service to some of the nrt tables

        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETE Old Keys from dbo.HEP_MULTI_VALUE_FIELD';


            DELETE FROM dbo.HEP_MULTI_VALUE_FIELD
            WHERE HEP_MULTI_VAL_GRP_KEY in 
            (SELECT HEP_MULTI_VAL_GRP_KEY FROM #OLD_GRP_KEYS);

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
                @PROC_STEP_NAME = 'DELETE Old Keys from dbo.HEP_MULTI_VALUE_FIELD_GROUP';


            DELETE FROM dbo.HEP_MULTI_VALUE_FIELD_GROUP
            WHERE HEP_MULTI_VAL_GRP_KEY in 
            (SELECT HEP_MULTI_VAL_GRP_KEY FROM #OLD_GRP_KEYS);

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


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;


        DECLARE
            @ErrorNumber INT = ERROR_NUMBER();
        DECLARE
            @ErrorLine INT = ERROR_LINE();
        DECLARE
            @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE
            @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE
            @ErrorState INT = ERROR_STATE();


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
               , LEFT(@ErrorMessage, 500)
               , 0);


        return -1;

    END CATCH

END;
