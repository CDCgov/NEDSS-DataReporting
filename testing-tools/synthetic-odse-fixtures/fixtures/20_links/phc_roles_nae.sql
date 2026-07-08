USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 2 link fixture: PHC role edges (nbs_act_entity).
--   Edge type 1: 'PerAsReporterOfPHC' (Investigation -> Provider/Person -- person-as-reporter)
--   Edge type 2: 'OrgAsReporterOfPHC' (Investigation -> Organization     -- org-as-reporter)
--   Edge type 3: 'HospOfADT'          (Investigation -> Organization     -- hospital of ADT)
--
-- All three edge types live on dbo.nbs_act_entity. This is the THIRD
-- nbs_act_entity edge agent (after vaccination_links 21007000-21007999
-- and interview_links 21008000-21008999) and the TENTH Tier 2 agent
-- overall. Same IDENTITY-column wrap pattern as the two prior siblings:
-- nbs_act_entity_uid is a bigint NOT NULL IDENTITY column, so the INSERT
-- is wrapped in SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF to
-- allow explicit UID allocation from this agent's block.
--
-- ARCHITECTURAL DISTINCTION FROM `reporter_phc` (NOT a duplicate):
--   The `reporter_phc` agent (sixth Tier 2 agent, 21005000-21005999)
--   already authored 4 dbo.participation rows for PerAsReporterOfPHC +
--   OrgAsReporterOfPHC. THIS agent authors complementary rows in
--   dbo.nbs_act_entity for the SAME source/target endpoints. Both are
--   required for full coverage because they feed different downstream
--   consumers:
--     1. participation rows surface in:
--        - sp_investigation_event person_participations /
--          organization_participations JSON branches (event SP lines
--          ~339-375).
--        - sp_public_health_case_fact_datamart_event/_update
--          (072/073) INNER JOINs filtered by
--          TYPE_CD IN ('OrgAsReporterOfPHC','InvestgrOfPHC',
--                      'PerAsReporterOfPHC','PhysicianOfPHC')
--          which feed F_PAGE_CASE.REPORTER_NAME / REPORTER_PHONE /
--          ORGANIZATION_NAME at Merge step 9.
--     2. nbs_act_entity rows surface in:
--        - sp_investigation_event CASE-pivot subquery at lines 909-934
--          which materializes the `investigation_act_entity` aliased
--          subquery and projects:
--            * person_as_reporter_uid (line 913, type_cd='PerAsReporterOfPHC')
--            * hospital_uid           (line 914, type_cd='HospOfADT')
--            * org_as_reporter_uid    (line 932, type_cd='OrgAsReporterOfPHC')
--          and 17 other *_of_phc_uid columns (deferred to Tier 3).
--          These columns are SELECTed at lines 137/140/141/171 of the
--          event SP into the Investigation_Dim_Event projection.
--        - F_PAGE_CASE consumes hospital_uid downstream at Merge
--          step 9 (datamart-side; out of scope for this Tier 2 agent's
--          verification).
--
--   The participation table and nbs_act_entity table are different
--   connective tables in the ODSE schema: each row in one does NOT
--   imply a row in the other. The investigation_event SP queries
--   participation directly (for the person_participations /
--   organization_participations JSON branches) AND nbs_act_entity
--   directly (for the investigation_act_entity CASE-pivot subquery).
--   To populate BOTH JSON branches AND the per-Investigation reporter
--   UID columns, BOTH tables must have the matching rows. Authoring
--   in only one would leave half the projection NULL — see
--   `coverage_reporter_phc.md` "Coverage still LINK_REQUIRED" section
--   which explicitly defers the nbs_act_entity rows to a separate
--   Tier 2 agent (this one).
--
-- DEFERRED TO TIER 3 (the other 17 roles in the same CASE pivot):
--   OrgAsClinicOfPHC (915), CASupervisorOfPHC (916),
--   ClosureInvestgrOfPHC (917), DispoFldFupInvestgrOfPHC (918),
--   FldFupInvestgrOfPHC (919), FldFupProvOfPHC (920),
--   FldFupSupervisorOfPHC (921), InitFldFupInvestgrOfPHC (922),
--   InitFupInvestgrOfPHC (923), InitInterviewerOfPHC (924),
--   InterviewerOfPHC (925), SurvInvestgrOfPHC (926),
--   FldFupFacilityOfPHC (927), OrgAsHospitalOfDelivery (928),
--   PerAsProviderOfDelivery (929), PerAsProviderOfOBGYN (930),
--   PerAsProvideroOfPediatrics (931, typo preserved per SP literal).
--   All 17 are MISSING_FROM_SRTE per Phase B's catalog/edge_types.md.
--   The CASE pivot uses LEFT JOIN against nbs_act_entity at line 909,
--   so missing rows just leave the corresponding *_of_phc_uid columns
--   NULL — the SP does not error.
--
-- COVERAGE SHAPE -- IMPORTANT (similar to interview_links, NOT
-- vaccination_links):
--   The investigation_act_entity subquery at lines 909-934 is a
--   LEFT JOIN at line 909 (joined ON .nac_page_case_uid = phc.public_health_case_uid).
--   So sp_investigation_event returns rows at Tier 1 isolation
--   regardless of these edges. Pre-edge, the JSON projection's
--   `investigation_act_entity` columns project as NULL on every row
--   (the LEFT JOIN finds no matching nbs_act_entity rows). Post-edge,
--   those same projection columns surface the wired entity_uids:
--     * person_as_reporter_uid <- foundation/v2 Provider
--     * hospital_uid           <- foundation/v2 Organization
--     * org_as_reporter_uid    <- foundation/v2 Organization
--
--   The PRIMARY value of this edge:
--     1. JSON-projection coverage of the event SP's `investigation_act_entity`
--        nested columns (consumed by Kafka in production, by RTR's
--        downstream debezium consumer in production).
--     2. ODSE graph correctness for the RDB-vs-RDB_MODERN comparison
--        test against MasterETL (which traverses nbs_act_entity to
--        derive analogous reporter / hospital linkages on the RDB
--        side).
--     3. Hospital_uid is consumed at Merge step 9 by F_PAGE_CASE
--        (datamart-side). At Tier 1 isolation, that column does NOT
--        flip (the postprocessing SP for INVESTIGATION reads from
--        nrt_investigation, not from nbs_act_entity).
--   The investigation postprocessing SP (sp_nrt_investigation_postprocessing)
--   reads from `nrt_investigation` (hand-authored by Tier 1) and does
--   NOT traverse nbs_act_entity. So INVESTIGATION dimension column
--   populations are byte-identical pre/post-edge. **0 RDB_MODERN
--   dim/fact column unlocks at Tier 1 isolation.**
--
-- Wires (6 nbs_act_entity rows total):
--   PerAsReporterOfPHC (Investigation -> Provider, person-as-reporter):
--     1) (21009000) foundation Investigation 20000100 -> foundation Provider 20000010
--     2) (21009001) v2 Investigation         20050010 -> v2 Provider         20010010
--   OrgAsReporterOfPHC (Investigation -> Organization, org-as-reporter):
--     3) (21009002) foundation Investigation 20000100 -> foundation Org      20000020
--     4) (21009003) v2 Investigation         20050010 -> v2 Org              20030010
--   HospOfADT          (Investigation -> Organization, hospital):
--     5) (21009004) foundation Investigation 20000100 -> foundation Org      20000020
--     6) (21009005) v2 Investigation         20050010 -> v2 Org              20030010
--
-- Same Org serves as both Reporter and Hospital — common in production
-- data; v1 simplification per the per-edge prompt and STRATEGY.md
-- (one canonical Org variant per tier).
--
-- Catalog citations (catalog/edge_types.md):
--   * 'PerAsReporterOfPHC' (act_class_cd='CASE', subject_class_cd='PSN')
--     - Used By: sp_investigation_event (CASE-pivot at line 913);
--                also datamart SPs (072/073) — but those read
--                participation, not nbs_act_entity.
--     - SP filter site: 056-sp_investigation_event-001.sql:913
--       (`MAX(CASE WHEN type_cd = 'PerAsReporterOfPHC' THEN entity_uid END)`).
--     - SRTE PAR_TYPE: present (subject_class_cd='PSN' applies for
--       participation use; the nbs_act_entity table has no
--       subject_class_cd column — endpoint shapes are inferred from
--       SP join logic).
--     - Note: the catalog entry for `PerAsReporterOfPHC` lives under
--       `dbo.participation` because the catalog enumerates SRTE
--       PAR_TYPE rows by table. RTR's investigation_event SP reads
--       the same type_cd LITERAL from nbs_act_entity at line 913 —
--       this is how the same code is consumed via two different
--       connective tables.
--   * 'OrgAsReporterOfPHC' (act_class_cd='CASE', subject_class_cd='ORG')
--     - Used By: sp_investigation_event (CASE-pivot at line 932).
--     - SP filter site: 056-sp_investigation_event-001.sql:932
--       (`MAX(CASE WHEN type_cd = 'OrgAsReporterOfPHC' THEN entity_uid END)`).
--     - SRTE PAR_TYPE: present.
--   * 'HospOfADT' (act_class_cd='CASE', subject_class_cd='ORG')
--     - Used By: sp_investigation_event (CASE-pivot at line 914).
--     - SP filter site: 056-sp_investigation_event-001.sql:914
--       (`MAX(CASE WHEN type_cd = 'HospOfADT' THEN entity_uid END)`).
--     - SRTE PAR_TYPE: present (in baseline SRTE).
--     - Downstream: hospital_uid surfaces in F_PAGE_CASE at Merge
--       step 9 (datamart-side — out of scope here).
--
-- UID block (Tier 2 - tenth agent): 21009000 - 21009999.
-- Allocated 6 UIDs (21009000-21009005). Unused 21009006-21009999
-- reserved for future amendments (e.g., Tier 3 expansion of the other
-- 17 *_of_phc_uid roles within this same family, or v3 Investigation
-- variants).
--
-- Forbidden in Tier 2 (per template):
--   - No new ODSE entity rows; no SRTE writes; no foundation/Tier 1
--     modifications; no INSERTs into RDB_MODERN dim/fact tables; no
--     infrastructure-SP invocation in this fixture (orchestrator owns
--     sp_get_date_dim and sp_nrt_srte_condition_code_postprocessing
--     per Merge contract step 2).
--
-- nbs_act_entity NOT-NULL columns (verified via INFORMATION_SCHEMA.COLUMNS,
-- consistent with vaccination_links / interview_links):
--   nbs_act_entity_uid (bigint), act_uid (bigint), add_time (datetime),
--   add_user_id (bigint), entity_uid (bigint),
--   entity_version_ctrl_nbr (smallint), last_chg_time (datetime),
--   last_chg_user_id (bigint), record_status_cd (varchar),
--   record_status_time (datetime).
-- Nullable: type_cd (varchar) -- but populated explicitly because the
-- SP filters on it via MAX(CASE WHEN type_cd = '...' THEN ...).
--
-- IDENTITY note: nbs_act_entity_uid is an IDENTITY column in the
-- baseline schema. To insert explicit UIDs from this agent's allocated
-- block, the INSERT must be wrapped in
-- SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF.
-- Pattern is identical to vaccination_links.sql / interview_links.sql.
-- =====================================================================

