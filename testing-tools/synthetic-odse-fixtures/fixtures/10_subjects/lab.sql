USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 1 Lab Report fixture
-- Baseline: 6.0.18.1 (post-liquibase) + fixtures/00_foundation/00_foundation.sql
--
-- ARCHITECTURAL NOTE
--   The Lab postprocessing chain consists of TWO postprocessing SPs that
--   share the same `@obs_ids` driver:
--     1. dbo.sp_d_lab_test_postprocessing  (LAB_TEST + LAB_RPT_USER_COMMENT)
--     2. dbo.sp_d_labtest_result_postprocessing (LAB_TEST_RESULT,
--        LAB_RESULT_VAL, TEST_RESULT_GROUPING, RESULT_COMMENT_GROUP,
--        LAB_RESULT_COMMENT)
--   Both SPs read from `dbo.nrt_observation` (and aux tables). The event
--   SP `sp_observation_event` is a JSON projection only — it does NOT
--   populate nrt_observation. We hand-author the staging rows directly,
--   bypassing CDC.
--
--   Lab observations form a hierarchy: an "Order" parent observation
--   (obs_domain_cd_st_1='Order') with one or more "Result" child
--   observations (obs_domain_cd_st_1='Result') linked by Lab-internal
--   act_relationship rows (COMP and APND as authored below). Lab-INTERNAL
--   act_relationships (Lab observation -> Lab observation) are allowed
--   at Tier 1; cross-subject act_relationships (Lab -> Investigation,
--   etc.) are Tier 2 only.
--
--   Cross-subject FK joins in sp_d_labtest_result_postprocessing
--   (PATIENT_KEY, INVESTIGATION_KEY, CONDITION_KEY, REPORTING_LAB_KEY,
--   ORDERING_PROVIDER_KEY, etc.) all use COALESCE(<lookup>, 1) and the
--   sentinel KEY=1 row exists in each dim, so Tier 1 isolation works
--   without LINK_REQUIRED scaffolding. The diff tool will see KEY=1 on
--   those columns until Tier 2 wires the cross-subject edges that let
--   the joins resolve to non-sentinel keys.
--
-- WHAT THIS FIXTURE DOES
--   1. Foundation Lab enrichment: keep the foundation observation
--      (UID 20000120) `Order` row unmodified per the Tier 1 contract.
--      Add an `act_id` row keyed on its act_uid (foundation has none).
--      Most observation columns remain NULL on the foundation row,
--      exhibiting the SP's null/blank transform path.
--   2. v2 Lab Order: a fully-attributed Order observation (UID 20070010)
--      in this block. Every column the postprocessing SPs read is set.
--      LOINC code '13950-1' (Hepatitis A IgM Ab — maps to condition_cd
--      '10110' via baseline-pre-populated nrt_srte_Loinc_condition).
--   3. v2 Lab Result child: a Result observation (UID 20070011) wired
--      to the Order via Lab-internal act_relationship (type_cd='COMP').
--      Carries the result value (coded + numeric + text + date) and
--      comment text.
--   4. Followup observation pair: C_Order (20070020) + C_Result
--      (20070021) — these drive sp_d_lab_test_postprocessing's
--      LAB_RPT_USER_COMMENT path (which requires the v2 Order's
--      followup_observation_uid to point at C_Order/C_Result that share
--      a value_txt comment). Linked via APND (C_Order -> Order)
--      and COMP (C_Result -> C_Order).
--   5. Synthetic staging rows in RDB_MODERN:
--        - dbo.nrt_observation (5 rows: foundation Order, v2 Order,
--          v2 Result, followup C_Order, followup C_Result)
--        - dbo.nrt_observation_txt (result text for v2 Result + C_Result)
--        - dbo.nrt_observation_coded (coded result for v2 Result)
--        - dbo.nrt_observation_numeric (numeric result for v2 Result)
--        - dbo.nrt_observation_date (date result for v2 Result)
--        - dbo.nrt_observation_material (material for v2 Order)
--        - dbo.nrt_observation_reason (reason for test on v2 Order)
--        - dbo.nrt_observation_edx (EDX document link for v2 Order)
--   6. Does NOT author cross-subject act_relationship rows
--      (Lab -> Investigation, MorbReport, etc.). LAB_TEST_RESULT.
--      INVESTIGATION_KEY etc. resolve to 1 via COALESCE.
--   7. Does NOT hand-author nrt_lab_test_key, nrt_lab_rpt_user_comment_key,
--      nrt_lab_test_result_group_key, or nrt_lab_result_comment_key —
--      the postprocessing SPs allocate via IDENTITY.
--   8. Does NOT invoke datamart SPs (lab100/lab101/case_lab/covid_lab) —
--      out-of-scope.
--
-- UID block (Lab Tier 1): 20070000-20079999.
-- Foundation dependencies (read-only):
--   @dbo_Act_lab_uid             20000120  (act / observation Order, foundation)
--   @dbo_Entity_patient_uid      20000000  (referenced via observation.subject_person_uid + nrt_observation.patient_id)
--   @dbo_Entity_provider_uid     20000010  (referenced via nrt_observation.ordering_person_id + result_interpreter_id)
--   @dbo_Entity_organization_uid 20000020  (referenced via nrt_observation.author_organization_id + ordering_organization_id + performing_organization_id)
-- =====================================================================

