IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_morbidity_report_datamart_postprocessing]')
                                      AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
    BEGIN
        DROP PROCEDURE [dbo].[sp_morbidity_report_datamart_postprocessing]
    END
GO

CREATE PROCEDURE dbo.sp_morbidity_report_datamart_postprocessing(
    @obs_uids NVARCHAR(MAX),
    @pat_uids NVARCHAR(MAX),
    @prov_uids NVARCHAR(MAX),
    @org_uids NVARCHAR(MAX),
    @inv_uids NVARCHAR(MAX),
    @debug bit = 'false')
as

BEGIN

    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';

    DECLARE @Dataflow_Name VARCHAR(200) = 'MORBIDITY_REPORT_DATAMART Post-Processing Event';
    DECLARE @Package_Name VARCHAR(200) = 'sp_morbidity_report_datamart_postprocessing';



    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';
        DECLARE @batch_id bigint;
        SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmssffff')) AS bigint);

        if @debug = 'true' select @batch_id;


        SELECT @ROWCOUNT_NO = 0;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT], [msg_description1])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO, LEFT('OBS_ID List-' + @obs_uids, 500));

        /*
            Create temp table containing necessary codes
        */
        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #SRTLOOKUP';

        SELECT  CODE,
                CODE_DESC_TXT,
                CODE_SET_NM,
                CODE_SHORT_DESC_TXT
        INTO #SRTLOOKUP
        FROM dbo.nrt_srte_Code_value_general WITH (NOLOCK)
        WHERE CODE_SET_NM IN('MORB_RPT_TYPE','MRB_RPT_METH','P_NM_SFX','AGE_UNIT','YNU');

        if @debug = 'true'
            SELECT @Proc_Step_Name, * from #SRTLOOKUP;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #MORB_EVENT_INIT';

        SELECT
            MR.MORB_RPT_KEY AS MORBIDITY_REPORT_KEY,
            MRE.PATIENT_KEY AS PERSON_KEY,
            MR.MORB_RPT_LOCAL_ID AS MORBIDITY_REPORT_LOCAL_ID,
            MR.JURISDICTION_NM AS JURISDICTION_NAME,
            MR.MORB_RPT_TYPE,
            MR.MORB_RPT_DELIVERY_METHOD,
            MR.PH_RECEIVE_DT AS PH_RECEIVE_DT,
            MR.DIAGNOSIS_DT AS DIAGNOSIS_DATE,
            MR.HSPTL_ADMISSION_DT AS HOSPITAL_ADMIN_DATE,
            MR.NURSING_HOME_ASSOCIATE_IND,
            MR.HEALTHCARE_ORG_ASSOCIATE_IND,
            MR.SUSPECT_FOOD_WTRBORNE_ILLNESS,
            MR.MORB_RPT_OTHER_SPECIFY AS OTHER_EPI,
            MR.MORB_RPT_OID AS PROGRAM_JURISDICTION_OID,
            MR.DIE_FROM_ILLNESS_IND,
            MR.HOSPITALIZED_IND,
            MR.PREGNANT_IND,
            MR.FOOD_HANDLER_IND,
            MR.DAYCARE_IND,
            MR.MORB_RPT_COMMENTS AS MORB_RPT_COMMENTS,
            MR.ELECTRONIC_IND AS ELECTRONIC_IND_CD,
            IIF(MR.ELECTRONIC_IND = 'E', 'Yes', 'No') AS EXTERNAL_IND,
            MR.RECORD_STATUS_CD,
            MRE.MORB_RPT_DT_KEY,
            MRE.ILLNESS_ONSET_DT_KEY,
            MRE.HSPTL_DISCHARGE_DT_KEY,
            MRE.CONDITION_KEY,
            pat.PATIENT_LOCAL_ID AS PATIENT_LOCAL_ID,
            pat.PATIENT_GENERAL_COMMENTS AS PATIENT_GENERAL_COMMENTS,
            pat.PATIENT_DOB AS PATIENT_DOB,
            pat.PATIENT_AGE_REPORTED AS AGE_REPORTED,
            pat.PATIENT_AGE_REPORTED_UNIT AS AGE_REPORTED_UNIT,
            pat.PATIENT_CURRENT_SEX AS PATIENT_CURRENT_SEX,
            pat.PATIENT_DECEASED_INDICATOR AS PATIENT_DECEASED_INDICATOR,
            pat.PATIENT_DECEASED_DATE AS PATIENT_DECEASED_DATE,
            pat.PATIENT_MARITAL_STATUS AS PATIENT_MARITAL_STATUS,
            pat.PATIENT_SSN AS PATIENT_SSN,
            pat.PATIENT_ETHNICITY AS PATIENT_ETHNICITY,
            pat.PATIENT_FIRST_NAME AS PATIENT_FIRST_NAME,
            pat.PATIENT_MIDDLE_NAME AS PATIENT_MIDDLE_NAME,
            pat.PATIENT_LAST_NAME AS PATIENT_LAST_NAME,
            pat.PATIENT_NAME_SUFFIX AS PATIENT_NAME_SUFFIX,
            pat.PATIENT_STREET_ADDRESS_1 AS PATIENT_STREET_ADDRESS_1,
            pat.PATIENT_STREET_ADDRESS_2 AS PATIENT_STREET_ADDRESS_2,
            pat.PATIENT_CITY AS PATIENT_CITY,
            pat.PATIENT_STATE AS PATIENT_STATE,
            pat.PATIENT_ZIP AS PATIENT_ZIP,
            pat.PATIENT_COUNTY AS PATIENT_COUNTY,
            pat.PATIENT_COUNTRY AS PATIENT_COUNTRY,
            pat.PATIENT_PHONE_HOME AS PATIENT_PHONE_NUMBER_HOME,
            pat.PATIENT_PHONE_EXT_HOME AS PATIENT_PHONE_EXT_HOME,
            pat.PATIENT_PHONE_WORK AS PATIENT_PHONE_NUMBER_WORK,
            pat.PATIENT_PHONE_EXT_WORK AS PATIENT_PHONE_EXT_WORK,
            pat.PATIENT_RACE_CALCULATED AS RACE_CALCULATED,
            pat.PATIENT_RACE_CALC_DETAILS AS RACE_CALCULATED_DETAILS,
            prov.PROVIDER_LAST_NAME AS PROVIDER_LAST_NAME,
            prov.PROVIDER_FIRST_NAME AS PROVIDER_FIRST_NAME,
            prov.PROVIDER_STREET_ADDRESS_1 AS PROVIDER_STREET_ADDR_1,
            prov.PROVIDER_STREET_ADDRESS_2 AS PROVIDER_STREET_ADDR_2,
            prov.PROVIDER_CITY AS PROVIDER_CITY,
            prov.PROVIDER_STATE AS PROVIDER_STATE,
            prov.PROVIDER_ZIP AS PROVIDER_ZIP,
            prov.PROVIDER_PHONE_WORK AS PROVIDER_PHONE,
            prov.PROVIDER_PHONE_EXT_WORK AS PROVIDER_PHONE_EXT,
            rep.PROVIDER_LAST_NAME AS REPORTER_LAST_NAME,
            rep.PROVIDER_FIRST_NAME AS REPORTER_FIRST_NAME,
            rep.PROVIDER_STREET_ADDRESS_1 AS REPORTER_STREET_ADDR_1,
            rep.PROVIDER_STREET_ADDRESS_2 AS REPORTER_STREET_ADDR_2,
            rep.PROVIDER_CITY AS REPORTER_CITY,
            rep.PROVIDER_STATE AS REPORTER_STATE,
            rep.PROVIDER_ZIP AS REPORTER_ZIP,
            rep.PROVIDER_PHONE_WORK AS REPORTER_PHONE,
            rep.PROVIDER_PHONE_EXT_WORK AS REPORTER_PHONE_EXT,
            rep_fac.ORGANIZATION_UID AS REPORTING_FACILITY_UID,
            rep_fac.ORGANIZATION_NAME AS REPORT_FAC_NAME,
            rep_fac.ORGANIZATION_STREET_ADDRESS_1 AS REPORT_FAC_STREET_ADDR_1,
            NULLIF(rep_fac.ORGANIZATION_STREET_ADDRESS_2, '') AS REPORT_FAC_STREET_ADDR_2,
            rep_fac.ORGANIZATION_CITY AS REPORT_FAC_CITY,
            rep_fac.ORGANIZATION_STATE AS REPORT_FAC_STATE,
            rep_fac.ORGANIZATION_ZIP AS REPORT_FAC_ZIP,
            rep_fac.ORGANIZATION_PHONE_WORK AS REPORT_FAC_PHONE,
            NULLIF(rep_fac.ORGANIZATION_PHONE_EXT_WORK, '') AS REPORT_FAC_PHONE_EXT,
            EM.PROG_AREA_DESC_TXT AS PROGRAM_AREA_DESCRIPTION,
            hsptl.ORGANIZATION_NAME AS HOSPITAL_FAC_NAME,
            hsptl.ORGANIZATION_STREET_ADDRESS_1 AS HOSPITAL_FAC_STREET_ADDR_1,
            NULLIF(hsptl.ORGANIZATION_STREET_ADDRESS_2, '') AS HOSPITAL_FAC_STREET_ADDR_2,
            hsptl.ORGANIZATION_CITY AS HOSPITAL_FAC_CITY,
            hsptl.ORGANIZATION_STATE AS HOSPITAL_FAC_STATE,
            hsptl.ORGANIZATION_ZIP AS HOSPITAL_FAC_ZIP,
            hsptl.ORGANIZATION_PHONE_WORK AS HOSPITAL_FAC_PHONE,
            NULLIF(hsptl.ORGANIZATION_PHONE_EXT_WORK, '') AS HOSPITAL_FAC_PHONE_EXT,
            EM.ADD_TIME AS MORB_REPORT_CREATE_DATE,
            EM.ADD_USER_ID,
            EM.LAST_CHG_TIME AS MORB_REPORT_LAST_UPDATED_DATE,
            EM.LAST_CHG_USER_ID,
            inv.INV_CASE_STATUS AS CASE_STATUS,
            IIF(COALESCE(inv.INVESTIGATION_KEY, 1) = 1, 'No', 'Yes') AS INVESTIGATION_CREATED_IND,
            NULLIF( inv.INVESTIGATION_KEY, 1) AS  INVESTIGATION_KEY,
            CASE
                WHEN CHARINDEX(',', EM.add_user_name) > 0
                    THEN TRIM(LEFT(EM.add_user_name, CHARINDEX(',', EM.add_user_name) - 1))
                ELSE EM.add_user_name
                END AS add_user_last_name,
            CASE
                WHEN CHARINDEX(',', EM.add_user_name) > 0
                    THEN TRIM(RIGHT(EM.add_user_name, LEN(EM.add_user_name) - CHARINDEX(',', EM.add_user_name)))
                ELSE ''
                END AS add_user_first_name,
            CASE
                WHEN CHARINDEX(',', EM.last_chg_user_name) > 0
                    THEN TRIM(LEFT(EM.last_chg_user_name, CHARINDEX(',', EM.last_chg_user_name) - 1))
                ELSE EM.last_chg_user_name
                END AS last_chg_user_last_name,
            CASE
                WHEN CHARINDEX(',', EM.last_chg_user_name) > 0
                    THEN TRIM(RIGHT(EM.last_chg_user_name, LEN(EM.last_chg_user_name) - CHARINDEX(',', EM.last_chg_user_name)))
                ELSE ''
                END AS last_chg_user_first_name,
            IIF(MRD.MORBIDITY_REPORT_KEY IS NULL, 'I', 'U') AS DML_IND
        INTO #MORB_EVENT_INIT
        FROM dbo.MORBIDITY_REPORT MR WITH (NOLOCK)
                 LEFT JOIN dbo.MORBIDITY_REPORT_EVENT MRE WITH (NOLOCK)
                           ON MR.MORB_RPT_KEY = MRE.MORB_RPT_KEY
                 LEFT JOIN dbo.MORBIDITY_REPORT_DATAMART MRD WITH (NOLOCK)
                           ON MR.MORB_RPT_KEY = MRD.MORBIDITY_REPORT_KEY
                 LEFT JOIN dbo.D_PATIENT pat WITH (NOLOCK)
                           ON MRE.PATIENT_KEY = pat.PATIENT_KEY
                 LEFT JOIN dbo.D_PROVIDER prov WITH (NOLOCK)
                           ON MRE.PHYSICIAN_KEY = prov.PROVIDER_KEY
                 LEFT JOIN dbo.D_PROVIDER rep WITH (NOLOCK)
                           ON MRE.REPORTER_KEY = rep.PROVIDER_KEY
                 LEFT JOIN dbo.D_ORGANIZATION rep_fac WITH (NOLOCK)
                           ON MRE.MORB_RPT_SRC_ORG_KEY = rep_fac.ORGANIZATION_KEY
                 LEFT JOIN dbo.D_ORGANIZATION hsptl WITH (NOLOCK)
                           ON MRE.HSPTL_KEY = hsptl.ORGANIZATION_KEY
                 LEFT JOIN dbo.INVESTIGATION inv WITH (NOLOCK)
                           ON MRE.INVESTIGATION_KEY = inv.INVESTIGATION_KEY
                 LEFT JOIN dbo.EVENT_METRIC EM WITH (NOLOCK)
                           ON MR.MORB_RPT_UID = EM.EVENT_UID
        WHERE
            (inv.CASE_UID IN (SELECT value FROM STRING_SPLIT(@inv_uids, ','))
                OR
             pat.PATIENT_UID IN (SELECT value FROM STRING_SPLIT(@pat_uids, ','))
                OR
             prov.PROVIDER_UID IN (SELECT value FROM STRING_SPLIT(@prov_uids, ','))
                OR
             rep.PROVIDER_UID IN (SELECT value FROM STRING_SPLIT(@prov_uids, ','))
                OR
             rep_fac.ORGANIZATION_UID IN (SELECT value FROM STRING_SPLIT(@org_uids, ','))
                OR
             hsptl.ORGANIZATION_UID IN (SELECT value FROM STRING_SPLIT(@org_uids, ','))
                OR
             CAST(mr.MORB_RPT_UID AS bigint) IN (SELECT value FROM STRING_SPLIT(@obs_uids, ','))
                )
          AND MR.MORB_RPT_KEY <> 1
          AND MR.RECORD_STATUS_CD = 'ACTIVE';

        if @debug = 'true'
            SELECT @Proc_Step_Name, * from #MORB_EVENT_INIT;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #INACTIVE_MORB';

        SELECT
            MR.MORB_RPT_KEY AS MORBIDITY_REPORT_KEY
        INTO #INACTIVE_MORB
        FROM dbo.MORBIDITY_REPORT MR WITH (NOLOCK)
        WHERE
            CAST(MR.MORB_RPT_UID AS bigint) IN (SELECT value FROM STRING_SPLIT(@obs_uids, ','))
          AND MR.RECORD_STATUS_CD = 'INACTIVE';

        if @debug = 'true'
            SELECT @Proc_Step_Name, * from #INACTIVE_MORB;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #MORB_TO_LAB_KEYS';

        SELECT LT.LAB_RPT_LOCAL_ID, LT.CLINICAL_INFORMATION AS SPECIMEN_SOURCE, M.MORBIDITY_REPORT_KEY, LT.LAB_TEST_TYPE,
               LT.lab_test_key
        INTO #MORB_TO_LAB_KEYS
        FROM #MORB_EVENT_INIT  M WITH (NOLOCK) INNER JOIN
             dbo.LAB_TEST_RESULT LTR WITH (NOLOCK) ON M.MORBIDITY_REPORT_KEY = LTR.MORB_RPT_KEY INNER JOIN
             dbo.LAB_TEST LT WITH (NOLOCK) ON LTR.LAB_TEST_KEY = LT.LAB_TEST_KEY
        WHERE M.MORBIDITY_REPORT_KEY != 1 AND M.RECORD_STATUS_CD = 'ACTIVE';

        if @debug = 'true'
            SELECT @Proc_Step_Name, * from #MORB_TO_LAB_KEYS;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        /*
            For treatments and lab results, only three are necessary for calculations,
            so a row number will be assigned and only the first three rows will be joined
            back onto the original table to flatten the data.
        */
        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #MORB_LAB_RESULTS';

        SELECT
            m.MORBIDITY_REPORT_KEY,
            m.SPECIMEN_SOURCE,
            LT.LAB_RPT_LOCAL_ID,
            LT.SPECIMEN_COLLECTION_DT AS SPECIMEN_COLLECTION_DATE_,
            LT.LAB_TEST_CD_DESC AS RESULTED_TEST_NAME_,
            LT.LAB_TEST_DT AS LAB_REPORT_DATE_,
            LRV.TEST_RESULT_VAL_CD_DESC AS RESULTED_TEST_RESULT_,
            LRV.NUMERIC_RESULT,
            LRV.RESULT_UNITS,
            NULLIF(CONCAT(TRIM(LRV.NUMERIC_RESULT), ' ', TRIM(LRV.RESULT_UNITS)), '') AS RESULTED_TEST_NUMERIC_CONCAT_,
            LRV.LAB_RESULT_TXT_VAL AS RESULTED_TEST_TEXT_RESULT_,
            LRC.LAB_RESULT_COMMENTS AS LAB_RESULT_COMMENTS_,
            ROW_NUMBER() OVER (PARTITION BY m.MORBIDITY_REPORT_KEY ORDER BY lt.LAB_RPT_LOCAL_ID) AS row_num
        INTO #MORB_LAB_RESULTS
        FROM
            dbo.LAB_TEST LT WITH (NOLOCK)
                INNER JOIN
            dbo.LAB_TEST_RESULT LTR WITH (NOLOCK)
            ON LT.LAB_TEST_KEY = LTR.LAB_TEST_KEY
                INNER JOIN
            dbo.LAB_RESULT_VAL LRV WITH (NOLOCK)
            ON LTR.TEST_RESULT_GRP_KEY = LRV.TEST_RESULT_GRP_KEY
                INNER JOIN
            dbo.LAB_RESULT_COMMENT LRC WITH (NOLOCK)
            ON LTR.RESULT_COMMENT_GRP_KEY = LRC.RESULT_COMMENT_GRP_KEY
                INNER JOIN #MORB_TO_LAB_KEYS m
                           on m.LAB_RPT_LOCAL_ID = lt.LAB_RPT_LOCAL_ID
        WHERE LT.LAB_TEST_TYPE = 'Result';

        if @debug = 'true'
            SELECT @Proc_Step_Name, * from #MORB_LAB_RESULTS;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #MORB_LAB_FLATTENED';

        SELECT
            morb.MORBIDITY_REPORT_KEY,
            ml1.SPECIMEN_COLLECTION_DATE_ AS SPECIMEN_COLLECTION_DATE_1,
            ml1.RESULTED_TEST_NAME_ AS RESULTED_TEST_NAME_1,
            ml1.LAB_REPORT_DATE_ AS LAB_REPORT_DATE_1,
            ml1.RESULTED_TEST_RESULT_ AS RESULTED_TEST_RESULT_1,
            ml1.RESULTED_TEST_TEXT_RESULT_ AS RESULTED_TEST_TEXT_RESULT_1,
            ml1.LAB_RESULT_COMMENTS_ AS LAB_RESULT_COMMENTS_1,
            ml1.RESULTED_TEST_NUMERIC_CONCAT_ AS RESULTED_TEST_NUMERIC_CONCAT_1,
            ml1.SPECIMEN_SOURCE AS SPECIMEN_SOURCE_1,
            ml2.SPECIMEN_COLLECTION_DATE_ AS SPECIMEN_COLLECTION_DATE_2,
            ml2.RESULTED_TEST_NAME_ AS RESULTED_TEST_NAME_2,
            ml2.LAB_REPORT_DATE_ AS LAB_REPORT_DATE_2,
            ml2.RESULTED_TEST_RESULT_ AS RESULTED_TEST_RESULT_2,
            ml2.RESULTED_TEST_TEXT_RESULT_ AS RESULTED_TEST_TEXT_RESULT_2,
            ml2.LAB_RESULT_COMMENTS_ AS LAB_RESULT_COMMENTS_2,
            ml2.RESULTED_TEST_NUMERIC_CONCAT_ AS RESULTED_TEST_NUMERIC_CONCAT_2,
            ml2.SPECIMEN_SOURCE AS SPECIMEN_SOURCE_2,
            ml3.SPECIMEN_COLLECTION_DATE_ AS SPECIMEN_COLLECTION_DATE_3,
            ml3.RESULTED_TEST_NAME_ AS RESULTED_TEST_NAME_3,
            ml3.LAB_REPORT_DATE_ AS LAB_REPORT_DATE_3,
            ml3.RESULTED_TEST_RESULT_ AS RESULTED_TEST_RESULT_3,
            ml3.RESULTED_TEST_TEXT_RESULT_ AS RESULTED_TEST_TEXT_RESULT_3,
            ml3.LAB_RESULT_COMMENTS_ AS LAB_RESULT_COMMENTS_3,
            ml3.RESULTED_TEST_NUMERIC_CONCAT_ AS RESULTED_TEST_NUMERIC_CONCAT_3,
            ml3.SPECIMEN_SOURCE AS SPECIMEN_SOURCE_3,
            IIF(morb.max_row > 3, 'Yes', 'No') AS LAB_GT3_CREATED_IND
        INTO #MORB_LAB_FLATTENED
        FROM
            (SELECT MORBIDITY_REPORT_KEY, MAX(row_num) as max_row
             FROM #MORB_LAB_RESULTS
             GROUP BY MORBIDITY_REPORT_KEY) as morb
                LEFT JOIN #MORB_LAB_RESULTS ml1
                          ON morb.MORBIDITY_REPORT_KEY = ml1.MORBIDITY_REPORT_KEY AND ml1.row_num = 1
                LEFT JOIN #MORB_LAB_RESULTS ml2
                          ON morb.MORBIDITY_REPORT_KEY = ml2.MORBIDITY_REPORT_KEY AND ml2.row_num = 2
                LEFT JOIN #MORB_LAB_RESULTS ml3
                          ON morb.MORBIDITY_REPORT_KEY = ml3.MORBIDITY_REPORT_KEY AND ml3.row_num = 3;

        if @debug = 'true'
            SELECT @Proc_Step_Name, * from #MORB_LAB_FLATTENED;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #MORB_TREATMENTS';

        SELECT
            M.MORBIDITY_REPORT_KEY,
            RD.DATE_MM_DD_YYYY AS TREATMENT_DATE_,
            T.TREATMENT_NM AS TREATMENT_NAME_,
            T.TREATMENT_COMMENTS AS TREATMENT_COMMENTS_,
            T.CUSTOM_TREATMENT AS TREATMENT_CUSTOM_NAME_,
            ROW_NUMBER() OVER (PARTITION BY m.morbidity_report_key ORDER BY T.TREATMENT_KEY) AS row_num
        INTO #MORB_TREATMENTS
        FROM dbo.TREATMENT_EVENT TE WITH (NOLOCK)
                 INNER JOIN #MORB_EVENT_INIT M ON TE.MORB_RPT_KEY = M.MORBIDITY_REPORT_KEY
                 INNER JOIN dbo.TREATMENT T WITH (NOLOCK) ON TE.TREATMENT_KEY = T.TREATMENT_KEY
                 INNER JOIN dbo.RDB_DATE RD WITH (NOLOCK) ON TE.TREATMENT_DT_KEY = RD.DATE_KEY;

        if @debug = 'true'
            SELECT @Proc_Step_Name, * from #MORB_TREATMENTS;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #MORB_TREATMENTS_FLATTENED';

        SELECT
            morb.MORBIDITY_REPORT_KEY,
            t1.TREATMENT_DATE_ AS TREATMENT_DATE_1,
            t1.TREATMENT_NAME_ AS TREATMENT_NAME_1,
            t1.TREATMENT_COMMENTS_ AS TREATMENT_COMMENTS_1,
            t1.TREATMENT_CUSTOM_NAME_ AS TREATMENT_CUSTOM_NAME_1,
            t2.TREATMENT_DATE_ AS TREATMENT_DATE_2,
            t2.TREATMENT_NAME_ AS TREATMENT_NAME_2,
            t2.TREATMENT_COMMENTS_ AS TREATMENT_COMMENTS_2,
            t2.TREATMENT_CUSTOM_NAME_ AS TREATMENT_CUSTOM_NAME_2,
            t3.TREATMENT_DATE_ AS TREATMENT_DATE_3,
            t3.TREATMENT_NAME_ AS TREATMENT_NAME_3,
            t3.TREATMENT_COMMENTS_ AS TREATMENT_COMMENTS_3,
            t3.TREATMENT_CUSTOM_NAME_ AS TREATMENT_CUSTOM_NAME_3,
            IIF(morb.max_row > 3, 'Yes', 'No') AS TREATMENT_GT3_CREATED_IND
        INTO #MORB_TREATMENTS_FLATTENED
        FROM
            (SELECT MORBIDITY_REPORT_KEY, MAX(row_num) as max_row
             FROM #MORB_TREATMENTS
             GROUP BY MORBIDITY_REPORT_KEY) as morb
                LEFT JOIN #MORB_TREATMENTS t1
                          ON morb.MORBIDITY_REPORT_KEY = t1.MORBIDITY_REPORT_KEY AND t1.row_num = 1
                LEFT JOIN #MORB_TREATMENTS t2
                          ON morb.MORBIDITY_REPORT_KEY = t2.MORBIDITY_REPORT_KEY AND t2.row_num = 2
                LEFT JOIN #MORB_TREATMENTS t3
                          ON morb.MORBIDITY_REPORT_KEY = t3.MORBIDITY_REPORT_KEY AND t3.row_num = 3;

        if @debug = 'true'
            SELECT @Proc_Step_Name, * from #MORB_TREATMENTS_FLATTENED;



        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #MORB_EVENT_FINAL';

        SELECT
            src.MORBIDITY_REPORT_KEY,
            src.MORBIDITY_REPORT_LOCAL_ID,
            src.PATIENT_LOCAL_ID,
            src.PATIENT_GENERAL_COMMENTS,
            src.PATIENT_FIRST_NAME,
            src.PATIENT_MIDDLE_NAME,
            src.PATIENT_LAST_NAME,
            src.PATIENT_NAME_SUFFIX,
            src.PATIENT_STREET_ADDRESS_1,
            src.PATIENT_STREET_ADDRESS_2,
            src.PATIENT_CITY,
            src.PATIENT_STATE,
            src.PATIENT_ZIP,
            src.PATIENT_COUNTY,
            src.PATIENT_COUNTRY,
            src.PATIENT_PHONE_NUMBER_HOME,
            src.PATIENT_PHONE_EXT_HOME,
            src.PATIENT_PHONE_NUMBER_WORK,
            src.PATIENT_PHONE_EXT_WORK,
            src.PATIENT_DOB,
            src.AGE_REPORTED,
            src.AGE_REPORTED_UNIT,
            src.PATIENT_CURRENT_SEX,
            src.PATIENT_DECEASED_INDICATOR,
            src.PATIENT_DECEASED_DATE,
            src.PATIENT_MARITAL_STATUS,
            src.PATIENT_SSN,
            src.PATIENT_ETHNICITY,
            src.RACE_CALCULATED,
            src.RACE_CALCULATED_DETAILS,
            src.PROGRAM_AREA_DESCRIPTION,
            src.JURISDICTION_NAME,
            src.PH_RECEIVE_DT,
            src.REPORT_FAC_NAME,
            src.REPORT_FAC_STREET_ADDR_1,
            src.REPORT_FAC_STREET_ADDR_2,
            src.REPORT_FAC_CITY,
            src.REPORT_FAC_STATE,
            src.REPORT_FAC_ZIP,
            src.REPORT_FAC_PHONE,
            src.REPORT_FAC_PHONE_EXT,
            src.PROVIDER_FIRST_NAME,
            src.PROVIDER_LAST_NAME,
            src.PROVIDER_STREET_ADDR_1,
            src.PROVIDER_STREET_ADDR_2,
            src.PROVIDER_CITY,
            src.PROVIDER_STATE,
            src.PROVIDER_ZIP,
            src.PROVIDER_PHONE,
            src.PROVIDER_PHONE_EXT,
            src.REPORTER_FIRST_NAME,
            src.REPORTER_LAST_NAME,
            src.REPORTER_STREET_ADDR_1,
            src.REPORTER_STREET_ADDR_2,
            src.REPORTER_CITY,
            src.REPORTER_STATE,
            src.REPORTER_ZIP,
            src.REPORTER_PHONE,
            src.REPORTER_PHONE_EXT,
            src.DIAGNOSIS_DATE,
            src.HOSPITAL_ADMIN_DATE,
            src.HOSPITAL_FAC_NAME,
            src.HOSPITAL_FAC_STREET_ADDR_1,
            src.HOSPITAL_FAC_STREET_ADDR_2,
            src.HOSPITAL_FAC_CITY,
            src.HOSPITAL_FAC_STATE,
            src.HOSPITAL_FAC_ZIP,
            src.HOSPITAL_FAC_PHONE,
            src.HOSPITAL_FAC_PHONE_EXT,
            src.OTHER_EPI,
            src.MORB_RPT_COMMENTS,
            src.INVESTIGATION_KEY,
            src.INVESTIGATION_CREATED_IND,
            src.CASE_STATUS,
            src.REPORTING_FACILITY_UID,
            src.PROGRAM_JURISDICTION_OID,
            src.MORB_REPORT_CREATE_DATE,
            CONCAT(src.add_user_first_name, ' ', src.add_user_last_name) AS MORB_REPORT_CREATED_BY,
            src.MORB_REPORT_LAST_UPDATED_DATE,
            CONCAT(src.last_chg_user_first_name, ' ', src.last_chg_user_last_name) AS MORB_REPORT_LAST_UPDATED_BY,
            src.EXTERNAL_IND,
            t.TREATMENT_DATE_1,
            t.TREATMENT_NAME_1,
            t.TREATMENT_COMMENTS_1,
            t.TREATMENT_CUSTOM_NAME_1,
            t.TREATMENT_DATE_2,
            t.TREATMENT_NAME_2,
            t.TREATMENT_COMMENTS_2,
            t.TREATMENT_CUSTOM_NAME_2,
            t.TREATMENT_DATE_3,
            t.TREATMENT_NAME_3,
            t.TREATMENT_COMMENTS_3,
            t.TREATMENT_CUSTOM_NAME_3,
            COALESCE(t.TREATMENT_GT3_CREATED_IND, 'No') AS TREATMENT_GT3_CREATED_IND,
            ml.SPECIMEN_COLLECTION_DATE_1,
            ml.RESULTED_TEST_NAME_1,
            ml.LAB_REPORT_DATE_1,
            ml.RESULTED_TEST_RESULT_1,
            ml.RESULTED_TEST_TEXT_RESULT_1,
            ml.LAB_RESULT_COMMENTS_1,
            ml.RESULTED_TEST_NUMERIC_CONCAT_1,
            ml.SPECIMEN_SOURCE_1,
            ml.SPECIMEN_COLLECTION_DATE_2,
            ml.RESULTED_TEST_NAME_2,
            ml.LAB_REPORT_DATE_2,
            ml.RESULTED_TEST_RESULT_2,
            ml.RESULTED_TEST_TEXT_RESULT_2,
            ml.LAB_RESULT_COMMENTS_2,
            ml.RESULTED_TEST_NUMERIC_CONCAT_2,
            ml.SPECIMEN_SOURCE_2,
            ml.SPECIMEN_COLLECTION_DATE_3,
            ml.RESULTED_TEST_NAME_3,
            ml.LAB_REPORT_DATE_3,
            ml.RESULTED_TEST_RESULT_3,
            ml.RESULTED_TEST_TEXT_RESULT_3,
            ml.LAB_RESULT_COMMENTS_3,
            ml.RESULTED_TEST_NUMERIC_CONCAT_3,
            ml.SPECIMEN_SOURCE_3,
            COALESCE(ml.LAB_GT3_CREATED_IND, 'No') AS LAB_GT3_CREATED_IND,
            cvg1.CODE_DESC_TXT AS MORBIDITY_REPORT_TYPE,
            cvg2.CODE_SHORT_DESC_TXT AS DELIVERY_METHOD,
            cvg3.CODE_DESC_TXT AS DIE_FROM_ILLNESS,
            cvg4.CODE_DESC_TXT AS HOSPITALIZED,
            cvg5.CODE_DESC_TXT AS PREGNANT,
            cvg6.CODE_DESC_TXT AS FOOD_HANDLER,
            cvg7.CODE_DESC_TXT AS DAYCARE,
            cvg8.CODE_DESC_TXT AS NURSING_HOME,
            cvg9.CODE_DESC_TXT AS HEALTHCARE_ORGANIZATION,
            cvg10.CODE_DESC_TXT AS FOOD_WATERBORNE_ILLNESS,
            con.condition_desc AS CONDITION_NAME,
            d1.DATE_MM_DD_YYYY AS MORBIDITY_REPORT_DATE,
            d2.DATE_MM_DD_YYYY AS ILLNESS_ONSET_DATE,
            d3.DATE_MM_DD_YYYY AS HOSPITAL_DISCHARGE_DATE,
            DML_IND
        INTO #MORB_EVENT_FINAL
        FROM  #MORB_EVENT_INIT src
                  LEFT JOIN #MORB_LAB_FLATTENED ml
                            ON src.MORBIDITY_REPORT_KEY = ml.MORBIDITY_REPORT_KEY
                  LEFT JOIN #MORB_TREATMENTS_FLATTENED t
                            ON src.MORBIDITY_REPORT_KEY = t.MORBIDITY_REPORT_KEY
                  LEFT JOIN #SRTLOOKUP cvg1
                            ON src.MORB_RPT_TYPE = cvg1.CODE AND cvg1.CODE_SET_NM = 'MORB_RPT_TYPE'
                  LEFT JOIN #SRTLOOKUP cvg2
                            ON src.MORB_RPT_DELIVERY_METHOD = cvg2.CODE AND cvg2.CODE_SET_NM = 'MRB_RPT_METH'
                  LEFT JOIN #SRTLOOKUP cvg3
                            ON src.DIE_FROM_ILLNESS_IND = cvg3.CODE AND cvg3.CODE_SET_NM = 'YNU'
                  LEFT JOIN #SRTLOOKUP cvg4
                            ON src.HOSPITALIZED_IND = cvg4.CODE AND cvg4.CODE_SET_NM = 'YNU'
                  LEFT JOIN #SRTLOOKUP cvg5
                            ON src.PREGNANT_IND = cvg5.CODE AND cvg5.CODE_SET_NM = 'YNU'
                  LEFT JOIN #SRTLOOKUP cvg6
                            ON src.FOOD_HANDLER_IND = cvg6.CODE AND cvg6.CODE_SET_NM = 'YNU'
                  LEFT JOIN #SRTLOOKUP cvg7
                            ON src.DAYCARE_IND = cvg7.CODE AND cvg7.CODE_SET_NM = 'YNU'
                  LEFT JOIN #SRTLOOKUP cvg8
                            ON src.NURSING_HOME_ASSOCIATE_IND = cvg8.CODE AND cvg8.CODE_SET_NM = 'YNU'
                  LEFT JOIN #SRTLOOKUP cvg9
                            ON src.HEALTHCARE_ORG_ASSOCIATE_IND = cvg9.CODE AND cvg9.CODE_SET_NM = 'YNU'
                  LEFT JOIN #SRTLOOKUP cvg10
                            ON src.SUSPECT_FOOD_WTRBORNE_ILLNESS = cvg10.CODE AND cvg10.CODE_SET_NM = 'YNU'
                  LEFT JOIN dbo.condition con WITH (NOLOCK)
                            ON con.condition_key = src.CONDITION_KEY
                  LEFT JOIN dbo.RDB_DATE d1 WITH (NOLOCK)
                            ON src.MORB_RPT_DT_KEY = d1.DATE_KEY
                  LEFT JOIN dbo.RDB_DATE d2 WITH (NOLOCK)
                            ON src.ILLNESS_ONSET_DT_KEY = d2.DATE_KEY
                  LEFT JOIN dbo.RDB_DATE d3 WITH (NOLOCK)
                            ON src.HSPTL_DISCHARGE_DT_KEY = d3.DATE_KEY;

        if @debug = 'true'
            SELECT @Proc_Step_Name, * from #MORB_EVENT_FINAL;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'DELETE INACTIVE RECORDS FROM dbo.MORBIDITY_REPORT_DATAMART';

        DELETE FROM dbo.MORBIDITY_REPORT_DATAMART
        WHERE MORBIDITY_REPORT_KEY IN (
            SELECT
                MORBIDITY_REPORT_KEY
            FROM #INACTIVE_MORB
        );


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'UPDATE dbo.MORBIDITY_REPORT_DATAMART';

        UPDATE tgt
        SET
            tgt.MORBIDITY_REPORT_KEY = src.MORBIDITY_REPORT_KEY,
            tgt.MORBIDITY_REPORT_LOCAL_ID = src.MORBIDITY_REPORT_LOCAL_ID,
            tgt.PATIENT_LOCAL_ID = src.PATIENT_LOCAL_ID,
            tgt.PATIENT_GENERAL_COMMENTS = src.PATIENT_GENERAL_COMMENTS,
            tgt.PATIENT_FIRST_NAME = src.PATIENT_FIRST_NAME,
            tgt.PATIENT_MIDDLE_NAME = src.PATIENT_MIDDLE_NAME,
            tgt.PATIENT_LAST_NAME = src.PATIENT_LAST_NAME,
            tgt.PATIENT_NAME_SUFFIX = src.PATIENT_NAME_SUFFIX,
            tgt.PATIENT_STREET_ADDRESS_1 = src.PATIENT_STREET_ADDRESS_1,
            tgt.PATIENT_STREET_ADDRESS_2 = src.PATIENT_STREET_ADDRESS_2,
            tgt.PATIENT_CITY = src.PATIENT_CITY,
            tgt.PATIENT_STATE = src.PATIENT_STATE,
            tgt.PATIENT_ZIP = src.PATIENT_ZIP,
            tgt.PATIENT_COUNTY = src.PATIENT_COUNTY,
            tgt.PATIENT_COUNTRY = src.PATIENT_COUNTRY,
            tgt.PATIENT_PHONE_NUMBER_HOME = src.PATIENT_PHONE_NUMBER_HOME,
            tgt.PATIENT_PHONE_EXT_HOME = src.PATIENT_PHONE_EXT_HOME,
            tgt.PATIENT_PHONE_NUMBER_WORK = src.PATIENT_PHONE_NUMBER_WORK,
            tgt.PATIENT_PHONE_EXT_WORK = src.PATIENT_PHONE_EXT_WORK,
            tgt.PATIENT_DOB = src.PATIENT_DOB,
            tgt.AGE_REPORTED = src.AGE_REPORTED,
            tgt.AGE_REPORTED_UNIT = src.AGE_REPORTED_UNIT,
            tgt.PATIENT_CURRENT_SEX = src.PATIENT_CURRENT_SEX,
            tgt.PATIENT_DECEASED_INDICATOR = src.PATIENT_DECEASED_INDICATOR,
            tgt.PATIENT_DECEASED_DATE = src.PATIENT_DECEASED_DATE,
            tgt.PATIENT_MARITAL_STATUS = src.PATIENT_MARITAL_STATUS,
            tgt.PATIENT_SSN = src.PATIENT_SSN,
            tgt.PATIENT_ETHNICITY = src.PATIENT_ETHNICITY,
            tgt.RACE_CALCULATED = src.RACE_CALCULATED,
            tgt.RACE_CALCULATED_DETAILS = src.RACE_CALCULATED_DETAILS,
            tgt.CONDITION_NAME = src.CONDITION_NAME,
            tgt.PROGRAM_AREA_DESCRIPTION = src.PROGRAM_AREA_DESCRIPTION,
            tgt.JURISDICTION_NAME = src.JURISDICTION_NAME,
            tgt.MORBIDITY_REPORT_TYPE = src.MORBIDITY_REPORT_TYPE,
            tgt.DELIVERY_METHOD = src.DELIVERY_METHOD,
            tgt.MORBIDITY_REPORT_DATE = src.MORBIDITY_REPORT_DATE,
            tgt.PH_RECEIVE_DT = src.PH_RECEIVE_DT,
            tgt.REPORT_FAC_NAME = src.REPORT_FAC_NAME,
            tgt.REPORT_FAC_STREET_ADDR_1 = src.REPORT_FAC_STREET_ADDR_1,
            tgt.REPORT_FAC_STREET_ADDR_2 = src.REPORT_FAC_STREET_ADDR_2,
            tgt.REPORT_FAC_CITY = src.REPORT_FAC_CITY,
            tgt.REPORT_FAC_STATE = src.REPORT_FAC_STATE,
            tgt.REPORT_FAC_ZIP = src.REPORT_FAC_ZIP,
            tgt.REPORT_FAC_PHONE = src.REPORT_FAC_PHONE,
            tgt.REPORT_FAC_PHONE_EXT = src.REPORT_FAC_PHONE_EXT,
            tgt.PROVIDER_FIRST_NAME = src.PROVIDER_FIRST_NAME,
            tgt.PROVIDER_LAST_NAME = src.PROVIDER_LAST_NAME,
            tgt.PROVIDER_STREET_ADDR_1 = src.PROVIDER_STREET_ADDR_1,
            tgt.PROVIDER_STREET_ADDR_2 = src.PROVIDER_STREET_ADDR_2,
            tgt.PROVIDER_CITY = src.PROVIDER_CITY,
            tgt.PROVIDER_STATE = src.PROVIDER_STATE,
            tgt.PROVIDER_ZIP = src.PROVIDER_ZIP,
            tgt.PROVIDER_PHONE = src.PROVIDER_PHONE,
            tgt.PROVIDER_PHONE_EXT = src.PROVIDER_PHONE_EXT,
            tgt.REPORTER_FIRST_NAME = src.REPORTER_FIRST_NAME,
            tgt.REPORTER_LAST_NAME = src.REPORTER_LAST_NAME,
            tgt.REPORTER_STREET_ADDR_1 = src.REPORTER_STREET_ADDR_1,
            tgt.REPORTER_STREET_ADDR_2 = src.REPORTER_STREET_ADDR_2,
            tgt.REPORTER_CITY = src.REPORTER_CITY,
            tgt.REPORTER_STATE = src.REPORTER_STATE,
            tgt.REPORTER_ZIP = src.REPORTER_ZIP,
            tgt.REPORTER_PHONE = src.REPORTER_PHONE,
            tgt.REPORTER_PHONE_EXT = src.REPORTER_PHONE_EXT,
            tgt.ILLNESS_ONSET_DATE = src.ILLNESS_ONSET_DATE,
            tgt.DIAGNOSIS_DATE = src.DIAGNOSIS_DATE,
            tgt.DIE_FROM_ILLNESS = src.DIE_FROM_ILLNESS,
            tgt.HOSPITALIZED = src.HOSPITALIZED,
            tgt.HOSPITAL_ADMIN_DATE = src.HOSPITAL_ADMIN_DATE,
            tgt.HOSPITAL_DISCHARGE_DATE = src.HOSPITAL_DISCHARGE_DATE,
            tgt.HOSPITAL_FAC_NAME = src.HOSPITAL_FAC_NAME,
            tgt.HOSPITAL_FAC_STREET_ADDR_1 = src.HOSPITAL_FAC_STREET_ADDR_1,
            tgt.HOSPITAL_FAC_STREET_ADDR_2 = src.HOSPITAL_FAC_STREET_ADDR_2,
            tgt.HOSPITAL_FAC_CITY = src.HOSPITAL_FAC_CITY,
            tgt.HOSPITAL_FAC_STATE = src.HOSPITAL_FAC_STATE,
            tgt.HOSPITAL_FAC_ZIP = src.HOSPITAL_FAC_ZIP,
            tgt.HOSPITAL_FAC_PHONE = src.HOSPITAL_FAC_PHONE,
            tgt.HOSPITAL_FAC_PHONE_EXT = src.HOSPITAL_FAC_PHONE_EXT,
            tgt.PREGNANT = src.PREGNANT,
            tgt.FOOD_HANDLER = src.FOOD_HANDLER,
            tgt.DAYCARE = src.DAYCARE,
            tgt.NURSING_HOME = src.NURSING_HOME,
            tgt.HEALTHCARE_ORGANIZATION = src.HEALTHCARE_ORGANIZATION,
            tgt.FOOD_WATERBORNE_ILLNESS = src.FOOD_WATERBORNE_ILLNESS,
            tgt.OTHER_EPI = src.OTHER_EPI,
            tgt.SPECIMEN_COLLECTION_DATE_1 = src.SPECIMEN_COLLECTION_DATE_1,
            tgt.LAB_REPORT_DATE_1 = src.LAB_REPORT_DATE_1,
            tgt.RESULTED_TEST_NAME_1 = src.RESULTED_TEST_NAME_1,
            tgt.SPECIMEN_SOURCE_1 = src.SPECIMEN_SOURCE_1,
            tgt.RESULTED_TEST_RESULT_1 = src.RESULTED_TEST_RESULT_1,
            tgt.RESULTED_TEST_NUMERIC_CONCAT_1 = src.RESULTED_TEST_NUMERIC_CONCAT_1,
            tgt.RESULTED_TEST_TEXT_RESULT_1 = src.RESULTED_TEST_TEXT_RESULT_1,
            tgt.LAB_RESULT_COMMENTS_1 = src.LAB_RESULT_COMMENTS_1,
            tgt.SPECIMEN_COLLECTION_DATE_2 = src.SPECIMEN_COLLECTION_DATE_2,
            tgt.LAB_REPORT_DATE_2 = src.LAB_REPORT_DATE_2,
            tgt.RESULTED_TEST_NAME_2 = src.RESULTED_TEST_NAME_2,
            tgt.SPECIMEN_SOURCE_2 = src.SPECIMEN_SOURCE_2,
            tgt.RESULTED_TEST_RESULT_2 = src.RESULTED_TEST_RESULT_2,
            tgt.RESULTED_TEST_NUMERIC_CONCAT_2 = src.RESULTED_TEST_NUMERIC_CONCAT_2,
            tgt.RESULTED_TEST_TEXT_RESULT_2 = src.RESULTED_TEST_TEXT_RESULT_2,
            tgt.LAB_RESULT_COMMENTS_2 = src.LAB_RESULT_COMMENTS_2,
            tgt.SPECIMEN_COLLECTION_DATE_3 = src.SPECIMEN_COLLECTION_DATE_3,
            tgt.LAB_REPORT_DATE_3 = src.LAB_REPORT_DATE_3,
            tgt.RESULTED_TEST_NAME_3 = src.RESULTED_TEST_NAME_3,
            tgt.SPECIMEN_SOURCE_3 = src.SPECIMEN_SOURCE_3,
            tgt.RESULTED_TEST_RESULT_3 = src.RESULTED_TEST_RESULT_3,
            tgt.RESULTED_TEST_NUMERIC_CONCAT_3 = src.RESULTED_TEST_NUMERIC_CONCAT_3,
            tgt.RESULTED_TEST_TEXT_RESULT_3 = src.RESULTED_TEST_TEXT_RESULT_3,
            tgt.LAB_RESULT_COMMENTS_3 = src.LAB_RESULT_COMMENTS_3,
            tgt.LAB_GT3_CREATED_IND = src.LAB_GT3_CREATED_IND,
            tgt.TREATMENT_DATE_1 = src.TREATMENT_DATE_1,
            tgt.TREATMENT_NAME_1 = src.TREATMENT_NAME_1,
            tgt.TREATMENT_COMMENTS_1 = src.TREATMENT_COMMENTS_1,
            tgt.TREATMENT_CUSTOM_NAME_1 = src.TREATMENT_CUSTOM_NAME_1,
            tgt.TREATMENT_DATE_2 = src.TREATMENT_DATE_2,
            tgt.TREATMENT_NAME_2 = src.TREATMENT_NAME_2,
            tgt.TREATMENT_COMMENTS_2 = src.TREATMENT_COMMENTS_2,
            tgt.TREATMENT_CUSTOM_NAME_2 = src.TREATMENT_CUSTOM_NAME_2,
            tgt.TREATMENT_DATE_3 = src.TREATMENT_DATE_3,
            tgt.TREATMENT_NAME_3 = src.TREATMENT_NAME_3,
            tgt.TREATMENT_COMMENTS_3 = src.TREATMENT_COMMENTS_3,
            tgt.TREATMENT_CUSTOM_NAME_3 = src.TREATMENT_CUSTOM_NAME_3,
            tgt.TREATMENT_GT3_CREATED_IND = src.TREATMENT_GT3_CREATED_IND,
            tgt.MORB_RPT_COMMENTS = src.MORB_RPT_COMMENTS,
            tgt.INVESTIGATION_KEY = src.INVESTIGATION_KEY,
            tgt.INVESTIGATION_CREATED_IND = src.INVESTIGATION_CREATED_IND,
            tgt.CASE_STATUS = src.CASE_STATUS,
            tgt.REPORTING_FACILITY_UID = src.REPORTING_FACILITY_UID,
            tgt.PROGRAM_JURISDICTION_OID = src.PROGRAM_JURISDICTION_OID,
            tgt.MORB_REPORT_CREATE_DATE = src.MORB_REPORT_CREATE_DATE,
            tgt.MORB_REPORT_CREATED_BY = src.MORB_REPORT_CREATED_BY,
            tgt.MORB_REPORT_LAST_UPDATED_DATE = src.MORB_REPORT_LAST_UPDATED_DATE,
            tgt.MORB_REPORT_LAST_UPDATED_BY = src.MORB_REPORT_LAST_UPDATED_BY,
            tgt.EXTERNAL_IND = src.EXTERNAL_IND
        FROM #MORB_EVENT_FINAL src
                 LEFT JOIN dbo.MORBIDITY_REPORT_DATAMART tgt
                           ON src.MORBIDITY_REPORT_KEY = tgt.MORBIDITY_REPORT_KEY
        WHERE src.DML_IND = 'U';


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'INSERT INTO dbo.MORBIDITY_REPORT_DATAMART';

        INSERT INTO dbo.MORBIDITY_REPORT_DATAMART
        (
            MORBIDITY_REPORT_KEY,
            MORBIDITY_REPORT_LOCAL_ID,
            PATIENT_LOCAL_ID,
            PATIENT_GENERAL_COMMENTS,
            PATIENT_FIRST_NAME,
            PATIENT_MIDDLE_NAME,
            PATIENT_LAST_NAME,
            PATIENT_NAME_SUFFIX,
            PATIENT_STREET_ADDRESS_1,
            PATIENT_STREET_ADDRESS_2,
            PATIENT_CITY,
            PATIENT_STATE,
            PATIENT_ZIP,
            PATIENT_COUNTY,
            PATIENT_COUNTRY,
            PATIENT_PHONE_NUMBER_HOME,
            PATIENT_PHONE_EXT_HOME,
            PATIENT_PHONE_NUMBER_WORK,
            PATIENT_PHONE_EXT_WORK,
            PATIENT_DOB,
            AGE_REPORTED,
            AGE_REPORTED_UNIT,
            PATIENT_CURRENT_SEX,
            PATIENT_DECEASED_INDICATOR,
            PATIENT_DECEASED_DATE,
            PATIENT_MARITAL_STATUS,
            PATIENT_SSN,
            PATIENT_ETHNICITY,
            RACE_CALCULATED,
            RACE_CALCULATED_DETAILS,
            CONDITION_NAME,
            PROGRAM_AREA_DESCRIPTION,
            JURISDICTION_NAME,
            MORBIDITY_REPORT_TYPE,
            DELIVERY_METHOD,
            MORBIDITY_REPORT_DATE,
            PH_RECEIVE_DT,
            REPORT_FAC_NAME,
            REPORT_FAC_STREET_ADDR_1,
            REPORT_FAC_STREET_ADDR_2,
            REPORT_FAC_CITY,
            REPORT_FAC_STATE,
            REPORT_FAC_ZIP,
            REPORT_FAC_PHONE,
            REPORT_FAC_PHONE_EXT,
            PROVIDER_FIRST_NAME,
            PROVIDER_LAST_NAME,
            PROVIDER_STREET_ADDR_1,
            PROVIDER_STREET_ADDR_2,
            PROVIDER_CITY,
            PROVIDER_STATE,
            PROVIDER_ZIP,
            PROVIDER_PHONE,
            PROVIDER_PHONE_EXT,
            REPORTER_FIRST_NAME,
            REPORTER_LAST_NAME,
            REPORTER_STREET_ADDR_1,
            REPORTER_STREET_ADDR_2,
            REPORTER_CITY,
            REPORTER_STATE,
            REPORTER_ZIP,
            REPORTER_PHONE,
            REPORTER_PHONE_EXT,
            ILLNESS_ONSET_DATE,
            DIAGNOSIS_DATE,
            DIE_FROM_ILLNESS,
            HOSPITALIZED,
            HOSPITAL_ADMIN_DATE,
            HOSPITAL_DISCHARGE_DATE,
            HOSPITAL_FAC_NAME,
            HOSPITAL_FAC_STREET_ADDR_1,
            HOSPITAL_FAC_STREET_ADDR_2,
            HOSPITAL_FAC_CITY,
            HOSPITAL_FAC_STATE,
            HOSPITAL_FAC_ZIP,
            HOSPITAL_FAC_PHONE,
            HOSPITAL_FAC_PHONE_EXT,
            PREGNANT,
            FOOD_HANDLER,
            DAYCARE,
            NURSING_HOME,
            HEALTHCARE_ORGANIZATION,
            FOOD_WATERBORNE_ILLNESS,
            OTHER_EPI,
            SPECIMEN_COLLECTION_DATE_1,
            LAB_REPORT_DATE_1,
            RESULTED_TEST_NAME_1,
            SPECIMEN_SOURCE_1,
            RESULTED_TEST_RESULT_1,
            RESULTED_TEST_NUMERIC_CONCAT_1,
            RESULTED_TEST_TEXT_RESULT_1,
            LAB_RESULT_COMMENTS_1,
            SPECIMEN_COLLECTION_DATE_2,
            LAB_REPORT_DATE_2,
            RESULTED_TEST_NAME_2,
            SPECIMEN_SOURCE_2,
            RESULTED_TEST_RESULT_2,
            RESULTED_TEST_NUMERIC_CONCAT_2,
            RESULTED_TEST_TEXT_RESULT_2,
            LAB_RESULT_COMMENTS_2,
            SPECIMEN_COLLECTION_DATE_3,
            LAB_REPORT_DATE_3,
            RESULTED_TEST_NAME_3,
            SPECIMEN_SOURCE_3,
            RESULTED_TEST_RESULT_3,
            RESULTED_TEST_NUMERIC_CONCAT_3,
            RESULTED_TEST_TEXT_RESULT_3,
            LAB_RESULT_COMMENTS_3,
            LAB_GT3_CREATED_IND,
            TREATMENT_DATE_1,
            TREATMENT_NAME_1,
            TREATMENT_COMMENTS_1,
            TREATMENT_CUSTOM_NAME_1,
            TREATMENT_DATE_2,
            TREATMENT_NAME_2,
            TREATMENT_COMMENTS_2,
            TREATMENT_CUSTOM_NAME_2,
            TREATMENT_DATE_3,
            TREATMENT_NAME_3,
            TREATMENT_COMMENTS_3,
            TREATMENT_CUSTOM_NAME_3,
            TREATMENT_GT3_CREATED_IND,
            MORB_RPT_COMMENTS,
            INVESTIGATION_KEY,
            INVESTIGATION_CREATED_IND,
            CASE_STATUS,
            REPORTING_FACILITY_UID,
            PROGRAM_JURISDICTION_OID,
            MORB_REPORT_CREATE_DATE,
            MORB_REPORT_CREATED_BY,
            MORB_REPORT_LAST_UPDATED_DATE,
            MORB_REPORT_LAST_UPDATED_BY,
            EXTERNAL_IND
        )
        SELECT
            src.MORBIDITY_REPORT_KEY,
            src.MORBIDITY_REPORT_LOCAL_ID,
            src.PATIENT_LOCAL_ID,
            src.PATIENT_GENERAL_COMMENTS,
            src.PATIENT_FIRST_NAME,
            src.PATIENT_MIDDLE_NAME,
            src.PATIENT_LAST_NAME,
            src.PATIENT_NAME_SUFFIX,
            src.PATIENT_STREET_ADDRESS_1,
            src.PATIENT_STREET_ADDRESS_2,
            src.PATIENT_CITY,
            src.PATIENT_STATE,
            src.PATIENT_ZIP,
            src.PATIENT_COUNTY,
            src.PATIENT_COUNTRY,
            src.PATIENT_PHONE_NUMBER_HOME,
            src.PATIENT_PHONE_EXT_HOME,
            src.PATIENT_PHONE_NUMBER_WORK,
            src.PATIENT_PHONE_EXT_WORK,
            src.PATIENT_DOB,
            src.AGE_REPORTED,
            src.AGE_REPORTED_UNIT,
            src.PATIENT_CURRENT_SEX,
            src.PATIENT_DECEASED_INDICATOR,
            src.PATIENT_DECEASED_DATE,
            src.PATIENT_MARITAL_STATUS,
            src.PATIENT_SSN,
            src.PATIENT_ETHNICITY,
            src.RACE_CALCULATED,
            src.RACE_CALCULATED_DETAILS,
            src.CONDITION_NAME,
            src.PROGRAM_AREA_DESCRIPTION,
            src.JURISDICTION_NAME,
            src.MORBIDITY_REPORT_TYPE,
            src.DELIVERY_METHOD,
            src.MORBIDITY_REPORT_DATE,
            src.PH_RECEIVE_DT,
            src.REPORT_FAC_NAME,
            src.REPORT_FAC_STREET_ADDR_1,
            src.REPORT_FAC_STREET_ADDR_2,
            src.REPORT_FAC_CITY,
            src.REPORT_FAC_STATE,
            src.REPORT_FAC_ZIP,
            src.REPORT_FAC_PHONE,
            src.REPORT_FAC_PHONE_EXT,
            src.PROVIDER_FIRST_NAME,
            src.PROVIDER_LAST_NAME,
            src.PROVIDER_STREET_ADDR_1,
            src.PROVIDER_STREET_ADDR_2,
            src.PROVIDER_CITY,
            src.PROVIDER_STATE,
            src.PROVIDER_ZIP,
            src.PROVIDER_PHONE,
            src.PROVIDER_PHONE_EXT,
            src.REPORTER_FIRST_NAME,
            src.REPORTER_LAST_NAME,
            src.REPORTER_STREET_ADDR_1,
            src.REPORTER_STREET_ADDR_2,
            src.REPORTER_CITY,
            src.REPORTER_STATE,
            src.REPORTER_ZIP,
            src.REPORTER_PHONE,
            src.REPORTER_PHONE_EXT,
            src.ILLNESS_ONSET_DATE,
            src.DIAGNOSIS_DATE,
            src.DIE_FROM_ILLNESS,
            src.HOSPITALIZED,
            src.HOSPITAL_ADMIN_DATE,
            src.HOSPITAL_DISCHARGE_DATE,
            src.HOSPITAL_FAC_NAME,
            src.HOSPITAL_FAC_STREET_ADDR_1,
            src.HOSPITAL_FAC_STREET_ADDR_2,
            src.HOSPITAL_FAC_CITY,
            src.HOSPITAL_FAC_STATE,
            src.HOSPITAL_FAC_ZIP,
            src.HOSPITAL_FAC_PHONE,
            src.HOSPITAL_FAC_PHONE_EXT,
            src.PREGNANT,
            src.FOOD_HANDLER,
            src.DAYCARE,
            src.NURSING_HOME,
            src.HEALTHCARE_ORGANIZATION,
            src.FOOD_WATERBORNE_ILLNESS,
            src.OTHER_EPI,
            src.SPECIMEN_COLLECTION_DATE_1,
            src.LAB_REPORT_DATE_1,
            src.RESULTED_TEST_NAME_1,
            src.SPECIMEN_SOURCE_1,
            src.RESULTED_TEST_RESULT_1,
            src.RESULTED_TEST_NUMERIC_CONCAT_1,
            src.RESULTED_TEST_TEXT_RESULT_1,
            src.LAB_RESULT_COMMENTS_1,
            src.SPECIMEN_COLLECTION_DATE_2,
            src.LAB_REPORT_DATE_2,
            src.RESULTED_TEST_NAME_2,
            src.SPECIMEN_SOURCE_2,
            src.RESULTED_TEST_RESULT_2,
            src.RESULTED_TEST_NUMERIC_CONCAT_2,
            src.RESULTED_TEST_TEXT_RESULT_2,
            src.LAB_RESULT_COMMENTS_2,
            src.SPECIMEN_COLLECTION_DATE_3,
            src.LAB_REPORT_DATE_3,
            src.RESULTED_TEST_NAME_3,
            src.SPECIMEN_SOURCE_3,
            src.RESULTED_TEST_RESULT_3,
            src.RESULTED_TEST_NUMERIC_CONCAT_3,
            src.RESULTED_TEST_TEXT_RESULT_3,
            src.LAB_RESULT_COMMENTS_3,
            src.LAB_GT3_CREATED_IND,
            src.TREATMENT_DATE_1,
            src.TREATMENT_NAME_1,
            src.TREATMENT_COMMENTS_1,
            src.TREATMENT_CUSTOM_NAME_1,
            src.TREATMENT_DATE_2,
            src.TREATMENT_NAME_2,
            src.TREATMENT_COMMENTS_2,
            src.TREATMENT_CUSTOM_NAME_2,
            src.TREATMENT_DATE_3,
            src.TREATMENT_NAME_3,
            src.TREATMENT_COMMENTS_3,
            src.TREATMENT_CUSTOM_NAME_3,
            src.TREATMENT_GT3_CREATED_IND,
            src.MORB_RPT_COMMENTS,
            src.INVESTIGATION_KEY,
            src.INVESTIGATION_CREATED_IND,
            src.CASE_STATUS,
            src.REPORTING_FACILITY_UID,
            src.PROGRAM_JURISDICTION_OID,
            src.MORB_REPORT_CREATE_DATE,
            src.MORB_REPORT_CREATED_BY,
            src.MORB_REPORT_LAST_UPDATED_DATE,
            src.MORB_REPORT_LAST_UPDATED_BY,
            src.EXTERNAL_IND
        FROM #MORB_EVENT_FINAL src
        WHERE src.DML_IND = 'I';


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;



        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name,@Package_Name, 'COMPLETE', 999, 'COMPLETE', 0);

        SELECT
            CAST(NULL AS BIGINT) AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            CAST(NULL AS VARCHAR(30)) AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            CAST(NULL AS VARCHAR(200)) AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
        WHERE 1=0;

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [Error_Description]
                                         , [row_count])
        VALUES ( @batch_id
               , @Dataflow_Name
               , @Package_Name
               , 'ERROR'
               , @Proc_Step_no
               , @Proc_Step_name
               , @FullErrorMessage
               , 0);


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