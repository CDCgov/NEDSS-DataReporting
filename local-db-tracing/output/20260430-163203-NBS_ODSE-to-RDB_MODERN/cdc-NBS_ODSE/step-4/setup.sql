USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 3300000;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 3300001;
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 3300002;
DECLARE @dbo_Tele_locator_tele_locator_uid_2 bigint = 3300003;
DECLARE @dbo_Entity_entity_uid_2 bigint = 3300004;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 3300005;
DECLARE @dbo_Tele_locator_tele_locator_uid_3 bigint = 3300006;
DECLARE @dbo_Tele_locator_tele_locator_uid_4 bigint = 3300007;
DECLARE @dbo_Act_act_uid bigint = 3300008;
DECLARE @dbo_Act_act_uid_2 bigint = 3300009;
DECLARE @dbo_Act_act_uid_3 bigint = 3300010;
DECLARE @dbo_Act_act_uid_4 bigint = 3300011;
DECLARE @dbo_Entity_entity_uid_3 bigint = 3300012;
DECLARE @dbo_Entity_entity_uid_4 bigint = 3300013;
DECLARE @dbo_Postal_locator_postal_locator_uid_3 bigint = 3300014;
DECLARE @dbo_Tele_locator_tele_locator_uid_5 bigint = 3300015;
DECLARE @dbo_Tele_locator_tele_locator_uid_6 bigint = 3300016;
DECLARE @dbo_Act_act_uid_5 bigint = 3300017;
DECLARE @dbo_Act_act_uid_6 bigint = 3300018;
DECLARE @dbo_Act_act_uid_7 bigint = 3300019;
DECLARE @dbo_Entity_entity_uid_5 bigint = 3300020;
DECLARE @dbo_Postal_locator_postal_locator_uid_4 bigint = 3300021;
DECLARE @dbo_Entity_entity_uid_6 bigint = 3300022;
DECLARE @dbo_Postal_locator_postal_locator_uid_5 bigint = 3300023;
DECLARE @dbo_Act_act_uid_8 bigint = 3300024;
DECLARE @dbo_Entity_entity_uid_7 bigint = 3300025;
DECLARE @dbo_Postal_locator_postal_locator_uid_6 bigint = 3300026;
DECLARE @dbo_Act_act_uid_9 bigint = 3300027;
DECLARE @dbo_Act_act_uid_10 bigint = 3300028;
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';
DECLARE @dbo_Observation_local_id nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid))) + N'GA01';
DECLARE @dbo_Observation_local_id_2 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_2))) + N'GA01';
DECLARE @dbo_Observation_local_id_3 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_3))) + N'GA01';
DECLARE @dbo_Observation_local_id_4 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_4))) + N'GA01';
DECLARE @dbo_Material_local_id nvarchar(40) = N'MAT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_3))) + N'GA01';
DECLARE @dbo_Public_health_case_local_id nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_5))) + N'GA01';
DECLARE @dbo_case_management_case_management_uid bigint;
DECLARE @dbo_case_management_case_management_uid_output TABLE ([value] bigint);
DECLARE @dbo_message_log_message_log_uid bigint;
DECLARE @dbo_message_log_message_log_uid_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_2 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_4 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_4_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_5 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_5_output TABLE ([value] bigint);
DECLARE @dbo_Treatment_local_id nvarchar(40) = N'TRT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_6))) + N'GA01';
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_6 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_6_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_7 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_7_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_8 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_8_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_4 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_4_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_9 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_9_output TABLE ([value] bigint);
DECLARE @dbo_message_log_message_log_uid_2 bigint;
DECLARE @dbo_message_log_message_log_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_10 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_10_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_11 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_11_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_12 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_12_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_13 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_13_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_14 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_14_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_15 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_15_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_16 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_16_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_5 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_5_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_6 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_6_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_7 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_7_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_8 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_8_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_9 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_9_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_10 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_10_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_11 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_11_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_12 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_12_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_13 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_13_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_14 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_14_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_15 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_15_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_16 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_16_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_17 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_17_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_18 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_18_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_19 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_19_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_20 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_20_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_21 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_21_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_22 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_22_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_23 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_23_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_24 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_24_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_25 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_25_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_26 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_26_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_27 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_27_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_28 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_28_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_29 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_29_output TABLE ([value] bigint);
DECLARE @dbo_Interview_local_id nvarchar(40) = N'INT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_7))) + N'GA01';
DECLARE @dbo_nbs_answer_nbs_answer_uid bigint;
DECLARE @dbo_nbs_answer_nbs_answer_uid_output TABLE ([value] bigint);
DECLARE @dbo_nbs_answer_nbs_answer_uid_2 bigint;
DECLARE @dbo_nbs_answer_nbs_answer_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_17 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_17_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_18 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_18_output TABLE ([value] bigint);
DECLARE @dbo_Person_local_id_2 nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_5))) + N'GA01';
DECLARE @dbo_Public_health_case_local_id_2 nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_8))) + N'GA01';
DECLARE @dbo_case_management_case_management_uid_2 bigint;
DECLARE @dbo_case_management_case_management_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_message_log_message_log_uid_3 bigint;
DECLARE @dbo_message_log_message_log_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_19 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_19_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_20 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_20_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_21 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_21_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_22 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_22_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_23 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_23_output TABLE ([value] bigint);
DECLARE @dbo_CT_contact_local_id nvarchar(40) = N'CON' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_9))) + N'GA01';
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid bigint;
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_output TABLE ([value] bigint);
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_2 bigint;
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_3 bigint;
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_24 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_24_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_25 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_25_output TABLE ([value] bigint);
DECLARE @dbo_message_log_message_log_uid_4 bigint;
DECLARE @dbo_message_log_message_log_uid_4_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_30 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_30_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_26 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_26_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_27 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_27_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_31 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_31_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_32 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_32_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_33 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_33_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_34 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_34_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_28 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_28_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_35 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_35_output TABLE ([value] bigint);
DECLARE @dbo_message_log_message_log_uid_5 bigint;
DECLARE @dbo_message_log_message_log_uid_5_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_36 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_36_output TABLE ([value] bigint);
DECLARE @dbo_message_log_message_log_uid_6 bigint;
DECLARE @dbo_message_log_message_log_uid_6_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_37 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_37_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_38 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_38_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_39 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_39_output TABLE ([value] bigint);
DECLARE @dbo_message_log_message_log_uid_7 bigint;
DECLARE @dbo_message_log_message_log_uid_7_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_29 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_29_output TABLE ([value] bigint);
DECLARE @dbo_Notification_local_id nvarchar(40) = N'NOT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_10))) + N'GA01';
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_40 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_40_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_41 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_41_output TABLE ([value] bigint);

