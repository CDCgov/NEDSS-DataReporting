-- =============================================================================
-- Procedure:   dbo.sp_patient_race_event
-- Purpose:     Derives a patient-level calculated race value (Unknown,
--              Multi-Race, or a single named race) and a detailed
--              breakdown of up to 4 sub-races for each of the 5 OMB race
--              categories, for a batch of patients. Output is one row per
--              patient, ready for load into the Patient dimension table.
--
-- Parameters:
--   @user_id_list  nvarchar(max) - Comma-delimited list of PERSON_UID
--                                  values to process for this batch.
--   @batch_id      bigint        - ETL batch identifier, used for error
--                                  logging only.
--
-- Returns:
--   Result set: one row per patient with RACE_CALCULATED, RACE_ALL,
--   RACE_CALC_DETAILS, and per-category (NAT_HI, ASIAN, AMER_IND, BLACK,
--   WHITE) breakdown columns (_1/_2/_3, _GT3_IND, _ALL).
--
--   On error: no result set is returned. The error is logged to
--   dbo.job_flow_log, and RETURN is called with the error message. Note
--   that T-SQL coerces the RETURN value to an int, so callers should not
--   rely on the literal text of the return code - dbo.job_flow_log is
--   the authoritative error record.
--
-- Dependencies:
--   NBS_ODSE.dbo.PERSON_RACE, NBS_SRTE.dbo.RACE_CODE, dbo.job_flow_log
--
-- Concurrency:
--   Reads use WITH (NOLOCK). Source tables are not modified concurrently
--   during the ETL window, so dirty reads are acceptable here.
--
-- Idempotency:
--   Proc is dropped and recreated on each deployment so this script can
--   be re-run safely in CI/CD pipelines.
-- =============================================================================

IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_patient_race_event]') 
    AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_patient_race_event]
END
GO 

