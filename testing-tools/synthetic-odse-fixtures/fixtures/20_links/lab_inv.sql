USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 2 link fixture: Lab Report -> Investigation (act_relationship)
-- Edge type: 'LabReport' (NBS convention; SRTE AR_TYPE).
-- Source class:  OBS  (Lab Order observation)
-- Target class:  CASE (Public_health_case / Investigation)
--
-- Wires:
--   1) foundation Lab Order   (20000120) -> foundation Investigation (20000100)
--   2) v2 Lab Order           (20070010) -> v2 Investigation         (20050010)
--
-- Catalog citation: catalog/edge_types.md, dbo.act_relationship row
--                   `LabReport`. The observation event SP filters at
--                   055-sp_observation_event-001.sql:116-117 and :430-431
--                   on type_cd IN ('MorbReport','LabReport') AND
--                   target_class_cd='CASE' (and source_class_cd='OBS' for
--                   the second site). Used by sp_observation_event for
--                   the lab->PHC association projection that downstream
--                   feeds nrt_observation.associated_phc_uids.
--
-- Lab hierarchy detail:
--   Lab's v2 has 4 observations (Order parent + Result child + C_Order +
--   C_Result). The cross-subject edge wires the Order parent (20070010)
--   to the Investigation. The Result/C_Order/C_Result children are tied
--   via lab-internal edges (Result->Order COMP, C_Order->Order APND,
--   C_Result->C_Order COMP);
--   they don't need their own cross-subject edges.
--
-- Coverage unlocked:
--   - LAB_TEST_RESULT.INVESTIGATION_KEY: was sentinel 1 for both rows;
--     after edge wired and Lab postprocessing re-runs, resolves to
--     INVESTIGATION_KEY 3 (foundation Inv) for foundation Lab and 4
--     (v2 Inv) for v2 Lab. The postprocessing SP at
--     017-sp_d_labtest_result_postprocessing-001.sql:117 reads
--     `nrt_observation.associated_phc_uids` and at line 343-346 joins
--     dbo.investigation via STRING_SPLIT against `case_uid`. Tier 1's
--     Lab fixture left associated_phc_uids NULL (it's the CDC-mirror of
--     the act_relationship that this Tier 2 edge wires). We update
--     nrt_observation post-edge to mirror what CDC/Debezium would
--     produce after sp_observation_event consumed the new act_relationship.
--   - sp_observation_event JSON projection's `associated_phc_uids`
--     branch (lines 105-119) now contains the wired investigation UIDs.
--   - Investigation event SP's `investigation_observation_ids` JSON
--     branch (referenced in coverage_investigation.md LINK_REQUIRED #14)
--     now finds the wired labs.
--
-- UID block (Tier 2 - second agent): 21001000-21001999.
-- This fixture authors NO new entity / Person / Act / Public_health_case
-- / Observation rows; it only writes 2 rows to dbo.act_relationship plus
-- 2 UPDATEs against staging dbo.nrt_observation.
--
-- Forbidden in Tier 2 (per template):
--   - No new ODSE entity rows; no SRTE writes; no foundation/Tier 1
--     modifications; no INSERTs into RDB_MODERN dim/fact tables; no
--     infrastructure-SP invocation in this fixture (orchestrator owns
--     sp_get_date_dim and sp_nrt_srte_condition_code_postprocessing
--     per Merge contract step 2).
--   - The UPDATE against `dbo.nrt_observation` is permitted: nrt_* are
--     STAGING tables (the CDC/Debezium-output mirror), not RDB_MODERN
--     dim/fact tables. STRATEGY.md "verification recipe" section calls
--     out that fixture authors hand-write nrt_* rows. The Tier 2 edge
--     here is the act_relationship in NBS_ODSE; the staging UPDATE is
--     the CDC-equivalent that Tier 1's lab.sql couldn't write because
--     associated_phc_uids depends on this cross-subject edge.
-- =====================================================================

-- ----- Sentinel reference (do not allocate) -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Cross-tier UIDs referenced (read-only) -----
DECLARE @foundation_act_lab_uid      bigint = 20000120;  -- foundation Lab Report act_uid / observation_uid
DECLARE @foundation_act_inv_uid      bigint = 20000100;  -- foundation Investigation act_uid (public_health_case_uid)
DECLARE @v2_act_lab_order_uid        bigint = 20070010;  -- v2 Lab Order observation (Lab Tier 1)
DECLARE @v2_act_inv_uid              bigint = 20050010;  -- v2 Investigation (Investigation Tier 1)

-- =====================================================================
-- act_relationship rows.
--
-- The composite PK on dbo.act_relationship is
-- (source_act_uid, target_act_uid, type_cd) - it does not need its own
-- surrogate UID. We do not allocate any UIDs from this agent's block
-- 21001000-21001999; the block is reserved here in case a future
-- amendment needs surrogate UIDs.
--
-- type_cd='LabReport' is verified present in baseline SRTE AR_TYPE
-- (code_set_nm='AR_TYPE') - see catalog/edge_types.md row.
-- =====================================================================
INSERT INTO [dbo].[act_relationship]
    ([target_act_uid], [source_act_uid], [type_cd], [source_class_cd],
     [target_class_cd], [add_time], [add_user_id], [from_time],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [sequence_nbr], [status_cd], [status_time])
VALUES
    -- Edge 1: foundation Lab Order -> foundation Investigation
    (@foundation_act_inv_uid,    -- target_act_uid (CASE; foundation Investigation)
     @foundation_act_lab_uid,    -- source_act_uid (OBS;  foundation Lab Order)
     N'LabReport',               -- type_cd (AR_TYPE 'LabReport' - NBS convention)
     N'OBS',                     -- source_class_cd
     N'CASE',                    -- target_class_cd
     '2026-04-01T00:00:00',      -- add_time
     @superuser_id,              -- add_user_id
     '2026-04-01T00:00:00',      -- from_time
     CAST(GETDATE() AS DATE),      -- last_chg_time
     @superuser_id,              -- last_chg_user_id
     N'ACTIVE',                  -- record_status_cd
     '2026-04-01T00:00:00',      -- record_status_time
     1,                          -- sequence_nbr
     N'A',                       -- status_cd
     '2026-04-01T00:00:00'),     -- status_time
    -- Edge 2: v2 Lab Order -> v2 Investigation
    (@v2_act_inv_uid,            -- target_act_uid (CASE; v2 Investigation)
     @v2_act_lab_order_uid,      -- source_act_uid (OBS;  v2 Lab Order)
     N'LabReport',               -- type_cd
     N'OBS',                     -- source_class_cd
     N'CASE',                    -- target_class_cd
     '2026-04-04T00:00:00',      -- add_time
     @superuser_id,              -- add_user_id
     '2026-04-04T00:00:00',      -- from_time
     CAST(GETDATE() AS DATE),      -- last_chg_time
     @superuser_id,              -- last_chg_user_id
     N'ACTIVE',                  -- record_status_cd
     '2026-04-04T00:00:00',      -- record_status_time
     1,                          -- sequence_nbr
     N'A',                       -- status_cd
     '2026-04-04T00:00:00');     -- status_time

GO

-- =====================================================================
-- Staging UPDATE: nrt_observation.associated_phc_uids
--
-- This mirrors what the CDC pipeline (sp_observation_event ->
-- Debezium -> Kafka -> kafka-connect JDBC sink -> nrt_observation)
-- would produce after the act_relationship rows above are wired.
-- sp_observation_event lines 105-119 build a CSV STRING_AGG of
-- act_relationship.target_act_uid where type_cd IN ('MorbReport',
-- 'LabReport') AND target_class_cd='CASE' AND source_act_uid =
-- observation.observation_uid - that becomes the JSON
-- `associated_phc_uids` field, which the kafka-connect sink would
-- materialize into nrt_observation.associated_phc_uids.
--
-- Tier 1's lab.sql could not populate this because the column depends
-- on a cross-subject act_relationship - exactly what this Tier 2
-- agent owns.
--
-- We write only on the Order rows (foundation 20000120, v2 20070010);
-- the Result/C_Order/C_Result children don't carry their own
-- associated_phc_uids - the postprocessing SP at line 117 reads
-- `no2.associated_phc_uids` keyed by `lab_test_uid` (which for Result
-- rows is the Result's own observation_uid; the SP path that resolves
-- INVESTIGATION_KEY then re-derives via `tst.associated_phc_uids` =
-- the Result row's mirrored value). To match the upstream CDC
-- behavior, we set associated_phc_uids on Result rows too so the
-- INVESTIGATION_KEY join resolves for both Order and Result LAB_TEST_RESULT
-- variants.
-- =====================================================================
-- [ODSE-only conversion] Removed the direct nrt_observation UPDATEs.
-- nrt_observation.associated_phc_uids is derived by 055-sp_observation_event
-- (STRING_AGG over act_relationship type_cd IN ('LabReport','MorbReport'),
-- target CASE) → CDC/sink → nrt_observation. The LabReport act_relationship
-- edges authored above are the only input needed; the pipeline produces the
-- staging value. No fixture write to RDB_MODERN.

-- =====================================================================
-- Post-edge SP re-runs.
--
-- Lab's Tier 1 chain was already run pre-edge; it resolved
-- LAB_TEST_RESULT.INVESTIGATION_KEY to sentinel 1 because
-- associated_phc_uids was NULL. Now that the edge is wired AND the
-- staging mirror is updated AND Investigation Tier 1's chain has
-- populated dbo.INVESTIGATION (foundation Inv -> KEY 3, v2 Inv -> KEY 4),
-- re-running the Lab postprocessing chain will resolve INVESTIGATION_KEY
-- to those real keys.
--
-- The merge orchestrator runs these EXEC statements as part of step 7
-- of the Merge contract sequence (Re-run Tier 1 chains affected by Tier
-- 2 edges).
--
-- We re-run BOTH lab postprocessing SPs because both write/update
-- LAB_TEST_RESULT (sp_d_lab_test_postprocessing only writes LAB_TEST,
-- but sp_d_labtest_result_postprocessing is the one that resolves
-- INVESTIGATION_KEY via associated_phc_uids).
-- =====================================================================

GO

GO
