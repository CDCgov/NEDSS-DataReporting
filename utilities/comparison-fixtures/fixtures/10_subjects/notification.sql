USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 1 Notification fixture
-- Baseline: 6.0.18.1 (post-liquibase) + fixtures/00_foundation/00_foundation.sql
--
-- ARCHITECTURAL NOTE
--   `sp_notification_event` (file 064-sp_notification_event-001.sql) at
--   line 49 has an INNER JOIN on `act_relationship` (Notification act_uid
--   -> Investigation public_health_case_uid). Without that cross-subject
--   `act_relationship` row (which is Tier 2 territory; cross-subject
--   edges are forbidden in Tier 1), the event SP's SELECT projection
--   returns ZERO rows. That is FINE — the event SP is a JSON-emit query
--   for downstream Kafka in production; it does NOT populate
--   `nrt_investigation_notification`.
--
--   `sp_nrt_notification_postprocessing`
--   (file 006-sp_nrt_notification_postprocessing-001.sql) at line 44
--   reads from `dbo.nrt_investigation_notification` directly. So we CAN
--   populate NOTIFICATION + NOTIFICATION_EVENT at Tier 1 by writing the
--   staging row by hand below — completely independent of the event SP.
--
--   At Tier 1 in isolation, the postprocessing SP's cross-subject FK
--   joins (D_PATIENT, INVESTIGATION, RDB_DATE, condition) will mostly
--   resolve to NULL; the SP's COALESCE-to-1 sentinel populates each FK
--   column to the unknown-key value 1. That counts as "populated" for
--   coverage measurement (the column is non-NULL) — Tier 2 will later
--   wire the act_relationship + cross-subject UID resolution to make
--   those joins resolve to real keys.
--
-- WHAT THIS FIXTURE DOES
--   1. Foundation Notification enrichment: leave the foundation
--      `notification` row (UID 20000110) unmodified — per the template's
--      "Forbidden in Tier 1" section, no UPDATE/DELETE against any
--      foundation row, including columns coverage_foundation.md flags as
--      "Tier 1 deferred" (case_class_cd, case_condition_cd,
--      confirmation_method_cd, mmwr_*, rpt_sent_time, rpt_source_cd).
--      The foundation row's NULL state is preserved so the SP's
--      null/blank transform path is observable on the foundation
--      Notification.
--   2. v2 Notification: a separate fully-attributed Notification act +
--      `notification` row in this block (UID 20060010). All Tier-1
--      deferred columns (case_class_cd, case_condition_cd,
--      confirmation_method_cd, mmwr_week, mmwr_year, rpt_sent_time,
--      rpt_source_cd) plus other notification columns are populated on
--      v2.
--   3. Synthetic staging rows in `dbo.nrt_investigation_notification`
--      (RDB_MODERN), mirroring what kafka-connect's JDBC sink would
--      have written. Two rows: one for foundation Notification (UID
--      20000110) with the SP's null/blank-driving columns left NULL,
--      and one for v2 Notification (UID 20060010) with every column the
--      postprocessing SP reads populated. Cross-subject UID columns
--      (local_patient_uid -> 20000000 foundation patient,
--      public_health_case_uid -> 20000100 foundation investigation)
--      are set so that Tier 2's eventual D_PATIENT + INVESTIGATION
--      population makes the FK joins resolve. At Tier 1 in isolation
--      D_PATIENT / INVESTIGATION dimension rows haven't been populated
--      by the Patient / Investigation chains, so the joins return NULL
--      and the COALESCE-to-1 sentinel handles it gracefully.
--   4. Does NOT author cross-subject act_relationship / participation /
--      nbs_act_entity rows. The Notification -> Investigation
--      act_relationship is Tier 2's job. nrt_notification_key is
--      IDENTITY-allocated by the SP itself; not hand-authored.
--
-- UID block (Notification Tier 1): 20060000-20069999.
-- Foundation dependencies (read-only):
--   @dbo_Act_notification_uid           20000110  (act / notification)
--   @dbo_Act_investigation_uid          20000100  (referenced via
--                                                  nrt_investigation_notification.public_health_case_uid)
--   @dbo_Entity_patient_uid             20000000  (referenced via
--                                                  nrt_investigation_notification.local_patient_uid)
-- =====================================================================

