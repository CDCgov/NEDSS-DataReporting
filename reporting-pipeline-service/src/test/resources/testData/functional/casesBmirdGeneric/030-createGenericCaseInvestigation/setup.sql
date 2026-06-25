USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;
DECLARE @elruser_id bigint = 10000015;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 1000001000;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 1000001002;
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 1000001004;
DECLARE @dbo_Tele_locator_tele_locator_uid_2 bigint = 1000001005;
DECLARE @dbo_Tele_locator_tele_locator_uid_3 bigint = 1000001006;
DECLARE @dbo_Tele_locator_tele_locator_uid_4 bigint = 1000001007;
DECLARE @dbo_Act_act_uid bigint = 1000001031;
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';
DECLARE @dbo_Public_health_case_local_id nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid))) + N'GA01';
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3_output TABLE ([value] bigint);

-- Alter EPI columns that are not configured to the correct size on RDB_MODERN.dbo.D_INVESTIGATION_REPEAT
ALTER TABLE [RDB_MODERN].[dbo].[D_INVESTIGATION_REPEAT]
  ALTER COLUMN [EPI_CITY_OF_EXP] varchar(2000) NULL;
ALTER TABLE [RDB_MODERN].[dbo].[D_INVESTIGATION_REPEAT]
  ALTER COLUMN [EPI_CNTRY_OF_EXP] varchar(2000) NULL;
ALTER TABLE [RDB_MODERN].[dbo].[D_INVESTIGATION_REPEAT]
  ALTER COLUMN [EPI_CNTY_OF_EXP] varchar(2000) NULL;
ALTER TABLE [RDB_MODERN].[dbo].[D_INVESTIGATION_REPEAT]
  ALTER COLUMN [EPI_ST_OR_PROV_OF_EXP] varchar(2000) NULL;

