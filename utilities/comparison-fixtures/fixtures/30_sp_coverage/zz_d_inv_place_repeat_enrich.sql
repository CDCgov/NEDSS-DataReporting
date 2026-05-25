-- =====================================================================
-- Tier 3 — D_INV_PLACE_REPEAT column-coverage enrichment
-- =====================================================================
-- Authored 2026-05-22.  Sibling of zz_d_investigation_repeat_extra_cols.sql.
--
-- Diagnosis (2026-05-22):
--   D_INV_PLACE_REPEAT was 1 row / 1 populated col (sentinel only)
--   because two things were both true pre-this-fixture:
--     (a) sp_repeated_place_postprocessing is NOT invoked anywhere
--         in utilities/comparison-fixtures/scripts/merge_and_verify.sh
--         (Steps 5/7/8.5/9 all skip it).  See ORCH_TODO in the
--         agent-D2 final report — orchestrator wire-up is required
--         BEFORE this fixture moves the needle.
--     (b) No fixtures author nrt_page_case_answer rows with
--         part_type_cd IN ('PlaceAsHangoutOfPHC','PlaceAsSexOfPHC')
--         and answer_txt pointing to a D_PLACE.PLACE_LOCATOR_UID
--         (only TRAVEL_BLOCK / EXPOSURE_BLOCK / GENERAL answers exist).
--
-- This fixture authors the (b) side: nrt_page_case_answer rows that
-- the SP picks up via its INNER JOIN to D_PLACE on PLACE_LOCATOR_UID.
-- When (a) is unblocked (orchestrator wiring), running the merge will
-- promote D_INV_PLACE_REPEAT from 1/42 toward ~30/42.
--
-- SP shape recap (035-sp_repeated_place_postprocessing-001.sql):
--   #PLACE_INIT_OUT: SELECT FROM nrt_page_case_answer
--     WHERE PART_TYPE_CD IN ('PlaceAsHangoutOfPHC','PlaceAsSexOfPHC')
--       AND act_uid IN @phc_id_list
--   #PLACE_INIT: PIVOT on PART_TYPE_CD → cols
--     PlaceAsHangoutOfPHC / PlaceAsSexOfPHC,
--     plus derived PLACE_HANGOUT_OF_PHC / PLACE_AS_SEX_OF_PHC.
--   #S_INV_PLACE_REPEAT: #PLACE_INIT INNER JOIN D_PLACE
--     ON D_PLACE.PLACE_LOCATOR_UID = PlaceAsSexOfPHC
--     OR D_PLACE.PLACE_LOCATOR_UID = PlaceAsHangoutOfPHC.
--   Final D_INV_PLACE_REPEAT row = PLACE_INIT cols + every D_PLACE col.
--
-- So coverage = (PAGE_CASE_UID, answer_group_seq_nbr,
--                PlaceAsHangoutOfPHC, PlaceAsSexOfPHC,
--                PLACE_HANGOUT_OF_PHC, PLACE_AS_SEX_OF_PHC) + all D_PLACE
-- cols populated on the referenced D_PLACE row.
--
-- v2 Place (20040010 → PLACE_LOCATOR_UID 'PLC20040010GA01', authored
-- by fixtures/10_subjects/place.sql) populates every D_PLACE column.
-- Foundation Place (20000030 → 'PLC20000030GA01') populates the
-- mandatory subset.
--
-- Authoring strategy:
--   Piggyback on Pertussis PHC 22006000 (already used by the sibling
--   d_investigation_repeat enrichment) plus a second PHC for variety.
--   Author both PART_TYPE_CD values across multiple answer_group_seq_nbr
--   so the PIVOT produces both PlaceAsHangoutOfPHC and PlaceAsSexOfPHC
--   non-NULL rows (which is what makes the CROSS APPLY emit BOTH the
--   PLACE_HANGOUT_OF_PHC and PLACE_AS_SEX_OF_PHC variants of #PLACE_INIT).
--
-- UID block: 22010000-22010999 (agent-D2 reserved).
-- =====================================================================

USE [RDB_MODERN];
GO

-- Idempotent guard so re-running the orchestrator doesn't duplicate rows.
IF NOT EXISTS (
    SELECT 1 FROM dbo.nrt_page_case_answer
    WHERE nbs_case_answer_uid BETWEEN 22010000 AND 22010999
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
         [unit_value], [unit_type_cd], [part_type_cd])
    VALUES
        -- ===== Pertussis PHC 22006000 — answer_group_seq_nbr 1
        -- both PART_TYPE_CD's, both pointing to v2 Place (max coverage).
        (22006000, 22010001, 1, 22010001,
         N'NRT_PAGE_CASE_ANSWER', NULL, N'PLC20040010GA01', N'1',
         N'PG_Pertussis_Investigation', N'INV900',
         N'NBS_Case_Answer.answer_txt', NULL,
         '2026-04-01T00:00:00', N'ACTIVE',
         NULL, NULL, 1, NULL,
         N'TEXT', 1, NULL, NULL, N'LITERAL', N'PlaceAsHangoutOfPHC'),
        (22006000, 22010002, 1, 22010002,
         N'NRT_PAGE_CASE_ANSWER', NULL, N'PLC20040010GA01', N'1',
         N'PG_Pertussis_Investigation', N'INV901',
         N'NBS_Case_Answer.answer_txt', NULL,
         '2026-04-01T00:00:00', N'ACTIVE',
         NULL, NULL, 1, NULL,
         N'TEXT', 1, NULL, NULL, N'LITERAL', N'PlaceAsSexOfPHC'),

        -- ===== Pertussis PHC 22006000 — answer_group_seq_nbr 2
        -- Hangout points to foundation Place (minimal coverage variant).
        (22006000, 22010003, 1, 22010003,
         N'NRT_PAGE_CASE_ANSWER', NULL, N'PLC20000030GA01', N'2',
         N'PG_Pertussis_Investigation', N'INV902',
         N'NBS_Case_Answer.answer_txt', NULL,
         '2026-04-01T00:00:00', N'ACTIVE',
         NULL, NULL, 1, NULL,
         N'TEXT', 1, NULL, NULL, N'LITERAL', N'PlaceAsHangoutOfPHC'),
        (22006000, 22010004, 1, 22010004,
         N'NRT_PAGE_CASE_ANSWER', NULL, N'PLC20040010GA01', N'2',
         N'PG_Pertussis_Investigation', N'INV903',
         N'NBS_Case_Answer.answer_txt', NULL,
         '2026-04-01T00:00:00', N'ACTIVE',
         NULL, NULL, 1, NULL,
         N'TEXT', 1, NULL, NULL, N'LITERAL', N'PlaceAsSexOfPHC'),

        -- ===== Pertussis PHC 22006000 — answer_group_seq_nbr 3
        -- Both PART_TYPE_CD's again; v2 Place for full-width coverage.
        (22006000, 22010005, 1, 22010005,
         N'NRT_PAGE_CASE_ANSWER', NULL, N'PLC20040010GA01', N'3',
         N'PG_Pertussis_Investigation', N'INV904',
         N'NBS_Case_Answer.answer_txt', NULL,
         '2026-04-01T00:00:00', N'ACTIVE',
         NULL, NULL, 1, NULL,
         N'TEXT', 1, NULL, NULL, N'LITERAL', N'PlaceAsHangoutOfPHC'),
        (22006000, 22010006, 1, 22010006,
         N'NRT_PAGE_CASE_ANSWER', NULL, N'PLC20040010GA01', N'3',
         N'PG_Pertussis_Investigation', N'INV905',
         N'NBS_Case_Answer.answer_txt', NULL,
         '2026-04-01T00:00:00', N'ACTIVE',
         NULL, NULL, 1, NULL,
         N'TEXT', 1, NULL, NULL, N'LITERAL', N'PlaceAsSexOfPHC');
END;
GO

-- NOTE: This fixture only authors source-side answers.  Without
-- orchestrator wire-up (see ORCH_TODO), running merge_and_verify.sh
-- will NOT call sp_repeated_place_postprocessing and D_INV_PLACE_REPEAT
-- will remain at 1/42 (sentinel only).
--
-- Smoke-test EXEC (manual):
--   EXEC dbo.sp_repeated_place_postprocessing
--        @batch_id = 260522,
--        @phc_id_list = N'22006000',
--        @debug = 0;
-- After which:
--   SELECT * FROM dbo.D_INV_PLACE_REPEAT WHERE PAGE_CASE_UID = 22006000;
-- should return 2-3 rows with most PLACE_* columns non-NULL (v2 Place
-- variant is fully populated by 10_subjects/place.sql).
