USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 14217;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 14218;
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 14219;
DECLARE @dbo_Tele_locator_tele_locator_uid_2 bigint = 14220;
DECLARE @dbo_Entity_entity_uid_2 bigint = 14221;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 14222;
DECLARE @dbo_Tele_locator_tele_locator_uid_3 bigint = 14223;
DECLARE @dbo_Tele_locator_tele_locator_uid_4 bigint = 14224;
DECLARE @dbo_Act_act_uid bigint = 14225;
DECLARE @dbo_Act_act_uid_2 bigint = 14226;
DECLARE @dbo_Act_act_uid_3 bigint = 14227;
DECLARE @dbo_Act_act_uid_4 bigint = 14228;
DECLARE @dbo_Act_act_uid_5 bigint = 14229;
DECLARE @dbo_Entity_entity_uid_3 bigint = 14230;
DECLARE @dbo_Entity_entity_uid_4 bigint = 14231;
DECLARE @dbo_Postal_locator_postal_locator_uid_3 bigint = 14232;
DECLARE @dbo_Tele_locator_tele_locator_uid_5 bigint = 14233;
DECLARE @dbo_Act_act_uid_6 bigint = 14234;
DECLARE @dbo_Act_act_uid_7 bigint = 14235;
DECLARE @dbo_Act_act_uid_8 bigint = 14236;
DECLARE @dbo_Act_act_uid_9 bigint = 14237;
DECLARE @dbo_Act_act_uid_10 bigint = 14238;
DECLARE @dbo_Act_act_uid_11 bigint = 14239;
DECLARE @dbo_Act_act_uid_12 bigint = 14240;
DECLARE @dbo_Act_act_uid_13 bigint = 14241;
DECLARE @dbo_Act_act_uid_14 bigint = 14242;
DECLARE @dbo_Act_act_uid_15 bigint = 14243;
DECLARE @dbo_Bus_obj_df_sf_mdata_group_business_object_uid bigint = 14244;
DECLARE @dbo_Act_act_uid_16 bigint = 14245;
DECLARE @dbo_Act_act_uid_17 bigint = 14246;
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';
DECLARE @dbo_Observation_local_id nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid))) + N'GA01';
DECLARE @dbo_Observation_local_id_2 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_2))) + N'GA01';
DECLARE @dbo_Observation_local_id_3 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_3))) + N'GA01';
DECLARE @dbo_Observation_local_id_4 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_4))) + N'GA01';
DECLARE @dbo_Observation_local_id_5 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_5))) + N'GA01';
DECLARE @dbo_Material_local_id nvarchar(40) = N'MAT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_3))) + N'GA01';
DECLARE @dbo_Observation_local_id_6 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_6))) + N'GA01';
DECLARE @dbo_Observation_local_id_7 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_7))) + N'GA01';
DECLARE @dbo_Observation_local_id_8 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_8))) + N'GA01';
DECLARE @dbo_Observation_local_id_9 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_9))) + N'GA01';
DECLARE @dbo_Observation_local_id_10 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_10))) + N'GA01';
DECLARE @dbo_Observation_local_id_11 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_11))) + N'GA01';
DECLARE @dbo_Observation_local_id_12 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_12))) + N'GA01';
DECLARE @dbo_Observation_local_id_13 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_13))) + N'GA01';
DECLARE @dbo_Observation_local_id_14 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_14))) + N'GA01';
DECLARE @dbo_Public_health_case_local_id nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_15))) + N'GA01';
DECLARE @dbo_Treatment_local_id nvarchar(40) = N'TRT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_16))) + N'GA01';
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_Notification_local_id nvarchar(40) = N'NOT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_17))) + N'GA01';

