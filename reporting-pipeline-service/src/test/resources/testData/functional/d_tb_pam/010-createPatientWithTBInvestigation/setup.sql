USE [NBS_ODSE];

DECLARE @superuser_id bigint = 10009282;
-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 1000011000;
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 1000011001;
DECLARE @dbo_Entity_entity_uid_2 bigint = 1000011002;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 bigint = 1000011003;
DECLARE @dbo_Act_act_uid bigint = 1000011004;

-- STEP 1: Create patient with TB investigation
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[entity]
            ([entity_uid],
             [class_cd])
VALUES      (@dbo_Entity_entity_uid,
             N'PSN');

-- dbo.Person
-- step: 1
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN'
  + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Entity_entity_uid)))
  + N'GA01';

INSERT INTO [dbo].[person]
            ([person_uid],
             [add_time],
             [add_user_id],
             [cd],
             [last_chg_time],
             [last_chg_user_id],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [first_nm],
             [last_nm],
             [version_ctrl_nbr],
             [as_of_date_admin],
             [as_of_date_general],
             [as_of_date_sex],
             [electronic_ind],
             [person_parent_uid],
             [edx_ind])
VALUES      (@dbo_Entity_entity_uid,
             N'2026-06-17T19:10:51.163',
             @superuser_id,
             N'PAT',
             N'2026-06-17T19:10:51.163',
             @superuser_id,
             @dbo_Person_local_id,
             N'ACTIVE',
             N'2026-06-17T19:10:51.163',
             N'A',
             N'2026-06-17T19:10:51.163',
             N'Tuber',
             N'Culosis',
             1,
             N'2026-06-17T00:00:00',
             N'2026-06-17T00:00:00',
             N'2026-06-17T00:00:00',
             N'N',
             @dbo_Entity_entity_uid,
             N'Y');

-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[person_name]
            ([person_uid],
             [person_name_seq],
             [add_reason_cd],
             [add_time],
             [first_nm],
             [first_nm_sndx],
             [last_nm],
             [last_nm_sndx],
             [nm_use_cd],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid,
             1,
             N'Add',
             N'2026-06-17T19:10:51.103',
             N'Tuber',
             N'M240',
             N'Culosis',
             N'P420',
             N'L',
             N'ACTIVE',
             N'2026-06-17T19:10:51.103',
             N'A',
             N'2026-06-17T19:10:51.103',
             N'2026-06-17T00:00:00');

-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[postal_locator]
            ([postal_locator_uid],
             [add_time],
             [cntry_cd],
             [record_status_cd],
             [record_status_time],
             [state_cd],
             [street_addr1],
             [street_addr2])
VALUES      (@dbo_Postal_locator_postal_locator_uid,
             N'2026-06-17T19:10:51.103',
             N'840',
             N'ACTIVE',
             N'2026-06-17T19:10:51.103',
             N'13',
             N'',
             N'');

-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[entity_locator_participation]
            ([entity_uid],
             [locator_uid],
             [cd],
             [class_cd],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [use_cd],
             [version_ctrl_nbr],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid,
             @dbo_Postal_locator_postal_locator_uid,
             N'H',
             N'PST',
             N'2026-06-17T19:10:51.163',
             @superuser_id,
             N'ACTIVE',
             N'2026-06-17T19:10:51.163',
             N'A',
             N'2026-06-17T19:10:51.163',
             N'H',
             1,
             N'2026-06-17T00:00:00');

-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[entity]
            ([entity_uid],
             [class_cd])
VALUES      (@dbo_Entity_entity_uid_2,
             N'PSN');

-- dbo.Person
-- step: 1
INSERT INTO [dbo].[person]
            ([person_uid],
             [add_time],
             [add_user_id],
             [cd],
             [last_chg_time],
             [last_chg_user_id],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [first_nm],
             [last_nm],
             [version_ctrl_nbr],
             [as_of_date_admin],
             [as_of_date_sex],
             [electronic_ind],
             [person_parent_uid])
