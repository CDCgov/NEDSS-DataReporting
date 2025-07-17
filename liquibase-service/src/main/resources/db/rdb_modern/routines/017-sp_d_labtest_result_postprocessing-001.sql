IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_d_labtest_result_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_d_labtest_result_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_d_labtest_result_postprocessing](
	@pLabResultList nvarchar(max), 
	@pDebug bit = 'false'
)
AS

BEGIN
    /*
     * [Description]
     * This stored procedure processes event based updates to LAB_TEST and associated tables.
     * 1. Receives input list of Lab Report based observations from Observation Service.
     * 2. Gets list of records from LAB TEST.
     * 3. Updates and inserts records into target dimensions.
     *
     * [Target Dimensions]
     * 1. LAB_TEST_RESULT
     * 2. TEST_RESULT_GROUPING
     * 3. RESULT_COMMENT_GROUP
     * 4. LAB_RESULT_VAL
     * 5. LAB_RESULT_COMMENT
     */ 

    DECLARE @batch_id bigint;
    SET @batch_id = CAST((format(GETDATE(), 'yyMMddHHmmssffff')) AS bigint);
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
    DECLARE @Dataflow_Name VARCHAR(200) = 'D_LABTEST_RESULTS Post-Processing Event';
    DECLARE @Package_Name VARCHAR(200) = 'sp_d_labtest_result_postprocessing';

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT], [Msg_Description1])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO, LEFT('ID List-' +@pLabResultList, 500));

        --------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #labResult_ids';

        IF OBJECT_ID('#labResult_ids', 'U') IS NOT NULL
            DROP TABLE #labResult_ids;

        SELECT value AS observation_uid
        INTO #labResult_ids
        FROM STRING_SPLIT(@pLabResultList, ',');

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #labResult_ids;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);        

        --------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #TMP_D_LAB_TEST_N';

		IF OBJECT_ID('#TMP_D_LAB_TEST_N', 'U') IS NOT NULL
            DROP TABLE #TMP_D_LAB_TEST_N;

        --List of new Observations for Lab Test Result
        SELECT 
			lt.lab_test_key,
            lt.root_ordered_test_pntr,
            lt.lab_test_uid,
            lt.record_status_cd,
            lt.lab_rpt_created_dt,
            lt.lab_test_type, -- for TMP_Result_And_R_Result
            lt.elr_ind,       -- for TMP_Result_And_R_Result
            lt.LAB_TEST_CD
        INTO #TMP_D_LAB_TEST_N
        FROM [dbo].LAB_TEST lt WITH (NOLOCK)
        INNER JOIN #labResult_ids ids ON ids.observation_uid = lt.lab_test_uid 

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_D_LAB_TEST_N;

        IF @pDebug = 'true' SELECT 'DEBUG: TMP_D_LAB_TEST_N', * FROM #TMP_D_LAB_TEST_N;

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #TMP_lab_test_resultInit ';

		IF OBJECT_ID('#TMP_lab_test_resultInit', 'U') IS NOT NULL
            DROP TABLE #TMP_lab_test_resultInit;

        --Get morbidity reports associated to lab
        SELECT tst.lab_test_key,
               tst.root_ordered_test_pntr,
               tst.lab_test_uid,
               tst.record_status_cd,
               tst.Root_Ordered_Test_Pntr      AS Root_Ordered_Test_Pntr2,
               tst.lab_rpt_created_dt,
               no2.associated_phc_uids,
               COALESCE(morb.morb_rpt_key, 1)  AS MORB_RPT_KEY, 
               morb_event.PATIENT_KEY          AS morb_patient_key,
               morb_event.Condition_Key        AS morb_Condition_Key,
               morb_event.Investigation_Key    AS morb_Investigation_Key,
               morb_event.MORB_RPT_SRC_ORG_KEY AS MORB_RPT_SRC_ORG_KEY
        INTO #TMP_lab_test_resultInit
        FROM #TMP_D_LAB_TEST_N tst
		/* Morb report */
		LEFT JOIN [dbo].nrt_observation no2 WITH (NOLOCK) 
			ON tst.lab_test_uid = no2.observation_uid
		LEFT JOIN [dbo].Morbidity_Report AS morb WITH (NOLOCK)
			ON no2.report_observation_uid = morb.morb_rpt_uid
		LEFT JOIN [dbo].Morbidity_Report_Event morb_event WITH (NOLOCK) 
			ON morb_event.morb_rpt_key = morb.morb_rpt_key;

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;
		
		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_lab_test_resultInit;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #TMP_nrt_observation_txt ';

		IF OBJECT_ID('#TMP_nrt_observation_txt', 'U') IS NOT NULL
            DROP TABLE #TMP_nrt_observation_txt;

		;WITH obstxt AS (
			SELECT obt.*
			FROM [dbo].nrt_observation_txt obt WITH (NOLOCK)
			INNER JOIN #labResult_ids ids ON ids.observation_uid = obt.observation_uid 
		)
        SELECT obstxt.*
        INTO #TMP_nrt_observation_txt
        FROM obstxt
		LEFT OUTER JOIN [dbo].nrt_observation obs WITH (NOLOCk)
			ON obs.observation_uid = obstxt.observation_uid
        WHERE ISNULL(obs.batch_id, 1) = ISNULL(obstxt.batch_id, 1);

        SELECT @RowCount_no = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_nrt_observation_txt;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #TMP_nrt_observation_coded';

		IF OBJECT_ID('#TMP_nrt_observation_coded', 'U') IS NOT NULL
            DROP TABLE #TMP_nrt_observation_coded;

		;WITH obscoded AS (
			SELECT obc.*
			FROM [dbo].nrt_observation_coded obc WITH (NOLOCK)
			INNER JOIN #labResult_ids ids ON ids.observation_uid = obc.observation_uid 
		)
        SELECT obscoded.*
        INTO #TMP_nrt_observation_coded
        FROM obscoded
		LEFT OUTER JOIN [dbo].nrt_observation obs WITH (NOLOCk)
			ON obs.observation_uid = obscoded.observation_uid
        WHERE ISNULL(obs.batch_id, 1) = ISNULL(obscoded.batch_id, 1);

        SELECT @RowCount_no = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_nrt_observation_coded;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

		--------------------------------------------------------------------------------------------------------------------------------


        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #TMP_nrt_observation_numeric';

		IF OBJECT_ID('#TMP_nrt_observation_numeric', 'U') IS NOT NULL
            DROP TABLE #TMP_nrt_observation_numeric;
        
		;WITH obsnum AS (
			SELECT obn.*
			FROM [dbo].nrt_observation_numeric obn WITH (NOLOCK)
			INNER JOIN #labResult_ids ids ON ids.observation_uid = obn.observation_uid
		)
		SELECT obsnum.*
        INTO #TMP_nrt_observation_numeric
        FROM obsnum
		LEFT OUTER JOIN [dbo].nrt_observation obs WITH (NOLOCK)
            ON obs.observation_uid = obsnum.observation_uid
        WHERE ISNULL(obs.batch_id, 1) = ISNULL(obsnum.batch_id, 1);

        SELECT @RowCount_no = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_nrt_observation_numeric;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

		--------------------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #TMP_nrt_observation_date';

		IF OBJECT_ID('#TMP_nrt_observation_date', 'U') IS NOT NULL
            DROP TABLE #TMP_nrt_observation_date;

		;WITH obsdate AS (
			SELECT obd.*
			FROM [dbo].nrt_observation_date obd WITH (NOLOCK)
			INNER JOIN #labResult_ids ids ON ids.observation_uid = obd.observation_uid
		)
        SELECT obsdate.*
        INTO #TMP_nrt_observation_date
        FROM obsdate
		LEFT OUTER JOIN [dbo].nrt_observation obs WITH (NOLOCK)
			ON obs.observation_uid = obsdate.observation_uid
        WHERE isnull(obs.batch_id, 1) = isnull(obsdate.batch_id, 1);

        SELECT @RowCount_no = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_nrt_observation_date;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Test_Result1 ';

		IF OBJECT_ID('#TMP_Lab_Test_Result1', 'U') IS NOT NULL
            DROP TABLE #TMP_Lab_Test_Result1;

        SELECT tst.lab_test_key,
			tst.root_ordered_test_pntr,
			tst.lab_test_uid,
			tst.record_status_cd,
			tst.Root_Ordered_Test_Pntr       	AS Root_Ordered_Test_Pntr2,
			tst.lab_rpt_created_dt,
			morb_rpt_key,
			tst.morb_patient_key,
			tst.morb_Condition_Key,
			tst.morb_Investigation_Key,
			tst.MORB_RPT_SRC_ORG_KEY,
			/*per1.person_key AS Transcriptionist_Key,*/
			/*per2.person_key AS Assistant_Interpreter_Key,*/
			/*per3.person_key AS Result_Interpreter_Key,*/
			COALESCE(per4.provider_key, 1)   	AS Specimen_Collector_Key,
			COALESCE(per5.provider_key, 1)   	AS Copy_To_Provider_Key,
			COALESCE(per6.provider_key, 1)   	AS Lab_Test_Technician_key,
			COALESCE(org.Organization_key, 1)   AS REPORTING_LAB_KEY,     
			COALESCE(prv.provider_key, 1)       AS ORDERING_PROVIDER_KEY, 
			COALESCE(org2.Organization_key, 1)  AS ORDERING_ORG_KEY,      
			COALESCE(con.condition_key, 1)      AS CONDITION_KEY,         
			COALESCE(dat.Date_key, 1)        	AS LAB_RPT_DT_KEY,
			COALESCE(inv.Investigation_key, 1)  AS INVESTIGATION_KEY,     
			COALESCE(ldf_g.ldf_group_key, 1) 	AS LDF_GROUP_KEY,
			tst.record_status_cd             	AS record_status_cd2,
			CAST(NULL AS BIGINT)                AS RESULT_COMMENT_GRP_KEY
        INTO #TMP_Lab_Test_Result1
        FROM #TMP_lab_test_resultInit AS tst 
		LEFT JOIN [dbo].nrt_observation AS no2 WITH (NOLOCK)
			ON tst.lab_test_uid = no2.observation_uid
		LEFT JOIN [dbo].nrt_observation AS no3 WITH (NOLOCK)
			ON tst.Root_Ordered_Test_Pntr = no3.observation_uid
            /*get specimen collector: Associated to Root Order*/
		LEFT JOIN [dbo].d_provider AS per4 WITH (NOLOCK)
			ON no3.specimen_collector_id = per4.provider_uid
            /*get copy_to_provider key: Associated to Root Order*/
		LEFT JOIN [dbo].d_provider AS per5 WITH (NOLOCK)
			ON no3.specimen_collector_id = per5.provider_uid
            /*get lab_test_technician: Associated to Root Order*/
		LEFT JOIN [dbo].d_provider AS per6 WITH (NOLOCK)
			ON no3.lab_test_technician_id = per6.provider_uid
            /* Ordering Provider
             * CNDE-2548: Account for Multiple ORD associated to a lab
             * */
		LEFT JOIN [dbo].d_provider AS prv WITH (NOLOCK)
			ON EXISTS (SELECT 1
                FROM STRING_SPLIT(no2.ordering_person_id, ',') nprv
                WHERE cast(nprv.value as bigint) = prv.provider_uid)
            --ON no2.ordering_person_id = prv.provider_uid
            /* Reporting_Lab*/
		LEFT JOIN [dbo].d_Organization AS org WITH (NOLOCK)
			ON no2.author_organization_id = org.Organization_uid
            /* Ordering Facility*/
		LEFT JOIN [dbo].d_Organization AS org2 WITH (NOLOCK)
			ON no2.ordering_organization_id = org2.Organization_uid
            /* Condition it's just program area */
            /*IF we add a program area to the Lab_Report Dimension we probably don't
               even need a condition dimension.  Even though it's OK with the Dimension Modeling
               principle for adding a prog_area_cd row to the condition, it sure will cause
               some confusion among users.  There's no "disease" ON the input.
             */
		LEFT JOIN [dbo].condition AS con WITH (NOLOCK)
			ON no2.prog_area_cd = con.program_area_cd AND con.condition_cd IS NULL
            /*LDF_GRP_KEY*/
            --LEFT JOIN ldf_group AS ldf_g 	ON tst.Lab_test_UID = ldf_g.business_object_uid --VS
		LEFT JOIN [dbo].ldf_group AS ldf_g WITH (NOLOCK)
			ON tst.Lab_test_UID = ldf_g.ldf_group_key
            /* Lab_Rpt_Dt */ --VS	LEFT JOIN rdb_datetable 		as dat
		LEFT JOIN [dbo].rdb_date AS dat WITH (NOLOCK)
			ON DATEADD(d, 0, DATEDIFF(d, 0, [lab_rpt_created_dt])) = dat.DATE_MM_DD_YYYY
            /* PHC: Using nrt_observation's associated_phc_uids which captures observation-investigation mapping  */
		LEFT JOIN [dbo].investigation AS inv WITH (NOLOCK) 
			ON EXISTS (SELECT 1
				FROM STRING_SPLIT(tst.associated_phc_uids, ',') i
				WHERE cast(i.value as bigint) = inv.case_uid);

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_Lab_Test_Result1;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Result_And_R_Result ';

		IF OBJECT_ID('#TMP_Result_And_R_Result', 'U') IS NOT NULL
            DROP TABLE #TMP_Result_And_R_Result;

        SELECT *
        INTO #TMP_Result_And_R_Result
        FROM #TMP_D_LAB_TEST_N 
        WHERE (Lab_Test_Type = 'Result' OR Lab_Test_Type IN ('R_Result', 'I_Result', 'Order_rslt'));

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_Result_And_R_Result;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Result_Comment ';

		IF OBJECT_ID('#TMP_Lab_Result_Comment', 'U') IS NOT NULL
            DROP TABLE #TMP_Lab_Result_Comment;

        /*Notes: Inner Join specified*/
        SELECT 
			lab104.lab_test_uid,
			REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13), ' '), CHAR(10),' ')  AS LAB_RESULT_COMMENTS, 
			ovt.ovt_seq  AS LAB_RESULT_TXT_SEQ,  
            lab104.record_status_cd
        INTO #TMP_Lab_Result_Comment
        FROM #TMP_Result_And_R_Result AS lab104
		INNER JOIN #TMP_nrt_observation_txt AS ovt 
			ON ovt.observation_uid = lab104.lab_test_uid
        WHERE ovt.ovt_value_txt IS NOT NULL
          AND ovt.ovt_txt_type_cd = 'N'
          AND ovt.ovt_seq <> 0;

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_Lab_Result_Comment;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        --------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_New_Lab_Result_Comment ';

        IF OBJECT_ID('#TMP_New_Lab_Result_Comment', 'U') IS NOT NULL
            DROP TABLE #TMP_New_Lab_Result_Comment;

        SELECT *,
               cast(NULL AS varchar(2000)) AS v_lab_result_val_comments
        INTO #TMP_New_Lab_Result_Comment
        FROM #TMP_Lab_Result_Comment;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_New_Lab_Result_Comment;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_New_Lab_Result_Comment_grouped ';

		IF OBJECT_ID('#TMP_New_Lab_Result_Comment_grouped', 'U') IS NOT NULL
            DROP TABLE #TMP_New_Lab_Result_Comment_grouped;

		-- create index idx_TMP_New_Lab_Result_Comment_uid ON  #TMP_New_Lab_Result_Comment (lab_test_uid);

        SELECT DISTINCT 
			LRV.lab_test_uid,
			SUBSTRING((SELECT ' ' + ST1.lab_result_comments AS [text()]
				FROM #TMP_New_Lab_Result_Comment ST1
				WHERE ST1.lab_test_uid = LRV.lab_test_uid
				ORDER BY ST1.lab_test_uid, ST1.lab_result_txt_seq
				FOR XML PATH ('')), 2, 2000) AS v_lab_result_val_txt
        INTO #TMP_New_Lab_Result_Comment_grouped
        FROM #TMP_New_Lab_Result_Comment LRV;


        UPDATE #TMP_New_Lab_Result_Comment
        SET lab_result_comments = (
			SELECT 
				CASE
					WHEN v_lab_result_val_txt = '#x20;' 
					THEN NULL
					ELSE v_lab_result_val_txt 
				END AS v_lab_result_val_txt
			FROM #TMP_New_Lab_Result_Comment_grouped tnl
			WHERE tnl.lab_test_uid = #TMP_New_Lab_Result_Comment.lab_test_uid
		);

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_New_Lab_Result_Comment_grouped;
        
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_New_Lab_Result_Comment_FINAL ';

        IF OBJECT_ID('#TMP_New_Lab_Result_Comment_FINAL', 'U') IS NOT NULL
            DROP TABLE #TMP_New_Lab_Result_Comment_FINAL;

        -- INSERT INTO #TMP_New_Lab_Result_Comment_FINAL
        SELECT DISTINCT 
			lab_test_uid,
            CAST(NULL AS BIGINT) AS LAB_RESULT_COMMENT_KEY,
			CASE
				WHEN [LAB_RESULT_COMMENTS] LIKE '%.&#x20;%'
				THEN REPLACE([LAB_RESULT_COMMENTS], '&#x20;', ' ')
				ELSE [LAB_RESULT_COMMENTS]
            END AS LAB_RESULT_COMMENTS,
            CAST(NULL AS BIGINT) AS RESULT_COMMENT_GRP_KEY,
            CASE
				WHEN record_status_cd = 'LOG_DEL' THEN 'INACTIVE'
				WHEN record_status_cd IN ('', 'UNPROCESSED', 'PROCESSED') THEN 'ACTIVE'
				ELSE 'ACTIVE'
            END AS record_status_cd,
        	GETDATE() AS RDB_LAST_REFRESH_TIME
		INTO #TMP_New_Lab_Result_Comment_FINAL
        FROM #TMP_New_Lab_Result_Comment;

		UPDATE #TMP_New_Lab_Result_Comment_FINAL
        SET [LAB_RESULT_COMMENTS] = (REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([LAB_RESULT_COMMENTS],
                                                                                             '&#x09;', CHAR(9)),
                                                                                     '&#x0A;', CHAR(10)),
                                                                             '&#x0D;', CHAR(13)),
                                                                     '&#x20;', CHAR(32)),
                                                             '&amp;', CHAR(38)),
                                                     '&lt;', CHAR(60)),
                                             '&gt;', CHAR(62)));

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_New_Lab_Result_Comment_FINAL;
        
		
		INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

		SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #Lab_Result_Comment_N ';

		IF OBJECT_ID('#Lab_Result_Comment_N', 'U') IS NOT NULL
            DROP TABLE #Lab_Result_Comment_N;

		SELECT 
			f.lab_test_uid 
		INTO #Lab_Result_Comment_N	
		FROM #TMP_New_Lab_Result_Comment_FINAL f
		WHERE f.RECORD_STATUS_CD <> 'INACTIVE'
		EXCEPT
		SELECT ck.LAB_RESULT_COMMENT_UID AS lab_test_uid
		FROM [dbo].nrt_lab_result_comment_key ck WITH (NOLOCK);

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #Lab_Result_Comment_N;
		
		INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

		SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #Lab_Result_Comment_E ';

		IF OBJECT_ID('#Lab_Result_Comment_E', 'U') IS NOT NULL
            DROP TABLE #Lab_Result_Comment_E;

		SELECT 
			f.lab_test_uid 
		INTO #Lab_Result_Comment_E	
		FROM #TMP_New_Lab_Result_Comment_FINAL f
		INNER JOIN [dbo].nrt_lab_result_comment_key ck WITH (NOLOCK)
			ON ck.LAB_RESULT_COMMENT_UID = f.lab_test_uid
		WHERE f.RECORD_STATUS_CD <> 'INACTIVE';

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #Lab_Result_Comment_E;
		
		INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------
		
		SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #Lab_Result_Comment_D ';

		IF OBJECT_ID('#Lab_Result_Comment_D', 'U') IS NOT NULL
            DROP TABLE #Lab_Result_Comment_D;

		SELECT 
			f.lab_test_uid 
		INTO #Lab_Result_Comment_D	
		FROM #TMP_New_Lab_Result_Comment_FINAL f
		INNER JOIN [dbo].nrt_lab_result_comment_key ck WITH (NOLOCK)
			ON ck.LAB_RESULT_COMMENT_UID = f.lab_test_uid
		WHERE f.RECORD_STATUS_CD = 'INACTIVE';

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #Lab_Result_Comment_D;
		
		INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------
		
		BEGIN TRANSACTION 

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'GENERATING keys for new LAB_RESULT_COMMENTS ';
		

			INSERT INTO [dbo].nrt_lab_result_comment_key (LAB_RESULT_COMMENT_UID)
			SELECT lab_test_uid
			FROM #Lab_Result_Comment_N

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF @pDebug = 'true'
				SELECT @Proc_Step_Name AS step, * 
				FROM [dbo].nrt_lab_result_comment_key ck WITH(NOLOCK)
				INNER JOIN #Lab_Result_Comment_N n 
				ON n.lab_test_uid = ck.LAB_RESULT_COMMENT_UID;
			
			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		COMMIT TRANSACTION

		--------------------------------------------------------------------------------------------------------------------------------------------
		
		SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'UPDATING keys in #TMP_New_Lab_Result_Comment_FINAL ';

		UPDATE f
			SET 
				f.LAB_RESULT_COMMENT_KEY = ck.LAB_RESULT_COMMENT_KEY,
				f.RESULT_COMMENT_GRP_KEY = ck.LAB_RESULT_COMMENT_KEY
		FROM #TMP_New_Lab_Result_Comment_FINAL f
		INNER JOIN [dbo].nrt_lab_result_comment_key ck WITH(NOLOCK)
			ON ck.LAB_RESULT_COMMENT_UID = f.lab_test_uid

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_New_Lab_Result_Comment_FINAL;
		
		INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Result_Comment_Group ';

        IF OBJECT_ID('#TMP_Result_Comment_Group', 'U') IS NOT NULL
            DROP TABLE #TMP_Result_Comment_Group;

        SELECT DISTINCT 
			rcg.Lab_Result_Comment_Key AS [RESULT_COMMENT_GRP_KEY],
        	rcg.[LAB_TEST_UID]
        INTO #tmp_Result_Comment_Group
        FROM #TMP_New_Lab_Result_Comment_FINAL rcg
        --WHERE  rcg.Lab_Result_Comment_Key <> 1 AND rcg.Lab_Result_Comment_Key IS not NULL
        ORDER BY rcg.Lab_Result_Comment_Key;


        IF NOT EXISTS (SELECT * FROM [dbo].RESULT_COMMENT_GROUP WITH (NOLOCK) WHERE [RESULT_COMMENT_GRP_KEY] = 1)
            INSERT INTO #tmp_Result_Comment_Group values (1, NULL);

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_Result_Comment_Group;


        UPDATE #TMP_lab_test_result1
        SET [RESULT_COMMENT_GRP_KEY] = (SELECT [RESULT_COMMENT_GRP_KEY]
                                        FROM #tmp_Result_Comment_Group trcg
                                        WHERE trcg.lab_test_uid = #tmp_lab_test_result1.lab_test_uid);
        UPDATE #TMP_lab_test_result1
        SET [RESULT_COMMENT_GRP_KEY] = 1
        WHERE [RESULT_COMMENT_GRP_KEY] IS NULL;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        --------------------------------------------------------------------------------------------------------------------------------------------


        /*-------------------------------------------------------

		Lab_Result_Val Dimension
		Test_Result_Grouping Dimension

		---------------------------------------------------------*/


        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Result_Val ';

        IF OBJECT_ID('#TMP_Lab_Result_Val', 'U') IS NOT NULL
            DROP TABLE #TMP_Lab_Result_Val;

        --INSERT INTO #TMP_Lab_Result_Val
        SELECT 
			rslt.lab_test_uid,
			NULLIF(TRIM(REPLACE(REPLACE(
			otxt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ')),'')	AS LAB_RESULT_TXT_VAL,
			otxt.ovt_seq                             				AS LAB_RESULT_TXT_SEQ,          
			onum.ovn_comparator_cd_1                                AS COMPARATOR_CD_1,
			onum.ovn_numeric_value_1 								AS NUMERIC_VALUE_1,
			onum.ovn_separator_cd    								AS SEPARATOR_CD,
			onum.ovn_numeric_value_2 								AS NUMERIC_VALUE_2,
			CASE
				WHEN RTRIM(onum.ovn_numeric_unit_cd) = '' THEN NULL
				ELSE onum.ovn_numeric_unit_cd 
			END 													AS RESULT_UNITS,
			SUBSTRING(onum.ovn_low_range, 1, 20)     				AS REF_RANGE_FRM,
			SUBSTRING(onum.ovn_high_range, 1, 20)   				AS REF_RANGE_TO,
			CASE
				WHEN RTRIM(code.ovc_code) = '' THEN NULL
				ELSE code.ovc_code 
			END            											AS TEST_RESULT_VAL_CD,
			CASE
				WHEN RTRIM(code.ovc_display_name) = '' THEN NULL
				ELSE code.ovc_display_name 
			END    													AS TEST_RESULT_VAL_CD_DESC,
			code.ovc_CODE_SYSTEM_CD                  				AS TEST_RESULT_VAL_CD_SYS_CD,
			code.ovc_CODE_SYSTEM_DESC_TXT            				AS TEST_RESULT_VAL_CD_SYS_NM,
			code.ovc_ALT_CD                          				AS ALT_RESULT_VAL_CD,
			code.ovc_ALT_CD_DESC_TXT                 				AS ALT_RESULT_VAL_CD_DESC,
			code.ovc_ALT_CD_SYSTEM_CD                				AS ALT_RESULT_VAL_CD_SYS_CD,
			code.ovc_ALT_CD_SYSTEM_DESC_TXT          				AS ALT_RESULT_VAL_CD_SYSTEM_NM,
			ndate.ovd_from_date                      				AS FROM_TIME,
			ndate.ovd_to_date                        				AS TO_TIME,
			CASE
				WHEN record_status_cd = 'LOG_DEL' THEN 'INACTIVE'
				WHEN record_status_cd IN ('', 'UNPROCESSED', 'PROCESSED') THEN 'ACTIVE'
				ELSE 'ACTIVE'
			END                               						AS RECORD_STATUS_CD,
			CAST(NULL AS BIGINT)                                   	AS TEST_RESULT_GRP_KEY,
			CASE
				WHEN onum.ovn_numeric_value_1 IS NOT NULL AND onum.ovn_numeric_value_2 IS NULL THEN
					rtrim(COALESCE(onum.ovn_comparator_cd_1, '')) + 
						rtrim(format(ovn_numeric_value_1, '0.#########'))
				WHEN onum.ovn_numeric_value_1 IS NOT NULL AND onum.ovn_numeric_value_2 IS NOT NULL THEN
					rtrim(COALESCE(rtrim(COALESCE(onum.ovn_comparator_cd_1, '')) +
						rtrim(format(ovn_numeric_value_1, '0.#########')), '')) +
					rtrim((COALESCE(onum.ovn_separator_cd, ''))) +
					rtrim(format(onum.ovn_numeric_value_2, '0.#########'))
				WHEN onum.ovn_numeric_value_1 IS NULL AND onum.ovn_numeric_value_2 IS NOT NULL THEN
					rtrim(COALESCE(NULL, '')) + rtrim((COALESCE(onum.ovn_separator_cd, ''))) +
					rtrim(format(onum.ovn_numeric_value_2, '0.#########'))
				ELSE NULL 
			END                     								AS NUMERIC_RESULT,
			CAST(NULL AS BIGINT) 									AS TEST_RESULT_VAL_KEY,
			CAST(NULL AS VARCHAR(2000))  							AS LAB_RESULT_TXT_VAL1
        INTO #TMP_Lab_Result_Val
		FROM #TMP_Result_And_R_Result AS rslt
		LEFT JOIN #TMP_nrt_observation_txt AS otxt 
			ON rslt.lab_test_uid = otxt.observation_uid
            AND ((otxt.ovt_txt_type_cd IS NULL) OR (rslt.ELR_IND = 'Y' AND otxt.ovt_txt_type_cd <> 'N'))
            --AND otxt.OBS_VALUE_TXT_SEQ =1
            /*
            Commented out because an ELR Test Result can have zero to many text result values
            AND otxt.OBS_VALUE_TXT_SEQ =1
            */
		LEFT JOIN #TMP_nrt_observation_numeric AS onum ON rslt.lab_test_uid = onum.observation_uid
		LEFT JOIN #TMP_nrt_observation_coded AS code ON rslt.lab_test_uid = code.observation_uid
		LEFT JOIN #TMP_nrt_observation_date AS ndate ON rslt.lab_test_uid = ndate.observation_uid

        --LEFT JOIN (SELECT *, ROW_NUMBER() OVER (PARTITION BY observation_uid ORDER BY refresh_datetime DESC) AS cr
        --	FROM nrt_observation_coded WITH (NOLOCK)) code on rslt.lab_test_uid = code.observation_uid and code.cr=1;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_Lab_Result_Val;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

		SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TEST_Result_Group_N ';

		IF OBJECT_ID('#TEST_Result_Group_N', 'U') IS NOT NULL
            DROP TABLE #TEST_Result_Group_N;

		SELECT 
			f.lab_test_uid 
		INTO #TEST_Result_Group_N	
		FROM #TMP_Lab_Result_Val f
		WHERE f.RECORD_STATUS_CD <> 'INACTIVE'
		EXCEPT
		SELECT ck.LAB_TEST_UID 
		FROM [dbo].nrt_lab_test_result_group_key ck WITH (NOLOCK);
		
		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TEST_Result_Group_N;
		
		INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

		SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TEST_Result_Group_E ';

		IF OBJECT_ID('#TEST_Result_Group_E', 'U') IS NOT NULL
            DROP TABLE #TEST_Result_Group_E;

		SELECT 
			f.lab_test_uid 
		INTO #TEST_Result_Group_E	
		FROM #TMP_Lab_Result_Val f
		INNER JOIN [dbo].nrt_lab_test_result_group_key ck WITH (NOLOCK)
			ON ck.LAB_TEST_UID = f.LAB_TEST_UID 
		WHERE f.RECORD_STATUS_CD <> 'INACTIVE'

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TEST_Result_Group_E;
		
		INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

		SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TEST_Result_Group_D ';

		IF OBJECT_ID('#TEST_Result_Group_D', 'U') IS NOT NULL
            DROP TABLE #TEST_Result_Group_D;

		SELECT 
			f.lab_test_uid 
		INTO #TEST_Result_Group_D	
		FROM #TMP_Lab_Result_Val f
		INNER JOIN [dbo].nrt_lab_test_result_group_key ck WITH (NOLOCK)
			ON ck.LAB_TEST_UID = f.LAB_TEST_UID 
		WHERE f.RECORD_STATUS_CD = 'INACTIVE'

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TEST_Result_Group_D;
		
		INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

		BEGIN TRANSACTION 

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'GENERATING keys for new TEST_RESULT_GROUP ';

			INSERT INTO [dbo].nrt_lab_test_result_group_key (LAB_TEST_UID)
			SELECT lab_test_uid
			FROM #TEST_Result_Group_N

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF @pDebug = 'true'
				SELECT @Proc_Step_Name AS step, * 
				FROM [dbo].nrt_lab_test_result_group_key ck WITH(NOLOCK)
				INNER JOIN #TEST_Result_Group_N n 
				ON n.LAB_TEST_UID = ck.LAB_TEST_UID;
			
			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		COMMIT TRANSACTION
		
		--------------------------------------------------------------------------------------------------------------------------------------------
		
		SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'UPDATING keys in #TMP_Lab_Result_Val ';

		UPDATE f
			SET 
				f.TEST_RESULT_GRP_KEY = ck.TEST_RESULT_GRP_KEY,
				f.TEST_RESULT_VAL_KEY = ck.TEST_RESULT_GRP_KEY
		FROM #TMP_Lab_Result_Val f
		INNER JOIN [dbo].nrt_lab_test_result_group_key ck WITH(NOLOCK)
			ON ck.LAB_TEST_UID = f.LAB_TEST_UID

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_Lab_Result_Val;
		
		INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_TEST_RESULT_GROUPING ';

        IF OBJECT_ID('#TMP_TEST_RESULT_GROUPING', 'U') IS NOT NULL
            DROP TABLE #TMP_TEST_RESULT_GROUPING;


        SELECT distinct 
			[TEST_RESULT_GRP_KEY],
            [LAB_TEST_UID]
        --,[RDB_LAST_REFRESH_TIME]
        INTO #TMP_TEST_RESULT_GROUPING
        FROM #TMP_Lab_Result_Val;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_TEST_RESULT_GROUPING;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_New_Lab_Result_Val ';


        SELECT DISTINCT 
			LRV.lab_test_uid,
			SUBSTRING(
					(SELECT ' ' + ST1.lab_result_txt_val AS [text()]
						FROM #TMP_Lab_Result_Val ST1
						WHERE ST1.lab_test_uid = LRV.lab_test_uid
						ORDER BY ST1.lab_test_uid, ST1.lab_result_txt_seq
						FOR XML PATH ('')), 2, 2000) v_lab_result_val_txt
        INTO #TMP_New_Lab_Result_Val
        FROM #TMP_Lab_Result_Val LRV;

        UPDATE #TMP_Lab_Result_Val
        SET lab_result_txt_val = (SELECT NULLIF(v_lab_result_val_txt, '') AS v_lab_result_val_txt
                                  FROM #TMP_New_Lab_Result_Val tnl
                                  WHERE tnl.lab_test_uid = #TMP_Lab_Result_Val.lab_test_uid);

        DELETE
        FROM #TMP_Lab_Result_Val
        WHERE Test_Result_Val_Key = 1;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_Lab_Result_Val;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        --------------------------------------------------------------------------------------------------------------------------------------------


        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Result_Val_Final ';

		IF OBJECT_ID('#TMP_Lab_Result_Val_Final', 'U') IS NOT NULL
            DROP TABLE #TMP_Lab_Result_Val_Final;

        SELECT MIN([TEST_RESULT_GRP_KEY])       AS TEST_RESULT_GRP_KEY
             , [NUMERIC_RESULT]
             , [RESULT_UNITS]
             --,[LAB_RESULT_TXT_VAL]
             , (REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lab_result_txt_val,
                                                                        '&#x09;', CHAR(9)),
                                                                '&#x0A;', CHAR(10)),
                                                        '&#x0D;', CHAR(13)),
                                                '&#x20;', CHAR(32)),
                                        '&amp;', CHAR(38)),
                                '&lt;', CHAR(60)),
                        '&gt;', CHAR(62)))      AS LAB_RESULT_TXT_VAL
             , [REF_RANGE_FRM]
             , [REF_RANGE_TO]
             , [TEST_RESULT_VAL_CD]
             , rtrim([TEST_RESULT_VAL_CD_DESC]) AS [TEST_RESULT_VAL_CD_DESC]
             , [TEST_RESULT_VAL_CD_SYS_CD]
             , [TEST_RESULT_VAL_CD_SYS_NM]
             , [ALT_RESULT_VAL_CD]
             , rtrim([ALT_RESULT_VAL_CD_DESC])  AS [ALT_RESULT_VAL_CD_DESC]
             , [ALT_RESULT_VAL_CD_SYS_CD]
             , [ALT_RESULT_VAL_CD_SYSTEM_NM]
             , MIN([TEST_RESULT_VAL_KEY])       AS TEST_RESULT_VAL_KEY
             , [RECORD_STATUS_CD]
             , [FROM_TIME]
             , [TO_TIME]
             , [LAB_TEST_UID]
        --, GETDATE()
        INTO #TMP_Lab_Result_Val_Final
        FROM #TMP_LAB_RESULT_VAL
        GROUP BY [NUMERIC_RESULT]
               , [RESULT_UNITS]
               , [LAB_RESULT_TXT_VAL]
               , [REF_RANGE_FRM]
               , [REF_RANGE_TO]
               , [TEST_RESULT_VAL_CD]
               , rtrim([TEST_RESULT_VAL_CD_DESC])
               , [TEST_RESULT_VAL_CD_SYS_CD]
               , [TEST_RESULT_VAL_CD_SYS_NM]
               , [ALT_RESULT_VAL_CD]
               , rtrim([ALT_RESULT_VAL_CD_DESC])
               , [ALT_RESULT_VAL_CD_SYS_CD]
               , [ALT_RESULT_VAL_CD_SYSTEM_NM]
               , [RECORD_STATUS_CD]
               , [FROM_TIME]
               , [TO_TIME]
               , [LAB_TEST_UID];


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_Lab_Result_Val_Final;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Test_Result2 ';


        SELECT 
			tst.*,
            COALESCE(lrv.Test_Result_Grp_Key, 1) AS Test_Result_Grp_Key
        INTO #TMP_Lab_Test_Result2
        FROM #TMP_Lab_Test_Result1 AS tst
		LEFT JOIN #TMP_Lab_Result_Val_FINAL AS lrv 
			ON tst.Lab_test_uid = lrv.Lab_test_uid
            AND lrv.Test_Result_Grp_Key <> 1;

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;
		
		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_Lab_Test_Result2;
        
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Test_Result3 ';


        SELECT 
			tst.*,
            COALESCE(psn.patient_key, 1) AS patient_key
        INTO #TMP_Lab_Test_Result3
        FROM #TMP_Lab_Test_Result2 AS tst
                 /*Get patient id for root observation ids*/
		LEFT JOIN [dbo].nrt_observation no2 WITH (NOLOCK) 
			ON no2.observation_uid = tst.root_ordered_test_pntr
		LEFT JOIN [dbo].d_patient AS psn WITH (NOLOCK)
			ON no2.patient_id = psn.patient_uid
			AND psn.patient_key <> 1;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_Lab_Test_Result3;

        UPDATE #TMP_Lab_Test_Result3
        SET PATIENT_KEY       = morb_patient_key,
            Condition_Key     = morb_Condition_Key,
            Investigation_Key = morb_Investigation_Key,
            REPORTING_LAB_KEY = MORB_RPT_SRC_ORG_KEY
        WHERE morb_rpt_key > 1;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
		
		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_Lab_Test_Result3;
        
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Test_Result ';

        SELECT DISTINCT 
			tst.*,
            COALESCE(org.Organization_key, 1) AS Performing_lab_key
        INTO #TMP_Lab_Test_Result
        FROM #TMP_Lab_Test_Result3 AS tst
		LEFT JOIN [dbo].nrt_observation AS no2 WITH (NOLOCK) 
			ON no2.observation_uid = tst.lab_test_uid
        LEFT JOIN [dbo].d_Organization AS org WITH (NOLOCK)
			ON no2.performing_organization_id = org.Organization_uid
			AND org.Organization_key <> 1;

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF @pDebug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #TMP_Lab_Test_Result;
       
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

		--------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'DELETING #TMP_TEST_RESULT_GROUPING ';

			IF @pDebug = 'true'
				SELECT @Proc_Step_Name AS step, * 
				FROM #TMP_TEST_RESULT_GROUPING 
				WHERE 
					test_result_grp_key = 1
					OR test_result_grp_key IS NULL
					OR test_result_grp_key NOT IN (
						SELECT TEST_RESULT_GRP_KEY 
						FROM #TMP_LAB_RESULT_VAL 
						WHERE TEST_RESULT_GRP_KEY IS NOT NULL
					);

			DELETE FROM #TMP_TEST_RESULT_GROUPING
			WHERE 
				test_result_grp_key = 1
				OR test_result_grp_key IS NULL
				OR test_result_grp_key NOT IN (
					SELECT TEST_RESULT_GRP_KEY 
					FROM #TMP_LAB_RESULT_VAL 
					WHERE TEST_RESULT_GRP_KEY IS NOT NULL
				);

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'UPDATE LAB_RESULT_VAL ';

			UPDATE dbo.LAB_RESULT_VAL
			SET [NUMERIC_RESULT]            = SUBSTRING(tmp.NUMERIC_RESULT, 1, 50),
				[RESULT_UNITS]              = SUBSTRING(tmp.RESULT_UNITS, 1, 50),
				[LAB_RESULT_TXT_VAL]        = rtrim(ltrim(SUBSTRING(tmp.LAB_RESULT_TXT_VAL, 1, 2000))),
				[REF_RANGE_FRM]             = SUBSTRING(tmp.REF_RANGE_FRM, 1, 20),
				[REF_RANGE_TO]              = SUBSTRING(tmp.REF_RANGE_TO, 1, 20),
				[TEST_RESULT_VAL_CD]        = SUBSTRING(tmp.TEST_RESULT_VAL_CD, 1, 20),
				[TEST_RESULT_VAL_CD_DESC]   = SUBSTRING(rtrim(tmp.TEST_RESULT_VAL_CD_DESC), 1, 300),
				[TEST_RESULT_VAL_CD_SYS_CD] = SUBSTRING(tmp.TEST_RESULT_VAL_CD_SYS_CD, 1, 100),
				[TEST_RESULT_VAL_CD_SYS_NM] = SUBSTRING(tmp.TEST_RESULT_VAL_CD_SYS_NM, 1, 100),
				[ALT_RESULT_VAL_CD]         = SUBSTRING(tmp.ALT_RESULT_VAL_CD, 1, 50),
				[ALT_RESULT_VAL_CD_DESC]    = SUBSTRING(rtrim(tmp.ALT_RESULT_VAL_CD_DESC), 1, 100),
				[ALT_RESULT_VAL_CD_SYS_CD]  = SUBSTRING(tmp.ALT_RESULT_VAL_CD_SYS_CD, 1, 50),
				[ALT_RESULT_VAL_CD_SYS_NM]  = SUBSTRING(tmp.ALT_RESULT_VAL_CD_SYSTEM_NM, 1, 100),
				[TEST_RESULT_VAL_KEY]       = tmp.TEST_RESULT_VAL_KEY,
				[RECORD_STATUS_CD]          = SUBSTRING(tmp.RECORD_STATUS_CD, 1, 8),
				[FROM_TIME]                 = tmp.FROM_TIME,
				[TO_TIME]                   = tmp.TO_TIME,
				[LAB_TEST_UID]              = tmp.LAB_TEST_UID,
				[RDB_LAST_REFRESH_TIME]     = GETDATE()
			FROM #TMP_LAB_RESULT_VAL_FINAL tmp
			INNER JOIN [dbo].LAB_RESULT_VAL val WITH (NOLOCK) 
				ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
				AND val.TEST_RESULT_GRP_KEY = tmp.TEST_RESULT_GRP_KEY
				AND val.TEST_RESULT_VAL_KEY = val.TEST_RESULT_VAL_KEY;


			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF @pDebug = 'true'
				SELECT @Proc_Step_Name AS step, * 
				FROM #TMP_LAB_RESULT_VAL_FINAL tmp
				INNER JOIN [dbo].LAB_RESULT_VAL val WITH (NOLOCK) 
					ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
					AND val.TEST_RESULT_GRP_KEY = tmp.TEST_RESULT_GRP_KEY
					AND val.TEST_RESULT_VAL_KEY = val.TEST_RESULT_VAL_KEY;

			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'UPDATE TEST_RESULT_GROUPING';

			--No downstream update of RDB_LAST_REFRESH_TIME.
			UPDATE dbo.TEST_RESULT_GROUPING
			SET [TEST_RESULT_GRP_KEY]   = tmp.TEST_RESULT_GRP_KEY,
				[LAB_TEST_UID]          = tmp.LAB_TEST_UID,
				[RDB_LAST_REFRESH_TIME] = CAST(NULL AS datetime)
			FROM #TMP_TEST_RESULT_GROUPING tmp
			INNER JOIN [dbo].TEST_RESULT_GROUPING g WITH (NOLOCK) 
				ON g.LAB_TEST_UID = tmp.LAB_TEST_UID
				AND g.TEST_RESULT_GRP_KEY = tmp.TEST_RESULT_GRP_KEY;

			IF @pDebug = 'true'
                SELECT @Proc_Step_Name AS step, tmp.* 
                FROM #TMP_TEST_RESULT_GROUPING tmp
				INNER JOIN [dbo].TEST_RESULT_GROUPING g WITH (NOLOCK) 
					ON g.LAB_TEST_UID = tmp.LAB_TEST_UID
					AND g.TEST_RESULT_GRP_KEY = tmp.TEST_RESULT_GRP_KEY;


			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------------------------------------------
		/*Update key table for TEST_RESULT_GROUPING*/

		BEGIN TRANSACTION 

            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'UPDATING [dbo].nrt_lab_test_result_group_key table';

			UPDATE trgk 
			SET trgk.[updated_dttm] = GETDATE()
			FROM [dbo].nrt_lab_test_result_group_key trgk 
			INNER JOIN #TMP_TEST_RESULT_GROUPING g 
				ON g.LAB_TEST_UID = trgk.LAB_TEST_UID
				AND g.TEST_RESULT_GRP_KEY = trgk.TEST_RESULT_GRP_KEY;

			SELECT @RowCount_no = @@ROWCOUNT;

            IF @pDebug = 'true'
                SELECT @Proc_Step_Name AS step, trgk.* 
                FROM [dbo].nrt_lab_test_result_group_key trgk WITH (NOLOCK) 
				INNER JOIN #TMP_TEST_RESULT_GROUPING g 
					ON g.LAB_TEST_UID = trgk.LAB_TEST_UID
					AND g.TEST_RESULT_GRP_KEY = trgk.TEST_RESULT_GRP_KEY;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

		COMMIT TRANSACTION

		--------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'GENERATING TEST_RESULT_GROUPING ';

			--No downstream update of RDB_LAST_REFRESH_TIME.
			INSERT INTO dbo.TEST_RESULT_GROUPING
				( [TEST_RESULT_GRP_KEY]
				, [LAB_TEST_UID]
				, [RDB_LAST_REFRESH_TIME])
			SELECT 
				tmp.[TEST_RESULT_GRP_KEY],
				tmp.[LAB_TEST_UID],
				CAST(NULL AS datetime) AS [RDB_LAST_REFRESH_TIME]
			FROM #TMP_TEST_RESULT_GROUPING tmp
			LEFT JOIN dbo.TEST_RESULT_GROUPING g WITH (NOLOCK) 
				ON g.LAB_TEST_UID = tmp.LAB_TEST_UID
			WHERE 
				g.LAB_TEST_UID IS NULL
				AND g.TEST_RESULT_GRP_KEY IS NULL;

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF @pDebug = 'true'
                SELECT @Proc_Step_Name AS step, tmp.* 
                FROM #TMP_TEST_RESULT_GROUPING tmp
				LEFT JOIN dbo.TEST_RESULT_GROUPING g WITH (NOLOCK) 
					ON g.LAB_TEST_UID = tmp.LAB_TEST_UID
				WHERE 
					g.LAB_TEST_UID IS NULL
					AND g.TEST_RESULT_GRP_KEY IS NULL;

			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'INSERTING INTO LAB_RESULT_VAL ';


			INSERT INTO dbo.LAB_RESULT_VAL
			( [TEST_RESULT_GRP_KEY]
			, [NUMERIC_RESULT]
			, [RESULT_UNITS]
			, [LAB_RESULT_TXT_VAL]
			, [REF_RANGE_FRM]
			, [REF_RANGE_TO]
			, [TEST_RESULT_VAL_CD]
			, [TEST_RESULT_VAL_CD_DESC]
			, [TEST_RESULT_VAL_CD_SYS_CD]
			, [TEST_RESULT_VAL_CD_SYS_NM]
			, [ALT_RESULT_VAL_CD]
			, [ALT_RESULT_VAL_CD_DESC]
			, [ALT_RESULT_VAL_CD_SYS_CD]
			, [ALT_RESULT_VAL_CD_SYS_NM]
			, [TEST_RESULT_VAL_KEY]
			, [RECORD_STATUS_CD]
			, [FROM_TIME]
			, [TO_TIME]
			, [LAB_TEST_UID]
			, [RDB_LAST_REFRESH_TIME])
			SELECT tmp.TEST_RESULT_GRP_KEY
				, SUBSTRING(tmp.NUMERIC_RESULT, 1, 50)
				, SUBSTRING(tmp.RESULT_UNITS, 1, 50)
				, rtrim(ltrim(SUBSTRING(tmp.LAB_RESULT_TXT_VAL, 1, 2000)))
				, SUBSTRING(tmp.REF_RANGE_FRM, 1, 20)
				, SUBSTRING(tmp.REF_RANGE_TO, 1, 20)
				, SUBSTRING(tmp.TEST_RESULT_VAL_CD, 1, 20)
				, SUBSTRING(rtrim(tmp.TEST_RESULT_VAL_CD_DESC), 1, 300)
				, SUBSTRING(tmp.TEST_RESULT_VAL_CD_SYS_CD, 1, 100)
				, SUBSTRING(tmp.TEST_RESULT_VAL_CD_SYS_NM, 1, 100)
				, SUBSTRING(tmp.ALT_RESULT_VAL_CD, 1, 50)
				, SUBSTRING(rtrim(tmp.ALT_RESULT_VAL_CD_DESC), 1, 100)
				, SUBSTRING(tmp.ALT_RESULT_VAL_CD_SYS_CD, 1, 50)
				, SUBSTRING(tmp.ALT_RESULT_VAL_CD_SYSTEM_NM, 1, 100)
				, tmp.TEST_RESULT_VAL_KEY
				, SUBSTRING(tmp.RECORD_STATUS_CD, 1, 8)
				, tmp.FROM_TIME
				, tmp.TO_TIME
				, tmp.LAB_TEST_UID
				, GETDATE()
			FROM #TMP_LAB_RESULT_VAL_FINAL tmp
			LEFT JOIN dbo.LAB_RESULT_VAL val WITH (NOLOCK) 
				ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
			WHERE 
				val.LAB_TEST_UID IS NULL
				AND val.TEST_RESULT_VAL_KEY IS NULL;

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF @pDebug = 'true'
                SELECT @Proc_Step_Name AS step, tmp.* 
                FROM #TMP_LAB_RESULT_VAL_FINAL tmp
				LEFT JOIN dbo.LAB_RESULT_VAL val WITH (NOLOCK) 
					ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
				WHERE 
					val.LAB_TEST_UID IS NULL
					AND val.TEST_RESULT_VAL_KEY IS NULL;

			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        COMMIT TRANSACTION;
		--------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'UPDATE RESULT_COMMENT_GROUP ';

			UPDATE dbo.RESULT_COMMENT_GROUP
			SET [RESULT_COMMENT_GRP_KEY] = tmp.RESULT_COMMENT_GRP_KEY,
				[LAB_TEST_UID]           = tmp.LAB_TEST_UID,
				[RDB_LAST_REFRESH_TIME]  = GETDATE()
			FROM #TMP_RESULT_COMMENT_GROUP tmp
					INNER JOIN dbo.RESULT_COMMENT_GROUP val ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
				AND val.RESULT_COMMENT_GRP_KEY = tmp.RESULT_COMMENT_GRP_KEY;

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;
			
			IF @pDebug = 'true'
                SELECT @Proc_Step_Name AS step, tmp.* 
                FROM #TMP_RESULT_COMMENT_GROUP tmp
				INNER JOIN [dbo].RESULT_COMMENT_GROUP val WITH (NOLOCK)
					ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
					AND val.RESULT_COMMENT_GRP_KEY = tmp.RESULT_COMMENT_GRP_KEY;
			
			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'INSERTING INTO RESULT_COMMENT_GROUP ';


			INSERT INTO dbo.RESULT_COMMENT_GROUP
			( [RESULT_COMMENT_GRP_KEY]
			, [LAB_TEST_UID]
			, [RDB_LAST_REFRESH_TIME])
			SELECT tmp.[RESULT_COMMENT_GRP_KEY]
				, tmp.[LAB_TEST_UID]
				, GETDATE()
			FROM #TMP_RESULT_COMMENT_GROUP tmp
			LEFT JOIN [dbo].RESULT_COMMENT_GROUP val WITH (NOLOCK) 
				ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
			WHERE 
				val.LAB_TEST_UID IS NULL
				AND val.RESULT_COMMENT_GRP_KEY IS NULL;

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;
			
			IF @pDebug = 'true'
                SELECT @Proc_Step_Name AS step, tmp.* 
                FROM #TMP_RESULT_COMMENT_GROUP tmp
				LEFT JOIN [dbo].RESULT_COMMENT_GROUP val WITH (NOLOCK) 
					ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
				WHERE 
					val.LAB_TEST_UID IS NULL
					AND val.RESULT_COMMENT_GRP_KEY IS NULL;
			
			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'DELETE LAB_RESULT_COMMENT ';

			IF @pDebug = 'true'
                SELECT @Proc_Step_Name AS step, lrc.* 
                FROM [dbo].LAB_RESULT_COMMENT lrc WITH (NOLOCk)
				INNER JOIN #TMP_LAB_TEST_RESULT ltr 
					ON ltr.lab_test_uid = lrc.lab_test_uid
				LEFT JOIN #TMP_RESULT_COMMENT_GROUP tcg 
					ON tcg.lab_test_uid = lrc.lab_test_uid
				WHERE tcg.lab_test_uid IS NULL;
			
			DELETE lrc
			FROM [dbo].LAB_RESULT_COMMENT lrc 
			INNER JOIN #TMP_LAB_TEST_RESULT ltr 
				ON ltr.lab_test_uid = lrc.lab_test_uid
			LEFT JOIN #TMP_RESULT_COMMENT_GROUP tcg 
				ON tcg.lab_test_uid = lrc.lab_test_uid
			WHERE tcg.lab_test_uid IS NULL;

			--delete keys related to deleted LAB result comments
			DELETE lrck
            FROM [dbo].nrt_lab_result_comment_key lrck
            INNER JOIN #TMP_LAB_TEST_RESULT ltr 
				ON ltr.lab_test_uid = lrck.LAB_RESULT_COMMENT_UID
			LEFT JOIN #TMP_RESULT_COMMENT_GROUP tcg 
				ON tcg.lab_test_uid = lrck.LAB_RESULT_COMMENT_UID
			WHERE tcg.lab_test_uid IS NULL;

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'DELETE RESULT_COMMENT_GROUP ';

			IF @pDebug = 'true'
                SELECT @Proc_Step_Name AS step, rcg.* 
                FROM [dbo].RESULT_COMMENT_GROUP rcg WITH (NOLOCK)
				INNER JOIN #TMP_LAB_TEST_RESULT ltr 
					ON ltr.lab_test_uid = rcg.lab_test_uid
				LEFT JOIN #TMP_RESULT_COMMENT_GROUP tcg 
					ON tcg.lab_test_uid = rcg.lab_test_uid
				WHERE tcg.lab_test_uid IS NULL;

			DELETE rcg
			FROM [dbo].RESULT_COMMENT_GROUP rcg 
			INNER JOIN #TMP_LAB_TEST_RESULT ltr 
				ON ltr.lab_test_uid = rcg.lab_test_uid
			LEFT JOIN #TMP_RESULT_COMMENT_GROUP tcg 
				ON tcg.lab_test_uid = rcg.lab_test_uid
			WHERE tcg.lab_test_uid IS NULL;

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;	

			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;
		--------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'UPDATE LAB_RESULT_COMMENT ';


			UPDATE [dbo].Lab_Result_Comment
			SET [LAB_RESULT_COMMENTS]    = SUBSTRING(tmp.LAB_RESULT_COMMENTS, 1, 2000),
				[RESULT_COMMENT_GRP_KEY] = tmp.RESULT_COMMENT_GRP_KEY,
				[RECORD_STATUS_CD]       = SUBSTRING(tmp.RECORD_STATUS_CD, 1, 8),
				[RDB_LAST_REFRESH_TIME]  = tmp.[RDB_LAST_REFRESH_TIME]
			FROM #TMP_New_Lab_Result_Comment_FINAL tmp
			INNER JOIN [dbo].Lab_Result_Comment val WITH (NOLOCK) 
				ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
				AND val.LAB_RESULT_COMMENT_KEY = tmp.LAB_RESULT_COMMENT_KEY;


			SELECT @ROWCOUNT_NO = @@ROWCOUNT;
			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------------------------------------------

         /*update key for LAB_RESULT_COMMENT*/

		 BEGIN TRANSACTION 

            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'UPDATING [dbo].nrt_lab_result_comment_key table';

			UPDATE lrck 
			SET lrck.[updated_dttm] = GETDATE()
			FROM [dbo].nrt_lab_result_comment_key lrck 
			INNER JOIN #Lab_Result_Comment_E rce
				ON lrck.LAB_RESULT_COMMENT_UID = rce.LAB_TEST_UID;

			SELECT @RowCount_no = @@ROWCOUNT;

            IF @pDebug = 'true'
                SELECT @Proc_Step_Name AS step, lrck.* 
                FROM [dbo].nrt_lab_result_comment_key lrck WITH (NOLOCK)
				INNER JOIN #Lab_Result_Comment_E rce
					ON lrck.LAB_RESULT_COMMENT_UID = rce.LAB_TEST_UID;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

		COMMIT TRANSACTION

		--------------------------------------------------------------------------------------------------------------------------------------------


        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'INSERTING INTO LAB_RESULT_COMMENT ';


			INSERT INTO [dbo].Lab_Result_Comment
			( [LAB_TEST_UID]
			, [LAB_RESULT_COMMENT_KEY]
			, [LAB_RESULT_COMMENTS]
			, [RESULT_COMMENT_GRP_KEY]
			, [RECORD_STATUS_CD]
			, [RDB_LAST_REFRESH_TIME])
			SELECT tmp.LAB_TEST_UID
				, tmp.LAB_RESULT_COMMENT_KEY
				, SUBSTRING(tmp.LAB_RESULT_COMMENTS, 1, 2000)
				, tmp.RESULT_COMMENT_GRP_KEY
				, SUBSTRING(tmp.RECORD_STATUS_CD, 1, 8)
				, tmp.[RDB_LAST_REFRESH_TIME]
			FROM #TMP_New_Lab_Result_Comment_FINAL tmp
			LEFT JOIN [dbo].Lab_Result_Comment val WITH (NOLOCK) 
				ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
			WHERE 
				val.LAB_TEST_UID IS NULL
				AND val.LAB_RESULT_COMMENT_KEY IS NULL;

			DELETE FROM #TMP_Lab_Test_Result WHERE lab_test_key IS NULL;

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------------------------------------------


        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'DELETE INCOMING RECORDS PRE-EXISTING LAB_TEST_RESULT';

			/* CNDE-2510: Bug fix to handle multiple Investigation and Ordering providers to Lab Test inserts.
			* This join will be revisited as more usage is reviewed.
			* To maintain history, Investigation_key=1, the record is not being deleted.
			* CNDE-2733: Remove update to insert current associations to LAB_TEST_UID and LAB_TEST_KEY associated.  */

			DELETE FROM [dbo].LAB_TEST_RESULT WHERE LAB_TEST_UID IN (SELECT DISTINCT LAB_TEST_UID FROM #TMP_LAB_TEST_RESULT);


			SELECT @ROWCOUNT_NO = @@ROWCOUNT;
			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

		----------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'INSERTING INTO LAB_TEST_RESULT';

			IF @pDebug = 'true'
				SELECT @PROC_STEP_NAME
					, tmp.[LAB_TEST_KEY]
					, tmp.[LAB_TEST_UID]
					, tmp.[RESULT_COMMENT_GRP_KEY]
					, tmp.[TEST_RESULT_GRP_KEY]
					, tmp.[PERFORMING_LAB_KEY]
					, COALESCE(tmp.[PATIENT_KEY], '')
					, COALESCE(tmp.[COPY_TO_PROVIDER_KEY], '')
					, COALESCE(tmp.[LAB_TEST_TECHNICIAN_KEY], '')
					, COALESCE(tmp.[SPECIMEN_COLLECTOR_KEY], '')
					, COALESCE(tmp.[ORDERING_ORG_KEY], '')
					, COALESCE(tmp.[REPORTING_LAB_KEY], '')
					, COALESCE(tmp.[CONDITION_KEY], '')
					, COALESCE(tmp.[LAB_RPT_DT_KEY], '')
					, COALESCE(tmp.[MORB_RPT_KEY], '')
					, COALESCE(tmp.[INVESTIGATION_KEY], '')
					, COALESCE(tmp.[LDF_GROUP_KEY], '')
					, COALESCE(tmp.[ORDERING_PROVIDER_KEY], '')
					, SUBSTRING(tmp.RECORD_STATUS_CD, 1, 8)
					, GETDATE() AS [RDB_LAST_REFRESH_TIME]
				FROM #TMP_LAB_TEST_RESULT tmp
				LEFT JOIN [dbo].LAB_TEST_RESULT val WITH (NOLOCK)
					ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
					AND val.LAB_TEST_KEY = tmp.LAB_TEST_KEY
					AND val.INVESTIGATION_KEY = tmp.INVESTIGATION_KEY
					AND val.ORDERING_PROVIDER_KEY = tmp.ORDERING_PROVIDER_KEY
				WHERE (val.LAB_TEST_UID IS NULL AND val.LAB_TEST_KEY IS NULL);

			/*CNDE-2510: Bug fix to handle multiple Investigation and Ordering providers to Lab Test inserts.
			* This join will be revisited as more usage is reviewed.*/


			INSERT INTO [dbo].LAB_TEST_RESULT
			( [LAB_TEST_KEY]
			, [LAB_TEST_UID]
			, [RESULT_COMMENT_GRP_KEY]
			, [TEST_RESULT_GRP_KEY]
			, [PERFORMING_LAB_KEY]
			, [PATIENT_KEY]
			, [COPY_TO_PROVIDER_KEY]
			, [LAB_TEST_TECHNICIAN_KEY]
			, [SPECIMEN_COLLECTOR_KEY]
			, [ORDERING_ORG_KEY]
			, [REPORTING_LAB_KEY]
			, [CONDITION_KEY]
			, [LAB_RPT_DT_KEY]
			, [MORB_RPT_KEY]
			, [INVESTIGATION_KEY]
			, [LDF_GROUP_KEY]
			, [ORDERING_PROVIDER_KEY]
			, [RECORD_STATUS_CD]
			, [RDB_LAST_REFRESH_TIME])
			SELECT tmp.[LAB_TEST_KEY]
				, tmp.[LAB_TEST_UID]
				, tmp.[RESULT_COMMENT_GRP_KEY]
				, tmp.[TEST_RESULT_GRP_KEY]
				, tmp.[PERFORMING_LAB_KEY]
				, COALESCE(tmp.[PATIENT_KEY], '')
				, COALESCE(tmp.[COPY_TO_PROVIDER_KEY], '')
				, COALESCE(tmp.[LAB_TEST_TECHNICIAN_KEY], '')
				, COALESCE(tmp.[SPECIMEN_COLLECTOR_KEY], '')
				, COALESCE(tmp.[ORDERING_ORG_KEY], '')
				, COALESCE(tmp.[REPORTING_LAB_KEY], '')
				, COALESCE(tmp.[CONDITION_KEY], '')
				, COALESCE(tmp.[LAB_RPT_DT_KEY], '')
				, COALESCE(tmp.[MORB_RPT_KEY], '')
				, COALESCE(tmp.[INVESTIGATION_KEY], '')
				, COALESCE(tmp.[LDF_GROUP_KEY], '')
				, COALESCE(tmp.[ORDERING_PROVIDER_KEY], '')
				, SUBSTRING(tmp.RECORD_STATUS_CD, 1, 8)
				, GETDATE() AS [RDB_LAST_REFRESH_TIME]
			FROM #TMP_LAB_TEST_RESULT tmp
			LEFT JOIN [dbo].LAB_TEST_RESULT val WITH (NOLOCK)
				ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
				AND val.LAB_TEST_KEY = tmp.LAB_TEST_KEY
				AND val.INVESTIGATION_KEY = tmp.INVESTIGATION_KEY
				AND val.ORDERING_PROVIDER_KEY = tmp.ORDERING_PROVIDER_KEY
			WHERE (val.LAB_TEST_UID IS NULL
				AND val.LAB_TEST_KEY IS NULL)
			OR (val.INVESTIGATION_KEY IS NULL
				OR val.ORDERING_PROVIDER_KEY IS NULL);

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;
			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'Update Inactive LAB_TEST_RESULT Records';

			/* Update record status for Inactive Orders and associated observations. */
			SELECT ltr.LAB_TEST_UID
			INTO #Inactive_Obs
			FROM [dbo].LAB_TEST lt WITH (NOLOCK)
			INNER JOIN [dbo].LAB_TEST_RESULT ltr WITH (NOLOCK) 
				ON ltr.LAB_TEST_UID = lt.LAB_TEST_UID
			WHERE ROOT_ORDERED_TEST_PNTR IN
				(SELECT ROOT_ORDERED_TEST_PNTR
				FROM [dbo].LAB_TEST ltr WITH (NOLOCK)
				WHERE LAB_TEST_TYPE = 'Order'
					AND RECORD_STATUS_CD = 'INACTIVE')
			AND ltr.RECORD_STATUS_CD <> 'INACTIVE';

			UPDATE lrc
			SET RECORD_STATUS_CD = 'INACTIVE'
			FROM [dbo].LAB_RESULT_COMMENT lrc
			INNER JOIN [dbo].RESULT_COMMENT_GROUP g WITH (NOLOCK)
				ON lrc.RESULT_COMMENT_GRP_KEY = g.RESULT_COMMENT_GRP_KEY
			INNER JOIN [dbo].LAB_TEST_RESULT R WITH (NOLOCK)
				ON R.RESULT_COMMENT_GRP_KEY = g.RESULT_COMMENT_GRP_KEY
			INNER JOIN #INACTIVE_OBS io 
				ON io.LAB_TEST_UID = lrc.LAB_TEST_UID
				AND lrc.RECORD_STATUS_CD <> 'INACTIVE';

			UPDATE lrv
			SET RECORD_STATUS_CD = 'INACTIVE'
			FROM [dbo].LAB_RESULT_VAL lrv
			INNER JOIN [dbo].TEST_RESULT_GROUPING R WITH (NOLOCK)
				ON R.TEST_RESULT_GRP_KEY = lrv.TEST_RESULT_GRP_KEY
			INNER JOIN [dbo].LAB_TEST_RESULT ltr WITH (NOLOCK)
				ON R.TEST_RESULT_GRP_KEY = ltr.TEST_RESULT_GRP_KEY
			INNER JOIN #INACTIVE_OBS io 
				ON io.LAB_TEST_UID = lrv.LAB_TEST_UID
				AND lrv.RECORD_STATUS_CD <> 'INACTIVE';

			UPDATE lt
			SET RECORD_STATUS_CD = 'INACTIVE'
			FROM [dbo].LAB_TEST_RESULT lt
			INNER JOIN #Inactive_Obs io 
				ON io.LAB_TEST_UID = lt.LAB_TEST_UID
				AND lt.RECORD_STATUS_CD <> 'INACTIVE';

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;
			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------------------------------------------


        BEGIN TRANSACTION;

			SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET @PROC_STEP_NAME = 'DELETE FROM LAB_TEST_RESULT';

			/* Remove lab_test_uids from LAB_TEST_RESULT that no longer exist in LAB_TEST. */
			SELECT DISTINCT ltr.LAB_TEST_UID
			INTO #Removed_Obs
			FROM [dbo].LAB_TEST_RESULT ltr WITH (NOLOCK)
			EXCEPT
			SELECT lt.LAB_TEST_UID
			FROM [dbo].LAB_TEST lt WITH (NOLOCK);

			DELETE FROM [dbo].LAB_RESULT_COMMENT WHERE LAB_TEST_UID IN (SELECT LAB_TEST_UID FROM #Removed_Obs);
			DELETE FROM [dbo].RESULT_COMMENT_GROUP WHERE LAB_TEST_UID IN (SELECT LAB_TEST_UID FROM #Removed_Obs);
			DELETE FROM [dbo].LAB_RESULT_VAL WHERE LAB_TEST_UID IN (SELECT LAB_TEST_UID FROM #Removed_Obs);
			DELETE FROM [dbo].TEST_RESULT_GROUPING WHERE LAB_TEST_UID IN (SELECT LAB_TEST_UID FROM #Removed_Obs);
			DELETE FROM [dbo].LAB_TEST_RESULT WHERE LAB_TEST_UID IN (SELECT LAB_TEST_UID FROM #Removed_Obs);

			-- Delete keys related to deleted rows from dbo.LAB_RESULT_COMMENT
			DELETE lrck
            FROM [dbo].nrt_lab_result_comment_key lrck
            LEFT JOIN dbo.LAB_RESULT_COMMENT lrc 
				ON lrc.LAB_RESULT_COMMENT_KEY = lrck.LAB_RESULT_COMMENT_KEY
			WHERE 
				lrc.LAB_RESULT_COMMENT_KEY IS NULL 
				AND lrck.LAB_RESULT_COMMENT_key > 1;

			-- Delete keys related to deleted rows from dbo.TEST_RESULT_GROUPING
			DELETE ltrcgk
            FROM [dbo].nrt_lab_test_result_group_key ltrcgk
            LEFT JOIN [dbo].TEST_RESULT_GROUPING trg
				ON trg.TEST_RESULT_GRP_KEY = ltrcgk.TEST_RESULT_GRP_KEY
			WHERE 
				ltrcgk.TEST_RESULT_GRP_KEY IS NULL
				AND ltrcgk.TEST_RESULT_GRP_KEY > 1;

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF @pDebug = 'true'
                SELECT @Proc_Step_Name AS step, * 
                FROM #Removed_Obs;

			INSERT INTO [DBO].[JOB_FLOW_LOG]
			(BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
			VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [row_count])
        VALUES ( @batch_id,
                 @Dataflow_Name
               , @Package_Name
               , 'COMPLETE'
               , @Proc_Step_no
               , @Proc_Step_name
               , @RowCount_no);


        --------------------------------------------------------------------------------------------------------------------------------------------


        /* Notes: Multiple lab report datapoints are returned to the postprocessing service.
         * Case 1: Return distinct Investigations associated to labs.
         * + This excludes covid related datamarts that have a different set of requirements.
         * */

        SELECT inv.CASE_UID         AS public_health_case_uid,
               pat.PATIENT_UID      AS patient_uid,
               null                 AS observation_uid,
               dtm.Datamart         AS datamart,
               c.CONDITION_CD       AS condition_cd,
               dtm.Stored_Procedure AS stored_procedure,
               null                 AS investigation_form_cd
        FROM #TMP_D_LAB_TEST_N tmp
                 INNER JOIN dbo.LAB_TEST_RESULT ltr WITH (NOLOCK) ON ltr.LAB_TEST_UID = tmp.lab_test_uid
                 JOIN dbo.INVESTIGATION inv WITH (NOLOCK) ON inv.INVESTIGATION_KEY = ltr.INVESTIGATION_KEY
                 LEFT JOIN dbo.CASE_COUNT cc WITH (NOLOCK) ON cc.INVESTIGATION_KEY = inv.INVESTIGATION_KEY
                 LEFT JOIN dbo.condition c WITH (NOLOCK) ON c.CONDITION_KEY = cc.CONDITION_KEY
                 LEFT JOIN dbo.D_PATIENT pat WITH (NOLOCK) ON pat.PATIENT_KEY = ltr.PATIENT_KEY
                 JOIN dbo.nrt_datamart_metadata dtm WITH (NOLOCK) ON dtm.condition_cd = c.CONDITION_CD
        WHERE ltr.INVESTIGATION_KEY <> 1
          AND dtm.Datamart NOT IN ('Covid_Case_Datamart', 'Covid_Contact_Datamart',
                                   'Covid_Vaccination_Datamart', 'Covid_Lab_Datamart')
        /* Case 2: Return Investigations for case_lab_datamart update.*/
        UNION
        SELECT DISTINCT inv.CASE_UID         AS public_health_case_uid,
                        pat.PATIENT_UID      AS patient_uid,
                        null                 AS observation_uid,
                        dtm.Datamart         AS datamart,
                        null                 AS condition_cd,
                        dtm.Stored_Procedure AS stored_procedure,
                        null                 AS investigation_form_cd
        FROM #TMP_D_LAB_TEST_N tmp
                 INNER JOIN dbo.LAB_TEST_RESULT ltr WITH (NOLOCK) ON ltr.LAB_TEST_UID = tmp.lab_test_uid
                 JOIN dbo.INVESTIGATION inv WITH (NOLOCK) ON inv.INVESTIGATION_KEY = ltr.INVESTIGATION_KEY
                 LEFT JOIN dbo.CASE_COUNT cc WITH (NOLOCK) ON cc.INVESTIGATION_KEY = inv.INVESTIGATION_KEY
                 LEFT JOIN dbo.condition c WITH (NOLOCK) ON c.CONDITION_KEY = cc.CONDITION_KEY
                 LEFT JOIN dbo.D_PATIENT pat WITH (NOLOCK) ON pat.PATIENT_KEY = ltr.PATIENT_KEY
                 JOIN dbo.nrt_datamart_metadata dtm WITH (NOLOCK) ON dtm.Datamart = 'Case_Lab_Datamart'
        WHERE ltr.INVESTIGATION_KEY <> 1
        /*Case 3: Return distinct Investigations for covid case and covid lab datamart postprocessing.
         * + Covid vaccination and contact are excluded as they can be independently associated to an investigation. */
        UNION
        SELECT DISTINCT inv.CASE_UID         AS public_health_case_uid,
                        pat.PATIENT_UID      AS patient_uid,
                        tmp.LAB_TEST_UID     AS observation_uid,
                        dtm.Datamart         AS datamart,
                        dtm.condition_cd     AS condition_cd,
                        dtm.Stored_Procedure AS stored_procedure,
                        null                 AS investigation_form_cd
        FROM #TMP_D_LAB_TEST_N tmp
                 INNER JOIN dbo.LAB_TEST_RESULT ltr WITH (NOLOCK) ON ltr.LAB_TEST_UID = tmp.lab_test_uid
                 INNER JOIN dbo.INVESTIGATION inv WITH (NOLOCK) ON inv.INVESTIGATION_KEY = ltr.INVESTIGATION_KEY
                 LEFT JOIN dbo.CASE_COUNT cc WITH (NOLOCK) ON cc.INVESTIGATION_KEY = inv.INVESTIGATION_KEY
                 LEFT JOIN dbo.condition c WITH (NOLOCK) ON c.CONDITION_KEY = cc.CONDITION_KEY
                 LEFT JOIN dbo.D_PATIENT pat WITH (NOLOCK) ON pat.PATIENT_KEY = ltr.PATIENT_KEY
                 LEFT JOIN dbo.nrt_datamart_metadata dtm WITH (NOLOCK) ON dtm.condition_cd = c.CONDITION_CD
        WHERE dtm.Datamart IN ('Covid_Case_Datamart', 'Covid_Lab_Datamart')
          AND ltr.INVESTIGATION_KEY <> 1
        /*CASE 4: Return covid labs that are unassociated to investigations.
         * + The phc_uid and observation_uid are the same and reconciled by the post-processing service.
         * + Sending the root_ordered_test_pntr/Order associated to the loinc-cds for Covid_Lab_Datamart.*/
        UNION
        SELECT DISTINCT tmp.root_ordered_test_pntr AS public_health_case_uid,
                        pat.PATIENT_UID            AS patient_uid,
                        tmp.root_ordered_test_pntr AS observation_uid,
                        dtm.Datamart               AS datamart,
                        dtm.condition_cd           AS condition_cd,
                        dtm.Stored_Procedure   AS stored_procedure,
                        null                       AS investigation_form_cd
        FROM #TMP_D_LAB_TEST_N tmp
                 INNER JOIN dbo.LAB_TEST_RESULT ltr WITH (NOLOCK) ON ltr.LAB_TEST_UID = tmp.lab_test_uid
                 LEFT JOIN dbo.D_PATIENT pat WITH (NOLOCK) ON pat.PATIENT_KEY = ltr.PATIENT_KEY
                 LEFT JOIN dbo.nrt_srte_Loinc_condition lc WITH (NOLOCK) ON lc.loinc_cd = tmp.LAB_TEST_CD
                 LEFT JOIN dbo.nrt_datamart_metadata dtm WITH (NOLOCK) ON dtm.Datamart = 'Covid_Lab_Datamart'
        WHERE lc.condition_cd = dtm.condition_cd;


    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;


        -- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) +
            CHAR(10) + -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();


        INSERT INTO [dbo].[job_flow_log] ( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count])
        VALUES ( @batch_id, @Dataflow_Name, @Package_Name, 'ERROR', @Proc_Step_no, @Proc_Step_name, @FullErrorMessage, 0);


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