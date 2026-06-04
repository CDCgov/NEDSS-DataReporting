-- =====================================================================
-- Tier 3 — STD/HIV D_CASE_MANAGEMENT fill (PHC 22004000)
-- =====================================================================
-- Authored 2026-06-04 (Round 5 incremental, std_hiv-casemgmt agent).
-- UID block: 22059000 - 22059999 (NO new UIDs consumed).
--
-- GOAL: fill the ~38 D_CASE_MANAGEMENT-sourced columns of
-- std_hiv_datamart for STD Syphilis-primary PHC 22004000 (cond 10311,
-- PG_STD_Investigation): FL_FUP_*/INIT_FUP_*/OOJ_*/SURV_*/CA_*/
-- ADI_900_STATUS_CD/EPI_LINK_ID/INITIATING_AGNCY.
--
-- These are NOT page answers. They flow through a SEPARATE SP path:
--   1. routine 056 sp_investigation_event builds the
--      `investigation_case_management` JSON for PHC 22004000 as a
--      subquery off the ODSE source table:
--        SELECT <columns> FROM nbs_odse.dbo.case_management cm
--        WHERE cm.public_health_case_uid = phc.public_health_case_uid
--        FOR json path,INCLUDE_NULL_VALUES
--      (056 lines 603-691). Several columns are decoded inline via
--      fn_get_value_by_cvg(<raw>, '<code_set_nm>') → nbs_srte.dbo.
--      code_value_general.
--   2. reporting-pipeline-service InvestigationService /
--      ProcessInvestigationDataUtil.processInvestigationCaseManagement
--      iterates that JSON array and emits one
--      RDB_MODERN.dbo.nrt_investigation_case_management row per
--      case_management_uid (keyed phc_uid + case_management_uid).
--   3. Step 9 sp_nrt_case_management_postprocessing (routine 022)
--      joins nrt → INVESTIGATION on public_health_case_uid, LEFT JOINs
--      D_CASE_MANAGEMENT on INVESTIGATION_KEY, and UPDATEs the dim row
--      (it already exists: D_CASE_MANAGEMENT_KEY=6, INVESTIGATION_KEY=8).
--   4. routine 026 sp_std_hiv_datamart_postprocessing LEFT JOINs
--      D_CASE_MANAGEMENT CM ON CM.INVESTIGATION_KEY = PC.INVESTIGATION_KEY
--      (026 lines 521, 1181) and reads CM.<col> into the datamart.
--
-- ROOT CAUSE of the NULLs: the per-investigation ODSE `case_management`
-- source row (case_management_uid 22004001, authored by
-- std_hiv_investigation_full_chain.sql lines 220-229) set only 5
-- columns (status_900='C', field_record_number, surv_assigned_date,
-- surv_closed_date, case_closed_date). Everything else NULL → the JSON
-- carries NULLs → nrt NULL → dim cols NULL → datamart cols NULL.
--
-- FIX (deterministic, ODSE-only, additive): UPDATE the currently-NULL
-- columns of that existing per-investigation source row (a
-- per-investigation ODSE source — NOT a shared dim like D_PATIENT/
-- D_PROVIDER/D_ORGANIZATION/USER_PROFILE) with valid code_value_general
-- codes + dates + free text, so BOTH the raw columns AND their
-- fn_get_value_by_cvg-decoded counterparts fill. Then bump
-- public_health_case.last_chg_time (GETDATE) to re-fire the investigation
-- event, which re-projects the enriched JSON during the Tier-3 drain.
--
-- WHY NOT a 2nd case_management row (the LOOP brief's suggested
-- AUTO-IDENTITY path): `case_management.case_management_uid` is NOT an
-- IDENTITY column in this DB (verified COLUMNPROPERTY IsIdentity=0; all
-- 16 baseline rows use hardcoded PHC_uid+1). A 2nd row for the same
-- public_health_case_uid would produce a 2nd JSON element → 2nd nrt row
-- → #temp_cm_table gets 2 rows mapping to the SAME D_CASE_MANAGEMENT_KEY
-- (one dim row per INVESTIGATION_KEY via nrt_case_management_key, keyed
-- on public_health_case_uid), so routine 022's UPDATE...FROM picks an
-- ARBITRARY one (non-deterministic last-writer-wins) and a sparse row
-- could blank the rich one. The single-source enrich below is the only
-- deterministic ODSE-only path.
--
-- Codes verified against NBS_SRTE.dbo.code_value_general 2026-06-04.
-- All varchar values fit the source column widths (status_900 etc =
-- varchar(20); init_foll_up_clinic_code = varchar(50);
-- subj_oth_idntfyng_info = varchar(2000)).
--
-- ORCH_TODO: none. 22004000 is already in PHC_UIDS; Step 9 runs
-- sp_nrt_case_management_postprocessing (merge_and_verify.sh:547) before
-- sp_std_hiv_datamart_postprocessing (line 585). No EXEC sp_ here.
-- =====================================================================

