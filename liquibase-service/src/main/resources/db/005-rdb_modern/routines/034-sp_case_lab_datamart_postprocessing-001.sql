IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_case_lab_datamart_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_case_lab_datamart_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_case_lab_datamart_postprocessing] @phc_id nvarchar(max),
                                                                          @debug bit = 'false'
AS
BEGIN
    DECLARE @batch_id BIGINT;
    SET @batch_id = CAST((FORMAT(GETDATE(), 'yyMMddHHmmssffff')) AS BIGINT);
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';

        SELECT @ROWCOUNT_NO = 0;

        INSERT
        INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID,
         [DATAFLOW_NAME],
         [PACKAGE_NAME],
         [STATUS_TYPE],
         [STEP_NUMBER],
         [STEP_NAME],
         [ROW_COUNT],
         [msg_description1])
        VALUES (@batch_id,
                'CASE_LAB_DATAMART',
                'CASE_LAB_DATAMART',
                'START',
                @PROC_STEP_NO,
                @PROC_STEP_NAME,
                @ROWCOUNT_NO,
                LEFT(@phc_id, 500));

-------------------------------------------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Creating LAB_INV_MAP';

        SELECT map.INVESTIGATION_KEY, map.LAB_TEST_KEY
        INTO #TEMP_UPDATED_LAB_INV_MAP
        FROM LAB_TEST_RESULT map
                 JOIN INVESTIGATION inv
                      ON inv.INVESTIGATION_KEY = map.INVESTIGATION_KEY
                          AND inv.CASE_UID IN (SELECT value FROM STRING_SPLIT(@phc_id, ','));

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT
        INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID,
         [DATAFLOW_NAME],
         [PACKAGE_NAME],
         [STATUS_TYPE],
         [STEP_NUMBER],
         [STEP_NAME],
         [ROW_COUNT])
        VALUES (@batch_id,
                'CASE_LAB_DATAMART',
                'CASE_LAB_DATAMART',
                'START',
                @PROC_STEP_NO,
                @PROC_STEP_NAME,
                @ROWCOUNT_NO);

-------------------------------------------------------------------------------------------------------------------------------------------


        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        SET @PROC_STEP_NAME = 'GENERATING INCREMENTAL TMP_CLDM_All_Case';

        SELECT INVESTIGATION.INVESTIGATION_KEY,
               RPT_SRC_ORG_KEY,
               INV_LOCAL_ID    AS INVESTIGATION_LOCAL_ID,
               CONDITION_KEY,
               JURISDICTION_NM AS JURISDICTION_NAME,
               PATIENT_key,
               PHYSICIAN_KEY
        INTO #TMP_CLDM_All_Case
        FROM dbo.INVESTIGATION with (nolock)
                 LEFT OUTER JOIN dbo.CASE_COUNT with (nolock)
                                 ON INVESTIGATION.INVESTIGATION_KEY = CASE_COUNT.INVESTIGATION_KEY
        WHERE
