CREATE OR ALTER PROCEDURE [dbo].[sp_nrt_d_gt_12_reas_postprocessing]
    @phc_id_list nvarchar(max),
    @debug bit = 'false'
AS
BEGIN

    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyyyMMddHHmmss')) AS BIGINT);
    PRINT @batch_id;
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT= 0;
    DECLARE @Proc_Step_Name VARCHAR(200)= '';
	DECLARE @Dataflow_Name VARCHAR(200) = 'D_GT_12_REAS Post-Processing Event';
	DECLARE @Package_Name VARCHAR(200) = 'sp_nrt_d_gt_12_reas_postprocessing';

    BEGIN TRY
        

        SET @Proc_Step_Name = 'SP_Start';

        BEGIN TRANSACTION

            INSERT INTO dbo.job_flow_log ( batch_id
                                        , [Dataflow_Name]
                                        , [package_Name]
                                        , [Status_Type]
                                        , [step_number]
                                        , [step_name]
                                        , [row_count]
                                        , [Msg_Description1])
            VALUES ( @batch_id
                , @Dataflow_Name
                , @Package_Name
                , 'START'
                , @Proc_Step_no
                , @Proc_Step_Name
                , 0
                , LEFT('ID List-' + @phc_id_list, 500));

        COMMIT TRANSACTION;
                
--------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #S_D_GT_12_REAS_TRANSLATED';

            IF OBJECT_ID('#S_D_GT_12_REAS_TRANSLATED', 'U') IS NOT NULL
            drop table #S_D_GT_12_REAS_TRANSLATED;
            
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
                CVG.CODE_SHORT_DESC_TXT
            INTO #S_D_GT_12_REAS_TRANSLATED 
            FROM [dbo].nrt_page_case_answer TB WITH (NOLOCK)
            LEFT JOIN [dbo].nrt_investigation inv WITH(NOLOCK) 
                ON TB.act_uid = inv.public_health_case_uid
            LEFT JOIN [dbo].nrt_srte_Codeset_Group_Metadata METADATA WITH (NOLOCK)
                ON METADATA.CODE_SET_GROUP_ID = TB.CODE_SET_GROUP_ID
            LEFT JOIN [dbo].nrt_srte_code_value_general CVG WITH (NOLOCK)
                ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
                AND CVG.CODE = TB.ANSWER_TXT
            INNER JOIN ( SELECT value FROM STRING_SPLIT(@phc_id_list, ',')) nu ON TB.ACT_UID = nu.value
            WHERE TB.DATAMART_COLUMN_NM <> 'n/a'
            AND ISNULL(tb.batch_id, 1) = ISNULL(inv.batch_id, 1)
            AND QUESTION_IDENTIFIER = 'TUB235';

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #S_D_GT_12_REAS_TRANSLATED;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;

---------------------------------------------------------------------------------------------------------------------        


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #S_D_GT_12_REAS';

            IF OBJECT_ID('#S_D_GT_12_REAS', 'U') IS NOT NULL
                DROP TABLE #S_D_GT_12_REAS;


            SELECT 
                *, 
                CASE 
                    WHEN CODE_SET_GROUP_ID IS NULL OR CODE_SET_GROUP_ID = '' 
                    THEN ANSWER_TXT 
                    WHEN CODE_SET_GROUP_ID<>'' THEN  CODE_SHORT_DESC_TXT 
                    ELSE ANSWER_TXT
                END AS VALUE
            INTO #S_D_GT_12_REAS
            FROM #S_D_GT_12_REAS_TRANSLATED WITH (NOLOCK);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #S_D_GT_12_REAS;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;
