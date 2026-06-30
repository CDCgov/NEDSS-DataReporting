-- =====================================================================
-- Round 4 (NO-SHORTCUT) — D_INVESTIGATION_REPEAT column fill (ODSE-only)
-- =====================================================================
-- Branch: aw/remove-nrt-shortcut. This fixture authors ONLY NBS_ODSE
-- rows. NO nrt_* INSERTs, NO EXEC sp_*, NO liquibase/seed/SRTE edits.
-- The real pipeline (CDC/Debezium -> kafka-connect sink ->
-- reporting-pipeline-service page builder; orchestrator Step 8.5
-- sp_sld_investigation_repeat_postprocessing over $PHC_UIDS) turns these
-- ODSE repeating-block answers into D_INVESTIGATION_REPEAT columns.
--
-- TARGET
--   dbo.D_INVESTIGATION_REPEAT (244 cols). Baseline 82/244 populated,
--   162 NULL. This fixture targets 40 of those NULL columns.
--
-- WHY THE 4 CONTRACT-NAMED FORMS YIELD ALMOST NOTHING (live-proven)
--   The orchestrator passes $PHC_UIDS to
--   sp_sld_investigation_repeat_postprocessing (routine 010). That SP at
--   line 91 EXCLUDES the legacy single-page forms:
--     INV_FORM_BMD*, INV_FORM_GEN, INV_FORM_HEP*, INV_FORM_MEA,
--     INV_FORM_PER, INV_FORM_RUB, INV_FORM_RVCT, INV_FORM_VAR.
--   So of the contract's named subjects:
--     - COVID 22003000  (PG_COVID-19_v1.1)        ROUTES, but already
--       has all 35 of its repeating columns populated (zz_covid_case_fill
--       authored answer_group_seq_nbr 1/2/3). Its ONLY remaining NULL
--       repeat col is TRV_DURATION_OUTSIDE_US (q 10006160), which is a
--       NUMERIC question with unit_type_cd='CODED'. The SP's numeric
--       branch (line 763-778) only accepts unit_type_cd NULL/'LITERAL';
--       the coded-numeric branch (line 441-448) requires
--       investigation_form_cd IS NULL -> so a NUMERIC+CODED question on a
--       NAMED form can never pivot. SP-gated; not fixable from ODSE.
--     - STD 22004000   (PG_STD_Investigation)     ROUTES, all 38 of its
--       repeat cols already populated. 0 net NULL cols reachable.
--     - Pertussis 22007000 (PG_Pertussis_Investigation) ROUTES; its 31
--       repeat cols overlap already-populated cols except 1
--       (EPI_SUSPECTED_SOURCE_AGE), itself NUMERIC+CODED (unfillable, as
--       above). Its existing answers sit at answer_group_seq_nbr=0.
--     - Hep 22043000   (INV_FORM_HEPGEN)          EXCLUDED by line 91 ->
--       never enters #phc_uids_REPT. Cannot feed D_INVESTIGATION_REPEAT
--       at all (it is a legacy-form Hepatitis_Case chain).
--   Net: the 4 named forms reach ~2 NULL cols, both SP-gated. Verified
--   live 2026-06-03 against the running stack.
--
-- WHERE THE REAL 162-COLUMN GAP LIVES
--   The NULL cols (LAB_MOLE_SUSC_*, CLN_CHEST_*, TRT_DRG_*, RSK_MEAT_*,
--   ADM_*, CMP_ADVERSE_*, ...) belong to repeating blocks of page-builder
--   forms that have NO investigation in the fixture corpus. Per-form
--   fillable-NULL survey (live):
--     PG_Malaria_Investigation         26  (SEED-GATED, see below)
--     PG_TB_LTBI_Investigation         25  <-- authored here
--     PG_Trichinellosis_Investigation  15  <-- authored here
--     PG_TBRD / Babesiosis / Monkeypox / ...  (smaller tails)
--   TB_LTBI + Trichinellosis = 40 DISTINCT NULL columns (after dedup).
--
-- SEED-GATED (documented, NOT fixed):
--   PG_Malaria_Investigation would add 26 NULL cols, but NBS_SRTE.dbo.
--   Condition_code has NO row mapping any condition to
--   PG_Malaria_Investigation (the page-builder routing key
--   condition_cd -> investigation_form_cd is absent). Authoring a Malaria
--   PHC therefore requires an SRTE Condition_code seed row -> OUT OF
--   BOUNDS (fixtures-only rule). Documented; skipped.
--
-- WHAT THIS FIXTURE AUTHORS (ODSE-only, additive)
--   Two NEW page-builder investigations, each a minimal Tier-1-shaped
--   ODSE chain + repeating-block nbs_case_answer rows:
--     1. TB_LTBI    PHC 22047000, condition 502582
--          (Latent Tuberculosis Infection (2020 TBLISS)) ->
--          condition_code.investigation_form_cd='PG_TB_LTBI_Investigation'
--          (NOT in the SP exclusion list). 25 repeating questions.
--     2. Trichinellosis PHC 22047500, condition 10270 ->
--          'PG_Trichinellosis_Investigation' (NOT excluded). 15 questions.
--   Each PHC gets:
--     - act (CASE/EVN) + public_health_case + act_id (PHC_LOCAL_ID)
--     - participation SubjOfPHC -> foundation patient 20000000
--       (nrt_investigation.patient_id; required so the page-builder/
--       datamart path is not silently dropped)
--     - case_management (minimal, IDENTITY_INSERT)
--     - nbs_case_answer rows: one per (question x answer_group_seq_nbr in
--       {1,2,3}). answer_group_seq_nbr 1/2/3 is what makes the SP treat
--       these as REPEATING-block answers (it requires
--       answer_group_seq_nbr IS NOT NULL AND question_group_seq_nbr IS
--       NOT NULL; the repeating questions carry question_group_seq_nbr in
--       ODSE ui_metadata). NULL group-seq would route to the single
--       D_INV_* dims instead (LESSON 9).
--   The CDC pipeline mirrors public_health_case -> nrt_investigation
--   (investigation_form_cd resolved from condition_code) and the service
--   builds nrt_page_case_answer from nbs_case_answer, resolving each
--   answer's rdb_table_nm/rdb_column_nm by joining nbs_question_uid to the
--   form's seed ui/rdb metadata (nrt_odse_NBS_ui_metadata +
--   v_nrt_odse_NBS_rdb_metadata_recent, both already seeded for these
--   forms). Step 8.5 then pivots them into D_INVESTIGATION_REPEAT.
--
-- VALUE FIDELITY: coded answers use real codes resolved live from the
--   question's code_set_group_id; dates/text are realistic literals.
--
-- ORCH_TODO (REQUIRED for these to populate):
--   Add 22047000 and 22047500 to PHC_UIDS in
--   testing-tools/synthetic-odse-fixtures/scripts/merge_and_verify.sh so the
--   Step-8.5 sp_sld_investigation_repeat_postprocessing @phc_id_list
--   includes them. Without this the SP never sees the new PHCs.
--
-- KNOWN UNFILLABLE within these 40 (document, do not chase):
--   TRV_DURATION_OUTSIDE_US (q 10006160) on Trichinellosis is NUMERIC
--   with unit_type_cd='CODED' -> same SP quirk described above; it likely
--   will NOT pivot. Counted out of the expected-fill total.
--
-- UID block (reserved 22047000-22047999 in catalog/uid_ranges.md, R4-H):
--   22047000              TB_LTBI act/public_health_case
--   22047001              TB_LTBI case_management
--   22047100-22047174     TB_LTBI nbs_case_answer (25 q x 3 grp = 75)
--   22047500              Trichinellosis act/public_health_case
--   22047501              Trichinellosis case_management
--   22047600-22047644     Trichinellosis nbs_case_answer (15 q x 3 = 45)
--
-- Foundation deps (read-only): patient 20000000, superuser 10009282.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @su   bigint   = 10009282;
DECLARE @t    datetime = '2026-04-03T00:00:00';

