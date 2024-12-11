CREATE OR ALTER PROCEDURE dbo.sp_lab101_datamart_postprocessing(
    @lab_test_uids NVARCHAR(MAX),
    @debug bit = 'false')
as

BEGIN

    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';
        DECLARE @batch_id bigint;
        SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmss')) AS bigint);

        BEGIN TRANSACTION;

        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'LAB101_DATAMART', 'LAB101_DATAMART', LEFT('START - UIDs: ' + @lab_test_uids, 200), @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        -- get all associated LAB_TEST's with I_RESULT that are coming in through @lab_test_uids
        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #tmp_I_Result_vals';


        IF OBJECT_ID('#tmp_I_Result_vals', 'U') IS NOT NULL
            drop table #tmp_I_Result_vals ;

        /*
        The subquery, aliased as tmp, works by getting the top level lab test uid and its followup uids for whatever ID(s) is(are) coming in,
        then joins back onto dbo.LAB_TEST to get all I_Results for a given test.
        */
        SELECT LAB_TEST_UID,
               LAB_TEST_KEY,
               LAB_TEST_CD,
               PARENT_TEST_PNTR,
               RECORD_STATUS_CD,
               OID,
               LAB_RPT_LOCAL_ID,
               LAB_RPT_UID
        INTO #tmp_I_Result_vals
        FROM dbo.LAB_TEST lt
        INNER JOIN
        (
        SELECT observation_uid,
        followup_observation_uid
        FROM dbo.nrt_observation
        WHERE observation_uid IN (SELECT ROOT_ORDERED_TEST_PNTR FROM dbo.LAB_TEST WHERE LAB_TEST_UID IN (SELECT value FROM STRING_SPLIT(@lab_test_uids, ',')))
        ) tmp
        on lt.lab_test_uid in (SELECT value FROM STRING_SPLIT(tmp.followup_observation_uid, ','))
            AND lt.LAB_TEST_TYPE = 'I_Result'
        order by LAB_RPT_UID;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'LAB101_DATAMART', 'LAB101_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        -- get test result values
        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #tmp_ISOLATE_TRACKING_INIT';


        IF OBJECT_ID('#tmp_ISOLATE_TRACKING_INIT', 'U') IS NOT NULL
            drop table #tmp_ISOLATE_TRACKING_INIT ;

        SELECT lt.LAB_TEST_KEY,
               lrv.TEST_RESULT_GRP_KEY,
               lt.LAB_TEST_CD,
               lrv.TEST_RESULT_VAL_CD,
               lrv.TEST_RESULT_VAL_CD_DESC,
               lrv.FROM_TIME,
               lrv.LAB_RESULT_TXT_VAL,
               lt.PARENT_TEST_PNTR,
               lt.RECORD_STATUS_CD,
               lt.OID,
               lt.LAB_RPT_LOCAL_ID,
               lt.LAB_RPT_UID
        INTO #tmp_ISOLATE_TRACKING_INIT
        FROM (SELECT TEST_RESULT_GRP_KEY,
                     TEST_RESULT_VAL_CD,
                     TEST_RESULT_VAL_CD_DESC,
                     FROM_TIME,
                     LAB_RESULT_TXT_VAL
              FROM dbo.LAB_RESULT_VAL
              WHERE LAB_TEST_UID IN (SELECT lab_test_uid from #tmp_I_Result_vals)) lrv
                 LEFT JOIN (SELECT TEST_RESULT_GRP_KEY
                            FROM dbo.TEST_RESULT_GROUPING
                            WHERE LAB_TEST_UID IN (SELECT lab_test_uid from #tmp_I_Result_vals)) trg
                           on lrv.TEST_RESULT_GRP_KEY = trg.TEST_RESULT_GRP_KEY
                 left join (SELECT TEST_RESULT_GRP_KEY,
                                   LAB_TEST_KEY
                            FROM dbo.LAB_TEST_RESULT
                            WHERE LAB_TEST_UID IN (SELECT lab_test_uid from #tmp_I_Result_vals)) ltr
                           on trg.TEST_RESULT_GRP_KEY = ltr.TEST_RESULT_GRP_KEY
                 left join #tmp_I_Result_vals lt
                           on lt.LAB_TEST_KEY = ltr.LAB_TEST_KEY
        order by LAB_RPT_UID;

        if @debug = 'true' SELECT @Proc_Step_Name, * FROM #tmp_ISOLATE_TRACKING_INIT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'LAB101_DATAMART', 'LAB101_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #tmp_RESULTED_TEST_DETAIL1';


        IF OBJECT_ID('#tmp_RESULTED_TEST_DETAIL1', 'U') IS NOT NULL
            drop table #tmp_RESULTED_TEST_DETAIL1 ;

        -- this query works through the LAB_TEST table to get the resulted test
        -- each subquery is filtering on LAB_TEST_UID (LAB_TEST's index) for improved performance
        select LAB_TEST_I_RESULT.LAB_RPT_UID,
               resulted_test.lab_test_cd_desc,
               resulted_test.SPECIMEN_SRC              as SPECIMEN_SRC_CD,
               resulted_test.SPECIMEN_DESC             as SPECIMEN_SRC_DESC,
               resulted_test.SPECIMEN_COLLECTION_DT    as SPECIMEN_COLLECTION_DT,
               resulted_test.LAB_TEST_DT               as LAB_TEST_DT,
               resulted_test.LAB_RPT_RECEIVED_BY_PH_DT as LAB_RPT_RECEIVED_BY_PH_DT,
               resulted_test.LAB_RPT_CREATED_DT        as LAB_RPT_CREATED_DT,
               resulted_test.record_status_cd          as record_status_cd_resulted_test,
               resulted_test.LAB_TEST_KEY              as RESULTED_LAB_TEST_KEY,
               LAB_TEST_I_result.LAB_RPT_UID           as LAB_RPT_UID_result,
               LAB_TEST_I_result.LAB_RPT_LOCAL_ID
        into #tmp_RESULTED_TEST_DETAIL1
        from (SELECT LAB_TEST_CD_DESC,
                     SPECIMEN_SRC,
                     SPECIMEN_DESC,
                     SPECIMEN_COLLECTION_DT,
                     LAB_TEST_DT,
                     LAB_RPT_RECEIVED_BY_PH_DT,
                     LAB_RPT_CREATED_DT,
                     RECORD_STATUS_CD,
                     LAB_TEST_KEY,
                     LAB_TEST_TYPE,
                     LAB_RPT_UID
              FROM dbo.lab_test
              where lab_test_uid in
                    (select parent_test_pntr
                     from (SELECT PARENT_TEST_PNTR, LAB_RPT_UID
                           FROM dbo.lab_test
                           where lab_test_uid in
                                 (select PARENT_TEST_PNTR from #tmp_I_result_vals)
                             and lab_test_type = 'I_Order') as tbl)
                and lab_test_type = 'Result') resulted_test
                 left join (SELECT LAB_TEST_TYPE, LAB_RPT_UID, PARENT_TEST_PNTR
                            FROM dbo.lab_test
                            where lab_test_uid in (select PARENT_TEST_PNTR from #tmp_I_result_vals)
                              and lab_test_type = 'I_Order') AS LAB_TEST_I_ORDER
                           ON resulted_test.LAB_RPT_UID = LAB_TEST_I_ORDER.PARENT_TEST_PNTR
                 left join #tmp_I_result_vals AS LAB_TEST_I_RESULT
                           ON LAB_TEST_I_ORDER.LAB_RPT_UID = LAB_TEST_I_RESULT.PARENT_TEST_PNTR
        WHERE LAB_TEST_I_ORDER.LAB_TEST_TYPE = 'I_Order'
          and resulted_test.LAB_TEST_TYPE = 'Result'

        ORDER BY LAB_RPT_UID;

        if @debug = 'true' SELECT @Proc_Step_Name, * FROM #tmp_RESULTED_TEST_DETAIL1;


        --CREATE TABLE RESULTED_TEST_DETAILS AS


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'LAB101_DATAMART', 'LAB101_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #tmp_RESULTED_TEST_DETAILS';


        IF OBJECT_ID('#tmp_RESULTED_TEST_DETAILS', 'U') IS NOT NULL
            drop table #tmp_RESULTED_TEST_DETAILS ;

        SELECT TRACK.LAB_TEST_KEY,
               TRACK.TEST_RESULT_GRP_KEY,
               TRACK.LAB_TEST_CD,
               TRACK.TEST_RESULT_VAL_CD,
               TRACK.TEST_RESULT_VAL_CD_DESC,
               TRACK.FROM_TIME,
               TRACK.LAB_RESULT_TXT_VAL,
               TRACK.PARENT_TEST_PNTR,
               TRACK.RECORD_STATUS_CD,
               TRACK.OID,
               TRACK.LAB_RPT_LOCAL_ID,
               TRACK.LAB_RPT_UID,
               RESULTED_TEST_DETAIL1.lab_test_cd_desc,
               RESULTED_TEST_DETAIL1.RESULTED_LAB_TEST_KEY,
               RESULTED_TEST_DETAIL1.SPECIMEN_COLLECTION_DT,
               RESULTED_TEST_DETAIL1.LAB_TEST_DT,
               RESULTED_TEST_DETAIL1.LAB_RPT_RECEIVED_BY_PH_DT,
               RESULTED_TEST_DETAIL1.LAB_RPT_CREATED_DT,
               RESULTED_TEST_DETAIL1.SPECIMEN_SRC_CD,
               RESULTED_TEST_DETAIL1.SPECIMEN_SRC_DESC,
               RESULTED_TEST_DETAIL1.record_status_cd_resulted_test,
               cast(null as varchar(50))  as LAB1,
               cast(null as varchar(50))  as LAB2,
               cast(null as varchar(50))  as LAB3,
               cast(null as varchar(50))  as LAB4,
               cast(null as varchar(50))  as LAB5,
               cast(null as varchar(50))  as LAB6,
               cast(null as varchar(50))  as LAB7,
               cast(null as varchar(50))  as LAB8,
               cast(null as varchar(50))  as LAB9,
               cast(null as varchar(50))  as LAB10,
               cast(null as varchar(100)) as LAB11,
               cast(null as varchar(50))  as LAB12,
               cast(null as varchar(50))  as LAB13,
               cast(null as varchar(50))  as LAB14,
               cast(null as varchar(50))  as LAB15,
               cast(null as varchar(50))  as LAB16,
               cast(null as varchar(50))  as LAB17,
               cast(null as varchar(50))  as LAB18,
               cast(null as varchar(50))  as LAB19,
               cast(null as varchar(100)) as LAB20,
               cast(null as varchar(50))  as LAB21,
               cast(null as varchar(50))  as LAB22,
               cast(null as varchar(50))  as LAB23,
               cast(null as varchar(50))  as LAB24,
               cast(null as varchar(50))  as LAB25,
               cast(null as varchar(50))  as LAB26,
               cast(null as varchar(50))  as LAB27,
               cast(null as varchar(50))  as LAB28,
               cast(null as varchar(50))  as LAB29,
               cast(null as varchar(50))  as LAB30,
               cast(null as varchar(50))  as LAB31,
               cast(null as varchar(50))  as LAB32,
               cast(null as varchar(50))  as LAB33,
               cast(null as varchar(50))  as LAB34,
               cast(null as varchar(50))  as LAB35
        into #tmp_RESULTED_TEST_DETAILS
        FROM #tmp_ISOLATE_TRACKING_INIT AS TRACK
                 LEFT JOIN #tmp_RESULTED_TEST_DETAIL1 AS RESULTED_TEST_DETAIL1
                           ON TRACK.LAB_RPT_UID = RESULTED_TEST_DETAIL1.LAB_RPT_UID;

        if @debug = 'true' SELECT @Proc_Step_Name, * FROM #tmp_RESULTED_TEST_DETAILS;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'LAB101_DATAMART', 'LAB101_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #tmp_ISOLATE_TRACKING_LAB330_INIT';


        IF OBJECT_ID('#tmp_ISOLATE_TRACKING_LAB330_INIT', 'U') IS NOT NULL
            drop table #tmp_ISOLATE_TRACKING_LAB330_INIT ;


        -- to get LAB330, we have to work up to the parent order for our observations, then
        -- find the child that has: cd = 'LAB330'
        SELECT lrv.TEST_RESULT_VAL_CD_DESC as LAB330,
               lt.local_id                 as LAB_RPT_LOCAL_ID
        into #tmp_ISOLATE_TRACKING_LAB330_INIT
        FROM dbo.LAB_RESULT_VAL lrv
                 INNER JOIN
             (SELECT observation_uid, foi.local_id
              FROM dbo.nrt_observation obs
                       INNER JOIN
                   (select followup_observation_uid, local_id
                    from dbo.nrt_observation
                    where observation_uid in (select root_ordered_test_pntr
                                              from dbo.LAB_TEST
                                              where lab_test_uid IN (SELECT lab_test_uid from #tmp_I_Result_vals))) AS foi
                   on obs.observation_uid in (SELECT value FROM STRING_SPLIT(foi.followup_observation_uid, ','))
                       AND obs.cd = 'LAB330') as lt
             on lrv.lab_test_uid = lt.observation_uid;

        if @debug = 'true' SELECT @Proc_Step_Name, * FROM #tmp_ISOLATE_TRACKING_LAB330_INIT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'LAB101_DATAMART', 'LAB101_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #tmp_RESULTED_TEST_DETAILS_final';


        IF OBJECT_ID('#tmp_RESULTED_TEST_DETAILS_final', 'U') IS NOT NULL
            drop table #tmp_RESULTED_TEST_DETAILS_final ;


        CREATE TABLE #tmp_RESULTED_TEST_DETAILS_final
        (
            [LAB_TEST_KEY]                   [bigint]        NULL,
            [TEST_RESULT_GRP_KEY]            [bigint]        NULL,
            [LAB_TEST_CD]                    [varchar](1000) NULL,
            [TEST_RESULT_VAL_CD]             [varchar](20)   NULL,
            [TEST_RESULT_VAL_CD_DESC]        [varchar](300)  NULL,
            [FROM_TIME]                      [datetime]      NULL,
            [LAB_RESULT_TXT_VAL]             [varchar](2000) NULL,
            [PARENT_TEST_PNTR]               [bigint]        NULL,
            [RECORD_STATUS_CD]               [varchar](8)    NULL,
            [OID]                            [bigint]        NULL,
            [LAB_RPT_LOCAL_ID]               [varchar](50)   NULL,
            [LAB_RPT_UID]                    [bigint]        NULL,
            [lab_test_cd_desc]               [varchar](2000) NULL,
            [RESULTED_LAB_TEST_KEY]          [bigint]        NULL,
            [SPECIMEN_COLLECTION_DT]         [datetime]      NULL,
            [LAB_TEST_DT]                    [datetime]      NULL,
            [LAB_RPT_RECEIVED_BY_PH_DT]      [datetime]      NULL,
            [LAB_RPT_CREATED_DT]             [datetime]      NULL,
            [SPECIMEN_SRC_CD]                [varchar](50)   NULL,
            [SPECIMEN_SRC_DESC]              [varchar](1000) NULL,
            [record_status_cd_resulted_test] [varchar](8)    NULL,
            [LAB1]                           [varchar](50)   NULL,
            [LAB2]                           [varchar](50)   NULL,
            [LAB3]                           [varchar](50)   NULL,
            [LAB4]                           [varchar](50)   NULL,
            [LAB5]                           [varchar](100)  NULL,
            [LAB6]                           [varchar](50)   NULL,
            [LAB7]                           [varchar](50)   NULL,
            [LAB8]                           [varchar](50)   NULL,
            [LAB9]                           [varchar](50)   NULL,
            [LAB10]                          [varchar](50)   NULL,
            [LAB11]                          [varchar](100)  NULL,
            [LAB12]                          [varchar](50)   NULL,
            [LAB13]                          [varchar](50)   NULL,
            [LAB14]                          [varchar](50)   NULL,
            [LAB15]                          [varchar](50)   NULL,
            [LAB16]                          [varchar](50)   NULL,
            [LAB17]                          [varchar](50)   NULL,
            [LAB18]                          [varchar](50)   NULL,
            [LAB19]                          [varchar](50)   NULL,
            [LAB20]                          [varchar](100)  NULL,
            [LAB21]                          [varchar](50)   NULL,
            [LAB22]                          [varchar](50)   NULL,
            [LAB23]                          [varchar](50)   NULL,
            [LAB24]                          [varchar](50)   NULL,
            [LAB25]                          [varchar](50)   NULL,
            [LAB26]                          [varchar](100)  NULL,
            [LAB27]                          [varchar](50)   NULL,
            [LAB28]                          [varchar](50)   NULL,
            [LAB29]                          [varchar](50)   NULL,
            [LAB30]                          [varchar](50)   NULL,
            [LAB31]                          [varchar](50)   NULL,
            [LAB32]                          [varchar](50)   NULL,
            [LAB33]                          [varchar](50)   NULL,
            [LAB34]                          [varchar](50)   NULL,
            [LAB35]                          [varchar](50)   NULL
        ) ON [PRIMARY];

        -- this query contains a series of left joins that mimic the update statements from the original stored procedure that used subqueries
        -- the assumption here is that each RESULTED_TEST_KEY contains only one type of each LAB code in its child observations
        insert into #tmp_RESULTED_TEST_DETAILS_final ( lab_rpt_local_id, PARENT_TEST_PNTR, [RESULTED_LAB_TEST_KEY]
                                                     , record_status_cd, oid,
                                                       lab_test_cd_desc, SPECIMEN_SRC_DESC, SPECIMEN_SRC_CD
                                                     , SPECIMEN_COLLECTION_DT
                                                     , LAB_TEST_DT
                                                     , LAB_RPT_RECEIVED_BY_PH_DT
                                                     , LAB_RPT_CREATED_DT
                                                     , LAB1
                                                     , LAB2
                                                     , LAB3
                                                     , LAB4
                                                     , LAB5
                                                     , LAB6
                                                     , LAB7
                                                     , LAB8
                                                     , LAB9
                                                     , LAB10
                                                     , LAB11
                                                     , LAB12
                                                     , LAB13
                                                     , LAB14
                                                     , LAB15
                                                     , LAB16
                                                     , LAB17
                                                     , LAB18
                                                     , LAB19
                                                     , LAB20
                                                     , LAB21
                                                     , LAB22
                                                     , LAB23
                                                     , LAB24
                                                     , LAB25
                                                     , LAB26
                                                     , LAB27
                                                     , LAB28
                                                     , LAB29
                                                     , LAB30
                                                     , LAB31
                                                     , LAB32
                                                     , LAB33
                                                     , LAB34
                                                     , LAB35)
        select gc.lab_rpt_local_id
             , gc.PARENT_TEST_PNTR
             , gc.[RESULTED_LAB_TEST_KEY]
             , gc.record_status_cd_resulted_test
             , gc.oid
             , gc.lab_test_cd_desc
             , gc.SPECIMEN_SRC_DESC
             , gc.SPECIMEN_SRC_CD
             , gc.SPECIMEN_COLLECTION_DT
             , gc.LAB_TEST_DT
             , gc.LAB_RPT_RECEIVED_BY_PH_DT
             , gc.LAB_RPT_CREATED_DT
             , substring(trtd1.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd2.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd3.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd4.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd5.LAB_RESULT_TXT_VAL, 1, 100)
             , trtd6.FROM_TIME
             , trtd7.LAB_RESULT_TXT_VAL
             , substring(trtd8.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd9.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd10.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd11.LAB_RESULT_TXT_VAL, 1, 100)
             , trtd12.LAB_RESULT_TXT_VAL
             , trtd13.LAB_RESULT_TXT_VAL
             , trtd14.LAB_RESULT_TXT_VAL
             , trtd15.LAB_RESULT_TXT_VAL
             , trtd16.LAB_RESULT_TXT_VAL
             , substring(trtd17.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd18.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd19.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd20.LAB_RESULT_TXT_VAL, 1, 100)
             , trtd21.FROM_TIME
             , trtd22.FROM_TIME
             , substring(trtd23.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd24.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd25.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd26.LAB_RESULT_TXT_VAL, 1, 100)
             , substring(trtd27.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , trtd28.FROM_TIME
             , trtd29.FROM_TIME
             , substring(trtd30.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , substring(trtd31.TEST_RESULT_VAL_CD_DESC, 1, 50)
             , trtd32.LAB_RESULT_TXT_VAL
             , trtd33.FROM_TIME
             , trtd34.FROM_TIME
             , substring(trtd35.TEST_RESULT_VAL_CD_DESC, 1, 50)
        from (select lab_rpt_local_id
                   , PARENT_TEST_PNTR
                   , [RESULTED_LAB_TEST_KEY]
                   , record_status_cd_resulted_test
                   , oid
                   , lab_test_cd_desc
                   , SPECIMEN_SRC_DESC
                   , SPECIMEN_SRC_CD
                   , SPECIMEN_COLLECTION_DT
                   , LAB_TEST_DT
                   , LAB_RPT_RECEIVED_BY_PH_DT
                   , LAB_RPT_CREATED_DT
              from #tmp_RESULTED_TEST_DETAILS
              group by lab_rpt_local_id, PARENT_TEST_PNTR, [RESULTED_LAB_TEST_KEY], record_status_cd_resulted_test, oid
                     , lab_test_cd_desc, SPECIMEN_SRC_DESC, SPECIMEN_SRC_CD, SPECIMEN_COLLECTION_DT
                     , LAB_TEST_DT
                     , LAB_RPT_RECEIVED_BY_PH_DT
                     , LAB_RPT_CREATED_DT) as gc
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd1
                           ON gc.lab_rpt_local_id = trtd1.lab_rpt_local_id
                               AND trtd1.lab_test_cd = 'LAB329a'
                               AND trtd1.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd1.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd2
                           ON gc.lab_rpt_local_id = trtd2.lab_rpt_local_id
                               AND trtd2.lab_test_cd = 'LAB330'
                               AND trtd2.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd2.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd3
                           ON gc.lab_rpt_local_id = trtd3.lab_rpt_local_id
                               AND trtd3.lab_test_cd = 'LAB331'
                               AND trtd3.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd3.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd4
                           ON gc.lab_rpt_local_id = trtd4.lab_rpt_local_id
                               AND trtd4.lab_test_cd = 'LAB332'
                               AND trtd4.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd4.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd5
                           ON gc.lab_rpt_local_id = trtd5.lab_rpt_local_id
                               AND trtd5.lab_test_cd = 'LAB333'
                               AND trtd5.LAB_RESULT_TXT_VAL IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd5.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd6
                           ON gc.lab_rpt_local_id = trtd6.lab_rpt_local_id
                               AND trtd6.lab_test_cd = 'LAB334'
                               AND trtd6.FROM_TIME IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd6.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd7
                           ON gc.lab_rpt_local_id = trtd7.lab_rpt_local_id
                               AND trtd7.lab_test_cd = 'LAB335'
                               AND trtd7.LAB_RESULT_TXT_VAL IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd7.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd8
                           ON gc.lab_rpt_local_id = trtd8.lab_rpt_local_id
                               AND trtd8.lab_test_cd = 'LAB336'
                               AND trtd8.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd8.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd9
                           ON gc.lab_rpt_local_id = trtd9.lab_rpt_local_id
                               AND trtd9.lab_test_cd = 'LAB337'
                               AND trtd9.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd9.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd10
                           ON gc.lab_rpt_local_id = trtd10.lab_rpt_local_id
                               AND trtd10.lab_test_cd = 'LAB338'
                               AND trtd10.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd10.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd11
                           ON gc.lab_rpt_local_id = trtd11.lab_rpt_local_id
                               AND trtd11.lab_test_cd = 'LAB339'
                               AND trtd11.LAB_RESULT_TXT_VAL IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd11.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd12
                           ON gc.lab_rpt_local_id = trtd12.lab_rpt_local_id
                               AND trtd12.lab_test_cd = 'LAB340'
                               AND trtd12.LAB_RESULT_TXT_VAL IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd12.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd13
                           ON gc.lab_rpt_local_id = trtd13.lab_rpt_local_id
                               AND trtd13.lab_test_cd = 'LAB341'
                               AND trtd13.LAB_RESULT_TXT_VAL IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd13.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd14
                           ON gc.lab_rpt_local_id = trtd14.lab_rpt_local_id
                               AND trtd14.lab_test_cd = 'LAB342'
                               AND trtd14.LAB_RESULT_TXT_VAL IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd14.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd15
                           ON gc.lab_rpt_local_id = trtd15.lab_rpt_local_id
                               AND trtd15.lab_test_cd = 'LAB343'
                               AND trtd15.LAB_RESULT_TXT_VAL IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd15.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd16
                           ON gc.lab_rpt_local_id = trtd16.lab_rpt_local_id
                               AND trtd16.lab_test_cd = 'LAB344'
                               AND trtd16.LAB_RESULT_TXT_VAL IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd16.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd17
                           ON gc.lab_rpt_local_id = trtd17.lab_rpt_local_id
                               AND trtd17.lab_test_cd = 'LAB345'
                               AND trtd17.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd17.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd18
                           ON gc.lab_rpt_local_id = trtd18.lab_rpt_local_id
                               AND trtd18.lab_test_cd = 'LAB346'
                               AND trtd18.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd18.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd19
                           ON gc.lab_rpt_local_id = trtd19.lab_rpt_local_id
                               AND trtd19.lab_test_cd = 'LAB347'
                               AND trtd19.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd19.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd20
                           ON gc.lab_rpt_local_id = trtd20.lab_rpt_local_id
                               AND trtd20.lab_test_cd = 'LAB348'
                               AND trtd20.LAB_RESULT_TXT_VAL IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd20.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd21
                           ON gc.lab_rpt_local_id = trtd21.lab_rpt_local_id
                               AND trtd21.lab_test_cd = 'LAB349'
                               AND trtd21.FROM_TIME IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd21.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd22
                           ON gc.lab_rpt_local_id = trtd22.lab_rpt_local_id
                               AND trtd22.lab_test_cd = 'LAB350'
                               AND trtd22.FROM_TIME IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd22.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd23
                           ON gc.lab_rpt_local_id = trtd23.lab_rpt_local_id
                               AND trtd23.lab_test_cd = 'LAB351'
                               AND trtd23.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd23.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd24
                           ON gc.lab_rpt_local_id = trtd24.lab_rpt_local_id
                               AND trtd24.lab_test_cd = 'LAB352'
                               AND trtd24.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd24.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd25
                           ON gc.lab_rpt_local_id = trtd25.lab_rpt_local_id
                               AND trtd25.lab_test_cd = 'LAB353'
                               AND trtd25.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd25.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd26
                           ON gc.lab_rpt_local_id = trtd26.lab_rpt_local_id
                               AND trtd26.lab_test_cd = 'LAB354'
                               AND trtd26.LAB_RESULT_TXT_VAL IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd26.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd27
                           ON gc.lab_rpt_local_id = trtd27.lab_rpt_local_id
                               AND trtd27.lab_test_cd = 'LAB355'
                               AND trtd27.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd27.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd28
                           ON gc.lab_rpt_local_id = trtd28.lab_rpt_local_id
                               AND trtd28.lab_test_cd = 'LAB356'
                               AND trtd28.FROM_TIME IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd28.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd29
                           ON gc.lab_rpt_local_id = trtd29.lab_rpt_local_id
                               AND trtd29.lab_test_cd = 'LAB357'
                               AND trtd29.FROM_TIME IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd29.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd30
                           ON gc.lab_rpt_local_id = trtd30.lab_rpt_local_id
                               AND trtd30.lab_test_cd = 'LAB358'
                               AND trtd30.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd30.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd31
                           ON gc.lab_rpt_local_id = trtd31.lab_rpt_local_id
                               AND trtd31.lab_test_cd = 'LAB359'
                               AND trtd31.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd31.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd32
                           ON gc.lab_rpt_local_id = trtd32.lab_rpt_local_id
                               AND trtd32.lab_test_cd = 'LAB360'
                               AND trtd32.LAB_RESULT_TXT_VAL IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd32.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd33
                           ON gc.lab_rpt_local_id = trtd33.lab_rpt_local_id
                               AND trtd33.lab_test_cd = 'LAB361'
                               AND trtd33.FROM_TIME IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd33.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd34
                           ON gc.lab_rpt_local_id = trtd34.lab_rpt_local_id
                               AND trtd34.lab_test_cd = 'LAB362'
                               AND trtd34.FROM_TIME IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd34.RESULTED_LAB_TEST_KEY
                 LEFT JOIN #tmp_RESULTED_TEST_DETAILS AS trtd35
                           ON gc.lab_rpt_local_id = trtd35.lab_rpt_local_id
                               AND trtd35.lab_test_cd = 'LAB363'
                               AND trtd35.TEST_RESULT_VAL_CD_DESC IS NOT NULL
                               AND gc.RESULTED_LAB_TEST_KEY = trtd35.RESULTED_LAB_TEST_KEY;

        if @debug = 'true' SELECT @Proc_Step_Name, * FROM #tmp_RESULTED_TEST_DETAILS_final;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'LAB101_DATAMART', 'LAB101_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #tmp_ISOLATE_TRACKING_WITH_LAB330';


        IF OBJECT_ID('#tmp_ISOLATE_TRACKING_WITH_LAB330', 'U') IS NOT NULL
            drop table #tmp_ISOLATE_TRACKING_WITH_LAB330 ;


        -- join lab330 back into the data
        SELECT TRACK_INFO.LAB_TEST_KEY,
               TRACK_INFO.TEST_RESULT_GRP_KEY,
               TRACK_INFO.LAB_TEST_CD,
               TRACK_INFO.TEST_RESULT_VAL_CD,
               TRACK_INFO.TEST_RESULT_VAL_CD_DESC,
               TRACK_INFO.FROM_TIME,
               TRACK_INFO.LAB_RESULT_TXT_VAL,
               TRACK_INFO.PARENT_TEST_PNTR,
               TRACK_INFO.RECORD_STATUS_CD,
               TRACK_INFO.OID,
               TRACK_INFO.LAB_RPT_LOCAL_ID,
               TRACK_INFO.LAB_RPT_UID,
               TRACK_INFO.lab_test_cd_desc,
               TRACK_INFO.RESULTED_LAB_TEST_KEY,
               TRACK_INFO.SPECIMEN_COLLECTION_DT,
               TRACK_INFO.LAB_TEST_DT,
               TRACK_INFO.LAB_RPT_RECEIVED_BY_PH_DT,
               TRACK_INFO.LAB_RPT_CREATED_DT,
               TRACK_INFO.SPECIMEN_SRC_CD,
               TRACK_INFO.SPECIMEN_SRC_DESC,
               TRACK_INFO.record_status_cd_resulted_test,
               TRACK_INFO.LAB1,
               TRACK_INFO.LAB2,
               TRACK_INFO.LAB3,
               TRACK_INFO.LAB4,
               TRACK_INFO.LAB5,
               TRACK_INFO.LAB6,
               TRACK_INFO.LAB7,
               TRACK_INFO.LAB8,
               TRACK_INFO.LAB9,
               TRACK_INFO.LAB10,
               TRACK_INFO.LAB11,
               TRACK_INFO.LAB12,
               TRACK_INFO.LAB13,
               TRACK_INFO.LAB14,
               TRACK_INFO.LAB15,
               TRACK_INFO.LAB16,
               TRACK_INFO.LAB17,
               TRACK_INFO.LAB18,
               TRACK_INFO.LAB19,
               TRACK_INFO.LAB20,
               TRACK_INFO.LAB21,
               TRACK_INFO.LAB22,
               TRACK_INFO.LAB23,
               TRACK_INFO.LAB24,
               TRACK_INFO.LAB25,
               TRACK_INFO.LAB26,
               TRACK_INFO.LAB27,
               TRACK_INFO.LAB28,
               TRACK_INFO.LAB29,
               TRACK_INFO.LAB30,
               TRACK_INFO.LAB31,
               TRACK_INFO.LAB32,
               TRACK_INFO.LAB33,
               TRACK_INFO.LAB34,
               TRACK_INFO.LAB35,
               LAB330.LAB330
        into #tmp_ISOLATE_TRACKING_WITH_LAB330
        FROM #tmp_RESULTED_TEST_DETAILS_FINAL AS TRACK_INFO
                 LEFT outer JOIN #tmp_ISOLATE_TRACKING_LAB330_INIT AS LAB330
                                 ON TRACK_INFO.LAB_RPT_LOCAL_ID = LAB330.LAB_RPT_LOCAL_ID;


        if @debug = 'true' SELECT @Proc_Step_Name, * FROM #tmp_ISOLATE_TRACKING_WITH_LAB330;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'LAB101_DATAMART', 'LAB101_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #tmp_LAB101_INIT';


        IF OBJECT_ID('#tmp_LAB101_INIT', 'U') IS NOT NULL
            drop table #tmp_LAB101_INIT ;

        SELECT OID                                                as 'PROGRAM_JURISDICTION_OID',
               lab_test_cd_desc                                   as 'RESULTED_LAB_TEST_CD_DESC',
               SPECIMEN_SRC_DESC,
               PARENT_TEST_PNTR,
               SPECIMEN_SRC_CD,
               RECORD_STATUS_CD,
               LAB_RPT_LOCAL_ID,
               RESULTED_LAB_TEST_KEY                              as 'RESULTED_LAB_TEST_KEY',
               LAB_RPT_CREATED_DT,
               SPECIMEN_COLLECTION_DT                             as 'SPECIMEN_COLLECTION_DT',
               LAB_RPT_RECEIVED_BY_PH_DT,
               LAB_TEST_DT,
               LAB_RPT_CREATED_DT                                 as LAB_RPT_CREATED_DT2,
               LAB.LAB330                                         AS 'PATIENT_STATUS',
               'Yes'                                              AS 'TRACK_ISO_IND',
               rtrim(LAB.LAB3)                                    AS 'ISO_RECEIVED_IND',
               LAB.LAB4                                           AS 'ISO_NO_RECEIVED_REASON',
               LAB.LAB5                                           AS 'ISO_NO_RECEIVED_REASON_OTH',
               LAB.LAB6                                           as 'ISO_RECEIVED_DT',
               LAB.LAB7                                           AS 'ISO_STATEID_NUM',
               LAB.LAB8                                           AS 'CASE_LAB_CONFIRMED_IND',
               LAB.LAB9                                           AS 'PULSENET_ISO_IND',
               LAB.LAB10                                          AS 'PFGE_PULSENET_SENT',
               LAB.LAB11                                          AS 'PFGE_PULSENET_ENZYME1',
               LAB.LAB12                                          AS 'PFGE_STATELAB_ENZYME1',
               LAB.LAB13                                          AS 'PFGE_PULSENET_ENZYME2',
               LAB.LAB14                                          AS 'PFGE_STATELAB_ENZYME2',
               LAB.LAB15                                          AS 'PFGE_PULSENET_ENZYME3',
               LAB.LAB16                                          AS 'PFGE_STATELAB_ENZYME3',
               LAB.LAB17                                          AS 'NARMS_ISO_IND',
               LAB.LAB18                                          AS 'NARMS_ISO_SENT_IND',
               LAB.LAB19                                          AS 'NARMS_NO_SENT_REASON',
               LAB.LAB20                                          AS 'NARMS_STATEID_NUM',
               LAB.LAB21                                          AS 'NARMS_EXPECTED_SHIP_DT',
               LAB.LAB22                                          AS 'NARMS_ACTUAL_SHIP_DT',
               LAB.LAB23                                AS 'EIP_ISO_IND',
               LAB.LAB24                                          AS 'EIP_SPEC_AVAIL_IND',
               LAB.LAB25                                          AS 'EIP_SPEC_NO_REASON',
               LAB.LAB26                                          AS 'EIP_SPEC_NO_REASON_OTH',
               LAB.LAB27                                          AS 'EIP_SHIP_LOCATION',
               LAB.LAB28                                          AS 'EIP_EXPECTED_SHIP_DT',
               LAB.LAB29                                          AS 'EIP_ACTUAL_SHIP_DT',
               LAB.LAB30                                          AS 'EIP_SPEC_RESHIP_IND',
               LAB.LAB31                                          AS 'EIP_SPEC_RESHIP_REASON',
               LAB.LAB32                AS 'EIP_SPEC_RESHIP_REASON_OTH',
               LAB.LAB33                                          AS 'EIP_SPEC_EXPECTED_RESHIP_DT',
               LAB.LAB34                                          AS 'EIP_SPEC_ACTUAL_RESHIP_DT',
               LAB.LAB35                                          AS 'ISO_SENT_CDC_IND',
               convert(datetime, replace(LAB.LAB6, '-', ' '), 0)  as ISO_RECEIVED_DATE,
               convert(datetime, replace(LAB.LAB21, '-', ' '), 0) as NARMS_EXPECTED_SHIP_DATE,
               convert(datetime, replace(LAB.LAB22, '-', ' '), 0) as NARMS_ACTUAL_SHIP_DATE,
               convert(datetime, replace(LAB.LAB28, '-', ' '), 0) as EIP_EXPECTED_SHIP_DATE,
               convert(datetime, replace(LAB.LAB29, '-', ' '), 0) as EIP_ACTUAL_SHIP_DATE,
               convert(datetime, replace(LAB.LAB33, '-', ' '), 0) as EIP_SPEC_EXPECTED_RESHIP_DATE,
               convert(datetime, replace(LAB.LAB34, '-', ' '), 0) as EIP_SPEC_ACTUAL_RESHIP_DATE,
               CAST(CASE
                        WHEN SPECIMEN_COLLECTION_DT is not null THEN SPECIMEN_COLLECTION_DT
                        WHEN LAB_TEST_DT is not null THEN LAB_TEST_DT
                        WHEN LAB_RPT_RECEIVED_BY_PH_DT is not null THEN LAB_RPT_RECEIVED_BY_PH_DT
                        WHEN LAB_RPT_CREATED_DT is not null THEN LAB_RPT_CREATED_DT
                        ELSE NULL
                   END as datetime)                               as EVENT_DATE
        into #tmp_LAB101_INIT
        FROM #tmp_ISOLATE_TRACKING_WITH_LAB330 AS LAB
        ORDER BY LAB_RPT_LOCAL_ID;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'LAB101_DATAMART', 'LAB101_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LAB101_INIT2';


        IF OBJECT_ID('#TMP_LAB101_INIT2', 'U') IS NOT NULL
            drop table #TMP_LAB101_INIT2 ;


-- combine this step with the one above

        SELECT L101.CASE_LAB_CONFIRMED_IND
             , L101.EIP_ACTUAL_SHIP_DATE
             , L101.EIP_EXPECTED_SHIP_DATE
             , L101.EIP_ISO_IND
             , L101.EIP_SHIP_LOCATION
             , L101.EIP_SPEC_ACTUAL_RESHIP_DATE
             , L101.EIP_SPEC_AVAIL_IND
             , L101.EIP_SPEC_EXPECTED_RESHIP_DATE
             , L101.EIP_SPEC_NO_REASON
             , L101.EIP_SPEC_NO_REASON_OTH
             , L101.EIP_SPEC_RESHIP_IND
             , L101.EIP_SPEC_RESHIP_REASON
             , L101.EIP_SPEC_RESHIP_REASON_OTH
             , L101.EVENT_DATE
             , L101.ISO_NO_RECEIVED_REASON
             , L101.ISO_NO_RECEIVED_REASON_OTH
             , L101.ISO_RECEIVED_DATE
             , L101.ISO_RECEIVED_IND
             , L101.ISO_STATEID_NUM
             , L101.LAB_RPT_LOCAL_ID
             , L101.NARMS_ACTUAL_SHIP_DATE
             , L101.NARMS_EXPECTED_SHIP_DATE
             , L101.NARMS_ISO_IND
             , L101.NARMS_ISO_SENT_IND
             , L101.NARMS_NO_SENT_REASON
             , L101.NARMS_STATEID_NUM
             , L101.PATIENT_STATUS
             , L101.PFGE_PULSENET_ENZYME1
             , L101.PFGE_PULSENET_ENZYME2
             , L101.PFGE_PULSENET_ENZYME3
             , L101.PFGE_PULSENET_SENT
             , L101.PFGE_STATELAB_ENZYME1
             , L101.PFGE_STATELAB_ENZYME2
             , L101.PFGE_STATELAB_ENZYME3
             , L101.PROGRAM_JURISDICTION_OID
             , L101.PULSENET_ISO_IND
             , L101.RECORD_STATUS_CD
             , L101.RESULTED_LAB_TEST_CD_DESC
             , L101.RESULTED_LAB_TEST_KEY
             , L101.SPECIMEN_COLLECTION_DT
             , L101.SPECIMEN_SRC_DESC
             , L101.SPECIMEN_SRC_CD
             , L101.TRACK_ISO_IND
             , L101.ISO_SENT_CDC_IND
             , L100.REPORTING_FACILITY_UID
             , getdate() as RDB_LAST_REFRESH_TIME
             , CASE
                   WHEN L101_TGT.RESULTED_LAB_TEST_KEY IS NULL THEN 'INSERT'
                   ELSE 'UPDATE'
            END          AS DML_IND
        INTO #TMP_LAB101_INIT2
        FROM #tmp_LAB101_INIT AS L101
                 LEFT JOIN (select resulted_lab_test_key, reporting_facility_uid
                            from dbo.LAB100
                            where LAB_RPT_LOCAL_ID in (SELECT LAB_RPT_LOCAL_ID FROM #tmp_LAB101_INIT)) L100
                           ON L101.RESULTED_LAB_TEST_KEY = L100.RESULTED_LAB_TEST_KEY
                 LEFT JOIN dbo.LAB101 L101_TGT
                           ON L101.RESULTED_LAB_TEST_KEY = L101_TGT.RESULTED_LAB_TEST_KEY;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'LAB101_DATAMART', 'LAB101_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        if @debug = 'true' SELECT @Proc_Step_Name, * FROM #TMP_LAB101_INIT2;

        COMMIT TRANSACTION;

        -- if @debug = 'true' RETURN;
        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' INSERT INTO dbo.LAB101';

        insert into dbo.LAB101
        ( [CASE_LAB_CONFIRMED_IND]
        , [EIP_ACTUAL_SHIP_DATE]
        , [EIP_EXPECTED_SHIP_DATE]
        , [EIP_ISO_IND]
        , [EIP_SHIP_LOCATION]
        , [EIP_SPEC_ACTUAL_RESHIP_DATE]
        , [EIP_SPEC_AVAIL_IND]
        , [EIP_SPEC_EXPECTED_RESHIP_DATE]
        , [EIP_SPEC_NO_REASON]
        , [EIP_SPEC_NO_REASON_OTH]
        , [EIP_SPEC_RESHIP_IND]
        , [EIP_SPEC_RESHIP_REASON]
        , [EIP_SPEC_RESHIP_REASON_OTH]
        , [EVENT_DATE]
        , [ISO_NO_RECEIVED_REASON]
        , [ISO_NO_RECEIVED_REASON_OTH]
        , [ISO_RECEIVED_DATE]
        , [ISO_RECEIVED_IND]
        , [ISO_STATEID_NUM]
        , [LAB_RPT_LOCAL_ID]
        , [NARMS_ACTUAL_SHIP_DATE]
        , [NARMS_EXPECTED_SHIP_DATE]
        , [NARMS_ISO_IND]
        , [NARMS_ISO_SENT_IND]
        , [NARMS_NO_SENT_REASON]
        , [NARMS_STATEID_NUM]
        , [PATIENT_STATUS]
        , [PFGE_PULSENET_ENZYME1]
        , [PFGE_PULSENET_ENZYME2]
        , [PFGE_PULSENET_ENZYME3]
        , [PFGE_PULSENET_SENT]
        , [PFGE_STATELAB_ENZYME1]
        , [PFGE_STATELAB_ENZYME2]
        , [PFGE_STATELAB_ENZYME3]
        , [PROGRAM_JURISDICTION_OID]
        , [PULSENET_ISO_IND]
        , [RECORD_STATUS_CD]
        , [RESULTED_LAB_TEST_CD_DESC]
        , [RESULTED_LAB_TEST_KEY]
        , [SPECIMEN_COLLECTION_DT]
        , [SPECIMEN_SRC_DESC]
        , [SPECIMEN_SRC_CD]
        , [TRACK_ISO_IND]
        , [ISO_SENT_CDC_IND]
        , [REPORTING_FACILITY_UID]
        , [RDB_LAST_REFRESH_TIME])

        SELECT rtrim(substring(CASE_LAB_CONFIRMED_IND, 1, 8))
             , EIP_ACTUAL_SHIP_DATE
             , EIP_EXPECTED_SHIP_DATE
             , rtrim(substring(EIP_ISO_IND, 1, 8))
             , rtrim(substring(EIP_SHIP_LOCATION, 1, 100))
             , EIP_SPEC_ACTUAL_RESHIP_DATE
             , rtrim(substring(EIP_SPEC_AVAIL_IND, 1, 50))
             , EIP_SPEC_EXPECTED_RESHIP_DATE
             , rtrim(substring(EIP_SPEC_NO_REASON, 1, 100))
             , rtrim(substring(EIP_SPEC_NO_REASON_OTH, 1, 100))
             , rtrim(substring(EIP_SPEC_RESHIP_IND, 1, 8))
             , rtrim(substring(EIP_SPEC_RESHIP_REASON, 1, 100))
             , rtrim(substring(EIP_SPEC_RESHIP_REASON_OTH, 1, 100))
             , EVENT_DATE
             , rtrim(substring(ISO_NO_RECEIVED_REASON, 1, 100))
             , rtrim(substring(ISO_NO_RECEIVED_REASON_OTH, 1, 100))
             , ISO_RECEIVED_DATE
             , rtrim(substring(ltrim(rtrim(ISO_RECEIVED_IND)), 1, 8))
             , rtrim(substring(ISO_STATEID_NUM, 1, 100))
             , rtrim(substring(LAB_RPT_LOCAL_ID, 1, 50))
             , NARMS_ACTUAL_SHIP_DATE
             , NARMS_EXPECTED_SHIP_DATE
             , rtrim(substring(NARMS_ISO_IND, 1, 8))
             , rtrim(substring(NARMS_ISO_SENT_IND, 1, 8))
             , rtrim(substring(NARMS_NO_SENT_REASON, 1, 100))
             , rtrim(substring(NARMS_STATEID_NUM, 1, 100))
             , rtrim(substring(PATIENT_STATUS, 1, 100))
             , rtrim(substring(PFGE_PULSENET_ENZYME1, 1, 100))
             , rtrim(substring(PFGE_PULSENET_ENZYME2, 1, 100))
             , rtrim(substring(PFGE_PULSENET_ENZYME3, 1, 100))
             , rtrim(substring(PFGE_PULSENET_SENT, 1, 8))
             , rtrim(substring(PFGE_STATELAB_ENZYME1, 1, 100))
             , rtrim(substring(PFGE_STATELAB_ENZYME2, 1, 100))
             , rtrim(substring(PFGE_STATELAB_ENZYME3, 1, 100))
             , PROGRAM_JURISDICTION_OID
             , rtrim(substring(PULSENET_ISO_IND, 1, 8))
             , rtrim(substring(RECORD_STATUS_CD, 1, 8))
             , rtrim(substring(RESULTED_LAB_TEST_CD_DESC, 1, 100))
             , RESULTED_LAB_TEST_KEY
             , SPECIMEN_COLLECTION_DT
             , rtrim(substring(SPECIMEN_SRC_DESC, 1, 100))
             , rtrim(substring(SPECIMEN_SRC_CD, 1, 100))
             , rtrim(substring(TRACK_ISO_IND, 1, 8))
             , rtrim(substring(ltrim(rtrim(ISO_SENT_CDC_IND)), 1, 8))
             , REPORTING_FACILITY_UID
             , RDB_LAST_REFRESH_TIME
        FROM #tmp_LAB101_INIT2
        WHERE DML_IND = 'INSERT';


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'LAB101_DATAMART', 'LAB101_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' UPDATING dbo.LAB101';

        UPDATE
            l101
        SET l101.[CASE_LAB_CONFIRMED_IND]        = rtrim(substring(tli2.CASE_LAB_CONFIRMED_IND, 1, 8))
          , l101.[EIP_ACTUAL_SHIP_DATE]          = tli2.EIP_ACTUAL_SHIP_DATE
          , l101.[EIP_EXPECTED_SHIP_DATE]        = tli2.EIP_ACTUAL_SHIP_DATE
          , l101.[EIP_ISO_IND]                   = rtrim(substring(tli2.EIP_ISO_IND, 1, 8))
          , l101.[EIP_SHIP_LOCATION]             = rtrim(substring(tli2.EIP_SHIP_LOCATION, 1, 100))
          , l101.[EIP_SPEC_ACTUAL_RESHIP_DATE]   = tli2.EIP_SPEC_ACTUAL_RESHIP_DATE
          , l101.[EIP_SPEC_AVAIL_IND]            = rtrim(substring(tli2.EIP_SPEC_AVAIL_IND, 1, 50))
          , l101.[EIP_SPEC_EXPECTED_RESHIP_DATE] = tli2.EIP_SPEC_EXPECTED_RESHIP_DATE
          , l101.[EIP_SPEC_NO_REASON]            = rtrim(substring(tli2.EIP_SPEC_NO_REASON, 1, 100))
          , l101.[EIP_SPEC_NO_REASON_OTH]        = rtrim(substring(tli2.EIP_SPEC_NO_REASON_OTH, 1, 100))
          , l101.[EIP_SPEC_RESHIP_IND]           = rtrim(substring(tli2.EIP_SPEC_RESHIP_IND, 1, 8))
          , l101.[EIP_SPEC_RESHIP_REASON]        = rtrim(substring(tli2.EIP_SPEC_RESHIP_REASON, 1, 100))
          , l101.[EIP_SPEC_RESHIP_REASON_OTH]    = rtrim(substring(tli2.EIP_SPEC_RESHIP_REASON_OTH, 1, 100))
          , l101.[EVENT_DATE]                    = tli2.EVENT_DATE
          , l101.[ISO_NO_RECEIVED_REASON]        = rtrim(substring(tli2.ISO_NO_RECEIVED_REASON, 1, 100))
          , l101.[ISO_NO_RECEIVED_REASON_OTH]    = rtrim(substring(tli2.ISO_NO_RECEIVED_REASON_OTH, 1, 100))
          , l101.[ISO_RECEIVED_DATE]             = tli2.ISO_RECEIVED_DATE
          , l101.[ISO_RECEIVED_IND]              = rtrim(substring(ltrim(rtrim(tli2.ISO_RECEIVED_IND)), 1, 8))
          , l101.[ISO_STATEID_NUM]               = rtrim(substring(tli2.ISO_STATEID_NUM, 1, 100))
          , l101.[LAB_RPT_LOCAL_ID]              = rtrim(substring(tli2.LAB_RPT_LOCAL_ID, 1, 50))
          , l101.[NARMS_ACTUAL_SHIP_DATE]        = tli2.NARMS_ACTUAL_SHIP_DATE
          , l101.[NARMS_EXPECTED_SHIP_DATE]      = tli2.NARMS_EXPECTED_SHIP_DATE
          , l101.[NARMS_ISO_IND]                 = rtrim(substring(tli2.NARMS_ISO_IND, 1, 8))
          , l101.[NARMS_ISO_SENT_IND]            = rtrim(substring(tli2.NARMS_ISO_SENT_IND, 1, 8))
          , l101.[NARMS_NO_SENT_REASON]          = rtrim(substring(tli2.NARMS_NO_SENT_REASON, 1, 100))
          , l101.[NARMS_STATEID_NUM]             = rtrim(substring(tli2.NARMS_STATEID_NUM, 1, 100))
          , l101.[PATIENT_STATUS]                = rtrim(substring(tli2.PATIENT_STATUS, 1, 100))
          , l101.[PFGE_PULSENET_ENZYME1]         = rtrim(substring(tli2.PFGE_PULSENET_ENZYME1, 1, 100))
          , l101.[PFGE_PULSENET_ENZYME2]         = rtrim(substring(tli2.PFGE_PULSENET_ENZYME2, 1, 100))
          , l101.[PFGE_PULSENET_ENZYME3]         = rtrim(substring(tli2.PFGE_PULSENET_ENZYME3, 1, 100))
          , l101.[PFGE_PULSENET_SENT]            = rtrim(substring(tli2.PFGE_PULSENET_SENT, 1, 8))
          , l101.[PFGE_STATELAB_ENZYME1]         = rtrim(substring(tli2.PFGE_STATELAB_ENZYME1, 1, 100))
          , l101.[PFGE_STATELAB_ENZYME2]         = rtrim(substring(tli2.PFGE_STATELAB_ENZYME2, 1, 100))
          , l101.[PFGE_STATELAB_ENZYME3]         = rtrim(substring(tli2.PFGE_STATELAB_ENZYME3, 1, 100))
          , l101.[PROGRAM_JURISDICTION_OID]      = tli2.PROGRAM_JURISDICTION_OID
          , l101.[PULSENET_ISO_IND]              = rtrim(substring(tli2.PULSENET_ISO_IND, 1, 8))
          , l101.[RECORD_STATUS_CD]              = rtrim(substring(tli2.RECORD_STATUS_CD, 1, 8))
          , l101.[RESULTED_LAB_TEST_CD_DESC]     = rtrim(substring(tli2.RESULTED_LAB_TEST_CD_DESC, 1, 100))
          , l101.[RESULTED_LAB_TEST_KEY]         = tli2.RESULTED_LAB_TEST_KEY
          , l101.[SPECIMEN_COLLECTION_DT]        = tli2.SPECIMEN_COLLECTION_DT
          , l101.[SPECIMEN_SRC_DESC]             = rtrim(substring(tli2.SPECIMEN_SRC_DESC, 1, 100))
          , l101.[SPECIMEN_SRC_CD]               = rtrim(substring(tli2.SPECIMEN_SRC_CD, 1, 100))
          , l101.[TRACK_ISO_IND]                 = rtrim(substring(tli2.TRACK_ISO_IND, 1, 8))
          , l101.[ISO_SENT_CDC_IND]              = rtrim(substring(ltrim(rtrim(tli2.ISO_SENT_CDC_IND)), 1, 8))
          , l101.[REPORTING_FACILITY_UID]        = tli2.REPORTING_FACILITY_UID
          , l101.[RDB_LAST_REFRESH_TIME]         = tli2.RDB_LAST_REFRESH_TIME
        FROM dbo.lab101 l101,
             #tmp_LAB101_INIT2 as tli2
        WHERE l101.RESULTED_LAB_TEST_KEY = tli2.RESULTED_LAB_TEST_KEY
          and tli2.DML_IND = 'UPDATE';


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'LAB101_DATAMART', 'LAB101_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'Update Inactive LAB101 Records';


        /* Update records associated to Inactive Orders using LAB_TEST */
        UPDATE l
        SET record_status_cd = 'INACTIVE'
        FROM dbo.LAB101 l
        WHERE
            RESULTED_LAB_TEST_KEY IN (
                SELECT
                    l.RESULTED_LAB_TEST_KEY
                FROM dbo.LAB_TEST lt
                         INNER JOIN dbo.LAB101 l on
                    l.RESULTED_LAB_TEST_KEY = lt.LAB_TEST_KEY
                WHERE
                    ROOT_ORDERED_TEST_PNTR IN
                    (
                        SELECT ROOT_ORDERED_TEST_PNTR
                        FROM dbo.LAB_TEST ltr
                        WHERE
                            LAB_TEST_TYPE = 'Order'
                          AND record_status_cd = 'INACTIVE'
                    )
                  AND l.record_status_cd <> 'INACTIVE'
            );


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'LAB101_DATAMART','LAB101_DATAMART','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'DELETE REMOVED OBSERVATIONS FROM LAB100';

        /* Remove keys in LAB101 that no longer exist in LAB_TEST. */
        DELETE FROM dbo.LAB101
        WHERE RESULTED_LAB_TEST_KEY IN (
            SELECT DISTINCT l.RESULTED_LAB_TEST_KEY
            FROM dbo.LAB101 l
            EXCEPT
            SELECT lt.LAB_TEST_KEY
            FROM dbo.LAB_TEST lt);

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'LAB101_DATAMART','LAB101_DATAMART','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        IF OBJECT_ID('#tmp_ISOLATE_TRACKING_INIT', 'U') IS NOT NULL drop table #tmp_ISOLATE_TRACKING_INIT ;
        IF OBJECT_ID('#tmp_UPDATED_LAB101', 'U') IS NOT NULL drop table #tmp_UPDATED_LAB101 ;
        IF OBJECT_ID('#tmp_ISOLATE_TRACKING_INIT', 'U') IS NOT NULL drop table #tmp_ISOLATE_TRACKING_INIT ;
        IF OBJECT_ID('#tmp_RESULTED_TEST_DETAIL1', 'U') IS NOT NULL drop table #tmp_RESULTED_TEST_DETAIL1 ;
        IF OBJECT_ID('#tmp_RESULTED_TEST_DETAILS', 'U') IS NOT NULL drop table #tmp_RESULTED_TEST_DETAILS ;
        IF OBJECT_ID('#tmp_ISOLATE_TRACKING_LAB330_INIT', 'U') IS NOT NULL
            drop table #tmp_ISOLATE_TRACKING_LAB330_INIT ;
        IF OBJECT_ID('#tmp_RESULTED_TEST_DETAILS_FINAL', 'U') IS NOT NULL drop table #tmp_RESULTED_TEST_DETAILS_FINAL ;
        IF OBJECT_ID('#tmp_ISOLATE_TRACKING_WITH_LAB330', 'U') IS NOT NULL
            drop table #tmp_ISOLATE_TRACKING_WITH_LAB330 ;
        IF OBJECT_ID('#tmp_LAB101_INIT', 'U') IS NOT NULL drop table #tmp_LAB101_INIT ;
        IF OBJECT_ID('#tmp_LAB101_INIT2', 'U') IS NOT NULL drop table #tmp_LAB101_INIT2 ;


        IF OBJECT_ID('#tmp_LAB_TEST_final', 'U') IS NOT NULL drop table #tmp_LAB_TEST_final ;
        IF OBJECT_ID('#tmp_LAB_TEST', 'U') IS NOT NULL drop table #tmp_LAB_TEST ;
        IF OBJECT_ID('#tmp_Lab_Test_Result', 'U') IS NOT NULL drop table #tmp_Lab_Test_Result;
        IF OBJECT_ID('#tmp_TEST_RESULT_GROUPING', 'U') IS NOT NULL drop table #TMP_TEST_RESULT_GROUPING;

        IF OBJECT_ID('#tmp_Lab_Result_Val', 'U') IS NOT NULL
            drop table #tmp_Lab_Result_Val;

        IF OBJECT_ID('#tmp_New_Lab_Result_Comment_FINAL', 'U') IS NOT NULL
            drop table #TMP_New_Lab_Result_Comment_FINAL;


        IF OBJECT_ID('#tmp_LAB_RESULT_VAL_final', 'U') IS NOT NULL drop table #tmp_LAB_RESULT_VAL_final ;
        IF OBJECT_ID('#tmp_TEST_RESULT_GROUPING', 'U') IS NOT NULL drop table #tmp_TEST_RESULT_GROUPING ;
        IF OBJECT_ID('#tmp_D_LAB_TEST_N', 'U') IS NOT NULL drop table #tmp_D_LAB_TEST_N ;
        IF OBJECT_ID('#tmp_LAB_TEST_RESULT', 'U') IS NOT NULL drop table #tmp_LAB_TEST_RESULT ;

        IF OBJECT_ID('#tmp_updated_participant', 'U') IS NOT NULL
            drop table #tmp_updated_participant;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        SET @Proc_Step_Name = 'SP_COMPLETE';


        INSERT INTO dbo.[job_flow_log] ( batch_id
                                       , [Dataflow_Name]
                                       , [package_Name]
                                       , [Status_Type]
                                       , [step_number]
                                       , [step_name]
                                       , [row_count])
        VALUES ( @batch_id,
                 'LAB101_DATAMART'
               , 'LAB101_DATAMART'
               , 'COMPLETE'
               , @Proc_Step_no
               , @Proc_Step_name
               , @RowCount_no);


        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;


        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [Error_Description]
                                         , [row_count])
        VALUES ( @batch_id
               , 'LAB101_DATAMART'
               , 'LAB101_DATAMART'
               , 'ERROR'
               , @Proc_Step_no
               , 'ERROR - ' + @Proc_Step_name
               , 'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
               , 0);


        return -1;

    END CATCH

END

    ;