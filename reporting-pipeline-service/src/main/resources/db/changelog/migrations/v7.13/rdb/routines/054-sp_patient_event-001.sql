-- =============================================================================
-- Procedure:   dbo.sp_patient_event
-- Purpose:     Pre-processing/extraction procedure for patient (Person) records.
--              Given a comma-delimited list of person_uid values, this procedure:
--                1. Calculates race breakdown data via sp_patient_race_event
--                2. Filters the NBS_ODSE Person table down to the requested patients
--                3. Resolves coded/lookup values (sex, ethnicity, language, etc.)
--                   into human-readable descriptions
--                4. Builds nested JSON structures for address, phone, email,
--                   name, race, and entity ID sub-records per patient
--                5. Logs START/COMPLETE/ERROR events to job_flow_log for
--                   monitoring and troubleshooting
--
-- Parameters:  @user_id_list  - Comma-separated list of person_uid (BIGINT) values
--                                identifying which patients to process.
--
-- Returns:     Result set of patient/person records (one row per person_uid),
--              including nested JSON columns for address/phone/email/name/race/entity.
--              On failure, returns a formatted error message string instead.
--
-- Notes:       - Uses NOLOCK hints throughout for read performance on a
--                (presumably) stable/replicated reporting source; be aware
--                this can read uncommitted/dirty data.
--              - @batch_id is derived from the current timestamp
--                (format yyMMddHHmmssffff) and is used to correlate all
--                job_flow_log entries for a single execution.
--              - Use of fn_get_user_name, fn_get_value_by_cvg, fn_get_value_by_cd_ques
--                were removed as this caused a large hit to performance due to the
--                inability of the optimizer to provide accurate cardinality estimates
--                and triggering a row-by-row execution.
-- =============================================================================

-- Drop the existing version of the procedure (if present) so it can be recreated.
IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_patient_event]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_patient_event]
END
GO 

