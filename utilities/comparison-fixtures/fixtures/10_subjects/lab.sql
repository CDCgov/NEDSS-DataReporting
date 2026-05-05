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
--   observations (obs_domain_cd_st_1='Result') linked by an
--   `act_relationship` row of type_cd='COMP'. Lab-INTERNAL
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
--      a value_txt comment). Linked to v2 Order via internal
--      act_relationship (type_cd='COMP').
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
     N'PROCESSED', '2026-04-04T00:00:00',
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
     N'PROCESSED', '2026-04-04T08:30:00',
     N'A', '2026-04-04T08:30:00', @foundation_patient_uid,
     N'T', 1, N'STD', N'130001',
     20070010, N'Y',
     '2026-04-04T08:30:00', '2026-04-03T18:00:00');  -- Abnormal result interpretation drives via observation_interp table below

-- =====================================================================
-- v2 followup C_Order/C_Result observations — drive LAB_RPT_USER_COMMENT.
-- These have ctrl_cd_display_form NULL (NULL is permitted by the SP's
-- WHERE clause at line 219: `OR obs.CTRL_CD_DISPLAY_FORM IS NULL`).
-- =====================================================================
INSERT INTO [dbo].[observation]
    ([observation_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [last_chg_time], [last_chg_user_id], [local_id],
     [obs_domain_cd_st_1], [obs_domain_cd],
     [record_status_cd], [record_status_time],
     [status_cd], [status_time], [subject_person_uid],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [electronic_ind],
     [activity_to_time])
VALUES
    (@dbo_Act_lab_v2_corder_uid, '2026-04-04T08:00:00', @superuser_id,
     N'NTE', N'Notes Comment Order',
     '2026-04-04T08:00:00', @superuser_id, N'OBS20070020GA01',
     N'C_Order', N'C_Order',
     N'PROCESSED', '2026-04-04T08:00:00',
     N'A', '2026-04-04T08:00:00', @foundation_patient_uid,
     N'T', 1, N'STD', N'130001',
     20070010, N'Y',
     '2026-04-04T08:00:00'),
    (@dbo_Act_lab_v2_cresult_uid, '2026-04-04T08:30:00', @superuser_id,
     N'NTE', N'Notes Comment Result',
     '2026-04-04T08:30:00', @superuser_id, N'OBS20070021GA01',
     N'C_Result', N'C_Result',
     N'PROCESSED', '2026-04-04T08:30:00',
     N'A', '2026-04-04T08:30:00', @foundation_patient_uid,
     N'T', 1, N'STD', N'130001',
     20070010, N'Y',
     '2026-04-04T08:30:00');

-- =====================================================================
-- Lab-internal act_relationship rows: Order -> Result and Order -> C_Result.
-- type_cd='COMP' from SRTE AR_TYPE (verified). class_cd 'OBS' for both
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
    -- v2 C_Order -> v2 Order (parent — followup-comment Order child)
    (@dbo_Act_lab_v2_corder_uid, @dbo_Act_lab_v2_order_uid, N'COMP',
     '2026-04-04T08:00:00', @superuser_id,
     '2026-04-04T08:00:00', @superuser_id, N'ACTIVE',
     '2026-04-04T08:00:00', 2, N'OBS', N'OBS', N'A',
     '2026-04-04T08:00:00', N'Component'),
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
INSERT INTO [dbo].[nrt_observation]
    ( [observation_uid], [class_cd], [mood_cd], [act_uid]                                  -- 01-04
    , [cd_desc_txt], [record_status_cd], [jurisdiction_cd]                                 -- 05-07
    , [program_jurisdiction_oid], [prog_area_cd], [pregnant_ind_cd]                        -- 08-10
    , [local_id], [activity_to_time], [effective_from_time]                                -- 11-13
    , [rpt_to_state_time], [electronic_ind], [version_ctrl_nbr]                            -- 14-16
    , [ordering_person_id], [patient_id], [result_observation_uid]                         -- 17-19
    , [author_organization_id], [ordering_organization_id]                                 -- 20-21
    , [performing_organization_id], [material_id], [obs_domain_cd_st_1]                    -- 22-24
    , [processing_decision_cd], [cd], [shared_ind]                                         -- 25-27
    , [add_user_id], [add_user_name], [add_time]                                           -- 28-30
    , [last_chg_user_id], [last_chg_user_name], [last_chg_time]                            -- 31-33
    , [ctrl_cd_display_form], [status_cd], [cd_system_cd]                                  -- 34-36
    , [cd_system_desc_txt], [ctrl_cd_user_defined_1], [alt_cd]                             -- 37-39
    , [alt_cd_desc_txt], [alt_cd_system_cd], [alt_cd_system_desc_txt]                      -- 40-42
    , [method_cd], [method_desc_txt], [target_site_cd]                                     -- 43-45
    , [target_site_desc_txt], [txt], [interpretation_cd]                                   -- 46-48
    , [interpretation_desc_txt], [report_observation_uid]                                  -- 49-50
    , [followup_observation_uid], [report_refr_uid], [report_sprt_uid]                     -- 51-53
    , [morb_physician_id], [morb_reporter_id], [transcriptionist_id]                       -- 54-56
    , [transcriptionist_val], [transcriptionist_first_nm]                                  -- 57-58
    , [transcriptionist_last_nm], [assistant_interpreter_id]                               -- 59-60
    , [assistant_interpreter_val], [assistant_interpreter_first_nm]                        -- 61-62
    , [assistant_interpreter_last_nm], [result_interpreter_id]                             -- 63-64
    , [specimen_collector_id], [copy_to_provider_id]                                       -- 65-66
    , [lab_test_technician_id], [health_care_id], [morb_hosp_reporter_id]                  -- 67-69
    , [accession_number], [morb_hosp_id]                                                   -- 70-71
    , [transcriptionist_id_assign_auth]                                                    -- 72
    , [transcriptionist_auth_type], [assistant_interpreter_id_assign_auth]                 -- 73-74
    , [assistant_interpreter_auth_type], [priority_cd]                                     -- 75-76
    , [record_status_time], [status_time], [batch_id]                                      -- 77-79
    , [associated_phc_uids], [activity_from_time]                                          -- 80-81
    , [device_instance_id_1], [device_instance_id_2]                                       -- 82-83
    )
VALUES
    -- ---------------------------------------------------------------
    -- Row 1. Foundation Lab Order (UID 20000120) — sparse / NULL-propagation variant.
    -- ---------------------------------------------------------------
    ( @foundation_act_lab_uid, N'OBS', N'EVN', @foundation_act_lab_uid                     -- 01-04
    , N'Foundation lab report', N'PROCESSED', N'1'                                         -- 05-07
    , NULL, N'STD', NULL                                                                   -- 08-10
    , N'OBS20000120GA01', NULL, NULL                                                       -- 11-13
    , NULL, N'N', 1                                                                        -- 14-16
    , NULL, @foundation_patient_uid, NULL                                                  -- 17-19
    , NULL, NULL                                                                           -- 20-21
    , NULL, NULL, N'Order'                                                                 -- 22-24
    , NULL, N'LAB100', N'F'                                                                -- 25-27
    , @superuser_id, N'Foundation, Superuser', '2026-04-01T00:00:00'                       -- 28-30
    , @superuser_id, N'Foundation, Superuser', '2026-04-01T00:00:00'                       -- 31-33
    , NULL, N'A', NULL                                                                     -- 34-36
    , NULL, NULL, NULL                                                                     -- 37-39
    , NULL, NULL, NULL                                                                     -- 40-42
    , NULL, NULL, NULL                                                                     -- 43-45
    , NULL, NULL, NULL                                                                     -- 46-48
    , NULL, NULL                                                                           -- 49-50
    , NULL, NULL, NULL                                                                     -- 51-53
    , NULL, NULL, NULL                                                                     -- 54-56
    , NULL, NULL                                                                           -- 57-58
    , NULL, NULL                                                                           -- 59-60
    , NULL, NULL                                                                           -- 61-62
    , NULL, NULL                                                                           -- 63-64
    , NULL, NULL                                                                           -- 65-66
    , NULL, NULL, NULL                                                                     -- 67-69
    , NULL, NULL                                                                           -- 70-71
    , NULL                                                                                 -- 72
    , NULL, NULL                                                                           -- 73-74
    , NULL, NULL                                                                           -- 75-76
    , '2026-04-01T00:00:00', '2026-04-01T00:00:00', NULL                                   -- 77-79
    , NULL, NULL                                                                           -- 80-81
    , NULL, NULL                                                                           -- 82-83
    ),
    -- ---------------------------------------------------------------
    -- Row 2. v2 Lab Order (UID 20070010) — fully populated.
    -- ---------------------------------------------------------------
    ( @dbo_Act_lab_v2_order_uid, N'OBS', N'EVN', @dbo_Act_lab_v2_order_uid                 -- 01-04
    , N'Hepatitis A virus IgM Ab [Presence] in Serum', N'PROCESSED', N'130001'             -- 05-07
    , 20070010, N'STD', N'N'                                                               -- 08-10
    , N'OBS20070010GA01', '2026-04-04T08:00:00', '2026-04-03T18:00:00'                     -- 11-13
    , '2026-04-04T10:00:00', N'Y', 1                                                       -- 14-16
    , CAST(@foundation_provider_uid AS nvarchar(50)), @foundation_patient_uid              -- 17-18
                                  , CAST(@dbo_Act_lab_v2_result_uid AS nvarchar(50))       -- 19
    , @foundation_org_uid, @foundation_org_uid                                             -- 20-21
    , @foundation_org_uid, @dbo_Material_v2_uid, N'Order'                                  -- 22-24
    , N'AC', N'13950-1', N'T'                                                              -- 25-27
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'                       -- 28-30
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T00:00:00'                       -- 31-33
    , N'LabReport', N'A', N'2.16.840.1.113883.6.1'                                         -- 34-36
    , N'LN', N'UDV1', N'HAVAB-IGM'                                                         -- 37-39
    , N'Hepatitis A IgM Ab', N'L', N'Local'                                                -- 40-42
    , N'IGM-EIA', N'IgM Enzyme Immunoassay', N'SER'                                        -- 43-45
    , N'Serum', N'Tier 1 v2 Lab Order — clinical narrative.', NULL                         -- 46-48
    , NULL, @dbo_Act_lab_v2_order_uid                                                      -- 49-50
    , CAST((CAST(@dbo_Act_lab_v2_corder_uid AS varchar(20)) + ',' + CAST(@dbo_Act_lab_v2_cresult_uid AS varchar(20))) AS nvarchar(50)), @dbo_Act_lab_v2_order_uid          -- 51-52
                                                            , @dbo_Act_lab_v2_order_uid    -- 53
    , @foundation_provider_uid, @foundation_provider_uid, @foundation_provider_uid         -- 54-56
    , N'TRX001', N'Tina'                                                                   -- 57-58
    , N'Transcriptionist', @foundation_provider_uid                                        -- 59-60
    , N'AIN001', N'Avery'                                                                  -- 61-62
    , N'Interpreter', @foundation_provider_uid                                             -- 63-64
    , @foundation_provider_uid, @foundation_provider_uid                                   -- 65-66
    , @foundation_provider_uid, @foundation_org_uid, @foundation_provider_uid              -- 67-69
    , N'ACC-V2-20070010', @foundation_org_uid                                              -- 70-71
    , N'2.16.840.1.113883.4.6'                                                             -- 72
    , N'NPI', N'2.16.840.1.113883.4.6'                                                     -- 73-74
    , N'NPI', N'R'                                                                         -- 75-76
    , '2026-04-04T00:00:00', '2026-04-04T00:00:00', NULL                                   -- 77-79
    , NULL, '2026-04-03T18:00:00'                                                          -- 80-81
    , N'DEV-INST-A', N'DEV-INST-B'                                                         -- 82-83
    ),
    -- ---------------------------------------------------------------
    -- Row 3. v2 Lab Result (UID 20070011) — child; report_observation_uid -> v2 Order.
    -- ---------------------------------------------------------------
    ( @dbo_Act_lab_v2_result_uid, N'OBS', N'EVN', @dbo_Act_lab_v2_result_uid               -- 01-04
    , N'Hepatitis A virus IgM Ab [Presence] in Serum', N'PROCESSED', N'130001'             -- 05-07
    , 20070010, N'STD', NULL                                                               -- 08-10
    , N'OBS20070011GA01', '2026-04-04T08:30:00', '2026-04-03T18:00:00'                     -- 11-13
    , '2026-04-04T10:00:00', N'Y', 1                                                       -- 14-16
    , CAST(@foundation_provider_uid AS nvarchar(50)), @foundation_patient_uid, NULL        -- 17-19
    , @foundation_org_uid, @foundation_org_uid                                             -- 20-21
    , @foundation_org_uid, NULL, N'Result'                                                 -- 22-24
    , NULL, N'13950-1', N'T'                                                               -- 25-27
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T08:30:00'                       -- 28-30
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T08:30:00'                       -- 31-33
    , N'LabReport', N'A', N'2.16.840.1.113883.6.1'                                         -- 34-36
    , N'LN', NULL, NULL                                                                    -- 37-39
    , NULL, NULL, NULL                                                                     -- 40-42
    , N'IGM-EIA', N'IgM Enzyme Immunoassay', NULL                                          -- 43-45
    , NULL, NULL, N'A'                                                                     -- 46-48
    , N'Abnormal', @dbo_Act_lab_v2_order_uid                                               -- 49-50
    , NULL, @dbo_Act_lab_v2_order_uid, @dbo_Act_lab_v2_order_uid                           -- 51-53
    , NULL, NULL, NULL                                                                     -- 54-56
    , NULL, NULL                                                                           -- 57-58
    , NULL, NULL                                                                           -- 59-60
    , NULL, NULL                                                                           -- 61-62
    , NULL, @foundation_provider_uid                                                       -- 63-64
    , NULL, NULL                                                                           -- 65-66
    , NULL, NULL, NULL                                                                     -- 67-69
    , NULL, NULL                                                                           -- 70-71
    , NULL                                                                                 -- 72
    , NULL, NULL                                                                           -- 73-74
    , NULL, NULL                                                                           -- 75-76
    , '2026-04-04T08:30:00', '2026-04-04T08:30:00', NULL                                   -- 77-79
    , NULL, '2026-04-03T18:00:00'                                                          -- 80-81
    , NULL, NULL                                                                           -- 82-83
    ),
    -- ---------------------------------------------------------------
    -- Row 4. v2 followup C_Order (UID 20070020).
    -- ---------------------------------------------------------------
    ( @dbo_Act_lab_v2_corder_uid, N'OBS', N'EVN', @dbo_Act_lab_v2_corder_uid               -- 01-04
    , N'Notes Comment Order', N'PROCESSED', N'130001'                                      -- 05-07
    , 20070010, N'STD', NULL                                                               -- 08-10
    , N'OBS20070020GA01', '2026-04-04T08:00:00', NULL                                      -- 11-13
    , NULL, N'Y', 1                                                                        -- 14-16
    , NULL, @foundation_patient_uid, NULL                                                  -- 17-19
    , NULL, NULL                                                                           -- 20-21
    , NULL, NULL, N'C_Order'                                                               -- 22-24
    , NULL, N'NTE', N'T'                                                                   -- 25-27
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T08:00:00'                       -- 28-30
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T08:00:00'                       -- 31-33
    , NULL, N'A', NULL                                                                     -- 34-36
    , NULL, NULL, NULL                                                                     -- 37-39
    , NULL, NULL, NULL                                                                     -- 40-42
    , NULL, NULL, NULL                                                                     -- 43-45
    , NULL, NULL, NULL                                                                     -- 46-48
    , NULL, @dbo_Act_lab_v2_order_uid                                                      -- 49-50
    , NULL, NULL, NULL                                                                     -- 51-53
    , NULL, NULL, NULL                                                                     -- 54-56
    , NULL, NULL                                                                           -- 57-58
    , NULL, NULL                                                                           -- 59-60
    , NULL, NULL                                                                           -- 61-62
    , NULL, NULL                                                                           -- 63-64
    , NULL, NULL                                                                           -- 65-66
    , NULL, NULL, NULL                                                                     -- 67-69
    , NULL, NULL                                                                           -- 70-71
    , NULL                                                                                 -- 72
    , NULL, NULL                                                                           -- 73-74
    , NULL, NULL                                                                           -- 75-76
    , '2026-04-04T08:00:00', '2026-04-04T08:00:00', NULL                                   -- 77-79
    , NULL, NULL                                                                           -- 80-81
    , NULL, NULL                                                                           -- 82-83
    ),
    -- ---------------------------------------------------------------
    -- Row 5. v2 followup C_Result (UID 20070021).
    -- ---------------------------------------------------------------
    ( @dbo_Act_lab_v2_cresult_uid, N'OBS', N'EVN', @dbo_Act_lab_v2_cresult_uid             -- 01-04
    , N'Notes Comment Result', N'PROCESSED', N'130001'                                     -- 05-07
    , 20070010, N'STD', NULL                                                               -- 08-10
    , N'OBS20070021GA01', '2026-04-04T08:30:00', NULL                                      -- 11-13
    , NULL, N'Y', 1                                                                        -- 14-16
    , NULL, @foundation_patient_uid, NULL                                                  -- 17-19
    , NULL, NULL                                                                           -- 20-21
    , NULL, NULL, N'C_Result'                                                              -- 22-24
    , NULL, N'NTE', N'T'                                                                   -- 25-27
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T08:30:00'                       -- 28-30
    , @superuser_id, N'Foundation, Superuser', '2026-04-04T08:30:00'                       -- 31-33
    , NULL, N'A', NULL                                                                     -- 34-36
    , NULL, NULL, NULL                                                                     -- 37-39
    , NULL, NULL, NULL                                                                     -- 40-42
    , NULL, NULL, NULL                                                                     -- 43-45
    , NULL, NULL, NULL                                                                     -- 46-48
    , NULL, @dbo_Act_lab_v2_corder_uid                                                     -- 49-50
    , NULL, NULL, NULL                                                                     -- 51-53
    , NULL, NULL, NULL                                                                     -- 54-56
    , NULL, NULL                                                                           -- 57-58
    , NULL, NULL                                                                           -- 59-60
    , NULL, NULL                                                                           -- 61-62
    , NULL, NULL                                                                           -- 63-64
    , NULL, NULL                                                                           -- 65-66
    , NULL, NULL, NULL                                                                     -- 67-69
    , NULL, NULL                                                                           -- 70-71
    , NULL                                                                                 -- 72
    , NULL, NULL                                                                           -- 73-74
    , NULL, NULL                                                                           -- 75-76
    , '2026-04-04T08:30:00', '2026-04-04T08:30:00', NULL                                   -- 77-79
    , NULL, NULL                                                                           -- 80-81
    , NULL, NULL                                                                           -- 82-83
    );

-- =====================================================================
-- nrt_observation_txt — value_txt rows for v2 Result + v2 C_Result.
-- ovt_txt_type_cd 'N' is required for the LAB_RPT_USER_COMMENT path
-- (sp_d_lab_test_postprocessing line 783, 785). C_Result text uses 'N'.
-- v2 Result lab-result text uses 'FT' so it lands in LAB_RESULT_VAL.LAB_RESULT_TXT_VAL.
-- =====================================================================
INSERT INTO [dbo].[nrt_observation_txt]
    ([observation_uid], [ovt_seq], [ovt_txt_type_cd], [ovt_value_txt], [batch_id])
VALUES
    -- v2 Result row 1: txt_type_cd='FT' — feeds LAB_RESULT_VAL.LAB_RESULT_TXT_VAL
    -- (sp_d_labtest_result_postprocessing line 766 — joins when ovt_txt_type_cd
    -- IS NULL OR rslt.ELR_IND='Y' AND <> 'N').
    (@dbo_Act_lab_v2_result_uid, 1, N'FT',
     N'Reactive — IgM antibody to Hepatitis A virus detected.', NULL),
    -- v2 Result row 2: txt_type_cd='N', seq=2 — feeds LAB_RESULT_COMMENT
    -- (sp_d_labtest_result_postprocessing line 400-401 filter:
    -- ovt_txt_type_cd='N' AND ovt_seq <> 0).
    (@dbo_Act_lab_v2_result_uid, 2, N'N',
     N'Result-level note — patient flagged for follow-up serology.', NULL),
    -- v2 C_Result text (txt_type_cd='N') feeds LAB_RPT_USER_COMMENT in
    -- sp_d_lab_test_postprocessing's followup-comment branch.
    (@dbo_Act_lab_v2_cresult_uid, 1, N'N',
     N'Comment from clinician — re-test recommended in 2 weeks.', NULL);

-- =====================================================================
-- nrt_observation_coded — coded result for v2 Result.
-- =====================================================================
INSERT INTO [dbo].[nrt_observation_coded]
    ([observation_uid], [ovc_code], [ovc_code_system_cd],
     [ovc_code_system_desc_txt], [ovc_display_name],
     [ovc_alt_cd], [ovc_alt_cd_desc_txt], [ovc_alt_cd_system_cd],
     [ovc_alt_cd_system_desc_txt], [batch_id])
VALUES
    (@dbo_Act_lab_v2_result_uid, N'10828004', N'2.16.840.1.113883.6.96',
     N'SCT', N'Positive',
     N'POS', N'Positive', N'L',
     N'Local', NULL);

-- =====================================================================
-- nrt_observation_numeric — numeric result for v2 Result.
-- =====================================================================
INSERT INTO [dbo].[nrt_observation_numeric]
    ([observation_uid], [ovn_high_range], [ovn_low_range],
     [ovn_comparator_cd_1], [ovn_numeric_value_1], [ovn_numeric_value_2],
     [ovn_numeric_unit_cd], [ovn_separator_cd], [ovn_seq], [batch_id])
VALUES
    (@dbo_Act_lab_v2_result_uid, N'0.90', N'0.00', N'>',
     1.10, NULL, N'Index', NULL, 1, NULL);

-- =====================================================================
-- nrt_observation_date — date result for v2 Result.
-- =====================================================================
INSERT INTO [dbo].[nrt_observation_date]
    ([observation_uid], [ovd_from_date], [ovd_to_date], [ovd_seq], [batch_id])
VALUES
    (@dbo_Act_lab_v2_result_uid, '2026-04-04T08:30:00',
     '2026-04-04T08:30:00', 1, NULL);

-- =====================================================================
-- nrt_observation_material — material participation for v2 Order.
-- Keyed by act_uid (= Order observation_uid) + material_id.
-- material_id is NOT NULL.
-- =====================================================================
INSERT INTO [dbo].[nrt_observation_material]
    ([act_uid], [type_cd], [material_id], [subject_class_cd],
     [record_status], [type_desc_txt], [last_chg_time],
     [material_cd], [material_nm], [material_details],
     [material_collection_vol], [material_collection_vol_unit],
     [material_desc], [risk_cd], [risk_desc_txt])
VALUES
    (@dbo_Act_lab_v2_order_uid, N'SPC', @dbo_Material_v2_uid, N'MAT',
     N'ACTIVE', N'Specimen', '2026-04-04T00:00:00',
     N'258450006', N'Serum sample',
     N'Patient serum specimen, 5 mL, refrigerated',
     N'5', N'mL',
     N'Serum specimen', N'B', N'Biohazard');

-- =====================================================================
-- nrt_observation_reason — reason-for-test for v2 Order.
-- =====================================================================
INSERT INTO [dbo].[nrt_observation_reason]
    ([observation_uid], [reason_cd], [reason_desc_txt], [batch_id])
VALUES
    (@dbo_Act_lab_v2_order_uid, N'B33.5',
     N'Acute hepatitis A — diagnostic workup', NULL);

-- =====================================================================
-- nrt_observation_edx — EDX_Document link for v2 Order.
-- Drives sp_d_lab_test_postprocessing's #edx_document temp table and
-- LAB_TEST.DOCUMENT_LINK is built from this.
-- =====================================================================
INSERT INTO [dbo].[nrt_observation_edx]
    ([edx_document_uid], [edx_act_uid], [edx_add_time])
VALUES
    (@dbo_EDX_Document_v2_uid, @dbo_Act_lab_v2_order_uid,
     '2026-04-04T00:00:00');

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
SET IDENTITY_INSERT dbo.nrt_lab_test_result_group_key ON;
INSERT INTO dbo.nrt_lab_test_result_group_key (TEST_RESULT_GRP_KEY, LAB_TEST_UID) VALUES (100, NULL);
SET IDENTITY_INSERT dbo.nrt_lab_test_result_group_key OFF;
DELETE FROM dbo.nrt_lab_test_result_group_key WHERE TEST_RESULT_GRP_KEY = 100;

SET IDENTITY_INSERT dbo.nrt_lab_test_key ON;
INSERT INTO dbo.nrt_lab_test_key (LAB_TEST_KEY, LAB_TEST_UID) VALUES (100, NULL);
SET IDENTITY_INSERT dbo.nrt_lab_test_key OFF;
DELETE FROM dbo.nrt_lab_test_key WHERE LAB_TEST_KEY = 100;
GO