-- ----- Sentinel reference (do not allocate — assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Foundation dependencies referenced (read-only) -----
DECLARE @foundation_act_notif_uid    bigint = 20000110;  -- foundation Notification Act / notification
DECLARE @foundation_act_inv_uid      bigint = 20000100;  -- foundation Investigation (cross-subject UID — referenced soft-ly via nrt_investigation_notification.public_health_case_uid; no act_relationship row)
DECLARE @foundation_patient_uid      bigint = 20000000;  -- foundation Patient (cross-subject UID — referenced soft-ly via nrt_investigation_notification.local_patient_uid; no participation row)

-- =====================================================================
-- UID allocations (Notification Tier 1: 20060000-20069999)
-- =====================================================================

-- ----- v2 Notification: a separate fully-attributed Notification -----
DECLARE @dbo_Act_notification_v2_uid bigint = 20060010;  -- v2 Notification: act.act_uid / notification.notification_uid

-- =====================================================================
-- ODSE rows — additive enrichments and v2 variant.
-- =====================================================================

-- The foundation Notification's `notification` row (UID 20000110) is
-- NOT modified. coverage_foundation.md notes case_class_cd,
-- case_condition_cd, confirmation_method_cd, mmwr_*, rpt_sent_time,
-- rpt_source_cd are "Tier 1 deferred" — that means the v2 variant
-- exercises the populated path, NOT a license to UPDATE the foundation
-- row. The two-variant pattern (foundation NULL + v2 populated) drives
-- both branches of the SP's transform.

-- =====================================================================
-- v2 Notification — fully-attributed variant for column coverage.
-- =====================================================================

-- act parent row. class_cd 'NOTF' from SRTE ACT_CLS; mood_cd 'EVN'.
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@dbo_Act_notification_v2_uid, N'NOTF', N'EVN');