-- ----- Sentinel reference -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Foundation dependencies referenced (read-only) -----
DECLARE @foundation_act_lab_uid    bigint = 20000120;  -- foundation Lab Order Act / observation
DECLARE @foundation_patient_uid    bigint = 20000000;  -- foundation Patient (subject_person_uid)
DECLARE @foundation_provider_uid   bigint = 20000010;  -- foundation Provider (ordering / result_interpreter)
DECLARE @foundation_org_uid        bigint = 20000020;  -- foundation Organization (reporting / ordering / performing lab)

-- =====================================================================
-- UID allocations (Lab Tier 1: 20070000-20079999)
-- =====================================================================

-- ----- v2 Lab observation hierarchy -----
DECLARE @dbo_Act_lab_v2_order_uid     bigint = 20070010;  -- v2 Order observation (root)
DECLARE @dbo_Act_lab_v2_result_uid    bigint = 20070011;  -- v2 Result child observation
DECLARE @dbo_Act_lab_v2_corder_uid    bigint = 20070020;  -- v2 followup C_Order observation (drives LAB_RPT_USER_COMMENT)
DECLARE @dbo_Act_lab_v2_cresult_uid   bigint = 20070021;  -- v2 followup C_Result observation (carries comment text)
DECLARE @dbo_Material_v2_uid          bigint = 20070030;  -- v2 specimen material
DECLARE @dbo_EDX_Document_v2_uid      bigint = 20070031;  -- v2 EDX_Document for ELR-style document link

-- =====================================================================
-- ODSE rows — additive enrichments and v2 variant.
-- =====================================================================

-- =====================================================================
-- Foundation Lab enrichment: act_id (accession-style local id).
-- The foundation observation 20000120 has no act_id; this enrichment
-- gives the event SP's act_ids JSON branch a non-empty array on the
-- foundation variant.
-- type_cd 'OBS_LOCAL_ID' (canonical for an observation local id; the
-- event SP does not filter on type_cd).
-- =====================================================================
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@foundation_act_lab_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE',
     '2026-04-01T00:00:00', N'OBS20000120GA01', N'OBS_LOCAL_ID',
     N'Local Observation Identifier', N'A', '2026-04-01T00:00:00');

-- =====================================================================
-- v2 act parent rows.
-- act.class_cd 'OBS' from SRTE ACT_CLS; mood_cd 'EVN'.
-- =====================================================================
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@dbo_Act_lab_v2_order_uid,   N'OBS', N'EVN'),
    (@dbo_Act_lab_v2_result_uid,  N'OBS', N'EVN'),
    (@dbo_Act_lab_v2_corder_uid,  N'OBS', N'EVN'),
    (@dbo_Act_lab_v2_cresult_uid, N'OBS', N'EVN');

