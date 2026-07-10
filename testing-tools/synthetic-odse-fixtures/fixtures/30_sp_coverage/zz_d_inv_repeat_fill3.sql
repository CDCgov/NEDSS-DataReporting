-- =====================================================================
-- Round 5 (NO-SHORTCUT) — D_INVESTIGATION_REPEAT column fill #3 (ODSE-only)
-- Agent R5 d_inv_repeat-more.  UID block 22060000-22060999.
-- =====================================================================
-- Branch: aw/remove-nrt-shortcut. This fixture authors ONLY NBS_ODSE
-- rows. NO nrt_* INSERTs, NO EXEC sp_*, NO liquibase/seed/SRTE edits.
-- The real pipeline (CDC/Debezium -> kafka-connect sink ->
-- reporting-pipeline-service page builder; orchestrator Step 8.5
-- sp_sld_investigation_repeat_postprocessing over $PHC_UIDS) turns these
-- ODSE repeating-block answers into D_INVESTIGATION_REPEAT columns.
--
-- TARGET
--   dbo.D_INVESTIGATION_REPEAT (299 cols). At authoring time the committed
--   corpus populates 200/299; 99 remain all-NULL (live survey 2026-06-04).
--   Prior waves (zz_d_inv_repeat_fill / fill2) authored TB_LTBI(502582),
--   Trichinellosis(10270), STEC(115631), Cyclosporiasis(115751),
--   Salmonellosis(502651), Malaria(10130).
--
-- WHY THESE FOUR FORMS (live survey 2026-06-04 against the running stack)
--   sp_sld_investigation_repeat_postprocessing (routine 010, line ~91)
--   EXCLUDES the legacy single-page forms (INV_FORM_BMD*, INV_FORM_GEN,
--   INV_FORM_HEP*, INV_FORM_MEA, INV_FORM_PER, INV_FORM_RUB,
--   INV_FORM_RVCT, INV_FORM_VAR) and pivots repeating-block answers
--   (answer_group_seq_nbr 1/2/3) of NON-excluded page-builder forms.
--   Joining the 99 all-NULL D_INVESTIGATION_REPEAT columns back through
--   nrt_odse_NBS_rdb_metadata -> nrt_odse_NBS_ui_metadata (repeating
--   questions: question_group_seq_nbr IS NOT NULL) for non-excluded forms
--   that have NO investigation in the corpus yields, ranked by distinct
--   NULL cols fed:
--     PG_TBRD_Investigation           9  <-- authored here (cond 10250)
--     PG_Monkeypox_Investigation      6  <-- authored here (cond 11801)
--     PG_Babesiosis_Investigation     5  <-- authored here (cond 12010)
--     PG_Carbon_Monoxide_Investigation 4 <-- authored here (cond 32016)
--   (PG_Congenital_Syphilis_Investigation also feeds 6, but its repeat
--    cols overlap LAB_RESULT_*/SUS_* shared SUS/LAB lab-result blocks that
--    need a different obs-driven path; deferred.)
--
-- CONDITION -> FORM mappings used (verified present in BOTH
-- NBS_SRTE.dbo.Condition_code AND the pipeline routing copy
-- RDB_MODERN.dbo.nrt_srte_Condition_code 2026-06-04 — NONE are SEED-gated;
-- the fixtures-only rule is respected, NO SRTE edits, these already exist):
--   10250 -> PG_TBRD_Investigation            (Spotted Fever Rickettsiosis, prog GCD)
--   11801 -> PG_Monkeypox_Investigation       (Monkeypox,                   prog GCD)
--   12010 -> PG_Babesiosis_Investigation      (Babesiosis,                  prog GCD)
--   32016 -> PG_Carbon_Monoxide_Investigation (Carbon Monoxide Poisoning,   prog GCD)
--
-- DISTINCT NULL COLUMNS EXPECTED TO FILL (union across the 4 forms, after
-- dedup of cols shared by TBRD & Babesiosis) = 18:
--   EPI_BLOOD_DONATION_DT      (TBRD, Babesiosis)
--   EPI_BLOOD_TRANSFUSION_DT   (TBRD, Babesiosis)
--   RSK_TICK_BITE_DT           (TBRD, Babesiosis)
--   RSK_TICK_BITE_LOCATION     (TBRD, Babesiosis)
--   LAB_LABORATORY_STATE       (TBRD)
--   RSK_DT_OF_BLD_TRANSFUSION  (TBRD)
--   RSK_ORGANS_TRANSPLNTD_TXT  (TBRD)
--   RSK_TRNSPLNT_ASSOC_INFCTN  (TBRD)
--   TRT_TREATMENT_RX_DT        (TBRD)
--   EPI_MASK_WORN_FREQUENCY    (Monkeypox)
--   EPI_MASK_WORN_TRAVELING    (Monkeypox)
--   LAB_SPECIMEN_TEST_DATE     (Monkeypox)
--   TRV_FLIGHT_NUMBER          (Monkeypox)
--   TRV_SEAT_NUMBER            (Monkeypox)
--   TRV_TRAVEL_SEX_CONTACT     (Monkeypox)
--   EPI_CO_LEVEL_IN_AIR        (Carbon Monoxide)
--   EPI_DATE_OF_READING        (Carbon Monoxide)
--   EPI_PSN_ORG_TKNG_CO_REDNG  (Carbon Monoxide)
--   TRT_TREATMENT_LOCATION     (Carbon Monoxide)
--   -> 18 distinct cols expected (DATE/TEXT/CODED/NUMERIC-LITERAL all
--      pivot via routine 010).
--
-- KNOWN UNFILLABLE (authored for completeness, NOT counted in the 18):
--   TRV_DURATION_OUTSIDE_US (q 10006160, NUMERIC unit_type_cd='CODED') on
--   Babesiosis — routine 010 numeric branch needs unit NULL/'LITERAL',
--   coded-numeric branch needs investigation_form_cd IS NULL -> cannot
--   pivot on a named form (same SP quirk documented in fill / fill2).
--
-- WHAT THIS FIXTURE AUTHORS (ODSE-only, additive)
--   FOUR NEW page-builder investigations, each a minimal Tier-1-shaped
--   ODSE chain + repeating-block nbs_case_answer rows:
--     - act (CASE/EVN) + public_health_case + act_id (PHC_LOCAL_ID)
--     - participation SubjOfPHC -> foundation patient 20000000 (which HAS
--       a D_PATIENT row, PATIENT_KEY 4) authored INLINE here (this fixture
--       owns its own SubjOfPHC links; does NOT touch
--       zz_investigation_patient_links.sql) so nrt_investigation.patient_id
--       is non-NULL and the page-builder/datamart path is not dropped.
--     - case_management (minimal, AUTO-IDENTITY + natural-key guard)
--     - nbs_case_answer rows: one per (question x answer_group_seq_nbr in
--       {1,2,3}). answer_group_seq_nbr 1/2/3 is what makes routine 010
--       treat these as REPEATING-block answers (it requires
--       answer_group_seq_nbr IS NOT NULL AND question_group_seq_nbr IS NOT
--       NULL; the repeating questions carry question_group_seq_nbr in ODSE
--       ui_metadata). NULL group-seq would route to the single D_INV_*
--       dims instead (LESSON 9).
--   The CDC pipeline mirrors public_health_case -> nrt_investigation
--   (investigation_form_cd resolved from condition_code) and the service
--   builds nrt_page_case_answer from nbs_case_answer, resolving each
--   answer's rdb_table_nm/rdb_column_nm by joining nbs_question_uid to the
--   form's seed ui/rdb metadata (already seeded for these forms). Step 8.5
--   then pivots them into D_INVESTIGATION_REPEAT.
--
-- IDENTITY / GUARD DISCIPLINE (LESSON 10/11):
--   nbs_case_answer_uid + case_management_uid are IDENTITY -> AUTO-assign
--   (no hardcoded IDENTITY_INSERT, which would collide with the
--   auto-IDENTITY flood and SILENTLY skip the block). Each nbs_case_answer
--   block guards on the natural key act_uid + nbs_question_uid +
--   answer_group_seq_nbr = 1 (the DISTINGUISHING column per LESSON 11, so
--   the guard matches ONLY this block's repeating rows, never the
--   group-0 page_answers_datamart_routing rows for a different form).
--
-- VALUE FIDELITY: coded answers use real codes resolved live from each
--   question's code_set_group_id (YNU 4150; STATE_CCD 3920;
--   PHVS_PERSONORGTAKINGREADING_CO 116350; PHVS_TREATMENTLOCATION_CO
--   116650; MASK_USAGE 117480); dates/text/numeric are realistic literals.
--
-- ORCH_TODO (REQUIRED for these to populate):
--   Add 22060000, 22060200, 22060400, 22060600 to PHC_UIDS in
--   testing-tools/synthetic-odse-fixtures/scripts/merge_and_verify.sh so the
--   Step-8.5 sp_sld_investigation_repeat_postprocessing @phc_id_list
--   includes them. Without this the SP never sees the new PHCs.
--
-- UID block (reserved 22060000-22060999 in catalog/uid_ranges.md):
--   22060000   TBRD             act/public_health_case/act_id
--   22060200   Monkeypox        act/public_health_case/act_id
--   22060400   Babesiosis       act/public_health_case/act_id
--   22060600   Carbon Monoxide  act/public_health_case/act_id
--   (case_management + nbs_case_answer UIDs are AUTO-IDENTITY)
--
-- Foundation deps (read-only): patient 20000000 (D_PATIENT PATIENT_KEY 4),
-- superuser 10009282.
-- =====================================================================

