USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 12345544332211;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 12345544332212;
DECLARE @dbo_Entity_entity_uid_2 bigint = 12345544332213;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 12345544332214;
DECLARE @dbo_Act_act_uid bigint = 12345544332215;
DECLARE @dbo_Act_act_uid_2 bigint = 12345544332216;
DECLARE @dbo_Act_act_uid_3 bigint = 12345544332217;
DECLARE @dbo_Act_act_uid_4 bigint = 12345544332218;
DECLARE @dbo_Act_act_uid_5 bigint = 12345544332219;
DECLARE @dbo_Act_act_uid_6 bigint = 12345544332220;
DECLARE @dbo_Act_act_uid_7 bigint = 12345544332221;
DECLARE @dbo_Act_act_uid_8 bigint = 12345544332222;
DECLARE @dbo_Act_act_uid_9 bigint = 12345544332223;
DECLARE @dbo_Act_act_uid_10 bigint = 12345544332224;
DECLARE @dbo_Act_act_uid_11 bigint = 12345544332225;
DECLARE @dbo_Act_act_uid_12 bigint = 12345544332226;
DECLARE @dbo_Act_act_uid_13 bigint = 12345544332227;
DECLARE @dbo_Act_act_uid_14 bigint = 12345544332228;
DECLARE @dbo_Act_act_uid_15 bigint = 12345544332229;
DECLARE @dbo_Act_act_uid_16 bigint = 12345544332230;
DECLARE @dbo_Act_act_uid_17 bigint = 12345544332231;
DECLARE @dbo_Act_act_uid_18 bigint = 12345544332232;
DECLARE @dbo_Act_act_uid_19 bigint = 12345544332233;
DECLARE @dbo_Act_act_uid_20 bigint = 12345544332234;
DECLARE @dbo_Act_act_uid_21 bigint = 12345544332235;
DECLARE @dbo_Act_act_uid_22 bigint = 12345544332236;
DECLARE @dbo_Act_act_uid_23 bigint = 12345544332237;
DECLARE @dbo_Act_act_uid_24 bigint = 12345544332238;
DECLARE @dbo_Act_act_uid_25 bigint = 12345544332239;
DECLARE @dbo_Act_act_uid_26 bigint = 12345544332240;
DECLARE @dbo_Act_act_uid_27 bigint = 12345544332241;
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';
DECLARE @dbo_Observation_local_id nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid))) + N'GA01';
DECLARE @dbo_Observation_local_id_2 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_2))) + N'GA01';
DECLARE @dbo_Observation_local_id_3 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_3))) + N'GA01';
DECLARE @dbo_Observation_local_id_4 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_4))) + N'GA01';
DECLARE @dbo_Observation_local_id_5 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_5))) + N'GA01';
DECLARE @dbo_Observation_local_id_6 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_6))) + N'GA01';
DECLARE @dbo_Observation_local_id_7 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_7))) + N'GA01';
DECLARE @dbo_Observation_local_id_8 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_8))) + N'GA01';
DECLARE @dbo_Observation_local_id_9 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_9))) + N'GA01';
DECLARE @dbo_Observation_local_id_10 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_10))) + N'GA01';
DECLARE @dbo_Observation_local_id_11 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_11))) + N'GA01';
DECLARE @dbo_Observation_local_id_12 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_12))) + N'GA01';
DECLARE @dbo_Observation_local_id_13 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_13))) + N'GA01';
DECLARE @dbo_Observation_local_id_14 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_14))) + N'GA01';
DECLARE @dbo_Observation_local_id_15 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_15))) + N'GA01';
DECLARE @dbo_Observation_local_id_16 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_16))) + N'GA01';
DECLARE @dbo_Observation_local_id_17 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_17))) + N'GA01';
DECLARE @dbo_Observation_local_id_18 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_18))) + N'GA01';
DECLARE @dbo_Observation_local_id_19 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_19))) + N'GA01';
DECLARE @dbo_Observation_local_id_20 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_20))) + N'GA01';
DECLARE @dbo_Observation_local_id_21 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_21))) + N'GA01';
DECLARE @dbo_Observation_local_id_22 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_22))) + N'GA01';
DECLARE @dbo_Observation_local_id_23 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_23))) + N'GA01';
DECLARE @dbo_Observation_local_id_24 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_24))) + N'GA01';
DECLARE @dbo_Observation_local_id_25 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_25))) + N'GA01';
DECLARE @dbo_Observation_local_id_26 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_26))) + N'GA01';
DECLARE @dbo_Public_health_case_local_id nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_27))) + N'GA01';

