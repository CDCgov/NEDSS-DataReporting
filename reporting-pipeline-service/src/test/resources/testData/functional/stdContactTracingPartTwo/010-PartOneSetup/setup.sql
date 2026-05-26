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
-- STEP 2: Create Investigation and Assign Investigator
-- dbo.Entity
-- step: 2
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_4, N'PSN');
-- dbo.Person
-- step: 2
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [age_reported], [age_reported_unit_cd], [birth_gender_cd], [birth_time], [birth_time_calc], [cd], [curr_sex_cd], [deceased_ind_cd], [last_chg_time], [last_chg_user_id], [local_id], [marital_status_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_4, N'2026-05-06T22:11:00.643', @superuser_id, N'41', N'Y', N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'PAT', N'F', N'N', N'2026-05-06T22:11:00.643', @superuser_id, @dbo_Person_local_id, N'M', N'ACTIVE', N'2026-05-06T22:11:00.643', N'A', N'2026-05-06T22:11:00.643', N'Taylor', N'Swift_fake77gg', 1, N'2026-05-06T00:00:00', N'2026-05-06T00:00:00', N'2026-05-06T00:00:00', N'2026-05-06T00:00:00', N'N', @dbo_Entity_entity_uid);
-- dbo.Person_name
-- step: 2
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, 1, N'2026-05-06T22:11:00.547', @superuser_id, N'Taylor', N'T460', N'2026-05-06T22:11:00.547', @superuser_id, N'Swift_fake77gg', N'S130', N'L', N'ACTIVE', N'2026-05-06T22:11:00.547', N'A', N'2026-05-06T22:11:00.547', N'2026-05-06T00:00:00');
-- dbo.Person_race
-- step: 2
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [add_user_id], [race_category_cd], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, N'2106-3', N'2026-05-06T22:11:00.547', @superuser_id, N'2106-3', N'ACTIVE', N'2026-05-06T00:00:00');
-- dbo.Entity_id
-- step: 2
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [assigning_authority_cd], [assigning_authority_desc_txt], [last_chg_time], [record_status_cd], [record_status_time], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid_4, 1, N'2026-05-06T22:11:00.570', N'GA', N'GA', N'2026-05-06T22:11:00.570', N'ACTIVE', N'2026-05-06T22:11:00.570', N'123987456', N'A', N'2026-05-06T22:11:00.570', N'DL', N'Driver''s license number', N'2026-05-06T00:00:00', N'L');
-- dbo.Postal_locator
-- step: 2
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt], [cntry_cd], [cnty_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_3, N'2026-05-06T22:11:00.547', @superuser_id, N'Atlanta', N'840', N'13121', N'ACTIVE', N'2026-05-06T22:11:00.547', N'13', N'1313 Pine Way', N'30033');
-- dbo.Entity_locator_participation
-- step: 2
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Postal_locator_postal_locator_uid_3, N'H', N'PST', N'2026-05-06T22:11:00.643', @superuser_id, N'ACTIVE', N'2026-05-06T22:11:00.643', N'A', N'2026-05-06T22:11:00.643', N'H', 1, N'2026-05-06T00:00:00');
-- dbo.Tele_locator
-- step: 2
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_5, N'2026-05-06T22:11:00.547', @superuser_id, N'', N'201-555-1212', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 2
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Tele_locator_tele_locator_uid_5, N'PH', N'TELE', N'2026-05-06T22:11:00.643', @superuser_id, N'ACTIVE', N'2026-05-06T22:11:00.643', N'A', N'2026-05-06T22:11:00.643', N'H', 1, N'2026-05-06T00:00:00');
-- dbo.Tele_locator
-- step: 2
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_6, N'2026-05-06T22:11:00.547', @superuser_id, N'taylor@example.com', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 2
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Tele_locator_tele_locator_uid_6, N'NET', N'TELE', N'2026-05-06T22:11:00.643', @superuser_id, N'ACTIVE', N'2026-05-06T22:11:00.643', N'A', N'2026-05-06T22:11:00.643', N'H', 1, N'2026-05-06T00:00:00');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_5, N'CASE', N'EVN');
-- dbo.Public_health_case
-- step: 2
INSERT INTO [dbo].[Public_health_case] ([public_health_case_uid], [activity_from_time], [add_time], [add_user_id], [case_class_cd], [case_type_cd], [cd], [cd_desc_txt], [detection_method_cd], [disease_imported_cd], [effective_duration_amt], [effective_duration_unit_cd], [group_case_cnt], [investigation_status_cd], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [mmwr_week], [mmwr_year], [outbreak_ind], [outbreak_name], [outcome_cd], [prog_area_cd], [record_status_cd], [record_status_time], [rpt_form_cmplt_time], [rpt_source_cd], [status_cd], [transmission_mode_cd], [transmission_mode_desc_txt], [txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [hospitalized_ind_cd], [pregnant_ind_cd], [day_care_ind_cd], [food_handler_ind_cd], [imported_country_cd], [imported_state_cd], [imported_city_desc_txt], [imported_county_cd], [priority_cd], [contact_inv_txt], [contact_inv_status_cd], [referral_basis_cd], [curr_process_state_cd], [coinfection_id]) VALUES (@dbo_Act_act_uid_5, N'2026-04-24T00:00:00', N'2026-05-06T22:11:00.673', @superuser_id, N'', N'I', N'700', N'Syphilis, Unknown', N'', N'', N'', N'', 1, N'O', N'130001', N'2026-05-06T22:11:00.673', @superuser_id, @dbo_Public_health_case_local_id, N'18', N'2026', N'', N'', N'', N'STD', N'OPEN', N'2026-05-06T22:11:00.673', N'2026-05-06T00:00:00', N'', N'A', N'', N'', N'', 1300100015, N'T', 1, N'', N'Y', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'T1', N'SF', N'COIN1000XX01');
-- dbo.case_management
-- step: 2
INSERT INTO [dbo].[case_management] ([public_health_case_uid], [epi_link_id], [field_record_number], [init_foll_up], [surv_assigned_date]) OUTPUT INSERTED.[case_management_uid] INTO @dbo_case_management_case_management_uid_output ([value]) VALUES (@dbo_Act_act_uid_5, N'1310000026', N'1310000026', N'SF', N'2026-04-24T00:00:00');
SELECT TOP 1 @dbo_case_management_case_management_uid = [value] FROM @dbo_case_management_case_management_uid_output;
-- dbo.Act_id
-- step: 2
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid_5, 1, N'', N'A', N'2026-05-06T22:11:00.700', N'STATE');
-- step: 2
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid_5, 2, N'', N'A', N'2026-05-06T22:11:00.703', N'CITY');
-- step: 2
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid_5, 3, N'', N'A', N'2026-05-06T22:11:00.703', N'LEGACY');
-- dbo.message_log
-- step: 2
INSERT INTO [dbo].[message_log] ([message_txt], [condition_cd], [person_uid], [assigned_to_uid], [event_uid], [event_type_cd], [message_status_cd], [record_status_cd], [record_status_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[message_log_uid] INTO @dbo_message_log_message_log_uid_output ([value]) VALUES (N'New assignment', N'700', @dbo_Entity_entity_uid_4, 10003010, 10009300, N'Investigation', N'N', N'ACTIVE', N'2026-05-06T22:11:00.543', N'2026-05-06T22:11:00.543', @superuser_id, N'2026-05-06T22:11:00.543', @superuser_id);
SELECT TOP 1 @dbo_message_log_message_log_uid = [value] FROM @dbo_message_log_message_log_uid_output;
-- dbo.Participation
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Act_act_uid_5, N'SubjOfPHC', N'CASE', N'2026-05-06T22:11:00.567', @superuser_id, N'2026-05-06T22:11:00.567', @superuser_id, N'ACTIVE', N'2026-05-06T22:11:00.567', N'A', N'2026-05-06T22:11:00.567', N'PSN', N'Subject Of Public Health Case');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003010, @dbo_Act_act_uid_5, N'InitFupInvestgrOfPHC', N'CASE', N'2026-05-06T22:11:00.570', @superuser_id, N'2026-05-06T22:11:00.570', @superuser_id, N'ACTIVE', N'2026-05-06T22:11:00.570', N'A', N'2026-05-06T22:11:00.570', N'PSN');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003010, @dbo_Act_act_uid_5, N'InvestgrOfPHC', N'CASE', N'2026-05-06T22:11:00.570', @superuser_id, N'2026-05-06T22:11:00.570', @superuser_id, N'ACTIVE', N'2026-05-06T22:11:00.570', N'A', N'2026-05-06T22:11:00.570', N'PSN', N'PHC Investigator');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003019, @dbo_Act_act_uid_5, N'OrgAsClinicOfPHC', N'CASE', N'2026-05-06T22:11:00.570', @superuser_id, N'2026-05-06T22:11:00.570', @superuser_id, N'ACTIVE', N'2026-05-06T22:11:00.570', N'A', N'2026-05-06T22:11:00.570', N'ORG');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003019, @dbo_Act_act_uid_5, N'OrgAsReporterOfPHC', N'CASE', N'2026-05-06T22:11:00.570', @superuser_id, N'2026-05-06T22:11:00.570', @superuser_id, N'ACTIVE', N'2026-05-06T22:11:00.570', N'A', N'2026-05-06T22:11:00.570', N'ORG', N'Organization As Reporter Of PHC');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003010, @dbo_Act_act_uid_5, N'SurvInvestgrOfPHC', N'CASE', N'2026-05-06T22:11:00.570', @superuser_id, N'2026-05-06T22:11:00.570', @superuser_id, N'ACTIVE', N'2026-05-06T22:11:00.570', N'A', N'2026-05-06T22:11:00.570', N'PSN');
-- dbo.NBS_case_answer
-- step: 2
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'N', 10001013, 3, N'2026-05-06T22:11:00.673', @superuser_id, N'OPEN', N'2026-05-06T22:11:00.673', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_output;
-- step: 2
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_2_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'30', 10001252, 3, N'2026-05-06T22:11:00.673', @superuser_id, N'OPEN', N'2026-05-06T22:11:00.673', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_2 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_2_output;
-- dbo.NBS_act_entity
-- step: 2
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, @dbo_Entity_entity_uid_4, 1, N'2026-05-06T22:11:00.673', @superuser_id, N'OPEN', N'2026-05-06T22:11:00.673', N'SubjOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_output;
-- step: 2
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_2_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003010, 1, N'2026-05-06T22:11:00.673', @superuser_id, N'OPEN', N'2026-05-06T22:11:00.673', N'InitFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_2 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_2_output;
-- step: 2
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_3_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003010, 1, N'2026-05-06T22:11:00.673', @superuser_id, N'OPEN', N'2026-05-06T22:11:00.673', N'InvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_3 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_3_output;
-- step: 2
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_4_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003019, 1, N'2026-05-06T22:11:00.673', @superuser_id, N'OPEN', N'2026-05-06T22:11:00.673', N'OrgAsClinicOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_4 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_4_output;
-- step: 2
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_5_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003019, 1, N'2026-05-06T22:11:00.673', @superuser_id, N'OPEN', N'2026-05-06T22:11:00.673', N'OrgAsReporterOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_5 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_5_output;
-- step: 2
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_6_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003010, 1, N'2026-05-06T22:11:00.673', @superuser_id, N'OPEN', N'2026-05-06T22:11:00.673', N'SurvInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_6 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_6_output;
-- dbo.Act_relationship
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_reason_cd], [add_time], [from_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_5, @dbo_Act_act_uid, N'LabReport', N'SF', N'2026-05-06T22:11:00.730', N'2026-05-06T22:11:00.673', N'2026-05-06T22:11:00.730', @superuser_id, N'ACTIVE', N'2026-05-06T22:11:00.730', N'OBS', N'A', N'2026-05-06T22:11:00.730', N'CASE');
-- dbo.Person
-- step: 2
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T22:11:00.633', [record_status_time] = N'2026-05-06T22:11:00.633', [status_time] = N'2026-05-06T22:11:00.633', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Entity_locator_participation
-- step: 2
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:11:00.633', [record_status_time] = N'2026-05-06T22:11:00.633', [status_time] = N'2026-05-06T22:11:00.633' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 2
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:11:00.633', [record_status_time] = N'2026-05-06T22:11:00.633', [status_time] = N'2026-05-06T22:11:00.633' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 2
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:11:00.633', [record_status_time] = N'2026-05-06T22:11:00.633', [status_time] = N'2026-05-06T22:11:00.633' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;
-- dbo.Observation
-- step: 2
UPDATE [dbo].[Observation] SET [last_chg_time] = N'2026-05-06T22:11:00.740', [record_status_cd] = N'PROCESSED', [record_status_time] = N'2026-05-06T22:11:00.740', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid;
-- dbo.PublicHealthCaseFact
-- step: 2
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [organizationName], [PAR_type_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [prog_area_desc_txt], [LASTUPDATE]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'', N'I', N'Atlanta', N'Fulton County', N'840', N'13121', N'F', N'N', N'PST', N'2026-05-06T22:11:00.673', N'P', 1.0, N'O', N'Keable, Kristi', N'404-851-8000', N'130001', N'M', N'Married', N'2026-05-06T22:11:06.497', 18, 2026, N'Emory University Hospital', N'SubjOfPHC', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-05-06T22:11:00.673', N'700', N'Syphilis, Unknown', N'Syphilis, Unknown', N'STD', N'2026-05-06T22:11:00.547', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'2026-05-06T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-05-06T22:11:00.673', 10009283, @dbo_Person_local_id, N'2026-05-06T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Female', N'UNITED STATES', N'Female', N'Open', N'STD', N'2026-05-06T22:11:00.673');
-- dbo.SubjectRaceInfo
-- step: 2
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');
-- STEP 3: Add Treatment to the Investigation
-- dbo.Act
-- step: 3
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_6, N'TRMT', N'EVN');
-- dbo.Treatment
-- step: 3
INSERT INTO [dbo].[Treatment] ([treatment_uid], [activity_from_time], [add_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [class_cd], [last_chg_time], [last_chg_user_id], [local_id], [prog_area_cd], [program_jurisdiction_oid], [record_status_cd], [record_status_time], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_6, N'2026-04-22T00:00:00', N'2026-05-06T22:16:04.753', @superuser_id, N'176', N'Benzathine penicillin G (Bicillin), 2.4 mu, IM, x 1 dose', N'2.16.840.1.114222.4.5.1', N'NEDSS Base System', N'TA', N'2026-05-06T22:16:04.760', @superuser_id, @dbo_Treatment_local_id, N'STD', 1, N'ACTIVE', N'2026-05-06T22:16:04.760', N'T', 1);
-- dbo.Treatment_administered
-- step: 3
INSERT INTO [dbo].[Treatment_administered] ([treatment_uid], [treatment_administered_seq], [cd], [dose_qty], [dose_qty_unit_cd], [effective_from_time], [interval_cd], [route_cd]) VALUES (@dbo_Act_act_uid_6, 1, N'176', N'2.4', N'mu', N'2026-04-22T00:00:00', N'Once', N'C0556983');
-- dbo.NBS_act_entity
-- step: 3
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_7_output ([value]) VALUES (@dbo_Act_act_uid_6, N'2026-05-06T22:16:04.753', @superuser_id, 10003004, 1, N'2026-05-06T22:16:04.760', @superuser_id, N'ACTIVE', N'2026-05-06T22:16:04.760', N'ProviderOfTrmt');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_7 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_7_output;
-- step: 3
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_8_output ([value]) VALUES (@dbo_Act_act_uid_6, N'2026-05-06T22:16:04.753', @superuser_id, @dbo_Entity_entity_uid, 1, N'2026-05-06T22:16:04.760', @superuser_id, N'ACTIVE', N'2026-05-06T22:16:04.760', N'SubjOfTrmt');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_8 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_8_output;
-- step: 3
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_9_output ([value]) VALUES (@dbo_Act_act_uid_6, N'2026-05-06T22:16:04.753', @superuser_id, 10003007, 1, N'2026-05-06T22:16:04.760', @superuser_id, N'ACTIVE', N'2026-05-06T22:16:04.760', N'ReporterOfTrmt');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_9 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_9_output;
-- dbo.Participation
-- step: 3
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_6, N'ProviderOfTrmt', N'TRMT', N'2026-05-06T22:16:04.760', @superuser_id, N'2026-05-06T22:16:04.760', @superuser_id, N'ACTIVE', N'2026-05-06T22:16:04.760', N'A', N'2026-05-06T22:16:04.760', N'PSN');
-- step: 3
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid, @dbo_Act_act_uid_6, N'SubjOfTrmt', N'TRMT', N'2026-05-06T22:16:04.760', @superuser_id, N'2026-05-06T22:16:04.760', @superuser_id, N'ACTIVE', N'2026-05-06T22:16:04.760', N'A', N'2026-05-06T22:16:04.760', N'PSN', N'Treatment Subject');
-- step: 3
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003007, @dbo_Act_act_uid_6, N'ReporterOfTrmt', N'TRMT', N'2026-05-06T22:16:04.760', @superuser_id, N'2026-05-06T22:16:04.760', @superuser_id, N'ACTIVE', N'2026-05-06T22:16:04.760', N'A', N'2026-05-06T22:16:04.760', N'ORG');
-- dbo.Act_relationship
-- step: 3
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_5, @dbo_Act_act_uid_6, N'TreatmentToPHC', N'2026-05-06T22:16:04.810', N'2026-05-06T22:16:04.810', @superuser_id, N'ACTIVE', N'2026-05-06T22:16:04.810', N'TRMT', N'A', N'2026-05-06T22:16:04.810', N'CASE');
-- STEP 4: Update Investigation Case Information
-- dbo.Participation
-- step: 4
UPDATE [dbo].[Participation] SET [from_time] = N'2026-04-17T00:00:00', [to_time] = N'2026-05-06T22:21:08.817' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';
-- step: 4
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003022, @dbo_Act_act_uid_5, N'PerAsReporterOfPHC', N'CASE', N'2026-05-06T22:11:00.673', @superuser_id, N'2026-05-06T22:21:08.720', @superuser_id, N'ACTIVE', N'2026-05-06T22:21:08.720', N'A', N'2026-05-06T22:21:08.720', N'PSN', N'PHC Reporter');
-- dbo.NBS_case_answer
-- step: 4
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_3_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'04/20/2026', 10001192, 3, N'2026-05-06T22:21:08.813', @superuser_id, N'OPEN', N'2026-05-06T22:21:08.813', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_3 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_3_output;
-- step: 4
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T22:21:08.813', [record_status_time] = N'2026-05-06T22:21:08.813' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10001013 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:11:00.673' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:11:00.673' AND [seq_nbr] = 0);
-- step: 4
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_4_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'720', 10001195, 3, N'2026-05-06T22:21:08.813', @superuser_id, N'OPEN', N'2026-05-06T22:21:08.813', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_4 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_4_output;
-- step: 4
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T22:21:08.813', [record_status_time] = N'2026-05-06T22:21:08.813' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'30' AND [nbs_question_uid] = 10001252 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:11:00.673' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:11:00.673' AND [seq_nbr] = 0);
-- dbo.NBS_act_entity
-- step: 4
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:21:08.813', [record_status_time] = N'2026-05-06T22:21:08.813' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003010 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitFupInvestgrOfPHC');
-- step: 4
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:21:08.813', [record_status_time] = N'2026-05-06T22:21:08.813' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003010 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InvestgrOfPHC');
-- step: 4
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:21:08.813', [record_status_time] = N'2026-05-06T22:21:08.813' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003019 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'OrgAsClinicOfPHC');
-- step: 4
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:21:08.813', [record_status_time] = N'2026-05-06T22:21:08.813' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003019 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'OrgAsReporterOfPHC');
-- step: 4
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_10_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003022, 1, N'2026-05-06T22:21:08.813', @superuser_id, N'OPEN', N'2026-05-06T22:21:08.813', N'PerAsReporterOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_10 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_10_output;
-- step: 4
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:21:08.813', [record_status_time] = N'2026-05-06T22:21:08.813' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'SubjOfPHC');
-- step: 4
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:21:08.813', [record_status_time] = N'2026-05-06T22:21:08.813' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003010 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'SurvInvestgrOfPHC');
-- dbo.Person
-- step: 4
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T22:21:08.767', [record_status_time] = N'2026-05-06T22:21:08.767', [status_time] = N'2026-05-06T22:21:08.767', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Entity_locator_participation
-- step: 4
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:21:08.767', [record_status_time] = N'2026-05-06T22:21:08.767', [status_time] = N'2026-05-06T22:21:08.767' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 4
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:21:08.767', [record_status_time] = N'2026-05-06T22:21:08.767', [status_time] = N'2026-05-06T22:21:08.767' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 4
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:21:08.767', [record_status_time] = N'2026-05-06T22:21:08.767', [status_time] = N'2026-05-06T22:21:08.767' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;
-- dbo.Person
-- step: 4
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T22:21:08.790', [record_status_time] = N'2026-05-06T22:21:08.790', [status_time] = N'2026-05-06T22:21:08.790', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_4;
-- dbo.Person_name
-- step: 4
UPDATE [dbo].[Person_name] SET [last_chg_time] = N'2026-05-06T22:21:08.690' WHERE [person_uid] = @dbo_Entity_entity_uid_4 AND [person_name_seq] = 1;
-- dbo.Entity_id
-- step: 4
UPDATE [dbo].[Entity_id] SET [last_chg_time] = N'2026-05-06T22:21:08.720' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_id_seq] = 1;
-- dbo.Postal_locator
-- step: 4
UPDATE [dbo].[Postal_locator] SET [last_chg_time] = N'2026-05-06T22:21:08.690', [last_chg_user_id] = @superuser_id, [street_addr2] = N'' WHERE [postal_locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;
-- dbo.Entity_locator_participation
-- step: 4
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:21:08.790', [record_status_time] = N'2026-05-06T22:21:08.790', [status_time] = N'2026-05-06T22:21:08.790' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;
-- dbo.Tele_locator
-- step: 4
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-05-06T22:21:08.690', [last_chg_user_id] = @superuser_id WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;
-- dbo.Entity_locator_participation
-- step: 4
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:21:08.790', [record_status_time] = N'2026-05-06T22:21:08.790', [status_time] = N'2026-05-06T22:21:08.790' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;
-- dbo.Tele_locator
-- step: 4
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-05-06T22:21:08.690', [last_chg_user_id] = @superuser_id WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;
-- dbo.Entity_locator_participation
-- step: 4
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:21:08.790', [record_status_time] = N'2026-05-06T22:21:08.790', [status_time] = N'2026-05-06T22:21:08.790' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;
-- dbo.Public_health_case
-- step: 4
UPDATE [dbo].[Public_health_case] SET [case_class_cd] = N'C', [cd] = N'10312', [cd_desc_txt] = N'Syphilis, secondary', [detection_method_cd] = N'21', [diagnosis_time] = N'2026-04-21T00:00:00', [effective_from_time] = N'2026-04-17T00:00:00', [last_chg_time] = N'2026-05-06T22:21:08.813', [pat_age_at_onset] = N'41', [pat_age_at_onset_unit_cd] = N'Y', [record_status_time] = N'2026-05-06T22:21:08.813', [transmission_mode_cd] = N'S', [transmission_mode_desc_txt] = N'S', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [hospitalized_ind_cd] = N'N' WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- dbo.Confirmation_method
-- step: 4
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_5, N'LD', N'2026-04-24T00:00:00');
-- dbo.Participation
-- step: 4
UPDATE [dbo].[Participation] SET [add_time] = N'2026-05-06T22:21:09.010', [last_chg_time] = N'2026-05-06T22:21:08.813', [record_status_time] = N'2026-05-06T22:21:08.813', [status_time] = N'2026-05-06T22:21:08.813', [to_time] = N'2026-05-06T22:21:09.010' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';
-- dbo.SubjectRaceInfo
-- step: 4
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_5 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';
-- dbo.PublicHealthCaseFact
-- step: 4
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- step: 4
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [onSetDate], [organizationName], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-24T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'21', N'Self Referral', N'2026-04-21T00:00:00', N'PST', N'2026-04-17T00:00:00', N'O', 1.0, N'O', N'Keable, Kristi', N'404-851-8000', N'130001', N'M', N'Married', N'2026-05-06T22:21:15.457', 18, 2026, N'2026-04-17T00:00:00', N'Emory University Hospital', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-05-06T22:11:00.673', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2026-05-06T22:11:00.547', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Nightingale, Florence', N'404-785-6000', N'2026-05-06T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-05-06T22:11:00.673', 10009283, @dbo_Person_local_id, N'2026-05-06T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Open', N'Years', N'STD', N' Laboratory confirmed', N'2026-05-06T22:21:08.813', N'N');
-- dbo.SubjectRaceInfo
-- step: 4
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');
-- STEP 5: Assign investigator for field follow up
-- dbo.message_log
-- step: 5
INSERT INTO [dbo].[message_log] ([message_txt], [condition_cd], [person_uid], [assigned_to_uid], [event_uid], [event_type_cd], [message_status_cd], [record_status_cd], [record_status_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[message_log_uid] INTO @dbo_message_log_message_log_uid_2_output ([value]) VALUES (N'New assignment', N'10312', @dbo_Entity_entity_uid_4, 10003004, 10009300, N'Investigation', N'N', N'ACTIVE', N'2026-05-06T22:27:49.240', N'2026-05-06T22:27:49.240', @superuser_id, N'2026-05-06T22:27:49.240', @superuser_id);
SELECT TOP 1 @dbo_message_log_message_log_uid_2 = [value] FROM @dbo_message_log_message_log_uid_2_output;
-- dbo.Participation
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_5, N'DispoFldFupInvestgrOfPHC', N'CASE', N'2026-05-06T22:11:00.673', @superuser_id, N'2026-05-06T22:27:49.310', @superuser_id, N'ACTIVE', N'2026-05-06T22:27:49.310', N'A', N'2026-05-06T22:27:49.310', N'PSN');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003013, @dbo_Act_act_uid_5, N'FldFupInvestgrOfPHC', N'CASE', N'2026-05-06T22:11:00.673', @superuser_id, N'2026-05-06T22:27:49.310', @superuser_id, N'ACTIVE', N'2026-05-06T22:27:49.310', N'A', N'2026-05-06T22:27:49.310', N'PSN');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_5, N'FldFupSupervisorOfPHC', N'CASE', N'2026-05-06T22:11:00.673', @superuser_id, N'2026-05-06T22:27:49.310', @superuser_id, N'ACTIVE', N'2026-05-06T22:27:49.310', N'A', N'2026-05-06T22:27:49.310', N'PSN');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003013, @dbo_Act_act_uid_5, N'InitFldFupInvestgrOfPHC', N'CASE', N'2026-05-06T22:11:00.673', @superuser_id, N'2026-05-06T22:27:49.310', @superuser_id, N'ACTIVE', N'2026-05-06T22:27:49.310', N'A', N'2026-05-06T22:27:49.310', N'PSN');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_5, N'InitInterviewerOfPHC', N'CASE', N'2026-05-06T22:11:00.673', @superuser_id, N'2026-05-06T22:27:49.310', @superuser_id, N'ACTIVE', N'2026-05-06T22:27:49.310', N'A', N'2026-05-06T22:27:49.310', N'PSN');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_5, N'InterviewerOfPHC', N'CASE', N'2026-05-06T22:11:00.673', @superuser_id, N'2026-05-06T22:27:49.310', @superuser_id, N'ACTIVE', N'2026-05-06T22:27:49.310', N'A', N'2026-05-06T22:27:49.310', N'PSN');
-- step: 5
DELETE FROM [dbo].[Participation] WHERE [subject_entity_uid] = 10003010 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'InvestgrOfPHC';
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003004, @dbo_Act_act_uid_5, N'InvestgrOfPHC', N'CASE', N'2026-05-06T22:11:00.673', @superuser_id, N'2026-05-06T22:27:49.310', @superuser_id, N'ACTIVE', N'2026-05-06T22:27:49.310', N'A', N'2026-05-06T22:27:49.310', N'PSN', N'PHC Investigator');
-- dbo.NBS_case_answer
-- step: 5
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T22:27:49.370', [record_status_time] = N'2026-05-06T22:27:49.370' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'04/20/2026' AND [nbs_question_uid] = 10001192 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:21:08.813' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:21:08.813' AND [seq_nbr] = 0);
-- step: 5
-- UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T22:27:49.370', [record_status_time] = N'2026-05-06T22:27:49.370' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10001013 AND [nbs_question_version_ctrl_nbr] = 3 AND AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [seq_nbr] = 0);
-- step: 5
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T22:27:49.370', [record_status_time] = N'2026-05-06T22:27:49.370' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'720' AND [nbs_question_uid] = 10001195 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_time] = N'2026-05-06T22:21:08.813' AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [record_status_time] = N'2026-05-06T22:21:08.813' AND [seq_nbr] = 0);
-- step: 5
-- updated
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T22:27:49.370', [record_status_time] = N'2026-05-06T22:27:49.370' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'30' AND [nbs_question_uid] = 10001252 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [seq_nbr] = 0);
-- dbo.NBS_act_entity
-- step: 5
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_11_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003004, 1, N'2026-05-06T22:27:49.370', @superuser_id, N'OPEN', N'2026-05-06T22:27:49.370', N'DispoFldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_11 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_11_output;
-- step: 5
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_12_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003013, 1, N'2026-05-06T22:27:49.370', @superuser_id, N'OPEN', N'2026-05-06T22:27:49.370', N'FldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_12 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_12_output;
-- step: 5
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_13_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003004, 1, N'2026-05-06T22:27:49.370', @superuser_id, N'OPEN', N'2026-05-06T22:27:49.370', N'FldFupSupervisorOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_13 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_13_output;
-- step: 5
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_14_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003013, 1, N'2026-05-06T22:27:49.370', @superuser_id, N'OPEN', N'2026-05-06T22:27:49.370', N'InitFldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_14 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_14_output;
-- step: 5
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:27:49.370', [record_status_time] = N'2026-05-06T22:27:49.370' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003010 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitFupInvestgrOfPHC');
-- step: 5
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_15_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003004, 1, N'2026-05-06T22:27:49.370', @superuser_id, N'OPEN', N'2026-05-06T22:27:49.370', N'InitInterviewerOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_15 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_15_output;
-- step: 5
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_16_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003004, 1, N'2026-05-06T22:27:49.370', @superuser_id, N'OPEN', N'2026-05-06T22:27:49.370', N'InterviewerOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_16 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_16_output;
-- step: 5
DELETE FROM [dbo].[NBS_act_entity] WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003010 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InvestgrOfPHC');
-- step: 5
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_17_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, 10003004, 1, N'2026-05-06T22:27:49.370', @superuser_id, N'OPEN', N'2026-05-06T22:27:49.370', N'InvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_17 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_17_output;
-- step: 5
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:27:49.370', [record_status_time] = N'2026-05-06T22:27:49.370' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003019 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'OrgAsClinicOfPHC');
-- step: 5
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:27:49.370', [record_status_time] = N'2026-05-06T22:27:49.370' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003019 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'OrgAsReporterOfPHC');
-- step: 5
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:27:49.370', [record_status_time] = N'2026-05-06T22:27:49.370' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003022 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'PerAsReporterOfPHC');
-- step: 5
UPDATE [dbo].[NBS_act_entity] SET [entity_version_ctrl_nbr] = 2, [last_chg_time] = N'2026-05-06T22:27:49.370', [record_status_time] = N'2026-05-06T22:27:49.370' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'SubjOfPHC');
-- step: 5
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:27:49.370', [record_status_time] = N'2026-05-06T22:27:49.370' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003010 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'SurvInvestgrOfPHC');
-- dbo.Person
-- step: 5
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T22:27:49.347', [record_status_time] = N'2026-05-06T22:27:49.347', [status_time] = N'2026-05-06T22:27:49.347', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Entity_locator_participation
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:27:49.347', [record_status_time] = N'2026-05-06T22:27:49.347', [status_time] = N'2026-05-06T22:27:49.347' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:27:49.347', [record_status_time] = N'2026-05-06T22:27:49.347', [status_time] = N'2026-05-06T22:27:49.347' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:27:49.347', [record_status_time] = N'2026-05-06T22:27:49.347', [status_time] = N'2026-05-06T22:27:49.347' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;
-- dbo.Person
-- step: 5
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T22:27:49.353', [record_status_time] = N'2026-05-06T22:27:49.353', [status_time] = N'2026-05-06T22:27:49.353', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_4;
-- dbo.Person_name
-- step: 5
UPDATE [dbo].[Person_name] SET [last_chg_time] = N'2026-05-06T22:27:49.243' WHERE [person_uid] = @dbo_Entity_entity_uid_4 AND [person_name_seq] = 1;
-- dbo.Entity_id
-- step: 5
UPDATE [dbo].[Entity_id] SET [last_chg_time] = N'2026-05-06T22:27:49.310' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_id_seq] = 1;
-- dbo.Postal_locator
-- step: 5
UPDATE [dbo].[Postal_locator] SET [last_chg_time] = N'2026-05-06T22:27:49.243' WHERE [postal_locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;
-- dbo.Entity_locator_participation
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:27:49.353', [record_status_time] = N'2026-05-06T22:27:49.353', [status_time] = N'2026-05-06T22:27:49.353' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;
-- dbo.Tele_locator
-- step: 5
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-05-06T22:27:49.243' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;
-- dbo.Entity_locator_participation
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:27:49.353', [record_status_time] = N'2026-05-06T22:27:49.353', [status_time] = N'2026-05-06T22:27:49.353' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;
-- dbo.Tele_locator
-- step: 5
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-05-06T22:27:49.243' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;
-- dbo.Entity_locator_participation
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:27:49.353', [record_status_time] = N'2026-05-06T22:27:49.353', [status_time] = N'2026-05-06T22:27:49.353' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;
-- dbo.Public_health_case
-- step: 5
UPDATE [dbo].[Public_health_case] SET [last_chg_time] = N'2026-05-06T22:27:49.370', [record_status_time] = N'2026-05-06T22:27:49.370', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [curr_process_state_cd] = N'AI' WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- dbo.Confirmation_method
-- step: 5
DELETE FROM [dbo].[Confirmation_method] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5 AND [confirmation_method_cd] = N'LD';
-- step: 5
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_5, N'LD', N'2026-04-24T00:00:00');
-- dbo.case_management
-- step: 5
UPDATE [dbo].[case_management] SET [fld_foll_up_dispo] = N'C', [fld_foll_up_dispo_date] = N'2026-04-25T00:00:00', [fld_foll_up_notification_plan] = N'3', [init_foll_up_notifiable] = N'06', [pat_intv_status_cd] = N'A', [surv_patient_foll_up] = N'FF', [foll_up_assigned_date] = N'2026-04-25T00:00:00', [init_foll_up_assigned_date] = N'2026-04-25T00:00:00', [interview_assigned_date] = N'2026-04-25T00:00:00', [init_interview_assigned_date] = N'2026-04-25T00:00:00' WHERE [case_management_uid] = (SELECT TOP 1 [case_management_uid] FROM [dbo].[case_management] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5 AND [epi_link_id] = N'1310000026' AND [field_record_number] = N'1310000026' AND [init_foll_up] = N'SF' AND [surv_assigned_date] = N'2026-04-24T00:00:00');
-- dbo.Participation
-- step: 5
UPDATE [dbo].[Participation] SET [add_time] = N'2026-05-06T22:27:49.557', [last_chg_time] = N'2026-05-06T22:27:49.370', [record_status_time] = N'2026-05-06T22:27:49.370', [status_time] = N'2026-05-06T22:27:49.370' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';
-- dbo.SubjectRaceInfo
-- step: 5
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_5 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';
-- dbo.PublicHealthCaseFact
-- step: 5
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- step: 5
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [onSetDate], [organizationName], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-24T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'21', N'Self Referral', N'2026-04-21T00:00:00', N'PST', N'2026-04-17T00:00:00', N'O', 1.0, N'O', N'Xerogeanes, John', N'404-778-3350', N'130001', N'M', N'Married', N'2026-05-06T22:27:53.587', 18, 2026, N'2026-04-17T00:00:00', N'Emory University Hospital', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-05-06T22:11:00.673', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2026-05-06T22:11:00.547', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Nightingale, Florence', N'404-785-6000', N'2026-05-06T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-05-06T22:11:00.673', 10009283, @dbo_Person_local_id, N'2026-05-06T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Open', N'Years', N'STD', N' Laboratory confirmed', N'2026-05-06T22:27:49.370', N'N');
-- dbo.SubjectRaceInfo
-- step: 5
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');
-- STEP 6: Patient interview
-- dbo.NBS_case_answer
-- step: 6
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'N' AND [nbs_question_uid] = 10001013 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [seq_nbr] = 0);
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_5_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'04/24/2026', 10001326, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_5 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_5_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_6_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'N', 10001327, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_6 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_6_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_7_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'Y', 10001325, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_7 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_7_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_8_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'R', 10001285, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_8 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_8_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_9_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'N', 10001331, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_9 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_9_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_10_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'N', 10001283, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_10 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_10_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_11_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'Y', 10001289, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_11 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_11_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_12_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'5', 10001290, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_12 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_12_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_13_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'2', 10003231, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_13 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_13_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_14_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'N', 10001316, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_14 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_14_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_15_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'Y', 10001287, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_15 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_15_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_16_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'N', 10003230, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_16 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_16_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_17_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'2', 10001288, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_17 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_17_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_18_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'Y', 10001302, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_18 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_18_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_19_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'N', 10001295, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_19 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_19_output;
-- step: 6
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'30' AND [nbs_question_uid] = 10001252 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [seq_nbr] = 0);
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_20_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'N', 10001291, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_20 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_20_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_21_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'Y', 10001296, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_21 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_21_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_22_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'1', 10001297, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_22 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_22_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_23_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'7', 10001293, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_23 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_23_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_24_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'N', 10001300, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_24 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_24_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_25_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'N', 10001322, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_25 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_25_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_26_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'Y', 10001298, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_26 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_26_output;
-- step: 6
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'04/20/2026' AND [nbs_question_uid] = 10001192 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [seq_nbr] = 0);
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_27_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'2', 10001299, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_27 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_27_output;
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_28_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'N', 10001294, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_28 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_28_output;
-- step: 6
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_case_answer_uid] = (SELECT TOP 1 [nbs_case_answer_uid] FROM [dbo].[NBS_case_answer] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_time] = N'2026-05-06T22:11:00.673' AND [add_user_id] = 10009282 AND [answer_txt] = N'720' AND [nbs_question_uid] = 10001195 AND [nbs_question_version_ctrl_nbr] = 3 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [seq_nbr] = 0);
-- step: 6
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_29_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-05-06T22:11:00.673', @superuser_id, N'1', 10001321, 3, N'2026-05-06T22:36:22.750', @superuser_id, N'OPEN', N'2026-05-06T22:36:22.750', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_29 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_29_output;
-- dbo.NBS_act_entity
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'DispoFldFupInvestgrOfPHC');
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003013 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'FldFupInvestgrOfPHC');
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'FldFupSupervisorOfPHC');
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003013 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitFldFupInvestgrOfPHC');
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003010 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitFupInvestgrOfPHC');
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InitInterviewerOfPHC');
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InterviewerOfPHC');
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003004 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'InvestgrOfPHC');
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003019 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'OrgAsClinicOfPHC');
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003019 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'OrgAsReporterOfPHC');
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003022 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'PerAsReporterOfPHC');
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [entity_version_ctrl_nbr] = 3, [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_version_ctrl_nbr] = 2 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'SubjOfPHC');
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750' WHERE [nbs_act_entity_uid] = (SELECT TOP 1 [nbs_act_entity_uid] FROM [dbo].[NBS_act_entity] WHERE [act_uid] = @dbo_Act_act_uid_5 AND [add_user_id] = 10009282 AND [entity_uid] = 10003010 AND [entity_version_ctrl_nbr] = 1 AND [last_chg_user_id] = 10009282 AND [record_status_cd] = N'OPEN' AND [type_cd] = N'SurvInvestgrOfPHC');
-- dbo.Person
-- step: 6
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T22:36:22.720', [record_status_time] = N'2026-05-06T22:36:22.720', [status_time] = N'2026-05-06T22:36:22.720', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Entity_locator_participation
-- step: 6
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:36:22.720', [record_status_time] = N'2026-05-06T22:36:22.720', [status_time] = N'2026-05-06T22:36:22.720' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 6
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:36:22.720', [record_status_time] = N'2026-05-06T22:36:22.720', [status_time] = N'2026-05-06T22:36:22.720' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 6
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:36:22.720', [record_status_time] = N'2026-05-06T22:36:22.720', [status_time] = N'2026-05-06T22:36:22.720' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;
-- dbo.Person
-- step: 6
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-06T22:36:22.730', [record_status_time] = N'2026-05-06T22:36:22.730', [status_time] = N'2026-05-06T22:36:22.730', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_4;
-- dbo.Person_name
-- step: 6
UPDATE [dbo].[Person_name] SET [last_chg_time] = N'2026-05-06T22:36:22.657' WHERE [person_uid] = @dbo_Entity_entity_uid_4 AND [person_name_seq] = 1;
-- dbo.Entity_id
-- step: 6
UPDATE [dbo].[Entity_id] SET [last_chg_time] = N'2026-05-06T22:36:22.677' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_id_seq] = 1;
-- dbo.Postal_locator
-- step: 6
UPDATE [dbo].[Postal_locator] SET [last_chg_time] = N'2026-05-06T22:36:22.657' WHERE [postal_locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;
-- dbo.Entity_locator_participation
-- step: 6
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:36:22.730', [record_status_time] = N'2026-05-06T22:36:22.730', [status_time] = N'2026-05-06T22:36:22.730' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;
-- dbo.Tele_locator
-- step: 6
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-05-06T22:36:22.657' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;
-- dbo.Entity_locator_participation
-- step: 6
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:36:22.730', [record_status_time] = N'2026-05-06T22:36:22.730', [status_time] = N'2026-05-06T22:36:22.730' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;
-- dbo.Tele_locator
-- step: 6
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-05-06T22:36:22.657' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;
-- dbo.Entity_locator_participation
-- step: 6
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-06T22:36:22.730', [record_status_time] = N'2026-05-06T22:36:22.730', [status_time] = N'2026-05-06T22:36:22.730' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;
-- dbo.Public_health_case
-- step: 6
UPDATE [dbo].[Public_health_case] SET [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [curr_process_state_cd] = N'OC' WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- dbo.Confirmation_method
-- step: 6
DELETE FROM [dbo].[Confirmation_method] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5 AND [confirmation_method_cd] = N'LD';
-- step: 6
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_5, N'LD', N'2026-04-24T00:00:00');
-- dbo.case_management
-- step: 6
UPDATE [dbo].[case_management] SET [pat_intv_status_cd] = N'I' WHERE [case_management_uid] = (SELECT TOP 1 [case_management_uid] FROM [dbo].[case_management] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5 AND [epi_link_id] = N'1310000026' AND [field_record_number] = N'1310000026' AND [init_foll_up] = N'SF' AND [surv_assigned_date] = N'2026-04-24T00:00:00');
-- dbo.Participation
-- step: 6
UPDATE [dbo].[Participation] SET [add_time] = N'2026-05-06T22:36:22.923', [last_chg_time] = N'2026-05-06T22:36:22.750', [record_status_time] = N'2026-05-06T22:36:22.750', [status_time] = N'2026-05-06T22:36:22.750' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';
-- dbo.Act
-- step: 6
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_7, N'IXS', N'EVN');
-- dbo.Interview
-- step: 6
INSERT INTO [dbo].[Interview] ([interview_uid], [interview_status_cd], [interview_date], [interviewee_role_cd], [interview_type_cd], [interview_loc_cd], [local_id], [record_status_cd], [record_status_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_7, N'COMPLETE', N'2026-04-24T00:00:00', N'SUBJECT', N'INITIAL', N'T', @dbo_Interview_local_id, N'ACTIVE', N'2026-05-06T22:36:25.797', N'2026-05-06T22:36:25.797', @superuser_id, N'2026-05-06T22:36:25.797', @superuser_id, 1);
-- dbo.nbs_answer
-- step: 6
INSERT INTO [dbo].[nbs_answer] ([act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [seq_nbr], [record_status_cd], [record_status_time], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[nbs_answer_uid] INTO @dbo_nbs_answer_nbs_answer_uid_output ([value]) VALUES (@dbo_Act_act_uid_7, N'Y', 10001355, 3, 0, N'ACTIVE', N'2026-05-06T22:36:25.797', N'2026-05-06T22:36:25.797', @superuser_id);
SELECT TOP 1 @dbo_nbs_answer_nbs_answer_uid = [value] FROM @dbo_nbs_answer_nbs_answer_uid_output;
-- step: 6
INSERT INTO [dbo].[nbs_answer] ([act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [seq_nbr], [answer_group_seq_nbr], [record_status_cd], [record_status_time], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[nbs_answer_uid] INTO @dbo_nbs_answer_nbs_answer_uid_2_output ([value]) VALUES (@dbo_Act_act_uid_7, N'Ariella Kent~05/06/2026 18:36~~asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say.', 10001024, 3, 0, 1, N'ACTIVE', N'2026-05-06T22:36:25.797', N'2026-05-06T22:36:25.797', @superuser_id);
SELECT TOP 1 @dbo_nbs_answer_nbs_answer_uid_2 = [value] FROM @dbo_nbs_answer_nbs_answer_uid_2_output;
-- dbo.NBS_act_entity
-- step: 6
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_18_output ([value]) VALUES (@dbo_Act_act_uid_7, N'2026-05-06T22:36:25.797', @superuser_id, 10003004, 4, N'2026-05-06T22:36:25.797', @superuser_id, N'ACTIVE', N'2026-05-06T22:36:25.797', N'IntrvwerOfInterview');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_18 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_18_output;
-- step: 6
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_19_output ([value]) VALUES (@dbo_Act_act_uid_7, N'2026-05-06T22:36:25.797', @superuser_id, @dbo_Entity_entity_uid_4, 4, N'2026-05-06T22:36:25.797', @superuser_id, N'ACTIVE', N'2026-05-06T22:36:25.797', N'IntrvweeOfInterview');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_19 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_19_output;
-- dbo.Participation
-- step: 6
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_7, N'IntrvwerOfInterview', N'IXS', N'2026-05-06T22:36:25.797', @superuser_id, N'2026-05-06T22:36:25.797', @superuser_id, N'ACTIVE', N'2026-05-06T22:36:25.797', N'A', N'2026-05-06T22:36:25.797', N'PSN');
-- step: 6
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Act_act_uid_7, N'IntrvweeOfInterview', N'IXS', N'2026-05-06T22:36:25.797', @superuser_id, N'2026-05-06T22:36:25.797', @superuser_id, N'ACTIVE', N'2026-05-06T22:36:25.797', N'A', N'2026-05-06T22:36:25.797', N'PSN');
-- dbo.Act_relationship
-- step: 6
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_reason_cd], [add_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_5, @dbo_Act_act_uid_7, N'IXS', N'because', N'2026-05-06T22:36:25.830', N'2026-05-06T22:36:25.830', @superuser_id, N'ACTIVE', N'2026-05-06T22:36:25.830', N'OBS', N'A', N'2026-05-06T22:36:25.830', N'CASE');
-- dbo.SubjectRaceInfo
-- step: 6
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_5 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';
-- dbo.PublicHealthCaseFact
-- step: 6
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- step: 6
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [onSetDate], [organizationName], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-24T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'21', N'Self Referral', N'2026-04-21T00:00:00', N'PST', N'2026-04-17T00:00:00', N'O', 1.0, N'O', N'Xerogeanes, John', N'404-778-3350', N'130001', N'M', N'Married', N'2026-05-06T22:36:27.310', 18, 2026, N'2026-04-17T00:00:00', N'Emory University Hospital', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-05-06T22:11:00.673', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2026-05-06T22:11:00.547', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Nightingale, Florence', N'404-785-6000', N'2026-05-06T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-05-06T22:11:00.673', 10009283, @dbo_Person_local_id, N'2026-05-06T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Open', N'Years', N'STD', N' Laboratory confirmed', N'2026-05-06T22:36:22.750', N'N');
-- dbo.SubjectRaceInfo
-- step: 6
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');
