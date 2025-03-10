CREATE OR ALTER PROCEDURE [dbo].[sp_nrt_d_tb_hiv_postprocessing]
    @phc_id_list nvarchar(max),
    @debug bit = 'false'
AS

BEGIN
	/*
	* [Description]
	* This procedure compute the Dimension D_TB_HIV based on the received investigation_case_answers
	* 1- Extracting TB-HIV Data 
	* 2- Join with Metadata
	* 3- Translate Codes
	* 4- Transform Data
	* 5- Pivot for S_TB_HIV
	* 6- Add columns and update
	* 7- Assign D_TB_HIV_KEY
	* 8- Apply additional logic
	* 9- Insert into L_TB_HIV 
	* 10- MERGE into D_TB_HIV
	*/

	DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyyyMMddHHmmss')) AS BIGINT);
    PRINT @batch_id;
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT= 0;
    DECLARE @Proc_Step_Name VARCHAR(200)= '';
    DECLARE @datamart_nm VARCHAR(100) = 'D_TB_HIV';

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
               , @datamart_nm
               , @datamart_nm
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
		
		SELECT 
			CODE_SET_GROUP_ID, 
			DATAMART_COLUMN_NM, 
			ANSWER_TXT, 
			ACT_UID AS TB_PAM_UID, 
			LAST_CHG_TIME
		INTO #S_TB_HIV_SET
		FROM [dbo].nrt_page_case_answer WITH (NOLOCK) 
		WHERE 
		    ACT_UID IN (SELECT value FROM STRING_SPLIT(@phc_id_list, ','))
			AND investigation_form_cd = @inv_form_cd
			AND datamart_column_nm IS NOT NULL
			AND datamart_column_nm <> 'N/A'
			AND question_identifier IN ('TUB154', 'TUB155', 'TUB156')
		GROUP BY ACT_UID, DATAMART_COLUMN_NM, CODE_SET_GROUP_ID, ANSWER_TXT, LAST_CHG_TIME;

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #S_TB_HIV_SET;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


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
		LEFT JOIN [dbo].nrt_srte_codeset_group_metadata METADATA
			ON METADATA.CODE_SET_GROUP_ID = TB.CODE_SET_GROUP_ID;

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #S_TB_HIV_CODED;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

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
			CVG.CODE_SHORT_DESC_TXT AS CODE_SHORT_DESC_TXT, 
			TB.LAST_CHG_TIME
		INTO #S_TB_PAM_HIV_TRANSLATED
		FROM #S_TB_HIV_CODED TB
		LEFT JOIN NBS_SRTe.dbo.CODE_VALUE_GENERAL CVG
			ON CVG.CODE_SET_NM = TB.CODE_SET_NM
			AND CVG.CODE = TB.ANSWER_TXT
		ORDER BY TB.TB_PAM_UID;

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #S_TB_PAM_HIV_TRANSLATED;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

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
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

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
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

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
		FROM [dbo].D_TB_HIV; 

		-- delete from key table and insert new elements to get all new D_TB_HIV_KEY for new elements
		DELETE FROM [dbo].[nrt_d_tb_hiv_key]; 
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
            FROM #L_TB_HIV_BASE_NEW;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

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
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

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
			S.TB_PAM_UID, 
			L.D_TB_HIV_KEY,     
			S.LAST_CHG_TIME, 
			S.HIV_STATE_PATIENT_NUM, 
			S.HIV_STATUS, 
			S.HIV_CITY_CNTY_PATIENT_NUM
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
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' INSERT NEW DIMENSION ENTRIES IN TABLE D_TB_HIV ';

		-- D_TB_HIV_N
		INSERT INTO [dbo].D_TB_HIV (
			TB_PAM_UID, 
			D_TB_HIV_KEY, 
			LAST_CHG_TIME,
			HIV_STATE_PATIENT_NUM, 
			HIV_STATUS, 
			HIV_CITY_CNTY_PATIENT_NUM
		)
		SELECT 
			TB_PAM_UID, 
			D_TB_HIV_KEY,     
			LAST_CHG_TIME, 
			HIV_STATE_PATIENT_NUM, 
			HIV_STATUS, 
			HIV_CITY_CNTY_PATIENT_NUM
		FROM #D_TB_HIV_N;
		

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM  [dbo].D_TB_HIV WHERE TB_PAM_UID IN (SELECT value FROM STRING_SPLIT(@phc_id_list, ','));

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

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
			S.TB_PAM_UID, 
			S.LAST_CHG_TIME, 
			S.HIV_STATE_PATIENT_NUM, 
			S.HIV_STATUS, 
			S.HIV_CITY_CNTY_PATIENT_NUM
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
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;


	BEGIN TRANSACTION

		SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' UPDATE EXISTING DIMENSION ENTRIES IN TABLE D_TB_HIV';

		-- 10. UPADTE into D_TB_HIV
			UPDATE [dbo].D_TB_HIV
			SET 
				HIV_STATE_PATIENT_NUM = S.HIV_STATE_PATIENT_NUM,
				HIV_STATUS = S.HIV_STATUS,
				HIV_CITY_CNTY_PATIENT_NUM = S.HIV_CITY_CNTY_PATIENT_NUM,
				LAST_CHG_TIME = S.LAST_CHG_TIME
			FROM  [dbo].D_TB_HIV D 
			INNER JOIN #L_TB_HIV_E L on L.D_TB_HIV_KEY = D.D_TB_HIV_KEY
			INNER JOIN #S_TB_HIV S ON S.TB_PAM_UID = L.TB_PAM_UID;

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM RDB_MODERN.DBO.D_TB_HIV  D
			INNER JOIN #D_TB_HIV_E DE 
				ON DE.TB_PAM_UID = D.TB_PAM_UID; 
			

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

	COMMIT TRANSACTION;

END TRY

BEGIN CATCH

	IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

	DECLARE @ErrorNumber INT = ERROR_NUMBER();
	DECLARE @ErrorLine INT = ERROR_LINE();
	DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
	DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
	DECLARE @ErrorState INT = ERROR_STATE();


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
		,@datamart_nm
		,@datamart_nm
		,'ERROR'
		,@Proc_Step_no
		,'ERROR - '+ @Proc_Step_name
		, 'Step -' +CAST(@Proc_Step_no AS VARCHAR(3))+' -' +CAST(@ErrorMessage AS VARCHAR(500))
		,0
	);

	return -1 ;

END CATCH

END;

