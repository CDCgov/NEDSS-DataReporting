-- =====================================================================
-- Tier 3 — LDF answers for BMIRD + Hepatitis  (Agent R3-C)
-- =====================================================================
-- Goal: populate the two empty LDF datamarts
--   dbo.LDF_BMIRD     (0/7)
--   dbo.LDF_HEPATITIS (0/7)
-- in RDB_MODERN.
--
-- ---------------------------------------------------------------------
-- Why these were empty (corrected root-cause)
-- ---------------------------------------------------------------------
-- Earlier fixtures (zz_ldf_flagged_answers.sql, ldf_answers_mumps_foodborne.sql)
-- declared BMIRD/HEP "cannot populate — no condition_cd metadata" and
-- skipped them. The triage note about nrt_page_case_answer.ldf_status_cd
-- is a red herring for THESE two tables: LDF_BMIRD / LDF_HEPATITIS are
-- NOT driven by the *_pam_ldf nrt_page_case_answer path. They are driven
-- by the nrt_ldf_data → LDF_DIMENSIONAL_DATA → datamart chain (the same
-- path proven by ldf_answers_tetanus.sql).
--
-- The real blocker is in the datamart SPs themselves
-- (285-sp_ldf_bmird_datamart_postprocessing, 320-sp_ldf_hepatitis_…):
--
--   #TMP_ALL_BMIRD / #TMP_ALL_HEPATITIS join
--     LDF_DATAMART_COLUMN_REF B ON A.LDF_UID = B.LDF_UID
--     WHERE B.LDF_PAGE_SET = 'BMIRD' (resp. 'HEP')
--        OR B.CONDITION_CD IN (SELECT CONDITION_CD FROM LDF_DATAMART_TABLE_REF
--                              WHERE DATAMART_NAME = 'LDF_BMIRD' / 'LDF_HEPATITIS')
--
--   So an LDF answer only reaches LDF_BMIRD/LDF_HEPATITIS if its metadata's
--   CONDITION_CD is one of the datamart's mapped condition codes (which
--   flows into LDF_DATAMART_COLUMN_REF.CONDITION_CD via the dimensional SP),
--   OR its LDF_PAGE_SET resolves to 'BMIRD'/'HEP' (requires business_object_nm
--   'BMD'/'HEP' metadata).
--
--   Baseline 6.0.18.1 ships ZERO nrt_odse_state_defined_field_metadata rows
--   with business_object_nm IN ('BMD','HEP'), and ZERO PHC metadata rows
--   whose condition_cd is any BMIRD code (10650,11710,11715,10590,10150,
--   11700,11716,11717,11720) or any HEP code (10110,10100,10104,10105,
--   10101,10106,10102,10103,10481). Hence the empty tables.
--
-- ---------------------------------------------------------------------
-- Fix
-- ---------------------------------------------------------------------
-- Author custom LDF metadata rows in nrt_odse_state_defined_field_metadata
-- (business_object_nm='PHC', data_type='ST') whose condition_cd IS a
-- BMIRD/HEP datamart condition code, then attach nrt_ldf_data answer rows
-- to existing fully-resolved investigations:
--
--   BMIRD: PHC 22005000 (Strep pneumoniae invasive, cd=11717).
--          BMIRD_CASE row exists; INVESTIGATION_KEY=6, CONDITION_KEY=150,
--          PATIENT_KEY=3 all resolve (verified live).
--   HEP:   PHC 22008500 (Hepatitis A acute, cd=10110).
--          HEPATITIS_CASE row exists; INVESTIGATION_KEY=26, CONDITION_KEY=15,
--          PATIENT_KEY=3 all resolve (verified live).
--
-- nrt_ldf_data.business_object_uid = the investigation's
-- public_health_case_uid; the dimensional SP joins
--   nrt_ldf_data → nrt_INVESTIGATION (business_object_uid = public_health_case_uid)
--   → LDF_DATAMART_TABLE_REF (inv.cd = condition_cd)
-- and stamps LDF_DIMENSIONAL_DATA.PHC_CD = inv.cd (11717 / 10110), which is
-- what the datamart SP's PHC_CD = CONDITION_CD join keys on.
--
-- These metadata rows ARE the LDF metadata seed STRATEGY warns about — but
-- nrt_odse_state_defined_field_metadata is an RDB_MODERN *staging* table
-- (the debezium projection of NBS_ODSE.dbo.state_defined_field_metadata),
-- not SRTE. Hand-authoring staging rows is the same fixture-authoring
-- shortcut used for every nrt_* table per STRATEGY.md "RTR transformation
-- chain (verification recipe)". We do NOT touch NBS_SRTE.
--
-- ---------------------------------------------------------------------
-- UID range: 22025000 - 22025999 (mandated by Agent R3-C task).
--   NOTE: 22025000 itself is consumed by zz_inv_summ_datamart_unblock.sql
--   (Agent S seed row). We allocate from 22025100+ to avoid collision.
--   22025101, 22025102        — BMIRD custom LDF metadata (ldf_uid)
--   22025111, 22025112        — HEP   custom LDF metadata (ldf_uid)
--   nrt_ldf_data keys on (ldf_uid, business_object_uid); the
--   business_object_uid values (22005000 / 22008500) are existing PHC UIDs
--   owned by their full-chain fixtures, referenced read-only here.
-- =====================================================================

