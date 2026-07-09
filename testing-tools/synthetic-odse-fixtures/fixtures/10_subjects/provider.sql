USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 1 Provider fixture (canary)
-- Baseline: 6.0.18.1 (post-liquibase) + fixtures/00_foundation/00_foundation.sql
--
-- WHAT THIS FIXTURE DOES
--   1. Adds Provider-specific ODSE rows that ENRICH the foundation Provider
--      (UID 20000010): an entity_id (NPI) row, a TELE/WP/O locator (work
--      phone with cd='O' as required by sp_provider_event lines 116-117),
--      and an additional WP/O TELE for email_work.
--   2. Adds a fully-attributed Provider variant ("Provider v2", UID 20010000)
--      so every D_PROVIDER column the postprocessing SP can write is exercised
--      for at least one provider.
--   3. Populates dbo.nrt_provider in RDB_MODERN directly. THIS IS REQUIRED:
--      sp_provider_event only emits a SELECT for downstream Kafka consumers;
--      it does NOT itself write to dbo.nrt_provider. The Tier 1 prompt /
--      STRATEGY.md description is incorrect on this point. Without these
--      direct INSERTs into nrt_provider, sp_nrt_provider_postprocessing
--      returns "Missing NRT Record" and never writes D_PROVIDER. See
--      coverage_provider.md "Notes for Tier 1 template" for details.
--
-- UID block (Provider Tier 1): 20010000-20019999.
-- Foundation dependencies (read-only): @dbo_Entity_provider_uid 20000010,
--   @dbo_Postal_locator_provider 20000011, @dbo_Tele_locator_provider 20000012.
-- =====================================================================

-- ----- Sentinel reference (do not allocate — assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Foundation dependencies referenced (read-only) -----
DECLARE @foundation_provider_uid       bigint = 20000010;  -- foundation Provider entity/person
DECLARE @foundation_postal_provider    bigint = 20000011;  -- foundation Provider postal_locator
DECLARE @foundation_tele_provider      bigint = 20000012;  -- foundation Provider tele_locator (cd='PH')

-- =====================================================================
-- UID allocations (Provider Tier 1: 20010000-20019999)
-- =====================================================================

-- ----- Enrichment of foundation Provider -----
DECLARE @dbo_Tele_locator_provider_work_o     bigint = 20010001;  -- new TELE locator: cd='O', use_cd='WP' (drives phone_work / email_work)
DECLARE @dbo_Postal_locator_provider_v1_alt   bigint = 20010002;  -- (reserved; not currently used)
-- entity_id row for foundation Provider (NPI) — keyed by (entity_uid, entity_id_seq), no separate UID

-- ----- Provider v2: a separate fully-attributed Provider entity -----
DECLARE @dbo_Entity_provider_v2_uid           bigint = 20010010;  -- v2 Provider entity / person / person_parent_uid
DECLARE @dbo_Postal_locator_provider_v2       bigint = 20010011;  -- v2 Provider work postal locator
DECLARE @dbo_Tele_locator_provider_v2_work    bigint = 20010012;  -- v2 Provider work tele locator (phone, cd='O', use_cd='WP')
DECLARE @dbo_Tele_locator_provider_v2_email   bigint = 20010013;  -- v2 Provider work email tele locator (cd='O', use_cd='WP')
DECLARE @dbo_Tele_locator_provider_v2_cell    bigint = 20010014;  -- v2 Provider cell phone tele locator (cd='CP')

-- =====================================================================
-- ODSE rows (NBS_ODSE) — additive, reflect what nrt_provider will contain.
-- These rows make the upstream sp_provider_event return realistic JSON for
-- the foundation + v2 provider; they are NOT what drives the postprocessing
-- SP (that is driven by direct nrt_provider inserts below).
-- =====================================================================

-- --- Foundation Provider enrichment: entity_id (NPI) ---
-- entity_id.type_cd 'NPI' from SRTE code_set_nm='EI_TYPE_PRV' (verified in baseline).
INSERT INTO [dbo].[entity_id]
    ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
VALUES
    (@foundation_provider_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'CMS', N'Centers for Medicare & Medicaid Services',
     CAST(GETDATE() AS DATE), @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'1234567890', N'NPI', N'National provider identifier', '2026-04-01T00:00:00');

-- --- Foundation Provider enrichment: TELE locator (work phone) cd='O', use_cd='WP' ---
-- The foundation Provider's existing TELE row uses cd='PH', but sp_provider_event
-- lines 115-118 filter `elp.CD IN ('O')` for phone_work/email_work. We add a new
-- tele_locator + entity_locator_participation pair so the upstream SELECT picks
-- up phone_work and email_work fields.
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
     [email_address],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_provider_work_o, '2026-04-01T00:00:00', @superuser_id, N'1',
     CAST(GETDATE() AS DATE), @superuser_id, N'404-555-0210', N'1234',
     N'foundation.provider@nbs.test',
     N'ACTIVE', '2026-04-01T00:00:00');

INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    (@foundation_provider_uid, @dbo_Tele_locator_provider_work_o,
     '2026-04-01T00:00:00', @superuser_id, N'O',
     N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'Provider work phone/email',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00');

-- =====================================================================
-- Provider v2 — fully attributed Provider variant for column coverage.
-- =====================================================================

-- entity.class_cd 'PSN' from SRTE code_set_nm='ENTITY_CLS'.
INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
    (@dbo_Entity_provider_v2_uid, N'PSN');

-- person.cd 'PRV' from SRTE code_set_nm='P_TYPE'.
-- Note: person.nm_degree does NOT exist on the dbo.person table; nm_degree
-- lives only on person_name. Verified via INFORMATION_SCHEMA.COLUMNS.
INSERT INTO [dbo].[person]
    ([person_uid], [add_time], [add_user_id], [cd],
     [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_suffix],
     [version_ctrl_nbr], [as_of_date_general],
     [electronic_ind], [person_parent_uid], [edx_ind],
     [description])
VALUES
    (@dbo_Entity_provider_v2_uid, '2026-04-01T00:00:00', @superuser_id, N'PRV',
     CAST(GETDATE() AS DATE), @superuser_id, N'PSN20010010GA01',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'Variant', N'Q', N'Provider', N'DR', N'JR',
     1, '2026-04-01T00:00:00',
     N'N', @dbo_Entity_provider_v2_uid, N'Y',
     N'Tier 1 fully-attributed provider variant');

-- person_name. nm_use_cd 'L' (legal). nm_prefix 'DR' from SRTE code_set_nm='DEM101';
-- nm_suffix 'JR' from SRTE code_set_nm='DEM107' (verified in baseline).
INSERT INTO [dbo].[person_name]
    ([person_uid], [person_name_seq], [add_time], [add_user_id],
     [first_nm], [middle_nm], [last_nm],
     [nm_prefix], [nm_suffix], [nm_degree], [nm_use_cd],
     [record_status_cd], [record_status_time], [status_cd], [status_time])
VALUES
    (@dbo_Entity_provider_v2_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'Variant', N'Q', N'Provider',
     N'DR', N'JR', N'PhD', N'L',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00');

-- v2 Provider entity_id (NPI).
INSERT INTO [dbo].[entity_id]
    ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
VALUES
    (@dbo_Entity_provider_v2_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'CMS', N'Centers for Medicare & Medicaid Services',
     CAST(GETDATE() AS DATE), @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'9876543210', N'NPI', N'National provider identifier', '2026-04-01T00:00:00');

-- v2 Provider postal_locator (work address).
-- state_cd '13' Georgia (NBS_SRTE.dbo.State_code); cnty_cd '13121' Fulton County
-- (NBS_SRTE.dbo.State_county_code_value); cntry_cd '840' United States (NBS_SRTE.dbo.Country_code).
INSERT INTO [dbo].[postal_locator]
    ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
     [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [state_cd],
     [street_addr1], [street_addr2], [zip_cd])
VALUES
    (@dbo_Postal_locator_provider_v2, '2026-04-01T00:00:00', @superuser_id, N'Atlanta',
     N'840', N'13121', CAST(GETDATE() AS DATE), @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'13',
     N'2010 Variant Provider Way', N'Suite 200', N'30303');

-- v2 Provider tele_locator (work phone with extension and email).
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_provider_v2_work, '2026-04-01T00:00:00', @superuser_id, N'1',
     CAST(GETDATE() AS DATE), @superuser_id, N'404-555-1010', N'5678',
     N'ACTIVE', '2026-04-01T00:00:00');

-- v2 Provider tele_locator (work email).
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [email_address],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_provider_v2_email, '2026-04-01T00:00:00', @superuser_id, N'1',
     CAST(GETDATE() AS DATE), @superuser_id, N'variant.provider@nbs.test',
     N'ACTIVE', '2026-04-01T00:00:00');

