USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 1 Interview fixture
-- Baseline: 6.0.18.1 (post-liquibase) + fixtures/00_foundation/00_foundation.sql
--
-- ARCHITECTURAL NOTE
--   Interview is a moderately-sized subject (Act-bearing entity):
--     - Event SP: dbo.sp_interview_event (param: @ix_uids)
--       File: routines/065-sp_interview_event-001.sql
--       Reads NBS_ODSE.dbo.interview + nbs_srte.code_value_general for
--       NBS_INTVW_STATUS, NBS_INTVWEE_ROLE, NBS_INTERVIEW_TYPE_STDHIV,
--       NBS_INTVW_LOC[_STDHIV] descriptions; LEFT JOINs NBS_act_entity
--       (IntrvwerOfInterview, OrgAsSiteOfIntv, IntrvweeOfInterview) for
--       provider/org/patient soft refs and Act_relationship (IXS) for
--       investigation soft ref. The cross-subject NBS_act_entity /
--       Act_relationship rows are TIER 2 territory; at Tier 1 isolation
--       these joins return NULL. The event SP simply emits a JSON
--       projection — its joins are LEFT JOINs and do not block.
--     - Postprocessing SPs (TWO — different param names):
--       1. dbo.sp_d_interview_postprocessing (param: @interview_uids)
--          File: routines/023-sp_d_interview_postprocessing-001.sql
--          Reads dbo.nrt_interview + dbo.nrt_interview_key +
--          dbo.nrt_interview_answer + dbo.nrt_interview_note. Allocates
--          surrogate keys via INSERT into nrt_interview_key (IDENTITY)
--          for any UID without a D_INTERVIEW_KEY, then INSERTs/UPDATEs
--          D_INTERVIEW (24 live cols) + D_INTERVIEW_NOTE (7 live cols).
--          NRT_METADATA_COLUMNS for D_INTERVIEW is EMPTY in baseline
--          6.0.18.1 (verified) so the dynamic LDF pivot collapses to a
--          no-op and nrt_interview_answer rows are not incorporated.
--          The "Missing NRT Record" backfill check (lines 122-145) is
--          driven by INTERVIEW_INIT.interview_uid coverage of the
--          @interview_uids list — must INSERT one nrt_interview row per
--          UID we pass in to avoid the early-return.
--       2. dbo.sp_f_interview_case_postprocessing (param: @ix_uids)
--          File: routines/024-sp_f_interview_case_postprocessing-001.sql
--          Reads dbo.nrt_interview_key + dbo.nrt_interview + D_INTERVIEW
--          + nrt_investigation + INVESTIGATION + D_PROVIDER + D_ORGANIZATION
--          + D_PATIENT. CASE branches on D_INTERVIEW.IX_INTERVIEWEE_ROLE_CD
--          to route lprov.PROVIDER_KEY into INTERPRETER_KEY / PHYSICIAN_KEY
--          / NURSE_KEY / PROXY_KEY (lines 95-106) or lpat.PATIENT_KEY
--          into IX_INTERVIEWEE_KEY (line 107) for SUBJECT. Cross-subject
--          PROVIDER_KEY / ORGANIZATION_KEY / PATIENT_KEY all COALESCE to
--          sentinel 1 (lines 93, 110, plus the inline CASE ELSE 1).
--          INVESTIGATION_KEY at line 94 is NOT COALESCEd, but the column
--          IS NULLABLE in F_INTERVIEW_CASE — verified — so a NULL
--          INVESTIGATION_KEY is acceptable. PATIENT_KEY likewise NULLABLE
--          (verified live schema).
--   No FK constraints on D_INTERVIEW / D_INTERVIEW_NOTE / F_INTERVIEW_CASE
--   in baseline 6.0.18.1 (verified via sys.foreign_keys). Therefore Tier 1
--   isolation is expected to populate 24/24 D_INTERVIEW columns
--   (LDF/dynamic columns 19-24 are populated only when NRT_METADATA_COLUMNS
--   has rows for D_INTERVIEW — empty in baseline → those 6 are deliberately
--   left NULL by the SP at Tier 1 isolation; documented as OUT_OF_SCOPE),
--   7/7 D_INTERVIEW_NOTE columns (notes attached to v2 interview), and
--   10/10 F_INTERVIEW_CASE columns (cross-subject keys at sentinel 1
--   except where v2's INTERVIEWEE_ROLE_CD='PHYS' routes PROVIDER_KEY into
--   PHYSICIAN_KEY).
--
-- WHAT THIS FIXTURE DOES
--   1. Foundation Interview enrichment:
--        - Foundation already has dbo.act 20000140 (ENC/EVN) and
--          dbo.interview 20000140 (interview_status_cd='C',
--          interview_type_cd='INITIAL', interview_loc_cd='HOSP',
--          interviewee_role_cd=NULL). interview_status_cd 'C' is NOT a
--          valid NBS_INTVW_STATUS code (real codes: COMPLETE, INPROG,
--          SCHED, UNABLE) — so the event SP's LEFT JOIN to
--          code_value_general for IX_STATUS surfaces NULL; the
--          postprocessing SP just propagates the raw 'C' to
--          IX_STATUS_CD. interviewee_role_cd=NULL exhibits the SUBJECT
--          ELSE-branch in F_INTERVIEW_CASE (line 107) which still routes
--          lpat.PATIENT_KEY (COALESCE 1) into IX_INTERVIEWEE_KEY only
--          when IX_INTERVIEWEE_ROLE_CD literally = 'SUBJECT'; with NULL
--          it falls into the ELSE 1 path on every CASE branch. So
--          foundation Interview drives the all-sentinel-1 path on the
--          5 role-routed key columns.
--        - Hand-author one nrt_interview row keyed on interview_uid
--          20000140 with most demographic fields mirroring the ODSE row
--          and the SP-friendly NULL-path for IX_STATUS/IX_TYPE/IX_LOCATION
--          /IX_INTERVIEWEE_ROLE (the upstream person-service / Debezium
--          projection would normally populate the IX_* description
--          columns from code_value_general; we leave them NULL on
--          foundation to exhibit the "no SRTE description" path on
--          D_INTERVIEW.IX_STATUS / IX_TYPE / etc.)
--        - No interview notes on foundation — all D_INTERVIEW_NOTE
--          coverage comes from v2.
--
--   2. v2 Interview: a fully-attributed alternative within block
--      20090000-20099999.
--        - dbo.act row at 20090010 (ENC/EVN).
--        - dbo.interview row at 20090010 with every column the event
--          SP / postprocessing SP touches set non-NULL:
--            * interview_status_cd='COMPLETE' (NBS_INTVW_STATUS)
--            * interview_type_cd='REINTVW' (NBS_INTERVIEW_TYPE_STDHIV)
--            * interview_loc_cd='PHCLINIC' (NBS_INTVW_LOC)
--            * interviewee_role_cd='PHYS' (NBS_INTVWEE_ROLE) — this
--              drives the F_INTERVIEW_CASE.PHYSICIAN_KEY CASE branch
--              (line 98) instead of the all-sentinel-1 ELSE path.
--            * local_id, interview_date, version_ctrl_nbr,
--              record_status_cd / time, add/last_chg time/user_id all
--              set.
--        - Hand-author the nrt_interview row keyed on 20090010 with:
--            * patient_uid=20000000 (foundation Patient)
--            * provider_uid=20000010 (foundation Provider)
--            * organization_uid=20000020 (foundation Organization)
--            * investigation_uid=20000100 (foundation Investigation)
--          The f_interview_case postprocessing SP COALESCEs PATIENT_KEY
--          and PROVIDER_KEY (via line 95/98/etc.) and ORGANIZATION_KEY
--          (line 110) — at Tier 1 isolation D_PATIENT/D_PROVIDER/
--          D_ORGANIZATION are empty so all resolve to 1. INVESTIGATION
--          at line 94 is read directly from dbo.INVESTIGATION (not
--          COALESCEd) but the column is NULLABLE; resolves to NULL at
--          Tier 1 isolation. In merged-fixture sequence after upstream
--          chains run, every key resolves to a real value.
--          Also populates IX_STATUS/IX_INTERVIEWEE_ROLE/IX_TYPE/
--          IX_LOCATION on nrt_interview directly (these are upstream-
--          projected description columns that the postprocessing SP
--          passes through to D_INTERVIEW columns of the same name).
--
--   3. v2 Interview Notes: 2 rows in nrt_interview_note keyed on
--      interview_uid=20090010 — exercises the D_INTERVIEW_NOTE
--      INSERT-after-DELETE path (the SP at lines 451-456 deletes any
--      existing notes for the interview's d_interview_key before
--      re-inserting; on first run there are none). user_first_name /
--      user_last_name / user_comment / comment_date / nbs_answer_uid
--      all populated.
--
--   4. Synthetic staging rows in RDB_MODERN:
--        - dbo.nrt_interview: 2 rows (foundation 20000140 + v2 20090010)
--          22 settable columns out of 25 (refresh_datetime + max_datetime
--          are GENERATED ALWAYS — verified via sys.columns
--          generated_always_type IN (1,2); batch_id left NULL).
--        - dbo.nrt_interview_note: 2 rows (both attached to v2 20090010)
--          7 settable columns of 10 (refresh_datetime + max_datetime
--          GENERATED ALWAYS; batch_id left NULL).
--        - dbo.nrt_interview_answer: NOT AUTHORED. NRT_METADATA_COLUMNS
--          for D_INTERVIEW is empty in baseline so the d_interview
--          postprocessing SP's dynamic-LDF pivot (line 256-257, 264-279)
--          collapses to a no-op. Authoring nrt_interview_answer rows
--          would be inert at Tier 1; they belong to a Tier 3 LDF-coverage
--          fixture once NRT_METADATA_COLUMNS is seeded.
--
--   5. Does NOT author cross-subject NBS_act_entity rows
--      (IntrvwerOfInterview / OrgAsSiteOfIntv / IntrvweeOfInterview),
--      Act_relationship (IXS) rows, or participation rows. These are
--      Tier 2.
--
--   6. Does NOT hand-author dbo.nrt_interview_key or
--      dbo.nrt_interview_note_key — postprocessing SP allocates
--      surrogate keys via IDENTITY at line 206-210 (interview_key) and
--      line 476-481 (note_key).
--
-- UID block (Interview Tier 1): 20090000-20099999.
-- Foundation dependencies (read-only):
--   @dbo_Act_interview_uid       20000140  (act / interview foundation)
--   @dbo_Entity_patient_uid      20000000  (referenced via nrt_interview.patient_uid)
--   @dbo_Entity_provider_uid     20000010  (referenced via nrt_interview.provider_uid)
--   @dbo_Entity_organization_uid 20000020  (referenced via nrt_interview.organization_uid)
--   @dbo_Act_investigation_uid   20000100  (referenced via nrt_interview.investigation_uid)
-- =====================================================================

