USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 1 Place fixture
-- Baseline: 6.0.18.1 (post-liquibase) + fixtures/00_foundation/00_foundation.sql
--
-- WHAT THIS FIXTURE DOES
--   1. Enriches the foundation Place (UID 20000030) with:
--        - a new postal_locator + ELP row (PST, WP, PLC) so
--          sp_place_event's address pivot
--          (068-sp_place_event-001.sql:91-94 — USE_CD='WP', CD='PLC',
--          CLASS_CD='PST') has a row to find. Foundation's existing ELP
--          on its postal_locator (PST, H, H) does NOT match. We can't
--          add an additional ELP edge for the foundation postal_locator
--          (20000031) because the entity_locator_participation PK is
--          (entity_uid, locator_uid) — adding a second ELP row with the
--          same locator_uid collides. Instead allocate a new
--          postal_locator in this block and wire it to the foundation
--          Place via (PST, WP, PLC).
--        - a tele_locator + ELP row (TELE/WP/PH) so sp_place_event's
--          tele pivot (line 121, class_cd='TELE') has a row to find.
--          Foundation has no tele locator on Place at all.
--      Foundation place.cd is left NULL per the Tier 1 contract
--      (coverage_foundation.md flags it "Tier 1 place agent picks place
--      type" — that means the v2 variant exercises the populated branch,
--      NOT that we UPDATE the foundation row). The foundation Place
--      therefore exhibits the SP's null-place-type / no-PLACE_TYPE_DESCRIPTION
--      branch.
--   2. Adds a fully-attributed Place v2 variant (UID 20040010) with
--      place.cd='M' (Motel/Hotel from PLACE_TYPE) so every D_PLACE
--      column the postprocessing SP propagates is populated for at
--      least one Place. v2 has its own postal_locator and tele_locator,
--      both wired via (PST,WP,PLC) and (TELE,WP,PH) ELP rows.
--   3. Populates dbo.nrt_place AND dbo.nrt_place_tele in RDB_MODERN
--      directly. Place is the FIRST subject with TWO staging tables:
--      sp_nrt_place_postprocessing LEFT JOINs nrt_place_tele on
--      place_uid (line 103). Tele rows must be present for
--      PLACE_TELE_LOCATOR_UID / PLACE_PHONE / PLACE_EMAIL etc. to be
--      non-NULL on D_PLACE. The event SP only emits a SELECT (consumed
--      by Kafka in production); kafka-connect would normally write
--      both nrt_place and nrt_place_tele. For fixture verification we
--      bypass that and write both staging rows by hand.
--      Without these direct INSERTs the postprocessing SP returns
--      "Missing NRT Record" and never writes D_PLACE.
--
-- UID block (Place Tier 1): 20040000-20049999.
-- Foundation dependencies (read-only):
--   @dbo_Entity_place_uid       20000030  (entity / place)
--   @dbo_Postal_locator_place   20000031  (PST/H/H — read-only; not
--                                          referenced as the event SP's
--                                          (PST,WP,PLC) address pivot
--                                          locator since the ELP filter
--                                          requires use_cd='WP'/cd='PLC').
-- =====================================================================