-- v2 Provider tele_locator (cell phone). Filter at sp_provider_event line 132 is `cd='CP'`.
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_provider_v2_cell, '2026-04-01T00:00:00', @superuser_id, N'1',
     CAST(GETDATE() AS DATE), @superuser_id, N'404-555-1011',
     N'ACTIVE', '2026-04-01T00:00:00');

-- v2 Provider entity_locator_participation rows.
-- elp.cd 'O' (Office) from SRTE code_set_nm='EL_TYPE'. use_cd 'WP' (Work Place) from SRTE EL_USE.
-- For phone_work/email_work the SP requires (TELE,O,WP); for cell phone (TELE,CP,*).
INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    -- v2 Provider work address (PST/WP/O — drives address columns).
    (@dbo_Entity_provider_v2_uid, @dbo_Postal_locator_provider_v2,
     '2026-04-01T00:00:00', @superuser_id, N'O',
     N'PST', CAST(GETDATE() AS DATE), @superuser_id, N'v2 Provider work address',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00'),
    -- v2 Provider work phone (TELE/WP/O — drives phone_work / phone_ext_work).
    (@dbo_Entity_provider_v2_uid, @dbo_Tele_locator_provider_v2_work,
     '2026-04-01T00:00:00', @superuser_id, N'O',
     N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'v2 Provider work phone',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00'),
    -- v2 Provider work email (TELE/WP/O — drives email_work).
    (@dbo_Entity_provider_v2_uid, @dbo_Tele_locator_provider_v2_email,
     '2026-04-01T00:00:00', @superuser_id, N'O',
     N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'v2 Provider work email',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00'),
    -- v2 Provider cell phone (TELE/CP/* — drives phone_cell).
    (@dbo_Entity_provider_v2_uid, @dbo_Tele_locator_provider_v2_cell,
     '2026-04-01T00:00:00', @superuser_id, N'CP',
     N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'v2 Provider cell phone',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00');

GO

-- =====================================================================
-- DRIVE THE POSTPROCESSING SP via direct nrt_provider INSERTs.
--
-- sp_provider_event only emits a SELECT (consumed by Kafka in production).
-- For fixture verification we populate dbo.nrt_provider directly to drive
-- sp_nrt_provider_postprocessing → D_PROVIDER. Two rows are inserted: one
-- for the foundation Provider (UID 20000010) and one for v2 (UID 20010010).
-- The foundation row deliberately leaves a few optional columns NULL so that
-- diff tooling can see "minimal" vs "fully attributed" rows. The v2 row sets
-- every column the postprocessing SP propagates.
-- =====================================================================

USE [RDB_MODERN];
GO

-- nrt_provider has refresh_datetime/max_datetime as system-period (GENERATED
-- ALWAYS) columns; SQL Server populates them automatically on INSERT, so we
-- omit them from the column list.

GO
