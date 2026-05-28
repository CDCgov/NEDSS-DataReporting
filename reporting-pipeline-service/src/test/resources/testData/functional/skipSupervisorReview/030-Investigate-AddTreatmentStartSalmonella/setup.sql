USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 1000006000;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 1000006001;
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 1000006002;
DECLARE @dbo_Tele_locator_tele_locator_uid_2 bigint = 1000006003;
DECLARE @dbo_Entity_entity_uid_2 bigint = 1000006004;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 1000006005;
DECLARE @dbo_Tele_locator_tele_locator_uid_3 bigint = 1000006006;
DECLARE @dbo_Tele_locator_tele_locator_uid_4 bigint = 1000006007;
DECLARE @dbo_Act_act_uid bigint = 1000006008;
DECLARE @dbo_Act_act_uid_2 bigint = 1000006009;
DECLARE @dbo_Act_act_uid_3 bigint = 1000006010;
DECLARE @dbo_Act_act_uid_4 bigint = 1000006011;
DECLARE @dbo_Act_act_uid_5 bigint = 1000006012;
DECLARE @dbo_Entity_entity_uid_3 bigint = 1000006013;
DECLARE @dbo_Entity_entity_uid_4 bigint = 1000006014;
DECLARE @dbo_Postal_locator_postal_locator_uid_3 bigint = 1000006015;
DECLARE @dbo_Tele_locator_tele_locator_uid_5 bigint = 1000006016;
DECLARE @dbo_Act_act_uid_6 bigint = 1000006017;
DECLARE @dbo_Act_act_uid_7 bigint = 1000006018;
DECLARE @dbo_Act_act_uid_8 bigint = 1000006019;
DECLARE @dbo_Act_act_uid_9 bigint = 1000006020;
DECLARE @dbo_Act_act_uid_10 bigint = 1000006021;
DECLARE @dbo_Act_act_uid_11 bigint = 1000006022;
DECLARE @dbo_Act_act_uid_12 bigint = 1000006023;
DECLARE @dbo_Act_act_uid_13 bigint = 1000006024;
DECLARE @dbo_Act_act_uid_14 bigint = 1000006025;
DECLARE @dbo_Act_act_uid_15 bigint = 1000006026;
DECLARE @dbo_Bus_obj_df_sf_mdata_group_business_object_uid bigint = @dbo_Act_act_uid_15;
DECLARE @dbo_Act_act_uid_16 bigint = 1000006028;
DECLARE @dbo_Act_act_uid_17 bigint = 1000006029;
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

