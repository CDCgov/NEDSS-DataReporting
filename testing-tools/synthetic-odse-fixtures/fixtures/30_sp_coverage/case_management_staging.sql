-- =====================================================================
-- Tier 3 — case_management ODSE source authoring (Hep A Investigations)
-- =====================================================================
-- Authored 2026-05-21; converted to ODSE-only 2026-06-05.
--
-- Goal: populate D_CASE_MANAGEMENT for the two Hep A Investigations
-- (foundation PHC 20000100 + v2 PHC 20050010) the ODSE-only way.
--
-- PRINCIPLE: fixtures author ONLY NBS_ODSE rows. The RTR pipeline
-- derives everything in RDB_MODERN:
--   1. routine 056 sp_investigation_event builds the
--      `investigation_case_management` JSON for the PHC as a subquery
--      off the ODSE source table NBS_ODSE.dbo.case_management
--      (056 lines 603-691). Several columns are decoded inline via
--      fn_get_value_by_cvg(<raw>, '<code_set_nm>') →
--      nbs_srte.dbo.code_value_general.
--   2. reporting-pipeline-service emits one
--      RDB_MODERN.dbo.nrt_investigation_case_management row per
--      case_management_uid (keyed phc_uid + case_management_uid).
--   3. Step 9 sp_nrt_case_management_postprocessing (routine 022)
--      joins nrt → INVESTIGATION and UPDATEs D_CASE_MANAGEMENT.
--
-- This file therefore writes RAW ODSE source codes (e.g. status_900='C',
-- init_foll_up='FF') — NOT the decoded nrt values ('CLOSED'/'COMPLETED')
-- the old version wrote directly into RDB_MODERN. fn_get_value_by_cvg
-- decodes the raw codes during the JSON projection.
--
-- nrt-col → ODSE-source-col + code_set_nm decode map mirrors
-- zz_std_case_management.sql (PHC 22004000). Raw codes verified against
-- NBS_SRTE.dbo.code_value_general 2026-06-04.
--
-- DETERMINISM: exactly one case_management row per PHC (routine 022
-- picks an arbitrary one if there are two). For 20050010 we ENRICH the
-- existing row (case_management_uid 20050011); for 20000100 we INSERT
-- the single source row (case_management_uid 20000101).
--
-- The prior STD/HIV staging row (PHC 22004000) lives in
-- zz_std_case_management.sql and is unaffected.
-- =====================================================================

USE [NBS_ODSE];
GO

