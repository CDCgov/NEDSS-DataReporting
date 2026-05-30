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
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_5 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_5_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_Notification_local_id nvarchar(40) = N'NOT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_17))) + N'GA01';

-- New variables for the Vaccination:
DECLARE @dbo_Act_act_uid_18 bigint = 1000006030; -- Intervention
DECLARE @dbo_Intervention_local_id nvarchar(40) = N'INT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_18))) + N'GA01';
DECLARE @vaccination_provider_entity_uid bigint = 10003004;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_4 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_output_4 TABLE ([value] bigint);

-- STEP 1: Added vaccination
-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_18, N'INTV', N'EVN');
-- dbo.Intervention
-- step: 1
INSERT INTO [dbo].[Intervention] ([intervention_uid], [activity_from_time], [add_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [effective_from_time], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [target_site_cd], [target_site_desc_txt], [shared_ind], [version_ctrl_nbr], [material_cd], [age_at_vacc], [age_at_vacc_unit_cd], [vacc_mfgr_cd], [material_lot_nm], [material_expiration_time], [vacc_dose_nbr], [vacc_info_source_cd], [electronic_ind]) VALUES (@dbo_Act_act_uid_18, N'2026-05-28T00:00:00', N'2026-05-28T14:18:25.180', @superuser_id, N'VACADM', N'Vaccine Administration', N'NBS', N'NEDSS Base System', N'2026-05-28T00:00:00', N'2026-05-28T14:18:25.183', @superuser_id, @dbo_Intervention_local_id, N'ACTIVE', N'2026-05-28T14:18:25.183', N'OC', N'Oral Cavity', N'T', 1, N'111', 62, N'Y', N'AVI', N'12', N'2027-05-07T00:00:00', 1, N'9', N'N');
-- dbo.NBS_act_entity
-- step: 1
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_output_4 ([value]) VALUES (@dbo_Act_act_uid_18, N'2026-05-28T14:18:25.180', @superuser_id, @dbo_Entity_entity_uid, 1, N'2026-05-28T14:18:25.183', @superuser_id, N'ACTIVE', N'2026-05-28T14:18:25.183', N'SubOfVacc');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_4 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_output_4;
-- step: 1
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_5_output ([value]) VALUES (@dbo_Act_act_uid_18, N'2026-05-28T14:18:25.180', @superuser_id, @vaccination_provider_entity_uid, 1, N'2026-05-28T14:18:25.183', @superuser_id, N'ACTIVE', N'2026-05-28T14:18:25.183', N'PerformerOfVacc');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_5 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_5_output;
-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid, @dbo_Act_act_uid_18, N'SubOfVacc', N'INTV', N'2026-05-28T14:18:25.223', @superuser_id, N'2026-05-28T14:18:25.223', @superuser_id, N'ACTIVE', N'2026-05-28T14:18:25.233', N'A', N'2026-05-28T14:18:25.233', N'PAT', N'Subject Of Vaccination');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@vaccination_provider_entity_uid, @dbo_Act_act_uid_18, N'PerformerOfVacc', N'INTV', N'2026-05-28T14:18:25.237', @superuser_id, N'2026-05-28T14:18:25.237', @superuser_id, N'ACTIVE', N'2026-05-28T14:18:25.237', N'A', N'2026-05-28T14:18:25.237', N'PSN', N'Vaccination Performer');
-- dbo.Person
-- step: 1
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-05-28T14:18:25.567', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-05-28T14:18:25.567', [status_time] = N'2026-05-28T14:18:25.567', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1, [as_of_date_ethnicity] = N'2026-05-28T00:00:00', [as_of_date_general] = N'2026-05-28T00:00:00', [as_of_date_morbidity] = N'2026-05-28T00:00:00', [as_of_date_sex] = N'2026-05-28T00:00:00' WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Person_name
-- step: 1
UPDATE [dbo].[Person_name] SET [as_of_date] = N'2026-05-28T00:00:00' WHERE [person_uid] = @dbo_Entity_entity_uid AND [person_name_seq] = 1;
-- dbo.Person_race
-- step: 1
UPDATE [dbo].[Person_race] SET [as_of_date] = N'2026-05-28T00:00:00' WHERE [person_uid] = @dbo_Entity_entity_uid AND [race_cd] = N'2106-3';
-- dbo.Entity_locator_participation
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-28T14:18:25.567', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-05-28T14:18:25.567', [status_time] = N'2026-05-28T14:18:25.567', [as_of_date] = N'2026-05-28T00:00:00' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-28T14:18:25.567', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-05-28T14:18:25.567', [status_time] = N'2026-05-28T14:18:25.567', [as_of_date] = N'2026-05-28T00:00:00' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-05-28T14:18:25.567', [last_chg_user_id] = @superuser_id, [record_status_time] = N'2026-05-28T14:18:25.567', [status_time] = N'2026-05-28T14:18:25.567', [as_of_date] = N'2026-05-28T00:00:00' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;