--case_uid instead of investigation_key
            CASE_TYPE = 'I'
          AND INVESTIGATION.case_uid in (SELECT value
                                         FROM
                                             STRING_SPLIT(@phc_id,
                                                          ','))
        UNION

        SELECT inv.INVESTIGATION_KEY,
               RPT_SRC_ORG_KEY,
               INV_LOCAL_ID    AS INVESTIGATION_LOCAL_ID,
               CONDITION_KEY,
               JURISDICTION_NM AS JURISDICTION_NAME,
               PATIENT_key,
               PHYSICIAN_KEY
        FROM dbo.INVESTIGATION inv with (nolock)
                 LEFT OUTER JOIN dbo.CASE_COUNT cc with (nolock)
                                 ON
                                     inv.INVESTIGATION_KEY = cc.INVESTIGATION_KEY
        WHERE CASE_TYPE = 'I'
          AND inv.INVESTIGATION_KEY in (SELECT [INVESTIGATION_KEY]
                                        FROM
--   dbo.TEMP_UPDATED_LAB_INV_MAP with (nolock) //removed as per team discussion
#TEMP_UPDATED_LAB_INV_MAP)
        UNION

        SELECT inv.INVESTIGATION_KEY,
               RPT_SRC_ORG_KEY,
               INV_LOCAL_ID    AS INVESTIGATION_LOCAL_ID,
               CONDITION_KEY,
               JURISDICTION_NM AS JURISDICTION_NAME,
               PATIENT_key,
               PHYSICIAN_KEY
        FROM dbo.INVESTIGATION inv with (nolock)
                 LEFT OUTER JOIN dbo.CASE_COUNT cc with (nolock)
                                 ON
                                     inv.INVESTIGATION_KEY = cc.INVESTIGATION_KEY
        WHERE CASE_TYPE = 'I'
          AND inv.INVESTIGATION_KEY in (select distinct(INVESTIGATION_KEY)
                                        FROM dbo.LAB_TEST_RESULT
                                        where LAB_TEST_KEY in (select lab_test_key
                                                               FROM dbo.LAB_TEST
                                                               where case_uid in (SELECT value
                                                                                  FROM
                                                                                      STRING_SPLIT(@phc_id,
                                                                                                   ',')))
                                          and INVESTIGATION_KEY <> 1)
        UNION

        SELECT inv.INVESTIGATION_KEY,
               RPT_SRC_ORG_KEY,
               INV_LOCAL_ID    AS INVESTIGATION_LOCAL_ID,
               CONDITION_KEY,
               JURISDICTION_NM AS JURISDICTION_NAME,
               PATIENT_key,
               PHYSICIAN_KEY
        FROM dbo.INVESTIGATION inv with (nolock)
                 LEFT OUTER JOIN dbo.CASE_COUNT cc with (nolock)
                                 ON
                                     inv.INVESTIGATION_KEY = cc.INVESTIGATION_KEY
        WHERE CASE_TYPE = 'I'
          AND inv.INVESTIGATION_KEY in (select INVESTIGATION_KEY
                                        from dbo.MORBIDITY_REPORT mr
                                                 inner join dbo.MORBIDITY_REPORT_EVENT mre
                                                            on
                                                                mr.MORB_RPT_KEY = mre.MORB_RPT_KEY
                                        where case_uid in (SELECT value
                                                           FROM
                                                               STRING_SPLIT(@phc_id,
                                                                            ',')))
        /*  UNION

          SELECT inv.INVESTIGATION_KEY,
                 RPT_SRC_ORG_KEY,
                 INV_LOCAL_ID    AS INVESTIGATION_LOCAL_ID,
                 CONDITION_KEY,
                 JURISDICTION_NM AS JURISDICTION_NAME,
                 PATIENT_key,
                 PHYSICIAN_KEY
          FROM dbo.INVESTIGATION inv with (nolock)
                   LEFT OUTER JOIN dbo.CASE_COUNT cc with (nolock)
                                   ON
                                       inv.INVESTIGATION_KEY = cc.INVESTIGATION_KEY
          WHERE CASE_TYPE = 'I'
            AND cc.patient_key in (select patient_key
                                   from dbo.d_patient
          where PATIENT_KEY in (select PATIENT_KEY
                                                         from dbo.INVESTIGATION
 where INVESTIGATION_KEY in (SELECT value
                                                                                     FROM
                                                                                         STRING_SPLIT(@phc_id,
                                                                                                      ',')))
                        group by PATIENT_LOCAL_ID,
                                            patient_key); */

        if @debug = 'true'
            select '#TMP_CLDM_All_Case',
                   *
            from #TMP_CLDM_All_Case;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT
        INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID,
         [DATAFLOW_NAME],
         [PACKAGE_NAME],
         [STATUS_TYPE],
         [STEP_NUMBER],
         [STEP_NAME],
         [ROW_COUNT])
        VALUES (@batch_id,
                'CASE_LAB_DATAMART',
                'CASE_LAB_DATAMART',
                'START',
                @PROC_STEP_NO,
                @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------

        -- Next section will handle patient info...

-- Create session table for patient info

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_GEN_PATIENT_ADD';

        select GC.*,
               C.CONDITION_CD              AS CONDITION_CD,
               p.PATIENT_local_id          AS PATIENT_LOCAL_ID,
               P.PATIENT_FIRST_NAME        AS PATIENT_FIRST_NM,
               P.PATIENT_MIDDLE_NAME       AS PATIENT_MIDDLE_NM,
               P.PATIENT_LAST_NAME         AS PATIENT_LAST_NM,
               P.PATIENT_PHONE_HOME        AS PATIENT_HOME_PHONE,
               P.PATIENT_PHONE_EXT_HOME,
               P.PATIENT_STREET_ADDRESS_1,
               P.PATIENT_STREET_ADDRESS_2,
               P.PATIENT_CITY,
               P.PATIENT_STATE,
               P.PATIENT_ZIP,
               p.PATIENT_RACE_CALCULATED   AS RACE,
               P.PATIENT_COUNTY,
               P.PATIENT_DOB               AS PATIENT_DOB,
               P.PATIENT_AGE_REPORTED      AS PATIENT_REPORTED_AGE,
               P.PATIENT_AGE_REPORTED_UNIT AS PATIENT_REPORTED_AGE_UNITS,
               P.PATIENT_CURRENT_SEX       AS PATIENT_CURR_GENDER,
               P.PATIENT_ENTRY_METHOD      AS PATIENT_ELECTRONIC_IND,
               P.PATIENT_UID               AS PATIENT_UID
        into #TMP_CLDM_GEN_PATIENT_ADD
        from #TMP_CLDM_ALL_CASE as GC with (nolock)
                 left join dbo.D_PATIENT as p with (nolock)
                           ON GC.PATIENT_KEY = p.PATIENT_key
                 left join dbo.condition as C with (nolock)
                           ON C.CONDITION_KEY = GC.CONDITION_KEY
                               AND P.PATIENT_KEY <> 1;

        if @debug = 'true'
            select '#TMP_CLDM_GEN_PATIENT_ADD', * from #TMP_CLDM_GEN_PATIENT_ADD;

        -- Process phone numbers
-- Optimized single UPDATE statement using CASE
        UPDATE #TMP_CLDM_GEN_PATIENT_ADD
        SET PATIENT_HOME_PHONE =
                CASE
                    WHEN PATIENT_HOME_PHONE <> '' AND PATIENT_PHONE_EXT_HOME <> ''
                        THEN rtrim(PATIENT_HOME_PHONE) + ' ext. ' + rtrim(PATIENT_PHONE_EXT_HOME)
                    WHEN PATIENT_HOME_PHONE <> '' AND PATIENT_PHONE_EXT_HOME = ''
                        THEN rtrim(PATIENT_HOME_PHONE)
                    WHEN PATIENT_HOME_PHONE = '' AND PATIENT_PHONE_EXT_HOME <> ''
                        THEN 'ext. ' + rtrim(PATIENT_PHONE_EXT_HOME)
                    ELSE PATIENT_HOME_PHONE
                    END
        WHERE PATIENT_HOME_PHONE <> ''
           OR PATIENT_PHONE_EXT_HOME <> '';

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------


-- Create session table for patient investigation info

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_GEN_PAT_ADD_INV';

        /*Notes: Event metric is not part of RTR yet.*/
        select GPA.*,
               i.INV_LOCAL_ID             'INV_LOCAL_ID',
               i.INVESTIGATION_STATUS     'INVESTIGATION_STATUS',
               i.INV_CASE_STATUS          'INV_CASE_STATUS',
               i.JURISDICTION_NM     AS   INV_JURISDICTION_NM,
               i.ILLNESS_ONSET_DT         'ILLNESS_ONSET_DT',
               i.INV_START_DT             'INV_START_DT',
               i.INV_RPT_DT               'INV_RPT_DT',
               i.RPT_SRC_CD_DESC          'RPT_SRC_CD_DESC',
               i.EARLIEST_RPT_TO_CNTY_DT  'EARLIEST_RPT_TO_CNTY_DT',
               i.EARLIEST_RPT_TO_STATE_DT 'EARLIEST_RPT_TO_STATE_DT',
               i.DIE_FRM_THIS_ILLNESS_IND 'DIE_FRM_THIS_ILLNESS_IND',
               i.outbreak_ind             'OUTBREAK_IND',
               i.DISEASE_IMPORTED_IND,
               i.Import_Frm_Cntry    AS   IMPORT_FROM_COUNTRY,
               i.Import_Frm_State    AS   IMPORT_FROM_STATE,
               i.Import_Frm_Cnty     AS   IMPORT_FROM_COUNTY,
               i.Import_Frm_City     AS   IMPORT_FROM_CITY,
               i.CASE_RPT_MMWR_WK,
               i.CASE_RPT_MMWR_YR         'CASE_RPT_MMWR_YR',
               i.DIAGNOSIS_DT             'DIAGNOSIS_DT',
               i.HSPTLIZD_IND             'HSPTLIZD_IND',
               i.HSPTL_ADMISSION_DT       'HSPTL_ADMISSION_DT',
               i.HSPTL_DISCHARGE_DT,
               i.HSPTL_DURATION_DAYS,
               i.Transmission_mode,
               i.CASE_OID,
               i.INV_COMMENTS             'INV_COMMENTS',
               em.ADD_TIME           AS   INV_ADD_TIME,
               em.LAST_CHG_TIME      AS   PHC_LAST_CHG_TIME,
               em.PROG_AREA_DESC_TXT AS   PROGRAM_AREA_DESCRIPTION,
               i.record_status_cd
        into #TMP_CLDM_GEN_PAT_ADD_INV
        from #TMP_CLDM_GEN_PATIENT_ADD as GPA with (nolock)
                 left join dbo.investigation as i with (nolock)
                           ON GPA.investigation_key = i.investigation_key
                 left join dbo.EVENT_METRIC_INC as em with (nolock)
                           ON em.event_uid = i.case_uid
                               and i.investigation_key <> 1
        WHERE (I.RECORD_STATUS_CD <> 'INACTIVE')
          AND (I.CASE_TYPE <> 'S');

        if @debug = 'true'
            select '#TMP_CLDM_GEN_PAT_ADD_INV', * from #TMP_CLDM_GEN_PAT_ADD_INV;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------

-- Create session table for provider info

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_GEN_PATCOMPL_INV_PROVIDER';

        SELECT GPI.*,
               PP.PROVIDER_FIRST_NAME,
               PP.PROVIDER_LAST_NAME,
               PP.PROVIDER_MIDDLE_NAME,
               PP.PROVIDER_PHONE_WORK,
               PP.PROVIDER_PHONE_EXT_WORK,
               cast(null as varchar(100)) as PHYSICIAN_NAME,
               cast(null as varchar(100)) as PHYSICIAN_PHONE
        into #TMP_CLDM_GEN_PATCOMPL_INV_PROVIDER
        FROM #TMP_CLDM_GEN_PAT_ADD_INV AS GPI with (nolock)
                 LEFT JOIN dbo.D_PROVIDER AS PP with (nolock)
                           ON GPI.PHYSICIAN_KEY = PP.PROVIDER_KEY;

        if @debug = 'true'
            select '#TMP_CLDM_GEN_PATCOMPL_INV_PROVIDER', * from #TMP_CLDM_GEN_PATCOMPL_INV_PROVIDER;

-- Format physician name
        update #TMP_CLDM_GEN_PATCOMPL_INV_PROVIDER
        set PHYSICIAN_NAME = cast(rtrim(PROVIDER_LAST_NAME) + ', ' + rtrim(PROVIDER_FIRST_NAME) as varchar(100))
        where PROVIDER_LAST_NAME is not null
           or PROVIDER_FIRST_NAME is not null;

-- Optimized physician phone update
        UPDATE #TMP_CLDM_GEN_PATCOMPL_INV_PROVIDER
        SET PHYSICIAN_PHONE =
                CASE
                    WHEN PROVIDER_PHONE_WORK <> '' AND PROVIDER_PHONE_EXT_WORK <> ''
                        THEN rtrim(PROVIDER_PHONE_WORK) + ' ext. ' + rtrim(PROVIDER_PHONE_EXT_WORK)
                    WHEN PROVIDER_PHONE_WORK <> '' AND PROVIDER_PHONE_EXT_WORK = ''
                        THEN rtrim(PROVIDER_PHONE_WORK)
                    WHEN PROVIDER_PHONE_WORK = '' AND PROVIDER_PHONE_EXT_WORK <> ''
                        THEN 'ext. ' + rtrim(PROVIDER_PHONE_EXT_WORK)
                    END
        WHERE PROVIDER_PHONE_WORK <> ''
           OR PROVIDER_PHONE_EXT_WORK <> '';

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------


-- Create session table for reporting source info ***

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_GEN_PATCOMPL_INV_INVESTIGATOR';

        SELECT GPI.*,
               O.ORGANIZATION_NAME AS REPORTING_SOURCE
        INTO #TMP_CLDM_GEN_PATCOMPL_INV_INVESTIGATOR
        FROM #TMP_CLDM_GEN_PATCOMPL_INV_PROVIDER AS GPI with (nolock)
                 LEFT JOIN dbo.D_ORGANIZATION AS O with (nolock)
                           ON GPI.RPT_SRC_ORG_KEY = O.ORGANIZATION_KEY;

        if @debug = 'true' select '#TMP_CLDM_GEN_PATCOMPL_INV_INVESTIGATOR', * from #TMP_CLDM_GEN_PATCOMPL_INV_INVESTIGATOR;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

-------------------------------------------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_GEN_PATINFO_INV_PHY_RPTSRC_COND';

        SELECT GPIPR.*,
               C.CONDITION_SHORT_NM,
               C.PROGRAM_AREA_DESC,
               minCMG.mCONFIRMATION_DT     as CONFIRMATION_DT,
               cast(null as datetime)     as EVENT_DATE,
               cast(null as varchar(200)) as EVENT_DATE_TYPE
        INTO #TMP_CLDM_GEN_PATINFO_INV_PHY_RPTSRC_COND
        FROM #TMP_CLDM_GEN_PATCOMPL_INV_INVESTIGATOR AS GPIPR with (nolock)
                 LEFT JOIN dbo.condition AS C with (nolock)
                           ON GPIPR.CONDITION_KEY = C.CONDITION_KEY
                 LEFT JOIN
             (SELECT
                  cmg.INVESTIGATION_KEY,
                  min(cmg.CONFIRMATION_DT) as mCONFIRMATION_DT
              FROM dbo.CONFIRMATION_METHOD_GROUP cmg with (nolock)
              GROUP BY cmg.INVESTIGATION_KEY
             ) AS minCMG ON minCMG.INVESTIGATION_KEY = GPIPR.INVESTIGATION_KEY;

        if @debug = 'true'
            select '#TMP_CLDM_GEN_PATINFO_INV_PHY_RPTSRC_COND', * from #TMP_CLDM_GEN_PATINFO_INV_PHY_RPTSRC_COND;


        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name],
                                          [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART',
                'START', @PROC_STEP_NO, @PROC_STEP_NAME, @RowCount_no);

        -------------------------------------------------------------------------------------------------------------------------------------------