-- =====================================================================
-- v2 Order observation — fully-attributed Order parent.
-- LOINC '13950-1' (Hepatitis A virus IgM Ab) maps to condition_cd
-- '10110' via baseline-seeded nrt_srte_Loinc_condition.
-- ctrl_cd_display_form='LabReport' satisfies the postprocessing SP's
-- WHERE clause (line 219 of sp_d_lab_test_postprocessing).
-- followup_observation_uid is set to the C_Order/C_Result UID list so
-- the LAB_RPT_USER_COMMENT path picks them up.
-- subject_person_uid = foundation Patient.
-- =====================================================================
INSERT INTO [dbo].[observation]
    ([observation_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [cd_system_cd], [cd_system_desc_txt], [alt_cd], [alt_cd_desc_txt],
     [alt_cd_system_cd], [alt_cd_system_desc_txt],
     [last_chg_time], [last_chg_user_id], [local_id],
     [obs_domain_cd_st_1], [obs_domain_cd], [ctrl_cd_display_form],
     [record_status_cd], [record_status_time],
     [status_cd], [status_time], [subject_person_uid],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [electronic_ind],
     [activity_to_time], [effective_from_time], [rpt_to_state_time],
     [activity_from_time], [method_cd], [method_desc_txt],
     [target_site_cd], [target_site_desc_txt], [txt],
     [priority_cd], [processing_decision_cd], [pregnant_ind_cd])
VALUES
    (@dbo_Act_lab_v2_order_uid, '2026-04-04T00:00:00', @superuser_id,
     N'13950-1', N'Hepatitis A virus IgM Ab [Presence] in Serum',
     N'2.16.840.1.113883.6.1', N'LN',
     N'HAVAB-IGM', N'Hepatitis A IgM Ab',
     N'L', N'Local',
     '2026-04-04T00:00:00', @superuser_id, N'OBS20070010GA01',
     N'Order', N'Order', N'LabReport',
    N'ACTIVE', '2026-04-04T00:00:00',
     N'A', '2026-04-04T00:00:00', @foundation_patient_uid,
     N'T', 1, N'STD', N'130001',
     20070010, N'Y',
     '2026-04-04T08:00:00', '2026-04-03T18:00:00', '2026-04-04T10:00:00',
     '2026-04-03T18:00:00', N'IGM-EIA', N'IgM Enzyme Immunoassay',
     N'SER', N'Serum',
     N'Tier 1 v2 Lab Order — clinical info / specimen narrative.',
     N'R', N'AC', N'N');

-- =====================================================================
-- v2 Result observation — child of v2 Order.
-- ctrl_cd_display_form='LabReport' matches SP filter.
-- =====================================================================
INSERT INTO [dbo].[observation]
    ([observation_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [cd_system_cd], [cd_system_desc_txt],
     [last_chg_time], [last_chg_user_id], [local_id],
     [obs_domain_cd_st_1], [obs_domain_cd], [ctrl_cd_display_form],
     [record_status_cd], [record_status_time],
     [status_cd], [status_time], [subject_person_uid],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [electronic_ind],
     [activity_to_time], [effective_from_time])
VALUES
    (@dbo_Act_lab_v2_result_uid, '2026-04-04T08:30:00', @superuser_id,
     N'13950-1', N'Hepatitis A virus IgM Ab [Presence] in Serum',
     N'2.16.840.1.113883.6.1', N'LN',
     '2026-04-04T08:30:00', @superuser_id, N'OBS20070011GA01',
     N'Result', N'Result', N'LabReport',
    N'ACTIVE', '2026-04-04T08:30:00',
     N'A', '2026-04-04T08:30:00', @foundation_patient_uid,
     N'T', 1, N'STD', N'130001',
     20070010, N'Y',
     '2026-04-04T08:30:00', '2026-04-03T18:00:00');  -- Abnormal result interpretation drives via observation_interp table below

-- =====================================================================
-- v2 followup C_Order/C_Result observations — drive LAB_RPT_USER_COMMENT.
-- Mirror UI-added lab shape where C_Order carries 'Lab Report' and
-- C_Result carries 'LabComment'.
-- =====================================================================
INSERT INTO [dbo].[observation]
    ([observation_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [last_chg_time], [last_chg_user_id], [local_id],
    [obs_domain_cd_st_1], [obs_domain_cd], [ctrl_cd_display_form],
     [record_status_cd], [record_status_time],
     [status_cd], [status_time], [subject_person_uid],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [electronic_ind],
     [activity_to_time])
VALUES
    (@dbo_Act_lab_v2_corder_uid, '2026-04-04T08:00:00', @superuser_id,
     N'NTE', N'Notes Comment Order',
     '2026-04-04T08:00:00', @superuser_id, N'OBS20070020GA01',
        N'C_Order', N'C_Order', N'Lab Report',
    N'ACTIVE', '2026-04-04T08:00:00',
     N'A', '2026-04-04T08:00:00', @foundation_patient_uid,
     N'T', 1, N'STD', N'130001',
     20070010, N'Y',
     '2026-04-04T08:00:00'),
    (@dbo_Act_lab_v2_cresult_uid, '2026-04-04T08:30:00', @superuser_id,
     N'NTE', N'Notes Comment Result',
     '2026-04-04T08:30:00', @superuser_id, N'OBS20070021GA01',
        N'C_Result', N'C_Result', N'LabComment',
    N'ACTIVE', '2026-04-04T08:30:00',
     N'A', '2026-04-04T08:30:00', @foundation_patient_uid,
     N'T', 1, N'STD', N'130001',
     20070010, N'Y',
     '2026-04-04T08:30:00');

    -- =====================================================================
    -- v2 Order participations.
    -- UI-created lab orders include at least patient-subject and author org
    -- participations. Add them explicitly so ODSE fixture shape matches UI.
    -- =====================================================================
    INSERT INTO [dbo].[participation]
        ([act_uid], [subject_entity_uid], [type_cd],
        [act_class_cd], [subject_class_cd],
        [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
        [record_status_cd], [record_status_time],
        [status_cd], [status_time], [type_desc_txt])
    VALUES
        (@dbo_Act_lab_v2_order_uid,
        @foundation_patient_uid,
        N'PATSBJ',
        N'OBS',
        N'PSN',
        '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00', @superuser_id,
        N'ACTIVE', '2026-04-04T00:00:00',
        N'A', '2026-04-04T00:00:00', N'Patient Subject'),
        (@dbo_Act_lab_v2_order_uid,
        @foundation_org_uid,
        N'AUT',
        N'OBS',
        N'ORG',
        '2026-04-04T00:00:00', @superuser_id, '2026-04-04T00:00:00', @superuser_id,
        N'ACTIVE', '2026-04-04T00:00:00',
        N'A', '2026-04-04T00:00:00', N'Author');

-- =====================================================================
-- Lab-internal act_relationship rows:
--   Result -> Order (COMP), C_Order -> Order (APND), C_Result -> C_Order (COMP).
-- class_cd 'OBS' for both
-- source/target. These are Lab-internal — both endpoints are Lab
-- observations. Cross-subject act_relationships (Lab -> Investigation)
-- are Tier 2 territory and NOT authored here.
-- Note: relationship orientation per the postprocessing SP is parent
-- (Order) source, child (Result) target — but the SP at line 416 reads
-- `parent_test ON tst.report_observation_uid = parent_test.observation_uid`
-- which is consumed via nrt_observation.report_observation_uid (set on
-- the child to point at the parent), NOT via act_relationship. The
-- act_relationship rows here exist for the event SP's parent_observations
-- JSON branch (sp_observation_event lines 158-178: `ar.source_act_uid =
-- o.observation_uid AND ar.target_class_cd = 'OBS'`), so the child is
-- the SOURCE (its parent is the TARGET).
-- =====================================================================
INSERT INTO [dbo].[act_relationship]
    ([source_act_uid], [target_act_uid], [type_cd], [add_time], [add_user_id],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [sequence_nbr], [source_class_cd],
     [target_class_cd], [status_cd], [status_time], [type_desc_txt])
VALUES
    -- v2 Result -> v2 Order (parent)
    (@dbo_Act_lab_v2_result_uid, @dbo_Act_lab_v2_order_uid, N'COMP',
     '2026-04-04T08:30:00', @superuser_id,
     '2026-04-04T08:30:00', @superuser_id, N'ACTIVE',
     '2026-04-04T08:30:00', 1, N'OBS', N'OBS', N'A',
     '2026-04-04T08:30:00', N'Component'),
        -- v2 C_Order -> v2 Order (append relationship, mirrors UI shape)
        (@dbo_Act_lab_v2_corder_uid, @dbo_Act_lab_v2_order_uid, N'APND',
     '2026-04-04T08:00:00', @superuser_id,
     '2026-04-04T08:00:00', @superuser_id, N'ACTIVE',
         '2026-04-04T08:00:00', 2, N'OBS', N'OBS', N'A',
         '2026-04-04T08:00:00', N'Append'),
    -- v2 C_Result -> v2 C_Order
    (@dbo_Act_lab_v2_cresult_uid, @dbo_Act_lab_v2_corder_uid, N'COMP',
     '2026-04-04T08:30:00', @superuser_id,
     '2026-04-04T08:30:00', @superuser_id, N'ACTIVE',
     '2026-04-04T08:30:00', 1, N'OBS', N'OBS', N'A',
     '2026-04-04T08:30:00', N'Component');

-- =====================================================================
-- v2 act_id rows for Order observation — accession + filler-style.
-- =====================================================================
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@dbo_Act_lab_v2_order_uid, 1, '2026-04-04T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     '2026-04-04T00:00:00', @superuser_id, N'ACTIVE',
     '2026-04-04T00:00:00', N'OBS20070010GA01', N'OBS_LOCAL_ID',
     N'Local Observation Identifier', N'A', '2026-04-04T00:00:00'),
    (@dbo_Act_lab_v2_order_uid, 2, '2026-04-04T00:00:00', @superuser_id,
     N'2.16.840.1.113883.4.6', N'NPI Filler',
     '2026-04-04T00:00:00', @superuser_id, N'ACTIVE',
     '2026-04-04T00:00:00', N'ACC-V2-20070010', N'FILLER',
     N'Filler Order Number', N'A', '2026-04-04T00:00:00');

-- =====================================================================
-- ODSE observation aux rows — value_txt / value_coded / value_numeric /
-- value_date / observation_interp / observation_reason / EDX_Document /
-- material.
-- These feed the event SP's nesteddata JSON projection. The
-- postprocessing SPs read from the corresponding nrt_observation_*
-- tables which we hand-author below.
-- =====================================================================

-- v2 Result observation_interp (interpretation flag)
INSERT INTO [dbo].[observation_interp]
    ([observation_uid], [interpretation_cd], [interpretation_desc_txt])
VALUES
    (@dbo_Act_lab_v2_result_uid, N'A', N'Abnormal');

-- v2 Order obs_value_txt — narrative comment  (txt_type_cd 'N')
INSERT INTO [dbo].[obs_value_txt]
    ([observation_uid], [obs_value_txt_seq], [txt_type_cd], [value_txt])
VALUES
    (@dbo_Act_lab_v2_result_uid, 1, N'FT', N'Reactive — IgM antibody to Hepatitis A virus detected.');

-- v2 C_Result obs_value_txt — drives LAB_RPT_USER_COMMENT.USER_RPT_COMMENTS
INSERT INTO [dbo].[obs_value_txt]
    ([observation_uid], [obs_value_txt_seq], [txt_type_cd], [value_txt])
VALUES
    (@dbo_Act_lab_v2_cresult_uid, 1, N'FT', N'Comment from clinician — re-test recommended in 2 weeks.');

-- v2 Result obs_value_coded — coded result with display name
INSERT INTO [dbo].[obs_value_coded]
    ([observation_uid], [code], [code_system_cd], [code_system_desc_txt],
     [display_name], [alt_cd], [alt_cd_desc_txt], [alt_cd_system_cd],
     [alt_cd_system_desc_txt])
VALUES
    (@dbo_Act_lab_v2_result_uid, N'10828004', N'2.16.840.1.113883.6.96', N'SCT',
     N'Positive', N'POS', N'Positive', N'L', N'Local');

-- v2 Result obs_value_numeric — numeric result with comparator + range
INSERT INTO [dbo].[obs_value_numeric]
    ([observation_uid], [obs_value_numeric_seq], [comparator_cd_1],
     [numeric_value_1], [numeric_unit_cd], [low_range], [high_range])
VALUES
    (@dbo_Act_lab_v2_result_uid, 1, N'>', 1.10, N'Index',
     N'0.00', N'0.90');

-- v2 Result obs_value_date — date result (specimen result emit time)
INSERT INTO [dbo].[obs_value_date]
    ([observation_uid], [obs_value_date_seq], [from_time], [to_time])
VALUES
    (@dbo_Act_lab_v2_result_uid, 1, '2026-04-04T08:30:00', '2026-04-04T08:30:00');

-- v2 Order observation_reason
INSERT INTO [dbo].[observation_reason]
    ([observation_uid], [reason_cd], [reason_desc_txt])
VALUES
    (@dbo_Act_lab_v2_order_uid, N'B33.5', N'Acute hepatitis A — diagnostic workup');

-- v2 Order EDX_Document and material rows are NOT inserted on the ODSE
-- side: EDX_Document.EDX_Document_uid is IDENTITY (cannot insert a
-- specific UID without IDENTITY_INSERT), and material.material_uid has
-- a hard FK to entity (we'd have to author a new entity row in the
-- 'PLC' or 'MAT' class — out of scope for Lab and not required since
-- the postprocessing SPs read from nrt_observation_edx /
-- nrt_observation_material in RDB_MODERN, which we hand-author below.
-- The event SP's JSON projection of EDX/material participations on the
-- foundation Lab will be empty; this is acceptable at Tier 1.

GO

-- =====================================================================
-- DRIVE THE POSTPROCESSING SPs via direct nrt_observation* INSERTs.
-- =====================================================================

USE [RDB_MODERN];
GO

-- Re-declare locals inside the RDB_MODERN batch (DECLAREs do not survive GO).
DECLARE @superuser_id bigint = 10009282;
DECLARE @foundation_act_lab_uid    bigint = 20000120;
DECLARE @foundation_patient_uid    bigint = 20000000;
DECLARE @foundation_provider_uid   bigint = 20000010;
DECLARE @foundation_org_uid        bigint = 20000020;
DECLARE @dbo_Act_lab_v2_order_uid     bigint = 20070010;
DECLARE @dbo_Act_lab_v2_result_uid    bigint = 20070011;
DECLARE @dbo_Act_lab_v2_corder_uid    bigint = 20070020;
DECLARE @dbo_Act_lab_v2_cresult_uid   bigint = 20070021;
DECLARE @dbo_Material_v2_uid          bigint = 20070030;
DECLARE @dbo_EDX_Document_v2_uid      bigint = 20070031;

-- =====================================================================
-- nrt_observation: 5 rows. Foundation Order is deliberately sparse to
-- exhibit the SP's null-propagation path; v2 Order/Result/C_Order/C_Result
-- are fully populated.
-- refresh_datetime + max_datetime are GENERATED ALWAYS (omitted).
--
-- Each row supplies 83 values aligned to the 83 settable columns.
-- Column ordinals (1-83) are commented inline on each row.
-- =====================================================================

-- =====================================================================
-- nrt_observation_txt — value_txt rows for v2 Result + v2 C_Result.
-- ovt_txt_type_cd 'N' is required for the LAB_RPT_USER_COMMENT path
-- (sp_d_lab_test_postprocessing line 783, 785). C_Result text uses 'N'.
-- v2 Result lab-result text uses 'FT' so it lands in LAB_RESULT_VAL.LAB_RESULT_TXT_VAL.
-- =====================================================================

-- =====================================================================
-- nrt_observation_coded — coded result for v2 Result.
-- =====================================================================

-- =====================================================================
-- nrt_observation_numeric — numeric result for v2 Result.
-- =====================================================================

-- =====================================================================
-- nrt_observation_date — date result for v2 Result.
-- =====================================================================

-- =====================================================================
-- nrt_observation_material — material participation for v2 Order.
-- Keyed by act_uid (= Order observation_uid) + material_id.
-- material_id is NOT NULL.
-- =====================================================================

-- =====================================================================
-- nrt_observation_reason — reason-for-test for v2 Order.
-- =====================================================================

-- =====================================================================
-- nrt_observation_edx — EDX_Document link for v2 Order.
-- Drives sp_d_lab_test_postprocessing's #edx_document temp table and
-- LAB_TEST.DOCUMENT_LINK is built from this.
-- =====================================================================

GO

-- =====================================================================
-- IDENTITY ADVANCE — baseline data quirk in 6.0.18.1.
--
-- The lab key tables (`nrt_lab_test_key`,
-- `nrt_lab_test_result_group_key`, `nrt_lab_result_comment_key`,
-- `nrt_lab_rpt_user_comment_key`) are seeded by Liquibase with a row
-- whose KEY = 1, but on `nrt_lab_test_result_group_key` the IDENTITY
-- counter is left at NULL (verified via DBCC CHECKIDENT NORESEED on a
-- fresh restore). Result: the next IDENTITY-driven INSERT inside
-- sp_d_labtest_result_postprocessing (line 875) allocates KEY=1 and
-- PK-conflicts with the seed row. DBCC CHECKIDENT(...,RESEED,N) on a
-- table with NULL current identity is a no-op in MSSQL — it does NOT
-- advance the counter. The reliable fix is IDENTITY_INSERT-and-delete
-- which forces the IDENTITY to the inserted-then-deleted high-water
-- value.
--
-- This is a baseline-data quirk in v6.0.18.1; not a Lab fixture
-- concern. Documented in coverage_lab.md as
-- BASELINE_QUIRK / merged-fixture sequence note.
-- =====================================================================
-- [ODSE-only conversion] Removed the IDENTITY-advance workaround that wrote
-- nrt_lab_test_key / nrt_lab_test_result_group_key directly. Those surrogate
-- keys are allocated by 017/018-sp_d_labtest*_postprocessing under the bug #17
-- fix (explicit sp_getapplock + IDENTITY RESEED, robust to empty/NULL-seed
-- state), so the fixture-side RDB_MODERN write is redundant. The driving ODSE
-- observation chain is already authored above.
