USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 2 link fixture: Contact cross-subject edges (nbs_act_entity).
--   Edge type 1: 'SiteOfExposure'        (Contact -> Place; exposure site)
--   Edge type 2: 'InvestgrOfContact'     (Contact -> Provider/Person; investigator)
--   Edge type 3: 'DispoInvestgrOfConRec' (Contact -> Provider/Person; disposition investigator)
--
-- All three edge types live on dbo.nbs_act_entity (NOT participation,
-- NOT act_relationship). This is the FOURTH nbs_act_entity edge agent
-- (after vaccination_links 21007000-21007999, interview_links
-- 21008000-21008999, phc_roles_nae 21009000-21009999) and the
-- ELEVENTH Tier 2 agent overall. Same IDENTITY-column wrap pattern
-- as siblings: nbs_act_entity_uid is a bigint NOT NULL IDENTITY
-- column, so the INSERT is wrapped in
-- SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF to allow explicit
-- UID allocation from this agent's block.
--
-- All three type_cds are MISSING_FROM_SRTE per Phase B's
-- catalog/edge_types.md (no parent code_value_general row in baseline
-- nbs_srte; rows 369-371 of catalog/edge_types.md). RTR's
-- sp_contact_record_event filters on the literal type_cd values
-- directly (lines 155-157 of 069-sp_contact_record_event-001.sql),
-- so the ODSE rows wired here would drive the SP behavior. This
-- matches the documented "MISSING_FROM_SRTE" Phase B policy: author
-- with the literal type_cd values.
--
-- COVERAGE SHAPE -- IMPORTANT (matches interview_links / phc_roles_nae,
-- with one critical caveat):
--   The three SP joins at lines 155-157 of
--   069-sp_contact_record_event-001.sql are LEFT OUTER JOINs:
--
--     left outer join nbs_odse.dbo.NBS_ACT_ENTITY act_entities1
--       on cc.CT_CONTACT_UID = act_entities1.ACT_UID
--       and act_entities1.TYPE_CD='SiteOfExposure'
--     left outer join nbs_odse.dbo.NBS_ACT_ENTITY act_entities2
--       on cc.CT_CONTACT_UID = act_entities2.ACT_UID
--       and act_entities2.TYPE_CD='InvestgrOfContact'
--     left outer join nbs_odse.dbo.NBS_ACT_ENTITY act_entities3
--       on cc.CT_CONTACT_UID = act_entities3.ACT_UID
--       and act_entities3.TYPE_CD='DispoInvestgrOfConRec'
--
--   So the event SP would return rows at Tier 1 isolation regardless of
--   these edges, were it runnable. CRITICAL CAVEAT:
--   sp_contact_record_event is BROKEN UPSTREAM in baseline 6.0.18.1 —
--   it references nbs_odse.dbo.fn_get_value_by_cd_codeset but that
--   function actually lives in RDB_MODERN.dbo.fn_get_value_by_cd_codeset.
--   The SP fails at parse time on every input. See
--   coverage/coverage_contact.md "OUT_OF_SCOPE_RTR_BUG" section. This
--   means we CANNOT tail-EXEC sp_contact_record_event to verify the
--   wiring drives the SP's #CONTACT_RECORD_INIT projection.
--
--   Furthermore, the Contact postprocessing SPs
--   (sp_d_contact_record_postprocessing,
--   sp_f_contact_record_case_postprocessing) read from nrt_contact
--   staging directly (CONTACT_EXPOSURE_SITE_UID,
--   PROVIDER_CONTACT_INVESTIGATOR_UID, DISPOSITIONED_BY_UID) and do NOT
--   traverse nbs_act_entity. So these edges have **zero RDB_MODERN
--   dim/fact column unlocks at Tier 1 isolation OR in the merged
--   sequence** until the upstream RTR bug is fixed.
--
--   The PRIMARY value of this edge:
--     1. ODSE graph correctness for the RDB-vs-RDB_MODERN comparison
--        test against MasterETL — MasterETL likely traverses
--        nbs_act_entity to derive analogous Contact-participant
--        linkages on the RDB side, even though RTR currently does not
--        reach them.
--     2. Future-proofing: once the upstream sp_contact_record_event
--        bug is fixed (function aliased into NBS_ODSE or SP body
--        rewritten with RDB_MODERN qualifier), the #CONTACT_RECORD_INIT
--        projection would surface CONTACT_EXPOSURE_SITE_UID /
--        PROVIDER_CONTACT_INVESTIGATOR_UID / DISPOSITIONED_BY_UID via
--        these wired rows — but at that future time, the postprocessing
--        SPs would still read soft-refs from nrt_contact, so the dim
--        column populations would be unchanged. The event SP's JSON
--        projection (consumed by Kafka in production) is the only
--        downstream that benefits.
--
-- Wires (6 nbs_act_entity rows total):
--   SiteOfExposure (Contact -> Place, exposure site):
--     1) (21010000) foundation Contact 20000170 -> foundation Place 20000030
--     2) (21010001) v2 Contact         20120010 -> foundation Place 20000030
--   InvestgrOfContact (Contact -> Provider, investigator):
--     3) (21010002) foundation Contact 20000170 -> foundation Provider 20000010
--     4) (21010003) v2 Contact         20120010 -> v2 Provider         20010010
--   DispoInvestgrOfConRec (Contact -> Provider, disposition investigator):
--     5) (21010004) foundation Contact 20000170 -> foundation Provider 20000010
--     6) (21010005) v2 Contact         20120010 -> v2 Provider         20010010
--
-- Both v2 Contact rows wire to the foundation Place (no v2 Place
-- variant exists in Place Tier 1; v1 simplification per the per-edge
-- prompt). Same Provider serves both InvestgrOfContact and
-- DispoInvestgrOfConRec for v1 simplification (could be a different
-- provider per role in production).
--
-- Catalog citations (catalog/edge_types.md, dbo.nbs_act_entity rows
-- 131-133 and act_relationship-style rows 369-371):
--   * 'SiteOfExposure' (Act endpoint=CT_contact (ENC), Entity endpoint=Place)
--     - Used By: sp_contact_record_event (broken upstream).
--     - SP filter site: 069-sp_contact_record_event-001.sql:155
--       (LEFT JOIN act_entities1 ON CT_CONTACT_UID=ACT_UID
--                                AND TYPE_CD='SiteOfExposure').
--     - SRTE PAR_TYPE: MISSING_FROM_SRTE.
--   * 'InvestgrOfContact' (Act endpoint=CT_contact (ENC), Entity endpoint=Person/PSN)
--     - Used By: sp_contact_record_event (broken upstream).
--     - SP filter site: 069-sp_contact_record_event-001.sql:156
--       (LEFT JOIN act_entities2 ON ... AND TYPE_CD='InvestgrOfContact').
--     - SRTE PAR_TYPE: MISSING_FROM_SRTE.
--   * 'DispoInvestgrOfConRec' (Act endpoint=CT_contact (ENC), Entity endpoint=Person/PSN)
--     - Used By: sp_contact_record_event (broken upstream).
--     - SP filter site: 069-sp_contact_record_event-001.sql:157
--       (LEFT JOIN act_entities3 ON ... AND TYPE_CD='DispoInvestgrOfConRec').
--     - SRTE PAR_TYPE: MISSING_FROM_SRTE.
--
-- UID block (Tier 2 - eleventh agent): 21010000 - 21010999.
-- Allocated 6 UIDs (21010000-21010005). Unused 21010006-21010999
-- reserved for future amendments.
--
-- Forbidden in Tier 2 (per template):
--   - No new ODSE entity rows; no SRTE writes; no foundation/Tier 1
--     modifications; no INSERTs into RDB_MODERN dim/fact tables; no
--     infrastructure-SP invocation in this fixture (orchestrator owns
--     sp_get_date_dim and sp_nrt_srte_condition_code_postprocessing
--     per Merge contract step 2).
--
-- nbs_act_entity NOT-NULL columns (verified via INFORMATION_SCHEMA.COLUMNS,
-- consistent with vaccination_links / interview_links / phc_roles_nae):
--   nbs_act_entity_uid (bigint), act_uid (bigint), add_time (datetime),
--   add_user_id (bigint), entity_uid (bigint),
--   entity_version_ctrl_nbr (smallint), last_chg_time (datetime),
--   last_chg_user_id (bigint), record_status_cd (varchar),
--   record_status_time (datetime).
-- Nullable: type_cd (varchar) -- but populated explicitly because the
-- SP filters on it directly via the LEFT JOIN ON clauses.
--
-- IDENTITY note: nbs_act_entity_uid is an IDENTITY column in the
-- baseline schema. To insert explicit UIDs from this agent's allocated
-- block, the INSERT must be wrapped in
-- SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF.
-- Pattern is identical to vaccination_links.sql / interview_links.sql /
-- phc_roles_nae.sql.
-- =====================================================================