VALUES      (@dbo_Entity_entity_uid_2,
             N'2026-06-17T19:14:40.797',
             @superuser_id,
             N'PAT',
             N'2026-06-17T19:14:40.797',
             @superuser_id,
             @dbo_Person_local_id,
             N'ACTIVE',
             N'2026-06-17T19:14:40.797',
             N'A',
             N'2026-06-17T19:14:40.797',
             N'Tuber',
             N'Culosis',
             1,
             N'2026-06-17T00:00:00',
             N'2026-06-17T00:00:00',
             N'N',
             @dbo_Entity_entity_uid);

-- dbo.Person_name
-- step: 1
INSERT INTO [dbo].[person_name]
            ([person_uid],
             [person_name_seq],
             [add_reason_cd],
             [add_time],
             [add_user_id],
             [first_nm],
             [first_nm_sndx],
             [last_nm],
             [last_nm_sndx],
             [nm_use_cd],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid_2,
             1,
             N'Add',
             N'2026-06-17T19:14:40.607',
             @superuser_id,
             N'Tuber',
             N'M240',
             N'Culosis',
             N'P420',
             N'L',
             N'ACTIVE',
             N'2026-06-17T19:14:40.607',
             N'A',
             N'2026-06-17T19:14:40.607',
             N'2026-06-17T00:00:00');

-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[postal_locator]
            ([postal_locator_uid],
             [add_time],
             [add_user_id],
             [cntry_cd],
             [cnty_cd],
             [record_status_cd],
             [record_status_time],
             [state_cd],
             [street_addr1],
             [street_addr2],
             [within_city_limits_ind])
VALUES      (@dbo_Postal_locator_postal_locator_uid_2,
             N'2026-06-17T19:14:40.607',
             @superuser_id,
             N'840',
             N'',
             N'ACTIVE',
             N'2026-06-17T19:14:40.607',
             N'13',
             N'',
             N'',
             N'');

-- dbo.Entity_locator_participation
-- step: 1
INSERT INTO [dbo].[entity_locator_participation]
            ([entity_uid],
             [locator_uid],
             [cd],
             [class_cd],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [use_cd],
             [version_ctrl_nbr],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid_2,
             @dbo_Postal_locator_postal_locator_uid_2,
             N'H',
             N'PST',
             N'2026-06-17T19:14:40.797',
             @superuser_id,
             N'ACTIVE',
             N'2026-06-17T19:14:40.797',
             N'A',
             N'2026-06-17T19:14:40.797',
             N'H',
             1,
             N'2026-06-17T00:00:00');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid,
             N'CASE',
             N'EVN');

-- dbo.Public_health_case
-- step: 1
DECLARE @dbo_Public_health_case_local_id nvarchar(40) = N'CAS'
  + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_Act_act_uid)))
  + N'GA01';

INSERT INTO [dbo].[public_health_case]
            ([public_health_case_uid],
             [add_time],
             [add_user_id],
             [case_class_cd],
             [case_type_cd],
             [cd],
             [cd_desc_txt],
             [detection_method_cd],
             [disease_imported_cd],
             [effective_duration_amt],
             [effective_duration_unit_cd],
             [group_case_cnt],
             [investigation_status_cd],
             [jurisdiction_cd],
             [last_chg_time],
             [last_chg_user_id],
             [local_id],
             [mmwr_week],
             [mmwr_year],
             [outbreak_ind],
             [outbreak_name],
             [outcome_cd],
             [prog_area_cd],
             [record_status_cd],
             [record_status_time],
             [rpt_form_cmplt_time],
             [rpt_source_cd],
             [status_cd],
             [transmission_mode_cd],
             [txt],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [hospitalized_ind_cd],
             [pregnant_ind_cd],
             [day_care_ind_cd],
             [food_handler_ind_cd],
             [imported_country_cd],
             [imported_state_cd],
             [imported_city_desc_txt],
             [imported_county_cd],
             [priority_cd],
             [contact_inv_txt],
             [contact_inv_status_cd])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'C',
             N'I',
             N'10220',
             N'Tuberculosis',
             N'',
             N'',
             N'',
             N'',
             1,
             N'O',
             N'130006',
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             @dbo_Public_health_case_local_id,
             N'',
             N'',
             N'',
             N'',
             N'',
             N'TB',
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             N'2026-06-17T00:00:00',
             N'',
             N'A',
             N'',
             N'',
             1300600014,
             N'T',
             1,
             N'',
             N'',
             N'',
             N'',
             N'',
             N'',
             N'',
             N'',
             N'',
             N'',
             N'');

