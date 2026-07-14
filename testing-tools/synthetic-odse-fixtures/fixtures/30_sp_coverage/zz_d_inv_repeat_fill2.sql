-- =====================================================================
-- Round 4 (NO-SHORTCUT) — D_INVESTIGATION_REPEAT column fill #2 (ODSE-only)
-- Agent R4-J.  UID block 22049000-22049999.
-- =====================================================================
-- Branch: aw/remove-nrt-shortcut. This fixture authors ONLY NBS_ODSE
-- rows. NO nrt_* INSERTs, NO EXEC sp_*, NO liquibase/seed/SRTE edits.
-- The real pipeline (CDC/Debezium -> kafka-connect sink ->
-- reporting-pipeline-service page builder; orchestrator Step 8.5
-- sp_sld_investigation_repeat_postprocessing over $PHC_UIDS) turns these
-- ODSE repeating-block answers into D_INVESTIGATION_REPEAT columns.
--
-- TARGET
--   dbo.D_INVESTIGATION_REPEAT (245 cols). At fixture-authoring time the
--   committed corpus populates 121/245; 124 remain NULL. This fixture
--   targets ~79 of those NULL columns via FOUR additional non-excluded
--   page-builder forms that currently have NO investigation in the corpus.
--
-- WHY THESE FORMS (live survey 2026-06-03 against the running stack)
--   sp_sld_investigation_repeat_postprocessing (routine 010, line 91)
--   EXCLUDES the legacy single-page forms (INV_FORM_BMD*, INV_FORM_GEN,
--   INV_FORM_HEP*, INV_FORM_MEA, INV_FORM_PER, INV_FORM_RUB,
--   INV_FORM_RVCT, INV_FORM_VAR) and pivots repeating-block answers
--   (answer_group_seq_nbr 1/2/3) of NON-excluded page-builder forms.
--   Prior agent R4-H filled TB_LTBI (502582) + Trichinellosis (10270).
--   Marginal NULL-column survey of the remaining mapped, non-excluded
--   forms (distinct D_INVESTIGATION_REPEAT cols still NULL):
--     PG_STEC_Investigation_(PB)        39  <-- authored here
--     PG_Cyclosporiasis_Investigation   33  <-- authored here
--     PG_Malaria_Investigation          24  <-- authored here
--     PG_Salmonellosis_(PB)             14  <-- authored here
--   These four share several LAB_*/RSK_RSNT_*/RSK_STORE_* repeating
--   columns; the DISTINCT union of their NULL columns is 81. Subtract the
--   2 SP-gated NUMERIC+unit_type_cd='CODED' questions that routine 010's
--   pivot cannot land (TRV_DURATION_OUTSIDE_US q 10006160 shared across
--   all four; CLN_ADVERSE_EVNT_ONSET q 10008164 on Malaria) => ~79
--   columns expected to fill.
--
-- R4-H "Malaria is SEED-GATED" CLAIM CORRECTED (live-verified 2026-06-03):
--   R4-H's fixture comment said PG_Malaria_Investigation has NO
--   Condition_code row. That is FALSE in this seed. Both
--   NBS_SRTE.dbo.Condition_code AND the pipeline's routing copy
--   RDB_MODERN.dbo.nrt_srte_Condition_code map condition_cd 10130 ->
--   investigation_form_cd 'PG_Malaria_Investigation', and the form's
--   ui/rdb metadata is seeded (24 D_INVESTIGATION_REPEAT repeat columns
--   resolve). Malaria is therefore IN BOUNDS and is authored here.
--
-- CONDITION -> FORM mappings used (all present in the baked seed; the
-- fixtures-only rule is respected — NO SRTE edits, these already exist):
--   115631 -> PG_STEC_Investigation_(PB)        (STEC (PB),     prog GCD)
--   115751 -> PG_Cyclosporiasis_Investigation   (Cyclospora,    prog GCD)
--   502651 -> PG_Salmonellosis_(PB)             (Salmonellosis, prog GCD)
--   10130  -> PG_Malaria_Investigation          (Malaria,       prog MAL)
--
-- WHAT THIS FIXTURE AUTHORS (ODSE-only, additive)
--   FOUR NEW page-builder investigations, each a minimal Tier-1-shaped
--   ODSE chain + repeating-block nbs_case_answer rows:
--     - act (CASE/EVN) + public_health_case + act_id (PHC_LOCAL_ID)
--     - participation SubjOfPHC -> foundation patient 20000000 (so
--       nrt_investigation.patient_id is non-NULL; page-builder/datamart
--       path is not silently dropped)
--     - case_management (minimal, IDENTITY_INSERT)
--     - nbs_case_answer rows: one per (question x answer_group_seq_nbr in
--       {1,2,3}). answer_group_seq_nbr 1/2/3 is what makes routine 010
--       treat these as REPEATING-block answers (it requires
--       answer_group_seq_nbr IS NOT NULL AND question_group_seq_nbr IS
--       NOT NULL; the repeating questions carry question_group_seq_nbr in
--       ODSE ui_metadata). NULL group-seq would route to the single
--       D_INV_* dims instead (LESSON 9).
--   The CDC pipeline mirrors public_health_case -> nrt_investigation
--   (investigation_form_cd resolved from condition_code) and the service
--   builds nrt_page_case_answer from nbs_case_answer, resolving each
--   answer's rdb_table_nm/rdb_column_nm by joining nbs_question_uid to the
--   form's seed ui/rdb metadata (already seeded for these forms). Step 8.5
--   then pivots them into D_INVESTIGATION_REPEAT.
--
-- VALUE FIDELITY: coded answers use real codes resolved live from each
--   question's code_set_group_id; dates/text/numeric are realistic
--   literals. NUMERIC+LITERAL questions (e.g. Malaria CLN_HSPTL_DUR_DAYS,
--   LAB_PARASITEMIA_LVL_PCT, TRT_MEDICATION_DURATION) DO pivot (routine
--   010's numeric branch accepts unit_type_cd NULL/'LITERAL').
--
-- KNOWN UNFILLABLE (authored for completeness, NOT counted in expected):
--   - TRV_DURATION_OUTSIDE_US (q 10006160) — NUMERIC unit_type_cd='CODED';
--     routine 010 numeric branch needs unit NULL/LITERAL, coded-numeric
--     branch needs investigation_form_cd IS NULL -> cannot pivot on a
--     named form. Shared across all four forms.
--   - CLN_ADVERSE_EVNT_ONSET (q 10008164, Malaria) — same NUMERIC+CODED.
--
-- ORCH_TODO (REQUIRED for these to populate):
--   Add 22049000, 22049200, 22049400, 22049500 to PHC_UIDS in
--   testing-tools/synthetic-odse-fixtures/scripts/merge_and_verify.sh so the
--   Step-8.5 sp_sld_investigation_repeat_postprocessing @phc_id_list
--   includes them. Without this the SP never sees the new PHCs.
--
-- UID block (reserved 22049000-22049999 in catalog/uid_ranges.md, R4-J):
--   22049000              STEC          act/public_health_case
--   22049001              STEC          case_management
--   22049010-22049126     STEC          nbs_case_answer (38 q x 3 = 114)
--   22049200              Cyclosporiasis act/public_health_case
--   22049201              Cyclosporiasis case_management
--   22049210-22049308     Cyclosporiasis nbs_case_answer (33 q x 3 = 99)
--   22049400              Salmonellosis act/public_health_case
--   22049401              Salmonellosis case_management
--   22049410-22049454     Salmonellosis nbs_case_answer (15 q x 3 = 45)
--   22049500              Malaria       act/public_health_case
--   22049501              Malaria       case_management
--   22049510-22049581     Malaria       nbs_case_answer (24 q x 3 = 72)
--
-- Foundation deps (read-only): patient 20000000, superuser 10009282.
-- =====================================================================

USE [NBS_ODSE];
GO

-- =====================================================================
-- 1) STEC investigation — PHC 22049000, condition 115631 ->
--    PG_STEC_Investigation_(PB)
-- =====================================================================
DECLARE @su   bigint   = 10009282;
DECLARE @t    datetime = '2026-04-03T00:00:00';
DECLARE @stec bigint   = 22049000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @stec)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@stec, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@stec, @t, @su, N'I',
         N'C', N'115631', N'STEC (PB)', N'NND', N'NND',
         N'O', CAST(GETDATE() AS DATE), @su, N'CAS22049000GA01',
         N'OPEN', @t, N'A', @t,
         N'T', 1, N'GCD', N'130001',
         @stec, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@stec, 1, @t, @su,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @su, N'ACTIVE',
         @t, N'CAS22049000GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @t);

    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @stec, N'SubjOfPHC', N'CASE', @t, @su,
         CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, N'A', @t, N'PSN',
         N'Subject of Public Health Case');

    SET IDENTITY_INSERT [dbo].[case_management] ON;
    INSERT INTO [dbo].[case_management]
        ([case_management_uid],[public_health_case_uid],[status_900],
         [field_record_number],[surv_assigned_date],[surv_closed_date],[case_closed_date])
    VALUES
        (22049001, @stec, N'C', N'FRN-STEC-01', @t, @t, @t);
    SET IDENTITY_INSERT [dbo].[case_management] OFF;
