USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 2 link fixture: Interview -> Investigation (act_relationship)
-- Edge type: 'IXS' (NBS convention; MISSING from SRTE AR_TYPE).
-- Source class:  ENC  (Interview's act.class_cd is 'ENC' per
--                      foundation 00_foundation.sql:316 + Interview Tier
--                      1 v2 act_uid 20090010)
-- Target class:  CASE (Investigation's act.class_cd is 'CASE')
--
-- Wires:
--   1) foundation Interview (20000140) -> foundation Investigation (20000100)
--   2) v2 Interview         (20090010) -> v2 Investigation         (20050010)
--
-- Catalog citation: catalog/edge_types.md row 338 -- 'IXS' is found in
-- the BUS_OBJ_TYPE and INFO_SOURCE_COVID code sets but **NOT** in
-- AR_TYPE per Phase B's catalog. RTR's sp_interview_event nonetheless
-- filters on the literal 'IXS' value at line 86 of
-- 065-sp_interview_event-001.sql:
--
--     LEFT JOIN NBS_ODSE.dbo.Act_relationship ar1 WITH (NOLOCK)
--         ON ar1.source_act_uid = ix.interview_uid AND ar1.type_cd = 'IXS'
--
-- and projects ar1.target_act_uid as INVESTIGATION_UID at line 70 of
-- the same SP. This is consistent with the documented "MISSING_FROM_SRTE"
-- Phase B policy: author with the literal type_cd value.
--
-- COVERAGE SHAPE -- IMPORTANT:
--   The join at line 85-86 is a LEFT JOIN. The Interview event SP
--   already returns 2 rows at Tier 1 isolation (#INTERVIEW_INIT for
--   foundation + v2 Interview), regardless of this edge. Pre-edge,
--   the JSON projection's INVESTIGATION_UID column projects as NULL
--   on every #INTERVIEW_INIT row (the LEFT JOIN finds no matching
--   act_relationship). Post-edge, INVESTIGATION_UID surfaces the
--   wired Investigation act_uids:
--     * foundation Interview row -> INVESTIGATION_UID = 20000100
--     * v2 Interview row         -> INVESTIGATION_UID = 20050010
--
--   This edge is therefore SHAPE-CONSISTENCY, NOT a Tier 1-isolation
--   coverage unlock. RDB_MODERN dim/fact column populations on
--   D_INTERVIEW (2 rows, 18/24 + 6 LDF OUT_OF_SCOPE), D_INTERVIEW_NOTE
--   (2 rows, 7/7), and F_INTERVIEW_CASE (2 rows, 8/10) are
--   byte-identical pre/post-edge -- the postprocessing SPs
--   (sp_d_interview_postprocessing, sp_f_interview_case_postprocessing)
--   read from nrt_interview / nrt_interview_note / nrt_interview_answer
--   directly and do NOT traverse act_relationship.
--
--   The PRIMARY value of this edge:
--     1. Unblocking the Interview event SP's JSON projection
--        (INVESTIGATION_UID populates post-edge). Kafka consumers in
--        production read this projection.
--     2. ODSE graph correctness for the RDB-vs-RDB_MODERN comparison
--        test against MasterETL (which traverses act_relationship to
--        derive Interview->Investigation linkages on the RDB side).
--
-- UID block (Tier 2 - twelfth agent): 21011000 - 21011999.
-- act_relationship has a composite PK (source_act_uid, target_act_uid,
-- type_cd) so no surrogate UID is needed; the block is reserved for
-- future amendments only. Pattern matches inv_notification.sql (sibling
-- act_relationship Tier 2 fixture).
--
-- This fixture authors NO new entity / Person / Act / Public_health_case
-- / Interview rows; it only writes 2 rows to dbo.act_relationship.
--
-- Forbidden in Tier 2 (per template):
--   - No new ODSE entity rows; no SRTE writes; no foundation/Tier 1
--     modifications; no INSERTs into RDB_MODERN dim/fact tables; no
--     infrastructure-SP invocation in this fixture (orchestrator owns
--     sp_get_date_dim and sp_nrt_srte_condition_code_postprocessing
--     per Merge contract step 2).
-- =====================================================================

