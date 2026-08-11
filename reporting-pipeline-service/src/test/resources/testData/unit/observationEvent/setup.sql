USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;
DECLARE @elruser_id bigint = 10000015;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 20001100;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 20001101;
DECLARE @dbo_Entity_entity_uid_2 bigint = 20001102;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 20001103;
DECLARE @dbo_Act_act_uid bigint = 20001104;
DECLARE @dbo_Act_act_uid_2 bigint = 20001105;
DECLARE @dbo_Act_act_uid_3 bigint = 20001106;
DECLARE @dbo_Act_act_uid_4 bigint = 20001107;
DECLARE @dbo_Act_act_uid_5 bigint = 20001108;
DECLARE @dbo_Act_act_uid_6 bigint = 20001109;
DECLARE @dbo_Act_act_uid_7 bigint = 20001110;
DECLARE @dbo_Act_act_uid_8 bigint = 20001111;
DECLARE @dbo_Act_act_uid_9 bigint = 20001112;
DECLARE @dbo_Entity_entity_uid_3 bigint = 20001113;
DECLARE @dbo_Entity_entity_uid_4 bigint = 20001114;
DECLARE @dbo_Postal_locator_postal_locator_uid_3 bigint = 20001115;
DECLARE @dbo_Act_act_uid_10 bigint = 20001116;
DECLARE @dbo_Entity_entity_uid_5 bigint = 20001117;
DECLARE @dbo_Postal_locator_postal_locator_uid_4 bigint = 20001118;
DECLARE @dbo_Act_act_uid_11 bigint = 20001119;
DECLARE @dbo_Act_act_uid_12 bigint = 20001120;
DECLARE @dbo_Act_act_uid_13 bigint = 20001121;
DECLARE @dbo_Act_act_uid_14 bigint = 20001122;
DECLARE @dbo_Act_act_uid_15 bigint = 20001123;
DECLARE @dbo_Entity_entity_uid_6 bigint = 20001124;

-- STEP 1: Create patient with lab report and associated investigation

-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid, N'PSN');

-- dbo.Person
-- step: 1
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [cd], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_general], [as_of_date_sex], [electronic_ind], [person_parent_uid], [edx_ind]) VALUES (@dbo_Entity_entity_uid, N'2026-07-29T22:50:57.417', @superuser_id, N'PAT', N'2026-07-29T22:50:57.417', @superuser_id, @dbo_Person_local_id, N'ACTIVE', N'2026-07-29T22:50:57.417', N'A', N'2026-07-29T22:50:57.417', N'Basic', N'Observation', 1, N'2026-07-29T00:00:00', N'2026-07-29T00:00:00', N'2026-07-29T00:00:00', N'N', @dbo_Entity_entity_uid, N'Y');

-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [first_nm], [first_nm_sndx], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid, 1, N'Add', N'2026-07-29T22:50:57.327', N'Basic', N'B220', N'Observation', N'O126', N'L', N'ACTIVE', N'2026-07-29T22:50:57.327', N'A', N'2026-07-29T22:50:57.327', N'2026-07-29T00:00:00');

-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [cntry_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [street_addr2]) VALUES (@dbo_Postal_locator_postal_locator_uid, N'2026-07-29T22:50:57.330', N'840', N'ACTIVE', N'2026-07-29T22:50:57.330', N'13', N'', N'');

-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Postal_locator_postal_locator_uid, N'H', N'PST', N'2026-07-29T22:50:57.417', @superuser_id, N'ACTIVE', N'2026-07-29T22:50:57.417', N'A', N'2026-07-29T22:50:57.417', N'H', 1, N'2026-07-29T00:00:00');

-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_2, N'PSN');

-- dbo.Person
-- step: 1
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [cd], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_2, N'2026-07-29T22:54:00.687', @superuser_id, N'PAT', N'2026-07-29T22:54:00.687', @superuser_id, @dbo_Person_local_id, N'ACTIVE', N'2026-07-29T22:54:00.687', N'A', N'2026-07-29T22:54:00.687', N'Basic', N'Observation', 1, N'2026-07-29T00:00:00', N'2026-07-29T00:00:00', N'N', @dbo_Entity_entity_uid);

-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, 1, N'ADD LAB REPORT', N'2026-07-29T22:54:00.510', @superuser_id, N'Basic', N'B220', N'2026-07-29T22:54:00.510', @superuser_id, N'Observation', N'O126', N'L', N'ACTIVE', N'2026-07-29T22:54:00.510', N'A', N'2026-07-29T22:54:00.510', N'2026-07-29T00:00:00');

-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [cntry_cd], [record_status_cd], [record_status_time], [state_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_2, N'2026-07-29T22:54:00.510', @superuser_id, N'840', N'ACTIVE', N'2026-07-29T22:54:00.510', N'13');