USE [NBS_ODSE];
GO

-- ---------------------------------------------------------------------
-- Enrich the existing per-investigation case_management source row.
-- Only fill columns currently NULL on row 22004001; the 5 already-set
-- columns (status_900/field_record_number/surv_assigned_date/
-- surv_closed_date/case_closed_date) are left as-is.
-- Guarded so this is a no-op if (somehow) the source row is absent.
-- ---------------------------------------------------------------------
UPDATE [dbo].[case_management]
   SET
       -- ADI block ---------------------------------------------------
       ehars_id                      = N'EHARS22004',                -- adi_ehars_id   (varchar 10)
       subj_height                   = N'70',                        -- adi_height / adi_height_legacy_case
       subj_size_build               = N'Medium',                   -- adi_size_build
       subj_hair                     = N'Black',                    -- adi_hair
       subj_complexion               = N'Medium',                   -- adi_complexion
       subj_oth_idntfyng_info        = N'Tattoo right forearm',      -- adi_other_identifying_info
       -- CA / interview block ---------------------------------------
       pat_intv_status_cd            = N'I',                         -- PAT_INTVW_STATUS → ca_patient_intv_status='I - Interviewed'
       interview_assigned_date       = '2026-04-05T00:00:00',       -- ca_interviewer_assign_dt
       init_interview_assigned_date  = '2026-04-02T00:00:00',       -- ca_init_intvwr_assgn_dt
       epi_link_id                   = N'EPI-STD-22004',             -- epi_link_id
       -- Initial follow-up block ------------------------------------
       init_foll_up                  = N'FF',                        -- STD_CREATE_INV_LABMORB_NONSYPHILIS_PROC_DECISION
                                                                     --   → init_fup_initial_foll_up='Field Follow-up'
                                                                     --   raw → init_fup_initial_foll_up_cd
       init_foll_up_closed_date      = '2026-04-12T00:00:00',       -- init_fup_closed_dt
       internet_foll_up              = N'Y',                         -- YN → internet_foll_up='Yes'; raw → init_fup_internet_foll_up_cd
       init_foll_up_notifiable       = N'06',                        -- NOTIFIABLE → init_foll_up_notifiable; raw → init_fup_notifiable_cd
       init_foll_up_clinic_code      = N'STD-CLINIC-22004',          -- init_fup_clinic_code
       init_foll_up_assigned_date    = '2026-04-10T00:00:00',       -- fl_fup_init_assgn_dt
       -- Field follow-up block --------------------------------------
       foll_up_assigned_date         = '2026-04-08T00:00:00',       -- fl_fup_investigator_assgn_dt
       fld_foll_up_prov_exm_reason   = N'S',                         -- PRVDR_EXAM_REASON → fl_fup_prov_exm_reason='Symptomatic'
       fld_foll_up_prov_diagnosis    = N'097.1 Syphilis pri',         -- raw (varchar 20); LEFT(,3) → fl_fup_prov_diagnosis='097'
       fld_foll_up_notification_plan = N'2',                         -- NOTIFICATION_PLAN → fl_fup_notification_plan_cd='Provider'
       fld_foll_up_expected_in       = N'Y',                         -- YN → fl_fup_expected_in_ind='Yes'
       fld_foll_up_expected_date     = '2026-04-22T00:00:00',       -- fl_fup_expected_dt
       fld_foll_up_exam_date         = '2026-04-20T00:00:00',       -- fl_fup_exam_dt
       fld_foll_up_dispo             = N'C',                         -- FIELD_FOLLOWUP_DISPOSITION_STDHIV
                                                                     --   → fl_fup_disposition_desc='C - Infected, Brought to Treatment'
                                                                     --   raw → fl_fup_disposition_cd
       fld_foll_up_dispo_date        = '2026-04-15T00:00:00',       -- fl_fup_dispo_dt
       act_ref_type_cd               = N'2',                         -- NOTIFICATION_ACTUAL_METHOD_STD → fl_fup_actual_ref_type='2 - Provider'
       case_review_status            = N'REVIEWED',                  -- case_review_status
       case_review_status_date       = '2026-04-29T00:00:00',       -- case_review_status_date
       fld_foll_up_internet_outcome  = N'I1',                        -- INTERNET_FOLLOWUP_OUTCOME → fl_fup_internet_outcome; raw → fl_fup_internet_outcome_cd
       field_foll_up_ooj_outcome     = N'K',                         -- FIELD_FOLLOWUP_DISPOSITION_STDHIV
                                                                     --   → fl_fup_ooj_outcome='K - Sent Out Of Jurisdiction'; raw also stored
       -- OOJ block --------------------------------------------------
       ooj_agency                    = N'13',                        -- OOJ_AGENCY_LOCAL → ooj_agency='Georgia'
       ooj_number                    = N'OOJ-2026-22004',            -- ooj_number
       ooj_due_date                  = '2026-04-25T00:00:00',       -- ooj_due_date
       initiating_agncy              = N'13',                        -- OOJ_AGENCY_LOCAL → initiating_agncy='Georgia'
       ooj_initg_agncy_recd_date     = '2026-04-18T00:00:00',       -- ooj_initg_agncy_recd_date
       ooj_initg_agncy_outc_due_date = '2026-04-28T00:00:00',       -- ooj_initg_agncy_outc_due_date
       ooj_initg_agncy_outc_snt_date = '2026-04-27T00:00:00',       -- ooj_initg_agncy_outc_snt_date
       -- Surveillance block -----------------------------------------
       surv_provider_contact         = N'S',                         -- PRVDR_CONTACT_OUTCOME → surv_provider_contact='S - Successful'; raw → _cd
       surv_prov_exm_reason          = N'S',                         -- PRVDR_EXAM_REASON → surv_provider_exam_reason='Symptomatic'
       surv_prov_diagnosis           = N'Syphilis primary',          -- surv_provider_diagnosis
       surv_patient_foll_up          = N'FF'                         -- SURVEILLANCE_PATIENT_FOLLOWUP → surv_patient_foll_up_cd='Field Follow-up'
 WHERE public_health_case_uid = 22004000
   AND case_management_uid     = 22004001;
GO

-- ---------------------------------------------------------------------
-- CDC RE-TRIGGER: bump public_health_case.last_chg_time so the
-- Debezium/connect chain re-emits PHC 22004000 → the service re-runs
-- sp_investigation_event and re-projects investigation_case_management
-- (the case_management subquery, 056 lines 603-691) with the enriched
-- values into nrt_investigation_case_management. GETDATE() guarantees a
-- value later than any prior literal bump in the STD fixture set so this
-- enrichment wins. (This is the investigation's OWN PHC row — not a
-- shared dim. No nrt_* INSERT, no EXEC sp_.)
-- ---------------------------------------------------------------------
UPDATE [dbo].[public_health_case]
   SET last_chg_time = GETDATE()
 WHERE public_health_case_uid = 22004000;
GO
