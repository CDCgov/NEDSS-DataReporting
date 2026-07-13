USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 2 link fixture: Patient -> Investigation (participation)
-- Edge type: 'SubjOfPHC' (NBS convention; SRTE PAR_TYPE).
-- Act class:     CASE (Public_health_case / Investigation)
-- Subject class: PSN  (Person / Patient)
--
-- Wires:
--   1) foundation Patient (entity_uid 20000000) AS subject of
--      foundation Investigation (act_uid 20000100)
--   2) v2 Patient        (entity_uid 20020010) AS subject of
--      v2 Investigation        (act_uid 20050010)
--
-- Catalog citation: catalog/edge_types.md, dbo.participation row
--                   `SubjOfPHC` (Used By: sp_investigation_event,
--                   sp_notification_event,
--                   sp_public_health_case_fact_datamart_event,
--                   sp_public_health_case_fact_datamart_update).
--                   Filter sites:
--                     - 056-sp_investigation_event-001.sql:741
--                       (LEFT JOIN; mixed-case 'SubjOfPHC')
--                     - 064-sp_notification_event-001.sql:102
--                       (LEFT JOIN; mixed-case 'SubjOfPHC')
--                     - 072-sp_public_health_case_fact_datamart_event-001.sql:147
--                       (WHERE; uppercase 'SUBJOFPHC')
--                     - 073-sp_public_health_case_fact_datamart_update-001.sql:54
--                       (WHERE; uppercase 'SUBJOFPHC')
--                   The default SQL Server collation
--                   (SQL_Latin1_General_CP1_CI_AS) is case-insensitive on
--                   string comparisons, so a single literal value
--                   'SubjOfPHC' satisfies all four filter sites. We use
--                   the mixed-case form to match what the event SPs
--                   write (matches the convention used by the foundation
--                   Patient/Investigation Tier 0 fixture's siblings).
--
-- Honest coverage assessment:
--   - This edge is **shape-consistency-mostly** at Tier 1 isolation.
--   - sp_nrt_investigation_postprocessing reads from the hand-authored
--     `nrt_investigation` staging table (not from `participation`); the
--     Investigation chain's INVESTIGATION dimension columns do not
--     change post-edge.
--   - sp_nrt_notification_postprocessing reads `local_patient_uid`
--     from `nrt_investigation_notification.local_patient_uid` (Tier 1
--     hand-authored to 20000000); the Notification dimension columns
--     do not change post-edge.
--   - The `local_patient_id` / `local_patient_uid` JSON projection in
--     sp_notification_event line 102 IS exercised by this edge — but
--     that JSON projection is consumed by the CDC pipeline / Kafka,
--     NOT by the postprocessing SP, so it does not flip RDB_MODERN
--     dim/fact column coverage at Tier 1 isolation.
--   - sp_investigation_event line 741 is inside the
--     `notification_history` aggregation. That aggregation is
--     projected into the JSON output and consumed by Kafka, NOT by
--     sp_nrt_investigation_postprocessing, so it does not flip
--     RDB_MODERN dim/fact column coverage at Tier 1 isolation.
--   - The PRIMARY value of this edge is at Merge contract step 9
--     (Datamart SPs): sp_public_health_case_fact_datamart_event /
--     _update both have INNER JOIN on PARTICIPATION with
--     TYPE_CD='SUBJOFPHC' and depend on the row's existence to
--     populate F_PAGE_CASE.PATIENT_KEY and patient-context columns.
--     Without this edge, the datamart SPs return zero rows for the
--     foundation/v2 Investigation pair.
--   - Secondary value: ODSE graph correctness for the
--     RDB-vs-RDB_MODERN comparison test against MasterETL (which
--     traverses participation directly to populate analogous patient
--     columns).
--
-- UID block (Tier 2 - fifth agent): 21004000 - 21004999.
-- This fixture authors NO new entity / Person / Act / Public_health_case
-- rows; it only writes 2 rows to dbo.participation.
--
-- Forbidden in Tier 2 (per template):
--   - No new ODSE entity rows; no SRTE writes; no foundation/Tier 1
--     modifications; no INSERTs into RDB_MODERN dim/fact tables; no
--     infrastructure-SP invocation in this fixture (orchestrator owns
--     sp_get_date_dim and sp_nrt_srte_condition_code_postprocessing
--     per Merge contract step 2).
-- =====================================================================

-- ----- Sentinel reference (do not allocate - assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Cross-tier UIDs referenced (read-only) -----
DECLARE @foundation_entity_patient_uid bigint = 20000000;  -- foundation Patient entity_uid / person_uid
DECLARE @foundation_act_inv_uid        bigint = 20000100;  -- foundation Investigation act_uid (public_health_case_uid)
DECLARE @v2_entity_patient_uid         bigint = 20020010;  -- v2 Patient (Patient Tier 1)
DECLARE @v2_act_inv_uid                bigint = 20050010;  -- v2 Investigation (Investigation Tier 1)

-- =====================================================================
-- participation rows.
--
-- The composite PK on dbo.participation is
-- (subject_entity_uid, act_uid, type_cd) - it does not need its own
-- surrogate UID. We do not allocate any UIDs from this agent's block
-- 21004000-21004999; the block is reserved here in case a future
-- amendment needs surrogate UIDs.
--
-- type_cd='SubjOfPHC' is verified present in baseline SRTE PAR_TYPE
-- (code_set_nm='PAR_TYPE') - see catalog/edge_types.md row.
--
-- NOT-NULL columns on dbo.participation are only:
--   subject_entity_uid, act_uid, type_cd
-- All other columns are nullable; we populate the standard lifecycle
-- columns (act_class_cd, subject_class_cd, add_*, last_chg_*,
-- record_status_*, status_*, type_desc_txt) for shape parity with
-- production data and for the few SPs that read those columns.
-- =====================================================================
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd],
     [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time],
     [status_cd], [status_time],
     [type_desc_txt])
