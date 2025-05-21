CREATE OR ALTER PROCEDURE dbo.[sp_lab100_datamart_postprocessing]
    @labtestuids nvarchar(max), @debug bit = 'false'
as

BEGIN

    DECLARE @batch_id bigint;
    SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmssffff')) AS bigint);
    DECLARE @RowCount_no INT ;
    DECLARE @Proc_Step_no FLOAT = 0 ;
    DECLARE @Proc_Step_Name VARCHAR(200) = '' ;

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';


        BEGIN TRANSACTION;

        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT], [Msg_Description1])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO, LEFT(@labtestuids,500));

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LABTEST_LABTESTRESULT';

        IF OBJECT_ID('#TMP_LABTEST_LABTESTRESULT', 'U') IS NOT NULL
            drop table #TMP_LABTEST_LABTESTRESULT
            ;

        select lt.* ,
               RESULT_COMMENT_GRP_KEY,
               TEST_RESULT_GRP_KEY,
               PERFORMING_LAB_KEY,
               PATIENT_KEY,
               COPY_TO_PROVIDER_KEY,
               LAB_TEST_TECHNICIAN_KEY,
               SPECIMEN_COLLECTOR_KEY,
               ORDERING_ORG_KEY,
               REPORTING_LAB_KEY,
               CONDITION_KEY,
               LAB_RPT_DT_KEY,
               MORB_RPT_KEY,
               INVESTIGATION_KEY,
               LDF_GROUP_KEY,
               ORDERING_PROVIDER_KEY

        into #TMP_LABTEST_LABTESTRESULT
        from
            dbo.LAB_TEST lt with(NOLOCK)
                left outer join
            dbo.LAB_TEST_RESULT  ltr with(NOLOCK) on lt.LAB_TEST_KEY = ltr.LAB_TEST_KEY
        where
            lt.LAB_TEST_KEY <> 1 and lt.lab_test_uid in (
            -- the procedure requires the parent order to be present in the batch and hence the union
            -- also LAB100 is only concerned with Results so adding LAB_TEST_TYPE filter
            select lab_test_uid as uid from dbo.LAB_TEST with(nolock)
            where lab_test_uid in (select value from string_split(@labtestuids, ',')) and LAB_TEST_TYPE = 'Result'
            UNION all
            select ROOT_ORDERED_TEST_PNTR as uid from dbo.LAB_TEST with(nolock)
            where lab_test_uid in(select value from string_split(@labtestuids, ',')) and LAB_TEST_TYPE = 'Result'
        )
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LABTEST_LABTESTRESULT>0', * from #TMP_LABTEST_LABTESTRESULT;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LABTEST_ORDER';

        IF OBJECT_ID('#TMP_LABTEST_ORDER', 'U') IS NOT NULL
            drop table #TMP_LABTEST_ORDER;
            ;

        select
            LAB_TEST_STATUS, LAB_TEST_KEY, LAB_RPT_LOCAL_ID, REASON_FOR_TEST_DESC, RECORD_STATUS_CD,
            LAB_RPT_UID as ORDERED_RPT_UID ,
            LAB_TEST_CD as ORDERED_LAB_TEST_CD ,
            LAB_TEST_CD_DESC as ORDERED_LAB_TEST_CD_DESC ,
            LAB_TEST_CD_SYS_CD as ORDERED_TEST_CODE ,
            LAB_TEST_CD_SYS_NM as ORDERED_LABTEST_CD_SYS_NM ,
            SPECIMEN_DETAILS,
            LAB_TEST_UID as ORDERED_TEST_UID ,
            SPECIMEN_ADD_TIME, SPECIMEN_LAST_CHANGE_TIME, ORDERING_ORG_KEY,
            REPORTING_LAB_KEY as REPORTING_LAB_KEY_ORDER ,
            CONDITION_KEY, INVESTIGATION_KEY, ORDERING_PROVIDER_KEY, LAB_RPT_STATUS, null as OID, CONDITION_CD,
            REASON_FOR_TEST_DESC as REASON_FOR_TEST_DESC1 ,
            SPECIMEN_SRC as SPECIMEN_SRC_CD ,
            SPECIMEN_DESC as  SPECIMEN_SRC_DESC ,
            case when LDF_GROUP_KEY=1 then null else LDF_GROUP_KEY end as LDF_GROUP_KEY,
            case when MORB_RPT_KEY=1 then null else MORB_RPT_KEY end as MORB_RPT_KEY,
            PATIENT_KEY,
            '' as DOCUMENT_LINK, ALT_LAB_TEST_CD_SYS_CD, ALT_LAB_TEST_CD_SYS_NM
                lab_test_type
        into #TMP_LABTEST_ORDER
        from #TMP_LABTEST_LABTESTRESULT
        where lab_test_type = 'Order'
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LABTEST_ORDER', * from #TMP_LABTEST_ORDER;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LABTEST_RESULT';


        IF OBJECT_ID('#TMP_LABTEST_RESULT', 'U') IS NOT NULL
            drop table #TMP_LABTEST_RESULT ;

        select
            LAB_TEST_KEY , LAB_RPT_LOCAL_ID , TEST_METHOD_CD ,
            TEST_METHOD_CD_DESC ,
            LAB_TEST_CD as RESULTED_LAB_TEST_CD ,
            ELR_IND ,
            [LAB_RPT_UID] as RESULTED_RPT_UID ,
            LAB_TEST_CD_DESC as RESULTED_TEST , -- VS
            INTERPRETATION_FLG ,
            LAB_RPT_RECEIVED_BY_PH_DT ,
            [LAB_RPT_CREATED_DT]     as LAB_RPT_CREATED_DT,
            LAB_RPT_CREATED_BY ,
            LAB_TEST_DT,
            LAB_RPT_LAST_UPDATE_DT ,
            JURISDICTION_CD , LAB_TEST_CD_SYS_NM ,
            JURISDICTION_NM ,
            OID,
            ACCESSION_NBR ,
            SPECIMEN_SRC , SPECIMEN_DESC , SPECIMEN_SITE ,
            SPECIMEN_SITE_DESC,
            SPECIMEN_COLLECTION_DT ,
            [LAB_TEST_UID] as RESULTED_TEST_UID ,
            ROOT_ORDERED_TEST_PNTR ,
            PARENT_TEST_PNTR,
            LAB_RPT_DT_KEY ,
            RESULT_COMMENT_GRP_KEY , TEST_RESULT_GRP_KEY ,
            [LAB_RPT_LAST_UPDATE_BY] as PERFORMING_LAB_KEY,
            LAB_RPT_LAST_UPDATE_BY ,
            ALT_LAB_TEST_CD , ALT_LAB_TEST_CD_DESC ,
            ALT_LAB_TEST_CD_SYS_CD , ALT_LAB_TEST_CD_SYS_NM ,
            [LAB_TEST_CD_DESC]    as RESULTED_LAB_TEST_CD_DESC ,
            [LAB_TEST_CD_SYS_NM]  as RESULTEDTEST_CD_SYS_NM ,
            [TEST_METHOD_CD]      as RESULT_TEST_METHOD_CD ,
            [LAB_TEST_KEY]        as RESULTED_LAB_TEST_KEY,
            lab_test_type
        into #TMP_LABTEST_RESULT
        from #TMP_LABTEST_LABTESTRESULT
        where lab_test_type = 'Result'
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LABTEST_RESULT', * from #TMP_LABTEST_RESULT;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_DELETEDMORBS';


        IF OBJECT_ID('#TMP_DELETEDMORBS', 'U') IS NOT NULL
            drop table  #TMP_DELETEDMORBS;
            ;


        SELECT
            mr.MORB_RPT_KEY, ORDERED_TEST_UID
        into #TMP_DELETEDMORBS
        from dbo.MORBIDITY_REPORT mr with(NOLOCK), #TMP_LABTEST_ORDER  tlo
        where mr.RECORD_STATUS_CD='INACTIVE'
          and mr.MORB_RPT_KEY=tlo.MORB_RPT_KEY
        ;

        DELETE FROM #TMP_LABTEST_RESULT
        WHERE ROOT_ORDERED_TEST_PNTR IN (SELECT ORDERED_TEST_UID FROM #TMP_DELETEDMORBS);

        DELETE FROM #TMP_LABTEST_ORDER
        WHERE MORB_RPT_KEY IN (SELECT  MORB_RPT_KEY FROM #TMP_DELETEDMORBS);


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_DELETEDMORBS', * from #TMP_DELETEDMORBS;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LAB_RESULT_VALMODIFIED';

        IF OBJECT_ID('#TMP_LAB_RESULT_VALMODIFIED', 'U') IS NOT NULL
            drop table #TMP_LAB_RESULT_VALMODIFIED;
            ;

        select
            TEST_RESULT_GRP_KEY as TEST_RESULT_GRP_KEY_VAL,
            replace (replace (ltrim(rTRIM(TEST_RESULT_VAL_CD_DESC) + ' ' + RTRIM(LAB_RESULT_TXT_VAL) + ' ' + RTRIM(NUMERIC_RESULT) + ' ' +
                                    RTRIM(RESULT_UNITS)),char(13),','),char(10),' ') as RESULT ,
            TEST_RESULT_VAL_CD , TEST_RESULT_VAL_CD_SYS_NM ,
            ALT_RESULT_VAL_CD      as LOCAL_RESULT_CODE ,
            ALT_RESULT_VAL_CD_DESC as LOCAL_RESULT_NAME ,
            REF_RANGE_FRM          as RESULT_REF_RANGE_FRM ,
            REF_RANGE_TO as RESULT_REF_RANGE_TO ,
            TEST_RESULT_VAL_CD as RESULTEDTEST_VAL_CD ,
            TEST_RESULT_VAL_CD_DESC as RESULTEDTEST_VAL_CD_DESC ,
            (REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lab_result_txt_val,
                                                                     '&#x09;', CHAR(9)),
                                                             '&#x0A;', CHAR(10)),
                                                     '&#x0D;', CHAR(13)),
                                             '&#x20;', CHAR(32)),
                                     '&amp;', CHAR(38)),
                             '&lt;', CHAR(60)),
                     '&gt;', CHAR(62))) as LAB_RESULT_TXT_VAL ,
            RTRIM(NUMERIC_RESULT)+coalesce(' '+RTRIM(RESULT_UNITS),'') as NUMERIC_RESULT_WITHUNITS
        into #TMP_LAB_RESULT_VALMODIFIED
        from dbo.LAB_RESULT_VAL lr with(NOLOCK)
        where TEST_RESULT_GRP_KEY in (
            select distinct TEST_RESULT_GRP_KEY from #TMP_LABTEST_LABTESTRESULT
        )
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LAB_RESULT_VALMODIFIED>0', * from #TMP_LAB_RESULT_VALMODIFIED;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LABTEST_RESULTS_VAL';


        IF OBJECT_ID('#TMP_LABTEST_RESULTS_VAL', 'U') IS NOT NULL
            drop table #TMP_LABTEST_RESULTS_VAL;


        select
            ltr.*, ltrv.*
        into  #TMP_LABTEST_RESULTS_VAL
        from  #TMP_LABTEST_RESULT ltr
                  left outer join  #TMP_LAB_RESULT_VALMODIFIED  ltrv on ltr.TEST_RESULT_GRP_KEY = ltrv.TEST_RESULT_GRP_KEY_VAL
        ;

        alter table #TMP_LABTEST_RESULTS_VAL drop column TEST_RESULT_GRP_KEY_VAL;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LABTEST_RESULTS_VAL', * from #TMP_LABTEST_RESULTS_VAL;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LAB_RESULT_COMMENT';


        IF OBJECT_ID('#TMP_LAB_RESULT_COMMENT', 'U') IS NOT NULL
            drop table #TMP_LAB_RESULT_COMMENT;

        select LAB_TEST_UID
             ,LAB_RESULT_COMMENT_KEY
             , substring(LAB_RESULT_COMMENTS ,1,2000) as [LAB_RESULT_COMMENTS]
             ,RESULT_COMMENT_GRP_KEY
             , substring(RECORD_STATUS_CD ,1,8) as [RECORD_STATUS_CD]
             ,[RDB_LAST_REFRESH_TIME]
        into #TMP_LAB_RESULT_COMMENT
        from (
                 select lrc.*
                 from dbo.LAB_RESULT_COMMENT lrc with(NOLOCK)
                          inner join #TMP_LABTEST_LABTESTRESULT tmp on lrc.LAB_TEST_UID = tmp.LAB_TEST_UID
             ) t;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LAB_RESULT_COMMENT', * from #TMP_LAB_RESULT_COMMENT;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LABTEST_RESULTS_VAL_COMMENT';


        IF OBJECT_ID('#TMP_LABTEST_RESULTS_VAL_COMMENT', 'U') IS NOT NULL
            drop table #TMP_LABTEST_RESULTS_VAL_COMMENT;

        select lrv.*, tlrc.LAB_RESULT_COMMENTS
        into  #TMP_LABTEST_RESULTS_VAL_COMMENT
        from #TMP_LABTEST_RESULTS_VAL lrv
                 left outer join #TMP_LAB_RESULT_COMMENT tlrc on tlrc.RESULT_COMMENT_GRP_KEY = lrv.RESULT_COMMENT_GRP_KEY
        ;

        alter table #TMP_LABTEST_RESULTS_VAL_COMMENT drop column RESULT_COMMENT_GRP_KEY, LAB_RPT_DT_KEY;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LABTEST_RESULTS_VAL_COMMENT', * from #TMP_LABTEST_RESULTS_VAL_COMMENT;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LABTEST_UPDATED';


        IF OBJECT_ID('#TMP_LABTEST_UPDATED', 'U') IS NOT NULL
            drop table  #TMP_LABTEST_UPDATED
            ;


        select
            lrvc1.*,
            PARENT_TEST_PNTR as ORDERED_TEST_UID
        into #TMP_LABTEST_UPDATED
        from #TMP_LABTEST_RESULTS_VAL_COMMENT lrvc1


        --  	select
