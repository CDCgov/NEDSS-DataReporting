CREATE OR ALTER PROCEDURE dbo.sp_nrt_d_rash_loc_gen_postprocessing 
@phc_uids nvarchar(max),
@debug bit = 'false'
AS
BEGIN
    BEGIN TRY
        /* Logging */

            declare @RowCount_no bigint;
            declare @proc_step_no float = 0;
            declare @proc_step_name varchar(200) = '';
            declare @batch_id bigint;
            declare @dataflow_name varchar(200) = 'RASH_LOC_GEN POST-Processing';
            declare @package_name varchar(200) = 'sp_nrt_rash_loc_gen_postprocessing';

        set @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);

        SELECT @ROWCOUNT_NO = 0;

        SET @Proc_Step_Name = 'SP_Start';

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT], [Msg_Description1])
        VALUES (@BATCH_ID, @dataflow_name, @package_name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO, LEFT (@phc_uids, 199));
                
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #PHC_LIST TABLE';

        IF OBJECT_ID('#S_PHC_LIST', 'U') IS NOT NULL
        drop table #S_PHC_LIST;

        SELECT value
        INTO  #S_PHC_LIST
        FROM STRING_SPLIT(@phc_uids, ',')

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_PHC_LIST;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #S_RASH_LOC_GEN_TRANSLATED';

        IF OBJECT_ID('#S_RASH_LOC_GEN_TRANSLATED', 'U') IS NOT NULL
        drop table #S_RASH_LOC_GEN_TRANSLATED;
        
        SELECT DISTINCT
            CAST(VAR.ACT_UID AS BIGINT) AS VAR_PAM_UID,
            VAR.SEQ_NBR, 
            VAR.DATAMART_COLUMN_NM, 
            VAR.NBS_CASE_ANSWER_UID, 
            VAR.ANSWER_TXT, 
            VAR.CODE_SET_GROUP_ID, 
            VAR.LAST_CHG_TIME,
            METADATA.CODE_SET_NM,
            CVG.CODE, 
            CVG.CODE_SHORT_DESC_TXT AS CODE_SHORT_DESC_TXT
        INTO #S_RASH_LOC_GEN_TRANSLATED 
        FROM DBO.NRT_PAGE_CASE_ANSWER VAR with (nolock)
        left join dbo.NRT_INVESTIGATION inv with (nolock)
            on VAR.act_uid = inv.public_health_case_uid
        LEFT JOIN DBO.nrt_srte_Codeset_Group_Metadata METADATA with (nolock)
            ON METADATA.CODE_SET_GROUP_ID = VAR.CODE_SET_GROUP_ID
        LEFT JOIN DBO.nrt_srte_CODE_VALUE_GENERAL CVG  with (nolock)
            ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
            AND CVG.CODE = VAR.ANSWER_TXT
        INNER JOIN #S_PHC_LIST nu
        ON VAR.ACT_UID = nu.value
        WHERE VAR.DATAMART_COLUMN_NM <> 'n/a'
        and isnull(VAR.batch_id, 1) = isnull(INV.batch_id, 1)
        AND QUESTION_IDENTIFIER = 'VAR105';

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_RASH_LOC_GEN_TRANSLATED;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
---------------------------------------------------------------------------------------------------------------------  

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #S_RASH_LOC_GEN';

        IF OBJECT_ID('#S_RASH_LOC_GEN', 'U') IS NOT NULL
        drop table #S_RASH_LOC_GEN;


        SELECT 
            *, 
            CODE_SHORT_DESC_TXT AS VALUE
        INTO #S_RASH_LOC_GEN
        FROM #S_RASH_LOC_GEN_TRANSLATED;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_RASH_LOC_GEN;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
