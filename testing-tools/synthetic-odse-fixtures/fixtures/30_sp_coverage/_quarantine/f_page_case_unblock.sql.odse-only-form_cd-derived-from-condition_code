-- =====================================================================
-- Tier 3 — F_PAGE_CASE unblock
-- =====================================================================
-- Goal: populate dbo.F_PAGE_CASE (and the cascade-dependent
-- HEPATITIS_DATAMART, F_STD_PAGE_CASE) by ensuring at least one
-- nrt_investigation row passes the SP's filter at
-- 012-sp_f_page_case_postprocessing-001.sql:85-95:
--
--   SELECT ... FROM dbo.nrt_investigation
--   WHERE INVESTIGATION_FORM_CD NOT IN (legacy form codes)
--     AND CASE_MANAGEMENT_UID is null;
--
-- Foundation's nrt_investigation row (CASE_UID 20000100) was authored
-- with INVESTIGATION_FORM_CD=NULL and CASE_MANAGEMENT_UID=NULL by
-- Investigation Tier 1's deliberate sparse-foundation design.
-- v2's nrt_investigation row has both columns set (form_cd='PG_Hepatitis_A_
-- Acute_Investigation' to exercise the modern-form path; case_management
-- exercises the case-management join).
--
-- Neither passes the F_PAGE_CASE filter:
-- - Foundation: NULL form_cd matches "NOT IN (...)" as UNKNOWN, treated
--   as false in WHERE — filtered out.
-- - v2: form_cd OK but case_management_uid IS NOT NULL — filtered out.
--
-- Tier 3 fix: UPDATE foundation's nrt_investigation row to set
-- INVESTIGATION_FORM_CD to the modern Hep A form. This is a staging-
-- table UPDATE consistent with how Tier 2 lab_inv/morb_inv updated
-- nrt_observation.associated_phc_uids — the postprocessing SP reads
-- the staging column directly, so the canonical fixture-authoring
-- pattern is to mirror what CDC would have produced.
--
-- After this UPDATE, foundation Inv passes both filters (modern
-- form_cd, NULL case_management_uid) and F_PAGE_CASE picks it up.
-- HEPATITIS_DATAMART then cascade-populates from F_PAGE_CASE +
-- INVESTIGATION + condition='10110' (Hep A acute).
--
-- This UPDATE is idempotent: running the fixture twice leaves the
-- column at the same value.
--
-- The merge orchestrator (scripts/merge_and_verify.sh) applies this
-- file at Step 8 (Tier 3 fixtures), AFTER Tier 2 chains have run and
-- BEFORE Step 9 (datamart SPs). The datamart SPs read from
-- nrt_investigation, so the UPDATE must happen before their invocation.
-- =====================================================================

USE [RDB_MODERN];

UPDATE dbo.nrt_investigation
   SET INVESTIGATION_FORM_CD = N'PG_Hepatitis_A_Acute_Investigation'
 WHERE public_health_case_uid = 20000100
   AND INVESTIGATION_FORM_CD IS NULL;
