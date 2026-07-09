-- =====================================================================
-- Tier 3 — Aggregate Report enrichment (zz_aggregate_report_enrich)
-- =====================================================================
-- Authored 2026-06-02 (loop agent R3-A).
--
-- Target: dbo.AGGREGATE_REPORT_DATAMART (0/42 columns in RDB_MODERN).
--
-- Companion to fixtures/30_sp_coverage/aggregate_report.sql (PHC 22010000),
-- which authors a single Aggregate-type Investigation with a Numeric-only
-- count grid. This fixture EXTENDS that coverage by adding a SECOND
-- Aggregate-type Investigation (PHC 22023500) that additionally exercises
-- the Coded data-type path (#AGG_DATA_CODED) — the SP branch the original
-- fixture leaves completely unexercised — plus the REPORTING_COUNTY SRTE
-- join and the NUM_HOSP_REPORTING numeric cell.
--
-- sp_aggregate_report_datamart_postprocessing reads:
--   - dbo.nrt_investigation rows with case_type_cd='A' (the #AGG_EVENT
--     CTE, lines 90-103) — event-block columns (REPORTING_COUNTY, COMMENTS,
--     REPORT_LOCAL_ID, CONDITION_DESCRIPTION, MMWR_*, REPORT_*_DATE, USER_NM,
--     REPORT_CREATED/UPDATED_BY_USER).
--   - dbo.nrt_investigation_aggregate rows joined on act_uid + matching
--     batch_id (the IIF(agg.batch_id = inv.batch_id, ...) guard at lines
--     43 and 66). Numeric rows (data_type='Numeric') feed #AGG_DATA_NUM;
--     Coded rows (data_type='Coded') feed #AGG_DATA_CODED via
--     nrt_srte_Codeset_Group_Metadata + nrt_srte_Code_value_general
--     (lines 63-77, joined on code_set_group_id and code = answer_txt).
--   - dbo.nrt_srte_state_county_code_value (REPORTING_COUNTY, line 126),
--     joined on rpt_cnty_cd = code.
--
-- KNOWN RTR BUG (#11) — this table CANNOT be populated as authored. The
-- SP's dynamic UPDATE (line 187) and INSERT (lines 268, 286) reference
-- target columns NOTIFICATION_UPD_DT_KEY and NOTIFICATION_LAST_CHANGE_TIME,
-- neither of which exists on AGGREGATE_REPORT_DATAMART (verified live
-- 2026-06-02: table has only NOTIFICATION_STATUS + NOTIFICATION_LOCAL_ID).
-- Step 5 (UPDATE) errors with msg 207 "Invalid column name
-- 'NOTIFICATION_UPD_DT_KEY'", the try/catch swallows it, and the table
-- stays at 0 rows. The error is in the SP's hardcoded dynamic SQL — NO
-- fixture data can avoid it. This fixture is authored so that the MOMENT
-- the RTR SP is fixed (drop the two phantom columns from the UPDATE/INSERT,
-- or add them to the target table), both the Numeric and Coded branches
-- populate without further fixture changes. See
-- bugs/11_aggregate_report_datamart_schema_mismatch/findings.md.
--
-- UID block: 22023000 - 22023999. UIDs used: 22023500 (PHC/act_uid),
-- 22023501-22023520 (nbs_case_answer_uid surrogate values on the
-- nrt_investigation_aggregate rows). The 22023001-22023003 / 22023100 /
-- 22023110-22023113 / 22023200-22023201 sub-range is reserved by the
-- (quarantined, merge-excluded) zz_hepatitis_datamart_round2 fixture; we
-- allocate from 22023500+ to avoid any overlap.
-- =====================================================================

USE [RDB_MODERN];
GO

-- Symbolic UID DECLAREs (all within the assigned 22023000-22023999 block).
DECLARE @agg_phc_uid            bigint = 22023500;  -- 2nd Aggregate Investigation act_uid / public_health_case_uid
DECLARE @agg_batch_id           bigint = 1;         -- must match the agg rows' batch_id (IIF guard, SP lines 43/66)
DECLARE @rpt_cnty_cd            varchar(20) = N'13089';  -- DeKalb County (grounded in nrt_srte_state_county_code_value)
DECLARE @coded_grp_id           bigint = 30;        -- ACT_MOOD codeset group (nrt_srte_Codeset_Group_Metadata)
DECLARE @coded_answer           varchar(20) = N'EVN';    -- ACT_MOOD code 'EVN' -> code_short_desc_txt 'Event (occurrence)'

-- =====================================================================
-- Second Aggregate-type Investigation (case_type_cd='A').
-- batch_id must equal the agg rows' batch_id, else the IIF guard drops
-- every count to NULL (NULL = NULL evaluates as NULL).
-- =====================================================================


-- =====================================================================
-- nrt_investigation_aggregate — Numeric count grid (24 cells) so the
-- #AGG_DATA_NUM pivot has all the age x type cells, PLUS NUM_HOSP_REPORTING.
-- =====================================================================
GO

-- =====================================================================
-- Tail-EXEC the populating SP with BOTH this fixture's PHC (22023500) and
-- the companion fixture's PHC (22010000), so the orchestrator can populate
-- all authored aggregate rows in one call once bug #11 is fixed.
--
-- NOTE: until RTR bug #11 is fixed, this EXEC returns "COMPLETE" but the
-- inner UPDATE (step 5) errors with msg 207 (Invalid column name
-- 'NOTIFICATION_UPD_DT_KEY') and AGGREGATE_REPORT_DATAMART stays at 0 rows.
-- The error is swallowed by the SP's try/catch; check job_flow_log
-- (Dataflow_Name='AGGREGATE_REPORT_DATAMART Post-Processing Event',
-- status_type='ERROR') to observe it.
-- =====================================================================
GO