-- ----- Sentinel reference (do not allocate — assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- USER_PROFILE-resolvable ids (for D_PLACE.PLACE_ADDED_BY / PLACE_LAST_UPDATED_BY).
-- The postprocessing SP joins nrt.place_add_user_id = USER_PROFILE.nedss_entry_id
-- (sp_nrt_place_postprocessing-001.sql:104-107). Picking a baseline-seeded id
-- so v2 exhibits the populated path. Foundation Place uses a non-matching id
-- so its PLACE_ADDED_BY exercises the NULL/no-match path.
DECLARE @user_profile_id_v2 bigint = 10003000; -- 'Nelson, Jay' in baseline USER_PROFILE

-- ----- Foundation dependencies referenced (read-only) -----
DECLARE @foundation_place_uid          bigint = 20000030;  -- foundation Place entity / place
DECLARE @foundation_postal_place       bigint = 20000031;  -- foundation Place postal_locator (PST/H/H)

-- =====================================================================
-- UID allocations (Place Tier 1: 20040000-20049999)
-- =====================================================================

-- ----- Enrichment of foundation Place -----
DECLARE @dbo_Postal_locator_place_wp      bigint = 20040000;  -- foundation Place work-place postal_locator (PST/WP/PLC)
DECLARE @dbo_Tele_locator_place_phone     bigint = 20040001;  -- foundation Place work phone (TELE/WP/PH)

-- ----- Place v2: a separate fully-attributed Place entity -----
DECLARE @dbo_Entity_place_v2_uid          bigint = 20040010;  -- v2 Place entity / place
DECLARE @dbo_Postal_locator_place_v2      bigint = 20040011;  -- v2 Place postal_locator (PST/WP/PLC)
DECLARE @dbo_Tele_locator_place_v2_phone  bigint = 20040012;  -- v2 Place work phone (TELE/WP/PH)
DECLARE @dbo_Tele_locator_place_v2_fax    bigint = 20040013;  -- v2 Place work fax (TELE/WP/FAX)

-- =====================================================================
-- ODSE rows — additive enrichments to the foundation Place.
-- These rows feed sp_place_event so its SELECT projection's address /
-- tele JSON branches resolve. They are NOT what drives the
-- postprocessing SP (that is driven by direct nrt_place / nrt_place_tele
-- INSERTs below).
-- =====================================================================

-- The foundation Place's place row is intentionally NOT modified.
-- foundation is read-only across all Tier 1 fixtures (template contract).
-- place.cd / place.cd_desc_txt remain NULL on the foundation row so its
-- D_PLACE.PLACE_TYPE_DESCRIPTION exhibits the null/blank-place-type
-- path; the v2 Place below sets cd='M' (PLACE_TYPE) to exercise the
-- resolved path. coverage_foundation.md's mention of place.cd under
-- "Columns deliberately skipped" describes which variant exercises the
-- populated path (the Tier 1 v2 variant), not a license to UPDATE the
-- foundation row.

-- --- Foundation Place enrichment: (PST,WP,PLC) postal_locator + ELP ---
-- The event SP filters address on (PST, WP, PLC) at lines 91-94.
-- Foundation's existing (PST,H,H) ELP on postal_locator 20000031 does
-- NOT match the filter. The ELP table's PK is (entity_uid, locator_uid),
-- so we cannot add a second ELP row for postal_locator 20000031 with a
-- different (use_cd, cd) tuple. Allocate a new postal_locator in this
-- block instead and wire it to the foundation Place via (PST,WP,PLC).
-- elp.cd 'PLC' from SRTE EL_TYPE_PST_PLC (verified — the event SP
-- exposes this code via fn_get_value_by_cvg(..., 'EL_TYPE_PST_PLC')).
-- elp.use_cd 'WP' from SRTE EL_USE (verified).
INSERT INTO [dbo].[postal_locator]
    ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
     [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [state_cd],
     [street_addr1], [zip_cd])
VALUES
    (@dbo_Postal_locator_place_wp, '2026-04-01T00:00:00', @superuser_id, N'Atlanta',
     N'840', N'13121', '2026-04-01T00:00:00', @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00', N'13',
     N'400 Place Avenue', N'30303');

INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    -- Foundation Place work-place (PST/WP/PLC) ELP edge for the event SP's address pivot.
    (@foundation_place_uid, @dbo_Postal_locator_place_wp,
     '2026-04-01T00:00:00', @superuser_id, N'PLC',
     N'PST', '2026-04-01T00:00:00', @superuser_id, N'Foundation Place work-place address',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00');

-- --- Foundation Place enrichment: tele_locator + ELP (TELE/WP/PH) ---
-- Foundation Place has no tele locator. The event SP filters tele on
-- (TELE, *, *) at line 121 (class_cd='TELE' only). Add a tele_locator
-- and an ELP row in this block, attached to @foundation_place_uid, so
-- the foundation Place's tele pivot resolves and the synthetic
-- nrt_place_tele row written below has a corresponding ODSE locator.
-- elp.cd 'PH' from SRTE EL_TYPE_TELE_PLC (verified — the event SP
-- exposes this code via fn_get_value_by_cvg(..., 'EL_TYPE_TELE_PLC'));
-- elp.use_cd 'WP' from SRTE EL_USE_TELE_PLC (verified — the only code in
-- that code set); elp.class_cd 'TELE' from SRTE EL_CLS (verified).
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_place_phone, '2026-04-01T00:00:00', @superuser_id, N'1',
     '2026-04-01T00:00:00', @superuser_id, N'404-555-0400',
     N'ACTIVE', '2026-04-01T00:00:00');

INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    (@foundation_place_uid, @dbo_Tele_locator_place_phone,
     '2026-04-01T00:00:00', @superuser_id, N'PH',
     N'TELE', '2026-04-01T00:00:00', @superuser_id, N'Foundation Place work phone',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00');

-- =====================================================================
-- Place v2 — fully attributed Place variant for column coverage.
-- =====================================================================

-- entity.class_cd 'PLC' from SRTE code_set_nm='ENTITY_CLS'.
INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
    (@dbo_Entity_place_v2_uid, N'PLC');

-- v2 place row. cd 'M' (Motel/Hotel from PLACE_TYPE) — exercises the
-- populated place-type branch. Every column the SP propagates is
-- populated. Note that nm_degree-style columns don't apply to place;
-- description / cd_desc_txt / nm / local_id / address denormals are the
-- main shape columns. add_user_id is set to @user_profile_id_v2 so the
-- USER_PROFILE join in sp_nrt_place_postprocessing-001.sql:104-107
-- resolves and PLACE_ADDED_BY / PLACE_LAST_UPDATED_BY are populated.
INSERT INTO [dbo].[place]
    ([place_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [description],
     [last_chg_time], [last_chg_user_id], [local_id], [nm],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [street_addr1], [street_addr2], [city_desc_txt], [state_cd], [zip_cd],
     [cnty_cd], [cntry_cd], [version_ctrl_nbr])
VALUES
    (@dbo_Entity_place_v2_uid, '2026-04-01T00:00:00', @user_profile_id_v2,
     N'M', N'Motel/Hotel',
     N'Tier 1 fully-attributed place variant',
     '2026-04-01T00:00:00', @user_profile_id_v2, N'PLC20040010GA01', N'Variant Motel',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'4010 Variant Motel Drive', N'Suite 200', N'Atlanta', N'13', N'30303',
     N'13121', N'840', 1);

-- v2 entity_id (QEC — Quick Entry Code). The event SP at lines 64-69
-- pivots an entity_id row with type_cd='QEC' and emits root_extension_txt
-- as place_quick_code. Adding this row ensures the JSON projection's
-- entity branch resolves on v2; PLACE_QUICK_CODE on D_PLACE is driven
-- by the hand-authored nrt_place row below, not by this entity_id row.
INSERT INTO [dbo].[entity_id]
    ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
VALUES
    (@dbo_Entity_place_v2_uid, 1, '2026-04-01T00:00:00', @user_profile_id_v2,
     NULL, NULL,
     '2026-04-01T00:00:00', @user_profile_id_v2,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'PLC-V2-QEC', N'QEC', N'Quick Entry Code', '2026-04-01T00:00:00');

-- v2 postal_locator (work-place address). state_cd '13' (GA),
-- cnty_cd '13121' (Fulton County), cntry_cd '840' (United States) —
-- all verified.
INSERT INTO [dbo].[postal_locator]
    ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
     [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [state_cd],
     [street_addr1], [street_addr2], [zip_cd])
VALUES
    (@dbo_Postal_locator_place_v2, '2026-04-01T00:00:00', @user_profile_id_v2, N'Atlanta',
     N'840', N'13121', '2026-04-01T00:00:00', @user_profile_id_v2,
     N'ACTIVE', '2026-04-01T00:00:00', N'13',
     N'4010 Variant Motel Drive', N'Suite 200', N'30303');

-- v2 tele_locator (work phone with extension and email).
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
     [email_address],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_place_v2_phone, '2026-04-01T00:00:00', @user_profile_id_v2, N'1',
     '2026-04-01T00:00:00', @user_profile_id_v2, N'404-555-4010', N'5678',
     N'variant.place@nbs.test',
     N'ACTIVE', '2026-04-01T00:00:00');

-- v2 tele_locator (work fax) — additional locator to demonstrate the
-- (TELE, *, FAX) shape; this is shape-only on the ODSE side. The
-- postprocessing SP only joins nrt_place to nrt_place_tele on place_uid
-- and propagates whatever PLACE_PHONE / PLACE_EMAIL / PLACE_PHONE_EXT
-- the staging row carries; we set those from the phone tele_locator on
-- the synthetic staging row, not the fax.
INSERT INTO [dbo].[tele_locator]
    ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
     [last_chg_time], [last_chg_user_id], [phone_nbr_txt],
     [record_status_cd], [record_status_time])
VALUES
    (@dbo_Tele_locator_place_v2_fax, '2026-04-01T00:00:00', @user_profile_id_v2, N'1',
     '2026-04-01T00:00:00', @user_profile_id_v2, N'404-555-4099',
     N'ACTIVE', '2026-04-01T00:00:00');

-- v2 entity_locator_participation rows.
-- Address pivot at sp_place_event:91-94 requires (PST, WP, PLC).
-- Tele pivot at :121 requires class_cd='TELE' only — additional fax row
-- exercises the FAX EL_TYPE_TELE_PLC code.
INSERT INTO [dbo].[entity_locator_participation]
    ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
     [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [use_cd], [version_ctrl_nbr], [as_of_date])
VALUES
    -- v2 Place work-place address (PST/WP/PLC).
    (@dbo_Entity_place_v2_uid, @dbo_Postal_locator_place_v2,
     '2026-04-01T00:00:00', @user_profile_id_v2, N'PLC',
     N'PST', '2026-04-01T00:00:00', @user_profile_id_v2, N'v2 Place work-place address',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00'),
    -- v2 Place work phone (TELE/WP/PH).
    (@dbo_Entity_place_v2_uid, @dbo_Tele_locator_place_v2_phone,
     '2026-04-01T00:00:00', @user_profile_id_v2, N'PH',
     N'TELE', '2026-04-01T00:00:00', @user_profile_id_v2, N'v2 Place work phone',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00'),
    -- v2 Place work fax (TELE/WP/FAX) — shape coverage on the ODSE side.
    (@dbo_Entity_place_v2_uid, @dbo_Tele_locator_place_v2_fax,
     '2026-04-01T00:00:00', @user_profile_id_v2, N'FAX',
     N'TELE', '2026-04-01T00:00:00', @user_profile_id_v2, N'v2 Place work fax',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'WP', 1, '2026-04-01T00:00:00');

GO

-- =====================================================================
-- DRIVE THE POSTPROCESSING SP via direct nrt_place + nrt_place_tele INSERTs.
--
-- sp_place_event only emits a SELECT (consumed by Kafka in production).
-- For fixture verification we populate dbo.nrt_place AND dbo.nrt_place_tele
-- directly to drive sp_nrt_place_postprocessing → D_PLACE. Two place_uids:
-- foundation Place (20000030) and v2 Place (20040010). The foundation row
-- deliberately leaves several optional columns NULL so the SP's
-- "blank/null → NULL" transform path is observable in the diff. The v2
-- row sets every column the SP propagates.
--
-- nrt_place AND nrt_place_tele both have refresh_datetime (AS_ROW_START)
-- and max_datetime (AS_ROW_END) GENERATED ALWAYS columns; SQL Server
-- populates them on INSERT, so they are omitted from the column lists.
-- =====================================================================

USE [RDB_MODERN];
GO

-- nrt_place: one row per place_uid. Mirrors the JSON projection emitted
-- by sp_place_event, flattened into the columnar shape kafka-connect's
-- JDBC sink would write.

-- nrt_place_tele: tele staging table. The postprocessing SP LEFT JOINs
-- on place_uid (line 103). Add one tele row per place_uid so PLACE_PHONE
-- / PLACE_EMAIL / PLACE_TELE_LOCATOR_UID etc. are populated for at least
-- one variant. Foundation row keeps email NULL to exercise the null-email
-- branch. v2 sets every column.

GO
