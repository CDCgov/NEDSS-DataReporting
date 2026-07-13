-- =====================================================================
-- Tier 3 — COVID-19 Investigation full ODSE + nrt + NBS_case_answer chain
-- =====================================================================
-- Goal: unblock the COVID-19 datamart cluster (`COVID_CASE_DATAMART`
-- 383 cols, `COVID_CONTACT_DATAMART` 94, `COVID_LAB_DATAMART` 129,
-- `COVID_LAB_CELR_DATAMART` 101, `COVID_VACCINATION_DATAMART` 60).
-- This fixture unblocks `COVID_CASE_DATAMART` directly; the lab /
-- contact / vaccination datamarts depend on additional inputs
-- (LAB observations linked to the COVID Investigation, vaccinations
-- gated on condition_cd via patient, ct_contact rows) that this
-- fixture does NOT author — those become follow-on Tier 3 work.
--
-- WHY A NEW UID, NOT AN UPGRADE
--   The existing COVID stub at public_health_case_uid 22000070 in
--   `multi_condition_investigations.sql` writes only an nrt_investigation
--   row (no ODSE-side act/PHC, no nbs_case_answer, no
--   nrt_page_case_answer). It populates `COVID_CASE_DATAMART` with
--   only the core/patient/entity columns (~30 of 383). We leave it
--   untouched and allocate a NEW COVID Investigation at 22003000 with
--   the full ODSE + staging + page-answer chain so:
--     - the stub continues exercising the no-answers path
--     - the new variant exercises the discrete-answers / multi-answers
--       paths that drive ~440 ALTER-TABLE-added datamart columns
--   Together they cover both branches of the COVID datamart SP.
--
-- WHAT THIS FIXTURE AUTHORS
--   1. ODSE chain (NBS_ODSE):
--        - act                (act_uid=22003000, class='CASE', mood='EVN')
--        - public_health_case (cd='11065' COVID-19, prog_area_cd='COV',
--                              investigation_form_cd='PG_COVID-19_v1.1',
--                              case_class_cd='C', jurisdiction_cd='130001')
--        - act_id             (PHC_LOCAL_ID assigning_authority)
--        - case_management    (IDENTITY-inserted; matches Tier 1 v2 shape)
--        - nbs_case_answer    rows for each COVID-form question we want
--                              exercised — datamart-column-mapped questions
--                              covering Symptoms (FEVER, HEADACHE,
--                              MYALGIA, FATIGUE_MALAISE, CHILLS_RIGORS,
--                              NAUSEA, DIARRHEA, ABDOMINAL_PAIN, ALT_MENTAL_STATUS),
--                              Disposition (HOSPITAL_ICU_STAY,
--                              US_HC_WORKER_IND), Exposure (TRAVEL_DOMESTICALLY,
--                              TRAVEL_INTERNATIONAL, CRUISE_TRAVEL_EXP,
--                              AIR_TRAVEL_EXP, WORKPLACE_EXP, ANIMAL_EXPOSURE_IND),
--                              Labs (TEST_TYPE, TEST_RESULT,
--                              PERFORMING_LAB_TYPE), Comorbidity
--                              (HYPERTENSION), Date (FIRST_RPT_TO_PHD_DT),
--                              Status (Symptomatic).
--   2. RDB_MODERN staging (mirrors the kafka-connect JDBC sink writes):
--        - nrt_investigation row keyed on public_health_case_uid 22003000
--          with patient_id=20000000 (foundation Patient), the
--          investigation_form_cd='PG_COVID-19_v1.1', and case_class_cd='C',
--          condition_cd='11065'. patient_id INLINED as the literal
--          20000000 (NOT @foundation_patient_uid — cross-batch DECLARE
--          scope; see TB-chain fixture, bug #5b convention).
--        - nrt_page_case_answer rows — one per COVID question, with
--          nbs_question_uid, datamart_column_nm, user_defined_column_nm
--          equivalents (the COVID SP reads user_defined_column_nm via
--          NRT_ODSE_NBS_RDB_METADATA, not datamart_column_nm directly),
--          code_set_group_id, question_identifier, data_location,
--          answer_txt, ldf_status_cd=NULL, batch_id=NULL,
--          last_chg_time set so all the COVID datamart SP joins and
--          predicates resolve correctly. Question UIDs and
--          code_set_group_ids verified live against
--          NBS_ODSE.dbo.nbs_question + dbo.nbs_ui_metadata on 2026-05-21.
--   3. Does NOT author nrt_investigation_confirmation (foundation /
--      v2 Investigation cover the confirmation-method LEFT JOIN path
--      with NULL).
--   4. Does NOT author followup observations, ct_contact rows, or
--      vaccinations — those would be needed to unblock the other 4
--      COVID datamarts (lab, lab_celr, contact, vaccination). The
--      orchestrator's Step 9 invokes those SPs with the existing
--      LAB_OBS_UIDS / VAC_UIDS / CT_UIDS lists; with no
--      condition_cd='11065' observations / vaccinations / contacts
--      in scope, they currently no-op. Follow-on Tier 3 work.
--
-- VERIFICATION CALL-CHAIN (tail-EXECs at bottom)
--   sp_nrt_investigation_postprocessing — flows nrt_investigation → INVESTIGATION
--   (sp_covid_case_datamart_postprocessing — NOT run here; Step 9
--    owns it. Running here would double-INSERT.)
--   COVID has NO dedicated *_dim_postprocessing or *_pam_postprocessing
--   chain analogous to TB-PAM (verified by grep against
--   `005-rdb_modern/routines/` 2026-05-21: the only COVID-named SPs are
--   the 5 datamart SPs at 310, 315, 320, 325, 330 — all Step-9 owned).
--   Thus this fixture's tail-EXEC is short: just the standard
--   `sp_nrt_investigation_postprocessing` to flow the new Investigation
--   into INVESTIGATION (so Step 9's COVID case datamart's
--   `INNER JOIN INVESTIGATION` can resolve when patients_uid /
--   entities are needed downstream).
--
-- DYN_DM NOTE
--   `PG_COVID-19_v1.1` is NOT present as a `FORM_CD` in
--   `RDB_MODERN.dbo.v_nrt_nbs_page` (verified live 2026-05-21 — only
--   `PG_MIS_C_Investigation_Page → MIS_COVID_19` is). Therefore the
--   orchestrator's dyn_dm Step 9 chain (which auto-discovers via
--   v_nrt_nbs_page) will NOT invoke any DM_INV_* for this fixture.
--   Bug #9 (dyn_dm UNPIVOT type conflict) is therefore not triggered
--   by this fixture.
--
-- UID block (Tier 3 full-chain COVID Investigation): 22003000-22003999
--   22003000  public_health_case.public_health_case_uid (act.act_uid;
--             nrt_investigation.public_health_case_uid;
--             nrt_page_case_answer.act_uid for every answer row)
--   22003001  case_management.case_management_uid (IDENTITY-inserted)
--   22003100..22003121  nbs_case_answer.nbs_case_answer_uid +
--             nrt_page_case_answer.nbs_case_answer_uid for each
--             authored COVID answer row (22 questions; curated set
--             spans 6 categories: symptoms, exposure, labs, disposition,
--             comorbidity, status).
--
-- Foundation dependencies (read-only):
--   @superuser_id              10009282
--   @foundation_patient_uid    20000000   (D_PATIENT row exists;
--                                          nrt_patient with status_name_cd='A'
--                                          and nm_use_cd='L' — the COVID
--                                          SP's #COVID_PATIENT_DATA join
--                                          predicates).
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;

