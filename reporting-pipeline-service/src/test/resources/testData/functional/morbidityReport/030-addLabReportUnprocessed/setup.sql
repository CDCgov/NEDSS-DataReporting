USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;

-- Adjust the UID declarations below manually so they remain unique across other tests.
-- @dbo_Patient_entity_uid is the patient created in 010-addPatient of this test.
DECLARE @dbo_Patient_entity_uid bigint = 1000005000;
DECLARE @dbo_Entity_entity_uid_specimen bigint = 1000005100;
DECLARE @dbo_Act_act_uid bigint = 1000005101;
DECLARE @dbo_Act_act_uid_2 bigint = 1000005102;
DECLARE @dbo_Act_act_uid_3 bigint = 1000005103;
DECLARE @dbo_Observation_local_id nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid))) + N'GA01';
DECLARE @dbo_Observation_local_id_2 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_2))) + N'GA01';
DECLARE @dbo_Observation_local_id_3 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_3))) + N'GA01';
DECLARE @dbo_Material_local_id nvarchar(40) = N'MAT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_specimen))) + N'GA01';

-- APP-1009 regression: reproduces the real create-then-delete flow end to end through
-- the CDC pipeline (Debezium -> observation service -> nrt_observation ->
-- sp_d_lab_test_postprocessing), rather than calling the stored procedure directly
-- like the reporting-pipeline-service unit tests (testData/unit/app1009_*) do.
--
-- This step creates a lab report (Order/Order_rslt/Result) for the patient added in
-- 010-addPatient, with the Order observation RECORD_STATUS_CD = 'UNPROCESSED' --
-- matching how a freshly-received ELR result initially lands before NBS processes it.
-- 040-labReportLogDel then flips the Order to LOG_DEL and asserts the whole lab
-- report (Order + its children) persists in LAB_TEST as INACTIVE rather than being
-- deleted or left stuck ACTIVE.

-- dbo.Entity / dbo.Material -- specimen
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_specimen, N'MAT');
INSERT INTO [dbo].[Material] ([material_uid], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid_specimen, N'Add', N'2026-08-22T00:00:00', @superuser_id, N'NOS', N'Nose (nasal passage)', N'2026-08-22T00:00:00', @superuser_id, @dbo_Material_local_id, N'ACTIVE', N'2026-08-22T00:00:00', N'A', N'2026-08-22T00:00:00', 1);

-- dbo.Act / dbo.Observation -- Order (UNPROCESSED)
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid, N'OBS', N'EVN');
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [effective_from_time], [electronic_ind], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [obs_domain_cd_st_1], [prog_area_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [target_site_cd], [target_site_desc_txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid, N'2026-08-22T00:00:00', N'ADD LAB REPORT', N'2026-08-22T00:00:00', @superuser_id, N'T-60825', N'Culture, Skin Biopsy', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'2026-08-22T00:00:00', N'N', N'130001', N'2026-08-22T00:00:00', @superuser_id, @dbo_Observation_local_id, N'Order', N'GCD', N'UNPROCESSED', N'2026-08-22T00:00:00', N'D', N'2026-08-22T00:00:00', N'LN', N'Left Naris', 1300100009, N'T', 1);
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, 0, N'Default Manual Lab', N'ACTIVE', N'APP1009100', N'A', N'2026-08-22T00:00:00', N'FN', N'Filler Number');
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq]) VALUES (@dbo_Act_act_uid, 0);

-- dbo.Act / dbo.Observation -- Order_rslt
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_2, N'OBS', N'EVN');
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [local_id], [obs_domain_cd_st_1], [record_status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_2, N'LAB330', N'Patient Status at Specimen Collection', N'2.16.840.1.114222.4.5.1', @dbo_Observation_local_id_2, N'Order_rslt', N'ACTIVE', N'2026-08-22T00:00:00', 4, N'T', 1);
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code], [display_name]) VALUES (@dbo_Act_act_uid_2, N'OUTP', N'outpatient');

-- dbo.Act / dbo.Observation -- Result
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_3, N'OBS', N'EVN');
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [electronic_ind], [local_id], [obs_domain_cd_st_1], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd]) VALUES (@dbo_Act_act_uid_3, N'2026-08-22T00:00:00', @superuser_id, N'T-50130', N'Acid-Fast Stain', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'N', @dbo_Observation_local_id_3, N'Result', N'2026-08-22T00:00:00', 4, N'T', 1, N'11545-1', N'MICROSCOPIC OBSERVATION', N'LN');
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code], [code_system_cd], [display_name], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd], [alt_cd_system_desc_txt], [code_derived_ind]) VALUES (@dbo_Act_act_uid_3, N'N', N'NBS', N'negative', N'R-40759', N'SNOMED', N'SNM', N'SNOMED', N'Y');
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq], [value_txt], [value_large_txt]) VALUES (@dbo_Act_act_uid_3, 1, N'Negative rapid for SARS-COV2', N'Negative rapid for SARS-COV2');

-- dbo.Participation -- Author / Orderer / Patient subject / Specimen, all on the Order
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003007, @dbo_Act_act_uid, N'AUT', N'OBS', N'2026-08-22T00:00:00', @superuser_id, N'2026-08-22T00:00:00', @superuser_id, N'ACTIVE', N'2026-08-22T00:00:00', N'A', N'2026-08-22T00:00:00', N'ORG', N'Author');
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003010, @dbo_Act_act_uid, N'ORD', N'OBS', N'2026-08-22T00:00:00', @superuser_id, N'2026-08-22T00:00:00', @superuser_id, N'ACTIVE', N'2026-08-22T00:00:00', N'A', N'2026-08-22T00:00:00', N'PSN', N'Orderer');
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Patient_entity_uid, @dbo_Act_act_uid, N'PATSBJ', N'OBS', N'2026-08-22T00:00:00', @superuser_id, N'2026-08-22T00:00:00', @superuser_id, N'ACTIVE', N'2026-08-22T00:00:00', N'A', N'2026-08-22T00:00:00', N'PSN', N'Patient subject');
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [from_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_specimen, @dbo_Act_act_uid, N'SPC', N'OBS', N'2026-08-22T00:00:00', @superuser_id, N'2026-08-22T00:00:00', N'2026-08-22T00:00:00', @superuser_id, N'ACTIVE', N'A', N'2026-08-22T00:00:00', N'MAT', N'Specimen');

-- dbo.Act_relationship -- Order has component Order_rslt, and Result
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_2, N'COMP', N'2026-08-22T00:00:00', N'2026-08-22T00:00:00', N'ACTIVE', N'2026-08-22T00:00:00', N'OBS', N'A', N'2026-08-22T00:00:00', N'OBS', N'Has Component');
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_3, N'COMP', N'2026-08-22T00:00:00', N'2026-08-22T00:00:00', N'ACTIVE', N'2026-08-22T00:00:00', N'OBS', N'A', N'2026-08-22T00:00:00', N'OBS', N'Has Component');
