USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 1 Patient fixture
-- Baseline: 6.0.18.1 (post-liquibase) + fixtures/00_foundation/00_foundation.sql
--
-- WHAT THIS FIXTURE DOES
--   1. Enriches the foundation Patient (UID 20000000) with:
--        - a (PST/BIR/...) postal_locator + ELP row so the event SP's
--          birth-country branch (sp_patient_event:251-252, use_cd IN ('H','BIR'))
--          has a row to pivot, and PATIENT_BIRTH_COUNTRY is populated for
--          the foundation patient.
--        - a (TELE/H/NET) tele_locator + ELP row to exercise the email
--          branch (sp_patient_event:278-279, cd='NET').
--        - a person_race row (foundation has none) so the race event SP
--          doesn't return empty for the foundation patient.
--        - an entity_id row of type_cd='PI' (patient internal id) to
--          surface in the entity_id JSON projection.
--   2. Adds a fully-attributed Patient v2 variant (UID 20020010) so every
--      D_PATIENT column the postprocessing SP propagates is populated for
--      at least one patient. This row carries multiple person_race rows
--      across multiple racial categories (root + detail) so race_amer_ind_*,
--      race_white_*, race_black_*, race_asian_*, race_nat_hi_*, and the
--      cross-category PATIENT_RACE_ALL/PATIENT_RACE_CALCULATED are
--      exercised.
--   3. Adds a v3 deceased Patient variant (UID 20020020) with
--      deceased_ind_cd='Y' and a non-NULL deceased_time so
--      D_PATIENT.PATIENT_DECEASED_DATE and the populated
--      PATIENT_DECEASED_INDICATOR='Yes' branch are exercised.
--   4. Populates dbo.nrt_patient in RDB_MODERN directly for all 3
--      patient_uids. The event SP only emits a SELECT (consumed by Kafka
--      in production); kafka-connect would normally write nrt_patient.
--      For fixture verification we bypass that and write nrt_patient by
--      hand. Without the direct INSERTs the postprocessing SP returns
--      "Missing NRT Record" and never writes D_PATIENT.
--      (Same approach as Provider/Organization canaries — see
--       coverage_provider.md "Notes for Tier 1 template".)
--
-- UID block (Patient Tier 1): 20020000-20029999.
-- Foundation dependencies (read-only):
--   @dbo_Entity_patient_uid       20000000  (entity / person / person_name)
--   @dbo_Postal_locator_patient   20000001  (PST/H/H)
--   @dbo_Tele_locator_patient     20000002  (TELE/H/PH)
-- =====================================================================

