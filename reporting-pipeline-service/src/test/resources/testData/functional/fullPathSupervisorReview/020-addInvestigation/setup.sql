USE [NBS_ODSE];

DECLARE @local_user_id BIGINT = 10007004;
-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid BIGINT = 20100400;
DECLARE @dbo_Postal_locator_postal_locator_uid BIGINT = 20100401;
DECLARE @dbo_Tele_locator_tele_locator_uid BIGINT = 20100402;
DECLARE @dbo_Tele_locator_tele_locator_uid_2 BIGINT = 20100403;
DECLARE @dbo_Entity_entity_uid_2 BIGINT = 20100404;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 BIGINT = 20100405;
DECLARE @dbo_Tele_locator_tele_locator_uid_3 BIGINT = 20100406;
DECLARE @dbo_Tele_locator_tele_locator_uid_4 BIGINT = 20100407;
DECLARE @dbo_Act_act_uid BIGINT = 20100408;
DECLARE @dbo_Person_local_id NVARCHAR(40) = N'PSN20100400GA01';

-- STEP 2: AddInvestigation
-- dbo.Entity
-- step: 2
INSERT INTO [dbo].[entity]
            ([entity_uid],
             [class_cd])
VALUES      (@dbo_Entity_entity_uid_2,
             N'PSN');

-- dbo.Person
-- step: 2
INSERT INTO [dbo].[person]
            ([person_uid],
             [add_time],
             [add_user_id],
             [age_reported],
             [age_reported_unit_cd],
             [birth_time],
             [birth_time_calc],
             [cd],
             [curr_sex_cd],
             [deceased_ind_cd],
             [ethnic_group_ind],
             [last_chg_time],
             [last_chg_user_id],
             [local_id],
             [marital_status_cd],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [first_nm],
             [last_nm],
             [version_ctrl_nbr],
             [as_of_date_admin],
             [as_of_date_ethnicity],
             [as_of_date_general],
             [as_of_date_morbidity],
             [as_of_date_sex],
             [electronic_ind],
             [person_parent_uid])
VALUES      (@dbo_Entity_entity_uid_2,
             N'2026-04-22T20:47:53.183',
             @local_user_id,
             N'62',
             N'Y',
             N'1964-01-30T00:00:00',
             N'1964-01-30T00:00:00',
             N'PAT',
             N'M',
             N'N',
             N'2186-5',
             N'2026-04-22T20:47:53.183',
             @local_user_id,
             @dbo_Person_local_id,
             N'M',
             N'ACTIVE',
             N'2026-04-22T20:47:53.183',
             N'A',
             N'2026-04-22T20:47:53.183',
             N'Richard',
             N'Wells',
             1,
             N'2026-04-22T00:00:00',
             N'2026-04-22T00:00:00',
             N'2026-04-22T00:00:00',
             N'2026-04-22T00:00:00',
             N'2026-04-22T00:00:00',
             N'N',
             @dbo_Entity_entity_uid);

-- dbo.Person_name
-- step: 2
INSERT INTO [dbo].[person_name]
            ([person_uid],
             [person_name_seq],
             [add_time],
             [add_user_id],
             [first_nm],
             [first_nm_sndx],
             [last_chg_time],
             [last_chg_user_id],
             [last_nm],
             [last_nm_sndx],
             [middle_nm],
             [nm_use_cd],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid_2,
             1,
             N'2026-04-22T20:47:52.973',
             @local_user_id,
             N'Richard',
             N'R263',
             N'2026-04-22T20:47:52.973',
             @local_user_id,
             N'Wells',
             N'W420',
             N'D',
             N'L',
             N'ACTIVE',
             N'2026-04-22T20:47:52.973',
             N'A',
             N'2026-04-22T20:47:52.973',
             N'2026-04-22T00:00:00');

-- dbo.Person_race
-- step: 2
INSERT INTO [dbo].[person_race]
            ([person_uid],
             [race_cd],
             [add_time],
             [add_user_id],
             [race_category_cd],
             [record_status_cd],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid_2,
             N'2106-3',
             N'2026-04-22T20:47:52.973',
             @local_user_id,
             N'2106-3',
             N'ACTIVE',
             N'2026-04-22T00:00:00');

