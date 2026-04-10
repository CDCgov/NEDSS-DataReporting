USE [NBS_ODSE]
DECLARE @superuser_id bigint = 10009282

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 20100000
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 20100001
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 20100002
DECLARE @dbo_Tele_locator_tele_locator_uid_2 bigint = 20100003
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
             [birth_gender_cd],
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
             [as_of_date_admin],
             [as_of_date_general],
             [as_of_date_morbidity],
             [as_of_date_sex],
             [electronic_ind],
             [person_parent_uid],
             [edx_ind])
VALUES      (@dbo_Entity_entity_uid,
             N'2026-04-10T20:21:26.800',
             @superuser_id,
             N'F',
             N'1985-03-17T00:00:00',
             N'1985-03-17T00:00:00',
             N'PAT',
             N'F',
             N'N',
             N'2026-04-10T20:21:26.800',
             @superuser_id,
             @dbo_Person_local_id,
             N'M',
             N'ACTIVE',
             N'2026-04-10T20:21:26.800',
             N'A',
             N'2026-04-10T20:21:26.800',
             N'Marie',
             N'Ball',
             1,
             N'2026-04-10T00:00:00',
             N'2026-04-10T00:00:00',
             N'2026-04-10T00:00:00',
             N'2026-04-10T00:00:00',
             N'N',
             @dbo_Entity_entity_uid,
             N'Y')

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
             N'2026-04-10T20:21:26.690',
             N'Marie',
             N'T460',
             N'Ball',
             N'S130',
             N'L',
             N'ACTIVE',
             N'2026-04-10T20:21:26.690',
             N'A',
             N'2026-04-10T20:21:26.690',
             N'2026-04-10T00:00:00')

-- dbo.Person_race
INSERT INTO [dbo].[person_race]
            ([person_uid],
             [race_cd],
             [add_time],
             [race_category_cd],
             [record_status_cd],
             [as_of_date])
VALUES      (@dbo_Entity_entity_uid,
             N'2106-3',
             N'2026-04-10T20:21:26.717',
             N'2106-3',
             N'ACTIVE',
             N'2026-04-10T00:00:00')

-- dbo.Entity_id
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
             N'2026-04-10T20:21:26.690',
             N'GA',
             N'GA',
             N'2026-04-10T20:21:26.690',
             N'ACTIVE',
             N'2026-04-10T20:21:26.690',
             N'123987456',
             N'A',
             N'2026-04-10T20:21:26.690',
             N'DL',
             N'Driver''s license number',
             N'2026-04-10T00:00:00',
             N'L')

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
             N'2026-04-10T20:21:26.717',
             N'Atlanta',
             N'840',
             N'13121',
             N'ACTIVE',
             N'2026-04-10T20:21:26.717',
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
             N'2026-04-10T20:21:26.800',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:21:26.800',
             N'A',
             N'2026-04-10T20:21:26.800',
             N'H',
             1,
             N'2026-04-10T00:00:00')

-- dbo.Tele_locator
INSERT INTO [dbo].[tele_locator]
            ([tele_locator_uid],
             [add_time],
             [add_user_id],
             [phone_nbr_txt],
             [record_status_cd])
VALUES      (@dbo_Tele_locator_tele_locator_uid,
             N'2026-04-10T20:21:26.717',
             @superuser_id,
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
             N'2026-04-10T20:21:26.800',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:21:26.800',
             N'A',
             N'2026-04-10T20:21:26.800',
             N'H',
             1,
             N'2026-04-10T00:00:00')

-- dbo.Tele_locator
INSERT INTO [dbo].[tele_locator]
            ([tele_locator_uid],
             [add_time],
             [add_user_id],
             [email_address],
             [record_status_cd])
VALUES      (@dbo_Tele_locator_tele_locator_uid_2,
             N'2026-04-10T20:21:26.717',
             @superuser_id,
             N'Marie@example.com',
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
             @dbo_Tele_locator_tele_locator_uid_2,
             N'NET',
             N'TELE',
             N'2026-04-10T20:21:26.800',
             @superuser_id,
             N'ACTIVE',
             N'2026-04-10T20:21:26.800',
             N'A',
             N'2026-04-10T20:21:26.800',
             N'H',
             1,
             N'2026-04-10T00:00:00') 