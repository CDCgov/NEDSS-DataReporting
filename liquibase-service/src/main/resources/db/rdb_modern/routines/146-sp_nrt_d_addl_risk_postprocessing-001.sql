CREATE OR ALTER PROCEDURE dbo.sp_nrt_d_addl_risk_postprocessing 
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
            declare @dataflow_name varchar(200) = 'ADDL_RISK POST-Processing';
            declare @package_name varchar(200) = 'RDB_MODERN.sp_nrt_addl_risk_postprocessing';

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
            @PROC_STEP_NAME = 'GENERATING #S_ADDL_RISK_CD_TRANSLATED';

        IF OBJECT_ID('#S_ADDL_RISK_CD_TRANSLATED', 'U') IS NOT NULL
        drop table #S_ADDL_RISK_CD_TRANSLATED;
        
        SELECT 
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
        INTO #S_ADDL_RISK_CD_TRANSLATED 
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
        AND QUESTION_IDENTIFIER = 'TUB167';

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_ADDL_RISK_CD_TRANSLATED;

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
            @PROC_STEP_NAME = 'GENERATING #S_ADDL_RISK';

        IF OBJECT_ID('#S_ADDL_RISK', 'U') IS NOT NULL
        drop table #S_ADDL_RISK;


        SELECT 
            *, 
            CASE 
                WHEN CODE_SET_GROUP_ID IS NULL OR CODE_SET_GROUP_ID = '' 
                THEN ANSWER_TXT 
                WHEN CODE_SET_GROUP_ID<>'' THEN  CODE_SHORT_DESC_TXT 
                ELSE ANSWER_TXT
            END AS VALUE
        INTO #S_ADDL_RISK
        FROM #S_ADDL_RISK_CD_TRANSLATED with (nolock);

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_ADDL_RISK;

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
            @PROC_STEP_NAME = 'GENERATING #TEMP_D_ADDL_RISK_DEL';

        IF OBJECT_ID('#TEMP_D_ADDL_RISK_DEL', 'U') IS NOT NULL
        drop table #TEMP_D_ADDL_RISK_DEL;

        SELECT ADDL_RISK.TB_PAM_UID, 
        ADDL_RISK.D_ADDL_RISK_KEY,
        ADDL_RISK.D_ADDL_RISK_GROUP_KEY
        INTO #TEMP_D_ADDL_RISK_DEL
        FROM DBO.D_ADDL_RISK ADDL_RISK with (nolock)
        LEFT JOIN DBO.NRT_ADDL_RISK_KEY ADDL_RISK_KEY with (nolock)
            ON ADDL_RISK.TB_PAM_UID = ADDL_RISK_KEY.TB_PAM_UID AND
            ADDL_RISK.D_ADDL_RISK_KEY = ADDL_RISK_KEY.D_ADDL_RISK_KEY
        LEFT JOIN #S_ADDL_RISK S with (nolock)
        ON S.TB_PAM_UID = ADDL_RISK_KEY.TB_PAM_UID AND
            S.NBS_CASE_ANSWER_UID = ADDL_RISK_KEY.NBS_CASE_ANSWER_UID
        WHERE ADDL_RISK.TB_PAM_UID IN (SELECT value FROM #S_PHC_LIST) AND
        S.NBS_CASE_ANSWER_UID IS NULL;


        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEMP_D_ADDL_RISK_DEL;

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
            @PROC_STEP_NAME = 'Deleting from NRT_ADDL_RISK_KEY key';

        DELETE T FROM DBO.NRT_ADDL_RISK_KEY T
        join #TEMP_D_ADDL_RISK_DEL S with (nolock)
        ON S.TB_PAM_UID =T.TB_PAM_UID AND
        S.D_ADDL_RISK_KEY = T.D_ADDL_RISK_KEY


        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEMP_D_ADDL_RISK_DEL;

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
            @PROC_STEP_NAME = 'Deleting from NRT_ADDL_RISK_GROUP_KEY';

        DELETE T FROM DBO.NRT_ADDL_RISK_GROUP_KEY T
        join #TEMP_D_ADDL_RISK_DEL S with (nolock)
        ON S.TB_PAM_UID =T.TB_PAM_UID AND
        S.D_ADDL_RISK_GROUP_KEY = T.D_ADDL_RISK_GROUP_KEY


        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEMP_D_ADDL_RISK_DEL;

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
            @PROC_STEP_NAME = 'DELETING FROM DBO.D_ADDL_RISK';


        DELETE T FROM DBO.D_ADDL_RISK T
        join #TEMP_D_ADDL_RISK_DEL S with (nolock)
        ON S.TB_PAM_UID =T.TB_PAM_UID AND
        S.D_ADDL_RISK_KEY = T.D_ADDL_RISK_KEY


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
            @PROC_STEP_NAME = 'Insert keys to nrt_addl_risk_group_key ';

        INSERT INTO  DBO.NRT_ADDL_RISK_GROUP_KEY(TB_PAM_UID) 
        SELECT ADDL_RISK.TB_PAM_UID FROM (SELECT DISTINCT TB_PAM_UID FROM #S_ADDL_RISK) ADDL_RISK
        LEFT JOIN DBO.NRT_ADDL_RISK_GROUP_KEY ADDL_RISK_GROUP_KEY  with (nolock)
            ON ADDL_RISK_GROUP_KEY.TB_PAM_UID = ADDL_RISK.TB_PAM_UID
        where ADDL_RISK_GROUP_KEY.TB_PAM_UID is null;

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
            @PROC_STEP_NAME = 'Insert keys to dbo.nrt_addl_risk_key';

        INSERT INTO  DBO.NRT_ADDL_RISK_KEY(TB_PAM_UID, NBS_CASE_ANSWER_UID) 
        SELECT ADDL_RISK.TB_PAM_UID, ADDL_RISK.NBS_CASE_ANSWER_UID FROM (SELECT DISTINCT TB_PAM_UID, NBS_CASE_ANSWER_UID FROM #S_ADDL_RISK) ADDL_RISK
        LEFT JOIN DBO.NRT_ADDL_RISK_KEY ADDL_RISK_KEY  with (nolock)
            ON ADDL_RISK_KEY.TB_PAM_UID = ADDL_RISK.TB_PAM_UID
            and ADDL_RISK_KEY.NBS_CASE_ANSWER_UID = ADDL_RISK.NBS_CASE_ANSWER_UID 
        where (ADDL_RISK_KEY.TB_PAM_UID is null and ADDL_RISK_KEY.NBS_CASE_ANSWER_UID is null);
        

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
            LEFT JOIN #S_ADDL_RISK ADDL_RISK  with (nolock)
                ON ADDL_RISK.TB_PAM_UID = D_TB_PAM.TB_PAM_UID;

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
            @PROC_STEP_NAME = 'GENERATING #L_ADDL_RISK_GROUP';

        IF OBJECT_ID('#L_ADDL_RISK_GROUP', 'U') IS NOT NULL
        drop table #L_ADDL_RISK_GROUP;

        SELECT D_TB_PAM.TB_PAM_UID,   NRT_GROUP_KEY.TB_PAM_UID AS D_ADDL_RISK_UID , NRT_GROUP_KEY.D_ADDL_RISK_GROUP_KEY
            INTO #L_ADDL_RISK_GROUP
            FROM   #D_TB_PAM_TEMP D_TB_PAM  with (nolock)
            LEFT OUTER JOIN DBO.NRT_ADDL_RISK_GROUP_KEY NRT_GROUP_KEY  with (nolock)
                ON NRT_GROUP_KEY.TB_PAM_UID=D_TB_PAM.TB_PAM_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #L_ADDL_RISK_GROUP;

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
            @PROC_STEP_NAME = 'GENERATING #L_ADDL_RISK';

        IF OBJECT_ID('#L_ADDL_RISK', 'U') IS NOT NULL
        drop table #L_ADDL_RISK;

        SELECT L.TB_PAM_UID,  
                K.NBS_CASE_ANSWER_UID, 
                CASE WHEN L.D_ADDL_RISK_GROUP_KEY IS NULL THEN 1 ELSE L.D_ADDL_RISK_GROUP_KEY END AS D_ADDL_RISK_GROUP_KEY,
                CASE WHEN K.D_ADDL_RISK_KEY IS NULL THEN 1 ELSE  K.D_ADDL_RISK_KEY END AS D_ADDL_RISK_KEY
        INTO #L_ADDL_RISK
        FROM   #L_ADDL_RISK_GROUP L  with (nolock)
        LEFT OUTER JOIN DBO.NRT_ADDL_RISK_KEY K  with (nolock)
            ON K.TB_PAM_UID=L.TB_PAM_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #L_ADDL_RISK;

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
            @PROC_STEP_NAME = 'GENERATING #TEMP_D_ADDL_RISK';

        IF OBJECT_ID('#TEMP_D_ADDL_RISK', 'U') IS NOT NULL
        drop table #TEMP_D_ADDL_RISK;

        SELECT L.TB_PAM_UID,
        L.D_ADDL_RISK_KEY,
        S.SEQ_NBR,
        L.D_ADDL_RISK_GROUP_KEY,
        S.LAST_CHG_TIME,
        S.VALUE
        INTO #TEMP_D_ADDL_RISK
        FROM   #L_ADDL_RISK L  with (nolock)
        LEFT OUTER JOIN #S_ADDL_RISK S  with (nolock)
            ON 	S.TB_PAM_UID=L.TB_PAM_UID
            AND S.NBS_CASE_ANSWER_UID= L.NBS_CASE_ANSWER_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEMP_D_ADDL_RISK;

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
            @PROC_STEP_NAME = 'Insert records to  d_addl_risk_group';

        INSERT INTO DBO.D_ADDL_RISK_GROUP
            ([D_ADDL_RISK_GROUP_KEY])
            SELECT 
               DISTINCT
                T.D_ADDL_RISK_GROUP_KEY
            FROM #TEMP_D_ADDL_RISK T  with (nolock)
            LEFT JOIN DBO.D_ADDL_RISK_GROUP DG with (nolock)
            ON 	DG.D_ADDL_RISK_GROUP_KEY= T.D_ADDL_RISK_GROUP_KEY
            WHERE DG.D_ADDL_RISK_GROUP_KEY IS NULL;

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
            @PROC_STEP_NAME = 'Update d_addl_risk';

        UPDATE DBO.D_ADDL_RISK
        SET 
        TB_PAM_UID = T.TB_PAM_UID,
        SEQ_NBR = T.SEQ_NBR,
        LAST_CHG_TIME = T.LAST_CHG_TIME,
        VALUE = T.VALUE
        FROM #TEMP_D_ADDL_RISK T  with (nolock)
        INNER JOIN DBO.D_ADDL_RISK D_ADDL_RISK with (nolock)
            ON 	D_ADDL_RISK.TB_PAM_UID= T.TB_PAM_UID
            and D_ADDL_RISK.D_ADDL_RISK_KEY = T.D_ADDL_RISK_KEY
        WHERE D_ADDL_RISK.D_ADDL_RISK_KEY IS NOT NULL;

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
            @PROC_STEP_NAME = 'Insert records to  d_addl_risk';

        INSERT INTO DBO.D_ADDL_RISK
            ([TB_PAM_UID]
            ,[D_ADDL_RISK_KEY]
            ,[SEQ_NBR]
            ,[D_ADDL_RISK_GROUP_KEY]
            ,[LAST_CHG_TIME]
            ,[VALUE])
            SELECT 
                T.TB_PAM_UID,
                T.D_ADDL_RISK_KEY,
                T.SEQ_NBR,
                T.D_ADDL_RISK_GROUP_KEY,
                T.LAST_CHG_TIME,
                T.VALUE
            FROM #TEMP_D_ADDL_RISK T  with (nolock)
            LEFT JOIN DBO.D_ADDL_RISK D_ADDL_RISK with (nolock)
            ON 	D_ADDL_RISK.TB_PAM_UID= T.TB_PAM_UID
            and D_ADDL_RISK.D_ADDL_RISK_KEY = T.D_ADDL_RISK_KEY
            WHERE D_ADDL_RISK.TB_PAM_UID IS NULL;

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