-- dbo.Entity_id
-- step: 2
INSERT INTO [dbo].[entity_id]
            ([entity_uid],
             [entity_id_seq],
             [add_time],
             [assigning_authority_cd],
             [assigning_authority_desc_txt],
             [last_chg_time],
             [record_status_cd],
             [record_status_time],
             [root_extension_txt],
             [status_cd],
             [status_time],
             [type_cd],
             [type_desc_txt],
             [as_of_date],
             [assigning_authority_id_type])
VALUES      (@dbo_Entity_entity_uid_2,
             1,
             N'2026-04-22T20:47:52.997',
             N'GA',
             N'GA',
             N'2026-04-22T20:47:52.997',
             N'ACTIVE',
             N'2026-04-22T20:47:52.997',
             N'111100000',
             N'A',
             N'2026-04-22T20:47:52.997',
             N'DL',
             N'Driver''s license number',
             N'2026-04-22T00:00:00',
             N'L');

-- dbo.Postal_locator
-- step: 2
INSERT INTO [dbo].[postal_locator]
            ([postal_locator_uid],
             [add_time],
             [add_user_id],
             [city_desc_txt],
             [cntry_cd],
             [cnty_cd],
             [record_status_cd],
             [record_status_time],
             [state_cd],
             [street_addr1],
             [zip_cd])
VALUES      (@dbo_Postal_locator_postal_locator_uid_2,
             N'2026-04-22T20:47:52.973',
             @local_user_id,
             N'Atlanta',
             N'840',
             N'13121',
             N'ACTIVE',
             N'2026-04-22T20:47:52.973',
             N'13',
             N'174 Neuport Drive',
             N'30338');

-- dbo.Entity_locator_participation
-- step: 2
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
             N'2026-04-22T20:47:53.183',
             @local_user_id,
             N'ACTIVE',
             N'2026-04-22T20:47:53.183',
             N'A',
             N'2026-04-22T20:47:53.183',
             N'H',
             1,
             N'2026-04-22T00:00:00');

-- dbo.Tele_locator
-- step: 2
INSERT INTO [dbo].[tele_locator]
            ([tele_locator_uid],
             [add_time],
             [add_user_id],
             [extension_txt],
             [phone_nbr_txt],
             [record_status_cd])
VALUES      (@dbo_Tele_locator_tele_locator_uid_3,
             N'2026-04-22T20:47:52.973',
             @local_user_id,
             N'',
             N'707-555-1111',
             N'ACTIVE');

-- dbo.Entity_locator_participation
-- step: 2
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
             @dbo_Tele_locator_tele_locator_uid_3,
             N'PH',
             N'TELE',
             N'2026-04-22T20:47:53.183',
             @local_user_id,
             N'ACTIVE',
             N'2026-04-22T20:47:53.183',
             N'A',
             N'2026-04-22T20:47:53.183',
             N'H',
             1,
             N'2026-04-22T00:00:00');

-- dbo.Tele_locator
-- step: 2
INSERT INTO [dbo].[tele_locator]
            ([tele_locator_uid],
             [add_time],
             [add_user_id],
             [extension_txt],
             [phone_nbr_txt],
             [record_status_cd])
VALUES      (@dbo_Tele_locator_tele_locator_uid_4,
             N'2026-04-22T20:47:52.973',
             @local_user_id,
             N'',
             N'707-454-1212',
             N'ACTIVE');

-- dbo.Entity_locator_participation
-- step: 2
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
             @dbo_Tele_locator_tele_locator_uid_4,
             N'PH',
             N'TELE',
             N'2026-04-22T20:47:53.183',
             @local_user_id,
             N'ACTIVE',
             N'2026-04-22T20:47:53.183',
             N'A',
             N'2026-04-22T20:47:53.183',
             N'WP',
             1,
             N'2026-04-22T00:00:00');

-- dbo.Act
-- step: 2
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid,
             N'CASE',
             N'EVN');

-- dbo.Public_health_case
-- step: 2
DECLARE @dbo_Public_health_case_local_id NVARCHAR(40) = N'CAS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid)))
  + N'GA01';

