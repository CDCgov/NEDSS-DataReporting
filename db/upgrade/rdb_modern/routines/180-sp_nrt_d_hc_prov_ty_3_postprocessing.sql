CREATE OR ALTER PROCEDURE [dbo].[sp_nrt_d_hc_prov_ty_3_postprocessing] 
    @phc_id_list nvarchar(max),
    @debug bit = 'false'
AS
BEGIN

    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) AS BIGINT);
    PRINT @batch_id;
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT= 0;
    DECLARE @Proc_Step_Name VARCHAR(200)= '';
	DECLARE @Dataflow_Name VARCHAR(200) = 'D_HC_PROV_TY_3 POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_nrt_d_hc_prov_ty_3_postprocessing';

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
            @PROC_STEP_NAME = 'GENERATING #D_HC_PROV_TY_3_PHC_LIST TABLE';

        IF OBJECT_ID('#D_HC_PROV_TY_3_PHC_LIST', 'U') IS NOT NULL
            drop table #D_HC_PROV_TY_3_PHC_LIST;

        SELECT value
        INTO  #D_HC_PROV_TY_3_PHC_LIST
        FROM STRING_SPLIT(@phc_id_list, ',')

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #D_HC_PROV_TY_3_PHC_LIST;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;
        
--------------------------------------------------------------------------------------------------------
        
        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #S_D_HC_PROV_TY_3_TRANSLATED';

            IF OBJECT_ID('#S_D_HC_PROV_TY_3_TRANSLATED', 'U') IS NOT NULL
                DROP TABLE #S_D_HC_PROV_TY_3_TRANSLATED;
            
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
            INTO #S_D_HC_PROV_TY_3_TRANSLATED 
            FROM [dbo].nrt_page_case_answer TB WITH (NOLOCK)
            LEFT JOIN [dbo].nrt_investigation inv WITH(NOLOCK) 
                ON TB.act_uid = inv.public_health_case_uid
            LEFT JOIN [dbo].nrt_srte_Codeset_Group_Metadata METADATA WITH (NOLOCK)
                ON METADATA.CODE_SET_GROUP_ID = TB.CODE_SET_GROUP_ID
            LEFT JOIN [dbo].nrt_srte_code_value_general CVG WITH (NOLOCK)
                ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
                AND CVG.CODE = TB.ANSWER_TXT
            INNER JOIN ( SELECT TRIM(value) FROM STRING_SPLIT(@phc_id_list, ',')) nu ON TB.ACT_UID = nu.value
            WHERE TB.DATAMART_COLUMN_NM <> 'n/a'
            AND ISNULL(tb.batch_id, 1) = ISNULL(inv.batch_id, 1)
            AND QUESTION_IDENTIFIER = 'TUB237';

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #S_D_HC_PROV_TY_3_TRANSLATED;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;

---------------------------------------------------------------------------------------------------------------------        


        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #S_D_HC_PROV_TY_3';

            IF OBJECT_ID('#S_D_HC_PROV_TY_3', 'U') IS NOT NULL
                DROP TABLE #S_D_HC_PROV_TY_3;


            SELECT 
                *, 
                CASE 
                    WHEN CODE_SET_GROUP_ID IS NULL OR CODE_SET_GROUP_ID = '' THEN ANSWER_TXT
                    ELSE CODE_SHORT_DESC_TXT
                END AS VALUE
            INTO #S_D_HC_PROV_TY_3
            FROM #S_D_HC_PROV_TY_3_TRANSLATED WITH (NOLOCK);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #S_D_HC_PROV_TY_3;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;
