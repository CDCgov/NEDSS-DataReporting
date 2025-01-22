CREATE OR ALTER PROCEDURE [dbo].[sp_user_profile_postprocessing] @id_list nvarchar(max), @debug bit = 'false'
AS
BEGIN

    DECLARE @batch_id bigint;
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
    SET @batch_id = cast((format(getdate(), 'yyMMddHHmmss')) as bigint);
    DECLARE @dataflow_name varchar(200) = 'User_Profile POST-Processing';
    DECLARE @package_name varchar(200) = 'sp_user_profile_postprocessing';


    BEGIN TRY
        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';

        BEGIN TRANSACTION;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ---------------@batch_id
                                         , [Dataflow_Name] --------------'User_Profile'
                                         , [package_Name] --------------'sp_user_profile_postprocessing'
                                         , [Status_Type] ---------------START
                                         , [step_number] ---------------@Proc_Step_no
                                         , [step_name] ------------------@Proc_Step_Name=sp_start
                                         , [row_count] --------------------0
        )
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @Proc_Step_no
               , @Proc_Step_Name
               , 0);
        COMMIT TRANSACTION;


-------------------------------------------------1. CREATE TABLE TMP_PROVIDER_USER_DIMENSION---------------------------------------------------------------------------

        BEGIN TRANSACTION;
        SET @Proc_Step_name = 'Create #TMP_PROVIDER_USER_DIMENSION';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        IF OBJECT_ID('#TMP_PROVIDER_USER_DIMENSION', 'U') IS NOT NULL
            drop table #TMP_PROVIDER_USER_DIMENSION;


        SELECT substring(RTRIM(LTRIM(a.FIRST_NM)), 1, 50) AS FIRST_NM,
               substring(RTRIM(LTRIM(a.LAST_NM)), 1, 50)  AS LAST_NM,
               a.LAST_CHG_TIME                            AS LAST_UPDT_TIME,
               a.NEDSS_ENTRY_ID,
               a.PROVIDER_UID
        INTO #TMP_PROVIDER_USER_DIMENSION
        FROM dbo.nrt_auth_user a
        WHERE A.auth_user_uid IN (SELECT value FROM STRING_SPLIT(@id_list, ','))
        ORDER BY NEDSS_ENTRY_ID;


        IF @debug = 'true' SELECT * FROM #TMP_PROVIDER_USER_DIMENSION;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @dataflow_name, @package_name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;
        --Select * from TMP_PROVIDER_USER_DIMENSION
-------------------------------------------------2. CREATE TABLE TMP_USER_PROVIDER---------------------------------------------------
        BEGIN TRANSACTION;
        SET @Proc_Step_name = 'Create #TMP_USER_PROVIDER';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        IF OBJECT_ID('#TMP_USER_PROVIDER', 'U') IS NOT NULL
            drop table #TMP_USER_PROVIDER;

        SELECT distinct PROVIDER_UID
        INTO #TMP_USER_PROVIDER
        FROM #TMP_PROVIDER_USER_DIMENSION
        where PROVIDER_UID is not null;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @dataflow_name, @package_name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;
-----------------------------------------------3. CREATE TMP_USER_PROVIDER_KEY----------------------------------------------------------------------------------
        BEGIN TRANSACTION;
        SET @Proc_Step_name = 'Create #TMP_USER_PROVIDER_KEY';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        IF OBJECT_ID('#TMP_USER_PROVIDER_KEY', 'U') IS NOT NULL
            drop table #TMP_USER_PROVIDER_KEY;

        SELECT T.PROVIDER_UID,
               D.PROVIDER_KEY,
               substring([PROVIDER_QUICK_CODE], 1, 50) AS PROVIDER_QUICK_CODE
        INTO #TMP_USER_PROVIDER_KEY
        FROM #TMP_USER_PROVIDER T
                 INNER JOIN dbo.D_PROVIDER D on
            T.PROVIDER_UID = D.PROVIDER_UID;

        IF @debug = 'true' SELECT * FROM #TMP_USER_PROVIDER_KEY;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @dataflow_name, @package_name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO)
        COMMIT TRANSACTION;
        ----Select * from TMP_USER_PROVIDER_KEY
