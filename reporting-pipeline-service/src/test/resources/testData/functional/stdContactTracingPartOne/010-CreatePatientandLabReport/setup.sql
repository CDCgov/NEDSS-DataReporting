USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 3410000;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 3410001;
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 3410002;
DECLARE @dbo_Tele_locator_tele_locator_uid_2 bigint = 3410003;
DECLARE @dbo_Entity_entity_uid_2 bigint = 3410004;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 3410005;
DECLARE @dbo_Tele_locator_tele_locator_uid_3 bigint = 3410006;
DECLARE @dbo_Tele_locator_tele_locator_uid_4 bigint = 3410007;
DECLARE @dbo_Act_act_uid bigint = 3410008;
DECLARE @dbo_Act_act_uid_2 bigint = 3410009;
DECLARE @dbo_Act_act_uid_3 bigint = 3410010;
DECLARE @dbo_Act_act_uid_4 bigint = 3410011;
DECLARE @dbo_Entity_entity_uid_3 bigint = 3410012;
DECLARE @dbo_Entity_entity_uid_4 bigint = 3410013;
DECLARE @dbo_Postal_locator_postal_locator_uid_3 bigint = 3410014;
DECLARE @dbo_Tele_locator_tele_locator_uid_5 bigint = 3410015;
DECLARE @dbo_Tele_locator_tele_locator_uid_6 bigint = 3410016;
DECLARE @dbo_Act_act_uid_5 bigint = 3410017;
DECLARE @dbo_Act_act_uid_6 bigint = 3410018;
DECLARE @dbo_Act_act_uid_7 bigint = 3410019;
DECLARE @dbo_Entity_entity_uid_5 bigint = 3410020;
DECLARE @dbo_Postal_locator_postal_locator_uid_4 bigint = 3410021;
DECLARE @dbo_Entity_entity_uid_6 bigint = 3410022;
DECLARE @dbo_Postal_locator_postal_locator_uid_5 bigint = 3410023;
DECLARE @dbo_Act_act_uid_8 bigint = 3410024;
DECLARE @dbo_Entity_entity_uid_7 bigint = 3410025;
DECLARE @dbo_Postal_locator_postal_locator_uid_6 bigint = 3410026;
DECLARE @dbo_Act_act_uid_9 bigint = 3410027;
DECLARE @dbo_Act_act_uid_10 bigint = 3410028;
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

