USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 2 link fixture: Reporter participations on PHC.
--   Edge type 1: 'PerAsReporterOfPHC' (Person/Provider as reporter)
--   Edge type 2: 'OrgAsReporterOfPHC' (Organization as reporter)
--
-- Both edge types live on dbo.participation, both with act_class_cd='CASE'.
-- The two type_cds are authored together because they form the
-- "reporter" half of an Investigation's reporting metadata and share
-- the same SP filter sites (event SP + datamart event/update).
--
-- Wires (4 participation rows total):
--   PerAsReporterOfPHC (subject_class_cd='PSN'):
--     1) foundation Provider (entity_uid 20000010) AS reporter of
--        foundation Investigation (act_uid 20000100)
--     2) v2 Provider        (entity_uid 20010010) AS reporter of
--        v2 Investigation         (act_uid 20050010)
--   OrgAsReporterOfPHC (subject_class_cd='ORG'):
--     3) foundation Organization (entity_uid 20000020) AS reporter of
--        foundation Investigation (act_uid 20000100)
--     4) v2 Organization        (entity_uid 20030010) AS reporter of
--        v2 Investigation         (act_uid 20050010)
--
-- Catalog citations (catalog/edge_types.md, dbo.participation rows):
--   * 'PerAsReporterOfPHC' (act_class_cd='CASE', subject_class_cd='PSN')
--     - Used By: sp_investigation_event;
--                sp_public_health_case_fact_datamart_event/_update.
--     - SP filter sites:
--       - 056-sp_investigation_event-001.sql:913 (CASE pivot extracting
--         person_as_reporter_uid from nbs_act_entity — note the
--         investigation_event SP reads nbs_act_entity, NOT participation,
--         for this pivot. Authored here on participation per the
--         catalog because the datamart SPs read participation.)
--       - 072-sp_public_health_case_fact_datamart_event-001.sql:1900
--         (PARTICIPATION INNER JOIN, TYPE_CD IN list)
--       - 072-...:1944-1948 (REPORTERNAME / REPORTERPHONE pivots
--         feeding F_PAGE_CASE)
--       - 073-sp_public_health_case_fact_datamart_update-001.sql:106
--         (PARTICIPATION INNER JOIN, TYPE_CD IN list)
--       - 073-...:155-156 (REPORTERNAME / REPORTERPHONE pivots, update
--         path)
--   * 'OrgAsReporterOfPHC' (act_class_cd='CASE', subject_class_cd='ORG')
--     - Used By: sp_investigation_event;
--                sp_public_health_case_fact_datamart_event/_update.
--     - SP filter sites:
--       - 056-sp_investigation_event-001.sql:932 (CASE pivot extracting
--         org_as_reporter_uid from nbs_act_entity — same caveat as
--         above; investigation_event reads nbs_act_entity for this
--         pivot, but the participation row is what the datamart SPs
--         read.)
--       - 072-sp_public_health_case_fact_datamart_event-001.sql:1898
--         (PARTICIPATION INNER JOIN, TYPE_CD IN list)
--       - 072-...:1917 (PARTICIPATION INNER JOIN, secondary UNION
--         block resolving the Organization name)
--       - 072-...:1964 (ORGANIZATIONNAME pivot feeding F_PAGE_CASE)
--       - 073-...:106 (PARTICIPATION INNER JOIN, TYPE_CD IN list)
--       - 073-...:160 (PARTICIPATION INNER JOIN, secondary UNION
--         block, update path)
--       - 073-...:213 (ORGANIZATIONNAME pivot, update path)
--
-- Honest coverage assessment (per the per-edge prompt):
--   - This edge is **shape-consistency-mostly at Tier 1 isolation**,
--     exactly like patient_phc.
--   - sp_nrt_investigation_postprocessing reads from the hand-authored
--     `nrt_investigation` staging table (not from `participation`); the
--     INVESTIGATION dimension columns do not change post-edge.
--   - The investigation_event SP's pivots at lines 909–933 read from
--     `nbs_act_entity` (not `participation`), so authoring participation
--     rows alone does NOT populate person_as_reporter_uid /
--     org_as_reporter_uid in the JSON projection at the
--     investigation_act_entity nested block. (The corresponding
--     nbs_act_entity rows are a separate Tier 2 deliverable, not in
--     scope here per the per-edge prompt's "4 participation rows total"
--     contract and per the explicit catalog row for participation.)
--   - The PRIMARY value lands at Merge contract step 9 (Datamart SPs):
--     sp_public_health_case_fact_datamart_event / _update both have
--     INNER JOINs on PARTICIPATION filtered by
--     `TYPE_CD IN ('OrgAsReporterOfPHC','InvestgrOfPHC',
--                  'PerAsReporterOfPHC','PhysicianOfPHC')`
--     (072 line 1897-1903 / 073 line 105-110) and depend on these
--     participation rows to populate F_PAGE_CASE.REPORTER_NAME,
--     REPORTER_PHONE, ORGANIZATION_NAME and related columns.
--   - Secondary value: ODSE graph correctness for the
--     RDB-vs-RDB_MODERN comparison test against MasterETL (which
--     traverses participation directly to populate analogous reporter
--     columns).
--
-- UID block (Tier 2 — sixth agent): 21005000 - 21005999.
-- This fixture authors NO new entity / Person / Organization /
-- Public_health_case rows; it only writes 4 rows to dbo.participation.
--
-- Forbidden in Tier 2 (per template):
--   - No new ODSE entity rows; no SRTE writes; no foundation/Tier 1
--     modifications; no INSERTs into RDB_MODERN dim/fact tables; no
--     infrastructure-SP invocation in this fixture (orchestrator owns
--     sp_get_date_dim and sp_nrt_srte_condition_code_postprocessing
--     per Merge contract step 2).
-- =====================================================================