USE [NBS_ODSE];
GO

-- =====================================================================
-- 1) TBRD investigation — PHC 22060000, condition 10250 ->
--    PG_TBRD_Investigation
-- =====================================================================
DECLARE @su   bigint   = 10009282;
DECLARE @t    datetime = '2026-04-03T00:00:00';
DECLARE @tbr  bigint   = 22060000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @tbr)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@tbr, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@tbr, @t, @su, N'I',
         N'C', N'10250', N'Spotted Fever Rickettsiosis', N'NND', N'NND',
         N'O', CAST(GETDATE() AS DATE), @su, N'CAS22060000GA01',
         N'OPEN', @t, N'A', @t,
         N'T', 1, N'GCD', N'130001',
         @tbr, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@tbr, 1, @t, @su,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @su, N'ACTIVE',
         @t, N'CAS22060000GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @t);

    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @tbr, N'SubjOfPHC', N'CASE', @t, @su,
         CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, N'A', @t, N'PSN',
         N'Subject of Public Health Case');

    IF NOT EXISTS (SELECT 1 FROM [dbo].[case_management] WHERE public_health_case_uid = @tbr)
        INSERT INTO [dbo].[case_management]
            ([public_health_case_uid],[status_900],
             [field_record_number],[surv_assigned_date],[surv_closed_date],[case_closed_date])
        VALUES
            (@tbr, N'C', N'FRN-TBRD-01', @t, @t, @t);