INSERT INTO [dbo].[public_health_case]
            ([public_health_case_uid],
             [activity_from_time],
             [add_time],
             [add_user_id],
             [case_class_cd],
             [case_type_cd],
             [cd],
             [cd_desc_txt],
             [detection_method_cd],
             [diagnosis_time],
             [disease_imported_cd],
             [effective_duration_amt],
             [effective_duration_unit_cd],
             [effective_from_time],
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
             [pat_age_at_onset],
             [pat_age_at_onset_unit_cd],
             [prog_area_cd],
             [record_status_cd],
             [record_status_time],
             [rpt_form_cmplt_time],
             [rpt_source_cd],
             [rpt_to_county_time],
             [rpt_to_state_time],
             [status_cd],
             [transmission_mode_cd],
             [transmission_mode_desc_txt],
             [txt],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [investigator_assigned_time],
             [hospitalized_ind_cd],
             [hospitalized_admin_time],
             [pregnant_ind_cd],
             [day_care_ind_cd],
             [food_handler_ind_cd],
             [imported_country_cd],
             [imported_state_cd],
             [imported_city_desc_txt],
             [imported_county_cd],
             [priority_cd],
             [contact_inv_txt],
             [infectious_from_date],
             [infectious_to_date],
             [contact_inv_status_cd])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T00:00:00',
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'C',
             N'I',
             N'10110',
             N'Hepatitis A, acute',
             N'PHC2112',
             N'2026-04-21T00:00:00',
             N'',
             N'',
             N'',
             N'2026-04-03T00:00:00',
             1,
             N'O',
             N'130005',
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             @dbo_Public_health_case_local_id,
             N'16',
             N'2026',
             N'N',
             N'',
             N'N',
             N'62',
             N'Y',
             N'HEP',
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             N'2026-04-01T00:00:00',
             N'HO',
             N'2026-04-02T00:00:00',
             N'2026-04-03T00:00:00',
             N'A',
             N'B',
             N'B',
             N'',
             1300500011,
             N'T',
             1,
             N'2026-04-20T00:00:00',
             N'Y',
             N'2026-04-01T00:00:00',
             N'',
             N'N',
             N'N',
             N'',
             N'',
             N'',
             N'',
             N'LOW',
             N'This is a test comment',
             N'2026-04-10T00:00:00',
             N'2026-04-21T00:00:00',
             N'O');

-- dbo.Confirmation_method
-- step: 2
INSERT INTO [dbo].[confirmation_method]
            ([public_health_case_uid],
             [confirmation_method_cd],
             [confirmation_method_time])
VALUES      (@dbo_Act_act_uid,
             N'LR',
             N'2026-04-20T00:00:00');

-- dbo.Act_id
-- step: 2
INSERT INTO [dbo].[act_id]
            ([act_uid],
             [act_id_seq],
             [root_extension_txt],
             [status_cd],
             [status_time],
             [type_cd])
VALUES      (@dbo_Act_act_uid,
             1,
             N'1',
             N'A',
             N'2026-04-22T20:47:53.277',
             N'STATE');

-- step: 2
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
             N'2026-04-22T20:47:53.277',
             N'CITY');

-- step: 2
INSERT INTO [dbo].[act_id]
            ([act_uid],
             [act_id_seq],
             [root_extension_txt],
             [status_cd],
             [status_time],
             [type_cd])
VALUES      (@dbo_Act_act_uid,
             3,
             N'2',
             N'A',
             N'2026-04-22T20:47:53.280',
             N'LEGACY');

-- dbo.Participation
-- step: 2
INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [add_time],
             [add_user_id],
             [from_time],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (@dbo_Entity_entity_uid_2,
             @dbo_Act_act_uid,
             N'SubjOfPHC',
             N'CASE',
             N'2026-04-22T20:47:52.990',
             @local_user_id,
             N'2026-04-03T00:00:00',
             N'2026-04-22T20:47:52.990',
             @local_user_id,
             N'ACTIVE',
             N'2026-04-22T20:47:52.997',
             N'A',
             N'2026-04-22T20:47:52.997',
             N'PSN',
             N'Subject Of Public Health Case');

-- step: 2
INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [add_time],
             [add_user_id],
             [from_time],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (10003001,
             @dbo_Act_act_uid,
             N'HospOfADT',
             N'CASE',
             N'2026-04-22T20:47:53.007',
             @local_user_id,
             N'2026-04-20T00:00:00',
             N'2026-04-22T20:47:53.007',
             @local_user_id,
             N'ACTIVE',
             N'2026-04-22T20:47:53.007',
             N'A',
             N'2026-04-22T20:47:53.007',
             N'ORG',
             N'Hospital Of ADT');

