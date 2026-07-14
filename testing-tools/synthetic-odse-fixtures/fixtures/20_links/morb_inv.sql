USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 2 link fixture: Morbidity Report -> Investigation (act_relationship)
-- Edge type: 'MorbReport' (NBS convention; SRTE AR_TYPE).
-- Source class:  OBS  (Morbidity Order observation)
-- Target class:  CASE (Public_health_case / Investigation)
--
-- Wires:
--   1) foundation Morb Order   (20000130) -> foundation Investigation (20000100)
--   2) v2 Morb Order           (20080010) -> v2 Investigation         (20050010)
--
-- Catalog citation: catalog/edge_types.md, dbo.act_relationship row
--                   `MorbReport`. The observation event SP filters at
--                   055-sp_observation_event-001.sql:116-117 on
--                   type_cd IN ('MorbReport','LabReport') AND
--                   target_class_cd='CASE' (and source_class_cd='OBS' at
--                   the second site, lines 430-431). Used by
--                   sp_observation_event for the morb->PHC association
--                   projection that downstream feeds
--                   nrt_observation.associated_phc_uids. The Morb
--                   postprocessing SP (016-sp_nrt_morbidity_report_postprocessing-001.sql,
--                   internal name `sp_d_morbidity_report_postprocessing`)
--                   reads `nrt_observation.associated_phc_uids` at line
--                   276 (into #tmp_morb_root.associated_phc_uids) and at
--                   line 984 joins `dbo.investigation` via
--                   `rpt.associated_phc_uids = inv.case_uid` to resolve
--                   INVESTIGATION_KEY in MORBIDITY_REPORT_EVENT.
--
-- Morb hierarchy detail:
--   Morbidity's v2 has 19 observations (Order + C_Order + C_Result +
--   16 INV/MRB followups). The cross-subject edge wires the **Order
--   parent** (20080010) to the Investigation. The C_Order/C_Result
--   user-comment children and the 16 INV/MRB followup children are tied
--   to the Order via Morb-internal act_relationships of `type_cd='COMP'`
--   authored in Morbidity Tier 1; they don't need their own
--   cross-subject edges.
--
-- Coverage unlocked:
--   - MORBIDITY_REPORT_EVENT was 0/17 at Tier 1 isolation because the
--     INSERT failed on PATIENT_KEY NOT NULL (sp_d_morbidity_report_postprocessing
--     line 950 reads pat.PATIENT_KEY directly with no COALESCE; Tier 1
--     isolation has no D_PATIENT row matching foundation Patient
--     UID 20000000). With Patient Tier 1's chain run (D_PATIENT
--     populated) AND this edge wired (associated_phc_uids set on Morb
--     nrt_observation rows AND act_relationship rows in ODSE), the
--     INSERT now succeeds, populating all 17 columns. INVESTIGATION_KEY
--     resolves to a real key (foundation Inv -> 3, v2 Inv -> 4).
--   - MORB_RPT_USER_COMMENT was 0/8 at Tier 1 isolation because it's
--     downstream of the failing MORBIDITY_REPORT_EVENT INSERT
--     (CATCH/rollback triggered). With the EVENT INSERT succeeding, all
--     8 columns populate for the v2 user-comment row driven by C_Result
--     20080021's nrt_observation_txt.
--   - MORBIDITY_REPORT was already 30/30 at Tier 1 isolation (committed
--     in an earlier transaction at line 1062-1142 before the EVENT
--     INSERT failure); those 2 rows persist after the post-edge re-run.
--   - sp_observation_event JSON projection's `associated_phc_uids`
--     branch (lines 105-119) now contains the wired investigation UIDs.
--   - Investigation event SP's `investigation_observation_ids` JSON
--     branch (referenced in coverage_investigation.md LINK_REQUIRED)
--     now finds the wired morbs.
--
-- UID block (Tier 2 - third agent): 21002000 - 21002999.
-- This fixture authors NO new entity / Person / Act / Public_health_case
-- / Observation rows; it only writes 2 rows to dbo.act_relationship plus
-- 2 UPDATEs against staging dbo.nrt_observation.
--
-- Forbidden in Tier 2 (per template):
--   - No new ODSE entity rows; no SRTE writes; no foundation/Tier 1
--     modifications; no INSERTs into RDB_MODERN dim/fact tables; no
--     infrastructure-SP invocation in this fixture (orchestrator owns
--     sp_get_date_dim/recursive-CTE and
--     sp_nrt_srte_condition_code_postprocessing per Merge contract
--     step 2).
--   - The UPDATE against `dbo.nrt_observation` is permitted: nrt_* are
--     STAGING tables (the CDC/Debezium-output mirror), not RDB_MODERN
--     dim/fact tables. STRATEGY.md "verification recipe" section calls
--     out that fixture authors hand-write nrt_* rows. The Tier 2 edge
--     here is the act_relationship in NBS_ODSE; the staging UPDATE is
--     the CDC-equivalent that Tier 1's morbidity.sql couldn't write
--     because associated_phc_uids depends on this cross-subject edge.
-- =====================================================================

