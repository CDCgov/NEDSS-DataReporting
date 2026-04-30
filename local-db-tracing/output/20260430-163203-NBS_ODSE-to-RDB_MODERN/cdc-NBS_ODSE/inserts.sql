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

-- STEP 1: CreatePatientAndLabReportSyphilis

-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid, N'PSN');

-- dbo.Person
-- step: 1
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [birth_gender_cd], [birth_time], [birth_time_calc], [cd], [curr_sex_cd], [deceased_ind_cd], [last_chg_time], [last_chg_user_id], [local_id], [marital_status_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid], [edx_ind]) VALUES (@dbo_Entity_entity_uid, N'2026-04-30T19:27:29.850', @superuser_id, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'PAT', N'F', N'N', N'2026-04-30T19:27:29.850', @superuser_id, @dbo_Person_local_id, N'M', N'ACTIVE', N'2026-04-30T19:27:29.850', N'A', N'2026-04-30T19:27:29.850', N'Taylor', N'Swift_fake77gg', 1, N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'N', @dbo_Entity_entity_uid, N'Y');

-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [first_nm], [first_nm_sndx], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid, 1, N'Add', N'2026-04-30T19:27:29.740', N'Taylor', N'T460', N'Swift_fake77gg', N'S130', N'L', N'ACTIVE', N'2026-04-30T19:27:29.740', N'A', N'2026-04-30T19:27:29.740', N'2026-04-30T00:00:00');

-- dbo.Person_race
-- step: 1
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [race_category_cd], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid, N'2106-3', N'2026-04-30T19:27:29.767', N'2106-3', N'ACTIVE', N'2026-04-30T00:00:00');

-- dbo.Entity_id
-- step: 1
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [assigning_authority_cd], [assigning_authority_desc_txt], [last_chg_time], [record_status_cd], [record_status_time], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid, 1, N'2026-04-30T19:27:29.740', N'GA', N'GA', N'2026-04-30T19:27:29.740', N'ACTIVE', N'2026-04-30T19:27:29.740', N'123987456', N'A', N'2026-04-30T19:27:29.740', N'DL', N'Driver''s license number', N'2026-04-30T00:00:00', N'L');

-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [city_desc_txt], [cntry_cd], [cnty_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [street_addr2], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid, N'2026-04-30T19:27:29.767', N'Atlanta', N'840', N'13121', N'ACTIVE', N'2026-04-30T19:27:29.767', N'13', N'1313 Pine Way', N'', N'30033');

-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Postal_locator_postal_locator_uid, N'H', N'PST', N'2026-04-30T19:27:29.850', @superuser_id, N'ACTIVE', N'2026-04-30T19:27:29.850', N'A', N'2026-04-30T19:27:29.850', N'H', 1, N'2026-04-30T00:00:00');

-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid, N'2026-04-30T19:27:29.767', @superuser_id, N'201-555-1212', N'ACTIVE');

-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Tele_locator_tele_locator_uid, N'PH', N'TELE', N'2026-04-30T19:27:29.850', @superuser_id, N'ACTIVE', N'2026-04-30T19:27:29.850', N'A', N'2026-04-30T19:27:29.850', N'H', 1, N'2026-04-30T00:00:00');

-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_2, N'2026-04-30T19:27:29.767', @superuser_id, N'taylor@example.com', N'ACTIVE');

-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Tele_locator_tele_locator_uid_2, N'NET', N'TELE', N'2026-04-30T19:27:29.850', @superuser_id, N'ACTIVE', N'2026-04-30T19:27:29.850', N'A', N'2026-04-30T19:27:29.850', N'H', 1, N'2026-04-30T00:00:00');

-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_2, N'PSN');

-- dbo.Person
-- step: 1
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [age_reported], [age_reported_unit_cd], [birth_time], [birth_time_calc], [cd], [curr_sex_cd], [deceased_ind_cd], [last_chg_time], [last_chg_user_id], [local_id], [marital_status_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_2, N'2026-04-30T19:27:33.873', @superuser_id, N'41', N'Y', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'PAT', N'F', N'N', N'2026-04-30T19:27:33.873', @superuser_id, @dbo_Person_local_id, N'M', N'ACTIVE', N'2026-04-30T19:27:33.873', N'A', N'2026-04-30T19:27:33.873', N'Taylor', N'Swift_fake77gg', 1, N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'N', @dbo_Entity_entity_uid);

-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, 1, N'ADD LAB REPORT', N'2026-04-30T19:27:33.763', @superuser_id, N'Taylor', N'T460', N'2026-04-30T19:27:33.763', @superuser_id, N'Swift_fake77gg', N'S130', N'L', N'ACTIVE', N'2026-04-30T19:27:33.763', N'A', N'2026-04-30T19:27:33.763', N'2026-04-30T00:00:00');

-- dbo.Person_race
-- step: 1
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [add_user_id], [race_category_cd], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, N'2106-3', N'2026-04-30T19:27:33.763', @superuser_id, N'2106-3', N'ACTIVE', N'2026-04-30T00:00:00');

-- dbo.Entity_id
-- step: 1
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [assigning_authority_cd], [assigning_authority_desc_txt], [last_chg_time], [record_status_cd], [record_status_time], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid_2, 1, N'2026-04-30T19:27:33.817', N'GA', N'GA', N'2026-04-30T19:27:33.817', N'ACTIVE', N'2026-04-30T19:27:33.817', N'123987456', N'A', N'2026-04-30T19:27:33.817', N'DL', N'Driver''s license number', N'2026-04-30T00:00:00', N'L');

-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt], [cntry_cd], [cnty_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_2, N'2026-04-30T19:27:33.763', @superuser_id, N'Atlanta', N'840', N'13121', N'ACTIVE', N'2026-04-30T19:27:33.763', N'13', N'1313 Pine Way', N'30033');

-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Postal_locator_postal_locator_uid_2, N'H', N'PST', N'2026-04-30T19:27:33.873', @superuser_id, N'ACTIVE', N'2026-04-30T19:27:33.873', N'A', N'2026-04-30T19:27:33.873', N'H', 1, N'2026-04-30T00:00:00');

-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_3, N'2026-04-30T19:27:33.763', @superuser_id, N'', N'201-555-1212', N'ACTIVE');

-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Tele_locator_tele_locator_uid_3, N'PH', N'TELE', N'2026-04-30T19:27:33.873', @superuser_id, N'ACTIVE', N'2026-04-30T19:27:33.873', N'A', N'2026-04-30T19:27:33.873', N'H', 1, N'2026-04-30T00:00:00');

-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_4, N'2026-04-30T19:27:33.763', @superuser_id, N'taylor@example.com', N'ACTIVE');

-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Tele_locator_tele_locator_uid_4, N'NET', N'TELE', N'2026-04-30T19:27:33.873', @superuser_id, N'ACTIVE', N'2026-04-30T19:27:33.873', N'A', N'2026-04-30T19:27:33.873', N'H', 1, N'2026-04-30T00:00:00');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [electronic_ind], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [obs_domain_cd_st_1], [prog_area_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [target_site_cd], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [rpt_to_state_time], [pregnant_ind_cd], [pregnant_week]) VALUES (@dbo_Act_act_uid, N'2026-04-20T00:00:00', N'ADD LAB REPORT', N'2026-04-30T19:27:33.910', @superuser_id, N'T-14900', N'No Information Given', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'N', N'130001', N'2026-04-30T19:27:33.910', @superuser_id, @dbo_Observation_local_id, N'Order', N'STD', N'UNPROCESSED', N'2026-04-30T19:27:33.910', N'D', N'2026-04-30T19:27:33.767', N'NI', 1300100015, N'T', 1, N'2026-04-30T00:00:00', N'Y', 30);

-- dbo.Act_id
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, 0, N'Default Manual Lab', N'ACTIVE', N'', N'A', N'2026-04-30T19:27:33.777', N'FN', N'Filler Number');

-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq]) VALUES (@dbo_Act_act_uid, 0);

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_2, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_2 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_2))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [local_id], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [rpt_to_state_time]) VALUES (@dbo_Act_act_uid_2, N'2026-04-20T00:00:00', N'NI', N'No Information Given', N'2.16.840.1.113883', N'LabComment', N'Lab Report', @dbo_Observation_local_id_2, N'C_Order', N'D', N'2026-04-30T19:27:33.777', 4, N'T', 1, N'2026-04-30T00:00:00');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_3, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_3 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_3))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [local_id], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_3, N'2026-04-30T19:27:33.777', @superuser_id, N'LAB214', N'User Report Comment', N'NBS', N'NEDSS Base System', N'LabComment', @dbo_Observation_local_id_3, N'C_Result', N'D', N'2026-04-30T19:27:33.777', 4, N'T', 1);

-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq], [value_txt], [value_large_txt]) VALUES (@dbo_Act_act_uid_3, 1, N'some comments', N'some comments');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_4, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_4 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_4))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [add_reason_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [electronic_ind], [local_id], [obs_domain_cd_st_1], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd]) VALUES (@dbo_Act_act_uid_4, N'ADD LAB REPORT', N'T-58955', N'RPR Titer ', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'N', @dbo_Observation_local_id_4, N'Result', N'2026-04-30T19:27:33.783', 4, N'T', 1, N'31147-2', N'REAGIN AB', N'LN');

-- dbo.Obs_value_numeric
-- step: 1
INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid], [obs_value_numeric_seq], [comparator_cd_1], [numeric_value_1], [numeric_value_2], [separator_cd], [numeric_scale_1], [numeric_scale_2]) VALUES (@dbo_Act_act_uid_4, 0, N'=', 1.0, 128.0, N':', 0, 0);

-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_3, N'MAT');

-- dbo.Material
-- step: 1
DECLARE @dbo_Material_local_id nvarchar(40) = N'MAT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_3))) + N'GA01';
INSERT INTO [dbo].[Material] ([material_uid], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid_3, N'Add', N'2026-04-30T19:27:34.010', @superuser_id, N'', N'', N'2026-04-30T19:27:34.010', @superuser_id, @dbo_Material_local_id, N'ACTIVE', N'2026-04-30T19:27:34.010', N'A', N'2026-04-30T19:27:34.010', 1);

-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003019, @dbo_Act_act_uid, N'AUT', N'OBS', N'2026-04-30T19:27:33.753', @superuser_id, N'2026-04-30T19:27:33.753', @superuser_id, N'ACTIVE', N'2026-04-30T19:27:33.760', N'A', N'2026-04-30T19:27:33.760', N'ORG', N'Author');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Act_act_uid, N'PATSBJ', N'OBS', N'2026-04-30T19:27:33.760', @superuser_id, N'2026-04-30T19:27:33.760', @superuser_id, N'ACTIVE', N'2026-04-30T19:27:33.760', N'A', N'2026-04-30T19:27:33.760', N'PSN', N'Patient subject');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_3, @dbo_Act_act_uid, N'SPC', N'OBS', N'2026-04-30T19:27:33.777', @superuser_id, N'2026-04-30T19:27:33.777', @superuser_id, N'ACTIVE', N'A', N'2026-04-30T19:27:33.777', N'MAT', N'Specimen');

-- dbo.Act_relationship
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_2, @dbo_Act_act_uid_3, N'COMP', N'2026-04-30T19:27:34.057', N'2026-04-30T19:27:34.057', N'ACTIVE', N'2026-04-30T19:27:34.057', N'OBS', N'A', N'2026-04-30T19:27:34.057', N'OBS', N'Is Cause For');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_2, N'APND', N'2026-04-30T19:27:34.067', N'2026-04-30T19:27:34.067', N'ACTIVE', N'2026-04-30T19:27:34.067', N'OBS', N'A', N'2026-04-30T19:27:34.067', N'OBS', N'Appends');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_4, N'COMP', N'2026-04-30T19:27:34.067', N'2026-04-30T19:27:34.067', N'ACTIVE', N'2026-04-30T19:27:34.067', N'OBS', N'A', N'2026-04-30T19:27:34.067', N'OBS', N'Has Component');

-- dbo.Role
-- step: 1
INSERT INTO [dbo].[Role] ([subject_entity_uid], [cd], [role_seq], [add_time], [cd_desc_txt], [effective_from_time], [effective_to_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [scoping_class_cd], [scoping_entity_uid], [scoping_role_cd], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_3, N'NI', 0, N'2026-04-30T19:27:34.073', N'No Information Given', N'2026-04-30T19:27:34.073', N'2026-04-30T19:27:34.073', N'2026-04-30T19:27:34.070', @superuser_id, N'ACTIVE', N'2026-04-30T19:27:34.070', N'PSN', @dbo_Entity_entity_uid_2, N'PAT', N'A', N'2026-04-30T19:27:34.070', N'SPEC');

-- dbo.Person
-- step: 1
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T19:27:33.867', [record_status_time] = N'2026-04-30T19:27:33.867', [status_time] = N'2026-04-30T19:27:33.867', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:27:33.867', [record_status_time] = N'2026-04-30T19:27:33.867', [status_time] = N'2026-04-30T19:27:33.867' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:27:33.867', [record_status_time] = N'2026-04-30T19:27:33.867', [status_time] = N'2026-04-30T19:27:33.867' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:27:33.867', [record_status_time] = N'2026-04-30T19:27:33.867', [status_time] = N'2026-04-30T19:27:33.867' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;

-- STEP 2: CreateInvestigationSyphilis

-- dbo.Entity
-- step: 2
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_4, N'PSN');

