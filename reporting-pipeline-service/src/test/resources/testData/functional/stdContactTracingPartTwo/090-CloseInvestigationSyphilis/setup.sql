USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 1000009000;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 1000009001;
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 1000009002;
DECLARE @dbo_Tele_locator_tele_locator_uid_2 bigint = 1000009003;
DECLARE @dbo_Entity_entity_uid_2 bigint = 1000009004;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 1000009005;
DECLARE @dbo_Tele_locator_tele_locator_uid_3 bigint = 1000009006;
DECLARE @dbo_Tele_locator_tele_locator_uid_4 bigint = 1000009007;
DECLARE @dbo_Act_act_uid bigint = 1000009008;
DECLARE @dbo_Act_act_uid_2 bigint = 1000009009;
DECLARE @dbo_Act_act_uid_3 bigint = 1000009010;
DECLARE @dbo_Act_act_uid_4 bigint = 1000009011;
DECLARE @dbo_Entity_entity_uid_3 bigint = 1000009012;
DECLARE @dbo_Entity_entity_uid_4 bigint = 1000009013;
DECLARE @dbo_Postal_locator_postal_locator_uid_3 bigint = 1000009014;
DECLARE @dbo_Tele_locator_tele_locator_uid_5 bigint = 1000009015;
DECLARE @dbo_Tele_locator_tele_locator_uid_6 bigint = 1000009016;
DECLARE @dbo_Act_act_uid_5 bigint = 1000009017;
DECLARE @dbo_Act_act_uid_6 bigint = 1000009018;
DECLARE @dbo_Act_act_uid_7 bigint = 1000009019;
DECLARE @dbo_Entity_entity_uid_5 bigint = 1000009020;
DECLARE @dbo_Postal_locator_postal_locator_uid_4 bigint = 1000009021;
DECLARE @dbo_Entity_entity_uid_6 bigint = 1000009022;
DECLARE @dbo_Postal_locator_postal_locator_uid_5 bigint = 1000009023;
DECLARE @dbo_Act_act_uid_8 bigint = 1000009024;
DECLARE @dbo_Entity_entity_uid_7 bigint = 1000009025;
DECLARE @dbo_Postal_locator_postal_locator_uid_6 bigint = 1000009026;
DECLARE @dbo_Act_act_uid_9 bigint = 1000009027;
DECLARE @dbo_Act_act_uid_10 bigint = 1000009028;
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
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_6 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_6_output TABLE ([value] bigint);
DECLARE @dbo_Treatment_local_id nvarchar(40) = N'TRT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_6))) + N'GA01';
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_7 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_7_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_8 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_8_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_9 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_9_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_4 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_4_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_10 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_10_output TABLE ([value] bigint);
DECLARE @dbo_message_log_message_log_uid_2 bigint;
DECLARE @dbo_message_log_message_log_uid_2_output TABLE ([value] bigint);
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
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_17 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_17_output TABLE ([value] bigint);
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
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_18 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_18_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_19 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_19_output TABLE ([value] bigint);
DECLARE @dbo_Person_local_id_2 nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_5))) + N'GA01';
DECLARE @dbo_Public_health_case_local_id_2 nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_8))) + N'GA01';
DECLARE @dbo_case_management_case_management_uid_2 bigint;
DECLARE @dbo_case_management_case_management_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_message_log_message_log_uid_3 bigint;
DECLARE @dbo_message_log_message_log_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_20 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_20_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_21 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_21_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_22 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_22_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_23 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_23_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_24 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_24_output TABLE ([value] bigint);
DECLARE @dbo_CT_contact_local_id nvarchar(40) = N'CON' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_9))) + N'GA01';
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid bigint;
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_output TABLE ([value] bigint);
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_2 bigint;
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_3 bigint;
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_25 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_25_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_26 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_26_output TABLE ([value] bigint);
DECLARE @dbo_message_log_message_log_uid_4 bigint;
DECLARE @dbo_message_log_message_log_uid_4_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_30 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_30_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_27 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_27_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_28 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_28_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_31 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_31_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_32 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_32_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_33 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_33_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_34 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_34_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_29 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_29_output TABLE ([value] bigint);
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
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_30 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_30_output TABLE ([value] bigint);
DECLARE @dbo_Notification_local_id nvarchar(40) = N'NOT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_10))) + N'GA01';
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_40 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_40_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_41 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_41_output TABLE ([value] bigint);

