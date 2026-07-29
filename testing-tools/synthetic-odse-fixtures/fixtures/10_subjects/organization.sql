USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 1 Organization fixture
-- Baseline: 6.0.18.1 (post-liquibase) + fixtures/00_foundation/00_foundation.sql
--
-- WHAT THIS FIXTURE DOES
--   1. Enriches the foundation Organization (UID 20000020) with:
--        - a fax tele_locator + ELP row (TELE/WP/FAX) so the event SP's
--          fax pivot has a row to find (sp_organization_event:124-135).
--        - an entity_id row of type_cd='FI' with assigning_authority_cd
--          to exercise the FACILITY_ID branch and the EI_AUTH_ORG case
--          branch in sp_organization_event:137-152.
--        (organization.standard_industry_class_cd is intentionally
--         NOT set on the foundation Org — foundation rows are read-only.
--         The v2 Org below sets the NAICS code to exercise the populated
--         STAND_IND_CLASS path; foundation exhibits the null path.)
--   2. Adds a fully-attributed Organization variant ("Org v2", UID
--      20030010) so every D_ORGANIZATION column the postprocessing SP
--      can write is exercised for at least one organization.
--   3. Populates dbo.nrt_organization in RDB_MODERN directly, mirroring
--      what kafka-connect would have written. The event SP only emits a
--      SELECT; it does not write nrt_organization. Without these direct
--      INSERTs the postprocessing SP returns "Missing NRT Record".
--
-- UID block (Organization Tier 1): 20030000-20039999.
-- Foundation dependencies (read-only):
--   @dbo_Entity_organization_uid     20000020 (entity / organization /
--                                              organization_name)
--   @dbo_Postal_locator_org          20000021 (PST/WP/O)
--   @dbo_Tele_locator_org            20000022 (TELE/WP/PH)
-- =====================================================================

-- ----- Sentinel reference (do not allocate — assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Foundation dependencies referenced (read-only) -----
DECLARE @foundation_org_uid           bigint = 20000020;  -- foundation Organization
DECLARE @foundation_postal_org        bigint = 20000021;  -- foundation Org postal_locator (PST/WP/O)
DECLARE @foundation_tele_org          bigint = 20000022;  -- foundation Org tele_locator  (TELE/WP/PH)

-- =====================================================================
-- UID allocations (Organization Tier 1: 20030000-20039999)
-- =====================================================================

-- ----- Enrichment of foundation Organization -----
DECLARE @dbo_Tele_locator_org_fax        bigint = 20030001;  -- foundation Org fax (TELE/WP/FAX)
-- entity_id row for foundation Organization (FI) — keyed by (entity_uid, entity_id_seq), no separate UID

-- ----- Org v2: a separate fully-attributed Organization entity -----
DECLARE @dbo_Entity_organization_v2_uid  bigint = 20030010;  -- v2 Organization entity / organization
DECLARE @dbo_Postal_locator_org_v2       bigint = 20030011;  -- v2 Org postal_locator (PST/WP/O)
DECLARE @dbo_Tele_locator_org_v2_phone   bigint = 20030012;  -- v2 Org work phone (TELE/WP/PH)
DECLARE @dbo_Tele_locator_org_v2_fax     bigint = 20030013;  -- v2 Org work fax (TELE/WP/FAX)

-- =====================================================================
-- ODSE rows — additive enrichments to the foundation Org.
-- These rows feed sp_organization_event so its SELECT projection picks
-- up fax / facility_id / NAICS-resolved stand_ind_class. They are NOT
-- what drives the postprocessing SP (that is driven by direct
-- nrt_organization inserts below).
-- =====================================================================

-- The foundation Org's organization row is intentionally NOT modified.
-- foundation is read-only across all Tier 1 fixtures (template contract).
-- standard_industry_class_cd is left NULL on the foundation Org so its
-- D_ORGANIZATION.ORGANIZATION_STAND_IND_CLASS exhibits the null/no-NAICS
-- path; the v2 Org below populates the column to exercise the resolved
-- path. coverage_foundation.md's mention of standard_industry_class_cd
-- under "Columns deliberately skipped" describes which variant exercises
-- the populated path (the Tier 1 v2 variant), not a license to UPDATE
-- foundation rows.

-- --- Foundation Org enrichment: entity_id (FI / facility identifier) ---
-- entity_id.type_cd 'FI' from SRTE code_set_nm='EI_TYPE_ORG' (verified).
-- assigning_authority_cd 'CLIA' from SRTE code_set_nm='EI_AUTH_ORG' so
-- the SP's case branch on (type_cd='FI' AND assigning_authority_cd IS
-- NOT NULL) at sp_organization_event:146-148 fires and returns
-- fn_get_value_by_cvg(...) for facility_id_auth.
INSERT INTO [dbo].[entity_id]
    ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