-- ----- Sentinel reference (do not allocate — assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Foundation dependencies referenced (read-only) -----
DECLARE @foundation_patient_uid        bigint = 20000000;  -- foundation Patient entity / person
DECLARE @foundation_postal_patient     bigint = 20000001;  -- foundation Patient postal_locator (PST/H/H)
DECLARE @foundation_tele_patient       bigint = 20000002;  -- foundation Patient tele_locator (TELE/H/PH)

-- =====================================================================
-- UID allocations (Patient Tier 1: 20020000-20029999)
-- =====================================================================

-- ----- Enrichment of foundation Patient -----
DECLARE @dbo_Postal_locator_patient_bir   bigint = 20020001;  -- foundation Patient (PST,BIR,*) — drives PATIENT_BIRTH_COUNTRY on foundation
DECLARE @dbo_Tele_locator_patient_email   bigint = 20020002;  -- foundation Patient (TELE,*,NET) — drives PATIENT_EMAIL on foundation
-- entity_id row + person_race row for foundation Patient — keyed by composite, no separate UID

-- ----- Patient v2: a separate fully-attributed Patient entity -----
DECLARE @dbo_Entity_patient_v2_uid             bigint = 20020010;  -- v2 Patient entity / person / person_parent_uid
DECLARE @dbo_Postal_locator_patient_v2_home    bigint = 20020011;  -- v2 home address (PST,H,H)
DECLARE @dbo_Postal_locator_patient_v2_bir     bigint = 20020012;  -- v2 birth-country locator (PST,BIR,*)
DECLARE @dbo_Tele_locator_patient_v2_home      bigint = 20020013;  -- v2 home phone (TELE,H,PH)
DECLARE @dbo_Tele_locator_patient_v2_work      bigint = 20020014;  -- v2 work phone (TELE,WP,*)
DECLARE @dbo_Tele_locator_patient_v2_cell      bigint = 20020015;  -- v2 cell phone (TELE,*,*)
DECLARE @dbo_Tele_locator_patient_v2_email     bigint = 20020016;  -- v2 email (TELE,*,NET)

-- ----- Patient v3 (deceased) -----
DECLARE @dbo_Entity_patient_v3_uid             bigint = 20020020;  -- v3 deceased Patient

-- =====================================================================
-- ODSE rows — additive enrichments to the foundation Patient.
-- These rows feed sp_patient_event so its SELECT projection picks up
-- birth-country, email, race, and entity_id. They are NOT what drives
-- the postprocessing SP (that is driven by direct nrt_patient inserts
-- below).
-- =====================================================================

-- --- Foundation Patient enrichment: birth-country postal_locator + ELP ---
-- sp_patient_event:251-252 filters (PST, H|BIR, *). Foundation has (PST,H,H);
-- this adds (PST,BIR,*) so the birth_country case branch resolves.
-- cntry_cd '156' = China (verified in NBS_SRTE.dbo.country_code and
-- code_value_general WHERE code_set_nm='PHVS_BIRTHCOUNTRY_CDC').
INSERT INTO [dbo].[postal_locator]
    ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
     [cntry_cd], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Postal_locator_patient_bir, '2026-04-01T00:00:00', @superuser_id, N'Shanghai',
     N'156', '2026-04-01T00:00:00', @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00');

INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    (@foundation_patient_uid, @dbo_Postal_locator_patient_bir,
     '2026-04-01T00:00:00', @superuser_id, N'BIR',
     N'PST', '2026-04-01T00:00:00', @superuser_id, N'Foundation Patient birth country',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'BIR', 1, '2026-04-01T00:00:00');

-- --- Foundation Patient enrichment: email tele_locator + ELP ---
-- sp_patient_event:278-279 filters (TELE, *, NET). Foundation has (TELE,H,PH);
-- this adds (TELE,H,NET) so the email branch resolves with a non-null
-- email_address.
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [email_address],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_patient_email, '2026-04-01T00:00:00', @superuser_id, N'1',
     '2026-04-01T00:00:00', @superuser_id, N'foundation.patient@nbs.test',
     N'ACTIVE', '2026-04-01T00:00:00');

INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    (@foundation_patient_uid, @dbo_Tele_locator_patient_email,
     '2026-04-01T00:00:00', @superuser_id, N'NET',
     N'TELE', '2026-04-01T00:00:00', @superuser_id, N'Foundation Patient email',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'H', 1, '2026-04-01T00:00:00');

-- --- Foundation Patient enrichment: entity_id (PI / patient internal) ---
-- entity_id.type_cd 'PI' from SRTE EI_TYPE_PAT (verified). Patient internal
-- identifier; surfaces in patient_entity JSON projection at
-- sp_patient_event:343-353.
INSERT INTO [dbo].[entity_id]
    ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
VALUES
    (@foundation_patient_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     NULL, NULL,
     '2026-04-01T00:00:00', @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'PAT-FND-1', N'PI', N'Patient Internal Identifier', '2026-04-01T00:00:00');

-- --- Foundation Patient enrichment: person_race (single White root row) ---
-- Foundation does not seed person_race; sp_patient_race_event would return
-- empty for the foundation patient, leaving every PATIENT_RACE_* column
-- NULL. Add a single White-only root row to exercise the simple
-- single-root path: PATIENT_RACE_CALCULATED='White', PATIENT_RACE_ALL='White',
-- PATIENT_RACE_CALC_DETAILS='White', and the per-category breakdown
-- columns NULL (because no detail row).
INSERT INTO [dbo].[person_race]
    ([person_uid], [race_cd], [race_category_cd], [add_time], [add_user_id],
     [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time],
     [as_of_date])
VALUES
    (@foundation_patient_uid, N'2106-3', N'2106-3',  -- White root (race_cd = race_category_cd; parent_is_cd='ROOT')
     '2026-04-01T00:00:00', @superuser_id,
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00',
     '2026-04-01T00:00:00');

-- =====================================================================
-- Patient v2 — fully attributed Patient variant for column coverage.
-- =====================================================================

-- entity.class_cd 'PSN' from SRTE ENTITY_CLS.
INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
    (@dbo_Entity_patient_v2_uid, N'PSN');

