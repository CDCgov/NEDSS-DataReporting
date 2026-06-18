-- =====================================================================
-- zz_zzz_zzz_enrich_notifications.sql
--
-- Adds a state case Notification (act NOTF/EVN + notification row + a
-- 'Notification' act_relationship to the PHC) for every synthetic investigation
-- that lacks one. Reportable investigations send a notification to the state;
-- this fills the Notifications section on the investigation detail and feeds the
-- NOTIFICATION dimension. Condition / case class / OID / jurisdiction / MMWR are
-- derived from the PHC so the notification matches its investigation. ODSE-only,
-- set-based, idempotent. UID block 22093000-22093099.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @su bigint = 10009282;

SELECT phc.public_health_case_uid AS phc, phc.cd, phc.case_class_cd AS ccl,
       phc.program_jurisdiction_oid AS oid, phc.jurisdiction_cd AS juris,
       phc.prog_area_cd AS pa, phc.mmwr_week AS wk, phc.mmwr_year AS yr,
       22093000 + ROW_NUMBER() OVER (ORDER BY phc.public_health_case_uid) - 1 AS nuid
INTO #need
FROM dbo.public_health_case phc
WHERE phc.public_health_case_uid >= 20000000
  AND phc.public_health_case_uid <> 20000100
  AND NOT EXISTS (SELECT 1 FROM dbo.act_relationship ar
                  JOIN dbo.notification n ON n.notification_uid = ar.source_act_uid
                  WHERE ar.target_act_uid = phc.public_health_case_uid
                    AND ar.type_cd = 'Notification');

INSERT INTO dbo.act (act_uid, class_cd, mood_cd)
  SELECT nuid, N'NOTF', N'EVN' FROM #need n
  WHERE NOT EXISTS (SELECT 1 FROM dbo.act a WHERE a.act_uid = n.nuid);

INSERT INTO dbo.notification
  (notification_uid, add_time, add_user_id, cd, cd_desc_txt, last_chg_time, last_chg_user_id,
   local_id, record_status_cd, record_status_time, status_cd, status_time, shared_ind,
   version_ctrl_nbr, prog_area_cd, jurisdiction_cd, program_jurisdiction_oid, case_class_cd,
   case_condition_cd, confirmation_method_cd, mmwr_week, mmwr_year, rpt_sent_time, rpt_source_cd,
   confidentiality_cd, confidentiality_desc_txt, method_cd, method_desc_txt, reason_cd,
   reason_desc_txt, auto_resend_ind, txt)
  SELECT nuid, '2026-04-16T09:00:00', @su, N'NOTF', N'Notification (NOTF)',
         '2026-04-16T09:00:00', @su, N'NOT' + CAST(nuid AS varchar(20)) + N'GA01',
         N'COMPLETED', '2026-04-16T09:00:00', N'A', '2026-04-16T09:00:00', N'T',
         1, pa, juris, oid, ISNULL(ccl, N'C'),
         cd, N'LB', ISNULL(wk, N'15'), ISNULL(yr, N'2026'), '2026-04-16T09:00:00', N'PHC',
         N'R', N'Restricted', N'ELC', N'Electronic',
         N'NEW', N'New notification', N'N', N'State case notification.'
  FROM #need;

INSERT INTO dbo.act_relationship
  (target_act_uid, source_act_uid, type_cd, source_class_cd, target_class_cd,
   add_time, add_user_id, last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
   status_cd, status_time)
  SELECT phc, nuid, N'Notification', N'NOTF', N'CASE',
         '2026-04-16T09:00:00', @su, '2026-04-16T09:00:00', @su, N'ACTIVE', '2026-04-16T09:00:00',
         N'A', '2026-04-16T09:00:00'
  FROM #need;

DROP TABLE #need;
GO