END
GO

DECLARE @su  bigint   = 10009282;
DECLARE @t   datetime = '2026-04-03T00:00:00';
DECLARE @tbr bigint   = 22060000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @tbr AND nbs_question_uid = 10007145 AND answer_group_seq_nbr = 1)
BEGIN
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid],[add_time],[add_user_id],[answer_txt],
     [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
     [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
     [answer_group_seq_nbr])
VALUES
    -- TRT_TREATMENT_RX_DT (q 10007145, DATE)
    (@tbr,@t,@su,N'2026-03-01',10007145,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@tbr,@t,@su,N'2026-03-03',10007145,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@tbr,@t,@su,N'2026-03-05',10007145,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ORGANS_TRANSPLNTD_TXT (q 10007148, TEXT)
    (@tbr,@t,@su,N'Kidney (left)',10007148,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@tbr,@t,@su,N'Liver lobe',10007148,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@tbr,@t,@su,N'Cornea',10007148,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_DT_OF_BLD_TRANSFUSION (q 10007149, DATE)
    (@tbr,@t,@su,N'2026-02-10',10007149,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@tbr,@t,@su,N'2026-02-12',10007149,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@tbr,@t,@su,N'2026-02-14',10007149,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_TRNSPLNT_ASSOC_INFCTN (q 10007150, CODED YNU csg 4150)
    (@tbr,@t,@su,N'N',10007150,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@tbr,@t,@su,N'Y',10007150,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@tbr,@t,@su,N'N',10007150,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_LABORATORY_STATE (q 10007152, CODED STATE_CCD csg 3920)
    (@tbr,@t,@su,N'13',10007152,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@tbr,@t,@su,N'01',10007152,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@tbr,@t,@su,N'12',10007152,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_TICK_BITE_LOCATION (q 10006152, TEXT)
    (@tbr,@t,@su,N'Right calf',10006152,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@tbr,@t,@su,N'Left forearm',10006152,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@tbr,@t,@su,N'Scalp',10006152,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_TICK_BITE_DT (q 10006153, DATE)
    (@tbr,@t,@su,N'2026-02-01',10006153,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@tbr,@t,@su,N'2026-02-03',10006153,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@tbr,@t,@su,N'2026-02-05',10006153,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- EPI_BLOOD_TRANSFUSION_DT (q 10006145, DATE)
    (@tbr,@t,@su,N'2026-01-20',10006145,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@tbr,@t,@su,N'2026-01-22',10006145,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@tbr,@t,@su,N'2026-01-24',10006145,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- EPI_BLOOD_DONATION_DT (q 10006147, DATE)
    (@tbr,@t,@su,N'2026-01-10',10006147,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@tbr,@t,@su,N'2026-01-12',10006147,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@tbr,@t,@su,N'2026-01-14',10006147,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3);
END
GO

-- =====================================================================
-- 2) Monkeypox investigation — PHC 22060200, condition 11801 ->
--    PG_Monkeypox_Investigation
-- =====================================================================
DECLARE @su  bigint   = 10009282;
DECLARE @t   datetime = '2026-04-03T00:00:00';
DECLARE @mpx bigint   = 22060200;

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @mpx)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@mpx, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@mpx, @t, @su, N'I',
         N'C', N'11801', N'Monkeypox', N'NND', N'NND',
         N'O', CAST(GETDATE() AS DATE), @su, N'CAS22060200GA01',
         N'OPEN', @t, N'A', @t,
         N'T', 1, N'GCD', N'130001',
         @mpx, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@mpx, 1, @t, @su,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @su, N'ACTIVE',
         @t, N'CAS22060200GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @t);

    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @mpx, N'SubjOfPHC', N'CASE', @t, @su,
         CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, N'A', @t, N'PSN',
         N'Subject of Public Health Case');

    IF NOT EXISTS (SELECT 1 FROM [dbo].[case_management] WHERE public_health_case_uid = @mpx)
        INSERT INTO [dbo].[case_management]
            ([public_health_case_uid],[status_900],
             [field_record_number],[surv_assigned_date],[surv_closed_date],[case_closed_date])
        VALUES
            (@mpx, N'C', N'FRN-MPX-01', @t, @t, @t);
END
GO

DECLARE @su  bigint   = 10009282;
DECLARE @t   datetime = '2026-04-03T00:00:00';
DECLARE @mpx bigint   = 22060200;

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @mpx AND nbs_question_uid = 10011189 AND answer_group_seq_nbr = 1)
BEGIN
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid],[add_time],[add_user_id],[answer_txt],
     [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
     [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
     [answer_group_seq_nbr])
VALUES
    -- TRV_FLIGHT_NUMBER (q 10011189, TEXT)
    (@mpx,@t,@su,N'DL1234',10011189,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mpx,@t,@su,N'AA5678',10011189,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mpx,@t,@su,N'UA9012',10011189,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRV_SEAT_NUMBER (q 10011190, TEXT)
    (@mpx,@t,@su,N'14C',10011190,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mpx,@t,@su,N'22A',10011190,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mpx,@t,@su,N'3F',10011190,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRV_TRAVEL_SEX_CONTACT (q 10011191, CODED YNU csg 4150)
    (@mpx,@t,@su,N'N',10011191,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mpx,@t,@su,N'Y',10011191,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mpx,@t,@su,N'N',10011191,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- EPI_MASK_WORN_TRAVELING (q 10011192, CODED YNU csg 4150)
    (@mpx,@t,@su,N'Y',10011192,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mpx,@t,@su,N'N',10011192,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mpx,@t,@su,N'Y',10011192,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- EPI_MASK_WORN_FREQUENCY (q 10011193, CODED MASK_USAGE csg 117480)
    (@mpx,@t,@su,N'ALWAYS',10011193,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mpx,@t,@su,N'SOMETIMES',10011193,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mpx,@t,@su,N'RARELY',10011193,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_SPECIMEN_TEST_DATE (q 10011198, DATE)
    (@mpx,@t,@su,N'2026-03-08',10011198,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mpx,@t,@su,N'2026-03-10',10011198,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mpx,@t,@su,N'2026-03-12',10011198,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3);
END
GO

-- =====================================================================
-- 3) Babesiosis investigation — PHC 22060400, condition 12010 ->
--    PG_Babesiosis_Investigation
-- =====================================================================
DECLARE @su  bigint   = 10009282;
DECLARE @t   datetime = '2026-04-03T00:00:00';
DECLARE @bab bigint   = 22060400;

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @bab)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@bab, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@bab, @t, @su, N'I',
         N'C', N'12010', N'Babesiosis', N'NND', N'NND',
         N'O', CAST(GETDATE() AS DATE), @su, N'CAS22060400GA01',
         N'OPEN', @t, N'A', @t,
         N'T', 1, N'GCD', N'130001',
         @bab, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@bab, 1, @t, @su,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @su, N'ACTIVE',
         @t, N'CAS22060400GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @t);

    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @bab, N'SubjOfPHC', N'CASE', @t, @su,
         CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, N'A', @t, N'PSN',
         N'Subject of Public Health Case');

    IF NOT EXISTS (SELECT 1 FROM [dbo].[case_management] WHERE public_health_case_uid = @bab)
        INSERT INTO [dbo].[case_management]
            ([public_health_case_uid],[status_900],
             [field_record_number],[surv_assigned_date],[surv_closed_date],[case_closed_date])
        VALUES
            (@bab, N'C', N'FRN-BAB-01', @t, @t, @t);
END
GO

DECLARE @su  bigint   = 10009282;
DECLARE @t   datetime = '2026-04-03T00:00:00';
DECLARE @bab bigint   = 22060400;

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @bab AND nbs_question_uid = 10006152 AND answer_group_seq_nbr = 1)
BEGIN
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid],[add_time],[add_user_id],[answer_txt],
     [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
     [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
     [answer_group_seq_nbr])
VALUES
    -- RSK_TICK_BITE_LOCATION (q 10006152, TEXT)
    (@bab,@t,@su,N'Left ankle',10006152,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@bab,@t,@su,N'Right thigh',10006152,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@bab,@t,@su,N'Neck',10006152,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_TICK_BITE_DT (q 10006153, DATE)
    (@bab,@t,@su,N'2026-02-02',10006153,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@bab,@t,@su,N'2026-02-04',10006153,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@bab,@t,@su,N'2026-02-06',10006153,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- EPI_BLOOD_TRANSFUSION_DT (q 10006145, DATE)
    (@bab,@t,@su,N'2026-01-21',10006145,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@bab,@t,@su,N'2026-01-23',10006145,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@bab,@t,@su,N'2026-01-25',10006145,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- EPI_BLOOD_DONATION_DT (q 10006147, DATE)
    (@bab,@t,@su,N'2026-01-11',10006147,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@bab,@t,@su,N'2026-01-13',10006147,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@bab,@t,@su,N'2026-01-15',10006147,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRV_DURATION_OUTSIDE_US (q 10006160, NUMERIC unit_type_cd=CODED ->
    --   SP-gated, likely WON'T pivot; authored for completeness, NOT
    --   counted in the 18 expected cols)
    (@bab,@t,@su,N'10',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@bab,@t,@su,N'18',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@bab,@t,@su,N'5',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3);
END
GO

-- =====================================================================
-- 4) Carbon Monoxide investigation — PHC 22060600, condition 32016 ->
--    PG_Carbon_Monoxide_Investigation
-- =====================================================================
DECLARE @su  bigint   = 10009282;
DECLARE @t   datetime = '2026-04-03T00:00:00';
DECLARE @com bigint   = 22060600;

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @com)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@com, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@com, @t, @su, N'I',
         N'C', N'32016', N'Carbon Monoxide Poisoning', N'NND', N'NND',
         N'O', CAST(GETDATE() AS DATE), @su, N'CAS22060600GA01',
         N'OPEN', @t, N'A', @t,
         N'T', 1, N'GCD', N'130001',
         @com, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@com, 1, @t, @su,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @su, N'ACTIVE',
         @t, N'CAS22060600GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @t);

    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @com, N'SubjOfPHC', N'CASE', @t, @su,
         CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, N'A', @t, N'PSN',
         N'Subject of Public Health Case');

    IF NOT EXISTS (SELECT 1 FROM [dbo].[case_management] WHERE public_health_case_uid = @com)
        INSERT INTO [dbo].[case_management]
            ([public_health_case_uid],[status_900],
             [field_record_number],[surv_assigned_date],[surv_closed_date],[case_closed_date])
        VALUES
            (@com, N'C', N'FRN-CO-01', @t, @t, @t);
END
GO

DECLARE @su  bigint   = 10009282;
DECLARE @t   datetime = '2026-04-03T00:00:00';
DECLARE @com bigint   = 22060600;

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @com AND nbs_question_uid = 10011155 AND answer_group_seq_nbr = 1)
BEGIN
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid],[add_time],[add_user_id],[answer_txt],
     [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
     [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
     [answer_group_seq_nbr])
VALUES
    -- EPI_CO_LEVEL_IN_AIR (q 10011155, NUMERIC unit_type_cd NULL -> LITERAL, pivots)
    (@com,@t,@su,N'35',10011155,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@com,@t,@su,N'70',10011155,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@com,@t,@su,N'120',10011155,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- EPI_PSN_ORG_TKNG_CO_REDNG (q 10011156, CODED PHVS_PERSONORGTAKINGREADING_CO csg 116350)
    (@com,@t,@su,N'PHC630',10011156,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@com,@t,@su,N'PHC2174',10011156,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@com,@t,@su,N'C0085098',10011156,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- EPI_DATE_OF_READING (q 10011157, DATE)
    (@com,@t,@su,N'2026-03-02',10011157,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@com,@t,@su,N'2026-03-04',10011157,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@com,@t,@su,N'2026-03-06',10011157,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRT_TREATMENT_LOCATION (q 10011164, CODED PHVS_TREATMENTLOCATION_CO csg 116650)
    (@com,@t,@su,N'257622000',10011164,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@com,@t,@su,N'PHC2175',10011164,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@com,@t,@su,N'257622000',10011164,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3);
END
GO