-- STEP 1: Create Patient and Lab Report
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid, N'PSN');
-- dbo.Person
-- step: 1
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [birth_gender_cd], [birth_time], [birth_time_calc], [cd], [curr_sex_cd], [deceased_ind_cd], [last_chg_time], [last_chg_user_id], [local_id], [marital_status_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid], [edx_ind]) VALUES (@dbo_Entity_entity_uid, N'2026-05-06T22:04:51.657', @superuser_id, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'PAT', N'F', N'N', N'2026-05-06T22:04:51.657', @superuser_id, @dbo_Person_local_id, N'M', N'ACTIVE', N'2026-05-06T22:04:51.657', N'A', N'2026-05-06T22:04:51.657', N'Taylor', N'Swift_fake77gg', 1, N'2026-05-06T00:00:00', N'2026-05-06T00:00:00', N'2026-05-06T00:00:00', N'2026-05-06T00:00:00', N'N', @dbo_Entity_entity_uid, N'Y');
-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [first_nm], [first_nm_sndx], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid, 1, N'Add', N'2026-05-06T22:04:51.590', N'Taylor', N'T460', N'Swift_fake77gg', N'S130', N'L', N'ACTIVE', N'2026-05-06T22:04:51.590', N'A', N'2026-05-06T22:04:51.590', N'2026-05-06T00:00:00');
-- dbo.Person_race
-- step: 1
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [race_category_cd], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid, N'2106-3', N'2026-05-06T22:04:51.607', N'2106-3', N'ACTIVE', N'2026-05-06T00:00:00');
-- dbo.Entity_id
-- step: 1
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [assigning_authority_cd], [assigning_authority_desc_txt], [last_chg_time], [record_status_cd], [record_status_time], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid, 1, N'2026-05-06T22:04:51.590', N'GA', N'GA', N'2026-05-06T22:04:51.590', N'ACTIVE', N'2026-05-06T22:04:51.590', N'123987456', N'A', N'2026-05-06T22:04:51.590', N'DL', N'Driver''s license number', N'2026-05-06T00:00:00', N'L');
-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [city_desc_txt], [cntry_cd], [cnty_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [street_addr2], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid, N'2026-05-06T22:04:51.607', N'Atlanta', N'840', N'13121', N'ACTIVE', N'2026-05-06T22:04:51.607', N'13', N'1313 Pine Way', N'', N'30033');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Postal_locator_postal_locator_uid, N'H', N'PST', N'2026-05-06T22:04:51.657', @superuser_id, N'ACTIVE', N'2026-05-06T22:04:51.657', N'A', N'2026-05-06T22:04:51.657', N'H', 1, N'2026-05-06T00:00:00');
-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid, N'2026-05-06T22:04:51.607', @superuser_id, N'201-555-1212', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Tele_locator_tele_locator_uid, N'PH', N'TELE', N'2026-05-06T22:04:51.657', @superuser_id, N'ACTIVE', N'2026-05-06T22:04:51.657', N'A', N'2026-05-06T22:04:51.657', N'H', 1, N'2026-05-06T00:00:00');
-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_2, N'2026-05-06T22:04:51.607', @superuser_id, N'taylor@example.com', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Tele_locator_tele_locator_uid_2, N'NET', N'TELE', N'2026-05-06T22:04:51.657', @superuser_id, N'ACTIVE', N'2026-05-06T22:04:51.657', N'A', N'2026-05-06T22:04:51.657', N'H', 1, N'2026-05-06T00:00:00');
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_2, N'PSN');
-- dbo.Person
-- step: 1
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [age_reported], [age_reported_unit_cd], [birth_time], [birth_time_calc], [cd], [curr_sex_cd], [deceased_ind_cd], [last_chg_time], [last_chg_user_id], [local_id], [marital_status_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_2, N'2026-05-06T22:04:56.943', @superuser_id, N'41', N'Y', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'PAT', N'F', N'N', N'2026-05-06T22:04:56.943', @superuser_id, @dbo_Person_local_id, N'M', N'ACTIVE', N'2026-05-06T22:04:56.943', N'A', N'2026-05-06T22:04:56.943', N'Taylor', N'Swift_fake77gg', 1, N'2026-05-06T00:00:00', N'2026-05-06T00:00:00', N'2026-05-06T00:00:00', N'2026-05-06T00:00:00', N'N', @dbo_Entity_entity_uid);
-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, 1, N'ADD LAB REPORT', N'2026-05-06T22:04:56.827', @superuser_id, N'Taylor', N'T460', N'2026-05-06T22:04:56.827', @superuser_id, N'Swift_fake77gg', N'S130', N'L', N'ACTIVE', N'2026-05-06T22:04:56.827', N'A', N'2026-05-06T22:04:56.827', N'2026-05-06T00:00:00');
-- dbo.Person_race
-- step: 1
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [add_user_id], [race_category_cd], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, N'2106-3', N'2026-05-06T22:04:56.827', @superuser_id, N'2106-3', N'ACTIVE', N'2026-05-06T00:00:00');
-- dbo.Entity_id
-- step: 1
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [assigning_authority_cd], [assigning_authority_desc_txt], [last_chg_time], [record_status_cd], [record_status_time], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid_2, 1, N'2026-05-06T22:04:56.873', N'GA', N'GA', N'2026-05-06T22:04:56.873', N'ACTIVE', N'2026-05-06T22:04:56.873', N'123987456', N'A', N'2026-05-06T22:04:56.873', N'DL', N'Driver''s license number', N'2026-05-06T00:00:00', N'L');
-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt], [cntry_cd], [cnty_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_2, N'2026-05-06T22:04:56.827', @superuser_id, N'Atlanta', N'840', N'13121', N'ACTIVE', N'2026-05-06T22:04:56.827', N'13', N'1313 Pine Way', N'30033');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Postal_locator_postal_locator_uid_2, N'H', N'PST', N'2026-05-06T22:04:56.943', @superuser_id, N'ACTIVE', N'2026-05-06T22:04:56.943', N'A', N'2026-05-06T22:04:56.943', N'H', 1, N'2026-05-06T00:00:00');
-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_3, N'2026-05-06T22:04:56.827', @superuser_id, N'', N'201-555-1212', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Tele_locator_tele_locator_uid_3, N'PH', N'TELE', N'2026-05-06T22:04:56.943', @superuser_id, N'ACTIVE', N'2026-05-06T22:04:56.943', N'A', N'2026-05-06T22:04:56.943', N'H', 1, N'2026-05-06T00:00:00');
-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_4, N'2026-05-06T22:04:56.827', @superuser_id, N'taylor@example.com', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Tele_locator_tele_locator_uid_4, N'NET', N'TELE', N'2026-05-06T22:04:56.943', @superuser_id, N'ACTIVE', N'2026-05-06T22:04:56.943', N'A', N'2026-05-06T22:04:56.943', N'H', 1, N'2026-05-06T00:00:00');
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid, N'OBS', N'EVN');
-- dbo.Observation
-- step: 1
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [electronic_ind], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [obs_domain_cd_st_1], [prog_area_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [target_site_cd], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [rpt_to_state_time], [pregnant_ind_cd], [pregnant_week]) VALUES (@dbo_Act_act_uid, N'2026-04-20T00:00:00', N'ADD LAB REPORT', N'2026-05-06T22:04:56.973', @superuser_id, N'T-14900', N'No Information Given', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'N', N'130001', N'2026-05-06T22:04:56.973', @superuser_id, @dbo_Observation_local_id, N'Order', N'STD', N'UNPROCESSED', N'2026-05-06T22:04:56.973', N'D', N'2026-05-06T22:04:56.827', N'NI', 1300100015, N'T', 1, N'2026-05-06T00:00:00', N'Y', 30);
-- dbo.Act_id
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, 0, N'Default Manual Lab', N'ACTIVE', N'', N'A', N'2026-05-06T22:04:56.837', N'FN', N'Filler Number');
-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq]) VALUES (@dbo_Act_act_uid, 0);
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_2, N'OBS', N'EVN');
-- dbo.Observation
-- step: 1
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [local_id], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [rpt_to_state_time]) VALUES (@dbo_Act_act_uid_2, N'2026-04-20T00:00:00', N'NI', N'No Information Given', N'2.16.840.1.113883', N'LabComment', N'Lab Report', @dbo_Observation_local_id_2, N'C_Order', N'D', N'2026-05-06T22:04:56.837', 4, N'T', 1, N'2026-05-06T00:00:00');
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_3, N'OBS', N'EVN');
-- dbo.Observation
-- step: 1
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [local_id], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_3, N'2026-05-06T22:04:56.837', @superuser_id, N'LAB214', N'User Report Comment', N'NBS', N'NEDSS Base System', N'LabComment', @dbo_Observation_local_id_3, N'C_Result', N'D', N'2026-05-06T22:04:56.837', 4, N'T', 1);
-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq], [value_txt], [value_large_txt]) VALUES (@dbo_Act_act_uid_3, 1, N'some comments', N'some comments');
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_4, N'OBS', N'EVN');
-- dbo.Observation
-- step: 1
INSERT INTO [dbo].[Observation] ([observation_uid], [add_reason_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [electronic_ind], [local_id], [obs_domain_cd_st_1], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd]) VALUES (@dbo_Act_act_uid_4, N'ADD LAB REPORT', N'T-58955', N'RPR Titer ', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'N', @dbo_Observation_local_id_4, N'Result', N'2026-05-06T22:04:56.843', 4, N'T', 1, N'31147-2', N'REAGIN AB', N'LN');
-- dbo.Obs_value_numeric
-- step: 1
INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid], [obs_value_numeric_seq], [comparator_cd_1], [numeric_value_1], [numeric_value_2], [separator_cd], [numeric_scale_1], [numeric_scale_2]) VALUES (@dbo_Act_act_uid_4, 0, N'=', 1.0, 128.0, N':', 0, 0);
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_3, N'MAT');
-- dbo.Material
-- step: 1
INSERT INTO [dbo].[Material] ([material_uid], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid_3, N'Add', N'2026-05-06T22:04:57.033', @superuser_id, N'', N'', N'2026-05-06T22:04:57.033', @superuser_id, @dbo_Material_local_id, N'ACTIVE', N'2026-05-06T22:04:57.033', N'A', N'2026-05-06T22:04:57.033', 1);
-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003019, @dbo_Act_act_uid, N'AUT', N'OBS', N'2026-05-06T22:04:56.807', @superuser_id, N'2026-05-06T22:04:56.807', @superuser_id, N'ACTIVE', N'2026-05-06T22:04:56.813', N'A', N'2026-05-06T22:04:56.813', N'ORG', N'Author');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003019, @dbo_Act_act_uid, N'ORD', N'OBS', N'2026-05-06T22:04:56.817', @superuser_id, N'2026-05-06T22:04:56.817', @superuser_id, N'ACTIVE', N'2026-05-06T22:04:56.817', N'A', N'2026-05-06T22:04:56.817', N'ORG', N'Orderer');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Act_act_uid, N'PATSBJ', N'OBS', N'2026-05-06T22:04:56.817', @superuser_id, N'2026-05-06T22:04:56.817', @superuser_id, N'ACTIVE', N'2026-05-06T22:04:56.817', N'A', N'2026-05-06T22:04:56.817', N'PSN', N'Patient subject');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_3, @dbo_Act_act_uid, N'SPC', N'OBS', N'2026-05-06T22:04:56.837', @superuser_id, N'2026-05-06T22:04:56.837', @superuser_id, N'ACTIVE', N'A', N'2026-05-06T22:04:56.837', N'MAT', N'Specimen');
-- dbo.Act_relationship
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_2, @dbo_Act_act_uid_3, N'COMP', N'2026-05-06T22:04:57.053', N'2026-05-06T22:04:57.053', N'ACTIVE', N'2026-05-06T22:04:57.053', N'OBS', N'A', N'2026-05-06T22:04:57.053', N'OBS', N'Is Cause For');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_2, N'APND', N'2026-05-06T22:04:57.057', N'2026-05-06T22:04:57.057', N'ACTIVE', N'2026-05-06T22:04:57.057', N'OBS', N'A', N'2026-05-06T22:04:57.057', N'OBS', N'Appends');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_4, N'COMP', N'2026-05-06T22:04:57.057', N'2026-05-06T22:04:57.057', N'ACTIVE', N'2026-05-06T22:04:57.057', N'OBS', N'A', N'2026-05-06T22:04:57.057', N'OBS', N'Has Component');
-- dbo.Role
-- step: 1
INSERT INTO [dbo].[Role] ([subject_entity_uid], [cd], [role_seq], [add_time], [cd_desc_txt], [effective_from_time], [effective_to_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [scoping_class_cd], [scoping_entity_uid], [scoping_role_cd], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_3, N'NI', 0, N'2026-05-06T22:04:57.060', N'No Information Given', N'2026-05-06T22:04:57.060', N'2026-05-06T22:04:57.060', N'2026-05-06T22:04:57.060', @superuser_id, N'ACTIVE', N'2026-05-06T22:04:57.060', N'PSN', @dbo_Entity_entity_uid_2, N'PAT', N'A', N'2026-05-06T22:04:57.060', N'SPEC');
-- dbo.Person
-- step: 1
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T22:04:56.937', [record_status_time] = N'2026-05-06T22:04:56.937', [status_time] = N'2026-05-06T22:04:56.937', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Entity_locator_participation
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:04:56.937', [record_status_time] = N'2026-05-06T22:04:56.937', [status_time] = N'2026-05-06T22:04:56.937' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:04:56.937', [record_status_time] = N'2026-05-06T22:04:56.937', [status_time] = N'2026-05-06T22:04:56.937' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:04:56.937', [record_status_time] = N'2026-05-06T22:04:56.937', [status_time] = N'2026-05-06T22:04:56.937' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;
