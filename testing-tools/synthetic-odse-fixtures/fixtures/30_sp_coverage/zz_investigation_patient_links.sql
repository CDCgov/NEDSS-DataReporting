-- =====================================================================
-- zz_investigation_patient_links.sql
--
-- Links each synthetic investigation to a patient via a SubjOfPHC
-- participation. Without this, sp_investigation_event cannot resolve
-- nrt_investigation.patient_id, so ProcessDatamartData skips EVERY
-- condition datamart (ProcessDatamartData.java:113-115 drops any
-- DatamartData whose patientUid is NULL). With it, the service fires the
-- condition datamart SP mapped in nrt_datamart_metadata for each
-- condition (COVID_CASE, STD_HIV, TB, Hepatitis, ...).
--
-- This is the Tier-2 link-fidelity fix (was P3): the *_investigation_
-- full_chain.sql fixtures created the PHC but never the patient subject
-- link. All investigations point at the foundation patient 20000000
-- (which has a complete D_PATIENT row) — a coverage-oriented
-- simplification; real NBS would use a distinct patient per case.
--
-- Sorts before zz_page_answers_datamart_routing.sql so that fixture's
-- closing CDC re-trigger (last_chg_time bump) reprocesses each
-- investigation with BOTH the page answers and this patient link present.
-- =====================================================================

INSERT INTO NBS_ODSE.dbo.participation
    (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
     last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
     status_cd, status_time, subject_class_cd, type_desc_txt)
SELECT 20000000, phc.public_health_case_uid, 'SubjOfPHC', 'CASE',
       '2026-04-01', 10009282,  CAST(GETDATE() AS DATE), 10009282, 'ACTIVE', '2026-04-01',
       'A', '2026-04-01', 'PSN', 'Subject of Public Health Case'
FROM NBS_ODSE.dbo.public_health_case phc
-- NOTE: 22003000 (COVID full-chain), 22004000 (STD Syphilis full-chain) and
-- 22001000 (TB RVCT full-chain) are INTENTIONALLY OMITTED here. Round 5 item C
-- authors dedicated, richly-attributed patients and links them as those PHCs'
-- SubjOfPHC so the covid_case_datamart / std_hiv_datamart / tb_datamart +
-- tb_hiv_datamart PATIENT_* columns populate:
--   22003000 -> 22055000 (zz_covid_dedicated_entities.sql)
--   22004000 -> 22057000 (zz_std_dedicated_entities.sql)
--   22001000 -> 22058000 (zz_tb_dedicated_entities.sql)
-- Adding the sparse foundation patient 20000000 here would create a SECOND
-- SubjOfPHC row on those PHCs (this fixture sorts BEFORE the dedicated-entity
-- fixtures, which DELETE the foundation link and INSERT their own — but
-- omitting them here keeps the link unambiguous regardless of run order),
-- making nrt_investigation.patient_id non-deterministic. Keep exactly one
-- SubjOfPHC for each (22003000 -> 22055000, 22004000 -> 22057000,
-- 22001000 -> 22058000).
WHERE phc.public_health_case_uid IN
        (22002000, 22005000, 22006000, 22007000, 22008500)
  AND NOT EXISTS (SELECT 1 FROM NBS_ODSE.dbo.participation p
                  WHERE p.act_uid = phc.public_health_case_uid
                    AND p.subject_entity_uid = 20000000
                    AND p.type_cd = 'SubjOfPHC');
GO
