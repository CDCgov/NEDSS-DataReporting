CREATE OR ALTER PROCEDURE [dbo].[sp_hepatitis_datamart_postprocessing]
    @phc_id nvarchar(max),
    @debug bit = 'false'
AS
BEGIN
    /*
    * [Description]
    * This stored procedure is handles event based updates to Hepatitis Datamart.
    * 1. Receives input list of Public_health_case_uids.
    * 2. Uses dimensions and tables records updated by RTR for processing.
    * 3. Inserts and updates new records into Hepatitis Datamart table.
    */

    BEGIN TRY


        DECLARE @RowCount_no int;

        DECLARE @Proc_Step_no float= 0;

        DECLARE @Proc_Step_Name varchar(200)= '';


        DECLARE @batch_id BIGINT;
        SET @batch_id = cast((format(getdate(),'yyyyMMddHHmmss')) as bigint);
        PRINT @batch_id;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';


        INSERT INTO [dbo].[job_flow_log]( batch_id, ---------------@batch_id
                                          [Dataflow_Name], --------------'HEPATITIS_DATAMART'
                                          [package_Name], --------------'Hepatitis_Case_DATAMART'
                                          [Status_Type], ---------------START
                                          [step_number], ---------------@Proc_Step_no
                                          [step_name], ------------------@Proc_Step_Name=sp_start
                                          [row_count], --------------------0
                                          [Msg_Description1]
        )
        VALUES( @batch_id, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @Proc_Step_no, @Proc_Step_Name, 0,LEFT('ID List-' + @phc_id,500));

        COMMIT TRANSACTION;


