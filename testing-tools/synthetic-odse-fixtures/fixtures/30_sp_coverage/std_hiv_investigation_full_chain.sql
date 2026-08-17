-- =====================================================================
-- Tier 3 — STD (Syphilis primary) Investigation full ODSE chain
-- =====================================================================
-- Goal: unblock the STD/HIV cluster:
--   - F_STD_PAGE_CASE (52 cols, currently 0 rows)
--   - STD_HIV_DATAMART (248 cols, currently 0 rows)
--   - INV_HIV / per-topic D_INV_* dims (currently sentinel-only)
--
-- Authors ONE new full-chain STD Investigation alongside the existing
-- Syphilis-primary stub at 22000080 (left untouched — it exercises the
-- nrt_investigation-only / no-CASE_MANAGEMENT / no-dimensional-keys
-- path; sp_f_std_page_case_postprocessing has an INNER predicate at
-- line 97 `nicm.CASE_MANAGEMENT_UID is not null` that filters that
-- stub out of #PHC_CASE_UIDS_ALL).
--
-- ODSE-ONLY CONVERSION (2026-06-05)
--   PRINCIPLE: fixtures author ONLY NBS_ODSE rows; the RTR pipeline
--   derives everything in RDB_MODERN. This fixture previously wrote 5
--   D_INV_* dimension rows + 5 L_INV_* link rows DIRECTLY into
--   RDB_MODERN — a violation, since per-topic D_INV_<category> /
--   L_INV_<category> are RTR-derived. The page-builder chain
--   (011-sp_page_builder_postprocessing -> 007-sp_s_pagebuilder ->
--   008-sp_l_pagebuilder -> 009-sp_d_pagebuilder, invoked once per
--   D_INV_<category> rdb_table_nm) reads dbo.nrt_page_case_answer,
--   pivots answers whose rdb_table_nm = 'D_INV_<category>' into
--   S_INV_<category>, then derives the L_INV_<category> link + the
--   D_INV_<category> dim dynamically. nrt_page_case_answer is fed by
--   CDC from NBS_ODSE.dbo.nbs_case_answer joined to the page metadata
--   (NBS_rdb_metadata -> nbs_ui_metadata -> nbs_question).
--
--   We therefore now author the UPSTREAM nbs_case_answer rows for the
--   STD/HIV-page questions that map to each of our 5 categories and let
--   011->007/008/009 derive the dims + links. Modeled on
--   tb_investigation_full_chain.sql / varicella_investigation_full_chain.sql
--   (both author only nbs_case_answer rows and let the pagebuilder /
--   PAM chain derive their dims; varicella validated live 2026-06-04).
--
-- STD/HIV-page question -> category mapping (queried live 2026-06-05 from
-- NBS_ODSE.dbo.NBS_rdb_metadata JOIN nbs_ui_metadata JOIN nbs_question,
-- nbs_page_uid=10006000 'PG_STD_Investigation'). Coded answer codes
-- verified to resolve through
-- RDB_MODERN.dbo.v_nrt_ref_formcode_translation for
-- investigation_form_cd='PG_STD_Investigation'.
--
-- WHAT THIS FIXTURE AUTHORS
--   ODSE chain (NBS_ODSE) ONLY:
--        - act               (act_uid=22004000, class='CASE', mood='EVN')
--        - public_health_case (condition_cd 10311, prog_area STD,
--                              investigation_form_cd PG_STD_Investigation;
--                              PHC-core scalar enrichment feeding 026)
--        - act_id            (PHC_LOCAL_ID)
--        - case_management   (IDENTITY-inserted — required by
--                              sp_f_std_page_case_postprocessing's INNER
--                              filter on nicm.CASE_MANAGEMENT_UID)
--        - nbs_case_answer   rows for the STD/HIV-page questions feeding
--                              the 5 categories below. The page-builder
--                              chain derives D_INV_*/L_INV_* from these.
--
-- CATEGORIES COVERED BY THIS FIXTURE (5):
--   D_INV_HIV, D_INV_ADMINISTRATIVE, D_INV_CLINICAL,
--   D_INV_EPIDEMIOLOGY, D_INV_COMPLICATION.
-- The remaining STD-page categories (LAB_FINDING, MEDICAL_HISTORY,
--   PATIENT_OBS, PREGNANCY_BIRTH, RISK_FACTOR, SOCIAL_HISTORY, SYMPTOM,
--   TREATMENT, CONTACT) are covered by the sibling fixture
--   zz_std_hiv_datamart_enrich.sql (same PHC 22004000).
--
-- DOES NOT AUTHOR (derived by the RTR pipeline, NOT fixture writes)
--   - D_INV_*/L_INV_* dims+links — derived by the pagebuilder chain
--     (011/007/008/009) from the nbs_case_answer rows above.
--   - nrt_investigation / nrt_investigation_case_management /
--     nrt_investigation_confirmation — flow via CDC from the ODSE
--     act/public_health_case/case_management rows
--     (sp_investigation_event 056 -> nrt_investigation ->
--      sp_nrt_investigation_postprocessing 005 -> INVESTIGATION).
--   - nrt_page_case_answer — flows via CDC from nbs_case_answer + the
--     page metadata.
--   - STD_HIV_DATAMART — Step-9 SP output (026-sp_std_hiv_datamart),
--     NOT a fixture write.
--   - Tier 2 participation/nbs_act_entity cross-subject keys.
--     PHYSICIAN_KEY / INVESTIGATOR_KEY / HOSPITAL_KEY / etc. resolve
--     via COALESCE->sentinel-1 at sp_f_std_page_case_postprocessing
--     lines 180-211, as for the TB sibling fixture.
--
-- UID block (Tier 3 STD Syphilis full-chain): 22004000-22004999
--   22004000          public_health_case.public_health_case_uid
--                     (act.act_uid; nbs_case_answer.act_uid for every
--                      answer row)
--   22004001          case_management.case_management_uid (IDENTITY-inserted)
--   22004200-22004299 nbs_case_answer.nbs_case_answer_uid for each
--                     authored STD/HIV-page answer row (IDENTITY-inserted).
--                     DISTINCT from the sibling zz_std_hiv_datamart_enrich.sql
--                     block (22012xxx) to avoid collision.
--
-- Foundation dependencies (read-only):
--   @superuser_id              10009282
--   @foundation_patient_uid    20000000   (D_PATIENT must exist; the STD
--                                          F_STD_PAGE_CASE keystore
--                                          LEFT JOINs D_PATIENT, and the
--                                          stage-7 DELETE `PATIENT_KEY=1`
--                                          purge would drop the row if
--                                          patient_id weren't a real Patient.)
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;

-- ----- New STD Syphilis Investigation full-chain UIDs -----
DECLARE @std_full_phc_uid          bigint = 22004000;
DECLARE @std_full_case_mgmt_uid    bigint = 22004001;

-- =====================================================================
-- ODSE: act parent row
-- =====================================================================
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@std_full_phc_uid, N'CASE', N'EVN');

-- =====================================================================
-- ODSE: public_health_case row
-- =====================================================================
-- SRTE-verified codes (NBS_SRTE.dbo.condition_code, 2026-05-21):
--   condition_cd='10311' Syphilis, primary; prog_area_cd='STD';
--     investigation_form_cd='PG_STD_Investigation';
--     coinfection_grp_cd='STD_HIV_GROUP'.
--   program_area_code.prog_area_cd='STD'.
--   code_value_general PHC_CLASS 'C' (Confirmed).
--   code_value_general PHC_IN_STS 'O' (Open).
--   jurisdiction_code '130001' Fulton County (used by Tier 1 v2 inv).
-- PHC-CORE SCALAR ENRICHMENT (Round 5 item C — STD, Part 2):
--   The columns below feed sp_std_hiv_datamart_postprocessing (routine 026)
--   via the INV alias = #tmp_investigation / INVESTIGATION, which the service
--   rebuilds from this public_health_case row through nrt_investigation
--   (CDC -> sp_investigation_event 056 -> nrt_investigation ->
--   sp_nrt_investigation_postprocessing 005 -> INVESTIGATION). 026 reads
--   these INV.* columns (NOT the dim/CM-sourced ones); each value uses a
--   realistic Syphilis-primary scenario + a valid coded value resolved from
--   the SRTE code sets (verified live 2026-06-04). The mapping chain is
--   public_health_case.<col> --(056)--> nrt_investigation.<col> --(005)-->
--   #tmp_investigation/INVESTIGATION.<COL> --(026 INV.<COL>)--> STD_HIV_DATAMART:
--     hospitalized_ind_cd 'N' (056 decodes via INV128->YNU 'No')   -> HSPTLIZD_IND
--     outcome_cd          'N' (056 decodes via INV145->YNU 'No')   -> DIE_FRM_THIS_ILLNESS_IND
--       (patient survives — no deceased_time, so INVESTIGATION_DEATH_DATE stays NULL, correct)
--     disease_imported_cd 'OOS' (056 decodes via INV152 'Out of State') -> DISEASE_IMPORTED_IND
--     imported_country_cd '840' (US) / imported_state_cd '13' (GA) /
--       imported_county_cd '13089' (DeKalb) / imported_city_desc_txt 'Decatur'
--       (these feed IMPORT_FRM_* on INVESTIGATION; not all surface in 026 but valid)
--     pat_age_at_onset 33 / _unit_cd 'Y' (P_AGE_UNIT Years)  -> PATIENT_AGE_AT_ONSET / _UNIT
--     pregnant_ind_cd  'N' (YNU; male patient)               -> PATIENT_PREGNANT_IND
--     diagnosis_time / effective_from_time(onset) / effective_to_time(end) /
--       effective_duration_amt 21 / _unit_cd 'D' (DUR_UNIT Days)  -> diagnosis/illness dates+duration
--     detection_method_cd 'PHC2112' (PHC_DET_MT Laboratory reported) -> DETECTION_METHOD_DESC_TXT
--     rpt_source_cd       'LA'      (PHC_RPT_SRC_T Laboratory)      -> RPT_SRC_CD / RPT_SRC_CD_DESC
--     referral_basis_cd   'P1'      (REFERRAL_BASIS P1 Partner, Sex; 056:311-315 decodes) -> REFERRAL_BASIS
--     txt (general comments)        -> INV_COMMENTS (not an STD_HIV_DATAMART col; harmless/realistic)
--     activity_from_time -> INV_START_DT ; activity_to_time -> INV_CLOSE_DT
--     investigator_assigned_time -> INV_ASSIGNED_DT ; rpt_form_cmplt_time -> INV_RPT_DT
--     rpt_to_county_time / rpt_to_state_time -> EARLIEST_RPT_TO_CNTY/STATE_DT
--     transmission_mode_cd '1' (PHVS_TRANSMISSIONCATEGORY_STD Adult heterosexual contact)
--   GENERATED ALWAYS period cols are omitted. INVESTIGATION_STATUS / INV_CASE_STATUS /
--   OUTBREAK_* / mmwr / jurisdiction already set above/below. NOTES / INV_STATE_CASE_ID
--   are NOT public_health_case scalars and are deliberately left.
INSERT INTO [dbo].[public_health_case]
    ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
     [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
     [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [outbreak_ind], [outbreak_name],
     [mmwr_week], [mmwr_year],
     [hospitalized_ind_cd], [outcome_cd], [disease_imported_cd],
     [imported_country_cd], [imported_state_cd], [imported_county_cd], [imported_city_desc_txt],
     [pat_age_at_onset], [pat_age_at_onset_unit_cd], [pregnant_ind_cd],
     [diagnosis_time], [effective_from_time], [effective_to_time],
     [effective_duration_amt], [effective_duration_unit_cd],
     [detection_method_cd], [rpt_source_cd], [referral_basis_cd], [txt],
     [activity_from_time], [activity_to_time],
     [investigator_assigned_time], [rpt_form_cmplt_time],
     [rpt_to_county_time], [rpt_to_state_time], [transmission_mode_cd])
VALUES
    (@std_full_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'I',
     N'C', N'10311', N'Syphilis, primary', N'NND', N'NND',
     N'O', CAST(GETDATE() AS DATE), @superuser_id, N'CAS22004000GA01',
     N'OPEN', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'T', 1, N'STD', N'130001',
     22004000, N'N', NULL,
     N'14', N'2026',
     N'N', N'N', N'OOS',
     N'840', N'13', N'13089', N'Decatur',
     33, N'Y', N'N',
     '2026-04-05T00:00:00', '2026-03-28T00:00:00', '2026-04-18T00:00:00',
     21, N'D',
     N'PHC2112', N'LA', N'P1', N'Syphilis primary confirmed by darkfield + RPR/TP-PA; partner services initiated.',
     '2026-04-03T00:00:00', '2026-04-30T00:00:00',
     '2026-04-03T00:00:00', '2026-04-20T00:00:00',
     '2026-04-02T00:00:00', '2026-04-03T00:00:00', N'1');

-- =====================================================================
-- ODSE: act_id (PHC_LOCAL_ID)
-- =====================================================================
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@std_full_phc_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE',
     '2026-04-01T00:00:00', N'CAS22004000GA01', N'PHC_LOCAL_ID',
     N'Local Public Health Case Identifier', N'A', '2026-04-01T00:00:00');

-- =====================================================================
-- ODSE: case_management (IDENTITY column requires IDENTITY_INSERT)
-- =====================================================================
SET IDENTITY_INSERT [dbo].[case_management] ON;
INSERT INTO [dbo].[case_management]
    ([case_management_uid], [public_health_case_uid], [status_900],
     [field_record_number], [surv_assigned_date],
     [surv_closed_date], [case_closed_date])
VALUES
    (@std_full_case_mgmt_uid, @std_full_phc_uid, N'C',
     N'FRN-STD-FULL-01', '2026-04-02T00:00:00',
     '2026-04-30T00:00:00', '2026-04-30T00:00:00');
SET IDENTITY_INSERT [dbo].[case_management] OFF;

GO

-- =====================================================================
-- ODSE: nbs_case_answer — one row per STD/HIV-page question we author.
-- These are the UPSTREAM ODSE rows from which CDC builds
-- dbo.nrt_page_case_answer (rdb_table_nm/rdb_column_nm resolved from the
-- page metadata), which the page-builder chain (011 -> 007/008/009)
-- then pivots into S_INV_<category> and derives L_INV_<category> +
-- D_INV_<category>. We author the questions that map to our 5 covered
-- categories; one valid answer per category is sufficient for the chain
-- to derive that dim+link, and we author several per category for a
-- realistic Syphilis-primary scenario.
--
-- (question_identifier | nbs_question_uid | rdb_column_nm | data_type |
--  code_set | answer) — mapping + code validity queried live 2026-06-05
-- (NBS_rdb_metadata / nbs_ui_metadata / nbs_question for page 10006000;
--  codes confirmed in v_nrt_ref_formcode_translation for
--  PG_STD_Investigation).
--
-- nbs_case_answer.nbs_case_answer_uid is an IDENTITY column; we pin our
-- allocated UIDs (22004200+) via IDENTITY_INSERT for stable references
-- and to match the varicella-fixture convention. answer_group_seq_nbr
-- is left NULL (non-repeating answers) so the pagebuilder
-- ANSWER_GROUP_SEQ_NBR IS NULL / QUESTION_GROUP_SEQ_NBR IS NULL
-- predicates admit every row.
-- =====================================================================

DECLARE @superuser_id_2 bigint = 10009282;
DECLARE @std_full_phc_uid_2 bigint = 22004000;

SET IDENTITY_INSERT [dbo].[nbs_case_answer] ON;

INSERT INTO [dbo].[nbs_case_answer]
    ([nbs_case_answer_uid], [act_uid], [add_time], [add_user_id],
     [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [seq_nbr])
VALUES
    -- ===== D_INV_HIV =====
    -- NBS261 HIV_900_TEST_REFERRAL_DT (DATE)
    (22004200, @std_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'2026-03-15', 10001326, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- NBS259 HIV_LAST_900_TEST_DT (DATE)
    (22004201, @std_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'2026-03-15', 10001324, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- NBS264 HIV_POST_TEST_900_COUNSELING (CODED YNU 4150) -> 'N'
    (22004202, @std_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10001330, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),

    -- ===== D_INV_ADMINISTRATIVE =====
    -- INV177 ADM_FIRST_RPT_TO_PHD_DT (DATE)
    (22004210, @std_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'2026-04-03', 10001004, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- INV886 ADM_NOTIF_COMMENT (TEXT)
    (22004211, @std_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Syphilis primary - partner services initiated.', 10001016, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- NBS137 ADM_DISSEMINATED_IND (CODED YNU 4150) -> 'N'
    (22004212, @std_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10001198, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),

    -- ===== D_INV_CLINICAL =====
    -- STD099 CLN_DT_INIT_HLTH_EXM (DATE)
    (22004220, @std_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'2026-04-05', 10001193, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- NBS443 CLN_PRE_EXP_PROPHY_IND (CODED YNU 4150) -> 'Y'
    (22004221, @std_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 10003230, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- STD102 CLN_NEUROSYPHILLIS_IND (CODED 105750) -> 'N' (N/C/P)
    (22004222, @std_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10001197, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),

    -- ===== D_INV_EPIDEMIOLOGY =====
    -- NBS135 SOURCE_SPREAD (CODED 105050) -> 'SP' (Spread)
    (22004230, @std_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'SP', 10001194, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),

    -- ===== D_INV_COMPLICATION =====
    -- INV361 CMP_CONJUNCTIVITIS_IND (CODED YNU 4150) -> 'N'
    (22004240, @std_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10001199, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- INV179 CMP_PID_IND (CODED YNU 4150) -> 'N'
    (22004241, @std_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 10001196, 1, CAST(GETDATE() AS DATE), @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0);

SET IDENTITY_INSERT [dbo].[nbs_case_answer] OFF;

GO

-- =====================================================================
-- RDB_MODERN: NOTHING is authored directly here anymore.
--
-- The investigation + its per-topic dims/links flow entirely via the
-- RTR pipeline from the ODSE rows above:
--   - act / public_health_case / case_management  --(CDC + 056/005)-->
--       nrt_investigation -> INVESTIGATION (+ nrt_investigation_case_management).
--   - nbs_case_answer  --(CDC + page metadata)-->  nrt_page_case_answer
--       --(011 -> 007 sp_s_pagebuilder -> 008 sp_l_pagebuilder ->
--          009 sp_d_pagebuilder, once per D_INV_<category>)-->
--       S_INV_<category> -> L_INV_<category> -> D_INV_<category>.
--
-- The page-builder chain (011) and the F_STD_PAGE_CASE / STD_HIV_DATAMART
-- datamart SPs are owned by Step 9 of merge_and_verify.sh and must be
-- invoked there scoped to PHC 22004000 (see ORCHESTRATOR note in the
-- coverage report). They are NOT tail-EXEC'd here — doing so would
-- double-process on the Step-9 re-run.
-- =====================================================================
