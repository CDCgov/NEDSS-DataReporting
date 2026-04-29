USE [NBS_ODSE];

DECLARE @superuser_id BIGINT = 10009282;
-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid BIGINT = 20002000;
DECLARE @dbo_Postal_locator_postal_locator_uid BIGINT = 20002001;
DECLARE @dbo_Entity_entity_uid_2 BIGINT = 20002002;
DECLARE @dbo_Postal_locator_postal_locator_uid_2 BIGINT = 20002003;
DECLARE @dbo_Act_act_uid BIGINT = 20002004;
DECLARE @dbo_Act_act_uid_2 BIGINT = 20002005;
DECLARE @dbo_Entity_entity_uid_3 BIGINT = 20002006;
DECLARE @dbo_Postal_locator_postal_locator_uid_3 BIGINT = 20002007;
DECLARE @dbo_Person_local_id NVARCHAR(40) = N'PSN'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Entity_entity_uid)))
  + N'GA01';
DECLARE @dbo_Public_health_case_local_id NVARCHAR(40) = N'CAS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid)))
  + N'GA01';
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid BIGINT;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_output TABLE
  (
     [value] BIGINT
  );
DECLARE @dbo_Intervention_local_id NVARCHAR(40) = N'INT'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_2)))
  + N'GA01';
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2 BIGINT;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_2_output TABLE
  (
     [value] BIGINT
  );
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3 BIGINT;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_3_output TABLE
  (
     [value] BIGINT
  );
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_4 BIGINT;
DECLARE @dbo_NBS_act_entity_nbs_act_entity_uid_4_output TABLE
  (
     [value] BIGINT
  );

-- STEP 1: Create Patient with Covid Investigation and Vaccination
-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[entity]
            ([entity_uid],
             [class_cd])
VALUES      (@dbo_Entity_entity_uid,
             N'PSN');

-- dbo.Person
-- step: 1
INSERT INTO [dbo].[person]
            ([person_uid],
             [add_time],
             [add_user_id],
             [birth_gender_cd],
             [cd],
             [curr_sex_cd],
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
             N'2026-04-29T20:55:17.803',
             @superuser_id,
             N'M',
             N'PAT',
             N'M',
             N'2026-04-29T20:55:17.803',
             @superuser_id,
             @dbo_Person_local_id,
             N'ACTIVE',
             N'2026-04-29T20:55:17.803',
             N'A',
             N'2026-04-29T20:55:17.803',
             N'Covid',
             N'Patient',
             1,
             N'2026-04-29T00:00:00',
             N'2026-04-29T00:00:00',
             N'2026-04-29T00:00:00',
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
             N'2026-04-29T20:55:17.667',
             N'Covid',
             N'C130',
             N'Patient',
             N'P353',
             N'L',
             N'ACTIVE',
             N'2026-04-29T20:55:17.667',
             N'A',
             N'2026-04-29T20:55:17.667',
             N'2026-04-29T00:00:00');

-- dbo.Person_race
-- step: 1
INSERT INTO [dbo].[person_race]
            ([person_uid],
             [race_cd],
             [race_category_cd],
             [race_desc_txt],
             [record_status_cd],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid,
             N'2131-1',
             N'2131-1',
             N'Other Race',
             N'ACTIVE',
             N'2026-04-29T00:00:00');

-- step: 1
INSERT INTO [dbo].[person_race]
            ([person_uid],
             [race_cd],
             [add_time],
             [race_category_cd],
             [record_status_cd],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid,
             N'2106-3',
             N'2026-04-29T20:55:17.667',
             N'2106-3',
             N'ACTIVE',
             N'2026-04-29T00:00:00');

-- dbo.Postal_locator
-- step: 1
INSERT INTO [dbo].[postal_locator]
            ([postal_locator_uid],
             [add_time],
             [city_desc_txt],
             [cntry_cd],
             [cnty_cd],
             [record_status_cd],
             [record_status_time],
             [state_cd],
             [street_addr1],
             [street_addr2],
             [zip_cd])