-- =====================================================================
-- 1) TB_LTBI investigation — PHC 22047000, condition 502582 ->
--    PG_TB_LTBI_Investigation
-- =====================================================================
DECLARE @tbl bigint = 22047000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @tbl)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@tbl, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@tbl, @t, @su, N'I',
         N'C', N'502582', N'Latent Tuberculosis Infection (2020 TBLISS)', N'NND', N'NND',
         N'O', @t, @su, N'CAS22047000GA01',
         N'OPEN', @t, N'A', @t,
         N'T', 1, N'TB', N'130001',
         @tbl, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@tbl, 1, @t, @su,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         @t, @su, N'ACTIVE',
         @t, N'CAS22047000GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @t);

    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @tbl, N'SubjOfPHC', N'CASE', @t, @su,
         @t, @su, N'ACTIVE', @t, N'A', @t, N'PSN',
         N'Subject of Public Health Case');

    SET IDENTITY_INSERT [dbo].[case_management] ON;
    INSERT INTO [dbo].[case_management]
        ([case_management_uid],[public_health_case_uid],[status_900],
         [field_record_number],[surv_assigned_date],[surv_closed_date],[case_closed_date])
    VALUES
        (22047001, @tbl, N'C', N'FRN-TBL-01', @t, @t, @t);
    SET IDENTITY_INSERT [dbo].[case_management] OFF;
