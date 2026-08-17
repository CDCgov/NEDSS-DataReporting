USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 2 link fixture: Treatment -> Investigation (TreatmentToPHC) and
--                      Treatment -> Morbidity Order (TreatmentToMorb)
-- Source class:  TRMT (Treatment Act)
-- Target class:  CASE (Public_health_case) for TreatmentToPHC
--                OBS  (Morbidity Order observation) for TreatmentToMorb
--
-- Wires (TreatmentToPHC, 3 pairs):
--   1) foundation Treatment (20000150) -> foundation Investigation (20000100)
--   2) v2 Treatment         (20100010) -> v2 Investigation         (20050010)
--   3) v3 Treatment         (20100020) -> foundation Investigation (20000100)
--
-- Wires (TreatmentToMorb, 3 pairs):
--   1) foundation Treatment (20000150) -> foundation Morb Order (20000130)
--   2) v2 Treatment         (20100010) -> v2 Morb Order         (20080010)
--   3) v3 Treatment         (20100020) -> foundation Morb Order (20000130)
--
-- Catalog citations:
--   - `TreatmentToPHC`: catalog/edge_types.md, dbo.act_relationship row
--     `TreatmentToPHC` (in SRTE AR_TYPE). SP filter at
--     `070-sp_treatment_event-001.sql:127-129`
--     (`type_cd='TreatmentToPHC' AND target_class_cd='CASE' AND
--      source_class_cd='TRMT'`).
--   - `TreatmentToMorb`: catalog/edge_types.md, MISSING_FROM_SRTE row
--     for `TreatmentToMorb` — RTR SPs filter on the literal regardless.
--     SP filter at `070-sp_treatment_event-001.sql:82-86`
--     (`type_cd='TreatmentToMorb' AND target_class_cd='OBS' AND
--      source_class_cd='TRMT'`). The corresponding code is NOT in any
--     SRTE code set (verified per Phase B). Authoring with the literal
--     value matches the SP's literal filter.
--
-- This edge is shape-consistency, not coverage-unlock:
--   - The Treatment postprocessing SP does NOT read
--     `act_relationship` directly. It reads
--     `nrt_treatment.associated_phc_uids` (line 134) for INVESTIGATION_KEY
--     resolution and `nrt_treatment.morbidity_uid` (line 215) for
--     MORB_RPT_KEY resolution.
--   - At Tier 1 isolation (Treatment chain only), 11/11 TREATMENT_EVENT
--     columns populate cleanly because every cross-subject FK is
--     `COALESCE(<lookup>, 1)`. v2 already resolves INVESTIGATION_KEY/
--     CONDITION_KEY because Tier 1 set
--     `nrt_treatment.associated_phc_uids='20000100'` for v2.
--   - Foundation (20000150) and v3 (20100020) had
--     `nrt_treatment.associated_phc_uids=NULL` at Tier 1 — so they
--     resolved INVESTIGATION_KEY/CONDITION_KEY to sentinel 1.
--     Updating their staging mirror to point at foundation Investigation
--     20000100 (which `TreatmentToPHC` here also wires at the ODSE
--     graph layer) flips those keys to real values on post-edge re-run.
--
-- ODSE-graph correctness:
--   - MasterETL traverses the act_relationship; RTR reads the
--     `nrt_treatment` soft-ref. For the comparison test to make sense,
--     both should reach the same endpoint. This fixture authors the
--     act_relationship rows so both pathways agree.
--
-- UID block (Tier 2 - fourth agent): 21003000 - 21003999.
-- This fixture authors NO new entity / Person / Act / Public_health_case /
-- Observation rows; it only writes 6 rows to dbo.act_relationship plus
-- 2 UPDATEs against staging dbo.nrt_treatment.
--
-- Forbidden in Tier 2 (per template):
--   - No new ODSE entity rows; no SRTE writes; no foundation/Tier 1
--     modifications; no INSERTs into RDB_MODERN dim/fact tables; no
--     infrastructure-SP invocation in this fixture (orchestrator owns
--     `sp_get_date_dim` (or recursive-CTE) and
--     `sp_nrt_srte_condition_code_postprocessing` per Merge contract
--     step 2).
--   - The UPDATE against `dbo.nrt_treatment` is permitted: nrt_* are
--     STAGING tables (the CDC/Debezium-output mirror), not RDB_MODERN
--     dim/fact tables. STRATEGY.md "verification recipe" section calls
--     out that fixture authors hand-write nrt_* rows. The Tier 2 edge
--     here is the act_relationship in NBS_ODSE; the staging UPDATE is
--     the CDC-equivalent of what the event SP would project (see
--     `070-sp_treatment_event-001.sql:118-131`, `STRING_AGG` of
--     `act_relationship.target_act_uid` filtered by `TreatmentToPHC`
--     INTO `associated_phc_uids` JSON field).
-- =====================================================================