-- STEP 1: Created a generic case investigation for existing patient
-- dbo.Postal_locator
-- step: 3
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt], [cntry_cd], [cnty_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid, N'2026-06-08T17:11:04.810', @superuser_id, N'Atlanta', N'840', N'13135', N'ACTIVE', N'2026-06-08T17:11:04.810', N'13', N'123 Main St.', N'30024');
-- dbo.Entity_locator_participation
-- step: 3
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Postal_locator_postal_locator_uid, N'H', N'PST', N'2026-06-08T17:11:04.960', @superuser_id, N'ACTIVE', N'2026-06-08T17:11:04.960', N'A', N'2026-06-08T17:11:04.960', N'H', 1, N'2026-06-08T00:00:00');
-- dbo.Tele_locator
-- step: 3
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid, N'2026-06-08T17:11:04.810', @superuser_id, N'', N'456-232-3222', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 3
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Tele_locator_tele_locator_uid, N'PH', N'TELE', N'2026-06-08T17:11:04.960', @superuser_id, N'ACTIVE', N'2026-06-08T17:11:04.960', N'A', N'2026-06-08T17:11:04.960', N'H', 1, N'2026-06-08T00:00:00');
-- dbo.Tele_locator
-- step: 3
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [extension_txt], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_2, N'2026-06-08T17:11:04.810', @superuser_id, N'', N'232-322-2222', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 3
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Tele_locator_tele_locator_uid_2, N'PH', N'TELE', N'2026-06-08T17:11:04.960', @superuser_id, N'ACTIVE', N'2026-06-08T17:11:04.960', N'A', N'2026-06-08T17:11:04.960', N'WP', 1, N'2026-06-08T00:00:00');
-- dbo.Tele_locator
-- step: 3
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_3, N'2026-06-08T17:11:04.810', @superuser_id, N'fdsfs@dsds.com', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 3
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Tele_locator_tele_locator_uid_3, N'NET', N'TELE', N'2026-06-08T17:11:04.960', @superuser_id, N'ACTIVE', N'2026-06-08T17:11:04.960', N'A', N'2026-06-08T17:11:04.960', N'H', 1, N'2026-06-08T00:00:00');
-- dbo.Tele_locator
-- step: 3
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_4, N'2026-06-08T17:11:04.810', @superuser_id, N'232-322-2222', N'ACTIVE');
-- dbo.Entity_locator_participation
-- step: 3
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid, @dbo_Tele_locator_tele_locator_uid_4, N'CP', N'TELE', N'2026-06-08T17:11:04.960', @superuser_id, N'ACTIVE', N'2026-06-08T17:11:04.960', N'A', N'2026-06-08T17:11:04.960', N'MC', 1, N'2026-06-08T00:00:00');
-- dbo.Act
-- step: 3
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid, N'CASE', N'EVN');
-- dbo.Public_health_case
-- step: 3
INSERT INTO [dbo].[Public_health_case] ([public_health_case_uid], [activity_from_time], [add_time], [add_user_id], [case_class_cd], [case_type_cd], [cd], [cd_desc_txt], [detection_method_cd], [disease_imported_cd], [effective_duration_amt], [effective_duration_unit_cd], [group_case_cnt], [investigation_status_cd], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [mmwr_week], [mmwr_year], [outbreak_ind], [outbreak_name], [outcome_cd], [prog_area_cd], [record_status_cd], [record_status_time], [rpt_source_cd], [status_cd], [transmission_mode_cd], [transmission_mode_desc_txt], [txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [hospitalized_ind_cd], [hospitalized_admin_time], [hospitalized_discharge_time], [hospitalized_duration_amt], [pregnant_ind_cd], [day_care_ind_cd], [food_handler_ind_cd], [imported_country_cd], [imported_state_cd], [imported_city_desc_txt], [imported_county_cd], [priority_cd], [contact_inv_txt], [contact_inv_status_cd]) VALUES (@dbo_Act_act_uid, N'2026-06-08T00:00:00', N'2026-06-08T17:11:05.093', @superuser_id, N'C', N'I', N'50225', N'Acanthamoeba Disease (Excluding Keratitis)', N'S', N'', N'', N'', 1, N'O', N'130005', N'2026-06-08T17:11:05.093', @superuser_id, @dbo_Public_health_case_local_id, N'23', N'2026', N'', N'', N'', N'GCD', N'OPEN', N'2026-06-08T17:11:05.093', N'HO', N'A', N'A', N'A', N'', 1300500009, N'T', 1, N'Y', N'2026-06-07T00:00:00', N'2026-06-08T00:00:00', 1, N'', N'', N'', N'', N'', N'', N'', N'', N'', N'');
-- dbo.Confirmation_method
-- step: 3
INSERT INTO [dbo].[Confirmation_method] ([public_health_case_uid], [confirmation_method_cd], [confirmation_method_time]) VALUES (@dbo_Act_act_uid, N'AS', N'2026-06-08T00:00:00');
-- dbo.Act_id
-- step: 3
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid, 1, N'', N'A', N'2026-06-08T17:11:05.120', N'STATE');
-- step: 3
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid, 2, N'', N'A', N'2026-06-08T17:11:05.123', N'CITY');
-- step: 3
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid, 3, N'', N'A', N'2026-06-08T17:11:05.123', N'LEGACY');
-- dbo.Participation
-- step: 3
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid, @dbo_Act_act_uid, N'SubjOfPHC', N'CASE', N'2026-06-08T17:11:04.810', @superuser_id, N'2026-06-08T17:11:04.810', @superuser_id, N'ACTIVE', N'2026-06-08T17:11:04.810', N'A', N'2026-06-08T17:11:04.810', N'PSN', N'Subject Of Public Health Case');
-- step: 3
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003007, @dbo_Act_act_uid, N'HospOfADT', N'CASE', N'2026-06-08T17:11:04.810', @superuser_id, N'2026-06-08T17:11:04.810', @superuser_id, N'ACTIVE', N'2026-06-08T17:11:04.810', N'A', N'2026-06-08T17:11:04.810', N'ORG', N'Hospital Of ADT');
-- step: 3
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003007, @dbo_Act_act_uid, N'OrgAsReporterOfPHC', N'CASE', N'2026-06-08T17:11:04.810', @superuser_id, N'2026-06-08T17:11:04.810', @superuser_id, N'ACTIVE', N'2026-06-08T17:11:04.810', N'A', N'2026-06-08T17:11:04.810', N'ORG', N'Organization As Reporter Of PHC');
-- dbo.NBS_act_entity
-- step: 3
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-06-08T17:11:05.093', @superuser_id, @dbo_Entity_entity_uid, 1, N'2026-06-08T17:11:05.093', @superuser_id, N'OPEN', N'2026-06-08T17:11:05.093', N'SubjOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_output;
-- step: 3
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_2_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-06-08T17:11:05.093', @superuser_id, 10003007, 1, N'2026-06-08T17:11:05.093', @superuser_id, N'OPEN', N'2026-06-08T17:11:05.093', N'HospOfADT');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_2 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_2_output;
-- step: 3
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_3_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-06-08T17:11:05.093', @superuser_id, 10003007, 1, N'2026-06-08T17:11:05.093', @superuser_id, N'OPEN', N'2026-06-08T17:11:05.093', N'OrgAsReporterOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_3 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_3_output;
-- dbo.Person
-- step: 3
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-06-08T17:11:04.940', [record_status_time] = N'2026-06-08T17:11:04.940', [status_time] = N'2026-06-08T17:11:04.940', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = 10000001;
-- dbo.Entity_locator_participation
-- step: 3
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-06-08T17:11:04.940', [record_status_time] = N'2026-06-08T17:11:04.940', [status_time] = N'2026-06-08T17:11:04.940' WHERE [entity_uid] = 10000001 AND [locator_uid] = 10000003;
-- step: 3
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-06-08T17:11:04.940', [record_status_time] = N'2026-06-08T17:11:04.940', [status_time] = N'2026-06-08T17:11:04.940' WHERE [entity_uid] = 10000001 AND [locator_uid] = 10000002;
-- step: 3
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-06-08T17:11:04.940', [record_status_time] = N'2026-06-08T17:11:04.940', [status_time] = N'2026-06-08T17:11:04.940' WHERE [entity_uid] = 10000001 AND [locator_uid] = 10000006;
-- step: 3
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-06-08T17:11:04.940', [record_status_time] = N'2026-06-08T17:11:04.940', [status_time] = N'2026-06-08T17:11:04.940' WHERE [entity_uid] = 10000001 AND [locator_uid] = 10000004;
-- step: 3
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-06-08T17:11:04.940', [record_status_time] = N'2026-06-08T17:11:04.940', [status_time] = N'2026-06-08T17:11:04.940' WHERE [entity_uid] = 10000001 AND [locator_uid] = 10000005;
-- dbo.PublicHealthCaseFact
-- step: 3
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [confirmation_method_cd], [confirmation_method_time], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [detection_method_cd], [detection_method_desc_txt], [ELP_class_cd], [ethnic_group_ind], [ethnic_group_ind_desc], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [jurisdiction_cd], [marital_status_cd], [marital_status_desc_txt], [mart_record_creation_time], [mmwr_week], [mmwr_year], [organizationName], [PAR_type_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [race_concatenated_txt], [race_concatenated_desc_txt], [record_status_cd], [rpt_source_cd], [rpt_source_desc_txt], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [prog_area_desc_txt], [confirmation_method_desc_txt], [LASTUPDATE], [HSPTL_ADMISSION_DT], [HSPTL_DISCHARGE_DT], [hospitalized_ind]) VALUES (@dbo_Act_act_uid, N'Y', 36, N'1990-01-01T00:00:00', N'1990-01-01T00:00:00', N'C', N'I', N'Atlanta', N'AS', N'2026-06-08T00:00:00', N'Gwinnett County', N'840', N'13135', N'M', N'N', N'S', N'Patient self-referral', N'PST', N'2186-5', N'Not Hispanic or Latino', N'2026-06-08T17:11:05.093', N'P', 1.0, N'O', N'130005', N'M', N'Married', N'2026-06-08T17:11:14.127', 23, 2026, N'CHOA - Scottish Rite', N'SubjOfPHC', @dbo_Postal_locator_postal_locator_uid, N'PAT', @dbo_Entity_entity_uid, N'2026-06-08T17:11:05.093', N'50225', N'Acanthamoeba Disease (Excluding Keratitis)', N'Acanthamoeba Disease (Excluding Keratitis)', N'GCD', N'2026-06-08T17:11:04.810', N'ACTIVE', N'2028-9', N'Asian', N'OPEN', N'HO', N'Hospital', N'T', N'Georgia', N'13', N'A', N'123 Main St.', N'H', N'30024', N'Singh, Surma', N'Dekalb County', N'2026-06-08T00:00:00', 1300500009, N'2026-06-08T17:11:05.093', 10000001, @dbo_Person_local_id, N'2026-06-08T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'Confirmed', N'UNITED STATES', N'Male', N'Open', N'GCD', N' Active Surveillance', N'2026-06-08T17:11:05.093', N'2026-06-07T00:00:00', N'2026-06-08T00:00:00', N'Y');
-- dbo.SubjectRaceInfo
-- step: 3
INSERT INTO [dbo].[SubjectRaceInfo] ([morbReport_uid], [public_health_case_uid], [race_cd], [race_category_cd]) VALUES (0, @dbo_Act_act_uid, N'2028-9', N'2028-9');
