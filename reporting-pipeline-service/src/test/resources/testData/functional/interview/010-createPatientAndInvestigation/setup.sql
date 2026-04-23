USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @patient_uid bigint = 10014313;
DECLARE @patient_uid_2 bigint = 10014315;
DECLARE @investigation_uid bigint = 10014317;
DECLARE @postal_locator_uid bigint = 10014314;
DECLARE @postal_locator_uid_2 bigint = 10014316;

-- Derived local_ids
DECLARE @patient_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @patient_uid))) + N'GA01';
DECLARE @investigation_local_id nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @investigation_uid))) + N'GA01';

-- =====================================================================================
-- STEP 1: CREATE PATIENT (MPR and version)
-- =====================================================================================

-- dbo.Entity (MPR)
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd])
VALUES (@patient_uid, N'PSN');

-- dbo.Person (MPR)
INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [cd], [last_chg_time], [last_chg_user_id],
    [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time],
    [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_general],
    [as_of_date_sex], [electronic_ind], [person_parent_uid], [edx_ind]
)
VALUES (
    @patient_uid, N'2026-04-20T04:19:32.230', @superuser_id, N'PAT', N'2026-04-20T04:19:32.230',
    @superuser_id, @patient_local_id, N'ACTIVE', N'2026-04-20T04:19:32.230', N'A',
    N'2026-04-20T04:19:32.230', N'Jeff', N'Doe', 1, N'2026-04-20T00:00:00', N'2026-04-20T00:00:00',
    N'2026-04-20T00:00:00', N'N', @patient_uid, N'Y'
);

-- dbo.Person_name (MPR)
INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [add_reason_cd], [add_time], [first_nm], [first_nm_sndx],
    [last_nm], [last_nm_sndx], [nm_use_cd], [record_status_cd], [record_status_time],
    [status_cd], [status_time], [as_of_date]
)
VALUES (
    @patient_uid, 1, N'Add', N'2026-04-20T04:19:32.193', N'Jeff', N'J100', N'Doe', N'D000',
    N'L', N'ACTIVE', N'2026-04-20T04:19:32.193', N'A', N'2026-04-20T04:19:32.193', N'2026-04-20T00:00:00'
);

-- dbo.Postal_locator (MPR)
INSERT INTO [dbo].[Postal_locator] (
    [postal_locator_uid], [add_time], [cntry_cd], [record_status_cd],
    [record_status_time], [state_cd], [street_addr1], [street_addr2]
)
VALUES (
    @postal_locator_uid, N'2026-04-20T04:19:32.193', N'840', N'ACTIVE',
    N'2026-04-20T04:19:32.193', N'13', N'', N''
);

-- dbo.Entity_locator_participation (MPR)
INSERT INTO [dbo].[Entity_locator_participation] (
    [entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id],
    [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd],
    [version_ctrl_nbr], [as_of_date]
)
VALUES (
    @patient_uid, @postal_locator_uid, N'H', N'PST', N'2026-04-20T04:19:32.230', @superuser_id,
    N'ACTIVE', N'2026-04-20T04:19:32.230', N'A', N'2026-04-20T04:19:32.230', N'H', 1, N'2026-04-20T00:00:00'
);

-- dbo.Entity (version for investigation)
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd])
VALUES (@patient_uid_2, N'PSN');

-- dbo.Person (version for investigation)
INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [cd], [last_chg_time], [last_chg_user_id],
    [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time],
    [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_admin], [as_of_date_sex],
    [electronic_ind], [person_parent_uid]
)
VALUES (
    @patient_uid_2, N'2026-04-20T04:21:34.430', @superuser_id, N'PAT', N'2026-04-20T04:21:34.430',
    @superuser_id, @patient_local_id, N'ACTIVE', N'2026-04-20T04:21:34.430', N'A',
    N'2026-04-20T04:21:34.430', N'Jeff', N'Doe', 1, N'2026-04-20T00:00:00', N'2026-04-20T00:00:00',
    N'N', @patient_uid
);

-- dbo.Person_name (version)
INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [add_time], [add_user_id], [first_nm], [first_nm_sndx],
    [last_chg_time], [last_chg_user_id], [last_nm], [last_nm_sndx], [nm_use_cd],
    [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]
)
VALUES (
    @patient_uid_2, 1, N'2026-04-20T04:21:34.090', @superuser_id, N'Jeff', N'J100',
    N'2026-04-20T04:21:34.090', @superuser_id, N'Doe', N'D000', N'L', N'ACTIVE',
    N'2026-04-20T04:21:34.090', N'A', N'2026-04-20T04:21:34.090', N'2026-04-20T00:00:00'
);