-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Postal_locator_postal_locator_uid_2, N'H', N'PST', N'2026-07-29T22:54:00.687', @superuser_id, N'ACTIVE', N'2026-07-29T22:54:00.687', N'A', N'2026-07-29T22:54:00.687', N'H', 1, N'2026-07-29T00:00:00');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [effective_from_time], [electronic_ind], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [obs_domain_cd_st_1], [prog_area_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [target_site_cd], [target_site_desc_txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [rpt_to_state_time]) VALUES (@dbo_Act_act_uid, N'2026-07-29T00:00:00', N'ADD LAB REPORT', N'2026-07-29T22:54:00.747', @superuser_id, N'T-10130', N'Acid-Fast Stain', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'2026-07-28T00:00:00', N'N', N'130006', N'2026-07-29T22:54:00.747', @superuser_id, @dbo_Observation_local_id, N'Order', N'ARBO', N'UNPROCESSED', N'2026-07-29T22:54:00.747', N'D', N'2026-07-29T22:54:00.510', N'LT', N'Left Thigh', 1300600013, N'T', 1, N'2026-07-29T00:00:00');

-- dbo.Act_id
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, 0, N'Default Manual Lab', N'ACTIVE', N'123455', N'A', N'2026-07-29T22:54:00.523', N'FN', N'Filler Number');

-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq]) VALUES (@dbo_Act_act_uid, 0);

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_2, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_2 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_2))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [local_id], [obs_domain_cd_st_1], [record_status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_2, N'LAB330', N'Patient Status at Specimen Collection', N'2.16.840.1.114222.4.5.1', @dbo_Observation_local_id_2, N'Order_rslt', N'ACTIVE', N'2026-07-29T22:54:00.523', 4, N'T', 1);

-- dbo.Obs_value_coded
-- step: 1
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code], [display_name]) VALUES (@dbo_Act_act_uid_2, N'OUTP', N'outpatient');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_3, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_3 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_3))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [effective_from_time], [local_id], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [rpt_to_state_time]) VALUES (@dbo_Act_act_uid_3, N'2026-07-29T00:00:00', N'NI', N'No Information Given', N'2.16.840.1.113883', N'LabComment', N'Lab Report', N'2026-07-28T00:00:00', @dbo_Observation_local_id_3, N'C_Order', N'D', N'2026-07-29T22:54:00.523', 4, N'T', 1, N'2026-07-29T00:00:00');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_4, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_4 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_4))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [local_id], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_4, N'2026-07-29T22:54:00.523', @superuser_id, N'LAB214', N'User Report Comment', N'NBS', N'NEDSS Base System', N'LabComment', @dbo_Observation_local_id_4, N'C_Result', N'D', N'2026-07-29T22:54:00.523', 4, N'T', 1);

-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq], [value_txt], [value_large_txt]) VALUES (@dbo_Act_act_uid_4, 1, N'Comments on lab report', N'Comments on lab report');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_5, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_5 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_5))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [add_reason_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [electronic_ind], [local_id], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd]) VALUES (@dbo_Act_act_uid_5, N'ADD LAB REPORT', N'T-50130', N'Acid-Fast Stain', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'N', @dbo_Observation_local_id_5, N'Result', N'N', N'2026-07-29T22:54:00.530', 4, N'T', 1, N'11545-1', N'MICROSCOPIC OBSERVATION', N'LN');

-- dbo.Obs_value_coded
-- step: 1
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code], [code_system_cd], [display_name], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd], [alt_cd_system_desc_txt], [code_derived_ind]) VALUES (@dbo_Act_act_uid_5, N'ABN', N'NBS', N'abnormal', N'R-42037', N'SNOMED', N'SNM', N'SNOMED', N'Y');

-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq], [txt_type_cd], [value_txt], [value_large_txt]) VALUES (@dbo_Act_act_uid_5, 1, N'N', N'Prelim', N'Prelim');
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq], [value_txt], [value_large_txt]) VALUES (@dbo_Act_act_uid_5, 2, N'1234 Text', N'1234 Text');

-- dbo.Obs_value_numeric
-- step: 1
INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid], [obs_value_numeric_seq], [high_range], [low_range], [comparator_cd_1], [numeric_value_1], [numeric_unit_cd], [numeric_scale_1]) VALUES (@dbo_Act_act_uid_5, 0, N'2000', N'0', N'=', 1234.0, N'(arb_u)', 0);

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_6, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_6 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_6))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [ctrl_cd_display_form], [local_id], [obs_domain_cd_st_1], [status_cd], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_6, N'LAB222', N'No Information Given', N'LabReport', @dbo_Observation_local_id_6, N'R_Order', N'A', 4, N'T', 1);