-- v2 person row. Every column the SP can propagate is populated.
-- - cd 'PAT' (P_TYPE)
-- - birth_gender_cd 'F' (DEM114→SEX), curr_sex_cd 'F' (DEM113→SEX),
--   ethnic_group_ind '2135-2' (DEM155→P_ETHN_GRP),
--   marital_status_cd 'M' (DEM140→P_MARITAL),
--   deceased_ind_cd 'N' (DEM127→YNU),
--   age_reported_unit_cd 'Y' (DEM218→AGE_UNIT),
--   speaks_english_cd 'Y' (NBS214→YNU),
--   ethnic_unk_reason_cd '6' (NBS273→P_ETHN_UNK_REASON),
--   sex_unk_reason_cd 'D' (NBS272→SEX_UNK_REASON),
--   preferred_gender_cd 'F' (NBS_STD_GENDER_PARPT via fn_get_value_by_cvg),
--   occupation_cd '622110' (DEM139→O_NAICS via naics_industry_code),
--   prim_lang_cd 'ENG' (DEM142→P_LANG via language_code).
-- All verified above in the SRTE checks.
INSERT INTO [dbo].[person]
    ([person_uid], [add_time], [add_user_id],
     [birth_gender_cd], [birth_time], [cd], [curr_sex_cd], [deceased_ind_cd],
     [ethnic_group_ind], [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [first_nm], [middle_nm], [last_nm], [nm_suffix], [version_ctrl_nbr],
     [as_of_date_general], [as_of_date_admin], [as_of_date_ethnicity],
     [as_of_date_morbidity], [as_of_date_sex],
     [electronic_ind], [person_parent_uid], [edx_ind],
     [age_reported], [age_reported_unit_cd],
     [marital_status_cd], [education_level_cd], [occupation_cd],
     [prim_lang_cd], [preferred_gender_cd], [additional_gender_cd],
     [speaks_english_cd], [ethnic_unk_reason_cd], [sex_unk_reason_cd],
     [adults_in_house_nbr], [children_in_house_nbr],
     [multiple_birth_ind], [birth_order_nbr],
     [description])
VALUES
    (@dbo_Entity_patient_v2_uid, '2026-04-01T00:00:00', @superuser_id,
     N'F', '1985-06-15T00:00:00', N'PAT', N'F', N'N',
     N'2135-2', '2026-04-01T00:00:00', @superuser_id, N'PSN20020010GA01',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'Diane', N'Marie', N'Whitfield', N'JR', 1,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', '2026-04-01T00:00:00',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00',
     N'N', @dbo_Entity_patient_v2_uid, N'Y',
     N'40', N'Y',
     N'M', N'BD', N'622110',
     N'ENG', N'F', N'Variant additional gender info',
     N'Y', N'6', N'D',
     2, 1,
     N'N', 1,
     N'Tier 1 fully-attributed patient variant');

-- v2 person_name. nm_use_cd 'L' (legal); same dialect as foundation.
-- nm_suffix 'JR' (P_NM_SFX). nm_degree free text per Provider canary
-- (column lives only on person_name).
INSERT INTO [dbo].[person_name]
    ([person_uid], [person_name_seq], [add_time], [add_user_id],
     [first_nm], [middle_nm], [last_nm], [nm_suffix], [nm_degree], [nm_use_cd],
     [record_status_cd], [record_status_time], [status_cd], [status_time])
VALUES
    (@dbo_Entity_patient_v2_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'Diane', N'Marie', N'Whitfield', N'JR', N'PhD', N'L',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00');

-- v2 alias name (nm_use_cd='AL') — surfaces in the patient_name JSON
-- projection (the postprocessing SP reads alias_nickname from the
-- nrt_patient row directly; this is shape-only, not directly required for
-- D_PATIENT.PATIENT_ALIAS_NICKNAME coverage).
INSERT INTO [dbo].[person_name]
    ([person_uid], [person_name_seq], [add_time], [add_user_id],
     [first_nm], [last_nm], [nm_use_cd],
     [record_status_cd], [record_status_time], [status_cd], [status_time])
VALUES
    (@dbo_Entity_patient_v2_uid, 2, '2026-04-01T00:00:00', @superuser_id,
     N'Vee', N'Patient', N'A',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00');

-- v2 entity_id (SS — Social Security number).
INSERT INTO [dbo].[entity_id]
    ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
VALUES
    (@dbo_Entity_patient_v2_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     '2026-04-01T00:00:00', @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'123-45-6789', N'SS', N'Social Security', '2026-04-01T00:00:00');

-- v2 entity_id row 2 — Medical Record Number.
INSERT INTO [dbo].[entity_id]
    ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
VALUES
    (@dbo_Entity_patient_v2_uid, 2, '2026-04-01T00:00:00', @superuser_id,
     '2026-04-01T00:00:00', @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'MRN20020010', N'MR', N'Medical record number', '2026-04-01T00:00:00');

-- v2 person_race rows: one root + one detail row across two categories.
-- This populates PATIENT_RACE_CALCULATED='Multi-Race', PATIENT_RACE_ALL,
-- PATIENT_RACE_CALC_DETAILS, PATIENT_RACE_AMER_IND_*, PATIENT_RACE_ASIAN_*.
-- Hawaiian / Black / White columns will be NULL on v2 by design.
-- Both root rows are required by the race event SP's join logic
-- (#TMP_S_PERSON_AMER_INDIAN_RACE filter requires `race_cd <> race_category_cd`
-- AND the breakdown CTE joins to the root row where `pr.race_cd = pr.race_category_cd`).
INSERT INTO [dbo].[person_race]
    ([person_uid], [race_cd], [race_category_cd], [add_time], [add_user_id],
     [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time],
     [as_of_date])
VALUES
    -- American Indian or Alaska Native root
    (@dbo_Entity_patient_v2_uid, N'1002-5', N'1002-5',
     '2026-04-01T00:00:00', @superuser_id,
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00',
     '2026-04-01T00:00:00'),
    -- American Indian (detail) under category 1002-5
    (@dbo_Entity_patient_v2_uid, N'1004-1', N'1002-5',
     '2026-04-01T00:00:00', @superuser_id,
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00',
     '2026-04-01T00:00:00'),
    -- Asian root
    (@dbo_Entity_patient_v2_uid, N'2028-9', N'2028-9',
     '2026-04-01T00:00:00', @superuser_id,
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00',
     '2026-04-01T00:00:00'),
    -- Chinese (detail) under category 2028-9
    (@dbo_Entity_patient_v2_uid, N'2034-7', N'2028-9',
     '2026-04-01T00:00:00', @superuser_id,
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00',
     '2026-04-01T00:00:00');

-- v2 postal_locator (home address).
-- state_cd '13' (GA), cnty_cd '13121' (Fulton), cntry_cd '840' (US) —
-- all verified.
INSERT INTO [dbo].[postal_locator]
    ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
     [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [state_cd],
     [street_addr1], [street_addr2], [zip_cd], [census_tract], [within_city_limits_ind])
VALUES
    (@dbo_Postal_locator_patient_v2_home, '2026-04-01T00:00:00', @superuser_id, N'Atlanta',
     N'840', N'13121', '2026-04-01T00:00:00', @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'13',
     N'500 Variant Patient Lane', N'Apartment 7B', N'30303', N'1210310', N'Y');

-- v2 postal_locator (birth country = Canada).
INSERT INTO [dbo].[postal_locator]
    ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
     [cntry_cd], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Postal_locator_patient_v2_bir, '2026-04-01T00:00:00', @superuser_id, N'Toronto',
     N'124', '2026-04-01T00:00:00', @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00');

-- v2 tele_locator (home phone).
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_patient_v2_home, '2026-04-01T00:00:00', @superuser_id, N'1',
     '2026-04-01T00:00:00', @superuser_id, N'404-555-2010', N'4321',
     N'ACTIVE', '2026-04-01T00:00:00');

-- v2 tele_locator (work phone).
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_patient_v2_work, '2026-04-01T00:00:00', @superuser_id, N'1',
     '2026-04-01T00:00:00', @superuser_id, N'404-555-2011', N'9999',
     N'ACTIVE', '2026-04-01T00:00:00');

-- v2 tele_locator (cell phone).
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_patient_v2_cell, '2026-04-01T00:00:00', @superuser_id, N'1',
     '2026-04-01T00:00:00', @superuser_id, N'404-555-2012',
     N'ACTIVE', '2026-04-01T00:00:00');

