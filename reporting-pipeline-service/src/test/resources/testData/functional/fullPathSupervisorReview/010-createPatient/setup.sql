USE [NBS_ODSE];

DECLARE @local_user_id BIGINT = 10007004;
-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid BIGINT = 20100400;
DECLARE @dbo_Postal_locator_postal_locator_uid BIGINT = 20100401;
DECLARE @dbo_Tele_locator_tele_locator_uid BIGINT = 20100402;
DECLARE @dbo_Tele_locator_tele_locator_uid_2 BIGINT = 20100403;
DECLARE @dbo_Person_local_id NVARCHAR(40) = N'PSN20100400GA01';

-- STEP 1: CreatePatient
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
             [middle_nm],
             [version_ctrl_nbr],
             [as_of_date_admin],
             [as_of_date_ethnicity],
             [as_of_date_general],
             [as_of_date_morbidity],
             [as_of_date_sex],
             [electronic_ind],
             [person_parent_uid],
             [edx_ind])
VALUES      (@dbo_Entity_entity_uid,
             N'2026-04-22T20:44:33.130',
             @local_user_id,
             N'M',
             N'1964-01-30T00:00:00',
             N'1964-01-30T00:00:00',
             N'PAT',
             N'M',
             N'N',
             N'2186-5',
             N'2026-04-22T20:44:33.130',
             @local_user_id,
             @dbo_Person_local_id,
             N'M',
             N'ACTIVE',
             N'2026-04-22T20:44:33.130',
             N'A',
             N'2026-04-22T20:44:33.130',
             N'Richard',
             N'Wells',
             N'D',
             1,
             N'2026-04-22T00:00:00',
             N'2026-04-22T00:00:00',
             N'2026-04-22T00:00:00',
             N'2026-04-22T00:00:00',
             N'2026-04-22T00:00:00',
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
             [middle_nm],
             [nm_use_cd],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid,
             1,
             N'Add',
             N'2026-04-22T20:44:33.037',
             N'Richard',
             N'R263',
             N'Wells',
             N'W420',
             N'D',
             N'L',
             N'ACTIVE',
             N'2026-04-22T20:44:33.037',
             N'A',
             N'2026-04-22T20:44:33.037',
             N'2026-04-22T00:00:00');

-- dbo.Person_name 2
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
             [middle_nm],
             [nm_use_cd],
             [record_status_cd],
             [record_status_time],
             [status_cd],
             [status_time],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid,
             2,
             N'Add',
             N'2026-04-22T20:44:33.037',
             N'Rich',
             N'R263',
             N'Wells',
             N'W420',
             N'D',
             N'A',
             N'ACTIVE',
             N'2026-04-22T20:44:33.037',
             N'A',
             N'2026-04-22T20:44:33.037',
             N'2026-04-22T00:00:00');

-- dbo.Person_race
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
             N'2026-04-22T20:44:33.060',
             N'2106-3',
             N'ACTIVE',
             N'2026-04-22T00:00:00');

-- dbo.Entity_id
-- step: 1
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
VALUES      (@dbo_Entity_entity_uid,
             1,
             N'2026-04-22T20:44:33.037',
             N'GA',
             N'GA',
             N'2026-04-22T20:44:33.037',
             N'ACTIVE',
             N'2026-04-22T20:44:33.037',
             N'111100000',
             N'A',
             N'2026-04-22T20:44:33.037',
             N'DL',
             N'Driver''s license number',
             N'2026-04-22T00:00:00',
             N'L');

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
             N'2026-04-22T20:44:33.060',
             N'Atlanta',
             N'840',
             N'13121',
             N'ACTIVE',
             N'2026-04-22T20:44:33.060',
             N'13',
             N'174 Neuport Drive',
             N'',
             N'30338');

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
             N'2026-04-22T20:44:33.130',
             @local_user_id,
             N'ACTIVE',
             N'2026-04-22T20:44:33.130',
             N'A',
             N'2026-04-22T20:44:33.130',
             N'H',
             1,
             N'2026-04-22T00:00:00');

-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[tele_locator]
            ([tele_locator_uid],
             [add_time],
             [add_user_id],
             [phone_nbr_txt],
             [record_status_cd])
VALUES      (@dbo_Tele_locator_tele_locator_uid,
             N'2026-04-22T20:44:33.060',
             @local_user_id,
             N'707-555-1111',
             N'ACTIVE');

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
             @dbo_Tele_locator_tele_locator_uid,
             N'PH',
             N'TELE',
             N'2026-04-22T20:44:33.130',
             @local_user_id,
             N'ACTIVE',
             N'2026-04-22T20:44:33.130',
             N'A',
             N'2026-04-22T20:44:33.130',
             N'H',
             1,
             N'2026-04-22T00:00:00');

-- dbo.Tele_locator
-- step: 1
INSERT INTO [dbo].[tele_locator]
            ([tele_locator_uid],
             [add_time],
             [add_user_id],
             [extension_txt],
             [phone_nbr_txt],
             [record_status_cd])
VALUES      (@dbo_Tele_locator_tele_locator_uid_2,
             N'2026-04-22T20:44:33.060',
             @local_user_id,
             N'',
             N'707-454-1212',
             N'ACTIVE');

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
             @dbo_Tele_locator_tele_locator_uid_2,
             N'PH',
             N'TELE',
             N'2026-04-22T20:44:33.130',
             @local_user_id,
             N'ACTIVE',
             N'2026-04-22T20:44:33.130',
             N'A',
             N'2026-04-22T20:44:33.130',
             N'WP',
             1,
             N'2026-04-22T00:00:00'); 