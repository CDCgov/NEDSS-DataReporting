-- =====================================================================
-- Round 6 (NO-SHORTCUT, NON-OBS-HEAVY) — D_INVESTIGATION_REPEAT
-- "other-value" (_OTH) column fill on EXISTING page-builder PHCs
-- =====================================================================
-- Branch: aw/remove-nrt-shortcut. This fixture authors ONLY NBS_ODSE
-- nbs_case_answer rows (+ a closing last_chg_time CDC re-trigger bump on
-- the affected public_health_case rows). It adds NO observations
-- (no observation/observation_reason/act-of-class-OBS, no lab/result
-- chains) — bug #20 obs fail-fast makes obs-heavy fixtures corrupt
-- lower-priority coverage, so this round is investigation/answer-only.
-- NO nrt_* INSERTs, NO EXEC sp_*, NO liquibase/seed/SRTE edits.
--
-- TARGET TABLE
--   dbo.D_INVESTIGATION_REPEAT (RDB_MODERN). This fixture targets the
--   still-NULL "_OTH" (other-value free-text) columns:
--     CLN_CHEST_STDY_TYPE_OTH, CLN_MAL_PREVIOUS_SPECI_OTH,
--     CMP_ADVERSE_EVENT_OTH, CMP_COMPLICATION_OTH,
--     EPI_PSN_ORG_TKNG_CO_RE_OTH, LAB_AST_SPECIMEN_TYPE_OTH,
--     LAB_AST_TEST_METHOD_OTH, LAB_AST_TEST_TYPE_OTH,
--     LAB_GENE_IDENTIFIER_OTH, LAB_ORGANISM_NAME_OTH,
--     LAB_PERFORMING_LAB_TYP_OTH, LAB_SPECIMEN_TYPE_OTH,
--     LAB_STRAIN_TYPE_OTH, LAB_SUSPECT_MEAT_TESTE_OTH,
--     LAB_TEST_METHOD_OTH, LAB_TEST_TYPE_OTH,
--     RSK_COOKING_METHOD_OTH, RSK_MEAT_PREPARATION_OTH,
--     RSK_SUSPECT_MEAT_TYPE_OTH, RSK_WHERE_MEAT_OBTAINE_OTH,
--     SYM_SIGNSSYMPTOMS_OTH, TRT_DRG_USD_TRT_MDR_TB_OTH,
--     TRT_MALARIA_INFO_OTH, TRT_MEDICATION_ADMINIS_OTH,
--     TRV_INTL_DESTINATIONS_OTH, TRV_VHF_TRAVEL_REASON_OTH.
--
-- HOW _OTH COLUMNS POPULATE (routine 010
-- sp_sld_investigation_repeat_postprocessing, the same SP the
-- orchestrator runs at Step 8.5 over $PHC_UIDS):
--   The CODED branch builds #CODED_TABLE_OTH_REPT from rows whose
--   metadata OTHER_VALUE_IND_CD='T' (SP lines 396-421). For such a
--   question, an answer of the form 'OTH^<free text>' yields:
--     ANSWER_OTH      = <free text>          (split on '^')
--     RDB_COLUMN_NM   = <col-first-22-chars> + '_OTH'
--     ANSWER_DESC11   = ANSWER_OTH
--   which then pivots into the <PARENT>_OTH column. The 26 parent
--   questions below ALL carry other_value_ind_cd='T' on their form
--   (verified live in NBS_ODSE nbs_ui_metadata join nbs_rdb_metadata,
--   rdb_table_nm='D_INVESTIGATION_REPEAT', question_group_seq_nbr NOT
--   NULL). Their group-1/2/3 answers (authored by zz_d_inv_repeat_fill
--   / fill2) used plain codes, so the _OTH columns stayed NULL.
--
-- WHY answer_group_seq_nbr = 4 (DISTINGUISHING-GUARD rule, LESSON
-- L10/L11):
--   Each target PHC already has these parent questions answered at
--   answer_group_seq_nbr 1/2/3 (zz_d_inv_repeat_fill*, auto-IDENTITY).
--   The dim rows key on (PAGE_CASE_UID, BLOCK_NM, ANSWER_GROUP_SEQ_NBR),
--   so adding a NEW repeating group (answer_group_seq_nbr = 4) creates
--   ADDITIONAL dim rows that carry the _OTH free-text — without touching
--   the existing 1/2/3 rows. answer_group_seq_nbr=4 is unused on every
--   target PHC (max existing group = 3, verified live), so it is also a
--   clean DISTINGUISHING guard: this fixture's idempotency guard matches
--   ONLY its own rows via (act_uid, nbs_question_uid, group=4) and never
--   collides with the earlier auto-IDENTITY page-answer flood.
--   nbs_case_answer is IDENTITY -> we LET IT AUTO-ASSIGN (no
--   IDENTITY_INSERT; L10) and guard on the natural key.
--
-- TARGET FORMS / EXISTING PHCs (all already in merge_and_verify.sh
-- $PHC_UIDS, so Step-8.5 sp_sld_investigation_repeat_postprocessing
-- already runs over them; all are page-builder forms NOT in routine
-- 010's line-91 legacy-form exclusion list):
--   22047000  PG_TB_LTBI_Investigation        (cond 502582)
--   22047500  PG_Trichinellosis_Investigation (cond 10270)
--   22049500  PG_Malaria_Investigation        (cond 10130)
--   22060000  PG_TBRD_Investigation           (cond 10250)
--   22060600  PG_Carbon_Monoxide_Investigation(cond 32016)
--   22007000  PG_Pertussis_Investigation      (cond 10190)
--
-- VALUE FIDELITY: each parent CODED question is answered 'OTH^<text>'
--   (the only value that populates the _OTH column). One realistic
--   free-text per parent. Companion answers in the same block at group 4
--   are NOT required for the _OTH pivot (the OTH branch emits its own
--   row), so this fixture stays minimal — one answer per parent.
--
-- UID block reserved 22064000-22064999 (catalog/uid_ranges.md): UNUSED
--   here by design — nbs_case_answer surrogate UID is auto-IDENTITY
--   (L10), and the pipeline keys page answers on
--   (act_uid, nbs_question_uid, seq/group), so no hardcoded UID is
--   needed or consumed. The block remains reserved/available.
--
-- Foundation deps (read-only): superuser 10009282.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @su bigint   = 10009282;
DECLARE @t  datetime = '2026-04-04T00:00:00';

-- ---------------------------------------------------------------------
-- (PHC, parent_q, OTH free-text) tuples. answer_group_seq_nbr=4, a
-- distinct seq_nbr per PHC. Guard each PHC's block on the natural key
-- (act_uid, first parent q, group=4) so the whole block is idempotent.
-- ---------------------------------------------------------------------

-- ===== 22047000 PG_TB_LTBI_Investigation =====
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = 22047000 AND nbs_question_uid = 10010264 AND answer_group_seq_nbr = 4)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid],[add_time],[add_user_id],[answer_txt],
         [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
         [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
         [answer_group_seq_nbr])
    VALUES
        -- CLN_CHEST_STDY_TYPE_OTH (q 10010264, CHEST_STUDY_INFO)
        (22047000,@t,@su,N'OTH^Low-dose chest CT',10010264,1,@t,@su,N'ACTIVE',@t,1,4),
        -- CMP_ADVERSE_EVENT_OTH (q 10012234, MDR_TB_SIDE_EFCT_TRT)
        (22047000,@t,@su,N'OTH^Peripheral neuropathy',10012234,1,@t,@su,N'ACTIVE',@t,2,4),
        -- TRT_DRG_USD_TRT_MDR_TB_OTH (q 10012229, MDR_TB_PREV_ADM_DRG)
        (22047000,@t,@su,N'OTH^Bedaquiline',10012229,1,@t,@su,N'ACTIVE',@t,3,4),
        -- LAB_AST_SPECIMEN_TYPE_OTH (q 10002147, PHENO_DRG_SUSC_TST)
        (22047000,@t,@su,N'OTH^Bronchoalveolar lavage',10002147,1,@t,@su,N'ACTIVE',@t,4,4),
        -- LAB_AST_TEST_METHOD_OTH (q 10002151, PHENO_DRG_SUSC_TST)
        (22047000,@t,@su,N'OTH^Agar proportion method',10002151,1,@t,@su,N'ACTIVE',@t,5,4),
        -- LAB_AST_TEST_TYPE_OTH (q 10002150, PHENO_DRG_SUSC_TST)
        (22047000,@t,@su,N'OTH^MIC determination',10002150,1,@t,@su,N'ACTIVE',@t,6,4),
        -- LAB_GENE_IDENTIFIER_OTH (q 10010295, MOLE_DRG_SUSCEP)
        (22047000,@t,@su,N'OTH^inhA promoter',10010295,1,@t,@su,N'ACTIVE',@t,7,4),
        -- LAB_TEST_TYPE_OTH (q 10001370, LAB_REPEATING)
        (22047000,@t,@su,N'OTH^Line probe assay',10001370,1,@t,@su,N'ACTIVE',@t,8,4);
END
GO

-- ===== 22047500 PG_Trichinellosis_Investigation =====
DECLARE @su bigint   = 10009282;
DECLARE @t  datetime = '2026-04-04T00:00:00';
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = 22047500 AND nbs_question_uid = 10009138 AND answer_group_seq_nbr = 4)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid],[add_time],[add_user_id],[answer_txt],
         [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
         [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
         [answer_group_seq_nbr])
    VALUES
        -- RSK_SUSPECT_MEAT_TYPE_OTH (q 10009138, FOOD_EXPOSURE_HIST)
        (22047500,@t,@su,N'OTH^Wild boar sausage',10009138,1,@t,@su,N'ACTIVE',@t,1,4),
        -- RSK_WHERE_MEAT_OBTAINE_OTH (q 10009141, FOOD_EXPOSURE_HIST)
        (22047500,@t,@su,N'OTH^Hunted (self-harvested)',10009141,1,@t,@su,N'ACTIVE',@t,2,4),
        -- RSK_MEAT_PREPARATION_OTH (q 10009142, FOOD_EXPOSURE_HIST)
        (22047500,@t,@su,N'OTH^Home-cured',10009142,1,@t,@su,N'ACTIVE',@t,3,4),
        -- RSK_COOKING_METHOD_OTH (q 10009143, FOOD_EXPOSURE_HIST)
        (22047500,@t,@su,N'OTH^Smoked',10009143,1,@t,@su,N'ACTIVE',@t,4,4),
        -- LAB_SUSPECT_MEAT_TESTE_OTH (q 10009145, FOOD_EXPOSURE_HIST)
        (22047500,@t,@su,N'OTH^Leftover frozen portion',10009145,1,@t,@su,N'ACTIVE',@t,5,4),
        -- LAB_STRAIN_TYPE_OTH (q 10009134, EPIDEMIOLOGY_LAB)
        (22047500,@t,@su,N'OTH^Trichinella murrelli',10009134,1,@t,@su,N'ACTIVE',@t,6,4);
END
GO

-- ===== 22049500 PG_Malaria_Investigation =====
DECLARE @su bigint   = 10009282;
DECLARE @t  datetime = '2026-04-04T00:00:00';
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = 22049500 AND nbs_question_uid = 10008150 AND answer_group_seq_nbr = 4)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid],[add_time],[add_user_id],[answer_txt],
         [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
         [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
         [answer_group_seq_nbr])
    VALUES
        -- CLN_MAL_PREVIOUS_SPECI_OTH (q 10008150, PREV_MALARIA_ILLNESS)
        (22049500,@t,@su,N'OTH^Plasmodium knowlesi',10008150,1,@t,@su,N'ACTIVE',@t,1,4),
        -- TRT_MALARIA_INFO_OTH (q 10008151, TREATMENT_THERAPY)
        (22049500,@t,@su,N'OTH^Tafenoquine',10008151,1,@t,@su,N'ACTIVE',@t,2,4),
        -- LAB_ORGANISM_NAME_OTH (q 10006163, LAB_INTERPRETATIVE)
        (22049500,@t,@su,N'OTH^Plasmodium ovale curtisi',10006163,1,@t,@su,N'ACTIVE',@t,3,4),
        -- TRV_INTL_DESTINATIONS_OTH (q 10004154, TRAVEL_HISTORY)
        (22049500,@t,@su,N'OTH^Papua New Guinea',10004154,1,@t,@su,N'ACTIVE',@t,4,4),
        -- TRV_VHF_TRAVEL_REASON_OTH (q 10001082, TRAVEL_HISTORY)
        (22049500,@t,@su,N'OTH^Missionary work',10001082,1,@t,@su,N'ACTIVE',@t,5,4);
END
GO

-- ===== 22060000 PG_TBRD_Investigation =====
DECLARE @su bigint   = 10009282;
DECLARE @t  datetime = '2026-04-04T00:00:00';
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = 22060000 AND nbs_question_uid = 10006163 AND answer_group_seq_nbr = 4)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid],[add_time],[add_user_id],[answer_txt],
         [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
         [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
         [answer_group_seq_nbr])
    VALUES
        -- LAB_ORGANISM_NAME_OTH (q 10006163, LAB_INTERPRETATIVE)
        (22060000,@t,@su,N'OTH^Rickettsia parkeri',10006163,1,@t,@su,N'ACTIVE',@t,1,4),
        -- LAB_SPECIMEN_TYPE_OTH (q 10001372, LAB_INTERPRETATIVE)
        (22060000,@t,@su,N'OTH^Eschar swab',10001372,1,@t,@su,N'ACTIVE',@t,2,4),
        -- LAB_TEST_TYPE_OTH (q 10001370, LAB_INTERPRETATIVE)
        (22060000,@t,@su,N'OTH^Immunohistochemistry',10001370,1,@t,@su,N'ACTIVE',@t,3,4),
        -- TRT_MEDICATION_ADMINIS_OTH (q 10006142, ANTIBIOTICS_INFO)
        (22060000,@t,@su,N'OTH^Chloramphenicol',10006142,1,@t,@su,N'ACTIVE',@t,4,4);
END
GO

-- ===== 22060600 PG_Carbon_Monoxide_Investigation =====
DECLARE @su bigint   = 10009282;
DECLARE @t  datetime = '2026-04-04T00:00:00';
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = 22060600 AND nbs_question_uid = 10011156 AND answer_group_seq_nbr = 4)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid],[add_time],[add_user_id],[answer_txt],
         [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
         [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
         [answer_group_seq_nbr])
    VALUES
        -- EPI_PSN_ORG_TKNG_CO_RE_OTH (q 10011156, CO_LEVEL)
        (22060600,@t,@su,N'OTH^On-scene fire marshal',10011156,1,@t,@su,N'ACTIVE',@t,1,4),
        -- TRT_MALARIA_INFO_OTH (q 10008151, TREATMENT) -- shared col name
        (22060600,@t,@su,N'OTH^Hyperbaric oxygen therapy',10008151,1,@t,@su,N'ACTIVE',@t,2,4);
END
GO

-- ===== 22007000 PG_Pertussis_Investigation =====
DECLARE @su bigint   = 10009282;
DECLARE @t  datetime = '2026-04-04T00:00:00';
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = 22007000 AND nbs_question_uid = 10006135 AND answer_group_seq_nbr = 4)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid],[add_time],[add_user_id],[answer_txt],
         [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
         [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
         [answer_group_seq_nbr])
    VALUES
        -- CMP_COMPLICATION_OTH (q 10006135, BLOCK_14)
        (22007000,@t,@su,N'OTH^Subconjunctival hemorrhage',10006135,1,@t,@su,N'ACTIVE',@t,1,4),
        -- SYM_SIGNSSYMPTOMS_OTH (q 10001312, BLOCK_13)
        (22007000,@t,@su,N'OTH^Post-tussive syncope',10001312,1,@t,@su,N'ACTIVE',@t,2,4);
END
GO

-- =====================================================================
-- Closing CDC re-trigger: bump last_chg_time on every affected PHC so
-- the real pipeline (CDC/Debezium -> kafka-connect -> reporting-
-- pipeline-service investigation event + page-builder) re-emits the
-- investigation and re-projects NRT_PAGE_CASE_ANSWER, after which the
-- orchestrator's Step-8.5 sp_sld_investigation_repeat_postprocessing
-- pivots these new group-4 OTH answers into the *_OTH columns.
-- (Per-investigation PHC rows — NOT shared dims.)
-- =====================================================================
UPDATE [dbo].[public_health_case]
   SET last_chg_time = GETDATE()
 WHERE public_health_case_uid IN
       (22047000, 22047500, 22049500, 22060000, 22060600, 22007000);
GO