-- ----- Sentinel reference (do not allocate — assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Cross-tier UIDs referenced (read-only) -----
DECLARE @foundation_entity_provider_uid bigint = 20000010;  -- foundation Provider entity_uid / person_uid
DECLARE @foundation_entity_org_uid      bigint = 20000020;  -- foundation Organization entity_uid / organization_uid
DECLARE @foundation_act_inv_uid         bigint = 20000100;  -- foundation Investigation act_uid (public_health_case_uid)
DECLARE @v2_entity_provider_uid         bigint = 20010010;  -- v2 Provider (Provider Tier 1)
DECLARE @v2_entity_org_uid              bigint = 20030010;  -- v2 Organization (Organization Tier 1)
DECLARE @v2_act_inv_uid                 bigint = 20050010;  -- v2 Investigation (Investigation Tier 1)

-- =====================================================================
-- participation rows.
--
-- The composite PK on dbo.participation is
-- (subject_entity_uid, act_uid, type_cd) — it does not need its own
-- surrogate UID. We do not allocate any UIDs from this agent's block
-- 21005000-21005999; the block is reserved here in case a future
-- amendment needs surrogate UIDs.
--
-- type_cd='PerAsReporterOfPHC' verified present in baseline SRTE
-- PAR_TYPE (act_class_cd='CASE', subject_class_cd='PSN',
-- type_desc_txt='Reporter of Case').
-- type_cd='OrgAsReporterOfPHC' verified present in baseline SRTE
-- PAR_TYPE (act_class_cd='CASE', subject_class_cd='ORG',
-- type_desc_txt='Reporting Source of Case').
--
-- NOT-NULL columns on dbo.participation are only:
--   subject_entity_uid, act_uid, type_cd
-- All other columns are nullable; we populate the standard lifecycle
-- columns (act_class_cd, subject_class_cd, add_*, last_chg_*,
-- record_status_*, status_*, type_desc_txt) for shape parity with
-- production data and for the few SPs that read those columns.
-- The datamart SPs at 072/073 lines 1897 / 105 explicitly filter on
-- PAR.RECORD_STATUS_CD = 'ACTIVE' (verified by reading both files),
-- so 'ACTIVE' is required here.
-- =====================================================================
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd],
     [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time],
     [status_cd], [status_time],
     [type_desc_txt])