-- dbo.Obs_value_coded
-- step: 1
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code]) VALUES (@dbo_Act_act_uid_6, N'Y');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_7, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_7 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_7))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [add_reason_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [electronic_ind], [local_id], [method_desc_txt], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_7, N'ADD LAB REPORT', N'18855-7', N'5-FLUOROCYTOSINE', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'N', @dbo_Observation_local_id_7, N'', N'R_Result', N'A', N'2026-07-29T22:54:00.580', 4, N'T', 1);

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_8, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_8 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_8))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [add_reason_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [electronic_ind], [local_id], [method_desc_txt], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_8, N'ADD LAB REPORT', N'1-8', N'ACYCLOVIR', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'N', @dbo_Observation_local_id_8, N'', N'R_Result', N'A', N'2026-07-29T22:54:00.583', 4, N'T', 1);

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_9, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_9 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_9))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [add_reason_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [ctrl_cd_user_defined_1], [electronic_ind], [local_id], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd]) VALUES (@dbo_Act_act_uid_9, N'ADD LAB REPORT', N'T-50205', N'AEROBIC BACTERIA IDENTIFIED', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'Y', N'N', @dbo_Observation_local_id_9, N'Result', N'N', N'2026-07-29T22:54:00.530', 4, N'T', 1, N'634-6', N'MICROORGANISM IDENTIFIED', N'LN');

-- dbo.Obs_value_coded
-- step: 1
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code], [code_system_cd], [display_name]) VALUES (@dbo_Act_act_uid_9, N'L-10500', N'NBS', N'Acinetobacter (organism)');

-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq], [txt_type_cd], [value_txt], [value_large_txt]) VALUES (@dbo_Act_act_uid_9, 1, N'N', N'uhoh', N'uhoh');
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq], [value_txt], [value_large_txt]) VALUES (@dbo_Act_act_uid_9, 2, N'1%', N'1%');

-- dbo.Obs_value_numeric
-- step: 1
INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid], [obs_value_numeric_seq], [high_range], [low_range], [comparator_cd_1], [numeric_value_1], [numeric_unit_cd], [numeric_scale_1]) VALUES (@dbo_Act_act_uid_9, 0, N'100', N'0', N'=', 1.0, N'%', 0);

-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_3, N'MAT');

-- dbo.Material
-- step: 1
DECLARE @dbo_Material_local_id nvarchar(40) = N'MAT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_3))) + N'GA01';
INSERT INTO [dbo].[Material] ([material_uid], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid_3, N'Add', N'2026-07-29T22:54:00.823', @superuser_id, N'ABS', N'Abcess', N'2026-07-29T22:54:00.823', @superuser_id, @dbo_Material_local_id, N'ACTIVE', N'2026-07-29T22:54:00.823', N'A', N'2026-07-29T22:54:00.823', 1);

-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003001, @dbo_Act_act_uid, N'AUT', N'OBS', N'2026-07-29T22:54:00.497', @superuser_id, N'2026-07-29T22:54:00.497', @superuser_id, N'ACTIVE', N'2026-07-29T22:54:00.497', N'A', N'2026-07-29T22:54:00.497', N'ORG', N'Author');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003013, @dbo_Act_act_uid, N'ORD', N'OBS', N'2026-07-29T22:54:00.497', @superuser_id, N'2026-07-29T22:54:00.497', @superuser_id, N'ACTIVE', N'2026-07-29T22:54:00.497', N'A', N'2026-07-29T22:54:00.497', N'PSN', N'Orderer');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003007, @dbo_Act_act_uid, N'ORD', N'OBS', N'2026-07-29T22:54:00.497', @superuser_id, N'2026-07-29T22:54:00.497', @superuser_id, N'ACTIVE', N'2026-07-29T22:54:00.497', N'A', N'2026-07-29T22:54:00.497', N'ORG', N'Orderer');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Act_act_uid, N'PATSBJ', N'OBS', N'2026-07-29T22:54:00.497', @superuser_id, N'2026-07-29T22:54:00.497', @superuser_id, N'ACTIVE', N'2026-07-29T22:54:00.497', N'A', N'2026-07-29T22:54:00.497', N'PSN', N'Patient subject');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [from_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_3, @dbo_Act_act_uid, N'SPC', N'OBS', N'2026-07-29T22:54:00.523', @superuser_id, N'2026-07-28T00:00:00', N'2026-07-29T22:54:00.523', @superuser_id, N'ACTIVE', N'A', N'2026-07-29T22:54:00.523', N'MAT', N'Specimen');

