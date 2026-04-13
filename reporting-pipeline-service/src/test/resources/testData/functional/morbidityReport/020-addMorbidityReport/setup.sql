USE [NBS_ODSE]
DECLARE @superuser_id bigint = 10009282

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 20100010
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 20100011
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 20100012
DECLARE @dbo_Act_act_uid bigint = 20100013
DECLARE @dbo_Act_act_uid_2 bigint = 20100014
DECLARE @dbo_Act_act_uid_3 bigint = 20100015
DECLARE @dbo_Act_act_uid_4 bigint = 20100016
DECLARE @dbo_Act_act_uid_5 bigint = 20100017
DECLARE @dbo_Act_act_uid_6 bigint = 20100018
DECLARE @dbo_Act_act_uid_7 bigint = 20100019
DECLARE @dbo_Act_act_uid_8 bigint = 20100020
DECLARE @dbo_Act_act_uid_9 bigint = 20100021
DECLARE @dbo_Act_act_uid_10 bigint = 20100022
DECLARE @dbo_Act_act_uid_11 bigint = 20100023
DECLARE @dbo_Act_act_uid_12 bigint = 20100024
DECLARE @dbo_Act_act_uid_13 bigint = 20100025
DECLARE @dbo_Act_act_uid_14 bigint = 20100026
DECLARE @dbo_Act_act_uid_15 bigint = 20100027
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN20100000GA01'

-- dbo.Entity
INSERT INTO [dbo].[entity]
            ([entity_uid],
             [class_cd])
VALUES      (@dbo_Entity_entity_uid,
             N'PSN')

-- dbo.Person
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
             [as_of_date_general],
             [as_of_date_morbidity],
             [as_of_date_sex],
             [electronic_ind],
             [person_parent_uid])
VALUES      (@dbo_Entity_entity_uid,
             N'2026-04-10T20:26:11.770',
             @superuser_id,
             N'41',
             N'Y',
             N'1985-03-17T00:00:00',
             N'1985-03-17T00:00:00',
             N'PAT',
             N'F',
             N'N',
             N'2026-04-10T20:26:11.770',
             @superuser_id,
             @dbo_Person_local_id,
             N'M',
             N'ACTIVE',
             N'2026-04-10T20:26:11.770',
             N'A',
             N'2026-04-10T20:26:11.770',
             N'Marie',
             N'Ball',
             1,
             N'2026-04-10T00:00:00',
             N'2026-04-10T00:00:00',
             N'2026-04-10T00:00:00',
             N'N',
             20100000)

-- dbo.Person_name
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
             N'2026-04-10T20:26:11.673',
             N'Marie',
             N'T460',
             N'Ball',
             N'S130',
             N'L',
             N'ACTIVE',
             N'2026-04-10T20:26:11.673',
             N'A',
             N'2026-04-10T20:26:11.673',
             N'2026-04-10T00:00:00')

-- dbo.Person_race
INSERT INTO [dbo].[person_race]
            ([person_uid],
             [race_cd],
             [race_category_cd],
             [record_status_cd],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid,
             N'2106-3',
             N'2106-3',
             N'ACTIVE',
             N'2026-04-10T00:00:00')

-- dbo.Entity_id
INSERT INTO [dbo].[entity_id]
            ([entity_uid],
             [entity_id_seq],
             [add_time],
             [assigning_authority_cd],
             [last_chg_time],
             [record_status_cd],
             [record_status_time],
             [root_extension_txt],
             [status_cd],
             [status_time],
             [type_cd],
             [type_desc_txt],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid,
             1,
             N'2026-04-10T20:26:11.673',
             N'GA',
             N'2026-04-10T20:26:11.673',
             N'ACTIVE',
             N'2026-04-10T20:26:11.673',
             N'123987456',
             N'A',
             N'2026-04-10T20:26:11.673',
             N'DL',
             N'Driver''s license number',
             N'2026-04-10T00:00:00')

-- dbo.Postal_locator
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
             N'2026-04-10T20:26:11.673',
             N'Atlanta',
             N'840',
             N'13121',
             N'ACTIVE',
             N'2026-04-10T20:26:11.673',
             N'13',
             N'1313 Pine Way',
             N'',
             N'30033')

