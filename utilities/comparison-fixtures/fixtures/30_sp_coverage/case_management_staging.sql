-- =====================================================================
-- Tier 3 — nrt_investigation_case_management staging rows
-- =====================================================================
-- Authored 2026-05-21 (overnight loop iteration #3).
--
-- Goal: populate D_CASE_MANAGEMENT (currently 0/67) by authoring
-- nrt_investigation_case_management staging rows. The orchestrator's
-- Step 9 now invokes sp_nrt_case_management_postprocessing.
--
-- Existing 1 staging row from STD/HIV agent (PHC=22004000) is left in
-- place. This fixture adds 2 rows for the Hep A Investigations
-- (foundation 20000100 + v2 20050010) plus broad-spectrum UPDATEs
-- with short string values that fit the narrow column widths.
--
-- Column-width constraint: many cols are varchar(3) or varchar(20).
-- All UPDATE values must fit. Validated 2026-05-21 against
-- INFORMATION_SCHEMA.COLUMNS.
-- =====================================================================

USE [RDB_MODERN];
GO

-- Minimal INSERT: just keys + a few non-NULL columns.

-- Enrich the v2 row (20050010) — all values fit the narrowest column
-- (varchar(3) for *_ind cols, varchar(10) for adi_ehars_id /
-- fl_fup_internet_outcome_cd, varchar(15) for fl_fup_actual_ref_type
-- and fl_fup_notification_plan_cd, varchar(20) for most others).
UPDATE [dbo].[nrt_investigation_case_management]
   SET adi_900_status_cd            = N'CLOSED',
       adi_complexion               = N'Medium',
       adi_ehars_id                 = N'EHARS-001',         -- max 10
       adi_hair                     = N'Brown',
       adi_height                   = N'70in',
       adi_other_identifying_info   = N'Tattoo left arm',
       adi_size_build               = N'Athletic',
       ca_init_intvwr_assgn_dt      = '2026-04-02T00:00:00',
       ca_interviewer_assign_dt     = '2026-04-05T00:00:00',
       ca_patient_intv_status       = N'COMPLETED',
       case_oid                     = 20050010,
       case_review_status           = N'CASE_REVIEWED',
       case_review_status_date      = '2026-04-29T00:00:00',
       cc_closed_dt                 = '2026-04-30T00:00:00',
       epi_link_id                  = N'EPI-HEPA-001',
       field_foll_up_ooj_outcome    = N'NOT_NOTIFIED',
       fl_fup_actual_ref_type       = N'PRIV_PROVIDER',     -- max 15
       fl_fup_dispo_dt              = '2026-04-15T00:00:00',
       fl_fup_disposition_cd        = N'CONTACT_FOUND',
       fl_fup_disposition_desc      = N'Contact found',
       fl_fup_exam_dt               = '2026-04-20T00:00:00',
       fl_fup_expected_dt           = '2026-04-22T00:00:00',
       fl_fup_expected_in_ind       = N'Y',                  -- max 3
       fl_fup_field_record_num      = N'FRN-FF-001',
       fl_fup_init_assgn_dt         = '2026-04-10T00:00:00',
       fl_fup_internet_outcome      = N'EXAMINED_BY_PROV',
       fl_fup_internet_outcome_cd   = N'EBP',                -- max 10
       fl_fup_investigator_assgn_dt = '2026-04-08T00:00:00',
       fl_fup_notification_plan_cd  = N'PHONE_AND_EMAIL',    -- max 15
       fl_fup_ooj_outcome           = N'OOJ_COMPLETED',
       fl_fup_prov_diagnosis        = N'AHA',                -- max 3
       fl_fup_prov_exm_reason       = N'INITIAL_EVALUATION',
       fld_foll_up_expected_in      = N'Yes',
       fld_foll_up_notification_plan = N'Phone',
       fld_foll_up_prov_diagnosis   = N'Acute hep A',
       fld_foll_up_prov_exm_reason  = N'Initial workup',
       init_fup_clinic_code         = N'STD-CLINIC',
       init_fup_closed_dt           = '2026-04-12T00:00:00',
       init_fup_initial_foll_up     = N'COMPLETED',
       init_fup_initial_foll_up_cd  = N'IFC',
       init_fup_internet_foll_up_cd = N'CONTACTED',
       init_foll_up_notifiable      = N'Y',
       init_fup_notifiable_cd       = N'Y',
       initiating_agncy             = N'GA-DPH-D3-2',
       internet_foll_up             = N'Y',                  -- max 3
       ooj_agency                   = N'GA-DPH-D4',
       ooj_due_date                 = '2026-04-25T00:00:00',
       ooj_number                   = N'OOJ-2026-001',
       pat_intv_status_cd           = N'COMPLETED',
       status_900                   = N'C',
       surv_closed_dt               = '2026-04-30T00:00:00',
       surv_investigator_assgn_dt   = '2026-04-04T00:00:00',
       surv_patient_foll_up         = N'COMPLETED_W7D',
       surv_patient_foll_up_cd      = N'CW7',
       surv_provider_contact        = N'PROVIDER_CONF',
       surv_provider_contact_cd     = N'PC',
       surv_provider_diagnosis      = N'Acute hep A',
       surv_provider_exam_reason    = N'Initial eval'
 WHERE public_health_case_uid = 20050010;

-- Add a few fields on the foundation row to exercise null/blank vs
-- populated branches downstream.
UPDATE [dbo].[nrt_investigation_case_management]
   SET adi_900_status_cd        = N'CLOSED',
       ca_init_intvwr_assgn_dt  = '2026-04-02T00:00:00',
       cc_closed_dt             = '2026-04-30T00:00:00'
 WHERE public_health_case_uid = 20000100;
