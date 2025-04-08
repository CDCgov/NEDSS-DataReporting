CREATE OR ALTER PROCEDURE dbo.sp_nrt_d_move_cntry_postprocessing 
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
            declare @dataflow_name varchar(200) = 'MOVE_CNTRY POST-Processing';
            declare @package_name varchar(200) = 'RDB_MODERN.sp_nrt_move_cntry_postprocessing';

        set @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);

        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT], [Msg_Description1])
        VALUES (@BATCH_ID, @dataflow_name, @package_name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO, LEFT (@phc_uids, 199));
                
--------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION
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
        
        COMMIT TRANSACTION;

--------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #S_MOVE_CNTRY_TRANSLATED';

        IF OBJECT_ID('#S_MOVE_CNTRY_TRANSLATED', 'U') IS NOT NULL
        drop table #S_MOVE_CNTRY_TRANSLATED;
        
        SELECT DISTINCT
            CAST(TB.ACT_UID AS BIGINT) AS TB_PAM_UID,
            TB.SEQ_NBR, 
            TB.DATAMART_COLUMN_NM, 
            TB.NBS_CASE_ANSWER_UID, 
            TB.ANSWER_TXT, 
            TB.CODE_SET_GROUP_ID, 
            TB.LAST_CHG_TIME,
            METADATA.CODE_SET_NM,
            CVG.CODE, 
            CVG.CODE_SHORT_DESC_TXT AS CODE_SHORT_DESC_TXT
        INTO #S_MOVE_CNTRY_TRANSLATED 
        FROM DBO.NRT_PAGE_CASE_ANSWER TB with (nolock)
        left join dbo.NRT_INVESTIGATION inv with(nolock)
            on TB.act_uid = inv.public_health_case_uid
        LEFT JOIN DBO.nrt_srte_Codeset_Group_Metadata METADATA with (nolock)
            ON METADATA.CODE_SET_GROUP_ID = TB.CODE_SET_GROUP_ID
        LEFT JOIN DBO.nrt_srte_CODE_VALUE_GENERAL CVG  with (nolock)
            ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
            AND CVG.CODE = TB.ANSWER_TXT
        INNER JOIN #S_PHC_LIST nu with (nolock)
        ON TB.ACT_UID = nu.value
        WHERE TB.DATAMART_COLUMN_NM <> 'n/a'
        and isnull(tb.batch_id, 1) = isnull(inv.batch_id, 1)
        AND QUESTION_IDENTIFIER = 'TUB230';

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_MOVE_CNTRY_TRANSLATED;

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
            @PROC_STEP_NAME = 'GENERATING #S_MOVE_CNTRY';

        IF OBJECT_ID('#S_MOVE_CNTRY', 'U') IS NOT NULL
        drop table #S_MOVE_CNTRY;


        SELECT 
            *, 
            CODE_SHORT_DESC_TXT AS VALUE
        INTO #S_MOVE_CNTRY
        FROM #S_MOVE_CNTRY_TRANSLATED with (nolock);

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_MOVE_CNTRY;

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
            @PROC_STEP_NAME = 'GENERATING #TEMP_D_MOVE_CNTRY_DEL';

        IF OBJECT_ID('#TEMP_D_MOVE_CNTRY_DEL', 'U') IS NOT NULL
        drop table #TEMP_D_MOVE_CNTRY_DEL;

        SELECT MOVE_CNTRY.TB_PAM_UID, 
        MOVE_CNTRY.D_MOVE_CNTRY_KEY,
        MOVE_CNTRY.D_MOVE_CNTRY_GROUP_KEY
        INTO #TEMP_D_MOVE_CNTRY_DEL
        FROM DBO.D_MOVE_CNTRY MOVE_CNTRY with (nolock)
        LEFT JOIN DBO.NRT_MOVE_CNTRY_KEY MOVE_CNTRY_KEY with (nolock)
            ON MOVE_CNTRY.TB_PAM_UID = MOVE_CNTRY_KEY.TB_PAM_UID AND
            MOVE_CNTRY.D_MOVE_CNTRY_KEY = MOVE_CNTRY_KEY.D_MOVE_CNTRY_KEY
        LEFT JOIN #S_MOVE_CNTRY S with (nolock)
        ON S.TB_PAM_UID = MOVE_CNTRY_KEY.TB_PAM_UID AND
            S.NBS_CASE_ANSWER_UID = MOVE_CNTRY_KEY.NBS_CASE_ANSWER_UID
        WHERE MOVE_CNTRY.TB_PAM_UID IN (SELECT value FROM #S_PHC_LIST) AND
        S.NBS_CASE_ANSWER_UID IS NULL;


        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEMP_D_MOVE_CNTRY_DEL;

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
            @PROC_STEP_NAME = 'Deleting from NRT_MOVE_CNTRY_KEY key';

        DELETE T FROM DBO.NRT_MOVE_CNTRY_KEY T
        join #TEMP_D_MOVE_CNTRY_DEL S with (nolock)
        ON S.TB_PAM_UID =T.TB_PAM_UID AND
        S.D_MOVE_CNTRY_KEY = T.D_MOVE_CNTRY_KEY;


        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEMP_D_MOVE_CNTRY_DEL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        

---------------------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Deleting from NRT_MOVE_CNTRY_GROUP_KEY';

        DELETE T FROM DBO.NRT_MOVE_CNTRY_GROUP_KEY T
        join #TEMP_D_MOVE_CNTRY_DEL S with (nolock)
        ON S.TB_PAM_UID =T.TB_PAM_UID AND
        S.D_MOVE_CNTRY_GROUP_KEY = T.D_MOVE_CNTRY_GROUP_KEY;


        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEMP_D_MOVE_CNTRY_DEL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        


-------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM DBO.D_MOVE_CNTRY';


        DELETE T FROM DBO.D_MOVE_CNTRY T
        join #TEMP_D_MOVE_CNTRY_DEL S with (nolock)
        ON S.TB_PAM_UID =T.TB_PAM_UID AND
        S.D_MOVE_CNTRY_KEY = T.D_MOVE_CNTRY_KEY;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        

---------------------------------------------------------------------------------------------------------------------


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM DBO.D_MOVE_CNTRY_GROUP';

        -- update F_TB_PAM table
        UPDATE F
            SET F.D_MOVE_CNTRY_GROUP_KEY = 1
        FROM DBO.F_TB_PAM F
        INNER JOIN #TEMP_D_MOVE_CNTRY_DEL T on T.D_MOVE_CNTRY_GROUP_KEY = F.D_MOVE_CNTRY_GROUP_KEY;

        -- delete from DBO.D_MOVE_CNTRY_GROUP
        DELETE T FROM DBO.D_MOVE_CNTRY_GROUP T
        left join (select distinct D_MOVE_CNTRY_GROUP_KEY from dbo.d_move_cntry) DBO
            ON DBO.D_MOVE_CNTRY_GROUP_KEY = T.D_MOVE_CNTRY_GROUP_KEY
        WHERE DBO.D_MOVE_CNTRY_GROUP_KEY is null;


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
            @PROC_STEP_NAME = 'Insert keys to nrt_move_cntry_group_key ';

        INSERT INTO  DBO.NRT_MOVE_CNTRY_GROUP_KEY(TB_PAM_UID) 
        SELECT MOVE_CNTRY.TB_PAM_UID FROM (SELECT DISTINCT TB_PAM_UID FROM #S_MOVE_CNTRY) MOVE_CNTRY
        LEFT JOIN DBO.NRT_MOVE_CNTRY_GROUP_KEY MOVE_CNTRY_GROUP_KEY  with (nolock)
            ON MOVE_CNTRY_GROUP_KEY.TB_PAM_UID = MOVE_CNTRY.TB_PAM_UID
        where MOVE_CNTRY_GROUP_KEY.TB_PAM_UID is null;

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
            @PROC_STEP_NAME = 'Insert keys to dbo.nrt_move_cntry_key';

        INSERT INTO  DBO.NRT_MOVE_CNTRY_KEY(TB_PAM_UID, NBS_CASE_ANSWER_UID) 
        SELECT MOVE_CNTRY.TB_PAM_UID, MOVE_CNTRY.NBS_CASE_ANSWER_UID FROM (SELECT DISTINCT TB_PAM_UID, NBS_CASE_ANSWER_UID FROM #S_MOVE_CNTRY) MOVE_CNTRY
        LEFT JOIN DBO.NRT_MOVE_CNTRY_KEY MOVE_CNTRY_KEY  with (nolock)
            ON MOVE_CNTRY_KEY.TB_PAM_UID = MOVE_CNTRY.TB_PAM_UID
            and MOVE_CNTRY_KEY.NBS_CASE_ANSWER_UID = MOVE_CNTRY.NBS_CASE_ANSWER_UID 
        where (MOVE_CNTRY_KEY.TB_PAM_UID is null and MOVE_CNTRY_KEY.NBS_CASE_ANSWER_UID is null);
        

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
            @PROC_STEP_NAME = 'GENERATING #D_TB_PAM_TEMP';

        IF OBJECT_ID('#D_TB_PAM_TEMP', 'U') IS NOT NULL
        drop table #D_TB_PAM_TEMP;
        

        SELECT DISTINCT D_TB_PAM.TB_PAM_UID
            INTO #D_TB_PAM_TEMP
            FROM   (SELECT DISTINCT TB_PAM_UID FROM DBO.D_TB_PAM WHERE TB_PAM_UID IN (SELECT VALUE FROM #S_PHC_LIST)) D_TB_PAM
            LEFT JOIN #S_MOVE_CNTRY MOVE_CNTRY  with (nolock)
                ON MOVE_CNTRY.TB_PAM_UID = D_TB_PAM.TB_PAM_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #D_TB_PAM_TEMP;

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
            @PROC_STEP_NAME = 'GENERATING #L_MOVE_CNTRY_GROUP';

        IF OBJECT_ID('#L_MOVE_CNTRY_GROUP', 'U') IS NOT NULL
        drop table #L_MOVE_CNTRY_GROUP;

        SELECT D_TB_PAM.TB_PAM_UID,   NRT_GROUP_KEY.TB_PAM_UID AS D_MOVE_CNTRY_UID , NRT_GROUP_KEY.D_MOVE_CNTRY_GROUP_KEY
            INTO #L_MOVE_CNTRY_GROUP
            FROM   #D_TB_PAM_TEMP D_TB_PAM  with (nolock)
            LEFT OUTER JOIN DBO.NRT_MOVE_CNTRY_GROUP_KEY NRT_GROUP_KEY  with (nolock)
                ON NRT_GROUP_KEY.TB_PAM_UID=D_TB_PAM.TB_PAM_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #L_MOVE_CNTRY_GROUP;

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
            @PROC_STEP_NAME = 'GENERATING #L_MOVE_CNTRY';

        IF OBJECT_ID('#L_MOVE_CNTRY', 'U') IS NOT NULL
        drop table #L_MOVE_CNTRY;

        SELECT L.TB_PAM_UID,  
                K.NBS_CASE_ANSWER_UID, 
                CASE WHEN L.D_MOVE_CNTRY_GROUP_KEY IS NULL THEN 1 ELSE L.D_MOVE_CNTRY_GROUP_KEY END AS D_MOVE_CNTRY_GROUP_KEY,
                CASE WHEN K.D_MOVE_CNTRY_KEY IS NULL THEN 1 ELSE  K.D_MOVE_CNTRY_KEY END AS D_MOVE_CNTRY_KEY
        INTO #L_MOVE_CNTRY
        FROM   #L_MOVE_CNTRY_GROUP L  with (nolock)
        LEFT OUTER JOIN DBO.NRT_MOVE_CNTRY_KEY K  with (nolock)
            ON K.TB_PAM_UID=L.TB_PAM_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #L_MOVE_CNTRY;

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
            @PROC_STEP_NAME = 'GENERATING #TEMP_D_MOVE_CNTRY';

        IF OBJECT_ID('#TEMP_D_MOVE_CNTRY', 'U') IS NOT NULL
        drop table #TEMP_D_MOVE_CNTRY;

        SELECT L.TB_PAM_UID,
        L.D_MOVE_CNTRY_KEY,
        S.SEQ_NBR,
        L.D_MOVE_CNTRY_GROUP_KEY,
        S.LAST_CHG_TIME,
        S.VALUE
        INTO #TEMP_D_MOVE_CNTRY
        FROM   #L_MOVE_CNTRY L  with (nolock)
        LEFT OUTER JOIN #S_MOVE_CNTRY S  with (nolock)
            ON 	S.TB_PAM_UID=L.TB_PAM_UID
            AND S.NBS_CASE_ANSWER_UID= L.NBS_CASE_ANSWER_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEMP_D_MOVE_CNTRY;

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
            @PROC_STEP_NAME = 'Insert records to  d_move_cntry_group';

        INSERT INTO DBO.D_MOVE_CNTRY_GROUP
            ([D_MOVE_CNTRY_GROUP_KEY])
            SELECT 
               DISTINCT
                T.D_MOVE_CNTRY_GROUP_KEY
            FROM #TEMP_D_MOVE_CNTRY T  with (nolock)
            LEFT JOIN DBO.D_MOVE_CNTRY_GROUP DG with (nolock)
            ON 	DG.D_MOVE_CNTRY_GROUP_KEY= T.D_MOVE_CNTRY_GROUP_KEY
            WHERE DG.D_MOVE_CNTRY_GROUP_KEY IS NULL;

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
            @PROC_STEP_NAME = 'Update d_move_cntry';

        UPDATE DBO.D_MOVE_CNTRY
        SET 
        TB_PAM_UID = T.TB_PAM_UID,
        SEQ_NBR = T.SEQ_NBR,
        LAST_CHG_TIME = T.LAST_CHG_TIME,
        VALUE = T.VALUE
        FROM #TEMP_D_MOVE_CNTRY T  with (nolock)
        INNER JOIN DBO.D_MOVE_CNTRY D_MOVE_CNTRY with (nolock)
            ON 	D_MOVE_CNTRY.TB_PAM_UID= T.TB_PAM_UID
            and D_MOVE_CNTRY.D_MOVE_CNTRY_KEY = T.D_MOVE_CNTRY_KEY
        WHERE D_MOVE_CNTRY.D_MOVE_CNTRY_KEY IS NOT NULL;

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
            @PROC_STEP_NAME = 'Insert records to  d_move_cntry';

        INSERT INTO DBO.D_MOVE_CNTRY
            ([TB_PAM_UID]
            ,[D_MOVE_CNTRY_KEY]
            ,[SEQ_NBR]
            ,[D_MOVE_CNTRY_GROUP_KEY]
            ,[LAST_CHG_TIME]
            ,[VALUE])
            SELECT 
                T.TB_PAM_UID,
                T.D_MOVE_CNTRY_KEY,
                T.SEQ_NBR,
                T.D_MOVE_CNTRY_GROUP_KEY,
                T.LAST_CHG_TIME,
                T.VALUE
            FROM #TEMP_D_MOVE_CNTRY T  with (nolock)
            LEFT JOIN DBO.D_MOVE_CNTRY D_MOVE_CNTRY with (nolock)
            ON 	D_MOVE_CNTRY.TB_PAM_UID= T.TB_PAM_UID
            and D_MOVE_CNTRY.D_MOVE_CNTRY_KEY = T.D_MOVE_CNTRY_KEY
            WHERE D_MOVE_CNTRY.TB_PAM_UID IS NULL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;          
--------------------------------------------------------------------------------------------

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
