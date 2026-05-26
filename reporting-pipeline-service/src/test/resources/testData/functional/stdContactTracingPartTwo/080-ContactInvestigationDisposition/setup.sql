USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 3400000;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 3400001;
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 3400002;
DECLARE @dbo_Tele_locator_tele_locator_uid_2 bigint = 3400003;
DECLARE @dbo_Entity_entity_uid_2 bigint = 3400004;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 3400005;
DECLARE @dbo_Tele_locator_tele_locator_uid_3 bigint = 3400006;
DECLARE @dbo_Tele_locator_tele_locator_uid_4 bigint = 3400007;
DECLARE @dbo_Act_act_uid bigint = 3400008;
DECLARE @dbo_Act_act_uid_2 bigint = 3400009;
DECLARE @dbo_Act_act_uid_3 bigint = 3400010;
DECLARE @dbo_Act_act_uid_4 bigint = 3400011;
DECLARE @dbo_Entity_entity_uid_3 bigint = 3400012;
DECLARE @dbo_Entity_entity_uid_4 bigint = 3400013;
DECLARE @dbo_Postal_locator_postal_locator_uid_3 bigint = 3400014;
DECLARE @dbo_Tele_locator_tele_locator_uid_5 bigint = 3400015;
DECLARE @dbo_Tele_locator_tele_locator_uid_6 bigint = 3400016;
DECLARE @dbo_Act_act_uid_5 bigint = 3400017;
DECLARE @dbo_Act_act_uid_6 bigint = 3400018;
DECLARE @dbo_Act_act_uid_7 bigint = 3400019;
DECLARE @dbo_Entity_entity_uid_5 bigint = 3400020;
DECLARE @dbo_Postal_locator_postal_locator_uid_4 bigint = 3400021;
DECLARE @dbo_Entity_entity_uid_6 bigint = 3400022;
DECLARE @dbo_Postal_locator_postal_locator_uid_5 bigint = 3400023;
DECLARE @dbo_Act_act_uid_8 bigint = 3400024;
DECLARE @dbo_Entity_entity_uid_7 bigint = 3400025;
DECLARE @dbo_Postal_locator_postal_locator_uid_6 bigint = 3400026;
DECLARE @dbo_Act_act_uid_9 bigint = 3400027;
DECLARE @dbo_Act_act_uid_10 bigint = 3400028;
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