-- dbo.Act_relationship
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_2, N'COMP', N'2026-07-29T22:54:00.843', N'2026-07-29T22:54:00.843', N'ACTIVE', N'2026-07-29T22:54:00.843', N'OBS', N'A', N'2026-07-29T22:54:00.843', N'OBS', N'Has Component');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_3, @dbo_Act_act_uid_4, N'COMP', N'2026-07-29T22:54:00.850', N'2026-07-29T22:54:00.850', N'ACTIVE', N'2026-07-29T22:54:00.850', N'OBS', N'A', N'2026-07-29T22:54:00.850', N'OBS', N'Is Cause For');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_3, N'APND', N'2026-07-29T22:54:00.853', N'2026-07-29T22:54:00.853', N'ACTIVE', N'2026-07-29T22:54:00.853', N'OBS', N'A', N'2026-07-29T22:54:00.853', N'OBS', N'Appends');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_5, N'COMP', N'2026-07-29T22:54:00.853', N'2026-07-29T22:54:00.853', N'ACTIVE', N'2026-07-29T22:54:00.853', N'OBS', N'A', N'2026-07-29T22:54:00.853', N'OBS', N'Has Component');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_6, N'SPRT', N'2026-07-29T22:54:00.853', N'2026-07-29T22:54:00.853', N'ACTIVE', N'2026-07-29T22:54:00.853', N'OBS', N'A', N'2026-07-29T22:54:00.853', N'OBS', N'Has Support');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_9, @dbo_Act_act_uid_6, N'REFR', N'2026-07-29T22:54:00.853', N'2026-07-29T22:54:00.853', N'ACTIVE', N'2026-07-29T22:54:00.853', N'OBS', N'A', N'2026-07-29T22:54:00.853', N'OBS', N'Refers to');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_6, @dbo_Act_act_uid_7, N'COMP', N'2026-07-29T22:54:00.853', N'2026-07-29T22:54:00.853', N'ACTIVE', N'2026-07-29T22:54:00.853', N'OBS', N'A', N'2026-07-29T22:54:00.853', N'OBS', N'Has Component');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_6, @dbo_Act_act_uid_8, N'COMP', N'2026-07-29T22:54:00.853', N'2026-07-29T22:54:00.853', N'ACTIVE', N'2026-07-29T22:54:00.853', N'OBS', N'A', N'2026-07-29T22:54:00.853', N'OBS', N'Has Component');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid, @dbo_Act_act_uid_9, N'COMP', N'2026-07-29T22:54:00.853', N'2026-07-29T22:54:00.853', N'ACTIVE', N'2026-07-29T22:54:00.853', N'OBS', N'A', N'2026-07-29T22:54:00.853', N'OBS', N'Has Component');

-- dbo.Role
-- step: 1
INSERT INTO [dbo].[Role] ([subject_entity_uid], [cd], [role_seq], [add_time], [cd_desc_txt], [effective_from_time], [effective_to_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [scoping_class_cd], [scoping_entity_uid], [scoping_role_cd], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_3, N'NI', 0, N'2026-07-29T22:54:00.857', N'No Information Given', N'2026-07-29T22:54:00.857', N'2026-07-29T22:54:00.857', N'2026-07-29T22:54:00.853', @superuser_id, N'ACTIVE', N'2026-07-29T22:54:00.853', N'PSN', @dbo_Entity_entity_uid_2, N'PAT', N'A', N'2026-07-29T22:54:00.853', N'SPEC');

-- dbo.Person
-- step: 1
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-07-29T22:54:00.673', [record_status_time] = N'2026-07-29T22:54:00.673', [status_time] = N'2026-07-29T22:54:00.673', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-07-29T22:54:00.673', [record_status_time] = N'2026-07-29T22:54:00.673', [status_time] = N'2026-07-29T22:54:00.673' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;

-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_4, N'PSN');

-- dbo.Person
-- step: 1
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [cd], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_4, N'2026-07-29T22:54:10.303', @superuser_id, N'PAT', N'2026-07-29T22:54:10.303', @superuser_id, @dbo_Person_local_id, N'ACTIVE', N'2026-07-29T22:54:10.303', N'A', N'2026-07-29T22:54:10.303', N'Basic', N'Observation', 1, N'2026-07-29T00:00:00', N'2026-07-29T00:00:00', N'N', @dbo_Entity_entity_uid);

-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, 1, N'2026-07-29T22:54:10.157', @superuser_id, N'Basic', N'B220', N'2026-07-29T22:54:10.157', @superuser_id, N'Observation', N'O126', N'L', N'ACTIVE', N'2026-07-29T22:54:10.157', N'A', N'2026-07-29T22:54:10.157', N'2026-07-29T00:00:00');