-- ----- Sentinel reference (do not allocate) -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Cross-tier UIDs referenced (read-only) -----
DECLARE @foundation_act_treatment_uid bigint = 20000150;  -- foundation Treatment act_uid / treatment_uid
DECLARE @foundation_act_inv_uid       bigint = 20000100;  -- foundation Investigation act_uid (public_health_case_uid)
DECLARE @foundation_act_morb_uid      bigint = 20000130;  -- foundation Morb Order observation_uid
DECLARE @v2_act_treatment_uid         bigint = 20100010;  -- v2 Treatment (Treatment Tier 1)
DECLARE @v3_act_treatment_uid         bigint = 20100020;  -- v3 Treatment (Treatment Tier 1, cd='OTH')
DECLARE @v2_act_inv_uid               bigint = 20050010;  -- v2 Investigation (Investigation Tier 1)
DECLARE @v2_act_morb_order_uid        bigint = 20080010;  -- v2 Morb Order (Morbidity Tier 1)

-- =====================================================================
-- act_relationship rows (6 total: 3 TreatmentToPHC + 3 TreatmentToMorb).
--
-- Composite PK is (source_act_uid, target_act_uid, type_cd). No surrogate
-- UID needed; the 21003000-21003999 block is reserved for any future
-- amendment.
--
-- type_cd='TreatmentToPHC' is in baseline SRTE AR_TYPE.
-- type_cd='TreatmentToMorb' is MISSING_FROM_SRTE per Phase B catalog —
-- RTR's SP filters on the literal regardless.
-- =====================================================================
INSERT INTO [dbo].[act_relationship]
    ([target_act_uid], [source_act_uid], [type_cd], [source_class_cd],
     [target_class_cd], [add_time], [add_user_id], [from_time],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [sequence_nbr], [status_cd], [status_time])