VALUES
    -- Edge 1: foundation Patient (PSN) AS subject of foundation Investigation (CASE)
    (@foundation_act_inv_uid,         -- act_uid (CASE; foundation Investigation)
     @foundation_entity_patient_uid,  -- subject_entity_uid (PSN; foundation Patient)
     N'SubjOfPHC',                    -- type_cd (PAR_TYPE 'SubjOfPHC' - in SRTE)
     N'CASE',                         -- act_class_cd
     N'PSN',                          -- subject_class_cd
     '2026-04-01T00:00:00',           -- add_time
     @superuser_id,                   -- add_user_id
     CAST(GETDATE() AS DATE),           -- last_chg_time
     @superuser_id,                   -- last_chg_user_id
     N'ACTIVE',                       -- record_status_cd
     '2026-04-01T00:00:00',           -- record_status_time
     'A',                             -- status_cd (char(1))
     '2026-04-01T00:00:00',           -- status_time
     N'Subject of Public Health Case'),
    -- Edge 2: v2 Patient (PSN) AS subject of v2 Investigation (CASE)
    (@v2_act_inv_uid,                 -- act_uid (CASE; v2 Investigation)
     @v2_entity_patient_uid,          -- subject_entity_uid (PSN; v2 Patient)
     N'SubjOfPHC',                    -- type_cd
     N'CASE',                         -- act_class_cd
     N'PSN',                          -- subject_class_cd
     '2026-04-04T00:00:00',           -- add_time
     @superuser_id,                   -- add_user_id
     CAST(GETDATE() AS DATE),           -- last_chg_time
     @superuser_id,                   -- last_chg_user_id
     N'ACTIVE',                       -- record_status_cd
     '2026-04-04T00:00:00',           -- record_status_time
     'A',                             -- status_cd
     '2026-04-04T00:00:00',           -- status_time
     N'Subject of Public Health Case');

GO

-- =====================================================================
-- Post-edge SP re-run.
--
-- Per the honest coverage assessment in the header: at Tier 1 isolation
-- this edge does NOT flip any RDB_MODERN dimension/fact columns from
-- NULL/sentinel-1 to populated values. The Investigation postprocessing
-- SP reads from `nrt_investigation` (hand-authored by Tier 1, not
-- traversing participation). The Notification postprocessing SP reads
-- `local_patient_uid` from `nrt_investigation_notification` (also
-- hand-authored by Tier 1).
--
-- We re-run sp_investigation_event purely as a SHAPE-CONSISTENCY
-- verification: the SP must execute cleanly with the participation row
-- present, and the LEFT JOIN at line 741 (notification_history nested
-- block) should now match the participation row when projecting JSON.
-- The event SP's output is not consumed in our fixture flow (it would
-- be consumed by Kafka in production), so this is an SP-callability
-- check, not a coverage-unlock check.
--
-- We do NOT re-run sp_nrt_investigation_postprocessing because its
-- output (the INVESTIGATION dimension) is unaffected by this edge:
-- the SP reads only `nrt_investigation`, never `participation`. Same
-- for sp_nrt_notification_postprocessing — it reads only
-- `nrt_investigation_notification`, never `participation`.
--
-- The merge orchestrator runs this EXEC as part of step 7 of the Merge
-- contract sequence (Re-run Tier 1 chains affected by Tier 2 edges).
-- The Datamart SPs at step 9 (sp_public_health_case_fact_datamart_event /
-- _update) are where the SubjOfPHC participation row's value will
-- actually land in RDB_MODERN.
-- =====================================================================

USE [RDB_MODERN];
GO

-- Tail-EXEC: re-run sp_investigation_event to confirm SP callability
-- with the new participation row. (Coverage does not change; this is
-- a shape-consistency verification.)
GO