-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [cntry_cd], [record_status_cd], [record_status_time], [state_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_3, N'2026-07-29T22:54:10.157', @superuser_id, N'840', N'ACTIVE', N'2026-07-29T22:54:10.157', N'13');

-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Postal_locator_postal_locator_uid_3, N'H', N'PST', N'2026-07-29T22:54:10.303', @superuser_id, N'ACTIVE', N'2026-07-29T22:54:10.303', N'A', N'2026-07-29T22:54:10.303', N'H', 1, N'2026-07-29T00:00:00');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_10, N'CASE', N'EVN');

-- dbo.Public_health_case
-- step: 1
DECLARE @dbo_Public_health_case_local_id nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_10))) + N'GA01';
INSERT INTO [dbo].[Public_health_case] ([public_health_case_uid], [activity_from_time], [add_time], [add_user_id], [case_class_cd], [case_type_cd], [cd], [cd_desc_txt], [detection_method_cd], [disease_imported_cd], [effective_duration_amt], [effective_duration_unit_cd], [group_case_cnt], [investigation_status_cd], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [mmwr_week], [mmwr_year], [outbreak_ind], [outbreak_name], [outcome_cd], [prog_area_cd], [record_status_cd], [record_status_time], [rpt_form_cmplt_time], [rpt_source_cd], [status_cd], [transmission_mode_cd], [transmission_mode_desc_txt], [txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [hospitalized_ind_cd], [pregnant_ind_cd], [day_care_ind_cd], [food_handler_ind_cd], [imported_country_cd], [imported_state_cd], [imported_city_desc_txt], [imported_county_cd], [priority_cd], [contact_inv_txt], [contact_inv_status_cd]) VALUES (@dbo_Act_act_uid_10, N'2026-07-29T00:00:00', N'2026-07-29T22:54:10.347', @superuser_id, N'', N'I', N'11120', N'Acute flaccid myelitis', N'', N'', N'', N'', 1, N'O', N'130006', N'2026-07-29T22:54:10.347', @superuser_id, @dbo_Public_health_case_local_id, N'30', N'2026', N'', N'', N'', N'GCD', N'OPEN', N'2026-07-29T22:54:10.347', N'2026-07-29T00:00:00', N'', N'A', N'', N'', N'', 1300600009, N'T', 1, N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'');

-- dbo.Act_id
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid_10, 1, N'', N'A', N'2026-07-29T22:54:10.363', N'STATE');
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid_10, 2, N'', N'A', N'2026-07-29T22:54:10.367', N'CITY');
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid_10, 3, N'', N'A', N'2026-07-29T22:54:10.367', N'LEGACY');

-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Act_act_uid_10, N'SubjOfPHC', N'CASE', N'2026-07-29T22:54:10.163', @superuser_id, N'2026-07-29T22:54:10.163', @superuser_id, N'ACTIVE', N'2026-07-29T22:54:10.163', N'A', N'2026-07-29T22:54:10.163', N'PSN', N'Subject Of Public Health Case');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003007, @dbo_Act_act_uid_10, N'OrgAsClinicOfPHC', N'CASE', N'2026-07-29T22:54:10.163', @superuser_id, N'2026-07-29T22:54:10.163', @superuser_id, N'ACTIVE', N'2026-07-29T22:54:10.163', N'A', N'2026-07-29T22:54:10.163', N'ORG');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003001, @dbo_Act_act_uid_10, N'OrgAsReporterOfPHC', N'CASE', N'2026-07-29T22:54:10.163', @superuser_id, N'2026-07-29T22:54:10.163', @superuser_id, N'ACTIVE', N'2026-07-29T22:54:10.163', N'A', N'2026-07-29T22:54:10.163', N'ORG', N'Organization As Reporter Of PHC');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003013, @dbo_Act_act_uid_10, N'PhysicianOfPHC', N'CASE', N'2026-07-29T22:54:10.163', @superuser_id, N'2026-07-29T22:54:10.163', @superuser_id, N'ACTIVE', N'2026-07-29T22:54:10.163', N'A', N'2026-07-29T22:54:10.163', N'PSN', N'Physician of PHC');

