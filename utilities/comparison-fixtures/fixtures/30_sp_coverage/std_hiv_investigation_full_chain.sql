-- =====================================================================
-- Tier 3 — STD (Syphilis primary) Investigation full ODSE + Tier 2
--           + dimensional D_INV_* chain
-- =====================================================================
-- Goal: unblock the STD/HIV cluster:
--   - F_STD_PAGE_CASE (52 cols, currently 0 rows)
--   - STD_HIV_DATAMART (248 cols, currently 0 rows)
--   - INV_HIV         (19 cols, currently 1 sentinel row only)
--
-- Authors ONE new full-chain STD Investigation alongside the existing
-- Syphilis-primary stub at 22000080 (left untouched — it exercises the
-- nrt_investigation-only / no-CASE_MANAGEMENT / no-dimensional-keys
-- path; sp_f_std_page_case_postprocessing has an INNER predicate at
-- line 97 `nicm.CASE_MANAGEMENT_UID is not null` that filters that
-- stub out of #PHC_CASE_UIDS_ALL).
--
-- WHY SYPHILIS PRIMARY (10311, PG_STD_Investigation)
--   PG_STD_Investigation is one of two FORM_CDs in
--   `RDB_MODERN.dbo.v_nrt_nbs_page` that maps to the STD datamart
--   (the other is PG_HIV_Investigation for DATAMART_NM='HIV'). The
--   orchestrator's Step 9 dyn_dm chain (merge_and_verify.sh:543) iterates
--   DISTINCT DATAMART_NMs that have a matching form on nrt_investigation
--   — picking Syphilis primary therefore exercises BOTH the STD HIV
--   datamart SP path AND the dyn_dm STD chain (subject to bug-9 caveat).
--
-- WHAT THIS FIXTURE AUTHORS
--   1. ODSE chain (NBS_ODSE):
--        - act               (act_uid=22004000, class='CASE', mood='EVN')
--        - public_health_case (condition_cd 10311, prog_area STD,
--                              investigation_form_cd PG_STD_Investigation)
--        - act_id            (PHC_LOCAL_ID)
--        - case_management   (IDENTITY-inserted — required by
--                              sp_f_std_page_case_postprocessing's INNER
--                              filter on nicm.CASE_MANAGEMENT_UID)
--   2. RDB_MODERN staging:
--        - nrt_investigation (full canonical Investigation shape — same
--                              ~30-col v2 mirror as Tier 1; PHC_UID
--                              22004000, patient_id=20000000 — inlined
--                              per bug-5b convention).
--        - nrt_investigation_case_management — the staging row
--                              sp_f_std_page_case_postprocessing reads
--                              at line 90 (LEFT JOIN to filter into
--                              #PHC_CASE_UIDS_ALL).
--        - D_INV_HIV         (1 row, KEY=22004100, NBS_CASE_ANSWER_UID
--                              identifier 22004001, populated HIV_* fields).
--        - D_INV_ADMINISTRATIVE (1 row, KEY=22004110, populated ADM_*
--                              fields read by std_hiv_datamart's UPDATE
--                              + INSERT blocks).
--        - D_INV_CLINICAL    (1 row, KEY=22004120, populated CLN_* fields).
--        - D_INV_EPIDEMIOLOGY (1 row, KEY=22004130, populated EPI_* fields).
--        - D_INV_COMPLICATION (1 row, KEY=22004140, populated CMP_* fields).
--        - L_INV_*           (5 link-table rows mapping PAGE_CASE_UID
--                              22004000 → each dimensional KEY; the
--                              25 reads in sp_f_std_page_case_postprocessing
--                              at lines 292-315 COALESCE to sentinel 1 if
--                              the L_INV_* lookup row is absent).
--   3. CONFIRMATION_METHOD_GROUP — 1 row keyed on INVESTIGATION_KEY of
--      22004000, supplies CONFIRMATION_DT to the datamart SP (line 519).
--
-- DOES NOT AUTHOR
--   - nrt_page_case_answer rows. The STD/HIV path does not read them —
--     sp_f_std_page_case_postprocessing reads only nrt_investigation +
--     nrt_investigation_case_management + RDB_MODERN dimensions.
--     dyn_dm STD will pivot answer rows only if seeded; out of scope
--     here (separate Tier 3 LDF/answer fixture).
--   - Tier 2 participation/nbs_act_entity rows for cross-subject keys.
--     PHYSICIAN_KEY / INVESTIGATOR_KEY / HOSPITAL_KEY / etc. will
--     resolve via COALESCE→sentinel-1 at sp_f_std_page_case_postprocessing
--     lines 180-211, exactly as for the TB sibling fixture.
--
-- VERIFICATION CALL-CHAIN (tail-EXECs at bottom)
--   sp_nrt_investigation_postprocessing    — flow nrt_investigation → INVESTIGATION
--     (the row already lands in INVESTIGATION via the existing multi-
--      condition stub run, but we re-EXEC defensively in case this
--      fixture is run standalone before the Syphilis stub run lands).
--   NOTE: sp_std_hiv_datamart_postprocessing (026) and
--   sp_f_std_page_case_postprocessing (025) are owned by Step 9 of
--   merge_and_verify.sh and NOT tail-EXEC'd here — that would produce
--   double-INSERT rows on the second invocation.
--
-- UID block (Tier 3 STD Syphilis full-chain): 22004000-22004999
--   22004000  public_health_case.public_health_case_uid (act.act_uid;
--             nrt_investigation.public_health_case_uid)
--   22004001  case_management.case_management_uid (IDENTITY-inserted)
--   22004100  D_INV_HIV.D_INV_HIV_KEY
--   22004110  D_INV_ADMINISTRATIVE.D_INV_ADMINISTRATIVE_KEY
--   22004120  D_INV_CLINICAL.D_INV_CLINICAL_KEY
--   22004130  D_INV_EPIDEMIOLOGY.D_INV_EPIDEMIOLOGY_KEY
--   22004140  D_INV_COMPLICATION.D_INV_COMPLICATION_KEY
--   (no surrogate UID for CONFIRMATION_METHOD_GROUP — composite PK
--    (INVESTIGATION_KEY, CONFIRMATION_METHOD_KEY); written by
--    sp_nrt_investigation_postprocessing from our authored
--    nrt_investigation_confirmation staging row.)
--
-- Foundation dependencies (read-only):
--   @superuser_id              10009282
--   @foundation_patient_uid    20000000   (D_PATIENT must exist; the STD
--                                          F_STD_PAGE_CASE keystore
--                                          INNER JOINs D_PATIENT only
--                                          via LEFT JOIN, but the
--                                          stage-7 DELETE at line 583
--                                          `PATIENT_KEY=1` purge would
--                                          drop the row if patient_id
--                                          weren't a real Patient.)
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
     N'O', '2026-04-01T00:00:00', @superuser_id, N'CAS22004000GA01',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
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
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE',
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
-- RDB_MODERN: nrt_investigation row + nrt_investigation_case_management
-- staging row + 5 dim rows (D_INV_*) + L_INV_* link rows +
-- CONFIRMATION_METHOD_GROUP.
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- nrt_investigation row — full canonical v2-Investigation shape,
-- STD-specific codes. Mirrors fixtures/10_subjects/investigation.sql v2
-- but for Syphilis primary instead of Hep A acute.
--   patient_id = 20000000 (foundation Patient) — inline literal per
--     bug-5b convention. NOT a DECLARE — cross-batch DECLARE scope
--     would surface NULL here (the Tier 1 fixture inlines for the same
--     reason; see fixtures/10_subjects/investigation.sql line 360).
--   case_management_uid = 22004001 — required so the
--     sp_f_std_page_case_postprocessing INNER filter at line 97
--     (`nicm.CASE_MANAGEMENT_UID is not null`) admits this PHC row
--     into #PHC_CASE_UIDS_ALL.
--   investigation_form_cd = 'PG_STD_Investigation' — required for the
--     same SP's #PHC_UIDS filter at line 152-154 (NOT-IN list of
--     PG_HEP*/INV_FORM_*/etc.).
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_investigation_case_management — the staging row that the
-- F_STD_PAGE_CASE SP LEFT JOINs at line 90 to filter into
-- #PHC_CASE_UIDS_ALL. All NOT-NULL columns are refresh_datetime +
-- max_datetime; everything else is nullable.
-- ---------------------------------------------------------------------
-- refresh_datetime + max_datetime are GENERATED ALWAYS (system-period) cols
-- on nrt_investigation_case_management — exclude from INSERT column list.

-- ---------------------------------------------------------------------
-- D_INV_HIV — one row. The std_hiv_datamart SP reads HIV_* columns
-- from this dimension via PC.D_INV_HIV_KEY join (see 026 lines 64-79).
-- Also populates INV_HIV's UPDATE / INSERT blocks (lines 62-159).
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[D_INV_HIV]
    ([D_INV_HIV_KEY], [nbs_case_answer_uid],
     [HIV_900_TEST_REFERRAL_DT], [HIV_LAST_900_TEST_DT],
     [HIV_900_RESULT], [HIV_900_TEST_IND],
     [HIV_AV_THERAPY_EVER_IND], [HIV_AV_THERAPY_LAST_12MO_IND],
     [HIV_ENROLL_PRTNR_SRVCS_IND], [HIV_KEEP_900_CARE_APPT_IND],
     [HIV_POST_TEST_900_COUNSELING], [HIV_PREVIOUS_900_TEST_IND],
     [HIV_REFER_FOR_900_CARE_IND], [HIV_REFER_FOR_900_TEST],
     [HIV_RST_PROVIDED_900_RSLT_IND], [HIV_SELF_REPORTED_RSLT_900],
     [HIV_STATE_CASE_ID])
VALUES
    (22004100, 22004001,
     '2026-03-15', '2026-03-15',
     N'Negative', N'Yes',
     N'No', N'No',
     N'Yes', N'Yes',
     N'Yes', N'No',
     N'Yes', N'Yes',
     N'Yes', N'Negative',
     N'HIV-STATE-STD-22004000');

-- ---------------------------------------------------------------------
-- D_INV_ADMINISTRATIVE — populates ADI_* / ADM_* fields the SP reads
-- via PC.D_INV_ADMINISTRATIVE_KEY join (see 026 lines 178-181, etc.).
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[D_INV_ADMINISTRATIVE]
    ([D_INV_ADMINISTRATIVE_KEY], [nbs_case_answer_uid],
     [ADM_REFERRAL_BASIS_OOJ], [ADM_RPTNG_CNTY],
     [ADM_DISSEMINATED_IND],
     [ADM_NK1_RELATIONSHIP])
VALUES
    (22004110, 22004001,
     N'PRESUMP', N'13121',
     N'No',
     N'Mother');

-- ---------------------------------------------------------------------
-- D_INV_CLINICAL — populates CLN_* fields the SP reads via
-- PC.D_INV_CLINICAL_KEY join.
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[D_INV_CLINICAL]
    ([D_INV_CLINICAL_KEY], [nbs_case_answer_uid],
     [CLN_CARE_STATUS_CLOSE_DT], [CLN_CONDITION_RESISTANT_TO],
     [CLN_DT_INIT_HLTH_EXM], [CLN_NEUROSYPHILLIS_IND],
     [CLN_PRE_EXP_PROPHY_IND], [CLN_PRE_EXP_PROPHY_REFER],
     [CLN_CASE_DIAGNOSIS])
VALUES
    (22004120, 22004001,
     '2026-04-15', N'None',
     '2026-04-05', N'No',
     N'Yes', N'PHC',
     N'097.1 Syphilis primary');

-- ---------------------------------------------------------------------
-- D_INV_EPIDEMIOLOGY — populates EPI_* fields the SP reads via
-- PC.D_INV_EPIDEMIOLOGY_KEY join (see 026 line 282).
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[D_INV_EPIDEMIOLOGY]
    ([D_INV_EPIDEMIOLOGY_KEY], [nbs_case_answer_uid],
     [EPI_CNTRY_USUAL_RESID])
VALUES
    (22004130, 22004001,
     N'840');  -- USA

-- ---------------------------------------------------------------------
-- D_INV_COMPLICATION — populates CMP_CONJUNCTIVITIS_IND / CMP_PID_IND
-- the SP reads via PC.D_INV_COMPLICATION_KEY (lines 268-269).
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[D_INV_COMPLICATION]
    ([D_INV_COMPLICATION_KEY], [nbs_case_answer_uid],
     [CMP_CONJUNCTIVITIS_IND], [CMP_PID_IND])
VALUES
    (22004140, 22004001,
     N'No', N'No');

-- ---------------------------------------------------------------------
-- L_INV_* link rows — sp_f_std_page_case_postprocessing at lines
-- 292-315 LEFT JOINs 25 L_INV_* tables on PAGE_CASE_UID to gather
-- dimensional KEYs. Each L_* table is a (PAGE_CASE_UID, D_INV_*_KEY)
-- mapping. We populate the 5 corresponding to our authored dim rows;
-- the remaining 20 will COALESCE→sentinel-1 via the SP's COALESCE
-- (no error, just NULL on those columns of F_STD_PAGE_CASE).
--
-- Per the catalog (`odse_unknown_tables.md` row group at line 76),
-- L_INV_* persistent tables are MasterETL output and only read by RTR
-- (never written). For RTR-side fixture coverage, we hand-write our
-- own rows. Verified by `grep -lE "INSERT INTO.*L_INV_ADMINISTRATIVE"`
-- → zero matches in `liquibase-service/.../routines`.
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[L_INV_ADMINISTRATIVE]
    ([PAGE_CASE_UID], [D_INV_ADMINISTRATIVE_KEY])
VALUES (22004000, 22004110);

INSERT INTO [dbo].[L_INV_CLINICAL]
    ([PAGE_CASE_UID], [D_INV_CLINICAL_KEY])
VALUES (22004000, 22004120);

INSERT INTO [dbo].[L_INV_EPIDEMIOLOGY]
    ([PAGE_CASE_UID], [D_INV_EPIDEMIOLOGY_KEY])
VALUES (22004000, 22004130);

INSERT INTO [dbo].[L_INV_COMPLICATION]
    ([PAGE_CASE_UID], [D_INV_COMPLICATION_KEY])
VALUES (22004000, 22004140);

INSERT INTO [dbo].[L_INV_HIV]
    ([PAGE_CASE_UID], [D_INV_HIV_KEY])
VALUES (22004000, 22004100);

-- ---------------------------------------------------------------------
-- nrt_investigation_confirmation — staging row that
-- sp_nrt_investigation_postprocessing (lines 714-732) reads to drive
-- the CONFIRMATION_METHOD_GROUP DELETE + re-INSERT cycle (lines
-- 849-858). Without this row, the post-Tier-3 re-run of the
-- investigation postprocessing SP wipes any hand-authored
-- CONFIRMATION_METHOD_GROUP row AND inserts a (sentinel KEY=1,
-- NULL date) row — which then causes the std_hiv_datamart SP's
-- non-DISTINCT join at line 1179-1180 to produce duplicate rows
-- (see report deliverable RTR Bug #N).
--
-- By authoring the upstream nrt_investigation_confirmation row, the
-- DELETE-then-INSERT round-trip emits exactly ONE CMG row with the
-- correct CONFIRMATION_METHOD_KEY (resolved from
-- confirmation_method_cd='LD') and a non-NULL CONFIRMATION_DT.
-- ---------------------------------------------------------------------

GO

-- =====================================================================
-- Tail-EXEC the SP chain.
--
-- Step A: flow the new nrt_investigation row into INVESTIGATION (and
--   process nrt_investigation_confirmation → CONFIRMATION_METHOD_GROUP).
--   sp_nrt_investigation_postprocessing reads nrt_investigation,
--   writes INVESTIGATION row keyed on case_uid=22004000, then DELETE-
--   then-INSERTs CONFIRMATION_METHOD_GROUP from
--   nrt_investigation_confirmation. The F_STD_PAGE_CASE SP then
--   LEFT JOINs INVESTIGATION at line 226 via
--   fsshc.PAGE_CASE_UID=INVESTIGATION.CASE_UID to resolve
--   INVESTIGATION_KEY. STD_HIV_DATAMART (026) INSERTs and UPDATEs use
--   that same INVESTIGATION_KEY.
-- =====================================================================


-- =====================================================================
-- Step B / C / D — NOT run from this fixture.
--   sp_f_std_page_case_postprocessing (025) and
--   sp_std_hiv_datamart_postprocessing (026) are owned by Step 9 of
--   merge_and_verify.sh against the global PHC_UIDS list (which
--   currently does NOT include 22004000 — see report deliverable for
--   the orchestrator-update task). Running them here in addition would
--   produce double rows on the second invocation because the SPs use
--   INSERT-then-DELETE-on-dup or unguarded INSERT (sp_std_hiv_datamart
--   line 1248: `DELETE FROM dbo.STD_HIV_DATAMART …` — but only the
--   subset matching the @phc_id list passed; subsequent calls with
--   different @phc_id won't see this row).
--
--   For the STANDALONE-fixture verification path the parent agent
--   invokes the SPs manually with @phc_id_list=22004000.
-- =====================================================================