-- dbo.Entity_locator_participation
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
             N'2026-04-10T20:26:11.783',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.783',
             N'A',
             N'2026-04-10T20:26:11.783',
             N'H',
             1,
             N'2026-04-10T00:00:00')

-- dbo.Tele_locator
INSERT INTO [dbo].[tele_locator]
            ([tele_locator_uid],
             [add_time],
             [extension_txt],
             [phone_nbr_txt],
             [record_status_cd])
VALUES      (@dbo_Tele_locator_tele_locator_uid,
             N'2026-04-10T20:26:11.673',
             N'',
             N'201-555-1212',
             N'ACTIVE')

-- dbo.Entity_locator_participation
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
             @dbo_Tele_locator_tele_locator_uid,
             N'PH',
             N'TELE',
             N'2026-04-10T20:26:11.783',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.783',
             N'A',
             N'2026-04-10T20:26:11.783',
             N'H',
             1,
             N'2026-04-10T00:00:00')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid,
             N'MRB100',
             N'* Morbidity Report Type ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_coded
INSERT INTO [dbo].[obs_value_coded]
            ([observation_uid],
             [code])
VALUES      (@dbo_Act_act_uid,
             N'INIT')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_2,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_2 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_2)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid_2,
             N'MRB122',
             N'Date of Onset ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id_2,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_date
INSERT INTO [dbo].[obs_value_date]
            ([observation_uid],
             [obs_value_date_seq],
             [from_time])
VALUES      (@dbo_Act_act_uid_2,
             1,
             N'2026-04-02T00:00:00')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_3,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_3 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_3)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid_3,
             N'MRB165',
             N'Date of Diagnosis ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id_3,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_date
INSERT INTO [dbo].[obs_value_date]
            ([observation_uid],
             [obs_value_date_seq],
             [from_time])
VALUES      (@dbo_Act_act_uid_3,
             1,
             N'2026-04-05T00:00:00')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_4,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_4 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_4)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid_4,
             N'INV145',
             N'Did patient die from this illness? ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id_4,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_coded
INSERT INTO [dbo].[obs_value_coded]
            ([observation_uid],
             [code])
VALUES      (@dbo_Act_act_uid_4,
             N'Y')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_5,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_5 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_5)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid_5,
             N'INV128',
             N'Was the patient hospitalized for this illness? ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id_5,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_coded
INSERT INTO [dbo].[obs_value_coded]
            ([observation_uid],
             [code])
VALUES      (@dbo_Act_act_uid_5,
             N'Y')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_6,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_6 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_6)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid_6,
             N'MRB166',
             N'Admission Date ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id_6,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_date
INSERT INTO [dbo].[obs_value_date]
            ([observation_uid],
             [obs_value_date_seq],
             [from_time])
VALUES      (@dbo_Act_act_uid_6,
             1,
             N'2026-04-03T00:00:00')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_7,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_7 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_7)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid_7,
             N'MRB167',
             N'Discharge Date ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id_7,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_date
INSERT INTO [dbo].[obs_value_date]
            ([observation_uid],
             [obs_value_date_seq],
             [from_time])
VALUES      (@dbo_Act_act_uid_7,
             1,
             N'2026-04-09T00:00:00')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_8,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_8 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_8)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid_8,
             N'INV178',
             N'Pregnant ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id_8,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_coded
INSERT INTO [dbo].[obs_value_coded]
            ([observation_uid],
             [code])
VALUES      (@dbo_Act_act_uid_8,
             N'Y')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_9,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_9 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_9)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid_9,
             N'INV149',
             N'Food Handler ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id_9,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_coded
INSERT INTO [dbo].[obs_value_coded]
            ([observation_uid],
             [code])
VALUES      (@dbo_Act_act_uid_9,
             N'N')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_10,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_10 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_10)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid_10,
             N'INV148',
             N'Associated with Day Care Facility ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id_10,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_coded
INSERT INTO [dbo].[obs_value_coded]
            ([observation_uid],
             [code])
VALUES      (@dbo_Act_act_uid_10,
             N'N')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_11,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_11 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_11)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid_11,
             N'MRB129',
             N'Affiliated with Nursing Home ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id_11,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_coded
INSERT INTO [dbo].[obs_value_coded]
            ([observation_uid],
             [code])
