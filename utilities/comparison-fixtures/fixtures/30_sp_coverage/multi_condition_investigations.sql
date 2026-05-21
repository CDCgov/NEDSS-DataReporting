-- =====================================================================
-- Tier 3 — multi-condition Investigation variants
-- =====================================================================
-- Goal: populate condition-gated datamart fact tables (TB_DATAMART,
-- VAR_DATAMART, COVID_*_DATAMART, sp_pertussis/measles/rubella_case
-- datamarts, BMIRD_STREP_PNEUMO_DATAMART, STD_HIV_DATAMART).
--
-- v1 originally used a single condition (Hep A acute, condition_cd
-- '10110') for all Investigation variants. The condition-specific
-- datamart SPs filter on condition_cd or investigation_form_cd; with
-- only Hep A in the merged state, none of them populate.
--
-- This Tier 3 fixture authors 10 additional Investigation variants —
-- one per condition family — as nrt_investigation rows directly. The
-- datamart SPs read from nrt_investigation + INVESTIGATION + condition
-- without traversing back to ODSE, so we skip authoring full
-- act/public_health_case ODSE rows for these variants. After applying,
-- sp_nrt_investigation_postprocessing flows them into INVESTIGATION;
-- then the datamart SPs at Step 9 pick them up.
--
-- UIDs allocated from Tier 3 block 22000000-22099999:
--   22000010 — TB (10220, INV_FORM_RVCT)
--   22000020 — Varicella (10030, INV_FORM_VAR)
--   22000030 — Mumps (10180, PG_Mumps_Investigation)
--   22000040 — Pertussis (10190, PG_Pertussis_Investigation)
--   22000050 — Measles (10140, PG_Measles_(PB))
--   22000060 — Rubella (10200, INV_FORM_RUB)
--   22000070 — COVID-19 (11065, PG_COVID-19_v1.1)
--   22000080 — Syphilis primary (10311, PG_STD_Investigation)
--   22000090 — HIV pediatric (10561, INV_FORM_GEN)
--   22000100 — Strep pneumoniae invasive (11717, INV_FORM_BMDSP)
--
-- INSERTs use the same column set as v2 Investigation, with NULL for
-- most columns and only the condition-defining columns populated. The
-- conditions referenced are seeded by sp_nrt_srte_condition_code_postprocessing
-- with a multi-condition list (extended in merge_and_verify.sh).
--
-- After this fixture applies, the orchestrator re-runs
-- sp_nrt_investigation_postprocessing to flow these into INVESTIGATION.
-- =====================================================================

USE [RDB_MODERN];

-- patient_id = 20000000 (foundation Patient) on every variant so the
-- HEPATITIS_DATAMART chain's COALESCE(PATIENT.PATIENT_KEY, 1) → sentinel
-- → DELETE WHERE PATIENT_UID IS NULL path doesn't drop the row pre-INSERT.
-- See fixtures/10_subjects/investigation.sql for the same convention on
-- Tier 1.
INSERT INTO [dbo].[nrt_investigation]
    ([public_health_case_uid], [patient_id], [local_id], [shared_ind], [case_type_cd],
     [jurisdiction_cd], [record_status_cd], [mood_cd], [class_cd],
     [case_class_cd], [cd], [cd_desc_txt], [prog_area_cd],
     [investigation_form_cd], [case_management_uid],
     [status_time], [record_status_time], [raw_record_status_cd],
     [add_time], [last_chg_time], [investigation_status_cd])
VALUES
    -- TB
    (22000010, 20000000, N'CAS22000010GA01', N'F', N'I',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'10220', N'Tuberculosis', N'TB',
     N'INV_FORM_RVCT', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O'),
    -- Varicella
    (22000020, 20000000, N'CAS22000020GA01', N'F', N'I',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'10030', N'Varicella (Chickenpox)', N'VAC',
     N'INV_FORM_VAR', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O'),
    -- Mumps
    (22000030, 20000000, N'CAS22000030GA01', N'F', N'I',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'10180', N'Mumps', N'VAC',
     N'PG_Mumps_Investigation', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O'),
    -- Pertussis
    (22000040, 20000000, N'CAS22000040GA01', N'F', N'I',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'10190', N'Pertussis', N'VAC',
     N'PG_Pertussis_Investigation', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O'),
    -- Measles
    (22000050, 20000000, N'CAS22000050GA01', N'F', N'I',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'10140', N'Measles (Rubeola)', N'VAC',
     N'PG_Measles_(PB)', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O'),
    -- Rubella
    (22000060, 20000000, N'CAS22000060GA01', N'F', N'I',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'10200', N'Rubella', N'VAC',
     N'INV_FORM_RUB', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O'),
    -- COVID-19
    (22000070, 20000000, N'CAS22000070GA01', N'F', N'I',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'11065', N'2019 Novel Coronavirus', N'COV',
     N'PG_COVID-19_v1.1', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O'),
    -- Syphilis primary (STD family)
    (22000080, 20000000, N'CAS22000080GA01', N'F', N'I',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'10311', N'Syphilis, primary', N'STD',
     N'PG_STD_Investigation', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O'),
    -- HIV pediatric
    (22000090, 20000000, N'CAS22000090GA01', N'F', N'I',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'10561', N'HIV Infection, pediatric', N'HIV',
     N'INV_FORM_GEN', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O'),
    -- Strep pneumoniae invasive (BMIRD family)
    (22000100, 20000000, N'CAS22000100GA01', N'F', N'I',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'11717', N'Strep pneumoniae, invasive', N'BMIRD',
     N'INV_FORM_BMDSP', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O');

-- Run sp_nrt_investigation_postprocessing to flow these into INVESTIGATION.
EXEC dbo.sp_nrt_investigation_postprocessing
    @id_list = N'22000010,22000020,22000030,22000040,22000050,22000060,22000070,22000080,22000090,22000100',
    @debug = 0;