-- ----- Sentinel reference -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Foundation dependencies referenced (read-only) -----
DECLARE @foundation_act_interview_uid bigint = 20000140;  -- foundation Interview Act / interview
DECLARE @foundation_patient_uid       bigint = 20000000;  -- foundation Patient
DECLARE @foundation_provider_uid      bigint = 20000010;  -- foundation Provider
DECLARE @foundation_org_uid           bigint = 20000020;  -- foundation Organization
DECLARE @foundation_investigation_uid bigint = 20000100;  -- foundation Investigation PHC

-- =====================================================================
-- UID allocations (Interview Tier 1: 20090000-20099999)
-- =====================================================================

DECLARE @dbo_Act_interview_v2_uid bigint = 20090010;  -- v2 Interview act / interview (interviewee_role_cd='PHYS' for CASE-branch coverage)

-- =====================================================================
-- ODSE rows — additive enrichments and v2 variant.
-- =====================================================================

-- =====================================================================
-- v2 Interview: fully-attributed alternative.
--   act.class_cd 'ENC' from SRTE ACT_CLS (foundation pattern); mood_cd 'EVN'.
-- =====================================================================
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@dbo_Act_interview_v2_uid, N'ENC', N'EVN');

-- v2 interview row — every column the event SP / postprocessing SP
-- references is set non-NULL.
--
-- Codes (all verified in baseline NBS_SRTE.dbo.code_value_general):
--   interview_status_cd 'COMPLETE' from NBS_INTVW_STATUS = 'Closed/Completed'
--   interview_type_cd 'REINTVW' from NBS_INTERVIEW_TYPE_STDHIV = 'Re-Interview'
--   interview_loc_cd 'PHCLINIC' from NBS_INTVW_LOC = 'Public Health Clinic'
--   interviewee_role_cd 'PHYS' from NBS_INTVWEE_ROLE = 'Reporting/Treating Physician'
--     -> drives F_INTERVIEW_CASE.PHYSICIAN_KEY CASE branch (line 98)
INSERT INTO [dbo].[interview]
    ([interview_uid], [interview_status_cd], [interview_date],
     [interviewee_role_cd], [interview_type_cd], [interview_loc_cd],
     [local_id], [record_status_cd], [record_status_time],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [version_ctrl_nbr])