-- dbo.Act_id
-- step: 1
INSERT INTO [dbo].[act_id]
            ([act_uid],
             [act_id_seq],
             [root_extension_txt],
             [status_cd],
             [status_time],
             [type_cd])
VALUES      (@dbo_Act_act_uid,
             1,
             N'',
             N'A',
             N'2026-06-17T19:14:40.870',
             N'STATE');

-- step: 1
INSERT INTO [dbo].[act_id]
            ([act_uid],
             [act_id_seq],
             [root_extension_txt],
             [status_cd],
             [status_time],
             [type_cd])
VALUES      (@dbo_Act_act_uid,
             2,
             N'',
             N'A',
             N'2026-06-17T19:14:40.873',
             N'CITY');

-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [record_status_cd],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (@dbo_Entity_entity_uid_2,
             @dbo_Act_act_uid,
             N'SubjOfPHC',
             N'CASE',
             N'ACTIVE',
             N'A',
             N'2026-06-17T19:14:40.633',
             N'PSN',
             N'Subject Of Public Health Case');

-- dbo.NBS_case_answer
-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1284,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_2 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_2_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_2_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'06/17/2026',
             1449,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_2 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_2_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_3_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1061,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_3 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_3_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_4 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_4_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_4_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'260385009',
             1045,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_4 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_4_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_5 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_5_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_5_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1426,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_5 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_5_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_6 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_6_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_6_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'105493001',
             1335,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_6 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_6_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_7 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_7_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_7_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'PHC645',
             1026,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_7 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_7_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_8 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_8_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_8_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'NA',
             1417,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_8 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_8_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_9 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_9_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_9_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'06/17/2026',
             1450,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_9 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_9_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_10 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_10_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_10_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'73211009',
             1230,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             1);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_10 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_10_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_11 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_11_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_11_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'06/17/2026',
             1390,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_11 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_11_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_12 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_12_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_12_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'10828004',
             1282,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_12 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_12_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_13 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_13_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_13_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1353,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_13 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_13_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_14 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_14_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_14_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'386147002',
             1174,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             1);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_14 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_14_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_15 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_15_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_15_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'23451007',
             1043,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_15 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_15_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_16 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_16_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_16_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'06/17/2026',
             1437,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_16 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_16_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_17 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_17_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_17_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'260385009',
             1025,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_17 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_17_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_18 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_18_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_18_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'10828004',
             1452,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_18 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_18_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_19 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_19_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_19_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1089,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_19 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_19_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_20 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_20_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_20_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'3331',
             1266,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_20 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_20_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_21 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_21_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_21_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'Y',
             1331,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_21 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_21_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_22 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_22_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_22_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'260385009',
             1273,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_22 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_22_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_23 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_23_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_23_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'168734001',
             1451,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_23 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_23_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_24 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_24_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_24_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'abc',
             1334,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_24 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_24_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_25 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_25_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_25_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'06/17/2026',
             1069,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_25 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_25_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_26 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_26_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_26_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1132,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_26 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_26_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_27 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_27_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_27_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1033,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_27 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_27_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_28 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_28_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_28_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'C0376558',
             1319,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_28 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_28_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_29 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_29_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_29_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'120228005',
             1079,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             1);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_29 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_29_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_30 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_30_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_30_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1006,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_30 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_30_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_31 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_31_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_31_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1351,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_31 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_31_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_32 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_32_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_32_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1375,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_32 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_32_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_33 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_33_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_33_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1000,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_33 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_33_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_34 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_34_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_34_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1458,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_34 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_34_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_35 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_35_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_35_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1150,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_35 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_35_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_36 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_36_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_36_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'UNK',
             1304,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_36 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_36_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_37 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_37_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_37_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1267,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_37 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_37_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_38 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_38_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_38_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'A',
             1302,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_38 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_38_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_39 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_39_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_39_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1414,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_39 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_39_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_40 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_40_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_40_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OTH',
             1077,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_40 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_40_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_41 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_41_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_41_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1300,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_41 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_41_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_42 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_42_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_42_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'10828004',
             1012,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_42 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_42_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_43 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_43_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_43_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'Y',
             1453,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_43 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_43_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_44 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_44_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_44_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'Y',
             1354,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_44 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_44_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_45 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_45_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_45_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'PHC97',
             1290,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_45 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_45_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_46 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_46_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_46_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'A',
             1315,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_46 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_46_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_47 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_47_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_47_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1279,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_47 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_47_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_48 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_48_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_48_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'12',
             1337,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_48 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_48_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_49 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_49_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_49_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'06/17/2026',
             1076,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_49 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_49_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_50 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_50_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_50_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'Y',
             1254,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_50 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_50_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_51 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_51_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_51_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'Y',
             1038,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_51 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_51_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_52 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_52_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_52_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'06/17/2026',
             1001,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_52 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_52_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_53 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_53_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_53_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'66754008',
             1425,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_53 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_53_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_54 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_54_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_54_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1391,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_54 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_54_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_55 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_55_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_55_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'06/17/2026',
             1316,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_55 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_55_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_56 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_56_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_56_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1352,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_56 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_56_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_57 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_57_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_57_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'10828004',
             1058,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_57 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_57_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_58 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_58_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_58_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'Y',
             1107,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_58 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_58_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_59 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_59_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_59_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'Y',
             1298,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_59 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_59_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_60 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_60_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_60_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'06/17/2026',
             1090,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_60 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_60_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_61 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_61_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_61_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'82334004',
             1149,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_61 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_61_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_62 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_62_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_62_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1115,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_62 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_62_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_63 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_63_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_63_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'PHC645',
             1233,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_63 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_63_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_64 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_64_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_64_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1247,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_64 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_64_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_65 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_65_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_65_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'06/17/2026',
             1108,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_65 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_65_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_66 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_66_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_66_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'N',
             1406,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_66 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_66_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_67 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_67_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_67_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'06/17/2026',
             1288,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_67 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_67_output;