-- ----- Sentinel reference (do not allocate -- assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;          -- conventional NBS superuser id

-- ----- Cross-tier UIDs referenced (read-only) -----
DECLARE @foundation_act_inv_uid          bigint = 20000100;  -- foundation Investigation act_uid (public_health_case_uid)
DECLARE @foundation_entity_provider_uid  bigint = 20000010;  -- foundation Provider entity_uid / person_uid
DECLARE @foundation_entity_org_uid       bigint = 20000020;  -- foundation Organization entity_uid / organization_uid
DECLARE @v2_act_inv_uid                  bigint = 20050010;  -- v2 Investigation (Investigation Tier 1)
DECLARE @v2_entity_provider_uid          bigint = 20010010;  -- v2 Provider (Provider Tier 1)
DECLARE @v2_entity_org_uid               bigint = 20030010;  -- v2 Organization (Organization Tier 1)

-- ----- Surrogate UIDs allocated from this agent's block -----
DECLARE @per_reporter_foundation_uid     bigint = 21009000;  -- PerAsReporterOfPHC foundation
DECLARE @per_reporter_v2_uid             bigint = 21009001;  -- PerAsReporterOfPHC v2
DECLARE @org_reporter_foundation_uid     bigint = 21009002;  -- OrgAsReporterOfPHC foundation
DECLARE @org_reporter_v2_uid             bigint = 21009003;  -- OrgAsReporterOfPHC v2
DECLARE @hosp_adt_foundation_uid         bigint = 21009004;  -- HospOfADT foundation
DECLARE @hosp_adt_v2_uid                 bigint = 21009005;  -- HospOfADT v2

-- =====================================================================
-- nbs_act_entity rows.
--
-- entity_version_ctrl_nbr is set to 1 by NBS convention (smallint;
-- versioning starts at 1 for new rows).
-- record_status_cd='ACTIVE' for shape-consistency parity (the CASE
-- pivot subquery at lines 909-934 has no record_status_cd predicate,
-- so 'ACTIVE' vs other values does not change SP behavior — but kept
-- consistent with sibling vaccination_links / interview_links and
-- prior Tier 2 conventions).
-- type_cd populated explicitly (the SP filters on it via MAX(CASE WHEN
-- type_cd = '...')).
-- =====================================================================
SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON;

INSERT INTO [dbo].[nbs_act_entity]
    ([nbs_act_entity_uid], [act_uid], [entity_uid], [type_cd],
     [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    -- Edge 1 (21009000): PerAsReporterOfPHC, foundation Investigation -> foundation Provider
    -- Drives sp_investigation_event investigation_act_entity.person_as_reporter_uid
    -- via the CASE-pivot at line 913 of 056-sp_investigation_event-001.sql.
    (@per_reporter_foundation_uid,              -- nbs_act_entity_uid (surrogate)
     @foundation_act_inv_uid,                   -- act_uid (CASE; foundation Investigation)
     @foundation_entity_provider_uid,           -- entity_uid (PSN/PRV; foundation Provider)
     N'PerAsReporterOfPHC',                     -- type_cd (in SRTE PAR_TYPE; SP CASE pivot literal)
     1,                                         -- entity_version_ctrl_nbr (smallint)
     '2026-04-01T00:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     '2026-04-01T00:00:00',                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-01T00:00:00'),                    -- record_status_time
    -- Edge 2 (21009001): PerAsReporterOfPHC, v2 Investigation -> v2 Provider
    -- Drives person_as_reporter_uid projection for v2 Investigation row.
    (@per_reporter_v2_uid,                      -- nbs_act_entity_uid
     @v2_act_inv_uid,                           -- act_uid (CASE; v2 Investigation)
     @v2_entity_provider_uid,                   -- entity_uid (PSN/PRV; v2 Provider)
     N'PerAsReporterOfPHC',                     -- type_cd
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-04T00:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     '2026-04-04T00:00:00',                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-04T00:00:00'),                    -- record_status_time
    -- Edge 3 (21009002): OrgAsReporterOfPHC, foundation Investigation -> foundation Organization
    -- Drives sp_investigation_event investigation_act_entity.org_as_reporter_uid
    -- via the CASE-pivot at line 932.
    (@org_reporter_foundation_uid,              -- nbs_act_entity_uid
     @foundation_act_inv_uid,                   -- act_uid (CASE; foundation Investigation)
     @foundation_entity_org_uid,                -- entity_uid (ORG; foundation Organization)
     N'OrgAsReporterOfPHC',                     -- type_cd (in SRTE PAR_TYPE; SP CASE pivot literal)
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-01T00:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     '2026-04-01T00:00:00',                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-01T00:00:00'),                    -- record_status_time
    -- Edge 4 (21009003): OrgAsReporterOfPHC, v2 Investigation -> v2 Organization
    -- Drives org_as_reporter_uid projection for v2 Investigation row.
    (@org_reporter_v2_uid,                      -- nbs_act_entity_uid
     @v2_act_inv_uid,                           -- act_uid (CASE; v2 Investigation)
     @v2_entity_org_uid,                        -- entity_uid (ORG; v2 Organization)
     N'OrgAsReporterOfPHC',                     -- type_cd
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-04T00:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     '2026-04-04T00:00:00',                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-04T00:00:00'),                    -- record_status_time
    -- Edge 5 (21009004): HospOfADT, foundation Investigation -> foundation Organization
    -- Drives sp_investigation_event investigation_act_entity.hospital_uid
    -- via the CASE-pivot at line 914. Same Org as the OrgAsReporterOfPHC
    -- pairing for v1 simplification (one canonical Org variant per tier).
    (@hosp_adt_foundation_uid,                  -- nbs_act_entity_uid
     @foundation_act_inv_uid,                   -- act_uid (CASE; foundation Investigation)
     @foundation_entity_org_uid,                -- entity_uid (ORG; foundation Organization)
     N'HospOfADT',                              -- type_cd (in SRTE PAR_TYPE; SP CASE pivot literal)
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-01T00:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     '2026-04-01T00:00:00',                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-01T00:00:00'),                    -- record_status_time
    -- Edge 6 (21009005): HospOfADT, v2 Investigation -> v2 Organization
    -- Drives hospital_uid projection for v2 Investigation row.
    (@hosp_adt_v2_uid,                          -- nbs_act_entity_uid
     @v2_act_inv_uid,                           -- act_uid (CASE; v2 Investigation)
     @v2_entity_org_uid,                        -- entity_uid (ORG; v2 Organization)
     N'HospOfADT',                              -- type_cd
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-04T00:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     '2026-04-04T00:00:00',                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-04T00:00:00');                    -- record_status_time

SET IDENTITY_INSERT [dbo].[nbs_act_entity] OFF;
GO

-- =====================================================================
-- Post-edge SP re-run.
--
-- Tail-EXEC: re-run sp_investigation_event so the JSON projection now
-- includes the wired entity_uids in the investigation_act_entity
-- nested columns:
--   * person_as_reporter_uid (line 913 CASE pivot)
--   * hospital_uid           (line 914 CASE pivot)
--   * org_as_reporter_uid    (line 932 CASE pivot)
-- Pre-edge those columns were NULL on every row (the LEFT JOIN at
-- line 909 returned no matching nbs_act_entity rows); post-edge they
-- resolve to the Provider/Organization entity_uids.
--
-- We do NOT re-run sp_nrt_investigation_postprocessing because its
-- input (nrt_investigation) is hand-authored by Tier 1 and the SP does
-- NOT traverse nbs_act_entity. The INVESTIGATION dimension column
-- populations are byte-identical pre/post-edge.
--
-- The merge orchestrator runs this EXEC as part of step 7 of the
-- Merge contract sequence (Re-run Tier 1 chains affected by Tier 2
-- edges).
-- =====================================================================

USE [RDB_MODERN];
GO

-- Tail-EXEC: re-run sp_investigation_event to confirm the
-- PerAsReporterOfPHC / OrgAsReporterOfPHC / HospOfADT rows project into
-- the JSON payload's investigation_act_entity nested columns:
--   * person_as_reporter_uid (foundation->20000010, v2->20010010)
--   * hospital_uid           (foundation->20000020, v2->20030010)
--   * org_as_reporter_uid    (foundation->20000020, v2->20030010)
GO
