-- =====================================================================
-- Tier 3 — BMIRD_STREP_PNEUMO_DATAMART column-coverage enrichment.
-- =====================================================================
-- Lift BMIRD_STREP_PNEUMO_DATAMART from 69/140 populated columns to as
-- close to 140 as observation-graph authoring will allow.
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
-- TARGET COLUMN GAINS (counts approximate — actual depends on whether
-- SP-internal pivot CASE-WHEN matches our codes):
--   1. BMIRD_Case single-value coded/text columns (8 cols)
--      OTHER_MALIGNANCY, ORGAN_TRANSPLANT, OTHER_PRIOR_ILLNESS_1..3,
--      BACTERIAL_SPECIES_ISOLATED_OTH, CASE_REPORT_STATUS,
--      INTERNAL_BODY_SITE, ADD_CULTURE_1_OTHER_SITE,
--      ADD_CULTURE_2_OTHER_SITE.
--   2. BMIRD_Multi_Value_field extra rows pivoted into wide columns
--      (~14 cols):
--      UNDERLYING_CONDITION_2..8 (7), NON_STERILE_SITE_2..3 (2),
--      ADD_CULTURE_1_SITE_2..3 (2), ADD_CULTURE_2_SITE_1..3 (3),
--      TYPE_INFECTION_OTHERS_CONCAT (1), STERILE_SITE_OTHERS_CONCAT (1).
--   3. ANTIMICROBIAL batch-entry rows -> Antimicrobial pivot (3 drugs ->
--      15 cols ANTIMICROBIAL_AGENT_TESTED_1..3 + SUSCEPTABILITY_METHOD_1..3
--      + S_I_R_U_RESULT_1..3 + MIC_SIGN_1..3 + MIC_VALUE_1..3).
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
IF NOT EXISTS (SELECT 1 FROM [dbo].[nrt_observation] WHERE observation_uid = 22013100)
BEGIN
    INSERT INTO [dbo].[nrt_observation]
        ([observation_uid], [class_cd], [mood_cd], [cd], [cd_desc_txt],
         [record_status_cd], [obs_domain_cd_st_1], [version_ctrl_nbr],
         [add_user_id], [add_time], [last_chg_user_id], [last_chg_time])
    VALUES
        -- ===== BMIRD_Case single-value coded =====
        -- BMD121 BACTERIAL_OTHER_ISOLATED -> 'STAPH AUR' (BM_OTHER_BAC_SP)
        (22013100, N'OBS', N'EVN', N'BMD121', N'Bacterial other isolated',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- BMD269 CASE_REPORT_STATUS -> 'COM' (BM_CRF_STS)
        (22013101, N'OBS', N'EVN', N'BMD269', N'Case report status',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- BMD295 INTBODYSITE -> 'INBODYSITE' (BM_ORG_ISO_S1)
        (22013102, N'OBS', N'EVN', N'BMD295', N'Internal body site',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),

        -- ===== BMIRD_Case single-value text =====
        -- BMD128 OTHER_MALIGNANCY (value_txt)
        (22013110, N'OBS', N'EVN', N'BMD128', N'Other malignancy free text',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- BMD129 ORGAN_TRANSPLANT (value_txt)
        (22013111, N'OBS', N'EVN', N'BMD129', N'Organ transplant free text',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- BMD130 UNDERLYING_CONDITIONS_OTHER (OTHER_PRIOR_ILLNESS_1)
        (22013112, N'OBS', N'EVN', N'BMD130', N'Underlying conditions other (prior illness 1)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- BMD296 OTHILL2
        (22013113, N'OBS', N'EVN', N'BMD296', N'Other prior illness 2',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- BMD297 OTHILL3
        (22013114, N'OBS', N'EVN', N'BMD297', N'Other prior illness 3',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- BMD318 OTH_STREP_PNEUMO1_CULT_SITES (ADD_CULTURE_1_OTHER_SITE)
        (22013115, N'OBS', N'EVN', N'BMD318', N'Other strep pneumo 1 cult site',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- BMD319 OTH_STREP_PNEUMO2_CULT_SITES (ADD_CULTURE_2_OTHER_SITE)
        (22013116, N'OBS', N'EVN', N'BMD319', N'Other strep pneumo 2 cult site',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),

        -- ===== BMIRD_Multi_Value_field extra rows =====
        -- 7 more BMD127 underlying-condition rows (-> UNDERLYING_CONDITION_2..8)
        (22013200, N'OBS', N'EVN', N'BMD127', N'Underlying condition 2', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013201, N'OBS', N'EVN', N'BMD127', N'Underlying condition 3', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013202, N'OBS', N'EVN', N'BMD127', N'Underlying condition 4', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013203, N'OBS', N'EVN', N'BMD127', N'Underlying condition 5', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013204, N'OBS', N'EVN', N'BMD127', N'Underlying condition 6', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013205, N'OBS', N'EVN', N'BMD127', N'Underlying condition 7', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013206, N'OBS', N'EVN', N'BMD127', N'Underlying condition 8', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- 2 more BMD125 non-sterile-site rows (-> NON_STERILE_SITE_2..3)
        (22013210, N'OBS', N'EVN', N'BMD125', N'Non-sterile site 2', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013211, N'OBS', N'EVN', N'BMD125', N'Non-sterile site 3', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- 2 more BMD142 culture-1-site rows (-> ADD_CULTURE_1_SITE_2..3)
        (22013220, N'OBS', N'EVN', N'BMD142', N'Strep pneumo 1 culture site 2', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013221, N'OBS', N'EVN', N'BMD142', N'Strep pneumo 1 culture site 3', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- 3 BMD144 culture-2-site rows (-> ADD_CULTURE_2_SITE_1..3)
        (22013230, N'OBS', N'EVN', N'BMD144', N'Strep pneumo 2 culture site 1', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013231, N'OBS', N'EVN', N'BMD144', N'Strep pneumo 2 culture site 2', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013232, N'OBS', N'EVN', N'BMD144', N'Strep pneumo 2 culture site 3', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- 1 BMD118 "other" infection type (-> TYPE_INFECTION_OTHERS_CONCAT)
        (22013240, N'OBS', N'EVN', N'BMD118', N'Types of infections other', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- 1 BMD122 "other" sterile site (-> STERILE_SITE_OTHERS_CONCAT)
        (22013250, N'OBS', N'EVN', N'BMD122', N'Sterile site other', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),

        -- ===== Antimicrobial batch-entry: 3 drugs x 5 branches =====
        -- Each drug = one root container observation; 5 child observations
        -- per drug provide the BMD212-216 answers.
        -- PENICILLIN root + branches
        (22013300, N'OBS', N'EVN', N'AntimicrobialRoot', N'PENICILLIN antimicrobial test',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013301, N'OBS', N'EVN', N'BMD212', N'Antimicrobial agent tested (PENICILLIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013302, N'OBS', N'EVN', N'BMD213', N'Susceptability method (PENICILLIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013303, N'OBS', N'EVN', N'BMD214', N'S/I/R/U result (PENICILLIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013304, N'OBS', N'EVN', N'BMD215', N'MIC sign (PENICILLIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013305, N'OBS', N'EVN', N'BMD216', N'MIC value (PENICILLIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- VANCOMYCIN root + branches
        (22013310, N'OBS', N'EVN', N'AntimicrobialRoot', N'VANCOMYCIN antimicrobial test',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013311, N'OBS', N'EVN', N'BMD212', N'Antimicrobial agent tested (VANCOMYCIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013312, N'OBS', N'EVN', N'BMD213', N'Susceptability method (VANCOMYCIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013313, N'OBS', N'EVN', N'BMD214', N'S/I/R/U result (VANCOMYCIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013314, N'OBS', N'EVN', N'BMD215', N'MIC sign (VANCOMYCIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013315, N'OBS', N'EVN', N'BMD216', N'MIC value (VANCOMYCIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        -- AMOXICILLIN root + branches
        (22013320, N'OBS', N'EVN', N'AntimicrobialRoot', N'AMOXICILLIN antimicrobial test',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013321, N'OBS', N'EVN', N'BMD212', N'Antimicrobial agent tested (AMOXICILLIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013322, N'OBS', N'EVN', N'BMD213', N'Susceptability method (AMOXICILLIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013323, N'OBS', N'EVN', N'BMD214', N'S/I/R/U result (AMOXICILLIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013324, N'OBS', N'EVN', N'BMD215', N'MIC sign (AMOXICILLIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
        (22013325, N'OBS', N'EVN', N'BMD216', N'MIC value (AMOXICILLIN)',
         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00');
END;
GO

-- =====================================================================
-- nrt_investigation_observation: link each new observation to PHC 22005000.
-- For BMIRD_Case + BMIRD_Multi_Value_field answers, observation_id =
-- branch_id = observation_uid (root_type_cd='PHC' is conventional).
-- For Antimicrobial branches, observation_id = root_uid (the container
-- observation_uid) and branch_id = the child observation_uid.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[nrt_investigation_observation]
               WHERE public_health_case_uid = 22005000 AND branch_id = 22013100)
BEGIN
    INSERT INTO [dbo].[nrt_investigation_observation]
        ([public_health_case_uid], [observation_id], [root_type_cd],
         [branch_id], [branch_type_cd], [batch_id])
    VALUES
        -- BMIRD_Case single-value
        (22005000, 22013100, N'PHC', 22013100, N'InvFrmQ', NULL),
        (22005000, 22013101, N'PHC', 22013101, N'InvFrmQ', NULL),
        (22005000, 22013102, N'PHC', 22013102, N'InvFrmQ', NULL),
        (22005000, 22013110, N'PHC', 22013110, N'InvFrmQ', NULL),
        (22005000, 22013111, N'PHC', 22013111, N'InvFrmQ', NULL),
        (22005000, 22013112, N'PHC', 22013112, N'InvFrmQ', NULL),
        (22005000, 22013113, N'PHC', 22013113, N'InvFrmQ', NULL),
        (22005000, 22013114, N'PHC', 22013114, N'InvFrmQ', NULL),
        (22005000, 22013115, N'PHC', 22013115, N'InvFrmQ', NULL),
        (22005000, 22013116, N'PHC', 22013116, N'InvFrmQ', NULL),
        -- BMIRD_Multi_Value_field
        (22005000, 22013200, N'PHC', 22013200, N'InvFrmQ', NULL),
        (22005000, 22013201, N'PHC', 22013201, N'InvFrmQ', NULL),
        (22005000, 22013202, N'PHC', 22013202, N'InvFrmQ', NULL),
        (22005000, 22013203, N'PHC', 22013203, N'InvFrmQ', NULL),
        (22005000, 22013204, N'PHC', 22013204, N'InvFrmQ', NULL),
        (22005000, 22013205, N'PHC', 22013205, N'InvFrmQ', NULL),
        (22005000, 22013206, N'PHC', 22013206, N'InvFrmQ', NULL),
        (22005000, 22013210, N'PHC', 22013210, N'InvFrmQ', NULL),
        (22005000, 22013211, N'PHC', 22013211, N'InvFrmQ', NULL),
        (22005000, 22013220, N'PHC', 22013220, N'InvFrmQ', NULL),
        (22005000, 22013221, N'PHC', 22013221, N'InvFrmQ', NULL),
        (22005000, 22013230, N'PHC', 22013230, N'InvFrmQ', NULL),
        (22005000, 22013231, N'PHC', 22013231, N'InvFrmQ', NULL),
        (22005000, 22013232, N'PHC', 22013232, N'InvFrmQ', NULL),
        (22005000, 22013240, N'PHC', 22013240, N'InvFrmQ', NULL),
        (22005000, 22013250, N'PHC', 22013250, N'InvFrmQ', NULL),
        -- Antimicrobial: observation_id = root_uid for each child branch.
        -- (SP 040's v_rdb_obs_mapping derives root_observation_uid from
        -- tnio.observation_id.)
        -- PENICILLIN root 22013300
        (22005000, 22013300, N'ANTIBIOTIC', 22013301, N'InvFrmQ', NULL),
        (22005000, 22013300, N'ANTIBIOTIC', 22013302, N'InvFrmQ', NULL),
        (22005000, 22013300, N'ANTIBIOTIC', 22013303, N'InvFrmQ', NULL),
        (22005000, 22013300, N'ANTIBIOTIC', 22013304, N'InvFrmQ', NULL),
        (22005000, 22013300, N'ANTIBIOTIC', 22013305, N'InvFrmQ', NULL),
        -- VANCOMYCIN root 22013310
        (22005000, 22013310, N'ANTIBIOTIC', 22013311, N'InvFrmQ', NULL),
        (22005000, 22013310, N'ANTIBIOTIC', 22013312, N'InvFrmQ', NULL),
        (22005000, 22013310, N'ANTIBIOTIC', 22013313, N'InvFrmQ', NULL),
        (22005000, 22013310, N'ANTIBIOTIC', 22013314, N'InvFrmQ', NULL),
        (22005000, 22013310, N'ANTIBIOTIC', 22013315, N'InvFrmQ', NULL),
        -- AMOXICILLIN root 22013320
        (22005000, 22013320, N'ANTIBIOTIC', 22013321, N'InvFrmQ', NULL),
        (22005000, 22013320, N'ANTIBIOTIC', 22013322, N'InvFrmQ', NULL),
        (22005000, 22013320, N'ANTIBIOTIC', 22013323, N'InvFrmQ', NULL),
        (22005000, 22013320, N'ANTIBIOTIC', 22013324, N'InvFrmQ', NULL),
        (22005000, 22013320, N'ANTIBIOTIC', 22013325, N'InvFrmQ', NULL);
END;
GO

-- =====================================================================
-- nrt_observation_coded: coded answers. Codes verified against
-- nrt_srte_Code_value_general for each unique_cd's codeset.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[nrt_observation_coded] WHERE observation_uid = 22013100)
BEGIN
    INSERT INTO [dbo].[nrt_observation_coded]
        ([observation_uid], [ovc_code], [batch_id])
    VALUES
        -- BMD121 BACTERIAL_OTHER_ISOLATED (BM_OTHER_BAC_SP -> Staphylococcus aureus)
        (22013100, N'STAPH AUR', NULL),
        -- BMD269 CASE_REPORT_STATUS (BM_CRF_STS -> 'Complete')
        (22013101, N'COM', NULL),
        -- BMD295 INTBODYSITE (BM_ORG_ISO_S1 -> Internal body site)
        (22013102, N'INBODYSITE', NULL),

        -- BMD127 additional UNDERLYING_CONDITION rows (distinct codes -> distinct values)
        (22013200, N'ASTH', NULL),      -- Asthma
        (22013201, N'CHF', NULL),       -- Heart Failure/CHF
        (22013202, N'COCIMP', NULL),    -- Cochlear implant
        (22013203, N'EMP', NULL),       -- Emphysema/COPD
        (22013204, N'HODK', NULL),      -- Hodgkin's Disease
        (22013205, N'LEUK', NULL),      -- Leukemia
        (22013206, N'SPLEN', NULL),     -- Splenectomy/Asplenia

        -- BMD125 additional non-sterile sites
        (22013210, N'MIDDLEAR', NULL),  -- Middle ear
        (22013211, N'WOUND', NULL),     -- Wound

        -- BMD142 additional culture-1 sites (codeset BM_ORG_ISO_S1)
        (22013220, N'BONE', NULL),      -- Bone
        (22013221, N'CSF', NULL),       -- Cerebral Spinal Fluid

        -- BMD144 culture-2 sites
        (22013230, N'BLOOD', NULL),     -- Blood
        (22013231, N'JOINT', NULL),     -- Joint
        (22013232, N'PLEURAL', NULL),   -- Pleural Fluid

        -- BMD118 extra "other" infection type (mark=0 path -> TYPE_INFECTION_OTHERS_CONCAT)
        (22013240, N'OSTEOMYE', NULL),  -- Osteomyelitis (not in the SP whitelist)

        -- BMD122 extra "other" sterile site (mark=0 path -> STERILE_SITE_OTHERS_CONCAT)
        (22013250, N'BONE', NULL),      -- Bone (BM_ORG_ISO_S1; not in SP whitelist of BMD122)

        -- Antimicrobial coded answers (BMD212 agent, BMD213 method, BMD214 SIR, BMD215 sign)
        -- PENICILLIN
        (22013301, N'PENICILLIN', NULL),  -- BMD212 ANTIMICROBIAL_AGENT_TESTED_IND
        (22013302, N'A', NULL),           -- BMD213 SUSCEPTABILITY_METHOD -> AGAR (BM_SUSC_MT)
        (22013303, N'R', NULL),           -- BMD214 S_I_R_U_RESULT -> Resistant (LAB_SENS_RSLT_Q)
        (22013304, N'LE', NULL),          -- BMD215 MIC_SIGN -> <= (BM_ORG_SIGN)
        -- VANCOMYCIN
        (22013311, N'VANCOMYCIN', NULL),
        (22013312, N'B', NULL),           -- BROTH
        (22013313, N'SUS', NULL),         -- Susceptible
        (22013314, N'EQ', NULL),          -- =
        -- AMOXICILLIN
        (22013321, N'AMOXICILLIN', NULL),
        (22013322, N'D', NULL),           -- DISK (KB)
        (22013323, N'I', NULL),           -- Intermediate
        (22013324, N'GT', NULL);          -- >
END;
GO

-- =====================================================================
-- nrt_observation_txt: text answer values (ovt_seq=1 — v_getobstxt filter).
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[nrt_observation_txt] WHERE observation_uid = 22013110)
BEGIN
    INSERT INTO [dbo].[nrt_observation_txt]
        ([observation_uid], [ovt_seq], [ovt_value_txt], [batch_id])
    VALUES
        (22013110, 1, N'Lung carcinoma — Stage IIIA', NULL),                      -- BMD128 OTHER_MALIGNANCY
        (22013111, 1, N'Renal transplant 2023-08; on tacrolimus', NULL),          -- BMD129 ORGAN_TRANSPLANT
        (22013112, 1, N'Chronic bronchitis with recurrent exacerbations', NULL), -- BMD130 OTHER_PRIOR_ILLNESS_1
        (22013113, 1, N'Rheumatoid arthritis on infliximab', NULL),               -- BMD296 OTHILL2
        (22013114, 1, N'Crohn disease on azathioprine', NULL),                    -- BMD297 OTHILL3
        (22013115, 1, N'Bronchial aspirate (specify)', NULL),                     -- BMD318 ADD_CULTURE_1_OTHER_SITE
        (22013116, 1, N'Peri-prosthetic joint fluid (specify)', NULL);            -- BMD319 ADD_CULTURE_2_OTHER_SITE
END;
GO

-- =====================================================================
-- nrt_observation_numeric: MIC numeric values for the 3 antimicrobial drugs
-- (ovn_seq=1 — v_getobsnum filter).
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[nrt_observation_numeric] WHERE observation_uid = 22013305)
BEGIN
    INSERT INTO [dbo].[nrt_observation_numeric]
        ([observation_uid], [ovn_seq], [ovn_numeric_value_1], [batch_id])
    VALUES
        (22013305, 1, 4.000, NULL),    -- PENICILLIN MIC <= 4.0
        (22013315, 1, 0.500, NULL),    -- VANCOMYCIN  MIC = 0.5
        (22013325, 1, 32.000, NULL);   -- AMOXICILLIN MIC > 32
END;
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
