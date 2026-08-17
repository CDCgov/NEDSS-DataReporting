-- =====================================================================
-- Tier 3 — D_INV_PLACE_REPEAT population (NO-SHORTCUT / ODSE-only)
-- =====================================================================
-- Authored 2026-06-04 (Round 5, incremental wave-2). UID block 22062000-22062999.
-- Supersedes the now-inert zz_d_inv_place_repeat_enrich.sql, which wrote
-- nrt_page_case_answer directly (an NRT-shortcut write that is forbidden
-- on the aw/remove-nrt-shortcut flow). This fixture instead authors the
-- ODSE source rows and lets the real pipeline build nrt_page_case_answer.
--
-- WHAT FEEDS D_INV_PLACE_REPEAT (SP evidence):
--   Step 8.6 of merge_and_verify.sh runs:
--     EXEC dbo.sp_repeated_place_postprocessing @phc_id_list = N'$PHC_UIDS'
--   (routines/035-sp_repeated_place_postprocessing-001.sql). That SP:
--     1. #PLACE_INIT_OUT <- SELECT FROM dbo.NRT_PAGE_CASE_ANSWER pca
--          WHERE pca.act_uid IN @phc_id_list
--            AND PART_TYPE_CD IN ('PlaceAsHangoutOfPHC','PlaceAsSexOfPHC')
--          (with answer_txt caret-normalization: <2 carets -> append '^').
--     2. PIVOT on PART_TYPE_CD, keyed on (PAGE_CASE_UID, ANSWER_GROUP_SEQ_NBR),
--          producing PlaceAsHangoutOfPHC / PlaceAsSexOfPHC columns, then a
--          CROSS APPLY emitting one row per non-NULL part type with the
--          derived PLACE_HANGOUT_OF_PHC / PLACE_AS_SEX_OF_PHC values.
--     3. #S_INV_PLACE_REPEAT <- #PLACE_INIT INNER JOIN dbo.D_PLACE
--          ON D_PLACE.PLACE_LOCATOR_UID = PLACE_AS_SEX_OF_PHC
--          OR D_PLACE.PLACE_LOCATOR_UID = PLACE_HANGOUT_OF_PHC.
--     4. Final D_INV_PLACE_REPEAT row = the 6 pivot/derived cols + all 38
--          D_PLACE cols (44 total).
--
-- HOW nrt_page_case_answer GETS THE PLACE PART TYPES (ODSE -> pipeline):
--   sp_investigation_event (routines/056-sp_investigation_event-001.sql,
--   lines 437-571) builds the investigation_case_answer JSON by joining
--   nbs_odse.dbo.nbs_case_answer -> nbs_odse.dbo.nbs_ui_metadata on
--   nbs_question_uid, taking nuim.part_type_cd, filtered by
--   nuim.investigation_form_cd = condition_code.investigation_form_cd for
--   phc.cd. The reporting-pipeline-service consumes that CDC payload and
--   writes dbo.NRT_PAGE_CASE_ANSWER (topic nrt_page_case_answer). So
--   authoring ODSE nbs_case_answer rows for the right question_uids on a
--   PHC whose condition maps to the STD/HIV form is sufficient — the
--   pipeline produces the PlaceAs* nrt_page_case_answer rows for us.
--
-- METADATA (verified live in nbs_odse.dbo.nbs_ui_metadata):
--   part_type_cd       | nbs_question_uid | question_id | forms
--   PlaceAsHangoutOfPHC| 10001284         | NBS243      | PG_STD_Investigation, PG_HIV_Investigation
--   PlaceAsSexOfPHC    | 10001286         | NBS290      | PG_STD_Investigation, PG_HIV_Investigation
--   (data_type TEXT, data_location NBS_CASE_ANSWER.ANSWER_TXT.)
--
-- TARGET PHC: 22004000 (STD investigation, condition 10311 ->
--   PG_STD_Investigation). Already in PHC_UIDS and already re-extracted by
--   the pipeline (474 nrt_page_case_answer rows). The generic routing
--   fixture (zz_page_answers_datamart_routing.sql) ALREADY answers
--   10001284/10001286 for 22004000 at answer_group_seq_nbr=0 with
--   answer_txt='RTRfix' — that text matches no D_PLACE.PLACE_LOCATOR_UID so
--   it produces no D_INV_PLACE_REPEAT row (this is why the table was 1/44).
--   We add the REPEATING-GROUP answers (answer_group_seq_nbr 1/2/3) whose
--   answer_txt IS a real D_PLACE.PLACE_LOCATOR_UID -> the SP's INNER JOIN
--   matches and emits rows.
--
-- PLACE_LOCATOR_UID values used (verified live in dbo.D_PLACE):
--   '20040010^20040011^20040012'  Variant Motel, Atlanta, GA 30303,
--                                  404-555-4010, variant.place@nbs.test,
--                                  4010 Variant Motel Drive (RICHEST row -
--                                  fills name/city/state/zip/phone/email/
--                                  street/type/local_id/postal/tele cols).
--   '20000030^20040000^20040001'  Foundation Place, Atlanta, 404-555-0400.
--   (Both already have >=2 carets so they bypass the SP's caret
--   normalization and match D_PLACE.PLACE_LOCATOR_UID verbatim.)
--
-- COVERAGE: with both part types present per group and a rich locator,
--   the SP populates all 44 D_INV_PLACE_REPEAT columns (6 pivot/derived +
--   38 D_PLACE), at multiple groups, for PAGE_CASE_UID 22004000.
--
-- RULES: ODSE-only. No nrt_* INSERT. No EXEC sp_*. No liquibase/seed/SRTE
--   edits. nbs_case_answer_uid is IDENTITY -> AUTO-assign (LESSON 10);
--   idempotency guard on the natural key act_uid+nbs_question_uid+
--   answer_group_seq_nbr (LESSON 11 distinguishing column: the group-0
--   RTRfix rows from the routing fixture must NOT match this guard).
--   No SubjOfPHC authored here (22004000 already has its patient link via
--   the existing STD chain; D_INV_PLACE_REPEAT does not require one).
--   UID block 22062000-22062999 (no explicit place/org entities needed:
--   we reuse the foundation/v2 D_PLACE rows authored by 10_subjects/place.sql).
-- =====================================================================

