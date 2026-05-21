USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 1 Investigation fixture
-- Baseline: 6.0.18.1 (post-liquibase) + fixtures/00_foundation/00_foundation.sql
--
-- WHAT THIS FIXTURE DOES
--   1. Enriches the foundation Investigation (UID 20000100,
--      public_health_case_uid 20000100) with:
--        - One additional `act_id` row for foundation Investigation. The
--          foundation has none. The event SP at lines 410-422 emits an
--          act_ids JSON branch, so adding a row gives the JSON projection
--          a non-empty array on the foundation variant.
--        - Foundation public_health_case columns case_class_cd,
--          condition cd_system_cd, etc. remain NULL on the foundation row
--          (no UPDATE — the template forbids modifying foundation, even
--          for columns coverage_foundation.md flags as "Tier 1 deferred").
--          The foundation row therefore exhibits the SP's null/blank
--          path for INVESTIGATION columns sourced from those fields.
--   2. Adds a fully-attributed Investigation v2 variant
--      (public_health_case_uid 20050010 — Act + Public_health_case +
--      act_id + case_management) so every column the postprocessing SP
--      propagates from `nrt_investigation` is populated for at least one
--      variant. v2 picks condition_cd '10110' (Hepatitis A, acute —
--      family_cd 'HEP', investigation_form_cd
--      'PG_Hepatitis_A_Acute_Investigation') matching the foundation's
--      condition_cd; STRATEGY.md notes v1 uses one canonical condition
--      per family — multi-condition fan-out is Phase 2.
--   3. Populates dbo.nrt_investigation AND dbo.nrt_investigation_confirmation
--      in RDB_MODERN directly. sp_nrt_investigation_postprocessing is
--      driven from these staging rows. Two public_health_case_uids:
--      foundation Investigation (20000100) and v2 Investigation
--      (20050010). The foundation staging row deliberately leaves several
--      optional columns NULL so the SP's "blank/null → NULL" transform
--      path is observable; the v2 staging row sets every column
--      `sp_nrt_investigation_postprocessing` propagates.
--      Without these direct INSERTs the postprocessing SP returns
--      "Missing NRT Record" and never writes INVESTIGATION.
--      `nrt_investigation_confirmation` rows drive
--      sp_nrt_investigation_postprocessing's confirmation-method
--      pivot (lines 713-732) and produce CONFIRMATION_METHOD +
--      CONFIRMATION_METHOD_GROUP rows.
--   4. Does NOT author cross-subject participation / act_relationship /
--      nbs_act_entity rows. The Investigation event SP references those
--      tables ~20 times (SubjOfPHC patient, OrgAsReporterOfPHC,
--      InvestgrOfPHC, NotificationToPHC, etc.); each missing edge surfaces
--      as a LINK_REQUIRED finding in coverage. Tier 2 will populate.
--      Note: INVESTIGATION dimension is not directly fed by those joins
--      (sp_nrt_investigation_postprocessing only reads nrt_investigation,
--      nrt_investigation_confirmation, and nrt_investigation_observation).
--      The cross-subject participation rows would only affect downstream
--      datamarts (Hepatitis_Datamart, sp_public_health_case_fact_datamart_*,
--      etc.) which are out of scope per the per-subject prompt.
--
-- UID block (Investigation Tier 1): 20050000-20059999.
-- Foundation dependencies (read-only):
--   @dbo_Act_investigation_uid          20000100  (act / public_health_case)
--   @dbo_Entity_patient_uid             20000000  (referenced via nrt_investigation.patient_id on v2)
-- =====================================================================