-- dbo.NBS_act_entity
-- step: 1
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_output ([value]) VALUES (@dbo_Act_act_uid_10, N'2026-07-29T22:54:10.347', @superuser_id, @dbo_Entity_entity_uid_4, 1, N'2026-07-29T22:54:10.347', @superuser_id, N'OPEN', N'2026-07-29T22:54:10.347', N'SubjOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_output;
-- step: 1
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_2_output ([value]) VALUES (@dbo_Act_act_uid_10, N'2026-07-29T22:54:10.347', @superuser_id, 10003007, 1, N'2026-07-29T22:54:10.347', @superuser_id, N'OPEN', N'2026-07-29T22:54:10.347', N'OrgAsClinicOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_2 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_2_output;
-- step: 1
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_3_output ([value]) VALUES (@dbo_Act_act_uid_10, N'2026-07-29T22:54:10.347', @superuser_id, 10003001, 1, N'2026-07-29T22:54:10.347', @superuser_id, N'OPEN', N'2026-07-29T22:54:10.347', N'OrgAsReporterOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_3 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_3_output;
-- step: 1
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_4 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_4_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_4_output ([value]) VALUES (@dbo_Act_act_uid_10, N'2026-07-29T22:54:10.347', @superuser_id, 10003013, 1, N'2026-07-29T22:54:10.347', @superuser_id, N'OPEN', N'2026-07-29T22:54:10.347', N'PhysicianOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_4 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_4_output;

-- dbo.Act_relationship
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_reason_cd], [add_time], [from_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_10, @dbo_Act_act_uid, N'LabReport', N'', N'2026-07-29T22:54:10.390', N'2026-07-29T22:54:10.347', N'2026-07-29T22:54:10.390', @superuser_id, N'ACTIVE', N'2026-07-29T22:54:10.390', N'OBS', N'A', N'2026-07-29T22:54:10.390', N'CASE');

-- dbo.Person
-- step: 1
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-07-29T22:54:10.283', [record_status_time] = N'2026-07-29T22:54:10.283', [status_time] = N'2026-07-29T22:54:10.283', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-07-29T22:54:10.283', [record_status_time] = N'2026-07-29T22:54:10.283', [status_time] = N'2026-07-29T22:54:10.283' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;

-- dbo.Observation
-- step: 1
UPDATE [dbo].[Observation] SET [last_chg_time] = N'2026-07-29T22:54:10.417', [record_status_cd] = N'PROCESSED', [record_status_time] = N'2026-07-29T22:54:10.417', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid;

-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_5, N'PSN');

-- dbo.Person
-- step: 1
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [cd], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_5, N'2026-07-29T22:57:05.783', @superuser_id, N'PAT', N'2026-07-29T22:57:05.783', @superuser_id, @dbo_Person_local_id, N'ACTIVE', N'2026-07-29T22:57:05.783', N'A', N'2026-07-29T22:57:05.783', N'Basic', N'Observation', 1, N'2026-07-29T00:00:00', N'2026-07-29T00:00:00', N'N', @dbo_Entity_entity_uid);

-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_reason_cd], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_5, 1, N'ADD LAB REPORT', N'2026-07-29T22:57:05.677', @superuser_id, N'Basic', N'B220', N'2026-07-29T22:57:05.677', @superuser_id, N'Observation', N'O126', N'L', N'ACTIVE', N'2026-07-29T22:57:05.677', N'A', N'2026-07-29T22:57:05.677', N'2026-07-29T00:00:00');

-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [cntry_cd], [record_status_cd], [record_status_time], [state_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_4, N'2026-07-29T22:57:05.677', @superuser_id, N'840', N'ACTIVE', N'2026-07-29T22:57:05.677', N'13');

-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_5, @dbo_Postal_locator_postal_locator_uid_4, N'H', N'PST', N'2026-07-29T22:57:05.783', @superuser_id, N'ACTIVE', N'2026-07-29T22:57:05.783', N'A', N'2026-07-29T22:57:05.783', N'H', 1, N'2026-07-29T00:00:00');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_11, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_10 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_11))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [effective_from_time], [electronic_ind], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [obs_domain_cd_st_1], [prog_area_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [target_site_cd], [target_site_desc_txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [rpt_to_state_time]) VALUES (@dbo_Act_act_uid_11, N'2026-07-29T00:00:00', N'ADD LAB REPORT', N'2026-07-29T22:57:05.820', @superuser_id, N'T-10130', N'Acid-Fast Stain', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'2026-07-29T00:00:00', N'N', N'130006', N'2026-07-29T22:57:05.820', @superuser_id, @dbo_Observation_local_id_10, N'Order', N'ARBO', N'UNPROCESSED', N'2026-07-29T22:57:05.820', N'D', N'2026-07-29T22:57:05.677', N'LT', N'Left Thigh', 1300600013, N'T', 1, N'2026-07-29T00:00:00');

-- dbo.Act_id
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [assigning_authority_desc_txt], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_11, 0, N'Default Manual Lab', N'ACTIVE', N'123455', N'A', N'2026-07-29T22:57:05.687', N'FN', N'Filler Number');

