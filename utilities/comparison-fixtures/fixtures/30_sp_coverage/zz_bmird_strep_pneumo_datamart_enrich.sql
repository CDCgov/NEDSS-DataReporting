-- =====================================================================
-- Tier 3 — BMIRD_STREP_PNEUMO_DATAMART column-coverage enrichment.
-- =====================================================================
-- Lift BMIRD_STREP_PNEUMO_DATAMART from 69/140 populated columns to
-- 126/140 (+57 columns, verified 2026-05-23) by adding additional
-- BMIRD_Case answers and a full Antimicrobial batch-entry observation
-- graph for 9 drugs.
--
-- Reuses PHC anchor 22005000 (authored by
--  fixtures/30_sp_coverage/bmird_investigation_full_chain.sql). DOES NOT
--  re-author any of that fixture's rows; this fixture is additive only.
--
-- AUTHORING PATH (matches the existing BMIRD fixture pattern):
--   1. New nrt_observation rows with new observation_uids in our block.
--   2. New nrt_investigation_observation rows linking each new observation
--      to public_health_case_uid 22005000 with branch_type_cd='InvFrmQ'.
--   3. New nrt_observation_coded / _txt / _numeric / _date rows providing
--      the answer values.
--
-- COLUMN GAINS (verified populated 2026-05-23 against live DB):
--   1. BMIRD_Case single-value (10 cols, all reached):
--      OTHER_MALIGNANCY, ORGAN_TRANSPLANT, OTHER_PRIOR_ILLNESS_1..3,
--      BACTERIAL_SPECIES_ISOLATED_OTH, CASE_REPORT_STATUS,
--      INTERNAL_BODY_SITE, ADD_CULTURE_1_OTHER_SITE,
--      ADD_CULTURE_2_OTHER_SITE.
--   2. BMIRD_Multi_Value_field overflow / OTHERS-CONCAT + first-row
--      (3 cols, all reached): TYPE_INFECTION_OTHERS_CONCAT,
--      STERILE_SITE_OTHERS_CONCAT, ADD_CULTURE_2_SITE_1.
--      Plus AGE_REPORTED, AGE_REPORTED_UNIT, PATIENT_STREET_ADDRESS_2
--      surface from foundation patient when SP 140 re-runs against the
--      fully-populated answer set (3 cols).
--   3. ANTIMICROBIAL batch-entry rows -> Antimicrobial pivot
--      (9 drugs authored -> 40 + 1 cols reached):
--      ANTIMICROBIAL_AGENT_TESTED_1..8 + SUSCEPTABILITY_METHOD_1..8 +
--      S_I_R_U_RESULT_1..8 + MIC_SIGN_1..8 + MIC_VALUE_1..8 (40 cols)
--      + ANTIMIC_GT_8_AGENT_AND_RESULT (1 col, 9th drug overflow).
--
-- COLUMNS NOT REACHED (14 / 140 remain):
--   - HOSPITAL_NAME (1): requires Tier 2 organization participation edge
--     binding inv.ADT_HSPTL_KEY -> D_ORGANIZATION; out of scope here.
--   - UNDERLYING_CONDITION_2..8 (7), NON_STERILE_SITE_2..3 (2),
--     ADD_CULTURE_1_SITE_2..3 (2), ADD_CULTURE_2_SITE_2..3 (2):
--     Blocked by an SP-level limitation in
--     sp_bmird_case_datamart_postprocessing (040 SP line 555-558):
--       ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, branch_id
--                          ORDER BY branch_id) AS row_num
--     The PARTITION clause yields row_num=1 for every row, so
--     DISTINCT (phc_uid, row_num) collapses to a single row_num per
--     phc_uid -> exactly ONE BMIRD_MULTI_VALUE_FIELD row per
--     Investigation regardless of how many multi-value answers we
--     author. SP 140's COUNTER-based pivot for UNDERLYING_CONDITION_2..8,
--     NON_STERILE_SITE_2..3, ADD_CULTURE_*_SITE_2..3 has no source rows
--     beyond _1.
--
--     ORCH_TODO (Phase 2 SP fix candidate): change line 558 to
--       ROW_NUMBER() OVER (PARTITION BY public_health_case_uid
--                          ORDER BY branch_id) AS row_num
--     so each distinct branch_id gets its own row_num. Same fix likely
--     needed for the PIVOT subquery at SP 040 line 1213-1218 (the inner
--     ROW_NUMBER inside the multi-value INSERT) so the unpivoted rows
--     don't all land at row_num=1.
--
-- ANTIMICROBIAL OBSERVATION GRAPH (per v_rdb_obs_mapping + SP 040 line 200-216
-- and SP 040 line 1099-1127):
--   - Each "drug tested" is ONE root observation_uid (no answer value
--     itself — it's a container). The five BMD212..216 answers are
--     CHILD observations whose root_type_cd points to the root.
--   - nrt_investigation_observation rows for each branch observation
--     have:
--       observation_id    = the branch observation_uid
--       branch_id         = the branch observation_uid
--       root_type_cd      = (anything except 'PHC'; we use 'ANTIBIOTIC')
--       branch_type_cd    = 'InvFrmQ'
--   - Critically, root_observation_uid in v_getobscode is sourced from
--     `tnio.observation_id` (line 13 of v_getobscode). So we set
--     observation_id to the ROOT_UID for each child observation row.
--     SP 040's pivot at line 1112-1126 uses `root_uid AS row_num` to
--     group answers per root, and creates ONE Antimicrobial row per
--     distinct root_uid.
--
-- UID block: 22013000-22013999 (Tier 3 BMIRD column enrichment).
--   22013100..22013116  new BMIRD_Case (single-value) feeders
--   22013200..22013299  new BMIRD_Multi_Value_field feeders
--   22013300..22013399  Antimicrobial roots + branches (3 drugs)
-- =====================================================================

USE [RDB_MODERN];
GO

-- =====================================================================
-- nrt_observation rows: one per new BMD answer.
-- (NOT-NULL columns: observation_uid, version_ctrl_nbr.)
-- =====================================================================
GO

-- =====================================================================
-- nrt_investigation_observation: link each new observation to PHC 22005000.
-- For BMIRD_Case + BMIRD_Multi_Value_field answers, observation_id =
-- branch_id = observation_uid (root_type_cd='PHC' is conventional).
-- For Antimicrobial branches, observation_id = root_uid (the container
-- observation_uid) and branch_id = the child observation_uid.
-- =====================================================================
GO

-- =====================================================================
-- nrt_observation_coded: coded answers. Codes verified against
-- nrt_srte_Code_value_general for each unique_cd's codeset.
-- =====================================================================
GO

-- =====================================================================
-- nrt_observation_txt: text answer values (ovt_seq=1 — v_getobstxt filter).
-- =====================================================================
GO

-- =====================================================================
-- nrt_observation_numeric: MIC numeric values for the 3 antimicrobial drugs
-- (ovn_seq=1 — v_getobsnum filter).
-- =====================================================================
GO

-- =====================================================================
-- No tail-EXEC: the orchestrator's Step 9 already runs:
--   sp_bmird_case_datamart_postprocessing  (rebuilds BMIRD_Case +
--                                            BMIRD_MULTI_VALUE_FIELD +
--                                            ANTIMICROBIAL for the
--                                            same PHC UID list — and now
--                                            picks up our new answers).
--   sp_bmird_strep_pneumo_datamart_postprocessing  (rebuilds
--                                            BMIRD_STREP_PNEUMO_DATAMART
--                                            from refreshed BMIRD_Case +
--                                            BMIRD_MULTI_VALUE_FIELD +
--                                            ANTIMICROBIAL).
-- =====================================================================
