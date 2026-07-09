-- =====================================================================
-- Tier 3 — Summary Report Case Investigation
-- =====================================================================
-- Authored 2026-05-21 (overnight loop iteration #4).
--
-- Goal: populate SUMMARY_REPORT_CASE (currently 0/12).
--
-- sp_summary_report_case_postprocessing reads nrt_investigation rows
-- with case_type_cd='S' (Summary, not Investigation) joined to
-- nrt_investigation_observation rows of root_type_cd IN
-- ('SummaryForm','SummaryNotification') joined to observations with
-- cd IN ('SUM103','SUM104','SUM105'). 12 target columns.
--
-- UID block: 22009000 - 22009999 (Summary Report Case Tier 3).
-- =====================================================================

USE [RDB_MODERN];
GO

-- =====================================================================
-- Summary-type Investigation (case_type_cd='S').
-- =====================================================================


-- =====================================================================
-- Observations for SUM103 (coded), SUM104 (numeric), SUM105 (text).
-- =====================================================================





-- DO NOT tail-EXEC sp_summary_report_case_postprocessing here —
-- Step 9 of merge_and_verify.sh owns it via $PHC_UIDS.
