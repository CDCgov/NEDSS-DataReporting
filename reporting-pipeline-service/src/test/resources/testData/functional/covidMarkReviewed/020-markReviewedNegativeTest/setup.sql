USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 22000000;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 22000001;
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 22000002;
DECLARE @dbo_Tele_locator_tele_locator_uid_2 bigint = 22000003;
DECLARE @dbo_Entity_entity_uid_2 bigint = 22000004;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 22000005;
DECLARE @dbo_Tele_locator_tele_locator_uid_3 bigint = 22000006;
DECLARE @dbo_Tele_locator_tele_locator_uid_4 bigint = 22000007;
DECLARE @dbo_Act_act_uid bigint = 22000008;
DECLARE @dbo_Act_act_uid_2 bigint = 22000009;
DECLARE @dbo_Act_act_uid_3 bigint = 22000010;
DECLARE @dbo_Act_act_uid_4 bigint = 22000011;
DECLARE @dbo_Act_act_uid_5 bigint = 22000012;
DECLARE @dbo_Entity_entity_uid_3 bigint = 22000013;
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';
DECLARE @dbo_Observation_local_id nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid))) + N'GA01';
DECLARE @dbo_Observation_local_id_2 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_2))) + N'GA01';
DECLARE @dbo_Observation_local_id_3 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_3))) + N'GA01';
DECLARE @dbo_Observation_local_id_4 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_4))) + N'GA01';
DECLARE @dbo_Observation_local_id_5 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_5))) + N'GA01';
DECLARE @dbo_Material_local_id nvarchar(40) = N'MAT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_3))) + N'GA01';

-- STEP 2: MarkCaseAsReviewedCovid
-- dbo.Observation
-- step: 2
UPDATE [dbo].[Observation] SET [last_chg_time] = N'2026-04-27T21:27:45.617', [record_status_cd] = N'PROCESSED', [record_status_time] = N'2026-04-27T21:27:45.617', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [processing_decision_cd] = N'NEGLAB', [processing_decision_txt] = N'No investigation needed' WHERE [observation_uid] = @dbo_Act_act_uid;