-------------------------------------------------------------------------------------------


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERT KEYS TO dbo.nrt_d_gt_12_reas_group_key ';

            INSERT INTO [dbo].nrt_d_gt_12_reas_group_key(TB_PAM_UID) 
            SELECT S.TB_PAM_UID FROM (SELECT DISTINCT TB_PAM_UID FROM #S_D_GT_12_REAS) S
            LEFT JOIN [dbo].nrt_d_gt_12_reas_group_key GK  WITH (NOLOCK)
                ON GK.TB_PAM_UID = S.TB_PAM_UID
            WHERE GK.TB_PAM_UID IS NULL;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM [dbo].nrt_d_gt_12_reas_group_key WITH (NOLOCK);

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERT KEYS TO dbo.nrt_d_gt_12_reas_key';

            INSERT INTO [dbo].nrt_d_gt_12_reas_key(TB_PAM_UID, NBS_CASE_ANSWER_UID) 
            SELECT 
                S.TB_PAM_UID, 
                S.NBS_CASE_ANSWER_UID 
            FROM (SELECT DISTINCT TB_PAM_UID, NBS_CASE_ANSWER_UID FROM #S_D_GT_12_REAS) S
            LEFT JOIN [dbo].nrt_d_gt_12_reas_key K WITH (NOLOCK)
                ON K.TB_PAM_UID = S.TB_PAM_UID
                AND K.NBS_CASE_ANSWER_UID = S.NBS_CASE_ANSWER_UID
            WHERE K.TB_PAM_UID is null;
            

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM [dbo].nrt_d_gt_12_reas_key WITH (NOLOCK);

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
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
                FROM (
                    SELECT DISTINCT TB_PAM_UID 
                    FROM DBO.D_TB_PAM 
                    WHERE TB_PAM_UID IN (SELECT VALUE FROM STRING_SPLIT(@phc_id_list, ','))
                ) D_TB_PAM
                LEFT JOIN #S_D_GT_12_REAS S with (nolock)
                    ON S.TB_PAM_UID = D_TB_PAM.TB_PAM_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_TB_PAM_TEMP;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #L_D_GT_12_REAS_GROUP';

            IF OBJECT_ID('#L_D_GT_12_REAS_GROUP', 'U') IS NOT NULL
                DROP TABLE #L_GT_12_REAS_GROUP;

            SELECT 
                D_TB_PAM.TB_PAM_UID,
                --GK.TB_PAM_UID AS D_ADDL_RISK_UID, --fdkjsfdsf
                GK.D_GT_12_REAS_GROUP_KEY
            INTO #L_D_GT_12_REAS_GROUP
            FROM #D_TB_PAM_TEMP D_TB_PAM
            LEFT OUTER JOIN [dbo].nrt_d_gt_12_reas_group_key GK WITH (NOLOCK)
                ON GK.TB_PAM_UID=D_TB_PAM.TB_PAM_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #L_D_GT_12_REAS_GROUP;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;               

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #L_D_GT_12_REAS';

            IF OBJECT_ID('#L_D_GT_12_REAS', 'U') IS NOT NULL
            drop table #L_D_GT_12_REAS;

            SELECT L.TB_PAM_UID,  
                K.NBS_CASE_ANSWER_UID, 
                COALESCE(L.D_GT_12_REAS_GROUP_KEY, 1) AS D_GT_12_REAS_GROUP_KEY,
                COALESCE(K.D_GT_12_REAS_KEY, 1) AS D_GT_12_REAS_KEY
                --CASE WHEN L.D_GT_12_REAS_GROUP_KEY IS NULL THEN 1 ELSE L.D_GT_12_REAS_GROUP_KEY END AS D_GT_12_REAS_GROUP_KEY,
                --CASE WHEN K.D_GT_12_REAS_KEY IS NULL THEN 1 ELSE  K.D_GT_12_REAS_KEY END AS D_GT_12_REAS_KEY
            INTO #L_D_GT_12_REAS
            FROM #L_D_GT_12_REAS_GROUP L 
            LEFT OUTER JOIN [dbo].nrt_d_gt_12_reas_key K  WITH (NOLOCK)
                ON K.TB_PAM_UID=L.TB_PAM_UID;

            SELECT @RowCount_no = @@ROWCOUNT;
            
            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #L_D_GT_12_REAS;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;           

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #TEMP_D_GT_12_REAS';

            IF OBJECT_ID('#TEMP_D_GT_12_REAS', 'U') IS NOT NULL
                DROP TABLE #TEMP_D_GT_12_REAS;

            SELECT LAR.TB_PAM_UID,
                LAR.D_GT_12_REAS_KEY, 
                S.SEQ_NBR,
                LAR.D_GT_12_REAS_GROUP_KEY,
                S.LAST_CHG_TIME,
                S.VALUE
            INTO #TEMP_D_GT_12_REAS
            FROM #L_D_GT_12_REAS LAR  
            LEFT OUTER JOIN #S_D_GT_12_REAS S
                ON 	S.TB_PAM_UID=LAR.TB_PAM_UID
                AND S.NBS_CASE_ANSWER_UID= LAR.NBS_CASE_ANSWER_UID;

            SELECT @RowCount_no = @@ROWCOUNT;
                
            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #L_D_GT_12_REAS;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;    

-------------------------------------------------------------------------------------------
        
        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERT RECORDS TO D_GT_12_REAS_GROUP';

            INSERT INTO [dbo].d_gt_12_reas_group ([D_GT_12_REAS_GROUP_KEY])
            SELECT DISTINCT
                T.D_GT_12_REAS_GROUP_KEY
            FROM #TEMP_D_GT_12_REAS T 
            LEFT JOIN [dbo].d_gt_12_reas_group G WITH (NOLOCK)
                ON G.D_GT_12_REAS_GROUP_KEY= T.D_GT_12_REAS_GROUP_KEY
            WHERE G.D_GT_12_REAS_GROUP_KEY IS NULL;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;          
    
-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'UPDATE D_GT_12_REAS';

            UPDATE [dbo].D_GT_12_REAS
            SET 
                TB_PAM_UID = T.TB_PAM_UID,
                SEQ_NBR = T.SEQ_NBR,
                LAST_CHG_TIME = T.LAST_CHG_TIME,
                VALUE = T.VALUE
            FROM #TEMP_D_GT_12_REAS T  
            INNER JOIN [dbo].D_GT_12_REAS D with (nolock)
                ON D.TB_PAM_UID= T.TB_PAM_UID 
                AND D.D_GT_12_REAS_KEY = T.D_GT_12_REAS_KEY
            WHERE D.D_GT_12_REAS_KEY IS NOT NULL;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;       

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'INSERT RECORDS TO  D_GT_12_REAS';

        INSERT INTO [dbo].D_GT_12_REAS
            ([TB_PAM_UID]
            ,[D_GT_12_REAS_KEY]
            ,[SEQ_NBR]
            ,[D_GT_12_REAS_GROUP_KEY]
            ,[LAST_CHG_TIME]
            ,[VALUE])
            SELECT 
                T.TB_PAM_UID,
                T.D_GT_12_REAS_KEY,
                T.SEQ_NBR,
                T.D_GT_12_REAS_GROUP_KEY,
                T.LAST_CHG_TIME,
                T.VALUE
            FROM #TEMP_D_GT_12_REAS T  WITH (NOLOCK)
            LEFT JOIN [dbo].D_GT_12_REAS D WITH (NOLOCK)
            ON 	D.TB_PAM_UID= T.TB_PAM_UID
            AND D.D_GT_12_REAS_KEY = T.D_GT_12_REAS_KEY
            WHERE D.TB_PAM_UID IS NULL;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;          
-------------------------------------------------------------------------------------------

        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);
    
-------------------------------------------------------------------------------------------
END TRY

BEGIN CATCH

	IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

	-- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();


        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'ERROR', @Proc_Step_no, @Proc_Step_name, @FullErrorMessage, 0);

	return -1 ;

END CATCH

END;


---------------------------------------------------END OF PROCEDURE---------------------------------------------------------------------
