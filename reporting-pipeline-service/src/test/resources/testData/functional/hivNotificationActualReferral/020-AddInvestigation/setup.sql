USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;
DECLARE @elruser_id bigint = 10000015;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 1000010000;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 1000010001;
DECLARE @dbo_Entity_entity_uid_2 bigint = 1000010002;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 1000010003;
DECLARE @dbo_Act_act_uid bigint = 1000010004;
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid))) + N'GA01';
DECLARE @dbo_Public_health_case_local_id nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid))) + N'GA01';
DECLARE @dbo_case_management_case_management_uid bigint;
DECLARE @dbo_case_management_case_management_uid_output TABLE ([value] bigint);
DECLARE @dbo_message_log_message_log_uid bigint;
DECLARE @dbo_message_log_message_log_uid_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_2 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3_output TABLE ([value] bigint);
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_4 bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_4_output TABLE ([value] bigint);

-- STEP 2: HIV Investigation
-- dbo.Entity
-- step: 2
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@dbo_Entity_entity_uid_2, N'PSN');
-- dbo.Person
-- step: 2
INSERT INTO [dbo].[Person] ([person_uid], [add_time], [add_user_id], [age_reported], [age_reported_unit_cd], [birth_time], [birth_time_calc], [cd], [last_chg_time], [last_chg_user_id], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_sex], [electronic_ind], [person_parent_uid]) VALUES (@dbo_Entity_entity_uid_2, N'2026-06-05T16:12:30.270', @superuser_id, N'47', N'Y', N'1978-08-16T00:00:00', N'1978-08-16T00:00:00', N'PAT', N'2026-06-05T16:12:30.270', @superuser_id, @dbo_Person_local_id, N'ACTIVE', N'2026-06-05T16:12:30.270', N'A', N'2026-06-05T16:12:30.270', N'Nil', N'Prevost', 1, N'2026-06-05T00:00:00', N'2026-06-05T00:00:00', N'N', @dbo_Entity_entity_uid);
-- dbo.Person_name
-- step: 2
INSERT INTO [dbo].[Person_name] ([person_uid], [person_name_seq], [add_time], [add_user_id], [first_nm], [first_nm_sndx], [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, 1, N'2026-06-05T16:12:30.110', @superuser_id, N'Nil', N'N400', N'2026-06-05T16:12:30.110', @superuser_id, N'Prevost', N'P612', N'L', N'ACTIVE', N'2026-06-05T16:12:30.110', N'A', N'2026-06-05T16:12:30.110', N'2026-06-05T00:00:00');
-- dbo.Entity_id
-- step: 2
INSERT INTO [dbo].[Entity_id] ([entity_uid], [entity_id_seq], [add_time], [assigning_authority_cd], [assigning_authority_desc_txt], [last_chg_time], [record_status_cd], [record_status_time], [root_extension_txt], [status_cd], [status_time], [type_cd], [type_desc_txt], [as_of_date], [assigning_authority_id_type]) VALUES (@dbo_Entity_entity_uid_2, 1, N'2026-06-05T16:12:30.153', N'GA', N'GA', N'2026-06-05T16:12:30.153', N'ACTIVE', N'2026-06-05T16:12:30.153', N'f2b09561-f7ca-40bd-9db6-ffca5d8c2e15', N'A', N'2026-06-05T16:12:30.153', N'DL', N'Driver''s license number', N'2026-06-05T00:00:00', N'L');
-- dbo.Postal_locator
-- step: 2
INSERT INTO [dbo].[Postal_locator] ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt], [cntry_cd], [record_status_cd], [record_status_time], [state_cd], [street_addr1], [zip_cd]) VALUES (@dbo_Postal_locator_postal_locator_uid_2, N'2026-06-05T16:12:30.110', @superuser_id, N'Atlanta', N'840', N'ACTIVE', N'2026-06-05T16:12:30.110', N'13', N'91181 Steensland', N'30368');
-- dbo.Entity_locator_participation
-- step: 2
INSERT INTO [dbo].[Entity_locator_participation] ([entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd], [version_ctrl_nbr], [as_of_date]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Postal_locator_postal_locator_uid_2, N'H', N'PST', N'2026-06-05T16:12:30.270', @superuser_id, N'ACTIVE', N'2026-06-05T16:12:30.270', N'A', N'2026-06-05T16:12:30.270', N'H', 1, N'2026-06-05T00:00:00');
-- dbo.Act
-- step: 2
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES (@dbo_Act_act_uid, N'CASE', N'EVN');
-- dbo.Public_health_case
-- step: 2
INSERT INTO [dbo].[Public_health_case] ([public_health_case_uid], [activity_from_time], [add_time], [add_user_id], [case_class_cd], [case_type_cd], [cd], [cd_desc_txt], [detection_method_cd], [disease_imported_cd], [effective_duration_amt], [effective_duration_unit_cd], [group_case_cnt], [investigation_status_cd], [jurisdiction_cd], [last_chg_time], [last_chg_user_id], [local_id], [mmwr_week], [mmwr_year], [outbreak_ind], [outbreak_name], [outcome_cd], [prog_area_cd], [record_status_cd], [record_status_time], [rpt_source_cd], [status_cd], [transmission_mode_cd], [transmission_mode_desc_txt], [txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr], [hospitalized_ind_cd], [pregnant_ind_cd], [day_care_ind_cd], [food_handler_ind_cd], [imported_country_cd], [imported_state_cd], [imported_city_desc_txt], [imported_county_cd], [priority_cd], [contact_inv_txt], [contact_inv_status_cd], [referral_basis_cd], [curr_process_state_cd], [coinfection_id]) VALUES (@dbo_Act_act_uid, N'2026-06-01T00:00:00', N'2026-06-05T16:12:30.327', @superuser_id, N'', N'I', N'900', N'HIV', N'', N'', N'', N'', 1, N'O', N'130005', N'2026-06-05T16:12:30.327', @superuser_id, @dbo_Public_health_case_local_id, N'22', N'2026', N'', N'', N'', N'HIV', N'OPEN', N'2026-06-05T16:12:30.327', N'', N'A', N'', N'', N'', 1300500016, N'T', 1, N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'C1', N'FF', N'COIN1001XX01');
-- dbo.case_management
-- step: 2
INSERT INTO [dbo].[case_management] ([public_health_case_uid], [epi_link_id], [field_record_number], [fld_foll_up_notification_plan], [init_foll_up], [init_foll_up_notifiable], [act_ref_type_cd], [initiating_agncy], [foll_up_assigned_date], [init_foll_up_assigned_date]) OUTPUT INSERTED.[case_management_uid] INTO @dbo_case_management_case_management_uid_output ([value]) VALUES (@dbo_Act_act_uid, N'1310000126', N'1310000126', N'6', N'FF', N'88', N'7', N'13', N'2026-06-05T00:00:00', N'2026-06-05T00:00:00');
SELECT TOP 1 @dbo_case_management_case_management_uid = [value] FROM @dbo_case_management_case_management_uid_output;
-- dbo.Act_id
-- step: 2
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid, 1, N'', N'A', N'2026-06-05T16:12:30.353', N'STATE');
-- step: 2
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid, 2, N'', N'A', N'2026-06-05T16:12:30.357', N'CITY');
-- step: 2
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd]) VALUES (@dbo_Act_act_uid, 3, N'', N'A', N'2026-06-05T16:12:30.360', N'LEGACY');
-- dbo.message_log
-- step: 2
INSERT INTO [dbo].[message_log] ([message_txt], [condition_cd], [person_uid], [assigned_to_uid], [event_uid], [event_type_cd], [message_status_cd], [record_status_cd], [record_status_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id]) OUTPUT INSERTED.[message_log_uid] INTO @dbo_message_log_message_log_uid_output ([value]) VALUES (N'New assignment', N'900', @dbo_Entity_entity_uid_2, 10003004, 10009292, N'Investigation', N'N', N'ACTIVE', N'2026-06-05T16:12:30.103', N'2026-06-05T16:12:30.103', @superuser_id, N'2026-06-05T16:12:30.103', @superuser_id);
SELECT TOP 1 @dbo_message_log_message_log_uid = [value] FROM @dbo_message_log_message_log_uid_output;
-- dbo.Participation
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (@dbo_Entity_entity_uid_2, @dbo_Act_act_uid, N'SubjOfPHC', N'CASE', N'2026-06-05T16:12:30.153', @superuser_id, N'2026-06-05T16:12:30.153', @superuser_id, N'ACTIVE', N'2026-06-05T16:12:30.153', N'A', N'2026-06-05T16:12:30.153', N'PSN', N'Subject Of Public Health Case');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid, N'FldFupInvestgrOfPHC', N'CASE', N'2026-06-05T16:12:30.153', @superuser_id, N'2026-06-05T16:12:30.153', @superuser_id, N'ACTIVE', N'2026-06-05T16:12:30.153', N'A', N'2026-06-05T16:12:30.153', N'PSN');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd]) VALUES (10003004, @dbo_Act_act_uid, N'InitFldFupInvestgrOfPHC', N'CASE', N'2026-06-05T16:12:30.153', @superuser_id, N'2026-06-05T16:12:30.153', @superuser_id, N'ACTIVE', N'2026-06-05T16:12:30.153', N'A', N'2026-06-05T16:12:30.153', N'PSN');
-- step: 2
INSERT INTO [dbo].[Participation] ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_class_cd], [type_desc_txt]) VALUES (10003004, @dbo_Act_act_uid, N'InvestgrOfPHC', N'CASE', N'2026-06-05T16:12:30.153', @superuser_id, N'2026-06-05T16:12:30.153', @superuser_id, N'ACTIVE', N'2026-06-05T16:12:30.153', N'A', N'2026-06-05T16:12:30.153', N'PSN', N'PHC Investigator');
-- dbo.NBS_case_answer
-- step: 2
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-06-05T16:12:30.327', @superuser_id, N'EMC', 10001188, 3, N'2026-06-05T16:12:30.327', @superuser_id, N'OPEN', N'2026-06-05T16:12:30.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_output;
-- step: 2
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_2_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-06-05T16:12:30.327', @superuser_id, N'N', 10001013, 3, N'2026-06-05T16:12:30.327', @superuser_id, N'OPEN', N'2026-06-05T16:12:30.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_2 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_2_output;
-- step: 2
INSERT INTO [dbo].[NBS_case_answer] ([act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [seq_nbr]) OUTPUT INSERTED.[nbs_case_answer_uid] INTO @dbo_NBS_case_answer_nbs_case_answer_uid_3_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-06-05T16:12:30.327', @superuser_id, N'C1', 10001177, 3, N'2026-06-05T16:12:30.327', @superuser_id, N'OPEN', N'2026-06-05T16:12:30.327', 0);
SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_3 = [value] FROM @dbo_NBS_case_answer_nbs_case_answer_uid_3_output;
-- dbo.NBS_act_entity
-- step: 2
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-06-05T16:12:30.327', @superuser_id, @dbo_Entity_entity_uid_2, 1, N'2026-06-05T16:12:30.327', @superuser_id, N'OPEN', N'2026-06-05T16:12:30.327', N'SubjOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_output;
-- step: 2
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_2_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-06-05T16:12:30.327', @superuser_id, 10003004, 1, N'2026-06-05T16:12:30.327', @superuser_id, N'OPEN', N'2026-06-05T16:12:30.327', N'FldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_2 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_2_output;
-- step: 2
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_3_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-06-05T16:12:30.327', @superuser_id, 10003004, 1, N'2026-06-05T16:12:30.327', @superuser_id, N'OPEN', N'2026-06-05T16:12:30.327', N'InitFldFupInvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_3 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_3_output;
-- step: 2
INSERT INTO [dbo].[NBS_act_entity] ([act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]) OUTPUT INSERTED.[nbs_act_entity_uid] INTO @dbo_NBS_act_entity_nbs_act_entity_uid_4_output ([value]) VALUES (@dbo_Act_act_uid, N'2026-06-05T16:12:30.327', @superuser_id, 10003004, 1, N'2026-06-05T16:12:30.327', @superuser_id, N'OPEN', N'2026-06-05T16:12:30.327', N'InvestgrOfPHC');
SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_4 = [value] FROM @dbo_NBS_act_entity_nbs_act_entity_uid_4_output;
-- dbo.Person
-- step: 2
UPDATE [dbo].[Person] SET [last_chg_time] = N'2026-06-05T16:12:30.253', [record_status_time] = N'2026-06-05T16:12:30.253', [status_time] = N'2026-06-05T16:12:30.253', [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1 WHERE [person_uid] = @dbo_Entity_entity_uid;
-- dbo.Entity_locator_participation
-- step: 2
UPDATE [dbo].[Entity_locator_participation] SET [last_chg_time] = N'2026-06-05T16:12:30.253', [record_status_time] = N'2026-06-05T16:12:30.253', [status_time] = N'2026-06-05T16:12:30.253' WHERE [entity_uid] = @dbo_Entity_entity_uid AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;
-- dbo.PublicHealthCaseFact
-- step: 2
INSERT INTO [dbo].[PublicHealthCaseFact] ([public_health_case_uid], [age_reported_unit_cd], [age_reported], [birth_time], [birth_time_calc], [case_class_cd], [case_type_cd], [city_desc_txt], [cntry_cd], [ELP_class_cd], [event_date], [event_type], [group_case_cnt], [investigation_status_cd], [investigatorName], [investigatorPhone], [jurisdiction_cd], [mart_record_creation_time], [mmwr_week], [mmwr_year], [PAR_type_cd], [postal_locator_uid], [person_cd], [person_uid], [PHC_add_time], [PHC_code], [PHC_code_desc], [PHC_code_short_desc], [prog_area_cd], [PST_record_status_time], [PST_record_status_cd], [record_status_cd], [shared_ind], [state], [state_cd], [status_cd], [street_addr1], [ELP_use_cd], [zip_cd], [patientName], [jurisdiction], [investigationstartdate], [program_jurisdiction_oid], [report_date], [person_parent_uid], [person_local_id], [sub_addr_as_of_date], [LOCAL_ID], [age_reported_unit_desc_txt], [cntry_desc_txt], [investigation_status_desc_txt], [prog_area_desc_txt], [LASTUPDATE]) VALUES (@dbo_Act_act_uid, N'Y', 47, N'1978-08-16T00:00:00', N'1978-08-16T00:00:00', N'', N'I', N'Atlanta', N'840', N'PST', N'2026-06-05T16:12:30.327', N'P', 1.0, N'O', N'Xerogeanes, John', N'404-778-3350', N'130005', N'2026-06-05T16:12:33.820', 22, 2026, N'SubjOfPHC', @dbo_Postal_locator_postal_locator_uid_2, N'PAT', @dbo_Entity_entity_uid_2, N'2026-06-05T16:12:30.327', N'900', N'HIV', N'HIV', N'HIV', N'2026-06-05T16:12:30.110', N'ACTIVE', N'OPEN', N'T', N'Georgia', N'13', N'A', N'91181 Steensland', N'H', N'30368', N'Prevost, Nil', N'Dekalb County', N'2026-06-01T00:00:00', 1300500016, N'2026-06-05T16:12:30.327', 10009288, @dbo_Person_local_id, N'2026-06-05T00:00:00', @dbo_Public_health_case_local_id, N'Years', N'UNITED STATES', N'Open', N'HIV', N'2026-06-05T16:12:30.327');