-- step: 2
INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [add_time],
             [add_user_id],
             [from_time],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (10007000,
             @dbo_Act_act_uid,
             N'InvestgrOfPHC',
             N'CASE',
             N'2026-04-22T20:47:53.007',
             @local_user_id,
             N'2026-04-20T00:00:00',
             N'2026-04-22T20:47:53.007',
             @local_user_id,
             N'ACTIVE',
             N'2026-04-22T20:47:53.007',
             N'A',
             N'2026-04-22T20:47:53.007',
             N'PSN',
             N'PHC Investigator');

-- step: 2
INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [add_time],
             [add_user_id],
             [from_time],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (10003007,
             @dbo_Act_act_uid,
             N'OrgAsReporterOfPHC',
             N'CASE',
             N'2026-04-22T20:47:53.007',
             @local_user_id,
             N'2026-04-20T00:00:00',
             N'2026-04-22T20:47:53.007',
             @local_user_id,
             N'ACTIVE',
             N'2026-04-22T20:47:53.007',
             N'A',
             N'2026-04-22T20:47:53.007',
             N'ORG',
             N'Organization As Reporter Of PHC');

-- step: 2
INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [add_time],
             [add_user_id],
             [from_time],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (10003004,
             @dbo_Act_act_uid,
             N'PerAsReporterOfPHC',
             N'CASE',
             N'2026-04-22T20:47:53.007',
             @local_user_id,
             N'2026-04-20T00:00:00',
             N'2026-04-22T20:47:53.007',
             @local_user_id,
             N'ACTIVE',
             N'2026-04-22T20:47:53.007',
             N'A',
             N'2026-04-22T20:47:53.007',
             N'PSN',
             N'PHC Reporter');

-- step: 2
INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [add_time],
             [add_user_id],
             [from_time],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (10003004,
             @dbo_Act_act_uid,
             N'PhysicianOfPHC',
             N'CASE',
             N'2026-04-22T20:47:53.007',
             @local_user_id,
             N'2026-04-20T00:00:00',
             N'2026-04-22T20:47:53.007',
             @local_user_id,
             N'ACTIVE',
             N'2026-04-22T20:47:53.007',
             N'A',
             N'2026-04-22T20:47:53.007',
             N'PSN',
             N'Physician of PHC');

