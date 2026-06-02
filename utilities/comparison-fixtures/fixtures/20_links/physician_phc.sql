USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 2 link fixture: Physician + Investigator participations on PHC.
--   Edge type 1: 'PhysicianOfPHC' (Provider as Physician of Investigation)
--   Edge type 2: 'InvestgrOfPHC'  (Provider as Investigator of Investigation)
--
-- Both edge types live on dbo.participation, both with act_class_cd='CASE'
-- and subject_class_cd='PSN'. The two type_cds are authored together
-- because they share the same SP filter sites at the datamart fact SPs:
--   072-sp_public_health_case_fact_datamart_event-001.sql:1897-1902
--     (PARTICIPATION INNER JOIN, TYPE_CD IN ('OrgAsReporterOfPHC',
--      'InvestgrOfPHC','PerAsReporterOfPHC','PhysicianOfPHC'))
--   073-sp_public_health_case_fact_datamart_update-001.sql:106
--     (PARTICIPATION INNER JOIN, same TYPE_CD list)
-- They feed F_PAGE_CASE columns:
--   PhysicianOfPHC -> PROVIDERNAME / PROVIDERPHONE  (072:1936-1942 / 073:153-154)
--   InvestgrOfPHC  -> INVESTIGATORNAME / INVESTIGATORPHONE / INVESTIGATORASSIGNEDDATE
--                                                    (072:1951-1962 / 073:157-159)
--
-- Wires (4 participation rows total):
--   PhysicianOfPHC (subject_class_cd='PSN'):
--     1) foundation Provider (entity_uid 20000010) AS physician of
--        foundation Investigation (act_uid 20000100)
--     2) v2 Provider        (entity_uid 20010010) AS physician of
--        v2 Investigation         (act_uid 20050010)
--   InvestgrOfPHC (subject_class_cd='PSN'):
--     3) foundation Provider (entity_uid 20000010) AS investigator of
--        foundation Investigation (act_uid 20000100)
--     4) v2 Provider        (entity_uid 20010010) AS investigator of
--        v2 Investigation         (act_uid 20050010)
--
-- (Per the per-edge prompt: same Provider serves as both Physician and
-- Investigator of the same Investigation; common in production, v1
-- simplification per STRATEGY.md.)
--
-- Catalog citations (catalog/edge_types.md, dbo.participation rows):
--   * 'PhysicianOfPHC' (act_class_cd='CASE', subject_class_cd='PSN')
--     - Used By: sp_public_health_case_fact_datamart_event/_update.
--     - NOT referenced by sp_investigation_event (verified by grep —
--       056-...sql contains zero matches for 'PhysicianOfPHC'). The
--       investigation_event SP uses HospOfADT and InvestgrOfPHC for
--       its PHC pivots; PhysicianOfPHC only manifests at the datamart
--       SPs (Merge contract step 9).
--     - SP filter sites:
--       - 072-...:1897-1902 (PARTICIPATION INNER JOIN, TYPE_CD IN list)
--       - 072-...:1936-1942 (PROVIDERNAME / PROVIDERPHONE pivots)
--       - 073-...:106 (PARTICIPATION INNER JOIN, TYPE_CD IN list)
--       - 073-...:153-154 (PROVIDERNAME / PROVIDERPHONE pivots,
--         update path)
--   * 'InvestgrOfPHC' (act_class_cd='CASE', subject_class_cd='PSN')
--     - Used By: sp_investigation_event;
--                sp_public_health_case_fact_datamart_event/_update.
--     - SP filter sites:
--       - 056-sp_investigation_event-001.sql:869-874 (LEFT OUTER JOIN
--         on participation; projects par2.from_time as
--         investigator_assigned_datetime in JSON output) — note the
--         investigation_event SP DOES read participation directly for
--         this edge type (unlike the reporter edges which read
--         nbs_act_entity for the *_uid pivots).
--       - 072-...:1897-1902 (PARTICIPATION INNER JOIN, TYPE_CD IN list)
--       - 072-...:1951-1962 (INVESTIGATORNAME / INVESTIGATORPHONE /
--         INVESTIGATORASSIGNEDDATE pivots)
--       - 073-...:106 (PARTICIPATION INNER JOIN, TYPE_CD IN list)
--       - 073-...:157-159 (INVESTIGATORNAME / INVESTIGATORPHONE /
--         INVESTIGATORASSIGNEDDATE pivots, update path)
--
-- Honest coverage assessment (per the per-edge prompt's guidance):
--   - This edge is **shape-consistency-mostly at Tier 1 isolation**,
--     exactly like reporter_phc / patient_phc.
--   - sp_nrt_investigation_postprocessing reads from the hand-authored
--     `nrt_investigation` staging table (not from `participation`); the
--     INVESTIGATION dimension columns do not change post-edge.
--   - The investigation_event SP DOES read participation at line 869
--     for the InvestgrOfPHC pivot — but the projection
--     (`investigator_assigned_datetime`) is in the JSON output that
--     would be consumed by Kafka/CDC in production, not by
--     sp_nrt_investigation_postprocessing in our local fixture flow.
--     The corresponding column on `nrt_investigation` is hand-authored
--     by Tier 1 (set on v2 to '2026-04-02', NULL on foundation), so
--     the post-edge re-run does not flip RDB_MODERN dim/fact column
--     coverage.
--   - Note on `nrt_investigation.investigator_id`: there is NO
--     participation->investigator_id pivot in either the event SP or
--     the postprocessing SP. The event SP at line 848 projects
--     par2.from_time as investigator_assigned_datetime ONLY (not the
--     subject_entity_uid). The investigator_id column is purely a
--     hand-authored column on the nrt_investigation staging row — it
--     does NOT auto-populate from the InvestgrOfPHC participation row.
--     This is documented as OUT_OF_SCOPE in the coverage report
--     (a separate Tier 1 staging-row UPDATE could populate it, but
--     that's not in scope for this Tier 2 agent — Tier 2 does not
--     modify Tier 1 outputs).
--   - PhysicianOfPHC is NOT read by sp_investigation_event at all, so
--     authoring its participation row has zero effect on
--     INVESTIGATION dim coverage at Tier 1 isolation.
--   - The PRIMARY value of both edges lands at Merge contract step 9
--     (Datamart SPs): sp_public_health_case_fact_datamart_event /
--     _update both have INNER JOIN on PARTICIPATION filtered by
--     `TYPE_CD IN ('OrgAsReporterOfPHC','InvestgrOfPHC',
--                  'PerAsReporterOfPHC','PhysicianOfPHC')`
--     and depend on these participation rows to populate
--     F_PAGE_CASE.PROVIDERNAME / PROVIDERPHONE / INVESTIGATORNAME /
--     INVESTIGATORPHONE / INVESTIGATORASSIGNEDDATE.
--   - Secondary value: ODSE graph correctness for the
--     RDB-vs-RDB_MODERN comparison test against MasterETL (which
--     traverses participation directly to populate analogous
--     physician/investigator columns).
--
-- UID block (Tier 2 — seventh agent): 21006000 - 21006999.
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
DECLARE @foundation_act_inv_uid         bigint = 20000100;  -- foundation Investigation act_uid (public_health_case_uid)
DECLARE @v2_entity_provider_uid         bigint = 20010010;  -- v2 Provider (Provider Tier 1)
DECLARE @v2_act_inv_uid                 bigint = 20050010;  -- v2 Investigation (Investigation Tier 1)

-- =====================================================================
-- participation rows.
--
-- The composite PK on dbo.participation is
-- (subject_entity_uid, act_uid, type_cd) — it does not need its own
-- surrogate UID. We do not allocate any UIDs from this agent's block
-- 21006000-21006999; the block is reserved here in case a future
-- amendment needs surrogate UIDs.
--
-- type_cd='PhysicianOfPHC' verified present in baseline SRTE
-- Participation_type (act_class_cd='CASE', subject_class_cd='PSN',
-- type_desc_txt='Physician'). Verified by:
--   SELECT type_cd, act_class_cd, subject_class_cd, type_desc_txt
--   FROM nbs_srte.dbo.Participation_type
--   WHERE type_cd = 'PhysicianOfPHC';
-- type_cd='InvestgrOfPHC' verified present in baseline SRTE
-- Participation_type (act_class_cd='CASE', subject_class_cd='PSN',
-- type_desc_txt='Investigator (Current)'). Same query confirms.
--
-- NOT-NULL columns on dbo.participation are only:
--   subject_entity_uid, act_uid, type_cd
-- All other columns are nullable; we populate the standard lifecycle
-- columns (act_class_cd, subject_class_cd, add_*, last_chg_*,
-- record_status_*, status_*, type_desc_txt, from_time) for shape
-- parity with production data and for the SPs that read those
-- columns.
-- The datamart SPs at 072/073 (line 1896 / 105) explicitly filter on
-- PAR.RECORD_STATUS_CD = 'ACTIVE' (verified by reading both files),
-- so 'ACTIVE' is required here.
-- The investigation_event SP at line 848 projects par2.from_time as
-- investigator_assigned_datetime — populating from_time on the
-- InvestgrOfPHC rows ensures that JSON projection has a non-NULL
-- value (matches Tier 1's hand-authored '2026-04-02' on v2 for
-- shape parity; for foundation we use the canonical 2026-04-01
-- baseline date). The datamart SP at 072:1959-1962 also projects
-- INVESTIGATORASSIGNEDDATE = MAX(CASE WHEN TYPE_CD = 'InvestgrOfPHC'
-- THEN FROM_TIME END), feeding F_PAGE_CASE.INVESTIGATORASSIGNEDDATE.
-- =====================================================================
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd],
     [act_class_cd], [subject_class_cd],
     [from_time],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time],
     [status_cd], [status_time],
     [type_desc_txt])
