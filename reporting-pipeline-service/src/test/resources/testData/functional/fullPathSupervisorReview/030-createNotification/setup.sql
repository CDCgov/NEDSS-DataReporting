USE [NBS_ODSE];

DECLARE @local_user_id BIGINT = 10007004;
-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Act_act_uid BIGINT = 20100408;
DECLARE @dbo_Act_act_uid_2 bigint = 20100409;
DECLARE @dbo_Notification_local_id NVARCHAR(40) = N'NOT20100409GA01';

-- STEP 3: CreateNotification
-- dbo.Act
-- step: 3
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_2,
             N'NOTF',
             N'EVN');

-- dbo.Notification
-- step: 3


INSERT INTO [dbo].[notification]
            ([notification_uid],
             [add_time],
             [add_user_id],
             [case_class_cd],
             [case_condition_cd],
             [cd],
             [jurisdiction_cd],
             [last_chg_time],
             [last_chg_user_id],
             [local_id],
             [mmwr_week],
             [mmwr_year],
             [prog_area_cd],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [txt],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [auto_resend_ind])
VALUES      (@dbo_Act_act_uid_2,
             N'2026-04-22T20:50:18.467',
             @local_user_id,
             N'C',
             N'10110',
             N'NOTF',
             N'130005',
             N'2026-04-22T20:50:18.467',
             @local_user_id,
             @dbo_Notification_local_id,
             N'16',
             N'2026',
             N'HEP',
             N'PEND_APPR',
             N'2026-04-22T20:50:18.467',
             N'A',
             N'2026-04-22T20:50:18.417',
             N'Notification Submitted 04/21/2026',
             1300500011,
             N'T',
             1,
             N'F');

-- dbo.Act_relationship
-- step: 3
INSERT INTO [dbo].[act_relationship]
            ([target_act_uid],
             [source_act_uid],
             [type_cd],
             [add_time],
             [last_chg_time],
             [record_status_cd],
             [record_status_time],
             [sequence_nbr],
             [source_class_cd],
             [status_cd],
             [status_time],
             [target_class_cd])
VALUES      (@dbo_Act_act_uid,
             @dbo_Act_act_uid_2,
             N'Notification',
             N'2026-04-22T20:50:18.417',
             N'2026-04-22T20:50:18.497',
             N'ACTIVE',
             N'2026-04-22T20:50:18.497',
             1,
             N'NOTF',
             N'A',
             N'2026-04-22T20:50:18.417',
             N'CASE');

-- dbo.PublicHealthCaseFact
-- step: 3
UPDATE [dbo].[publichealthcasefact]
SET    [firstnotificationdate] = N'2026-04-22T20:50:18.467',
       [firstnotificationstatus] = N'PEND_APPR',
       [firstnotificationsubmittedby] = 10007004,
       [lastnotificationdate] = N'2026-04-22T20:50:18.467',
       [lastnotificationsubmittedby] = 10007004,
       [notifcreatedcount] = 1,
       [notifsentcount] = 0,
       [notifcurrentstate] = N'PEND_APPR',
       [notitxt] = N'Notification Submitted 04/21/2026',
       [notification_local_id] = @dbo_Notification_local_id
WHERE  [public_health_case_uid] = @dbo_Act_act_uid; 