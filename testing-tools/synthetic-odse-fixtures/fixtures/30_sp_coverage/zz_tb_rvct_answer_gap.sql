-- =====================================================================
-- zz_tb_rvct_answer_gap.sql  (Round 6, R6-TB-GAP, no-shortcut, ODSE-only,
--                            NON-OBS-HEAVY)
-- =====================================================================
-- TARGET: close part of the NON-PATIENT column gap (25 always-NULL cols
--   each) in dbo.tb_datamart (293/318) and dbo.tb_hiv_datamart (297/322)
--   by authoring additional RVCT-form D_TB_PAM ANSWER columns on the
--   EXISTING TB chain. Specifically the three answer-derived D_TB_PAM
--   columns that are still NULL across ALL tb_datamart / tb_hiv_datamart
--   rows because no investigation answers them with a value that survives
--   the 147 SP's codeset/date pivot:
--
--     COLUMN (datamart)              D_TB_PAM <- nbs_question_uid (RVCT q)
--     -----------------------------  ------------------------------------
--     PRIMARY_GUARD_1_BIRTH_COUNTRY  1042  TUB115  (codeset 4260 PHVS_TB_BIRTH_CNTRY)
--     PRIMARY_GUARD_2_BIRTH_COUNTRY  1320  TUB116  (codeset 4260 PHVS_TB_BIRTH_CNTRY)
--     INIT_REGIMEN_START_DATE        1001  TUB170  (date answer, no codeset)
--
--   Both datamarts inherit these identically: routine 260
--   (sp_tb_hiv_datamart_postprocessing) builds tb_hiv_datamart as
--   `d.* FROM TB_DATAMART d`, so filling tb_datamart's PRIMARY_GUARD_*/
--   INIT_REGIMEN_START_DATE automatically fills the same-named
--   tb_hiv_datamart columns. => +3 cols on EACH table (293->296, 297->300).
--
-- WHY THESE WERE NULL (verified live 2026-06-04)
--   * PRIMARY_GUARD_1/2_BIRTH_COUNTRY: the only investigation answering
--     1042/1320 is TB PHC 22001000, whose answer_txt='840' is NOT a valid
--     code in codeset 4260 (PHVS_TB_BIRTH_CNTRY) -> the 147 SP codeset join
--     collapses to NULL. (The valid 4260 codes are ISO-3166 alpha-3, e.g.
--     'USA','CAN','IND','MEX','FRA'.) The second TB PHC 22050000 has NO
--     1042/1320 answer at all.
--   * INIT_REGIMEN_START_DATE (TUB170, 1001): no investigation answers it
--     on EITHER TB PHC.
--
-- WHY ON THE SECOND TB PHC 22050000 (not 22001000)
--   Coverage is per-COLUMN "any non-NULL across all rows". The SECOND TB
--   RVCT investigation 22050000 (authored by zz_tb_datamart_fill.sql) is a
--   full TB RVCT case that already lands its own tb_datamart / tb_hiv_datamart
--   row and is already in PHC_UIDS, but has NONE of these three answers.
--   Authoring valid answers there lights up all three columns table-wide
--   WITHOUT editing any existing fixture or any PHC INSERT, and WITHOUT
--   risking the codeset clash that the 22001000 '840' rows carry. Purely
--   additive RVCT clinical/treatment answers on the existing TB chain.
--
-- HOW THE REAL PIPELINE TURNS THIS INTO COVERAGE (no-shortcut, no obs)
--   These are nbs_case_answer rows only (NO observations of any class — the
--   service obs-batch is FAIL-FAST per bug #20, so this fixture deliberately
--   adds ZERO observation/lab/result rows). The reporting-pipeline-service:
--     1. CDC mirrors nbs_case_answer -> page-builder writes
--        nrt_page_case_answer (datamart_column_nm + code_set_group_id +
--        question_identifier resolved from nbs_question by nbs_question_uid).
--     2. sp_nrt_d_tb_pam_postprocessing (147) pivots nrt_page_case_answer for
--        INV_FORM_RVCT on DATAMART_COLUMN_NM -> D_TB_PAM gains
--        PRIMARY_GUARD_1_BIRTH_COUNTRY / PRIMARY_GUARD_2_BIRTH_COUNTRY /
--        INIT_REGIMEN_START_DATE for 22050000.
--     3. sp_f_tb_pam_postprocessing (206) rebuilds F_TB_PAM (key
--        nac_page_case_uid=22050000), then sp_tb_datamart_postprocessing
--        (255) + sp_tb_hiv_datamart_postprocessing (260) re-emit the
--        22050000 datamart rows with the three new column values.
--   The closing public_health_case.last_chg_time bump on 22050000 (and the
--   bump on 22001000 left to the existing fixtures) is the CDC re-trigger
--   that drives sp_investigation_event -> the page-builder -> the TB datamart
--   SP chain. 22050000 is already in scripts/merge_and_verify.sh PHC_UIDS,
--   so Step 9 (147/206/255/260) and the service page-builder process it; NO
--   ORCH_TODO is required.
--
-- COLUMNS DELIBERATELY NOT TARGETED (out of scope for an additive,
-- NON-OBS, RVCT-answer-only fixture on the existing chain — documented so a
-- later pass doesn't re-chase them blind):
--   * RACE_ASIAN_2/3, RACE_NAT_HI_1/2/3/_ALL/_GT3_IND  -> D_PATIENT race
--     detail (patient-side; would need person_race edits, not RVCT answers).
--   * INVESTIGATION_START_DATE, STATE_CASE_NUMBER, ILLNESS_ONSET_DATE,
--     ILLNESS_END_DATE, ILLNESS_DURATION(_UNIT), DETECTION_METHOD,
--     OUTBREAK_NAME  -> nrt_investigation/PHC-core fields (activity_from_time,
--     effective_from_time/to_time, inv_state_case_id, detection_method_cd,
--     outbreak_name); these read from public_health_case columns, NOT page
--     answers, so they require editing an existing PHC INSERT (forbidden) or a
--     NEW PHC (out of this fixture's additive-answer scope).
--   * CITY_COUNTY_CASE_NUMBER (INV198, 1287) -> data_location
--     Act_id.root_extension_txt (an act_id row, not an RVCT answer).
--   * NOTIFICATION_SENT_DATE (SUM109, 5370) -> Notification.rpt_sent_time
--     (requires a Notification record, not a case answer).
--   * SMR_EXAM_TY_3 (TUB129, 1174) -> UNREACHABLE: codeset 2560
--     (PHVS_TB_MICRO_EX_TY) ships only TWO valid codes (Pathology/Cytology,
--     Smear), so the ROW_NUMBER-over-distinct-VALUE pivot can never produce a
--     3rd rank (documented ceiling, also noted in zz_tb_datamart_fill.sql).
--
-- UID BLOCK (reserved catalog/uid_ranges.md R6 tb gap agent):
--   22066000 - 22066999. nbs_case_answer.nbs_case_answer_uid is a flood-prone
--   IDENTITY column (LESSON 10) -> this fixture does NOT IDENTITY_INSERT and
--   does NOT hardcode any nbs_case_answer_uid; IDENTITY auto-assigns and the
--   pipeline keys page answers on (act_uid, nbs_question_uid, seq_nbr). The
--   reserved 22066xxx block is therefore NOT consumed by surrogate keys
--   (IDENTITY owns the value); it remains reserved for this target.
--
-- IDEMPOTENT: guarded by IF NOT EXISTS on the block's natural key
--   (act_uid=22050000, nbs_question_uid=1042, answer_group_seq_nbr IS NULL).
--   Per LESSON 11 the guard includes the distinguishing column
--   (answer_group_seq_nbr IS NULL) so it matches ONLY this block's single-dim
--   rows and cannot be masked by any earlier fixture answering the same
--   (act,Q) at a different group (none does for the TB legacy form, verified).
-- ADDITIVE: only NEW nbs_case_answer rows + the new PHC's own last_chg_time
--   bump. NO UPDATE of any shared dim. NO observations (NON-OBS-HEAVY). NO
--   nrt_* INSERT. NO EXEC sp_. NO liquibase / seed / SRTE / routine edit. NO
--   edit to any existing fixture. GENERATED ALWAYS period cols omitted.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @user    bigint = 10009282;
DECLARE @tb_phc  bigint = 22050000;   -- the second TB RVCT PHC (zz_tb_datamart_fill.sql)

-- nbs_case_answer_uid is IDENTITY; let it AUTO-assign (LESSON 10) and guard
-- on the natural key + distinguishing column (answer_group_seq_nbr IS NULL,
-- LESSON 11). These are single (non-repeating) D_TB_PAM answers.
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @tb_phc AND nbs_question_uid = 1042
                 AND answer_group_seq_nbr IS NULL)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
    -- TUB115 PRIMARY_GUARD_1_BIRTH_COUNTRY (codeset 4260 PHVS_TB_BIRTH_CNTRY; 'IND' = INDIA)
    (@tb_phc, '2026-04-01T00:00:00', @user, N'IND', 1042, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB116 PRIMARY_GUARD_2_BIRTH_COUNTRY (codeset 4260; 'CAN' = CANADA)
    (@tb_phc, '2026-04-01T00:00:00', @user, N'CAN', 1320, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TUB170 INIT_REGIMEN_START_DATE (date answer; no codeset)
    (@tb_phc, '2026-04-01T00:00:00', @user, N'2026-04-08', 1001, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0);
END
GO

-- ---------------------------------------------------------------------
-- CDC re-trigger: bump the SECOND TB PHC's last_chg_time so Debezium/connect
-- re-emits public_health_case 22050000 -> the service re-runs
-- sp_investigation_event and the page-builder fires the RVCT D_TB_PAM SP
-- chain (147 -> 206 -> 255 -> 260) AFTER the new answers exist. This is the
-- investigation's OWN row (not a shared dim). Same bump pattern as
-- zz_tb_datamart_fill.sql. No nrt_* / EXEC sp_ here.
-- ---------------------------------------------------------------------
UPDATE [dbo].[public_health_case]
   SET last_chg_time = GETDATE()
 WHERE public_health_case_uid = 22050000;
GO