END
GO

-- STEC repeating-block answers (answer_group_seq_nbr 1/2/3).
DECLARE @su   bigint   = 10009282;
DECLARE @t    datetime = '2026-04-03T00:00:00';
DECLARE @stec bigint   = 22049000;

-- nbs_case_answer_uid is IDENTITY; let it AUTO-assign (LESSON 10:
-- hardcoded IDENTITY_INSERT UIDs collide with the auto-IDENTITY flood and
-- the guard silently skips the whole INSERT). Guard on the natural key.
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @stec AND nbs_question_uid = 10013307 AND answer_group_seq_nbr = 1)
BEGIN
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid],[add_time],[add_user_id],[answer_txt],
     [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
     [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
     [answer_group_seq_nbr])
VALUES
    -- LAB_CDC_LAB_CONFIRMED (q 10013307, CODED YNU csg 4150)
    (@stec,@t,@su,N'N',10013307,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Y',10013307,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'N',10013307,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_LAB_OTHER_DETAILS (q 10013308, TEXT)
    (@stec,@t,@su,N'State PHL confirmation pending',10013308,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Reflex culture performed',10013308,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Shiga toxin EIA positive',10013308,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_ORGANISM_TST_RSLT (q 10013304, CODED csg 120950)
    (@stec,@t,@su,N'131260002',10013304,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'131260002',10013304,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'131260002',10013304,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_PULSENET_ID (q 10013563, TEXT)
    (@stec,@t,@su,N'PNUSAE001234',10013563,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'PNUSAE001235',10013563,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'PNUSAE001236',10013563,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_STATE_LAB_CONFIRMED (q 10013306, CODED csg 4150)
    (@stec,@t,@su,N'Y',10013306,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Y',10013306,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'N',10013306,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_TEST_METHOD (q 10010294, CODED csg 114070)
    (@stec,@t,@su,N'FDD_A_10',10010294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'FDD_A_10',10010294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'FDD_A_10',10010294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_TEST_RESULT_TEXT (q 10013305, TEXT)
    (@stec,@t,@su,N'O157:H7 detected',10013305,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'stx1+ stx2+',10013305,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Non-O157 STEC',10013305,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ATE_FD_PRCH_FRM_STORE (q 10013295, TEXT)
    (@stec,@t,@su,N'Ground beef',10013295,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Bagged spinach',10013295,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Romaine lettuce',10013295,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ATE_ICEBERG_BRANDS_HM (q 10013529, TEXT)
    (@stec,@t,@su,N'Brand A',10013529,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Brand B',10013529,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Store brand',10013529,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ATE_ICEBRG_OTS_HM_LOC (q 10013531, TEXT)
    (@stec,@t,@su,N'Deli counter',10013531,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Salad bar',10013531,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Restaurant',10013531,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ATE_ROMAIN_OTS_HM_LOC (q 10013539, TEXT)
    (@stec,@t,@su,N'Fast food',10013539,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Cafeteria',10013539,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Catered event',10013539,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ATE_ROMAINE_BRANDS_HM (q 10013537, TEXT)
    (@stec,@t,@su,N'Fresh Express',10013537,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Dole',10013537,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Bulk',10013537,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ATE_SPINACH_BRANDS_HM (q 10013545, TEXT)
    (@stec,@t,@su,N'Earthbound',10013545,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Taylor Farms',10013545,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Organic Girl',10013545,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ATE_SPINCH_OTS_HM_LOC (q 10013547, TEXT)
    (@stec,@t,@su,N'Buffet',10013547,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Wedding',10013547,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Picnic',10013547,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ATE_SPROUT_PRCHSE_LOC (q 10013552, TEXT)
    (@stec,@t,@su,N'Farmers market',10013552,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Grocery',10013552,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Co-op',10013552,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ATE_SPROUTS_BRANDS (q 10013551, TEXT)
    (@stec,@t,@su,N'Alfalfa fresh',10013551,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Mung local',10013551,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Clover mix',10013551,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_FOOD_ATE_RSTURNT_DT (q 10013303, DATE)
    (@stec,@t,@su,N'2026-03-01',10013303,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'2026-03-03',10013303,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'2026-03-05',10013303,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_FOOD_EATEN_RESTAURANT (q 10013302, TEXT)
    (@stec,@t,@su,N'Cheeseburger',10013302,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Caesar salad',10013302,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Steak tartare',10013302,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_FD_ATE_OTS_HM_NM (q 10013555, TEXT)
    (@stec,@t,@su,N'Diner on Main',10013555,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Grill House',10013555,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Taco stand',10013555,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_FOOD_ATE_HM_NAMES (q 10013554, TEXT)
    (@stec,@t,@su,N'Home kitchen',10013554,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'BBQ at home',10013554,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Family dinner',10013554,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_GRND_BEEF_ATE_HM (q 10013505, TEXT)
    (@stec,@t,@su,N'Home',10013505,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Home',10013505,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Relative home',10013505,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_GRND_BEEF_OTS_HM (q 10013507, TEXT)
    (@stec,@t,@su,N'Burger joint',10013507,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Food truck',10013507,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Pub',10013507,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_STEAK_ATE_HM (q 10013510, TEXT)
    (@stec,@t,@su,N'Home',10013510,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Home',10013510,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Home',10013510,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_STEAK_ATE_OTS_HM (q 10013512, TEXT)
    (@stec,@t,@su,N'Steakhouse',10013512,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Bistro',10013512,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Hotel',10013512,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_OTH_TYPE_LEAFY_GREEN (q 10013549, TEXT)
    (@stec,@t,@su,N'Kale',10013549,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Arugula',10013549,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Spring mix',10013549,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_RSNT_ADDR_FD_PRCHSE (q 10013299, TEXT)
    (@stec,@t,@su,N'100 Main St',10013299,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'200 Oak Ave',10013299,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'300 Pine Rd',10013299,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_RSNT_CTY_EXP_OCCURRED (q 10013300, TEXT)
    (@stec,@t,@su,N'Atlanta',10013300,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Decatur',10013300,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Marietta',10013300,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_RSNT_NM_EXP_OCCURRED (q 10013298, TEXT)
    (@stec,@t,@su,N'The Grill',10013298,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Cafe One',10013298,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Diner Two',10013298,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_RSNT_STATE_EXP_OCCRD (q 10013301, CODED state csg 3920)
    (@stec,@t,@su,N'13',10013301,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'13',10013301,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'01',10013301,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_SHOPPER_CARD_NUMBER (q 10013296, TEXT)
    (@stec,@t,@su,N'SC-001122',10013296,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'SC-334455',10013296,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'SC-667788',10013296,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_STORE_ADDR_FOOD_PRCH (q 10013291, TEXT)
    (@stec,@t,@su,N'10 Market St',10013291,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'20 Grocery Ln',10013291,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'30 Super Way',10013291,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_STORE_CITY_FD_PRCHSE (q 10013292, TEXT)
    (@stec,@t,@su,N'Atlanta',10013292,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Athens',10013292,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Macon',10013292,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_STORE_NM_FOOD_PRCHSE (q 10013290, TEXT)
    (@stec,@t,@su,N'MegaMart',10013290,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'FreshCo',10013290,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'CornerStore',10013290,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_STORE_SHOPPED_DATE (q 10013294, DATE)
    (@stec,@t,@su,N'2026-02-25',10013294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'2026-02-26',10013294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'2026-02-27',10013294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_STORE_STATE_FD_PRCHSE (q 10013293, CODED state csg 3920)
    (@stec,@t,@su,N'13',10013293,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'13',10013293,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'01',10013293,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_TREAT_WTR_FAC_LOC (q 10013498, TEXT)
    (@stec,@t,@su,N'City reservoir',10013498,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Municipal supply',10013498,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Treated well',10013498,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_TYPE_DRIED_MEAT (q 10013516, TEXT)
    (@stec,@t,@su,N'Beef jerky',10013516,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Venison jerky',10013516,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Biltong',10013516,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_UNTREAT_WTR_FAC_LOC (q 10013500, TEXT)
    (@stec,@t,@su,N'Farm pond',10013500,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'Creek',10013500,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'Lake',10013500,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRV_DURATION_OUTSIDE_US (q 10006160, NUMERIC unit_type_cd=CODED ->
    --   SP-gated; authored for completeness, NOT counted)
    (@stec,@t,@su,N'10',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@stec,@t,@su,N'14',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@stec,@t,@su,N'7',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3);
END
GO

-- =====================================================================
-- 2) Cyclosporiasis investigation — PHC 22049200, condition 115751 ->
--    PG_Cyclosporiasis_Investigation
-- =====================================================================
DECLARE @su   bigint   = 10009282;
DECLARE @t    datetime = '2026-04-03T00:00:00';
DECLARE @cyc  bigint   = 22049200;

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @cyc)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@cyc, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@cyc, @t, @su, N'I',
         N'C', N'115751', N'Cyclosporiasis (PB)', N'NND', N'NND',
         N'O', CAST(GETDATE() AS DATE), @su, N'CAS22049200GA01',
         N'OPEN', @t, N'A', @t,
         N'T', 1, N'GCD', N'130001',
         @cyc, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@cyc, 1, @t, @su,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @su, N'ACTIVE',
         @t, N'CAS22049200GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @t);

    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @cyc, N'SubjOfPHC', N'CASE', @t, @su,
         CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, N'A', @t, N'PSN',
         N'Subject of Public Health Case');

    SET IDENTITY_INSERT [dbo].[case_management] ON;
    INSERT INTO [dbo].[case_management]
        ([case_management_uid],[public_health_case_uid],[status_900],
         [field_record_number],[surv_assigned_date],[surv_closed_date],[case_closed_date])
    VALUES
        (22049201, @cyc, N'C', N'FRN-CYC-01', @t, @t, @t);
    SET IDENTITY_INSERT [dbo].[case_management] OFF;
END
GO

DECLARE @su   bigint   = 10009282;
DECLARE @t    datetime = '2026-04-03T00:00:00';
DECLARE @cyc  bigint   = 22049200;

-- nbs_case_answer_uid is IDENTITY; let it AUTO-assign (LESSON 10:
-- hardcoded IDENTITY_INSERT UIDs collide with the auto-IDENTITY flood and
-- the guard silently skips the whole INSERT). Guard on the natural key.
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @cyc AND nbs_question_uid = 10013307 AND answer_group_seq_nbr = 1)
BEGIN
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid],[add_time],[add_user_id],[answer_txt],
     [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
     [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
     [answer_group_seq_nbr])
VALUES
    -- LAB_CDC_LAB_CONFIRMED (q 10013307, CODED csg 4150)
    (@cyc,@t,@su,N'N',10013307,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Y',10013307,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'N',10013307,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_LAB_OTHER_DETAILS (q 10013308, TEXT)
    (@cyc,@t,@su,N'Ova and parasite exam',10013308,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'PCR confirmed',10013308,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Acid-fast stain positive',10013308,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_ORGANISM_TST_RSLT (q 10013304, CODED csg 119380)
    (@cyc,@t,@su,N'103560006',10013304,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'103560006',10013304,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'103560006',10013304,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_STATE_LAB_CONFIRMED (q 10013306, CODED csg 4150)
    (@cyc,@t,@su,N'Y',10013306,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Y',10013306,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'N',10013306,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_TEST_METHOD (q 10010294, CODED csg 119080)
    (@cyc,@t,@su,N'FDD_A_10',10010294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'FDD_A_10',10010294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'FDD_A_10',10010294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_TEST_RESULT_TEXT (q 10013305, TEXT)
    (@cyc,@t,@su,N'Oocysts seen',10013305,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Autofluorescence +',10013305,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Cyclospora cayetanensis',10013305,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ATE_FD_PRCH_FRM_STORE (q 10013295, TEXT)
    (@cyc,@t,@su,N'Fresh basil',10013295,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Raspberries',10013295,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Snow peas',10013295,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_DATE_OF_EVENT (q 10013158, DATE)
    (@cyc,@t,@su,N'2026-03-02',10013158,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'2026-03-04',10013158,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'2026-03-06',10013158,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_EVENT_SPECIFY (q 10013157, TEXT)
    (@cyc,@t,@su,N'Catered lunch',10013157,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Office party',10013157,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Wedding reception',10013157,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_FOOD_ATE_RSTURNT_DT (q 10013303, DATE)
    (@cyc,@t,@su,N'2026-03-01',10013303,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'2026-03-03',10013303,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'2026-03-05',10013303,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_FOOD_EATEN_RESTAURANT (q 10013302, TEXT)
    (@cyc,@t,@su,N'Salad with herbs',10013302,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Berry parfait',10013302,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Pesto pasta',10013302,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_FRESH_BERRIES (q 10013174, TEXT)
    (@cyc,@t,@su,N'Grocery A',10013174,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Farmers market',10013174,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Imported brand',10013174,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_FRESH_FRUIT (q 10013240, TEXT)
    (@cyc,@t,@su,N'Supermarket',10013240,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Roadside stand',10013240,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Co-op',10013240,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_FRESH_HERB (q 10013191, TEXT)
    (@cyc,@t,@su,N'Specialty grocer',10013191,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Garden center',10013191,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Restaurant supply',10013191,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_FRESH_LETTUCE (q 10013213, TEXT)
    (@cyc,@t,@su,N'Big box store',10013213,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Local market',10013213,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Salad bar',10013213,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_ONION (q 10013262, TEXT)
    (@cyc,@t,@su,N'Grocery B',10013262,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Wholesale',10013262,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Market stall',10013262,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_OTHER_PRODUCE (q 10013288, TEXT)
    (@cyc,@t,@su,N'Mixed greens vendor',10013288,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Organic shop',10013288,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'CSA box',10013288,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_PEAS (q 10013269, TEXT)
    (@cyc,@t,@su,N'Frozen aisle',10013269,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Fresh produce',10013269,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Imported',10013269,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_PEPPERS (q 10013247, TEXT)
    (@cyc,@t,@su,N'Grocery C',10013247,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Market',10013247,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Farm box',10013247,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_ROOT_VEG (q 10013254, TEXT)
    (@cyc,@t,@su,N'Supermarket',10013254,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Co-op',10013254,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Farm stand',10013254,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_LOC_TOMATOES (q 10013276, TEXT)
    (@cyc,@t,@su,N'Grocery D',10013276,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Greenhouse',10013276,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Vine ripened brand',10013276,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_RSNT_ADDR_FD_PRCHSE (q 10013299, TEXT)
    (@cyc,@t,@su,N'400 Elm St',10013299,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'500 Maple Dr',10013299,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'600 Birch Ln',10013299,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_RSNT_CTY_EXP_OCCURRED (q 10013300, TEXT)
    (@cyc,@t,@su,N'Savannah',10013300,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Augusta',10013300,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Columbus',10013300,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_RSNT_NM_EXP_OCCURRED (q 10013298, TEXT)
    (@cyc,@t,@su,N'Garden Bistro',10013298,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Fresh Cafe',10013298,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Green Table',10013298,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_RSNT_STATE_EXP_OCCRD (q 10013301, CODED state csg 3920)
    (@cyc,@t,@su,N'13',10013301,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'13',10013301,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'01',10013301,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_SHOPPER_CARD_NUMBER (q 10013296, TEXT)
    (@cyc,@t,@su,N'SC-991122',10013296,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'SC-883344',10013296,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'SC-775566',10013296,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_STORE_ADDR_FOOD_PRCH (q 10013291, TEXT)
    (@cyc,@t,@su,N'15 Produce Way',10013291,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'25 Fresh Blvd',10013291,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'35 Market Sq',10013291,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_STORE_CITY_FD_PRCHSE (q 10013292, TEXT)
    (@cyc,@t,@su,N'Atlanta',10013292,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Savannah',10013292,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Athens',10013292,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_STORE_NM_FOOD_PRCHSE (q 10013290, TEXT)
    (@cyc,@t,@su,N'GreenGrocer',10013290,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'ProduceMart',10013290,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'FarmFresh',10013290,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_STORE_SHOPPED_DATE (q 10013294, DATE)
    (@cyc,@t,@su,N'2026-02-22',10013294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'2026-02-23',10013294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'2026-02-24',10013294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_STORE_STATE_FD_PRCHSE (q 10013293, CODED state csg 3920)
    (@cyc,@t,@su,N'13',10013293,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'13',10013293,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'01',10013293,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRV_DURATION_OUTSIDE_US (q 10006160, NUMERIC unit_type_cd=CODED ->
    --   SP-gated; authored for completeness, NOT counted)
    (@cyc,@t,@su,N'12',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'9',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'5',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRV_TRAVEL_CITY (q 10013161, TEXT)
    (@cyc,@t,@su,N'Cancun',10013161,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@cyc,@t,@su,N'Lima',10013161,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@cyc,@t,@su,N'Guatemala City',10013161,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3);
END
GO

-- =====================================================================
-- 3) Salmonellosis investigation — PHC 22049400, condition 502651 ->
--    PG_Salmonellosis_(PB)
-- =====================================================================
DECLARE @su   bigint   = 10009282;
DECLARE @t    datetime = '2026-04-03T00:00:00';
DECLARE @sal  bigint   = 22049400;

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @sal)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@sal, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@sal, @t, @su, N'I',
         N'C', N'502651', N'Salmonellosis (PB)', N'NND', N'NND',
         N'O', CAST(GETDATE() AS DATE), @su, N'CAS22049400GA01',
         N'OPEN', @t, N'A', @t,
         N'T', 1, N'GCD', N'130001',
         @sal, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@sal, 1, @t, @su,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @su, N'ACTIVE',
         @t, N'CAS22049400GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @t);

    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @sal, N'SubjOfPHC', N'CASE', @t, @su,
         CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, N'A', @t, N'PSN',
         N'Subject of Public Health Case');

    SET IDENTITY_INSERT [dbo].[case_management] ON;
    INSERT INTO [dbo].[case_management]
        ([case_management_uid],[public_health_case_uid],[status_900],
         [field_record_number],[surv_assigned_date],[surv_closed_date],[case_closed_date])
    VALUES
        (22049401, @sal, N'C', N'FRN-SAL-01', @t, @t, @t);
    SET IDENTITY_INSERT [dbo].[case_management] OFF;
END
GO

DECLARE @su   bigint   = 10009282;
DECLARE @t    datetime = '2026-04-03T00:00:00';
DECLARE @sal  bigint   = 22049400;

-- nbs_case_answer_uid is IDENTITY; let it AUTO-assign (LESSON 10:
-- hardcoded IDENTITY_INSERT UIDs collide with the auto-IDENTITY flood and
-- the guard silently skips the whole INSERT). Guard on the natural key.
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @sal AND nbs_question_uid = 10013307 AND answer_group_seq_nbr = 1)
BEGIN
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid],[add_time],[add_user_id],[answer_txt],
     [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
     [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
     [answer_group_seq_nbr])
VALUES
    -- LAB_CDC_LAB_CONFIRMED (q 10013307, CODED csg 4150)
    (@sal,@t,@su,N'N',10013307,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'Y',10013307,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'N',10013307,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_LAB_OTHER_DETAILS (q 10013308, TEXT)
    (@sal,@t,@su,N'Stool culture',10013308,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'Serotyped at state lab',10013308,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'Blood culture positive',10013308,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_ORGANISM_TST_RSLT (q 10013304, CODED csg 120860)
    (@sal,@t,@su,N'1009003',10013304,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'1009003',10013304,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'1009003',10013304,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_PULSENET_ID (q 10013563, TEXT)
    (@sal,@t,@su,N'PNUSAS012345',10013563,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'PNUSAS012346',10013563,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'PNUSAS012347',10013563,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_STATE_LAB_CONFIRMED (q 10013306, CODED csg 4150)
    (@sal,@t,@su,N'Y',10013306,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'Y',10013306,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'N',10013306,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_TEST_METHOD (q 10010294, CODED csg 114070)
    (@sal,@t,@su,N'FDD_A_10',10010294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'FDD_A_10',10010294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'FDD_A_10',10010294,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_TEST_RESULT_TEXT (q 10013305, TEXT)
    (@sal,@t,@su,N'Salmonella Enteritidis',10013305,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'Salmonella Typhimurium',10013305,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'Group B',10013305,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ANIMAL_CONTACT_FDD (q 10013590, CODED csg 4150)
    (@sal,@t,@su,N'Y',10013590,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'N',10013590,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'Y',10013590,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ANIMAL_CONTACT_WHEN_B (q 10013591, TEXT)
    (@sal,@t,@su,N'One week before onset',10013591,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'Two days before',10013591,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'Same week',10013591,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ANIMAL_EXPOSURE_SALM (q 10013588, CODED csg 120270)
    (@sal,@t,@su,N'2773008',10013588,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'2773008',10013588,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'2773008',10013588,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ANIMAL_TYPE_OTH_SALM (q 10013589, TEXT)
    (@sal,@t,@su,N'Backyard chickens',10013589,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'Pet turtle',10013589,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'Bearded dragon',10013589,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- RSK_ANIMALCONTACT_WHERE_B (q 10013592, TEXT)
    (@sal,@t,@su,N'Home coop',10013592,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'Petting zoo',10013592,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'Farm visit',10013592,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRV_PATIENTTRAVEL (q 10001080, CODED csg 4150)
    (@sal,@t,@su,N'N',10001080,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'Y',10001080,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'N',10001080,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRV_DURATION_OUTSIDE_US (q 10006160, NUMERIC unit_type_cd=CODED ->
    --   SP-gated; authored for completeness, NOT counted)
    (@sal,@t,@su,N'8',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@sal,@t,@su,N'15',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@sal,@t,@su,N'4',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3);
END
GO

-- =====================================================================
-- 4) Malaria investigation — PHC 22049500, condition 10130 ->
--    PG_Malaria_Investigation
--    (R4-H "SEED-GATED" claim corrected: mapping 10130 -> form is
--    present in both NBS_SRTE.dbo.Condition_code and the pipeline's
--    routing copy RDB_MODERN.dbo.nrt_srte_Condition_code.)
-- =====================================================================
DECLARE @su   bigint   = 10009282;
DECLARE @t    datetime = '2026-04-03T00:00:00';
DECLARE @mal  bigint   = 22049500;

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @mal)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@mal, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@mal, @t, @su, N'I',
         N'C', N'10130', N'Malaria', N'NND', N'NND',
         N'O', CAST(GETDATE() AS DATE), @su, N'CAS22049500GA01',
         N'OPEN', @t, N'A', @t,
         N'T', 1, N'MAL', N'130001',
         @mal, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@mal, 1, @t, @su,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @su, N'ACTIVE',
         @t, N'CAS22049500GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @t);

    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @mal, N'SubjOfPHC', N'CASE', @t, @su,
         CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, N'A', @t, N'PSN',
         N'Subject of Public Health Case');

    SET IDENTITY_INSERT [dbo].[case_management] ON;
    INSERT INTO [dbo].[case_management]
        ([case_management_uid],[public_health_case_uid],[status_900],
         [field_record_number],[surv_assigned_date],[surv_closed_date],[case_closed_date])
    VALUES
        (22049501, @mal, N'C', N'FRN-MAL-01', @t, @t, @t);
    SET IDENTITY_INSERT [dbo].[case_management] OFF;
END
GO

DECLARE @su   bigint   = 10009282;
DECLARE @t    datetime = '2026-04-03T00:00:00';
DECLARE @mal  bigint   = 22049500;

-- nbs_case_answer_uid is IDENTITY; let it AUTO-assign (LESSON 10:
-- hardcoded IDENTITY_INSERT UIDs collide with the auto-IDENTITY flood and
-- the guard silently skips the whole INSERT). Guard on the natural key.
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @mal AND nbs_question_uid = 10008136 AND answer_group_seq_nbr = 1)
BEGIN
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid],[add_time],[add_user_id],[answer_txt],
     [nbs_question_uid],[nbs_question_version_ctrl_nbr],[last_chg_time],
     [last_chg_user_id],[record_status_cd],[record_status_time],[seq_nbr],
     [answer_group_seq_nbr])
VALUES
    -- CLN_ADMISSION_DATE (q 10008136, DATE)
    (@mal,@t,@su,N'2026-03-08',10008136,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'2026-03-10',10008136,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'2026-03-12',10008136,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- CLN_ADMITTED_AS_INPATIENT (q 10008134, CODED csg 4150)
    (@mal,@t,@su,N'Y',10008134,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'N',10008134,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'Y',10008134,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- CLN_ADVERSE_EVNT_ONSET (q 10008164, NUMERIC unit_type_cd=CODED ->
    --   SP-gated; authored for completeness, NOT counted)
    (@mal,@t,@su,N'3',10008164,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'5',10008164,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'2',10008164,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- CLN_ADVERSE_EVNT_SEVERITY (q 10008165, CODED csg 112460)
    (@mal,@t,@su,N'399166001',10008165,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'399166001',10008165,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'399166001',10008165,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- CLN_ADVERSE_EVT_RLTD_TRMT (q 10008163, CODED csg 4150)
    (@mal,@t,@su,N'Y',10008163,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'N',10008163,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'Y',10008163,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- CLN_DISCHARGE_DATE (q 10008137, DATE)
    (@mal,@t,@su,N'2026-03-15',10008137,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'2026-03-17',10008137,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'2026-03-19',10008137,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- CLN_HOSPITAL_NAME (q 10008135, TEXT)
    (@mal,@t,@su,N'County General',10008135,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'University Hospital',10008135,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'Regional Medical Center',10008135,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- CLN_HOSPITAL_RECORD_NBR (q 10008139, TEXT)
    (@mal,@t,@su,N'MRN-001',10008139,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'MRN-002',10008139,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'MRN-003',10008139,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- CLN_HSPTL_DUR_DAYS (q 10008138, NUMERIC unit_type_cd=LITERAL -> pivots)
    (@mal,@t,@su,N'7',10008138,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'5',10008138,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'10',10008138,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- CLN_MAL_PREVIOUS_SPECIES (q 10008150, CODED csg 112150)
    (@mal,@t,@su,N'18508006',10008150,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'18508006',10008150,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'18508006',10008150,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- CMP_ADVERSE_EVNT_DESC (q 10008162, TEXT)
    (@mal,@t,@su,N'Nausea and vomiting',10008162,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'Headache',10008162,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'Dizziness',10008162,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_ORGANISM_NAME (q 10006163, CODED csg 112150)
    (@mal,@t,@su,N'18508006',10006163,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'18508006',10006163,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'18508006',10006163,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_PARASITEMIA_LVL_PCT (q 10006164, NUMERIC unit_type_cd=LITERAL -> pivots)
    (@mal,@t,@su,N'2',10006164,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'5',10006164,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'1',10006164,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_PERFORMING_LAB_NAME (q 10007151, TEXT)
    (@mal,@t,@su,N'State Public Health Lab',10007151,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'Hospital Lab',10007151,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'Reference Lab',10007151,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- LAB_PHONE_NUMBER (q 10008140, TEXT)
    (@mal,@t,@su,N'404-555-0101',10008140,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'404-555-0102',10008140,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'404-555-0103',10008140,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRT_MALARIA_INFO (q 10008151, CODED csg 112470)
    (@mal,@t,@su,N'10395',10008151,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'10395',10008151,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'10395',10008151,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRT_MED_ADMST_RELTVE_TRT (q 10008158, CODED csg 112520)
    (@mal,@t,@su,N'PHC2145',10008158,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'PHC2145',10008158,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'PHC2145',10008158,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRT_MEDICATION_ADMSTRD (q 10008157, TEXT)
    (@mal,@t,@su,N'Chloroquine',10008157,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'Artemether-lumefantrine',10008157,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'Atovaquone-proguanil',10008157,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRT_MEDICATION_DURATION (q 10008161, NUMERIC unit_type_cd=LITERAL -> pivots)
    (@mal,@t,@su,N'3',10008161,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'7',10008161,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'5',10008161,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRT_MEDICATION_START_DT (q 10008159, DATE)
    (@mal,@t,@su,N'2026-03-08',10008159,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'2026-03-09',10008159,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'2026-03-10',10008159,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRT_MEDICATION_STOP_DATE (q 10008160, DATE)
    (@mal,@t,@su,N'2026-03-11',10008160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'2026-03-16',10008160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'2026-03-15',10008160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRT_TREATMENT_END_DT (q 10008152, DATE)
    (@mal,@t,@su,N'2026-03-12',10008152,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'2026-03-17',10008152,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'2026-03-16',10008152,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRV_DURATION_OUTSIDE_US (q 10006160, NUMERIC unit_type_cd=CODED ->
    --   SP-gated; authored for completeness, NOT counted)
    (@mal,@t,@su,N'21',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'30',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'14',10006160,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3),
    -- TRV_TRAVEL_RETURN_DT (q 10005162, DATE)
    (@mal,@t,@su,N'2026-02-28',10005162,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,1,1),
    (@mal,@t,@su,N'2026-02-25',10005162,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,2,2),
    (@mal,@t,@su,N'2026-02-20',10005162,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE',@t,3,3);
END
GO
