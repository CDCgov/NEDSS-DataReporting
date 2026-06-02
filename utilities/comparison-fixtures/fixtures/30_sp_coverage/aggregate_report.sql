-- =====================================================================
-- Tier 3 — Aggregate Report Investigation
-- =====================================================================
-- Authored 2026-05-21 (overnight loop iteration #5).
--
-- Goal: populate AGGREGATE_REPORT_DATAMART (currently 0/42).
--
-- sp_aggregate_report_datamart_postprocessing reads nrt_investigation
-- rows with case_type_cd='A' (Aggregate) joined to nrt_investigation_aggregate
-- rows providing per-cell counts via (act_uid, data_type, datamart_column_nm,
-- answer_txt). 42 target columns: event-block (8 from Investigation) +
-- count grid (24 cells: 8 age groups x 3 types HOSPITALIZED/DIED/TOTAL) +
-- some notification/provider context.
--
-- UID block: 22010000 - 22010999.
-- =====================================================================

USE [RDB_MODERN];
GO

-- =====================================================================
-- Aggregate-type Investigation (case_type_cd='A').
-- =====================================================================
-- batch_id = 1 — must match the agg rows' batch_id so the SP's
-- IIF(agg.batch_id = inv.batch_id, ...) returns the numeric response
-- and not NULL. NULL = NULL evaluates as NULL, so leaving both NULL
-- silently drops every count. Discovered the hard way in iter 5
-- attempt 1.


-- =====================================================================
-- nrt_investigation_aggregate rows — one per (count_type, age_group).
-- 24 cells (HOSPITALIZED/DIED/TOTAL × 0-4 / 5-18 / 19-24 / 25-49 /
-- 50-64 / 65+ / TOTAL / UNKNOWN). All Numeric type.
-- =====================================================================

-- DO NOT tail-EXEC sp_aggregate_report_datamart_postprocessing here —
-- Step 9 of merge_and_verify.sh owns it via $PHC_UIDS.
