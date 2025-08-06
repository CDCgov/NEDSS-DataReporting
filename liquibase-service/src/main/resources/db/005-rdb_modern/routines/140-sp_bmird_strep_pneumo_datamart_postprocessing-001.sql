IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_bmird_strep_pneumo_datamart_postprocessing]')
                                      AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
    BEGIN
        DROP PROCEDURE [dbo].[sp_bmird_strep_pneumo_datamart_postprocessing]
    END
GO

CREATE PROCEDURE [dbo].[sp_bmird_strep_pneumo_datamart_postprocessing]
    @phc_uids nvarchar(max),
    @debug bit = 'false'
AS
BEGIN
    BEGIN TRY

        DECLARE @RowCount_no INT;
        DECLARE @Proc_Step_no FLOAT = 0;
        DECLARE @Proc_Step_Name VARCHAR(200) = '';
        DECLARE @batch_id bigint;
        SET @batch_id = cast((format(getdate(), 'yyMMddHHmmssffff')) as bigint);
        DECLARE @Dataflow_Name VARCHAR(200) = 'BMIRD_STREP_PNEUMO Post-Processing Event';
        DECLARE @Package_Name VARCHAR(200) = 'sp_bmird_strep_pneumo_datamart_postprocessing';

        if @debug = 'true' print @batch_id;



        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';



        INSERT INTO [dbo].[job_flow_log] ( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count], [msg_description1])
        VALUES ( @batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, 0, LEFT('PHC_ID List-' + @phc_uids, 500));


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #INVKEYS';


        /**
            Creating a dataset of investigation keys pertaining to specific conditions
        **/
        SELECT BC.*, C.CONDITION_CD
        into #INVKEYS
        FROM
            dbo.BMIRD_CASE BC with (nolock)
                INNER JOIN
            dbo.CONDITION C with (nolock) ON BC.CONDITION_KEY = C.CONDITION_KEY
                INNER JOIN
            dbo.INVESTIGATION I with (nolock) ON BC.INVESTIGATION_KEY = I.INVESTIGATION_KEY
        WHERE (BC.INVESTIGATION_KEY <> 1) AND (C.CONDITION_CD in ('11723','11717','11720'))
          AND (I.RECORD_STATUS_CD = 'ACTIVE') AND I.CASE_UID IN (SELECT value FROM STRING_SPLIT(@phc_uids, ','))
        ORDER BY BC.INVESTIGATION_KEY;


        if @debug = 'true' select @Proc_Step_Name as step, * from #INVKEYS;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = 'Generating #BMIRD_PATIENT1';

        /**
        Creating a dataset of all patient details pertaining to BMIRD case and the same conditions
        **/

        select  BC.PATIENT_KEY, BC.INVESTIGATION_KEY,
                BC.TYPES_OF_OTHER_INFECTION	AS TYPE_INFECTION_OTHER_SPECIFY,
                BC.BACTERIAL_SPECIES_ISOLATED AS BACTERIAL_SPECIES_ISOLATED,
                BC.BACTERIAL_OTHER_ISOLATED	AS	BACTERIAL_SPECIES_ISOLATED_OTH,
                BC.FIRST_POSITIVE_CULTURE_DT AS FIRST_POSITIVE_CULTURE_DT,
                BC.STERILE_SITE_OTHER AS STERILE_SITE_OTHER,
                BC.INTBODYSITE AS INTERNAL_BODY_SITE,
                BC.OTHNONSTER AS NON_STERILE_SITE_OTHER,
                BC.UNDERLYING_CONDITION_IND	AS	UNDERLYING_CONDITION_IND,
                BC.OTHER_MALIGNANCY	AS OTHER_MALIGNANCY,
                BC.ORGAN_TRANSPLANT	AS ORGAN_TRANSPLANT,
                BC.UNDERLYING_CONDITIONS_OTHER	AS	OTHER_PRIOR_ILLNESS_1,
                BC.OTHILL2 AS OTHER_PRIOR_ILLNESS_2,
                BC.OTHILL3 AS OTHER_PRIOR_ILLNESS_3,
                BC.SAME_PATHOGEN_RECURRENT_IND	AS	SAME_PATHOGEN_RECURRENT,
                BC.CASE_REPORT_STATUS AS CASE_REPORT_STATUS,
                BC.OXACILLIN_INTERPRETATION	AS OXACILLIN_INTERPRETATION,
                BC.PERSISTENT_DISEASE_IND AS PERSISTENT_DISEASE_IND,
                BC.FIRST_ADDITIONAL_SPECIMEN_DT	AS ADD_CULTURE_1_DATE,
                BC.OTH_STREP_PNEUMO1_CULT_SITES	AS ADD_CULTURE_1_OTHER_SITE,
                BC.SECOND_ADDITIONAL_SPECIMEN_DT AS ADD_CULTURE_2_DATE,
                BC.OTH_STREP_PNEUMO2_CULT_SITES	AS	ADD_CULTURE_2_OTHER_SITE,
                BC.PNEUVACC_RECEIVED_IND AS VACCINE_POLYSACCHARIDE,
                BC.PNEUCONJ_RECEIVED_IND AS	VACCINE_CONJUGATE,
                BC.OXACILLIN_ZONE_SIZE AS OXACILLIN_ZONE_SIZE,
                BC.CULTURE_SEROTYPE AS CULTURE_SEROTYPE,
                BC.OTHSEROTYPE AS OTHSEROTYPE,
                BC.ANTIMICROBIAL_GRP_KEY,
                BC.BMIRD_MULTI_VAL_GRP_KEY,
                C.CONDITION_CD AS DISEASE_CD,
                C.CONDITION_SHORT_NM AS DISEASE,
                P.PATIENT_local_id AS PATIENT_LOCAL_ID,
                P.PATIENT_FIRST_NAME AS PATIENT_FIRST_NAME,
                P.PATIENT_LAST_NAME AS PATIENT_LAST_NAME,
                P.PATIENT_DOB AS PATIENT_DOB,
                P.PATIENT_CURRENT_SEX AS PATIENT_CURRENT_SEX,
                P.PATIENT_AGE_REPORTED AS AGE_REPORTED,
                P.PATIENT_AGE_REPORTED_UNIT AS AGE_REPORTED_UNIT,
                P.PATIENT_ETHNICITY AS PATIENT_ETHNICITY ,
                P.PATIENT_STREET_ADDRESS_1 AS PATIENT_STREET_ADDRESS_1,
                P.PATIENT_STREET_ADDRESS_2 AS PATIENT_STREET_ADDRESS_2,
                P.PATIENT_CITY AS PATIENT_CITY,
                P.PATIENT_STATE AS PATIENT_STATE,
                P.PATIENT_ZIP AS PATIENT_ZIP,
                P.PATIENT_COUNTY AS PATIENT_COUNTY,
                P.PATIENT_RACE_CALCULATED AS RACE_CALCULATED,
                P.PATIENT_RACE_CALC_DETAILS AS  RACE_CALC_DETAILS,
                ''+
                CASE
                    WHEN LEN(TRIM(PATIENT_STREET_ADDRESS_2)) > 0
                        THEN TRIM(PATIENT_STREET_ADDRESS_2)
                    ELSE ''
                    END +
                CASE
                    WHEN LEN(TRIM(PATIENT_CITY)) > 0
                        THEN ',' + TRIM(PATIENT_CITY)
                    ELSE ''
                    END +
                CASE
                    WHEN LEN(TRIM(PATIENT_COUNTY)) > 0
                        THEN ',' + TRIM(PATIENT_COUNTY)
                    ELSE ''
                    END +
                CASE
                    WHEN LEN(TRIM(PATIENT_ZIP)) > 0
                        THEN ',' + TRIM(PATIENT_ZIP)
                    ELSE ''
                    END +
                CASE
                    WHEN LEN(TRIM(PATIENT_STATE)) > 0
                        THEN ',' + TRIM(PATIENT_STATE)
                    ELSE ''
                    END as PATIENT_ADDRESS
        into #BMIRD_PATIENT1
        from #INVKEYS BC
                 left join dbo.D_PATIENT as P with (nolock)
                           on BC.PATIENT_KEY = P.PATIENT_key
                 left join dbo.CONDITION as C with (nolock)
                           on C.CONDITION_KEY = BC.CONDITION_KEY
                               AND P.PATIENT_KEY <> 1
        ;

        if @debug = 'true' select @Proc_Step_Name as step, * from #BMIRD_PATIENT1;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #BMIRD_PAT_INV';

