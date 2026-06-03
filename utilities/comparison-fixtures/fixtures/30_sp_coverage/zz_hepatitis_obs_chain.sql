-- =====================================================================
-- Round 4 (NO-SHORTCUT) — Hepatitis observation chain (ODSE-only)
-- =====================================================================
-- TARGET: populate dbo.HEP100 (0/187) and raise dbo.HEPATITIS_DATAMART
--   (39/209) through the REAL pipeline — no nrt_* INSERTs, no EXEC sp_*.
--
-- PIPELINE (verified against SP + view source, 2026-06-03):
--   ODSE Observation graph  --CDC/debezium-->  RDB_MODERN.nrt_observation*,
--     and service sp_investigation_event (driven off the PHC's
--     act_relationship graph) --> nrt_investigation_observation
--     (branch_type_cd='InvFrmQ', branch_id = question observation_uid).
--   dbo.v_getobs{code,num,txt,date}  (filter branch_type_cd='InvFrmQ',
--     ovX_seq=1)  JOIN  dbo.nrt_srte_IMRDBMapping (RDB_table='Hepatitis_Case',
--     match on unique_cd = obs.cd)  ==>  dbo.v_rdb_obs_mapping.
--   sp_hepatitis_case_datamart_postprocessing (routine 039) reads
--     v_rdb_obs_mapping and dynamic-INSERTs dbo.HEPATITIS_CASE
--     (one row per public_health_case_uid in @phc_uids).
--   sp_hep100_datamart_postprocessing (routine 042) builds #HEP100_INIT
--     FROM dbo.HEPATITIS_CASE hc INNER JOIN dbo.investigation I ON
--     hc.investigation_key=i.investigation_key, then INSERT dbo.HEP100.
--   sp_hepatitis_datamart_postprocessing (routine 013) also consumes the
--     same observation-derived HEP attributes -> more HEPATITIS_DATAMART cols.
--
-- WHY THIS WAS EMPTY: the Hep A acute Investigation PHC 22008500
--   (condition 10110, PG_Hepatitis_A_Acute_Investigation, prog_area HEP)
--   already exists in ODSE with a SubjOfPHC patient link and already flows
--   to nrt_investigation, but it had ZERO HEP observations -> the whole
--   v_rdb_obs_mapping->HEPATITIS_CASE->HEP100 chain produced nothing.
--   22008500 is already in scripts/merge_and_verify.sh PHC_UIDS, so the
--   Step-9 hepatitis SPs already target it; they just had no obs to read.
--
-- WHAT THIS AUTHORS (additive, ODSE-only):
--   - 1 L1 "form" Observation (act 22042001, cd 'INV_FORM_HepatitisInvestigation',
--     group_level_cd='L1', obs_domain_cd='CLN') — the target of every
--     InvFrmQ act_relationship and the source of the single PHCInvForm
--     act_relationship to PHC 22008500. This mirrors the L1 form
--     observation pattern in the bmirdCase functional test setup
--     (reporting-pipeline-service .../bmirdCase/020-.../setup.sql, act 14).
--   - 139 question Observations (act 22042100-22042238): exactly one per
--     nrt_srte_IMRDBMapping unique_cd where RDB_table='Hepatitis_Case'
--     (103 coded, 12 numeric, 13 txt, 11 date), each with the matching
--     Obs_value_{coded,numeric,txt,date} row (seq=1). Coded answers use a
--     code that actually exists in each question's code_set (resolved live
--     from nrt_srte_Code_value_general) so v_getobscode yields a non-NULL
--     response. HEP232 has no code_set; its coded value won't resolve
--     (column stays NULL) but the row is harmless.
--   - InvFrmQ act_relationships: target=L1 form (22042001), source=each
--     question obs. PHCInvForm act_relationship: target=PHC 22008500,
--     source=L1 form.
--
-- DOES NOT author HEPATITIS_CASE, HEP100, HEPATITIS_DATAMART, nrt_* rows,
--   or call any sp_* — all downstream of the real Step-9 pipeline.
--
-- UID block (reserved 22042000-22042999 in catalog/uid_ranges.md):
--   22042001              L1 form Observation (act_uid/observation_uid)
--   22042100-22042238     139 question Observations (act_uid/observation_uid)
--
-- Foundation dependencies (read-only):
--   PHC 22008500 (NBS_ODSE.public_health_case + act + SubjOfPHC participation
--     to patient 20000000) authored upstream; in PHC_UIDS already.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @ts datetime = '2026-04-01T00:00:00';
DECLARE @phc_uid bigint = 22008500;
DECLARE @l1_uid  bigint = 22042001;