VALUES      (@dbo_Act_act_uid_11,
             N'Y')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_12,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_12 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_12)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid_12,
             N'MRB130',
             N'Affiliated with Health Care Organization ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id_12,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_coded
INSERT INTO [dbo].[obs_value_coded]
            ([observation_uid],
             [code])
VALUES      (@dbo_Act_act_uid_12,
             N'UNK')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_13,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_13 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_13)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid_13,
             N'MRB168',
             N'Suspected Food or Waterborne Illness ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id_13,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_coded
INSERT INTO [dbo].[obs_value_coded]
            ([observation_uid],
             [code])
VALUES      (@dbo_Act_act_uid_13,
             N'N')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_14,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_14 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_14)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [local_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [cd_version])
VALUES      (@dbo_Act_act_uid_14,
             N'MRB169',
             N'Other, specify ',
             N'NBS',
             N'NEDSS Base System',
             @dbo_Observation_local_id_14,
             N'ACTIVE',
             N'2026-04-10T20:26:11.670',
             N'D',
             N'2026-04-10T20:26:11.670',
             4,
             N'T',
             1,
             N'1.0')

-- dbo.Obs_value_txt
INSERT INTO [dbo].[obs_value_txt]
            ([observation_uid],
             [obs_value_txt_seq],
             [value_txt],
             [value_large_txt])
VALUES      (@dbo_Act_act_uid_14,
             1,
             N'other something',
             N'other something')

-- dbo.Act
INSERT INTO [dbo].[act]
            ([act_uid],
             [class_cd],
             [mood_cd])
VALUES      (@dbo_Act_act_uid_15,
             N'OBS',
             N'EVN')

-- dbo.Observation
DECLARE @dbo_Observation_local_id_15 NVARCHAR(40) = N'OBS'
  + CONVERT(NVARCHAR(20), Abs(CONVERT(BIGINT, @dbo_Act_act_uid_15)))
  + N'GA01'

INSERT INTO [dbo].[observation]
            ([observation_uid],
             [activity_to_time],
             [add_time],
             [add_user_id],
             [cd],
             [cd_desc_txt],
             [cd_system_cd],
             [cd_system_desc_txt],
             [ctrl_cd_display_form],
             [electronic_ind],
             [jurisdiction_cd],
             [lab_condition_cd],
             [last_chg_time],
             [last_chg_user_id],
             [local_id],
             [obs_domain_cd_st_1],
             [prog_area_cd],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [program_jurisdiction_oid],
             [shared_ind],
             [version_ctrl_nbr],
             [rpt_to_state_time],
             [cd_version],
             [pregnant_week])
VALUES      (@dbo_Act_act_uid_15,
             N'2026-04-09T00:00:00',
             N'2026-04-10T20:26:11.853',
             @superuser_id,
             N'50265',
             N'Condition',
             N'NBS',
             N'NEDSS Base System',
             N'MorbReport',
             N'N',
             N'130001',
             N'',
             N'2026-04-10T20:26:11.853',
             @superuser_id,
             @dbo_Observation_local_id_15,
             N'Order',
             N'GCD',
             N'UNPROCESSED',
             N'2026-04-10T20:26:11.853',
             N'D',
             N'2026-04-10T20:26:11.670',
             1300100009,
             N'T',
             1,
             N'2026-04-10T00:00:00',
             N'1.0',
             15)

-- dbo.Participation
INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (@dbo_Entity_entity_uid,
             @dbo_Act_act_uid_15,
             N'SubjOfMorbReport',
             N'OBS',
             N'2026-04-10T20:26:11.943',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.943',
             N'A',
             N'2026-04-10T20:26:11.943',
             N'PSN',
             N'Subject Of Morbidity Report')

INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (10003013,
             @dbo_Act_act_uid_15,
             N'ReporterOfMorbReport',
             N'OBS',
             N'2026-04-10T20:26:11.953',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.953',
             N'A',
             N'2026-04-10T20:26:11.953',
             N'PSN',
             N'Reporter Of Morbidity Report')

INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (10003010,
             @dbo_Act_act_uid_15,
             N'PhysicianOfMorb',
             N'OBS',
             N'2026-04-10T20:26:11.953',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.953',
             N'A',
             N'2026-04-10T20:26:11.953',
             N'PSN',
             N'Physician Of Morbidity Report')

INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (10003001,
             @dbo_Act_act_uid_15,
             N'ReporterOfMorbReport',
             N'OBS',
             N'2026-04-10T20:26:11.957',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.957',
             N'A',
             N'2026-04-10T20:26:11.957',
             N'ORG',
             N'Reporter Of Morbidity Report')

INSERT INTO [dbo].[participation]
            ([subject_entity_uid],
             [act_uid],
             [type_cd],
             [act_class_cd],
             [last_chg_time],
             [last_chg_user_id],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [subject_class_cd],
             [type_desc_txt])
VALUES      (10003007,
             @dbo_Act_act_uid_15,
             N'HospOfMorbObs',
             N'OBS',
             N'2026-04-10T20:26:11.957',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.957',
             N'A',
             N'2026-04-10T20:26:11.957',
             N'ORG',
             N'Hospital Of Morbidity Report')

-- dbo.Act_relationship
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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.957',
             N'2026-04-10T20:26:11.957',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.957',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.957',
             N'OBS')

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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid_2,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.963',
             N'2026-04-10T20:26:11.963',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.963',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.963',
             N'OBS')

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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid_3,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.963',
             N'2026-04-10T20:26:11.963',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.963',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.963',
             N'OBS')

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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid_4,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.963',
             N'2026-04-10T20:26:11.963',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.963',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.963',
             N'OBS')

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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid_5,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.963',
             N'2026-04-10T20:26:11.963',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.963',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.963',
             N'OBS')

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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid_6,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.967',
             N'2026-04-10T20:26:11.967',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.967',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.967',
             N'OBS')

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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid_7,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.967',
             N'2026-04-10T20:26:11.967',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.967',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.967',
             N'OBS')

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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid_8,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.967',
             N'2026-04-10T20:26:11.967',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.967',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.967',
             N'OBS')

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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid_9,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.967',
             N'2026-04-10T20:26:11.967',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.967',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.967',
             N'OBS')

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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid_10,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.967',
             N'2026-04-10T20:26:11.967',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.967',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.967',
             N'OBS')

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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid_11,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.967',
             N'2026-04-10T20:26:11.967',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.967',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.967',
             N'OBS')

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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid_12,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.967',
             N'2026-04-10T20:26:11.967',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.967',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.967',
             N'OBS')

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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid_13,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.967',
             N'2026-04-10T20:26:11.967',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.967',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.967',
             N'OBS')

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
VALUES      (@dbo_Act_act_uid_15,
             @dbo_Act_act_uid_14,
             N'MorbFrmQ',
             N'2026-04-10T20:26:11.967',
             N'2026-04-10T20:26:11.967',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:26:11.967',
             N'OBS',
             N'A',
             N'2026-04-10T20:26:11.967',
             N'OBS')

-- dbo.Person
UPDATE [dbo].[person]
SET    [last_chg_time] = N'2026-04-10T20:26:11.770',
       [record_status_time] = N'2026-04-10T20:26:11.770',
       [status_time] = N'2026-04-10T20:26:11.770',
       [version_ctrl_nbr] = Isnull([version_ctrl_nbr], 0) + 1
WHERE  [person_uid] = 20100000

-- dbo.Entity_locator_participation
UPDATE [dbo].[entity_locator_participation]
SET    [last_chg_time] = N'2026-04-10T20:26:11.770',
       [record_status_time] = N'2026-04-10T20:26:11.770',
       [status_time] = N'2026-04-10T20:26:11.770'
WHERE  [entity_uid] = 20100000
       AND [locator_uid] = 20100001

UPDATE [dbo].[entity_locator_participation]
SET    [last_chg_time] = N'2026-04-10T20:26:11.770',
       [record_status_time] = N'2026-04-10T20:26:11.770',
       [status_time] = N'2026-04-10T20:26:11.770'
WHERE  [entity_uid] = 20100000
       AND [locator_uid] = 20100002

UPDATE [dbo].[entity_locator_participation]
SET    [last_chg_time] = N'2026-04-10T20:26:11.770',
       [record_status_time] = N'2026-04-10T20:26:11.770',
       [status_time] = N'2026-04-10T20:26:11.770'
WHERE  [entity_uid] = 20100000
       AND [locator_uid] = 20100003 