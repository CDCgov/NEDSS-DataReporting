-- =====================================================================
-- Round 5 inc-wave-2 (NO-SHORTCUT) — BMIRD antimicrobial batch-entry
-- observation graph (ODSE-only). Fills the ~41 ANTIMICROBIAL_*/MIC_*/
-- SUSCEPTABILITY_*/S_I_R_U_RESULT_*/ANTIMIC_GT_8_* columns of
-- dbo.bmird_strep_pneumo_datamart for BMIRD Strep pneumo PHC 22005000.
--
-- These were explicitly DEFERRED by zz_bmird_fill.sql ("antimicrobial
-- batch-entry root-observation + branch_id graph BMD212-216; reserve
-- 22005200-22005299"). This fixture authors that graph in UID block
-- 22061000-22061999.
--
-- HOW THE COLUMNS POPULATE (proven from routines 040 + 140 + view 010,
-- 2026-06-04):
--   sp_bmird_strep_pneumo_datamart_postprocessing (routine 140) joins
--   dbo.ANTIMICROBIAL a ON bc.ANTIMICROBIAL_GRP_KEY = a.ANTIMICROBIAL_GRP_KEY
--   WHERE a.ANTIMICROBIAL_GRP_KEY <> 1, splits PENICILLIN (SORT_ORDER 1)
--   vs everything-else (SORT_ORDER 9), ROW_NUMBER()s them into COUNTER,
--   pivots COUNTER 1..8 into the *_1.._8 columns and STRING_AGGs COUNTER>8
--   into ANTIMIC_GT_8_AGENT_AND_RESULT.
--
--   dbo.ANTIMICROBIAL is built by sp_bmird_case_datamart_postprocessing
--   (routine 040). It reads dbo.v_rdb_obs_mapping (view 010) filtered to
--   RDB_table='Antimicrobial', which exposes per InvFrmQ observation:
--       public_health_case_uid, unique_cd, root_observation_uid (=root_uid),
--       branch_id, coded/numeric response.
--   IMRDBMapping (RDB_MODERN.dbo.nrt_srte_IMRDBMapping) maps:
--       BMD212 ANTIMICROBIAL_AGENT_TESTED_IND  code
--       BMD213 SUSCEPTABILITY_METHOD           code
--       BMD214 S_I_R_U_RESULT                  code
--       BMD215 MIC_SIGN                         code
--       BMD216 MIC_VALUE                        numeric_value_1
--   Routine 040 then pivots one ANTIMICROBIAL row PER DISTINCT root_uid
--   (selection_number = root_uid), joining the BMD212..216 branch answers
--   that share that root. So: one drug = one root observation; its five
--   BMD212..216 answers = five branch observations sharing that root.
--   The ANTIMICROBIAL_GRP_KEY is auto-assigned (>1) by routine 040 once
--   any antimicrobial obs exist for the PHC (nrt_antimicrobial_group_key
--   .ANTIMICROBIAL_GRP_KEY is IDENTITY) — exactly like the multi-value
--   grp key zz_bmird_fill already produced (=2). No grp-key management here.
--
-- HOW THE OBS GRAPH MAPS TO root_uid/branch_id (routine 056
-- sp_investigation_event, JSON consumer ProcessInvestigationDataUtil):
--   For each act_relationship 'act' with target_act_uid = PHC:
--     branch = act_relationship where branch.target_act_uid = act.source_act_uid
--     root   = act_relationship where root.source_act_uid = branch.source_act_uid
--              AND root.type_cd = 'ItemToRow'
--     observation_id (root_uid) = COALESCE(root.target_act_uid, branch.target_act_uid)
--     branch_id      (branch_uid) = branch.source_act_uid
--     branch_type_cd               = branch.type_cd
--   => Each BMD212..216 branch obs gets:
--       (a) an InvFrmQ act_relationship: target = our antimicrobial form
--           observation 22061000, source = the branch obs  (branch.type_cd='InvFrmQ')
--       (b) an ItemToRow act_relationship: source = the branch obs,
--           target = the drug ROOT observation
--   so all five branches of one drug resolve to observation_id = that
--   drug's root, distinct per drug. (zz_bmird_fill's direct questions have
--   NO ItemToRow, so they all collapse to observation_id = the form — that
--   is why they are direct BMIRD_Case cols, not per-row antimicrobial rows.)
--
-- SELF-CONTAINED ORDERING: globbed *.sql runs alphabetically, so
--   zz_bmird_antimicrobial.sql executes BEFORE zz_bmird_fill.sql. We
--   therefore author our OWN antimicrobial form observation (22061000) +
--   its PHCInvForm link — we do NOT reuse zz_bmird_fill's L1 form 22048001.
--   Multiple InvFrmQ forms per PHC are fine; v_getobscode keys on branch_id.
--
-- DRUGS AUTHORED (9 → fills all 8 slots + the GT_8 overflow = 41 cols):
--   selection roots 22061010/020/.../090. Drug 1 = PENICILLIN (SORT_ORDER 1
--   => COUNTER 1 => slot 1). Drugs 2..9 = eight other agents (SORT_ORDER 9
--   => COUNTER 2..9). COUNTER 2..8 fill slots 2..8; COUNTER 9 (>8) feeds
--   ANTIMIC_GT_8_AGENT_AND_RESULT.
--   Agent codes (RDB_MODERN BM_ANTI_AGENT, response = code_short_desc_txt):
--     C0220892 PENICILLIN, C0002645 AMOXICILLIN, C0007554 CEFOTAXIME,
--     C0007561 CEFTRIAXONE, C0008947 CLINDAMYCIN, C0014806 ERYTHROMYCIN,
--     C0042313 VANCOMYCIN, C0052796 AZITHROMYCIN, C0663241 LINEZOLID.
--   BMD213 BM_SUSC_MT (B=BROTH), BMD214 LAB_SENS_RSLT_Q (R=Resistant,
--     SUS=Susceptible, I=Intermediate), BMD215 BM_ORG_SIGN (LE='<=',
--     EQ='='), BMD216 numeric MIC_VALUE.
--
-- ODSE-ONLY: no nrt_* INSERTs, no EXEC sp_*, no seed/SRTE/liquibase edits.
--   Additive (new UID-block entities only); no UPDATE of shared dims.
--   PHC 22005000 already in scripts/merge_and_verify.sh PHC_UIDS and both
--   sp_bmird_case_datamart_postprocessing + sp_bmird_strep_pneumo_datamart
--   _postprocessing already target it -> NO harness/ORCH change needed.
--   No GENERATED ALWAYS period cols inserted. Idempotent (guarded on the
--   antimicrobial form obs 22061000 not yet existing).
--
-- UID block 22061000-22061999 (reserved in catalog/uid_ranges.md):
--   22061000               antimicrobial InvFrmQ form observation
--   22061010..22061090     per-drug ROOT observations (step 10)
--   22061011..22061015     drug-1 branch obs BMD212..216 (PENICILLIN)
--   22061021..22061025     drug-2 branches ... 22061091..22061095 drug-9
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @ts   datetime = '2026-04-01T00:00:00';
DECLARE @phc_uid bigint = 22005000;   -- existing BMIRD Strep pneumo PHC
DECLARE @form_uid bigint = 22061000;  -- our antimicrobial InvFrmQ form obs