-- Create final case lab datamart session table

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_CASE_LAB_DATAMART';

        ;WITH computed_min_date AS (
        SELECT 
                (SELECT	MIN(col_value) 
                        FROM ( VALUES 
                                (COALESCE(EARLIEST_RPT_TO_CNTY_DT, '9999-12-31')), 
                                (COALESCE(EARLIEST_RPT_TO_STATE_DT, '9999-12-31')), 
                                (COALESCE(INV_RPT_DT, '9999-12-31')), 
                                (COALESCE(INV_START_DT, '9999-12-31')), 
                                (COALESCE(CONFIRMATION_DT, '9999-12-31')),
                                (COALESCE(HSPTL_ADMISSION_DT, '9999-12-31')), 
                                (COALESCE(HSPTL_DISCHARGE_DT, '9999-12-31'))
                ) AS vals(col_value)) AS min_date,
                INVESTIGATION_KEY
                FROM #TMP_CLDM_GEN_PATINFO_INV_PHY_RPTSRC_COND
        )
        SELECT DISTINCT t.INVESTIGATION_KEY,
                        PATIENT_LOCAL_ID,
                        INV_LOCAL_ID               AS INVESTIGATION_LOCAL_ID,
                        PATIENT_FIRST_NM,
                        PATIENT_MIDDLE_NM,
                        PATIENT_LAST_NM,
                        PATIENT_STREET_ADDRESS_1,
                        PATIENT_STREET_ADDRESS_2,
                        PATIENT_CITY,
                        PATIENT_STATE,
                        PATIENT_ZIP,
                        PATIENT_COUNTY,
                        PATIENT_HOME_PHONE,
                        PATIENT_DOB,
                        PATIENT_REPORTED_AGE       AS AGE_REPORTED,
                        PATIENT_REPORTED_AGE_UNITS AS AGE_REPORTED_UNIT,
                        PATIENT_CURR_GENDER        AS PATIENT_CURRENT_SEX,
                        RACE,
                        INV_JURISDICTION_NM        AS JURISDICTION_NAME,
                        PROGRAM_AREA_DESCRIPTION,
                        INV_START_DT               AS INVESTIGATION_START_DATE,
                        INV_CASE_STATUS            AS CASE_STATUS,
                        condition_short_nm         AS DISEASE,
                        CONDITION_CD               AS DISEASE_CD,
                        REPORTING_SOURCE,
                        INV_COMMENTS               AS GENERAL_COMMENTS,
                        PHYSICIAN_NAME,
                        PHYSICIAN_PHONE,
                        CASE_OID                   AS PROGRAM_JURISDICTION_OID,
                        INV_ADD_TIME               AS PHC_ADD_TIME,
                        PHC_LAST_CHG_TIME,
                        CASE
                            WHEN ILLNESS_ONSET_DT IS NOT NULL THEN ILLNESS_ONSET_DT
                            WHEN DIAGNOSIS_DT IS NOT NULL THEN DIAGNOSIS_DT
                            WHEN COALESCE(
                                    EARLIEST_RPT_TO_CNTY_DT,
                                    EARLIEST_RPT_TO_STATE_DT,
                                    INV_RPT_DT,
                                    INV_START_DT,
                                    CONFIRMATION_DT,
                                    HSPTL_ADMISSION_DT,
                                    HSPTL_DISCHARGE_DT
                                 ) IS NOT NULL THEN cmd.min_date
                            ELSE NULL
                            END AS EVENT_DATE,
                        CASE
                            WHEN ILLNESS_ONSET_DT IS NOT NULL THEN 'Illness Onset Date'
                            WHEN DIAGNOSIS_DT IS NOT NULL THEN 'Date of Diagnosis'
                            WHEN COALESCE(
                                    EARLIEST_RPT_TO_CNTY_DT,
                                    EARLIEST_RPT_TO_STATE_DT,
                                    INV_RPT_DT,
                                    INV_START_DT,
                                    HSPTL_ADMISSION_DT,
                                    HSPTL_DISCHARGE_DT
                                 ) IS NOT NULL THEN (
                                CASE 
                                        WHEN EARLIEST_RPT_TO_CNTY_DT = cmd.min_date	THEN 'Earliest date received by the county/local health department'
                                        WHEN EARLIEST_RPT_TO_STATE_DT = cmd.min_date	THEN 'EarliEarliest date received by the state health department'
                                        WHEN INV_RPT_DT = cmd.min_date			THEN 'Date of Report'
                                        WHEN INV_START_DT = cmd.min_date		THEN 'Investigation Start Date'
                                        WHEN CONFIRMATION_DT = cmd.min_date		THEN 'Confirmation Date'
                                        WHEN HSPTL_ADMISSION_DT = cmd.min_date		THEN 'Hospitalization Admit Date'
                                        WHEN HSPTL_DISCHARGE_DT = cmd.min_date		THEN 'Hospitalization Discharge Date'
                                END 
                            )
                            ELSE NULL
                            END AS EVENT_DATE_TYPE
        INTO #TMP_CLDM_CASE_LAB_DATAMART
        FROM #TMP_CLDM_GEN_PATINFO_INV_PHY_RPTSRC_COND t with (nolock)
        INNER JOIN computed_min_date cmd ON cmd.INVESTIGATION_KEY = t.INVESTIGATION_KEY;

        if @debug = 'true' select '#TMP_CLDM_CASE_LAB_DATAMART', * from #TMP_CLDM_CASE_LAB_DATAMART;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------