-- ----- New COVID Investigation full-chain UIDs -----
DECLARE @covid_full_phc_uid          bigint = 22003000;  -- act.act_uid + public_health_case.public_health_case_uid
DECLARE @covid_full_case_mgmt_uid    bigint = 22003001;  -- case_management.case_management_uid

-- =====================================================================
-- ODSE: act parent row
-- =====================================================================
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@covid_full_phc_uid, N'CASE', N'EVN');

-- =====================================================================
-- ODSE: public_health_case row
-- =====================================================================
-- SRTE-verified codes (queried 2026-05-21):
--   condition_code.condition_cd='11065' 2019 Novel Coronavirus,
--     prog_area_cd='GCD' (General Communicable Disease) per SRTE,
--     investigation_form_cd='PG_COVID-19_v1.1'.
--     [NOTE: The multi-condition stub uses prog_area_cd='COV' which
--     does NOT match the SRTE-canonical 'GCD'. We follow the stub here
--     for consistency with the Step 9 chain (the SP filters on `cd`
--     and `investigation_form_cd`, not `prog_area_cd`). prog_area_cd
--     mismatch flagged in coverage report.]
--   code_value_general PHC_CLASS 'C' (Confirmed).
--   code_value_general PHC_IN_STS 'O' (Open).
--   jurisdiction_code '130001' Fulton County.
-- PHC-CORE SCALAR ENRICHMENT (Round 5 item C, Part 2):
--   The columns below feed sp_covid_case_datamart_postprocessing Step 4
--   (#COVID_CASE_CORE_DATA, routine 310 lines 168-204) via NRT_INVESTIGATION
--   (which the service rebuilds from this public_health_case row). Each
--   value uses a realistic COVID scenario + a valid coded value resolved
--   from the SRTE code sets (verified live 2026-06-04):
--     hospitalized_ind_cd      'Y'        (YNU)          -> HSPTLIZD_IND
--     hospitalized_admin_time/_discharge_time/_duration_amt -> HSPTL_* (admit/discharge/duration)
--     diagnosis_time           -> DIAGNOSIS_DT
--     effective_from_time/_to_time -> ILLNESS_ONSET_DT / ILLNESS_END_DT
--     effective_duration_amt   14 / _unit_cd 'D' (DUR_UNIT Days) -> ILLNESS_DURATION / _UNIT
--     pat_age_at_onset         47 / _unit_cd 'Y' (P_AGE_UNIT Years) -> PATIENT_ONSET_AGE / _UNIT
--     pregnant_ind_cd          'N'        (YNU; male patient)  -> PATIENT_PREGNANT_IND
--     outcome_cd               'D'        (PHC_OUTCM Died) -> DIE_FROM_ILLNESS_IND
--     deceased_time            -> INV_DEATH_DT
--     day_care_ind_cd          'N' / food_handler_ind_cd 'N' (YNU) -> DAYCARE_ASSOC_IND / FOOD_HANDLER_IND
--     disease_imported_cd      'OOS'      (PHC_IMPRT Out of state) -> DISEASE_IMPORTED_IND
--     imported_country_cd '840' (US) / imported_state_cd '12' (FL) /
--       imported_county_cd '12086' (Miami-Dade) / imported_city_desc_txt 'Miami'
--       -> IMPORT_FROM_CNTRY / _STATE / _CNTY / _CITY
--     transmission_mode_cd     'OTH'      (PHVS_TRANSMISSIONMODE_ARBOVIRUS Other; COVID respiratory not enumerated) -> TRANSMISSION_MODE_CD
--     detection_method_cd      'PHC2112'  (PHC_DET_MT Laboratory reported) -> DETECT_METHOD_CD
--     rpt_source_cd            'LA'       (PHC_RPT_SRC_T Laboratory) -> RPT_SOURCE_CD
--     txt                      -> INV_COMMENTS ; activity_from_time -> INV_START_DT
--     investigator_assigned_time -> INV_ASSIGNED_DT ; rpt_form_cmplt_time -> INV_RPT_DT
--     rpt_to_county_time / rpt_to_state_time -> EARLIEST_RPT_TO_CNTY_DT / _ST_DT
--     inv_priority_cd          'HIGH'     (NBS_PRIORITY) -> CTT_INV_PRIORITY_CD
--     infectious_from_date / infectious_to_date -> CTT_INFECTIOUS_FROM_DT / _TO_DT
--     contact_inv_status_cd    'O'        (PHC_IN_STS Open) -> CTT_INV_STATUS
--     contact_inv_txt          -> CTT_INV_COMMENTS
--   GENERATED ALWAYS period cols are omitted. NOTES / INV_STATE_CASE_ID /
--   INV_LEGACY_CASE_ID are NOT public_health_case scalars (NRT_INVESTIGATION
--   derives them from NBS_Note / other paths) and are deliberately left.
INSERT INTO [dbo].[public_health_case]
    ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
     [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
     [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [outbreak_ind], [outbreak_name],
     [mmwr_week], [mmwr_year],
     [hospitalized_ind_cd], [hospitalized_admin_time], [hospitalized_discharge_time],
     [hospitalized_duration_amt], [diagnosis_time],
     [effective_from_time], [effective_to_time],
     [effective_duration_amt], [effective_duration_unit_cd],
     [pat_age_at_onset], [pat_age_at_onset_unit_cd], [pregnant_ind_cd],
     [outcome_cd], [deceased_time], [day_care_ind_cd], [food_handler_ind_cd],
     [disease_imported_cd], [imported_country_cd], [imported_state_cd],
     [imported_county_cd], [imported_city_desc_txt],
     [transmission_mode_cd], [detection_method_cd], [rpt_source_cd], [txt],
     [activity_from_time], [investigator_assigned_time], [rpt_form_cmplt_time],
     [rpt_to_county_time], [rpt_to_state_time],
     [inv_priority_cd], [infectious_from_date], [infectious_to_date],
     [contact_inv_status_cd], [contact_inv_txt])
VALUES
    (@covid_full_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'I',
     N'C', N'11065', N'2019 Novel Coronavirus', N'NND', N'NND',
     N'O', CAST(GETDATE() AS DATE), @superuser_id, N'CAS22003000GA01',
     N'OPEN', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'T', 1, N'COV', N'130001',
     22003000, N'N', NULL,
     N'14', N'2026',
     N'Y', '2026-03-20T08:00:00', '2026-03-30T10:00:00',
     10, '2026-03-18T00:00:00',
     '2026-03-12T00:00:00', '2026-04-02T00:00:00',
     14, N'D',
     47, N'Y', N'N',
     N'D', '2026-04-02T12:00:00', N'N', N'N',
     N'OOS', N'840', N'12',
     N'12086', N'Miami',
     N'OTH', N'PHC2112', N'LA', N'COVID-19 confirmed case; patient hospitalized and expired.',
     '2026-03-15T00:00:00', '2026-03-16T00:00:00', '2026-04-05T00:00:00',
     '2026-03-16T00:00:00', '2026-03-17T00:00:00',
     N'HIGH', '2026-03-10T00:00:00', '2026-03-25T00:00:00',
     N'O', N'Contact tracing initiated for household and workplace contacts.');

-- =====================================================================
-- ODSE: act_id (PHC_LOCAL_ID) — matches the canonical Investigation pattern
-- =====================================================================
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@covid_full_phc_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE',
     '2026-04-01T00:00:00', N'CAS22003000GA01', N'PHC_LOCAL_ID',
     N'Local Public Health Case Identifier', N'A', '2026-04-01T00:00:00');

-- =====================================================================
-- ODSE: case_management (minimal; matches Tier 1 v2 Investigation shape)
-- IDENTITY column requires IDENTITY_INSERT toggle to pin our UID.
-- =====================================================================
SET IDENTITY_INSERT [dbo].[case_management] ON;
INSERT INTO [dbo].[case_management]
    ([case_management_uid], [public_health_case_uid], [status_900],
     [field_record_number], [surv_assigned_date],
     [surv_closed_date], [case_closed_date])
VALUES
    (@covid_full_case_mgmt_uid, @covid_full_phc_uid, N'C',
     N'FRN-COVID-FULL-01', '2026-04-02T00:00:00',
     '2026-04-30T00:00:00', '2026-04-30T00:00:00');
SET IDENTITY_INSERT [dbo].[case_management] OFF;

GO

-- =====================================================================
-- ODSE: nbs_case_answer — one row per COVID question we author.
-- These satisfy the ODSE-side referential model. The downstream RTR
-- COVID datamart SP does NOT read this table directly — it reads
-- dbo.nrt_page_case_answer in RDB_MODERN, which the kafka-connect JDBC
-- sink writes. We mirror those staging rows below.
--
-- COVID question UIDs verified live against
-- NBS_ODSE.dbo.nbs_question + dbo.nbs_ui_metadata WHERE
-- investigation_form_cd='PG_COVID-19_v1.1' AND data_location LIKE
-- '%Answer_txt' AND nbs_ui_component_uid NOT IN (1013, 1025) — these
-- are the "discrete data" Type 1 questions the SP pivots into
-- COVID_CASE_DATAMART columns (Step 4 / Step 8 in the SP).
-- =====================================================================

DECLARE @superuser_id_2 bigint = 10009282;
DECLARE @covid_full_phc_uid_2 bigint = 22003000;

-- nbs_case_answer.nbs_case_answer_uid is an IDENTITY column. We let it
-- AUTO-assign (LESSON 10: hardcoded IDENTITY_INSERT UIDs collide with the
-- auto-IDENTITY flood from zz_page_answers_datamart_routing.sql and the
-- guard silently skips the whole INSERT). The pipeline keys page answers
-- on (act_uid, nbs_question_uid, seq_nbr), so the surrogate UID is
-- irrelevant. Guard on the natural key (act_uid, first nbs_question_uid).
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @covid_full_phc_uid_2 AND nbs_question_uid = 10001378 AND answer_group_seq_nbr IS NULL)
BEGIN
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid], [add_time], [add_user_id],
     [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [seq_nbr])
