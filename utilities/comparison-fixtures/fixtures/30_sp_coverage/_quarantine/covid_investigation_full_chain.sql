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
INSERT INTO [dbo].[public_health_case]
    ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
     [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
     [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [outbreak_ind], [outbreak_name],
     [mmwr_week], [mmwr_year])
VALUES
    (@covid_full_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'I',
     N'C', N'11065', N'2019 Novel Coronavirus', N'NND', N'NND',
     N'O', '2026-04-01T00:00:00', @superuser_id, N'CAS22003000GA01',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'T', 1, N'COV', N'130001',
     22003000, N'N', NULL,
     N'14', N'2026');

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
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE',
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

INSERT INTO [dbo].[nbs_case_answer]
    ([nbs_case_answer_uid], [act_uid], [add_time], [add_user_id],
     [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [seq_nbr])
VALUES
    -- ===== Symptoms (PHVS YNU code_set_group_id 4150) =====
    -- 386661006 FEVER -> Y
    (22003100, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 10001378, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 43724002 CHILLS_RIGORS -> Y
    (22003101, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 10001379, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 271795006 FATIGUE_MALAISE -> Y
    (22003102, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 10001380, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 25064002 HEADACHE -> Y
    (22003103, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 10001382, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 68962001 MYALGIA -> Y
    (22003104, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 10001383, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 419284004 ALT_MENTAL_STATUS -> N
    (22003105, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10001390, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 16932000 NAUSEA -> N
    (22003106, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10001394, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 62315008 DIARRHEA -> N
    (22003107, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10001395, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 21522001 ABDOMINAL_PAIN -> N
    (22003108, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10001396, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),

    -- ===== Disposition (4150) =====
    -- 309904001 HOSPITAL_ICU_STAY -> N
    (22003109, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004144, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- NBS540 US_HC_WORKER_IND -> N
    (22003110, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004148, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),

    -- ===== Exposure (4150) =====
    -- INV664 TRAVEL_DOMESTICALLY -> N
    (22003111, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004151, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- TRAVEL38 TRAVEL_INTERNATIONAL -> N
    (22003112, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004153, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 473085002 CRUISE_TRAVEL_EXP -> N
    (22003113, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004155, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- 445000002 AIR_TRAVEL_EXP -> N
    (22003114, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004160, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- NBS684 WORKPLACE_EXP -> N
    (22003115, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004157, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- NBS559 ANIMAL_EXPOSURE_IND -> N
    (22003116, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10004165, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),

    -- ===== Labs =====
    -- INV290 TEST_TYPE -> '94309-2' SARS coronavirus 2 RNA NAA (code_set_group 108020)
    (22003117, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'94309-2', 10001370, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- INV291 TEST_RESULT -> '10828004' Positive (code_set_group 108610)
    (22003118, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'10828004', 10001371, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- LAB606 PERFORMING_LAB_TYPE -> 'PHC1317' Hospital Laboratory (108620)
    (22003119, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'PHC1317', 10001374, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),

    -- ===== Comorbidity / Status (4150) =====
    -- ARB017 HYPERTENSION -> N
    (22003120, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10000075, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- INV576 Symptomatic -> Y
    (22003121, @covid_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 10001027, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0);

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
INSERT INTO [dbo].[nrt_investigation]
    ([public_health_case_uid], [patient_id], [program_jurisdiction_oid],
     [local_id], [shared_ind], [case_type_cd],
     [jurisdiction_cd], [record_status_cd], [mood_cd], [class_cd],
     [case_class_cd], [cd], [cd_desc_txt], [prog_area_cd],
     [investigation_form_cd], [case_management_uid],
     [investigation_status_cd], [investigation_status],
     [inv_case_status],
     [status_time], [record_status_time], [raw_record_status_cd],
     [add_user_id], [add_user_name], [add_time],
     [last_chg_user_id], [last_chg_user_name], [last_chg_time],
     [mmwr_week], [mmwr_year],
     [nac_page_case_uid],
     [outbreak_ind])
VALUES
    (22003000,                              -- public_health_case_uid
     20000000,                              -- patient_id (foundation Patient)
     22003000,                              -- program_jurisdiction_oid
     N'CAS22003000GA01',                    -- local_id
     N'T',                                  -- shared_ind
     N'I',                                  -- case_type_cd
     N'130001',                             -- jurisdiction_cd (Fulton)
     N'ACTIVE',                             -- record_status_cd
     N'EVN', N'CASE',                       -- mood_cd, class_cd
     N'C', N'11065', N'2019 Novel Coronavirus', N'COV', -- case_class_cd, cd, cd_desc, prog
     N'PG_COVID-19_v1.1',                   -- investigation_form_cd
     22003001,                              -- case_management_uid
     N'O', N'Open',
     N'Confirmed',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     10009282, N'Foundation, Superuser', '2026-04-01T00:00:00',
     10009282, N'Foundation, Superuser', '2026-04-01T00:00:00',
     N'14', N'2026',
     22003000,                              -- nac_page_case_uid
     N'N');                                 -- outbreak_ind

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
INSERT INTO [dbo].[nrt_page_case_answer]
    ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid],
     [nbs_question_uid],
     [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr],
     [investigation_form_cd], [question_identifier], [data_location],
     [code_set_group_id], [last_chg_time], [record_status_cd],
     [datamart_column_nm], [ldf_status_cd], [seq_nbr], [batch_id])
VALUES
    -- ===== Symptoms (code_set_group 4150 YNU) =====
    (22003000, 22003100, 1, 10001378, N'COVID_CASE', N'FEVER',
     N'Y', NULL, N'PG_COVID-19_v1.1', N'386661006',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'FEVER', NULL, NULL, NULL),
    (22003000, 22003101, 1, 10001379, N'COVID_CASE', N'CHILLS_RIGORS',
     N'Y', NULL, N'PG_COVID-19_v1.1', N'43724002',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CHILLS_RIGORS', NULL, NULL, NULL),
    (22003000, 22003102, 1, 10001380, N'COVID_CASE', N'FATIGUE_MALAISE',
     N'Y', NULL, N'PG_COVID-19_v1.1', N'271795006',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'FATIGUE_MALAISE', NULL, NULL, NULL),
    (22003000, 22003103, 1, 10001382, N'COVID_CASE', N'HEADACHE',
     N'Y', NULL, N'PG_COVID-19_v1.1', N'25064002',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'HEADACHE', NULL, NULL, NULL),
    (22003000, 22003104, 1, 10001383, N'COVID_CASE', N'MYALGIA',
     N'Y', NULL, N'PG_COVID-19_v1.1', N'68962001',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'MYALGIA', NULL, NULL, NULL),
    (22003000, 22003105, 1, 10001390, N'COVID_CASE', N'ALT_MENTAL_STATUS',
     N'N', NULL, N'PG_COVID-19_v1.1', N'419284004',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'ALT_MENTAL_STATUS', NULL, NULL, NULL),
    (22003000, 22003106, 1, 10001394, N'COVID_CASE', N'NAUSEA',
     N'N', NULL, N'PG_COVID-19_v1.1', N'16932000',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'NAUSEA', NULL, NULL, NULL),
    (22003000, 22003107, 1, 10001395, N'COVID_CASE', N'DIARRHEA',
     N'N', NULL, N'PG_COVID-19_v1.1', N'62315008',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'DIARRHEA', NULL, NULL, NULL),
    (22003000, 22003108, 1, 10001396, N'COVID_CASE', N'ABDOMINAL_PAIN',
     N'N', NULL, N'PG_COVID-19_v1.1', N'21522001',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'ABDOMINAL_PAIN', NULL, NULL, NULL),

    -- ===== Disposition (4150) =====
    (22003000, 22003109, 1, 10004144, N'COVID_CASE', N'HOSPITAL_ICU_STAY',
     N'N', NULL, N'PG_COVID-19_v1.1', N'309904001',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'HOSPITAL_ICU_STAY', NULL, NULL, NULL),
    (22003000, 22003110, 1, 10004148, N'COVID_CASE', N'US_HC_WORKER_IND',
     N'N', NULL, N'PG_COVID-19_v1.1', N'NBS540',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'US_HC_WORKER_IND', NULL, NULL, NULL),

    -- ===== Exposure (4150) =====
    (22003000, 22003111, 1, 10004151, N'COVID_CASE', N'TRAVEL_DOMESTICALLY',
     N'N', NULL, N'PG_COVID-19_v1.1', N'INV664',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_DOMESTICALLY', NULL, NULL, NULL),
    (22003000, 22003112, 1, 10004153, N'COVID_CASE', N'TRAVEL_INTERNATIONAL',
     N'N', NULL, N'PG_COVID-19_v1.1', N'TRAVEL38',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_INTERNATIONAL', NULL, NULL, NULL),
    (22003000, 22003113, 1, 10004155, N'COVID_CASE', N'CRUISE_TRAVEL_EXP',
     N'N', NULL, N'PG_COVID-19_v1.1', N'473085002',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'CRUISE_TRAVEL_EXP', NULL, NULL, NULL),
    (22003000, 22003114, 1, 10004160, N'COVID_CASE', N'AIR_TRAVEL_EXP',
     N'N', NULL, N'PG_COVID-19_v1.1', N'445000002',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'AIR_TRAVEL_EXP', NULL, NULL, NULL),
    (22003000, 22003115, 1, 10004157, N'COVID_CASE', N'WORKPLACE_EXP',
     N'N', NULL, N'PG_COVID-19_v1.1', N'NBS684',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'WORKPLACE_EXP', NULL, NULL, NULL),
    (22003000, 22003116, 1, 10004165, N'COVID_CASE', N'ANIMAL_EXPOSURE_IND',
     N'N', NULL, N'PG_COVID-19_v1.1', N'NBS559',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'ANIMAL_EXPOSURE_IND', NULL, NULL, NULL),

    -- ===== Labs (Type 3 / repeating block — nbs_ui_metadata.question_group_seq_nbr=4) =====
    -- Per SP line 805: `caseAns.answer_group_seq_nbr=1` for the _1
    -- pivot, =2 for _2, =3 for _3 (the SP only supports up to 3
    -- repeating instances — see Step 4 SP header comment lines 26-28).
    -- We author all 3 lab questions as the first repeat instance (=1)
    -- so they land in TEST_TYPE_1 / TEST_RESULT_1 / PERFORMING_LAB_TYPE_1.
    --
    -- INV290 TEST_TYPE: '94309-2' SARS coronavirus 2 RNA NAA
    --   (code_set_group 108020 = TEST_TYPE_COVID)
    (22003000, 22003117, 1, 10001370, N'COVID_CASE', N'TEST_TYPE',
     N'94309-2', N'1', N'PG_COVID-19_v1.1', N'INV290',
     N'NBS_Case_Answer.answer_txt', 108020,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TEST_TYPE', NULL, 1, NULL),
    -- INV291 TEST_RESULT: '10828004' Positive
    --   (code_set_group 108610 = PHVS_LABTESTINTERPRETATION_VPD_COVID19)
    (22003000, 22003118, 1, 10001371, N'COVID_CASE', N'TEST_RESULT',
     N'10828004', N'1', N'PG_COVID-19_v1.1', N'INV291',
     N'NBS_Case_Answer.answer_txt', 108610,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TEST_RESULT', NULL, 1, NULL),
    -- LAB606 PERFORMING_LAB_TYPE: 'PHC1317' Hospital Laboratory
    --   (code_set_group 108620 = PHVS_PERFORMINGLABORATORYTYPE_VPD_COVID19)
    (22003000, 22003119, 1, 10001374, N'COVID_CASE', N'PERFORMING_LAB_TYPE',
     N'PHC1317', N'1', N'PG_COVID-19_v1.1', N'LAB606',
     N'NBS_Case_Answer.answer_txt', 108620,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'PERFORMING_LAB_TYPE', NULL, 1, NULL),

    -- ===== Comorbidity / Status (4150) =====
    (22003000, 22003120, 1, 10000075, N'COVID_CASE', N'HYPERTENSION',
     N'N', NULL, N'PG_COVID-19_v1.1', N'ARB017',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'HYPERTENSION', NULL, NULL, NULL),
    (22003000, 22003121, 1, 10001027, N'COVID_CASE', N'Symptomatic',
     N'Y', NULL, N'PG_COVID-19_v1.1', N'INV576',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'Symptomatic', NULL, NULL, NULL);

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

EXEC dbo.sp_nrt_investigation_postprocessing
    @id_list = N'22003000',
    @debug = 0;

-- =====================================================================
-- COVID case datamart SP — NOT run from this fixture.
--   sp_covid_case_datamart_postprocessing is invoked by Step 9 of
--   merge_and_verify.sh against the global PHC_UIDS list. The
--   orchestrator's PHC_UIDS must be extended to include 22003000 so
--   that Step 9 picks it up. Running it here in addition would
--   produce double rows because the SP does DELETE-then-INSERT per
--   PHC, and Step 9 would re-execute identically.
--
--   (The SP at line 110-111 has a DELETE-first guard:
--      `DELETE FROM dbo.COVID_CASE_DATAMART
--       WHERE public_health_case_uid IN (SELECT public_health_case_uid FROM #PHC_LIST)`
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
