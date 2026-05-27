USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;
DECLARE @elruser_id bigint = 10000015;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 14250;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 14251;
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 14252;
DECLARE @dbo_Entity_entity_uid_2 bigint = 14253;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 14254;
DECLARE @dbo_Tele_locator_tele_locator_uid_2 bigint = 14255;
DECLARE @dbo_Entity_entity_uid_3 bigint = 14256;
DECLARE @dbo_Postal_locator_postal_locator_uid_3 bigint = 14257;
DECLARE @dbo_Entity_entity_uid_4 bigint = 14258;
DECLARE @dbo_Entity_entity_uid_5 bigint = 14259;
DECLARE @dbo_Postal_locator_postal_locator_uid_4 bigint = 14260;
DECLARE @dbo_Tele_locator_tele_locator_uid_3 bigint = 14261;
DECLARE @dbo_Act_act_uid bigint = 14262;
DECLARE @dbo_Act_act_uid_2 bigint = 14263;
DECLARE @dbo_Entity_entity_uid_6 bigint = 14264;
DECLARE @dbo_Entity_entity_uid_7 bigint = 14265;
DECLARE @dbo_Postal_locator_postal_locator_uid_5 bigint = 14266;
DECLARE @dbo_Tele_locator_tele_locator_uid_4 bigint = 14267;
DECLARE @dbo_Act_act_uid_3 bigint = 14268;
DECLARE @dbo_Act_act_uid_4 bigint = 14269;
DECLARE @dbo_DF_sf_metadata_group_df_sf_metadata_group_uid bigint = 14270;
DECLARE @dbo_Bus_obj_df_sf_mdata_group_business_object_uid bigint = 14271;
DECLARE @dbo_Tele_locator_tele_locator_uid_5 bigint = 14272;
DECLARE @dbo_Act_act_uid_5 bigint = 14273;
DECLARE @dbo_Entity_entity_uid_8 bigint = 14274;
DECLARE @dbo_Postal_locator_postal_locator_uid_6 bigint = 14275;
DECLARE @dbo_Tele_locator_tele_locator_uid_6 bigint = 14276;
DECLARE @dbo_Entity_entity_uid_9 bigint = 14277;
DECLARE @dbo_Postal_locator_postal_locator_uid_7 bigint = 14278;
DECLARE @dbo_Tele_locator_tele_locator_uid_7 bigint = 14279;
DECLARE @dbo_Act_act_uid_6 bigint = 14280;
DECLARE @dbo_Act_act_uid_7 bigint = 14281;
DECLARE @dbo_Entity_entity_uid_10 bigint = 14282;
DECLARE @dbo_Entity_entity_uid_11 bigint = 14283;
DECLARE @dbo_Postal_locator_postal_locator_uid_8 bigint = 14284;
DECLARE @dbo_Tele_locator_tele_locator_uid_8 bigint = 14285;
DECLARE @dbo_Act_act_uid_8 bigint = 14286;
DECLARE @dbo_Act_act_uid_9 bigint = 14287;
DECLARE @dbo_Act_act_uid_10 bigint = 14288;
DECLARE @dbo_Entity_entity_uid_12 bigint = 14289;
DECLARE @dbo_Entity_entity_uid_13 bigint = 14290;
DECLARE @dbo_Postal_locator_postal_locator_uid_9 bigint = 14291;
DECLARE @dbo_Tele_locator_tele_locator_uid_9 bigint = 14292;
DECLARE @dbo_Act_act_uid_11 bigint = 14293;
DECLARE @dbo_Act_act_uid_12 bigint = 14294;
DECLARE @dbo_Entity_entity_uid_14 bigint = 14295;
DECLARE @dbo_Act_act_uid_13 bigint = 14296;
DECLARE @dbo_Entity_entity_uid_15 bigint = 14297;
DECLARE @dbo_Postal_locator_postal_locator_uid_10 bigint = 14298;
DECLARE @dbo_Tele_locator_tele_locator_uid_10 bigint = 14299;
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

