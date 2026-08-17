USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 3 coverage fixture: INTERVIEW answer + note gap-fill.
--
-- TARGETS
--   1. dbo.D_INTERVIEW (RDB_MODERN) — close the 6 NULL dynamic/LDF
--      columns (currently 0/2 across the 2 interview rows; the other
--      18/24 already populate from the foundation + v2 interview rows):
--        IX_CONTACTS_NAMED_IND   (question STD301 / 10001355, CODED YN)
--        IX_900_SITE_TYPE        (question IXS109 / 10001358, CODED NBS_SITE_TYPE_HIV)
--        IX_INTERVENTION         (question IXS110 / 10001359, CODED NBS_INTERVENTION_HIV)
--        CLN_CARE_STATUS_IXS     (question NBS445 / 10003226, CODED NBS_CARE_STATUS)
--        IX_900_SITE_ID          (question IXS107 / 10001356, TEXT)
--        IX_900_SITE_ZIP         (question IXS108 / 10001357, TEXT / TXT_ZIP)
--   2. dbo.D_INTERVIEW_NOTE (RDB_MODERN) — currently 0/7 EMPTY. Populate
--      all 7 live columns by authoring one IXS111 (10001024) interview
--      NOTE answer on the v2 interview.
--
-- WHY ANSWERS, NOT A NEW INTERVIEW ENTITY (no obs chains — LESSON R5
-- d_var_pam tip): D_INTERVIEW's 6 dynamic columns are the LDF pivot
-- columns registered in RDB_MODERN.dbo.nrt_metadata_columns for
-- D_INTERVIEW (verified: the 6 columns above are present). The
-- postprocessing SP (routines/023-sp_d_interview_postprocessing) PIVOTs
-- dbo.nrt_interview_answer.rdb_column_nm -> answer_val into those
-- columns. nrt_interview_answer is produced by the event SP
-- (routines/065-sp_interview_event) from #UNIONED_DATA, which reads
-- NBS_ODSE.dbo.v_rdb_ui_metadata_answers WHERE rdb_table_nm='D_INTERVIEW'
-- AND answer_group_seq_nbr IS NULL. That view joins
-- nbs_rdb_metadata -> nbs_ui_metadata -> nbs_answer ON nbs_question_uid.
-- So the ONLY ODSE rows needed are dbo.nbs_answer rows on the interview
-- act for the 6 backing questions (the nbs_rdb_metadata / nbs_ui_metadata
-- rows already exist in the seed — verified live). No observations, no
-- act chains, no new entities.
--
-- The D_INTERVIEW_NOTE source is the event SP #INTERVIEW_NOTE_INIT step
-- (065 lines ~1079-1135): it reads v_rdb_ui_metadata_answers WHERE
-- QUESTION_IDENTIFIER='IXS111' AND RDB_TABLE_NM='D_INTERVIEW_NOTE', and
-- parses ANSWER_TXT in the form  "<First Last>~<comment_date>~~<comment>"
--   USER             = text before the first '~'
--   USER_FIRST_NAME  = USER before first space; USER_LAST_NAME = after
--   COMMENT_DATE     = text between the first '~' and the second '~'
--   USER_COMMENT     = text after '~~'
-- One IXS111 nbs_answer (also a row on the same interview act) produces
-- one D_INTERVIEW_NOTE row with all 7 live columns set.
--
-- TARGET INTERVIEW (existing, already investigation/patient-linked):
--   v2 interview act_uid = 20090010 (fixtures/10_subjects/interview.sql)
--     - already linked to v2 Investigation 20050010 via act_relationship
--       'IXS' (fixtures/20_links/interview_phc.sql)
--     - already linked to v2 Patient 20020010 via nbs_act_entity
--       'IntrvweeOfInterview' (fixtures/20_links/interview_links.sql)
--   This fixture does NOT author a new interview / act / entity — it is
--   purely additive answer rows on the existing v2 interview, closing the
--   D_INTERVIEW LDF columns + the empty D_INTERVIEW_NOTE for that row.
--   (Adding answers to the foundation interview 20000140 is deliberately
--   NOT done — foundation exhibits the no-answer / NULL-description path
--   and other coverage reports baseline against it.)
--
-- nbs_answer.nbs_answer_uid is an IDENTITY column (verified via
-- sys.identity_columns). Per LESSON 10 / 11 we do NOT use a hardcoded
-- SET IDENTITY_INSERT (which would collide with the auto-IDENTITY flood
-- from zz_page_answers_datamart_routing and silently skip). Let IDENTITY
-- auto-assign; guard idempotency on the natural key
-- (act_uid, nbs_question_uid, answer_group_seq_nbr IS NULL). The surrogate
-- UID is irrelevant downstream — the SPs key on (act_uid, question) and
-- carry whatever surrogate the view surfaces. UID block 22075000-22075999
-- is therefore reserved (catalog/uid_ranges.md) but consumed only as the
-- documentation anchor / note comment_date marker; no explicit UID is
-- inserted into an IDENTITY column.
--
-- CODE VALUES (all verified live in NBS_SRTE):
--   STD301 (YN, 4130):              'Y'      -> Yes (contacts named)
--   IXS109 (NBS_SITE_TYPE_HIV,105840):'F03'  -> Clinical - Emergency department
--   IXS110 (NBS_INTERVENTION_HIV,105880):'b' -> HIV Intervention Value b
--   NBS445 (NBS_CARE_STATUS,107860):'1'      -> 1-In Care
--   IXS107 (TEXT):                  'SITE-22075'
--   IXS108 (TEXT / TXT_ZIP):        '30303'
--
-- HARD RULES OBSERVED: ODSE-only (dbo.nbs_answer); no nrt_* INSERT; no
-- EXEC sp_*; no liquibase/seed/SRTE edit; additive (UID block 22075xxx);
-- never UPDATE shared dims; idempotent NOT EXISTS guards; closing
-- last_chg_time bump on the interview act. No observations / no act
-- chains (LESSON: keep interview/answer-driven, not obs-heavy).
--
-- ORCH_TODO (orchestrator — harness wiring in scripts/merge_and_verify.sh):
--   run_interview_chain() runs ONLY in Step 5 (run_tier_1_chains) and
--   Step 7 (rerun_tier_1_chains), both BEFORE Tier 3 fixtures are applied
--   (Step 8). These nbs_answer rows are applied in Step 8, so the
--   interview chain must be re-driven AFTER apply_tier_3_fixtures so the
--   event SP picks up the new answers into nrt_interview_answer /
--   nrt_interview_note and the postprocessing SP pivots them into
--   D_INTERVIEW + D_INTERVIEW_NOTE. Add, after the Step-9 Tier-3 drain
--   (merge_and_verify.sh ~line 764) and before/alongside
--   run_summary_datamarts, a re-run of the interview chain over the v2
--   interview UID:
--       sql_q RDB_MODERN "EXEC dbo.sp_interview_event @ix_uids = N'20090010'" >/dev/null
--       sql_q RDB_MODERN "EXEC dbo.sp_d_interview_postprocessing @interview_uids = N'20090010', @debug = 0" >/dev/null
--   (Idempotent: the event SP rebuilds nrt_interview_answer/note from
--   ODSE; sp_d_interview_postprocessing UPDATEs D_INTERVIEW in place and
--   DELETE+reinserts D_INTERVIEW_NOTE. The f_interview_case SP is
--   unaffected and need not re-run.)
-- =====================================================================

