CREATE OR ALTER PROCEDURE [dbo].[sp_d_labtest_result_postprocessing]
(@pLabResultList nvarchar(max)
, @pDebug bit = 'false')

AS

BEGIN
    /*
     * [Description]
     * This stored procedure is handles event based updates to LAB_TEST_RESULT and associated tables.
     * 1. Receives input list of Lab Report based Observations with Order.
     * 2. Pulls changed records FROM nrt_observation using the input list into temporary tables for processing.
     * 3. Inserts new records into target dimensions.
     *
     * [Target Dimensions]
     * 1. LAB_TEST_RESULT
     * 2. TEST_RESULT_GROUPING
     * 3. RESULT_COMMENT_GROUP
     * 4. LAB_RESULT_VAL
     * 5. LAB_RESULT_COMMENT
     */

    DECLARE @batch_id bigint;
    SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmss')) AS bigint);
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


        --List of Observations for Lab Test Result
        SELECT lab_test_key,
               root_ordered_test_pntr,
               lab_test_uid,
               record_status_cd,
               lab_rpt_created_dt,
               lab_test_type, -- for TMP_Result_And_R_Result
               elr_ind -- for TMP_Result_And_R_Result
        INTO #TMP_D_LAB_TEST_N
        FROM dbo.LAB_TEST --remove RDB after testing
        --WHERE lab_test_key NOT IN (SELECT LAB_TEST_KEY FROM LAB_TEST_RESULT);
        WHERE lab_test_uid IN (SELECT value FROM string_split(@pLabResultList, ','));

        IF @pDebug = 'true' SELECT 'DEBUG: TMP_D_LAB_TEST_N',* FROM #TMP_D_LAB_TEST_N;


        --Get morbidity report associated to lab
        SELECT
            tst.lab_test_key,
            tst.root_ordered_test_pntr,
            tst.lab_test_uid,
            tst.record_status_cd,
            tst.Root_Ordered_Test_Pntr AS Root_Ordered_Test_Pntr2 ,
            tst.lab_rpt_created_dt,
            COALESCE(morb.morb_rpt_key,1) 'MORB_RPT_KEY' ,
            morb_event.PATIENT_KEY AS morb_patient_key,
            morb_event.Condition_Key AS morb_Condition_Key,
            morb_event.Investigation_Key AS morb_Investigation_Key,
            morb_event.MORB_RPT_SRC_ORG_KEY AS MORB_RPT_SRC_ORG_KEY
        INTO #TMP_lab_test_resultInit
        FROM  #TMP_D_LAB_TEST_N AS tst
                  /* Morb report */
                  LEFT JOIN dbo.nrt_observation no2 ON tst.lab_test_uid = no2.observation_uid
                  LEFT JOIN Morbidity_Report	as morb
                            ON no2.report_observation_uid = morb.morb_rpt_uid
                  LEFT JOIN Morbidity_report_event morb_event on
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


        --NRT update
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
        FROM #TMP_lab_test_resultInit AS tst
                 LEFT JOIN dbo.nrt_observation no2 ON tst.lab_test_uid = no2.observation_uid
            /*get specimen collector*/
                 LEFT JOIN d_provider AS per4
                           ON no2.specimen_collector_id = per4.provider_uid
            /*get copy_to_provider key*/
                 LEFT JOIN d_provider AS per5
                           ON no2.specimen_collector_id = per5.provider_uid
            /*get lab_test_technician*/
                 LEFT JOIN d_provider AS per6
                           ON no2.lab_test_technician_id = per6.provider_uid
            /* Ordering Provider */
                 LEFT JOIN	d_provider 	AS prv
                              ON no2.ordering_person_id = prv.provider_uid
            /* Reporting_Lab*/
                 LEFT JOIN d_Organization	AS org
                           ON no2.author_organization_id = org.Organization_uid
            /* Ordering Facility */
                 LEFT JOIN d_Organization	AS org2
                           ON no2.ordering_organization_id = org2.Organization_uid

            /* Conditon, it's just program area */

            /*IF we add a program area to the Lab_Report DimensiON we probably don't
            even need a conditiON dimension.  Even though it's OK with the DimensiON Modeling
            principle for adding a prog_area_cd row to the condition, it sure will cause
            some confusiON among users.  There's no "disease" ON the input.
            */
                 LEFT JOIN	Condition	AS con
                              ON	no2.prog_area_cd  = con.program_area_cd
                                  AND con.condition_cd IS NULL
            /*LDF_GRP_KEY*/
            --LEFT JOIN ldf_group AS ldf_g 	ON tst.Lab_test_UID = ldf_g.business_object_uid --VS
                 LEFT JOIN ldf_group AS ldf_g 	ON tst.Lab_test_UID = ldf_g.ldf_group_key

            /* Lab_Rpt_Dt */ --VS	LEFT JOIN rdb_datetable 		as dat
                 LEFT JOIN rdb_date AS dat 	ON  DATEADD(d,0,DATEDIFF(d,0,[lab_rpt_created_dt])) = dat.DATE_MM_DD_YYYY
            /* PHC */
                 LEFT JOIN dbo.nrt_investigation_observation ninv ON ninv.observation_id = tst.lab_test_uid
                 LEFT JOIN investigation AS inv ON ninv.public_health_case_uid = inv.case_uid;


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Test_Result1',* FROM #TMP_Lab_Test_Result1;


        --	IF @pDebug = 'true' SELECT 'TMP_Lab_Test_Result12',* FROM #TMP_Lab_Test_Result12;


        /*-------------------------------------------------------

            Lab_Result_Comment Dimension

            Note: User Comments for Result Test Object (Lab104)

        ---------------------------------------------------------*/


        --create table Result_And_R_Result;

        /** -- VS

        --create table Result_And_R_Result;

        data Result_And_R_Result;
        SET Lab_Test;
            IF (Lab_Test_Type = 'Result' OR  Lab_Test_Type IN ('R_Result', 'I_Result',  'Order_rslt'));
        run;

        proc sql;
        */


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


        --NRT
        SELECT *
        INTO #TMP_Result_And_R_Result
        FROM #TMP_D_LAB_TEST_N --dbo.LAB_TEST
        WHERE
            (Lab_Test_Type = 'Result' OR  Lab_Test_Type IN ('R_Result', 'I_Result', 'Order_rslt'));


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Result_And_R_Result',* FROM #TMP_Result_And_R_Result;


        -- create table Lab_Result_Comment AS

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

        SELECT
            lab104.lab_test_uid,
            REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ')	'LAB_RESULT_COMMENTS'  , -- asLab_Result_Comments,
            ovt.ovt_seq	'LAB_RESULT_TXT_SEQ'  , -- AS Lab_Result_Txt_Seq,
            lab104.record_status_cd
        INTO #TMP_Lab_Result_Comment
        FROM
            #TMP_Result_And_R_Result		as lab104,
            dbo.nrt_observation_txt AS ovt
        WHERE 	ovt.ovt_value_txt IS NOT NULL
          AND ovt.ovt_txt_type_cd = 'N'
          AND ovt.ovt_seq <>  0
          AND ovt.observation_uid =  lab104.lab_test_uid;


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Result_Comment',* FROM #TMP_Lab_Result_Comment;


        /*************************************************************
        Added  support wrapping of comments when comments are
        stored IN multiple obs_value_txt rows IN ODS
        */


        /*
        proc sort data = Lab_Result_Comment;
        by lab_test_uid DESCENDING lab_result_txt_seq;


        data New_Lab_Result_Comment (drop = lab_result_txt_seq);
          SET Lab_Result_Comment;
            by lab_test_uid;

            Length v_lab_result_val_comments $10000;
            RetaIN v_lab_result_val_comments;

        */

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


        /*
            IF first.lab_test_uid then
     v_lab_result_val_comments = trim(lab_result_comments);
            else
                v_lab_result_val_comments = (trim(lab_result_comments) || ' ' || v_lab_result_val_comments);

            IF last.lab_test_uid then
                output;
        run;
        */

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
        SET lab_result_comments = ( SELECT v_lab_result_val_txt
                                    FROM  #TMP_New_Lab_Result_Comment_grouped tnl
                                    WHERE tnl.lab_test_uid = #TMP_New_Lab_Result_Comment.lab_test_uid);


        UPDATE #TMP_New_Lab_Result_Comment
        SET [LAB_RESULT_COMMENTS] = NULL
        WHERE [LAB_RESULT_COMMENTS] = '#x20;';


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
                                                          Lab_Result_Comment_Key_id  [int] IDENTITY(1,1) NOT NULL,
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
                      ,[LAB_RESULT_COMMENTS]
                      ,NULL
                      ,[record_status_cd]
                      , NULL
        FROM #TMP_New_Lab_Result_Comment;


        /*
        data Lab_Result_Comment (drop = Lab_Result_Comments);
         SET New_Lab_Result_Comment;
         rename v_lab_result_val_comments = lab_result_comments;
        run;


        data Lab_Result_Comment;
        SET Lab_Result_Comment; run;
        */


        /*
        /*************************************************************/

        proc sort data = Lab_Result_Comment nodupkey; by Lab_test_uid; run;
        %assign_key(Lab_Result_Comment, Lab_Result_Comment_Key);

        proc sql;
        ALTER TABLE Lab_Result_Comment ADD Lab_Result_Comment_Key_MAX_VAL  NUMERIC;
        UPDATE  Lab_Result_Comment SET Lab_Result_Comment_Key_MAX_VAL=(SELECT MAX(Lab_Result_Comment_Key) FROM Lab_Result_Comment);
        quit;
        DATA Lab_Result_Comment;
        SET Lab_Result_Comment;
        IF Lab_Result_Comment_Key_MAX_VAL  <> . AND Lab_Result_Comment_Key<> 1 THEN Lab_Result_Comment_Key= Lab_Result_Comment_Key+Lab_Result_Comment_Key_MAX_VAL;
        RUN;
        t
        */

        UPDATE #TMP_New_Lab_Result_Comment_FINAL
        SET [LAB_RESULT_COMMENT_KEY]= Lab_Result_Comment_Key_id
            + COALESCE((SELECT MAX(Lab_Result_Comment_Key) FROM Lab_Result_Comment),1);


        /*
        data Lab_Result_Comment;
        SET Lab_Result_Comment;
        Result_Comment_Grp_Key = Lab_Result_Comment_Key;
        run;
        data Result_Comment_Group (Keep = Result_Comment_Grp_Key lab_test_uid);
            SET Lab_Result_Comment;
        run;
        */
        UPDATE #TMP_New_Lab_Result_Comment_FINAL
        SET Result_Comment_Grp_Key = [LAB_RESULT_COMMENT_KEY];


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_New_Lab_Result_Comment', * FROM #TMP_New_Lab_Result_Comment;


        /*
        proc sort data=result_comment_group;
            by Result_Comment_Grp_Key;
        proc sql;
        DELETE FROM Result_Comment_Group WHERE result_comment_grp_key=1;
        DELETE FROM Result_Comment_Group WHERE result_comment_grp_key=.;
        quit;

        */

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


        /* --VS

        DATA lab_test_result1;
            MERGE Result_Comment_Group lab_test_result1;
            by lab_test_uid;
        run;

        data lab_test_result1;
        SET lab_test_result1;



        IF Result_Comment_Grp_Key =.  then Result_Comment_Grp_Key = 1;
        */

        UPDATE #TMP_lab_test_result1
        SET [RESULT_COMMENT_GRP_KEY] = ( SELECT [RESULT_COMMENT_GRP_KEY]
                                         FROM #tmp_Result_Comment_Group trcg
                                         WHERE trcg.lab_test_uid = #tmp_lab_test_result1.lab_test_uid);


        UPDATE #TMP_lab_test_result1
        SET [RESULT_COMMENT_GRP_KEY] = 1
        WHERE [RESULT_COMMENT_GRP_KEY] IS NULL;


        /*
        /*Creating Result_Comment_Group **/

        data Result_Comment_Group;
            SET Result_Comment_Group;
        run;

        data lab_result_comment;
        SET lab_result_comment;
        WHERE Lab_Result_Comment_Key <> 1; run;
        proc sort data = Lab_Result_Comment nodupkey; by Lab_test_uid; run;

        */


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        /*-------------------------------------------------------

		Lab_Result_Val Dimension
		Test_Result_Grouping Dimension

		---------------------------------------------------------*/

        --create table Lab_Result_Val as


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #TMP_Lab_Result_Val ';

        IF OBJECT_ID('#TMP_Lab_Result_Val', 'U') IS NOT NULL
            DROP TABLE   #TMP_Lab_Result_Val;


        --NRT
        CREATE TABLE #TMP_LAB_RESULT_VAL(
                                            test_result_grp_id  [int] IDENTITY(1,1) NOT NULL,
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
            REPLACE(REPLACE(otxt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ') 		'LAB_RESULT_TXT_VAL'  , -- AS Lab_Result_Txt_Val,
            otxt.ovt_seq			'LAB_RESULT_TXT_SEQ'  , -- AS Lab_Result_Txt_Seq,
            onum.ovn_comparator_cd_1,
            onum.ovn_numeric_value_1,
            onum.ovn_separator_cd,
            onum.ovn_numeric_value_2,
            onum.ovn_numeric_unit_cd    	'Result_Units'  , -- asResult_Units,
            SUBSTRING(onum.ovn_low_range,1,20)					'REF_RANGE_FRM'  , -- AS Ref_Range_Frm,
            SUBSTRING(onum.ovn_high_range,1,20)				'REF_RANGE_TO'  , -- AS Ref_Range_To,
            code.ovc_code						'TEST_RESULT_VAL_CD'  , -- AS Test_result_val_cd,
            code.ovc_display_name				'TEST_RESULT_VAL_CD_DESC'  , -- AS Test_result_val_cd_desc,
            code.ovc_CODE_SYSTEM_CD			'TEST_RESULT_VAL_CD_SYS_CD'  , -- AS Test_result_val_cd_sys_cd,
            code.ovc_CODE_SYSTEM_DESC_TXT	'TEST_RESULT_VAL_CD_SYS_NM'  , -- AS Test_result_val_cd_sys_nm,
            code.ovc_ALT_CD						'ALT_RESULT_VAL_CD'  , -- AS Alt_result_val_cd,
            code.ovc_ALT_CD_DESC_TXT			'ALT_RESULT_VAL_CD_DESC'  , -- AS Alt_result_val_cd_desc,
            code.ovc_ALT_CD_SYSTEM_CD		'ALT_RESULT_VAL_CD_SYS_CD'  , -- AS Alt_result_val_cd_sys_cd,
            code.ovc_ALT_CD_SYSTEM_DESC_TXT	'ALT_RESULT_VAL_CD_SYSTEM_NM'  , -- AS Alt_result_val_cd_sys_nm,
            ndate.ovd_from_date 'FROM_TIME'  , -- AS from_time,
            ndate.ovd_to_date 'TO_TIME'  , -- AS to_time,
            rslt.record_status_cd,
            NULL,
            NULL,
            NULL,
            NULL
        FROM #TMP_Result_And_R_Result		as rslt
                 LEFT JOIN nrt_observation_txt	as otxt 		ON rslt.lab_test_uid = otxt.observation_uid
            AND ((otxt.ovt_txt_type_cd IS NULL) OR (rslt.ELR_IND = 'Y' AND otxt.ovt_txt_type_cd <>  'N'))
            --AND otxt.OBS_VALUE_TXT_SEQ =1
            /*
            Commented out because an ELR Test Result can have zero to many text result values
            AND otxt.OBS_VALUE_TXT_SEQ =1
            */
                 LEFT JOIN nrt_observation_numeric	as onum 	ON rslt.lab_test_uid = onum.observation_uid
                 LEFT JOIN nrt_observation_coded		as code		ON rslt.lab_test_uid = code.observation_uid
                 LEFT JOIN nrt_observation_date		as ndate 	ON rslt.lab_test_uid = ndate.observation_uid;


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Result_Val',* FROM #TMP_Lab_Result_Val;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'UPDATE  #TMP_Lab_Result_Val ';


        /*
        quit;
        %assign_key(Lab_Result_Val,Test_Result_Grp_Key);

        proc sql;
        ALTER TABLE Lab_Result_Val ADD test_result_grp_key_MAX_VAL  NUMERIC;
        UPDATE  Lab_Result_Val SET test_result_grp_key_MAX_VAL=(SELECT MAX(test_result_grp_key) FROM Test_Result_Grouping);
        quit;
        DATA Lab_Result_Val;
        SET Lab_Result_Val;
        IF test_result_grp_key_MAX_VAL = 1 then test_result_grp_key_MAX_VAL=.;
        IF test_result_grp_key_MAX_VAL  <> . AND test_result_grp_key<> 1 THEN test_result_grp_key= test_result_grp_key+test_result_grp_key_MAX_VAL;
        RUN;
        */

        UPDATE #TMP_Lab_Result_Val
        SET test_result_grp_key= test_result_grp_id
            + COALESCE((SELECT MAX(test_result_grp_key) FROM TEST_RESULT_GROUPING),1);


        UPDATE #TMP_Lab_Result_Val
        SET Lab_Result_Txt_Val = NULL
        WHERE ltrim(rtrim(Lab_Result_Txt_Val)) = '';

        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Result_Val GROUP KEY',* FROM #TMP_Lab_Result_Val;


        /*

        proc sort tagsort data = Lab_Result_Val;
            by lab_test_uid;

        data Lab_Result_Val;
            SET Lab_Result_Val;
            format Numeric_Result	$50.;
        */
        /*
            IF NUMERIC_VALUE_1 <> . then
                Numeric_Result = trim(COMPARATOR_CD_1)||trim(left(put(NUMERIC_VALUE_1, 11.5)));
            IF NUMERIC_VALUE_2 <> . then
                Numeric_Result = trim(Numeric_Result) ||trim(left(separator_cd)) || trim(left(put(NUMERIC_VALUE_2, 11.5)));

            drop COMPARATOR_CD_1 NUMERIC_VALUE_1 separator_cd NUMERIC_VALUE_2;
        run;
        */

        UPDATE #TMP_Lab_Result_Val
        SET 	Numeric_Result = rtrim(COALESCE(COMPARATOR_CD_1,''))+rtrim(format(numeric_value_1,'0.#########') )
        WHERE NUMERIC_VALUE_1 IS not NULL;


        UPDATE #TMP_Lab_Result_Val
        SET	Numeric_Result = rtrim(COALESCE(Numeric_Result,'')) + rtrim((COALESCE(separator_cd,'')))
            + rtrim(format(numeric_value_2,'0.#########') )
        WHERE  NUMERIC_VALUE_2 IS not NULL;


        /* alter table #TMP_Lab_Result_Val
        drop column COMPARATOR_CD_1, NUMERIC_VALUE_1, separator_cd, NUMERIC_VALUE_2
        ;
        */


        /*-------------------------------------------------------


            Result_Comment_Group

        ---------------------------------------------------------*/

        /* -- vs

        data Lab_Result_val Test_Result_Grouping (keep=TEST_RESULT_Grp_Key lab_test_uid);
        SET  Lab_Result_val;
             TEST_RESULT_Grp_Key = TEST_RESULT_Grp_Key;
            output Lab_Result_val Test_Result_Grouping;
        run;
        */


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


        /*
        /*Setting value for Test_Result_Val_Key column*/
        data Lab_Result_Val;
            SET Lab_Result_Val;
            IF Test_Result_Grp_Key <> . then Test_Result_Val_Key = Test_Result_Grp_Key;
        run;
        */

        UPDATE #TMP_Lab_Result_Val
        SET Test_Result_Val_Key = Test_Result_Grp_Key
        WHERE Test_Result_Grp_Key IS NOT NULL;


        /*
        proc sort tagsort data = Lab_Result_Val;
            by lab_test_uid DESCENDING lab_result_txt_seq;

        data New_Lab_Result_Val (drop = lab_result_txt_seq);
          SET Lab_Result_Val;
            by lab_test_uid;

            Length v_lab_result_val_txt $10000;
            RetaIN v_lab_result_val_txt;

            IF first.lab_test_uid then
                v_lab_result_val_txt = trim(lab_result_txt_val);
     else
      /* v_lab_result_val_txt = (trim(lab_result_txt_val) || v_lab_result_val_txt);  */
                v_lab_result_val_txt = (trim(lab_result_txt_val) || ' ' || v_lab_result_val_txt);


            IF last.lab_test_uid then
                output;
        run;

        */

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


        /*
        data Lab_Result_Val (drop = Lab_Result_Txt_Val);
         SET New_Lab_Result_Val;
         rename v_lab_result_val_txt = lab_result_txt_val;
        run;
        */

        UPDATE #TMP_Lab_Result_Val
        SET lab_result_txt_val = ( SELECT v_lab_result_val_txt
                                   FROM  #TMP_New_Lab_Result_Val tnl
                                   WHERE tnl.lab_test_uid = #TMP_Lab_Result_Val.lab_test_uid);

        /*

        data Lab_Result_Val;
            SET Lab_Result_Val;
            IF record_status_cd = '' then record_status_cd = 'ACTIVE';
            IF record_status_cd = 'UNPROCESSED' then record_status_cd = 'ACTIVE';
            IF record_status_cd = 'PROCESSED' then record_status_cd = 'ACTIVE';
            IF record_status_cd = 'LOG_DEL' then record_status_cd = 'INACTIVE';
        run;

        DATA Lab_Result_Val;
        SET Lab_Result_Val;
        RDB_LAST_REFRESH_TIME=DATETIME();
        RUN;
        */

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


        DELETE
        FROM #TMP_Lab_Result_Val
        WHERE Test_Result_Val_Key = 1;


        /* Update Lab_Test Keys */

        /* Test_Result_Grp_Key */


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


        -- create table Lab_Test_Result2 AS

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

        /*
        proc sort tagsort data = lab_test_result2;
            by Lab_test_uid;
        */


        /* Patient Key */
        /* bad data seen for a order test without patient, will reseach later*/

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
                    LEFT JOIN nrt_observation no2 ON no2.observation_uid = tst.LAB_TEST_UID
                    LEFT JOIN d_patient AS psn
                              ON no2.patient_id = psn.patient_uid
                                  AND psn.patient_key <> 1;

        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Test_Result3',* FROM #TMP_Lab_Test_Result3;


        /*
        quit;
        data Lab_Test_Result3;
        SET Lab_Test_Result3;
        IF morb_rpt_key>1 then PATIENT_KEY=morb_patient_key;
        IF morb_rpt_key>1 then Condition_Key=morb_Condition_Key;
        IF morb_rpt_key>1 then Investigation_Key = morb_Investigation_Key;
        IF morb_rpt_key>1 then REPORTING_LAB_KEY= MORB_RPT_SRC_ORG_KEY;
        run;
        */


        UPDATE  #TMP_Lab_Test_Result3
        set
            PATIENT_KEY=morb_patient_key,
            Condition_Key=morb_Condition_Key,
            Investigation_Key = morb_Investigation_Key,
            REPORTING_LAB_KEY= MORB_RPT_SRC_ORG_KEY
        WHERE morb_rpt_key>1;


        /* Performing Lab */
        -- create table Lab_Test_Result AS

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
                    LEFT JOIN nrt_observation AS no2 ON no2.observation_uid= tst.lab_test_uid
                    LEFT JOIN d_Organization  AS org
                              ON no2.performing_organization_id = org.Organization_uid
                                  AND org.Organization_key <> 1;


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_Lab_Test_Result',* FROM #TMP_Lab_Test_Result;


        /*
        proc sort tagsort data = Test_Result_Grouping nodupkey;
            by test_result_grp_key;

        proc sql;
        quit;
        data Test_Result_Grouping;
            SET Test_Result_Grouping; run;
        DATA Test_Result_Grouping;
        SET Test_Result_Grouping;
        RDB_LAST_REFRESH_TIME=DATETIME();
		 RUN;
        proc sql;

        DELETE FROM TEST_RESULT_GROUPING WHERE test_result_grp_key=1;
        DELETE FROM TEST_RESULT_GROUPING WHERE test_result_grp_key=.;
        DELETE FROM TEST_RESULT_GROUPING WHERE TEST_RESULT_GRP_KEY NOT IN (SELECT TEST_RESULT_GRP_KEY FROM LAB_RESULT_VAL);
        */


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'DELETING #TMP_TEST_RESULT_GROUPING ';


        CREATE NONCLUSTERED INDEX [idx_TMP_LAB_RESULT_VAL_tp_hp_key] ON #TMP_LAB_RESULT_VAL
            (
             [test_result_grp_key] ASC
                );

        DELETE FROM #TMP_TEST_RESULT_GROUPING WHERE test_result_grp_key=1;
        DELETE FROM #TMP_TEST_RESULT_GROUPING WHERE test_result_grp_key IS NULL;
        DELETE FROM #TMP_TEST_RESULT_GROUPING
        WHERE TEST_RESULT_GRP_KEY NOT IN (SELECT TEST_RESULT_GRP_KEY FROM #TMP_LAB_RESULT_VAL);


        /*
 		quit;

        -- %dbload(TEST_RESULT_GROUPING, TEST_RESULT_GROUPING);
        */

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'GENERATING TEST_RESULT_GROUPING ';


        INSERT INTO TEST_RESULT_GROUPING
        ([TEST_RESULT_GRP_KEY]
        ,[LAB_TEST_UID]
        ,[RDB_LAST_REFRESH_TIME])
        SELECT [TEST_RESULT_GRP_KEY]
                ,[LAB_TEST_UID],
               CAST( NULL AS datetime) AS [RDB_LAST_REFRESH_TIME]
        FROM #TMP_TEST_RESULT_GROUPING;


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_TEST_RESULT_GROUPING',* FROM #TMP_TEST_RESULT_GROUPING;
        IF @pDebug = 'true' SELECT 'DEBUG: TMP_LAB_RESULT_VAL_FINAL',* FROM #TMP_LAB_RESULT_VAL_FINAL;


        --%dbload(Lab_Result_Val, Lab_Result_Val);
        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;


        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'INSERTING INTO  LAB_RESULT_VAL ';


        INSERT INTO LAB_RESULT_VAL
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
        SELECT TEST_RESULT_GRP_KEY
             , SUBSTRING(NUMERIC_RESULT ,1,50)
             , SUBSTRING(RESULT_UNITS ,1,50)
             , rtrim(ltrim(SUBSTRING(LAB_RESULT_TXT_VAL ,1,2000)))
             , SUBSTRING(REF_RANGE_FRM ,1,20)
             , SUBSTRING(REF_RANGE_TO ,1,20)
             , SUBSTRING(TEST_RESULT_VAL_CD ,1,20)
             , SUBSTRING(rtrim(TEST_RESULT_VAL_CD_DESC) ,1,300)
             , SUBSTRING(TEST_RESULT_VAL_CD_SYS_CD ,1,100)
             , SUBSTRING(TEST_RESULT_VAL_CD_SYS_NM ,1,100)
             , SUBSTRING(ALT_RESULT_VAL_CD ,1,50)
             , SUBSTRING(rtrim(ALT_RESULT_VAL_CD_DESC) ,1,100)
             , SUBSTRING(ALT_RESULT_VAL_CD_SYS_CD ,1,50)
             , SUBSTRING(ALT_RESULT_VAL_CD_SYSTEM_NM ,1,100)
             ,TEST_RESULT_VAL_KEY
             , SUBSTRING(RECORD_STATUS_CD ,1,8)
             ,FROM_TIME
             ,TO_TIME
             ,LAB_TEST_UID
             , GETDATE()
        FROM #TMP_LAB_RESULT_VAL_FINAL;


        /*

        data Result_Comment_Group;
            SET Result_Comment_Group;
            RDB_LAST_REFRESH_TIME=DATETIME();
        run;
        --%dbload(Result_Comment_Group, Result_Comment_Group);
        */


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;


        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'INSERTING INTO RESULT_COMMENT_GROUP ';


        INSERT INTO  [dbo].[RESULT_COMMENT_GROUP]
        ([RESULT_COMMENT_GRP_KEY]
        ,[LAB_TEST_UID]
        ,[RDB_LAST_REFRESH_TIME]
        )
        SELECT [RESULT_COMMENT_GRP_KEY]
             ,[LAB_TEST_UID]
             , GETDATE()
        FROM #TMP_RESULT_COMMENT_GROUP;


        IF @pDebug = 'true' SELECT 'DEBUG: TMP_RESULT_COMMENT_GROUP', * FROM #TMP_RESULT_COMMENT_GROUP;


        --  SELECT ' i am here';

        /*
        data Lab_Result_Comment;
            SET Lab_Result_Comment;
            IF record_status_cd = '' then record_status_cd = 'ACTIVE';
            IF record_status_cd = 'UNPROCESSED' then record_status_cd = 'ACTIVE';
            IF record_status_cd = 'PROCESSED' then record_status_cd = 'ACTIVE';
            IF record_status_cd = 'LOG_DEL' then record_status_cd = 'INACTIVE';
        run;


        DATA Lab_Result_Comment;
        SET Lab_Result_Comment;
        RDB_LAST_REFRESH_TIME=DATETIME();
        RUN;


        */

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


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;


        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'INSERTING INTO Lab_Result_Comment ';


        --%dbload(LAB_RESULT_COMMENT, Lab_Result_Comment);
        INSERT INTO Lab_Result_Comment
        ([LAB_TEST_UID]
        ,[LAB_RESULT_COMMENT_KEY]
        ,[LAB_RESULT_COMMENTS]
        ,[RESULT_COMMENT_GRP_KEY]
        ,[RECORD_STATUS_CD]
        ,[RDB_LAST_REFRESH_TIME]
        )
        SELECT LAB_TEST_UID
             ,LAB_RESULT_COMMENT_KEY
             , SUBSTRING(LAB_RESULT_COMMENTS ,1,2000)
             ,RESULT_COMMENT_GRP_KEY
             , SUBSTRING(RECORD_STATUS_CD ,1,8)
             ,[RDB_LAST_REFRESH_TIME]
        FROM #TMP_New_Lab_Result_Comment_FINAL;


        /*

      DELETE * FROM Lab_Test_Result WHERE lab_test_key IS NULL;


      run;
      proc sort data = Lab_Test_Result;
          by root_ordered_test_pntr lab_test_uid;
      data Lab_Test_Result (drop = root_ordered_test_pntr);
          SET Lab_Test_Result;
          IF record_status_cd = '' then record_status_cd = 'ACTIVE';
          IF record_status_cd = 'UNPROCESSED' then record_status_cd = 'ACTIVE';
          IF record_status_cd = 'PROCESSED' then record_status_cd = 'ACTIVE';
          IF record_status_cd = 'LOG_DEL' then record_status_cd = 'INACTIVE';
      run;


      DATA Lab_Test_Result;
      SET Lab_Test_Result;
      RDB_LAST_REFRESH_TIME=DATETIME();
      RUN;
      */

        DELETE FROM #TMP_Lab_Test_Result WHERE lab_test_key IS NULL;

        UPDATE #TMP_Lab_Test_Result
        SET record_status_cd = 'ACTIVE'
        WHERE record_status_cd IN ( '' ,'UNPROCESSED' ,'PROCESSED' )
           OR  record_status_cd = NULL;

        UPDATE #TMP_Lab_Test_Result
        SET record_status_cd = 'INACTIVE'
        WHERE record_status_cd = 'LOG_DEL';


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'INSERTING INTO LAB_TEST_RESULT ';

        --%dbload(Lab_Test_Result, Lab_Test_Result);
        INSERT INTO LAB_TEST_RESULT
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
        SELECT [LAB_TEST_KEY]
             ,[LAB_TEST_UID]
             ,[RESULT_COMMENT_GRP_KEY]
             ,[TEST_RESULT_GRP_KEY]
             ,[PERFORMING_LAB_KEY]
             ,COALESCE([PATIENT_KEY],'')
             ,COALESCE([COPY_TO_PROVIDER_KEY],'')
             ,COALESCE([LAB_TEST_TECHNICIAN_KEY],'')
             ,COALESCE([SPECIMEN_COLLECTOR_KEY],'')
             ,COALESCE([ORDERING_ORG_KEY],'')
             ,COALESCE([REPORTING_LAB_KEY],'')
             ,COALESCE([CONDITION_KEY],'')
             ,COALESCE([LAB_RPT_DT_KEY],'')
             ,COALESCE([MORB_RPT_KEY],'')
             ,COALESCE([INVESTIGATION_KEY],'')
             ,COALESCE([LDF_GROUP_KEY],'')
             ,COALESCE([ORDERING_PROVIDER_KEY],'')
             , SUBSTRING(RECORD_STATUS_CD ,1,8)
             , GETDATE() AS [RDB_LAST_REFRESH_TIME]
        FROM #TMP_LAB_TEST_RESULT;


        IF @pDebug = 'true' SELECT 'TMP_LAB_TEST_RESULT', * FROM #TMP_LAB_TEST_RESULT;


        /*

        /**Delete Temporary Data sets**/
        /**Delete temporary data set**/
        PROC datasets library = work nolist;

        delete
             Lab_Result_Val
            New_Lab_Result_Val
            Result_And_R_Result
            Lab_Result_Comment
            Result_Comment_Group
            lab_test_result
          lab_test_result1
            lab_test_result2
            lab_test_result3
            Test_Result_Grouping
            Lab_Test
        ;
        run;
        quit;
        */


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

        --IF OBJECT_ID('#TMP_New_Lab_Result_Comment_FINAL', 'U') IS NOT NULL
        --DROP TABLE   .[dbo].[TMP_New_Lab_Result_Comment_FINAL];

        IF OBJECT_ID('#TMP_Result_Comment_Group', 'U') IS NOT NULL
            DROP TABLE  #TMP_Result_Comment_Group;


        --IF OBJECT_ID('#TMP_Lab_Result_Val', 'U') IS NOT NULL
        --DROP TABLE   #TMP_Lab_Result_Val;

        --IF OBJECT_ID('#TMP_TEST_RESULT_GROUPING', 'U') IS NOT NULL
        --DROP TABLE   #[TMP_TEST_RESULT_GROUPING];

        IF OBJECT_ID('#TMP_New_Lab_Result_Val', 'U') IS NOT NULL
            DROP TABLE  #TMP_New_Lab_Result_Val;

        IF OBJECT_ID('#TMP_Lab_Test_Result2', 'U') IS NOT NULL
            DROP TABLE  #TMP_Lab_Test_Result2;

        IF OBJECT_ID('#TMP_Lab_Test_Result3', 'U') IS NOT NULL
            DROP TABLE   #TMP_Lab_Test_Result3;

        --IF OBJECT_ID('#TMP_Lab_Test_Result', 'U') IS NOT NULL
        --   DROP TABLE     #TMP_Lab_Test_Result;


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