-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq]) VALUES (@dbo_Act_act_uid_11, 0);

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_12, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_11 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_12))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [cd], [cd_desc_txt], [cd_system_cd], [local_id], [obs_domain_cd_st_1], [record_status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_12, N'LAB330', N'Patient Status at Specimen Collection', N'2.16.840.1.114222.4.5.1', @dbo_Observation_local_id_11, N'Order_rslt', N'ACTIVE', N'2026-07-29T22:57:05.687', 4, N'T', 1);

-- dbo.Obs_value_coded
-- step: 1
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code], [display_name]) VALUES (@dbo_Act_act_uid_12, N'OUTP', N'outpatient');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_13, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_12 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_13))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [effective_from_time], [local_id], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [rpt_to_state_time]) VALUES (@dbo_Act_act_uid_13, N'2026-07-29T00:00:00', N'NI', N'No Information Given', N'2.16.840.1.113883', N'LabComment', N'Lab Report', N'2026-07-29T00:00:00', @dbo_Observation_local_id_12, N'C_Order', N'D', N'2026-07-29T22:57:05.687', 4, N'T', 1, N'2026-07-29T00:00:00');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_14, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_13 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_14))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [activity_to_time], [add_user_id], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [local_id], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr]) VALUES (@dbo_Act_act_uid_14, N'2026-07-29T22:57:05.687', @superuser_id, N'LAB214', N'User Report Comment', N'NBS', N'NEDSS Base System', N'LabComment', @dbo_Observation_local_id_13, N'C_Result', N'D', N'2026-07-29T22:57:05.687', 4, N'T', 1);

-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq], [value_txt], [value_large_txt]) VALUES (@dbo_Act_act_uid_14, 1, N'final result', N'final result');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid_15, N'OBS', N'EVN');

-- dbo.Observation
-- step: 1
DECLARE @dbo_Observation_local_id_14 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid_15))) + N'GA01';
INSERT INTO [dbo].[Observation] ([observation_uid], [add_reason_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt], [ctrl_cd_display_form], [electronic_ind], [local_id], [obs_domain_cd_st_1], [status_cd], [status_time], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd]) VALUES (@dbo_Act_act_uid_15, N'ADD LAB REPORT', N'T-50130', N'Acid-Fast Stain', N'DEFAULT', N'Default Manual Lab', N'LabReport', N'N', @dbo_Observation_local_id_14, N'Result', N'D', N'2026-07-29T22:57:05.690', 4, N'T', 1, N'11545-1', N'MICROSCOPIC OBSERVATION', N'LN');

-- dbo.Obs_value_coded
-- step: 1
INSERT INTO [dbo].[Obs_value_coded] ([observation_uid], [code], [code_system_cd], [display_name], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd], [alt_cd_system_desc_txt], [code_derived_ind]) VALUES (@dbo_Act_act_uid_15, N'ABN', N'NBS', N'abnormal', N'R-42037', N'SNOMED', N'SNM', N'SNOMED', N'Y');

-- dbo.Obs_value_txt
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq], [txt_type_cd], [value_txt], [value_large_txt]) VALUES (@dbo_Act_act_uid_15, 1, N'N', N'final result', N'final result');
-- step: 1
INSERT INTO [dbo].[Obs_value_txt] ([observation_uid], [obs_value_txt_seq], [value_txt], [value_large_txt]) VALUES (@dbo_Act_act_uid_15, 2, N'222 text', N'222 text');

-- dbo.Obs_value_numeric
-- step: 1
INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid], [obs_value_numeric_seq], [high_range], [low_range], [comparator_cd_1], [numeric_value_1], [numeric_unit_cd], [numeric_scale_1]) VALUES (@dbo_Act_act_uid_15, 0, N'2000', N'0', N'=', 222.0, N'(arb_u)', 0);

-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_6, N'MAT');

-- dbo.Material
-- step: 1
DECLARE @dbo_Material_local_id_2 nvarchar(40) = N'MAT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_6))) + N'GA01';
INSERT INTO [dbo].[Material] ([material_uid], [add_reason_cd], [add_time], [add_user_id], [cd], [cd_desc_txt], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid_6, N'Add', N'2026-07-29T22:57:05.883', @superuser_id, N'BIFL', N'Bile fluid', N'2026-07-29T22:57:05.883', @superuser_id, @dbo_Material_local_id_2, N'ACTIVE', N'2026-07-29T22:57:05.883', N'A', N'2026-07-29T22:57:05.883', 1);

