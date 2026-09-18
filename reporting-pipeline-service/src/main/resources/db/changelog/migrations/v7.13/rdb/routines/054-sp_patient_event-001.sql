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
-- Parameters:  @user_id_list   - Comma-separated list of person_uid (BIGINT)
--                                 values identifying which patients to process.
--              @debug_logging  - When 1, writes START/COMPLETE rows to
--                                 job_flow_log in addition to the ERROR row
--                                 that is always written on failure.
--
-- Returns:     Result set of patient/person records (one row per person_uid),
--              including nested JSON columns for address/phone/email/name/race/entity.
--              On failure, returns a formatted error message string instead.
--
-- Design notes:
--   - Uses NOLOCK hints throughout for read performance on a (presumably)
--     stable/replicated reporting source; be aware this can read
--     uncommitted/dirty data.
--   - @batch_id is derived from the current timestamp (format
--     yyMMddHHmmssffff) and is used to correlate all job_flow_log entries
--     for a single execution.
--   - fn_get_user_name, fn_get_value_by_cvg, and fn_get_value_by_cd_ques are
--     intentionally not used: scalar UDFs of this kind force row-by-row
--     execution and prevent the optimizer from producing accurate
--     cardinality estimates. All lookups here are done with joins/derived
--     tables instead.
--   - Small reference/dedupe lookups (current country-code description,
--     DEM107 name-suffix description, preferred-gender description, and
--     add/last-change user display names) are each resolved once into a
--     small indexed temp table up front, then joined normally, rather than
--     being re-resolved per patient row.
--   - The nested JSON sub-records (address, phone, email, name, race,
--     entity ID) are each built by first joining the relevant source
--     tables against the full filtered patient set in one set-based pass,
--     landing the results in a small temp table indexed on person_uid.
--     The final per-patient FOR JSON PATH projection then reads from that
--     small temp table instead of re-joining the large source tables for
--     every patient.
-- =============================================================================

IF EXISTS (
    SELECT *
    FROM sysobjects
    WHERE id = OBJECT_ID(N'[dbo].[sp_patient_event]')
      AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_patient_event];
END
GO

CREATE PROCEDURE dbo.sp_patient_event
    @user_id_list   NVARCHAR(MAX),
    @debug_logging  BIT = 0