CREATE PROCEDURE dbo.sp_patient_race_event @user_id_list nvarchar(max), @batch_id bigint
AS
BEGIN

    BEGIN TRY

        -- -----------------------------------------------------------------
        -- Pull all race rows for the requested patients, resolving the
        -- description text for the reported RACE_CD and the parent-level
        -- (ROOT vs. category) classification for RACE_CATEGORY_CD.
        -- -----------------------------------------------------------------
        SELECT pr.PERSON_UID AS 'PATIENT_UID',
               RACE_CD,
               RACE_CODE.CODE_DESC_TXT,
               RACE_CATEGORY_CD,
               RACE_CODE.PARENT_IS_CD
        into #TMP_S_PERSON_RACE
        from NBS_ODSE.dbo.PERSON_RACE pr with (nolock)
                 LEFT OUTER JOIN NBS_SRTE.dbo.RACE_CODE with (nolock) ON pr.RACE_CD = RACE_CODE.CODE
                 LEFT OUTER JOIN NBS_SRTE.dbo.RACE_CODE RT with (nolock) ON pr.RACE_CATEGORY_CD = RT.CODE
        where pr.person_uid in (SELECT value FROM STRING_SPLIT(@user_id_list, ','))
        ORDER BY PATIENT_UID, CODE_DESC_TXT;

        CREATE CLUSTERED INDEX IX_TMP_S_PERSON_RACE_UID
            ON #TMP_S_PERSON_RACE (PATIENT_UID);

        -- Rows whose category is a top-level ("ROOT") OMB race category;
        -- basis for the patient-level RACE_CALCULATED / RACE_ALL fields.
        SELECT *
        into #TMP_PERSON_ROOT_RACE
        FROM #TMP_S_PERSON_RACE
        WHERE PARENT_IS_CD = 'ROOT'
        ;

        CREATE CLUSTERED INDEX IX_TMP_PERSON_ROOT_RACE_UID
            ON #TMP_PERSON_ROOT_RACE (PATIENT_UID);

        -- -----------------------------------------------------------------
        -- Detailed sub-race rows rolling up under each of the 5 OMB race
        -- categories, tagged with RACE_CATEGORY_TAG so all 5 categories
        -- can be processed together below. RACE_CD <> RACE_CATEGORY_CD
        -- excludes the category's own summary row.
        -- -----------------------------------------------------------------
        IF OBJECT_ID('tempdb..#TMP_S_PERSON_RACE_CAT', 'U') IS NOT NULL
            drop table #TMP_S_PERSON_RACE_CAT;

        SELECT *,
               CASE RACE_CATEGORY_CD
                   WHEN '1002-5' THEN 'AMER_IND'  -- American Indian / Alaska Native
                   WHEN '2054-5' THEN 'BLACK'     -- Black or African American
                   WHEN '2106-3' THEN 'WHITE'     -- White
                   WHEN '2028-9' THEN 'ASIAN'     -- Asian
                   WHEN '2076-8' THEN 'NAT_HI'    -- Native Hawaiian / Other Pacific Islander
                   END AS RACE_CATEGORY_TAG
        into #TMP_S_PERSON_RACE_CAT
        FROM #TMP_S_PERSON_RACE
        WHERE RACE_CATEGORY_CD IN ('1002-5', '2054-5', '2106-3', '2028-9', '2076-8')
          AND RACE_CD <> RACE_CATEGORY_CD
        ;

        CREATE CLUSTERED INDEX IX_TMP_PERSON_RACE_CAT_UID_TAG
            ON #TMP_S_PERSON_RACE_CAT (PATIENT_UID, RACE_CATEGORY_TAG);


        -- ===================================================================
        -- Patient-level calculated race
        -- ===================================================================
        IF OBJECT_ID('tempdb..#TMP_S_PERSON_ROOT_RACE', 'U') IS NOT NULL
            drop table #TMP_S_PERSON_ROOT_RACE;

        select *
        into #TMP_S_PERSON_ROOT_RACE
        from #TMP_PERSON_ROOT_RACE;

        CREATE CLUSTERED INDEX IX_TMP_S_PERSON_ROOT_RACE_UID
            ON #TMP_S_PERSON_ROOT_RACE (PATIENT_UID);

        ALTER TABLE #TMP_S_PERSON_ROOT_RACE
            ADD PATIENT_RACE_CALCULATED VARCHAR(2000),
                PATIENT_RACE_CALC_DETAILS varchar(4000),
                PATIENT_RACE_ALL varchar(4000);

        -- PATIENT_RACE_ALL: pipe-delimited list of all root race
        -- descriptions for the patient (includes Unknown/Not Asked/etc.).
        -- PATIENT_RACE_CALC_DETAILS: same, excluding "non-answer" codes
        -- (PHC1175, NASK, U) so it reflects only actual reported races.
        ;WITH agg AS (
            SELECT patient_uid,
                   STRING_AGG(CAST(code_desc_txt AS varchar(2000)), ' | ')
                       WITHIN GROUP (ORDER BY code_desc_txt) AS race_all,
                   STRING_AGG(
                       CASE WHEN race_category_cd NOT IN ('PHC1175', 'NASK', 'U')
                            THEN CAST(code_desc_txt AS varchar(2000)) END,
                       ' | '
                   ) WITHIN GROUP (ORDER BY code_desc_txt) AS race_calc_details
            FROM #TMP_S_PERSON_ROOT_RACE
            WHERE code_desc_txt IS NOT NULL
            GROUP BY patient_uid
        )
        UPDATE sppr
        SET sppr.PATIENT_RACE_ALL = rtrim(ltrim(a.race_all)),
            sppr.PATIENT_RACE_CALC_DETAILS = rtrim(ltrim(a.race_calc_details))
        FROM #TMP_S_PERSON_ROOT_RACE sppr
                 JOIN agg a ON sppr.PATIENT_UID = a.patient_uid;

        -- Parity with legacy SAS logic (PatientDimension.sas): if a
        -- patient has no qualifying (non-"non-answer") race rows,
        -- CALC_DETAILS is forced to the literal 'Unknown' instead of
        -- being left NULL/blank.
        UPDATE sppr
        SET sppr.PATIENT_RACE_CALC_DETAILS = 'Unknown'
        FROM #TMP_S_PERSON_ROOT_RACE sppr
        WHERE NULLIF(LTRIM(RTRIM(sppr.PATIENT_RACE_CALC_DETAILS)), '') IS NULL;

        -- Single-value rollup: no details -> 'Unknown'; more than one
        -- race listed (delimiter present) -> 'Multi-Race'; exactly one
        -- race listed -> that race's description text.
        update #TMP_S_PERSON_ROOT_RACE
        set PATIENT_RACE_CALCULATED =
                case
                    when len(PATIENT_RACE_CALC_DETAILS) < 1 OR PATIENT_RACE_CALC_DETAILS is null then 'Unknown'
                    when CHARINDEX('|', PATIENT_RACE_CALC_DETAILS) > 0 then 'Multi-Race'
                    when CHARINDEX('|', PATIENT_RACE_CALC_DETAILS) = 0 then PATIENT_RACE_CALC_DETAILS
                    end;


        -- ===================================================================
        -- Per-category sub-race breakdown (all 5 OMB categories in one pass,
        -- partitioned by PATIENT_UID + RACE_CATEGORY_TAG)
        -- ===================================================================
        ALTER TABLE #TMP_S_PERSON_RACE_CAT
            ADD
                RACE_ALL varchar(2000),
                RACE_1 varchar(50),
                RACE_2 varchar(50),
                RACE_3 varchar(50),
                RACE_4 varchar(50),
                RACE_GT3_IND varchar(10);

        -- Rank each patient/category's distinct sub-race rows (tie-break
        -- on PATIENT_UID for run-to-run stability) and pivot ranks 1-4
        -- into the RACE_1..RACE_4 slot columns.
        ;WITH ranked_CAT AS (
            SELECT PATIENT_UID AS person_uid,
                   RACE_CATEGORY_TAG AS category_tag,
                   CODE_DESC_TXT AS code_desc_txt,
                   row_number() OVER (
                       PARTITION BY PATIENT_UID, RACE_CATEGORY_TAG
                       ORDER BY PATIENT_UID) AS rn
            FROM #TMP_S_PERSON_RACE_CAT
        ),
        pivoted_CAT AS (
            SELECT person_uid,
                   category_tag,
                   MAX(CASE WHEN rn = 1 THEN code_desc_txt END) AS r1,
                   MAX(CASE WHEN rn = 2 THEN code_desc_txt END) AS r2,
                   MAX(CASE WHEN rn = 3 THEN code_desc_txt END) AS r3,
                   MAX(CASE WHEN rn = 4 THEN code_desc_txt END) AS r4
            FROM ranked_CAT
            GROUP BY person_uid, category_tag
        )
        UPDATE prc
        SET prc.RACE_1 = pv.r1,
            prc.RACE_2 = pv.r2,
            prc.RACE_3 = pv.r3,
            prc.RACE_4 = pv.r4
        FROM #TMP_S_PERSON_RACE_CAT prc
                 JOIN pivoted_CAT pv
                      ON pv.person_uid = prc.PATIENT_UID
                     AND pv.category_tag = prc.RACE_CATEGORY_TAG;


        -- Flag whether the patient has more than 3 distinct sub-races
        -- reported for this category (i.e. a 4th slot was populated).
        update #TMP_S_PERSON_RACE_CAT
        set RACE_GT3_IND =
                case
                    when RACE_4 is not null then 'TRUE'
                    when RACE_4 is null then 'FALSE'
                    end;


        -- Pipe-delimited list of every distinct sub-race description for
        -- the (patient, category).
        UPDATE prc
        SET prc.RACE_ALL = agg.desc_list
        FROM #TMP_S_PERSON_RACE_CAT prc
                 JOIN (
                     SELECT patient_uid, race_category_tag, STRING_AGG(code_desc_txt, ' | ') AS desc_list
                     FROM (SELECT DISTINCT patient_uid, race_category_tag, code_desc_txt
                           FROM #TMP_S_PERSON_RACE_CAT) d
                     GROUP BY patient_uid, race_category_tag
                 ) agg
                      ON agg.patient_uid = prc.PATIENT_UID
                     AND agg.race_category_tag = prc.RACE_CATEGORY_TAG;


        -- ===================================================================
        -- Assemble final wide output: one row per patient, seeded with
        -- typed NULLs for every category breakdown column. Only slots
        -- 1-3 are surfaced per category in the output shape (slot 4,
        -- computed above, is used only to derive RACE_GT3_IND).
        -- ===================================================================
        IF OBJECT_ID('tempdb..#TMP_S_PERSON_RACE_OUT', 'U') IS NOT NULL
            DROP TABLE #TMP_S_PERSON_RACE_OUT ;

        -- #TMP_S_PERSON_ROOT_RACE has one row per (patient, root
        -- category); RACE_CALCULATED/_ALL/_CALC_DETAILS are patient-level
        -- values duplicated across those rows, so ROW_NUMBER() is used to
        -- pick a single representative row per patient.
        ;WITH one_per_patient AS (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY patient_uid ORDER BY patient_uid) AS rn
            FROM #tmp_s_person_root_race
        )
        select patient_race_calculated     as race_calculated
             , patient_race_calc_details   as race_calc_details
             , patient_race_all            as race_all
             , cast(null as varchar(50))   as race_nat_hi_1
             , cast(null as varchar(50))   as race_nat_hi_2
             , cast(null as varchar(50))   as race_nat_hi_3
             , cast(null as varchar(10))   as race_nat_hi_gt3_ind
             , cast(null as varchar(2000)) as race_nat_hi_all
             , cast(null as varchar(50))   as race_asian_1
             , cast(null as varchar(50))   as race_asian_2
             , cast(null as varchar(2000)) as race_asian_all
             , cast(null as varchar(50))   as race_asian_3
             , cast(null as varchar(10))   as race_asian_gt3_ind
             , cast(null as varchar(50))   as race_amer_ind_1
             , cast(null as varchar(50))   as race_amer_ind_2
             , cast(null as varchar(50))   as race_amer_ind_3
             , cast(null as varchar(10))   as race_amer_ind_gt3_ind
             , cast(null as varchar(2000)) as race_amer_ind_all
             , cast(null as varchar(50))   as race_black_1
             , cast(null as varchar(50))   as race_black_2
             , cast(null as varchar(50))   as race_black_3
             , cast(null as varchar(10))   as race_black_gt3_ind
             , cast(null as varchar(2000)) as race_black_all
             , cast(null as varchar(50))   as race_white_1
             , cast(null as varchar(50))   as race_white_2
             , cast(null as varchar(50))   as race_white_3
             , cast(null as varchar(10))   as race_white_gt3_ind
             , cast(null as varchar(2000)) as race_white_all
             , patient_uid                 as patient_uid_race_out
        into #tmp_s_person_race_out
        from one_per_patient
        where rn = 1;

        CREATE CLUSTERED INDEX IX_TMP_S_PERSON_RACE_OUT_UID
            ON #tmp_s_person_race_out (patient_uid_race_out);


        -- Fill in every category's breakdown columns in a single UPDATE,
        -- pivoting #TMP_S_PERSON_RACE_CAT from (patient, category) rows
        -- into one row per patient with all 5 categories as columns. A
        -- patient with no rows for a given category gets NULL from
        -- MAX(CASE...) and the seeded NULL above is left unchanged.
        ;WITH cat_summary AS (
            SELECT
                patient_uid,
                MAX(CASE WHEN race_category_tag = 'AMER_IND' THEN race_1 END)       AS amer_ind_1,
                MAX(CASE WHEN race_category_tag = 'AMER_IND' THEN race_2 END)       AS amer_ind_2,
                MAX(CASE WHEN race_category_tag = 'AMER_IND' THEN race_3 END)       AS amer_ind_3,
                MAX(CASE WHEN race_category_tag = 'AMER_IND' THEN race_gt3_ind END) AS amer_ind_gt3_ind,
                MAX(CASE WHEN race_category_tag = 'AMER_IND' THEN race_all END)     AS amer_ind_all,

                MAX(CASE WHEN race_category_tag = 'NAT_HI' THEN race_1 END)         AS nat_hi_1,
                MAX(CASE WHEN race_category_tag = 'NAT_HI' THEN race_2 END)         AS nat_hi_2,
                MAX(CASE WHEN race_category_tag = 'NAT_HI' THEN race_3 END)         AS nat_hi_3,
                MAX(CASE WHEN race_category_tag = 'NAT_HI' THEN race_gt3_ind END)   AS nat_hi_gt3_ind,
                MAX(CASE WHEN race_category_tag = 'NAT_HI' THEN race_all END)       AS nat_hi_all,

                MAX(CASE WHEN race_category_tag = 'BLACK' THEN race_1 END)          AS black_1,
                MAX(CASE WHEN race_category_tag = 'BLACK' THEN race_2 END)          AS black_2,
                MAX(CASE WHEN race_category_tag = 'BLACK' THEN race_3 END)          AS black_3,
                MAX(CASE WHEN race_category_tag = 'BLACK' THEN race_gt3_ind END)    AS black_gt3_ind,
                MAX(CASE WHEN race_category_tag = 'BLACK' THEN race_all END)        AS black_all,

                MAX(CASE WHEN race_category_tag = 'WHITE' THEN race_1 END)          AS white_1,
                MAX(CASE WHEN race_category_tag = 'WHITE' THEN race_2 END)          AS white_2,
                MAX(CASE WHEN race_category_tag = 'WHITE' THEN race_3 END)          AS white_3,
                MAX(CASE WHEN race_category_tag = 'WHITE' THEN race_gt3_ind END)    AS white_gt3_ind,
                MAX(CASE WHEN race_category_tag = 'WHITE' THEN race_all END)        AS white_all,

                MAX(CASE WHEN race_category_tag = 'ASIAN' THEN race_1 END)          AS asian_1,
                MAX(CASE WHEN race_category_tag = 'ASIAN' THEN race_2 END)          AS asian_2,
                MAX(CASE WHEN race_category_tag = 'ASIAN' THEN race_3 END)          AS asian_3,
                MAX(CASE WHEN race_category_tag = 'ASIAN' THEN race_gt3_ind END)    AS asian_gt3_ind,
                MAX(CASE WHEN race_category_tag = 'ASIAN' THEN race_all END)        AS asian_all
            FROM #TMP_S_PERSON_RACE_CAT
            GROUP BY patient_uid
        )
        UPDATE spr
        SET spr.race_amer_ind_1       = cs.amer_ind_1,
            spr.race_amer_ind_2       = cs.amer_ind_2,
            spr.race_amer_ind_3       = cs.amer_ind_3,
            spr.race_amer_ind_gt3_ind = cs.amer_ind_gt3_ind,
            spr.race_amer_ind_all     = left(rtrim(ltrim(cs.amer_ind_all)), 2000),

            spr.race_nat_hi_1         = cs.nat_hi_1,
            spr.race_nat_hi_2         = cs.nat_hi_2,
            spr.race_nat_hi_3         = cs.nat_hi_3,
            spr.race_nat_hi_gt3_ind   = cs.nat_hi_gt3_ind,
            spr.race_nat_hi_all       = left(rtrim(ltrim(cs.nat_hi_all)), 2000),

            spr.race_black_1          = cs.black_1,
            spr.race_black_2          = cs.black_2,
            spr.race_black_3          = cs.black_3,
            spr.race_black_gt3_ind    = cs.black_gt3_ind,
            spr.race_black_all        = left(rtrim(ltrim(cs.black_all)), 2000),

            spr.race_white_1          = cs.white_1,
            spr.race_white_2          = cs.white_2,
            spr.race_white_3          = cs.white_3,
            spr.race_white_gt3_ind    = cs.white_gt3_ind,
            spr.race_white_all        = left(rtrim(ltrim(cs.white_all)), 2000),

            spr.race_asian_1          = cs.asian_1,
            spr.race_asian_2          = cs.asian_2,
            spr.race_asian_3          = cs.asian_3,
            spr.race_asian_gt3_ind    = cs.asian_gt3_ind,
            spr.race_asian_all        = left(rtrim(ltrim(cs.asian_all)), 2000)
        FROM #tmp_s_person_race_out spr
                 JOIN cat_summary cs ON spr.patient_uid_race_out = cs.patient_uid;


        -- ===================================================================
        -- Final result set. LEFT(...) is applied defensively on every
        -- varchar output column to enforce the destination dimension
        -- table's column widths and avoid truncation errors on load.
        -- ===================================================================
        select left(race_calculated,50) as race_calculated,
               left(race_calc_details,4000) as race_calc_details,
               left(race_all,4000) as race_all,
               left(race_nat_hi_1,50) as race_nat_hi_1,
               left(race_nat_hi_2,50) as race_nat_hi_2,
               left(race_nat_hi_3,50) as race_nat_hi_3,
               left(race_nat_hi_gt3_ind,50) as race_nat_hi_gt3_ind,
               left(race_nat_hi_all,2000) as race_nat_hi_all,
               left(race_asian_1,50) as race_asian_1,
               left(race_asian_2,50) as race_asian_2,
               left(race_asian_3,50) as race_asian_3,
               left(race_asian_gt3_ind,50) as race_asian_gt3_ind,
               left(race_asian_all,2000) as race_asian_all,
               left(race_amer_ind_1,50) as race_amer_ind_1,
               left(race_amer_ind_2,50) as race_amer_ind_2,
               left(race_amer_ind_3,50) as race_amer_ind_3,
               left(race_amer_ind_gt3_ind,50) as race_amer_ind_gt3_ind,
               left(race_amer_ind_all,2000) as race_amer_ind_all,
               left(race_black_1,50) as race_black_1,
               left(race_black_2,50) as race_black_2,
               left(race_black_3,50) as race_black_3,
               left(race_black_gt3_ind,50) as race_black_gt3_ind,
               left(race_black_all,2000) as race_black_all,
               left(race_white_1,50) as race_white_1,
               left(race_white_2,50) as race_white_2,
               left(race_white_3,50) as race_white_3,
               left(race_white_gt3_ind,50) as race_white_gt3_ind,
               left(race_white_all,2000) as race_white_all,
               patient_uid_race_out
        from #tmp_s_person_race_out;


    end try

    BEGIN CATCH

        -- On any error: roll back if a transaction happens to be open
        -- (defensive - this proc does not open its own transaction), log
        -- the failure to dbo.job_flow_log with enough context for
        -- pipeline monitoring/troubleshooting, and return the error
        -- message to the caller.
        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        INSERT INTO [dbo].[job_flow_log]
        (
          batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[Msg_Description1]
        ,[Error_Description]
        )
        VALUES (
                 @batch_id
               ,'Patient PRE-Processing Event:Person Race Module'
               ,'sp_patient_race_event'
               ,'ERROR'
               ,0
               ,'Patient PRE-Processing Event:Person Race'
               ,0
               ,LEFT(@user_id_list,199)
                ,@ErrorMessage
               );
        return @ErrorMessage;

    END CATCH

end;
