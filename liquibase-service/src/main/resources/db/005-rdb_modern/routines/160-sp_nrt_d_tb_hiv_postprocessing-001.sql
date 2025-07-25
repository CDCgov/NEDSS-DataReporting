IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_nrt_d_tb_hiv_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_nrt_d_tb_hiv_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_nrt_d_tb_hiv_postprocessing]
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
	DECLARE @Dataflow_Name VARCHAR(200) = 'D_TB_HIV POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_nrt_d_tb_hiv_postprocessing';


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
		@PROC_STEP_NAME = 'GENERATING #TB_PAM_UID_LIST';
	
	IF OBJECT_ID('#TB_PAM_UID_LIST') IS NOT NULL
		DROP TABLE #TB_PAM_UID_LIST;

	SELECT DISTINCT
		public_health_case_uid,
		batch_id
	INTO #TB_PAM_UID_LIST	
	FROM [dbo].nrt_investigation I WITH (NOLOCK) 
	INNER JOIN  (SELECT TRIM(value) AS value FROM STRING_SPLIT(@phc_id_list, ',')) nu on nu.value = I.public_health_case_uid  
	WHERE I.investigation_form_cd='INV_FORM_RVCT'

	SELECT @RowCount_no = @@ROWCOUNT;

	IF
		@debug = 'true'
		SELECT @Proc_Step_Name AS step, *
		FROM #TB_PAM_UID_LIST;

	INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
	VALUES 
		(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


	--------------------------------------------------------------------------------------------------------


	SET
		@PROC_STEP_NO = @PROC_STEP_NO + 1;
	SET
		@PROC_STEP_NAME = 'EXTRACTING TB-HIV DATA';
	
	-- #S_TB_HIV_SET
	IF OBJECT_ID('#S_TB_HIV_SET') IS NOT NULL
		DROP TABLE #S_TB_HIV_SET;
	
	SELECT 
		CAST(A.ACT_UID AS BIGINT) AS TB_PAM_UID,
		A.CODE_SET_GROUP_ID, 
		A.DATAMART_COLUMN_NM, 
		A.ANSWER_TXT,			
		A.LAST_CHG_TIME
	INTO #S_TB_HIV_SET	
	FROM [dbo].nrt_page_case_answer A WITH (NOLOCK) 
	INNER JOIN #TB_PAM_UID_LIST I 
	ON I.public_health_case_uid = A.ACT_UID AND ISNULL(I.batch_id, 1) = ISNULL(A.batch_id, 1)
	WHERE 
		A.datamart_column_nm IS NOT NULL
		AND A.datamart_column_nm <> 'N/A'
		AND A.question_identifier IN ('TUB154', 'TUB155', 'TUB156')

	SELECT @RowCount_no = @@ROWCOUNT;

	IF
		@debug = 'true'
		SELECT @Proc_Step_Name AS step, *
		FROM #S_TB_HIV_SET;

	INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
	VALUES 
		(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


	--------------------------------------------------------------------------------------------------------

	SET
		@PROC_STEP_NO = @PROC_STEP_NO + 1;
	SET
		@PROC_STEP_NAME = 'GENRATING DELETED TB-HIV';
	
	IF OBJECT_ID('#TB_HIV_DEL') IS NOT NULL
		DROP TABLE #TB_HIV_DEL;

	SELECT public_health_case_uid
	INTO #TB_HIV_DEL	
	FROM #TB_PAM_UID_LIST S
	INNER JOIN [dbo].D_TB_HIV D WITH (NOLOCK)
		ON D.TB_PAM_UID = S.public_health_case_uid
	EXCEPT
	SELECT TB_PAM_UID
	FROM #S_TB_HIV_SET

	SELECT @RowCount_no = @@ROWCOUNT;

	IF
		@debug = 'true'
		SELECT @Proc_Step_Name AS step, *
		FROM #TB_HIV_DEL;

	INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
	VALUES 
		(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	--------------------------------------------------------------------------------------------------------

	BEGIN TRANSACTION
	
		SET
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET
			@PROC_STEP_NAME = 'DELETE FROM D_TB_HIV';

		DELETE D
		FROM [dbo].D_TB_HIV D 
		INNER JOIN #TB_HIV_DEL R
			ON R.public_health_case_uid = D.TB_PAM_UID
		
		SELECT @RowCount_no = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #TB_HIV_DEL;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


	COMMIT TRANSACTION;

	--------------------------------------------------------------------------------------------------------

	BEGIN TRANSACTION
	
		SET
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET
			@PROC_STEP_NAME = 'DELETE FROM nrt_d_tb_hiv_key';

		DELETE D
		FROM [dbo].[nrt_d_tb_hiv_key] D 
		INNER JOIN #TB_HIV_DEL R
			ON R.public_health_case_uid = D.TB_PAM_UID
		
		SELECT @RowCount_no = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #TB_HIV_DEL;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


	COMMIT TRANSACTION;

	--------------------------------------------------------------------------------------------------------


	SET
		@PROC_STEP_NO = @PROC_STEP_NO + 1;
	SET
		@PROC_STEP_NAME = 'JOIN WITH METADATA';

	-- #S_TB_HIV_CODED
	IF OBJECT_ID('#S_TB_HIV_CODED') IS NOT NULL
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
	VALUES 
		(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


	--------------------------------------------------------------------------------------------------------


	SET
		@PROC_STEP_NO = @PROC_STEP_NO + 1;
	SET
		@PROC_STEP_NAME = 'TRANSFORM DATA';

	IF OBJECT_ID('#S_TB_PAM_HIV_TRANSLATED') IS NOT NULL
		DROP TABLE #S_TB_PAM_HIV_TRANSLATED;

	SELECT 
		TB.CODE_SET_GROUP_ID, 
		TB.TB_PAM_UID, 
		CASE 
			WHEN TB.CODE_SET_GROUP_ID IS NULL OR TB.CODE_SET_GROUP_ID = '' 
			THEN TB.ANSWER_TXT 
			ELSE CVG.CODE_SHORT_DESC_TXT 
		END AS ANSWER_TXT,
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
	VALUES 
		(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


	--------------------------------------------------------------------------------------------------------


	SET
		@PROC_STEP_NO = @PROC_STEP_NO + 1;
	SET
		@PROC_STEP_NAME = 'PIVOT TO CREATE STAGING S_TB_HIV';
	
	IF OBJECT_ID('#S_TB_HIV') IS NOT NULL
	Drop Table #S_TB_HIV;

	SELECT 
		TB_PAM_UID, 
		MAX(HIV_STATE_PATIENT_NUM) AS HIV_STATE_PATIENT_NUM, 
		MAX(HIV_STATUS) AS HIV_STATUS, 
		MAX(HIV_CITY_CNTY_PATIENT_NUM) AS HIV_CITY_CNTY_PATIENT_NUM,
		MAX(LAST_CHG_TIME) AS LAST_CHG_TIME
	INTO #S_TB_HIV
	FROM #S_TB_PAM_HIV_TRANSLATED
	PIVOT (
		MAX(ANSWER_TXT)
		FOR DATAMART_COLUMN_NM IN ([HIV_STATE_PATIENT_NUM], [HIV_STATUS], [HIV_CITY_CNTY_PATIENT_NUM])
	) AS PivotTable
	GROUP BY TB_PAM_UID;

	SELECT @RowCount_no = @@ROWCOUNT;

	IF
		@debug = 'true'
		SELECT @Proc_Step_Name AS step, *
		FROM #S_TB_HIV;

	INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
	VALUES 
		(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


	--------------------------------------------------------------------------------------------------------


	SET
		@PROC_STEP_NO = @PROC_STEP_NO + 1;
	SET
		@PROC_STEP_NAME = 'GENERATE NEW KEYS';

	--insert new items to generate key D_TB_HIV_KEY
	INSERT INTO [dbo].[nrt_d_tb_hiv_key] (TB_PAM_UID)
	SELECT TB_PAM_UID		
	FROM #S_TB_HIV
	EXCEPT 
	SELECT TB_PAM_UID 
	FROM [dbo].D_TB_HIV WITH (NOLOCK); 

	SELECT @RowCount_no = @@ROWCOUNT;

	IF
		@debug = 'true'
		SELECT @Proc_Step_Name AS step, *
		FROM [dbo].[nrt_d_tb_hiv_key] L WITH (NOLOCK) 
		INNER JOIN #S_TB_HIV S ON S.TB_PAM_UID = L.TB_PAM_UID;

	INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
	VALUES 
		(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


	--------------------------------------------------------------------------------------------------------


	SET
		@PROC_STEP_NO = @PROC_STEP_NO + 1;
	SET
		@PROC_STEP_NAME = 'GET NEW DIMENSION ENTRIES D_TB_HIV_N';

	-- D_TB_HIV_N (for INSERT)
	IF OBJECT_ID('#D_TB_HIV_N') IS NOT NULL
		DROP TABLE #D_TB_HIV_N;

	SELECT 
		L.D_TB_HIV_KEY,
		S.*
	INTO #D_TB_HIV_N
	FROM #S_TB_HIV S
	INNER JOIN [dbo].[nrt_d_tb_hiv_key] L WITH (NOLOCK)
		ON S.TB_PAM_UID = L.TB_PAM_UID
	LEFT JOIN [dbo].D_TB_HIV D WITH (NOLOCK)
		ON S.TB_PAM_UID = D.TB_PAM_UID
	WHERE D.TB_PAM_UID IS NULL

	SELECT @RowCount_no = @@ROWCOUNT;

	IF
		@debug = 'true'
		SELECT @Proc_Step_Name AS step, *
		FROM #D_TB_HIV_N

	INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
	VALUES 
		(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


	--------------------------------------------------------------------------------------------------------


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'INSERT NEW DIMENSION ENTRIES IN TABLE D_TB_HIV ';

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
        VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;

	--------------------------------------------------------------------------------------------------------


	SET
		@PROC_STEP_NO = @PROC_STEP_NO + 1;
	SET
		@PROC_STEP_NAME = 'GET EXISTING DIMENSION ENTRIES D_TB_HIV_E';

	-- D_TB_HIV_E (for UPDATE)
	IF OBJECT_ID('#D_TB_HIV_E') IS NOT NULL
		DROP TABLE #D_TB_HIV_E;

	SELECT 
		D.D_TB_HIV_KEY, 
		S.*
	INTO #D_TB_HIV_E
	FROM #S_TB_HIV S	
	INNER JOIN [dbo].D_TB_HIV D WITH (NOLOCK)
		ON S.TB_PAM_UID = D.TB_PAM_UID

	SELECT @RowCount_no = @@ROWCOUNT;

	IF
		@debug = 'true'
		SELECT @Proc_Step_Name AS step, *
		FROM #D_TB_HIV_E;

	INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
	VALUES 
		(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


	--------------------------------------------------------------------------------------------------------


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'UPDATE EXISTING DIMENSION ENTRIES IN TABLE D_TB_HIV';

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
        VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;

	--------------------------------------------------------------------------------------------------------

	SET @Proc_Step_no = 999;
	SET @Proc_Step_Name = 'SP_COMPLETE';
	SELECT @ROWCOUNT_NO = 0;

	INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
	VALUES 
		(@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);

		SELECT
            CAST(NULL AS BIGINT) AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            CAST(NULL AS VARCHAR(30)) AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            CAST(NULL AS VARCHAR(200)) AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=0;

	--------------------------------------------------------------------------------------------------------	

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