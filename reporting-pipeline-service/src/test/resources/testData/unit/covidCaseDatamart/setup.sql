USE NBS_ODSE;

-----------------------------------------------------------------------
-- SHARED CLEANUPS
-----------------------------------------------------------------------
-- Cleanup ODSE
DELETE FROM [dbo].[NBS_case_answer];
DELETE FROM [dbo].[NBS_act_entity];
DELETE FROM [dbo].[Participation];
DELETE FROM [dbo].[Act_id];
DELETE FROM [dbo].[Public_health_case];
DELETE FROM [dbo].[Act];
DELETE FROM [dbo].[Person_race];
DELETE FROM [dbo].[Person_name];
DELETE FROM [dbo].[Person];
DELETE FROM [dbo].[Organization_name];
DELETE FROM [dbo].[Organization];
DELETE FROM [dbo].[Entity_locator_participation];
DELETE FROM [dbo].[Postal_locator];
DELETE FROM [dbo].[Tele_locator];
DELETE FROM [dbo].[Entity];

-- Cleanup Modern RDB
DELETE FROM RDB_MODERN.DBO.COVID_CASE_DATAMART;
DELETE FROM RDB_MODERN.DBO.NRT_INVESTIGATION;
DELETE FROM RDB_MODERN.DBO.INVESTIGATION;
DELETE FROM RDB_MODERN.DBO.NRT_PATIENT;
DELETE FROM RDB_MODERN.DBO.D_PATIENT;
DELETE FROM RDB_MODERN.DBO.NRT_PAGE_CASE_ANSWER;
DELETE FROM RDB_MODERN.DBO.NRT_INVESTIGATION_NOTIFICATION;
DELETE FROM RDB_MODERN.DBO.NRT_INVESTIGATION_CONFIRMATION;
DELETE FROM RDB_MODERN.DBO.D_PROVIDER;
DELETE FROM RDB_MODERN.DBO.D_ORGANIZATION;

DECLARE @superuser_id bigint = 10009282;

-----------------------------------------------------------------------
-- SECTION 1: ODSE SEEDING
-----------------------------------------------------------------------
-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 8502;
DECLARE @dbo_Act_act_uid bigint = 8503;
DECLARE @dbo_Entity_entity_uid_2 bigint = 8504;
DECLARE @dbo_Entity_entity_uid_3 bigint = 8505;
DECLARE @dbo_Entity_entity_uid_4 bigint = 8506;
DECLARE @dbo_Entity_entity_uid_5 bigint = 8507;
DECLARE @dbo_Entity_entity_uid_6 bigint = 8508;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 8509;
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 8510;
DECLARE @dbo_Tele_locator_tele_locator_uid_2 bigint = 8511;
DECLARE @dbo_Tele_locator_tele_locator_uid_3 bigint = 8512;
DECLARE @dbo_Tele_locator_tele_locator_uid_4 bigint = 8513;

-- STEP 1: Start a new COVID19 investigation for Surma Singh

-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid, N'PSN');

-- dbo.Person
-- step: 1
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [age_reported], [age_reported_unit_cd], [birth_time], [birth_time_calc], [cd], [curr_sex_cd], [deceased_ind_cd], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid, N'2026-04-24T23:15:09.073', @superuser_id, N'36', N'Y', N'1990-01-01T00:00:00', N'1990-01-01T00:00:00', N'PAT', N'M', N'Y', N'2030-01-01T00:00:00', @superuser_id, @dbo_Person_local_id, N'ACTIVE', N'2026-04-24T23:15:09.073', N'A', N'2026-04-24T23:15:09.073', N'Surma', N'Singh', 1, @dbo_Entity_entity_uid);

-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_time], [add_user_id], [first_nm], [last_chg_time], [last_chg_user_id], [last_nm], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time]) VALUES (@dbo_Entity_entity_uid, 1, N'2026-04-24T23:15:07.563', @superuser_id, N'Surma', N'2026-04-24T23:15:07.563', @superuser_id, N'Singh', N'L', N'ACTIVE', N'2026-04-24T23:15:07.563', N'A', N'2026-04-24T23:15:07.563');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid, N'CASE', N'EVN');

-- dbo.Public_health_case
-- step: 1
DECLARE @dbo_Public_health_case_local_id nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid))) + N'GA01';
INSERT INTO [dbo].[Public_health_case] ([public_health_case_uid], [activity_from_time], [add_time], [add_user_id], [case_class_cd], [cd], [cd_desc_txt], [diagnosis_time], [effective_duration_amt], [effective_duration_unit_cd], [effective_from_time], [effective_to_time], [investigation_status_cd], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [mmwr_week], [mmwr_year], [outbreak_ind], [outbreak_name], [outcome_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [prog_area_cd], [record_status_cd], [record_status_time], [rpt_form_cmplt_time], [rpt_source_cd], [status_cd], [transmission_mode_cd], [txt], [shared_ind], [version_ctrl_nbr], [hospitalized_ind_cd], [hospitalized_admin_time], [pregnant_ind_cd], [deceased_time], [inv_priority_cd]) VALUES (@dbo_Act_act_uid, N'2026-04-24T00:00:00', N'2026-04-24T23:15:09.197', @superuser_id, N'C', N'11065', N'2019 Novel Coronavirus', N'2026-04-12T00:00:00', N'15', N'D', N'2026-04-05T00:00:00', N'2026-04-20T00:00:00', N'O', N'130001', N'2030-01-01T00:00:00', @superuser_id, @dbo_Public_health_case_local_id, N'16', N'2026', N'Y', N'COVID Outbreak 2026', N'Y', N'36', N'Y', N'GCD', N'OPEN', N'2026-04-24T23:15:09.197', N'2026-04-10T00:00:00', N'OTH', N'A', N'A', N'This is a sample investigation comment.', N'T', 1, N'Y', N'2026-04-17T00:00:00', N'N', N'2026-04-24T00:00:00', N'1');

-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid, @dbo_Act_act_uid, N'SubjOfPHC', N'CASE', N'2026-04-24T23:15:07.597', @superuser_id, N'2026-04-24T23:15:07.597', @superuser_id, N'ACTIVE', N'2026-04-24T23:15:07.607', N'A', N'2026-04-24T23:15:07.607', N'PSN');

-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_2, N'PSN');
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_3, N'PSN');
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_4, N'PSN');
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_5, N'ORG');
-- step: 1
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_6, N'ORG');

-- dbo.Person
-- step: 1
DECLARE @dbo_Person_local_id_2 nvarchar(40) = N'INV' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_2))) + N'';
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [cd], [local_id], [record_status_cd], [version_ctrl_nbr], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_2, N'2026-04-30T03:32:35.397', @superuser_id, N'PRV', @dbo_Person_local_id_2, N'ACTIVE', 1, @dbo_Entity_entity_uid_2);
-- step: 1
DECLARE @dbo_Person_local_id_3 nvarchar(40) = N'PHY' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_3))) + N'';
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [cd], [local_id], [record_status_cd], [version_ctrl_nbr], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_3, N'2026-04-30T03:32:35.397', @superuser_id, N'PRV', @dbo_Person_local_id_3, N'ACTIVE', 1, @dbo_Entity_entity_uid_3);
-- step: 1
DECLARE @dbo_Person_local_id_4 nvarchar(40) = N'REP' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_4))) + N'';
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [cd], [local_id], [record_status_cd], [version_ctrl_nbr], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_4, N'2026-04-30T03:32:35.397', @superuser_id, N'PRV', @dbo_Person_local_id_4, N'ACTIVE', 1, @dbo_Entity_entity_uid_4);

-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_time], [add_user_id], [first_nm], [last_nm], [nm_use_cd], [record_status_cd], [status_cd], [status_time]) VALUES (@dbo_Entity_entity_uid_2, 1, N'2026-04-30T03:32:35.400', @superuser_id, N'Super', N'User', N'L', N'ACTIVE', N'A', N'2026-04-30T03:32:35.400');
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_time], [add_user_id], [first_nm], [last_nm], [nm_use_cd], [record_status_cd], [status_cd], [status_time]) VALUES (@dbo_Entity_entity_uid_3, 1, N'2026-04-30T03:32:35.400', @superuser_id, N'John', N'Physician', N'L', N'ACTIVE', N'A', N'2026-04-30T03:32:35.400');
-- step: 1
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_time], [add_user_id], [first_nm], [last_nm], [nm_use_cd], [record_status_cd], [status_cd], [status_time]) VALUES (@dbo_Entity_entity_uid_4, 1, N'2026-04-30T03:32:35.400', @superuser_id, N'Jane', N'Reporter', N'L', N'ACTIVE', N'A', N'2026-04-30T03:32:35.400');

-- dbo.Organization
-- step: 1
DECLARE @dbo_Organization_local_id nvarchar(40) = N'HOSP' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_5))) + N'';
INSERT INTO [dbo].[Organization] ([organization_uid], [add_time], [add_user_id], [local_id], [record_status_cd], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid_5, N'2026-04-30T03:32:35.400', @superuser_id, @dbo_Organization_local_id, N'ACTIVE', 1);
-- step: 1
DECLARE @dbo_Organization_local_id_2 nvarchar(40) = N'AGEN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid_6))) + N'';
INSERT INTO [dbo].[Organization] ([organization_uid], [add_time], [add_user_id], [local_id], [record_status_cd], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid_6, N'2026-04-30T03:32:35.400', @superuser_id, @dbo_Organization_local_id_2, N'ACTIVE', 1);

