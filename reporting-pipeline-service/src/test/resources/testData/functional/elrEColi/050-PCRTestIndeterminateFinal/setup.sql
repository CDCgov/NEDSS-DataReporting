USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;
DECLARE @elruser_id bigint = 10000015;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 1000008000;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 1000008001;
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 1000008002;
DECLARE @dbo_Entity_entity_uid_2 bigint = 1000008003;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 1000008004;
DECLARE @dbo_Tele_locator_tele_locator_uid_2 bigint = 1000008005;
DECLARE @dbo_Entity_entity_uid_3 bigint = 1000008006;
DECLARE @dbo_Postal_locator_postal_locator_uid_3 bigint = 1000008007;
DECLARE @dbo_Entity_entity_uid_4 bigint = 1000008008;
DECLARE @dbo_Entity_entity_uid_5 bigint = 1000008009;
DECLARE @dbo_Postal_locator_postal_locator_uid_4 bigint = 1000008010;
DECLARE @dbo_Tele_locator_tele_locator_uid_3 bigint = 1000008011;
DECLARE @dbo_Act_act_uid bigint = 1000008012;
DECLARE @dbo_Act_act_uid_2 bigint = 1000008013;
DECLARE @dbo_Entity_entity_uid_6 bigint = 1000008014;
DECLARE @dbo_Entity_entity_uid_7 bigint = 1000008015;
DECLARE @dbo_Postal_locator_postal_locator_uid_5 bigint = 1000008016;
DECLARE @dbo_Tele_locator_tele_locator_uid_4 bigint = 1000008017;
DECLARE @dbo_Act_act_uid_3 bigint = 1000008018;
DECLARE @dbo_Act_act_uid_4 bigint = 1000008019;
DECLARE @dbo_DF_sf_metadata_group_df_sf_metadata_group_uid bigint = 1000008020;
DECLARE @dbo_Bus_obj_df_sf_mdata_group_business_object_uid bigint = 1000008021;
DECLARE @dbo_Tele_locator_tele_locator_uid_5 bigint = 1000008022;
DECLARE @dbo_Act_act_uid_5 bigint = 1000008023;
DECLARE @dbo_Entity_entity_uid_8 bigint = 1000008024;
DECLARE @dbo_Postal_locator_postal_locator_uid_6 bigint = 1000008025;
DECLARE @dbo_Tele_locator_tele_locator_uid_6 bigint = 1000008026;
DECLARE @dbo_Entity_entity_uid_9 bigint = 1000008027;
DECLARE @dbo_Postal_locator_postal_locator_uid_7 bigint = 1000008028;
DECLARE @dbo_Tele_locator_tele_locator_uid_7 bigint = 1000008029;
DECLARE @dbo_Act_act_uid_6 bigint = 1000008030;
DECLARE @dbo_Act_act_uid_7 bigint = 1000008031;
DECLARE @dbo_Entity_entity_uid_10 bigint = 1000008032;
DECLARE @dbo_Entity_entity_uid_11 bigint = 1000008033;
DECLARE @dbo_Postal_locator_postal_locator_uid_8 bigint = 1000008034;
DECLARE @dbo_Tele_locator_tele_locator_uid_8 bigint = 1000008035;
DECLARE @dbo_Act_act_uid_8 bigint = 1000008036;
DECLARE @dbo_Act_act_uid_9 bigint = 1000008037;
DECLARE @dbo_Act_act_uid_10 bigint = 1000008038;
DECLARE @dbo_Entity_entity_uid_12 bigint = 1000008039;
DECLARE @dbo_Entity_entity_uid_13 bigint = 1000008040;
DECLARE @dbo_Postal_locator_postal_locator_uid_9 bigint = 1000008041;
DECLARE @dbo_Tele_locator_tele_locator_uid_9 bigint = 1000008042;
DECLARE @dbo_Act_act_uid_11 bigint = 1000008043;
DECLARE @dbo_Act_act_uid_12 bigint = 1000008044;
DECLARE @dbo_Entity_entity_uid_14 bigint = 1000008045;
DECLARE @dbo_Act_act_uid_13 bigint = 1000008046;
DECLARE @dbo_Entity_entity_uid_15 bigint = 1000008047;
DECLARE @dbo_Postal_locator_postal_locator_uid_10 bigint = 1000008048;
DECLARE @dbo_Tele_locator_tele_locator_uid_10 bigint = 1000008049;
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';
DECLARE @dbo_Person_local_id_2 nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_3))) + N'GA01';
DECLARE @dbo_Organization_local_id nvarchar(40) = N'ORG' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_4))) + N'GA01';
DECLARE @dbo_Organization_local_id_2 nvarchar(40) = N'ORG' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_5))) + N'GA01';
DECLARE @dbo_Observation_local_id nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid))) + N'GA01';
DECLARE @dbo_Observation_local_id_2 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_2))) + N'GA01';
DECLARE @dbo_Material_local_id nvarchar(40) = N'MAT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_6))) + N'GA01';
DECLARE @dbo_EDX_Document_EDX_Document_uid bigint;
DECLARE @dbo_EDX_Document_EDX_Document_uid_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_log_edx_activity_log_uid bigint;
DECLARE @dbo_EDX_activity_log_edx_activity_log_uid_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_2 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_3 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_4 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_4_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_5 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_5_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_6 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_6_output TABLE ([value] bigint);
DECLARE @dbo_Observation_local_id_3 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_3))) + N'GA01';
DECLARE @dbo_Public_health_case_local_id nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_4))) + N'GA01';
DECLARE @dbo_Observation_local_id_4 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_5))) + N'GA01';
DECLARE @dbo_Material_local_id_2 nvarchar(40) = N'MAT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_8))) + N'GA01';
DECLARE @dbo_EDX_Document_EDX_Document_uid_2 bigint;
DECLARE @dbo_EDX_Document_EDX_Document_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_log_edx_activity_log_uid_2 bigint;
DECLARE @dbo_EDX_activity_log_edx_activity_log_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_7 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_7_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_8 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_8_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_9 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_9_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_10 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_10_output TABLE ([value] bigint);
DECLARE @dbo_Observation_local_id_5 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_6))) + N'GA01';
DECLARE @dbo_Observation_local_id_6 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_7))) + N'GA01';
DECLARE @dbo_Material_local_id_3 nvarchar(40) = N'MAT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_10))) + N'GA01';
DECLARE @dbo_EDX_Document_EDX_Document_uid_3 bigint;
DECLARE @dbo_EDX_Document_EDX_Document_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_log_edx_activity_log_uid_3 bigint;
DECLARE @dbo_EDX_activity_log_edx_activity_log_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_11 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_11_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_12 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_12_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_13 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_13_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_14 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_14_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_15 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_15_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_16 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_16_output TABLE ([value] bigint);
DECLARE @dbo_Observation_local_id_7 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_8))) + N'GA01';
DECLARE @dbo_Observation_local_id_8 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_9))) + N'GA01';
DECLARE @dbo_Observation_local_id_9 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_10))) + N'GA01';
DECLARE @dbo_Material_local_id_4 nvarchar(40) = N'MAT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_12))) + N'GA01';
DECLARE @dbo_EDX_Document_EDX_Document_uid_4 bigint;
DECLARE @dbo_EDX_Document_EDX_Document_uid_4_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_log_edx_activity_log_uid_4 bigint;
DECLARE @dbo_EDX_activity_log_edx_activity_log_uid_4_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_17 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_17_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_18 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_18_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_19 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_19_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_20 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_20_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_21 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_21_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_22 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_22_output TABLE ([value] bigint);
DECLARE @dbo_Observation_local_id_10 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_11))) + N'GA01';
DECLARE @dbo_Observation_local_id_11 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_12))) + N'GA01';
DECLARE @dbo_Material_local_id_5 nvarchar(40) = N'MAT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_14))) + N'GA01';
DECLARE @dbo_EDX_Document_EDX_Document_uid_5 bigint;
DECLARE @dbo_EDX_Document_EDX_Document_uid_5_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_log_edx_activity_log_uid_5 bigint;
DECLARE @dbo_EDX_activity_log_edx_activity_log_uid_5_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_23 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_23_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_24 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_24_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_25 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_25_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_26 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_26_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_27 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_27_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_28 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_28_output TABLE ([value] bigint);
DECLARE @dbo_Observation_local_id_12 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_13))) + N'GA01';
DECLARE @dbo_Material_local_id_6 nvarchar(40) = N'MAT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_15))) + N'GA01';
DECLARE @dbo_EDX_Document_EDX_Document_uid_6 bigint;
DECLARE @dbo_EDX_Document_EDX_Document_uid_6_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_log_edx_activity_log_uid_6 bigint;
DECLARE @dbo_EDX_activity_log_edx_activity_log_uid_6_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_29 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_29_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_30 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_30_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_31 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_31_output TABLE ([value] bigint);
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_32 bigint;
DECLARE @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_32_output TABLE ([value] bigint);

