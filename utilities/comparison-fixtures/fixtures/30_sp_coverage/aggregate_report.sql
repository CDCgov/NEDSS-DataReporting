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
    (22010000, 20000000, N'AGG22010000GA01', N'T', N'A',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'10470', N'Salmonellosis', N'FOOD',
     N'INV_FORM_GEN', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O',
     N'13121', N'Foundation, Superuser', N'Foundation, Superuser',
     N'2026', N'14',
     N'Weekly aggregate Salmonellosis report — week 14 2026',
     1);

EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'22010000', @debug = 0;

-- =====================================================================
-- nrt_investigation_aggregate rows — one per (count_type, age_group).
-- 24 cells (HOSPITALIZED/DIED/TOTAL × 0-4 / 5-18 / 19-24 / 25-49 /
-- 50-64 / 65+ / TOTAL / UNKNOWN). All Numeric type.
-- =====================================================================
INSERT INTO [dbo].[nrt_investigation_aggregate]
    (act_uid, nbs_case_answer_uid, answer_txt, data_type, datamart_column_nm, batch_id)
VALUES
    -- HOSPITALIZED counts
    (22010000, 22010001, N'1',  N'Numeric', N'HOSPITALIZED_COUNT_0_TO_4',   1),
    (22010000, 22010002, N'3',  N'Numeric', N'HOSPITALIZED_COUNT_5_TO_18',  1),
    (22010000, 22010003, N'2',  N'Numeric', N'HOSPITALIZED_19_TO_24',       1),
    (22010000, 22010004, N'5',  N'Numeric', N'HOSPITALIZED_COUNT_25_TO_49', 1),
    (22010000, 22010005, N'4',  N'Numeric', N'HOSPITALIZED_COUNT_50_TO_64', 1),
    (22010000, 22010006, N'6',  N'Numeric', N'HOSPITALIZED_COUNT_65_PLUS',  1),
    (22010000, 22010007, N'21', N'Numeric', N'HOSPITALIZED_COUNT_TOTAL',    1),
    (22010000, 22010008, N'0',  N'Numeric', N'HOSPITALIZED_COUNT_UNKNOWN',  1),
    -- DIED counts
    (22010000, 22010011, N'0', N'Numeric', N'DIED_COUNT_0_TO_4',   1),
    (22010000, 22010012, N'0', N'Numeric', N'DIED_COUNT_5_TO_18',  1),
    (22010000, 22010013, N'0', N'Numeric', N'DIED_COUNT_19_TO_24', 1),
    (22010000, 22010014, N'1', N'Numeric', N'DIED_COUNT_25_TO_49', 1),
    (22010000, 22010015, N'1', N'Numeric', N'DIED_COUNT_50_TO_64', 1),
    (22010000, 22010016, N'2', N'Numeric', N'DIED_COUNT_65_PLUS',  1),
    (22010000, 22010017, N'4', N'Numeric', N'DIED_COUNT_TOTAL',    1),
    (22010000, 22010018, N'0', N'Numeric', N'DIED_COUNT_UNKNOWN',  1),
    -- TOTAL counts
    (22010000, 22010021, N'12', N'Numeric', N'TOTAL_COUNT_0_TO_4',   1),
    (22010000, 22010022, N'25', N'Numeric', N'TOTAL_COUNT_5_TO_18',  1),
    (22010000, 22010023, N'18', N'Numeric', N'TOTAL_COUNT_19_TO_24', 1),
    (22010000, 22010024, N'40', N'Numeric', N'TOTAL_COUNT_25_TO_49', 1),
    (22010000, 22010025, N'30', N'Numeric', N'TOTAL_COUNT_50_TO_64', 1),
    (22010000, 22010026, N'22', N'Numeric', N'TOTAL_COUNT_65_PLUS',  1),
    (22010000, 22010027, N'147',N'Numeric', N'TOTAL_COUNT_TOTAL',    1),
    (22010000, 22010028, N'5',  N'Numeric', N'TOTAL_COUNT_UNKNOWN',  1),
    -- A few other numeric fields
    (22010000, 22010030, N'8',  N'Numeric', N'NUM_HOSP_REPORTING',   1);

-- DO NOT tail-EXEC sp_aggregate_report_datamart_postprocessing here —
-- Step 9 of merge_and_verify.sh owns it via $PHC_UIDS.
