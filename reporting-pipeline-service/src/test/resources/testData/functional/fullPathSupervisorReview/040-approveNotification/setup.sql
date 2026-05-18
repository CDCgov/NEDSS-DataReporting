USE [NBS_ODSE];

DECLARE @superuser_id BIGINT = 10009282;
-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Act_act_uid_2 bigint = 20100409;
DECLARE @dbo_Act_act_uid BIGINT = 20100408;

-- STEP 4: ApproveNotification
-- dbo.Notification
-- step: 4
UPDATE [dbo].[notification]
SET    [last_chg_time] = N'2026-04-24T15:24:03.983',
       [last_chg_user_id] = @superuser_id,
       [record_status_cd] = N'APPROVED',
       [record_status_time] = N'2026-04-24T15:24:03.983',
       [txt] = N'Notification Approved 04/21/2026',
       [version_ctrl_nbr] = Isnull([version_ctrl_nbr], 0) + 1
WHERE  [notification_uid] = @dbo_Act_act_uid_2;

-- dbo.PublicHealthCaseFact
-- step: 1
UPDATE [dbo].[publichealthcasefact]
SET    [lastnotificationdate] = N'2026-04-24T15:24:03.983',
       [lastnotificationsubmittedby] = @superuser_id,
       [notifcurrentstate] = N'APPROVED',
       [notitxt] = N'Notification Approved 04/21/2026'
WHERE  [public_health_case_uid] = @dbo_Act_act_uid; 