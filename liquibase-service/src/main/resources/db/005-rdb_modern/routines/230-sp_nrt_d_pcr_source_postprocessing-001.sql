IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_nrt_d_pcr_source_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_nrt_d_pcr_source_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_nrt_d_pcr_source_postprocessing]  
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
	DECLARE @Dataflow_Name VARCHAR(200) = 'D_PCR_SOURCE POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_nrt_d_pcr_source_postprocessing';

    BEGIN TRY
        

        SET @Proc_Step_Name = 'SP_Start';

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

--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #D_PCR_SOURCE_PHC_LIST TABLE';

        IF OBJECT_ID('#D_PCR_SOURCE_PHC_LIST', 'U') IS NOT NULL
            drop table #D_PCR_SOURCE_PHC_LIST;

        SELECT value
        INTO  #D_PCR_SOURCE_PHC_LIST
        FROM STRING_SPLIT(@phc_id_list, ',')

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #D_PCR_SOURCE_PHC_LIST;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
--------------------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #S_D_PCR_SOURCE_TRANSLATED';

            IF OBJECT_ID('#S_D_PCR_SOURCE_TRANSLATED', 'U') IS NOT NULL
                DROP TABLE #S_D_PCR_SOURCE_TRANSLATED;
            
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
                CVG.CODE_SHORT_DESC_TXT
            INTO #S_D_PCR_SOURCE_TRANSLATED 
            FROM [dbo].nrt_page_case_answer VAR WITH (NOLOCK)
            LEFT JOIN [dbo].nrt_investigation inv WITH(NOLOCK) 
                ON VAR.act_uid = inv.public_health_case_uid
            LEFT JOIN [dbo].nrt_srte_Codeset_Group_Metadata METADATA WITH (NOLOCK)
                ON METADATA.CODE_SET_GROUP_ID = VAR.CODE_SET_GROUP_ID
            LEFT JOIN [dbo].nrt_srte_code_value_general CVG WITH (NOLOCK)
                ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
                AND CVG.CODE = VAR.ANSWER_TXT
            INNER JOIN ( SELECT TRIM(value) AS value FROM STRING_SPLIT(@phc_id_list, ',')) nu ON VAR.ACT_UID = nu.value
            WHERE VAR.DATAMART_COLUMN_NM <> 'n/a'
            AND ISNULL(VAR.batch_id, 1) = ISNULL(inv.batch_id, 1)
            AND QUESTION_IDENTIFIER = 'VAR176';

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #S_D_PCR_SOURCE_TRANSLATED;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
---------------------------------------------------------------------------------------------------------------------        

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #S_D_PCR_SOURCE';

            IF OBJECT_ID('#S_D_PCR_SOURCE', 'U') IS NOT NULL
                DROP TABLE #S_D_PCR_SOURCE;


            SELECT 
                *, 
                CASE 
                    WHEN CODE_SET_GROUP_ID IS NULL OR CODE_SET_GROUP_ID = '' THEN ANSWER_TXT
                    ELSE CODE_SHORT_DESC_TXT
                END AS VALUE
            INTO #S_D_PCR_SOURCE
            FROM #S_D_PCR_SOURCE_TRANSLATED;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #S_D_PCR_SOURCE;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #TEMP_D_PCR_SOURCE_DEL';

            IF OBJECT_ID('#TEMP_D_PCR_SOURCE_DEL', 'U') IS NOT NULL
            drop table #TEMP_D_PCR_SOURCE_DEL;

            SELECT 
                D.VAR_PAM_UID, 
                D.D_PCR_SOURCE_KEY,
                D.D_PCR_SOURCE_GROUP_KEY
            INTO #TEMP_D_PCR_SOURCE_DEL
            FROM [dbo].D_PCR_SOURCE D WITH (NOLOCK)
            LEFT JOIN [dbo].nrt_d_pcr_source_key K WITH (NOLOCK)
                ON D.VAR_PAM_UID = K.VAR_PAM_UID AND
                D.D_PCR_SOURCE_KEY = K.D_PCR_SOURCE_KEY
            LEFT JOIN #S_D_PCR_SOURCE S 
            ON S.VAR_PAM_UID = K.VAR_PAM_UID AND
                S.NBS_CASE_ANSWER_UID = K.NBS_CASE_ANSWER_UID
            WHERE D.VAR_PAM_UID IN (SELECT value FROM #D_PCR_SOURCE_PHC_LIST);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #TEMP_D_PCR_SOURCE_DEL;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_d_pcr_source_key';

            DELETE K 
            FROM [dbo].nrt_d_pcr_source_key K
            INNER JOIN #TEMP_D_PCR_SOURCE_DEL T with (nolock)
                ON T.VAR_PAM_UID = K.VAR_PAM_UID 
                AND T.D_PCR_SOURCE_KEY = K.D_PCR_SOURCE_KEY

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #TEMP_D_PCR_SOURCE_DEL;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        

-------------------------------------------------------------------------------------------


            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETING FROM dbo.nrt_d_pcr_source_group_key';

            DELETE GK 
            FROM [dbo].nrt_d_pcr_source_group_key GK
            INNER JOIN #TEMP_D_PCR_SOURCE_DEL T 
                ON T.VAR_PAM_UID = GK.VAR_PAM_UID 
                AND T.D_PCR_SOURCE_GROUP_KEY = GK.D_PCR_SOURCE_GROUP_KEY


            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #TEMP_D_PCR_SOURCE_DEL;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        

-------------------------------------------------------------------------------------------


            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETING FROM dbo.D_PCR_SOURCE';

            DELETE D 
            FROM [dbo].D_PCR_SOURCE D
            INNER join #TEMP_D_PCR_SOURCE_DEL T with (nolock)
                ON T.VAR_PAM_UID =D.VAR_PAM_UID 
                AND T.D_PCR_SOURCE_KEY = D.D_PCR_SOURCE_KEY

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
                @PROC_STEP_NAME = 'INSERT KEYS TO dbo.nrt_d_pcr_source_group_key ';

            INSERT INTO [dbo].nrt_d_pcr_source_group_key (VAR_PAM_UID) 
            SELECT S.VAR_PAM_UID FROM (SELECT DISTINCT VAR_PAM_UID FROM #S_D_PCR_SOURCE) S
            LEFT JOIN [dbo].nrt_d_pcr_source_group_key GK  WITH (NOLOCK)
                ON GK.VAR_PAM_UID = S.VAR_PAM_UID
            WHERE GK.VAR_PAM_UID IS NULL;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM [dbo].nrt_d_pcr_source_group_key WITH (NOLOCK);

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERT KEYS TO dbo.nrt_d_pcr_source_key';

            INSERT INTO [dbo].nrt_d_pcr_source_key(VAR_PAM_UID, NBS_CASE_ANSWER_UID) 
            SELECT 
                S.VAR_PAM_UID, 
                S.NBS_CASE_ANSWER_UID 
            FROM (SELECT DISTINCT VAR_PAM_UID, NBS_CASE_ANSWER_UID FROM #S_D_PCR_SOURCE) S
            LEFT JOIN [dbo].nrt_d_pcr_source_key K WITH (NOLOCK)
                ON K.VAR_PAM_UID = S.VAR_PAM_UID
                AND K.NBS_CASE_ANSWER_UID = S.NBS_CASE_ANSWER_UID
            WHERE 
                K.VAR_PAM_UID is null 
                AND K.NBS_CASE_ANSWER_UID is null;
            

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM [dbo].nrt_d_pcr_source_key WITH (NOLOCK);

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;

-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #D_VAR_PAM_TEMP';

            IF OBJECT_ID('#D_VAR_PAM_TEMP', 'U') IS NOT NULL
                DROP TABLE #D_VAR_PAM_TEMP;
            

            SELECT DISTINCT D_VAR_PAM.VAR_PAM_UID
                INTO #D_VAR_PAM_TEMP
                FROM (
                    SELECT DISTINCT VAR_PAM_UID 
                    FROM [dbo].D_VAR_PAM WITH (NOLOCK)
                    WHERE VAR_PAM_UID IN (SELECT VALUE FROM #D_PCR_SOURCE_PHC_LIST)
                ) D_VAR_PAM
                LEFT JOIN #S_D_PCR_SOURCE S
                    ON S.VAR_PAM_UID = D_VAR_PAM.VAR_PAM_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_VAR_PAM_TEMP;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #L_D_PCR_SOURCE_GROUP';

            IF OBJECT_ID('#L_D_PCR_SOURCE_GROUP', 'U') IS NOT NULL
                DROP TABLE #L_D_PCR_SOURCE_GROUP;

            SELECT 
                D.VAR_PAM_UID,
                GK.D_PCR_SOURCE_GROUP_KEY
            INTO #L_D_PCR_SOURCE_GROUP
            FROM #D_VAR_PAM_TEMP D
            LEFT OUTER JOIN [dbo].nrt_d_pcr_source_group_key GK WITH (NOLOCK)
                ON GK.VAR_PAM_UID=D.VAR_PAM_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #L_D_PCR_SOURCE_GROUP;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #L_D_PCR_SOURCE';

            IF OBJECT_ID('#L_D_PCR_SOURCE', 'U') IS NOT NULL
                DROP TABLE #L_D_PCR_SOURCE;

            SELECT 
                L.VAR_PAM_UID,  
                K.NBS_CASE_ANSWER_UID, 
                COALESCE(L.D_PCR_SOURCE_GROUP_KEY, 1) AS D_PCR_SOURCE_GROUP_KEY,
                COALESCE(K.D_PCR_SOURCE_KEY, 1) AS D_PCR_SOURCE_KEY
            INTO #L_D_PCR_SOURCE
            FROM #L_D_PCR_SOURCE_GROUP L 
            LEFT OUTER JOIN [dbo].nrt_d_pcr_source_key K  WITH (NOLOCK)
                ON K.VAR_PAM_UID=L.VAR_PAM_UID;

            SELECT @RowCount_no = @@ROWCOUNT;
            
            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #L_D_PCR_SOURCE;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #TEMP_D_PCR_SOURCE';

            IF OBJECT_ID('#TEMP_D_PCR_SOURCE', 'U') IS NOT NULL
                DROP TABLE #TEMP_D_PCR_SOURCE;

            SELECT L.VAR_PAM_UID,
                L.D_PCR_SOURCE_KEY, 
                S.SEQ_NBR,
                L.D_PCR_SOURCE_GROUP_KEY,
                S.LAST_CHG_TIME,
                S.VALUE
            INTO #TEMP_D_PCR_SOURCE
            FROM #L_D_PCR_SOURCE L  
            LEFT OUTER JOIN #S_D_PCR_SOURCE S
                ON 	S.VAR_PAM_UID=L.VAR_PAM_UID
                AND S.NBS_CASE_ANSWER_UID= L.NBS_CASE_ANSWER_UID;

            SELECT @RowCount_no = @@ROWCOUNT;
                
            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #L_D_PCR_SOURCE;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------
        
        BEGIN TRANSACTION

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'INSERT RECORDS TO D_PCR_SOURCE_GROUP';

            INSERT INTO [dbo].d_pcr_source_group ([D_PCR_SOURCE_GROUP_KEY])
            SELECT DISTINCT
                T.D_PCR_SOURCE_GROUP_KEY
            FROM #TEMP_D_PCR_SOURCE T 
            LEFT JOIN [dbo].d_pcr_source_group G WITH (NOLOCK)
                ON G.D_PCR_SOURCE_GROUP_KEY= T.D_PCR_SOURCE_GROUP_KEY
            WHERE G.D_PCR_SOURCE_GROUP_KEY IS NULL;

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
                @PROC_STEP_NAME = 'UPDATE D_PCR_SOURCE';

            UPDATE [dbo].D_PCR_SOURCE
            SET 
                VAR_PAM_UID = T.VAR_PAM_UID,
                SEQ_NBR = T.SEQ_NBR,
                LAST_CHG_TIME = T.LAST_CHG_TIME,
                VALUE = T.VALUE
            FROM #TEMP_D_PCR_SOURCE T  
            INNER JOIN [dbo].D_PCR_SOURCE D with (nolock)
                ON D.VAR_PAM_UID= T.VAR_PAM_UID 
                AND D.D_PCR_SOURCE_KEY = T.D_PCR_SOURCE_KEY
            WHERE D.D_PCR_SOURCE_KEY IS NOT NULL;

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
            @PROC_STEP_NAME = 'INSERT RECORDS TO D_PCR_SOURCE';

        INSERT INTO [dbo].D_PCR_SOURCE
            ([VAR_PAM_UID]
            ,[D_PCR_SOURCE_KEY]
            ,[SEQ_NBR]
            ,[D_PCR_SOURCE_GROUP_KEY]
            ,[LAST_CHG_TIME]
            ,[VALUE])
            SELECT 
                T.VAR_PAM_UID,
                T.D_PCR_SOURCE_KEY,
                T.SEQ_NBR,
                T.D_PCR_SOURCE_GROUP_KEY,
                T.LAST_CHG_TIME,
                T.VALUE
            FROM #TEMP_D_PCR_SOURCE T  
            LEFT JOIN [dbo].D_PCR_SOURCE D WITH (NOLOCK)
            ON 	D.VAR_PAM_UID= T.VAR_PAM_UID
            AND D.D_PCR_SOURCE_KEY = T.D_PCR_SOURCE_KEY
            WHERE D.VAR_PAM_UID IS NULL;

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;          

--------------------------------------------------------------------------------------------
        BEGIN TRANSACTION


        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'DELETING FROM DBO.D_PCR_SOURCE_GROUP';

        -- update F_VAR_PAM table
        UPDATE F
            SET F.D_PCR_SOURCE_GROUP_KEY = D.D_PCR_SOURCE_GROUP_KEY
        FROM DBO.F_VAR_PAM F with (nolock)
        INNER JOIN DBO.D_VAR_PAM DIM  with (nolock)
            ON DIM.D_VAR_PAM_KEY = F.D_VAR_PAM_KEY
        INNER JOIN DBO.D_PCR_SOURCE D with (nolock)
            ON D.VAR_PAM_UID = DIM.VAR_PAM_UID
        INNER JOIN #D_PCR_SOURCE_PHC_LIST S
            ON D.VAR_PAM_UID = S.VALUE;

        -- delete from DBO.D_PCR_SOURCE_GROUP
        DELETE T FROM DBO.D_PCR_SOURCE_GROUP T with (nolock)
        INNER JOIN #TEMP_D_PCR_SOURCE_DEL DEL
            on T.D_PCR_SOURCE_GROUP_KEY = DEL.D_PCR_SOURCE_GROUP_KEY
        left join (select distinct D_PCR_SOURCE_GROUP_KEY from dbo.d_pcr_source with (nolock)) D
            ON D.D_PCR_SOURCE_GROUP_KEY = T.D_PCR_SOURCE_GROUP_KEY
        WHERE D.D_PCR_SOURCE_GROUP_KEY is null;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;  
-------------------------------------------------------------------------------------------

        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);
    
        SELECT
            CAST(NULL AS BIGINT) AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            CAST(NULL AS VARCHAR(30)) AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            CAST(NULL AS VARCHAR(200)) AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=0;

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

END;


---------------------------------------------------END OF PROCEDURE---------------------------------------------------------------------