--  		lrvc1.*,
--  		PARENT_TEST_PNTR as ORDERED_TEST_UID,
--  		cast (RTRIM(UP.FIRST_NM)+','+RTRIM(UP.LAST_NM)  as varchar(150)) as LAB_REPORT_LAST_UPDATED_BY,
--  		case
-- 	 		when cast(RTRIM(coalesce(UP.FIRST_NM,'')+' ')+RTRIM(up.LAST_NM) AS varchar(150))='N ELR' then 'NEDSS_ELR'
--  			else cast(RTRIM(coalesce(UP.FIRST_NM,'')+' ')+RTRIM(up.LAST_NM) AS varchar(150))
--  		end as LAB_REPORT_LAST_UPDATED_BY_UID
--  	INTO #TMP_LABTEST_UPDATED
--  	from #TMP_LABTEST_RESULTS_VAL_COMMENT1 lrvc1
--  	left outer join nbs_odse..user_profile up on up.[NEDSS_ENTRY_ID] = lrvc1.LAB_RPT_LAST_UPDATE_BY
--  	;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LABTEST_UPDATED', * from #TMP_LABTEST_UPDATED;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LABTEST_ORDER1';


        IF OBJECT_ID('#TMP_LABTEST_ORDER1', 'U') IS NOT NULL
            drop table #TMP_LABTEST_ORDER1
            ;


        SELECT
            distinct LTO.*,
                     PATIENT_UID,
                     PATIENT_FIRST_NAME as PERSON_FIRST_NM,
                     PATIENT_MIDDLE_NAME as PERSON_MIDDLE_NM,
                     PATIENT_LAST_NAME as PERSON_LAST_NM,
                     PATIENT_LOCAL_ID as PERSON_LOCAL_ID,
                     PATIENT_DOB as PERSON_DOB,
                     PATIENT_CURRENT_SEX  as PERSON_CURR_GENDER,
                     CAST ( (
                         coalesce(RTRIM(PATIENT_STREET_ADDRESS_1),'')
                             +coalesce(','+RTRIM( PATIENT_STREET_ADDRESS_2),'')
                             +coalesce(','+upper(RTRIM( PATIENT_CITY)),'')
                             +coalesce(','+RTRIM( PATIENT_COUNTY ),'')
                             +coalesce(','+RTRIM( PATIENT_ZIP),'')
                             +coalesce(','+RTRIM( PATIENT_STATE ),'')
                         )	as varchar(725) ) as PATIENT_ADDRESS,
                     PATIENT_STREET_ADDRESS_2,
                     rtrim(PATIENT_CITY) as PATIENT_CITY ,
                     PATIENT_STATE,
                     PATIENT_ZIP as PATIENT_ZIP_CODE,
                     PATIENT_COUNTY,
                     PATIENT_COUNTRY,
                     PATIENT_AGE_REPORTED as AGE_REPORTED,
                     PATIENT_AGE_REPORTED_UNIT as PATIENT_REPORTED_AGE_UNITS,
                     cast ( '' as varchar(10)) as ADDR_USE_CD_DESC,
                     cast ( '' as varchar(10)) as ADDR_CD_DESC

        into #TMP_LABTEST_ORDER1
        FROM #TMP_LABTEST_ORDER LTO
                 LEFT OUTER JOIN dbo.D_PATIENT PAT with(NOLOCK) ON LTO.PATIENT_KEY=PAT.PATIENT_KEY
        ;


        update  #TMP_LABTEST_ORDER1
        set  ADDR_USE_CD_DESC= 'HOME',
             ADDR_CD_DESC='HOUSE'
        where PATIENT_ADDRESS is not null and rtrim(PATIENT_ADDRESS) != ''
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LABTEST_ORDER1', * from #TMP_LABTEST_ORDER1;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING tmp_LAB_RESULTS_ORDER_CONTACT1';

        IF OBJECT_ID('#TMP_LAB_RESULTS_ORDER_CONTACT1', 'U') IS NOT NULL
            drop table #TMP_LAB_RESULTS_ORDER_CONTACT1;

        select
            * , substring(left( oid+ space(11), 11),7,5) as PROGRAM_AREA_ID  --VS =SUBSTR(PUT(OID,11.),7,5)
        into #TMP_LAB_RESULTS_ORDER_CONTACT1
        from #TMP_LABTEST_UPDATED
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LAB_RESULTS_ORDER_CONTACT1', * from #TMP_LAB_RESULTS_ORDER_CONTACT1;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LAB_RESULTS_ORDER_CONTACT2';

        IF OBJECT_ID('#TMP_LAB_RESULTS_ORDER_CONTACT2', 'U') IS NOT NULL
            drop table #TMP_LAB_RESULTS_ORDER_CONTACT2;

        select
            tlroc1.*, pac.*
        into #TMP_LAB_RESULTS_ORDER_CONTACT2
        from #TMP_LAB_RESULTS_ORDER_CONTACT1 tlroc1
                 left outer join dbo.nrt_srte_Program_area_code pac with(NOLOCK)
                                 on left( pac.NBS_UID+ space(5), 5)  = cast(tlroc1.PROGRAM_AREA_ID as int)

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LAB_RESULTS_ORDER_CONTACT2', * from #TMP_LAB_RESULTS_ORDER_CONTACT2;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_PERSON_ORDER_PROVIDER';

        IF OBJECT_ID('#TMP_PERSON_ORDER_PROVIDER', 'U') IS NOT NULL
            drop table #TMP_PERSON_ORDER_PROVIDER;

        SELECT
            LABORDER.*,
            PROVIDER_PHONE_WORK as PROVIDER_PHONE,
            PROVIDER_FIRST_NAME, PROVIDER_MIDDLE_NAME, PROVIDER_LAST_NAME,
            coalesce((RTRIM(PROVIDER_LAST_NAME)),'')+', '+coalesce((RTRIM(PROVIDER_FIRST_NAME)),'')+coalesce(' '+(RTRIM(PROVIDER_MIDDLE_NAME))  ,'')
                                as ORDERING_PROVIDER_NM,
            PROVIDER_STREET_ADDRESS_1,PROVIDER_STREET_ADDRESS_2,
            upper(PROVIDER_CITY) as PROVIDER_CITY,
            PROVIDER_STATE,PROVIDER_ZIP ,
            PROVIDER_COUNTY,PROVIDER_COUNTRY,
            CAST ( (
                coalesce(RTRIM(PROVIDER_STREET_ADDRESS_1),'')
                    +coalesce(','+RTRIM( PROVIDER_STREET_ADDRESS_2),'')
                    +coalesce(','+upper(RTRIM( PROVIDER_CITY)),'')
                    +coalesce(','+RTRIM( PROVIDER_COUNTY ),'')
                    +coalesce(','+RTRIM( PROVIDER_ZIP),'')
                    +coalesce(','+RTRIM( PROVIDER_STATE ),'')
                )	as varchar(725) ) as PROVIDER_ADDRESS,
            cast ( '' as varchar(30)) as PRV_ADDR_USE_CD_DESC,
            cast ( '' as varchar(30)) as PRV_ADDR_CD_DESC
        into #TMP_PERSON_ORDER_PROVIDER
        from dbo.D_PROVIDER P with(NOLOCK),
             #TMP_LABTEST_ORDER1 LABORDER
        where LABORDER.ORDERING_PROVIDER_KEY= P.PROVIDER_KEY
        ;

        update  #TMP_PERSON_ORDER_PROVIDER
        set  PRV_ADDR_USE_CD_DESC='PRIMARY WORK PLACE',
             PRV_ADDR_CD_DESC='OFFICE'
        where PROVIDER_ADDRESS is not null and rtrim(PROVIDER_ADDRESS) != ''
        ;


        update  #TMP_PERSON_ORDER_PROVIDER
        set  PRV_ADDR_USE_CD_DESC=null
        where rtrim(PRV_ADDR_USE_CD_DESC) = ''
        ;

        update  #TMP_PERSON_ORDER_PROVIDER
        set  PRV_ADDR_CD_DESC=null
        where rtrim(PRV_ADDR_CD_DESC) = ''
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_PERSON_ORDER_PROVIDER', * from #TMP_PERSON_ORDER_PROVIDER;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING tmp_lab_REPORTING_ORG';


        IF OBJECT_ID('#TMP_LAB_REPORTING_ORG', 'U') IS NOT NULL
            drop table  #TMP_LAB_REPORTING_ORG  ;

        select
            REPORTING_LAB_KEY_ORDER as REPORTING_LAB_KEY_REPORTING
        into #TMP_LAB_REPORTING_ORG
        FROM #TMP_PERSON_ORDER_PROVIDER;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LAB_REPORTING_ORG', * from #TMP_LAB_REPORTING_ORG;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_ORDERING_ORG';


        IF OBJECT_ID('#TMP_ORDERING_ORG', 'U') IS NOT NULL
            drop table  #TMP_ORDERING_ORG  ;

        select
            ORDERING_ORG_KEY as ORDERING_ORG_KEY_ORDER
        into #TMP_ORDERING_ORG
        from #TMP_PERSON_ORDER_PROVIDER;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_ORDERING_ORG', * from #TMP_ORDERING_ORG;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LAB_ENTITY1';


        IF OBJECT_ID('#TMP_LAB_ENTITY1', 'U') IS NOT NULL
            drop table #TMP_LAB_ENTITY1;

        select
            distinct  A.*,
                      REPORTING_LAB.ORGANIZATION_NAME AS  'REPORTING_FACILITY',
                      REPORTING_LAB.ORGANIZATION_FACILITY_ID AS  'REPORTING_FACILITY_CLIA_NBR',
                      REPORTING_LAB.ORGANIZATION_LOCAL_ID AS  'REPORTING_FACILITY_ID',
                      REPORTING_LAB.ORGANIZATION_UID AS  'REPORTING_FACILITY_UID',
                      REPORTING_LAB.ORGANIZATION_PHONE_WORK AS  'REPORTING_FACILITY_PHONE_NBR'
        into #TMP_LAB_ENTITY1
        from #TMP_LAB_REPORTING_ORG A ,
             dbo.D_ORGANIZATION REPORTING_LAB with(NOLOCK)
        where REPORTING_LAB.ORGANIZATION_KEY=A.REPORTING_LAB_KEY_REPORTING;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_ORDERING_ORG', * from #TMP_ORDERING_ORG;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LAB_ENTITY2';

        IF OBJECT_ID('#TMP_LAB_ENTITY2', 'U') IS NOT NULL
            drop table #TMP_LAB_ENTITY2;

        select
            distinct A.*,
                     ORDERING_ORG.ORGANIZATION_LOCAL_ID AS  'ORDERING_FACILITY_ID',
                     ORDERING_ORG.ORGANIZATION_NAME AS  'ORDERING_FACILITY',
                     ORDERING_ORG.ORGANIZATION_PHONE_WORK AS    'ORDERING_FACILITY_PHONE_NBR'
        into #TMP_LAB_ENTITY2
        from #TMP_ORDERING_ORG A ,
             dbo.D_ORGANIZATION ORDERING_ORG with(NOLOCK)
        where ORDERING_ORG.ORGANIZATION_KEY=A.ORDERING_ORG_KEY_ORDER
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LAB_ENTITY2', * from #TMP_LAB_ENTITY2;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LAB_ORDER_ENTITY1';

        IF OBJECT_ID('#TMP_LAB_ORDER_ENTITY1', 'U') IS NOT NULL
            drop table #TMP_LAB_ORDER_ENTITY1;

        select
            distinct le.*,pop.*
        into #TMP_LAB_ORDER_ENTITY1
        from #TMP_LAB_ENTITY1 le,
             #tmp_PERSON_ORDER_PROVIDER pop
        where  le.REPORTING_LAB_KEY_REPORTING= pop.REPORTING_LAB_KEY_ORDER
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LAB_ORDER_ENTITY1', * from #TMP_LAB_ORDER_ENTITY1;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LAB_ORDER_ENTITY_KEY';

        IF OBJECT_ID('#TMP_LAB_ORDER_ENTITY_KEY', 'U') IS NOT NULL
            drop table #TMP_LAB_ORDER_ENTITY_KEY;

        select
            ORDERING_ORG_KEY_ORDER
        into #TMP_LAB_ORDER_ENTITY_KEY
        from #TMP_LAB_ENTITY2
        union
        select
            ORDERING_ORG_KEY
        from #TMP_LAB_ORDER_ENTITY1
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LAB_ORDER_ENTITY_KEY', * from #TMP_LAB_ORDER_ENTITY_KEY;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LAB_ORDER_ENTITY11';


        IF OBJECT_ID('#TMP_LAB_ORDER_ENTITY11', 'U') IS NOT NULL
            drop table #TMP_LAB_ORDER_ENTITY11
            ;

        select
            distinct coalesce(e2.ORDERING_ORG_KEY_ORDER, e1.REPORTING_LAB_KEY_REPORTING) as ORDERING_ORG_KEY_MAIN,e2.*,e1.*,
                     cast(null as varchar(2000)) as  INVESTIGATION_KEYS,
                     cast(null as bigint) as  INV_KEY
        into #TMP_LAB_ORDER_ENTITY11
        from #TMP_LAB_ORDER_ENTITY_KEY loek
                 left outer join #TMP_LAB_ENTITY2 e2 on e2.ORDERING_ORG_KEY_ORDER = loek.ORDERING_ORG_KEY_ORDER
                 left outer join #tmp_LAB_ORDER_ENTITY1 e1 on e1.ORDERING_ORG_KEY = loek.ORDERING_ORG_KEY_ORDER
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LAB_ORDER_ENTITY11', * from #TMP_LAB_ORDER_ENTITY11;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LAB_ORDER_ENTITY11_INVKEYS';

        IF OBJECT_ID('#TMP_LAB_ORDER_ENTITY11_INVKEYS', 'U') IS NOT NULL
            drop table  #TMP_LAB_ORDER_ENTITY11_INVKEYS
            ;

        select
            tloe1.lab_test_key
             , stuff((
                         select ', ' + cast(tloe2.investigation_key as varchar)
                         from #TMP_LAB_ORDER_ENTITY11  tloe2
                         where tloe2.lab_test_key = tloe1.lab_test_key
                         group by tloe2.investigation_key
                         order by tloe2.investigation_key
                         for xml path('')
                     ),1,2,'') as INVESTIGATION_KEYS
        into #TMP_LAB_ORDER_ENTITY11_INVKEYS
        from #TMP_LAB_ORDER_ENTITY11  tloe1
        group by tloe1.lab_test_key
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LAB_ORDER_ENTITY11_INVKEYS', * from #TMP_LAB_ORDER_ENTITY11_INVKEYS;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LAB_ORDER_ENTITY';

        IF OBJECT_ID('#TMP_LAB_ORDER_ENTITY', 'U') IS NOT NULL
            drop table  #TMP_LAB_ORDER_ENTITY
            ;

        select
            distinct [ORDERING_ORG_KEY_MAIN]
                   ,[ORDERING_ORG_KEY_ORDER]
                   ,[ORDERING_FACILITY_ID]
                   ,[ORDERING_FACILITY]
                   ,[ORDERING_FACILITY_PHONE_NBR]
                   ,[REPORTING_LAB_KEY_REPORTING]
                   ,[REPORTING_FACILITY]
                   ,[REPORTING_FACILITY_CLIA_NBR]
                   ,[REPORTING_FACILITY_ID]
                   ,[REPORTING_FACILITY_UID]
                   ,[REPORTING_FACILITY_PHONE_NBR]
                   ,[LAB_TEST_STATUS]
                   ,loe11.[LAB_TEST_KEY] as LAB_TEST_KEY_OE
                   ,[LAB_RPT_LOCAL_ID] as LAB_RPT_LOCAL_ID_OE
                   ,[REASON_FOR_TEST_DESC]
                   ,[RECORD_STATUS_CD]
                   ,[ORDERED_RPT_UID]
                   ,[ORDERED_LAB_TEST_CD]
                   ,[ORDERED_LAB_TEST_CD_DESC]
                   ,[ORDERED_TEST_CODE]
                   ,[ORDERED_LABTEST_CD_SYS_NM]
                   ,[SPECIMEN_DETAILS]
                   ,[ORDERED_TEST_UID] as ORDERED_TEST_UID_OE
                   ,[SPECIMEN_ADD_TIME]
                   ,[SPECIMEN_LAST_CHANGE_TIME]
                   ,[ORDERING_ORG_KEY]
                   ,[REPORTING_LAB_KEY_ORDER]
                   ,[CONDITION_KEY]
                        -- ,[INVESTIGATION_KEY]
                   ,[ORDERING_PROVIDER_KEY]
                   ,[LAB_RPT_STATUS]
                   ,[OID] as oid_order
                   ,[CONDITION_CD]
                   ,[REASON_FOR_TEST_DESC1]
                   ,[SPECIMEN_SRC_CD]
                   ,[SPECIMEN_SRC_DESC]
                   ,[LDF_GROUP_KEY]
                   ,[MORB_RPT_KEY]
                   ,[PATIENT_KEY]
                   ,[DOCUMENT_LINK]
                   ,[ALT_LAB_TEST_CD_SYS_CD] as ALT_LAB_TEST_CD_SYS_CD_OE
                   ,[lab_test_type] as lab_test_type_oe
                   ,[PATIENT_UID]
                   ,[PERSON_FIRST_NM]
                   ,[PERSON_MIDDLE_NM]
                   ,[PERSON_LAST_NM]
                   ,[PERSON_LOCAL_ID]
                   ,[PERSON_DOB]
                   ,[PERSON_CURR_GENDER]
                   ,[PATIENT_ADDRESS]
                   ,[PATIENT_STREET_ADDRESS_2]
                   ,[PATIENT_CITY]
                   ,[PATIENT_STATE]
                   ,[PATIENT_ZIP_CODE]
                   ,[PATIENT_COUNTY]
                   ,[PATIENT_COUNTRY]
                   ,[AGE_REPORTED]
                   ,[PATIENT_REPORTED_AGE_UNITS]
                   ,[ADDR_USE_CD_DESC]
                   ,[ADDR_CD_DESC]
                   ,[PROVIDER_PHONE]
                   ,[PROVIDER_FIRST_NAME]
                   ,[PROVIDER_MIDDLE_NAME]
                   ,[PROVIDER_LAST_NAME]
                   ,[ORDERING_PROVIDER_NM]
                   ,[PROVIDER_STREET_ADDRESS_1]
                   ,[PROVIDER_STREET_ADDRESS_2]
                   ,[PROVIDER_CITY]
                   ,[PROVIDER_STATE]
                   ,[PROVIDER_ZIP]
                   ,[PROVIDER_COUNTY]
                   ,[PROVIDER_COUNTRY]
                   ,[PROVIDER_ADDRESS]
                   ,[PRV_ADDR_USE_CD_DESC]
                   ,[PRV_ADDR_CD_DESC]
                   ,loei.[INVESTIGATION_KEYS]
                   ,[INV_KEY]
        into #TMP_LAB_ORDER_ENTITY
        from #TMP_LAB_ORDER_ENTITY11 loe11
                 left outer join #TMP_LAB_ORDER_ENTITY11_INVKEYS loei on loei.lab_test_key = loe11.lab_test_key
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LAB_ORDER_ENTITY', * from #TMP_LAB_ORDER_ENTITY;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LABTESTSINIT';

        IF OBJECT_ID('#TMP_LABTESTSINIT', 'U') IS NOT NULL
            drop table #TMP_LABTESTSINIT;

        select *
        into #TMP_LABTESTSINIT
        from  #TMP_LAB_ORDER_ENTITY loe
                  left outer join #TMP_LABTEST_UPDATED loeu on loe.ORDERED_TEST_UID_OE=loeu.ORDERED_TEST_UID
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LABTESTSINIT', * from #TMP_LABTESTSINIT;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LABTESTS';

        IF OBJECT_ID('#TMP_LABTESTS', 'U') IS NOT NULL
            drop table #TMP_LABTESTS
            ;

        SELECT
            li.*
             , lroc2.code_seq
             , lroc2.code_set_nm
             , lroc2.nbs_uid
             , lroc2.prog_area_cd
             , lroc2.prog_area_desc_txt
             , lroc2.PROGRAM_AREA_ID
             , lroc2.status_cd
             , lroc2.status_time
             , CONDITION_SHORT_NM
             ,  case
                    when UPPER(li.LAB_TEST_CD_SYS_NM)='LOINC' then ORDERED_LAB_TEST_CD
                    else cast ( null as varchar(50))
            end as LOINC
             , cast ( null as varchar(50)) as  CONDITION
        into #TMP_LABTESTS
        from #TMP_LABTESTSINIT li
                 left outer join dbo.nrt_srte_Condition_code cc with(NOLOCK) on cc.CONDITION_CD = li.CONDITION_CD
                 left outer join #TMP_LAB_RESULTS_ORDER_CONTACT2  lroc2 on lroc2.RESULTED_TEST_UID = li.RESULTED_TEST_UID
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LABTESTS', * from #TMP_LABTESTS;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LABTESTS2';


        IF OBJECT_ID('#TMP_LABTESTS2', 'U') IS NOT NULL
            drop table  #TMP_LABTESTS2
            ;

        select
            tl.ORDERING_ORG_KEY_MAIN,
            tl.ORDERING_ORG_KEY_ORDER,
            tl.ORDERING_FACILITY_ID,
            tl.ORDERING_FACILITY,
            tl.ORDERING_FACILITY_PHONE_NBR,
            tl.REPORTING_LAB_KEY_REPORTING,
            tl.REPORTING_FACILITY,
            tl.REPORTING_FACILITY_CLIA_NBR,
            tl.REPORTING_FACILITY_ID,
            tl.REPORTING_FACILITY_UID,
            tl.REPORTING_FACILITY_PHONE_NBR,
            tl.LAB_TEST_STATUS,
            tl.LAB_TEST_KEY_OE,
            tl.LAB_RPT_LOCAL_ID_OE,
            tl.REASON_FOR_TEST_DESC,
            tl.RECORD_STATUS_CD,
            tl.ORDERED_RPT_UID,
            tl.ORDERED_LAB_TEST_CD,
            tl.ORDERED_LAB_TEST_CD_DESC,
            tl.ORDERED_TEST_CODE,
            tl.ORDERED_LABTEST_CD_SYS_NM,
            tl.SPECIMEN_DETAILS,
            tl.ORDERED_TEST_UID_OE,
            tl.SPECIMEN_ADD_TIME,
            tl.SPECIMEN_LAST_CHANGE_TIME,
            tl.ORDERING_ORG_KEY,
            tl.REPORTING_LAB_KEY_ORDER,
            tl.CONDITION_KEY,
            tl.ORDERING_PROVIDER_KEY,
            tl.LAB_RPT_STATUS,
            tl.oid_order,
            tl.CONDITION_CD,
            tl.REASON_FOR_TEST_DESC1,
            tl.SPECIMEN_SRC_CD,
            tl.SPECIMEN_SRC_DESC,
            tl.LDF_GROUP_KEY,
            tl.MORB_RPT_KEY,
            tl.PATIENT_KEY,
            tl.DOCUMENT_LINK,
            tl.ALT_LAB_TEST_CD_SYS_CD_OE,
            tl.lab_test_type_oe,
            tl.PATIENT_UID,
            tl.PERSON_FIRST_NM,
            tl.PERSON_MIDDLE_NM,
            tl.PERSON_LAST_NM,
            tl.PERSON_LOCAL_ID,
            tl.PERSON_DOB,
            tl.PERSON_CURR_GENDER,
            tl.PATIENT_ADDRESS,
            tl.PATIENT_STREET_ADDRESS_2,
            tl.PATIENT_CITY,
            tl.PATIENT_STATE,
            tl.PATIENT_ZIP_CODE,
            tl.PATIENT_COUNTY,
            tl.PATIENT_COUNTRY,
            tl.AGE_REPORTED,
            tl.PATIENT_REPORTED_AGE_UNITS,
            tl.ADDR_USE_CD_DESC,
            tl.ADDR_CD_DESC,
            tl.PROVIDER_PHONE,
            tl.PROVIDER_FIRST_NAME,
            tl.PROVIDER_MIDDLE_NAME,
            tl.PROVIDER_LAST_NAME,
            tl.ORDERING_PROVIDER_NM,
            tl.PROVIDER_STREET_ADDRESS_1,
            tl.PROVIDER_STREET_ADDRESS_2,
            tl.PROVIDER_CITY,
            tl.PROVIDER_STATE,
            tl.PROVIDER_ZIP,
            tl.PROVIDER_COUNTY,
            tl.PROVIDER_COUNTRY,
            tl.PROVIDER_ADDRESS,
            tl.PRV_ADDR_USE_CD_DESC,
            tl.PRV_ADDR_CD_DESC,
            tl.INVESTIGATION_KEYS,
            tl.INV_KEY,
            tl.LAB_TEST_KEY,
            tl.LAB_RPT_LOCAL_ID,
            tl.TEST_METHOD_CD,
            tl.TEST_METHOD_CD_DESC,
            tl.RESULTED_LAB_TEST_CD,
            tl.ELR_IND,
            tl.RESULTED_RPT_UID,
            tl.RESULTED_TEST,
            tl.INTERPRETATION_FLG,
            tl.LAB_RPT_RECEIVED_BY_PH_DT,
            tl.LAB_RPT_CREATED_DT,
            tl.LAB_RPT_CREATED_BY,
            tl.LAB_TEST_DT,
            tl.LAB_RPT_LAST_UPDATE_DT,
            tl.JURISDICTION_CD,
            tl.LAB_TEST_CD_SYS_NM,
            tl.JURISDICTION_NM,
            tl.OID,
            tl.ACCESSION_NBR,
            tl.SPECIMEN_SRC,
            tl.SPECIMEN_DESC,
            tl.SPECIMEN_SITE,
            tl.SPECIMEN_SITE_DESC,
            tl.SPECIMEN_COLLECTION_DT,
            tl.RESULTED_TEST_UID,
            tl.ROOT_ORDERED_TEST_PNTR,
            tl.PARENT_TEST_PNTR,
            tl.TEST_RESULT_GRP_KEY,
            tl.PERFORMING_LAB_KEY,
            tl.ALT_LAB_TEST_CD,
            tl.ALT_LAB_TEST_CD_DESC,
            tl.ALT_LAB_TEST_CD_SYS_CD,
            tl.ALT_LAB_TEST_CD_SYS_NM,
            tl.RESULTED_LAB_TEST_CD_DESC,
            tl.RESULTEDTEST_CD_SYS_NM,
            tl.RESULT_TEST_METHOD_CD,
            tl.RESULTED_LAB_TEST_KEY,
            tl.lab_test_type,
            tl.RESULT,
            tl.TEST_RESULT_VAL_CD,
            tl.TEST_RESULT_VAL_CD_SYS_NM,
            tl.LOCAL_RESULT_CODE,
            tl.LOCAL_RESULT_NAME,
            tl.RESULT_REF_RANGE_FRM,
            tl.RESULT_REF_RANGE_TO,
            tl.RESULTEDTEST_VAL_CD,
            tl.RESULTEDTEST_VAL_CD_DESC,
            tl.LAB_RESULT_TXT_VAL,
            tl.NUMERIC_RESULT_WITHUNITS,
            tl.LAB_RESULT_COMMENTS,
            tl.ORDERED_TEST_UID,
            tl.code_seq,
            tl.code_set_nm,
            tl.nbs_uid,
            tl.prog_area_cd,
            tl.prog_area_desc_txt,
            tl.PROGRAM_AREA_ID,
            tl.status_cd,
            tl.status_time,
            tl.CONDITION_SHORT_NM,
            case
                when ltrim(rtrim(tl.LOINC)) is null and charindex('-',ORDERED_LAB_TEST_CD) > 3 then ORDERED_LAB_TEST_CD
                when ltrim(rtrim(tl.LOINC)) is null then loinc_cd
                else tl.LOINC
                end as LOINC,
            tl.CONDITION
        into #TMP_LABTESTS2
        from #TMP_LABTESTS tl
                 left outer join dbo.nrt_srte_Labtest_loinc ll  on ll.LAB_TEST_CD = tl.ORDERED_LAB_TEST_CD
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LABTESTS2', * from #TMP_LABTESTS2;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LABTESTS3';


        IF OBJECT_ID('#TMP_LABTESTS3', 'U') IS NOT NULL
            drop table  #TMP_LABTESTS3 ;

        select

            lt2.ORDERING_ORG_KEY_MAIN,
            lt2.ORDERING_ORG_KEY_ORDER,
            lt2.ORDERING_FACILITY_ID,
            lt2.ORDERING_FACILITY,
            lt2.ORDERING_FACILITY_PHONE_NBR,
            lt2.REPORTING_LAB_KEY_REPORTING,
            lt2.REPORTING_FACILITY,
            lt2.REPORTING_FACILITY_CLIA_NBR,
            lt2.REPORTING_FACILITY_ID,
            lt2.REPORTING_FACILITY_UID,
            lt2.REPORTING_FACILITY_PHONE_NBR,
            lt2.LAB_TEST_STATUS,
            lt2.LAB_TEST_KEY_OE,
            lt2.LAB_RPT_LOCAL_ID_OE,
            lt2.REASON_FOR_TEST_DESC,
            lt2.RECORD_STATUS_CD,
            lt2.ORDERED_RPT_UID,
            lt2.ORDERED_LAB_TEST_CD,
            lt2.ORDERED_LAB_TEST_CD_DESC,
            lt2.ORDERED_TEST_CODE,
            lt2.ORDERED_LABTEST_CD_SYS_NM,
            lt2.SPECIMEN_DETAILS,
            lt2.ORDERED_TEST_UID_OE,
            lt2.SPECIMEN_ADD_TIME,
            lt2.SPECIMEN_LAST_CHANGE_TIME,
            lt2.ORDERING_ORG_KEY,
            lt2.REPORTING_LAB_KEY_ORDER,
            lt2.CONDITION_KEY,
            lt2.ORDERING_PROVIDER_KEY,
            lt2.LAB_RPT_STATUS,
            lt2.oid_order,
            case
                when RTRIM(LTRIM(lt2.CONDITION_SHORT_NM))=''
                    or RTRIM(LTRIM(lt2.CONDITION_SHORT_NM)) is null then lc.condition_cd
                else lt2.CONDITION_CD
                end as CONDITION_CD,
            lt2.REASON_FOR_TEST_DESC1,
            lt2.SPECIMEN_SRC_CD,
            lt2.SPECIMEN_SRC_DESC,
            lt2.LDF_GROUP_KEY,
            lt2.MORB_RPT_KEY,
            lt2.PATIENT_KEY,
            lt2.DOCUMENT_LINK,
            lt2.ALT_LAB_TEST_CD_SYS_CD_OE,
            lt2.lab_test_type_oe,
            lt2.PATIENT_UID,
            lt2.PERSON_FIRST_NM,
            lt2.PERSON_MIDDLE_NM,
            lt2.PERSON_LAST_NM,
            lt2.PERSON_LOCAL_ID,
            lt2.PERSON_DOB,
            lt2.PERSON_CURR_GENDER,
            lt2.PATIENT_ADDRESS,
            lt2.PATIENT_STREET_ADDRESS_2,
            lt2.PATIENT_CITY,
            lt2.PATIENT_STATE,
            lt2.PATIENT_ZIP_CODE,
            lt2.PATIENT_COUNTY,
            lt2.PATIENT_COUNTRY,
            lt2.AGE_REPORTED,
            lt2.PATIENT_REPORTED_AGE_UNITS,
            lt2.ADDR_USE_CD_DESC,
            lt2.ADDR_CD_DESC,
            lt2.PROVIDER_PHONE,
            lt2.PROVIDER_FIRST_NAME,
            lt2.PROVIDER_MIDDLE_NAME,
            lt2.PROVIDER_LAST_NAME,
            lt2.ORDERING_PROVIDER_NM,
            lt2.PROVIDER_STREET_ADDRESS_1,
            lt2.PROVIDER_STREET_ADDRESS_2,
            lt2.PROVIDER_CITY,
            lt2.PROVIDER_STATE,
            lt2.PROVIDER_ZIP,
            lt2.PROVIDER_COUNTY,
            lt2.PROVIDER_COUNTRY,
            lt2.PROVIDER_ADDRESS,
            lt2.PRV_ADDR_USE_CD_DESC,
            lt2.PRV_ADDR_CD_DESC,
            lt2.INVESTIGATION_KEYS,
            lt2.INV_KEY,
            lt2.LAB_TEST_KEY,
            lt2.LAB_RPT_LOCAL_ID,
            lt2.TEST_METHOD_CD,
            lt2.TEST_METHOD_CD_DESC,
            lt2.RESULTED_LAB_TEST_CD,
            lt2.ELR_IND,
            lt2.RESULTED_RPT_UID,
            lt2.RESULTED_TEST,
            lt2.INTERPRETATION_FLG,
            lt2.LAB_RPT_RECEIVED_BY_PH_DT,
            lt2.LAB_RPT_CREATED_DT,
            lt2.LAB_RPT_CREATED_BY,
            lt2.LAB_TEST_DT,
            lt2.LAB_RPT_LAST_UPDATE_DT,
            lt2.JURISDICTION_CD,
            lt2.LAB_TEST_CD_SYS_NM,
            lt2.JURISDICTION_NM,
            lt2.OID,
            lt2.ACCESSION_NBR,
            lt2.SPECIMEN_SRC,
            lt2.SPECIMEN_DESC,
            lt2.SPECIMEN_SITE,
            lt2.SPECIMEN_SITE_DESC,
            lt2.SPECIMEN_COLLECTION_DT,
            lt2.RESULTED_TEST_UID,
            lt2.ROOT_ORDERED_TEST_PNTR,
            lt2.PARENT_TEST_PNTR,
            lt2.TEST_RESULT_GRP_KEY,
            lt2.PERFORMING_LAB_KEY,
            lt2.ALT_LAB_TEST_CD,
            lt2.ALT_LAB_TEST_CD_DESC,
            lt2.ALT_LAB_TEST_CD_SYS_CD,
            lt2.ALT_LAB_TEST_CD_SYS_NM,
            lt2.RESULTED_LAB_TEST_CD_DESC,
            lt2.RESULTEDTEST_CD_SYS_NM,
            lt2.RESULT_TEST_METHOD_CD,
            lt2.RESULTED_LAB_TEST_KEY,
            lt2.lab_test_type,
            lt2.RESULT,
            lt2.TEST_RESULT_VAL_CD,
            lt2.TEST_RESULT_VAL_CD_SYS_NM,
            lt2.LOCAL_RESULT_CODE,
            lt2.LOCAL_RESULT_NAME,
            lt2.RESULT_REF_RANGE_FRM,
            lt2.RESULT_REF_RANGE_TO,
            lt2.RESULTEDTEST_VAL_CD,
            lt2.RESULTEDTEST_VAL_CD_DESC,
            lt2.LAB_RESULT_TXT_VAL,
            lt2.NUMERIC_RESULT_WITHUNITS,
            lt2.LAB_RESULT_COMMENTS,
            lt2.ORDERED_TEST_UID,
            lt2.code_seq,
            lt2.code_set_nm,
            lt2.nbs_uid,
            lt2.prog_area_cd,
            lt2.prog_area_desc_txt,
            lt2.PROGRAM_AREA_ID,
            lt2.status_cd,
            lt2.status_time,
            case
                when RTRIM(LTRIM(lt2.CONDITION_SHORT_NM))='' or RTRIM(LTRIM(lt2.CONDITION_SHORT_NM)) is null then lc.DISEASE_NM
                else lt2.CONDITION_SHORT_NM
                end as CONDITION_SHORT_NM,
            lt2.LOINC,
            lt2.CONDITION
        into #TMP_LABTESTS3
        from #TMP_LABTESTS2 lt2
                 left outer join dbo.nrt_srte_Loinc_condition lc with(NOLOCK) on lc.loinc_cd = lt2.LOINC
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LABTESTS3', * from #TMP_LABTESTS3;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING TMP_LABTESTS4';

        IF OBJECT_ID('#TMP_LABTESTS4', 'U') IS NOT NULL
            drop table  #TMP_LABTESTS4
            ;

        select
            lt3.ORDERING_ORG_KEY_MAIN,
            lt3.ORDERING_ORG_KEY_ORDER,
            lt3.ORDERING_FACILITY_ID,
            lt3.ORDERING_FACILITY,
            lt3.ORDERING_FACILITY_PHONE_NBR,
            lt3.REPORTING_LAB_KEY_REPORTING,
            lt3.REPORTING_FACILITY,
            lt3.REPORTING_FACILITY_CLIA_NBR,
            lt3.REPORTING_FACILITY_ID,
            lt3.REPORTING_FACILITY_UID,
            lt3.REPORTING_FACILITY_PHONE_NBR,
            lt3.LAB_TEST_STATUS,
            lt3.LAB_TEST_KEY_OE,
            lt3.LAB_RPT_LOCAL_ID_OE,
            lt3.REASON_FOR_TEST_DESC,
            lt3.RECORD_STATUS_CD,
            lt3.ORDERED_RPT_UID,
            lt3.ORDERED_LAB_TEST_CD,
            lt3.ORDERED_LAB_TEST_CD_DESC,
            lt3.ORDERED_TEST_CODE,
            lt3.ORDERED_LABTEST_CD_SYS_NM,
            lt3.SPECIMEN_DETAILS,
            lt3.ORDERED_TEST_UID_OE,
            lt3.SPECIMEN_ADD_TIME,
            lt3.SPECIMEN_LAST_CHANGE_TIME,
            lt3.ORDERING_ORG_KEY,
            lt3.REPORTING_LAB_KEY_ORDER,
            lt3.CONDITION_KEY,
            lt3.ORDERING_PROVIDER_KEY,
            lt3.LAB_RPT_STATUS,
            lt3.oid_order,
            case
                when TEST_RESULT_VAL_CD   like '%[^0-9]%' and SUBSTRING(TEST_RESULT_VAL_CD,2,1) = '-'
                    and (lt3.CONDITION_CD='' or lt3.CONDITION_CD is null) then sc.DISEASE_NM
                else lt3.CONDITION_CD
                end as CONDITION_CD,
            lt3.REASON_FOR_TEST_DESC1,
            lt3.SPECIMEN_SRC_CD,
            lt3.SPECIMEN_SRC_DESC,
            lt3.LDF_GROUP_KEY,
            lt3.MORB_RPT_KEY,
            lt3.PATIENT_KEY,
            lt3.DOCUMENT_LINK,
            lt3.ALT_LAB_TEST_CD_SYS_CD_OE,
            lt3.lab_test_type_oe,
            lt3.PATIENT_UID,
            lt3.PERSON_FIRST_NM,
            lt3.PERSON_MIDDLE_NM,
            lt3.PERSON_LAST_NM,
            lt3.PERSON_LOCAL_ID,
            lt3.PERSON_DOB,
            lt3.PERSON_CURR_GENDER,
            case
                when rtrim(Patient_Address) = '' then null
                else  lt3.PATIENT_ADDRESS
                end as PATIENT_ADDRESS,
            lt3.PATIENT_STREET_ADDRESS_2,
            lt3.PATIENT_CITY,
            lt3.PATIENT_STATE,
            lt3.PATIENT_ZIP_CODE,
            lt3.PATIENT_COUNTY,
            lt3.PATIENT_COUNTRY,
            lt3.AGE_REPORTED,
            lt3.PATIENT_REPORTED_AGE_UNITS,
            case
                when rtrim(lt3.ADDR_USE_CD_DESC) = '' then null
                else lt3.ADDR_USE_CD_DESC
                end as ADDR_USE_CD_DESC,
            case
                when rtrim(lt3.ADDR_CD_DESC) = '' then null
                else lt3.ADDR_CD_DESC
                end as ADDR_CD_DESC,
            lt3.PROVIDER_PHONE,
            lt3.PROVIDER_FIRST_NAME,
            lt3.PROVIDER_MIDDLE_NAME,
            lt3.PROVIDER_LAST_NAME,
            lt3.ORDERING_PROVIDER_NM,
            lt3.PROVIDER_STREET_ADDRESS_1,
            lt3.PROVIDER_STREET_ADDRESS_2,
            lt3.PROVIDER_CITY,
            lt3.PROVIDER_STATE,
            lt3.PROVIDER_ZIP,
            lt3.PROVIDER_COUNTY,
            lt3.PROVIDER_COUNTRY,
            case
                when rtrim(PROVIDER_ADDRESS) = '' then null
                else lt3.PROVIDER_ADDRESS
                end as PROVIDER_ADDRESS,
            lt3.PRV_ADDR_USE_CD_DESC,
            lt3.PRV_ADDR_CD_DESC,
            lt3.INVESTIGATION_KEYS,
            lt3.INV_KEY,
            lt3.LAB_TEST_KEY,
            lt3.LAB_RPT_LOCAL_ID,
            lt3.TEST_METHOD_CD,
            lt3.TEST_METHOD_CD_DESC,
            lt3.RESULTED_LAB_TEST_CD,
            lt3.ELR_IND,
            lt3.RESULTED_RPT_UID,
            lt3.RESULTED_TEST,
            lt3.INTERPRETATION_FLG,
            lt3.LAB_RPT_RECEIVED_BY_PH_DT,
            lt3.LAB_RPT_CREATED_DT,
            lt3.LAB_RPT_CREATED_BY,
            lt3.LAB_TEST_DT,
            lt3.LAB_RPT_LAST_UPDATE_DT,
            lt3.JURISDICTION_CD,
            lt3.LAB_TEST_CD_SYS_NM,
            lt3.JURISDICTION_NM,
            lt3.OID,
            lt3.ACCESSION_NBR,
            lt3.SPECIMEN_SRC,
            lt3.SPECIMEN_DESC,
            lt3.SPECIMEN_SITE,
            lt3.SPECIMEN_SITE_DESC,
            lt3.SPECIMEN_COLLECTION_DT,
            lt3.RESULTED_TEST_UID,
            lt3.ROOT_ORDERED_TEST_PNTR,
            lt3.PARENT_TEST_PNTR,
            lt3.TEST_RESULT_GRP_KEY,
            lt3.PERFORMING_LAB_KEY,
            lt3.ALT_LAB_TEST_CD,
            lt3.ALT_LAB_TEST_CD_DESC,
            lt3.ALT_LAB_TEST_CD_SYS_CD,
            lt3.ALT_LAB_TEST_CD_SYS_NM,
            lt3.RESULTED_LAB_TEST_CD_DESC,
            lt3.RESULTEDTEST_CD_SYS_NM,
            lt3.RESULT_TEST_METHOD_CD,
            lt3.RESULTED_LAB_TEST_KEY,
            lt3.lab_test_type,
            lt3.RESULT,
            lt3.TEST_RESULT_VAL_CD,
            lt3.TEST_RESULT_VAL_CD_SYS_NM,
            lt3.LOCAL_RESULT_CODE,
            lt3.LOCAL_RESULT_NAME,
            lt3.RESULT_REF_RANGE_FRM,
            lt3.RESULT_REF_RANGE_TO,
            lt3.RESULTEDTEST_VAL_CD,
            lt3.RESULTEDTEST_VAL_CD_DESC,
            lt3.LAB_RESULT_TXT_VAL,
            lt3.NUMERIC_RESULT_WITHUNITS,
            lt3.LAB_RESULT_COMMENTS,
            lt3.ORDERED_TEST_UID,
            lt3.code_seq,
            lt3.code_set_nm,
            lt3.nbs_uid,
            lt3.prog_area_cd,
            lt3.prog_area_desc_txt,
            lt3.PROGRAM_AREA_ID,
            lt3.status_cd,
            lt3.status_time,
            case
                when lt3.TEST_RESULT_VAL_CD   like '%[^0-9]%' and SUBSTRING(lt3.TEST_RESULT_VAL_CD,2,1) = '-'
                    and (lt3.CONDITION='' or lt3.CONDITION is null) and lt3.CONDITION_SHORT_NM is null then substring(sc.DISEASE_NM,1,50)
                else lt3.CONDITION_SHORT_NM
                end as CONDITION_SHORT_NM,
            lt3.LOINC,
            case
                when TEST_RESULT_VAL_CD   like '%[^0-9]%' and SUBSTRING(TEST_RESULT_VAL_CD,2,1) = '-'
                    and (CONDITION='' or CONDITION is null) then substring(sc.DISEASE_NM,1,50)
                else lt3.CONDITION
                end as CONDITION,
            case
                when lt3.TEST_RESULT_VAL_CD like '%[^0-9]%' and SUBSTRING(lt3.TEST_RESULT_VAL_CD,2,1) = '-' then lt3.TEST_RESULT_VAL_CD
                else cast(null as [varchar](1000) )
                end as SNOMED
        into #TMP_LABTESTS4
        from #TMP_LABTESTS3 lt3
                 left outer join dbo.nrt_srte_Snomed_condition sc with(NOLOCK) on sc.SNOMED_CD = lt3.TEST_RESULT_VAL_CD
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES
            (@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if @debug = 'true' select 'TMP_LABTESTS4', * from #TMP_LABTESTS4;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING LAB100 Table - Update';


        update dbo.LAB100
        set
            [LAB_RPT_LOCAL_ID] = src.[LAB_RPT_LOCAL_ID]
          ,[RESULTED_LAB_TEST_CD] = substring(src.RESULTED_LAB_TEST_CD ,1,50)
          ,[PROGRAM_JURISDICTION_OID] = src.[oid]
          ,[RECORD_STATUS_CD] = substring(src.RECORD_STATUS_CD ,1,8)
          ,[RESULTED_LAB_TEST_CD_DESC] = substring(rtrim(src.RESULTED_LAB_TEST_CD_DESC) ,1,1000)
          ,[RESULTEDTEST_CD_SYS_NM] = substring(src.RESULTEDTEST_CD_SYS_NM ,1,100)
          ,[RESULTEDTEST_VAL_CD] = substring(src.RESULTEDTEST_VAL_CD ,1,20)
          ,[RESULTEDTEST_VAL_CD_DESC] = substring(src.RESULTEDTEST_VAL_CD_DESC ,1,1000)
          ,[NUMERIC_RESULT_WITHUNITS] = substring(src.NUMERIC_RESULT_WITHUNITS ,1,50)
          ,[LAB_RESULT_TXT_VAL] = substring(rtrim(src.LAB_RESULT_TXT_VAL ),1,2000)
          ,[LAB_RESULT_COMMENTS] = substring(rtrim(src.LAB_RESULT_COMMENTS) ,1,2000)
          ,[RESULT_REF_RANGE_FRM] = substring(src.RESULT_REF_RANGE_FRM ,1,20)
          ,[RESULT_REF_RANGE_TO] = substring(src.RESULT_REF_RANGE_TO ,1,20)
          ,[ALT_LAB_TEST_CD] = substring(src.ALT_LAB_TEST_CD ,1,50)
          ,[ALT_LAB_TEST_CD_DESC] = substring(src.ALT_LAB_TEST_CD_DESC ,1,1000)
          ,[ALT_LAB_TEST_CD_SYS_CD] = substring(src.ALT_LAB_TEST_CD_SYS_CD ,1,50)
          ,[ALT_LAB_TEST_CD_SYS_NM] = substring(src.ALT_LAB_TEST_CD_SYS_NM ,1,100)
          ,[PATIENT_KEY] = src.[PATIENT_KEY]
          ,[ACCESSION_NBR] = substring(src.ACCESSION_NBR ,1,199)
          ,[JURISDICTION_CD] = substring(src.JURISDICTION_CD ,1,20)
          ,[JURISDICTION_NM] = substring(src.JURISDICTION_NM ,1,32)
          ,[ORDERING_FACILITY] = substring(src.ORDERING_FACILITY ,1,100)
          ,[REPORTING_FACILITY] = substring(src.REPORTING_FACILITY ,1,100)
          ,[LAB_TEST_STATUS] = substring(src.LAB_TEST_STATUS ,1,50)
          ,[ELR_IND] = substring(src.ELR_IND ,1,1)
          ,[ORDERED_LAB_TEST_CD] = substring(src.ORDERED_LAB_TEST_CD ,1,50)
          ,[ORDERED_LAB_TEST_CD_DESC] = substring(src.ORDERED_LAB_TEST_CD_DESC ,1,1000)
          ,[ORDERED_LABTEST_CD_SYS_NM] = substring(src.ORDERED_LABTEST_CD_SYS_NM ,1,100)
          ,[CONDITION_CD] = substring(src.CONDITION_CD ,1,72)
          ,[CONDITION_SHORT_NM] = substring(src.CONDITION_SHORT_NM ,1,50)
          ,[PROGRAM_AREA_CD] = substring(src.PROG_AREA_CD ,1,20)
          ,[PROGRAM_AREA_DESC] = substring(src.PROG_AREA_DESC_TXT ,1,33)
          ,[SPECIMEN_COLLECTION_DT] = src.[SPECIMEN_COLLECTION_DT]
          ,[SPECIMEN_SRC_DESC] = substring(src.SPECIMEN_SRC_DESC ,1,100)
          ,[SPECIMEN_SRC_CD] = substring(src.SPECIMEN_SRC_CD ,1,50)
          ,[LAB_TEST_DT] = src.[LAB_TEST_DT]
          ,[LAB_RPT_CREATED_DT] = src.[LAB_RPT_CREATED_DT]
          ,[LAB_RPT_LAST_UPDATE_DT] = src.[LAB_RPT_LAST_UPDATE_DT]
          ,[LAB_RPT_RECEIVED_BY_PH_DT] = src.[LAB_RPT_RECEIVED_BY_PH_DT]
          ,[LAB_RPT_STATUS] = substring(src.LAB_RPT_STATUS ,1,50)
          ,[REASON_FOR_TEST_DESC] = substring(src.REASON_FOR_TEST_DESC ,1,4000)
          ,[PERSON_LOCAL_ID] = substring(src.PERSON_LOCAL_ID ,1,50)
          ,[PERSON_FIRST_NM] = substring(src.PERSON_FIRST_NM ,1,50)
          ,[PERSON_MIDDLE_NM] = substring(src.PERSON_MIDDLE_NM ,1,50)
          ,[PERSON_LAST_NM] = substring(src.PERSON_LAST_NM ,1,50)
          ,[PERSON_DOB] = src.[PERSON_DOB]
          ,[AGE_REPORTED] = src.[AGE_REPORTED]
          ,[PATIENT_REPORTED_AGE_UNITS] = substring(rtrim(src.PATIENT_REPORTED_AGE_UNITS) ,1,20)
          ,[PERSON_CURR_GENDER] = substring(src.PERSON_CURR_GENDER ,1,1)
          ,[PATIENT_ADDRESS] = substring(src.PATIENT_ADDRESS ,1,725)
          ,[ADDR_USE_CD_DESC] = substring(src.ADDR_USE_CD_DESC ,1,1000)
          ,[ADDR_CD_DESC] = substring(src.ADDR_CD_DESC ,1,1000)
          ,[PATIENT_CITY] = substring(rtrim(src.PATIENT_CITY) ,1,50)
          ,[PATIENT_COUNTY] =  substring(src.PATIENT_COUNTY ,1,50)
          ,[PATIENT_STATE] = substring(src.PATIENT_STATE ,1,50)
          ,[PATIENT_ZIP_CODE] = substring(src.PATIENT_ZIP_CODE ,1,20)
          ,[ADDRESS_DATE] = null
          ,[ORDERING_PROVIDER_NM] = rtrim(ltrim(substring(src.ORDERING_PROVIDER_NM ,1,50)))
          ,[PROVIDER_ADDRESS] = substring(src.PROVIDER_ADDRESS ,1,725)
          ,[PRV_ADDR_USE_CD_DESC] = substring(src.PRV_ADDR_USE_CD_DESC ,1,1000)
          ,[PRV_ADDR_CD_DESC] = substring(src.PRV_ADDR_CD_DESC ,1,1000)
          ,[PROVIDER_PHONE] = substring(src.PROVIDER_PHONE ,1,50)
          ,[MORB_RPT_KEY] = src.[MORB_RPT_KEY]
          ,[LDF_GROUP_KEY] = src.[LDF_GROUP_KEY]
          ,[INVESTIGATION_KEYS] = substring(src.INVESTIGATION_KEYS ,1,1000)
          ,[EVENT_DATE] = coalesce(src.SPECIMEN_COLLECTION_DT, src.LAB_TEST_DT, src.LAB_RPT_RECEIVED_BY_PH_DT, src.LAB_RPT_CREATED_DT)
          ,[REPORTING_FACILITY_UID] = src.REPORTING_FACILITY_UID
          ,[RDB_LAST_REFRESH_TIME] = current_timestamp
        from
            dbo.LAB100 tgt inner join (select * from #TMP_LABTESTS4 where LAB_RPT_LOCAL_ID is not null) src
                                      on src.RESULTED_LAB_TEST_KEY = tgt.RESULTED_LAB_TEST_KEY;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING LAB100 Table - Insert';

        insert into dbo.[LAB100](
                                  [LAB_RPT_LOCAL_ID]
                                ,[RESULTED_LAB_TEST_CD]
                                ,[PROGRAM_JURISDICTION_OID]
                                ,[RECORD_STATUS_CD]
                                ,[RESULTED_LAB_TEST_CD_DESC]
                                ,[RESULTEDTEST_CD_SYS_NM]
                                ,[RESULTEDTEST_VAL_CD]
                                ,[RESULTEDTEST_VAL_CD_DESC]
                                ,[NUMERIC_RESULT_WITHUNITS]
                                ,[LAB_RESULT_TXT_VAL]
                                ,[LAB_RESULT_COMMENTS]
                                ,[RESULT_REF_RANGE_FRM]
                                ,[RESULT_REF_RANGE_TO]
                                ,[ALT_LAB_TEST_CD]
                                ,[ALT_LAB_TEST_CD_DESC]
                                ,[ALT_LAB_TEST_CD_SYS_CD]
                                ,[ALT_LAB_TEST_CD_SYS_NM]
                                ,[PATIENT_KEY]
                                ,[ACCESSION_NBR]
                                ,[JURISDICTION_CD]
                                ,[JURISDICTION_NM]
                                ,[ORDERING_FACILITY]
                                ,[REPORTING_FACILITY]
                                ,[LAB_TEST_STATUS]
                                ,[ELR_IND]
                                ,[ORDERED_LAB_TEST_CD]
                                ,[ORDERED_LAB_TEST_CD_DESC]
                                ,[ORDERED_LABTEST_CD_SYS_NM]
                                ,[CONDITION_CD]
                                ,[CONDITION_SHORT_NM]
                                ,[PROGRAM_AREA_CD]
                                ,[PROGRAM_AREA_DESC]
                                ,[SPECIMEN_COLLECTION_DT]
                                ,[SPECIMEN_SRC_DESC]
                                ,[SPECIMEN_SRC_CD]
                                ,[LAB_TEST_DT]
                                ,[LAB_RPT_CREATED_DT]
                                ,[LAB_RPT_LAST_UPDATE_DT]
                                ,[LAB_RPT_RECEIVED_BY_PH_DT]
                                ,[LAB_RPT_STATUS]
                                ,[REASON_FOR_TEST_DESC]
                                ,[PERSON_LOCAL_ID]
                                ,[PERSON_FIRST_NM]
                                ,[PERSON_MIDDLE_NM]
                                ,[PERSON_LAST_NM]
                                ,[PERSON_DOB]
                                ,[AGE_REPORTED]
                                ,[PATIENT_REPORTED_AGE_UNITS]
                                ,[PERSON_CURR_GENDER]
                                ,[PATIENT_ADDRESS]
                                ,[ADDR_USE_CD_DESC]
                                ,[ADDR_CD_DESC]
                                ,[PATIENT_CITY]
                                ,[PATIENT_COUNTY]
                                ,[PATIENT_STATE]
                                ,[PATIENT_ZIP_CODE]
                                ,[ADDRESS_DATE]
                                ,[ORDERING_PROVIDER_NM]
                                ,[PROVIDER_ADDRESS]
                                ,[PRV_ADDR_USE_CD_DESC]
                                ,[PRV_ADDR_CD_DESC]
                                ,[PROVIDER_PHONE]
                                ,[RESULTED_LAB_TEST_KEY]
                                ,[MORB_RPT_KEY]
                                ,[LDF_GROUP_KEY]
                                ,[INVESTIGATION_KEYS]
                                ,[EVENT_DATE]
                                ,[REPORTING_FACILITY_UID]
                                ,[RDB_LAST_REFRESH_TIME]
        )
        SELECT
            distinct
            src.[LAB_RPT_LOCAL_ID]
                   , substring(src.RESULTED_LAB_TEST_CD ,1,50)
                   , src.oid
                   , substring(src.RECORD_STATUS_CD ,1,8)
                   , substring(rtrim(src.RESULTED_LAB_TEST_CD_DESC) ,1,1000)
                   , substring(src.RESULTEDTEST_CD_SYS_NM ,1,100)
                   , substring(src.RESULTEDTEST_VAL_CD ,1,20)
                   , substring(src.RESULTEDTEST_VAL_CD_DESC ,1,1000)
                   , substring(src.NUMERIC_RESULT_WITHUNITS ,1,50)
                   , substring(rtrim(src.LAB_RESULT_TXT_VAL ),1,2000)
                   , substring(rtrim(src.LAB_RESULT_COMMENTS) ,1,2000)
                   , substring(src.RESULT_REF_RANGE_FRM ,1,20)
                   , substring(src.RESULT_REF_RANGE_TO ,1,20)
                   , substring(src.ALT_LAB_TEST_CD ,1,50)
                   , substring(src.ALT_LAB_TEST_CD_DESC ,1,1000)
                   , substring(src.ALT_LAB_TEST_CD_SYS_CD ,1,50)
                   , substring(src.ALT_LAB_TEST_CD_SYS_NM ,1,100)
                   , src.PATIENT_KEY
                   , substring(src.ACCESSION_NBR ,1,199)
                   , substring(src.JURISDICTION_CD ,1,20)
                   , substring(src.JURISDICTION_NM ,1,32)
                   , substring(src.ORDERING_FACILITY ,1,100)
                   , substring(src.REPORTING_FACILITY ,1,100)
                   , substring(src.LAB_TEST_STATUS ,1,50)
                   , substring(src.ELR_IND ,1,1)
                   , substring(src.ORDERED_LAB_TEST_CD ,1,50)
                   , substring(src.ORDERED_LAB_TEST_CD_DESC ,1,1000)
                   , substring(src.ORDERED_LABTEST_CD_SYS_NM ,1,100)
                   , substring(src.CONDITION_CD ,1,72)
                   , substring(src.CONDITION_SHORT_NM ,1,50)
                   , substring(src.PROG_AREA_CD ,1,20)
                   , substring(src.PROG_AREA_DESC_TXT ,1,33)
                   , src.SPECIMEN_COLLECTION_DT
                   , substring(src.SPECIMEN_SRC_DESC ,1,100)
                   , substring(src.SPECIMEN_SRC_CD ,1,50)
                   , src.LAB_TEST_DT
                   , src.LAB_RPT_CREATED_DT
                   , src.LAB_RPT_LAST_UPDATE_DT
                   , src.LAB_RPT_RECEIVED_BY_PH_DT
                   , substring(src.LAB_RPT_STATUS ,1,50)
                   , substring(src.REASON_FOR_TEST_DESC ,1,4000)
                   , substring(src.PERSON_LOCAL_ID ,1,50)
                   , substring(src.PERSON_FIRST_NM ,1,50)
                   , substring(src.PERSON_MIDDLE_NM ,1,50)
                   , substring(src.PERSON_LAST_NM ,1,50)
                   , src.PERSON_DOB
                   , src.AGE_REPORTED
                   , substring(rtrim(src.PATIENT_REPORTED_AGE_UNITS) ,1,20)
                   , substring(src.PERSON_CURR_GENDER ,1,1)
                   , substring(src.PATIENT_ADDRESS ,1,725)
                   , substring(src.ADDR_USE_CD_DESC ,1,1000)
                   , substring(src.ADDR_CD_DESC ,1,1000)
                   , substring(rtrim(src.PATIENT_CITY) ,1,50)
                   , substring(src.PATIENT_COUNTY ,1,50)
                   , substring(src.PATIENT_STATE ,1,50)
                   , substring(src.PATIENT_ZIP_CODE ,1,20)
                   , null as [ADDRESS_DATE]
                   , rtrim(ltrim(substring(src.ORDERING_PROVIDER_NM ,1,50)))
                   , substring(src.PROVIDER_ADDRESS ,1,725)
                   , substring(src.PRV_ADDR_USE_CD_DESC ,1,1000)
                   , substring(src.PRV_ADDR_CD_DESC ,1,1000)
                   , substring(src.PROVIDER_PHONE ,1,50)
                   , src.RESULTED_LAB_TEST_KEY
                   , src.MORB_RPT_KEY
                   , src.LDF_GROUP_KEY
                   , substring(src.INVESTIGATION_KEYS ,1,1000)
                   , coalesce(src.SPECIMEN_COLLECTION_DT, src.LAB_TEST_DT, src.LAB_RPT_RECEIVED_BY_PH_DT, src.LAB_RPT_CREATED_DT) as [EVENT_DATE]
                   , src.REPORTING_FACILITY_UID
                   ,current_timestamp as [RDB_LAST_REFRESH_TIME]
        from
            #TMP_LABTESTS4 src
                left join
            dbo.LAB100 tgt
            on src.RESULTED_LAB_TEST_KEY = tgt.RESULTED_LAB_TEST_KEY
        where src.LAB_RPT_LOCAL_ID is not null and tgt.RESULTED_LAB_TEST_KEY is null
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO dbo.[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'Update Inactive LAB100 Records';


        /* Update records associated to Inactive Orders using LAB_TEST */
        UPDATE l
        SET record_status_cd = 'INACTIVE'
        FROM dbo.LAB100 l
        WHERE
            RESULTED_LAB_TEST_KEY IN (
                SELECT
                    l.RESULTED_LAB_TEST_KEY
                FROM dbo.LAB_TEST lt
                         INNER JOIN dbo.LAB100 l on
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
        VALUES(@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'DELETE REMOVED OBSERVATIONS FROM LAB100';

        /* Remove keys in LAB100 that no longer exist in LAB_TEST. */
        DELETE FROM dbo.LAB100
        WHERE RESULTED_LAB_TEST_KEY IN (
            SELECT DISTINCT l.RESULTED_LAB_TEST_KEY
            FROM dbo.LAB100 l
            EXCEPT
            SELECT lt.LAB_TEST_KEY
            FROM dbo.LAB_TEST lt);

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'LAB100_DATAMART','LAB100_DATAMART','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;



        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  999 ;
        SET @Proc_Step_Name = 'SP_COMPLETE';

        INSERT INTO dbo.[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name],[Status_Type] ,[step_number],[step_name],[row_count])
        VALUES
            (@batch_id,'D_LAB100','D_LAB100','COMPLETE',@Proc_Step_no,@Proc_Step_name,@RowCount_no);

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
        VALUES
            (
              @batch_id
            ,'D_LAB100'
            ,'D_LAB100'
            ,'ERROR'
            ,@Proc_Step_no
            ,@Proc_Step_name
            ,@FullErrorMessage
            ,0
            );


        return -1 ;

    END CATCH

END;