VALUES      (@dbo_Postal_locator_postal_locator_uid,
             N'2026-04-29T20:55:17.667',
             N'Atlanta',
             N'840',
             N'13231',
             N'ACTIVE',
             N'2026-04-29T20:55:17.667',
             N'13',
             N'123 Second St',
             N'',
             N'33033');

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
             N'2026-04-29T20:55:17.803',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-29T20:55:17.803',
             N'A',
             N'2026-04-29T20:55:17.803',
             N'H',
             1,
             N'2026-04-29T00:00:00');

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
             [curr_sex_cd],
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
             N'2026-04-29T20:56:23.223',
             @superuser_id,
             N'PAT',
             N'M',
             N'2026-04-29T20:56:23.223',
             @superuser_id,
             @dbo_Person_local_id,
             N'ACTIVE',
             N'2026-04-29T20:56:23.223',
             N'A',
             N'2026-04-29T20:56:23.223',
             N'Covid',
             N'Patient',
             1,
             N'2026-04-29T00:00:00',
             N'2026-04-29T00:00:00',
             N'N',
             @dbo_Entity_entity_uid);

-- dbo.Person_name
-- step: 1
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
             [nm_use_cd],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid_2,
             1,
             N'2026-04-29T20:56:22.907',
             @superuser_id,
             N'Covid',
             N'C130',
             N'2026-04-29T20:56:22.907',
             @superuser_id,
             N'Patient',
             N'P353',
             N'L',
             N'ACTIVE',
             N'2026-04-29T20:56:22.907',
             N'A',
             N'2026-04-29T20:56:22.907',
             N'2026-04-29T00:00:00');

-- dbo.Person_race
-- step: 1
INSERT INTO [dbo].[person_race]
            ([person_uid],
             [race_cd],
             [add_time],
             [add_user_id],
             [race_category_cd],
             [record_status_cd],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid_2,
             N'2131-1',
             N'2026-04-29T20:56:22.907',
             @superuser_id,
             N'2131-1',
             N'ACTIVE',
             N'2026-04-29T00:00:00');

-- step: 1
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
             N'2026-04-29T20:56:22.907',
             @superuser_id,
             N'2106-3',
             N'ACTIVE',
             N'2026-04-29T00:00:00');

-- dbo.Postal_locator
-- step: 1
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
             N'2026-04-29T20:56:22.907',
             @superuser_id,
             N'Atlanta',
             N'840',
             N'13231',
             N'ACTIVE',
             N'2026-04-29T20:56:22.907',
             N'13',
             N'123 Second St',
             N'33033');

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
             N'2026-04-29T20:56:23.223',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-29T20:56:23.223',
             N'A',
             N'2026-04-29T20:56:23.223',
             N'H',
             1,
             N'2026-04-29T00:00:00');

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
             [rpt_source_cd],
             [status_cd],
             [transmission_mode_cd],
             [transmission_mode_desc_txt],
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
             N'2026-04-29T00:00:00',
             N'2026-04-29T20:56:23.277',
             @superuser_id,
             N'C',
             N'I',
             N'11065',
             N'2019 Novel Coronavirus',
             N'',
             N'',
             N'',
             N'',
             1,
             N'O',
             N'130005',
             N'2026-04-29T20:56:23.277',
             @superuser_id,
             @dbo_Public_health_case_local_id,
             N'17',
             N'2026',
             N'',
             N'',
             N'',
             N'GCD',
             N'OPEN',
             N'2026-04-29T20:56:23.277',
             N'',
             N'A',
             N'',
             N'',
             N'',
             1300500009,
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

-- dbo.Confirmation_method
-- step: 1
INSERT INTO [dbo].[confirmation_method]
            ([public_health_case_uid],
             [confirmation_method_cd],
             [confirmation_method_time])
VALUES      (@dbo_Act_act_uid,
             N'NA',
             N'2026-04-29T00:00:00');

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
             N'2026-04-29T20:56:23.310',
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
             N'2026-04-29T20:56:23.313',
             N'CITY');

-- step: 1
INSERT INTO [dbo].[act_id]
            ([act_uid],
             [act_id_seq],
             [root_extension_txt],
             [status_cd],
             [status_time],
             [type_cd])
VALUES      (@dbo_Act_act_uid,
             3,
             N'',
             N'A',
             N'2026-04-29T20:56:23.313',
             N'LEGACY');

-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [add_time],
             [add_user_id],
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
             N'2026-04-29T20:56:22.940',
             @superuser_id,
             N'2026-04-29T20:56:22.940',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-29T20:56:22.950',
             N'A',
             N'2026-04-29T20:56:22.950',
             N'PSN',
             N'Subject Of Public Health Case');