VALUES
    -- =================================================================
    -- TreatmentToPHC (TRMT -> CASE), 3 rows
    -- =================================================================
    -- Edge 1: foundation Treatment -> foundation Investigation
    (@foundation_act_inv_uid,        -- target_act_uid (CASE)
     @foundation_act_treatment_uid,  -- source_act_uid (TRMT)
     N'TreatmentToPHC',              -- type_cd (AR_TYPE; in SRTE)
     N'TRMT',                        -- source_class_cd
     N'CASE',                        -- target_class_cd
     '2026-04-01T00:00:00',          -- add_time
     @superuser_id,                  -- add_user_id
     '2026-04-01T00:00:00',          -- from_time
     CAST(GETDATE() AS DATE),          -- last_chg_time
     @superuser_id,                  -- last_chg_user_id
     N'ACTIVE',                      -- record_status_cd
     '2026-04-01T00:00:00',          -- record_status_time
     1,                              -- sequence_nbr
     N'A',                           -- status_cd
     '2026-04-01T00:00:00'),         -- status_time
    -- Edge 2: v2 Treatment -> v2 Investigation
    (@v2_act_inv_uid,                -- target_act_uid (CASE)
     @v2_act_treatment_uid,          -- source_act_uid (TRMT)
     N'TreatmentToPHC',              -- type_cd
     N'TRMT',                        -- source_class_cd
     N'CASE',                        -- target_class_cd
     '2026-04-04T00:00:00',          -- add_time
     @superuser_id,                  -- add_user_id
     '2026-04-04T00:00:00',          -- from_time
     CAST(GETDATE() AS DATE),          -- last_chg_time
     @superuser_id,                  -- last_chg_user_id
     N'ACTIVE',                      -- record_status_cd
     '2026-04-04T00:00:00',          -- record_status_time
     1,                              -- sequence_nbr
     N'A',                           -- status_cd
     '2026-04-04T00:00:00'),         -- status_time
    -- Edge 3: v3 Treatment -> foundation Investigation (multi-trmt-per-inv)
    (@foundation_act_inv_uid,        -- target_act_uid (CASE)
     @v3_act_treatment_uid,          -- source_act_uid (TRMT)
     N'TreatmentToPHC',              -- type_cd
     N'TRMT',                        -- source_class_cd
     N'CASE',                        -- target_class_cd
     '2026-04-04T00:00:00',          -- add_time
     @superuser_id,                  -- add_user_id
     '2026-04-04T00:00:00',          -- from_time
     CAST(GETDATE() AS DATE),          -- last_chg_time
     @superuser_id,                  -- last_chg_user_id
     N'ACTIVE',                      -- record_status_cd
     '2026-04-04T00:00:00',          -- record_status_time
     1,                              -- sequence_nbr
     N'A',                           -- status_cd
     '2026-04-04T00:00:00'),         -- status_time
    -- =================================================================
    -- TreatmentToMorb (TRMT -> OBS), 3 rows
    -- =================================================================
    -- Edge 4: foundation Treatment -> foundation Morb Order
    (@foundation_act_morb_uid,       -- target_act_uid (OBS)
     @foundation_act_treatment_uid,  -- source_act_uid (TRMT)
     N'TreatmentToMorb',             -- type_cd (MISSING_FROM_SRTE; SP filters literal)
     N'TRMT',                        -- source_class_cd
     N'OBS',                         -- target_class_cd
     '2026-04-01T00:00:00',          -- add_time
     @superuser_id,                  -- add_user_id
     '2026-04-01T00:00:00',          -- from_time
     CAST(GETDATE() AS DATE),          -- last_chg_time
     @superuser_id,                  -- last_chg_user_id
     N'ACTIVE',                      -- record_status_cd
     '2026-04-01T00:00:00',          -- record_status_time
     1,                              -- sequence_nbr
     N'A',                           -- status_cd
     '2026-04-01T00:00:00'),         -- status_time
    -- Edge 5: v2 Treatment -> v2 Morb Order
    (@v2_act_morb_order_uid,         -- target_act_uid (OBS)
     @v2_act_treatment_uid,          -- source_act_uid (TRMT)
     N'TreatmentToMorb',             -- type_cd
     N'TRMT',                        -- source_class_cd
     N'OBS',                         -- target_class_cd
     '2026-04-04T00:00:00',          -- add_time
     @superuser_id,                  -- add_user_id
     '2026-04-04T00:00:00',          -- from_time
     CAST(GETDATE() AS DATE),          -- last_chg_time
     @superuser_id,                  -- last_chg_user_id
     N'ACTIVE',                      -- record_status_cd
     '2026-04-04T00:00:00',          -- record_status_time
     1,                              -- sequence_nbr
     N'A',                           -- status_cd
     '2026-04-04T00:00:00'),         -- status_time
    -- Edge 6: v3 Treatment -> foundation Morb Order
    (@foundation_act_morb_uid,       -- target_act_uid (OBS)
     @v3_act_treatment_uid,          -- source_act_uid (TRMT)
     N'TreatmentToMorb',             -- type_cd
     N'TRMT',                        -- source_class_cd
     N'OBS',                         -- target_class_cd
     '2026-04-04T00:00:00',          -- add_time
     @superuser_id,                  -- add_user_id
     '2026-04-04T00:00:00',          -- from_time
     CAST(GETDATE() AS DATE),          -- last_chg_time
     @superuser_id,                  -- last_chg_user_id
     N'ACTIVE',                      -- record_status_cd
     '2026-04-04T00:00:00',          -- record_status_time
     1,                              -- sequence_nbr
     N'A',                           -- status_cd
     '2026-04-04T00:00:00');         -- status_time