-- STEP 5: ELR comes in as a PCR test and the result is indeterminate with the status as final.
-- dbo.Entity
-- step: 5
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_13, N'PSN');
-- dbo.Person
-- step: 5
INSERT INTO [dbo].[Person] ([person_uid], [add_reason_cd], [add_time], [add_user_id], [birth_time], [birth_time_calc], [cd], [cd_desc_txt], [curr_sex_cd], [ethnic_group_ind], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_ethnicity], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_13, N'because', N'2026-05-26T13:51:43.130', @elruser_id, N'1990-01-01T00:00:00', N'1990-01-01T00:00:00', N'PAT', N'Observation Subject', N'F', N'N', N'2026-05-26T13:51:43.130', @elruser_id, @dbo_Person_local_id, N'ACTIVE', N'2026-05-26T13:51:43.130', N'A', N'2026-05-26T13:51:43.130', N'Taylor', N'Swift', 1, N'2026-05-26T13:51:43.047', N'2026-05-26T13:51:43.047', N'2026-05-26T13:51:43.047', N'2026-05-26T13:51:43.047', N'2026-05-26T00:00:00', N'Y', @dbo_Entity_entity_uid);
-- dbo.Person_name
-- step: 5
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_13, 1, N'Add', N'2026-05-26T13:51:43.047', @elruser_id, N'Taylor', N'T460', N'2026-05-26T13:51:43.047', @elruser_id, N'Swift', N'S130', N'L', N'ACTIVE', N'A', N'2026-05-26T13:51:43.133', N'2026-05-26T13:51:43.047');
-- dbo.Person_race
-- step: 5
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [add_user_id], [race_category_cd], [race_desc_txt], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid_13, N'2106-3', N'2026-05-26T13:51:43.057', @elruser_id, N'2106-3', N'White', N'ACTIVE', N'2026-05-26T13:51:43.047');
-- dbo.Person_ethnic_group
-- step: 5
INSERT INTO [dbo].[Person_ethnic_group] ([person_uid], [ethnic_group_cd], [ethnic_group_desc_txt], [record_status_cd]) VALUES (@dbo_Entity_entity_uid_13, N'N', N'Not Hispanic or Latino', N'ACTIVE');
-- dbo.Entity_id
-- step: 5
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [add_user_id], [assigning_authority_cd], [assigning_authority_desc_txt], [last_chg_user_id], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid_13, 1, N'2026-05-26T13:51:43.047', @elruser_id, N'2.16.840.1.113883.19.3.2.1', N'TEST_ELR_APP', @elruser_id, N'ACTIVE', N'CDC-TEST-PATIENT-001', N'A', N'2026-05-26T13:51:43.147', N'PI', N'2026-05-26T13:51:43.047', N'ISO');
-- dbo.Postal_locator
-- step: 5
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt], [cntry_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [street_addr2], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_9, N'2026-05-26T13:51:43.053', @elruser_id, N'Atlanta', N'840', N'ACTIVE', N'2026-05-26T13:51:43.053', N'13', N'1600 Clifton Rd NE', N' ', N'30333');
-- dbo.Entity_locator_participation
-- step: 5
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_13, @dbo_Postal_locator_postal_locator_uid_9, N'H', N'PST', N'2026-05-26T13:51:43.130', @elruser_id, N'ACTIVE', N'2026-05-26T13:51:43.130', N'A', N'2026-05-26T13:51:43.130', N'H', 1, N'2026-05-26T13:51:43.047');
-- dbo.Tele_locator
-- step: 5
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_9, N'2026-05-26T13:51:43.057', @elruser_id, N'0.0', N'404-639-3311', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 5
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [cd_desc_txt], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_13, @dbo_Tele_locator_tele_locator_uid_9, N'PH', N'PHONE', N'TELE', N'2026-05-26T13:51:43.130', @elruser_id, N'ACTIVE', N'2026-05-26T13:51:43.130', N'A', N'2026-05-26T13:51:43.130', N'H', 1, N'2026-05-26T13:51:43.047');
-- dbo.Act
-- step: 5
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_11, N'OBS', N'EVN');
-- dbo.Observation
-- step: 5
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [effective_from_time], [electronic_ind], [last_chg_time], [last_chg_user_id], [local_id], [obs_domain_cd], [obs_domain_cd_st_1], [record_status_cd], [record_status_time], [status_cd], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [rpt_to_state_time]) VALUES (@dbo_Act_act_uid_11, N'2026-05-19T13:00:00', N'2026-05-26T13:51:43.260', @elruser_id, N'80679-4', N'Escherichia coli Stx1 and Stx2 toxin stx1+stx2 genes [Presence] in Stool by NAA with probe detection', N'LN', N'LOINC', N'LabReport', N'2026-05-19T08:00:00', N'Y', N'2026-05-26T13:51:43.260', @elruser_id, @dbo_Observation_local_id_10, N'LabReport', N'Order', N'UNPROCESSED', N'2026-05-26T13:51:43.260', N'D', 4, N'T', 1, N'2026-05-26T13:51:43.047');
-- dbo.Act_id
-- step: 5
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_cd], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_11, 1, N'CLIA', N'Clinical Laboratory Improvement Amendment', N'ACTIVE', N'ELR-STEC-0004A', N'A', N'2026-05-26T13:51:43.270', N'MCID', N'Message Control ID');
-- step: 5
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_cd], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_11, 2, N'CLIA', N'Clinical Laboratory Improvement Amendment', N'ACTIVE', N'LAB-STEC-20260527-001', N'A', N'2026-05-26T13:51:43.270', N'FN', N'Filler Number');
-- dbo.Act
-- step: 5
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_12, N'OBS', N'EVN');
-- dbo.Observation
-- step: 5
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [electronic_ind], [local_id], [obs_domain_cd_st_1], [status_cd], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_12, N'2026-05-19T13:00:00', N'80679-4', N'Escherichia coli Stx1 and Stx2 toxin stx1+stx2 genes [Presence] in Stool by NAA with probe detection', N'LN', N'LOINC', N'LabReport', N'Y', @dbo_Observation_local_id_11, N'Result', N'D', 4, N'T', 1);
-- dbo.Act_id
-- step: 5
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_cd], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_12, 1, N'99D9999999', N'CDC TEST LAB', N'ACTIVE', N'ELR-STEC-0004A', N'A', N'2026-05-26T13:51:43.277', N'MCID', N'Message Control ID');
-- step: 5
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_cd], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_12, 2, N'99D9999999', N'CDC TEST LAB', N'ACTIVE', N'LAB-STEC-20260527-001', N'A', N'2026-05-26T13:51:43.277', N'FN', N'Filler Number');
-- dbo.Obs_value_coded
-- step: 5
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code], [code_system_cd], [display_name], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd], [alt_cd_system_desc_txt]) VALUES (@dbo_Act_act_uid_12, N'82334004', N'SCT', N'Indeterminate', N'IND', N'LOCAL', N'L', N'LOCAL');
-- dbo.Entity
-- step: 5
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_14, N'MAT');
-- dbo.Material
-- step: 5
INSERT INTO [dbo].[Material] ([material_uid], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid_14, N'Add', N'2026-05-26T13:51:43.287', @elruser_id, N'119339001', N'Stool specimen (specimen)', N'2026-05-26T13:51:43.287', @elruser_id, @dbo_Material_local_id_5, N'ACTIVE', N'2026-05-26T13:51:43.287', N'A', N'2026-05-26T13:51:43.287', 1);
-- dbo.Entity_id
-- step: 5
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [assigning_authority_cd], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid_14, 1, N'2026-05-26T13:51:43.047', N'2.16.840.1.113883.19.3.2.1', N'TEST_ELR_APP', N'ACTIVE', N'SPM-STEC-20260527-001', N'A', N'2026-05-26T13:51:43.297', N'SPC', N'Specimen', N'2026-05-26T13:51:43.047', N'ISO');
-- dbo.Participation
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_reason_cd], [add_time], [add_user_id], [cd], [last_chg_time], [record_status_cd], [status_cd], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Act_act_uid_11, N'AUT', N'OBS', N'because', N'2026-05-26T13:51:43.047', @elruser_id, N'SF', N'2026-05-26T13:51:43.047', N'ACTIVE', N'A', N'ORG', N'Author');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_user_id], [cd], [record_status_cd], [status_cd], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_13, @dbo_Act_act_uid_11, N'PATSBJ', N'OBS', @superuser_id, N'PAT', N'ACTIVE', N'A', N'PSN', N'Patient Subject');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_reason_cd], [add_time], [add_user_id], [cd], [last_chg_time], [record_status_cd], [status_cd], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_5, @dbo_Act_act_uid_11, N'ORD', N'OBS', N'because', N'2026-05-26T13:51:43.047', @elruser_id, N'OP', N'2026-05-26T13:51:43.047', N'ACTIVE', N'A', N'ORG', N'Orderer');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_reason_cd], [add_time], [add_user_id], [cd], [last_chg_time], [record_status_cd], [status_cd], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_14, @dbo_Act_act_uid_11, N'SPC', N'OBS', N'because', N'2026-05-26T13:51:43.047', @elruser_id, N'NI', N'2026-05-26T13:51:43.047', N'ACTIVE', N'A', N'MAT', N'Specimen');
-- step: 5
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_reason_cd], [add_time], [add_user_id], [cd], [last_chg_time], [record_status_cd], [status_cd], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_3, @dbo_Act_act_uid_11, N'ORD', N'OBS', N'because', N'2026-05-26T13:51:43.047', @elruser_id, N'OP', N'2026-05-26T13:51:43.047', N'ACTIVE', N'A', N'PSN', N'Orderer');
-- dbo.Act_relationship
-- step: 5
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [sequence_nbr], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_11, @dbo_Act_act_uid_12, N'COMP', N'2026-05-26T13:51:43.047', N'2026-05-26T13:51:43.047', N'ACTIVE', N'2026-05-26T13:51:43.047', 1, N'OBS', N'A', N'2026-05-26T13:51:43.303', N'OBS', N'Has Component');
-- dbo.Role
-- step: 5
INSERT INTO [dbo].[Role] ([subject_entity_uid], [cd], [role_seq], [add_reason_cd], [add_time], [cd_desc_txt], [effective_from_time], [effective_to_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_13, N'PAT', 1, N'because', N'2026-05-26T13:51:43.310', N'PATIENT', N'2026-05-26T13:51:43.310', N'2026-05-26T13:51:43.310', N'2026-05-26T13:51:43.307', @elruser_id, N'ACTIVE', N'2026-05-26T13:51:43.307', N'A', N'2026-05-26T13:51:43.307', N'PATIENT');
-- step: 5
INSERT INTO [dbo].[Role] ([subject_entity_uid], [cd], [role_seq], [add_time], [cd_desc_txt], [effective_from_time], [effective_to_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [scoping_class_cd], [scoping_entity_uid], [scoping_role_cd], [scoping_role_seq], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_14, N'NI', 1, N'2026-05-26T13:51:43.317', N'No Information Given', N'2026-05-26T13:51:43.317', N'2026-05-26T13:51:43.317', N'2026-05-26T13:51:43.313', @elruser_id, N'ACTIVE', N'2026-05-26T13:51:43.313', N'PATIENT', @dbo_Entity_entity_uid_13, N'PATIENT', 1, N'A', N'2026-05-26T13:51:43.313', N'MAT');
-- dbo.EDX_Document
-- step: 5
INSERT INTO [dbo].[EDX_Document] ([act_uid], [payload], [record_status_cd], [record_status_time], [add_time], [doc_type_cd], [nbs_document_metadata_uid]) OUTPUT INSERTED.[EDX_Document_uid] INTO @dbo_EDX_Document_EDX_Document_uid_5_output ([value]) VALUES (@dbo_Act_act_uid_11, N'<Container xmlns="http://www.cdc.gov/NEDSS"><HL7LabReport><HL7MSH><FieldSeparator>|</FieldSeparator><EncodingCharacters>^~\&amp;</EncodingCharacters><SendingApplication><HL7NamespaceID>TEST_ELR_APP</HL7NamespaceID><HL7UniversalID>2.16.840.1.113883.19.3.2.1</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></SendingApplication><SendingFacility><HL7NamespaceID>CDC TEST LAB</HL7NamespaceID><HL7UniversalID>99D9999999</HL7UniversalID><HL7UniversalIDType>CLIA</HL7UniversalIDType></SendingFacility><ReceivingApplication><HL7NamespaceID>NBS</HL7NamespaceID><HL7UniversalID>2.16.840.1.113883.19.4.1</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></ReceivingApplication><ReceivingFacility><HL7NamespaceID>PUBLIC HEALTH</HL7NamespaceID><HL7UniversalID>2.16.840.1.113883.19.4.2</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></ReceivingFacility><DateTimeOfMessage><year>2026</year><month>05</month><day>27</day><hours>13</hours><minutes>00</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></DateTimeOfMessage><Security/><MessageType><MessageCode>ORU</MessageCode><TriggerEvent>R01</TriggerEvent><MessageStructure>ORU_R01</MessageStructure></MessageType><MessageControlID>ELR-STEC-0004A</MessageControlID><ProcessingID><HL7ProcessingID>T</HL7ProcessingID><HL7ProcessingMode/></ProcessingID><VersionID><HL7VersionID>2.5.1</HL7VersionID></VersionID><AcceptAcknowledgmentType>AL</AcceptAcknowledgmentType><ApplicationAcknowledgmentType>NE</ApplicationAcknowledgmentType><CountryCode>USA</CountryCode><CharacterSet/><MessageProfileIdentifier><HL7EntityIdentifier>PHLabReport-Ack</HL7EntityIdentifier><HL7NamespaceID/><HL7UniversalID>2.16.840.1.113883.9.10</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></MessageProfileIdentifier></HL7MSH><HL7SoftwareSegment><SoftwareVendorOrganization><HL7OrganizationName>TEST ELR GENERATOR</HL7OrganizationName><HL7OrganizationNameTypeCode>L</HL7OrganizationNameTypeCode><HL7IDNumber/><HL7CheckDigit/></SoftwareVendorOrganization><SoftwareCertifiedVersionOrReleaseNumber>1.0</SoftwareCertifiedVersionOrReleaseNumber><SoftwareProductName>CDC TEST DATA</SoftwareProductName><SoftwareBinaryID>1.0</SoftwareBinaryID><SoftwareProductInformation/></HL7SoftwareSegment><HL7PATIENT_RESULT><PATIENT><PatientIdentification><SetIDPID><HL7SequenceID>1</HL7SequenceID></SetIDPID><PatientIdentifierList><HL7IDNumber>CDC-TEST-PATIENT-001</HL7IDNumber><HL7AssigningAuthority><HL7NamespaceID>TEST_ELR_APP</HL7NamespaceID><HL7UniversalID>2.16.840.1.113883.19.3.2.1</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></HL7AssigningAuthority><HL7IdentifierTypeCode>PI</HL7IdentifierTypeCode></PatientIdentifierList><PatientName><HL7FamilyName><HL7Surname>Swift</HL7Surname></HL7FamilyName><HL7GivenName>Taylor</HL7GivenName><HL7Degree/></PatientName><DateTimeOfBirth><year>1990</year><month>01</month><day>01</day></DateTimeOfBirth><AdministrativeSex>F</AdministrativeSex><Race><HL7Identifier>2106-3</HL7Identifier><HL7Text>White</HL7Text><HL7NameofCodingSystem>CDCREC</HL7NameofCodingSystem></Race><PatientAddress><HL7StreetAddress><HL7StreetOrMailingAddress>1600 Clifton Rd NE</HL7StreetOrMailingAddress></HL7StreetAddress><HL7City>Atlanta</HL7City><HL7StateOrProvince>GA</HL7StateOrProvince><HL7ZipOrPostalCode>30333</HL7ZipOrPostalCode><HL7Country>USA</HL7Country><HL7AddressType>H</HL7AddressType></PatientAddress><PhoneNumberHome><HL7TelecommunicationUseCode>PRN</HL7TelecommunicationUseCode><HL7TelecommunicationEquipmentType>PH</HL7TelecommunicationEquipmentType><HL7CountryCode><HL7Numeric>1</HL7Numeric></HL7CountryCode><HL7AreaCityCode><HL7Numeric>404</HL7Numeric></HL7AreaCityCode><HL7LocalNumber><HL7Numeric>6393311</HL7Numeric></HL7LocalNumber><HL7Extension/></PhoneNumberHome><SSNNumberPatient/><EthnicGroup><HL7Identifier>N</HL7Identifier><HL7Text>Not Hispanic or Latino</HL7Text><HL7NameofCodingSystem>HL70189</HL7NameofCodingSystem></EthnicGroup><BirthOrder/></PatientIdentification></PATIENT><ORDER_OBSERVATION><CommonOrder><OrderControl>RE</OrderControl><FillerOrderNumber><HL7EntityIdentifier>ORD-STEC-20260527-001</HL7EntityIdentifier><HL7NamespaceID>TEST_ELR_APP</HL7NamespaceID><HL7UniversalID>2.16.840.1.113883.19.3.2.1</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></FillerOrderNumber><OrderStatus>CM</OrderStatus><DateTimeOfTransaction><year>2026</year><month>05</month><day>20</day><hours>13</hours><minutes>30</minutes><seconds>00</seconds><gmtOffset/></DateTimeOfTransaction><OrderingProvider><HL7IDNumber>9999999999</HL7IDNumber><HL7FamilyName><HL7Surname>Sample</HL7Surname></HL7FamilyName><HL7GivenName>Sarah</HL7GivenName><HL7NameTypeCode>NPI</HL7NameTypeCode><HL7IdentifierTypeCode/></OrderingProvider><OrderingFacilityName><HL7OrganizationName>Republic Records</HL7OrganizationName><HL7IDNumber/><HL7CheckDigit/></OrderingFacilityName><OrderingFacilityAddress><HL7StreetAddress><HL7StreetOrMailingAddress>CDC TEST CLINIC</HL7StreetOrMailingAddress></HL7StreetAddress><HL7City/><HL7StateOrProvince/><HL7ZipOrPostalCode/><HL7Country/><HL7AddressType/></OrderingFacilityAddress><OrderingFacilityPhoneNumber><HL7TelecommunicationUseCode/><HL7TelecommunicationEquipmentType>Atlanta</HL7TelecommunicationEquipmentType><HL7CountryCode><HL7Numeric>30333</HL7Numeric></HL7CountryCode><HL7AreaCityCode><HL7Numeric>404</HL7Numeric></HL7AreaCityCode><HL7LocalNumber><HL7Numeric>6393311</HL7Numeric></HL7LocalNumber><HL7Extension/></OrderingFacilityPhoneNumber><OrderingProviderAddress><HL7StreetAddress><HL7StreetOrMailingAddress/></HL7StreetAddress><HL7City>PH</HL7City><HL7StateOrProvince/><HL7ZipOrPostalCode>1</HL7ZipOrPostalCode><HL7Country>404</HL7Country><HL7AddressType>6393311</HL7AddressType></OrderingProviderAddress></CommonOrder><ObservationRequest><SetIDOBR><HL7SequenceID>1</HL7SequenceID></SetIDOBR><FillerOrderNumber><HL7EntityIdentifier>LAB-STEC-20260527-001</HL7EntityIdentifier><HL7NamespaceID>CDC TEST LAB</HL7NamespaceID><HL7UniversalID>99D9999999</HL7UniversalID><HL7UniversalIDType>CLIA</HL7UniversalIDType></FillerOrderNumber><UniversalServiceIdentifier><HL7Identifier>80679-4</HL7Identifier><HL7Text>Escherichia coli Stx1 and Stx2 toxin stx1+stx2 genes [Presence] in Stool by NAA with probe detection</HL7Text><HL7NameofCodingSystem>LN</HL7NameofCodingSystem></UniversalServiceIdentifier><ObservationDateTime><year>2026</year><month>05</month><day>19</day><hours>08</hours><minutes>00</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></ObservationDateTime><SpecimenReceivedDateTime><year>2026</year><month>05</month><day>19</day><hours>09</hours><minutes>15</minutes><seconds>00</seconds><gmtOffset/></SpecimenReceivedDateTime><OrderingProvider><HL7IDNumber>9999999999</HL7IDNumber><HL7FamilyName><HL7Surname>Sample</HL7Surname></HL7FamilyName><HL7GivenName>Sarah</HL7GivenName><HL7NameTypeCode>NPI</HL7NameTypeCode><HL7IdentifierTypeCode/></OrderingProvider><ResultsRptStatusChngDateTime><year>2026</year><month>05</month><day>19</day><hours>13</hours><minutes>00</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></ResultsRptStatusChngDateTime><ResultStatus>F</ResultStatus><NumberofSampleContainers/></ObservationRequest><PatientResultOrderObservation><OBSERVATION><ObservationResult><SetIDOBX><HL7SequenceID>1</HL7SequenceID></SetIDOBX><ValueType>CWE</ValueType><ObservationIdentifier><HL7Identifier>80679-4</HL7Identifier><HL7Text>Escherichia coli Stx1 and Stx2 toxin stx1+stx2 genes [Presence] in Stool by NAA with probe detection</HL7Text><HL7NameofCodingSystem>LN</HL7NameofCodingSystem></ObservationIdentifier><ObservationValue>82334004^Indeterminate^SCT^IND^Indeterminate^L</ObservationValue><Probability/><ObservationResultStatus>F</ObservationResultStatus><DateTimeOftheObservation><year>2026</year><month>05</month><day>19</day><hours>08</hours><minutes>00</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></DateTimeOftheObservation><DateTimeOftheAnalysis><year>2026</year><month>05</month><day>19</day><hours>13</hours><minutes>00</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></DateTimeOftheAnalysis></ObservationResult></OBSERVATION></PatientResultOrderObservation><PatientResultOrderSPMObservation><SPECIMEN><SPECIMEN><SetIDSPM><HL7SequenceID>1</HL7SequenceID></SetIDSPM><SpecimenID><HL7PlacerAssignedIdentifier><HL7EntityIdentifier/></HL7PlacerAssignedIdentifier><HL7FillerAssignedIdentifier><HL7EntityIdentifier>SPM-STEC-20260527-001</HL7EntityIdentifier><HL7NamespaceID>TEST_ELR_APP</HL7NamespaceID><HL7UniversalID>2.16.840.1.113883.19.3.2.1</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></HL7FillerAssignedIdentifier></SpecimenID><SpecimenType><HL7Identifier>119339001</HL7Identifier><HL7Text>Stool specimen (specimen)</HL7Text><HL7NameofCodingSystem>SCT</HL7NameofCodingSystem></SpecimenType><GroupedSpecimenCount/><SpecimenCollectionDateTime><HL7RangeStartDateTime><year>2026</year><month>05</month><day>19</day><hours>08</hours><minutes>00</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></HL7RangeStartDateTime></SpecimenCollectionDateTime><SpecimenReceivedDateTime><year>2026</year><month>05</month><day>19</day><hours>09</hours><minutes>15</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></SpecimenReceivedDateTime><NumberOfSpecimenContainers/></SPECIMEN></SPECIMEN></PatientResultOrderSPMObservation></ORDER_OBSERVATION></HL7PATIENT_RESULT></HL7LabReport></Container>', N'ACTIVE', N'2026-05-26T13:51:43.047', N'2026-05-26T13:51:43.047', N'11648804', 1005);
SELECT TOP 1 @dbo_EDX_Document_EDX_Document_uid_5 = [value] FROM @dbo_EDX_Document_EDX_Document_uid_5_output;
-- dbo.Person
-- step: 5
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-26T13:51:43.117', [record_status_time] = N'2026-05-26T13:51:43.117', [status_time] = N'2026-05-26T13:51:43.117', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [as_of_date_ethnicity] = N'2026-05-26T13:51:43.047' WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Person_name
-- step: 5
UPDATE [dbo].[Person_name] SET [as_of_date] = N'2026-05-26T13:51:43.047' WHERE [person_uid] = @dbo_Entity_entity_uid AND [person_name_seq] = 1;
-- dbo.Person_race
-- step: 5
UPDATE [dbo].[Person_race] SET [as_of_date] = N'2026-05-26T13:51:43.047' WHERE [person_uid] = @dbo_Entity_entity_uid AND [race_cd] = N'2106-3';
-- dbo.Entity_id
-- step: 5
UPDATE [dbo].[Entity_id] SET [as_of_date] = N'2026-05-26T13:51:43.047' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [entity_id_seq] = 1;
-- dbo.Entity_locator_participation
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-26T13:51:43.117', [record_status_time] = N'2026-05-26T13:51:43.117', [status_time] = N'2026-05-26T13:51:43.117', [as_of_date] = N'2026-05-26T13:51:43.047' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-26T13:51:43.117', [record_status_time] = N'2026-05-26T13:51:43.117', [status_time] = N'2026-05-26T13:51:43.117', [as_of_date] = N'2026-05-26T13:51:43.047' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;
-- step: 5
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-26T13:51:43.117', [record_status_time] = N'2026-05-26T13:51:43.117', [status_time] = N'2026-05-26T13:51:43.117' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;
-- dbo.EDX_activity_log
-- step: 5
INSERT INTO [dbo].[EDX_activity_log] ([source_uid], [target_uid], [doc_type], [record_status_cd], [record_status_time], [exception_txt], [imp_exp_ind_cd], [source_type_cd], [target_type_cd], [business_obj_localId], [source_nm], [Message_id], [Entity_nm], [Accession_nbr]) OUTPUT INSERTED.[edx_activity_log_uid] INTO @dbo_EDX_activity_log_edx_activity_log_uid_5_output ([value]) VALUES (10000015, 10009414, N'11648804', N'Success', N'2026-05-26T13:51:43.447', N'Jurisdiction and/or Program Area could not be derived.  The Lab Report is logged in Documents Requiring Security Assignment queue.', N'I', N'INT', N'LAB', N'OBS10001022GA01', N'CDC TEST LAB', N'ELR-STEC-0004A', N'Taylor Swift', N'LAB-STEC-20260527-001');
SELECT TOP 1 @dbo_EDX_activity_log_edx_activity_log_uid_5 = [value] FROM @dbo_EDX_activity_log_edx_activity_log_uid_5_output;
-- dbo.EDX_activity_detail_log
-- step: 5
INSERT INTO [dbo].[EDX_activity_detail_log] ([edx_activity_log_uid], [record_id], [record_type], [record_nm], [log_type], [log_comment]) OUTPUT INSERTED.[edx_activity_detail_log_uid] INTO @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_23_output ([value]) VALUES (@dbo_EDX_activity_log_edx_activity_log_uid_5, N'10009372', N'Electronic Lab Report', N'ELR_IMPORT', N'Success', N'Patient match found: Taylor Swift (UID: 10009372).');
SELECT TOP 1 @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_23 = [value] FROM @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_23_output;
-- step: 5
INSERT INTO [dbo].[EDX_activity_detail_log] ([edx_activity_log_uid], [record_id], [record_type], [record_nm], [log_type], [log_comment]) OUTPUT INSERTED.[edx_activity_detail_log_uid] INTO @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_24_output ([value]) VALUES (@dbo_EDX_activity_log_edx_activity_log_uid_5, N'OBS10001022GA01', N'Electronic Lab Report', N'ELR_IMPORT', N'Failure', N'Jurisdiction not derived.');
SELECT TOP 1 @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_24 = [value] FROM @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_24_output;
-- step: 5
INSERT INTO [dbo].[EDX_activity_detail_log] ([edx_activity_log_uid], [record_id], [record_type], [record_nm], [log_type], [log_comment]) OUTPUT INSERTED.[edx_activity_detail_log_uid] INTO @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_25_output ([value]) VALUES (@dbo_EDX_activity_log_edx_activity_log_uid_5, N'OBS10001022GA01', N'Electronic Lab Report', N'ELR_IMPORT', N'Failure', N'Program Area not derived.');
SELECT TOP 1 @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_25 = [value] FROM @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_25_output;
-- step: 5
INSERT INTO [dbo].[EDX_activity_detail_log] ([edx_activity_log_uid], [record_id], [record_type], [record_nm], [log_type], [log_comment]) OUTPUT INSERTED.[edx_activity_detail_log_uid] INTO @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_26_output ([value]) VALUES (@dbo_EDX_activity_log_edx_activity_log_uid_5, N'OBS10001022GA01', N'Electronic Lab Report', N'ELR_IMPORT', N'Success', N'Lab OBS10001022GA01 created and associated to Patient.');
SELECT TOP 1 @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_26 = [value] FROM @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_26_output;
-- step: 5
INSERT INTO [dbo].[EDX_activity_detail_log] ([edx_activity_log_uid], [record_id], [record_type], [record_nm], [log_type], [log_comment]) OUTPUT INSERTED.[edx_activity_detail_log_uid] INTO @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_27_output ([value]) VALUES (@dbo_EDX_activity_log_edx_activity_log_uid_5, N'OBS10001022GA01', N'Electronic Lab Report', N'ELR_IMPORT', N'Success', N'Document created and associated to Lab.');
SELECT TOP 1 @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_27 = [value] FROM @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_27_output;
-- step: 5
INSERT INTO [dbo].[EDX_activity_detail_log] ([edx_activity_log_uid], [record_id], [record_type], [record_nm], [log_type], [log_comment]) OUTPUT INSERTED.[edx_activity_detail_log_uid] INTO @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_28_output ([value]) VALUES (@dbo_EDX_activity_log_edx_activity_log_uid_5, N'OBS10001022GA01', N'Electronic Lab Report', N'ELR_IMPORT', N'Success', N'The Ethnicity code provided in the message is not found in the SRT database.  The code is saved to the NBS.');
SELECT TOP 1 @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_28 = [value] FROM @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_28_output;
-- dbo.EDX_activity_log
-- step: 5
UPDATE [dbo].[EDX_activity_log] SET [exception_txt] = N'Jurisdiction and/or Program Area could not be derived.  The Lab Report is logged in Documents Requiring Security Assignment queue.' WHERE [edx_activity_log_uid] = @dbo_EDX_activity_log_edx_activity_log_uid_5;
-- dbo.Observation
-- step: 5
UPDATE [dbo].[Observation] SET [jurisdiction_cd] = N'130004', [last_chg_time] = N'2026-05-26T13:51:58.780', [last_chg_user_id] = @superuser_id, [prog_area_cd] = N'GCD', [record_status_time] = N'2026-05-26T13:51:58.780', [program_jurisdiction_oid] = 1300400009, [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid_11;
-- dbo.Act_relationship
-- step: 5
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_4, @dbo_Act_act_uid_11, N'LabReport', N'2026-05-26T13:52:08.120', N'2026-05-26T13:52:08.120', @superuser_id, N'ACTIVE', N'2026-05-26T13:52:08.120', N'OBS', N'A', N'2026-05-26T13:52:08.120', N'CASE');
-- dbo.Observation
-- step: 5
UPDATE [dbo].[Observation] SET [last_chg_time] = N'2026-05-26T13:52:08.127', [record_status_cd] = N'PROCESSED', [record_status_time] = N'2026-05-26T13:52:08.127', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid_11;