-- dbo.NBS_act_entity
-- step: 1
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
             N'2026-04-29T20:56:23.277',
             @superuser_id,
             @dbo_Entity_entity_uid_2,
             1,
             N'2026-04-29T20:56:23.277',
             @superuser_id,
             N'OPEN',
             N'2026-04-29T20:56:23.277',
             N'SubjOfPHC');

SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid = [value]
FROM   @dbo_NBS_act_entity_nbs_act_entity_uid_output;

-- dbo.Person
-- step: 1
UPDATE [dbo].[person]
SET    [last_chg_time] = N'2026-04-29T20:56:23.210',
       [record_status_time] = N'2026-04-29T20:56:23.210',
       [status_time] = N'2026-04-29T20:56:23.210',
       [version_ctrl_nbr] = Isnull([version_ctrl_nbr], 0) + 1
WHERE  [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 1
UPDATE [dbo].[entity_locator_participation]
SET    [last_chg_time] = N'2026-04-29T20:56:23.210',
       [record_status_time] = N'2026-04-29T20:56:23.210',
       [status_time] = N'2026-04-29T20:56:23.210'
WHERE  [entity_uid] = @dbo_Entity_entity_uid
       AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid;

-- dbo.PublicHealthCaseFact
-- step: 1
INSERT INTO [dbo].[publichealthcasefact]
            ([public_health_case_uid],
             [birth_gender_cd],
             [case_class_cd],
             [case_type_cd],
             [city_desc_txt],
             [confirmation_method_cd],
             [confirmation_method_time],
             [county],
             [cntry_cd],
             [cnty_cd],
             [curr_sex_cd],
             [elp_class_cd],
             [event_date],
             [event_type],
             [group_case_cnt],
             [investigation_status_cd],
             [jurisdiction_cd],
             [mart_record_creation_time],
             [mmwr_week],
             [mmwr_year],
             [par_type_cd],
             [postal_locator_uid],
             [person_cd],
             [person_uid],
             [phc_add_time],
             [phc_code],
             [phc_code_desc],
             [phc_code_short_desc],
             [prog_area_cd],
             [pst_record_status_time],
             [pst_record_status_cd],
             [race_concatenated_txt],
             [race_concatenated_desc_txt],
             [record_status_cd],
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
             [local_id],
             [birth_gender_desc_txt],
             [case_class_desc_txt],
             [cntry_desc_txt],
             [curr_sex_desc_txt],
             [investigation_status_desc_txt],
             [prog_area_desc_txt],
             [lastupdate])
VALUES      (@dbo_Act_act_uid,
             N'M',
             N'C',
             N'I',
             N'Atlanta',
             N'NA',
             N'2026-04-29T00:00:00',
             N'Pike County',
             N'840',
             N'13231',
             N'M',
             N'PST',
             N'2026-04-29T20:56:23.277',
             N'P',
             1.0,
             N'O',
             N'130005',
             N'2026-04-29T20:56:26.610',
             17,
             2026,
             N'SubjOfPHC',
             @dbo_Postal_locator_postal_locator_uid_2,
             N'PAT',
             @dbo_Entity_entity_uid_2,
             N'2026-04-29T20:56:23.277',
             N'11065',
             N'2019 Novel Coronavirus',
             N'2019 Novel Coronavirus',
             N'GCD',
             N'2026-04-29T20:56:22.907',
             N'ACTIVE',
             N'2106-3, 2131-1',
             N'White, Other Race',
             N'OPEN',
             N'T',
             N'Georgia',
             N'13',
             N'A',
             N'123 Second St',
             N'H',
             N'33033',
             N'Patient, Covid',
             N'Dekalb County',
             N'2026-04-29T00:00:00',
             1300500009,
             N'2026-04-29T20:56:23.277',
             10009283,
             @dbo_Person_local_id,
             N'2026-04-29T00:00:00',
             @dbo_Public_health_case_local_id,
             N'Male',
             N'Confirmed',
             N'UNITED STATES',
             N'Male',
             N'Open',
             N'GCD',
             N'2026-04-29T20:56:23.277');

-- dbo.SubjectRaceInfo
-- step: 1
INSERT INTO [dbo].[subjectraceinfo]
            ([morbreport_uid],
             [public_health_case_uid],
             [race_cd],
             [race_category_cd])
VALUES      (0,
             @dbo_Act_act_uid,
             N'2106-3',
             N'2106-3');

-- step: 1
INSERT INTO [dbo].[subjectraceinfo]
            ([morbreport_uid],
             [public_health_case_uid],
             [race_cd],
             [race_category_cd])
VALUES      (0,
             @dbo_Act_act_uid,
             N'2131-1',
             N'2131-1');

-- dbo.Act
-- step: 1
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_2,
             N'INTV',
             N'EVN');

