-- =====================================================================
-- Tier 3 - More BLOCK_NM x SEQ variants for D_INVESTIGATION_REPEAT
-- =====================================================================
-- Authored 2026-05-24 (second-round parallel agent H).
--
-- Goal: lift D_INVESTIGATION_REPEAT row count and populated column
-- count.  Existing state (pre-this-fixture):
--   * 8 dim rows (1 NULL-block sentinel + TRAVEL_BLOCK x 3 + EXPOSURE_BLOCK x 3)
--   * 256 total columns
--
-- KEY GOTCHA / ORCH_TODO discovered while authoring:
--   The TEXT pivot in sp_sld_investigation_repeat_postprocessing is
--   FRAGILE: the column-list builder at SP line 212 uses
--     SELECT @cols += N', p.' + QUOTENAME(RDB_COLUMN_NM) FROM ... GROUP BY RDB_COLUMN_NM
--   If ANY row in #text_data_REPT has a NULL rdb_column_nm, @cols
--   becomes NULL via SQL Server's NULL-propagation in row-by-row
--   string concatenation, the dynamic pivot SQL becomes NULL, and
--   the EXEC silently no-ops -- ZERO TEXT columns get populated for
--   the entire PHC.
--
--   The agent-D2 fixture (zz_d_inv_place_repeat_enrich.sql, UID block
--   22010xxx) authors nrt_page_case_answer rows on PHC 22006000 with
--   data_type='TEXT' AND rdb_column_nm=NULL (intentional -- those
--   rows target the *different* SP sp_repeated_place_postprocessing
--   via part_type_cd).  Those rows live in the same table the
--   investigation_repeat SP scans, so the TEXT pivot for PHC 22006000
--   silently fails whenever the D2 fixture is loaded.
--
--   ORCH_TODO bug: sp_sld_investigation_repeat_postprocessing should
--   filter out rows with NULL rdb_column_nm before building the pivot
--   column list (or COALESCE @cols to '' / use the FOR XML PATH idiom).
--
--   WORKAROUND adopted by this fixture: emphasise DATE, NUMERIC, and
--   CODED rows for every new BLOCK_NM x ANSWER_GROUP_SEQ_NBR combo.
--   Those pivots are unaffected by the D2 pollution.  TEXT rows are
--   still authored (they'd populate cols once the bug is fixed) but
--   we DO NOT rely on them for dim-row materialization.
--
-- This fixture adds 5 new BLOCK_NM values, each with 3
-- ANSWER_GROUP_SEQ_NBR values, expecting 15 new dim rows on top of
-- the existing 8.  Each new (block, seq) has at least one DATE,
-- NUMERIC, and CODED row (so the dim row materializes regardless of
-- TEXT pivot status) PLUS several TEXT rows targeting baseline
-- columns (which will populate once bug is fixed).
--
-- UID block: 22014000 - 22014999 (reserved in catalog/uid_ranges.md
-- row 1240).
-- Sort prefix: zz_ -- runs AFTER d_investigation_repeat.sql and
-- zz_d_investigation_repeat_extra_cols.sql.
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- Idempotency guard: skip the INSERT if any of our authored
-- nbs_case_answer_uids are already present (re-run safety).
-- ---------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM dbo.nrt_page_case_answer
    WHERE nbs_case_answer_uid BETWEEN 22014000 AND 22014999
)
BEGIN

INSERT INTO [dbo].[nrt_page_case_answer]
    ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid],
     [nbs_question_uid],
     [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr],
     [investigation_form_cd], [question_identifier], [data_location],
     [code_set_group_id], [last_chg_time], [record_status_cd],
     [datamart_column_nm], [ldf_status_cd], [seq_nbr], [batch_id],
     [data_type], [question_group_seq_nbr], [block_nm],
     [unit_value], [unit_type_cd])