-------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #TEMP_D_RASH_LOC_GEN_DEL';

        IF OBJECT_ID('#TEMP_D_RASH_LOC_GEN_DEL', 'U') IS NOT NULL
        drop table #TEMP_D_RASH_LOC_GEN_DEL;

        SELECT RASH_LOC_GEN.VAR_PAM_UID, 
        RASH_LOC_GEN.D_RASH_LOC_GEN_KEY,
        RASH_LOC_GEN.D_RASH_LOC_GEN_GROUP_KEY
        INTO #TEMP_D_RASH_LOC_GEN_DEL
        FROM DBO.D_RASH_LOC_GEN RASH_LOC_GEN with (nolock)
        LEFT JOIN DBO.NRT_RASH_LOC_GEN_KEY RASH_LOC_GEN_KEY with (nolock)
            ON RASH_LOC_GEN.VAR_PAM_UID = RASH_LOC_GEN_KEY.VAR_PAM_UID AND
            RASH_LOC_GEN.D_RASH_LOC_GEN_KEY = RASH_LOC_GEN_KEY.D_RASH_LOC_GEN_KEY
        LEFT JOIN #S_RASH_LOC_GEN S
        ON S.VAR_PAM_UID = RASH_LOC_GEN_KEY.VAR_PAM_UID AND
            S.NBS_CASE_ANSWER_UID = RASH_LOC_GEN_KEY.NBS_CASE_ANSWER_UID
        WHERE RASH_LOC_GEN.VAR_PAM_UID IN (SELECT value FROM #S_PHC_LIST);


        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEMP_D_RASH_LOC_GEN_DEL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        

---------------------------------------------------------------------------------------------------------------------     

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Deleting from NRT_RASH_LOC_GEN_KEY key';

        DELETE T FROM DBO.NRT_RASH_LOC_GEN_KEY T
        join #TEMP_D_RASH_LOC_GEN_DEL S
        ON S.VAR_PAM_UID =T.VAR_PAM_UID AND
        S.D_RASH_LOC_GEN_KEY = T.D_RASH_LOC_GEN_KEY


        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEMP_D_RASH_LOC_GEN_DEL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        

---------------------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Deleting from NRT_RASH_LOC_GEN_GROUP_KEY';

        DELETE T FROM DBO.NRT_RASH_LOC_GEN_GROUP_KEY T
        join #TEMP_D_RASH_LOC_GEN_DEL S
        ON S.VAR_PAM_UID =T.VAR_PAM_UID AND
        S.D_RASH_LOC_GEN_GROUP_KEY = T.D_RASH_LOC_GEN_GROUP_KEY


        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEMP_D_RASH_LOC_GEN_DEL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        


-------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM DBO.D_RASH_LOC_GEN';


        DELETE T FROM DBO.D_RASH_LOC_GEN T
        join #TEMP_D_RASH_LOC_GEN_DEL S
        ON S.VAR_PAM_UID =T.VAR_PAM_UID AND
        S.D_RASH_LOC_GEN_KEY = T.D_RASH_LOC_GEN_KEY


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        
        COMMIT TRANSACTION;   

---------------------------------------------------------------------------------------------------------------------


        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Insert keys to nrt_rash_loc_gen_group_key ';

        INSERT INTO  DBO.NRT_RASH_LOC_GEN_GROUP_KEY(VAR_PAM_UID) 
        SELECT RASH_LOC_GEN.VAR_PAM_UID FROM (SELECT DISTINCT VAR_PAM_UID FROM #S_RASH_LOC_GEN) RASH_LOC_GEN
        LEFT JOIN DBO.NRT_RASH_LOC_GEN_GROUP_KEY RASH_LOC_GEN_GROUP_KEY  with (nolock)
            ON RASH_LOC_GEN_GROUP_KEY.VAR_PAM_UID = RASH_LOC_GEN.VAR_PAM_UID
        where RASH_LOC_GEN_GROUP_KEY.VAR_PAM_UID is null;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Insert keys to dbo.nrt_rash_loc_gen_key';

        INSERT INTO  DBO.NRT_RASH_LOC_GEN_KEY(VAR_PAM_UID, NBS_CASE_ANSWER_UID) 
        SELECT RASH_LOC_GEN.VAR_PAM_UID, RASH_LOC_GEN.NBS_CASE_ANSWER_UID FROM (SELECT DISTINCT VAR_PAM_UID, NBS_CASE_ANSWER_UID FROM #S_RASH_LOC_GEN) RASH_LOC_GEN
        LEFT JOIN DBO.NRT_RASH_LOC_GEN_KEY RASH_LOC_GEN_KEY  with (nolock)
            ON RASH_LOC_GEN_KEY.VAR_PAM_UID = RASH_LOC_GEN.VAR_PAM_UID
            and RASH_LOC_GEN_KEY.NBS_CASE_ANSWER_UID = RASH_LOC_GEN.NBS_CASE_ANSWER_UID 
        where (RASH_LOC_GEN_KEY.VAR_PAM_UID is null and RASH_LOC_GEN_KEY.NBS_CASE_ANSWER_UID is null);
        

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;

-------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #D_VAR_PAM_TEMP';

        IF OBJECT_ID('#D_VAR_PAM_TEMP', 'U') IS NOT NULL
        drop table #D_VAR_PAM_TEMP;
        

        SELECT DISTINCT D_VAR_PAM.VAR_PAM_UID
            INTO #D_VAR_PAM_TEMP
            FROM   (SELECT DISTINCT VAR_PAM_UID FROM DBO.D_VAR_PAM WHERE VAR_PAM_UID IN (SELECT VALUE FROM #S_PHC_LIST)) D_VAR_PAM
            LEFT JOIN #S_RASH_LOC_GEN RASH_LOC_GEN
                ON RASH_LOC_GEN.VAR_PAM_UID = D_VAR_PAM.VAR_PAM_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #D_VAR_PAM_TEMP;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
-------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #L_RASH_LOC_GEN_GROUP';

        IF OBJECT_ID('#L_RASH_LOC_GEN_GROUP', 'U') IS NOT NULL
        drop table #L_RASH_LOC_GEN_GROUP;

        SELECT D_VAR_PAM.VAR_PAM_UID,   NRT_GROUP_KEY.VAR_PAM_UID AS D_RASH_LOC_GEN_UID , NRT_GROUP_KEY.D_RASH_LOC_GEN_GROUP_KEY
            INTO #L_RASH_LOC_GEN_GROUP
            FROM   #D_VAR_PAM_TEMP D_VAR_PAM
            LEFT OUTER JOIN DBO.NRT_RASH_LOC_GEN_GROUP_KEY NRT_GROUP_KEY  with (nolock)
                ON NRT_GROUP_KEY.VAR_PAM_UID=D_VAR_PAM.VAR_PAM_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #L_RASH_LOC_GEN_GROUP;

         SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
-------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #L_RASH_LOC_GEN';

        IF OBJECT_ID('#L_RASH_LOC_GEN', 'U') IS NOT NULL
        drop table #L_RASH_LOC_GEN;

        SELECT L.VAR_PAM_UID,  
                K.NBS_CASE_ANSWER_UID, 
                CASE WHEN L.D_RASH_LOC_GEN_GROUP_KEY IS NULL THEN 1 ELSE L.D_RASH_LOC_GEN_GROUP_KEY END AS D_RASH_LOC_GEN_GROUP_KEY,
                CASE WHEN K.D_RASH_LOC_GEN_KEY IS NULL THEN 1 ELSE  K.D_RASH_LOC_GEN_KEY END AS D_RASH_LOC_GEN_KEY
        INTO #L_RASH_LOC_GEN
        FROM   #L_RASH_LOC_GEN_GROUP L
        LEFT OUTER JOIN DBO.NRT_RASH_LOC_GEN_KEY K  with (nolock)
            ON K.VAR_PAM_UID=L.VAR_PAM_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #L_RASH_LOC_GEN;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
-------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #TEMP_D_RASH_LOC_GEN';

        IF OBJECT_ID('#TEMP_D_RASH_LOC_GEN', 'U') IS NOT NULL
        drop table #TEMP_D_RASH_LOC_GEN;

        SELECT L.VAR_PAM_UID,
        L.D_RASH_LOC_GEN_KEY,
        S.SEQ_NBR,
        L.D_RASH_LOC_GEN_GROUP_KEY,
        S.LAST_CHG_TIME,
        S.VALUE
        INTO #TEMP_D_RASH_LOC_GEN
        FROM   #L_RASH_LOC_GEN L
        LEFT OUTER JOIN #S_RASH_LOC_GEN S
            ON 	S.VAR_PAM_UID=L.VAR_PAM_UID
            AND S.NBS_CASE_ANSWER_UID= L.NBS_CASE_ANSWER_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEMP_D_RASH_LOC_GEN;

          SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
-------------------------------------------------------------------------------------------       
        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Insert records to  d_rash_loc_gen_group';

        INSERT INTO DBO.D_RASH_LOC_GEN_GROUP
            ([D_RASH_LOC_GEN_GROUP_KEY])
            SELECT 
               DISTINCT
                T.D_RASH_LOC_GEN_GROUP_KEY
            FROM #TEMP_D_RASH_LOC_GEN T
            LEFT JOIN DBO.D_RASH_LOC_GEN_GROUP DG with (nolock)
            ON 	DG.D_RASH_LOC_GEN_GROUP_KEY= T.D_RASH_LOC_GEN_GROUP_KEY
            WHERE DG.D_RASH_LOC_GEN_GROUP_KEY IS NULL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;          
    
-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Update d_rash_loc_gen';

        UPDATE DBO.D_RASH_LOC_GEN
        SET 
        VAR_PAM_UID = T.VAR_PAM_UID,
        SEQ_NBR = T.SEQ_NBR,
        LAST_CHG_TIME = T.LAST_CHG_TIME,
        VALUE = T.VALUE
        FROM #TEMP_D_RASH_LOC_GEN T
        INNER JOIN DBO.D_RASH_LOC_GEN D_RASH_LOC_GEN with (nolock)
            ON 	D_RASH_LOC_GEN.VAR_PAM_UID= T.VAR_PAM_UID
            and D_RASH_LOC_GEN.D_RASH_LOC_GEN_KEY = T.D_RASH_LOC_GEN_KEY
        WHERE D_RASH_LOC_GEN.D_RASH_LOC_GEN_KEY IS NOT NULL;

         SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;       

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Insert records to  d_rash_loc_gen';

        INSERT INTO DBO.D_RASH_LOC_GEN
            ([VAR_PAM_UID]
            ,[D_RASH_LOC_GEN_KEY]
            ,[SEQ_NBR]
            ,[D_RASH_LOC_GEN_GROUP_KEY]
            ,[LAST_CHG_TIME]
            ,[VALUE])
            SELECT 
                T.VAR_PAM_UID,
                T.D_RASH_LOC_GEN_KEY,
                T.SEQ_NBR,
                T.D_RASH_LOC_GEN_GROUP_KEY,
                T.LAST_CHG_TIME,
                T.VALUE
            FROM #TEMP_D_RASH_LOC_GEN T
            LEFT JOIN DBO.D_RASH_LOC_GEN D_RASH_LOC_GEN with (nolock)
            ON 	D_RASH_LOC_GEN.VAR_PAM_UID= T.VAR_PAM_UID
            and D_RASH_LOC_GEN.D_RASH_LOC_GEN_KEY = T.D_RASH_LOC_GEN_KEY
            WHERE D_RASH_LOC_GEN.VAR_PAM_UID IS NULL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;          
--------------------------------------------------------------------------------------------
        BEGIN TRANSACTION


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM DBO.D_RASH_LOC_GEN_GROUP';

        -- update F_VAR_PAM table
        UPDATE F
            SET F.D_RASH_LOC_GEN_GROUP_KEY = D.D_RASH_LOC_GEN_GROUP_KEY
        FROM DBO.F_VAR_PAM F with (nolock)
        INNER JOIN DBO.D_VAR_PAM DIM  with (nolock)
            ON DIM.D_VAR_PAM_KEY = F.D_VAR_PAM_KEY
        INNER JOIN DBO.D_RASH_LOC_GEN D with (nolock)
            ON D.VAR_PAM_UID = DIM.VAR_PAM_UID
        INNER JOIN #S_PHC_LIST S
            ON D.VAR_PAM_UID = S.VALUE;

        -- delete from DBO.D_RASH_LOC_GEN_GROUP
        DELETE T FROM DBO.D_RASH_LOC_GEN_GROUP T with (nolock)
        INNER JOIN #TEMP_D_RASH_LOC_GEN_DEL DEL
            on T.D_RASH_LOC_GEN_GROUP_KEY = DEL.D_RASH_LOC_GEN_GROUP_KEY
        left join (select distinct D_RASH_LOC_GEN_GROUP_KEY from dbo.D_RASH_LOC_GEN with (nolock)) D
            ON D.D_RASH_LOC_GEN_GROUP_KEY = T.D_RASH_LOC_GEN_GROUP_KEY
        WHERE D.D_RASH_LOC_GEN_GROUP_KEY is null;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;         
---------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = 999;

        SET @Proc_Step_Name = 'SP_COMPLETE';

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'COMPLETE', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
    
-------------------------------------------------------------------------------------------
    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0   
            BEGIN
                ROLLBACK TRANSACTION;
            END;

        DECLARE @FullErrorMessage VARCHAR(8000) =
		'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
		'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		'Error Message: ' + ERROR_MESSAGE();


        INSERT INTO dbo.[job_flow_log] (
			batch_id
			,[Dataflow_Name]
			,[package_Name]
			,[Status_Type]
			,[step_number]
			,[step_name]
			,[Error_Description]
			,[row_count]
        )
        VALUES (
            @batch_id
            ,@dataflow_name
            ,@package_name
            ,'ERROR'
            ,@Proc_Step_no
            , @Proc_Step_name
            , @FullErrorMessage
            ,0
		);

        return -1 ;

    END CATCH

END;

---------------------------------------------------END OF PROCEDURE---------------------------------------------------------------------