-- dbo.Intervention
-- step: 1
INSERT INTO [dbo].[intervention]
            ([intervention_uid],
             [activity_from_time],
             [add_time],
             [add_user_id],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [effective_from_time],
             [last_chg_time],
             [last_chg_user_id],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [target_site_cd],
             [target_site_desc_txt],
             [shared_ind],
             [version_ctrl_nbr],
             [material_cd],
             [age_at_vacc],
             [age_at_vacc_unit_cd],
             [vacc_mfgr_cd],
             [material_lot_nm],
             [material_expiration_time],
             [vacc_dose_nbr],
             [vacc_info_source_cd],
             [electronic_ind])
VALUES      (@dbo_Act_act_uid_2,
             N'2026-04-29T00:00:00',
             N'2026-04-29T20:57:09.377',
             @superuser_id,
             N'VACADM',
             N'Vaccine Administration',
             N'NBS',
             N'NEDSS Base System',
             N'2026-04-29T00:00:00',
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             @dbo_Intervention_local_id,
             N'ACTIVE',
             N'2026-04-29T20:57:09.380',
             N'LA',
             N'Left Arm',
             N'T',
             1,
             N'207',
             22,
             N'Y',
             N'AKR',
             N'11111111',
             N'2026-04-30T00:00:00',
             1,
             N'9',
             N'N');

-- dbo.Entity
-- step: 1
INSERT INTO [dbo].[entity]
            ([entity_uid],
             [class_cd])
VALUES      (@dbo_Entity_entity_uid_3,
             N'PSN');

-- dbo.Person
-- step: 1
INSERT INTO [dbo].[person]
            ([person_uid],
             [add_time],
             [add_user_id],
             [cd],
             [curr_sex_cd],
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
VALUES      (@dbo_Entity_entity_uid_3,
             N'2026-04-29T20:57:09.590',
             @superuser_id,
             N'PAT',
             N'M',
             N'2026-04-29T20:57:09.590',
             @superuser_id,
             @dbo_Person_local_id,
             N'ACTIVE',
             N'2026-04-29T20:57:09.590',
             N'A',
             N'2026-04-29T20:57:09.590',
             N'Covid',
             N'Patient',
             1,
             N'2026-04-29T00:00:00',
             N'2026-04-29T00:00:00',
             N'N',
             @dbo_Entity_entity_uid);

-- dbo.Person_name
-- step: 1
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
             [nm_use_cd],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid_3,
             1,
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'Covid',
             N'C130',
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'Patient',
             N'P353',
             N'L',
             N'ACTIVE',
             N'2026-04-29T20:57:09.380',
             N'A',
             N'2026-04-29T20:57:09.380',
             N'2026-04-29T00:00:00');

-- dbo.Person_race
-- step: 1
INSERT INTO [dbo].[person_race]
            ([person_uid],
             [race_cd],
             [add_time],
             [add_user_id],
             [race_category_cd],
             [record_status_cd],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid_3,
             N'2131-1',
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'2131-1',
             N'ACTIVE',
             N'2026-04-29T00:00:00');

-- step: 1
INSERT INTO [dbo].[person_race]
            ([person_uid],
             [race_cd],
             [add_time],
             [add_user_id],
             [race_category_cd],
             [record_status_cd],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid_3,
             N'2106-3',
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'2106-3',
             N'ACTIVE',
             N'2026-04-29T00:00:00');