VALUES
    -- =================================================================
    -- BLOCK 1: LAB_BLOCK (3 seqs)
    -- DATE-heavy: targets LAB_*_DT baseline cols
    -- =================================================================
    -- ----- seq 1 -----
    (22006000, 22014000, 1, 22014001, N'D_INVESTIGATION_REPEAT', N'LAB_RESULT_DT',
     N'04/05/26', 1, N'PG_Pertussis_Investigation', N'INVH001',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_RESULT_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014001, 1, 22014002, N'D_INVESTIGATION_REPEAT', N'LAB_SPECIMEN_COLLECT_DT',
     N'04/01/26', 1, N'PG_Pertussis_Investigation', N'INVH002',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_SPECIMEN_COLLECT_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014002, 1, 22014003, N'D_INVESTIGATION_REPEAT', N'LAB_SAMPLE_ANALYZD_DT',
     N'04/03/26', 1, N'PG_Pertussis_Investigation', N'INVH003',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_SAMPLE_ANALYZD_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014003, 1, 22014004, N'D_INVESTIGATION_REPEAT', N'LAB_AST_SPEC_COLLECT_DT',
     N'04/02/26', 1, N'PG_Pertussis_Investigation', N'INVH004',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_AST_SPEC_COLLECT_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014004, 1, 22014005, N'D_INVESTIGATION_REPEAT', N'LAB_SPEC_SENT_TO_SPHL_DT',
     N'04/04/26', 1, N'PG_Pertussis_Investigation', N'INVH005',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_SPEC_SENT_TO_SPHL_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),

    -- ----- seq 2 -----
    (22006000, 22014010, 1, 22014011, N'D_INVESTIGATION_REPEAT', N'LAB_RESULT_DT',
     N'04/15/26', 2, N'PG_Pertussis_Investigation', N'INVH001',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_RESULT_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014011, 1, 22014012, N'D_INVESTIGATION_REPEAT', N'LAB_SPECIMEN_ANALYZED_DT',
     N'04/14/26', 2, N'PG_Pertussis_Investigation', N'INVH012',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_SPECIMEN_ANALYZED_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014012, 1, 22014013, N'D_INVESTIGATION_REPEAT', N'LAB_SPECIMEN_COLLECTION_DT',
     N'04/13/26', 2, N'PG_Pertussis_Investigation', N'INVH013',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_SPECIMEN_COLLECTION_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014013, 1, 22014014, N'D_INVESTIGATION_REPEAT', N'LAB_SPECIMEN_SENT_TO_CDC_DT',
     N'04/16/26', 2, N'PG_Pertussis_Investigation', N'INVH014',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_SPECIMEN_SENT_TO_CDC_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014014, 1, 22014015, N'D_INVESTIGATION_REPEAT', N'LAB_ANTI_MIC_SUSC_RSLT_DT',
     N'04/17/26', 2, N'PG_Pertussis_Investigation', N'INVH015',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_ANTI_MIC_SUSC_RSLT_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014015, 1, 22014016, N'D_INVESTIGATION_REPEAT', N'LAB_SPECIMEN_TEST_DATE',
     N'04/14/26', 2, N'PG_Pertussis_Investigation', N'INVH016',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_SPECIMEN_TEST_DATE', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),

    -- ----- seq 3 -----
    (22006000, 22014020, 1, 22014021, N'D_INVESTIGATION_REPEAT', N'LAB_RESULT_DT',
     N'04/25/26', 3, N'PG_Pertussis_Investigation', N'INVH001',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_RESULT_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014021, 1, 22014022, N'D_INVESTIGATION_REPEAT', N'LAB_MOLE_SUSC_REPRTD_DT',
     N'04/26/26', 3, N'PG_Pertussis_Investigation', N'INVH022',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_MOLE_SUSC_REPRTD_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014022, 1, 22014023, N'D_INVESTIGATION_REPEAT', N'LAB_MOLE_SUSC_SPC_COLC_DT',
     N'04/22/26', 3, N'PG_Pertussis_Investigation', N'INVH023',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-05T00:00:00', N'ACTIVE', N'LAB_MOLE_SUSC_SPC_COLC_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),

    -- =================================================================
    -- BLOCK 2: TRT_BLOCK (3 seqs)
    -- =================================================================
    -- ----- seq 1 -----
    (22006000, 22014100, 1, 22014031, N'D_INVESTIGATION_REPEAT', N'TRT_MEDICATION_START_DT',
     N'04/10/26', 1, N'PG_Pertussis_Investigation', N'INVH031',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-10T00:00:00', N'ACTIVE', N'TRT_MEDICATION_START_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014101, 1, 22014032, N'D_INVESTIGATION_REPEAT', N'TRT_MEDICATION_STOP_DATE',
     N'04/24/26', 1, N'PG_Pertussis_Investigation', N'INVH032',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-10T00:00:00', N'ACTIVE', N'TRT_MEDICATION_STOP_DATE', NULL, 1, NULL,
     N'DATE', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014102, 1, 22014033, N'D_INVESTIGATION_REPEAT', N'TRT_TREATMENT_START_DT',
     N'04/10/26', 1, N'PG_Pertussis_Investigation', N'INVH033',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-10T00:00:00', N'ACTIVE', N'TRT_TREATMENT_START_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014103, 1, 22014034, N'D_INVESTIGATION_REPEAT', N'TRT_TREATMENT_END_DT',
     N'04/24/26', 1, N'PG_Pertussis_Investigation', N'INVH034',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-10T00:00:00', N'ACTIVE', N'TRT_TREATMENT_END_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014104, 1, 22014035, N'D_INVESTIGATION_REPEAT', N'TRT_TREATMENT_RX_DT',
     N'04/09/26', 1, N'PG_Pertussis_Investigation', N'INVH035',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-10T00:00:00', N'ACTIVE', N'TRT_TREATMENT_RX_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRT_BLOCK', NULL, N'LITERAL'),

    -- ----- seq 2 -----
    (22006000, 22014110, 1, 22014041, N'D_INVESTIGATION_REPEAT', N'TRT_MEDICATION_START_DT',
     N'04/12/26', 2, N'PG_Pertussis_Investigation', N'INVH031',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-10T00:00:00', N'ACTIVE', N'TRT_MEDICATION_START_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014111, 1, 22014042, N'D_INVESTIGATION_REPEAT', N'TRT_TREATMENT_START_DT',
     N'04/12/26', 2, N'PG_Pertussis_Investigation', N'INVH033',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-10T00:00:00', N'ACTIVE', N'TRT_TREATMENT_START_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRT_BLOCK', NULL, N'LITERAL'),

    -- ----- seq 3 -----
    (22006000, 22014120, 1, 22014051, N'D_INVESTIGATION_REPEAT', N'TRT_TREATMENT_END_DT',
     N'05/01/26', 3, N'PG_Pertussis_Investigation', N'INVH034',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-10T00:00:00', N'ACTIVE', N'TRT_TREATMENT_END_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014121, 1, 22014052, N'D_INVESTIGATION_REPEAT', N'TRT_MEDICATION_STOP_DATE',
     N'05/01/26', 3, N'PG_Pertussis_Investigation', N'INVH032',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-10T00:00:00', N'ACTIVE', N'TRT_MEDICATION_STOP_DATE', NULL, 1, NULL,
     N'DATE', 1, N'TRT_BLOCK', NULL, N'LITERAL'),

    -- =================================================================
    -- BLOCK 3: RSK_BLOCK (3 seqs)
    -- =================================================================
    -- ----- seq 1 -----
    (22006000, 22014200, 1, 22014061, N'D_INVESTIGATION_REPEAT', N'RSK_CONSUMED_DT',
     N'03/20/26', 1, N'PG_Pertussis_Investigation', N'INVH061',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-25T00:00:00', N'ACTIVE', N'RSK_CONSUMED_DT', NULL, 1, NULL,
     N'DATE', 1, N'RSK_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014201, 1, 22014062, N'D_INVESTIGATION_REPEAT', N'RSK_DT_OF_BLD_TRANSFUSION',
     N'01/05/26', 1, N'PG_Pertussis_Investigation', N'INVH062',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-25T00:00:00', N'ACTIVE', N'RSK_DT_OF_BLD_TRANSFUSION', NULL, 1, NULL,
     N'DATE', 1, N'RSK_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014202, 1, 22014063, N'D_INVESTIGATION_REPEAT', N'RSK_TICK_BITE_DT',
     N'03/01/26', 1, N'PG_Pertussis_Investigation', N'INVH063',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-25T00:00:00', N'ACTIVE', N'RSK_TICK_BITE_DT', NULL, 1, NULL,
     N'DATE', 1, N'RSK_BLOCK', NULL, N'LITERAL'),

    -- ----- seq 2 -----
    (22006000, 22014210, 1, 22014071, N'D_INVESTIGATION_REPEAT', N'RSK_CONSUMED_DT',
     N'03/22/26', 2, N'PG_Pertussis_Investigation', N'INVH061',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-25T00:00:00', N'ACTIVE', N'RSK_CONSUMED_DT', NULL, 1, NULL,
     N'DATE', 1, N'RSK_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014211, 1, 22014072, N'D_INVESTIGATION_REPEAT', N'RSK_TICK_BITE_DT',
     N'03/05/26', 2, N'PG_Pertussis_Investigation', N'INVH063',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-25T00:00:00', N'ACTIVE', N'RSK_TICK_BITE_DT', NULL, 1, NULL,
     N'DATE', 1, N'RSK_BLOCK', NULL, N'LITERAL'),

    -- ----- seq 3 -----
    (22006000, 22014220, 1, 22014081, N'D_INVESTIGATION_REPEAT', N'RSK_DT_OF_BLD_TRANSFUSION',
     N'01/15/26', 3, N'PG_Pertussis_Investigation', N'INVH062',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-25T00:00:00', N'ACTIVE', N'RSK_DT_OF_BLD_TRANSFUSION', NULL, 1, NULL,
     N'DATE', 1, N'RSK_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014221, 1, 22014082, N'D_INVESTIGATION_REPEAT', N'RSK_CONSUMED_DT',
     N'03/15/26', 3, N'PG_Pertussis_Investigation', N'INVH061',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-25T00:00:00', N'ACTIVE', N'RSK_CONSUMED_DT', NULL, 1, NULL,
     N'DATE', 1, N'RSK_BLOCK', NULL, N'LITERAL'),

    -- =================================================================
    -- BLOCK 4: SYM_BLOCK (3 seqs) - SYM + TRV + MDH date cols
    -- =================================================================
    -- ----- seq 1 -----
    (22006000, 22014300, 1, 22014091, N'D_INVESTIGATION_REPEAT', N'SYM_SIGN_SX_OBVTN_ONSET_DT',
     N'03/25/26', 1, N'PG_Pertussis_Investigation', N'INVH091',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-30T00:00:00', N'ACTIVE', N'SYM_SIGN_SX_OBVTN_ONSET_DT', NULL, 1, NULL,
     N'DATE', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014301, 1, 22014092, N'D_INVESTIGATION_REPEAT', N'TRV_DEPART_TRVL_DEST_DT',
     N'03/10/26', 1, N'PG_Pertussis_Investigation', N'INVH092',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-30T00:00:00', N'ACTIVE', N'TRV_DEPART_TRVL_DEST_DT', NULL, 1, NULL,
     N'DATE', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014302, 1, 22014093, N'D_INVESTIGATION_REPEAT', N'TRV_ARRIVAL_TRVL_DEST_DT',
     N'03/12/26', 1, N'PG_Pertussis_Investigation', N'INVH093',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-30T00:00:00', N'ACTIVE', N'TRV_ARRIVAL_TRVL_DEST_DT', NULL, 1, NULL,
     N'DATE', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014303, 1, 22014094, N'D_INVESTIGATION_REPEAT', N'TRV_TRAVEL_RETURN_DT',
     N'03/18/26', 1, N'PG_Pertussis_Investigation', N'INVH094',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-30T00:00:00', N'ACTIVE', N'TRV_TRAVEL_RETURN_DT', NULL, 1, NULL,
     N'DATE', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014304, 1, 22014095, N'D_INVESTIGATION_REPEAT', N'MDH_HX_DIAGNOSIS_DT',
     N'01/15/24', 1, N'PG_Pertussis_Investigation', N'INVH095',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-30T00:00:00', N'ACTIVE', N'MDH_HX_DIAGNOSIS_DT', NULL, 1, NULL,
     N'DATE', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014305, 1, 22014096, N'D_INVESTIGATION_REPEAT', N'MDH_HX_TREATMENT_DT',
     N'01/20/24', 1, N'PG_Pertussis_Investigation', N'INVH096',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-30T00:00:00', N'ACTIVE', N'MDH_HX_TREATMENT_DT', NULL, 1, NULL,
     N'DATE', 1, N'SYM_BLOCK', NULL, N'LITERAL'),

    -- ----- seq 2 -----
    (22006000, 22014310, 1, 22014101, N'D_INVESTIGATION_REPEAT', N'SYM_SIGN_SX_OBVTN_ONSET_DT',
     N'04/05/26', 2, N'PG_Pertussis_Investigation', N'INVH091',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-30T00:00:00', N'ACTIVE', N'SYM_SIGN_SX_OBVTN_ONSET_DT', NULL, 1, NULL,
     N'DATE', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014311, 1, 22014102, N'D_INVESTIGATION_REPEAT', N'CLN_PREVIOUS_ILLNESS_DT',
     N'02/15/26', 2, N'PG_Pertussis_Investigation', N'INVH102',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-30T00:00:00', N'ACTIVE', N'CLN_PREVIOUS_ILLNESS_DT', NULL, 1, NULL,
     N'DATE', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014312, 1, 22014103, N'D_INVESTIGATION_REPEAT', N'CLN_CHEST_STUDY_DT',
     N'03/28/26', 2, N'PG_Pertussis_Investigation', N'INVH103',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-30T00:00:00', N'ACTIVE', N'CLN_CHEST_STUDY_DT', NULL, 1, NULL,
     N'DATE', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014313, 1, 22014104, N'D_INVESTIGATION_REPEAT', N'ADM_ADV_EVE_MNFSTN_DT',
     N'03/29/26', 2, N'PG_Pertussis_Investigation', N'INVH104',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-30T00:00:00', N'ACTIVE', N'ADM_ADV_EVE_MNFSTN_DT', NULL, 1, NULL,
     N'DATE', 1, N'SYM_BLOCK', NULL, N'LITERAL'),

    -- ----- seq 3 -----
    (22006000, 22014320, 1, 22014111, N'D_INVESTIGATION_REPEAT', N'SYM_SIGN_SX_OBVTN_ONSET_DT',
     N'04/12/26', 3, N'PG_Pertussis_Investigation', N'INVH091',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-30T00:00:00', N'ACTIVE', N'SYM_SIGN_SX_OBVTN_ONSET_DT', NULL, 1, NULL,
     N'DATE', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014321, 1, 22014112, N'D_INVESTIGATION_REPEAT', N'SUS_REPORT_DT',
     N'04/15/26', 3, N'PG_Pertussis_Investigation', N'INVH112',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-03-30T00:00:00', N'ACTIVE', N'SUS_REPORT_DT', NULL, 1, NULL,
     N'DATE', 1, N'SYM_BLOCK', NULL, N'LITERAL'),

    -- =================================================================
    -- BLOCK 5: VAC_BLOCK (3 seqs)
    -- VAC_VACCINATIONDATE + NUMERIC VAC_VACCINEDOSENUM + CODED MDH
    -- =================================================================
    -- ----- seq 1: dates + numeric + coded =====
    (22006000, 22014400, 1, 22014121, N'D_INVESTIGATION_REPEAT', N'VAC_VACCINATIONDATE',
     N'02/01/24', 1, N'PG_Pertussis_Investigation', N'INVH121',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'VAC_VACCINATIONDATE', NULL, 1, NULL,
     N'DATE', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014401, 1, 22014122, N'D_INVESTIGATION_REPEAT', N'VAC_VACCINEDOSENUM',
     N'1', 1, N'PG_Pertussis_Investigation', N'INVH122',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'VAC_VACCINEDOSENUM', NULL, 1, NULL,
     N'NUMERIC', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014402, 1, 22014123, N'D_INVESTIGATION_REPEAT', N'SYM_SIGN_SX_DURATION_IN_DAYS',
     N'14', 1, N'PG_Pertussis_Investigation', N'INVH123',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'SYM_SIGN_SX_DURATION_IN_DAYS', NULL, 1, NULL,
     N'NUMERIC', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    -- CODED: MDH_HX_CONFIRMED_IND uses 'Y' from YNU codeset (4150)
    (22006000, 22014403, 1, 22014124, N'D_INVESTIGATION_REPEAT', N'MDH_HX_CONFIRMED_IND',
     N'Y', 1, N'PG_Pertussis_Investigation', N'INVH124',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'MDH_HX_CONFIRMED_IND', NULL, 1, NULL,
     N'CODED', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014404, 1, 22014125, N'D_INVESTIGATION_REPEAT', N'CMP_COMPLICATION_IND',
     N'N', 1, N'PG_Pertussis_Investigation', N'INVH125',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'CMP_COMPLICATION_IND', NULL, 1, NULL,
     N'CODED', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014405, 1, 22014126, N'D_INVESTIGATION_REPEAT', N'ADM_ADV_EVE_IND',
     N'N', 1, N'PG_Pertussis_Investigation', N'INVH126',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'ADM_ADV_EVE_IND', NULL, 1, NULL,
     N'CODED', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014406, 1, 22014127, N'D_INVESTIGATION_REPEAT', N'LAB_SPECIMEN_SENT_TO_CDC_IND',
     N'Y', 1, N'PG_Pertussis_Investigation', N'INVH127',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_SPECIMEN_SENT_TO_CDC_IND', NULL, 1, NULL,
     N'CODED', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014407, 1, 22014128, N'D_INVESTIGATION_REPEAT', N'SYM_SIGN_SYMPTOM_IND',
     N'Y', 1, N'PG_Pertussis_Investigation', N'INVH128',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'SYM_SIGN_SYMPTOM_IND', NULL, 1, NULL,
     N'CODED', 1, N'VAC_BLOCK', NULL, N'LITERAL'),

    -- ----- seq 2 -----
    (22006000, 22014410, 1, 22014131, N'D_INVESTIGATION_REPEAT', N'VAC_VACCINATIONDATE',
     N'04/01/24', 2, N'PG_Pertussis_Investigation', N'INVH121',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'VAC_VACCINATIONDATE', NULL, 1, NULL,
     N'DATE', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014411, 1, 22014132, N'D_INVESTIGATION_REPEAT', N'VAC_VACCINEDOSENUM',
     N'2', 2, N'PG_Pertussis_Investigation', N'INVH122',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'VAC_VACCINEDOSENUM', NULL, 1, NULL,
     N'NUMERIC', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014412, 1, 22014133, N'D_INVESTIGATION_REPEAT', N'MDH_HX_CONFIRMED_IND',
     N'N', 2, N'PG_Pertussis_Investigation', N'INVH124',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'MDH_HX_CONFIRMED_IND', NULL, 1, NULL,
     N'CODED', 1, N'VAC_BLOCK', NULL, N'LITERAL'),

    -- ----- seq 3 -----
    (22006000, 22014420, 1, 22014141, N'D_INVESTIGATION_REPEAT', N'VAC_VACCINATIONDATE',
     N'06/01/24', 3, N'PG_Pertussis_Investigation', N'INVH121',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'VAC_VACCINATIONDATE', NULL, 1, NULL,
     N'DATE', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014421, 1, 22014142, N'D_INVESTIGATION_REPEAT', N'VAC_VACCINEDOSENUM',
     N'3', 3, N'PG_Pertussis_Investigation', N'INVH122',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'VAC_VACCINEDOSENUM', NULL, 1, NULL,
     N'NUMERIC', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014422, 1, 22014143, N'D_INVESTIGATION_REPEAT', N'CMP_COMPLICATION_IND',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INVH125',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'CMP_COMPLICATION_IND', NULL, 1, NULL,
     N'CODED', 1, N'VAC_BLOCK', NULL, N'LITERAL'),

    -- =================================================================
    -- Extra CODED cols on existing TRAVEL_BLOCK / EXPOSURE_BLOCK rows
    -- (these will populate the existing dim rows -- no new rows added,
    -- but +cols).
    -- =================================================================
    (22006000, 22014500, 1, 22014151, N'D_INVESTIGATION_REPEAT', N'CLN_ADMITTED_AS_INPATIENT',
     N'U', 1, N'PG_Pertussis_Investigation', N'INVH151',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'CLN_ADMITTED_AS_INPATIENT', NULL, 1, NULL,
     N'CODED', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014501, 1, 22014152, N'D_INVESTIGATION_REPEAT', N'LAB_INTERP_FLAG',
     N'Y', 1, N'PG_Pertussis_Investigation', N'INVH152',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_INTERP_FLAG', NULL, 1, NULL,
     N'CODED', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014502, 1, 22014153, N'D_INVESTIGATION_REPEAT', N'SUS_INTERP_FLAG',
     N'Y', 1, N'PG_Pertussis_Investigation', N'INVH153',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'SUS_INTERP_FLAG', NULL, 1, NULL,
     N'CODED', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014503, 1, 22014154, N'D_INVESTIGATION_REPEAT', N'TRT_CMPLT_TRT_PREV_DIAG',
     N'N', 1, N'PG_Pertussis_Investigation', N'INVH154',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'TRT_CMPLT_TRT_PREV_DIAG', NULL, 1, NULL,
     N'CODED', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    -- NUMERIC extras on existing rows
    (22006000, 22014504, 1, 22014155, N'D_INVESTIGATION_REPEAT', N'LAB_PARASITEMIA_LVL_PCT',
     N'0', 1, N'PG_Pertussis_Investigation', N'INVH155',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_PARASITEMIA_LVL_PCT', NULL, 1, NULL,
     N'NUMERIC', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014505, 1, 22014156, N'D_INVESTIGATION_REPEAT', N'LAB_RESULT_NUM_VAL',
     N'42', 1, N'PG_Pertussis_Investigation', N'INVH156',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_RESULT_NUM_VAL', NULL, 1, NULL,
     N'NUMERIC', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014506, 1, 22014157, N'D_INVESTIGATION_REPEAT', N'SUS_RESULT_NUM_VAL',
     N'42', 1, N'PG_Pertussis_Investigation', N'INVH157',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'SUS_RESULT_NUM_VAL', NULL, 1, NULL,
     N'NUMERIC', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    -- More DATEs on existing rows (TRAVEL seq 1)
    (22006000, 22014507, 1, 22014158, N'D_INVESTIGATION_REPEAT', N'LAB_RESULT_DT',
     N'03/16/26', 1, N'PG_Pertussis_Investigation', N'INVH158',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_RESULT_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014508, 1, 22014159, N'D_INVESTIGATION_REPEAT', N'TRT_TREATMENT_START_DT',
     N'03/17/26', 1, N'PG_Pertussis_Investigation', N'INVH159',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'TRT_TREATMENT_START_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014509, 1, 22014160, N'D_INVESTIGATION_REPEAT', N'MDH_HX_DIAGNOSIS_DT',
     N'01/01/24', 1, N'PG_Pertussis_Investigation', N'INVH160',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'MDH_HX_DIAGNOSIS_DT', NULL, 1, NULL,
     N'DATE', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),

    -- =================================================================
    -- Round 2: More CODED rows across various blocks to populate
    -- unfilled baseline IND/coded cols. All use YNU codeset (4150).
    -- Each row hits a different (block, seq) so cols spread across rows.
    -- =================================================================
    -- LAB_BLOCK seq 1: CODED cols
    (22006000, 22014600, 1, 22014201, N'D_INVESTIGATION_REPEAT', N'LAB_TEST_STATUS',
     N'Y', 1, N'PG_Pertussis_Investigation', N'INVH201',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TEST_STATUS', NULL, 1, NULL,
     N'CODED', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014601, 1, 22014202, N'D_INVESTIGATION_REPEAT', N'SUS_TEST_STATUS',
     N'Y', 1, N'PG_Pertussis_Investigation', N'INVH202',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'SUS_TEST_STATUS', NULL, 1, NULL,
     N'CODED', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014602, 1, 22014203, N'D_INVESTIGATION_REPEAT', N'ELECTRONIC_IND',
     N'Y', 1, N'PG_Pertussis_Investigation', N'INVH203',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'ELECTRONIC_IND', NULL, 1, NULL,
     N'CODED', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014603, 1, 22014204, N'D_INVESTIGATION_REPEAT', N'ELECTRONIC_IND2',
     N'N', 1, N'PG_Pertussis_Investigation', N'INVH204',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'ELECTRONIC_IND2', NULL, 1, NULL,
     N'CODED', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    -- LAB_BLOCK seq 2
    (22006000, 22014610, 1, 22014211, N'D_INVESTIGATION_REPEAT', N'CLN_DIAGNOSIS_TYPE',
     N'Y', 2, N'PG_Pertussis_Investigation', N'INVH211',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'CLN_DIAGNOSIS_TYPE', NULL, 1, NULL,
     N'CODED', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014611, 1, 22014212, N'D_INVESTIGATION_REPEAT', N'CLN_EVIDENCE_CAVITY',
     N'N', 2, N'PG_Pertussis_Investigation', N'INVH212',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'CLN_EVIDENCE_CAVITY', NULL, 1, NULL,
     N'CODED', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014612, 1, 22014213, N'D_INVESTIGATION_REPEAT', N'CLN_EVIDENCE_MILIARY_TB',
     N'N', 2, N'PG_Pertussis_Investigation', N'INVH213',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'CLN_EVIDENCE_MILIARY_TB', NULL, 1, NULL,
     N'CODED', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    -- LAB_BLOCK seq 3
    (22006000, 22014620, 1, 22014221, N'D_INVESTIGATION_REPEAT', N'CLN_RSLT_CHEST_STDY',
     N'N', 3, N'PG_Pertussis_Investigation', N'INVH221',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'CLN_RSLT_CHEST_STDY', NULL, 1, NULL,
     N'CODED', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014621, 1, 22014222, N'D_INVESTIGATION_REPEAT', N'RSK_LARVA_SUSPECT_MEAT',
     N'N', 3, N'PG_Pertussis_Investigation', N'INVH222',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'RSK_LARVA_SUSPECT_MEAT', NULL, 1, NULL,
     N'CODED', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    -- TRT_BLOCK seq 1
    (22006000, 22014700, 1, 22014231, N'D_INVESTIGATION_REPEAT', N'TRT_DRG_USD_TRT_MDR_TB',
     N'N', 1, N'PG_Pertussis_Investigation', N'INVH231',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'TRT_DRG_USD_TRT_MDR_TB', NULL, 1, NULL,
     N'CODED', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014701, 1, 22014232, N'D_INVESTIGATION_REPEAT', N'LAB_ISOLTE_SENT_STATE_LAB',
     N'Y', 1, N'PG_Pertussis_Investigation', N'INVH232',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_ISOLTE_SENT_STATE_LAB', NULL, 1, NULL,
     N'CODED', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014702, 1, 22014233, N'D_INVESTIGATION_REPEAT', N'LAB_SUSPECT_MEAT_TESTED',
     N'N', 1, N'PG_Pertussis_Investigation', N'INVH233',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_SUSPECT_MEAT_TESTED', NULL, 1, NULL,
     N'CODED', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    -- TRT_BLOCK seq 2
    (22006000, 22014710, 1, 22014241, N'D_INVESTIGATION_REPEAT', N'RSK_TRNSPLNT_ASSOC_INFCTN',
     N'N', 2, N'PG_Pertussis_Investigation', N'INVH241',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'RSK_TRNSPLNT_ASSOC_INFCTN', NULL, 1, NULL,
     N'CODED', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    -- TRT_BLOCK seq 3
    (22006000, 22014720, 1, 22014251, N'D_INVESTIGATION_REPEAT', N'TRV_TRAVEL_SEX_CONTACT',
     N'N', 3, N'PG_Pertussis_Investigation', N'INVH251',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'TRV_TRAVEL_SEX_CONTACT', NULL, 1, NULL,
     N'CODED', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    -- RSK_BLOCK seq 1
    (22006000, 22014800, 1, 22014261, N'D_INVESTIGATION_REPEAT', N'MDH_HX_CONFIRMED_IND',
     N'Y', 1, N'PG_Pertussis_Investigation', N'INVH261',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'MDH_HX_CONFIRMED_IND', NULL, 1, NULL,
     N'CODED', 1, N'RSK_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014801, 1, 22014262, N'D_INVESTIGATION_REPEAT', N'LAB_INTERP_FLAG',
     N'Y', 1, N'PG_Pertussis_Investigation', N'INVH262',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_INTERP_FLAG', NULL, 1, NULL,
     N'CODED', 1, N'RSK_BLOCK', NULL, N'LITERAL'),
    -- RSK_BLOCK seq 2
    (22006000, 22014810, 1, 22014271, N'D_INVESTIGATION_REPEAT', N'ADM_ADV_EVE_IND',
     N'Y', 2, N'PG_Pertussis_Investigation', N'INVH271',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'ADM_ADV_EVE_IND', NULL, 1, NULL,
     N'CODED', 1, N'RSK_BLOCK', NULL, N'LITERAL'),
    -- SYM_BLOCK seq 2: NUMERIC cols on SYM rows
    (22006000, 22014820, 1, 22014281, N'D_INVESTIGATION_REPEAT', N'SYM_SIGN_SX_DURATION_IN_DAYS',
     N'21', 2, N'PG_Pertussis_Investigation', N'INVH281',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'SYM_SIGN_SX_DURATION_IN_DAYS', NULL, 1, NULL,
     N'NUMERIC', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014821, 1, 22014282, N'D_INVESTIGATION_REPEAT', N'LAB_RESULT_NUM_VAL',
     N'7', 2, N'PG_Pertussis_Investigation', N'INVH282',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_RESULT_NUM_VAL', NULL, 1, NULL,
     N'NUMERIC', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014822, 1, 22014283, N'D_INVESTIGATION_REPEAT', N'LAB_QUANT_TEST_RESULT',
     N'200', 2, N'PG_Pertussis_Investigation', N'INVH283',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_QUANT_TEST_RESULT', NULL, 1, NULL,
     N'NUMERIC', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014823, 1, 22014284, N'D_INVESTIGATION_REPEAT', N'LAB_AST_QUANT_RSLT',
     N'150', 2, N'PG_Pertussis_Investigation', N'INVH284',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_AST_QUANT_RSLT', NULL, 1, NULL,
     N'NUMERIC', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    -- VAC_BLOCK seq 2
    (22006000, 22014830, 1, 22014291, N'D_INVESTIGATION_REPEAT', N'LAB_PARASITEMIA_LVL_PCT',
     N'5', 2, N'PG_Pertussis_Investigation', N'INVH291',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_PARASITEMIA_LVL_PCT', NULL, 1, NULL,
     N'NUMERIC', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014831, 1, 22014292, N'D_INVESTIGATION_REPEAT', N'SUS_RESULT_NUM_VAL',
     N'12', 2, N'PG_Pertussis_Investigation', N'INVH292',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'SUS_RESULT_NUM_VAL', NULL, 1, NULL,
     N'NUMERIC', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    -- VAC_BLOCK seq 3
    (22006000, 22014840, 1, 22014301, N'D_INVESTIGATION_REPEAT', N'LAB_RESULT_NUM_VAL',
     N'88', 3, N'PG_Pertussis_Investigation', N'INVH301',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_RESULT_NUM_VAL', NULL, 1, NULL,
     N'NUMERIC', 1, N'VAC_BLOCK', NULL, N'LITERAL'),

    -- More dates spread across (block, seq) combos for col coverage
    (22006000, 22014900, 1, 22014311, N'D_INVESTIGATION_REPEAT', N'EPI_BLOOD_DONATION_DT',
     N'02/01/26', 2, N'PG_Pertussis_Investigation', N'INVH311',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'EPI_BLOOD_DONATION_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014901, 1, 22014312, N'D_INVESTIGATION_REPEAT', N'EPI_BLOOD_TRANSFUSION_DT',
     N'02/02/26', 2, N'PG_Pertussis_Investigation', N'INVH312',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'EPI_BLOOD_TRANSFUSION_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014902, 1, 22014313, N'D_INVESTIGATION_REPEAT', N'EPI_DATE_OF_READING',
     N'02/03/26', 2, N'PG_Pertussis_Investigation', N'INVH313',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'EPI_DATE_OF_READING', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014903, 1, 22014314, N'D_INVESTIGATION_REPEAT', N'EPI_SUSPCTD_SRC_COUGH_ONSET_DT',
     N'02/04/26', 2, N'PG_Pertussis_Investigation', N'INVH314',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'EPI_SUSPCTD_SRC_COUGH_ONSET_DT', NULL, 1, NULL,
     N'DATE', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014904, 1, 22014315, N'D_INVESTIGATION_REPEAT', N'CLN_ADMISSION_DATE',
     N'03/26/26', 1, N'PG_Pertussis_Investigation', N'INVH315',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'CLN_ADMISSION_DATE', NULL, 1, NULL,
     N'DATE', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014905, 1, 22014316, N'D_INVESTIGATION_REPEAT', N'CLN_DISCHARGE_DATE',
     N'04/02/26', 1, N'PG_Pertussis_Investigation', N'INVH316',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'CLN_DISCHARGE_DATE', NULL, 1, NULL,
     N'DATE', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014906, 1, 22014317, N'D_INVESTIGATION_REPEAT', N'SUS_REPORT_DT',
     N'04/05/26', 1, N'PG_Pertussis_Investigation', N'INVH317',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'SUS_REPORT_DT', NULL, 1, NULL,
     N'DATE', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014907, 1, 22014318, N'D_INVESTIGATION_REPEAT', N'TRT_MEDICATION_START_DT',
     N'04/06/26', 1, N'PG_Pertussis_Investigation', N'INVH318',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'TRT_MEDICATION_START_DT', NULL, 1, NULL,
     N'DATE', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014908, 1, 22014319, N'D_INVESTIGATION_REPEAT', N'TRT_MEDICATION_STOP_DATE',
     N'04/20/26', 1, N'PG_Pertussis_Investigation', N'INVH319',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'TRT_MEDICATION_STOP_DATE', NULL, 1, NULL,
     N'DATE', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014909, 1, 22014320, N'D_INVESTIGATION_REPEAT', N'TRV_DEPART_TRVL_DEST_DT',
     N'03/01/26', 1, N'PG_Pertussis_Investigation', N'INVH320',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'TRV_DEPART_TRVL_DEST_DT', NULL, 1, NULL,
     N'DATE', 1, N'VAC_BLOCK', NULL, N'LITERAL'),

    -- =================================================================
    -- Round 3: More NUMERIC + CODED targeting still-unpopulated cols.
    -- =================================================================
    -- NUMERIC cols
    (22006000, 22014950, 1, 22014401, N'D_INVESTIGATION_REPEAT', N'LAB_REF_RANGE_FROM',
     N'0', 3, N'PG_Pertussis_Investigation', N'INVH401',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_REF_RANGE_FROM', NULL, 1, NULL,
     N'NUMERIC', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014951, 1, 22014402, N'D_INVESTIGATION_REPEAT', N'LAB_REF_RANGE_TO',
     N'10', 3, N'PG_Pertussis_Investigation', N'INVH402',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_REF_RANGE_TO', NULL, 1, NULL,
     N'NUMERIC', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014952, 1, 22014403, N'D_INVESTIGATION_REPEAT', N'SUS_REF_RANGE_FROM',
     N'0', 3, N'PG_Pertussis_Investigation', N'INVH403',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'SUS_REF_RANGE_FROM', NULL, 1, NULL,
     N'NUMERIC', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014953, 1, 22014404, N'D_INVESTIGATION_REPEAT', N'SUS_REF_RANGE_TO',
     N'10', 3, N'PG_Pertussis_Investigation', N'INVH404',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'SUS_REF_RANGE_TO', NULL, 1, NULL,
     N'NUMERIC', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014954, 1, 22014405, N'D_INVESTIGATION_REPEAT', N'CLN_ADVERSE_EVNT_ONSET',
     N'5', 3, N'PG_Pertussis_Investigation', N'INVH405',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'CLN_ADVERSE_EVNT_ONSET', NULL, 1, NULL,
     N'NUMERIC', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014955, 1, 22014406, N'D_INVESTIGATION_REPEAT', N'CLN_ADVERSE_EVNT_SEVERITY',
     N'2', 3, N'PG_Pertussis_Investigation', N'INVH406',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'CLN_ADVERSE_EVNT_SEVERITY', NULL, 1, NULL,
     N'NUMERIC', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014956, 1, 22014407, N'D_INVESTIGATION_REPEAT', N'EPI_SUSPECTED_SOURCE_AGE',
     N'45', 3, N'PG_Pertussis_Investigation', N'INVH407',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'EPI_SUSPECTED_SOURCE_AGE', NULL, 1, NULL,
     N'NUMERIC', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014957, 1, 22014408, N'D_INVESTIGATION_REPEAT', N'EPI_CO_LEVEL_IN_AIR',
     N'15', 3, N'PG_Pertussis_Investigation', N'INVH408',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE', N'EPI_CO_LEVEL_IN_AIR', NULL, 1, NULL,
     N'NUMERIC', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    -- CODED cols (more on existing rows)
    (22006000, 22014960, 1, 22014411, N'D_INVESTIGATION_REPEAT', N'CLN_ADMITTED_AS_INPATIENT',
     N'N', 2, N'PG_Pertussis_Investigation', N'INVH411',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'CLN_ADMITTED_AS_INPATIENT', NULL, 1, NULL,
     N'CODED', 1, N'RSK_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014961, 1, 22014412, N'D_INVESTIGATION_REPEAT', N'CLN_ADVERSE_EVT_RLTD_TRMT',
     N'N', 2, N'PG_Pertussis_Investigation', N'INVH412',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'CLN_ADVERSE_EVT_RLTD_TRMT', NULL, 1, NULL,
     N'CODED', 1, N'RSK_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014962, 1, 22014413, N'D_INVESTIGATION_REPEAT', N'IPO_CURRENT_OCCUPATION',
     N'Y', 2, N'PG_Pertussis_Investigation', N'INVH413',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'IPO_CURRENT_OCCUPATION', NULL, 1, NULL,
     N'CODED', 1, N'RSK_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014963, 1, 22014414, N'D_INVESTIGATION_REPEAT', N'IPO_CURRENT_INDUSTRY',
     N'Y', 2, N'PG_Pertussis_Investigation', N'INVH414',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'IPO_CURRENT_INDUSTRY', NULL, 1, NULL,
     N'CODED', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014964, 1, 22014415, N'D_INVESTIGATION_REPEAT', N'LAB_AST_INTERPRETATION',
     N'Y', 2, N'PG_Pertussis_Investigation', N'INVH415',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_AST_INTERPRETATION', NULL, 1, NULL,
     N'CODED', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014965, 1, 22014416, N'D_INVESTIGATION_REPEAT', N'LAB_LAB_TST_MODIFIER',
     N'Y', 2, N'PG_Pertussis_Investigation', N'INVH416',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_LAB_TST_MODIFIER', NULL, 1, NULL,
     N'CODED', 1, N'SYM_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014966, 1, 22014417, N'D_INVESTIGATION_REPEAT', N'LAB_MICROORG_IDENTIFIED',
     N'Y', 2, N'PG_Pertussis_Investigation', N'INVH417',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_MICROORG_IDENTIFIED', NULL, 1, NULL,
     N'CODED', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014967, 1, 22014418, N'D_INVESTIGATION_REPEAT', N'LAB_PERFORMING_LAB_TYPE',
     N'Y', 2, N'PG_Pertussis_Investigation', N'INVH418',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_PERFORMING_LAB_TYPE', NULL, 1, NULL,
     N'CODED', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014968, 1, 22014419, N'D_INVESTIGATION_REPEAT', N'LAB_RESULTED_TEST_CD',
     N'Y', 2, N'PG_Pertussis_Investigation', N'INVH419',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_RESULTED_TEST_CD', NULL, 1, NULL,
     N'CODED', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014969, 1, 22014420, N'D_INVESTIGATION_REPEAT', N'LAB_SPECIMEN_SOURCE',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INVH420',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_SPECIMEN_SOURCE', NULL, 1, NULL,
     N'CODED', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014970, 1, 22014421, N'D_INVESTIGATION_REPEAT', N'LAB_SPECIMEN_TYPE',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INVH421',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_SPECIMEN_TYPE', NULL, 1, NULL,
     N'CODED', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014971, 1, 22014422, N'D_INVESTIGATION_REPEAT', N'LAB_TEST_CD',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INVH422',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TEST_CD', NULL, 1, NULL,
     N'CODED', 1, N'VAC_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014972, 1, 22014423, N'D_INVESTIGATION_REPEAT', N'LAB_TEST_METHOD_CD',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INVH423',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TEST_METHOD_CD', NULL, 1, NULL,
     N'CODED', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014973, 1, 22014424, N'D_INVESTIGATION_REPEAT', N'LAB_TEST_TYPE',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INVH424',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TEST_TYPE', NULL, 1, NULL,
     N'CODED', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014974, 1, 22014425, N'D_INVESTIGATION_REPEAT', N'LAB_RESULT_CODE',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INVH425',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'LAB_RESULT_CODE', NULL, 1, NULL,
     N'CODED', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014975, 1, 22014426, N'D_INVESTIGATION_REPEAT', N'SUS_TEST_CD',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INVH426',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'SUS_TEST_CD', NULL, 1, NULL,
     N'CODED', 1, N'LAB_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014976, 1, 22014427, N'D_INVESTIGATION_REPEAT', N'SUS_TEST_METHOD_CD',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INVH427',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'SUS_TEST_METHOD_CD', NULL, 1, NULL,
     N'CODED', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014977, 1, 22014428, N'D_INVESTIGATION_REPEAT', N'STD_SIGN_SX_ANATOMIC_SITE',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INVH428',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'STD_SIGN_SX_ANATOMIC_SITE', NULL, 1, NULL,
     N'CODED', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014978, 1, 22014429, N'D_INVESTIGATION_REPEAT', N'MDH_HX_CONDITION',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INVH429',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'MDH_HX_CONDITION', NULL, 1, NULL,
     N'CODED', 1, N'TRT_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014979, 1, 22014430, N'D_INVESTIGATION_REPEAT', N'SYM_SIGN_SX_SOURCE',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INVH430',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'SYM_SIGN_SX_SOURCE', NULL, 1, NULL,
     N'CODED', 1, N'RSK_BLOCK', NULL, N'LITERAL'),
    (22006000, 22014980, 1, 22014431, N'D_INVESTIGATION_REPEAT', N'CMP_COMPLICATION',
     N'Y', 3, N'PG_Pertussis_Investigation', N'INVH431',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE', N'CMP_COMPLICATION', NULL, 1, NULL,
     N'CODED', 1, N'RSK_BLOCK', NULL, N'LITERAL');

END;
GO

-- =====================================================================
-- TAIL-EXEC: re-run sp_sld_investigation_repeat_postprocessing for PHC
-- 22006000 to pick up:
--   - the original 24 answers from d_investigation_repeat.sql
--   - the 30 baseline-col-targeting answers from
--     zz_d_investigation_repeat_extra_cols.sql
--   - this fixture's ~130 additional answers
--
-- WHY THIS IS NEEDED (ORCH_TODO finding):
--   orchestrator merge_and_verify.sh Step 8.5 runs the SP for
--   @phc_id_list = N'$PHC_UIDS' where $PHC_UIDS DOES NOT include
--   22006000 (verified live 2026-05-24).  Without a tail-EXEC here,
--   only the answers loaded *before* d_investigation_repeat.sql's
--   own tail-EXEC make it into the dim; both zz_*_extra_cols.sql
--   and this fixture's answers would be invisible to the SP at
--   merge_and_verify.sh runtime.
--
--   FIX OPTIONS (pick one):
--     a) Add '22006000' to PHC_UIDS in scripts/merge_and_verify.sh
--        (so Step 8.5 picks up the Pertussis full-chain PHC across
--        all D_INVESTIGATION_REPEAT-related fixtures).
--     b) Keep this tail-EXEC (acceptable pattern -- matches the tail
--        in d_investigation_repeat.sql).
--   This fixture takes option (b) for safety.  Recommended long-term
--   is (a) -- delete this tail-EXEC and the one in
--   d_investigation_repeat.sql once PHC_UIDS includes 22006000.
--
-- @batch_id: a per-run bigint for job_flow_log correlation; we use
-- 22014000 to disambiguate from the d_investigation_repeat.sql tail
-- (which uses 22006000).
-- =====================================================================
EXEC dbo.sp_sld_investigation_repeat_postprocessing
    @batch_id    = 22014000,
    @phc_id_list = N'22006000',
    @debug       = 0;