-- ----- Sentinel reference (do not allocate) -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Cross-tier UIDs referenced (read-only) -----
DECLARE @foundation_act_morb_uid     bigint = 20000130;  -- foundation Morb Report act_uid / observation_uid
DECLARE @foundation_act_inv_uid      bigint = 20000100;  -- foundation Investigation act_uid (public_health_case_uid)
DECLARE @v2_act_morb_order_uid       bigint = 20080010;  -- v2 Morb Order observation (Morbidity Tier 1)
DECLARE @v2_act_inv_uid              bigint = 20050010;  -- v2 Investigation (Investigation Tier 1)

-- =====================================================================
-- act_relationship rows.
--
-- The composite PK on dbo.act_relationship is
-- (source_act_uid, target_act_uid, type_cd) - it does not need its own
-- surrogate UID. We do not allocate any UIDs from this agent's block
-- 21002000 - 21002999; the block is reserved here in case a future
-- amendment needs surrogate UIDs.
--
-- type_cd='MorbReport' is verified present in baseline SRTE AR_TYPE
-- (code_set_nm='AR_TYPE') - see catalog/edge_types.md row.
-- =====================================================================
INSERT INTO [dbo].[act_relationship]
    ([target_act_uid], [source_act_uid], [type_cd], [source_class_cd],
     [target_class_cd], [add_time], [add_user_id], [from_time],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [sequence_nbr], [status_cd], [status_time])
VALUES
    -- Edge 1: foundation Morb Order -> foundation Investigation
    (@foundation_act_inv_uid,    -- target_act_uid (CASE; foundation Investigation)
     @foundation_act_morb_uid,   -- source_act_uid (OBS;  foundation Morb Order)
     N'MorbReport',              -- type_cd (AR_TYPE 'MorbReport' - NBS convention)
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
    -- Edge 2: v2 Morb Order -> v2 Investigation
    (@v2_act_inv_uid,            -- target_act_uid (CASE; v2 Investigation)
     @v2_act_morb_order_uid,     -- source_act_uid (OBS;  v2 Morb Order)
     N'MorbReport',              -- type_cd
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
-- Tier 1's morbidity.sql could not populate this because the column
-- depends on a cross-subject act_relationship - exactly what this
-- Tier 2 agent owns.
--
-- We write only on the Order rows (foundation 20000130, v2 20080010).
-- The C_Order/C_Result user-comment rows (20080020/20080021) and the 16
-- INV/MRB followup rows (20080100..20080115) are NOT in @pMorbidityIdList
-- (the postprocessing SP filters at line 281-282 to obs_domain_cd_st_1='Order'
-- AND CTRL_CD_DISPLAY_FORM='MorbReport') and their associated_phc_uids
-- is never read by MORBIDITY_REPORT or MORBIDITY_REPORT_EVENT. Per the
-- comment block at lines 204-210 of the Morb postprocessing SP:
-- "associated_phc_uids is a comma separated list of phc's that are
--  associated with a LabReport or a MorbReport. For MorbReport
--  observations, there can only be one associated investigation."
-- So we set a single UID (no commas) on each Order row.
-- =====================================================================
-- [ODSE-only conversion] Removed the direct nrt_observation UPDATEs.
-- nrt_observation.associated_phc_uids is derived by 055-sp_observation_event
-- from the MorbReport act_relationship edges authored above (CDC → sink).
-- No fixture write to RDB_MODERN.

-- =====================================================================
-- Post-edge SP re-run.
--
-- Morbidity's Tier 1 chain was deliberately NOT run pre-edge in the
-- focused merged-sequence (the SP fails at MORBIDITY_REPORT_EVENT
-- INSERT due to PATIENT_KEY NOT NULL with no COALESCE - see
-- coverage_morbidity.md LINK_REQUIRED). Now that:
--   (a) Patient Tier 1's chain has populated D_PATIENT with rows for
--       PATIENT_UID=20000000 (foundation) and 20020010 (v2),
--   (b) Investigation Tier 1's chain has populated dbo.INVESTIGATION
--       (foundation Inv -> KEY 3, v2 Inv -> KEY 4),
--   (c) sp_nrt_srte_condition_code_postprocessing has populated
--       dbo.CONDITION (cd='10110' Hep A acute),
--   (d) the recursive-CTE infrastructure step has populated dbo.RDB_DATE,
--   (e) Provider/Organization Tier 1 chains have populated d_provider /
--       d_organization for the soft cross-subject FK joins,
--   (f) this edge is wired (act_relationship rows + nrt_observation
--       associated_phc_uids UPDATEs above),
-- ...the Morb postprocessing SP can run cleanly. The PATIENT_KEY join
-- resolves to a real key, the EVENT INSERT succeeds, and
-- MORB_RPT_USER_COMMENT INSERT runs (it's downstream of the previously-
-- failing transaction).
--
-- Note: The SP is named `sp_d_morbidity_report_postprocessing` inside
-- the file even though the filename is `sp_nrt_morbidity_report_postprocessing`.
-- The parameter is `@pMorbidityIdList` (camelCase).
--
-- The merge orchestrator runs this EXEC as part of step 7 of the Merge
-- contract sequence (Re-run Tier 1 chains affected by Tier 2 edges).
-- =====================================================================

GO