END
GO

-- TB_LTBI repeating-block answers (answer_group_seq_nbr 1/2/3).
-- (uid, act, q_uid, grp1_val, grp2_val, grp3_val) materialised inline.
DECLARE @su   bigint   = 10009282;
DECLARE @t    datetime = '2026-04-03T00:00:00';
DECLARE @tbl  bigint   = 22047000;

-- nbs_case_answer_uid is IDENTITY; let it AUTO-assign (LESSON 10:
-- hardcoded IDENTITY_INSERT UIDs collide with the auto-IDENTITY flood and
-- the guard silently skips the whole INSERT). Guard on the natural key.
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @tbl AND nbs_question_uid = 10011154 AND answer_group_seq_nbr = 1)
BEGIN
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid],[add_time],[add_user_id],[answer_txt],
     [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
     [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
     [answer_group_seq_nbr])
VALUES
    -- ADM_ADV_EVE_IND (q 10011154, CODED YNU csg 4150)
    (@tbl,@t,@su,N'N',10011154,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'Y',10011154,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'N',10011154,1,@t,@su,N'ACTIVE',@t,3,3),
    -- ADM_ADV_EVE_MNFSTN_DT (q 10012235, CODED csg 118700)
    (@tbl,@t,@su,N'PHC1917',10012235,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'PHC1917',10012235,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'PHC1917',10012235,1,@t,@su,N'ACTIVE',@t,3,3),
    -- ADM_LINKED_CASE_NBR (q 10012173, TEXT)
    (@tbl,@t,@su,N'LINK-22047000-A',10012173,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'LINK-22047000-B',10012173,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'LINK-22047000-C',10012173,1,@t,@su,N'ACTIVE',@t,3,3),
    -- ADM_PREV_STATE_CASE_NBR (q 10012175, TEXT)
    (@tbl,@t,@su,N'PSC-001',10012175,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'PSC-002',10012175,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'PSC-003',10012175,1,@t,@su,N'ACTIVE',@t,3,3),
    -- CLN_CHEST_STDY_TYPE (q 10010264, CODED csg 115430)
    (@tbl,@t,@su,N'113091000',10010264,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'113091000',10010264,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'113091000',10010264,1,@t,@su,N'ACTIVE',@t,3,3),
    -- CLN_CHEST_STUDY_DT (q 10012166, DATE)
    (@tbl,@t,@su,N'2026-03-10',10012166,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'2026-03-12',10012166,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'2026-03-14',10012166,1,@t,@su,N'ACTIVE',@t,3,3),
    -- CLN_DIAGNOSIS_TYPE (q 10012174, CODED csg 118230)
    (@tbl,@t,@su,N'11999007',10012174,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'11999007',10012174,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'11999007',10012174,1,@t,@su,N'ACTIVE',@t,3,3),
    -- CLN_EVIDENCE_CAVITY (q 10012167, CODED csg 4150)
    (@tbl,@t,@su,N'N',10012167,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'Y',10012167,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'N',10012167,1,@t,@su,N'ACTIVE',@t,3,3),
    -- CLN_EVIDENCE_MILIARY_TB (q 10012168, CODED csg 4150)
    (@tbl,@t,@su,N'N',10012168,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'N',10012168,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'Y',10012168,1,@t,@su,N'ACTIVE',@t,3,3),
    -- CLN_PREVIOUS_ILLNESS_DT (q 10006140, DATE)
    (@tbl,@t,@su,N'2026-02-01',10006140,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'2026-02-05',10006140,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'2026-02-09',10006140,1,@t,@su,N'ACTIVE',@t,3,3),
    -- CLN_RSLT_CHEST_STDY (q 10010265, CODED csg 115120)
    (@tbl,@t,@su,N'385660001',10010265,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'385660001',10010265,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'385660001',10010265,1,@t,@su,N'ACTIVE',@t,3,3),
    -- CMP_ADVERSE_EVENT (q 10012234, CODED csg 118520)
    (@tbl,@t,@su,N'15188001',10012234,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'15188001',10012234,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'15188001',10012234,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_ANTI_MIC_SUSC_RSLT_DT (q 10012206, DATE)
    (@tbl,@t,@su,N'2026-03-15',10012206,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'2026-03-17',10012206,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'2026-03-19',10012206,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_GENE_IDENTIFIER (q 10010295, CODED csg 118040)
    (@tbl,@t,@su,N'OTH',10010295,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'OTH',10010295,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'OTH',10010295,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_MOLE_SUSC_AMINO_ACID (q 10012213, TEXT)
    (@tbl,@t,@su,N'Ser315Thr',10012213,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'Lys43Arg',10012213,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'Asp94Gly',10012213,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_MOLE_SUSC_INDEL (q 10012214, CODED csg 118130)
    (@tbl,@t,@su,N'246114006',10012214,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'246114006',10012214,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'246114006',10012214,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_MOLE_SUSC_NUCLIC_ACID (q 10012212, TEXT)
    (@tbl,@t,@su,N'katG c.944G>C',10012212,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'rpoB c.1349C>T',10012212,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'gyrA c.280G>A',10012212,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_MOLE_SUSC_REPRTD_DT (q 10012209, DATE)
    (@tbl,@t,@su,N'2026-03-20',10012209,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'2026-03-22',10012209,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'2026-03-24',10012209,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_MOLE_SUSC_SPC_COLC_DT (q 10012208, DATE)
    (@tbl,@t,@su,N'2026-03-05',10012208,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'2026-03-07',10012208,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'2026-03-09',10012208,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_MOLE_SUSC_SPEC_TY (q 10012210, CODED csg 117770)
    (@tbl,@t,@su,N'10200004',10012210,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'10200004',10012210,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'10200004',10012210,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_MOLE_SUSC_TST_MTHD (q 10012215, CODED csg 118630)
    (@tbl,@t,@su,N'OTH',10012215,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'OTH',10012215,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'OTH',10012215,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_MOLE_SUSC_TST_RSLT (q 10012211, CODED csg 118600)
    (@tbl,@t,@su,N'260373001',10012211,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'260373001',10012211,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'260373001',10012211,1,@t,@su,N'ACTIVE',@t,3,3),
    -- TRT_CMPLT_TRT_PREV_DIAG (q 10012176, CODED csg 4150)
    (@tbl,@t,@su,N'N',10012176,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'Y',10012176,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'N',10012176,1,@t,@su,N'ACTIVE',@t,3,3),
    -- TRT_DRG_USD_TRT_MDR_TB (q 10012229, CODED csg 117700)
    (@tbl,@t,@su,N'10109',10012229,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'10109',10012229,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'10109',10012229,1,@t,@su,N'ACTIVE',@t,3,3),
    -- TRT_DUR_DRG_ADMINSTRD (q 10012230, CODED csg 118300)
    (@tbl,@t,@su,N'266710000',10012230,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tbl,@t,@su,N'266710000',10012230,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tbl,@t,@su,N'266710000',10012230,1,@t,@su,N'ACTIVE',@t,3,3);
END
GO

-- =====================================================================
-- 2) Trichinellosis investigation — PHC 22047500, condition 10270 ->
--    PG_Trichinellosis_Investigation
-- =====================================================================
DECLARE @su  bigint   = 10009282;
DECLARE @t   datetime = '2026-04-03T00:00:00';
DECLARE @tri bigint = 22047500;

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @tri)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@tri, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@tri, @t, @su, N'I',
         N'C', N'10270', N'Trichinellosis', N'NND', N'NND',
         N'O', @t, @su, N'CAS22047500GA01',
         N'OPEN', @t, N'A', @t,
         N'T', 1, N'GCD', N'130001',
         @tri, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@tri, 1, @t, @su,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         @t, @su, N'ACTIVE',
         @t, N'CAS22047500GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @t);

    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @tri, N'SubjOfPHC', N'CASE', @t, @su,
         @t, @su, N'ACTIVE', @t, N'A', @t, N'PSN',
         N'Subject of Public Health Case');

    SET IDENTITY_INSERT [dbo].[case_management] ON;
    INSERT INTO [dbo].[case_management]
        ([case_management_uid],[public_health_case_uid],[status_900],
         [field_record_number],[surv_assigned_date],[surv_closed_date],[case_closed_date])
    VALUES
        (22047501, @tri, N'C', N'FRN-TRI-01', @t, @t, @t);
    SET IDENTITY_INSERT [dbo].[case_management] OFF;
END
GO

DECLARE @su  bigint   = 10009282;
DECLARE @t   datetime = '2026-04-03T00:00:00';
DECLARE @tri bigint = 22047500;

-- nbs_case_answer_uid is IDENTITY; let it AUTO-assign (LESSON 10:
-- hardcoded IDENTITY_INSERT UIDs collide with the auto-IDENTITY flood and
-- the guard silently skips the whole INSERT). Guard on the natural key.
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @tri AND nbs_question_uid = 10009139 AND answer_group_seq_nbr = 1)
BEGIN
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid],[add_time],[add_user_id],[answer_txt],
     [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
     [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
     [answer_group_seq_nbr])
VALUES
    -- EPI_OTHER_MEAT_TYPE (q 10009139, TEXT)
    (@tri,@t,@su,N'Wild boar',10009139,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'Bear',10009139,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'Cougar',10009139,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_SPECIMEN_ANALYZED_DT (q 10002105, DATE)
    (@tri,@t,@su,N'2026-03-11',10002105,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'2026-03-13',10002105,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'2026-03-15',10002105,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_SPECIMEN_TYPE (q 10001372, CODED csg 113080)
    (@tri,@t,@su,N'119297000',10001372,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'119297000',10001372,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'119297000',10001372,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_STRAIN_TYPE (q 10009134, CODED csg 113150)
    (@tri,@t,@su,N'264435007',10009134,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'264435007',10009134,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'264435007',10009134,1,@t,@su,N'ACTIVE',@t,3,3),
    -- LAB_SUSPECT_MEAT_TESTED (q 10009145, CODED csg 113350)
    (@tri,@t,@su,N'OTH',10009145,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'OTH',10009145,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'OTH',10009145,1,@t,@su,N'ACTIVE',@t,3,3),
    -- RSK_CONSUMED_DT (q 10009140, DATE)
    (@tri,@t,@su,N'2026-02-20',10009140,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'2026-02-22',10009140,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'2026-02-24',10009140,1,@t,@su,N'ACTIVE',@t,3,3),
    -- RSK_COOKING_METHOD (q 10009143, CODED csg 113300)
    (@tri,@t,@su,N'F0003',10009143,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'F0003',10009143,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'F0003',10009143,1,@t,@su,N'ACTIVE',@t,3,3),
    -- RSK_LARVA_SUSPECT_MEAT (q 10009144, CODED csg 112930)
    (@tri,@t,@su,N'2667000',10009144,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'2667000',10009144,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'2667000',10009144,1,@t,@su,N'ACTIVE',@t,3,3),
    -- RSK_MEAT_COMMENTS (q 10009146, TEXT)
    (@tri,@t,@su,N'Home-processed, undercooked',10009146,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'Shared at family event',10009146,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'Frozen >30 days',10009146,1,@t,@su,N'ACTIVE',@t,3,3),
    -- RSK_MEAT_PREPARATION (q 10009142, CODED csg 113190)
    (@tri,@t,@su,N'A0769',10009142,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'A0769',10009142,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'A0769',10009142,1,@t,@su,N'ACTIVE',@t,3,3),
    -- RSK_SUSPECT_MEAT_TYPE (q 10009138, CODED csg 113020)
    (@tri,@t,@su,N'B1292',10009138,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'B1292',10009138,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'B1292',10009138,1,@t,@su,N'ACTIVE',@t,3,3),
    -- RSK_WHERE_MEAT_OBTAINED (q 10009141, CODED csg 112900)
    (@tri,@t,@su,N'224834004',10009141,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'224834004',10009141,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'224834004',10009141,1,@t,@su,N'ACTIVE',@t,3,3),
    -- TRV_DESTINATION_TYPE (q 10006155, CODED csg 3010)
    (@tri,@t,@su,N'DOM',10006155,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'INTL',10006155,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'DOM',10006155,1,@t,@su,N'ACTIVE',@t,3,3),
    -- TRV_DURATION_OUTSIDE_US (q 10006160, NUMERIC unit_type_cd=CODED ->
    --   SP-gated, likely WON'T pivot; authored for completeness)
    (@tri,@t,@su,N'14',10006160,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'21',10006160,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'7',10006160,1,@t,@su,N'ACTIVE',@t,3,3),
    -- TRV_TRAVEL_COUNTY (q 10006156, CODED county csg 110410)
    (@tri,@t,@su,N'13001',10006156,1,@t,@su,N'ACTIVE',@t,1,1),
    (@tri,@t,@su,N'13003',10006156,1,@t,@su,N'ACTIVE',@t,2,2),
    (@tri,@t,@su,N'13001',10006156,1,@t,@su,N'ACTIVE',@t,3,3);
END
GO