-- dbo.NBS_case_answer
-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001091,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_2 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_2_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_2_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'840',
             10001007,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_2 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_2_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_3_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_3_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'P',
             10001040,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_3 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_3_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_4 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_4_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_4_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'P',
             10001059,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_4 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_4_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_5 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_5_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_5_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001013,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_5 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_5_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_6 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_6_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_6_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'2',
             10001035,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_6 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_6_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_7 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_7_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_7_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001042,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_7 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_7_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_8 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_8_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_8_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001095,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_8 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_8_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_9 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_9_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_9_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/15/2026',
             10001034,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_9 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_9_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_10 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_10_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_10_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001083,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_10 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_10_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_11 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_11_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_11_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/07/2026',
             10001045,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_11 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_11_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_12 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_12_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_12_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'2',
             10001075,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_12 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_12_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_13 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_13_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_13_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/11/2026',
             10001053,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_13 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_13_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_14 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_14_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_14_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'13089',
             10001005,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_14 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_14_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_15 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_15_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_15_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001080,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_15 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_15_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_16 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_16_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_16_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/16/2026',
             10001037,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_16 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_16_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_17 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_17_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_17_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001048,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_17 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_17_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_18 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_18_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_18_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/13/2026',
             10001060,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_18 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_18_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_19 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_19_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_19_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'P',
             10001046,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_19 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_19_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_20 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_20_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_20_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/14/2026',
             10001062,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_20 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_20_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_21 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_21_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_21_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'P',
             10001052,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_21 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_21_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_22 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_22_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_22_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/08/2026',
             10001047,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_22 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_22_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_23 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_23_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_23_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'1',
             10001093,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_23 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_23_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_24 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_24_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_24_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/06/2026',
             10001043,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_24 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_24_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_25 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_25_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_25_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001054,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_25 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_25_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_26 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_26_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_26_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/10/2026',
             10001051,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_26 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_26_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_27 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_27_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_27_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'2',
             10001055,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_27 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_27_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_28 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_28_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_28_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'1',
             10001038,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_28 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_28_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_29 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_29_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_29_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'1978',
             10001094,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_29 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_29_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_30 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_30_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_30_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001031,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_30 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_30_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_31 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_31_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_31_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'UNK',
             10001064,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_31 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_31_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_32 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_32_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_32_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001078,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_32 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_32_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_33 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_33_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_33_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001079,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_33 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_33_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_34 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_34_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_34_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'UNK',
             10001057,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_34 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_34_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_35 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_35_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_35_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'0',
             10001076,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_35 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_35_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_36 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_36_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_36_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/09/2026',
             10001049,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_36 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_36_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_37 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_37_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_37_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'Y',
             10001092,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_37 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_37_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_38 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_38_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_38_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'1',
             10001077,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_38 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_38_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_39 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_39_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_39_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'UNK',
             10001050,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_39 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_39_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_40 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_40_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_40_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/12/2026',
             10001056,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_40 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_40_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_41 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_41_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_41_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001061,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_41 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_41_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_42 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_42_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_42_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001074,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_42 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_42_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_43 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_43_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_43_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001028,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_43 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_43_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_44 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_44_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_44_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             1113,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_44 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_44_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_45 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_45_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_45_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/12/2026',
             10001058,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_45 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_45_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_46 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_46_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_46_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'Y',
             10001029,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_46 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_46_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_47 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_47_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_47_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001030,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_47 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_47_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_48 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_48_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_48_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/05/2026',
             10001041,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_48 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_48_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_49 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_49_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_49_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'1',
             10001033,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_49 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_49_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_50 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_50_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_50_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'Y',
             10001027,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_50 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_50_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_51 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_51_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_51_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001085,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_51 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_51_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_52 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_52_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_52_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'UNK',
             10001072,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_52 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_52_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_53 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_53_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_53_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'N',
             10001073,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_53 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_53_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_54 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_54_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_54_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'2',
             10001036,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_54 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_54_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_55 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_55_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_55_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'04/04/2026',
             10001039,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_55 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_55_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_56 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_56_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_56_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'UNK',
             10001044,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_56 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_56_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_57 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_57_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_57_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'UNK',
             10001063,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_57 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_57_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_58 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_58_output TABLE
  (
     [value] BIGINT
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
             [seq_nbr],
             [answer_group_seq_nbr])
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_58_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'Atlanta',
             10001010,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0,
             1);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_58 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_58_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_59 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_59_output TABLE
  (
     [value] BIGINT
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
             [seq_nbr],
             [answer_group_seq_nbr])
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_59_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'13089',
             10001011,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0,
             1);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_59 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_59_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_60 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_60_output TABLE
  (
     [value] BIGINT
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
             [seq_nbr],
             [answer_group_seq_nbr])
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_60_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'840',
             10001008,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0,
             1);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_60 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_60_output;

-- step: 2
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_61 BIGINT;
DECLARE @dbo_NBS_case_answer_nbs_case_answer_uid_61_output TABLE
  (
     [value] BIGINT
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
             [seq_nbr],
             [answer_group_seq_nbr])
output      inserted.[nbs_case_answer_uid]
INTO @dbo_NBS_case_answer_nbs_case_answer_uid_61_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'13',
             10001009,
             4,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             0,
             1);

SELECT TOP 1 @dbo_NBS_case_answer_nbs_case_answer_uid_61 = [value]
FROM   @dbo_NBS_case_answer_nbs_case_answer_uid_61_output;

-- dbo.NBS_act_entity
-- step: 2
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid BIGINT;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_act_entity_uid]
INTO @dbo_NBS_act_entity_nbs_act_entity_uid_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             @dbo_Entity_entity_uid_2,
             1,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             N'SubjOfPHC');

SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid = [value]
FROM   @dbo_NBS_act_entity_nbs_act_entity_uid_output;

-- step: 2
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2 BIGINT;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_act_entity_uid]
INTO @dbo_NBS_act_entity_nbs_act_entity_uid_2_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             10003001,
             2,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             N'HospOfADT');

SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_2 = [value]
FROM   @dbo_NBS_act_entity_nbs_act_entity_uid_2_output;

-- step: 2
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3 BIGINT;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_act_entity_uid]
INTO @dbo_NBS_act_entity_nbs_act_entity_uid_3_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             10007000,
             1,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             N'InvestgrOfPHC');

SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_3 = [value]
FROM   @dbo_NBS_act_entity_nbs_act_entity_uid_3_output;

-- step: 2
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_4 BIGINT;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_4_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_act_entity_uid]
INTO @dbo_NBS_act_entity_nbs_act_entity_uid_4_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             10003007,
             1,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             N'OrgAsReporterOfPHC');

SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_4 = [value]
FROM   @dbo_NBS_act_entity_nbs_act_entity_uid_4_output;

-- step: 2
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_5 BIGINT;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_5_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_act_entity_uid]
INTO @dbo_NBS_act_entity_nbs_act_entity_uid_5_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             10003004,
             1,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             N'PerAsReporterOfPHC');

SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_5 = [value]
FROM   @dbo_NBS_act_entity_nbs_act_entity_uid_5_output;

-- step: 2
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_6 BIGINT;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_6_output TABLE
  (
     [value] BIGINT
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
output      inserted.[nbs_act_entity_uid]
INTO @dbo_NBS_act_entity_nbs_act_entity_uid_6_output ([value])
VALUES      (@dbo_Act_act_uid,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             10003004,
             1,
             N'2026-04-22T20:47:53.240',
             @local_user_id,
             N'OPEN',
             N'2026-04-22T20:47:53.240',
             N'PhysicianOfPHC');

SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_6 = [value]
FROM   @dbo_NBS_act_entity_nbs_act_entity_uid_6_output;

-- dbo.Person
-- step: 2
UPDATE [dbo].[person]
SET    [last_chg_time] = N'2026-04-22T20:47:53.160',
       [record_status_time] = N'2026-04-22T20:47:53.160',
       [status_time] = N'2026-04-22T20:47:53.160',
       [version_ctrl_nbr] = Isnull([version_ctrl_nbr], 0) + 1
WHERE  [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 2
UPDATE [dbo].[entity_locator_participation]
SET    [last_chg_time] = N'2026-04-22T20:47:53.163',
       [record_status_time] = N'2026-04-22T20:47:53.163',
       [status_time] = N'2026-04-22T20:47:53.163'
WHERE  [entity_uid] = @dbo_Entity_entity_uid
       AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;

-- step: 2
UPDATE [dbo].[entity_locator_participation]
SET    [last_chg_time] = N'2026-04-22T20:47:53.163',
       [record_status_time] = N'2026-04-22T20:47:53.163',
       [status_time] = N'2026-04-22T20:47:53.163'
WHERE  [entity_uid] = @dbo_Entity_entity_uid
       AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid;

-- step: 2
UPDATE [dbo].[entity_locator_participation]
SET    [last_chg_time] = N'2026-04-22T20:47:53.163',
       [record_status_time] = N'2026-04-22T20:47:53.163',
       [status_time] = N'2026-04-22T20:47:53.163'
WHERE  [entity_uid] = @dbo_Entity_entity_uid
       AND [locator_uid] = @dbo_Tele_locator_tele_locator_uid_2;

-- dbo.PublicHealthCaseFact
-- step: 2
INSERT INTO [dbo].[publichealthcasefact]
            ([public_health_case_uid],
             [age_reported_unit_cd],
             [age_reported],
             [birth_gender_cd],
             [birth_time],
             [birth_time_calc],
             [case_class_cd],
             [case_type_cd],
             [city_desc_txt],
             [confirmation_method_cd],
             [confirmation_method_time],
             [county],
             [cntry_cd],
             [cnty_cd],
             [curr_sex_cd],
             [deceased_ind_cd],
             [detection_method_cd],
             [detection_method_desc_txt],
             [diagnosis_date],
             [elp_class_cd],
             [ethnic_group_ind],
             [ethnic_group_ind_desc],
             [event_date],
             [event_type],
             [group_case_cnt],
             [investigation_status_cd],
             [investigatorassigneddate],
             [investigatorname],
             [jurisdiction_cd],
             [marital_status_cd],
             [marital_status_desc_txt],
             [mart_record_creation_time],
             [mmwr_week],
             [mmwr_year],
             [onsetdate],
             [organizationname],
             [outcome_cd],
             [outbreak_ind],
             [par_type_cd],
             [pat_age_at_onset],
             [pat_age_at_onset_unit_cd],
             [postal_locator_uid],
             [person_cd],
             [person_uid],
             [phc_add_time],
             [phc_code],
             [phc_code_desc],
             [phc_code_short_desc],
             [prog_area_cd],
             [providerphone],
             [providername],
             [pst_record_status_time],
             [pst_record_status_cd],
             [race_concatenated_txt],
             [race_concatenated_desc_txt],
             [record_status_cd],
             [reportername],
             [reporterphone],
             [rpt_form_cmplt_time],
             [rpt_source_cd],
             [rpt_source_desc_txt],
             [rpt_to_county_time],
             [rpt_to_state_time],
             [shared_ind],
             [state],
             [state_cd],
             [status_cd],
             [street_addr1],
             [elp_use_cd],
             [zip_cd],
             [patientname],
             [jurisdiction],
             [investigationstartdate],
             [program_jurisdiction_oid],
             [report_date],
             [person_parent_uid],
             [person_local_id],
             [sub_addr_as_of_date],
             [state_case_id],
             [local_id],
             [age_reported_unit_desc_txt],
             [birth_gender_desc_txt],
             [case_class_desc_txt],
             [cntry_desc_txt],
             [curr_sex_desc_txt],
             [investigation_status_desc_txt],
             [outcome_desc_txt],
             [pat_age_at_onset_unit_desc_txt],
             [prog_area_desc_txt],
             [confirmation_method_desc_txt],
             [lastupdate],
             [hsptl_admission_dt],
             [hospitalized_ind])
VALUES      (@dbo_Act_act_uid,
             N'Y',
             62,
             N'M',
             N'1964-01-30T00:00:00',
             N'1964-01-30T00:00:00',
             N'C',
             N'I',
             N'Atlanta',
             N'LR',
             N'2026-04-20T00:00:00',
             N'Fulton County',
             N'840',
             N'13121',
             N'M',
             N'N',
             N'PHC2112',
             N'Laboratory reported',
             N'2026-04-21T00:00:00',
             N'PST',
             N'2186-5',
             N'Not Hispanic or Latino',
             N'2026-04-03T00:00:00',
             N'O',
             1.0,
             N'O',
             N'2026-04-20T00:00:00',
             N'LocalUser, DIS',
             N'130005',
             N'M',
             N'Married',
             N'2026-04-22T20:48:00.643',
             16,
             2026,
             N'2026-04-03T00:00:00',
             N'CHOA - Scottish Rite',
             N'N',
             N'N',
             N'SubjOfPHC',
             62,
             N'Y',
             @dbo_Postal_locator_postal_locator_uid_2,
             N'PAT',
             @dbo_Entity_entity_uid_2,
             N'2026-04-22T20:47:53.240',
             N'10110',
             N'Hepatitis A, acute',
             N'Hepatitis A, acute',
             N'HEP',
             N'404-778-3350',
             N'Xerogeanes, John',
             N'2026-04-22T20:47:52.973',
             N'ACTIVE',
             N'2106-3',
             N'White',
             N'OPEN',
             N'Xerogeanes, John',
             N'404-778-3350',
             N'2026-04-01T00:00:00',
             N'HO',
             N'Hospital',
             N'2026-04-02T00:00:00',
             N'2026-04-03T00:00:00',
             N'T',
             N'Georgia',
             N'13',
             N'A',
             N'174 Neuport Drive',
             N'H',
             N'30338',
             N'Wells, Richard',
             N'Dekalb County',
             N'2026-04-22T00:00:00',
             1300500011,
             N'2026-04-02T00:00:00',
             10009283,
             @dbo_Person_local_id,
             N'2026-04-22T00:00:00',
             N'1',
             @dbo_Public_health_case_local_id,
             N'Years',
             N'Male',
             N'Confirmed',
             N'UNITED STATES',
             N'Male',
             N'Open',
             N'No',
             N'Years',
             N'HEP',
             N' Laboratory report',
             N'2026-04-22T20:47:53.240',
             N'2026-04-01T00:00:00',
             N'Y');

-- dbo.SubjectRaceInfo
-- step: 2
INSERT INTO [dbo].[subjectraceinfo]
            ([morbreport_uid],
             [public_health_case_uid],
             [race_cd],
             [race_category_cd])
VALUES      (0,
             @dbo_Act_act_uid,
             N'2106-3',
             N'2106-3'); 