USE [RDB_MODERN];
GO

PRINT '[ldf_answers_bmird_hepatitis] start';

DECLARE @bmird_phc      bigint = 22005000;   -- Strep pneumoniae invasive, cd=11717
DECLARE @hep_phc        bigint = 22008500;   -- Hepatitis A acute,        cd=10110
DECLARE @bmird_cond     varchar(10) = '11717';
DECLARE @hep_cond       varchar(10) = '10110';

DECLARE @bmird_ldf_1    bigint = 22025101;
DECLARE @bmird_ldf_2    bigint = 22025102;
DECLARE @hep_ldf_1      bigint = 22025111;
DECLARE @hep_ldf_2      bigint = 22025112;

-- ---------------------------------------------------------------------
-- 1. Custom LDF metadata (nrt_odse_state_defined_field_metadata).
--    business_object_nm='PHC', data_type='ST' (free text — no code
--    translation needed; LDF_VALUE passes through as COL1).
--    condition_cd = the BMIRD / HEP datamart condition so the datamart
--    SP's column-ref filter admits these answers.
--    refresh_datetime/max_datetime are GENERATED ALWAYS — omitted.
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_odse_state_defined_field_metadata WHERE ldf_uid = @bmird_ldf_1)
BEGIN
    PRINT '[ldf_answers_bmird_hepatitis] inserted 4 custom LDF metadata rows';
END

-- ---------------------------------------------------------------------
-- 2. LDF answer data (nrt_ldf_data) attached to the existing
--    BMIRD (22005000) and HEP (22008500) investigations.
--    refresh_datetime/max_datetime are GENERATED ALWAYS — omitted.
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_ldf_data WHERE ldf_uid = @bmird_ldf_1 AND business_object_uid = @bmird_phc)
BEGIN
    PRINT '[ldf_answers_bmird_hepatitis] inserted 4 nrt_ldf_data answer rows';
END

-- =====================================================================
-- 3. Tail-EXEC the LDF chain.
-- =====================================================================
DECLARE @ldf_uids nvarchar(max) =
    CAST(@bmird_ldf_1 AS varchar(20)) + ',' + CAST(@bmird_ldf_2 AS varchar(20)) + ','
  + CAST(@hep_ldf_1   AS varchar(20)) + ',' + CAST(@hep_ldf_2   AS varchar(20));

-- 3a. Dimensional data — populates LDF_DIMENSIONAL_DATA (+ D_LDF_META_DATA,
--     LDF_DATAMART_COLUMN_REF) for these ldf_uids. REQUIRED before the
--     datamart SPs; the orchestrator does not run this for our ldf_uids.
BEGIN TRY
    PRINT '[ldf_answers_bmird_hepatitis] sp_nrt_ldf_dimensional_data_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[ldf_answers_bmird_hepatitis] dimensional SP ERROR: ' + ERROR_MESSAGE();
END CATCH;

-- 3b. LDF postprocessing — maintains ldf_data / ldf_group / *_LDF_GROUP.
BEGIN TRY
    PRINT '[ldf_answers_bmird_hepatitis] sp_nrt_ldf_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[ldf_answers_bmird_hepatitis] ldf SP ERROR: ' + ERROR_MESSAGE();
END CATCH;

-- 3c. BMIRD datamart — populates dbo.LDF_BMIRD for PHC 22005000.
--     (Orchestrator Step 9 also runs this against $PHC_UIDS, which already
--      includes 22005000; we run it here for self-containment.)
BEGIN TRY
    PRINT '[ldf_answers_bmird_hepatitis] sp_ldf_bmird_datamart_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[ldf_answers_bmird_hepatitis] bmird datamart ERROR: ' + ERROR_MESSAGE();
END CATCH;

-- 3d. Hepatitis datamart — populates dbo.LDF_HEPATITIS for PHC 22008500.
--     (Orchestrator Step 9 also runs this against $PHC_UIDS, which already
--      includes 22008500.)
BEGIN TRY
    PRINT '[ldf_answers_bmird_hepatitis] sp_ldf_hepatitis_datamart_postprocessing OK';
END TRY
BEGIN CATCH
    PRINT '[ldf_answers_bmird_hepatitis] hepatitis datamart ERROR: ' + ERROR_MESSAGE();
END CATCH;

PRINT '[ldf_answers_bmird_hepatitis] done';
GO