CREATE PROCEDURE dbo.sp_patient_event @user_id_list nvarchar(max), @debug_logging bit = 0
AS
BEGIN

    BEGIN TRY

        -- ---------------------------------------------------------------
        -- Generate a unique batch identifier for this execution based on
        -- the current date/time (down to fractional seconds). Used to
        -- correlate all log rows written by this run.
        -- ---------------------------------------------------------------
        DECLARE @batch_id BIGINT;
        DECLARE @job_flow_step_name VARCHAR(200) = LEFT('Pre ID-' + @user_id_list, 199);
        DECLARE @job_flow_message VARCHAR(200) = LEFT(@user_id_list, 199);
        SET @batch_id = cast((format(getdate(), 'yyMMddHHmmssffff')) as bigint);

        IF @debug_logging = 1
        BEGIN
            EXEC dbo.sp_add_job_flow_log
                @batch_id = @batch_id,
                @dataflow_name = 'Patient PRE-Processing Event',
                @package_name = 'sp_patient_event',
                @status_type = 'START',
                @step_number = 0,
                @step_name = @job_flow_step_name,
                @row_count = 0,
                @msg_description1 = @job_flow_message;
        END;

        -- ---------------------------------------------------------------
        -- Temp table used to capture the detailed race calculation output
        -- returned by sp_patient_race_event (breakdown by race category:
        -- Native Hawaiian/Pacific Islander, Asian, American Indian, Black,
        -- White — up to 3 codes each plus a ">3 codes" indicator/summary).
        -- patient_uid_race_out is the join key back to person_uid.
        -- ---------------------------------------------------------------
        create table #temp_race_table
        (
            race_calculated       varchar(50)   null,
            race_calc_details     varchar(4000) null,
            race_all              varchar(4000) null,
            race_nat_hi_1         varchar(50)   null,
            race_nat_hi_2         varchar(50)   null,
            race_nat_hi_3         varchar(50)   null,
            race_nat_hi_gt3_ind   varchar(50)   null,
            race_nat_hi_all       varchar(2000) null,
            race_asian_1          varchar(50)   null,
            race_asian_2          varchar(50)   null,
            race_asian_3          varchar(50)   null,
            race_asian_gt3_ind    varchar(50)   null,
            race_asian_all        varchar(2000) null,
            race_amer_ind_1       varchar(50)   null,
            race_amer_ind_2       varchar(50)   null,
            race_amer_ind_3       varchar(50)   null,
            race_amer_ind_gt3_ind varchar(50)   null,
            race_amer_ind_all     varchar(2000) null,
            race_black_1          varchar(50)   null,
            race_black_2          varchar(50)   null,
            race_black_3          varchar(50)   null,
            race_black_gt3_ind    varchar(50)   null,
            race_black_all        varchar(2000) null,
            race_white_1          varchar(50)   null,
            race_white_2          varchar(50)   null,
            race_white_3          varchar(50)   null,
            race_white_gt3_ind    varchar(50)   null,
            race_white_all        varchar(2000) null,
            patient_uid_race_out  bigint        null
        )

        -- Populate the race temp table by executing the race-calculation
        -- sub-procedure for the same batch/person list. This pre-computes
        -- the race rollup so it can be joined into the final JSON payload
        -- later without recalculating per row.
        insert into #temp_race_table
        (race_calculated,
         race_calc_details,
         race_all,
         race_nat_hi_1,
         race_nat_hi_2,
         race_nat_hi_3,
         race_nat_hi_gt3_ind,
         race_nat_hi_all,
         race_asian_1,
         race_asian_2,
         race_asian_3,
         race_asian_gt3_ind,
         race_asian_all,
         race_amer_ind_1,
         race_amer_ind_2,
         race_amer_ind_3,
         race_amer_ind_gt3_ind,
         race_amer_ind_all,
         race_black_1,
         race_black_2,
         race_black_3,
         race_black_gt3_ind,
         race_black_all,
         race_white_1,
         race_white_2,
         race_white_3,
         race_white_gt3_ind,
         race_white_all,
         patient_uid_race_out)
            exec dbo.sp_patient_race_event @user_id_list, @batch_id;
        -- ---------------------------------------------------------------
        -- Materialize the incoming person_uid list into a temp table so
        -- the subsequent Person lookup can use a relational join instead
        -- of a string-splitting subquery. This is generally more efficient
        -- for larger Person tables and keeps the filtering plan simpler.
        -- ---------------------------------------------------------------
        CREATE TABLE #requested_person_ids
        (
            person_uid BIGINT NOT NULL PRIMARY KEY
        );

        INSERT INTO #requested_person_ids (person_uid)
        SELECT CAST(value AS BIGINT) AS person_uid
        FROM STRING_SPLIT(@user_id_list, ',')
        WHERE TRY_CAST(value AS BIGINT) IS NOT NULL;
        -- ---------------------------------------------------------------
        -- Pull the base Person records for only the requested person_uid
        -- values, restricted to cd = 'PAT' (patient-type Person entities).
        -- Materialized into a temp table (with a unique clustered index on
        -- person_uid) so subsequent joins/CTEs perform well and person_uid
        -- lookups are indexed.
        -- ---------------------------------------------------------------
        SELECT p.*
        INTO #filtered_person
        FROM nbs_odse.dbo.Person p WITH (NOLOCK)
                 JOIN #requested_person_ids rpi ON rpi.person_uid = p.person_uid
          AND p.cd = 'PAT';

        CREATE UNIQUE CLUSTERED INDEX IX_filtered_person_uid ON #filtered_person(person_uid);

        -- ---------------------------------------------------------------
        -- CTE pipeline to resolve coded (SRTE) values on the Person record
        -- into their human-readable short descriptions, so the final
        -- result set includes both the raw code and its description
        -- (e.g. curr_sex_cd -> current_sex).
        -- ---------------------------------------------------------------
        ;WITH person_codes AS (
            -- Flatten each filtered person's relevant code columns into
            -- one row per (person_uid, question_identifier, code) pair,
            -- using CROSS APPLY VALUES as a manual "unpivot". Blank
            -- string codes are converted to NULL and filtered out below.
            SELECT
                fp.person_uid,
                v.question_identifier,
                v.srte_code
            FROM #filtered_person fp
                CROSS APPLY (VALUES
                    ('DEM218', NULLIF(fp.age_reported_unit_cd, '')),
                    ('DEM113', NULLIF(fp.curr_sex_cd, '')),
                    ('DEM127', NULLIF(fp.deceased_ind_cd, '')),
                    ('DEM155', NULLIF(fp.ethnic_group_ind, '')),
                    ('DEM114', NULLIF(fp.birth_gender_cd, '')),
                    ('DEM140', NULLIF(fp.marital_status_cd, '')),
                    ('NBS214', NULLIF(fp.speaks_english_cd, '')),
                    ('NBS273', NULLIF(fp.ethnic_unk_reason_cd, '')),
                    ('NBS272', NULLIF(fp.sex_unk_reason_cd, '')),
                    ('DEM139', NULLIF(fp.occupation_cd, '')),
                    ('DEM142', NULLIF(fp.prim_lang_cd, ''))
                ) AS v(question_identifier, srte_code)
            WHERE v.srte_code IS NOT NULL
        ),
        person_code_desc AS (
            -- Standard lookup path: join question_identifier -> code_set_group_id
            -- -> codeset -> code_value_general to get the description for
            -- most demographic codes.
            SELECT pc.person_uid, pc.question_identifier, cvg.code_short_desc_txt
            FROM person_codes pc
                JOIN nbs_odse.dbo.nbs_question nq WITH (NOLOCK)
                    ON nq.question_identifier = pc.question_identifier
                JOIN nbs_srte.dbo.codeset cs WITH (NOLOCK)
                    ON cs.code_set_group_id = nq.code_set_group_id
                JOIN nbs_srte.dbo.code_value_general cvg WITH (NOLOCK)
                    ON cvg.code_set_nm = cs.code_set_nm
                   AND cvg.code = pc.srte_code

            UNION

            -- Special-case lookup for Occupation (DEM139): resolved against
            -- the NAICS industry code table instead of code_value_general.
            SELECT pc.person_uid, pc.question_identifier, cvg.code_short_desc_txt
            FROM person_codes pc
                JOIN nbs_odse.dbo.nbs_question nq WITH (NOLOCK)
                    ON nq.question_identifier = pc.question_identifier
                JOIN nbs_srte.dbo.codeset cs WITH (NOLOCK)
                    ON cs.code_set_group_id = nq.code_set_group_id
                JOIN nbs_srte.dbo.naics_industry_code cvg WITH (NOLOCK)
                    ON cvg.code_set_nm = cs.code_set_nm
                   AND cvg.code = pc.srte_code
            WHERE pc.question_identifier = 'DEM139'

            UNION

            -- Special-case lookup for Primary Language (DEM142): resolved
            -- against the language_code table instead of code_value_general.
            SELECT pc.person_uid, pc.question_identifier, cvg.code_short_desc_txt
            FROM person_codes pc
                JOIN nbs_odse.dbo.nbs_question nq WITH (NOLOCK)
                    ON nq.question_identifier = pc.question_identifier
                JOIN nbs_srte.dbo.codeset cs WITH (NOLOCK)
                    ON cs.code_set_group_id = nq.code_set_group_id
                JOIN nbs_srte.dbo.language_code cvg WITH (NOLOCK)
                    ON cvg.code_set_nm = cs.code_set_nm
                   AND cvg.code = pc.srte_code
            WHERE pc.question_identifier = 'DEM142'
        ),
        person_code_pivot AS (
            -- Pivot the long-format (person_uid, question_identifier, desc)
            -- rows back into one row per person_uid with a named column per
            -- code type, using MIN(CASE WHEN ...) as a manual PIVOT.
            SELECT
                person_uid,
                MIN(CASE WHEN question_identifier = 'DEM218' THEN code_short_desc_txt END) AS age_reported_unit,
                MIN(CASE WHEN question_identifier = 'DEM113' THEN code_short_desc_txt END) AS current_sex,
                MIN(CASE WHEN question_identifier = 'DEM127' THEN code_short_desc_txt END) AS deceased_indicator,
                MIN(CASE WHEN question_identifier = 'DEM155' THEN code_short_desc_txt END) AS ethnicity,
                MIN(CASE WHEN question_identifier = 'DEM114' THEN code_short_desc_txt END) AS birth_sex,
                MIN(CASE WHEN question_identifier = 'DEM140' THEN code_short_desc_txt END) AS marital_status,
                MIN(CASE WHEN question_identifier = 'NBS214' THEN code_short_desc_txt END) AS speaks_english,
                MIN(CASE WHEN question_identifier = 'NBS273' THEN code_short_desc_txt END) AS unk_ethnic_rsn,
                MIN(CASE WHEN question_identifier = 'NBS272' THEN code_short_desc_txt END) AS curr_sex_unk_rsn,
                MIN(CASE WHEN question_identifier = 'DEM139' THEN code_short_desc_txt END) AS primary_occupation,
                MIN(CASE WHEN question_identifier = 'DEM142' THEN code_short_desc_txt END) AS primary_language
            FROM person_code_desc
            GROUP BY person_uid
        )
        -- ---------------------------------------------------------------
        -- Final result set: one row per filtered person, combining:
        --   - raw Person columns (p.*)
        --   - resolved code descriptions from person_code_pivot (pcp.*)
        --   - preferred gender description (OUTER APPLY lookup)
        --   - add/last-change user full names (OUTER APPLY lookups)
        --   - nested JSON blocks for address, phone, email, name, race,
        --     and entity_id (OUTER APPLY ... FOR JSON PATH)
        -- ---------------------------------------------------------------
        SELECT p.person_uid,
               p.person_parent_uid,
               -- Strip embedded CR/LF from free-text description and trim whitespace.
               RTRIM(LTRIM(Replace(Replace(p.description, CHAR(10), ' '), CHAR(13), ' '))) as description,
               p.add_time,
               p.age_reported,
               p.age_reported_unit_cd,
               pcp.age_reported_unit,
               p.first_nm,
               p.middle_nm,
               p.last_nm,
               p.nm_suffix,
               p.as_of_date_admin,
               p.as_of_date_ethnicity,
               p.as_of_date_general,
               p.as_of_date_morbidity,
               p.as_of_date_sex,
               p.birth_time,
               p.birth_time_calc,
               p.cd,
               p.curr_sex_cd,
               pcp.current_sex,
               p.deceased_ind_cd,
               pcp.deceased_indicator,
               p.electronic_ind,
               p.ethnic_group_ind,
               pcp.ethnicity,
               p.birth_gender_cd,
               pcp.birth_sex,
               p.deceased_time,
               p.last_chg_time,
               p.marital_status_cd,
               pcp.marital_status,
               -- Normalize various "inactive" statuses down to a single
               -- ACTIVE/INACTIVE flag for simpler downstream consumption.
               CASE p.record_status_cd
                   WHEN 'LOG_DEL' THEN 'INACTIVE'
                   WHEN 'SUPERCEDED' THEN 'INACTIVE'
                   WHEN 'INACTIVE' THEN 'INACTIVE'
                   ELSE 'ACTIVE'
                   END AS record_status_cd,
               p.record_status_time,
               p.status_cd,
               p.status_time,
               p.local_id,
               p.version_ctrl_nbr,
               p.edx_ind,
               p.dedup_match_ind,
               p.speaks_english_cd,
               pcp.speaks_english,
               p.ethnic_unk_reason_cd,
               pcp.unk_ethnic_rsn,
               p.sex_unk_reason_cd,
               pcp.curr_sex_unk_rsn,
               p.preferred_gender_cd,
               preferred_gender_lookup.preferred_gender,
               p.additional_gender_cd,
               p.occupation_cd,
               pcp.primary_occupation,
               p.prim_lang_cd,
               pcp.primary_language,
               p.multiple_birth_ind,
               p.adults_in_house_nbr,
               p.birth_order_nbr,
               p.children_in_house_nbr,
               p.education_level_cd,
               p.add_user_id,
               add_user_lookup.add_user_name,
               p.last_chg_user_id,
               last_chg_user_lookup.last_chg_user_name,
               nested.name                                                                 AS 'patient_name',
               nested.address                                                              AS 'patient_address',
               nested.phone                                                                AS 'patient_telephone',
               nested.email                                                                AS 'patient_email',
               nested.race                                                                 AS 'patient_race',
               nested.entity_id                                                            AS 'patient_entity'
        FROM #filtered_person p
                 LEFT JOIN person_code_pivot pcp ON pcp.person_uid = p.person_uid

                 -- Resolve preferred_gender_cd against the NBS_STD_GENDER_PARPT
                 -- code set. TOP 1 + ORDER BY guards against duplicate code
                 -- entries returning multiple rows. fn_get_value_by_cvg is purposely
                 -- avoided due to performance issues
                 OUTER APPLY (
                     SELECT TOP 1 cvg.code_short_desc_txt
                     FROM nbs_srte.dbo.code_value_general cvg WITH (NOLOCK)
                     WHERE cvg.code_set_nm = 'NBS_STD_GENDER_PARPT'
                       AND cvg.code = NULLIF(p.preferred_gender_cd, '')
                     ORDER BY cvg.code_short_desc_txt
                 ) AS preferred_gender_lookup(preferred_gender)

                 -- Resolve the user who created the record ("Last, First").
                 -- Guards against add_user_id <= 0 (system/no user) before joining.
                 -- fn_get_user_name is purposely avoided due to it triggering
                 -- row by row execution and improper cardinality estimation
                 OUTER APPLY (
                     SELECT TOP 1 CAST((RTRIM(LTRIM(au.user_last_nm)) + ', ' +
                                        RTRIM(LTRIM(au.user_first_nm))) AS VARCHAR(150)) AS user_full_name
                     FROM NBS_ODSE.dbo.Auth_user au WITH (NOLOCK)
                     WHERE p.add_user_id > 0
                       AND au.NEDSS_ENTRY_ID = p.add_user_id
                     ORDER BY au.last_chg_time DESC
                 ) AS add_user_lookup(add_user_name)

                 -- Resolve the user who last modified the record ("Last, First").
                 -- fn_get_user_name is purposely avoided due to it triggering
                 -- row by row execution and improper cardinality estimation
                 OUTER APPLY (
                     SELECT TOP 1 CAST((RTRIM(LTRIM(au.user_last_nm)) + ', ' +
                                        RTRIM(LTRIM(au.user_first_nm))) AS VARCHAR(150)) AS user_full_name
                     FROM NBS_ODSE.dbo.Auth_user au WITH (NOLOCK)
                     WHERE p.last_chg_user_id > 0
                       AND au.NEDSS_ENTRY_ID = p.last_chg_user_id
                     ORDER BY au.last_chg_time DESC
                 ) AS last_chg_user_lookup(last_chg_user_name)

                 -- =========================================================
                 -- Per-person nested JSON payload. Each sub-select builds
                 -- one JSON array (via FOR JSON PATH) for a related child
                 -- entity set, all combined into a single "nested" row so
                 -- they can be selected as individual JSON columns above.
                 -- =========================================================
                 OUTER apply (SELECT *
                              FROM
                                  -- -----------------------------------------------------
                                  -- ADDRESS: home ('H') and birth ('BIR') postal locators,
                                  -- with state/county/country descriptions resolved and
                                  -- string fields JSON-escaped/truncated to 50 chars.
                                  -- home_country / birth_country are conditionally
                                  -- populated depending on the locator's use_cd.
                                  -- -----------------------------------------------------
                                  (SELECT (SELECT elp.cd                                                                 AS [addr_elp_cd],

                                                  elp.use_cd                                                             AS [addr_elp_use_cd],
                                                  pl.postal_locator_uid                                                  as [addr_pl_uid],
                                                  LTRIM(RTRIM(SUBSTRING(STRING_ESCAPE(pl.street_addr1, 'json'),1,50)))   AS street_addr1,
                                                  LTRIM(RTRIM(SUBSTRING(STRING_ESCAPE(pl.street_addr2, 'json'),1,50)))   AS street_addr2,
                                                  LTRIM(RTRIM(SUBSTRING(STRING_ESCAPE(pl.city_desc_txt, 'json'),1,50)))  AS city,
                                                  pl.zip_cd                                                              AS [zip],
                                                  pl.cnty_cd                                                             AS [cntyCd],
                                                  pl.state_cd                                                            AS [state],
                                                  pl.cntry_cd                                                            AS [cntryCd],
                                                  sc.code_desc_txt                                                      AS [state_desc],
                                                  scc.code_desc_txt                                                     AS [county],
                                                  pl.census_tract                                                       AS [census_tract],
                                                  pl.within_city_limits_ind,
                                                  case
                                                      when elp.use_cd = 'H'
                                                          then coalesce(cc.code_short_desc_txt, pl.cntry_cd)
                                                      else null end                                                      AS [home_country],
                                                  case when elp.use_cd = 'BIR' then cvg.code_short_desc_txt else null end AS [birth_country]
                                           FROM nbs_odse.dbo.Entity_locator_participation elp WITH (NOLOCK)
                                                    LEFT OUTER JOIN nbs_odse.dbo.Postal_locator pl WITH (NOLOCK)
                                                                    ON elp.locator_uid = pl.postal_locator_uid
                                                    LEFT OUTER JOIN nbs_srte.dbo.State_code sc with (NOLOCK) ON sc.state_cd = pl.state_cd
                                                    LEFT OUTER JOIN nbs_srte.dbo.State_county_code_value scc with (NOLOCK)
                                                                    ON scc.code = pl.cnty_cd
                                                    LEFT OUTER JOIN nbs_srte.dbo.Country_CODE cc with (nolock) ON cc.code = pl.cntry_cd
                                                    -- Birth-country description: dedupe against multiple code sets
                                                    -- by ranking on nbs_uid and keeping only the most recent (rnk = 1) per code.
                                                    LEFT OUTER JOIN (
                                                        select tmp.code, tmp.code_short_desc_txt from (
                                                            -- ranking added to pick the latest valid short desc
                                                            select code, code_short_desc_txt, rank () OVER (PARTITION BY code order by nbs_uid desc) rnk
                                                            from nbs_srte.dbo.CODE_VALUE_GENERAL with (nolock) where CODE_SET_NM in( 'PHVS_BIRTHCOUNTRY_CDC', 'PHVS_TB_BIRTH_CNTRY', 'PSL_CNTRY')
                                                        ) tmp where rnk=1
                                                    ) cvg ON cvg.code = pl.cntry_cd
                                           WHERE elp.entity_uid = p.person_uid
                                             AND elp.class_cd = 'PST'
                                             AND elp.use_cd IN ('H', 'BIR')
                                             AND elp.RECORD_STATUS_CD = 'ACTIVE'
                                           FOR json path, INCLUDE_NULL_VALUES) AS address) AS address,

                                  -- -----------------------------------------------------
                                  -- PHONE: active telephone locators for this person,
                                  -- with spaces stripped from the phone number.
                                  -- -----------------------------------------------------
                                  (SELECT (SELECT tl.tele_locator_uid                AS [ph_tl_uid],
                                                  elp.cd                             AS [ph_elp_cd],
                                                  elp.use_cd                         AS [ph_elp_use_cd],
                                                  REPLACE(tl.phone_nbr_txt, ' ', '') AS [telephoneNbr],
                                                  tl.extension_txt                   AS [extensionTxt]
                                           FROM nbs_odse.dbo.Entity_locator_participation elp WITH (NOLOCK)
                                                    JOIN nbs_odse.dbo.Tele_locator tl WITH (NOLOCK)
                                                         ON elp.locator_uid = tl.tele_locator_uid
                                           WHERE elp.entity_uid = p.person_uid
                                             AND elp.class_cd = 'TELE'
                                             AND elp.record_status_cd = 'ACTIVE'
                                             AND tl.phone_nbr_txt IS NOT NULL
                                           FOR json path, INCLUDE_NULL_VALUES) AS phone) AS phone,

                                  -- -----------------------------------------------------
                                  -- EMAIL: active email-type ('NET') telephone locators,
                                  -- with the address JSON-escaped.
                                  -- -----------------------------------------------------
                                  (SELECT (SELECT tl.tele_locator_uid                     AS [email_tl_uid],
                                                  elp.cd                                  AS [email_elp_cd],
                                                  elp.use_cd                              AS [email_elp_use_cd],
                                                  STRING_ESCAPE(tl.email_address, 'json') AS [emailAddress]
                                           FROM nbs_odse.dbo.Entity_locator_participation elp WITH (NOLOCK)
                                                    JOIN nbs_odse.dbo.Tele_locator tl WITH (NOLOCK)
                                                         ON elp.locator_uid = tl.tele_locator_uid
                                           WHERE elp.entity_uid = p.person_uid
                                             AND elp.cd = 'NET'
                                             AND elp.class_cd = 'TELE'
                                             AND elp.record_status_cd = 'ACTIVE'
                                             AND tl.email_address IS NOT NULL
                                           FOR json path, INCLUDE_NULL_VALUES) AS email) AS email,

                                  -- -----------------------------------------------------
                                  -- NAME: all person_name records for this person, with
                                  -- Soundex codes computed for first/last name (for fuzzy
                                  -- matching downstream) and the name suffix resolved via
                                  -- the DEM107 code set.
                                  -- fn_get_value_by_cd_ques is purposely avoided due to it triggering
                                  -- row by row execution and improper cardinality estimation
                                  -- -----------------------------------------------------
                                  (SELECT (SELECT pn.person_uid                                        AS [pn_person_uid],
                                                  STRING_ESCAPE(REPLACE(pn.last_nm, '-', ' '), 'json') AS [lastNm],
                                                  soundex(pn.last_nm)                                  AS [lastNmSndx],
                                                  STRING_ESCAPE(pn.middle_nm, 'json')                  AS [middleNm],
                                                  STRING_ESCAPE(pn.first_nm, 'json')                   AS [firstNm],
                                                  soundex(pn.first_nm)                                 AS [firstNmSndx],
                                                  pn.nm_use_cd                                         AS [nm_use_cd],
                                                  pn.status_cd                                         AS [status_name_cd],
                                                  pn.nm_suffix                                         AS [nmSuffix],
                                                  suffix_lookup.name_suffix                            AS name_suffix,
                                                  pn.nm_degree                                         AS [nmDegree],
                                                  pn.person_name_seq                                   AS [pn_person_name_seq],
                                                  pn.last_chg_time                                     AS [pn_last_chg_time]
                                           FROM nbs_odse.dbo.person_name pn WITH (NOLOCK)
                                                    OUTER APPLY (
                                                        SELECT TOP 1 cvg.code_short_desc_txt
                                                        FROM nbs_odse.dbo.nbs_question nq WITH (NOLOCK)
                                                                 JOIN nbs_srte.dbo.codeset cs WITH (NOLOCK)
                                                                      ON cs.code_set_group_id = nq.code_set_group_id
                                                                 JOIN nbs_srte.dbo.code_value_general cvg WITH (NOLOCK)
                                                                      ON cvg.code_set_nm = cs.code_set_nm
                                                        WHERE nq.question_identifier = 'DEM107'
                                                          AND cvg.code = NULLIF(pn.nm_suffix, '')
                                                        ORDER BY cvg.code_short_desc_txt
                                                    ) AS suffix_lookup(name_suffix)
                                           WHERE person_uid = p.person_uid
                                           FOR json path, INCLUDE_NULL_VALUES) AS name) AS name,

                                  -- -----------------------------------------------------
                                  -- RACE: raw person_race rows joined to the race_code
                                  -- reference table plus the pre-calculated race rollup
                                  -- fields from #temp_race_table (populated earlier via
                                  -- sp_patient_race_event).
                                  -- -----------------------------------------------------
                                  (SELECT (SELECT pr.person_uid       AS [pr_person_uid],
                                                  pr.race_cd          AS [raceCd],
                                                  pr.race_desc_txt    AS [raceDescTxt],
                                                  pr.race_category_cd AS [raceCategoryCd],
                                                  src.code_desc_txt   AS [srte_code_desc_txt],
                                                  src.parent_is_cd    AS [srte_parent_is_cd],
                                                  race_calculated,
                                                  race_calc_details,
                                                  race_amer_ind_1,
                                                  race_amer_ind_2,
                                                  race_amer_ind_3,
                                                  race_amer_ind_gt3_ind,
                                                  race_amer_ind_all,
                                                  race_asian_1,
                                                  race_asian_2,
                                                  race_asian_3,
                                                  race_asian_gt3_ind,
                                                  race_asian_all,
                                                  race_black_1,
                                                  race_black_2,
                                                  race_black_3,
                                                  race_black_gt3_ind,
                                                  race_black_all,
                                                  race_nat_hi_1,
                                                  race_nat_hi_2,
                                                  race_nat_hi_3,
                                                  race_nat_hi_gt3_ind,
                                                  race_nat_hi_all,
                                                  race_white_1,
                                                  race_white_2,
                                                  race_white_3,
                                                  race_white_gt3_ind,
                                                  race_white_all,
                                                  race_all
                                           FROM nbs_odse.dbo.person_race pr WITH (NOLOCK)
                                                    left outer join nbs_srte.dbo.race_code src WITH (NOLOCK) ON pr.race_cd = src.code
                                                    left outer join #temp_race_table trt WITH (NOLOCK) on trt.patient_uid_race_out = p.person_uid
                                           WHERE person_uid = p.person_uid
                                           FOR json path, INCLUDE_NULL_VALUES) AS race) AS race,

                                  -- -----------------------------------------------------
                                  -- ENTITY_ID: all entity_id records (e.g. SSN/Driver's License/etc)
                                  -- associated with this person, with spaces stripped and value JSON-escaped.
                                  -- -----------------------------------------------------
                                  (SELECT (SELECT ei.entity_uid             AS [entity_uid],
                                                  ei.type_cd                AS [typeCd],
                                                  ei.record_status_cd       AS [recordStatusCd],
                                                  STRING_ESCAPE(REPLACE(ei.root_extension_txt, ' ', ''),
                                                                'json')     AS [rootExtensionTxt],
                                                  ei.entity_id_seq          AS [entity_id_seq],
                                                  ei.assigning_authority_cd AS [assigning_authority_cd]
                                           FROM nbs_odse.dbo.entity_id ei WITH (NOLOCK)
                                           WHERE ei.entity_uid = p.person_uid
                                           FOR json path, INCLUDE_NULL_VALUES) AS entity_id) AS entity_id) AS nested;

        IF @debug_logging = 1
        BEGIN
            EXEC dbo.sp_add_job_flow_log
                @batch_id = @batch_id,
                @dataflow_name = 'Patient PRE-Processing Event',
                @package_name = 'sp_patient_event',
                @status_type = 'COMPLETE',
                @step_number = 0,
                @step_name = @job_flow_step_name,
                @row_count = 0,
                @msg_description1 = @job_flow_message;
        END;

    END TRY
    BEGIN CATCH

        -- Roll back any open transaction before logging the error.
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        EXEC dbo.sp_add_job_flow_log
            @batch_id = @batch_id,
            @dataflow_name = 'Patient PRE-Processing Event',
            @package_name = 'sp_patient_event',
            @status_type = 'ERROR',
            @step_number = 0,
            @step_name = 'Patient PRE-Processing Event',
            @row_count = 0,
            @msg_description1 = @job_flow_message,
            @error_description = @FullErrorMessage;
        return @FullErrorMessage;

    END CATCH

END;
