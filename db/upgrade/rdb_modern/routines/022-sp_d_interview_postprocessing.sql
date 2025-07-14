IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_d_interview_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_d_interview_postprocessing]
END
GO 

CREATE PROCEDURE dbo.sp_d_interview_postprocessing(
    @interview_uids NVARCHAR(MAX),
    @debug bit = 'false')
as

BEGIN

    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
    DECLARE @ColumnAdd_sql NVARCHAR(MAX) = '';
    DECLARE @PivotColumns NVARCHAR(MAX) = '';
    DECLARE @Insert_sql NVARCHAR(MAX) = '';
    DECLARE @Update_sql NVARCHAR(MAX) = '';
    -- number of columns for the dynamic sql
    DECLARE @Col_number BIGINT = (SELECT COUNT(*) FROM dbo.nrt_metadata_columns where TABLE_NAME ='D_INTERVIEW');

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';
        DECLARE @batch_id bigint;
        SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmssffff')) AS bigint);

        BEGIN TRANSACTION;

        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #NEW_COLUMNS';

        SELECT RDB_COLUMN_NM
        INTO #NEW_COLUMNS
        FROM dbo.nrt_metadata_columns
        WHERE NEW_FLAG = 1
          AND RDB_COLUMN_NM NOT IN (SELECT COLUMN_NAME
                                    FROM INFORMATION_SCHEMA.COLUMNS
                                    WHERE TABLE_NAME = 'D_INTERVIEW'
                                      AND TABLE_SCHEMA = 'dbo');

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'ADDING COLUMNS TO D_INTERVIEW';

        SELECT @ColumnAdd_sql =
               STRING_AGG('ALTER TABLE dbo.D_INTERVIEW ADD ' + QUOTENAME(RDB_COLUMN_NM) + ' VARCHAR(50);',
                          CHAR(13) + CHAR(10))
        FROM #NEW_COLUMNS;


        -- if there aren't any new columns to add, sp_executesql won't fire
        IF @ColumnAdd_sql IS NOT NULL
            BEGIN
                EXEC sp_executesql @ColumnAdd_sql;
            END

        UPDATE dbo.nrt_metadata_columns
        SET NEW_FLAG = 0
        WHERE NEW_FLAG = 1
        AND TABLE_NAME = 'D_INTERVIEW'
        AND RDB_COLUMN_NM IN (
            SELECT COLUMN_NAME
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = 'D_INTERVIEW'
              AND TABLE_SCHEMA = 'dbo'
        );

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #INTERVIEW_INIT';

        SELECT ix.INTERVIEW_UID,
               ixk.D_INTERVIEW_KEY,
               ix.interview_status_cd AS IX_STATUS_CD,
               ix.interview_date      AS IX_DATE,
               ix.interviewee_role_cd AS IX_INTERVIEWEE_ROLE_CD,
               ix.interview_type_cd   AS IX_TYPE_CD,
               ix.interview_loc_cd    AS IX_LOCATION_CD,
               ix.local_id,
               ix.record_status_cd,
               ix.record_status_time,
               ix.ADD_TIME,
               ix.add_user_id,
               ix.last_chg_time,
               ix.last_chg_user_id,
               ix.version_ctrl_nbr,
               ix.IX_STATUS,
               ix.IX_TYPE,
               ix.IX_LOCATION,
               ix.IX_INTERVIEWEE_ROLE
        INTO #INTERVIEW_INIT
        FROM dbo.nrt_interview ix
            LEFT JOIN dbo.nrt_interview_key ixk
                ON ix.interview_uid = ixk.interview_uid
        WHERE ix.interview_uid in (SELECT value FROM STRING_SPLIT(@interview_uids, ','));

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #INTERVIEW_INIT;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        declare @backfill_list nvarchar(max);
        SET @backfill_list =
        (
            SELECT string_agg(t.value, ',')
            FROM (SELECT distinct TRIM(value) AS value FROM STRING_SPLIT(@interview_uids, ',')) t
                left join #INTERVIEW_INIT tmp
                on tmp.interview_uid = t.value
                WHERE tmp.interview_uid is null
        );

        IF @backfill_list IS NOT NULL
        BEGIN
            SELECT
                0 AS public_health_case_uid,
                CAST(NULL AS BIGINT) AS patient_uid,
                CAST(NULL AS BIGINT) AS observation_uid,
                'Error' AS datamart,
                CAST(NULL AS VARCHAR(50))  AS condition_cd,
                'Missing NRT Record: sp_d_interview_postprocessing' AS stored_procedure,
                CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
                WHERE 1=1;
            RETURN;

        END
        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #INTERVIEW_ANSWERS';

        SELECT intans.interview_uid,
               rdb_column_nm,
               answer_val
        INTO #INTERVIEW_ANSWERS
        FROM
        dbo.NRT_INTERVIEW_ANSWER intans  with(nolock)
        left outer join dbo.NRT_INTERVIEW inv with(nolock)
        on intans.interview_uid = inv.interview_uid
        where isnull(intans.batch_id, 1) = isnull(inv.batch_id, 1)
        and inv.interview_uid in (SELECT value FROM STRING_SPLIT(@interview_uids, ','));

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #INTERVIEW_ANSWERS;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'UPDATE nrt_interview_key';

        update k
        SET
          k.updated_dttm = GETDATE()
        FROM dbo.nrt_interview_key k
          INNER JOIN #INTERVIEW_INIT d
            ON K.d_interview_key = d.d_interview_key;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'INSERT INTO nrt_interview_key';

        INSERT INTO dbo.nrt_interview_key(interview_uid)
        SELECT
            INTERVIEW_UID
        FROM #INTERVIEW_INIT
        WHERE D_INTERVIEW_KEY IS NULL;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'UPDATE D_INTERVIEW';

        SET @PivotColumns = (SELECT STRING_AGG(QUOTENAME(RDB_COLUMN_NM), ',')
                             FROM dbo.nrt_metadata_columns where TABLE_NAME ='D_INTERVIEW' );


        /*
        Query is built one part after another, adding in extra parts
        for the dynamic columns if @Col_number > 0
        */
        SET @Update_sql = '
        UPDATE dl
        SET
        dl.IX_STATUS_CD = ix.IX_STATUS_CD,
        dl.IX_DATE = ix.IX_DATE,
        dl.IX_INTERVIEWEE_ROLE_CD = ix.IX_INTERVIEWEE_ROLE_CD,
        dl.IX_TYPE_CD = ix.IX_TYPE_CD,
        dl.IX_LOCATION_CD = ix.IX_LOCATION_CD,
        dl.LOCAL_ID = ix.LOCAL_ID,
        dl.RECORD_STATUS_CD = ix.RECORD_STATUS_CD,
        dl.RECORD_STATUS_TIME = ix.RECORD_STATUS_TIME,
        dl.ADD_TIME = ix.ADD_TIME,
        dl.ADD_USER_ID = ix.ADD_USER_ID,
        dl.LAST_CHG_TIME = ix.LAST_CHG_TIME,
        dl.LAST_CHG_USER_ID = ix.LAST_CHG_USER_ID,
        dl.VERSION_CTRL_NBR = ix.VERSION_CTRL_NBR,
        dl.IX_STATUS = ix.IX_STATUS,
        dl.IX_INTERVIEWEE_ROLE = ix.IX_INTERVIEWEE_ROLE,
        dl.IX_TYPE = ix.IX_TYPE,
        dl.IX_LOCATION = ix.IX_LOCATION
        ' + CASE
                WHEN @Col_number > 0 THEN ',' + (SELECT STRING_AGG('dl.' + QUOTENAME(RDB_COLUMN_NM) + ' = pv.' + QUOTENAME(RDB_COLUMN_NM),',')
                                                 FROM dbo.nrt_metadata_columns where TABLE_NAME ='D_INTERVIEW')
            ELSE '' END +
        ' FROM
        #INTERVIEW_INIT ix
        LEFT JOIN dbo.D_INTERVIEW dl
            ON ix.d_interview_key = dl.d_interview_key '
        + CASE
              WHEN @Col_number > 0 THEN
        ' LEFT JOIN (
        SELECT interview_uid, ' + @PivotColumns + '
        FROM (
            SELECT
                interview_uid,
                rdb_column_nm,
                answer_val
            FROM
                #INTERVIEW_ANSWERS
        ) AS SourceData
        PIVOT (
            MAX(answer_val)
            FOR rdb_column_nm IN (' + @PivotColumns + ')
        ) AS PivotTable) pv
        ON pv.interview_uid = ix.interview_uid'
        ELSE ' ' END +
        ' WHERE
        ix.D_INTERVIEW_KEY IS NOT NULL;';

        exec sp_executesql @Update_sql;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'INSERT INTO D_INTERVIEW';

        SET @PivotColumns = (SELECT STRING_AGG(QUOTENAME(RDB_COLUMN_NM), ',')
                             FROM dbo.nrt_metadata_columns where TABLE_NAME ='D_INTERVIEW');

        /*
        Query is built one part after another, adding in extra parts
        for the dynamic columns if @Col_number > 0
        */
        SET @Insert_sql = '
        INSERT INTO dbo.D_INTERVIEW (
        D_INTERVIEW_KEY,
        IX_STATUS_CD,
        IX_DATE,
        IX_INTERVIEWEE_ROLE_CD,
        IX_TYPE_CD,
        IX_LOCATION_CD,
        LOCAL_ID,
        RECORD_STATUS_CD,
        RECORD_STATUS_TIME,
        ADD_TIME,
        ADD_USER_ID,
        LAST_CHG_TIME,
        LAST_CHG_USER_ID,
        VERSION_CTRL_NBR,
        IX_STATUS,
        IX_INTERVIEWEE_ROLE,
        IX_TYPE,
        IX_LOCATION
        ' + CASE
        WHEN @Col_number > 0 THEN ',' +
        (SELECT STRING_AGG(QUOTENAME(RDB_COLUMN_NM), ',')
        FROM dbo.nrt_metadata_columns where TABLE_NAME ='D_INTERVIEW') + ') '
        ELSE ')' end +
                          ' SELECT
                          ixk.D_INTERVIEW_KEY,
                          ix.IX_STATUS_CD,
                          ix.IX_DATE,
                          ix.IX_INTERVIEWEE_ROLE_CD,
                          ix.IX_TYPE_CD,
                          ix.IX_LOCATION_CD,
                          ix.LOCAL_ID,
                          ix.RECORD_STATUS_CD,
                          ix.RECORD_STATUS_TIME,
                          ix.ADD_TIME,
                          ix.ADD_USER_ID,
                          ix.LAST_CHG_TIME,
                          ix.LAST_CHG_USER_ID,
                          ix.VERSION_CTRL_NBR,
                          ix.IX_STATUS,
                          ix.IX_INTERVIEWEE_ROLE,
                          ix.IX_TYPE,
                          ix.IX_LOCATION
                          ' + CASE
                          WHEN @Col_number > 0 THEN ',' +
                          (SELECT STRING_AGG('pv.' + QUOTENAME(RDB_COLUMN_NM), ',')
                          FROM dbo.nrt_metadata_columns where TABLE_NAME ='D_INTERVIEW')
                          ELSE ' ' END +
                          'FROM #INTERVIEW_INIT ix
                          LEFT JOIN dbo.nrt_interview_key ixk
                              ON ixk.interview_uid = ix.interview_uid
                          LEFT JOIN dbo.D_INTERVIEW dint
                              ON ixk.D_INTERVIEW_KEY = dint.D_INTERVIEW_KEY
                             '
            + CASE
            WHEN @Col_number > 0 THEN
         ' LEFT JOIN (
        SELECT interview_uid, ' + @PivotColumns + '
    FROM (
        SELECT
            interview_uid,
            rdb_column_nm,
            answer_val
        FROM
            #INTERVIEW_ANSWERS
    ) AS SourceData
    PIVOT (
        MAX(answer_val)
        FOR rdb_column_nm IN (' + @PivotColumns + ')
    ) AS PivotTable) pv
    ON pv.interview_uid = ix.interview_uid '
        ELSE ' ' END
        + ' WHERE (ix.D_INTERVIEW_KEY IS NULL
             OR dint.D_INTERVIEW_KEY IS NULL)
             AND ixk.D_INTERVIEW_KEY IS NOT NULL';


        exec sp_executesql @Insert_sql;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #INTERVIEW_NOTE_INIT';

        SELECT ixn.interview_uid,
               ixk.d_interview_key,
               ixnk.d_interview_note_key,
               ixn.nbs_answer_uid,
               ixn.user_first_name,
               ixn.user_last_name,
               ixn.user_comment,
               ixn.comment_date
        INTO #INTERVIEW_NOTE_INIT
        FROM
            dbo.NRT_INTERVIEW_NOTE ixn  with(nolock)
        left join dbo.NRT_INTERVIEW inv with(nolock)
        on ixn.interview_uid = inv.interview_uid
        LEFT JOIN dbo.NRT_INTERVIEW_KEY ixk
            ON ixn.interview_uid = ixk.interview_uid
        LEFT JOIN dbo.NRT_INTERVIEW_NOTE_KEY ixnk
            ON ixn.nbs_answer_uid = ixnk.nbs_answer_uid
            AND ixk.d_interview_key = ixnk.d_interview_key
        WHERE isnull(ixn.batch_id, 1) = isnull(inv.batch_id, 1) and ixn.interview_uid in (SELECT value FROM STRING_SPLIT(@interview_uids, ','));


        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #INTERVIEW_NOTE_INIT;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Remove existing comments from D_INTERVIEW_NOTE';

        /*
        There is no update step for D_INTERVIEW_NOTE.
        This is because each time a new interview note is created or an existing interview note is updated/deleted,
        all associated interview notes are deleted from NBS_ODSE.dbo.NBS_ANSWER.

        So, it is necessary to delete and reinsert every time.
        */
        DELETE FROM dbo.D_INTERVIEW_NOTE
        WHERE D_INTERVIEW_KEY IN (SELECT D_INTERVIEW_KEY FROM #INTERVIEW_NOTE_INIT WHERE D_INTERVIEW_KEY IS NOT NULL);

        -- remove old keys
        DELETE FROM dbo.nrt_interview_note_key
        WHERE D_INTERVIEW_KEY IN (SELECT D_INTERVIEW_KEY FROM #INTERVIEW_NOTE_INIT WHERE D_INTERVIEW_KEY IS NOT NULL);


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'INSERT INTO nrt_interview_note_key';

        INSERT INTO dbo.nrt_interview_note_key(d_interview_key,nbs_answer_uid)
        SELECT
            D_INTERVIEW_KEY,
            NBS_ANSWER_UID
        FROM #INTERVIEW_NOTE_INIT
        WHERE D_INTERVIEW_KEY IS NOT NULL;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'INSERTING INTO D_INTERVIEW_NOTE';


        INSERT INTO dbo.D_INTERVIEW_NOTE (D_INTERVIEW_KEY,
                                          D_INTERVIEW_NOTE_KEY,
                                          NBS_ANSWER_UID,
                                          USER_FIRST_NAME,
                                          USER_LAST_NAME,
                                          USER_COMMENT,
                                          COMMENT_DATE)
        SELECT ixnk.D_INTERVIEW_KEY,
               ixnk.D_INTERVIEW_NOTE_KEY,
               ixn.NBS_ANSWER_UID,
               ixn.USER_FIRST_NAME,
               ixn.USER_LAST_NAME,
               ixn.USER_COMMENT,
               ixn.COMMENT_DATE
        FROM #INTERVIEW_NOTE_INIT ixn
            LEFT JOIN dbo.nrt_interview_note_key ixnk
                ON ixn.D_INTERVIEW_KEY = ixnk.D_INTERVIEW_KEY
                AND ixn.NBS_ANSWER_UID = ixnk.NBS_ANSWER_UID;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_INTERVIEW', 'D_INTERVIEW', 'COMPLETE', 999, 'COMPLETE', 0);

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
               , 'D_INTERVIEW'
               , 'D_INTERVIEW'
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

END

    ;