-----------------------------------------------4. CREATE TMP_USER_PROFILE----------------------------------------------------------------------------------

        BEGIN TRANSACTION;
        SET @Proc_Step_name = 'Create #TMP_USER_PROFILE';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;


        IF OBJECT_ID('#TMP_USER_PROFILE', 'U') IS NOT NULL
            drop table #TMP_USER_PROFILE;

        IF OBJECT_ID('#USER_PROFILE_FINAL', 'U') IS NOT NULL
            drop table #USER_PROFILE_FINAL;

        SELECT P.*,
               T.provider_key,
               T.PROVIDER_QUICK_CODE
        INTO #TMP_USER_PROFILE
        from #TMP_PROVIDER_USER_DIMENSION P
                 LEFT JOIN #TMP_USER_PROVIDER_KEY T ON P.PROVIDER_UID = T.PROVIDER_UID
        ORDER BY NEDSS_ENTRY_ID;

        SELECT FIRST_NM,
               LAST_NM,
               LAST_UPDT_TIME,
               NEDSS_ENTRY_ID,
               PROVIDER_UID,
               COALESCE(PROVIDER_KEY,1) AS PROVIDER_KEY,
               PROVIDER_QUICK_CODE,
               CASE
                   WHEN LEN(LAST_NM) > 0 AND LEN(FIRST_NM) > 0
                       THEN CAST(substring(LAST_NM, 1, 49) + ', ' + substring(FIRST_NM, 1, 49) as varchar(100))
                   WHEN LEN(LAST_NM) <= 0 AND LEN(FIRST_NM) > 0 THEN CAST(substring(FIRST_NM, 1, 49) as varchar(100))
                   WHEN LEN(LAST_NM) > 0 AND LEN(FIRST_NM) <= 0 THEN CAST(substring(LAST_NM, 1, 49) as varchar(100))
                   ELSE NULL
                   END AS USER_NM
        INTO #USER_PROFILE_FINAL
        FROM (SELECT *,
                     ROW_NUMBER() OVER (PARTITION BY NEDSS_ENTRY_ID order by NEDSS_ENTRY_ID ) rowid
              FROM #TMP_USER_PROFILE) AS CTE
        WHERE rowid = 1;

        IF @debug = 'true' SELECT * FROM #USER_PROFILE_FINAL;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @dataflow_name, @package_name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        -----------------------------------------------5. Insert in Table USER_PROFILE ----------------------------------------------------------------------------------

        BEGIN TRANSACTION;
        SET @Proc_Step_name = 'Insert into USER_PROFILE';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        INSERT INTO dbo.USER_PROFILE
        (FIRST_NM,
         LAST_NM,
         LAST_UPD_TIME,
         NEDSS_ENTRY_ID,
         PROVIDER_UID,
         PROVIDER_KEY,
         PROVIDER_QUICK_CODE,
         USER_NM)

        SELECT FIRST_NM,
               LAST_NM,
               LAST_UPDT_TIME,
               NEDSS_ENTRY_ID,
               PROVIDER_UID,
               PROVIDER_KEY,
               PROVIDER_QUICK_CODE,
               USER_NM
        FROM #USER_PROFILE_FINAL T

        WHERE NOT EXISTS
                  (SELECT FIRST_NM,
                          LAST_NM,
                          LAST_UPDT_TIME,
                          NEDSS_ENTRY_ID,
                          PROVIDER_UID,
                          PROVIDER_KEY,
                          PROVIDER_QUICK_CODE,
                          USER_NM
                   FROM dbo.[USER_PROFILE] with (nolock)
                   WHERE [NEDSS_ENTRY_ID] = T.[NEDSS_ENTRY_ID])
        ORDER BY [NEDSS_ENTRY_ID]


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @dataflow_name, @package_name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

-----------------------------------------------6. Update in Table USER_PROFILE----------------------------------------------------------------------------------

        BEGIN TRANSACTION;
        SET @Proc_Step_name = 'Update into USER_PROFILE';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        UPDATE dbo.USER_PROFILE
        SET FIRST_NM            = F.FIRST_NM,           ----------1
            LAST_NM             = F.LAST_NM,            -----------2
            LAST_UPD_TIME       = F.LAST_UPDT_TIME,     ----3
            PROVIDER_QUICK_CODE = F.PROVIDER_QUICK_CODE,--4
            PROVIDER_UID        = F.PROVIDER_UID,       ------5
            PROVIDER_KEY        = F.PROVIDER_KEY,       ------6
            USER_NM             =F.USER_NM              -------7
        FROM #USER_PROFILE_FINAL F
        WHERE F.nedss_entry_id = USER_PROFILE.NEDSS_ENTRY_ID


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @dataflow_name, @package_name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


----------------------------------------------Dropping all tmp tables.------------------------------

        IF OBJECT_ID('#TMP_PROVIDER_USER_DIMENSION', 'U') IS NOT NULL ---Step1
            drop table #TMP_PROVIDER_USER_DIMENSION;
        IF OBJECT_ID('#TMP_USER_PROVIDER', 'U') IS NOT NULL ------------Step2
            drop table #TMP_USER_PROVIDER;
        IF OBJECT_ID('#TMP_USER_PROVIDER_KEY', 'U') IS NOT NULL --------Step3
            drop table #TMP_USER_PROVIDER_KEY;
        IF OBJECT_ID('#TMP_USER_PROFILE', 'U') IS NOT NULL ------------Step4
            drop table #TMP_USER_PROFILE;
        IF OBJECT_ID('#USER_PROFILE_FINAL', 'U') IS NOT NULL
            drop table #USER_PROFILE_FINAL;

----------------------------------------------------------------------------------------------------------------
        BEGIN TRANSACTION ;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
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


        COMMIT TRANSACTION;
    END TRY
--------------------------------------------------------------------------------------------------------------------------------------------------------------
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();


        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [Error_Description]
        , [row_count])
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'ERROR'
               , @Proc_Step_no
               , 'ERROR - ' + @Proc_Step_name
               , 'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
               , 0);


        return -1;

    END CATCH

END;