-- dbo.Organization_name
-- step: 1
INSERT INTO [dbo].[Organization_name] ([organization_uid], [organization_name_seq], [nm_txt], [nm_use_cd], [record_status_cd]) VALUES (@dbo_Entity_entity_uid_5, 1, N'General Hospital', N'L', N'ACTIVE');
-- step: 1
INSERT INTO [dbo].[Organization_name] ([organization_uid], [organization_name_seq], [nm_txt], [nm_use_cd], [record_status_cd]) VALUES (@dbo_Entity_entity_uid_6, 1, N'Reporting Agency', N'L', N'ACTIVE');

-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [record_status_cd], [status_cd], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Act_act_uid, N'InvestgrOfPHC', N'PHC', N'2026-04-30T03:32:35.403', @superuser_id, N'ACTIVE', N'A', N'PSN');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [record_status_cd], [status_cd], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_3, @dbo_Act_act_uid, N'PhysicianOfPHC', N'PHC', N'2026-04-30T03:32:35.403', @superuser_id, N'ACTIVE', N'A', N'PSN');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [record_status_cd], [status_cd], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_4, @dbo_Act_act_uid, N'PerAsReporterOfPHC', N'PHC', N'2026-04-30T03:32:35.403', @superuser_id, N'ACTIVE', N'A', N'PSN');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [record_status_cd], [status_cd], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_6, @dbo_Act_act_uid, N'OrgAsReporterOfPHC', N'PHC', N'2026-04-30T03:32:35.403', @superuser_id, N'ACTIVE', N'A', N'ORG');
-- step: 1
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [record_status_cd], [status_cd], [subject_class_cd]) VALUES (@dbo_Entity_entity_uid_5, @dbo_Act_act_uid, N'HospOfADT', N'PHC', N'2026-04-30T03:32:35.403', @superuser_id, N'ACTIVE', N'A', N'ORG');

-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid, 10009291, N'2026-04-30T03:32:35.407', @superuser_id, N'H', N'PST', N'2026-04-30T03:32:35.407', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.407', N'A', N'2026-04-30T03:32:35.407', N'H', 1);
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid, 10009292, N'2026-04-30T03:32:35.407', @superuser_id, N'PH', N'TELE', N'2026-04-30T03:32:35.407', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.407', N'A', N'2026-04-30T03:32:35.407', N'H', 1);
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid, 10009293, N'2026-04-30T03:32:35.407', @superuser_id, N'PH', N'TELE', N'2026-04-30T03:32:35.407', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.407', N'A', N'2026-04-30T03:32:35.407', N'WP', 1);
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid, 10009294, N'2026-04-30T03:32:35.407', @superuser_id, N'CP', N'TELE', N'2026-04-30T03:32:35.407', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.407', N'A', N'2026-04-30T03:32:35.407', N'MC', 1);
-- step: 1
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr]) VALUES (@dbo_Entity_entity_uid, 10009295, N'2026-04-30T03:32:35.407', @superuser_id, N'NET', N'TELE', N'2026-04-30T03:32:35.407', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.407', N'A', N'2026-04-30T03:32:35.407', N'H', 1);

-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt], [cntry_cd], [cnty_cd], [record_status_cd], [state_cd], [street_addr1], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid, N'2026-04-30T03:32:35.410', @superuser_id, N'Atlanta', N'840', N'13135', N'ACTIVE', N'13', N'123 Main St.', N'30024');

-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid, N'2026-04-30T03:32:35.413', @superuser_id, N'456-232-3222', N'ACTIVE');
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_2, N'2026-04-30T03:32:35.413', @superuser_id, N'232-322-2222', N'ACTIVE');
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_3, N'2026-04-30T03:32:35.413', @superuser_id, N'232-322-2222', N'ACTIVE');
-- step: 1
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd]) VALUES (@dbo_Tele_locator_tele_locator_uid_4, N'2026-04-30T03:32:35.413', @superuser_id, N'fdsfs@dsds.com', N'ACTIVE');

-- dbo.Act_id
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [add_time], [add_user_id], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid, 1, N'2026-04-30T03:32:35.417', @superuser_id, N'ACTIVE', N'XYZ1234', N'A', N'2026-04-30T03:32:35.417', N'STATE');
-- step: 1
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [add_time], [add_user_id], [record_status_cd], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid, 2, N'2026-04-30T03:32:35.417', @superuser_id, N'ACTIVE', N'', N'A', N'2026-04-30T03:32:35.417', N'LEGACY');

-- dbo.NBS_case_answer
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Clinical evaluation', 10004138, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_2 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_2_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_2_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'SARS-CoV-2 variant B.1.1.7 (501Y.V1)', 10010318, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_2 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_2_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_3_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Yes', 10006139, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_3 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_3_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_4 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_4_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_4_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10010298, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_4 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_4_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_5 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_5_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_5_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004132, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_5 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_5_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_6 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_6_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_6_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Apartment', 10001159, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_6 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_6_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_7 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_7_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_7_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Atlanta', 10000006, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_7 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_7_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_8 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_8_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_8_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10001396, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_8 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_8_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_9 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_9_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_9_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Normal', 10004182, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_9 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_9_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_10 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_10_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_10_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004161, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_10 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_10_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_11 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_11_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_11_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004160, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_11 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_11_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_12 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_12_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_12_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10001390, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_12 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_12_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_13 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_13_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_13_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004165, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_13 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_13_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_14 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_14_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_14_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004181, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_14 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_14_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_15 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_15_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_15_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004164, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_15 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_15_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_16 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_16_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_16_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004199, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_16 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_16_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_17 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_17_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_17_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10010301, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_17 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_17_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_18 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_18_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_18_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Yes', 10004190, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_18 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_18_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_19 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_19_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_19_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004209, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_19 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_19_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_20 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_20_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_20_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004210, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_20 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_20_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_21 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_21_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_21_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004208, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_21 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_21_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_22 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_22_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_22_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004163, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_22 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_22_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_23 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_23_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_23_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Yes', 10004192, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_23 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_23_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_24 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_24_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_24_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Yes', 10004195, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_24 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_24_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_25 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_25_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_25_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004155, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_25 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_25_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_26 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_26_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_26_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004207, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_26 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_26_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_27 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_27_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_27_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004205, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_27 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_27_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_28 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_28_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_28_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10001395, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_28 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_28_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_29 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_29_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_29_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Yes', 10004198, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_29 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_29_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_30 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_30_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_30_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Yes', 10004197, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_30 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_30_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_31 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_31_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_31_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Yes', 10001380, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_31 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_31_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_32 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_32_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_32_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Yes', 10001378, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_32 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_32_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_33 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_33_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_33_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Yes', 10004189, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_33 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_33_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_34 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_34_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_34_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Yes', 10001382, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_34 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_34_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_35 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_35_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_35_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004238, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_35 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_35_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_36 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_36_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_36_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'clerk', 10005133, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_36 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_36_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_37 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_37_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_37_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Judicial law clerks [2105]', 10005132, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_37 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_37_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_38 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_38_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_38_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Other', 10004149, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_38 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_38_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_39 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_39_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_39_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Other', 10004150, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_39 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_39_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_40 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_40_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_40_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10001384, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_40 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_40_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_41 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_41_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_41_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10001383, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_41 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_41_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_42 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_42_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_42_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004212, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_42 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_42_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_43 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_43_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_43_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004193, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_43 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_43_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_44 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_44_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_44_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004159, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_44 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_44_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_45 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_45_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_45_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004156, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_45 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_45_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_46 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_46_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_46_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004152, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_46 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_46_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_47 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_47_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_47_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'UNITED STATES', 10001008, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_47 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_47_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_48 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_48_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_48_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Georgia', 10001009, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_48 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_48_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_49 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_49_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_49_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Other', 10009148, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_49 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_49_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_50 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_50_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_50_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Hamster', 10004166, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_50 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_50_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_51 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_51_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_51_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'102.5', 10004188, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_51 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_51_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_52 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_52_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_52_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'04/10/2026', 10004141, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_52 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_52_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_53 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_53_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_53_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'SPEC12345', 10004232, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_53 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_53_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_54 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_54_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_54_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Yes', 10004201, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_54 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_54_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_55 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_55_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_55_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Loss of appetite', 10004202, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_55 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_55_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_56 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_56_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_56_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Yes', 10004204, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_56 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_56_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_57 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_57_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_57_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Atlanta', 10001010, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_57 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_57_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_58 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_58_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_58_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'Fulton', 10001011, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_58 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_58_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_59 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_59_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_59_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004167, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_59 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_59_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_60 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_60_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_60_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004169, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_60 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_60_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_61 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_61_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_61_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'No', 10004144, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_61 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_61_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_62 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_62_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_62_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'04/17/2026', 10004145, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_62 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_62_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_63 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_63_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_63_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'04/20/2026', 10004146, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_63 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_63_output;
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_64 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_64_output TABLE ([value] bigint);
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [answer_group_seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_64_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-04-30T03:32:35.420', @superuser_id, N'COVID Outbreak 2026', 1338, 1, N'2026-04-30T03:32:35.420', @superuser_id, N'ACTIVE', N'2026-04-30T03:32:35.420', 1);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_64 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_64_output;

-- dbo.PublicHealthCaseFact
-- step: 1
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_time], [birth_time_calc], [case_class_cd], [city_desc_txt], [county], [cntry_cd], [cnty_cd], [curr_sex_cd], [deceased_ind_cd], [diagnosis_date], [ELP_class_cd], [event_date], [event_type], [investigation_status_cd], [investigatorName], [jurisdiction_cd], [mart_record_creation_time], [mmwr_week], [mmwr_year], [onSetDate], [organizationName], [outcome_cd], [outbreak_ind], [outbreak_name], [PAR_type_cd], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [providerName], [PST_record_status_cd], [record_status_cd], [reporterName], [rpt_form_cmplt_time], [rpt_source_cd], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [report_date], [person_parent_uid], [person_local_id], [state_case_id], [LOCAL_ID], [age_reported_unit_desc_txt], [case_class_desc_txt], [cntry_desc_txt], [curr_sex_desc_txt], [investigation_status_desc_txt], [outcome_desc_txt], [pat_age_at_onset_unit_desc_txt], [prog_area_desc_txt], [LASTUPDATE], [PHCTXT], [HSPTL_ADMISSION_DT], [hospitalized_ind]) VALUES (@dbo_Act_act_uid, N'Y', 36, N'1990-01-01T00:00:00', N'1990-01-01T00:00:00', N'C', N'Atlanta', N'Gwinnett County', N'840', N'13135', N'M', N'Y', N'2026-04-12T00:00:00', N'PST', N'2026-04-05T00:00:00', N'O', N'O', N'User, Super', N'130001', N'2026-04-30T03:32:39.793', 16, 2026, N'2026-04-05T00:00:00', N'Reporting Agency', N'Y', N'Y', N'COVID Outbreak 2026', N'SubjOfPHC', 36, N'Y', @dbo_Postal_locator_postal_locator_uid, N'PAT', @dbo_Entity_entity_uid, N'2026-04-24T23:15:09.197', N'11065', N'2019 Novel Coronavirus', N'2019 Novel Coronavirus', N'GCD', N'Physician, John', N'ACTIVE', N'OPEN', N'Reporter, Jane', N'2026-04-10T00:00:00', N'OTH', N'T', N'Georgia', N'13', N'A', N'123 Main St.', N'H', N'30024', N'Singh, Surma', N'Fulton County', N'2026-04-24T00:00:00', N'2026-04-24T23:15:09.197', 10009283, @dbo_Person_local_id, N'XYZ1234', @dbo_Public_health_case_local_id, N'Years', N'Confirmed', N'UNITED STATES', N'Male', N'Open', N'Yes', N'Years', N'GCD', N'2030-01-01T00:00:00', N'This is a sample investigation comment.', N'2026-04-17T00:00:00', N'Y');

