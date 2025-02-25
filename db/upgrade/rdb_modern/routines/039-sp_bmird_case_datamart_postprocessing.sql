CREATE OR ALTER PROCEDURE [dbo].[sp_bmird_case_datamart_postprocessing]
    @phc_uids nvarchar(max),
    @debug bit = 'false'
AS

BEGIN
    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyyyMMddHHmmss')) as bigint);
    PRINT @batch_id;
    DECLARE @RowCount_no int;
    DECLARE @Proc_Step_no float= 0;
    DECLARE @Proc_Step_Name varchar(200) = '';
    DECLARE @datamart_nm VARCHAR(100) = 'BMIRD_CASE_DATAMART';

    DECLARE @tgt_table_nm VARCHAR(50) = 'BMIRD_Case';
    DECLARE @am_tgt_table_nm VARCHAR(50) = 'Antimicrobial';
    DECLARE @multival_tgt_table_nm VARCHAR(50) = 'BMIRD_Multi_Value_field';


    DECLARE @inv_form_cd VARCHAR(100) = 'INV_FORM_BMD%';

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


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #OBS_CODED_BMIRD_Case';

            IF OBJECT_ID('#OBS_CODED_BMIRD_Case', 'U') IS NOT NULL
                drop table #OBS_CODED_BMIRD_Case;

            SELECT public_health_case_uid,
                   unique_cd      as cd,
                   col_nm,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.label,
                   coded_response as response
            INTO #OBS_CODED_BMIRD_Case
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @tgt_table_nm and db_field = 'code'
              AND (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_CODED_BMIRD_Case;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = ' GENERATING #OBS_TXT_BMIRD_Case';

            IF OBJECT_ID('#OBS_TXT_BMIRD_Case', 'U') IS NOT NULL
                drop table #OBS_TXT_BMIRD_Case;

            SELECT public_health_case_uid,
                   unique_cd    as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   txt_response as response
            INTO #OBS_TXT_BMIRD_Case
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @tgt_table_nm and db_field = 'value_txt' or unique_cd in ('INV172','BMD267','BMD302','BMD303','BMD304','BMD305','BMD306')
                AND (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_TXT_BMIRD_Case;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_DATE_BMIRD_Case';

            IF OBJECT_ID('#OBS_DATE_BMIRD_Case', 'U') IS NOT NULL
                drop table #OBS_DATE_BMIRD_Case;

            select public_health_case_uid,
                   unique_cd     as cd,
                   col_nm,
                   DB_field,
                   rdb_table,
                   date_response as response
            INTO #OBS_DATE_BMIRD_Case
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE (RDB_TABLE = @tgt_table_nm and db_field = 'from_time' or unique_cd in ('BMD124','BMD307'))
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_DATE_BMIRD_Case;

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
                @PROC_STEP_NAME = ' GENERATING #OBS_NUMERIC_BMIRD_Case';

            IF OBJECT_ID('#OBS_NUMERIC_BMIRD_Case', 'U') IS NOT NULL
                drop table #OBS_NUMERIC_BMIRD_Case;

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
            INTO #OBS_NUMERIC_BMIRD_Case
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE rom.RDB_TABLE = @tgt_table_nm and rom.db_field = 'numeric_value_1'
              and (rom.public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_NUMERIC_BMIRD_Case;

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
                @PROC_STEP_NAME = 'GENERATING #OBS_CODED_Antimicrobial';

            IF OBJECT_ID('#OBS_CODED_Antimicrobial', 'U') IS NOT NULL
                drop table #OBS_CODED_Antimicrobial;

            SELECT public_health_case_uid,
                   unique_cd      as cd,
                   col_nm,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.label,
                   coded_response as response,
                   branch_id
            INTO #OBS_CODED_Antimicrobial
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @am_tgt_table_nm and db_field = 'code'
              AND (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_CODED_Antimicrobial;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #OBS_NUMERIC_Antimicrobial';

            IF OBJECT_ID('#OBS_NUMERIC_Antimicrobial', 'U') IS NOT NULL
                drop table #OBS_NUMERIC_Antimicrobial;

            SELECT public_health_case_uid,
                   unique_cd      as cd,
                   col_nm,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.numeric_response as response,
                   branch_id,
                   CASE WHEN isc.DATA_TYPE = 'numeric' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS NUMERIC(' + CAST(isc.NUMERIC_PRECISION as NVARCHAR(5)) + ',' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + '))'
                        WHEN isc.DATA_TYPE LIKE '%int' THEN 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ', ' + CAST(isc.NUMERIC_SCALE as NVARCHAR(5)) + ') AS ' + isc.DATA_TYPE + ')'
                        WHEN isc.DATA_TYPE IN ('varchar', 'nvarchar') THEN 'CAST(ovn.' + QUOTENAME(col_nm) + ' AS ' + isc.DATA_TYPE + '(' + CAST(isc.CHARACTER_MAXIMUM_LENGTH as NVARCHAR(5)) + '))'
                        ELSE 'CAST(ROUND(ovn.' + QUOTENAME(col_nm) + ',5) AS NUMERIC(15,5))'
                   END AS converted_column
            INTO #OBS_NUMERIC_Antimicrobial
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @am_tgt_table_nm and db_field = 'numeric_value_1'
              AND (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_NUMERIC_Antimicrobial;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #OBS_CODED_BMIRD_Multi_Value_field';

            IF OBJECT_ID('#OBS_CODED_BMIRD_Multi_Value_field', 'U') IS NOT NULL
                drop table #OBS_CODED_BMIRD_Multi_Value_field;


            select public_health_case_uid,
                   unique_cd      as cd,
                   col_nm,
                   rom.DB_field,
                   rom.rdb_table,
                   rom.label,
                   coded_response as response,
                   branch_id
            INTO #OBS_CODED_BMIRD_Multi_Value_field
            from dbo.v_rdb_obs_mapping rom
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS isc
                ON UPPER(isc.TABLE_NAME) = UPPER(rom.RDB_table) AND UPPER(isc.COLUMN_NAME) = UPPER(rom.col_nm)
            WHERE RDB_TABLE = @multival_tgt_table_nm and db_field = 'code'
              and (public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) OR (public_health_case_uid IS NULL and isc.column_name IS NOT NULL));

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OBS_CODED_BMIRD_Multi_Value_field;

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
                @PROC_STEP_NAME = 'GENERATING #OLD_AM_GRP_KEYS';

            IF OBJECT_ID('#OLD_AM_GRP_KEYS', 'U') IS NOT NULL
                drop table #OLD_AM_GRP_KEYS;

            SELECT ANTIMICROBIAL_GRP_KEY
            INTO #OLD_AM_GRP_KEYS
            FROM dbo.BMIRD_Case bmc WITH (nolock)
            INNER JOIN dbo.INVESTIGATION inv WITH (nolock) ON inv.INVESTIGATION_KEY = bmc.INVESTIGATION_KEY
            WHERE inv.CASE_UID IN (SELECT value FROM STRING_SPLIT(@phc_uids, ','))

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OLD_AM_GRP_KEYS;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #TMP_AM_GRP';

            IF OBJECT_ID('#TMP_AM_GRP', 'U') IS NOT NULL
                drop table #TMP_AM_GRP;

            SELECT DISTINCT public_health_case_uid,
                            COALESCE(ANTIMICROBIAL_GRP_KEY, 1) AS ANTIMICROBIAL_GRP_KEY
            INTO #TMP_AM_GRP
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN dbo.INVESTIGATION inv WITH (nolock) ON inv.CASE_UID=rom.public_health_case_uid
            LEFT JOIN dbo.BMIRD_Case bmc WITH (nolock) ON bmc.INVESTIGATION_KEY = inv.INVESTIGATION_KEY
            WHERE public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) AND RDB_table=@am_tgt_table_nm;

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #TMP_AM_GRP;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #Antimicrobial_IDS';

            IF OBJECT_ID('#Antimicrobial_IDS', 'U') IS NOT NULL
                drop table #Antimicrobial_IDS;

            WITH id_cte AS (
                SELECT public_health_case_uid, cd
                FROM #OBS_CODED_Antimicrobial
                WHERE public_health_case_uid IS NOT NULL
                UNION ALL
                SELECT public_health_case_uid, cd
                FROM #OBS_NUMERIC_Antimicrobial
                WHERE public_health_case_uid IS NOT NULL
            ),
                 ordered_selection AS
                     (SELECT public_health_case_uid,
                             cd,
                             ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, cd ORDER BY cd) as row_num
                      FROM id_cte)

            -- distinct here makes it to where we only keep row numbers 1 -> max row num for each phc
            SELECT DISTINCT ids.public_health_case_uid, ids.row_num
            INTO #Antimicrobial_IDS
            FROM ordered_selection ids
            LEFT JOIN #TMP_AM_GRP ag ON ids.public_health_case_uid = ag.public_health_case_uid;

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #Antimicrobial_IDS;

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
                @PROC_STEP_NAME = 'INSERTING INTO nrt_antimicrobial_group_key';

            DELETE FROM dbo.nrt_antimicrobial_group_key;
            INSERT INTO dbo.nrt_antimicrobial_group_key (public_health_case_uid)
            SELECT DISTINCT public_health_case_uid
            FROM #TMP_AM_GRP
            WHERE ANTIMICROBIAL_GRP_KEY = 1
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
                @PROC_STEP_NAME = 'INSERTING INTO ANTIMICROBIAL_GROUP';


            INSERT INTO dbo.ANTIMICROBIAL_GROUP (ANTIMICROBIAL_GRP_KEY)
            SELECT ANTIMICROBIAL_GRP_KEY
            FROM dbo.nrt_antimicrobial_group_key;

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
                @PROC_STEP_NAME = 'UPDATING #TMP_AM_GRP';

            UPDATE #TMP_AM_GRP
            SET #TMP_AM_GRP.ANTIMICROBIAL_GRP_KEY = amg.ANTIMICROBIAL_GRP_KEY
            FROM dbo.nrt_antimicrobial_group_key amg
            WHERE amg.public_health_case_uid = #TMP_AM_GRP.public_health_case_uid;

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #TMP_AM_GRP;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERTING INTO nrt_antimicrobial_key';

            DELETE FROM dbo.nrt_antimicrobial_key;
            INSERT INTO dbo.nrt_antimicrobial_key
            (
                ANTIMICROBIAL_GRP_KEY,
                public_health_case_uid,
                selection_number
            )
            SELECT
                amg.ANTIMICROBIAL_GRP_KEY,
                ids.public_health_case_uid,
                ids.row_num AS selection_number
            FROM #Antimicrobial_IDS ids
            LEFT JOIN #TMP_AM_GRP amg
                ON ids.public_health_case_uid = amg.public_health_case_uid;

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
                @PROC_STEP_NAME = 'GENERATING #OLD_MV_GRP_KEYS';

            IF OBJECT_ID('#OLD_MV_GRP_KEYS', 'U') IS NOT NULL
                drop table #OLD_MV_GRP_KEYS;

            SELECT BMIRD_MULTI_VAL_GRP_KEY
            INTO #OLD_MV_GRP_KEYS
            FROM dbo.BMIRD_Case bmc WITH (nolock)
            INNER JOIN dbo.INVESTIGATION inv WITH (nolock) ON inv.INVESTIGATION_KEY = bmc.INVESTIGATION_KEY
            WHERE inv.CASE_UID IN (SELECT value FROM STRING_SPLIT(@phc_uids, ','))

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #OLD_MV_GRP_KEYS;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #TMP_MV_GRP';

            IF OBJECT_ID('#TMP_MV_GRP', 'U') IS NOT NULL
                drop table #TMP_MV_GRP;

            SELECT DISTINCT public_health_case_uid,
                            COALESCE(BMIRD_MULTI_VAL_GRP_KEY, 1) AS BMIRD_MULTI_VAL_GRP_KEY
            INTO #TMP_MV_GRP
            FROM dbo.v_rdb_obs_mapping rom
            LEFT JOIN dbo.INVESTIGATION inv WITH (nolock) ON inv.CASE_UID=rom.public_health_case_uid
            LEFT JOIN dbo.BMIRD_Case bmc WITH (nolock) ON bmc.INVESTIGATION_KEY = inv.INVESTIGATION_KEY
            WHERE public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) AND RDB_table=@multival_tgt_table_nm;

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #TMP_MV_GRP;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #BMIRD_Multi_Value_field_IDS';

            IF OBJECT_ID('#BMIRD_Multi_Value_field_IDS', 'U') IS NOT NULL
                drop table #BMIRD_Multi_Value_field_IDS;

            WITH id_cte AS (
                SELECT public_health_case_uid, branch_id
                FROM #OBS_CODED_BMIRD_Multi_Value_field
                WHERE public_health_case_uid IS NOT NULL
            ),
                 ordered_selection AS
                     (SELECT public_health_case_uid,
                             branch_id,
                             ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, branch_id ORDER BY branch_id) as row_num
                      FROM id_cte)

            -- distinct here makes it to where we only keep row numbers 1 -> max row num for each phc
            SELECT DISTINCT ids.public_health_case_uid, ids.row_num
            INTO #BMIRD_Multi_Value_field_IDS
            FROM ordered_selection ids
            LEFT JOIN #TMP_MV_GRP mvg ON ids.public_health_case_uid = mvg.public_health_case_uid;

            if
                @debug = 'true'
                select @Proc_Step_Name as step, *
                from #BMIRD_Multi_Value_field_IDS;

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
                @PROC_STEP_NAME = 'INSERTING INTO nrt_bmird_multi_val_group_key';

            DELETE FROM dbo.nrt_bmird_multi_val_group_key;
            INSERT INTO dbo.nrt_bmird_multi_val_group_key (public_health_case_uid)
            SELECT DISTINCT public_health_case_uid
            FROM #TMP_MV_GRP
            WHERE BMIRD_MULTI_VAL_GRP_KEY = 1
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
                @PROC_STEP_NAME = 'INSERTING INTO BMIRD_MULTI_VALUE_FIELD_GROUP';


            INSERT INTO dbo.BMIRD_MULTI_VALUE_FIELD_GROUP (BMIRD_MULTI_VAL_GRP_KEY)
            SELECT BMIRD_MULTI_VAL_GRP_KEY
            FROM dbo.nrt_bmird_multi_val_group_key;

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
                @PROC_STEP_NAME = 'UPDATING #TMP_MV_GRP';

            UPDATE #TMP_MV_GRP
            SET #TMP_MV_GRP.BMIRD_MULTI_VAL_GRP_KEY = mvg.BMIRD_MULTI_VAL_GRP_KEY
            FROM dbo.nrt_bmird_multi_val_group_key mvg
            WHERE mvg.public_health_case_uid = #TMP_MV_GRP.public_health_case_uid;

            if @debug = 'true'
                select @Proc_Step_Name as step, *
                from #TMP_MV_GRP;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERTING INTO nrt_bmird_multi_val_key';

            DELETE FROM dbo.nrt_bmird_multi_val_key;
            INSERT INTO dbo.nrt_bmird_multi_val_key
            (
                BMIRD_MULTI_VAL_GRP_KEY,
                public_health_case_uid,
                selection_number
            )
            SELECT
                mvg.BMIRD_MULTI_VAL_GRP_KEY,
                ids.public_health_case_uid,
                ids.row_num AS selection_number
            FROM #BMIRD_Multi_Value_field_IDS ids
            LEFT JOIN #TMP_MV_GRP mvg
                ON ids.public_health_case_uid = mvg.public_health_case_uid;

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
                NURSING_HOME_KEY,
                DAYCARE_FACILITY_KEY,
                INV_ASSIGNED_DT_KEY,
                1 AS TREATMENT_HOSPITAL_KEY,
                map.diagnosis_time AS FIRST_POSITIVE_CULTURE_DT,
                COALESCE(mvg.BMIRD_MULTI_VAL_GRP_KEY, 1) AS BMIRD_MULTI_VAL_GRP_KEY,
                COALESCE(amg.ANTIMICROBIAL_GRP_KEY, 1) AS ANTIMICROBIAL_GRP_KEY,
                INVESTIGATION_KEY,
                ADT_HSPTL_KEY,
                RPT_SRC_ORG_KEY,
                CONDITION_KEY,
                LDF_GROUP_KEY,
                GEOCODING_LOCATION_KEY
            INTO #KEY_ATTR_INIT
            FROM dbo.v_nrt_inv_keys_attrs_mapping map
            LEFT JOIN #TMP_MV_GRP mvg ON mvg.public_health_case_uid=map.public_health_case_uid
            LEFT JOIN #TMP_AM_GRP amg ON amg.public_health_case_uid=map.public_health_case_uid
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
        SET @PROC_STEP_NAME = 'CHECKING FOR NEW COLUMNS - ' + @am_tgt_table_nm;

        -- run procedure for checking target table schema vs results of temp tables above (antimicrobial)
        exec sp_alter_datamart_schema_postprocessing @batch_id, @datamart_nm, @am_tgt_table_nm, @debug;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'CHECKING FOR NEW COLUMNS - ' + @multival_tgt_table_nm;

        -- run procedure for checking target table schema vs results of temp tables above (multival)
        exec sp_alter_datamart_schema_postprocessing @batch_id, @datamart_nm, @multival_tgt_table_nm, @debug;

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
            FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_BMIRD_Case) AS cols;

            DECLARE @obsnum_columns NVARCHAR(MAX) = '';
            SELECT @obsnum_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_NUMERIC_BMIRD_Case) AS cols;

            DECLARE @obstxt_columns NVARCHAR(MAX) = '';
            SELECT @obstxt_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_TXT_BMIRD_Case) AS cols;

            DECLARE @obsdate_columns NVARCHAR(MAX) = '';
            SELECT @obsdate_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_DATE_BMIRD_Case) AS cols;

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
                    tgt.NURSING_HOME_KEY = src.NURSING_HOME_KEY,
                    tgt.DAYCARE_FACILITY_KEY = src.DAYCARE_FACILITY_KEY,
                    tgt.INV_ASSIGNED_DT_KEY = src.INV_ASSIGNED_DT_KEY,
                    tgt.TREATMENT_HOSPITAL_KEY = src.TREATMENT_HOSPITAL_KEY,
                    tgt.FIRST_POSITIVE_CULTURE_DT = src.FIRST_POSITIVE_CULTURE_DT,
                    tgt.BMIRD_MULTI_VAL_GRP_KEY = src.BMIRD_MULTI_VAL_GRP_KEY,
                    tgt.ANTIMICROBIAL_GRP_KEY = src.ANTIMICROBIAL_GRP_KEY,
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
                                 FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_BMIRD_Case) as cols),
                          '')
                    + IIF(@obsnum_columns != '',
                          ',' + (SELECT STRING_AGG('tgt.'
                                                       + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX))
                                                       + ' = '
                                                       + CAST(converted_column AS NVARCHAR(MAX)),',')
                                 FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_BMIRD_Case) as cols),
                          '')
                    + IIF(@obstxt_columns != '',
                          ',' + (SELECT STRING_AGG('tgt.'
                                                       + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX))
                                                       + ' = ovt.'
                                                       + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)),',')
                                 FROM (SELECT DISTINCT col_nm FROM #OBS_TXT_BMIRD_Case) as cols),
                          '')
                    + IIF(@obsdate_columns != '',
                          ',' + (SELECT STRING_AGG('tgt.'
                                                       + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX))
                                                       + ' = ovd.'
                                                       + CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)),',')
                                 FROM (SELECT DISTINCT col_nm FROM #OBS_DATE_BMIRD_Case) as cols),
                          '')
                + ' FROM #KEY_ATTR_INIT src
                    LEFT JOIN dbo. ' + @tgt_table_nm + ' tgt
                        ON src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY'
                + IIF(@obscoded_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, ' + @obscoded_columns + '
                        FROM ('
                        + @select_phc_col_nm_response
                        + ' FROM #OBS_CODED_BMIRD_Case
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
                        + ' FROM #OBS_NUMERIC_BMIRD_Case
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
                        + ' FROM #OBS_TXT_BMIRD_Case
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
                        + ' FROM #OBS_DATE_BMIRD_Case
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
            FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_BMIRD_Case) AS cols;


            DECLARE @Insert_sql NVARCHAR(MAX) = ''

            SET @Insert_sql = '
            INSERT INTO dbo. ' + @tgt_table_nm + ' (
                INVESTIGATOR_KEY,
                PHYSICIAN_KEY,
                PATIENT_KEY,
                REPORTER_KEY,
                NURSING_HOME_KEY,
                DAYCARE_FACILITY_KEY,
                INV_ASSIGNED_DT_KEY,
                TREATMENT_HOSPITAL_KEY,
                FIRST_POSITIVE_CULTURE_DT,
                BMIRD_MULTI_VAL_GRP_KEY,
                ANTIMICROBIAL_GRP_KEY,
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
                        src.NURSING_HOME_KEY,
                        src.DAYCARE_FACILITY_KEY,
                        src.INV_ASSIGNED_DT_KEY,
                        src.TREATMENT_HOSPITAL_KEY,
                        src.FIRST_POSITIVE_CULTURE_DT,
                        src.BMIRD_MULTI_VAL_GRP_KEY,
                        src.ANTIMICROBIAL_GRP_KEY,
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
                        + ' FROM #OBS_CODED_BMIRD_Case
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
                        + ' FROM #OBS_NUMERIC_BMIRD_Case
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
                        + ' FROM #OBS_TXT_BMIRD_Case
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
                        + ' FROM #OBS_DATE_BMIRD_Case
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
                @PROC_STEP_NAME = 'DELETING Old Keys from ' + @am_tgt_table_nm;

            DELETE FROM dbo.Antimicrobial
            WHERE ANTIMICROBIAL_GRP_KEY > 1 AND EXISTS (
                SELECT 1 FROM #OLD_AM_GRP_KEYS
                WHERE ANTIMICROBIAL_GRP_KEY = dbo.Antimicrobial.ANTIMICROBIAL_GRP_KEY
            );

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'INSERT INTO ' + @am_tgt_table_nm;


            SELECT @obscoded_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_Antimicrobial) AS cols;


            SELECT @obsnum_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_NUMERIC_Antimicrobial) AS cols;


            SELECT @obsnum_insert_columns = COALESCE(
                    STRING_AGG(CAST(converted_column AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm), '')
            FROM (SELECT DISTINCT col_nm, converted_column FROM #OBS_NUMERIC_Antimicrobial) AS cols;


            SET @Insert_sql = '
            INSERT INTO dbo. ' + @am_tgt_table_nm + ' (
                ANTIMICROBIAL_GRP_KEY,
                ANTIMICROBIAL_KEY'
                + IIF(@obscoded_columns != '', ',' + @obscoded_columns, '')
                + IIF(@obsnum_columns != '', ',' + @obsnum_columns, '')
                + ') SELECT
                        src.ANTIMICROBIAL_GRP_KEY,
                        src.ANTIMICROBIAL_KEY'
                + IIF(@obscoded_columns != '', ',' + @obscoded_columns, '')
                + IIF(@obsnum_columns != '', ',' + @obsnum_insert_columns, '')
                + ' FROM dbo.nrt_antimicrobial_key src'
                + IIF(@obscoded_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, row_num, ' + @obscoded_columns + '
                        FROM (
                            SELECT
                                public_health_case_uid,
                                col_nm,
                                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, cd ORDER BY branch_id) AS row_num,
                                response
                            FROM #OBS_CODED_Antimicrobial
                            WHERE public_health_case_uid IS NOT NULL
                            ) AS SourceData
                            PIVOT (
                                MAX(response)
                                FOR col_nm IN (' + @obscoded_columns + ')
                            ) AS PivotTable) ovc
                            ON ovc.public_health_case_uid = src.public_health_case_uid and ovc.row_num = src.selection_number ', ' ') +
                + IIF(@obsnum_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, row_num, ' + @obsnum_columns + '
                        FROM (
                            SELECT
                                public_health_case_uid,
                                col_nm,
                                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, cd ORDER BY branch_id) AS row_num,
                                response
                            FROM #OBS_NUMERIC_Antimicrobial
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
                @PROC_STEP_NAME = 'DELETING Old Keys from ' + @multival_tgt_table_nm;

            DELETE FROM dbo.BMIRD_Multi_Value_field
            WHERE BMIRD_MULTI_VAL_GRP_KEY > 1 AND EXISTS (
                SELECT 1 FROM #OLD_MV_GRP_KEYS
                WHERE BMIRD_MULTI_VAL_GRP_KEY = dbo.BMIRD_Multi_Value_field.BMIRD_MULTI_VAL_GRP_KEY
            );

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'INSERT INTO ' + @multival_tgt_table_nm;


            SELECT @obscoded_columns =
                   COALESCE(STRING_AGG(CAST(QUOTENAME(col_nm) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY col_nm),
                            '')
            FROM (SELECT DISTINCT col_nm FROM #OBS_CODED_BMIRD_Multi_Value_field) AS cols;


            SET @Insert_sql = '
            INSERT INTO dbo. ' + @multival_tgt_table_nm + ' (
                BMIRD_MULTI_VAL_GRP_KEY,
                BMIRD_MULTI_VAL_FIELD_KEY'
                + IIF(@obscoded_columns != '', ',' + @obscoded_columns, '')
                + ') SELECT
                        src.BMIRD_MULTI_VAL_GRP_KEY,
                        src.BMIRD_MULTI_VAL_FIELD_KEY'
                + IIF(@obscoded_columns != '', ',' + @obscoded_columns, '')
                + ' FROM dbo.nrt_bmird_multi_val_key src'
                + IIF(@obscoded_columns != '',
                      ' LEFT JOIN (
                        SELECT public_health_case_uid, row_num, ' + @obscoded_columns + '
                        FROM (
                            SELECT
                                public_health_case_uid,
                                col_nm,
                                ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, branch_id ORDER BY branch_id) AS row_num,
                                response
                            FROM #OBS_CODED_BMIRD_Multi_Value_field
                            WHERE public_health_case_uid IS NOT NULL
                            ) AS SourceData
                            PIVOT (
                                MAX(response)
                                FOR col_nm IN (' + @obscoded_columns + ')
                            ) AS PivotTable) ovc
                            ON ovc.public_health_case_uid = src.public_health_case_uid and ovc.row_num = src.selection_number ', ' ')
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
                @PROC_STEP_NAME = 'DELETE Old Keys from ANTIMICROBIAL_GRP';

            DELETE FROM dbo.ANTIMICROBIAL_GROUP
            WHERE ANTIMICROBIAL_GRP_KEY > 1 AND EXISTS (
                SELECT 1 FROM #OLD_AM_GRP_KEYS
                WHERE ANTIMICROBIAL_GRP_KEY = dbo.ANTIMICROBIAL_GROUP.ANTIMICROBIAL_GRP_KEY
            ) AND NOT EXISTS (
                SELECT 1 FROM #TMP_AM_GRP
                WHERE ANTIMICROBIAL_GRP_KEY = dbo.ANTIMICROBIAL_GROUP.ANTIMICROBIAL_GRP_KEY
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
                @PROC_STEP_NAME = 'DELETE Old Keys from BMIRD_MULTI_VALUE_FIELD_GROUP';

            DELETE FROM dbo.BMIRD_MULTI_VALUE_FIELD_GROUP
            WHERE BMIRD_MULTI_VAL_GRP_KEY > 1 AND EXISTS (
                SELECT 1 FROM #OLD_MV_GRP_KEYS
                WHERE BMIRD_MULTI_VAL_GRP_KEY = dbo.BMIRD_MULTI_VALUE_FIELD_GROUP.BMIRD_MULTI_VAL_GRP_KEY
            ) AND NOT EXISTS (
                SELECT 1 FROM #TMP_MV_GRP
                WHERE BMIRD_MULTI_VAL_GRP_KEY = dbo.BMIRD_MULTI_VALUE_FIELD_GROUP.BMIRD_MULTI_VAL_GRP_KEY
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