-- Idempotency: skip the whole chain if the L1 form observation already exists.
IF NOT EXISTS (SELECT 1 FROM [dbo].[Observation] WHERE observation_uid = @l1_uid)
BEGIN
    -- ----- L1 form observation (target of every InvFrmQ; source of PHCInvForm) -----
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@l1_uid, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation]
        ([observation_uid],[cd],[cd_system_cd],[group_level_cd],[local_id],[obs_domain_cd],
         [status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr])
    VALUES
        (@l1_uid, N'INV_FORM_HepatitisInvestigation', N'NBS', N'L1', N'OBS22042001GA01', N'CLN',
         N'A', @ts, 22008500, N'T', 1);

    -- ----- 139 question observations + their answer values -----
    -- HEP101 (value_txt)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042100, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042100, N'HEP101', N'NBS', N'NEDSS Base System', N'OBS22042100GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22042100, 1, N'Hep A acute test note');
    
    -- HEP102 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042101, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042101, N'HEP102', N'NBS', N'NEDSS Base System', N'OBS22042101GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042101, N'N');
    
    -- HEP104 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042102, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042102, N'HEP104', N'NBS', N'NEDSS Base System', N'OBS22042102GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042102, N'N');
    
    -- HEP106 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042103, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042103, N'HEP106', N'NBS', N'NEDSS Base System', N'OBS22042103GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042103, N'N');
    
    -- HEP107 (from_time)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042104, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042104, N'HEP107', N'NBS', N'NEDSS Base System', N'OBS22042104GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22042104, 1, '2026-03-20T00:00:00');
    
    -- HEP110 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042105, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042105, N'HEP110', N'NBS', N'NEDSS Base System', N'OBS22042105GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042105, N'N');
    
    -- HEP111 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042106, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042106, N'HEP111', N'NBS', N'NEDSS Base System', N'OBS22042106GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042106, N'N');
    
    -- HEP112 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042107, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042107, N'HEP112', N'NBS', N'NEDSS Base System', N'OBS22042107GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042107, N'N');
    
    -- HEP113 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042108, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042108, N'HEP113', N'NBS', N'NEDSS Base System', N'OBS22042108GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042108, N'N');
    
    -- HEP114 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042109, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042109, N'HEP114', N'NBS', N'NEDSS Base System', N'OBS22042109GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042109, N'N');
    
    -- HEP115 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042110, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042110, N'HEP115', N'NBS', N'NEDSS Base System', N'OBS22042110GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042110, N'N');
    
    -- HEP116 (value_txt)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042111, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042111, N'HEP116', N'NBS', N'NEDSS Base System', N'OBS22042111GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22042111, 1, N'Hep A acute test note');
    
    -- HEP117 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042112, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042112, N'HEP117', N'NBS', N'NEDSS Base System', N'OBS22042112GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042112, N'N');
    
    -- HEP118 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042113, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042113, N'HEP118', N'NBS', N'NEDSS Base System', N'OBS22042113GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042113, N'N');
    
    -- HEP119 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042114, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042114, N'HEP119', N'NBS', N'NEDSS Base System', N'OBS22042114GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042114, N'N');
    
    -- HEP120 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042115, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042115, N'HEP120', N'NBS', N'NEDSS Base System', N'OBS22042115GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042115, N'N');
    
    -- HEP121 (numeric_value_1)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042116, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042116, N'HEP121', N'NBS', N'NEDSS Base System', N'OBS22042116GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22042116, 1, 95.0, 0);
    
    -- HEP122 (numeric_value_1)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042117, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042117, N'HEP122', N'NBS', N'NEDSS Base System', N'OBS22042117GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22042117, 1, 55.0, 0);
    
    -- HEP123 (numeric_value_1)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042118, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042118, N'HEP123', N'NBS', N'NEDSS Base System', N'OBS22042118GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22042118, 1, 88.0, 0);
    
    -- HEP124 (numeric_value_1)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042119, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042119, N'HEP124', N'NBS', N'NEDSS Base System', N'OBS22042119GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22042119, 1, 50.0, 0);
    
    -- HEP125 (from_time)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042120, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042120, N'HEP125', N'NBS', N'NEDSS Base System', N'OBS22042120GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22042120, 1, '2026-03-20T00:00:00');
    
    -- HEP126 (from_time)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042121, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042121, N'HEP126', N'NBS', N'NEDSS Base System', N'OBS22042121GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22042121, 1, '2026-03-20T00:00:00');
    
    -- HEP127 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042122, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042122, N'HEP127', N'NBS', N'NEDSS Base System', N'OBS22042122GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042122, N'N');
    
    -- HEP129 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042123, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042123, N'HEP129', N'NBS', N'NEDSS Base System', N'OBS22042123GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042123, N'N');
    
    -- HEP131 (value_txt)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042124, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042124, N'HEP131', N'NBS', N'NEDSS Base System', N'OBS22042124GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22042124, 1, N'Hep A acute test note');
    
    -- HEP132 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042125, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042125, N'HEP132', N'NBS', N'NEDSS Base System', N'OBS22042125GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042125, N'N');
    
    -- HEP133 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042126, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042126, N'HEP133', N'NBS', N'NEDSS Base System', N'OBS22042126GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042126, N'N');
    
    -- HEP134 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042127, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042127, N'HEP134', N'NBS', N'NEDSS Base System', N'OBS22042127GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042127, N'N');
    
    -- HEP135 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042128, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042128, N'HEP135', N'NBS', N'NEDSS Base System', N'OBS22042128GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042128, N'0');
    
    -- HEP136 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042129, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042129, N'HEP136', N'NBS', N'NEDSS Base System', N'OBS22042129GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042129, N'0');
    
    -- HEP137 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042130, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042130, N'HEP137', N'NBS', N'NEDSS Base System', N'OBS22042130GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042130, N'N');
    
    -- HEP138 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042131, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042131, N'HEP138', N'NBS', N'NEDSS Base System', N'OBS22042131GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042131, N'N');
    
    -- HEP139 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042132, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042132, N'HEP139', N'NBS', N'NEDSS Base System', N'OBS22042132GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042132, N'N');
    
    -- HEP141 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042133, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042133, N'HEP141', N'NBS', N'NEDSS Base System', N'OBS22042133GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042133, N'N');
    
    -- HEP143 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042134, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042134, N'HEP143', N'NBS', N'NEDSS Base System', N'OBS22042134GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042134, N'N');
    
    -- HEP144 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042135, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042135, N'HEP144', N'NBS', N'NEDSS Base System', N'OBS22042135GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042135, N'FA');
    
    -- HEP145 (value_txt)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042136, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042136, N'HEP145', N'NBS', N'NEDSS Base System', N'OBS22042136GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22042136, 1, N'Hep A acute test note');
    
    -- HEP146 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042137, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042137, N'HEP146', N'NBS', N'NEDSS Base System', N'OBS22042137GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042137, N'N');
    
    -- HEP147 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042138, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042138, N'HEP147', N'NBS', N'NEDSS Base System', N'OBS22042138GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042138, N'N');
    
    -- HEP148 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042139, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042139, N'HEP148', N'NBS', N'NEDSS Base System', N'OBS22042139GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042139, N'1');
    
    -- HEP149 (numeric_value_1)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042140, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042140, N'HEP149', N'NBS', N'NEDSS Base System', N'OBS22042140GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22042140, 1, 2024.0, 0);
    
    -- HEP150 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042141, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042141, N'HEP150', N'NBS', N'NEDSS Base System', N'OBS22042141GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042141, N'N');
    
    -- HEP151 (from_time)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042142, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042142, N'HEP151', N'NBS', N'NEDSS Base System', N'OBS22042142GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22042142, 1, '2026-03-20T00:00:00');
    
    -- HEP152 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042143, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042143, N'HEP152', N'NBS', N'NEDSS Base System', N'OBS22042143GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042143, N'N');
    
    -- HEP154 (value_txt)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042144, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042144, N'HEP154', N'NBS', N'NEDSS Base System', N'OBS22042144GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22042144, 1, N'Hep A acute test note');
    
    -- HEP155 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042145, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042145, N'HEP155', N'NBS', N'NEDSS Base System', N'OBS22042145GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042145, N'0');
    
    -- HEP156 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042146, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042146, N'HEP156', N'NBS', N'NEDSS Base System', N'OBS22042146GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042146, N'0');
    
    -- HEP157 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042147, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042147, N'HEP157', N'NBS', N'NEDSS Base System', N'OBS22042147GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042147, N'N');
    
    -- HEP158 (numeric_value_1)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042148, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042148, N'HEP158', N'NBS', N'NEDSS Base System', N'OBS22042148GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22042148, 1, 2024.0, 0);
    
    -- HEP159 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042149, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042149, N'HEP159', N'NBS', N'NEDSS Base System', N'OBS22042149GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042149, N'N');
    
    -- HEP160 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042150, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042150, N'HEP160', N'NBS', N'NEDSS Base System', N'OBS22042150GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042150, N'N');
    
    -- HEP161 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042151, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042151, N'HEP161', N'NBS', N'NEDSS Base System', N'OBS22042151GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042151, N'N');
    
    -- HEP162 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042152, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042152, N'HEP162', N'NBS', N'NEDSS Base System', N'OBS22042152GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042152, N'N');
    
    -- HEP163 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042153, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042153, N'HEP163', N'NBS', N'NEDSS Base System', N'OBS22042153GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042153, N'N');
    
    -- HEP164 (from_time)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042154, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042154, N'HEP164', N'NBS', N'NEDSS Base System', N'OBS22042154GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22042154, 1, '2026-03-20T00:00:00');
    
    -- HEP165 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042155, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042155, N'HEP165', N'NBS', N'NEDSS Base System', N'OBS22042155GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042155, N'N');
    
    -- HEP166 (value_txt)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042156, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042156, N'HEP166', N'NBS', N'NEDSS Base System', N'OBS22042156GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22042156, 1, N'Hep A acute test note');
    
    -- HEP167 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042157, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042157, N'HEP167', N'NBS', N'NEDSS Base System', N'OBS22042157GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042157, N'N');
    
    -- HEP168 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042158, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042158, N'HEP168', N'NBS', N'NEDSS Base System', N'OBS22042158GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042158, N'F');
    
    -- HEP169 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042159, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042159, N'HEP169', N'NBS', N'NEDSS Base System', N'OBS22042159GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042159, N'N');
    
    -- HEP170 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042160, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042160, N'HEP170', N'NBS', N'NEDSS Base System', N'OBS22042160GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042160, N'F');
    
    -- HEP171 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042161, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042161, N'HEP171', N'NBS', N'NEDSS Base System', N'OBS22042161GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042161, N'N');
    
    -- HEP173 (value_txt)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042162, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042162, N'HEP173', N'NBS', N'NEDSS Base System', N'OBS22042162GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22042162, 1, N'Hep A acute test note');
    
    -- HEP174 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042163, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042163, N'HEP174', N'NBS', N'NEDSS Base System', N'OBS22042163GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042163, N'N');
    
    -- HEP176 (value_txt)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042164, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042164, N'HEP176', N'NBS', N'NEDSS Base System', N'OBS22042164GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22042164, 1, N'Hep A acute test note');
    
    -- HEP177 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042165, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042165, N'HEP177', N'NBS', N'NEDSS Base System', N'OBS22042165GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042165, N'N');
    
    -- HEP178 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042166, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042166, N'HEP178', N'NBS', N'NEDSS Base System', N'OBS22042166GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042166, N'N');
    
    -- HEP179 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042167, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042167, N'HEP179', N'NBS', N'NEDSS Base System', N'OBS22042167GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042167, N'N');
    
    -- HEP180 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042168, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042168, N'HEP180', N'NBS', N'NEDSS Base System', N'OBS22042168GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042168, N'N');
    
    -- HEP181 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042169, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042169, N'HEP181', N'NBS', N'NEDSS Base System', N'OBS22042169GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042169, N'N');
    
    -- HEP183 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042170, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042170, N'HEP183', N'NBS', N'NEDSS Base System', N'OBS22042170GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042170, N'N');
    
    -- HEP184 (numeric_value_1)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042171, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042171, N'HEP184', N'NBS', N'NEDSS Base System', N'OBS22042171GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22042171, 1, 2024.0, 0);
    
    -- HEP185 (numeric_value_1)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042172, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042172, N'HEP185', N'NBS', N'NEDSS Base System', N'OBS22042172GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22042172, 1, 6.0, 0);
    
    -- HEP186 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042173, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042173, N'HEP186', N'NBS', N'NEDSS Base System', N'OBS22042173GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042173, N'N');
    
    -- HEP187 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042174, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042174, N'HEP187', N'NBS', N'NEDSS Base System', N'OBS22042174GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042174, N'N');
    
    -- HEP188 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042175, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042175, N'HEP188', N'NBS', N'NEDSS Base System', N'OBS22042175GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042175, N'1');
    
    -- HEP189 (numeric_value_1)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042176, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042176, N'HEP189', N'NBS', N'NEDSS Base System', N'OBS22042176GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22042176, 1, 2024.0, 0);
    
    -- HEP190 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042177, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042177, N'HEP190', N'NBS', N'NEDSS Base System', N'OBS22042177GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042177, N'N');
    
    -- HEP191 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042178, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042178, N'HEP191', N'NBS', N'NEDSS Base System', N'OBS22042178GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042178, N'N');
    
    -- HEP192 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042179, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042179, N'HEP192', N'NBS', N'NEDSS Base System', N'OBS22042179GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042179, N'N');
    
    -- HEP194 (value_txt)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042180, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042180, N'HEP194', N'NBS', N'NEDSS Base System', N'OBS22042180GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22042180, 1, N'Hep A acute test note');
    
    -- HEP195 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042181, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042181, N'HEP195', N'NBS', N'NEDSS Base System', N'OBS22042181GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042181, N'0');
    
    -- HEP196 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042182, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042182, N'HEP196', N'NBS', N'NEDSS Base System', N'OBS22042182GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042182, N'0');
    
    -- HEP197 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042183, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042183, N'HEP197', N'NBS', N'NEDSS Base System', N'OBS22042183GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042183, N'N');
    
    -- HEP198 (numeric_value_1)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042184, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042184, N'HEP198', N'NBS', N'NEDSS Base System', N'OBS22042184GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22042184, 1, 2024.0, 0);
    
    -- HEP199 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042185, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042185, N'HEP199', N'NBS', N'NEDSS Base System', N'OBS22042185GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042185, N'N');
    
    -- HEP200 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042186, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042186, N'HEP200', N'NBS', N'NEDSS Base System', N'OBS22042186GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042186, N'F');
    
    -- HEP201 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042187, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042187, N'HEP201', N'NBS', N'NEDSS Base System', N'OBS22042187GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042187, N'N');
    
    -- HEP202 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042188, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042188, N'HEP202', N'NBS', N'NEDSS Base System', N'OBS22042188GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042188, N'F');
    
    -- HEP203 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042189, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042189, N'HEP203', N'NBS', N'NEDSS Base System', N'OBS22042189GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042189, N'N');
    
    -- HEP204 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042190, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042190, N'HEP204', N'NBS', N'NEDSS Base System', N'OBS22042190GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042190, N'CM');
    
    -- HEP205 (value_txt)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042191, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042191, N'HEP205', N'NBS', N'NEDSS Base System', N'OBS22042191GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22042191, 1, N'Hep A acute test note');
    
    -- HEP206 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042192, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042192, N'HEP206', N'NBS', N'NEDSS Base System', N'OBS22042192GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042192, N'N');
    
    -- HEP207 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042193, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042193, N'HEP207', N'NBS', N'NEDSS Base System', N'OBS22042193GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042193, N'CM');
    
    -- HEP208 (value_txt)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042194, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042194, N'HEP208', N'NBS', N'NEDSS Base System', N'OBS22042194GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22042194, 1, N'Hep A acute test note');
    
    -- HEP209 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042195, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042195, N'HEP209', N'NBS', N'NEDSS Base System', N'OBS22042195GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042195, N'N');
    
    -- HEP210 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042196, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042196, N'HEP210', N'NBS', N'NEDSS Base System', N'OBS22042196GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042196, N'N');
    
    -- HEP211 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042197, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042197, N'HEP211', N'NBS', N'NEDSS Base System', N'OBS22042197GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042197, N'N');
    
    -- HEP212 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042198, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042198, N'HEP212', N'NBS', N'NEDSS Base System', N'OBS22042198GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042198, N'N');
    
    -- HEP213 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042199, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042199, N'HEP213', N'NBS', N'NEDSS Base System', N'OBS22042199GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042199, N'N');
    
    -- HEP214 (from_time)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042200, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042200, N'HEP214', N'NBS', N'NEDSS Base System', N'OBS22042200GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22042200, 1, '2026-03-20T00:00:00');
    
    -- HEP215 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042201, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042201, N'HEP215', N'NBS', N'NEDSS Base System', N'OBS22042201GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042201, N'N');
    
    -- HEP216 (value_txt)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042202, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042202, N'HEP216', N'NBS', N'NEDSS Base System', N'OBS22042202GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22042202, 1, N'Hep A acute test note');
    
    -- HEP217 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042203, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042203, N'HEP217', N'NBS', N'NEDSS Base System', N'OBS22042203GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042203, N'N');
    
    -- HEP218 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042204, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042204, N'HEP218', N'NBS', N'NEDSS Base System', N'OBS22042204GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042204, N'N');
    
    -- HEP219 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042205, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042205, N'HEP219', N'NBS', N'NEDSS Base System', N'OBS22042205GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042205, N'N');
    
    -- HEP220 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042206, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042206, N'HEP220', N'NBS', N'NEDSS Base System', N'OBS22042206GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042206, N'N');
    
    -- HEP221 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042207, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042207, N'HEP221', N'NBS', N'NEDSS Base System', N'OBS22042207GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042207, N'N');
    
    -- HEP222 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042208, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042208, N'HEP222', N'NBS', N'NEDSS Base System', N'OBS22042208GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042208, N'J');
    
    -- HEP223 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042209, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042209, N'HEP223', N'NBS', N'NEDSS Base System', N'OBS22042209GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042209, N'N');
    
    -- HEP224 (numeric_value_1)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042210, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042210, N'HEP224', N'NBS', N'NEDSS Base System', N'OBS22042210GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22042210, 1, 2024.0, 0);
    
    -- HEP225 (numeric_value_1)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042211, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042211, N'HEP225', N'NBS', N'NEDSS Base System', N'OBS22042211GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22042211, 1, 6.0, 0);
    
    -- HEP226 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042212, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042212, N'HEP226', N'NBS', N'NEDSS Base System', N'OBS22042212GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042212, N'N');
    
    -- HEP227 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042213, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042213, N'HEP227', N'NBS', N'NEDSS Base System', N'OBS22042213GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042213, N'N');
    
    -- HEP228 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042214, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042214, N'HEP228', N'NBS', N'NEDSS Base System', N'OBS22042214GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042214, N'N');
    
    -- HEP229 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042215, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042215, N'HEP229', N'NBS', N'NEDSS Base System', N'OBS22042215GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042215, N'N');
    
    -- HEP230 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042216, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042216, N'HEP230', N'NBS', N'NEDSS Base System', N'OBS22042216GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042216, N'N');
    
    -- HEP231 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042217, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042217, N'HEP231', N'NBS', N'NEDSS Base System', N'OBS22042217GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042217, N'N');
    
    -- HEP232 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042218, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042218, N'HEP232', N'NBS', N'NEDSS Base System', N'OBS22042218GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042218, N'N');
    
    -- HEP233 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042219, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042219, N'HEP233', N'NBS', N'NEDSS Base System', N'OBS22042219GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042219, N'N');
    
    -- HEP234 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042220, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042220, N'HEP234', N'NBS', N'NEDSS Base System', N'OBS22042220GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042220, N'N');
    
    -- HEP235 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042221, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042221, N'HEP235', N'NBS', N'NEDSS Base System', N'OBS22042221GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042221, N'N');
    
    -- HEP236 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042222, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042222, N'HEP236', N'NBS', N'NEDSS Base System', N'OBS22042222GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042222, N'B');
    
    -- HEP237 (value_txt)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042223, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042223, N'HEP237', N'NBS', N'NEDSS Base System', N'OBS22042223GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22042223, 1, N'Hep A acute test note');
    
    -- HEP238 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042224, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042224, N'HEP238', N'NBS', N'NEDSS Base System', N'OBS22042224GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042224, N'N');
    
    -- HEP241 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042225, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042225, N'HEP241', N'NBS', N'NEDSS Base System', N'OBS22042225GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042225, N'N');
    
    -- HEP243 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042226, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042226, N'HEP243', N'NBS', N'NEDSS Base System', N'OBS22042226GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042226, N'N');
    
    -- HEP244 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042227, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042227, N'HEP244', N'NBS', N'NEDSS Base System', N'OBS22042227GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042227, N'N');
    
    -- HEP245 (from_time)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042228, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042228, N'HEP245', N'NBS', N'NEDSS Base System', N'OBS22042228GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22042228, 1, '2026-03-20T00:00:00');
    
    -- HEP246 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042229, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042229, N'HEP246', N'NBS', N'NEDSS Base System', N'OBS22042229GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042229, N'1');
    
    -- HEP247 (from_time)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042230, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042230, N'HEP247', N'NBS', N'NEDSS Base System', N'OBS22042230GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22042230, 1, '2026-03-20T00:00:00');
    
    -- HEP248 (from_time)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042231, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042231, N'HEP248', N'NBS', N'NEDSS Base System', N'OBS22042231GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22042231, 1, '2026-03-20T00:00:00');
    
    -- HEP249 (from_time)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042232, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042232, N'HEP249', N'NBS', N'NEDSS Base System', N'OBS22042232GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22042232, 1, '2026-03-20T00:00:00');
    
    -- HEP250 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042233, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042233, N'HEP250', N'NBS', N'NEDSS Base System', N'OBS22042233GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042233, N'N');
    
    -- HEP251 (from_time)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042234, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042234, N'HEP251', N'NBS', N'NEDSS Base System', N'OBS22042234GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22042234, 1, '2026-03-20T00:00:00');
    
    -- HEP252 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042235, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042235, N'HEP252', N'NBS', N'NEDSS Base System', N'OBS22042235GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042235, N'N');
    
    -- HEP253 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042236, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042236, N'HEP253', N'NBS', N'NEDSS Base System', N'OBS22042236GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042236, N'N');
    
    -- HEP263 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042237, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042237, N'HEP263', N'NBS', N'NEDSS Base System', N'OBS22042237GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042237, N'N');
    
    -- HEP264 (code)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22042238, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22042238, N'HEP264', N'NBS', N'NEDSS Base System', N'OBS22042238GA01', N'A', @ts, 22008500, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22042238, N'N');

    -- ----- act_relationships -----
    -- InvFrmQ: target = L1 form (22042001), source = each question observation.
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042100, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042101, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042102, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042103, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042104, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042105, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042106, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042107, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042108, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042109, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042110, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042111, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042112, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042113, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042114, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042115, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042116, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042117, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042118, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042119, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042120, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042121, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042122, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042123, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042124, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042125, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042126, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042127, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042128, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042129, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042130, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042131, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042132, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042133, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042134, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042135, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042136, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042137, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042138, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042139, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042140, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042141, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042142, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042143, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042144, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042145, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042146, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042147, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042148, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042149, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042150, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042151, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042152, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042153, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042154, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042155, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042156, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042157, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042158, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042159, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042160, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042161, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042162, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042163, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042164, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042165, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042166, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042167, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042168, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042169, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042170, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042171, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042172, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042173, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042174, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042175, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042176, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042177, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042178, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042179, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042180, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042181, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042182, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042183, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042184, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042185, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042186, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042187, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042188, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042189, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042190, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042191, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042192, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042193, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042194, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042195, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042196, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042197, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042198, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042199, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042200, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042201, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042202, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042203, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042204, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042205, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042206, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042207, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042208, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042209, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042210, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042211, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042212, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042213, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042214, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042215, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042216, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042217, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042218, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042219, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042220, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042221, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042222, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042223, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042224, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042225, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042226, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042227, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042228, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042229, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042230, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042231, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042232, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042233, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042234, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042235, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042236, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042237, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (22042001, 22042238, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    -- PHCInvForm: target = PHC 22008500, source = L1 form observation.
    INSERT INTO [dbo].[Act_relationship]
        ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],
         [record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],
         [target_class_cd],[type_desc_txt])
    VALUES
        (@phc_uid, @l1_uid, N'PHCInvForm', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts,
         N'CASE', N'PHC Investigation Form');

    -- Bump the PHC last_chg_time so CDC re-emits the investigation and the
    -- service re-runs sp_investigation_event, rebuilding nrt_investigation_observation
    -- with the newly-authored InvFrmQ branches.
    UPDATE [dbo].[public_health_case]
       SET [last_chg_time] = SYSDATETIME()
     WHERE public_health_case_uid = @phc_uid;
END;
GO