GO

-- =====================================================================
-- Staging UPDATE: nrt_treatment.associated_phc_uids
--
-- Mirrors what the CDC pipeline (sp_treatment_event -> Debezium ->
-- Kafka -> kafka-connect JDBC sink -> nrt_treatment) would produce
-- after the act_relationship rows above are wired.
-- sp_treatment_event lines 118-131 build a CSV STRING_AGG of
-- `act_relationship.target_act_uid` where `type_cd='TreatmentToPHC'`,
-- `target_class_cd='CASE'`, `source_class_cd='TRMT'`, grouped by
-- source_act_uid - that becomes the JSON `associated_phc_uids` field,
-- which the kafka-connect sink would materialize into
-- `nrt_treatment.associated_phc_uids`.
--
-- Tier 1's treatment.sql set associated_phc_uids='20000100' on v2
-- (UID 20100010) only; foundation (20000150) and v3 (20100020) were
-- left NULL at Tier 1 because the cross-subject act_relationship
-- depends on Tier 2 — exactly what this fixture wires.
--
-- Effect: post-edge re-run of `sp_nrt_treatment_postprocessing` will
-- now resolve INVESTIGATION_KEY (foundation Inv -> 3) and CONDITION_KEY
-- (Hep A acute, cd='10110' -> 42) for the foundation and v3 Treatment
-- rows. v2 is unchanged (Tier 1 already had it correct).
-- =====================================================================
-- [ODSE-only conversion] Removed the direct nrt_treatment UPDATEs.
-- nrt_treatment.associated_phc_uids is derived by 070-sp_treatment_event
-- (STRING_AGG over act_relationship type_cd='TreatmentToPHC', target CASE)
-- → CDC/sink → nrt_treatment. The TreatmentToPHC act_relationship edges
-- authored above are the only input needed. No fixture write to RDB_MODERN.

-- =====================================================================
-- Post-edge SP re-run.
--
-- Treatment's Tier 1 chain ran cleanly pre-edge (11/11 TREATMENT_EVENT
-- columns populated, but with sentinel 1 in cross-subject FK columns
-- when associated_phc_uids was NULL). Re-running after this fixture's
-- staging UPDATEs upgrades sentinel-1 INVESTIGATION_KEY / CONDITION_KEY
-- to real keys for foundation (20000150) and v3 (20100020).
-- v2 (20100010) is unchanged from Tier 1 since its associated_phc_uids
-- was already wired by Tier 1.
--
-- MORB_RPT_KEY remains sentinel 1 in this focused merged-sequence
-- because MORBIDITY_REPORT is empty for our morbidity_uid (20000130);
-- Morbidity's chain depends on the morb_inv Tier 2 edge being applied
-- (a different Tier 2 agent's deliverable). After the full merge
-- (foundation + all Tier 1 + all Tier 2), MORB_RPT_KEY will resolve
-- to a real key for v2 Treatment (whose nrt_treatment.morbidity_uid
-- is 20000130).
--
-- TREATMENT_DT_KEY for foundation/v3 also remains sentinel 1 because
-- their nrt_treatment.treatment_date is NULL by Tier 1 design (only
-- v2 has a real treatment_date). Not in scope for this Tier 2 edge.
--
-- The merge orchestrator runs this EXEC as part of step 7 of the Merge
-- contract sequence (Re-run Tier 1 chains affected by Tier 2 edges).
-- =====================================================================

GO