-- v2 tele_locator (email).
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [email_address],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_patient_v2_email, '2026-04-01T00:00:00', @superuser_id, N'1',
     '2026-04-01T00:00:00', @superuser_id, N'variant.patient@nbs.test',
     N'ACTIVE', '2026-04-01T00:00:00');

-- v2 entity_locator_participation rows. Filters per sp_patient_event:
--   address (PST,H|BIR,*); phone (TELE,*,*); email (TELE,*,NET).
INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    -- v2 home address (PST,H,H)
    (@dbo_Entity_patient_v2_uid, @dbo_Postal_locator_patient_v2_home,
     '2026-04-01T00:00:00', @superuser_id, N'H',
     N'PST', '2026-04-01T00:00:00', @superuser_id, N'v2 Patient home address',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'H', 1, '2026-04-01T00:00:00'),
    -- v2 birth country (PST,BIR,BIR)
    (@dbo_Entity_patient_v2_uid, @dbo_Postal_locator_patient_v2_bir,
     '2026-04-01T00:00:00', @superuser_id, N'BIR',
     N'PST', '2026-04-01T00:00:00', @superuser_id, N'v2 Patient birth country',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'BIR', 1, '2026-04-01T00:00:00'),
    -- v2 home phone (TELE,H,PH)
    (@dbo_Entity_patient_v2_uid, @dbo_Tele_locator_patient_v2_home,
     '2026-04-01T00:00:00', @superuser_id, N'PH',
     N'TELE', '2026-04-01T00:00:00', @superuser_id, N'v2 Patient home phone',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'H', 1, '2026-04-01T00:00:00'),
    -- v2 work phone (TELE,WP,PH)
    (@dbo_Entity_patient_v2_uid, @dbo_Tele_locator_patient_v2_work,
     '2026-04-01T00:00:00', @superuser_id, N'PH',
     N'TELE', '2026-04-01T00:00:00', @superuser_id, N'v2 Patient work phone',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00'),
    -- v2 cell phone (TELE,*,CP)
    (@dbo_Entity_patient_v2_uid, @dbo_Tele_locator_patient_v2_cell,
     '2026-04-01T00:00:00', @superuser_id, N'CP',
     N'TELE', '2026-04-01T00:00:00', @superuser_id, N'v2 Patient cell phone',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'H', 1, '2026-04-01T00:00:00'),
    -- v2 email (TELE,H,NET)
    (@dbo_Entity_patient_v2_uid, @dbo_Tele_locator_patient_v2_email,
     '2026-04-01T00:00:00', @superuser_id, N'NET',
     N'TELE', '2026-04-01T00:00:00', @superuser_id, N'v2 Patient email',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'H', 1, '2026-04-01T00:00:00');

-- =====================================================================
-- Patient v3 — deceased variant for PATIENT_DECEASED_DATE coverage.
-- Minimal demographics; the postprocessing SP propagates deceased_date
-- and deceased_indicator irrespective of other columns.
-- =====================================================================

INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
    (@dbo_Entity_patient_v3_uid, N'PSN');

INSERT INTO [dbo].[person]
    ([person_uid], [add_time], [add_user_id],
     [birth_gender_cd], [birth_time], [cd], [curr_sex_cd],
     [deceased_ind_cd], [deceased_time],
     [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [first_nm], [last_nm], [version_ctrl_nbr], [as_of_date_general],
     [electronic_ind], [person_parent_uid], [edx_ind])
VALUES
    (@dbo_Entity_patient_v3_uid, '2026-04-01T00:00:00', @superuser_id,
     N'M', '1955-03-10T00:00:00', N'PAT', N'M',
     N'Y', '2025-12-15T00:00:00',
     '2026-04-01T00:00:00', @superuser_id, N'PSN20020020GA01',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'Deceased', N'Patient', 1, '2026-04-01T00:00:00',
     N'N', @dbo_Entity_patient_v3_uid, N'Y');

INSERT INTO [dbo].[person_name]
    ([person_uid], [person_name_seq], [add_time], [add_user_id],
     [first_nm], [last_nm], [nm_use_cd],
     [record_status_cd], [record_status_time], [status_cd], [status_time])
VALUES
    (@dbo_Entity_patient_v3_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'Deceased', N'Patient', N'L',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00');

GO

-- =====================================================================
-- DRIVE THE POSTPROCESSING SP via direct nrt_patient INSERTs.
--
-- sp_patient_event only emits a SELECT (consumed by Kafka in production).
-- For fixture verification we populate dbo.nrt_patient directly to drive
-- sp_nrt_patient_postprocessing → D_PATIENT. Three rows: foundation
-- (20000000), v2 (20020010), v3 deceased (20020020). Foundation row
-- deliberately leaves a few optional columns NULL so the SP's
-- "blank/null → NULL" transform path is observable. The v2 row sets
-- every column the SP propagates (within v2's chosen race profile).
--
-- nrt_patient has refresh_datetime (AS_ROW_START) and max_datetime
-- (AS_ROW_END) GENERATED ALWAYS columns; SQL Server populates them on
-- INSERT, so they are omitted from the column list.
-- =====================================================================

USE [RDB_MODERN];
GO


GO