-- STEP 1: Taylor Swift experiences nausea and vomiting after drinking raw milk
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid, N'PSN');
-- dbo.Person
-- step: 1
INSERT INTO [dbo].[Person] ([person_uid], [add_reason_cd], [add_time], [add_user_id], [birth_time], [birth_time_calc], [cd], [cd_desc_txt], [curr_sex_cd], [ethnic_group_ind], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_ethnicity], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid, N'because', N'2026-05-26T13:36:10.070', @elruser_id, N'1990-01-01T00:00:00', N'1990-01-01T00:00:00', N'PAT', N'Observation Subject', N'F', N'N', N'2026-05-26T13:36:10.070', @elruser_id, @dbo_Person_local_id, N'ACTIVE', N'A', N'2026-05-26T13:36:10.070', N'Taylor', N'Swift', 1, N'2026-05-26T13:36:10.070', N'2026-05-26T13:36:10.070', N'2026-05-26T13:36:10.070', N'2026-05-26T13:36:10.070', N'2026-05-26T00:00:00', N'Y', @dbo_Entity_entity_uid);
-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid, 1, N'Add', N'2026-05-26T13:36:10.070', @elruser_id, N'Taylor', N'T460', N'2026-05-26T13:36:10.070', @elruser_id, N'Swift', N'S130', N'L', N'ACTIVE', N'A', N'2026-05-26T13:36:10.140', N'2026-05-26T13:36:10.070');
-- dbo.Person_race
-- step: 1
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [add_user_id], [race_category_cd], [race_desc_txt], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid, N'2106-3', N'2026-05-26T13:36:10.087', @elruser_id, N'2106-3', N'White', N'ACTIVE', N'2026-05-26T13:36:10.070');
-- dbo.Person_ethnic_group
-- step: 1
INSERT INTO [dbo].[Person_ethnic_group] ([person_uid], [ethnic_group_cd], [ethnic_group_desc_txt], [record_status_cd]) VALUES (@dbo_Entity_entity_uid, N'N', N'Not Hispanic or Latino', N'ACTIVE');
-- dbo.Entity_id
-- step: 1
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [add_user_id], [assigning_authority_cd], [assigning_authority_desc_txt], [last_chg_user_id], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid, 1, N'2026-05-26T13:36:10.070', @elruser_id, N'2.16.840.1.113883.19.3.2.1', N'TEST_ELR_APP', @elruser_id, N'ACTIVE', N'CDC-TEST-PATIENT-001', N'A', N'2026-05-26T13:36:10.157', N'PI', N'2026-05-26T13:36:10.070', N'ISO');
-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt], [cntry_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [street_addr2], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid, N'2026-05-26T13:36:10.080', @elruser_id, N'Atlanta', N'840', N'ACTIVE', N'2026-05-26T13:36:10.080', N'13', N'1600 Clifton Rd NE', N' ', N'30333');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Postal_locator_postal_locator_uid, N'H', N'PST', N'2026-05-26T13:36:10.120', @elruser_id, N'ACTIVE', N'2026-05-26T13:36:10.120', N'A', N'2026-05-26T13:36:10.120', N'H', 1, N'2026-05-26T13:36:10.070');
-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid, N'2026-05-26T13:36:10.087', @elruser_id, N'0.0', N'404-639-3311', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [cd_desc_txt], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Tele_locator_tele_locator_uid, N'PH', N'PHONE', N'TELE', N'2026-05-26T13:36:10.120', @elruser_id, N'ACTIVE', N'2026-05-26T13:36:10.120', N'A', N'2026-05-26T13:36:10.120', N'H', 1, N'2026-05-26T13:36:10.070');
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_2, N'PSN');
-- dbo.Person
-- step: 1
INSERT INTO [dbo].[Person] ([person_uid], [add_reason_cd], [add_time], [add_user_id], [birth_time], [birth_time_calc], [cd], [cd_desc_txt], [curr_sex_cd], [ethnic_group_ind], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_ethnicity], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_2, N'because', N'2026-05-26T13:36:10.250', @elruser_id, N'1990-01-01T00:00:00', N'1990-01-01T00:00:00', N'PAT', N'Observation Subject', N'F', N'N', N'2026-05-26T13:36:10.250', @elruser_id, @dbo_Person_local_id, N'ACTIVE', N'2026-05-26T13:36:10.250', N'A', N'2026-05-26T13:36:10.250', N'Taylor', N'Swift', 1, N'2026-05-26T13:36:10.070', N'2026-05-26T13:36:10.070', N'2026-05-26T13:36:10.070', N'2026-05-26T13:36:10.070', N'2026-05-26T00:00:00', N'Y', @dbo_Entity_entity_uid);
-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, 1, N'Add', N'2026-05-26T13:36:10.070', @elruser_id, N'Taylor', N'T460', N'2026-05-26T13:36:10.070', @elruser_id, N'Swift', N'S130', N'L', N'ACTIVE', N'A', N'2026-05-26T13:36:10.260', N'2026-05-26T13:36:10.070');
-- dbo.Person_race
-- step: 1
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [add_time], [add_user_id], [race_category_cd], [race_desc_txt], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, N'2106-3', N'2026-05-26T13:36:10.087', @elruser_id, N'2106-3', N'White', N'ACTIVE', N'2026-05-26T13:36:10.070');
-- dbo.Person_ethnic_group
-- step: 1
INSERT INTO [dbo].[Person_ethnic_group] ([person_uid], [ethnic_group_cd], [ethnic_group_desc_txt], [record_status_cd]) VALUES (@dbo_Entity_entity_uid_2, N'N', N'Not Hispanic or Latino', N'ACTIVE');
-- dbo.Entity_id
-- step: 1
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [add_user_id], [assigning_authority_cd], [assigning_authority_desc_txt], [last_chg_user_id], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid_2, 1, N'2026-05-26T13:36:10.070', @elruser_id, N'2.16.840.1.113883.19.3.2.1', N'TEST_ELR_APP', @elruser_id, N'ACTIVE', N'CDC-TEST-PATIENT-001', N'A', N'2026-05-26T13:36:10.263', N'PI', N'2026-05-26T13:36:10.070', N'ISO');
-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt], [cntry_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [street_addr2], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_2, N'2026-05-26T13:36:10.080', @elruser_id, N'Atlanta', N'840', N'ACTIVE', N'2026-05-26T13:36:10.080', N'13', N'1600 Clifton Rd NE', N' ', N'30333');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Postal_locator_postal_locator_uid_2, N'H', N'PST', N'2026-05-26T13:36:10.250', @elruser_id, N'ACTIVE', N'2026-05-26T13:36:10.250', N'A', N'2026-05-26T13:36:10.250', N'H', 1, N'2026-05-26T13:36:10.070');
-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_2, N'2026-05-26T13:36:10.087', @elruser_id, N'0.0', N'404-639-3311', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [cd_desc_txt], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Tele_locator_tele_locator_uid_2, N'PH', N'PHONE', N'TELE', N'2026-05-26T13:36:10.250', @elruser_id, N'ACTIVE', N'2026-05-26T13:36:10.250', N'A', N'2026-05-26T13:36:10.250', N'H', 1, N'2026-05-26T13:36:10.070');
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_3, N'PSN');
-- dbo.Person
-- step: 1
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [cd], [cd_desc_txt], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_ethnicity], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex], [electronic_ind], [person_parent_uid], [edx_ind]) VALUES (@dbo_Entity_entity_uid_3, N'2026-05-26T13:36:10.280', @elruser_id, N'PRV', N'Provider', N'2026-05-26T13:36:10.280', @elruser_id, @dbo_Person_local_id_2, N'ACTIVE', N'2026-05-26T13:36:10.280', N'A', N'2026-05-26T13:36:10.280', N'Sarah', N'Sample', 1, N'2026-05-26T13:36:10.070', N'2026-05-26T13:36:10.070', N'2026-05-26T13:36:10.070', N'2026-05-26T13:36:10.070', N'2026-05-26T00:00:00', N'Y', @dbo_Entity_entity_uid_3, N'Y');
-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd], [status_cd], [status_time]) VALUES (@dbo_Entity_entity_uid_3, 1, N'Add', N'2026-05-26T13:36:10.070', @elruser_id, N'Sarah', N'S600', N'2026-05-26T13:36:10.070', @elruser_id, N'Sample', N'S514', N'L', N'A', N'2026-05-26T13:36:10.293');
-- dbo.Entity_id
-- step: 1
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [assigning_authority_cd], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid_3, 1, N'2026-05-26T13:36:10.070', N'99D9999999', N'CDC TEST LAB', N'ACTIVE', N'9999999999', N'A', N'2026-05-26T13:36:10.297', N'PRN', N'Provider Registration Number', N'2026-05-26T13:36:10.070', N'CLIA');
-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt], [cntry_cd], [record_status_cd], [record_status_time], [street_addr1], [street_addr2], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_3, N'2026-05-26T13:36:10.097', @superuser_id, N'PH', N'404', N'ACTIVE', N'2026-05-26T13:36:10.097', N'', N' ', N'1');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [cd_desc_txt], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid_3, @dbo_Postal_locator_postal_locator_uid_3, N'O', N'Office', N'PST', N'2026-05-26T13:36:10.280', @elruser_id, N'ACTIVE', N'2026-05-26T13:36:10.280', N'A', N'2026-05-26T13:36:10.280', N'WP', 1);
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_4, N'ORG');
-- dbo.Organization
-- step: 1
INSERT INTO [dbo].[Organization] ([organization_uid], [add_time], [add_user_id], [cd], [cd_desc_txt], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [standard_industry_class_cd], [standard_industry_desc_txt], [status_cd], [status_time], [display_nm], [version_ctrl_nbr], [electronic_ind]) VALUES (@dbo_Entity_entity_uid_4, N'2026-05-26T13:36:10.310', @elruser_id, N'LAB', N'Laboratory', N'2026-05-26T13:36:10.310', @elruser_id, @dbo_Organization_local_id, N'ACTIVE', N'2026-05-26T13:36:10.310', N'CLIA', N'CDC TEST LAB', N'A', N'2026-05-26T13:36:10.310', N'CDC TEST LAB', 1, N'Y');
-- dbo.Organization_name
-- step: 1
INSERT INTO [dbo].[Organization_name] ([organization_uid], [organization_name_seq], [nm_txt], [nm_use_cd]) VALUES (@dbo_Entity_entity_uid_4, 1, N'CDC TEST LAB', N'L');
-- dbo.Entity_id
-- step: 1
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [assigning_authority_cd], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_4, 1, N'CLIA', N'Clinical Laboratory Improvement Amendment', N'ACTIVE', N'99D9999999', N'A', N'2026-05-26T13:36:10.320', N'FI', N'Facility Identifier');
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_5, N'ORG');
-- dbo.Organization
-- step: 1
INSERT INTO [dbo].[Organization] ([organization_uid], [add_time], [add_user_id], [cd], [cd_desc_txt], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [standard_industry_class_cd], [standard_industry_desc_txt], [status_cd], [status_time], [display_nm], [version_ctrl_nbr], [electronic_ind]) VALUES (@dbo_Entity_entity_uid_5, N'2026-05-26T13:36:10.323', @elruser_id, N'OTH', N'Other', N'2026-05-26T13:36:10.323', @elruser_id, @dbo_Organization_local_id_2, N'ACTIVE', N'2026-05-26T13:36:10.323', N'621399', N'Offices of Misc. Health Providers', N'A', N'2026-05-26T13:36:10.323', N'Republic Records', 1, N'Y');
-- dbo.Organization_name
-- step: 1
INSERT INTO [dbo].[Organization_name] ([organization_uid], [organization_name_seq], [nm_txt], [nm_use_cd]) VALUES (@dbo_Entity_entity_uid_5, 0, N'Republic Records', N'L');
-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [cntry_cd], [record_status_cd], [record_status_time], [street_addr1], [street_addr2]) VALUES (@dbo_Postal_locator_postal_locator_uid_4, N'2026-05-26T13:36:10.097', @elruser_id, N'', N'ACTIVE', N'2026-05-26T13:36:10.097', N'CDC TEST CLINIC', N' ');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [cd_desc_txt], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid_5, @dbo_Postal_locator_postal_locator_uid_4, N'O', N'Office', N'PST', N'2026-05-26T13:36:10.323', @elruser_id, N'ACTIVE', N'2026-05-26T13:36:10.323', N'A', N'2026-05-26T13:36:10.323', N'WP', 1);
-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_3, N'2026-05-26T13:36:10.097', @elruser_id, N'0.0', N'404-639-3311', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [cd_desc_txt], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid_5, @dbo_Tele_locator_tele_locator_uid_3, N'PH', N'PHONE', N'TELE', N'2026-05-26T13:36:10.323', @elruser_id, N'ACTIVE', N'2026-05-26T13:36:10.323', N'A', N'2026-05-26T13:36:10.323', N'WP', 1);
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid, N'OBS', N'EVN');
-- dbo.Observation
-- step: 1
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [effective_from_time], [electronic_ind], [last_chg_time], [last_chg_user_id], [local_id], [obs_domain_cd], [obs_domain_cd_st_1], [record_status_cd], [record_status_time], [status_cd], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [rpt_to_state_time]) VALUES (@dbo_Act_act_uid, N'2026-05-13T09:00:00', N'2026-05-26T13:36:10.447', @elruser_id, N'82195-9', N'Gastrointestinal pathogens panel - Stool by NAA with probe detection', N'LN', N'LOINC', N'LabReport', N'2026-05-13T07:30:00', N'Y', N'2026-05-26T13:36:10.447', @elruser_id, @dbo_Observation_local_id, N'LabReport', N'Order', N'UNPROCESSED', N'2026-05-26T13:36:10.447', N'N', 4, N'T', 1, N'2026-05-26T13:36:10.070');
-- dbo.Act_id
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_cd], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, 1, N'CLIA', N'Clinical Laboratory Improvement Amendment', N'ACTIVE', N'ELR-STEC-0001', N'A', N'2026-05-26T13:36:10.457', N'MCID', N'Message Control ID');
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_cd], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, 2, N'CLIA', N'Clinical Laboratory Improvement Amendment', N'ACTIVE', N'LAB-STEC-20260520-001', N'A', N'2026-05-26T13:36:10.460', N'FN', N'Filler Number');
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_2, N'OBS', N'EVN');
-- dbo.Observation
-- step: 1
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [electronic_ind], [local_id], [obs_domain_cd_st_1], [status_cd], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_2, N'2026-05-13T09:00:00', N'82203-1', N'Shiga-toxin-producing E coli stx1/stx2 [Presence] in Stool by NAA with probe detection', N'LN', N'LOINC', N'LabReport', N'Y', @dbo_Observation_local_id_2, N'Result', N'N', 4, N'T', 1);
-- dbo.Act_id
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_cd], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_2, 1, N'99D9999999', N'CDC TEST LAB', N'ACTIVE', N'ELR-STEC-0001', N'A', N'2026-05-26T13:36:10.470', N'MCID', N'Message Control ID');
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_cd], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_2, 2, N'99D9999999', N'CDC TEST LAB', N'ACTIVE', N'LAB-STEC-20260520-001', N'A', N'2026-05-26T13:36:10.470', N'FN', N'Filler Number');
-- dbo.Obs_value_coded
-- step: 1
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code], [code_system_cd], [display_name], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd], [alt_cd_system_desc_txt]) VALUES (@dbo_Act_act_uid_2, N'260373001', N'SCT', N'Detected', N'DET', N'LOCAL', N'L', N'LOCAL');
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_6, N'MAT');
-- dbo.Material
-- step: 1
INSERT INTO [dbo].[Material] ([material_uid], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid_6, N'Add', N'2026-05-26T13:36:10.483', @elruser_id, N'119339001', N'Stool specimen (specimen)', N'2026-05-26T13:36:10.483', @elruser_id, @dbo_Material_local_id, N'ACTIVE', N'2026-05-26T13:36:10.483', N'A', N'2026-05-26T13:36:10.483', 1);
-- dbo.Entity_id
-- step: 1
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [assigning_authority_cd], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid_6, 1, N'2026-05-26T13:36:10.070', N'2.16.840.1.113883.19.3.2.1', N'TEST_ELR_APP', N'ACTIVE', N'SPM-STEC-20260520-001', N'A', N'2026-05-26T13:36:10.497', N'SPC', N'Specimen', N'2026-05-26T13:36:10.070', N'ISO');
-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_reason_cd], [add_time], [add_user_id], [cd], [last_chg_time], [record_status_cd], [status_cd], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Act_act_uid, N'AUT', N'OBS', N'because', N'2026-05-26T13:36:10.070', @elruser_id, N'SF', N'2026-05-26T13:36:10.070', N'ACTIVE', N'A', N'ORG', N'Author');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_user_id], [cd], [record_status_cd], [status_cd], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Act_act_uid, N'PATSBJ', N'OBS', @superuser_id, N'PAT', N'ACTIVE', N'A', N'PSN', N'Patient Subject');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_reason_cd], [add_time], [add_user_id], [cd], [last_chg_time], [record_status_cd], [status_cd], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_5, @dbo_Act_act_uid, N'ORD', N'OBS', N'because', N'2026-05-26T13:36:10.070', @elruser_id, N'OP', N'2026-05-26T13:36:10.070', N'ACTIVE', N'A', N'ORG', N'Orderer');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_reason_cd], [add_time], [add_user_id], [cd], [last_chg_time], [record_status_cd], [status_cd], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_6, @dbo_Act_act_uid, N'SPC', N'OBS', N'because', N'2026-05-26T13:36:10.070', @elruser_id, N'NI', N'2026-05-26T13:36:10.070', N'ACTIVE', N'A', N'MAT', N'Specimen');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_reason_cd], [add_time], [add_user_id], [cd], [last_chg_time], [record_status_cd], [status_cd], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_3, @dbo_Act_act_uid, N'ORD', N'OBS', N'because', N'2026-05-26T13:36:10.070', @elruser_id, N'OP', N'2026-05-26T13:36:10.070', N'ACTIVE', N'A', N'PSN', N'Orderer');
-- dbo.Act_relationship
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [sequence_nbr], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_2, N'COMP', N'2026-05-26T13:36:10.070', N'2026-05-26T13:36:10.070', N'ACTIVE', N'2026-05-26T13:36:10.070', 1, N'OBS', N'A', N'2026-05-26T13:36:10.513', N'OBS', N'Has Component');
-- dbo.Role
-- step: 1
INSERT INTO [dbo].[Role] ([subject_entity_uid], [cd], [role_seq], [add_reason_cd], [add_time], [cd_desc_txt], [effective_from_time], [effective_to_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [scoping_class_cd], [status_cd], [status_time]) VALUES (@dbo_Entity_entity_uid_5, N'OP', 1, N'because', N'2026-05-26T13:36:10.520', N'Order Provider', N'2026-05-26T13:36:10.520', N'2026-05-26T13:36:10.520', N'2026-05-26T13:36:10.517', @elruser_id, N'ACTIVE', N'2026-05-26T13:36:10.517', N'HCFAC', N'A', N'2026-05-26T13:36:10.517');
-- step: 1
INSERT INTO [dbo].[Role] ([subject_entity_uid], [cd], [role_seq], [add_time], [cd_desc_txt], [effective_from_time], [effective_to_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_4, N'SF', 1, N'2026-05-26T13:36:10.523', N'Sending Facility', N'2026-05-26T13:36:10.523', N'2026-05-26T13:36:10.523', N'2026-05-26T13:36:10.523', @elruser_id, N'ACTIVE', N'2026-05-26T13:36:10.523', N'A', N'2026-05-26T13:36:10.523', N'HCFAC');
-- step: 1
INSERT INTO [dbo].[Role] ([subject_entity_uid], [cd], [role_seq], [add_reason_cd], [add_time], [cd_desc_txt], [effective_from_time], [effective_to_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_2, N'PAT', 1, N'because', N'2026-05-26T13:36:10.523', N'PATIENT', N'2026-05-26T13:36:10.523', N'2026-05-26T13:36:10.523', N'2026-05-26T13:36:10.523', @elruser_id, N'ACTIVE', N'2026-05-26T13:36:10.523', N'A', N'2026-05-26T13:36:10.523', N'PATIENT');
-- step: 1
INSERT INTO [dbo].[Role] ([subject_entity_uid], [cd], [role_seq], [add_time], [cd_desc_txt], [effective_from_time], [effective_to_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [scoping_class_cd], [scoping_entity_uid], [scoping_role_cd], [scoping_role_seq], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_6, N'NI', 1, N'2026-05-26T13:36:10.527', N'No Information Given', N'2026-05-26T13:36:10.527', N'2026-05-26T13:36:10.527', N'2026-05-26T13:36:10.523', @elruser_id, N'ACTIVE', N'2026-05-26T13:36:10.523', N'PATIENT', @dbo_Entity_entity_uid_2, N'PATIENT', 1, N'A', N'2026-05-26T13:36:10.523', N'MAT');
-- step: 1
INSERT INTO [dbo].[Role] ([subject_entity_uid], [cd], [role_seq], [add_reason_cd], [add_time], [cd_desc_txt], [effective_from_time], [effective_to_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [scoping_class_cd], [scoping_entity_uid], [scoping_role_cd], [scoping_role_seq], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_3, N'OP', 1, N'because', N'2026-05-26T13:36:10.527', N'Order Provider', N'2026-05-26T13:36:10.527', N'2026-05-26T13:36:10.527', N'2026-05-26T13:36:10.527', @elruser_id, N'ACTIVE', N'2026-05-26T13:36:10.527', N'PAT', @dbo_Entity_entity_uid_2, N'PAT', 1, N'A', N'2026-05-26T13:36:10.527', N'PRV');
-- dbo.EDX_Document
-- step: 1
INSERT INTO [dbo].[EDX_Document] ([act_uid], [payload], [record_status_cd], [record_status_time], [add_time], [doc_type_cd], [nbs_document_metadata_uid]) OUTPUT INSERTED.[EDX_Document_uid] INTO @dbo_EDX_Document_EDX_Document_uid_output ([value]) VALUES (@dbo_Act_act_uid, N'<Container xmlns="http://www.cdc.gov/NEDSS"><HL7LabReport><HL7MSH><FieldSeparator>|</FieldSeparator><EncodingCharacters>^~\&amp;</EncodingCharacters><SendingApplication><HL7NamespaceID>TEST_ELR_APP</HL7NamespaceID><HL7UniversalID>2.16.840.1.113883.19.3.2.1</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></SendingApplication><SendingFacility><HL7NamespaceID>CDC TEST LAB</HL7NamespaceID><HL7UniversalID>99D9999999</HL7UniversalID><HL7UniversalIDType>CLIA</HL7UniversalIDType></SendingFacility><ReceivingApplication><HL7NamespaceID>NBS</HL7NamespaceID><HL7UniversalID>2.16.840.1.113883.19.4.1</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></ReceivingApplication><ReceivingFacility><HL7NamespaceID>PUBLIC HEALTH</HL7NamespaceID><HL7UniversalID>2.16.840.1.113883.19.4.2</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></ReceivingFacility><DateTimeOfMessage><year>2026</year><month>05</month><day>20</day><hours>09</hours><minutes>00</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></DateTimeOfMessage><Security/><MessageType><MessageCode>ORU</MessageCode><TriggerEvent>R01</TriggerEvent><MessageStructure>ORU_R01</MessageStructure></MessageType><MessageControlID>ELR-STEC-0001</MessageControlID><ProcessingID><HL7ProcessingID>T</HL7ProcessingID><HL7ProcessingMode/></ProcessingID><VersionID><HL7VersionID>2.5.1</HL7VersionID></VersionID><AcceptAcknowledgmentType>AL</AcceptAcknowledgmentType><ApplicationAcknowledgmentType>NE</ApplicationAcknowledgmentType><CountryCode>USA</CountryCode><CharacterSet/><MessageProfileIdentifier><HL7EntityIdentifier>PHLabReport-Ack</HL7EntityIdentifier><HL7NamespaceID/><HL7UniversalID>2.16.840.1.113883.9.10</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></MessageProfileIdentifier></HL7MSH><HL7SoftwareSegment><SoftwareVendorOrganization><HL7OrganizationName>TEST ELR GENERATOR</HL7OrganizationName><HL7OrganizationNameTypeCode>L</HL7OrganizationNameTypeCode><HL7IDNumber/><HL7CheckDigit/></SoftwareVendorOrganization><SoftwareCertifiedVersionOrReleaseNumber>1.0</SoftwareCertifiedVersionOrReleaseNumber><SoftwareProductName>CDC TEST DATA</SoftwareProductName><SoftwareBinaryID>1.0</SoftwareBinaryID><SoftwareProductInformation/></HL7SoftwareSegment><HL7PATIENT_RESULT><PATIENT><PatientIdentification><SetIDPID><HL7SequenceID>1</HL7SequenceID></SetIDPID><PatientIdentifierList><HL7IDNumber>CDC-TEST-PATIENT-001</HL7IDNumber><HL7AssigningAuthority><HL7NamespaceID>TEST_ELR_APP</HL7NamespaceID><HL7UniversalID>2.16.840.1.113883.19.3.2.1</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></HL7AssigningAuthority><HL7IdentifierTypeCode>PI</HL7IdentifierTypeCode></PatientIdentifierList><PatientName><HL7FamilyName><HL7Surname>Swift</HL7Surname></HL7FamilyName><HL7GivenName>Taylor</HL7GivenName><HL7Degree/></PatientName><DateTimeOfBirth><year>1990</year><month>01</month><day>01</day></DateTimeOfBirth><AdministrativeSex>F</AdministrativeSex><Race><HL7Identifier>2106-3</HL7Identifier><HL7Text>White</HL7Text><HL7NameofCodingSystem>CDCREC</HL7NameofCodingSystem></Race><PatientAddress><HL7StreetAddress><HL7StreetOrMailingAddress>1600 Clifton Rd NE</HL7StreetOrMailingAddress></HL7StreetAddress><HL7City>Atlanta</HL7City><HL7StateOrProvince>GA</HL7StateOrProvince><HL7ZipOrPostalCode>30333</HL7ZipOrPostalCode><HL7Country>USA</HL7Country><HL7AddressType>H</HL7AddressType></PatientAddress><PhoneNumberHome><HL7TelecommunicationUseCode>PRN</HL7TelecommunicationUseCode><HL7TelecommunicationEquipmentType>PH</HL7TelecommunicationEquipmentType><HL7CountryCode><HL7Numeric>1</HL7Numeric></HL7CountryCode><HL7AreaCityCode><HL7Numeric>404</HL7Numeric></HL7AreaCityCode><HL7LocalNumber><HL7Numeric>6393311</HL7Numeric></HL7LocalNumber><HL7Extension/></PhoneNumberHome><SSNNumberPatient/><EthnicGroup><HL7Identifier>N</HL7Identifier><HL7Text>Not Hispanic or Latino</HL7Text><HL7NameofCodingSystem>HL70189</HL7NameofCodingSystem></EthnicGroup><BirthOrder/></PatientIdentification></PATIENT><ORDER_OBSERVATION><CommonOrder><OrderControl>RE</OrderControl><FillerOrderNumber><HL7EntityIdentifier>ORD-STEC-20260520-001</HL7EntityIdentifier><HL7NamespaceID>TEST_ELR_APP</HL7NamespaceID><HL7UniversalID>2.16.840.1.113883.19.3.2.1</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></FillerOrderNumber><OrderStatus>A</OrderStatus><DateTimeOfTransaction><year>2026</year><month>05</month><day>20</day><hours>07</hours><minutes>30</minutes><seconds>00</seconds><gmtOffset/></DateTimeOfTransaction><OrderingProvider><HL7IDNumber>9999999999</HL7IDNumber><HL7FamilyName><HL7Surname>Sample</HL7Surname></HL7FamilyName><HL7GivenName>Sarah</HL7GivenName><HL7NameTypeCode>NPI</HL7NameTypeCode><HL7IdentifierTypeCode/></OrderingProvider><OrderingFacilityName><HL7OrganizationName>Republic Records</HL7OrganizationName><HL7IDNumber/><HL7CheckDigit/></OrderingFacilityName><OrderingFacilityAddress><HL7StreetAddress><HL7StreetOrMailingAddress>CDC TEST CLINIC</HL7StreetOrMailingAddress></HL7StreetAddress><HL7City/><HL7StateOrProvince/><HL7ZipOrPostalCode/><HL7Country/><HL7AddressType/></OrderingFacilityAddress><OrderingFacilityPhoneNumber><HL7TelecommunicationUseCode/><HL7TelecommunicationEquipmentType>Atlanta</HL7TelecommunicationEquipmentType><HL7CountryCode><HL7Numeric>30333</HL7Numeric></HL7CountryCode><HL7AreaCityCode><HL7Numeric>404</HL7Numeric></HL7AreaCityCode><HL7LocalNumber><HL7Numeric>6393311</HL7Numeric></HL7LocalNumber><HL7Extension/></OrderingFacilityPhoneNumber><OrderingProviderAddress><HL7StreetAddress><HL7StreetOrMailingAddress/></HL7StreetAddress><HL7City>PH</HL7City><HL7StateOrProvince/><HL7ZipOrPostalCode>1</HL7ZipOrPostalCode><HL7Country>404</HL7Country><HL7AddressType>6393311</HL7AddressType></OrderingProviderAddress></CommonOrder><ObservationRequest><SetIDOBR><HL7SequenceID>1</HL7SequenceID></SetIDOBR><FillerOrderNumber><HL7EntityIdentifier>LAB-STEC-20260520-001</HL7EntityIdentifier><HL7NamespaceID>CDC TEST LAB</HL7NamespaceID><HL7UniversalID>99D9999999</HL7UniversalID><HL7UniversalIDType>CLIA</HL7UniversalIDType></FillerOrderNumber><UniversalServiceIdentifier><HL7Identifier>82195-9</HL7Identifier><HL7Text>Gastrointestinal pathogens panel - Stool by NAA with probe detection</HL7Text><HL7NameofCodingSystem>LN</HL7NameofCodingSystem></UniversalServiceIdentifier><ObservationDateTime><year>2026</year><month>05</month><day>13</day><hours>07</hours><minutes>30</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></ObservationDateTime><SpecimenReceivedDateTime><year>2026</year><month>05</month><day>13</day><hours>08</hours><minutes>45</minutes><seconds>00</seconds><gmtOffset/></SpecimenReceivedDateTime><OrderingProvider><HL7IDNumber>9999999999</HL7IDNumber><HL7FamilyName><HL7Surname>Sample</HL7Surname></HL7FamilyName><HL7GivenName>Sarah</HL7GivenName><HL7NameTypeCode>NPI</HL7NameTypeCode><HL7IdentifierTypeCode/></OrderingProvider><ResultsRptStatusChngDateTime><year>2026</year><month>05</month><day>13</day><hours>09</hours><minutes>00</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></ResultsRptStatusChngDateTime><ResultStatus>P</ResultStatus></ObservationRequest><PatientResultOrderObservation><OBSERVATION><ObservationResult><SetIDOBX><HL7SequenceID>1</HL7SequenceID></SetIDOBX><ValueType>CWE</ValueType><ObservationIdentifier><HL7Identifier>82203-1</HL7Identifier><HL7Text>Shiga-toxin-producing E coli stx1/stx2 [Presence] in Stool by NAA with probe detection</HL7Text><HL7NameofCodingSystem>LN</HL7NameofCodingSystem></ObservationIdentifier><ObservationValue>260373001^Detected^SCT^DET^Detected^L</ObservationValue><Probability/><ObservationResultStatus>P</ObservationResultStatus><DateTimeOftheObservation><year>2026</year><month>05</month><day>13</day><hours>07</hours><minutes>30</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></DateTimeOftheObservation><DateTimeOftheAnalysis><year>2026</year><month>05</month><day>13</day><hours>09</hours><minutes>00</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></DateTimeOftheAnalysis></ObservationResult></OBSERVATION></PatientResultOrderObservation><PatientResultOrderSPMObservation><SPECIMEN><SPECIMEN><SetIDSPM><HL7SequenceID>1</HL7SequenceID></SetIDSPM><SpecimenID><HL7PlacerAssignedIdentifier><HL7EntityIdentifier/></HL7PlacerAssignedIdentifier><HL7FillerAssignedIdentifier><HL7EntityIdentifier>SPM-STEC-20260520-001</HL7EntityIdentifier><HL7NamespaceID>TEST_ELR_APP</HL7NamespaceID><HL7UniversalID>2.16.840.1.113883.19.3.2.1</HL7UniversalID><HL7UniversalIDType>ISO</HL7UniversalIDType></HL7FillerAssignedIdentifier></SpecimenID><SpecimenType><HL7Identifier>119339001</HL7Identifier><HL7Text>Stool specimen (specimen)</HL7Text><HL7NameofCodingSystem>SCT</HL7NameofCodingSystem></SpecimenType><SpecimenCollectionDateTime><HL7RangeStartDateTime><year>2026</year><month>05</month><day>13</day><hours>07</hours><minutes>30</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></HL7RangeStartDateTime></SpecimenCollectionDateTime><SpecimenReceivedDateTime><year>2026</year><month>05</month><day>13</day><hours>08</hours><minutes>45</minutes><seconds>00</seconds><gmtOffset>-0500</gmtOffset></SpecimenReceivedDateTime></SPECIMEN></SPECIMEN></PatientResultOrderSPMObservation></ORDER_OBSERVATION></HL7PATIENT_RESULT></HL7LabReport></Container>', N'ACTIVE', N'2026-05-26T13:36:10.070', N'2026-05-26T13:36:10.070', N'11648804', 1005);
SELECT TOP 1 @dbo_EDX_Document_EDX_Document_uid = [value] FROM @dbo_EDX_Document_EDX_Document_uid_output;
-- dbo.EDX_activity_log
-- step: 1
INSERT INTO [dbo].[EDX_activity_log] ([source_uid], [target_uid], [doc_type], [record_status_cd], [record_status_time], [exception_txt], [imp_exp_ind_cd], [source_type_cd], [target_type_cd], [business_obj_localId], [source_nm], [Message_id], [Entity_nm], [Accession_nbr]) OUTPUT INSERTED.[edx_activity_log_uid] INTO @dbo_EDX_activity_log_edx_activity_log_uid_output ([value]) VALUES (10000011, 10009384, N'11648804', N'Success', N'2026-05-26T13:36:10.560', N'Jurisdiction and/or Program Area could not be derived.  The Lab Report is logged in Documents Requiring Security Assignment queue.', N'I', N'INT', N'LAB', N'OBS10001013GA01', N'CDC TEST LAB', N'ELR-STEC-0001', N'Taylor Swift', N'LAB-STEC-20260520-001');
SELECT TOP 1 @dbo_EDX_activity_log_edx_activity_log_uid = [value] FROM @dbo_EDX_activity_log_edx_activity_log_uid_output;
-- dbo.EDX_activity_detail_log
-- step: 1
INSERT INTO [dbo].[EDX_activity_detail_log] ([edx_activity_log_uid], [record_id], [record_type], [record_nm], [log_type], [log_comment]) OUTPUT INSERTED.[edx_activity_detail_log_uid] INTO @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_output ([value]) VALUES (@dbo_EDX_activity_log_edx_activity_log_uid, N'10009372', N'Electronic Lab Report', N'ELR_IMPORT', N'Success', N'Patient match not found; New Patient created: Taylor Swift (UID: 10009372).');
SELECT TOP 1 @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid = [value] FROM @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_output;
-- step: 1
INSERT INTO [dbo].[EDX_activity_detail_log] ([edx_activity_log_uid], [record_id], [record_type], [record_nm], [log_type], [log_comment]) OUTPUT INSERTED.[edx_activity_detail_log_uid] INTO @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_2_output ([value]) VALUES (@dbo_EDX_activity_log_edx_activity_log_uid, N'OBS10001013GA01', N'Electronic Lab Report', N'ELR_IMPORT', N'Failure', N'Jurisdiction not derived.');
SELECT TOP 1 @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_2 = [value] FROM @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_2_output;
-- step: 1
INSERT INTO [dbo].[EDX_activity_detail_log] ([edx_activity_log_uid], [record_id], [record_type], [record_nm], [log_type], [log_comment]) OUTPUT INSERTED.[edx_activity_detail_log_uid] INTO @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_3_output ([value]) VALUES (@dbo_EDX_activity_log_edx_activity_log_uid, N'OBS10001013GA01', N'Electronic Lab Report', N'ELR_IMPORT', N'Failure', N'Program Area not derived.');
SELECT TOP 1 @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_3 = [value] FROM @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_3_output;
-- step: 1
INSERT INTO [dbo].[EDX_activity_detail_log] ([edx_activity_log_uid], [record_id], [record_type], [record_nm], [log_type], [log_comment]) OUTPUT INSERTED.[edx_activity_detail_log_uid] INTO @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_4_output ([value]) VALUES (@dbo_EDX_activity_log_edx_activity_log_uid, N'OBS10001013GA01', N'Electronic Lab Report', N'ELR_IMPORT', N'Success', N'Lab OBS10001013GA01 created and associated to Patient.');
SELECT TOP 1 @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_4 = [value] FROM @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_4_output;
-- step: 1
INSERT INTO [dbo].[EDX_activity_detail_log] ([edx_activity_log_uid], [record_id], [record_type], [record_nm], [log_type], [log_comment]) OUTPUT INSERTED.[edx_activity_detail_log_uid] INTO @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_5_output ([value]) VALUES (@dbo_EDX_activity_log_edx_activity_log_uid, N'OBS10001013GA01', N'Electronic Lab Report', N'ELR_IMPORT', N'Success', N'Document created and associated to Lab.');
SELECT TOP 1 @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_5 = [value] FROM @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_5_output;
-- step: 1
INSERT INTO [dbo].[EDX_activity_detail_log] ([edx_activity_log_uid], [record_id], [record_type], [record_nm], [log_type], [log_comment]) OUTPUT INSERTED.[edx_activity_detail_log_uid] INTO @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_6_output ([value]) VALUES (@dbo_EDX_activity_log_edx_activity_log_uid, N'OBS10001013GA01', N'Electronic Lab Report', N'ELR_IMPORT', N'Success', N'The Ethnicity code provided in the message is not found in the SRT database.  The code is saved to the NBS.');
SELECT TOP 1 @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_6 = [value] FROM @dbo_EDX_activity_detail_log_edx_activity_detail_log_uid_6_output;
-- dbo.EDX_activity_log
-- step: 1
UPDATE [dbo].[EDX_activity_log] SET [exception_txt] = N'Jurisdiction and/or Program Area could not be derived.  The Lab Report is logged in Documents Requiring Security Assignment queue.' WHERE [edx_activity_log_uid] = @dbo_EDX_activity_log_edx_activity_log_uid;
-- dbo.Observation
-- step: 1
UPDATE [dbo].[Observation] SET [jurisdiction_cd] = N'130004', [last_chg_time] = N'2026-05-26T13:37:00.107', [last_chg_user_id] = @superuser_id, [prog_area_cd] = N'GCD', [record_status_time] = N'2026-05-26T13:37:00.107', [program_jurisdiction_oid] = 1300400009, [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid;
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_7, N'PSN');
-- dbo.Person
-- step: 1
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [age_reported], [age_reported_unit_cd], [birth_time], [birth_time_calc], [cd], [curr_sex_cd], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_7, N'2026-05-26T13:38:45.340', @superuser_id, N'36', N'Y', N'1990-01-01T00:00:00', N'1990-01-01T00:00:00', N'PAT', N'F', N'2026-05-26T13:38:45.340', @superuser_id, @dbo_Person_local_id, N'ACTIVE', N'2026-05-26T13:38:45.340', N'A', N'2026-05-26T13:38:45.340', N'Taylor', N'Swift', 1, N'2026-05-26T00:00:00', N'N', @dbo_Entity_entity_uid);
-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [first_nm], [first_nm_sndx], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_7, 1, N'Add', N'2026-05-26T13:38:45.123', N'Taylor', N'T460', N'Swift', N'S130', N'L', N'ACTIVE', N'2026-05-26T13:38:45.123', N'A', N'2026-05-26T13:38:45.123', N'2026-05-26T00:00:00');
-- dbo.Person_race
-- step: 1
INSERT INTO [dbo].[Person_race] ([person_uid], [race_cd], [race_category_cd], [record_status_cd], [as_of_date]) VALUES (@dbo_Entity_entity_uid_7, N'2106-3', N'2106-3', N'ACTIVE', N'2026-05-26T00:00:00');
-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [city_desc_txt], [cntry_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [street_addr2], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_5, N'2026-05-26T13:38:45.123', N'Atlanta', N'840', N'ACTIVE', N'2026-05-26T13:38:45.123', N'13', N'1600 Clifton Rd NE', N'', N'30333');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_7, @dbo_Postal_locator_postal_locator_uid_5, N'H', N'PST', N'2026-05-26T13:38:45.340', @superuser_id, N'ACTIVE', N'2026-05-26T13:38:45.340', N'A', N'2026-05-26T13:38:45.340', N'H', 1, N'2026-05-26T00:00:00');
-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_4, N'2026-05-26T13:38:45.127', N'0', N'404-639-3311', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_7, @dbo_Tele_locator_tele_locator_uid_4, N'PH', N'TELE', N'2026-05-26T13:38:45.340', @superuser_id, N'ACTIVE', N'2026-05-26T13:38:45.340', N'A', N'2026-05-26T13:38:45.340', N'H', 1, N'2026-05-26T00:00:00');
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_3, N'OBS', N'EVN');
-- dbo.Observation
-- step: 1
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_system_cd], [group_level_cd], [local_id], [obs_domain_cd], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_3, N'INV_FORM_GEN', N'NBS', N'L1', @dbo_Observation_local_id_3, N'CLN', N'A', N'2026-05-26T13:38:45.143', 4, N'T', 1);
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_4, N'CASE', N'EVN');
-- dbo.Public_health_case
-- step: 1
INSERT INTO [dbo].[Public_health_case] ([public_health_case_uid], [activity_from_time], [add_time], [add_user_id], [case_type_cd], [cd], [cd_desc_txt], [effective_duration_amt], [effective_duration_unit_cd], [group_case_cnt], [investigation_status_cd], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [mmwr_week], [mmwr_year], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [prog_area_cd], [record_status_cd], [record_status_time], [rpt_form_cmplt_time], [status_cd], [txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [contact_inv_txt]) VALUES (@dbo_Act_act_uid_4, N'2026-05-14T00:00:00', N'2026-05-26T13:38:45.407', @superuser_id, N'I', N'11563', N'Shiga toxin-producing Escherichia coli (STEC)', N'', N'D', 1, N'O', N'130004', N'2026-05-26T13:38:45.407', @superuser_id, @dbo_Public_health_case_local_id, N'21', N'2026', N'', N'Y', N'GCD', N'OPEN', N'2026-05-26T13:38:45.407', N'2026-05-26T00:00:00', N'A', N'', 1300400009, N'T', 1, N'');
-- dbo.Confirmation_method
-- step: 1
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd]) VALUES (@dbo_Act_act_uid_4, N'NA');
-- dbo.Act_id
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid_4, 1, N'', N'A', N'2026-05-26T13:38:45.460', N'STATE');
-- dbo.Act_relationship
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_4, @dbo_Act_act_uid_3, N'PHCInvForm', N'2026-05-26T13:38:45.467', N'2026-05-26T13:38:45.467', N'ACTIVE', N'2026-05-26T13:38:45.467', N'OBS', N'A', N'2026-05-26T13:38:45.467', N'CASE', N'PHC Investigation Form');
-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_7, @dbo_Act_act_uid_4, N'SubjOfPHC', N'CASE', N'ACTIVE', N'A', N'2026-05-26T13:38:45.140', N'PSN', N'Subject Of Public Health Case');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_3, @dbo_Act_act_uid_4, N'PhysicianOfPHC', N'CASE', N'ACTIVE', N'A', N'2026-05-26T13:38:45.140', N'PSN', N'Physician of PHC');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Act_act_uid_4, N'OrgAsReporterOfPHC', N'CASE', N'ACTIVE', N'A', N'2026-05-26T13:38:45.140', N'ORG', N'Organization As Reporter Of PHC');
-- dbo.DF_sf_metadata_group
-- step: 1
INSERT INTO [dbo].[DF_sf_metadata_group] ([df_sf_metadata_group_uid], [group_name], [version_ctrl_nbr]) VALUES (@dbo_DF_sf_metadata_group_df_sf_metadata_group_uid, N'|10001722_10001730_10001754_10001762_10001769_10001779_10001790_10001794_10001808', 1);
-- dbo.DF_sf_mdata_field_group
-- step: 1
INSERT INTO [dbo].[DF_sf_mdata_field_group] ([df_sf_metadata_group_uid], [field_uid], [field_type], [version_ctrl_nbr]) VALUES (@dbo_DF_sf_metadata_group_df_sf_metadata_group_uid, 10001722, N'CustomSubform', 1);
-- step: 1
INSERT INTO [dbo].[DF_sf_mdata_field_group] ([df_sf_metadata_group_uid], [field_uid], [field_type], [version_ctrl_nbr]) VALUES (@dbo_DF_sf_metadata_group_df_sf_metadata_group_uid, 10001730, N'CustomSubform', 1);
-- step: 1
INSERT INTO [dbo].[DF_sf_mdata_field_group] ([df_sf_metadata_group_uid], [field_uid], [field_type], [version_ctrl_nbr]) VALUES (@dbo_DF_sf_metadata_group_df_sf_metadata_group_uid, 10001754, N'CustomSubform', 1);
-- step: 1
INSERT INTO [dbo].[DF_sf_mdata_field_group] ([df_sf_metadata_group_uid], [field_uid], [field_type], [version_ctrl_nbr]) VALUES (@dbo_DF_sf_metadata_group_df_sf_metadata_group_uid, 10001762, N'CustomSubform', 1);
-- step: 1
INSERT INTO [dbo].[DF_sf_mdata_field_group] ([df_sf_metadata_group_uid], [field_uid], [field_type], [version_ctrl_nbr]) VALUES (@dbo_DF_sf_metadata_group_df_sf_metadata_group_uid, 10001769, N'CustomSubform', 1);
-- step: 1
INSERT INTO [dbo].[DF_sf_mdata_field_group] ([df_sf_metadata_group_uid], [field_uid], [field_type], [version_ctrl_nbr]) VALUES (@dbo_DF_sf_metadata_group_df_sf_metadata_group_uid, 10001779, N'CustomSubform', 1);
-- step: 1
INSERT INTO [dbo].[DF_sf_mdata_field_group] ([df_sf_metadata_group_uid], [field_uid], [field_type], [version_ctrl_nbr]) VALUES (@dbo_DF_sf_metadata_group_df_sf_metadata_group_uid, 10001790, N'CustomSubform', 1);
-- step: 1
INSERT INTO [dbo].[DF_sf_mdata_field_group] ([df_sf_metadata_group_uid], [field_uid], [field_type], [version_ctrl_nbr]) VALUES (@dbo_DF_sf_metadata_group_df_sf_metadata_group_uid, 10001794, N'CustomSubform', 1);
-- step: 1
INSERT INTO [dbo].[DF_sf_mdata_field_group] ([df_sf_metadata_group_uid], [field_uid], [field_type], [version_ctrl_nbr]) VALUES (@dbo_DF_sf_metadata_group_df_sf_metadata_group_uid, 10001808, N'CustomSubform', 1);
-- dbo.Bus_obj_df_sf_mdata_group
-- step: 1
INSERT INTO [dbo].[Bus_obj_df_sf_mdata_group] ([business_object_uid], [version_ctrl_nbr], [df_sf_metadata_group_uid]) VALUES (@dbo_Bus_obj_df_sf_mdata_group_business_object_uid, 1, @dbo_DF_sf_metadata_group_df_sf_metadata_group_uid);
-- dbo.Act_relationship
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_4, @dbo_Act_act_uid, N'LabReport', N'2026-05-26T13:38:45.663', N'2026-05-26T13:38:45.663', @superuser_id, N'ACTIVE', N'2026-05-26T13:38:45.663', N'OBS', N'A', N'2026-05-26T13:38:45.663', N'CASE');
-- dbo.Person
-- step: 1
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-26T13:38:45.320', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-05-26T13:38:45.320', [status_time] = N'2026-05-26T13:38:45.320', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [edx_ind] = N'Y' WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Entity_locator_participation
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-26T13:38:45.320', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-05-26T13:38:45.320', [status_time] = N'2026-05-26T13:38:45.320' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-26T13:38:45.320', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-05-26T13:38:45.320', [status_time] = N'2026-05-26T13:38:45.320' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;
-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_5, N'2026-05-26T13:38:45.127', N'0', N'404-639-3311', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Tele_locator_tele_locator_uid_5, N'PH', N'TELE', N'2026-05-26T13:38:45.320', @superuser_id, N'ACTIVE', N'2026-05-26T13:38:45.320', N'A', N'2026-05-26T13:38:45.320', N'H', 1, N'2026-05-26T00:00:00');
-- dbo.Observation
-- step: 1
UPDATE [dbo].[Observation] SET [last_chg_time] = N'2026-05-26T13:38:45.680', [record_status_cd] = N'PROCESSED', [record_status_time] = N'2026-05-26T13:38:45.680', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid;
-- dbo.PublicHealthCaseFact
-- step: 1
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [cntry_cd], [curr_sex_cd], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [jurisdiction_cd], [mart_record_creation_time], [mmwr_week], [mmwr_year], [organizationName], [PAR_type_cd], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [providerName], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [rpt_form_cmplt_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [LASTUPDATE]) VALUES (@dbo_Act_act_uid_4, N'Y', 36, N'1990-01-01T00:00:00', N'1990-01-01T00:00:00', N'', N'I', N'Atlanta', N'NA', N'840', N'F', N'PST', N'2026-05-26T13:38:45.407', N'P', 1.0, N'O', N'130004', N'2026-05-26T13:38:53.587', 21, 2026, N'CDC TEST LAB', N'SubjOfPHC', N'Y', @dbo_Postal_locator_postal_locator_uid_5, N'PAT', @dbo_Entity_entity_uid_7, N'2026-05-26T13:38:45.407', N'11563', N'Shiga toxin-producing Escherichia coli (STEC)', N'Shiga toxin-producing Escherichia coli (STEC)', N'GCD', N'Sample, Sarah', N'2026-05-26T13:38:45.123', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'2026-05-26T00:00:00', N'T', N'Georgia', N'13', N'A', N'1600 Clifton Rd NE', N'H', N'30333', N'Swift, Taylor', N'Cobb County', N'2026-05-14T00:00:00', 1300400009, N'2026-05-26T13:38:45.407', 10009372, @dbo_Person_local_id, N'2026-05-26T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'UNITED STATES', N'Female', N'Open', N'Years', N'GCD', N'2026-05-26T13:38:45.407');
-- dbo.SubjectRaceInfo
-- step: 1
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_4, N'2106-3', N'2106-3');