-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003007, @dbo_Act_act_uid_11, N'AUT', N'OBS', N'2026-07-29T22:57:05.663', @superuser_id, N'2026-07-29T22:57:05.663', @superuser_id, N'ACTIVE', N'2026-07-29T22:57:05.663', N'A', N'2026-07-29T22:57:05.663', N'ORG', N'Author');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003013, @dbo_Act_act_uid_11, N'ORD', N'OBS', N'2026-07-29T22:57:05.667', @superuser_id, N'2026-07-29T22:57:05.667', @superuser_id, N'ACTIVE', N'2026-07-29T22:57:05.667', N'A', N'2026-07-29T22:57:05.667', N'PSN', N'Orderer');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003001, @dbo_Act_act_uid_11, N'ORD', N'OBS', N'2026-07-29T22:57:05.667', @superuser_id, N'2026-07-29T22:57:05.667', @superuser_id, N'ACTIVE', N'2026-07-29T22:57:05.667', N'A', N'2026-07-29T22:57:05.667', N'ORG', N'Orderer');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_5, @dbo_Act_act_uid_11, N'PATSBJ', N'OBS', N'2026-07-29T22:57:05.667', @superuser_id, N'2026-07-29T22:57:05.667', @superuser_id, N'ACTIVE', N'2026-07-29T22:57:05.667', N'A', N'2026-07-29T22:57:05.667', N'PSN', N'Patient subject');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [from_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_6, @dbo_Act_act_uid_11, N'SPC', N'OBS', N'2026-07-29T22:57:05.687', @superuser_id, N'2026-07-29T00:00:00', N'2026-07-29T22:57:05.687', @superuser_id, N'ACTIVE', N'A', N'2026-07-29T22:57:05.687', N'MAT', N'Specimen');

-- dbo.Act_relationship
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_11, @dbo_Act_act_uid_12, N'COMP', N'2026-07-29T22:57:05.903', N'2026-07-29T22:57:05.903', N'ACTIVE', N'2026-07-29T22:57:05.903', N'OBS', N'A', N'2026-07-29T22:57:05.903', N'OBS', N'Has Component');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_13, @dbo_Act_act_uid_14, N'COMP', N'2026-07-29T22:57:05.907', N'2026-07-29T22:57:05.907', N'ACTIVE', N'2026-07-29T22:57:05.907', N'OBS', N'A', N'2026-07-29T22:57:05.907', N'OBS', N'Is Cause For');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_11, @dbo_Act_act_uid_13, N'APND', N'2026-07-29T22:57:05.907', N'2026-07-29T22:57:05.907', N'ACTIVE', N'2026-07-29T22:57:05.907', N'OBS', N'A', N'2026-07-29T22:57:05.907', N'OBS', N'Appends');
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd], [type_desc_txt]) VALUES (@dbo_Act_act_uid_11, @dbo_Act_act_uid_15, N'COMP', N'2026-07-29T22:57:05.907', N'2026-07-29T22:57:05.907', N'ACTIVE', N'2026-07-29T22:57:05.907', N'OBS', N'A', N'2026-07-29T22:57:05.907', N'OBS', N'Has Component');

-- dbo.Role
-- step: 1
INSERT INTO [dbo].[Role] ([subject_entity_uid], [cd], [role_seq], [add_time], [cd_desc_txt], [effective_from_time], [effective_to_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [scoping_class_cd], [scoping_entity_uid], [scoping_role_cd], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_6, N'NI', 0, N'2026-07-29T22:57:05.907', N'No Information Given', N'2026-07-29T22:57:05.907', N'2026-07-29T22:57:05.907', N'2026-07-29T22:57:05.907', @superuser_id, N'ACTIVE', N'2026-07-29T22:57:05.907', N'PSN', @dbo_Entity_entity_uid_5, N'PAT', N'A', N'2026-07-29T22:57:05.907', N'SPEC');

-- dbo.Person
-- step: 1
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-07-29T22:57:05.770', [record_status_time] = N'2026-07-29T22:57:05.770', [status_time] = N'2026-07-29T22:57:05.770', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 1
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-07-29T22:57:05.770', [record_status_time] = N'2026-07-29T22:57:05.770', [status_time] = N'2026-07-29T22:57:05.770' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;

-- dbo.Act_relationship
-- step: 1
INSERT INTO [dbo].[Act_relationship] ([target_act_uid], [source_act_uid], [type_cd], [add_time], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [source_class_cd], [status_cd], [status_time], [target_class_cd]) VALUES (@dbo_Act_act_uid_10, @dbo_Act_act_uid_11, N'LabReport', N'2026-07-29T22:57:21.827', N'2026-07-29T22:57:21.827', @superuser_id, N'ACTIVE', N'2026-07-29T22:57:21.827', N'OBS', N'A', N'2026-07-29T22:57:21.827', N'CASE');

-- dbo.Observation
-- step: 1
UPDATE [dbo].[Observation] SET [last_chg_time] = N'2026-07-29T22:57:21.930', [record_status_cd] = N'PROCESSED', [record_status_time] = N'2026-07-29T22:57:21.930', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [observation_uid] = @dbo_Act_act_uid_11;