-- STEP 2: CreateInvestigationSalmonella
-- dbo.Entity
-- step: 2
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_4, N'PSN');
-- dbo.Person
-- step: 2
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [age_reported], [age_reported_unit_cd], [birth_time], [birth_time_calc], [cd], [curr_sex_cd], [deceased_ind_cd], [last_chg_time], [last_chg_user_id], [local_id], [marital_status_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_4, N'2026-04-23T14:30:02.313', @superuser_id, N'41', N'Y', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'PAT', N'F', N'N', N'2026-04-23T14:30:02.313', @superuser_id, @dbo_Person_local_id, N'M', N'ACTIVE', N'2026-04-23T14:30:02.313', N'A', N'2026-04-23T14:30:02.313', N'Taylor', N'Swift_fake55ee', 1, N'2026-04-23T00:00:00', N'2026-04-23T00:00:00', N'2026-04-23T00:00:00', N'N', @dbo_Entity_entity_uid);
-- dbo.Person_name
-- step: 2
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [first_nm], [first_nm_sndx], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, 1, N'Add', N'2026-04-23T14:30:02.177', N'Taylor', N'T460', N'Swift_fake55ee', N'S130', N'L', N'ACTIVE', N'2026-04-23T14:30:02.177', N'A', N'2026-04-23T14:30:02.177', N'2026-04-23T00:00:00');
-- dbo.Person_race
-- step: 2
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [race_category_cd], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, N'2106-3', N'2106-3', N'ACTIVE', N'2026-04-23T00:00:00');
-- dbo.Postal_locator
-- step: 2
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [city_desc_txt], [cntry_cd], [cnty_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [street_addr2], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_3, N'2026-04-23T14:30:02.177', N'Atlanta', N'840', N'13121', N'ACTIVE', N'2026-04-23T14:30:02.177', N'13', N'1313 Pine Way', N'', N'30033');
-- dbo.Entity_locator_participation
-- step: 2
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Postal_locator_postal_locator_uid_3, N'H', N'PST', N'2026-04-23T14:30:02.313', @superuser_id, N'ACTIVE', N'2026-04-23T14:30:02.313', N'A', N'2026-04-23T14:30:02.313', N'H', 1, N'2026-04-23T00:00:00');
-- dbo.Tele_locator
-- step: 2
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_5, N'2026-04-23T14:30:02.177', N'', N'201-555-1212', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 2
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Tele_locator_tele_locator_uid_5, N'PH', N'TELE', N'2026-04-23T14:30:02.313', @superuser_id, N'ACTIVE', N'2026-04-23T14:30:02.313', N'A', N'2026-04-23T14:30:02.313', N'H', 1, N'2026-04-23T00:00:00');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_6, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_6, N'INV128', N'Was the patient hospitalized for this illness? ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_6, N'A', N'2026-04-23T14:30:02.177', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_6, N'Y');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_7, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_7, N'INV178', N'Is the patient pregnant? ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_7, N'A', N'2026-04-23T14:30:02.177', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_7, N'Y');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_8, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_8, N'INV179', N'Does the patient have pelvic inflammatory disease? ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_8, N'A', N'2026-04-23T14:30:02.177', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_8, N'N');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_9, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_9, N'INV134', N'Duration of Stay ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_9, N'A', N'2026-04-23T14:30:02.177', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_numeric
-- step: 2
INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid], [obs_value_numeric_seq], [numeric_value_1], [numeric_unit_cd], [numeric_scale_1]) VALUES (@dbo_Act_act_uid_9, 1, 9.0, N'D', 0);
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_10, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_10, N'INV148', N'Is this patient associated with a day care facility? ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_10, N'A', N'2026-04-23T14:30:02.177', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_10, N'Y');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_11, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_11, N'INV149', N'Is this patient a food handler? ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_11, N'A', N'2026-04-23T14:30:02.177', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_11, N'N');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_12, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_12, N'INV132', N'Admission Date ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_12, N'A', N'2026-04-23T14:30:02.177', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_date
-- step: 2
INSERT INTO [dbo].[Obs_value_date] ([observation_uid], [obs_value_date_seq], [from_time]) VALUES (@dbo_Act_act_uid_12, 1, N'2026-04-02T00:00:00');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_13, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_13, N'INV133', N'Discharge Date ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_13, N'A', N'2026-04-23T14:30:02.177', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_date
-- step: 2
INSERT INTO [dbo].[Obs_value_date] ([observation_uid], [obs_value_date_seq], [from_time]) VALUES (@dbo_Act_act_uid_13, 1, N'2026-04-08T00:00:00');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_14, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_system_cd], [group_level_cd], [local_id], [obs_domain_cd], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_14, N'INV_FORM_GEN', N'NBS', N'L1', @dbo_Observation_local_id_14, N'CLN', N'A', N'2026-04-23T14:30:02.177', 4, N'T', 1);
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_15, N'CASE', N'EVN');
-- dbo.Public_health_case
-- step: 2
INSERT INTO [dbo].[Public_health_case] ([public_health_case_uid], [activity_from_time], [add_time], [add_user_id], [case_class_cd], [case_type_cd], [cd], [cd_desc_txt], [detection_method_cd], [diagnosis_time], [disease_imported_cd], [effective_duration_amt], [effective_duration_unit_cd], [effective_from_time], [effective_to_time], [group_case_cnt], [investigation_status_cd], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [mmwr_week], [mmwr_year], [outbreak_ind], [outbreak_name], [outcome_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [prog_area_cd], [record_status_cd], [record_status_time], [rpt_form_cmplt_time], [rpt_source_cd], [rpt_to_county_time], [rpt_to_state_time], [status_cd], [transmission_mode_cd], [txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [contact_inv_txt]) VALUES (@dbo_Act_act_uid_15, N'2026-04-08T00:00:00', N'2026-04-23T14:30:02.400', @superuser_id, N'C', N'I', N'50265', N'Salmonellosis (excluding S. typhi/paratyphi)', N'PR', N'2026-04-03T00:00:00', N'IND', N'4', N'D', N'2026-03-20T00:00:00', N'2026-03-24T00:00:00', 1, N'O', N'130001', N'2026-04-23T14:30:02.400', @superuser_id, @dbo_Public_health_case_local_id, N'16', N'2026', N'Y', N'WHS', N'N', N'41', N'Y', N'GCD', N'OPEN', N'2026-04-23T14:30:02.400', N'2026-04-23T00:00:00', N'LA', N'2026-04-07T00:00:00', N'2026-04-08T00:00:00', N'A', N'F', N'', 1300100009, N'T', 1, N'');
-- dbo.Confirmation_method
-- step: 2
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_15, N'LD', N'2026-04-08T00:00:00');
-- dbo.Act_id
-- step: 2
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid_15, 1, N'', N'A', N'2026-04-23T14:30:02.417', N'STATE');
-- dbo.Act_relationship
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_6, N'InvFrmQ', N'2026-04-23T14:30:02.420', N'2026-04-23T14:30:02.420', N'ACTIVE', N'2026-04-23T14:30:02.420', N'OBS', N'A', N'2026-04-23T14:30:02.420', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_7, N'InvFrmQ', N'2026-04-23T14:30:02.423', N'2026-04-23T14:30:02.423', N'ACTIVE', N'2026-04-23T14:30:02.423', N'OBS', N'A', N'2026-04-23T14:30:02.423', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_8, N'InvFrmQ', N'2026-04-23T14:30:02.423', N'2026-04-23T14:30:02.423', N'ACTIVE', N'2026-04-23T14:30:02.423', N'OBS', N'A', N'2026-04-23T14:30:02.423', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_9, N'InvFrmQ', N'2026-04-23T14:30:02.423', N'2026-04-23T14:30:02.423', N'ACTIVE', N'2026-04-23T14:30:02.423', N'OBS', N'A', N'2026-04-23T14:30:02.423', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_10, N'InvFrmQ', N'2026-04-23T14:30:02.427', N'2026-04-23T14:30:02.427', N'ACTIVE', N'2026-04-23T14:30:02.427', N'OBS', N'A', N'2026-04-23T14:30:02.427', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_11, N'InvFrmQ', N'2026-04-23T14:30:02.427', N'2026-04-23T14:30:02.427', N'ACTIVE', N'2026-04-23T14:30:02.427', N'OBS', N'A', N'2026-04-23T14:30:02.427', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_12, N'InvFrmQ', N'2026-04-23T14:30:02.427', N'2026-04-23T14:30:02.427', N'ACTIVE', N'2026-04-23T14:30:02.427', N'OBS', N'A', N'2026-04-23T14:30:02.427', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_13, N'InvFrmQ', N'2026-04-23T14:30:02.427', N'2026-04-23T14:30:02.427', N'ACTIVE', N'2026-04-23T14:30:02.427', N'OBS', N'A', N'2026-04-23T14:30:02.427', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_15, @dbo_Act_act_uid_14, N'PHCInvForm', N'2026-04-23T14:30:02.427', N'2026-04-23T14:30:02.427', N'ACTIVE', N'2026-04-23T14:30:02.427', N'OBS', N'A', N'2026-04-23T14:30:02.427', N'CASE', N'PHC Investigation Form');
-- dbo.Participation
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [from_time], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Act_act_uid_15, N'SubjOfPHC', N'CASE', N'2026-03-20T00:00:00', N'ACTIVE', N'A', N'2026-04-23T14:30:02.177', N'PSN', N'Subject Of Public Health Case');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [from_time], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003013, @dbo_Act_act_uid_15, N'InvestgrOfPHC', N'CASE', N'2026-04-08T00:00:00', N'ACTIVE', N'A', N'2026-04-23T14:30:02.177', N'PSN', N'PHC Investigator');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003013, @dbo_Act_act_uid_15, N'PerAsReporterOfPHC', N'CASE', N'ACTIVE', N'A', N'2026-04-23T14:30:02.177', N'PSN', N'PHC Reporter');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003010, @dbo_Act_act_uid_15, N'PhysicianOfPHC', N'CASE', N'ACTIVE', N'A', N'2026-04-23T14:30:02.177', N'PSN', N'Physician of PHC');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003001, @dbo_Act_act_uid_15, N'OrgAsReporterOfPHC', N'CASE', N'ACTIVE', N'A', N'2026-04-23T14:30:02.177', N'ORG', N'Organization As Reporter Of PHC');
-- dbo.Bus_obj_df_sf_mdata_group
-- step: 2
INSERT INTO [dbo].[Bus_obj_df_sf_mdata_group] ([business_object_uid], [version_ctrl_nbr], [df_sf_metadata_group_uid]) VALUES (@dbo_Bus_obj_df_sf_mdata_group_business_object_uid, 1, (SELECT top(1) [df_sf_metadata_group_uid] FROM [dbo].[DF_sf_metadata_group] where [group_name]='|' order by [version_ctrl_nbr] desc));
-- dbo.Act_relationship
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_15, @dbo_Act_act_uid, N'LabReport', N'2026-04-23T14:30:02.557', N'2026-04-23T14:30:02.557', @superuser_id, N'ACTIVE', N'2026-04-23T14:30:02.557', N'OBS', N'A', N'2026-04-23T14:30:02.557', N'CASE');
-- dbo.Person
-- step: 2
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-23T14:30:02.297', [record_status_time] = N'2026-04-23T14:30:02.297', [status_time] = N'2026-04-23T14:30:02.297', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Entity_locator_participation
-- step: 2
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-23T14:30:02.297', [record_status_time] = N'2026-04-23T14:30:02.297', [status_time] = N'2026-04-23T14:30:02.297' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 2
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-23T14:30:02.297', [record_status_time] = N'2026-04-23T14:30:02.297', [status_time] = N'2026-04-23T14:30:02.297' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 2
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-23T14:30:02.297', [record_status_time] = N'2026-04-23T14:30:02.297', [status_time] = N'2026-04-23T14:30:02.297' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;
-- dbo.Observation
-- step: 2
UPDATE [dbo].[Observation] SET [last_chg_time] = N'2026-04-23T14:30:02.570', [record_status_cd] = N'PROCESSED', [record_status_time] = N'2026-04-23T14:30:02.570', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid;
-- dbo.PublicHealthCaseFact
-- step: 2
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [disease_imported_cd], [disease_imported_desc_txt], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorAssigneddate], [investigatorName], [investigatorPhone], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [onSetDate], [organizationName], [outcome_cd], [outbreak_ind], [outbreak_name], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [providerPhone], [providerName], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [rpt_source_cd], [rpt_source_desc_txt], [rpt_to_county_time], [rpt_to_state_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [outcome_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [outbreak_name_desc], [confirmation_method_desc_txt], [LASTUPDATE], [HSPTL_ADMISSION_DT], [HSPTL_DISCHARGE_DT], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_15, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-08T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'PR', N'Provider reported', N'2026-04-03T00:00:00', N'IND', N'Indigenous, within jurisdiction', N'PST', N'2026-03-20T00:00:00', N'O', 1.0, N'O', N'2026-04-08T00:00:00', N'Jones, Indiana', N'404-712-5227', N'130001', N'M', N'Married', N'2026-04-23T14:30:12.623', 16, 2026, N'2026-03-20T00:00:00', N'Piedmont Hospital', N'N', N'Y', N'WHS', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-04-23T14:30:02.400', N'50265', N'Salmonellosis (excluding S. typhi/paratyphi)', N'Salmonellosis (excluding S. typhi/paratyphi)', N'GCD', N'404-851-8000', N'Keable, Kristi', N'2026-04-23T14:30:02.177', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Jones, Indiana', N'404-712-5227', N'2026-04-23T00:00:00', N'LA', N'Laboratory', N'2026-04-07T00:00:00', N'2026-04-08T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake55ee, Taylor', N'Fulton County', N'2026-04-08T00:00:00', 1300100009, N'2026-04-07T00:00:00', 10009406, @dbo_Person_local_id, N'2026-04-23T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Open', N'No', N'Years', N'GCD', N'Waffle House - Syrup', N' Laboratory confirmed', N'2026-04-23T14:30:02.400', N'2026-04-02T00:00:00', N'2026-04-08T00:00:00', N'Y');
-- dbo.SubjectRaceInfo
-- step: 2
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_15, N'2106-3', N'2106-3');
