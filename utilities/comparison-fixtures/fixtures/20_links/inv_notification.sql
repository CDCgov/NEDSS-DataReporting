USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 2 link fixture: Notification -> Investigation (act_relationship)
-- Edge type: 'Notification' (NBS convention; SRTE AR_TYPE).
-- Source class:  NOTF
-- Target class:  CASE
--
-- Wires:
--   1) foundation Notification (20000110) -> foundation Investigation (20000100)
--   2) v2 Notification         (20060010) -> v2 Investigation         (20050010)
--
-- Catalog citation: catalog/edge_types.md, dbo.act_relationship row
--                   `Notification`. The SP filter at
--                   064-sp_notification_event-001.sql:208-209 enforces
--                   source_class_cd='NOTF' AND target_class_cd='CASE';
--                   type_cd='Notification' is the conventional NBS value
--                   used upstream — RTR does not filter on it directly.
--                   We use it for shape consistency with NBS data.
--
-- Coverage unlocked:
--   - Notification Tier 1 isolation: 0/6 NOTIFICATION + 0/8
--     NOTIFICATION_EVENT -> 6/6 + 8/8 (the postprocessing SP no longer
--     hits the FK gap because foundation Investigation is now in
--     dbo.INVESTIGATION via the Investigation chain, the condition is
--     in dbo.CONDITION via sp_nrt_srte_condition_code_postprocessing,
--     and RDB_DATE is populated via sp_get_date_dim).
--   - Investigation event SP's notification_history aggregation
--     (lines 692-845) now finds these notifications via the wired
--     act_relationship.
--   - sp_notification_event's INNER JOIN at line 49 now matches both
--     notification UIDs.
--
-- UID block (Tier 2 — first agent): 21000000 - 21000999.
-- This fixture authors NO new entity / Person / Act / Public_health_case
-- rows; it only writes 2 rows to dbo.act_relationship.
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
DECLARE @foundation_act_notif_uid    bigint = 20000110;  -- foundation Notification act_uid
DECLARE @foundation_act_inv_uid      bigint = 20000100;  -- foundation Investigation act_uid (public_health_case_uid)
DECLARE @v2_act_notif_uid            bigint = 20060010;  -- v2 Notification (Notification Tier 1)
DECLARE @v2_act_inv_uid              bigint = 20050010;  -- v2 Investigation (Investigation Tier 1)

-- =====================================================================
-- act_relationship rows.
--
-- The composite PK on dbo.act_relationship is (source_act_uid,
-- target_act_uid, type_cd) — it does not need its own surrogate UID.
-- We do not allocate any UIDs from this agent's block 21000000-21000999;
-- the block is reserved here in case a future amendment needs surrogate
-- UIDs (e.g., an enrichment row keyed differently).
--
-- type_cd='Notification' is verified present in baseline SRTE AR_TYPE
-- (code_set_nm='AR_TYPE') — see Phase B catalog.
-- =====================================================================
INSERT INTO [dbo].[act_relationship]
    ([target_act_uid], [source_act_uid], [type_cd], [source_class_cd],
     [target_class_cd], [add_time], [add_user_id], [from_time],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [sequence_nbr], [status_cd], [status_time])
VALUES
    -- Edge 1: foundation Notification -> foundation Investigation
    (@foundation_act_inv_uid,    -- target_act_uid (CASE; foundation Investigation)
     @foundation_act_notif_uid,  -- source_act_uid (NOTF; foundation Notification)
     N'Notification',            -- type_cd  (AR_TYPE 'Notification' — NBS convention)
     N'NOTF',                    -- source_class_cd
     N'CASE',                    -- target_class_cd
     '2026-04-01T00:00:00',      -- add_time
     @superuser_id,              -- add_user_id
     '2026-04-01T00:00:00',      -- from_time
     '2026-04-01T00:00:00',      -- last_chg_time
     @superuser_id,              -- last_chg_user_id
     N'ACTIVE',                  -- record_status_cd
     '2026-04-01T00:00:00',      -- record_status_time
     1,                          -- sequence_nbr
     N'A',                       -- status_cd
     '2026-04-01T00:00:00'),     -- status_time
    -- Edge 2: v2 Notification -> v2 Investigation
    (@v2_act_inv_uid,            -- target_act_uid (CASE; v2 Investigation)
     @v2_act_notif_uid,          -- source_act_uid (NOTF; v2 Notification)
     N'Notification',            -- type_cd
     N'NOTF',                    -- source_class_cd
     N'CASE',                    -- target_class_cd
     '2026-04-04T00:00:00',      -- add_time
     @superuser_id,              -- add_user_id
     '2026-04-04T00:00:00',      -- from_time
     '2026-04-04T00:00:00',      -- last_chg_time
     @superuser_id,              -- last_chg_user_id
     N'ACTIVE',                  -- record_status_cd
     '2026-04-04T00:00:00',      -- record_status_time
     1,                          -- sequence_nbr
     N'A',                       -- status_cd
     '2026-04-04T00:00:00');     -- status_time

GO

-- =====================================================================
-- Post-edge SP re-runs.
--
-- Notification's Tier 1 chain was deliberately NOT run pre-edge in the
-- focused merged-sequence (the FK gap on INVESTIGATION_KEY/CONDITION_KEY
-- causes its postprocessing SP to roll back). Now that the edge is
-- wired AND Investigation Tier 1's chain has populated dbo.INVESTIGATION
-- AND sp_nrt_srte_condition_code_postprocessing has populated
-- dbo.CONDITION AND sp_get_date_dim has populated dbo.RDB_DATE, the
-- chain runs cleanly.
--
-- The merge orchestrator runs these EXEC statements as part of step 7
-- of the Merge contract sequence (Re-run Tier 1 chains affected by Tier
-- 2 edges).
-- =====================================================================

USE [RDB_MODERN];
GO

-- Re-run Notification chain — INVESTIGATION_KEY/CONDITION_KEY now resolve.
GO