-- STEP 9: Close investigation
-- dbo.Participation
-- step: 9
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_5, N'ClosureInvestgrOfPHC', N'CASE', N'2026-05-06T22:11:00.673', @superuser_id, N'2026-05-06T23:00:20.310', @superuser_id, N'ACTIVE', N'2026-05-06T23:00:20.310', N'A', N'2026-05-06T23:00:20.310', N'PSN');
-- dbo.NBS_case_answer
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10001013 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:11:00.673' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:11:00.673' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'04/24/2026' AND [nbs_question_uid] = 10001326 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10001327 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'Y' AND [nbs_question_uid] = 10001325 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'R' AND [nbs_question_uid] = 10001285 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10001331 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10001283 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'Y' AND [nbs_question_uid] = 10001289 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'5' AND [nbs_question_uid] = 10001290 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'2' AND [nbs_question_uid] = 10003231 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10001316 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'Y' AND [nbs_question_uid] = 10001287 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10003230 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'2' AND [nbs_question_uid] = 10001288 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_33_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'1', 10003228, 3, N'2026-05-06T23:00:20.390', @superuser_id, N'OPEN', N'2026-05-06T23:00:20.390', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_33 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_33_output;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'Y' AND [nbs_question_uid] = 10001302 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10001295 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'30' AND [nbs_question_uid] = 10001252 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:11:00.673' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:11:00.673' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10001291 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'Y' AND [nbs_question_uid] = 10001296 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'1' AND [nbs_question_uid] = 10001297 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'7' AND [nbs_question_uid] = 10001293 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10001300 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10001322 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'Y' AND [nbs_question_uid] = 10001298 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'04/20/2026' AND [nbs_question_uid] = 10001192 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:21:08.813' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:21:08.813' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'2' AND [nbs_question_uid] = 10001299 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10001294 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'720' AND [nbs_question_uid] = 10001195 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:21:08.813' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:21:08.813' AND [seq_nbr] = 0);
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'1' AND [nbs_question_uid] = 10001321 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:36:22.750' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:36:22.750' AND [seq_nbr] = 0);
-- step: 9
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_34_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'Ariella Kent~05/06/2026 19:00~~finished gathering information about this case', 10001240, 3, N'2026-05-06T23:00:20.390', @superuser_id, N'OPEN', N'2026-05-06T23:00:20.390', 0, 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_34 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_34_output;
-- dbo.NBS_act_entity
-- step: 9
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_29_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003004, 1, N'2026-05-06T23:00:20.390', @superuser_id, N'OPEN', N'2026-05-06T23:00:20.390', N'ClosureInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_29 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_29_output;
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'DispoFldFupInvestgrOfPHC');
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003013 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'FldFupInvestgrOfPHC');
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'FldFupSupervisorOfPHC');
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003013 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitFldFupInvestgrOfPHC');
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003010 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitFupInvestgrOfPHC');
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitInterviewerOfPHC');
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InterviewerOfPHC');
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InvestgrOfPHC');
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003019 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'OrgAsClinicOfPHC');
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003019 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'OrgAsReporterOfPHC');
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003022 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'PerAsReporterOfPHC');
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [entity_version_ctrl_nbr] = 4, [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'SubjOfPHC');
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003010 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'SurvInvestgrOfPHC');
-- dbo.Person
-- step: 9
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T23:00:20.360', [record_status_time] = N'2026-05-06T23:00:20.360', [status_time] = N'2026-05-06T23:00:20.360', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Entity_locator_participation
-- step: 9
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T23:00:20.360', [record_status_time] = N'2026-05-06T23:00:20.360', [status_time] = N'2026-05-06T23:00:20.360' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 9
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T23:00:20.360', [record_status_time] = N'2026-05-06T23:00:20.360', [status_time] = N'2026-05-06T23:00:20.360' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 9
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T23:00:20.360', [record_status_time] = N'2026-05-06T23:00:20.360', [status_time] = N'2026-05-06T23:00:20.360' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;
-- dbo.Person
-- step: 9
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T23:00:20.373', [record_status_time] = N'2026-05-06T23:00:20.373', [status_time] = N'2026-05-06T23:00:20.373', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_4;
-- dbo.Person_name
-- step: 9
UPDATE [dbo].[Person_name] SET [last_chg_time] = N'2026-05-06T23:00:20.287' WHERE [person_uid] = @dbo_Entity_entity_uid_4 AND [person_name_seq] = 1;
-- dbo.Entity_id
-- step: 9
UPDATE [dbo].[Entity_id] SET [last_chg_time] = N'2026-05-06T23:00:20.310' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_id_seq] = 1;
-- dbo.Postal_locator
-- step: 9
UPDATE [dbo].[Postal_locator] SET [last_chg_time] = N'2026-05-06T23:00:20.287' WHERE [postal_locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;
-- dbo.Entity_locator_participation
-- step: 9
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T23:00:20.373', [record_status_time] = N'2026-05-06T23:00:20.373', [status_time] = N'2026-05-06T23:00:20.373' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;
-- dbo.Tele_locator
-- step: 9
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-05-06T23:00:20.287' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;
-- dbo.Entity_locator_participation
-- step: 9
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T23:00:20.373', [record_status_time] = N'2026-05-06T23:00:20.373', [status_time] = N'2026-05-06T23:00:20.373' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;
-- dbo.Tele_locator
-- step: 9
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-05-06T23:00:20.287' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;
-- dbo.Entity_locator_participation
-- step: 9
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T23:00:20.373', [record_status_time] = N'2026-05-06T23:00:20.373', [status_time] = N'2026-05-06T23:00:20.373' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;
-- dbo.Public_health_case
-- step: 9
UPDATE [dbo].[Public_health_case] SET [activity_to_time] = N'2026-04-27T00:00:00', [investigation_status_cd] = N'C', [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [curr_process_state_cd] = N'CC' WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- dbo.Confirmation_method
-- step: 9
DELETE FROM [dbo].[Confirmation_method] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5 AND [confirmation_method_cd] = N'LD';
-- step: 9
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_5, N'LD', N'2026-04-24T00:00:00');
-- dbo.case_management
-- step: 9
UPDATE [dbo].[case_management] SET [case_review_status] = N'Ready', [case_closed_date] = N'2026-04-27T00:00:00', [case_review_status_date] = N'2026-05-06T23:00:20.310' WHERE [case_management_uid] = (SELECT TOP 1 [case_management_uid] FROM [dbo].[case_management] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5 AND [epi_link_id] = N'1310000026' AND [field_record_number] = N'1310000026' AND [init_foll_up] = N'SF' AND [surv_assigned_date] = N'2026-04-24T00:00:00');
-- dbo.Participation
-- step: 9
UPDATE [dbo].[Participation] SET [add_time] = N'2026-05-06T23:00:20.573', [last_chg_time] = N'2026-05-06T23:00:20.390', [record_status_time] = N'2026-05-06T23:00:20.390', [status_time] = N'2026-05-06T23:00:20.390' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';
-- dbo.SubjectRaceInfo
-- step: 9
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_5 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';
-- dbo.PublicHealthCaseFact
-- step: 9
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- step: 9
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [onSetDate], [organizationName], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-24T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'21', N'Self Referral', N'2026-04-21T00:00:00', N'PST', N'2026-04-17T00:00:00', N'O', 1.0, N'C', N'Xerogeanes, John', N'404-778-3350', N'130001', N'M', N'Married', N'2026-05-06T23:00:28.980', 18, 2026, N'2026-04-17T00:00:00', N'Emory University Hospital', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-05-06T22:11:00.673', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2026-05-06T22:11:00.547', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Nightingale, Florence', N'404-785-6000', N'2026-05-06T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-05-06T22:11:00.673', 10009283, @dbo_Person_local_id, N'2026-05-06T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Closed', N'Years', N'STD', N' Laboratory confirmed', N'2026-05-06T23:00:20.390', N'N');
-- dbo.SubjectRaceInfo
-- step: 9
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');
