-- =====================================================================
-- Round 4 (NO-SHORTCUT) — hepatitis_datamart REMAINDER fill (ODSE-only)
--   Agent R4-O. UID block 22054000-22054999.
-- =====================================================================
-- TARGET: of the 209 hepatitis_datamart columns, 133 are populated and
--   76 remain NULL across all rows (live-verified 2026-06-03). R4-G's
--   PHC 22046000 (cond 10100 -> PG_Hepatitis_B_and_C_Acute_Investigation)
--   fed FOUR single page-builder dims (D_INV_LAB_FINDING 36 / RISK_FACTOR
--   30 / MEDICAL_HISTORY 9 / EPIDEMIOLOGY 10 = 85 answers) which routine
--   013 reads via F_PAGE_CASE. It left untouched: (a) THREE more dims the
--   SAME form maps (D_INV_CLINICAL, D_INV_PATIENT_OBS, D_INV_VACCINATION,
--   D_INV_ADMINISTRATIVE) and (b) the ~17 INVESTIGATION-dim columns that
--   routine 013 sources from dbo.INVESTIGATION (alias I) — which are built
--   from public_health_case CORE fields (not page answers).
--
-- ROUTINE-013 EVIDENCE (line refs in
--   liquibase-service/.../routines/013-sp_hepatitis_datamart_postprocessing-001.sql):
--   * step 5  (#TMP_D_INV_CLINICAL,  ~219-221): CLN_HepDInfection ->
--       HEP_D_INFECTION_IND, CLN_MedsforHep -> HEP_MEDS_RECVD_IND.
--   * step 6  (#TMP_D_INV_PATIENT_OBS, ~272):   IPO_SEXUAL_PREF -> SEX_PREF.
--   * step 4  (#TMP_D_INV_ADMINISTRATIVE,~165): ADM_INNC_NOTIFICATION_DT ->
--       INNC_NOTIFICATION_DT, ADM_BINATIONAL_RPTNG_CRIT -> BINATIONAL_RPTNG_CRIT
--       (final INSERT cols 1/12; FIRST_RPT_PHD_DT is computed but NOT in the
--        final INSERT list, so it does not count).
--   * step 13 (#TMP_D_INV_VACCINATION, ~1005-1007): VAC_Vacc_Rcvd ->
--       VACC_RECVD_IND, VAC_VaccineDoses -> VACC_DOSE_RECVD_NBR,
--       VAC_YearofLastDose -> VACC_LAST_RECVD_YR.
--   * #TMP_INVESTIGATION (~1069-1074, SELECT FROM dbo.INVESTIGATION I):
--       ILLNESS_ONSET_DT, DIAGNOSIS_DT, HSPTLIZD_IND, HSPTL_ADMISSION_DT,
--       HSPTL_DISCHARGE_DT, HSPTL_DURATION_DAYS, INV_RPT_DT, INV_START_DT,
--       EARLIEST_RPT_TO_CNTY, EARLIEST_RPT_TO_STATE_DT, DISEASE_IMPORTED_IND,
--       TRANSMISSION_MODE, PAT_PREGNANT_IND, RPT_SRC_CD_DESC, INV_COMMENTS,
--       IMPORT_FROM_CITY/COUNTRY/STATE/COUNTY.
--
-- The INVESTIGATION dim (dbo.INVESTIGATION) is built by
--   sp_nrt_investigation_postprocessing (routine 005) from nrt_investigation,
--   which the service's sp_investigation_event (routine 056, FROM
--   nbs_odse.dbo.public_health_case phc, ~lines 175-330) derives DIRECTLY from
--   the public_health_case CORE columns:
--       phc.effective_from_time      -> ILLNESS_ONSET_DT
--       phc.diagnosis_time           -> DIAGNOSIS_DT
--       phc.hospitalized_ind_cd      -> HSPTLIZD_IND        (codeset INV128/YNU)
--       phc.hospitalized_admin_time  -> HSPTL_ADMISSION_DT
--       phc.hospitalized_discharge_time -> HSPTL_DISCHARGE_DT
--       phc.hospitalized_duration_amt -> HSPTL_DURATION_DAYS
--       phc.rpt_form_cmplt_time      -> INV_RPT_DT
--       phc.activity_from_time       -> INV_START_DT
--       phc.rpt_to_county_time       -> EARLIEST_RPT_TO_CNTY
--       phc.rpt_to_state_time        -> EARLIEST_RPT_TO_STATE_DT
--       phc.disease_imported_cd      -> DISEASE_IMPORTED_IND (codeset INV152)
--       phc.transmission_mode_cd     -> TRANSMISSION_MODE    (codeset INV157)
--       phc.pregnant_ind_cd          -> PAT_PREGNANT_IND     (codeset INV178)
--       phc.rpt_source_cd            -> RPT_SRC_CD_DESC       (codeset INV112)
--       phc.txt                      -> INV_COMMENTS
--       phc.imported_city_desc_txt   -> IMPORT_FROM_CITY
--       phc.imported_country_cd      -> IMPORT_FROM_COUNTRY  (codeset INV153)
--       phc.imported_state_cd        -> IMPORT_FROM_STATE
--       phc.imported_county_cd       -> IMPORT_FROM_COUNTY
--   Coded values were verified to resolve through fn_get_value_by_cd_codeset
--   (codeset -> totalidm.unique_cd -> code_value_general): INV128/INV178=YNU
--   ('Y'), INV112=PHC_RPT_SRC_T ('BB'), INV152=PHVS_DISEASEACQUIREDJURISDICTION_NND
--   ('IND'), INV157=PHC_TRAN_M ('417409004'), INV153=PSL_CNTRY ('100'),
--   imported_state via state_code ('01' -> Alabama), imported_county via
--   state_county_code_value ('01001' -> Autauga County).
--
-- FIX (ODSE-only, additive): a NEW Hepatitis-B-acute investigation
--   (PHC 22054000, condition 10100 -> form PG_Hepatitis_B_and_C_Acute_Investigation,
--   which maps in nrt_datamart_metadata to Hepatitis_Datamart -> routine 013)
--   that (1) sets the public_health_case CORE fields above, and (2) carries
--   the SAME 85 page answers as 22046000 PLUS 13 EXTRA datamart-mapped
--   answers for the CLINICAL/PATIENT_OBS/VACCINATION/ADMINISTRATIVE dims.
--   All page answers use answer_group_seq_nbr = NULL so they route to the
--   SINGLE D_INV_* dims (routine 007, LESSON 9), not D_INVESTIGATION_REPEAT.
--   A SubjOfPHC patient link (subject 20000000) sets nrt_investigation.patient_id
--   so ProcessDatamartData does not silently drop the datamart (LESSON 5).
--   Because coverage counts a column populated if ANY row is non-NULL, this
--   3rd datamart row fills the still-NULL columns.
--
-- EXPECTED FILL (all 8 dim + ~17 INVESTIGATION cols are NULL today):
--   D_INV_CLINICAL     : HEP_D_INFECTION_IND, HEP_MEDS_RECVD_IND            (2)
--   D_INV_PATIENT_OBS  : SEX_PREF                                          (1)
--   D_INV_VACCINATION  : VACC_RECVD_IND, VACC_DOSE_RECVD_NBR, VACC_LAST_RECVD_YR (3)
--   D_INV_ADMINISTRATIVE: INNC_NOTIFICATION_DT, BINATIONAL_RPTNG_CRIT      (2)
--   INVESTIGATION dim  : ILLNESS_ONSET_DT, DIAGNOSIS_DT, HSPTLIZD_IND,
--       HSPTL_ADMISSION_DT, HSPTL_DISCHARGE_DT, HSPTL_DURATION_DAYS,
--       INV_RPT_DT, INV_START_DT, EARLIEST_RPT_TO_CNTY, EARLIEST_RPT_TO_STATE_DT,
--       DISEASE_IMPORTED_IND, TRANSMISSION_MODE, PAT_PREGNANT_IND,
--       RPT_SRC_CD_DESC, INV_COMMENTS, IMPORT_FROM_CITY, IMPORT_FROM_COUNTRY,
--       IMPORT_FROM_STATE, IMPORT_FROM_COUNTY                              (19)
--   => ~27 additional columns expected (133 -> ~160 of 209). Conservative
--      floor ~22 (some coded resolutions / SP normalization may vary).
--
-- DOCUMENTED-NOT-FIXED (out of reach for this form / additive ODSE):
--   * PAT_MIDDLE_NM is sourced from the SHARED D_PATIENT dim (routine 013,
--     ~line 1037: D_PATIENT.PATIENT_MIDDLE_NAME). The foundation patient
--     20000000 has no middle name and the LOOP forbids UPDATE of shared dims
--     -> left NULL (same constraint R4-K hit for TB PATIENT_* cols).
--   * D_INV_MOTHER (MTH_*) and D_INV_TRAVEL (TRAVEL_*/HOUSEHOLD_TRAVEL_*) have
--     NO datamart-mapped questions on PG_Hepatitis_B_and_C_Acute_Investigation
--     (verified live: form maps 0 questions to D_INV_MOTHER/D_INV_TRAVEL) ->
--     unreachable via this form's page-builder route -> left NULL.
--   * Remaining EPI/RISK cols not on this form's mapped set (CHILDCARE_CASE_IND,
--     CT_BABYSITTER_IND, CT_CHILDCARE_IND, CT_PLAYMATE_IND, COM_SRC_OUTBREAK_IND,
--     DNP_*, FOOD*/OBRK_*, HEP_A_EPLINK_IND, FOODHNDLR_PRIOR_IND, BLD_TRANSF_PRIOR_1992,
--     CLOTFACTOR_PRIOR_1987, EVER_INCAR_IND, EVER_INJCT_NOPRSC_DRG, HEP_CONTACT_EVER_IND,
--     LIFE_SEX_PRTNR_NBR, LT_HEMODIALYSIS_IND, MED_DEN_EMP_EVER_IND, ORGN_TRNSP_PRIOR_1992)
--     map to question_uids that are NOT datamart-mapped on this form -> NULL.
--   * DIE_FRM_THIS_ILLNESS_IND: no die_frm_this_illness_ind column exists on
--     public_health_case in this seed (observation-sourced) -> left NULL.
--   * Vaccine repeating cols (VACC_DOSE_NBR_1..4, VACC_RECVD_DT_1..4),
--     IMM_GLOB_RECVD_IND, GLOB_LAST_RECVD_YR, INIT_NND_NOT_DT, INV_RPT_DT
--     subfields, LEGACY_CASE_ID, RPT_SRC_CD_DESC variants: either no mapped
--     question on this form or repeating-block route (out of single-dim scope).
--
-- ORCH_TODO: add 22054000 to PHC_UIDS in scripts/merge_and_verify.sh so the
--   service page-builder (routines 007/036) + routine 013 process it. (Same
--   orchestration 22043000/22046000 required.)
--
-- UID block (reserved 22054000-22054999 in catalog/uid_ranges.md):
--   22054000   act + public_health_case + act_id (new Hep-B-acute PHC).
--   (nbs_case_answer_uid is IDENTITY -> omitted; SubjOfPHC subject is the
--    foundation patient 20000000, no new UID consumed.)
--
-- Foundation deps (read-only): patient 20000000 (D_PATIENT), superuser 10009282.
-- ODSE-only: no nrt_* INSERTs, no EXEC sp_*, no seed/SRTE/liquibase edits.
-- Omit GENERATED ALWAYS period cols. Additive; never UPDATE shared dims.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @ts datetime = '2026-04-01T00:00:00';
DECLARE @superuser_id bigint = 10009282;
DECLARE @phc_uid bigint = 22054000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @phc_uid)
BEGIN
    -- ----- ODSE: act + public_health_case (condition 10100 -> PG_Hepatitis_B_and_C_Acute) -----
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@phc_uid, N'CASE', N'EVN');

    -- public_health_case with CORE fields populated so sp_investigation_event
    -- (routine 056) derives the INVESTIGATION-dim datamart columns.
    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year],
         -- CORE date/numeric fields -> INVESTIGATION dim
         [effective_from_time],[diagnosis_time],
         [hospitalized_admin_time],[hospitalized_discharge_time],[hospitalized_duration_amt],
         [rpt_form_cmplt_time],[activity_from_time],
         [rpt_to_county_time],[rpt_to_state_time],
         [txt],
         -- CORE coded fields -> INVESTIGATION dim (codeset-resolved)
         [hospitalized_ind_cd],[disease_imported_cd],[transmission_mode_cd],
         [pregnant_ind_cd],[rpt_source_cd],
         [imported_city_desc_txt],[imported_country_cd],[imported_state_cd],[imported_county_cd])
    VALUES
        (@phc_uid, @ts, @superuser_id, N'I',
         N'C', N'10100', N'Hepatitis B, acute', N'NND', N'NND',
         N'O', CAST(GETDATE() AS DATE), @superuser_id, N'CAS22054000GA01',
         N'OPEN', @ts, N'A', @ts,
         N'T', 1, N'HEP', N'130001',
         @phc_uid, N'N', NULL,
         N'14', N'2026',
         '2026-03-15T00:00:00', '2026-03-18T00:00:00',
         '2026-03-19T00:00:00', '2026-03-25T00:00:00', 6,
         '2026-03-26T00:00:00', '2026-03-14T00:00:00',
         '2026-03-16T00:00:00', '2026-03-17T00:00:00',
         N'Hepatitis B acute investigation - R4-O coverage fixture.',
         N'Y', N'IND', N'417409004',
         N'Y', N'BB',
         N'Springfield', N'100', N'01', N'01001');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@phc_uid, 1, @ts, @superuser_id,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE',
         @ts, N'CAS22054000GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @ts);

    -- ----- ODSE: SubjOfPHC patient link (sets nrt_investigation.patient_id) -----
    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @phc_uid, N'SubjOfPHC', N'CASE', @ts, @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', @ts, N'A', @ts, N'PSN',
         N'Subject of Public Health Case');

    -- ===== Page-builder answers on PG_Hepatitis_B_and_C_Acute_Investigation =====
    -- answer_group_seq_nbr = NULL routes each to the SINGLE D_INV_* dim (routine 007,
    -- LESSON 9). nbs_case_answer_uid is IDENTITY -> omitted. Comments map each
    -- question -> target D_INV dim column.

    -- ---- D_INV_EPIDEMIOLOGY (10) ----
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001007,1,'840',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_CNTRY_USUAL_RESID
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001065,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_ContactHousehold
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001064,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_ContactOfCase
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001070,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_ContactOther
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001071,1,'RTRfix',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_ContactOthSpecify
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001066,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_ContactSexPartner
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001077,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_FemaleSexPartners
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001078,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_IVDrugUse
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001076,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_MaleSexPartner
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001079,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_EPIDEMIOLOGY.EPI_RecDrugUse

    -- ---- D_INV_LAB_FINDING (36) ----
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001033,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_ALT_Result
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001133,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_AntiHBsPositive
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001132,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_AntiHBsTested
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001036,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_AST_Result
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001052,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HBeAg
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001051,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HBeAg_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001044,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HBsAg
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001043,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HBsAg_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001050,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HBV_NAT
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001049,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HBV_NAT_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001059,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HCVRNA
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001058,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HCVRNA_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001099,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_HepDTest
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001042,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_IgM_AntiHAV
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001041,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_IgMAntiHAVDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001048,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_IgMAntiHBc
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001047,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_IgMAntiHBcDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001097,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_PrevNegHepTest
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001055,1,'RTRfix',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_SignalToCutoff
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001057,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_Supplem_antiHCV
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001056,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_Supplem_antiHCV_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001034,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TestDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001037,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TestDate2
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001035,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TestResultUpperLimit
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001038,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TestResultUpperLimit2
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001040,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHAV
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001039,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHAVDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001046,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHBc
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001045,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHBcDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001054,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHCV
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001053,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHCV_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001061,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHDV
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001060,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHDV_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001063,1,'P',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHEV
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001062,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_TotalAntiHEV_Date
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001098,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_LAB_FINDING.LAB_VerifiedTestDate

    -- ---- D_INV_MEDICAL_HISTORY (9) ----
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001031,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_Diabetes
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001032,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_DiabetesDxDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001006,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_DueDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001028,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_Jaundiced
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001029,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_PrevAwareInfection
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001030,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_ProviderOfCare
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001025,1,'OTH',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_ReasonForTest
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001026,1,'RTRfix',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_ReasonForTestingOth
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001027,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_MEDICAL_HISTORY.MDH_Symptomatic

    -- ---- D_INV_RISK_FACTOR (30) ----
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001108,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_BloodExpOther
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001105,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_BloodTransfusion
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001106,1,'2026-03-20',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_BloodTransfusionDate
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001111,1,'1',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_BloodWorkerCnctFreq
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001110,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_BloodWorkerOnset
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001104,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_ContaminatedStick
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001120,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_DentalOralSx
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001103,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_HEMODIALYSIS_BEFORE_ONSET
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001122,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_HospitalizedPrior
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001124,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_Incarcerated24Hrs
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001128,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_Incarcerated6months
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001126,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_IncarceratedJail
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001125,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_IncarcerationPrison
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001127,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_IncarcJuvenileFacilit
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001130,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_IncarcTimeMonths
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001129,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_IncarcYear6Mos
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001107,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_IVInjectInfuseOutpt
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001123,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_LongTermCareRes
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001109,1,'RTRfix',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_OtherBldExpSpec
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001117,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_Piercing
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001119,1,'RTRfix',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_PiercingOthLocSpec
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001118,1,'1',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_PiercingRcvdFrom
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001113,1,'1',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_PSWrkrBldCnctFreq
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001112,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_PublicSafetyWorker
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001101,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_STDTxEver
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001102,1,'2',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_STDTxYr
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001121,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_SurgeryOther
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001114,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_Tattoo
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001115,1,'1',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_TattooLocation
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001116,1,'RTRfix',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_RISK_FACTOR.RSK_TattooLocOthSpec

    -- ============ EXTRA dims R4-G did not feed (the 76-col remainder) ============
    -- ---- D_INV_CLINICAL (2) -> HEP_D_INFECTION_IND / HEP_MEDS_RECVD_IND ----
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001100,1,'N',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_CLINICAL.CLN_HepDInfection -> HEP_D_INFECTION_IND (csg 4150)
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001131,1,'N',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_CLINICAL.CLN_MedsforHep -> HEP_MEDS_RECVD_IND (csg 4150)

    -- ---- D_INV_PATIENT_OBS (1) -> SEX_PREF ----
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001075,1,'1',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_PATIENT_OBS.IPO_SEXUAL_PREF -> SEX_PREF (csg 104210)

    -- ---- D_INV_VACCINATION (3) -> VACC_RECVD_IND / VACC_DOSE_RECVD_NBR / VACC_LAST_RECVD_YR ----
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001092,1,'Y',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_VACCINATION.VAC_Vacc_Rcvd -> VACC_RECVD_IND (csg 4150)
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001093,1,'3',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_VACCINATION.VAC_VaccineDoses -> VACC_DOSE_RECVD_NBR (numeric)
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001094,1,'2025',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_VACCINATION.VAC_YearofLastDose -> VACC_LAST_RECVD_YR (numeric)

    -- ---- D_INV_ADMINISTRATIVE (2 datamart cols) -> INNC_NOTIFICATION_DT / BINATIONAL_RPTNG_CRIT ----
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001015,1,'2026-03-22',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_ADMINISTRATIVE.ADM_INNC_NOTIFICATION_DT -> INNC_NOTIFICATION_DT (date)
    INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES (22054000,10001012,1,'PHC1137',1,NULL,GETDATE(),10009282,GETDATE(),10009282,'ACTIVE',GETDATE()); -- D_INV_ADMINISTRATIVE.ADM_BINATIONAL_RPTNG_CRIT -> BINATIONAL_RPTNG_CRIT (csg 102980)
    -- (ADM_FIRST_RPT_TO_PHD_DT 10001004 omitted: FIRST_RPT_PHD_DT is computed in
    --  routine 013 step 4 but is NOT in the final hepatitis_datamart INSERT list.)
END;
GO

-- Bump last_chg_time so CDC re-emits the investigation and the service
-- re-runs sp_investigation_event, deriving rdb_table_name_list from the page
-- answers and the INVESTIGATION-dim columns from the PHC core fields, then
-- driving the page-builder + hepatitis_datamart SPs.
UPDATE [NBS_ODSE].[dbo].[public_health_case]
   SET [last_chg_time] = SYSDATETIME()
 WHERE public_health_case_uid = 22054000;
GO