-- ----- Sentinel reference (do not allocate -- assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;          -- conventional NBS superuser id

-- ----- Cross-tier UIDs referenced (read-only) -----
DECLARE @foundation_act_contact_uid      bigint = 20000170;  -- foundation Contact act_uid / ct_contact_uid
DECLARE @foundation_entity_place_uid     bigint = 20000030;  -- foundation Place entity_uid
DECLARE @foundation_entity_provider_uid  bigint = 20000010;  -- foundation Provider entity_uid / person_uid
DECLARE @v2_act_contact_uid              bigint = 20120010;  -- v2 Contact (Contact Tier 1)
DECLARE @v2_entity_provider_uid          bigint = 20010010;  -- v2 Provider (Provider Tier 1)

-- ----- Surrogate UIDs allocated from this agent's block -----
DECLARE @site_exposure_foundation_uid    bigint = 21010000;  -- SiteOfExposure foundation
DECLARE @site_exposure_v2_uid            bigint = 21010001;  -- SiteOfExposure v2 (uses foundation Place)
DECLARE @investgr_foundation_uid         bigint = 21010002;  -- InvestgrOfContact foundation
DECLARE @investgr_v2_uid                 bigint = 21010003;  -- InvestgrOfContact v2
DECLARE @dispo_investgr_foundation_uid   bigint = 21010004;  -- DispoInvestgrOfConRec foundation
DECLARE @dispo_investgr_v2_uid           bigint = 21010005;  -- DispoInvestgrOfConRec v2

-- =====================================================================
-- nbs_act_entity rows.
--
-- entity_version_ctrl_nbr is set to 1 by NBS convention (smallint;
-- versioning starts at 1 for new rows).
-- record_status_cd='ACTIVE' for shape-consistency parity with sibling
-- nbs_act_entity Tier 2 fixtures (the LEFT JOINs at lines 155-157 of
-- 069-sp_contact_record_event-001.sql have no record_status_cd
-- predicate — value does not affect SP behavior, but kept consistent).
-- type_cd populated explicitly (the SP filters on it directly via the
-- LEFT JOIN ON clause).
-- =====================================================================
SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON;

INSERT INTO [dbo].[nbs_act_entity]
    ([nbs_act_entity_uid], [act_uid], [entity_uid], [type_cd],
     [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    -- Edge 1 (21010000): SiteOfExposure, foundation Contact -> foundation Place
    -- Drives sp_contact_record_event #CONTACT_RECORD_INIT.<exposure-site>
    -- projection via the LEFT JOIN act_entities1 at line 155 of
    -- 069-sp_contact_record_event-001.sql. (The SP is broken upstream
    -- so this row does not actually flow through to coverage at Tier 1
    -- or merged sequence — see header comment.)
    (@site_exposure_foundation_uid,             -- nbs_act_entity_uid (surrogate)
     @foundation_act_contact_uid,               -- act_uid (ENC; foundation Contact / ct_contact)
     @foundation_entity_place_uid,              -- entity_uid (Place; foundation Place)
     N'SiteOfExposure',                         -- type_cd (MISSING_FROM_SRTE; SP filters on literal)
     1,                                         -- entity_version_ctrl_nbr (smallint)
     '2026-04-01T00:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     CAST(GETDATE() AS DATE),                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-01T00:00:00'),                    -- record_status_time
    -- Edge 2 (21010001): SiteOfExposure, v2 Contact -> foundation Place
    -- v1 simplification: no v2 Place variant exists, so v2 Contact
    -- wires to the same foundation Place. Drives the same projection
    -- for the v2 Contact row.
    (@site_exposure_v2_uid,                     -- nbs_act_entity_uid
     @v2_act_contact_uid,                       -- act_uid (ENC; v2 Contact)
     @foundation_entity_place_uid,              -- entity_uid (Place; foundation Place — v1 simplification)
     N'SiteOfExposure',                         -- type_cd
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-15T10:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     CAST(GETDATE() AS DATE),                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-15T10:00:00'),                    -- record_status_time
    -- Edge 3 (21010002): InvestgrOfContact, foundation Contact -> foundation Provider
    -- Drives sp_contact_record_event #CONTACT_RECORD_INIT.<investigator>
    -- projection via the LEFT JOIN act_entities2 at line 156.
    (@investgr_foundation_uid,                  -- nbs_act_entity_uid
     @foundation_act_contact_uid,               -- act_uid (ENC; foundation Contact)
     @foundation_entity_provider_uid,           -- entity_uid (PSN/PRV; foundation Provider)
     N'InvestgrOfContact',                      -- type_cd (MISSING_FROM_SRTE; SP filters on literal)
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-01T00:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     CAST(GETDATE() AS DATE),                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-01T00:00:00'),                    -- record_status_time
    -- Edge 4 (21010003): InvestgrOfContact, v2 Contact -> v2 Provider
    -- Drives investigator projection for v2 Contact row.
    (@investgr_v2_uid,                          -- nbs_act_entity_uid
     @v2_act_contact_uid,                       -- act_uid (ENC; v2 Contact)
     @v2_entity_provider_uid,                   -- entity_uid (PSN/PRV; v2 Provider)
     N'InvestgrOfContact',                      -- type_cd
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-15T10:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     CAST(GETDATE() AS DATE),                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-15T10:00:00'),                    -- record_status_time
    -- Edge 5 (21010004): DispoInvestgrOfConRec, foundation Contact -> foundation Provider
    -- Drives sp_contact_record_event #CONTACT_RECORD_INIT.<dispo-investigator>
    -- projection via the LEFT JOIN act_entities3 at line 157. Same
    -- Provider as InvestgrOfContact for v1 simplification (could be a
    -- distinct provider per role in production).
    (@dispo_investgr_foundation_uid,            -- nbs_act_entity_uid
     @foundation_act_contact_uid,               -- act_uid (ENC; foundation Contact)
     @foundation_entity_provider_uid,           -- entity_uid (PSN/PRV; foundation Provider)
     N'DispoInvestgrOfConRec',                  -- type_cd (MISSING_FROM_SRTE; SP filters on literal)
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-01T00:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     CAST(GETDATE() AS DATE),                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-01T00:00:00'),                    -- record_status_time
    -- Edge 6 (21010005): DispoInvestgrOfConRec, v2 Contact -> v2 Provider
    -- Drives dispo-investigator projection for v2 Contact row.
    (@dispo_investgr_v2_uid,                    -- nbs_act_entity_uid
     @v2_act_contact_uid,                       -- act_uid (ENC; v2 Contact)
     @v2_entity_provider_uid,                   -- entity_uid (PSN/PRV; v2 Provider)
     N'DispoInvestgrOfConRec',                  -- type_cd
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-15T10:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     CAST(GETDATE() AS DATE),                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-15T10:00:00');                    -- record_status_time

SET IDENTITY_INSERT [dbo].[nbs_act_entity] OFF;
GO

-- =====================================================================
-- Post-edge SP re-run -- DELIBERATELY OMITTED.
--
-- We do NOT tail-EXEC sp_contact_record_event because that SP is BROKEN
-- UPSTREAM in baseline 6.0.18.1 -- it references
-- nbs_odse.dbo.fn_get_value_by_cd_codeset but the function actually
-- lives in RDB_MODERN.dbo.fn_get_value_by_cd_codeset (verified across
-- all 5 baseline DBs; only RDB_MODERN has it). The SP fails at parse
-- time on every input -- leaving CONTACT_STATUS NULL on every ct_contact
-- row does NOT short-circuit the parse error because SQL Server
-- resolves object names at parse time for the entire SELECT, regardless
-- of CASE branch evaluation. See coverage/coverage_contact.md
-- "OUT_OF_SCOPE_RTR_BUG" section for full diagnosis.
--
-- We also do NOT re-run sp_d_contact_record_postprocessing or
-- sp_f_contact_record_case_postprocessing because their input
-- (nrt_contact) is hand-authored by Tier 1 and they do NOT traverse
-- nbs_act_entity. D_CONTACT_RECORD (2 rows, 41 SP-write columns
-- populated) and F_CONTACT_RECORD_CASE (2 rows, 11/11 columns populated
-- with sentinel-1 cross-FKs) populations are byte-identical pre/post-
-- edge.
--
-- The merge orchestrator therefore has no Tier 1 chain to re-run for
-- this edge type. The fixture's value is purely shape-consistency for
-- the eventual RDB-vs-RDB_MODERN comparison test against MasterETL.
--
-- Verification of this fixture's apply correctness is a simple SELECT
-- against dbo.nbs_act_entity:
--   SELECT type_cd, COUNT(*) FROM dbo.nbs_act_entity
--   WHERE type_cd IN ('SiteOfExposure','InvestgrOfContact',
--                     'DispoInvestgrOfConRec')
--   GROUP BY type_cd;
-- Expected: 3 rows, 2 each.
-- =====================================================================