-- dbo.Person
-- step: 2
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [age_reported], [age_reported_unit_cd], [birth_gender_cd], [birth_time], [birth_time_calc], [cd], [curr_sex_cd], [deceased_ind_cd], [last_chg_time], [last_chg_user_id], [local_id], [marital_status_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_4, N'2026-04-30T19:32:00.600', @superuser_id, N'41', N'Y', N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'PAT', N'F', N'N', N'2026-04-30T19:32:00.600', @superuser_id, @dbo_Person_local_id, N'M', N'ACTIVE', N'2026-04-30T19:32:00.600', N'A', N'2026-04-30T19:32:00.600', N'Taylor', N'Swift_fake77gg', 1, N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'2026-04-30T00:00:00', N'N', @dbo_Entity_entity_uid);

-- dbo.Person_name
-- step: 2
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, 1, N'2026-04-30T19:32:00.493', @superuser_id, N'Taylor', N'T460', N'2026-04-30T19:32:00.493', @superuser_id, N'Swift_fake77gg', N'S130', N'L', N'ACTIVE', N'2026-04-30T19:32:00.493', N'A', N'2026-04-30T19:32:00.493', N'2026-04-30T00:00:00');

-- dbo.Person_race
-- step: 2
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [add_user_id], [race_category_cd], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, N'2106-3', N'2026-04-30T19:32:00.493', @superuser_id, N'2106-3', N'ACTIVE', N'2026-04-30T00:00:00');

-- dbo.Entity_id
-- step: 2
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [assigning_authority_cd], [assigning_authority_desc_txt], [last_chg_time], [record_status_cd], [record_status_time], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid_4, 1, N'2026-04-30T19:32:00.520', N'GA', N'GA', N'2026-04-30T19:32:00.520', N'ACTIVE', N'2026-04-30T19:32:00.520', N'123987456', N'A', N'2026-04-30T19:32:00.520', N'DL', N'Driver''s license number', N'2026-04-30T00:00:00', N'L');

-- dbo.Postal_locator
-- step: 2
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt], [cntry_cd], [cnty_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_3, N'2026-04-30T19:32:00.493', @superuser_id, N'Atlanta', N'840', N'13121', N'ACTIVE', N'2026-04-30T19:32:00.493', N'13', N'1313 Pine Way', N'30033');

-- dbo.Entity_locator_participation
-- step: 2
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Postal_locator_postal_locator_uid_3, N'H', N'PST', N'2026-04-30T19:32:00.600', @superuser_id, N'ACTIVE', N'2026-04-30T19:32:00.600', N'A', N'2026-04-30T19:32:00.600', N'H', 1, N'2026-04-30T00:00:00');

-- dbo.Tele_locator
-- step: 2
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_5, N'2026-04-30T19:32:00.493', @superuser_id, N'', N'201-555-1212', N'ACTIVE');

-- dbo.Entity_locator_participation
-- step: 2
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Tele_locator_tele_locator_uid_5, N'PH', N'TELE', N'2026-04-30T19:32:00.600', @superuser_id, N'ACTIVE', N'2026-04-30T19:32:00.600', N'A', N'2026-04-30T19:32:00.600', N'H', 1, N'2026-04-30T00:00:00');

-- dbo.Tele_locator
-- step: 2
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_6, N'2026-04-30T19:32:00.493', @superuser_id, N'taylor@example.com', N'ACTIVE');

-- dbo.Entity_locator_participation
-- step: 2
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Tele_locator_tele_locator_uid_6, N'NET', N'TELE', N'2026-04-30T19:32:00.600', @superuser_id, N'ACTIVE', N'2026-04-30T19:32:00.600', N'A', N'2026-04-30T19:32:00.600', N'H', 1, N'2026-04-30T00:00:00');

-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_5, N'CASE', N'EVN');

-- dbo.Public_health_case
-- step: 2
DECLARE @dbo_Public_health_case_local_id nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_5))) + N'GA01';
INSERT INTO [dbo].[Public_health_case] ([public_health_case_uid], [activity_from_time], [add_time], [add_user_id], [case_class_cd], [case_type_cd], [cd], [cd_desc_txt], [detection_method_cd], [disease_imported_cd], [effective_duration_amt], [effective_duration_unit_cd], [group_case_cnt], [investigation_status_cd], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [mmwr_week], [mmwr_year], [outbreak_ind], [outbreak_name], [outcome_cd], [prog_area_cd], [record_status_cd], [record_status_time], [rpt_form_cmplt_time], [rpt_source_cd], [status_cd], [transmission_mode_cd], [transmission_mode_desc_txt], [txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [hospitalized_ind_cd], [pregnant_ind_cd], [day_care_ind_cd], [food_handler_ind_cd], [imported_country_cd], [imported_state_cd], [imported_city_desc_txt], [imported_county_cd], [priority_cd], [contact_inv_txt], [contact_inv_status_cd], [referral_basis_cd], [curr_process_state_cd], [coinfection_id]) VALUES (@dbo_Act_act_uid_5, N'2026-04-24T00:00:00', N'2026-04-30T19:32:00.637', @superuser_id, N'', N'I', N'700', N'Syphilis, Unknown', N'', N'', N'', N'', 1, N'O', N'130001', N'2026-04-30T19:32:00.637', @superuser_id, @dbo_Public_health_case_local_id, N'17', N'2026', N'', N'', N'', N'STD', N'OPEN', N'2026-04-30T19:32:00.637', N'2026-04-30T00:00:00', N'', N'A', N'', N'', N'', 1300100015, N'T', 1, N'', N'Y', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'T1', N'SF', N'COIN1000XX01');

-- dbo.case_management
-- step: 2
DECLARE @dbo_case_management_case_management_uid bigint;
DECLARE @dbo_case_management_case_management_uid_output TABLE ([value] bigint);
INSERT INTO [dbo].[case_management] ([public_health_case_uid], [epi_link_id], [field_record_number], [init_foll_up], [surv_assigned_date]) OUTPUT INSERTED.[case_management_uid] INTO @dbo_case_management_case_management_uid_output ([value]) VALUES (@dbo_Act_act_uid_5, N'1310000026', N'1310000026', N'SF', N'2026-04-24T00:00:00');
SELECT TOP 1 @dbo_case_management_case_management_uid = [value] FROM @dbo_case_management_case_management_uid_output;

-- dbo.Act_id
-- step: 2
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid_5, 1, N'', N'A', N'2026-04-30T19:32:00.670', N'STATE');
-- step: 2
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid_5, 2, N'', N'A', N'2026-04-30T19:32:00.673', N'CITY');
-- step: 2
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid_5, 3, N'', N'A', N'2026-04-30T19:32:00.673', N'LEGACY');

-- dbo.message_log
-- step: 2
DECLARE @dbo_message_log_message_log_uid bigint;
DECLARE @dbo_message_log_message_log_uid_output TABLE ([value] bigint);
INSERT INTO [dbo].[message_log] ([message_txt], [condition_cd], [person_uid], [assigned_to_uid], [event_uid], [event_type_cd], [message_status_cd], [record_status_cd], [record_status_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[message_log_uid] INTO @dbo_message_log_message_log_uid_output ([value]) VALUES (N'New assignment', N'700', @dbo_Entity_entity_uid_4, 10003010, 10009300, N'Investigation', N'N', N'ACTIVE', N'2026-04-30T19:32:00.490', N'2026-04-30T19:32:00.490', @superuser_id, N'2026-04-30T19:32:00.490', @superuser_id);
SELECT TOP 1 @dbo_message_log_message_log_uid = [value] FROM @dbo_message_log_message_log_uid_output;

-- dbo.Participation
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Act_act_uid_5, N'SubjOfPHC', N'CASE', N'2026-04-30T19:32:00.520', @superuser_id, N'2026-04-30T19:32:00.520', @superuser_id, N'ACTIVE', N'2026-04-30T19:32:00.520', N'A', N'2026-04-30T19:32:00.520', N'PSN', N'Subject Of Public Health Case');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003010, @dbo_Act_act_uid_5, N'InitFupInvestgrOfPHC', N'CASE', N'2026-04-30T19:32:00.520', @superuser_id, N'2026-04-30T19:32:00.520', @superuser_id, N'ACTIVE', N'2026-04-30T19:32:00.520', N'A', N'2026-04-30T19:32:00.520', N'PSN');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003010, @dbo_Act_act_uid_5, N'InvestgrOfPHC', N'CASE', N'2026-04-30T19:32:00.523', @superuser_id, N'2026-04-30T19:32:00.523', @superuser_id, N'ACTIVE', N'2026-04-30T19:32:00.523', N'A', N'2026-04-30T19:32:00.523', N'PSN', N'PHC Investigator');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003019, @dbo_Act_act_uid_5, N'OrgAsReporterOfPHC', N'CASE', N'2026-04-30T19:32:00.523', @superuser_id, N'2026-04-30T19:32:00.523', @superuser_id, N'ACTIVE', N'2026-04-30T19:32:00.523', N'A', N'2026-04-30T19:32:00.523', N'ORG', N'Organization As Reporter Of PHC');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003010, @dbo_Act_act_uid_5, N'SurvInvestgrOfPHC', N'CASE', N'2026-04-30T19:32:00.523', @superuser_id, N'2026-04-30T19:32:00.523', @superuser_id, N'ACTIVE', N'2026-04-30T19:32:00.523', N'A', N'2026-04-30T19:32:00.523', N'PSN');

-- dbo.NBS_case_answer
-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'N', 10001013, 3, N'2026-04-30T19:32:00.637', @superuser_id, N'OPEN', N'2026-04-30T19:32:00.637', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_output;
-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_2 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_2_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_2_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'30', 10001252, 3, N'2026-04-30T19:32:00.637', @superuser_id, N'OPEN', N'2026-04-30T19:32:00.637', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_2 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_2_output;

-- dbo.NBS_act_entity
-- step: 2
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, @dbo_Entity_entity_uid_4, 1, N'2026-04-30T19:32:00.637', @superuser_id, N'OPEN', N'2026-04-30T19:32:00.637', N'SubjOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_output;
-- step: 2
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_2_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003010, 1, N'2026-04-30T19:32:00.637', @superuser_id, N'OPEN', N'2026-04-30T19:32:00.637', N'InitFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_2 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_2_output;
-- step: 2
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_3_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003010, 1, N'2026-04-30T19:32:00.637', @superuser_id, N'OPEN', N'2026-04-30T19:32:00.637', N'InvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_3 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_3_output;
-- step: 2
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_4 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_4_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_4_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003019, 1, N'2026-04-30T19:32:00.637', @superuser_id, N'OPEN', N'2026-04-30T19:32:00.637', N'OrgAsReporterOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_4 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_4_output;
-- step: 2
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_5 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_5_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_5_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003010, 1, N'2026-04-30T19:32:00.637', @superuser_id, N'OPEN', N'2026-04-30T19:32:00.637', N'SurvInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_5 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_5_output;

-- dbo.Act_relationship
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_reason_cd], [add_time], [from_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_5, @dbo_Act_act_uid, N'LabReport', N'SF', N'2026-04-30T19:32:00.697', N'2026-04-30T19:32:00.637', N'2026-04-30T19:32:00.697', @superuser_id, N'ACTIVE', N'2026-04-30T19:32:00.697', N'OBS', N'A', N'2026-04-30T19:32:00.697', N'CASE');

-- dbo.Person
-- step: 2
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T19:32:00.587', [record_status_time] = N'2026-04-30T19:32:00.587', [status_time] = N'2026-04-30T19:32:00.587', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 2
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:32:00.587', [record_status_time] = N'2026-04-30T19:32:00.587', [status_time] = N'2026-04-30T19:32:00.587' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 2
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:32:00.587', [record_status_time] = N'2026-04-30T19:32:00.587', [status_time] = N'2026-04-30T19:32:00.587' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 2
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:32:00.587', [record_status_time] = N'2026-04-30T19:32:00.587', [status_time] = N'2026-04-30T19:32:00.587' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;

-- dbo.Observation
-- step: 2
UPDATE [dbo].[Observation] SET [last_chg_time] = N'2026-04-30T19:32:00.707', [record_status_cd] = N'PROCESSED', [record_status_time] = N'2026-04-30T19:32:00.707', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid;

-- dbo.PublicHealthCaseFact
-- step: 2
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [organizationName], [PAR_type_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [prog_area_desc_txt], [LASTUPDATE]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'', N'I', N'Atlanta', N'Fulton County', N'840', N'13121', N'F', N'N', N'PST', N'2026-04-30T19:32:00.637', N'P', 1.0, N'O', N'Keable, Kristi', N'404-851-8000', N'130001', N'M', N'Married', N'2026-04-30T19:32:05.287', 17, 2026, N'Emory University Hospital', N'SubjOfPHC', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-04-30T19:32:00.637', N'700', N'Syphilis, Unknown', N'Syphilis, Unknown', N'STD', N'2026-04-30T19:32:00.493', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'2026-04-30T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-04-30T19:32:00.637', 10009283, @dbo_Person_local_id, N'2026-04-30T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Female', N'UNITED STATES', N'Female', N'Open', N'STD', N'2026-04-30T19:32:00.637');

-- dbo.SubjectRaceInfo
-- step: 2
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');

-- STEP 3: AddTreatmentSyphilis

-- dbo.Act
-- step: 3
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_6, N'TRMT', N'EVN');