-- STEP 3: InvestigateSalmonella
-- dbo.Observation
-- step: 3
UPDATE [dbo].[Observation] SET [record_status_cd] = N'ACTIVE', [record_status_time] = N'2026-04-23T14:33:26.127', [status_cd] = N'D', [status_time] = N'2026-04-23T14:33:26.127', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid_6;
-- step: 3
UPDATE [dbo].[Observation] SET [record_status_cd] = N'ACTIVE', [record_status_time] = N'2026-04-23T14:33:26.127', [status_cd] = N'D', [status_time] = N'2026-04-23T14:33:26.127', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid_7;
-- step: 3
UPDATE [dbo].[Observation] SET [record_status_cd] = N'ACTIVE', [record_status_time] = N'2026-04-23T14:33:26.127', [status_cd] = N'D', [status_time] = N'2026-04-23T14:33:26.127', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid_8;
-- step: 3
UPDATE [dbo].[Observation] SET [record_status_cd] = N'ACTIVE', [record_status_time] = N'2026-04-23T14:33:26.127', [status_cd] = N'D', [status_time] = N'2026-04-23T14:33:26.127', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid_9;
-- step: 3
UPDATE [dbo].[Observation] SET [record_status_cd] = N'ACTIVE', [record_status_time] = N'2026-04-23T14:33:26.127', [status_cd] = N'D', [status_time] = N'2026-04-23T14:33:26.127', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid_10;
-- step: 3
UPDATE [dbo].[Observation] SET [record_status_cd] = N'ACTIVE', [record_status_time] = N'2026-04-23T14:33:26.127', [status_cd] = N'D', [status_time] = N'2026-04-23T14:33:26.127', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid_11;
-- step: 3
UPDATE [dbo].[Observation] SET [record_status_cd] = N'ACTIVE', [record_status_time] = N'2026-04-23T14:33:26.127', [status_cd] = N'D', [status_time] = N'2026-04-23T14:33:26.127', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid_12;
-- step: 3
UPDATE [dbo].[Observation] SET [record_status_cd] = N'ACTIVE', [record_status_time] = N'2026-04-23T14:33:26.127', [status_cd] = N'D', [status_time] = N'2026-04-23T14:33:26.127', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid_13;
-- dbo.state_defined_field_data
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008091, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.327', N'PHC', N'Y|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008092, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.330', N'PHC', N'Y|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008093, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.330', N'PHC', N'Y|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008024, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.333', N'PHC', N'08|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008026, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.333', N'PHC', N'71783008|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008027, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.333', N'PHC', N'03/05/2026', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008028, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.333', N'PHC', N'03/07/2026', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008017, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.337', N'PHC', N'International', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008019, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.337', N'PHC', N'52|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008020, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.337', N'PHC', N'C0683901|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008021, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.340', N'PHC', N'03/01/2026', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008022, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.340', N'PHC', N'03/03/2026', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008023, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.343', N'PHC', N'Domestic', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008009, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.343', N'PHC', N'Y|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008010, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.343', N'PHC', N'03/21/2026', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008011, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.347', N'PHC', N'Taco Bell', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008013, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.347', N'PHC', N'Y|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008015, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.347', N'PHC', N'C0085936|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008001, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.347', N'PHC', N'Y|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008002, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.347', N'PHC', N'N|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008003, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.350', N'PHC', N'Y|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008004, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.350', N'PHC', N'DCT005|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008006, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.350', N'PHC', N'Y|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008007, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.353', N'PHC', N'N|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008040, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.353', N'PHC', N'PW|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008041, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.357', N'PHC', N'FLT|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008043, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.357', N'PHC', N'Y|', 2);
-- step: 3
INSERT INTO [dbo].[state_defined_field_data] ([ldf_uid], [business_object_uid], [add_time], [business_object_nm], [ldf_value], [version_ctrl_nbr]) VALUES (10008037, @dbo_Bus_obj_df_sf_mdata_group_business_object_uid, N'2026-04-23T14:33:26.357', N'PHC', N'MUNI|', 2);
-- dbo.Person
-- step: 3
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-23T14:33:26.213', [record_status_time] = N'2026-04-23T14:33:26.213', [status_time] = N'2026-04-23T14:33:26.213', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Entity_locator_participation
-- step: 3
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-23T14:33:26.213', [record_status_time] = N'2026-04-23T14:33:26.213', [status_time] = N'2026-04-23T14:33:26.213' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 3
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-23T14:33:26.213', [record_status_time] = N'2026-04-23T14:33:26.213', [status_time] = N'2026-04-23T14:33:26.213' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
-- step: 3
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-23T14:33:26.213', [record_status_time] = N'2026-04-23T14:33:26.213', [status_time] = N'2026-04-23T14:33:26.213' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;
-- dbo.Person
-- step: 3
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-04-23T14:33:26.227', [record_status_time] = N'2026-04-23T14:33:26.227', [status_time] = N'2026-04-23T14:33:26.227', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid_4;
-- dbo.Person_name
-- step: 3
UPDATE [dbo].[Person_name] SET [last_chg_time] = N'2026-04-23T14:33:26.127' WHERE [person_uid] = @dbo_Entity_entity_uid_4 AND [person_name_seq] = 1;
-- dbo.Postal_locator
-- step: 3
UPDATE [dbo].[Postal_locator] SET [last_chg_time] = N'2026-04-23T14:33:26.127' WHERE [postal_locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;
-- dbo.Entity_locator_participation
-- step: 3
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-23T14:33:26.227', [record_status_time] = N'2026-04-23T14:33:26.227', [status_time] = N'2026-04-23T14:33:26.227' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid_3;
-- dbo.Tele_locator
-- step: 3
UPDATE [dbo].[Tele_locator] SET [add_time] = N'2026-04-23T14:33:26.127', [last_chg_time] = N'2026-04-23T14:33:26.127' WHERE [tele_locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;
-- dbo.Entity_locator_participation
-- step: 3
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-04-23T14:33:26.227', [record_status_time] = N'2026-04-23T14:33:26.227', [status_time] = N'2026-04-23T14:33:26.227' WHERE [entity_uid] = @dbo_Entity_entity_uid_4 AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_5;
-- dbo.Public_health_case
-- step: 3
UPDATE [dbo].[Public_health_case] SET [last_chg_time] = N'2026-04-23T14:33:26.307', [record_status_time] = N'2026-04-23T14:33:26.307', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [public_health_case_uid] = @dbo_Act_act_uid_15;
-- dbo.Confirmation_method
-- step: 3
DELETE FROM [dbo].[Confirmation_method] WHERE [public_health_case_uid] = @dbo_Act_act_uid_15 AND [confirmation_method_cd] = N'LD';
-- step: 3
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid_15, N'LD', N'2026-04-08T00:00:00');
-- dbo.Participation
-- step: 3
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-23T14:33:26.667', [last_chg_time] = N'2026-04-23T14:33:26.307', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-04-23T14:33:26.307', [status_time] = N'2026-04-23T14:33:26.307', [to_time] = N'2026-04-23T14:33:26.667' WHERE [subject_entity_uid] = 10003013 AND [act_uid] = @dbo_Act_act_uid_15 AND [type_cd] = N'InvestgrOfPHC';
-- step: 3
UPDATE [dbo].[Participation] SET [add_time] = N'2026-04-23T14:33:26.680', [last_chg_time] = N'2026-04-23T14:33:26.307', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-04-23T14:33:26.307', [status_time] = N'2026-04-23T14:33:26.307', [to_time] = N'2026-04-23T14:33:26.680' WHERE [subject_entity_uid] = @dbo_Entity_entity_uid_4 AND [act_uid] = @dbo_Act_act_uid_15 AND [type_cd] = N'SubjOfPHC';
-- dbo.SubjectRaceInfo
-- step: 3
DELETE FROM [dbo].[SubjectRaceInfo] WHERE [morbReport_uid] = 0 AND [public_health_case_uid] = @dbo_Act_act_uid_15 AND [race_cd] = N'2106-3' AND [race_category_cd] = N'2106-3';
-- dbo.PublicHealthCaseFact
-- step: 3
DELETE FROM [dbo].[PublicHealthCaseFact] WHERE [public_health_case_uid] = @dbo_Act_act_uid_15;
-- step: 3
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_gender_cd], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [diagnosis_date], [disease_imported_cd], [disease_imported_desc_txt], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorAssigneddate], [investigatorName], [investigatorPhone], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [onSetDate], [organizationName], [outcome_cd], [outbreak_ind], [outbreak_name], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [providerPhone], [providerName], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [reporterName], [reporterPhone], [rpt_form_cmplt_time], [rpt_source_cd], [rpt_source_desc_txt], [rpt_to_county_time], [rpt_to_state_time], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [birth_gender_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [outcome_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [outbreak_name_desc], [confirmation_method_desc_txt], [LASTUPDATE], [HSPTL_ADMISSION_DT], [HSPTL_DISCHARGE_DT], [hospitalized_ind]) VALUES (@dbo_Act_act_uid_15, N'Y', 41, N'F', N'1985-03-17T00:00:00', N'1985-03-17T00:00:00', N'C', N'I', N'Atlanta', N'LD', N'2026-04-08T00:00:00', N'Fulton County', N'840', N'13121', N'F', N'N', N'PR', N'Provider reported', N'2026-04-03T00:00:00', N'IND', N'Indigenous, within jurisdiction', N'PST', N'2026-03-20T00:00:00', N'O', 1.0, N'O', N'2026-04-08T00:00:00', N'Jones, Indiana', N'404-712-5227', N'130001', N'M', N'Married', N'2026-04-23T14:33:32.330', 16, 2026, N'2026-03-20T00:00:00', N'Piedmont Hospital', N'N', N'Y', N'WHS', N'SubjOfPHC', 41, N'Y', @dbo_Postal_locator_postal_locator_uid_3, N'PAT', @dbo_Entity_entity_uid_4, N'2026-04-23T14:30:02.400', N'50265', N'Salmonellosis (excluding S. typhi/paratyphi)', N'Salmonellosis (excluding S. typhi/paratyphi)', N'GCD', N'404-851-8000', N'Keable, Kristi', N'2026-04-23T14:30:02.177', N'ACTIVE', N'2106-3', N'White', N'OPEN', N'Jones, Indiana', N'404-712-5227', N'2026-04-23T00:00:00', N'LA', N'Laboratory', N'2026-04-07T00:00:00', N'2026-04-08T00:00:00', N'T', N'Georgia', N'13', N'A', N'1313 Pine Way', N'H', N'30033', N'Swift_fake55ee, Taylor', N'Fulton County', N'2026-04-08T00:00:00', 1300100009, N'2026-04-07T00:00:00', 10009406, @dbo_Person_local_id, N'2026-04-23T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Female', N'Confirmed', N'UNITED STATES', N'Female', N'Open', N'No', N'Years', N'GCD', N'Waffle House - Syrup', N' Laboratory confirmed', N'2026-04-23T14:33:26.307', N'2026-04-02T00:00:00', N'2026-04-08T00:00:00', N'Y');
-- dbo.SubjectRaceInfo
-- step: 3
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid_15, N'2106-3', N'2106-3');
-- dbo.Act
-- step: 3
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_16, N'TRMT', N'EVN');
-- dbo.Treatment
-- step: 3
INSERT INTO [dbo].[Treatment] ([treatment_uid], [activity_from_time], [add_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [class_cd], [last_chg_time], [last_chg_user_id], [local_id], [prog_area_cd], [program_jurisdiction_oid], [record_status_cd], [record_status_time], [shared_ind], [txt], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_16, N'2026-04-05T00:00:00', N'2026-04-23T14:33:40.903', @superuser_id, N'174', N'Azithromycin, 1 gm, PO, QW, x 3 weeks', N'2.16.840.1.114222.4.5.1', N'NEDSS Base System', N'TA', N'2026-04-23T14:33:40.907', @superuser_id, @dbo_Treatment_local_id, N'GCD', 1, N'ACTIVE', N'2026-04-23T14:33:40.907', N'T', N'treatment comment', 1);
-- dbo.Treatment_administered
-- step: 3
INSERT INTO [dbo].[Treatment_administered] ([treatment_uid], [treatment_administered_seq], [cd], [dose_qty], [dose_qty_unit_cd], [effective_duration_amt], [effective_duration_unit_cd], [effective_from_time], [interval_cd], [route_cd]) VALUES (@dbo_Act_act_uid_16, 1, N'174', N'1', N'gm', N'3', N'Weeks', N'2026-04-05T00:00:00', N'QW', N'C0205531');
-- dbo.NBS_act_entity
-- step: 3
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_output ([value]) VALUES (@dbo_Act_act_uid_16, N'2026-04-23T14:33:40.903', @superuser_id, 10003004, 1, N'2026-04-23T14:33:40.907', @superuser_id, N'ACTIVE', N'2026-04-23T14:33:40.907', N'ProviderOfTrmt');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_output;
-- step: 3
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_2_output ([value]) VALUES (@dbo_Act_act_uid_16, N'2026-04-23T14:33:40.903', @superuser_id, @dbo_Entity_entity_uid, 1, N'2026-04-23T14:33:40.907', @superuser_id, N'ACTIVE', N'2026-04-23T14:33:40.907', N'SubjOfTrmt');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_2 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_2_output;
-- step: 3
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_3_output ([value]) VALUES (@dbo_Act_act_uid_16, N'2026-04-23T14:33:40.903', @superuser_id, 10003019, 1, N'2026-04-23T14:33:40.907', @superuser_id, N'ACTIVE', N'2026-04-23T14:33:40.907', N'ReporterOfTrmt');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_3 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_3_output;
-- dbo.Participation
-- step: 3
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid_16, N'ProviderOfTrmt', N'TRMT', N'2026-04-23T14:33:40.907', @superuser_id, N'2026-04-23T14:33:40.907', @superuser_id, N'ACTIVE', N'2026-04-23T14:33:40.907', N'A', N'2026-04-23T14:33:40.907', N'PSN');
-- step: 3
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid, @dbo_Act_act_uid_16, N'SubjOfTrmt', N'TRMT', N'2026-04-23T14:33:40.907', @superuser_id, N'2026-04-23T14:33:40.907', @superuser_id, N'ACTIVE', N'2026-04-23T14:33:40.907', N'A', N'2026-04-23T14:33:40.907', N'PSN', N'Treatment Subject');
-- step: 3
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003019, @dbo_Act_act_uid_16, N'ReporterOfTrmt', N'TRMT', N'2026-04-23T14:33:40.907', @superuser_id, N'2026-04-23T14:33:40.907', @superuser_id, N'ACTIVE', N'2026-04-23T14:33:40.907', N'A', N'2026-04-23T14:33:40.907', N'ORG');
-- dbo.Act_relationship
-- step: 3
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_15, @dbo_Act_act_uid_16, N'TreatmentToPHC', N'2026-04-23T14:33:40.933', N'2026-04-23T14:33:40.933', @superuser_id, N'ACTIVE', N'2026-04-23T14:33:40.933', N'TRMT', N'A', N'2026-04-23T14:33:40.933', N'CASE');