-- STEP 4: InvestigateSyphilisInitialFollowup
-- dbo.Participation
-- step: 4
UPDATE [dbo].[Participation] SET [from_time] = N'2026-04-17T00:00:00', [to_time] = N'2026-04-30T19:39:22.757' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';
-- step: 4
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003022, @dbo_Act_act_uid_5, N'PerAsReporterOfPHC', N'CASE', N'2026-04-30T19:32:00.637', @superuser_id, N'2026-04-30T19:39:22.653', @superuser_id, N'ACTIVE', N'2026-04-30T19:39:22.653', N'A', N'2026-04-30T19:39:22.653', N'PSN', N'PHC Reporter');
-- dbo.NBS_case_answer
-- step: 4
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_3_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'04/20/2026', 10001192, 3, N'2026-04-30T19:39:22.743', @superuser_id, N'OPEN', N'2026-04-30T19:39:22.743', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_3 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_3_output;
-- step: 4
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T19:39:22.743', [record_status_time] = N'2026-04-30T19:39:22.743' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid;
-- step: 4
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_4_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'720', 10001195, 3, N'2026-04-30T19:39:22.743', @superuser_id, N'OPEN', N'2026-04-30T19:39:22.743', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_4 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_4_output;
-- step: 4
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T19:39:22.743', [record_status_time] = N'2026-04-30T19:39:22.743' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_2;
-- dbo.NBS_act_entity
-- step: 4
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:39:22.743', [record_status_time] = N'2026-04-30T19:39:22.743' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_2;
-- step: 4
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:39:22.743', [record_status_time] = N'2026-04-30T19:39:22.743' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_3;
-- step: 4
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:39:22.743', [record_status_time] = N'2026-04-30T19:39:22.743' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_4;
-- step: 4
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_9_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003022, 1, N'2026-04-30T19:39:22.743', @superuser_id, N'OPEN', N'2026-04-30T19:39:22.743', N'PerAsReporterOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_9 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_9_output;
-- step: 4
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:39:22.743', [record_status_time] = N'2026-04-30T19:39:22.743' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid;
-- step: 4
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:39:22.743', [record_status_time] = N'2026-04-30T19:39:22.743' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_5;
-- dbo.Person
-- step: 4
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T19:39:22.713', [record_status_time] = N'2026-04-30T19:39:22.713', [status_time] = N'2026-04-30T19:39:22.713', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Entity_locator_participation
-- step: 4
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:39:22.713', [record_status_time] = N'2026-04-30T19:39:22.713', [status_time] = N'2026-04-30T19:39:22.713' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 4
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:39:22.713', [record_status_time] = N'2026-04-30T19:39:22.713', [status_time] = N'2026-04-30T19:39:22.713' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 4
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:39:22.713', [record_status_time] = N'2026-04-30T19:39:22.713', [status_time] = N'2026-04-30T19:39:22.713' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;
-- dbo.Person
-- step: 4
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T19:39:22.727', [record_status_time] = N'2026-04-30T19:39:22.727', [status_time] = N'2026-04-30T19:39:22.727', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_4;
-- dbo.Person_name
-- step: 4
UPDATE [dbo].[Person_name] SET [last_chg_time] = N'2026-04-30T19:39:22.630' WHERE [person_uid] = @dbo_Entity_entity_uid_4 AND [person_name_seq] = 1;
-- dbo.Entity_id
-- step: 4
UPDATE [dbo].[Entity_id] SET [last_chg_time] = N'2026-04-30T19:39:22.653' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_id_seq] = 1;
-- dbo.Postal_locator
-- step: 4
UPDATE [dbo].[Postal_locator] SET [last_chg_time] = N'2026-04-30T19:39:22.630', [last_chg_user_id] = @superuser_id, [street_addr2] = N'' WHERE [postal_locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;
-- dbo.Entity_locator_participation
-- step: 4
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:39:22.727', [record_status_time] = N'2026-04-30T19:39:22.727', [status_time] = N'2026-04-30T19:39:22.727' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;
-- dbo.Tele_locator
-- step: 4
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-04-30T19:39:22.630', [last_chg_user_id] = @superuser_id WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;
-- dbo.Entity_locator_participation
-- step: 4
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:39:22.727', [record_status_time] = N'2026-04-30T19:39:22.727', [status_time] = N'2026-04-30T19:39:22.727' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;
-- dbo.Tele_locator
-- step: 4
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-04-30T19:39:22.630', [last_chg_user_id] = @superuser_id WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;
-- dbo.Entity_locator_participation
-- step: 4
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:39:22.727', [record_status_time] = N'2026-04-30T19:39:22.727', [status_time] = N'2026-04-30T19:39:22.727' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;
-- dbo.Public_health_case
-- step: 4
UPDATE [dbo].[Public_health_case] SET [case_class_cd] = N'C', [cd] = N'10312', [cd_desc_txt] = N'Syphilis, secondary', [detection_method_cd] = N'21', [diagnosis_time] = N'2026-04-21T00:00:00', [effective_from_time] = N'2026-04-17T00:00:00', [last_chg_time] = N'2026-04-30T19:39:22.743', [pat_age_at_onset] = N'41', [pat_age_at_onset_unit_cd] = N'Y', [record_status_time] = N'2026-04-30T19:39:22.743', [transmission_mode_cd] = N'S', [transmission_mode_desc_txt] = N'S', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [hospitalized_ind_cd] = N'N' WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- dbo.Confirmation_method
-- step: 4
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_5, N'LD', N'2026-04-24T00:00:00');
-- dbo.Participation
-- step: 4
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T19:39:22.947', [last_chg_time] = N'2026-04-30T19:39:22.743', [record_status_time] = N'2026-04-30T19:39:22.743', [status_time] = N'2026-04-30T19:39:22.743', [to_time] = N'2026-04-30T19:39:22.947' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';
-- dbo.SubjectRaceInfo
-- step: 4
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_5 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';
-- dbo.PublicHealthCaseFact
-- step: 4
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- step: 4
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [onSetDate], [organizationName], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-24T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'21', N'Self Referral', N'2026-04-21T00:00:00', N'PST', N'2026-04-17T00:00:00', N'O', 1.0, N'O', N'Keable, Kristi', N'404-851-8000', N'130001', N'M', N'Married', N'2026-04-30T19:39:28.983', 17, 2026, N'2026-04-17T00:00:00', N'Emory University Hospital', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-04-30T19:32:00.637', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2026-04-30T19:32:00.493', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Nightingale, Florence', N'404-785-6000', N'2026-04-30T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-04-30T19:32:00.637', 10009283, @dbo_Person_local_id, N'2026-04-30T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Open', N'Years', N'STD', N' Laboratory confirmed', N'2026-04-30T19:39:22.743', N'N');
-- dbo.SubjectRaceInfo
-- step: 4
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');