-- step: 1
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_68 bigint;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_68_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_case_answer]
            ([act_uid],
             [add_time],
             [add_user_id],
             [answer_txt],
             [nbs_question_uid],
             [nbs_question_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [seq_nbr])
OUTPUT      INSERTED.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_68_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'Y',
             1281,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_68 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_68_output;

-- dbo.NBS_act_entity
-- step: 1
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid bigint;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_output TABLE
  (
     [value] bigint
  );

INSERT INTO [dbo].[nbs_act_entity]
            ([act_uid],
             [add_time],
             [add_user_id],
             [entity_uid],
             [entity_version_ctrl_nbr],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [type_cd])
OUTPUT      INSERTED.[nbs_act_entity_uid]
INTO @dbo_NBS_act_entity_nbs_act_entity_uid_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             @dbo_Entity_entity_uid_2,
             1,
             N'2026-06-17T19:14:40.847',
             @superuser_id,
             N'OPEN',
             N'2026-06-17T19:14:40.847',
             N'SubjOfPHC');

SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid = [value]
FROM   @dbo_NBS_act_entity_nbs_act_entity_uid_output;

-- dbo.Person
-- step: 1
UPDATE [dbo].[person]
SET    [last_chg_time] = N'2026-06-17T19:14:40.787',
       [record_status_time] = N'2026-06-17T19:14:40.787',
       [status_time] = N'2026-06-17T19:14:40.787',
       [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 0) + 1
WHERE  [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 1
UPDATE [dbo].[entity_locator_participation]
SET    [last_chg_time] = N'2026-06-17T19:14:40.787',
       [record_status_time] = N'2026-06-17T19:14:40.787',
       [status_time] = N'2026-06-17T19:14:40.787'
WHERE  [entity_uid] = @dbo_Entity_entity_uid
       AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid; 