-- ----- Sentinel reference -----
DECLARE @superuser_id bigint = 10009282;          -- conventional NBS superuser id

-- ----- Target interview (existing v2, read-only reference) -----
DECLARE @v2_interview_uid bigint = 20090010;      -- v2 interview act_uid (fixtures/10_subjects/interview.sql)

-- =====================================================================
-- 1. The 6 dynamic-column D_INTERVIEW answers + the IXS111 note answer.
--    All on the v2 interview act 20090010, answer_group_seq_nbr = NULL
--    (the single-dim / D_INTERVIEW pivot path the event SP requires).
--    seq_nbr = 0, ACTIVE, superuser, version ctrl 1 (NBS convention).
--    nbs_answer_uid auto-assigns (IDENTITY) — no SET IDENTITY_INSERT.
--    Guard on (act_uid, nbs_question_uid, answer_group_seq_nbr IS NULL).
-- =====================================================================

-- IX_CONTACTS_NAMED_IND (STD301 / 10001355, ver 10) — CODED YN
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_answer]
               WHERE act_uid = @v2_interview_uid AND nbs_question_uid = 10001355 AND answer_group_seq_nbr IS NULL)
    INSERT INTO [dbo].[nbs_answer]
        ([act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [seq_nbr], [answer_group_seq_nbr], [record_status_cd], [record_status_time],
         [last_chg_time], [last_chg_user_id])
    VALUES
        (@v2_interview_uid, N'Y', 10001355, 10, 0, NULL, N'ACTIVE', GETDATE(), CAST(GETDATE() AS DATE), @superuser_id);

-- IX_900_SITE_TYPE (IXS109 / 10001358, ver 8) — CODED NBS_SITE_TYPE_HIV
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_answer]
               WHERE act_uid = @v2_interview_uid AND nbs_question_uid = 10001358 AND answer_group_seq_nbr IS NULL)
    INSERT INTO [dbo].[nbs_answer]
        ([act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [seq_nbr], [answer_group_seq_nbr], [record_status_cd], [record_status_time],
         [last_chg_time], [last_chg_user_id])
    VALUES
        (@v2_interview_uid, N'F03', 10001358, 8, 0, NULL, N'ACTIVE', GETDATE(), CAST(GETDATE() AS DATE), @superuser_id);

-- IX_INTERVENTION (IXS110 / 10001359, ver 8) — CODED NBS_INTERVENTION_HIV
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_answer]
               WHERE act_uid = @v2_interview_uid AND nbs_question_uid = 10001359 AND answer_group_seq_nbr IS NULL)
    INSERT INTO [dbo].[nbs_answer]
        ([act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [seq_nbr], [answer_group_seq_nbr], [record_status_cd], [record_status_time],
         [last_chg_time], [last_chg_user_id])
    VALUES
        (@v2_interview_uid, N'b', 10001359, 8, 0, NULL, N'ACTIVE', GETDATE(), CAST(GETDATE() AS DATE), @superuser_id);

-- CLN_CARE_STATUS_IXS (NBS445 / 10003226, ver 4) — CODED NBS_CARE_STATUS
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_answer]
               WHERE act_uid = @v2_interview_uid AND nbs_question_uid = 10003226 AND answer_group_seq_nbr IS NULL)
    INSERT INTO [dbo].[nbs_answer]
        ([act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [seq_nbr], [answer_group_seq_nbr], [record_status_cd], [record_status_time],
         [last_chg_time], [last_chg_user_id])
    VALUES
        (@v2_interview_uid, N'1', 10003226, 4, 0, NULL, N'ACTIVE', GETDATE(), CAST(GETDATE() AS DATE), @superuser_id);

-- IX_900_SITE_ID (IXS107 / 10001356, ver 8) — TEXT
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_answer]
               WHERE act_uid = @v2_interview_uid AND nbs_question_uid = 10001356 AND answer_group_seq_nbr IS NULL)
    INSERT INTO [dbo].[nbs_answer]
        ([act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [seq_nbr], [answer_group_seq_nbr], [record_status_cd], [record_status_time],
         [last_chg_time], [last_chg_user_id])
    VALUES
        (@v2_interview_uid, N'SITE-22075', 10001356, 8, 0, NULL, N'ACTIVE', GETDATE(), CAST(GETDATE() AS DATE), @superuser_id);

-- IX_900_SITE_ZIP (IXS108 / 10001357, ver 8) — TEXT / TXT_ZIP
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_answer]
               WHERE act_uid = @v2_interview_uid AND nbs_question_uid = 10001357 AND answer_group_seq_nbr IS NULL)
    INSERT INTO [dbo].[nbs_answer]
        ([act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [seq_nbr], [answer_group_seq_nbr], [record_status_cd], [record_status_time],
         [last_chg_time], [last_chg_user_id])
    VALUES
        (@v2_interview_uid, N'30303', 10001357, 8, 0, NULL, N'ACTIVE', GETDATE(), CAST(GETDATE() AS DATE), @superuser_id);

-- IXS111 (10001024, ver 16) — D_INTERVIEW_NOTE source. TEXT answer parsed
-- as  "<First Last>~<comment_date>~~<comment>"  by event SP 065 step
-- #INTERVIEW_NOTE (lines ~1113-1135). All 7 D_INTERVIEW_NOTE live columns
-- derive from this single answer (NBS_ANSWER_UID + D_INTERVIEW_KEY +
-- USER_FIRST_NAME 'Dana' + USER_LAST_NAME 'Reyes' + USER_COMMENT +
-- COMMENT_DATE + D_INTERVIEW_NOTE_KEY surrogate).
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_answer]
               WHERE act_uid = @v2_interview_uid AND nbs_question_uid = 10001024 AND answer_group_seq_nbr IS NULL)
    INSERT INTO [dbo].[nbs_answer]
        ([act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [seq_nbr], [answer_group_seq_nbr], [record_status_cd], [record_status_time],
         [last_chg_time], [last_chg_user_id])
    VALUES
        (@v2_interview_uid,
         N'Dana Reyes~2026-04-15 10:30:00~~Re-interview completed; partner services follow-up scheduled.',
         10001024, 16, 0, NULL, N'ACTIVE', GETDATE(), CAST(GETDATE() AS DATE), @superuser_id);

GO

-- =====================================================================
-- 2. Closing last_chg_time bump on the interview act so the event /
--    postprocessing re-run sees a fresh change marker (mirrors the
--    last_chg_time bump pattern used by zz_std_hiv_fill.sql et al.).
--    interview is NOT a shared dim — this is the per-subject Tier 1
--    interview row, additive-context only.
-- =====================================================================
UPDATE [dbo].[interview]
   SET last_chg_time = GETDATE()
 WHERE interview_uid = 20090010;
GO
