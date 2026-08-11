-- =====================================================================
-- Tier 3 (NO-SHORTCUT, ODSE-ONLY) — fill dbo.LAB100 + unblock dbo.LAB101
-- Agent R4-N. UID block 22053000-22053999 (catalog/uid_ranges.md).
-- =====================================================================
-- Branch aw/remove-nrt-shortcut: this fixture authors ONLY NBS_ODSE rows
-- (act / observation / obs_value_* / act_relationship / act_id /
-- participation / role). The REAL pipeline (CDC/Debezium -> kafka-connect
-- -> nrt_observation* ; service sp_observation_event ; orchestrator Step-5
-- sp_d_lab_test_postprocessing + sp_d_labtest_result_postprocessing ;
-- Step-9 sp_lab100/101_datamart_postprocessing) turns these into datamart
-- rows. NO nrt_* INSERT, NO EXEC sp_, NO liquibase/seed/SRTE edits.
--
-- ---------------------------------------------------------------------
-- WHY LAB100 IS ONLY 36/69 (demographics + facility columns NULL)
-- ---------------------------------------------------------------------
-- The two live LAB100 rows (COVID 94309-2, HepA 13950-1) resolve
-- PATIENT_KEY / ORDERING_PROVIDER_KEY / ORDERING_ORG_KEY / REPORTING_LAB_KEY
-- all to sentinel 1, so every PERSON_* / PATIENT_* / PROVIDER_* /
-- ORDERING_FACILITY / REPORTING_FACILITY* column is NULL. Verified live:
-- the v2 lab Order 20070010 has ZERO participation rows in NBS_ODSE, so
-- CDC leaves nrt_observation.patient_id / ordering_person_id /
-- author_organization_id / ordering_organization_id / specimen_collector_id
-- NULL, and sp_d_labtest_result_postprocessing (017, lines 281-328)
-- COALESCEs every dim lookup to 1.
--   Mapping (service ProcessObservationDataUtil.java, VERIFIED):
--     person  PATSBJ            -> patient_id              -> PATIENT_KEY
--     person  ORD               -> ordering_person_id      -> ORDERING_PROVIDER_KEY
--     person  VRF               -> result_interpreter_id   -> RESULT_INTERPRETER_NAME
--     role    SPP (scoping PSN) -> specimen_collector_id   -> SPECIMEN_COLLECTOR_KEY
--     org(Order) AUT           -> author_organization_id  -> REPORTING_LAB_KEY  -> REPORTING_FACILITY*
--     org(Order) ORD           -> ordering_organization_id-> ORDERING_ORG_KEY   -> ORDERING_FACILITY
--   The dim rows already exist (D_PATIENT key 4 = uid 20000000,
--   D_PROVIDER key 12 = uid 20000010, D_ORGANIZATION key 7 = uid
--   20000020), so authoring these participations on a NEW lab Order
--   resolves them to real keys and lights up the demographic/facility
--   columns of LAB100.
-- => Part A: ONE fully-attributed Order (22053010) + Result child
--    (22053011) with the participations above.
--
-- ---------------------------------------------------------------------
-- WHY LAB101 IS 0/46 (verified root cause)
-- ---------------------------------------------------------------------
-- sp_lab101_datamart_postprocessing (020) step 2 (#tmp_I_Result_vals)
-- reads dbo.nrt_observation for the ROOT order's followup_observation_uid
-- CSV and joins to LAB_TEST rows of LAB_TEST_TYPE='I_Result'. The prior
-- shortcut-era zz_lab101_unblock.sql injected LAB_TEST/LAB_RESULT_VAL rows
-- directly into RDB_MODERN but its nrt_observation INSERT was stripped on
-- the no-shortcut branch, so the root-order nrt_observation (and its
-- followup CSV) NEVER EXISTS -> #tmp_I_Result_vals returns 0 -> the whole
-- LAB101 chain starves -> 0/46. Verified live: nrt_observation has only
-- CDC-produced rows (e.g. 20070010); 22029500 is absent.
--   The fix on no-shortcut is to author the full ODSE observation
--   hierarchy so CDC produces the nrt_observation rows:
--     I_Order  (root)                       obs_domain_cd_st_1='I_Order'
--     I_Result (carries LAB_RPT_UID detail) obs_domain_cd_st_1='I_Result'
--     Result   (specimen-detail test)       obs_domain_cd_st_1='Result'
--     35 LABxxx isolate-tracking children   obs_domain_cd_st_1='I_Result',
--         cd IN ('LAB329a','LAB330'..'LAB363') -> LAB1..LAB35 pivot
--   The children are wired to the I_Order via Lab-internal act_relationship
--   (type_cd='COMP', source=child, target=I_Order) so sp_observation_event
--   (055, lines 130-156) emits them in the I_Order's followup_observations
--   JSON; the service routes the 'Result'-domain one to result_observation_uid
--   and the rest to followup_observation_uid (ProcessObservationDataUtil
--   lines 308-326). Each LABxxx child gets an obs_value_coded whose
--   display_name -> LAB_RESULT_VAL.TEST_RESULT_VAL_CD_DESC (017 line 731-733),
--   which the LAB101 trtdN pivot (020 lines 510-682) lands into LAB1..LAB35.
-- => Part B: I_Order 22053500 + I_Result 22053501 + Result 22053502 +
--    35 LABxxx I_Result children 22053600-22053634, each + obs_value_coded.
--
-- ---------------------------------------------------------------------
-- ORCH_TODO (REQUIRED — see ORDERING note below; without these the
--            orchestrator never feeds these observations to the lab
--            postprocessing/datamart SPs):
--   1. scripts/merge_and_verify.sh run_lab_chain() (~lines 312-315): add
--      the new lab observation UIDs to BOTH the sp_observation_event
--      @obs_id_list AND the two postprocessing @obs_ids lists:
--        22053010,22053011,22053500,22053501,22053502
--      (the 35 LABxxx children 22053600-22053634 are reached via the
--       I_Order followup CSV; do NOT add them to @obs_ids — the
--       postprocessing SP filters obs_domain_cd_st_1 to the standard
--       Order/Result/I_Order/I_Result list and the I_Result/LABxxx children
--       land via the followup traversal, mirroring the C_Order/C_Result
--       precedent in lab.sql.)
--   2. scripts/merge_and_verify.sh LAB_OBS_UIDS (~line 473): add the
--      Result/I_Result test UIDs the datamart SPs key on:
--        22053011  (LAB100 Result),
--        22053501  (LAB101 I_Result; its ROOT_ORDERED_TEST_PNTR=22053500
--                   drives sp_lab101 step 2).
--
--   ** ORDERING (CRITICAL) ** — these observations are authored at Step 8
--   (Tier 3) and CDC-mirrored to nrt_observation only during the Step-9
--   drain. But sp_d_lab_test_postprocessing / sp_d_labtest_result_postprocessing
--   (the SPs that BUILD LAB_TEST/LAB_RESULT_VAL from nrt_observation) run in
--   run_lab_chain() at Step 5/7 — BEFORE these rows exist — and are NOT
--   re-invoked in Step 9. The shortcut-era lab fixtures dodged this by
--   INSERTing LAB_TEST directly into RDB_MODERN (banned on no-shortcut).
--   So the orchestrator MUST, AFTER the Step-9 drain confirms idle and
--   BEFORE the lab100/101 datamart SPs (~lines 553-555), run the two lab
--   postprocessing SPs once more with the new UIDs:
--        EXEC dbo.sp_d_lab_test_postprocessing       @obs_ids = N'<existing>,22053010,22053011,22053500,22053501,22053502', @debug = 0;
--        EXEC dbo.sp_d_labtest_result_postprocessing @obs_ids = N'<existing>,22053010,22053011,22053500,22053501,22053502', @debug = 0;
--   (Equivalently: add a "Step 8.7 — re-run run_lab_chain for Tier-3 lab
--    obs" hook with the extended @obs_ids, after the Step-9 drain.)
--
-- ---------------------------------------------------------------------
-- SEED-GATED columns (DOCUMENT, do NOT fix):
--   * LAB100.CONDITION_CD / CONDITION_SHORT_NM / PROGRAM_AREA_* — resolve
--     only when the resulted LOINC maps in nrt_srte_Loinc_condition. The
--     new lab uses LOINC 13950-1 (Hep A IgM -> cond 10110), which IS
--     baseline-seeded (proven by the existing 13950-1 LAB100 row carrying
--     CONDITION_CD=10110), so these DO fill. No new seed needed here.
--     (Contrast: covid_lab is blocked by the MISSING 11065 LOINC->cond
--     seed, bug #16 — OUT OF BOUNDS. LAB100/LAB101 are NOT subject to
--     that gate for non-COVID conditions.)
--   * LAB100.MORB_RPT_KEY / LDF_GROUP_KEY / INVESTIGATION_KEYS — require a
--     cross-subject act_relationship (Lab->Morb/Investigation, Tier 2) and
--     LDF data; NOT authored here (would be a different agent's target).
-- =====================================================================

USE [NBS_ODSE];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- ----- read-only foundation references -----
DECLARE @superuser_id bigint = 10009282;
DECLARE @pat_uid      bigint = 20000000;   -- D_PATIENT key 4 (rich demographics)
DECLARE @prov_uid     bigint = 20000010;   -- D_PROVIDER key 12 (rich address/phone)
DECLARE @org_uid      bigint = 20000020;   -- D_ORGANIZATION key 7 (CLIA/name/phone)

-- =====================================================================
-- PART A — LAB100 demographics fill
-- New fully-attributed Order (22053010) + Result child (22053011).
-- LOINC 13950-1 (Hep A IgM Ab) maps to baseline-seeded cond 10110.
-- =====================================================================
DECLARE @a_order  bigint = 22053010;
DECLARE @a_result bigint = 22053011;

INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES
    (@a_order,  N'OBS', N'EVN'),
    (@a_result, N'OBS', N'EVN');

-- Order observation
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
    (@a_order, '2026-04-20T08:00:00', @superuser_id,
     N'13950-1', N'Hepatitis A virus IgM Ab [Presence] in Serum',
     N'2.16.840.1.113883.6.1', N'LN', N'HAVAB-IGM', N'Hepatitis A IgM Ab',
     N'L', N'Local',
     '2026-04-20T08:00:00', @superuser_id, N'OBS22053010GA01',
     N'Order', N'Order', N'LabReport',
    N'ACTIVE', '2026-04-20T08:00:00', N'A', '2026-04-20T08:00:00',
     @pat_uid, N'T', 1,
     N'VPD', N'130001', 20053010,
     N'Y', '2026-04-20T08:00:00', '2026-04-19T18:00:00',
     '2026-04-20T10:00:00', '2026-04-19T18:00:00', N'IGM-EIA', N'IgM Enzyme Immunoassay',
     N'SER', N'Serum', N'R4-N LAB100 demographics-fill Order.', N'R',
     N'AC');

-- Result child observation
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
    (@a_result, '2026-04-20T09:00:00', @superuser_id,
     N'13950-1', N'Hepatitis A virus IgM Ab [Presence] in Serum',
     N'2.16.840.1.113883.6.1', N'LN',
     '2026-04-20T09:00:00', @superuser_id, N'OBS22053011GA01',
     N'Result', N'Result', N'LabReport',
    N'ACTIVE', '2026-04-20T09:00:00', N'A', '2026-04-20T09:00:00',
     @pat_uid, N'T', 1,
     N'VPD', N'130001', 20053010,
     N'Y', '2026-04-20T09:00:00', '2026-04-19T18:00:00');

-- Result -> Order (Lab-internal COMP; child is source, parent is target)
INSERT INTO [dbo].[act_relationship]
    ([source_act_uid],[target_act_uid],[type_cd],[add_time],[add_user_id],
     [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
     [sequence_nbr],[source_class_cd],[target_class_cd],[status_cd],[status_time],
     [type_desc_txt])
VALUES
    (@a_result, @a_order, N'COMP', '2026-04-20T09:00:00', @superuser_id,
     '2026-04-20T09:00:00', @superuser_id, N'ACTIVE', '2026-04-20T09:00:00',
     1, N'OBS', N'OBS', N'A', '2026-04-20T09:00:00', N'Component');

-- Lab Order -> Investigation (LabReport cross-subject edge; wires
-- associated_phc_uids in nrt_observation for RDB_MODERN LAB100)
INSERT INTO [dbo].[act_relationship]
    ([source_act_uid],[target_act_uid],[type_cd],[add_time],[add_user_id],
     [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
     [sequence_nbr],[source_class_cd],[target_class_cd],[status_cd],[status_time],
     [type_desc_txt])
VALUES
    (@a_order, 20050010, N'LabReport', '2026-04-20T08:00:00', @superuser_id,
     '2026-04-20T08:00:00', @superuser_id, N'ACTIVE', '2026-04-20T08:00:00',
     1, N'OBS', N'CASE', N'A', '2026-04-20T08:00:00', N'Lab Report');

-- Bump observation change time after wiring the LabReport edge so CDC emits
-- an observation change event that includes the CASE association.
UPDATE [dbo].[observation]
     SET [last_chg_time] = DATEADD(SECOND, 1, [last_chg_time])
 WHERE [observation_uid] = @a_order;

-- act_id for the Order (accession-style local id -> ACCESSION_NBR feed)
INSERT INTO [dbo].[act_id]
    ([act_uid],[act_id_seq],[add_time],[add_user_id],
     [assigning_authority_cd],[assigning_authority_desc_txt],
     [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
     [root_extension_txt],[type_cd],[type_desc_txt],[status_cd],[status_time])
VALUES
    (@a_order, 1, '2026-04-20T08:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     '2026-04-20T08:00:00', @superuser_id, N'ACTIVE', '2026-04-20T08:00:00',
     N'OBS22053010GA01', N'OBS_LOCAL_ID', N'Local Observation Identifier', N'A', '2026-04-20T08:00:00'),
    (@a_order, 2, '2026-04-20T08:00:00', @superuser_id,
     N'2.16.840.1.113883.4.6', N'NPI Filler',
     '2026-04-20T08:00:00', @superuser_id, N'ACTIVE', '2026-04-20T08:00:00',
     N'ACC-22053010', N'FILLER', N'Filler Order Number', N'A', '2026-04-20T08:00:00');

-- Result value rows (coded + numeric + txt) -> LAB_RESULT_VAL columns
INSERT INTO [dbo].[obs_value_coded]
    ([observation_uid],[code],[code_system_cd],[code_system_desc_txt],
     [display_name],[alt_cd],[alt_cd_desc_txt],[alt_cd_system_cd],[alt_cd_system_desc_txt])
VALUES
    (@a_result, N'10828004', N'2.16.840.1.113883.6.96', N'SCT',
     N'Positive', N'POS', N'Positive', N'L', N'Local');

INSERT INTO [dbo].[obs_value_numeric]
    ([observation_uid],[obs_value_numeric_seq],[comparator_cd_1],
     [numeric_value_1],[numeric_unit_cd],[low_range],[high_range])
VALUES
    (@a_result, 1, N'>', 1.20, N'Index', N'0.00', N'0.90');

INSERT INTO [dbo].[obs_value_txt]
    ([observation_uid],[obs_value_txt_seq],[txt_type_cd],[value_txt])
VALUES
    (@a_result, 1, N'FT', N'Reactive — IgM antibody to Hepatitis A virus detected (R4-N).');

-- ---- Participations on the ORDER (drive demographics/facility) ----
-- Persons: PATSBJ (patient), ORD (ordering provider), VRF (interpreter)
INSERT INTO [dbo].[participation]
    ([subject_entity_uid],[act_uid],[type_cd],[act_class_cd],[add_time],[add_user_id],
     [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
     [status_cd],[status_time],[subject_class_cd],[type_desc_txt])
VALUES
    (@pat_uid,  @a_order, N'PATSBJ', N'OBS', '2026-04-20T08:00:00', @superuser_id,
     '2026-04-20T08:00:00', @superuser_id, N'ACTIVE', '2026-04-20T08:00:00',
     N'A', '2026-04-20T08:00:00', N'PSN', N'Patient Subject'),
    (@prov_uid, @a_order, N'ORD',    N'OBS', '2026-04-20T08:00:00', @superuser_id,
     '2026-04-20T08:00:00', @superuser_id, N'ACTIVE', '2026-04-20T08:00:00',
     N'A', '2026-04-20T08:00:00', N'PSN', N'Ordering Provider'),
    (@prov_uid, @a_order, N'VRF',    N'OBS', '2026-04-20T08:00:00', @superuser_id,
     '2026-04-20T08:00:00', @superuser_id, N'ACTIVE', '2026-04-20T08:00:00',
     N'A', '2026-04-20T08:00:00', N'PSN', N'Result Interpreter');

-- Organizations on the ORDER: AUT (reporting lab), ORD (ordering org)
INSERT INTO [dbo].[participation]
    ([subject_entity_uid],[act_uid],[type_cd],[act_class_cd],[add_time],[add_user_id],
     [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
     [status_cd],[status_time],[subject_class_cd],[type_desc_txt])
VALUES
    (@org_uid, @a_order, N'AUT', N'OBS', '2026-04-20T08:00:00', @superuser_id,
     '2026-04-20T08:00:00', @superuser_id, N'ACTIVE', '2026-04-20T08:00:00',
     N'A', '2026-04-20T08:00:00', N'ORG', N'Author/Reporting Organization'),
    (@org_uid, @a_order, N'ORD', N'OBS', '2026-04-20T08:00:00', @superuser_id,
     '2026-04-20T08:00:00', @superuser_id, N'ACTIVE', '2026-04-20T08:00:00',
     N'A', '2026-04-20T08:00:00', N'ORG', N'Ordering Organization');

-- Organization on the RESULT: PRF (performing org)
INSERT INTO [dbo].[participation]
    ([subject_entity_uid],[act_uid],[type_cd],[act_class_cd],[add_time],[add_user_id],
     [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
     [status_cd],[status_time],[subject_class_cd],[type_desc_txt])
VALUES
    (@org_uid, @a_result, N'PRF', N'OBS', '2026-04-20T09:00:00', @superuser_id,
     '2026-04-20T09:00:00', @superuser_id, N'ACTIVE', '2026-04-20T09:00:00',
     N'A', '2026-04-20T09:00:00', N'ORG', N'Performing Organization');

-- Specimen collector via role SPP (subject PROV, scoping PSN) on the ORDER.
-- ProcessObservationDataUtil maps role SPP/PSN -> specimen_collector_id.
INSERT INTO [dbo].[participation]
    ([subject_entity_uid],[act_uid],[type_cd],[act_class_cd],[add_time],[add_user_id],
     [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
     [status_cd],[status_time],[subject_class_cd],[type_desc_txt])
VALUES
    (@prov_uid, @a_order, N'SPP', N'OBS', '2026-04-20T08:00:00', @superuser_id,
     '2026-04-20T08:00:00', @superuser_id, N'ACTIVE', '2026-04-20T08:00:00',
     N'A', '2026-04-20T08:00:00', N'PROV', N'Specimen Collector');

IF NOT EXISTS (SELECT 1 FROM dbo.role WHERE subject_entity_uid = @prov_uid AND cd = N'SPP' AND role_seq = 1)
    INSERT INTO [dbo].[role]
        ([subject_entity_uid],[cd],[role_seq],[add_time],[add_user_id],[cd_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
         [scoping_class_cd],[scoping_entity_uid],[status_cd],[status_time],[subject_class_cd])
    VALUES
        (@prov_uid, N'SPP', 1, '2026-04-20T08:00:00', @superuser_id, N'Specimen Collector',
         '2026-04-20T08:00:00', @superuser_id, N'ACTIVE', '2026-04-20T08:00:00',
         N'PSN', @pat_uid, N'A', '2026-04-20T08:00:00', N'PROV');
GO

-- =====================================================================
-- PART B — LAB101 unblock (isolate-tracking EIP/NARMS/PFGE/ISO chain)
-- =====================================================================
USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;
DECLARE @pat_uid      bigint = 20000000;
DECLARE @prov_uid     bigint = 20000010;
DECLARE @org_uid      bigint = 20000020;

DECLARE @i_order  bigint = 22053500;   -- root I_Order
DECLARE @i_result bigint = 22053501;   -- I_Result (LAB_RPT_UID detail carrier)
DECLARE @resulted bigint = 22053502;   -- 'Result' test (specimen detail source)

-- act parents (I_Order, I_Result, Result + 35 LABxxx children 22053600-634)
INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd])
SELECT v, N'OBS', N'EVN'
FROM (VALUES (22053500),(22053501),(22053502)) AS t(v);

DECLARE @c int = 0;
WHILE @c < 35
BEGIN
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22053600 + @c, N'OBS', N'EVN');
    SET @c += 1;
END;

-- I_Order observation (root). subject_person_uid = patient (also gets a
-- PATSBJ participation so demographics resolve on LAB101 too).
INSERT INTO [dbo].[observation]
    ([observation_uid],[add_time],[add_user_id],[cd],[cd_desc_txt],
     [cd_system_cd],[cd_system_desc_txt],
     [last_chg_time],[last_chg_user_id],[local_id],
     [obs_domain_cd_st_1],[obs_domain_cd],[ctrl_cd_display_form],
     [record_status_cd],[record_status_time],[status_cd],[status_time],
     [subject_person_uid],[shared_ind],[version_ctrl_nbr],
     [prog_area_cd],[jurisdiction_cd],[program_jurisdiction_oid],
     [electronic_ind],[method_cd],[method_desc_txt],[target_site_cd],[target_site_desc_txt])
VALUES
    (@i_order, '2026-04-21T08:00:00', @superuser_id,
     N'CULT', N'Bacterial culture — isolate tracking',
     N'L', N'Local',
     '2026-04-21T08:00:00', @superuser_id, N'OBS22053500GA01',
     N'I_Order', N'I_Order', N'LabReport',
    N'ACTIVE', '2026-04-21T08:00:00', N'A', '2026-04-21T08:00:00',
     @pat_uid, N'T', 1,
     N'ENT', N'130001', 20053500,
     N'Y', N'CULT', N'Culture', N'STOOL', N'Stool specimen');

-- I_Result observation (carries the LAB_RPT_UID detail)
INSERT INTO [dbo].[observation]
    ([observation_uid],[add_time],[add_user_id],[cd],[cd_desc_txt],
     [cd_system_cd],[cd_system_desc_txt],
     [last_chg_time],[last_chg_user_id],[local_id],
     [obs_domain_cd_st_1],[obs_domain_cd],[ctrl_cd_display_form],
     [record_status_cd],[record_status_time],[status_cd],[status_time],
     [subject_person_uid],[shared_ind],[version_ctrl_nbr],
     [prog_area_cd],[jurisdiction_cd],[program_jurisdiction_oid],[electronic_ind])
VALUES
    (@i_result, '2026-04-21T09:00:00', @superuser_id,
     N'CULT', N'Bacterial culture — isolate tracking',
     N'L', N'Local',
     '2026-04-21T09:00:00', @superuser_id, N'OBS22053500GA01',
     N'I_Result', N'I_Result', N'LabReport',
    N'ACTIVE', '2026-04-21T09:00:00', N'A', '2026-04-21T09:00:00',
     @pat_uid, N'T', 1,
     N'ENT', N'130001', 20053500, N'Y');

-- 'Result'-type test (specimen-detail source for #tmp_RESULTED_TEST_DETAIL1).
-- Same local_id so the SP's LAB_RPT_UID/local_id joins line up.
INSERT INTO [dbo].[observation]
    ([observation_uid],[add_time],[add_user_id],[cd],[cd_desc_txt],
     [cd_system_cd],[cd_system_desc_txt],
     [last_chg_time],[last_chg_user_id],[local_id],
     [obs_domain_cd_st_1],[obs_domain_cd],[ctrl_cd_display_form],
     [record_status_cd],[record_status_time],[status_cd],[status_time],
     [subject_person_uid],[shared_ind],[version_ctrl_nbr],
     [prog_area_cd],[jurisdiction_cd],[program_jurisdiction_oid],
     [electronic_ind],[target_site_cd],[target_site_desc_txt],[effective_from_time])
VALUES
    (@resulted, '2026-04-21T09:30:00', @superuser_id,
     N'CULT', N'Bacterial culture — Salmonella isolate',
     N'L', N'Local',
     '2026-04-21T09:30:00', @superuser_id, N'OBS22053500GA01',
     N'Result', N'Result', N'LabReport',
    N'ACTIVE', '2026-04-21T09:30:00', N'A', '2026-04-21T09:30:00',
     @pat_uid, N'T', 1,
     N'ENT', N'130001', 20053500,
     N'Y', N'STOOL', N'Stool specimen', '2026-04-20T18:00:00');

-- 35 LABxxx isolate-tracking I_Result children + obs_value_coded.
-- cd: LAB329a, LAB330..LAB363. display_name -> TEST_RESULT_VAL_CD_DESC ->
-- LAB1..LAB35 in the LAB101 pivot.
--
-- DATE PIVOT COLUMNS (CRITICAL — routine 020 hard convert(datetime)):
-- The seven datetime pivot positions LAB6/21/22/28/29/33/34 (sp_lab101 lines
-- 839-845 do `convert(datetime, replace(LAB.LABn,'-',' '),0)`) are sourced
-- from the trtdN.FROM_TIME channel — trtd6=LAB334, trtd21=LAB349,
-- trtd22=LAB350, trtd28=LAB356, trtd29=LAB357, trtd33=LAB361, trtd34=LAB362
-- (lines 462/477/478/484/485/489/490, each gated AND FROM_TIME IS NOT NULL).
-- FROM_TIME = nrt_observation_date.ovd_from_date = obs_value_date.from_time
-- (routine 017 line 740). So the date children must carry an obs_value_date
-- with a real datetime; the convert() then only ever sees a datetime string
-- or NULL and CANNOT throw. The other children get NO obs_value_date (FROM_TIME
-- stays NULL -> those LABn pivots stay NULL -> not date-converted). We feed the
-- date through obs_value_date, NOT obs_value_coded.display_name (the date pivots
-- never read CD_DESC), so the display_name below is plain descriptive text.
DECLARE @date_cds TABLE (cd nvarchar(20) PRIMARY KEY);
INSERT INTO @date_cds(cd) VALUES
    (N'LAB334'),(N'LAB349'),(N'LAB350'),(N'LAB356'),(N'LAB357'),(N'LAB361'),(N'LAB362');
SET @c = 0;
WHILE @c < 35
BEGIN
    DECLARE @child bigint = 22053600 + @c;
    DECLARE @cd nvarchar(20) =
        CASE WHEN @c = 0 THEN N'LAB329a'
             ELSE N'LAB' + CAST(329 + @c AS nvarchar(10)) END;

    INSERT INTO [dbo].[observation]
        ([observation_uid],[add_time],[add_user_id],[cd],[cd_desc_txt],
         [cd_system_cd],[cd_system_desc_txt],
         [last_chg_time],[last_chg_user_id],[local_id],
         [obs_domain_cd_st_1],[obs_domain_cd],[ctrl_cd_display_form],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [subject_person_uid],[shared_ind],[version_ctrl_nbr],
         [prog_area_cd],[jurisdiction_cd],[program_jurisdiction_oid],[electronic_ind])
    VALUES
        (@child, '2026-04-21T09:15:00', @superuser_id,
         @cd, N'Isolate-tracking element ' + @cd,
         N'L', N'Local',
         '2026-04-21T09:15:00', @superuser_id, N'OBS22053500GA01',
         N'I_Result', N'I_Result', N'LabReport',
         N'ACTIVE', '2026-04-21T09:15:00', N'A', '2026-04-21T09:15:00',
         @pat_uid, N'T', 1,
         N'ENT', N'130001', 20053500, N'Y');

    -- coded value -> TEST_RESULT_VAL_CD_DESC. Plain descriptive text for ALL
    -- children (incl. date cds): the date pivots read FROM_TIME, not CD_DESC.
    INSERT INTO [dbo].[obs_value_coded]
        ([observation_uid],[code],[code_system_cd],[code_system_desc_txt],
         [display_name],[alt_cd],[alt_cd_desc_txt],[alt_cd_system_cd],[alt_cd_system_desc_txt])
    VALUES
        (@child, N'VAL' + CAST(@c AS nvarchar(10)), N'L', N'Local',
         N'Value for ' + @cd,
         N'POS', N'Positive', N'L', N'Local');

    -- a few pivot cols read LAB_RESULT_TXT_VAL instead of CD_DESC -> add txt too.
    INSERT INTO [dbo].[obs_value_txt]
        ([observation_uid],[obs_value_txt_seq],[txt_type_cd],[value_txt])
    VALUES
        (@child, 1, N'FT', N'Isolate-tracking text result for ' + @cd);

    -- DATE children only: author obs_value_date so CDC -> nrt_observation_date
    -- -> FROM_TIME (datetime). Non-date children get NO obs_value_date, so their
    -- FROM_TIME stays NULL and routine 020's convert(datetime) yields NULL.
    IF EXISTS (SELECT 1 FROM @date_cds WHERE cd = @cd)
        INSERT INTO [dbo].[obs_value_date]
            ([observation_uid],[obs_value_date_seq],[from_time],[to_time])
        VALUES
            (@child, 1, '2026-04-21T00:00:00', '2026-04-21T00:00:00');

    SET @c += 1;
END;

-- act_id on the I_Order (local id)
INSERT INTO [dbo].[act_id]
    ([act_uid],[act_id_seq],[add_time],[add_user_id],
     [assigning_authority_cd],[assigning_authority_desc_txt],
     [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
     [root_extension_txt],[type_cd],[type_desc_txt],[status_cd],[status_time])
VALUES
    (@i_order, 1, '2026-04-21T08:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     '2026-04-21T08:00:00', @superuser_id, N'ACTIVE', '2026-04-21T08:00:00',
     N'OBS22053500GA01', N'OBS_LOCAL_ID', N'Local Observation Identifier', N'A', '2026-04-21T08:00:00');

-- Lab-internal COMP edges: every child (I_Result, Result, 35 LABxxx) is the
-- SOURCE pointing at the I_Order TARGET, so sp_observation_event emits them
-- in the I_Order's followup_observations JSON.
INSERT INTO [dbo].[act_relationship]
    ([source_act_uid],[target_act_uid],[type_cd],[add_time],[add_user_id],
     [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
     [sequence_nbr],[source_class_cd],[target_class_cd],[status_cd],[status_time],[type_desc_txt])
SELECT s.v, @i_order, N'COMP', '2026-04-21T09:00:00', @superuser_id,
       '2026-04-21T09:00:00', @superuser_id, N'ACTIVE', '2026-04-21T09:00:00',
       ROW_NUMBER() OVER (ORDER BY s.v), N'OBS', N'OBS', N'A', '2026-04-21T09:00:00', N'Component'
FROM (
    SELECT 22053501 AS v UNION ALL SELECT 22053502
    UNION ALL SELECT 22053600 + n FROM (
        SELECT TOP (35) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
        FROM sys.all_objects
    ) AS nums
) AS s;

-- Participations on the I_Order so LAB101 demographics resolve too.
INSERT INTO [dbo].[participation]
    ([subject_entity_uid],[act_uid],[type_cd],[act_class_cd],[add_time],[add_user_id],
     [last_chg_time],[last_chg_user_id],[record_status_cd],[record_status_time],
     [status_cd],[status_time],[subject_class_cd],[type_desc_txt])
VALUES
    (@pat_uid,  @i_order, N'PATSBJ', N'OBS', '2026-04-21T08:00:00', @superuser_id,
     '2026-04-21T08:00:00', @superuser_id, N'ACTIVE', '2026-04-21T08:00:00',
     N'A', '2026-04-21T08:00:00', N'PSN', N'Patient Subject'),
    (@prov_uid, @i_order, N'ORD',    N'OBS', '2026-04-21T08:00:00', @superuser_id,
     '2026-04-21T08:00:00', @superuser_id, N'ACTIVE', '2026-04-21T08:00:00',
     N'A', '2026-04-21T08:00:00', N'PSN', N'Ordering Provider'),
    (@org_uid,  @i_order, N'AUT',    N'OBS', '2026-04-21T08:00:00', @superuser_id,
     '2026-04-21T08:00:00', @superuser_id, N'ACTIVE', '2026-04-21T08:00:00',
     N'A', '2026-04-21T08:00:00', N'ORG', N'Author/Reporting Organization'),
    (@org_uid,  @i_order, N'ORD',    N'OBS', '2026-04-21T08:00:00', @superuser_id,
     '2026-04-21T08:00:00', @superuser_id, N'ACTIVE', '2026-04-21T08:00:00',
     N'A', '2026-04-21T08:00:00', N'ORG', N'Ordering Organization');
GO