VALUES
    -- ===== Symptoms (PHVS YNU code_set_group_id 4150) =====
    -- 386661006 FEVER -> Y
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 10001378, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 43724002 CHILLS_RIGORS -> Y
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 10001379, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 271795006 FATIGUE_MALAISE -> Y
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 10001380, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 25064002 HEADACHE -> Y
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 10001382, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 68962001 MYALGIA -> Y
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 10001383, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 419284004 ALT_MENTAL_STATUS -> N
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10001390, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 16932000 NAUSEA -> N
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10001394, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 62315008 DIARRHEA -> N
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10001395, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 21522001 ABDOMINAL_PAIN -> N
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10001396, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),

    -- ===== Disposition (4150) =====
    -- 309904001 HOSPITAL_ICU_STAY -> N
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004144, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- NBS540 US_HC_WORKER_IND -> N
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004148, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),

    -- ===== Exposure (4150) =====
    -- INV664 TRAVEL_DOMESTICALLY -> N
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004151, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TRAVEL38 TRAVEL_INTERNATIONAL -> N
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004153, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 473085002 CRUISE_TRAVEL_EXP -> N
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004155, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 445000002 AIR_TRAVEL_EXP -> N
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004160, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- NBS684 WORKPLACE_EXP -> N
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004157, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- NBS559 ANIMAL_EXPOSURE_IND -> N
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004165, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),

    -- ===== Labs =====
    -- INV290 TEST_TYPE -> '94309-2' SARS coronavirus 2 RNA NAA (code_set_group 108020)
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'94309-2', 10001370, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- INV291 TEST_RESULT -> '10828004' Positive (code_set_group 108610)
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'10828004', 10001371, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- LAB606 PERFORMING_LAB_TYPE -> 'PHC1317' Hospital Laboratory (108620)
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'PHC1317', 10001374, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),

    -- ===== Comorbidity / Status (4150) =====
    -- ARB017 HYPERTENSION -> N
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10000075, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- INV576 Symptomatic -> Y
    (@covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 10001027, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0);
