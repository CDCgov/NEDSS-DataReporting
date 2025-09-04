IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_covid_contact_datamart_postprocessing]')
                                      AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
    BEGIN
        DROP PROCEDURE [dbo].[sp_covid_contact_datamart_postprocessing]
    END
GO

CREATE PROCEDURE [dbo].[sp_covid_contact_datamart_postprocessing]
    @phcid_list nvarchar(max), -- Removed default NULL value to make it required
    @debug bit = 'false'
AS
BEGIN
    BEGIN TRY
        /* Logging */
        DECLARE @rowcount bigint;
        DECLARE @proc_step_no float = 0;
        DECLARE @proc_step_name varchar(200) = '';
        DECLARE @batch_id bigint;
        DECLARE @dataflow_name varchar(200) = 'COVID DATAMART Post-Processing Event';
        DECLARE @package_name varchar(200) = 'covid_contact_datamart_postprocessing';
        DECLARE @conditionCd varchar(200);

        SET @conditionCd = '11065'; -- COVID-19 condition code
        SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);

        -- Initialize logging
        INSERT INTO [dbo].[job_flow_log] (
            batch_id, [Dataflow_Name], [package_Name], [Status_Type],
            [step_number], [step_name], [msg_description1], [row_count]
        )
        VALUES (
                   @batch_id, @dataflow_name, @package_name, 'START',
                   0, 'SP_Start', LEFT(ISNULL(@phcid_list, 'NULL'),500), 0
               );

        SET @proc_step_name = 'Create COVID_CONTACT_DATAMART Temp table';
        SET @proc_step_no = 1;

        /* Create temporary table for COVID contact data */
        IF OBJECT_ID('tempdb..#COVID_CONTACT_DATAMART', 'U') IS NOT NULL
            DROP TABLE #COVID_CONTACT_DATAMART;

        SELECT DISTINCT
            -- SRC: patient (using D_PATIENT dimension table directly)
            pat.PATIENT_FIRST_NAME                                  AS 'SRC_PATIENT_FIRST_NAME',
            pat.PATIENT_MIDDLE_NAME                                 AS 'SRC_PATIENT_MIDDLE_NAME',
            pat.PATIENT_LAST_NAME                                   AS 'SRC_PATIENT_LAST_NAME',
            pat.PATIENT_DOB                                         AS 'SRC_PATIENT_DOB',
            pat.PATIENT_AGE_REPORTED                                AS 'SRC_PATIENT_AGE_REPORTED',
            pat.PATIENT_AGE_REPORTED_UNIT                           AS 'SRC_PATIENT_AGE_RPTD_UNIT',
            cvg1.CODE_VAL                                           AS 'SRC_PATIENT_CURRENT_SEX',
            cvg2.CODE_VAL                                           AS 'SRC_PATIENT_DECEASED_IND',
            pat.PATIENT_DECEASED_DATE                               AS 'SRC_PATIENT_DECEASED_DT',
            pat.PATIENT_STREET_ADDRESS_1                            AS 'SRC_PATIENT_STREET_ADDR_1',
            pat.PATIENT_STREET_ADDRESS_2                            AS 'SRC_PATIENT_STREET_ADDR_2',
            pat.PATIENT_CITY                                        AS 'SRC_PATIENT_CITY',
            pat.PATIENT_STATE_CODE                                  AS 'SRC_PATIENT_STATE',
            pat.PATIENT_ZIP                                         AS 'SRC_PATIENT_ZIP',
            pat.PATIENT_COUNTY_CODE                                 AS 'SRC_PATIENT_COUNTY',
            nrt_pat.country_code                                    AS 'SRC_PATIENT_COUNTRY',
            j_inv.code_desc_txt                                     AS 'SRC_INV_JURISDICTION_NM',
            inv.activity_from_time                                  AS 'SRC_INV_START_DT',
            inv.investigation_status_cd                             AS 'SRC_INV_STATUS',
            inv.inv_state_case_id                                   AS 'SRC_INV_STATE_CASE_ID',
            inv.legacy_case_id                                      AS 'SRC_INV_LEGACY_CASE_ID',
            inv_asw1.answer_txt                                     AS 'SRC_INV_CDC_ASSIGNED_ID',
            inv_asw2.answer_txt                                     AS 'SRC_INV_RPTNG_CNTY',
            inv.hospitalized_ind_cd                                 AS 'SRC_INV_HSPTLIZD_IND',
            inv.outcome_cd                                          AS 'SRC_INV_DIE_FRM_ILLNESS_IND',
            inv.deceased_time                                       AS 'SRC_INV_DEATH_DT',
            inv.case_class_cd                                       AS 'SRC_INV_CASE_STATUS',
            inv_asw3.answer_txt                                     AS 'SRC_INV_SYMPTOMATIC',
            inv.effective_from_time                                 AS 'SRC_INV_ILLNESS_ONSET_DT',
            inv.effective_to_time                                   AS 'SRC_INV_ILLNESS_END_DT',
            inv_asw4.answer_txt                                     AS 'SRC_INV_SYMPTOM_STATUS',
            cvg4.code                                               AS 'SRC_CTT_INV_PRIORITY',
            inv.infectious_from_date                                AS 'SRC_CTT_INV_INFECTIOUS_FRM_DT',
            inv.infectious_to_date                                  AS 'SRC_CTT_INV_INFECTIOUS_TO_DT',
            inv.contact_inv_status                                  AS 'SRC_CTT_INV_STATUS',
            REPLACE(inv.contact_inv_txt, CHAR(13) + CHAR(10), ' ')  AS 'SRC_CTT_INV_COMMENTS',

            -- CR: Contact Record (using nrt_contact instead of ct_contact)
            con.CTT_JURISDICTION_NM                                 AS 'CR_JURISDICTION_NM',
            con.CTT_STATUS                                          AS 'CR_STATUS',
            cvg5.code                                               AS 'CR_PRIORITY',

            -- Investigator information (using D_PROVIDER dimension table)
            pat_inv.PROVIDER_FIRST_NAME                             AS 'CR_INV_FIRST_NAME',
            pat_inv.PROVIDER_LAST_NAME                              AS 'CR_INV_LAST_NAME',
            con.CTT_INV_ASSIGNED_DT                                 AS 'CR_INV_ASSIGNED_DT',
            cvg6.code                                               AS 'CR_DISPOSITION',
            con.CTT_DISPO_DT                                        AS 'CR_DISPO_DT',
            con.CTT_NAMED_ON_DT                                     AS 'CR_NAMED_ON_DT',
            cvg7.code                                               AS 'CR_RELATIONSHIP',
            cvg8.code                                               AS 'CR_HEALTH_STATUS',

            -- These match CT_CONTACT_ANSWER with different question identifiers
            con_ans1.answer_val                                     AS 'CR_EXPOSURE_TYPE',
            con_ans2.answer_val                                     AS 'CR_EXPOSURE_SITE_TY',
            con_ans3.answer_val                                     AS 'CR_FIRST_EXPOSURE_DT',
            con_ans4.answer_val                                     AS 'CR_LAST_EXPOSURE_DT',
            cvg9.code                                               AS 'CR_SYMP_IND',
            con.CTT_SYMP_ONSET_DT                                   AS 'CR_SYMP_ONSET_DT',
            cvg10.code                                              AS 'CR_RISK_IND',
            REPLACE(con.CTT_RISK_NOTES, CHAR(13) + CHAR(10), ' ')   AS 'CR_RISK_NOTES',
            cvg11.code                                              AS 'CR_EVAL_COMPLETED',
            con.CTT_EVAL_DT                                         AS 'CR_EVAL_DT',
            REPLACE(con.CTT_EVAL_NOTES, CHAR(13) + CHAR(10), ' ')   AS 'CR_EVAL_NOTES',

            -- CTT: if there's a contact investigation, get demographics from investigation, if not, get demographics from contact record
            -- Using dimension tables with verified column names
            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_FIRST_NAME
                ELSE ctt_pat_con.PATIENT_FIRST_NAME
                END AS 'CTT_PATIENT_FIRST_NAME',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_MIDDLE_NAME
                ELSE ctt_pat_con.PATIENT_MIDDLE_NAME
                END AS 'CTT_PATIENT_MIDDLE_NAME',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_LAST_NAME
                ELSE ctt_pat_con.PATIENT_LAST_NAME
                END AS 'CTT_PATIENT_LAST_NAME',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_DOB
                ELSE ctt_pat_con.PATIENT_DOB
                END AS 'CTT_PATIENT_DOB',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_AGE_REPORTED
                ELSE ctt_pat_con.PATIENT_AGE_REPORTED
                END AS 'CTT_PATIENT_AGE_REPORTED',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_AGE_REPORTED_UNIT
                ELSE ctt_pat_con.PATIENT_AGE_REPORTED_UNIT
                END AS 'CTT_PATIENT_AGE_RPTD_UNIT',

            cvg12.CODE_VAL AS 'CTT_PATIENT_CURRENT_SEX',
            cvg13.CODE_VAL AS 'CTT_PATIENT_DECEASED_IND',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_DECEASED_DATE
                ELSE ctt_pat_con.PATIENT_DECEASED_DATE
                END AS 'CTT_PATIENT_DECEASED_DT',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_STREET_ADDRESS_1
                ELSE ctt_pat_con.PATIENT_STREET_ADDRESS_1
                END AS 'CTT_PATIENT_STREET_ADDR_1',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_STREET_ADDRESS_2
                ELSE ctt_pat_con.PATIENT_STREET_ADDRESS_2
                END AS 'CTT_PATIENT_STREET_ADDR_2',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_CITY
                ELSE ctt_pat_con.PATIENT_CITY
                END AS 'CTT_PATIENT_CITY',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_STATE_CODE
                ELSE ctt_pat_con.PATIENT_STATE_CODE
                END AS 'CTT_PATIENT_STATE',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_ZIP
                ELSE ctt_pat_con.PATIENT_ZIP
                END AS 'CTT_PATIENT_ZIP',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_COUNTY_CODE
                ELSE ctt_pat_con.PATIENT_COUNTY_CODE
                END AS 'CTT_PATIENT_COUNTY',

            cvg14.CODE_VAL AS 'CTT_PATIENT_COUNTRY',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_PHONE_HOME
                ELSE ctt_pat_con.PATIENT_PHONE_HOME
                END AS 'CTT_PATIENT_TEL_HOME',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_PHONE_WORK
                ELSE ctt_pat_con.PATIENT_PHONE_WORK
                END AS 'CTT_PATIENT_PHONE_WORK',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_PHONE_EXT_WORK
                ELSE ctt_pat_con.PATIENT_PHONE_EXT_WORK
                END AS 'CTT_PATIENT_PHONE_EXT_WORK',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_PHONE_CELL
                ELSE ctt_pat_con.PATIENT_PHONE_CELL
                END AS 'CTT_PATIENT_TEL_CELL',

            CASE
                WHEN con.CONTACT_ENTITY_PHC_UID is not NULL THEN ctt_pat_inv.PATIENT_EMAIL
                ELSE ctt_pat_con.PATIENT_EMAIL
                END AS 'CTT_PATIENT_EMAIL',

            j_con_inv.code_desc_txt AS 'CTT_INV_JURISDICTION_NM',
            con_inv.activity_from_time AS 'CTT_INV_START_DT',
            con_inv.investigation_status_cd AS 'CTT_INV_STATUS',
            con_inv.inv_state_case_id AS 'CTT_INV_STATE_CASE_ID',
            con_inv.legacy_case_id AS 'CTT_INV_LEGACY_CASE_ID',
            con_inv_asw1.answer_txt AS 'CTT_INV_CDC_ASSIGNED_ID',
            con_inv_asw2.answer_txt AS 'CTT_INV_RPTNG_CNTY',
            con_inv.hospitalized_ind_cd AS 'CTT_INV_HSPTLIZD_IND',
            con_inv.outcome_cd AS 'CTT_INV_DIE_FRM_ILLNESS_IND',
            con_inv.deceased_time AS 'CTT_INV_DEATH_DT',
            con_inv.case_class_cd AS 'CTT_INV_CASE_STATUS',
            con_inv_asw3.answer_txt AS 'CTT_INV_SYMPTOMATIC',
            con_inv.effective_from_time AS 'CTT_INV_ILLNESS_ONSET_DT',
            con_inv.effective_to_time AS 'CTT_INV_ILLNESS_END_DT',
            con_inv_asw4.answer_txt AS 'CTT_INV_SYMPTOM_STATUS'
        INTO #COVID_CONTACT_DATAMART
        FROM dbo.nrt_contact con WITH (NOLOCK)
                 INNER JOIN dbo.nrt_investigation inv WITH (NOLOCK)
                            ON con.SUBJECT_ENTITY_PHC_UID = inv.public_health_case_uid
                                AND con.RECORD_STATUS_CD <> 'LOG_DEL'

            -- SRC: Index patient (use D_PATIENT dimension table directly)
                 LEFT OUTER JOIN dbo.D_PATIENT pat WITH (NOLOCK)
                                 ON pat.PATIENT_UID = inv.patient_id

                 LEFT OUTER JOIN dbo.nrt_patient nrt_pat WITH (NOLOCK)
                                 ON nrt_pat.patient_uid = inv.patient_id

                 LEFT JOIN dbo.v_code_value_general cvg1 WITH (NOLOCK)
                           ON cvg1.CODE_DESC = pat.PATIENT_CURRENT_SEX AND cvg1.cd='DEM113'           --Person.PERSON_CURR_GENDER

                 LEFT JOIN dbo.v_code_value_general cvg2 WITH (NOLOCK)
                           ON pat.PATIENT_DECEASED_INDICATOR = cvg2.CODE_DESC AND cvg2.cd='DEM127'    --Person.PATIENT_DECEASED_IND

            -- These replace CT_CONTACT_ANSWER joins in original with corresponding question identifiers
                 LEFT OUTER JOIN dbo.nrt_contact_answer con_ans1 WITH (NOLOCK)
                                 ON con_ans1.contact_uid = con.CONTACT_UID
                                     AND con_ans1.rdb_column_nm = 'CTT_EXPOSURE_TYPE' -- Contact Exposure Type with Investigation Subject

                 LEFT OUTER JOIN dbo.nrt_contact_answer con_ans2 WITH (NOLOCK)
                                 ON con_ans2.contact_uid = con.CONTACT_UID
                                     AND con_ans2.rdb_column_nm = 'CTT_EXPOSURE_SITE_TYPE' -- Contact Exposure Site Type

                 LEFT OUTER JOIN dbo.nrt_contact_answer con_ans3 WITH (NOLOCK)
                                 ON con_ans3.contact_uid = con.CONTACT_UID
                                     AND con_ans3.rdb_column_nm = 'CTT_FIRST_EXPOSURE_DT' -- First Exposure Date with Contact

                 LEFT OUTER JOIN dbo.nrt_contact_answer con_ans4 WITH (NOLOCK)
                                 ON con_ans4.contact_uid = con.CONTACT_UID
                                     AND con_ans4.rdb_column_nm = 'CTT_LAST_EXPOSURE_DT' -- Last Exposure Date with Contact

            -- These replace NBS_CASE_ANSWER joins with investigation_observation and include batch_id matching
                 LEFT OUTER JOIN dbo.nrt_page_case_answer inv_asw1 WITH (NOLOCK)
                                 ON inv_asw1.act_uid = inv.public_health_case_uid
                                     AND inv_asw1.question_identifier = 'NBS547' -- CDC-Assigned Case ID
                                     AND ISNULL(inv.batch_id,1) = ISNULL(inv_asw1.batch_id,1)

                 LEFT OUTER JOIN dbo.nrt_page_case_answer inv_asw2 WITH (NOLOCK)
                                 ON inv_asw2.act_uid = inv.public_health_case_uid
                                     AND inv_asw2.question_identifier = 'NOT113' -- Reporting County
                                     AND ISNULL(inv.batch_id,1) = ISNULL(inv_asw2.batch_id, 1)

                 LEFT OUTER JOIN dbo.nrt_page_case_answer inv_asw3 WITH (NOLOCK)
                                 ON inv_asw3.act_uid = inv.public_health_case_uid
                                     AND inv_asw3.question_identifier = 'INV576' -- Symptomatic
                                     AND ISNULL(inv.batch_id,1) = ISNULL(inv_asw3.batch_id, 1)

                 LEFT OUTER JOIN dbo.nrt_page_case_answer inv_asw4 WITH (NOLOCK)
                                 ON inv_asw4.act_uid = inv.public_health_case_uid
                                     AND inv_asw4.question_identifier = 'NBS555' -- Symptomatic status
                                     AND ISNULL(inv.batch_id,1) = ISNULL(inv_asw4.batch_id,1)

            -- These replace JURISDICTION_CODE table joins
                 LEFT OUTER JOIN dbo.nrt_srte_Jurisdiction_code j_inv WITH (NOLOCK)
                                 ON inv.jurisdiction_cd = j_inv.CODE

            -- Investigator information (use D_PROVIDER dimension table directly)
                 LEFT OUTER JOIN dbo.D_PROVIDER pat_inv WITH (NOLOCK)
                                 ON pat_inv.PROVIDER_UID = inv.investigator_id

            -- Contact investigation (maps to original's contactInvestigation join)
                 LEFT OUTER JOIN dbo.nrt_investigation con_inv WITH (NOLOCK)
                                 ON con.CONTACT_ENTITY_PHC_UID = con_inv.public_health_case_uid

            -- Contact investigation jurisdiction
                 LEFT OUTER JOIN dbo.nrt_srte_Jurisdiction_code j_con_inv WITH (NOLOCK)
                                 ON con_inv.jurisdiction_cd = j_con_inv.CODE

            -- Contact investigation observations with batch_id matching
                 LEFT OUTER JOIN dbo.nrt_page_case_answer con_inv_asw1 WITH (NOLOCK)
                                 ON con_inv_asw1.act_uid = con_inv.public_health_case_uid
                                     AND con_inv_asw1.question_identifier = 'NBS547' -- CDC-Assigned Case ID
                                     AND ISNULL(con_inv.batch_id,1) = ISNULL(con_inv_asw1.batch_id,1)

                 LEFT OUTER JOIN dbo.nrt_page_case_answer con_inv_asw2 WITH (NOLOCK)
                                 ON con_inv_asw2.act_uid = con_inv.public_health_case_uid
                                     AND con_inv_asw2.question_identifier = 'NOT113' -- Reporting County
                                     AND ISNULL(con_inv.batch_id,1) = ISNULL(con_inv_asw2.batch_id,1)

                 LEFT OUTER JOIN dbo.nrt_page_case_answer con_inv_asw3 WITH (NOLOCK)
                                 ON con_inv_asw3.act_uid = con_inv.public_health_case_uid
                                     AND con_inv_asw3.question_identifier = 'INV576' -- Symptomatic
                                     AND ISNULL(con_inv.batch_id,1) = ISNULL(con_inv_asw3.batch_id,1)

                 LEFT OUTER JOIN dbo.nrt_page_case_answer con_inv_asw4 WITH (NOLOCK)
                                 ON con_inv_asw4.act_uid = con_inv.public_health_case_uid
                                     AND con_inv_asw4.question_identifier = 'NBS555' -- Symptomatic status
                                     AND ISNULL(con_inv.batch_id,1) = ISNULL(con_inv_asw4.batch_id,1)

            -- CTT records from investigation (use D_PATIENT dimension table directly)
                 LEFT OUTER JOIN dbo.D_PATIENT ctt_pat_inv WITH (NOLOCK)
                                 ON ctt_pat_inv.PATIENT_UID = con_inv.patient_id

            -- CTT records from contact (use D_PATIENT dimension table directly)
                 LEFT OUTER JOIN dbo.D_PATIENT ctt_pat_con WITH (NOLOCK)
                                 ON ctt_pat_con.PATIENT_UID = con.CONTACT_ENTITY_UID

                 LEFT JOIN dbo.nrt_srte_Code_value_general cvg4 WITH (NOLOCK)
                           ON cvg4.code_short_desc_txt = inv.contact_inv_priority AND cvg4.code_set_nm = 'NBS_PRIORITY'

                 LEFT JOIN dbo.nrt_srte_Code_value_general cvg5 WITH (NOLOCK)
                           ON cvg5.code_short_desc_txt = con.CTT_PRIORITY AND cvg5.code_set_nm = 'NBS_PRIORITY'

                 LEFT JOIN dbo.nrt_srte_Code_value_general cvg6 WITH (NOLOCK)
                           ON cvg6.code_short_desc_txt = con.CTT_DISPOSITION AND cvg6.code_set_nm IN ('NBS_DISPO','FIELD_FOLLOWUP_DISPOSITION_STD')

                 LEFT JOIN dbo.nrt_srte_Code_value_general cvg7 WITH (NOLOCK)
                           ON cvg7.code_short_desc_txt = con.CTT_RELATIONSHIP AND cvg7.code_set_nm = 'NBS_RELATIONSHIP'

                 LEFT JOIN dbo.nrt_srte_Code_value_general cvg8 WITH (NOLOCK)
                           ON cvg8.code_short_desc_txt = con.CTT_HEALTH_STATUS AND cvg8.code_set_nm = 'NBS_HEALTH_STATUS'

                 LEFT JOIN dbo.nrt_srte_Code_value_general cvg9 WITH (NOLOCK)
                           ON cvg9.code_short_desc_txt = con.CTT_SYMP_IND AND cvg9.code_set_nm = 'YNU'

                 LEFT JOIN dbo.nrt_srte_Code_value_general cvg10 WITH (NOLOCK)
                           ON cvg10.code_short_desc_txt = con.CTT_RISK_IND AND cvg10.code_set_nm = 'YNU'

                 LEFT JOIN dbo.nrt_srte_Code_value_general cvg11 WITH (NOLOCK)
                           ON cvg11.code_short_desc_txt = con.CTT_EVAL_COMPLETED AND cvg11.code_set_nm = 'YNU'

                 OUTER APPLY (
            SELECT
                IIF (con.CONTACT_ENTITY_PHC_UID IS NOT NULL,
                     ctt_pat_inv.PATIENT_CURRENT_SEX,
                     ctt_pat_con.PATIENT_CURRENT_SEX) AS PATIENT_CURRENT_SEX,
                IIF (con.CONTACT_ENTITY_PHC_UID IS NOT NULL,
                     ctt_pat_inv.PATIENT_DECEASED_INDICATOR,
                     ctt_pat_con.PATIENT_DECEASED_INDICATOR) AS PATIENT_DECEASED_INDICATOR,
                IIF (con.CONTACT_ENTITY_PHC_UID IS NOT NULL,
                     ctt_pat_inv.PATIENT_COUNTRY,
                     ctt_pat_con.PATIENT_COUNTRY) AS PATIENT_COUNTRY

        ) AS pd

                 LEFT JOIN dbo.v_code_value_general cvg12 WITH (NOLOCK)
                           ON cvg12.CODE_DESC = pd.PATIENT_CURRENT_SEX AND cvg12.cd='DEM113'           --Person.PERSON_CURR_GENDER

                 LEFT JOIN dbo.v_code_value_general cvg13 WITH (NOLOCK)
                           ON cvg13.CODE_DESC = pd.PATIENT_DECEASED_INDICATOR AND cvg13.cd='DEM127'    --Person.PATIENT_DECEASED_IND

                 LEFT JOIN dbo.v_code_value_general cvg14 WITH (NOLOCK)
                           ON cvg14.CODE_DESC = pd.PATIENT_COUNTRY AND cvg14.cd='DEM126'         --Location.PSL_CNTRY

        WHERE inv.cd = @conditionCd
          AND inv.public_health_case_uid IN (  -- Removed NULL check for @phcid_list
            SELECT TRY_CAST(value AS BIGINT)
            FROM STRING_SPLIT(@phcid_list, ',')
        );

        /* Logging */
        SET @rowcount = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (
            batch_id, [Dataflow_Name], [package_Name], [Status_Type],
            [step_number], [step_name], [row_count], [msg_description1]
        )
        VALUES (
                   @batch_id, @dataflow_name, @package_name, 'PROCESSING',
                   @proc_step_no, @proc_step_name, @rowcount, LEFT(ISNULL(@phcid_list, 'NULL'),500)
               );

        /* Debug output if requested */
        IF @debug = 'true' SELECT * FROM #COVID_CONTACT_DATAMART;

        SET @proc_step_name = 'Update COVID_CONTACT_DATAMART';
        SET @proc_step_no = 2;

        /* Start transaction for the delete and insert operations */
        BEGIN TRANSACTION;


        /* Insert updated records */
        INSERT INTO dbo.COVID_CONTACT_DATAMART (SRC_PATIENT_FIRST_NAME, SRC_PATIENT_MIDDLE_NAME, SRC_PATIENT_LAST_NAME, SRC_PATIENT_DOB, SRC_PATIENT_AGE_REPORTED, SRC_PATIENT_AGE_RPTD_UNIT, SRC_PATIENT_CURRENT_SEX, SRC_PATIENT_DECEASED_IND, SRC_PATIENT_DECEASED_DT, SRC_PATIENT_STREET_ADDR_1, SRC_PATIENT_STREET_ADDR_2, SRC_PATIENT_CITY, SRC_PATIENT_STATE, SRC_PATIENT_ZIP, SRC_PATIENT_COUNTY, SRC_PATIENT_COUNTRY, SRC_INV_JURISDICTION_NM, SRC_INV_START_DT, SRC_INV_STATUS, SRC_INV_STATE_CASE_ID, SRC_INV_LEGACY_CASE_ID, SRC_INV_CDC_ASSIGNED_ID, SRC_INV_RPTNG_CNTY, SRC_INV_HSPTLIZD_IND, SRC_INV_DIE_FRM_ILLNESS_IND, SRC_INV_DEATH_DT, SRC_INV_CASE_STATUS, SRC_INV_SYMPTOMATIC, SRC_INV_ILLNESS_ONSET_DT, SRC_INV_ILLNESS_END_DT, SRC_INV_SYMPTOM_STATUS, SRC_CTT_INV_PRIORITY, SRC_CTT_INV_INFECTIOUS_FRM_DT, SRC_CTT_INV_INFECTIOUS_TO_DT, SRC_CTT_INV_STATUS, SRC_CTT_INV_COMMENTS, CR_JURISDICTION_NM, CR_STATUS, CR_PRIORITY, CR_INV_FIRST_NAME, CR_INV_LAST_NAME, CR_INV_ASSIGNED_DT, CR_DISPOSITION, CR_DISPO_DT, CR_NAMED_ON_DT, CR_RELATIONSHIP, CR_HEALTH_STATUS, CR_EXPOSURE_TYPE, CR_EXPOSURE_SITE_TY, CR_FIRST_EXPOSURE_DT, CR_LAST_EXPOSURE_DT, CR_SYMP_IND, CR_SYMP_ONSET_DT, CR_RISK_IND, CR_RISK_NOTES, CR_EVAL_COMPLETED, CR_EVAL_DT, CR_EVAL_NOTES, CTT_PATIENT_FIRST_NAME, CTT_PATIENT_MIDDLE_NAME, CTT_PATIENT_LAST_NAME, CTT_PATIENT_DOB, CTT_PATIENT_AGE_REPORTED, CTT_PATIENT_AGE_RPTD_UNIT, CTT_PATIENT_CURRENT_SEX, CTT_PATIENT_DECEASED_IND, CTT_PATIENT_DECEASED_DT, CTT_PATIENT_STREET_ADDR_1, CTT_PATIENT_STREET_ADDR_2, CTT_PATIENT_CITY, CTT_PATIENT_STATE, CTT_PATIENT_ZIP, CTT_PATIENT_COUNTY, CTT_PATIENT_COUNTRY, CTT_PATIENT_TEL_HOME, CTT_PATIENT_PHONE_WORK, CTT_PATIENT_PHONE_EXT_WORK, CTT_PATIENT_TEL_CELL, CTT_PATIENT_EMAIL, CTT_INV_JURISDICTION_NM, CTT_INV_START_DT, CTT_INV_STATUS, CTT_INV_STATE_CASE_ID, CTT_INV_LEGACY_CASE_ID, CTT_INV_CDC_ASSIGNED_ID, CTT_INV_RPTNG_CNTY, CTT_INV_HSPTLIZD_IND, CTT_INV_DIE_FRM_ILLNESS_IND, CTT_INV_DEATH_DT, CTT_INV_CASE_STATUS, CTT_INV_SYMPTOMATIC, CTT_INV_ILLNESS_ONSET_DT, CTT_INV_ILLNESS_END_DT, CTT_INV_SYMPTOM_STATUS)
        SELECT SRC_PATIENT_FIRST_NAME, SRC_PATIENT_MIDDLE_NAME, SRC_PATIENT_LAST_NAME, SRC_PATIENT_DOB, SRC_PATIENT_AGE_REPORTED, SRC_PATIENT_AGE_RPTD_UNIT, SRC_PATIENT_CURRENT_SEX, SRC_PATIENT_DECEASED_IND, SRC_PATIENT_DECEASED_DT, SRC_PATIENT_STREET_ADDR_1, SRC_PATIENT_STREET_ADDR_2, SRC_PATIENT_CITY, SRC_PATIENT_STATE, SRC_PATIENT_ZIP, SRC_PATIENT_COUNTY, SRC_PATIENT_COUNTRY, SRC_INV_JURISDICTION_NM, SRC_INV_START_DT, SRC_INV_STATUS, SRC_INV_STATE_CASE_ID, SRC_INV_LEGACY_CASE_ID, SRC_INV_CDC_ASSIGNED_ID, SRC_INV_RPTNG_CNTY, SRC_INV_HSPTLIZD_IND, SRC_INV_DIE_FRM_ILLNESS_IND, SRC_INV_DEATH_DT, SRC_INV_CASE_STATUS, SRC_INV_SYMPTOMATIC, SRC_INV_ILLNESS_ONSET_DT, SRC_INV_ILLNESS_END_DT, SRC_INV_SYMPTOM_STATUS, SRC_CTT_INV_PRIORITY, SRC_CTT_INV_INFECTIOUS_FRM_DT, SRC_CTT_INV_INFECTIOUS_TO_DT, SRC_CTT_INV_STATUS, SRC_CTT_INV_COMMENTS, CR_JURISDICTION_NM, CR_STATUS, CR_PRIORITY, CR_INV_FIRST_NAME, CR_INV_LAST_NAME, CR_INV_ASSIGNED_DT, CR_DISPOSITION, CR_DISPO_DT, CR_NAMED_ON_DT, CR_RELATIONSHIP, CR_HEALTH_STATUS, CR_EXPOSURE_TYPE, CR_EXPOSURE_SITE_TY, CR_FIRST_EXPOSURE_DT, CR_LAST_EXPOSURE_DT, CR_SYMP_IND, CR_SYMP_ONSET_DT, CR_RISK_IND, CR_RISK_NOTES, CR_EVAL_COMPLETED, CR_EVAL_DT, CR_EVAL_NOTES, CTT_PATIENT_FIRST_NAME, CTT_PATIENT_MIDDLE_NAME, CTT_PATIENT_LAST_NAME, CTT_PATIENT_DOB, CTT_PATIENT_AGE_REPORTED, CTT_PATIENT_AGE_RPTD_UNIT, CTT_PATIENT_CURRENT_SEX, CTT_PATIENT_DECEASED_IND, CTT_PATIENT_DECEASED_DT, CTT_PATIENT_STREET_ADDR_1, CTT_PATIENT_STREET_ADDR_2, CTT_PATIENT_CITY, CTT_PATIENT_STATE, CTT_PATIENT_ZIP, CTT_PATIENT_COUNTY, CTT_PATIENT_COUNTRY, CTT_PATIENT_TEL_HOME, CTT_PATIENT_PHONE_WORK, CTT_PATIENT_PHONE_EXT_WORK, CTT_PATIENT_TEL_CELL, CTT_PATIENT_EMAIL, CTT_INV_JURISDICTION_NM, CTT_INV_START_DT, CTT_INV_STATUS, CTT_INV_STATE_CASE_ID, CTT_INV_LEGACY_CASE_ID, CTT_INV_CDC_ASSIGNED_ID, CTT_INV_RPTNG_CNTY, CTT_INV_HSPTLIZD_IND, CTT_INV_DIE_FRM_ILLNESS_IND, CTT_INV_DEATH_DT, CTT_INV_CASE_STATUS, CTT_INV_SYMPTOMATIC, CTT_INV_ILLNESS_ONSET_DT, CTT_INV_ILLNESS_END_DT, CTT_INV_SYMPTOM_STATUS
        FROM #COVID_CONTACT_DATAMART;

        /* Logging for insert operation */
        SET @rowcount = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (
            batch_id, [Dataflow_Name], [package_Name], [Status_Type],
            [step_number], [step_name], [row_count], [msg_description1]
        )
        VALUES (
                   @batch_id, @dataflow_name, @package_name, 'PROCESSING',
                   @proc_step_no + 0.1, @proc_step_name + ' - Insert', @rowcount,
                   LEFT(ISNULL(@phcid_list, 'NULL'),500)
               );

        /* Commit the transaction */
        COMMIT TRANSACTION;

        /* Clean up temporary table */
        IF OBJECT_ID('tempdb..#COVID_CONTACT_DATAMART', 'U') IS NOT NULL
            DROP TABLE #COVID_CONTACT_DATAMART;

        /* Final logging */
        SET @proc_step_name = 'SP_COMPLETE';
        SET @proc_step_no = 999;

        INSERT INTO [dbo].[job_flow_log] (
            batch_id, [Dataflow_Name], [package_Name], [Status_Type],
            [step_number], [step_name], [row_count], [msg_description1]
        )
        VALUES (
                   @batch_id, @dataflow_name, @package_name, 'COMPLETE',
                   @proc_step_no, @proc_step_name, 0, LEFT(ISNULL(@phcid_list, 'NULL'),500)
               );

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
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @FullErrorMessage NVARCHAR(4000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        /* Logging */
        INSERT INTO [dbo].[job_flow_log] (
            batch_id, [Dataflow_Name], [package_Name], [Status_Type],
            [step_number], [step_name], [row_count], [msg_description1], [Error_Description]
        )
        VALUES (
                   @batch_id, @dataflow_name, @package_name, 'ERROR',
                   @proc_Step_no, @proc_step_name, 0, LEFT(ISNULL(@phcid_list, 'NULL'),500), @FullErrorMessage
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

    END CATCH;
END;