-- =====================================================================
-- zz_std_hiv_answer_gap.sql  (Round 6, no-shortcut, ODSE-only, NON-OBS)
-- =====================================================================
-- Authored 2026-06-04 (R6 incremental, std_hiv-answer-gap agent).
-- UID block reserved: 22070000 - 22070999 (NONE consumed — this fixture
-- is a pure UPDATE of the STD investigation's OWN public_health_case
-- row, exactly like zz_std_case_management.sql; no new entities/answers
-- needed, so the block stays free).
--
-- TARGET: close 4 of the ~25 currently-NULL non-PATIENT columns of
-- dbo.STD_HIV_DATAMART (RDB_MODERN, live 223/248 on STD Syphilis-primary
-- PHC 22004000, INVESTIGATION_KEY=6, cond 10311 / PG_STD_Investigation):
--
--     OUTBREAK_NAME             <- INV.OUTBREAK_NAME
--     INVESTIGATION_DEATH_DATE  <- INV.INVESTIGATION_DEATH_DATE
--     CURR_PROCESS_STATE        <- INV.CURR_PROCESS_STATE  (decoded)
--     COINFECTION_ID            <- INV.COINFECTION_ID
--
-- These are PHC-core scalars carried by the Investigation dim
-- (nrt_investigation), NOT page answers and NOT observations. They are
-- NULL purely because the per-investigation public_health_case source
-- row (authored by std_hiv_investigation_full_chain.sql, line 166) left
-- the four underlying ODSE columns NULL / unset:
--     outbreak_name = NULL, deceased_time unset,
--     curr_process_state_cd unset, coinfection_id unset.
--
-- LINEAGE (verified live against routine source 2026-06-04)
--   1. sp_investigation_event (routine 056) projects, from the PHC's OWN
--      row, the investigation JSON:
--        - outbreak_name           -> raw passthrough (056 line 183/45;
--                                     NULLIF only — NO codeset gate, so
--                                     free text lands directly)
--        - deceased_time           -> passthrough (056 line 289/111)
--        - curr_process_state_cd   -> DECODED via
--                                     fn_get_value_by_cvg(cd,'CM_PROCESS_STAGE')
--                                     into `curr_process_state` (056 line 201-207)
--        - coinfection_id          -> passthrough (056 line 318/130)
--   2. sp_nrt_investigation_postprocessing (routine 005) lands them on the
--      Investigation dim:
--        OUTBREAK_NAME (005 line 51/434), INVESTIGATION_DEATH_DATE
--        (line 94/476), CURR_PROCESS_STATE (line 119/494 = decoded value),
--        COINFECTION_ID (line 121/496).
--   3. sp_std_hiv_datamart_postprocessing (routine 026) reads them off the
--      Investigation alias INV:
--        ADI... ,[OUTBREAK_NAME]=INV.OUTBREAK_NAME (026 line 388),
--        [INVESTIGATION_DEATH_DATE]=CAST(FORMAT(INV.INVESTIGATION_DEATH_DATE...))
--        (line 332), [CURR_PROCESS_STATE]=INV.CURR_PROCESS_STATE (line 274),
--        [COINFECTION_ID]=INV.COINFECTION_ID (line 270).
--
-- CODE VERIFICATION (NBS_SRTE.dbo.code_value_general 2026-06-04)
--   curr_process_state_cd = 'OC' is a valid CM_PROCESS_STAGE code
--   ('Open Case'); it decodes -> CURR_PROCESS_STATE='Open Case'.
--   (The stock 'OPEN-NEW' value does NOT exist in CM_PROCESS_STAGE, so it
--   would decode to NULL — that's why CURR_PROCESS_STATE was NULL.)
--   outbreak_name is raw free text (no codeset), coinfection_id is free
--   text, deceased_time is a datetime — all land verbatim.
--
-- WIDTHS: source public_health_case columns
--   outbreak_name varchar(100), curr_process_state_cd varchar(20),
--   coinfection_id varchar(50), deceased_time datetime — all values fit;
--   target datamart columns are varchar(100)/datetime — all fit.
--
-- WHICH SP(s) PICK THIS UP (no manual EXEC — the real pipeline runs them)
--   The closing public_health_case.last_chg_time bump re-fires CDC ->
--   sp_investigation_event (re-projects the enriched investigation JSON)
--   -> Step-9 sp_nrt_investigation_postprocessing (re-lands the dim)
--   -> sp_std_hiv_datamart_postprocessing (re-reads INV.* -> the 4 cols).
--   22004000 is already in PHC_UIDS, so all Step-9 SPs run for it.
--
-- NON-OBS-HEAVY (bug #20 obs fail-fast): this fixture authors NO
-- observations and NO new nbs_case_answer rows — it only UPDATEs four
-- columns on the investigation's OWN public_health_case row + bumps
-- last_chg_time. Zero added obs => cannot enlarge the obs batch =>
-- cannot trip the obs fail-fast skip path.
--
-- ADDITIVE / SAFETY: the public_health_case row is the investigation's
-- OWN per-investigation row (NOT a shared dim like D_PATIENT/D_PROVIDER/
-- D_ORGANIZATION/USER_PROFILE). This is the same mechanism used by
-- zz_std_case_management.sql. Only the four currently-unset columns are
-- written; nothing already populated is touched. No nrt_* INSERT, no
-- EXEC sp_*, no liquibase/seed/SRTE edits. Idempotent (re-running sets
-- the same values).
--
-- ==================== NULL COLUMNS DELIBERATELY SKIPPED ===============
-- The other ~21 NULL non-key columns of STD_HIV_DATAMART are NOT
-- reachable on the no-shortcut answer/PHC path (documented, not fixed):
--   * PATIENT-derived (D_PATIENT, shared foundation patient — never
--     UPDATE shared dims): PATIENT_ADDL_GENDER_INFO, PATIENT_ALIAS,
--     PATIENT_DECEASED_DATE, PATIENT_PREFERRED_GENDER.
--   * PROVIDER-derived (D_PROVIDER.PROVIDER_QUICK_CODE via F_STD_PAGE_CASE
--     provider keys — need dedicated provider chains): the 10
--     INVESTIGATOR_*_QC columns (CLOSED/CURRENT/DISP_FL_FUP/FL_FUP/
--     INITIAL/INIT_FL_FUP/INIT_INTRVW/INTERVIEW/SUPER_CASE/SUPER_FL_FUP/
--     SURV_QC).
--   * INTERVIEW-derived: IX_DATE_OI (F_INTERVIEW_CASE + D_INTERVIEW,
--     IX_TYPE_CD='INITIAL') — needs an interview/observation chain.
--   * OBSERVATION/confirmation-derived: CONFIRMATION_DT
--     (CONFIRMATION_METHOD_GROUP) — obs-driven; skipped per bug #20.
--   * MASTERETL-ONLY D_INV_HIV columns (no RTR page-builder mapping;
--     lineage L3 marks them MASTERETL_ONLY / hand-authored):
--     HIV_CA_900_OTH_RSN_NOT_LO, HIV_CA_900_REASON_NOT_LOC — unreachable
--     via the no-shortcut pipeline.
--   * CODE-DECODE dead-ends on D_CASE_MANAGEMENT:
--     ADI_900_STATUS (= CM.STATUS_900, the decoded sibling of the
--     already-populated ADI_900_STATUS_CD='C'); the raw status_900='C'
--     does not decode to a display value in the modern codeset, so the
--     decoded column stays NULL.
--   * PAGE-BUILDER, BUT BLOCKED:
--     SOC_MALE_PRTNRS_12MO_IND (D_INV_SOCIAL_HISTORY, code set YNUR /
--     group 105240) is NULL because zz_std_hiv_fill.sql already authored
--     a NULL-group answer on (22004000, q 10001289) with the value '1',
--     which fails YNUR resolution. The page-builder single-dim path only
--     reads answer_group_seq_nbr IS NULL (routine 007 lines 103/191), so
--     a corrective answer cannot be hidden behind a distinguishing group;
--     a 2nd NULL-group answer would collide with the existing one and
--     risks a LESSON-11-class regression. Left untouched (would need a
--     value correction to the existing fill, owned elsewhere).
-- =====================================================================

USE [NBS_ODSE];
GO

-- ---------------------------------------------------------------------
-- Enrich the four currently-NULL PHC-core scalars on the STD
-- investigation's OWN public_health_case row (22004000). Guarded so it
-- only writes when the columns are still NULL/unset (idempotent + does
-- not stomp any later enrichment). Nothing else on the row is touched.
-- ---------------------------------------------------------------------
UPDATE [dbo].[public_health_case]
   SET outbreak_name         = N'STD-OUTBREAK-22004',   -- raw -> OUTBREAK_NAME
       deceased_time         = '2026-05-01T00:00:00',   -- -> INVESTIGATION_DEATH_DATE
       curr_process_state_cd = N'OC',                   -- CM_PROCESS_STAGE -> CURR_PROCESS_STATE='Open Case'
       coinfection_id        = N'COINF-STD-22004'        -- -> COINFECTION_ID
 WHERE public_health_case_uid = 22004000
   AND ( outbreak_name IS NULL
      OR deceased_time IS NULL
      OR curr_process_state_cd IS NULL
      OR coinfection_id IS NULL );
GO

-- ---------------------------------------------------------------------
-- CDC RE-TRIGGER: bump public_health_case.last_chg_time so Debezium
-- re-emits PHC 22004000 -> the service re-runs sp_investigation_event and
-- re-projects the enriched investigation JSON during the Tier-3 drain.
-- GETDATE() guarantees a value later than any prior literal bump in the
-- STD fixture set, so this enrichment wins. (Investigation's OWN PHC row;
-- not a shared dim. No nrt_* INSERT, no EXEC sp_.)
-- ---------------------------------------------------------------------
UPDATE [dbo].[public_health_case]
   SET last_chg_time = GETDATE()
 WHERE public_health_case_uid = 22004000;
GO