-- dbo.Postal_locator
-- step: 1
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
VALUES      (@dbo_Postal_locator_postal_locator_uid_3,
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'Atlanta',
             N'840',
             N'13231',
             N'ACTIVE',
             N'2026-04-29T20:57:09.380',
             N'13',
             N'123 Second St',
             N'33033');

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
VALUES      (@dbo_Entity_entity_uid_3,
             @dbo_Postal_locator_postal_locator_uid_3,
             N'H',
             N'PST',
             N'2026-04-29T20:57:09.590',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-29T20:57:09.590',
             N'A',
             N'2026-04-29T20:57:09.590',
             N'H',
             1,
             N'2026-04-29T00:00:00');

-- dbo.NBS_act_entity
-- step: 1
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
VALUES      (@dbo_Act_act_uid_2,
             N'2026-04-29T20:57:09.377',
             @superuser_id,
             @dbo_Entity_entity_uid_3,
             1,
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-29T20:57:09.380',
             N'SubOfVacc');

SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_2 = [value]
FROM   @dbo_NBS_act_entity_nbs_act_entity_uid_2_output;

-- step: 1
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
VALUES      (@dbo_Act_act_uid_2,
             N'2026-04-29T20:57:09.377',
             @superuser_id,
             10003001,
             2,
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-29T20:57:09.380',
             N'PerformerOfVacc');

SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_3 = [value]
FROM   @dbo_NBS_act_entity_nbs_act_entity_uid_3_output;

-- step: 1
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
VALUES      (@dbo_Act_act_uid_2,
             N'2026-04-29T20:57:09.377',
             @superuser_id,
             10003010,
             1,
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-29T20:57:09.380',
             N'PerformerOfVacc');

SELECT TOP 1 @dbo_NBS_act_entity_nbs_act_entity_uid_4 = [value]
FROM   @dbo_NBS_act_entity_nbs_act_entity_uid_4_output;

-- dbo.Participation
-- step: 1
INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [add_time],
             [add_user_id],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (@dbo_Entity_entity_uid_3,
             @dbo_Act_act_uid_2,
             N'SubOfVacc',
             N'INTV',
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-29T20:57:09.380',
             N'A',
             N'2026-04-29T20:57:09.380',
             N'PAT',
             N'Subject Of Vaccination');

-- step: 1
INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [add_time],
             [add_user_id],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (10003001,
             @dbo_Act_act_uid_2,
             N'PerformerOfVacc',
             N'INTV',
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-29T20:57:09.380',
             N'A',
             N'2026-04-29T20:57:09.380',
             N'ORG',
             N'Vaccination Performer');

-- step: 1
INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [add_time],
             [add_user_id],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (10003010,
             @dbo_Act_act_uid_2,
             N'PerformerOfVacc',
             N'INTV',
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'2026-04-29T20:57:09.380',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-29T20:57:09.380',
             N'A',
             N'2026-04-29T20:57:09.380',
             N'PSN',
             N'Vaccination Performer');

-- dbo.Act_relationship
-- step: 1
INSERT INTO [dbo].[act_relationship]
            ([target_act_uid],
             [source_act_uid],
             [type_cd],
             [add_time],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [source_class_cd],
             [status_cd],
             [status_time],
             [target_class_cd])
VALUES      (@dbo_Act_act_uid,
             @dbo_Act_act_uid_2,
             N'1180',
             N'2026-04-29T20:57:09.663',
             N'2026-04-29T20:57:09.663',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-29T20:57:09.663',
             N'INTV',
             N'A',
             N'2026-04-29T20:57:09.663',
             N'CASE');

-- dbo.Person
-- step: 1
UPDATE [dbo].[person]
SET    [last_chg_time] = N'2026-04-29T20:57:09.577',
       [record_status_time] = N'2026-04-29T20:57:09.577',
       [status_time] = N'2026-04-29T20:57:09.577',
       [version_ctrl_nbr] = Isnull([version_ctrl_nbr], 0) + 1
WHERE  [person_uid] = @dbo_Entity_entity_uid;

-- dbo.Entity_locator_participation
-- step: 1
UPDATE [dbo].[entity_locator_participation]
SET    [last_chg_time] = N'2026-04-29T20:57:09.577',
       [record_status_time] = N'2026-04-29T20:57:09.577',
       [status_time] = N'2026-04-29T20:57:09.577'
WHERE  [entity_uid] = @dbo_Entity_entity_uid
       AND [locator_uid] = @dbo_Postal_locator_postal_locator_uid; 