-----------------------------------------------------------2. (New) Create Table #TMP_CONDITION---------------------------------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_CONDITION';
        SET @Proc_Step_no = 2;

        IF OBJECT_ID('#TMP_CONDITION', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_CONDITION;
            END;

        SELECT CONDITION_CD, CONDITION_DESC, DISEASE_GRP_DESC, CONDITION_KEY
        INTO #TMP_CONDITION
        FROM [dbo].[CONDITION] WITH(NOLOCK)
        WHERE CONDITION_CD IN( '10110', '10104', '10100', '10106', '10101', '10102', '10103', '10105', '10481', '50248', '999999' );

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;


---------------------------------------------------------------------3. CREATE TABLE #TMP_F_PAGE_CASE-------------------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_F_PAGE_CASE';
        SET @Proc_Step_no = 3;

        IF OBJECT_ID('#TMP_F_PAGE_CASE', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_F_PAGE_CASE;
            END;

        /* Select Keys that do not exist in Hepatitis Datamart and Investigations that are being updated.*/

        SELECT F_PAGE_CASE.INVESTIGATION_KEY, T.CONDITION_KEY, F_PAGE_CASE.PATIENT_KEY
        INTO #TMP_F_PAGE_CASE
        FROM dbo.F_PAGE_CASE WITH(NOLOCK)---Original table
                 INNER JOIN	 #TMP_CONDITION AS T WITH(NOLOCK) ON F_PAGE_CASE.CONDITION_KEY = T.CONDITION_KEY  ------(my table condition)
                 INNER JOIN	 dbo.D_PATIENT WITH(NOLOCK)		 ON F_PAGE_CASE.PATIENT_KEY = D_PATIENT.PATIENT_KEY
                 INNER JOIN	 dbo.INVESTIGATION WITH(NOLOCK)		 ON INVESTIGATION.INVESTIGATION_KEY = F_PAGE_CASE.INVESTIGATION_KEY
                 LEFT JOIN	 dbo.HEPATITIS_DATAMART hd WITH(NOLOCK) ON F_PAGE_CASE.INVESTIGATION_KEY = hd.INVESTIGATION_KEY
        WHERE   (hd.INVESTIGATION_KEY IS NULL
            OR  (INVESTIGATION.CASE_UID IN (SELECT value FROM STRING_SPLIT(@phc_id, ','))))
          AND INVESTIGATION.RECORD_STATUS_CD = 'ACTIVE'
        ORDER BY F_PAGE_CASE.INVESTIGATION_KEY;

        IF @debug ='true' SELECT '#TMP_F_PAGE_CASE', * FROM #TMP_F_PAGE_CASE;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;


---------------------------------------------------------------------4. CREATE TABLE #TMP_D_INV_ADMINISTRATIVE
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_D_INV_ADMINISTRATIVE';
        SET @Proc_Step_no = 4;


        IF OBJECT_ID('#TMP_F_INV_ADMINISTRATIVE', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_F_INV_ADMINISTRATIVE;
            END;


        SELECT page_case.D_INV_ADMINISTRATIVE_KEY, page_case.INVESTIGATION_KEY
        INTO #TMP_F_INV_ADMINISTRATIVE
        FROM dbo.F_PAGE_CASE AS page_case WITH(NOLOCK) ----Original table
                 INNER JOIN	 #TMP_F_PAGE_CASE AS T
                                ON T.INVESTIGATION_KEY = PAGE_CASE.INVESTIGATION_KEY  ---(My Table)--Should it be F-Page or tmp_F_Page
        ORDER BY D_INV_ADMINISTRATIVE_KEY;

        IF @debug ='true' SELECT 'TMP_F_INV_ADMINISTRATIVE', * FROM #TMP_F_INV_ADMINISTRATIVE;


        IF OBJECT_ID('#TMP_D_INV_ADMINISTRATIVE', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_D_INV_ADMINISTRATIVE;
            END;

        /*D_INV_ADMINISTRATOR columns are temporarily collected. If the columns do not exist, null values are assigned.*/

        SELECT admin.*
        INTO #D_INV_ADMIN_TEMP_COLS
        FROM (
                 SELECT CAST(NULL as varchar(300)) AS ADM_INNC_NOTIFICATION_DT,
                        CAST(NULL as varchar(300)) AS ADM_FIRST_RPT_TO_PHD_DT,
                        CAST(NULL as varchar(300)) AS ADM_BINATIONAL_RPTNG_CRIT
             ) AS temp_admin_columns
                 CROSS APPLY
             ( SELECT D_INV_ADMINISTRATIVE_KEY,
                      ADM_INNC_NOTIFICATION_DT,
                      ADM_FIRST_RPT_TO_PHD_DT,
                      ADM_BINATIONAL_RPTNG_CRIT
               FROM dbo.D_INV_ADMINISTRATIVE
             ) AS admin;


        SELECT F.D_INV_ADMINISTRATIVE_KEY, F.INVESTIGATION_KEY AS ADMIN_INV_KEY,
               ADM_INNC_NOTIFICATION_DT AS INNC_NOTIFICATION_DT, ADM_FIRST_RPT_TO_PHD_DT AS FIRST_RPT_PHD_DT,
               ADM_BINATIONAL_RPTNG_CRIT AS BINATIONAL_RPTNG_CRIT
        INTO #TMP_D_INV_ADMINISTRATIVE
        FROM #TMP_F_INV_ADMINISTRATIVE AS F
                 LEFT JOIN #D_INV_ADMIN_TEMP_COLS AS D WITH(NOLOCK) ON F.D_INV_ADMINISTRATIVE_KEY = D.D_INV_ADMINISTRATIVE_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

-----------------------------------------------------------------------------5. CREATE TABLE TMP_D_INV_CLINICAL----------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_D_INV_CLINICAL';
        SET @Proc_Step_no = 5;


        IF OBJECT_ID('#TMP_F_INV_CLINICAL', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_F_INV_CLINICAL;
            END;


        IF OBJECT_ID('#TMP_D_INV_CLINICAL', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_D_INV_CLINICAL;
            END;


        SELECT F_PAGE_CASE.D_INV_CLINICAL_KEY, F_PAGE_CASE.INVESTIGATION_KEY
        INTO #TMP_F_INV_CLINICAL
        FROM dbo.F_PAGE_CASE WITH(NOLOCK)
                 INNER JOIN	 #TMP_F_PAGE_CASE AS PAGE_CASE ON F_PAGE_CASE.INVESTIGATION_KEY = PAGE_CASE.INVESTIGATION_KEY ---(my Table)
        ORDER BY D_INV_CLINICAL_KEY;


        SELECT clinical.*
        INTO #D_INV_CLINICAL_TEMP_COLS
        FROM (
                 SELECT CAST(NULL as varchar(4000)) AS CLN_HepDInfection,
                        CAST(NULL as varchar(4000)) AS CLN_MedsforHep
             ) AS temp_clinical_columns
                 CROSS APPLY
             ( SELECT D_INV_CLINICAL_KEY,
                      CLN_HepDInfection,
                      CLN_MedsforHep
               FROM dbo.D_INV_CLINICAL
             ) AS clinical;


        SELECT F.D_INV_CLINICAL_KEY as D_INV_CLINICAL_KEY_1 , F.INVESTIGATION_KEY AS CLINICAL_INV_KEY,
               RTRIM(LTRIM(CLN_HepDInfection)) as HEP_D_INFECTION_IND,
               RTRIM(LTRIM(CLN_MedsforHep)) as HEP_MEDS_RECVD_IND
        INTO #TMP_D_INV_CLINICAL
        FROM #TMP_F_INV_CLINICAL AS F
                 LEFT JOIN #D_INV_CLINICAL_TEMP_COLS AS D WITH(NOLOCK)  ON F.D_INV_CLINICAL_KEY = D.D_INV_CLINICAL_KEY
        ORDER BY F.INVESTIGATION_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

--------------------------------------------------------------------------------6. CREATE TABLE TMP_D_INV_PATIENT_OBS----------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_D_INV_PATIENT_OBS';
        SET @Proc_Step_no = 6;

        IF OBJECT_ID('#TMP_D_INV_PATIENT_OBS', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_D_INV_PATIENT_OBS;
            END;

        IF OBJECT_ID('#TMP_F_INV_PATIENT_OBS', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_F_INV_PATIENT_OBS;
            END;


        SELECT F_PAGE_CASE.D_INV_PATIENT_OBS_KEY, F_PAGE_CASE.INVESTIGATION_KEY
        INTO #TMP_F_INV_PATIENT_OBS
        FROM dbo.F_PAGE_CASE WITH(NOLOCK)
                 INNER JOIN #TMP_F_PAGE_CASE AS PAGE_CASE
                            ON F_PAGE_CASE.INVESTIGATION_KEY = PAGE_CASE.INVESTIGATION_KEY	---(my table)
        ORDER BY D_INV_PATIENT_OBS_KEY;

        SELECT pat_obs.*
        INTO #D_INV_PAT_OBS_TEMP_COLS
        FROM (
                 SELECT NULL AS IPO_SEXUAL_PREF
             ) AS temp_pat_obs_columns
                 CROSS APPLY
             ( SELECT D_INV_PATIENT_OBS_KEY,
                      IPO_SEXUAL_PREF
               FROM dbo.D_INV_PATIENT_OBS
             ) AS pat_obs;


        SELECT F.D_INV_PATIENT_OBS_KEY, F.INVESTIGATION_KEY AS PATIENT_OBS_INV_KEY,
               RTRIM(LTRIM(D.IPO_SEXUAL_PREF)) AS SEX_PREF
        INTO #TMP_D_INV_PATIENT_OBS
        FROM #TMP_F_INV_PATIENT_OBS AS F
                 LEFT JOIN	#D_INV_PAT_OBS_TEMP_COLS AS D WITH(NOLOCK) ON F.D_INV_PATIENT_OBS_KEY = D.D_INV_PATIENT_OBS_KEY
        ORDER BY F.INVESTIGATION_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

--------------------------------------------------------------------------------7. CREATE TABLE TMP_D_INV_EPIDEMIOLOGY----------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_D_INV_EPIDEMIOLOGY';
        SET @Proc_Step_no = 7;

        IF OBJECT_ID('#TMP_F_INV_EPIDEMIOLOGY', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_F_INV_EPIDEMIOLOGY;
            END;

        IF OBJECT_ID('#TMP_D_INV_EPIDEMIOLOGY', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_D_INV_EPIDEMIOLOGY;
            END;


        SELECT F_PAGE_CASE.[D_INV_EPIDEMIOLOGY_KEY], F_PAGE_CASE.[INVESTIGATION_KEY]
        INTO #TMP_F_INV_EPIDEMIOLOGY
        FROM dbo.F_PAGE_CASE WITH(NOLOCK)
                 INNER JOIN #TMP_F_PAGE_CASE AS PAGE_CASE  ON F_PAGE_CASE.INVESTIGATION_KEY = PAGE_CASE.INVESTIGATION_KEY	 ---(my table)
        ORDER BY D_INV_EPIDEMIOLOGY_KEY;

        SELECT epidemiology.*
        INTO #D_EPIDEMIOLOGY_TEMP_COLS
        FROM (
                 SELECT CAST( null AS varchar(2000)) AS EPI_ChildCareCase, ----1
                        CAST( null  AS varchar(2000)) AS EPI_CNTRY_USUAL_RESID, --2
                        CAST( null  AS varchar(2000)) AS EPI_ContactBabysitter, ----3
                        CAST( null  AS varchar(2000)) AS EPI_ContactChildcare, --4
                        CAST( null  AS varchar(2000)) AS EPI_ContactHousehold, --5
                        CAST( null  AS varchar(2000)) AS EPI_ContactOfCase, ----6
                        CAST( null  AS varchar(2000)) AS EPI_ContactOther, -----7
                        CAST( null  AS varchar(2000)) AS EPI_ContactOthSpecify, --8
                        CAST( null  AS varchar(2000)) AS EPI_ContactPlaymate, ----9
                        CAST( null  AS varchar(2000)) AS EPI_ContactSexPartner, ---10
                        CAST( null  AS varchar(2000)) AS EPI_DaycareContact, -----11
                        CAST( null  AS varchar(2000)) AS EPI_EpiLinked, ----------12
                        CAST( null  AS varchar(2000)) AS EPI_FemaleSexPartners, ------13
                        CAST( null  AS varchar(2000)) AS EPI_FoodHandler, ------14
                        CAST( null  AS varchar(2000)) AS EPI_InDayCare, ----------15
                        CAST( null  AS varchar(2000)) AS EPI_IVDrugUse, ------16
                        CAST( null  AS varchar(2000)) AS EPI_MaleSexPartner, -------17
                        --- EPI_OutbreakAssoc,	   ---OUTBREAK_IND-----18
                        CAST( null  AS varchar(2000)) AS EPI_OutbreakFoodHndlr, -------19
                        CAST( null  AS varchar(2000)) AS EPI_OutbreakFoodItem, ------20
                        CAST( null  AS varchar(2000)) AS EPI_outbreakNonFoodHndlr, -----21
                        CAST( null  AS varchar(2000)) AS EPI_OutbreakUnidentified, ----22
                        CAST( null  AS varchar(2000)) AS EPI_OutbreakWaterborne, -----23
                        CAST( null  AS varchar(2000)) AS EPI_RecDrugUse, ----24
                        CAST( null  AS varchar(2000)) AS EPI_OutbreakAssoc ----25
             ) AS temp_epidemiology_columns
                 CROSS APPLY
             ( SELECT D_INV_EPIDEMIOLOGY_KEY,
                      EPI_ChildCareCase,
                      EPI_CNTRY_USUAL_RESID,
                      EPI_ContactBabysitter,
                      EPI_ContactChildcare,
                      EPI_ContactHousehold,
                      EPI_ContactOfCase,
                      EPI_ContactOther,
                      EPI_ContactOthSpecify,
                      EPI_ContactPlaymate,
                      EPI_ContactSexPartner,
                      EPI_DaycareContact,
                      EPI_EpiLinked,
                      EPI_FemaleSexPartners,
                      EPI_FoodHandler,
                      EPI_InDayCare,
                      EPI_IVDrugUse,
                      EPI_MaleSexPartner,
                      EPI_OutbreakFoodHndlr,
                      EPI_OutbreakFoodItem,
                      EPI_outbreakNonFoodHndlr,
                      EPI_OutbreakUnidentified,
                      EPI_OutbreakWaterborne,
                      EPI_RecDrugUse,
                      EPI_OutbreakAssoc
               FROM dbo.D_INV_EPIDEMIOLOGY
             ) AS epidemiology;


        SELECT F.D_INV_EPIDEMIOLOGY_KEY as D_INV_EPIDEMIOLOGY_KEY1, F.INVESTIGATION_KEY AS EPIDEMIOLOGY_INV_KEY,
               EPI_ChildCareCase	AS	CHILDCARE_CASE_IND, ----1
               EPI_CNTRY_USUAL_RESID	AS	CNTRY_USUAL_RESIDENCE, --2
               EPI_ContactBabysitter	AS	CT_BABYSITTER_IND, ----3
               EPI_ContactChildcare	AS	CT_CHILDCARE_IND, --4
               EPI_ContactHousehold	AS	CT_HOUSEHOLD_IND, --5
               EPI_ContactOfCase	AS	HEP_CONTACT_IND, ----6
               EPI_ContactOther	AS	OTHER_CONTACT_IND, -----7
               EPI_ContactOthSpecify	AS	CONTACT_TYPE_OTH, --8
               EPI_ContactPlaymate	AS	CT_PLAYMATE_IND, ----9
               EPI_ContactSexPartner	AS	SEXUAL_PARTNER_IND, ---10
               EPI_DaycareContact	AS	DNP_HOUSEHOLD_CT_IND, -----11
               EPI_EpiLinked	AS	HEP_A_EPLINK_IND, ----------12
               EPI_FemaleSexPartners	AS	FEMALE_SEX_PRTNR_NBR, ------13
               EPI_FoodHandler	AS	FOODHNDLR_PRIOR_IND, ------14
               EPI_InDayCare	AS	DNP_EMPLOYEE_IND, ----------15
               EPI_IVDrugUse	AS	STREET_DRUG_INJECTED, ------16
               EPI_MaleSexPartner	AS	MALE_SEX_PRTNR_NBR, -------17
               --- EPI_OutbreakAssoc, ---OUTBREAK_IND-----18
               EPI_OutbreakFoodHndlr	AS	OBRK_FOODHNDLR_IND, -------19
               EPI_OutbreakFoodItem	AS	FOOD_OBRK_FOOD_ITEM, ------20
               EPI_outbreakNonFoodHndlr	AS	OBRK_NOFOODHNDLR_IND, -----21
               EPI_OutbreakUnidentified	AS	OBRK_UNIDENTIFIED_IND, ----22
               EPI_OutbreakWaterborne	AS	OBRK_WATERBORNE_IND, -----23
               EPI_RecDrugUse	AS	STREET_DRUG_USED, ----24
               EPI_OutbreakAssoc	AS	COM_SRC_OUTBREAK_IND ----25
        INTO #TMP_D_INV_EPIDEMIOLOGY
        FROM #TMP_F_INV_EPIDEMIOLOGY AS F
                 LEFT JOIN #D_EPIDEMIOLOGY_TEMP_COLS AS D WITH(NOLOCK)  ON F.D_INV_EPIDEMIOLOGY_KEY = D.D_INV_EPIDEMIOLOGY_KEY
        ORDER BY F.INVESTIGATION_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

        IF @debug = 'true' SELECT '#TMP_D_INV_EPIDEMIOLOGY', * FROM #TMP_D_INV_EPIDEMIOLOGY;

--------------------------------------------------------------------------------------8. CREATE TABLE dbo.D_INV_LAB_FINDING_TMP----------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_D_INV_LAB_FINDING';
        SET @Proc_Step_no = 8;


        IF OBJECT_ID('#TMP_F_INV_LAB_FINDING', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_F_INV_LAB_FINDING;
            END;


        IF OBJECT_ID('#TMP_D_INV_LAB_FINDING', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_D_INV_LAB_FINDING;
            END;


        SELECT F_PAGE_CASE.[D_INV_LAB_FINDING_KEY], F_PAGE_CASE.[INVESTIGATION_KEY]
        INTO #TMP_F_INV_LAB_FINDING
        FROM dbo.F_PAGE_CASE WITH(NOLOCK)
                 INNER JOIN
             #TMP_F_PAGE_CASE AS PAGE_CASE
             ON F_PAGE_CASE.INVESTIGATION_KEY = PAGE_CASE.INVESTIGATION_KEY;


        SELECT lab_finding.*
        INTO #D_INV_LAB_FINDING_TEMP_COLS
        FROM (
                 SELECT CAST( null  AS varchar(2000)) AS LAB_TotalAntiHCV, ---1
                        CAST( null  AS date) AS LAB_Supplem_antiHCV_Date, ------2
                        CAST( null  AS varchar(2000)) AS LAB_ALT_Result, ---3
                        CAST( null  AS varchar(2000)) AS LAB_AntiHBsPositive, ---4
                        CAST( null  AS varchar(2000)) AS LAB_AntiHBsTested, ----5
                        CAST( null  AS varchar(2000)) AS LAB_AST_Result, ---6
                        CAST( null  AS varchar(2000)) AS LAB_HBeAg, ---7
                        CAST( null  AS date) AS LAB_HBeAg_Date, ---8
                        CAST( null  AS varchar(2000)) AS LAB_HBsAg, --9
                        CAST( null  AS date) AS LAB_HBsAg_Date, --10
                        CAST( null  AS varchar(2000)) AS LAB_HBV_NAT, -----11
                        CAST( null  AS date) AS LAB_HBV_NAT_Date, ---12
                        CAST( null  AS varchar(2000)) AS LAB_HCVRNA, ---13
                        CAST( null  AS date) AS LAB_HCVRNA_Date, ---14
                        CAST( null  AS varchar(2000)) AS LAB_HepDTest, -----15
                        CAST( null  AS varchar(2000)) AS LAB_IgM_AntiHAV, ---16
                        CAST( null  AS date) AS LAB_IgMAntiHAVDate, ---17
                        CAST( null  AS varchar(2000)) AS LAB_IgMAntiHBc, ---18
                        CAST( null  AS date) AS LAB_IgMAntiHBcDate, ---19
                        CAST( null  AS varchar(2000)) AS LAB_PrevNegHepTest, --20
                        CAST( null  AS varchar(2000)) AS LAB_SignalToCutoff, ---21
                        CAST( null  AS varchar(2000)) AS LAB_Supplem_antiHCV, ---22
                        CAST( null  AS date) AS LAB_TestDate, -----23
                        CAST( null  AS date) AS LAB_TestDate2, ---24
                        CAST( null  AS varchar(2000)) AS LAB_TestResultUpperLimit, ---25
                        CAST( null  AS varchar(2000)) AS LAB_TestResultUpperLimit2, ---26
                        CAST( null  AS varchar(2000)) AS LAB_TotalAntiHAV, ---27
                        CAST( null  AS date) AS LAB_TotalAntiHAVDate, ---28
                        CAST( null  AS varchar(2000)) AS LAB_TotalAntiHBc, ---29
                        CAST( null  AS date) AS LAB_TotalAntiHBcDate, ----30
                        CAST( null  AS date) AS LAB_TotalAntiHCV_Date, --31
                        CAST( null  AS varchar(2000)) AS LAB_TotalAntiHDV, ---32
                        CAST( null  AS date) AS LAB_TotalAntiHDV_Date, ---33
                        CAST( null  AS varchar(2000)) AS LAB_TotalAntiHEV, ---34
                        CAST( null  AS date) AS LAB_TotalAntiHEV_Date, ---35
                        CAST( null  AS date) AS LAB_VerifiedTestDate ---36
             ) AS temp_lab_finding_columns
                 CROSS APPLY
             ( SELECT D_INV_LAB_FINDING_KEY,
                      LAB_TotalAntiHCV, ---1
                      LAB_Supplem_antiHCV_Date, ------2
                      LAB_ALT_Result, ---3
                      LAB_AntiHBsPositive, ---4
                      LAB_AntiHBsTested, ----5
                      LAB_AST_Result, ---6
                      LAB_HBeAg, ---7
                      LAB_HBeAg_Date, ---8
                      LAB_HBsAg, --9
                      LAB_HBsAg_Date, --10
                      LAB_HBV_NAT, -----11
                      LAB_HBV_NAT_Date, ---12
                      LAB_HCVRNA, ---13
                      LAB_HCVRNA_Date, ---14
                      LAB_HepDTest, -----15
                      LAB_IgM_AntiHAV, ---16
                      LAB_IgMAntiHAVDate, ---17
                      LAB_IgMAntiHBc, ---18
                      LAB_IgMAntiHBcDate, ---19
                      LAB_PrevNegHepTest, --20
                      LAB_SignalToCutoff, ---21
                      LAB_Supplem_antiHCV, ---22
                      LAB_TestDate, -----23
                      LAB_TestDate2, ---24
                      LAB_TestResultUpperLimit, ---25
                      LAB_TestResultUpperLimit2, ---26
                      LAB_TotalAntiHAV, ---27
                      LAB_TotalAntiHAVDate, ---28
                      LAB_TotalAntiHBc, ---29
                      LAB_TotalAntiHBcDate, ----30
                      LAB_TotalAntiHCV_Date, --31
                      LAB_TotalAntiHDV, ---32
                      LAB_TotalAntiHDV_Date, ---33
                      LAB_TotalAntiHEV, ---34
                      LAB_TotalAntiHEV_Date, ---35
                      LAB_VerifiedTestDate ---36
               FROM dbo.D_INV_LAB_FINDING
             ) AS lab_finding;

        IF @debug = 'true' SELECT '#D_INV_LAB_FINDING_TEMP_COLS', * FROM #D_INV_LAB_FINDING_TEMP_COLS;


        SELECT F.[D_INV_LAB_FINDING_KEY] AS D_INV_LAB_FINDING_KEY1, F.[INVESTIGATION_KEY] AS LAB_INV_KEY,
               LAB_TotalAntiHCV AS	HEP_C_TOTAL_ANTIBODY, ---1
               LAB_Supplem_antiHCV_Date	AS	SUPP_ANTI_HCV_DT, ------2
               LAB_ALT_Result	AS	ALT_SGPT_RESULT, ---3
               LAB_AntiHBsPositive AS	ANTI_HBS_POS_REAC_IND, ---4
               LAB_AntiHBsTested AS	ANTI_HBSAG_TESTED_IND, ----5
               LAB_AST_Result	AS	AST_SGOT_RESULT, ---6
               LAB_HBeAg	AS	HEP_E_ANTIGEN, ---7
               LAB_HBeAg_Date	AS	HBE_AG_DT, ---8
               LAB_HBsAg	AS	HEP_B_SURFACE_ANTIGEN, --9
               LAB_HBsAg_Date	AS	HBS_AG_DT, --10
               LAB_HBV_NAT	AS	HEP_B_DNA, -----11
               LAB_HBV_NAT_Date	AS	HBV_NAT_DT, ---12
               LAB_HCVRNA	AS	HCV_RNA, ---13
               LAB_HCVRNA_Date	AS	HCV_RNA_DT, ---14
               LAB_HepDTest	AS	HEP_D_TEST_IND, -----15
               LAB_IgM_AntiHAV	AS	HEP_A_IGM_ANTIBODY, ---16
               LAB_IgMAntiHAVDate	AS	IGM_ANTI_HAV_DT, ---17
               LAB_IgMAntiHBc	AS	HEP_B_IGM_ANTIBODY, ---18
               LAB_IgMAntiHBcDate	AS	IGM_ANTI_HBC_DT, ---19
               LAB_PrevNegHepTest	AS	PREV_NEG_HEP_TEST_IND, --20
               LAB_SignalToCutoff	AS	ANTIHCV_SIGCUT_RATIO, ---21
               LAB_Supplem_antiHCV	AS	ANTIHCV_SUPP_ASSAY, ---22
               LAB_TestDate AS	ALT_RESULT_DT, -----23
               LAB_TestDate2	AS	AST_RESULT_DT, ---24
               LAB_TestResultUpperLimit	AS	ALT_SGPT_RSLT_UP_LMT, ---25
               LAB_TestResultUpperLimit2	AS	AST_SGOT_RSLT_UP_LMT, ---26
               LAB_TotalAntiHAV	AS	HEP_A_TOTAL_ANTIBODY, ---27
               LAB_TotalAntiHAVDate	AS	TOTAL_ANTI_HAV_DT, ---28
               LAB_TotalAntiHBc	AS	HEP_B_TOTAL_ANTIBODY, ---29
               LAB_TotalAntiHBcDate	AS	TOTAL_ANTI_HBC_DT, ----30
               LAB_TotalAntiHCV_Date	AS	TOTAL_ANTI_HCV_DT, --31
               LAB_TotalAntiHDV	AS	HEP_D_TOTAL_ANTIBODY, ---32
               LAB_TotalAntiHDV_Date	AS	TOTAL_ANTI_HDV_DT, ---33
               LAB_TotalAntiHEV	AS	HEP_E_TOTAL_ANTIBODY, ---34
               LAB_TotalAntiHEV_Date	AS	TOTAL_ANTI_HEV_DT, ---35
               LAB_VerifiedTestDate 	AS	VERIFIED_TEST_DT ---36
        INTO #TMP_D_INV_LAB_FINDING
        FROM #TMP_F_INV_LAB_FINDING AS F
                 LEFT JOIN
             #D_INV_LAB_FINDING_TEMP_COLS AS D WITH(NOLOCK)
             ON F.D_INV_LAB_FINDING_KEY = D.D_INV_LAB_FINDING_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

        IF @debug = 'true' SELECT '#TMP_D_INV_LAB_FINDING', * FROM #TMP_D_INV_LAB_FINDING;


        ---------------------------------------------------------------------------------------9. CREATE TABLE TMP_D_INV_MEDICAL_HISTORY----------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_D_INV_MEDICAL_HISTORY';
        SET @Proc_Step_no = 9;

        IF OBJECT_ID('#TMP_F_INV_MEDICAL_HISTORY', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_F_INV_MEDICAL_HISTORY;
            END;

        IF OBJECT_ID('#TMP_D_INV_MEDICAL_HISTORY', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_D_INV_MEDICAL_HISTORY;
            END;

        SELECT F_PAGE_CASE.D_INV_MEDICAL_HISTORY_KEY, F_PAGE_CASE.[INVESTIGATION_KEY]
        INTO #TMP_F_INV_MEDICAL_HISTORY
        FROM dbo.F_PAGE_CASE WITH(NOLOCK)
                 INNER JOIN	 #TMP_F_PAGE_CASE AS PAGE_CASE  ON F_PAGE_CASE.INVESTIGATION_KEY = PAGE_CASE.INVESTIGATION_KEY---(my table)
        ORDER BY D_INV_MEDICAL_HISTORY_KEY;

        SELECT med_history.*
        INTO #D_INV_MED_HIST_TEMP_COLS
        FROM (
                 SELECT CAST( NULL  AS date) AS MDH_DiabetesDxDate,
                        NULL AS MDH_Diabetes,
                        NULL AS MDH_Jaundiced,
                        NULL AS MDH_PrevAwareInfection,
                        NULL AS MDH_ProviderOfCare,
                        NULL AS MDH_ReasonForTest,
                        NULL AS MDH_ReasonForTestingOth,
                        NULL AS MDH_Symptomatic,
                        CAST( NULL  AS date) AS MDH_DueDate
             ) AS temp_med_history_columns
                 CROSS APPLY
             ( SELECT D_INV_MEDICAL_HISTORY_KEY,
                      MDH_DiabetesDxDate,
                      MDH_Diabetes,
                      MDH_Jaundiced,
                      MDH_PrevAwareInfection,
                      MDH_ProviderOfCare,
                      MDH_ReasonForTest,
                      MDH_ReasonForTestingOth,
                      MDH_Symptomatic,
                      MDH_DueDate
               FROM dbo.D_INV_MEDICAL_HISTORY
             ) AS med_history;


        SELECT F.D_INV_MEDICAL_HISTORY_KEY, F.INVESTIGATION_KEY AS MEDHistory_INV_KEY,
               CAST(MDH_DiabetesDxDate AS date) AS DIABETES_DX_DT,
               CAST(MDH_Diabetes AS [varchar](300)) AS DIABETES_IND,
               CAST(MDH_Jaundiced AS [varchar](300)) AS PAT_JUNDICED_IND,
               CAST(MDH_PrevAwareInfection AS [varchar](300)) AS PAT_PREV_AWARE_IND,
               CAST(MDH_ProviderOfCare AS [varchar](300)) AS HEP_CARE_PROVIDER,
               CAST(MDH_ReasonForTest AS [varchar](300)) AS TEST_REASON,
               CAST(MDH_ReasonForTestingOth AS [varchar](300)) AS TEST_REASON_OTH,
               CAST(MDH_Symptomatic AS [varchar](300)) AS SYMPTOMATIC_IND,
               CAST(MDH_DueDate AS date) AS PREGNANCY_DUE_DT
        INTO #TMP_D_INV_MEDICAL_HISTORY
        FROM #TMP_F_INV_MEDICAL_HISTORY AS F
                 LEFT JOIN	#D_INV_MED_HIST_TEMP_COLS AS D WITH(NOLOCK)  ON F.D_INV_MEDICAL_HISTORY_KEY = D.D_INV_MEDICAL_HISTORY_KEY
        ORDER BY F.INVESTIGATION_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;


        ---------------------------------------------------------------------------------10. CREATE TABLE TMP.D_INV_MOTHER-------------------------------------------------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_D_INV_MOTHER';
        SET @Proc_Step_no = 10;

        IF OBJECT_ID('#TMP_F_INV_MOTHER', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_F_INV_MOTHER;
            END;

        IF OBJECT_ID('#TMP_D_INV_MOTHER', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_D_INV_MOTHER;
            END;


        SELECT F_PAGE_CASE.D_INV_MOTHER_KEY, F_PAGE_CASE.INVESTIGATION_KEY
        INTO #TMP_F_INV_MOTHER
        FROM dbo.F_PAGE_CASE WITH(NOLOCK)
                 INNER JOIN
             #TMP_F_PAGE_CASE AS PAGE_CASE
             ON F_PAGE_CASE.INVESTIGATION_KEY = PAGE_CASE.INVESTIGATION_KEY---(my table)
        ORDER BY D_INV_MOTHER_KEY;

        SELECT mother.*
        INTO #D_INV_MOTHER_TEMP_COLS
        FROM (
                 SELECT NULL AS MTH_MotherBornOutsideUS,
                        NULL AS MTH_MotherEthnicity,
                        NULL AS MTH_MotherHBsAgPosPrior,
                        NULL AS MTH_MotherPositiveAfter,
                        NULL AS MTH_MotherRace,
                        NULL AS MTH_MothersBirthCountry,
                        CAST( NULL  AS date) AS MTH_MotherPosTestDate
             ) AS temp_med_mother_columns
                 CROSS APPLY
             ( SELECT D_INV_MOTHER_KEY,
                      MTH_MotherBornOutsideUS,
                      MTH_MotherEthnicity,
                      MTH_MotherHBsAgPosPrior,
                      MTH_MotherPositiveAfter,
                      MTH_MotherRace,
                      MTH_MothersBirthCountry,
                      MTH_MotherPosTestDate
               FROM dbo.D_INV_MOTHER
             ) AS mother;


        SELECT F.D_INV_MOTHER_KEY D_INV_MOTHER_KEY1, F.INVESTIGATION_KEY AS MOTHER_INV_KEY,
               RTRIM(LTRIM(MTH_MotherBornOutsideUS))	AS	MTH_BORN_OUTSIDE_US,
               RTRIM(LTRIM(MTH_MotherEthnicity))	AS	MTH_ETHNICITY,
               RTRIM(LTRIM(MTH_MotherHBsAgPosPrior))	AS	MTH_HBS_AG_PRIOR_POS,
               RTRIM(LTRIM(MTH_MotherPositiveAfter))	AS	MTH_POS_AFTER,
               RTRIM(LTRIM(MTH_MotherRace))	AS	MTH_RACE,
               RTRIM(LTRIM(MTH_MothersBirthCountry))	AS	MTH_BIRTH_COUNTRY,
               RTRIM(LTRIM(MTH_MotherPosTestDate))	AS	MTH_POS_TEST_DT
        INTO #TMP_D_INV_MOTHER
        FROM #TMP_F_INV_MOTHER AS F
                 LEFT JOIN	#D_INV_MOTHER_TEMP_COLS AS D WITH(NOLOCK)  ON F.D_INV_MOTHER_KEY = D.D_INV_MOTHER_KEY
        ORDER BY F.INVESTIGATION_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

----------------------------------------------------------------------------------11. CREATE TABLE TMP_D_INV_RISK_FACTOR---------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_D_INV_RISK_FACTOR';

        SET @Proc_Step_no = 11;

        IF OBJECT_ID('#TMP_F_INV_RISK_FACTOR', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_F_INV_RISK_FACTOR;
            END;

        IF OBJECT_ID('#TMP_D_INV_RISK_FACTOR', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_D_INV_RISK_FACTOR;
            END;

        SELECT F_PAGE_CASE.D_INV_RISK_FACTOR_KEY, F_PAGE_CASE.INVESTIGATION_KEY
        INTO #TMP_F_INV_RISK_FACTOR
        FROM dbo.F_PAGE_CASE WITH(NOLOCK)
                 INNER JOIN
             #TMP_F_PAGE_CASE AS PAGE_CASE  ON F_PAGE_CASE.INVESTIGATION_KEY = PAGE_CASE.INVESTIGATION_KEY	---(my table)
        ORDER BY D_INV_RISK_FACTOR_KEY;


        SELECT risk.*
        INTO #D_INV_RISK_FACT_TEMP_COLS
        FROM (
                 SELECT CAST( null AS varchar(300)) AS RSK_BloodExpOther, ---1
                        CAST( NULL  AS varchar(1000)) AS RSK_BloodTransfusion, ----2
                        CAST( null  AS date) AS RSK_BloodTransfusionDate, ---3
                        CAST( NULL  AS varchar(1000)) AS RSK_BloodWorkerCnctFreq, ---4
                        CAST( NULL  AS varchar(1000)) AS RSK_BloodWorkerEver, ---5
                        CAST( NULL  AS varchar(1000)) AS RSK_BloodWorkerOnset, ---6
                        CAST( NULL  AS varchar(1000)) AS RSK_ClottingPrior87, ----7
                        CAST( NULL  AS varchar(1000)) AS RSK_ContaminatedStick, ----8
                        CAST( NULL  AS varchar(1000)) AS RSK_DentalOralSx, ----9
                        CAST( NULL  AS varchar(1000)) AS RSK_HEMODIALYSIS_BEFORE_ONSET, --10
                        CAST( NULL  AS varchar(1000)) AS RSK_HemodialysisLongTerm, --11
                        CAST( NULL  AS varchar(1000)) AS RSK_HospitalizedPrior, --12
                        CAST( NULL  AS varchar(1000)) AS RSK_IDU, ------13
                        CAST( NULL  AS varchar(1000)) AS RSK_Incarcerated24Hrs, ---14
                        CAST( NULL  AS varchar(1000)) AS RSK_Incarcerated6months, ----15
                        CAST( NULL  AS varchar(1000)) AS RSK_IncarceratedEver, ---16
                        CAST( NULL  AS varchar(1000)) AS RSK_IncarceratedJail, -- -17
                        CAST( NULL  AS varchar(1000)) AS RSK_IncarcerationPrison, ---18
                        CAST( NULL  AS varchar(1000)) AS RSK_IncarcJuvenileFacilit, ---19
                        CAST( NULL  AS varchar(1000)) AS RSK_IncarcTimeMonths, ------20
                        CAST( NULL  AS varchar(1000)) AS RSK_IncarcYear6Mos, ---21
                        CAST( NULL  AS varchar(1000)) AS RSK_IVInjectInfuseOutpt, ---22
                        CAST( NULL  AS varchar(1000)) AS RSK_LongTermCareRes, ---23
                        CAST( NULL  AS varchar(1000)) AS RSK_NumSexPrtners, ---24
                        CAST( NULL  AS varchar(1000)) AS RSK_OtherBldExpSpec, ---25
                        CAST( NULL  AS varchar(1000)) AS RSK_Piercing, ---26
                        CAST( NULL  AS varchar(1000)) AS RSK_PiercingOthLocSpec, ----27
                        CAST( NULL  AS varchar(1000)) AS RSK_PiercingRcvdFrom, -------28
                        CAST( NULL  AS varchar(1000)) AS RSK_PSWrkrBldCnctFreq, ---29
                        CAST( NULL  AS varchar(1000)) AS RSK_PublicSafetyWorker, ---30
                        CAST( NULL  AS varchar(1000)) AS RSK_STDTxEver, ---31
                        CAST( NULL  AS varchar(1000)) AS RSK_STDTxYr, ---32
                        CAST( NULL  AS varchar(1000)) AS RSK_SurgeryOther, -----33
                        CAST( NULL  AS varchar(1000)) AS RSK_Tattoo, ----34
                        CAST( NULL  AS varchar(1000)) AS RSK_TattooLocation, ----35
                        CAST( NULL  AS varchar(1000)) AS RSK_TattooLocOthSpec, ---36
                        CAST( NULL  AS varchar(1000)) AS RSK_TransfusionPrior92, ---37
                        CAST( NULL  AS varchar(1000)) AS RSK_TransplantPrior92, ---38
                        CAST( NULL  AS varchar(1000)) AS RSK_HepContactEver     ----39
             ) AS temp_risk_columns
                 CROSS APPLY
             ( SELECT D_INV_RISK_FACTOR_KEY,
                      RSK_BloodExpOther,
                      RSK_BloodTransfusion,
                      RSK_BloodTransfusionDate,
                      RSK_BloodWorkerCnctFreq,
                      RSK_BloodWorkerEver,
                      RSK_BloodWorkerOnset,
                      RSK_ClottingPrior87,
                      RSK_ContaminatedStick,
                      RSK_DentalOralSx,
                      RSK_HEMODIALYSIS_BEFORE_ONSET,
                      RSK_HemodialysisLongTerm,
                      RSK_HospitalizedPrior,
                      RSK_IDU,
                      RSK_Incarcerated24Hrs,
                      RSK_Incarcerated6months,
                      RSK_IncarceratedEver,
                      RSK_IncarceratedJail,
                      RSK_IncarcerationPrison,
                      RSK_IncarcJuvenileFacilit,
                      RSK_IncarcTimeMonths,
                      RSK_IncarcYear6Mos,
                      RSK_IVInjectInfuseOutpt,
                      RSK_LongTermCareRes,
                      RSK_NumSexPrtners,
                      RSK_OtherBldExpSpec,
                      RSK_Piercing,
                      RSK_PiercingOthLocSpec,
                      RSK_PiercingRcvdFrom,
                      RSK_PSWrkrBldCnctFreq,
                      RSK_PublicSafetyWorker,
                      RSK_STDTxEver,
                      RSK_STDTxYr,
                      RSK_SurgeryOther,
                      RSK_Tattoo,
                      RSK_TattooLocation,
                      RSK_TattooLocOthSpec,
                      RSK_TransfusionPrior92,
                      RSK_TransplantPrior92,
                      RSK_HepContactEver
               FROM dbo.D_INV_RISK_FACTOR
             ) AS risk;


        SELECT F.D_INV_RISK_FACTOR_KEY D_INV_RISK_FACTOR_KEY1, F.INVESTIGATION_KEY AS RISK_INV_KEY,
               RTRIM(LTRIM(RSK_BloodExpOther))	AS	BLD_EXPOSURE_IND, ---1
               RTRIM(LTRIM(RSK_BloodTransfusion))	AS	BLD_RECVD_IND, ----2
               RSK_BloodTransfusionDate	AS	BLD_RECVD_DT, ---3
               RTRIM(LTRIM(RSK_BloodWorkerCnctFreq))	AS	MED_DEN_BLD_CT_FRQ, ---4
               RTRIM(LTRIM(RSK_BloodWorkerEver))	AS	MED_DEN_EMP_EVER_IND, ---5
               RTRIM(LTRIM(RSK_BloodWorkerOnset))	AS	MED_DEN_EMPLOYEE_IND, ---6
               RTRIM(LTRIM(RSK_ClottingPrior87))	AS	CLOTFACTOR_PRIOR_1987, ----7
               RTRIM(LTRIM(RSK_ContaminatedStick))	AS	BLD_CONTAM_IND, ----8
               RTRIM(LTRIM(RSK_DentalOralSx))	AS	DEN_WORK_OR_SURG_IND, ----9
               RTRIM(LTRIM(RSK_HEMODIALYSIS_BEFORE_ONSET))	AS	HEMODIALYSIS_IND, --10
               RTRIM(LTRIM(RSK_HemodialysisLongTerm))	AS	LT_HEMODIALYSIS_IND, --11
               RTRIM(LTRIM(RSK_HospitalizedPrior))	AS	HSPTL_PRIOR_ONSET_IND, --12
               RTRIM(LTRIM(RSK_IDU))	AS	EVER_INJCT_NOPRSC_DRG, ------13
               RTRIM(LTRIM(RSK_Incarcerated24Hrs))	AS	INCAR_24PLUSHRS_IND, ---14
               RTRIM(LTRIM(RSK_Incarcerated6months))	AS	INCAR_6PLUS_MO_IND, ----15
               RTRIM(LTRIM(RSK_IncarceratedEver))	AS	EVER_INCAR_IND, ---16
               RTRIM(LTRIM(RSK_IncarceratedJail))	AS	INCAR_TYPE_JAIL_IND, -- -17
               RTRIM(LTRIM(RSK_IncarcerationPrison))	AS	INCAR_TYPE_PRISON_IND, ---18
               RTRIM(LTRIM(RSK_IncarcJuvenileFacilit))	AS	INCAR_TYPE_JUV_IND, ---19
               RTRIM(LTRIM(RSK_IncarcTimeMonths))	AS	LAST6PLUSMO_INCAR_PER, ------20
               RTRIM(LTRIM(RSK_IncarcYear6Mos))	AS	LAST6PLUSMO_INCAR_YR, ---21
               RTRIM(LTRIM(RSK_IVInjectInfuseOutpt))	AS	OUTPAT_IV_INF_IND, ---22
               RTRIM(LTRIM(RSK_LongTermCareRes))	AS	LTCARE_RESIDENT_IND, ---23
               RTRIM(LTRIM(RSK_NumSexPrtners))	AS	LIFE_SEX_PRTNR_NBR, ---24
               RTRIM(LTRIM(RSK_OtherBldExpSpec))	AS	BLD_EXPOSURE_OTH, ---25
               RTRIM(LTRIM(RSK_Piercing))	AS	PIERC_PRIOR_ONSET_IND, ---26
               RTRIM(LTRIM(RSK_PiercingOthLocSpec))	AS	PIERC_PERF_LOC_OTH, ----27
               RTRIM(LTRIM(RSK_PiercingRcvdFrom))	AS	PIERC_PERF_LOC, -------28
               RTRIM(LTRIM(RSK_PSWrkrBldCnctFreq))	AS	PUB_SAFETY_BLD_CT_FRQ, ---29
               RTRIM(LTRIM(RSK_PublicSafetyWorker))	AS	PUB_SAFETY_WORKER_IND, ---30
               RTRIM(LTRIM(RSK_STDTxEver))	AS	STD_TREATED_IND, ---31
               RTRIM(LTRIM(RSK_STDTxYr))	AS	STD_LAST_TREATMENT_YR, ---32
               RTRIM(LTRIM(RSK_SurgeryOther))	AS	NON_ORAL_SURGERY_IND, -----33
               RTRIM(LTRIM(RSK_Tattoo))	AS	TATT_PRIOR_ONSET_IND, ----34
               RTRIM(LTRIM(RSK_TattooLocation))	AS	TATTOO_PERF_LOC, ----35
               RTRIM(LTRIM(RSK_TattooLocOthSpec))	AS	TATT_PRIOR_LOC_OTH, ---36
               RTRIM(LTRIM(RSK_TransfusionPrior92))	AS	BLD_TRANSF_PRIOR_1992, ---37
               RTRIM(LTRIM(RSK_TransplantPrior92))	AS	ORGN_TRNSP_PRIOR_1992, ---38
               RTRIM(LTRIM(RSK_HepContactEver))	AS	HEP_CONTACT_EVER_IND ----39
        INTO #TMP_D_INV_RISK_FACTOR
        FROM #TMP_F_INV_RISK_FACTOR AS F
                 LEFT JOIN
             #D_INV_RISK_FACT_TEMP_COLS AS D WITH(NOLOCK)  ON F.D_INV_RISK_FACTOR_KEY = D.D_INV_RISK_FACTOR_KEY
        ORDER BY RISK_INV_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

---------------------------------------------------12. CREATE TABLE #TMP_D_INV_TRAVEL---------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating #TMP_D_INV_TRAVEL';
        SET @Proc_Step_no = 12;

        IF OBJECT_ID('#TMP_F_INV_TRAVEL', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_F_INV_TRAVEL;
            END;

        IF OBJECT_ID('#TMP_D_INV_TRAVEL', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_D_INV_TRAVEL;
            END;


        SELECT F_PAGE_CASE.D_INV_TRAVEL_KEY, F_PAGE_CASE.INVESTIGATION_KEY
        INTO #TMP_F_INV_TRAVEL
        FROM dbo.F_PAGE_CASE WITH(NOLOCK)
                 INNER JOIN
             #TMP_F_PAGE_CASE AS PAGE_CASE
             ON F_PAGE_CASE.INVESTIGATION_KEY = PAGE_CASE.INVESTIGATION_KEY---(my table)
        ORDER BY D_INV_TRAVEL_KEY;


        SELECT travel.*
        INTO #D_INV_TRAVEL_TEMP_COLS
        FROM (
                 SELECT CAST( NULL  AS varchar(1000)) AS TRV_HouseholdTravel,
                        CAST( NULL  AS varchar(1000)) AS TRV_PatientTravel,
                        CAST( NULL  AS varchar(1000)) AS TRV_PtTravelCountries,
                        CAST( NULL  AS varchar(1000)) AS TRV_TravelCountryHouse,
                        CAST( NULL  AS varchar(1000)) AS TRV_VHF_TRAVEL_REASON
             ) AS temp_travel_columns
                 CROSS APPLY
             ( SELECT D_INV_TRAVEL_KEY,
                      TRV_HouseholdTravel,
                      TRV_PatientTravel,
                      TRV_PtTravelCountries,
                      TRV_TravelCountryHouse,
                      TRV_VHF_TRAVEL_REASON
               FROM dbo.D_INV_TRAVEL
             ) AS travel;


        SELECT F.D_INV_TRAVEL_KEY D_INV_TRAVEL_KEY1, F.INVESTIGATION_KEY AS Travel_INV_KEY,
               RTRIM(LTRIM(TRV_HouseholdTravel)) AS HOUSEHOLD_TRAVEL_IND,
               RTRIM(LTRIM(TRV_PatientTravel)) AS TRAVEL_OUT_USACAN_IND,
               RTRIM(LTRIM(TRV_PtTravelCountries)) AS TRAVEL_OUT_USACAN_LOC,
               RTRIM(LTRIM(TRV_TravelCountryHouse)) AS HOUSEHOLD_TRAVEL_LOC,
               RTRIM(LTRIM(TRV_VHF_TRAVEL_REASON)) AS TRAVEL_REASON
        INTO #TMP_D_INV_TRAVEL
        FROM #TMP_F_INV_TRAVEL AS F
                 LEFT JOIN
             #D_INV_TRAVEL_TEMP_COLS AS D WITH(NOLOCK)
             ON F.D_INV_TRAVEL_KEY = D.D_INV_TRAVEL_KEY
        ORDER BY F.INVESTIGATION_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;


        -------------------------------------------------------------------13. CREATE TABLE TMP_D_INV_VACCINATION--------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  TMP_D_INV_VACCINATION';
        SET @Proc_Step_no = 13;

        IF OBJECT_ID('#TMP_F_INV_VACCINATION', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_F_INV_VACCINATION;
            END;

        IF OBJECT_ID('#TMP_D_INV_VACCINATION', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_D_INV_VACCINATION;
            END;

        SELECT F_PAGE_CASE.D_INV_VACCINATION_KEY, F_PAGE_CASE.INVESTIGATION_KEY
        INTO #TMP_F_INV_VACCINATION
        FROM dbo.F_PAGE_CASE WITH(NOLOCK)
                 INNER JOIN
             #TMP_F_PAGE_CASE AS PAGE_CASE
             ON F_PAGE_CASE.INVESTIGATION_KEY = PAGE_CASE.INVESTIGATION_KEY	---(my table)
        ORDER BY D_INV_VACCINATION_KEY;

        SELECT vacc.*
        INTO #D_INV_VACCINATION_TEMP_COLS
        FROM (
                 SELECT CAST( NULL  AS varchar(1000)) AS VAC_ImmuneGlobulin,
                        CAST( NULL  AS varchar(1000)) AS RSK_STDTxYr,
                        CAST( NULL  AS varchar(1000)) AS VAC_LastIGDose,
                        CAST( NULL  AS varchar(1000)) AS VAC_Vacc_Rcvd,
                        CAST( NULL  AS varchar(1000)) AS VAC_VaccineDoses,
                        CAST( NULL  AS varchar(1000)) AS VAC_YearofLastDose,
                        CAST( NULL  AS date) AS VAC_VaccinationDate
             ) AS temp_vaccination_columns
                 CROSS APPLY
             ( SELECT D_INV_VACCINATION_KEY,
                      VAC_ImmuneGlobulin,
                      RSK_STDTxYr,
                      VAC_LastIGDose,
                      VAC_Vacc_Rcvd,
                      VAC_VaccineDoses,
                      VAC_YearofLastDose,
                      VAC_VaccinationDate
               FROM dbo.D_INV_VACCINATION
             ) AS vacc;


        SELECT F.D_INV_VACCINATION_KEY D_INV_VACCINATION_KEY1, F.INVESTIGATION_KEY AS VACCINATION_INV_KEY,
               VAC_ImmuneGlobulin AS IMM_GLOB_RECVD_IND, ----EXT_IMM_GLOB_RECVD_IND,
               RSK_STDTxYr AS STD_LAST_TREATMENT_YR, -----EXT_STD_LAST_TREATMENT_YR,
               VAC_LastIGDose AS GLOB_LAST_RECVD_YR, -----EXT_GLOB_LAST_RECVD_YR,
               VAC_Vacc_Rcvd AS VACC_RECVD_IND, ---- ---EXT_VACC_RECVD_IND--------------5-13-2021
               VAC_VaccineDoses AS VACC_DOSE_RECVD_NBR, ---EXT_VACC_DOSE_RECVD_NBR,-----INPUT(VAC_VaccineDoses, comma20.);
               VAC_YearofLastDose AS VACC_LAST_RECVD_YR, -----EXT_VACC_LAST_RECVD_YR,-------INPUT(VAC_YearofLastDose, comma20.);
               VAC_VaccinationDate  ---EXT_VACC_RECVD_DT,------------VAC_VaccinationDate---could not find
        INTO #TMP_D_INV_VACCINATION
        FROM #TMP_F_INV_VACCINATION AS F
                 LEFT JOIN
             #D_INV_VACCINATION_TEMP_COLS AS V WITH(NOLOCK)
             ON F.D_INV_VACCINATION_KEY = V.D_INV_VACCINATION_KEY
        ORDER BY F.INVESTIGATION_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

----------------------------------------------------------14. CREATE TABLE #TMP_D_Patient---------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_D_Patient';

        SET @Proc_Step_no = 14;

        IF OBJECT_ID('#TMP_D_Patient', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_D_Patient;
            END;

        SELECT F_PAGE_CASE.INVESTIGATION_KEY AS Patient_INV_KEY, D_PATIENT.PATIENT_UID, D_PATIENT.PATIENT_ETHNICITY AS PAT_ETHNICITY, D_PATIENT.PATIENT_AGE_REPORTED AS PAT_REPORTED_AGE, D_PATIENT.PATIENT_AGE_REPORTED_UNIT AS PAT_REPORTED_AGE_UNIT, D_PATIENT.PATIENT_CITY AS PAT_CITY, D_PATIENT.PATIENT_COUNTRY AS PAT_COUNTRY, D_PATIENT.PATIENT_BIRTH_COUNTRY AS PAT_BIRTH_COUNTRY, D_PATIENT.PATIENT_COUNTY AS PAT_COUNTY, D_PATIENT.PATIENT_CURRENT_SEX AS PAT_CURR_GENDER, D_PATIENT.PATIENT_DOB AS PAT_DOB, D_PATIENT.PATIENT_FIRST_NAME AS PAT_FIRST_NM, D_PATIENT.PATIENT_LAST_NAME AS PAT_LAST_NM, SUBSTRING(LTRIM(RTRIM(D_PATIENT.PATIENT_LOCAL_ID)), 1, 25) AS PAT_LOCAL_ID, ---added 9/9/2021
               D_PATIENT.PATIENT_MIDDLE_NAME AS PAT_MIDDLE_NM, D_PATIENT.PATIENT_RACE_CALCULATED AS PAT_RACE, D_PATIENT.PATIENT_STATE AS PAT_STATE, D_PATIENT.PATIENT_STREET_ADDRESS_1 AS PAT_STREET_ADDR_1, D_PATIENT.PATIENT_STREET_ADDRESS_2 AS PAT_STREET_ADDR_2, SUBSTRING(LTRIM(RTRIM(D_PATIENT.PATIENT_ZIP)), 1, 10) AS PAT_ZIP_CODE, ---added 9/9/2021
               D_PATIENT.PATIENT_ENTRY_METHOD AS PAT_ELECTRONIC_IND, D_PATIENT.PATIENT_ADD_TIME AS INV_ADD_TIME
        INTO #TMP_D_Patient
        ----FROM F_PAGE_CASE
        FROM #TMP_F_PAGE_CASE AS F_PAGE_CASE---(my table)
                 INNER JOIN
             #TMP_CONDITION AS T
             ON F_PAGE_CASE.CONDITION_KEY = T.CONDITION_KEY---(my table)
                 INNER JOIN
             dbo.D_PATIENT WITH(NOLOCK)
             ON D_PATIENT.PATIENT_KEY = F_PAGE_CASE.PATIENT_KEY
        ORDER BY INVESTIGATION_KEY;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

---------------------------------------------------15. CREATE TABLE TMP_INVESTIGATION---------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_Investigation';
        SET @Proc_Step_no = 15;

        IF OBJECT_ID('#TMP_Investigation', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_Investigation;

            END;

        SELECT PAGE_CASE.INVESTIGATION_KEY, INVESTIGATION.CASE_UID, T.CONDITION_CD AS CONDITION_CD, INVESTIGATION.CASE_OID AS PROGRAM_JURISDICTION_OID, CAST([CASE_RPT_MMWR_WK] AS varchar(100)) AS CASE_RPT_MMWR_WEEK, CAST([CASE_RPT_MMWR_YR] AS varchar(100)) AS CASE_RPT_MMWR_YEAR, INVESTIGATION.DIAGNOSIS_DT AS DIAGNOSIS_DT, INVESTIGATION.DIE_FRM_THIS_ILLNESS_IND AS DIE_FRM_THIS_ILLNESS_IND, INVESTIGATION.DISEASE_IMPORTED_IND AS DISEASE_IMPORTED_IND, INVESTIGATION.EARLIEST_RPT_TO_CNTY_DT AS EARLIEST_RPT_TO_CNTY, INVESTIGATION.EARLIEST_RPT_TO_STATE_DT AS EARLIEST_RPT_TO_STATE_DT,
               INVESTIGATION.HSPTL_ADMISSION_DT AS HSPTL_ADMISSION_DT, INVESTIGATION.HSPTL_DISCHARGE_DT AS HSPTL_DISCHARGE_DT,
               INVESTIGATION.HSPTL_DURATION_DAYS AS HSPTL_DURATION_DAYS, INVESTIGATION.HSPTLIZD_IND AS HSPTLIZD_IND, INVESTIGATION.ILLNESS_ONSET_DT AS ILLNESS_ONSET_DT, INVESTIGATION.IMPORT_FRM_CITY AS IMPORT_FROM_CITY, INVESTIGATION.IMPORT_FRM_CNTRY AS IMPORT_FROM_COUNTRY, INVESTIGATION.IMPORT_FRM_CNTY AS IMPORT_FROM_COUNTY, INVESTIGATION.IMPORT_FRM_STATE AS IMPORT_FROM_STATE, INVESTIGATION.INV_CASE_STATUS AS INV_CASE_STATUS, LTRIM(RTRIM(INVESTIGATION.INV_COMMENTS)) AS INV_COMMENTS, ---added 7/21/2021
               INVESTIGATION.INV_LOCAL_ID AS INV_LOCAL_ID, INVESTIGATION.INV_RPT_DT AS INV_RPT_DT, INVESTIGATION.INV_START_DT AS INV_START_DT,
               ----	INVESTIGATION.INVESTIGATION_KEY	AS 	INVESTIGATION_KEY,
               INVESTIGATION.INVESTIGATION_STATUS AS INVESTIGATION_STATUS, INVESTIGATION.JURISDICTION_NM AS JURISDICTION_NM, INVESTIGATION.OUTBREAK_IND AS OUTBREAK_IND, INVESTIGATION.PATIENT_PREGNANT_IND AS PAT_PREGNANT_IND, INVESTIGATION.RPT_SRC_CD_DESC AS RPT_SRC_CD_DESC, INVESTIGATION.TRANSMISSION_MODE AS TRANSMISSION_MODE, SUBSTRING(LTRIM(RTRIM(INVESTIGATION.LEGACY_CASE_ID)), 1, 15) AS LEGACY_CASE_ID, ----added on 9/8/2021
               DATE_MM_DD_YYYY AS NOT_SUBMIT_DT
        INTO #TMP_Investigation
        FROM dbo.F_PAGE_CASE AS PAGE_CASE WITH(NOLOCK)---(original table)
                 INNER JOIN  #TMP_F_PAGE_CASE AS F_PAGE_CASE  ON F_PAGE_CASE.INVESTIGATION_KEY = PAGE_CASE.INVESTIGATION_KEY--(myTable)
                 INNER JOIN	 #TMP_CONDITION AS T		 ON F_PAGE_CASE.CONDITION_KEY = T.CONDITION_KEY---(my table)
                 INNER JOIN	 dbo.D_PATIENT WITH(NOLOCK)	 ON F_PAGE_CASE.patient_key = D_PATIENT.patient_key
                 INNER JOIN	 dbo.INVESTIGATION WITH(NOLOCK)	 ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY
                 LEFT OUTER JOIN	 dbo.NOTIFICATION_EVENT WITH(NOLOCK) 	 ON NOTIFICATION_EVENT.PATIENT_KEY = F_PAGE_CASE.PATIENT_KEY
                 LEFT OUTER JOIN	 dbo.RDB_DATE WITH(NOLOCK)		 ON NOTIFICATION_EVENT.NOTIFICATION_SUBMIT_DT_KEY = DATE_KEY
        ORDER BY PAGE_CASE.INVESTIGATION_key;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_Notif and #TMP_Event';
        SET @Proc_Step_no = 16;

        IF OBJECT_ID('#TMP_Notif', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_Notif;
            END;

        IF OBJECT_ID('#TMP_Event', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_Event;
            END;

        /*Solution to update columns referenced from CASE_LAB_DATAMART and INV_SUMMARY_DATAMART. This be refactor once they are hydrated by RTR.
         * INIT_NND_NOT_DT is rpt_sent_time from Notification. Data is pulled from NRT tables to reference original value. */

        SELECT I.INVESTIGATION_KEY
             ,MIN(notif.rpt_sent_time) AS FIRSTNOTIFICATIONSENDDATE
        INTO #TMP_Notif
        FROM #TMP_Investigation AS I WITH(NOLOCK)
                 LEFT JOIN dbo.NOTIFICATION_EVENT NE WITH(NOLOCK) ON NE.INVESTIGATION_KEY = I.INVESTIGATION_KEY
                 LEFT JOIN dbo.nrt_notification_key NK WITH(NOLOCK)	ON NE.NOTIFICATION_KEY = NK.d_notification_key
                 LEFT JOIN dbo.nrt_investigation_notification notif WITH(NOLOCK) ON notif.notification_uid= NK.notification_uid
        WHERE notif.NOTIF_STATUS = 'COMPLETED' and notif.RPT_SENT_TIME IS NOT NULL
        GROUP BY I.INVESTIGATION_KEY
        ORDER BY I.INVESTIGATION_KEY;


        if @debug = 'true' select 'TMP_Notif', * from #TMP_Notif;


        --Temporary table for Event Date.

        SELECT I.INVESTIGATION_KEY
             ,COALESCE(MAX(no2.effective_from_time),cast( null as datetime)) AS SPECIMEN_COLLECTION_DT
             ,COALESCE(MIN(notif.notif_add_time),cast( null as datetime)) AS INV_ADD_TIME
             ,COALESCE(MIN(n_inv.add_time),cast( null as datetime)) AS INVESTIGATION_CREATE_DATE
             ,COALESCE(MIN(CMG.[CONFIRMATION_DT]),cast( null as datetime)) AS CONFIRMATION_DT
             ,COALESCE(MIN(I.ILLNESS_ONSET_DT),cast( null as datetime)) AS ILLNESS_ONSET_DT
             ,COALESCE(MAX(I.DIAGNOSIS_DT),cast( null as datetime)) AS DIAGNOSIS_DT
             ,COALESCE(MIN(I.EARLIEST_RPT_TO_STATE_DT),cast( null as datetime)) AS EARLIEST_RPT_TO_STATE_DT
             ,COALESCE(MIN(I.EARLIEST_RPT_TO_CNTY),cast( null as datetime)) AS EARLIEST_RPT_TO_CNTY
             ,COALESCE(MIN(I.INV_RPT_DT),cast( null as datetime)) AS INV_RPT_DT
             ,COALESCE(MIN(I.INV_START_DT),cast( null as datetime)) AS INV_START_DT
             ,COALESCE(MIN(I.HSPTL_ADMISSION_DT),cast( null as datetime)) AS HSPTL_ADMISSION_DT
             ,COALESCE(MIN(I.HSPTL_DISCHARGE_DT),cast( null as datetime)) AS HSPTL_DISCHARGE_DT
             ,cast( null as datetime) as EVENT_DATE
             ,cast( null as varchar(200)) as EVENT_DATE_TYPE
        INTO #TMP_Event
        FROM #TMP_Investigation AS I WITH(NOLOCK)
                 LEFT JOIN dbo.CONFIRMATION_METHOD_GROUP CMG WITH(NOLOCK) ON CMG.INVESTIGATION_KEY = I.INVESTIGATION_KEY
                 LEFT JOIN dbo.NOTIFICATION_EVENT NE WITH(NOLOCK) ON NE.INVESTIGATION_KEY = I.INVESTIGATION_KEY
                 LEFT JOIN
             (SELECT DISTINCT public_health_case_uid, observation_id
              FROM dbo.nrt_investigation_observation with (nolock)
             ) NIO ON nio.public_health_case_uid = i.case_uid
                 LEFT JOIN dbo.nrt_observation no2 WITH(NOLOCK) ON nio.observation_id = no2.observation_uid
                 LEFT JOIN dbo.nrt_notification_key nk WITH(NOLOCK)ON NE.notification_key = nk.d_notification_key
                 LEFT JOIN dbo.nrt_investigation_notification notif WITH(NOLOCK) ON notif.notification_uid= NK.notification_uid
                 LEFT JOIN dbo.nrt_investigation n_inv WITH(NOLOCK) ON n_inv.public_health_case_uid= I.CASE_UID
        GROUP BY I.INVESTIGATION_KEY;


        --Adapting logic from SP_UPDATE_EVENT_DATE for RTR.
        UPDATE #TMP_Event
        SET EVENT_DATE =
                CASE
                    WHEN SPECIMEN_COLLECTION_DT IS NOT NULL THEN SPECIMEN_COLLECTION_DT
                    WHEN ILLNESS_ONSET_DT IS NOT NULL THEN ILLNESS_ONSET_DT
                    WHEN DIAGNOSIS_DT IS NOT NULL THEN DIAGNOSIS_DT
                    WHEN minEventDate.min_date IS NOT NULL THEN minEventDate.min_date
                    WHEN INV_ADD_TIME IS NOT NULL THEN INV_ADD_TIME
                    WHEN INVESTIGATION_CREATE_DATE IS NOT NULL THEN INVESTIGATION_CREATE_DATE
                    ELSE EVENT_DATE
                    END,
            EVENT_DATE_TYPE =
                CASE
                    WHEN SPECIMEN_COLLECTION_DT IS NOT NULL THEN 'Specimen Collection Date of Earliest Associated Lab'
                    WHEN ILLNESS_ONSET_DT IS NOT NULL THEN 'Illness Onset Date'
                    WHEN DIAGNOSIS_DT IS NOT NULL THEN 'Date of Diagnosis'
                    WHEN minEventDate.min_date = EARLIEST_RPT_TO_STATE_DT THEN 'Earliest date received by the state health department'
                    WHEN minEventDate.min_date = EARLIEST_RPT_TO_CNTY THEN 'Earliest date received by the county/local health department'
                    WHEN minEventDate.min_date = INV_RPT_DT THEN 'Date of Report'
                    WHEN minEventDate.min_date =  INV_START_DT THEN 'Investigation Start Date'
                    WHEN minEventDate.min_date = CONFIRMATION_DT THEN 'Confirmation Date'
                    WHEN minEventDate.min_date =  HSPTL_ADMISSION_DT THEN 'Hospitalization Admit Date'
                    WHEN minEventDate.min_date = HSPTL_DISCHARGE_DT THEN 'Hospitalization Discharge Date'
                    WHEN INV_ADD_TIME IS NOT NULL THEN 'Investigation Add Date'
                    WHEN INVESTIGATION_CREATE_DATE IS NOT NULL THEN 'Investigation Add Date'
                    ELSE EVENT_DATE_TYPE
                    END
        FROM #TMP_Event
                 CROSS apply
             (
                 SELECT MIN(eventdate) AS min_date
                 FROM (VALUES (EARLIEST_RPT_TO_STATE_DT)
                            ,(EARLIEST_RPT_TO_CNTY)
                            ,(INV_RPT_DT)
                            ,(INV_START_DT)
                            ,(CONFIRMATION_DT)
                            ,(HSPTL_ADMISSION_DT)
                            ,(HSPTL_DISCHARGE_DT))
                          AS Dates(eventdate)
                 WHERE eventdate IS NOT NULL
             ) as minEventDate;


        if @debug = 'true' select 'TMP_Event:Update Event Date and Type', * from #TMP_Event;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;


        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );


        COMMIT TRANSACTION;


---------------------------------------------------17. CREATE TABLE TMP_HEP_PAT_PROV ---------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating  #TMP_HEP_PAT_PROV';
        SET @Proc_Step_no = 17;

        IF OBJECT_ID('#TMP_HEP_PAT_PROV', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_HEP_PAT_PROV;

            END;

        SELECT DISTINCT
            TMP_F_PAGE_CASE.INVESTIGATION_KEY AS HEP_PAT_PROV_INV_KEY
                      ,P.PROVIDER_LOCAL_ID
                      ,RTRIM(LTRIM(P.PROVIDER_FIRST_NAME)) AS PHYSICIAN_FIRST_NM
                      ,P.PROVIDER_MIDDLE_NAME AS PHYSICIAN_MIDDLE_NM
                      ,P.PROVIDER_LAST_NAME AS PHYSICIAN_LAST_NM
                      ,CASE
                           WHEN RTRIM(LTRIM(P.PROVIDER_FIRST_NAME)) IS NOT NULL THEN
                               CASE WHEN LEN(P.PROVIDER_MIDDLE_NAME) > 0 THEN RTRIM(LTRIM(CONCAT(P.PROVIDER_LAST_NAME, ', ', RTRIM(LTRIM(P.PROVIDER_FIRST_NAME)), ' ',  P.PROVIDER_MIDDLE_NAME)))
                                    ELSE CONCAT(P.PROVIDER_LAST_NAME, ', ', RTRIM(LTRIM(P.PROVIDER_FIRST_NAME)), ' ',  P.PROVIDER_MIDDLE_NAME)
                                   END
                           ELSE CAST(NULL AS varchar(300)) END AS PHYS_NAME
                      ,P.PROVIDER_CITY AS PHYS_CITY
                      ,P.PROVIDER_STATE AS PHYS_STATE
                      ,P.PROVIDER_COUNTY AS PHYS_COUNTY
                      ,CASE WHEN LEN(COALESCE(RTRIM(LTRIM(P.PROVIDER_CITY)),RTRIM(LTRIM(P.PROVIDER_STATE)),RTRIM(LTRIM(P.PROVIDER_COUNTY))))>0 THEN 'Primary Work Place'
                            ELSE NULL
            END AS PHYSICIAN_ADDRESS_USE_DESC
                      ,CASE WHEN LEN(COALESCE(RTRIM(LTRIM(REPTORG.ORGANIZATION_COUNTY)),RTRIM(LTRIM(REPTORG.ORGANIZATION_STATE)),RTRIM(LTRIM(REPTORG.ORGANIZATION_CITY))))>0 THEN 'Office'
                            ELSE CAST(NULL AS varchar(300))
            END AS PHYSICIAN_ADDRESS_TYPE_DESC
                      ,P.PROVIDER_ADD_TIME
                      ,P.PROVIDER_LAST_CHANGE_TIME
                      ,P.PROVIDER_UID AS PHYSICIAN_UID
                      ,RTRIM(LTRIM(INVGTR.PROVIDER_FIRST_NAME)) AS INVESTIGATOR_FIRST_NM
                      ,INVGTR.PROVIDER_MIDDLE_NAME AS INVESTIGATOR_MIDDLE_NM
                      ,INVGTR.PROVIDER_LAST_NAME AS INVESTIGATOR_LAST_NM
                      ,CASE
                           WHEN RTRIM(LTRIM(INVGTR.PROVIDER_FIRST_NAME)) IS NOT NULL THEN
                               CASE WHEN LEN(INVGTR.PROVIDER_MIDDLE_NAME) > 0  THEN CONCAT(INVGTR.PROVIDER_LAST_NAME, ', ', RTRIM(LTRIM(INVGTR.PROVIDER_FIRST_NAME)), ' ', INVGTR.PROVIDER_MIDDLE_NAME)
                                    ELSE CONCAT(INVGTR.PROVIDER_LAST_NAME, ', ', RTRIM(LTRIM(INVGTR.PROVIDER_FIRST_NAME)), ' ', INVGTR.PROVIDER_MIDDLE_NAME)
                                   END
                           ELSE CAST(NULL AS varchar(300)) END AS INVESTIGATOR_NAME
                      ,INVGTR.PROVIDER_UID AS INVESTIGATOR_UID
                      ,REPTORG.ORGANIZATION_NAME AS RPT_SRC_SOURCE_NM
                      ,REPTORG.ORGANIZATION_COUNTY_CODE AS RPT_SRC_COUNTY_CD
                      ,REPTORG.ORGANIZATION_COUNTY AS RPT_SRC_COUNTY
                      ,REPTORG.ORGANIZATION_CITY AS RPT_SRC_CITY
                      ,REPTORG.ORGANIZATION_STATE AS RPT_SRC_STATE
                      ,CASE WHEN LEN(COALESCE(RTRIM(LTRIM(P.PROVIDER_CITY )), RTRIM(LTRIM(P.PROVIDER_STATE)),RTRIM(LTRIM(P.PROVIDER_COUNTY))))>0 THEN 'Primary Work Place'
                            ELSE CAST(NULL AS varchar(300))
            END AS REPORTING_SOURCE_ADDRESS_USE
                      ,CASE WHEN LEN(COALESCE(RTRIM(LTRIM(REPTORG.ORGANIZATION_COUNTY)),RTRIM(LTRIM(REPTORG.ORGANIZATION_STATE)),RTRIM(LTRIM(REPTORG.ORGANIZATION_CITY))))>0 THEN 'Office'
                            ELSE CAST(NULL AS varchar(300))
            END AS REPORTING_SOURCE_ADDRESS_TYPE
                      ,REPTORG.ORGANIZATION_UID AS REPORTING_SOURCE_UID
        INTO
            #TMP_HEP_PAT_PROV
        FROM dbo.F_PAGE_CASE AS PAGE_CASE WITH(NOLOCK)
                 INNER JOIN
             #TMP_F_PAGE_CASE TMP_F_PAGE_CASE
             ON TMP_F_PAGE_CASE.INVESTIGATION_KEY = PAGE_CASE.INVESTIGATION_KEY------ (My table)
                 INNER JOIN
             #TMP_CONDITION AS T
             ON TMP_F_PAGE_CASE.CONDITION_KEY = T.CONDITION_KEY------ (My table)
                 LEFT OUTER JOIN
             dbo.D_PROVIDER AS P WITH(NOLOCK)
             ON PAGE_CASE.PHYSICIAN_KEY = P.PROVIDER_KEY
                 LEFT OUTER JOIN
             dbo.D_PROVIDER AS INVGTR WITH(NOLOCK)
             ON PAGE_CASE.INVESTIGATOR_KEY = INVGTR.PROVIDER_KEY
                 LEFT OUTER JOIN
             dbo.D_ORGANIZATION AS REPTORG WITH(NOLOCK)
             ON PAGE_CASE.ORG_AS_REPORTER_KEY = REPTORG.ORGANIZATION_KEY
        ORDER BY HEP_PAT_PROV_INV_KEY;

        /*
         UPDATE #TMP_HEP_PAT_PROV
         SET PHYS_NAME = RTRIM(LTRIM(PHYSICIAN_first_nm));

         UPDATE #TMP_HEP_PAT_PROV
         SET PHYS_NAME = CASE
                             WHEN PHYS_NAME IS NOT NULL THEN CONCAT(PHYSICIAN_Last_nm, ', ', RTRIM(LTRIM(PHYSICIAN_first_nm)), ' ', PHYSICIAN_middle_nm)
                             ELSE PHYS_NAME
             END;


         UPDATE #TMP_HEP_PAT_PROV
         SET PHYS_NAME = CASE
                             WHEN LEN(PHYSICIAN_middle_nm) > 0 THEN PHYS_NAME
                             ELSE RTRIM(LTRIM(PHYS_NAME))
             END;



         ----5-17-2021
         UPDATE #TMP_HEP_PAT_PROV
         SET INVESTIGATOR_NAME = RTRIM(LTRIM(INVESTIGATOR_FIRST_NM));


         UPDATE #TMP_HEP_PAT_PROV
         SET INVESTIGATOR_NAME = CASE
                                     WHEN INVESTIGATOR_NAME IS NOT NULL THEN CONCAT(INVESTIGATOR_Last_nm, ', ', RTRIM(LTRIM(INVESTIGATOR_FIRST_NM)), ' ', INVESTIGATOR_MIDDLE_NM)
                                     ELSE INVESTIGATOR_NAME
             END;


         UPDATE #TMP_HEP_PAT_PROV
         SET INVESTIGATOR_NAME = CASE
                                     WHEN LEN(INVESTIGATOR_middle_nm) > 0 THEN INVESTIGATOR_NAME
                                     ELSE RTRIM(LTRIM(INVESTIGATOR_NAME))
             END;



         ----5-21-2021
         UPDATE #TMP_HEP_PAT_PROV
         --SET PHYSICIAN_ADDRESS_USE_DESC =concat_ws(' ',RTRIM(LTRIM(PHYS_CITY)),RTRIM(LTRIM(PHYS_STATE)),RTRIM(LTRIM(PHYS_COUNTY)))
         SET PHYSICIAN_ADDRESS_USE_DESC = concat(RTRIM(LTRIM(ISNULL(PHYS_CITY, ''))), ' ', RTRIM(LTRIM(ISNULL(PHYS_STATE, ''))), ' ', RTRIM(LTRIM(ISNULL(PHYS_COUNTY, ''))));



         ---8-31-2021
         UPDATE #TMP_HEP_PAT_PROV
         SET PHYSICIAN_ADDRESS_USE_DESC = CASE
                                              WHEN LEN(PHYSICIAN_ADDRESS_USE_DESC) > 0 THEN 'Primary Work Place'
                                              ELSE NULL
             END;



         UPDATE #TMP_HEP_PAT_PROV
         --SET PHYSICIAN_ADDRESS_TYPE_DESC =concat_ws(' ',RTRIM(LTRIM(RPT_SRC_COUNTY)),RTRIM(LTRIM(RPT_SRC_STATE)),RTRIM(LTRIM(RPT_SRC_CITY)))
         SET PHYSICIAN_ADDRESS_TYPE_DESC = concat(RTRIM(LTRIM(ISNULL(RPT_SRC_COUNTY, ''))), ' ', RTRIM(LTRIM(ISNULL(RPT_SRC_STATE, ''))), ' ', RTRIM(LTRIM(ISNULL(RPT_SRC_CITY, ''))));

         ---8-31-2021
         UPDATE #TMP_HEP_PAT_PROV
         SET PHYSICIAN_ADDRESS_TYPE_DESC = CASE
                                               WHEN LEN(PHYSICIAN_ADDRESS_TYPE_DESC) > 0 THEN 'Office'
                                               ELSE NULL
             END;


         UPDATE #TMP_HEP_PAT_PROV
         ---SET REPORTING_SOURCE_ADDRESS_USE =concat_ws(' ',RTRIM(LTRIM(PHYS_CITY)),RTRIM(LTRIM(PHYS_STATE)),RTRIM(LTRIM(PHYS_COUNTY)))
         SET REPORTING_SOURCE_ADDRESS_USE = concat(RTRIM(LTRIM(ISNULL(PHYS_CITY, ''))), ' ', RTRIM(LTRIM(ISNULL(PHYS_STATE, ''))), ' ', RTRIM(LTRIM(ISNULL(PHYS_COUNTY, ''))));

         ---8-31-2021
         UPDATE #TMP_HEP_PAT_PROV
         SET REPORTING_SOURCE_ADDRESS_USE = CASE
                                                WHEN LEN(REPORTING_SOURCE_ADDRESS_USE) > 0 THEN 'Primary Work Place'
                                                ELSE NULL
             END;


         UPDATE #TMP_HEP_PAT_PROV
         ---SET REPORTING_SOURCE_ADDRESS_TYPE =concat_ws(' ',RTRIM(LTRIM(RPT_SRC_COUNTY)),RTRIM(LTRIM(RPT_SRC_STATE)),RTRIM(LTRIM(RPT_SRC_CITY)))
         SET REPORTING_SOURCE_ADDRESS_TYPE = concat(RTRIM(LTRIM(ISNULL(RPT_SRC_COUNTY, ''))), ' ', RTRIM(LTRIM(ISNULL(RPT_SRC_STATE, ''))), ' ', RTRIM(LTRIM(ISNULL(RPT_SRC_CITY, ''))));

         ---8-31-2021
         UPDATE #TMP_HEP_PAT_PROV
       SET REPORTING_SOURCE_ADDRESS_TYPE = CASE
                                                 WHEN LEN(REPORTING_SOURCE_ADDRESS_TYPE) > 0 THEN 'office'
                                                 ELSE NULL
             END;
              */

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

-------------------------------------------------18. CREATE TABLE TMP_D_INVESTIGATION_REPEAT ---------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating #TMP_D_INVESTIGATION_REPEAT';
        SET @Proc_Step_no = 18;

        IF OBJECT_ID('#TMP_F_INVESTIGATION_REPEAT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_F_INVESTIGATION_REPEAT;
            END;

        IF OBJECT_ID('#TMP_D_INVESTIGATION_REPEAT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_D_INVESTIGATION_REPEAT;
            END;

        SELECT PAGE_CASE.D_INVESTIGATION_REPEAT_KEY, PAGE_CASE.INVESTIGATION_KEY, TMP_F_PAGE_CASE.CONDITION_KEY
        INTO #TMP_F_INVESTIGATION_REPEAT
        FROM dbo.F_PAGE_CASE AS PAGE_CASE WITH(NOLOCK)
                 INNER JOIN
             #TMP_F_PAGE_CASE AS TMP_F_PAGE_CASE
             ON TMP_F_PAGE_CASE.INVESTIGATION_KEY = PAGE_CASE.INVESTIGATION_KEY   ----(my table) since in sas it is dbo
        ORDER BY D_INVESTIGATION_REPEAT_KEY;

        SELECT inv_repeat.*
        INTO #D_INV_REPEAT_TEMP_COLS
        FROM (
                 SELECT CAST( NULL  AS varchar(1000)) AS VAC_VaccineDoseNum ,
                        CAST( NULL   AS varchar(2000)) AS VAC_VaccinationDate,
                        CAST( NULL AS FLOAT) AS PAGE_CASE_UID,
                        CAST( NULL AS VARCHAR(30)) AS BLOCK_NM,
                        CAST( NULL AS BIGINT) AS ANSWER_GROUP_SEQ_NBR
             ) AS temp_inv_repeat_columns
                 CROSS APPLY
             ( SELECT D_INVESTIGATION_REPEAT_KEY,
                      VAC_VaccineDoseNum,
                      VAC_VaccinationDate,
                      PAGE_CASE_UID,
                      BLOCK_NM,
                      ANSWER_GROUP_SEQ_NBR
               FROM dbo.D_INVESTIGATION_REPEAT
             ) AS inv_repeat;

        SELECT DISTINCT
            F.D_INVESTIGATION_REPEAT_KEY D_INVESTIGATION_REPEAT_KEY1, F.INVESTIGATION_KEY, F.CONDITION_KEY, D.*,
            RTRIM(LTRIM(VAC_VaccineDoseNum)) AS VAC_VaccineDoseNum1 ,
            VAC_VaccinationDate as VAC_VaccinationDate1 ,
            PAGE_CASE_UID PAGE_CASE_UID1, BLOCK_NM BLOCK_NM1, ANSWER_GROUP_SEQ_NBR ANSWER_GROUP_SEQ_NBR1
        INTO #TMP_D_INVESTIGATION_REPEAT
        FROM #TMP_F_INVESTIGATION_REPEAT AS F
                 LEFT JOIN
             #D_INV_REPEAT_TEMP_COLS AS D WITH(NOLOCK)
             ON D.D_INVESTIGATION_REPEAT_KEY = F.D_INVESTIGATION_REPEAT_KEY
        ORDER BY F.INVESTIGATION_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;


--------------------------------------------------19. CREATE TABLE TMP_METADATA_TEST---------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating #TMP_METADATA_TEST';
        SET @Proc_Step_no = 19;

        IF OBJECT_ID('#TMP_METADATA_TEST', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_METADATA_TEST;
            END;


        SELECT C.CONDITION_KEY, M.block_nm, M.investigation_form_cd, M.question_identifier
        INTO #TMP_METADATA_TEST
        FROM RDB_MODERN.dbo.nrt_page_case_answer AS M WITH(NOLOCK)
                 INNER JOIN
             #TMP_CONDITION AS C
             ON M.INVESTIGATION_FORM_CD = C.DISEASE_GRP_DESC
        WHERE M.question_identifier IN ( 'VAC103', 'VAC120' ) AND
            M.[block_nm] IS NOT NULL;



        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;


--------------------------------------------------2a. CREATE TABLE TMP_VAC_REPEAT------------------------------------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating #TMP_VAC_REPEAT';
        SET @Proc_Step_no = 20;


        IF OBJECT_ID('#TMP_VAC_REPEAT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_VAC_REPEAT;
            END;

        SELECT DISTINCT
            D.D_INVESTIGATION_REPEAT_KEY, D.INVESTIGATION_KEY,
            VAC_VaccinationDate1 VAC_VaccinationDate ,
            VAC_VaccineDoseNum1 VAC_VaccineDoseNum,
            D.PAGE_CASE_UID, D.ANSWER_GROUP_SEQ_NBR AS SEQNBR, D.BLOCK_NM, CAST(NULL  AS varchar(1000)) AS VAC_GT_4_IND, -----Date Indicator
            CAST(NULL AS varchar(1000)) AS VAC_DOSE_4_IND, ---Dose Indicator
            CAST(NULL  AS varchar(1000)) AS VACC_GT_4_IND   ---------FinalIndicator
        INTO #TMP_VAC_REPEAT
        FROM #TMP_D_INVESTIGATION_REPEAT AS D
                 INNER JOIN	 #TMP_CONDITION AS C  ON C.CONDITION_KEY = D.CONDITION_KEY----My Table
                 INNER JOIN	 #TMP_METADATA_TEST AS M ON M.CONDITION_KEY = D.CONDITION_KEY
        WHERE M.block_nm = D.BLOCK_NM
          AND   M.block_nm IN
                (
                    SELECT DISTINCT
                        BLOCK_NM
                    FROM #TMP_METADATA_TEST
                    WHERE QUESTION_IDENTIFIER IN( 'VAC103', 'VAC120' ) AND
                        BLOCK_NM IS NOT NULL
                )
        ORDER BY PAGE_CASE_UID;

        IF @debug = 'true' SELECT '#TMP_VAC_REPEAT', * FROM #TMP_VAC_REPEAT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;


        ---------------------------------------------------21. CREATE TABLE TMP_VAC_REPEAT_OUT_DATE_Pivot---------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating TMP_VAC_REPEAT_OUT_DATE_Pivot';
        SET @Proc_Step_no = 21;

        ----b
        IF OBJECT_ID('#TMP_VAC_REPEAT_OUT_DATE_Pivot', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_VAC_REPEAT_OUT_DATE_Pivot;

            END;

        IF OBJECT_ID('#TMP_VAC_REPEAT_OUT_DATE', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_VAC_REPEAT_OUT_DATE;
            END;

        IF OBJECT_ID('#TMP_VAC_REPEAT_OUT_DATE_Final', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_VAC_REPEAT_OUT_DATE_Final;
            END;

        DECLARE @cols AS nvarchar(max)= STUFF(
                (
                    SELECT DISTINCT
                        ',[' + CAST(NUM AS varchar) + ']'
                    FROM
                        (
                            SELECT ROW_NUMBER() OVER(
                                ORDER BY(SELECT NULL)) AS num
                            FROM Sys.Objects
                        ) AS X
                    WHERE num <= 5 FOR XML PATH('')
                ), 1, 1, '');

        IF @debug = 'true' PRINT @cols;


        CREATE TABLE #TMP_VAC_REPEAT_OUT_DATE_Pivot
        (	D_INVESTIGATION_REPEAT_KEY BIGINT,
             INVESTIGATION_KEY BIGINT,
             Page_Case_UId BIGINT,
             VACC_RECVD_DT_1 DATE,
             VACC_RECVD_DT_2 DATE,
             VACC_RECVD_DT_3 DATE,
             VACC_RECVD_DT_4 DATE,
             VACC_RECVD_DT_5 DATE
        );


        DECLARE @SqlCmd nvarchar(max)= '';

        SET @SqlCmd = '
						INSERT INTO #TMP_VAC_REPEAT_OUT_DATE_Pivot
						SELECT
						 D_INVESTIGATION_REPEAT_KEY,INVESTIGATION_KEY,Page_Case_UId,
							[1] as VACC_RECVD_DT_1,
							[2] as VACC_RECVD_DT_2,
							[3] as VACC_RECVD_DT_3,
							[4] as VACC_RECVD_DT_4,
							[5] as VACC_RECVD_DT_5

					    FROM
						(
						SELECT p.*
						 FROM
						 (
							SELECT D_INVESTIGATION_REPEAT_KEY,VAC_VaccinationDate,SEQNBR,INVESTIGATION_KEY, Page_Case_UId
							FROM #TMP_VAC_REPEAT
						 ) AS tbl
						 PIVOT
						 (
							MAX(VAC_VaccinationDate) FOR SEQNBR IN(' + @cols + ')
						 ) AS p)
						 as c
						 ';

        IF @debug = 'true' PRINT @SqlCmd;

        EXEC sp_executesql @SqlCmd;

        SELECT *, CAST(NULL  AS varchar(1000)) AS VAC_GT_4_IND      -----Date Indicator---change the length to 300 on 5-13-2021
        INTO #TMP_VAC_REPEAT_OUT_DATE
        FROM #TMP_VAC_REPEAT_OUT_DATE_Pivot
        WHERE LEN(VACC_RECVD_DT_1) > 0 OR
            LEN(VACC_RECVD_DT_2) > 0 OR
            LEN(VACC_RECVD_DT_3) > 0 OR
            LEN(VACC_RECVD_DT_4) > 0 OR
            LEN(VACC_RECVD_DT_5) > 0 AND
            PAGE_CASE_UID > 0;

        UPDATE #TMP_VAC_REPEAT_OUT_DATE
        SET VAC_GT_4_IND = CASE
                               WHEN VACC_RECVD_DT_5 IS NULL THEN NULL
                               ELSE 'True'
            END;

        IF @debug = 'true' SELECT '#TMP_VAC_REPEAT_OUT_DATE', * FROM #TMP_VAC_REPEAT_OUT_DATE;


        SELECT DISTINCT
            Page_Case_UId, D_INVESTIGATION_REPEAT_KEY, INVESTIGATION_KEY, VACC_RECVD_DT_1, VACC_RECVD_DT_2, VACC_RECVD_DT_3, VACC_RECVD_DT_4, VAC_GT_4_IND
        INTO #TMP_VAC_REPEAT_OUT_DATE_Final
        FROM #TMP_VAC_REPEAT_OUT_DATE
        ORDER BY D_INVESTIGATION_REPEAT_KEY;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

        ---------------------------------------22. CREATE TABLE TMP_VAC_REPEAT_OUT_NUM_Pivot-------------------------------------------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating TMP_VAC_REPEAT_OUT_NUM_Pivot';
        SET @Proc_Step_no = 22;

        ----c
        IF OBJECT_ID('#TMP_VAC_REPEAT_OUT_NUM_Pivot', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_VAC_REPEAT_OUT_NUM_Pivot;
            END;

        IF OBJECT_ID('#TMP_VAC_REPEAT_OUT_NUM', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_VAC_REPEAT_OUT_NUM;
            END;

        IF OBJECT_ID('#TMP_VAC_REPEAT_OUT_NUM_final', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_VAC_REPEAT_OUT_NUM_Final;
            END;

        DECLARE @col AS nvarchar(max)= STUFF(
                (
                    SELECT DISTINCT
                        ',[' + CAST(NUM AS varchar) + ']'
                    FROM
                        (
                            SELECT ROW_NUMBER() OVER(
                                ORDER BY(SELECT NULL)) AS num
                            FROM Sys.Objects
                        ) AS X
                    WHERE num <= 5 FOR XML PATH('')
                ), 1, 1, '');

        IF @debug = 'true' PRINT @col;

        CREATE TABLE #TMP_VAC_REPEAT_OUT_NUM_Pivot
        (
            D_INVESTIGATION_REPEAT_KEY BIGINT,
            INVESTIGATION_KEY BIGINT,
            Page_Case_UId BIGINT,
            VACC_DOSE_NBR_1 BIGINT,
            VACC_DOSE_NBR_2 BIGINT,
            VACC_DOSE_NBR_3 BIGINT,
            VACC_DOSE_NBR_4 BIGINT,
            VACC_DOSE_NBR_5 BIGINT
        );

        DECLARE @SqlCmds nvarchar(max)= '';

        SET @SqlCmds = '
							INSERT INTO #TMP_VAC_REPEAT_OUT_NUM_Pivot
							SELECT
							 D_INVESTIGATION_REPEAT_KEY,INVESTIGATION_KEY,Page_Case_UId,
								[1] as VACC_DOSE_NBR_1,
								[2] as VACC_DOSE_NBR_2,
								[3] as VACC_DOSE_NBR_3,
								[4] as VACC_DOSE_NBR_4,
								[5] as VACC_DOSE_NBR_5
							 FROM
							(
							SELECT p.*
							 FROM
							 (
								SELECT D_INVESTIGATION_REPEAT_KEY,VAC_VaccineDoseNum,SEQNBR,INVESTIGATION_KEY, Page_Case_UId
								FROM #TMP_VAC_REPEAT
							 ) AS tbl
							 PIVOT
							 (
								MAX(VAC_VaccineDoseNum) FOR SEQNBR IN(' + @col + ')
							 ) AS p)
							 as c
							 ';

        IF @debug = 'true' PRINT @SqlCmds;

        EXEC sp_executesql @SqlCmds;

        SELECT *, CAST(NULL AS [varchar](2000)) AS VAC_DOSE_4_IND     ---Dose Indicator
        INTO #TMP_VAC_REPEAT_OUT_NUM
        FROM #TMP_VAC_REPEAT_OUT_NUM_Pivot
        WHERE LEN(VACC_DOSE_NBR_1) > 0 OR
            LEN(VACC_DOSE_NBR_2) > 0 OR
            LEN(VACC_DOSE_NBR_3) > 0 OR
            LEN(VACC_DOSE_NBR_4) > 0 OR
            LEN(VACC_DOSE_NBR_5) > 0 AND
            PAGE_CASE_UID > 0;

        UPDATE #TMP_VAC_REPEAT_OUT_NUM
        SET VAC_DOSE_4_IND = CASE
                                 WHEN VACC_DOSE_NBR_5 IS NULL THEN NULL
                                 ELSE 'True'
            END;

        IF @debug = 'true' SELECT '#TMP_VAC_REPEAT_OUT_NUM', * FROM #TMP_VAC_REPEAT_OUT_NUM;

        SELECT DISTINCT
            Page_Case_UId, D_INVESTIGATION_REPEAT_KEY, INVESTIGATION_KEY, VACC_DOSE_NBR_1, VACC_DOSE_NBR_2, VACC_DOSE_NBR_3, VACC_DOSE_NBR_4, VAC_DOSE_4_IND
        INTO #TMP_VAC_REPEAT_OUT_NUM_Final
        FROM #TMP_VAC_REPEAT_OUT_NUM
        ORDER BY D_INVESTIGATION_REPEAT_KEY;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;


-------------------------------------------------------23. CREATE TABLE TMP_VAC_REPEAT_OUT_FINAL1--------------------------------------------------------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating TMP_VAC_REPEAT_OUT_FINAL1';
        SET @Proc_Step_no = 23;


        IF OBJECT_ID('#TMP_VAC_REPEAT_OUT_FINAL1', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_VAC_REPEAT_OUT_FINAL1;
            END;


        SELECT DISTINCT
            D.Page_Case_UId, D.D_INVESTIGATION_REPEAT_KEY, D.INVESTIGATION_KEY, VACC_DOSE_NBR_1, VACC_RECVD_DT_1, VACC_DOSE_NBR_2, VACC_RECVD_DT_2, VACC_DOSE_NBR_3, VACC_RECVD_DT_3, VACC_DOSE_NBR_4, VACC_RECVD_DT_4, VAC_GT_4_IND, VAC_DOSE_4_IND, CAST(NULL  AS varchar(1000)) AS VACC_GT_4_IND   ---------FinalIndicator
        INTO #TMP_VAC_REPEAT_OUT_FINAL1
        FROM #TMP_VAC_REPEAT_OUT_Date_Final AS D
                 INNER JOIN
             #TMP_VAC_REPEAT_OUT_NUM_Final AS N
             ON D.D_INVESTIGATION_REPEAT_KEY = N.D_INVESTIGATION_REPEAT_KEY
        ORDER BY D.D_INVESTIGATION_REPEAT_KEY;

        UPDATE #TMP_VAC_REPEAT_OUT_FINAL1
        SET VACC_GT_4_IND = CASE
                                WHEN LEN(RTRIM(VAC_DOSE_4_IND)) > 0 OR
                                     LEN(RTRIM(VAC_GT_4_IND)) > 0 THEN 'True'
                                ELSE NULL
            END;

        IF @debug = 'true' SELECT '#TMP_VAC_REPEAT_OUT_FINAL1', * FROM #TMP_VAC_REPEAT_OUT_FINAL1;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

        --------------------------------------------------24. CREATE TABLE TMP_VAC_REPEAT_OUT_FINAL--------------------------------------------------------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating TMP_VAC_REPEAT_OUT_FINAL';
        SET @Proc_Step_no = 24;

        ----e
        IF OBJECT_ID('#TMP_VAC_REPEAT_OUT_FINAL', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_VAC_REPEAT_OUT_FINAL;

            END;

        SELECT  Page_Case_UId,
                D_INVESTIGATION_REPEAT_KEY,
                INVESTIGATION_KEY,
                VACC_DOSE_NBR_1,
                VACC_RECVD_DT_1,
                VACC_DOSE_NBR_2,
                VACC_RECVD_DT_2,
                VACC_DOSE_NBR_3,
                VACC_RECVD_DT_3,
                VACC_DOSE_NBR_4,
                VACC_RECVD_DT_4,
                VACC_GT_4_IND
        ---------FinalIndicator
        INTO #TMP_VAC_REPEAT_OUT_FINAL
        FROM #TMP_VAC_REPEAT_OUT_FINAL1;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;


        ---------------------------------------------------------Final Table 25 TMP_HEPATITIS_CASE_BASE------------------------------------------------------------------------------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Generating TMP_HEPATITIS_CASE_BASE';
        SET @Proc_Step_no = 25;

        IF OBJECT_ID('#TMP_HEPATITIS_CASE_BASE', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #TMP_HEPATITIS_CASE_BASE;
            END;

        SELECT DISTINCT
            A.INNC_NOTIFICATION_DT, ---1
            I.CASE_RPT_MMWR_WEEK, ---2
            I.CASE_RPT_MMWR_YEAR, ----3
            C.HEP_D_INFECTION_IND, ----4
            C.HEP_MEDS_RECVD_IND, ----5
            L.HEP_C_TOTAL_ANTIBODY, ----6
            I.DIAGNOSIS_DT, ------------7
            I.DIE_FRM_THIS_ILLNESS_IND, ----8
            I.DISEASE_IMPORTED_IND, -----9
            I.EARLIEST_RPT_TO_CNTY, ----10
            I.EARLIEST_RPT_TO_STATE_DT, ---11
            RTRIM(LTRIM(SUBSTRING(A.BINATIONAL_RPTNG_CRIT,1,300))) as BINATIONAL_RPTNG_CRIT, ---12
            E.CHILDCARE_CASE_IND, ---13
            E.CNTRY_USUAL_RESIDENCE, ---14
            E.CT_BABYSITTER_IND, ---15
            E.CT_CHILDCARE_IND, ----16
            E.CT_HOUSEHOLD_IND, ---17
            E.HEP_CONTACT_IND, ----18
            R.HEP_CONTACT_EVER_IND, ----19
            E.OTHER_CONTACT_IND, ---20
            ISNULL(NULLIF(E.COM_SRC_OUTBREAK_IND, ''), NULL) AS COM_SRC_OUTBREAK_IND, ---21
            E.CONTACT_TYPE_OTH, ----22
            E.CT_PLAYMATE_IND, ----23
            E.SEXUAL_PARTNER_IND, ----24
            E.DNP_HOUSEHOLD_CT_IND, ---25
            E.HEP_A_EPLINK_IND, ----25
            E.FEMALE_SEX_PRTNR_NBR, ---27
            E.FOODHNDLR_PRIOR_IND, ----28
            ISNULL(NULLIF(E.DNP_EMPLOYEE_IND, ''), NULL) AS DNP_EMPLOYEE_IND, -----29
            ISNULL(NULLIF(E.STREET_DRUG_INJECTED, ''), NULL) AS STREET_DRUG_INJECTED, -----30
            ISNULL(NULLIF(E.MALE_SEX_PRTNR_NBR, ''), NULL) AS MALE_SEX_PRTNR_NBR, ----31
            I.OUTBREAK_IND, -----32
            ISNULL(NULLIF(E.OBRK_FOODHNDLR_IND, ''), NULL) AS OBRK_FOODHNDLR_IND, ----33
            ISNULL(NULLIF(E.FOOD_OBRK_FOOD_ITEM, ''), NULL) AS FOOD_OBRK_FOOD_ITEM, ----34
            ISNULL(NULLIF(E.OBRK_NOFOODHNDLR_IND, ''), NULL) AS OBRK_NOFOODHNDLR_IND, ----35
            ISNULL(NULLIF(E.OBRK_UNIDENTIFIED_IND, ''), NULL) AS OBRK_UNIDENTIFIED_IND, ----36
            ISNULL(NULLIF(E.OBRK_WATERBORNE_IND, ''), NULL) AS OBRK_WATERBORNE_IND, ----37
            ISNULL(NULLIF(E.STREET_DRUG_USED, ''), NULL) AS STREET_DRUG_USED, ---38
            PO.SEX_PREF, ----39
            I.HSPTL_ADMISSION_DT, ----40
            I.HSPTL_DISCHARGE_DT, ----41
            I.HSPTL_DURATION_DAYS, ----42
            I.HSPTLIZD_IND, ---43
            I.ILLNESS_ONSET_DT, ----44
            I.INV_CASE_STATUS, ----45
            ----	ltrim(rtrim(I.INV_COMMENTS)) as INV_COMMENTS,----46--------7/21/2021
            LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE([INV_COMMENTS], CHAR(10), CHAR(32)), CHAR(13), CHAR(32)), CHAR(160), CHAR(32)), CHAR(9), CHAR(32)))) AS INV_COMMENTS, ----46--------7/21/2021
            I.INV_LOCAL_ID, ---47
            I.INV_RPT_DT, ---48
            I.INV_START_DT, ---49
            I.INVESTIGATION_STATUS, ---50
            I.JURISDICTION_NM, ---51
            L.ALT_SGPT_RESULT, ----52
            L.ANTI_HBS_POS_REAC_IND, -----53
            L.AST_SGOT_RESULT, ---54
            L.HEP_E_ANTIGEN, ----55
            L.HBE_AG_DT, ---56
            L.HEP_B_SURFACE_ANTIGEN, ----57
            L.HBS_AG_DT, ----58
            L.HEP_B_DNA, -----59
            L.HBV_NAT_DT, ----60
            L.HCV_RNA, ----61
            L.HCV_RNA_DT, ----62
            -- L.HEP_D_TEST_IND, ----63
            CASE WHEN  L.HEP_D_TEST_IND IS NULL THEN NULL
                 WHEN  L.HEP_D_TEST_IND = 'Yes' THEN 'Y'
                 WHEN  L.HEP_D_TEST_IND = 'No' THEN 'N'
                 ELSE 'U' END AS HEP_D_TEST_IND,
            L.HEP_A_IGM_ANTIBODY, ----64
            L.IGM_ANTI_HAV_DT, ----65
            L.HEP_B_IGM_ANTIBODY, ----66
            L.IGM_ANTI_HBC_DT, ----67
            L.PREV_NEG_HEP_TEST_IND, ------68
            L.ANTIHCV_SIGCUT_RATIO, ----69
            L.ANTIHCV_SUPP_ASSAY, -----70
            L.SUPP_ANTI_HCV_DT, -----71
            L.ALT_RESULT_DT, ----72
            L.AST_RESULT_DT, -----73
            L.ALT_SGPT_RSLT_UP_LMT, ----74
            L.AST_SGOT_RSLT_UP_LMT, ----75
            L.HEP_A_TOTAL_ANTIBODY, ----76
            L.TOTAL_ANTI_HAV_DT, ----77
            L.HEP_B_TOTAL_ANTIBODY, ----78
            L.TOTAL_ANTI_HBC_DT, ----79
            L.TOTAL_ANTI_HCV_DT, ----80
            L.HEP_D_TOTAL_ANTIBODY, ----81
            L.TOTAL_ANTI_HDV_DT, ----82
            L.HEP_E_TOTAL_ANTIBODY, ----83
            L.TOTAL_ANTI_HEV_DT, ----84
            L.VERIFIED_TEST_DT, ----85
            I.LEGACY_CASE_ID, ---86
            MH.DIABETES_IND, ----87
            MH.DIABETES_DX_DT, ----88
            MH.PREGNANCY_DUE_DT, ----89
            MH.PAT_JUNDICED_IND, -----90
            MH.PAT_PREV_AWARE_IND, ----91
            MH.HEP_CARE_PROVIDER, ----92
            MH.TEST_REASON, ------93
            RTRIM(LTRIM(SUBSTRING(MH.TEST_REASON_OTH,1,150))) as TEST_REASON_OTH, -----94----10/18/2021 added the trim since the dest has only 150 length
            MH.SYMPTOMATIC_IND, -----95
            M.MTH_BORN_OUTSIDE_US, ---96
            M.MTH_ETHNICITY, ------97
            M.MTH_HBS_AG_PRIOR_POS, ----98
            M.MTH_POS_AFTER, ------99
            M.MTH_POS_TEST_DT, ----100
            M.MTH_RACE, -----101
            M.MTH_BIRTH_COUNTRY, ----102
            I.NOT_SUBMIT_DT, ----103
            P.PAT_REPORTED_AGE, ----104
            P.PAT_REPORTED_AGE_UNIT, ----105
            P.PAT_CITY, ----106
            P.PAT_COUNTRY, ----107
            P.PAT_COUNTY, ----108
            P.PAT_CURR_GENDER, ---109
            P.PAT_DOB, ---110
            LTRIM(RTRIM(P.PAT_ETHNICITY)) AS PAT_ETHNICITY, ---111
            P.PAT_FIRST_NM, ---112
            P.PAT_LAST_NM, ---113
            P.PAT_LOCAL_ID, ---114
            P.PAT_MIDDLE_NM, ---115
            I.PAT_PREGNANT_IND, ---116
            P.PAT_RACE, ----117
            P.PAT_STATE, ----118
            LTRIM(RTRIM(P.PAT_STREET_ADDR_1)) AS PAT_STREET_ADDR_1, ---119-------------------7/14/2021
            P.PAT_STREET_ADDR_2, ----120
            P.PAT_ZIP_CODE, ----121
            HP.RPT_SRC_SOURCE_NM, ----122
            HP.RPT_SRC_STATE, ----123
            I.RPT_SRC_CD_DESC, ---124
            R.BLD_EXPOSURE_IND, ----125
            R.BLD_RECVD_IND, ----126
            R.BLD_RECVD_DT, ----127
            R.MED_DEN_BLD_CT_FRQ, ----128
            R.MED_DEN_EMP_EVER_IND, ----129
            R.MED_DEN_EMPLOYEE_IND, ---130
            R.CLOTFACTOR_PRIOR_1987, ----131
            R.BLD_CONTAM_IND, ------132
            R.DEN_WORK_OR_SURG_IND, ----133
            R.HEMODIALYSIS_IND, ----134
            R.LT_HEMODIALYSIS_IND, -----135
            R.HSPTL_PRIOR_ONSET_IND, ----136
            R.EVER_INJCT_NOPRSC_DRG, -----137
            R.INCAR_24PLUSHRS_IND, ---138
            R.INCAR_6PLUS_MO_IND, ---139
            R.EVER_INCAR_IND, ----140
            R.INCAR_TYPE_JAIL_IND, ----141
            R.INCAR_TYPE_PRISON_IND, ----142
            R.INCAR_TYPE_JUV_IND, ----143
            --R.LAST6PLUSMO_INCAR_PER, ----144
            CASE WHEN R.LAST6PLUSMO_INCAR_PER IS NOT NULL THEN
                     CASE
                         WHEN LAST6PLUSMO_INCAR_PER NOT LIKE N'%[^0-9.,-]%'  AND LAST6PLUSMO_INCAR_PER NOT LIKE '.'
                             AND ISNUMERIC(LAST6PLUSMO_INCAR_PER) = 1  THEN LAST6PLUSMO_INCAR_PER
                         ELSE 0 END
                 ELSE LAST6PLUSMO_INCAR_PER
                END AS LAST6PLUSMO_INCAR_PER,
            --R.LAST6PLUSMO_INCAR_YR, ----145
            CASE WHEN R.LAST6PLUSMO_INCAR_YR IS NOT NULL THEN
                     CASE WHEN LAST6PLUSMO_INCAR_YR NOT LIKE N'%[^0-9.,-]%' AND LAST6PLUSMO_INCAR_YR NOT LIKE '.'
                         AND ISNUMERIC(LAST6PLUSMO_INCAR_YR) = 1 THEN LAST6PLUSMO_INCAR_YR
                          ELSE 0 END
                 ELSE LAST6PLUSMO_INCAR_YR
                END AS LAST6PLUSMO_INCAR_YR,
            R.OUTPAT_IV_INF_IND, ----146
            R.LTCARE_RESIDENT_IND, ----147
            R.LIFE_SEX_PRTNR_NBR, ----148
            R.BLD_EXPOSURE_OTH, ----149
            R.PIERC_PRIOR_ONSET_IND, ----150
            R.PIERC_PERF_LOC_OTH, ----151
            R.PIERC_PERF_LOC, -----152
            R.PUB_SAFETY_BLD_CT_FRQ, ----153
            R.PUB_SAFETY_WORKER_IND, ----154
            R.STD_TREATED_IND, ----155
            R.STD_LAST_TREATMENT_YR, ---156
            R.NON_ORAL_SURGERY_IND, ---157
            R.TATT_PRIOR_ONSET_IND, ---158
            R.TATTOO_PERF_LOC, ----158
            R.TATT_PRIOR_LOC_OTH, ----160
            R.BLD_TRANSF_PRIOR_1992, ---161
            R.ORGN_TRNSP_PRIOR_1992, ----162
            I.TRANSMISSION_MODE, ----163
            T.HOUSEHOLD_TRAVEL_IND, ----164
            T.TRAVEL_OUT_USACAN_IND, ----165
            T.TRAVEL_OUT_USACAN_LOC, -----166
            T.HOUSEHOLD_TRAVEL_LOC, ----167
            T.TRAVEL_REASON, -----168
            V.IMM_GLOB_RECVD_IND, ----169
            V.GLOB_LAST_RECVD_YR, ----170
            V.VACC_RECVD_IND, ----171-------Has to be 10 digits long
            VAC.VACC_DOSE_NBR_1, ----172
            VAC.VACC_RECVD_DT_1, ----173
            VAC.VACC_DOSE_NBR_2, ----174
            VAC.VACC_RECVD_DT_2, ----175
            VAC.VACC_DOSE_NBR_3, ----176
            VAC.VACC_RECVD_DT_3, -----177
            VAC.VACC_DOSE_NBR_4, -----178
            VAC.VACC_RECVD_DT_4, ---179
            --VAC.VACC_GT_4_IND, -----180
            CASE WHEN LEN(ISNULL(RTRIM(LTRIM(VAC.VACC_GT_4_IND)), '')) < 1 THEN 'False'
                 ELSE VAC.VACC_GT_4_IND
                END AS VACC_GT_4_IND,
            V.VACC_DOSE_RECVD_NBR, ----181
            V.VACC_LAST_RECVD_YR, -----182
            L.ANTI_HBSAG_TESTED_IND, ----183
            I.CONDITION_CD, -----184
            CAST(NULL AS datetime) AS EVENT_DATE, ----185
            I.IMPORT_FROM_CITY, ----186
            I.IMPORT_FROM_COUNTRY, ----187
            I.IMPORT_FROM_COUNTY, ----188
            I.IMPORT_FROM_STATE, ----189
            I.INVESTIGATION_KEY, -----190
            HP.INVESTIGATOR_NAME, -----191
            P.PAT_ELECTRONIC_IND, ----192
            HP.PHYS_CITY, ----193
            HP.PHYS_COUNTY, ----194
            HP.PHYS_NAME, ----195
            HP.PHYS_STATE, ----196
            I.PROGRAM_JURISDICTION_OID, ----197
            HP.RPT_SRC_CITY, ---198
            HP.RPT_SRC_COUNTY, ----199
            HP.RPT_SRC_COUNTY_CD, ---200
            HP.PHYSICIAN_UID, ----201
            P.PATIENT_UID, ----202
            I.CASE_UID, ---203
            HP.INVESTIGATOR_UID, ---204
            HP.REPORTING_SOURCE_UID, ---205
            GETDATE() AS REFRESH_DATETIME, ---206
            P.PAT_BIRTH_COUNTRY,----207
            CAST(NULL AS varchar(2000)) AS EVENT_DATE_TYPE
        INTO #TMP_HEPATITIS_CASE_BASE
        FROM #TMP_Investigation AS I WITH(NOLOCK)
                 FULL OUTER JOIN  #TMP_D_INV_LAB_FINDING AS L WITH(NOLOCK)  ON I.INVESTIGATION_KEY = L.LAB_INV_KEY
                 FULL OUTER JOIN  #TMP_D_INV_RISK_FACTOR AS R WITH(NOLOCK)  ON I.INVESTIGATION_KEY = R.RISK_INV_KEY
                 FULL OUTER JOIN  #TMP_D_INV_EPIDEMIOLOGY AS E WITH(NOLOCK) ON I.INVESTIGATION_KEY = E.EPIDEMIOLOGY_INV_KEY
                 FULL OUTER JOIN  #TMP_D_Patient AS P WITH(NOLOCK)          ON I.INVESTIGATION_KEY = P.Patient_INV_KEY
                 FULL OUTER JOIN  #TMP_D_INV_VACCINATION AS V WITH(NOLOCK)  ON I.INVESTIGATION_KEY = V.VACCINATION_INV_KEY
                 FULL OUTER JOIN  #TMP_D_INV_TRAVEL AS T WITH(NOLOCK)  ON I.INVESTIGATION_KEY = T.Travel_INV_KEY
                 FULL OUTER JOIN  #TMP_D_INV_MOTHER AS M WITH(NOLOCK)  ON I.INVESTIGATION_KEY = M.Mother_INV_KEY
                 FULL OUTER JOIN  #TMP_D_INV_MEDICAL_HISTORY AS MH WITH(NOLOCK)  ON I.INVESTIGATION_KEY = MH.MEDHistory_INV_KEY
                 FULL OUTER JOIN  #TMP_D_INV_ADMINISTRATIVE AS A WITH(NOLOCK)  ON I.INVESTIGATION_KEY = A.ADMIN_INV_KEY
                 FULL OUTER JOIN  #TMP_D_INV_PATIENT_OBS AS PO WITH(NOLOCK)  ON I.INVESTIGATION_KEY = PO.PATIENT_OBS_INV_KEY
                 FULL OUTER JOIN  #TMP_HEP_PAT_PROV AS HP WITH(NOLOCK)  ON I.INVESTIGATION_KEY = HP.HEP_PAT_PROV_INV_KEY
                 FULL OUTER JOIN  #TMP_D_INV_CLINICAL AS C WITH(NOLOCK)  ON I.INVESTIGATION_KEY = C.CLINICAL_INV_KEY
                 FULL OUTER JOIN  #TMP_VAC_REPEAT_OUT_FINAL AS VAC WITH(NOLOCK)  ON I.INVESTIGATION_KEY = VAC.INVESTIGATION_KEY;

        --Revise (CDW): Evaluate LEFT JOIN for future performance enhancements.

        IF @debug = 'true' SELECT '#TMP_HEPATITIS_CASE_BASE', * FROM #TMP_HEPATITIS_CASE_BASE;


        ---7/14/2021(since getting error converting varchar to int)
        /*
         UPDATE #TMP_HEPATITIS_CASE_BASE
         SET LAST6PLUSMO_INCAR_PER = CASE
                                         WHEN LAST6PLUSMO_INCAR_PER NOT LIKE N'%[^0-9.,-]%' AND
                                              LAST6PLUSMO_INCAR_PER NOT LIKE '.' AND
                                              ISNUMERIC(LAST6PLUSMO_INCAR_PER) = 1 THEN LAST6PLUSMO_INCAR_PER
                                         ELSE 0
             END
         where LAST6PLUSMO_INCAR_PER is not null
         ;



         ------------  /*EXT_LAST6PLUSMO_INCAR_PER= INPUT(RSK_IncarcTimeMonths, comma20.)*/----20
         UPDATE #TMP_HEPATITIS_CASE_BASE
         SET LAST6PLUSMO_INCAR_YR = CASE
                                        WHEN LAST6PLUSMO_INCAR_YR NOT LIKE N'%[^0-9.,-]%' AND
                                             LAST6PLUSMO_INCAR_YR NOT LIKE '.' AND
                                             ISNUMERIC(LAST6PLUSMO_INCAR_YR) = 1 THEN LAST6PLUSMO_INCAR_YR
                                        ELSE 0
             END
         where LAST6PLUSMO_INCAR_YR is not null
         ;


         ------------  /*EXT_LAST6PLUSMO_INCAR_PER= INPUT(RSK_IncarcTimeMonths, comma20.)*/----20
         UPDATE #TMP_HEPATITIS_CASE_BASE
         SET VACC_GT_4_IND = CASE
                                 WHEN LEN(ISNULL(RTRIM(LTRIM(VACC_GT_4_IND)), '')) < 1 THEN 'False'
                                 ELSE VACC_GT_4_IND
             END;

           */



        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

        ------------------------------------------------------------------------------------------------------------------------------------------------------
        DELETE FROM #TMP_HEPATITIS_CASE_BASE
        WHERE PATIENT_UID IS NULL;

        /*

         UPDATE #TMP_HEPATITIS_CASE_BASE
         SET REFRESH_DATETIME = GETDATE();
         */


        ------------------------------------------------------------------------------------------------------
        ----HEP_D_TEST_IND  to appear as N,Y U or Null--added on 5-19-2021
        /*
         UPDATE #TMP_HEPATITIS_CASE_BASE ----5/20-2021
         SET HEP_D_TEST_IND = CASE
                                  WHEN HEP_D_TEST_IND IS NULL THEN NULL
                                  WHEN HEP_D_TEST_IND = 'Yes' THEN 'Y'
                                  WHEN HEP_D_TEST_IND = 'No' THEN 'N'
                                  ELSE 'U'
             END;
             */


        ---------------------------------------------------------Final Table 26 TMP_HEPATITIS_CASE_BASE------------------------------------------------------------------------------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_name = 'Updating HEPATITIS_CASE_BASE';
        SET @Proc_Step_no = 26;

        UPDATE [dbo].[HEPATITIS_DATAMART]
        SET
            INNC_NOTIFICATION_DT = H.[INNC_NOTIFICATION_DT],
            CASE_RPT_MMWR_WEEK = H.[CASE_RPT_MMWR_WEEK],
            CASE_RPT_MMWR_YEAR = H.[CASE_RPT_MMWR_YEAR],
            HEP_D_INFECTION_IND = H.[HEP_D_INFECTION_IND],
            HEP_MEDS_RECVD_IND = H.[HEP_MEDS_RECVD_IND],
            HEP_C_TOTAL_ANTIBODY = H.[HEP_C_TOTAL_ANTIBODY],
            DIAGNOSIS_DT = H.[DIAGNOSIS_DT],
            DIE_FRM_THIS_ILLNESS_IND = H.[DIE_FRM_THIS_ILLNESS_IND],
            DISEASE_IMPORTED_IND = H.[DISEASE_IMPORTED_IND],
            EARLIEST_RPT_TO_CNTY = H.[EARLIEST_RPT_TO_CNTY],
            EARLIEST_RPT_TO_STATE_DT = H.[EARLIEST_RPT_TO_STATE_DT],
            BINATIONAL_RPTNG_CRIT = H.[BINATIONAL_RPTNG_CRIT],
            CHILDCARE_CASE_IND = H.[CHILDCARE_CASE_IND],
            CNTRY_USUAL_RESIDENCE = H.[CNTRY_USUAL_RESIDENCE],
            CT_BABYSITTER_IND = H.[CT_BABYSITTER_IND],
            CT_CHILDCARE_IND = H.[CT_CHILDCARE_IND],
            CT_HOUSEHOLD_IND = H.[CT_HOUSEHOLD_IND],
            HEP_CONTACT_IND = H.[HEP_CONTACT_IND],
            HEP_CONTACT_EVER_IND = H.[HEP_CONTACT_EVER_IND],
            OTHER_CONTACT_IND = H.[OTHER_CONTACT_IND],
            COM_SRC_OUTBREAK_IND = H.[COM_SRC_OUTBREAK_IND],
            CONTACT_TYPE_OTH = H.[CONTACT_TYPE_OTH],
            CT_PLAYMATE_IND = H.[CT_PLAYMATE_IND],
            SEXUAL_PARTNER_IND = H.[SEXUAL_PARTNER_IND],
            DNP_HOUSEHOLD_CT_IND = H.[DNP_HOUSEHOLD_CT_IND],
            HEP_A_EPLINK_IND = H.[HEP_A_EPLINK_IND],
            FEMALE_SEX_PRTNR_NBR = H.[FEMALE_SEX_PRTNR_NBR],
            FOODHNDLR_PRIOR_IND = H.[FOODHNDLR_PRIOR_IND],
            DNP_EMPLOYEE_IND = H.[DNP_EMPLOYEE_IND],
            STREET_DRUG_INJECTED = H.[STREET_DRUG_INJECTED],
            MALE_SEX_PRTNR_NBR = H.[MALE_SEX_PRTNR_NBR],
            OUTBREAK_IND = H.[OUTBREAK_IND],
            OBRK_FOODHNDLR_IND = H.[OBRK_FOODHNDLR_IND],
            FOOD_OBRK_FOOD_ITEM = H.[FOOD_OBRK_FOOD_ITEM],
            OBRK_NOFOODHNDLR_IND = H.[OBRK_NOFOODHNDLR_IND],
            OBRK_UNIDENTIFIED_IND = H.[OBRK_UNIDENTIFIED_IND],
            OBRK_WATERBORNE_IND = H.[OBRK_WATERBORNE_IND],
            STREET_DRUG_USED = H.[STREET_DRUG_USED],
            SEX_PREF = H.[SEX_PREF],
            HSPTL_ADMISSION_DT = H.[HSPTL_ADMISSION_DT],
            HSPTL_DISCHARGE_DT = H.[HSPTL_DISCHARGE_DT],
            HSPTL_DURATION_DAYS = H.[HSPTL_DURATION_DAYS],
            HSPTLIZD_IND = H.[HSPTLIZD_IND],
            ILLNESS_ONSET_DT = H.[ILLNESS_ONSET_DT],
            INV_CASE_STATUS = H.[INV_CASE_STATUS],
            INV_COMMENTS = H.[INV_COMMENTS],
            INV_LOCAL_ID = H.[INV_LOCAL_ID],
            INV_RPT_DT = H.[INV_RPT_DT],
            INV_START_DT = H.[INV_START_DT],
            INVESTIGATION_STATUS = H.[INVESTIGATION_STATUS],
            JURISDICTION_NM = H.[JURISDICTION_NM],
            ALT_SGPT_RESULT = H.[ALT_SGPT_RESULT],
            ANTI_HBS_POS_REAC_IND = H.[ANTI_HBS_POS_REAC_IND],
            AST_SGOT_RESULT = H.[AST_SGOT_RESULT],
            HEP_E_ANTIGEN = H.[HEP_E_ANTIGEN],
            HBE_AG_DT = H.[HBE_AG_DT],
            HEP_B_SURFACE_ANTIGEN = H.[HEP_B_SURFACE_ANTIGEN],
            HBS_AG_DT = H.[HBS_AG_DT],
            HBV_NAT_DT = H.[HBV_NAT_DT],
            HCV_RNA = H.[HCV_RNA],
            HCV_RNA_DT = H.[HCV_RNA_DT],
            HEP_D_TEST_IND = H.[HEP_D_TEST_IND],
            HEP_A_IGM_ANTIBODY = H.[HEP_A_IGM_ANTIBODY],
            IGM_ANTI_HAV_DT = H.[IGM_ANTI_HAV_DT],
            HEP_B_IGM_ANTIBODY = H.[HEP_B_IGM_ANTIBODY],
            IGM_ANTI_HBC_DT = H.[IGM_ANTI_HBC_DT],
            PREV_NEG_HEP_TEST_IND = H.[PREV_NEG_HEP_TEST_IND],
            ANTIHCV_SIGCUT_RATIO = H.[ANTIHCV_SIGCUT_RATIO],
            ANTIHCV_SUPP_ASSAY = H.[ANTIHCV_SUPP_ASSAY],
            SUPP_ANTI_HCV_DT = H.[SUPP_ANTI_HCV_DT],
            ALT_RESULT_DT = H.[ALT_RESULT_DT],
            AST_RESULT_DT = H.[AST_RESULT_DT],
            ALT_SGPT_RSLT_UP_LMT = H.[ALT_SGPT_RSLT_UP_LMT],
            AST_SGOT_RSLT_UP_LMT = H.[AST_SGOT_RSLT_UP_LMT],
            HEP_A_TOTAL_ANTIBODY = H.[HEP_A_TOTAL_ANTIBODY],
            TOTAL_ANTI_HAV_DT = H.[TOTAL_ANTI_HAV_DT],
            HEP_B_TOTAL_ANTIBODY = H.[HEP_B_TOTAL_ANTIBODY],
            TOTAL_ANTI_HBC_DT = H.[TOTAL_ANTI_HBC_DT],
            TOTAL_ANTI_HCV_DT = H.[TOTAL_ANTI_HCV_DT],
            HEP_D_TOTAL_ANTIBODY = H.[HEP_D_TOTAL_ANTIBODY],
            TOTAL_ANTI_HDV_DT = H.[TOTAL_ANTI_HDV_DT],
            HEP_E_TOTAL_ANTIBODY = H.[HEP_E_TOTAL_ANTIBODY],
            TOTAL_ANTI_HEV_DT = H.[TOTAL_ANTI_HEV_DT],
            VERIFIED_TEST_DT = H.[VERIFIED_TEST_DT],
            LEGACY_CASE_ID = H.[LEGACY_CASE_ID],
            DIABETES_IND = H.[DIABETES_IND],
            DIABETES_DX_DT = H.[DIABETES_DX_DT],
            PREGNANCY_DUE_DT = H.[PREGNANCY_DUE_DT],
            PAT_JUNDICED_IND = H.[PAT_JUNDICED_IND],
            PAT_PREV_AWARE_IND = H.[PAT_PREV_AWARE_IND],
            HEP_CARE_PROVIDER = H.[HEP_CARE_PROVIDER],
            TEST_REASON = H.[TEST_REASON],
            TEST_REASON_OTH = H.[TEST_REASON_OTH],
            SYMPTOMATIC_IND = H.[SYMPTOMATIC_IND],
            MTH_BORN_OUTSIDE_US = H.[MTH_BORN_OUTSIDE_US],
            MTH_ETHNICITY = H.[MTH_ETHNICITY],
            MTH_HBS_AG_PRIOR_POS = H.[MTH_HBS_AG_PRIOR_POS],
            MTH_POS_AFTER = H.[MTH_POS_AFTER],
            MTH_POS_TEST_DT = H.[MTH_POS_TEST_DT],
            MTH_RACE = H.[MTH_RACE],
            MTH_BIRTH_COUNTRY = H.[MTH_BIRTH_COUNTRY],
            NOT_SUBMIT_DT = H.[NOT_SUBMIT_DT],
            PAT_REPORTED_AGE = H.[PAT_REPORTED_AGE],
            PAT_REPORTED_AGE_UNIT = H.[PAT_REPORTED_AGE_UNIT],
            PAT_CITY = H.[PAT_CITY],
            PAT_COUNTRY = H.[PAT_COUNTRY],
            PAT_COUNTY = H.[PAT_COUNTY],
            PAT_CURR_GENDER = H.[PAT_CURR_GENDER],
            PAT_DOB = H.[PAT_DOB],
            PAT_ETHNICITY = H.[PAT_ETHNICITY],
            PAT_FIRST_NM = H.[PAT_FIRST_NM],
            PAT_LAST_NM = H.[PAT_LAST_NM],
            PAT_LOCAL_ID = H.[PAT_LOCAL_ID],
            PAT_MIDDLE_NM = H.[PAT_MIDDLE_NM],
            PAT_PREGNANT_IND = H.[PAT_PREGNANT_IND],
            PAT_RACE = H.[PAT_RACE],
            PAT_STATE = H.[PAT_STATE],
            PAT_STREET_ADDR_1 = H.[PAT_STREET_ADDR_1],
            PAT_STREET_ADDR_2 = H.[PAT_STREET_ADDR_2],
            PAT_ZIP_CODE = H.[PAT_ZIP_CODE],
            RPT_SRC_SOURCE_NM = H.[RPT_SRC_SOURCE_NM],
            RPT_SRC_STATE = H.[RPT_SRC_STATE],
            RPT_SRC_CD_DESC = H.[RPT_SRC_CD_DESC],
            BLD_EXPOSURE_IND = H.[BLD_EXPOSURE_IND],
            BLD_RECVD_IND = H.[BLD_RECVD_IND],
            BLD_RECVD_DT = H.[BLD_RECVD_DT],
            MED_DEN_BLD_CT_FRQ = H.[MED_DEN_BLD_CT_FRQ],
            MED_DEN_EMPLOYEE_IND = H.[MED_DEN_EMPLOYEE_IND],
            MED_DEN_EMP_EVER_IND = H.[MED_DEN_EMP_EVER_IND],
            CLOTFACTOR_PRIOR_1987 = H.[CLOTFACTOR_PRIOR_1987],
            BLD_CONTAM_IND = H.[BLD_CONTAM_IND],
            DEN_WORK_OR_SURG_IND = H.[DEN_WORK_OR_SURG_IND],
            HEMODIALYSIS_IND = H.[HEMODIALYSIS_IND],
            LT_HEMODIALYSIS_IND = H.[LT_HEMODIALYSIS_IND],
            HSPTL_PRIOR_ONSET_IND = H.[HSPTL_PRIOR_ONSET_IND],
            EVER_INJCT_NOPRSC_DRG = H.[EVER_INJCT_NOPRSC_DRG],
            INCAR_24PLUSHRS_IND = H.[INCAR_24PLUSHRS_IND],
            INCAR_6PLUS_MO_IND = H.[INCAR_6PLUS_MO_IND],
            EVER_INCAR_IND = H.[EVER_INCAR_IND],
            INCAR_TYPE_JAIL_IND = H.[INCAR_TYPE_JAIL_IND],
            INCAR_TYPE_PRISON_IND = H.[INCAR_TYPE_PRISON_IND],
            INCAR_TYPE_JUV_IND = H.[INCAR_TYPE_JUV_IND],
            LAST6PLUSMO_INCAR_PER = H.[LAST6PLUSMO_INCAR_PER],
            LAST6PLUSMO_INCAR_YR = H.[LAST6PLUSMO_INCAR_YR],
            OUTPAT_IV_INF_IND = H.[OUTPAT_IV_INF_IND],
            LTCARE_RESIDENT_IND = H.[LTCARE_RESIDENT_IND],
            LIFE_SEX_PRTNR_NBR = H.[LIFE_SEX_PRTNR_NBR],
            BLD_EXPOSURE_OTH = H.[BLD_EXPOSURE_OTH],
            PIERC_PRIOR_ONSET_INd = H.[PIERC_PRIOR_ONSET_IND],
            PIERC_PERF_LOC_OTH = H.[PIERC_PERF_LOC_OTH],
            PIERC_PERF_LOC = H.[PIERC_PERF_LOC],
            PUB_SAFETY_BLD_CT_FRQ = H.[PUB_SAFETY_BLD_CT_FRQ],
            PUB_SAFETY_WORKER_IND = H.[PUB_SAFETY_WORKER_IND],
            STD_TREATED_IND = H.[STD_TREATED_IND],
            STD_LAST_TREATMENT_YR = H.[STD_LAST_TREATMENT_YR],
            NON_ORAL_SURGERY_IND = H.[NON_ORAL_SURGERY_IND],
            TATT_PRIOR_ONSET_IND = H.[TATT_PRIOR_ONSET_IND],
            TATTOO_PERF_LOC = H.[TATTOO_PERF_LOC],
            TATT_PRIOR_LOC_OTH = H.[TATT_PRIOR_LOC_OTH],
            BLD_TRANSF_PRIOR_1992 = H.[BLD_TRANSF_PRIOR_1992],
            ORGN_TRNSP_PRIOR_1992 = H.[ORGN_TRNSP_PRIOR_1992],
            TRANSMISSION_MODE = H.[TRANSMISSION_MODE],
            HOUSEHOLD_TRAVEL_IND = H.[HOUSEHOLD_TRAVEL_IND],
            TRAVEL_OUT_USACAN_IND = H.[TRAVEL_OUT_USACAN_IND],
            TRAVEL_OUT_USACAN_LOC = H.[TRAVEL_OUT_USACAN_LOC],
            HOUSEHOLD_TRAVEL_LOC = H.[HOUSEHOLD_TRAVEL_LOC],
            TRAVEL_REASON = H.[TRAVEL_REASON],
            IMM_GLOB_RECVD_IND = H.[IMM_GLOB_RECVD_IND],
            GLOB_LAST_RECVD_YR = H.[GLOB_LAST_RECVD_YR],
            VACC_RECVD_IND = H.[VACC_RECVD_IND],
            VACC_DOSE_NBR_1 = H.[VACC_DOSE_NBR_1],
            VACC_RECVD_DT_1 = H.[VACC_RECVD_DT_1],
            VACC_DOSE_NBR_2 = H.[VACC_DOSE_NBR_2],
            VACC_RECVD_DT_2 = H.[VACC_RECVD_DT_2],
            VACC_DOSE_NBR_3 = H.[VACC_DOSE_NBR_3],
            VACC_RECVD_DT_3 = H.[VACC_RECVD_DT_3],
            VACC_DOSE_NBR_4 = H.[VACC_DOSE_NBR_4],
            VACC_RECVD_DT_4 = H.[VACC_RECVD_DT_4],
            VACC_GT_4_IND = H.[VACC_GT_4_IND],
            VACC_DOSE_RECVD_NBR = H.[VACC_DOSE_RECVD_NBR],
            VACC_LAST_RECVD_YR = H.[VACC_LAST_RECVD_YR],
            ANTI_HBSAG_TESTED_IND = H.[ANTI_HBSAG_TESTED_IND],
            CONDITION_CD = H.[CONDITION_CD],
            EVENT_DATE = H.[EVENT_DATE],
            IMPORT_FROM_CITY = H.[IMPORT_FROM_CITY],
            IMPORT_FROM_COUNTRY = H.[IMPORT_FROM_COUNTRY],
            IMPORT_FROM_COUNTY = H.[IMPORT_FROM_COUNTY],
            IMPORT_FROM_STATE = H.[IMPORT_FROM_STATE],
            INVESTIGATION_KEY = H.[INVESTIGATION_KEY],
            INVESTIGATOR_NAME = H.[INVESTIGATOR_NAME],
            PAT_ELECTRONIC_IND = H.[PAT_ELECTRONIC_IND],
            PHYS_CITY = H.[PHYS_CITY],
            PHYS_COUNTY = H.[PHYS_COUNTY],
            PHYS_NAME = H.[PHYS_NAME],
            PHYS_STATE = H.[PHYS_STATE],
            PROGRAM_JURISDICTION_OID = H.[PROGRAM_JURISDICTION_OID],
            RPT_SRC_CITY = H.[RPT_SRC_CITY],
            RPT_SRC_COUNTY = H.[RPT_SRC_COUNTY],
            RPT_SRC_COUNTY_CD = H.[RPT_SRC_COUNTY_CD],
            PHYSICIAN_UID = H.[PHYSICIAN_UID],
            PATIENT_UID = H.[PATIENT_UID],
            CASE_UID = H.[CASE_UID],
            INVESTIGATOR_UID = H.[INVESTIGATOR_UID],
            REPORTING_SOURCE_UID = H.[REPORTING_SOURCE_UID],
            REFRESH_DATETIME = H.[REFRESH_DATETIME],
            PAT_BIRTH_COUNTRY = H.[PAT_BIRTH_COUNTRY]
        FROM #TMP_HEPATITIS_CASE_BASE H WITH(NOLOCK)
        WHERE H.[CASE_UID] = [dbo].[HEPATITIS_DATAMART].[CASE_UID] AND
            H.[PATIENT_UID] = [dbo].[HEPATITIS_DATAMART].[PATIENT_UID] AND
            H.[INVESTIGATION_KEY] = [dbo].[HEPATITIS_DATAMART].[INVESTIGATION_KEY];

        COMMIT TRANSACTION;


        --------------------------------------27.-----Final ---Inserting into dbo.HEPATITIS_DATAMART----------------------------------------------
        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = 27;
        SET @PROC_STEP_NAME = 'Inserting new entries dbo.HEPATITIS_DATAMART';

        INSERT INTO dbo.[HEPATITIS_DATAMART]( INNC_NOTIFICATION_DT, ---1
                                              CASE_RPT_MMWR_WEEK, ---2
                                              CASE_RPT_MMWR_YEAR, ----3
                                              HEP_D_INFECTION_IND, ----4
                                              HEP_MEDS_RECVD_IND, ----5
                                              HEP_C_TOTAL_ANTIBODY, ----6
                                              DIAGNOSIS_DT, ------------7
                                              DIE_FRM_THIS_ILLNESS_IND, ----8
                                              DISEASE_IMPORTED_IND, -----9
                                              EARLIEST_RPT_TO_CNTY, ----10
                                              EARLIEST_RPT_TO_STATE_DT, ---11
                                              BINATIONAL_RPTNG_CRIT, ---12
                                              CHILDCARE_CASE_IND, ---13
                                              CNTRY_USUAL_RESIDENCE, ---14
                                              CT_BABYSITTER_IND, ---15
                                              CT_CHILDCARE_IND, ----16
                                              CT_HOUSEHOLD_IND, ---17
                                              HEP_CONTACT_IND, ----18
                                              HEP_CONTACT_EVER_IND, ----19
                                              OTHER_CONTACT_IND, ---20
                                              COM_SRC_OUTBREAK_IND, ---21
                                              CONTACT_TYPE_OTH, ----22
                                              CT_PLAYMATE_IND, ----23
                                              SEXUAL_PARTNER_IND, ----24
                                              DNP_HOUSEHOLD_CT_IND, ---25
                                              HEP_A_EPLINK_IND, ----25
                                              FEMALE_SEX_PRTNR_NBR, ---27
                                              FOODHNDLR_PRIOR_IND, ----28
                                              DNP_EMPLOYEE_IND, -----29
                                              STREET_DRUG_INJECTED, -----30
                                              MALE_SEX_PRTNR_NBR, ----31
                                              OUTBREAK_IND, -----32
                                              OBRK_FOODHNDLR_IND, ----33
                                              FOOD_OBRK_FOOD_ITEM, ----34
                                              OBRK_NOFOODHNDLR_IND, ----35
                                              OBRK_UNIDENTIFIED_IND, ----36
                                              OBRK_WATERBORNE_IND, ----37
                                              STREET_DRUG_USED, ---38
                                              SEX_PREF, ----39
                                              HSPTL_ADMISSION_DT, ----40
                                              HSPTL_DISCHARGE_DT, ----41
                                              HSPTL_DURATION_DAYS, ----42
                                              HSPTLIZD_IND, ---43
                                              ILLNESS_ONSET_DT, ----44
                                              INV_CASE_STATUS, ----45
                                              INV_COMMENTS, ----46
                                              INV_LOCAL_ID, ---47
                                              INV_RPT_DT, ---48
                                              INV_START_DT, ---49
                                              INVESTIGATION_STATUS, ---50
                                              JURISDICTION_NM, ---51
                                              ALT_SGPT_RESULT, ----52
                                              ANTI_HBS_POS_REAC_IND, -----53
                                              AST_SGOT_RESULT, ---54
                                              HEP_E_ANTIGEN, ----55
                                              HBE_AG_DT, ---56
                                              HEP_B_SURFACE_ANTIGEN, ----57
                                              HBS_AG_DT, ----58
                                              HEP_B_DNA, -----59
                                              HBV_NAT_DT, ----60
                                              HCV_RNA, ----61
                                              HCV_RNA_DT, ----62
                                              HEP_D_TEST_IND, ----63
                                              HEP_A_IGM_ANTIBODY, ----64
                                              IGM_ANTI_HAV_DT, ----65
                                              HEP_B_IGM_ANTIBODY, ----66
                                              IGM_ANTI_HBC_DT, ----67
                                              PREV_NEG_HEP_TEST_IND, ------68
                                              ANTIHCV_SIGCUT_RATIO, ----69
                                              ANTIHCV_SUPP_ASSAY, -----70
                                              SUPP_ANTI_HCV_DT, -----71
                                              ALT_RESULT_DT, ----72
                                              AST_RESULT_DT, -----73
                                              ALT_SGPT_RSLT_UP_LMT, ----74
                                              AST_SGOT_RSLT_UP_LMT, ----75
                                              HEP_A_TOTAL_ANTIBODY, ----76
                                              TOTAL_ANTI_HAV_DT, ----77
                                              HEP_B_TOTAL_ANTIBODY, ----78
                                              TOTAL_ANTI_HBC_DT, ----79
                                              TOTAL_ANTI_HCV_DT, ----80
                                              HEP_D_TOTAL_ANTIBODY, ----81
                                              TOTAL_ANTI_HDV_DT, ----82
                                              HEP_E_TOTAL_ANTIBODY, ----83
                                              TOTAL_ANTI_HEV_DT, ----84
                                              VERIFIED_TEST_DT, ----85
                                              LEGACY_CASE_ID, ---86
                                              DIABETES_IND, ----87
                                              DIABETES_DX_DT, ----88
                                              PREGNANCY_DUE_DT, ----89
                                              PAT_JUNDICED_IND, -----90
                                              PAT_PREV_AWARE_IND, ----91
                                              HEP_CARE_PROVIDER, ----92
                                              TEST_REASON, ------93
                                              TEST_REASON_OTH, -----94
                                              SYMPTOMATIC_IND, -----95
                                              MTH_BORN_OUTSIDE_US, ---96
                                              MTH_ETHNICITY, ------97
                                              MTH_HBS_AG_PRIOR_POS, ----98
                                              MTH_POS_AFTER, ------99
                                              MTH_POS_TEST_DT, ----100
                                              MTH_RACE, -----101
                                              MTH_BIRTH_COUNTRY, ----102
                                              NOT_SUBMIT_DT, ----103
                                              PAT_REPORTED_AGE, ----104
                                              PAT_REPORTED_AGE_UNIT, ----105
                                              PAT_CITY, ----106
                                              PAT_COUNTRY, ----107
                                              PAT_COUNTY, ----108
                                              PAT_CURR_GENDER, ---109
                                              PAT_DOB, ---110
                                              PAT_ETHNICITY, ---111
                                              PAT_FIRST_NM, ---112
                                              PAT_LAST_NM, ---113
                                              PAT_LOCAL_ID, ---114
                                              PAT_MIDDLE_NM, ---115
                                              PAT_PREGNANT_IND, ---116
                                              PAT_RACE, ----117
                                              PAT_STATE, ----118
                                              PAT_STREET_ADDR_1, ---119
                                              PAT_STREET_ADDR_2, ----120
                                              PAT_ZIP_CODE, ----121
                                              RPT_SRC_SOURCE_NM, ----122
                                              RPT_SRC_STATE, ----123
                                              RPT_SRC_CD_DESC, ---124
                                              BLD_EXPOSURE_IND, ----125
                                              BLD_RECVD_IND, ----126
                                              BLD_RECVD_DT, ----127
                                              MED_DEN_BLD_CT_FRQ, ----128
                                              MED_DEN_EMP_EVER_IND, ----129
                                              MED_DEN_EMPLOYEE_IND, ---130
                                              CLOTFACTOR_PRIOR_1987, ----131
                                              BLD_CONTAM_IND, ------132
                                              DEN_WORK_OR_SURG_IND, ----133
                                              HEMODIALYSIS_IND, ----134
                                              LT_HEMODIALYSIS_IND, -----135
                                              HSPTL_PRIOR_ONSET_IND, ----136
                                              EVER_INJCT_NOPRSC_DRG, -----137
                                              INCAR_24PLUSHRS_IND, ---138
                                              INCAR_6PLUS_MO_IND, ---139
                                              EVER_INCAR_IND, ----140
                                              INCAR_TYPE_JAIL_IND, ----141
                                              INCAR_TYPE_PRISON_IND, ----142
                                              INCAR_TYPE_JUV_IND, ----143
                                              LAST6PLUSMO_INCAR_PER, ----144
                                              LAST6PLUSMO_INCAR_YR, ----145
                                              OUTPAT_IV_INF_IND, ----146
                                              LTCARE_RESIDENT_IND, ----147
                                              LIFE_SEX_PRTNR_NBR, ----148
                                              BLD_EXPOSURE_OTH, ----149
                                              PIERC_PRIOR_ONSET_IND, ----150
                                              PIERC_PERF_LOC_OTH, ----151
                                              PIERC_PERF_LOC, -----152
                                              PUB_SAFETY_BLD_CT_FRQ, ----153
                                              PUB_SAFETY_WORKER_IND, ----154
                                              STD_TREATED_IND, ----155
                                              STD_LAST_TREATMENT_YR, ---156
                                              NON_ORAL_SURGERY_IND, ---157
                                              TATT_PRIOR_ONSET_IND, ---158
                                              TATTOO_PERF_LOC, ----158
                                              TATT_PRIOR_LOC_OTH, ----160
                                              BLD_TRANSF_PRIOR_1992, ---161
                                              ORGN_TRNSP_PRIOR_1992, ----162
                                              TRANSMISSION_MODE, ----163
                                              HOUSEHOLD_TRAVEL_IND, ----164
                                              TRAVEL_OUT_USACAN_IND, ----165
                                              TRAVEL_OUT_USACAN_LOC, -----166
                                              HOUSEHOLD_TRAVEL_LOC, ----167
                                              TRAVEL_REASON, -----168
                                              IMM_GLOB_RECVD_IND, ----169
                                              GLOB_LAST_RECVD_YR, ----170
                                              VACC_RECVD_IND, ----171
                                              VACC_DOSE_NBR_1, ----172
                                              VACC_RECVD_DT_1, ----173
                                              VACC_DOSE_NBR_2, ----174
                                              VACC_RECVD_DT_2, ----175
                                              VACC_DOSE_NBR_3, ----176
                                              VACC_RECVD_DT_3, -----177
                                              VACC_DOSE_NBR_4, -----178
                                              VACC_RECVD_DT_4, ---179
                                              VACC_GT_4_IND, -----180
                                              VACC_DOSE_RECVD_NBR, ----181
                                              VACC_LAST_RECVD_YR, -----182
                                              ANTI_HBSAG_TESTED_IND, ----183
                                              CONDITION_CD, -----184
                                              EVENT_DATE, ----185
                                              IMPORT_FROM_CITY, ----186
                                              IMPORT_FROM_COUNTRY, ----187
                                              IMPORT_FROM_COUNTY, ----188
                                              IMPORT_FROM_STATE, ----189
                                              INVESTIGATION_KEY, -----190
                                              INVESTIGATOR_NAME, -----191
                                              PAT_ELECTRONIC_IND, ----192
                                              PHYS_CITY, ----193
                                              PHYS_COUNTY, ----194
                                              PHYS_NAME, ----195
                                              PHYS_STATE, ----196
                                              PROGRAM_JURISDICTION_OID, ----197
                                              RPT_SRC_CITY, ---198
                                              RPT_SRC_COUNTY, ----199
                                              RPT_SRC_COUNTY_CD, ---200
                                              PHYSICIAN_UID, ----201
                                              PATIENT_UID, ----202
                                              CASE_UID, ---203
                                              INVESTIGATOR_UID, ---204
                                              REPORTING_SOURCE_UID, ---205
                                              REFRESH_DATETIME, ---206
                                              PAT_BIRTH_COUNTRY ----207
        )
        SELECT  INNC_NOTIFICATION_DT,
                CASE_RPT_MMWR_WEEK,
                CASE_RPT_MMWR_YEAR,
                cast(HEP_D_INFECTION_IND as varchar(300)),
                cast(HEP_MEDS_RECVD_IND as varchar(300)),
                cast(HEP_C_TOTAL_ANTIBODY as varchar(300)),
                DIAGNOSIS_DT,
                cast(DIE_FRM_THIS_ILLNESS_IND as varchar(300)),
                cast(DISEASE_IMPORTED_IND as varchar(300)),
                EARLIEST_RPT_TO_CNTY,
                EARLIEST_RPT_TO_STATE_DT,
                cast(BINATIONAL_RPTNG_CRIT as varchar(300)),
                cast(CHILDCARE_CASE_IND as varchar(300)),
                cast(CNTRY_USUAL_RESIDENCE as varchar(300)),
                cast(CT_BABYSITTER_IND as varchar(300)),
                cast(CT_CHILDCARE_IND as varchar(300)),
                cast(CT_HOUSEHOLD_IND as varchar(300)),
                cast(HEP_CONTACT_IND as varchar(300)),
                cast(HEP_CONTACT_EVER_IND as varchar(300)),
                cast(OTHER_CONTACT_IND as varchar(300)),
                cast(COM_SRC_OUTBREAK_IND as varchar(300)),
                cast(CONTACT_TYPE_OTH as varchar(100)),
                cast(CT_PLAYMATE_IND as varchar(300)),
                cast(SEXUAL_PARTNER_IND as varchar(300)),
                cast(DNP_HOUSEHOLD_CT_IND as varchar(300)),
                cast(HEP_A_EPLINK_IND as varchar(300)),
                FEMALE_SEX_PRTNR_NBR,
                cast(FOODHNDLR_PRIOR_IND as varchar(300)),
                cast(DNP_EMPLOYEE_IND as varchar(300)),
                cast(STREET_DRUG_INJECTED as varchar(300)),
                MALE_SEX_PRTNR_NBR,
                cast(OUTBREAK_IND as varchar(300)),
                cast(OBRK_FOODHNDLR_IND as varchar(300)),
                cast(FOOD_OBRK_FOOD_ITEM as varchar(100)),
                cast(OBRK_NOFOODHNDLR_IND as varchar(300)),
                cast(OBRK_UNIDENTIFIED_IND as varchar(300)),
                cast(OBRK_WATERBORNE_IND as varchar(300)),
                cast(STREET_DRUG_USED as varchar(300)),
                cast(SEX_PREF as varchar(300)),
                HSPTL_ADMISSION_DT,
                HSPTL_DISCHARGE_DT,
                HSPTL_DURATION_DAYS,
                cast(HSPTLIZD_IND as varchar(300)),
                ILLNESS_ONSET_DT,
                cast(INV_CASE_STATUS as varchar(300)),
                cast(INV_COMMENTS as varchar(2000)),
                cast(INV_LOCAL_ID as varchar(25)),
                INV_RPT_DT,
                INV_START_DT,
                cast(INVESTIGATION_STATUS as varchar(300)),
                cast(JURISDICTION_NM as varchar(300)),
                ALT_SGPT_RESULT,
                cast(ANTI_HBS_POS_REAC_IND as varchar(300)),
                AST_SGOT_RESULT,
                cast(HEP_E_ANTIGEN as varchar(300)),
                HBE_AG_DT,
                cast(HEP_B_SURFACE_ANTIGEN as varchar(300)),
                HBS_AG_DT,
                cast(HEP_B_DNA as varchar(300)),
                HBV_NAT_DT,
                cast(HCV_RNA as varchar(300)),
                HCV_RNA_DT,
                cast(HEP_D_TEST_IND as varchar(300)),
                cast(HEP_A_IGM_ANTIBODY as varchar(300)),
                IGM_ANTI_HAV_DT,
                cast(HEP_B_IGM_ANTIBODY as varchar(300)),
                IGM_ANTI_HBC_DT,
                cast(PREV_NEG_HEP_TEST_IND as varchar(300)),
                cast(ANTIHCV_SIGCUT_RATIO as varchar(25)),
                cast(ANTIHCV_SUPP_ASSAY as varchar(300)),
                SUPP_ANTI_HCV_DT,
                ALT_RESULT_DT,
                AST_RESULT_DT,
                ALT_SGPT_RSLT_UP_LMT,
                AST_SGOT_RSLT_UP_LMT,
                cast(HEP_A_TOTAL_ANTIBODY as varchar(300)),
                TOTAL_ANTI_HAV_DT,
                cast(HEP_B_TOTAL_ANTIBODY as varchar(300)),
                TOTAL_ANTI_HBC_DT,
                TOTAL_ANTI_HCV_DT,
                cast(HEP_D_TOTAL_ANTIBODY as varchar(300)),
                TOTAL_ANTI_HDV_DT,
                cast(HEP_E_TOTAL_ANTIBODY as varchar(300)),
                TOTAL_ANTI_HEV_DT,
                VERIFIED_TEST_DT,
                cast(LEGACY_CASE_ID as varchar(15)),
                cast(DIABETES_IND as varchar(300)),
                DIABETES_DX_DT,
                PREGNANCY_DUE_DT,
                cast(PAT_JUNDICED_IND as varchar(300)),
                cast(PAT_PREV_AWARE_IND as varchar(300)),
                cast(HEP_CARE_PROVIDER as varchar(300)),
                cast(TEST_REASON as varchar(300)),
                cast(TEST_REASON_OTH as varchar(150)),
                cast(SYMPTOMATIC_IND as varchar(300)),
                cast(MTH_BORN_OUTSIDE_US as varchar(300)),
                cast(MTH_ETHNICITY as varchar(300)),
                cast(MTH_HBS_AG_PRIOR_POS as varchar(300)),
                cast(MTH_POS_AFTER as varchar(300)),
                MTH_POS_TEST_DT,
                cast(MTH_RACE as varchar(300)),
                cast(MTH_BIRTH_COUNTRY as varchar(300)),
                NOT_SUBMIT_DT,
                PAT_REPORTED_AGE,
                cast(PAT_REPORTED_AGE_UNIT as varchar(300)),
                cast(PAT_CITY as varchar(50)),
                cast(PAT_COUNTRY as varchar(300)),
                cast(PAT_COUNTY as varchar(300)),
                cast(PAT_CURR_GENDER as varchar(300)),
                PAT_DOB,
                cast(PAT_ETHNICITY as varchar(300)),
                cast(PAT_FIRST_NM as varchar(50)),
                cast(PAT_LAST_NM as varchar(50)),
                cast(PAT_LOCAL_ID as varchar(25)),
                cast(PAT_MIDDLE_NM as varchar(50)),
                cast(PAT_PREGNANT_IND as varchar(300)),
                cast(PAT_RACE as varchar(300)),
                cast(PAT_STATE as varchar(300)),
                cast(PAT_STREET_ADDR_1 as varchar(50)),
                cast(PAT_STREET_ADDR_2 as varchar(50)),
                cast(PAT_ZIP_CODE as varchar(10)),
                cast(RPT_SRC_SOURCE_NM as varchar(300)),
                cast(RPT_SRC_STATE as varchar(300)),
                cast(RPT_SRC_CD_DESC as varchar(300)),
                cast(BLD_EXPOSURE_IND as varchar(300)),
                cast(BLD_RECVD_IND as varchar(300)),
                BLD_RECVD_DT,
                cast(MED_DEN_BLD_CT_FRQ as varchar(300)),
                cast(MED_DEN_EMP_EVER_IND as varchar(300)),
                cast(MED_DEN_EMPLOYEE_IND as varchar(300)),
                cast(CLOTFACTOR_PRIOR_1987 as varchar(300)),
                cast(BLD_CONTAM_IND as varchar(300)),
                cast(DEN_WORK_OR_SURG_IND as varchar(300)),
                cast(HEMODIALYSIS_IND as varchar(300)),
                cast(LT_HEMODIALYSIS_IND as varchar(300)),
                cast(HSPTL_PRIOR_ONSET_IND as varchar(300)),
                cast(EVER_INJCT_NOPRSC_DRG as varchar(300)),
                cast(INCAR_24PLUSHRS_IND as varchar(300)),
                cast(INCAR_6PLUS_MO_IND as varchar(300)),
                cast(EVER_INCAR_IND as varchar(300)),
                cast(INCAR_TYPE_JAIL_IND as varchar(300)),
                cast(INCAR_TYPE_PRISON_IND as varchar(300)),
                cast(INCAR_TYPE_JUV_IND as varchar(300)),
                LAST6PLUSMO_INCAR_PER,
                LAST6PLUSMO_INCAR_YR,
                cast(OUTPAT_IV_INF_IND as varchar(300)),
                cast(LTCARE_RESIDENT_IND as varchar(300)),
                LIFE_SEX_PRTNR_NBR,
                cast(BLD_EXPOSURE_OTH as varchar(200)),
                cast(PIERC_PRIOR_ONSET_IND as varchar(300)),
                cast(PIERC_PERF_LOC_OTH as varchar(150)),
                cast(PIERC_PERF_LOC as varchar(300)),
                cast(PUB_SAFETY_BLD_CT_FRQ as varchar(300)),
                cast(PUB_SAFETY_WORKER_IND as varchar(300)),
                cast(STD_TREATED_IND as varchar(300)),
                STD_LAST_TREATMENT_YR,
                cast(NON_ORAL_SURGERY_IND as varchar(300)),
                cast(TATT_PRIOR_ONSET_IND as varchar(300)),
                cast(TATTOO_PERF_LOC as varchar(300)),
                cast(TATT_PRIOR_LOC_OTH as varchar(150)),
                cast(BLD_TRANSF_PRIOR_1992 as varchar(300)),
                cast(ORGN_TRNSP_PRIOR_1992 as varchar(300)),
                cast(TRANSMISSION_MODE as varchar(300)),
                cast(HOUSEHOLD_TRAVEL_IND as varchar(300)),
                cast(TRAVEL_OUT_USACAN_IND as varchar(300)),
                cast(TRAVEL_OUT_USACAN_LOC as varchar(300)),
                cast(HOUSEHOLD_TRAVEL_LOC as varchar(300)),
                cast(TRAVEL_REASON as varchar(300)),
                cast(IMM_GLOB_RECVD_IND as varchar(300)),
                GLOB_LAST_RECVD_YR,
                cast(cast(VACC_RECVD_IND as varchar(10)) as varchar(10)),
                VACC_DOSE_NBR_1,
                VACC_RECVD_DT_1,
                VACC_DOSE_NBR_2,
                VACC_RECVD_DT_2,
                VACC_DOSE_NBR_3,
                VACC_RECVD_DT_3,
                VACC_DOSE_NBR_4,
                VACC_RECVD_DT_4,
                cast(VACC_GT_4_IND as varchar(300)),
                VACC_DOSE_RECVD_NBR,
                VACC_LAST_RECVD_YR,
                cast(ANTI_HBSAG_TESTED_IND as varchar(300)),
                cast(CONDITION_CD as varchar(300)),
                EVENT_DATE,
                cast(IMPORT_FROM_CITY as varchar(300)),
                cast(IMPORT_FROM_COUNTRY as varchar(300)),
                cast(IMPORT_FROM_COUNTY as varchar(300)),
                cast(IMPORT_FROM_STATE as varchar(300)),
                INVESTIGATION_KEY,
                cast(INVESTIGATOR_NAME as varchar(300)),
                cast(PAT_ELECTRONIC_IND as varchar(300)),
                cast(PHYS_CITY as varchar(300)),
                cast(PHYS_COUNTY as varchar(300)),
                cast(PHYS_NAME as varchar(300)),
                cast(PHYS_STATE as varchar(300)),
                PROGRAM_JURISDICTION_OID,
                cast(RPT_SRC_CITY as varchar(300)),
                cast(RPT_SRC_COUNTY as varchar(300)),
                cast(RPT_SRC_COUNTY_CD as varchar(300)),
                PHYSICIAN_UID,
                PATIENT_UID,
                CASE_UID,
                INVESTIGATOR_UID,
                REPORTING_SOURCE_UID,
                REFRESH_DATETIME,
                cast(PAT_BIRTH_COUNTRY as varchar(50))
        FROM #TMP_HEPATITIS_CASE_BASE  TH WITH(NOLOCK)
        WHERE NOT EXISTS
                  (
                      SELECT *
                      FROM [dbo].[HEPATITIS_DATAMART] WITH(NOLOCK)
                      WHERE [CASE_UID] = TH.[CASE_UID] AND
                          [PATIENT_UID] = TH.[PATIENT_UID] AND
                          [INVESTIGATION_KEY] = TH.[INVESTIGATION_KEY]
                  )
        ORDER BY INVESTIGATION_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]( BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] )
        VALUES( @BATCH_ID, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO );

        COMMIT TRANSACTION;

        if @debug = 'true' select * from  #TMP_HEPATITIS_CASE_BASE;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = 27;
        SET @PROC_STEP_NAME = 'Updating EVENT DATE AND TYPE in Hepatitis_Case_DATAMART';


        IF @debug = 'true' SELECT 'TMP_Event-caselab', * FROM  #TMP_Event;


        UPDATE ISD
        SET ISD.EVENT_DATE = E.EVENT_DATE,
            ISD.EVENT_DATE_TYPE = E.EVENT_DATE_TYPE
        FROM dbo.[HEPATITIS_DATAMART] ISD
                 LEFT OUTER JOIN #TMP_Event E WITH (NOLOCK) ON E.INVESTIGATION_KEY=ISD.INVESTIGATION_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'HEPATITIS_DATAMART','Hepatitis_Case_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no =  28;
        SET @PROC_STEP_NAME = 'Updating INIT_NND_NOTF_DT in HEPATITIS_DATAMART';

        IF @debug = 'true' SELECT 'TMP_Notif-caselab', * FROM #TMP_Notif;


        UPDATE ISD
        SET ISD.INIT_NND_NOT_DT = NND.FIRSTNOTIFICATIONSENDDATE
        FROM dbo.[HEPATITIS_DATAMART] ISD
                 LEFT JOIN #TMP_Notif NND with (nolock) ON ISD.INVESTIGATION_KEY = NND.INVESTIGATION_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'HEPATITIS_DATAMART','Hepatitis_Case_DATAMART','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


---------------------------------------------------------------------------Dropping All TMP Tables------------------------------------------------------------

        SELECT 'Transaction_count',@@TRANCOUNT;

        IF @@TRANCOUNT > 0
            BEGIN
                select 'COMMIT 1';

                COMMIT TRANSACTION;
            END;

        -------------------------------------------------------------------------------------------------------------------------
        BEGIN TRANSACTION;

        SET @Proc_Step_no = 29;

        SET @Proc_Step_Name = 'SP_COMPLETE';

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @batch_id, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'COMPLETE', @Proc_Step_no, @Proc_Step_name, @RowCount_no );


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
        VALUES( @Batch_id, 'HEPATITIS_DATAMART', 'Hepatitis_Case_DATAMART', 'ERROR', @Proc_Step_no, 'ERROR - ' + @Proc_Step_name, 'Step -' + CAST(@Proc_Step_no AS varchar(3)) + ' -' + CAST(@ErrorMessage AS varchar(500)), 0 );

        RETURN -1;

    END CATCH;

END;

---First begin;