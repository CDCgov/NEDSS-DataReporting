USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 1000001000;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 1000001001;
DECLARE @dbo_Entity_entity_uid_2 bigint = 1000001002;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 1000001003;
DECLARE @dbo_Act_act_uid bigint = 1000001004;
DECLARE @dbo_Act_act_uid_2 bigint = 1000001005;
DECLARE @dbo_Act_act_uid_3 bigint = 1000001006;
DECLARE @dbo_Act_act_uid_4 bigint = 1000001007;
DECLARE @dbo_Act_act_uid_5 bigint = 1000001008;
DECLARE @dbo_Act_act_uid_6 bigint = 1000001009;
DECLARE @dbo_Act_act_uid_7 bigint = 1000001010;
DECLARE @dbo_Act_act_uid_8 bigint = 1000001011;
DECLARE @dbo_Act_act_uid_9 bigint = 1000001012;
DECLARE @dbo_Act_act_uid_10 bigint = 1000001013;
DECLARE @dbo_Act_act_uid_11 bigint = 1000001014;
DECLARE @dbo_Act_act_uid_12 bigint = 1000001015;
DECLARE @dbo_Act_act_uid_13 bigint = 1000001016;
DECLARE @dbo_Act_act_uid_14 bigint = 1000001017;
DECLARE @dbo_Act_act_uid_15 bigint = 1000001018;
DECLARE @dbo_Act_act_uid_16 bigint = 1000001019;
DECLARE @dbo_Act_act_uid_17 bigint = 1000001020;
DECLARE @dbo_Act_act_uid_18 bigint = 1000001021;
DECLARE @dbo_Act_act_uid_19 bigint = 1000001022;
DECLARE @dbo_Act_act_uid_20 bigint = 1000001023;
DECLARE @dbo_Act_act_uid_21 bigint = 1000001024;
DECLARE @dbo_Act_act_uid_22 bigint = 1000001025;
DECLARE @dbo_Act_act_uid_23 bigint = 1000001026;
DECLARE @dbo_Act_act_uid_24 bigint = 1000001027;
DECLARE @dbo_Act_act_uid_25 bigint = 1000001028;
DECLARE @dbo_Act_act_uid_26 bigint = 1000001029;
DECLARE @dbo_Act_act_uid_27 bigint = 1000001030;
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

-- STEP 1: Create the Obi Wan Kenobi patient
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid, N'PSN');
-- dbo.Person
-- step: 1
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [birth_time], [birth_time_calc], [cd], [curr_sex_cd], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_general], [as_of_date_sex], [electronic_ind], [person_parent_uid], [edx_ind]) VALUES (@dbo_Entity_entity_uid, N'2026-05-20T17:52:20.203', @superuser_id, N'1978-01-18T00:00:00', N'1978-01-18T00:00:00', N'PAT', N'M', N'2026-05-20T17:52:20.203', @superuser_id, @dbo_Person_local_id, N'ACTIVE', N'2026-05-20T17:52:20.203', N'A', N'2026-05-20T17:52:20.203', N'Obi Wan', N'Kenobi', 1, N'2026-05-20T00:00:00', N'2026-05-20T00:00:00', N'2026-05-20T00:00:00', N'N', @dbo_Entity_entity_uid, N'Y');
-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [first_nm], [first_nm_sndx], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid, 1, N'Add', N'2026-05-20T17:52:20.133', N'Obi Wan', N'O100', N'Kenobi', N'K510', N'L', N'ACTIVE', N'2026-05-20T17:52:20.133', N'A', N'2026-05-20T17:52:20.133', N'2026-05-20T00:00:00');
-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [cntry_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [street_addr2]) VALUES (@dbo_Postal_locator_postal_locator_uid, N'2026-05-20T17:52:20.133', N'840', N'ACTIVE', N'2026-05-20T17:52:20.133', N'13', N'', N'');
-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Postal_locator_postal_locator_uid, N'H', N'PST', N'2026-05-20T17:52:20.203', @superuser_id, N'ACTIVE', N'2026-05-20T17:52:20.203', N'A', N'2026-05-20T17:52:20.203', N'H', 1, N'2026-05-20T00:00:00');
