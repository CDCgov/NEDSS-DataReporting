USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 2 link fixture: Vaccination cross-subject edges (nbs_act_entity).
--   Edge type 1: 'SubOfVacc'        (Vaccination -> Patient subject)
--   Edge type 2: 'PerformerOfVacc'  (Vaccination -> Provider performer)
--
-- Both edge types live on dbo.nbs_act_entity (NOT participation, NOT
-- act_relationship). This is the FIRST nbs_act_entity edge in Tier 2
-- (prior 7 Tier 2 edges used participation or act_relationship). Two
-- key differences:
--   1. nbs_act_entity has a surrogate UID column (nbs_act_entity_uid
--      bigint NOT NULL) -- we allocate 4 UIDs from this agent's block
--      21007000-21007999. (Prior edges used composite PKs and did not
--      need surrogate UIDs.)
--   2. The Vaccination event SP filters on TYPE_CD='SubOfVacc' as an
--      INNER-style filter at line 108 of
--      071-sp_vaccination_event-001.sql. Without our SubOfVacc rows,
--      sp_vaccination_event returns 0 rows at Tier 1 isolation
--      (documented in coverage_vaccination.md as the LINK_REQUIRED
--      entry at the bottom). Our edge directly unblocks the event SP.
--
-- Wires (4 nbs_act_entity rows total):
--   SubOfVacc (Vaccination act -> Patient entity):
--     1) (21007000) foundation Vaccination 20000160 -> foundation Patient 20000000
--     2) (21007001) v2 Vaccination         20110010 -> v2 Patient         20020010
--   PerformerOfVacc (Vaccination act -> Provider entity):
--     3) (21007002) foundation Vaccination 20000160 -> foundation Provider 20000010
--     4) (21007003) v2 Vaccination         20110010 -> v2 Provider         20010010
--
-- Catalog citations (catalog/edge_types.md, dbo.nbs_act_entity rows):
--   * 'SubOfVacc' (Act endpoint=Intervention/INTV, Entity endpoint=Person/PAT)
--     - Used By: sp_vaccination_event.
--     - SP filter sites:
--       - 071-sp_vaccination_event-001.sql:108 (main FROM clause INNER
--         JOIN; INTERVENTION_UID -> NBS_ACT_ENTITY.ACT_UID with
--         TYPE_CD='SubOfVacc'; this is the gating filter that returns
--         zero rows pre-edge).
--       - 071-...:1156 (PAT_INFO CTE, INNER JOIN on NBS_ACT_ENTITY
--         where TYPE_CD='SubOfVacc' to project PATIENT_UID into the
--         JSON payload).
--     - SRTE PAR_TYPE: present (act_class_cd='INTV',
--       subject_class_cd='PAT', type_desc_txt='Subject of Vaccination').
--   * 'PerformerOfVacc' (Act endpoint=Intervention/INTV,
--                        Entity endpoint=Person/PSN or Organization/ORG)
--     - Used By: sp_vaccination_event.
--     - SP filter sites:
--       - 071-...:1135 (PROVIDER_INFO CTE, INNER JOIN on NBS_ACT_ENTITY
--         where TYPE_CD='PerformerOfVacc' AND inner join Person -> projects
--         PROVIDER_UID).
--       - 071-...:1146 (ORG_INFO CTE, INNER JOIN on NBS_ACT_ENTITY where
--         TYPE_CD='PerformerOfVacc' AND inner join Organization ->
--         projects ORGANIZATION_UID).
--     - SRTE PAR_TYPE: present (two rows -- one for INTV/PSN
--       'Vaccination Administration Provider' and one for INTV/ORG
--       'Vaccination Administration Facility').
--
-- Honest coverage assessment (per the per-edge prompt's guidance):
--   - At Tier 1 isolation, the event SP returns 0 rows because the
--     SubOfVacc INNER JOIN at line 108 finds no matches. After this
--     edge applies, the event SP should project 2 rows (one per
--     vaccination UID), and the JSON payload's PATIENT_UID and
--     PROVIDER_UID fields will be populated for both vaccinations.
--   - The event SP's JSON output is consumed by Kafka in production
--     but is not consumed by our local fixture flow's postprocessing
--     SPs. The d_vaccination / f_vaccination postprocessing SPs read
--     directly from nrt_vaccination (hand-authored by Tier 1) and do
--     NOT traverse nbs_act_entity. So the D_VACCINATION /
--     F_VACCINATION column values are unchanged post-edge:
--       * D_VACCINATION still 21/21 columns populated for both rows
--         (foundation null path + v2 populated path).
--       * F_VACCINATION still 6/6 columns populated. The 4 cross-
--         subject FK columns (PATIENT_KEY, VACCINE_GIVEN_BY_KEY,
--         VACCINE_GIVEN_BY_ORG_KEY, INVESTIGATION_KEY) remain at
--         sentinel 1 at Tier 1 isolation -- they only flip to
--         non-sentinel keys after the upstream subjects' chains have
--         populated D_PATIENT / D_PROVIDER / D_ORGANIZATION /
--         INVESTIGATION (which they have, since the verification
--         recipe re-runs Patient and Provider chains pre-edge). So
--         post-edge, F_VACCINATION's PATIENT_KEY / VACCINE_GIVEN_BY_KEY
--         resolve to the real D_PATIENT / D_PROVIDER keys when
--         f_vaccination_postprocessing is re-run after the edge --
--         BUT this is unrelated to nbs_act_entity (it's solely driven
--         by D_PATIENT / D_PROVIDER having rows for the soft-ref
--         patient_uid/provider_uid in nrt_vaccination, which were
--         hand-authored by Tier 1 and resolve through Patient/Provider
--         dimensions).
--   - The PRIMARY value of this edge is: (a) unblocking the event SP's
--     JSON projection (Kafka consumer in prod), (b) ODSE graph
--     correctness for the RDB-vs-RDB_MODERN comparison test against
--     MasterETL.
--
-- UID block (Tier 2 - eighth agent): 21007000 - 21007999.
-- This fixture authors NO new entity / Person / Organization /
-- Intervention / Act rows; it only writes 4 rows to dbo.nbs_act_entity
-- (each row consuming one surrogate UID from the allocated block).
--
-- Forbidden in Tier 2 (per template):
--   - No new ODSE entity rows; no SRTE writes; no foundation/Tier 1
--     modifications; no INSERTs into RDB_MODERN dim/fact tables; no
--     infrastructure-SP invocation in this fixture (orchestrator owns
--     sp_get_date_dim and sp_nrt_srte_condition_code_postprocessing
--     per Merge contract step 2).
--
-- nbs_act_entity NOT-NULL columns (verified via INFORMATION_SCHEMA.COLUMNS):
--   nbs_act_entity_uid (bigint), act_uid (bigint), add_time (datetime),
--   add_user_id (bigint), entity_uid (bigint),
--   entity_version_ctrl_nbr (smallint), last_chg_time (datetime),
--   last_chg_user_id (bigint), record_status_cd (varchar),
--   record_status_time (datetime).
-- Nullable: type_cd (varchar) -- counter-intuitive but the schema lists
--   it nullable. We populate it explicitly because the SPs filter on it.
--
-- IDENTITY note: nbs_act_entity_uid is an IDENTITY column in the
-- baseline schema (verified via sys.columns.is_identity=1). To insert
-- explicit UIDs from this agent's allocated block, the INSERT must be
-- wrapped in SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF.
-- =====================================================================

-- ----- Sentinel reference (do not allocate -- assumed by all fixtures) -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Cross-tier UIDs referenced (read-only) -----
DECLARE @foundation_act_vaccination_uid  bigint = 20000160;  -- foundation Vaccination act_uid / intervention_uid
DECLARE @foundation_entity_patient_uid   bigint = 20000000;  -- foundation Patient entity_uid / person_uid
DECLARE @foundation_entity_provider_uid  bigint = 20000010;  -- foundation Provider entity_uid / person_uid
DECLARE @v2_act_vaccination_uid          bigint = 20110010;  -- v2 Vaccination (Vaccination Tier 1)
DECLARE @v2_entity_patient_uid           bigint = 20020010;  -- v2 Patient (Patient Tier 1)
DECLARE @v2_entity_provider_uid          bigint = 20010010;  -- v2 Provider (Provider Tier 1)

-- ----- Surrogate UIDs allocated from this agent's block -----
DECLARE @subofvacc_foundation_uid        bigint = 21007000;  -- nbs_act_entity_uid for SubOfVacc foundation row
DECLARE @subofvacc_v2_uid                bigint = 21007001;  -- nbs_act_entity_uid for SubOfVacc v2 row
DECLARE @performerofvacc_foundation_uid  bigint = 21007002;  -- nbs_act_entity_uid for PerformerOfVacc foundation row
DECLARE @performerofvacc_v2_uid          bigint = 21007003;  -- nbs_act_entity_uid for PerformerOfVacc v2 row

-- =====================================================================
-- nbs_act_entity rows.
--
-- entity_version_ctrl_nbr is set to 1 by NBS convention (smallint;
-- versioning starts at 1 for new rows).
-- record_status_cd='ACTIVE' so any future SP filter on record_status_cd
-- (none currently in sp_vaccination_event but kept for shape parity).
-- type_cd populated explicitly (the SPs filter on it).
-- =====================================================================
SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON;

INSERT INTO [dbo].[nbs_act_entity]
    ([nbs_act_entity_uid], [act_uid], [entity_uid], [type_cd],
     [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    -- Edge 1 (21007000): SubOfVacc, foundation Vaccination -> foundation Patient
    -- Unblocks sp_vaccination_event's main FROM clause INNER JOIN at line 108
    -- (TYPE_CD='SubOfVacc' filter) for the foundation Vaccination UID.
    (@subofvacc_foundation_uid,             -- nbs_act_entity_uid (surrogate)
     @foundation_act_vaccination_uid,       -- act_uid (INTV; foundation Vaccination)
     @foundation_entity_patient_uid,        -- entity_uid (PSN/PAT; foundation Patient)
     N'SubOfVacc',                          -- type_cd (PAR_TYPE 'SubOfVacc' -- in SRTE: INTV/PAT)
     1,                                     -- entity_version_ctrl_nbr (smallint)
     '2026-04-01T00:00:00',                 -- add_time
     @superuser_id,                         -- add_user_id
     CAST(GETDATE() AS DATE),                 -- last_chg_time
     @superuser_id,                         -- last_chg_user_id
     N'ACTIVE',                             -- record_status_cd
     '2026-04-01T00:00:00'),                -- record_status_time
    -- Edge 2 (21007001): SubOfVacc, v2 Vaccination -> v2 Patient
    -- Unblocks the same INNER JOIN for the v2 Vaccination UID.
    (@subofvacc_v2_uid,                     -- nbs_act_entity_uid
     @v2_act_vaccination_uid,               -- act_uid (INTV; v2 Vaccination)
     @v2_entity_patient_uid,                -- entity_uid (PSN/PAT; v2 Patient)
     N'SubOfVacc',                          -- type_cd
     1,                                     -- entity_version_ctrl_nbr
     '2026-04-15T10:00:00',                 -- add_time
     @superuser_id,                         -- add_user_id
     CAST(GETDATE() AS DATE),                 -- last_chg_time
     @superuser_id,                         -- last_chg_user_id
     N'ACTIVE',                             -- record_status_cd
     '2026-04-15T10:00:00'),                -- record_status_time
    -- Edge 3 (21007002): PerformerOfVacc, foundation Vaccination -> foundation Provider
    -- Drives the PROVIDER_INFO CTE (sp_vaccination_event line 1135)
    -- INNER JOIN on NBS_ACT_ENTITY.TYPE_CD='PerformerOfVacc' joining
    -- to Person -> PROVIDER_UID projection. (Foundation Provider has
    -- person.cd='PRV' / class_cd='PSN' from foundation fixture.)
    (@performerofvacc_foundation_uid,       -- nbs_act_entity_uid
     @foundation_act_vaccination_uid,       -- act_uid (INTV; foundation Vaccination)
     @foundation_entity_provider_uid,       -- entity_uid (PSN/PRV; foundation Provider)
     N'PerformerOfVacc',                    -- type_cd (PAR_TYPE 'PerformerOfVacc' -- INTV/PSN in SRTE)
     1,                                     -- entity_version_ctrl_nbr
     '2026-04-01T00:00:00',                 -- add_time
     @superuser_id,                         -- add_user_id
     CAST(GETDATE() AS DATE),                 -- last_chg_time
     @superuser_id,                         -- last_chg_user_id
     N'ACTIVE',                             -- record_status_cd
     '2026-04-01T00:00:00'),                -- record_status_time
    -- Edge 4 (21007003): PerformerOfVacc, v2 Vaccination -> v2 Provider
    -- Same PROVIDER_INFO CTE for v2.
    (@performerofvacc_v2_uid,               -- nbs_act_entity_uid
     @v2_act_vaccination_uid,               -- act_uid (INTV; v2 Vaccination)
     @v2_entity_provider_uid,               -- entity_uid (PSN/PRV; v2 Provider)
     N'PerformerOfVacc',                    -- type_cd
     1,                                     -- entity_version_ctrl_nbr
     '2026-04-15T10:00:00',                 -- add_time
     @superuser_id,                         -- add_user_id
     CAST(GETDATE() AS DATE),                 -- last_chg_time
     @superuser_id,                         -- last_chg_user_id
     N'ACTIVE',                             -- record_status_cd
     '2026-04-15T10:00:00');                -- record_status_time

SET IDENTITY_INSERT [dbo].[nbs_act_entity] OFF;
GO

-- =====================================================================
-- Post-edge SP re-run.
--
-- The event SP (sp_vaccination_event) is the primary verification
-- target: pre-edge it returns 0 rows due to the SubOfVacc INNER JOIN
-- gating at line 108; post-edge it should return 2 rows (one per
-- vaccination UID) with PATIENT_UID and PROVIDER_UID JSON fields
-- populated from the PAT_INFO and PROVIDER_INFO CTEs at lines
-- 1150-1158 / 1129-1138.
--
-- We do NOT re-run sp_d_vaccination_postprocessing or
-- sp_f_vaccination_postprocessing because their input
-- (nrt_vaccination) is hand-authored by Tier 1 and they do NOT
-- traverse nbs_act_entity. D_VACCINATION (21/21) and F_VACCINATION
-- (6/6) column populations are unchanged at Tier 1 isolation.
-- However, F_VACCINATION's COALESCE-to-sentinel-1 columns
-- (PATIENT_KEY, VACCINE_GIVEN_BY_KEY, VACCINE_GIVEN_BY_ORG_KEY,
-- INVESTIGATION_KEY) WILL resolve to non-sentinel keys whenever
-- f_vaccination_postprocessing is re-run after the upstream chains
-- have populated D_PATIENT / D_PROVIDER / D_ORGANIZATION /
-- INVESTIGATION -- but that resolution is driven by nrt_vaccination's
-- soft-ref columns (patient_uid, provider_uid, organization_uid,
-- phc_uid), NOT by nbs_act_entity rows. The Merge contract sequence
-- handles that re-run at step 7; this fixture's tail-EXEC is
-- specifically about unblocking the event SP.
--
-- The merge orchestrator runs this EXEC as part of step 7 of the
-- Merge contract sequence (Re-run Tier 1 chains affected by Tier 2
-- edges).
-- =====================================================================

USE [RDB_MODERN];
GO

-- Tail-EXEC: re-run sp_vaccination_event to confirm the SubOfVacc /
-- PerformerOfVacc rows unblock the event SP's main projection.
-- Expected: 2 rows projected (one per vaccination UID), JSON output
-- contains PATIENT_UID and PROVIDER_UID for both rows.
GO
