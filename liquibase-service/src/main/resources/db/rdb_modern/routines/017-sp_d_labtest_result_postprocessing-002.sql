CREATE OR ALTER PROCEDURE [dbo].[sp_d_labtest_result_postprocessing]
@batch_id BIGINT
as

BEGIN

    --
--UPDATE ACTIVITY_LOG_DETAIL SET 
--START_DATE=DATETIME();
-- dec
    DECLARE @RowCount_no INT ;
    DECLARE @Proc_Step_no FLOAT = 0 ;
    DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
    DECLARE @batch_start_time datetime2(7) = null ;
    DECLARE @batch_end_time datetime2(7) = null ;

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';




        BEGIN TRANSACTION;
        --create table Lab_Test_Result1 as

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

--create table updated_observation_List as


        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_lab_test_resultInit ';



        IF OBJECT_ID('rdb.dbo.TMP_lab_test_resultInit', 'U') IS NOT NULL
            drop table   rdb.dbo.TMP_lab_test_resultInit ;
        -- go



        select
            tst.lab_test_key,
            tst.root_ordered_test_pntr,
            tst.lab_test_uid,
            tst.record_status_cd,
            tst.Root_Ordered_Test_Pntr as Root_Ordered_Test_Pntr2 ,
            tst.lab_rpt_created_dt,
            coalesce(morb.morb_rpt_key,1) 'MORB_RPT_KEY' ,
            morb_event.PATIENT_KEY as morb_patient_key,
            morb_event.Condition_Key as morb_Condition_Key,
            morb_event.Investigation_Key as morb_Investigation_Key,
            morb_event.MORB_RPT_SRC_ORG_KEY as MORB_RPT_SRC_ORG_KEY
        into rdb..TMP_lab_test_resultInit
        from  rdb..TMP_D_LAB_TEST_N as tst
                  /* Morb report */
                  left join nbs_odse..act_relationship	as act
                            on tst.Lab_test_Uid = act.source_act_uid
                                and act.type_cd = 'LabReport'
                                and act.target_class_cd = 'OBS'
                                and act.source_class_cd = 'OBS'
                                and act.record_status_cd = 'ACTIVE'

                  left join rdb..Morbidity_Report	as morb
                            on act.target_act_uid = morb.Morb_rpt_uid
                  left join rdb..Morbidity_report_event morb_event on
            morb_event.morb_rpt_key= morb.morb_rpt_key
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_Lab_Test_Result1 ';


        IF OBJECT_ID('rdb.dbo.TMP_Lab_Test_Result1', 'U') IS NOT NULL
            drop table  rdb..TMP_Lab_Test_Result1;


        select
            tst.lab_test_key,
            tst.root_ordered_test_pntr,
            tst.lab_test_uid,
            tst.record_status_cd,
            tst.Root_Ordered_Test_Pntr as Root_Ordered_Test_Pntr2,
            tst.lab_rpt_created_dt,
            morb_rpt_key,
            tst.morb_patient_key,
            tst.morb_Condition_Key,
            tst.morb_Investigation_Key,
            tst.MORB_RPT_SRC_ORG_KEY,
            /*per1.person_key as Transcriptionist_Key,*/
            /*per2.person_key as Assistant_Interpreter_Key,*/
            /*per3.person_key as Result_Interpreter_Key,*/
            coalesce(per4.provider_key,1) as Specimen_Collector_Key,
            coalesce(per5.provider_key,1) as Copy_To_Provider_Key,
            coalesce(per6.provider_key,1) as Lab_Test_Technician_key,
            coalesce(org.Organization_key,1)		'REPORTING_LAB_KEY'  , -- as Reporting_Lab_Key,
            coalesce(prv.provider_key,1) 'ORDERING_PROVIDER_KEY'  , -- as Ordering_provider_key,
            coalesce(org2.Organization_key,1)	'ORDERING_ORG_KEY'  , -- as Ordering_org_key,
            coalesce(con.condition_key,1) 'CONDITION_KEY'  , -- as condition_key,
            coalesce(dat.Date_key,1) 						as LAB_RPT_DT_KEY,

            coalesce(inv.Investigation_key,1) 	'INVESTIGATION_KEY'  , -- as Investigation_key,
            coalesce(ldf_g.ldf_group_key,1)			as LDF_GROUP_KEY,
            tst.record_status_cd as record_status_cd2,
            cast ( null as  bigint) RESULT_COMMENT_GRP_KEY
        into rdb..TMP_Lab_Test_Result1
        from rdb..TMP_lab_test_resultInit as tst

                 /*get specimen collector*/
                 left join rdb..TMP_updated_participant as par4
                           on tst.Root_Ordered_Test_Pntr = par4.act_uid
                               and par4.type_cd = 'PATSBJ'
                 left join nbs_odse..role as r1
                           on par4.subject_entity_uid = r1.subject_entity_uid
                               and r1.cd = 'SPP'
                               and r1.subject_class_cd = 'PROV'
                               and r1.scoping_class_cd = 'PSN'
                 left join rdb..d_provider as per4
                           on r1.scoping_entity_uid = per4.provider_uid

            /*get copy_to_provider key*/
                 left join rdb..TMP_updated_participant as par5
                           on tst.Root_Ordered_Test_Pntr = par5.act_uid
                               and par5.type_cd = 'PATSBJ'
                 left join nbs_odse..role as r2 	on par5.subject_entity_uid = r2.subject_entity_uid
            and r2.cd ='CT'
            AND r2.subject_class_cd = 'PROV'
                 left join rdb..d_provider as per5	on r2.scoping_entity_uid = per5.provider_uid

            /*get lab_test_technician*/

                 left join rdb..TMP_updated_participant as par6
                           on tst.Root_Ordered_Test_Pntr = par6.act_uid
                               and par6.act_class_cd = 'OBS'
                               and par6.subject_class_cd = 'PSN'
                               and par6.type_cd = 'PRF'
                 left join rdb..d_provider as per6
                           on par6.subject_entity_uid = per6.provider_uid

            /* Ordering Provider */
                 left join rdb..TMP_updated_participant as par7
                           on tst.Lab_test_Uid = par7.act_uid
                               and par7.type_cd ='ORD'
                               and par7.act_class_cd ='OBS'
                               and par7.subject_class_cd = 'PSN'
                               and par7.record_status_cd ='ACTIVE'
                 left join	rdb..d_provider 	as prv
                              on	par7.subject_entity_uid = prv.provider_uid

            /* Reporting_Lab*/
                 left join rdb..TMP_updated_participant as par
                           on tst.Lab_test_uid = par.act_uid
                               and par.type_cd = 'AUT'
                               and par.record_status_cd = 'ACTIVE'
                               and par.act_class_cd = 'OBS'
                               and par.subject_class_cd = 'ORG'
                 left join rdb..d_Organization	as org
                           on par.subject_entity_uid = org.Organization_uid

            /* Ordering Facility */
                 left join rdb..TMP_updated_participant as par8
                           on tst.Lab_Test_uid = par8.act_uid
                               /*and par2.type_cd = 'ORG'*/
                               and par8.type_cd = 'ORD'
                               and par8.record_status_cd = 'ACTIVE'
                               and par8.act_class_cd = 'OBS'
                               and par8.subject_class_cd = 'ORG'
                 left join rdb..d_Organization	as org2
                           on par8.subject_entity_uid = org2.Organization_uid

            /* Conditon, it's just program area */

            /*if we add a program area to the Lab_Report Dimension we probably don't
            even need a condition dimension.  Even though it's OK with the Dimension Modeling
            principle for adding a prog_area_cd row to the condition, it sure will cause
            some confusion among users.  There's no "disease" on the input.
            */
                 left join nbs_odse..observation 	as obs
                           on tst.Lab_test_Uid = obs.observation_uid
                 left join	rdb..Condition	as con
                              on	obs.prog_area_cd  = con.program_area_cd
                                  and con.condition_cd is null


            /*LDF_GRP_KEY*/
            --left join rdb..ldf_group as ldf_g 	on tst.Lab_test_UID = ldf_g.business_object_uid --VS
                 left join rdb..ldf_group as ldf_g 	on tst.Lab_test_UID = ldf_g.ldf_group_key


            /* Lab_Rpt_Dt */ --VS	left join rdb..rdb_datetable 		as dat
                 left join rdb..rdb_date as dat 	on  DATEADD(d,0,DATEDIFF(d,0,[lab_rpt_created_dt])) = dat.DATE_MM_DD_YYYY


            /* PHC */
                 left join nbs_odse..act_relationship	as act2
                           on tst.Lab_Test_Uid = act2.source_act_uid
                               and act2.type_cd = 'LabReport'
                               and act2.target_class_cd = 'CASE'
                               and act2.source_class_cd = 'OBS'
                               and act2.record_status_cd = 'ACTIVE'
                 left join rdb..investigation		as inv
                           on act2.target_act_uid = inv.case_uid
        ;

        /*-------------------------------------------------------

            Lab_Result_Comment Dimension

            Note: User Comments for Result Test Object (Lab104)

        ---------------------------------------------------------*/


        --create table Result_And_R_Result;

        /** -- VS

        --create table Result_And_R_Result;

        data Result_And_R_Result;
        set rdb..Lab_Test;
            if (Lab_Test_Type = 'Result' or Lab_Test_Type IN ('R_Result', 'I_Result',  'Order_rslt'));
        run;

        proc sql;
        */

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_Result_And_R_Result ';



        IF OBJECT_ID('rdb.dbo.TMP_Result_And_R_Result', 'U') IS NOT NULL
            drop table  rdb..TMP_Result_And_R_Result;


        select *
        into rdb..TMP_Result_And_R_Result
        from rdb..tmp_Lab_Test_Final
        where  (Lab_Test_Type = 'Result' or Lab_Test_Type IN ('R_Result', 'I_Result',  'Order_rslt'))
        ;



        -- create table Lab_Result_Comment as

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_Lab_Result_Comment ';

        IF OBJECT_ID('rdb.dbo.TMP_Lab_Result_Comment', 'U') IS NOT NULL
            drop table   rdb..TMP_Lab_Result_Comment ;

        select
            lab104.lab_test_uid,
            REPLACE(REPLACE(ovt.value_txt, CHAR(13), ' '), CHAR(10), ' ')	'LAB_RESULT_COMMENTS'  , -- asLab_Result_Comments,
            ovt.obs_value_txt_seq	'LAB_RESULT_TXT_SEQ'  , -- as Lab_Result_Txt_Seq,
            lab104.record_status_cd
        into rdb..TMP_Lab_Result_Comment
        from
            rdb..TMP_Result_And_R_Result		as lab104,
            nbs_odse..obs_value_txt	as ovt
        where 	ovt.value_txt is not null
          and ovt.txt_type_cd = 'N'
          and ovt.OBS_VALUE_TXT_SEQ <>  0
          and ovt.observation_uid =  lab104.lab_test_uid

        ;




        /*************************************************************
        Added  support wrapping of comments when comments are
        stored in multiple obs_value_txt rows in ODS
        */


        /*
        proc sort data = Lab_Result_Comment;
        by lab_test_uid DESCENDING lab_result_txt_seq;


        data New_Lab_Result_Comment (drop = lab_result_txt_seq);
          set Lab_Result_Comment;
            by lab_test_uid;

            Length v_lab_result_val_comments $10000;
            Retain v_lab_result_val_comments;

        */

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_New_Lab_Result_Comment ';

        IF OBJECT_ID('rdb.dbo.TMP_New_Lab_Result_Comment', 'U') IS NOT NULL
            drop table  rdb..TMP_New_Lab_Result_Comment;

        select *,
               cast( null as varchar(2000)) as v_lab_result_val_comments
        into rdb..TMP_New_Lab_Result_Comment
        from rdb..TMP_Lab_Result_Comment
        ;

        /*
            if first.lab_test_uid then
                v_lab_result_val_comments = trim(lab_result_comments);
            else
                v_lab_result_val_comments = (trim(lab_result_comments) || ' ' || v_lab_result_val_comments);

            if last.lab_test_uid then
                output;
        run;
        */
        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_New_Lab_Result_Comment_grouped ';


        create index idx_TMP_New_Lab_Result_Comment_uid on  rdb.dbo.TMP_New_Lab_Result_Comment (lab_test_uid);


        IF OBJECT_ID('rdb.dbo.TMP_New_Lab_Result_Comment_grouped', 'U') IS NOT NULL
            drop table  rdb.dbo.TMP_New_Lab_Result_Comment_grouped;


        SELECT DISTINCT LRV.lab_test_uid,
                        SUBSTRING(
                                (
                                    SELECT ' '+ST1.lab_result_comments  AS [text()]
                                    FROM rdb.dbo.TMP_New_Lab_Result_Comment ST1
                                    WHERE ST1.lab_test_uid = LRV.lab_test_uid
                                    ORDER BY ST1.lab_test_uid,ST1.lab_result_txt_seq
                                    FOR XML PATH ('')
                                ), 2, 2000) v_lab_result_val_txt
        into rdb.dbo.TMP_New_Lab_Result_Comment_grouped
        FROM rdb.dbo.TMP_New_Lab_Result_Comment LRV

        ;

        update rdb.dbo.TMP_New_Lab_Result_Comment
        set lab_result_comments = ( select v_lab_result_val_txt
                                    from  rdb.dbo.TMP_New_Lab_Result_Comment_grouped tnl
                                    where tnl.lab_test_uid = rdb.dbo.TMP_New_Lab_Result_Comment.lab_test_uid)
        ;


        update [RDB].[dbo].[TMP_New_Lab_Result_Comment]
        set [LAB_RESULT_COMMENTS] = null
        where [LAB_RESULT_COMMENTS] = '#x20;'
        ;



        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_New_Lab_Result_Comment_FINAL ';

        IF OBJECT_ID('rdb.dbo.TMP_New_Lab_Result_Comment_FINAL', 'U') IS NOT NULL
            drop table   [RDB].[dbo].[TMP_New_Lab_Result_Comment_FINAL];

        CREATE TABLE rdb.[dbo].[TMP_New_Lab_Result_Comment_FINAL](
                                                                     Lab_Result_Comment_Key_id  [int] IDENTITY(1,1) NOT NULL,
                                                                     [LAB_TEST_UID] [bigint] NULL,
                                                                     [LAB_RESULT_COMMENT_KEY] [bigint]  NULL,
                                                                     [LAB_RESULT_COMMENTS] [varchar](2000) NULL,
                                                                     [RESULT_COMMENT_GRP_KEY] [bigint]  NULL,
                                                                     [RECORD_STATUS_CD] [varchar](8)  NULL,
                                                                     [RDB_LAST_REFRESH_TIME] [datetime] NULL
        )
        ;


        INSERT INTO [RDB].[dbo].[TMP_New_Lab_Result_Comment_FINAL]
        SELECT distinct [lab_test_uid]
                      ,NULL
                      ,[LAB_RESULT_COMMENTS]
                      ,null
                      ,[record_status_cd]
                      , null
        FROM [RDB].[dbo].[TMP_New_Lab_Result_Comment]
        ;

        /*
        data Lab_Result_Comment (drop = Lab_Result_Comments);
         set New_Lab_Result_Comment;
         rename v_lab_result_val_comments = lab_result_comments;
        run;


        data rdb..Lab_Result_Comment;
        set Lab_Result_Comment; run;
        */




        /*
        /*************************************************************/

        proc sort data = Lab_Result_Comment nodupkey; by Lab_test_uid; run;
        %assign_key(Lab_Result_Comment, Lab_Result_Comment_Key);

        proc sql;
        ALTER TABLE Lab_Result_Comment ADD Lab_Result_Comment_Key_MAX_VAL  NUMERIC;
        UPDATE  Lab_Result_Comment SET Lab_Result_Comment_Key_MAX_VAL=(SELECT MAX(Lab_Result_Comment_Key) FROM rdb..Lab_Result_Comment);
        quit;
        DATA Lab_Result_Comment;
        SET Lab_Result_Comment;
        IF Lab_Result_Comment_Key_MAX_VAL  <> . AND Lab_Result_Comment_Key<> 1 THEN Lab_Result_Comment_Key= Lab_Result_Comment_Key+Lab_Result_Comment_Key_MAX_VAL;
        RUN;
        t
        */

        UPDATE rdb.dbo.[TMP_New_Lab_Result_Comment_FINAL]
        SET [LAB_RESULT_COMMENT_KEY]= Lab_Result_Comment_Key_id
            + coalesce((SELECT MAX(Lab_Result_Comment_Key) FROM rdb..Lab_Result_Comment),1)
        ;



        /*


        data Lab_Result_Comment;
        set Lab_Result_Comment;
        Result_Comment_Grp_Key = Lab_Result_Comment_Key;
        run;
        data Result_Comment_Group (Keep = Result_Comment_Grp_Key lab_test_uid);
            Set Lab_Result_Comment;
        run;
        */
        UPDATE rdb.dbo.[TMP_New_Lab_Result_Comment_FINAL]
        SET Result_Comment_Grp_Key = [LAB_RESULT_COMMENT_KEY]
        ;




        /*
        proc sort data=result_comment_group;
            by Result_Comment_Grp_Key;
        proc sql;
        delete from Result_Comment_Group where result_comment_grp_key=1;
        delete from Result_Comment_Group where result_comment_grp_key=.;
        quit;

        */

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_Result_Comment_Group ';

        IF OBJECT_ID('rdb.dbo.TMP_Result_Comment_Group', 'U') IS NOT NULL
            drop table  rdb.dbo.TMP_Result_Comment_Group;


        select
            distinct rcg.Lab_Result_Comment_Key as [RESULT_COMMENT_GRP_KEY]
                   , rcg.[LAB_TEST_UID]
        into rdb.dbo.tmp_Result_Comment_Group
        from  rdb.dbo.[TMP_New_Lab_Result_Comment_FINAL]  rcg
        --where  rcg.Lab_Result_Comment_Key <> 1 and rcg.Lab_Result_Comment_Key is not null
        order by  rcg.Lab_Result_Comment_Key
        ;

        IF NOT EXISTS (SELECT * FROM rdb.dbo.Result_Comment_Group WHERE [RESULT_COMMENT_GRP_KEY]=1)
            insert into rdb.dbo.tmp_Result_Comment_Group values ( 1,null);



        /* --VS

        DATA lab_test_result1;
            MERGE Result_Comment_Group lab_test_result1;
            by lab_test_uid;
        run;

        data lab_test_result1;
        set lab_test_result1;



        if Result_Comment_Grp_Key =.  then Result_Comment_Grp_Key = 1;
        */

        UPDATE RDB..tmp_lab_test_result1
        set [RESULT_COMMENT_GRP_KEY] = ( select [RESULT_COMMENT_GRP_KEY]
                                         from rdb.dbo.tmp_Result_Comment_Group trcg
                                         where trcg.lab_test_uid = rdb.dbo.tmp_lab_test_result1.lab_test_uid)
        ;


        UPDATE RDB..tmp_lab_test_result1
        set [RESULT_COMMENT_GRP_KEY] = 1
        where [RESULT_COMMENT_GRP_KEY] is null
        ;


        /*
        /*Creating Result_Comment_Group **/

        data Result_Comment_Group;
            set Result_Comment_Group;
        run;

        data lab_result_comment;
        set lab_result_comment;
        where Lab_Result_Comment_Key <> 1; run;
        proc sort data = Lab_Result_Comment nodupkey; by Lab_test_uid; run;

        */





        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;


        /*-------------------------------------------------------

Lab_Result_Val Dimension
Test_Result_Grouping Dimension

---------------------------------------------------------*/

        --create table Lab_Result_Val as



        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_Lab_Result_Val ';

        IF OBJECT_ID('rdb.dbo.TMP_Lab_Result_Val', 'U') IS NOT NULL
            drop table   rdb.dbo.TMP_Lab_Result_Val;


        CREATE TABLE rdb.dbo.TMP_LAB_RESULT_VAL(
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
        ) ON [PRIMARY]
        ;

        insert into rdb..TMP_Lab_Result_Val
        select
            rslt.lab_test_uid,
            REPLACE(REPLACE(otxt.value_txt, CHAR(13), ' '), CHAR(10), ' ') 		'LAB_RESULT_TXT_VAL'  , -- as Lab_Result_Txt_Val,
            otxt.obs_value_txt_seq			'LAB_RESULT_TXT_SEQ'  , -- as Lab_Result_Txt_Seq,
            onum.COMPARATOR_CD_1,
            onum.NUMERIC_VALUE_1,
            onum.separator_cd,
            onum.NUMERIC_VALUE_2,
            onum.numeric_unit_cd    	'Result_Units'  , -- asResult_Units,
            substring(onum.LOW_RANGE,1,20)					'REF_RANGE_FRM'  , -- as Ref_Range_Frm,
            substring(onum.HIGH_RANGE,1,20)				'REF_RANGE_TO'  , -- as Ref_Range_To,
            code.code						'TEST_RESULT_VAL_CD'  , -- as Test_result_val_cd,
            code.display_name				'TEST_RESULT_VAL_CD_DESC'  , -- as Test_result_val_cd_desc,
            code.CODE_SYSTEM_CD			'TEST_RESULT_VAL_CD_SYS_CD'  , -- as Test_result_val_cd_sys_cd,
            code.CODE_SYSTEM_DESC_TXT	'TEST_RESULT_VAL_CD_SYS_NM'  , -- as Test_result_val_cd_sys_nm,
            code.ALT_CD						'ALT_RESULT_VAL_CD'  , -- as Alt_result_val_cd,
            code.ALT_CD_DESC_TXT			'ALT_RESULT_VAL_CD_DESC'  , -- as Alt_result_val_cd_desc,
            code.ALT_CD_SYSTEM_CD		'ALT_RESULT_VAL_CD_SYS_CD'  , -- as Alt_result_val_cd_sys_cd,
            code.ALT_CD_SYSTEM_DESC_TXT	'ALT_RESULT_VAL_CD_SYSTEM_NM'  , -- as Alt_result_val_cd_sys_nm,
            date.from_time 'FROM_TIME'  , -- as from_time,
            date.to_time 'TO_TIME'  , -- as to_time,
            rslt.record_status_cd,
            NULL,
            NULL,
            NULL,
            NULL
        FROM	rdb..TMP_Result_And_R_Result		as rslt
                    LEFT JOIN nbs_odse..obs_value_txt	as otxt 		ON rslt.lab_test_uid = otxt.observation_uid
            and ((otxt.TXT_TYPE_CD is null) OR (rslt.ELR_IND = 'Y' AND otxt.TXT_TYPE_CD <>  'N'))
            --AND otxt.OBS_VALUE_TXT_SEQ =1
            /*
            Commented out because an ELR Test Result can have zero to many text result values
            AND otxt.OBS_VALUE_TXT_SEQ =1
            */

                    LEFT JOIN  nbs_odse..obs_value_numeric	as onum 	ON rslt.lab_test_uid = onum.observation_uid

                    LEFT JOIN nbs_odse..obs_value_coded		as code		ON rslt.lab_test_uid = code.observation_uid

                    LEFT JOIN nbs_odse..obs_value_date		as date 	ON rslt.lab_test_uid = date.observation_uid
        ;




        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' UPDATE  TMP_Lab_Result_Val ';


        /*
        quit;
        %assign_key(Lab_Result_Val,Test_Result_Grp_Key);

        proc sql;
        ALTER TABLE Lab_Result_Val ADD test_result_grp_key_MAX_VAL  NUMERIC;
        UPDATE  Lab_Result_Val SET test_result_grp_key_MAX_VAL=(SELECT MAX(test_result_grp_key) FROM rdb..Test_Result_Grouping);
        quit;
        DATA Lab_Result_Val;
        SET Lab_Result_Val;
        if test_result_grp_key_MAX_VAL = 1 then test_result_grp_key_MAX_VAL=.;
        IF test_result_grp_key_MAX_VAL  <> . AND test_result_grp_key<> 1 THEN test_result_grp_key= test_result_grp_key+test_result_grp_key_MAX_VAL;
        RUN;
        */

        UPDATE rdb.dbo.TMP_Lab_Result_Val
        SET test_result_grp_key= test_result_grp_id
            + coalesce((SELECT MAX(test_result_grp_key) FROM RDB.dbo.TEST_RESULT_GROUPING),1)
        ;


        UPDATE rdb.dbo.TMP_Lab_Result_Val
        set Lab_Result_Txt_Val = null
        where ltrim(rtrim(Lab_Result_Txt_Val)) = ''
        ;

        /*

        proc sort tagsort data = Lab_Result_Val;
            by lab_test_uid;

        data Lab_Result_Val;
            set Lab_Result_Val;
            format Numeric_Result	$50.;
        */
        /*
            if NUMERIC_VALUE_1 <> . then
                Numeric_Result = trim(COMPARATOR_CD_1)||trim(left(put(NUMERIC_VALUE_1, 11.5)));
            if NUMERIC_VALUE_2 <> . then
                Numeric_Result = trim(Numeric_Result) ||trim(left(separator_cd)) || trim(left(put(NUMERIC_VALUE_2, 11.5)));

            drop COMPARATOR_CD_1 NUMERIC_VALUE_1 separator_cd NUMERIC_VALUE_2;
        run;
        */

        UPDATE rdb.dbo.TMP_Lab_Result_Val
        set 	Numeric_Result = rtrim(coalesce(COMPARATOR_CD_1,''))+rtrim(format(numeric_value_1,'0.#########') )
        where NUMERIC_VALUE_1 is not null
        ;


        UPDATE rdb.dbo.TMP_Lab_Result_Val

        set	Numeric_Result = rtrim(coalesce(Numeric_Result,'')) + rtrim((coalesce(separator_cd,'')))
            + rtrim(format(numeric_value_2,'0.#########') )
        where  NUMERIC_VALUE_2 is not null
        ;

        /* alter table rdb.dbo.TMP_Lab_Result_Val
        drop column COMPARATOR_CD_1, NUMERIC_VALUE_1, separator_cd, NUMERIC_VALUE_2
        ;
        */



        /*-------------------------------------------------------


            Result_Comment_Group

        ---------------------------------------------------------*/

        /* -- vs

        data Lab_Result_val Test_Result_Grouping (keep=TEST_RESULT_Grp_Key lab_test_uid);
        set  Lab_Result_val;
             TEST_RESULT_Grp_Key = TEST_RESULT_Grp_Key;
            output Lab_Result_val Test_Result_Grouping;
        run;
        */

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_TEST_RESULT_GROUPING ';

        IF OBJECT_ID('rdb.dbo.TMP_TEST_RESULT_GROUPING', 'U') IS NOT NULL
            drop table   [RDB].[dbo].[TMP_TEST_RESULT_GROUPING];



        SELECT distinct [TEST_RESULT_GRP_KEY]
                      ,[LAB_TEST_UID]
        --,[RDB_LAST_REFRESH_TIME]
        into [RDB].[dbo].[TMP_TEST_RESULT_GROUPING]
        from rdb.dbo.TMP_Lab_Result_Val
        ;


        /*
        /*Setting value for Test_Result_Val_Key column*/
        data Lab_Result_Val;
            set Lab_Result_Val;
            if Test_Result_Grp_Key <> . then Test_Result_Val_Key = Test_Result_Grp_Key;
        run;
        */

        UPDATE rdb.dbo.TMP_Lab_Result_Val
        set Test_Result_Val_Key = Test_Result_Grp_Key
        where Test_Result_Grp_Key is not null
        ;



        /*
        proc sort tagsort data = Lab_Result_Val;
            by lab_test_uid DESCENDING lab_result_txt_seq;

        data New_Lab_Result_Val (drop = lab_result_txt_seq);
          set Lab_Result_Val;
            by lab_test_uid;

            Length v_lab_result_val_txt $10000;
            Retain v_lab_result_val_txt;

            if first.lab_test_uid then
                v_lab_result_val_txt = trim(lab_result_txt_val);
            else
                /* v_lab_result_val_txt = (trim(lab_result_txt_val) || v_lab_result_val_txt);  */
                v_lab_result_val_txt = (trim(lab_result_txt_val) || ' ' || v_lab_result_val_txt);


            if last.lab_test_uid then
                output;
        run;

        */

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_New_Lab_Result_Val ';

        IF OBJECT_ID('rdb.dbo.TMP_New_Lab_Result_Val', 'U') IS NOT NULL
            drop table  rdb.dbo.TMP_New_Lab_Result_Val;


        SELECT DISTINCT LRV.lab_test_uid,
                        SUBSTRING(
                                (
                                    SELECT ' '+ST1.lab_result_txt_val  AS [text()]
                                    FROM rdb.dbo.TMP_Lab_Result_Val ST1
                                    WHERE ST1.lab_test_uid = LRV.lab_test_uid
                                    ORDER BY ST1.lab_test_uid,ST1.lab_result_txt_seq
                                    FOR XML PATH ('')
                                ), 2, 2000) v_lab_result_val_txt
        into rdb.dbo.TMP_New_Lab_Result_Val
        FROM rdb.dbo.TMP_Lab_Result_Val LRV

        ;



        /*
        data Lab_Result_Val (drop = Lab_Result_Txt_Val);
         set New_Lab_Result_Val;
         rename v_lab_result_val_txt = lab_result_txt_val;
        run;
        */


        update rdb.dbo.TMP_Lab_Result_Val
        set lab_result_txt_val = ( select v_lab_result_val_txt
                                   from  rdb.dbo.TMP_New_Lab_Result_Val tnl
                                   where tnl.lab_test_uid = rdb.dbo.TMP_Lab_Result_Val.lab_test_uid)
        ;



        /*

        data rdb..Lab_Result_Val;
            set Lab_Result_Val;
            If record_status_cd = '' then record_status_cd = 'ACTIVE';
            If record_status_cd = 'UNPROCESSED' then record_status_cd = 'ACTIVE';
            If record_status_cd = 'PROCESSED' then record_status_cd = 'ACTIVE';
            If record_status_cd = 'LOG_DEL' then record_status_cd = 'INACTIVE';
        run;

        DATA rdb..Lab_Result_Val;
        SET rdb..Lab_Result_Val;
        RDB_LAST_REFRESH_TIME=DATETIME();
        RUN;
        */

        update rdb..TMP_Lab_Result_Val
        set record_status_cd = 'ACTIVE'
        where record_status_cd in ( '' ,'UNPROCESSED' ,'PROCESSED' )
           or record_status_cd = null
        ;

        update rdb..TMP_Lab_Result_Val
        set record_status_cd = 'INACTIVE'
        where record_status_cd = 'LOG_DEL'
        ;


        update rdb..TMP_Lab_Result_Val
        set Test_Result_Val_Cd = null
        where rtrim(Test_Result_Val_Cd ) = ''
        ;


        update rdb..TMP_Lab_Result_Val
        set Test_Result_Val_Cd_Desc  = null
        where rtrim(Test_Result_Val_Cd_Desc  ) = ''
        ;

        update rdb..TMP_Lab_Result_Val
        set Result_Units  = null
        where rtrim(Result_Units  ) = ''
        ;

        UPDATE rdb.dbo.TMP_Lab_Result_Val
        set Lab_Result_Txt_Val = null
        where ltrim(rtrim(Lab_Result_Txt_Val)) = ''
        ;


        delete
        from rdb..TMP_Lab_Result_Val
        where Test_Result_Val_Key =1
        ;





        /* Update Lab_Test Keys */

        /* Test_Result_Grp_Key */


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_Lab_Result_Val_Final ';

        IF OBJECT_ID('rdb.dbo.TMP_Lab_Result_Val_Final', 'U') IS NOT NULL
            drop table  rdb.dbo.TMP_Lab_Result_Val_Final;

        SELECT               MIN([TEST_RESULT_GRP_KEY]) AS TEST_RESULT_GRP_KEY
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
                       '&gt;', CHAR(62))) as LAB_RESULT_TXT_VAL
             ,[REF_RANGE_FRM]
             ,[REF_RANGE_TO]
             ,[TEST_RESULT_VAL_CD]
             ,rtrim([TEST_RESULT_VAL_CD_DESC]) as [TEST_RESULT_VAL_CD_DESC]
             ,[TEST_RESULT_VAL_CD_SYS_CD]
             ,[TEST_RESULT_VAL_CD_SYS_NM]
             ,[ALT_RESULT_VAL_CD]
             ,rtrim([ALT_RESULT_VAL_CD_DESC]) as [ALT_RESULT_VAL_CD_DESC]
             ,[ALT_RESULT_VAL_CD_SYS_CD]
             ,[ALT_RESULT_VAL_CD_SYSTEM_NM]
             ,MIN([TEST_RESULT_VAL_KEY]) as TEST_RESULT_VAL_KEY
             ,[RECORD_STATUS_CD]
             ,[FROM_TIME]
             ,[TO_TIME]
             ,[LAB_TEST_UID]
        --, getdate()
        into  rdb.dbo.TMP_Lab_Result_Val_Final
        FROM [RDB].[dbo].TMP_LAB_RESULT_VAL
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
               ,[LAB_TEST_UID]
        ;




        -- create table Lab_Test_Result2 as

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_Lab_Test_Result2 ';

        IF OBJECT_ID('rdb.dbo.TMP_Lab_Test_Result2', 'U') IS NOT NULL
            drop table  rdb.dbo.TMP_Lab_Test_Result2;

        select 	tst.*,
                  coalesce(lrv.Test_Result_Grp_Key,1) as Test_Result_Grp_Key
        into rdb.dbo.TMP_Lab_Test_Result2
        from
            rdb.dbo.TMP_Lab_Test_Result1		as tst
                left join	rdb.dbo.TMP_Lab_Result_Val_FINAL as lrv	on tst.Lab_test_uid = lrv.Lab_test_uid
                and lrv.Test_Result_Grp_Key <> 1
        ;



        /*
        proc sort tagsort data = lab_test_result2;
            by Lab_test_uid;
        */




        /* Patient Key */
        /* bad data seen for a order test without patient, will reseach later*/

        -- create table Lab_Test_Result3 as

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;


        IF not exists (SELECT 1 FROM sys.indexes WHERE name = 'idx_TMP_updated_participant_tcd'
                                                   AND object_id = OBJECT_ID('rdb.dbo.TMP_updated_participant') )
            begin
                CREATE NONCLUSTERED INDEX idx_TMP_updated_participant_tcd ON rdb.dbo.TMP_updated_participant
                    (
                     [type_cd] ASC,
                     [act_class_cd] ASC,
                     [record_status_cd] ASC,
                     [subject_class_cd] ASC
                        )
                    INCLUDE ( 	[act_uid],
                                 [subject_entity_uid])
            end
            ;


        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_Lab_Test_Result3 ';

        IF OBJECT_ID('rdb.dbo.TMP_Lab_Test_Result3', 'U') IS NOT NULL
            drop table   rdb.dbo.TMP_Lab_Test_Result3;

        select 	tst.*,
                  coalesce(psn.patient_key,1) as patient_key
        into rdb.dbo.TMP_Lab_Test_Result3
        from 	rdb.dbo.TMP_Lab_Test_Result2 as tst
                    left join rdb..TMP_updated_participant as par
                              on tst.Root_Ordered_Test_Pntr = par.act_uid
                                  and par.type_cd ='PATSBJ'
                                  and par.act_class_cd ='OBS'
                                  and par.subject_class_cd = 'PSN'
                                  and par.record_status_cd ='ACTIVE'
                    left join rdb..d_patient as psn
                              on par.subject_entity_uid = psn.patient_uid
                                  and psn.patient_key <> 1

        ;



        /*
        quit;
        data Lab_Test_Result3;
        set Lab_Test_Result3;
        if morb_rpt_key>1 then PATIENT_KEY=morb_patient_key;
        if morb_rpt_key>1 then Condition_Key=morb_Condition_Key;
        if morb_rpt_key>1 then Investigation_Key = morb_Investigation_Key;
        if morb_rpt_key>1 then REPORTING_LAB_KEY= MORB_RPT_SRC_ORG_KEY;
        run;
        */


        update  rdb.dbo.TMP_Lab_Test_Result3
        set
            PATIENT_KEY=morb_patient_key,
            Condition_Key=morb_Condition_Key,
            Investigation_Key = morb_Investigation_Key,
            REPORTING_LAB_KEY= MORB_RPT_SRC_ORG_KEY
        where morb_rpt_key>1
        ;


        /* Performing Lab */
        -- create table Lab_Test_Result as

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START', @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_Lab_Test_Result ';

        IF OBJECT_ID('rdb.dbo.TMP_Lab_Test_Result', 'U') IS NOT NULL
            drop table     rdb.dbo.TMP_Lab_Test_Result;


        select 	distinct tst.*,
                           coalesce(org.Organization_key,1) as Performing_lab_key
        into    rdb.dbo.TMP_Lab_Test_Result
        from 	rdb.dbo.TMP_Lab_Test_Result3 as tst
                    left join rdb..TMP_updated_participant as par
                              on tst.lab_test_uid = par.act_uid
                                  and par.type_cd ='PRF'
                                  and par.act_class_cd ='OBS'
                                  and par.subject_class_cd = 'ORG'
                                  and par.record_status_cd ='ACTIVE'
                    left join rdb..d_Organization  as org
                              on par.subject_entity_uid = org.Organization_uid
                                  and org.Organization_key <> 1
        ;



        /*
        proc sort tagsort data = Test_Result_Grouping nodupkey;
            by test_result_grp_key;

        proc sql;
        quit;
        data rdb..Test_Result_Grouping;
            set Test_Result_Grouping; run;
        DATA rdb..Test_Result_Grouping;
        SET rdb..Test_Result_Grouping;
        RDB_LAST_REFRESH_TIME=DATETIME();
        RUN;
        proc sql;

        delete from rdb..TEST_RESULT_GROUPING where test_result_grp_key=1;
        delete from rdb..TEST_RESULT_GROUPING where test_result_grp_key=.;
        delete from rdb..TEST_RESULT_GROUPING where TEST_RESULT_GRP_KEY not in (select TEST_RESULT_GRP_KEY from rdb..LAB_RESULT_VAL);
        */


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = ' DELETING TMP_TEST_RESULT_GROUPING ';


        CREATE NONCLUSTERED INDEX [idx_TMP_LAB_RESULT_VAL_tp_hp_key] ON [dbo].[TMP_LAB_RESULT_VAL]
            (
             [test_result_grp_key] ASC
                )
        ;

        delete from rdb..TMP_TEST_RESULT_GROUPING where test_result_grp_key=1;
        delete from rdb..TMP_TEST_RESULT_GROUPING where test_result_grp_key is null;
        delete from rdb..TMP_TEST_RESULT_GROUPING
        where TEST_RESULT_GRP_KEY not in (select TEST_RESULT_GRP_KEY from rdb..tmp_LAB_RESULT_VAL);



        /*
        quit;

        -- %dbload(TEST_RESULT_GROUPING, rdb..TEST_RESULT_GROUPING);
        */

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = ' GENERATING TEST_RESULT_GROUPING ';



        insert into  rdb..TEST_RESULT_GROUPING
        ([TEST_RESULT_GRP_KEY]
        ,[LAB_TEST_UID]
        ,[RDB_LAST_REFRESH_TIME])
        select [TEST_RESULT_GRP_KEY]
                ,[LAB_TEST_UID],
               cast( null as datetime) as [RDB_LAST_REFRESH_TIME]
        from rdb..TMP_TEST_RESULT_GROUPING
        ;



        --%dbload(Lab_Result_Val, rdb..Lab_Result_Val);
        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = ' INSERTING INTO  LAB_RESULT_VAL ';



        insert into rdb..LAB_RESULT_VAL
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
        Select TEST_RESULT_GRP_KEY
             , substring(NUMERIC_RESULT ,1,50)
             , substring(RESULT_UNITS ,1,50)
             , rtrim(ltrim(substring(LAB_RESULT_TXT_VAL ,1,2000)))
             , substring(REF_RANGE_FRM ,1,20)
             , substring(REF_RANGE_TO ,1,20)
             , substring(TEST_RESULT_VAL_CD ,1,20)
             , substring(rtrim(TEST_RESULT_VAL_CD_DESC) ,1,300)
             , substring(TEST_RESULT_VAL_CD_SYS_CD ,1,100)
             , substring(TEST_RESULT_VAL_CD_SYS_NM ,1,100)
             , substring(ALT_RESULT_VAL_CD ,1,50)
             , substring(rtrim(ALT_RESULT_VAL_CD_DESC) ,1,100)
             , substring(ALT_RESULT_VAL_CD_SYS_CD ,1,50)
             , substring(ALT_RESULT_VAL_CD_SYSTEM_NM ,1,100)
             ,TEST_RESULT_VAL_KEY
             , substring(RECORD_STATUS_CD ,1,8)
             ,FROM_TIME
             ,TO_TIME
             ,LAB_TEST_UID
             , getdate()
        FROM [RDB].[dbo].TMP_LAB_RESULT_VAL_FINAL
        ;




        /*

        data rdb..Result_Comment_Group;
            set Result_Comment_Group;
            RDB_LAST_REFRESH_TIME=DATETIME();
        run;
        --%dbload(Result_Comment_Group, rdb..Result_Comment_Group);
        */


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = ' INSERTING INTO RESULT_COMMENT_GROUP ';



        insert into   [RDB].[dbo].[RESULT_COMMENT_GROUP]
        ([RESULT_COMMENT_GRP_KEY]
        ,[LAB_TEST_UID]
        ,[RDB_LAST_REFRESH_TIME]
        )
        select [RESULT_COMMENT_GRP_KEY]
             ,[LAB_TEST_UID]
             , getdate()
        FROM [RDB].[dbo].[TMP_RESULT_COMMENT_GROUP]
        ;

        --  SELECT ' i am here';

        /*
        data rdb..Lab_Result_Comment;
            set Lab_Result_Comment;
            If record_status_cd = '' then record_status_cd = 'ACTIVE';
            If record_status_cd = 'UNPROCESSED' then record_status_cd = 'ACTIVE';
            If record_status_cd = 'PROCESSED' then record_status_cd = 'ACTIVE';
            If record_status_cd = 'LOG_DEL' then record_status_cd = 'INACTIVE';
        run;


        DATA rdb..Lab_Result_Comment;
        SET rdb..Lab_Result_Comment;
        RDB_LAST_REFRESH_TIME=DATETIME();
        RUN;


        */

        update rdb..TMP_New_Lab_Result_Comment_FINAL
        set record_status_cd = 'ACTIVE'
        where record_status_cd in ( '' ,'UNPROCESSED' ,'PROCESSED' )
           or record_status_cd = null
        ;

        update rdb..TMP_New_Lab_Result_Comment_FINAL
        set record_status_cd = 'INACTIVE'
        where record_status_cd = 'LOG_DEL'
        ;



        update [RDB].[dbo].TMP_New_Lab_Result_Comment_FINAL
        set [LAB_RESULT_COMMENTS] = replace ( [LAB_RESULT_COMMENTS],'&#x20;',' ')
        where [LAB_RESULT_COMMENTS] like  '%.&#x20;%'
        ;

        update [RDB].[dbo].TMP_New_Lab_Result_Comment_FINAL
        set [LAB_RESULT_COMMENTS] = (REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([LAB_RESULT_COMMENTS],
                                                                                             '&#x09;', CHAR(9)),
                                                                                     '&#x0A;', CHAR(10)),
                                                                             '&#x0D;', CHAR(13)),
                                                                     '&#x20;', CHAR(32)),
                                                             '&amp;', CHAR(38)),
                                                     '&lt;', CHAR(60)),
                                             '&gt;', CHAR(62)))
        ;




        update rdb..TMP_New_Lab_Result_Comment_FINAL
        set [RDB_LAST_REFRESH_TIME] = getdate()
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = ' INSERTING INTO Lab_Result_Comment ';


        --%dbload(LAB_RESULT_COMMENT, rdb..Lab_Result_Comment);

        insert into rdb..Lab_Result_Comment
        ([LAB_TEST_UID]
        ,[LAB_RESULT_COMMENT_KEY]
        ,[LAB_RESULT_COMMENTS]
        ,[RESULT_COMMENT_GRP_KEY]
        ,[RECORD_STATUS_CD]
        ,[RDB_LAST_REFRESH_TIME]
        )
        SELECT LAB_TEST_UID
             ,LAB_RESULT_COMMENT_KEY
             , substring(LAB_RESULT_COMMENTS ,1,2000)
             ,RESULT_COMMENT_GRP_KEY
             , substring(RECORD_STATUS_CD ,1,8)
             ,[RDB_LAST_REFRESH_TIME]
        FROM [RDB].[dbo].[TMP_New_Lab_Result_Comment_FINAL]
        ;
        /*

      delete * from Lab_Test_Result where lab_test_key is null;


      run;
      proc sort data = Lab_Test_Result;
          by root_ordered_test_pntr lab_test_uid;
      data rdb..Lab_Test_Result (drop = root_ordered_test_pntr);
          set Lab_Test_Result;
          If record_status_cd = '' then record_status_cd = 'ACTIVE';
          If record_status_cd = 'UNPROCESSED' then record_status_cd = 'ACTIVE';
          If record_status_cd = 'PROCESSED' then record_status_cd = 'ACTIVE';
          If record_status_cd = 'LOG_DEL' then record_status_cd = 'INACTIVE';
      run;


      DATA rdb..Lab_Test_Result;
      SET rdb..Lab_Test_Result;
      RDB_LAST_REFRESH_TIME=DATETIME();
      RUN;
      */

        delete from rdb..TMP_Lab_Test_Result where lab_test_key is null;

        update rdb..TMP_Lab_Test_Result
        set record_status_cd = 'ACTIVE'
        where record_status_cd in ( '' ,'UNPROCESSED' ,'PROCESSED' )
           or record_status_cd = null
        ;

        update rdb..TMP_Lab_Test_Result
        set record_status_cd = 'INACTIVE'
        where record_status_cd = 'LOG_DEL'
        ;







        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = ' INSERTING INTO LAB_TEST_RESULT ';



        --%dbload(Lab_Test_Result, rdb..Lab_Test_Result);
        insert into rdb.. LAB_TEST_RESULT
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
             ,coalesce([PATIENT_KEY],'')
             ,coalesce([COPY_TO_PROVIDER_KEY],'')
             ,coalesce([LAB_TEST_TECHNICIAN_KEY],'')
             ,coalesce([SPECIMEN_COLLECTOR_KEY],'')
             ,coalesce([ORDERING_ORG_KEY],'')
             ,coalesce([REPORTING_LAB_KEY],'')
             ,coalesce([CONDITION_KEY],'')
             ,coalesce([LAB_RPT_DT_KEY],'')
             ,coalesce([MORB_RPT_KEY],'')
             ,coalesce([INVESTIGATION_KEY],'')
             ,coalesce([LDF_GROUP_KEY],'')
             ,coalesce([ORDERING_PROVIDER_KEY],'')
             , substring(RECORD_STATUS_CD ,1,8)
             , getdate() as [RDB_LAST_REFRESH_TIME]
        FROM [RDB].[dbo].[TMP_LAB_TEST_RESULT]
        ;




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
        INSERT INTO RDB.[DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_LABTEST_RESULTS','RDB.D_LABTEST_RESULTS','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        IF OBJECT_ID('rdb.dbo.TMP_lab_test_resultInit', 'U') IS NOT NULL
            drop table   rdb.dbo.TMP_lab_test_resultInit ;

        IF OBJECT_ID('rdb.dbo.TMP_Lab_Test_Result1', 'U') IS NOT NULL
            drop table  rdb..TMP_Lab_Test_Result1;

        IF OBJECT_ID('rdb.dbo.TMP_Result_And_R_Result', 'U') IS NOT NULL
            drop table  rdb..TMP_Result_And_R_Result;

        IF OBJECT_ID('rdb.dbo.TMP_Lab_Result_Comment', 'U') IS NOT NULL
            drop table   rdb..TMP_Lab_Result_Comment ;

        IF OBJECT_ID('rdb.dbo.TMP_New_Lab_Result_Comment', 'U') IS NOT NULL
            drop table  rdb..TMP_New_Lab_Result_Comment;

        IF OBJECT_ID('rdb.dbo.TMP_New_Lab_Result_Comment_grouped', 'U') IS NOT NULL
            drop table  rdb.dbo.TMP_New_Lab_Result_Comment_grouped;

        --IF OBJECT_ID('rdb.dbo.TMP_New_Lab_Result_Comment_FINAL', 'U') IS NOT NULL
        --drop table   [RDB].[dbo].[TMP_New_Lab_Result_Comment_FINAL];

        IF OBJECT_ID('rdb.dbo.TMP_Result_Comment_Group', 'U') IS NOT NULL
            drop table  rdb.dbo.TMP_Result_Comment_Group;


        --IF OBJECT_ID('rdb.dbo.TMP_Lab_Result_Val', 'U') IS NOT NULL
        --drop table   rdb..TMP_Lab_Result_Val;

        --IF OBJECT_ID('rdb.dbo.TMP_TEST_RESULT_GROUPING', 'U') IS NOT NULL
        --drop table   [RDB].[dbo].[TMP_TEST_RESULT_GROUPING];

        IF OBJECT_ID('rdb.dbo.TMP_New_Lab_Result_Val', 'U') IS NOT NULL
            drop table  rdb.dbo.TMP_New_Lab_Result_Val;

        IF OBJECT_ID('rdb.dbo.TMP_Lab_Test_Result2', 'U') IS NOT NULL
            drop table  rdb.dbo.TMP_Lab_Test_Result2;

        IF OBJECT_ID('rdb.dbo.TMP_Lab_Test_Result3', 'U') IS NOT NULL
            drop table   rdb.dbo.TMP_Lab_Test_Result3;

        --IF OBJECT_ID('rdb.dbo.TMP_Lab_Test_Result', 'U') IS NOT NULL
        --   drop table     rdb.dbo.TMP_Lab_Test_Result;


        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;

        SET @Proc_Step_Name = 'SP_COMPLETE';


        INSERT INTO rdb.[dbo].[job_flow_log] (
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
            ,'RDB.D_LABTEST_RESULTS'
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


        INSERT INTO rdb.[dbo].[job_flow_log] (
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
            ,'RDB.D_LABTEST_RESULTS'
            ,'ERROR'
            ,@Proc_Step_no
            ,'ERROR - '+ @Proc_Step_name
            , 'Step -' +CAST(@Proc_Step_no AS VARCHAR(3))+' -' +CAST(@ErrorMessage AS VARCHAR(500))
            ,0
            );


        return -1 ;

    END CATCH

END

    ;










