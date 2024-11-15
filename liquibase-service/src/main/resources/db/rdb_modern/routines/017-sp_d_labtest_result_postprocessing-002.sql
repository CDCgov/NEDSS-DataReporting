CREATE OR ALTER PROCEDURE [dbo].[sp_d_labtest_result_postprocessing]
(@pLabResultList nvarchar(max)
, @pDebug bit = 'false')

AS

BEGIN
    /*
     * [Description]
     * This stored procedure processes event based updates to LAB_TEST_RESULT and associated tables.
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
    SET @batch_id = CAST((format(GETDATE(), 'yyMMddHHmmss')) AS bigint);
    DECLARE @RowCount_no INT ;
    DECLARE @Proc_Step_no FLOAT = 0 ;
    DECLARE @Proc_Step_Name VARCHAR(200) = '' ;

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';

        BEGIN TRANSACTION;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_lab_test_resultInit ';


        IF OBJECT_ID('#TMP_lab_test_resultInit', 'U') IS NOT NULL
            DROP TABLE #TMP_lab_test_resultInit ;


        --List of new Observations for Lab Test Result
        SELECT lab_test_key,
               root_ordered_test_pntr,
               lab_test_uid,
               record_status_cd,
               lab_rpt_created_dt,
               lab_test_type, -- for TMP_Result_And_R_Result
               elr_ind -- for TMP_Result_And_R_Result
        INTO #TMP_D_LAB_TEST_N
        FROM dbo.LAB_TEST with (nolock)
        WHERE lab_test_uid IN (SELECT value FROM string_split(@pLabResultList, ','))


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_D_LAB_TEST_N',* FROM #TMP_D_LAB_TEST_N;


        --Get morbidity reports associated to lab
        SELECT
            tst.lab_test_key,
            tst.root_ordered_test_pntr,
            tst.lab_test_uid,
            tst.record_status_cd,
            tst.Root_Ordered_Test_Pntr AS Root_Ordered_Test_Pntr2 ,
            tst.lab_rpt_created_dt,
            COALESCE(morb.morb_rpt_key,1) 'MORB_RPT_KEY',
            morb_event.PATIENT_KEY AS morb_patient_key,
            morb_event.Condition_Key AS morb_Condition_Key,
            morb_event.Investigation_Key AS morb_Investigation_Key,
            morb_event.MORB_RPT_SRC_ORG_KEY AS MORB_RPT_SRC_ORG_KEY
        INTO #TMP_lab_test_resultInit
        FROM  #TMP_D_LAB_TEST_N AS tst
                  /* Morb report */
                  LEFT JOIN dbo.nrt_observation no2 with (nolock) ON tst.lab_test_uid = no2.observation_uid
                  LEFT JOIN dbo.Morbidity_Report as morb with (nolock)
                            ON no2.report_observation_uid = morb.morb_rpt_uid
                  LEFT JOIN dbo.Morbidity_report_event morb_event with (nolock) on
            morb_event.morb_rpt_key= morb.morb_rpt_key;

        IF @pDebug = 'true' SELECT 'DEBUG: TMP_lab_test_resultInit',* FROM #TMP_lab_test_resultInit;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Test_Result1 ';


        IF OBJECT_ID('#TMP_Lab_Test_Result1', 'U') IS NOT NULL
            DROP TABLE  #TMP_Lab_Test_Result1;


        SELECT
            tst.lab_test_key,
            tst.root_ordered_test_pntr,
            tst.lab_test_uid,
            tst.record_status_cd,
            tst.Root_Ordered_Test_Pntr AS Root_Ordered_Test_Pntr2,
            tst.lab_rpt_created_dt,
            morb_rpt_key,
            tst.morb_patient_key,
            tst.morb_Condition_Key,
            tst.morb_Investigation_Key,
            tst.MORB_RPT_SRC_ORG_KEY,
            /*per1.person_key AS Transcriptionist_Key,*/
            /*per2.person_key AS Assistant_Interpreter_Key,*/
            /*per3.person_key AS Result_Interpreter_Key,*/
            COALESCE(per4.provider_key,1) AS Specimen_Collector_Key,
            COALESCE(per5.provider_key,1) AS Copy_To_Provider_Key,
            COALESCE(per6.provider_key,1) AS Lab_Test_Technician_key,
            COALESCE(org.Organization_key,1)		'REPORTING_LAB_KEY'  , -- AS Reporting_Lab_Key,
            COALESCE(prv.provider_key,1) 'ORDERING_PROVIDER_KEY'  , -- AS Ordering_provider_key,
            COALESCE(org2.Organization_key,1)	'ORDERING_ORG_KEY'  , -- AS Ordering_org_key,
            COALESCE(con.condition_key,1) 'CONDITION_KEY'  , -- AS condition_key,
            COALESCE(dat.Date_key,1) 						AS LAB_RPT_DT_KEY,

            COALESCE(inv.Investigation_key,1) 	'INVESTIGATION_KEY'  , -- AS Investigation_key,
            COALESCE(ldf_g.ldf_group_key,1)			AS LDF_GROUP_KEY,
            tst.record_status_cd AS record_status_cd2,
            cast ( NULL AS  bigint) RESULT_COMMENT_GRP_KEY
        INTO #TMP_Lab_Test_Result1
        FROM #TMP_lab_test_resultInit AS tst with (nolock)
                 LEFT JOIN dbo.nrt_observation AS no2 with (nolock) ON tst.lab_test_uid = no2.observation_uid
                 LEFT JOIN dbo.nrt_observation AS no3 with (nolock) ON tst.Root_Ordered_Test_Pntr = no3.observation_uid
            /*get specimen collector: Associated to Root Order*/
                 LEFT JOIN dbo.d_provider AS per4 with (nolock)
                           ON no3.specimen_collector_id = per4.provider_uid
            /*get copy_to_provider key: Associated to Root Order*/
                 LEFT JOIN dbo.d_provider AS per5 with (nolock)
                           ON no3.specimen_collector_id = per5.provider_uid
            /*get lab_test_technician: Associated to Root Order*/
                 LEFT JOIN dbo.d_provider AS per6 with (nolock)
                           ON no3.lab_test_technician_id = per6.provider_uid
            /* Ordering Provider */
                 LEFT JOIN	dbo.d_provider 	AS prv with (nolock)
                              ON no2.ordering_person_id = prv.provider_uid
            /* Reporting_Lab*/
                 LEFT JOIN dbo.d_Organization	AS org with (nolock)
                           ON no2.author_organization_id = org.Organization_uid
            /* Ordering Facility */
                 LEFT JOIN dbo.d_Organization	AS org2 with (nolock)
                           ON no2.ordering_organization_id = org2.Organization_uid

            /* Condition it's just program area */

            /*IF we add a program area to the Lab_Report Dimension we probably don't
            even need a condition dimension.  Even though it's OK with the Dimension Modeling
            principle for adding a prog_area_cd row to the condition, it sure will cause
            some confusion among users.  There's no "disease" ON the input.
            */
                 LEFT JOIN dbo.Condition	AS con with (nolock)
                           ON	no2.prog_area_cd  = con.program_area_cd
                               AND con.condition_cd IS NULL
            /*LDF_GRP_KEY*/
            --LEFT JOIN ldf_group AS ldf_g 	ON tst.Lab_test_UID = ldf_g.business_object_uid --VS
                 LEFT JOIN dbo.ldf_group AS ldf_g  with (nolock)	ON tst.Lab_test_UID = ldf_g.ldf_group_key

            /* Lab_Rpt_Dt */ --VS	LEFT JOIN rdb_datetable 		as dat
                 LEFT JOIN dbo.rdb_date AS dat  with (nolock)	ON  DATEADD(d,0,DATEDIFF(d,0,[lab_rpt_created_dt])) = dat.DATE_MM_DD_YYYY
            /* PHC: Using NRT nrt_investigation_observation which captures observation-investigation mapping  */
                 LEFT JOIN
             ( select distinct public_health_case_uid, observation_id
               from
                   dbo.nrt_investigation_observation with (nolock)
             ) ninv ON ninv.observation_id = tst.lab_test_uid
                 LEFT JOIN dbo.investigation AS inv with (nolock) ON ninv.public_health_case_uid = inv.case_uid;


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Test_Result1',* FROM #TMP_Lab_Test_Result1;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Result_And_R_Result ';


        IF OBJECT_ID('#TMP_Result_And_R_Result', 'U') IS NOT NULL
            DROP TABLE  #TMP_Result_And_R_Result;


        SELECT *
        INTO #TMP_Result_And_R_Result
        FROM #TMP_D_LAB_TEST_N --dbo.LAB_TEST
        WHERE
            (Lab_Test_Type = 'Result' OR  Lab_Test_Type IN ('R_Result', 'I_Result', 'Order_rslt'));


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Result_And_R_Result',* FROM #TMP_Result_And_R_Result;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Result_Comment ';

        IF OBJECT_ID('#TMP_Lab_Result_Comment', 'U') IS NOT NULL
            DROP TABLE #TMP_Lab_Result_Comment ;

        /*Notes: Inner Join specified*/
        SELECT
            lab104.lab_test_uid,
            REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ')	'LAB_RESULT_COMMENTS'  , -- asLab_Result_Comments,
            ovt.ovt_seq	'LAB_RESULT_TXT_SEQ'  , -- AS Lab_Result_Txt_Seq,
            lab104.record_status_cd
        INTO #TMP_Lab_Result_Comment
        FROM
            #TMP_Result_And_R_Result		AS lab104
                INNER JOIN dbo.nrt_observation_txt AS ovt with (nolock) ON ovt.observation_uid =  lab104.lab_test_uid
        WHERE 	ovt.ovt_value_txt IS NOT NULL
          AND ovt.ovt_txt_type_cd = 'N'
          AND ovt.ovt_seq <>  0;


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Result_Comment',* FROM #TMP_Lab_Result_Comment;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_New_Lab_Result_Comment ';

        IF OBJECT_ID('#TMP_New_Lab_Result_Comment', 'U') IS NOT NULL
            DROP TABLE #TMP_New_Lab_Result_Comment;

        SELECT *,
               cast( NULL AS varchar(2000)) AS v_lab_result_val_comments
        INTO #TMP_New_Lab_Result_Comment
        FROM #TMP_Lab_Result_Comment;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_New_Lab_Result_Comment_grouped ';


        create index idx_TMP_New_Lab_Result_Comment_uid ON  #TMP_New_Lab_Result_Comment (lab_test_uid);


        IF OBJECT_ID('#TMP_New_Lab_Result_Comment_grouped', 'U') IS NOT NULL
            DROP TABLE  #TMP_New_Lab_Result_Comment_grouped;


        SELECT DISTINCT LRV.lab_test_uid,
                        SUBSTRING(
                                (
                                    SELECT ' '+ST1.lab_result_comments  AS [text()]
                                    FROM #TMP_New_Lab_Result_Comment ST1
                                    WHERE ST1.lab_test_uid = LRV.lab_test_uid
                                    ORDER BY ST1.lab_test_uid,ST1.lab_result_txt_seq
                                    FOR XML PATH ('')
                                ), 2, 2000) v_lab_result_val_txt
        INTO #TMP_New_Lab_Result_Comment_grouped
        FROM #TMP_New_Lab_Result_Comment LRV;


        UPDATE #TMP_New_Lab_Result_Comment
        SET lab_result_comments = ( SELECT CASE WHEN v_lab_result_val_txt = '#x20;' THEN NULL
                                                ELSE v_lab_result_val_txt END AS v_lab_result_val_txt
                                    FROM  #TMP_New_Lab_Result_Comment_grouped tnl
                                    WHERE tnl.lab_test_uid = #TMP_New_Lab_Result_Comment.lab_test_uid);


        /*
        UPDATE #TMP_New_Lab_Result_Comment
        SET [LAB_RESULT_COMMENTS] = NULL
        WHERE [LAB_RESULT_COMMENTS] = '#x20;';
        */


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_New_Lab_Result_Comment_grouped', * FROM #TMP_New_Lab_Result_Comment_grouped;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_New_Lab_Result_Comment_FINAL ';

        IF OBJECT_ID('#TMP_New_Lab_Result_Comment_FINAL', 'U') IS NOT NULL
            DROP TABLE  #TMP_New_Lab_Result_Comment_FINAL;

        CREATE TABLE #TMP_New_Lab_Result_Comment_FINAL(
                                                          [LAB_TEST_UID] [bigint] NULL,
                                                          [LAB_RESULT_COMMENT_KEY] [bigint]  NULL,
                                                          [LAB_RESULT_COMMENTS] [varchar](2000) NULL,
                                                          [RESULT_COMMENT_GRP_KEY] [bigint]  NULL,
                                                          [RECORD_STATUS_CD] [varchar](8)  NULL,
                                                          [RDB_LAST_REFRESH_TIME] [datetime] NULL
        );


        INSERT INTO #TMP_New_Lab_Result_Comment_FINAL
        SELECT distinct [lab_test_uid]
                      ,NULL
                      ,CASE WHEN [LAB_RESULT_COMMENTS] LIKE  '%.&#x20;%' THEN REPLACE([LAB_RESULT_COMMENTS],'&#x20;',' ')
                            ELSE  [LAB_RESULT_COMMENTS]
            END AS LAB_RESULT_COMMENTS
                      ,NULL
                      ,CASE WHEN record_status_cd = 'LOG_DEL' THEN 'INACTIVE'
                            WHEN record_status_cd IN ('', 'UNPROCESSED', 'PROCESSED') THEN 'ACTIVE'
                            ELSE 'ACTIVE'
            END AS record_status_cd
                      ,GETDATE()
        FROM #TMP_New_Lab_Result_Comment;


        /*Key generation*/

        UPDATE tmp_val
        SET tmp_val.Lab_Result_Comment_Key = lrc.Lab_Result_Comment_Key
        FROM #TMP_New_Lab_Result_Comment_FINAL tmp_val
                 INNER JOIN Lab_Result_Comment lrc ON lrc.lab_test_uid = tmp_val.lab_test_uid;

        CREATE TABLE #tmp_id_assignment_comment(
                                                   Lab_Result_Comment_Key_id [int] IDENTITY(1,1) NOT NULL,
                                                   [lab_test_uid] [bigint] NOT NULL
        )
        INSERT INTO #tmp_id_assignment_comment
        SELECT rslt.lab_test_uid
        FROM #TMP_New_Lab_Result_Comment_FINAL rslt
                 LEFT JOIN Lab_Result_Comment lrc ON lrc.lab_test_uid = rslt.lab_test_uid
        WHERE lrc.lab_test_uid IS NULL;


        UPDATE tmp_val
        SET tmp_val.LAB_RESULT_COMMENT_KEY =
                Lab_Result_Comment_Key_id + COALESCE((SELECT MAX(Lab_Result_Comment_Key) FROM Lab_Result_Comment),1)
        FROM #TMP_New_Lab_Result_Comment_FINAL tmp_val
                 LEFT JOIN #tmp_id_assignment_comment id ON tmp_val.lab_test_uid = id.lab_test_uid
        WHERE tmp_val.Lab_Result_Comment_Key IS NULL;


        /*
 		UPDATE #TMP_New_Lab_Result_Comment_FINAL
        SET [LAB_RESULT_COMMENT_KEY]= Lab_Result_Comment_Key_id
            + COALESCE((SELECT MAX(Lab_Result_Comment_Key) FROM Lab_Result_Comment),1);

                */

        UPDATE #TMP_New_Lab_Result_Comment_FINAL
        SET Result_Comment_Grp_Key = [LAB_RESULT_COMMENT_KEY];


        UPDATE #TMP_New_Lab_Result_Comment_FINAL
        SET [LAB_RESULT_COMMENTS] = (REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([LAB_RESULT_COMMENTS],
                                                                                             '&#x09;', CHAR(9)),
                                                                                     '&#x0A;', CHAR(10)),
                                                                             '&#x0D;', CHAR(13)),
                                                                     '&#x20;', CHAR(32)),
                                                             '&amp;', CHAR(38)),
                                                     '&lt;', CHAR(60)),
                                             '&gt;', CHAR(62)));




        IF @pDebug = 'true' SELECT 'DEBUG: TMP_New_Lab_Result_Comment', * FROM #TMP_New_Lab_Result_Comment;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Result_Comment_Group ';

        IF OBJECT_ID('#TMP_Result_Comment_Group', 'U') IS NOT NULL
            DROP TABLE  #TMP_Result_Comment_Group;


        SELECT
            DISTINCT rcg.Lab_Result_Comment_Key AS [RESULT_COMMENT_GRP_KEY]
                   , rcg.[LAB_TEST_UID]
        INTO #tmp_Result_Comment_Group
        FROM  #TMP_New_Lab_Result_Comment_FINAL  rcg
        --WHERE  rcg.Lab_Result_Comment_Key <> 1 AND rcg.Lab_Result_Comment_Key IS not NULL
        ORDER BY rcg.Lab_Result_Comment_Key;


        IF NOT EXISTS (SELECT * FROM Result_Comment_Group WHERE [RESULT_COMMENT_GRP_KEY]=1)
            INSERT INTO #tmp_Result_Comment_Group values ( 1,NULL);

        IF @pDebug = 'true' SELECT 'DEBUG: tmp_Result_Comment_Group',* FROM #tmp_Result_Comment_Group;


        UPDATE #TMP_lab_test_result1
        SET [RESULT_COMMENT_GRP_KEY] = ( SELECT [RESULT_COMMENT_GRP_KEY]
                                         FROM #tmp_Result_Comment_Group trcg
                                         WHERE trcg.lab_test_uid = #tmp_lab_test_result1.lab_test_uid);


        UPDATE #TMP_lab_test_result1
        SET [RESULT_COMMENT_GRP_KEY] = 1
        WHERE [RESULT_COMMENT_GRP_KEY] IS NULL;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        /*-------------------------------------------------------

		Lab_Result_Val Dimension
		Test_Result_Grouping Dimension

		---------------------------------------------------------*/


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Result_Val ';

        IF OBJECT_ID('#TMP_Lab_Result_Val', 'U') IS NOT NULL
            DROP TABLE   #TMP_Lab_Result_Val;


        CREATE TABLE #TMP_LAB_RESULT_VAL(
                                            [lab_test_uid] [bigint] NULL,
                                            [LAB_RESULT_TXT_VAL] [varchar](8000) NULL,
                                            [LAB_RESULT_TXT_SEQ] [smallint] NULL,
                                            [COMPARATOR_CD_1] [varchar](10) NULL,
                                            [NUMERIC_VALUE_1] [numeric](15, 5) NULL,
                                            [separator_cd] [varchar](10) NULL,
                                            [NUMERIC_VALUE_2] [numeric](15, 5) NULL,
                                            [Result_Units] [varchar](20) NULL,
                                            [REF_RANGE_FRM] [varchar](20) NULL,
                                            [REF_RANGE_TO] [varchar](20) NULL,
                                            [TEST_RESULT_VAL_CD] [varchar](20) NULL,
                                            [TEST_RESULT_VAL_CD_DESC] [varchar](300) NULL,
                                            [TEST_RESULT_VAL_CD_SYS_CD] [varchar](300) NULL,
                                            [TEST_RESULT_VAL_CD_SYS_NM] [varchar](100) NULL,
                                            [ALT_RESULT_VAL_CD] [varchar](50) NULL,
                                            [ALT_RESULT_VAL_CD_DESC] [varchar](100) NULL,
                                            [ALT_RESULT_VAL_CD_SYS_CD] [varchar](300) NULL,
                                            [ALT_RESULT_VAL_CD_SYSTEM_NM] [varchar](100) NULL,
                                            [FROM_TIME] [datetime] NULL,
                                            [TO_TIME] [datetime] NULL,
                                            [record_status_cd] [varchar](8) NOT NULL,
                                            test_result_grp_key [bigint]  NULL,
                                            Numeric_Result varchar(50),
                                            Test_Result_Val_Key [bigint]  NULL,
                                            lab_result_txt_val1 varchar(2000)
        ) ON [PRIMARY];

        INSERT INTO #TMP_Lab_Result_Val
        SELECT
            rslt.lab_test_uid,
            NULLIF(trim(REPLACE(REPLACE(otxt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ')), '') AS 'LAB_RESULT_TXT_VAL',
            otxt.ovt_seq			'LAB_RESULT_TXT_SEQ'  , -- AS Lab_Result_Txt_Seq,
            onum.ovn_comparator_cd_1,
            onum.ovn_numeric_value_1,
            onum.ovn_separator_cd,
            onum.ovn_numeric_value_2,
            CASE WHEN rtrim(onum.ovn_numeric_unit_cd) = '' THEN NULL
                 ELSE onum.ovn_numeric_unit_cd  END AS 'Result_Units',  -- as Result_Units,
            SUBSTRING(onum.ovn_low_range,1,20)					'REF_RANGE_FRM'  , -- AS Ref_Range_Frm,
            SUBSTRING(onum.ovn_high_range,1,20)				'REF_RANGE_TO'  , -- AS Ref_Range_To,
            CASE WHEN rtrim(code.ovc_code) = '' THEN NULL
                 ELSE code.ovc_code END AS 'TEST_RESULT_VAL_CD', -- AS Test_result_val_cd,
            CASE WHEN rtrim(code.ovc_display_name) = '' THEN NULL
                 ELSE code.ovc_display_name END AS 'TEST_RESULT_VAL_CD_DESC', -- AS Test_result_val_cd_desc,
            code.ovc_CODE_SYSTEM_CD			'TEST_RESULT_VAL_CD_SYS_CD'  , -- AS Test_result_val_cd_sys_cd,
            code.ovc_CODE_SYSTEM_DESC_TXT	'TEST_RESULT_VAL_CD_SYS_NM'  , -- AS Test_result_val_cd_sys_nm,
            code.ovc_ALT_CD						'ALT_RESULT_VAL_CD'  , -- AS Alt_result_val_cd,
            code.ovc_ALT_CD_DESC_TXT			'ALT_RESULT_VAL_CD_DESC'  , -- AS Alt_result_val_cd_desc,
            code.ovc_ALT_CD_SYSTEM_CD		'ALT_RESULT_VAL_CD_SYS_CD'  , -- AS Alt_result_val_cd_sys_cd,
            code.ovc_ALT_CD_SYSTEM_DESC_TXT	'ALT_RESULT_VAL_CD_SYSTEM_NM'  , -- AS Alt_result_val_cd_sys_nm,
            ndate.ovd_from_date 'FROM_TIME'  , -- AS from_time,
            ndate.ovd_to_date 'TO_TIME'  , -- AS to_time,
            CASE WHEN record_status_cd = 'LOG_DEL' THEN 'INACTIVE'
                 WHEN record_status_cd IN ('', 'UNPROCESSED', 'PROCESSED') THEN 'ACTIVE'
                 ELSE 'ACTIVE'
                END AS record_status_cd,
            NULL, --test_result_grp_key
            CASE WHEN onum.ovn_numeric_value_1 IS NOT NULL AND onum.ovn_numeric_value_2 IS NULL THEN rtrim(COALESCE(onum.ovn_comparator_cd_1,''))+rtrim(format(ovn_numeric_value_1,'0.#########'))
                 WHEN onum.ovn_numeric_value_1 IS NOT NULL AND onum.ovn_numeric_value_2 IS NOT NULL THEN rtrim(COALESCE(rtrim(COALESCE(onum.ovn_comparator_cd_1,''))+rtrim(format(ovn_numeric_value_1,'0.#########')),'')) + rtrim((COALESCE(onum.ovn_separator_cd,''))) + rtrim(format(onum.ovn_numeric_value_2,'0.#########'))
                 WHEN onum.ovn_numeric_value_1 IS NULL AND onum.ovn_numeric_value_2 IS NOT NULL THEN rtrim(COALESCE(NULL,'')) + rtrim((COALESCE(onum.ovn_separator_cd,''))) + rtrim(format(onum.ovn_numeric_value_2,'0.#########'))
                 ELSE NULL END AS Numeric_Result,
            NULL, --Test_Result_Val_Key
            NULL --lab_result_txt_val1
        FROM #TMP_Result_And_R_Result		as rslt
                 LEFT JOIN dbo.nrt_observation_txt	as otxt  with (nolock)	ON rslt.lab_test_uid = otxt.observation_uid
            AND ((otxt.ovt_txt_type_cd IS NULL) OR (rslt.ELR_IND = 'Y' AND otxt.ovt_txt_type_cd <>  'N'))
            --AND otxt.OBS_VALUE_TXT_SEQ =1
            /*
            Commented out because an ELR Test Result can have zero to many text result values
            AND otxt.OBS_VALUE_TXT_SEQ =1
            */
                 LEFT JOIN dbo.nrt_observation_numeric	as onum  with (nolock)	ON rslt.lab_test_uid = onum.observation_uid
                 LEFT JOIN dbo.nrt_observation_coded		as code	 with (nolock)	ON rslt.lab_test_uid = code.observation_uid
                 LEFT JOIN dbo.nrt_observation_date		as ndate  with (nolock)	ON rslt.lab_test_uid = ndate.observation_uid

        --LEFT JOIN (SELECT *, ROW_NUMBER() OVER (PARTITION BY observation_uid ORDER BY refresh_datetime DESC) AS cr
        --	FROM nrt_observation_coded with (nolock)) code on rslt.lab_test_uid = code.observation_uid and code.cr=1;


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Result_Val',* FROM #TMP_Lab_Result_Val;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'UPDATE #TMP_Lab_Result_Val ';

        /*Key Generation: TEST_RESULT_GROUPING */
        UPDATE tmp_val
        SET tmp_val.test_result_grp_key = trg.test_result_grp_key
        FROM #TMP_Lab_Result_Val tmp_val
                 INNER JOIN TEST_RESULT_GROUPING trg ON trg.lab_test_uid = tmp_val.lab_test_uid;


        CREATE TABLE #tmp_id_assignment(
                                           test_result_grp_id [int] IDENTITY(1,1) NOT NULL,
                                           [lab_test_uid] [bigint] NOT NULL
        )
        INSERT INTO #tmp_id_assignment
        SELECT rslt.lab_test_uid
        FROM #TMP_Lab_Result_Val rslt
                 LEFT JOIN TEST_RESULT_GROUPING trg ON trg.lab_test_uid = rslt.lab_test_uid
        WHERE trg.lab_test_uid IS NULL;


        UPDATE tmp_val
        SET tmp_val.test_result_grp_key =
                test_result_grp_id + COALESCE((SELECT MAX(test_result_grp_key) FROM TEST_RESULT_GROUPING),1)
        FROM #TMP_Lab_Result_Val tmp_val
                 LEFT JOIN #tmp_id_assignment id ON tmp_val.lab_test_uid = id.lab_test_uid
        WHERE tmp_val.test_result_grp_key IS NULL;

        /*
     UPDATE #TMP_Lab_Result_Val
        SET Lab_Result_Txt_Val = NULL
        WHERE ltrim(rtrim(Lab_Result_Txt_Val)) = '';


        UPDATE #TMP_Lab_Result_Val
        SET 	Numeric_Result = rtrim(COALESCE(COMPARATOR_CD_1,''))+rtrim(format(numeric_value_1,'0.#########') )
        WHERE NUMERIC_VALUE_1 IS not NULL;


        UPDATE #TMP_Lab_Result_Val
        SET	Numeric_Result = rtrim(COALESCE(Numeric_Result,'')) + rtrim((COALESCE(separator_cd,'')))
            + rtrim(format(numeric_value_2,'0.#########') )
        WHERE  NUMERIC_VALUE_2 IS not NULL;
        */


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Result_Val GROUP KEY',* FROM #TMP_Lab_Result_Val;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_TEST_RESULT_GROUPING ';

        IF OBJECT_ID('#TMP_TEST_RESULT_GROUPING', 'U') IS NOT NULL
            DROP TABLE   #TMP_TEST_RESULT_GROUPING;


        SELECT distinct [TEST_RESULT_GRP_KEY]
                      ,[LAB_TEST_UID]
        --,[RDB_LAST_REFRESH_TIME]
        INTO #TMP_TEST_RESULT_GROUPING
        FROM #TMP_Lab_Result_Val;


        UPDATE #TMP_Lab_Result_Val
        SET Test_Result_Val_Key = Test_Result_Grp_Key
        WHERE Test_Result_Grp_Key IS NOT NULL;



        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_New_Lab_Result_Val ';

        IF OBJECT_ID('#TMP_New_Lab_Result_Val', 'U') IS NOT NULL
            DROP TABLE  #TMP_New_Lab_Result_Val;


        SELECT DISTINCT LRV.lab_test_uid,
                        SUBSTRING(
                                (
                                    SELECT ' '+ST1.lab_result_txt_val  AS [text()]
                                    FROM #TMP_Lab_Result_Val ST1
                                    WHERE ST1.lab_test_uid = LRV.lab_test_uid
                                    ORDER BY ST1.lab_test_uid,ST1.lab_result_txt_seq
                                    FOR XML PATH ('')
                                ), 2, 2000) v_lab_result_val_txt
        INTO #TMP_New_Lab_Result_Val
        FROM #TMP_Lab_Result_Val LRV;


        UPDATE #TMP_Lab_Result_Val
        SET lab_result_txt_val = ( SELECT NULLIF(v_lab_result_val_txt,'') AS v_lab_result_val_txt
                                   FROM  #TMP_New_Lab_Result_Val tnl
                                   WHERE tnl.lab_test_uid = #TMP_Lab_Result_Val.lab_test_uid);


        /*
        UPDATE #TMP_Lab_Result_Val
        SET record_status_cd = 'ACTIVE'
        WHERE record_status_cd IN ( '' ,'UNPROCESSED' ,'PROCESSED' )
           OR  record_status_cd = NULL;

        UPDATE #TMP_Lab_Result_Val
        SET record_status_cd = 'INACTIVE'
        WHERE record_status_cd = 'LOG_DEL';


        UPDATE #TMP_Lab_Result_Val
        SET Test_Result_Val_Cd = NULL
        WHERE rtrim(Test_Result_Val_Cd ) = '';


        UPDATE #TMP_Lab_Result_Val
        SET Test_Result_Val_Cd_Desc  = NULL
        WHERE rtrim(Test_Result_Val_Cd_Desc  ) = '';


        UPDATE #TMP_Lab_Result_Val
        SET Result_Units  = NULL
    WHERE rtrim(Result_Units  ) = '';


        UPDATE #TMP_Lab_Result_Val
        SET Lab_Result_Txt_Val = NULL
        WHERE ltrim(rtrim(Lab_Result_Txt_Val)) = '';
        */


        DELETE
        FROM #TMP_Lab_Result_Val
        WHERE Test_Result_Val_Key = 1;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Result_Val_Final ';

        IF OBJECT_ID('#TMP_Lab_Result_Val_Final', 'U') IS NOT NULL
            DROP TABLE  #TMP_Lab_Result_Val_Final;

        SELECT MIN([TEST_RESULT_GRP_KEY]) AS TEST_RESULT_GRP_KEY
             ,[NUMERIC_RESULT]
             ,[RESULT_UNITS]
             --,[LAB_RESULT_TXT_VAL]
             ,(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lab_result_txt_val,
                                                                       '&#x09;', CHAR(9)),
                                                               '&#x0A;', CHAR(10)),
                                                       '&#x0D;', CHAR(13)),
                                               '&#x20;', CHAR(32)),
                                       '&amp;', CHAR(38)),
                               '&lt;', CHAR(60)),
                       '&gt;', CHAR(62))) AS LAB_RESULT_TXT_VAL
             ,[REF_RANGE_FRM]
             ,[REF_RANGE_TO]
             ,[TEST_RESULT_VAL_CD]
             ,rtrim([TEST_RESULT_VAL_CD_DESC]) AS [TEST_RESULT_VAL_CD_DESC]
             ,[TEST_RESULT_VAL_CD_SYS_CD]
             ,[TEST_RESULT_VAL_CD_SYS_NM]
             ,[ALT_RESULT_VAL_CD]
             ,rtrim([ALT_RESULT_VAL_CD_DESC]) AS [ALT_RESULT_VAL_CD_DESC]
             ,[ALT_RESULT_VAL_CD_SYS_CD]
             ,[ALT_RESULT_VAL_CD_SYSTEM_NM]
             ,MIN([TEST_RESULT_VAL_KEY]) AS TEST_RESULT_VAL_KEY
             ,[RECORD_STATUS_CD]
             ,[FROM_TIME]
             ,[TO_TIME]
             ,[LAB_TEST_UID]
        --, GETDATE()
        INTO  #TMP_Lab_Result_Val_Final
        FROM #TMP_LAB_RESULT_VAL
        GROUP BY
            [NUMERIC_RESULT]
               ,[RESULT_UNITS]
               ,[LAB_RESULT_TXT_VAL]
               ,[REF_RANGE_FRM]
               ,[REF_RANGE_TO]
               ,[TEST_RESULT_VAL_CD]
               ,rtrim([TEST_RESULT_VAL_CD_DESC])
               ,[TEST_RESULT_VAL_CD_SYS_CD]
               ,[TEST_RESULT_VAL_CD_SYS_NM]
               ,[ALT_RESULT_VAL_CD]
               ,rtrim([ALT_RESULT_VAL_CD_DESC])
               ,[ALT_RESULT_VAL_CD_SYS_CD]
               ,[ALT_RESULT_VAL_CD_SYSTEM_NM]
               ,[RECORD_STATUS_CD]
               ,[FROM_TIME]
               ,[TO_TIME]
               ,[LAB_TEST_UID];


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Result_Val_Final',* FROM #TMP_Lab_Result_Val_Final;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Test_Result2 ';

        IF OBJECT_ID('#TMP_Lab_Test_Result2', 'U') IS NOT NULL
            DROP TABLE  #TMP_Lab_Test_Result2;

        SELECT 	tst.*,
                  COALESCE(lrv.Test_Result_Grp_Key,1) AS Test_Result_Grp_Key
        INTO #TMP_Lab_Test_Result2
        from
            #TMP_Lab_Test_Result1 AS tst
                LEFT JOIN #TMP_Lab_Result_Val_FINAL AS lrv	ON tst.Lab_test_uid = lrv.Lab_test_uid
                AND lrv.Test_Result_Grp_Key <> 1;

        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Test_Result2',* FROM #TMP_Lab_Test_Result2;


        -- create table Lab_Test_Result3 AS

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Test_Result3 ';

        IF OBJECT_ID('#TMP_Lab_Test_Result3', 'U') IS NOT NULL
            DROP TABLE   #TMP_Lab_Test_Result3;


        SELECT 	tst.*,
                  COALESCE(psn.patient_key,1) AS patient_key
        INTO #TMP_Lab_Test_Result3
        FROM 	#TMP_Lab_Test_Result2 AS tst
                    /*Get patient id for root observation ids*/
                    LEFT JOIN dbo.nrt_observation no2 with (nolock) ON no2.observation_uid = tst.root_ordered_test_pntr
                    LEFT JOIN dbo.d_patient AS psn with (nolock)
                              ON no2.patient_id = psn.patient_uid
                                  AND psn.patient_key <> 1;

        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Test_Result3',* FROM #TMP_Lab_Test_Result3;


        UPDATE #TMP_Lab_Test_Result3
        SET
            PATIENT_KEY = morb_patient_key,
            Condition_Key = morb_Condition_Key,
            Investigation_Key = morb_Investigation_Key,
            REPORTING_LAB_KEY = MORB_RPT_SRC_ORG_KEY
        WHERE morb_rpt_key>1;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Test_Result ';

        IF OBJECT_ID('#TMP_Lab_Test_Result', 'U') IS NOT NULL
            DROP TABLE  #TMP_Lab_Test_Result;


        SELECT DISTINCT tst.*,
                        COALESCE(org.Organization_key,1) AS Performing_lab_key
        INTO    #TMP_Lab_Test_Result
        FROM 	#TMP_Lab_Test_Result3 AS tst
                    LEFT JOIN dbo.nrt_observation AS no2 with (nolock) ON no2.observation_uid= tst.lab_test_uid
                    LEFT JOIN dbo.d_Organization  AS org with (nolock)
                              ON no2.performing_organization_id = org.Organization_uid
                                  AND org.Organization_key <> 1;


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Test_Result',* FROM #TMP_Lab_Test_Result;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'DELETING #TMP_TEST_RESULT_GROUPING ';


        DELETE FROM #TMP_TEST_RESULT_GROUPING WHERE test_result_grp_key=1;
        DELETE FROM #TMP_TEST_RESULT_GROUPING WHERE test_result_grp_key IS NULL;
        DELETE FROM #TMP_TEST_RESULT_GROUPING
        WHERE TEST_RESULT_GRP_KEY NOT IN (SELECT TEST_RESULT_GRP_KEY FROM #TMP_LAB_RESULT_VAL);


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'UPDATE LAB_RESULT_VAL ';


        UPDATE dbo.LAB_RESULT_VAL
        SET
            [NUMERIC_RESULT]	 = 	SUBSTRING(tmp.NUMERIC_RESULT ,1,50),
            [RESULT_UNITS]	 = 	 SUBSTRING(tmp.RESULT_UNITS ,1,50)	,
            [LAB_RESULT_TXT_VAL]	 = 	rtrim(ltrim(SUBSTRING(tmp.LAB_RESULT_TXT_VAL ,1,2000))),
            [REF_RANGE_FRM]	 = 	SUBSTRING(tmp.REF_RANGE_FRM ,1,20),
            [REF_RANGE_TO]	 = 	 SUBSTRING(tmp.REF_RANGE_TO ,1,20),
            [TEST_RESULT_VAL_CD]	 = 	SUBSTRING(tmp.TEST_RESULT_VAL_CD ,1,20),
            [TEST_RESULT_VAL_CD_DESC]	 = 	SUBSTRING(rtrim(tmp.TEST_RESULT_VAL_CD_DESC) ,1,300),
            [TEST_RESULT_VAL_CD_SYS_CD]	 = 	SUBSTRING(tmp.TEST_RESULT_VAL_CD_SYS_CD ,1,100),
            [TEST_RESULT_VAL_CD_SYS_NM]	 = 	 SUBSTRING(tmp.TEST_RESULT_VAL_CD_SYS_NM ,1,100),
            [ALT_RESULT_VAL_CD]	 = 	 SUBSTRING(tmp.ALT_RESULT_VAL_CD ,1,50),
            [ALT_RESULT_VAL_CD_DESC]	 = 	 SUBSTRING(rtrim(tmp.ALT_RESULT_VAL_CD_DESC) ,1,100),
            [ALT_RESULT_VAL_CD_SYS_CD]	 = 	 SUBSTRING(tmp.ALT_RESULT_VAL_CD_SYS_CD ,1,50),
            [ALT_RESULT_VAL_CD_SYS_NM]	 = 	 SUBSTRING(tmp.ALT_RESULT_VAL_CD_SYSTEM_NM ,1,100),
            [TEST_RESULT_VAL_KEY]	 = 	tmp.TEST_RESULT_VAL_KEY,
            [RECORD_STATUS_CD]	 = 	SUBSTRING(tmp.RECORD_STATUS_CD, 1, 8),
            [FROM_TIME]	 = 	tmp.FROM_TIME,
            [TO_TIME]	 = tmp.TO_TIME,
            [LAB_TEST_UID]	 = 	tmp.LAB_TEST_UID,
            [RDB_LAST_REFRESH_TIME]	 = 	GETDATE()
        FROM #TMP_LAB_RESULT_VAL_FINAL tmp
                 INNER JOIN dbo.LAB_RESULT_VAL val with (nolock) ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
            AND val.TEST_RESULT_GRP_KEY = tmp.TEST_RESULT_GRP_KEY
            AND val.TEST_RESULT_VAL_KEY = val.TEST_RESULT_VAL_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'UPDATE TEST_RESULT_GROUPING';

        --No downstream update of RDB_LAST_REFRESH_TIME.
        UPDATE dbo.TEST_RESULT_GROUPING
        SET
            [TEST_RESULT_GRP_KEY] = tmp.TEST_RESULT_GRP_KEY,
            [LAB_TEST_UID] = tmp.LAB_TEST_UID,
            [RDB_LAST_REFRESH_TIME] = CAST( NULL AS datetime)
        FROM #TMP_TEST_RESULT_GROUPING tmp
                 INNER JOIN dbo.TEST_RESULT_GROUPING g with (nolock) ON g.LAB_TEST_UID = tmp.LAB_TEST_UID
            AND g.TEST_RESULT_GRP_KEY = tmp.TEST_RESULT_GRP_KEY;


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_TEST_RESULT_GROUPING',* FROM #TMP_TEST_RESULT_GROUPING;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'GENERATING TEST_RESULT_GROUPING ';

        --No downstream update of RDB_LAST_REFRESH_TIME.
        INSERT INTO dbo.TEST_RESULT_GROUPING
        ([TEST_RESULT_GRP_KEY]
        ,[LAB_TEST_UID]
        ,[RDB_LAST_REFRESH_TIME])
        SELECT tmp.[TEST_RESULT_GRP_KEY]
                ,tmp.[LAB_TEST_UID],
               CAST( NULL AS datetime) AS [RDB_LAST_REFRESH_TIME]
        FROM #TMP_TEST_RESULT_GROUPING tmp
                 LEFT JOIN dbo.TEST_RESULT_GROUPING g with (nolock) ON g.LAB_TEST_UID = tmp.LAB_TEST_UID
        WHERE g.LAB_TEST_UID IS NULL AND g.TEST_RESULT_GRP_KEY IS NULL;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'INSERTING INTO LAB_RESULT_VAL ';


        INSERT INTO dbo.LAB_RESULT_VAL
        ([TEST_RESULT_GRP_KEY]
        ,[NUMERIC_RESULT]
        ,[RESULT_UNITS]
        ,[LAB_RESULT_TXT_VAL]
        ,[REF_RANGE_FRM]
        ,[REF_RANGE_TO]
        ,[TEST_RESULT_VAL_CD]
        ,[TEST_RESULT_VAL_CD_DESC]
        ,[TEST_RESULT_VAL_CD_SYS_CD]
        ,[TEST_RESULT_VAL_CD_SYS_NM]
        ,[ALT_RESULT_VAL_CD]
        ,[ALT_RESULT_VAL_CD_DESC]
        ,[ALT_RESULT_VAL_CD_SYS_CD]
        ,[ALT_RESULT_VAL_CD_SYS_NM]
        ,[TEST_RESULT_VAL_KEY]
        ,[RECORD_STATUS_CD]
        ,[FROM_TIME]
        ,[TO_TIME]
        ,[LAB_TEST_UID]
        ,[RDB_LAST_REFRESH_TIME]
        )
        SELECT tmp.TEST_RESULT_GRP_KEY
             , SUBSTRING(tmp.NUMERIC_RESULT ,1,50)
             , SUBSTRING(tmp.RESULT_UNITS ,1,50)
             , rtrim(ltrim(SUBSTRING(tmp.LAB_RESULT_TXT_VAL ,1,2000)))
             , SUBSTRING(tmp.REF_RANGE_FRM ,1,20)
             , SUBSTRING(tmp.REF_RANGE_TO ,1,20)
             , SUBSTRING(tmp.TEST_RESULT_VAL_CD ,1,20)
             , SUBSTRING(rtrim(tmp.TEST_RESULT_VAL_CD_DESC) ,1,300)
             , SUBSTRING(tmp.TEST_RESULT_VAL_CD_SYS_CD ,1,100)
             , SUBSTRING(tmp.TEST_RESULT_VAL_CD_SYS_NM ,1,100)
             , SUBSTRING(tmp.ALT_RESULT_VAL_CD ,1,50)
             , SUBSTRING(rtrim(tmp.ALT_RESULT_VAL_CD_DESC) ,1,100)
             , SUBSTRING(tmp.ALT_RESULT_VAL_CD_SYS_CD ,1,50)
             , SUBSTRING(tmp.ALT_RESULT_VAL_CD_SYSTEM_NM ,1,100)
             ,tmp.TEST_RESULT_VAL_KEY
             , SUBSTRING(tmp.RECORD_STATUS_CD ,1,8)
             ,tmp.FROM_TIME
             ,tmp.TO_TIME
             ,tmp.LAB_TEST_UID
             , GETDATE()
        FROM #TMP_LAB_RESULT_VAL_FINAL tmp
                 LEFT JOIN dbo.LAB_RESULT_VAL val with (nolock) ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
        WHERE val.LAB_TEST_UID IS NULL and val.TEST_RESULT_VAL_KEY IS NULL;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;


        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'UPDATE RESULT_COMMENT_GROUP ';


        UPDATE dbo.RESULT_COMMENT_GROUP
        SET
            [RESULT_COMMENT_GRP_KEY] = tmp.RESULT_COMMENT_GRP_KEY,
            [LAB_TEST_UID] = tmp.LAB_TEST_UID,
            [RDB_LAST_REFRESH_TIME] = GETDATE()
        FROM #TMP_RESULT_COMMENT_GROUP tmp
                 INNER JOIN dbo.RESULT_COMMENT_GROUP val ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
            AND val.RESULT_COMMENT_GRP_KEY = tmp.RESULT_COMMENT_GRP_KEY;



        IF @pDebug = 'true' SELECT 'DEBUG: TMP_RESULT_COMMENT_GROUP Update', * FROM #TMP_RESULT_COMMENT_GROUP;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;


        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'INSERTING INTO RESULT_COMMENT_GROUP ';


        INSERT INTO  dbo.RESULT_COMMENT_GROUP
        ([RESULT_COMMENT_GRP_KEY]
        ,[LAB_TEST_UID]
        ,[RDB_LAST_REFRESH_TIME]
        )
        SELECT tmp.[RESULT_COMMENT_GRP_KEY]
             , tmp.[LAB_TEST_UID]
             , GETDATE()
        FROM #TMP_RESULT_COMMENT_GROUP tmp
                 LEFT JOIN dbo.RESULT_COMMENT_GROUP val with (nolock) ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
        WHERE val.LAB_TEST_UID IS NULL and val.RESULT_COMMENT_GRP_KEY IS NULL;


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_RESULT_COMMENT_GROUP', * FROM #TMP_RESULT_COMMENT_GROUP;

        /*
        UPDATE #TMP_New_Lab_Result_Comment_FINAL
        SET record_status_cd = 'ACTIVE'
        WHERE record_status_cd IN ( '' ,'UNPROCESSED' ,'PROCESSED' )
           OR  record_status_cd = NULL;

        UPDATE #TMP_New_Lab_Result_Comment_FINAL
        SET record_status_cd = 'INACTIVE'
        WHERE record_status_cd = 'LOG_DEL';



        UPDATE #TMP_New_Lab_Result_Comment_FINAL
        SET [LAB_RESULT_COMMENTS] = replace ( [LAB_RESULT_COMMENTS],'&#x20;',' ')
        WHERE [LAB_RESULT_COMMENTS] like  '%.&#x20;%';

        UPDATE #TMP_New_Lab_Result_Comment_FINAL
        SET [LAB_RESULT_COMMENTS] = (REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([LAB_RESULT_COMMENTS],
                                                                                             '&#x09;', CHAR(9)),
                                                                                     '&#x0A;', CHAR(10)),
                                                                             '&#x0D;', CHAR(13)),
                                                                     '&#x20;', CHAR(32)),
                                                             '&amp;', CHAR(38)),
                                                     '&lt;', CHAR(60)),
    '&gt;', CHAR(62)));




        UPDATE #TMP_New_Lab_Result_Comment_FINAL
        SET [RDB_LAST_REFRESH_TIME] = GETDATE();

        */


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;


        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'UPDATE Lab_Result_Comment ';


        UPDATE dbo.Lab_Result_Comment
        SET
            [LAB_RESULT_COMMENTS] = SUBSTRING(tmp.LAB_RESULT_COMMENTS ,1,2000),
            [RESULT_COMMENT_GRP_KEY] = tmp.RESULT_COMMENT_GRP_KEY,
            [RECORD_STATUS_CD] = SUBSTRING(tmp.RECORD_STATUS_CD ,1,8),
            [RDB_LAST_REFRESH_TIME] = tmp.[RDB_LAST_REFRESH_TIME]
        FROM #TMP_New_Lab_Result_Comment_FINAL tmp
                 INNER JOIN dbo.Lab_Result_Comment val with (nolock) ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
            AND val.LAB_RESULT_COMMENT_KEY = tmp.LAB_RESULT_COMMENT_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;


        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'INSERTING INTO Lab_Result_Comment ';


        INSERT INTO dbo.Lab_Result_Comment
        ([LAB_TEST_UID]
        ,[LAB_RESULT_COMMENT_KEY]
        ,[LAB_RESULT_COMMENTS]
        ,[RESULT_COMMENT_GRP_KEY]
        ,[RECORD_STATUS_CD]
        ,[RDB_LAST_REFRESH_TIME]
        )
        SELECT tmp.LAB_TEST_UID
             , tmp.LAB_RESULT_COMMENT_KEY
             , SUBSTRING(tmp.LAB_RESULT_COMMENTS ,1,2000)
             , tmp.RESULT_COMMENT_GRP_KEY
             , SUBSTRING(tmp.RECORD_STATUS_CD ,1,8)
             , tmp.[RDB_LAST_REFRESH_TIME]
        FROM #TMP_New_Lab_Result_Comment_FINAL tmp
                 LEFT JOIN dbo.Lab_Result_Comment val with (nolock) ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
        WHERE val.LAB_TEST_UID IS NULL AND val.LAB_RESULT_COMMENT_KEY IS NULL;


        DELETE FROM #TMP_Lab_Test_Result WHERE lab_test_key IS NULL;

        /*
        UPDATE #TMP_Lab_Test_Result
        SET record_status_cd = 'ACTIVE'
        WHERE record_status_cd IN ( '' ,'UNPROCESSED' ,'PROCESSED' )
           OR  record_status_cd = NULL;

        UPDATE #TMP_Lab_Test_Result
        SET record_status_cd = 'INACTIVE'
        WHERE record_status_cd = 'LOG_DEL';
        */


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'UPDATE LAB_TEST_RESULT';

        UPDATE dbo.LAB_TEST_RESULT
        SET
            [LAB_TEST_KEY]	 =	tmp.[LAB_TEST_KEY],
            [LAB_TEST_UID]	 =	tmp.[LAB_TEST_UID],
            [RESULT_COMMENT_GRP_KEY]	 =	tmp.[RESULT_COMMENT_GRP_KEY],
            [TEST_RESULT_GRP_KEY]	 =	tmp.[TEST_RESULT_GRP_KEY],
            [PERFORMING_LAB_KEY]	 =	tmp.[PERFORMING_LAB_KEY],
            [PATIENT_KEY]	 =	COALESCE(tmp.[PATIENT_KEY],''),
            [COPY_TO_PROVIDER_KEY]	 =	COALESCE(tmp.[COPY_TO_PROVIDER_KEY],''),
            [LAB_TEST_TECHNICIAN_KEY]	 =	COALESCE(tmp.[LAB_TEST_TECHNICIAN_KEY],''),
            [SPECIMEN_COLLECTOR_KEY]	 =	COALESCE(tmp.[SPECIMEN_COLLECTOR_KEY],''),
            [ORDERING_ORG_KEY]	 =	COALESCE(tmp.[ORDERING_ORG_KEY],''),
            [REPORTING_LAB_KEY]	 =	COALESCE(tmp.[REPORTING_LAB_KEY],''),
            [CONDITION_KEY]	 =	COALESCE(tmp.[CONDITION_KEY],''),
            [LAB_RPT_DT_KEY]	 =	COALESCE(tmp.[LAB_RPT_DT_KEY],''),
            [MORB_RPT_KEY]	 =	COALESCE(tmp.[MORB_RPT_KEY],''),
            [INVESTIGATION_KEY]	 =	COALESCE(tmp.[INVESTIGATION_KEY],''),
            [LDF_GROUP_KEY]	 =	COALESCE(tmp.[LDF_GROUP_KEY],''),
            [ORDERING_PROVIDER_KEY]	 =	COALESCE(tmp.[ORDERING_PROVIDER_KEY],''),
            [RECORD_STATUS_CD]	 =	SUBSTRING(tmp.RECORD_STATUS_CD ,1,8),
            [RDB_LAST_REFRESH_TIME]	 =	GETDATE()
        FROM #TMP_LAB_TEST_RESULT tmp
                 INNER JOIN dbo.LAB_TEST_RESULT val with (nolock) ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
            AND val.RESULT_COMMENT_GRP_KEY = tmp.RESULT_COMMENT_GRP_KEY
            AND val.TEST_RESULT_GRP_KEY = tmp.TEST_RESULT_GRP_KEY;


        IF @pDebug = 'true' SELECT 'TMP_LAB_TEST_RESULT', * FROM #TMP_LAB_TEST_RESULT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'INSERTING INTO LAB_TEST_RESULT';

        INSERT INTO dbo.LAB_TEST_RESULT
        ([LAB_TEST_KEY]
        ,[LAB_TEST_UID]
        ,[RESULT_COMMENT_GRP_KEY]
        ,[TEST_RESULT_GRP_KEY]
        ,[PERFORMING_LAB_KEY]
        ,[PATIENT_KEY]
        ,[COPY_TO_PROVIDER_KEY]
        ,[LAB_TEST_TECHNICIAN_KEY]
        ,[SPECIMEN_COLLECTOR_KEY]
        ,[ORDERING_ORG_KEY]
        ,[REPORTING_LAB_KEY]
        ,[CONDITION_KEY]
        ,[LAB_RPT_DT_KEY]
        ,[MORB_RPT_KEY]
        ,[INVESTIGATION_KEY]
        ,[LDF_GROUP_KEY]
        ,[ORDERING_PROVIDER_KEY]
        ,[RECORD_STATUS_CD]
        ,[RDB_LAST_REFRESH_TIME]
        )
        SELECT tmp.[LAB_TEST_KEY]
             ,tmp.[LAB_TEST_UID]
             ,tmp.[RESULT_COMMENT_GRP_KEY]
             ,tmp.[TEST_RESULT_GRP_KEY]
             ,tmp.[PERFORMING_LAB_KEY]
             ,COALESCE(tmp.[PATIENT_KEY],'')
             ,COALESCE(tmp.[COPY_TO_PROVIDER_KEY],'')
             ,COALESCE(tmp.[LAB_TEST_TECHNICIAN_KEY],'')
             ,COALESCE(tmp.[SPECIMEN_COLLECTOR_KEY],'')
             ,COALESCE(tmp.[ORDERING_ORG_KEY],'')
             ,COALESCE(tmp.[REPORTING_LAB_KEY],'')
             ,COALESCE(tmp.[CONDITION_KEY],'')
             ,COALESCE(tmp.[LAB_RPT_DT_KEY],'')
             ,COALESCE(tmp.[MORB_RPT_KEY],'')
             ,COALESCE(tmp.[INVESTIGATION_KEY],'')
             ,COALESCE(tmp.[LDF_GROUP_KEY],'')
             ,COALESCE(tmp.[ORDERING_PROVIDER_KEY],'')
             , SUBSTRING(tmp.RECORD_STATUS_CD ,1,8)
             , GETDATE() AS [RDB_LAST_REFRESH_TIME]
        FROM #TMP_LAB_TEST_RESULT tmp
                 LEFT JOIN dbo.LAB_TEST_RESULT val with (nolock) ON val.LAB_TEST_UID = tmp.LAB_TEST_UID
            AND val.LAB_TEST_KEY = tmp.LAB_TEST_KEY
        WHERE val.LAB_TEST_UID IS NULL AND val.LAB_TEST_KEY IS NULL;


        IF @pDebug = 'true' SELECT 'TMP_LAB_TEST_RESULT', * FROM #TMP_LAB_TEST_RESULT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        IF OBJECT_ID('#TMP_lab_test_resultInit', 'U') IS NOT NULL
            DROP TABLE   #TMP_lab_test_resultInit ;

        IF OBJECT_ID('#TMP_Lab_Test_Result1', 'U') IS NOT NULL
            DROP TABLE  #TMP_Lab_Test_Result1;

        IF OBJECT_ID('#TMP_Result_And_R_Result', 'U') IS NOT NULL
            DROP TABLE  #TMP_Result_And_R_Result;

        IF OBJECT_ID('#TMP_Lab_Result_Comment', 'U') IS NOT NULL
            DROP TABLE   #TMP_Lab_Result_Comment ;

        IF OBJECT_ID('#TMP_New_Lab_Result_Comment', 'U') IS NOT NULL
            DROP TABLE  #TMP_New_Lab_Result_Comment;

        IF OBJECT_ID('#TMP_New_Lab_Result_Comment_grouped', 'U') IS NOT NULL
            DROP TABLE  #TMP_New_Lab_Result_Comment_grouped;

        IF OBJECT_ID('#TMP_New_Lab_Result_Comment_FINAL', 'U') IS NOT NULL
            DROP TABLE   #TMP_New_Lab_Result_Comment_FINAL;

        IF OBJECT_ID('#TMP_Result_Comment_Group', 'U') IS NOT NULL
            DROP TABLE  #TMP_Result_Comment_Group;

        IF OBJECT_ID('#TMP_Lab_Result_Val', 'U') IS NOT NULL
            DROP TABLE   #TMP_Lab_Result_Val;

        IF OBJECT_ID('#TMP_TEST_RESULT_GROUPING', 'U') IS NOT NULL
            DROP TABLE   #TMP_TEST_RESULT_GROUPING;

        IF OBJECT_ID('#TMP_New_Lab_Result_Val', 'U') IS NOT NULL
            DROP TABLE  #TMP_New_Lab_Result_Val;

        IF OBJECT_ID('#TMP_Lab_Test_Result2', 'U') IS NOT NULL
            DROP TABLE  #TMP_Lab_Test_Result2;

        IF OBJECT_ID('#TMP_Lab_Test_Result3', 'U') IS NOT NULL
            DROP TABLE   #TMP_Lab_Test_Result3;

        IF OBJECT_ID('#TMP_Lab_Test_Result', 'U') IS NOT NULL
            DROP TABLE     #TMP_Lab_Test_Result;


        BEGIN TRANSACTION;


        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @Proc_Step_Name = 'SP_COMPLETE';


        INSERT INTO [dbo].[job_flow_log] (
                                           batch_id
                                         ,[Dataflow_Name]
                                         ,[package_Name]
                                         ,[Status_Type]
                                         ,[step_number]
                                         ,[step_name]
                                         ,[row_count]
        )
        VALUES
            (
              @batch_id,
              'D_LABTEST_RESULTS'
            ,'D_LABTEST_RESULTS'
            ,'COMPLETE'
            ,@Proc_Step_no
            ,@Proc_Step_name
            ,@RowCount_no
            );


        COMMIT TRANSACTION;


    END TRY


    BEGIN CATCH


        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;


        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();


        INSERT INTO [dbo].[job_flow_log] (
                                           batch_id
                                         ,[Dataflow_Name]
                                         ,[package_Name]
                                         ,[Status_Type]
                                         ,[step_number]
                                         ,[step_name]
                                         ,[Error_Description]
                                         ,[row_count]
        )
        VALUES
            (
              @batch_id
            ,'D_LABTEST_RESULTS'
            ,'D_LABTEST_RESULTS'
            ,'ERROR'
            ,@Proc_Step_no
            ,'ERROR - '+ @Proc_Step_name
            , 'Step -' +CAST(@Proc_Step_no AS VARCHAR(3))+' -' +CAST(@ErrorMessage AS VARCHAR(500))
            ,0
            );


        RETURN -1 ;


    END CATCH


END;