-- STEP 2: Create a BMIRD investigation for the Obi Wan Kenobi patient
-- dbo.Entity
-- step: 2
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_2, N'PSN');
-- dbo.Person
-- step: 2
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [age_reported], [age_reported_unit_cd], [birth_time], [birth_time_calc], [cd], [curr_sex_cd], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_2, N'2026-05-20T17:57:03.690', @superuser_id, N'48', N'Y', N'1978-01-18T00:00:00', N'1978-01-18T00:00:00', N'PAT', N'M', N'2026-05-20T17:57:03.690', @superuser_id, @dbo_Person_local_id, N'ACTIVE', N'2026-05-20T17:57:03.690', N'A', N'2026-05-20T17:57:03.690', N'Obi Wan', N'Kenobi', 1, N'2026-05-20T00:00:00', N'N', @dbo_Entity_entity_uid);
-- dbo.Person_name
-- step: 2
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [first_nm], [first_nm_sndx], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, 1, N'Add', N'2026-05-20T17:57:03.503', N'Obi Wan', N'O100', N'Kenobi', N'K510', N'L', N'ACTIVE', N'2026-05-20T17:57:03.503', N'A', N'2026-05-20T17:57:03.503', N'2026-05-20T00:00:00');
-- dbo.Postal_locator
-- step: 2
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [cntry_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [street_addr2]) VALUES (@dbo_Postal_locator_postal_locator_uid_2, N'2026-05-20T17:57:03.503', N'840', N'ACTIVE', N'2026-05-20T17:57:03.503', N'13', N'', N'');
-- dbo.Entity_locator_participation
-- step: 2
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Postal_locator_postal_locator_uid_2, N'H', N'PST', N'2026-05-20T17:57:03.690', @superuser_id, N'ACTIVE', N'2026-05-20T17:57:03.690', N'A', N'2026-05-20T17:57:03.690', N'H', 1, N'2026-05-20T00:00:00');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid, N'INV128', N'Was the patient hospitalized for this illness? ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id, N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid, N'N');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_2, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_2, N'BMD118', N'Types of infection caused by organism  ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_2, N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_2, N'CELL');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_3, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_3, N'BMD120', N'Bacterial species isolated from any normally sterile site ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_3, N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_3, N'11723');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_4, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_4, N'BMD122', N'Sterile sites from which organism isolated ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_4, N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_4, N'BONE');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_5, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_5, N'BMD125', N'Nonsterile sites from which organism isolated ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_5, N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_5, N'MIDDLEAR');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_6, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_6, N'BMD126', N'Did the patient have any underlying conditions? ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_6, N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_6, N'N');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_7, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_7, N'BMD113', N'Is the patient < 1 month of age ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_7, N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_7, N'N');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_8, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_8, N'BMD105', N'If < 6 years of age is the patient in daycare?  (Daycare is defined as a supervised group of 2 or more unrelated children for > 4 hours/week)', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_8, N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_8, N'UNK');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_9, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_9, N'BMD107', N'Was the patient a resident of a nursing home or other chronic care facility at the time of first positive culture?', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_9, N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_9, N'N');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_10, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_10, N'BMD320', N'', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_10, N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_numeric
-- step: 2
INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid], [obs_value_numeric_seq], [numeric_value_1], [numeric_unit_cd], [numeric_scale_1]) VALUES (@dbo_Act_act_uid_10, 1, 167.0, N'lbs', 0);
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_11, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_11, N'BMD321', N' ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_11, N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_numeric
-- step: 2
INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid], [obs_value_numeric_seq], [numeric_value_1], [numeric_unit_cd], [numeric_scale_1]) VALUES (@dbo_Act_act_uid_11, 1, 5.0, N'ozs', 0);
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_12, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_12, N'BMD323', N'Height ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_12, N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_numeric
-- step: 2
INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid], [obs_value_numeric_seq], [numeric_value_1], [numeric_unit_cd], [numeric_scale_1]) VALUES (@dbo_Act_act_uid_12, 1, 5.0, N'ft', 0);
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_13, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_13, N'BMD324', N'', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_13, N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_numeric
-- step: 2
INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid], [obs_value_numeric_seq], [numeric_value_1], [numeric_unit_cd], [numeric_scale_1]) VALUES (@dbo_Act_act_uid_13, 1, 9.0, N'in', 0);
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_14, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_system_cd], [group_level_cd], [local_id], [obs_domain_cd], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_14, N'INV_FORM_BMDSP', N'NBS', N'L1', @dbo_Observation_local_id_14, N'CLN', N'A', N'2026-05-20T17:57:03.503', 4, N'T', 1);
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_15, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_15, N'BMD136', N'Oxacillin Zone Size ', N'NBS', N'NEDSS Base System', N'supplemental', @dbo_Observation_local_id_15, N'ACTIVE', N'2026-05-20T17:57:03.503', N'D', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_numeric
-- step: 2
INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid], [obs_value_numeric_seq], [numeric_value_1], [numeric_scale_1]) VALUES (@dbo_Act_act_uid_15, 1, 2.0, 0);
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_16, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_16, N'BMD137', N'Interpretation ', N'NBS', N'NEDSS Base System', N'supplemental', @dbo_Observation_local_id_16, N'ACTIVE', N'2026-05-20T17:57:03.503', N'D', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_16, N'R');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_17, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_17, N'BMD140', N'Does the patient have persistent disease as defined by positive sterile site cultures 2-7 days after the first positive culture? ', N'NBS', N'NEDSS Base System', N'supplemental', @dbo_Observation_local_id_17, N'ACTIVE', N'2026-05-20T17:57:03.503', N'D', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_17, N'N');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_18, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_18, N'BMD138', N'Has patient received 23-valent pneumococcal POLYSACCHARIDE vaccine? ', N'NBS', N'NEDSS Base System', N'supplemental', @dbo_Observation_local_id_18, N'ACTIVE', N'2026-05-20T17:57:03.503', N'D', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_18, N'N');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_19, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_19, N'BMD139', N'If < 15 years of age, did the patient receive pneumococcal CONJUGATE vaccine? ', N'NBS', N'NEDSS Base System', N'supplemental', @dbo_Observation_local_id_19, N'ACTIVE', N'2026-05-20T17:57:03.503', N'D', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_19, N'N');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_20, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_20, N'BMD131', N'What was the serotype? ', N'NBS', N'NEDSS Base System', N'supplemental', @dbo_Observation_local_id_20, N'ACTIVE', N'2026-05-20T17:57:03.503', N'D', N'2026-05-20T17:57:03.503', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_20, N'10A');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_21, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_system_cd], [ctrl_cd_display_form], [group_level_cd], [local_id], [obs_domain_cd], [record_status_cd], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_21, N'ItemToRow', N'NBS', N'AntibioticContainRow', N'L2', @dbo_Observation_local_id_21, N'CLN', N'ACTIVE', N'A', N'2026-05-20T17:57:03.507', 4, N'T', 1);
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_22, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_22, N'BMD212', N'Antimicrobial Agent ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_22, N'ACTIVE', N'2026-05-20T17:57:03.507', N'D', N'2026-05-20T17:57:03.507', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_22, N'C0002645');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_23, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_23, N'BMD213', N'Susceptibility Method ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_23, N'ACTIVE', N'2026-05-20T17:57:03.507', N'D', N'2026-05-20T17:57:03.507', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_23, N'A');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_24, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_24, N'BMD214', N'S/I/R/U Result ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_24, N'ACTIVE', N'2026-05-20T17:57:03.507', N'D', N'2026-05-20T17:57:03.507', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_24, N'I');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_25, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_25, N'BMD215', N'Sign ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_25, N'ACTIVE', N'2026-05-20T17:57:03.507', N'D', N'2026-05-20T17:57:03.507', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_coded
-- step: 2
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_25, N'LT');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_26, N'OBS', N'EVN');
-- dbo.Observation
-- step: 2
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [cd_version]) VALUES (@dbo_Act_act_uid_26, N'BMD216', N'MIC Value ', N'NBS', N'NEDSS Base System', @dbo_Observation_local_id_26, N'ACTIVE', N'2026-05-20T17:57:03.507', N'D', N'2026-05-20T17:57:03.507', 4, N'T', 1, N'1.0');
-- dbo.Obs_value_numeric
-- step: 2
INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid], [obs_value_numeric_seq], [numeric_value_1], [numeric_scale_1]) VALUES (@dbo_Act_act_uid_26, 1, 3.0, 0);
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_27, N'CASE', N'EVN');
-- dbo.Public_health_case
-- step: 2
INSERT INTO [dbo].[Public_health_case] ([public_health_case_uid], [activity_from_time], [add_time], [add_user_id], [case_class_cd], [case_type_cd], [cd], [cd_desc_txt], [disease_imported_cd], [effective_from_time], [effective_to_time], [group_case_cnt], [investigation_status_cd], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [mmwr_week], [mmwr_year], [outbreak_ind], [outbreak_name], [outcome_cd], [prog_area_cd], [record_status_cd], [record_status_time], [rpt_form_cmplt_time], [rpt_source_cd], [rpt_to_county_time], [rpt_to_state_time], [status_cd], [txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [contact_inv_txt]) VALUES (@dbo_Act_act_uid_27, N'2026-05-17T00:00:00', N'2026-05-20T17:57:03.777', @superuser_id, N'P', N'I', N'11723', N'Streptococcus pneumoniae, invasive disease (IPD)', N'IND', N'2026-05-16T00:00:00', N'2026-05-20T00:00:00', 1, N'O', N'130006', N'2026-05-20T17:57:03.777', @superuser_id, @dbo_Public_health_case_local_id, N'20', N'2026', N'N', N'', N'N', N'BMIRD', N'OPEN', N'2026-05-20T17:57:03.777', N'2026-05-17T00:00:00', N'RE', N'2026-05-18T00:00:00', N'2026-05-20T00:00:00', N'A', N'', 1300600008, N'T', 1, N'');
-- dbo.Confirmation_method
-- step: 2
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd]) VALUES (@dbo_Act_act_uid_27, N'CD');
-- dbo.Act_id
-- step: 2
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid_27, 1, N'OBI1K', N'A', N'2026-05-20T17:57:03.790', N'STATE');
-- step: 2
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_cd], [assigning_authority_desc_txt], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid_27, 2, N'ABCS', N'Active Bacterial Core Surveillance', N'', N'A', N'2026-05-20T17:57:03.797', N'STATE');
-- dbo.Act_relationship
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid, N'InvFrmQ', N'2026-05-20T17:57:03.797', N'2026-05-20T17:57:03.797', N'ACTIVE', N'2026-05-20T17:57:03.797', N'OBS', N'A', N'2026-05-20T17:57:03.797', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_2, N'InvFrmQ', N'2026-05-20T17:57:03.803', N'2026-05-20T17:57:03.803', N'ACTIVE', N'2026-05-20T17:57:03.803', N'OBS', N'A', N'2026-05-20T17:57:03.803', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_3, N'InvFrmQ', N'2026-05-20T17:57:03.803', N'2026-05-20T17:57:03.803', N'ACTIVE', N'2026-05-20T17:57:03.803', N'OBS', N'A', N'2026-05-20T17:57:03.803', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_4, N'InvFrmQ', N'2026-05-20T17:57:03.803', N'2026-05-20T17:57:03.803', N'ACTIVE', N'2026-05-20T17:57:03.803', N'OBS', N'A', N'2026-05-20T17:57:03.803', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_5, N'InvFrmQ', N'2026-05-20T17:57:03.803', N'2026-05-20T17:57:03.803', N'ACTIVE', N'2026-05-20T17:57:03.803', N'OBS', N'A', N'2026-05-20T17:57:03.803', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_6, N'InvFrmQ', N'2026-05-20T17:57:03.803', N'2026-05-20T17:57:03.803', N'ACTIVE', N'2026-05-20T17:57:03.803', N'OBS', N'A', N'2026-05-20T17:57:03.803', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_7, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.807', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_8, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.807', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_9, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.807', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_10, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.807', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_11, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.807', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_12, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.807', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_13, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.807', N'OBS', N'Investigation Form Question');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_27, @dbo_Act_act_uid_14, N'PHCInvForm', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.807', N'CASE', N'PHC Investigation Form');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_15, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.503', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_16, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.503', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_17, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.503', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_18, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.503', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_19, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.503', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_20, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.503', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_21, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.507', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_21, @dbo_Act_act_uid_22, N'ItemToRow', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.507', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_22, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.507', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_21, @dbo_Act_act_uid_23, N'ItemToRow', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.507', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_23, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.507', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_21, @dbo_Act_act_uid_24, N'ItemToRow', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.507', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_24, N'InvFrmQ', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.507', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_21, @dbo_Act_act_uid_25, N'ItemToRow', N'2026-05-20T17:57:03.807', N'2026-05-20T17:57:03.807', N'ACTIVE', N'2026-05-20T17:57:03.807', N'OBS', N'A', N'2026-05-20T17:57:03.507', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_25, N'InvFrmQ', N'2026-05-20T17:57:03.810', N'2026-05-20T17:57:03.810', N'ACTIVE', N'2026-05-20T17:57:03.810', N'OBS', N'A', N'2026-05-20T17:57:03.507', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_21, @dbo_Act_act_uid_26, N'ItemToRow', N'2026-05-20T17:57:03.810', N'2026-05-20T17:57:03.810', N'ACTIVE', N'2026-05-20T17:57:03.810', N'OBS', N'A', N'2026-05-20T17:57:03.507', N'OBS');
-- step: 2
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_14, @dbo_Act_act_uid_26, N'InvFrmQ', N'2026-05-20T17:57:03.810', N'2026-05-20T17:57:03.810', N'ACTIVE', N'2026-05-20T17:57:03.810', N'OBS', N'A', N'2026-05-20T17:57:03.507', N'OBS');
-- dbo.Participation
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [from_time], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Act_act_uid_27, N'SubjOfPHC', N'CASE', N'2026-05-16T00:00:00', N'ACTIVE', N'A', N'2026-05-20T17:57:03.503', N'PSN', N'Subject Of Public Health Case');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [from_time], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003010, @dbo_Act_act_uid_27, N'InvestgrOfPHC', N'CASE', N'2026-05-20T00:00:00', N'ACTIVE', N'A', N'2026-05-20T17:57:03.503', N'PSN', N'PHC Investigator');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003010, @dbo_Act_act_uid_27, N'PerAsReporterOfPHC', N'CASE', N'ACTIVE', N'A', N'2026-05-20T17:57:03.503', N'PSN', N'PHC Reporter');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10007003, @dbo_Act_act_uid_27, N'PhysicianOfPHC', N'CASE', N'ACTIVE', N'A', N'2026-05-20T17:57:03.503', N'PSN', N'Physician of PHC');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003007, @dbo_Act_act_uid_27, N'OrgAsReporterOfPHC', N'CASE', N'ACTIVE', N'A', N'2026-05-20T17:57:03.503', N'ORG', N'Organization As Reporter Of PHC');
-- dbo.Person
-- step: 2
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-20T17:57:03.677', [record_status_time] = N'2026-05-20T17:57:03.677', [status_time] = N'2026-05-20T17:57:03.677', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Entity_locator_participation
-- step: 2
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-20T17:57:03.677', [record_status_time] = N'2026-05-20T17:57:03.677', [status_time] = N'2026-05-20T17:57:03.677' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- dbo.PublicHealthCaseFact
-- step: 2
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [confirmation_method_cd], [cntry_cd], [curr_sex_cd], [disease_imported_cd], [disease_imported_desc_txt], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorAssigneddate], [investigatorName], [investigatorPhone], [jurisdiction_cd], [mart_record_creation_time], [mmwr_week], [mmwr_year], [onSetDate], [organizationName], [outcome_cd], [outbreak_ind], [PAR_type_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [providerName], [PST_record_status_time], [PST_record_status_cd], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [rpt_source_cd], [rpt_source_desc_txt], [rpt_to_county_time], [rpt_to_state_time], [shared_ind], [state], [state_cd], [status_cd], [ELP_use_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [state_case_id], [LOCAL_ID], [age_reported_unit_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [outcome_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_27, N'Y', 48, N'1978-01-18T00:00:00', N'1978-01-18T00:00:00', N'P', N'I', N'CD', N'840', N'M', N'IND', N'Indigenous, within jurisdiction', N'PST', N'2026-05-16T00:00:00', N'O', 1.0, N'O', N'2026-05-20T00:00:00', N'Keable, Kristi', N'404-851-8000', N'130006', N'2026-05-20T17:57:11.040', 20, 2026, N'2026-05-16T00:00:00', N'CHOA - Scottish Rite', N'N', N'N', N'SubjOfPHC', @dbo_Postal_locator_postal_locator_uid_2, N'PAT', @dbo_Entity_entity_uid_2, N'2026-05-20T17:57:03.777', N'11723', N'Streptococcus pneumoniae, invasive disease (IPD)', N'Streptococcus pneumoniae, invasive disease (IPD)', N'BMIRD', N'LocalUser, Dekalb', N'2026-05-20T17:57:03.503', N'ACTIVE', N'OPEN', N'Keable, Kristi', N'404-851-8000', N'2026-05-17T00:00:00', N'RE', N'Data Registries', N'2026-05-18T00:00:00', N'2026-05-20T00:00:00', N'T', N'Georgia', N'13', N'A', N'H', N'Kenobi, Obi Wan', N'Clayton County', N'2026-05-17T00:00:00', 1300600008, N'2026-05-18T00:00:00', 10009317, @dbo_Person_local_id, N'2026-05-20T00:00:00', N'OBI1K', @dbo_Public_health_case_local_id, N'Years', N'Probable', N'UNITED STATES', N'Male', N'Open', N'No', N'BMIRD', N' Clinical diagnosis (non-laboratory confirmed)', N'2026-05-20T17:57:03.777', N'N');