-- dbo.Treatment
-- step: 3
DECLARE @dbo_Treatment_local_id nvarchar(40) = N'TRT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_6))) + N'GA01';
INSERT INTO [dbo].[Treatment] ([treatment_uid], [activity_from_time], [add_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [class_cd], [last_chg_time], [last_chg_user_id], [local_id], [prog_area_cd], [program_jurisdiction_oid], [record_status_cd], [record_status_time], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_6, N'2026-04-22T00:00:00', N'2026-04-30T19:35:52.997', @superuser_id, N'176', N'Benzathine penicillin G (Bicillin), 2.4 mu, IM, x 1 dose', N'2.16.840.1.114222.4.5.1', N'NEDSS Base System', N'TA', N'2026-04-30T19:35:53.003', @superuser_id, @dbo_Treatment_local_id, N'STD', 1, N'ACTIVE', N'2026-04-30T19:35:53.003', N'T', 1);

-- dbo.Treatment_administered
-- step: 3
INSERT INTO [dbo].[Treatment_administered] ([treatment_uid], [treatment_administered_seq], [cd], [dose_qty], [dose_qty_unit_cd], [effective_from_time], [interval_cd], [route_cd]) VALUES (@dbo_Act_act_uid_6, 1, N'176', N'2.4', N'mu', N'2026-04-22T00:00:00', N'Once', N'C0556983');

-- dbo.NBS_act_entity
-- step: 3
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_6 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_6_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_6_output ([value]) VALUES (@dbo_Act_act_uid_6, N'2026-04-30T19:35:52.997', @superuser_id, 10003004, 1, N'2026-04-30T19:35:53.003', @superuser_id, N'ACTIVE', N'2026-04-30T19:35:53.003', N'ProviderOfTrmt');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_6 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_6_output;
-- step: 3
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_7 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_7_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_7_output ([value]) VALUES (@dbo_Act_act_uid_6, N'2026-04-30T19:35:52.997', @superuser_id, @dbo_Entity_entity_uid, 1, N'2026-04-30T19:35:53.003', @superuser_id, N'ACTIVE', N'2026-04-30T19:35:53.003', N'SubjOfTrmt');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_7 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_7_output;
-- step: 3
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_8 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_8_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_8_output ([value]) VALUES (@dbo_Act_act_uid_6, N'2026-04-30T19:35:52.997', @superuser_id, 10003007, 1, N'2026-04-30T19:35:53.003', @superuser_id, N'ACTIVE', N'2026-04-30T19:35:53.003', N'ReporterOfTrmt');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_8 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_8_output;

-- dbo.Participation
-- step: 3
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_6, N'ProviderOfTrmt', N'TRMT', N'2026-04-30T19:35:53.003', @superuser_id, N'2026-04-30T19:35:53.003', @superuser_id, N'ACTIVE', N'2026-04-30T19:35:53.003', N'A', N'2026-04-30T19:35:53.003', N'PSN');
-- step: 3
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid, @dbo_Act_act_uid_6, N'SubjOfTrmt', N'TRMT', N'2026-04-30T19:35:53.003', @superuser_id, N'2026-04-30T19:35:53.003', @superuser_id, N'ACTIVE', N'2026-04-30T19:35:53.003', N'A', N'2026-04-30T19:35:53.003', N'PSN', N'Treatment Subject');
-- step: 3
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003007, @dbo_Act_act_uid_6, N'ReporterOfTrmt', N'TRMT', N'2026-04-30T19:35:53.003', @superuser_id, N'2026-04-30T19:35:53.003', @superuser_id, N'ACTIVE', N'2026-04-30T19:35:53.003', N'A', N'2026-04-30T19:35:53.003', N'ORG');

-- dbo.Act_relationship
-- step: 3
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_5, @dbo_Act_act_uid_6, N'TreatmentToPHC', N'2026-04-30T19:35:53.043', N'2026-04-30T19:35:53.043', @superuser_id, N'ACTIVE', N'2026-04-30T19:35:53.043', N'TRMT', N'A', N'2026-04-30T19:35:53.043', N'CASE');

-- STEP 4: InvestigateSyphilisInitialFollowup

-- dbo.Participation
-- step: 4
UPDATE [dbo].[Participation] SET [from_time] = N'2026-04-17T00:00:00', [to_time] = N'2026-04-30T19:39:22.757' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';
-- step: 4
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003022, @dbo_Act_act_uid_5, N'PerAsReporterOfPHC', N'CASE', N'2026-04-30T19:32:00.637', @superuser_id, N'2026-04-30T19:39:22.653', @superuser_id, N'ACTIVE', N'2026-04-30T19:39:22.653', N'A', N'2026-04-30T19:39:22.653', N'PSN', N'PHC Reporter');

-- dbo.NBS_case_answer
-- step: 4
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_3_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'04/20/2026', 10001192, 3, N'2026-04-30T19:39:22.743', @superuser_id, N'OPEN', N'2026-04-30T19:39:22.743', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_3 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_3_output;
-- step: 4
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T19:39:22.743', [record_status_time] = N'2026-04-30T19:39:22.743' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid;
-- step: 4
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_4 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_4_output TABLE ([value] bigint);
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
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_9 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_9_output TABLE ([value] bigint);
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

-- STEP 5: InvestigateSyphilisAssignFieldFollowup

-- dbo.message_log
-- step: 5
DECLARE @dbo_message_log_message_log_uid_2 bigint;
DECLARE @dbo_message_log_message_log_uid_2_output TABLE ([value] bigint);
INSERT INTO [dbo].[message_log] ([message_txt], [condition_cd], [person_uid], [assigned_to_uid], [event_uid], [event_type_cd], [message_status_cd], [record_status_cd], [record_status_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[message_log_uid] INTO @dbo_message_log_message_log_uid_2_output ([value]) VALUES (N'New assignment', N'10312', @dbo_Entity_entity_uid_4, 10003004, 10009300, N'Investigation', N'N', N'ACTIVE', N'2026-04-30T19:44:42.790', N'2026-04-30T19:44:42.790', @superuser_id, N'2026-04-30T19:44:42.790', @superuser_id);
SELECT TOP 1 @dbo_message_log_message_log_uid_2 = [value] FROM @dbo_message_log_message_log_uid_2_output;

-- dbo.Participation
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_5, N'DispoFldFupInvestgrOfPHC', N'CASE', N'2026-04-30T19:32:00.637', @superuser_id, N'2026-04-30T19:44:42.850', @superuser_id, N'ACTIVE', N'2026-04-30T19:44:42.850', N'A', N'2026-04-30T19:44:42.850', N'PSN');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003013, @dbo_Act_act_uid_5, N'FldFupInvestgrOfPHC', N'CASE', N'2026-04-30T19:32:00.637', @superuser_id, N'2026-04-30T19:44:42.850', @superuser_id, N'ACTIVE', N'2026-04-30T19:44:42.850', N'A', N'2026-04-30T19:44:42.850', N'PSN');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_5, N'FldFupSupervisorOfPHC', N'CASE', N'2026-04-30T19:32:00.637', @superuser_id, N'2026-04-30T19:44:42.850', @superuser_id, N'ACTIVE', N'2026-04-30T19:44:42.850', N'A', N'2026-04-30T19:44:42.850', N'PSN');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003013, @dbo_Act_act_uid_5, N'InitFldFupInvestgrOfPHC', N'CASE', N'2026-04-30T19:32:00.637', @superuser_id, N'2026-04-30T19:44:42.850', @superuser_id, N'ACTIVE', N'2026-04-30T19:44:42.850', N'A', N'2026-04-30T19:44:42.850', N'PSN');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_5, N'InitInterviewerOfPHC', N'CASE', N'2026-04-30T19:32:00.637', @superuser_id, N'2026-04-30T19:44:42.850', @superuser_id, N'ACTIVE', N'2026-04-30T19:44:42.850', N'A', N'2026-04-30T19:44:42.850', N'PSN');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_5, N'InterviewerOfPHC', N'CASE', N'2026-04-30T19:32:00.637', @superuser_id, N'2026-04-30T19:44:42.850', @superuser_id, N'ACTIVE', N'2026-04-30T19:44:42.850', N'A', N'2026-04-30T19:44:42.850', N'PSN');
-- step: 5
DELETE FROM [dbo].[Participation] WHERE [subject_entity_uid] = 10003010 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'InvestgrOfPHC';
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003004, @dbo_Act_act_uid_5, N'InvestgrOfPHC', N'CASE', N'2026-04-30T19:32:00.637', @superuser_id, N'2026-04-30T19:44:42.850', @superuser_id, N'ACTIVE', N'2026-04-30T19:44:42.850', N'A', N'2026-04-30T19:44:42.850', N'PSN', N'PHC Investigator');

-- dbo.NBS_case_answer
-- step: 5
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T19:44:42.917', [record_status_time] = N'2026-04-30T19:44:42.917' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_3;
-- step: 5
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T19:44:42.917', [record_status_time] = N'2026-04-30T19:44:42.917' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid;
-- step: 5
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T19:44:42.917', [record_status_time] = N'2026-04-30T19:44:42.917' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_4;
-- step: 5
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T19:44:42.917', [record_status_time] = N'2026-04-30T19:44:42.917' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_2;

-- dbo.NBS_act_entity
-- step: 5
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_10 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_10_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_10_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003004, 1, N'2026-04-30T19:44:42.917', @superuser_id, N'OPEN', N'2026-04-30T19:44:42.917', N'DispoFldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_10 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_10_output;
-- step: 5
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_11 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_11_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_11_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003013, 1, N'2026-04-30T19:44:42.917', @superuser_id, N'OPEN', N'2026-04-30T19:44:42.917', N'FldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_11 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_11_output;
-- step: 5
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_12 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_12_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_12_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003004, 1, N'2026-04-30T19:44:42.917', @superuser_id, N'OPEN', N'2026-04-30T19:44:42.917', N'FldFupSupervisorOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_12 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_12_output;
-- step: 5
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_13 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_13_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_13_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003013, 1, N'2026-04-30T19:44:42.917', @superuser_id, N'OPEN', N'2026-04-30T19:44:42.917', N'InitFldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_13 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_13_output;
-- step: 5
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:44:42.917', [record_status_time] = N'2026-04-30T19:44:42.917' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_2;
-- step: 5
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_14 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_14_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_14_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003004, 1, N'2026-04-30T19:44:42.917', @superuser_id, N'OPEN', N'2026-04-30T19:44:42.917', N'InitInterviewerOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_14 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_14_output;
-- step: 5
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_15 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_15_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_15_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003004, 1, N'2026-04-30T19:44:42.917', @superuser_id, N'OPEN', N'2026-04-30T19:44:42.917', N'InterviewerOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_15 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_15_output;
-- step: 5
DELETE FROM [dbo].[NBS_act_entity] WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_3;
-- step: 5
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_16 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_16_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_16_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003004, 1, N'2026-04-30T19:44:42.917', @superuser_id, N'OPEN', N'2026-04-30T19:44:42.917', N'InvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_16 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_16_output;
-- step: 5
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:44:42.917', [record_status_time] = N'2026-04-30T19:44:42.917' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_4;
-- step: 5
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:44:42.917', [record_status_time] = N'2026-04-30T19:44:42.917' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_9;
-- step: 5
UPDATE [dbo].[NBS_act_entity] SET [entity_version_ctrl_nbr] = 2, [last_chg_time] = N'2026-04-30T19:44:42.917', [record_status_time] = N'2026-04-30T19:44:42.917' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid;
-- step: 5
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:44:42.917', [record_status_time] = N'2026-04-30T19:44:42.917' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_5;

-- dbo.Person
-- step: 5
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T19:44:42.890', [record_status_time] = N'2026-04-30T19:44:42.890', [status_time] = N'2026-04-30T19:44:42.890', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:44:42.890', [record_status_time] = N'2026-04-30T19:44:42.890', [status_time] = N'2026-04-30T19:44:42.890' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:44:42.890', [record_status_time] = N'2026-04-30T19:44:42.890', [status_time] = N'2026-04-30T19:44:42.890' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:44:42.890', [record_status_time] = N'2026-04-30T19:44:42.890', [status_time] = N'2026-04-30T19:44:42.890' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;

-- dbo.Person
-- step: 5
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T19:44:42.900', [record_status_time] = N'2026-04-30T19:44:42.900', [status_time] = N'2026-04-30T19:44:42.900', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_4;

-- dbo.Person_name
-- step: 5
UPDATE [dbo].[Person_name] SET [last_chg_time] = N'2026-04-30T19:44:42.790' WHERE [person_uid] = @dbo_Entity_entity_uid_4 AND [person_name_seq] = 1;