-- ----- Sentinel reference (do not allocate -- assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;          -- conventional NBS superuser id

-- ----- Cross-tier UIDs referenced (read-only) -----
DECLARE @foundation_act_interview_uid bigint = 20000140;  -- foundation Interview act_uid
DECLARE @foundation_act_inv_uid       bigint = 20000100;  -- foundation Investigation act_uid (public_health_case_uid)
DECLARE @v2_act_interview_uid         bigint = 20090010;  -- v2 Interview (Interview Tier 1)
DECLARE @v2_act_inv_uid               bigint = 20050010;  -- v2 Investigation (Investigation Tier 1)

-- =====================================================================
-- act_relationship rows.
--
-- The composite PK on dbo.act_relationship is (source_act_uid,
-- target_act_uid, type_cd) -- it does not need its own surrogate UID.
-- We do not allocate any UIDs from this agent's block 21011000-21011999;
-- the block is reserved here in case a future amendment needs surrogate
-- UIDs.
--
-- type_cd='IXS' is MISSING from baseline SRTE AR_TYPE per Phase B
-- (catalog/edge_types.md row 338) -- found in BUS_OBJ_TYPE and
-- INFO_SOURCE_COVID code sets but not in AR_TYPE. RTR's
-- sp_interview_event filters on the literal 'IXS' regardless. Same
-- shape as 'Notification' edge in inv_notification.sql (sibling
-- act_relationship fixture).
-- =====================================================================
INSERT INTO [dbo].[act_relationship]
    ([target_act_uid], [source_act_uid], [type_cd], [source_class_cd],
     [target_class_cd], [add_time], [add_user_id], [from_time],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [sequence_nbr], [status_cd], [status_time])
VALUES
    -- Edge 1: foundation Interview -> foundation Investigation
    -- Drives sp_interview_event #INTERVIEW_INIT.INVESTIGATION_UID
    -- projection via the LEFT JOIN ar1 at lines 85-86 of
    -- 065-sp_interview_event-001.sql for the foundation Interview row.
    (@foundation_act_inv_uid,        -- target_act_uid (CASE; foundation Investigation)
     @foundation_act_interview_uid,  -- source_act_uid (ENC; foundation Interview)
     N'IXS',                         -- type_cd (MISSING_FROM_SRTE AR_TYPE; SP filters on literal)
     N'ENC',                         -- source_class_cd (Interview act.class_cd)
     N'CASE',                        -- target_class_cd (Investigation act.class_cd)
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
    -- Edge 2: v2 Interview -> v2 Investigation
    -- Drives INVESTIGATION_UID projection for v2 Interview row.
    (@v2_act_inv_uid,                -- target_act_uid (CASE; v2 Investigation)
     @v2_act_interview_uid,          -- source_act_uid (ENC; v2 Interview)
     N'IXS',                         -- type_cd
     N'ENC',                         -- source_class_cd
     N'CASE',                        -- target_class_cd
     '2026-04-15T10:00:00',          -- add_time
     @superuser_id,                  -- add_user_id
     '2026-04-15T10:00:00',          -- from_time
     CAST(GETDATE() AS DATE),          -- last_chg_time
     @superuser_id,                  -- last_chg_user_id
     N'ACTIVE',                      -- record_status_cd
     '2026-04-15T10:00:00',          -- record_status_time
     1,                              -- sequence_nbr
     N'A',                           -- status_cd
     '2026-04-15T10:00:00');         -- status_time

GO

-- =====================================================================
-- Post-edge SP re-run.
--
-- Tail-EXEC: re-run sp_interview_event so the JSON projection now
-- includes the wired INVESTIGATION_UID for both Interview rows.
-- Pre-edge those columns were NULL on every #INTERVIEW_INIT row (the
-- LEFT JOIN ar1 at lines 85-86 returned no matching act_relationship
-- row); post-edge they should resolve to the wired Investigation
-- act_uids:
--   * foundation Interview (20000140) -> INVESTIGATION_UID = 20000100
--   * v2 Interview         (20090010) -> INVESTIGATION_UID = 20050010
--
-- We do NOT re-run sp_d_interview_postprocessing or
-- sp_f_interview_case_postprocessing because their input
-- (nrt_interview / nrt_interview_note / nrt_interview_answer) is
-- hand-authored by Tier 1 and they do NOT traverse act_relationship.
-- D_INTERVIEW (2 rows, 18/24 + 6 LDF OUT_OF_SCOPE), D_INTERVIEW_NOTE
-- (2 rows, 7/7), and F_INTERVIEW_CASE (2 rows, 8/10) column populations
-- are unchanged at Tier 1 isolation by this edge -- the postprocessing
-- SPs are insensitive to act_relationship row presence.
--
-- The merge orchestrator runs this EXEC as part of step 7 of the
-- Merge contract sequence (Re-run Tier 1 chains affected by Tier 2
-- edges).
-- =====================================================================

USE [RDB_MODERN];
GO

-- Tail-EXEC: re-run sp_interview_event to confirm the IXS
-- act_relationship rows project into the JSON payload's
-- INVESTIGATION_UID field. Expected: 2 rows in #INTERVIEW_INIT (one per
-- Interview UID), each with non-NULL INVESTIGATION_UID matching the
-- wired target_act_uid.
GO
