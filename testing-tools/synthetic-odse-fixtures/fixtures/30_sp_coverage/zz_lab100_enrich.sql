-- =====================================================================
-- Tier 3 ENRICHMENT — LAB100 column expansion (ODSE-ONLY, NO-SHORTCUT)
-- =====================================================================
-- Branch aw/remove-nrt-shortcut: this fixture authors ONLY NBS_ODSE rows
-- (act / observation / obs_value_* / act_relationship / act_id /
-- participation / role). The REAL pipeline (CDC/Debezium -> kafka-connect
-- -> nrt_observation* ; service sp_observation_event ; orchestrator
-- run_lab_chain sp_d_lab_test_postprocessing + sp_d_labtest_result_postprocessing ;
-- Step-9 sp_lab100_datamart_postprocessing) derives the LAB_TEST /
-- LAB_TEST_RESULT / LAB_RESULT_VAL / LAB_RESULT_COMMENT /
-- TEST_RESULT_GROUPING / RESULT_COMMENT_GROUP rows in RDB_MODERN.
-- NO RDB_MODERN INSERT, NO EXEC sp_, NO liquibase/seed/SRTE edits.
--
-- ---------------------------------------------------------------------
-- WHAT THIS FIXTURE DOES (marginal value over zz_lab100_101_fill Part A)
-- ---------------------------------------------------------------------
-- zz_lab100_101_fill.sql Part A already authors ONE fully-attributed
-- LAB100 Order+Result (Hep A IgM, LOINC 13950-1) ODSE-only, lighting up
-- the PATIENT_* / PROVIDER_* / ORDERING_FACILITY / REPORTING_FACILITY* /
-- ACCESSION_NBR / RESULT_REF_RANGE / coded+numeric result columns. This
-- enrich fixture is NOT redundant with it: it adds TWO further condition
-- variants (RPR/Syphilis LOINC 86592-1; ANA LOINC 5048-4) AND exercises
-- two LAB100 source columns Part A omits:
--   * REASON_FOR_TEST_DESC/CD  <- observation_reason (Order)
--   * LAB_RESULT_COMMENTS      <- 2nd obs_value_txt txt_type_cd='N'
--                                 (017 #TMP_Lab_Result_Comment requires
--                                  ovt_txt_type_cd='N' AND ovt_seq<>0)
-- Plus observation_interp (abnormal/normal result interpretation).
--
-- Each pair is a full ODSE Lab observation hierarchy modeled line-for-line
-- on zz_lab100_101_fill.sql Part A:
--   act (class_cd='OBS', mood_cd='EVN') x2 (Order + Result)
--   observation Order  (obs_domain_cd_st_1='Order',  ctrl_cd_display_form='LabReport')
--   observation Result (obs_domain_cd_st_1='Result', ctrl_cd_display_form='LabReport')
--   act_relationship type_cd='COMP' (source=Result, target=Order)
--   act_id OBS_LOCAL_ID + FILLER (-> ACCESSION_NBR feed)
--   obs_value_coded   (-> TEST_RESULT_VAL_CD/DESC + alt codes)
--   obs_value_numeric (-> numeric result + ref range)
--   obs_value_txt FT seq 1 (-> LAB_RESULT_TXT_VAL)
--   obs_value_txt N  seq 2 (-> LAB_RESULT_COMMENTS)
--   observation_interp / observation_reason
--   participations on Order: PATSBJ, ORD(person), VRF, AUT(org), ORD(org), SPP
--   participation  on Result: PRF(org)
--   role SPP (scoping PSN) for the specimen collector
--
-- Foundation dependencies (read-only; same rows the fill fixture uses):
--   @pat_uid  20000000  D_PATIENT key 4    (rich demographics)
--   @prov_uid 20000010  D_PROVIDER key 12  (rich address/phone)
--   @org_uid  20000020  D_ORGANIZATION key 7 (CLIA/name/phone)
--
-- UID block (this fixture): 22021000-22021999.
--   22021010 act/observation  Order  #1 (RPR  86592-1)
--   22021011 act/observation  Result #1
--   22021020 act/observation  Order  #2 (ANA  5048-4)
--   22021021 act/observation  Result #2
--
-- SEED NOTE (DOCUMENT, do NOT fix): LOINC 86592-1 (RPR) and 5048-4 (ANA)
-- are NOT in NBS_SRTE.dbo.Loinc_condition (verified 0 rows each). All
-- condition joins in 017/018/019 are LEFT joins, so the LAB100 rows still
-- materialize; only CONDITION_CD / CONDITION_SHORT_NM / PROGRAM_AREA_* stay
-- NULL for these two rows. Those columns are already non-NULL on the Hep A
-- fill row, so no coverage is lost. Seeding the LOINC map is an SRTE edit =
-- OUT OF BOUNDS (cf. bug #16 covid_lab 11065 seed gap).
--
-- ORCH_TODO (REQUIRED — the lab SPs only process UIDs in the orchestrator
--   lists; this fixture does NOT tail-EXEC):
--   1. scripts/merge_and_verify.sh run_lab_chain() (~lines 322-324): add
--        22021010,22021011,22021020,22021021
--      to the sp_observation_event @obs_id_list AND to both postprocessing
--      @obs_ids lists (sp_d_lab_test_postprocessing + sp_d_labtest_result_postprocessing).
--   2. scripts/merge_and_verify.sh LAB_OBS_UIDS (~line 486): add the two
--      Result test UIDs the lab100 datamart SP keys on:
--        22021011,22021021
--
-- IDEMPOTENCY: whole body guarded by IF NOT EXISTS on the first act_uid
-- (22021010). Safe to re-run; second invocation is a no-op.
-- =====================================================================

USE [NBS_ODSE];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- ----- read-only foundation references -----
DECLARE @superuser_id bigint = 10009282;
DECLARE @pat_uid      bigint = 20000000;   -- D_PATIENT key 4
DECLARE @prov_uid     bigint = 20000010;   -- D_PROVIDER key 12
DECLARE @org_uid      bigint = 20000020;   -- D_ORGANIZATION key 7

-- ----- pair UIDs -----
DECLARE @rpr_order  bigint = 22021010;
DECLARE @rpr_result bigint = 22021011;
DECLARE @ana_order  bigint = 22021020;
DECLARE @ana_result bigint = 22021021;

IF NOT EXISTS (SELECT 1 FROM [dbo].[act] WHERE act_uid = @rpr_order)
BEGIN
    -- =================================================================
    -- act parents (Order + Result for both pairs)
    -- =================================================================
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES
        (@rpr_order,  N'OBS', N'EVN'),
        (@rpr_result, N'OBS', N'EVN'),
        (@ana_order,  N'OBS', N'EVN'),
        (@ana_result, N'OBS', N'EVN');

    -- =================================================================
    -- ORDER observations
    -- =================================================================
    INSERT INTO [dbo].[observation]
        ([observation_uid],[add_time],[add_user_id],[cd],[cd_desc_txt],
         [cd_system_cd],[cd_system_desc_txt],[alt_cd],[alt_cd_desc_txt],
         [alt_cd_system_cd],[alt_cd_system_desc_txt],
         [last_chg_time],[last_chg_user_id],[local_id],
         [obs_domain_cd_st_1],[obs_domain_cd],[ctrl_cd_display_form],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [subject_person_uid],[shared_ind],[version_ctrl_nbr],
         [prog_area_cd],[jurisdiction_cd],[program_jurisdiction_oid],
         [electronic_ind],[activity_to_time],[effective_from_time],
         [rpt_to_state_time],[activity_from_time],[method_cd],[method_desc_txt],
         [target_site_cd],[target_site_desc_txt],[txt],[priority_cd],
         [processing_decision_cd])
    VALUES
        (@rpr_order, '2026-04-22T08:00:00', @superuser_id,
         N'86592-1', N'Rapid plasma reagin (RPR) test',
         N'2.16.840.1.113883.6.1', N'LN', N'ALT-RPR-1', N'RPR Card (Locally Coded)',
         N'L', N'Local',
         CAST(GETDATE() AS DATE), @superuser_id, N'OBS22021010GA01',
         N'Order', N'Order', N'LabReport',
         N'ACTIVE', '2026-04-22T08:00:00', N'A', '2026-04-22T08:00:00',
         @pat_uid, N'T', 1,
         N'STD', N'130001', 22021010,
         N'Y', '2026-04-22T08:00:00', '2026-04-21T18:00:00',
         '2026-04-22T10:00:00', '2026-04-21T18:00:00', N'RPR', N'Rapid Plasma Reagin',
         N'SER', N'Serum', N'RPR enrich Order — syphilis screen, high-risk contact.', N'R',
         N'AC'),
        (@ana_order, '2026-04-23T08:00:00', @superuser_id,
         N'5048-4', N'ANA — antinuclear antibody titer',
         N'2.16.840.1.113883.6.1', N'LN', N'ALT-ANA-1', N'ANA Titer (Locally Coded)',
         N'L', N'Local',
         CAST(GETDATE() AS DATE), @superuser_id, N'OBS22021020GA01',
         N'Order', N'Order', N'LabReport',
         N'ACTIVE', '2026-04-23T08:00:00', N'A', '2026-04-23T08:00:00',
         @pat_uid, N'T', 1,
         N'STD', N'130001', 22021020,
         N'Y', '2026-04-23T08:00:00', '2026-04-22T18:00:00',
         '2026-04-23T10:00:00', '2026-04-22T18:00:00', N'ANA-IF', N'Antinuclear Antibody — Indirect Immunofluorescence',
         N'SER', N'Serum', N'ANA enrich Order — auto-immune workup, rule out SLE.', N'R',
         N'AC');

    -- =================================================================
    -- RESULT observations (children)
    -- =================================================================
    INSERT INTO [dbo].[observation]
        ([observation_uid],[add_time],[add_user_id],[cd],[cd_desc_txt],
         [cd_system_cd],[cd_system_desc_txt],
         [last_chg_time],[last_chg_user_id],[local_id],
         [obs_domain_cd_st_1],[obs_domain_cd],[ctrl_cd_display_form],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [subject_person_uid],[shared_ind],[version_ctrl_nbr],
         [prog_area_cd],[jurisdiction_cd],[program_jurisdiction_oid],
         [electronic_ind],[activity_to_time],[effective_from_time])
    VALUES
        (@rpr_result, '2026-04-22T09:00:00', @superuser_id,
         N'86592-1', N'Rapid plasma reagin (RPR) test',
         N'2.16.840.1.113883.6.1', N'LN',
         CAST(GETDATE() AS DATE), @superuser_id, N'OBS22021011GA01',
         N'Result', N'Result', N'LabReport',
         N'ACTIVE', '2026-04-22T09:00:00', N'A', '2026-04-22T09:00:00',
         @pat_uid, N'T', 1,
         N'STD', N'130001', 22021010,
         N'Y', '2026-04-22T09:00:00', '2026-04-21T18:00:00'),
        (@ana_result, '2026-04-23T09:00:00', @superuser_id,
         N'5048-4', N'ANA — antinuclear antibody titer',
         N'2.16.840.1.113883.6.1', N'LN',
         CAST(GETDATE() AS DATE), @superuser_id, N'OBS22021021GA01',
         N'Result', N'Result', N'LabReport',
         N'ACTIVE', '2026-04-23T09:00:00', N'A', '2026-04-23T09:00:00',
         @pat_uid, N'T', 1,
         N'STD', N'130001', 22021020,
         N'Y', '2026-04-23T09:00:00', '2026-04-22T18:00:00');

    -- =================================================================
    -- act_relationship: Result -> Order (Lab-internal COMP, child source)
    -- =================================================================
    INSERT INTO [dbo].[act_relationship]
        ([source_act_uid],[target_act_uid],[type_cd],[add_time],[add_user_id],
         [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
         [sequence_nbr],[source_class_cd],[target_class_cd],[status_cd],[status_time],
         [type_desc_txt])
    VALUES
        (@rpr_result, @rpr_order, N'COMP', '2026-04-22T09:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-22T09:00:00',
         1, N'OBS', N'OBS', N'A', '2026-04-22T09:00:00', N'Component'),
        (@ana_result, @ana_order, N'COMP', '2026-04-23T09:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-23T09:00:00',
         1, N'OBS', N'OBS', N'A', '2026-04-23T09:00:00', N'Component');

    -- =================================================================
    -- act_relationship: Lab Order -> Investigation (LabReport cross-subject)
    -- Wires associated_phc_uids in nrt_observation so sp_observation_event
    -- projects the investigation uid and RDB_MODERN LAB100 populates.
    -- Both STD labs link to investigation 22004000 (STD dedicated entities).
    -- =================================================================
    INSERT INTO [dbo].[act_relationship]
        ([source_act_uid],[target_act_uid],[type_cd],[add_time],[add_user_id],
         [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
         [sequence_nbr],[source_class_cd],[target_class_cd],[status_cd],[status_time],
         [type_desc_txt])
    VALUES
        (@rpr_order, 22004000, N'LabReport', '2026-04-22T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-22T08:00:00',
         1, N'OBS', N'CASE', N'A', '2026-04-22T08:00:00', N'Lab Report'),
        (@ana_order, 22004000, N'LabReport', '2026-04-23T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-23T08:00:00',
         1, N'OBS', N'CASE', N'A', '2026-04-23T08:00:00', N'Lab Report');

        -- Bump observation change time after wiring LabReport edges so CDC emits
        -- an observation change event that sees the cross-subject CASE link.
        UPDATE [dbo].[observation]
             SET [last_chg_time] = DATEADD(SECOND, 1, [last_chg_time])
         WHERE [observation_uid] IN (@rpr_order, @ana_order);

    -- =================================================================
    -- act_id on each Order: OBS_LOCAL_ID + FILLER (-> ACCESSION_NBR)
    -- =================================================================
    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
         [root_extension_txt],[type_cd],[type_desc_txt],[status_cd],[status_time])
    VALUES
        (@rpr_order, 1, '2026-04-22T08:00:00', @superuser_id,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-22T08:00:00',
         N'OBS22021010GA01', N'OBS_LOCAL_ID', N'Local Observation Identifier', N'A', '2026-04-22T08:00:00'),
        (@rpr_order, 2, '2026-04-22T08:00:00', @superuser_id,
         N'2.16.840.1.113883.4.6', N'NPI Filler',
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-22T08:00:00',
         N'ACC-V2-22021010', N'FILLER', N'Filler Order Number', N'A', '2026-04-22T08:00:00'),
        (@ana_order, 1, '2026-04-23T08:00:00', @superuser_id,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-23T08:00:00',
         N'OBS22021020GA01', N'OBS_LOCAL_ID', N'Local Observation Identifier', N'A', '2026-04-23T08:00:00'),
        (@ana_order, 2, '2026-04-23T08:00:00', @superuser_id,
         N'2.16.840.1.113883.4.6', N'NPI Filler',
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-23T08:00:00',
         N'ACC-V2-22021020', N'FILLER', N'Filler Order Number', N'A', '2026-04-23T08:00:00');

    -- =================================================================
    -- obs_value_coded on each Result -> TEST_RESULT_VAL_CD/DESC + alt codes
    -- =================================================================
    INSERT INTO [dbo].[obs_value_coded]
        ([observation_uid],[code],[code_system_cd],[code_system_desc_txt],
         [display_name],[alt_cd],[alt_cd_desc_txt],[alt_cd_system_cd],[alt_cd_system_desc_txt])
    VALUES
        (@rpr_result, N'10828004', N'2.16.840.1.113883.6.96', N'SCT',
         N'Positive', N'POS', N'Positive', N'L', N'Local'),
        (@ana_result, N'260385009', N'2.16.840.1.113883.6.96', N'SCT',
         N'Negative', N'NEG', N'Negative', N'L', N'Local');

    -- =================================================================
    -- obs_value_numeric on each Result -> numeric result + ref range
    -- =================================================================
    INSERT INTO [dbo].[obs_value_numeric]
        ([observation_uid],[obs_value_numeric_seq],[comparator_cd_1],
         [numeric_value_1],[numeric_unit_cd],[low_range],[high_range])
    VALUES
        (@rpr_result, 1, N'=', 32.00, N'titer', N'Non-reactive', N'1:8'),
        (@ana_result, 1, N'<', 40.00, N'titer', N'<1:40', N'1:40');

    -- =================================================================
    -- obs_value_txt: FT seq 1 (-> LAB_RESULT_TXT_VAL),
    --                N  seq 2 (-> LAB_RESULT_COMMENTS, 017 ovt_type='N')
    -- =================================================================
    INSERT INTO [dbo].[obs_value_txt]
        ([observation_uid],[obs_value_txt_seq],[txt_type_cd],[value_txt])
    VALUES
        (@rpr_result, 1, N'FT', N'Reactive at 1:32 — non-treponemal screen positive; recommend FTA-ABS / TP-PA confirmation.'),
        (@rpr_result, 2, N'N',  N'RPR positive at 1:32. Recommend FTA-ABS or TP-PA confirmation. Patient counseling per CDC syphilis guidelines.'),
        (@ana_result, 1, N'FT', N'Non-reactive — ANA undetected at screening titer (<1:40).'),
        (@ana_result, 2, N'N',  N'ANA non-reactive. Auto-immune disease unlikely; consider alternate dx for joint symptoms.');

    -- =================================================================
    -- observation_interp on each Result
    -- =================================================================
    INSERT INTO [dbo].[observation_interp]
        ([observation_uid],[interpretation_cd],[interpretation_desc_txt])
    VALUES
        (@rpr_result, N'A', N'Abnormal'),
        (@ana_result, N'N', N'Normal');

    -- =================================================================
    -- observation_reason on each Order -> REASON_FOR_TEST_DESC/CD
    -- =================================================================
    INSERT INTO [dbo].[observation_reason]
        ([observation_uid],[reason_cd],[reason_desc_txt])
    VALUES
        (@rpr_order, N'SCRN', N'Syphilis screening — high-risk contact'),
        (@ana_order, N'SYMP', N'Auto-immune workup — joint pain + rash');

    -- =================================================================
    -- Participations on each ORDER:
    --   persons: PATSBJ (patient), ORD (ordering provider), VRF (interpreter)
    --   orgs:    AUT (reporting lab), ORD (ordering org)
    --   SPP:     specimen collector (paired with role row below)
    -- =================================================================
    INSERT INTO [dbo].[participation]
        ([subject_entity_uid],[act_uid],[type_cd],[act_class_cd],[add_time],[add_user_id],
         [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
         [status_cd],[status_time],[subject_class_cd],[type_desc_txt])
    VALUES
        -- RPR Order
        (@pat_uid,  @rpr_order, N'PATSBJ', N'OBS', '2026-04-22T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-22T08:00:00',
         N'A', '2026-04-22T08:00:00', N'PSN', N'Patient Subject'),
        (@prov_uid, @rpr_order, N'ORD',    N'OBS', '2026-04-22T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-22T08:00:00',
         N'A', '2026-04-22T08:00:00', N'PSN', N'Ordering Provider'),
        (@prov_uid, @rpr_order, N'VRF',    N'OBS', '2026-04-22T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-22T08:00:00',
         N'A', '2026-04-22T08:00:00', N'PSN', N'Result Interpreter'),
        (@org_uid,  @rpr_order, N'AUT',    N'OBS', '2026-04-22T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-22T08:00:00',
         N'A', '2026-04-22T08:00:00', N'ORG', N'Author/Reporting Organization'),
        (@org_uid,  @rpr_order, N'ORD',    N'OBS', '2026-04-22T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-22T08:00:00',
         N'A', '2026-04-22T08:00:00', N'ORG', N'Ordering Organization'),
        (@prov_uid, @rpr_order, N'SPP',    N'OBS', '2026-04-22T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-22T08:00:00',
         N'A', '2026-04-22T08:00:00', N'PROV', N'Specimen Collector'),
        -- ANA Order
        (@pat_uid,  @ana_order, N'PATSBJ', N'OBS', '2026-04-23T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-23T08:00:00',
         N'A', '2026-04-23T08:00:00', N'PSN', N'Patient Subject'),
        (@prov_uid, @ana_order, N'ORD',    N'OBS', '2026-04-23T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-23T08:00:00',
         N'A', '2026-04-23T08:00:00', N'PSN', N'Ordering Provider'),
        (@prov_uid, @ana_order, N'VRF',    N'OBS', '2026-04-23T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-23T08:00:00',
         N'A', '2026-04-23T08:00:00', N'PSN', N'Result Interpreter'),
        (@org_uid,  @ana_order, N'AUT',    N'OBS', '2026-04-23T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-23T08:00:00',
         N'A', '2026-04-23T08:00:00', N'ORG', N'Author/Reporting Organization'),
        (@org_uid,  @ana_order, N'ORD',    N'OBS', '2026-04-23T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-23T08:00:00',
         N'A', '2026-04-23T08:00:00', N'ORG', N'Ordering Organization'),
        (@prov_uid, @ana_order, N'SPP',    N'OBS', '2026-04-23T08:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-23T08:00:00',
         N'A', '2026-04-23T08:00:00', N'PROV', N'Specimen Collector');

    -- Performing org (PRF) on each RESULT
    INSERT INTO [dbo].[participation]
        ([subject_entity_uid],[act_uid],[type_cd],[act_class_cd],[add_time],[add_user_id],
         [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
         [status_cd],[status_time],[subject_class_cd],[type_desc_txt])
    VALUES
        (@org_uid, @rpr_result, N'PRF', N'OBS', '2026-04-22T09:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-22T09:00:00',
         N'A', '2026-04-22T09:00:00', N'ORG', N'Performing Organization'),
        (@org_uid, @ana_result, N'PRF', N'OBS', '2026-04-23T09:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-23T09:00:00',
         N'A', '2026-04-23T09:00:00', N'ORG', N'Performing Organization');

    -- Specimen-collector role (SPP scoping PSN). ProcessObservationDataUtil
    -- maps role SPP/PSN -> specimen_collector_id. Reuses the same provider
    -- the fill fixture authors; guarded so it no-ops if already present.
    IF NOT EXISTS (SELECT 1 FROM dbo.role WHERE subject_entity_uid = @prov_uid AND cd = N'SPP' AND role_seq = 1)
        INSERT INTO [dbo].[role]
            ([subject_entity_uid],[cd],[role_seq],[add_time],[add_user_id],[cd_desc_txt],
             [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
             [scoping_class_cd],[scoping_entity_uid],[status_cd],[status_time],[subject_class_cd])
        VALUES
            (@prov_uid, N'SPP', 1, '2026-04-22T08:00:00', @superuser_id, N'Specimen Collector',
             CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-22T08:00:00',
             N'PSN', @pat_uid, N'A', '2026-04-22T08:00:00', N'PROV');
END
GO