IF NOT EXISTS (SELECT 1 FROM [dbo].[Observation] WHERE observation_uid = @form_uid)
   AND EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @phc_uid)
BEGIN

    -- ----- antimicrobial form observation (InvFrmQ target / PHCInvForm source) -----
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@form_uid, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation]
        ([observation_uid],[cd],[cd_system_cd],[group_level_cd],[local_id],[obs_domain_cd],
         [status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr])
    VALUES
        (@form_uid, N'INV_FORM_BMDSP', N'NBS', N'L1', N'OBS22061000GA01', N'CLN',
         N'A', @ts, @phc_uid, N'T', 1);

    -- =================================================================
    -- Per-drug ROOT observations (one per ANTIMICROBIAL row / slot).
    -- These are the ItemToRow targets; they carry no answer themselves.
    -- =================================================================
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd])
    SELECT v.r, N'OBS', N'EVN'
    FROM (VALUES (22061010),(22061020),(22061030),(22061040),(22061050),
                 (22061060),(22061070),(22061080),(22061090)) AS v(r);
    INSERT INTO [dbo].[Observation]
        ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],
         [program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr])
    SELECT v.r, N'BMD_ANTIMICRO_ROW', N'NBS',
           N'OBS' + CAST(v.r AS varchar(20)) + N'GA01', N'A', @ts, @phc_uid, N'T', 1
    FROM (VALUES (22061010),(22061020),(22061030),(22061040),(22061050),
                 (22061060),(22061070),(22061080),(22061090)) AS v(r);

    -- =================================================================
    -- Branch observations: BMD212..216 for each drug. Each is an
    -- act(OBS)+Observation(cd=BMDnnn)+Obs_value_coded/numeric answer.
    -- root = root_uid + offset: 212->+1, 213->+2, 214->+3, 215->+4, 216->+5.
    -- =================================================================

    -- ---- coded branches (BMD212/213/214/215): Obs_value_coded.code ----
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd])
    SELECT v.u, N'OBS', N'EVN'
    FROM (VALUES
        -- drug 1 PENICILLIN
        (22061011),(22061012),(22061013),(22061014),
        -- drug 2 AMOXICILLIN
        (22061021),(22061022),(22061023),(22061024),
        -- drug 3 CEFOTAXIME
        (22061031),(22061032),(22061033),(22061034),
        -- drug 4 CEFTRIAXONE
        (22061041),(22061042),(22061043),(22061044),
        -- drug 5 CLINDAMYCIN
        (22061051),(22061052),(22061053),(22061054),
        -- drug 6 ERYTHROMYCIN
        (22061061),(22061062),(22061063),(22061064),
        -- drug 7 VANCOMYCIN
        (22061071),(22061072),(22061073),(22061074),
        -- drug 8 AZITHROMYCIN
        (22061081),(22061082),(22061083),(22061084),
        -- drug 9 LINEZOLID (-> COUNTER 9 -> ANTIMIC_GT_8)
        (22061091),(22061092),(22061093),(22061094)
    ) AS v(u);

    INSERT INTO [dbo].[Observation]
        ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],
         [program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr])
    SELECT v.u, v.cd, N'NBS',
           N'OBS' + CAST(v.u AS varchar(20)) + N'GA01', N'A', @ts, @phc_uid, N'T', 1
    FROM (VALUES
        (22061011,N'BMD212'),(22061012,N'BMD213'),(22061013,N'BMD214'),(22061014,N'BMD215'),
        (22061021,N'BMD212'),(22061022,N'BMD213'),(22061023,N'BMD214'),(22061024,N'BMD215'),
        (22061031,N'BMD212'),(22061032,N'BMD213'),(22061033,N'BMD214'),(22061034,N'BMD215'),
        (22061041,N'BMD212'),(22061042,N'BMD213'),(22061043,N'BMD214'),(22061044,N'BMD215'),
        (22061051,N'BMD212'),(22061052,N'BMD213'),(22061053,N'BMD214'),(22061054,N'BMD215'),
        (22061061,N'BMD212'),(22061062,N'BMD213'),(22061063,N'BMD214'),(22061064,N'BMD215'),
        (22061071,N'BMD212'),(22061072,N'BMD213'),(22061073,N'BMD214'),(22061074,N'BMD215'),
        (22061081,N'BMD212'),(22061082,N'BMD213'),(22061083,N'BMD214'),(22061084,N'BMD215'),
        (22061091,N'BMD212'),(22061092,N'BMD213'),(22061093,N'BMD214'),(22061094,N'BMD215')
    ) AS v(u,cd);

    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code])
    SELECT v.u, v.code FROM (VALUES
        -- drug 1 PENICILLIN: BROTH / Resistant / <=
        (22061011,N'C0220892'),(22061012,N'B'),(22061013,N'R'),(22061014,N'LE'),
        -- drug 2 AMOXICILLIN: BROTH / Susceptible / =
        (22061021,N'C0002645'),(22061022,N'B'),(22061023,N'SUS'),(22061024,N'EQ'),
        -- drug 3 CEFOTAXIME
        (22061031,N'C0007554'),(22061032,N'B'),(22061033,N'SUS'),(22061034,N'LE'),
        -- drug 4 CEFTRIAXONE
        (22061041,N'C0007561'),(22061042,N'B'),(22061043,N'I'),(22061044,N'EQ'),
        -- drug 5 CLINDAMYCIN
        (22061051,N'C0008947'),(22061052,N'A'),(22061053,N'R'),(22061054,N'GE'),
        -- drug 6 ERYTHROMYCIN
        (22061061,N'C0014806'),(22061062,N'D'),(22061063,N'R'),(22061064,N'GT'),
        -- drug 7 VANCOMYCIN
        (22061071,N'C0042313'),(22061072,N'B'),(22061073,N'SUS'),(22061074,N'LE'),
        -- drug 8 AZITHROMYCIN
        (22061081,N'C0052796'),(22061082,N'B'),(22061083,N'I'),(22061084,N'LT'),
        -- drug 9 LINEZOLID
        (22061091,N'C0663241'),(22061092,N'B'),(22061093,N'SUS'),(22061094,N'EQ')
    ) AS v(u,code);

    -- ---- numeric branch (BMD216 MIC_VALUE): Obs_value_numeric.numeric_value_1 ----
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd])
    SELECT v.u, N'OBS', N'EVN'
    FROM (VALUES (22061015),(22061025),(22061035),(22061045),(22061055),
                 (22061065),(22061075),(22061085),(22061095)) AS v(u);

    INSERT INTO [dbo].[Observation]
        ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],
         [program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr])
    SELECT v.u, N'BMD216', N'NBS',
           N'OBS' + CAST(v.u AS varchar(20)) + N'GA01', N'A', @ts, @phc_uid, N'T', 1
    FROM (VALUES (22061015),(22061025),(22061035),(22061045),(22061055),
                 (22061065),(22061075),(22061085),(22061095)) AS v(u);

    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1])
    SELECT v.u, 1, v.val, 1 FROM (VALUES
        (22061015, CAST(2.00 AS numeric(15,5))),
        (22061025, CAST(0.50 AS numeric(15,5))),
        (22061035, CAST(0.25 AS numeric(15,5))),
        (22061045, CAST(1.00 AS numeric(15,5))),
        (22061055, CAST(4.00 AS numeric(15,5))),
        (22061065, CAST(8.00 AS numeric(15,5))),
        (22061075, CAST(0.50 AS numeric(15,5))),
        (22061085, CAST(0.12 AS numeric(15,5))),
        (22061095, CAST(1.00 AS numeric(15,5)))
    ) AS v(u,val);

    -- =================================================================
    -- InvFrmQ act_relationships: target = antimicrobial form 22061000,
    -- source = each BMD212..216 branch obs. (-> branch_type_cd='InvFrmQ',
    -- branch_id = the branch obs.)
    -- =================================================================
    INSERT INTO [dbo].[Act_relationship]
        ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],
         [record_status_cd],[record_status_time],[source_class_cd],[status_cd],
         [status_time],[target_class_cd],[type_desc_txt])
    SELECT @form_uid, q.src, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts,
           N'OBS', N'Investigation Form Question'
    FROM (VALUES
        (22061011),(22061012),(22061013),(22061014),(22061015),
        (22061021),(22061022),(22061023),(22061024),(22061025),
        (22061031),(22061032),(22061033),(22061034),(22061035),
        (22061041),(22061042),(22061043),(22061044),(22061045),
        (22061051),(22061052),(22061053),(22061054),(22061055),
        (22061061),(22061062),(22061063),(22061064),(22061065),
        (22061071),(22061072),(22061073),(22061074),(22061075),
        (22061081),(22061082),(22061083),(22061084),(22061085),
        (22061091),(22061092),(22061093),(22061094),(22061095)
    ) AS q(src);

    -- =================================================================
    -- ItemToRow act_relationships: source = each branch obs, target = the
    -- drug ROOT obs. (routine 056: root.source_act_uid = branch.source_act_uid
    -- AND root.type_cd='ItemToRow' -> observation_id = root.target_act_uid.)
    -- Each drug's 5 branches all point at the same root.
    -- =================================================================
    INSERT INTO [dbo].[Act_relationship]
        ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],
         [record_status_cd],[record_status_time],[source_class_cd],[status_cd],
         [status_time],[target_class_cd],[type_desc_txt])
    SELECT v.root, v.branch, N'ItemToRow', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts,
           N'OBS', N'Item To Row'
    FROM (VALUES
        (22061010,22061011),(22061010,22061012),(22061010,22061013),(22061010,22061014),(22061010,22061015),
        (22061020,22061021),(22061020,22061022),(22061020,22061023),(22061020,22061024),(22061020,22061025),
        (22061030,22061031),(22061030,22061032),(22061030,22061033),(22061030,22061034),(22061030,22061035),
        (22061040,22061041),(22061040,22061042),(22061040,22061043),(22061040,22061044),(22061040,22061045),
        (22061050,22061051),(22061050,22061052),(22061050,22061053),(22061050,22061054),(22061050,22061055),
        (22061060,22061061),(22061060,22061062),(22061060,22061063),(22061060,22061064),(22061060,22061065),
        (22061070,22061071),(22061070,22061072),(22061070,22061073),(22061070,22061074),(22061070,22061075),
        (22061080,22061081),(22061080,22061082),(22061080,22061083),(22061080,22061084),(22061080,22061085),
        (22061090,22061091),(22061090,22061092),(22061090,22061093),(22061090,22061094),(22061090,22061095)
    ) AS v(root,branch);

    -- PHCInvForm: target = PHC, source = antimicrobial form obs. Wires the
    -- form (and thus all its InvFrmQ branches) to public_health_case 22005000.
    INSERT INTO [dbo].[Act_relationship]
        ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],
         [record_status_cd],[record_status_time],[source_class_cd],[status_cd],
         [status_time],[target_class_cd],[type_desc_txt])
    VALUES
        (@phc_uid, @form_uid, N'PHCInvForm', @ts, CAST(GETDATE() AS DATE), N'ACTIVE', @ts, N'OBS', N'A',
         @ts, N'CASE', N'PHC Investigation Form');
END;
GO

-- Bump last_chg_time so CDC re-emits the investigation and the service
-- re-runs sp_investigation_event, building nrt_investigation_observation
-- with InvFrmQ branches + ItemToRow roots for this PHC; Step-9 then rebuilds
-- ANTIMICROBIAL, BMIRD_CASE, and bmird_strep_pneumo_datamart for 22005000.
UPDATE [NBS_ODSE].[dbo].[public_health_case]
   SET [last_chg_time] = SYSDATETIME()
 WHERE public_health_case_uid = 22005000;
GO