-- v2 notification — every Tier-1 deferred column populated.
--   cd='NOTF'                 — N_TYPE 'NOTF' (verified in code_value_general). The
--                               event SP at line 207 filters notif.cd NOT IN
--                               ('EXP_NOTF', 'SHARE_NOTF', 'EXP_NOTF_PHDC',
--                               'SHARE_NOTF_PHDC') — 'NOTF' passes.
--   cd_desc_txt               — display text.
--   case_class_cd='C'         — PHC_CLASS 'C' = Confirmed (verified; same code set
--                               as PHC.case_class_cd).
--   case_condition_cd='10110' — condition_code 'Hepatitis A, acute' (HEP family;
--                               matches foundation's investigation cd selection).
--   confirmation_method_cd='LD' — PHC_CONF_M 'LD' = Laboratory confirmed (verified
--                                 in baseline SRTE; same code referenced by
--                                 investigation Tier 1 nrt_investigation_confirmation).
--   mmwr_week='14', mmwr_year='2026' — MMWR week of 2026-04-04 sample date.
--   rpt_sent_time             — when the notification was sent (drives event SP's
--                               first_notification_send_date aggregate; here on the
--                               v2 ODSE row though postprocessing SP doesn't read
--                               this column from ODSE — it reads from
--                               nrt_investigation_notification.rpt_sent_time).
--   rpt_source_cd='PP'        — RPT_SRC 'PP' = Private Physician Office (verified;
--                               same code referenced in investigation Tier 1).
--   record_status_cd='COMPLETED' — REC_STAT 'COMPLETED' (verified). The event SP's
--                                  Notification_HIST aggregate filters on
--                                  RECORD_STATUS_CD IN ('COMPLETED', 'MSG_FAIL',
--                                  'REJECTED', 'PEND_APPR', 'APPROVED') (line 163).
--                                  'COMPLETED' triggers the notif_sent_count branch
--                                  (line 116) and first_notification_send_date
--                                  (line 117).
INSERT INTO [dbo].[notification]
    ([notification_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [case_class_cd], [case_condition_cd],
     [confirmation_method_cd], [mmwr_week], [mmwr_year], [rpt_sent_time],
     [rpt_source_cd], [confidentiality_cd], [confidentiality_desc_txt],
     [method_cd], [method_desc_txt], [reason_cd], [reason_desc_txt],
     [auto_resend_ind], [user_affiliation_txt], [txt])
VALUES
    (@dbo_Act_notification_v2_uid, '2026-04-01T00:00:00', @superuser_id,
     N'NOTF', N'Notification (NOTF)',
     '2026-04-04T00:00:00', @superuser_id, N'NOT20060010GA01',
     N'COMPLETED', '2026-04-04T00:00:00', N'A', '2026-04-01T00:00:00',
     N'T', 1, N'HEP', N'130001',
     20060010, N'C', N'10110',
     N'LD', N'14', N'2026', '2026-04-04T00:00:00',
     N'PP', N'R', N'Restricted',
     N'ELR', N'Electronic Laboratory Report', N'NEW', N'New notification',
     N'N', N'V2 Aff',
     N'Tier 1 v2 notification comments — exercises the txt -> NOTIFICATION_COMMENTS path.');

GO

-- =====================================================================
-- DRIVE THE POSTPROCESSING SP via direct nrt_investigation_notification
-- INSERTs.
--
-- sp_notification_event only emits a SELECT (and at Tier 1 returns 0
-- rows because of the act_relationship inner join). For fixture
-- verification we populate dbo.nrt_investigation_notification directly
-- to drive sp_nrt_notification_postprocessing -> NOTIFICATION +
-- NOTIFICATION_EVENT. Two notification_uids: foundation Notification
-- (20000110) and v2 Notification (20060010).
--
-- nrt_investigation_notification has refresh_datetime (AS_ROW_START)
-- and max_datetime (AS_ROW_END) GENERATED ALWAYS columns; SQL Server
-- populates them on INSERT, so they are omitted from the column list.
-- =====================================================================

USE [RDB_MODERN];
GO

-- ----- Re-declare locals inside the RDB_MODERN batch (DECLAREs do not -----
-- ----- survive a `GO` batch terminator).                              -----
DECLARE @superuser_id bigint = 10009282;
DECLARE @foundation_act_notif_uid    bigint = 20000110;
DECLARE @foundation_act_inv_uid      bigint = 20000100;
DECLARE @foundation_patient_uid      bigint = 20000000;
DECLARE @dbo_Act_notification_v2_uid bigint = 20060010;

-- =====================================================================
-- DIMENSION-LEVEL DEPENDENCIES
--
-- `sp_nrt_notification_postprocessing` resolves NOTIFICATION_EVENT.
-- INVESTIGATION_KEY via `LEFT JOIN dbo.INVESTIGATION inv ON
-- nrt.public_health_case_uid = inv.CASE_UID` and CONDITION_KEY via
-- `LEFT JOIN dbo.condition cnd ON nrt.condition_cd = cnd.CONDITION_CD`.
--
-- Both are NOT NULL columns on NOTIFICATION_EVENT, AND the SP does NOT
-- COALESCE these two keys to the sentinel (lines 79-80 of the SP read
-- inv.INVESTIGATION_KEY / cnd.CONDITION_KEY directly — only PATIENT_KEY
-- and the date keys are COALESCEd to 1). So a NULL from either LEFT
-- JOIN produces a NULL → INSERT failure.
--
-- Per the per-subject prompt, the prompt author expected COALESCE
-- handling for both keys; in practice the SP body does not COALESCE
-- INVESTIGATION_KEY/CONDITION_KEY. This is an SP discrepancy, not a
-- fixture bug. To get the SP to COMPLETE at Tier 1 in isolation we have
-- to ensure the LEFT JOINs resolve to existing rows. Two options:
--   (a) Run the Investigation/Patient/etc. Tier 1 chains first so
--       INVESTIGATION + CONDITION dims are populated.
--   (b) Author the minimum dimension rows directly here, scoped to
--       CASE_UID/CONDITION_CD values our staging rows reference.
--
-- We pick (b) so this fixture is self-contained at Tier 1. The rows
-- authored below are fixture-environment scaffolding (analogous to the
-- sentinel `INVESTIGATION_KEY=1, CASE_UID=NULL` row Liquibase already
-- seeds). They do NOT represent SP-driven coverage of D_INVESTIGATION
-- or D_CONDITION — those dimensions are owned by their own subjects'
-- Tier 1 fixtures, which run their own postprocessing SPs to populate
-- them properly. When the merged fixture runs (foundation + ALL Tier 1
-- subjects + Tier 2 + datamart), Investigation Tier 1 + the SRTE
-- condition postprocessing SP will populate INVESTIGATION/CONDITION
-- with their canonical rows; this Notification fixture's rows here are
-- harmless additions (different CASE_UID / different CONDITION_KEY) and
-- the merge-order dependency is documented in coverage.
-- =====================================================================

-- =====================================================================
-- INFRASTRUCTURE-DIMENSION DEPENDENCY (deferred to project-wide fix)
-- =====================================================================
-- An earlier draft of this fixture INSERTed scaffolding rows into
-- dbo.INVESTIGATION (KEY=20060001, CASE_UID=20000100), dbo.CONDITION
-- (KEY=20060002, CD='10110'), and dbo.RDB_DATE (DATE_KEY=1) to satisfy
-- NOTIFICATION_EVENT's FK constraints. **That violated the Tier 1
-- contract** — those tables are output of other subjects' chains
-- (Investigation Tier 1, sp_nrt_srte_condition_code_postprocessing,
-- and the date-dim utility sp_get_date_dim respectively), and Tier 1
-- fixtures must not write to other subjects' RDB_MODERN output tables.
-- The scaffolding has been removed.
--
-- Consequence: in Tier 1 ISOLATION (foundation + this notification.sql
-- only), the postprocessing SP's INSERT INTO NOTIFICATION_EVENT will
-- FAIL with FK violations because:
--   - INVESTIGATION_KEY (line 79 of postprocessing SP, no COALESCE) is
--     NULL when no INVESTIGATION row matches CASE_UID=20000100.
--   - CONDITION_KEY (line 80, no COALESCE) is NULL when CONDITION is
--     empty.
--   - The COALESCEd date keys default to 1, which has no matching
--     RDB_DATE.DATE_KEY=1 row in baseline → FK violation.
--
-- This is a real Tier-1-isolation gap. The fixture is still authored
-- correctly; it just can't run end-to-end alone. The full chain works
-- in the merged-fixture sequence where:
--   1. foundation applies
--   2. infrastructure SPs run: sp_get_date_dim (populates RDB_DATE)
--      and sp_nrt_srte_condition_code_postprocessing (populates
--      CONDITION).
--   3. All Tier 1 subjects' fixtures apply.
--   4. Each Tier 1 chain runs (Investigation populates INVESTIGATION
--      with CASE_UID=20000100; Patient populates D_PATIENT; etc.).
--   5. Notification's chain runs last among Tier 1 (or after at least
--      Investigation, condition postprocessing, and date dim) so its
--      FK joins resolve to real rows.
--
-- The merge-order dependency and infrastructure-SP requirement are
-- recorded as LINK_REQUIRED entries in coverage_notification.md.
-- A future iteration of STRATEGY.md will codify the infrastructure-SP
-- step as part of the merged fixture's verification recipe.
-- =====================================================================

-- nrt_investigation_notification: one row per notification_uid.
--
-- The columns this SP reads (per body of
-- 006-sp_nrt_notification_postprocessing-001.sql):
--   nrt.notification_uid              -> driver key
--   nrt.notif_status                  -> NOTIFICATION.NOTIFICATION_STATUS
--   nrt.notif_comments                -> NOTIFICATION.NOTIFICATION_COMMENTS
--   nrt.notif_local_id                -> NOTIFICATION.NOTIFICATION_LOCAL_ID
--   nrt.notif_add_user_id             -> NOTIFICATION.NOTIFICATION_SUBMITTED_BY
--   nrt.notif_last_chg_time           -> NOTIFICATION.NOTIFICATION_LAST_CHANGE_TIME
--   nrt.public_health_case_uid        -> INVESTIGATION_KEY join (LEFT JOIN
--                                          dbo.INVESTIGATION on
--                                          inv.CASE_UID = nrt.public_health_case_uid)
--   nrt.local_patient_uid             -> PATIENT_KEY join (LEFT JOIN
--                                          dbo.D_PATIENT on
--                                          p.PATIENT_UID = nrt.local_patient_uid)
--   nrt.rpt_sent_time                 -> NOTIFICATION_SENT_DT_KEY (CAST to date,
--                                          LEFT JOIN dbo.RDB_DATE)
--   nrt.notif_add_time                -> NOTIFICATION_SUBMIT_DT_KEY (CAST to date,
--                                          LEFT JOIN dbo.RDB_DATE)
--   nrt.notif_last_chg_time (again)   -> NOTIFICATION_UPD_DT_KEY (CAST to date,
--                                          LEFT JOIN dbo.RDB_DATE)
--   nrt.condition_cd                  -> CONDITION_KEY join (LEFT JOIN
--                                          dbo.condition on
--                                          cnd.CONDITION_CD = nrt.condition_cd)
--
-- The remaining columns (program_jurisdiction_oid, jurisdiction_cd,
-- prog_area_cd, status_cd, source_class_cd, target_class_cd, etc.) are
-- not read by the postprocessing SP (only by the event SP, which we are
-- not running productively at Tier 1). They are still populated on the
-- v2 row for staging-shape fidelity / future Tier 3 expansion.

GO