-- ---------------------------------------------------------------------
-- PHC 20050010 (v2 Hep A) — ENRICH the existing per-investigation
-- case_management source row (case_management_uid 20050011). We write
-- the RAW source columns; fn_get_value_by_cvg decodes them into the
-- nrt/dim columns during the 056 JSON projection. Comments show the
-- resulting nrt column (and decode code_set where applicable).
-- ---------------------------------------------------------------------
UPDATE [dbo].[case_management]
   SET
       -- ADI block ---------------------------------------------------
       status_900                    = N'C',                         -- adi_900_status_cd; decode STATUS_900 → status_900
       ehars_id                      = N'EHARS-001',                 -- adi_ehars_id (varchar 10)
       subj_height                   = N'70',                        -- adi_height / adi_height_legacy_case
       subj_size_build               = N'Athletic',                  -- adi_size_build
       subj_hair                     = N'Brown',                     -- adi_hair
       subj_complexion               = N'Medium',                    -- adi_complexion
       subj_oth_idntfyng_info        = N'Tattoo left arm',           -- adi_other_identifying_info
       -- CA / interview block ---------------------------------------
       pat_intv_status_cd            = N'I',                         -- pat_intv_status_cd; decode PAT_INTVW_STATUS → ca_patient_intv_status
       interview_assigned_date       = '2026-04-05T00:00:00',       -- ca_interviewer_assign_dt
       init_interview_assigned_date  = '2026-04-02T00:00:00',       -- ca_init_intvwr_assgn_dt
       epi_link_id                   = N'EPI-HEPA-001',              -- epi_link_id
       case_closed_date              = '2026-04-30T00:00:00',       -- cc_closed_dt
       -- Initial follow-up block ------------------------------------
       init_foll_up                  = N'FF',                        -- init_fup_initial_foll_up_cd;
                                                                     --   decode STD_CREATE_INV_LABMORB_NONSYPHILIS_PROC_DECISION
                                                                     --   → init_fup_initial_foll_up
       init_foll_up_closed_date      = '2026-04-12T00:00:00',       -- init_fup_closed_dt
       internet_foll_up              = N'Y',                         -- init_fup_internet_foll_up_cd; decode YN → internet_foll_up
       init_foll_up_notifiable       = N'06',                        -- init_fup_notifiable_cd; decode NOTIFIABLE → init_foll_up_notifiable
       init_foll_up_clinic_code      = N'STD-CLINIC',                -- init_fup_clinic_code
       init_foll_up_assigned_date    = '2026-04-10T00:00:00',       -- fl_fup_init_assgn_dt
       -- Field follow-up block --------------------------------------
       field_record_number           = N'FRN-FF-001',               -- fl_fup_field_record_num
       foll_up_assigned_date         = '2026-04-08T00:00:00',       -- fl_fup_investigator_assgn_dt
       fld_foll_up_prov_exm_reason   = N'S',                         -- decode PRVDR_EXAM_REASON → fl_fup_prov_exm_reason
       fld_foll_up_prov_diagnosis    = N'Acute hep A',               -- fld_foll_up_prov_diagnosis (varchar 20); LEFT(,3) → fl_fup_prov_diagnosis
       fld_foll_up_notification_plan = N'2',                         -- decode NOTIFICATION_PLAN → fl_fup_notification_plan_cd
       fld_foll_up_expected_in       = N'Y',                         -- decode YN → fl_fup_expected_in_ind
       fld_foll_up_expected_date     = '2026-04-22T00:00:00',       -- fl_fup_expected_dt
       fld_foll_up_exam_date         = '2026-04-20T00:00:00',       -- fl_fup_exam_dt
       fld_foll_up_dispo             = N'C',                         -- fl_fup_disposition_cd;
                                                                     --   decode FIELD_FOLLOWUP_DISPOSITION_STDHIV → fl_fup_disposition_desc
       fld_foll_up_dispo_date        = '2026-04-15T00:00:00',       -- fl_fup_dispo_dt
       act_ref_type_cd               = N'2',                         -- decode NOTIFICATION_ACTUAL_METHOD_STD → fl_fup_actual_ref_type
       case_review_status            = N'REVIEWED',                  -- case_review_status (passthrough)
       case_review_status_date       = '2026-04-29T00:00:00',       -- case_review_status_date
       fld_foll_up_internet_outcome  = N'I1',                        -- fl_fup_internet_outcome_cd;
                                                                     --   decode INTERNET_FOLLOWUP_OUTCOME → fl_fup_internet_outcome
       field_foll_up_ooj_outcome     = N'K',                         -- field_foll_up_ooj_outcome;
                                                                     --   decode FIELD_FOLLOWUP_DISPOSITION_STDHIV → fl_fup_ooj_outcome
       -- OOJ block --------------------------------------------------
       ooj_agency                    = N'13',                        -- decode OOJ_AGENCY_LOCAL → ooj_agency
       ooj_number                    = N'OOJ-2026-001',              -- ooj_number
       ooj_due_date                  = '2026-04-25T00:00:00',       -- ooj_due_date
       initiating_agncy              = N'13',                        -- decode OOJ_AGENCY_LOCAL → initiating_agncy
       ooj_initg_agncy_recd_date     = '2026-04-18T00:00:00',       -- ooj_initg_agncy_recd_date
       ooj_initg_agncy_outc_due_date = '2026-04-28T00:00:00',       -- ooj_initg_agncy_outc_due_date
       ooj_initg_agncy_outc_snt_date = '2026-04-27T00:00:00',       -- ooj_initg_agncy_outc_snt_date
       -- Surveillance block -----------------------------------------
       surv_assigned_date            = '2026-04-04T00:00:00',       -- surv_investigator_assgn_dt
       surv_closed_date              = '2026-04-30T00:00:00',       -- surv_closed_dt
       surv_provider_contact         = N'S',                         -- decode PRVDR_CONTACT_OUTCOME → surv_provider_contact; raw → _cd
       surv_prov_exm_reason          = N'S',                         -- decode PRVDR_EXAM_REASON → surv_provider_exam_reason
       surv_prov_diagnosis           = N'Acute hep A',               -- surv_provider_diagnosis
       surv_patient_foll_up          = N'FF'                         -- decode SURVEILLANCE_PATIENT_FOLLOWUP → surv_patient_foll_up_cd
 WHERE public_health_case_uid = 20050010
   AND case_management_uid     = 20050011;
GO

-- ---------------------------------------------------------------------
-- PHC 20000100 (foundation Hep A) — INSERT the single per-investigation
-- case_management source row (none exists yet). A few populated columns
-- exercise the populated branches downstream; the rest stay NULL.
-- case_management_uid is IDENTITY → toggle IDENTITY_INSERT to pin the
-- conventional PHC_uid+1 key (20000101).
-- ---------------------------------------------------------------------
SET IDENTITY_INSERT [dbo].[case_management] ON;
INSERT INTO [dbo].[case_management]
    ([case_management_uid], [public_health_case_uid], [status_900],
     [init_interview_assigned_date], [case_closed_date])
VALUES
    (20000101, 20000100, N'C',
     '2026-04-02T00:00:00', '2026-04-30T00:00:00');
SET IDENTITY_INSERT [dbo].[case_management] OFF;
GO

-- ---------------------------------------------------------------------
-- CDC RE-TRIGGER: bump public_health_case.last_chg_time so the
-- Debezium/connect chain re-emits each PHC → the service re-runs
-- sp_investigation_event and re-projects investigation_case_management
-- with the enriched/new values into nrt_investigation_case_management.
-- GETDATE() guarantees a value later than any prior literal bump so this
-- authoring wins. (These are the investigations' OWN PHC rows — not a
-- shared dim. No nrt_* INSERT, no EXEC sp_.)
-- ---------------------------------------------------------------------
UPDATE [dbo].[public_health_case]
   SET last_chg_time = GETDATE()
 WHERE public_health_case_uid IN (20050010, 20000100);
GO
