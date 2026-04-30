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

-- STEP 7: AddContactSyphilis
-- dbo.Entity
-- step: 7
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_5, N'PSN');
-- dbo.Person
-- step: 7
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [cd], [curr_sex_cd], [deceased_ind_cd], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [version_ctrl_nbr], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid], [edx_ind]) VALUES (@dbo_Entity_entity_uid_5, N'2026-04-30T19:57:57.537', @superuser_id, N'PAT', N'M', N'N', N'2026-04-30T19:57:57.537', @superuser_id, @dbo_Person_local_id_2, N'ACTIVE', N'2026-04-30T19:57:57.537', N'A', N'2026-04-30T19:57:57.537', N'FredContact', 1, N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'N', @dbo_Entity_entity_uid_5, N'Y');
-- dbo.Person_name
-- step: 7
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_5, 1, N'Add', N'2026-04-30T19:57:57.467', @superuser_id, N'FredContact', N'F632', N'2026-04-30T19:57:57.467', @superuser_id, N'L', N'ACTIVE', N'2026-04-30T19:57:57.467', N'A', N'2026-04-30T19:57:57.467', N'2026-04-30T00:00:00');
-- dbo.Person_race
-- step: 7
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [add_user_id], [race_category_cd], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid_5, N'2106-3', N'2026-04-30T19:57:57.467', @superuser_id, N'2106-3', N'ACTIVE', N'2026-04-30T00:00:00');
-- dbo.Postal_locator
-- step: 7
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [cntry_cd], [record_status_cd], [record_status_time]) VALUES (@dbo_Postal_locator_postal_locator_uid_4, N'2026-04-30T19:57:57.467', @superuser_id, N'', N'ACTIVE', N'2026-04-30T19:57:57.467');
-- dbo.Entity_locator_participation
-- step: 7
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_5, @dbo_Postal_locator_postal_locator_uid_4, N'O', N'PST', N'2026-04-30T19:57:57.537', @superuser_id, N'found in the park wearing a red shirt and jeans', N'ACTIVE', N'2026-04-30T19:57:57.537', N'A', N'2026-04-30T19:57:57.537', N'PB', 1, N'2026-04-30T00:00:00');
-- dbo.Entity
-- step: 7
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_6, N'PSN');
-- dbo.Person
-- step: 7
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [cd], [curr_sex_cd], [deceased_ind_cd], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_6, N'2026-04-30T19:57:57.577', @superuser_id, N'PAT', N'M', N'N', N'2026-04-30T19:57:57.577', @superuser_id, @dbo_Person_local_id_2, N'ACTIVE', N'2026-04-30T19:57:57.577', N'A', N'2026-04-30T19:57:57.577', N'FredContact', 1, N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'N', @dbo_Entity_entity_uid_5);
-- dbo.Person_name
-- step: 7
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_6, 1, N'Add', N'2026-04-30T19:57:57.467', @superuser_id, N'FredContact', N'F632', N'2026-04-30T19:57:57.467', @superuser_id, N'L', N'ACTIVE', N'2026-04-30T19:57:57.467', N'A', N'2026-04-30T19:57:57.467', N'2026-04-30T00:00:00');
-- dbo.Person_race
-- step: 7
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [add_user_id], [race_category_cd], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid_6, N'2106-3', N'2026-04-30T19:57:57.467', @superuser_id, N'2106-3', N'ACTIVE', N'2026-04-30T00:00:00');
-- dbo.Postal_locator
-- step: 7
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [cntry_cd], [record_status_cd], [record_status_time]) VALUES (@dbo_Postal_locator_postal_locator_uid_5, N'2026-04-30T19:57:57.467', @superuser_id, N'', N'ACTIVE', N'2026-04-30T19:57:57.467');
-- dbo.Entity_locator_participation
-- step: 7
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_6, @dbo_Postal_locator_postal_locator_uid_5, N'O', N'PST', N'2026-04-30T19:57:57.577', @superuser_id, N'found in the park wearing a red shirt and jeans', N'ACTIVE', N'2026-04-30T19:57:57.577', N'A', N'2026-04-30T19:57:57.577', N'PB', 1, N'2026-04-30T00:00:00');
-- dbo.Act
-- step: 7
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_8, N'CASE', N'EVN');
-- dbo.Public_health_case
-- step: 7
INSERT INTO [dbo].[Public_health_case] ([public_health_case_uid], [activity_from_time], [add_time], [add_user_id], [case_class_cd], [case_type_cd], [cd], [cd_desc_txt], [detection_method_cd], [disease_imported_cd], [effective_duration_amt], [effective_duration_unit_cd], [group_case_cnt], [investigation_status_cd], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [mmwr_week], [mmwr_year], [prog_area_cd], [record_status_cd], [record_status_time], [status_cd], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [investigator_assigned_time], [hospitalized_ind_cd], [day_care_ind_cd], [food_handler_ind_cd], [imported_country_cd], [imported_state_cd], [imported_city_desc_txt], [imported_county_cd], [contact_inv_txt], [contact_inv_status_cd], [referral_basis_cd], [curr_process_state_cd], [coinfection_id]) VALUES (@dbo_Act_act_uid_8, N'2026-04-25T00:00:00', N'2026-04-30T19:57:57.590', @superuser_id, N'', N'I', N'10312', N'Syphilis, secondary', N'', N'', N'', N'', 1, N'O', N'130001', N'2026-04-30T19:57:57.590', @superuser_id, @dbo_Public_health_case_local_id_2, N'16', N'2026', N'STD', N'OPEN', N'2026-04-30T19:57:57.590', N'A', 1300100015, N'T', 1, N'2026-04-25T00:00:00', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'P1', N'FF', N'COIN1001XX01');
-- dbo.case_management
-- step: 7
INSERT INTO [dbo].[case_management] ([public_health_case_uid], [epi_link_id], [field_record_number], [init_foll_up], [init_foll_up_notifiable], [internet_foll_up], [subj_complexion], [subj_hair], [subj_height], [subj_oth_idntfyng_info], [subj_size_build], [foll_up_assigned_date], [init_foll_up_assigned_date]) OUTPUT INSERTED.[case_management_uid] INTO @dbo_case_management_case_management_uid_2_output ([value]) VALUES (@dbo_Act_act_uid_8, N'1310000026', N'1310000126', N'FF', N'06', N'', N'', N'', N'', N'', N'', N'2026-04-25T00:00:00', N'2026-04-25T00:00:00');
SELECT TOP 1 @dbo_case_management_case_management_uid_2 = [value] FROM @dbo_case_management_case_management_uid_2_output;
-- dbo.message_log
-- step: 7
INSERT INTO [dbo].[message_log] ([message_txt], [condition_cd], [person_uid], [assigned_to_uid], [event_uid], [event_type_cd], [message_status_cd], [record_status_cd], [record_status_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[message_log_uid] INTO @dbo_message_log_message_log_uid_3_output ([value]) VALUES (N'New assignment', N'10312', @dbo_Entity_entity_uid_6, 10003004, 10009307, N'Investigation', N'N', N'ACTIVE', N'2026-04-30T19:57:57.470', N'2026-04-30T19:57:57.470', @superuser_id, N'2026-04-30T19:57:57.470', @superuser_id);
SELECT TOP 1 @dbo_message_log_message_log_uid_3 = [value] FROM @dbo_message_log_message_log_uid_3_output;
-- dbo.Participation
-- step: 7
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [from_time], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_6, @dbo_Act_act_uid_8, N'SubjOfPHC', N'CASE', N'2026-04-25T00:00:00', N'ACTIVE', N'A', N'2026-04-30T19:57:57.483', N'PSN', N'Subject Of Public Health Case');
-- step: 7
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [from_time], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003004, @dbo_Act_act_uid_8, N'InvestgrOfPHC', N'CASE', N'2026-04-25T00:00:00', N'ACTIVE', N'A', N'2026-04-30T19:57:57.483', N'PSN', N'PHC Investigator');
-- step: 7
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [from_time], [record_status_cd], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_8, N'InitFupInvestgrOfPHC', N'CASE', N'2026-04-25T00:00:00', N'ACTIVE', N'A', N'2026-04-30T19:57:57.483', N'PSN');
-- step: 7
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [from_time], [record_status_cd], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_8, N'InitFldFupInvestgrOfPHC', N'CASE', N'2026-04-25T00:00:00', N'ACTIVE', N'A', N'2026-04-30T19:57:57.483', N'PSN');
-- step: 7
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [from_time], [record_status_cd], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_8, N'FldFupInvestgrOfPHC', N'CASE', N'2026-04-25T00:00:00', N'ACTIVE', N'A', N'2026-04-30T19:57:57.483', N'PSN');
-- dbo.NBS_act_entity
-- step: 7
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_19_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, @dbo_Entity_entity_uid_6, 1, N'2026-04-30T19:57:57.590', @superuser_id, N'OPEN', N'2026-04-30T19:57:57.590', N'SubjOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_19 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_19_output;
-- step: 7
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_20_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, 10003004, 1, N'2026-04-30T19:57:57.590', @superuser_id, N'OPEN', N'2026-04-30T19:57:57.590', N'InvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_20 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_20_output;
-- step: 7
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_21_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, 10003004, 1, N'2026-04-30T19:57:57.590', @superuser_id, N'OPEN', N'2026-04-30T19:57:57.590', N'InitFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_21 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_21_output;
-- step: 7
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_22_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, 10003004, 1, N'2026-04-30T19:57:57.590', @superuser_id, N'OPEN', N'2026-04-30T19:57:57.590', N'InitFldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_22 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_22_output;
-- step: 7
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_23_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, 10003004, 1, N'2026-04-30T19:57:57.590', @superuser_id, N'OPEN', N'2026-04-30T19:57:57.590', N'FldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_23 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_23_output;
-- dbo.Entity
-- step: 7
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_7, N'PSN');
-- dbo.Person
-- step: 7
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [cd], [curr_sex_cd], [deceased_ind_cd], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_7, N'2026-04-30T19:57:57.627', @superuser_id, N'PAT', N'M', N'N', N'2026-04-30T19:57:57.627', @superuser_id, @dbo_Person_local_id_2, N'ACTIVE', N'2026-04-30T19:57:57.627', N'A', N'2026-04-30T19:57:57.627', N'FredContact', 1, N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'N', @dbo_Entity_entity_uid_5);
-- dbo.Person_name
-- step: 7
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_7, 1, N'Add', N'2026-04-30T19:57:57.467', @superuser_id, N'FredContact', N'F632', N'2026-04-30T19:57:57.467', @superuser_id, N'L', N'ACTIVE', N'2026-04-30T19:57:57.467', N'A', N'2026-04-30T19:57:57.467', N'2026-04-30T00:00:00');
-- dbo.Person_race
-- step: 7
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [add_user_id], [race_category_cd], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid_7, N'2106-3', N'2026-04-30T19:57:57.467', @superuser_id, N'2106-3', N'ACTIVE', N'2026-04-30T00:00:00');
-- dbo.Postal_locator
-- step: 7
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [cntry_cd], [record_status_cd], [record_status_time]) VALUES (@dbo_Postal_locator_postal_locator_uid_6, N'2026-04-30T19:57:57.467', @superuser_id, N'', N'ACTIVE', N'2026-04-30T19:57:57.467');
-- dbo.Entity_locator_participation
-- step: 7
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_7, @dbo_Postal_locator_postal_locator_uid_6, N'O', N'PST', N'2026-04-30T19:57:57.627', @superuser_id, N'found in the park wearing a red shirt and jeans', N'ACTIVE', N'2026-04-30T19:57:57.627', N'A', N'2026-04-30T19:57:57.627', N'PB', 1, N'2026-04-30T00:00:00');
-- dbo.Act
-- step: 7
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_9, N'CT', N'EVN');
-- dbo.CT_contact
-- step: 7
INSERT INTO [dbo].[CT_contact] ([ct_contact_uid], [local_id], [subject_entity_uid], [contact_entity_uid], [subject_entity_phc_uid], [contact_entity_phc_uid], [record_status_cd], [record_status_time], [add_user_id], [add_time], [last_chg_time], [last_chg_user_id], [prog_area_cd], [jurisdiction_cd], [program_jurisdiction_oid], [shared_ind_cd], [contact_status], [priority_cd], [group_name_cd], [disposition_cd], [relationship_cd], [health_status_cd], [txt], [symptom_cd], [symptom_txt], [risk_factor_cd], [risk_factor_txt], [evaluation_completed_cd], [evaluation_txt], [treatment_initiated_cd], [treatment_not_start_rsn_cd], [treatment_end_cd], [treatment_not_end_rsn_cd], [treatment_txt], [version_ctrl_nbr], [processing_decision_cd], [subject_entity_epi_link_id], [contact_entity_epi_link_id], [named_during_interview_uid], [contact_referral_basis_cd]) VALUES (@dbo_Act_act_uid_9, @dbo_CT_contact_local_id, @dbo_Entity_entity_uid_4, @dbo_Entity_entity_uid_7, @dbo_Act_act_uid_5, @dbo_Act_act_uid_8, N'ACTIVE', N'2026-04-30T19:57:57.627', @superuser_id, N'2026-04-30T19:57:57.627', N'2026-04-30T19:57:57.627', @superuser_id, N'STD', N'130001', 1300100015, N'T', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', 1, N'FF', N'1310000026', N'1310000026', @dbo_Act_act_uid_7, N'P1');
-- dbo.CT_contact_answer
-- step: 7
INSERT INTO [dbo].[CT_contact_answer] ([ct_contact_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[ct_contact_answer_uid] INTO @dbo_CT_contact_answer_ct_contact_answer_uid_output ([value]) VALUES (@dbo_Act_act_uid_9, N'04/01/2026', 10001184, 3, N'2026-04-30T19:57:57.627', @superuser_id, N'ACTIVE', N'2026-04-30T19:57:57.627', 0);
SELECT TOP 1 @dbo_CT_contact_answer_ct_contact_answer_uid = [value] FROM @dbo_CT_contact_answer_ct_contact_answer_uid_output;
-- step: 7
INSERT INTO [dbo].[CT_contact_answer] ([ct_contact_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[ct_contact_answer_uid] INTO @dbo_CT_contact_answer_ct_contact_answer_uid_2_output ([value]) VALUES (@dbo_Act_act_uid_9, N'03/15/2026', 10001182, 3, N'2026-04-30T19:57:57.627', @superuser_id, N'ACTIVE', N'2026-04-30T19:57:57.627', 0);
SELECT TOP 1 @dbo_CT_contact_answer_ct_contact_answer_uid_2 = [value] FROM @dbo_CT_contact_answer_ct_contact_answer_uid_2_output;
-- step: 7
INSERT INTO [dbo].[CT_contact_answer] ([ct_contact_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[ct_contact_answer_uid] INTO @dbo_CT_contact_answer_ct_contact_answer_uid_3_output ([value]) VALUES (@dbo_Act_act_uid_9, N'THSPAT', 10001348, 3, N'2026-04-30T19:57:57.627', @superuser_id, N'ACTIVE', N'2026-04-30T19:57:57.627', 0);
SELECT TOP 1 @dbo_CT_contact_answer_ct_contact_answer_uid_3 = [value] FROM @dbo_CT_contact_answer_ct_contact_answer_uid_3_output;
-- dbo.NBS_act_entity
-- step: 7
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_24_output ([value]) VALUES (@dbo_Act_act_uid_9, N'2026-04-30T19:57:57.627', @superuser_id, @dbo_Entity_entity_uid_4, 1, N'2026-04-30T19:57:57.627', @superuser_id, N'ACTIVE', N'2026-04-30T19:57:57.627', N'SubjOfContact');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_24 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_24_output;
-- step: 7
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_25_output ([value]) VALUES (@dbo_Act_act_uid_9, N'2026-04-30T19:57:57.653', @superuser_id, 10003004, 1, N'2026-04-30T19:57:57.627', @superuser_id, N'ACTIVE', N'2026-04-30T19:57:57.627', N'InvestgrOfContact');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_25 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_25_output;
-- dbo.PublicHealthCaseFact
-- step: 7
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [case_class_cd], [case_type_cd], [curr_sex_cd], [deceased_ind_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorAssigneddate], [investigatorName], [investigatorPhone], [jurisdiction_cd], [mart_record_creation_time], [mmwr_week], [mmwr_year], [PAR_type_cd], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [shared_ind], [status_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [LOCAL_ID], [curr_sex_desc_txt], [investigation_status_desc_txt], [prog_area_desc_txt], [LASTUPDATE]) VALUES (@dbo_Act_act_uid_8, N'', N'I', N'M', N'N', N'2026-04-30T19:57:57.590', N'P', 1.0, N'O', N'2026-04-25T00:00:00', N'Xerogeanes, John', N'404-778-3350', N'130001', N'2026-04-30T19:58:04.653', 16, 2026, N'SubjOfPHC', N'PAT', @dbo_Entity_entity_uid_6, N'2026-04-30T19:57:57.590', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2106-3', N'White', N'OPEN', N'T', N'A', N', FredContact', N'Fulton County', N'2026-04-25T00:00:00', 1300100015, N'2026-04-30T19:57:57.590', 10009303, @dbo_Person_local_id_2, @dbo_Public_health_case_local_id_2, N'Male', N'Open', N'STD', N'2026-04-30T19:57:57.590');
-- dbo.SubjectRaceInfo
-- step: 7
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_8, N'2106-3', N'2106-3');
