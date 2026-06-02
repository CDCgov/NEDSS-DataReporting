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
INSERT INTO [dbo].[nrt_investigation]
    ([public_health_case_uid], [patient_id], [local_id], [shared_ind], [case_type_cd],
     [jurisdiction_cd], [record_status_cd], [mood_cd], [class_cd],
     [case_class_cd], [cd], [cd_desc_txt], [prog_area_cd],
     [investigation_form_cd], [case_management_uid],
     [status_time], [record_status_time], [raw_record_status_cd],
     [add_time], [last_chg_time], [investigation_status_cd],
     [rpt_cnty_cd], [add_user_name], [last_chg_user_name],
     [mmwr_year], [mmwr_week], [txt], [batch_id])
VALUES
    (@agg_phc_uid, 20000000, N'AGG22023500GA01', N'T', N'A',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'10470', N'Salmonellosis', N'FOOD',
     N'INV_FORM_GEN', NULL,
     '2026-05-04T00:00:00', '2026-05-04T00:00:00', N'ACTIVE',
     '2026-05-04T00:00:00', '2026-05-04T00:00:00', N'O',
     @rpt_cnty_cd, N'Foundation, Superuser', N'Foundation, Superuser',
     N'2026', N'18',
     N'Weekly aggregate Salmonellosis report — week 18 2026 (enrich: coded path)',
     @agg_batch_id);

EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'22023500', @debug = 0;

-- =====================================================================
-- nrt_investigation_aggregate — Numeric count grid (24 cells) so the
-- #AGG_DATA_NUM pivot has all the age x type cells, PLUS NUM_HOSP_REPORTING.
-- =====================================================================
INSERT INTO [dbo].[nrt_investigation_aggregate]
    (act_uid, nbs_case_answer_uid, answer_txt, data_type, code_set_group_id, datamart_column_nm, batch_id)
VALUES
    -- HOSPITALIZED counts
    (@agg_phc_uid, 22023501, N'2',  N'Numeric', NULL, N'HOSPITALIZED_COUNT_0_TO_4',   @agg_batch_id),
    (@agg_phc_uid, 22023502, N'4',  N'Numeric', NULL, N'HOSPITALIZED_COUNT_5_TO_18',  @agg_batch_id),
    (@agg_phc_uid, 22023503, N'3',  N'Numeric', NULL, N'HOSPITALIZED_19_TO_24',       @agg_batch_id),
    (@agg_phc_uid, 22023504, N'6',  N'Numeric', NULL, N'HOSPITALIZED_COUNT_25_TO_49', @agg_batch_id),
    (@agg_phc_uid, 22023505, N'5',  N'Numeric', NULL, N'HOSPITALIZED_COUNT_50_TO_64', @agg_batch_id),
    (@agg_phc_uid, 22023506, N'7',  N'Numeric', NULL, N'HOSPITALIZED_COUNT_65_PLUS',  @agg_batch_id),
    (@agg_phc_uid, 22023507, N'27', N'Numeric', NULL, N'HOSPITALIZED_COUNT_TOTAL',    @agg_batch_id),
    (@agg_phc_uid, 22023508, N'0',  N'Numeric', NULL, N'HOSPITALIZED_COUNT_UNKNOWN',  @agg_batch_id),
    -- DIED counts
    (@agg_phc_uid, 22023509, N'0', N'Numeric', NULL, N'DIED_COUNT_0_TO_4',   @agg_batch_id),
    (@agg_phc_uid, 22023510, N'0', N'Numeric', NULL, N'DIED_COUNT_5_TO_18',  @agg_batch_id),
    (@agg_phc_uid, 22023511, N'1', N'Numeric', NULL, N'DIED_COUNT_19_TO_24', @agg_batch_id),
    (@agg_phc_uid, 22023512, N'2', N'Numeric', NULL, N'DIED_COUNT_25_TO_49', @agg_batch_id),
    (@agg_phc_uid, 22023513, N'1', N'Numeric', NULL, N'DIED_COUNT_50_TO_64', @agg_batch_id),
    (@agg_phc_uid, 22023514, N'3', N'Numeric', NULL, N'DIED_COUNT_65_PLUS',  @agg_batch_id),
    (@agg_phc_uid, 22023515, N'7', N'Numeric', NULL, N'DIED_COUNT_TOTAL',    @agg_batch_id),
    (@agg_phc_uid, 22023516, N'0', N'Numeric', NULL, N'DIED_COUNT_UNKNOWN',  @agg_batch_id),
    -- TOTAL counts
    (@agg_phc_uid, 22023517, N'15', N'Numeric', NULL, N'TOTAL_COUNT_0_TO_4',   @agg_batch_id),
    (@agg_phc_uid, 22023518, N'30', N'Numeric', NULL, N'TOTAL_COUNT_5_TO_18',  @agg_batch_id),
    (@agg_phc_uid, 22023519, N'20', N'Numeric', NULL, N'TOTAL_COUNT_19_TO_24', @agg_batch_id),
    (@agg_phc_uid, 22023520, N'45', N'Numeric', NULL, N'TOTAL_COUNT_25_TO_49', @agg_batch_id),
    (@agg_phc_uid, 22023521, N'35', N'Numeric', NULL, N'TOTAL_COUNT_50_TO_64', @agg_batch_id),
    (@agg_phc_uid, 22023522, N'25', N'Numeric', NULL, N'TOTAL_COUNT_65_PLUS',  @agg_batch_id),
    (@agg_phc_uid, 22023523, N'170',N'Numeric', NULL, N'TOTAL_COUNT_TOTAL',    @agg_batch_id),
    (@agg_phc_uid, 22023524, N'5',  N'Numeric', NULL, N'TOTAL_COUNT_UNKNOWN',  @agg_batch_id),
    -- Numeric administrative cell
    (@agg_phc_uid, 22023525, N'11', N'Numeric', NULL, N'NUM_HOSP_REPORTING',   @agg_batch_id),
    -- ===============================================================
    -- CODED cell — exercises the #AGG_DATA_CODED branch (SP lines 63-77).
    -- code_set_group_id=30 (ACT_MOOD); answer_txt='EVN' resolves via
    -- nrt_srte_Code_value_general.code -> code_short_desc_txt
    -- 'Event (occurrence)', written to SURVEILLANCE_METHOD (a real
    -- varchar column on the target). The original fixture has zero Coded
    -- rows, so this is the only exercise of the coded pivot.
    -- ===============================================================
    (@agg_phc_uid, 22023526, @coded_answer, N'Coded', @coded_grp_id, N'SURVEILLANCE_METHOD', @agg_batch_id);
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
EXEC dbo.sp_aggregate_report_datamart_postprocessing @id_list = N'22010000,22023500', @debug = 0;
GO
