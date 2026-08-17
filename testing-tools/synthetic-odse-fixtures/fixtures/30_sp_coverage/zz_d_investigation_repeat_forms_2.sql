-- =====================================================================
-- Round 6 tick 2 (NO-SHORTCUT, NON-OBS-HEAVY) — D_INVESTIGATION_REPEAT
-- 2nd "other-value" (_OTH) column fill on EXISTING page-builder PHCs.
-- COMPANION to zz_d_investigation_repeat_forms.sql (#1) — targets a
-- DIFFERENT set of _OTH columns / PHCs / blocks and a NON-COLLIDING
-- answer_group_seq_nbr (=5), so it never touches #1's group-4 rows.
-- =====================================================================
-- Branch: aw/remove-nrt-shortcut. This fixture authors ONLY NBS_ODSE
-- nbs_case_answer rows (+ a closing last_chg_time CDC re-trigger bump on
-- the affected public_health_case rows). It adds NO observations
-- (no observation/observation_reason/act-of-class-OBS, no lab/result
-- chains) — bug #20 obs fail-fast makes obs-heavy fixtures corrupt
-- lower-priority coverage, so this round stays investigation/answer-only.
-- NO nrt_* INSERTs, NO EXEC sp_*, NO liquibase/seed/SRTE edits.
--
-- TARGET TABLE / COLUMNS
--   dbo.D_INVESTIGATION_REPEAT (RDB_MODERN). Targets these still-NULL
--   "_OTH" (other-value free-text) columns that fixture #1 did NOT fill
--   (verified live: COUNT(col)=0 over the whole dim before this fixture):
--     LAB_TEST_RESULT_OTH        (parent q 10001371, LAB_INTERPRETIVE)
--     LAB_PERFORMING_LAB_TYP_OTH (parent q 10001374, LAB_INTERPRETIVE)
--     LAB_SPECIMEN_SOURCE_OTH    (parent q 10002114, LAB_INTERPRETIVE)
--     LAB_TEST_METHOD_OTH        (parent q 10010294, LAB_BLOCK)
--     LAB_MOLE_SUSC_SPEC_TY_OTH  (parent q 10012210, MOLE_DRG_SUSCEP)
--     LAB_MOLE_SUSC_TST_MTHD_OTH (parent q 10012215, MOLE_DRG_SUSCEP)
--     EPI_SUSPECTED_SOURCE_R_OTH (parent q 10009214, BLOCK_8)
--     LAB_AST_COLLECTION_SIT_OTH (parent q 10002148, BLOCK_14)
--   The corresponding PARENT columns are already populated on these PHCs
--   (their group-1/2/3 answers used plain codes, so the _OTH stayed NULL).
--   NOTE: these parent questions are DISJOINT from fixture #1's 26 parents
--   (#1 used 10010264/10012234/10012229/10002147/10002151/10002150/
--    10010295/10001370 on 22047000, none of which is in this file) — so
--   there is zero parent-question overlap on any shared PHC.
--
-- HOW _OTH COLUMNS POPULATE (routine 010
-- sp_sld_investigation_repeat_postprocessing, run by the orchestrator at
-- Step 8.5 over $PHC_UIDS):
--   The CODED branch builds #CODED_TABLE_OTH_REPT from rows whose
--   metadata OTHER_VALUE_IND_CD='T' (SP lines 396-421). For such a
--   question, an answer of the form 'OTH^<free text>' yields:
--     ANSWER_OTH      = <free text>          (split on '^')
--     RDB_COLUMN_NM   = <col-first-22-chars> + '_OTH'
--     ANSWER_DESC11   = ANSWER_OTH
--   which then pivots into the <PARENT>_OTH column, keyed on
--   (PAGE_CASE_UID, BLOCK_NM, ANSWER_GROUP_SEQ_NBR). All 8 parent
--   questions below carry other_value_ind_cd='T' on the relevant form
--   (verified live in NBS_ODSE nbs_ui_metadata join nbs_rdb_metadata,
--   rdb_table_nm='D_INVESTIGATION_REPEAT', question_group_seq_nbr NOT
--   NULL).
--
-- WHY answer_group_seq_nbr = 5 (DISTINGUISHING-GUARD rule, LESSON L10/L11):
--   The dim rows key on (PAGE_CASE_UID, BLOCK_NM, ANSWER_GROUP_SEQ_NBR).
--   Adding a NEW repeating group creates ADDITIONAL dim rows carrying the
--   _OTH free-text without touching existing rows. Group 1/2/3 are the
--   pre-existing *_fill answers; group 4 is fixture #1's reserved seam
--   (it answers 22047000/22047500/22049500/22060000/22060600/22007000 at
--   group 4). Group 5 is UNUSED on every PHC here (max existing group = 4
--   on 22007000/22049500, =3 elsewhere — verified live), so group 5 is a
--   clean DISTINGUISHING guard: each block's idempotency guard matches
--   ONLY its own rows via (act_uid, first parent q, group=5) and never
--   collides with #1's group-4 flood or the auto-IDENTITY page-answer
--   flood at group 0. nbs_case_answer is IDENTITY -> we LET IT AUTO-ASSIGN
--   (no IDENTITY_INSERT; L10) and guard on the natural key.
--
-- TARGET FORMS / EXISTING PHCs (all already in merge_and_verify.sh
-- $PHC_UIDS; all page-builder forms NOT in routine 010's line-91 legacy
-- INV_FORM_* exclusion list; all carry the named repeating block live):
--   22003000  PG_COVID-19_v1.1         (cond 11065)  block LAB_INTERPRETIVE
--   22047000  PG_TB_LTBI_Investigation (cond 502582) block MOLE_DRG_SUSCEP
--   22049000  PG_STEC_Investigation    (cond 115631) block LAB_BLOCK
--   22004000  PG_STD/HIV (page-builder)              block BLOCK_14
--   22007000  PG_Pertussis_Investigation(cond 10190) block BLOCK_8
--   (22004000/22007000 BLOCK_8/BLOCK_14 currently carry only the group-0
--    single projection; a group-5 repeating answer creates a fresh
--    repeating dim row — the OTH branch pivots any non-NULL group.)
--
-- VALUE FIDELITY: each parent CODED question is answered 'OTH^<text>'
--   (the only value that populates the _OTH column). One realistic
--   free-text per parent. The OTH branch emits its own row, so companion
--   answers in the same block at group 5 are NOT required — minimal.
--
-- UID block reserved 22068000-22068999 (catalog/uid_ranges.md): UNUSED
--   here by design — nbs_case_answer surrogate UID is auto-IDENTITY
--   (L10), and the pipeline keys page answers on
--   (act_uid, nbs_question_uid, seq/group), so no hardcoded UID is needed
--   or consumed. The block remains reserved/available.
--
-- Foundation deps (read-only): superuser 10009282.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @su bigint   = 10009282;
DECLARE @t  datetime = '2026-06-04T00:00:00';

-- ===== 22003000 PG_COVID-19 — LAB_INTERPRETIVE block =====
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = 22003000 AND nbs_question_uid = 10001371 AND answer_group_seq_nbr = 5)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid],[add_time],[add_user_id],[answer_txt],
         [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
         [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
         [answer_group_seq_nbr])
    VALUES
        -- LAB_TEST_RESULT_OTH (q 10001371, LAB_INTERPRETIVE)
        (22003000,@t,@su,N'OTH^Presumptive positive',10001371,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,5),
        -- LAB_PERFORMING_LAB_TYP_OTH (q 10001374, LAB_INTERPRETIVE)
        (22003000,@t,@su,N'OTH^Point-of-care site',10001374,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,5),
        -- LAB_SPECIMEN_SOURCE_OTH (q 10002114, LAB_INTERPRETIVE)
        (22003000,@t,@su,N'OTH^Anterior nares (self-collected)',10002114,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,5);
END
GO

-- ===== 22047000 PG_TB_LTBI — MOLE_DRG_SUSCEP block =====
DECLARE @su bigint   = 10009282;
DECLARE @t  datetime = '2026-06-04T00:00:00';
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = 22047000 AND nbs_question_uid = 10012210 AND answer_group_seq_nbr = 5)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid],[add_time],[add_user_id],[answer_txt],
         [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
         [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
         [answer_group_seq_nbr])
    VALUES
        -- LAB_MOLE_SUSC_SPEC_TY_OTH (q 10012210, MOLE_DRG_SUSCEP)
        (22047000,@t,@su,N'OTH^Pleural fluid',10012210,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,5),
        -- LAB_MOLE_SUSC_TST_MTHD_OTH (q 10012215, MOLE_DRG_SUSCEP)
        (22047000,@t,@su,N'OTH^Whole-genome sequencing',10012215,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,5);
END
GO

-- ===== 22049000 PG_STEC — LAB_BLOCK block =====
DECLARE @su bigint   = 10009282;
DECLARE @t  datetime = '2026-06-04T00:00:00';
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = 22049000 AND nbs_question_uid = 10010294 AND answer_group_seq_nbr = 5)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid],[add_time],[add_user_id],[answer_txt],
         [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
         [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
         [answer_group_seq_nbr])
    VALUES
        -- LAB_TEST_METHOD_OTH (q 10010294, LAB_BLOCK)
        (22049000,@t,@su,N'OTH^Shiga toxin EIA',10010294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,5);
END
GO

-- ===== 22007000 PG_Pertussis — BLOCK_8 (suspected source) =====
DECLARE @su bigint   = 10009282;
DECLARE @t  datetime = '2026-06-04T00:00:00';
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = 22007000 AND nbs_question_uid = 10009214 AND answer_group_seq_nbr = 5)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid],[add_time],[add_user_id],[answer_txt],
         [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
         [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
         [answer_group_seq_nbr])
    VALUES
        -- EPI_SUSPECTED_SOURCE_R_OTH (q 10009214, BLOCK_8)
        (22007000,@t,@su,N'OTH^Household childcare provider',10009214,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,5);
END
GO

-- ===== 22004000 PG_STD/HIV — BLOCK_14 (AST collection site) =====
DECLARE @su bigint   = 10009282;
DECLARE @t  datetime = '2026-06-04T00:00:00';
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = 22004000 AND nbs_question_uid = 10002148 AND answer_group_seq_nbr = 5)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid],[add_time],[add_user_id],[answer_txt],
         [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
         [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
         [answer_group_seq_nbr])
    VALUES
        -- LAB_AST_COLLECTION_SIT_OTH (q 10002148, BLOCK_14)
        (22004000,@t,@su,N'OTH^Rectal swab',10002148,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,5);
END
GO

-- =====================================================================
-- Closing CDC re-trigger: bump last_chg_time on every affected PHC so
-- the real pipeline (CDC/Debezium -> kafka-connect -> reporting-
-- pipeline-service investigation event + page-builder) re-emits the
-- investigation and re-projects NRT_PAGE_CASE_ANSWER, after which the
-- orchestrator's Step-8.5 sp_sld_investigation_repeat_postprocessing
-- pivots these new group-5 OTH answers into the *_OTH columns.
-- (Per-investigation PHC rows — NOT shared dims.)
-- =====================================================================
UPDATE [dbo].[public_health_case]
   SET last_chg_time = GETDATE()
 WHERE public_health_case_uid IN
       (22003000, 22047000, 22049000, 22007000, 22004000);
GO
