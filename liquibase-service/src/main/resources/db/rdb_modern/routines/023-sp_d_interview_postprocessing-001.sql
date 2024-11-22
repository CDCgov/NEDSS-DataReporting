CREATE OR ALTER PROCEDURE dbo.sp_d_interview_postprocessing(
    @interview_uids NVARCHAR(MAX),
    @debug bit = 'false')
as

BEGIN

    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
    DECLARE @ColumnAdd_sql NVARCHAR(MAX) = '';
    DECLARE @PivotColumns NVARCHAR(MAX) = '';
    DECLARE @Pivot_sql NVARCHAR(MAX) = '';
    DECLARE @Insert_sql NVARCHAR(MAX) = '';
    DECLARE @Update_sql NVARCHAR(MAX) = '';
    -- number of columns for the dynamic sql
    DECLARE @Col_number BIGINT = (SELECT COUNT(*) FROM dbo.nrt_metadata_columns);

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';
        DECLARE @batch_id bigint;
        SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmss')) AS bigint);

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

        IF @ColumnAdd_sql IS NOT NULL
            BEGIN
                EXEC sp_executesql @ColumnAdd_sql;
            END

        UPDATE dbo.nrt_metadata_columns
        SET NEW_FLAG = 0
        WHERE NEW_FLAG = 1
          AND TABLE_NAME = 'D_INTERVIEW';

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #INTERVIEW_INIT';

        SELECT INTERVIEW_UID,
               interview_status_cd AS IX_STATUS_CD,
               interview_date      AS IX_DATE,
               interviewee_role_cd AS IX_INTERVIEWEE_ROLE_CD,
               interview_type_cd   AS IX_TYPE_CD,
               interview_loc_cd    AS IX_LOCATION_CD,
               local_id,
               record_status_cd,
               record_status_time,
               ADD_TIME,
               add_user_id,
               last_chg_time,
               last_chg_user_id,
               version_ctrl_nbr,
               IX_STATUS,
               IX_TYPE,
               IX_LOCATION,
               IX_INTERVIEWEE_ROLE
        INTO #INTERVIEW_INIT
        FROM dbo.nrt_interview
        WHERE interview_uid in (SELECT value FROM STRING_SPLIT(@interview_uids, ','));

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #INTERVIEW_INIT;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #INTERVIEW_ANSWERS';

        SELECT interview_uid,
               rdb_column_nm,
               answer_val
        INTO #INTERVIEW_ANSWERS
        FROM dbo.nrt_interview_answer
        WHERE interview_uid in (SELECT value FROM STRING_SPLIT(@interview_uids, ','));

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #INTERVIEW_ANSWERS;

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
            @PROC_STEP_NAME = ' GENERATING #L_INTERVIEW_N ';


        IF
            OBJECT_ID('#L_INTERVIEW_N', 'U') IS NOT NULL
            drop table #L_INTERVIEW_N;


        CREATE TABLE #L_INTERVIEW_N
        (
            [id]              [int] IDENTITY
                (
                1,
                1
                )                              NOT NULL,
            [INTERVIEW_UID]   [numeric](20, 0) NULL,
            [D_INTERVIEW_KEY] [numeric](18, 0) NULL
        ) ON [PRIMARY];


        insert into #L_INTERVIEW_N ([INTERVIEW_UID])
        SELECT DISTINCT INTERVIEW_UID
        FROM #INTERVIEW_INIT
        EXCEPT
        SELECT INTERVIEW_UID
        FROM dbo.L_INTERVIEW lt;

        UPDATE #L_INTERVIEW_N
        SET D_INTERVIEW_KEY = id + coalesce((SELECT MAX(D_INTERVIEW_KEY) FROM dbo.L_INTERVIEW), 0)


        DELETE
        FROM #L_INTERVIEW_N
        WHERE INTERVIEW_UID IS NULL;


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
            @PROC_STEP_NAME = 'INSERTING INTO L_INTERVIEW';


        INSERT INTO dbo.L_INTERVIEW
        ( [D_INTERVIEW_KEY]
        , [INTERVIEW_UID])
        SELECT [D_INTERVIEW_KEY], [INTERVIEW_UID]
        FROM #L_INTERVIEW_N;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'INSERT INTO D_INTERVIEW';

        SET @PivotColumns = (SELECT STRING_AGG(QUOTENAME(RDB_COLUMN_NM), ',')
                             FROM dbo.nrt_metadata_columns);

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
        FROM dbo.nrt_metadata_columns) + ') '
        ELSE ')' end +
                          ' SELECT 
                          li.D_INTERVIEW_KEY,
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
                          FROM dbo.nrt_metadata_columns)
                          ELSE '' END +
                          'FROM #L_INTERVIEW_N li
                          LEFT JOIN #INTERVIEW_INIT ix
                              ON li.interview_uid = ix.interview_uid'
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
        ELSE '' END;


        exec sp_executesql @Insert_sql;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'UPDATE D_INTERVIEW';

        SET @PivotColumns = (SELECT STRING_AGG(QUOTENAME(RDB_COLUMN_NM), ',')
                             FROM dbo.nrt_metadata_columns);


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
                                                 FROM dbo.nrt_metadata_columns)
            ELSE '' END +
        ' FROM 
        #INTERVIEW_INIT ix
        LEFT JOIN dbo.L_INTERVIEW lint
            ON ix.interview_uid = lint.interview_uid
        LEFT JOIN dbo.D_INTERVIEW dl
            ON lint.d_interview_key = dl.d_interview_key '
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
        ix.interview_uid NOT IN (SELECT interview_uid FROM #L_INTERVIEW_N);';

        SELECT @Update_sql;

        exec sp_executesql @Update_sql;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #INTERVIEW_NOTE_INIT';

        SELECT ixn.interview_uid,
               lint.d_interview_key,
               ixn.nbs_answer_uid,
               ixn.user_first_name,
               ixn.user_last_name,
               ixn.user_comment,
               ixn.comment_date
        INTO #INTERVIEW_NOTE_INIT
        FROM dbo.nrt_interview_note ixn
                 LEFT JOIN dbo.L_INTERVIEW lint
                           ON ixn.interview_uid = lint.interview_uid
        WHERE ixn.interview_uid in (SELECT value FROM STRING_SPLIT(@interview_uids, ','));


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
            @PROC_STEP_NAME = ' GENERATING #L_INTERVIEW_NOTE_N ';


        IF
            OBJECT_ID('#L_INTERVIEW__NOTE_N', 'U') IS NOT NULL
            drop table #L_INTERVIEW_NOTE_N;


        CREATE TABLE #L_INTERVIEW_NOTE_N
        (
            [id]                   [int] IDENTITY
                (
                1,
                1
                )                                   NOT NULL,
            [D_INTERVIEW_KEY]      [numeric](20, 0) NULL,
            [D_INTERVIEW_NOTE_KEY] [numeric](18, 0) NULL,
            [NBS_ANSWER_UID]       [numeric](18, 0) NULL
        ) ON [PRIMARY];


        insert into #L_INTERVIEW_NOTE_N (D_INTERVIEW_KEY, NBS_ANSWER_UID)
        SELECT DISTINCT D_INTERVIEW_KEY, NBS_ANSWER_UID
        FROM #INTERVIEW_NOTE_INIT
        EXCEPT
        SELECT D_INTERVIEW_KEY, NBS_ANSWER_UID
        FROM dbo.L_INTERVIEW_NOTE;

        UPDATE #L_INTERVIEW_NOTE_N
        SET D_INTERVIEW_NOTE_KEY = id + coalesce((SELECT MAX(D_INTERVIEW_NOTE_KEY) FROM dbo.L_INTERVIEW_NOTE), 0)


        DELETE
        FROM #L_INTERVIEW_NOTE_N
        WHERE NBS_ANSWER_UID IS NULL;


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
            @PROC_STEP_NAME = 'INSERTING INTO L_INTERVIEW_NOTE';


        INSERT INTO dbo.L_INTERVIEW_NOTE
        ( D_INTERVIEW_KEY
        , D_INTERVIEW_NOTE_KEY
        , NBS_ANSWER_UID)
        SELECT D_INTERVIEW_KEY, D_INTERVIEW_NOTE_KEY, NBS_ANSWER_UID
        FROM #L_INTERVIEW_NOTE_N;


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
        SELECT lintn.D_INTERVIEW_KEY,
               lintn.D_INTERVIEW_NOTE_KEY,
               ixn.NBS_ANSWER_UID,
               ixn.USER_FIRST_NAME,
               ixn.USER_LAST_NAME,
               ixn.USER_COMMENT,
               ixn.COMMENT_DATE
        FROM #L_INTERVIEW_NOTE_N lintn
                 LEFT JOIN #INTERVIEW_NOTE_INIT ixn
                           ON lintn.NBS_ANSWER_UID = ixn.nbs_answer_uid;


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
            @PROC_STEP_NAME = 'UPDATE D_INTERVIEW_NOTE';

        UPDATE din
        SET din.USER_FIRST_NAME = ixn.USER_FIRST_NAME,
            din.USER_LAST_NAME  = ixn.USER_LAST_NAME,
            din.USER_COMMENT    = ixn.USER_COMMENT,
            din.COMMENT_DATE    = ixn.COMMENT_DATE
        FROM #INTERVIEW_NOTE_INIT ixn
                 LEFT JOIN dbo.D_INTERVIEW_NOTE din
                           ON ixn.NBS_ANSWER_UID = din.NBS_ANSWER_UID
        WHERE ixn.NBS_ANSWER_UID NOT IN (SELECT NBS_ANSWER_UID FROM #L_INTERVIEW_NOTE_N);


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_INTERVIEW', 'D_INTERVIEW', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;


        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();


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
               , 'ERROR - ' + @Proc_Step_name
               , 'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
               , 0);


        return -1;

    END CATCH

END

    ;