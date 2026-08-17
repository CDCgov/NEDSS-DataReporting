-- =====================================================================
-- Round 6 (NO-SHORTCUT, NON-OBS-HEAVY) — SUMMARY_REPORT_CASE + SR100 chain
-- =====================================================================
-- TARGET: populate dbo.SUMMARY_REPORT_CASE (0 rows / 0 of 12 cols) and
--   thence dbo.SR100 (0 rows / 0 of 20 cols) through the REAL pipeline.
--
-- WHY THIS IS AUTHORABLE WITHOUT ANY NEW OBSERVATIONS
-- ---------------------------------------------------
-- sp_summary_report_case_postprocessing (routine 150) builds its work set
-- (CTE SumRptWork) from:
--     nrt_investigation ni  (case_type_cd = 'S')
--       INNER JOIN nrt_investigation_observation nio
--         ON ni.public_health_case_uid = nio.public_health_case_uid
--        AND nio.root_type_cd IN ('SummaryForm','SummaryNotification')
-- The numeric/text/coded SUM104/SUM105/SUM103 joins are all LEFT JOINs
-- (nrt_observation_numeric/txt/coded) and the notification join is a LEFT
-- JOIN too — so NONE of them is required for a row to land. The only
-- mandatory ingredients are:
--   (1) an nrt_investigation row with case_type_cd='S', and
--   (2) an nrt_investigation_observation row with
--       root_type_cd IN ('SummaryForm','SummaryNotification').
--
-- Critically, nrt_investigation_observation.root_type_cd is NOT sourced
-- from an OBS-class observation. routine 056 (sp_investigation_event)
-- builds the investigation_observation_ids JSON from
-- dbo.act_relationship rows where target_act_uid = phc, projecting
-- act.type_cd AS act_type_cd, and the Java consumer
-- (ProcessInvestigationDataUtil.transformObservationIds line 345/353)
-- writes act_type_cd straight into root_type_cd. So a SummaryNotification
-- act_relationship (NOTF notification -> CASE phc) produces the required
-- nrt_investigation_observation row with NO observation rows at all.
--
-- The same SummaryNotification act_relationship also drives the
-- investigation_notifications JSON block in routine 056 (line ~737,
-- act_relationship INNER JOIN notification) -> nrt_investigation_notification,
-- whose notif_status / rpt_sent_time / last_chg_time feed
-- SUM_RPT_CASE_STATUS / NOTIFICATION_SEND_DT / NOTI_LAST_CHG_TIME. The
-- summary SP joins it on sr.observation_id = nio.notification_uid; we make
-- observation_id resolve to the notification_uid by adding one "branch"
-- act_relationship whose target = the notification (root_uid =
-- COALESCE(root.target, branch.target), routine 056 line 396).
--
-- The Java summary path is fired the moment the investigation CDC event
-- carries case_type_cd='S' (PostProcessingService.extractSummaryCase line
-- 414-417 adds the PHC to sumCache -> processSummaryCases runs both
-- sp_summary_report_case_postprocessing and sp_sr100_datamart_postprocessing).
-- merge_and_verify.sh Step-9 ALSO drives both SPs over $PHC_UIDS.
--
-- NOT-NULL GUARDRAILS satisfied:
--   SUMMARY_REPORT_CASE.COUNTY_CD / COUNTY_NAME / STATE_CD are NOT NULL.
--   They come from ni.rpt_cnty_cd + the nrt_srte_state_county_code_value
--   join, so the PHC sets rpt_cnty_cd='13121' (Fulton County GA, parent
--   state '13' — verified present in nrt_srte_state_county_code_value).
--   CONDITION_KEY resolves via dbo.condition (cd '10110' = Hepatitis A,
--   acute; CONDITION_KEY=15 present). NOTIFICATION_SEND_DT_KEY /
--   SUMMARY_CASE_SRC_KEY default to the unknown-key 1 (ISNULL in the SP).
--
-- SR100 additionally INNER JOINs dbo.EVENT_METRIC em ON em.local_id =
--   I.inv_local_id and dbo.nrt_srte_state_county_code_value on county_cd.
--   EVENT_METRIC is populated by sp_event_metric_datamart_postprocessing
--   over $PHC_UIDS (merge_and_verify Step-9), which runs for this PHC once
--   it is added to PHC_UIDS — so SR100 lands after the summary_report_case
--   row exists.
--
-- ORCH_TODO (for the orchestrator — NOT applied in this file):
--   add 22065000 to PHC_UIDS in scripts/merge_and_verify.sh so the Step-9
--   summary / sr100 / event_metric SPs target this summary investigation.
--
-- UID block (reserved 22065000-22065999 in catalog/uid_ranges.md):
--   22065000  act + public_health_case (the summary investigation, case_type_cd='S')
--   22065010  act (NOTF) + notification  (the SummaryNotification source)
--
-- Foundation deps (read-only): patient 20000000 (SubjOfPHC), superuser 10009282.
-- NON-OBS-HEAVY: authors ZERO observation/OBS-class rows, ZERO obs_value_*.
-- ODSE-only: no nrt_* INSERTs, no EXEC sp_*, no seed/SRTE/liquibase edits.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @ts        datetime = '2026-04-01T00:00:00';
DECLARE @superuser_id bigint = 10009282;
DECLARE @phc_uid   bigint = 22065000;   -- summary investigation
DECLARE @notif_uid bigint = 22065010;   -- SummaryNotification

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @phc_uid)
BEGIN
    -- ----- Summary investigation: act + public_health_case (case_type_cd='S') -----
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@phc_uid, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [rpt_cnty_cd],[mmwr_week],[mmwr_year],[rpt_to_state_time])
    VALUES
        (@phc_uid, @ts, @superuser_id, N'S',          -- case_type_cd 'S' = Summary
         N'C', N'10110', N'Hepatitis A, acute', N'NND', N'NND',
         N'O', CAST(GETDATE() AS DATE), @superuser_id, N'CAS22065000GA01',
         N'OPEN', @ts, N'A', @ts,
         N'T', 1, N'HEP', N'130001',
         @phc_uid, N'N', NULL,
         N'13121', N'14', N'2026', '2026-04-04T00:00:00');  -- rpt_cnty_cd Fulton GA (NOT NULL COUNTY_* path); rpt_to_state_time -> EARLIEST_RPT_TO_STATE_DT (SR100.DATE_REPORTED/MONTH_REPORTED NOT NULL gate)

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@phc_uid, 1, @ts, @superuser_id,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE',
         @ts, N'CAS22065000GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @ts);

    -- ----- SubjOfPHC patient link (defensive: keeps ProcessDatamartData from dropping it) -----
    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @phc_uid, N'SubjOfPHC', N'CASE', @ts, @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', @ts, N'A', @ts, N'PSN',
         N'Subject of Public Health Case');

    -- ----- SummaryNotification: act (NOTF) + notification -----
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@notif_uid, N'NOTF', N'EVN');

    INSERT INTO [dbo].[notification]
        ([notification_uid],[add_time],[add_user_id],[cd],[cd_desc_txt],
         [last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[case_class_cd],[case_condition_cd],
         [mmwr_week],[mmwr_year],[rpt_sent_time],[txt])
    VALUES
        (@notif_uid, @ts, @superuser_id, N'NOTF', N'Summary Notification (NOTF)',
         CAST(GETDATE() AS DATE), @superuser_id, N'NOT22065010GA01',
         N'COMPLETED', '2026-04-04T00:00:00', N'A', @ts,
         N'T', 1, N'HEP', N'130001',
         @notif_uid, N'C', N'10110',
         N'14', N'2026', '2026-04-04T00:00:00',
         N'Summary report case comments — exercises the txt path.');

    -- ----- PRIMARY edge: SummaryNotification (source = notification, target = phc) -----
    -- routine 056 projects this as nrt_investigation_observation
    -- root_type_cd='SummaryNotification' (the summary-SP INNER JOIN gate) AND
    -- as an investigation_notifications row -> nrt_investigation_notification.
    INSERT INTO [dbo].[act_relationship]
        ([target_act_uid],[source_act_uid],[type_cd],[source_class_cd],
         [target_class_cd],[add_time],[add_user_id],[from_time],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[sequence_nbr],[status_cd],[status_time],[type_desc_txt])
    VALUES
        (@phc_uid, @notif_uid, N'SummaryNotification', N'NOTF',
         N'CASE', @ts, @superuser_id, @ts,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE',
         @ts, 1, N'A', @ts, N'Summary Notification');

    -- ----- BRANCH edge: makes root_uid resolve to the notification_uid -----
    -- routine 056 sets observation_id = COALESCE(root.target, branch.target)
    -- where branch joins on branch.target_act_uid = act.source_act_uid
    -- (= the notification). With this branch (target = notification),
    -- observation_id = notification_uid, so the summary SP's
    -- LEFT JOIN nrt_investigation_notification ON observation_id = notification_uid
    -- resolves -> SUM_RPT_CASE_STATUS / NOTIFICATION_SEND_DT / NOTI_LAST_CHG_TIME.
    -- target = notification (NOT phc), so this row is NOT itself picked up as a
    -- second SummaryNotification obs row.
    INSERT INTO [dbo].[act_relationship]
        ([target_act_uid],[source_act_uid],[type_cd],[source_class_cd],
         [target_class_cd],[add_time],[add_user_id],[from_time],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[sequence_nbr],[status_cd],[status_time],[type_desc_txt])
    VALUES
        (@notif_uid, @phc_uid, N'SummaryRow', N'CASE',
         N'NOTF', @ts, @superuser_id, @ts,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE',
         @ts, 1, N'A', @ts, N'Summary Row');
END;
GO

-- Bump last_chg_time so CDC re-emits the investigation. The service
-- re-runs sp_investigation_event (building nrt_investigation_observation
-- with root_type_cd='SummaryNotification' + nrt_investigation_notification)
-- and, because case_type_cd='S', enqueues the PHC for the summary path
-- (processSummaryCases -> sp_summary_report_case_postprocessing +
-- sp_sr100_datamart_postprocessing).
UPDATE [NBS_ODSE].[dbo].[public_health_case]
   SET [last_chg_time] = SYSDATETIME()
 WHERE public_health_case_uid = 22065000;
GO
