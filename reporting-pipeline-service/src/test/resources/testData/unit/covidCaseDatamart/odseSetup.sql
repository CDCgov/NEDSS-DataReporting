USE NBS_ODSE;

-----------------------------------------------------------------------
-- CLEANUPS
-----------------------------------------------------------------------
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
-- Cleanup ODSE
DELETE FROM NBS_ODSE.DBO.NBS_case_answer;
DELETE FROM NBS_ODSE.DBO.NBS_act_entity;
DELETE FROM NBS_ODSE.DBO.Participation;
DELETE FROM NBS_ODSE.DBO.Act_id;
DELETE FROM NBS_ODSE.DBO.Public_health_case;
DELETE FROM NBS_ODSE.DBO.PublicHealthCaseFact;
DELETE FROM NBS_ODSE.DBO.Act;
DELETE FROM NBS_ODSE.DBO.Person_race;
DELETE FROM NBS_ODSE.DBO.Person_name;
DELETE FROM NBS_ODSE.DBO.Person;
DELETE FROM NBS_ODSE.DBO.Organization_name;
DELETE FROM NBS_ODSE.DBO.Organization;
DELETE FROM NBS_ODSE.DBO.Entity_locator_participation;
DELETE FROM NBS_ODSE.DBO.Postal_locator;
DELETE FROM NBS_ODSE.DBO.Tele_locator;
DELETE FROM NBS_ODSE.DBO.Entity;
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

-----------------------------------------------------------------------
-- SECTION 1: ODSE SEEDING
-----------------------------------------------------------------------
-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @superuser_id bigint = 10009282;
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