USE [NBS_ODSE];
GO

-- Repeating-group place answers for STD PHC 22004000.
-- Guard on the natural key INCLUDING answer_group_seq_nbr (LESSON 11) so
-- this block is distinct from the routing fixture's group-0 RTRfix rows
-- and re-runnable. We probe group 1 of the first question as the sentinel.
IF NOT EXISTS (
    SELECT 1 FROM [dbo].[nbs_case_answer]
     WHERE act_uid = 22004000
       AND nbs_question_uid = 10001284
       AND answer_group_seq_nbr = 1
)
BEGIN
    -- nbs_case_answer_uid AUTO (IDENTITY). seq_nbr mirrors the group.
    -- answer_txt = a real D_PLACE.PLACE_LOCATOR_UID (>=2 carets, verbatim).
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id], [record_status_cd],
         [record_status_time], [seq_nbr], [answer_group_seq_nbr])
    VALUES
    -- ---- group 1: both part types -> richest locator (Variant Motel) ----
    (22004000, GETDATE(), 10009282, N'20040010^20040011^20040012', 10001284, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', GETDATE(), 1, 1), -- PlaceAsHangoutOfPHC g1
    (22004000, GETDATE(), 10009282, N'20040010^20040011^20040012', 10001286, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', GETDATE(), 1, 1), -- PlaceAsSexOfPHC     g1

    -- ---- group 2: both part types -> foundation locator ----
    (22004000, GETDATE(), 10009282, N'20000030^20040000^20040001', 10001284, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', GETDATE(), 2, 2), -- PlaceAsHangoutOfPHC g2
    (22004000, GETDATE(), 10009282, N'20000030^20040000^20040001', 10001286, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', GETDATE(), 2, 2), -- PlaceAsSexOfPHC     g2

    -- ---- group 3: hangout=variant / sex=foundation (mixed) ----
    (22004000, GETDATE(), 10009282, N'20040010^20040011^20040012', 10001284, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', GETDATE(), 3, 3), -- PlaceAsHangoutOfPHC g3
    (22004000, GETDATE(), 10009282, N'20000030^20040000^20040001', 10001286, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', GETDATE(), 3, 3); -- PlaceAsSexOfPHC     g3
END
GO

-- ---------------------------------------------------------------------
-- Re-trigger CDC -> reporting-pipeline-service so sp_investigation_event
-- re-extracts PHC 22004000 with these new repeating place answers into
-- dbo.NRT_PAGE_CASE_ANSWER (with part_type_cd from nbs_ui_metadata). Step
-- 8.6's sp_repeated_place_postprocessing then builds D_INV_PLACE_REPEAT.
-- Same last_chg_time bump pattern as zz_std_hiv_fill.sql /
-- zz_page_answers_datamart_routing.sql. This fixture sorts AFTER
-- zz_std_hiv_fill.sql, so its bump is the last one for 22004000 and the
-- resulting CDC extract captures every nbs_case_answer row for the PHC.
-- ---------------------------------------------------------------------
UPDATE [dbo].[public_health_case]
   SET last_chg_time = GETDATE()
 WHERE public_health_case_uid = 22004000;
GO