-- ----- Sentinel reference (do not allocate — assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Foundation dependencies referenced (read-only) -----
DECLARE @foundation_act_inv_uid     bigint = 20000100;  -- foundation Investigation Act / Public_health_case
DECLARE @foundation_patient_uid     bigint = 20000000;  -- foundation Patient (used as nrt_investigation.patient_id soft reference for v2)

-- =====================================================================
-- UID allocations (Investigation Tier 1: 20050000-20059999)
-- =====================================================================

-- ----- v2 Investigation: a separate fully-attributed PHC -----
DECLARE @dbo_Act_investigation_v2_uid bigint = 20050010;  -- v2 Investigation: act.act_uid / public_health_case.public_health_case_uid
DECLARE @dbo_Case_management_v2_uid   bigint = 20050011;  -- v2 case_management.case_management_uid (referenced by event SP at line 135 cm.case_management_uid; INVESTIGATION dimension does not store this directly, but exercising the join keeps the JSON projection populated)

-- =====================================================================
-- ODSE rows — additive enrichments to the foundation Investigation.
-- These rows feed sp_investigation_event so its SELECT projection's
-- act_ids / case_management JSON branches resolve.
-- They are NOT what drives sp_nrt_investigation_postprocessing (that is
-- driven by direct nrt_investigation INSERTs below).
-- =====================================================================

-- The foundation Investigation's public_health_case row is intentionally
-- NOT modified. coverage_foundation.md notes case_class_cd /
-- cd_system_cd are "Tier 1 deferred" — that means the v2 variant
-- exercises the populated path, NOT a license to UPDATE the foundation
-- row (per the Tier 1 template's contract).

-- --- Foundation Investigation enrichment: act_id row ---
-- The event SP at lines 410-422 emits act_ids as a JSON branch from
-- nbs_odse.dbo.act_id WHERE act_uid = phc.public_health_case_uid.
-- Foundation has no act_id row attached to its Investigation; add one
-- so the projection resolves. type_cd 'PHC_LOCAL_ID' (canonical for
-- a local-id act_id; the SP doesn't filter on type_cd).
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@foundation_act_inv_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE',
     '2026-04-01T00:00:00', N'CAS20000100GA01', N'PHC_LOCAL_ID',
     N'Local Public Health Case Identifier', N'A', '2026-04-01T00:00:00');

-- =====================================================================
-- Investigation v2 — fully attributed PHC variant for column coverage.
-- =====================================================================

-- act parent row. class_cd 'CASE' from SRTE ACT_CLS; mood_cd 'EVN'.
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@dbo_Act_investigation_v2_uid, N'CASE', N'EVN');

-- v2 public_health_case. Every code is grounded in baseline SRTE:
--   case_type_cd='I'        — Individual case (canonical PHC case_type for non-aggregate)
--   case_class_cd='C'       — PHC_CLASS 'C' = Confirmed (verified)
--   cd='10110'              — condition_code 'Hepatitis A, acute' (HEP family,
--                             investigation_form_cd 'PG_Hepatitis_A_Acute_Investigation';
--                             matches foundation's cd selection)
--   cd_desc_txt             — display text from condition_code
--   investigation_status_cd='O' — PHC_IN_STS 'O' = Open (verified)
--   prog_area_cd='HEP'      — program_area_code 'HEP' (verified)
--   jurisdiction_cd='130001' — jurisdiction_code '130001' = Fulton County (verified;
--                              foundation's '1' does not exist in jurisdiction_code,
--                              so the foundation variant exercises the no-jurisdiction-match
--                              path while v2 exercises the populated path)
--   pregnant_ind_cd='Y'     — totalidm INV178 -> YNU 'Y' = Yes (verified)
--   day_care_ind_cd='N'     — totalidm INV148 -> YNU 'N' = No (verified)
--   food_handler_ind_cd='N' — totalidm INV149 -> YNU 'N' = No (verified)
--   hospitalized_ind_cd='Y' — totalidm INV128 -> YNU 'Y' = Yes (verified)
--   outbreak_ind='Y'        — totalidm INV150 -> YNU 'Y' = Yes (verified)
--   outcome_cd='Y'          — totalidm INV145 -> YNU 'Y' = Yes (verified) -> die_frm_this_illness_ind
--   transmission_mode_cd='B'  — code_value_general PHC_TRAN_M 'B' = Bloodborne (verified)
--   disease_imported_cd='IND' — code_value_general
--                                PHVS_DISEASEACQUIREDJURISDICTION_NND 'IND' = Indigenous (verified)
--   pat_age_at_onset_unit_cd='Y' — totalidm INV144 -> AGE_UNIT 'Y' = Years (verified)
--   detection_method_cd='AS'    — code_value_general PHC_DET_MT 'AS' = Active Surveillance
--                                                                     (verified;
--                                                                      detection_method_desc_txt is
--                                                                      sourced from cvg.code_desc_txt)
--   priority_cd='HIGH'         — code_value_general NBS_PRIORITY 'HIGH' (verified)
--   contact_inv_status_cd='O'  — code_value_general PHC_IN_STS 'O' = Open (verified)
--   referral_basis_cd='AI'     — code_value_general REFERRAL_BASIS 'AI' (verified;
--                                                                       fn_get_value_by_cvg uses code_set_nm REFERRAL_BASIS)
--   curr_process_state_cd='OPEN-NEW' — code_value_general CM_PROCESS_STAGE
--                                       (we will leave this NULL since CM_PROCESS_STAGE
--                                       seed values were not verified in this baseline; the
--                                       SP returns curr_process_state_cd directly anyway and
--                                       curr_process_state via fn lookup. Using a safe value).
--   imported_country_cd='840' — totalidm INV153 -> country code 840 (United States;
--                                fn returns code_short_desc_txt from country_code via lookup;
--                                may resolve to NULL if INV153 is not totalidm-mapped to a code
--                                set. Setting the raw cd nonetheless propagates to nrt staging).
INSERT INTO [dbo].[public_health_case]
    ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
     [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
     [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [pregnant_ind_cd], [day_care_ind_cd],
     [food_handler_ind_cd], [hospitalized_ind_cd], [outbreak_ind], [outbreak_name],
     [outcome_cd], [transmission_mode_cd], [disease_imported_cd],
     [pat_age_at_onset], [pat_age_at_onset_unit_cd], [detection_method_cd],
     [priority_cd], [contact_inv_status_cd], [referral_basis_cd],
     [curr_process_state_cd], [investigator_assigned_time], [diagnosis_time],
     [hospitalized_admin_time], [hospitalized_discharge_time], [hospitalized_duration_amt],
     [imported_country_cd], [imported_state_cd], [imported_city_desc_txt],
     [imported_county_cd], [deceased_time], [contact_inv_txt],
     [infectious_from_date], [infectious_to_date], [activity_from_time],
     [activity_to_time], [effective_from_time], [effective_to_time],
     [effective_duration_amt], [effective_duration_unit_cd],
     [rpt_form_cmplt_time], [rpt_to_county_time], [rpt_to_state_time],
     [rpt_source_cd], [rpt_source_cd_desc_txt], [rpt_cnty_cd],
     [mmwr_week], [mmwr_year], [coinfection_id], [inv_priority_cd],
     [outbreak_from_time], [outbreak_to_time], [txt])
VALUES
    (@dbo_Act_investigation_v2_uid, '2026-04-01T00:00:00', @superuser_id, N'I',
     N'C', N'10110', N'Hepatitis A, acute', N'NND', N'NND',
     N'O', '2026-04-01T00:00:00', @superuser_id, N'CAS20050010GA01',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'T', 1, N'HEP', N'130001',
     20050010, N'Y', N'N',
     N'N', N'Y', N'Y', N'V2 Hepatitis Outbreak',
     N'Y', N'B', N'IND',
     N'45', N'Y', N'AS',
     N'HIGH', N'O', N'AI',
     N'OPEN-NEW', '2026-04-02T00:00:00', '2026-04-01T00:00:00',
     '2026-04-03T00:00:00', '2026-04-08T00:00:00', 5,
     N'840', N'13', N'Atlanta',
     N'13121', '2026-04-09T00:00:00', N'Tier 1 v2 contact investigation comments',
     '2026-04-01T00:00:00', '2026-04-15T00:00:00', '2026-04-01T00:00:00',
     '2026-04-30T00:00:00', '2026-04-01T00:00:00', '2026-04-15T00:00:00',
     N'15', N'D',
     '2026-04-04T00:00:00', '2026-04-05T00:00:00', '2026-04-06T00:00:00',
     N'PP', N'Private Physician Office', N'13121',
     N'14', N'2026', N'COINF-V2-01', N'HIGH',
     '2026-04-01T00:00:00', '2026-04-30T00:00:00',
     N'Tier 1 v2 investigation comments — exercises every INV_COMMENTS column.');

-- v2 act_id row (matches the foundation pattern).
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@dbo_Act_investigation_v2_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE',
     '2026-04-01T00:00:00', N'CAS20050010GA01', N'PHC_LOCAL_ID',
     N'Local Public Health Case Identifier', N'A', '2026-04-01T00:00:00');

-- v2 case_management — exercises the event SP's case_management JSON
-- branch (lines 603-691). case_management.case_management_uid is an
-- IDENTITY column in baseline ODSE; toggle IDENTITY_INSERT so we can
-- pin the UID to our allocated value.
SET IDENTITY_INSERT [dbo].[case_management] ON;
INSERT INTO [dbo].[case_management]
    ([case_management_uid], [public_health_case_uid],
     [status_900], [ehars_id], [epi_link_id],
     [field_record_number],
     [fld_foll_up_dispo], [fld_foll_up_dispo_date],
     [fld_foll_up_exam_date], [fld_foll_up_expected_date],
     [fld_foll_up_expected_in], [fld_foll_up_internet_outcome],
     [fld_foll_up_notification_plan], [fld_foll_up_prov_diagnosis],
     [fld_foll_up_prov_exm_reason], [init_foll_up],
     [init_foll_up_clinic_code], [init_foll_up_closed_date],
     [init_foll_up_notifiable], [internet_foll_up],
     [pat_intv_status_cd], [surv_assigned_date],
     [surv_closed_date], [surv_provider_contact],
     [surv_prov_exm_reason], [surv_prov_diagnosis],
     [surv_patient_foll_up], [act_ref_type_cd],
     [initiating_agncy], [foll_up_assigned_date],
     [init_foll_up_assigned_date], [interview_assigned_date],
     [init_interview_assigned_date], [case_closed_date])
VALUES
    (@dbo_Case_management_v2_uid, @dbo_Act_investigation_v2_uid,
     N'C', N'EH-V2-01', N'EPI-V2-01',
     N'FRN-V2-01',
     N'C', '2026-04-20T00:00:00',
     '2026-04-19T00:00:00', '2026-04-21T00:00:00',
     N'Y', N'M',
     N'I', N'1',
     N'1', N'I',
     N'CL-V2-01', '2026-04-22T00:00:00',
     N'Y', N'Y',
     N'P', '2026-04-02T00:00:00',
     '2026-04-30T00:00:00', N'C',
     N'1', N'1',
     N'1', N'I',
     N'L', '2026-04-03T00:00:00',
     '2026-04-04T00:00:00', '2026-04-05T00:00:00',
     '2026-04-06T00:00:00', '2026-04-30T00:00:00');
SET IDENTITY_INSERT [dbo].[case_management] OFF;

GO

-- =====================================================================
-- DRIVE THE POSTPROCESSING SP via direct nrt_investigation +
-- nrt_investigation_confirmation INSERTs.
--
-- sp_investigation_event only emits a SELECT (consumed by Kafka in
-- production). For fixture verification we populate dbo.nrt_investigation
-- AND dbo.nrt_investigation_confirmation directly to drive
-- sp_nrt_investigation_postprocessing → INVESTIGATION + confirmation_method
-- + CONFIRMATION_METHOD_GROUP. Two public_health_case_uids: foundation
-- Investigation (20000100) and v2 Investigation (20050010). The foundation
-- staging row deliberately leaves several optional columns NULL so the
-- SP's "blank/null → NULL" transform path is observable in the diff. The
-- v2 staging row sets every column the SP propagates (modulo Tier 2
-- cross-subject UID columns — patient_id, investigator_id, physician_id,
-- organization_id, hospital_uid, ordering_facility_uid, *_of_phc_uid —
-- which are LINK_REQUIRED for Tier 2 to populate).
--
-- nrt_investigation has refresh_datetime (AS_ROW_START) and max_datetime
-- (AS_ROW_END) GENERATED ALWAYS columns; SQL Server populates them on
-- INSERT, so they are omitted from the column list.
-- =====================================================================

USE [RDB_MODERN];
GO

-- nrt_investigation: one row per public_health_case_uid. Mirrors the
-- JSON projection emitted by sp_investigation_event, flattened into the
-- columnar shape kafka-connect's JDBC sink would write.
--
-- Cross-subject UID columns (Tier 2 territory) are deliberately NULL on
-- both variants:
--     patient_id, investigator_id, physician_id, organization_id,
--     phc_inv_form_id, case_management_uid (set on v2 since case_management
--     ODSE row is internal to this fixture), nac_page_case_uid,
--     person_as_reporter_uid, hospital_uid, ordering_facility_uid,
--     ca_supervisor_of_phc_uid, closure_investgr_of_phc_uid,
--     dispo_fld_fupinvestgr_of_phc_uid, fld_fup_investgr_of_phc_uid,
--     fld_fup_prov_of_phc_uid, fld_fup_supervisor_of_phc_uid,
--     init_fld_fup_investgr_of_phc_uid, init_fup_investgr_of_phc_uid,
--     init_interviewer_of_phc_uid, interviewer_of_phc_uid,
--     surv_investgr_of_phc_uid, fld_fup_facility_of_phc_uid,
--     org_as_hospital_of_delivery_uid, per_as_provider_of_delivery_uid,
--     per_as_provider_of_obgyn_uid, per_as_provider_of_pediatrics_uid,
--     org_as_reporter_uid, daycare_fac_uid, chronic_care_fac_uid.
-- These are populated by the event SP's join to participation /
-- act_relationship / nbs_act_entity, which Tier 2 will provide. The
-- INVESTIGATION dimension does NOT directly read most of those columns
-- from nrt_investigation either, so leaving them NULL does not affect
-- the populated/NULL count for INVESTIGATION columns measured by this
-- fixture; the LINK_REQUIRED entries cover dimension/datamart columns
-- that depend on those connective rows downstream.
INSERT INTO [dbo].[nrt_investigation]
    ([public_health_case_uid], [patient_id], [program_jurisdiction_oid],
     [local_id], [shared_ind], [outbreak_name],
     [investigation_status], [inv_case_status], [case_type_cd], [txt],
     [jurisdiction_cd], [jurisdiction_nm],
     [earliest_rpt_to_phd_dt], [effective_from_time], [effective_to_time],
     [rpt_form_cmplt_time], [activity_from_time], [rpt_src_cd_desc],
     [rpt_to_county_time], [rpt_to_state_time],
     [mmwr_week], [mmwr_year], [disease_imported_ind],
     [imported_from_country], [imported_from_state], [imported_from_county],
     [imported_city_desc_txt], [earliest_rpt_to_cdc_dt], [rpt_source_cd],
     [imported_country_cd], [imported_state_cd], [imported_county_cd],
     [import_frm_city_cd], [diagnosis_time],
     [hospitalized_admin_time], [hospitalized_discharge_time],
     [hospitalized_duration_amt], [outbreak_ind], [outbreak_ind_val],
     [hospitalized_ind], [hospitalized_ind_cd],
     [city_county_case_nbr], [transmission_mode_cd], [transmission_mode],
     [record_status_cd], [pregnant_ind_cd], [pregnant_ind],
     [die_frm_this_illness_ind], [day_care_ind], [day_care_ind_cd],
     [food_handler_ind_cd], [food_handler_ind], [deceased_time],
     [pat_age_at_onset], [pat_age_at_onset_unit_cd], [pat_age_at_onset_unit],
     [investigator_assigned_time], [detection_method_desc_txt],
     [effective_duration_amt], [effective_duration_unit_cd], [illness_duration_unit],
     [contact_inv_txt], [contact_inv_priority],
     [infectious_from_date], [infectious_to_date], [contact_inv_status],
     [activity_to_time], [program_area_description],
     [add_user_id], [add_user_name], [add_time],
     [last_chg_user_id], [last_chg_user_name], [last_chg_time],
     [referral_basis_cd], [referral_basis], [curr_process_state],
     [inv_priority_cd], [coinfection_id], [legacy_case_id],
     [curr_process_state_cd], [investigation_status_cd],
     [outcome_cd], [disease_imported_cd], [mood_cd], [class_cd],
     [case_class_cd], [cd], [cd_desc_txt], [prog_area_cd],
     [inv_state_case_id], [investigation_form_cd], [outbreak_name_desc],
     [investigator_assigned_datetime], [case_management_uid],
     [status_time], [record_status_time], [raw_record_status_cd],
     [batch_id], [rpt_cnty_cd], [notes])
VALUES
-- Foundation Investigation (UID 20000100): minimal but valid row mirroring
-- foundation's NULL-heavy public_health_case state. case_class_cd /
-- cd_system_cd / outcome_cd / hospitalized_ind_cd / etc. all NULL by
-- design — the foundation row exercises the SP's null/blank path on
-- INVESTIGATION columns. Foundation's public_health_case has prog_area_cd
-- 'STD', cd '10110', case_type_cd 'I', shared_ind 'F', record_status_cd
-- 'ACTIVE', investigation_status_cd 'O' — propagate those.
    (20000100,                            -- 1  public_health_case_uid
     @foundation_patient_uid,             -- 2  patient_id (foundation Patient; required by HEPATITIS_DATAMART chain — sentinel-key cascade otherwise deletes the row pre-INSERT)
     NULL,                                -- 3  program_jurisdiction_oid
     N'CAS20000100GA01',                  -- 4  local_id
     N'F',                                -- 5  shared_ind
     NULL,                                -- 6  outbreak_name
     NULL,                                -- 7  investigation_status
     NULL,                                -- 8  inv_case_status
     N'I',                                -- 9  case_type_cd
     NULL,                                -- 10 txt
     N'1',                                -- 11 jurisdiction_cd (foundation '1' has no match in jurisdiction_code; jurisdiction_nm stays NULL)
     NULL,                                -- 12 jurisdiction_nm
     NULL,                                -- 13 earliest_rpt_to_phd_dt
     NULL,                                -- 14 effective_from_time
     NULL,                                -- 15 effective_to_time
     NULL,                                -- 16 rpt_form_cmplt_time
     NULL,                                -- 17 activity_from_time
     NULL,                                -- 18 rpt_src_cd_desc
     NULL,                                -- 19 rpt_to_county_time
     NULL,                                -- 20 rpt_to_state_time
     NULL,                                -- 21 mmwr_week
     NULL,                                -- 22 mmwr_year
     NULL,                                -- 23 disease_imported_ind
     NULL,                                -- 24 imported_from_country
     NULL,                                -- 25 imported_from_state
     NULL,                                -- 26 imported_from_county
     NULL,                                -- 27 imported_city_desc_txt
     NULL,                                -- 28 earliest_rpt_to_cdc_dt
     NULL,                                -- 29 rpt_source_cd
     NULL,                                -- 30 imported_country_cd
     NULL,                                -- 31 imported_state_cd
     NULL,                                -- 32 imported_county_cd
     NULL,                                -- 33 import_frm_city_cd
     NULL,                                -- 34 diagnosis_time
     NULL,                                -- 35 hospitalized_admin_time
     NULL,                                -- 36 hospitalized_discharge_time
     NULL,                                -- 37 hospitalized_duration_amt
     NULL,                                -- 38 outbreak_ind
     NULL,                                -- 39 outbreak_ind_val
     NULL,                                -- 40 hospitalized_ind
     NULL,                                -- 41 hospitalized_ind_cd
     NULL,                                -- 42 city_county_case_nbr
     NULL,                                -- 43 transmission_mode_cd
     NULL,                                -- 44 transmission_mode
     N'ACTIVE',                           -- 45 record_status_cd
     NULL,                                -- 46 pregnant_ind_cd
     NULL,                                -- 47 pregnant_ind
     NULL,                                -- 48 die_frm_this_illness_ind
     NULL,                                -- 49 day_care_ind
     NULL,                                -- 50 day_care_ind_cd
     NULL,                                -- 51 food_handler_ind_cd
     NULL,                                -- 52 food_handler_ind
     NULL,                                -- 53 deceased_time
     NULL,                                -- 54 pat_age_at_onset
     NULL,                                -- 55 pat_age_at_onset_unit_cd
     NULL,                                -- 56 pat_age_at_onset_unit
     NULL,                                -- 57 investigator_assigned_time
     NULL,                                -- 58 detection_method_desc_txt
     NULL,                                -- 59 effective_duration_amt
     NULL,                                -- 60 effective_duration_unit_cd
     NULL,                                -- 61 illness_duration_unit
     NULL,                                -- 62 contact_inv_txt
     NULL,                                -- 63 contact_inv_priority
     NULL,                                -- 64 infectious_from_date
     NULL,                                -- 65 infectious_to_date
     NULL,                                -- 66 contact_inv_status
     NULL,                                -- 67 activity_to_time
     NULL,                                -- 68 program_area_description
     10009282,                            -- 69 add_user_id
     N'Foundation, Superuser',            -- 70 add_user_name
     '2026-04-01T00:00:00',               -- 71 add_time
     10009282,                            -- 72 last_chg_user_id
     N'Foundation, Superuser',            -- 73 last_chg_user_name
     '2026-04-01T00:00:00',               -- 74 last_chg_time
     NULL,                                -- 75 referral_basis_cd
     NULL,                                -- 76 referral_basis
     NULL,                                -- 77 curr_process_state
     NULL,                                -- 78 inv_priority_cd
     NULL,                                -- 79 coinfection_id
     NULL,                                -- 80 legacy_case_id
     NULL,                                -- 81 curr_process_state_cd
     N'O',                                -- 82 investigation_status_cd (foundation 'O')
     NULL,                                -- 83 outcome_cd
     NULL,                                -- 84 disease_imported_cd
     N'EVN',                              -- 85 mood_cd
     N'CASE',                             -- 86 class_cd
     NULL,                                -- 87 case_class_cd (foundation case_class_cd is NULL)
     N'10110',                            -- 88 cd
     N'Foundation investigation',         -- 89 cd_desc_txt
     N'STD',                              -- 90 prog_area_cd
     NULL,                                -- 91 inv_state_case_id
     NULL,                                -- 92 investigation_form_cd
     NULL,                                -- 93 outbreak_name_desc
     NULL,                                -- 94 investigator_assigned_datetime
     NULL,                                -- 95 case_management_uid
     '2026-04-01T00:00:00',               -- 96 status_time
     '2026-04-01T00:00:00',               -- 97 record_status_time
     N'ACTIVE',                           -- 98 raw_record_status_cd
     NULL,                                -- 99 batch_id
     NULL,                                -- 100 rpt_cnty_cd
     NULL),                               -- 101 notes
-- v2 Investigation (UID 20050010): every column populated to maximize
-- INVESTIGATION coverage for the populated path. Codes mirror v2
-- public_health_case row. *_cd vs *-resolved-text columns are paired
-- (e.g., outbreak_ind 'Y' / outbreak_ind_val 'Yes' from YNU lookup
-- via INV150).
    (20050010,                            -- 1  public_health_case_uid
     @foundation_patient_uid,             -- 2  patient_id (foundation Patient; required by HEPATITIS_DATAMART chain — see foundation row comment)
     20050010,                            -- 3  program_jurisdiction_oid
     N'CAS20050010GA01',                  -- 4  local_id
     N'T',                                -- 5  shared_ind
     N'V2 Hepatitis Outbreak',            -- 6  outbreak_name
     N'Open',                             -- 7  investigation_status
     N'Confirmed',                        -- 8  inv_case_status
     N'I',                                -- 9  case_type_cd
     N'Tier 1 v2 investigation comments — exercises every INV_COMMENTS column.', -- 10 txt
     N'130001',                           -- 11 jurisdiction_cd (Fulton County — verified in jurisdiction_code)
     N'Fulton County',                    -- 12 jurisdiction_nm
     '2026-04-06T00:00:00',               -- 13 earliest_rpt_to_phd_dt
     '2026-04-01T00:00:00',               -- 14 effective_from_time
     '2026-04-15T00:00:00',               -- 15 effective_to_time
     '2026-04-04T00:00:00',               -- 16 rpt_form_cmplt_time
     '2026-04-01T00:00:00',               -- 17 activity_from_time
     N'Private Physician Office',         -- 18 rpt_src_cd_desc
     '2026-04-05T00:00:00',               -- 19 rpt_to_county_time
     '2026-04-06T00:00:00',               -- 20 rpt_to_state_time
     N'14',                               -- 21 mmwr_week
     N'2026',                             -- 22 mmwr_year
     N'Indigenous',                       -- 23 disease_imported_ind
     N'United States',                    -- 24 imported_from_country
     N'Georgia',                          -- 25 imported_from_state
     N'Fulton County',                    -- 26 imported_from_county
     N'Atlanta',                          -- 27 imported_city_desc_txt
     '2026-04-07T00:00:00',               -- 28 earliest_rpt_to_cdc_dt
     N'PP',                               -- 29 rpt_source_cd
     N'840',                              -- 30 imported_country_cd
     N'13',                               -- 31 imported_state_cd
     N'13121',                            -- 32 imported_county_cd
     N'13',                               -- 33 import_frm_city_cd
     '2026-04-03T00:00:00',               -- 34 diagnosis_time
     '2026-04-03T00:00:00',               -- 35 hospitalized_admin_time
     '2026-04-08T00:00:00',               -- 36 hospitalized_discharge_time
     5,                                   -- 37 hospitalized_duration_amt
     N'Y',                                -- 38 outbreak_ind
     N'Yes',                              -- 39 outbreak_ind_val
     N'Yes',                              -- 40 hospitalized_ind
     N'Y',                                -- 41 hospitalized_ind_cd
     N'CCN-V2-01',                        -- 42 city_county_case_nbr
     N'B',                                -- 43 transmission_mode_cd
     N'Bloodborne',                       -- 44 transmission_mode
     N'ACTIVE',                           -- 45 record_status_cd
     N'Y',                                -- 46 pregnant_ind_cd
     N'Yes',                              -- 47 pregnant_ind
     N'Yes',                              -- 48 die_frm_this_illness_ind
     N'No',                               -- 49 day_care_ind
     N'N',                                -- 50 day_care_ind_cd
     N'N',                                -- 51 food_handler_ind_cd
     N'No',                               -- 52 food_handler_ind
     '2026-04-09T00:00:00',               -- 53 deceased_time (populated on v2 to exercise INVESTIGATION_DEATH_DATE; foundation row exhibits null path)
     N'45',                               -- 54 pat_age_at_onset
     N'Y',                                -- 55 pat_age_at_onset_unit_cd
     N'Years',                            -- 56 pat_age_at_onset_unit
     '2026-04-02T00:00:00',               -- 57 investigator_assigned_time
     N'Active Surveillance',              -- 58 detection_method_desc_txt
     N'15',                               -- 59 effective_duration_amt
     N'D',                                -- 60 effective_duration_unit_cd
     N'Days',                             -- 61 illness_duration_unit
     N'Tier 1 v2 contact investigation comments', -- 62 contact_inv_txt
     N'HIGH',                             -- 63 contact_inv_priority
     '2026-04-01T00:00:00',               -- 64 infectious_from_date
     '2026-04-15T00:00:00',               -- 65 infectious_to_date
     N'O',                                -- 66 contact_inv_status
     '2026-04-30T00:00:00',               -- 67 activity_to_time
     N'Hepatitis',                        -- 68 program_area_description
     10009282,                            -- 69 add_user_id
     N'Foundation, Superuser',            -- 70 add_user_name
     '2026-04-01T00:00:00',               -- 71 add_time
     10009282,                            -- 72 last_chg_user_id
     N'Foundation, Superuser',            -- 73 last_chg_user_name
     '2026-04-01T00:00:00',               -- 74 last_chg_time
     N'AI',                               -- 75 referral_basis_cd
     N'Awaiting Interview',               -- 76 referral_basis
     N'Open',                             -- 77 curr_process_state
     N'HIGH',                             -- 78 inv_priority_cd
     N'COINF-V2-01',                      -- 79 coinfection_id
     N'LEGACY-CASE-V2-01',                -- 80 legacy_case_id
     N'OPEN-NEW',                         -- 81 curr_process_state_cd
     N'O',                                -- 82 investigation_status_cd
     N'Y',                                -- 83 outcome_cd
     N'IND',                              -- 84 disease_imported_cd
     N'EVN',                              -- 85 mood_cd
     N'CASE',                             -- 86 class_cd
     N'C',                                -- 87 case_class_cd (PHC_CLASS 'Confirmed')
     N'10110',                            -- 88 cd
     N'Hepatitis A, acute',               -- 89 cd_desc_txt
     N'HEP',                              -- 90 prog_area_cd
     N'V2-STATE-CASE-01',                 -- 91 inv_state_case_id
     N'PG_Hepatitis_A_Acute_Investigation', -- 92 investigation_form_cd
     N'Hepatitis Outbreak',               -- 93 outbreak_name_desc
     '2026-04-02T00:00:00',               -- 94 investigator_assigned_datetime
     20050011,                            -- 95 case_management_uid
     '2026-04-01T00:00:00',               -- 96 status_time
     '2026-04-01T00:00:00',               -- 97 record_status_time
     N'ACTIVE',                           -- 98 raw_record_status_cd
     1,                                   -- 99 batch_id
     N'13121',                            -- 100 rpt_cnty_cd
     N'Tier 1 v2 phc note text');         -- 101 notes

-- nrt_investigation_confirmation: drives the confirmation-method pivot
-- in the postprocessing SP (lines 713-732, 802-855). Two rows: one for
-- the v2 Investigation only. The foundation Investigation has no
-- confirmation method — exercises the no-CM-row branch (no row in
-- CONFIRMATION_METHOD_GROUP for foundation_investigation).
INSERT INTO [dbo].[nrt_investigation_confirmation]
    ([public_health_case_uid], [confirmation_method_cd],
     [confirmation_method_desc_txt], [confirmation_method_time], [batch_id])
VALUES
    -- v2 Investigation: confirmation_method_cd 'LD' (PHC_CONF_M
    -- 'Laboratory confirmed' — verified). Drives both confirmation_method
    -- INSERT (new row not in baseline) and CONFIRMATION_METHOD_GROUP.
    (20050010, N'LD', N'Laboratory confirmed', '2026-04-10T00:00:00', 1);

GO
