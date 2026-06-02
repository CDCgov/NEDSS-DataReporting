-- =====================================================================
-- Tier 3 — SR100 datamart (SR100 summary-report datamart)
-- =====================================================================
-- Authored 2026-06-02 (loop agent R3-B).
--
-- Goal: populate dbo.SR100 (RDB_MODERN), currently 0/20 columns.
--
-- SR100 is a summary-report datamart written by
--   sp_sr100_datamart_postprocessing (155-...-001.sql).
-- Its #temp_sr100 source SELECT (lines 38-86) has these INNER JOINs that
-- ALL must resolve for a PHC to surface a row:
--
--   dbo.SUMMARY_REPORT_CASE  SRC   (the summary-report fact)
--   dbo.INVESTIGATION        I     ON src.INVESTIGATION_KEY = I.INVESTIGATION_KEY
--   dbo.condition            c     ON c.CONDITION_KEY       = src.CONDITION_KEY
--   dbo.nrt_srte_state_county_code_value sccv ON SRC.county_cd = sccv.code
--   dbo.EVENT_METRIC         em    ON em.local_id           = I.inv_local_id
--
-- So SR100 sits downstream of the SUMMARY_REPORT_CASE chain AND the
-- EVENT_METRIC datamart. SUMMARY_REPORT_CASE is itself populated by
-- sp_summary_report_case_postprocessing from a Summary-type
-- nrt_investigation (case_type_cd='S') plus SummaryForm observations
-- (cd IN 'SUM103','SUM104','SUM105') — exactly the shape authored by
-- the existing fixtures/30_sp_coverage/summary_report_case.sql.
--
-- ---------------------------------------------------------------------
-- RTR BUG (see bugs/15_event_metric_add_user_name_null/findings.md):
-- SR100's INSERT (155-...-001.sql lines 139-183) maps
--   em.ADD_USER_NAME  AS ADD_USER_NAME
-- into SR100.ADD_USER_NAME, which is declared NOT NULL, with NO COALESCE.
-- For a summary investigation whose nrt_investigation.add_user_name is
-- NULL (as in summary_report_case.sql), the PHCInvForm row that
-- sp_event_metric_datamart_postprocessing writes to EVENT_METRIC carries
-- ADD_USER_NAME = NULL (it is copied straight from
-- nrt_investigation.add_user_name, 037-...-001.sql line 661). SR100's
-- INSERT then fails with:
--   Msg 515: Cannot insert the value NULL into column 'ADD_USER_NAME',
--   table 'RDB_MODERN.dbo.SR100'; column does not allow nulls.
-- This is why SR100 is empty even though summary_report_case.sql has
-- already populated SUMMARY_REPORT_CASE for PHC 22009000.
--
-- Fixture workaround (no RTR-routine change): this fixture authors its
-- OWN summary investigation (PHC 22024000) with add_user_name set
-- non-NULL, so the EVENT_METRIC PHCInvForm row it produces carries a
-- non-NULL ADD_USER_NAME and SR100's NOT NULL INSERT succeeds.
-- ---------------------------------------------------------------------
--
-- UID block: 22024000 - 22024999 (Tier 3, SR100 — agent R3-B, per the
-- "Round 3 loop reservations" table in catalog/uid_ranges.md). No ODSE
-- rows exist in this block in the baseline-merged DB (verified), so there
-- is no collision with the earlier Agent-R covid round-2 reservation.
-- All UIDs DECLAREd symbolically below.
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- Symbolic UIDs (block 22024000 - 22024999)
-- ---------------------------------------------------------------------
DECLARE @sr100_phc_uid        bigint = 22024000;  -- Summary-type investigation (case_type_cd='S')
DECLARE @sr100_obs_sum103     bigint = 22024100;  -- SUM103 coded   (summary case source)
DECLARE @sr100_obs_sum104     bigint = 22024101;  -- SUM104 numeric (summary case count)
DECLARE @sr100_obs_sum105     bigint = 22024102;  -- SUM105 text    (summary case comments)
DECLARE @superuser_id         bigint = 10009282;  -- sentinel add/last_chg user
DECLARE @sr100_patient_uid    bigint = 20000000;  -- foundation Patient (read-only ref)

-- =====================================================================
-- 1) Summary-type Investigation (case_type_cd='S').
--    Mirrors summary_report_case.sql, but adds add_user_name /
--    last_chg_user_name so the downstream EVENT_METRIC PHCInvForm row
--    has a non-NULL ADD_USER_NAME (SR100.ADD_USER_NAME is NOT NULL).
--    county_cd=13121 (Fulton County, GA; state 13) — present in
--    nrt_srte_state_county_code_value so SR100's INNER JOIN resolves.
--    cd='10470' (Cholera) — present in RDB_MODERN.dbo.condition.
-- =====================================================================


-- =====================================================================
-- 2) SummaryForm observations: SUM103 (coded), SUM104 (numeric),
--    SUM105 (text). Drives SUMMARY_REPORT_CASE via
--    sp_summary_report_case_postprocessing.
-- =====================================================================





-- =====================================================================
-- 3) Tail-EXEC the dependency chain for SR100, in dependency order:
--      a. SUMMARY_REPORT_CASE  (sp_summary_report_case_postprocessing)
--      b. EVENT_METRIC         (sp_event_metric_datamart_postprocessing)
--      c. SR100                (sp_sr100_datamart_postprocessing)
--    NOTE on ordering: the merge orchestrator (scripts/merge_and_verify.sh)
--    currently runs sp_sr100_datamart_postprocessing (Step 9, line 528)
--    BEFORE sp_event_metric_datamart_postprocessing (line 538). At that
--    point EVENT_METRIC is empty so SR100's INNER JOIN on EVENT_METRIC
--    yields 0 rows. Re-running SR100 here (after EVENT_METRIC is built)
--    populates it. ORCH_TODO: move sp_sr100_datamart_postprocessing to
--    run AFTER sp_event_metric_datamart_postprocessing in Step 9.
-- =====================================================================


