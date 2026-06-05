-- =====================================================================
-- Tier 3 — Extra rdb_column_nm coverage for D_INVESTIGATION_REPEAT
-- =====================================================================
-- Authored 2026-05-22 (overnight, post bug #9/#10 fixes).
--
-- Goal: populate more BASELINE-DEFINED columns in D_INVESTIGATION_REPEAT.
-- The Pertussis fixture (22006000) authored 8 NEW rdb_column_nm values
-- (TRAVEL_*, EXPOSURE_*) which grew the schema by +8 cols.  But D_INV_REPEAT
-- has ~248 baseline-seeded columns (EPI_*, CLN_*, ADM_*, CMP_*, ...) that
-- are still NULL because no nrt_page_case_answer rows target them.
--
-- Adding answers with rdb_column_nm = existing baseline col name
-- populates that column without growing the schema width.  Net coverage
-- impact = +1 per column populated (numerator only, denominator stays
-- at 256).
--
-- Pattern: piggyback on Pertussis fixture's 6 dim slots
-- (TRAVEL_BLOCK × 3 seq, EXPOSURE_BLOCK × 3 seq) — additional answers
-- with matching (act_uid=22006000, block_nm, answer_group_seq_nbr,
-- new rdb_column_nm) populate the new columns on the SAME dim rows.
--
-- UID block: 22006200-22006499 (300 reserved, comfortable for 50+ rows).
-- Sort prefix: zz_ so this applies AFTER d_investigation_repeat.sql
-- (the SP runs once at Step 8.5 against all PHC_UIDS; both sets of
-- answers are picked up in one pass).
-- =====================================================================

USE [RDB_MODERN];
GO


-- The orchestrator's Step 8.5 (added in commit 99ef3517) runs
-- sp_sld_investigation_repeat_postprocessing against $PHC_UIDS,
-- which picks up these answers along with d_investigation_repeat.sql's
-- 24 original answers in one pass.  No tail-EXEC here.
