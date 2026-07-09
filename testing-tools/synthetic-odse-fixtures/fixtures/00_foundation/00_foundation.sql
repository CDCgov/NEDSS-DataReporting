USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 0 Foundation fixture
-- Baseline: 6.0.18.1 (post-liquibase)
-- Single canonical instance of each parent entity. No SP execution.
-- No cross-subject act_relationship / participation / nbs_act_entity rows.
-- All UIDs are allocated within Tier 0 block 20000000 - 20009999.
-- See testing-tools/synthetic-odse-fixtures/catalog/uid_ranges.md for the registry.
-- =====================================================================

-- ----- Sentinel reference (do not allocate — assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id (soft reference; auth_user.user_id is varchar)

-- ----- Patient: Entity + Person (+address, phone) -----
DECLARE @dbo_Entity_patient_uid       bigint = 20000000;   -- Patient entity_uid / person_uid / person_parent_uid
DECLARE @dbo_Postal_locator_patient   bigint = 20000001;   -- Patient home postal_locator_uid
DECLARE @dbo_Tele_locator_patient     bigint = 20000002;   -- Patient home tele_locator_uid

-- ----- Provider: Entity + Person (+address, phone) -----
DECLARE @dbo_Entity_provider_uid      bigint = 20000010;   -- Provider entity_uid / person_uid / person_parent_uid
DECLARE @dbo_Postal_locator_provider  bigint = 20000011;   -- Provider work postal_locator_uid
DECLARE @dbo_Tele_locator_provider    bigint = 20000012;   -- Provider work tele_locator_uid

-- ----- Organization: Entity + Organization (+address) -----
DECLARE @dbo_Entity_organization_uid  bigint = 20000020;   -- Organization entity_uid / organization_uid
DECLARE @dbo_Postal_locator_org       bigint = 20000021;   -- Organization work postal_locator_uid
DECLARE @dbo_Tele_locator_org         bigint = 20000022;   -- Organization work tele_locator_uid

-- ----- Place: Entity + Place (+address) -----
DECLARE @dbo_Entity_place_uid         bigint = 20000030;   -- Place entity_uid / place_uid
DECLARE @dbo_Postal_locator_place     bigint = 20000031;   -- Place postal_locator_uid

-- ----- Acts (one per canonical subject act-bearing entity) -----
DECLARE @dbo_Act_investigation_uid    bigint = 20000100;   -- Investigation: Act + Public_health_case
DECLARE @dbo_Act_notification_uid     bigint = 20000110;   -- Notification: Act + Notification
DECLARE @dbo_Act_lab_uid              bigint = 20000120;   -- Lab Report: Act + Observation (obs_domain_cd_st_1='Order')
DECLARE @dbo_Act_morbidity_uid        bigint = 20000130;   -- Morbidity Report: Act + Observation
DECLARE @dbo_Act_interview_uid        bigint = 20000140;   -- Interview: Act + Interview
DECLARE @dbo_Act_treatment_uid        bigint = 20000150;   -- Treatment: Act + Treatment
DECLARE @dbo_Act_vaccination_uid      bigint = 20000160;   -- Vaccination: Act + Intervention
DECLARE @dbo_Act_contact_uid          bigint = 20000170;   -- Contact Record: Act + CT_contact

-- =====================================================================
-- ENTITIES (Patient, Provider, Organization, Place)
-- entity.class_cd values from SRTE code_set_nm='ENTITY_CLS': PSN, ORG, PLC.
-- =====================================================================
INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
    (@dbo_Entity_patient_uid,      N'PSN'),
    (@dbo_Entity_provider_uid,     N'PSN'),
    (@dbo_Entity_organization_uid, N'ORG'),
    (@dbo_Entity_place_uid,        N'PLC');

-- =====================================================================
-- PATIENT person row
-- person.cd: 'PAT' from SRTE code_set_nm='P_TYPE'.
-- =====================================================================
INSERT INTO [dbo].[person]
    ([person_uid], [add_time], [add_user_id], [administrative_gender_cd],
     [birth_gender_cd], [birth_time], [cd], [curr_sex_cd], [deceased_ind_cd],
     [ethnic_group_ind], [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_general],
     [electronic_ind], [person_parent_uid], [edx_ind])
VALUES
    (@dbo_Entity_patient_uid, '2026-04-01T00:00:00', @superuser_id, N'M',
     N'M', '1990-01-15T00:00:00', N'PAT', N'M', N'N',
     N'2186-5', CAST(GETDATE() AS DATE), @superuser_id, N'PSN20000000GA01',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'Raymond', N'Foster', 1, '2026-04-01T00:00:00',
     N'N', @dbo_Entity_patient_uid, N'Y');

-- Patient person_name (status_cd / status_time are NOT NULL on this table).
INSERT INTO [dbo].[person_name]
    ([person_uid], [person_name_seq], [add_time], [add_user_id],
     [first_nm], [last_nm], [nm_use_cd],
     [record_status_cd], [record_status_time], [status_cd], [status_time])
VALUES
    (@dbo_Entity_patient_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'Raymond', N'Foster', N'L',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00');

-- Patient postal_locator (home address).
INSERT INTO [dbo].[postal_locator]
    ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
     [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [state_cd],
     [street_addr1], [zip_cd])
VALUES
    (@dbo_Postal_locator_patient, '2026-04-01T00:00:00', @superuser_id, N'Atlanta',
     N'840', N'13121', CAST(GETDATE() AS DATE), @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'13',
     N'742 Mapleview Drive', N'30303');

-- Patient tele_locator (home phone).
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_patient, '2026-04-01T00:00:00', @superuser_id, N'1',
     CAST(GETDATE() AS DATE), @superuser_id, N'404-555-0100',
     N'ACTIVE', '2026-04-01T00:00:00');

-- Patient entity_locator_participation:
--   class_cd 'PST' (postal) and 'TELE' (telecom) from SRTE code_set_nm='EL_CLS'.
--   use_cd 'H' (home) from SRTE code_set_nm='EL_USE'.
--   cd 'H' (home) and 'PH' (phone) from SRTE code_set_nm='EL_TYPE'.
INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    (@dbo_Entity_patient_uid, @dbo_Postal_locator_patient,
     '2026-04-01T00:00:00', @superuser_id, N'H',
     N'PST', CAST(GETDATE() AS DATE), @superuser_id, N'Patient home address',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'H', 1, '2026-04-01T00:00:00'),
    (@dbo_Entity_patient_uid, @dbo_Tele_locator_patient,
     '2026-04-01T00:00:00', @superuser_id, N'PH',
     N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'Patient home phone',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'H', 1, '2026-04-01T00:00:00');

-- =====================================================================
-- PROVIDER person row
-- person.cd: 'PRV' from SRTE code_set_nm='P_TYPE'.
-- =====================================================================
INSERT INTO [dbo].[person]
    ([person_uid], [add_time], [add_user_id], [cd],
     [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_general],
     [electronic_ind], [person_parent_uid], [edx_ind])
VALUES
    (@dbo_Entity_provider_uid, '2026-04-01T00:00:00', @superuser_id, N'PRV',
     CAST(GETDATE() AS DATE), @superuser_id, N'PSN20000010GA01',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'Foundation', N'Provider', 1, '2026-04-01T00:00:00',
     N'N', @dbo_Entity_provider_uid, N'Y');

-- Provider person_name.
INSERT INTO [dbo].[person_name]
    ([person_uid], [person_name_seq], [add_time], [add_user_id],
     [first_nm], [last_nm], [nm_suffix], [nm_use_cd],
     [record_status_cd], [record_status_time], [status_cd], [status_time])
VALUES
    (@dbo_Entity_provider_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'Foundation', N'Provider', N'MD', N'L',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00');

-- Provider postal_locator (work address).
INSERT INTO [dbo].[postal_locator]
    ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
     [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [state_cd],
     [street_addr1], [zip_cd])
VALUES
    (@dbo_Postal_locator_provider, '2026-04-01T00:00:00', @superuser_id, N'Atlanta',
     N'840', N'13121', CAST(GETDATE() AS DATE), @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'13',
     N'200 Provider Plaza', N'30303');

-- Provider tele_locator (work phone).
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_provider, '2026-04-01T00:00:00', @superuser_id, N'1',
     CAST(GETDATE() AS DATE), @superuser_id, N'404-555-0200',
     N'ACTIVE', '2026-04-01T00:00:00');

-- Provider entity_locator_participation: WP (work) per RTR provider pivot.
--   See edge_types.md (PST,WP,*) used by sp_provider_event line 99 and (TELE,*,*) at line 144.
INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    (@dbo_Entity_provider_uid, @dbo_Postal_locator_provider,
     '2026-04-01T00:00:00', @superuser_id, N'O',
     N'PST', CAST(GETDATE() AS DATE), @superuser_id, N'Provider work address',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00'),
    (@dbo_Entity_provider_uid, @dbo_Tele_locator_provider,
     '2026-04-01T00:00:00', @superuser_id, N'PH',
     N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'Provider work phone',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00');

-- =====================================================================
-- ORGANIZATION
-- =====================================================================
INSERT INTO [dbo].[organization]
    ([organization_uid], [add_time], [add_user_id], [description],
     [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [display_nm], [version_ctrl_nbr], [electronic_ind])
VALUES
    (@dbo_Entity_organization_uid, '2026-04-01T00:00:00', @superuser_id,
     N'Foundation organization for fixture comparison',
     CAST(GETDATE() AS DATE), @superuser_id, N'ORG20000020GA01',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'Foundation Organization', 1, N'N');

-- Organization name (organization_name_seq is NOT NULL).
INSERT INTO [dbo].[organization_name]
    ([organization_uid], [organization_name_seq], [nm_txt], [nm_use_cd],
     [record_status_cd], [default_nm_ind])
VALUES
    (@dbo_Entity_organization_uid, 1, N'Foundation Organization', N'L',
     N'ACTIVE', N'Y');

-- Organization postal_locator (work address).
INSERT INTO [dbo].[postal_locator]
    ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
     [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [state_cd],
     [street_addr1], [zip_cd])
VALUES
    (@dbo_Postal_locator_org, '2026-04-01T00:00:00', @superuser_id, N'Atlanta',
     N'840', N'13121', CAST(GETDATE() AS DATE), @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'13',
     N'300 Organization Boulevard', N'30303');

-- Organization tele_locator (work phone).
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_org, '2026-04-01T00:00:00', @superuser_id, N'1',
     CAST(GETDATE() AS DATE), @superuser_id, N'404-555-0300',
     N'ACTIVE', '2026-04-01T00:00:00');

-- Organization entity_locator_participation: WP (work) per RTR org pivot.
--   See edge_types.md (PST,WP,*) used by sp_organization_event line 96-97 and (TELE,WP,*) line 118-119.
INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    (@dbo_Entity_organization_uid, @dbo_Postal_locator_org,
     '2026-04-01T00:00:00', @superuser_id, N'O',
     N'PST', CAST(GETDATE() AS DATE), @superuser_id, N'Organization work address',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00'),
    (@dbo_Entity_organization_uid, @dbo_Tele_locator_org,
     '2026-04-01T00:00:00', @superuser_id, N'PH',
     N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'Organization work phone',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00');

-- =====================================================================
-- PLACE
-- =====================================================================
INSERT INTO [dbo].[place]
    ([place_uid], [add_time], [add_user_id], [description],
     [last_chg_time], [last_chg_user_id], [local_id], [nm],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [street_addr1], [city_desc_txt], [state_cd], [zip_cd],
     [cnty_cd], [cntry_cd], [version_ctrl_nbr])
VALUES
    (@dbo_Entity_place_uid, '2026-04-01T00:00:00', @superuser_id,
     N'Foundation place for fixture comparison',
     CAST(GETDATE() AS DATE), @superuser_id, N'PLC20000030GA01', N'Foundation Place',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'400 Place Avenue', N'Atlanta', N'13', N'30303',
     N'13121', N'840', 1);

-- Place postal_locator.
INSERT INTO [dbo].[postal_locator]
    ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
     [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [state_cd],
     [street_addr1], [zip_cd])
VALUES
    (@dbo_Postal_locator_place, '2026-04-01T00:00:00', @superuser_id, N'Atlanta',
     N'840', N'13121', CAST(GETDATE() AS DATE), @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'13',
     N'400 Place Avenue', N'30303');

-- Place entity_locator_participation: physical address.
--   class_cd 'PST' from SRTE EL_CLS; use_cd 'WP' is read by sp_place_event (TELE,*,*) at line 121
--   and sp_place_event also pivots PST locators. Use 'H' for use_cd to remain
--   shape-consistent with NBS place address rows.
INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    (@dbo_Entity_place_uid, @dbo_Postal_locator_place,
     '2026-04-01T00:00:00', @superuser_id, N'H',
     N'PST', CAST(GETDATE() AS DATE), @superuser_id, N'Place address',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'H', 1, '2026-04-01T00:00:00');

-- =====================================================================
-- ACTS — one parent Act row per canonical subject.
-- act.class_cd from SRTE code_set_nm='ACT_CLS': CASE, NOTF, OBS, TRMT, INTV.
-- act.mood_cd 'EVN' (event) from SRTE code_set_nm='ACT_MOOD'.
-- ct_contact has no parent Act class in ACT_CLS; we use 'CON' (Contact)
--   which is referenced as a class concept in PAR_TYPE/RL_CLASS.
-- =====================================================================
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@dbo_Act_investigation_uid, N'CASE', N'EVN'),
    (@dbo_Act_notification_uid,  N'NOTF', N'EVN'),
    (@dbo_Act_lab_uid,           N'OBS',  N'EVN'),
    (@dbo_Act_morbidity_uid,     N'OBS',  N'EVN'),
    (@dbo_Act_interview_uid,     N'ENC',  N'EVN'),  -- Interview class — ENC is the ACT_CLS code for an encounter-style act
    (@dbo_Act_treatment_uid,     N'TRMT', N'EVN'),
    (@dbo_Act_vaccination_uid,   N'INTV', N'EVN'),
    (@dbo_Act_contact_uid,       N'ENC',  N'EVN'); -- Contact record act; CT_contact attaches via FK on Act.act_uid via third_party_entity_phc_uid; the contact act itself is read-through.

-- =====================================================================
-- INVESTIGATION — Public_health_case
-- case_class_cd / case_type_cd / cd_system_cd left NULL; Tier 1 datamart
-- variants will populate condition-driven branches.
-- =====================================================================
INSERT INTO [dbo].[public_health_case]
    ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
     [cd], [cd_desc_txt], [investigation_status_cd],
     [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd])
VALUES
    (@dbo_Act_investigation_uid, '2026-04-01T00:00:00', @superuser_id, N'I',
     N'10110', N'Foundation investigation', N'O',
     CAST(GETDATE() AS DATE), @superuser_id, N'CAS20000100GA01',
     N'OPEN', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'F', 1, N'STD', N'1');

-- =====================================================================
-- NOTIFICATION
-- =====================================================================
INSERT INTO [dbo].[notification]
    ([notification_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd])
VALUES
    (@dbo_Act_notification_uid, '2026-04-01T00:00:00', @superuser_id,
     N'NOT100', N'Foundation notification',
     CAST(GETDATE() AS DATE), @superuser_id, N'NOT20000110GA01',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'F', 1, N'STD', N'1');

-- =====================================================================
-- LAB REPORT — Observation with obs_domain_cd_st_1='Order'
--   Per edge_types.md, RTR disambiguates Lab vs Morbidity by joining the
--   source observation's `obs_domain_cd_st_1` ('Order' = lab order root).
--   subject_person_uid is a soft FK to person; we point at Patient.
-- =====================================================================
INSERT INTO [dbo].[observation]
    ([observation_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [last_chg_time], [last_chg_user_id], [local_id],
     [obs_domain_cd_st_1], [record_status_cd], [record_status_time],
     [status_cd], [status_time], [subject_person_uid],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [electronic_ind])
VALUES
    (@dbo_Act_lab_uid, '2026-04-01T00:00:00', @superuser_id,
     N'LAB100', N'Foundation lab report',
     CAST(GETDATE() AS DATE), @superuser_id, N'OBS20000120GA01',
     N'Order', N'ACTIVE', '2026-04-01T00:00:00',
     N'A', '2026-04-01T00:00:00', @dbo_Entity_patient_uid,
     N'F', 1, N'STD', N'1', N'N');

-- =====================================================================
-- MORBIDITY REPORT — Observation with obs_domain_cd_st_1='Order'
--   Same shape as Lab; cd / cd_desc_txt distinguish at fixture level.
-- =====================================================================
INSERT INTO [dbo].[observation]
    ([observation_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [last_chg_time], [last_chg_user_id], [local_id],
     [obs_domain_cd_st_1], [record_status_cd], [record_status_time],
     [status_cd], [status_time], [subject_person_uid],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [electronic_ind])
VALUES
    (@dbo_Act_morbidity_uid, '2026-04-01T00:00:00', @superuser_id,
     N'MOR100', N'Foundation morbidity report',
     CAST(GETDATE() AS DATE), @superuser_id, N'OBS20000130GA01',
     N'Order', N'ACTIVE', '2026-04-01T00:00:00',
     N'A', '2026-04-01T00:00:00', @dbo_Entity_patient_uid,
     N'F', 1, N'STD', N'1', N'N');

-- =====================================================================
-- INTERVIEW
--   interview.local_id, record_status_cd, record_status_time, add_time,
--   add_user_id, last_chg_time, last_chg_user_id, version_ctrl_nbr are
--   all NOT NULL.
-- =====================================================================
INSERT INTO [dbo].[interview]
    ([interview_uid], [interview_status_cd], [interview_date],
     [interview_type_cd], [interview_loc_cd], [local_id],
     [record_status_cd], [record_status_time], [add_time], [add_user_id],
     [last_chg_time], [last_chg_user_id], [version_ctrl_nbr])
VALUES
    (@dbo_Act_interview_uid, N'C', '2026-04-01T00:00:00',
     N'INITIAL', N'HOSP', N'INT20000140GA01',
     N'ACTIVE', '2026-04-01T00:00:00', '2026-04-01T00:00:00', @superuser_id,
     CAST(GETDATE() AS DATE), @superuser_id, 1);

-- =====================================================================
-- TREATMENT
--   Only treatment_uid is NOT NULL beyond bookkeeping; class_cd column
--   (treatment.class_cd) is nullable but we set 'TRMT' to keep shape.
-- =====================================================================
INSERT INTO [dbo].[treatment]
    ([treatment_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [class_cd], [last_chg_time], [last_chg_user_id], [local_id],
     [prog_area_cd], [jurisdiction_cd], [record_status_cd],
     [record_status_time], [shared_ind], [status_cd], [status_time],
     [version_ctrl_nbr])
VALUES
    (@dbo_Act_treatment_uid, '2026-04-01T00:00:00', @superuser_id,
     N'TRMT100', N'Foundation treatment',
     N'TRMT', CAST(GETDATE() AS DATE), @superuser_id, N'TRT20000150GA01',
     N'STD', N'1', N'ACTIVE',
     '2026-04-01T00:00:00', N'F', N'A', '2026-04-01T00:00:00',
     1);

-- =====================================================================
-- VACCINATION — Intervention
--   intervention.shared_ind and version_ctrl_nbr are NOT NULL.
-- =====================================================================
INSERT INTO [dbo].[intervention]
    ([intervention_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [class_cd], [last_chg_time], [last_chg_user_id], [local_id],
     [prog_area_cd], [jurisdiction_cd], [record_status_cd],
     [record_status_time], [shared_ind], [status_cd], [status_time],
     [version_ctrl_nbr], [material_cd], [vacc_dose_nbr], [electronic_ind])
VALUES
    (@dbo_Act_vaccination_uid, '2026-04-01T00:00:00', @superuser_id,
     N'VAC100', N'Foundation vaccination',
     N'INTV', CAST(GETDATE() AS DATE), @superuser_id, N'VAC20000160GA01',
     N'IMM', N'1', N'ACTIVE',
     '2026-04-01T00:00:00', N'F', N'A', '2026-04-01T00:00:00',
     1, N'207', 1, N'N');

-- =====================================================================
-- CONTACT RECORD — CT_contact
--   Hard FKs (NOT NULL): subject_entity_uid, contact_entity_uid -> entity;
--   subject_entity_phc_uid -> public_health_case.
--   Decision: subject = Patient, contact = Patient (foundation has only one
--   Person-class entity available without inventing a second; downstream
--   Tier 1 contact subject can override). PHC = Investigation.
--   This is internal foundation linkage, NOT a cross-subject act_relationship
--   / participation row.
-- =====================================================================
INSERT INTO [dbo].[ct_contact]
    ([ct_contact_uid], [local_id], [subject_entity_uid], [contact_entity_uid],
     [subject_entity_phc_uid], [record_status_cd], [record_status_time],
     [add_user_id], [add_time], [last_chg_time], [last_chg_user_id],
     [version_ctrl_nbr])
VALUES
    (@dbo_Act_contact_uid, N'CON20000170GA01',
     @dbo_Entity_patient_uid, @dbo_Entity_patient_uid,
     @dbo_Act_investigation_uid, N'ACTIVE', '2026-04-01T00:00:00',
     @superuser_id, '2026-04-01T00:00:00', CAST(GETDATE() AS DATE), @superuser_id,
     1);
GO