-- STEP 8: Disposition and Close Contact investigation
-- dbo.message_log
-- step: 8
INSERT INTO [dbo].[message_log] ([message_txt], [condition_cd], [person_uid], [assigned_to_uid], [event_uid], [event_type_cd], [message_status_cd], [record_status_cd], [record_status_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[message_log_uid] INTO @dbo_message_log_message_log_uid_4_output ([value]) VALUES (N'Disposition specified for all Contacts', N'10312', @dbo_Entity_entity_uid, 10003004, 10009300, N'Investigation', N'N', N'ACTIVE', N'2026-05-06T22:36:22.750', N'2026-05-06T22:36:22.750', @superuser_id, N'2026-05-06T22:36:22.750', @superuser_id);
SELECT TOP 1 @dbo_message_log_message_log_uid_4 = [value] FROM @dbo_message_log_message_log_uid_4_output;
-- dbo.Participation
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-05-06T22:51:39.063', [last_chg_time] = N'2026-05-06T22:51:39.063', [to_time] = N'2026-05-06T22:51:39.063' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_6 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'SubjOfPHC';
-- step: 8
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_8, N'DispoFldFupInvestgrOfPHC', N'CASE', N'2026-05-06T22:43:44.750', @superuser_id, N'2026-05-06T22:51:38.997', @superuser_id, N'ACTIVE', N'2026-05-06T22:51:38.997', N'A', N'2026-05-06T22:51:38.997', N'PSN');
-- step: 8
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003013, @dbo_Act_act_uid_8, N'FldFupSupervisorOfPHC', N'CASE', N'2026-05-06T22:43:44.750', @superuser_id, N'2026-05-06T22:51:38.997', @superuser_id, N'ACTIVE', N'2026-05-06T22:51:38.997', N'A', N'2026-05-06T22:51:38.997', N'PSN');
-- dbo.NBS_case_answer
-- step: 8
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_30_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-05-06T22:43:44.750', @superuser_id, N'Ariella Kent~05/06/2026 18:51~~he wasn''t in the park anymore. we don''t know where he is.', 10001240, 3, N'2026-05-06T22:51:39.050', @superuser_id, N'OPEN', N'2026-05-06T22:51:39.050', 0, 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_30 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_30_output;
-- dbo.NBS_act_entity
-- step: 8
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_27_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-05-06T22:43:44.750', @superuser_id, 10003004, 1, N'2026-05-06T22:51:39.050', @superuser_id, N'OPEN', N'2026-05-06T22:51:39.050', N'DispoFldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_27 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_27_output;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:39.050', [record_status_time] = N'2026-05-06T22:51:39.050' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'FldFupInvestgrOfPHC');
-- step: 8
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_28_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-05-06T22:43:44.750', @superuser_id, 10003013, 1, N'2026-05-06T22:51:39.050', @superuser_id, N'OPEN', N'2026-05-06T22:51:39.050', N'FldFupSupervisorOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_28 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_28_output;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:39.050', [record_status_time] = N'2026-05-06T22:51:39.050' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitFldFupInvestgrOfPHC');
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:39.050', [record_status_time] = N'2026-05-06T22:51:39.050' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitFupInvestgrOfPHC');
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:39.050', [record_status_time] = N'2026-05-06T22:51:39.050' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InvestgrOfPHC');
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:39.050', [record_status_time] = N'2026-05-06T22:51:39.050' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = @dbo_Entity_entity_uid_6 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'SubjOfPHC');
-- dbo.CT_contact
-- step: 8
UPDATE [dbo].[CT_contact] SET [disposition_cd] = N'H', [disposition_date] = N'2026-04-27T00:00:00' WHERE [ct_contact_uid] = @dbo_Act_act_uid_9;
-- dbo.Person
-- step: 8
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T22:51:39.030', [record_status_time] = N'2026-05-06T22:51:39.030', [status_time] = N'2026-05-06T22:51:39.030', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_5;
-- dbo.Entity_locator_participation
-- step: 8
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:51:39.030', [record_status_time] = N'2026-05-06T22:51:39.030', [status_time] = N'2026-05-06T22:51:39.030' WHERE [entity_uid] = @dbo_Entity_entity_uid_5 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_4;
-- dbo.Person
-- step: 8
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T22:51:39.037', [record_status_time] = N'2026-05-06T22:51:39.037', [status_time] = N'2026-05-06T22:51:39.037', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_6;
-- dbo.Person_name
-- step: 8
UPDATE [dbo].[Person_name] SET [last_chg_time] = N'2026-05-06T22:51:38.753' WHERE [person_uid] = @dbo_Entity_entity_uid_6 AND [person_name_seq] = 1;
-- dbo.Entity_locator_participation
-- step: 8
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:51:39.037', [record_status_cd] = N'INACTIVE', [record_status_time] = N'2026-05-06T22:51:39.037', [status_cd] = N'I', [status_time] = N'2026-05-06T22:51:39.037' WHERE [entity_uid] = @dbo_Entity_entity_uid_6 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_5;
-- dbo.Public_health_case
-- step: 8
UPDATE [dbo].[Public_health_case] SET [activity_to_time] = N'2026-04-27T00:00:00', [investigation_status_cd] = N'C', [last_chg_time] = N'2026-05-06T22:51:39.050', [outbreak_ind] = N'', [outbreak_name] = N'', [outcome_cd] = N'', [pat_age_at_onset] = N'', [pat_age_at_onset_unit_cd] = N'', [record_status_time] = N'2026-05-06T22:51:39.050', [rpt_source_cd] = N'', [transmission_mode_cd] = N'', [transmission_mode_desc_txt] = N'', [txt] = N'', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [pregnant_ind_cd] = N'', [priority_cd] = N'' WHERE [public_health_case_uid] = @dbo_Act_act_uid_8;
-- dbo.case_management
-- step: 8
UPDATE [dbo].[case_management] SET [fld_foll_up_dispo] = N'H', [fld_foll_up_dispo_date] = N'2026-04-27T00:00:00', [case_review_status] = N'Ready', [case_review_status_date] = N'2026-05-06T22:51:38.777' WHERE [case_management_uid] = (SELECT TOP 1 [case_management_uid] FROM [dbo].[case_management] WHERE [public_health_case_uid] = @dbo_Act_act_uid_8 AND [epi_link_id] = N'1310000026' AND [field_record_number] = N'1310000126' AND [init_foll_up] = N'FF' AND [init_foll_up_notifiable] = N'06' AND [internet_foll_up] = N'' AND [subj_complexion] = N'' AND [subj_hair] = N'' AND [subj_height] = N'' AND [subj_oth_idntfyng_info] = N'' AND [subj_size_build] = N'' AND [foll_up_assigned_date] = N'2026-04-25T00:00:00' AND [init_foll_up_assigned_date] = N'2026-04-25T00:00:00');
-- dbo.Participation
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-05-06T22:51:39.210', [last_chg_time] = N'2026-05-06T22:51:39.050', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-05-06T22:51:39.050', [status_time] = N'2026-05-06T22:51:39.050', [to_time] = N'2026-05-06T22:51:39.210' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_6 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'SubjOfPHC';
-- dbo.NBS_case_answer
-- step: 8
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_31_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-05-06T22:43:44.750', @superuser_id, N'Ariella Kent~05/06/2026 22:51~~the neighbors think he left the country', 10001241, 1, N'2026-05-06T22:51:40.207', @superuser_id, N'OPEN', N'2026-05-06T22:51:39.050', 0, 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_31 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_31_output;
-- dbo.NBS_act_entity
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.207' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = @dbo_Entity_entity_uid_6 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'SubjOfPHC');
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.207' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InvestgrOfPHC');
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.207' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitFupInvestgrOfPHC');
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.207' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitFldFupInvestgrOfPHC');
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.207' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'FldFupInvestgrOfPHC');
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.207' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_27;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.207' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_28;
-- dbo.NBS_case_answer
-- step: 8
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_32_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-05-06T22:43:44.750', @superuser_id, N'Ariella Kent~05/06/2026 22:51~~the neighbors think he left the country', 10001241, 1, N'2026-05-06T22:51:40.267', @superuser_id, N'OPEN', N'2026-05-06T22:51:40.267', 0, 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_32 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_32_output;
-- dbo.NBS_act_entity
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.267', [record_status_time] = N'2026-05-06T22:51:40.267' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = @dbo_Entity_entity_uid_6 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'SubjOfPHC');
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.267', [record_status_time] = N'2026-05-06T22:51:40.267' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InvestgrOfPHC');
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.267', [record_status_time] = N'2026-05-06T22:51:40.267' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitFupInvestgrOfPHC');
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.267', [record_status_time] = N'2026-05-06T22:51:40.267' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitFldFupInvestgrOfPHC');
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.267', [record_status_time] = N'2026-05-06T22:51:40.267' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_8 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'FldFupInvestgrOfPHC');
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.267', [record_status_time] = N'2026-05-06T22:51:40.267' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_27;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:51:40.267', [record_status_time] = N'2026-05-06T22:51:40.267' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_28;
-- dbo.Person
-- step: 8
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T22:51:40.257', [record_status_time] = N'2026-05-06T22:51:40.257', [status_time] = N'2026-05-06T22:51:40.257', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_5;
-- dbo.Entity_locator_participation
-- step: 8
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:51:40.257', [record_status_time] = N'2026-05-06T22:51:40.257', [status_time] = N'2026-05-06T22:51:40.257' WHERE [entity_uid] = @dbo_Entity_entity_uid_5 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_4;
-- dbo.Person
-- step: 8
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T22:51:40.260', [record_status_time] = N'2026-05-06T22:51:40.260', [status_time] = N'2026-05-06T22:51:40.260', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_6;
-- dbo.Public_health_case
-- step: 8
UPDATE [dbo].[Public_health_case] SET [last_chg_time] = N'2026-05-06T22:51:40.267', [record_status_time] = N'2026-05-06T22:51:40.267', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [public_health_case_uid] = @dbo_Act_act_uid_8;
-- dbo.case_management
-- step: 8
UPDATE [dbo].[case_management] SET [case_review_status] = N'Accept' WHERE [case_management_uid] = (SELECT TOP 1 [case_management_uid] FROM [dbo].[case_management] WHERE [public_health_case_uid] = @dbo_Act_act_uid_8 AND [epi_link_id] = N'1310000026' AND [field_record_number] = N'1310000126' AND [init_foll_up] = N'FF' AND [init_foll_up_notifiable] = N'06' AND [internet_foll_up] = N'' AND [subj_complexion] = N'' AND [subj_hair] = N'' AND [subj_height] = N'' AND [subj_oth_idntfyng_info] = N'' AND [subj_size_build] = N'' AND [foll_up_assigned_date] = N'2026-04-25T00:00:00' AND [init_foll_up_assigned_date] = N'2026-04-25T00:00:00');
-- dbo.Participation
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-05-06T22:51:40.297', [last_chg_time] = N'2026-05-06T22:51:40.267', [record_status_time] = N'2026-05-06T22:51:40.267', [status_time] = N'2026-05-06T22:51:40.267', [to_time] = N'2026-05-06T22:51:40.297' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'DispoFldFupInvestgrOfPHC';
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-05-06T22:51:40.297', [last_chg_time] = N'2026-05-06T22:51:40.267', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-05-06T22:51:40.267', [status_time] = N'2026-05-06T22:51:40.267', [to_time] = N'2026-05-06T22:51:40.297' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'FldFupInvestgrOfPHC';
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-05-06T22:51:40.297', [last_chg_time] = N'2026-05-06T22:51:40.267', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-05-06T22:51:40.267', [status_time] = N'2026-05-06T22:51:40.267', [to_time] = N'2026-05-06T22:51:40.297' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'InitFldFupInvestgrOfPHC';
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-05-06T22:51:40.297', [last_chg_time] = N'2026-05-06T22:51:40.267', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-05-06T22:51:40.267', [status_time] = N'2026-05-06T22:51:40.267', [to_time] = N'2026-05-06T22:51:40.297' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'InitFupInvestgrOfPHC';
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-05-06T22:51:40.297', [last_chg_time] = N'2026-05-06T22:51:40.267', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-05-06T22:51:40.267', [status_time] = N'2026-05-06T22:51:40.267', [to_time] = N'2026-05-06T22:51:40.297' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'InvestgrOfPHC';
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-05-06T22:51:40.300', [last_chg_time] = N'2026-05-06T22:51:40.267', [record_status_time] = N'2026-05-06T22:51:40.267', [status_time] = N'2026-05-06T22:51:40.267', [to_time] = N'2026-05-06T22:51:40.300' WHERE [subject_entity_uid] = 10003013 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'FldFupSupervisorOfPHC';
-- step: 8
UPDATE [dbo].[Participation] SET [add_time] = N'2026-05-06T22:51:40.300', [last_chg_time] = N'2026-05-06T22:51:40.267', [record_status_time] = N'2026-05-06T22:51:40.267', [status_time] = N'2026-05-06T22:51:40.267' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_6 AND [act_uid] = @dbo_Act_act_uid_8 AND [type_cd] = N'SubjOfPHC';
-- dbo.SubjectRaceInfo
-- step: 8
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_8 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';
-- dbo.PublicHealthCaseFact
-- step: 8
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_8;
-- step: 8
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [case_class_cd], [case_type_cd], [curr_sex_cd], [deceased_ind_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorAssigneddate], [investigatorName], [investigatorPhone], [jurisdiction_cd], [mart_record_creation_time], [mmwr_week], [mmwr_year], [PAR_type_cd], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [shared_ind], [status_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [LOCAL_ID], [curr_sex_desc_txt], [investigation_status_desc_txt], [prog_area_desc_txt], [LASTUPDATE]) VALUES (@dbo_Act_act_uid_8, N'', N'I', N'M', N'N', N'2026-05-06T22:43:44.750', N'P', 1.0, N'C', N'2026-04-25T00:00:00', N'Xerogeanes, John', N'404-778-3350', N'130001', N'2026-05-06T22:51:45.520', 16, 2026, N'SubjOfPHC', N'PAT', @dbo_Entity_entity_uid_6, N'2026-05-06T22:43:44.750', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2106-3', N'White', N'OPEN', N'T', N'A', N', FredContact', N'Fulton County', N'2026-04-25T00:00:00', 1300100015, N'2026-05-06T22:43:44.750', 10009303, @dbo_Person_local_id_2, @dbo_Public_health_case_local_id_2, N'Male', N'Closed', N'STD', N'2026-05-06T22:51:40.267');
-- dbo.SubjectRaceInfo
-- step: 8
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_8, N'2106-3', N'2106-3');
-- step: 8
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_8 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';
-- dbo.PublicHealthCaseFact
-- step: 8
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_8;
-- step: 8
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [case_class_cd], [case_type_cd], [curr_sex_cd], [deceased_ind_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorAssigneddate], [investigatorName], [investigatorPhone], [jurisdiction_cd], [mart_record_creation_time], [mmwr_week], [mmwr_year], [PAR_type_cd], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [shared_ind], [status_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [LOCAL_ID], [curr_sex_desc_txt], [investigation_status_desc_txt], [prog_area_desc_txt], [LASTUPDATE]) VALUES (@dbo_Act_act_uid_8, N'', N'I', N'M', N'N', N'2026-05-06T22:43:44.750', N'P', 1.0, N'C', N'2026-04-25T00:00:00', N'Xerogeanes, John', N'404-778-3350', N'130001', N'2026-05-06T22:51:45.993', 16, 2026, N'SubjOfPHC', N'PAT', @dbo_Entity_entity_uid_6, N'2026-05-06T22:43:44.750', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2106-3', N'White', N'OPEN', N'T', N'A', N', FredContact', N'Fulton County', N'2026-04-25T00:00:00', 1300100015, N'2026-05-06T22:43:44.750', 10009303, @dbo_Person_local_id_2, @dbo_Public_health_case_local_id_2, N'Male', N'Closed', N'STD', N'2026-05-06T22:51:40.267');
-- dbo.SubjectRaceInfo
-- step: 8
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_8, N'2106-3', N'2106-3');