VALUES
    -- Edge 1: foundation Provider (PSN) AS reporter of foundation Investigation (CASE)
    (@foundation_act_inv_uid,            -- act_uid (CASE; foundation Investigation)
     @foundation_entity_provider_uid,    -- subject_entity_uid (PSN; foundation Provider)
     N'PerAsReporterOfPHC',              -- type_cd (PAR_TYPE 'PerAsReporterOfPHC' — in SRTE)
     N'CASE',                            -- act_class_cd
     N'PSN',                             -- subject_class_cd
     '2026-04-01T00:00:00',              -- add_time
     @superuser_id,                      -- add_user_id
     '2026-04-01T00:00:00',              -- last_chg_time
     @superuser_id,                      -- last_chg_user_id
     N'ACTIVE',                          -- record_status_cd (datamart SPs filter on this)
     '2026-04-01T00:00:00',              -- record_status_time
     'A',                                -- status_cd (char(1))
     '2026-04-01T00:00:00',              -- status_time
     N'Reporter of Case'),
    -- Edge 2: v2 Provider (PSN) AS reporter of v2 Investigation (CASE)
    (@v2_act_inv_uid,                    -- act_uid (CASE; v2 Investigation)
     @v2_entity_provider_uid,            -- subject_entity_uid (PSN; v2 Provider)
     N'PerAsReporterOfPHC',              -- type_cd
     N'CASE',                            -- act_class_cd
     N'PSN',                             -- subject_class_cd
     '2026-04-04T00:00:00',              -- add_time
     @superuser_id,                      -- add_user_id
     '2026-04-04T00:00:00',              -- last_chg_time
     @superuser_id,                      -- last_chg_user_id
     N'ACTIVE',                          -- record_status_cd
     '2026-04-04T00:00:00',              -- record_status_time
     'A',                                -- status_cd
     '2026-04-04T00:00:00',              -- status_time
     N'Reporter of Case'),
    -- Edge 3: foundation Organization (ORG) AS reporting source of foundation Investigation (CASE)
    (@foundation_act_inv_uid,            -- act_uid (CASE; foundation Investigation)
     @foundation_entity_org_uid,         -- subject_entity_uid (ORG; foundation Organization)
     N'OrgAsReporterOfPHC',              -- type_cd (PAR_TYPE 'OrgAsReporterOfPHC' — in SRTE)
     N'CASE',                            -- act_class_cd
     N'ORG',                             -- subject_class_cd
     '2026-04-01T00:00:00',              -- add_time
     @superuser_id,                      -- add_user_id
     '2026-04-01T00:00:00',              -- last_chg_time
     @superuser_id,                      -- last_chg_user_id
     N'ACTIVE',                          -- record_status_cd
     '2026-04-01T00:00:00',              -- record_status_time
     'A',                                -- status_cd
     '2026-04-01T00:00:00',              -- status_time
     N'Reporting Source of Case'),
    -- Edge 4: v2 Organization (ORG) AS reporting source of v2 Investigation (CASE)
    (@v2_act_inv_uid,                    -- act_uid (CASE; v2 Investigation)
     @v2_entity_org_uid,                 -- subject_entity_uid (ORG; v2 Organization)
     N'OrgAsReporterOfPHC',              -- type_cd
     N'CASE',                            -- act_class_cd
     N'ORG',                             -- subject_class_cd
     '2026-04-04T00:00:00',              -- add_time
     @superuser_id,                      -- add_user_id
     '2026-04-04T00:00:00',              -- last_chg_time
     @superuser_id,                      -- last_chg_user_id
     N'ACTIVE',                          -- record_status_cd
     '2026-04-04T00:00:00',              -- record_status_time
     'A',                                -- status_cd
     '2026-04-04T00:00:00',              -- status_time
     N'Reporting Source of Case');

GO

-- =====================================================================
-- Post-edge SP re-run.
--
-- Per the honest coverage assessment in the header: at Tier 1 isolation
-- this edge does NOT flip any RDB_MODERN dimension/fact columns from
-- NULL/sentinel-1 to populated values. The Investigation postprocessing
-- SP reads from `nrt_investigation` (hand-authored by Tier 1, not
-- traversing `participation`).
--
-- We re-run sp_investigation_event purely as a SHAPE-CONSISTENCY
-- verification: the SP must execute cleanly with the participation rows
-- present. Note the investigation_event SP's reporter pivots at lines
-- 909–933 read from `nbs_act_entity` (not `participation`), so this
-- re-run does NOT surface person_as_reporter_uid / org_as_reporter_uid
-- in the investigation_act_entity nested JSON block. The participation
-- rows authored here are consumed by the datamart SPs at Merge contract
-- step 9 (sp_public_health_case_fact_datamart_event / _update) which
-- populate F_PAGE_CASE.REPORTER_NAME / REPORTER_PHONE /
-- ORGANIZATION_NAME — out of scope for this Tier 2 agent's verification.
--
-- We do NOT re-run sp_nrt_investigation_postprocessing because its
-- output (the INVESTIGATION dimension) is unaffected by this edge:
-- the SP reads only `nrt_investigation`, never `participation`.
--
-- The merge orchestrator runs this EXEC as part of step 7 of the Merge
-- contract sequence (Re-run Tier 1 chains affected by Tier 2 edges).
-- The Datamart SPs at step 9 are where the participation rows authored
-- here will actually land in RDB_MODERN.
-- =====================================================================

USE [RDB_MODERN];
GO

-- Tail-EXEC: re-run sp_investigation_event to confirm SP callability
-- with the new participation rows. (Coverage does not change at the
-- INVESTIGATION dim level; this is a shape-consistency verification.)
GO