-----------------------------------------------------------------------
-- SECTION 2: RDB_MODERN SEEDING
-----------------------------------------------------------------------
USE RDB_MODERN;
-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_nrt_organization_organization_uid bigint = 10000000;
DECLARE @dbo_nrt_organization_organization_uid_2 bigint = 10000001;
DECLARE @dbo_nrt_patient_patient_uid bigint = 10000002;
DECLARE @dbo_nrt_investigation_public_health_case_uid bigint = 10000003;
DECLARE @dbo_nrt_provider_provider_uid bigint = 10000004;
DECLARE @dbo_nrt_provider_provider_uid_2 bigint = 10000005;
DECLARE @dbo_nrt_provider_provider_uid_3 bigint = 10000006;

-- STEP 1: Start a new COVID19 investigation for Surma Singh

-- dbo.nrt_organization
-- step: 1
DECLARE @dbo_nrt_organization_local_id nvarchar(40) = N'HOSP' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_organization_organization_uid))) + N'';
INSERT INTO [dbo].[nrt_organization] ([organization_uid], [local_id], [record_status], [organization_name], [add_user_id], [add_user_name], [add_time]) VALUES (@dbo_nrt_organization_organization_uid, @dbo_nrt_organization_local_id, N'ACTIVE', N'General Hospital', @superuser_id, N'Kent, Ariella', N'2026-04-30T03:32:35.400');
-- step: 1
DECLARE @dbo_nrt_organization_local_id_2 nvarchar(40) = N'AGEN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_organization_organization_uid_2))) + N'';
INSERT INTO [dbo].[nrt_organization] ([organization_uid], [local_id], [record_status], [organization_name], [add_user_id], [add_user_name], [add_time]) VALUES (@dbo_nrt_organization_organization_uid_2, @dbo_nrt_organization_local_id_2, N'ACTIVE', N'Reporting Agency', @superuser_id, N'Kent, Ariella', N'2026-04-30T03:32:35.400');

-- dbo.nrt_patient
-- step: 1
DECLARE @dbo_nrt_patient_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_patient_patient_uid))) + N'GA01';
DECLARE @dbo_nrt_patient_patient_mpr_uid bigint = @dbo_nrt_patient_patient_uid + 1;
INSERT INTO [dbo].[nrt_patient] ([patient_uid], [patient_mpr_uid], [record_status], [local_id], [first_name], [last_name], [nm_use_cd], [status_name_cd], [street_address_1], [city], [state], [state_code], [zip], [county], [county_code], [country], [country_code], [phone_home], [phone_work], [phone_cell], [email], [dob], [age_reported], [age_reported_unit], [age_reported_unit_cd], [current_sex], [curr_sex_cd], [deceased_indicator], [deceased_ind_cd], [add_user_id], [add_user_name], [add_time], [last_chg_user_id], [last_chg_user_name], [last_chg_time]) VALUES (@dbo_nrt_patient_patient_uid, @dbo_nrt_patient_patient_mpr_uid, N'ACTIVE', @dbo_nrt_patient_local_id, N'Surma', N'Singh', N'L', N'A', N'123 Main St.', N'Atlanta', N'Georgia', N'13', N'30024', N'Gwinnett County', N'13135', N'United States', N'840', N'456-232-3222', N'232-322-2222', N'232-322-2222', N'fdsfs@dsds.com', N'1990-01-01T00:00:00', 36, N'Years', N'Y', N'Male', N'M', N'Yes', N'Y', @superuser_id, N'Kent, Ariella', N'2026-04-24T23:15:09.073', @superuser_id, N'Kent, Ariella', N'2030-01-01T00:00:00');