-- dbo.Entity_id
-- step: 5
UPDATE [dbo].[Entity_id] SET [last_chg_time] = N'2026-04-30T19:44:42.850' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_id_seq] = 1;

-- dbo.Postal_locator
-- step: 5
UPDATE [dbo].[Postal_locator] SET [last_chg_time] = N'2026-04-30T19:44:42.790' WHERE [postal_locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;

-- dbo.Entity_locator_participation
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:44:42.900', [record_status_time] = N'2026-04-30T19:44:42.900', [status_time] = N'2026-04-30T19:44:42.900' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;

-- dbo.Tele_locator
-- step: 5
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-04-30T19:44:42.790' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;

-- dbo.Entity_locator_participation
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:44:42.900', [record_status_time] = N'2026-04-30T19:44:42.900', [status_time] = N'2026-04-30T19:44:42.900' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;

-- dbo.Tele_locator
-- step: 5
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-04-30T19:44:42.790' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;

-- dbo.Entity_locator_participation
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:44:42.900', [record_status_time] = N'2026-04-30T19:44:42.900', [status_time] = N'2026-04-30T19:44:42.900' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;

-- dbo.Public_health_case
-- step: 5
UPDATE [dbo].[Public_health_case] SET [last_chg_time] = N'2026-04-30T19:44:42.917', [record_status_time] = N'2026-04-30T19:44:42.917', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [curr_process_state_cd] = N'AI' WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;

-- dbo.Confirmation_method
-- step: 5
DELETE FROM [dbo].[Confirmation_method] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5 AND [confirmation_method_cd] = N'LD';
-- step: 5
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_5, N'LD', N'2026-04-24T00:00:00');

-- dbo.case_management
-- step: 5
UPDATE [dbo].[case_management] SET [fld_foll_up_dispo] = N'C', [fld_foll_up_dispo_date] = N'2026-04-25T00:00:00', [fld_foll_up_notification_plan] = N'3', [init_foll_up_notifiable] = N'06', [pat_intv_status_cd] = N'A', [surv_patient_foll_up] = N'FF', [foll_up_assigned_date] = N'2026-04-25T00:00:00', [init_foll_up_assigned_date] = N'2026-04-25T00:00:00', [interview_assigned_date] = N'2026-04-25T00:00:00', [init_interview_assigned_date] = N'2026-04-25T00:00:00' WHERE [case_management_uid] = @dbo_case_management_case_management_uid;

-- dbo.Participation
-- step: 5
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T19:44:43.100', [last_chg_time] = N'2026-04-30T19:44:42.917', [record_status_time] = N'2026-04-30T19:44:42.917', [status_time] = N'2026-04-30T19:44:42.917' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';

-- dbo.SubjectRaceInfo
-- step: 5
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_5 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';

-- dbo.PublicHealthCaseFact
-- step: 5
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- step: 5
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [onSetDate], [organizationName], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-24T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'21', N'Self Referral', N'2026-04-21T00:00:00', N'PST', N'2026-04-17T00:00:00', N'O', 1.0, N'O', N'Xerogeanes, John', N'404-778-3350', N'130001', N'M', N'Married', N'2026-04-30T19:44:47.013', 17, 2026, N'2026-04-17T00:00:00', N'Emory University Hospital', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-04-30T19:32:00.637', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2026-04-30T19:32:00.493', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Nightingale, Florence', N'404-785-6000', N'2026-04-30T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-04-30T19:32:00.637', 10009283, @dbo_Person_local_id, N'2026-04-30T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Open', N'Years', N'STD', N' Laboratory confirmed', N'2026-04-30T19:44:42.917', N'N');

-- dbo.SubjectRaceInfo
-- step: 5
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');

-- STEP 6: AddInterviewSyphilis

-- dbo.NBS_case_answer
-- step: 6
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_5 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_5_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_5_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'04/24/2026', 10001326, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_5 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_5_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_6 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_6_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_6_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'N', 10001327, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_6 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_6_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_7 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_7_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_7_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'Y', 10001325, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_7 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_7_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_8 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_8_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_8_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'R', 10001285, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_8 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_8_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_9 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_9_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_9_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'N', 10001331, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_9 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_9_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_10 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_10_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_10_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'N', 10001283, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_10 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_10_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_11 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_11_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_11_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'Y', 10001289, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_11 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_11_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_12 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_12_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_12_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'5', 10001290, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_12 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_12_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_13 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_13_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_13_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'2', 10003231, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_13 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_13_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_14 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_14_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_14_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'N', 10001316, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_14 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_14_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_15 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_15_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_15_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'Y', 10001287, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_15 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_15_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_16 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_16_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_16_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'N', 10003230, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_16 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_16_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_17 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_17_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_17_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'2', 10001288, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_17 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_17_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_18 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_18_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_18_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'Y', 10001302, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_18 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_18_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_19 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_19_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_19_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'N', 10001295, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_19 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_19_output;
-- step: 6
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_2;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_20 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_20_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_20_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'N', 10001291, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_20 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_20_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_21 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_21_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_21_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'Y', 10001296, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_21 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_21_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_22 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_22_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_22_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'1', 10001297, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_22 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_22_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_23 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_23_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_23_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'7', 10001293, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_23 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_23_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_24 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_24_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_24_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'N', 10001300, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_24 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_24_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_25 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_25_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_25_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'N', 10001322, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_25 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_25_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_26 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_26_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_26_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'Y', 10001298, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_26 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_26_output;
-- step: 6
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_3;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_27 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_27_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_27_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'2', 10001299, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_27 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_27_output;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_28 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_28_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_28_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'N', 10001294, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_28 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_28_output;
-- step: 6
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_4;
-- step: 6
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_29 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_29_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_29_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'1', 10001321, 3, N'2026-04-30T19:50:49.327', @superuser_id, N'OPEN', N'2026-04-30T19:50:49.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_29 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_29_output;

-- dbo.NBS_act_entity
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_10;
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_11;
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_12;
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_13;
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_2;
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_14;
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_15;
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_16;
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_4;
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_9;
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [entity_version_ctrl_nbr] = 3, [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid;
-- step: 6
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_5;

-- dbo.Person
-- step: 6
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T19:50:49.297', [record_status_time] = N'2026-04-30T19:50:49.297', [status_time] = N'2026-04-30T19:50:49.297', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 6
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:50:49.297', [record_status_time] = N'2026-04-30T19:50:49.297', [status_time] = N'2026-04-30T19:50:49.297' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 6
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:50:49.297', [record_status_time] = N'2026-04-30T19:50:49.297', [status_time] = N'2026-04-30T19:50:49.297' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 6
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:50:49.297', [record_status_time] = N'2026-04-30T19:50:49.297', [status_time] = N'2026-04-30T19:50:49.297' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;

-- dbo.Person
-- step: 6
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T19:50:49.307', [record_status_time] = N'2026-04-30T19:50:49.307', [status_time] = N'2026-04-30T19:50:49.307', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_4;

-- dbo.Person_name
-- step: 6
UPDATE [dbo].[Person_name] SET [last_chg_time] = N'2026-04-30T19:50:49.233' WHERE [person_uid] = @dbo_Entity_entity_uid_4 AND [person_name_seq] = 1;

-- dbo.Entity_id
-- step: 6
UPDATE [dbo].[Entity_id] SET [last_chg_time] = N'2026-04-30T19:50:49.253' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_id_seq] = 1;

-- dbo.Postal_locator
-- step: 6
UPDATE [dbo].[Postal_locator] SET [last_chg_time] = N'2026-04-30T19:50:49.233' WHERE [postal_locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;

-- dbo.Entity_locator_participation
-- step: 6
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:50:49.307', [record_status_time] = N'2026-04-30T19:50:49.307', [status_time] = N'2026-04-30T19:50:49.307' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;

-- dbo.Tele_locator
-- step: 6
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-04-30T19:50:49.233' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;

-- dbo.Entity_locator_participation
-- step: 6
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:50:49.307', [record_status_time] = N'2026-04-30T19:50:49.307', [status_time] = N'2026-04-30T19:50:49.307' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;

-- dbo.Tele_locator
-- step: 6
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-04-30T19:50:49.233' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;

-- dbo.Entity_locator_participation
-- step: 6
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T19:50:49.307', [record_status_time] = N'2026-04-30T19:50:49.307', [status_time] = N'2026-04-30T19:50:49.307' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;

-- dbo.Public_health_case
-- step: 6
UPDATE [dbo].[Public_health_case] SET [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [curr_process_state_cd] = N'OC' WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;

-- dbo.Confirmation_method
-- step: 6
DELETE FROM [dbo].[Confirmation_method] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5 AND [confirmation_method_cd] = N'LD';
-- step: 6
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_5, N'LD', N'2026-04-24T00:00:00');

-- dbo.case_management
-- step: 6
UPDATE [dbo].[case_management] SET [pat_intv_status_cd] = N'I' WHERE [case_management_uid] = @dbo_case_management_case_management_uid;

-- dbo.Participation
-- step: 6
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T19:50:49.493', [last_chg_time] = N'2026-04-30T19:50:49.327', [record_status_time] = N'2026-04-30T19:50:49.327', [status_time] = N'2026-04-30T19:50:49.327' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';

-- dbo.Act
-- step: 6
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_7, N'IXS', N'EVN');

-- dbo.Interview
-- step: 6
DECLARE @dbo_Interview_local_id nvarchar(40) = N'INT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_7))) + N'GA01';
INSERT INTO [dbo].[Interview] ([interview_uid], [interview_status_cd], [interview_date], [interviewee_role_cd], [interview_type_cd], [interview_loc_cd], [local_id], [record_status_cd], [record_status_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_7, N'COMPLETE', N'2026-04-24T00:00:00', N'SUBJECT', N'INITIAL', N'T', @dbo_Interview_local_id, N'ACTIVE', N'2026-04-30T19:50:52.317', N'2026-04-30T19:50:52.317', @superuser_id, N'2026-04-30T19:50:52.317', @superuser_id, 1);

-- dbo.nbs_answer
-- step: 6
DECLARE @dbo_nbs_answer_nbs_answer_uid bigint;
DECLARE @dbo_nbs_answer_nbs_answer_uid_output TABLE ([value] bigint);
INSERT INTO [dbo].[nbs_answer] ([act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [seq_nbr], [record_status_cd], [record_status_time], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[nbs_answer_uid] INTO @dbo_nbs_answer_nbs_answer_uid_output ([value]) VALUES (@dbo_Act_act_uid_7, N'Y', 10001355, 3, 0, N'ACTIVE', N'2026-04-30T19:50:52.317', N'2026-04-30T19:50:52.317', @superuser_id);
SELECT TOP 1 @dbo_nbs_answer_nbs_answer_uid = [value] FROM @dbo_nbs_answer_nbs_answer_uid_output;
-- step: 6
DECLARE @dbo_nbs_answer_nbs_answer_uid_2 bigint;
DECLARE @dbo_nbs_answer_nbs_answer_uid_2_output TABLE ([value] bigint);
INSERT INTO [dbo].[nbs_answer] ([act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [seq_nbr], [answer_group_seq_nbr], [record_status_cd], [record_status_time], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[nbs_answer_uid] INTO @dbo_nbs_answer_nbs_answer_uid_2_output ([value]) VALUES (@dbo_Act_act_uid_7, N'Ariella Kent~04/30/2026 15:50~~asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say.', 10001024, 3, 0, 1, N'ACTIVE', N'2026-04-30T19:50:52.317', N'2026-04-30T19:50:52.317', @superuser_id);
SELECT TOP 1 @dbo_nbs_answer_nbs_answer_uid_2 = [value] FROM @dbo_nbs_answer_nbs_answer_uid_2_output;

-- dbo.NBS_act_entity
-- step: 6
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_17 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_17_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_17_output ([value]) VALUES (@dbo_Act_act_uid_7, N'2026-04-30T19:50:52.317', @superuser_id, 10003004, 4, N'2026-04-30T19:50:52.317', @superuser_id, N'ACTIVE', N'2026-04-30T19:50:52.317', N'IntrvwerOfInterview');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_17 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_17_output;
-- step: 6
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_18 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_18_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_18_output ([value]) VALUES (@dbo_Act_act_uid_7, N'2026-04-30T19:50:52.317', @superuser_id, @dbo_Entity_entity_uid_4, 4, N'2026-04-30T19:50:52.317', @superuser_id, N'ACTIVE', N'2026-04-30T19:50:52.317', N'IntrvweeOfInterview');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_18 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_18_output;

-- dbo.Participation
-- step: 6
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_7, N'IntrvwerOfInterview', N'IXS', N'2026-04-30T19:50:52.320', @superuser_id, N'2026-04-30T19:50:52.320', @superuser_id, N'ACTIVE', N'2026-04-30T19:50:52.320', N'A', N'2026-04-30T19:50:52.320', N'PSN');
-- step: 6
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Act_act_uid_7, N'IntrvweeOfInterview', N'IXS', N'2026-04-30T19:50:52.320', @superuser_id, N'2026-04-30T19:50:52.320', @superuser_id, N'ACTIVE', N'2026-04-30T19:50:52.320', N'A', N'2026-04-30T19:50:52.320', N'PSN');

-- dbo.Act_relationship
-- step: 6
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_reason_cd], [add_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_5, @dbo_Act_act_uid_7, N'IXS', N'because', N'2026-04-30T19:50:52.357', N'2026-04-30T19:50:52.357', @superuser_id, N'ACTIVE', N'2026-04-30T19:50:52.357', N'OBS', N'A', N'2026-04-30T19:50:52.357', N'CASE');

-- dbo.SubjectRaceInfo
-- step: 6
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_5 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';

-- dbo.PublicHealthCaseFact
-- step: 6
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- step: 6
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [onSetDate], [organizationName], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-24T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'21', N'Self Referral', N'2026-04-21T00:00:00', N'PST', N'2026-04-17T00:00:00', N'O', 1.0, N'O', N'Xerogeanes, John', N'404-778-3350', N'130001', N'M', N'Married', N'2026-04-30T19:50:56.103', 17, 2026, N'2026-04-17T00:00:00', N'Emory University Hospital', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-04-30T19:32:00.637', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2026-04-30T19:32:00.493', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Nightingale, Florence', N'404-785-6000', N'2026-04-30T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-04-30T19:32:00.637', 10009283, @dbo_Person_local_id, N'2026-04-30T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Open', N'Years', N'STD', N' Laboratory confirmed', N'2026-04-30T19:50:49.327', N'N');

-- dbo.SubjectRaceInfo
-- step: 6
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');

-- STEP 7: AddContactSyphilis

-- dbo.Entity
-- step: 7
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_5, N'PSN');

-- dbo.Person
-- step: 7
DECLARE @dbo_Person_local_id_2 nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_5))) + N'GA01';
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
DECLARE @dbo_Public_health_case_local_id_2 nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_8))) + N'GA01';
INSERT INTO [dbo].[Public_health_case] ([public_health_case_uid], [activity_from_time], [add_time], [add_user_id], [case_class_cd], [case_type_cd], [cd], [cd_desc_txt], [detection_method_cd], [disease_imported_cd], [effective_duration_amt], [effective_duration_unit_cd], [group_case_cnt], [investigation_status_cd], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [mmwr_week], [mmwr_year], [prog_area_cd], [record_status_cd], [record_status_time], [status_cd], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [investigator_assigned_time], [hospitalized_ind_cd], [day_care_ind_cd], [food_handler_ind_cd], [imported_country_cd], [imported_state_cd], [imported_city_desc_txt], [imported_county_cd], [contact_inv_txt], [contact_inv_status_cd], [referral_basis_cd], [curr_process_state_cd], [coinfection_id]) VALUES (@dbo_Act_act_uid_8, N'2026-04-25T00:00:00', N'2026-04-30T19:57:57.590', @superuser_id, N'', N'I', N'10312', N'Syphilis, secondary', N'', N'', N'', N'', 1, N'O', N'130001', N'2026-04-30T19:57:57.590', @superuser_id, @dbo_Public_health_case_local_id_2, N'16', N'2026', N'STD', N'OPEN', N'2026-04-30T19:57:57.590', N'A', 1300100015, N'T', 1, N'2026-04-25T00:00:00', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'P1', N'FF', N'COIN1001XX01');