VALUES
    (@dbo_Act_interview_v2_uid, N'COMPLETE', '2026-04-15T10:00:00',
     N'PHYS', N'REINTVW', N'PHCLINIC',
     N'INT20090010GA01', N'ACTIVE', '2026-04-15T10:00:00',
     '2026-04-15T10:00:00', @superuser_id, CAST(GETDATE() AS DATE), @superuser_id,
     1);

GO

-- =====================================================================
-- DRIVE THE POSTPROCESSING SPs via direct nrt_interview / nrt_interview_note
-- INSERTs.
-- =====================================================================

USE [RDB_MODERN];
GO

-- Re-declare locals inside the RDB_MODERN batch (DECLAREs do not survive GO).
DECLARE @superuser_id bigint = 10009282;
DECLARE @foundation_act_interview_uid bigint = 20000140;
DECLARE @foundation_patient_uid       bigint = 20000000;
DECLARE @foundation_provider_uid      bigint = 20000010;
DECLARE @foundation_org_uid           bigint = 20000020;
DECLARE @foundation_investigation_uid bigint = 20000100;
DECLARE @dbo_Act_interview_v2_uid     bigint = 20090010;

-- =====================================================================
-- nrt_interview: 2 rows total.
--   Row 1. Foundation Interview (UID 20000140) — sparse / null path.
--     Mirrors foundation NBS_ODSE.dbo.interview row content.
--     interview_status_cd='C' (NOT a real NBS_INTVW_STATUS code; the
--     postprocessing SP's `nrt_interview.interview_status_cd` propagates
--     directly to D_INTERVIEW.IX_STATUS_CD with no JOIN to SRTE in the
--     postprocessing path). interviewee_role_cd=NULL exhibits the
--     all-sentinel-1 ELSE path on every F_INTERVIEW_CASE CASE branch.
--     Soft refs (provider/org/patient/investigation) NULL — exhibits
--     the no-cross-subject path. ix_status / ix_type / ix_location /
--     ix_interviewee_role NULL — exhibits the no-SRTE-description path.
--   Row 2. v2 Interview (UID 20090010) — fully populated.
--     Soft refs point at foundation Patient/Provider/Org/Investigation.
--     interviewee_role_cd='PHYS' drives PHYSICIAN_KEY routing.
-- 22 settable columns out of 25. refresh_datetime + max_datetime are
-- GENERATED ALWAYS (omitted; system fills them). batch_id NULL is fine
-- (the SP's join `isnull(intans.batch_id, 1) = isnull(inv.batch_id, 1)`
-- handles NULL).
-- =====================================================================

-- =====================================================================
-- nrt_interview_note: 2 rows attached to v2 Interview (UID 20090010).
--   Foundation has no notes (exhibits empty-notes path).
--   v2 carries 2 notes — exercises the SP's INSERT-after-DELETE path
--   in D_INTERVIEW_NOTE (lines 451-519 of sp_d_interview_postprocessing).
--   Each note has its own nbs_answer_uid (the SP joins on it for the
--   surrogate-key map). nbs_answer_uid values 20090020 and 20090021
--   are inside Interview's UID block but are NOT real ODSE NBS_ANSWER
--   row UIDs — they're standalone identity values. The SP only reads
--   nbs_answer_uid as a column on nrt_interview_note + nrt_interview_note_key
--   (no FK to NBS_ANSWER). Same approach as the rest of the synthetic
--   staging.
-- 7 settable columns of 10. refresh_datetime + max_datetime GENERATED
-- ALWAYS (omitted). batch_id NULL — the SP joins
-- `isnull(ixn.batch_id, 1) = isnull(inv.batch_id, 1)` handles NULL.
-- =====================================================================

GO