-- dbo.Postal_locator (version)
INSERT INTO [dbo].[Postal_locator] (
    [postal_locator_uid], [add_time], [add_user_id], [cntry_cd], [record_status_cd],
    [record_status_time], [state_cd]
)
VALUES (
    @postal_locator_uid_2, N'2026-04-20T04:21:34.090', @superuser_id, N'840', N'ACTIVE',
    N'2026-04-20T04:21:34.090', N'13'
);

-- dbo.Entity_locator_participation (version)
INSERT INTO [dbo].[Entity_locator_participation] (
    [entity_uid], [locator_uid], [cd], [class_cd], [last_chg_time], [last_chg_user_id],
    [record_status_cd], [record_status_time], [status_cd], [status_time], [use_cd],
    [version_ctrl_nbr], [as_of_date]
)
VALUES (
    @patient_uid_2, @postal_locator_uid_2, N'H', N'PST', N'2026-04-20T04:21:34.430', @superuser_id,
    N'ACTIVE', N'2026-04-20T04:21:34.430', N'A', N'2026-04-20T04:21:34.430', N'H', 1, N'2026-04-20T00:00:00'
);

-- =====================================================================================
-- STEP 2: CREATE INVESTIGATION
-- =====================================================================================

-- dbo.Act
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd])
VALUES (@investigation_uid, N'CASE', N'EVN');

-- dbo.Public_health_case
INSERT INTO [dbo].[Public_health_case] (
    [public_health_case_uid], [activity_from_time], [add_time], [add_user_id],
    [case_class_cd], [case_type_cd], [cd], [cd_desc_txt], [detection_method_cd],
    [disease_imported_cd], [effective_duration_amt], [effective_duration_unit_cd],
    [group_case_cnt], [investigation_status_cd], [jurisdiction_cd], [last_chg_time],
    [last_chg_user_id], [local_id], [mmwr_week], [mmwr_year], [outbreak_ind],
    [outbreak_name], [outcome_cd], [prog_area_cd], [record_status_cd], [record_status_time],
    [rpt_source_cd], [status_cd], [transmission_mode_cd], [transmission_mode_desc_txt],
    [txt], [program_jurisdiction_oid], [shared_ind], [version_ctrl_nbr],
    [hospitalized_ind_cd], [pregnant_ind_cd], [day_care_ind_cd], [food_handler_ind_cd],
    [imported_country_cd], [imported_state_cd], [imported_city_desc_txt],
    [imported_county_cd], [priority_cd], [contact_inv_txt], [contact_inv_status_cd],
    [referral_basis_cd], [curr_process_state_cd], [coinfection_id]
)
VALUES (
    @investigation_uid, N'2026-04-01T00:00:00', N'2026-04-20T04:21:34.507', @superuser_id,
    N'', N'I', N'10280', N'Gonorrhea', N'', N'', N'', N'', 1, N'O', N'130006',
    N'2026-04-20T04:21:34.507', @superuser_id, @investigation_local_id, N'16', N'2026',
    N'', N'', N'', N'STD', N'OPEN', N'2026-04-20T04:21:34.507', N'', N'A', N'', N'', N'',
    1300600015, N'T', 1, N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'P1', N'OC',
    N'COIN1005XX01'
);

-- dbo.case_management
DECLARE @case_management_uid bigint;
DECLARE @case_management_uid_output TABLE ([value] bigint);
INSERT INTO [dbo].[case_management] (
    [public_health_case_uid], [epi_link_id], [field_record_number], [fld_foll_up_dispo],
    [fld_foll_up_dispo_date], [fld_foll_up_exam_date], [init_foll_up],
    [init_foll_up_notifiable], [pat_intv_status_cd], [initiating_agncy],
    [foll_up_assigned_date], [init_foll_up_assigned_date], [interview_assigned_date],
    [init_interview_assigned_date]
)
OUTPUT INSERTED.[case_management_uid] INTO @case_management_uid_output ([value])
VALUES (
    @investigation_uid, N'1310000526', N'1310000526', N'D', N'2026-04-15T00:00:00',
    N'2026-04-14T00:00:00', N'FF', N'06', N'I', N'13', N'2026-04-02T00:00:00',
    N'2026-04-02T00:00:00', N'2026-04-17T00:00:00', N'2026-04-17T00:00:00'
);
SELECT TOP 1 @case_management_uid = [value] FROM @case_management_uid_output;

-- dbo.Act_id
INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd])
VALUES (@investigation_uid, 1, N'', N'A', N'2026-04-20T04:21:34.543', N'STATE');

INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd])
VALUES (@investigation_uid, 2, N'', N'A', N'2026-04-20T04:21:34.547', N'CITY');

INSERT INTO [dbo].[Act_id] ([act_uid], [act_id_seq], [root_extension_txt], [status_cd], [status_time], [type_cd])
VALUES (@investigation_uid, 3, N'', N'A', N'2026-04-20T04:21:34.550', N'LEGACY');

-- dbo.message_log
DECLARE @message_log_uid bigint;
DECLARE @message_log_uid_output TABLE ([value] bigint);
INSERT INTO [dbo].[message_log] (
    [message_txt], [condition_cd], [person_uid], [assigned_to_uid], [event_uid],
    [event_type_cd], [message_status_cd], [record_status_cd], [record_status_time],
    [add_time], [add_user_id], [last_chg_time], [last_chg_user_id]
)
OUTPUT INSERTED.[message_log_uid] INTO @message_log_uid_output ([value])
VALUES (
    N'New assignment', N'10280', @patient_uid_2, 10003013, @investigation_uid,
    N'Investigation', N'N', N'ACTIVE', N'2026-04-20T04:21:34.077', N'2026-04-20T04:21:34.077',
    @superuser_id, N'2026-04-20T04:21:34.077', @superuser_id
);
SELECT TOP 1 @message_log_uid = [value] FROM @message_log_uid_output;

-- dbo.Participation (link patient to investigation)
INSERT INTO [dbo].[Participation] (
    [subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id],
    [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time],
    [status_cd], [status_time], [subject_class_cd], [type_desc_txt]
)
VALUES (
    @patient_uid_2, @investigation_uid, N'SubjOfPHC', N'CASE', N'2026-04-20T04:21:34.180',
    @superuser_id, N'2026-04-20T04:21:34.180', @superuser_id, N'ACTIVE',
    N'2026-04-20T04:21:34.180', N'A', N'2026-04-20T04:21:34.180', N'PSN', N'Subject Of Public Health Case'
);

-- Additional participations (investigators, supervisors, etc.)
INSERT INTO [dbo].[Participation] (
    [subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id],
    [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time],
    [status_cd], [status_time], [subject_class_cd]
)
VALUES
    (10003013, @investigation_uid, N'CASupervisorOfPHC', N'CASE', N'2026-04-20T04:21:34.180', @superuser_id, N'2026-04-20T04:21:34.180', @superuser_id, N'ACTIVE', N'2026-04-20T04:21:34.180', N'A', N'2026-04-20T04:21:34.180', N'PSN'),
    (10003013, @investigation_uid, N'DispoFldFupInvestgrOfPHC', N'CASE', N'2026-04-20T04:21:34.180', @superuser_id, N'2026-04-20T04:21:34.180', @superuser_id, N'ACTIVE', N'2026-04-20T04:21:34.180', N'A', N'2026-04-20T04:21:34.180', N'PSN'),
    (10003019, @investigation_uid, N'FldFupFacilityOfPHC', N'CASE', N'2026-04-20T04:21:34.180', @superuser_id, N'2026-04-20T04:21:34.180', @superuser_id, N'ACTIVE', N'2026-04-20T04:21:34.180', N'A', N'2026-04-20T04:21:34.180', N'ORG'),
    (10003013, @investigation_uid, N'FldFupInvestgrOfPHC', N'CASE', N'2026-04-20T04:21:34.180', @superuser_id, N'2026-04-20T04:21:34.180', @superuser_id, N'ACTIVE', N'2026-04-20T04:21:34.180', N'A', N'2026-04-20T04:21:34.180', N'PSN'),
    (10003013, @investigation_uid, N'FldFupProvOfPHC', N'CASE', N'2026-04-20T04:21:34.180', @superuser_id, N'2026-04-20T04:21:34.180', @superuser_id, N'ACTIVE', N'2026-04-20T04:21:34.180', N'A', N'2026-04-20T04:21:34.180', N'PSN'),
    (10003013, @investigation_uid, N'FldFupSupervisorOfPHC', N'CASE', N'2026-04-20T04:21:34.180', @superuser_id, N'2026-04-20T04:21:34.180', @superuser_id, N'ACTIVE', N'2026-04-20T04:21:34.180', N'A', N'2026-04-20T04:21:34.180', N'PSN'),
    (10003013, @investigation_uid, N'InitFldFupInvestgrOfPHC', N'CASE', N'2026-04-20T04:21:34.180', @superuser_id, N'2026-04-20T04:21:34.180', @superuser_id, N'ACTIVE', N'2026-04-20T04:21:34.180', N'A', N'2026-04-20T04:21:34.180', N'PSN'),
    (10003013, @investigation_uid, N'InitFupInvestgrOfPHC', N'CASE', N'2026-04-20T04:21:34.180', @superuser_id, N'2026-04-20T04:21:34.180', @superuser_id, N'ACTIVE', N'2026-04-20T04:21:34.180', N'A', N'2026-04-20T04:21:34.180', N'PSN'),
    (10003013, @investigation_uid, N'InitInterviewerOfPHC', N'CASE', N'2026-04-20T04:21:34.180', @superuser_id, N'2026-04-20T04:21:34.180', @superuser_id, N'ACTIVE', N'2026-04-20T04:21:34.180', N'A', N'2026-04-20T04:21:34.180', N'PSN'),
    (10003013, @investigation_uid, N'InterviewerOfPHC', N'CASE', N'2026-04-20T04:21:34.180', @superuser_id, N'2026-04-20T04:21:34.180', @superuser_id, N'ACTIVE', N'2026-04-20T04:21:34.180', N'A', N'2026-04-20T04:21:34.180', N'PSN');

