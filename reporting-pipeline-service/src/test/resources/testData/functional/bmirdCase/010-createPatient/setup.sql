-- reporting-pipeline-service/src/test/resources/testData/functional/bmirdCase/010-createPatient/setup.sql
USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 10067003;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 10067004;
DECLARE @dbo_Entity_entity_uid_2 bigint = 10067005;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 10067006;
DECLARE @dbo_Act_act_uid bigint = 10067007;

DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';
DECLARE @dbo_Public_health_case_local_id nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid))) + N'GA01';

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