/**
    Create dataset of investigation information from the prior dataset but filtered for only active and case_type <> 'S'
 */
        select bpa.*,
               i.INV_LOCAL_ID AS INVESTIGATION_LOCAL_ID,
               i.EARLIEST_RPT_TO_CNTY_DT,
               i.HSPTLIZD_IND AS HOSPITALIZED,
               i.HSPTL_ADMISSION_DT AS HOSPITALIZED_ADMISSION_DATE,
               i.HSPTL_DISCHARGE_DT AS HOSPITALIZED_DISCHARGE_DATE,
               i.HSPTL_DURATION_DAYS AS HOSPITALIZED_DURATION_DAYS,
               i.ILLNESS_ONSET_DT AS ILLNESS_ONSET_DATE,
               i.ILLNESS_END_DT AS ILLNESS_END_DATE,
               i.DIE_FRM_THIS_ILLNESS_IND AS DIE_FRM_THIS_ILLNESS_IND,
               i.INV_CASE_STATUS AS CASE_STATUS,
               i.CASE_RPT_MMWR_WK AS MMWR_WEEK,
               i.CASE_RPT_MMWR_YR AS MMWR_YEAR,
               i.CASE_OID AS PROGRAM_JURISDICTION_OID,
               i.INV_COMMENTS AS GENERAL_COMMENTS,
               em.ADD_TIME AS PHC_ADD_TIME,
               em.LAST_CHG_TIME AS PHC_LAST_CHG_TIME,
               i.EARLIEST_RPT_TO_STATE_DT,
               o.ORGANIZATION_NAME  AS HOSPITAL_NAME
        into #BMIRD_PAT_INV
        from #BMIRD_PATIENT1 as bpa
                 left join dbo.v_nrt_inv_keys_attrs_mapping as inv
                           on bpa.investigation_key = inv.investigation_key
                 left join dbo.INVESTIGATION i with (nolock)
                           on i.INVESTIGATION_KEY  = bpa.INVESTIGATION_KEY and i.INVESTIGATION_KEY <> 1
                 left join dbo.EVENT_METRIC em with (nolock)
                           on em.event_uid = i.CASE_UID
                 left outer join dbo.D_ORGANIZATION o with (nolock)
                                 on inv.ADT_HSPTL_KEY = o.ORGANIZATION_KEY and o.ORGANIZATION_KEY <> 1
        WHERE (i.RECORD_STATUS_CD <> 'INACTIVE') AND (i.CASE_TYPE <> 'S');


        if @debug = 'true' select @Proc_Step_Name as step, * from #BMIRD_PAT_INV;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #BMIRD_WITH_EVENT_DATE';


        /**
            Get the earliest date from the four date columns
            PHC_ADD_TIME, EARLIEST_RPT_TO_STATE_DT, FIRST_POSITIVE_CULTURE_DT, ILLNESS_ONSET_DATE
            and assign the corresponding column name to EVENT_TYP and retain the min value in a new column EVENT_DATE
         */
        SELECT *,
               CASE
                   WHEN PHC_ADD_TIME = (
                       SELECT MIN(dt)
                       FROM (
                                VALUES (PHC_ADD_TIME), (EARLIEST_RPT_TO_STATE_DT), (FIRST_POSITIVE_CULTURE_DT), (ILLNESS_ONSET_DATE)
                            ) AS v(dt)
                   ) THEN 'Investigation Add Date'
                   WHEN EARLIEST_RPT_TO_STATE_DT = (
                       SELECT MIN(dt)
                       FROM (
                                VALUES (PHC_ADD_TIME), (EARLIEST_RPT_TO_STATE_DT), (FIRST_POSITIVE_CULTURE_DT), (ILLNESS_ONSET_DATE)
                            ) AS v(dt)
                   ) THEN 'Earliest Date Reported to State'
                   WHEN FIRST_POSITIVE_CULTURE_DT = (
                       SELECT MIN(dt)
                       FROM (
                                VALUES (PHC_ADD_TIME), (EARLIEST_RPT_TO_STATE_DT), (FIRST_POSITIVE_CULTURE_DT), (ILLNESS_ONSET_DATE)
                            ) AS v(dt)
                   ) THEN 'Date First Positive Culture Obtained'
                   WHEN ILLNESS_ONSET_DATE = (
                       SELECT MIN(dt)
                       FROM (
                                VALUES (PHC_ADD_TIME), (EARLIEST_RPT_TO_STATE_DT), (FIRST_POSITIVE_CULTURE_DT), (ILLNESS_ONSET_DATE)
                            ) AS v(dt)
                   ) THEN 'Illness Onset Date'
                   END AS EVENT_DATE_TYPE,
               (
                   SELECT MIN(dt)
                   FROM (
                            VALUES (PHC_ADD_TIME), (EARLIEST_RPT_TO_STATE_DT), (FIRST_POSITIVE_CULTURE_DT), (ILLNESS_ONSET_DATE)
                        ) AS v(dt)
               ) AS EVENT_DATE
        into #BMIRD_WITH_EVENT_DATE
        FROM #BMIRD_PAT_INV;

        if @debug = 'true' select @Proc_Step_Name as step, * from #BMIRD_WITH_EVENT_DATE;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        /**
        Antimicrobial Data Processing -
        Retrive the BatchEntry Answers from ANTIMICROBIAL table and pivoting to 8 (Max) + 1 Columns

        Step 1: Create Antimicrobial tables with only Pencillin and everything except Pencillin
        Step 2: Merge the two tables together
        Step 3: Create a new table with the merged data and add a counter column
        Step 4: Based on whether the counter is greater than 8, create two new tables
        Step 5: For counter values less than or equal to 8, create a new table with the columns transposed
        Step 6: For counter values greater than 8, create a new table with the columns concatenated
        Step 7: Merge the tables so that both <= 8 and > 8 results are included
        **/

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #ANTIMICRO1A and #ANTIMICRO1B';


        -- Step 1: Create Antimicrobial tables with only Pencillin and everything except Pencillin
        -- Create 2 tables ANTIMICRO1A (with Only Pencillin) and ANTIMICRO1B (everything except Pencillin) and merge them together
        -- The Antimicrobial tables are joined to the BMIRD_PATIENT1 table using the Antimicrobial Group Key.
        -- The result is a dataset that contains all the relevant information for each patient, including their antimicrobial susceptibility results.


        SELECT
            bc.INVESTIGATION_KEY,
            a.ANTIMICROBIAL_KEY,
            a.ANTIMICROBIAL_AGENT_TESTED_IND AS ANTIMICROBIAL_AGENT_TESTED_,
            a.SUSCEPTABILITY_METHOD AS SUSCEPTABILITY_METHOD_,
            a.S_I_R_U_RESULT AS S_I_R_U_RESULT_,
            a.MIC_SIGN AS MIC_SIGN_,
            CASE
                WHEN a.MIC_VALUE IS NULL THEN REPLICATE(' ', 44) + '.'
                ELSE RIGHT(REPLICATE(' ', 50) + RTRIM(CAST(a.MIC_VALUE AS VARCHAR(50))), 50)
                END AS MIC_VALUE_,
            1 as SORT_ORDER
        into #ANTIMICRO1A
        FROM #BMIRD_PATIENT1 bc
                 INNER JOIN dbo.ANTIMICROBIAL a with (nolock)
                            ON bc.ANTIMICROBIAL_GRP_KEY = a.ANTIMICROBIAL_GRP_KEY
        WHERE a.ANTIMICROBIAL_GRP_KEY <> 1 AND a.ANTIMICROBIAL_AGENT_TESTED_IND = 'PENICILLIN'

        ;

        if @debug = 'true' select @Proc_Step_Name as step, * from #ANTIMICRO1A;


        SELECT
            bc.INVESTIGATION_KEY,
            a.ANTIMICROBIAL_KEY,
            a.ANTIMICROBIAL_AGENT_TESTED_IND AS ANTIMICROBIAL_AGENT_TESTED_ ,
            a.SUSCEPTABILITY_METHOD AS SUSCEPTABILITY_METHOD_,
            a.S_I_R_U_RESULT AS S_I_R_U_RESULT_,
            a.MIC_SIGN AS MIC_SIGN_,
            CASE
                WHEN a.MIC_VALUE IS NULL THEN REPLICATE(' ', 44) + '.'
                ELSE RIGHT(REPLICATE(' ', 50) + RTRIM(CAST(a.MIC_VALUE AS VARCHAR(50))), 50)
                END AS MIC_VALUE_,
            9 AS SORT_ORDER
        into #ANTIMICRO1B
        FROM #BMIRD_PATIENT1 bc
                 INNER JOIN dbo.ANTIMICROBIAL a with (nolock)  ON bc.ANTIMICROBIAL_GRP_KEY = a.ANTIMICROBIAL_GRP_KEY
        WHERE a.ANTIMICROBIAL_GRP_KEY <> 1 AND a.ANTIMICROBIAL_AGENT_TESTED_IND <> 'PENICILLIN'
        ;

        if @debug = 'true' select @Proc_Step_Name as step, * from #ANTIMICRO1B;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #ANTIMICRO2_A and #ANTIMICRO2_B Sorted';

        -- Step 2: Merge the two tables together
        SELECT *
        into #ANTIMICRO1
        FROM #ANTIMICRO1A
        UNION ALL
        SELECT *
        FROM #ANTIMICRO1B;
        -- Step 3: Create a new table with the merged data and add a counter column
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY INVESTIGATION_KEY ORDER BY SORT_ORDER, ANTIMICROBIAL_KEY) AS COUNTER
        into #ANTIMICRO2
        FROM #ANTIMICRO1;
        if @debug = 'true' select @Proc_Step_Name as step, * from #ANTIMICRO2;

        -- Step 4: Based on whether the counter is greater than 8, create two new tables
        SELECT *
        into #ANTIMICRO2_A
        FROM #ANTIMICRO2 WHERE COUNTER > 8;

        SELECT *
        into #ANTIMICRO2_B
        FROM #ANTIMICRO2 WHERE COUNTER <= 8;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #BMIRD_ANTIMICRO_1';


        -- Step 5: For counter values less than or equal to 8, create a new table with the columns transposed
        SELECT
            INVESTIGATION_KEY,
            MAX(CASE WHEN COUNTER = 1 THEN ANTIMICROBIAL_AGENT_TESTED_ END) AS ANTIMICROBIAL_AGENT_TESTED_1,
            MAX(CASE WHEN COUNTER = 1 THEN SUSCEPTABILITY_METHOD_ END) AS SUSCEPTABILITY_METHOD_1,
            MAX(CASE WHEN COUNTER = 1 THEN S_I_R_U_RESULT_ END) AS S_I_R_U_RESULT_1,
            MAX(CASE WHEN COUNTER = 1 THEN MIC_SIGN_ END) AS MIC_SIGN_1,
            MAX(CASE WHEN COUNTER = 1 THEN MIC_VALUE_ END) AS MIC_VALUE_1,
            MAX(CASE WHEN COUNTER = 2 THEN ANTIMICROBIAL_AGENT_TESTED_ END) AS ANTIMICROBIAL_AGENT_TESTED_2,
            MAX(CASE WHEN COUNTER = 2 THEN SUSCEPTABILITY_METHOD_ END) AS SUSCEPTABILITY_METHOD_2,
            MAX(CASE WHEN COUNTER = 2 THEN S_I_R_U_RESULT_ END) AS S_I_R_U_RESULT_2,
            MAX(CASE WHEN COUNTER = 2 THEN MIC_SIGN_ END) AS MIC_SIGN_2,
            MAX(CASE WHEN COUNTER = 2 THEN MIC_VALUE_ END) AS MIC_VALUE_2,
            MAX(CASE WHEN COUNTER = 3 THEN ANTIMICROBIAL_AGENT_TESTED_ END) AS ANTIMICROBIAL_AGENT_TESTED_3,
            MAX(CASE WHEN COUNTER = 3 THEN SUSCEPTABILITY_METHOD_ END) AS SUSCEPTABILITY_METHOD_3,
            MAX(CASE WHEN COUNTER = 3 THEN S_I_R_U_RESULT_ END) AS S_I_R_U_RESULT_3,
            MAX(CASE WHEN COUNTER = 3 THEN MIC_SIGN_ END) AS MIC_SIGN_3,
            MAX(CASE WHEN COUNTER = 3 THEN MIC_VALUE_ END) AS MIC_VALUE_3,
            MAX(CASE WHEN COUNTER = 4 THEN ANTIMICROBIAL_AGENT_TESTED_ END) AS ANTIMICROBIAL_AGENT_TESTED_4,
            MAX(CASE WHEN COUNTER = 4 THEN SUSCEPTABILITY_METHOD_ END) AS SUSCEPTABILITY_METHOD_4,
            MAX(CASE WHEN COUNTER = 4 THEN S_I_R_U_RESULT_ END) AS S_I_R_U_RESULT_4,
            MAX(CASE WHEN COUNTER = 4 THEN MIC_SIGN_ END) AS MIC_SIGN_4,
            MAX(CASE WHEN COUNTER = 4 THEN MIC_VALUE_ END) AS MIC_VALUE_4,
            MAX(CASE WHEN COUNTER = 5 THEN ANTIMICROBIAL_AGENT_TESTED_ END) AS ANTIMICROBIAL_AGENT_TESTED_5,
            MAX(CASE WHEN COUNTER = 5 THEN SUSCEPTABILITY_METHOD_ END) AS SUSCEPTABILITY_METHOD_5,
            MAX(CASE WHEN COUNTER = 5 THEN S_I_R_U_RESULT_ END) AS S_I_R_U_RESULT_5,
            MAX(CASE WHEN COUNTER = 5 THEN MIC_SIGN_ END) AS MIC_SIGN_5,
            MAX(CASE WHEN COUNTER = 5 THEN MIC_VALUE_ END) AS MIC_VALUE_5,
            MAX(CASE WHEN COUNTER = 6 THEN ANTIMICROBIAL_AGENT_TESTED_ END) AS ANTIMICROBIAL_AGENT_TESTED_6,
            MAX(CASE WHEN COUNTER = 6 THEN SUSCEPTABILITY_METHOD_ END) AS SUSCEPTABILITY_METHOD_6,
            MAX(CASE WHEN COUNTER = 6 THEN S_I_R_U_RESULT_ END) AS S_I_R_U_RESULT_6,
            MAX(CASE WHEN COUNTER = 6 THEN MIC_SIGN_ END) AS MIC_SIGN_6,
            MAX(CASE WHEN COUNTER = 6 THEN MIC_VALUE_ END) AS MIC_VALUE_6,
            MAX(CASE WHEN COUNTER = 7 THEN ANTIMICROBIAL_AGENT_TESTED_ END) AS ANTIMICROBIAL_AGENT_TESTED_7,
            MAX(CASE WHEN COUNTER = 7 THEN SUSCEPTABILITY_METHOD_ END) AS SUSCEPTABILITY_METHOD_7,
            MAX(CASE WHEN COUNTER = 7 THEN S_I_R_U_RESULT_ END) AS S_I_R_U_RESULT_7,
            MAX(CASE WHEN COUNTER = 7 THEN MIC_SIGN_ END) AS MIC_SIGN_7,
            MAX(CASE WHEN COUNTER = 7 THEN MIC_VALUE_ END) AS MIC_VALUE_7,
            MAX(CASE WHEN COUNTER = 8 THEN ANTIMICROBIAL_AGENT_TESTED_ END) AS ANTIMICROBIAL_AGENT_TESTED_8,
            MAX(CASE WHEN COUNTER = 8 THEN SUSCEPTABILITY_METHOD_ END) AS SUSCEPTABILITY_METHOD_8,
            MAX(CASE WHEN COUNTER = 8 THEN S_I_R_U_RESULT_ END) AS S_I_R_U_RESULT_8,
            MAX(CASE WHEN COUNTER = 8 THEN MIC_SIGN_ END) AS MIC_SIGN_8,
            MAX(CASE WHEN COUNTER = 8 THEN MIC_VALUE_ END) AS MIC_VALUE_8
        into #ANTIMICRO4
        FROM #ANTIMICRO2_B
        GROUP BY INVESTIGATION_KEY
        ;

        select
            t2.*,
            t1.ANTIMICROBIAL_AGENT_TESTED_1,
            t1.SUSCEPTABILITY_METHOD_1,
            t1.S_I_R_U_RESULT_1,
            t1.MIC_SIGN_1,
            t1.MIC_VALUE_1,
            t1.ANTIMICROBIAL_AGENT_TESTED_2,
            t1.SUSCEPTABILITY_METHOD_2,
            t1.S_I_R_U_RESULT_2,
            t1.MIC_SIGN_2,
            t1.MIC_VALUE_2,
            t1.ANTIMICROBIAL_AGENT_TESTED_3,
            t1.SUSCEPTABILITY_METHOD_3,
            t1.S_I_R_U_RESULT_3,
            t1.MIC_SIGN_3,
            t1.MIC_VALUE_3,
            t1.ANTIMICROBIAL_AGENT_TESTED_4,
            t1.SUSCEPTABILITY_METHOD_4,
            t1.S_I_R_U_RESULT_4,
            t1.MIC_SIGN_4,
            t1.MIC_VALUE_4,
            t1.ANTIMICROBIAL_AGENT_TESTED_5,
            t1.SUSCEPTABILITY_METHOD_5,
            t1.S_I_R_U_RESULT_5,
            t1.MIC_SIGN_5,
            t1.MIC_VALUE_5,
            t1.ANTIMICROBIAL_AGENT_TESTED_6,
            t1.SUSCEPTABILITY_METHOD_6,
            t1.S_I_R_U_RESULT_6,
            t1.MIC_SIGN_6,
            t1.MIC_VALUE_6,
            t1.ANTIMICROBIAL_AGENT_TESTED_7,
            t1.SUSCEPTABILITY_METHOD_7,
            t1.S_I_R_U_RESULT_7,
            t1.MIC_SIGN_7,
            t1.MIC_VALUE_7,
            t1.ANTIMICROBIAL_AGENT_TESTED_8,
            t1.SUSCEPTABILITY_METHOD_8,
            t1.S_I_R_U_RESULT_8,
            t1.MIC_SIGN_8,
            t1.MIC_VALUE_8
        into #BMIRD_ANTIMICRO_1
        from #BMIRD_WITH_EVENT_DATE t2
                 left join #ANTIMICRO4 t1
                           on t1.INVESTIGATION_KEY = t2.INVESTIGATION_KEY;

        if @debug = 'true' select @Proc_Step_Name as step, * from #BMIRD_ANTIMICRO_1;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #ANTIMICRO2_AGENT_RESULT';

        -- Step 6: For counter values greater than 8, create a new table with the columns concatenated
        WITH ANTIMICRO2_A_CTE AS (
            SELECT
                INVESTIGATION_KEY,
                TRIM(ANTIMICROBIAL_AGENT_TESTED_) + ': ' + TRIM(S_I_R_U_RESULT_) AS CONCAT_COL
            FROM #ANTIMICRO2_A
        )
        SELECT
            INVESTIGATION_KEY,
            STRING_AGG(CONCAT_COL, ', ') WITHIN GROUP (ORDER BY CONCAT_COL) AS ANTIMIC_GT_8_AGENT_AND_RESULT
        INTO #ANTIMICRO2_AGENT_RESULT
        FROM ANTIMICRO2_A_CTE
        GROUP BY INVESTIGATION_KEY;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #BMIRD_ANTIMICRO_2';

        -- Step 7: Merge the tables so that both <= 8 and > 8 results are included to build BMIRD_ANTIMICRO_2
        SELECT
            b.*,
            c.ANTIMIC_GT_8_AGENT_AND_RESULT
        INTO #BMIRD_ANTIMICRO_2
        FROM #BMIRD_ANTIMICRO_1 b
                 LEFT JOIN #ANTIMICRO2_AGENT_RESULT c
                           ON b.INVESTIGATION_KEY = c.INVESTIGATION_KEY;

        if @debug = 'true' select @Proc_Step_Name as step, * from #BMIRD_ANTIMICRO_2;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        /**
        Conditions Data Processing -
        Retrieve Underlying Conditions from BMIRD_MULTI_VALUE_FIELD Table to 8 (Max) Columns

        Step 1: Create a dataset of all underlying conditions
        Step 2: Create a new table with the dataset and add a counter column
        Step 3: For counter values less than or equal to 8, create a new table with the columns transposed
        Step 4: For counter values greater than 8, create a new table with the columns concatenated
        Step 5: Merge the tables so that both <= 8 and > 8 results are included

        **/



        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #BMD127';

        -- Step 1: Create a dataset of all underlying conditions
        SELECT
            distinct bc.INVESTIGATION_KEY,
                     a.UNDERLYING_CONDITION_NM as UNDERLYING_CONDITION_
        into #BMD127
        FROM #BMIRD_PATIENT1 bc
                 INNER JOIN dbo.BMIRD_MULTI_VALUE_FIELD a with (nolock)
                            on bc.BMIRD_MULTI_VAL_GRP_KEY = a.BMIRD_MULTI_VAL_GRP_KEY
        WHERE a.UNDERLYING_CONDITION_NM IS NOT NULL
        ;



        if @debug = 'true' select @Proc_Step_Name as step, * from #BMD127;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #BMD127_1';

        -- Step 2: Create a new table with the dataset and add a counter column
        -- Step 3: For counter values less than or equal to 8, create a new table with the columns transposed
        with cte1 as (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY INVESTIGATION_KEY ORDER BY UNDERLYING_CONDITION_) AS COUNTER
            FROM #BMD127
        )
           , cte2 as (
            select *
            from cte1
            WHERE COUNTER <= 8
        )
        SELECT INVESTIGATION_KEY,
               MAX(CASE WHEN COUNTER = 1 THEN UNDERLYING_CONDITION_ END) AS UNDERLYING_CONDITION_1,
               MAX(CASE WHEN COUNTER = 2 THEN UNDERLYING_CONDITION_ END) AS UNDERLYING_CONDITION_2,
               MAX(CASE WHEN COUNTER = 3 THEN UNDERLYING_CONDITION_ END) AS UNDERLYING_CONDITION_3,
               MAX(CASE WHEN COUNTER = 4 THEN UNDERLYING_CONDITION_ END) AS UNDERLYING_CONDITION_4,
               MAX(CASE WHEN COUNTER = 5 THEN UNDERLYING_CONDITION_ END) AS UNDERLYING_CONDITION_5,
               MAX(CASE WHEN COUNTER = 6 THEN UNDERLYING_CONDITION_ END) AS UNDERLYING_CONDITION_6,
               MAX(CASE WHEN COUNTER = 7 THEN UNDERLYING_CONDITION_ END) AS UNDERLYING_CONDITION_7,
               MAX(CASE WHEN COUNTER = 8 THEN UNDERLYING_CONDITION_ END) AS UNDERLYING_CONDITION_8
        into #BMD127_1
        from cte2
        group by INVESTIGATION_KEY;


        if @debug = 'true' select @Proc_Step_Name as step, * from #BMD127_1;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #BMIRD_ANTIMICRO_3';

        SELECT
            b.*,
            c.UNDERLYING_CONDITION_1,
            c.UNDERLYING_CONDITION_2,
            c.UNDERLYING_CONDITION_3,
            c.UNDERLYING_CONDITION_4,
            c.UNDERLYING_CONDITION_5,
            c.UNDERLYING_CONDITION_6,
            c.UNDERLYING_CONDITION_7,
            c.UNDERLYING_CONDITION_8
        INTO #BMIRD_ANTIMICRO_3
        FROM #BMIRD_ANTIMICRO_2 b
                 LEFT JOIN #BMD127_1 c
                           ON b.INVESTIGATION_KEY = c.INVESTIGATION_KEY;

        if @debug = 'true' select @Proc_Step_Name as step, * from #BMIRD_ANTIMICRO_3;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        /*
        Site Data Processing -
        Retrieve BMD125, BMD142 and BMD144 from BMIRD_MULTI_VALUE_FIELD and pivot into 3 columns

        Step 1: Create a dataset of all non-sterile sites
        Step 2: Create 2 datasets of all additional culture sites
        Step 3: Merge the datasets to create a new table with the columns transposed
        Step 4: Merge the new table with the BMIRD_ANTIMICRO table
        */

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #DM_BMD125, #DM_BMD142 and #DM_BMD144';

        -- Step 1: Create a dataset of all non-sterile sites
        SELECT
            distinct bc.INVESTIGATION_KEY,
                     a.NON_STERILE_SITE AS NON_STERILE_SITE_
        into #DM_BMD125
        FROM #BMIRD_PATIENT1 bc
                 INNER JOIN dbo.BMIRD_MULTI_VALUE_FIELD a with (nolock)
                            on bc.BMIRD_MULTI_VAL_GRP_KEY = a.BMIRD_MULTI_VAL_GRP_KEY
        WHERE A.NON_STERILE_SITE IS NOT NULL
        ORDER BY bc.INVESTIGATION_KEY, a.NON_STERILE_SITE;

        -- Step 2: Create 2 datasets of all additional culture sites
        SELECT
            distinct bc.INVESTIGATION_KEY,
                     a.STREP_PNEUMO_1_CULTURE_SITES AS ADD_CULTURE_1_SITE_
        into #DM_BMD142
        FROM #BMIRD_PATIENT1 bc
                 INNER JOIN dbo.BMIRD_MULTI_VALUE_FIELD a with (nolock)
                            on bc.BMIRD_MULTI_VAL_GRP_KEY = a.BMIRD_MULTI_VAL_GRP_KEY
        WHERE A.STREP_PNEUMO_1_CULTURE_SITES IS NOT NULL
        ORDER BY bc.INVESTIGATION_KEY, 	a.STREP_PNEUMO_1_CULTURE_SITES;

        SELECT
            distinct bc.INVESTIGATION_KEY,
                     a.STREP_PNEUMO_2_CULTURE_SITES  AS ADD_CULTURE_2_SITE_
        into #DM_BMD144
        FROM #BMIRD_PATIENT1 bc
                 INNER JOIN dbo.BMIRD_MULTI_VALUE_FIELD a with (nolock)
                            on bc.BMIRD_MULTI_VAL_GRP_KEY = a.BMIRD_MULTI_VAL_GRP_KEY
        WHERE A.STREP_PNEUMO_2_CULTURE_SITES IS NOT NULL
        ORDER BY bc.INVESTIGATION_KEY, 	a.STREP_PNEUMO_2_CULTURE_SITES;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #DM_BR7';


        -- Step 3: Merge the datasets to create a new table with the columns transposed
        select d.INVESTIGATION_KEY, a.NON_STERILE_SITE_, b.ADD_CULTURE_1_SITE_, c.ADD_CULTURE_2_SITE_
        into #DM_BR7
        from #BMIRD_PATIENT1 d
                 left outer join #DM_BMD125 a on a.INVESTIGATION_KEY = d.INVESTIGATION_KEY
                 left outer join #DM_BMD142 b on b.INVESTIGATION_KEY = d.INVESTIGATION_KEY
                 left outer join #DM_BMD144 c on c.INVESTIGATION_KEY = d.INVESTIGATION_KEY
        where coalesce(a.NON_STERILE_SITE_, b.ADD_CULTURE_1_SITE_, c.ADD_CULTURE_2_SITE_) is not null ;

        with cte1 as  (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY INVESTIGATION_KEY
                       ORDER BY coalesce(NON_STERILE_SITE_, ADD_CULTURE_1_SITE_, ADD_CULTURE_2_SITE_)) AS COUNTER
            FROM #DM_BR7
        )
           , cte2 as (
            SELECT *
            FROM cte1 WHERE COUNTER <= 3
        )
        SELECT INVESTIGATION_KEY,
               MAX(CASE WHEN COUNTER = 1 THEN NON_STERILE_SITE_ END) AS NON_STERILE_SITE_1,
               MAX(CASE WHEN COUNTER = 1 THEN ADD_CULTURE_1_SITE_ END) AS ADD_CULTURE_1_SITE_1,
               MAX(CASE WHEN COUNTER = 1 THEN ADD_CULTURE_2_SITE_ END) AS ADD_CULTURE_2_SITE_1,
               MAX(CASE WHEN COUNTER = 2 THEN NON_STERILE_SITE_ END) AS NON_STERILE_SITE_2,
               MAX(CASE WHEN COUNTER = 2 THEN ADD_CULTURE_1_SITE_ END) AS ADD_CULTURE_1_SITE_2,
               MAX(CASE WHEN COUNTER = 2 THEN ADD_CULTURE_2_SITE_ END) AS ADD_CULTURE_2_SITE_2,
               MAX(CASE WHEN COUNTER = 3 THEN NON_STERILE_SITE_ END) AS NON_STERILE_SITE_3,
               MAX(CASE WHEN COUNTER = 3 THEN ADD_CULTURE_1_SITE_ END) AS ADD_CULTURE_1_SITE_3,
               MAX(CASE WHEN COUNTER = 3 THEN ADD_CULTURE_2_SITE_ END) AS ADD_CULTURE_2_SITE_3
        into #DM_BR7_T
        from cte2
        group by INVESTIGATION_KEY;

        if @debug = 'true' select @Proc_Step_Name as step, * from #DM_BR7_T;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #BMIRD_ANTIMICRO_4';


        -- Step 4: Merge the new table with the BMIRD_ANTIMICRO table to build BMIRD_ANTIMICRO_4
        SELECT
            b.*,
            c.NON_STERILE_SITE_1,
            c.ADD_CULTURE_1_SITE_1,
            c.ADD_CULTURE_2_SITE_1,
            c.NON_STERILE_SITE_2,
            c.ADD_CULTURE_1_SITE_2,
            c.ADD_CULTURE_2_SITE_2,
            c.NON_STERILE_SITE_3,
            c.ADD_CULTURE_1_SITE_3,
            c.ADD_CULTURE_2_SITE_3
        INTO #BMIRD_ANTIMICRO_4
        FROM #BMIRD_ANTIMICRO_3 b
                 LEFT JOIN #DM_BR7_T c
                           ON b.INVESTIGATION_KEY = c.INVESTIGATION_KEY;

        if @debug = 'true' select @Proc_Step_Name as step, * from #BMIRD_ANTIMICRO_4;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        /*
        Types of Infection Data Processing
        Retrieve BMD118 'Types of Infection' pivot to 10 columns

        Step 1: Create a dataset of all types of infections
        Step 2: Create a new table with the columns (based on a set of conditions).
                For rows that doesn't fall into that condition, they are marked as 0 and 1
        Step 3: Create a new table with the columns transposed for marked as 1
        Step 4: Create a new table with the columns concatenated for marked as 0
        Step 5: Merge the new table with the BMIRD_ANTIMICRO table
        */

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #DM_BMD118';

        -- Step 1: Create a dataset of all types of infections
        -- Step 2: Create a new table with the columns (based on a set of conditions). For rows that doesn't fall into that condition, they are marked as 0 and 1
        with cte as (
            SELECT
                distinct bc.INVESTIGATION_KEY,
                         a.TYPES_OF_INFECTIONS AS TYPES_OF_INFECTIONS_
            from #BMIRD_PATIENT1 bc
                     INNER JOIN dbo.BMIRD_MULTI_VALUE_FIELD a with (nolock)
                                on bc.BMIRD_MULTI_VAL_GRP_KEY = a.BMIRD_MULTI_VAL_GRP_KEY
        )
        SELECT
            INVESTIGATION_KEY,
            CASE
                WHEN TYPES_OF_INFECTIONS_ = 'Bacteremia without focus' THEN 'TYPE_INFECTION_BACTEREMIA'
                WHEN TYPES_OF_INFECTIONS_ = 'Pneumonia' THEN 'TYPE_INFECTION_PNEUMONIA'
                WHEN TYPES_OF_INFECTIONS_ = 'Meningitis' THEN 'TYPE_INFECTION_MENINGITIS'
                WHEN TYPES_OF_INFECTIONS_ = 'Empyema' THEN 'TYPE_INFECTION_EMPYEMA'
                WHEN TYPES_OF_INFECTIONS_ = 'Cellulitis' THEN 'TYPE_INFECTION_CELLULITIS'
                WHEN TYPES_OF_INFECTIONS_ = 'Peritonitis' THEN 'TYPE_INFECTION_PERITONITIS'
                WHEN TYPES_OF_INFECTIONS_ = 'Pericarditis' THEN 'TYPE_INFECTION_PERICARDITIS'
                WHEN TYPES_OF_INFECTIONS_ = 'Puerperal sepsis' THEN 'TYPE_INFECTION_PUERPERAL_SEP'
                WHEN TYPES_OF_INFECTIONS_ = 'Septic arthritis' THEN 'TYPE_INFECTION_SEP_ARTHRITIS'
                WHEN TYPES_OF_INFECTIONS_ = '' THEN ''
                ELSE TYPES_OF_INFECTIONS_
                END AS TYPES_OF_INFECTIONS_,
            CASE
                WHEN TYPES_OF_INFECTIONS_ IN ('Bacteremia without focus', 'Pneumonia', 'Meningitis', 'Empyema', 'Cellulitis', 'Peritonitis', 'Pericarditis', 'Puerperal sepsis', 'Septic arthritis', '') THEN 1
                ELSE 0
                END AS _mark_
        into #DM_BMD118
        FROM cte
        ;

        if @debug = 'true' select @Proc_Step_Name as step, * from #DM_BMD118;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #TYPE_INFECTION_INFO';

        -- Step 3: Create a new table with the columns transposed for marked as 1
        SELECT
            INVESTIGATION_KEY,
            MAX(CASE WHEN TYPES_OF_INFECTIONS_ = 'TYPE_INFECTION_BACTEREMIA' THEN 'Yes' ELSE 'No' END)
                AS TYPE_INFECTION_BACTEREMIA,
            MAX(CASE WHEN TYPES_OF_INFECTIONS_ = 'TYPE_INFECTION_PNEUMONIA' THEN 'Yes' ELSE 'No' END)
                AS TYPE_INFECTION_PNEUMONIA,
            MAX(CASE WHEN TYPES_OF_INFECTIONS_ = 'TYPE_INFECTION_MENINGITIS' THEN 'Yes' ELSE 'No' END)
                AS TYPE_INFECTION_MENINGITIS,
            MAX(CASE WHEN TYPES_OF_INFECTIONS_ = 'TYPE_INFECTION_EMPYEMA' THEN 'Yes' ELSE 'No' END)
                AS TYPE_INFECTION_EMPYEMA,
            MAX(CASE WHEN TYPES_OF_INFECTIONS_ = 'TYPE_INFECTION_CELLULITIS' THEN 'Yes' ELSE 'No' END)
                AS TYPE_INFECTION_CELLULITIS,
            MAX(CASE WHEN TYPES_OF_INFECTIONS_ = 'TYPE_INFECTION_PERITONITIS' THEN 'Yes' ELSE 'No' END)
                AS TYPE_INFECTION_PERITONITIS,
            MAX(CASE WHEN TYPES_OF_INFECTIONS_ = 'TYPE_INFECTION_PERICARDITIS' THEN 'Yes' ELSE 'No' END)
                AS TYPE_INFECTION_PERICARDITIS,
            MAX(CASE WHEN TYPES_OF_INFECTIONS_ = 'TYPE_INFECTION_PUERPERAL_SEP' THEN 'Yes' ELSE 'No' END)
                AS TYPE_INFECTION_PUERPERAL_SEP,
            MAX(CASE WHEN TYPES_OF_INFECTIONS_ = 'TYPE_INFECTION_SEP_ARTHRITIS' THEN 'Yes' ELSE 'No' END)
                AS TYPE_INFECTION_SEP_ARTHRITIS
        into #TYPE_INFECTION_INFO
        FROM #DM_BMD118
        WHERE _mark_ = 1
        GROUP BY INVESTIGATION_KEY;

        if @debug = 'true' select @Proc_Step_Name as step, * from #TYPE_INFECTION_INFO;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #TYPE_INFECTION_INFO_OTHERS';

        -- Step 4: Create a new table with the columns concatenated for marked as 0
        SELECT
            INVESTIGATION_KEY,
            STRING_AGG(TYPES_OF_INFECTIONS_, ',') WITHIN GROUP (ORDER BY TYPES_OF_INFECTIONS_ ASC)
                 AS TYPE_INFECTION_OTHERS_CONCAT,
            'No' as TYPE_INFECTION_BACTEREMIA,
            'No' as TYPE_INFECTION_PNEUMONIA,
            'No' as TYPE_INFECTION_MENINGITIS,
            'No' as TYPE_INFECTION_EMPYEMA,
            'No' as TYPE_INFECTION_CELLULITIS,
            'No' as TYPE_INFECTION_PERITONITIS,
            'No' as TYPE_INFECTION_PERICARDITIS,
            'No' as TYPE_INFECTION_PUERPERAL_SEP,
            'No' as TYPE_INFECTION_SEP_ARTHRITIS
        into #TYPE_INFECTION_INFO_OTHERS
        FROM #DM_BMD118
        WHERE _mark_ = 0
        GROUP BY INVESTIGATION_KEY;

        if @debug = 'true' select @Proc_Step_Name as step, * from #TYPE_INFECTION_INFO_OTHERS;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #BMIRD_ANTIMICRO_5';

        -- Step 5: Merge the new table with the BMIRD_ANTIMICRO table to build BMIRD_ANTIMICRO_5
        SELECT
            b.*,
            COALESCE(c.TYPE_INFECTION_BACTEREMIA,d.TYPE_INFECTION_BACTEREMIA) AS TYPE_INFECTION_BACTEREMIA,
            COALESCE(c.TYPE_INFECTION_PNEUMONIA,d.TYPE_INFECTION_PNEUMONIA) AS TYPE_INFECTION_PNEUMONIA,
            COALESCE(c.TYPE_INFECTION_MENINGITIS,d.TYPE_INFECTION_MENINGITIS) AS TYPE_INFECTION_MENINGITIS,
            COALESCE(c.TYPE_INFECTION_EMPYEMA,d.TYPE_INFECTION_EMPYEMA) AS TYPE_INFECTION_EMPYEMA,
            COALESCE(c.TYPE_INFECTION_CELLULITIS,d.TYPE_INFECTION_CELLULITIS) AS TYPE_INFECTION_CELLULITIS,
            COALESCE(c.TYPE_INFECTION_PERITONITIS,d.TYPE_INFECTION_PERITONITIS) AS TYPE_INFECTION_PERITONITIS,
            COALESCE(c.TYPE_INFECTION_PERICARDITIS,d.TYPE_INFECTION_PERICARDITIS) AS TYPE_INFECTION_PERICARDITIS,
            COALESCE(c.TYPE_INFECTION_PUERPERAL_SEP,d.TYPE_INFECTION_PUERPERAL_SEP) AS TYPE_INFECTION_PUERPERAL_SEP,
            COALESCE(c.TYPE_INFECTION_SEP_ARTHRITIS,d.TYPE_INFECTION_SEP_ARTHRITIS) AS TYPE_INFECTION_SEP_ARTHRITIS,
            d.TYPE_INFECTION_OTHERS_CONCAT
        INTO #BMIRD_ANTIMICRO_5
        FROM #BMIRD_ANTIMICRO_4 b
                 LEFT JOIN #TYPE_INFECTION_INFO c
                           ON b.INVESTIGATION_KEY = c.INVESTIGATION_KEY
                 LEFT JOIN #TYPE_INFECTION_INFO_OTHERS d
                           ON b.INVESTIGATION_KEY = d.INVESTIGATION_KEY;


        if @debug = 'true' select @Proc_Step_Name as step, * from #BMIRD_ANTIMICRO_5;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;



        /*
        Sterile Sites Data Processing -
        BMD122 'Sterile Sites from which Organism Isolated' pivot to 7 columns
        Step 1: Create a dataset of all sterile sites
        Step 2: Create a new table with the columns (based on a set of conditions).
            For rows that doesn't fall into that condition, they are marked as 0 and 1
        Step 3: Create a new table with the columns transposed for marked as 1
        Step 4: Create a new table with the columns concatenated for marked as 0
        Step 5: Merge the new table with the BMIRD_ANTIMICRO table
        */


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #DM_BMD122';

        -- Step 1: Create a dataset of all sterile sites
        -- Step 2: Create a new table with the columns (based on a set of conditions). For rows that doesn't fall into that condition, they are marked as 0 and 1
        with cte as (
            SELECT
                distinct bc.INVESTIGATION_KEY,
                         a.STERILE_SITE AS STERILE_SITE_
            FROM #BMIRD_PATIENT1 bc
                     INNER JOIN dbo.BMIRD_MULTI_VALUE_FIELD a with (nolock)
                                ON bc.BMIRD_MULTI_VAL_GRP_KEY = a.BMIRD_MULTI_VAL_GRP_KEY
        )
        SELECT
            INVESTIGATION_KEY,
            CASE
                WHEN STERILE_SITE_ = 'Blood' THEN 'STERILE_SITE_BLOOD'
                WHEN STERILE_SITE_ = 'Cerebral Spinal Fluid' THEN 'STERILE_SITE_CEREBRAL_SF'
                WHEN STERILE_SITE_ = 'Pleural Fluid' THEN 'STERILE_SITE_PLEURAL_FLUID'
                WHEN STERILE_SITE_ = 'Peritoneal fluid' THEN 'STERILE_SITE_PERITONEAL_FLUID'
                WHEN STERILE_SITE_ = 'Pericardial Fluid' THEN 'STERILE_SITE_PERICARDIAL_FLUID'
                WHEN STERILE_SITE_ = 'Joint' THEN 'STERILE_SITE_JOINT_FLUID'
                WHEN STERILE_SITE_ = '' THEN ''
                ELSE STERILE_SITE_
                END AS STERILE_SITE_,
            CASE
                WHEN STERILE_SITE_ IN ('Blood', 'Cerebral Spinal Fluid', 'Pleural Fluid', 'Peritoneal fluid', 'Pericardial Fluid', 'Joint', '') THEN 1
                ELSE 0
                END AS _mark_
        into #DM_BMD122
        FROM cte;

        if @debug = 'true' select @Proc_Step_Name as step, * from #DM_BMD122;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #STEP_STERILE_SITE_INFO';

        -- Step 3: Create a new table with the columns transposed for marked as 1
        SELECT
            INVESTIGATION_KEY,
            MAX(CASE WHEN STERILE_SITE_ = 'STERILE_SITE_BLOOD' THEN 'Yes' ELSE 'No' END)
                AS STERILE_SITE_BLOOD,
            MAX(CASE WHEN STERILE_SITE_ = 'STERILE_SITE_CEREBRAL_SF' THEN 'Yes' ELSE 'No' END)
                AS STERILE_SITE_CEREBRAL_SF,
            MAX(CASE WHEN STERILE_SITE_ = 'STERILE_SITE_PLEURAL_FLUID' THEN 'Yes' ELSE 'No' END)
                AS STERILE_SITE_PLEURAL_FLUID,
            MAX(CASE WHEN STERILE_SITE_ = 'STERILE_SITE_PERITONEAL_FLUID' THEN 'Yes' ELSE 'No' END)
                AS STERILE_SITE_PERITONEAL_FLUID,
            MAX(CASE WHEN STERILE_SITE_ = 'STERILE_SITE_PERICARDIAL_FLUID' THEN 'Yes' ELSE 'No' END)
                AS STERILE_SITE_PERICARDIAL_FLUID,
            MAX(CASE WHEN STERILE_SITE_ = 'STERILE_SITE_JOINT_FLUID' THEN 'Yes' ELSE 'No' END)
                AS STERILE_SITE_JOINT_FLUID
        into #STEP_STERILE_SITE_INFO
        FROM #DM_BMD122
        WHERE _mark_ = 1
        GROUP BY INVESTIGATION_KEY;

        if @debug = 'true' select @Proc_Step_Name as step, * from #STEP_STERILE_SITE_INFO;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #STEP_STERILE_SITE_INFO_OTHERS';

        --Step 4: Create a new table with the columns concatenated for marked as 0
        SELECT
            INVESTIGATION_KEY,
            STRING_AGG(STERILE_SITE_, ',') WITHIN GROUP (ORDER BY STERILE_SITE_ DESC)
                 AS STERILE_SITE_OTHERS_CONCAT,
            'No' as STERILE_SITE_BLOOD,
            'No' as STERILE_SITE_CEREBRAL_SF,
            'No' as STERILE_SITE_PLEURAL_FLUID,
            'No' as STERILE_SITE_PERITONEAL_FLUID,
            'No' as STERILE_SITE_PERICARDIAL_FLUID,
            'No' as STERILE_SITE_JOINT_FLUID
        into #STEP_STERILE_SITE_INFO_OTHERS
        FROM #DM_BMD122
        WHERE _mark_ = 0
        GROUP BY INVESTIGATION_KEY;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Generating #BMIRD_ANTIMICRO_6';

        -- Step 5: Merge the new table with the BMIRD_ANTIMICRO table to build BMIRD_ANTIMICRO_6
        SELECT
            b.*,
            COALESCE(c.STERILE_SITE_BLOOD,d.STERILE_SITE_BLOOD) AS STERILE_SITE_BLOOD,
            COALESCE(c.STERILE_SITE_CEREBRAL_SF,d.STERILE_SITE_CEREBRAL_SF) AS STERILE_SITE_CEREBRAL_SF,
            COALESCE(c.STERILE_SITE_PLEURAL_FLUID,d.STERILE_SITE_PLEURAL_FLUID) AS STERILE_SITE_PLEURAL_FLUID,
            COALESCE(c.STERILE_SITE_PERITONEAL_FLUID,d.STERILE_SITE_PERITONEAL_FLUID) AS STERILE_SITE_PERITONEAL_FLUID,
            COALESCE(c.STERILE_SITE_PERICARDIAL_FLUID,d.STERILE_SITE_PERICARDIAL_FLUID) AS STERILE_SITE_PERICARDIAL_FLUID,
            COALESCE(c.STERILE_SITE_JOINT_FLUID,d.STERILE_SITE_JOINT_FLUID) AS STERILE_SITE_JOINT_FLUID,
            d.STERILE_SITE_OTHERS_CONCAT
        INTO #BMIRD_ANTIMICRO_6
        FROM #BMIRD_ANTIMICRO_5 b
                 LEFT JOIN #STEP_STERILE_SITE_INFO c
                           ON b.INVESTIGATION_KEY = c.INVESTIGATION_KEY
                 LEFT JOIN #STEP_STERILE_SITE_INFO_OTHERS d
                           ON b.INVESTIGATION_KEY = d.INVESTIGATION_KEY;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Update dbo.BMIRD_STREP_PNEUMO_DATAMART';

        UPDATE tgt
        SET
            tgt.PATIENT_LOCAL_ID = src.PATIENT_LOCAL_ID,
            tgt.INVESTIGATION_LOCAL_ID = src.INVESTIGATION_LOCAL_ID,
            tgt.DISEASE = src.DISEASE,
            tgt.DISEASE_CD = src.DISEASE_CD,
            tgt.PATIENT_FIRST_NAME = src.PATIENT_FIRST_NAME,
            tgt.PATIENT_LAST_NAME = src.PATIENT_LAST_NAME,
            tgt.PATIENT_DOB = src.PATIENT_DOB,
            tgt.PATIENT_CURRENT_SEX = src.PATIENT_CURRENT_SEX,
            tgt.AGE_REPORTED = src.AGE_REPORTED,
            tgt.AGE_REPORTED_UNIT = src.AGE_REPORTED_UNIT,
            tgt.PATIENT_STREET_ADDRESS_1 = src.PATIENT_STREET_ADDRESS_1,
            tgt.PATIENT_STREET_ADDRESS_2 = src.PATIENT_STREET_ADDRESS_2,
            tgt.PATIENT_CITY = src.PATIENT_CITY,
            tgt.PATIENT_STATE = src.PATIENT_STATE,
            tgt.PATIENT_ZIP = src.PATIENT_ZIP,
            tgt.PATIENT_COUNTY = src.PATIENT_COUNTY,
            tgt.PATIENT_ETHNICITY = src.PATIENT_ETHNICITY,
            tgt.RACE_CALCULATED = src.RACE_CALCULATED,
            tgt.RACE_CALC_DETAILS = src.RACE_CALC_DETAILS,
            tgt.EARLIEST_RPT_TO_CNTY_DT = src.EARLIEST_RPT_TO_CNTY_DT,
            tgt.EARLIEST_RPT_TO_STATE_DT  = src.EARLIEST_RPT_TO_STATE_DT ,
            tgt.HOSPITALIZED = src.HOSPITALIZED,
            tgt.HOSPITALIZED_ADMISSION_DATE = src.HOSPITALIZED_ADMISSION_DATE,
            tgt.HOSPITALIZED_DISCHARGE_DATE = src.HOSPITALIZED_DISCHARGE_DATE,
            tgt.HOSPITALIZED_DURATION_DAYS = src.HOSPITALIZED_DURATION_DAYS,
            tgt.HOSPITAL_NAME = src.HOSPITAL_NAME,
            tgt.ILLNESS_ONSET_DATE = src.ILLNESS_ONSET_DATE,
            tgt.ILLNESS_END_DATE = src.ILLNESS_END_DATE,
            tgt.DIE_FRM_THIS_ILLNESS_IND = src.DIE_FRM_THIS_ILLNESS_IND,
            tgt.TYPE_INFECTION_BACTEREMIA = src.TYPE_INFECTION_BACTEREMIA,
            tgt.TYPE_INFECTION_PNEUMONIA = src.TYPE_INFECTION_PNEUMONIA,
            tgt.TYPE_INFECTION_MENINGITIS = src.TYPE_INFECTION_MENINGITIS,
            tgt.TYPE_INFECTION_EMPYEMA = src.TYPE_INFECTION_EMPYEMA,
            tgt.TYPE_INFECTION_CELLULITIS = src.TYPE_INFECTION_CELLULITIS,
            tgt.TYPE_INFECTION_PERITONITIS = src.TYPE_INFECTION_PERITONITIS,
            tgt.TYPE_INFECTION_PERICARDITIS = src.TYPE_INFECTION_PERICARDITIS,
            tgt.TYPE_INFECTION_PUERPERAL_SEP = src.TYPE_INFECTION_PUERPERAL_SEP,
            tgt.TYPE_INFECTION_SEP_ARTHRITIS = src.TYPE_INFECTION_SEP_ARTHRITIS,
            tgt.TYPE_INFECTION_OTHERS_CONCAT = src.TYPE_INFECTION_OTHERS_CONCAT,
            tgt.TYPE_INFECTION_OTHER_SPECIFY = src.TYPE_INFECTION_OTHER_SPECIFY,
            tgt.BACTERIAL_SPECIES_ISOLATED = src.BACTERIAL_SPECIES_ISOLATED,
            tgt.BACTERIAL_SPECIES_ISOLATED_OTH = src.BACTERIAL_SPECIES_ISOLATED_OTH,
            tgt.FIRST_POSITIVE_CULTURE_DT = src.FIRST_POSITIVE_CULTURE_DT,
            tgt.STERILE_SITE_BLOOD = src.STERILE_SITE_BLOOD,
            tgt.STERILE_SITE_CEREBRAL_SF = src.STERILE_SITE_CEREBRAL_SF,
            tgt.STERILE_SITE_PLEURAL_FLUID = src.STERILE_SITE_PLEURAL_FLUID,
            tgt.STERILE_SITE_PERITONEAL_FLUID = src.STERILE_SITE_PERITONEAL_FLUID,
            tgt.STERILE_SITE_PERICARDIAL_FLUID = src.STERILE_SITE_PERICARDIAL_FLUID,
            tgt.STERILE_SITE_JOINT_FLUID = src.STERILE_SITE_JOINT_FLUID,
            tgt.STERILE_SITE_OTHERS_CONCAT = src.STERILE_SITE_OTHERS_CONCAT,
            tgt.STERILE_SITE_OTHER = src.STERILE_SITE_OTHER,
            tgt.INTERNAL_BODY_SITE = src.INTERNAL_BODY_SITE,
            tgt.NON_STERILE_SITE_1 = src.NON_STERILE_SITE_1,
            tgt.NON_STERILE_SITE_2 = src.NON_STERILE_SITE_2,
            tgt.NON_STERILE_SITE_3 = src.NON_STERILE_SITE_3,
            tgt.NON_STERILE_SITE_OTHER = src.NON_STERILE_SITE_OTHER,
            tgt.UNDERLYING_CONDITION_IND = src.UNDERLYING_CONDITION_IND,
            tgt.UNDERLYING_CONDITION_1 = src.UNDERLYING_CONDITION_1,
            tgt.UNDERLYING_CONDITION_2 = src.UNDERLYING_CONDITION_2,
            tgt.UNDERLYING_CONDITION_3 = src.UNDERLYING_CONDITION_3,
            tgt.UNDERLYING_CONDITION_4 = src.UNDERLYING_CONDITION_4,
            tgt.UNDERLYING_CONDITION_5 = src.UNDERLYING_CONDITION_5,
            tgt.UNDERLYING_CONDITION_6 = src.UNDERLYING_CONDITION_6,
            tgt.UNDERLYING_CONDITION_7 = src.UNDERLYING_CONDITION_7,
            tgt.UNDERLYING_CONDITION_8 = src.UNDERLYING_CONDITION_8,
            tgt.OTHER_MALIGNANCY = src.OTHER_MALIGNANCY,
            tgt.ORGAN_TRANSPLANT = src.ORGAN_TRANSPLANT,
            tgt.OTHER_PRIOR_ILLNESS_1 = src.OTHER_PRIOR_ILLNESS_1,
            tgt.OTHER_PRIOR_ILLNESS_2 = src.OTHER_PRIOR_ILLNESS_2,
            tgt.OTHER_PRIOR_ILLNESS_3 = src.OTHER_PRIOR_ILLNESS_3,
            tgt.CASE_STATUS = src.CASE_STATUS,
            tgt.MMWR_WEEK = src.MMWR_WEEK,
            tgt.MMWR_YEAR = src.MMWR_YEAR,
            tgt.SAME_PATHOGEN_RECURRENT = src.SAME_PATHOGEN_RECURRENT,
            tgt.CASE_REPORT_STATUS = src.CASE_REPORT_STATUS,
            tgt.OXACILLIN_INTERPRETATION = src.OXACILLIN_INTERPRETATION,
            tgt.OXACILLIN_ZONE_SIZE = src.OXACILLIN_ZONE_SIZE,
            tgt.ANTIMICROBIAL_AGENT_TESTED_1 = src.ANTIMICROBIAL_AGENT_TESTED_1,
            tgt.SUSCEPTABILITY_METHOD_1 = src.SUSCEPTABILITY_METHOD_1,
            tgt.S_I_R_U_RESULT_1 = src.S_I_R_U_RESULT_1,
            tgt.MIC_SIGN_1 = src.MIC_SIGN_1,
            tgt.MIC_VALUE_1 = src.MIC_VALUE_1,
            tgt.ANTIMICROBIAL_AGENT_TESTED_2 = src.ANTIMICROBIAL_AGENT_TESTED_2,
            tgt.SUSCEPTABILITY_METHOD_2 = src.SUSCEPTABILITY_METHOD_2,
            tgt.S_I_R_U_RESULT_2 = src.S_I_R_U_RESULT_2,
            tgt.MIC_SIGN_2 = src.MIC_SIGN_2,
            tgt.MIC_VALUE_2 = src.MIC_VALUE_2,
            tgt.ANTIMICROBIAL_AGENT_TESTED_3 = src.ANTIMICROBIAL_AGENT_TESTED_3,
            tgt.SUSCEPTABILITY_METHOD_3 = src.SUSCEPTABILITY_METHOD_3,
            tgt.S_I_R_U_RESULT_3 = src.S_I_R_U_RESULT_3,
            tgt.MIC_SIGN_3 = src.MIC_SIGN_3,
            tgt.MIC_VALUE_3 = src.MIC_VALUE_3,
            tgt.ANTIMICROBIAL_AGENT_TESTED_4 = src.ANTIMICROBIAL_AGENT_TESTED_4,
            tgt.SUSCEPTABILITY_METHOD_4 = src.SUSCEPTABILITY_METHOD_4,
            tgt.S_I_R_U_RESULT_4 = src.S_I_R_U_RESULT_4,
            tgt.MIC_SIGN_4 = src.MIC_SIGN_4,
            tgt.MIC_VALUE_4 = src.MIC_VALUE_4,
            tgt.ANTIMICROBIAL_AGENT_TESTED_5 = src.ANTIMICROBIAL_AGENT_TESTED_5,
            tgt.SUSCEPTABILITY_METHOD_5 = src.SUSCEPTABILITY_METHOD_5,
            tgt.S_I_R_U_RESULT_5 = src.S_I_R_U_RESULT_5,
            tgt.MIC_SIGN_5 = src.MIC_SIGN_5,
            tgt.MIC_VALUE_5 = src.MIC_VALUE_5,
            tgt.ANTIMICROBIAL_AGENT_TESTED_6 = src.ANTIMICROBIAL_AGENT_TESTED_6,
            tgt.SUSCEPTABILITY_METHOD_6 = src.SUSCEPTABILITY_METHOD_6,
            tgt.S_I_R_U_RESULT_6 = src.S_I_R_U_RESULT_6,
            tgt.MIC_SIGN_6 = src.MIC_SIGN_6,
            tgt.MIC_VALUE_6 = src.MIC_VALUE_6,
            tgt.ANTIMICROBIAL_AGENT_TESTED_7 = src.ANTIMICROBIAL_AGENT_TESTED_7,
            tgt.SUSCEPTABILITY_METHOD_7 = src.SUSCEPTABILITY_METHOD_7,
            tgt.S_I_R_U_RESULT_7 = src.S_I_R_U_RESULT_7,
            tgt.MIC_SIGN_7 = src.MIC_SIGN_7,
            tgt.MIC_VALUE_7 = src.MIC_VALUE_7,
            tgt.ANTIMICROBIAL_AGENT_TESTED_8 = src.ANTIMICROBIAL_AGENT_TESTED_8,
            tgt.SUSCEPTABILITY_METHOD_8 = src.SUSCEPTABILITY_METHOD_8,
            tgt.S_I_R_U_RESULT_8 = src.S_I_R_U_RESULT_8,
            tgt.MIC_SIGN_8 = src.MIC_SIGN_8,
            tgt.MIC_VALUE_8 = src.MIC_VALUE_8,
            tgt.ANTIMIC_GT_8_AGENT_AND_RESULT = src.ANTIMIC_GT_8_AGENT_AND_RESULT,
            tgt.PERSISTENT_DISEASE_IND = src.PERSISTENT_DISEASE_IND,
            tgt.ADD_CULTURE_1_DATE = src.ADD_CULTURE_1_DATE,
            tgt.ADD_CULTURE_1_SITE_1 = src.ADD_CULTURE_1_SITE_1,
            tgt.ADD_CULTURE_1_SITE_2 = src.ADD_CULTURE_1_SITE_2,
            tgt.ADD_CULTURE_1_SITE_3 = src.ADD_CULTURE_1_SITE_3,
            tgt.ADD_CULTURE_1_OTHER_SITE = src.ADD_CULTURE_1_OTHER_SITE,
            tgt.ADD_CULTURE_2_DATE = src.ADD_CULTURE_2_DATE,
            tgt.ADD_CULTURE_2_SITE_1 = src.ADD_CULTURE_2_SITE_1,
            tgt.ADD_CULTURE_2_SITE_2 = src.ADD_CULTURE_2_SITE_2,
            tgt.ADD_CULTURE_2_SITE_3 = src.ADD_CULTURE_2_SITE_3,
            tgt.ADD_CULTURE_2_OTHER_SITE = src.ADD_CULTURE_2_OTHER_SITE,
            tgt.VACCINE_POLYSACCHARIDE = src.VACCINE_POLYSACCHARIDE,
            tgt.VACCINE_CONJUGATE = src.VACCINE_CONJUGATE,
            tgt.PROGRAM_JURISDICTION_OID = src.PROGRAM_JURISDICTION_OID,
            tgt.GENERAL_COMMENTS = src.GENERAL_COMMENTS,
            tgt.PHC_ADD_TIME = src.PHC_ADD_TIME,
            tgt.PHC_LAST_CHG_TIME = src.PHC_LAST_CHG_TIME,
            tgt.EVENT_DATE = src.EVENT_DATE,
            tgt.EVENT_DATE_TYPE = src.EVENT_DATE_TYPE,
            tgt.CULTURE_SEROTYPE = src.CULTURE_SEROTYPE,
            tgt.OTHSEROTYPE	 = src.OTHSEROTYPE
        FROM #BMIRD_ANTIMICRO_6 src
                 LEFT JOIN dbo.BMIRD_STREP_PNEUMO_DATAMART tgt ON src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_name = ' Insert BMIRD_STREP_PNEUMO_DATAMART';

        INSERT INTO dbo.BMIRD_STREP_PNEUMO_DATAMART (
                                                      INVESTIGATION_KEY
                                                    ,PATIENT_LOCAL_ID
                                                    ,INVESTIGATION_LOCAL_ID
                                                    ,DISEASE
                                                    ,DISEASE_CD
                                                    ,PATIENT_FIRST_NAME
                                                    ,PATIENT_LAST_NAME
                                                    ,PATIENT_DOB
                                                    ,PATIENT_CURRENT_SEX
                                                    ,AGE_REPORTED
                                                    ,AGE_REPORTED_UNIT
                                                    ,PATIENT_STREET_ADDRESS_1
                                                    ,PATIENT_STREET_ADDRESS_2
                                                    ,PATIENT_CITY
                                                    ,PATIENT_STATE
                                                    ,PATIENT_ZIP
                                                    ,PATIENT_COUNTY
                                                    ,PATIENT_ETHNICITY
                                                    ,RACE_CALCULATED
                                                    ,RACE_CALC_DETAILS
                                                    ,EARLIEST_RPT_TO_CNTY_DT
                                                    ,EARLIEST_RPT_TO_STATE_DT
                                                    ,HOSPITALIZED
                                                    ,HOSPITALIZED_ADMISSION_DATE
                                                    ,HOSPITALIZED_DISCHARGE_DATE
                                                    ,HOSPITALIZED_DURATION_DAYS
                                                    ,HOSPITAL_NAME
                                                    ,ILLNESS_ONSET_DATE
                                                    ,ILLNESS_END_DATE
                                                    ,DIE_FRM_THIS_ILLNESS_IND
                                                    ,TYPE_INFECTION_BACTEREMIA
                                                    ,TYPE_INFECTION_PNEUMONIA
                                                    ,TYPE_INFECTION_MENINGITIS
                                                    ,TYPE_INFECTION_EMPYEMA
                                                    ,TYPE_INFECTION_CELLULITIS
                                                    ,TYPE_INFECTION_PERITONITIS
                                                    ,TYPE_INFECTION_PERICARDITIS
                                                    ,TYPE_INFECTION_PUERPERAL_SEP
                                                    ,TYPE_INFECTION_SEP_ARTHRITIS
                                                    ,TYPE_INFECTION_OTHERS_CONCAT
                                                    ,TYPE_INFECTION_OTHER_SPECIFY
                                                    ,BACTERIAL_SPECIES_ISOLATED
                                                    ,BACTERIAL_SPECIES_ISOLATED_OTH
                                                    ,FIRST_POSITIVE_CULTURE_DT
                                                    ,STERILE_SITE_BLOOD
                                                    ,STERILE_SITE_CEREBRAL_SF
                                                    ,STERILE_SITE_PLEURAL_FLUID
                                                    ,STERILE_SITE_PERITONEAL_FLUID
                                                    ,STERILE_SITE_PERICARDIAL_FLUID
                                                    ,STERILE_SITE_JOINT_FLUID
                                                    ,STERILE_SITE_OTHERS_CONCAT
                                                    ,STERILE_SITE_OTHER
                                                    ,INTERNAL_BODY_SITE
                                                    ,NON_STERILE_SITE_1
                                                    ,NON_STERILE_SITE_2
                                                    ,NON_STERILE_SITE_3
                                                    ,NON_STERILE_SITE_OTHER
                                                    ,UNDERLYING_CONDITION_IND
                                                    ,UNDERLYING_CONDITION_1
                                                    ,UNDERLYING_CONDITION_2
                                                    ,UNDERLYING_CONDITION_3
                                                    ,UNDERLYING_CONDITION_4
                                                    ,UNDERLYING_CONDITION_5
                                                    ,UNDERLYING_CONDITION_6
                                                    ,UNDERLYING_CONDITION_7
                                                    ,UNDERLYING_CONDITION_8
                                                    ,OTHER_MALIGNANCY
                                                    ,ORGAN_TRANSPLANT
                                                    ,OTHER_PRIOR_ILLNESS_1
                                                    ,OTHER_PRIOR_ILLNESS_2
                                                    ,OTHER_PRIOR_ILLNESS_3
                                                    ,CASE_STATUS
                                                    ,MMWR_WEEK
                                                    ,MMWR_YEAR
                                                    ,SAME_PATHOGEN_RECURRENT
                                                    ,CASE_REPORT_STATUS
                                                    ,OXACILLIN_INTERPRETATION
                                                    ,OXACILLIN_ZONE_SIZE
                                                    ,ANTIMICROBIAL_AGENT_TESTED_1
                                                    ,SUSCEPTABILITY_METHOD_1
                                                    ,S_I_R_U_RESULT_1
                                                    ,MIC_SIGN_1
                                                    ,MIC_VALUE_1
                                                    ,ANTIMICROBIAL_AGENT_TESTED_2
                                                    ,SUSCEPTABILITY_METHOD_2
                                                    ,S_I_R_U_RESULT_2
                                                    ,MIC_SIGN_2
                                                    ,MIC_VALUE_2
                                                    ,ANTIMICROBIAL_AGENT_TESTED_3
                                                    ,SUSCEPTABILITY_METHOD_3
                                                    ,S_I_R_U_RESULT_3
                                                    ,MIC_SIGN_3
                                                    ,MIC_VALUE_3
                                                    ,ANTIMICROBIAL_AGENT_TESTED_4
                                                    ,SUSCEPTABILITY_METHOD_4
                                                    ,S_I_R_U_RESULT_4
                                                    ,MIC_SIGN_4
                                                    ,MIC_VALUE_4
                                                    ,ANTIMICROBIAL_AGENT_TESTED_5
                                                    ,SUSCEPTABILITY_METHOD_5
                                                    ,S_I_R_U_RESULT_5
                                                    ,MIC_SIGN_5
                                                    ,MIC_VALUE_5
                                                    ,ANTIMICROBIAL_AGENT_TESTED_6
                                                    ,SUSCEPTABILITY_METHOD_6
                                                    ,S_I_R_U_RESULT_6
                                                    ,MIC_SIGN_6
                                                    ,MIC_VALUE_6
                                                    ,ANTIMICROBIAL_AGENT_TESTED_7
                                                    ,SUSCEPTABILITY_METHOD_7
                                                    ,S_I_R_U_RESULT_7
                                                    ,MIC_SIGN_7
                                                    ,MIC_VALUE_7
                                                    ,ANTIMICROBIAL_AGENT_TESTED_8
                                                    ,SUSCEPTABILITY_METHOD_8
                                                    ,S_I_R_U_RESULT_8
                                                    ,MIC_SIGN_8
                                                    ,MIC_VALUE_8
                                                    ,ANTIMIC_GT_8_AGENT_AND_RESULT
                                                    ,PERSISTENT_DISEASE_IND
                                                    ,ADD_CULTURE_1_DATE
                                                    ,ADD_CULTURE_1_SITE_1
                                                    ,ADD_CULTURE_1_SITE_2
                                                    ,ADD_CULTURE_1_SITE_3
                                                    ,ADD_CULTURE_1_OTHER_SITE
                                                    ,ADD_CULTURE_2_DATE
                                                    ,ADD_CULTURE_2_SITE_1
                                                    ,ADD_CULTURE_2_SITE_2
                                                    ,ADD_CULTURE_2_SITE_3
                                                    ,ADD_CULTURE_2_OTHER_SITE
                                                    ,VACCINE_POLYSACCHARIDE
                                                    ,VACCINE_CONJUGATE
                                                    ,PROGRAM_JURISDICTION_OID
                                                    ,GENERAL_COMMENTS
                                                    ,PHC_ADD_TIME
                                                    ,PHC_LAST_CHG_TIME
                                                    ,EVENT_DATE
                                                    ,EVENT_DATE_TYPE
                                                    ,CULTURE_SEROTYPE
                                                    ,OTHSEROTYPE
        )
        SELECT src.INVESTIGATION_KEY
             ,src.PATIENT_LOCAL_ID
             ,src.INVESTIGATION_LOCAL_ID
             ,src.DISEASE
             ,src.DISEASE_CD
             ,src.PATIENT_FIRST_NAME
             ,src.PATIENT_LAST_NAME
             ,src.PATIENT_DOB
             ,src.PATIENT_CURRENT_SEX
             ,src.AGE_REPORTED
             ,src.AGE_REPORTED_UNIT
             ,src.PATIENT_STREET_ADDRESS_1
             ,src.PATIENT_STREET_ADDRESS_2
             ,src.PATIENT_CITY
             ,src.PATIENT_STATE
             ,src.PATIENT_ZIP
             ,src.PATIENT_COUNTY
             ,src.PATIENT_ETHNICITY
             ,src.RACE_CALCULATED
             ,src.RACE_CALC_DETAILS
             ,src.EARLIEST_RPT_TO_CNTY_DT
             ,src.EARLIEST_RPT_TO_STATE_DT
             ,src.HOSPITALIZED
             ,src.HOSPITALIZED_ADMISSION_DATE
             ,src.HOSPITALIZED_DISCHARGE_DATE
             ,src.HOSPITALIZED_DURATION_DAYS
             ,src.HOSPITAL_NAME
             ,src.ILLNESS_ONSET_DATE
             ,src.ILLNESS_END_DATE
             ,src.DIE_FRM_THIS_ILLNESS_IND
             ,src.TYPE_INFECTION_BACTEREMIA
             ,src.TYPE_INFECTION_PNEUMONIA
             ,src.TYPE_INFECTION_MENINGITIS
             ,src.TYPE_INFECTION_EMPYEMA
             ,src.TYPE_INFECTION_CELLULITIS
             ,src.TYPE_INFECTION_PERITONITIS
             ,src.TYPE_INFECTION_PERICARDITIS
             ,src.TYPE_INFECTION_PUERPERAL_SEP
             ,src.TYPE_INFECTION_SEP_ARTHRITIS
             ,src.TYPE_INFECTION_OTHERS_CONCAT
             ,src.TYPE_INFECTION_OTHER_SPECIFY
             ,src.BACTERIAL_SPECIES_ISOLATED
             ,src.BACTERIAL_SPECIES_ISOLATED_OTH
             ,src.FIRST_POSITIVE_CULTURE_DT
             ,src.STERILE_SITE_BLOOD
             ,src.STERILE_SITE_CEREBRAL_SF
             ,src.STERILE_SITE_PLEURAL_FLUID
             ,src.STERILE_SITE_PERITONEAL_FLUID
             ,src.STERILE_SITE_PERICARDIAL_FLUID
             ,src.STERILE_SITE_JOINT_FLUID
             ,src.STERILE_SITE_OTHERS_CONCAT
             ,src.STERILE_SITE_OTHER
             ,src.INTERNAL_BODY_SITE
             ,src.NON_STERILE_SITE_1
             ,src.NON_STERILE_SITE_2
             ,src.NON_STERILE_SITE_3
             ,src.NON_STERILE_SITE_OTHER
             ,src.UNDERLYING_CONDITION_IND
             ,src.UNDERLYING_CONDITION_1
             ,src.UNDERLYING_CONDITION_2
             ,src.UNDERLYING_CONDITION_3
             ,src.UNDERLYING_CONDITION_4
             ,src.UNDERLYING_CONDITION_5
             ,src.UNDERLYING_CONDITION_6
             ,src.UNDERLYING_CONDITION_7
             ,src.UNDERLYING_CONDITION_8
             ,src.OTHER_MALIGNANCY
             ,src.ORGAN_TRANSPLANT
             ,src.OTHER_PRIOR_ILLNESS_1
             ,src.OTHER_PRIOR_ILLNESS_2
             ,src.OTHER_PRIOR_ILLNESS_3
             ,src.CASE_STATUS
             ,src.MMWR_WEEK
             ,src.MMWR_YEAR
             ,src.SAME_PATHOGEN_RECURRENT
             ,src.CASE_REPORT_STATUS
             ,src.OXACILLIN_INTERPRETATION
             ,src.OXACILLIN_ZONE_SIZE
             ,src.ANTIMICROBIAL_AGENT_TESTED_1
             ,src.SUSCEPTABILITY_METHOD_1
             ,src.S_I_R_U_RESULT_1
             ,src.MIC_SIGN_1
             ,src.MIC_VALUE_1
             ,src.ANTIMICROBIAL_AGENT_TESTED_2
             ,src.SUSCEPTABILITY_METHOD_2
             ,src.S_I_R_U_RESULT_2
             ,src.MIC_SIGN_2
             ,src.MIC_VALUE_2
             ,src.ANTIMICROBIAL_AGENT_TESTED_3
             ,src.SUSCEPTABILITY_METHOD_3
             ,src.S_I_R_U_RESULT_3
             ,src.MIC_SIGN_3
             ,src.MIC_VALUE_3
             ,src.ANTIMICROBIAL_AGENT_TESTED_4
             ,src.SUSCEPTABILITY_METHOD_4
             ,src.S_I_R_U_RESULT_4
             ,src.MIC_SIGN_4
             ,src.MIC_VALUE_4
             ,src.ANTIMICROBIAL_AGENT_TESTED_5
             ,src.SUSCEPTABILITY_METHOD_5
             ,src.S_I_R_U_RESULT_5
             ,src.MIC_SIGN_5
             ,src.MIC_VALUE_5
             ,src.ANTIMICROBIAL_AGENT_TESTED_6
             ,src.SUSCEPTABILITY_METHOD_6
             ,src.S_I_R_U_RESULT_6
             ,src.MIC_SIGN_6
             ,src.MIC_VALUE_6
             ,src.ANTIMICROBIAL_AGENT_TESTED_7
             ,src.SUSCEPTABILITY_METHOD_7
             ,src.S_I_R_U_RESULT_7
             ,src.MIC_SIGN_7
             ,src.MIC_VALUE_7
             ,src.ANTIMICROBIAL_AGENT_TESTED_8
             ,src.SUSCEPTABILITY_METHOD_8
             ,src.S_I_R_U_RESULT_8
             ,src.MIC_SIGN_8
             ,src.MIC_VALUE_8
             ,src.ANTIMIC_GT_8_AGENT_AND_RESULT
             ,src.PERSISTENT_DISEASE_IND
             ,src.ADD_CULTURE_1_DATE
             ,src.ADD_CULTURE_1_SITE_1
             ,src.ADD_CULTURE_1_SITE_2
             ,src.ADD_CULTURE_1_SITE_3
             ,src.ADD_CULTURE_1_OTHER_SITE
             ,src.ADD_CULTURE_2_DATE
             ,src.ADD_CULTURE_2_SITE_1
             ,src.ADD_CULTURE_2_SITE_2
             ,src.ADD_CULTURE_2_SITE_3
             ,src.ADD_CULTURE_2_OTHER_SITE
             ,src.VACCINE_POLYSACCHARIDE
             ,src.VACCINE_CONJUGATE
             ,src.PROGRAM_JURISDICTION_OID
             ,src.GENERAL_COMMENTS
             ,src.PHC_ADD_TIME
             ,src.PHC_LAST_CHG_TIME
             ,src.EVENT_DATE
             ,src.EVENT_DATE_TYPE
             ,src.CULTURE_SEROTYPE
             ,src.OTHSEROTYPE
        FROM #BMIRD_ANTIMICRO_6 src
                 LEFT JOIN dbo.BMIRD_STREP_PNEUMO_DATAMART tgt
                           on src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY
        WHERE tgt.INVESTIGATION_KEY IS NULL;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [row_count])
        VALUES ( @batch_id
               , @Dataflow_Name
               , @Package_Name
               , 'COMPLETE'
               , 999
               , @Proc_Step_name
               , @RowCount_no);

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
        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();


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
            ,@Dataflow_Name
            ,@Package_Name
            ,'ERROR'
            ,@Proc_Step_no
            ,@Proc_Step_name
            , @FullErrorMessage
            ,0
            );

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