-- dbo.nrt_page_case_answer
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3306, 10023339, 10057831, 1338, N'INVESTIGATION', N'OUTBREAK_NAME', N'COVID Outbreak 2026', N'1', N'PG_COVID-19_v1.1', N'INV151', N'PUBLIC_HEALTH_CASE.OUTBREAK_NAME', N'Outbreak Name', N'F', N'CODED', 1820, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [mask], [data_type], [last_chg_time], [record_status_cd], [part_type_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3247, 10023171, 10057636, 10000006, N'D_PROVIDER', N'PROVIDER_CITY', N'Atlanta', N'1', N'PG_COVID-19_v1.1', N'NBS051', N'POSTAL_LOCATOR.CITY_DESC_TXT', N'City', N'TXT', N'TEXT', N'2026-04-30T03:32:35.420', N'ACTIVE', N'PhysicianOfPHC', 1777519958514, 1008, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [question_group_seq_nbr], [code_set_group_id], [block_nm], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3289, 10023348, 10057845, 10001008, N'D_INVESTIGATION_REPEAT', N'EPI_CNTRY_OF_EXP', N'UNITED STATES', N'1', N'PG_COVID-19_v1.1', N'INV502', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Country of Exposure', N'F', N'CODED', 1, 3560, N'EXPOSURE_LOCATION', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [question_group_seq_nbr], [code_set_group_id], [block_nm], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3290, 10023349, 10057847, 10001009, N'D_INVESTIGATION_REPEAT', N'EPI_ST_OR_PROV_OF_EXP', N'Georgia', N'1', N'PG_COVID-19_v1.1', N'INV503', N'NBS_CASE_ANSWER.ANSWER_TXT', N'State or Province of Exposure', N'F', N'CODED', 1, 102970, N'EXPOSURE_LOCATION', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [mask], [data_type], [question_group_seq_nbr], [block_nm], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3299, 10023350, 10057849, 10001010, N'D_INVESTIGATION_REPEAT', N'EPI_CITY_OF_EXP', N'Atlanta', N'1', N'PG_COVID-19_v1.1', N'INV504', N'NBS_CASE_ANSWER.ANSWER_TXT', N'City of Exposure', N'TXT', N'TEXT', 1, N'EXPOSURE_LOCATION', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1008, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [question_group_seq_nbr], [code_set_group_id], [block_nm], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3300, 10023351, 10057851, 10001011, N'D_INVESTIGATION_REPEAT', N'EPI_CNTY_OF_EXP', N'Fulton', N'1', N'PG_COVID-19_v1.1', N'INV505', N'NBS_CASE_ANSWER.ANSWER_TXT', N'County of Exposure', N'F', N'CODED', 1, 560, N'EXPOSURE_LOCATION', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3246, 10023375, 10057876, 10001159, N'D_INV_PATIENT_OBS', N'IPO_TYPE_OF_RESIDENCE', N'Apartment', N'1', N'PG_COVID-19_v1.1', N'NBS202', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Which would best describe where the patient was staying at the time of illness onset?', N'T', N'CODED', 108100, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3274, 10023460, 10058001, 10001378, N'D_INV_SYMPTOM', N'SYM_FEVER', N'Yes', N'1', N'PG_COVID-19_v1.1', N'386661006', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Fever >100.4F (38C)', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3273, 10023471, 10058022, 10001380, N'D_INV_SYMPTOM', N'SYM_FATIGUE_MALAISE', N'Yes', N'1', N'PG_COVID-19_v1.1', N'271795006', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Fatigue or malaise', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3276, 10023470, 10058020, 10001382, N'D_INV_SYMPTOM', N'SYM_HEADACHE', N'Yes', N'1', N'PG_COVID-19_v1.1', N'25064002', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Headache', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3283, 10023465, 10058010, 10001383, N'D_INV_SYMPTOM', N'SYM_MYALGIA', N'No', N'1', N'PG_COVID-19_v1.1', N'68962001', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Muscle aches (myalgia)', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3254, 10023472, 10058024, 10001390, N'D_INV_SYMPTOM', N'SYM_ALTERED_MENTAL_STATUS', N'No', N'1', N'PG_COVID-19_v1.1', N'419284004', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Altered Mental Status', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3270, 10023486, 10058052, 10001395, N'D_INV_SYMPTOM', N'SYM_DIARRHEA', N'No', N'1', N'PG_COVID-19_v1.1', N'62315008', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Diarrhea (=3 loose/looser than normal stools/24hr period)', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3250, 10023485, 10058050, 10001396, N'D_INV_SYMPTOM', N'SYM_ABDOMINAL_PAIN', N'No', N'1', N'PG_COVID-19_v1.1', N'21522001', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Abdominal Pain or Tenderness', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3245, 10023268, 10057740, 10004132, N'D_INV_PATIENT_OBS', N'IPO_TRIBAL_AFFIL_IND', N'No', N'1', N'PG_COVID-19_v1.1', N'NBS681', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Does this case have any tribal affiliation?', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3241, 10023293, 10057772, 10004138, N'D_INV_ADMINISTRATIVE', N'ADM_CASE_IDENTIFY_PROCESS', N'Clinical evaluation', N'1', N'PG_COVID-19_v1.1', N'NBS551', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Under what process was the case first identified?', N'T', N'CODED', 108030, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1013, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [mask], [data_type], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3294, 10023295, 10057776, 10004141, N'D_INV_LAB_FINDING', N'LAB_FRST_POS_SPEC_CLCT_DT', N'04/10/2026', N'1', N'PG_COVID-19_v1.1', N'NBS550', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Date of first positive specimen collection', N'DATE', N'DATE', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1008, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3303, 10023326, 10057814, 10004144, N'D_INV_CLINICAL', N'CLN_HOSPITAL_ICU_STAY', N'No', N'1', N'PG_COVID-19_v1.1', N'309904001', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Was the patient admitted to an intensive care unit (ICU)?', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [mask], [data_type], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3304, 10023327, 10057816, 10004145, N'D_INV_CLINICAL', N'CLN_UNIT_ADMIT_DT', N'04/17/2026', N'1', N'PG_COVID-19_v1.1', N'NBS679', N'NBS_CASE_ANSWER.ANSWER_TXT', N'ICU Admission Date', N'DATE', N'DATE', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1008, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [mask], [data_type], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3305, 10023328, 10057818, 10004146, N'D_INV_CLINICAL', N'CLN_UNIT_DISCHARGE_DT', N'04/20/2026', N'1', N'PG_COVID-19_v1.1', N'NBS680', N'NBS_CASE_ANSWER.ANSWER_TXT', N'ICU Discharge Date', N'DATE', N'DATE', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1008, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3280, 10023379, 10057880, 10004149, N'D_INV_PATIENT_OBS', N'IPO_HCW_OCCUPATION', N'Other', N'1', N'PG_COVID-19_v1.1', N'14679004', N'NBS_CASE_ANSWER.ANSWER_TXT', N'If yes, what is their occupation (type of job)?', N'T', N'CODED', 108460, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3281, 10023380, 10057882, 10004150, N'D_INV_PATIENT_OBS', N'IPO_HCW_SETTING', N'Other', N'1', N'PG_COVID-19_v1.1', N'NBS683', N'NBS_CASE_ANSWER.ANSWER_TXT', N'If yes, what is their job setting?', N'T', N'CODED', 108440, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [question_group_seq_nbr], [code_set_group_id], [block_nm], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3288, 10023390, 10057894, 10004152, N'D_INVESTIGATION_REPEAT', N'TRV_TRAVEL_STATE', N'No', N'1', N'PG_COVID-19_v1.1', N'82754_3', N'NBS_CASE_ANSWER.ANSWER_TXT', N'State of Travel', N'F', N'CODED', 5, 3920, N'TRAVEL_EVENT', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3267, 10023386, 10057888, 10004155, N'D_INV_TRAVEL', N'TRV_CRUISE_TRAVEL_EXP', N'No', N'1', N'PG_COVID-19_v1.1', N'473085002', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Cruise ship or vessel travel as passenger or crew member', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [mask], [data_type], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3287, 10023387, 10057890, 10004156, N'D_INV_TRAVEL', N'TRV_SHIP_NAME', N'No', N'1', N'PG_COVID-19_v1.1', N'NBS690', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Specify Name of Ship or Vessel', N'TXT', N'TEXT', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1008, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [mask], [data_type], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3286, 10023580, 10058171, 10004159, N'D_INV_RISK_FACTOR', N'RSK_WKPLC_SETTING', N'No', N'1', N'PG_COVID-19_v1.1', N'NBS686', N'NBS_CASE_ANSWER.ANSWER_TXT', N'If yes, specify workplace setting (Retired)', N'TXT', N'TEXT', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1008, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3253, 10023402, 10057910, 10004160, N'D_INV_TRAVEL', N'TRV_AIR_TRAVEL_EXP', N'No', N'1', N'PG_COVID-19_v1.1', N'445000002', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Airport/Airplane', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3252, 10023403, 10057912, 10004161, N'D_INV_RISK_FACTOR', N'RSK_ADULT_CONG_LIVING_EXP', N'No', N'1', N'PG_COVID-19_v1.1', N'NBS687', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Adult Congregate Living Facility (nursing, assisted living, or LTC facility)', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3264, 10023404, 10057914, 10004163, N'D_INV_RISK_FACTOR', N'RSK_CORRECTIONAL_EXP', N'No', N'1', N'PG_COVID-19_v1.1', N'NBS689', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Correctional Facility', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3257, 10023407, 10057920, 10004164, N'D_INV_RISK_FACTOR', N'RSK_ATTEND_EVENTS', N'No', N'1', N'PG_COVID-19_v1.1', N'FDD_Q_184', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Community Event/Mass Gathering', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3255, 10023408, 10057922, 10004165, N'D_INV_EPIDEMIOLOGY', N'EPI_ANIMAL_EXPOSURE_IND', N'No', N'1', N'PG_COVID-19_v1.1', N'NBS559', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Animal with confirmed or suspected COVID-19', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [mask], [data_type], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3292, 10023581, 10058172, 10004166, N'D_INV_EPIDEMIOLOGY', N'EPI_ANIMAL_TYPE_TXT', N'Hamster', N'1', N'PG_COVID-19_v1.1', N'FDD_Q_32_TXT', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Specify Type of Animal (Retired)', N'TXT', N'TEXT', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1008, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3301, 10023410, 10057926, 10004167, N'D_INV_EPIDEMIOLOGY', N'EPI_OTH_EXPOSURE_IND', N'No', N'1', N'PG_COVID-19_v1.1', N'NBS560', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Other Exposure', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3302, 10023412, 10057930, 10004169, N'D_INV_EPIDEMIOLOGY', N'EPI_UNK_EXPOSURE_SOURCE', N'No', N'1', N'PG_COVID-19_v1.1', N'NBS667', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Unknown exposures in the 14 days prior to illness onset', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3256, 10023442, 10057969, 10004181, N'D_INV_COMPLICATION', N'CMP_ARDS_IND', N'No', N'1', N'PG_COVID-19_v1.1', N'67782005', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Did the patient have acute respiratory distress syndrome?', N'F', N'CODED', 108430, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3251, 10023443, 10057971, 10004182, N'D_INV_CLINICAL', N'CLN_ABN_CHEST_XRAY_IND', N'Normal', N'1', N'PG_COVID-19_v1.1', N'168734001', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Did the patient have an abnormal chest X-ray?', N'F', N'CODED', 108430, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [unit_value], [question_identifier], [data_location], [question_label], [unit_type_cd], [mask], [data_type], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3293, 10023461, 10058003, 10004188, N'D_INV_SYMPTOM', N'SYM_FEVER_HIGHEST_TEMP', N'102.5', N'1', N'PG_COVID-19_v1.1', N'2650', N'INV202', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Highest Measured Temperature', N'CODED', N'NUM_TEMP', N'NUMERIC', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1008, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3275, 10023462, 10058004, 10004189, N'D_INV_SYMPTOM', N'SYM_FEVERISH', N'Yes', N'1', N'PG_COVID-19_v1.1', N'103001002', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Subjective fever (felt feverish)', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3260, 10023463, 10058006, 10004190, N'D_INV_SYMPTOM', N'SYM_CHILLS_IND', N'Yes', N'1', N'PG_COVID-19_v1.1', N'28376_2', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Chills', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3265, 10023466, 10058012, 10004192, N'D_INV_SYMPTOM', N'SYM_CORYZA_RUNNY_NOSE_IND', N'Yes', N'1', N'PG_COVID-19_v1.1', N'82272006', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Runny nose (rhinorrhea)', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3285, 10023467, 10058014, 10004193, N'D_INV_SYMPTOM', N'SYM_SORE_THROAT_IND', N'No', N'1', N'PG_COVID-19_v1.1', N'267102003', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Sore Throat', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3266, 10023478, 10058036, 10004195, N'D_INV_SYMPTOM', N'SYM_COUGH_IND', N'Yes', N'1', N'PG_COVID-19_v1.1', N'49727002', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Cough (new onset or worsening of chronic cough)', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3272, 10023480, 10058040, 10004197, N'D_INV_SYMPTOM', N'SYM_DYSPNEA_IND', N'Yes', N'1', N'PG_COVID-19_v1.1', N'267036007', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Shortness of Breath (dyspnea)', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3271, 10023481, 10058042, 10004198, N'D_INV_SYMPTOM', N'SYM_DIFFICULT_BREATH_IND', N'Yes', N'1', N'PG_COVID-19_v1.1', N'230145002', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Difficulty Breathing', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3258, 10023482, 10058044, 10004199, N'D_INV_SYMPTOM', N'SYM_CHEST_PAIN_IND', N'No', N'1', N'PG_COVID-19_v1.1', N'29857009', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Chest Pain', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3296, 10023488, 10058055, 10004201, N'D_INV_SYMPTOM', N'SYM_OTH_SYMPTOM_IND', N'Yes', N'1', N'PG_COVID-19_v1.1', N'NBS338', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Other symptom(s)?', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [mask], [data_type], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3297, 10023489, 10058057, 10004202, N'D_INV_SYMPTOM', N'SYM_OTHER_SYMPTOM_SPEC', N'Loss of appetite', N'1', N'PG_COVID-19_v1.1', N'NBS338_OTH', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Other Symptoms', N'TXT', N'TEXT', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1009, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3298, 10023494, 10058060, 10004204, N'D_INV_MEDICAL_HISTORY', N'MDH_PREEXISTING_COND_IND', N'Yes', N'1', N'PG_COVID-19_v1.1', N'102478008', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Pre-existing medical conditions?', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3269, 10023496, 10058062, 10004205, N'D_INV_MEDICAL_HISTORY', N'MDH_DIABETES_MELLITUS_IND', N'No', N'1', N'PG_COVID-19_v1.1', N'73211009', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Diabetes Mellitus', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3268, 10023499, 10058068, 10004207, N'D_INV_MEDICAL_HISTORY', N'MDH_CV_DISEASE_IND', N'No', N'1', N'PG_COVID-19_v1.1', N'128487001', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Cardiovascular disease', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3263, 10023500, 10058070, 10004208, N'D_INV_MEDICAL_HISTORY', N'MDH_CHRONIC_RENAL_DIS_IND', N'No', N'1', N'PG_COVID-19_v1.1', N'709044004', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Chronic Renal disease', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3261, 10023501, 10058072, 10004209, N'D_INV_MEDICAL_HISTORY', N'MDH_CHRONIC_LIVER_DIS_IND', N'No', N'1', N'PG_COVID-19_v1.1', N'328383001', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Chronic Liver disease', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3262, 10023502, 10058074, 10004210, N'D_INV_MEDICAL_HISTORY', N'MDH_CHRONIC_LUNG_DIS_IND', N'No', N'1', N'PG_COVID-19_v1.1', N'413839001', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Chronic Lung Disease (asthma/emphysema/COPD)', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [mask], [data_type], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3284, 10023504, 10058078, 10004212, N'D_INV_MEDICAL_HISTORY', N'MDH_OTH_CHRONIC_DIS_TXT', N'No', N'1', N'PG_COVID-19_v1.1', N'NBS662_OTH', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Specify Other Chronic Diseases', N'TXT', N'TEXT', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1008, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [mask], [data_type], [question_group_seq_nbr], [block_nm], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3295, 10023555, 10058155, 10004232, N'D_INVESTIGATION_REPEAT', N'LAB_CDC_SPECIMEN_ID', N'SPEC12345', N'1', N'PG_COVID-19_v1.1', N'INV965', N'NBS_CASE_ANSWER.ANSWER_TXT', N'CDC Specimen ID Number', N'TXT', N'TEXT', 4, N'LAB_INTERPRETIVE', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1008, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3277, 10023573, 10058166, 10004238, N'D_INV_TRAVEL', N'TRV_HIGH_RISK_TRAVEL_LOC', N'No', N'1', N'PG_COVID-19_v1.1', N'NBS556', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Did the patient travel to any high-risk locations', N'T', N'CODED', 108270, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1013, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [question_group_seq_nbr], [code_set_group_id], [block_nm], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3279, 10023274, 10057747, 10005132, N'D_INVESTIGATION_REPEAT', N'IPO_CURRENT_OCCUPATION', N'Judicial law clerks [2105]', N'1', N'PG_COVID-19_v1.1', N'85659_1', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Current Occupation Standardized', N'F', N'CODED', 6, 109180, N'OCCUPATION_INDUSTRY', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [mask], [data_type], [question_group_seq_nbr], [block_nm], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3278, 10023275, 10057749, 10005133, N'D_INVESTIGATION_REPEAT', N'IPO_CURRENT_OCCUPATION_TXT', N'clerk', N'1', N'PG_COVID-19_v1.1', N'85658_3', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Current Occupation', N'F', N'TXT', N'TEXT', 6, N'OCCUPATION_INDUSTRY', N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1009, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3243, 10023296, 10057778, 10006139, N'D_INV_CLINICAL', N'CLN_HIST_PREV_ILLNESS', N'Yes', N'1', N'PG_COVID-19_v1.1', N'161413004', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Did the patient previously meet the case definition for a probable or confirmed case of SARS-CoV-2?', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3291, 10023409, 10057924, 10009148, N'D_INV_EPIDEMIOLOGY', N'EPI_ANIMAL_TYPE', N'Other', N'1', N'PG_COVID-19_v1.1', N'FDD_Q_32', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Animal Type', N'T', N'CODED', 108580, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1013, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3244, 10023374, 10057875, 10010298, N'D_INV_PATIENT_OBS', N'IPO_RESIDENT_CONGREGATE', N'No', N'1', N'PG_COVID-19_v1.1', N'95421_4', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Is the patient a resident in a congregate care/living setting?', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3259, 10023406, 10057918, 10010301, N'D_INV_RISK_FACTOR', N'RSK_CHILD_CARE_FACILITY', N'No', N'1', N'PG_COVID-19_v1.1', N'413817003', N'NBS_CASE_ANSWER.ANSWER_TXT', N'Child Care Facility Exposure', N'F', N'CODED', 4150, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1007, N'2026-04-30T03:32:35.420', N'Active');
-- step: 1
INSERT INTO [dbo].[nrt_page_case_answer] ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_rdb_metadata_uid], [nbs_question_uid], [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr], [investigation_form_cd], [question_identifier], [data_location], [question_label], [other_value_ind_cd], [data_type], [code_set_group_id], [last_chg_time], [record_status_cd], [batch_id], [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd]) VALUES (10009289, 3242, 10023367, 10057873, 10010318, N'D_INV_LAB_FINDING', N'LAB_COVID_19_VARIANT', N'SARS-CoV-2 variant B.1.1.7 (501Y.V1)', N'1', N'PG_COVID-19_v1.1', N'NBS786', N'NBS_CASE_ANSWER.ANSWER_TXT', N'COVID-19 Variant Type', N'T', N'CODED', 115910, N'2026-04-30T03:32:35.420', N'ACTIVE', 1777519958514, 1013, N'2026-04-30T03:32:35.420', N'Active');

