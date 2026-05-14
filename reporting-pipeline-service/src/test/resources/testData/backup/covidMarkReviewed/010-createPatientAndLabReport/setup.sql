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

-- STEP 1: CreatePatientAndAddLabReportCovid
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid, N'PSN');
-- dbo.Person
-- step: 1
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [birth_gender_cd], [birth_time], [birth_time_calc], [cd], [curr_sex_cd], [deceased_ind_cd], [last_chg_time], [last_chg_user_id], [local_id], [marital_status_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid], [edx_ind]) VALUES (@dbo_Entity_entity_uid, N'2026-04-27T21:25:28.777', @superuser_id, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'PAT', N'F', N'N', N'2026-04-27T21:25:28.777', @superuser_id, @dbo_Person_local_id, N'M', N'ACTIVE', N'2026-04-27T21:25:28.777', N'A', N'2026-04-27T21:25:28.777', N'Taylor', N'Swift_fake66ff', 1, N'2026-04-27T00:00:00', N'2026-04-27T00:00:00', N'2026-04-27T00:00:00', N'2026-04-27T00:00:00', N'N', @dbo_Entity_entity_uid, N'Y');
-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [first_nm], [first_nm_sndx], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid, 1, N'Add', N'2026-04-27T21:25:28.713', N'Taylor', N'T460', N'Swift_fake66ff', N'S130', N'L', N'ACTIVE', N'2026-04-27T21:25:28.713', N'A', N'2026-04-27T21:25:28.713', N'2026-04-27T00:00:00');
-- dbo.Person_race
-- step: 1
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [race_category_cd], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid, N'2106-3', N'2026-04-27T21:25:28.727', N'2106-3', N'ACTIVE', N'2026-04-27T00:00:00');
-- dbo.Entity_id
-- step: 1
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [assigning_authority_cd], [assigning_authority_desc_txt], [last_chg_time], [record_status_cd], [record_status_time], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid, 1, N'2026-04-27T21:25:28.713', N'GA', N'GA', N'2026-04-27T21:25:28.713', N'ACTIVE', N'2026-04-27T21:25:28.713', N'123987456', N'A', N'2026-04-27T21:25:28.713', N'DL', N'Driver''s license number', N'2026-04-27T00:00:00', N'L');
-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [city_desc_txt], [cntry_cd], [cnty_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [street_addr2], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid, N'2026-04-27T21:25:28.727', N'Atlanta', N'840', N'13121', N'ACTIVE', N'2026-04-27T21:25:28.727', N'13', N'1313 Pine Way', N'', N'30033');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Postal_locator_postal_locator_uid, N'H', N'PST', N'2026-04-27T21:25:28.777', @superuser_id, N'ACTIVE', N'2026-04-27T21:25:28.777', N'A', N'2026-04-27T21:25:28.777', N'H', 1, N'2026-04-27T00:00:00');
-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid, N'2026-04-27T21:25:28.727', @superuser_id, N'201-555-1212', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Tele_locator_tele_locator_uid, N'PH', N'TELE', N'2026-04-27T21:25:28.777', @superuser_id, N'ACTIVE', N'2026-04-27T21:25:28.777', N'A', N'2026-04-27T21:25:28.777', N'H', 1, N'2026-04-27T00:00:00');
-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_2, N'2026-04-27T21:25:28.727', @superuser_id, N'taylor@example.com', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Tele_locator_tele_locator_uid_2, N'NET', N'TELE', N'2026-04-27T21:25:28.777', @superuser_id, N'ACTIVE', N'2026-04-27T21:25:28.777', N'A', N'2026-04-27T21:25:28.777', N'H', 1, N'2026-04-27T00:00:00');
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_2, N'PSN');
-- dbo.Person
-- step: 1
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [age_reported], [age_reported_unit_cd], [birth_time], [birth_time_calc], [cd], [curr_sex_cd], [deceased_ind_cd], [last_chg_time], [last_chg_user_id], [local_id], [marital_status_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_2, N'2026-04-27T21:25:33.830', @superuser_id, N'41', N'Y', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'PAT', N'F', N'N', N'2026-04-27T21:25:33.830', @superuser_id, @dbo_Person_local_id, N'M', N'ACTIVE', N'2026-04-27T21:25:33.830', N'A', N'2026-04-27T21:25:33.830', N'Taylor', N'Swift_fake66ff', 1, N'2026-04-27T00:00:00', N'2026-04-27T00:00:00', N'2026-04-27T00:00:00', N'2026-04-27T00:00:00', N'N', @dbo_Entity_entity_uid);
-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, 1, N'ADD LAB REPORT', N'2026-04-27T21:25:33.700', @superuser_id, N'Taylor', N'T460', N'2026-04-27T21:25:33.700', @superuser_id, N'Swift_fake66ff', N'S130', N'L', N'ACTIVE', N'2026-04-27T21:25:33.700', N'A', N'2026-04-27T21:25:33.700', N'2026-04-27T00:00:00');
-- dbo.Person_race
-- step: 1
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [add_user_id], [race_category_cd], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, N'2106-3', N'2026-04-27T21:25:33.700', @superuser_id, N'2106-3', N'ACTIVE', N'2026-04-27T00:00:00');
-- dbo.Entity_id
-- step: 1
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [assigning_authority_cd], [assigning_authority_desc_txt], [last_chg_time], [record_status_cd], [record_status_time], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid_2, 1, N'2026-04-27T21:25:33.757', N'GA', N'GA', N'2026-04-27T21:25:33.757', N'ACTIVE', N'2026-04-27T21:25:33.757', N'123987456', N'A', N'2026-04-27T21:25:33.757', N'DL', N'Driver''s license number', N'2026-04-27T00:00:00', N'L');
-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt], [cntry_cd], [cnty_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_2, N'2026-04-27T21:25:33.700', @superuser_id, N'Atlanta', N'840', N'13121', N'ACTIVE', N'2026-04-27T21:25:33.700', N'13', N'1313 Pine Way', N'30033');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Postal_locator_postal_locator_uid_2, N'H', N'PST', N'2026-04-27T21:25:33.830', @superuser_id, N'ACTIVE', N'2026-04-27T21:25:33.830', N'A', N'2026-04-27T21:25:33.830', N'H', 1, N'2026-04-27T00:00:00');
-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_3, N'2026-04-27T21:25:33.700', @superuser_id, N'', N'201-555-1212', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Tele_locator_tele_locator_uid_3, N'PH', N'TELE', N'2026-04-27T21:25:33.830', @superuser_id, N'ACTIVE', N'2026-04-27T21:25:33.830', N'A', N'2026-04-27T21:25:33.830', N'H', 1, N'2026-04-27T00:00:00');
-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_4, N'2026-04-27T21:25:33.700', @superuser_id, N'taylor@example.com', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Tele_locator_tele_locator_uid_4, N'NET', N'TELE', N'2026-04-27T21:25:33.830', @superuser_id, N'ACTIVE', N'2026-04-27T21:25:33.830', N'A', N'2026-04-27T21:25:33.830', N'H', 1, N'2026-04-27T00:00:00');
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid, N'OBS', N'EVN');
-- dbo.Observation
-- step: 1
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [effective_from_time], [electronic_ind], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [obs_domain_cd_st_1], [prog_area_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [target_site_cd], [target_site_desc_txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd], [rpt_to_state_time]) VALUES (@dbo_Act_act_uid, N'2026-04-20T00:00:00', N'ADD LAB REPORT', N'2026-04-27T21:25:33.867', @superuser_id, N'T-60825', N'Culture, Skin Biopsy', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'2026-04-20T00:00:00', N'N', N'130001', N'2026-04-27T21:25:33.867', @superuser_id, @dbo_Observation_local_id, N'Order', N'GCD', N'UNPROCESSED', N'2026-04-27T21:25:33.867', N'D', N'2026-04-27T21:25:33.700', N'LN', N'Left Naris', 1300100009, N'T', 1, N'620-5', N'MICROORGANISM IDENTIFIED', N'LN', N'2026-04-27T00:00:00');
-- dbo.Act_id
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, 0, N'Default Manual Lab', N'ACTIVE', N'1234567890', N'A', N'2026-04-27T21:25:33.713', N'FN', N'Filler Number');
-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq]) VALUES (@dbo_Act_act_uid, 0);
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_2, N'OBS', N'EVN');
-- dbo.Observation
-- step: 1
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [local_id], [obs_domain_cd_st_1], [record_status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_2, N'LAB330', N'Patient Status at Specimen Collection', N'2.16.840.1.114222.4.5.1', @dbo_Observation_local_id_2, N'Order_rslt', N'ACTIVE', N'2026-04-27T21:25:33.720', 4, N'T', 1);
-- dbo.Obs_value_coded
-- step: 1
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code], [display_name]) VALUES (@dbo_Act_act_uid_2, N'OUTP', N'outpatient');
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_3, N'OBS', N'EVN');
-- dbo.Observation
-- step: 1
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [effective_from_time], [local_id], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [rpt_to_state_time]) VALUES (@dbo_Act_act_uid_3, N'2026-04-20T00:00:00', N'NI', N'No Information Given', N'2.16.840.1.113883', N'LabComment', N'Lab Report', N'2026-04-20T00:00:00', @dbo_Observation_local_id_3, N'C_Order', N'D', N'2026-04-27T21:25:33.720', 4, N'T', 1, N'2026-04-27T00:00:00');
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_4, N'OBS', N'EVN');
-- dbo.Observation
-- step: 1
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [local_id], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_4, N'2026-04-27T21:25:33.720', @superuser_id, N'LAB214', N'User Report Comment', N'NBS', N'NEDSS Base System', N'LabComment', @dbo_Observation_local_id_4, N'C_Result', N'D', N'2026-04-27T21:25:33.720', 4, N'T', 1);
-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq], [value_txt], [value_large_txt]) VALUES (@dbo_Act_act_uid_4, 1, N'', N'');
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_5, N'OBS', N'EVN');
-- dbo.Observation
-- step: 1
INSERT INTO [dbo].[Observation] ([observation_uid], [add_reason_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [electronic_ind], [local_id], [obs_domain_cd_st_1], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd]) VALUES (@dbo_Act_act_uid_5, N'ADD LAB REPORT', N'T-50130', N'Acid-Fast Stain', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'N', @dbo_Observation_local_id_5, N'Result', N'2026-04-27T21:25:33.723', 4, N'T', 1, N'11545-1', N'MICROSCOPIC OBSERVATION', N'LN');
-- dbo.Obs_value_coded
-- step: 1
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code], [code_system_cd], [display_name], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd], [alt_cd_system_desc_txt], [code_derived_ind]) VALUES (@dbo_Act_act_uid_5, N'N', N'NBS', N'negative', N'R-40759', N'SNOMED', N'SNM', N'SNOMED', N'Y');
-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq], [value_txt], [value_large_txt]) VALUES (@dbo_Act_act_uid_5, 1, N'Negative rapid for SARS-COV2', N'Negative rapid for SARS-COV2');
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_3, N'MAT');
-- dbo.Material
-- step: 1
INSERT INTO [dbo].[Material] ([material_uid], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid_3, N'Add', N'2026-04-27T21:25:33.927', @superuser_id, N'NOS', N'Nose (nasal passage)', N'2026-04-27T21:25:33.927', @superuser_id, @dbo_Material_local_id, N'ACTIVE', N'2026-04-27T21:25:33.927', N'A', N'2026-04-27T21:25:33.927', 1);
-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003007, @dbo_Act_act_uid, N'AUT', N'OBS', N'2026-04-27T21:25:33.687', @superuser_id, N'2026-04-27T21:25:33.687', @superuser_id, N'ACTIVE', N'2026-04-27T21:25:33.693', N'A', N'2026-04-27T21:25:33.693', N'ORG', N'Author');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003010, @dbo_Act_act_uid, N'ORD', N'OBS', N'2026-04-27T21:25:33.697', @superuser_id, N'2026-04-27T21:25:33.697', @superuser_id, N'ACTIVE', N'2026-04-27T21:25:33.697', N'A', N'2026-04-27T21:25:33.697', N'PSN', N'Orderer');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Act_act_uid, N'PATSBJ', N'OBS', N'2026-04-27T21:25:33.697', @superuser_id, N'2026-04-27T21:25:33.697', @superuser_id, N'ACTIVE', N'2026-04-27T21:25:33.697', N'A', N'2026-04-27T21:25:33.697', N'PSN', N'Patient subject');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [from_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_3, @dbo_Act_act_uid, N'SPC', N'OBS', N'2026-04-27T21:25:33.713', @superuser_id, N'2026-04-20T00:00:00', N'2026-04-27T21:25:33.713', @superuser_id, N'ACTIVE', N'A', N'2026-04-27T21:25:33.713', N'MAT', N'Specimen');
-- dbo.Act_relationship
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_2, N'COMP', N'2026-04-27T21:25:33.950', N'2026-04-27T21:25:33.950', N'ACTIVE', N'2026-04-27T21:25:33.950', N'OBS', N'A', N'2026-04-27T21:25:33.950', N'OBS', N'Has Component');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_3, @dbo_Act_act_uid_4, N'COMP', N'2026-04-27T21:25:33.957', N'2026-04-27T21:25:33.957', N'ACTIVE', N'2026-04-27T21:25:33.957', N'OBS', N'A', N'2026-04-27T21:25:33.957', N'OBS', N'Is Cause For');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_3, N'APND', N'2026-04-27T21:25:33.957', N'2026-04-27T21:25:33.957', N'ACTIVE', N'2026-04-27T21:25:33.957', N'OBS', N'A', N'2026-04-27T21:25:33.957', N'OBS', N'Appends');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_5, N'COMP', N'2026-04-27T21:25:33.957', N'2026-04-27T21:25:33.957', N'ACTIVE', N'2026-04-27T21:25:33.957', N'OBS', N'A', N'2026-04-27T21:25:33.957', N'OBS', N'Has Component');
-- dbo.Role
-- step: 1
INSERT INTO [dbo].[Role] ([subject_entity_uid], [cd], [role_seq], [add_time], [cd_desc_txt], [effective_from_time], [effective_to_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [scoping_class_cd], [scoping_entity_uid], [scoping_role_cd], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_3, N'NI', 0, N'2026-04-27T21:25:33.957', N'No Information Given', N'2026-04-27T21:25:33.957', N'2026-04-27T21:25:33.957', N'2026-04-27T21:25:33.957', @superuser_id, N'ACTIVE', N'2026-04-27T21:25:33.957', N'PSN', @dbo_Entity_entity_uid_2, N'PAT', N'A', N'2026-04-27T21:25:33.957', N'SPEC');
-- dbo.Person
-- step: 1
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-27T21:25:33.813', [record_status_time] = N'2026-04-27T21:25:33.813', [status_time] = N'2026-04-27T21:25:33.813', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Entity_locator_participation
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-27T21:25:33.817', [record_status_time] = N'2026-04-27T21:25:33.817', [status_time] = N'2026-04-27T21:25:33.817' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-27T21:25:33.817', [record_status_time] = N'2026-04-27T21:25:33.817', [status_time] = N'2026-04-27T21:25:33.817' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-27T21:25:33.817', [record_status_time] = N'2026-04-27T21:25:33.817', [status_time] = N'2026-04-27T21:25:33.817' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;