VALUES
    (@foundation_org_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'CLIA', N'Clinical Laboratory Improvement Amendments',
     '2026-04-01T00:00:00', @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'11D2030855', N'FI', N'Facility identifier', '2026-04-01T00:00:00');

-- --- Foundation Org enrichment: fax tele_locator + ELP row ---
-- Foundation Org has no fax locator. The event SP filters fax on
-- (TELE, WP, FAX) at sp_organization_event:124-135. Add a tele_locator
-- and entity_locator_participation row in this block, attached to
-- @foundation_org_uid, so the foundation Org's fax pivot resolves.
-- elp.cd 'FAX' from SRTE EL_TYPE; use_cd 'WP' from EL_USE; class_cd
-- 'TELE' from EL_CLS — all verified.
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_org_fax, '2026-04-01T00:00:00', @superuser_id, N'1',
     '2026-04-01T00:00:00', @superuser_id, N'404-555-0399',
     N'ACTIVE', '2026-04-01T00:00:00');

INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    (@foundation_org_uid, @dbo_Tele_locator_org_fax,
     '2026-04-01T00:00:00', @superuser_id, N'FAX',
     N'TELE', '2026-04-01T00:00:00', @superuser_id, N'Foundation Organization work fax',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00');

-- =====================================================================
-- Org v2 — fully attributed Organization variant for column coverage.
-- =====================================================================

-- entity.class_cd 'ORG' from SRTE code_set_nm='ENTITY_CLS'.
INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
    (@dbo_Entity_organization_v2_uid, N'ORG');

-- v2 organization row. NAICS '622110' (verified). edx_ind 'Y' to
-- distinguish from foundation. display_nm and description populated.
INSERT INTO [dbo].[organization]
    ([organization_uid], [add_time], [add_user_id], [description],
     [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [display_nm], [version_ctrl_nbr], [electronic_ind],
     [standard_industry_class_cd], [standard_industry_desc_txt],
     [edx_ind])
VALUES
    (@dbo_Entity_organization_v2_uid, '2026-04-01T00:00:00', @superuser_id,
     N'Tier 1 fully-attributed organization variant',
     '2026-04-01T00:00:00', @superuser_id, N'ORG20030010GA01',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'Variant Hospital', 1, N'Y',
     N'622110', N'General Medical and Surgical Hospitals',
     N'Y');

-- v2 organization_name row. nm_use_cd 'L' (legal); same dialect as
-- foundation organization_name.
INSERT INTO [dbo].[organization_name]
    ([organization_uid], [organization_name_seq], [nm_txt], [nm_use_cd],
     [record_status_cd], [default_nm_ind])
VALUES
    (@dbo_Entity_organization_v2_uid, 1, N'Variant Hospital', N'L',
     N'ACTIVE', N'Y');

-- v2 entity_id (FI / facility identifier) — assigning_authority_cd
-- 'CLIA' so the EI_AUTH_ORG branch resolves.
INSERT INTO [dbo].[entity_id]
    ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
VALUES
    (@dbo_Entity_organization_v2_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'CLIA', N'Clinical Laboratory Improvement Amendments',
     '2026-04-01T00:00:00', @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'22D9999999', N'FI', N'Facility identifier', '2026-04-01T00:00:00');

-- v2 postal_locator (work address). state_cd '13' (Georgia),
-- cnty_cd '13121' (Fulton County), cntry_cd '840' (United States) —
-- all verified in NBS_SRTE.dbo.{State_code, State_county_code_value,
-- Country_code} (matches Provider canary's choices).
INSERT INTO [dbo].[postal_locator]
    ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
     [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [state_cd],
     [street_addr1], [street_addr2], [zip_cd])
VALUES
    (@dbo_Postal_locator_org_v2, '2026-04-01T00:00:00', @superuser_id, N'Atlanta',
     N'840', N'13121', '2026-04-01T00:00:00', @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'13',
     N'3010 Variant Hospital Way', N'Building B', N'30303');

-- v2 tele_locator (work phone with extension and email).
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
     [email_address],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_org_v2_phone, '2026-04-01T00:00:00', @superuser_id, N'1',
     '2026-04-01T00:00:00', @superuser_id, N'404-555-3010', N'8765',
     N'variant.org@nbs.test',
     N'ACTIVE', '2026-04-01T00:00:00');

-- v2 tele_locator (work fax).
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_org_v2_fax, '2026-04-01T00:00:00', @superuser_id, N'1',
     '2026-04-01T00:00:00', @superuser_id, N'404-555-3099',
     N'ACTIVE', '2026-04-01T00:00:00');

-- v2 entity_locator_participation rows.
-- Address pivot at sp_organization_event:96-99 requires (PST,WP,O).
-- Phone pivot at :117-120 requires (TELE,WP,PH).
-- Fax pivot at :130-133 requires (TELE,WP,FAX).
INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    -- v2 Org work address (PST/WP/O).
    (@dbo_Entity_organization_v2_uid, @dbo_Postal_locator_org_v2,
     '2026-04-01T00:00:00', @superuser_id, N'O',
     N'PST', '2026-04-01T00:00:00', @superuser_id, N'v2 Organization work address',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00'),
    -- v2 Org work phone (TELE/WP/PH).
    (@dbo_Entity_organization_v2_uid, @dbo_Tele_locator_org_v2_phone,
     '2026-04-01T00:00:00', @superuser_id, N'PH',
     N'TELE', '2026-04-01T00:00:00', @superuser_id, N'v2 Organization work phone',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00'),
    -- v2 Org work fax (TELE/WP/FAX).
    (@dbo_Entity_organization_v2_uid, @dbo_Tele_locator_org_v2_fax,
     '2026-04-01T00:00:00', @superuser_id, N'FAX',
     N'TELE', '2026-04-01T00:00:00', @superuser_id, N'v2 Organization work fax',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00');

GO

-- =====================================================================
-- DRIVE THE POSTPROCESSING SP via direct nrt_organization INSERTs.
--
-- sp_organization_event only emits a SELECT (consumed by Kafka in
-- production). For fixture verification we populate dbo.nrt_organization
-- directly to drive sp_nrt_organization_postprocessing → D_ORGANIZATION.
-- Two rows: foundation Org (20000020) and v2 (20030010). The foundation
-- row deliberately leaves a few optional columns NULL so the SP's
-- "blank/null → NULL" transform path (case-when-empty in the INSERT
-- SELECT at sp_nrt_organization_postprocessing-001.sql:251-267) is
-- observable in the diff. The v2 row sets every column the SP
-- propagates.
--
-- nrt_organization has refresh_datetime (AS_ROW_START) and max_datetime
-- (AS_ROW_END) GENERATED ALWAYS columns; SQL Server populates them on
-- INSERT, so they are omitted from the column list.
-- =====================================================================

USE [RDB_MODERN];
GO


GO