-- dbo.nrt_investigation
-- step: 1
DECLARE @dbo_nrt_investigation_local_id nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_investigation_public_health_case_uid))) + N'GA01';
INSERT INTO [dbo].[nrt_investigation] ([public_health_case_uid], [local_id], [shared_ind], [outbreak_name], [investigation_status], [inv_case_status], [txt], [jurisdiction_cd], [jurisdiction_nm], [effective_from_time], [effective_to_time], [rpt_form_cmplt_time], [activity_from_time], [rpt_src_cd_desc], [mmwr_week], [mmwr_year], [rpt_source_cd], [diagnosis_time], [hospitalized_admin_time], [outbreak_ind], [outbreak_ind_val], [hospitalized_ind], [hospitalized_ind_cd], [transmission_mode_cd], [transmission_mode], [record_status_cd], [pregnant_ind_cd], [pregnant_ind], [die_frm_this_illness_ind], [deceased_time], [pat_age_at_onset], [pat_age_at_onset_unit_cd], [pat_age_at_onset_unit], [effective_duration_amt], [effective_duration_unit_cd], [illness_duration_unit], [program_area_description], [add_user_id], [add_user_name], [add_time], [last_chg_user_id], [last_chg_user_name], [last_chg_time], [inv_priority_cd], [investigation_status_cd], [investigator_id], [physician_id], [patient_id], [organization_id], [outcome_cd], [mood_cd], [class_cd], [case_class_cd], [cd], [cd_desc_txt], [prog_area_cd], [inv_state_case_id], [rdb_table_name_list], [person_as_reporter_uid], [hospital_uid], [investigation_form_cd], [investigation_count], [case_count], [record_status_time], [raw_record_status_cd], [batch_id]) VALUES (@dbo_nrt_investigation_public_health_case_uid, @dbo_nrt_investigation_local_id, N'T', N'COVID Outbreak 2026', N'Open', N'Confirmed', N'This is a sample investigation comment.', N'130001', N'Fulton County', N'2026-04-05T00:00:00', N'2026-04-20T00:00:00', N'2026-04-10T00:00:00', N'2026-04-24T00:00:00', N'OTH', N'16', N'2026', N'OTH', N'2026-04-12T00:00:00', N'2026-04-17T00:00:00', N'Y', N'Yes', N'Yes', N'Y', N'A', N'Airborne', N'ACTIVE', N'N', N'No', N'Yes', N'2026-04-24T00:00:00', N'36', N'Y', N'Years', N'15', N'D', N'Days', N'GCD', @superuser_id, N'Kent, Ariella', N'2026-04-24T23:15:09.197', @superuser_id, N'Kent, Ariella', N'2030-01-01T00:00:00', N'1', N'O', 10009282, 10009284, 10009283, 10009287, N'Y', N'EVN', N'CASE', N'C', N'11065', N'2019 Novel Coronavirus', N'GCD', N'XYZ1234', N'D_INV_CLINICAL,D_INV_TRAVEL,D_INV_SYMPTOM,D_INV_EPIDEMIOLOGY,D_INV_ADMINISTRATIVE,D_INV_LAB_FINDING,D_INV_PATIENT_OBS,D_INV_MEDICAL_HISTORY,D_INVESTIGATION_REPEAT,D_INV_RISK_FACTOR,INVESTIGATION,D_PROVIDER,D_INV_COMPLICATION', 10009285, 10009286, N'PG_COVID-19_v1.1', 0, 0, N'2026-04-24T23:15:09.197', N'OPEN', 1777519958514);

