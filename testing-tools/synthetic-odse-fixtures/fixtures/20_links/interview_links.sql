USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 2 link fixture: Interview cross-subject edges (nbs_act_entity).
--   Edge type 1: 'IntrvwerOfInterview' (Interview act -> Provider/Person -- interviewer)
--   Edge type 2: 'IntrvweeOfInterview' (Interview act -> Patient/Person   -- interviewee)
--   Edge type 3: 'OrgAsSiteOfIntv'     (Interview act -> Organization      -- interview site)
--
-- All three edge types live on dbo.nbs_act_entity (NOT participation,
-- NOT act_relationship). This is the SECOND nbs_act_entity edge agent
-- after vaccination_links (the eighth Tier 2 agent). Same IDENTITY-
-- column wrap pattern as vaccination_links: nbs_act_entity_uid is a
-- bigint NOT NULL IDENTITY column, so the INSERT is wrapped in
-- SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF to allow explicit
-- UID allocation from this agent's block.
--
-- All three type_cds are MISSING_FROM_SRTE per Phase B's
-- catalog/edge_types.md (no parent code_value_general row in baseline
-- nbs_srte). RTR's sp_interview_event nonetheless filters on the
-- literal type_cd values directly (not via a code-set join), so the
-- ODSE rows wired here drive the SP behavior even though SRTE has no
-- parent. This matches the documented "MISSING_FROM_SRTE" Phase B
-- policy: author with the literal type_cd values.
--
-- COVERAGE SHAPE -- IMPORTANT (differs from vaccination_links):
--   Unlike vaccination_links (whose SubOfVacc INNER JOIN at line 108
--   of 071-sp_vaccination_event-001.sql gates the entire SP and
--   returns 0 rows pre-edge), all three Interview event-SP joins are
--   LEFT JOIN (lines 87-95 of 065-sp_interview_event-001.sql):
--
--     LEFT JOIN NBS_ACT_ENTITY nae  ON ix.interview_uid = nae.act_uid
--                                   AND nae.type_cd = 'IntrvwerOfInterview'
--     LEFT JOIN NBS_ACT_ENTITY nae2 ON ix.interview_uid = nae2.act_uid
--                                   AND nae2.type_cd = 'OrgAsSiteOfIntv'
--     LEFT JOIN NBS_ACT_ENTITY nae3 ON ix.interview_uid = nae3.act_uid
--                                   AND nae3.type_cd = 'IntrvweeOfInterview'
--
--   So the Interview event SP returns rows at Tier 1 isolation
--   regardless of these edges. Pre-edge, #INTERVIEW_INIT projects
--   PROVIDER_UID/ORGANIZATION_UID/PATIENT_UID as NULL (from the
--   missing nae*/nae2/nae3 joins). Post-edge, those same JSON-
--   projection columns surface the wired entity_uids.
--
--   This edge is therefore SHAPE-CONSISTENCY, NOT a Tier 1-isolation
--   coverage unlock. RDB_MODERN dim/fact column populations on
--   D_INTERVIEW (2 rows, 18/24 + 6 LDF OUT_OF_SCOPE), D_INTERVIEW_NOTE
--   (2 rows, 7/7), and F_INTERVIEW_CASE (2 rows, 8/10) are
--   byte-identical pre/post-edge. The Interview Tier 1 coverage
--   report (coverage_interview.md) was already at 18/24 + 7/7 + 8/10
--   at Tier 1 isolation -- this Tier 2 edge does not change those
--   numbers.
--
--   The PRIMARY value of this edge:
--     1. Unblocking the Interview event SP's JSON projection
--        (PROVIDER_UID / ORGANIZATION_UID / PATIENT_UID populate
--        post-edge). Kafka consumers in production read this
--        projection.
--     2. ODSE graph correctness for the RDB-vs-RDB_MODERN comparison
--        test against MasterETL (which traverses nbs_act_entity to
--        derive analogous Interview-participant linkages on the RDB
--        side).
--
-- Wires (6 nbs_act_entity rows total):
--   IntrvwerOfInterview (Interview -> Provider, interviewer):
--     1) (21008000) foundation Interview 20000140 -> foundation Provider 20000010
--     2) (21008001) v2 Interview         20090010 -> v2 Provider         20010010
--   IntrvweeOfInterview (Interview -> Patient, interviewee):
--     3) (21008002) foundation Interview 20000140 -> foundation Patient  20000000
--     4) (21008003) v2 Interview         20090010 -> v2 Patient          20020010
--   OrgAsSiteOfIntv     (Interview -> Organization, site):
--     5) (21008004) foundation Interview 20000140 -> foundation Org      20000020
--     6) (21008005) v2 Interview         20090010 -> v2 Org              20030010
--
-- Catalog citations (catalog/edge_types.md, dbo.nbs_act_entity rows):
--   * 'IntrvwerOfInterview' (Act endpoint=Interview, Entity endpoint=Person/PSN)
--     - Used By: sp_interview_event.
--     - SP filter: 065-sp_interview_event-001.sql:87-89 (LEFT JOIN nae
--       on TYPE_CD='IntrvwerOfInterview', projects nae.entity_uid as
--       PROVIDER_UID at line 71).
--     - SRTE PAR_TYPE: MISSING_FROM_SRTE (per Phase B's catalog).
--   * 'IntrvweeOfInterview' (Act endpoint=Interview, Entity endpoint=Person/PSN -- patient)
--     - Used By: sp_interview_event.
--     - SP filter: 065-sp_interview_event-001.sql:93-95 (LEFT JOIN nae3
--       on TYPE_CD='IntrvweeOfInterview', projects nae3.entity_uid as
--       PATIENT_UID at line 73).
--     - SRTE PAR_TYPE: MISSING_FROM_SRTE.
--   * 'OrgAsSiteOfIntv' (Act endpoint=Interview, Entity endpoint=Organization/ORG)
--     - Used By: sp_interview_event.
--     - SP filter: 065-sp_interview_event-001.sql:90-92 (LEFT JOIN nae2
--       on TYPE_CD='OrgAsSiteOfIntv', projects nae2.entity_uid as
--       ORGANIZATION_UID at line 72).
--     - SRTE PAR_TYPE: MISSING_FROM_SRTE.
--
-- UID block (Tier 2 - ninth agent): 21008000 - 21008999.
-- This fixture authors NO new entity / Person / Organization /
-- Interview / Act rows; it only writes 6 rows to dbo.nbs_act_entity
-- (each row consuming one surrogate UID from the allocated block).
--
-- Forbidden in Tier 2 (per template):
--   - No new ODSE entity rows; no SRTE writes; no foundation/Tier 1
--     modifications; no INSERTs into RDB_MODERN dim/fact tables; no
--     infrastructure-SP invocation in this fixture (orchestrator owns
--     sp_get_date_dim and sp_nrt_srte_condition_code_postprocessing
--     per Merge contract step 2).
--
-- nbs_act_entity NOT-NULL columns (verified via INFORMATION_SCHEMA.COLUMNS):
--   nbs_act_entity_uid (bigint), act_uid (bigint), add_time (datetime),
--   add_user_id (bigint), entity_uid (bigint),
--   entity_version_ctrl_nbr (smallint), last_chg_time (datetime),
--   last_chg_user_id (bigint), record_status_cd (varchar),
--   record_status_time (datetime).
-- Nullable: type_cd (varchar) -- counter-intuitive but the schema lists
--   it nullable. We populate it explicitly because the SPs filter on it.
--
-- IDENTITY note: nbs_act_entity_uid is an IDENTITY column in the
-- baseline schema (verified via sys.columns.is_identity=1). To insert
-- explicit UIDs from this agent's allocated block, the INSERT must be
-- wrapped in SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF.
-- Pattern is identical to vaccination_links.sql (sibling agent).
-- =====================================================================

-- ----- Sentinel reference (do not allocate -- assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;          -- conventional NBS superuser id

-- ----- Cross-tier UIDs referenced (read-only) -----
DECLARE @foundation_act_interview_uid    bigint = 20000140;  -- foundation Interview act_uid / interview_uid
DECLARE @foundation_entity_provider_uid  bigint = 20000010;  -- foundation Provider entity_uid / person_uid
DECLARE @foundation_entity_patient_uid   bigint = 20000000;  -- foundation Patient entity_uid / person_uid
DECLARE @foundation_entity_org_uid       bigint = 20000020;  -- foundation Organization entity_uid / organization_uid
DECLARE @v2_act_interview_uid            bigint = 20090010;  -- v2 Interview (Interview Tier 1)
DECLARE @v2_entity_provider_uid          bigint = 20010010;  -- v2 Provider (Provider Tier 1)
DECLARE @v2_entity_patient_uid           bigint = 20020010;  -- v2 Patient (Patient Tier 1)
DECLARE @v2_entity_org_uid               bigint = 20030010;  -- v2 Organization (Organization Tier 1)

-- ----- Surrogate UIDs allocated from this agent's block -----
DECLARE @intrvwer_foundation_uid         bigint = 21008000;  -- IntrvwerOfInterview foundation
DECLARE @intrvwer_v2_uid                 bigint = 21008001;  -- IntrvwerOfInterview v2
DECLARE @intrvwee_foundation_uid         bigint = 21008002;  -- IntrvweeOfInterview foundation
DECLARE @intrvwee_v2_uid                 bigint = 21008003;  -- IntrvweeOfInterview v2
DECLARE @orgsite_foundation_uid          bigint = 21008004;  -- OrgAsSiteOfIntv foundation
DECLARE @orgsite_v2_uid                  bigint = 21008005;  -- OrgAsSiteOfIntv v2

-- =====================================================================
-- nbs_act_entity rows.
--
-- entity_version_ctrl_nbr is set to 1 by NBS convention (smallint;
-- versioning starts at 1 for new rows).
-- record_status_cd='ACTIVE' for shape-consistency parity (no current
-- SP filter at sp_interview_event:87-95 reads it, but kept consistent
-- with sibling vaccination_links and prior Tier 2 conventions).
-- type_cd populated explicitly (the SP filters on it directly).
-- =====================================================================
SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON;

INSERT INTO [dbo].[nbs_act_entity]
    ([nbs_act_entity_uid], [act_uid], [entity_uid], [type_cd],
     [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    -- Edge 1 (21008000): IntrvwerOfInterview, foundation Interview -> foundation Provider
    -- Drives sp_interview_event #INTERVIEW_INIT.PROVIDER_UID projection
    -- via the LEFT JOIN nae at lines 87-89 of 065-sp_interview_event-001.sql.
    (@intrvwer_foundation_uid,                  -- nbs_act_entity_uid (surrogate)
     @foundation_act_interview_uid,             -- act_uid (Interview foundation)
     @foundation_entity_provider_uid,           -- entity_uid (PSN/PRV foundation Provider)
     N'IntrvwerOfInterview',                    -- type_cd (MISSING_FROM_SRTE; SP filters on literal)
     1,                                         -- entity_version_ctrl_nbr (smallint)
     '2026-04-01T00:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     '2026-04-01T00:00:00',                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-01T00:00:00'),                    -- record_status_time
    -- Edge 2 (21008001): IntrvwerOfInterview, v2 Interview -> v2 Provider
    -- Drives PROVIDER_UID projection for v2 Interview row.
    (@intrvwer_v2_uid,                          -- nbs_act_entity_uid
     @v2_act_interview_uid,                     -- act_uid (Interview v2)
     @v2_entity_provider_uid,                   -- entity_uid (PSN/PRV v2 Provider)
     N'IntrvwerOfInterview',                    -- type_cd
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-15T10:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     '2026-04-15T10:00:00',                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-15T10:00:00'),                    -- record_status_time
    -- Edge 3 (21008002): IntrvweeOfInterview, foundation Interview -> foundation Patient
    -- Drives sp_interview_event #INTERVIEW_INIT.PATIENT_UID projection
    -- via the LEFT JOIN nae3 at lines 93-95.
    (@intrvwee_foundation_uid,                  -- nbs_act_entity_uid
     @foundation_act_interview_uid,             -- act_uid (Interview foundation)
     @foundation_entity_patient_uid,            -- entity_uid (PSN/PAT foundation Patient)
     N'IntrvweeOfInterview',                    -- type_cd (MISSING_FROM_SRTE; SP filters on literal)
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-01T00:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     '2026-04-01T00:00:00',                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-01T00:00:00'),                    -- record_status_time
    -- Edge 4 (21008003): IntrvweeOfInterview, v2 Interview -> v2 Patient
    -- Drives PATIENT_UID projection for v2 Interview row.
    (@intrvwee_v2_uid,                          -- nbs_act_entity_uid
     @v2_act_interview_uid,                     -- act_uid (Interview v2)
     @v2_entity_patient_uid,                    -- entity_uid (PSN/PAT v2 Patient)
     N'IntrvweeOfInterview',                    -- type_cd
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-15T10:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     '2026-04-15T10:00:00',                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-15T10:00:00'),                    -- record_status_time
    -- Edge 5 (21008004): OrgAsSiteOfIntv, foundation Interview -> foundation Organization
    -- Drives sp_interview_event #INTERVIEW_INIT.ORGANIZATION_UID
    -- projection via the LEFT JOIN nae2 at lines 90-92.
    (@orgsite_foundation_uid,                   -- nbs_act_entity_uid
     @foundation_act_interview_uid,             -- act_uid (Interview foundation)
     @foundation_entity_org_uid,                -- entity_uid (ORG foundation Organization)
     N'OrgAsSiteOfIntv',                        -- type_cd (MISSING_FROM_SRTE; SP filters on literal)
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-01T00:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     '2026-04-01T00:00:00',                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-01T00:00:00'),                    -- record_status_time
    -- Edge 6 (21008005): OrgAsSiteOfIntv, v2 Interview -> v2 Organization
    -- Drives ORGANIZATION_UID projection for v2 Interview row.
    (@orgsite_v2_uid,                           -- nbs_act_entity_uid
     @v2_act_interview_uid,                     -- act_uid (Interview v2)
     @v2_entity_org_uid,                        -- entity_uid (ORG v2 Organization)
     N'OrgAsSiteOfIntv',                        -- type_cd
     1,                                         -- entity_version_ctrl_nbr
     '2026-04-15T10:00:00',                     -- add_time
     @superuser_id,                             -- add_user_id
     '2026-04-15T10:00:00',                     -- last_chg_time
     @superuser_id,                             -- last_chg_user_id
     N'ACTIVE',                                 -- record_status_cd
     '2026-04-15T10:00:00');                    -- record_status_time

SET IDENTITY_INSERT [dbo].[nbs_act_entity] OFF;
GO

-- =====================================================================
-- Post-edge SP re-run.
--
-- Tail-EXEC: re-run sp_interview_event so the JSON projection now
-- includes PROVIDER_UID / ORGANIZATION_UID / PATIENT_UID for both
-- Interview rows. Pre-edge those columns were NULL on every #INTERVIEW_INIT
-- row (LEFT JOINs returned no matching nbs_act_entity row); post-edge
-- they should resolve to the wired entity_uids.
--
-- We do NOT re-run sp_d_interview_postprocessing or
-- sp_f_interview_case_postprocessing because their input
-- (nrt_interview / nrt_interview_note / nrt_interview_answer) is
-- hand-authored by Tier 1 and they do NOT traverse nbs_act_entity.
-- D_INTERVIEW (2 rows, 18/24 + 6 LDF OUT_OF_SCOPE), D_INTERVIEW_NOTE
-- (2 rows, 7/7), and F_INTERVIEW_CASE (2 rows, 8/10) column populations
-- are unchanged at Tier 1 isolation by this edge -- the postprocessing
-- SPs are insensitive to nbs_act_entity row presence.
--
-- The merge orchestrator runs this EXEC as part of step 7 of the
-- Merge contract sequence (Re-run Tier 1 chains affected by Tier 2
-- edges).
-- =====================================================================

USE [RDB_MODERN];
GO

-- Tail-EXEC: re-run sp_interview_event to confirm the IntrvwerOfInterview /
-- IntrvweeOfInterview / OrgAsSiteOfIntv rows project into the JSON
-- payload's PROVIDER_UID / PATIENT_UID / ORGANIZATION_UID fields.
-- Expected: 2 rows in #INTERVIEW_INIT (one per Interview UID), each with
-- non-NULL PROVIDER_UID, ORGANIZATION_UID, PATIENT_UID.
GO
