CREATE OR ALTER PROCEDURE [dbo].[sp_nrt_d_tb_hiv_postprocessing]
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
	DECLARE @Dataflow_Name VARCHAR(200) = 'D_TB_HIV Post-Processing Event';
	DECLARE @Package_Name VARCHAR(200) = 'sp_nrt_d_tb_hiv_postprocessing';

    DECLARE @inv_form_cd VARCHAR(100) = 'INV_FORM_RVCT';


BEGIN TRY

	SET @Proc_Step_Name = 'SP_Start';


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
               , @Dataflow_Name
               , @Package_Name
               , 'START'
               , @Proc_Step_no
               , @Proc_Step_Name
               , 0
               , LEFT('ID List-' + @phc_id_list, 500));

    COMMIT TRANSACTION;


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' EXTRACTING TB-HIV DATA';
		
		-- #S_TB_HIV_SET
		IF OBJECT_ID('tempdb..#S_TB_HIV_SET') IS NOT NULL
			DROP TABLE #S_TB_HIV_SET;
		
		WITH 
		CTE_INVESTIGATION_BATCH_ID AS (
			SELECT 
				public_health_case_uid,
				batch_id
			FROM [dbo].nrt_investigation I WITH (NOLOCK) 
			INNER JOIN  (SELECT value FROM STRING_SPLIT(@phc_id_list, ',')) nu on nu.value = I.public_health_case_uid  
		),
		CTE_S_TB_HIV_SET AS (
		SELECT 
			CAST(A.ACT_UID AS BIGINT) AS TB_PAM_UID,
			A.CODE_SET_GROUP_ID, 
			A.DATAMART_COLUMN_NM, 
			A.ANSWER_TXT,			
			A.LAST_CHG_TIME, 
			ROW_NUMBER() OVER (PARTITION BY A.ACT_UID, A.CODE_SET_GROUP_ID, A.DATAMART_COLUMN_NM  ORDER BY A.LAST_CHG_TIME DESC) AS rn
		FROM [dbo].nrt_page_case_answer A WITH (NOLOCK) 
		INNER JOIN CTE_INVESTIGATION_BATCH_ID I 
		ON I.public_health_case_uid = A.ACT_UID AND ISNULL(I.batch_id, 1) = ISNULL(A.batch_id, 1)
		WHERE 
			investigation_form_cd = @inv_form_cd
			AND datamart_column_nm IS NOT NULL
			AND datamart_column_nm <> 'N/A'
			AND question_identifier IN ('TUB154', 'TUB155', 'TUB156')
		)
		SELECT 
			TB_PAM_UID,
			CODE_SET_GROUP_ID, 
			DATAMART_COLUMN_NM, 
			ANSWER_TXT,			
			LAST_CHG_TIME
		INTO #S_TB_HIV_SET
		FROM CTE_S_TB_HIV_SET
		WHERE rn = 1;

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #S_TB_HIV_SET;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


	COMMIT TRANSACTION;


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' JOIN WITH METADATA';

		-- #S_TB_HIV_CODED
		IF OBJECT_ID('tempdb..#S_TB_HIV_CODED') IS NOT NULL
		DROP TABLE #S_TB_HIV_CODED;

		SELECT 
			TB.*,
			METADATA.code_set_desc_txt,
			METADATA.code_set_nm,
			METADATA.code_set_short_desc_txt,
			METADATA.ldf_picklist_ind_cd,
			METADATA.phin_std_val_ind,
			METADATA.vads_value_set_code
		INTO #S_TB_HIV_CODED
		FROM #S_TB_HIV_SET TB
		LEFT JOIN [dbo].nrt_srte_codeset_group_metadata METADATA WITH (NOLOCK)
			ON METADATA.CODE_SET_GROUP_ID = TB.CODE_SET_GROUP_ID;

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #S_TB_HIV_CODED;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' TRANSLATE AND ADD CODES';

		IF OBJECT_ID('tempdb..#S_TB_PAM_HIV_TRANSLATED') IS NOT NULL
		DROP TABLE #S_TB_PAM_HIV_TRANSLATED;

		SELECT 
			TB.CODE_SET_GROUP_ID, 
			TB.TB_PAM_UID, 
			TB.ANSWER_TXT, 
			TB.CODE_SET_NM, 
			TB.DATAMART_COLUMN_NM, 
			CVG.CODE, 
			CVG.CODE_SHORT_DESC_TXT, 
			TB.LAST_CHG_TIME
		INTO #S_TB_PAM_HIV_TRANSLATED
		FROM #S_TB_HIV_CODED TB
		LEFT JOIN [dbo].nrt_srte_code_value_general CVG WITH (NOLOCK)
			ON CVG.CODE_SET_NM = TB.CODE_SET_NM
			AND CVG.CODE = TB.ANSWER_TXT;
		
		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #S_TB_PAM_HIV_TRANSLATED;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;		


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' TRANSFORM DATA';

		IF OBJECT_ID('tempdb..#S_TB_PAM_HIV_TIME') IS NOT NULL
		Drop Table #S_TB_PAM_HIV_TIME;

		SELECT DISTINCT TB_PAM_UID, LAST_CHG_TIME
		INTO #S_TB_PAM_HIV_TIME
		FROM #S_TB_PAM_HIV_TRANSLATED;

		IF OBJECT_ID('tempdb..#S_TB_PAM_HIV_CVG') IS NOT NULL
			Drop Table #S_TB_PAM_HIV_CVG;

		SELECT 
			CODE_SET_GROUP_ID, 
			TB_PAM_UID, 
			CASE 
				WHEN CODE_SET_GROUP_ID = '' THEN ANSWER_TXT
				WHEN CODE_SET_GROUP_ID <> '' THEN CODE_SHORT_DESC_TXT
			END AS ANSWER_TXT,
			CODE_SET_NM, 
			DATAMART_COLUMN_NM, 
			CODE, 
			CODE_SHORT_DESC_TXT, 
			LAST_CHG_TIME
		INTO #S_TB_PAM_HIV_CVG
		FROM #S_TB_PAM_HIV_TRANSLATED;

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #S_TB_PAM_HIV_CVG;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;	


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' PIVOT TO CREATE STAGING S_TB_HIV';

		
		IF OBJECT_ID('tempdb..#S_TB_HIV') IS NOT NULL
		Drop Table #S_TB_HIV;

		SELECT 
			T.TB_PAM_UID, 
			[HIV_STATE_PATIENT_NUM], 
			[HIV_STATUS], 
			[HIV_CITY_CNTY_PATIENT_NUM],
			MAX(T.LAST_CHG_TIME) AS LAST_CHG_TIME
		INTO #S_TB_HIV
		FROM #S_TB_PAM_HIV_CVG
		PIVOT (
			MAX(ANSWER_TXT)
			FOR DATAMART_COLUMN_NM IN ([HIV_STATE_PATIENT_NUM], [HIV_STATUS], [HIV_CITY_CNTY_PATIENT_NUM])
		) AS PivotTable
		INNER JOIN #S_TB_PAM_HIV_TIME T
			ON PivotTable.TB_PAM_UID = T.TB_PAM_UID
		WHERE T.TB_PAM_UID IS NOT NULL
		GROUP BY T.TB_PAM_UID, [HIV_STATE_PATIENT_NUM], [HIV_STATUS], [HIV_CITY_CNTY_PATIENT_NUM];

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #S_TB_HIV;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;	


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GET NEW ANSWER ENTRIES L_TB_HIV_N';

		IF OBJECT_ID('tempdb..#L_TB_HIV_BASE_NEW') IS NOT NULL
		DROP Table #L_TB_HIV_BASE_NEW;

		-- L_TB_HIV_BASE_NEW
		SELECT 
			TB_PAM_UID
		INTO #L_TB_HIV_BASE_NEW
		FROM #S_TB_HIV
		EXCEPT 
		SELECT TB_PAM_UID 
		FROM [dbo].D_TB_HIV WITH (NOLOCK); 

		--insert new items to generate key D_TB_HIV_KEY
		INSERT INTO [dbo].[nrt_d_tb_hiv_key] (TB_PAM_UID)
		SELECT TB_PAM_UID		
		FROM #L_TB_HIV_BASE_NEW;

		ALTER TABLE #L_TB_HIV_BASE_NEW 
		ADD D_TB_HIV_KEY INT;

		UPDATE #L_TB_HIV_BASE_NEW 
		SET D_TB_HIV_KEY = K.D_TB_HIV_key
		FROM #L_TB_HIV_BASE_NEW N
		INNER JOIN [dbo].[nrt_d_tb_hiv_key] K
		ON K.TB_PAM_UID = N.TB_PAM_UID;

		IF OBJECT_ID('tempdb..#L_TB_HIV_N') IS NOT NULL
		DROP TABLE #L_TB_HIV_N;

		SELECT
			TB_PAM_UID,
			D_TB_HIV_KEY
		INTO #L_TB_HIV_N
		FROM #L_TB_HIV_BASE_NEW;


		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #L_TB_HIV_N;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;	

	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GET EXISTING ANSWER ENTRIES L_TB_HIV_E';

		-- L_TB_HIV_E
		IF OBJECT_ID('tempdb..#L_TB_HIV_E') IS NOT NULL
			DROP TABLE #L_TB_HIV_E

		SELECT 
			S.TB_PAM_UID, 
			D.D_TB_HIV_KEY
		INTO #L_TB_HIV_E
		FROM #S_TB_HIV S
		INNER JOIN  [dbo].D_TB_HIV D 
			ON S.TB_PAM_UID = D.TB_PAM_UID;

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #L_TB_HIV_E;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GET NEW DIMENSION ENTRIES D_TB_HIV_N';

		-- D_TB_HIV_N (for INSERT)
		IF OBJECT_ID('tempdb..#D_TB_HIV_N') IS NOT NULL
			DROP TABLE #D_TB_HIV_N;

		SELECT 
			L.D_TB_HIV_KEY,
			S.*
		INTO #D_TB_HIV_N
		FROM #S_TB_HIV S
		INNER JOIN #L_TB_HIV_N L
			ON S.TB_PAM_UID = L.TB_PAM_UID;

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #D_TB_HIV_N

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' INSERT NEW DIMENSION ENTRIES IN TABLE D_TB_HIV ';

		-- D_TB_HIV_N
		INSERT INTO [dbo].D_TB_HIV (
			D_TB_HIV_KEY, 
			TB_PAM_UID,
			HIV_STATE_PATIENT_NUM, 
			HIV_STATUS, 
			HIV_CITY_CNTY_PATIENT_NUM,
			LAST_CHG_TIME
		)
		SELECT 
			D_TB_HIV_KEY, 
			TB_PAM_UID, 			    
			HIV_STATE_PATIENT_NUM, 
			HIV_STATUS, 
			HIV_CITY_CNTY_PATIENT_NUM,
			LAST_CHG_TIME
		FROM #D_TB_HIV_N;
		

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #D_TB_HIV_N;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GET EXISTING DIMENSION ENTRIES D_TB_HIV_E';

		-- D_TB_HIV_E (for UPDATE)
		IF OBJECT_ID('tempdb..#D_TB_HIV_E') IS NOT NULL
			DROP TABLE #D_TB_HIV_E;

		SELECT 
			E.D_TB_HIV_KEY, 
			S.*
		INTO #D_TB_HIV_E
		FROM #S_TB_HIV S
		INNER JOIN #L_TB_HIV_E E
			ON S.TB_PAM_UID = E.TB_PAM_UID;

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #D_TB_HIV_E;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' UPDATE EXISTING DIMENSION ENTRIES IN TABLE D_TB_HIV';

		-- 10. UPADTE into D_TB_HIV
			UPDATE D
			SET 
				D.HIV_STATE_PATIENT_NUM = S.HIV_STATE_PATIENT_NUM,
				D.HIV_STATUS = S.HIV_STATUS,
				D.HIV_CITY_CNTY_PATIENT_NUM = S.HIV_CITY_CNTY_PATIENT_NUM,
				D.LAST_CHG_TIME = S.LAST_CHG_TIME
			FROM  [dbo].D_TB_HIV D 
			INNER JOIN #D_TB_HIV_E S ON D.D_TB_HIV_KEY = S.D_TB_HIV_KEY AND D.TB_PAM_UID = S.TB_PAM_UID;

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM  #D_TB_HIV_E; 
			

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;

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