-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #TEMP_D_HC_PROV_TY_3_DEL';

            IF OBJECT_ID('#TEMP_D_HC_PROV_TY_3_DEL', 'U') IS NOT NULL
            drop table #TEMP_D_HC_PROV_TY_3_DEL;

            SELECT 
                D.TB_PAM_UID, 
                D.D_HC_PROV_TY_3_KEY,
                D.D_HC_PROV_TY_3_GROUP_KEY
            INTO #TEMP_D_HC_PROV_TY_3_DEL
            FROM [dbo].D_HC_PROV_TY_3 D WITH (NOLOCK)
            LEFT JOIN [dbo].nrt_d_hc_prov_ty_3_key K WITH (NOLOCK)
                ON D.TB_PAM_UID = K.TB_PAM_UID AND
                D.D_HC_PROV_TY_3_KEY = K.D_HC_PROV_TY_3_KEY
            LEFT JOIN #S_D_HC_PROV_TY_3 S 
            ON S.TB_PAM_UID = K.TB_PAM_UID AND
                S.NBS_CASE_ANSWER_UID = K.NBS_CASE_ANSWER_UID
            WHERE D.TB_PAM_UID IN (SELECT value FROM #D_HC_PROV_TY_3_PHC_LIST) 
            AND S.NBS_CASE_ANSWER_UID IS NULL;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #TEMP_D_HC_PROV_TY_3_DEL;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;   

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_d_hc_prov_ty_3_key';

            DELETE K 
            FROM [dbo].nrt_d_hc_prov_ty_3_key K
            INNER JOIN #TEMP_D_HC_PROV_TY_3_DEL T with (nolock)
                ON T.TB_PAM_UID = K.TB_PAM_UID 
                AND T.D_HC_PROV_TY_3_KEY = K.D_HC_PROV_TY_3_KEY;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #TEMP_D_HC_PROV_TY_3_DEL;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        

-------------------------------------------------------------------------------------------


            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_d_hc_prov_ty_3_group_key';

            DELETE GK 
            FROM [dbo].nrt_d_hc_prov_ty_3_group_key GK
            INNER JOIN #TEMP_D_HC_PROV_TY_3_DEL T 
                ON T.TB_PAM_UID = GK.TB_PAM_UID 
                AND T.D_HC_PROV_TY_3_GROUP_KEY = GK.D_HC_PROV_TY_3_GROUP_KEY;


            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #TEMP_D_HC_PROV_TY_3_DEL;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        

-------------------------------------------------------------------------------------------


            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETING FROM dbo.D_HC_PROV_TY_3';

            DELETE D 
            FROM [dbo].D_HC_PROV_TY_3 D
            INNER join #TEMP_D_HC_PROV_TY_3_DEL T with (nolock)
                ON T.TB_PAM_UID =D.TB_PAM_UID 
                AND T.D_HC_PROV_TY_3_KEY = D.D_HC_PROV_TY_3_KEY;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        

-------------------------------------------------------------------------------------------

 
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETING FROM dbo.D_HC_PROV_TY_3_GROUP';
    
            -- update F_TB_PAM table
            UPDATE F
                SET F.D_HC_PROV_TY_3_GROUP_KEY = 1
            FROM [dbo].F_TB_PAM F
            INNER JOIN #TEMP_D_HC_PROV_TY_3_DEL T on T.D_HC_PROV_TY_3_GROUP_KEY = F.D_HC_PROV_TY_3_GROUP_KEY;

            -- delete from [dbo].D_HC_PROV_TY_3_GROUP    
            DELETE G 
            FROM [dbo].D_HC_PROV_TY_3_GROUP G
            LEFT JOIN (SELECT DISTINCT D_HC_PROV_TY_3_GROUP_KEY FROM [dbo].D_HC_PROV_TY_3) D
                ON D.D_HC_PROV_TY_3_GROUP_KEY = G.D_HC_PROV_TY_3_GROUP_KEY
            WHERE D.D_HC_PROV_TY_3_GROUP_KEY is null;
    
    
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
                @PROC_STEP_NAME = 'INSERT KEYS TO dbo.nrt_d_hc_prov_ty_3_group_key ';

            INSERT INTO [dbo].nrt_d_hc_prov_ty_3_group_key (TB_PAM_UID) 
            SELECT S.TB_PAM_UID FROM (SELECT DISTINCT TB_PAM_UID FROM #S_D_HC_PROV_TY_3) S
            LEFT JOIN [dbo].nrt_d_hc_prov_ty_3_group_key GK  WITH (NOLOCK)
                ON GK.TB_PAM_UID = S.TB_PAM_UID
            WHERE GK.TB_PAM_UID IS NULL;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM [dbo].nrt_d_hc_prov_ty_3_group_key WITH (NOLOCK);

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERT KEYS TO dbo.nrt_d_hc_prov_ty_3_key';

            INSERT INTO [dbo].nrt_d_hc_prov_ty_3_key(TB_PAM_UID, NBS_CASE_ANSWER_UID) 
            SELECT 
                S.TB_PAM_UID, 
                S.NBS_CASE_ANSWER_UID 
            FROM (SELECT DISTINCT TB_PAM_UID, NBS_CASE_ANSWER_UID FROM #S_D_HC_PROV_TY_3) S
            LEFT JOIN [dbo].nrt_d_hc_prov_ty_3_key K WITH (NOLOCK)
                ON K.TB_PAM_UID = S.TB_PAM_UID
                AND K.NBS_CASE_ANSWER_UID = S.NBS_CASE_ANSWER_UID
            WHERE 
                K.TB_PAM_UID IS NULL
                AND K.NBS_CASE_ANSWER_UID IS NULL;
            

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM [dbo].nrt_d_hc_prov_ty_3_key WITH (NOLOCK);

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
                DROP TABLE #D_TB_PAM_TEMP;
            

            SELECT DISTINCT D_TB_PAM.TB_PAM_UID
                INTO #D_TB_PAM_TEMP
                FROM (
                    SELECT DISTINCT TB_PAM_UID 
                    FROM [dbo].D_TB_PAM WITH (NOLOCK)
                    WHERE TB_PAM_UID IN (SELECT VALUE FROM #D_HC_PROV_TY_3_PHC_LIST)
                ) D_TB_PAM
                LEFT JOIN #S_D_HC_PROV_TY_3 S
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
                @PROC_STEP_NAME = 'GENERATING #L_D_HC_PROV_TY_3_GROUP';

            IF OBJECT_ID('#L_D_HC_PROV_TY_3_GROUP', 'U') IS NOT NULL
                DROP TABLE #L_GT_12_REAS_GROUP;

            SELECT 
                D_TB_PAM.TB_PAM_UID,
                GK.D_HC_PROV_TY_3_GROUP_KEY
            INTO #L_D_HC_PROV_TY_3_GROUP
            FROM #D_TB_PAM_TEMP D_TB_PAM
            LEFT OUTER JOIN [dbo].nrt_d_hc_prov_ty_3_group_key GK WITH (NOLOCK)
                ON GK.TB_PAM_UID=D_TB_PAM.TB_PAM_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #L_D_HC_PROV_TY_3_GROUP;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;               

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #L_D_HC_PROV_TY_3';

            IF OBJECT_ID('#L_D_HC_PROV_TY_3', 'U') IS NOT NULL
                DROP TABLE #L_D_HC_PROV_TY_3;

            SELECT 
                L.TB_PAM_UID,  
                K.NBS_CASE_ANSWER_UID, 
                COALESCE(L.D_HC_PROV_TY_3_GROUP_KEY, 1) AS D_HC_PROV_TY_3_GROUP_KEY,
                COALESCE(K.D_HC_PROV_TY_3_KEY, 1) AS D_HC_PROV_TY_3_KEY
            INTO #L_D_HC_PROV_TY_3
            FROM #L_D_HC_PROV_TY_3_GROUP L 
            LEFT OUTER JOIN [dbo].nrt_d_hc_prov_ty_3_key K  WITH (NOLOCK)
                ON K.TB_PAM_UID=L.TB_PAM_UID;

            SELECT @RowCount_no = @@ROWCOUNT;
            
            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #L_D_HC_PROV_TY_3;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;           

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #TEMP_D_HC_PROV_TY_3';

            IF OBJECT_ID('#TEMP_D_HC_PROV_TY_3', 'U') IS NOT NULL
                DROP TABLE #TEMP_D_HC_PROV_TY_3;

            SELECT L.TB_PAM_UID,
                L.D_HC_PROV_TY_3_KEY, 
                S.SEQ_NBR,
                L.D_HC_PROV_TY_3_GROUP_KEY,
                S.LAST_CHG_TIME,
                S.VALUE
            INTO #TEMP_D_HC_PROV_TY_3
            FROM #L_D_HC_PROV_TY_3 L  
            LEFT OUTER JOIN #S_D_HC_PROV_TY_3 S
                ON 	S.TB_PAM_UID=L.TB_PAM_UID
                AND S.NBS_CASE_ANSWER_UID= L.NBS_CASE_ANSWER_UID;

            SELECT @RowCount_no = @@ROWCOUNT;
                
            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #L_D_HC_PROV_TY_3;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;    

-------------------------------------------------------------------------------------------
        
        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERT RECORDS TO D_HC_PROV_TY_3_GROUP';

            INSERT INTO [dbo].d_hc_prov_ty_3_group ([D_HC_PROV_TY_3_GROUP_KEY])
            SELECT DISTINCT
                T.D_HC_PROV_TY_3_GROUP_KEY
            FROM #TEMP_D_HC_PROV_TY_3 T 
            LEFT JOIN [dbo].d_hc_prov_ty_3_group G WITH (NOLOCK)
                ON G.D_HC_PROV_TY_3_GROUP_KEY= T.D_HC_PROV_TY_3_GROUP_KEY
            WHERE G.D_HC_PROV_TY_3_GROUP_KEY IS NULL;

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
                @PROC_STEP_NAME = 'UPDATE D_HC_PROV_TY_3';

            UPDATE [dbo].D_HC_PROV_TY_3
            SET 
                TB_PAM_UID = T.TB_PAM_UID,
                SEQ_NBR = T.SEQ_NBR,
                LAST_CHG_TIME = T.LAST_CHG_TIME,
                VALUE = T.VALUE
            FROM #TEMP_D_HC_PROV_TY_3 T  
            INNER JOIN [dbo].D_HC_PROV_TY_3 D with (nolock)
                ON D.TB_PAM_UID= T.TB_PAM_UID 
                AND D.D_HC_PROV_TY_3_KEY = T.D_HC_PROV_TY_3_KEY
            WHERE D.D_HC_PROV_TY_3_KEY IS NOT NULL;

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
            @PROC_STEP_NAME = 'INSERT RECORDS TO  D_HC_PROV_TY_3';

        INSERT INTO [dbo].D_HC_PROV_TY_3
            ([TB_PAM_UID]
            ,[D_HC_PROV_TY_3_KEY]
            ,[SEQ_NBR]
            ,[D_HC_PROV_TY_3_GROUP_KEY]
            ,[LAST_CHG_TIME]
            ,[VALUE])
            SELECT 
                T.TB_PAM_UID,
                T.D_HC_PROV_TY_3_KEY,
                T.SEQ_NBR,
                T.D_HC_PROV_TY_3_GROUP_KEY,
                T.LAST_CHG_TIME,
                T.VALUE
            FROM #TEMP_D_HC_PROV_TY_3 T  WITH (NOLOCK)
            LEFT JOIN [dbo].D_HC_PROV_TY_3 D WITH (NOLOCK)
            ON 	D.TB_PAM_UID= T.TB_PAM_UID
            AND D.D_HC_PROV_TY_3_KEY = T.D_HC_PROV_TY_3_KEY
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