INSERT INTO [dbo].[Participation] (
    [subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id],
    [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time],
    [status_cd], [status_time], [subject_class_cd], [type_desc_txt]
)
VALUES (
    10003013, @investigation_uid, N'InvestgrOfPHC', N'CASE', N'2026-04-20T04:21:34.180',
    @superuser_id, N'2026-04-20T04:21:34.180', @superuser_id, N'ACTIVE',
    N'2026-04-20T04:21:34.180', N'A', N'2026-04-20T04:21:34.180', N'PSN', N'PHC Investigator'
);

-- dbo.NBS_case_answer (sample answers from the investigation form)
DECLARE @nbs_case_answer_uid bigint;
DECLARE @nbs_case_answer_uid_output TABLE ([value] bigint);

INSERT INTO [dbo].[NBS_case_answer] (
    [act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid],
    [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id],
    [record_status_cd], [record_status_time], [seq_nbr]
)
OUTPUT INSERTED.[nbs_case_answer_uid] INTO @nbs_case_answer_uid_output ([value])
VALUES
    (@investigation_uid, N'2026-04-20T04:21:34.507', @superuser_id, N'N', 10001013, 3, N'2026-04-20T04:21:34.507', @superuser_id, N'OPEN', N'2026-04-20T04:21:34.507', 0);

INSERT INTO [dbo].[NBS_case_answer] (
    [act_uid], [add_time], [add_user_id], [answer_txt], [nbs_question_uid],
    [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id],
    [record_status_cd], [record_status_time], [seq_nbr]
)
OUTPUT INSERTED.[nbs_case_answer_uid] INTO @nbs_case_answer_uid_output ([value])
VALUES
    (@investigation_uid, N'2026-04-20T04:21:34.507', @superuser_id, N'P1', 10001177, 3, N'2026-04-20T04:21:34.507', @superuser_id, N'OPEN', N'2026-04-20T04:21:34.507', 0);

-- dbo.NBS_act_entity
INSERT INTO [dbo].[NBS_act_entity] (
    [act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr],
    [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]
)
VALUES
    (@investigation_uid, N'2026-04-20T04:21:34.507', @superuser_id, @patient_uid_2, 1, N'2026-04-20T04:21:34.507', @superuser_id, N'OPEN', N'2026-04-20T04:21:34.507', N'SubjOfPHC'),
    (@investigation_uid, N'2026-04-20T04:21:34.507', @superuser_id, 10003013, 1, N'2026-04-20T04:21:34.507', @superuser_id, N'OPEN', N'2026-04-20T04:21:34.507', N'InvestgrOfPHC');

-- Update MPR person record (timestamp change from investigation creation)
UPDATE [dbo].[Person]
SET [last_chg_time] = N'2026-04-20T04:21:34.363',
    [record_status_time] = N'2026-04-20T04:21:34.363',
    [status_time] = N'2026-04-20T04:21:34.363',
    [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1
WHERE [person_uid] = @patient_uid;

-- Update MPR entity locator participation
UPDATE [dbo].[Entity_locator_participation]
SET [last_chg_time] = N'2026-04-20T04:21:34.363',
    [record_status_time] = N'2026-04-20T04:21:34.363',
    [status_time] = N'2026-04-20T04:21:34.363'
WHERE [entity_uid] = @patient_uid AND [locator_uid] = @postal_locator_uid;
