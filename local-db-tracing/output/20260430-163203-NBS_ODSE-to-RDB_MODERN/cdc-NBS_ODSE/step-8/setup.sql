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

-- STEP 8: ChangeContactInvestigationDisposition
-- dbo.message_log
-- step: 8
INSERT INTO [dbo].[message_log] ([message_txt], [condition_cd], [person_uid], [assigned_to_uid], [event_uid], [event_type_cd], [message_status_cd], [record_status_cd], [record_status_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[message_log_uid] INTO @dbo_message_log_message_log_uid_4_output ([value]) VALUES (N'Disposition specified for all Contacts', N'10312', @dbo_Entity_entity_uid, 10003004, 10009300, N'Investigation', N'N', N'ACTIVE', N'2026-04-30T19:50:49.327', N'2026-04-30T19:50:49.327', @superuser_id, N'2026-04-30T19:50:49.327', @superuser_id);
SELECT TOP 1 @dbo_message_log_message_log_uid_4 = [value] FROM @dbo_message_log_message_log_uid_4_output;
-- dbo.Participation
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:02:59.267', [last_chg_time] = N'2026-04-30T20:02:59.267', [to_time] = N'2026-04-30T20:02:59.267' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_6 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'SubjOfPHC';
-- step: 8
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_8, N'DispoFldFupInvestgrOfPHC', N'CASE', N'2026-04-30T19:57:57.590', @superuser_id, N'2026-04-30T20:02:59.210', @superuser_id, N'ACTIVE', N'2026-04-30T20:02:59.210', N'A', N'2026-04-30T20:02:59.210', N'PSN');
-- step: 8
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003013, @dbo_Act_act_uid_8, N'FldFupSupervisorOfPHC', N'CASE', N'2026-04-30T19:57:57.590', @superuser_id, N'2026-04-30T20:02:59.210', @superuser_id, N'ACTIVE', N'2026-04-30T20:02:59.210', N'A', N'2026-04-30T20:02:59.210', N'PSN');
-- dbo.NBS_case_answer
-- step: 8
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_30_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, N'Ariella Kent~04/30/2026 16:02~~he wasn''t in the park anymore. we don''t know where he is.', 10001240, 3, N'2026-04-30T20:02:59.263', @superuser_id, N'OPEN', N'2026-04-30T20:02:59.263', 0, 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_30 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_30_output;
-- dbo.NBS_act_entity
-- step: 8
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_26_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, 10003004, 1, N'2026-04-30T20:02:59.263', @superuser_id, N'OPEN', N'2026-04-30T20:02:59.263', N'DispoFldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_26 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_26_output;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:02:59.263', [record_status_time] = N'2026-04-30T20:02:59.263' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_23;
-- step: 8
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_27_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, 10003013, 1, N'2026-04-30T20:02:59.263', @superuser_id, N'OPEN', N'2026-04-30T20:02:59.263', N'FldFupSupervisorOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_27 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_27_output;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:02:59.263', [record_status_time] = N'2026-04-30T20:02:59.263' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_22;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:02:59.263', [record_status_time] = N'2026-04-30T20:02:59.263' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_21;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:02:59.263', [record_status_time] = N'2026-04-30T20:02:59.263' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_20;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:02:59.263', [record_status_time] = N'2026-04-30T20:02:59.263' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_19;
-- dbo.CT_contact
-- step: 8
UPDATE [dbo].[CT_contact] SET [disposition_cd] = N'H', [disposition_date] = N'2026-04-27T00:00:00' WHERE [ct_contact_uid] = @dbo_Act_act_uid_9;
-- dbo.Person
-- step: 8
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:02:59.240', [record_status_time] = N'2026-04-30T20:02:59.240', [status_time] = N'2026-04-30T20:02:59.240', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_5;
-- dbo.Entity_locator_participation
-- step: 8
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:02:59.240', [record_status_time] = N'2026-04-30T20:02:59.240', [status_time] = N'2026-04-30T20:02:59.240' WHERE [entity_uid] = @dbo_Entity_entity_uid_5 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_4;
-- dbo.Person
-- step: 8
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:02:59.247', [record_status_time] = N'2026-04-30T20:02:59.247', [status_time] = N'2026-04-30T20:02:59.247', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_6;
-- dbo.Person_name
-- step: 8
UPDATE [dbo].[Person_name] SET [last_chg_time] = N'2026-04-30T20:02:58.953' WHERE [person_uid] = @dbo_Entity_entity_uid_6 AND [person_name_seq] = 1;
-- dbo.Entity_locator_participation
-- step: 8
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:02:59.247', [record_status_cd] = N'INACTIVE', [record_status_time] = N'2026-04-30T20:02:59.247', [status_cd] = N'I', [status_time] = N'2026-04-30T20:02:59.247' WHERE [entity_uid] = @dbo_Entity_entity_uid_6 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_5;
-- dbo.Public_health_case
-- step: 8
UPDATE [dbo].[Public_health_case] SET [activity_to_time] = N'2026-04-27T00:00:00', [investigation_status_cd] = N'C', [last_chg_time] = N'2026-04-30T20:02:59.263', [outbreak_ind] = N'', [outbreak_name] = N'', [outcome_cd] = N'', [pat_age_at_onset] = N'', [pat_age_at_onset_unit_cd] = N'', [record_status_time] = N'2026-04-30T20:02:59.263', [rpt_source_cd] = N'', [transmission_mode_cd] = N'', [transmission_mode_desc_txt] = N'', [txt] = N'', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [pregnant_ind_cd] = N'', [priority_cd] = N'' WHERE [public_health_case_uid] = @dbo_Act_act_uid_8;
-- dbo.case_management
-- step: 8
UPDATE [dbo].[case_management] SET [fld_foll_up_dispo] = N'H', [fld_foll_up_dispo_date] = N'2026-04-27T00:00:00', [case_review_status] = N'Ready', [case_review_status_date] = N'2026-04-30T20:02:58.980' WHERE [case_management_uid] = @dbo_case_management_case_management_uid_2;
-- dbo.Participation
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:02:59.400', [last_chg_time] = N'2026-04-30T20:02:59.263', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-04-30T20:02:59.263', [status_time] = N'2026-04-30T20:02:59.263', [to_time] = N'2026-04-30T20:02:59.400' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_6 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'SubjOfPHC';
-- dbo.NBS_case_answer
-- step: 8
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_31_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, N'Ariella Kent~04/30/2026 20:03~~the neighbors think he left the country', 10001241, 1, N'2026-04-30T20:03:00.800', @superuser_id, N'OPEN', N'2026-04-30T20:02:59.263', 0, 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_31 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_31_output;
-- dbo.NBS_act_entity
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.800' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_19;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.800' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_20;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.800' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_21;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.800' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_22;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.800' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_23;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.800' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_26;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.800' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_27;
-- dbo.NBS_case_answer
-- step: 8
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_32_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, N'Ariella Kent~04/30/2026 20:03~~the neighbors think he left the country', 10001241, 1, N'2026-04-30T20:03:00.873', @superuser_id, N'OPEN', N'2026-04-30T20:03:00.873', 0, 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_32 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_32_output;
-- dbo.NBS_act_entity
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.873', [record_status_time] = N'2026-04-30T20:03:00.873' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_19;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.873', [record_status_time] = N'2026-04-30T20:03:00.873' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_20;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.873', [record_status_time] = N'2026-04-30T20:03:00.873' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_21;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.873', [record_status_time] = N'2026-04-30T20:03:00.873' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_22;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.873', [record_status_time] = N'2026-04-30T20:03:00.873' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_23;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.873', [record_status_time] = N'2026-04-30T20:03:00.873' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_26;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:03:00.873', [record_status_time] = N'2026-04-30T20:03:00.873' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_27;
-- dbo.Person
-- step: 8
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:03:00.863', [record_status_time] = N'2026-04-30T20:03:00.863', [status_time] = N'2026-04-30T20:03:00.863', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_5;
-- dbo.Entity_locator_participation
-- step: 8
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:03:00.863', [record_status_time] = N'2026-04-30T20:03:00.863', [status_time] = N'2026-04-30T20:03:00.863' WHERE [entity_uid] = @dbo_Entity_entity_uid_5 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_4;
-- dbo.Person
-- step: 8
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:03:00.867', [record_status_time] = N'2026-04-30T20:03:00.867', [status_time] = N'2026-04-30T20:03:00.867', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_6;
-- dbo.Public_health_case
-- step: 8
UPDATE [dbo].[Public_health_case] SET [last_chg_time] = N'2026-04-30T20:03:00.873', [record_status_time] = N'2026-04-30T20:03:00.873', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [public_health_case_uid] = @dbo_Act_act_uid_8;
-- dbo.case_management
-- step: 8
UPDATE [dbo].[case_management] SET [case_review_status] = N'Accept' WHERE [case_management_uid] = @dbo_case_management_case_management_uid_2;
-- dbo.Participation
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:03:00.900', [last_chg_time] = N'2026-04-30T20:03:00.873', [record_status_time] = N'2026-04-30T20:03:00.873', [status_time] = N'2026-04-30T20:03:00.873', [to_time] = N'2026-04-30T20:03:00.900' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'DispoFldFupInvestgrOfPHC';
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:03:00.900', [last_chg_time] = N'2026-04-30T20:03:00.873', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-04-30T20:03:00.873', [status_time] = N'2026-04-30T20:03:00.873', [to_time] = N'2026-04-30T20:03:00.900' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'FldFupInvestgrOfPHC';
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:03:00.900', [last_chg_time] = N'2026-04-30T20:03:00.873', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-04-30T20:03:00.873', [status_time] = N'2026-04-30T20:03:00.873', [to_time] = N'2026-04-30T20:03:00.900' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'InitFldFupInvestgrOfPHC';
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:03:00.900', [last_chg_time] = N'2026-04-30T20:03:00.873', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-04-30T20:03:00.873', [status_time] = N'2026-04-30T20:03:00.873', [to_time] = N'2026-04-30T20:03:00.900' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'InitFupInvestgrOfPHC';
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:03:00.900', [last_chg_time] = N'2026-04-30T20:03:00.873', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-04-30T20:03:00.873', [status_time] = N'2026-04-30T20:03:00.873', [to_time] = N'2026-04-30T20:03:00.900' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'InvestgrOfPHC';
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:03:00.900', [last_chg_time] = N'2026-04-30T20:03:00.873', [record_status_time] = N'2026-04-30T20:03:00.873', [status_time] = N'2026-04-30T20:03:00.873', [to_time] = N'2026-04-30T20:03:00.900' WHERE [subject_entity_uid] = 10003013 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'FldFupSupervisorOfPHC';
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:03:00.900', [last_chg_time] = N'2026-04-30T20:03:00.873', [record_status_time] = N'2026-04-30T20:03:00.873', [status_time] = N'2026-04-30T20:03:00.873' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_6 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'SubjOfPHC';
-- dbo.SubjectRaceInfo
-- step: 8
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_8 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';
-- dbo.PublicHealthCaseFact
-- step: 8
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_8;
-- step: 8
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [case_class_cd], [case_type_cd], [curr_sex_cd], [deceased_ind_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorAssigneddate], [investigatorName], [investigatorPhone], [jurisdiction_cd], [mart_record_creation_time], [mmwr_week], [mmwr_year], [PAR_type_cd], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [shared_ind], [status_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [LOCAL_ID], [curr_sex_desc_txt], [investigation_status_desc_txt], [prog_area_desc_txt], [LASTUPDATE]) VALUES (@dbo_Act_act_uid_8, N'', N'I', N'M', N'N', N'2026-04-30T19:57:57.590', N'P', 1.0, N'C', N'2026-04-25T00:00:00', N'Xerogeanes, John', N'404-778-3350', N'130001', N'2026-04-30T20:03:07.313', 16, 2026, N'SubjOfPHC', N'PAT', @dbo_Entity_entity_uid_6, N'2026-04-30T19:57:57.590', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2106-3', N'White', N'OPEN', N'T', N'A', N', FredContact', N'Fulton County', N'2026-04-25T00:00:00', 1300100015, N'2026-04-30T19:57:57.590', 10009303, @dbo_Person_local_id_2, @dbo_Public_health_case_local_id_2, N'Male', N'Closed', N'STD', N'2026-04-30T20:03:00.873');
-- dbo.SubjectRaceInfo
-- step: 8
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_8, N'2106-3', N'2106-3');
-- step: 8
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_8 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';
-- dbo.PublicHealthCaseFact
-- step: 8
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_8;
-- step: 8
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [case_class_cd], [case_type_cd], [curr_sex_cd], [deceased_ind_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorAssigneddate], [investigatorName], [investigatorPhone], [jurisdiction_cd], [mart_record_creation_time], [mmwr_week], [mmwr_year], [PAR_type_cd], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [shared_ind], [status_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [LOCAL_ID], [curr_sex_desc_txt], [investigation_status_desc_txt], [prog_area_desc_txt], [LASTUPDATE]) VALUES (@dbo_Act_act_uid_8, N'', N'I', N'M', N'N', N'2026-04-30T19:57:57.590', N'P', 1.0, N'C', N'2026-04-25T00:00:00', N'Xerogeanes, John', N'404-778-3350', N'130001', N'2026-04-30T20:03:07.610', 16, 2026, N'SubjOfPHC', N'PAT', @dbo_Entity_entity_uid_6, N'2026-04-30T19:57:57.590', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2106-3', N'White', N'OPEN', N'T', N'A', N', FredContact', N'Fulton County', N'2026-04-25T00:00:00', 1300100015, N'2026-04-30T19:57:57.590', 10009303, @dbo_Person_local_id_2, @dbo_Public_health_case_local_id_2, N'Male', N'Closed', N'STD', N'2026-04-30T20:03:00.873');
-- dbo.SubjectRaceInfo
-- step: 8
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_8, N'2106-3', N'2106-3');
