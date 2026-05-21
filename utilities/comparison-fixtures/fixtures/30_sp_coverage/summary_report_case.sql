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
INSERT INTO [dbo].[nrt_investigation]
    ([public_health_case_uid], [patient_id], [local_id], [shared_ind], [case_type_cd],
     [jurisdiction_cd], [record_status_cd], [mood_cd], [class_cd],
     [case_class_cd], [cd], [cd_desc_txt], [prog_area_cd],
     [investigation_form_cd], [case_management_uid],
     [status_time], [record_status_time], [raw_record_status_cd],
     [add_time], [last_chg_time], [investigation_status_cd],
     [rpt_cnty_cd])
VALUES
    (22009000, 20000000, N'CAS22009000GA01', N'T', N'S',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'10470', N'Salmonellosis', N'FOOD',
     N'INV_FORM_GEN', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O',
     N'13121');

EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'22009000', @debug = 0;

-- =====================================================================
-- Observations for SUM103 (coded), SUM104 (numeric), SUM105 (text).
-- =====================================================================
INSERT INTO [dbo].[nrt_observation]
    ([observation_uid], [class_cd], [mood_cd], [cd], [cd_desc_txt],
     [record_status_cd], [obs_domain_cd_st_1], [version_ctrl_nbr],
     [add_user_id], [add_time], [last_chg_user_id], [last_chg_time])
VALUES
    (22009100, N'OBS', N'EVN', N'SUM103', N'Summary case source',  N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22009101, N'OBS', N'EVN', N'SUM104', N'Summary case count',   N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22009102, N'OBS', N'EVN', N'SUM105', N'Summary case comments',N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00');

INSERT INTO [dbo].[nrt_investigation_observation]
    ([public_health_case_uid], [observation_id], [root_type_cd],
     [branch_id], [branch_type_cd], [batch_id])
VALUES
    (22009000, 22009100, N'SummaryForm', 22009100, N'InvFrmQ', NULL),
    (22009000, 22009101, N'SummaryForm', 22009101, N'InvFrmQ', NULL),
    (22009000, 22009102, N'SummaryForm', 22009102, N'InvFrmQ', NULL);

INSERT INTO [dbo].[nrt_observation_coded] ([observation_uid], [ovc_code], [batch_id]) VALUES
    (22009100, N'PHC_LOCAL', NULL);

INSERT INTO [dbo].[nrt_observation_numeric] ([observation_uid], [ovn_seq], [ovn_numeric_value_1], [batch_id]) VALUES
    (22009101, 1, 42, NULL);

INSERT INTO [dbo].[nrt_observation_txt] ([observation_uid], [ovt_seq], [ovt_value_txt], [batch_id]) VALUES
    (22009102, 1, N'42 cases of foodborne Salmonellosis, week 14 2026.', NULL);

-- DO NOT tail-EXEC sp_summary_report_case_postprocessing here —
-- Step 9 of merge_and_verify.sh owns it via $PHC_UIDS.
