CREATE OR ALTER PROCEDURE [dbo].[sp_inv_summary_datamart_postprocessing]
    @phc_uids nvarchar(max) = '',
    @notif_uids nvarchar(max) = '',
    @obs_uids nvarchar(max) = '',
    @debug bit = 'false'

AS
BEGIN
    BEGIN TRY

        DECLARE @RowCount_no INT ;
        DECLARE @Proc_Step_no FLOAT = 0 ;
        DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
        DECLARE @batch_id bigint;
        SET @batch_id = cast((format(getdate(),'yyMMddHHmmss')) as bigint);

        DECLARE @COUNTSTD AS int;

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';


        BEGIN TRANSACTION;

        INSERT INTO [dbo].[job_flow_log] (
                                           batch_id         ---------------@batch_id
                                         ,[Dataflow_Name]  --------------'INV_SUMM_DATAMART'
                                         ,[package_Name]   --------------'INV_SUMM_DATAMART'
                                         ,[Status_Type]    ---------------START
                                         ,[step_number]    ---------------@Proc_Step_no
                                         ,[step_name]   ------------------@Proc_Step_Name=sp_start
                                         ,[row_count] --------------------0
                                         ,[msg_description1]
                                         ,[msg_description2]
        )
        VALUES
            (
              @batch_id
            ,'INV_SUMM_DATAMART'
            ,'INV_SUMM_DATAMART'
            ,'START'
            ,@Proc_Step_no
            ,@Proc_Step_Name
            ,0
            ,LEFT('PHC_ID List-' +@phc_uids, 500)
            ,LEFT('NOTF_ID List-' +@notif_uids, 500)
            );

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no  + 1;
        SET @Proc_Step_name='Checking case_management COUNT';

        /*Notes: Determination between executing either F_STD_PAGE_CASE or F_PAGE_CASE blocks.*/
        SET @COUNTSTD= (select  count(*) from rdb_modern.dbo.nrt_investigation_case_management nicm with(nolock));
        ----Print @COUNTSTD


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Generating #TMP_UPDATED_INV_WITH_NOTIF';

        /*Notes: Hydrate TMP_UPDATED_INV_WITH_NOTIF if notifications are updated.*/
        DECLARE @INV_SUMMARY_DATAMART_COUNT AS BIGINT=0;
        SET @INV_SUMMARY_DATAMART_COUNT= (SELECT COUNT(*) FROM dbo.INV_SUMM_DATAMART);
        PRINT @INV_SUMMARY_DATAMART_COUNT;


        IF OBJECT_ID('tempdb..#TMP_UPDATED_INV_WITH_NOTIF', 'U') IS NOT NULL
            drop table #TMP_UPDATED_INV_WITH_NOTIF;


        SELECT INVESTIGATION.INVESTIGATION_KEY , INVESTIGATION.CASE_UID
        INTO #TMP_UPDATED_INV_WITH_NOTIF
        FROM dbo.NOTIFICATION_EVENT with(nolock)
                 INNER JOIN	DBO.NOTIFICATION  with(nolock)  on NOTIFICATION_EVENT.NOTIFICATION_KEY = NOTIFICATION.NOTIFICATION_KEY
                 INNER JOIN DBO.RDB_DATE  with(nolock) ON RDB_DATE.DATE_KEY = NOTIFICATION_EVENT.NOTIFICATION_UPD_DT_KEY
                 INNER JOIN DBO.INVESTIGATION  with(nolock)  ON INVESTIGATION.INVESTIGATION_KEY = NOTIFICATION_EVENT.INVESTIGATION_KEY
        WHERE (
            (
                INVESTIGATION.CASE_TYPE= 'I'
                    AND INVESTIGATION.RECORD_STATUS_CD = 'ACTIVE'
                    AND INVESTIGATION.CASE_UID IN (SELECT value FROM STRING_SPLIT(@phc_uids, ','))
                )
                OR
            NOTIFICATION.NOTIFICATION_KEY in (
                select NOTIFICATION_KEY
                from dbo.NOTIFICATION with ( nolock)
                         inner join dbo.nrt_notification_key k on k.d_notification_key = NOTIFICATION.NOTIFICATION_KEY
                where notification_uid IN (SELECT value FROM STRING_SPLIT(@notif_uids, ','))
            )
            )
          AND @INV_SUMMARY_DATAMART_COUNT>0
          AND INVESTIGATION.CASE_TYPE= 'I'
          AND INVESTIGATION.RECORD_STATUS_CD = 'ACTIVE'
        ;

        if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_UPDATED_INV_WITH_NOTIF;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        IF OBJECT_ID('tempdb..#TMP_PATIENT_LOCATION_KEYS_INIT', 'U') IS NOT NULL
            DROP TABLE #TMP_PATIENT_LOCATION_KEYS_INIT;

        CREATE TABLE #TMP_PATIENT_LOCATION_KEYS_INIT
        (
            INVESTIGATION_KEY BIGINT NOT NULL,
            INVESTIGATION_STATUS varchar(50) NULL,
            INVESTIGATION_LOCAL_ID varchar(50) NULL,
            EARLIEST_RPT_TO_CNTY_DT datetime NULL,
            EARLIEST_RPT_TO_STATE_DT datetime NULL,
            DIAGNOSIS_DATE datetime NULL,
            ILLNESS_ONSET_DATE datetime NULL,
            CASE_STATUS varchar(50) NULL,
            MMWR_WEEK numeric(18,0) NULL,
            MMWR_YEAR numeric(18,0) NULL,
            PROGRAM_JURISDICTION_OID bigint NULL,
            HSPTL_ADMISSION_DT datetime NULL,
            INV_START_DT datetime NULL,
            INV_RPT_DT datetime NULL,
            CURR_PROCESS_STATE varchar(100) NULL,
            JURISDICTION_NM varchar(100) NULL,
            INVESTIGATION_CREATE_DATE datetime NULL,
            INVESTIGATION_CREATED_BY varchar(50) NULL,
            INVESTIGATION_LAST_UPDTD_DATE datetime NULL,
            INVESTIGATION_LAST_UPDTD_BY varchar(50) NULL,
            PROGRAM_AREA varchar(50) NULL,
            GENERIC_PHYSICIAN_KEY bigint NULL,
            GEN_PATI_KEY bigint NULL,
            CRS_PHYSICIAN_KEY bigint NULL,
            CRS_PAT_KEY bigint NULL,
            MEASLES_PHYSICIAN_KEY bigint NULL,
            MEASLES_PAT_KEY bigint NULL,
            RUBELLA_PHYSICIAN_KEY bigint NULL,
            RUBELLA_PAT_KEY bigint NULL,
            HEPATITIS_PHYSICIAN_KEY bigint NULL,
            HEPATITIS_PAT_KEY bigint NULL,
            BMIRD_PHYSICIAN_KEY bigint NULL,
            BMIRD_PAT_KEY bigint NULL,
            FIRST_POSITIVE_CULTURE_DT datetime NULL,
            PERTUSSIS_PHYSICIAN_KEY bigint NULL,
            PERTUSSIS_PAT_KEY bigint NULL,
            F_TB_PAM_PHYSICIAN_KEY bigint NULL,
            F_TB_PAM_PAT_KEY bigint NULL,
            F_VAR_PAM_PHYSICIAN_KEY bigint NULL,
            F_VAR_PAM_PAT_KEY bigint NULL,
            F_PAGE_CASE_PHYSICIAN_KEY bigint NULL,
            F_PAGE_PATIENT_KEY bigint NULL,
            F_STD_PHYSICIAN_KEY bigint NULL,
            F_STD_PATIENT_KEY bigint NULL,
            PATIENT_KEY bigint NULL,
            PHYSICIAN_KEY bigint NULL
        )

        --------------------------2a. Create Table #TMP_PATIENT_LOCATION_KEYS_INIT---STD Cases
        if (@COUNTSTD >0) ------------------STD CASES

            BEGIN

                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = 'Generating STD #TMP_PATIENT_LOCATION_KEYS_INIT';

                INSERT INTO #TMP_PATIENT_LOCATION_KEYS_INIT
                SELECT DISTINCT
                    I.INVESTIGATION_KEY			 AS  'INVESTIGATION_KEY',---1
                    SUBSTRING(I.INVESTIGATION_STATUS,1,50) AS  'INVESTIGATION_STATUS',---2
                    I.INV_LOCAL_ID                       AS  'INVESTIGATION_LOCAL_ID',---3
                    I.EARLIEST_RPT_TO_CNTY_DT            AS  'EARLIEST_RPT_TO_CNTY_DT',---4
                    I.EARLIEST_RPT_TO_STATE_DT           AS  'EARLIEST_RPT_TO_STATE_DT',---5
                    I.DIAGNOSIS_DT                       AS  'DIAGNOSIS_DATE',---6
                    I.ILLNESS_ONSET_DT                   AS  'ILLNESS_ONSET_DATE',   ---7
                    SUBSTRING(I.INV_CASE_STATUS ,1,50)   AS  'CASE_STATUS',---8
                    I.CASE_RPT_MMWR_WK                   AS  'MMWR_WEEK',      ---9
                    I.CASE_RPT_MMWR_YR                   AS  'MMWR_YEAR' ,     ---10
                    I.CASE_OID                           AS  'PROGRAM_JURISDICTION_OID',---11
                    I.HSPTL_ADMISSION_DT                 AS  'HSPTL_ADMISSION_DT',--12
                    I.INV_START_DT                       AS  'INV_START_DT',---13
                    I.INV_RPT_DT                         AS  'INV_RPT_DT', ---14
                    SUBSTRING(I.CURR_PROCESS_STATE,1,50)        AS  'CURR_PROCESS_STATE',----15
                    SUBSTRING(I.JURISDICTION_NM,1,100) 			 AS 'JURISDICTION_NM',                                         ---16
                    I.ADD_TIME			 AS  'INVESTIGATION_CREATE_DATE',--17
                    I.INVESTIGATION_ADDED_BY	 AS  'INVESTIGATION_CREATED_BY',---18
                    I.LAST_CHG_TIME			     AS  'INVESTIGATION_LAST_UPDTD_DATE',---19
                    SUBSTRING(I.INVESTIGATION_LAST_UPDATED_BY,1,50)		 AS  'INVESTIGATION_LAST_UPDTD_BY',---20
                    I.PROGRAM_AREA_DESCRIPTION	 AS  'PROGRAM_AREA', ---21
                    COALESCE(GC.PHYSICIAN_KEY,0)          AS  'GENERIC_PHYSICIAN_KEY'  ,---22
                    COALESCE(GC.PATIENT_KEY,0)	         AS  'GEN_PATI_KEY',---23
                    COALESCE(CC.PHYSICIAN_KEY,0)	 AS  'CRS_PHYSICIAN_KEY',---24
                    COALESCE(CC.PATIENT_KEY,0)	 AS  'CRS_PAT_KEY',---25
                    COALESCE(MC.PHYSICIAN_KEY,0)	 AS  'MEASLES_PHYSICIAN_KEY',---26
                    COALESCE(MC.PATIENT_KEY,0)	 AS  'MEASLES_PAT_KEY',---27
                    COALESCE(RC.PHYSICIAN_KEY,0)	 AS  'RUBELLA_PHYSICIAN_KEY',---28
                    COALESCE(RC.PATIENT_KEY,0)	 AS  'RUBELLA_PAT_KEY',---29
                    COALESCE(HC.PHYSICIAN_KEY,0)	 AS  'HEPATITIS_PHYSICIAN_KEY',---30
                    COALESCE(HC.PATIENT_KEY,0)		     AS  'HEPATITIS_PAT_KEY',---31
                    COALESCE(BC.PHYSICIAN_KEY,0)		     AS  'BMIRD_PHYSICIAN_KEY',---32
                    COALESCE(BC.PATIENT_KEY,0)	 AS  'BMIRD_PAT_KEY',---33
                    BC.FIRST_POSITIVE_CULTURE_DT		 AS  'FIRST_POSITIVE_CULTURE_DT',---34
                    COALESCE(PC.PHYSICIAN_KEY,0)		 AS  'PERTUSSIS_PHYSICIAN_KEY',---35
                    COALESCE(PC.PATIENT_KEY	,0)	 AS  'PERTUSSIS_PAT_KEY',---36
                    COALESCE(F_TB.PHYSICIAN_KEY	,0)		 AS  'F_TB_PAM_PHYSICIAN_KEY',---37
                    COALESCE(F_TB.PERSON_KEY,0)	 AS  'F_TB_PAM_PAT_KEY',---38
                    COALESCE(F_VAR.PHYSICIAN_KEY,0)		 AS  'F_VAR_PAM_PHYSICIAN_KEY',---39
                    COALESCE(F_VAR.PERSON_KEY,0)		 AS  'F_VAR_PAM_PAT_KEY',---40
                    COALESCE(F_PAGE.PHYSICIAN_KEY,0)	 AS  'F_PAGE_CASE_PHYSICIAN_KEY', ---41
                    COALESCE(F_PAGE.PATIENT_KEY	,0)		 AS  'F_PAGE_PATIENT_KEY', ---42
                    COALESCE(F_STD.PHYSICIAN_KEY,0)      AS  'F_STD_PHYSICIAN_KEY',---43
                    COALESCE(F_STD.PATIENT_KEY,0)		 AS  'F_STD_PATIENT_KEY', ---STD---44
                    Cast (NULL as  bigint)		 AS  'PATIENT_KEY',---45
                    Cast (NULL as  bigint)               AS  'PHYSICIAN_KEY'---46
                FROM [dbo].[INVESTIGATION] I             with (nolock)
                         FULL JOIN  [dbo].GENERIC_CASE    GC      with (nolock) ON GC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].CRS_CASE        CC      with (nolock) ON CC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].MEASLES_CASE    MC      with (nolock) ON MC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].RUBELLA_CASE    RC      with (nolock) ON RC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].HEPATITIS_CASE  HC      with (nolock) ON HC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].BMIRD_CASE      BC      with (nolock) ON BC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].PERTUSSIS_CASE  PC      with (nolock) ON PC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].F_TB_PAM        F_TB    with (nolock) ON F_TB.INVESTIGATION_KEY  = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].F_VAR_PAM       F_VAR   with (nolock) ON F_VAR.INVESTIGATION_KEY = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].F_PAGE_CASE     F_PAGE  with (nolock) ON F_PAGE.INVESTIGATION_KEY= I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].[F_STD_PAGE_CASE] F_STD  with (nolock) ON F_STD.INVESTIGATION_KEY = I.INVESTIGATION_KEY--STD
                         FULL JOIN  [dbo].EVENT_METRIC    EM      with (nolock) ON EM.LOCAL_ID             = I.INV_LOCAL_ID
                WHERE (I.CASE_TYPE= 'I' AND I.RECORD_STATUS_CD = 'ACTIVE'
                           AND I.CASE_UID IN (SELECT value FROM STRING_SPLIT(@phc_uids, ','))
                    OR I.INVESTIGATION_KEY IN (SELECT INVESTIGATION_KEY FROM #TMP_UPDATED_INV_WITH_NOTIF));


                UPDATE  #TMP_PATIENT_LOCATION_KEYS_INIT
                SET PATIENT_KEY  =
                        (CASE
                             WHEN   GEN_PATI_KEY       >1  then  GEN_PATI_KEY
                             WHEN   CRS_PAT_KEY        >1  then  CRS_PAT_KEY
                             WHEN   MEASLES_PAT_KEY    >1  then  MEASLES_PAT_KEY
                             WHEN   RUBELLA_PAT_KEY    >1  then  RUBELLA_PAT_KEY
                             WHEN   HEPATITIS_PAT_KEY  >1  then  HEPATITIS_PAT_KEY
                             WHEN   BMIRD_PAT_KEY      >1  then  BMIRD_PAT_KEY
                             WHEN   PERTUSSIS_PAT_KEY  >1  then  PERTUSSIS_PAT_KEY
                             WHEN   F_TB_PAM_PAT_KEY   >1  then  F_TB_PAM_PAT_KEY
                             WHEN   F_PAGE_PATIENT_KEY >1  then  F_PAGE_PATIENT_KEY
                             WHEN   F_VAR_PAM_PAT_KEY  >1  then  F_VAR_PAM_PAT_KEY
                             WHEN   F_STD_PATIENT_KEY  >1  then  F_STD_PATIENT_KEY---STD
                             ELSE NULL
                            END
                            )
                ;

                UPDATE  #TMP_PATIENT_LOCATION_KEYS_INIT
                SET PHYSICIAN_KEY   =
                        (CASE
                             WHEN   GENERIC_PHYSICIAN_KEY    >1  then GENERIC_PHYSICIAN_KEY
                             WHEN   CRS_PHYSICIAN_KEY        >1  then CRS_PHYSICIAN_KEY
                             WHEN   MEASLES_PHYSICIAN_KEY    >1  then MEASLES_PHYSICIAN_KEY
                             WHEN   RUBELLA_PHYSICIAN_KEY    >1  then RUBELLA_PHYSICIAN_KEY
                             WHEN   HEPATITIS_PHYSICIAN_KEY  >1  then HEPATITIS_PHYSICIAN_KEY
                             WHEN   BMIRD_PHYSICIAN_KEY      >1  then BMIRD_PHYSICIAN_KEY
                             WHEN   PERTUSSIS_PHYSICIAN_KEY  >1  then PERTUSSIS_PHYSICIAN_KEY
                             WHEN   F_TB_PAM_PHYSICIAN_KEY   >1  then F_TB_PAM_PHYSICIAN_KEY
                             WHEN   F_VAR_PAM_PHYSICIAN_KEY  >1  then F_VAR_PAM_PHYSICIAN_KEY
                             WHEN   F_PAGE_CASE_PHYSICIAN_KEY>1  then F_PAGE_CASE_PHYSICIAN_KEY
                             WHEN   F_STD_PHYSICIAN_KEY      >1  then F_STD_PHYSICIAN_KEY
                             ELSE NULL
                            END
                            )
                ;

                if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_PATIENT_LOCATION_KEYS_INIT;


                SELECT @ROWCOUNT_NO = @@ROWCOUNT;

                INSERT INTO [DBO].[JOB_FLOW_LOG]
                (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
                VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


            END;
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        ------------------------2a. Create Table #TMP_PATIENT_LOCATION_KEYS_INIT---NON-STD Cases
        if (@COUNTSTD =0) ------------------NO STD CASES
            begin

                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = 'Generating NON STD #TMP_PATIENT_LOCATION_KEYS_INIT';

                INSERT INTO #TMP_PATIENT_LOCATION_KEYS_INIT
                SELECT DISTINCT
                    I.INVESTIGATION_KEY			 AS  'INVESTIGATION_KEY',---1
                    SUBSTRING(I.INVESTIGATION_STATUS,1,50) AS  'INVESTIGATION_STATUS',---2
                    I.INV_LOCAL_ID                       AS  'INVESTIGATION_LOCAL_ID',---3
                    I.EARLIEST_RPT_TO_CNTY_DT            AS  'EARLIEST_RPT_TO_CNTY_DT',---4
                    I.EARLIEST_RPT_TO_STATE_DT           AS  'EARLIEST_RPT_TO_STATE_DT',---5
                    I.DIAGNOSIS_DT                       AS  'DIAGNOSIS_DATE',---6
                    I.ILLNESS_ONSET_DT                   AS  'ILLNESS_ONSET_DATE',   ---7
                    SUBSTRING(I.INV_CASE_STATUS ,1,50)   AS  'CASE_STATUS',---8
                    I.CASE_RPT_MMWR_WK                   AS  'MMWR_WEEK',      ---9
                    I.CASE_RPT_MMWR_YR                   AS  'MMWR_YEAR' ,     ---10
                    I.CASE_OID                           AS  'PROGRAM_JURISDICTION_OID',---11
                    I.HSPTL_ADMISSION_DT                 AS  'HSPTL_ADMISSION_DT',--12
                    I.INV_START_DT                       AS  'INV_START_DT',---13
                    I.INV_RPT_DT                         AS  'INV_RPT_DT', ---14
                    SUBSTRING(I.CURR_PROCESS_STATE,1,50)        AS  'CURR_PROCESS_STATE',----15
                    SUBSTRING(I.JURISDICTION_NM,1,100) 			 AS 'JURISDICTION_NM',                                         ---16
                    I.ADD_TIME			 AS  'INVESTIGATION_CREATE_DATE',--17
                    I.INVESTIGATION_ADDED_BY	 AS  'INVESTIGATION_CREATED_BY',---18
                    I.LAST_CHG_TIME			     AS  'INVESTIGATION_LAST_UPDTD_DATE',---19
                    SUBSTRING(I.INVESTIGATION_LAST_UPDATED_BY,1,50)		 AS  'INVESTIGATION_LAST_UPDTD_BY',---20
                    I.PROGRAM_AREA_DESCRIPTION	 AS  'PROGRAM_AREA', ---21
                    COALESCE(GC.PHYSICIAN_KEY,0)          AS  'GENERIC_PHYSICIAN_KEY'  ,---22
                    COALESCE(GC.PATIENT_KEY,0)	         AS  'GEN_PATI_KEY',---23
                    COALESCE(CC.PHYSICIAN_KEY,0)	 AS  'CRS_PHYSICIAN_KEY',---24
                    COALESCE(CC.PATIENT_KEY,0)	 AS  'CRS_PAT_KEY',---25
                    COALESCE(MC.PHYSICIAN_KEY,0)	 AS  'MEASLES_PHYSICIAN_KEY',---26
                    COALESCE(MC.PATIENT_KEY,0)	 AS  'MEASLES_PAT_KEY',---27
                    COALESCE(RC.PHYSICIAN_KEY,0)	 AS  'RUBELLA_PHYSICIAN_KEY',---28
                    COALESCE(RC.PATIENT_KEY,0)	 AS  'RUBELLA_PAT_KEY',---29
                    COALESCE(HC.PHYSICIAN_KEY,0)	 AS  'HEPATITIS_PHYSICIAN_KEY',---30
                    COALESCE(HC.PATIENT_KEY,0)		     AS  'HEPATITIS_PAT_KEY',---31
                    COALESCE(BC.PHYSICIAN_KEY,0)		     AS  'BMIRD_PHYSICIAN_KEY',---32
                    COALESCE(BC.PATIENT_KEY,0)	 AS  'BMIRD_PAT_KEY',---33
                    BC.FIRST_POSITIVE_CULTURE_DT		 AS  'FIRST_POSITIVE_CULTURE_DT',---34
                    COALESCE(PC.PHYSICIAN_KEY,0)		 AS  'PERTUSSIS_PHYSICIAN_KEY',---35
                    COALESCE(PC.PATIENT_KEY	,0)	 AS  'PERTUSSIS_PAT_KEY',---36
                    COALESCE(F_TB.PHYSICIAN_KEY	,0)		 AS  'F_TB_PAM_PHYSICIAN_KEY',---37
                    COALESCE(F_TB.PERSON_KEY,0)	 AS  'F_TB_PAM_PAT_KEY',---38
                    COALESCE(F_VAR.PHYSICIAN_KEY,0)		 AS  'F_VAR_PAM_PHYSICIAN_KEY',---39
                    COALESCE(F_VAR.PERSON_KEY,0)		 AS  'F_VAR_PAM_PAT_KEY',---40
                    COALESCE(F_PAGE.PHYSICIAN_KEY,0)	 AS  'F_PAGE_CASE_PHYSICIAN_KEY',---41
                    COALESCE(F_PAGE.PATIENT_KEY	,0)		 AS  'F_PAGE_PATIENT_KEY',---42
                    Cast (NULL as  bigint)		 AS  'F_STD_PHYSICIAN_KEY', ---STD	---43
                    Cast (NULL as  bigint)		 AS  'F_STD_PATIENT_KEY',---44
                    Cast (NULL as  bigint)		 AS  'PATIENT_KEY',---45
                    Cast (NULL as  bigint)               AS  'PHYSICIAN_KEY'---46
                FROM [dbo].[INVESTIGATION] I             with (nolock)
                         FULL JOIN  [dbo].GENERIC_CASE    GC      with (nolock) ON GC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].CRS_CASE        CC      with (nolock) ON CC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].MEASLES_CASE    MC      with (nolock) ON MC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].RUBELLA_CASE    RC      with (nolock) ON RC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].HEPATITIS_CASE  HC      with (nolock) ON HC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].BMIRD_CASE      BC      with (nolock) ON BC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].PERTUSSIS_CASE  PC      with (nolock) ON PC.INVESTIGATION_KEY    = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].F_TB_PAM        F_TB    with (nolock) ON F_TB.INVESTIGATION_KEY  = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].F_VAR_PAM       F_VAR   with (nolock) ON F_VAR.INVESTIGATION_KEY = I.INVESTIGATION_KEY
                         FULL JOIN  [dbo].F_PAGE_CASE     F_PAGE  with (nolock) ON F_PAGE.INVESTIGATION_KEY= I.INVESTIGATION_KEY
                    --		FULL JOIN  [dbo].[F_STD_PAGE_CASE]F_STD  with (nolock) ON F_STD.INVESTIGATION_KEY = I.INVESTIGATION_KEY--STD
                         FULL JOIN  [dbo].EVENT_METRIC    EM      with (nolock) ON EM.LOCAL_ID = I.INV_LOCAL_ID
                WHERE I.CASE_TYPE= 'I' AND I.RECORD_STATUS_CD = 'ACTIVE'

                    AND CASE_UID IN (SELECT value FROM STRING_SPLIT(@phc_uids, ','))
                   OR I.INVESTIGATION_KEY IN (SELECT INVESTIGATION_KEY FROM #TMP_UPDATED_INV_WITH_NOTIF WITH (NOLOCK))
                ;


                UPDATE  #TMP_PATIENT_LOCATION_KEYS_INIT
                SET PATIENT_KEY  =
                        (CASE
                             WHEN   GEN_PATI_KEY       >1  then  GEN_PATI_KEY
                             WHEN   CRS_PAT_KEY        >1  then  CRS_PAT_KEY
                             WHEN   MEASLES_PAT_KEY    >1  then  MEASLES_PAT_KEY
                             WHEN   RUBELLA_PAT_KEY    >1  then  RUBELLA_PAT_KEY
                             WHEN   HEPATITIS_PAT_KEY  >1  then  HEPATITIS_PAT_KEY
                             WHEN   BMIRD_PAT_KEY      >1  then  BMIRD_PAT_KEY
                             WHEN   PERTUSSIS_PAT_KEY  >1  then  PERTUSSIS_PAT_KEY
                             WHEN   F_TB_PAM_PAT_KEY   >1  then  F_TB_PAM_PAT_KEY
                             WHEN   F_PAGE_PATIENT_KEY >1  then  F_PAGE_PATIENT_KEY
                             WHEN   F_VAR_PAM_PAT_KEY  >1  then  F_VAR_PAM_PAT_KEY
                             ELSE NULL
                            END
                            )
                ;

                UPDATE  #TMP_PATIENT_LOCATION_KEYS_INIT
                SET PHYSICIAN_KEY   =
                        (CASE
                             WHEN   GENERIC_PHYSICIAN_KEY    >1  then GENERIC_PHYSICIAN_KEY
                             WHEN   CRS_PHYSICIAN_KEY        >1  then CRS_PHYSICIAN_KEY
                             WHEN   MEASLES_PHYSICIAN_KEY    >1  then MEASLES_PHYSICIAN_KEY
                             WHEN   RUBELLA_PHYSICIAN_KEY    >1  then RUBELLA_PHYSICIAN_KEY
                             WHEN   HEPATITIS_PHYSICIAN_KEY  >1  then HEPATITIS_PHYSICIAN_KEY
                             WHEN   BMIRD_PHYSICIAN_KEY      >1  then BMIRD_PHYSICIAN_KEY
                             WHEN   PERTUSSIS_PHYSICIAN_KEY  >1  then PERTUSSIS_PHYSICIAN_KEY
                             WHEN   F_TB_PAM_PHYSICIAN_KEY   >1  then F_TB_PAM_PHYSICIAN_KEY
                             WHEN   F_VAR_PAM_PHYSICIAN_KEY  >1  then F_VAR_PAM_PHYSICIAN_KEY
                             WHEN F_PAGE_CASE_PHYSICIAN_KEY>1  then F_PAGE_CASE_PHYSICIAN_KEY
                            --WHEN   F_STD_PHYSICIAN_KEY      >1  then F_STD_PHYSICIAN_KEY
                             ELSE NULL
                            END
                            )
                ;
                if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_PATIENT_LOCATION_KEYS_INIT;

                SELECT @ROWCOUNT_NO = @@ROWCOUNT;

                INSERT INTO [DBO].[JOB_FLOW_LOG]
                (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
                VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


            END;



        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @Proc_Step_Name = 'Generating #TMP_CONFIRMATION_METHOD_BASE2';



        --------------------------------------5. Create Table TMP_S_CONFIRMATION_METHOD_PIVOT

        IF OBJECT_ID('tempdb..#TMP_CONFIRMATION_METHOD_BASE') IS NOT NULL
            drop table #TMP_CONFIRMATION_METHOD_BASE  ;


        SELECT CM.*,
               CMG.INVESTIGATION_KEY,
               CMG.[CONFIRMATION_DT]
        INTO  #TMP_CONFIRMATION_METHOD_BASE
        FROM
            dbo.[CONFIRMATION_METHOD] CM with (nolock)
                INNER JOIN  dbo.[CONFIRMATION_METHOD_GROUP]CMG with (nolock) ON CMG.[CONFIRMATION_METHOD_KEY]= CM.[CONFIRMATION_METHOD_KEY]
                INNER JOIN #TMP_PATIENT_LOCATION_KEYS_INIT PL with (nolock) ON  CMG.[INVESTIGATION_KEY]      = PL.INVESTIGATION_KEY
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @Proc_Step_Name = 'Generating ##TMP_CONFIRMATION_METHOD_PIVOT';


        IF OBJECT_ID('tempdb..##TMP_CONFIRMATION_METHOD_PIVOT', 'U') IS NOT NULL
            DROP TABLE ##TMP_CONFIRMATION_METHOD_PIVOT;


        DECLARE @CONFIRMATION_METHOD_DESC nvarchar(max)='',
            @sqlQuery nvarchar(max)=''

        ;With CTE_Description
                  AS
                  (SELECT DISTINCT COALESCE(CONFIRMATION_METHOD_DESC,'NULL') as CMD FROM [dbo].[CONFIRMATION_METHOD] )

         SELECT @CONFIRMATION_METHOD_DESC= @CONFIRMATION_METHOD_DESC+QUOTENAME(LTRIM(RTRIM([CMD]))) +',' from CTE_Description
        SET @CONFIRMATION_METHOD_DESC= LEFT( @CONFIRMATION_METHOD_DESC,len( @CONFIRMATION_METHOD_DESC)-1)

        Print @CONFIRMATION_METHOD_DESC;


        SET @sqlQuery =
                '
				SELECT *
				INTO ##TMP_CONFIRMATION_METHOD_PIVOT
                FROM
                (
                SELECT * FROM
                      (
                 SELECT CONFIRMATION_METHOD_DESC,investigation_key ,confirmation_dt
                 FROM  #TMP_CONFIRMATION_METHOD_BASE
                 GROUP BY  investigation_key,CONFIRMATION_METHOD_DESC,confirmation_dt
                      )MAIN
                     PIVOT
                   (
                MAX(CONFIRMATION_METHOD_DESC) For CONFIRMATION_METHOD_DESC in

 ('+
                @CONFIRMATION_METHOD_DESC
                    +')
				)as P) as c

			'
        PRINT (@sqlQuery)
        EXEC sp_executesql  @sqlQuery;

        if @debug = 'true' select @Proc_Step_Name as step, * from ##TMP_CONFIRMATION_METHOD_PIVOT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @Proc_Step_Name = 'Update ##TMP_CONFIRMATION_METHOD_PIVOT';

        ----added
        BEGIN

            ALTER TABLE ##TMP_CONFIRMATION_METHOD_PIVOT
                ADD CONFIRMATION_METHOD varchar(2000)

        END

        ;WITH  CTE as


                   (
                       select Investigation_key,
                              (    STUFF(
                                      (SELECT ' | ' + CAST(CMB.[CONFIRMATION_METHOD_DESC] AS varchar(2000))
                                       FROM #TMP_CONFIRMATION_METHOD_Base CMB
                                                inner join ##TMP_CONFIRMATION_METHOD_PIVOT p on CMB.INVESTIGATION_KEY=p.INVESTIGATION_KEY
                                       WHERE CMB.[INVESTIGATION_KEY] =CMP.[INVESTIGATION_KEY]
                                       FOR XML PATH('')
                                      )
                                  , 2 ,1, ''
                                   )

                                  ) AS CODE_DESC_TXT_List
                       from  ##TMP_CONFIRMATION_METHOD_PIVOT CMP
                       ----	where [CONFIRMATION_dt] is not null ----Commended on 3/29/2021
                       group by [INVESTIGATION_KEY]
                   )

         UPDATE CMP
         set CMP.confirmation_Method = RTRIM(ltrim(cte1.CODE_DESC_TXT_List))
         from  ##TMP_CONFIRMATION_METHOD_PIVOT CMP,
               CTE CTE1
         where CMP.[INVESTIGATION_KEY] = CTE1.[INVESTIGATION_KEY] ;

        if @debug = 'true' select @Proc_Step_Name as step, * from ##TMP_CONFIRMATION_METHOD_PIVOT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @Proc_Step_Name = 'Generating #tmp_PATIENT_LOCATION_KEYS';


        IF OBJECT_ID('tempdb..#TMP_PATIENT_LOCATION_KEYS', 'U') IS NOT NULL
            DROP TABLE #TMP_PATIENT_LOCATION_KEYS;


        SELECT A.*,
               B.CONFIRMATION_METHOD,
               B.CONFIRMATION_DT AS confirmationdte
        INTO #TMP_PATIENT_LOCATION_KEYS
        FROM ##TMP_CONFIRMATION_METHOD_PIVOT B
                 INNER JOIN #TMP_PATIENT_LOCATION_KEYS_INIT A ON a.investigation_key = b.investigation_key;

        if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_PATIENT_LOCATION_KEYS;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @Proc_Step_Name = 'Generating #tmp_PATIENT_INFO';


        IF OBJECT_ID('tempdb..#TMP_PATIENT_INFO', 'U') IS NOT NULL
            DROP TABLE #TMP_PATIENT_INFO;

        SELECT
            KEYS.*,
            substring(C.CONDITION_DESC,1,50) AS DISEASE,
            C.CONDITION_CD AS DISEASE_CD
        into #TMP_PATIENT_INFO
        FROM #TMP_PATIENT_LOCATION_KEYS keys
                 INNER JOIN dbo.CASE_COUNT CC ON keys.investigation_key=CC.investigation_key
                 INNER JOIN  dbo.CONDITION C ON C.CONDITION_KEY=CC.CONDITION_KEY
        ;

        if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_PATIENT_INFO;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @Proc_Step_Name = 'Generating #tmp_PHYSICIAN_INFO';


        IF OBJECT_ID('tempdb..#TMP_PHYSICIAN_INFO', 'U') IS NOT NULL
            DROP TABLE #TMP_PHYSICIAN_INFO;


        SELECT KEYS.*,
               PROVIDER_LAST_NAME AS PHYSICIAN_LAST_NAME ,
               PROVIDER_FIRST_NAME AS PHYSICIAN_FIRST_NAME
        into #TMP_PHYSICIAN_INFO
        FROM #TMP_PATIENT_INFO KEYS
                 left outer join dbo.D_PROVIDER ON	KEYS.PHYSICIAN_KEY =D_PROVIDER.PROVIDER_KEY
        --ORDER BY PATIENT_KEY
        ;

        if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_PHYSICIAN_INFO;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @Proc_Step_Name = 'Generating #tmp_PATIENT_DETAILS';


        IF OBJECT_ID('tempdb..#TMP_PATIENT_DETAILS', 'U') IS NOT NULL
            DROP TABLE #TMP_PATIENT_DETAILS;


        SELECT
            A.*,
            PATIENT.PATIENT_FIRST_NAME AS PATIENT_FIRST_NAME ,
            PATIENT.PATIENT_LAST_NAME AS PATIENT_LAST_NAME ,
            PATIENT.PATIENT_COUNTY AS PATIENT_COUNTY  ,
            PATIENT_COUNTY_CODE,
            PATIENT.PATIENT_STREET_ADDRESS_1 AS  PATIENT_STREET_ADDRESS_1 ,
            PATIENT.PATIENT_STREET_ADDRESS_2 AS   PATIENT_STREET_ADDRESS_2 ,
            PATIENT.PATIENT_CITY AS  PATIENT_CITY  ,
            PATIENT.PATIENT_STATE AS   PATIENT_STATE ,
            PATIENT.PATIENT_ZIP AS   PATIENT_ZIP ,
            PATIENT.PATIENT_ETHNICITY AS PATIENT_HISPANIC_IND ,
            PATIENT.PATIENT_LOCAL_ID AS PATIENT_LOCAL_ID ,
            PATIENT.PATIENT_DOB AS PATIENT_DOB ,
            PATIENT.PATIENT_CURRENT_SEX AS PATIENT_CURRENT_SEX ,
            PATIENT.PATIENT_AGE_REPORTED AS AGE_REPORTED ,
            PATIENT.PATIENT_AGE_REPORTED_UNIT AS AGE_REPORTED_UNIT ,
            PATIENT.PATIENT_ETHNICITY AS PATIENT_ETHNICITY ,
            PATIENT.PATIENT_RACE_CALCULATED AS RACE_CALCULATED ,
            PATIENT.PATIENT_RACE_CALC_DETAILS AS RACE_CALC_DETAILS
        into #TMP_PATIENT_DETAILS
        FROM 	#TMP_PHYSICIAN_INFO A
                    LEFT OUTER JOIN	dbo.D_PATIENT PATIENT ON 	PATIENT.PATIENT_KEY=A.PATIENT_KEY
        ;

        if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_PATIENT_DETAILS;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @Proc_Step_Name = 'GENERATING #TMP_S_INV_SUMM_DATAMART_INIT';

        IF OBJECT_ID('tempdb..#TMP_S_INV_SUMM_DATAMART_INIT', 'U') IS NOT NULL
            DROP TABLE #TMP_S_INV_SUMM_DATAMART_INIT  ;

            ; With CTE as (
            SELECT A.*,
                   NOTI.NOTIFICATION_STATUS,
                   NOTI.NOTIFICATION_LOCAL_ID,
                   NOTI.NOTIFICATION_SUBMITTED_BY ,
                   NOTI.NOTIFICATION_LAST_CHANGE_TIME,
                   CASE WHEN NOTI.NOTIFICATION_STATUS IS NOT NULL THEN RDB_DATE.DATE_MM_DD_YYYY
                        ELSE NULL END AS 'NOTIFICATION_CREATE_DATE',
                   CASE WHEN NOTI.NOTIFICATION_STATUS IS NOT NULL THEN RDB_DATE_SENT.DATE_MM_DD_YYYY
                        ELSE NULL END AS 'NOTIFICATION_SENT_DATE',
                   ROW_NUMBER() OVER (Partition by A.Investigation_Key Order by RDB_DATE.DATE_MM_DD_YYYY ASC )as rn
            --INTO #TMP_S_INV_SUMM_DATAMART_INIT
            FROM #TMP_PATIENT_DETAILS A

                     LEFT OUTER JOIN [dbo].[NOTIFICATION_EVENT] NOT_EVENT with (nolock) ON A.INVESTIGATION_KEY=NOT_EVENT.INVESTIGATION_KEY
                     LEFT OUTER JOIN [dbo].[NOTIFICATION]            NOTI with (nolock) ON NOTI.NOTIFICATION_KEY=NOT_EVENT.NOTIFICATION_KEY
                     LEFT OUTER JOIN [dbo].[RDB_DATE]		    RDB_DATE with (nolock) ON NOT_EVENT.NOTIFICATION_SUBMIT_DT_KEY= RDB_DATE.DATE_KEY
                     LEFT OUTER JOIN [dbo].[RDB_DATE]       RDB_DATE_SENT with (nolock) ON NOT_EVENT.NOTIFICATION_SENT_DT_KEY= RDB_DATE_SENT.DATE_KEY

        )
              SELECT *
              INTO #TMP_S_INV_SUMM_DATAMART_INIT from CTE where rn=1
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_S_INV_SUMM_DATAMART_INIT;


        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

---------------------------------------------------------12. Create table TMP_InvLab
        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO+1;
        SET @Proc_Step_Name = 'GENERATING #TMP_InvLab';


        IF OBJECT_ID('tempdb..#TMP_InvLab', 'U') IS NOT NULL
            drop table #TMP_InvLab ;


        SELECT L.INVESTIGATION_KEY, L.LAB_TEST_KEY
        INTO  #TMP_InvLab
        FROM  dbo.LAB_TEST_RESULT L   with (nolock)
                  INNER JOIN dbo.INVESTIGATION I with (nolock)ON L.INVESTIGATION_KEY = I.INVESTIGATION_KEY
        WHERE (L.LAB_TEST_KEY IN (SELECT LAB_TEST_KEY FROM dbo.LAB_TEST WHERE LAB_RPT_UID IN (SELECT value FROM STRING_SPLIT(@obs_uids, ','))))
          AND (L.INVESTIGATION_KEY <> 1) 	AND (I.RECORD_STATUS_CD = 'ACTIVE')
        ORDER BY LAB_TEST_KEY;

        if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_InvLab;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


--------------------------------------------------13. Create Table  Tmp_BothTable--------------------------------------

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @Proc_Step_no + 1 ;

        SET @PROC_STEP_NAME = 'GENERATING  #Tmp_BothTable';


        IF OBJECT_ID('tempdb..#TMP_BothTable', 'U') IS NOT NULL
            drop table  #TMP_BothTable ;


        SELECT INV.INVESTIGATION_KEY,
               INV.LAB_TEST_KEY as INVTestKey,
               L.LAB_TEST_KEY   as LabTestKey,
               L.LAB_RPT_LOCAL_ID
        INTO  #TMP_BothTable
        FROM #TMP_InvLab INV
                 INNER JOIN dbo.Lab_test L with (nolock)
                            ON INV.LAB_TEST_KEY = L.LAB_TEST_KEY;

        if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_InvLab;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @Proc_Step_Name = 'GENERATING  #TMP_Inv2Labs';


        IF OBJECT_ID('tempdb..#TMP_Inv2Labs', 'U') IS NOT NULL
            DROP TABLE #TMP_Inv2Labs ;

        SELECT distinct
            b.investigation_key,
            b.LabTestKey as lab_test_key,
            l.lab_rpt_LOCAL_ID,
            l.LAB_RPT_RECEIVED_BY_PH_DT,
            l.SPECIMEN_COLLECTION_DT,
            l.RESULTED_LAB_TEST_CD_DESC,
            l.RESULTEDTEST_VAL_CD_DESC,
            l.NUMERIC_RESULT_WITHUNITS,
            l.LAB_RESULT_TXT_VAL,
            l.LAB_RESULT_COMMENTS,
            l.ELR_IND
        INTO #TMP_Inv2Labs
        FROM #TMP_BothTable b
                 INNER JOIN dbo.lab100 l with (nolock) on  l.LAB_RPT_LOCAL_ID = b.LAB_RPT_LOCAL_ID
        ORDER BY b.investigation_key;

        if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_Inv2Labs;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;
------------------------------------------------------------------15. Create Table TMP_SPECIMEN_COLLECTION---------------------------------------------------------
        BEGIN TRANSACTION
            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @Proc_Step_Name = 'GENERATING  #TMP_SPECIMEN_COLLECTION';


            IF OBJECT_ID('tempdb..#TMP_SPECIMEN_COLLECTION', 'U') IS NOT NULL
                DROP TABLE #TMP_SPECIMEN_COLLECTION ;

            SELECT DISTINCT  INVESTIGATION_KEY ,
                             MIN(SPECIMEN_COLLECTION_DT) as  EARLIEST_SPECIMEN_COLLECTION_DT
            INTO  #TMP_SPECIMEN_COLLECTION
            from  #TMP_Inv2Labs with (nolock) where SPECIMEN_COLLECTION_DT is not null
            Group by INVESTIGATION_KEY
            union
            select INVESTIGATION_KEY, EARLIEST_SPECIMEN_COLLECT_DATE AS EARLIEST_SPECIMEN_COLLECTION_DT
            from dbo.CASE_LAB_DATAMART c
            WHERE c.INVESTIGATION_KEY IN (SELECT INVESTIGATION_KEY
                                          FROM dbo.INVESTIGATION
                                          WHERE case_uid IN (SELECT value FROM STRING_SPLIT(@phc_uids, ',')))
            ;

            if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_SPECIMEN_COLLECTION;


            SELECT @ROWCOUNT_NO = @@ROWCOUNT;

            INSERT INTO [DBO].[JOB_FLOW_LOG]
            (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
            VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);
        COMMIT TRANSACTION;
-----------------------------------------------------------------16. Create Table TMP_CASE_LAB_DATAMART_MODIFIED---------------------------------
        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'GENERATING  #TMP_CASE_LAB_DATAMART_MODIFIED';


        IF OBJECT_ID('tempdb..#TMP_CASE_LAB_DATAMART_MODIFIED', 'U') IS NOT NULL
            DROP TABLE  #TMP_CASE_LAB_DATAMART_MODIFIED ;

        CREATE TABLE #TMP_CASE_LAB_DATAMART_MODIFIED
        (
            INVESTIGATION_KEY BIGINT NOT NULL,
            EARLIEST_SPECIMEN_COLLECTION_DT  DATETIME NULL
        );


        INSERT INTO #TMP_CASE_LAB_DATAMART_MODIFIED
        SELECT DISTINCT C.INVESTIGATION_KEY ,
                        SC.EARLIEST_SPECIMEN_COLLECTION_DT
        from  dbo.[CASE_LAB_DATAMART] C with (nolock)
                  JOIN #TMP_SPECIMEN_COLLECTION SC with (nolock) ON SC.INVESTIGATION_KEY = C.INVESTIGATION_KEY
        order by C.INVESTIGATION_KEY asc
        ;

        if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_CASE_LAB_DATAMART_MODIFIED;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;
        ------------------------------------------------------17. Create Table  TMP_INV_SUMM_DATAMART


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @Proc_Step_Name = 'Generating #TMP_INV_SUMM_DATAMART';


        IF OBJECT_ID('tempdb..#TMP_INV_SUMM_DATAMART', 'U') IS NOT NULL
            DROP TABLE  #TMP_INV_SUMM_DATAMART

        select A.*
             ,CASE WHEN A.NOTIFICATION_STATUS IS NOT NULL THEN A.INVESTIGATION_CREATED_BY
                   ELSE NULL END AS NOTIFICATION_SUBMITTER ---42
             --,A.INVESTIGATION_LAST_UPDTD_DATE AS NOTIFICATION_LAST_UPDATED_DATE	---43
             ,CASE WHEN A.NOTIFICATION_STATUS IS NOT NULL THEN coalesce(A.NOTIFICATION_LAST_CHANGE_TIME,A.INVESTIGATION_LAST_UPDTD_DATE)
                   ELSE NULL END AS NOTIFICATION_LAST_UPDATED_DATE ---43
             ,CASE WHEN A.NOTIFICATION_STATUS IS NOT NULL THEN Substring(A.INVESTIGATION_LAST_UPDTD_BY,1,50)
                   ELSE NULL END AS NOTIFICATION_LAST_UPDATED_USER ---44
             ,A.CONFIRMATIONDTE as CONFIRMATION_DT   ----49
             ,A.DIAGNOSIS_DATE as DIAGNOSIS_DT   ----49
             ,A.ILLNESS_ONSET_DATE as ILLNESS_ONSET_DT
             ,Substring(B.LABORATORY_INFORMATION,1,4000) as LABORATORY_INFORMATION ----54----6/2/2021
             ,S.EARLIEST_SPECIMEN_COLLECTION_DT  EARLIEST_SPECIMEN_COLLECT_DATE ----55 ----dont have this field in the table
             ,S.EARLIEST_SPECIMEN_COLLECTION_DT   ----55 ----dont have this field in the table
             ,CAST(NULL as datetime ) as EVENT_DATE----56
             ,CAST(NULL as  varchar(200))as EVENT_DATE_TYPE----57
        INTO #TMP_INV_SUMM_DATAMART
        FROM #TMP_S_INV_SUMM_DATAMART_INIT A
                 LEFT OUTER JOIN [dbo].[CASE_LAB_DATAMART]  B  with (nolock) ON 	A.INVESTIGATION_KEY=B.INVESTIGATION_KEY
                 LEFT OUTER JOIN #TMP_CASE_LAB_DATAMART_MODIFIED S with (nolock) ON A.INVESTIGATION_KEY=S.INVESTIGATION_KEY
        ;


        if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_INV_SUMM_DATAMART;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        ---------------------

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @PROC_STEP_NAME = 'Updating dbo.INV_SUMM_DATAMART';


        UPDATE  dbo.INV_SUMM_DATAMART
        SET  [INVESTIGATION_KEY]             =  ISD.[INVESTIGATION_KEY],---1
             [PATIENT_LOCAL_ID]              =  ISD.[PATIENT_LOCAL_ID] ,---2
             [PATIENT_KEY]                   =  ISD.[PATIENT_KEY],----3
             [INVESTIGATION_LOCAL_ID]        =  ISD.[INVESTIGATION_LOCAL_ID],---4
             [DISEASE]                       =  ISD.[DISEASE] ,---5
             [DISEASE_CD]                    =  ISD.[DISEASE_CD] ,---6
             [PATIENT_FIRST_NAME]            =  ISD.[PATIENT_FIRST_NAME] ,---7
             [PATIENT_LAST_NAME]             =  ISD.[PATIENT_LAST_NAME],---8
             [PATIENT_DOB]                   =  ISD.[PATIENT_DOB]  ,---9
             [PATIENT_CURRENT_SEX]           =  ISD.[PATIENT_CURRENT_SEX] ,---10
             [AGE_REPORTED]                  =  ISD.[AGE_REPORTED],----11
             [AGE_REPORTED_UNIT]             =  ISD.[AGE_REPORTED_UNIT],----12
             [PATIENT_STREET_ADDRESS_1]      =  ISD.[PATIENT_STREET_ADDRESS_1] ,----13
             [PATIENT_STREET_ADDRESS_2]      =  ISD.[PATIENT_STREET_ADDRESS_2] ,-----14
             [PATIENT_CITY]                  =  ISD.[PATIENT_CITY],----15
             [PATIENT_STATE]                 =  ISD.[PATIENT_STATE] ,----16
             [PATIENT_ZIP]                   =  ISD.[PATIENT_ZIP] ,----17
             [PATIENT_COUNTY]                =  ISD.[PATIENT_COUNTY] ,---18
             [PATIENT_ETHNICITY]             =  ISD.[PATIENT_ETHNICITY] ,----19
             [RACE_CALCULATED]               =  ISD.[RACE_CALCULATED],---table name changed---20
             [RACE_CALC_DETAILS]             =  ISD.[RACE_CALC_DETAILS],---table name changed---21
             [INVESTIGATION_STATUS]          =  ISD.[INVESTIGATION_STATUS],---22
             [EARLIEST_RPT_TO_CNTY_DT]       =  ISD.[EARLIEST_RPT_TO_CNTY_DT],---23
             [EARLIEST_RPT_TO_STATE_DT]      =  ISD.[EARLIEST_RPT_TO_STATE_DT]  ,---24
             [DIAGNOSIS_DATE]                =  ISD.[DIAGNOSIS_DATE] ,---25
             [ILLNESS_ONSET_DATE]            =  ISD.[ILLNESS_ONSET_DATE],---26
             [CASE_STATUS]                   =  ISD.[CASE_STATUS],---27
             [MMWR_WEEK]                     =  ISD.[MMWR_WEEK] ,---28
             [MMWR_YEAR]                     =  ISD.[MMWR_YEAR] ,---29
             [INVESTIGATION_CREATE_DATE]     =  ISD.[INVESTIGATION_CREATE_DATE] ,---30
             [INVESTIGATION_CREATED_BY]      =  ISD.[INVESTIGATION_CREATED_BY],---31
             [INVESTIGATION_LAST_UPDTD_DATE] =  ISD.[INVESTIGATION_LAST_UPDTD_DATE],---32
             [NOTIFICATION_STATUS]            = ISD.[NOTIFICATION_STATUS]  ,----33
             [INVESTIGATION_LAST_UPDTD_BY]    = ISD.[INVESTIGATION_LAST_UPDTD_BY] ,----34
             [PROGRAM_JURISDICTION_OID]       = ISD.[PROGRAM_JURISDICTION_OID] ,---35
             [PROGRAM_AREA]                   = ISD.[PROGRAM_AREA],-----36
             [PHYSICIAN_LAST_NAME]            = ISD.[PHYSICIAN_LAST_NAME] ,----37
             [PHYSICIAN_FIRST_NAME]           = ISD.[PHYSICIAN_FIRST_NAME],----38
             [NOTIFICATION_LOCAL_ID]          = ISD.[NOTIFICATION_LOCAL_ID],----39
             [NOTIFICATION_CREATE_DATE]       = ISD.[NOTIFICATION_CREATE_DATE] ,----40
             [NOTIFICATION_SENT_DATE]         = ISD.[NOTIFICATION_SENT_DATE],  ----41         ---Required since NBS 6.3
             [NOTIFICATION_SUBMITTER]         = ISD.[NOTIFICATION_SUBMITTER]  ,---42
             [NOTIFICATION_LAST_UPDATED_DATE] = ISD.[NOTIFICATION_LAST_UPDATED_DATE] ,---43
             [NOTIFICATION_LAST_UPDATED_USER] = ISD.[NOTIFICATION_LAST_UPDATED_USER],---44
             [FIRST_POSITIVE_CULTURE_DT]      = ISD.[FIRST_POSITIVE_CULTURE_DT] ,---45
             [INV_START_DT]                   = ISD.[INV_START_DT]  ,---46
             [HSPTL_ADMISSION_DT]             = ISD.[HSPTL_ADMISSION_DT],---47
             [INV_RPT_DT]             = ISD.[INV_RPT_DT],----48
             [CONFIRMATION_DT]                = ISD.[CONFIRMATION_DT] ,----49
             [CONFIRMATION_METHOD]            = ISD.[CONFIRMATION_METHOD],----50
             [CURR_PROCESS_STATE]             = ISD.[CURR_PROCESS_STATE] ,----51
             [JURISDICTION_NM]                = ISD.[JURISDICTION_NM],---52
             [PATIENT_COUNTY_CODE]            = ISD.[PATIENT_COUNTY_CODE],---53
             [LABORATORY_INFORMATION]         = ISD.[LABORATORY_INFORMATION]----54
        --[EARLIEST_SPECIMEN_COLLECT_DATE] = ISD.[EARLIEST_SPECIMEN_COLLECT_DATE] ---table changed----55
        --[EVENT_DATE]                     = ISD.[EVENT_DATE] ,---56
        --[EVENT_DATE_TYPE]                 =ISD.[EVENT_DATE_TYPE]----57
        FROM   #TMP_INV_SUMM_DATAMART ISD
        Where ISD.[INVESTIGATION_KEY]  = [dbo].[INV_SUMM_DATAMART].INVESTIGATION_KEY
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        ---------------------

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @PROC_STEP_NAME = 'Updating Additional values in dbo.INV_SUMM_DATAMART';


        DELETE inv FROM  dbo.INV_SUMM_DATAMART INV
                             INNER JOIN [dbo].[INVESTIGATION] I ON   I.[INVESTIGATION_KEY]=INV.INVESTIGATION_KEY
        WHERE I.CASE_TYPE= 'I' AND I.RECORD_STATUS_CD = 'INACTIVE'
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        -------------------
        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @Proc_Step_Name = 'Inserting new records into dbo.INV_SUMM_DATAMART';


        IF OBJECT_ID('tempdb..#TMP_FINAL_INV_SUMM_DATAMART', 'U') IS NOT NULL
            DROP TABLE    #TMP_FINAL_INV_SUMM_DATAMART ;


        INSERT INTO dbo.INV_SUMM_DATAMART(
                                           [INVESTIGATION_KEY]
                                         ,[PATIENT_KEY]
                                         ,[PATIENT_LOCAL_ID]
                                         ,[INVESTIGATION_LOCAL_ID]
                                         ,[DISEASE]
                                         ,[DISEASE_CD]
                                         ,[PATIENT_FIRST_NAME]
                                         ,[PATIENT_LAST_NAME]
                                         ,[PATIENT_DOB]
                                         ,[PATIENT_CURRENT_SEX]
                                         ,[AGE_REPORTED]
                                         ,[AGE_REPORTED_UNIT]
                                         ,[PATIENT_STREET_ADDRESS_1]
                                         ,[PATIENT_STREET_ADDRESS_2]
                                         ,[PATIENT_CITY]
                                         ,[PATIENT_STATE]
                                         ,[PATIENT_ZIP]
                                         ,[PATIENT_COUNTY]
                                         ,[PATIENT_ETHNICITY]
                                         ,[RACE_CALCULATED]
                                         ,[RACE_CALC_DETAILS]
                                         ,[INVESTIGATION_STATUS]
                                         ,[EARLIEST_RPT_TO_CNTY_DT]
                                         ,[EARLIEST_RPT_TO_STATE_DT]
                                         ,[DIAGNOSIS_DATE]
                                         ,[ILLNESS_ONSET_DATE]
                                         ,[CASE_STATUS]
                                         ,[MMWR_WEEK]
                                         ,[MMWR_YEAR]
                                         ,[INVESTIGATION_CREATE_DATE]
                                         ,[INVESTIGATION_CREATED_BY]
                                         ,[INVESTIGATION_LAST_UPDTD_DATE]
                                         ,[NOTIFICATION_STATUS]
                                         ,[INVESTIGATION_LAST_UPDTD_BY]
                                         ,[PROGRAM_JURISDICTION_OID]
            --,[EVENT_DATE]
            --,[EVENT_DATE_TYPE]
                                         ,[LABORATORY_INFORMATION]
                                         ,[FIRST_POSITIVE_CULTURE_DT]
            --,[EARLIEST_SPECIMEN_COLLECT_DATE]
                                         ,[PROGRAM_AREA]
                                         ,[PHYSICIAN_LAST_NAME]
                                         ,[PHYSICIAN_FIRST_NAME]
                                         ,[NOTIFICATION_LOCAL_ID]
                                         ,[NOTIFICATION_CREATE_DATE]
                                         ,[NOTIFICATION_SENT_DATE]
                                         ,[NOTIFICATION_SUBMITTER]
                                         ,[NOTIFICATION_LAST_UPDATED_DATE]
                                         ,[NOTIFICATION_LAST_UPDATED_USER]
                                         ,[INV_RPT_DT]
                                         ,[INV_START_DT]
                                         ,[CONFIRMATION_DT]
                                         ,[CONFIRMATION_METHOD]
                                         ,[HSPTL_ADMISSION_DT]
                                         ,[CURR_PROCESS_STATE]
                                         ,[PATIENT_COUNTY_CODE]
                                         ,[JURISDICTION_NM]
        )
        SELECT DISTINCT [INVESTIGATION_KEY]
                      ,[PATIENT_KEY]
                      ,[PATIENT_LOCAL_ID]
                      ,[INVESTIGATION_LOCAL_ID]
                      ,substring([DISEASE],1,50)
                      ,[DISEASE_CD]
                      ,[PATIENT_FIRST_NAME]
                      ,[PATIENT_LAST_NAME]
                      ,[PATIENT_DOB]
                      ,[PATIENT_CURRENT_SEX]
                      ,[AGE_REPORTED]
                      ,[AGE_REPORTED_UNIT]
                      ,[PATIENT_STREET_ADDRESS_1]
                      ,[PATIENT_STREET_ADDRESS_2]
                      ,[PATIENT_CITY]
                      ,[PATIENT_STATE]
                      ,[PATIENT_ZIP]
                      ,[PATIENT_COUNTY]
                      ,[PATIENT_ETHNICITY]
                      ,[RACE_CALCULATED]
                      ,[RACE_CALC_DETAILS]
                      ,[INVESTIGATION_STATUS]
                      ,[EARLIEST_RPT_TO_CNTY_DT]
                      ,[EARLIEST_RPT_TO_STATE_DT]
                      ,[DIAGNOSIS_DATE]
                      ,[ILLNESS_ONSET_DATE]
                      ,[CASE_STATUS]
                      ,[MMWR_WEEK]
                      ,[MMWR_YEAR]
                      ,[INVESTIGATION_CREATE_DATE]
                      ,[INVESTIGATION_CREATED_BY]
                      ,[INVESTIGATION_LAST_UPDTD_DATE]
                      ,[NOTIFICATION_STATUS]
                      ,[INVESTIGATION_LAST_UPDTD_BY]
                      ,[PROGRAM_JURISDICTION_OID]
                      --,[EVENT_DATE]
                      --,[EVENT_DATE_TYPE]
                      ,[LABORATORY_INFORMATION]
                      ,[FIRST_POSITIVE_CULTURE_DT]
                      --,[EARLIEST_SPECIMEN_COLLECT_DATE]
                      ,[PROGRAM_AREA]
                      ,[PHYSICIAN_LAST_NAME]
                      ,[PHYSICIAN_FIRST_NAME]
                      ,[NOTIFICATION_LOCAL_ID]
                      ,[NOTIFICATION_CREATE_DATE]
                      ,[NOTIFICATION_SENT_DATE]
                      ,[NOTIFICATION_SUBMITTER]
                      ,[NOTIFICATION_LAST_UPDATED_DATE]
                      ,[NOTIFICATION_LAST_UPDATED_USER]
                      ,[INV_RPT_DT]
                      ,[INV_START_DT]
                      ,[CONFIRMATION_DT]
                      ,[CONFIRMATION_METHOD]
                      ,[HSPTL_ADMISSION_DT]
                      ,[CURR_PROCESS_STATE]
                      ,[PATIENT_COUNTY_CODE]
                      ,[JURISDICTION_NM]
        FROM #TMP_INV_SUMM_DATAMART T
        WHERE NOT EXISTS
                  (
                      SELECT *
                      FROM dbo.INV_SUMM_DATAMART with (nolock)
                      WHERE INVESTIGATION_KEY = T.INVESTIGATION_KEY
                  )
        ;



        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;



        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @PROC_STEP_NAME = 'Updating EVENT DATE AND TYPE in dbo.INV_SUMM_DATAMART';

        IF NOT EXISTS (SELECT 1 FROM #TMP_CASE_LAB_DATAMART_MODIFIED)
            BEGIN

                INSERT INTO #TMP_CASE_LAB_DATAMART_MODIFIED
                SELECT DISTINCT C.INVESTIGATION_KEY ,
                                C.EARLIEST_SPECIMEN_COLLECT_DATE as EARLIEST_SPECIMEN_COLLECTION_DT
                FROM  dbo.[CASE_LAB_DATAMART] C with (nolock)
            END


        if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_CASE_LAB_DATAMART_MODIFIED;


        UPDATE ISD
        set ISD.EVENT_DATE = CLD.EVENT_DATE,
            ISD.EVENT_DATE_TYPE = CLD.EVENT_DATE_TYPE,
            ISD.Earliest_specimen_collect_date = cld.Earliest_specimen_collect_date,
            ISD.LABORATORY_INFORMATION  = cld.LABORATORY_INFORMATION
        FROM dbo.INV_SUMM_DATAMART ISD
                 LEFT OUTER JOIN [dbo].[CASE_LAB_DATAMART]  CLD  with (nolock) ON 	ISD.INVESTIGATION_KEY=CLD.INVESTIGATION_KEY
                 JOIN #TMP_CASE_LAB_DATAMART_MODIFIED TCLDM with (nolock) ON ISD.INVESTIGATION_KEY=TCLDM.INVESTIGATION_KEY
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no =  @Proc_Step_no +1  ;
        SET @PROC_STEP_NAME = 'Creating #TMP_CASE_LAB_DATAMART_MODIFIED_OUTPUT';

        --new stag testing changes 02012024
        IF OBJECT_ID('tempdb..#TMP_CASE_LAB_DATAMART_MODIFIED_output') IS NOT NULL
            DROP TABLE #TMP_CASE_LAB_DATAMART_MODIFIED_output;


        SELECT distinct CASE_UID
        INTO #TMP_CASE_LAB_DATAMART_MODIFIED_OUTPUT
        FROM #TMP_CASE_LAB_DATAMART_MODIFIED TCL WITH ( NOLOCK)
                 INNER JOIN dbo.INVESTIGATION INV  WITH ( NOLOCK)
                            ON TCL.INVESTIGATION_KEY = INV.INVESTIGATION_KEY
        GROUP BY CASE_UID
        ;


        /*Notes: If required, this can be revisited.*/
        --CREATE  NONCLUSTERED INDEX idx_tlcd_caseuid ON #TMP_CASE_LAB_DATAMART_MODIFIED_OUTPUT (CASE_UID);


        if @debug = 'true' select @Proc_Step_Name as step, * from #TMP_CASE_LAB_DATAMART_MODIFIED_OUTPUT;

        --new stag testing changes 02012024


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no =  @Proc_Step_no +1  ;
        SET @PROC_STEP_NAME = 'Creating #TEMP_MIN_MAX_NOTIFICATION';


        IF OBJECT_ID('tempdb..#TEMP_MIN_MAX_NOTIFICATION') IS NOT NULL
            DROP TABLE #TEMP_MIN_MAX_NOTIFICATION;

        SELECT DISTINCT
            first_notification_status AS FIRSTNOTIFICATIONSTATUS
                      , notif_rejected_count AS NOTIFREJECTEDCOUNT
                      , notif_created_count AS  NOTIFCREATEDCOUNT
                      , notif_sent_count AS NOTIFSENTCOUNT
                      , first_notification_send_date AS FIRSTNOTIFICATIONSENDDATE
                      , notif_created_pending_count AS NOTIFCREATEDPENDINGSCOUNT
                      , last_notification_date AS LASTNOTIFICATIONDATE
                      , last_notification_send_date AS LASTNOTIFICATIONSENDDATE
                      , first_notification_date AS FIRSTNOTIFICATIONDATE
                      , first_notification_submitted_by AS FIRSTNOTIFICATIONSUBMITTEDBY
                      , last_notification_submitted_by AS LASTNOTIFICATIONSUBMITTEDBY
                      , notification_date AS NOTIFICATIONDATE
                      , PUBLIC_HEALTH_CASE_UID
        INTO #TEMP_MIN_MAX_NOTIFICATION
        FROM dbo.nrt_investigation_notification WITH (NOLOCK)
        WHERE notification_uid IN (SELECT value FROM STRING_SPLIT(@notif_uids, ','))
           OR PUBLIC_HEALTH_CASE_UID IN (SELECT CASE_UID FROM #TMP_CASE_LAB_DATAMART_MODIFIED_output)
        ;

        if @debug = 'true' select @Proc_Step_Name as step, * from #TEMP_MIN_MAX_NOTIFICATION;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no =  @Proc_Step_no +1  ;
        SET @PROC_STEP_NAME = 'Creating tmp_inv_sum_nnd_info';  -- DO NOT DROP NEEDED FOR HEP_DATAMART


        IF OBJECT_ID('tempdb..#TMP_inv_sum_nnd_info') IS NOT NULL
            DROP TABLE #TMP_inv_sum_nnd_info;

        SELECT PUBLIC_HEALTH_CASE_UID,FIRSTNOTIFICATIONSENDDATE,INVESTIGATION_KEY
        INTO #TMP_inv_sum_nnd_info
        FROM #TEMP_MIN_MAX_NOTIFICATION tcl with ( nolock)
                 INNER JOIN dbo.INVESTIGATION inv  with ( nolock)
                            ON tcl.PUBLIC_HEALTH_CASE_UID = inv.CASE_UID
        WHERE FIRSTNOTIFICATIONSENDDATE is not null
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;



        BEGIN TRANSACTION;

        SET @Proc_Step_no =  @Proc_Step_no +1  ;
        SET @PROC_STEP_NAME = 'Updating INIT_NND_NOTF_DT in INV_SUMM_DATAMART';


        UPDATE ISD
        SET ISD.INIT_NND_NOT_DT = NND.FIRSTNOTIFICATIONSENDDATE
        FROM dbo.INV_SUMM_DATAMART ISD
                 JOIN #TMP_inv_sum_nnd_info NND with (nolock) ON ISD.INVESTIGATION_KEY=NND.INVESTIGATION_KEY
        where INIT_NND_NOT_DT is null
        ;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'INV_SUMM_DATAMART','INV_SUMM_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;



        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no +1 ;
        SET @Proc_Step_Name = 'Deleting TMP Tables ';



        IF OBJECT_ID('tempdb..#TMP_UPDATED_INV_WITH_NOTIF', 'U') IS NOT NULL
            DROP TABLE #TMP_UPDATED_INV_WITH_NOTIF
            ;

        IF OBJECT_ID('tempdb..#TMP_PATIENT_LOCATION_KEYS_INIT', 'U') IS NOT NULL
            DROP TABLE #TMP_PATIENT_LOCATION_KEYS_INIT
            ;

        IF OBJECT_ID('tempdb..#TMP_CONFIRMATION_METHOD_BASE', 'U') IS NOT NULL
            DROP TABLE #TMP_CONFIRMATION_METHOD_BASE
            ;

        IF OBJECT_ID('tempdb..##TMP_CONFIRMATION_METHOD_PIVOT', 'U') IS NOT NULL
            DROP TABLE ##TMP_CONFIRMATION_METHOD_PIVOT
            ;

        IF OBJECT_ID('tempdb..#TMP_PATIENT_LOCATION_KEYS', 'U') IS NOT NULL
            DROP TABLE #TMP_PATIENT_LOCATION_KEYS
            ;

        IF OBJECT_ID('tempdb..#TMP_PATIENT_INFO', 'U') IS NOT NULL
            DROP TABLE #TMP_PATIENT_INFO
            ;

        IF OBJECT_ID('tempdb..#TMP_PHYSICIAN_INFO', 'U') IS NOT NULL
            DROP TABLE #TMP_PHYSICIAN_INFO
            ;

        IF OBJECT_ID('tempdb..#TMP_PATIENT_DETAILS', 'U') IS NOT NULL
            DROP TABLE #TMP_PATIENT_DETAILS
            ;

        IF OBJECT_ID('tempdb..#TMP_S_INV_SUMM_DATAMART_INIT', 'U') IS NOT NULL
            DROP TABLE #TMP_S_INV_SUMM_DATAMART_INIT
            ;

        IF OBJECT_ID('tempdb..#TMP_InvLab', 'U') IS NOT NULL
            DROP TABLE #TMP_InvLab
            ;

        IF OBJECT_ID('tempdb..#TMP_Lab', 'U') IS NOT NULL
            DROP TABLE #TMP_Lab
            ;

        IF OBJECT_ID('tempdb..#TMP_BothTable', 'U') IS NOT NULL
            DROP TABLE #TMP_BothTable
            ;

        IF OBJECT_ID('tempdb..#TMP_Inv2Labs', 'U') IS NOT NULL
            DROP TABLE #TMP_Inv2Labs
            ;

        IF OBJECT_ID('tempdb..#TMP_SPECIMEN_COLLECTION', 'U') IS NOT NULL
            DROP TABLE #TMP_SPECIMEN_COLLECTION
            ;


        IF OBJECT_ID('tempdb..#TMP_INV_SUMM_DATAMART', 'U') IS NOT NULL
            DROP TABLE #TMP_INV_SUMM_DATAMART
            ;


        IF OBJECT_ID('tempdb..#TMP_INV_SUMM_DATAMART_LAB_DT', 'U') IS NOT NULL
            drop table    #TMP_INV_SUMM_DATAMART_LAB_DT ;


        IF OBJECT_ID('tempdb..#TEMP_MIN_MAX_NOTIFICATION', 'U') IS NOT NULL
            drop table #TEMP_MIN_MAX_NOTIFICATION

        IF OBJECT_ID('tempdb..#TEMP_PHCFACT', 'U') IS NOT NULL
            drop table    #TEMP_PHCFACT ;

        IF OBJECT_ID('tempdb..#TMP_CLDM_CASE_LAB_DATAMART_FINAL', 'U') IS NOT NULL
            drop table  #TMP_CLDM_CASE_LAB_DATAMART_FINAL ;

        IF OBJECT_ID('tempdb..#TMP_CASE_LAB_DATAMART_MODIFIED_output') IS NOT NULL
            DROP TABLE #TMP_CASE_LAB_DATAMART_MODIFIED_output;

        COMMIT TRANSACTION;

----------------------------------------------------------------------------
        BEGIN TRANSACTION ;

        SET @Proc_Step_no =  999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;


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
              'INV_SUMM_DATAMART'
            ,'INV_SUMM_DATAMART'
            ,'COMPLETE'
            ,999
            ,@Proc_Step_name
            ,@RowCount_no
            );


        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION;
            END;
        DECLARE @ErrorNumber int= ERROR_NUMBER();
        DECLARE @ErrorLine int= ERROR_LINE();
        DECLARE @ErrorMessage nvarchar(4000)= ERROR_MESSAGE();
        DECLARE @ErrorSeverity int= ERROR_SEVERITY();
        DECLARE @ErrorState int= ERROR_STATE();
        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count] )
        VALUES( @Batch_id, 'INV_SUMM_DATAMART', 'INV_SUMM_DATAMART', 'ERROR', @Proc_Step_no, 'ERROR - '+@Proc_Step_name, 'Step -'+CAST(@Proc_Step_no AS varchar(3))+' -'+CAST(@ErrorMessage AS varchar(500)), 0 );
        RETURN -1;
    END CATCH;
END;