-- dbo.case_management
-- step: 7
DECLARE @dbo_case_management_case_management_uid_2 bigint;
DECLARE @dbo_case_management_case_management_uid_2_output TABLE ([value] bigint);
INSERT INTO [dbo].[case_management] ([public_health_case_uid], [epi_link_id], [field_record_number], [init_foll_up], [init_foll_up_notifiable], [internet_foll_up], [subj_complexion], [subj_hair], [subj_height], [subj_oth_idntfyng_info], [subj_size_build], [foll_up_assigned_date], [init_foll_up_assigned_date]) OUTPUT INSERTED.[case_management_uid] INTO @dbo_case_management_case_management_uid_2_output ([value]) VALUES (@dbo_Act_act_uid_8, N'1310000026', N'1310000126', N'FF', N'06', N'', N'', N'', N'', N'', N'', N'2026-04-25T00:00:00', N'2026-04-25T00:00:00');
SELECT TOP 1 @dbo_case_management_case_management_uid_2 = [value] FROM @dbo_case_management_case_management_uid_2_output;

-- dbo.message_log
-- step: 7
DECLARE @dbo_message_log_message_log_uid_3 bigint;
DECLARE @dbo_message_log_message_log_uid_3_output TABLE ([value] bigint);
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
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_19 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_19_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_19_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, @dbo_Entity_entity_uid_6, 1, N'2026-04-30T19:57:57.590', @superuser_id, N'OPEN', N'2026-04-30T19:57:57.590', N'SubjOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_19 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_19_output;
-- step: 7
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_20 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_20_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_20_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, 10003004, 1, N'2026-04-30T19:57:57.590', @superuser_id, N'OPEN', N'2026-04-30T19:57:57.590', N'InvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_20 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_20_output;
-- step: 7
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_21 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_21_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_21_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, 10003004, 1, N'2026-04-30T19:57:57.590', @superuser_id, N'OPEN', N'2026-04-30T19:57:57.590', N'InitFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_21 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_21_output;
-- step: 7
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_22 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_22_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_22_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, 10003004, 1, N'2026-04-30T19:57:57.590', @superuser_id, N'OPEN', N'2026-04-30T19:57:57.590', N'InitFldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_22 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_22_output;
-- step: 7
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_23 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_23_output TABLE ([value] bigint);
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
DECLARE @dbo_CT_contact_local_id nvarchar(40) = N'CON' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_9))) + N'GA01';
INSERT INTO [dbo].[CT_contact] ([ct_contact_uid], [local_id], [subject_entity_uid], [contact_entity_uid], [subject_entity_phc_uid], [contact_entity_phc_uid], [record_status_cd], [record_status_time], [add_user_id], [add_time], [last_chg_time], [last_chg_user_id], [prog_area_cd], [jurisdiction_cd], [program_jurisdiction_oid], [shared_ind_cd], [contact_status], [priority_cd], [group_name_cd], [disposition_cd], [relationship_cd], [health_status_cd], [txt], [symptom_cd], [symptom_txt], [risk_factor_cd], [risk_factor_txt], [evaluation_completed_cd], [evaluation_txt], [treatment_initiated_cd], [treatment_not_start_rsn_cd], [treatment_end_cd], [treatment_not_end_rsn_cd], [treatment_txt], [version_ctrl_nbr], [processing_decision_cd], [subject_entity_epi_link_id], [contact_entity_epi_link_id], [named_during_interview_uid], [contact_referral_basis_cd]) VALUES (@dbo_Act_act_uid_9, @dbo_CT_contact_local_id, @dbo_Entity_entity_uid_4, @dbo_Entity_entity_uid_7, @dbo_Act_act_uid_5, @dbo_Act_act_uid_8, N'ACTIVE', N'2026-04-30T19:57:57.627', @superuser_id, N'2026-04-30T19:57:57.627', N'2026-04-30T19:57:57.627', @superuser_id, N'STD', N'130001', 1300100015, N'T', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', 1, N'FF', N'1310000026', N'1310000026', @dbo_Act_act_uid_7, N'P1');

-- dbo.CT_contact_answer
-- step: 7
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid bigint;
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_output TABLE ([value] bigint);
INSERT INTO [dbo].[CT_contact_answer] ([ct_contact_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[ct_contact_answer_uid] INTO @dbo_CT_contact_answer_ct_contact_answer_uid_output ([value]) VALUES (@dbo_Act_act_uid_9, N'04/01/2026', 10001184, 3, N'2026-04-30T19:57:57.627', @superuser_id, N'ACTIVE', N'2026-04-30T19:57:57.627', 0);
SELECT TOP 1 @dbo_CT_contact_answer_ct_contact_answer_uid = [value] FROM @dbo_CT_contact_answer_ct_contact_answer_uid_output;
-- step: 7
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_2 bigint;
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_2_output TABLE ([value] bigint);
INSERT INTO [dbo].[CT_contact_answer] ([ct_contact_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[ct_contact_answer_uid] INTO @dbo_CT_contact_answer_ct_contact_answer_uid_2_output ([value]) VALUES (@dbo_Act_act_uid_9, N'03/15/2026', 10001182, 3, N'2026-04-30T19:57:57.627', @superuser_id, N'ACTIVE', N'2026-04-30T19:57:57.627', 0);
SELECT TOP 1 @dbo_CT_contact_answer_ct_contact_answer_uid_2 = [value] FROM @dbo_CT_contact_answer_ct_contact_answer_uid_2_output;
-- step: 7
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_3 bigint;
DECLARE @dbo_CT_contact_answer_ct_contact_answer_uid_3_output TABLE ([value] bigint);
INSERT INTO [dbo].[CT_contact_answer] ([ct_contact_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[ct_contact_answer_uid] INTO @dbo_CT_contact_answer_ct_contact_answer_uid_3_output ([value]) VALUES (@dbo_Act_act_uid_9, N'THSPAT', 10001348, 3, N'2026-04-30T19:57:57.627', @superuser_id, N'ACTIVE', N'2026-04-30T19:57:57.627', 0);
SELECT TOP 1 @dbo_CT_contact_answer_ct_contact_answer_uid_3 = [value] FROM @dbo_CT_contact_answer_ct_contact_answer_uid_3_output;

-- dbo.NBS_act_entity
-- step: 7
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_24 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_24_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_24_output ([value]) VALUES (@dbo_Act_act_uid_9, N'2026-04-30T19:57:57.627', @superuser_id, @dbo_Entity_entity_uid_4, 1, N'2026-04-30T19:57:57.627', @superuser_id, N'ACTIVE', N'2026-04-30T19:57:57.627', N'SubjOfContact');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_24 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_24_output;
-- step: 7
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_25 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_25_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_25_output ([value]) VALUES (@dbo_Act_act_uid_9, N'2026-04-30T19:57:57.653', @superuser_id, 10003004, 1, N'2026-04-30T19:57:57.627', @superuser_id, N'ACTIVE', N'2026-04-30T19:57:57.627', N'InvestgrOfContact');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_25 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_25_output;

-- dbo.PublicHealthCaseFact
-- step: 7
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [case_class_cd], [case_type_cd], [curr_sex_cd], [deceased_ind_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorAssigneddate], [investigatorName], [investigatorPhone], [jurisdiction_cd], [mart_record_creation_time], [mmwr_week], [mmwr_year], [PAR_type_cd], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [shared_ind], [status_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [LOCAL_ID], [curr_sex_desc_txt], [investigation_status_desc_txt], [prog_area_desc_txt], [LASTUPDATE]) VALUES (@dbo_Act_act_uid_8, N'', N'I', N'M', N'N', N'2026-04-30T19:57:57.590', N'P', 1.0, N'O', N'2026-04-25T00:00:00', N'Xerogeanes, John', N'404-778-3350', N'130001', N'2026-04-30T19:58:04.653', 16, 2026, N'SubjOfPHC', N'PAT', @dbo_Entity_entity_uid_6, N'2026-04-30T19:57:57.590', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2106-3', N'White', N'OPEN', N'T', N'A', N', FredContact', N'Fulton County', N'2026-04-25T00:00:00', 1300100015, N'2026-04-30T19:57:57.590', 10009303, @dbo_Person_local_id_2, @dbo_Public_health_case_local_id_2, N'Male', N'Open', N'STD', N'2026-04-30T19:57:57.590');

-- dbo.SubjectRaceInfo
-- step: 7
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_8, N'2106-3', N'2106-3');

-- STEP 8: ChangeContactInvestigationDisposition

-- dbo.message_log
-- step: 8
DECLARE @dbo_message_log_message_log_uid_4 bigint;
DECLARE @dbo_message_log_message_log_uid_4_output TABLE ([value] bigint);
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
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_30 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_30_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_30_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, N'Ariella Kent~04/30/2026 16:02~~he wasn''t in the park anymore. we don''t know where he is.', 10001240, 3, N'2026-04-30T20:02:59.263', @superuser_id, N'OPEN', N'2026-04-30T20:02:59.263', 0, 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_30 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_30_output;

-- dbo.NBS_act_entity
-- step: 8
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_26 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_26_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_26_output ([value]) VALUES (@dbo_Act_act_uid_8, N'2026-04-30T19:57:57.590', @superuser_id, 10003004, 1, N'2026-04-30T20:02:59.263', @superuser_id, N'OPEN', N'2026-04-30T20:02:59.263', N'DispoFldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_26 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_26_output;
-- step: 8
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:02:59.263', [record_status_time] = N'2026-04-30T20:02:59.263' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_23;
-- step: 8
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_27 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_27_output TABLE ([value] bigint);
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
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_31 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_31_output TABLE ([value] bigint);
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
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_32 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_32_output TABLE ([value] bigint);
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

-- STEP 9: CloseInvestigationSyphilis

-- dbo.Participation
-- step: 9
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_5, N'ClosureInvestgrOfPHC', N'CASE', N'2026-04-30T19:32:00.637', @superuser_id, N'2026-04-30T20:09:14.247', @superuser_id, N'ACTIVE', N'2026-04-30T20:09:14.247', N'A', N'2026-04-30T20:09:14.247', N'PSN');

-- dbo.NBS_case_answer
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_5;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_6;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_7;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_8;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_9;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_10;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_11;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_12;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_13;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_14;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_15;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_16;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_17;
-- step: 9
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_33 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_33_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_33_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'1', 10003228, 3, N'2026-04-30T20:09:14.380', @superuser_id, N'OPEN', N'2026-04-30T20:09:14.380', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_33 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_33_output;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_18;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_19;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_2;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_20;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_21;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_22;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_23;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_24;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_25;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_26;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_3;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_27;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_28;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_4;
-- step: 9
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_29;
-- step: 9
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_34 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_34_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_34_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'Ariella Kent~04/30/2026 16:09~~finished gathering information about this case', 10001240, 3, N'2026-04-30T20:09:14.380', @superuser_id, N'OPEN', N'2026-04-30T20:09:14.380', 0, 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_34 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_34_output;

-- dbo.NBS_act_entity
-- step: 9
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_28 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_28_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_28_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003004, 1, N'2026-04-30T20:09:14.380', @superuser_id, N'OPEN', N'2026-04-30T20:09:14.380', N'ClosureInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_28 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_28_output;
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_10;
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_11;
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_12;
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_13;
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_2;
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_14;
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_15;
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_16;
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_4;
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_9;
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [entity_version_ctrl_nbr] = 4, [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid;
-- step: 9
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_5;

-- dbo.Person
-- step: 9
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:09:14.347', [record_status_time] = N'2026-04-30T20:09:14.347', [status_time] = N'2026-04-30T20:09:14.347', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 9
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:09:14.347', [record_status_time] = N'2026-04-30T20:09:14.347', [status_time] = N'2026-04-30T20:09:14.347' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 9
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:09:14.347', [record_status_time] = N'2026-04-30T20:09:14.347', [status_time] = N'2026-04-30T20:09:14.347' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 9
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:09:14.347', [record_status_time] = N'2026-04-30T20:09:14.347', [status_time] = N'2026-04-30T20:09:14.347' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;

-- dbo.Person
-- step: 9
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:09:14.357', [record_status_time] = N'2026-04-30T20:09:14.357', [status_time] = N'2026-04-30T20:09:14.357', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_4;

-- dbo.Person_name
-- step: 9
UPDATE [dbo].[Person_name] SET [last_chg_time] = N'2026-04-30T20:09:14.223' WHERE [person_uid] = @dbo_Entity_entity_uid_4 AND [person_name_seq] = 1;

-- dbo.Entity_id
-- step: 9
UPDATE [dbo].[Entity_id] SET [last_chg_time] = N'2026-04-30T20:09:14.247' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_id_seq] = 1;

-- dbo.Postal_locator
-- step: 9
UPDATE [dbo].[Postal_locator] SET [last_chg_time] = N'2026-04-30T20:09:14.223' WHERE [postal_locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;

-- dbo.Entity_locator_participation
-- step: 9
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:09:14.357', [record_status_time] = N'2026-04-30T20:09:14.357', [status_time] = N'2026-04-30T20:09:14.357' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;

-- dbo.Tele_locator
-- step: 9
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-04-30T20:09:14.223' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;

-- dbo.Entity_locator_participation
-- step: 9
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:09:14.357', [record_status_time] = N'2026-04-30T20:09:14.357', [status_time] = N'2026-04-30T20:09:14.357' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;

-- dbo.Tele_locator
-- step: 9
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-04-30T20:09:14.223' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;

-- dbo.Entity_locator_participation
-- step: 9
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:09:14.357', [record_status_time] = N'2026-04-30T20:09:14.357', [status_time] = N'2026-04-30T20:09:14.357' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;

-- dbo.Public_health_case
-- step: 9
UPDATE [dbo].[Public_health_case] SET [activity_to_time] = N'2026-04-27T00:00:00', [investigation_status_cd] = N'C', [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [curr_process_state_cd] = N'CC' WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;

-- dbo.Confirmation_method
-- step: 9
DELETE FROM [dbo].[Confirmation_method] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5 AND [confirmation_method_cd] = N'LD';
-- step: 9
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_5, N'LD', N'2026-04-24T00:00:00');

-- dbo.case_management
-- step: 9
UPDATE [dbo].[case_management] SET [case_review_status] = N'Ready', [case_closed_date] = N'2026-04-27T00:00:00', [case_review_status_date] = N'2026-04-30T20:09:14.247' WHERE [case_management_uid] = @dbo_case_management_case_management_uid;

-- dbo.Participation
-- step: 9
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:09:14.587', [last_chg_time] = N'2026-04-30T20:09:14.380', [record_status_time] = N'2026-04-30T20:09:14.380', [status_time] = N'2026-04-30T20:09:14.380' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';

-- dbo.SubjectRaceInfo
-- step: 9
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_5 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';

-- dbo.PublicHealthCaseFact
-- step: 9
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- step: 9
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [onSetDate], [organizationName], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-24T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'21', N'Self Referral', N'2026-04-21T00:00:00', N'PST', N'2026-04-17T00:00:00', N'O', 1.0, N'C', N'Xerogeanes, John', N'404-778-3350', N'130001', N'M', N'Married', N'2026-04-30T20:09:20.110', 17, 2026, N'2026-04-17T00:00:00', N'Emory University Hospital', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-04-30T19:32:00.637', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2026-04-30T19:32:00.493', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Nightingale, Florence', N'404-785-6000', N'2026-04-30T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-04-30T19:32:00.637', 10009283, @dbo_Person_local_id, N'2026-04-30T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Closed', N'Years', N'STD', N' Laboratory confirmed', N'2026-04-30T20:09:14.380', N'N');

-- dbo.SubjectRaceInfo
-- step: 9
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');

-- STEP 10: SupervisorRejectsCloseInvestigation

-- dbo.NBS_case_answer
-- step: 10
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_35 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_35_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_35_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'Ariella Kent~04/30/2026 20:17~~we need more information before we can close this.', 10001241, 1, N'2026-04-30T20:17:00.683', @superuser_id, N'OPEN', N'2026-04-30T20:09:14.380', 0, 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_35 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_35_output;

-- dbo.NBS_act_entity
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.683' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.683' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_2;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.683' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_4;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.683' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_5;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.683' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_9;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.683' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_10;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.683' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_11;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.683' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_12;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.683' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_13;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.683' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_14;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.683' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_15;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.683' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_16;
-- step: 10
DELETE FROM [dbo].[NBS_act_entity] WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_28;

-- dbo.message_log
-- step: 10
DECLARE @dbo_message_log_message_log_uid_5 bigint;
DECLARE @dbo_message_log_message_log_uid_5_output TABLE ([value] bigint);
INSERT INTO [dbo].[message_log] ([message_txt], [condition_cd], [person_uid], [assigned_to_uid], [event_uid], [event_type_cd], [message_status_cd], [record_status_cd], [record_status_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[message_log_uid] INTO @dbo_message_log_message_log_uid_5_output ([value]) VALUES (N'Investigation Reopened', N'10312', @dbo_Entity_entity_uid_4, 10003004, 10009300, N'Investigation', N'N', N'ACTIVE', N'2026-04-30T20:17:00.683', N'2026-04-30T20:17:00.683', @superuser_id, N'2026-04-30T20:17:00.683', @superuser_id);
SELECT TOP 1 @dbo_message_log_message_log_uid_5 = [value] FROM @dbo_message_log_message_log_uid_5_output;

-- dbo.NBS_case_answer
-- step: 10
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_36 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_36_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_36_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'Ariella Kent~04/30/2026 20:17~~we need more information before we can close this.', 10001241, 1, N'2026-04-30T20:17:00.797', @superuser_id, N'OPEN', N'2026-04-30T20:17:00.797', 0, 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_36 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_36_output;

-- dbo.NBS_act_entity
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.797', [record_status_time] = N'2026-04-30T20:17:00.797' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.797', [record_status_time] = N'2026-04-30T20:17:00.797' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_2;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.797', [record_status_time] = N'2026-04-30T20:17:00.797' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_4;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.797', [record_status_time] = N'2026-04-30T20:17:00.797' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_5;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.797', [record_status_time] = N'2026-04-30T20:17:00.797' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_9;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.797', [record_status_time] = N'2026-04-30T20:17:00.797' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_10;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.797', [record_status_time] = N'2026-04-30T20:17:00.797' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_11;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.797', [record_status_time] = N'2026-04-30T20:17:00.797' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_12;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.797', [record_status_time] = N'2026-04-30T20:17:00.797' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_13;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.797', [record_status_time] = N'2026-04-30T20:17:00.797' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_14;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.797', [record_status_time] = N'2026-04-30T20:17:00.797' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_15;
-- step: 10
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:17:00.797', [record_status_time] = N'2026-04-30T20:17:00.797' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_16;

-- dbo.Person
-- step: 10
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:17:00.770', [record_status_time] = N'2026-04-30T20:17:00.770', [status_time] = N'2026-04-30T20:17:00.770', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 10
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:17:00.770', [record_status_time] = N'2026-04-30T20:17:00.770', [status_time] = N'2026-04-30T20:17:00.770' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 10
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:17:00.770', [record_status_time] = N'2026-04-30T20:17:00.770', [status_time] = N'2026-04-30T20:17:00.770' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 10
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:17:00.770', [record_status_time] = N'2026-04-30T20:17:00.770', [status_time] = N'2026-04-30T20:17:00.770' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;

-- dbo.Person
-- step: 10
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:17:00.777', [record_status_time] = N'2026-04-30T20:17:00.777', [status_time] = N'2026-04-30T20:17:00.777', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_4;

-- dbo.Public_health_case
-- step: 10
UPDATE [dbo].[Public_health_case] SET [investigation_status_cd] = N'O', [last_chg_time] = N'2026-04-30T20:17:00.797', [record_status_time] = N'2026-04-30T20:17:00.797', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;

-- dbo.Confirmation_method
-- step: 10
DELETE FROM [dbo].[Confirmation_method] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5 AND [confirmation_method_cd] = N'LD';
-- step: 10
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_5, N'LD', N'2026-04-24T00:00:00');

-- dbo.case_management
-- step: 10
UPDATE [dbo].[case_management] SET [case_review_status] = N'Reject' WHERE [case_management_uid] = @dbo_case_management_case_management_uid;

-- dbo.Participation
-- step: 10
DELETE FROM [dbo].[Participation] WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'ClosureInvestgrOfPHC';
-- step: 10
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:17:00.923', [last_chg_time] = N'2026-04-30T20:17:00.800', [record_status_time] = N'2026-04-30T20:17:00.800', [status_time] = N'2026-04-30T20:17:00.800', [to_time] = N'2026-04-30T20:17:00.923' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'DispoFldFupInvestgrOfPHC';
-- step: 10
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:17:00.927', [last_chg_time] = N'2026-04-30T20:17:00.800', [record_status_time] = N'2026-04-30T20:17:00.800', [status_time] = N'2026-04-30T20:17:00.800', [to_time] = N'2026-04-30T20:17:00.927' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'FldFupSupervisorOfPHC';
-- step: 10
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:17:00.930', [last_chg_time] = N'2026-04-30T20:17:00.800', [record_status_time] = N'2026-04-30T20:17:00.800', [status_time] = N'2026-04-30T20:17:00.800', [to_time] = N'2026-04-30T20:17:00.930' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'InitInterviewerOfPHC';
-- step: 10
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:17:00.930', [last_chg_time] = N'2026-04-30T20:17:00.800', [record_status_time] = N'2026-04-30T20:17:00.800', [status_time] = N'2026-04-30T20:17:00.800', [to_time] = N'2026-04-30T20:17:00.930' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'InterviewerOfPHC';
-- step: 10
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:17:00.930', [last_chg_time] = N'2026-04-30T20:17:00.800', [record_status_time] = N'2026-04-30T20:17:00.800', [status_time] = N'2026-04-30T20:17:00.800', [to_time] = N'2026-04-30T20:17:00.930' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'InvestgrOfPHC';
-- step: 10
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:17:00.930', [last_chg_time] = N'2026-04-30T20:17:00.800', [record_status_time] = N'2026-04-30T20:17:00.800', [status_time] = N'2026-04-30T20:17:00.800', [to_time] = N'2026-04-30T20:17:00.930' WHERE [subject_entity_uid] = 10003010 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'InitFupInvestgrOfPHC';
-- step: 10
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:17:00.930', [last_chg_time] = N'2026-04-30T20:17:00.800', [record_status_time] = N'2026-04-30T20:17:00.800', [status_time] = N'2026-04-30T20:17:00.800', [to_time] = N'2026-04-30T20:17:00.930' WHERE [subject_entity_uid] = 10003010 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SurvInvestgrOfPHC';
-- step: 10
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:17:00.930', [last_chg_time] = N'2026-04-30T20:17:00.800', [record_status_time] = N'2026-04-30T20:17:00.800', [status_time] = N'2026-04-30T20:17:00.800', [to_time] = N'2026-04-30T20:17:00.930' WHERE [subject_entity_uid] = 10003013 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'FldFupInvestgrOfPHC';
-- step: 10
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:17:00.930', [last_chg_time] = N'2026-04-30T20:17:00.800', [record_status_time] = N'2026-04-30T20:17:00.800', [status_time] = N'2026-04-30T20:17:00.800', [to_time] = N'2026-04-30T20:17:00.930' WHERE [subject_entity_uid] = 10003013 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'InitFldFupInvestgrOfPHC';
-- step: 10
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:17:00.930', [last_chg_time] = N'2026-04-30T20:17:00.800', [record_status_time] = N'2026-04-30T20:17:00.800', [status_time] = N'2026-04-30T20:17:00.800', [to_time] = N'2026-04-30T20:17:00.930' WHERE [subject_entity_uid] = 10003019 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'OrgAsReporterOfPHC';
-- step: 10
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:17:00.930', [last_chg_time] = N'2026-04-30T20:17:00.800', [record_status_time] = N'2026-04-30T20:17:00.800', [status_time] = N'2026-04-30T20:17:00.800', [to_time] = N'2026-04-30T20:17:00.930' WHERE [subject_entity_uid] = 10003022 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'PerAsReporterOfPHC';
-- step: 10
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:17:00.930', [last_chg_time] = N'2026-04-30T20:17:00.800', [record_status_time] = N'2026-04-30T20:17:00.800', [status_time] = N'2026-04-30T20:17:00.800' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';

-- dbo.SubjectRaceInfo
-- step: 10
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_5 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';

-- dbo.PublicHealthCaseFact
-- step: 10
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- step: 10
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [onSetDate], [organizationName], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-24T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'21', N'Self Referral', N'2026-04-21T00:00:00', N'PST', N'2026-04-17T00:00:00', N'O', 1.0, N'O', N'Xerogeanes, John', N'404-778-3350', N'130001', N'M', N'Married', N'2026-04-30T20:17:08.777', 17, 2026, N'2026-04-17T00:00:00', N'Emory University Hospital', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-04-30T19:32:00.637', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2026-04-30T19:32:00.493', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Nightingale, Florence', N'404-785-6000', N'2026-04-30T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-04-30T19:32:00.637', 10009283, @dbo_Person_local_id, N'2026-04-30T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Open', N'Years', N'STD', N' Laboratory confirmed', N'2026-04-30T20:17:00.797', N'N');

-- dbo.SubjectRaceInfo
-- step: 10
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');

-- STEP 11: CloseInvestigationAndCreateNotificationSyphilis

-- dbo.message_log
-- step: 11
DECLARE @dbo_message_log_message_log_uid_6 bigint;
DECLARE @dbo_message_log_message_log_uid_6_output TABLE ([value] bigint);
INSERT INTO [dbo].[message_log] ([message_txt], [condition_cd], [person_uid], [assigned_to_uid], [event_uid], [event_type_cd], [message_status_cd], [record_status_cd], [record_status_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[message_log_uid] INTO @dbo_message_log_message_log_uid_6_output ([value]) VALUES (N'Field Supervisory Review/Comments Modified', N'10312', @dbo_Entity_entity_uid_4, 10003004, 10009300, N'Investigation', N'N', N'ACTIVE', N'2026-04-30T20:22:45.880', N'2026-04-30T20:22:45.880', @superuser_id, N'2026-04-30T20:22:45.880', @superuser_id);
SELECT TOP 1 @dbo_message_log_message_log_uid_6 = [value] FROM @dbo_message_log_message_log_uid_6_output;

-- dbo.NBS_case_answer
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_5;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_6;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_7;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_8;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_9;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_10;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_11;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_12;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_13;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_14;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_15;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_16;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_17;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_33;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_18;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_19;
-- step: 11
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_37 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_37_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_37_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'1', 10001261, 3, N'2026-04-30T20:22:45.977', @superuser_id, N'OPEN', N'2026-04-30T20:22:45.977', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_37 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_37_output;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_2;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_20;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_21;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_22;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_23;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_24;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_25;
-- step: 11
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_38 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_38_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_38_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'N', 10001274, 3, N'2026-04-30T20:22:45.977', @superuser_id, N'OPEN', N'2026-04-30T20:22:45.977', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_38 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_38_output;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_26;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_3;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_27;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_28;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_4;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_29;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_34;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [nbs_question_version_ctrl_nbr] = 3, [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_36;
-- step: 11
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_39 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_39_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_39_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'Ariella Kent~04/30/2026 16:22~~here are some more notes', 10001248, 3, N'2026-04-30T20:22:45.977', @superuser_id, N'OPEN', N'2026-04-30T20:22:45.977', 0, 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_39 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_39_output;

-- dbo.NBS_act_entity
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_10;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_11;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_12;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_13;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_2;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_14;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_15;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_16;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_4;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_9;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [entity_version_ctrl_nbr] = 6, [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:45.977', [record_status_time] = N'2026-04-30T20:22:45.977' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_5;

-- dbo.Person
-- step: 11
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:22:45.950', [record_status_time] = N'2026-04-30T20:22:45.950', [status_time] = N'2026-04-30T20:22:45.950', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 11
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:22:45.950', [record_status_time] = N'2026-04-30T20:22:45.950', [status_time] = N'2026-04-30T20:22:45.950' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 11
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:22:45.950', [record_status_time] = N'2026-04-30T20:22:45.950', [status_time] = N'2026-04-30T20:22:45.950' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 11
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:22:45.950', [record_status_time] = N'2026-04-30T20:22:45.950', [status_time] = N'2026-04-30T20:22:45.950' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;

-- dbo.Person
-- step: 11
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:22:45.960', [record_status_time] = N'2026-04-30T20:22:45.960', [status_time] = N'2026-04-30T20:22:45.960', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_4;

-- dbo.Person_name
-- step: 11
UPDATE [dbo].[Person_name] SET [last_chg_time] = N'2026-04-30T20:22:45.883' WHERE [person_uid] = @dbo_Entity_entity_uid_4 AND [person_name_seq] = 1;

-- dbo.Entity_id
-- step: 11
UPDATE [dbo].[Entity_id] SET [last_chg_time] = N'2026-04-30T20:22:45.907' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_id_seq] = 1;

-- dbo.Postal_locator
-- step: 11
UPDATE [dbo].[Postal_locator] SET [last_chg_time] = N'2026-04-30T20:22:45.883' WHERE [postal_locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;

-- dbo.Entity_locator_participation
-- step: 11
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:22:45.960', [record_status_time] = N'2026-04-30T20:22:45.960', [status_time] = N'2026-04-30T20:22:45.960' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;

-- dbo.Tele_locator
-- step: 11
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-04-30T20:22:45.883' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;

-- dbo.Entity_locator_participation
-- step: 11
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:22:45.960', [record_status_time] = N'2026-04-30T20:22:45.960', [status_time] = N'2026-04-30T20:22:45.960' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;

-- dbo.Tele_locator
-- step: 11
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-04-30T20:22:45.883' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;

-- dbo.Entity_locator_participation
-- step: 11
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:22:45.960', [record_status_time] = N'2026-04-30T20:22:45.960', [status_time] = N'2026-04-30T20:22:45.960' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;

-- dbo.Public_health_case
-- step: 11
UPDATE [dbo].[Public_health_case] SET [disease_imported_cd] = N'', [effective_duration_amt] = N'', [effective_duration_unit_cd] = N'', [last_chg_time] = N'2026-04-30T20:22:45.977', [outbreak_ind] = N'', [outbreak_name] = N'', [outcome_cd] = N'', [record_status_time] = N'2026-04-30T20:22:45.977', [rpt_source_cd] = N'', [txt] = N'', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [day_care_ind_cd] = N'', [food_handler_ind_cd] = N'', [imported_country_cd] = N'', [imported_state_cd] = N'', [imported_city_desc_txt] = N'', [imported_county_cd] = N'', [priority_cd] = N'', [contact_inv_txt] = N'', [contact_inv_status_cd] = N'', [curr_process_state_cd] = N'OC' WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;

-- dbo.Confirmation_method
-- step: 11
DELETE FROM [dbo].[Confirmation_method] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5 AND [confirmation_method_cd] = N'LD';
-- step: 11
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_5, N'LD', N'2026-04-24T00:00:00');

-- dbo.Participation
-- step: 11
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:22:46.167', [last_chg_time] = N'2026-04-30T20:22:45.980', [record_status_time] = N'2026-04-30T20:22:45.980', [status_time] = N'2026-04-30T20:22:45.980' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';

-- dbo.message_log
-- step: 11
DECLARE @dbo_message_log_message_log_uid_7 bigint;
DECLARE @dbo_message_log_message_log_uid_7_output TABLE ([value] bigint);
INSERT INTO [dbo].[message_log] ([message_txt], [condition_cd], [person_uid], [assigned_to_uid], [event_uid], [event_type_cd], [message_status_cd], [record_status_cd], [record_status_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[message_log_uid] INTO @dbo_message_log_message_log_uid_7_output ([value]) VALUES (N'Field Supervisory Review/Comments Modified', N'10312', @dbo_Entity_entity_uid_4, 10003004, 10009300, N'Investigation', N'N', N'ACTIVE', N'2026-04-30T20:22:47.463', N'2026-04-30T20:22:47.463', @superuser_id, N'2026-04-30T20:22:47.463', @superuser_id);
SELECT TOP 1 @dbo_message_log_message_log_uid_7 = [value] FROM @dbo_message_log_message_log_uid_7_output;

-- dbo.Participation
-- step: 11
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_5, N'ClosureInvestgrOfPHC', N'CASE', N'2026-04-30T19:32:00.637', @superuser_id, N'2026-04-30T20:22:47.477', @superuser_id, N'ACTIVE', N'2026-04-30T20:22:47.477', N'A', N'2026-04-30T20:22:47.477', N'PSN');

-- dbo.NBS_case_answer
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_5;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_6;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_7;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_8;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_9;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_10;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_11;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_12;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_13;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_14;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_15;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_16;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_17;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_33;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_18;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_19;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_37;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_2;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_20;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_21;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_22;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_23;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_24;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_25;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_38;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_26;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_3;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_27;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_28;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_4;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_29;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_34;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_36;
-- step: 11
UPDATE [dbo].[NBS_case_answer] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_case_answer_uid] = @dbo_NBS_case_answer_nbs_case_answer_uid_39;

-- dbo.NBS_act_entity
-- step: 11
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_29 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_29_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_29_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, 10003004, 1, N'2026-04-30T20:22:47.510', @superuser_id, N'OPEN', N'2026-04-30T20:22:47.510', N'ClosureInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_29 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_29_output;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_10;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_11;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_12;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_13;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_2;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_14;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_15;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_16;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_4;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_9;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [entity_version_ctrl_nbr] = 7, [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid;
-- step: 11
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_5;

-- dbo.Person
-- step: 11
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:22:47.497', [record_status_time] = N'2026-04-30T20:22:47.497', [status_time] = N'2026-04-30T20:22:47.497', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 11
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:22:47.497', [record_status_time] = N'2026-04-30T20:22:47.497', [status_time] = N'2026-04-30T20:22:47.497' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 11
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:22:47.497', [record_status_time] = N'2026-04-30T20:22:47.497', [status_time] = N'2026-04-30T20:22:47.497' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 11
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:22:47.497', [record_status_time] = N'2026-04-30T20:22:47.497', [status_time] = N'2026-04-30T20:22:47.497' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;

-- dbo.Person
-- step: 11
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:22:47.500', [record_status_time] = N'2026-04-30T20:22:47.500', [status_time] = N'2026-04-30T20:22:47.500', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_4;

-- dbo.Person_name
-- step: 11
UPDATE [dbo].[Person_name] SET [last_chg_time] = N'2026-04-30T20:22:47.463' WHERE [person_uid] = @dbo_Entity_entity_uid_4 AND [person_name_seq] = 1;

-- dbo.Entity_id
-- step: 11
UPDATE [dbo].[Entity_id] SET [last_chg_time] = N'2026-04-30T20:22:47.477' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [entity_id_seq] = 1;

-- dbo.Postal_locator
-- step: 11
UPDATE [dbo].[Postal_locator] SET [last_chg_time] = N'2026-04-30T20:22:47.463' WHERE [postal_locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;

-- dbo.Entity_locator_participation
-- step: 11
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:22:47.500', [record_status_time] = N'2026-04-30T20:22:47.500', [status_time] = N'2026-04-30T20:22:47.500' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;

-- dbo.Tele_locator
-- step: 11
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-04-30T20:22:47.463' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;

-- dbo.Entity_locator_participation
-- step: 11
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:22:47.500', [record_status_time] = N'2026-04-30T20:22:47.500', [status_time] = N'2026-04-30T20:22:47.500' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_6;

-- dbo.Tele_locator
-- step: 11
UPDATE [dbo].[Tele_locator] SET [last_chg_time] = N'2026-04-30T20:22:47.463' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;

-- dbo.Entity_locator_participation
-- step: 11
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:22:47.500', [record_status_time] = N'2026-04-30T20:22:47.500', [status_time] = N'2026-04-30T20:22:47.500' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;

-- dbo.Public_health_case
-- step: 11
UPDATE [dbo].[Public_health_case] SET [activity_to_time] = N'2026-04-27T00:00:00', [investigation_status_cd] = N'C', [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [curr_process_state_cd] = N'CC' WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;

-- dbo.Confirmation_method
-- step: 11
DELETE FROM [dbo].[Confirmation_method] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5 AND [confirmation_method_cd] = N'LD';
-- step: 11
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_5, N'LD', N'2026-04-24T00:00:00');

-- dbo.case_management
-- step: 11
UPDATE [dbo].[case_management] SET [case_review_status] = N'Ready', [case_closed_date] = N'2026-04-27T00:00:00', [case_review_status_date] = N'2026-04-30T20:22:47.477' WHERE [case_management_uid] = @dbo_case_management_case_management_uid;

-- dbo.Participation
-- step: 11
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:22:47.560', [last_chg_time] = N'2026-04-30T20:22:47.510', [record_status_time] = N'2026-04-30T20:22:47.510', [status_time] = N'2026-04-30T20:22:47.510' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';

-- dbo.Act
-- step: 11
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_10, N'NOTF', N'EVN');

-- dbo.Notification
-- step: 11
DECLARE @dbo_Notification_local_id nvarchar(40) = N'NOT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_10))) + N'GA01';
INSERT INTO [dbo].[Notification] ([notification_uid], [add_time], [add_user_id], [case_class_cd], [case_condition_cd], [cd], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [mmwr_week], [mmwr_year], [prog_area_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [auto_resend_ind]) VALUES (@dbo_Act_act_uid_10, N'2026-04-30T20:22:48.217', @superuser_id, N'C', N'10312', N'NOTF', N'130001', N'2026-04-30T20:22:48.217', @superuser_id, @dbo_Notification_local_id, N'17', N'2026', N'STD', N'APPROVED', N'2026-04-30T20:22:48.217', N'A', N'2026-04-30T20:22:48.207', N'tell the CDC about this', 1300100015, N'T', 1, N'F');

-- dbo.Act_relationship
-- step: 11
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [sequence_nbr], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_5, @dbo_Act_act_uid_10, N'Notification', N'2026-04-30T20:22:48.207', N'2026-04-30T20:22:48.240', N'ACTIVE', N'2026-04-30T20:22:48.240', 1, N'NOTF', N'A', N'2026-04-30T20:22:48.207', N'CASE');

-- dbo.SubjectRaceInfo
-- step: 11
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_5 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';

-- dbo.PublicHealthCaseFact
-- step: 11
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- step: 11
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [ELP_class_cd], [event_date], [event_type], [firstNotificationdate], [firstNotificationStatus], [firstNotificationSubmittedBy], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [lastNotificationdate], [lastNotificationSubmittedBy], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [notifCreatedCount], [notifSentCount], [onSetDate], [organizationName], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [NOTIFCURRENTSTATE], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [NOTITXT], [NOTIFICATION_LOCAL_ID], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-24T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'21', N'Self Referral', N'2026-04-21T00:00:00', N'PST', N'2026-04-17T00:00:00', N'O', N'2026-04-30T20:22:48.217', N'APPROVED', 10009282, 1.0, N'C', N'Xerogeanes, John', N'404-778-3350', N'130001', N'2026-04-30T20:22:48.217', 10009282, N'M', N'Married', N'2026-04-30T20:22:53.027', 17, 2026, 1, 0, N'2026-04-17T00:00:00', N'Emory University Hospital', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-04-30T19:32:00.637', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2026-04-30T19:32:00.493', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Nightingale, Florence', N'404-785-6000', N'2026-04-30T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-04-30T19:32:00.637', 10009283, @dbo_Person_local_id, N'2026-04-30T00:00:00', @dbo_Public_health_case_local_id, N'APPROVED', N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Closed', N'Years', N'STD', N' Laboratory confirmed', N'2026-04-30T20:22:47.510', N'tell the CDC about this', @dbo_Notification_local_id, N'N');

-- dbo.SubjectRaceInfo
-- step: 11
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');
-- step: 11
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_5 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';

-- dbo.PublicHealthCaseFact
-- step: 11
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- step: 11
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [ELP_class_cd], [event_date], [event_type], [firstNotificationdate], [firstNotificationStatus], [firstNotificationSubmittedBy], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [lastNotificationdate], [lastNotificationSubmittedBy], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [notifCreatedCount], [notifSentCount], [onSetDate], [organizationName], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [NOTIFCURRENTSTATE], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [NOTITXT], [NOTIFICATION_LOCAL_ID], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-24T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'21', N'Self Referral', N'2026-04-21T00:00:00', N'PST', N'2026-04-17T00:00:00', N'O', N'2026-04-30T20:22:48.217', N'APPROVED', 10009282, 1.0, N'C', N'Xerogeanes, John', N'404-778-3350', N'130001', N'2026-04-30T20:22:48.217', 10009282, N'M', N'Married', N'2026-04-30T20:22:53.493', 17, 2026, 1, 0, N'2026-04-17T00:00:00', N'Emory University Hospital', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-04-30T19:32:00.637', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2026-04-30T19:32:00.493', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Nightingale, Florence', N'404-785-6000', N'2026-04-30T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-04-30T19:32:00.637', 10009283, @dbo_Person_local_id, N'2026-04-30T00:00:00', @dbo_Public_health_case_local_id, N'APPROVED', N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Closed', N'Years', N'STD', N' Laboratory confirmed', N'2026-04-30T20:22:47.510', N'tell the CDC about this', @dbo_Notification_local_id, N'N');

-- dbo.SubjectRaceInfo
-- step: 11
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');

-- STEP 12: SupervisorApprove

-- dbo.NBS_case_answer
-- step: 12
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_40 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_40_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_40_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'Ariella Kent~04/30/2026 20:27~~keep updating if new information comes in', 10001241, 1, N'2026-04-30T20:27:43.180', @superuser_id, N'OPEN', N'2026-04-30T20:22:47.510', 0, 2);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_40 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_40_output;

-- dbo.NBS_act_entity
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.180' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.180' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_2;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.180' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_4;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.180' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_5;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.180' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_9;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.180' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_10;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.180' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_11;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.180' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_12;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.180' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_13;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.180' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_14;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.180' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_15;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.180' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_16;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.180' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_29;

-- dbo.NBS_case_answer
-- step: 12
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_41 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_41_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_41_output ([value]) VALUES (@dbo_Act_act_uid_5, N'2026-04-30T19:32:00.637', @superuser_id, N'Ariella Kent~04/30/2026 20:27~~keep updating if new information comes in', 10001241, 1, N'2026-04-30T20:27:43.313', @superuser_id, N'OPEN', N'2026-04-30T20:27:43.313', 0, 2);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_41 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_41_output;

-- dbo.NBS_act_entity
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_2;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_4;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_5;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_9;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_10;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_11;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_12;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_13;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_14;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_15;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_16;
-- step: 12
UPDATE [dbo].[NBS_act_entity] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313' WHERE [nbs_act_entity_uid] = @dbo_NBS_act_entity_nbs_act_entity_uid_29;

-- dbo.Person
-- step: 12
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:27:43.287', [record_status_time] = N'2026-04-30T20:27:43.287', [status_time] = N'2026-04-30T20:27:43.287', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 12
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:27:43.287', [record_status_time] = N'2026-04-30T20:27:43.287', [status_time] = N'2026-04-30T20:27:43.287' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 12
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:27:43.287', [record_status_time] = N'2026-04-30T20:27:43.287', [status_time] = N'2026-04-30T20:27:43.287' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 12
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-30T20:27:43.287', [record_status_time] = N'2026-04-30T20:27:43.287', [status_time] = N'2026-04-30T20:27:43.287' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;

-- dbo.Person
-- step: 12
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-30T20:27:43.297', [record_status_time] = N'2026-04-30T20:27:43.297', [status_time] = N'2026-04-30T20:27:43.297', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_4;

-- dbo.Public_health_case
-- step: 12
UPDATE [dbo].[Public_health_case] SET [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;

-- dbo.Confirmation_method
-- step: 12
DELETE FROM [dbo].[Confirmation_method] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5 AND [confirmation_method_cd] = N'LD';
-- step: 12
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_5, N'LD', N'2026-04-24T00:00:00');

-- dbo.case_management
-- step: 12
UPDATE [dbo].[case_management] SET [case_review_status] = N'Accept' WHERE [case_management_uid] = @dbo_case_management_case_management_uid;

-- dbo.Participation
-- step: 12
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:27:43.437', [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [status_time] = N'2026-04-30T20:27:43.313', [to_time] = N'2026-04-30T20:27:43.437' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'ClosureInvestgrOfPHC';
-- step: 12
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:27:43.440', [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [status_time] = N'2026-04-30T20:27:43.313' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'DispoFldFupInvestgrOfPHC';
-- step: 12
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:27:43.443', [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [status_time] = N'2026-04-30T20:27:43.313' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'FldFupSupervisorOfPHC';
-- step: 12
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:27:43.443', [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [status_time] = N'2026-04-30T20:27:43.313' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'InitInterviewerOfPHC';
-- step: 12
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:27:43.443', [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [status_time] = N'2026-04-30T20:27:43.313' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'InterviewerOfPHC';
-- step: 12
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:27:43.443', [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [status_time] = N'2026-04-30T20:27:43.313' WHERE [subject_entity_uid] = 10003004 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'InvestgrOfPHC';
-- step: 12
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:27:43.443', [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [status_time] = N'2026-04-30T20:27:43.313' WHERE [subject_entity_uid] = 10003010 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'InitFupInvestgrOfPHC';
-- step: 12
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:27:43.443', [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [status_time] = N'2026-04-30T20:27:43.313' WHERE [subject_entity_uid] = 10003010 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SurvInvestgrOfPHC';
-- step: 12
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:27:43.443', [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [status_time] = N'2026-04-30T20:27:43.313' WHERE [subject_entity_uid] = 10003013 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'FldFupInvestgrOfPHC';
-- step: 12
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:27:43.443', [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [status_time] = N'2026-04-30T20:27:43.313' WHERE [subject_entity_uid] = 10003013 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'InitFldFupInvestgrOfPHC';
-- step: 12
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:27:43.443', [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [status_time] = N'2026-04-30T20:27:43.313' WHERE [subject_entity_uid] = 10003019 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'OrgAsReporterOfPHC';
-- step: 12
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:27:43.443', [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [status_time] = N'2026-04-30T20:27:43.313' WHERE [subject_entity_uid] = 10003022 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'PerAsReporterOfPHC';
-- step: 12
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-30T20:27:43.443', [last_chg_time] = N'2026-04-30T20:27:43.313', [record_status_time] = N'2026-04-30T20:27:43.313', [status_time] = N'2026-04-30T20:27:43.313' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_5 AND [type_cd] = N'SubjOfPHC';

-- dbo.Notification
-- step: 12
UPDATE [dbo].[Notification] SET [last_chg_time] = N'2026-04-30T20:27:43.327', [record_status_time] = N'2026-04-30T20:27:43.327', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [notification_uid] = @dbo_Act_act_uid_10;

-- dbo.PublicHealthCaseFact
-- step: 12
UPDATE [dbo].[PublicHealthCaseFact] SET [lastNotificationdate] = N'2026-04-30T20:27:43.327', [notifCreatedCount] = 2 WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;

-- dbo.SubjectRaceInfo
-- step: 12
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_5 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';

-- dbo.PublicHealthCaseFact
-- step: 12
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_5;
-- step: 12
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [ELP_class_cd], [event_date], [event_type], [firstNotificationdate], [firstNotificationStatus], [firstNotificationSubmittedBy], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [lastNotificationdate], [lastNotificationSubmittedBy], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [notifCreatedCount], [notifSentCount], [onSetDate], [organizationName], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [NOTIFCURRENTSTATE], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [NOTITXT], [NOTIFICATION_LOCAL_ID], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_5, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-24T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'21', N'Self Referral', N'2026-04-21T00:00:00', N'PST', N'2026-04-17T00:00:00', N'O', N'2026-04-30T20:22:48.217', N'APPROVED', 10009282, 1.0, N'C', N'Xerogeanes, John', N'404-778-3350', N'130001', N'2026-04-30T20:27:43.327', 10009282, N'M', N'Married', N'2026-04-30T20:27:51.873', 17, 2026, 2, 0, N'2026-04-17T00:00:00', N'Emory University Hospital', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-04-30T19:32:00.637', N'10312', N'Syphilis, secondary', N'Syphilis, secondary', N'STD', N'2026-04-30T19:32:00.493', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Nightingale, Florence', N'404-785-6000', N'2026-04-30T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake77gg, Taylor', N'Fulton County', N'2026-04-24T00:00:00', 1300100015, N'2026-04-30T19:32:00.637', 10009283, @dbo_Person_local_id, N'2026-04-30T00:00:00', @dbo_Public_health_case_local_id, N'APPROVED', N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Closed', N'Years', N'STD', N' Laboratory confirmed', N'2026-04-30T20:27:43.313', N'tell the CDC about this', @dbo_Notification_local_id, N'N');

-- dbo.SubjectRaceInfo
-- step: 12
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_5, N'2106-3', N'2106-3');