-- dbo.nrt_provider
-- step: 1
DECLARE @dbo_nrt_provider_local_id nvarchar(40) = N'REP' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_provider_provider_uid))) + N'';
INSERT INTO [dbo].[nrt_provider] ([provider_uid], [local_id], [record_status], [first_name], [last_name], [add_user_id], [add_user_name], [add_time]) VALUES (@dbo_nrt_provider_provider_uid, @dbo_nrt_provider_local_id, N'ACTIVE', N'Jane', N'Reporter', @superuser_id, N'Kent, Ariella', N'2026-04-30T03:32:35.397');
-- step: 1
DECLARE @dbo_nrt_provider_local_id_2 nvarchar(40) = N'PHY' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_provider_provider_uid_2))) + N'';
INSERT INTO [dbo].[nrt_provider] ([provider_uid], [local_id], [record_status], [first_name], [last_name], [add_user_id], [add_user_name], [add_time]) VALUES (@dbo_nrt_provider_provider_uid_2, @dbo_nrt_provider_local_id_2, N'ACTIVE', N'John', N'Physician', @superuser_id, N'Kent, Ariella', N'2026-04-30T03:32:35.397');
-- step: 1
DECLARE @dbo_nrt_provider_local_id_3 nvarchar(40) = N'INV' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_provider_provider_uid_3))) + N'';
INSERT INTO [dbo].[nrt_provider] ([provider_uid], [local_id], [record_status], [first_name], [last_name], [add_user_id], [add_user_name], [add_time]) VALUES (@dbo_nrt_provider_provider_uid_3, @dbo_nrt_provider_local_id_3, N'ACTIVE', N'Super', N'User', @superuser_id, N'Kent, Ariella', N'2026-04-30T03:32:35.397');