-- Create session table for investigation lab info

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_invlab';

        SELECT l.INVESTIGATION_KEY, l.LAB_TEST_KEY
        into #TMP_CLDM_invlab
        FROM dbo.LAB_TEST_RESULT l with (nolock)
                 INNER JOIN dbo.INVESTIGATION I with (nolock)
                            ON l.INVESTIGATION_KEY = I.INVESTIGATION_KEY
        WHERE (l.LAB_TEST_KEY IN (SELECT LAB_TEST_KEY FROM dbo.LAB_TEST))
          AND (l.INVESTIGATION_KEY <> 1)
          AND (I.RECORD_STATUS_CD = 'ACTIVE')
          AND l.INVESTIGATION_KEY in (select INVESTIGATION_KEY from #TMP_CLDM_All_Case);

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------

-- Create session table for lab info and both

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_both';

        SELECT til.INVESTIGATION_KEY,
               til.LAB_TEST_KEY,
               tl.lab_rpt_local_id
        into #TMP_CLDM_both
        from #TMP_CLDM_invlab til,
             dbo.lab_test tl with (nolock)
        where til.LAB_TEST_KEY = tl.LAB_TEST_KEY
          and til.INVESTIGATION_KEY is not null;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------


-- Create inv2labs table

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_inv2labs';

        SELECT distinct b.investigation_key,
                        b.lab_test_key,
                        l.lab_rpt_LOCAL_ID,
                        l.LAB_RPT_RECEIVED_BY_PH_DT,
                        l.SPECIMEN_COLLECTION_DT,
                        l.RESULTED_LAB_TEST_CD_DESC,
                        l.RESULTEDTEST_VAL_CD_DESC,
                        l.NUMERIC_RESULT_WITHUNITS,
                        l.LAB_RESULT_TXT_VAL,
                        l.LAB_RESULT_COMMENTS,
                        l.ELR_IND
        into #TMP_CLDM_inv2labs
        FROM #TMP_CLDM_both b
                 inner join dbo.lab100 l with (nolock)
                            ON l.LAB_RPT_LOCAL_ID = b.LAB_RPT_LOCAL_ID;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------

-- Create invmorb table

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_invmorb';

        SELECT ME.MORB_RPT_KEY,
               I.INVESTIGATION_KEY,
               I.INV_LOCAL_ID,
               MR.MORB_RPT_LOCAL_ID
        into #TMP_CLDM_invmorb
        FROM dbo.MORBIDITY_REPORT_EVENT ME with (nolock)
                 INNER JOIN dbo.INVESTIGATION I with (nolock)
                            ON ME.INVESTIGATION_KEY = I.INVESTIGATION_KEY
                                AND I.INVESTIGATION_KEY in (select INVESTIGATION_KEY from #TMP_CLDM_All_Case)
                 INNER JOIN dbo.MORBIDITY_REPORT MR with (nolock)
                            ON ME.MORB_RPT_KEY = MR.MORB_RPT_KEY
        WHERE (I.RECORD_STATUS_CD = 'ACTIVE');

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------

-- Create morbResults table

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_morbResults';

        select *
        into #TMP_CLDM_morbResults
        from dbo.lab100 with (nolock)
        where morb_rpt_key in (SELECT ME.MORB_RPT_KEY
                               FROM dbo.MORBIDITY_REPORT_EVENT ME with (nolock)
                                        INNER JOIN dbo.INVESTIGATION I with (nolock)
                                                   ON ME.INVESTIGATION_KEY = I.INVESTIGATION_KEY
                                                       AND I.INVESTIGATION_KEY in
                                                           (select INVESTIGATION_KEY from #TMP_CLDM_All_Case)
                               WHERE (I.RECORD_STATUS_CD = 'ACTIVE'));

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------

-- Create morbLabResults table

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_morbLabResults';

        SELECT distinct a.investigation_key,
                        b.resulted_lab_test_key,
                        a.MORB_RPT_LOCAL_ID as lab_rpt_LOCAL_ID,
                        b.LAB_RPT_RECEIVED_BY_PH_DT,
                        b.SPECIMEN_COLLECTION_DT,
                        b.RESULTED_LAB_TEST_CD_DESC,
                        b.RESULTEDTEST_VAL_CD_DESC,
                        b.NUMERIC_RESULT_WITHUNITS,
                        b.LAB_RESULT_TXT_VAL,
                        b.LAB_RESULT_COMMENTS
        into #TMP_CLDM_morbLabResults
        FROM #TMP_CLDM_invmorb a
                 inner join #TMP_CLDM_morbResults b
                            on a.MORB_RPT_KEY = b.MORB_RPT_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------


-- Create Inv2labs_final table combining both sets of results

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_Inv2labs_final';

        select *
        into #TMP_CLDM_Inv2labs_final
        from #TMP_CLDM_Inv2labs
        union
        select *, null
        from #TMP_CLDM_Morblabresults;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------

        -- Create sample tables for formatting lab information
-- Sample1

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_sample1';

        select investigation_key as [KEY],
               ''                as Bigchunk
        into #TMP_CLDM_sample1
        from #TMP_CLDM_CASE_LAB_DATAMART;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------

-- Sample2

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_sample2';

        select investigation_key                                as 'KEY',
               lab_test_key                                     as 'SUBKEY',
               FORMAT(LAB_RPT_RECEIVED_BY_PH_DT, 'MM/dd/yyyy ') as C1,
               FORMAT(SPECIMEN_COLLECTION_DT, 'MM/dd/yyyy ')    as C2,
               rtrim(RESULTED_LAB_TEST_CD_DESC)                 as 'C3',
               rtrim(RESULTEDTEST_VAL_CD_DESC)                  as 'C4',
               rtrim(NUMERIC_RESULT_WITHUNITS)                  as 'C5',
               substring(rtrim(LAB_RESULT_TXT_VAL), 1, 200)     as 'C6',
               substring(rtrim(LAB_RESULT_COMMENTS), 1, 200)    as 'C7',
               rtrim(LAB_RPT_LOCAL_ID)                          as 'C8',
               rtrim(ELR_IND)                                   as 'c9'
        into #TMP_CLDM_sample2
        from #TMP_CLDM_inv2labs_final;

        -- Notes: Index creation can be revisited during performance improvements.
--        CREATE NONCLUSTERED INDEX [idx_tmp_sample2_key]
--            ON #TMP_CLDM_sample2 ([KEY] ASC);

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------

-- Sample21 (Top 9 results per investigation)

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_sample21';

        WITH lst AS (SELECT *,
                            ROW_NUMBER() over (PARTITION BY [key] order by subkey) AS RowNo
                     FROM #TMP_CLDM_sample2)
        SELECT *
        into #TMP_CLDM_sample21
        FROM lst
        WHERE RowNo <= 9;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------


-- Sample3 (HTML Formatting)

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_sample3';

        select distinct [key], subkey,
                        (
                            '<b>Local ID:</b> '  +  rtrim (coalesce(C8,''))  +  '<br>'  +
                            '<b>Date Received by PH:</b> '  + rtrim (coalesce(C1,''))  +  '<br>'  +
                            '<b>Specimen Collection Date:</b> '  +  rtrim (coalesce(C2,''))  +  '<br>'  +
                            '<b>ELR Indicator:</b>' +  rtrim (coalesce(c9,'')) +  '<br>'  +
                            '<b>Resulted Test:</b> '  +  (case when rtrim(coalesce(C3,''))='' THEN '' else rtrim(C3) END)  +  '<br>'  +
                            '<b>Coded Result:</b> '   +  (case when rtrim(coalesce(C4,''))='' THEN '' else rtrim(C4) END)  +  '<br>'  +
                            '<b>Numeric Result:</b> ' +  (case when rtrim(coalesce(C5,''))='' THEN '' else rtrim(C5) END)  +  '<br>'  +
                            '<b>Text Result:</b> '    +  (case when rtrim(coalesce(C6,''))='' THEN '' else rtrim(C6) END)  +  '<br>'  +
                            '<b>Comments:</b> '       +    (case when rtrim(coalesce(C7,''))='' THEN '' else rtrim(C7) END)
                            )	as bigChunk
        into #TMP_CLDM_sample3
        from #TMP_CLDM_sample21;

        if @debug = 'true' select @PROC_STEP_NAME, * from #TMP_CLDM_sample3;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------


-- Sample4 (Concatenate results per investigation)

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_sample4';

        SELECT [key], bigChunk =
            STUFF((SELECT DISTINCT '  <br><br>' + bigChunk
                   FROM #TMP_CLDM_sample3 b
                   WHERE b.[key] = a.[key]
                   FOR XML PATH('')), 1, 2, '')
        into #TMP_CLDM_sample4
        FROM #TMP_CLDM_sample3 a
        GROUP BY [key];


        if @debug = 'true' select @PROC_STEP_NAME, * from #TMP_CLDM_sample4;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------

-- Sample5 (Final lab information format)

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_sample5';

        select [key]    as investigation_key,
               bigChunk as LABORATORY_INFORMATION
        into #TMP_CLDM_sample5
        from #TMP_CLDM_sample4;

        if @debug = 'true' select @PROC_STEP_NAME, * from #TMP_CLDM_sample5;


        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------


-- Create specimen collection table

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_SPECIMEN_COLLECTION_TABLE';

        select investigation_key           as 'KEY',
               min(SPECIMEN_COLLECTION_DT) as SPECIMEN_COLLECTION_DT
        into #TMP_SPECIMEN_COLLECTION_TABLE
        from #TMP_CLDM_Inv2labs_final
        group by investigation_key;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        -------------------------------------------------------------------------------------------------------------------------------------------


-- Create final case lab datamart table

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING TMP_CLDM_CASE_LAB_DATAMART_FINAL';


        select tcld.*,
               replace(replace(replace(replace(ts5.Laboratory_Information, '&lt;', '<'), '&gt;', '>'), '&amp;', '&') ,'™', '&trade;')as Laboratory_Information,
               SPECIMEN_COLLECTION_DT  as EARLIEST_SPECIMEN_COLLECTION_DT
        into #TMP_CLDM_CASE_LAB_DATAMART_FINAL
        from #TMP_CLDM_CASE_LAB_DATAMART tcld
                 left join #TMP_CLDM_sample5 ts5 with (nolock)
                           ON tcld.investigation_key = ts5.investigation_key
                 LEFT OUTER JOIN #TMP_SPECIMEN_COLLECTION_TABLE tspt with (nolock)
                                 ON tcld.INVESTIGATION_KEY = tspt.[KEY];

-- Update laboratory information formatting
        update #TMP_CLDM_CASE_LAB_DATAMART_FINAL
        set Laboratory_Information = substring(Laboratory_Information, 9, len(Laboratory_Information)) + '<br><br>'
        where Laboratory_Information is not null;

        update #TMP_CLDM_CASE_LAB_DATAMART_FINAL
        set Laboratory_Information = cast([LABORATORY_INFORMATION] as varchar(3996)) + '<br>'
        where len(Laboratory_Information) >= 4000;


-- Update event dates based on specimen collection
        update #TMP_CLDM_CASE_LAB_DATAMART_FINAL
        set EVENT_DATE      = EARLIEST_SPECIMEN_COLLECTION_DT,
            EVENT_DATE_TYPE = 'Specimen Collection Date of Earliest Associated Lab'
        where EARLIEST_SPECIMEN_COLLECTION_DT is not null;


        if @debug = 'true' select @PROC_STEP_NAME, * from #TMP_CLDM_CASE_LAB_DATAMART_FINAL;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

-------------------------------------------------------------------------------------------------------------------------------------------


        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING CASE_LAB_DATAMART';

        -- Delete records that will be updated
        Delete cld
        from dbo.CASE_LAB_DATAMART cld
                 Inner Join #TMP_CLDM_CASE_LAB_DATAMART_FINAL tcld
                            ON tcld.[INVESTIGATION_KEY] = cld.INVESTIGATION_KEY;

        -- Delete inactive records
        delete
        from dbo.case_lab_datamart
        where investigation_key in (SELECT li.[INVESTIGATION_KEY]
                                    FROM dbo.[S_INVESTIGATION] si
                                             JOIN dbo.[L_INVESTIGATION] li ON si.CASE_UID = li.CASE_UID
                                    where RECORD_STATUS_CD = 'INACTIVE');

-- Insert new/updated records
        insert into [dbo].CASE_LAB_DATAMART
        SELECT distinct [INVESTIGATION_KEY],
                        [PATIENT_LOCAL_ID],
                        [INVESTIGATION_LOCAL_ID],
                        [PATIENT_FIRST_NM],
                        [PATIENT_MIDDLE_NM],
                        [PATIENT_LAST_NM],
                        [PATIENT_STREET_ADDRESS_1],
                        [PATIENT_STREET_ADDRESS_2],
                        [PATIENT_CITY],
                        [PATIENT_STATE],
                        [PATIENT_ZIP],
                        [PATIENT_COUNTY],
                        [PATIENT_HOME_PHONE],
                        [PATIENT_DOB],
                        [AGE_REPORTED],
                        [AGE_REPORTED_UNIT],
                        [PATIENT_CURRENT_SEX],
                        [RACE],
                        [JURISDICTION_NAME],
                        [PROGRAM_AREA_DESCRIPTION],
                        [INVESTIGATION_START_DATE],
                        [CASE_STATUS],
                        [DISEASE],
                        [DISEASE_CD],
                        [REPORTING_SOURCE],
                        [GENERAL_COMMENTS],
                        [PHYSICIAN_NAME],
                        [PHYSICIAN_PHONE],
                        cast([LABORATORY_INFORMATION] as varchar(4000)),
                        [PROGRAM_JURISDICTION_OID],
                        [PHC_ADD_TIME],
                        [PHC_LAST_CHG_TIME],
                        [EVENT_DATE],
                        EARLIEST_SPECIMEN_COLLECTION_DT,
                        EVENT_DATE_TYPE
        FROM #TMP_CLDM_CASE_LAB_DATAMART_FINAL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@batch_id, 'CASE_LAB_DATAMART', 'CASE_LAB_DATAMART', 'START', @PROC_STEP_NO, @PROC_STEP_NAME,
                @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        -------------------------------------------------------------------------------------------------------------------------------------------

-- Log completion
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @Proc_Step_Name = 'SP_COMPLETE';

        INSERT INTO [dbo].[job_flow_log] (batch_id,
                                          [Dataflow_Name],
                                          [package_Name],
                                          [Status_Type],
                                          [step_number],
                                          [step_name],
                                          [row_count])
        VALUES (@batch_id,
                'CASE_LAB_DATAMART',
                'CASE_LAB_DATAMART',
                'COMPLETE',
                @Proc_Step_no,
                @Proc_Step_name,
                @RowCount_no);


        SELECT
            CAST(NULL AS BIGINT) AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            CAST(NULL AS VARCHAR(30)) AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            CAST(NULL AS VARCHAR(200)) AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=0;
-------------------------------------------------------------------------------------------------------------------------------------------

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) +
            CHAR(10) + -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [dbo].[job_flow_log] (batch_id,
                                          [Dataflow_Name],
                                          [package_Name],
                                          [Status_Type],
                                          [step_number],
                                          [step_name],
                                          [Error_Description],
                                          [row_count])
        VALUES (@batch_id,
                'CASE_LAB_DATAMART',
                'CASE_LAB_DATAMART',
                'ERROR',
                @Proc_Step_no,
                @Proc_Step_Name,
                @FullErrorMessage,
                0);

        SELECT
            0 AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            'Error' AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            @FullErrorMessage AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=1;
            
    END CATCH;
END;