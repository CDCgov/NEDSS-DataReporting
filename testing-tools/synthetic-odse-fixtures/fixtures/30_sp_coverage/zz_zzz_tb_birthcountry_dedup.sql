-- =====================================================================
-- zz_zzz_tb_birthcountry_dedup.sql
--
-- The legacy TB PAM datamart (TB_Staging.sas) transposes the RVCT answers with
-- PROC TRANSPOSE BY TB_PAM_UID, ID=datamart_column_nm. The *_BIRTH_COUNTRY
-- columns are single-value and resolve through the COUNTRY_CODE path (codeset
-- group 77777), which -- unlike the main coded path -- does NOT collapse
-- duplicate answers. Several synthetic TB investigations carry TWO answers for
-- each birth-country question: the numeric ISO code '840' (which COUNTRY_CODE
-- resolves to "United States") plus an invalid 'USA' duplicate left by an
-- enrichment fixture. PROC TRANSPOSE then fails with
--   ERROR: The ID value "PATIENT_BIRTH_COUNTRY" occurs twice in the same BY group
-- (also PRIMARY_GUARD_1/2_BIRTH_COUNTRY), which empties the BY group and leaves
-- 7 errors in MasterEtl2.log.
--
-- Keep ONE answer per (investigation, birth-country question): prefer the value
-- that COUNTRY_CODE can resolve (the numeric ISO code), break ties by seq_nbr,
-- and delete the rest. Synthetic-only (act_uid >= 20000000). Idempotent.
-- LAST-SORTING (zz_zzz_) so it runs after every TB fixture that authors answers.
-- =====================================================================

USE [NBS_ODSE];
GO

;WITH bc AS (
    SELECT ca.nbs_case_answer_uid,
           ROW_NUMBER() OVER (
               PARTITION BY ca.act_uid, ca.nbs_question_uid
               ORDER BY CASE WHEN cc.code IS NOT NULL THEN 0 ELSE 1 END, ca.seq_nbr
           ) AS rk
    FROM dbo.nbs_case_answer ca
    JOIN dbo.nbs_question q ON q.nbs_question_uid = ca.nbs_question_uid
    LEFT JOIN NBS_SRTE.dbo.country_code cc ON cc.code = ca.answer_txt
    WHERE ca.act_uid >= 20000000
      AND q.datamart_column_nm LIKE '%BIRTH_COUNTRY%'
)
DELETE FROM dbo.nbs_case_answer
 WHERE nbs_case_answer_uid IN (SELECT nbs_case_answer_uid FROM bc WHERE rk > 1);
GO

-- CDC re-emit the affected TB investigations so the page-builder D_TB_PAM chain
-- rebuilds from the deduped answers in RDB_MODERN as well.
UPDATE dbo.public_health_case
   SET last_chg_time = SYSDATETIME()
 WHERE public_health_case_uid >= 20000000
   AND public_health_case_uid IN (
        SELECT DISTINCT ca.act_uid
        FROM dbo.nbs_case_answer ca
        JOIN dbo.nbs_question q ON q.nbs_question_uid = ca.nbs_question_uid
        WHERE q.datamart_column_nm LIKE '%BIRTH_COUNTRY%');
GO