-- dbo.nrt_organization_key
-- step: 1
DECLARE @dbo_nrt_organization_key_d_organization_key bigint;
DECLARE @dbo_nrt_organization_key_d_organization_key_output TABLE ([value] bigint);
INSERT INTO [dbo].[nrt_organization_key] ([organization_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_organization_key] INTO @dbo_nrt_organization_key_d_organization_key_output ([value]) VALUES (@dbo_nrt_organization_organization_uid, N'2026-04-30T03:32:43.2033333', N'2026-04-30T03:32:43.2033333');
SELECT TOP 1 @dbo_nrt_organization_key_d_organization_key = [value] FROM @dbo_nrt_organization_key_d_organization_key_output;
-- step: 1
DECLARE @dbo_nrt_organization_key_d_organization_key_2 bigint;
DECLARE @dbo_nrt_organization_key_d_organization_key_2_output TABLE ([value] bigint);
INSERT INTO [dbo].[nrt_organization_key] ([organization_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_organization_key] INTO @dbo_nrt_organization_key_d_organization_key_2_output ([value]) VALUES (@dbo_nrt_organization_organization_uid_2, N'2026-04-30T03:32:43.2033333', N'2026-04-30T03:32:43.2033333');
SELECT TOP 1 @dbo_nrt_organization_key_d_organization_key_2 = [value] FROM @dbo_nrt_organization_key_d_organization_key_2_output;

-- dbo.D_ORGANIZATION
-- step: 1
INSERT INTO [dbo].[D_ORGANIZATION] ([ORGANIZATION_KEY], [ORGANIZATION_UID], [ORGANIZATION_LOCAL_ID], [ORGANIZATION_RECORD_STATUS], [ORGANIZATION_NAME], [ORGANIZATION_ADD_TIME], [ORGANIZATION_ADDED_BY]) VALUES (@dbo_nrt_organization_key_d_organization_key, @dbo_nrt_organization_organization_uid, @dbo_nrt_organization_local_id, N'ACTIVE', N'General Hospital', N'2026-04-30T03:32:35.400', N'Kent, Ariella');
-- step: 1
INSERT INTO [dbo].[D_ORGANIZATION] ([ORGANIZATION_KEY], [ORGANIZATION_UID], [ORGANIZATION_LOCAL_ID], [ORGANIZATION_RECORD_STATUS], [ORGANIZATION_NAME], [ORGANIZATION_ADD_TIME], [ORGANIZATION_ADDED_BY]) VALUES (@dbo_nrt_organization_key_d_organization_key_2, @dbo_nrt_organization_organization_uid_2, @dbo_nrt_organization_local_id_2, N'ACTIVE', N'Reporting Agency', N'2026-04-30T03:32:35.400', N'Kent, Ariella');

-- dbo.nrt_provider_key
-- step: 1
DECLARE @dbo_nrt_provider_key_d_provider_key bigint;
DECLARE @dbo_nrt_provider_key_d_provider_key_output TABLE ([value] bigint);
INSERT INTO [dbo].[nrt_provider_key] ([provider_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_provider_key] INTO @dbo_nrt_provider_key_d_provider_key_output ([value]) VALUES (@dbo_nrt_provider_provider_uid_3, N'2026-04-30T03:32:43.4966667', N'2026-04-30T03:32:43.4966667');
SELECT TOP 1 @dbo_nrt_provider_key_d_provider_key = [value] FROM @dbo_nrt_provider_key_d_provider_key_output;
-- step: 1
DECLARE @dbo_nrt_provider_key_d_provider_key_2 bigint;
DECLARE @dbo_nrt_provider_key_d_provider_key_2_output TABLE ([value] bigint);
INSERT INTO [dbo].[nrt_provider_key] ([provider_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_provider_key] INTO @dbo_nrt_provider_key_d_provider_key_2_output ([value]) VALUES (@dbo_nrt_provider_provider_uid_2, N'2026-04-30T03:32:43.4966667', N'2026-04-30T03:32:43.4966667');
SELECT TOP 1 @dbo_nrt_provider_key_d_provider_key_2 = [value] FROM @dbo_nrt_provider_key_d_provider_key_2_output;
-- step: 1
DECLARE @dbo_nrt_provider_key_d_provider_key_3 bigint;
DECLARE @dbo_nrt_provider_key_d_provider_key_3_output TABLE ([value] bigint);
INSERT INTO [dbo].[nrt_provider_key] ([provider_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_provider_key] INTO @dbo_nrt_provider_key_d_provider_key_3_output ([value]) VALUES (@dbo_nrt_provider_provider_uid, N'2026-04-30T03:32:43.4966667', N'2026-04-30T03:32:43.4966667');
SELECT TOP 1 @dbo_nrt_provider_key_d_provider_key_3 = [value] FROM @dbo_nrt_provider_key_d_provider_key_3_output;

-- dbo.D_PROVIDER
-- step: 1
INSERT INTO [dbo].[D_PROVIDER] ([PROVIDER_UID], [PROVIDER_KEY], [PROVIDER_LOCAL_ID], [PROVIDER_RECORD_STATUS], [PROVIDER_FIRST_NAME], [PROVIDER_LAST_NAME], [PROVIDER_ADD_TIME], [PROVIDER_ADDED_BY]) VALUES (@dbo_nrt_provider_provider_uid_3, @dbo_nrt_provider_key_d_provider_key, @dbo_nrt_provider_local_id_3, N'ACTIVE', N'Super', N'User', N'2026-04-30T03:32:35.397', N'Kent, Ariella');
-- step: 1
INSERT INTO [dbo].[D_PROVIDER] ([PROVIDER_UID], [PROVIDER_KEY], [PROVIDER_LOCAL_ID], [PROVIDER_RECORD_STATUS], [PROVIDER_FIRST_NAME], [PROVIDER_LAST_NAME], [PROVIDER_ADD_TIME], [PROVIDER_ADDED_BY]) VALUES (@dbo_nrt_provider_provider_uid_2, @dbo_nrt_provider_key_d_provider_key_2, @dbo_nrt_provider_local_id_2, N'ACTIVE', N'John', N'Physician', N'2026-04-30T03:32:35.397', N'Kent, Ariella');
-- step: 1
INSERT INTO [dbo].[D_PROVIDER] ([PROVIDER_UID], [PROVIDER_KEY], [PROVIDER_LOCAL_ID], [PROVIDER_RECORD_STATUS], [PROVIDER_FIRST_NAME], [PROVIDER_LAST_NAME], [PROVIDER_ADD_TIME], [PROVIDER_ADDED_BY]) VALUES (@dbo_nrt_provider_provider_uid, @dbo_nrt_provider_key_d_provider_key_3, @dbo_nrt_provider_local_id, N'ACTIVE', N'Jane', N'Reporter', N'2026-04-30T03:32:35.397', N'Kent, Ariella');

-- dbo.nrt_patient_key
-- step: 1
DECLARE @dbo_nrt_patient_key_d_patient_key bigint;
DECLARE @dbo_nrt_patient_key_d_patient_key_output TABLE ([value] bigint);
INSERT INTO [dbo].[nrt_patient_key] ([patient_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_patient_key] INTO @dbo_nrt_patient_key_d_patient_key_output ([value]) VALUES (@dbo_nrt_patient_patient_uid, N'2026-04-30T03:32:43.5900000', N'2026-04-30T03:32:43.5900000');
SELECT TOP 1 @dbo_nrt_patient_key_d_patient_key = [value] FROM @dbo_nrt_patient_key_d_patient_key_output;

-- dbo.D_PATIENT
-- step: 1
INSERT INTO [dbo].[D_PATIENT] ([PATIENT_KEY], [PATIENT_MPR_UID], [PATIENT_RECORD_STATUS], [PATIENT_LOCAL_ID], [PATIENT_FIRST_NAME], [PATIENT_LAST_NAME], [PATIENT_STREET_ADDRESS_1], [PATIENT_CITY], [PATIENT_STATE], [PATIENT_STATE_CODE], [PATIENT_ZIP], [PATIENT_COUNTY], [PATIENT_COUNTY_CODE], [PATIENT_COUNTRY], [PATIENT_PHONE_HOME], [PATIENT_PHONE_WORK], [PATIENT_PHONE_CELL], [PATIENT_EMAIL], [PATIENT_DOB], [PATIENT_AGE_REPORTED], [PATIENT_AGE_REPORTED_UNIT], [PATIENT_CURRENT_SEX], [PATIENT_DECEASED_INDICATOR], [PATIENT_LAST_CHANGE_TIME], [PATIENT_UID], [PATIENT_ADD_TIME], [PATIENT_ADDED_BY], [PATIENT_LAST_UPDATED_BY]) VALUES (@dbo_nrt_patient_key_d_patient_key, @dbo_nrt_patient_patient_mpr_uid, N'ACTIVE', @dbo_nrt_patient_local_id, N'Surma', N'Singh', N'123 Main St.', N'Atlanta', N'Georgia', N'13', N'30024', N'Gwinnett County', N'13135', N'United States', N'456-232-3222', N'232-322-2222', N'232-322-2222', N'fdsfs@dsds.com', N'1990-01-01T00:00:00', 36, N'Years', N'Male', N'Yes', N'2030-01-01T00:00:00', @dbo_nrt_patient_patient_uid, N'2026-04-24T23:15:09.073', N'Kent, Ariella', N'Kent, Ariella');

-- dbo.nrt_investigation_key
-- step: 1
DECLARE @dbo_nrt_investigation_key_d_investigation_key bigint;
DECLARE @dbo_nrt_investigation_key_d_investigation_key_output TABLE ([value] bigint);
INSERT INTO [dbo].[nrt_investigation_key] ([case_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_investigation_key] INTO @dbo_nrt_investigation_key_d_investigation_key_output ([value]) VALUES (@dbo_nrt_investigation_public_health_case_uid, N'2026-04-30T03:32:43.7666667', N'2026-04-30T03:32:43.7666667');
SELECT TOP 1 @dbo_nrt_investigation_key_d_investigation_key = [value] FROM @dbo_nrt_investigation_key_d_investigation_key_output;

-- dbo.INVESTIGATION
-- step: 1
INSERT INTO [dbo].[INVESTIGATION] ([INVESTIGATION_KEY], [CASE_UID], [INV_LOCAL_ID], [INV_SHARE_IND], [OUTBREAK_NAME], [INVESTIGATION_STATUS], [INV_CASE_STATUS], [INV_COMMENTS], [JURISDICTION_CD], [JURISDICTION_NM], [ILLNESS_ONSET_DT], [ILLNESS_END_DT], [INV_RPT_DT], [INV_START_DT], [RPT_SRC_CD_DESC], [CASE_RPT_MMWR_WK], [CASE_RPT_MMWR_YR], [RPT_SRC_CD], [DIAGNOSIS_DT], [HSPTL_ADMISSION_DT], [OUTBREAK_IND], [HSPTLIZD_IND], [INV_STATE_CASE_ID], [TRANSMISSION_MODE], [RECORD_STATUS_CD], [PATIENT_PREGNANT_IND], [DIE_FRM_THIS_ILLNESS_IND], [INVESTIGATION_DEATH_DATE], [PATIENT_AGE_AT_ONSET], [PATIENT_AGE_AT_ONSET_UNIT], [ILLNESS_DURATION], [ILLNESS_DURATION_UNIT], [PROGRAM_AREA_DESCRIPTION], [ADD_TIME], [LAST_CHG_TIME], [INVESTIGATION_ADDED_BY], [INVESTIGATION_LAST_UPDATED_BY], [INV_PRIORITY_CD]) VALUES (@dbo_nrt_investigation_key_d_investigation_key, @dbo_nrt_investigation_public_health_case_uid, @dbo_nrt_investigation_local_id, N'T', N'COVID Outbreak 2026', N'Open', N'Confirmed', N'This is a sample investigation comment.', N'130001', N'Fulton County', N'2026-04-05T00:00:00', N'2026-04-20T00:00:00', N'2026-04-10T00:00:00', N'2026-04-24T00:00:00', N'OTH', 16, 2026, N'OTH', N'2026-04-12T00:00:00', N'2026-04-17T00:00:00', N'Yes', N'Yes', N'XYZ1234', N'Airborne', N'ACTIVE', N'No', N'Yes', N'2026-04-24T00:00:00', 36, N'Years', 15, N'Days', N'GCD', N'2026-04-24T23:15:09.197', N'2030-01-01T00:00:00', N'Kent, Ariella', N'Kent, Ariella', N'1');

-- dbo.CONFIRMATION_METHOD_GROUP
-- step: 1
INSERT INTO [dbo].[CONFIRMATION_METHOD_GROUP] ([INVESTIGATION_KEY], [CONFIRMATION_METHOD_KEY]) VALUES (@dbo_nrt_investigation_key_d_investigation_key, 1);

-- dbo.L_INV_CLINICAL
-- step: 1
INSERT INTO [dbo].[L_INV_CLINICAL] ([PAGE_CASE_UID], [D_INV_CLINICAL_KEY]) VALUES (10009289.0, 1.0);

-- dbo.L_INV_TRAVEL
-- step: 1
INSERT INTO [dbo].[L_INV_TRAVEL] ([PAGE_CASE_UID], [D_INV_TRAVEL_KEY]) VALUES (10009289.0, 1.0);

-- dbo.L_INV_SYMPTOM
-- step: 1
INSERT INTO [dbo].[L_INV_SYMPTOM] ([PAGE_CASE_UID], [D_INV_SYMPTOM_KEY]) VALUES (10009289.0, 1.0);

-- dbo.L_INV_EPIDEMIOLOGY
-- step: 1
INSERT INTO [dbo].[L_INV_EPIDEMIOLOGY] ([PAGE_CASE_UID], [D_INV_EPIDEMIOLOGY_KEY]) VALUES (10009289.0, 1.0);

-- dbo.L_INV_LAB_FINDING
-- step: 1
INSERT INTO [dbo].[L_INV_LAB_FINDING] ([PAGE_CASE_UID], [D_INV_LAB_FINDING_KEY]) VALUES (10009289.0, 1.0);

-- dbo.L_INV_ADMINISTRATIVE
-- step: 1
INSERT INTO [dbo].[L_INV_ADMINISTRATIVE] ([PAGE_CASE_UID], [D_INV_ADMINISTRATIVE_KEY]) VALUES (10009289.0, 1.0);

-- dbo.L_INV_PATIENT_OBS
-- step: 1
INSERT INTO [dbo].[L_INV_PATIENT_OBS] ([PAGE_CASE_UID], [D_INV_PATIENT_OBS_KEY]) VALUES (10009289.0, 1.0);

-- dbo.L_INV_MEDICAL_HISTORY
-- step: 1
INSERT INTO [dbo].[L_INV_MEDICAL_HISTORY] ([PAGE_CASE_UID], [D_INV_MEDICAL_HISTORY_KEY]) VALUES (10009289.0, 1.0);

-- dbo.LOOKUP_TABLE_N_REPT
-- step: 1
INSERT INTO [dbo].[LOOKUP_TABLE_N_REPT] ([PAGE_CASE_UID], [D_REPT_KEY]) VALUES (10009289, 1);

-- dbo.L_INVESTIGATION_REPEAT
-- step: 1
INSERT INTO [dbo].[L_INVESTIGATION_REPEAT] ([D_INVESTIGATION_REPEAT_KEY], [PAGE_CASE_UID]) VALUES (1.0, 10009289);

-- dbo.L_INV_RISK_FACTOR
-- step: 1
INSERT INTO [dbo].[L_INV_RISK_FACTOR] ([PAGE_CASE_UID], [D_INV_RISK_FACTOR_KEY]) VALUES (10009289.0, 1.0);

-- dbo.L_INV_COMPLICATION
-- step: 1
INSERT INTO [dbo].[L_INV_COMPLICATION] ([PAGE_CASE_UID], [D_INV_COMPLICATION_KEY]) VALUES (10009289.0, 1.0);

-- dbo.F_PAGE_CASE
-- step: 1
INSERT INTO [dbo].[F_PAGE_CASE] ([D_INV_ADMINISTRATIVE_KEY], [D_INV_CLINICAL_KEY], [D_INV_COMPLICATION_KEY], [D_INV_CONTACT_KEY], [D_INV_DEATH_KEY], [D_INV_EPIDEMIOLOGY_KEY], [D_INV_HIV_KEY], [D_INV_PATIENT_OBS_KEY], [D_INV_ISOLATE_TRACKING_KEY], [D_INV_LAB_FINDING_KEY], [D_INV_MEDICAL_HISTORY_KEY], [D_INV_MOTHER_KEY], [D_INV_OTHER_KEY], [D_INV_PREGNANCY_BIRTH_KEY], [D_INV_RESIDENCY_KEY], [D_INV_RISK_FACTOR_KEY], [D_INV_SOCIAL_HISTORY_KEY], [D_INV_SYMPTOM_KEY], [D_INV_TREATMENT_KEY], [D_INV_TRAVEL_KEY], [D_INV_UNDER_CONDITION_KEY], [D_INV_VACCINATION_KEY], [D_INVESTIGATION_REPEAT_KEY], [D_INV_PLACE_REPEAT_KEY], [CONDITION_KEY], [INVESTIGATION_KEY], [PHYSICIAN_KEY], [INVESTIGATOR_KEY], [HOSPITAL_KEY], [PATIENT_KEY], [PERSON_AS_REPORTER_KEY], [ORG_AS_REPORTER_KEY], [GEOCODING_LOCATION_KEY]) VALUES (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 94, @dbo_nrt_investigation_key_d_investigation_key, 13, 12, 7, @dbo_nrt_patient_key_d_patient_key, 14, 8, 1.0);

-- dbo.CASE_COUNT
-- step: 1
INSERT INTO [dbo].[CASE_COUNT] ([CASE_COUNT], [INVESTIGATOR_KEY], [REPORTER_KEY], [PHYSICIAN_KEY], [RPT_SRC_ORG_KEY], [INV_ASSIGNED_DT_KEY], [PATIENT_KEY], [INVESTIGATION_KEY], [INVESTIGATION_COUNT], [CONDITION_KEY], [ADT_HSPTL_KEY], [INV_START_DT_KEY], [DIAGNOSIS_DT_KEY], [INV_RPT_DT_KEY], [GEOCODING_LOCATION_KEY]) VALUES (0, @dbo_nrt_provider_key_d_provider_key, @dbo_nrt_provider_key_d_provider_key_3, @dbo_nrt_provider_key_d_provider_key_2, @dbo_nrt_organization_key_d_organization_key_2, 1, @dbo_nrt_patient_key_d_patient_key, @dbo_nrt_investigation_key_d_investigation_key, 0, 94, 7, 1, 1, 1, 1);

-- dbo.EVENT_METRIC_INC
-- step: 1
INSERT INTO [dbo].[EVENT_METRIC_INC] ([EVENT_TYPE], [EVENT_UID], [LOCAL_ID], [LOCAL_PATIENT_ID], [CONDITION_CD], [CONDITION_DESC_TXT], [PROG_AREA_CD], [PROG_AREA_DESC_TXT], [JURISDICTION_CD], [JURISDICTION_DESC_TXT], [RECORD_STATUS_CD], [RECORD_STATUS_DESC_TXT], [RECORD_STATUS_TIME], [ADD_TIME], [ADD_USER_ID], [LAST_CHG_TIME], [LAST_CHG_USER_ID], [CASE_CLASS_CD], [CASE_CLASS_DESC_TXT], [INVESTIGATION_STATUS_CD], [INVESTIGATION_STATUS_DESC_TXT], [ADD_USER_NAME], [LAST_CHG_USER_NAME]) VALUES (N'PHCInvForm', 10009289, @dbo_nrt_investigation_local_id, N'PSN10063000GA01', N'11065', N'2019 Novel Coronavirus', N'GCD', N'GCD', N'130001', N'Fulton County', N'OPEN', N'Open', N'2026-04-24T23:15:09.197', N'2026-04-24T23:15:09.197', @superuser_id, N'2030-01-01T00:00:00', @superuser_id, N'C', N'Confirmed', N'O', N'Open', N'Kent, Ariella', N'Kent, Ariella');

-- dbo.EVENT_METRIC
-- step: 1
INSERT INTO [dbo].[EVENT_METRIC] ([EVENT_TYPE], [EVENT_UID], [LOCAL_ID], [LOCAL_PATIENT_ID], [CONDITION_CD], [CONDITION_DESC_TXT], [PROG_AREA_CD], [PROG_AREA_DESC_TXT], [JURISDICTION_CD], [JURISDICTION_DESC_TXT], [RECORD_STATUS_CD], [RECORD_STATUS_DESC_TXT], [RECORD_STATUS_TIME], [ADD_TIME], [ADD_USER_ID], [LAST_CHG_TIME], [LAST_CHG_USER_ID], [CASE_CLASS_CD], [CASE_CLASS_DESC_TXT], [INVESTIGATION_STATUS_CD], [INVESTIGATION_STATUS_DESC_TXT], [ADD_USER_NAME], [LAST_CHG_USER_NAME]) VALUES (N'PHCInvForm', 10009289, @dbo_nrt_investigation_local_id, N'PSN10063000GA01', N'11065', N'2019 Novel Coronavirus', N'GCD', N'GCD', N'130001', N'Fulton County', N'OPEN', N'Open', N'2026-04-24T23:15:09.197', N'2026-04-24T23:15:09.197', @superuser_id, N'2030-01-01T00:00:00', @superuser_id, N'C', N'Confirmed', N'O', N'Open', N'Kent, Ariella', N'Kent, Ariella');

-- dbo.COVID_CASE_DATAMART
-- step: 1
INSERT INTO [dbo].[COVID_CASE_DATAMART] ([COVID_CASE_DATAMART_KEY], [public_health_case_uid], [INV_LOCAL_ID], [PATIENT_LOCAL_ID], [ADD_TIME], [LAST_CHG_TIME], [CONDITION_CD], [JURISDICTION_CD], [JURISDICTION_NM], [PROGRAM_AREA_CD], [INV_START_DT], [INVESTIGATION_STATUS_CD], [INV_STATE_CASE_ID], [INV_RPT_DT], [RPT_SOURCE_CD], [HSPTLIZD_IND], [HSPTL_ADMISSION_DT], [DIAGNOSIS_DT], [ILLNESS_ONSET_DT], [ILLNESS_END_DT], [ILLNESS_DURATION], [ILLNESS_DURATION_UNIT], [PATIENT_ONSET_AGE], [PATIENT_ONSET_AGE_UNIT], [PATIENT_PREGNANT_IND], [DIE_FROM_ILLNESS_IND], [INV_DEATH_DT], [OUTBREAK_IND], [OUTBREAK_NAME], [TRANSMISSION_MODE_CD], [INV_CASE_STATUS], [CASE_RPT_MMWR_WK], [CASE_RPT_MMWR_YR], [INV_COMMENTS], [CTT_INV_PRIORITY_CD], [PATIENT_FIRST_NAME], [PATIENT_LAST_NAME], [PATIENT_DOB], [PATIENT_AGE_REPORTED], [PATIENT_AGE_RPTD_UNIT], [PATIENT_CURRENT_SEX], [PATIENT_DECEASED_IND], [PATIENT_STREET_ADDR_1], [PATIENT_CITY], [PATIENT_STATE], [PATIENT_ZIP], [PATIENT_COUNTY], [PATIENT_COUNTRY], [PATIENT_TEL_HOME], [PATIENT_PHONE_WORK], [PATIENT_TEL_CELL], [PATIENT_EMAIL], [HOSPITAL_NAME], [PHC_INV_LAST_NAME], [PHC_INV_FIRST_NAME], [PHYS_LAST_NAME], [PHYS_FIRST_NAME], [RPT_PRV_LAST_NAME], [RPT_PRV_FIRST_NAME], [RPT_ORG_NAME]) VALUES (10009289, @dbo_nrt_investigation_public_health_case_uid, @dbo_nrt_investigation_local_id, @dbo_nrt_patient_local_id, N'2026-04-24T23:15:09.197', N'2030-01-01T00:00:00', N'11065', N'130001', N'Fulton County', N'GCD', N'2026-04-24T00:00:00', N'O', N'XYZ1234', N'2026-04-10T00:00:00', N'OTH', N'Y', N'2026-04-17T00:00:00', N'2026-04-12T00:00:00', N'2026-04-05T00:00:00', N'2026-04-20T00:00:00', N'15', N'D', N'36', N'Y', N'N', N'Y', N'2026-04-24T00:00:00', N'Y', N'COVID Outbreak 2026', N'A', N'C', N'16', N'2026', N'This is a sample investigation comment.', N'1', N'Surma', N'Singh', N'1990-01-01T00:00:00', N'36', N'Years', N'M', N'Yes', N'123 Main St.', N'Atlanta', N'Georgia', N'30024', N'Gwinnett County', N'United States', N'456-232-3222', N'232-322-2222', N'232-322-2222', N'fdsfs@dsds.com', N'General Hospital', N'User', N'Super', N'Physician', N'John', N'Reporter', N'Jane', N'Reporting Agency');