END

GO

-- =====================================================================
-- RDB_MODERN: staging rows that the RTR postprocessing chain consumes.
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- nrt_investigation row for the full-chain COVID Investigation.
-- Mirrors the v2 Tier 1 Investigation shape from
-- fixtures/10_subjects/investigation.sql but with COVID-specific codes.
--   patient_id = 20000000 (INLINED literal — foundation Patient). Required
--     so the COVID SP's #COVID_PATIENT_DATA join
--     `LEFT OUTER JOIN dbo.D_PATIENT pat ON inv.patient_id = pat.patient_uid`
--     and the `LEFT OUTER JOIN dbo.NRT_PATIENT nrtPat ON nrtPat.patient_uid
--     = pat.patient_uid AND nrtPat.status_name_cd='A' AND nrtPat.nm_use_cd='L'`
--     both resolve to populated rows. Per bug-5b convention
--     (fixtures/10_subjects/investigation.sql), inline literal here —
--     @foundation_patient_uid DECLARE would be out of scope after the
--     prior GO batch.
--   cd = '11065' — required by the SP at line 76:
--     `inner join (...) on nrtInv.public_health_case_uid = phcList.value
--     and nrtInv.cd = @conditionCd` where @conditionCd is hardcoded '11065'.
--   investigation_form_cd = 'PG_COVID-19_v1.1' — drives the inv_form_cd
--     filter on `NRT_ODSE_NBS_UI_METADATA` joins (lines 390, 455, 474,
--     etc. throughout the SP).
--   batch_id NULL — matches the existing convention.
--   case_management_uid populated so the (separate Tier 3) f_page_case
--     filter can compute COALESCEs cleanly.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_page_case_answer rows. One per COVID question we want exercised.
-- Each row mirrors what a kafka-connect JDBC sink would write after the
-- upstream page-builder service joined nbs_case_answer to
-- nbs_question / nbs_ui_metadata. The COVID datamart SP reads:
--   act_uid (= the Investigation's public_health_case_uid)
--   nbs_question_uid (joined to NRT_ODSE_NBS_UI_METADATA.nbs_question_uid)
--   answer_txt (CODE value joined to nrt_srte_Code_value_general via
--     codeset/code_set_group_id from NRT_ODSE_NBS_UI_METADATA)
--   data_location (filters `LIKE '%ANSWER_TXT'`, case-insensitive
--     collation)
--   seq_nbr (NULL for discrete, NOT NULL for multi-select)
-- The SP's PIVOT uses `user_defined_column_nm` from
-- NRT_ODSE_NBS_RDB_METADATA — that metadata is already populated for
-- PG_COVID-19_v1.1 (verified 2026-05-21: 470 metadata rows for the form).
--
-- NOT-NULL columns:
--   act_uid, nbs_case_answer_uid, nbs_ui_metadata_uid, nbs_question_uid,
--   record_status_cd, refresh_datetime, max_datetime.
-- nbs_ui_metadata_uid has no FK constraint; we use a stable
-- block-internal value (1 — production allocates per ui_metadata row;
-- the COVID datamart SP does not read this column directly — it joins
-- by nbs_question_uid).
-- ---------------------------------------------------------------------

GO

-- =====================================================================
-- Tail-EXEC the SP chain in dependency order.
--
-- Step A: flow the new nrt_investigation row into INVESTIGATION.
--   sp_nrt_investigation_postprocessing reads nrt_investigation,
--   writes INVESTIGATION row keyed on case_uid=22003000. Required so
--   the COVID datamart SP's `LEFT OUTER JOIN dbo.INVESTIGATION
--   INVESTIGATION ON cte.public_health_case_uid = INVESTIGATION.CASE_UID`
--   resolves to a populated row.
-- =====================================================================


-- =====================================================================
-- COVID case datamart SP — NOT run from this fixture.
--   sp_covid_case_datamart_postprocessing is invoked by Step 9 of
--   merge_and_verify.sh against the global PHC_UIDS list. The
--   orchestrator's PHC_UIDS must be extended to include 22003000 so
--   that Step 9 picks it up. Running it here in addition would
--   produce double rows because the SP does DELETE-then-INSERT per
--   PHC, and Step 9 would re-execute identically.
--
--   (The SP at line 110-111 has a delete-first guard — it clears
--      COVID_CASE_DATAMART rows for the PHCs in #PHC_LIST before insert —
--   so re-execution is idempotent for a SINGLE invocation. Tail-EXEC +
--   Step 9 = 2 invocations, which IS idempotent — but conservative
--   pattern: leave Step 9 as the single owner, matching TB-fixture
--   convention.)
-- =====================================================================

-- =====================================================================
-- Other COVID datamarts (lab, lab_celr, contact, vaccination) — also
-- NOT run from this fixture, AND not expected to populate without
-- additional Tier 3 work:
--
--   sp_covid_lab_datamart_postprocessing / sp_covid_lab_celr_datamart_postprocessing
--     read `@observation_id_list` / `@obs_uids`. The orchestrator
--     passes LAB_OBS_UIDS='20000120,20070010'; both labs are bound to
--     condition_cd '10110' Hep A (via nrt_srte_Loinc_condition for
--     LOINC '13950-1'). To make these populate for COVID we'd need a
--     COVID-coded LAB observation (cd='94309-2' / '94500-6' /
--     LOINC's COVID code) plus a Tier 2 lab_inv act_relationship to
--     the COVID Investigation. Out of scope for this fixture.
--
--   sp_covid_contact_datamart_postprocessing reads from ct_contact +
--     nrt_investigation filtered on condition_cd='11065'. Foundation
--     ct_contact (20000170) has no condition_cd link to a COVID inv.
--     Out of scope.
--
--   sp_covid_vaccination_datamart_postprocessing reads from
--     nrt_vaccination filtered on vaccination/condition mapping.
--     No COVID vaccination exists. Out of scope.
-- =====================================================================