AS
BEGIN

    BEGIN TRY

        -- ---------------------------------------------------------------
        -- Generate a unique batch identifier for this execution based on
        -- the current date/time (down to fractional seconds). Used to
        -- correlate all log rows written by this run.
        -- ---------------------------------------------------------------
        DECLARE @batch_id            BIGINT;
        DECLARE @job_flow_step_name  VARCHAR(200) = LEFT('Pre ID-' + @user_id_list, 199);
        DECLARE @job_flow_message    VARCHAR(200) = LEFT(@user_id_list, 199);

        SET @batch_id = CAST(FORMAT(GETDATE(), 'yyMMddHHmmssffff') AS BIGINT);

        IF @debug_logging = 1
        BEGIN
            EXEC dbo.sp_add_job_flow_log
                @batch_id          = @batch_id,
                @dataflow_name     = 'Patient PRE-Processing Event',
                @package_name      = 'sp_patient_event',
                @status_type       = 'START',
                @step_number       = 0,
                @step_name         = @job_flow_step_name,
                @row_count         = 0,
                @msg_description1  = @job_flow_message;
        END;

        -- ---------------------------------------------------------------
        -- Temp table used to capture the detailed race calculation output
        -- returned by sp_patient_race_event (breakdown by race category:
        -- Native Hawaiian/Pacific Islander, Asian, American Indian, Black,
        -- White -- up to 3 codes each plus a ">3 codes" indicator/summary).
        -- patient_uid_race_out is the join key back to person_uid.
        -- ---------------------------------------------------------------
        CREATE TABLE #temp_race_table
        (
            race_calculated        VARCHAR(50)    NULL,
            race_calc_details      VARCHAR(4000)  NULL,
            race_all                VARCHAR(4000) NULL,
            race_nat_hi_1           VARCHAR(50)   NULL,
            race_nat_hi_2           VARCHAR(50)   NULL,
            race_nat_hi_3           VARCHAR(50)   NULL,
            race_nat_hi_gt3_ind     VARCHAR(50)   NULL,
            race_nat_hi_all         VARCHAR(2000) NULL,
            race_asian_1            VARCHAR(50)   NULL,
            race_asian_2            VARCHAR(50)   NULL,
            race_asian_3            VARCHAR(50)   NULL,
            race_asian_gt3_ind      VARCHAR(50)   NULL,
            race_asian_all          VARCHAR(2000) NULL,
            race_amer_ind_1         VARCHAR(50)   NULL,
            race_amer_ind_2         VARCHAR(50)   NULL,
            race_amer_ind_3         VARCHAR(50)   NULL,
            race_amer_ind_gt3_ind   VARCHAR(50)   NULL,
            race_amer_ind_all       VARCHAR(2000) NULL,
            race_black_1            VARCHAR(50)   NULL,
            race_black_2            VARCHAR(50)   NULL,
            race_black_3            VARCHAR(50)   NULL,
            race_black_gt3_ind      VARCHAR(50)   NULL,
            race_black_all          VARCHAR(2000) NULL,
            race_white_1            VARCHAR(50)   NULL,
            race_white_2            VARCHAR(50)   NULL,
            race_white_3            VARCHAR(50)   NULL,
            race_white_gt3_ind      VARCHAR(50)   NULL,
            race_white_all          VARCHAR(2000) NULL,
            patient_uid_race_out    BIGINT        NULL
        );

        -- Populate the race temp table by executing the race-calculation
        -- sub-procedure for the same batch/person list. This pre-computes
        -- the race rollup so it can be joined into the final JSON payload
        -- later without recalculating per row.
        INSERT INTO #temp_race_table
        (
            race_calculated,
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
            patient_uid_race_out
        )
        EXEC dbo.sp_patient_race_event @user_id_list, @batch_id;

        -- ---------------------------------------------------------------
        -- Materialize the incoming person_uid list into a temp table so
        -- the subsequent Person lookup can use a relational join instead
        -- of a string-splitting subquery. This is generally more efficient
        -- for larger Person tables and keeps the filtering plan simpler.
        -- Non-numeric/blank list entries are silently discarded via
        -- TRY_CAST rather than raising a conversion error.
        -- ---------------------------------------------------------------
        CREATE TABLE #requested_person_ids
        (
            person_uid  BIGINT NOT NULL PRIMARY KEY
        );

        INSERT INTO #requested_person_ids (person_uid)
        SELECT v.person_uid
        FROM (
            SELECT TRY_CAST(value AS BIGINT) AS person_uid
            FROM STRING_SPLIT(@user_id_list, ',')
        ) v
        WHERE v.person_uid IS NOT NULL;

        -- ---------------------------------------------------------------
        -- Pull the base Person records for only the requested person_uid
        -- values, restricted to cd = 'PAT' (patient-type Person entities).
        -- Only the columns consumed later in this procedure are selected,
        -- to keep the temp table (and every downstream join against it)
        -- as narrow as possible. Materialized into a temp table (with a
        -- unique clustered index on person_uid) so subsequent joins/CTEs
        -- perform well and person_uid lookups are indexed.
        -- ---------------------------------------------------------------
        SELECT
            p.person_uid,
            p.person_parent_uid,
            p.description,
            p.add_time,
            p.age_reported,
            p.age_reported_unit_cd,
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
            p.deceased_ind_cd,
            p.electronic_ind,
            p.ethnic_group_ind,
            p.birth_gender_cd,
            p.deceased_time,
            p.last_chg_time,
            p.marital_status_cd,
            p.record_status_cd,
            p.record_status_time,
            p.status_cd,
            p.status_time,
            p.local_id,
            p.version_ctrl_nbr,
            p.edx_ind,
            p.dedup_match_ind,
            p.speaks_english_cd,
            p.ethnic_unk_reason_cd,
            p.sex_unk_reason_cd,
            p.preferred_gender_cd,
            p.additional_gender_cd,
            p.occupation_cd,
            p.prim_lang_cd,
            p.multiple_birth_ind,
            p.adults_in_house_nbr,
            p.birth_order_nbr,
            p.children_in_house_nbr,
            p.education_level_cd,
            p.add_user_id,
            p.last_chg_user_id
        INTO #filtered_person
        FROM nbs_odse.dbo.Person p WITH (NOLOCK)
        JOIN #requested_person_ids rpi
            ON rpi.person_uid = p.person_uid
           AND p.cd = 'PAT';

        CREATE UNIQUE CLUSTERED INDEX IX_filtered_person_uid ON #filtered_person (person_uid);

        -- =================================================================
        -- Reference/dedupe lookups
        --
        -- Each of these resolves a small, fixed reference code set exactly
        -- once for the whole batch (rather than once per patient), then
        -- gets joined normally further down. Where a code can map to more
        -- than one description (e.g. multiple valid code sets, or multiple
        -- Auth_user rows for the same login), a deterministic ranking picks
        -- a single "best" row per code so the later joins stay one-to-one.
        -- =================================================================

        -- Current description for a country code, deduplicated across the
        -- three code sets that can define it (birth country, TB birth
        -- country, and general country code sets), keeping the most
        -- recently added definition per code.
        ;WITH ranked_country AS
        (
            SELECT
                code,
                code_short_desc_txt,
                RANK() OVER (PARTITION BY code ORDER BY nbs_uid DESC) AS rnk
            FROM nbs_srte.dbo.CODE_VALUE_GENERAL WITH (NOLOCK)
            WHERE CODE_SET_NM IN ('PHVS_BIRTHCOUNTRY_CDC', 'PHVS_TB_BIRTH_CNTRY', 'PSL_CNTRY')
        )
        SELECT
            code,
            code_short_desc_txt
        INTO #country_code_latest
        FROM ranked_country
        WHERE rnk = 1;

        CREATE UNIQUE CLUSTERED INDEX IX_country_code_latest ON #country_code_latest (code);

        -- Name-suffix description (DEM107 code set, e.g. Jr., Sr., III).
        ;WITH ranked_suffix AS
        (
            SELECT
                cvg.code,
                cvg.code_short_desc_txt,
                ROW_NUMBER() OVER (PARTITION BY cvg.code ORDER BY cvg.code_short_desc_txt) AS rn
            FROM nbs_odse.dbo.nbs_question nq WITH (NOLOCK)
            JOIN nbs_srte.dbo.codeset cs WITH (NOLOCK)
                ON cs.code_set_group_id = nq.code_set_group_id
            JOIN nbs_srte.dbo.code_value_general cvg WITH (NOLOCK)
                ON cvg.code_set_nm = cs.code_set_nm
            WHERE nq.question_identifier = 'DEM107'
        )
        SELECT
            code,
            code_short_desc_txt
        INTO #suffix_codes
        FROM ranked_suffix
        WHERE rn = 1;

        CREATE UNIQUE CLUSTERED INDEX IX_suffix_codes ON #suffix_codes (code);

        -- Preferred-gender description (NBS_STD_GENDER_PARPT code set).
        ;WITH ranked_gender AS
        (
            SELECT
                code,
                code_short_desc_txt,
                ROW_NUMBER() OVER (PARTITION BY code ORDER BY code_short_desc_txt) AS rn
            FROM nbs_srte.dbo.code_value_general WITH (NOLOCK)
            WHERE code_set_nm = 'NBS_STD_GENDER_PARPT'
        )
        SELECT
            code,
            code_short_desc_txt
        INTO #gender_codes
        FROM ranked_gender
        WHERE rn = 1;

        CREATE UNIQUE CLUSTERED INDEX IX_gender_codes ON #gender_codes (code);

        -- Display name ("Last, First") for the users who created or last
        -- modified any patient in this batch. Only the distinct user IDs
        -- actually referenced by #filtered_person are looked up. Where a
        -- user ID has multiple Auth_user rows, the most recently changed
        -- row is kept.
        ;WITH user_ids AS
        (
            SELECT add_user_id AS nedss_entry_id FROM #filtered_person WHERE add_user_id > 0
            UNION
            SELECT last_chg_user_id FROM #filtered_person WHERE last_chg_user_id > 0
        ),
        ranked_users AS
        (
            SELECT
                au.NEDSS_ENTRY_ID,
                CAST((RTRIM(LTRIM(au.user_last_nm)) + ', ' + RTRIM(LTRIM(au.user_first_nm))) AS VARCHAR(150)) AS user_full_name,
                ROW_NUMBER() OVER (PARTITION BY au.NEDSS_ENTRY_ID ORDER BY au.last_chg_time DESC) AS rn
            FROM NBS_ODSE.dbo.Auth_user au WITH (NOLOCK)
            JOIN user_ids ui
                ON ui.nedss_entry_id = au.NEDSS_ENTRY_ID
        )
        SELECT
            NEDSS_ENTRY_ID,
            user_full_name
        INTO #user_names
        FROM ranked_users
        WHERE rn = 1;

        CREATE UNIQUE CLUSTERED INDEX IX_user_names ON #user_names (NEDSS_ENTRY_ID);

        -- =================================================================
        -- Nested-record staging tables
        --
        -- Each block below resolves one of the nested JSON sub-records
        -- (address, phone/email, name, race, entity ID) for every patient
        -- in the batch in a single set-based pass, indexed on person_uid.
        -- The final result set further down reads from these staging
        -- tables when assembling the per-patient JSON payloads.
        -- =================================================================

        -- Active home ('H') and birth ('BIR') postal addresses, with
        -- state/county/country descriptions resolved and text fields
        -- JSON-escaped and truncated to 50 characters. home_country and
        -- birth_country are populated only for the matching use_cd.
        SELECT
            elp.entity_uid                                                          AS person_uid,
            elp.cd                                                                  AS elp_cd,
            elp.use_cd                                                              AS elp_use_cd,
            pl.postal_locator_uid                                                   AS pl_uid,
            LTRIM(RTRIM(SUBSTRING(STRING_ESCAPE(pl.street_addr1, 'json'), 1, 50)))   AS street_addr1,
            LTRIM(RTRIM(SUBSTRING(STRING_ESCAPE(pl.street_addr2, 'json'), 1, 50)))   AS street_addr2,
            LTRIM(RTRIM(SUBSTRING(STRING_ESCAPE(pl.city_desc_txt, 'json'), 1, 50)))  AS city,
            pl.zip_cd,
            pl.cnty_cd,
            pl.state_cd,
            pl.cntry_cd,
            sc.code_desc_txt                                                        AS state_desc,
            scc.code_desc_txt                                                       AS county_desc,
            pl.census_tract,
            pl.within_city_limits_ind,
            CASE WHEN elp.use_cd = 'H'   THEN COALESCE(cc.code_short_desc_txt, pl.cntry_cd) ELSE NULL END AS home_country,
            CASE WHEN elp.use_cd = 'BIR' THEN ccl.code_short_desc_txt               ELSE NULL END AS birth_country
        INTO #person_address
        FROM #filtered_person fp
        JOIN nbs_odse.dbo.Entity_locator_participation elp WITH (NOLOCK)
            ON elp.entity_uid = fp.person_uid
           AND elp.class_cd = 'PST'
           AND elp.use_cd IN ('H', 'BIR')
           AND elp.record_status_cd = 'ACTIVE'
        LEFT OUTER JOIN nbs_odse.dbo.Postal_locator pl WITH (NOLOCK)
            ON pl.postal_locator_uid = elp.locator_uid
        LEFT OUTER JOIN nbs_srte.dbo.State_code sc WITH (NOLOCK)
            ON sc.state_cd = pl.state_cd
        LEFT OUTER JOIN nbs_srte.dbo.State_county_code_value scc WITH (NOLOCK)
            ON scc.code = pl.cnty_cd
        LEFT OUTER JOIN nbs_srte.dbo.Country_code cc WITH (NOLOCK)
            ON cc.code = pl.cntry_cd
        LEFT OUTER JOIN #country_code_latest ccl
            ON ccl.code = pl.cntry_cd;

        CREATE INDEX IX_person_address_uid ON #person_address (person_uid);

        -- Active telephone locators, covering both phone and email
        -- ('NET') use cases in a single pass; the final projection below
        -- filters this set differently for the phone vs. email JSON
        -- blocks. Phone numbers have spaces stripped; email addresses are
        -- JSON-escaped.
        SELECT
            elp.entity_uid                            AS person_uid,
            tl.tele_locator_uid                        AS tl_uid,
            elp.cd                                     AS elp_cd,
            elp.use_cd                                 AS elp_use_cd,
            REPLACE(tl.phone_nbr_txt, ' ', '')          AS phone_nbr,
            tl.extension_txt,
            STRING_ESCAPE(tl.email_address, 'json')     AS email_address
        INTO #person_tele
        FROM #filtered_person fp
        JOIN nbs_odse.dbo.Entity_locator_participation elp WITH (NOLOCK)
            ON elp.entity_uid = fp.person_uid
           AND elp.class_cd = 'TELE'
           AND elp.record_status_cd = 'ACTIVE'
        JOIN nbs_odse.dbo.Tele_locator tl WITH (NOLOCK)
            ON tl.tele_locator_uid = elp.locator_uid
        WHERE tl.phone_nbr_txt IS NOT NULL
           OR tl.email_address IS NOT NULL;

        CREATE INDEX IX_person_tele_uid ON #person_tele (person_uid);

        -- All person_name records for each patient, with Soundex codes
        -- computed for first/last name (for downstream fuzzy matching)
        -- and the name-suffix description resolved from #suffix_codes.
        SELECT
            pn.person_uid,
            pn.person_name_seq,
            pn.last_chg_time,
            pn.nm_degree,
            pn.nm_suffix,
            pn.nm_use_cd,
            pn.status_cd,
            STRING_ESCAPE(REPLACE(pn.last_nm, '-', ' '), 'json')  AS last_nm_esc,
            SOUNDEX(pn.last_nm)                                    AS last_nm_sndx,
            STRING_ESCAPE(pn.middle_nm, 'json')                    AS middle_nm_esc,
            STRING_ESCAPE(pn.first_nm, 'json')                     AS first_nm_esc,
            SOUNDEX(pn.first_nm)                                   AS first_nm_sndx,
            sfx.code_short_desc_txt                                AS name_suffix
        INTO #person_name
        FROM #filtered_person fp
        JOIN nbs_odse.dbo.person_name pn WITH (NOLOCK)
            ON pn.person_uid = fp.person_uid
        LEFT OUTER JOIN #suffix_codes sfx
            ON sfx.code = NULLIF(pn.nm_suffix, '');

        CREATE INDEX IX_person_name_uid ON #person_name (person_uid);

        -- Raw person_race rows joined to the race reference table, plus
        -- the pre-calculated race rollup fields from #temp_race_table
        -- (populated earlier via sp_patient_race_event).
        SELECT
            pr.person_uid,
            pr.race_cd,
            pr.race_desc_txt,
            pr.race_category_cd,
            src.code_desc_txt  AS srte_code_desc_txt,
            src.parent_is_cd   AS srte_parent_is_cd,
            trt.race_calculated,
            trt.race_calc_details,
            trt.race_amer_ind_1,
            trt.race_amer_ind_2,
            trt.race_amer_ind_3,
            trt.race_amer_ind_gt3_ind,
            trt.race_amer_ind_all,
            trt.race_asian_1,
            trt.race_asian_2,
            trt.race_asian_3,
            trt.race_asian_gt3_ind,
            trt.race_asian_all,
            trt.race_black_1,
            trt.race_black_2,
            trt.race_black_3,
            trt.race_black_gt3_ind,
            trt.race_black_all,
            trt.race_nat_hi_1,
            trt.race_nat_hi_2,
            trt.race_nat_hi_3,
            trt.race_nat_hi_gt3_ind,
            trt.race_nat_hi_all,
            trt.race_white_1,
            trt.race_white_2,
            trt.race_white_3,
            trt.race_white_gt3_ind,
            trt.race_white_all,
            trt.race_all
        INTO #person_race
        FROM #filtered_person fp
        JOIN nbs_odse.dbo.person_race pr WITH (NOLOCK)
            ON pr.person_uid = fp.person_uid
        LEFT OUTER JOIN nbs_srte.dbo.race_code src WITH (NOLOCK)
            ON pr.race_cd = src.code
        LEFT OUTER JOIN #temp_race_table trt
            ON trt.patient_uid_race_out = fp.person_uid;

        CREATE INDEX IX_person_race_uid ON #person_race (person_uid);

        -- All entity_id records (e.g. SSN, Driver's License, etc.)
        -- associated with each patient, with spaces stripped and the
        -- value JSON-escaped.
        SELECT
            ei.entity_uid                                                    AS person_uid,
            ei.type_cd,
            ei.record_status_cd,
            STRING_ESCAPE(REPLACE(ei.root_extension_txt, ' ', ''), 'json')   AS root_extension_esc,
            ei.entity_id_seq,
            ei.assigning_authority_cd
        INTO #person_entity_id
        FROM #filtered_person fp
        JOIN nbs_odse.dbo.entity_id ei WITH (NOLOCK)
            ON ei.entity_uid = fp.person_uid;

        CREATE INDEX IX_person_entity_id_uid ON #person_entity_id (person_uid);

        -- ---------------------------------------------------------------
        -- CTE pipeline to resolve coded (SRTE) values on the Person record
        -- into their human-readable short descriptions, so the final
        -- result set includes both the raw code and its description
        -- (e.g. curr_sex_cd -> current_sex).
        -- ---------------------------------------------------------------
        ;WITH person_codes AS
        (
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
            ) AS v (question_identifier, srte_code)
            WHERE v.srte_code IS NOT NULL
        ),
        person_code_desc AS
        (
            -- Standard lookup path: join question_identifier -> code_set_group_id
            -- -> codeset -> code_value_general to get the description for
            -- most demographic codes.
            SELECT
                pc.person_uid,
                pc.question_identifier,
                cvg.code_short_desc_txt
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
            SELECT
                pc.person_uid,
                pc.question_identifier,
                cvg.code_short_desc_txt
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
            SELECT
                pc.person_uid,
                pc.question_identifier,
                cvg.code_short_desc_txt
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
        person_code_pivot AS
        (
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
        --   - preferred gender description (from #gender_codes)
        --   - add/last-change user full names (from #user_names)
        --   - nested JSON blocks for address, phone, email, name, race,
        --     and entity_id (built from the #person_* staging tables via
        --     OUTER APPLY ... FOR JSON PATH)
        -- ---------------------------------------------------------------
        SELECT
            p.person_uid,
            p.person_parent_uid,
            -- Strip embedded CR/LF from free-text description and trim whitespace.
            RTRIM(LTRIM(REPLACE(REPLACE(p.description, CHAR(10), ' '), CHAR(13), ' '))) AS description,
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
                WHEN 'LOG_DEL'     THEN 'INACTIVE'
                WHEN 'SUPERCEDED'  THEN 'INACTIVE'
                WHEN 'INACTIVE'    THEN 'INACTIVE'
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
            gc.code_short_desc_txt AS preferred_gender,
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
            aun.user_full_name AS add_user_name,
            p.last_chg_user_id,
            lun.user_full_name AS last_chg_user_name,
            nested.name        AS 'patient_name',
            nested.address     AS 'patient_address',
            nested.phone       AS 'patient_telephone',
            nested.email       AS 'patient_email',
            nested.race        AS 'patient_race',
            nested.entity_id   AS 'patient_entity'
        FROM #filtered_person p
        LEFT JOIN person_code_pivot pcp
            ON pcp.person_uid = p.person_uid

        -- Preferred-gender description, resolved from the pre-built
        -- NBS_STD_GENDER_PARPT lookup rather than a per-row
        -- code_value_general join.
        LEFT JOIN #gender_codes gc
            ON gc.code = NULLIF(p.preferred_gender_cd, '')

        -- Display name of the user who created the record, resolved from
        -- the pre-built Auth_user lookup.
        LEFT JOIN #user_names aun
            ON aun.NEDSS_ENTRY_ID = p.add_user_id

        -- Display name of the user who last modified the record, resolved
        -- from the pre-built Auth_user lookup.
        LEFT JOIN #user_names lun
            ON lun.NEDSS_ENTRY_ID = p.last_chg_user_id

        -- =========================================================
        -- Per-person nested JSON payload. Each sub-select builds one
        -- JSON array (via FOR JSON PATH) for a related child entity
        -- set, pulling from the pre-joined #person_* staging tables,
        -- all combined into a single "nested" row so they can be
        -- selected as individual JSON columns above.
        -- =========================================================
        OUTER APPLY (
            SELECT *
            FROM
            (
                -- ADDRESS: home and birth postal addresses for this patient.
                SELECT
                (
                    SELECT
                        elp_cd                  AS [addr_elp_cd],
                        elp_use_cd               AS [addr_elp_use_cd],
                        pl_uid                   AS [addr_pl_uid],
                        street_addr1,
                        street_addr2,
                        city,
                        zip_cd                   AS [zip],
                        cnty_cd                  AS [cntyCd],
                        state_cd                 AS [state],
                        cntry_cd                 AS [cntryCd],
                        state_desc,
                        county_desc              AS [county],
                        census_tract,
                        within_city_limits_ind,
                        home_country,
                        birth_country
                    FROM #person_address pa
                    WHERE pa.person_uid = p.person_uid
                    ORDER BY pl_uid
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                ) AS address
            ) AS address,
            (
                -- PHONE: active telephone numbers for this patient.
                SELECT
                (
                    SELECT
                        tl_uid          AS [ph_tl_uid],
                        elp_cd          AS [ph_elp_cd],
                        elp_use_cd      AS [ph_elp_use_cd],
                        phone_nbr       AS [telephoneNbr],
                        extension_txt   AS [extensionTxt]
                    FROM #person_tele pt
                    WHERE pt.person_uid = p.person_uid
                      AND pt.phone_nbr IS NOT NULL
                    ORDER BY tl_uid
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                ) AS phone
            ) AS phone,
            (
                -- EMAIL: active email-type ('NET') telephone locators for this patient.
                SELECT
                (
                    SELECT
                        tl_uid          AS [email_tl_uid],
                        elp_cd          AS [email_elp_cd],
                        elp_use_cd      AS [email_elp_use_cd],
                        email_address   AS [emailAddress]
                    FROM #person_tele pt
                    WHERE pt.person_uid = p.person_uid
                      AND pt.elp_cd = 'NET'
                      AND pt.email_address IS NOT NULL
                    ORDER BY tl_uid
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                ) AS email
            ) AS email,
            (
                -- NAME: all person_name records for this patient.
                SELECT
                (
                    SELECT
                        person_uid       AS [pn_person_uid],
                        last_nm_esc      AS [lastNm],
                        last_nm_sndx     AS [lastNmSndx],
                        middle_nm_esc    AS [middleNm],
                        first_nm_esc     AS [firstNm],
                        first_nm_sndx    AS [firstNmSndx],
                        nm_use_cd        AS [nm_use_cd],
                        status_cd        AS [status_name_cd],
                        nm_suffix        AS [nmSuffix],
                        name_suffix,
                        nm_degree        AS [nmDegree],
                        person_name_seq  AS [pn_person_name_seq],
                        last_chg_time    AS [pn_last_chg_time]
                    FROM #person_name pn
                    WHERE pn.person_uid = p.person_uid
                    ORDER BY person_name_seq
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                ) AS name
            ) AS name,
            (
                -- RACE: raw person_race rows plus the pre-calculated race rollup.
                SELECT
                (
                    SELECT
                        person_uid           AS [pr_person_uid],
                        race_cd              AS [raceCd],
                        race_desc_txt        AS [raceDescTxt],
                        race_category_cd     AS [raceCategoryCd],
                        srte_code_desc_txt,
                        srte_parent_is_cd,
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
                    FROM #person_race pr
                    WHERE pr.person_uid = p.person_uid
                    ORDER BY race_cd
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                ) AS race
            ) AS race,
            (
                -- ENTITY_ID: all entity_id records (e.g. SSN/Driver's License/etc) for this patient.
                SELECT
                (
                    SELECT
                        person_uid              AS [entity_uid],
                        type_cd                 AS [typeCd],
                        record_status_cd        AS [recordStatusCd],
                        root_extension_esc      AS [rootExtensionTxt],
                        entity_id_seq           AS [entity_id_seq],
                        assigning_authority_cd  AS [assigning_authority_cd]
                    FROM #person_entity_id pei
                    WHERE pei.person_uid = p.person_uid
                    ORDER BY entity_id_seq
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                ) AS entity_id
            ) AS entity_id
        ) AS nested;

        IF @debug_logging = 1
        BEGIN
            EXEC dbo.sp_add_job_flow_log
                @batch_id          = @batch_id,
                @dataflow_name     = 'Patient PRE-Processing Event',
                @package_name      = 'sp_patient_event',
                @status_type       = 'COMPLETE',
                @step_number       = 0,
                @step_name         = @job_flow_step_name,
                @row_count         = 0,
                @msg_description1  = @job_flow_message;
        END;

    END TRY
    BEGIN CATCH

        -- Roll back any open transaction before logging the error.
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Construct the error message string with all details.
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: '   + CAST(ERROR_NUMBER()   AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: '    + CAST(ERROR_STATE()    AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: '     + CAST(ERROR_LINE()     AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: '  + ERROR_MESSAGE();

        EXEC dbo.sp_add_job_flow_log
            @batch_id          = @batch_id,
            @dataflow_name     = 'Patient PRE-Processing Event',
            @package_name      = 'sp_patient_event',
            @status_type       = 'ERROR',
            @step_number       = 0,
            @step_name         = 'Patient PRE-Processing Event',
            @row_count         = 0,
            @msg_description1  = @job_flow_message,
            @error_description = @FullErrorMessage;

        RETURN @FullErrorMessage;

    END CATCH

END;
GO