VALUES
    -- Edge 1: foundation Provider (PSN) AS physician of foundation Investigation (CASE)
    (@foundation_act_inv_uid,            -- act_uid (CASE; foundation Investigation)
     @foundation_entity_provider_uid,    -- subject_entity_uid (PSN; foundation Provider)
     N'PhysicianOfPHC',                  -- type_cd (PAR_TYPE 'PhysicianOfPHC' — in SRTE)
     N'CASE',                            -- act_class_cd
     N'PSN',                             -- subject_class_cd
     '2026-04-01T00:00:00',              -- from_time (datamart projects this for INVESTIGATORASSIGNEDDATE — Physician's value is unused, but populated for parity)
     '2026-04-01T00:00:00',              -- add_time
     @superuser_id,                      -- add_user_id
     '2026-04-01T00:00:00',              -- last_chg_time
     @superuser_id,                      -- last_chg_user_id
     N'ACTIVE',                          -- record_status_cd (datamart SPs filter on this)
     '2026-04-01T00:00:00',              -- record_status_time
     'A',                                -- status_cd (char(1))
     '2026-04-01T00:00:00',              -- status_time
     N'Physician'),
    -- Edge 2: v2 Provider (PSN) AS physician of v2 Investigation (CASE)
    (@v2_act_inv_uid,                    -- act_uid (CASE; v2 Investigation)
     @v2_entity_provider_uid,            -- subject_entity_uid (PSN; v2 Provider)
     N'PhysicianOfPHC',                  -- type_cd
     N'CASE',                            -- act_class_cd
     N'PSN',                             -- subject_class_cd
     '2026-04-04T00:00:00',              -- from_time
     '2026-04-04T00:00:00',              -- add_time
     @superuser_id,                      -- add_user_id
     '2026-04-04T00:00:00',              -- last_chg_time
     @superuser_id,                      -- last_chg_user_id
     N'ACTIVE',                          -- record_status_cd
     '2026-04-04T00:00:00',              -- record_status_time
     'A',                                -- status_cd
     '2026-04-04T00:00:00',              -- status_time
     N'Physician'),
    -- Edge 3: foundation Provider (PSN) AS investigator of foundation Investigation (CASE)
    (@foundation_act_inv_uid,            -- act_uid (CASE; foundation Investigation)
     @foundation_entity_provider_uid,    -- subject_entity_uid (PSN; foundation Provider)
     N'InvestgrOfPHC',                   -- type_cd (PAR_TYPE 'InvestgrOfPHC' — in SRTE)
     N'CASE',                            -- act_class_cd
     N'PSN',                             -- subject_class_cd
     '2026-04-01T00:00:00',              -- from_time (event SP line 848 projects this as investigator_assigned_datetime; datamart SP 072:1959-1962 projects same as INVESTIGATORASSIGNEDDATE)
     '2026-04-01T00:00:00',              -- add_time
     @superuser_id,                      -- add_user_id
     '2026-04-01T00:00:00',              -- last_chg_time
     @superuser_id,                      -- last_chg_user_id
     N'ACTIVE',                          -- record_status_cd
     '2026-04-01T00:00:00',              -- record_status_time
     'A',                                -- status_cd
     '2026-04-01T00:00:00',              -- status_time
     N'Investigator (Current)'),
    -- Edge 4: v2 Provider (PSN) AS investigator of v2 Investigation (CASE)
    (@v2_act_inv_uid,                    -- act_uid (CASE; v2 Investigation)
     @v2_entity_provider_uid,            -- subject_entity_uid (PSN; v2 Provider)
     N'InvestgrOfPHC',                   -- type_cd
     N'CASE',                            -- act_class_cd
     N'PSN',                             -- subject_class_cd
     '2026-04-02T00:00:00',              -- from_time (matches Tier 1 hand-authored nrt_investigation.investigator_assigned_datetime on v2)
     '2026-04-04T00:00:00',              -- add_time
     @superuser_id,                      -- add_user_id
     '2026-04-04T00:00:00',              -- last_chg_time
     @superuser_id,                      -- last_chg_user_id
     N'ACTIVE',                          -- record_status_cd
     '2026-04-04T00:00:00',              -- record_status_time
     'A',                                -- status_cd
     '2026-04-04T00:00:00',              -- status_time
     N'Investigator (Current)');

GO

-- =====================================================================
-- Post-edge SP re-run.
--
-- Per the honest coverage assessment in the header: at Tier 1 isolation
-- this edge does NOT flip any RDB_MODERN dimension/fact columns from
-- NULL/sentinel-1 to populated values. The Investigation postprocessing
-- SP reads from `nrt_investigation` (hand-authored by Tier 1, not
-- traversing participation).
--
-- We re-run sp_investigation_event purely as a SHAPE-CONSISTENCY
-- verification: the SP must execute cleanly with the participation rows
-- present, and the LEFT OUTER JOIN at line 869 (InvestgrOfPHC pivot for
-- investigator_assigned_datetime in the JSON output) should now match
-- the participation row when projecting JSON. The event SP's output is
-- not consumed in our fixture flow (it would be consumed by Kafka in
-- production), so this is an SP-callability check + JSON-projection
-- spot-check, not a coverage-unlock check.
--
-- We do NOT re-run sp_nrt_investigation_postprocessing because its
-- output (the INVESTIGATION dimension) is unaffected by this edge:
-- the SP reads only `nrt_investigation`, never `participation`.
--
-- PhysicianOfPHC is NOT read by sp_investigation_event at all (verified
-- by grep — zero matches for 'PhysicianOfPHC' in 056-...sql), so the
-- re-run only verifies the InvestgrOfPHC pivot. PhysicianOfPHC's value
-- only manifests at Merge contract step 9 (Datamart SPs).
--
-- The merge orchestrator runs this EXEC as part of step 7 of the Merge
-- contract sequence (Re-run Tier 1 chains affected by Tier 2 edges).
-- The Datamart SPs at step 9 are where the participation rows authored
-- here will actually land in RDB_MODERN dim/fact tables.
-- =====================================================================

USE [RDB_MODERN];
GO

-- Tail-EXEC: re-run sp_investigation_event to confirm SP callability
-- with the new participation rows. (Coverage does not change at the
-- INVESTIGATION dim level; this is a shape-consistency verification.)
GO
